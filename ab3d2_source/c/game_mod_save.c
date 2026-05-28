#include <stdio.h>
#include "game_mod.h"
#include "devmode.h"
#include <proto/exec.h>
#include <dos/dos.h>
#include <proto/dos.h>
#include "system.h"
#include "game.h"

static UWORD gmod_CountActiveAdjustments()
{
    UWORD uCount = 0;
    GMod_WeaponAdjustment const* pAdjustment = GMod_Progress.pprg_WeaponAdjustments;
    for (UWORD i = 0; i < NUM_GUN_DEFS; ++i) {
        if (pAdjustment[i].wadj_SlotID != 0xFFFF) {
            ++uCount;
        }
    }
    dprintf("\tGot %u Weapon Adjustments\n", (unsigned)uCount);
    return uCount;
}

static UWORD gmod_CountAchievementUnlocks()
{
    UWORD uCount = 0;
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


typedef struct {
    ULONG uTotalSize;
    ULONG uIndexChunkSize;
    ULONG uInventoryLimitChunkSize;
    ULONG uProgressCountersChunkSize;
    ULONG uWeaponAdjustmentsChunkSize;
    ULONG uUnlocksChunkSize;
    ULONG uStringChunkSize;
    UWORD uIndexCount;
    UWORD uNumWeaponAdjustments;
    UWORD uNumUnlocks;
} GMod_SaveInfo;

/**
 * Calculates the required allocation buffer size.
 */
static void gmod_CalculateProgressSaveSize(GMod_SaveInfo* restrict pSaveInfo)
{
    // Start by assuming the string, limits, counters are all present
    pSaveInfo->uIndexCount = 3;
    pSaveInfo->uInventoryLimitChunkSize   = Sys_Round4(sizeof(GMF_ChunkHeader) + sizeof(GMod_InventoryLimits));
    pSaveInfo->uProgressCountersChunkSize = Sys_Round4(sizeof(GMF_ChunkHeader) + sizeof(GMod_ProgressCounters));
    pSaveInfo->uStringChunkSize           = Sys_Round4(sizeof(GMF_ChunkHeader) + sizeof(sSaveDesc));

    pSaveInfo->uTotalSize = sizeof(GMF_Header) +
        pSaveInfo->uInventoryLimitChunkSize +
        pSaveInfo->uProgressCountersChunkSize +
        pSaveInfo->uStringChunkSize;


    // Only include the weapon adjustment chunk if there are any
    pSaveInfo->uNumWeaponAdjustments = gmod_CountActiveAdjustments();
    if (pSaveInfo->uNumWeaponAdjustments) {
        pSaveInfo->uWeaponAdjustmentsChunkSize = Sys_Round4(sizeof(GMF_ChunkHeader) + (pSaveInfo->uNumWeaponAdjustments * sizeof(GMod_WeaponAdjustment)));
        pSaveInfo->uTotalSize += pSaveInfo->uWeaponAdjustmentsChunkSize;
        ++pSaveInfo->uIndexCount;
    } else {
        pSaveInfo->uWeaponAdjustmentsChunkSize = 0;
    }

    // Only include the unlock chunk if there are any
    pSaveInfo->uNumUnlocks = gmod_CountAchievementUnlocks();
    if (pSaveInfo->uNumUnlocks) {
        pSaveInfo->uUnlocksChunkSize = Sys_Round4(sizeof(GMF_ChunkHeader) + (pSaveInfo->uNumUnlocks * sizeof(GMod_Unlocked)));
        pSaveInfo->uTotalSize += pSaveInfo->uUnlocksChunkSize;
        ++pSaveInfo->uIndexCount;
    } else {
        pSaveInfo->uUnlocksChunkSize = 0;
    }

    // Add the size of the index chunk
    pSaveInfo->uIndexChunkSize = Sys_Round4(sizeof(GMF_ChunkHeader) + pSaveInfo->uIndexCount * sizeof(GMF_IndexEntry));
    pSaveInfo->uTotalSize += pSaveInfo->uIndexChunkSize;
}

static UBYTE* gmod_makeProgressHeader(UBYTE* pBuffer)
{
    extern GMF_Header const gprg_Header;
    CopyMem(
        &gprg_Header,
        pBuffer,
        sizeof(GMF_Header)
    );
    GMF_Header* pHeader = (GMF_Header*)pBuffer;
    pHeader->h_Description.do_Offset = sizeof(GMF_ChunkHeader);
    return pBuffer + sizeof(GMF_Header);
}

static UBYTE* gmod_MakeIndexChunk(UBYTE* pBuffer, GMod_SaveInfo const* pSaveInfo)
{
    // We assume the index is immediately after the header
    GMF_ChunkHeader* pHeader = (GMF_ChunkHeader*)pBuffer;
    pHeader->ch_Ident.id_Value = IDENT_INDX;
    pHeader->ch_Length = pSaveInfo->uIndexChunkSize;
    GMF_IndexEntry* pIndex = (GMF_IndexEntry*)GMF_ChunkData(pHeader);
    ULONG uOffset = sizeof(GMF_Header) + pSaveInfo->uIndexChunkSize;
    if (pSaveInfo->uInventoryLimitChunkSize) {
        pIndex->ie_Ident.id_Value = IDENT_INVL;
        pIndex->ie_Offset.do_Offset = uOffset;
        uOffset += pSaveInfo->uInventoryLimitChunkSize;
        ++pIndex;
    }
    if (pSaveInfo->uProgressCountersChunkSize) {
        pIndex->ie_Ident.id_Value = IDENT_CTRS;
        pIndex->ie_Offset.do_Offset = uOffset;
        uOffset += pSaveInfo->uProgressCountersChunkSize;
        ++pIndex;
    }
    if (pSaveInfo->uWeaponAdjustmentsChunkSize) {
        pIndex->ie_Ident.id_Value = IDENT_WADJ;
        pIndex->ie_Offset.do_Offset = uOffset;
        uOffset += pSaveInfo->uWeaponAdjustmentsChunkSize;
        ++pIndex;
    }
    if (pSaveInfo->uUnlocksChunkSize) {
        pIndex->ie_Ident.id_Value = IDENT_UNLK;
        pIndex->ie_Offset.do_Offset = uOffset;
        uOffset += pSaveInfo->uUnlocksChunkSize;
        ++pIndex;
    }
    if (pSaveInfo->uStringChunkSize) {
        pIndex->ie_Ident.id_Value = IDENT_STRH;
        pIndex->ie_Offset.do_Offset = uOffset;
        uOffset += pSaveInfo->uStringChunkSize;
        ++pIndex;
    }

    dprintf(
        "expected size %u, computed size %u\n",
        pSaveInfo->uTotalSize,
        uOffset
    );

    return pBuffer + pSaveInfo->uIndexChunkSize;
}

static UBYTE* gmod_MakeInventoryLimitsChunk(UBYTE* pBuffer, GMod_SaveInfo const* pSaveInfo)
{
    GMF_ChunkHeader* pHeader = (GMF_ChunkHeader*)pBuffer;
    pHeader->ch_Ident.id_Value = IDENT_INVL;
    pHeader->ch_Length = pSaveInfo->uInventoryLimitChunkSize;
    CopyMem(
        &GMod_Progress.pprg_InventoryLimits,
        GMF_ChunkData(pHeader),
        sizeof(GMod_InventoryLimits)
    );
    return pBuffer + pSaveInfo->uInventoryLimitChunkSize;
}

static UBYTE* gmod_MakeProgressCountersChunk(UBYTE* pBuffer, GMod_SaveInfo const* pSaveInfo)
{
    GMF_ChunkHeader* pHeader = (GMF_ChunkHeader*)pBuffer;
    pHeader->ch_Ident.id_Value = IDENT_CTRS;
    pHeader->ch_Length = pSaveInfo->uProgressCountersChunkSize;
    CopyMem(
        &GMod_Progress.pprg_Counters,
        GMF_ChunkData(pHeader),
        sizeof(GMod_ProgressCounters)
    );
    return pBuffer + pSaveInfo->uProgressCountersChunkSize;
}

static UBYTE* gmod_MakeWeaponAdjustmentsChunk(UBYTE* pBuffer, GMod_SaveInfo const* pSaveInfo)
{
    GMF_ChunkHeader* pHeader = (GMF_ChunkHeader*)pBuffer;
    pHeader->ch_Ident.id_Value = IDENT_WADJ;
    pHeader->ch_Length = pSaveInfo->uWeaponAdjustmentsChunkSize;
    GMod_WeaponAdjustment *pSave = (GMod_WeaponAdjustment*)GMF_ChunkData(pHeader);
    GMod_WeaponAdjustment const* pAdjustment = GMod_Progress.pprg_WeaponAdjustments;
    for (UWORD i=0; i < NUM_GUN_DEFS; ++i) {
        if (pAdjustment[i].wadj_SlotID != 0xFFFF) {
            CopyMem(
                &pAdjustment[i],
                pSave,
                sizeof(GMod_WeaponAdjustment)
            );
            ++pSave;
        }
    }
    return pBuffer + pSaveInfo->uWeaponAdjustmentsChunkSize;
}

static UBYTE* gmod_MakeUnlocksChunk(UBYTE* pBuffer, GMod_SaveInfo const* pSaveInfo)
{
    GMF_ChunkHeader* pHeader = (GMF_ChunkHeader*)pBuffer;
    pHeader->ch_Ident.id_Value = IDENT_UNLK;
    pHeader->ch_Length = pSaveInfo->uUnlocksChunkSize;
    GMod_Unlocked *pSave = (GMod_Unlocked*)GMF_ChunkData(pHeader);
    for (ULONG i = 0; i < GMod_Defaults.gmod_NumDefinedAchievements; ++i) {
        if (GMod_Progress.pprg_Unlocked[i]) {
            pSave->gpc_Awarded = GMod_Progress.pprg_Unlocked[i];
            pSave->gpc_ID      = (UWORD)i;
            ++pSave;
        }
    }
    return pBuffer + pSaveInfo->uUnlocksChunkSize;
}

static UBYTE* gmod_MakeStringChunk(UBYTE* pBuffer, GMod_SaveInfo const* pSaveInfo)
{
    GMF_ChunkHeader* pHeader = (GMF_ChunkHeader*)pBuffer;
    pHeader->ch_Ident.id_Value = IDENT_STRH;
    pHeader->ch_Length = pSaveInfo->uStringChunkSize;
    CopyMem(
        sSaveDesc,
        GMF_ChunkData(pHeader),
        sizeof(sSaveDesc)
    );
    return pBuffer + pSaveInfo->uStringChunkSize;
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

    GMod_SaveInfo* pSaveInfo = (GMod_SaveInfo*)Sys_GetTemporaryWorkspace();

    gmod_CalculateProgressSaveSize(pSaveInfo);

//     dprintf(
//         "uTotalSize %u\n"
//         "uIndexChunkSize %u\n"
//         "uInventoryLimitChunkSize %u\n"
//         "uProgressCountersChunkSize %u\n"
//         "uWeaponAdjustmentsChunkSize %u\n"
//         "uUnlocksChunkSize %u\n"
//         "uStringChunkSize %u\n"
//         "uIndexCount %u\n"
//         "uNumWeaponAdjustments %u\n"
//         "uNumUnlocks %u\n",
//         (unsigned)pSaveInfo->uTotalSize,
//         (unsigned)pSaveInfo->uIndexChunkSize,
//         (unsigned)pSaveInfo->uInventoryLimitChunkSize,
//         (unsigned)pSaveInfo->uProgressCountersChunkSize,
//         (unsigned)pSaveInfo->uWeaponAdjustmentsChunkSize,
//         (unsigned)pSaveInfo->uUnlocksChunkSize,
//         (unsigned)pSaveInfo->uStringChunkSize,
//         (unsigned)pSaveInfo->uIndexCount,
//         (unsigned)pSaveInfo->uNumWeaponAdjustments,
//         (unsigned)pSaveInfo->uNumUnlocks
//     );

    UBYTE* pBufferBase = (UBYTE*)AllocVec(pSaveInfo->uTotalSize, MEMF_ANY|MEMF_CLEAR);

    if (!pBufferBase) {
        dprintf("Couldn't allocate %u bytes for progress save buffer\n", pSaveInfo->uTotalSize);
        return;
    }

    // Add the header.
    UBYTE* pBuffer = gmod_makeProgressHeader(pBufferBase);

    pBuffer = gmod_MakeIndexChunk(pBuffer, pSaveInfo);

    if (pSaveInfo->uInventoryLimitChunkSize) {
        pBuffer = gmod_MakeInventoryLimitsChunk(pBuffer, pSaveInfo);
    }

    if (pSaveInfo->uProgressCountersChunkSize) {
        pBuffer = gmod_MakeProgressCountersChunk(pBuffer, pSaveInfo);
    }

    if (pSaveInfo->uWeaponAdjustmentsChunkSize) {
        pBuffer = gmod_MakeWeaponAdjustmentsChunk(pBuffer, pSaveInfo);
    }

    if (pSaveInfo->uNumUnlocks) {
        pBuffer = gmod_MakeUnlocksChunk(pBuffer, pSaveInfo);
    }

    if (pSaveInfo->uStringChunkSize) {
        pBuffer = gmod_MakeStringChunk(pBuffer, pSaveInfo);
    }

    BPTR gameProgressFH = Open("ab3:progress.save.stats", MODE_NEWFILE);
    if (DOSFALSE != gameProgressFH) {
        Write(gameProgressFH, pBufferBase, pSaveInfo->uTotalSize);
        Close(gameProgressFH);
    }

    FreeVec(pBufferBase);
}


