
*****************************
* Structure Padding Macro ***
*****************************

PADDING		MACRO
SOFFSET		SET    SOFFSET+\1
			ENDM

*****************************
* Structure definitions *****
*****************************

	; Bullet definition
	STRUCTURE BulT,0
		ULONG BulT_IsHitScan_l			;   0, 4
		ULONG BulT_Gravity_l			;   4, 4
		ULONG BulT_Lifetime_l			;   8, 4
		ULONG BulT_AmmoInClip_l			;  12, 4
		ULONG BulT_BounceHoriz_l		;  16, 4
		ULONG BulT_BounceVert_l			;  20, 4
		ULONG BulT_HitDamage_l			;  24, 4
		ULONG BulT_ExplosiveForce_l		;  28, 4
		ULONG BulT_Speed_l				;  32, 4
		ULONG BulT_AnimFrames_l			;  36, 4
		ULONG BulT_PopFrames_l			;  40, 4
		ULONG BulT_BounceSFX_l			;  44, 4
		ULONG BulT_ImpactSFX_l			;  48, 4
		ULONG BulT_GraphicType_l		;  52, 4
		ULONG BulT_ImpactGraphicType_l	;  56, 4
		STRUCT BulT_AnimData_vb,120		;  60, 120
		STRUCT BulT_PopData_vb,120		; 180, 0
		LABEL BulT_SizeOf_l				; 300

	; Bullet shoot definition
	STRUCTURE ShootT,0
		UWORD ShootT_BulType_w			; 0, 2
		UWORD ShootT_Delay_w			; 2, 2
		UWORD ShootT_BulCount_w			; 4, 2
		UWORD ShootT_SFX_w				; 6, 2
		LABEL ShootT_SizeOf_l			; 8

	; Alien Defs
	STRUCTURE AlienT,0
		UWORD AlienT_GFXType_w				;  0, 2
		UWORD AlienT_DefaultBehaviour_w		;  2, 2
		UWORD AlienT_ReactionTime_w			;  4, 2
		UWORD AlienT_DefaultSpeed_w			;  6, 2
		UWORD AlienT_ResponseBehaviour_w	;  8, 2
		UWORD AlienT_ResponseSpeed_w		; 10, 2
		UWORD AlienT_ResponseTimeout_w		; 12, 2
		UWORD AlienT_DamageToRetreat_w		; 14, 2
		UWORD AlienT_DamageToFollowup_w		; 16, 2
		UWORD AlienT_FollowupBehaviour_w	; 18, 2
		UWORD AlienT_FollowupSpeed_w		; 20, 2
		UWORD AlienT_FollowupTimeout_w		; 22, 2
		UWORD AlienT_RetreatBehaviour_w		; 24, 2
		UWORD AlienT_RetreatSpeed_w			; 26, 2
		UWORD AlienT_RetreatTimeout_w		; 28, 2
		UWORD AlienT_BulType_w				; 30, 2
		UWORD AlienT_HitPoints_w			; 32, 2
		UWORD AlienT_Height_w				; 34, 2
		UWORD AlienT_Girth_w				; 36, 2
		UWORD AlienT_SplatType_w			; 38, 2
		UWORD AlienT_Auxilliary_w			; 40, 2
		LABEL AlienT_SizeOf_l				; 42

	; Object Definition
	STRUCTURE ObjT,0
		UWORD ObjT_Behaviour_w		;  0, 2
		UWORD ObjT_GFXType_w		;  2, 2
		UWORD ObjT_ActiveTimeout_w	;  4, 2
		UWORD ObjT_HitPoints_w		;  6, 2
		UWORD ObjT_ExplosiveForce_w	;  8, 2 unused
		UWORD ObjT_Impassible_w		; 10, 2 unused
		UWORD ObjT_DefaultAnimLen_w	; 12, 2 unused
		UWORD ObjT_CollideRadius_w	; 14, 2
		UWORD ObjT_CollideHeight_w	; 16, 2
		UWORD ObjT_FloorCeiling_w	; 18, 2
		UWORD ObjT_LockToWall_w		; 20, 2 unused
		UWORD ObjT_ActiveAnimLen_w	; 22, 2 unused
		UWORD ObjT_SFX_w			; 24, 2
		PADDING 14					; 26, 14
		LABEL ObjT_SizeOf_l			; 40

	; Extended data for AI entities
	; TODO - move this to a .i definition file for the AI module
	;      - Can this be reorganised ?
	STRUCTURE EntT,18
		UBYTE EntT_NumLives_b				; 18, 1
		UBYTE EntT_DamageTaken_b			; 19, 1
		UBYTE EntT_CurrentMode_b			; 20, 1
		UBYTE EntT_TeamNumber_b				; 21, 1
		UWORD EntT_CurrentSpeed_w 			; 22, 2 unused
		UWORD EntT_DisplayText_w			; 24, 2
		UWORD EntT_GraphicRoom_w			; 26, 2
		UWORD EntT_CurrentControlPoint_w	; 28, 2
		UWORD EntT_CurrentAngle_w			; 30, 2
		UWORD EntT_TargetControlPoint_w		; 32, 2
		UWORD EntT_Timer1_w					; 34, 2
		ULONG EntT_EnemyFlags_l				; 36, 4
		UWORD EntT_Timer2_w					; 40, 2
		UWORD EntT_ImpactX_w				; 42, 2
		UWORD EntT_ImpactZ_w				; 44, 2
		UWORD EntT_ImpactY_w				; 46, 2
		UWORD EntT_VelocityY_w				; 48, 2
		UWORD EntT_DoorsHeld_w				; 50, 2
		UWORD EntT_Timer3_w					; 52, 2
		; union field of UWORD, UBYTE[2]
		LABEL EntT_Timer4_w					; 54, 0
		UBYTE EntT_Type_b					; 54, 1
		UBYTE EntT_WhichAnim_b				; 55, 1
		LABEL EntT_SizeOf_l					; 56

	; Shot Definition
	STRUCTURE ShotT,18
		UWORD ShotT_VelocityX_w		; 18, 2
		PADDING 2           		; 20, 2
		UWORD ShotT_VelocityZ_w		; 22, 2
		PADDING 4           		; 24, 4
		UWORD ShotT_Power_w			; 28, 2
		UBYTE ShotT_Status_b		; 30, 1
		UBYTE ShotT_Size_b			; 31, 1
		PADDING 10          		; 32, 10
		UWORD ShotT_VelocityY_w		; 42, 2

		; union
		LABEL ShotT_AccYPos_w		; 44, 0
		UWORD ShotT_AuxOffsetX_w	; 44, 2
		UWORD ShotT_AuxOffsetY_w	; 46, 2
		PADDING 4           		; 48, 4
		UBYTE ShotT_Anim_b			; 52, 1
		PADDING 1           		; 53, 1
		UWORD ShotT_Gravity_w		; 54, 2
		UWORD ShotT_Impact_w		; 56, 2
		UWORD ShotT_Lifetime_w		; 58, 2
		UWORD ShotT_Flags_w			; 60, 2
		UBYTE ShotT_Worry_b			; 62, 1
		UBYTE ShotT_InUpperZone_b	; 63, 1
		LABEL ShotT_SizeOf_l		; 64

	; Zone Structure todo - what gives with the 16-bit alignment of these?
	STRUCTURE ZoneT,2
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
		UWORD ZoneT_ExitList_w			; 32, 2
		UWORD ZoneT_Points_w			; 34, 2
		UBYTE ZoneT_Back_b				; 36, 1 unused
		UBYTE ZoneT_Echo_b				; 37, 1
		UWORD ZoneT_TelZone_w			; 38, 2
		UWORD ZoneT_TelX_w				; 40, 2
		UWORD ZoneT_TelZ_w				; 42, 2
		UWORD ZoneT_FloorNoise_w		; 44, 2
		UWORD ZoneT_UpperFloorNoise_w	; 46, 2
		UWORD ZoneT_ListOfGraph_w		; 48, 2
		LABEL ZoneT_SizeOf_l			; 50

**************************
* Game link file offsets *
**************************

O_FrameStoreSize 	EQU		6
O_AnimSize			EQU		O_FrameStoreSize*20
AmmoGiveLen			EQU		22*2
GunGiveLen			EQU		12*2
A_FrameLen			EQU		11
A_OptLen			EQU		A_FrameLen*20
A_AnimLen			EQU		A_OptLen*11


NUM_LEVELS			EQU	16
NUM_BULLET_DEFS		EQU 20
NUM_GUN_DEFS		EQU 10
NUM_ALIEN_DEFS		EQU 20
NUM_OBJECT_DEFS		EQU 30
NUM_SFX				EQU 64
NUM_WALL_TEXTURES	EQU 16

	; Game Link File Offsets
	; Where possible, these are defined in terms the NUM limits above.
	STRUCTURE GLFT,64
		STRUCT GLFT_LevelNames_l,(NUM_LEVELS*40)
		STRUCT GLFT_ObjGfxNames_l,(NUM_OBJECT_DEFS*64)
		STRUCT GLFT_SFXFilenames_l,(NUM_SFX*60)
		STRUCT GLFT_FloorFilename_l,64
		STRUCT GLFT_TextureFilename_l,192
		STRUCT GLFT_GunGFXFilename_l,64
		STRUCT GLFT_StoryFilename_l,64
		STRUCT GLFT_BulletDefs_l,(NUM_BULLET_DEFS*BulT_SizeOf_l)
		STRUCT GLFT_BulletNames_l,(NUM_BULLET_DEFS*20)
		STRUCT GLFT_GunNames_l,(NUM_GUN_DEFS*20)
		STRUCT GLFT_ShootDefs_l,(NUM_GUN_DEFS*ShootT_SizeOf_l)
		STRUCT GLFT_AlienNames_l,(NUM_ALIEN_DEFS*20)
		STRUCT GLFT_AlienDefs_l,(NUM_ALIEN_DEFS*AlienT_SizeOf_l)
		STRUCT GLFT_FrameData_l,7680 								; todo - figure out how this is derived
		STRUCT GLFT_ObjectNames_l,(NUM_OBJECT_DEFS*20)
		STRUCT GLFT_ObjectDefs,(NUM_OBJECT_DEFS*ObjT_SizeOf_l)
		STRUCT GLFT_ObjectDefAnims_l,(NUM_OBJECT_DEFS*O_AnimSize)
		STRUCT GLFT_ObjectActAnims_l,(NUM_OBJECT_DEFS*O_AnimSize)
		STRUCT GLFT_AmmoGive_l,(NUM_OBJECT_DEFS*AmmoGiveLen)		; ammo given per (collectable) object
		STRUCT GLFT_GunGive_l,(NUM_OBJECT_DEFS*GunGiveLen)			; guns given per (collectable) object
		STRUCT GLFT_AlienAnims_l,(NUM_ALIEN_DEFS*A_AnimLen)
		STRUCT GLFT_VectorNames_l,(NUM_OBJECT_DEFS*64)
		STRUCT GLFT_WallGFXNames_l,(NUM_WALL_TEXTURES*64)
		STRUCT GLFT_WallHeights_l,(NUM_WALL_TEXTURES*2)
		STRUCT GLFT_AlienBrights_l,(NUM_ALIEN_DEFS*2)
		STRUCT GLFT_GunObjects_l,(NUM_GUN_DEFS*2)
		UWORD  GLFT_Player1Graphic_w
		UWORD  GLFT_Player2Graphic_w
		STRUCT GLFT_FloorData_l,(16*4) ; MSW is damage, LSW is sound effect
		STRUCT GLFT_AlienShootDefs_l,(NUM_ALIEN_DEFS*ShootT_SizeOf_l)
		STRUCT GLFT_AmbientSFX_l,(16*2)
		STRUCT GLFT_LevelMusic_l,(NUM_LEVELS*64)
		STRUCT GLFT_EchoTable_l,(60)
		LABEL  GLFT_SizeOf_l

*****************************
* Door Definitions **********
*****************************

DR_Plr_SPC		EQU		0
DR_Plr			EQU		1
DR_Bul			EQU		2
DR_Alien		EQU		3
DR_Timeout		EQU		4
DR_Never		EQU		5
DL_Timeout		EQU		0
DL_Never		EQU		1

