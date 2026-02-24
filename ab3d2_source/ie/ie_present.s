; ie_present.s - Intuition Engine present path
;
; Layout:
;   chunky8  @ 0x060000 (320x240, 1 byte/pixel)
;   pal_rgba @ 0x073000 (256 * 4 bytes, prebuilt RGBA LUT)
;   scratch  @ 0x22C000 (320x240, 4 bytes/pixel)
;   fb       @ 0x100000 (640x480, 4 bytes/pixel)

	xdef ie_present_frame
	xdef ie_palette_init
	xdef ie_palette_upload_12bit
	xdef ie_palette_upload_rgb8
	xdef ie_palette_set_rgb8_ptr
	xdef ie_palette_set_texture_ptr
	xdef _ie_palette_set_texture_ptr
	xdef ie_palette_poll_update
	xdef ie_palette_mark_dirty
	xdef Vid_LoadMainPalette
	xdef _Vid_LoadMainPalette
	xdef Vid_UpdatePalette_b
	xdef Draw_TexturePalettePtr_l

CHUNKY_BASE	equ	$060000
PALETTE_BASE	equ	$073000
SCRATCH_BASE	equ	$22C000
FRAMEBUF_BASE	equ	$100000

PIXELS_320x240	equ	76800

ie_palette_init:
	; Build a default grayscale RGBA LUT at 0x073000.
	; Game palette loading will overwrite this later.
	move.l	#PALETTE_BASE,a0
	moveq	#0,d0

.pal_loop:
	move.l	d0,d1
	lsl.l	#8,d1
	or.l	d0,d1
	lsl.l	#8,d1
	or.l	d0,d1
	lsl.l	#8,d1
	ori.l	#$FF,d1
	move.l	d1,(a0)+
	addq.l	#1,d0
	cmpi.l	#256,d0
	bne.s	.pal_loop
	rts

; ie_palette_upload_12bit
; in: a0 -> 256 x 16-bit palette entries (Amiga format 0x0RGB, 4 bits/channel)
; out: writes converted RGBA8888 LUT to PALETTE_BASE
ie_palette_upload_12bit:
	move.l	#PALETTE_BASE,a1
	move.w	#255,d7

.pal12_loop:
	move.w	(a0)+,d0

	; R nibble -> 8-bit in d1
	move.w	d0,d1
	lsr.w	#8,d1
	andi.w	#$000F,d1
	move.w	d1,d2
	lsl.w	#4,d1
	or.w	d2,d1

	; G nibble -> 8-bit in d3
	move.w	d0,d3
	lsr.w	#4,d3
	andi.w	#$000F,d3
	move.w	d3,d2
	lsl.w	#4,d3
	or.w	d2,d3

	; B nibble -> 8-bit in d4
	move.w	d0,d4
	andi.w	#$000F,d4
	move.w	d4,d2
	lsl.w	#4,d4
	or.w	d2,d4

	; Pack RGBA = (R<<24)|(G<<16)|(B<<8)|0xFF
	moveq	#0,d5
	move.b	d1,d5
	lsl.l	#8,d5
	move.b	d3,d5
	lsl.l	#8,d5
	move.b	d4,d5
	lsl.l	#8,d5
	ori.l	#$000000FF,d5
	move.l	d5,(a1)+

	dbra	d7,.pal12_loop
	rts

; ie_palette_upload_rgb8
; in: a0 -> 256 RGB entries, packed as 768 bytes: R,G,B,R,G,B,...
; out: writes converted RGBA8888 LUT to PALETTE_BASE
ie_palette_upload_rgb8:
	move.l	#PALETTE_BASE,a1
	move.w	#255,d7

.pal8_loop:
	moveq	#0,d1
	moveq	#0,d3
	moveq	#0,d4
	move.b	(a0)+,d1	; R
	move.b	(a0)+,d3	; G
	move.b	(a0)+,d4	; B

	moveq	#0,d5
	move.b	d1,d5
	lsl.l	#8,d5
	move.b	d3,d5
	lsl.l	#8,d5
	move.b	d4,d5
	lsl.l	#8,d5
	ori.l	#$000000FF,d5
	move.l	d5,(a1)+

	dbra	d7,.pal8_loop
	rts

; ie_palette_set_rgb8_ptr
; in: a0 -> RGB triplet palette source (768 bytes)
ie_palette_set_rgb8_ptr:
	move.l	a0,ie_palette_rgb8_ptr
	rts

; Set Draw_TexturePalettePtr_l and request a palette refresh.
; in: a0 -> RGB8 palette table (768 bytes)
ie_palette_set_texture_ptr:
_ie_palette_set_texture_ptr:
	move.l	a0,Draw_TexturePalettePtr_l
	st		Vid_UpdatePalette_b
	rts

ie_palette_mark_dirty:
	st		Vid_UpdatePalette_b
	rts

ie_palette_poll_update:
	tst.b	Vid_UpdatePalette_b
	beq.s	.no_update
	clr.b	Vid_UpdatePalette_b
	bsr		Vid_LoadMainPalette
.no_update:
	rts

; Compatibility entrypoint for existing game-side call sites.
; Uses the configured RGB8 source pointer when available.
Vid_LoadMainPalette:
_Vid_LoadMainPalette:
	move.l	ie_palette_rgb8_ptr,a0
	tst.l	a0
	bne.s	.have_src
	move.l	Draw_TexturePalettePtr_l,a0
	tst.l	a0
	bne.s	.have_src
	bsr		ie_palette_init
	rts
.have_src:
	tst.l	a0
	beq.s	.no_src_fallback
	bsr		ie_palette_upload_rgb8
	rts
.no_src_fallback:
	bsr		ie_palette_init
	rts

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

ie_palette_rgb8_ptr:
	dc.l	0

Vid_UpdatePalette_b:
	dc.b	0
	dc.b	0
	dc.b	0
	dc.b	0

Draw_TexturePalettePtr_l:
	dc.l	0
