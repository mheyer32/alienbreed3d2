#ifndef GAME_H
#define GAME_H
#include <SDI_compiler.h>
#include "defs.h"

/** Inventory limits for the default game */
#define GAME_DEFAULT_AMMO_LIMIT 10000
#define GAME_DEFAULT_HEALTH_LIMIT 10000
#define GAME_DEFAULT_FUEL_LIMIT 250
#define GAME_UNCAPPED_LIMIT 32000

#define GAME_MODE_SINGLE_PLAYER 'n'
#define GAME_MODE_TWO_PLAYER_MASTER 'm'
#define GAME_MODE_TWO_PLAYER_SLAVE 's'
#define GAME_MAX_ACHIEVEMENTS 128

#define GAME_EVENTBIT_KILL 0
#define GAME_EVENTBIT_ZONE_CHANGE 1
#define GAME_EVENTBIT_LEVEL_START 2
#define GAME_EVENTBIT_ADD_INVENTORY 3

/**
 * Achievement definition
 *
 * The name and description point to a shared strings lump after the achievement data
 * The strings themselves must be 80 chars or less. Thus the maximum size of these data are
 *
 * NUM_ACHIEVEMENTS * sizeof(AchievementStruct) + 2*80*NUM_ACHIEVEMENTS
 */
struct AchievementStruct;
typedef BOOL (*Rule)(struct AchievementStruct const*);
struct AchievementStruct {
    char const* ac_Name;             // 4 4    Name
    char const* ac_RewardDesc;       // 4 8    Reward message

    UWORD       ac_RuleMask;         // 2      Determined at load time
    UWORD       ac_RuleId;           // 2

    UBYTE       ac_RuleParams[8];    // 8 20   Parameters (really a union)
    UWORD       ac_HealthCapBonus;   // 2 24   Health cap increase
    UWORD       ac_HealthBonus;      // 2 22   Immediate health bonus (applies after cap increase)
    UWORD       ac_FuelCapBonus;     // 2 26   Fuel cap bonus
    WORD        ac_AmmoType;         // 2 28   Ammunition type (-1 for none)
    UWORD       ac_AmmoTypeCapBonus; // 2 30   Capacity bonus for ammunition type
    UWORD       ac_AmmoTypeBonus;    // 2 32   Immediate bonus for ammunition type
} __attribute__((packed)) __attribute__ ((aligned (2)));
typedef struct AchievementStruct Achievement;

/**
 * Game Mod Properties
 *
 * Defines special customisations of the loaded mod.
 */
typedef struct {
    InventoryConsumables gmp_MaxInventory;
    UWORD                gmp_NumAchievements;   // Number of defined achievements
    UWORD                gmp_AchievementSize;   // total size of the achivement data ssection (bytes)
    /** TODO other things here ... */
} Game_ModProperties;

/**
 * Player progression
 */
typedef struct {
    /** Current player ammo cap */
    InventoryConsumables gs_MaxInventory;

    // Level related statistics

    /** The best elapsed time so far for each level. Only level completion counts */
    ULONG gs_LevelBestTimes[NUM_LEVELS];

    /** Total number of times the player has attempted a level */
    UWORD gs_LevelPlayCounts[NUM_LEVELS];

    /** Total number of times the player has beaten a level */
    UWORD gs_LevelWonCounts[NUM_LEVELS];

    /** Total number of times the player failed a level */
    UWORD gs_LevelFailCounts[NUM_LEVELS];

    /** The number of times so far the player has bested their previous time record */
    UWORD gs_LevelImprovedTimeCounts[NUM_LEVELS];

    /** Total number of times the player has killed each class of alien */
    UWORD gs_AlienKills[NUM_ALIEN_DEFS];

    /** The following totals fields are defined in the same order as for InventoryConsumables, but are 32-bit */

    /** Total health collected */
    ULONG gs_TotalHealthCollected;

    /** Total fuel collected */
    ULONG gs_TotalFuelCollected;

    /** Total ammo collected, per ammo class */
    ULONG gs_TotalAmmoFound[NUM_BULLET_DEFS];

    /** Bitmap of achievements. A mod may define up to GAME_MAX_ACHIEVEMENTS */
    UBYTE gs_Achieved[GAME_MAX_ACHIEVEMENTS/8];

} Game_PlayerProgression;

/**
 * Startup
 *
 * Load the mod properties, progress and prefs
 */
extern void Game_Init(void);

/**
 * Shutdown
 *
 * Persist progress and prefs
 */
extern void Game_Done(void);

/**
 * Called when something may need to update the player progression
 */
extern void Game_UpdatePlayerProgress(void);

/**
 * Checks if an item can be collected based on the players inventory state and the items Inventory.
 *
 * Returns true when:
 *
 * 1. itemInventory contains an item (weapon, shield, jetpack) that the playerInventory does not have.
 * 2. itemInventory provides ammunition that the playerInventory has less than the limits defined
 *    by the game mod properties in gmp_MaxInventory
 *
 * Note that the consumables and items provided by an entiity are stored in separate arrays in the GLF data, so
 * this function requires pointers to each.
 */
extern BOOL Game_CheckInventoryLimits(
    REG(a0, const Inventory*            inventory),
    REG(a1, const InventoryConsumables* consumables),
    REG(a2, const InventoryItems*       items)
);

/**
 * Add to the player Inventory, respecting the limits set in Game_ModProperties.gmp_MaxInventory.
 *
 * Note that the consumables and items provided by an entiity are stored in separate arrays in the GLF data, so
 * this function requires pointers to each.
 */
extern void Game_AddToInventory(
    REG(a0, Inventory*                  inventory),
    REG(a1, const InventoryConsumables* consumables),
    REG(a2, const InventoryItems*       items)
);

/**
 * Applys the current limits to any saved game after loading.
 */
extern void Game_ApplyInventoryLimits(
    REG(a0, Inventory* inventory)
);

extern void Game_LevelBegin(void);
extern void Game_LevelWon(void);
extern void Game_LevelFailed(void);

#endif // GAME_H
