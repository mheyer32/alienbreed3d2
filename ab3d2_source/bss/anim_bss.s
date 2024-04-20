
			section .bss,bss

; BSS data - to be included in BSS section
			align 4

Anim_BrightY_l:			ds.l	1
anim_MiddleRoom_l:		ds.l	1

; Union
Anim_DoorAndLiftLocks_l:	ds.w	1 ; MSW accessed as long
anim_LiftOnlyLocks_w:		ds.w	1 ; LSW accessed independently as word

; Word data
Anim_SplatType_w:		ds.w	1
anim_MiddleX_w:			ds.w	1
anim_MiddleZ_w:			ds.w	1
anim_DoneFlames_w:		ds.w	1

Anim_FramesToDraw_w:	ds.w	1
Anim_TempFrames_w:		ds.w	1
anim_TimeToNoise_w:		ds.w	1
anim_OddEven_w:			ds.w	1
anim_FloorMoveSpeed_w:	ds.w	1
Anim_BrightTable_vw:	ds.w	20
Anim_Timer_w:			ds.w	1
anim_ThisDoor_w:		ds.w	1
anim_OpeningSpeed_w:	ds.w	1
anim_ClosingSpeed_w:	ds.w	1
anim_OpenDuration_w:	ds.w	1
anim_OpeningSoundFX_w:	ds.w	1
anim_ClosingSoundFX_w:	ds.w	1
anim_OpenedSoundFX_w:	ds.w	1
anim_ClosedSoundFX_w:	ds.w	1
anim_ActionSoundFX_w:	ds.w	1
anim_MaxDamage_w:		ds.w	1
