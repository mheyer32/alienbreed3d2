
			section bss,bss

; BSS data - to be included in BSS section
			align 4

; TODO Analyse the usage patterns of these fields and work out if any of the temp/snap versions
; are better off placed closer (cache line)

; READY PLAYER ONE !

; Long data
Plr1_ObjectPtr_l:			ds.l	1
Plr1_XOff_l:				ds.l	1 ; sometimes accessed as w - todo understand real size
Plr1_YOff_l:				ds.l	1
Plr1_ZOff_l:				ds.l	1 ; sometimes accessed as w - todo understand real size
Plr1_RoomPtr_l:				ds.l	1
Plr1_OldRoomPtr_l:			ds.l	1
Plr1_PointsToRotatePtr_l:	ds.l	1
Plr1_ListOfGraphRoomsPtr_l:	ds.l	1
Plr1_Height_l:				ds.l	1
Plr1_BobbleY_l:				ds.l	1
Plr1_AimSpeed_l:			ds.l	1

Plr1_SnapXOff_l:			ds.l	1
Plr1_SnapYOff_l:			ds.l	1
Plr1_SnapYVel_l:			ds.l	1
Plr1_SnapZOff_l:			ds.l	1
Plr1_SnapTYOff_l:			ds.l	1
Plr1_SnapXSpdVal_l:			ds.l	1
Plr1_SnapZSpdVal_l:			ds.l	1
Plr1_SnapHeight_l:			ds.l	1
Plr1_SnapSquishedHeight_l:	ds.l	1
Plr1_SnapTargHeight_l: 		ds.l	1

Plr1_TmpXOff_l:				ds.l	1 ; also accessed as w, todo determine correct size
Plr1_TmpZOff_l:				ds.l	1
Plr1_TmpYOff_l:				ds.l	1
Plr1_TmpHeight_l:			ds.l	1
OldX1_l:					ds.l	1
OldZ1_l:					ds.l	1

; Word data
Plr1_Energy_w:				ds.w	1
Plr1_CosVal_w:				ds.w	1
Plr1_SinVal_w:				ds.w	1
Plr1_AngPos_w:				ds.w	1
Plr1_Zone_w:				ds.w	1
Plr1_FloorSpd_w:			ds.w	1
Plr1_RoomBright_w: 			ds.w	1
Plr1_Bobble_w:				ds.w	1

Plr1_SnapCosVal_w:			ds.w	1
Plr1_SnapSinVal_w:			ds.w	1
Plr1_SnapAngPos_w:			ds.w	1
Plr1_SnapAngSpd_w:			ds.w	1

Plr1_TmpAngPos_w:			ds.w	1
Plr1_TmpBobble_w:			ds.w	1
Plr1_TmpHoldDown_w:			ds.w	1

; Byte data
Plr1_Keys_b:				ds.b	1
Plr1_Path_b:				ds.b	1
Plr1_Mouse_b:				ds.b	1
Plr1_Joystick_b:			ds.b	1
Plr1_GunSelected_b: 		ds.b	1
Plr1_StoodInTop_b: 			ds.b	1
Plr1_Teleported_b:			ds.b	1
Plr1_Ducked_b:				ds.b	1
Plr1_Squished_b:			ds.b	1
Plr1_Echo_b:				ds.b	1
Plr1_Dead_b:				ds.b	1
Plr1_Fire_b:				ds.b	1
Plr1_Clicked_b:				ds.b    1
Plr1_TmpClicked_b:			ds.b	1
Plr1_TmpSpcTap_b:			ds.b	1
Plr1_TmpDucked_b:			ds.b	1
Plr1_TmpGunSelected_b:		ds.b	1
Plr1_TmpFire_b:				ds.b	1


; READY PLAYER TWO !

			align 4
; Long data
Plr2_ObjectPtr_l:			ds.l	1
Plr2_XOff_l:				ds.l	1
Plr2_YOff_l:				ds.l	1
Plr2_ZOff_l:				ds.l	1
Plr2_RoomPtr_l:				ds.l	1
Plr2_OldRoomPtr_l:			ds.l	1
Plr2_PointsToRotatePtr_l:	ds.l 	1
Plr2_ListOfGraphRoomsPtr_l: ds.l 	1
Plr2_Height_l:				ds.l	1
Plr2_BobbleY_l:				ds.l	1
Plr2_AimSpeed_l:			ds.l	1

Plr2_SnapXOff_l:			ds.l	1
Plr2_SnapYOff_l:			ds.l	1
Plr2_SnapYVel_l:			ds.l	1
Plr2_SnapZOff_l:			ds.l	1
Plr2_SnapTYOff_l:			ds.l	1
Plr2_SnapXSpdVal_l:			ds.l	1
Plr2_SnapZSpdVal_l:			ds.l	1
Plr2_SnapHeight_l:			ds.l	1
Plr2_SnapSquishedHeight_l:	ds.l	1
Plr2_SnapTargHeight_l:		ds.l	1

Plr2_TmpXOff_l:				ds.l	1
Plr2_TmpZOff_l:				ds.l	1
Plr2_TmpYOff_l:				ds.l	1
Plr2_TmpHeight_l:			ds.l	1
OldX2_l:					ds.l	1
OldZ2_l:					ds.l	1
; Word Data
Plr2_Energy_w:				ds.w	1
Plr2_CosVal_w:				ds.w	1
Plr2_SinVal_w:				ds.w	1
Plr2_AngPos_w:				ds.w	1
Plr2_Zone_w:				ds.w	1
Plr2_FloorSpd_w:			ds.w	1
Plr2_Bobble_w:				ds.w	1

Plr2_SnapCosVal_w:			ds.w	1
Plr2_SnapSinVal_w:			ds.w	1
Plr2_SnapAngPos_w:			ds.w	1
Plr2_SnapAngSpd_w:			ds.w	1

Plr2_TmpAngPos_w:			ds.w	1
Plr2_TmpBobble_w:			ds.w	1
Plr2_TmpHoldDown_w:			ds.w	1

; Byte Data
Plr2_Keys_b:				ds.b	1
Plr2_Path_b:				ds.b	1
Plr2_Mouse_b:				ds.b	1
Plr2_Joystick_b:			ds.b	1
Plr2_GunSelected_b:			ds.b	1
Plr2_StoodInTop_b:			ds.b	1
Plr2_Teleported_b:			ds.b	1
Plr2_Ducked_b:				ds.b	1
Plr2_Squished_b:			ds.b	1
Plr2_Echo_b:				ds.b	1
Plr2_Dead_b:				ds.b	1
Plr2_Fire_b:				ds.b	1
Plr2_Clicked_b:				ds.b	1
Plr2_TmpClicked_b:			ds.b	1
Plr2_TmpSpcTap_b:			ds.b	1
Plr2_TmpDucked_b:			ds.b	1
Plr2_TmpGunSelected_b:		ds.b	1
Plr2_TmpFire_b:				ds.b	1

; READY PLAYER whoever...
			align 4
Plr_GunDataPtr_l:			ds.l	1
Plr_ShotDataPtr_l:			ds.l	1
Plr_JumpSpeed_l:			ds.l	1
Plr_MultiplayerType_b:		ds.b	1	; CHAR enum - m(aster), s(lave), n(either)
Plr_GunSelected_b:			ds.b	1
Plr_Decelerate_b:			ds.b	1
Plr_CanJump_b:				ds.b	1

; Tables...
			align 4
PLR1_ObjDists:				ds.w	250
PLR2_ObjDists:				ds.w	250
