

Draw_Radar:
				; Pulse effect every 32 frame steps
				move.l Sys_FrameNumber_l,d0
				and.w  #$1f,d0
				move.w d0,d2
				move.w d0,d3

				; Determine basic radius based on frame step
				add.w  #1,d2  ;
				lsl.w  #2,d2
				sub.w  d0,d2  ; radius in steps of 3

				; Determine the shade level based on the frame step (16 levels)
				lsr.w  #1,d3
				add.w  #16,d3

				move.w  Draw_MapZoomLevel_w,d0
				and.b   #7,d0
				move.w  d0,a0

				move.w  draw_MapXOffset_w,d0

				; Fullscreen aspect ratio fix for 288 -> 320
				tst.b   Vid_FullScreen_b
				beq.s   .no_aspect

				muls.w #1229,d0
				moveq  #11,d1
				asr.l  d1,d0

.no_aspect:
				move.w	draw_MapZOffset_w,d1
				neg.w	d1

				; Depending on the zoom level we need to scale
				; the coordinates and radius.
				move.w  .jump(pc,a0.w*2),a0
				jmp     .jump(pc,a0.w)
.jump:
				dc.w	.level_0-.jump
				dc.w	.level_1-.jump
				dc.w	.level_2-.jump
				dc.w	.level_3-.jump
				dc.w	.level_4-.jump
				dc.w	.level_5-.jump
				dc.w	.level_6-.jump
				dc.w	.level_7-.jump

.level_1:
				lsl.w   #2,d2  ; radius in steps of 12
				asr.w   #1,d0
				asr.w   #1,d1
				bra.s  .draw

.level_2:
				lsl.w   #1,d2  ; radius in steps of 6
				asr.w   #2,d0
				asr.w   #2,d1
				bra.s  .draw

.level_3:
				asr.w	#3,d0
				asr.w   #3,d1
				bra.s   .draw

.level_4:
				lsr.w   #1,d2
				asr.w   #4,d0
				asr.w   #4,d1
				bra.s   .draw

.level_5:
				lsr.w   #2,d2
				asr.w   #5,d0
				asr.w   #5,d1
				bra.s   .draw

.level_6:
				lsr.w   #3,d2
				asr.w   #6,d0
				asr.w   #6,d1



.draw:
				add.w   Vid_CentreX_w,d0
				add.w   Vid_CentreY_w,d1
				bra     Draw_CircleShaded

; skip on
.level_7:
.level_0:
				rts

				include "modules/draw/draw_circle.s"
