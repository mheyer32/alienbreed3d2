
			section .bss,bss

; BSS data - to be included in BSS section

			align 4

_Game_ProgressSignal::
Game_ProgressSignal_l	ds.l 1 ; cleared at the start of every frame and checked at the end

_game_PlayerProgression::
game_PlayerProgression:
	ds.b GStatT_SizeOf_l ; see defs.i for structure
game_PlayerProgressionEnd:
