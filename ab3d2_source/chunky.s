				; a0 src chunky ptr
				; a1 dst chipmem ptr
				; d0 number of pixels per line
				; d1 number of lines
				; d2 src modulo (offset from last pixel of previous line to start of next line)
				; d3 dst modulo (offset in byte from last pixel to first pixel)
				; d4 !=0 use doublewidth
				; d5 !=0 use teleport effect

				; HACK - This is a temporary fix until the root cause of the wall texture
				; perspective issues are properly understood.

FS_C2P_HEIGHT equ FS_HEIGHT-FS_HEIGHT_C2P_DIFF

Vid_ConvertC2P:
				tst.b	d5
				beq.s	.noteleffect

				move.w	#8,Game_TeleportFrame_w				; Start a number of teleporter frames

.noteleffect:
				tst.w	Game_TeleportFrame_w
				beq		.chunky_to_planar

				sub.w	#1,Game_TeleportFrame_w
				move.w	Game_TeleportFrame_w,d5

				bra		.chunky_to_planar_teleport_fx

.chunky_to_planar:
				tst.b	Vid_FullScreen_b
				beq		.smallscreen

				; fullscreen
				tst.b	Vid_DoubleWidth_b
				bne		.doublewidthFullscreen

				tst.b	Vid_DoubleHeight_b
				bne		.doubleheightFullscreen

				move.w	#SCREEN_WIDTH,d0
				move.w	Vid_LetterBoxMarginHeight_w,d3				; height of black border top/bottom
				move.w	#FS_C2P_HEIGHT,d1
				sub.w	d3,d1					; top letterbox
				sub.w	d3,d1					; bottom letterbox: d1: number of lines
				move.l	#(SCREEN_WIDTH/8)*256,d5
				jsr		c2p1x1_8_c5_040_init

				; scroffsy only accounts for the Y offset in the destination buffer
				move.l	Vid_FastBufferPtr_l,a0
				mulu.w	#SCREEN_WIDTH,d3
				lea		(a0,d3.w),a0
				move.l	Vid_DrawScreenPtr_l,a1
				jsr		c2p1x1_8_c5_040

.nothingLeft:
				rts

; d0.w	chunkyx [chunky-pixels] (even multiple of 32)
; d1.w	chunkyy [chunky-pixels]
; d2.w	scroffsx [screen-pixels] (even multiple of 8)
; d3.w	scroffsy [screen-pixels]
; d4.l	rowlen [bytes] -- offset between one row and the next in a bpl
; d5.l	bplsize [bytes] -- offset between one row in one bpl and the next bpl
; d6.l	chunkylen [bytes] -- offset between one row and the next in chunkybuffer

.doublewidthFullscreen:
				tst.b	Vid_DoubleHeight_b
				bne.s	.doublewidthheightFullscreen

				move.w	#FS_WIDTH/2,d0
				move.w	Vid_LetterBoxMarginHeight_w,d3				; height of black border top/bottom
				move.w	#FS_C2P_HEIGHT,d1
				sub.w	d3,d1					; top letterbox
				sub.w	d3,d1					; bottom letterbox: d1: number of lines
				moveq.l	#0,d2
				move.l	#SCREEN_WIDTH/8,d4
				move.l	#(SCREEN_WIDTH/8)*256,d5
				move.l	#SCREEN_WIDTH,d6
				jsr		c2p2x1_8_c5_gen_init

				; scroffsy only accounts for the Y offset in the destination buffer
				move.l	Vid_FastBufferPtr_l,a0
				mulu.w	d6,d3
				lea		(a0,d3.w),a0
				move.l	Vid_DrawScreenPtr_l,a1
				jsr		c2p2x1_8_c5_gen

				rts

.doublewidthheightFullscreen:
				move.w	#FS_WIDTH/2,d0
				move.w	Vid_LetterBoxMarginHeight_w,d3				; height of black border top/bottom
				move.w	#FS_C2P_HEIGHT/2,d1
				sub.w	d3,d1					; top letterbox
				sub.w	d3,d1					; bottom letterbox: d1: number of lines
				ble		.nothingLeft

				moveq.l	#0,d2
				move.l	#(SCREEN_WIDTH/8)*2,d4
				move.l	#(SCREEN_WIDTH/8)*256,d5
				move.l	#SCREEN_WIDTH*2,d6
				jsr		c2p2x1_8_c5_gen_init

				; scroffsy only accounts for the Y offset in the destination buffer
				move.l	Vid_FastBufferPtr_l,a0
				mulu.w	d6,d3
				lea		(a0,d3.w),a0
				move.l	Vid_DrawScreenPtr_l,a1
				jsr		c2p2x1_8_c5_gen

				rts


.doubleheightFullscreen:
				moveq.l	#0,d0					; x
				move.w	Vid_LetterBoxMarginHeight_w,d1				; y, height of black border top/bottom
				add.w	d1,d1
				move.l	#FS_WIDTH,d2			; width
				move.l	#FS_C2P_HEIGHT/2,d3			; height
				sub.w	d1,d3					; top letterbox
				sub.w	d1,d3					; bottom letterbox: d3: number of lines
				ble		.nothingLeft

				move.l	#SCREEN_WIDTH*2,d4		; chunkymod
				move.l	#(SCREEN_WIDTH/8)*2,d5	; bpl rowmod
				move.l	#(SCREEN_WIDTH/8)*256,d6	; bplsize
				move.l	Vid_FastBufferPtr_l,a0
				move.l	Vid_DrawScreenPtr_l,a1
				jsr		c2p_rect

				rts

.smallscreen:
				tst.b	Vid_DoubleWidth_b
				bne		.doublewidthSmallscreen
				tst.b	Vid_DoubleHeight_b
				bne		.doubleheightSmallscreen

				moveq.l	#0,d0					; x
				move.w	Vid_LetterBoxMarginHeight_w,d1				; y, height of black border top/bottom
				move.l	#SMALL_WIDTH,d2			; width
				move.l	#SMALL_HEIGHT,d3		; height
				sub.w	d1,d3					; top letterbox
				sub.w	d1,d3					; bottom letterbox: d3: number of lines
				move.l	#SCREEN_WIDTH,d4			; chunkymod
				move.l	#SCREEN_WIDTH/8,d5		; bpl rowmod
				move.l	#(SCREEN_WIDTH/8)*256,d6	; bplsize
				move.l	Vid_FastBufferPtr_l,a0
				move.l	Vid_DrawScreenPtr_l,a1
				add.l	#(SCREEN_WIDTH/8)*20+(64/8),a1 ; top of regular small screen
														; c2p_rect will apply d1 offset ontop
				jsr		c2p_rect

				rts

.doublewidthSmallscreen:
				tst.b	Vid_DoubleHeight_b
				bne.s	.doublewidthheightSmallscreen

				move.w	#SMALL_WIDTH/2,d0
				move.w	Vid_LetterBoxMarginHeight_w,d3				; height of black border top/bottom
				move.w	#SMALL_HEIGHT,d1
				sub.w	d3,d1					; top letterbox
				sub.w	d3,d1					; bottom letterbox: d1: number of lines
				moveq.l	#0,d2
				move.l	#SCREEN_WIDTH/8,d4
				move.l	#(SCREEN_WIDTH/8)*256,d5
				move.l	#SCREEN_WIDTH,d6
				jsr		c2p2x1_8_c5_gen_init

				; scroffsy only accounts for the Y offset in the destination buffer
				move.l	Vid_FastBufferPtr_l,a0
				mulu.w	d6,d3
				lea		(a0,d3.w),a0
				move.l	Vid_DrawScreenPtr_l,a1
				; top left of small render window in chipmem
				add.l	#(SCREEN_WIDTH/8)*20+(64/8),a1

				jsr		c2p2x1_8_c5_gen

				rts

.doublewidthheightSmallscreen:
				move.w	#SMALL_WIDTH/2,d0
				move.w	Vid_LetterBoxMarginHeight_w,d3				; height of black border top/bottom
				add.w	d3,d3
				move.w	#SMALL_HEIGHT/2,d1
				sub.w	d3,d1					; top letterbox
				sub.w	d3,d1					; bottom letterbox: d1: number of lines
				ble		.nothingLeft

				moveq.l	#0,d2
				move.l	#(SCREEN_WIDTH/8)*2,d4
				move.l	#(SCREEN_WIDTH/8)*256,d5
				move.l	#SCREEN_WIDTH*2,d6
				jsr		c2p2x1_8_c5_gen_init

				; scroffsy only accounts for the Y offset in the destination buffer
				move.l	Vid_FastBufferPtr_l,a0
				mulu.w	d6,d3
				lea		(a0,d3.w),a0
				move.l	Vid_DrawScreenPtr_l,a1
				; top left of small render window in chipmem
				add.l	#(SCREEN_WIDTH/8)*20+(64/8),a1

				jsr		c2p2x1_8_c5_gen

				rts

.doubleheightSmallscreen:
				moveq.l	#0,d0					; x
				move.w	Vid_LetterBoxMarginHeight_w,d1				; y, height of black border top/bottom
				add.w	d1,d1
				move.l	#SMALL_WIDTH,d2			; width
				move.l	#SMALL_HEIGHT/2,d3		; height
				sub.w	d1,d3					; top letterbox
				sub.w	d1,d3					; bottom letterbox: d3: number of lines
				ble		.nothingLeft

				move.l	#(SCREEN_WIDTH)*2,d4		; chunkymod
				move.l	#(SCREEN_WIDTH/8)*2,d5	; bpl rowmod
				move.l	#(SCREEN_WIDTH/8)*256,d6	; bplsize
				move.l	Vid_FastBufferPtr_l,a0
				move.l	Vid_DrawScreenPtr_l,a1
				add.l	#(SCREEN_WIDTH/8)*20+(64/8),a1 ; top of regular small screen
														; c2p_rect will apply d1 offset ontop
				jsr		c2p_rect

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


.chunky_to_planar_teleport_fx:
;a0 = byte pixels , a1 = plane 1
;256 colour / 8 bitplane

				; fullscreen
				tst.b	Vid_FullScreen_b
				beq		.smallscreenTele

				move.w	#(FS_WIDTH/8)-1,WTC		; width in chipmem?
				move.w	Vid_LetterBoxMarginHeight_w,d7

				move.l	#FS_C2P_HEIGHT-1,d1	; height of area to convert
				sub.w	d7,d1				; top letterbox
				sub.w	d7,d1				; bottom letterbox: d1: number of lines
				move.w	d1,HTC
				move.w	#(SCREEN_WIDTH-FS_WIDTH),MODUL ; modulo chunky
				move.w	#(SCREEN_WIDTH-FS_WIDTH)/8,SCRMOD ; modulo chipmem
				move.l	Vid_FastBufferPtr_l,a0
				move.w	#SCREEN_WIDTH,d3
				mulu.w	d7,d3
				lea		(a0,d3.w),a0			; offset for top letterbox in renderbuffer
				move.l	Vid_DrawScreenPtr_l,a1
				move.w	#(SCREEN_WIDTH/8),d3
				mulu.w	d7,d3					; offset for top letterbox in screenbuffer
				lea		(a1,d3.w),a1

				bra		.startchunkytel

.smallscreenTele:
				move.w	#(SMALL_WIDTH/8)-1,WTC	; width in chipmem?
				move.w	Vid_LetterBoxMarginHeight_w,d7
				move.l	#SMALL_HEIGHT-1,d1		; height of area to convert
				sub.w	d7,d1					; top letterbox
				sub.w	d7,d1					; bottom letterbox: d1: number of lines
				move.w	d1,HTC
				move.w	#(SCREEN_WIDTH-SMALL_WIDTH),MODUL ; modulo chunky
				move.w	#(SCREEN_WIDTH-SMALL_WIDTH)/8,SCRMOD ; modulo chipmem
				move.l	Vid_FastBufferPtr_l,a0
				move.w	#SCREEN_WIDTH,d3
				mulu.w	d7,d3
				lea		(a0,d3.w),a0			; offset for top letterbox in renderbuffer
				move.l	Vid_DrawScreenPtr_l,a1
				move.w	#(SCREEN_WIDTH/8),d3
				mulu.w	d7,d3					; offset for top letterbox in screenbuffer
				lea		(a1,d3.w),a1
				add.l	#(SCREEN_WIDTH/8)*20+(64/8),a1; top left corner of small render window in chipmem

.startchunkytel:
				movem.l	d2-d7/a2-a6,-(a7)
				move.l	#draw_TeleportShimmerFXData_vb,a6
				asl.w	#8,d5
				asl.w	#2,d5
				add.w	d5,a6
				move.l	a6,STARTSHIM
				movem.l	.Const(pc),d5-d7
				move.l	a1,a2
				adda.w	WTC,a2
				addq	#1,a2					; end of line to convert

				lea		2*40*256(a1),a3			Plane3
				lea		2*40*256(a3),a4			Plane5
				lea		2*40*256(a4),a5			Plane7

				bra.s	.BPPLoop
.Const			dc.l	$0f0f0f0f,$55555555,$3333cccc
				Cnop	0,4


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

				move.b	d1,40*256(a4)			; 12 plane 6
				swap	d1						;  4
				move.b	d1,40*256(a5)			; 12 plane 8
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
				move.b	d1,40*256(a1)			; 12 plane 2
				swap	d1						;  4
				move.b	d1,40*256(a3)			;  8 plane 4
				move.b	d2,(a1)+				;  8 plane 1
				swap	d2						;  4
				move.b	d2,(a3)+				;  8 plane 3 ;126 bytws
				cmpa.l	a1,a2					;  6
				bne		.BPPLoop				; 10

				move.l	a6,d0
				sub.l	STARTSHIM,d0
				and.l	#255*2,d0
				add.l	STARTSHIM,d0
				move.l	d0,a6

				move.w	SCRMOD,d0
				add.w	d0,a1
				add.w	d0,a3
				add.w	d0,a4
				add.w	d0,a5
				move.w	WTC,d0
				lea		1(a1,d0.w),a2
				add.w	MODUL,a0
				subq.w	#1,HTC
				bge		.BPPLoop

				movem.l	(a7)+,d2-d7/a2-a6
				rts

;DOUBWIDTHCHUNKTEL:
;				move.w	d2,MODUL
;				move.w	d0,WTC
;
;				move.w	d1,HTC
;				move.w	d3,SCRMOD
;
;				movem.l	d2-d7/a2-a6,-(a7)
;				movem.l	.Const(pc),d5-d7
;
;				move.l	a1,a2
;				adda.w	WTC,a2
;				addq	#1,a2					; end of line to convert
;
;				lea		40*256(a1),a3			Plane2
;				lea		2*40*256(a1),a4			Plane3
;				lea		2*40*256(a4),a5			Plane5
;				lea		2*40*256(a5),a6			Plane7
;				bra.s	.BPPLoop
;.Const			dc.l	$0f0f0f0f,$55555555,$3333cccc
;				Cnop	0,4
;
;
;.BPPLoop		move.l	(a0)+,d0				; 12 get next 4 chunky pixels in d0
;
;				and.l	#$ff00ff00,d0
;				move.l	d0,d2
;				lsr.l	#8,d2
;				or.l	d2,d0
;
;				move.l	d0,d2					;  4
;				and.l	d5,d2					;  8 d5=$0f0f0f0f
;				eor.l	d2,d0					;  8
;				move.l	(a0)+,d1				; 12 get next 4 chunky pixels in d1
;				and.l	#$ff00ff00,d1
;				move.l	d1,d3
;				lsr.l	#8,d3
;				or.l	d3,d1
;; d0 = a7a6a5a4a3a2a1a0 b7b6b5b4b3b2b1b0 c7c6c5c4c3c2c1c0 d7d6d5d4d3d2d1d0
;; d1 = e7e6e5e4e3e2e1e0 f7f6f5f4f3f2f1f0 g7g6g5g4g3g2g1g0 h7h6h5h4h3h2h1h0
;
;				move.l	d1,d3					;  4
;				and.l	d5,d3					;  8 d5=$0f0f0f0f
;				eor.l	d3,d1					;  8
;; d0 = a7a6a5a4........ b7b6b5b4........ c7c6c5c4........ d7d6d5d4........
;; d1 = e7e6e5e4........ f7f6f5f4........ g7g6g5g4........ h7h6h5h4........
;; d2 = ........a3a2a1a0 ........b3b2b1b0 ........c3c2c1c0 ........d3d2d1d0
;; d3 = ........e3e2e1e0 ........f3f2f1f0 ........g3g2g1g0 ........h3h2h1h0
;
;				lsl.l	#4,d2					; 16
;				lsr.l	#4,d1					; 16
;				or.l	d3,d2					;  8
;				or.l	d1,d0					;  8
;; d0 = a7a6a5a4e7e6e5e4 b7b6b5b4f7f6f5f4 c7c6c5c4g7g6g5g4 d7d6d5d4h7h6h5h4
;; d2 = a3a2a1a0e3e2e1e0 b3b2b1b0f3f2f1f0 c3c2c1c0g3g2g1g0 d3d2d1d0h3h2h1h0
;
;				move.l	d0,d1					;  4
;				move.l	d2,d3					;  4
;				and.l	d7,d1					;  8	;128
;				and.l	d7,d3					;  8
;				eor.l	d1,d0					;  8
;				eor.l	d3,d2					;  8
;				lsr.w	#2,d1					; 10
;				lsr.w	#2,d3					; 10
;				swap	d1						;  4
;				swap	d3						;  4
;				lsl.w	#2,d1					; 10
;				lsl.w	#2,d3					; 10
;; d0 = a7a6....e7e6.... b7b6....f7f6.... ....c5c4....g5g4 ....d5d4....h5h4
;; d1 = ....c7c6....g7g6 ....d7d6....h7h6 a5a4....e5e4.... b5b4....f5f4....
;
;				or.l	d1,d0					;  8
;				or.l	d3,d2					;  8
;; d0 = a7a6c7c6e7e6g7g6 b7b6d7d6f7f6h7h6 a5a4c5c4e5e4g5g4 b5b4d5d4f5f4h5h4 , d2=32/10
;
;				move.l	d0,d1					;  4
;				lsr.l	#7,d1					; 22
;; d0 = a7a6c7c6e7e6g7g6 b7b6d7d6f7f6h7h6 a5a4c5c4e5e4g5g4 b5b4d5d4f5f4h5h4
;; d1 = ..............a7 a6c7c6e7e6g7g6b7 b6d7d6f7f6h7h6a5 a4c5c4e5e4g5g4b5
;
;				move.l	d0,d3					;  4
;				move.l	d1,d4					;  4
;				and.l	d6,d0					;  8	;258
;				and.l	d6,d1					;  8
;				eor.l	d0,d3					;  8
;				eor.l	d1,d4					;  8
;; d0 = ..a6..c6..e6..g6 ..b6..d6..f6..h6 ..a4..c4..e4..g4 ..b4..d4..f4..h4
;; d3 = a7..c7..e7..g7.. b7..d7..f7..h7.. a5..c5..e5..g5.. b5..d5..f5..h5..
;; d1 = ..............a7 ..c7..e7..g7..b7 ..d7..f7..h7..a5 ..c5..e5..g5..b5
;; d4 = ................ a6..c6..e6..g6.. b6..d6..f6..h6.. a4..c4..e4..g4..
;
;				or.l	d4,d0					;  8
;				or.l	d3,d1					;  8
;				lsr.l	#1,d1					; 10
;; d0 = ..a6..c6..e6..g6 a6b6c6d6e6f6g6h6 b6a4d6c4f6e4h6g4 a4b4c4d4e4f4g4h4
;; d1 = ..a7..c7..e7..g7 a7b7c7d7e7f7g7h7 b7a5d7c5f7e5h7g5 a5b5c5d5e5f5g5h5
;
;				move.b	d1,40*256(a5)			; 12 plane 6
;				swap	d1						;  4
;				move.b	d1,40*256(a6)			; 12 plane 8
;				move.b	d0,(a5)+				;  8 plane 5
;				swap	d0						;  4
;				move.b	d0,(a6)+				;  8 plane 7
;
;				move.l	d2,d1					;  4
;				lsr.l	#7,d1					; 22
;; d2 = a3a2c3c2e3e2g3g2 b3b2d3d2f3f2h3h2 a1a0c1c0e1e0g1g0 b1b0d1d0f1f0h1h0
;; d1 = ..............a3 a2c3c2e3e2g3g2b3 b2d3d2f3f2h3h2a1 a0c1c0e1e0g1g0b1
;
;				move.l	d2,d3					;  4
;				move.l	d1,d4					;  4
;				and.l	d6,d2					;  8
;				and.l	d6,d1					;  8
;				eor.l	d2,d3					;  8
;				eor.l	d1,d4					;  8
;; d2 = ..a2..c2..e2..g2 ..b2..d2..f2..h2 ..a0..c0..e0..g0 ..b0..d0..f0..h0
;; d3 = a3..c3..e3..g3.. b3..d3..f3..h3.. a1..c1..e1..g1.. b1..d1..f1..h1..
;; d1 = ..............a3 ..c3..e3..g3..b3 ..d3..f3..h3..a1 ..c1..e1..g1..b1
;; d4 = ................ a2..c2..e2..g2.. b2..d2..f2..h2.. a0..c0..e0..g0..
;
;				or.l	d4,d2					;  8
;				or.l	d3,d1					;  8
;				lsr.l	#1,d1					; 10	;448
;; d2 = ..a2..c2..e2..g2 a2b2c2d2e2f2g2h2 b2a0d2c0f2e0h2g0 a0b0c0d0e0f0g0h0
;; d1 = ..a3..c3..e3..g3 a3b3c3d3e3f3g3h3 b3a1d3c1f3e1h3g1 a1b1c1d1e1f1g1h1
;				move.b	d1,(a3)+				; 12 plane 2
;				swap	d1						;  4
;				move.b	d1,40*256(a4)			;  8 plane 4
;				move.b	d2,(a1)+				;  8 plane 1
;				swap	d2						;  4
;				move.b	d2,(a4)+				;  8 plane 3 ;126 bytws
;				cmpa.l	a1,a2					;  6
;				bne		.BPPLoop				; 10
;
;				move.w	SCRMOD,d0
;				add.w	d0,a1
;				add.w	d0,a3
;				add.w	d0,a4
;				add.w	d0,a5
;				add.w	d0,a6
;				move.w	WTC,d0
;				lea		1(a1,d0.w),a2
;				add.w	MODUL,a0
;				subq.w	#1,HTC
;				bge		.BPPLoop
;
;				movem.l	(a7)+,d2-d7/a2-a6
;				rts

;USEDOUG:		dc.w	0

MODUL:			dc.w	0
HTC:			dc.w	0
WTC:			dc.w	0
SCRMOD:			dc.w	0
Game_TeleportFrame_w:			dc.w	0

SCREENPTRFLIG:	dc.l	0

STARTSHIM:		dc.l	0
;draw_TeleportShimmerFXData_vb:		incbin	"includes/shimmerfile"
