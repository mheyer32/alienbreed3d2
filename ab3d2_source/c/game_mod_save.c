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
    for(UWORD i = 0; i < NUM_GUN_DEFS; ++i) {
        if (pAdjustment->wadj_SlotID != 0xFFFF) {
            ++uCount;
        }
    }
    return uCount;
}

static ULONG gmod_CountAchievementUnlocks()
{
    return 0;
}

static ULONG gmod_CalculateProgressSaveSize()
{
    // Start by assuming the string chunk and the fixed size inventory limit are always present
    ULONG uIndexCount = 2;
    ULONG uTotalSize = sizeof(GMF_Header);
    uTotalSize += Sys_Round4(sizeof(GMF_ChunkHeader) + sizeof(Inventory));

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


    return uTotalSize;
}

void GMod_SavePlayerProgress(void)
{
    dputs("GMod_SavePlayerProgress() is not yet implemented.");

    // First work out the required total buffer size:
    // 1. Basic Header
    // 2. Index Chunk with references to each chunk.
    // 3. Inventory Limis Chunk (fixed size)
    // 4. Weapon Adjustments Chunk (depends on number of defined adjustments)
    // 5. Unlocked Chunk.
    // 6. String Chunk
}

