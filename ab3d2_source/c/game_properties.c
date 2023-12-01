#include "system.h"
#include "game_properties.h"
#include <dos/dos.h>
#include <proto/dos.h>

extern Game_ModProperties game_ModProps;

extern struct FileInfoBlock io_FileInfoBlock;

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
    UWORD const *plrInvPtr = &inventory->inv_Items.ii_Jetpack;
    UWORD const *objInvPtr = &items->ii_Jetpack;
	UWORD givesAnything = 0;
    extern BYTE  Plr_MultiplayerType_b;
    if (Plr_MultiplayerType_b == GAME_MODE_SINGLE_PLAYER) {
        /**
         * In single player, we can just early out if any item is given, even if we won't get ammo.
         */
        for (UWORD n = 0; n < sizeof(InventoryItems)/sizeof(UWORD); ++n) {
            givesAnything |= objInvPtr[n];
            if (objInvPtr[n]) {
                return TRUE;
            }
        }
    } else {
        /**
         * In multiplayer, don't collect items you have already, unless your ammo is not saturated.
         */
        for (UWORD n = 0; n < sizeof(InventoryItems)/sizeof(UWORD); ++n) {
            givesAnything |= objInvPtr[n];
            if (objInvPtr[n] && !plrInvPtr[n]) {
                return TRUE;
            }
        }
    }

    /** If the item gives us a quantity of something we aren't maxed out on, we can collect it */
    plrInvPtr = &inventory->inv_Consumables.ic_Health;
    objInvPtr = &consumables->ic_Health;
    UWORD const *limPtr = &game_ModProps.gmp_MaxInventory.ic_Health;
    for (UWORD n = 0; n < sizeof(InventoryConsumables)/sizeof(UWORD); ++n) {
        givesAnything += objInvPtr[n];
        if (objInvPtr[n] > 0 && plrInvPtr[n] < limPtr[n]) {
            return TRUE;
        }
    }
    return givesAnything ? FALSE : TRUE;
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
    UWORD       *plrInvPtr = &inventory->inv_Items.ii_Jetpack;
    UWORD const *objInvPtr = &items->ii_Jetpack;

    /* Add all the items */
    for (UWORD n = 0; n < sizeof(InventoryItems)/sizeof(UWORD); ++n) {
        plrInvPtr[n] |= objInvPtr[n];
    }

    plrInvPtr = &inventory->inv_Consumables.ic_Health;
    objInvPtr = &consumables->ic_Health;

    UWORD const* limInvPtr = &game_ModProps.gmp_MaxInventory.ic_Health;

    /* Add all the consumables */
    for (UWORD n = 0; n < sizeof(InventoryConsumables)/sizeof(UWORD); ++n) {
        plrInvPtr[n] = addSaturated(
            plrInvPtr[n],
            objInvPtr[n],
            limInvPtr[n]
        );
    }
}

void Game_ApplyInventoryLimits(REG(a0, Inventory* inventory))
{
    UWORD const *limPtr = &game_ModProps.gmp_MaxInventory.ic_Health;
    UWORD *invPtr         = &inventory->inv_Consumables.ic_Health;
    for (UWORD n = 0; n < sizeof(InventoryConsumables)/sizeof(UWORD); ++n) {
        if (invPtr[n] > limPtr[n]) {
            invPtr[n] = limPtr[n];
        }
    }
}

void game_LoadModProperties()
{
    BPTR modPropsFH = Open(GAME_PROPERTIES_DATA_PATH, MODE_OLDFILE);
    if (DOSFALSE == modPropsFH) {
        return;
    }

    ExamineFH(modPropsFH, &io_FileInfoBlock);

    if (
       io_FileInfoBlock.fib_DirEntryType >= 0 ||
       io_FileInfoBlock.fib_Size < (LONG)sizeof(Game_ModProperties)
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
