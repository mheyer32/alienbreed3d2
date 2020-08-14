_LVOGetWBObject	EQU	-30
_LVOPutWBObject	EQU	-36
_LVOGetIcon	EQU	-42
_LVOPutIcon	EQU	-48
_LVOFreeFreeList	EQU	-54
_LVOFreeWBObject	EQU	-60
_LVOAllocWBObject	EQU	-66
_LVOAddFreeList	EQU	-72
_LVOGetDiskObject	EQU	-78
_LVOPutDiskObject	EQU	-84
_LVOFreeDiskObject	EQU	-90
_LVOFindToolType	EQU	-96
_LVOMatchToolValue	EQU	-102
_LVOBumpRevision	EQU	-108

CALLICON	MACRO
	move.l	_IconBase,a6
	jsr	_LVO\1(a6)
	ENDM

ICONNAME	MACRO
	dc.b	'icon.library',0
	ENDM
