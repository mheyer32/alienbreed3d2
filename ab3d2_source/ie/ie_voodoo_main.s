; ie_voodoo_main.s - Intuition Engine Voodoo bootstrap (WIP)

	org $1000

	xdef start

start:
	; Enable IE video/compositor path.
	move.l	#1,$F0000
	move.l	#0,$F0004

	; Enable Voodoo engine.
	move.l	#1,$F4004

	bsr	ie_init

main_loop:
	bsr	ie_poll_input

	; Temporary Voodoo frame loop: clear + swap.
	move.l	#0,$F4124
	move.l	#1,$F4128

	bsr	ie_wait_vblank
	bra.s	main_loop

	include "ie_hal.s"
	include "ie_input.s"
	include "ie_audio.s"
	include "ie_fileio.s"
	include "ie_present.s"
