
	; Object Data Definition
	STRUCTURE ODefT,0
		UWORD ODefT_Behaviour_w		;  0, 2
		UWORD ODefT_GFXType_w		;  2, 2
		UWORD ODefT_ActiveTimeout_w	;  4, 2
		UWORD ODefT_HitPoints_w		;  6, 2
		UWORD ODefT_ExplosiveForce_w	;  8, 2 unused
		UWORD ODefT_Impassible_w		; 10, 2 unused
		UWORD ODefT_DefaultAnimLen_w	; 12, 2 unused
		UWORD ODefT_CollideRadius_w	; 14, 2
		UWORD ODefT_CollideHeight_w	; 16, 2
		UWORD ODefT_FloorCeiling_w	; 18, 2
		UWORD ODefT_LockToWall_w		; 20, 2 unused
		UWORD ODefT_ActiveAnimLen_w	; 22, 2 unused
		UWORD ODefT_SFX_w			; 24, 2
		PADDING 14					; 26, 14
		LABEL ODefT_SizeOf_l			; 40

OBJ_TYPE_ALIEN EQU 0
OBJ_TYPE_OBJECT EQU 1
OBJ_TYPE_PROJECTILE EQU 2
OBJ_TYPE_AUX EQU 3
OBJ_TYPE_PLAYER1 EQU 4
OBJ_TYPE_PLAYER2 EQU 5

	; Runtime objects are 64 byte structures. The first 18 bytes are common, but the remainder depend on what the type
	; of the object is, e.g. decoration, bullet, alien, collectable etc.
	STRUCTURE ObjT,0
		; TODO work out what the hidden data are.
		; It appears these are accessed as bytes in some use cases, so the probability is that the
		; data is overwritten or repurposed for temporary objects (projectiles/explosions)
		ULONG ObjT_XPos_l			; 0, 4 - To be confirmed
		ULONG ObjT_ZPos_l 			; 4, 4 - To be confirmed
		ULONG ObjT_YPos_l 			; 8, 4 - To be confirmed

		UWORD ObjT_ZoneID_w			; 12, 2 - Zone where the object is located, or -1 if it's been removed
		PADDING 2					; 2     - Unknown
		UBYTE ObjT_TypeID_b			; 16    - Defines the type (alien, bullet, object etc.)
		UBYTE ObjT_SeePlayer_b      ; 17    - Line of sight to player
		LABEL ObjT_Header_SizeOf_l	; 18    - After here, the remaining structure depends on ObjT_TypeID_b
		PADDING 46
		LABEL ObjT_SizeOf_l			; 64

OBJ_PREV	EQU (-ObjT_SizeOf_l)	; object before current
OBJ_NEXT	EQU	ObjT_SizeOf_l		; object after current

	MACRO NEXT_OBJ
	add.w #ObjT_SizeOf_l,\1
	ENDM

	MACRO PREV_OBJ
	sub.w #ObjT_SizeOf_l,\1
	ENDM

	; Runtime entity extension for ObjT
	STRUCTURE EntT,ObjT_Header_SizeOf_l
		UBYTE EntT_HitPoints_b				; 18, 1
		UBYTE EntT_DamageTaken_b			; 19, 1
		UBYTE EntT_CurrentMode_b			; 20, 1
		UBYTE EntT_TeamNumber_b				; 21, 1
		UWORD EntT_CurrentSpeed_w 			; 22, 2 unused
		UWORD EntT_DisplayText_w			; 24, 2
		UWORD EntT_ZoneID_w					; 26, 2 ; todo - how is this related to ObjT_ZoneID_w ?
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

 		; Union
		LABEL EntT_DoorsAndLiftsHeld_l		; 50, 4 ; actually accessd as a long
		PADDING 2
		UWORD EntT_Timer3_w					; 52, 2

		; union field of UWORD, UBYTE[2]
		LABEL EntT_Timer4_w					; 54, 0
		UBYTE EntT_Type_b					; 54, 1
		UBYTE EntT_WhichAnim_b				; 55, 1
		PADDING 8
		LABEL EntT_SizeOf_l					; 64 - This is the actual size in memory

ENT_TYPE_COLLECTABLE	EQU 0
ENT_TYPE_ACTIVATABLE	EQU 1
ENT_TYPE_DESTRUCTABLE	EQU 2
ENT_TYPE_DECORATION		EQU 3

ENT_PREV_2	EQU (-EntT_SizeOf_l*2)	; entity two before current
ENT_PREV	EQU (-EntT_SizeOf_l)	; entity before current
ENT_NEXT	EQU	EntT_SizeOf_l		; entity after current
ENT_NEXT_2	EQU	(EntT_SizeOf_l*2)	; entity two after current
