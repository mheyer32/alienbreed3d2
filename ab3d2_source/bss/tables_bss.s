
			section bss,bss

; BSS data - to be included in BSS section
			align 4

; Ad hoc tables that we don't know where else to put yet.

PointBrights:			ds.l	1
CurrentPointBrights:	ds.l	2*256*10
ClipTable:				ds.l	30
EndOfClipPt:			ds.l	1

Rotated:				ds.l	2*800	; store rotated X and Z coordinates with Z scaling applied
ObjRotated_vl:			ds.l	2*500
OnScreen:				ds.l	2*800	; store screen projected X coordinates for rotated points


leftsidetab:			ds.w	512*2
rightsidetab:			ds.w	512*2
leftbrighttab:			ds.w	512*2
rightbrighttab:			ds.w	512*2

consttab:				ds.b	65536
