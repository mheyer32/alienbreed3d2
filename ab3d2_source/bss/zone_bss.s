
			section .bss,bss

; BSS data - to be included in BSS section
			align 4
Zone_BrightTable_vl:			ds.l	300

; Zone ordering
Zone_EndOfListPtr_l:			ds.l	1
zone_ToDrawTable_vw:			ds.w	400*2	; originally declared as 400 long, accessed as word
zone_OrderTable_vw:				ds.w	400*2	; originally declared as 400 long, accessed as word
Zone_OrderTable_Barrier_w:		ds.w	1 		; needs initialisation to -1
Zone_FinalOrderTable_vw:		ds.w	400*2
zone_FinalOrderTableBarrier_w:	ds.w	1 		; deliniates end of table

			align 4
Zone_BackdropDisable_vb:		ds.b	256		; todo - this needs to be defined
