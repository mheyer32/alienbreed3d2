
; Unclipped Circle Routine : Rewritten from compiler output, this is the
; fast path with all steps inluned.
;
; Uses Jesko Midpoint algorithm to plot 8 octants per loop. Results are
; undefied and potentially disasterous if the circle position/size exceed
; the buffer extents. This code should only be used when the circle is
; already guaranteed to fit within the render buffer.
;
; Octants
;
;    \F | G/
;     \ | /
;   E  \|/  H
; ------o------
;   D  /|\  A
;     / | \
;    /C | B\
;
; Points are plotted as luminance over the buffer by first reading the pixel
; then looking up it's luminance remapepd value in the slice of the shade
; table indicated by the shade value.
;
; This is a total refactor of the compiler generated baseline that aims to
; pair octant read/remap/write cycles to avoid AGU stalls. The main loop is
; free from stride table reads and multiplication.
;
; Params
; d0.w centreX
; d1.w centreY
; d2.w radius
; d3.w shade (0 - 31 white to normal, 32-63 normal to black)

draw_ShadeCircleUnclipped:
				; Check if the radius is small enough to use the small circle fast path
				cmp.w	#16,d2
				bge.s	.ready

.small_path:
				movem.l	a2-a4,-(sp)
				; shade table lookup
				and.l   #$3f,d3
				lsl.l   #8,d3                              ; 256 bytes per slice
				add.l   Draw_PaletteShadeTablePtr_l,d3
				move.l  d3,a0                              ; a0 = shade

				; circle centre address
				move.l  Vid_FastBufferPtr_l,a1
				add.w   d0,a1
				lea     draw_RenderBufferStrideTable_vl,a2 ; stride table from wall plotting code
				move.l  (a2,d1.w*4),d1                     ; y * stride
				add.l   d1,a1                              ; a1 = center address (Xc, Yc)

				; load up the small circle data pointer
				subq.w	#1,d2                              ; radius - 1 = index in table
				lea 	draw_SmallCiclePtrs_vl,a2
				move.l  (a2,d2.w*4),a2                     ; a2 = circle data location

				clr.l   d2
				clr.l   d3
.pairs:
				; Register assignments
				;
				; d0 = offset
				; d1 = -offset
				; d2/d3 = read/remap/write temporaries
				;
				; a0 = shade table slice
				; a1 = circle centre address in framebuffer
				; a2 = offset pointer
				; a3,a4 pixel address caches

				move.w	(a2)+,d0                    ; next offset in list
				beq.s	.done_small                 ; zero terminated

				; d0 and d1 contain the offsets
				move.w	d0,d1
				neg.w   d1
				;st (a1,d0.w)
				;st (a1,d1.w)
				lea     (a1,d0.w),a3
				lea     (a1,d1.w),a4
				move.b  (a3),d2        ; read
				move.b  (a4),d3
				PLOT    (a0,d2.w),(a3) ; remap and write
				PLOT    (a0,d3.w),(a4)
				bra.s   .pairs

.done_small:
				movem.l  (sp)+,a2-a4
				rts

.ready:
				movem.l d4-d7/a2-a6,-(sp)

				; shade table lookup
				and.l   #$3f,d3
				lsl.l   #8,d3                       ; 256 bytes per slice
				add.l   Draw_PaletteShadeTablePtr_l,d3
				move.l  d3,a0                       ; a0 = shade

				; circle centre address
				move.l  Vid_FastBufferPtr_l,a1
				add.w   d0,a1
				lea     draw_RenderBufferStrideTable_vl,a2 ; stride table from wall plotting code
				move.l  (a2,d1.w*4),d1              ; y * stride
				add.l   d1,a1                       ; a1 = center address (Xc, Yc)

				; row pointers
				move.l  4(a2),d3                    ; d3 = stride
                move.l  (a2,d2.w*4),d0              ; d0 = radius * stride
				move.l  a1,a4
				add.l   d0,a4                       ; a4 = center + (radius * stride)
				move.l  a1,a5
				sub.l   d0,a5                       ; a5 = centre - (radius * stride)
				move.l  a1,a2                       ; a2 = centre row (+y)
				move.l  a1,a3                       ; a3 = centre row (-y)
				move.w  d2,d0                       ; d0.w = x (radius)
				clr.l	d1                          ; d1.w = y (0)
				moveq   #1,d2
				sub.w   d0,d2                       ; err = 1 - radius

				; temporaries for pixel buffering
				clr.l   d4
				clr.l   d5

				; mirror ordinates
				move.w  d0,d6
				neg.w   d6                          ; d6.w = -x
				move.w  d1,d7
				neg.w   d7                          ; d7.w = -y

				; Register assignments:
				;
				; d0 = x
				; d1 = y
				; d2 = err
				; d3 = buffer stride
				; d4,d5 = pixel read/remap temporaries
				; d6 = -x
				; d7 = -y
				;
				; a0 = shade slice
				; a1,a6 = pixel address temporaries (saves calculating indexed modes repeatedly)
				; a2 = row + y
				; a3 = row - y
				; a4 = centre + radius * stride
				; a5 = centre - radius * stride

.loop:
				; Octants A,D,E,H
				tst.w   d1                          ; y == 0?
				beq.s   .plot_y0_axis               ; at y = 0, a2 == a3, avoid double plot

				lea     (a2,d0.w),a1                ; Octant A
				lea     (a3,d0.w),a6                ; Octant H
				move.b  (a1),d4                     ; Octant A
				move.b  (a6),d5                     ; Octant H
				PLOT    (a0,d4.w),(a1)              ; remap and write
				PLOT    (a0,d5.w),(a6)

				tst.w   d0                          ; skip duplicate x = 0 on vertical axis
				beq.s   .skip_neg_x

				lea     (a2,d6.w),a1                ; Octant D
				lea     (a3,d6.w),a6                ; Octant E
				move.b  (a1),d4                     ; Octant D
				move.b  (a6),d5                     ; Octant E
				PLOT    (a0,d4.w),(a1)              ; remap and write
				PLOT    (a0,d5.w),(a6)
				bra.s   .skip_neg_x

.plot_y0_axis:
				; At y = 0: a2 == a3 => plot (+x, 0) and (-x, 0) just once
				lea     (a2,d0.w),a1                ; Octant A (+x, 0)
				move.b  (a1),d4
				PLOT    (a0,d4.w),(a1)
				tst.w   d0                          ; skip duplicate x = 0 on vertical axis
				beq.s   .skip_neg_x

				lea     (a2,d6.w),a1                ; Octant D (-x, 0)
				move.b  (a1),d4
				PLOT    (a0,d4.w),(a1)

.skip_neg_x:
				; Octants B,C,F,G - skip if x == y to avoid double plot
				cmp.w   d0,d1                       ; x == y
				beq.s   .step                       ; skip transposed octants

				lea     (a4,d1.w),a1                ; Octant B
				lea     (a5,d1.w),a6                ; Octant G
				move.b  (a1),d4
				move.b  (a6),d5
				PLOT    (a0,d4.w),(a1)              ; remap and write
				PLOT    (a0,d5.w),(a6)

				tst.w   d1                          ; skip duplicate y = 0 on horizontal axis
				beq.s   .step

				lea     (a4,d7.w),a1                ; Octant C
				lea     (a5,d7.w),a6                ; Octant F
				move.b  (a1),d4
				move.b  (a6),d5
				PLOT    (a0,d4.w),(a1)              ; remap and write
				PLOT    (a0,d5.w),(a6)

; Jesko step
.step:
				tst.w   d2
				ble.s   .step_y

.step_x:
				subq.w  #1,d0                      ; x--
				addq.w  #1,d6                      ; -x++
				sub.l   d3,a4                      ; pointer (yc + x) decrement line
				add.l   d3,a5                      ; pointer (yc - x) increment line
				move.w  d0,d4
				add.w   d4,d4
				addq.w  #1,d4
				sub.w   d4,d2                      ; err -= (2 * x) + 1
				cmp.w   d1,d0                      ; while x >= y
				bge     .loop
				bra.s   .done

.step_y:
				addq.w  #1,d1                      ; y++
				subq.w  #1,d7                      ; -y--
				add.l   d3,a2                      ; pointer (yc + y) increment line
				sub.l   d3,a3                      ; pointer (yc - y) decrement line
				move.w  d1,d4
				add.w   d4,d4
				addq.w  #1,d4
				add.w   d4,d2                      ; err += (2 * y) + 1
				tst.w   d2
				bgt.s   .step_x

				cmp.w   d1,d0                      ; while x >= y
				bge     .loop

.done:
				movem.l (sp)+,d4-d7/a2-a6
				rts

