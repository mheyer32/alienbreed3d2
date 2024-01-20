
			section .bss,bss

; BSS data - to be included in BSS section
			align 4

; Globals used in more than one source file are considered public and are capitalised.
; Globals used in one file is considered private and is not capitalised. The file should be
; noted as a comment. As the code is refactored these could change and should be updated
; accordingly.

; TODO Analyse the usage patterns of these fields and work out if any of the temp/snap versions
; are better off placed closer (cache line)

; READY PLAYER ONE !

; Long data
Plr1_Data:
Plr1_ObjectPtr_l:			ds.l	1
Plr1_XOff_l:				ds.l	1 ; sometimes accessed as w - todo understand real size
Plr1_YOff_l:				ds.l	1
Plr1_ZOff_l:				ds.l	1 ; sometimes accessed as w - todo understand real size
Plr1_ZonePtr_l:				ds.l	1
Plr1_Height_l:				ds.l	1
Plr1_AimSpeed_l:			ds.l	1
Plr1_SnapXOff_l:			ds.l	1
Plr1_SnapYOff_l:			ds.l	1
Plr1_SnapYVel_l:			ds.l	1
Plr1_SnapZOff_l:			ds.l	1
Plr1_SnapTYOff_l:			ds.l	1
Plr1_SnapXSpdVal_l:			ds.l	1
Plr1_SnapZSpdVal_l:			ds.l	1
Plr1_SnapHeight_l:			ds.l	1
Plr1_SnapTargHeight_l: 		ds.l	1
Plr1_TmpXOff_l:				ds.l	1 ; also accessed as w, todo determine correct size
Plr1_TmpZOff_l:				ds.l	1 ; suspect 16:16
Plr1_TmpYOff_l:				ds.l	1

; Private fields
plr1_ListOfGraphRoomsPtr_l:	ds.l	1 ; hires.s
plr1_PointsToRotatePtr_l:	ds.l	1 ; hires.s
plr1_BobbleY_l:				ds.l	1 ; hires.s
plr1_TmpHeight_l:			ds.l	1 ; hires.s
plr1_OldX_l:				ds.l	1 ; hires.s
plr1_OldZ_l:				ds.l	1 ; hires.s
plr1_OldRoomPtr_l:			ds.l	1 ; leveldata2.s - write once?
plr1_SnapSquishedHeight_l:	ds.l	1 ; plr1control.s
plr1_DefaultEnemyFlags_l:	ds.l	1

; Word data
Plr1_Energy_w:				ds.w	1
Plr1_CosVal_w:				ds.w	1
Plr1_SinVal_w:				ds.w	1
Plr1_AngPos_w:				ds.w	1
_Plr1_Zone::
Plr1_Zone_w:				ds.w	1
Plr1_FloorSpd_w:			ds.w	1
Plr1_RoomBright_w: 			ds.w	1
Plr1_Bobble_w:				ds.w	1
Plr1_SnapAngPos_w:			ds.w	1
Plr1_SnapAngSpd_w:			ds.w	1
Plr1_TmpAngPos_w:			ds.w	1
Plr1_TimeToShoot_w:			ds.w	1

; CAUTION This section is loaded/saved and must not be reordered
_Plr1_Inventory::
Plr1_Invetory_vw:
Plr1_Health_w:				ds.w	1
Plr1_JetpackFuel_w:			ds.w	1
Plr1_AmmoCounts_vw:			ds.w	20
Plr1_Shield_w:				ds.w	1
Plr1_Jetpack_w:				ds.w	1

_Plr1_Weapons_vb::
Plr1_Weapons_vb:			ds.w	10 ; todo - convert to bytes or bitfield

Plr1_GunFrame_w:			ds.w	1
Plr1_NoiseVol_w:			ds.w	1

; Private fields
plr1_TmpHoldDown_w:			ds.w	1 ; hires.s
plr1_TmpBobble_w:			ds.w	1 ; hires.s

plr1_SnapCosVal_w:			ds.w	1 ; plr1control.s
plr1_SnapSinVal_w:			ds.w	1 ; plr1control.s

plr1_WalkSFXTime_w:			ds.w	1 ; fall.s

; Byte data
Plr1_Keys_b:				ds.b	1
Plr1_Path_b:				ds.b	1

Plr1_Mouse_b:				ds.b	1
Plr1_Joystick_b:			ds.b	1
Plr1_GunSelected_b: 		ds.b	1
Plr1_StoodInTop_b: 			ds.b	1

Plr1_Ducked_b:				ds.b	1
Plr1_Squished_b:			ds.b	1
Plr1_Echo_b:				ds.b	1
Plr1_Fire_b:				ds.b	1

Plr1_Clicked_b:				ds.b    1
Plr1_Used_b:				ds.b	1
Plr1_TmpClicked_b:			ds.b	1
Plr1_TmpSpcTap_b:			ds.b	1

_Plr1_TmpGunSelected_b::
Plr1_TmpGunSelected_b:		ds.b	1
Plr1_TmpFire_b:				ds.b	1

; Private fields
plr1_Teleported_b:			ds.b	1 ; hires.s
plr1_Dead_b:				ds.b	1 ; hires.s

plr1_TmpDucked_b:			ds.b	1 ; hires.s
plr1_StoodOnLift_b:			ds.b	1 ; newanims.s
plr1_Reserved1_b:			ds.b	1
plr1_Reserved2_b:			ds.b	1

; aligned 4
Plr1_ObjectDistances_vw:	ds.w	MAX_LEVEL_OBJ_DIST_COUNT
Plr1_ObsInLine_vb:			ds.b	MAX_OBJS_IN_LINE_COUNT


; READY PLAYER TWO !

			align 4
; Long data
Plr2_Data:
Plr2_ObjectPtr_l:			ds.l	1
Plr2_XOff_l:				ds.l	1
Plr2_YOff_l:				ds.l	1
Plr2_ZOff_l:				ds.l	1
Plr2_ZonePtr_l:				ds.l	1
Plr2_Height_l:				ds.l	1
Plr2_AimSpeed_l:			ds.l	1
Plr2_SnapXOff_l:			ds.l	1
Plr2_SnapYOff_l:			ds.l	1
Plr2_SnapYVel_l:			ds.l	1
Plr2_SnapZOff_l:			ds.l	1
Plr2_SnapTYOff_l:			ds.l	1
Plr2_SnapXSpdVal_l:			ds.l	1
Plr2_SnapZSpdVal_l:			ds.l	1
Plr2_SnapHeight_l:			ds.l	1
Plr2_SnapTargHeight_l:		ds.l	1
Plr2_TmpXOff_l:				ds.l	1
Plr2_TmpZOff_l:				ds.l	1
Plr2_TmpYOff_l:				ds.l	1

; Private fields
plr2_ListOfGraphRoomsPtr_l: ds.l 	1 ; hires.s
plr2_PointsToRotatePtr_l:	ds.l 	1 ; hires.s
plr2_BobbleY_l:				ds.l	1 ; hires.s
plr2_TmpHeight_l:			ds.l	1 ; hires.s
plr2_OldX_l:				ds.l	1 ; hires.s
plr2_OldZ_l:				ds.l	1 ; hires.s
plr2_OldRoomPtr_l:			ds.l	1 ; leveldata2.s
plr2_SnapSquishedHeight_l:	ds.l	1 ; plr2control.s
plr2_DefaultEnemyFlags_l:	ds.l	1

; Word Data
Plr2_Energy_w:				ds.w	1
Plr2_CosVal_w:				ds.w	1
Plr2_SinVal_w:				ds.w	1
Plr2_AngPos_w:				ds.w	1
Plr2_Zone_w:				ds.w	1
Plr2_FloorSpd_w:			ds.w	1 ; newanim.s
Plr2_RoomBright_w:			ds.w	1 ;
Plr2_Bobble_w:				ds.w	1
Plr2_SnapAngPos_w:			ds.w	1
Plr2_SnapAngSpd_w:			ds.w	1
Plr2_TmpAngPos_w:			ds.w	1 ; hires.s
Plr2_TimeToShoot_w:			ds.w	1

_Plr2_Inventory::
Plr2_Invetory_vw:
Plr2_Health_w:				ds.w	1
Plr2_JetpackFuel_w:			ds.w	1
Plr2_AmmoCounts_vw:			ds.w	20
Plr2_Shield_w:				ds.w	1
Plr2_Jetpack_w:				ds.w	1

_Plr2_Weapons_vb::
Plr2_Weapons_vb:			ds.w	10 ; todo - convert to bytes or bitfield

Plr2_GunFrame_w:			ds.w	1
Plr2_NoiseVol_w:			ds.w	1

; Private
plr2_TmpHoldDown_w:			ds.w	1 ; hires.s
plr2_TmpBobble_w:			ds.w	1 ; hires.s

plr2_SnapCosVal_w:			ds.w	1 ; plr2control.s
plr2_SnapSinVal_w:			ds.w	1 ; plr2control.s

plr2_WalkSFXTime_w:			ds.w	1 ; fall.s

; Byte Data
Plr2_Keys_b:				ds.b	1
Plr2_Path_b:				ds.b	1

Plr2_Mouse_b:				ds.b	1
Plr2_Joystick_b:			ds.b	1
Plr2_GunSelected_b:			ds.b	1
Plr2_StoodInTop_b:			ds.b	1

Plr2_Ducked_b:				ds.b	1
Plr2_Squished_b:			ds.b	1
Plr2_Echo_b:				ds.b	1
Plr2_Fire_b:				ds.b	1

Plr2_Clicked_b:				ds.b	1
Plr2_Used_b:				ds.b	1
Plr2_TmpClicked_b:			ds.b	1
Plr2_TmpSpcTap_b:			ds.b	1

_Plr2_TmpGunSelected_b::
Plr2_TmpGunSelected_b:		ds.b	1
Plr2_TmpFire_b:				ds.b	1

; Private fields
plr2_Teleported_b:			ds.b	1 ; hires.s
plr2_Dead_b:				ds.b	1 ; hires.s

plr2_TmpDucked_b:			ds.b	1 ; hires.s
plr2_StoodOnLift_b:			ds.b	1 ; newanims.s

plr2_Reserved1_b:			ds.b	1
plr2_Reserved2_b:			ds.b	1

; aligned 4
Plr2_ObjectDistances_vw:	ds.w	MAX_LEVEL_OBJ_DIST_COUNT
Plr2_ObsInLine_vb:			ds.b	MAX_OBJS_IN_LINE_COUNT


; READY PLAYER whoever...
			align 4
Plr_ShotDataPtr_l:				ds.l	1

; Private fields
plr_JumpSpeed_l:				ds.l	1 ; fall.s
plr_OldHeight_l:				ds.l	1 ; fall.s

Plr_AddToBobble_w:				ds.w	1


; Word fields
; Private
plr_FallDamage_w:				ds.w	1 ; fall.s

_Plr_MultiplayerType_b::
Plr_MultiplayerType_b:			ds.b	1	; CHAR enum - m(aster), s(lave), n(either)
Plr_Decelerate_b:				ds.b	1

; Byte fields
; Private
plr_CanJump_b:					ds.b	1
plr_GunSelected_b:				ds.b	1
plr_PrevNextWeaponKeyState_b:	ds.b	1
plr_PrevUseKeyState_b:			ds.b	1

Plr_Health_w:					ds.w	2
Plr_AmmoCounts_vw:				ds.w	20
Plr_Shield_w:					ds.w	2
Plr_Weapons_vw:					ds.w	10
Plr_TurnSpeed_w:				ds.w	1
BIGsmall:						ds.b	1
lastscr:						ds.b	1
