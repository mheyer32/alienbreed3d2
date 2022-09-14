**************************
* Game link file offsets *
**************************

LevelName		EQU		64

ObjectGfxNames	EQU		LevelName+40*16

SFXFilenames	EQU		ObjectGfxNames+64*30

FloorTileFilename EQU	SFXFilenames+64*60
TextureFilename	EQU		FloorTileFilename+64

GunGFXFilename	equ		FloorTileFilename+256

BlurbFileName	equ		GunGFXFilename+64

BulletAnimData	equ		BlurbFileName+64
B_VisibleOrInstant equ	0
B_Gravity		equ		4
B_LifeTime		equ		8
B_AmmoInClip	equ		12
B_BounceOffWalls equ	16
B_BounceOffFloors equ	20
B_DamageToTarget equ	24
B_ExplosiveForce equ	28
B_MovementSpeed	equ		32
B_AnimFrames	equ		36
B_PopFrames		equ		40
B_BounceSFX		equ		44
B_ImpactSFX		equ		48
B_GraphType		equ		52
B_ImpactGraphicType equ	56
B_StartOfAnim	equ		60
B_StartOfPop	equ		B_StartOfAnim+6*20
B_BulStatLen	equ		B_StartOfAnim+(6*20*2)

BulletNames		equ		BulletAnimData+(20*B_BulStatLen)

GunNames		equ		BulletNames+20*20

GunBulletTypes	equ		GunNames+10*20
G_BulletType	equ		0
G_DelayBetweenShots equ	2
G_BulletsPerShot equ	4
;G_InitialYVel equ 6
G_SoundEffect	equ		6

AlienNames		equ		GunBulletTypes+10*8

AlienStats		equ		AlienNames+20*20
A_GFXType		equ		0
A_DefBeh		equ		2
A_ReactionTime	equ		4
A_DefSpeed		equ		6
A_ResBeh		equ		8
A_ResSpeed		equ		10
A_ResTimeout	equ		12
A_DamageToRet	equ		14
A_DamageToFol	equ		16
A_FolBeh		equ		18
A_FolSpeed		equ		20
A_FolTimeout	equ		22
A_RetBeh		equ		24
A_RetSpeed		equ		26
A_RetTimeout	equ		28
A_BulletType	equ		30
A_HitPoints		equ		32
A_Height		equ		34
A_WallCollDist	equ		36
A_TypeOfSplat	equ		38
A_Auxilliary	equ		40
AlienStatLen	equ		21*2

FrameData		equ		AlienStats+(AlienStatLen*20)

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

ToZoneFloor		EQU		2
ToZoneRoof		EQU		6
ToUpperFloor	EQU		10
ToUpperRoof		EQU		14

ToZoneWater		EQU		18

ToZoneBrightness EQU	22
ToUpperBrightness EQU	24
ToZoneCpt		EQU		26
ToWallList		EQU		28
ToBackSFX		EQU		28

ToExitList		EQU		32
ToZonePts		EQU		34
ToBack			EQU		36
ToEcho			EQU		37
ToTelZone		EQU		38
ToTelX			EQU		40
ToTelZ			EQU		42
ToFloorNoise	EQU		44
ToUpperFloorNoise EQU	46
ToListOfGraph	EQU		48

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
