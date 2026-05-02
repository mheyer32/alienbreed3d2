#include <stdio.h>
#include "game_mod.h"
#include "devmode.h"
#include <proto/exec.h>
#include "system.h"

extern char const game_PropertiesFile[];

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



extern GMod_DefaultProperties GMod_Defaults; // Defined in BSS


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
    dprintf(
        "\tgmod_ParseSpecialAmmoBonuses() %.*s\n",
        4, pChunkHeader->ch_Ident.id_Text
    );
    GMF_ChunkHeader const* pRewardChunk = GMF_LocateChunk(pGMFData, IDENT_RWRD);
    GMod_SpecialAmmoBonus* pSPAB = (GMod_SpecialAmmoBonus*)GMF_ChunkData(pChunkHeader);
    while (pSPAB->spab_Index != 0xFFFF) {
        if (pSPAB->spab_Reward != NULL) {
            dprintf(
                "\t\tResolving SPAB %d [%d]\n\t\t\tReward [%p + %zu] ",
                (int)pSPAB->spab_Index,
                (int)pSPAB->spab_AmmoID,
                pRewardChunk,
                (size_t)pSPAB->spab_Reward
            );
            GMod_Reward* pReward   = gmod_ResolveReward(pSPAB->spab_Reward, pRewardChunk);
            pReward->rwrd_Description = GMF_ResolveString(pReward->rwrd_Description, pGMFData);
            pSPAB->spab_Reward     = pReward;
            dputs(pReward->rwrd_Description);
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
    dprintf(
        "\tgmod_ParseAchievements() %.*s\n",
        4, pChunkHeader->ch_Ident.id_Text
    );
    GMF_ChunkHeader const* pRewardChunk = GMF_LocateChunk(pGMFData, IDENT_RWRD);
    GMod_Achievement*      pAchievement = (GMod_Achievement*)GMF_ChunkData(pChunkHeader);

    int iNumEntries = (pChunkHeader->ch_Length - sizeof(GMF_ChunkHeader)) / sizeof(GMod_Achievement);

    for (int i = 0; i < iNumEntries; ++i) {
        pAchievement->achv_Description = GMF_ResolveString(pAchievement->achv_Description, pGMFData);
        if (pAchievement->achv_Reward != NULL) {
            dprintf(
                "\t\tResolving ACHV %d [Rule %d %s] [Name %s]\n\t\t\tReward [%p + %zu] ",
                i,
                (int)pAchievement->achv_RuleType,
                aRuleNames[pAchievement->achv_RuleType],
                pAchievement->achv_Description,
                pRewardChunk,
                (size_t)pAchievement->achv_Reward
            );
            GMod_Reward* pReward   = gmod_ResolveReward(pAchievement->achv_Reward, pRewardChunk);
            pReward->rwrd_Description = GMF_ResolveString(pReward->rwrd_Description, pGMFData);
            pAchievement->achv_Reward = pReward;
            dputs(pReward->rwrd_Description);
        } else {
            dprintf(
                "\t\tResolving ACHV %d [Rule %d %s] [Name %s]\n",
                i,
                (int)pAchievement->achv_RuleType,
                aRuleNames[pAchievement->achv_RuleType],
                pAchievement->achv_Description
            );
        }
        ++pAchievement;
    }

    return TRUE;
}

static UWORD const* gmod_GetRewardCarry(GMod_Reward const* pReward)
{
    if (pReward->rwrd_CarryOffset >= sizeof(GMF_ChunkHeader)) {
        return (UWORD const*) (
            ((UBYTE const*)pReward) + pReward->rwrd_CarryOffset
        );
    }
    return NULL;
}

static UWORD const* gmod_GetRewardImmediate(GMod_Reward const* pReward)
{
    if (pReward->rwrd_ImmediateOffset >= sizeof(GMF_ChunkHeader)) {
        return (UWORD const*) (
            ((UBYTE const*)pReward) + pReward->rwrd_ImmediateOffset
        );
    }
    return NULL;
}

static inline UWORD gmod_addSaturated(UWORD a, UWORD b, UWORD limit)
{
    UWORD sum = a + b;
    return (sum < a || sum < b || sum > limit) ? limit : sum;
}



void GMod_ApplyReward(
    GMod_Reward const* pReward,
    InventoryConsumables* pInventoryLimits,
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

// typedef struct {
//     GMF_Data const*                 gmod_Loaded;
//     InventoryConsumables const*     gmod_DefinedInventoryLimits;
//     GMod_SpecialAmmoBonus const*    gmod_DefinedSpecialAmmoBonuses;
//     GMod_WeaponAdjustment const*    gmod_DefinedWeaponAdjustments;
//     GMod_Achievement const*         gmod_DefinedAchievements;
//     ULONG                           gmod_NumDefinedSpecialAmmoBonuses;
//     ULONG                           gmod_NumDefinedWeaponAdjustments;
//     ULONG                           gmod_NumDefinedAchievements;
// } GMod_DefaultProperties;

void GMod_Init()
{
    // Paranoia
    Sys_MemFillLong(&GMod_Defaults, 0, sizeof(GMod_DefaultProperties)/sizeof(LONG));

    GMod_Defaults.gmod_Loaded = GMF_LoadFile("ab3:Includes/custom_game.props", &gmod_Header, gmod_Parsers);

    if (NULL == GMod_Defaults.gmod_Loaded) {
        dputs("No game modification properties loaded");
        return;
    }

    GMF_ChunkHeader const* pChunk;

    // Inventory limits (size is fixed)
    if ( (pChunk = GMF_LocateChunk(GMod_Defaults.gmod_Loaded, IDENT_INVL)) ) {
        // Fixed size
        GMod_Defaults.gmod_DefinedInventoryLimits = (InventoryConsumables const*)GMF_ChunkData(pChunk);
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
    dprintf(
        "GMod_Init()\n"
        "\tgmod_Loaded:                    %p\n"
        "\tgmod_DefinedInventoryLimits:    %p\n"
        "\tgmod_DefinedSpecialAmmoBonuses: %p %lu\n"
        "\tgmod_DefinedWeaponAdjustments:  %p %lu\n"
        "\tgmod_DefinedAchievements:       %p %lu\n",
        GMod_Defaults.gmod_Loaded,
        GMod_Defaults.gmod_DefinedInventoryLimits,
        GMod_Defaults.gmod_DefinedSpecialAmmoBonuses,
        GMod_Defaults.gmod_NumDefinedSpecialAmmoBonuses,
        GMod_Defaults.gmod_DefinedWeaponAdjustments,
        GMod_Defaults.gmod_NumDefinedWeaponAdjustments,
        GMod_Defaults.gmod_DefinedAchievements,
        GMod_Defaults.gmod_NumDefinedAchievements
    );
}

void GMod_Done()
{
    if (GMod_Defaults.gmod_Loaded) {
        GMF_Free(GMod_Defaults.gmod_Loaded);
    }
    // Paranoia
    Sys_MemFillLong(&GMod_Defaults, 0, sizeof(GMod_DefaultProperties)/sizeof(LONG));
}
