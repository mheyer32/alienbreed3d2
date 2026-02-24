; ie_main.s - Intuition Engine VideoChip bootstrap (WIP)

	org $1000

start:
	; Enable IE video and select 640x480 mode.
	move.l	#1,$F0000
	move.l	#0,$F0004

main_loop:
	; TODO: call ie_hal / game loop entry.
	bra.s	main_loop
