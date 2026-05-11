#ifndef _TKG_GMOD_H_
#   define _TKG_GMOD_H_

#include "game_mod_format.h"

/**
 * Import InventoryConsumables, needed for GMod_InventoryLimits Limits
 */
#include "inventory.h"

/**********************************************************************************************************************/

/**
 * GMod_InventoryLimits
 *
 * Defines limits on the Inventory carry. Alias of existing InventoryConsumables.
 *
 * Used in:
 *     - Main Game Modification (initial defaults)
 *     - Player Progression (current limits)
 */
typedef InventoryConsumables GMod_InventoryLimits;

/**********************************************************************************************************************/

/**
 * Additional Chunk Idents
 */
enum {
    IDENT_INVL = 0x494E564C,    // Inventory Limits (used in: GMOD, GPRG)
    IDENT_WADJ = 0x5741444A,    // Weapon adjustments (used in: GMOD, GPRG)
    IDENT_SPAB = 0x53504142,    // Special Ammo Bonuses (used in: GMOD)
    IDENT_RWRD = 0x52575244,    // Rewards (used in: GMOD)
    IDENT_ACHV = 0x41434856,    // Achievements (used in: GMOD)
    IDENT_CTRS = 0x5741444A,    // Counters (used in: GPRG)
    IDENT_UNLK = 0x554E4C4B,    // Unlocked (used in: GPRG)
};

/**********************************************************************************************************************/

/**
 * GMod_Reward (header structure only)
 *
 * Defines a reward structure, which applied modifications to player items and carry limits.
 *
 * Used in:
 *     - Main Game Modification
 */
typedef struct {
    char const* rwrd_Description;
    UWORD       rwrd_CarryOffset;
    UWORD       rwrd_ImmediateOffset;
    UWORD       rwrd_RewardData[1];     // Beware: varying length data here.
} ASM_ALIGN(sizeof(ULONG)) GMod_Reward;

/**********************************************************************************************************************/

/**
 * GMod_SpecialAmmoBonus
 *
 * Defines rewards associated with collecting of special ammo types.
 *
 * Used in:
 *     - Main Game Modification
 */
typedef struct {
    UWORD              spab_Index;
    UWORD              spab_AmmoID;
    GMod_Reward const* spab_Reward;
} ASM_ALIGN(sizeof(ULONG)) GMod_SpecialAmmoBonus; // 8 bytes

/**********************************************************************************************************************/

/**
 * GMod_Achievement
 *
 * Defines rewards associated with collecting of special ammo types.
 *
 * Used in:
 *     - Main Game Modification
 */
typedef struct {
    char const*        achv_Description;
    GMod_Reward const* achv_Reward;
    UWORD              achv_RuleType;
    UWORD              achv_EventMask;  // Must be zero in file.
    union {
        UBYTE          bytes[20]; // Varies depending on rule type

        // Structure mappings
        struct {
            ULONG uCount;
            UWORD uAlienType;
        } ASM_ALIGN(sizeof(UWORD)) oKillCount;

        struct {
            ULONG uCount;
            ULONG uAlienMask;
        } ASM_ALIGN(sizeof(UWORD)) oGroupKillCount;

        struct {
            UWORD uLevel;
            UWORD uZoneID;
        } ASM_ALIGN(sizeof(UWORD)) oZoneFound;

        struct {
            ULONG uCount;
            UWORD bOverall;
            UWORD uMask;
        } ASM_ALIGN(sizeof(UWORD)) oMaskedLevelCount;

    } achv_Param;
} ASM_ALIGN(sizeof(ULONG)) GMod_Achievement; // 32 bytes

/**********************************************************************************************************************/

/**
 * GMod_WeaponAdjustment
 *
 * Defines a behavioural adjustment for a weapon.
 *
 * Used in:
 *     - Main Game Modification (initial defaults)
 *     - Player Progression (current values)
 */
typedef struct {
    UWORD wadj_SlotID;
    WORD  wadj_XOffset;
    WORD  wadj_YOffset;
    WORD  wadj_Recoil;
    WORD  wadj_Spray;
    UWORD wadj_BurstLimit;
    UWORD wadj_CoolDown;
    UWORD wadj_Flags;
} ASM_ALIGN(sizeof(UWORD)) GMod_WeaponAdjustment; // 16 bytes

/**
 * GMod_WeaponAdjustment.wadj_Flags
 */
#define WAF_NO_RUN            0x0001
#define WAF_NO_CROUCH         0x0002
#define WAF_NO_FLY            0x0004
#define WAF_NO_FIRE_SUBMERGED 0x0008

/**********************************************************************************************************************/

/**
 * GMod_ProgressCounters
 *
 * Contains progress statistics.
 *
 * Used in:
 *     - Player Progression
 */
typedef struct {
    /**
     * Record the expected counts of data which will help if this is ever expanded.
     */
    UWORD prgc_LevelCount;       // NUM_LEVELS
    UWORD prgc_AmmoDefCount;     // NUM_BULLET_DEFS
    UWORD prgc_AlienDefCount;    // NUM_ALIEN_DEFS
    UWORD prgc_Reserved;

    /** The best elapsed time so far for each level. Only level completion counts */
    ULONG prgc_LevelBestTimes[NUM_LEVELS];

    /** Total number of times the player has attempted a level */
    UWORD prgc_LevelPlayCounts[NUM_LEVELS];

    /** Total number of times the player has beaten a level */
    UWORD prgc_LevelWonCounts[NUM_LEVELS];

    /** Total number of times the player failed a level */
    UWORD prgc_LevelFailCounts[NUM_LEVELS];

    /** The number of times so far the player has bested their previous time record */
    UWORD prgc_LevelImprovedTimeCounts[NUM_LEVELS];

    /** Total number of times the player has killed each class of alien */
    UWORD prgc_AlienKills[NUM_ALIEN_DEFS];

    /** The following totals fields are defined in the same order as for InventoryConsumables, but are 32-bit */

    /** Total health collected */
    ULONG prgc_TotalHealthCollected;

    /** Total fuel collected */
    ULONG prgc_TotalFuelCollected;

    /** Total ammo collected, per ammo class */
    ULONG prgc_TotalAmmoFound[NUM_BULLET_DEFS];
} ASM_ALIGN(sizeof(ULONG)) GMod_ProgressCounters;

/**********************************************************************************************************************/

/**
 * 11:5 Bitfields < Months since AmigaDOS Epoch 1978-01-01>:< Calendar Day Of Month (1-31) >
 * 0 is regarded as "not defined"
 */
typedef UWORD ShortDate;

/**
 * GMod_ProgressAchieved
 *
 * Lists the date and ID of unlocked Achievements
 *
 * Used in:
 *     - Player Progression
 */
typedef struct {
    ShortDate gpc_Awarded; // Date Awarded
    UWORD     gpc_ID;       // Index of Achievement
} ASM_ALIGN(sizeof(UWORD)) GMod_Unlocked;


/**********************************************************************************************************************/

/**
 * Default definitions for the game modification. The pointers here will be initialised with either the
 * data from the loaded mod, some global definition, or NULL.
 *
 * Some data are not fixed size. Those include a corresponding counter.
 */
typedef struct {
    /** Loaded file data */
    GMF_Data const*                 gmod_Loaded;
    GMod_InventoryLimits const*     gmod_DefinedInventoryLimits;
    GMod_SpecialAmmoBonus const*    gmod_DefinedSpecialAmmoBonuses;
    GMod_WeaponAdjustment const*    gmod_DefinedWeaponAdjustments;
    GMod_Achievement const*         gmod_DefinedAchievements;
    ULONG                           gmod_NumDefinedSpecialAmmoBonuses;
    ULONG                           gmod_NumDefinedWeaponAdjustments;
    ULONG                           gmod_NumDefinedAchievements;
} GMod_DefaultProperties;

extern GMod_DefaultProperties GMod_Defaults; // Defined in BSS

/**********************************************************************************************************************/

/**
 * Note: This is the runtime representation of player progression.
 */
typedef struct {
    GMod_InventoryLimits    pprg_InventoryLimits;
    GMod_WeaponAdjustment   pprg_WeaponAdjustments[NUM_GUN_DEFS];
    GMod_ProgressCounters   pprg_Counters;

    /** Dynamically allocated, count matches GMod_DefaultProperties.gmod_NumDefinedAchievements */
    ShortDate* pprg_Unlocked;

    /** Bitmap of already unlocked achievements, for quick testing via tst.b */
    UBYTE*     pprg_UnlockedMap;
} GMod_PlayerProgression;

extern GMod_PlayerProgression GMod_Progress; // In BSS

/**********************************************************************************************************************/

/**
 * GMod_Init()
 *
 * Attempts to load the Game Modification File and apply the settings
 */
extern void GMod_Init(void);

/**********************************************************************************************************************/

/**
 * GMod_Done()
 *
 * Releases any resources acquired by GMod_Init()
 */
extern void GMod_Done(void);

/**********************************************************************************************************************/

/**
 * GMod_LoadModDefaults()
 *
 * Attempts to load the defaults for the current game modification, if any.
 * Returns true if a viable modification file was found and processed correctly.
 */
extern BOOL GMod_LoadModDefaults(void);

/**********************************************************************************************************************/

/**
 * GMod_LoadPlayerProgress()
 *
 * Attempts to load the the progress for the current player, updating the current modification limits accordingly.
 */
extern void GMod_LoadPlayerProgress(void);

/**********************************************************************************************************************/

/**
 * GMod_ApplyReward()
 *
 * Applies the reward definition to the inventory limits and current carry.
 */
extern void GMod_ApplyReward(
    GMod_Reward const*    pReward,
    GMod_InventoryLimits* pInventoryLimits,
    InventoryConsumables* pInventoryConsumables
);

#endif
