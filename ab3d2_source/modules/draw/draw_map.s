
MAP_SOLID_WALL_PEN	EQU	255
MAP_STEP_WALL_PEN	EQU 254

					align 4
draw_BaseMapTransparencyPtr_l:	ds.l	1

DoTheMapWotNastyCharlesIsForcingMeToDo:


				; 0xABADCAFE - Fixme - make these assignable and remember to clear the keys
				; as the zoom speed is insane under emulations

				move.l	Draw_TexturePalettePtr_l,a4
				add.l	#256*25,a4 ; glare offset
				move.l	a4,draw_BaseMapTransparencyPtr_l

				; add.w Draw_MapZoomLevel_w,a4

				move.l	#KeyMap_vb,a5

				tst.b	RAWKEY_NUM_ENTER(a5)
				beq.s	.skip_render_toggle

				clr.b	RAWKEY_NUM_ENTER(a5)
				not.b	draw_MapTransparent_b

.skip_render_toggle:
				tst.b	RAWKEY_F1(a5)			; Zoom In
				beq.s	.skip_zoom_in

				clr.b	RAWKEY_F1(a5)

				tst.w	Draw_MapZoomLevel_w
				beq.s	.skip_zoom_in

				sub.w	#1,Draw_MapZoomLevel_w

.skip_zoom_in:
				tst.b	RAWKEY_F2(a5)			; Zoom Out
				beq.s	.skip_zoom_out

				clr.b	RAWKEY_F2(a5)

				cmp.w	#7,Draw_MapZoomLevel_w
				bge.s	.skip_zoom_out

				add.w	#1,Draw_MapZoomLevel_w

.skip_zoom_out:
				move.l	#Rotated_vl,a1
				move.l	#Lvl_CompactMap_vl,a2
				move.l	#Lvl_BigMap_vl-40,a3

pre_show:
				add.w	#40,a3

show_map:
				move.l	(a2)+,d5
				move.l	a2,d7
				cmp.l	LastZonePtr_l,d7
				bgt		shown_map

				tst.l	d5
				beq.s	pre_show

				move.w	#9,d7

walls_of_zone:
				asr.l	#1,d5
				bcs.s	wall_seen

				asr.l	#1,d5
				bcs.s	wall_mapped

				asr.l	#1,d5
				addq	#4,a3
				bra		decided_wall

wall_mapped:
				move.w	#$b00,d4
				asr.l	#1,d5
				bcc.s	.not_a_door

				move.w	#$e00,d4

.not_a_door:
				bra.s	decided_colour

wall_seen:
				move.l	draw_BaseMapTransparencyPtr_l,a4
				move.w	#MAP_SOLID_WALL_PEN,d4
				asr.l	#2,d5
				bcc.s	.not_a_door

				move.w	#MAP_STEP_WALL_PEN,d4
				add.w	#256*2,a4 ; 2 steps more transparent

.not_a_door:
decided_colour:
				move.w	(a3)+,d6
				move.l	(a1,d6.w*8),d0
				asr.l	#7,d0
				movem.l	d7/d5,-(a7)
				move.w	draw_MapXOffset_w,d5
				ext.l	d5
				add.l	d5,d0
				move.l	4(a1,d6.w*8),d1
				move.w	draw_MapZOffset_w,d5
				ext.l	d5
				add.l	d5,d1
				move.w	(a3)+,d6
				move.l	(a1,d6.w*8),d2
				move.w	draw_MapXOffset_w,d5
				ext.l	d5
				asr.l	#7,d2
				add.l	d5,d2
				move.l	4(a1,d6.w*8),d3
				move.w	draw_MapZOffset_w,d5
				ext.l	d5
				add.l	d5,d3
				neg.l	d1
				neg.l	d3
				bsr		draw_MapClipAndDraw

				movem.l	(a7)+,d7/d5

				; 0xABADCAFE - TODO - Knowing if a wall is a door may help PVS in future
decided_wall:
				dbra	d7,walls_of_zone
				bra		show_map


				; FIXME: why does map rendering have an effect on wall rendering?
shown_map:
				; Is this drawing the Arrow?
				;move.w	draw_MapXOffset_w,d0
				;move.w	draw_MapZOffset_w,d1
				;neg.w	d1
				;move.w	d0,d2
				;move.w	d1,d3
				;sub.w	#128,d1
				;add.w	#128,d3
				;move.w	#250,d4
				;bsr		draw_MapClipAndDraw

				move.w	draw_MapXOffset_w,d0
				move.w	draw_MapZOffset_w,d1
				neg.w	d1
				move.w	d0,d2
				move.w	d1,d3
				sub.w	#64-32,d1
				sub.w	#32-32,d3
				sub.w	#64,d2
				move.w	#250,d4
				bsr		draw_MapClipAndDraw

				move.w	draw_MapXOffset_w,d0
				move.w	draw_MapZOffset_w,d1
				neg.w	d1
				move.w	d0,d2
				move.w	d1,d3
				sub.w	#64-32,d1
				sub.w	#32-32,d3
				add.w	#64,d2
				move.w	#250,d4
				bsr		draw_MapClipAndDraw

				rts

draw_MapClipAndDraw:
				; d0 x1
				; d1 y1
				; d2 x2
				; d3 y2
				tst.b	Vid_FullScreen_b
				beq.s	.nodov

				; This is scaling the coordinates by 3/5 for Fullscreen (used to be 2/3 for 288 wide)
				; For 320 wide, we are have a 3/5 ratio rather than 2/3
				; use an 11 bit approximation based on 1229/2048
				move.l d1,-(sp) ; todo - find a free register
				move.w #1229,d1
				muls  d1,d0 ; 320 * 3/5 = 192
				muls  d1,d2
				move.l #11,d1
				asr.l d1,d0
				asr.l d1,d2
				move.l (sp)+,d1

.nodov:
				tst.b	Vid_DoubleWidth_b				; correct aspect ratio for DW/DH
				beq.s	.no_double_width

				asr.w	#1,d0
				asr.w	#1,d2

.no_double_width:
				tst.b	Vid_DoubleHeight_b
				;beq.s	.no_double_height         ; 0xABADCAFE - commented out to avoid branch converted to nop
				;asr.w	#1,d1					; DOUBLEHIGHT renderbuffer is still full height
				;asr.w	#1,d3

.no_double_height:
				move.w	Draw_MapZoomLevel_w,d5			; is this the map zoom?
				asr.w	d5,d0					; I guess, this achieves X*0.5 + 0.5 for centered map rendering?
				asr.w	d5,d1
				asr.w	d5,d2
				asr.w	d5,d3

no_scaling:
				add.w	Vid_CentreX_w,d0
				bge		p1xpos

				add.w	Vid_CentreX_w,d2
				blt		map_offscreen

x1nx2p:			;		X1<0					X2>0, clip against X=0
				move.w	d2,d6
				sub.w	d0,d6					; dx
				beq		map_offscreen				; dx == 0?

				move.w	d3,d5
				sub.w	d1,d5					; dy
				muls.w	d0,d5					; x1 * dy
				divs.w	d6,d5					; x1 * dy / dx
				sub.w	d5,d1					; y1 = y1 - x * dy / dx
				moveq.l	#0,d0					; x1 = 0
				bra		done_left_clip

p1xpos:
				add.w	Vid_CentreX_w,d2
				bge		done_left_clip

				move.w	d0,d6
				sub.w	d2,d6					; dx
				ble		map_offscreen				; dx == 0?

				move.w	d1,d5
				sub.w	d3,d5					; dy
				muls.w	d2,d5					; x2 * dy
				divs.w	d6,d5					; x2 * dy / dx
				sub.w	d5,d3					; y2 = y2 - x2 * dy / dx
				moveq.l	#0,d2					; x2 == 0

done_left_clip:
				cmp.w	Vid_RightX_w,d0
				blt		p1xneg

				cmp.w	Vid_RightX_w,d2
				bge		map_offscreen

				move.w	d0,d6
				sub.w	d2,d6					; dx
				beq		map_offscreen

				move.w	d3,d5
				sub.w	d1,d5					; dy

				sub.w	Vid_RightX_w,d0
				addq.w	#1,d0

				muls.w	d5,d0					; dy * (rightx -x1)
				divs.w	d6,d0					; (dy * (rightx -x1))/dx
				add.w	d0,d1					; y1 + (dy * (rightx -x1))/dx = y1 + dy/dx * (rightx - x1)
				move.w	Vid_RightX_w,d0
				subq.w	#1,d0
				bra		done_right_clip

p1xneg:
				cmp.w	Vid_RightX_w,d2
				blt		done_right_clip

				move.w	d2,d6
				sub.w	d0,d6
				ble		map_offscreen

				sub.w	Vid_RightX_w,d2
				addq.w	#1,d2
				move.w	d1,d5
				sub.w	d3,d5

				muls.w	d5,d2
				divs.w	d6,d2
				add.w	d2,d3
				move.w	Vid_RightX_w,d2
				subq.w	#1,d2

done_right_clip:
				add.w	TOTHEMIDDLE,d1
				bge		p1ypos

				add.w	TOTHEMIDDLE,d3
				blt		map_offscreen

				move.w	d3,d6
				sub.w	d1,d6
				ble		map_offscreen

				move.w	d2,d5
				sub.w	d0,d5
				muls.w	d1,d5
				divs.w	d6,d5
				sub.w	d5,d0
				moveq.l	#0,d1
				bra		done_top_clip

p1ypos:
				add.w	TOTHEMIDDLE,d3
				bge		done_top_clip
;Vid_CentreY_w
				move.w	d1,d6
				sub.w	d3,d6
				ble		map_offscreen

				move.w	d0,d5
				sub.w	d2,d5
				muls.w	d3,d5
				divs.w	d6,d5
				sub.w	d5,d2
				moveq.l	#0,d3

done_top_clip:
				cmp.w	Vid_BottomY_w,d1
				blt		p1yneg

				cmp.w	Vid_BottomY_w,d3
				bge		map_offscreen

				move.w	d1,d6
				sub.w	d3,d6
				ble		map_offscreen

				sub.w	Vid_BottomY_w,d1
				addq.w	#1,d1
				move.w	d2,d5
				sub.w	d0,d5
				muls.w	d5,d1
				divs.w	d6,d1
				add.w	d1,d0
				move.w	Vid_BottomY_w,d1
				subq.w	#1,d1
				bra		done_bottom_clip

p1yneg:
				cmp.w	Vid_BottomY_w,d3
				blt		done_bottom_clip

				move.w	d3,d6
				sub.w	d1,d6
				ble		map_offscreen

				sub.w	Vid_BottomY_w,d3
				addq.w	#1,d3
				move.w	d0,d5
				sub.w	d2,d5
				muls.w	d5,d3
				divs.w	d6,d3
				add.w	d3,d2
				move.w	Vid_BottomY_w,d3
				subq.w	#1,d3

done_bottom_clip:
				; Transparent drawing does work, but is somewhat broken
				; TODO - come back and fix. Probably needs a better pen choice for the
				; transparency blending as well as the transformation fixes.

				bra		draw_MapLine

Draw_MapZoomLevel_w:	dc.w	3
draw_MapXOffset_w:		dc.w	0
draw_MapZOffset_w:		dc.w	0
draw_MapTransparent_b:	dc.w	0

map_offscreen:
no_line:
				rts

draw_MapLine:
;				move.b	Vid_DoubleHeight_b,d5
;				or.b	Vid_DoubleWidth_b,d5
;				tst.b	d5
;				bne		draw_MapLineDoubleWidth

				move.l	Vid_FastBufferPtr_l,a0			; screen to render to.
				cmp.w	d1,d3
				bgt.s	.okdown

				bne.s	.aline

				cmp.w	d0,d2
				beq.s	no_line

.aline:
				exg		d0,d2
				exg		d1,d3

.okdown:
				move.w	d1,d5
				muls	#SCREEN_WIDTH,d5
				add.l	d5,a0
				lea		(a0,d0.w),a0

				sub.w	d1,d3

				sub.w	d0,d2
				bge.s	down_right

down_left:
				neg.w	d2
				cmp.w	d2,d3
				bgt.s	down_more_left

down_left_more:
				move.w	#SCREEN_WIDTH,d6
				move.w	d2,d0
				move.w	d2,d7
				addq	#1,a0

				tst.b	draw_MapTransparent_b
				bne.s	.line_loop_transparent

.line_loop:		; regular solid colour mode
				move.b	d4,-(a0)

				sub.w	d3,d0
				bgt.s	.no_extra

				add.w	d2,d0
				add.w	d6,a0

.no_extra:
				dbra	d7,.line_loop

				rts

.line_loop_transparent:
				move.b	-(a0),d4		; read chunky buffer
				move.b	(a4,d4.w),(a0)	; Replace and write back

				sub.w	d3,d0
				bgt.s	.no_extra_transparent

				add.w	d2,d0
				add.w	d6,a0

.no_extra_transparent:
				dbra	d7,.line_loop_transparent

				rts



down_more_left:
				move.w	#SCREEN_WIDTH,d6
				move.w	d3,d0
				move.w	d3,d7

				tst.b	draw_MapTransparent_b
				bne.s	.line_loop_transparent

.line_loop:		; regular solid colour mode
				move.b	d4,(a0)

				add.w	d6,a0
				sub.w	d2,d0
				bgt.s	.no_extra

				add.w	d3,d0
				subq	#1,a0

.no_extra:
				dbra	d7,.line_loop

				rts


.line_loop_transparent:
				move.b	(a0),d4			; read chunky buffer
				move.b	(a4,d4.w),(a0)	; Replace and write back

				add.w	d6,a0
				sub.w	d2,d0
				bgt.s	.no_extra_transparent

				add.w	d3,d0
				subq	#1,a0

.no_extra_transparent:
				dbra	d7,.line_loop_transparent

				rts

down_right:
				cmp.w	d2,d3
				bgt.s	down_more_right

down_right_more:
				move.w	#SCREEN_WIDTH,d6
				move.w	d2,d0
				move.w	d2,d7

				tst.b	draw_MapTransparent_b
				bne.s	.line_loop_transparent

.line_loop:		; regular solid colour mode
				move.b	d4,(a0)+
				sub.w	d3,d0
				bgt.s	.no_extra

				add.w	d2,d0
				add.w	d6,a0

.no_extra:
				dbra	d7,.line_loop

				rts


.line_loop_transparent:
				move.b	(a0),d4			; read chunky buffer
				move.b	(a4,d4.w),(a0)+	; Replace and write back

				sub.w	d3,d0
				bgt.s	.no_extra_transparent

				add.w	d2,d0
				add.w	d6,a0

.no_extra_transparent:
				dbra	d7,.line_loop_transparent

				rts

down_more_right:
				move.w	#SCREEN_WIDTH,d6
				move.w	d3,d0
				move.w	d3,d7

				tst.b	draw_MapTransparent_b
				bne.s	.line_loop_transparent

.line_loop:		; regular solid colour mode
				move.b	d4,(a0)
				add.w	d6,a0
				sub.w	d2,d0
				bgt.s	.no_extra

				add.w	d3,d0
				addq	#1,a0

.no_extra:
				dbra	d7,.line_loop
				rts


.line_loop_transparent:
				move.b	(a0),d4			; read chunky buffer
				move.b	(a4,d4.w),(a0)	; Replace and write back

				add.w	d6,a0
				sub.w	d2,d0
				bgt.s	.no_extra_transparent
				add.w	d3,d0
				addq	#1,a0

.no_extra_transparent:
				dbra	d7,.line_loop_transparent
				rts


draw_MapLineDoubleWidth:
				move.l	Vid_FastBufferPtr_l,a0			; screen to render to.
				cmp.w	d1,d3
				bgt.s	.okdown

				bne.s	.aline

				cmp.w	d0,d2
				beq		no_line
.aline:
				exg		d0,d2
				exg		d1,d3

.okdown:
				move.w	d1,d5
				muls	#SCREEN_WIDTH,d5
				add.l	d5,a0
				lea		(a0,d0.w),a0
				sub.w	d1,d3
				sub.w	d0,d2
				bge		down_right_dw

down_left_dw:
				neg.w	d2
				cmp.w	d2,d3
				bgt.s	down_more_left_dw

down_left_more_dw:
				move.w	#SCREEN_WIDTH,d6
				move.w	d2,d0
				move.w	d2,d7
				addq	#1,a0

.line_loop:
				move.b	d4,SCREEN_WIDTH-1(a0)
				move.b	d4,(a0)
				move.b	d4,-(a0)
				sub.w	d3,d0
				bgt.s	.no_extra

				add.w	d2,d0
				add.w	d6,a0
.no_extra:
				dbra	d7,.line_loop

				rts

down_more_left_dw:
				move.w	#SCREEN_WIDTH,d6
				move.w	d3,d0
				move.w	d3,d7

.line_loop:
				move.b	d4,SCREEN_WIDTH(a0)
				move.b	d4,1(a0)
				move.b	d4,(a0)
				add.w	d6,a0
				sub.w	d2,d0
				bgt.s	.no_extra

				add.w	d3,d0
				subq	#1,a0

.no_extra:
				dbra	d7,.line_loop

				rts

downrightFAT:	; retained for posterity
down_right_dw:
				cmp.w	d2,d3
				bgt.s	down_more_right_dw

down_right_more_dw:
				move.w	#SCREEN_WIDTH,d6
				move.w	d2,d0
				move.w	d2,d7

.line_loop:
				move.b	d4,SCREEN_WIDTH(a0)
				move.b	d4,(a0)+
				move.b	d4,(a0)
				sub.w	d3,d0
				bgt.s	.no_extra

				add.w	d2,d0
				add.w	d6,a0
.no_extra:
				dbra	d7,.line_loop

				rts

down_more_right_dw:
				move.w	#SCREEN_WIDTH,d6
				move.w	d3,d0
				move.w	d3,d7

.line_loop:
				move.b	d4,SCREEN_WIDTH(a0)
				move.b	d4,1(a0)
				move.b	d4,(a0)
				add.w	d6,a0
				sub.w	d2,d0
				bgt.s	.no_extra

				add.w	d3,d0
				addq	#1,a0

.no_extra:
				dbra	d7,.line_loop

				rts

