#include <stdio.h>
#include "game_mod.h"
#include "system.h"
#include "devmode.h"
#include <proto/exec.h>
#include <proto/dos.h>
#include <proto/utility.h>

// reset at level start and incremented by the interrupt
volatile ULONG GMod_Ticks  = 0;

// Current ShortDate
ShortDate GMod_Date = 0;

#define EPOCH_YEAR 1978
#define TICK_MASK 0x1FF

/**********************************************************************************************************************/

/**
typedef struct {
    GMod_InventoryLimits    pprg_InventoryLimits;
    GMod_WeaponAdjustment   pprg_WeaponAdjustments[NUM_GUN_DEFS];
    GMod_ProgressCounters   pprg_Counters;

    ShortDate* pprg_Unlocked;

    UBYTE*     pprg_UnlockedMap;
} GMod_PlayerProgression;

extern GMod_PlayerProgression GMod_Progress; // In BSS

*/

/**
 * Achievement test total quantity of something collected
 *
 * params {
 *     ULONG totalCount;
 *     UWORD consumable; // 0 == health, 1 == fuel, 2... = ammo class 0 ....
 * }
 *
 */
static BOOL game_AchievementRuleStuffCollected(Achievement const* achievement)
{
    ULONG totalCount = *(ULONG const*)&(achievement->ac_RuleParams[0]);
    UWORD consumable = *(UWORD const*)&(achievement->ac_RuleParams[sizeof(ULONG)]);
    ULONG *consumables = &GMod_Progress.pprg_Counters.prgc_TotalHealthCollected;
    return consumables[consumable] >= totalCount;
}

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
