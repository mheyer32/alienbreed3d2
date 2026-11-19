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

; TODO - Gravity Overhaul
;
; Instead of using a terminal velocity in water and immediately limiting to it we can simulate drag for whatever
; we are falling through. Since we update the velocity every tick:
;
;         V_new = V_prev + ((G << P) - V_prev) >> P
;
; Where:
;         G is the fall acceleration, either global, level or zone overridden.
;         P is a shift factor for how easy it is to pass through the medium.
;
; At V = 0, the calculation is as present: V_new = P_prev + G (the shifts cancel)
;
; As V increases, the effective acceleration begins to fall. Terminal velocity is reached at G << P.
;
; Worked example for water: The current terminal velocity for water is defined as 512, and G is 64:
;
; V_term = G << P, 512 = 64 << P => P = 3
;
; For air, we should use a higher value of P. For example, a value of 8 would have a terminal velocity of 16384
; i.e. 32x faster than falling through water.


PLAYER_FALL_ACCELERATION EQU 64			; Fall velocity increment per tick
PLAYER_WATER_MAX_SINK_SPEED EQU 512		; Terminal fall velcity when in liquid
PLAYER_FALL_DAMAGE_MIN EQU 100			; Min threshold for damage. A counter is incremented every tick the player
										; is falling. The fall damage delivered is whatever the tick count is
										; above this. This need replacing with a gravity based estimate,
PLAYER_JETPACK_ACCELERATION EQU -128	; Jetpack Thrust velocity increment, per tick.
PLAYER_JUMP_IMPULSE_AIR EQU -1024		; Velocity increment for jumping in air.
PLAYER_JUMP_IMPULSE_WATER EQU -512      ; Velocity increment for jumping in water.
