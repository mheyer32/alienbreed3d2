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

// If the current short date evaluates to 0, we have a problem with the RTC.
// So instead we substitute 0x42A1 which represents 2022-06-01, the date the recompilable build was announced.
#define GAME_EPOCH_SHORTDATE 0x42A1

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
        if (!GMod_Date) {
            GMod_Date = GAME_EPOCH_SHORTDATE;
        }
    }
}

/**********************************************************************************************************************/

/**
 * Reward helper function. Returns the address of the carry modification, if a carry modification is defined.
 */
static UWORD const* gmod_GetRewardCarry(GMod_Reward const* rewardPtr)
{
    if (rewardPtr->rwrd_CarryOffset >= sizeof(GMF_ChunkHeader)) {
        return (UWORD const*) (
            ((UBYTE const*)rewardPtr) + rewardPtr->rwrd_CarryOffset
        );
    }
    return NULL;
}

/**
 * Reward helper function. Returns the address of the immediate modification, if an immediate modification is defined.
 */
static UWORD const* gmod_GetRewardImmediate(GMod_Reward const* rewardPtr)
{
    if (rewardPtr->rwrd_ImmediateOffset >= sizeof(GMF_ChunkHeader)) {
        return (UWORD const*) (
            ((UBYTE const*)rewardPtr) + rewardPtr->rwrd_ImmediateOffset
        );
    }
    return NULL;
}

/**
 * Reward helper function. Performs a saturated addition.
 */
static inline UWORD gmod_AddSaturated(UWORD a, UWORD b, UWORD limit)
{
    UWORD sum = a + b;
    return (sum < a || sum < b || sum > limit) ? limit : sum;
}

/**********************************************************************************************************************/

void GMod_ApplyReward(
    GMod_Reward const* rewardPtr,
    GMod_InventoryLimits* inventoryLimitsPtr,
    InventoryConsumables* inventoryConsumablesPtr
) {
    /**
     * First apply any carry limit updates
     */
    UWORD const* pRewardData = gmod_GetRewardCarry(rewardPtr);
    if (pRewardData) {
        inventoryLimitsPtr->ic_Health += *pRewardData++;
        inventoryLimitsPtr->ic_JetpackFuel += *pRewardData++;

        /**
         * Add ammo
         */
        while (*pRewardData != 0xFFFF) {
            UWORD slot = *pRewardData++;
            inventoryLimitsPtr->ic_AmmoCounts[slot] += *pRewardData++;
        }
    }

    /**
     * Then apply any immediate updates, not exceeding the carry limits
     */
    pRewardData = gmod_GetRewardImmediate(rewardPtr);
    if (pRewardData) {
        inventoryConsumablesPtr->ic_Health = gmod_AddSaturated(
            inventoryConsumablesPtr->ic_Health,
            *pRewardData++,
            inventoryLimitsPtr->ic_Health
        );
        inventoryConsumablesPtr->ic_JetpackFuel = gmod_AddSaturated(
            inventoryConsumablesPtr->ic_JetpackFuel,
            *pRewardData++,
            inventoryLimitsPtr->ic_JetpackFuel
        );

        /**
         * Add ammo
         */
        while (*pRewardData != 0xFFFF) {
            UWORD slot = *pRewardData++;
            inventoryConsumablesPtr->ic_AmmoCounts[slot] = gmod_AddSaturated(
                inventoryConsumablesPtr->ic_AmmoCounts[slot],
                *pRewardData++,
                inventoryLimitsPtr->ic_AmmoCounts[slot]
            );
        }
    }
    if (rewardPtr->rwrd_DescriptionPtr) {
        Msg_PushLine(rewardPtr->rwrd_DescriptionPtr, MSG_TAG_OPTIONS|80);
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

    // A slot ID of 0xFFFF means there is no defined adjustment.
    for (WORD i = 0; i < NUM_GUN_DEFS; ++i) {
        GMod_Progress.pprg_WeaponAdjustments[i].wadj_SlotID = 0xFFFF;
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
    GMod_SavePlayerProgress();

    if (GMod_Defaults.gmod_LoadedPtr) {
        GMF_Free(GMod_Defaults.gmod_LoadedPtr);
    }
    if (GMod_Progress.pprg_UnlockedPtr) {
        FreeVec(GMod_Progress.pprg_UnlockedPtr);
    }
}

/**********************************************************************************************************************/

/**
 * Returns true if the achievement withe the given ID has alreadty been awarded.
 */
static inline BOOL gmod_CheckAchieved(UWORD id)
{
    return GMod_Progress.pprg_UnlockedMapPtr[(id >> 3)] & (1 << (id & 7));
}

static void gmod_MarkAchieved(UWORD id)
{
    UWORD byte = id >> 3;
    UBYTE bit  = (1 << (id & 7));
    if (!(GMod_Progress.pprg_UnlockedMapPtr[byte] & bit)) {
        GMod_Progress.pprg_UnlockedMapPtr[byte] |= bit;
        GMod_Progress.pprg_UnlockedPtr[id] = GMod_Date;
    }
/*
    int iDay    = GMod_Date & 0x1F;
    int iMonths = GMod_Date >> 5;
    int iMonth  = (iMonths % 12) + 1;
    int iYear   = (iMonths / 12) + 1978;

    dprintf("Achieved %d on 0x%04X [%d-%d-%d]\n", (int)id, (unsigned)GMod_Date, iYear, iMonth, iDay);
*/
}

static BOOL gmod_TestRuleKillCount(GMod_Achievement const* restrict achievementPtr)
{
    UWORD uAlienTypeId = achievementPtr->achv_Param.oKillCount.uAlienType;

#ifdef PARANOID
    if (uAlienTypeId >= NUM_ALIEN_DEFS) {
        return FALSE;
    }
#endif

    return GMod_Progress.pprg_Counters.prgc_AlienKills[uAlienTypeId] >= achievementPtr->achv_Param.oKillCount.uCount;
}

static BOOL gmod_TestRuleGroupKillCount(GMod_Achievement const* restrict achievementPtr)
{
    ULONG const uEnemyMask = achievementPtr->achv_Param.oGroupKillCount.uAlienMask;
    ULONG const uCount     = achievementPtr->achv_Param.oGroupKillCount.uCount;
    ULONG uTotal = 0;
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

static BOOL gmod_TestRuleZoneFound(GMod_Achievement const* restrict achievementPtr)
{
    return Game_LevelNumber == achievementPtr->achv_Param.oZoneFound.uLevel
        && Plr1_Zone == achievementPtr->achv_Param.oZoneFound.uZoneID;
}

static BOOL gmod_TestRuleLevelTimeImproved(GMod_Achievement const* restrict achievementPtr)
{
    ULONG const uCountLimit = achievementPtr->achv_Param.oMaskedLevelCount.uCount;
    UWORD const uLevelMask  = achievementPtr->achv_Param.oMaskedLevelCount.uLevelMask;

    if (achievementPtr->achv_Param.oMaskedLevelCount.bOverall) {
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

static BOOL gmod_TestRulePlayerDied(GMod_Achievement const* restrict achievementPtr)
{
    ULONG const uCountLimit = achievementPtr->achv_Param.oMaskedLevelCount.uCount;
    UWORD const uLevelMask  = achievementPtr->achv_Param.oMaskedLevelCount.uLevelMask;

    if (achievementPtr->achv_Param.oMaskedLevelCount.bOverall) {
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

static BOOL gmod_TestRuleStuffCollected(GMod_Achievement const* restrict achievementPtr)
{
    ULONG const* pConsumables = &GMod_Progress.pprg_Counters.prgc_TotalHealthCollected;
    UWORD consumableId = achievementPtr->achv_Param.oCollected.uConsumable;

#ifdef PARANOID
    if (consumableId >= INVENTORY_SLOTS) {
        return FALSE;
    }
#endif

    return pConsumables[consumableId] >= achievementPtr->achv_Param.oCollected.uCount;
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
 * Called each frame when Game_ProgressSignal is non-zero.
 */
void GMod_UpdateProgress(void)
{
    //extern LONG Sys_FrameNumber_l;
    //dprintf("Frame %d Progress Signal 0x%08X\n", Sys_FrameNumber_l, Game_ProgressSignal);
    GMod_Achievement const* achievementPtr = GMod_Defaults.gmod_DefinedAchievementsPtr;
    UWORD uNumAchievements = (UWORD)GMod_Defaults.gmod_NumDefinedAchievements;
    for (UWORD id = 0; id < uNumAchievements; ++id, ++achievementPtr) {
        /** Early out on any achievements where the rule mask doesn't intersect with the event signal */
        if (
            !(Game_ProgressSignal & achievementPtr->achv_EventMask) ||
            gmod_CheckAchieved(id)
        ) {
            continue;
        }

        if (gmod_TestRules[achievementPtr->achv_RuleType](achievementPtr)) {
            Msg_PushLine(achievementPtr->achv_DescriptionPtr, MSG_TAG_OPTIONS|80);
            if (achievementPtr->achv_RewardPtr) {
                GMod_ApplyReward(
                    achievementPtr->achv_RewardPtr,
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
    extern UBYTE Zone_Visited_vb[];
    Sys_MemFillLong(Zone_Visited_vb, 0, LVL_MAX_ZONE_COUNT/sizeof(ULONG));

    GetSysTime(&game_LevelBegin);
    ++GMod_Progress.pprg_Counters.prgc_LevelPlayCounts[Game_LevelNumber];

    // Report best level time, if there is one.
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

    // Initialise the progress data.
    GMod_CalculateDate();
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

/**
 * Called from assembler.
 *
 * Check if an item can be collected based on the player's Inventory state. This is a bit more complicated since
 * items which give absolutely nothing are considered collectable too, e.g. the message markers.
 */
BOOL GMod_RawCheckInventoryLimits(
    REG(a0, const UWORD* restrict pInventoryTarget),
    REG(a1, const UWORD* restrict pSourceConsumables),
    REG(a2, const UWORD* restrict pSourceItems)
)
{
    // Test consumables first. Most items give one or more consumables.
    UWORD const * restrict pLimit = &GMod_Progress.pprg_InventoryLimits.ic_Health;
    UWORD uGivesAnything = 0;
    for (UWORD n = 0; n < sizeof(InventoryConsumables)/sizeof(UWORD); ++n) {
        UWORD uSource = *pSourceConsumables++;
        uGivesAnything += uSource;
        if (uSource > 0 && *pInventoryTarget < pLimit[n]) {
            return TRUE;
        }
        ++pInventoryTarget;
    }

    // Now check the items. By now, pInventoryTarget must point at the .inv_Items section of the Inventory.
    // The current ii_Shield property isn't used and is the zeroth index, so just skip over it.
    ++pInventoryTarget;
    ++pSourceItems;

    extern BYTE  Plr_MultiplayerType_b;
    if (Plr_MultiplayerType_b == GAME_MODE_SINGLE_PLAYER) {
        /**
         * In single player, we can just early out if any item is given, even if we won't get ammo.
         */
        for (UWORD n = 0; n < (sizeof(InventoryItems)/sizeof(UWORD) - 1); ++n) {
            if (*pSourceItems++) {
                return TRUE;
            }
        }
    } else {
        /**
         * In multiplayer, don't collect items you have already, unless your ammo is not saturated.
         */
        for (UWORD n = 0; n < (sizeof(InventoryItems)/sizeof(UWORD) - 1); ++n) {
            UWORD uSource = *pSourceItems++;
            uGivesAnything |= uSource;
            UWORD pTarget = *pInventoryTarget++;
            if (uSource && !pTarget) {
                return TRUE;
            }
        }
    }

    /**
     * If we arrive here, nothing was awarded. Totally empty items are removed by collection, triggering other
     * behaviours instead.
     */

    return 0 == uGivesAnything;
}


/**
 * Called from assembler.
 *
 * Add to the player Inventory, respecting the limits set by the modification in GMod_Progress.
 *
 * A0/A1 are volatile
 *
 */
void GMod_RawAddToInventory(
    REG(a0, UWORD* restrict pInventoryTarget),         /* Invetory* */
    REG(a1, const UWORD* restrict pSourceConsumables), /* InventoryConsumables const* */
    REG(a2, const UWORD* restrict pSourceItems)        /* InventoryItems const* */
)
{
    ULONG* restrict pTotalCollected = &GMod_Progress.pprg_Counters.prgc_TotalHealthCollected;
    UWORD const* restrict pLimit    = &GMod_Progress.pprg_InventoryLimits.ic_Health;

    /* First Add all the consumables */
    for (UWORD n = 0; n < sizeof(InventoryConsumables)/sizeof(UWORD); ++n) {
        /**
         * For achievements, we need to track the amount actually collected, which might be less than the object
         * normally carries,
         */
        UWORD prevInv = *pInventoryTarget;
        *pInventoryTarget = gmod_AddSaturated(
            prevInv,
            pSourceConsumables[n],
            pLimit[n]
        );
        /**
         * Add the actual amount given to the collected total for progression.
         * These are intentionally defined in the same order but are ULONG sized.
         */
        pTotalCollected[n] += (*pInventoryTarget++ - prevInv);
    }

    /* Add all the items */
    for (UWORD n = 0; n < sizeof(InventoryItems)/sizeof(UWORD); ++n) {
        *pInventoryTarget++ |= pSourceItems[n];
    }

    Game_ProgressSignal |= (1 << GAME_EVENTBIT_ADD_INVENTORY);
}

/**
 * Called from assembler.
 *
 * Cap the inventory to the currently defined limits
 *
 */
void GMod_RawApplyInventoryLimits(REG(a0, UWORD* pInventoryTarget))
{
    UWORD const * restrict pLimit = &GMod_Progress.pprg_InventoryLimits.ic_Health;
    for (UWORD n = 0; n < sizeof(InventoryConsumables)/sizeof(UWORD); ++n) {
        if (pInventoryTarget[n] > pLimit[n]) {
            pInventoryTarget[n] = pLimit[n];
        }
    }
}
