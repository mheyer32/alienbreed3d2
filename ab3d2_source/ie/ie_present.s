; ie_present.s - Intuition Engine present path
;
; Layout:
;   chunky8  @ 0x060000 (320x240, 1 byte/pixel)
;   pal_rgba @ 0x073000 (256 * 4 bytes, prebuilt RGBA LUT)
;   scratch  @ 0x22C000 (320x240, 4 bytes/pixel)
;   fb       @ 0x100000 (640x480, 4 bytes/pixel)

	xdef ie_present_frame

CHUNKY_BASE	equ	$060000
PALETTE_BASE	equ	$073000
SCRATCH_BASE	equ	$22C000
FRAMEBUF_BASE	equ	$100000

PIXELS_320x240	equ	76800

ie_present_frame:
	; 1) Convert indexed chunky buffer -> RGBA scratch using LUT.
	move.l	#CHUNKY_BASE,a0
	move.l	#SCRATCH_BASE,a1
	move.l	#PALETTE_BASE,a2
	move.l	#PIXELS_320x240,d7

.convert_loop:
	moveq	#0,d0
	move.b	(a0)+,d0
	lsl.l	#2,d0
	move.l	0(a2,d0.l),(a1)+
	subq.l	#1,d7
	bne.s	.convert_loop

	; 2) Mode7 upscale from 320x240 scratch -> 640x480 framebuffer.
	move.l	#5,$F0020		; BLT_OP = MODE7
	move.l	#SCRATCH_BASE,$F0024	; BLT_SRC
	move.l	#FRAMEBUF_BASE,$F0028	; BLT_DST
	move.l	#640,$F002C		; BLT_WIDTH
	move.l	#480,$F0030		; BLT_HEIGHT
	move.l	#1280,$F0034		; BLT_SRC_STRIDE (320 * 4)
	move.l	#2560,$F0038		; BLT_DST_STRIDE (640 * 4)
	move.l	#0,$F0058		; U0
	move.l	#0,$F005C		; V0
	move.l	#$00008000,$F0060	; DU_COL (0.5)
	move.l	#0,$F0064		; DV_COL
	move.l	#0,$F0068		; DU_ROW
	move.l	#$00008000,$F006C	; DV_ROW (0.5)
	move.l	#511,$F0070		; TEX_W mask
	move.l	#255,$F0074		; TEX_H mask
	move.l	#1,$F001C		; BLT_CTRL start
	rts
