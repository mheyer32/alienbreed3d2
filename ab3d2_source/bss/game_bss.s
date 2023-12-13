
			section .bss,bss

; BSS data - to be included in BSS section

			align 4

_game_Stats::
Game_Stats:
	ds.b GStatT_SizeOf_l ; see defs.i for structure
Game_StatsEnd:
