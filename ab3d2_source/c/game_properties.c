#include "system.h"
#include "game.h"
#include <dos/dos.h>
#include <proto/dos.h>
#include <proto/exec.h>

extern Game_ModProperties       game_ModProps;
extern Game_PlayerProgression   game_PlayerProgression;
extern Achievement*             game_AchievementsDataPtr;
extern UWORD                    game_AchievementRuleMask[];
extern char const               game_PropertiesFile[];
extern ULONG                    Game_ProgressSignal; // signal to check progress

extern struct FileInfoBlock io_FileInfoBlock;

/**
 * Free any achievements data that was loaded
 */
void game_FreeAchievementsData(void)
{
    if (game_AchievementsDataPtr) {
        FreeVec(game_AchievementsDataPtr);
    }
    game_AchievementsDataPtr = 0;
    game_ModProps.gmp_NumAchievements = 0;
    game_ModProps.gmp_AchievementSize = 0;
}

/**
 * Prepare any loaded achievements data. This involves replacing nonzero string offsets with their addresses in the
 * shared string heap
 */
void game_InitAchievementsData(void)
{
    if (!game_AchievementsDataPtr || !game_ModProps.gmp_NumAchievements) {
        return;
    }
    char const* stringHeap = (char const*)game_AchievementsDataPtr + (game_ModProps.gmp_NumAchievements * sizeof(Achievement));
    ULONG offset;
    for (UWORD i = 0; i < game_ModProps.gmp_NumAchievements; ++i) {
        if ( (offset = (ULONG)game_AchievementsDataPtr[i].ac_Name) ) {
            game_AchievementsDataPtr[i].ac_Name = stringHeap + offset;
        }
        if ( (offset = (ULONG)game_AchievementsDataPtr[i].ac_RewardDesc) ) {
            game_AchievementsDataPtr[i].ac_RewardDesc = stringHeap + offset;
        }

        offset = game_AchievementsDataPtr[i].ac_RuleId;
        game_AchievementsDataPtr[i].ac_RuleMask = game_AchievementRuleMask[offset];
    }
}

void game_LoadModProperties(void)
{
    /* Safely initialise defaults */
    game_ModProps.gmp_MaxInventory.ic_Health      = GAME_DEFAULT_HEALTH_LIMIT;
    game_ModProps.gmp_MaxInventory.ic_JetpackFuel = GAME_DEFAULT_FUEL_LIMIT;
    for (int i = 0; i < NUM_BULLET_DEFS; ++i) {
        game_ModProps.gmp_MaxInventory.ic_AmmoCounts[i] = GAME_DEFAULT_AMMO_LIMIT;
    }
    BPTR modPropsFH = Open(game_PropertiesFile, MODE_OLDFILE);
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
        game_ModProps.gmp_NumAchievements =
            props->gmp_NumAchievements < GAME_MAX_ACHIEVEMENTS ?
            props->gmp_NumAchievements : 0;
        game_ModProps.gmp_AchievementSize =
            props->gmp_NumAchievements ?
            props->gmp_AchievementSize : 0;
    }

    /** Now, read in the achievements data */
    if (
        game_ModProps.gmp_NumAchievements &&
        game_ModProps.gmp_AchievementSize > (game_ModProps.gmp_NumAchievements * sizeof(Achievement)) &&
        (game_AchievementsDataPtr = AllocVec(game_ModProps.gmp_AchievementSize, MEMF_ANY))
    ) {

        bytesRead = Read(modPropsFH, game_AchievementsDataPtr, game_ModProps.gmp_AchievementSize);

        if (bytesRead != game_ModProps.gmp_AchievementSize) {
            game_FreeAchievementsData();
        } else {
            game_InitAchievementsData();
        }
    }

    Close(modPropsFH);
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
            //givesAnything |= objInvPtr[n];
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
)
{
    UWORD       *plrInvPtr = &inventory->inv_Items.ii_Jetpack;
    UWORD const *objInvPtr = &items->ii_Jetpack;

    /* Add all the items */
    for (UWORD n = 0; n < sizeof(InventoryItems)/sizeof(UWORD); ++n) {
        plrInvPtr[n] |= objInvPtr[n];
    }

    plrInvPtr = &inventory->inv_Consumables.ic_Health;
    objInvPtr = &consumables->ic_Health;

    ULONG* game_TotalCollectedPtr = &game_PlayerProgression.gs_TotalHealthCollected;

    UWORD const* limInvPtr = &game_ModProps.gmp_MaxInventory.ic_Health;

    /* Add all the consumables */
    for (UWORD n = 0; n < sizeof(InventoryConsumables)/sizeof(UWORD); ++n) {
        /** For achievements, we need to track the amount actually collected */
        UWORD preInv = plrInvPtr[n];
        plrInvPtr[n] = addSaturated(
            plrInvPtr[n],
            objInvPtr[n],
            limInvPtr[n]
        );
        /** Add to the collected total for progression. These are intentionally defined in the same order */
        game_TotalCollectedPtr[n] += plrInvPtr[n] - preInv;
    }
    Game_ProgressSignal |= (1 << GAME_EVENTBIT_ADD_INVENTORY);
}

void Game_ApplyInventoryLimits(REG(a0, Inventory* inventory))
{
    UWORD const *limPtr = &game_ModProps.gmp_MaxInventory.ic_Health;
    UWORD *invPtr       = &inventory->inv_Consumables.ic_Health;
    for (UWORD n = 0; n < sizeof(InventoryConsumables)/sizeof(UWORD); ++n) {
        if (invPtr[n] > limPtr[n]) {
            invPtr[n] = limPtr[n];
        }
    }
}


