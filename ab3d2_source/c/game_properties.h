#ifndef GAME_PROPERTIES_H
#define GAME_PROPERTIES_H

#include "defs.h"

#define GAME_PROPERTIES_DATA_PATH "ab3:Includes/game_properties.dat"

/** Inventory limits for the default game */
#define GAME_DEFAULT_AMMO_LIMIT 10000
#define GAME_DEFAULT_HEALTH_LIMIT 10000
#define GAME_DEFAULT_FUEL_LIMIT 250
#define GAME_UNCAPPED_LIMIT 32767

/**
 * @see defs.i / STRUCTURE PlrT
 */
typedef struct {
    UWORD maxHealth;
    UWORD maxJetpackFuel;
    UWORD maxAmmoCounts[NUM_BULLET_DEFS];
} Game_InventoryLimits;

typedef struct {
    Game_InventoryLimits invLimits;
    /** TODO other things here ... */
} Game_ModProperties;

extern void Game_InitDefaults(void);

#endif // MESSAGE_H
