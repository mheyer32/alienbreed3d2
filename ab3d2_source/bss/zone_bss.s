
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

		DCLC Zone_VisJoins_w,	ds.w,	1
		DCLC Zone_TotJoins_w,	ds.w,	1
		DCLC Zone_EdgeClipIndexes_vw, ds.w, 2

		DCLC Zone_EdgePointIndexes_vw, ds.w, 32

		DCLC Zone_PVSList_vw,   ds.w,    512
		DCLC Zone_PVSMask_vb,   ds.b,    512
			align 4


; Bitmask
EDGE_POINT_ID_LIST_END EQU -4
ZONE_BACKDROP_DISABLE_SIZE  EQU LVL_EXPANDED_MAX_ZONE_COUNT/8

Zone_BackdropDisable_vb:		ds.b	ZONE_BACKDROP_DISABLE_SIZE
