	; Player Definition (runtime)
	STRUCTURE PlrT,0
		; Long fields
		ULONG PlrT_ObjectPtr_l				;   0, 4
		ULONG PlrT_XOff_l					;   4, 4 - sometimes accessed as w - todo understand real size
		ULONG PlrT_YOff_l					;   8, 4
		ULONG PlrT_ZOff_l					;  12, 4 - sometimes accessed as w - todo understand real size
		ULONG PlrT_ZonePtr_l				;  16, 4
		ULONG PlrT_Height_l					;  20, 4
		ULONG PlrT_AimSpeed_l				;  24, 4
		ULONG PlrT_SnapXOff_l				;  28, 4
		ULONG PlrT_SnapYOff_l				;  32, 4
		ULONG PlrT_SnapYVel_l				;  36, 4
		ULONG PlrT_SnapZOff_l				;  40, 4
		ULONG PlrT_SnapTYOff_l				;  44, 4
		ULONG PlrT_SnapXSpdVal_l			;  48, 4
		ULONG PlrT_SnapZSpdVal_l			;  52, 4
		ULONG PlrT_SnapHeight_l				;  56, 4
		ULONG PlrT_SnapTargHeight_l			;  60, 4
		ULONG PlrT_TmpXOff_l				;  64, 4 - also accessed as w, todo determine correct size
		ULONG PlrT_TmpZOff_l				;  68, 4
		ULONG PlrT_TmpYOff_l				;  72, 4

		; Private
		ULONG PlrT_ListOfGraphRoomsPtr_l	;  76, 4
		ULONG PlrT_PointsToRotatePtr_l		;  80, 4
		ULONG PlrT_BobbleY_l				;  84, 4
		ULONG PlrT_TmpHeight_l				;  88, 4
		ULONG PlrT_OldX_l					;  92, 4
		ULONG PlrT_OldZ_l					;  96, 4
		ULONG PlrT_OldRoomPtr_l				; 100, 4
		ULONG PlrT_SnapSquishedHeight_l		; 104, 4
		ULONG PlrT_DefaultEnemyFlags_l		; 108, 4


		; Word fields
		UWORD PlrT_Energy_w					; 112, 2
		UWORD PlrT_CosVal_w					; 114, 2
		UWORD PlrT_SinVal_w					; 116, 2
		UWORD PlrT_AngPos_w					; 118, 2
		UWORD PlrT_Zone_w					; 120, 2
		UWORD PlrT_FloorSpd_w				; 122, 2
		UWORD PlrT_RoomBright_w				; 124, 2
		UWORD PlrT_Bobble_w					; 126, 2
		UWORD PlrT_SnapAngPos_w				; 128, 2
		UWORD PlrT_SnapAngSpd_w				; 130, 2
		UWORD PlrT_TmpAngPos_w				; 132, 2
		UWORD PlrT_TimeToShoot_w			; 134, 2

		; This section is saved/loaded in game save
		UWORD PlrT_Health_w					; 136, 2
		UWORD PlrT_JetpackFuel_w			; 138, 2
		UWORD PlrT_AmmoCounts_vw			; 140, 40 - UWORD[20]
		PADDING (NUM_BULLET_DEFS*2)-2
		UWORD PlrT_Shield_w					; 180, 2
		UWORD PlrT_Jetpack_w				; 182, 2
		UWORD PlrT_Weapons_vb				; 184, 20 - UWORD[10]
		PADDING (NUM_GUN_DEFS*2)-2

		UWORD PlrT_GunFrame_w				; 204, 2
		UWORD PlrT_NoiseVol_w				; 206, 2
		; Private

		UWORD PlrT_TmpHoldDown_w			; 208, 2
		UWORD PlrT_TmpBobble_w				; 210, 2
		UWORD PlrT_SnapCosVal_w				; 212, 2
		UWORD PlrT_SnapSinVal_w				; 214, 2
		UWORD PlrT_WalkSFXTime_w			; 216, 2

		; Byte data
		UBYTE PlrT_Keys_b					; 218
		UBYTE PlrT_Path_b					; 219
		UBYTE PlrT_Mouse_b					; 220
		UBYTE PlrT_Joystick_b				; 221
		UBYTE PlrT_GunSelected_b			; 222
		UBYTE PlrT_StoodInTop_b				; 223
		UBYTE PlrT_Ducked_b					; 224
		UBYTE PlrT_Squished_b				; 225
		UBYTE PlrT_Echo_b					; 226
		UBYTE PlrT_Fire_b					; 227
		UBYTE PlrT_Clicked_b				; 228
		UBYTE PlrT_Used_b					; 229
		UBYTE PlrT_TmpClicked_b				; 230
		UBYTE PlrT_TmpSpcTap_b				; 231
		UBYTE PlrT_TmpGunSelected_b			; 232
		UBYTE PlrT_TmpFire_b				; 233

 		; Private
		UBYTE PlrT_Teleported_b				; 234
		UBYTE PlrT_Dead_b					; 235
		UBYTE PlrT_TmpDucked_b				; 236
		UBYTE PlrT_StoodOnLift_b			; 237

		UBYTE PlrT_InvMouse_b				; 238
		UBYTE PlrT_Reserved2_b				; 239

		; Tables
		UWORD PlrT_ObjectDistances_vw		; 240, MAX_LEVEL_OBJ_DIST_COUNT*2 : UWORD[MAX_LEVEL_OBJ_DIST_COUNT]
		PADDING (MAX_LEVEL_OBJ_DIST_COUNT*2)-2
		UBYTE PlrT_ObjectsInLine_vb			; ..., MAX_OBJS_IN_LINE_COUNT : UBYTE[MAX_OBJS_IN_LINE_COUNT]
		PADDING (MAX_OBJS_IN_LINE_COUNT-1)
		LABEL PlrT_SizeOf_l
