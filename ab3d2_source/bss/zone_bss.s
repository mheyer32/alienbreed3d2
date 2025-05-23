
			section .bss,bss

; BSS data - to be included in BSS section
			align 4
Zone_BrightTable_vl:			ds.l	300

; Zone ordering
Zone_EndOfListPtr_l:			ds.l	1
zone_ToDrawTable_vw:			ds.w	400*2	; originally declared as 400 long, accessed as word
zone_OrderTable_vw:				ds.w	400*2	; originally declared as 400 long, accessed as word
Zone_OrderTable_Barrier_w:		ds.w	1 		; needs initialisation to -1
Zone_FinalOrderTable_vw:		ds.w	400*2
zone_FinalOrderTableBarrier_w:	ds.w	1 		; deliniates end of table

		DCLC Zone_VisJoins_w,	ds.w,	1 		; The nuber of visible joins in the current zone
		DCLC Zone_TotJoins_w,	ds.w,	1 		; The total number joins in the current zone
		DCLC Zone_VisJoinMask_w,	ds.w,	1 		; Bitmap of the visible joining edges

		; For the shared edges in a zone, space to hold the indexes of the start/end points to add to the
		; subset of points that need to be rotated. This is because the original code does not apply clips
		; to the current zone, only the immediately adjacent and beyond. This allows us to determine our
		; own clip extents to the root zone's shared edges.
		DCLC Zone_EdgePointIndexes_vw, ds.w, 32

		; For each of the doors and lifts, the Zone ID for each (or -1 if not associated)
		DCLC Zone_DoorList_vw,  ds.w,    LVL_MAX_DOOR_ZONES
		DCLC Zone_LiftList_vw,  ds.w,    LVL_MAX_LIFT_ZONES

		; The immediate global door state. This is updated during game logic when doors open and close.
		; The state may change unexpectedly as the logic runs in an interrupts
		DCLC Zone_CurrentDoorState_w,	ds.w,	1

		; A snapshot of the Zone_CurrentDoorState_w taken at the beginning of rendering each frame.
		; This value will be used by the Edge PVS visibility at runtime
		DCLC Zone_RenderDoorState_w,	ds.w,	1

		; Bitmap of the zones that contain doors. Since there are only 16 doors, except for very small levels,
		; most zones will not be a door. When we are processing the full level's per-zone PVS, we are going to
		; be querying if any given zone is a door with monotonous regularity. When a zone is not a door, which
		; is expected to be the most common case, we will be doing an exaustive check across the door list.
		; This bitmap prevents this by allowing us to test first if a zone is a door, before we then look up
		; which one it is.
		DCLC Zone_DoorMap_vb,   ds.b,    LVL_MAX_ZONE_COUNT/8

		; As aboce, for lift zones
		DCLC Zone_LiftMap_vb,   ds.b,    LVL_MAX_ZONE_COUNT/8

			align 4

		DCLC Zone_PVSList_vw,   ds.w,    LVL_MAX_ZONE_COUNT ; worst case sizes. We don't expect all zones visible
		DCLC Zone_PVSMask_vb,   ds.b,    LVL_MAX_ZONE_COUNT
			align 4


; Bitmask
EDGE_POINT_ID_LIST_END EQU -4
ZONE_BACKDROP_DISABLE_SIZE  EQU LVL_EXPANDED_MAX_ZONE_COUNT/8

Zone_BackdropDisable_vb:		ds.b	ZONE_BACKDROP_DISABLE_SIZE
