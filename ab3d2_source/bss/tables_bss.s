
			section bss,bss

; BSS data - to be included in BSS section
			align 4

; Ad hoc tables that we don't know where else to put yet.

PointBrightsPtr_l:		ds.l	1
CurrentPointBrights_vl:	ds.l	2*256*10
ClipsTable_vl:			ds.l	30
EndOfClipPtr_l:			ds.l	1

Rotated_vl:				ds.l	2*800	; store rotated X and Z coordinates with Z scaling applied
ObjRotated_vl:			ds.l	2*500
OnScreen_vl:			ds.l	2*800	; store screen projected X coordinates for rotated points

ZoneBrightTable_vl:		ds.l	300

ConstantTable_vl:		ds.l	8192

LeftSideTable_vw:		ds.w	512*2
RightSideTable_vw:		ds.w	512*2
LeftBrightTable_vw:		ds.w	512*2
RightBrightTable_vw:	ds.w	512*2

anim_LiftHeightTable_vw:	ds.w	40 ; newanims.s
anim_DoorHeightTable_vw:	ds.w	40 ; newanims.s

KeyMap_vb:				ds.b	256
