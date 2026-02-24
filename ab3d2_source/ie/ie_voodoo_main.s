; ie_voodoo_main.s - Intuition Engine Voodoo bootstrap (WIP)

	org $1000

start:
	; Video init remains required for present path/compositor.
	move.l	#1,$F0000
	move.l	#0,$F0004

	; TODO: initialize Voodoo MMIO state and submit test geometry.
main_loop:
	bra.s	main_loop
