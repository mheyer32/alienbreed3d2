
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
		LABEL BulT_AnimData_vb			;  60, 0
		PADDING 120						;  60, 120
		LABEL BulT_PopData_vb			; 180, 0
		PADDING 120						; 180, 120
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

	; Game Link File: Object Defs
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

*****************************
* Bullet object definitions *
*****************************

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

**************************
* Game link file offsets *
**************************

LevelName			EQU		64
ObjectGfxNames		EQU		LevelName+40*16
SFXFilenames		EQU		ObjectGfxNames+64*30
FloorTileFilename	EQU		SFXFilenames+64*60
TextureFilename		EQU		FloorTileFilename+64
GunGFXFilename		EQU		FloorTileFilename+256
BlurbFileName		EQU		GunGFXFilename+64
BulletAnimData		EQU		BlurbFileName+64
BulletNames			EQU		BulletAnimData+(20*BulT_SizeOf_l)
GunNames			EQU		BulletNames+20*20
GunBulletTypes		EQU		GunNames+10*20
AlienNames			EQU		GunBulletTypes+10*8
AlienStats			EQU		AlienNames+20*20
FrameData			EQU		AlienStats+(AlienT_SizeOf_l*20)
ObjectNames			EQU		FrameData+7680
ObjectStats			EQU		ObjectNames+600
ObjectDefAnims		EQU		ObjectStats+(ObjT_SizeOf_l*30)
O_FrameStoreSize 	EQU		6
O_AnimSize			EQU		O_FrameStoreSize*20
ObjectActAnims		EQU		ObjectDefAnims+(O_AnimSize*30)
AmmoGive			EQU		ObjectActAnims+(O_AnimSize*30)
AmmoGiveLen			EQU		22*2
GunGive				EQU		AmmoGive+(AmmoGiveLen*30)
GunGiveLen			EQU		12*2
AlienAnimData		EQU		GunGive+(GunGiveLen*30)
A_FrameLen			EQU		11
A_OptLen			EQU		A_FrameLen*20
A_AnimLen			EQU		A_OptLen*11
VectorGfxNames		EQU		AlienAnimData+A_AnimLen*20
WallGFXNames		EQU		VectorGfxNames+64*30
WallHeights			EQU		WallGFXNames+(64*16)
AlienBrights		EQU		WallHeights+(16*2)
GunObjects			EQU		AlienBrights+20*2
PLR1ALIEN			EQU		GunObjects+(10*2)
PLR2ALIEN			EQU		PLR1ALIEN+2
FloorData			EQU		PLR2ALIEN+2
AlienShotOffsets	EQU		FloorData+16*4
BackSFX				EQU		AlienShotOffsets+20*8
LevelMusic			EQU		BackSFX+16*2
EchoTable			EQU		LevelMusic+16*64
LinkFileLen			EQU		EchoTable+60

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

*****************************
* Data Offset Defs **********
*****************************
	; todo - what gives with the 16-bit alignment of these?
	STRUCTURE ZoneT,2
		ULONG ZoneT_Floor_l
		ULONG ZoneT_Roof_l
		ULONG ZoneT_UpperFloor_l
		ULONG ZoneT_UpperRoof_l
		ULONG ZoneT_Water_l

		UWORD ZoneT_Brightness_w
		UWORD ZoneT_UpperBrightness_w
		UWORD ZoneT_ControlPoint_w		; really UBYTE[2]
		UWORD ZoneT_BackSFXMask_w		; Originally long but always accessed as word
		UWORD ZoneT_Unused_w            ; so this is the unused half
		UWORD ZoneT_ExitList_w
		UWORD ZoneT_Points_w

		UBYTE ZoneT_Back_b				; unused
		UBYTE ZoneT_Echo_b

		UWORD ZoneT_TelZone_w
		UWORD ZoneT_TelX_w
		UWORD ZoneT_TelZ_w
		UWORD ZoneT_FloorNoise_w
		UWORD ZoneT_UpperFloorNoise_w
		UWORD ZoneT_ListOfGraph_w

*****************************
* Graphics definitions ******
*****************************

KeyGraph0		EQU		256*65536*19
KeyGraph1		EQU		256*65536*19+32
KeyGraph2		EQU		(256*19+128)*65536
KeyGraph3		EQU		(256*19+128)*65536+32
Nas1ClosedMouth	EQU		256*5*65536
MediKit_Graph	EQU		256*10*65536
BigGun_Graph	EQU		256*10*65536+32

