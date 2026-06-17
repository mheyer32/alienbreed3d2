#include <stdio.h>
#include "game_mod.h"
#include "devmode.h"
#include <proto/exec.h>
#include "system.h"
#include "game.h"

/**
 * game_mod_load.c
 *
 * Code for loading and parsing the main game modification files and associated game progress.
 *
 */

extern char const GMod_PropertiesFile[];
extern char const GMod_ProgressFile[];

#if defined(DEV)
static char const* aRuleNames[] = {
    "KillCount",      // 0
    "GroupKillCount", // 1
    "ZoneFound",      // 2
    "TimeImproved",   // 3
    "PlayerDied",     // 4
    "Collected",      // 5
};
#endif

/**
 * For every rule type, there are game event signal bits that should be set before we bother wasting
 * time checking achievements.
 */
static UWORD gmod_AchievementRuleSignalMask[] = {
    1 << GAME_EVENTBIT_KILL,
    1 << GAME_EVENTBIT_KILL,
    1 << GAME_EVENTBIT_ZONE_CHANGE,
    1 << GAME_EVENTBIT_LEVEL_START,
    1 << GAME_EVENTBIT_LEVEL_START,
    1 << GAME_EVENTBIT_ADD_INVENTORY,
};

/**********************************************************************************************************************/

/**
 * gmod_ResolveReward()
 *
 * For a given initial reward reference, resolves an offset to the actual in memory location of the GMod_Reward
 * instance.
 */
static GMod_Reward* gmod_ResolveReward(GMod_Reward const* pReward, GMF_ChunkHeader const* pRewardChunk)
{
    return (GMod_Reward*)((UBYTE*)pReward + (size_t)pRewardChunk);
}

/**
 * gmod_ParseSpecialAmmoBonuses()
 *
 * Parser for the Special Ammo Bonuses Chunk
 *
 * Parser is only called if the chunk exists, so assumptions about the pointer are safe.
 */
BOOL gmod_ParseSpecialAmmoBonuses(GMF_ChunkHeader const* pChunkHeader, GMF_Data* pGMFData)
{
//     dprintf(
//         "\tgmod_ParseSpecialAmmoBonuses() %.*s\n",
//         4, pChunkHeader->ch_Ident.id_Text
//     );
    GMF_ChunkHeader const* pRewardChunk = GMF_LocateChunk(pGMFData, IDENT_RWRD);
    GMod_SpecialAmmoBonus* pSPAB = (GMod_SpecialAmmoBonus*)GMF_ChunkData(pChunkHeader);
    while (pSPAB->spab_Index != 0xFFFF) {
        if (pSPAB->spab_Reward != NULL) {
//             dprintf(
//                 "\t\tResolving SPAB %d [%d]\n\t\t\tReward [%p + %zu] ",
//                 (int)pSPAB->spab_Index,
//                 (int)pSPAB->spab_AmmoID,
//                 pRewardChunk,
//                 (size_t)pSPAB->spab_Reward
//             );
            GMod_Reward* pReward   = gmod_ResolveReward(pSPAB->spab_Reward, pRewardChunk);
            pReward->rwrd_Description = GMF_ResolveString(pReward->rwrd_Description, pGMFData);
            pSPAB->spab_Reward     = pReward;
//            dputs(pReward->rwrd_Description);
        }
        ++pSPAB;
    }
    return TRUE;
}

/**
 * gmod_ParseAchievements()
 *
 * Parser for the Achievements Chunk
 *
 * Parser is only called if the chunk exists, so assumptions about the pointer are safe.
 */
BOOL gmod_ParseAchievements(GMF_ChunkHeader const* pChunkHeader, GMF_Data* pGMFData)
{
//     dprintf(
//         "\tgmod_ParseAchievements() %.*s\n",
//         4, pChunkHeader->ch_Ident.id_Text
//     );
    GMF_ChunkHeader const* pRewardChunk = GMF_LocateChunk(pGMFData, IDENT_RWRD);
    GMod_Achievement*      pAchievement = (GMod_Achievement*)GMF_ChunkData(pChunkHeader);

    int iNumEntries = (pChunkHeader->ch_Length - sizeof(GMF_ChunkHeader)) / sizeof(GMod_Achievement);

    for (int i = 0; i < iNumEntries; ++i) {
        pAchievement->achv_Description = GMF_ResolveString(pAchievement->achv_Description, pGMFData);
        if (pAchievement->achv_Reward != NULL) {
//             dprintf(
//                 "\t\tResolving ACHV %d [Rule %d %s] [Name %s]\n\t\t\tReward [%p + %zu] ",
//                 i,
//                 (int)pAchievement->achv_RuleType,
//                 aRuleNames[pAchievement->achv_RuleType],
//                 pAchievement->achv_Description,
//                 pRewardChunk,
//                 (size_t)pAchievement->achv_Reward
//             );
            GMod_Reward* pReward      = gmod_ResolveReward(pAchievement->achv_Reward, pRewardChunk);
            pReward->rwrd_Description = GMF_ResolveString(pReward->rwrd_Description, pGMFData);
            pAchievement->achv_Reward = pReward;
            //dputs(pReward->rwrd_Description);
        } /*else {
            dprintf(
                "\t\tResolving ACHV %d [Rule %d %s] [Name %s]\n",
                i,
                (int)pAchievement->achv_RuleType,
                aRuleNames[pAchievement->achv_RuleType],
                pAchievement->achv_Description
            );
        }*/

        // Set the event signal mask from the rule type.
        pAchievement->achv_EventMask = gmod_AchievementRuleSignalMask[pAchievement->achv_RuleType];
/*
        // Verbose
        switch (pAchievement->achv_RuleType) {
            case AR_KILL_COUNT:
                dprintf(
                    "\t\t\t{ uCount: %lu, uAlienType: %d }\n",
                    pAchievement->achv_Param.oKillCount.uCount,
                    (int)pAchievement->achv_Param.oKillCount.uAlienType
                );
                break;

            case AR_GROUP_KILL_COUNT:
                dprintf(
                    "\t\t\t{ uCount: %lu, uAlienMask: 0x%08X }\n",
                    pAchievement->achv_Param.oGroupKillCount.uCount,
                    pAchievement->achv_Param.oGroupKillCount.uAlienMask
                );
                break;

            case AR_ZONE_FOUND:
                dprintf(
                    "\t\t\t{ uLevel: %d, uZoneID: %d }\n",
                    (int)pAchievement->achv_Param.oZoneFound.uLevel,
                    (int)pAchievement->achv_Param.oZoneFound.uZoneID
                );
                break;

            case AR_TIME_IMPROVED:
                dprintf(
                    "\t\t\t{ uCount: %d, bOverall: %d, uLevelMask: 0x%04X }\n",
                    pAchievement->achv_Param.oMaskedLevelCount.uCount,
                    (int)pAchievement->achv_Param.oMaskedLevelCount.bOverall,
                    pAchievement->achv_Param.oMaskedLevelCount.uLevelMask
                );
                break;

            case AR_PLAYER_DIED:
                dprintf(
                    "\t\t\t{ uCount: %d, bOverall: %d, uLevelMask: 0x%04X }\n",
                    pAchievement->achv_Param.oMaskedLevelCount.uCount,
                    (int)pAchievement->achv_Param.oMaskedLevelCount.bOverall,
                    pAchievement->achv_Param.oMaskedLevelCount.uLevelMask
                );
                break;

            case AR_COLLECTED:
                dprintf(
                    "\t\t\t{ uCount: %lu, uConsumable: %d }\n",
                    pAchievement->achv_Param.oCollected.uCount,
                    pAchievement->achv_Param.oCollected.uConsumable
                );
                break;

            default:
                break;
        }
*/
        ++pAchievement;
    }

    return TRUE;
}

/**********************************************************************************************************************/
/**
 * Zero terminated list of custom parser functions for specific idents
 */
static GMF_ParserEntry gmod_Parsers[] = {
    { IDENT_SPAB, gmod_ParseSpecialAmmoBonuses },
    { IDENT_ACHV, gmod_ParseAchievements },
    { 0, NULL },
};

/**
 * Main Game Modification File, GMOD
 */
static GMF_Header const gmod_Header = {
    .h_Ident.id_Value     = IDENT_TKGD,
    .h_SubFormat.id_Value = IDENT_GMOD,
    .h_Version            = {TKG_VERSION, TKG_REVISION}
};


/**
 * Player Progression File, GPRG.
 * Also referenced from the save code.
 */
GMF_Header const gprg_Header = {
    .h_Ident.id_Value     = IDENT_TKGD,
    .h_SubFormat.id_Value = IDENT_GPRG,
    .h_Version            = {TKG_VERSION, TKG_REVISION}
};


/**********************************************************************************************************************/

static inline UWORD clamp(UWORD val, UWORD max)
{
    return val < max ? val : max;
}

/**
 * Helper function, sets the active inventory limits according to some source. Caller bears responsibility
 * for ensuring source is valid.
 */
static void gmod_SetInventoryLimitsFrom(GMod_InventoryLimits const* restrict pSource)
{
    GMod_Progress.pprg_InventoryLimits.ic_Health = clamp(
        pSource->ic_Health,
        INVENTORY_UNCAPPED_LIMIT
    );
    GMod_Progress.pprg_InventoryLimits.ic_JetpackFuel = clamp(
        pSource->ic_JetpackFuel,
        INVENTORY_UNCAPPED_LIMIT
    );
    for (WORD i = 0; i < NUM_BULLET_DEFS; ++i) {
        GMod_Progress.pprg_InventoryLimits.ic_AmmoCounts[i] = clamp(
            pSource->ic_AmmoCounts[i],
            INVENTORY_UNCAPPED_LIMIT
        );
    }
}

/**
 * Helper function, sets the active weaoin adjustments limits according to some source. Caller bears responsibility
 * for ensuring source is valid.
 */
static void gmod_SetWeaponAdjustmentsFrom(GMod_WeaponAdjustment const* pSource, ULONG iNum)
{
    while (iNum--) {
        UWORD slotID = pSource->wadj_SlotID;
        // TODO - when we add these for real, this is where to sanity check the field rather than just
        // copying
        CopyMem(
            pSource,
            &GMod_Progress.pprg_WeaponAdjustments[slotID],
            sizeof(GMod_WeaponAdjustment)
        );
        ++pSource;
    }
}

/**********************************************************************************************************************/

/**
 * Set the mod defined defaults for GMod_Progress
 */
static void gmod_SetModDefaults(void)
{
    // If we have defined limits, apply those.
    if (GMod_Defaults.gmod_DefinedInventoryLimits) {
        gmod_SetInventoryLimitsFrom(GMod_Defaults.gmod_DefinedInventoryLimits);
        //dputs("Set modification default inventory limits");
    }

    // If we have weapon adjustments, apply those
    if (GMod_Defaults.gmod_DefinedWeaponAdjustments && GMod_Defaults.gmod_NumDefinedWeaponAdjustments > 0) {
        gmod_SetWeaponAdjustmentsFrom(
            GMod_Defaults.gmod_DefinedWeaponAdjustments,
            GMod_Defaults.gmod_NumDefinedWeaponAdjustments
        );
    }

    // Allocate the dynamic achievements data here.
    if (GMod_Defaults.gmod_DefinedAchievements && GMod_Defaults.gmod_NumDefinedAchievements > 0) {
        ULONG allocSize =
            (GMod_Defaults.gmod_NumDefinedAchievements * sizeof(ShortDate)) + // Unlock Date buffer
            ((GMod_Defaults.gmod_NumDefinedAchievements + 7) >> 3);           // Bitmap
        UWORD* pData = (UWORD*)AllocVec(allocSize, MEMF_ANY|MEMF_CLEAR);
        if (pData) {
            //dprintf("Allocated %lu bytes for achievement unlock tracking\n", allocSize);
            GMod_Progress.pprg_Unlocked    = pData;
            GMod_Progress.pprg_UnlockedMap = (UBYTE*)(&pData[GMod_Defaults.gmod_NumDefinedAchievements]);
        } else {
            dprintf("WARNING: Failed to allocate %lu bytes for achievement tracking!", allocSize);
            // As a precaution set these to null. They only point at resources that we manage via a different
            // pointer
            GMod_Defaults.gmod_DefinedAchievements = NULL;
            GMod_Defaults.gmod_NumDefinedAchievements = 0;
            GMod_Progress.pprg_Unlocked = NULL;
            GMod_Progress.pprg_UnlockedMap = NULL;
        }
    }
}

/**********************************************************************************************************************/

/**
 * Load and apply any the defaults defined by the game modification.
 */
BOOL GMod_LoadModDefaults(void)
{
    dputs("GMod_LoadModDefaults()");
    GMod_Defaults.gmod_Loaded = GMF_LoadFile(GMod_PropertiesFile, &gmod_Header, gmod_Parsers);
    if (NULL == GMod_Defaults.gmod_Loaded) {
        dputs("No game modification properties loaded");
        return FALSE;
    }

    GMF_ChunkHeader const* pChunk;
    // Inventory limits (size is fixed)
    if ( (pChunk = GMF_LocateChunk(GMod_Defaults.gmod_Loaded, IDENT_INVL)) ) {
        // Fixed size
        GMod_Defaults.gmod_DefinedInventoryLimits = (GMod_InventoryLimits const*)GMF_ChunkData(pChunk);
    }

    // Special Ammo Bonuses
    if ( (pChunk = GMF_LocateChunk(GMod_Defaults.gmod_Loaded, IDENT_SPAB)) ) {
        GMod_Defaults.gmod_DefinedSpecialAmmoBonuses    = (GMod_SpecialAmmoBonus const*)GMF_ChunkData(pChunk);
        GMod_Defaults.gmod_NumDefinedSpecialAmmoBonuses = GMF_ChunkRecordCount(pChunk, GMod_SpecialAmmoBonus);
    }

    // Weapon Adjustments
    if ( (pChunk = GMF_LocateChunk(GMod_Defaults.gmod_Loaded, IDENT_WADJ)) ) {
        GMod_Defaults.gmod_DefinedWeaponAdjustments    = (GMod_WeaponAdjustment const*)GMF_ChunkData(pChunk);
        GMod_Defaults.gmod_NumDefinedWeaponAdjustments = GMF_ChunkRecordCount(pChunk, GMod_WeaponAdjustment);
    }

    // Achievements
    if ( (pChunk = GMF_LocateChunk(GMod_Defaults.gmod_Loaded, IDENT_ACHV)) ) {
        GMod_Defaults.gmod_DefinedAchievements         = (GMod_Achievement const*)GMF_ChunkData(pChunk);
        GMod_Defaults.gmod_NumDefinedAchievements      = GMF_ChunkRecordCount(pChunk, GMod_Achievement);
    }
//     dprintf(
//         "GMod_LoadModDefaults()\n"
//         "\tgmod_Loaded:                    %p\n"
//         "\tgmod_DefinedInventoryLimits:    %p\n"
//         "\tgmod_DefinedSpecialAmmoBonuses: %p %lu\n"
//         "\tgmod_DefinedWeaponAdjustments:  %p %lu\n"
//         "\tgmod_DefinedAchievements:       %p %lu\n",
//         GMod_Defaults.gmod_Loaded,
//         GMod_Defaults.gmod_DefinedInventoryLimits,
//         GMod_Defaults.gmod_DefinedSpecialAmmoBonuses,
//         GMod_Defaults.gmod_NumDefinedSpecialAmmoBonuses,
//         GMod_Defaults.gmod_DefinedWeaponAdjustments,
//         GMod_Defaults.gmod_NumDefinedWeaponAdjustments,
//         GMod_Defaults.gmod_DefinedAchievements,
//         GMod_Defaults.gmod_NumDefinedAchievements
//     );
    gmod_SetModDefaults();
    return TRUE;
}

/**********************************************************************************************************************/

void GMod_LoadPlayerProgress(void)
{
    dputs("GMod_LoadPlayerProgress()");
    GMF_Data const* pLoaded = GMF_LoadFile(GMod_ProgressFile, &gprg_Header, NULL);
    if (pLoaded) {
        GMF_ChunkHeader const* pChunk;

        // Current Inventory Limits
        if ( (pChunk = GMF_LocateChunk(pLoaded, IDENT_INVL)) ) {
            // Fixed size
            gmod_SetInventoryLimitsFrom(
                (GMod_InventoryLimits const *)GMF_ChunkData(pChunk)
            );
        }

        // Current Weapon Adjustments
        if ( (pChunk = GMF_LocateChunk(pLoaded, IDENT_WADJ)) ) {
            ULONG numAdjustments = GMF_ChunkRecordCount(pChunk, GMod_WeaponAdjustment);
            if (numAdjustments > 0) {
                gmod_SetWeaponAdjustmentsFrom(
                    (GMod_WeaponAdjustment const *)GMF_ChunkData(pChunk),
                    numAdjustments
                );
            }
        }

        // Counters
        if ( (pChunk = GMF_LocateChunk(pLoaded, IDENT_CTRS)) ) {
            CopyMem(
                GMF_ChunkData(pChunk),
                &GMod_Progress.pprg_Counters,
                sizeof(GMod_ProgressCounters)
            );
        }

        // Current unlocked achievements
        if (
            GMod_Defaults.gmod_DefinedAchievements &&
            GMod_Progress.pprg_Unlocked &&
            (pChunk = GMF_LocateChunk(pLoaded, IDENT_UNLK))
        ) {
            ULONG numUnlocked = GMF_ChunkRecordCount(pChunk, GMod_Unlocked);
            GMod_Unlocked const* restrict pUnlocked = (GMod_Unlocked const *)GMF_ChunkData(pChunk);
            while (numUnlocked--) {
                // Sanity check here.
                if (pUnlocked->gpc_ID < GMod_Defaults.gmod_NumDefinedAchievements) {
                    //dprintf("Unlocked %d [0x%04X]\n", (int)pUnlocked->gpc_ID, (unsigned)pUnlocked->gpc_Awarded);

                    GMod_Progress.pprg_Unlocked[pUnlocked->gpc_ID] = pUnlocked->gpc_Awarded;
                    UWORD byte = pUnlocked->gpc_ID >> 3;
                    UBYTE bit  = (1 << (pUnlocked->gpc_ID  & 7));
                    GMod_Progress.pprg_UnlockedMap[byte] |= bit;
                } else {
                    dprintf("Unrecognised achievement ID %d\n", (int)pUnlocked->gpc_ID);
                }
                ++pUnlocked;
            }
        }

        // We're done here. Free the temporary.
        FreeVec((void*)pLoaded);
    } else {
        dputs("Failed to process player progress");
    }
}

