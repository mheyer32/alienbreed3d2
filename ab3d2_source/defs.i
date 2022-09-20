
* Structures
	; Bullet definition
	STRUCTURE BulT,0
		ULONG BulT_IsHitScan_l
		ULONG BulT_Gravity_l
		ULONG BulT_Lifetime_l
		ULONG BulT_AmmoInClip_l
		ULONG BulT_BounceHoriz_l
		ULONG BulT_BounceVert_l
		ULONG BulT_HitDamage_l
		ULONG BulT_ExplosiveForce_l
		ULONG BulT_Speed_l
		ULONG BulT_AnimFrames_l
		ULONG BulT_PopFrames_l
		ULONG BulT_BounceSFX_l
		ULONG BulT_ImpactSFX_l
		ULONG BulT_GraphicType_l
		ULONG BulT_ImpactGraphicType_l
		LABEL BulT_AnimData_vb
SOFFSET	    SET	    SOFFSET+(6*20)
		LABEL BulT_PopData_vb
SOFFSET	    SET	    SOFFSET+(6*20)
		LABEL BulT_SizeOf_l

	; Bullet shoot definition
	STRUCTURE ShootT,0
		UWORD ShootT_BulType_w
		UWORD ShootT_Delay_w
		UWORD ShootT_BulCount_w
		UWORD ShootT_SFX_w
		LABEL ShootT_SizeOf_l

**************************
* Game link file offsets *
**************************



LevelName			EQU	64
ObjectGfxNames		EQU	LevelName+40*16
SFXFilenames		EQU	ObjectGfxNames+64*30
FloorTileFilename	EQU	SFXFilenames+64*60
TextureFilename		EQU	FloorTileFilename+64
GunGFXFilename		EQU	FloorTileFilename+256
BlurbFileName		EQU	GunGFXFilename+64
BulletAnimData		EQU	BlurbFileName+64



BulletNames		EQU		BulletAnimData+(20*BulT_SizeOf_l)
GunNames		EQU		BulletNames+20*20

GunBulletTypes	EQU		GunNames+10*20



AlienNames		EQU		GunBulletTypes+10*8
AlienStats		EQU		AlienNames+20*20

	; Game Link File: Alien Defs
	STRUCTURE AlienT,0
		UWORD AlienT_GFXType_w
		UWORD AlienT_DefaultBehaviour_w
		UWORD AlienT_ReactionTime_w
		UWORD AlienT_DefaultSpeed_w
		UWORD AlienT_ResponseBehaviour_w
		UWORD AlienT_ResponseSpeed_w
		UWORD AlienT_ResponseTimeout_w
		UWORD AlienT_DamageToRetreat_w
		UWORD AlienT_DamageToFollowup_w
		UWORD AlienT_FollowupBehaviour_w
		UWORD AlienT_FollowupSpeed_w
		UWORD AlienT_FollowupTimeout_w
		UWORD AlienT_RetreatBehaviour_w
		UWORD AlienT_RetreatSpeed_w
		UWORD AlienT_RetreatTimeout_w
		UWORD AlienT_BulType_w
		UWORD AlienT_HitPoints_w
		UWORD AlienT_Height_w
		UWORD AlienT_Girth_w
		UWORD AlienT_SplatType_w
		UWORD AlienT_Auxilliary_w
		LABEL AlienT_SizeOf_l

FrameData		EQU		AlienStats+(AlienT_SizeOf_l*20)
ObjectNames		EQU		FrameData+7680
ObjectStats		EQU		ObjectNames+600

	; Game Link File: Object Defs
	STRUCTURE ObjT,0
		UWORD ObjT_Behaviour_w
		UWORD ObjT_GFXType_w
		UWORD ObjT_ActiveTimeout_w
		UWORD ObjT_HitPoints_w
		UWORD ObjT_ExplosiveForce_w	; unused
		UWORD ObjT_Impassible_w		; unused
		UWORD ObjT_DefaultAnimLen_w	; unused
		UWORD ObjT_CollideRadius_w
		UWORD ObjT_CollideHeight_w
		UWORD ObjT_FloorCeiling_w
		UWORD ObjT_LockToWall_w		; unused
		UWORD ObjT_ActiveAnimLen_w	; unused
		UWORD ObjT_SFX_w
;SOFFSET	    SET	    SOFFSET+(14)    ; TotalSize 40
;		LABEL ObjT_SizeOf_l

ObjT_SizeOf_l	EQU 40

ObjectDefAnims	EQU		ObjectStats+(ObjT_SizeOf_l*30)
O_FrameStoreSize EQU	6
O_AnimSize		EQU		O_FrameStoreSize*20
ObjectActAnims	EQU		ObjectDefAnims+(O_AnimSize*30)

AmmoGive		EQU		ObjectActAnims+(O_AnimSize*30)
AmmoGiveLen		EQU		22*2

GunGive			EQU		AmmoGive+(AmmoGiveLen*30)
GunGiveLen		EQU		12*2

AlienAnimData	EQU		GunGive+(GunGiveLen*30)
A_FrameLen		EQU		11
A_OptLen		EQU		A_FrameLen*20
A_AnimLen		EQU		A_OptLen*11

VectorGfxNames	EQU		AlienAnimData+A_AnimLen*20
WallGFXNames	EQU		VectorGfxNames+64*30
WallHeights		EQU		WallGFXNames+(64*16)
AlienBrights	EQU		WallHeights+(16*2)
GunObjects		EQU		AlienBrights+20*2
PLR1ALIEN		EQU		GunObjects+(10*2)
PLR2ALIEN		EQU		PLR1ALIEN+2
FloorData		EQU		PLR2ALIEN+2
AlienShotOffsets EQU	FloorData+16*4
BackSFX			EQU		AlienShotOffsets+20*8
LevelMusic		EQU		BackSFX+16*2
EchoTable		EQU		LevelMusic+16*64
LinkFileLen		EQU		EchoTable+60

*****************************
* Bullet object definitions *
*****************************

shotxvel		EQU		18
shotzvel		EQU		22

shotpower		EQU		28
shotstatus		EQU		30
shotsize		EQU		31

shotyvel		EQU		42
accypos			EQU		44
auxxoff			EQU		44
auxyoff			EQU		46
TextToShow		EQU		24

shotanim		EQU		52
shotgrav		EQU		54
shotimpact		EQU		56
shotlife		EQU		58
shotflags		EQU		60
worry			EQU		62
ObjInTop		EQU		63

*****************************
* Nasty definitions *********
*****************************

	; Extended data for AI entities
	; TODO - move this to a .i definition file for the AI module
	;      - Can this be reorganised ?
	STRUCTURE EntT,18
		UBYTE EntT_NumLives_b
		UBYTE EntT_DamageTaken_b
		UBYTE EntT_CurrentMode_b
		UBYTE EntT_TeamNumber_b
		UWORD EntT_CurrentSpeed_w ; unused
		UWORD EntT_TargetHeight_w ; unused
		UWORD EntT_GraphicRoom_w
		UWORD EntT_CurrentControlPoint_w
		UWORD EntT_CurrentAngle_w
		UWORD EntT_TargetControlPoint_w
		UWORD EntT_Timer1_w
		ULONG EntT_EnemyFlags_l
		UWORD EntT_Timer2_w
		UWORD EntT_ImpactX_w
		UWORD EntT_ImpactZ_w
		UWORD EntT_ImpactY_w
		UWORD EntT_VelocityY_w
		UWORD EntT_DoorsHeld_w
		UWORD EntT_Timer3_w
		; union field of UWORD, UBYTE[2]
		LABEL EntT_Timer4_w
		UBYTE EntT_Type_b
		UBYTE EntT_WhichAnim_b
		LABEL EntT_SizeOf_l

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

