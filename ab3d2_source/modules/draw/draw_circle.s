
; Outcode bits for clipping
OUTCODE_POS_LEFT	EQU 0
OUTCODE_POS_RIGHT	EQU 1
OUTCODE_POS_TOP		EQU 2
OUTCODE_POS_BOTTOM	EQU 3
OUTCODE_BIT_LEFT	EQU 1<<OUTCODE_POS_LEFT
OUTCODE_BIT_RIGHT	EQU 1<<OUTCODE_POS_RIGHT
OUTCODE_BIT_TOP		EQU 1<<OUTCODE_POS_TOP
OUTCODE_BIT_BOTTOM	EQU 1<<OUTCODE_POS_BOTTOM

; Quadrant bits for incomplete clipped circles
QUADRANT_BIT_BR		EQU 1
QUADRANT_BIT_BL		EQU 2
QUADRANT_BIT_TL		EQU 4
QUADRANT_BIT_TR		EQU 8
QUADRANT_MASK       EQU 15

; Params
; d0.w centreX
; d1.w centreY
; d2.w radius
; d3.w shade (0 - 31 white to normal, 32-63 normal to black)
;
; NOTE: does not preserve d0-d3,a0,a1
;

Draw_CircleShaded:
				; Trivially reject for r not in range 1-512
				tst.w   d2
				bgt.s   .check_big

.early_exit:
				rts

.check_big:
				; nope
				cmp.w   #512,d2
				bge.s   .early_exit

;				; hackity hack
;				and.l   #$3f,d3
;				lsl.l   #8,d3                              ; 256 bytes per slice
;				add.l   Draw_PaletteShadeTablePtr_l,d3
;				move.l  d3,a0                              ; a0 = shade
;				CALLC   draw_SCUPartialClipped
;				rts


				; Next decide if we are fully inside the viewport to use fully unclipped path.
				; After that, we can use Sutherland-Cohen style outcode style clipping against view edges.
.decide_path:
				;if (
				;   x - radius >= 0 && x + radius < Vid_RightX_w &&
				;   y - radius >= 0 && y + radius < Vid_BottomY_w
				;)

				swap    d3 ; use upper half for arithmetic temporary

.check_inside_left:
				move.w  d0,d3
				sub.w   d2,d3 ; x - radius
				blt.s   .not_fully_inside

.check_inside_right:
				move.w  d0,d3
				add.w   d2,d3    ; x + radius
				cmp.w   Vid_RightX_w,d3 ; x + radius
				bge.s   .not_fully_inside

.check_inside_top:
				move.w  d1,d3
				sub.w   d2,d3   ; y - radius
				blt.s   .not_fully_inside

.check_inside_bottom:
				move.w  d1,d3
				add.w   d2,d3
				cmp.w   Vid_BottomY_w,d3
				bge.s   .not_fully_inside

				; We are fully inside the view rectangle, no clipping needed.
.fully_inside:
				; restore shadeval in d3.w and we are good to go
				swap   d3
				bra    draw_ShadeCircleUnclipped

				; We are not fully inside the view rectangle so we need to ensure
				; we aren't completely outside it either before we go down the
				; clipping path.
.not_fully_inside:
				;else if (
				;    x + radius >= 0 && x - radius < Vid_RightX_w &&
				;    y + radius >= 0 && y - radius < Vid_BottomY_w
				;)

.check_left:
				move.w  d0,d3
				add.w   d2,d3 ; x + radius
				blt     .fully_outside

.check_right:
				move.w  d0,d3
				sub.w   d2,d3
				cmp.w   Vid_RightX_w,d3 ; x - radius
				bge     .fully_outside

.check_top:
				move.w  d1,d3
				add.w   d2,d3   ; y + radius
				blt     .fully_outside

.check_bottom:
				move.w  d1,d3
				sub.w   d2,d3 ; y - radius
				cmp.w   Vid_BottomY_w,d3
				bge     .fully_outside

.clipped:
				; Determine where the centre of the circle is. We can use Sutherland-Cohen style
				; outcode calculation here.

				; shade level is still in upper word.
				clr.w   d3

				; CENTRE OUTCODE

				; Test 0 <= x < Vid_RightX_w
				tst.w   d0
				bpl.s   .not_left

				bset    #OUTCODE_POS_LEFT,d3

.not_left:
				cmp.w   Vid_RightX_w,d0
				blt.s   .not_right

				bset    #OUTCODE_POS_RIGHT,d3

				; Test 0 <= y < Vid_BottomY_w
.not_right:
				tst.w   d1
				bpl.s   .not_top
				bset    #OUTCODE_POS_TOP,d3
.not_top:
				cmp.w   Vid_BottomY_w,d1
				blt.s   .not_bottom
				bset    #OUTCODE_POS_BOTTOM,d3
.not_bottom:

				tst.w	d3
				bne.s	.centre_outside

				; TODO - Outcode test for the circle edge here.
				;        When the circle centre is inside, some quadrants
				;        can be fully unclipped. For example, if the left
				;        extent crosses the left edge only, the entire
				;        right hand octants of the circle can be rendered
				;        totally unclipped and only the left hand octants
				;        need to use the clipped path.

				; d3.w is already zero here ...


				; Test 0 <= x - radius
.centre_inside:
				move.l  d4,a0
				move.w  d0,d4
				sub.w   d2,d4 ; x - radius
				bpl.s   .left_inside

				bset    #OUTCODE_POS_LEFT,d3

				; Test x + radius < Vid_RightX_w
.left_inside:
				move.w  d0,d4
				add.w   d2,d4 ; x + radius
				cmp.w   Vid_RightX_w,d4
				blt.s   .right_inside

				bset    #OUTCODE_POS_RIGHT,d3

				; Test 0 <= y - radius
.right_inside:
				move.w  d1,d4
				sub.w   d2,d4 ; y - radius
				bpl.s   .top_inside

				bset    #OUTCODE_POS_TOP,d3

				; Test y + radius < Vid_BottomY_w
.top_inside:
				move.w  d1,d4
				add.w   d2,d4 ; y + radius
				cmp.w   Vid_BottomY_w,d4
				blt.s   .bottom_inside

				bset    #OUTCODE_POS_BOTTOM,d3

.bottom_inside:
				IFD DEV
				move.w  d3,dev_Reserved2_w
				ENDIF

				; restore d4
				move.l a0,d4
				bra     jump_SCUPartialUnclipped


.centre_outside:
				; When the circle centre is outside, any quadrants we need to determine an outcode
				; so that we know which quadrants to draw.
				IFD DEV
				move.w  #101,dev_Reserved2_w
				ENDIF

				; Get the shade slice into a0 to free up d3 for the quadrant code
				swap    d3
				and.l   #$3f,d3
				lsl.l   #8,d3                              ; 256 bytes per slice
				add.l   Draw_PaletteShadeTablePtr_l,d3
				move.l  d3,a0                              ; a0 = shade

				; Now calculate which quadrants to render based on the centre outcode
				moveq	#QUADRANT_MASK,d3

.check_centre_off_left:
				tst.w	d0
				bge.s	.check_centre_off_right

				; clear left quadrants
				andi.w	#~(QUADRANT_BIT_BL|QUADRANT_BIT_TL),d3

.check_centre_off_right:
				cmp.w	Vid_RightX_w,d0
				blt.s   .check_centre_off_top

				; clear right quadrants
				andi.w	#~(QUADRANT_BIT_TR|QUADRANT_BIT_BR),d3

.check_centre_off_top:
				tst.w	d1
				bge.s	.check_centre_off_bottom

				; clear top quadrants
				andi.w	#~(QUADRANT_BIT_TL|QUADRANT_BIT_TR),d3

.check_centre_off_bottom:
				cmp.w	Vid_BottomY_w,d1
				blt.s   .all_checked

				; clear bottom quadrants
				andi.w	#~(QUADRANT_BIT_BL|QUADRANT_BIT_BR),d3

.all_checked:
				CALLC   draw_SCUPartialClipped

				rts
.fully_outside:
				IFD DEV
				move.w  #202,dev_Reserved2_w
				ENDIF

				; Nothing to do
				swap d3
				rts

; Plotting macros. In order to validate each pixel is plotted once, define VALIDATE_PIXEL_ONCE
; which chages the plotting mode to a straight increment. Test against a flat background shade.

				IFD VALIDATE_PIXEL_ONCE
PLOT			MACRO
				add.b #32,\2 ; Increment the buffer
				ENDM
				ELSE
PLOT			MACRO
				move.b  \1,\2 ; Write value to the buffer
				ENDM
				ENDIF

				include "modules/draw/circle/unclipped_inside.s"
				include "modules/draw/circle/unclipped_partials.s"

; Called from C init. Sorts out the small circle tables
	DCLC	draw_InitCircleTable
				movem.l d2/a2,-(sp)

				lea     draw_SmallCicleList_vw,a0
				lea     draw_EndSmallCicleList,a1
				lea     draw_RenderBufferStrideTable_vl,a2
				clr.l   d0

				; Convert the -y,x byte pair ordinates in draw_SmallCicleList_vw to signed 16-bit pointer
				; offsets for use in the small circle code path. We use the stride table which is already
				; set up for the width multiplication.
.pair:
				move.b  (a0),d0         ; (positive) y-offset in d0
				move.w  2(a2,d0.w*4),d1 ; fetch the low 16-bits of the 32-bit stride index for the y component.
				move.b  1(a0),d2        ; (signed) x-offset in d2
				ext.w   d2              ; sign extend
				sub.w   d1,d2           ; offset = x - y*stride
				move.w  d2,(a0)+        ; store the (signed) offset
				cmp.l   a0,a1
				bhi.s   .pair

				movem.l (sp)+,d2/a2
				rts
