#include <stdio.h>
#include "game_mod.h"
#include "devmode.h"

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

static GMF_Data* gmod_Data = NULL;

/**
 * TODO
 *
 * Define new structure that has the direct references to the data we need.
 */
struct {
    GMod_Achievement const* GMod_aAchievements;
    ULONG GMod_NumAchievements;
} GMod_Properties = {
    .GMod_aAchievements   = NULL,
    .GMod_NumAchievements = 0
};

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
 * Parser for the Special Ammo Bonuses Chunk
 */
BOOL gmod_ParseAchievements(GMF_ChunkHeader const* pChunkHeader, GMF_Data* pGMFData)
{
    dprintf(
        "\tgmod_ParseAchievements() %.*s\n",
        4, pChunkHeader->ch_Ident.id_Text
    );
    GMF_ChunkHeader const* pRewardChunk = GMF_LocateChunk(pGMFData, IDENT_RWRD);
    GMod_Achievement*      pAchievement = (GMod_Achievement*)GMF_ChunkData(pChunkHeader);

    int iNumEntries = pChunkHeader->ch_Length / sizeof(GMod_Achievement);

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


void GMod_Init()
{
    gmod_Data = GMF_LoadFile("ab3:Includes/custom_game.props", &gmod_Header, gmod_Parsers);

    // Assign pointers to frequently accessed members to GMod_Properties fields here.
}

void GMod_Done()
{
    if (gmod_Data) {
        GMF_Free(gmod_Data);
        gmod_Data = NULL;
    }
}
