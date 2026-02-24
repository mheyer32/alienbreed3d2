; ie_voodoo_main.s - Intuition Engine Voodoo bootstrap

	org $1000

	xdef start
	xref ie_voodoo_init
	xref ie_voodoo_render_frame

start:
	; Enable IE compositor path.
	move.l	#1,$F0000
	move.l	#0,$F0004

	bsr	ie_mem_init
	bsr	ie_init
	bsr	ie_voodoo_init

main_loop:
	bsr	ie_game_frame
	bsr	ie_poll_input
	bsr	ie_voodoo_render_frame
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
	include "ie_voodoo_render.s"
	include "ie_compat.s"
