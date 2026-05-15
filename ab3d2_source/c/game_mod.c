#include <stdio.h>
#include "game.h"
#include "game_mod.h"
#include "system.h"
#include "message.h"
#include "devmode.h"
#include <proto/exec.h>
#include <proto/dos.h>
#include <proto/utility.h>
#include <devices/timer.h>
#include <proto/timer.h>

extern ULONG Game_ProgressSignal; // signal to check progress
extern UWORD Game_LevelNumber;
extern UWORD Plr1_Zone;

extern char  game_BestLevelTimeBuffer[];

static struct timeval game_LevelBegin = { {0}, {0} };
static struct timeval game_LevelEnd   = { {0}, {0} };

// reset at level start and incremented by the interrupt
volatile ULONG GMod_Ticks  = 0;

// Current ShortDate
ShortDate GMod_Date = 0;

#define EPOCH_YEAR 1978
#define TICK_MASK 0x1FF

extern Inventory Plr1_Inventory;
extern Inventory Plr2_Inventory;

/**********************************************************************************************************************/

/**
 * Calculates the current date as a ShortDate (11:5 months_since_epoch:calendar_day_of_month) for achievements recording.
 */
void GMod_CalculateDate(void)
{
    if (0 == GMod_Date || 0 == (GMod_Ticks & TICK_MASK)) {
        static struct DateStamp oDateStamp = { 0 };
        static struct ClockData oClockData = { 0 };
        DateStamp(&oDateStamp);

        // Since the ShortDate only has day granularity we can just use coarse seconds time here.
        Amiga2Date(oDateStamp.ds_Days * 86400, &oClockData);
        UWORD months = ((oClockData.year - EPOCH_YEAR) * 12) + oClockData.month - 1;
        GMod_Date = months << 5 | (oClockData.mday & 0x1F);
    }
}

/**********************************************************************************************************************/

/**
 * Reward helper function. Returns the address of the carry modification, if a carry modification is defined.
 */
static UWORD const* gmod_GetRewardCarry(GMod_Reward const* pReward)
{
    if (pReward->rwrd_CarryOffset >= sizeof(GMF_ChunkHeader)) {
        return (UWORD const*) (
            ((UBYTE const*)pReward) + pReward->rwrd_CarryOffset
        );
    }
    return NULL;
}

/**
 * Reward helper function. Returns the address of the immediate modification, if an immediate modification is defined.
 */
static UWORD const* gmod_GetRewardImmediate(GMod_Reward const* pReward)
{
    if (pReward->rwrd_ImmediateOffset >= sizeof(GMF_ChunkHeader)) {
        return (UWORD const*) (
            ((UBYTE const*)pReward) + pReward->rwrd_ImmediateOffset
        );
    }
    return NULL;
}

/**
 * Reward helper function. Performs a saturated addition.
 */
static inline UWORD gmod_addSaturated(UWORD a, UWORD b, UWORD limit)
{
    UWORD sum = a + b;
    return (sum < a || sum < b || sum > limit) ? limit : sum;
}

/**********************************************************************************************************************/

void GMod_ApplyReward(
    GMod_Reward const* pReward,
    GMod_InventoryLimits* pInventoryLimits,
    InventoryConsumables* pInventoryConsumables
) {
    /**
     * First apply any carry limit updates
     */
    UWORD const* pRewardData = gmod_GetRewardCarry(pReward);
    if (pRewardData) {
        pInventoryLimits->ic_Health += *pRewardData++;
        pInventoryLimits->ic_JetpackFuel += *pRewardData++;

        /**
         * Add ammo
         */
        while (*pRewardData != 0xFFFF) {
            UWORD slot = *pRewardData++;
            pInventoryLimits->ic_AmmoCounts[slot] += *pRewardData++;
        }
    }

    /**
     * Then apply any immediate updates, not exceeding the carry limits
     */
    pRewardData = gmod_GetRewardImmediate(pReward);
    if (pRewardData) {
        pInventoryConsumables->ic_Health = gmod_addSaturated(
            pInventoryConsumables->ic_Health,
            *pRewardData++,
            pInventoryLimits->ic_Health
        );
        pInventoryConsumables->ic_JetpackFuel = gmod_addSaturated(
            pInventoryConsumables->ic_JetpackFuel,
            *pRewardData++,
            pInventoryLimits->ic_JetpackFuel
        );

        /**
         * Add ammo
         */
        while (*pRewardData != 0xFFFF) {
            UWORD slot = *pRewardData++;
            pInventoryConsumables->ic_AmmoCounts[slot] = gmod_addSaturated(
                pInventoryConsumables->ic_AmmoCounts[slot],
                *pRewardData++,
                pInventoryLimits->ic_AmmoCounts[slot]
            );
        }
    }
    if (pReward->rwrd_Description) {
        Msg_PushLine(pReward->rwrd_Description, MSG_TAG_OPTIONS|80);
    }
}

/**********************************************************************************************************************/

/**
 * Set the engine defaults for GMod_Progress
 */
static void gmod_SetEngineDefaults()
{
    // Set the initial inventory limits to the engine defaults
    GMod_Progress.pprg_InventoryLimits.ic_Health      = INVENTORY_DEFAULT_HEALTH_LIMIT;
    GMod_Progress.pprg_InventoryLimits.ic_JetpackFuel = INVENTORY_DEFAULT_FUEL_LIMIT;
    for (WORD i = 0; i < NUM_BULLET_DEFS; ++i) {
        GMod_Progress.pprg_InventoryLimits.ic_AmmoCounts[i] = INVENTORY_DEFAULT_AMMO_LIMIT;
    }

    dputs("Set engine default inventory limits");
}

void GMod_Init()
{
    // Game defaults must be set, no matter what.
    gmod_SetEngineDefaults();

    // If the module defaults can't be loaded, player progress isn't usable.
    if (FALSE == GMod_LoadModDefaults()) {
        return;
    }

    GMod_LoadPlayerProgress();
}

void GMod_Done()
{
    if (GMod_Defaults.gmod_Loaded) {
        GMF_Free(GMod_Defaults.gmod_Loaded);
    }
    if (GMod_Progress.pprg_Unlocked) {
        FreeVec(GMod_Progress.pprg_Unlocked);
    }
}

/**********************************************************************************************************************/

/**
 * Returns true if the achievement withe the given ID has alreadty been awarded.
 */
static inline BOOL gmod_CheckAchieved(UWORD id)
{
    return GMod_Progress.pprg_UnlockedMap[(id >> 3)] & (1 << (id & 7));
}

static void gmod_MarkAchieved(UWORD id)
{
    UWORD byte = id >> 3;
    UBYTE bit  = (1 << (id & 7));
    if (!(GMod_Progress.pprg_UnlockedMap[byte] & bit)) {
        GMod_Progress.pprg_UnlockedMap[byte] |= bit;
        GMod_Progress.pprg_Unlocked[id] = GMod_Date;
    }
}

static BOOL gmod_TestRuleKillCount(GMod_Achievement const* pAchievement)
{
    UWORD uAlienTypeId = pAchievement->achv_Param.oKillCount.uAlienType;

#ifdef PARANOID
    if (uAlienTypeId >= NUM_ALIEN_DEFS) {
        return FALSE;
    }
#endif

    return GMod_Progress.pprg_Counters.prgc_AlienKills[uAlienTypeId] >= pAchievement->achv_Param.oKillCount.uCount;
}

static BOOL gmod_TestRuleGroupKillCount(GMod_Achievement const* pAchievement)
{
    ULONG uEnemyMask = pAchievement->achv_Param.oGroupKillCount.uAlienMask;
    ULONG uCount     = pAchievement->achv_Param.oGroupKillCount.uCount;
    ULONG uTotal     = 0;
    for (UWORD uAlienTypeId = 0; uAlienTypeId < NUM_ALIEN_DEFS; ++uAlienTypeId) {
        if (uEnemyMask & (1 << uAlienTypeId)) {
            uTotal += GMod_Progress.pprg_Counters.prgc_AlienKills[uAlienTypeId];
        }
        if (uTotal >= uCount) {
            return TRUE;
        }
    }
    return FALSE;
}

static BOOL gmod_TestRuleZoneFound(GMod_Achievement const* pAchievement)
{
    return Game_LevelNumber == pAchievement->achv_Param.oZoneFound.uLevel
        && Plr1_Zone == pAchievement->achv_Param.oZoneFound.uZoneID;
}

static BOOL gmod_TestRuleLevelTimeImproved(GMod_Achievement const* pAchievement)
{
    ULONG uCountLimit = pAchievement->achv_Param.oMaskedLevelCount.uCount;
    UWORD uLevelMask  = pAchievement->achv_Param.oMaskedLevelCount.uLevelMask;

    if (pAchievement->achv_Param.oMaskedLevelCount.bOverall) {
        // The combined times improved count across all inclued levels
        ULONG uCount = 0;
        for (UWORD uLevelNum = 0; uLevelNum < NUM_LEVELS; ++uLevelNum) {
            if (uLevelMask & (1 << uLevelNum)) {
                uCount += GMod_Progress.pprg_Counters.prgc_LevelImprovedTimeCounts[uLevelNum];
                if (uCount >= uCountLimit) {
                    return TRUE;
                }
            }
        }
    } else {
        // The times improved for any of the included levels
        for (UWORD uLevelNum = 0; uLevelNum < NUM_LEVELS; ++uLevelNum) {
            if (uLevelMask & (1 << uLevelNum)) {
                if (GMod_Progress.pprg_Counters.prgc_LevelImprovedTimeCounts[uLevelNum] >= uCountLimit) {
                    return TRUE;
                }
            }
        }
    }
    return FALSE;
}

static BOOL gmod_TestRulePlayerDied(GMod_Achievement const* pAchievement)
{
    ULONG uCountLimit = pAchievement->achv_Param.oMaskedLevelCount.uCount;
    UWORD uLevelMask  = pAchievement->achv_Param.oMaskedLevelCount.uLevelMask;

    if (pAchievement->achv_Param.oMaskedLevelCount.bOverall) {
        // The combined number of times the player died across all inclued levels
        ULONG uCount = 0;
        for (UWORD uLevelNum = 0; uLevelNum < NUM_LEVELS; ++uLevelNum) {
            if (uLevelMask & (1 << uLevelNum)) {
                uCount += GMod_Progress.pprg_Counters.prgc_LevelFailCounts[uLevelNum];
                if (uCount >= uCountLimit) {
                    return TRUE;
                }
            }
        }
    } else {
        // The number of times the player died for any of the included levels
        for (UWORD uLevelNum = 0; uLevelNum < NUM_LEVELS; ++uLevelNum) {
            if (uLevelMask & (1 << uLevelNum)) {
                if (GMod_Progress.pprg_Counters.prgc_LevelFailCounts[uLevelNum] >= uCountLimit) {
                    return TRUE;
                }
            }
        }
    }
    return FALSE;
}

static BOOL gmod_TestRuleStuffCollected(GMod_Achievement const* pAchievement)
{
    ULONG const* pConsumables = &GMod_Progress.pprg_Counters.prgc_TotalHealthCollected;
    UWORD consumableId = pAchievement->achv_Param.oCollected.uConsumable;

#ifdef PARANOID
    if (consumableId >= INVENTORY_SLOTS) {
        return FALSE;
    }
#endif

    return pConsumables[consumableId] >= pAchievement->achv_Param.oCollected.uCount;
}

typedef BOOL (*TestRuleFunction)(GMod_Achievement const*);

static TestRuleFunction gmod_TestRules[] = {
    gmod_TestRuleKillCount,
    gmod_TestRuleGroupKillCount,
    gmod_TestRuleZoneFound,
    gmod_TestRuleLevelTimeImproved,
    gmod_TestRulePlayerDied,
    gmod_TestRuleStuffCollected,
};

/**
 * Called each frame wheb Game_ProgressSignal is non-zero.
 */
void GMod_UpdateProgress(void)
{
    GMod_Achievement const* pAchievement = GMod_Defaults.gmod_DefinedAchievements;
    UWORD uNumAchievements = (UWORD)GMod_Defaults.gmod_NumDefinedAchievements;
    for (UWORD id = 0; id < uNumAchievements; ++id, ++pAchievement) {
        /** Early out on any achiecvements where the rule mask doesn't intersect with the event signal */
        if (
            !(Game_ProgressSignal & pAchievement->achv_EventMask) ||
            gmod_CheckAchieved(id)
        ) {
            continue;
        }

        if (gmod_TestRules[pAchievement->achv_RuleType](pAchievement)) {
            Msg_PushLine(pAchievement->achv_Description, MSG_TAG_OPTIONS|80);
            if (pAchievement->achv_Reward) {
                GMod_ApplyReward(
                    pAchievement->achv_Reward,
                    &GMod_Progress.pprg_InventoryLimits,
                    &Plr1_Inventory.inv_Consumables
                );
            }
            gmod_MarkAchieved(id);
        }
    }
    Game_ProgressSignal = 0;
}

/**********************************************************************************************************************/

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
void GMod_LevelBegin(void)
{
    GetSysTime(&game_LevelBegin);
    ++GMod_Progress.pprg_Counters.prgc_LevelPlayCounts[Game_LevelNumber];

    if (GMod_Progress.pprg_Counters.prgc_LevelBestTimes[Game_LevelNumber]) {
        ULONG time = GMod_Progress.pprg_Counters.prgc_LevelBestTimes[Game_LevelNumber];

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
    GMod_UpdateProgress();
}

/**
 * Called when the level is completed sucessfully
 *
 * Capture the end time and calculate the level duration. If the duration is better than any existing one
 * for this level, update it and increment the corresponding improved time counter for the level.
 */
void GMod_LevelWon(void)
{
    GetSysTime(&game_LevelEnd);
    SubTime(&game_LevelEnd, &game_LevelBegin);
    ++GMod_Progress.pprg_Counters.prgc_LevelWonCounts[Game_LevelNumber];
    ULONG elapsedCentis = (game_LevelEnd.tv_sec * 100) + (game_LevelEnd.tv_usec/10000);
    if (0 == GMod_Progress.pprg_Counters.prgc_LevelBestTimes[Game_LevelNumber]) {
        GMod_Progress.pprg_Counters.prgc_LevelBestTimes[Game_LevelNumber] = elapsedCentis;
    } else if (elapsedCentis < GMod_Progress.pprg_Counters.prgc_LevelBestTimes[Game_LevelNumber]) {
        GMod_Progress.pprg_Counters.prgc_LevelBestTimes[Game_LevelNumber] = elapsedCentis;
        ++GMod_Progress.pprg_Counters.prgc_LevelImprovedTimeCounts[Game_LevelNumber];
    }
}


/**
 * Called when the level fails. Maybe there's a point to recording how long it took before that happened
 * for a sort of anti-achievement.
 */
void GMod_LevelFailed(void)
{
    ++GMod_Progress.pprg_Counters.prgc_LevelFailCounts[Game_LevelNumber];
}
