#include <stdio.h>
#include "game_mod.h"
#include "devmode.h"
#include <proto/exec.h>
#include "system.h"



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
