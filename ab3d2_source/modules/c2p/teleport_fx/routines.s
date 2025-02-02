

				section .data,data
				align 4
c2p_SetParamsTeleFxPtrs_vl:
				dc.l	c2p_SetParamsTeleFx			; 000
				dc.l	c2p_SetParamsTeleFx			; 001
				dc.l	c2p_SetParamsNull			; 010
				dc.l	c2p_SetParamsNull			; 011
				dc.l	c2p_SetParamsTeleFxFull		; 100
				dc.l	c2p_SetParamsTeleFxFull		; 101
				dc.l	c2p_SetParamsNull			; 110
				dc.l	c2p_SetParamsNull			; 111

c2p_ConvertTeleFxPtrs_vl:
				dc.l	c2p_Convert1xTeleFx			; 000
				dc.l	c2p_Convert1xTeleFx			; 001
				dc.l	c2p_ConvertNull				; 010
				dc.l	c2p_ConvertNull				; 011
				dc.l	c2p_Convert1xTeleFx			; 100
				dc.l	c2p_Convert1xTeleFx			; 101
				dc.l	c2p_ConvertNull				; 110
				dc.l	c2p_ConvertNull				; 111

				section	.text,code

c2p_SetParamsTeleFx:
				move.w	#7,Game_TeleportFrame_w				; Start a number of teleporter frames
				move.w	#(C2P_BPL_SMALL_ROWBYTES)-1,c2p_WTC_w	; width in chipmem?
				move.w	Vid_LetterBoxMarginHeight_w,d7
				move.l	#SMALL_HEIGHT-1,d1		; height of area to convert
				sub.w	d7,d1					; top letterbox
				sub.w	d7,d1					; bottom letterbox: d1: number of lines
				move.w	d1,c2p_HTC_Init_w
				move.w	#(SCREEN_WIDTH-SMALL_WIDTH),c2p_ChunkyModulus_w ; modulo chunky
				move.w	#(SCREEN_WIDTH-SMALL_WIDTH)/8,c2p_PlaneModulus_w ; modulo chipmem
				move.w	#SCREEN_WIDTH,d3
				mulu.w	d7,d3
				move.w	d3,c2p_ChunkyOffset_w
				move.w	#C2P_BPL_ROWBYTES,d3
				mulu.w	d7,d3					; offset for top letterbox in screenbuffer
				add.w	#(C2P_BPL_ROWBYTES)*20+(64/8),d3; top left corner of small render window in chipmem
				move.w	d3,c2p_PlanarOffset_w
				rts

c2p_SetParamsTeleFxFull:
				move.w	#7,Game_TeleportFrame_w				; Start a number of teleporter frames
				move.w	#(FS_WIDTH/8)-1,c2p_WTC_w		; width in chipmem?
				move.w	Vid_LetterBoxMarginHeight_w,d7
				move.l	#FS_C2P_HEIGHT-1,d1	; height of area to convert
				sub.w	d7,d1				; top letterbox
				sub.w	d7,d1				; bottom letterbox: d1: number of lines
				move.w	d1,c2p_HTC_Init_w
				clr.l	c2p_ChunkyModulus_w ; // clears both
				move.w	#SCREEN_WIDTH,d3
				mulu.w	d7,d3
				move.w	d3,c2p_ChunkyOffset_w
				move.w	#C2P_BPL_ROWBYTES,d3
				mulu.w	d7,d3					; offset for top letterbox in screenbuffer
				move.w	d3,c2p_PlanarOffset_w
				rts

; a0 src chunky ptr
; a1 dst chipmem ptr
; d0 number of pixels per line
; d1 number of lines
; d2 src modulo (offset from last pixel of previous line to start of next line)
; d3 dst modulo (offset in byte from last pixel to first pixel)
; d4 !=0 use doublewidth
; d5 !=0 use teleport effect


;*		Length	Cycles	Cyc/pix.
;*MainLoop	132 	508	63.5
;*Double Main	258 	1000	62.5
;
;*Seeing as we will probably be averaging at least 50000 pixels per "frame" any
;*cycle saving is significant


;a0 = byte pixels , a1 = plane 1
;256 colour / 8 bitplane


c2p_Convert1xTeleFx:
				move.w	c2p_HTC_Init_w,c2p_HTC_w
				move.l	Vid_FastBufferPtr_l,a0
				move.l	Vid_DrawScreenPtr_l,a1
				add.w	c2p_ChunkyOffset_w,a0
				add.w	c2p_PlanarOffset_w,a1


startchunkytel:
				movem.l	d2-d7/a2-a6,-(a7)
				move.l	#draw_TeleportShimmerFXData_vb,a6
				move.w	Game_TeleportFrame_w,d5
				asl.w	#8,d5
				asl.w	#2,d5
				add.w	d5,a6
				move.l	a6,c2p_StartShim_l
				movem.l	.Const(pc),d5-d7
				move.l	a1,a2
				adda.w	c2p_WTC_w,a2
				addq	#1,a2					; end of line to convert

				lea		2*C2P_BPL_SIZE(a1),a3;			Plane3
				lea		2*C2P_BPL_SIZE(a3),a4;			Plane5
				lea		2*C2P_BPL_SIZE(a4),a5;			Plane7

				bra.s	.BPPLoop

				align	4
.Const			dc.l	$0f0f0f0f,$55555555,$3333cccc

.BPPLoop:
				move.w	(a6)+,d0
				move.l	(a0,d0.w),d0			; 12 get next 4 chunky pixels in d0
				move.l	d0,d2					;  4
				move.l	(a6)+,d1
				and.l	d5,d2					;  8 d5=$0f0f0f0f
				eor.l	d2,d0					;  8
				move.l	4(a0,d1.w),d1			; 12 get next 4 chunky pixels in d1
				addq	#8,a0
; d0 = a7a6a5a4a3a2a1a0 b7b6b5b4b3b2b1b0 c7c6c5c4c3c2c1c0 d7d6d5d4d3d2d1d0
; d1 = e7e6e5e4e3e2e1e0 f7f6f5f4f3f2f1f0 g7g6g5g4g3g2g1g0 h7h6h5h4h3h2h1h0

				move.l	d1,d3					;  4
				and.l	d5,d3					;  8 d5=$0f0f0f0f
				eor.l	d3,d1					;  8
; d0 = a7a6a5a4........ b7b6b5b4........ c7c6c5c4........ d7d6d5d4........
; d1 = e7e6e5e4........ f7f6f5f4........ g7g6g5g4........ h7h6h5h4........
; d2 = ........a3a2a1a0 ........b3b2b1b0 ........c3c2c1c0 ........d3d2d1d0
; d3 = ........e3e2e1e0 ........f3f2f1f0 ........g3g2g1g0 ........h3h2h1h0

				lsl.l	#4,d2					; 16
				lsr.l	#4,d1					; 16
				or.l	d3,d2					;  8
				or.l	d1,d0					;  8
; d0 = a7a6a5a4e7e6e5e4 b7b6b5b4f7f6f5f4 c7c6c5c4g7g6g5g4 d7d6d5d4h7h6h5h4
; d2 = a3a2a1a0e3e2e1e0 b3b2b1b0f3f2f1f0 c3c2c1c0g3g2g1g0 d3d2d1d0h3h2h1h0

				move.l	d0,d1					;  4
				move.l	d2,d3					;  4
				and.l	d7,d1					;  8	;128
				and.l	d7,d3					;  8
				eor.l	d1,d0					;  8
				eor.l	d3,d2					;  8
				lsr.w	#2,d1					; 10
				lsr.w	#2,d3					; 10
				swap	d1						;  4
				swap	d3						;  4
				lsl.w	#2,d1					; 10
				lsl.w	#2,d3					; 10
; d0 = a7a6....e7e6.... b7b6....f7f6.... ....c5c4....g5g4 ....d5d4....h5h4
; d1 = ....c7c6....g7g6 ....d7d6....h7h6 a5a4....e5e4.... b5b4....f5f4....

				or.l	d1,d0					;  8
				or.l	d3,d2					;  8
; d0 = a7a6c7c6e7e6g7g6 b7b6d7d6f7f6h7h6 a5a4c5c4e5e4g5g4 b5b4d5d4f5f4h5h4 , d2=32/10

				move.l	d0,d1					;  4
				lsr.l	#7,d1					; 22
; d0 = a7a6c7c6e7e6g7g6 b7b6d7d6f7f6h7h6 a5a4c5c4e5e4g5g4 b5b4d5d4f5f4h5h4
; d1 = ..............a7 a6c7c6e7e6g7g6b7 b6d7d6f7f6h7h6a5 a4c5c4e5e4g5g4b5

				move.l	d0,d3					;  4
				move.l	d1,d4					;  4
				and.l	d6,d0					;  8	;258
				and.l	d6,d1					;  8
				eor.l	d0,d3					;  8
				eor.l	d1,d4					;  8
; d0 = ..a6..c6..e6..g6 ..b6..d6..f6..h6 ..a4..c4..e4..g4 ..b4..d4..f4..h4
; d3 = a7..c7..e7..g7.. b7..d7..f7..h7.. a5..c5..e5..g5.. b5..d5..f5..h5..
; d1 = ..............a7 ..c7..e7..g7..b7 ..d7..f7..h7..a5 ..c5..e5..g5..b5
; d4 = ................ a6..c6..e6..g6.. b6..d6..f6..h6.. a4..c4..e4..g4..

				or.l	d4,d0					;  8
				or.l	d3,d1					;  8
				lsr.l	#1,d1					; 10
; d0 = ..a6..c6..e6..g6 a6b6c6d6e6f6g6h6 b6a4d6c4f6e4h6g4 a4b4c4d4e4f4g4h4
; d1 = ..a7..c7..e7..g7 a7b7c7d7e7f7g7h7 b7a5d7c5f7e5h7g5 a5b5c5d5e5f5g5h5

				move.b	d1,C2P_BPL_SIZE(a4)			; 12 plane 6
				swap	d1						;  4
				move.b	d1,C2P_BPL_SIZE(a5)			; 12 plane 8
				move.b	d0,(a4)+				;  8 plane 5
				swap	d0						;  4
				move.b	d0,(a5)+				;  8 plane 7

				move.l	d2,d1					;  4
				lsr.l	#7,d1					; 22
; d2 = a3a2c3c2e3e2g3g2 b3b2d3d2f3f2h3h2 a1a0c1c0e1e0g1g0 b1b0d1d0f1f0h1h0
; d1 = ..............a3 a2c3c2e3e2g3g2b3 b2d3d2f3f2h3h2a1 a0c1c0e1e0g1g0b1

				move.l	d2,d3					;  4
				move.l	d1,d4					;  4
				and.l	d6,d2					;  8
				and.l	d6,d1					;  8
				eor.l	d2,d3					;  8
				eor.l	d1,d4					;  8
; d2 = ..a2..c2..e2..g2 ..b2..d2..f2..h2 ..a0..c0..e0..g0 ..b0..d0..f0..h0
; d3 = a3..c3..e3..g3.. b3..d3..f3..h3.. a1..c1..e1..g1.. b1..d1..f1..h1..
; d1 = ..............a3 ..c3..e3..g3..b3 ..d3..f3..h3..a1 ..c1..e1..g1..b1
; d4 = ................ a2..c2..e2..g2.. b2..d2..f2..h2.. a0..c0..e0..g0..

				or.l	d4,d2					;  8
				or.l	d3,d1					;  8
				lsr.l	#1,d1					; 10	;448
; d2 = ..a2..c2..e2..g2 a2b2c2d2e2f2g2h2 b2a0d2c0f2e0h2g0 a0b0c0d0e0f0g0h0
; d1 = ..a3..c3..e3..g3 a3b3c3d3e3f3g3h3 b3a1d3c1f3e1h3g1 a1b1c1d1e1f1g1h1
				move.b	d1,C2P_BPL_SIZE(a1)			; 12 plane 2
				swap	d1						;  4
				move.b	d1,C2P_BPL_SIZE(a3)			;  8 plane 4
				move.b	d2,(a1)+				;  8 plane 1
				swap	d2						;  4
				move.b	d2,(a3)+				;  8 plane 3 ;126 bytws
				cmpa.l	a1,a2					;  6
				bne		.BPPLoop				; 10

				move.l	a6,d0
				sub.l	c2p_StartShim_l,d0
				and.l	#255*2,d0
				add.l	c2p_StartShim_l,d0
				move.l	d0,a6

				move.w	c2p_PlaneModulus_w,d0
				add.w	d0,a1
				add.w	d0,a3
				add.w	d0,a4
				add.w	d0,a5
				move.w	c2p_WTC_w,d0
				lea		1(a1,d0.w),a2
				add.w	c2p_ChunkyModulus_w,a0
				subq.w	#1,c2p_HTC_w
				bge		.BPPLoop

				; Frame countdown
				subq.w	#1,Game_TeleportFrame_w
				bgt.s	.done

				clr.b	C2P_Teleporting_b
				st		C2P_NeedsInit_b

.done:
				movem.l	(a7)+,d2-d7/a2-a6
				rts

				align 4
c2p_StartShim_l:			dc.l	0
c2p_ChunkyOffset_w:			dc.w	0
c2p_PlanarOffset_w:			dc.w	0
c2p_HTC_Init_w:				dc.w	0
c2p_HTC_w:					dc.w	0
c2p_WTC_w:					dc.w	0
c2p_ChunkyModulus_w:		dc.w	0
c2p_PlaneModulus_w:			dc.w	0
Game_TeleportFrame_w:		dc.w	0




