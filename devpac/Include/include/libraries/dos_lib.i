_LVOOpen	EQU	-30
_LVOClose	EQU	-36
_LVORead	EQU	-42
_LVOWrite	EQU	-48
_LVOInput	EQU	-54
_LVOOutput	EQU	-60
_LVOSeek	EQU	-66
_LVODeleteFile	EQU	-72
_LVORename	EQU	-78
_LVOLock	EQU	-84
_LVOUnLock	EQU	-90
_LVODupLock	EQU	-96
_LVOExamine	EQU	-102
_LVOExNext	EQU	-108
_LVOInfo	EQU	-114
_LVOCreateDir	EQU	-120
_LVOCurrentDir	EQU	-126
_LVOIoErr	EQU	-132
_LVOCreateProc	EQU	-138
_LVOExit	EQU	-144
_LVOLoadSeg	EQU	-150
_LVOUnLoadSeg	EQU	-156
_LVODeviceProc	EQU	-174
_LVOSetComment	EQU	-180
_LVOSetProtection	EQU	-186
_LVODateStamp	EQU	-192
_LVODelay	EQU	-198
_LVOWaitForChar	EQU	-204
_LVOParentDir	EQU	-210
_LVOIsInteractive	EQU	-216
_LVOExecute	EQU	-222

CALLDOS	MACRO
	move.l	_DOSBase,a6
	jsr	_LVO\1(a6)
	ENDM
