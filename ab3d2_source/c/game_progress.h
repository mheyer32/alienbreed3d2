#ifndef _TKG_GMOD_PROGRESS_H_
#   define _TKG_GMOD_PROGRESS_H_

#include "game_mod_common.h"

enum {
    IDENT_GPRG = 0x47505247,
    IDENT_CTRS = 0x5741444A,
    IDENT_ACHD = 0x41434844
};

/**
 * Counters chunk data
 */
typedef struct {
    UWORD gpc_LevelCount;       // NUM_LEVELS
    UWORD gpc_AmmoDefCount;     // NUM_BULLET_DEFS
    UWORD gpc_AlienDefCount;    // NUM_ALIEN_DEFS
    UWORD gpc_Reserved;

    /** The best elapsed time so far for each level. Only level completion counts */
    ULONG gpc_LevelBestTimes[NUM_LEVELS];

    /** Total number of times the player has attempted a level */
    UWORD gpc_LevelPlayCounts[NUM_LEVELS];

    /** Total number of times the player has beaten a level */
    UWORD gpc_LevelWonCounts[NUM_LEVELS];

    /** Total number of times the player failed a level */
    UWORD gpc_LevelFailCounts[NUM_LEVELS];

    /** The number of times so far the player has bested their previous time record */
    UWORD gpc_LevelImprovedTimeCounts[NUM_LEVELS];

    /** Total number of times the player has killed each class of alien */
    UWORD gpc_AlienKills[NUM_ALIEN_DEFS];

    /** The following totals fields are defined in the same order as for InventoryConsumables, but are 32-bit */

    /** Total health collected */
    ULONG gpc_TotalHealthCollected;

    /** Total fuel collected */
    ULONG gpc_TotalFuelCollected;

    /** Total ammo collected, per ammo class */
    ULONG gpc_TotalAmmoFound[NUM_BULLET_DEFS];
} ASM_ALIGN(sizeof(ULONG)) GMod_ProgressCounters;

typedef struct {
    struct {
        UWORD gpc_DateAwarded;
        UWORD gpc_AchievementID;
    } gpc_Achieved [1]; // Varying
} ASM_ALIGN(sizeof(UWORD)) GMod_ProgressAchieved;

#endif
