; Common 68040 C2P logic. This code is based on Kalms optimised 030 C2P

				section	.text,code

				include "modules/c2p/68040/full1x1.s"
				include "modules/c2p/68040/c2p_rect.s"

				section	.text,code
				align 4

; These all end up using the c2p_rect code
; TODO - extract into variables and set only during SetParams
; d0.w	x [multiple of 32]
; d1.w	y
; d2.w	width [multiple of 32]
; d3.w	height
; d4.w	chunky rowmod
; d5.w	bpl rowmod
; d6.l	bplsize
; a0	chunky, upper-left corner of rect
; a1	bitplanes, upper-left corner of rect


c2p_SetParamsFull1x2Opt040:
				rts

c2p_SetParamsSmall1x1Opt040:
				rts

c2p_SetParamsSmall1x2Opt040:
				rts

c2p_ConvertFull1x2Opt040:
				movem.l	d2-d6,-(sp)

				moveq.l	#0,d0					; x
				move.w	Vid_LetterBoxMarginHeight_w,d1				; y, height of black border top/bottom
				move.l	#FS_WIDTH,d2			; width
				move.l	#FS_C2P_HEIGHT/2,d3		; height
				sub.w	d1,d3					; top letterbox
				sub.w	d1,d3					; bottom letterbox: d3: number of lines
				ble		.nothing

				move.l	#FS_WIDTH*2,d4		; chunkymod
				move.l	#(FS_WIDTH/8)*2,d5	; bpl rowmod
				move.l	#(FS_WIDTH/8)*256,d6	; bplsize
				move.l	Vid_FastBufferPtr_l,a0
				move.l	Vid_DrawScreenPtr_l,a1
				bsr		c2p_rect

.nothing:
				movem.l	(sp)+,d2-d6
				rts

c2p_ConvertSmall1x1Opt040:
				movem.l	d2-d6,-(sp)

				moveq.l	#0,d0					; x
				move.w	Vid_LetterBoxMarginHeight_w,d1				; y, height of black border top/bottom
				move.l	#SMALL_WIDTH,d2			; width
				move.l	#SMALL_HEIGHT,d3		; height
				sub.w	d1,d3					; top letterbox
				sub.w	d1,d3					; bottom letterbox: d3: number of lines
				ble		.nothing

				move.l	#FS_WIDTH,d4			; chunkymod
				move.l	#FS_WIDTH/8,d5		; bpl rowmod
				move.l	#(FS_WIDTH/8)*256,d6	; bplsize
				move.l	Vid_FastBufferPtr_l,a0
				move.l	Vid_DrawScreenPtr_l,a1
				add.l	#(FS_WIDTH/8)*20+(64/8),a1 ; top of regular small screen
														; c2p_rect will apply d1 offset ontop
				bsr		c2p_rect


.nothing:
				movem.l	(sp)+,d2-d6
				rts

c2p_ConvertSmall1x2Opt040:
				movem.l	d2-d6,-(sp)

				moveq.l	#0,d0					; x
				move.w	Vid_LetterBoxMarginHeight_w,d1				; y, height of black border top/bottom
				add.w	d1,d1
				move.l	#SMALL_WIDTH,d2			; width
				move.l	#SMALL_HEIGHT/2,d3		; height
				sub.w	d1,d3					; top letterbox
				sub.w	d1,d3					; bottom letterbox: d3: number of lines
				ble		.nothing

				move.l	#(FS_WIDTH)*2,d4		; chunkymod
				move.l	#(FS_WIDTH/8)*2,d5	; bpl rowmod
				move.l	#(FS_WIDTH/8)*256,d6	; bplsize
				move.l	Vid_FastBufferPtr_l,a0
				move.l	Vid_DrawScreenPtr_l,a1
				add.l	#(FS_WIDTH/8)*20+(64/8),a1 ; top of regular small screen
														; c2p_rect will apply d1 offset ontop
				bsr		c2p_rect
.nothing:
				movem.l	(sp)+,d2-d6
				rts