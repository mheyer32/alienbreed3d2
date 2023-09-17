#include "system.h"
#include "game_properties.h"
#include <dos/dos.h>
#include <proto/dos.h>

extern Game_ModProperties game_ModProperties;

static void game_LoadModProperties(void);

void Game_InitDefaults(void)
{
    game_ModProperties.gmp_MaxCollectableCounts.cc_Health      = GAME_DEFAULT_HEALTH_LIMIT;
    game_ModProperties.gmp_MaxCollectableCounts.cc_JetpackFuel = GAME_DEFAULT_FUEL_LIMIT;
    for (int i = 0; i < NUM_BULLET_DEFS; ++i) {
        game_ModProperties.gmp_MaxCollectableCounts.cc_AmmoCounts[i] = GAME_DEFAULT_AMMO_LIMIT;
    }
    game_LoadModProperties();
}

/**
 * Check if an item can be collected based on the player's Inventory state
 */
BOOL Game_CheckItemCollect(REG(a0, const Inventory* playerInventory), REG(a1, const Inventory* itemInventory))
{
    /** If the item gives us an item we don't have, we can collect it */
    if (itemInventory->inv_Jetpack && !playerInventory->inv_Jetpack) {
        return TRUE;
    }

    if (itemInventory->inv_Shield && !playerInventory->inv_Shield) {
        return TRUE;
    }

    for (UWORD n = 0; n < NUM_GUN_DEFS; ++n) {
        if (itemInventory->inv_Weapons[n] && !playerInventory->inv_Weapons[n]) {
            return TRUE;
        }
    }

    /** If the item gives us a quantity of something we aren't maxed out on, we can collect it */
    if (
        itemInventory->inv_Counts.cc_Health > 0 &&
        playerInventory->inv_Counts.cc_Health < game_ModProperties.gmp_MaxCollectableCounts.cc_Health
    ) {
        return TRUE;
    }

    /** If the item gives us fuel and we aren't maxed. we can collect */
    if (
        itemInventory->inv_Counts.cc_JetpackFuel > 0 &&
        playerInventory->inv_Counts.cc_JetpackFuel < game_ModProperties.gmp_MaxCollectableCounts.cc_JetpackFuel
    ) {
        return TRUE;
    }

    for (UWORD n = 0; n < NUM_BULLET_DEFS; ++n) {
        if (
            itemInventory->inv_Counts.cc_AmmoCounts[n] > 0 &&
            playerInventory->inv_Counts.cc_AmmoCounts[n] < game_ModProperties.gmp_MaxCollectableCounts.cc_AmmoCounts[n]
        ) {
            return FALSE;
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
void Game_AddToPlayerInventory(REG(a0, Inventory* playerInventory), REG(a1, const Inventory* itemInventory))
{
    /** Add all of the items to the player inventory */
    playerInventory->inv_Jetpack |= itemInventory->inv_Jetpack;
    playerInventory->inv_Shield  |= itemInventory->inv_Shield;
    for (UWORD n = 0; n < NUM_GUN_DEFS; ++n) {
        playerInventory->inv_Weapons[n] |= itemInventory->inv_Weapons[n];
    }

    playerInventory->inv_Counts.cc_Health = addSaturated(
        playerInventory->inv_Counts.cc_Health,
        itemInventory->inv_Counts.cc_Health,
        game_ModProperties.gmp_MaxCollectableCounts.cc_Health
    );

    playerInventory->inv_Counts.cc_JetpackFuel = addSaturated(
        playerInventory->inv_Counts.cc_JetpackFuel,
        itemInventory->inv_Counts.cc_JetpackFuel,
        game_ModProperties.gmp_MaxCollectableCounts.cc_JetpackFuel
    );

    for (UWORD n = 0; n < NUM_BULLET_DEFS; ++n) {
        playerInventory->inv_Counts.cc_AmmoCounts[n] = addSaturated(
            playerInventory->inv_Counts.cc_AmmoCounts[n],
            itemInventory->inv_Counts.cc_AmmoCounts[n],
            game_ModProperties.gmp_MaxCollectableCounts.cc_AmmoCounts[n]
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

    Game_ModProperties* tempProps = (Game_ModProperties*)Sys_GetTemporaryWorkspace();

    LONG bytesRead = Read(modPropsFH, tempProps, sizeof(Game_ModProperties));
    if (bytesRead == (LONG)sizeof(Game_ModProperties)) {
        if (tempProps->gmp_MaxCollectableCounts.cc_Health < GAME_UNCAPPED_LIMIT) {
            game_ModProperties.gmp_MaxCollectableCounts.cc_Health = tempProps->gmp_MaxCollectableCounts.cc_Health;
        }
        if (tempProps->gmp_MaxCollectableCounts.cc_JetpackFuel < GAME_UNCAPPED_LIMIT) {
            game_ModProperties.gmp_MaxCollectableCounts.cc_JetpackFuel = tempProps->gmp_MaxCollectableCounts.cc_JetpackFuel;
        }

        for (int i = 0; i < NUM_BULLET_DEFS; ++i) {
            if (tempProps->gmp_MaxCollectableCounts.cc_AmmoCounts[i] < GAME_UNCAPPED_LIMIT) {
                game_ModProperties.gmp_MaxCollectableCounts.cc_AmmoCounts[i] = tempProps->gmp_MaxCollectableCounts.cc_AmmoCounts[i];
            }
        }
    }
    Close(modPropsFH);
}
