; ie_main.s - Intuition Engine VideoChip bootstrap (WIP)

	org $1000

	xdef start

start:
	; Enable IE video and select 640x480 mode.
	move.l	#1,$F0000
	move.l	#0,$F0004

	bsr	ie_mem_init
	bsr	ie_init

main_loop:
	bsr	ie_poll_input
	bsr	ie_palette_poll_update
	bsr	ie_present
	bsr	ie_wait_vblank
	bra.s	main_loop

	include "ie_hal.s"
	include "ie_input.s"
	include "ie_audio.s"
	include "ie_mem.s"
	include "ie_fileio.s"
	include "ie_present.s"
