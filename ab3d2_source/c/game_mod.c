#include <stdio.h>
#include "game_mod.h"
#include "devmode.h"
#include <proto/exec.h>

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

/**
 * TODO
 *
 * Define new structure that has the direct references to the data we need.
 */
struct {
    GMF_Data const* gmp_Data;
    UBYTE*          gmp_Buffers;
    GMod_Achievement const* gmp_Achievements;
    ULONG  gmp_NumAchievements;
    UBYTE* gmp_AchievedBitmap;
    UWORD* gmp_AchievedDate;

} GMod_Properties = {
    .gmp_Data            = NULL,
    .gmp_Buffers         = NULL,
    .gmp_Achievements    = NULL,
    .gmp_NumAchievements = 0,
    .gmp_AchievedBitmap  = NULL,
    .gmp_AchievedDate    = NULL
};

static void gmod_ResetProperties()
{
    GMod_Properties.gmp_Data            = NULL;
    GMod_Properties.gmp_Buffers         = NULL;
    GMod_Properties.gmp_Achievements    = NULL;
    GMod_Properties.gmp_NumAchievements = 0;
    GMod_Properties.gmp_AchievedBitmap  = NULL;
    GMod_Properties.gmp_AchievedDate    = NULL;
}

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

    GMod_Properties.gmp_Achievements    = pAchievement;
    GMod_Properties.gmp_NumAchievements = (ULONG)iNumEntries;

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
    GMod_Properties.gmp_Data = GMF_LoadFile("ab3:Includes/custom_game.props", &gmod_Header, gmod_Parsers);

    /* Round up the achievement count to the nearest 8 */
    ULONG roundBufferCount = (GMod_Properties.gmp_NumAchievements + 7) & ~7;

    /* Calculate the size needed for a single allocation */
    ULONG allocSize = (roundBufferCount * sizeof(UWORD)) + (roundBufferCount >> 8);
    GMod_Properties.gmp_Buffers = (UBYTE*)AllocVec(allocSize, MEMF_ANY|MEMF_CLEAR);
    GMod_Properties.gmp_AchievedDate   = (UWORD*)GMod_Properties.gmp_Buffers;
    GMod_Properties.gmp_AchievedBitmap = (UBYTE*)(GMod_Properties.gmp_AchievedDate + roundBufferCount);
    printf(
        "gmp_Buffers %p\n"
        "gmp_NumAchievements %d [rounded %d]\n"
        "gmp_AchievedDate %p\n"
        "gmp_AchievedBitmap %p\n",
        GMod_Properties.gmp_Buffers,
        (int)GMod_Properties.gmp_NumAchievements,
        (int)roundBufferCount,
        GMod_Properties.gmp_AchievedDate,
        GMod_Properties.gmp_AchievedBitmap
    );
}

void GMod_Done()
{
    if (GMod_Properties.gmp_Data) {
        GMF_Free(GMod_Properties.gmp_Data);
    }
    if (GMod_Properties.gmp_Buffers) {
        FreeVec((void*)GMod_Properties.gmp_Buffers);
    }
    gmod_ResetProperties();
}
