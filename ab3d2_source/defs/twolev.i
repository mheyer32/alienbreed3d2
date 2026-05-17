;
; LEVEL DATA FILES
;

LVLT_MESSAGE_LENGTH EQU 160
LVLT_MESSAGE_COUNT  EQU 10

; Maximum number of zones. Note that the game doesn't yet support this limit fully.
LVL_EXPANDED_MAX_ZONE_COUNT EQU 512

; Maximum number of zones. Once this is fully working, redefine as LVL_EXPANDED_MAX_ZONE_COUNT
LVL_MAX_ZONE_COUNT EQU 256

; Maximum number of door zones.
LVL_MAX_DOOR_ZONES EQU 16

; Maximum number of lift zones.
LVL_MAX_LIFT_ZONES EQU 16

	; twolev.bin data header, after the text messages (first: LVLT_MESSAGE_LENGTH * LVLT_NUM_MESSAGES)
	STRUCTURE TLBT,0
		UWORD TBLT_Plr1_StartXPos_w			; 0
		UWORD TBLT_Plr1_StartZPos_w			; 2
		UWORD TBLT_Plr1_StartZoneID_w		; 4
		UWORD TBLT_Plr2_StartXPos_w			; 6
		UWORD TBLT_Plr2_StartZPos_w			; 8
		UWORD TBLT_Plr2_StartZoneID_w		; 10
		UWORD TLBT_NumControlPoints_w		; 12
		UWORD TLBT_NumPoints_w				; 14
		UWORD TLBT_NumZones_w				; 16
		UWORD TLBT_Unknown_w				; 18
		UWORD TLBT_NumObjects_w				; 20
		ULONG TLBT_PointsOffset_l			; 22
		ULONG TLBT_FloorLineOffset_l		; 26
		ULONG TLBT_ObjectDataOffset_l		; 30
		ULONG TLBT_ShotDataOffset_l			; 34 - this in twolev.bin ?
		ULONG TLBT_AlienShotDataOffset_l	; 38 - this in twolev.bin ?
		ULONG TLBT_ObjectPointsOffset_l		; 42
		ULONG TLBT_Plr1ObjectOffset_l		; 46
		ULONG TLBT_Plr2ObjectOffset_l		; 50
	LABEL TLBT_SizeOf_l						; This is the end of the header


	; twolev.graph.bin data header
	STRUCTURE TLGT,0
		; Offset values
		ULONG TLGT_DoorDataOffset_l			; 0
		ULONG TLGT_LiftDataOffset_l			; 4
		ULONG TLGT_SwitchDataOffset_l		; 8
		ULONG TLGT_ZoneGraphAddsOffset_l	; 12
		ULONG TLGT_ZoneAddsOffset_l			; 16
	LABEL TLGT_SizeOf_l


	; Level Data Structure (after message block of LVLT_MESSAGE_LENGTH*LVLT_MESSAGE_COUNT)
	STRUCTURE LvlT,0					; offset, size
		UWORD LvlT_Plr1_StartX_w		; 0, 2
		UWORD LvlT_Plr1_StartZ_w		; 2, 2
		UWORD LvlT_Plr1_Start_ZoneID_w 	; 4, 2
		UWORD LvlT_Plr2_StartX_w		; 6, 2
		UWORD LvlT_Plr2_StartZ_w		; 8, 2
		UWORD LvlT_Plr2_Start_ZoneID_w 	; 10, 2

		UWORD LvlT_NumControlPoints_w	; 12, 2
		UWORD LvlT_NumPoints_w			; 14, 2

		UWORD LvlT_NumZones_w			; 16, 2

		UWORD LvlT_Unk_0_w				; 18,2
		UWORD LvlT_NumObjectPoints_w	; 20,2

		; Offset values are typically measured relative to the start of the file (inc message block)
		ULONG LvlT_OffsetToPoints_l			; 22,4
		ULONG LvlT_OffsetToFloorLines_l		; 26,4
		ULONG LvlT_OffsetToObjects_l		; 30,4
		ULONG LvlT_OffsetToPlayerShot_l		; 34,4
		ULONG LvlT_OffsetToAlienShot_l		; 38,4
		ULONG LvlT_OffsetToObjectPoints_l	; 42,4
		ULONG LvlT_OffsetToPlr1Obj_l		; 46,4
		ULONG LvlT_OffsetToPlr2Obj_l		; 50,4

		LABEL LvlT_ControlPointCoords_vw	; 54 ? LvlT_NumControlPoints_w ?

		LABEL LvlT_SizeOf_l
