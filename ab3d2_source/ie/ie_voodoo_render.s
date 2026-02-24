; ie_voodoo_render.s - Intuition Engine Voodoo frame renderer

	xdef ie_voodoo_init
	xdef ie_voodoo_render_frame
	xdef ie_voodoo_frame_counter_l

VOODOO_ENABLE			equ	$00F4004
VOODOO_VERTEX_AX		equ	$00F4008
VOODOO_VERTEX_AY		equ	$00F400C
VOODOO_VERTEX_BX		equ	$00F4010
VOODOO_VERTEX_BY		equ	$00F4014
VOODOO_VERTEX_CX		equ	$00F4018
VOODOO_VERTEX_CY		equ	$00F401C
VOODOO_START_R			equ	$00F4020
VOODOO_START_G			equ	$00F4024
VOODOO_START_B			equ	$00F4028
VOODOO_START_Z			equ	$00F402C
VOODOO_START_A			equ	$00F4030
VOODOO_TRIANGLE_CMD		equ	$00F4080
VOODOO_FBZ_COLOR_PATH	equ	$00F4104
VOODOO_ALPHA_MODE		equ	$00F410C
VOODOO_FBZ_MODE			equ	$00F4110
VOODOO_CLIP_LEFT_RIGHT	equ	$00F4118
VOODOO_CLIP_LOW_Y_HIGH	equ	$00F411C
VOODOO_FAST_FILL_CMD	equ	$00F4124
VOODOO_SWAP_BUFFER_CMD	equ	$00F4128
VOODOO_COLOR0			equ	$00F41D8
VOODOO_VIDEO_DIM		equ	$00F4214

; fbzMode bits used here:
; clipping + depth enable + depth func LESS + rgb write + depth write + draw back
VOODOO_FBZ_MODE_DEFAULT	equ	$00008631
; Color combine: pass through iterated (vertex) color
VOODOO_COLOR_PATH_ITERATED	equ	$00000040

ie_voodoo_init:
	; 640x480 render target and engine enable.
	move.l	#$028001E0,VOODOO_VIDEO_DIM
	move.l	#1,VOODOO_ENABLE

	; Clip rectangle uses exclusive right/bottom bounds.
	move.l	#((0<<16)|640),VOODOO_CLIP_LEFT_RIGHT
	move.l	#((0<<16)|480),VOODOO_CLIP_LOW_Y_HIGH

	move.l	#VOODOO_COLOR_PATH_ITERATED,VOODOO_FBZ_COLOR_PATH
	move.l	#0,VOODOO_ALPHA_MODE
	move.l	#VOODOO_FBZ_MODE_DEFAULT,VOODOO_FBZ_MODE
	clr.l	ie_voodoo_frame_counter_l
	rts

ie_voodoo_render_frame:
	; Clear color+depth every frame via FAST_FILL.
	move.l	#$00101010,VOODOO_COLOR0
	move.l	#0,VOODOO_FAST_FILL_CMD

	; Triangle A: farther blue background wedge.
	move.l	#(0<<4),VOODOO_VERTEX_AX
	move.l	#(0<<4),VOODOO_VERTEX_AY
	move.l	#(640<<4),VOODOO_VERTEX_BX
	move.l	#(0<<4),VOODOO_VERTEX_BY
	move.l	#(320<<4),VOODOO_VERTEX_CX
	move.l	#(470<<4),VOODOO_VERTEX_CY
	move.l	#0,VOODOO_START_R
	move.l	#0,VOODOO_START_G
	move.l	#$00001000,VOODOO_START_B
	move.l	#$00001800,VOODOO_START_Z
	move.l	#$00001000,VOODOO_START_A
	move.l	#0,VOODOO_TRIANGLE_CMD

	; Triangle B: nearer red wedge to confirm depth ordering.
	move.l	#(120<<4),VOODOO_VERTEX_AX
	move.l	#(80<<4),VOODOO_VERTEX_AY
	move.l	#(560<<4),VOODOO_VERTEX_BX
	move.l	#(120<<4),VOODOO_VERTEX_BY
	move.l	#(320<<4),VOODOO_VERTEX_CX
	move.l	#(420<<4),VOODOO_VERTEX_CY
	move.l	#$00001000,VOODOO_START_R
	move.l	#0,VOODOO_START_G
	move.l	#0,VOODOO_START_B
	move.l	#$00000800,VOODOO_START_Z
	move.l	#$00001000,VOODOO_START_A
	move.l	#0,VOODOO_TRIANGLE_CMD

	move.l	#1,VOODOO_SWAP_BUFFER_CMD
	addq.l	#1,ie_voodoo_frame_counter_l
	rts

ie_voodoo_frame_counter_l:
	dc.l	0
