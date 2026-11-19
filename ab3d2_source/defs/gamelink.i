
;**************************
;* Game link file offsets *
;**************************

O_FrameStoreSize 	EQU		6
O_AnimSize			EQU		O_FrameStoreSize*20
AmmoGiveLen			EQU		22*2
GunGiveLen			EQU		12*2
A_FrameLen			EQU		11
A_OptLen			EQU		A_FrameLen*20
A_AnimLen			EQU		A_OptLen*11

GLFT_OBJ_NAME_LENGTH EQU 20
GLFT_GUN_NAME_LENGTH EQU 20
GLFT_BUL_NAME_LENGTH EQU 20

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
		STRUCT GLFT_BulletNames_l,(NUM_BULLET_DEFS*GLFT_BUL_NAME_LENGTH)
		STRUCT GLFT_GunNames_l,(NUM_GUN_DEFS*GLFT_GUN_NAME_LENGTH)
		STRUCT GLFT_ShootDefs_l,(NUM_GUN_DEFS*ShootT_SizeOf_l)
		STRUCT GLFT_AlienNames_l,(NUM_ALIEN_DEFS*20)
		STRUCT GLFT_AlienDefs_l,(NUM_ALIEN_DEFS*AlienT_SizeOf_l)
		STRUCT GLFT_FrameData_l,7680 								; todo - figure out how this is derived
		STRUCT GLFT_ObjectNames_l,(NUM_OBJECT_DEFS*GLFT_OBJ_NAME_LENGTH)
		STRUCT GLFT_ObjectDefs,(NUM_OBJECT_DEFS*ODefT_SizeOf_l)
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
