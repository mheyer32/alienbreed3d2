
; Unclipped Circle Routine : Partials
;
; Uses Jesko Midpoint algorithm to plot up to four octants per loop. This code
; is used when it has already been determined that the centre of the circle is
; within the the view rectangle but the circumference intersects with one or
; more of the edges. The goal of this code is to plot only the unclipped
; half or quarter of the circle that remains completely within bounds.
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
; Params
; d0.w = centreX
; d1.w = centreY
; d2.w = radius
; d3.l = [ uppwer .w: shade level ][ lower .w: clipping outcode ]
jump_SCUPartialUnclipped:
				movem.l d4-d7/a2-a6,-(sp)

				; save off the current coordinates as we will need those to draw the clipped
				; portions later.
				movem.w d0-d2,-(sp)
				clr.l   d5
				move.w	d3,d4  ; will switch on this in a moment
				and.w   #$f,d4 ; ensure d4 has only the expected 16 combinations
				swap    d3     ; shade table level restored in d3.w

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
				; d6 = -x (if used)
				; d7 = -y (if used)
				;
				; a0 = shade slice
				; a1,a6 = pixel address temporaries (saves calculating indexed modes repeatedly)
				; a2 = row + y
				; a3 = row - y
				; a4 = centre + radius * stride
				; a5 = centre - radius * stride

				; Now jump to a specific variation to draw only the fully unclipped octants
				; based on the outcode we already computed.

				move.w  jump_SCU(pc,d4.w*2),d4
				jmp     jump_SCU(pc,d4.w)

jump_SCU:
				; not all clip codes are possibe.
				dc.w	jump_SCU_nop-jump_SCU ; outcode  0: Unreachable, already handled by fast path.
				dc.w	jump_SCU_R-jump_SCU   ; outcode  1: OUTCODE_BIT_LEFT, draw right half only
				dc.w	jump_SCU_L-jump_SCU   ; outcode  2: OUTCODE_BIT_RIGHT, draw left half only
				dc.w	jump_SCU_nop-jump_SCU ; outcode  3: Unreachable; can't be LR clipped but not top and/or bottom.
				dc.w	jump_SCU_B-jump_SCU   ; outcode  4: OUTCODE_BIT_TOP, draw bottom half only
				dc.w	jump_SCU_BR-jump_SCU  ; outcode  5: OUTCODE_BIT_TOP|OUTCODE_BIT_LEFT, draw bottom-right corner only
				dc.w	jump_SCU_BL-jump_SCU  ; outcode  6: OUTCODE_BIT_TOP|OUTCODE_BIT_RIGHT, draw bottom-left corner only
				dc.w	jump_SCU_full_clip-jump_SCU ; outcode  7:
				dc.w	jump_SCU_T-jump_SCU   ; outcode  8: OUTCODE_BIT_BOTTOM, draw top half only
				dc.w	jump_SCU_TR-jump_SCU  ; outcode  9: OUTCODE_BIT_BOTTOM|OUTCODE_BIT_LEFT, draw top-right corner only
				dc.w	jump_SCU_TL-jump_SCU  ; outcode 10: OUTCODE_BIT_BOTTOM|OUTCODE_BIT_RIGHT, draw top-pleft-corner only
				dc.w	jump_SCU_full_clip-jump_SCU ; outcode 11:
				dc.w	jump_SCU_full_clip-jump_SCU ; outcode 12: top and bottom
				dc.w	jump_SCU_full_clip-jump_SCU ; outcode 13:
				dc.w	jump_SCU_full_clip-jump_SCU ; outcode 14:
				dc.w	jump_SCU_full_clip-jump_SCU ; outcode 15: all


jump_SCU_full_clip:
				; None of the interior quarter or half partials can be rendered without clipping, so we have to go to
				; the PITA path.
				; restore source coordinates
				movem.w (sp)+,d0-d2
				moveq   #$f,d3
				CALLC   draw_SCUPartialClipped
				movem.l (sp)+,d4-d7/a2-a6
				rts
jump_SCU_nop:
				movem.w (sp)+,d0-d2
				movem.l (sp)+,d4-d7/a2-a6
				rts

; Common Jesko step. This is not strictly a subroutine as it does not use a return on the stack,
; Instead, we put the return address into a6 and jump back, i.e. a linkless call.
scu_step:
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
				jmp     (a6)                       ; test BGE at return site

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
				jmp     (a6)                       ; test BGE at return site

; Right Half Octants
;
;    \. | G/
;     \ | /
;   .  \|/  H
; ------o------
;   .  /|\  A
;     / | \
;    /. | B\
jump_SCU_R:

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

				bra.s   .skip_neg_x

.plot_y0_axis:
				; At y = 0: a2 == a3 => plot (+x, 0) and (-x, 0) just once
				lea     (a2,d0.w),a1                ; Octant A (+x, 0)
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

.step:
				lea     .continue(pc),a6
				bra     scu_step
.continue:
				bge     .loop

.done:
				; restore source coordinates
				movem.w (sp)+,d0-d2
				moveq	#QUADRANT_BIT_BL|QUADRANT_BIT_TL,d3
				CALLC   draw_SCUPartialClipped

				movem.l (sp)+,d4-d7/a2-a6
				rts

; Left Half Octants
;
;    \F | ./
;     \ | /
;   E  \|/  .
; ------o------
;   D  /|\  .
;     / | \
;    /C | .\
jump_SCU_L:

.loop:
				; Octants A,D,E,H
				tst.w   d1                          ; y == 0?
				beq.s   .plot_y0_axis               ; at y = 0, a2 == a3, avoid double plot

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
				tst.w   d0                          ; skip duplicate x = 0 on vertical axis
				beq.s   .skip_neg_x

				lea     (a2,d6.w),a1                ; Octant D (-x, 0)
				move.b  (a1),d4
				PLOT    (a0,d4.w),(a1)

.skip_neg_x:
				; Octants B,C,F,G - skip if x == y to avoid double plot
				cmp.w   d0,d1                       ; x == y
				beq.s   .step                       ; skip transposed octants

				tst.w   d1                          ; skip duplicate y = 0 on horizontal axis
				beq.s   .step

				lea     (a4,d7.w),a1                ; Octant C
				lea     (a5,d7.w),a6                ; Octant F
				move.b  (a1),d4
				move.b  (a6),d5
				PLOT    (a0,d4.w),(a1)              ; remap and write
				PLOT    (a0,d5.w),(a6)

.step:
				lea     .continue(pc),a6
				bra     scu_step
.continue:
				bge     .loop

.done:
				; restore source coordinates
				movem.w (sp)+,d0-d2
				moveq	#QUADRANT_BIT_BR|QUADRANT_BIT_TR,d3
				CALLC   draw_SCUPartialClipped

				movem.l (sp)+,d4-d7/a2-a6
				rts

; Top Half Octants
;
;    \F | G/
;     \ | /
;   E  \|/  H
; ------o------
;   .  /|\  .
;     / | \
;    /. | .\

jump_SCU_T:

.loop:
				; Octants A,D,E,H
				tst.w   d1                          ; y == 0?
				beq.s   .plot_y0_axis               ; at y = 0, a2 == a3, avoid double plot

				lea     (a3,d0.w),a6                ; Octant H
				move.b  (a6),d5                     ; Octant H
				PLOT    (a0,d5.w),(a6)

				tst.w   d0                          ; skip duplicate x = 0 on vertical axis
				beq.s   .skip_neg_x

				lea     (a3,d6.w),a6                ; Octant E
				move.b  (a6),d5                     ; Octant E
				PLOT    (a0,d5.w),(a6)

.plot_y0_axis:

.skip_neg_x:
				; Octants B,C,F,G - skip if x == y to avoid double plot
				cmp.w   d0,d1                       ; x == y
				beq.s   .step                       ; skip transposed octants

				lea     (a5,d1.w),a6                ; Octant G
				move.b  (a6),d5
				PLOT    (a0,d5.w),(a6)

				tst.w   d1                          ; skip duplicate y = 0 on horizontal axis
				beq.s   .step

				lea     (a5,d7.w),a6                ; Octant F
				move.b  (a6),d5
				PLOT    (a0,d5.w),(a6)

.step:
				lea     .continue(pc),a6
				bra     scu_step
.continue:
				bge     .loop

.done:
				; restore source coordinates
				movem.w (sp)+,d0-d2
				moveq	#QUADRANT_BIT_BR|QUADRANT_BIT_BL,d3
				CALLC   draw_SCUPartialClipped


				movem.l (sp)+,d4-d7/a2-a6
				rts


; Bottom Half Octants
;
;    \. | ./
;     \ | /
;   .  \|/  .
; ------o------
;   D  /|\  A
;     / | \
;    /C | B\

jump_SCU_B:

.loop:
				; Octants A,D,E,H
				tst.w   d1                          ; y == 0?
				beq.s   .plot_y0_axis               ; at y = 0, a2 == a3, avoid double plot

				lea     (a2,d0.w),a1                ; Octant A
				move.b  (a1),d4                     ; Octant A
				PLOT    (a0,d4.w),(a1)              ; remap and write

				tst.w   d0                          ; skip duplicate x = 0 on vertical axis
				beq.s   .skip_neg_x

				lea     (a2,d6.w),a1                ; Octant D
				move.b  (a1),d4                     ; Octant D
				PLOT    (a0,d4.w),(a1)              ; remap and write
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
				move.b  (a1),d4
				PLOT    (a0,d4.w),(a1)              ; remap and write

				tst.w   d1                          ; skip duplicate y = 0 on horizontal axis
				beq.s   .step

				lea     (a4,d7.w),a1                ; Octant C
				move.b  (a1),d4
				PLOT    (a0,d4.w),(a1)              ; remap and write

.step:
				lea     .continue(pc),a6
				bra     scu_step
.continue:
				bge     .loop

.done:
				; restore source coordinates
				movem.w (sp)+,d0-d2
				moveq	#QUADRANT_BIT_TR|QUADRANT_BIT_TL,d3
				CALLC   draw_SCUPartialClipped

				movem.l (sp)+,d4-d7/a2-a6
				rts



; Bottom Right Quarter Octants
;
;    \. | ./
;     \ | /
;   .  \|/  .
; ------o------
;   .  /|\  A
;     / | \
;    /. | B\

jump_SCU_BR:

.loop:
				; Octants A,D,E,H
				tst.w   d1                          ; y == 0?
				beq.s   .plot_y0_axis               ; at y = 0, a2 == a3, avoid double plot

				lea     (a2,d0.w),a1                ; Octant A
				move.b  (a1),d4                     ; Octant A
				PLOT    (a0,d4.w),(a1)              ; remap and write

				bra.s   .skip_neg_x

.plot_y0_axis:
				; At y = 0: a2 == a3 => plot (+x, 0) and (-x, 0) just once
				lea     (a2,d0.w),a1                ; Octant A (+x, 0)
				move.b  (a1),d4
				PLOT    (a0,d4.w),(a1)

.skip_neg_x:
				; Octants B,C,F,G - skip if x == y to avoid double plot
				cmp.w   d0,d1                       ; x == y
				beq.s   .step                       ; skip transposed octants

				lea     (a4,d1.w),a1                ; Octant B
				move.b  (a1),d4
				PLOT    (a0,d4.w),(a1)              ; remap and write

.step:
				lea     .continue(pc),a6
				bra     scu_step
.continue:
				bge     .loop

.done:
				; restore source coordinates
				movem.w (sp)+,d0-d2
				moveq	#QUADRANT_BIT_BL|QUADRANT_BIT_TR,d3
				CALLC   draw_SCUPartialClipped

				movem.l (sp)+,d4-d7/a2-a6
				rts

; Bottom Left Quarter Octants
;
;    \. | ./
;     \ | /
;   .  \|/  .
; ------o------
;   D  /|\  .
;     / | \
;    /C | .\

jump_SCU_BL:

.loop:
				; Octants A,D,E,H
				tst.w   d1                          ; y == 0?
				beq.s   .plot_y0_axis               ; at y = 0, a2 == a3, avoid double plot

				tst.w   d0                          ; skip duplicate x = 0 on vertical axis
				beq.s   .skip_neg_x

				lea     (a2,d6.w),a1                ; Octant D
				move.b  (a1),d4                     ; Octant D
				PLOT    (a0,d4.w),(a1)              ; remap and write
				bra.s   .skip_neg_x

.plot_y0_axis:
				; At y = 0: a2 == a3 => plot (+x, 0) and (-x, 0) just once
				tst.w   d0                          ; skip duplicate x = 0 on vertical axis
				beq.s   .skip_neg_x

				lea     (a2,d6.w),a1                ; Octant D (-x, 0)
				move.b  (a1),d4
				PLOT    (a0,d4.w),(a1)

.skip_neg_x:
				; Octants B,C,F,G - skip if x == y to avoid double plot
				cmp.w   d0,d1                       ; x == y
				beq.s   .step                       ; skip transposed octants

				tst.w   d1                          ; skip duplicate y = 0 on horizontal axis
				beq.s   .step

				lea     (a4,d7.w),a1                ; Octant C
				move.b  (a1),d4
				PLOT    (a0,d4.w),(a1)              ; remap and write

.step:
				lea     .continue(pc),a6
				bra     scu_step
.continue:
				bge     .loop

.done:
				; restore source coordinates
				movem.w (sp)+,d0-d2
				moveq	#QUADRANT_BIT_BR|QUADRANT_BIT_TL,d3
				CALLC   draw_SCUPartialClipped

				movem.l (sp)+,d4-d7/a2-a6
				rts


; Top Left Quarter Octants
;
;    \F | ./
;     \ | /
;   E  \|/  .
; ------o------
;   .  /|\  .
;     / | \
;    /. | .\

jump_SCU_TL:

.loop:
				; Octants A,D,E,H
				tst.w   d1                          ; y == 0?
				beq.s   .plot_y0_axis               ; at y = 0, a2 == a3, avoid double plot

				tst.w   d0                          ; skip duplicate x = 0 on vertical axis
				beq.s   .skip_neg_x

				lea     (a3,d6.w),a6                ; Octant E
				move.b  (a6),d5                     ; Octant E
				PLOT    (a0,d5.w),(a6)

.plot_y0_axis:

.skip_neg_x:
				; Octants B,C,F,G - skip if x == y to avoid double plot
				cmp.w   d0,d1                       ; x == y
				beq.s   .step                       ; skip transposed octants

				tst.w   d1                          ; skip duplicate y = 0 on horizontal axis
				beq.s   .step

				lea     (a5,d7.w),a6                ; Octant F
				move.b  (a6),d5
				PLOT    (a0,d5.w),(a6)

.step:
				lea     .continue(pc),a6
				bra     scu_step
.continue:
				bge     .loop


.done:
				; restore source coordinates
				movem.w (sp)+,d0-d2
				moveq	#QUADRANT_BIT_BL|QUADRANT_BIT_TR,d3
				CALLC   draw_SCUPartialClipped

				movem.l (sp)+,d4-d7/a2-a6
				rts

; Top Right Quarter Octants
;
;    \. | G/
;     \ | /
;   .  \|/  H
; ------o------
;   .  /|\  .
;     / | \
;    /. | .\

jump_SCU_TR:

.loop:
				; Octants A,D,E,H
				tst.w   d1                          ; y == 0?
				beq.s   .plot_y0_axis               ; at y = 0, a2 == a3, avoid double plot

				lea     (a3,d0.w),a6                ; Octant H
				move.b  (a6),d5                     ; Octant H
				PLOT    (a0,d5.w),(a6)

.plot_y0_axis:

.skip_neg_x:
				; Octants B,C,F,G - skip if x == y to avoid double plot
				cmp.w   d0,d1                       ; x == y
				beq.s   .step                       ; skip transposed octants

				lea     (a5,d1.w),a6                ; Octant G
				move.b  (a6),d5
				PLOT    (a0,d5.w),(a6)

.step:
				lea     .continue(pc),a6
				bra     scu_step
.continue:
				bge     .loop

.done:
				; restore source coordinates
				movem.w (sp)+,d0-d2
				moveq	#QUADRANT_BIT_TL|QUADRANT_BIT_BR,d3
				CALLC   draw_SCUPartialClipped

				movem.l (sp)+,d4-d7/a2-a6
				rts
