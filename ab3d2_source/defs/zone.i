
	; Zone Structure todo - what gives with the 16-bit alignment of these?
	; TODO - consider rearranging the data after loading into something with optimal alignment
	STRUCTURE ZoneT,0
		UWORD ZoneT_ID_w                ;  2, 2
		ULONG ZoneT_Floor_l				;  2, 4
		ULONG ZoneT_Roof_l				;  6, 4
		ULONG ZoneT_UpperFloor_l		; 10, 4
		ULONG ZoneT_UpperRoof_l			; 14, 4
		ULONG ZoneT_Water_l				; 18, 4
		UWORD ZoneT_Brightness_w		; 22, 2
		UWORD ZoneT_UpperBrightness_w	; 24, 2
		UWORD ZoneT_ControlPoint_w		; 26, 2 really UBYTE[2]
		UWORD ZoneT_BackSFXMask_w		; 28, 2 Originally long but always accessed as word
		UWORD ZoneT_Unused_w            ; 30, 2 so this is the unused half
		UWORD ZoneT_EdgeListOffset_w	; 32, 2 Offset relative to ZoneT instance
		UWORD ZoneT_Points_w			; 34, 2
		UBYTE ZoneT_DrawBackdrop_b		; 36, 1 Draw background?
		UBYTE ZoneT_Echo_b				; 37, 1
		UWORD ZoneT_TelZone_w			; 38, 2
		UWORD ZoneT_TelX_w				; 40, 2
		UWORD ZoneT_TelZ_w				; 42, 2
		UWORD ZoneT_FloorNoise_w		; 44, 2
		UWORD ZoneT_UpperFloorNoise_w	; 46, 2
		UWORD ZoneT_PotVisibleZoneList_vw		; 48, 2 - Set of Potentially Visible Zones (array of 4-word tuples)
		LABEL ZoneT_SizeOf_l			; 50

	; Edge structure. The ZoneT_EdgeListOffset_w points to a list of words that are indexes
	; in an array of the following structure, pointed to by Lvl_ZoneEdgePtr_l
	STRUCTURE EdgeT,0
		WORD  EdgeT_XPos_w        ; 0 X coordinate
		WORD  EdgeT_ZPos_w        ; 2 Z coordinate
		WORD  EdgeT_XLen_w        ; 4 Length in X direction
		WORD  EdgeT_ZLen_w        ; 6 Length in Z direction
		WORD  EdgeT_JoinZone_w    ; 8 Zone the edge joins to, or -1 for a solid wall
		WORD  EdgeT_Length_w      ; 10 Scaled wall length for collision code
		BYTE  EdgeT_UnitNormalX_b ; 12 X uhit normal
		BYTE  EdgeT_UnitNormalZ_b ; 13 Y unit normal
		WORD  EdgeT_Flags_w       ; 14 TODO - determine flag bits
		LABEL EdgeT_SizeOf_l      ; 16

	STRUCTURE PVST,0
		WORD  PVST_Zone_w ; 0
		WORD  PVST_ClipID_w ; 2
		WORD  PVST_Word_2 ; 4 TODO
		WORD  PVST_Word_3 ; 6 TODO
		LABEL PVST_SizeOf_l ; 8

    ; Liftable Zone (Door, Lift) Structure
	STRUCTURE ZLiftableT,0
		UWORD ZLiftableT_Bottom_w			;  0, 2
		UWORD ZLiftableT_Top_w				;  2, 2
		UWORD ZLiftableT_OpeningSpeed_w		;  4, 2
		UWORD ZLiftableT_ClosingSpeed_w		;  6, 2
		UWORD ZLiftableT_OpenDuration_w		;  8, 2
		UWORD ZLiftableT_OpeningSoundFX_w	; 10, 2
		UWORD ZLiftableT_ClosingSoundFX_w	; 12, 2
		UWORD ZLiftableT_OpenedSoundFX_w	; 14, 2
		UWORD ZLiftableT_ClosedSoundFX_w	; 16, 2
		UWORD ZLiftableT_Word9_w			; 18, 2 - something X coordinate related
		UWORD ZLiftableT_Word10_w			; 20, 2 - something Z coordinate related
		UWORD ZLiftableT_Word11_w			; 22, 2
		UWORD ZLiftableT_Word12_w			; 24, 2
		UWORD ZLiftableT_GraphicsPtrOffset_l; 26, 4 - offset from Lvl_GraphicsPtr_l
		UWORD ZLiftableT_ZoneID_w			; 30, 2
		UWORD ZLiftableT_Word16_w			; 32, 2
		UBYTE ZLiftableT_RaiseCondition_b	; 34, 1
		UBYTE ZLiftableT_LowerCondition_b   ; 35, 1
		LABEL ZLiftableT_SizeOf_l			; 36
		; Lift ZLiftWallT list follows the structure

	STRUCTURE ZLiftWallT,0
		UWORD ZLiftWallT_EdgeID_w			; 0, 2
		ULONG ZLiftWallT_GraphicsOffset_l	; 2, 4
		ULONG ZLiftWallT_Long_l				; 6, 4
		LABEL ZLoftWallT_SizeOf_l

NOT_A_DOOR				EQU -1
END_OF_DOOR_LIST		EQU 999
END_OF_DOOR_WALL_LIST 	EQU -1

*****************************
* Door Definitions **********
*****************************

; Roor raise and Door Lower activiatin types
DR_Plr_SPC		EQU		0
DR_Plr			EQU		1
DR_Bul			EQU		2
DR_Alien		EQU		3
DR_Timeout		EQU		4
DR_Never		EQU		5
DL_Timeout		EQU		0
DL_Never		EQU		1
