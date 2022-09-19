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

	; Game Link File: Bullet Definition
	STRUCTURE GLF_BulT,0
		ULONG GLF_BulT_VisibleOrInstant_l
		ULONG GLF_BulT_Gravity_l
		ULONG GLF_BulT_LifeTime_l
		ULONG GLF_BulT_AmmoInClip_l
		ULONG GLF_BulT_BounceOffWalls_l
		ULONG GLF_BulT_BounceOffFloors_l
		ULONG GLF_BulT_DamageToTarget_l
		ULONG GLF_BulT_ExplosiveForce_l
		ULONG GLF_BulT_MovementSpeed_l
		ULONG GLF_BulT_AnimFrames_l
		ULONG GLF_BulT_PopFrames_l
		ULONG GLF_BulT_BounceSFX_l
		ULONG GLF_BulT_ImpactSFX_l
		ULONG GLF_BulT_GraphType_l
		ULONG GLF_BulT_ImpactGraphicType_l
		LABEL GLF_BulT_StartOfAnim_vb
SOFFSET	    SET	    SOFFSET+(6*20)
		LABEL GLF_BulT_StartOfPop_vb
SOFFSET	    SET	    SOFFSET+(6*20)
		LABEL GLF_BulT_SizeOf_l

BulletNames		equ		BulletAnimData+(20*GLF_BulT_SizeOf_l)
GunNames		equ		BulletNames+20*20

GunBulletTypes	equ		GunNames+10*20

	; Game Link File: Bullet shoot behaviours
	STRUCTURE GLF_ShootT,0
		UWORD GLF_ShootT_BulType_w
		UWORD GLF_ShootT_Delay_w
		UWORD GLF_ShootT_Count_w
		UWORD GLF_ShootT_SFX_w

AlienNames		equ		GunBulletTypes+10*8

AlienStats		equ		AlienNames+20*20
;A_GFXType		equ		0
;A_DefBeh		equ		2
;A_ReactionTime	equ		4
;A_DefSpeed		equ		6

;A_ResBeh		equ		8
;A_ResSpeed		equ		10
;A_ResTimeout	equ		12
;A_DamageToRet	equ		14

;A_DamageToFol	equ		16
;A_FolBeh		equ		18
;A_FolSpeed		equ		20
;A_FolTimeout	equ		22

;A_RetBeh		equ		24
;A_RetSpeed		equ		26
;A_RetTimeout	equ		28
;A_BulletType	equ		30

;A_HitPoints		equ		32
;A_Height		equ		34
;A_WallCollDist	equ		36
;A_TypeOfSplat	equ		38

;A_Auxilliary	equ		40
AlienStatLen	equ		21*2

	; Game Link File: Alien Defs
	STRUCTURE GLF_AlienT,0
		UWORD GLF_AlienT_GFXType_w
		UWORD GLF_AlienT_DefaultBehaviour_w
		UWORD GLF_AlienT_ReactionTime_w
		UWORD GLF_AlienT_DefaultSpeed_w
		UWORD GLF_AlienT_ResponseBehaviour_w
		UWORD GLF_AlienT_ResponseSpeed_w
		UWORD GLF_AlienT_ResponseTimeout_w
		UWORD GLF_AlienT_DamageToRetreat_w
		UWORD GLF_AlienT_DamageToFollowup_w
		UWORD GLF_AlienT_FollowupBehaviour_w
		UWORD GLF_AlienT_FollowupSpeed_w
		UWORD GLF_AlienT_FollowupTimeout_w
		UWORD GLF_AlienT_RetreatBehaviour_w
		UWORD GLF_AlienT_RetreatSpeed_w
		UWORD GLF_AlienT_RetreatTimeout_w
		UWORD GLF_AlienT_BulType_w
		UWORD GLF_AlienT_HitPoints_w
		UWORD GLF_AlienT_Height_w
		UWORD GLF_AlienT_Girth_w
		UWORD GLF_AlienT_SplatType_w
		UWORD GLF_AlienT_Auxilliary_w
		LABEL GLF_AlienT_SizeOf_l

FrameData		equ		AlienStats+(GLF_AlienT_SizeOf_l*20)

ObjectNames		equ		FrameData+7680

ObjectStats		equ		ObjectNames+600
O_Behaviour		equ		0
O_GFXType		equ		2
O_ActiveTimeout	equ		4
O_HitPoints		equ		6
O_ExplosiveForce equ	8
O_Impassible	equ		10
O_DefAnimLen	equ		12
O_ColBoxRad		equ		14
O_ColBoxHeight	equ		16
O_FloorCeiling	equ		18
O_LockToWall	equ		20
O_ActAnimLen	equ		22
O_SoundEffect	equ		24

ObjectStatLen	equ		20*2

ObjectDefAnims	equ		ObjectStats+(ObjectStatLen*30)
O_FrameStoreSize equ	6
O_AnimSize		equ		O_FrameStoreSize*20
ObjectActAnims	equ		ObjectDefAnims+(O_AnimSize*30)

AmmoGive		equ		ObjectActAnims+(O_AnimSize*30)
AmmoGiveLen		equ		22*2

GunGive			equ		AmmoGive+(AmmoGiveLen*30)
GunGiveLen		equ		12*2

AlienAnimData	equ		GunGive+(GunGiveLen*30)
A_FrameLen		equ		11
A_OptLen		equ		A_FrameLen*20
A_AnimLen		equ		A_OptLen*11

VectorGfxNames	equ		AlienAnimData+A_AnimLen*20

WallGFXNames	equ		VectorGfxNames+64*30

WallHeights		equ		WallGFXNames+(64*16)

AlienBrights	equ		WallHeights+(16*2)

GunObjects		equ		AlienBrights+20*2

PLR1ALIEN		equ		GunObjects+(10*2)

PLR2ALIEN		equ		PLR1ALIEN+2

FloorData		equ		PLR2ALIEN+2

AlienShotOffsets equ	FloorData+16*4

BackSFX			equ		AlienShotOffsets+20*8

LevelMusic		equ		BackSFX+16*2

EchoTable		equ		LevelMusic+16*64

LinkFileLen		equ		EchoTable+60

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
auxxoff			equ		44
auxyoff			equ		46
TextToShow		equ		24

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
	STRUCTURE AI_EntT,18
		UBYTE AI_EntT_NumLives_b
		UBYTE AI_EntT_DamageTaken_b
		UBYTE AI_EntT_CurrentMode_b
		UBYTE AI_EntT_TeamNumber_b
		UWORD AI_EntT_CurrentSpeed_w ; unused
		UWORD AI_EntT_TargetHeight_w ; unused
		UWORD AI_EntT_GraphicRoom_w
		UWORD AI_EntT_CurrentControlPoint_w
		UWORD AI_EntT_CurrentAngle_w
		UWORD AI_EntT_TargetControlPoint_w
		UWORD AI_EntT_Timer1_w
		ULONG AI_EntT_EnemyFlags_l
		UWORD AI_EntT_Timer2_w
		UWORD AI_EntT_ImpactX_w
		UWORD AI_EntT_ImpactZ_w
		UWORD AI_EntT_ImpactY_w
		UWORD AI_EntT_VelocityY_w
		UWORD AI_EntT_DoorsHeld_w
		UWORD AI_EntT_Timer3_w
		; union field of UWORD, UBYTE[2]
		LABEL AI_EntT_Timer4_w
		UBYTE AI_EntT_Type_b
		UBYTE AI_EntT_WhichAnim_b

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
	STRUCTURE Lvl_ZoneT,2
		ULONG Lvl_ZoneT_Floor_l
		ULONG Lvl_ZoneT_Roof_l
		ULONG Lvl_ZoneT_UpperFloor_l
		ULONG Lvl_ZoneT_UpperRoof_l
		ULONG Lvl_ZoneT_Water_l

		UWORD Lvl_ZoneT_Brightness_w
		UWORD Lvl_ZoneT_UpperBrightness_w
		UWORD Lvl_ZoneT_ControlPoint_w		; really UBYTE[2]
		UWORD Lvl_ZoneT_BackSFXMask_w		; Originally long but always accessed as word
		UWORD Lvl_ZoneT_Unused_w            ; so this is the unused half
		UWORD Lvl_ZoneT_ExitList_w
		UWORD Lvl_ZoneT_Points_w

		UBYTE Lvl_ZoneT_Back_b				; unused
		UBYTE Lvl_ZoneT_Echo_b

		UWORD Lvl_ZoneT_TelZone_w
		UWORD Lvl_ZoneT_TelX_w
		UWORD Lvl_ZoneT_TelZ_w
		UWORD Lvl_ZoneT_FloorNoise_w
		UWORD Lvl_ZoneT_UpperFloorNoise_w
		UWORD Lvl_ZoneT_ListOfGraph_w

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

* Object numbers:
* 0 = alien
* 1 = medikit
* 2 = bullet
* 3 = BigGun
* 4 = Key
* 5 = Marine
* 6 = Robot

;dc.l AlienNames
;dc.l ObjectNames
;dc.l ObjectStats
;dc.l AlienStats
;dc.l WallGFXNames
;dc.l FloorData
