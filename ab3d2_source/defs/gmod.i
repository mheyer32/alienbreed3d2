	; Game Modification Structures

NUM_INVENTORY_ITEMS EQU (NUM_GUN_DEFS+2)
NUM_INVENTORY_CONSUMABLES EQU (NUM_BULLET_DEFS+2)

MAX_ACHIEVEMENTS EQU 128

	; Inventory consumables (health/fuel/ammo)
	STRUCTURE InvCT,0
		UWORD InvCT_Health_w		        ; 2
		UWORD InvCT_JetpackFuel_w			; 2
		UWORD InvCT_AmmoCounts_vw			; 40 - UWORD[NUM_BULLET_DEFS]
		PADDING (NUM_BULLET_DEFS*2)-2
		LABEL InvCT_SizeOf_l				; 44


	; Inventory items (weapons/jetpack/shield)
	STRUCTURE InvIT,0
		UWORD InvIT_Shield_w				; 2
		UWORD InvIT_JetPack_w				; 2
		UWORD InvIT_Weapons_vw				; 20 - UWORD[NUM_GUN_DEFS]
		PADDING (NUM_GUN_DEFS*2)-2
		LABEL InvIT_SizeOf_l				; 24

	; Full Inventory (player/collectable)
	STRUCTURE InvT,0
		STRUCT InvT_Consumables,(InvCT_SizeOf_l)	; 44
		STRUCT InvT_Items,(InvIT_SizeOf_l)			; 24
		LABEL InvT_SizeOf_l							; 68

	; TODO - Incorporate game_mod.h data structures here
	; GMod_DefaultProperties
	; GMod_PlayerProgression
	; - GMod_WeaponAdjustment
	; - GMod_ProgressCounters

	; Weapon Adjustment: see game_mod.h/ GMod_WeaponAdjustment
	STRUCTURE WAdjT,0
		UWORD	WAdjT_SlotID_w			; 0, 2
		WORD	WAdjT_XOffset_w			; 2, 2
		WORD	WAdjT_YOffset_w			; 4, 2
		WORD	WAdjT_Recoil_w			; 6, 2
		WORD	WAdjT_Spray_w			; 8, 2
		UWORD	WAdjT_BurstLimit_w		; 10, 2
		UWORD	WAdjT_CoolDown_w		; 12, 2
		UWORD	WAdjT_Flags_w			; 14, 2
		LABEL	WAdjT_SizeOf_l			; 16

	; Progress Counters: see game_mod.h / GMod_ProgressCounters
	STRUCTURE	GPCT,0

		LABEL	GPCT_SizeOf_l

    ; TODO - this needs to be replaced
	; Custom game properties
	STRUCTURE GModT,0
		; Default inventory limits
		STRUCTURE GModT_MaxInv,(InvCT_SizeOf_l)		; 44
		UWORD     GModT_NumAchievements             ; 2
		UWORD     GModT_AchievementSize             ; 2
		LABEL GModT_SizeOf_l						; 48

    ; TODO - this needs to be replaced
	; Game statistics
	STRUCTURE GStatT,0
		; Progressed inventory limits
		STRUCTURE GStatT_MaxInv,(InvCT_SizeOf_l)	; 44

		; Best time so far for each level
		ULONG GStatT_LevelBestTimes_vl              ; 64 - ULONG[NUM_LEVELS]
		PADDING (NUM_LEVELS*4)-4

		; Number of times each level attempted
		UWORD GStatT_LevelPlayCounts_vw			; 32 - UWORD[NUM_LEVELS]
		PADDING (NUM_LEVELS*2)-2

		; Number of times each level beaten
		UWORD GStatT_LevelWonCounts_vw			; 32 - UWORD[NUM_LEVELS]
		PADDING (NUM_LEVELS*2)-2

		; Number of times killed in each level
		UWORD GStatT_LevelFailCounts_vw			; 32 - UWORD[NUM_LEVELS]
		PADDING (NUM_LEVELS*2)-2

		; Number of times the player has improved their best time, per level
		UWORD GStatT_LevelImprovedTimeCounts_vw	; 32 - UWORD[NUM_LEVELS]
		PADDING (NUM_LEVELS*2)-2

		; Number of aliens killed, by type
		UWORD GStatT_AlienKills_vw
		PADDING (NUM_ALIEN_DEFS*2)-2			; 40 - UWORD[NUM_ALIEN_DEFS]

		; Total health collected
		ULONG GStatT_TotalHealthCollected_w     ; 4

		; Total fuel collected
		ULONG GStatT_TotalFuelCollected_w       ; 4

		; Total ammo collected, per ammo class
		ULONG GStatT_TotalAmmoFound_vw
		PADDING (NUM_BULLET_DEFS*4)-4           ; 80 UWORD[NUM_BULLET_DEFS]

		UBYTE GStatT_Achieved_vb
		PADDING (MAX_ACHIEVEMENTS/8)-1

		LABEL GStatT_SizeOf_l

		; TODO GPrefsT

GAME_EVENTBIT_KILL EQU 0
GAME_EVENTBIT_ZONE_CHANGE EQU 1
GAME_EVENTBIT_LEVEL_START  EQU 2
