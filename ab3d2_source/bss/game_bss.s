
			section .bss,bss

; BSS data - to be included in BSS section

; Game modification defaults

			align 4
			DCLC GMod_Defaults, ds.b, GDefT_SizeOf_l

			align 4
			DCLC GMod_Progress, ds.b, PPrgT_SizeOf_l

			align 4
_Game_ProgressSignal::
Game_ProgressSignal_l:			ds.l 1 ; cleared at the start of every frame and checked at the end

_game_BestLevelTimeBuffer::
game_BestLevelTimeBuffer_vb:	ds.b LVLT_MESSAGE_LENGTH
