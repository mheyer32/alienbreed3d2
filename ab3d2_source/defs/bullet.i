

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


	; Runtime projectile extension for ObjT
	STRUCTURE ShotT,ObjT_Header_SizeOf_l
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
