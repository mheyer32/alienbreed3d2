#ifndef INVENTORY_H
#define INVENTORY_H

#include "defs.h"

/*
 * These structures are managed by the assembler side and the alignment constraints are to preven the compiler
 * from padding them further for alignment purposes. It does not mean that the structures themselves are only
 * aligned to a 2 byte boundary,
 */
typedef struct {
    /* Note that we have separate named fields here, but we regard the struct as equivalent to UWORD[]*/
    UWORD ic_Health;
    UWORD ic_JetpackFuel;
    UWORD ic_AmmoCounts[NUM_BULLET_DEFS];
} ASM_ALIGN(sizeof(WORD)) InventoryConsumables;

typedef struct {
    /* Note that we have separate named fields here, but we regard the struct as equivalent to UWORD[]*/
    UWORD ii_Shield;
    UWORD ii_Jetpack;
    UWORD ii_Weapons[NUM_GUN_DEFS];
} ASM_ALIGN(sizeof(WORD)) InventoryItems;

typedef struct {
    InventoryConsumables inv_Consumables;
    InventoryItems       inv_Items;
} ASM_ALIGN(sizeof(WORD)) Inventory;

/**
 * Unmodified default limits
 */
#define INVENTORY_DEFAULT_AMMO_LIMIT 10000
#define INVENTORY_DEFAULT_HEALTH_LIMIT 10000
#define INVENTORY_DEFAULT_FUEL_LIMIT 250
#define INVENTORY_UNCAPPED_LIMIT 32000
#define INVENTORY_SLOTS (sizeof(InventoryConsumables)/sizeof(UWORD))

#endif // INVENTORY_H
