; ie_voodoo_main.s - Intuition Engine Voodoo bootstrap (WIP)

	org $1000

	xdef start

start:
	; Enable IE video/compositor path.
	move.l	#1,$F0000
	move.l	#0,$F0004

	; Configure Voodoo output dimensions (640x480) and enable engine.
	move.l	#$028001E0,$F4214
	move.l	#1,$F4004

	bsr	ie_mem_init
	bsr	ie_init

main_loop:
	bsr	ie_poll_input

	; Clear to black via COLOR0 + FAST_FILL.
	move.l	#0,$F41D8
	move.l	#0,$F4124

	; Flat red triangle (12.4 coords, 12.12 color, 20.12 depth).
	move.l	#$00000640,$F4008	; AX = 100
	move.l	#$00000320,$F400C	; AY = 50
	move.l	#$00001900,$F4010	; BX = 400
	move.l	#$00000640,$F4014	; BY = 100
	move.l	#$00000A00,$F4018	; CX = 160
	move.l	#$00001400,$F401C	; CY = 320

	move.l	#$00001000,$F4020	; R = 1.0
	move.l	#0,$F4024		; G = 0.0
	move.l	#0,$F4028		; B = 0.0
	move.l	#$00000800,$F402C	; Z = 0.5
	move.l	#$00001000,$F4030	; A = 1.0

	move.l	#0,$F4080		; TRIANGLE_CMD
	move.l	#1,$F4128		; SWAP_BUFFER_CMD (vsync)

	bsr	ie_wait_vblank
	bra	main_loop

	include "ie_hal.s"
	include "ie_input.s"
	include "ie_audio.s"
	include "ie_mem.s"
	include "ie_fileio.s"
	include "ie_res.s"
	include "ie_game.s"
	include "ie_present.s"
