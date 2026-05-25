#include <stdio.h>
#include "game_mod.h"
#include "devmode.h"
#include <proto/exec.h>
#include "system.h"
#include "game.h"

static ULONG gmod_CountActiveAdjustments()
{
    ULONG uCount = 0;
    GMod_WeaponAdjustment const* pAdjustment = GMod_Progress.pprg_WeaponAdjustments;
    for (UWORD i = 0; i < NUM_GUN_DEFS; ++i) {
        if (pAdjustment[i].wadj_SlotID != 0xFFFF) {
            ++uCount;
        }
    }
    dprintf("\tGot %u Weapon Adjustments\n", uCount);
    return uCount;
}

static ULONG gmod_CountAchievementUnlocks()
{
    ULONG uCount = 0;
    for (ULONG i = 0; i < GMod_Defaults.gmod_NumDefinedAchievements; ++i) {
        if (GMod_Progress.pprg_Unlocked[i]) {
            ++uCount;
        }
    }
    dprintf("\tGot %u Unlocks\n", uCount);
    return uCount;
}

/** Description for string chunk */
char const sSaveDesc[8] = {
    'P','l','y','r','P','r','g', 0
};

static ULONG gmod_CalculateProgressSaveSize()
{
    // Start by assuming the string, limits, adjustments, counters are all present
    ULONG uIndexCount = 4;
    ULONG uTotalSize = sizeof(GMF_Header);
    uTotalSize += Sys_Round4(sizeof(GMF_ChunkHeader) + sizeof(Inventory));
    uTotalSize += Sys_Round4(sizeof(GMF_ChunkHeader) + sizeof(GMod_ProgressCounters));

    // Only include the weapon adjustment chunk if there are any
    ULONG uNumAdjustments = gmod_CountActiveAdjustments();
    if (uNumAdjustments) {
        uTotalSize += Sys_Round4(sizeof(GMF_ChunkHeader) + (uNumAdjustments * sizeof(GMod_WeaponAdjustment)));
        ++uIndexCount;
    }

    // Only include the unlock chunk if there are any
    ULONG uNumUnlocks = gmod_CountAchievementUnlocks();
    if (uNumUnlocks) {
        uTotalSize += Sys_Round4(sizeof(GMF_ChunkHeader) + (uNumUnlocks * sizeof(GMod_Unlocked)));
        ++uIndexCount;
    }

    // Add the size of the index chunk
    uTotalSize += Sys_Round4(sizeof(GMF_ChunkHeader) + uIndexCount * sizeof(GMF_IndexEntry));

    // Single string chunk
    uTotalSize += Sys_Round4(sizeof(GMF_ChunkHeader) + sizeof(sSaveDesc));

    return uTotalSize;
}

void GMod_SavePlayerProgress(void)
{
    dputs("GMod_SavePlayerProgress() is not yet implemented.");

    // First work out the required total buffer size:
    // 1. Basic Header
    // 2. Index Chunk with references to each chunk.
    // 3. Inventory Limits Chunk (fixed size)
    // 4. Weapon Adjustments Chunk (depends on number of defined adjustments)
    // 5. Unlocked Chunk.
    // 6. String Chunk

    ULONG uSize = gmod_CalculateProgressSaveSize();

    dprintf("\tRequire %u bytes for progress save buffer\n", uSize);
}

