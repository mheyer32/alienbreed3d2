
			section bss,bss

; BSS data - to be included in BSS section
			align 4

; Ad hoc tables that we don't know where else to put yet.

PointBrights:			ds.l	1
CurrentPointBrights_vl:	ds.l	2*256*10
ClipsTable_vl:			ds.l	30
EndOfClipPtr_l:			ds.l	1

Rotated_vl:				ds.l	2*800	; store rotated X and Z coordinates with Z scaling applied
ObjRotated_vl_vl:		ds.l	2*500
OnScreen_vl:			ds.l	2*800	; store screen projected X coordinates for rotated points

walltiles:				ds.l	40

leftsidetab:			ds.w	512*2
rightsidetab:			ds.w	512*2
leftbrighttab:			ds.w	512*2
rightbrighttab:			ds.w	512*2

consttab:				ds.b	65536
