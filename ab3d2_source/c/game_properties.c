#include "system.h"
#include "game_properties.h"
#include <dos/dos.h>
#include <proto/dos.h>

extern Game_ModProperties game_ModProps;

static void game_LoadModProperties(void);

/**
 * Install the game default values. This is basically uncapped ammo, health.
 */
void Game_InitDefaults(void)
{
    game_ModProps.gmp_MaxInventory.ic_Health      = GAME_DEFAULT_HEALTH_LIMIT;
    game_ModProps.gmp_MaxInventory.ic_JetpackFuel = GAME_DEFAULT_FUEL_LIMIT;
    for (int i = 0; i < NUM_BULLET_DEFS; ++i) {
        game_ModProps.gmp_MaxInventory.ic_AmmoCounts[i] = GAME_DEFAULT_AMMO_LIMIT;
    }
    game_LoadModProperties();
}

/**
 * Check if an item can be collected based on the player's Inventory state
 */
BOOL Game_CheckInventoryLimits(
    REG(a0, const Inventory*            inventory),
    REG(a1, const InventoryConsumables* consumables),
    REG(a2, const InventoryItems*       items)
)
{
#ifdef MULTIPLAYER_LEAVE_ITEMS
    extern BYTE  Plr_MultiplayerType_b;
    if (Plr_MultiplayerType_b == GAME_MODE_SINGLE_PLAYER) {
        return TRUE;
        /* In single player, we can just early out if any item is given, even if we won't get ammo. */
        UWORD const *itemPtr = &items->ii_Jetpack;
        for (UWORD n = 0; n < sizeof(InventoryItems)/sizeof(UWORD); ++n) {
            if (itemPtr[n]) {
                return TRUE;
            }
        }
    } else {
        /**
         * In multiplayer, don't collect items you have already, unless your ammo is not saturated.
         */
        UWORD const *itemPtr    = &items->ii_Jetpack;
        UWORD const *invItemPtr = &inventory->inv_Items.ii_Jetpack;
        for (UWORD n = 0; n < sizeof(InventoryItems)/sizeof(UWORD); ++n) {
            if (itemPtr[n] && !invItemPtr[n]) {
                return TRUE;
            }
        }
    }
#else
    UWORD const *itemPtr = &items->ii_Jetpack;
    for (UWORD n = 0; n < sizeof(InventoryItems)/sizeof(UWORD); ++n) {
        if (itemPtr[n]) {
            return TRUE;
        }
    }
#endif
    /** If the item gives us a quantity of something we aren't maxed out on, we can collect it */
    if (
        consumables->ic_Health > 0 &&
        inventory->inv_Consumables.ic_Health < game_ModProps.gmp_MaxInventory.ic_Health
    ) {
        return TRUE;
    }

    /** If the item gives us fuel and we aren't maxed. we can collect */
    if (
        consumables->ic_JetpackFuel > 0 &&
        inventory->inv_Consumables.ic_JetpackFuel < game_ModProps.gmp_MaxInventory.ic_JetpackFuel
    ) {
        return TRUE;
    }

    for (UWORD n = 0; n < NUM_BULLET_DEFS; ++n) {
        if (
            consumables->ic_AmmoCounts[n] > 0 &&
            inventory->inv_Consumables.ic_AmmoCounts[n] < game_ModProps.gmp_MaxInventory.ic_AmmoCounts[n]
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
        game_ModProps.gmp_MaxInventory.ic_Health
    );

    inventory->inv_Consumables.ic_JetpackFuel = addSaturated(
        inventory->inv_Consumables.ic_JetpackFuel,
        consumables->ic_JetpackFuel,
        game_ModProps.gmp_MaxInventory.ic_JetpackFuel
    );

    for (UWORD n = 0; n < NUM_BULLET_DEFS; ++n) {
        inventory->inv_Consumables.ic_AmmoCounts[n] = addSaturated(
            inventory->inv_Consumables.ic_AmmoCounts[n],
            consumables->ic_AmmoCounts[n],
            game_ModProps.gmp_MaxInventory.ic_AmmoCounts[n]
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

    Game_ModProperties* props = (Game_ModProperties*)Sys_GetTemporaryWorkspace();

    LONG bytesRead = Read(modPropsFH, props, sizeof(Game_ModProperties));
    if (bytesRead == (LONG)sizeof(Game_ModProperties)) {
        if (props->gmp_MaxInventory.ic_Health < GAME_UNCAPPED_LIMIT) {
            game_ModProps.gmp_MaxInventory.ic_Health = props->gmp_MaxInventory.ic_Health;
        }
        if (props->gmp_MaxInventory.ic_JetpackFuel < GAME_UNCAPPED_LIMIT) {
            game_ModProps.gmp_MaxInventory.ic_JetpackFuel = props->gmp_MaxInventory.ic_JetpackFuel;
        }

        for (int i = 0; i < NUM_BULLET_DEFS; ++i) {
            if (props->gmp_MaxInventory.ic_AmmoCounts[i] < GAME_UNCAPPED_LIMIT) {
                game_ModProps.gmp_MaxInventory.ic_AmmoCounts[i] = props->gmp_MaxInventory.ic_AmmoCounts[i];
            }
        }
    }
    Close(modPropsFH);
}
