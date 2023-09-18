#ifndef GAME_PROPERTIES_H
#define GAME_PROPERTIES_H

#include "defs.h"

#define GAME_PROPERTIES_DATA_PATH "ab3:Includes/game_properties.dat"

/** Inventory limits for the default game */
#define GAME_DEFAULT_AMMO_LIMIT 10000
#define GAME_DEFAULT_HEALTH_LIMIT 10000
#define GAME_DEFAULT_FUEL_LIMIT 250
#define GAME_UNCAPPED_LIMIT 32767

typedef struct {
    InventoryConsumables gmp_MaxInventory;
    /** TODO other things here ... */
} Game_ModProperties;

extern void Game_InitDefaults(void);

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
extern BOOL Game_CheckCanCollect(
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

#endif // GAME_PROPERTIES_H
