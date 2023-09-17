#include "system.h"
#include "game_properties.h"
#include <dos/dos.h>
#include <proto/dos.h>

extern Game_ModProperties game_ModProps;

static void game_LoadModProperties(void);

void Game_InitDefaults(void)
{
    game_ModProps.gmp_MaxInventoryConsumables.ic_Health      = GAME_DEFAULT_HEALTH_LIMIT;
    game_ModProps.gmp_MaxInventoryConsumables.ic_JetpackFuel = GAME_DEFAULT_FUEL_LIMIT;
    for (int i = 0; i < NUM_BULLET_DEFS; ++i) {
        game_ModProps.gmp_MaxInventoryConsumables.ic_AmmoCounts[i] = GAME_DEFAULT_AMMO_LIMIT;
    }
    game_LoadModProperties();
}

/**
 * Check if an item can be collected based on the player's Inventory state
 */
BOOL Game_CheckCanCollect(
    REG(a0, const Inventory*            inventory),
    REG(a1, const InventoryConsumables* consumables),
    REG(a2, const InventoryItems*       items)
)
{
    /** If the item gives us an item we don't have, we can collect it */
    if (items->ii_Jetpack && !inventory->inv_Items.ii_Jetpack) {
        return TRUE;
    }

    if (items->ii_Shield && !inventory->inv_Items.ii_Shield) {
        return TRUE;
    }

    for (UWORD n = 0; n < NUM_GUN_DEFS; ++n) {
        if (items->ii_Weapons[n] && !inventory->inv_Items.ii_Weapons[n]) {
            return TRUE;
        }
    }

    /** If the item gives us a quantity of something we aren't maxed out on, we can collect it */
    if (
        consumables->ic_Health > 0 &&
        inventory->inv_Consumables.ic_Health < game_ModProps.gmp_MaxInventoryConsumables.ic_Health
    ) {
        return TRUE;
    }

    /** If the item gives us fuel and we aren't maxed. we can collect */
    if (
        consumables->ic_JetpackFuel > 0 &&
        inventory->inv_Consumables.ic_JetpackFuel < game_ModProps.gmp_MaxInventoryConsumables.ic_JetpackFuel
    ) {
        return TRUE;
    }

    for (UWORD n = 0; n < NUM_BULLET_DEFS; ++n) {
        if (
            consumables->ic_AmmoCounts[n] > 0 &&
            inventory->inv_Consumables.ic_AmmoCounts[n] < game_ModProps.gmp_MaxInventoryConsumables.ic_AmmoCounts[n]
        ) {
            return TRUE;
        }
    }
    return FALSE;
}

/**
 * Simple helper function to perform a saturated add up to a given limit. If the sum overflows or is above the limit
 * the limit is returned, otherwise the sum.
 */
static inline UWORD addSaturated(UWORD a, UWORD b, UWORD limit)
{
    UWORD sum = a + b;
    return (sum < a || sum < b || sum > limit) ? limit : sum;
}

/**
 * Add to the player Inventory, respecting the limits set in Game_ModProperties.gmp_MaxCollectableCounts
 */
void Game_AddToInventory(
    REG(a0, Inventory*                  inventory),
    REG(a1, const InventoryConsumables* consumables),
    REG(a2, const InventoryItems*       items)
) {
    /** Add all of the items to the player inventory */
    inventory->inv_Items.ii_Jetpack |= items->ii_Jetpack;
    inventory->inv_Items.ii_Shield  |= items->ii_Shield;
    for (UWORD n = 0; n < NUM_GUN_DEFS; ++n) {
        inventory->inv_Items.ii_Weapons[n] |= items->ii_Weapons[n];
    }

    inventory->inv_Consumables.ic_Health = addSaturated(
        inventory->inv_Consumables.ic_Health,
        consumables->ic_Health,
        game_ModProps.gmp_MaxInventoryConsumables.ic_Health
    );

    inventory->inv_Consumables.ic_JetpackFuel = addSaturated(
        inventory->inv_Consumables.ic_JetpackFuel,
        consumables->ic_JetpackFuel,
        game_ModProps.gmp_MaxInventoryConsumables.ic_JetpackFuel
    );

    for (UWORD n = 0; n < NUM_BULLET_DEFS; ++n) {
        inventory->inv_Consumables.ic_AmmoCounts[n] = addSaturated(
            inventory->inv_Consumables.ic_AmmoCounts[n],
            consumables->ic_AmmoCounts[n],
            game_ModProps.gmp_MaxInventoryConsumables.ic_AmmoCounts[n]
        );
    }
}

void game_LoadModProperties()
{
    BPTR modPropsFH = Open(GAME_PROPERTIES_DATA_PATH, MODE_OLDFILE);
    if (DOSFALSE == modPropsFH) {
        return;
    }
    struct FileInfoBlock* modPropsFIB = (struct FileInfoBlock*)Sys_GetTemporaryWorkspace();
    ExamineFH(modPropsFH, modPropsFIB);

    if (
        modPropsFIB->fib_DirEntryType >= 0 ||
        modPropsFIB->fib_Size < (LONG)sizeof(Game_ModProperties)
    ) {
        return;
    }

    Game_ModProperties* tp = (Game_ModProperties*)Sys_GetTemporaryWorkspace();

    LONG bytesRead = Read(modPropsFH, tp, sizeof(Game_ModProperties));
    if (bytesRead == (LONG)sizeof(Game_ModProperties)) {
        if (tp->gmp_MaxInventoryConsumables.ic_Health < GAME_UNCAPPED_LIMIT) {
            game_ModProps.gmp_MaxInventoryConsumables.ic_Health = tp->gmp_MaxInventoryConsumables.ic_Health;
        }
        if (tp->gmp_MaxInventoryConsumables.ic_JetpackFuel < GAME_UNCAPPED_LIMIT) {
            game_ModProps.gmp_MaxInventoryConsumables.ic_JetpackFuel = tp->gmp_MaxInventoryConsumables.ic_JetpackFuel;
        }

        for (int i = 0; i < NUM_BULLET_DEFS; ++i) {
            if (tp->gmp_MaxInventoryConsumables.ic_AmmoCounts[i] < GAME_UNCAPPED_LIMIT) {
                game_ModProps.gmp_MaxInventoryConsumables.ic_AmmoCounts[i] = tp->gmp_MaxInventoryConsumables.ic_AmmoCounts[i];
            }
        }
    }
    Close(modPropsFH);
}
