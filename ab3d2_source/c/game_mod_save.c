#include <stdio.h>
#include "game_mod.h"
#include "devmode.h"
#include <proto/exec.h>
#include <dos/dos.h>
#include <proto/dos.h>
#include "system.h"
#include "game.h"

extern char const GMod_PropertiesFile[];
extern char const GMod_ProgressFile[];

static UWORD gmod_CountActiveAdjustments()
{
    UWORD uCount = 0;
    GMod_WeaponAdjustment const* pAdjustment = GMod_Progress.pprg_WeaponAdjustments;
    for (UWORD i = 0; i < NUM_GUN_DEFS; ++i) {
        if (pAdjustment[i].wadj_SlotID != 0xFFFF) {
            ++uCount;
        }
    }
    return uCount;
}

static UWORD gmod_CountAchievementUnlocks()
{
    UWORD uCount = 0;
    for (ULONG i = 0; i < GMod_Defaults.gmod_NumDefinedAchievements; ++i) {
        if (GMod_Progress.pprg_UnlockedPtr[i]) {
            ++uCount;
        }
    }
    return uCount;
}

/** Description for string chunk */
static char const sSaveDesc[8] = {
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

static UBYTE* gmod_MakeProgressHeader(UBYTE* bufferPtr)
{
    extern GMF_Header const gprg_Header;
    CopyMem(
        &gprg_Header,
        bufferPtr,
        sizeof(GMF_Header)
    );
    GMF_Header* headerPtr = (GMF_Header*)bufferPtr;

    // The version required is at least the version saved from.
    headerPtr->h_RequiresVersion = headerPtr->h_Version;
    headerPtr->h_Description.do_Offset = sizeof(GMF_ChunkHeader);
    return bufferPtr + sizeof(GMF_Header);
}

static UBYTE* gmod_MakeIndexChunk(UBYTE* bufferPtr, GMod_SaveInfo const* pSaveInfo)
{
    // We assume the index is immediately after the header
    GMF_ChunkHeader* headerPtr = (GMF_ChunkHeader*)bufferPtr;
    headerPtr->ch_Ident.id_Value = IDENT_INDX;
    headerPtr->ch_Length = pSaveInfo->uIndexChunkSize;
    GMF_IndexEntry* pIndex = (GMF_IndexEntry*)GMF_ChunkData(headerPtr);
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

    return bufferPtr + pSaveInfo->uIndexChunkSize;
}

static UBYTE* gmod_MakeInventoryLimitsChunk(UBYTE* bufferPtr, GMod_SaveInfo const* pSaveInfo)
{
    GMF_ChunkHeader* headerPtr = (GMF_ChunkHeader*)bufferPtr;
    headerPtr->ch_Ident.id_Value = IDENT_INVL;
    headerPtr->ch_Length = pSaveInfo->uInventoryLimitChunkSize;
    CopyMem(
        &GMod_Progress.pprg_InventoryLimits,
        GMF_ChunkData(headerPtr),
        sizeof(GMod_InventoryLimits)
    );
    return bufferPtr + pSaveInfo->uInventoryLimitChunkSize;
}

static UBYTE* gmod_MakeProgressCountersChunk(UBYTE* bufferPtr, GMod_SaveInfo const* pSaveInfo)
{
    GMF_ChunkHeader* headerPtr = (GMF_ChunkHeader*)bufferPtr;
    headerPtr->ch_Ident.id_Value = IDENT_CTRS;
    headerPtr->ch_Length = pSaveInfo->uProgressCountersChunkSize;
    CopyMem(
        &GMod_Progress.pprg_Counters,
        GMF_ChunkData(headerPtr),
        sizeof(GMod_ProgressCounters)
    );
    return bufferPtr + pSaveInfo->uProgressCountersChunkSize;
}

static UBYTE* gmod_MakeWeaponAdjustmentsChunk(UBYTE* bufferPtr, GMod_SaveInfo const* pSaveInfo)
{
    GMF_ChunkHeader* headerPtr = (GMF_ChunkHeader*)bufferPtr;
    headerPtr->ch_Ident.id_Value = IDENT_WADJ;
    headerPtr->ch_Length = pSaveInfo->uWeaponAdjustmentsChunkSize;
    GMod_WeaponAdjustment *pSave = (GMod_WeaponAdjustment*)GMF_ChunkData(headerPtr);
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
    return bufferPtr + pSaveInfo->uWeaponAdjustmentsChunkSize;
}

static UBYTE* gmod_MakeUnlocksChunk(UBYTE* bufferPtr, GMod_SaveInfo const* pSaveInfo)
{
    GMF_ChunkHeader* headerPtr = (GMF_ChunkHeader*)bufferPtr;
    headerPtr->ch_Ident.id_Value = IDENT_UNLK;
    headerPtr->ch_Length = pSaveInfo->uUnlocksChunkSize;
    GMod_Unlocked *pSave = (GMod_Unlocked*)GMF_ChunkData(headerPtr);
    for (ULONG i = 0; i < GMod_Defaults.gmod_NumDefinedAchievements; ++i) {
        if (GMod_Progress.pprg_UnlockedPtr[i]) {
            pSave->gpc_Awarded = GMod_Progress.pprg_UnlockedPtr[i];
            pSave->gpc_ID      = (UWORD)i;
            ++pSave;
        }
    }
    return bufferPtr + pSaveInfo->uUnlocksChunkSize;
}

static UBYTE* gmod_MakeStringChunk(UBYTE* bufferPtr, GMod_SaveInfo const* pSaveInfo)
{
    GMF_ChunkHeader* headerPtr = (GMF_ChunkHeader*)bufferPtr;
    headerPtr->ch_Ident.id_Value = IDENT_STRH;
    headerPtr->ch_Length = pSaveInfo->uStringChunkSize;
    CopyMem(
        sSaveDesc,
        GMF_ChunkData(headerPtr),
        sizeof(sSaveDesc)
    );
    return bufferPtr + pSaveInfo->uStringChunkSize;
}

void GMod_SavePlayerProgress(void)
{
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
    UBYTE* bufferPtr = gmod_MakeProgressHeader(pBufferBase);

    bufferPtr = gmod_MakeIndexChunk(bufferPtr, pSaveInfo);

    if (pSaveInfo->uInventoryLimitChunkSize) {
        bufferPtr = gmod_MakeInventoryLimitsChunk(bufferPtr, pSaveInfo);
    }

    if (pSaveInfo->uProgressCountersChunkSize) {
        bufferPtr = gmod_MakeProgressCountersChunk(bufferPtr, pSaveInfo);
    }

    if (pSaveInfo->uWeaponAdjustmentsChunkSize) {
        bufferPtr = gmod_MakeWeaponAdjustmentsChunk(bufferPtr, pSaveInfo);
    }

    if (pSaveInfo->uNumUnlocks) {
        bufferPtr = gmod_MakeUnlocksChunk(bufferPtr, pSaveInfo);
    }

    if (pSaveInfo->uStringChunkSize) {
        bufferPtr = gmod_MakeStringChunk(bufferPtr, pSaveInfo);
    }

    BPTR gameProgressFH = Open(GMod_ProgressFile, MODE_NEWFILE);
    if (DOSFALSE != gameProgressFH) {
        Write(gameProgressFH, pBufferBase, pSaveInfo->uTotalSize);
        Close(gameProgressFH);
    }

    FreeVec(pBufferBase);
}


