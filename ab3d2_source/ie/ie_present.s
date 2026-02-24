; ie_present.s - Intuition Engine present path (Mode7 blit stage)
; NOTE: palette index -> RGBA conversion is still pending.

	xdef ie_present_frame

ie_present_frame:
	; Mode7 upscale from RGBA scratch (320x240) to framebuffer (640x480).
	move.l	#5,$F0020		; BLT_OP = MODE7
	move.l	#$22C000,$F0024		; BLT_SRC
	move.l	#$100000,$F0028		; BLT_DST
	move.l	#640,$F002C		; BLT_WIDTH
	move.l	#480,$F0030		; BLT_HEIGHT
	move.l	#1280,$F0034		; BLT_SRC_STRIDE
	move.l	#2560,$F0038		; BLT_DST_STRIDE
	move.l	#0,$F0058		; U0
	move.l	#0,$F005C		; V0
	move.l	#$00008000,$F0060	; DU_COL
	move.l	#0,$F0064		; DV_COL
	move.l	#0,$F0068		; DU_ROW
	move.l	#$00008000,$F006C	; DV_ROW
	move.l	#511,$F0070		; TEX_W mask
	move.l	#255,$F0074		; TEX_H mask
	move.l	#1,$F001C		; BLT_CTRL start
	rts
