#include "game.h"
#include "message.h"
#include <devices/timer.h>
#include <proto/timer.h>
#include <proto/exec.h>
#include <dos/dos.h>
#include <proto/dos.h>

extern char const               game_ProgressFile[];
extern Game_ModProperties       game_ModProps;
extern Game_PlayerProgression   game_PlayerProgression;
extern ULONG                    Game_ProgressSignal; // signal to check progress
extern Rule                     game_AchievementRules[];
extern Achievement*             game_AchievementsDataPtr;
extern Inventory                Plr1_Inventory;
extern Inventory                Plr2_Inventory;
extern UWORD Plr1_Zone;
extern UWORD Game_LevelNumber;
extern char  game_BestLevelTimeBuffer[];

static struct timeval game_LevelBegin = { {0}, {0} };
static struct timeval game_LevelEnd   = { {0}, {0} };

/**
 * Load the player's current progression, if any.
 */
void game_LoadPlayerProgression(void)
{
    BPTR gameProgressFH = Open(game_ProgressFile, MODE_OLDFILE);
    if (DOSFALSE == gameProgressFH) {
        // Set the initial state of the player's inventory cap to the default for the game mod.
        CopyMem(
            &game_ModProps.gmp_MaxInventory,
            &game_PlayerProgression.gs_MaxInventory,
            sizeof(InventoryConsumables)
        );
        return;
    }

    LONG read = Read(gameProgressFH, &game_PlayerProgression, sizeof(game_PlayerProgression));
    if (read == sizeof(Game_PlayerProgression)) {
        // Overwrite the inventory cap with the player's progressed version
        CopyMem(
            &game_PlayerProgression.gs_MaxInventory,
            &game_ModProps.gmp_MaxInventory,
            sizeof(InventoryConsumables)
        );
    }
    Close(gameProgressFH);
}

/**
 * Persist the player's current progression.
 */
void game_SavePlayerProgression(void)
{
    BPTR gameProgressFH = Open(game_ProgressFile, MODE_READWRITE);
    if (DOSFALSE == gameProgressFH) {
        return;
    }
    // Persist the progressed inventory limits
    CopyMem(
        &game_ModProps.gmp_MaxInventory,
        &game_PlayerProgression.gs_MaxInventory,
        sizeof(InventoryConsumables)
    );
    Write(gameProgressFH, &game_PlayerProgression, sizeof(game_PlayerProgression));
    Close(gameProgressFH);
}

static inline BOOL game_CheckAchieved(UWORD i)
{
	return game_PlayerProgression.gs_Achieved[(i >> 3)] & (1 << (i & 7));
}

static inline BOOL game_MarkAchieved(UWORD i)
{
	return game_PlayerProgression.gs_Achieved[(i >> 3)] |= (1 << (i & 7));
}

/**
 * Achievement test for killing a single alien class:
 *
 * params {
 *     UWORD alienClass;
 *     UWORD countLimit;
 * }
 *
 */
static BOOL game_AchievementRuleKillCount(Achievement const* achievement)
{
    UWORD const * ac_Params = (UWORD const *)&(achievement->ac_RuleParams[0]);
    return game_PlayerProgression.gs_AlienKills[ac_Params[0]] >= ac_Params[1];
}

/**
 * Achievement test for killing a single alien class:
 *
 * params {
 *     UWORD totalCount;
 *     UWORD consumable; // 0 == health, 1 == fuel, 2... = ammo class 0 ....
 * }
 *
 */
static BOOL game_AchievementRuleStuffCollected(Achievement const* achievement)
{
    ULONG totalCount = *(ULONG const*)&(achievement->ac_RuleParams[0]);
    UWORD consumable = *(UWORD const*)&(achievement->ac_RuleParams[sizeof(ULONG)]);
    ULONG *consumables = &game_PlayerProgression.gs_TotalHealthCollected;
    return consumables[consumable] >= totalCount;
}


/**
 * Achievement test for killing a total of any group of alien classes:
 *
 * params {
 *     ULONG aliemMask; (1 << alienClass for multiple classes)
 *     UWORD countLimit
 * }
 *
 */
static BOOL game_AchievementRuleGroupKillCount(Achievement const* achievement)
{
    ULONG enemyMask  = *(ULONG const*)&(achievement->ac_RuleParams[0]) & ((1 << NUM_ALIEN_DEFS) - 1);
    UWORD countLimit = *(UWORD const*)&(achievement->ac_RuleParams[sizeof(ULONG)]);
    UWORD count      = 0;
    for (UWORD id = 0; id < NUM_ALIEN_DEFS; ++id) {
        if (enemyMask & (1 << id)) {
            count += game_PlayerProgression.gs_AlienKills[id];
        }
        if (count >= countLimit) {
            return TRUE;
        }
    }
    return FALSE;
}

/**
 * Achievement test for finding a specific zone
 *
 * params {
 *     UWORD levelNumber
 *     UWORD zoneID
 * }
 *
 */
static BOOL game_AchievementRuleZoneFound(Achievement const* achievement)
{
    ULONG levelAndZone = ((ULONG)Game_LevelNumber << 16) | Plr1_Zone;
    return levelAndZone == *(ULONG const*)&(achievement->ac_RuleParams[0]);
}

/**
 * Achievement test for level time improvements
 *
 * params {
 *     ULONG levelMask;   Which levels (32 bit to allow expansion in future)
 *     UWORD countLimit;  Number of times an improvement was made
 *     BOOL  overall;     When true, tests the total improvement count across the all levels in the mask.
 *                        When false, test any one of the individual levels must meet the improvement count.
 * }
 *
 */
static BOOL game_AchievementRuleLevelTimeImproved(Achievement const* achievement)
{
    UWORD const * ac_Params = (UWORD const *)&(achievement->ac_RuleParams[0]);
    ULONG levelMask     = *((ULONG*)(&ac_Params[0]));
    UWORD countLimit    = ac_Params[2];
    UWORD count         = 0;
    BOOL  overall       = ac_Params[3];
    for (UWORD levelNum = 0; levelNum < NUM_LEVELS; ++levelNum) {
        if (levelMask & (1 << levelNum)) {
            if (overall) {
                count += game_PlayerProgression.gs_LevelImprovedTimeCounts[levelNum];
            } else {
                count = game_PlayerProgression.gs_LevelImprovedTimeCounts[levelNum];
            }
            if (count >= countLimit) {
                return TRUE;
            }
        }
    }
    return FALSE;
}

/**
 * Achievement test for times the player died
 *
 * params {
 *     ULONG levelMask;   Which levels (32 bit to allow expansion in future)
 *     UWORD countLimit;
 *     BOOL  overall;
 * }
 *
 */
static BOOL game_AchievementRuleTimesDied(Achievement const* achievement)
{
    UWORD const * ac_Params = (UWORD const *)&(achievement->ac_RuleParams[0]);
    ULONG levelMask  = *((ULONG*)(&ac_Params[0]));
    UWORD countLimit = ac_Params[2];
    UWORD count      = 0;
    BOOL  overall    = ac_Params[3];
    for (UWORD levelNum = 0; levelNum < NUM_LEVELS; ++levelNum) {
        if (levelMask & (1 << levelNum)) {
            if (overall) {
                count += game_PlayerProgression.gs_LevelFailCounts[levelNum];
            } else {
                count = game_PlayerProgression.gs_LevelFailCounts[levelNum];
            }
            if (count >= countLimit) {
                return TRUE;
            }
        }
    }
    return FALSE;
}

Rule game_AchievementRules[] = {
    game_AchievementRuleKillCount,
    game_AchievementRuleGroupKillCount,
    game_AchievementRuleZoneFound,
    game_AchievementRuleLevelTimeImproved,
    game_AchievementRuleTimesDied,
    game_AchievementRuleStuffCollected,
};

/**
 * Event signal bit masks. These are masked against the Game_ProgressSignal and where there is a nonzero result
 * the corresponding rule from game_AchievementRules[] needs to be invoked
 */
UWORD game_AchievementRuleMask[] = {
    1 << GAME_EVENTBIT_KILL,
    1 << GAME_EVENTBIT_KILL,
    1 << GAME_EVENTBIT_ZONE_CHANGE,
    1 << GAME_EVENTBIT_LEVEL_START,
    1 << GAME_EVENTBIT_LEVEL_START,
    1 << GAME_EVENTBIT_ADD_INVENTORY,
};

/**
 *  Apply the reward for an achievement.
 *  TODO - multiplayer, figure out what we should be doing here...
 */
static void game_ApplyAchievementReward(Achievement const* achievement)
{
    Msg_PushLine(achievement->ac_RewardDesc, MSG_TAG_OPTIONS|80);

    InventoryConsumables* player_ic = &Plr1_Inventory.inv_Consumables;

    // First, apply any cap modifications
    game_ModProps.gmp_MaxInventory.ic_Health      += achievement->ac_HealthCapBonus;
    game_ModProps.gmp_MaxInventory.ic_JetpackFuel += achievement->ac_FuelCapBonus;

    // Now any instant bonuses
    player_ic->ic_Health += achievement->ac_HealthBonus;

    if (
        achievement->ac_AmmoType > -1 &&
        achievement->ac_AmmoType < NUM_BULLET_DEFS
    ) {
        game_ModProps.gmp_MaxInventory.ic_AmmoCounts[achievement->ac_AmmoType] += achievement->ac_AmmoTypeCapBonus;
        player_ic->ic_AmmoCounts[achievement->ac_AmmoType] += achievement->ac_AmmoTypeBonus;
    }

    // Apply (updated) caps to inventory
    Game_ApplyInventoryLimits(&Plr1_Inventory);
}

/**
 * Called at the end of a frame when the Game_ProgressSignal is non-zero, signifying that a progress event
 * has happened.
 *
 * For each of the defined achievements, we walk the array, skipping any that do not intersect the
 * Game_ProgressSignal bits or that are already marked as achieved.
 *
 * The remainder are evaluated using their enumerated rule function. Any that return true are marked as
 * achieved, the corresponding message is displayed and the reward, if any, is applied.
 */
void Game_UpdatePlayerProgress(void)
{
    Achievement const* achievements = game_AchievementsDataPtr;
    for (UWORD id = 0; id < game_ModProps.gmp_NumAchievements; ++id) {
        /** Early out on any achiecvements where the rule mask doesn't intersect with the event signal */
        if (
            !(Game_ProgressSignal & achievements[id].ac_RuleMask) ||
            game_CheckAchieved(id)
        ) {
            continue;
        }

        if (game_AchievementRules[achievements[id].ac_RuleId](&achievements[id])) {
            Msg_PushLine(achievements[id].ac_Name, MSG_TAG_OPTIONS|80);
            if (achievements[id].ac_RewardDesc) {
                game_ApplyAchievementReward(&achievements[id]);
            }
            game_MarkAchieved(id);
        }
    }
    Game_ProgressSignal = 0;
}

/**
 * @todo - this should probably just be shared with the one in system.c.
 */
static void SAVEDS PutChProc(REG(d0, char c), REG(a3, char** out))
{
    **out = c;
    ++(*out);
}

/**
 * Called whe level begins. Set the level event bit and trigger the status update to capture any
 * pesky level events.
 *
 * If we have played the level before, we show the currently recorded best time for the level.
 */
void Game_LevelBegin(void)
{
    GetSysTime(&game_LevelBegin);
    ++game_PlayerProgression.gs_LevelPlayCounts[Game_LevelNumber];

    if (game_PlayerProgression.gs_LevelBestTimes[Game_LevelNumber]) {
        ULONG time = game_PlayerProgression.gs_LevelBestTimes[Game_LevelNumber];

        char* outPtr = game_BestLevelTimeBuffer;

        UWORD data[5] = { 0, 0, 0, 0, 0 };

        data[4]  = time % 100; time /= 100;
        data[3]  = time % 60;  time /= 60;
        data[2]  = time % 60;  time /= 60;
        data[1]  = time;
        data[0]  = (UWORD)('A' + Game_LevelNumber);

        RawDoFmt(
            "Level %c: Best %dh %02dm %02d.%02ds",
            &data,
            (void (*)()) & PutChProc,
            &outPtr
        );

        Msg_PushLine(game_BestLevelTimeBuffer, MSG_TAG_OPTIONS|(outPtr - game_BestLevelTimeBuffer));
    }

    Game_ProgressSignal |= (1 << GAME_EVENTBIT_LEVEL_START);
    Game_UpdatePlayerProgress();
}

/**
 * Called when the level is completed sucessfully
 *
 * Capture the end time and calculate the level duration. If the duration is better than any existing one
 * for this level, update it and increment the corresponding improved time counter for the level.
 */
void Game_LevelWon(void)
{
    GetSysTime(&game_LevelEnd);
    SubTime(&game_LevelEnd, &game_LevelBegin);
    ++game_PlayerProgression.gs_LevelWonCounts[Game_LevelNumber];
    ULONG elapsedCentis = (game_LevelEnd.tv_sec * 100) + (game_LevelEnd.tv_usec/10000);
    if (0 == game_PlayerProgression.gs_LevelBestTimes[Game_LevelNumber]) {
        game_PlayerProgression.gs_LevelBestTimes[Game_LevelNumber] = elapsedCentis;
    } else if (elapsedCentis < game_PlayerProgression.gs_LevelBestTimes[Game_LevelNumber]) {
        game_PlayerProgression.gs_LevelBestTimes[Game_LevelNumber] = elapsedCentis;
        ++game_PlayerProgression.gs_LevelImprovedTimeCounts[Game_LevelNumber];
    }
}

/**
 * Called when the level fails. Maybe there's a point to recording how long it took before that happened
 * for a sort of anti-achievement.
 */
void Game_LevelFailed(void)
{
    ++game_PlayerProgression.gs_LevelFailCounts[Game_LevelNumber];
}
