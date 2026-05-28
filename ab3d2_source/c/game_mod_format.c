#include <stdio.h>
#include "game_mod_format.h"
#include "devmode.h"
#include <dos/dos.h>
#include <proto/dos.h>
#include <proto/exec.h>

extern struct FileInfoBlock io_FileInfoBlock;

/**
 * Minimum viable size for a modification file size:
 * Header plus the smallest possible chunk.
 */
#define MIN_GMF_SIZE (sizeof(GMF_Header) + sizeof(GMF_ChunkHeader) + sizeof(ULONG))

/**
 * gmf_CheckData()
 *
 * Basic valiation for Game Modification Files based on expected header properties.
 */
static BOOL gmf_CheckData(
    GMF_Data* pGMFData,
    GMF_Header const* pAgainst
) {
    //dputs("\tgmf_CheckData()");

    if (!pGMFData || !pAgainst || !pGMFData->gmd_Data) {
        return FALSE;
    }
    GMF_Header const* pFrom = (GMF_Header const*)pGMFData->gmd_Data;

    return
        pAgainst->h_Ident.id_Value     == pFrom->h_Ident.id_Value &&
        pAgainst->h_SubFormat.id_Value == pFrom->h_SubFormat.id_Value &&
        pAgainst->h_Version.v_Major    == pFrom->h_RequiresVersion.v_Major &&
        pAgainst->h_Version.v_Minor    >= pFrom->h_RequiresVersion.v_Minor &&
        pFrom->h_Description.do_Offset >= sizeof(GMF_ChunkHeader);
}

/**
 * gmf_ReadFile()
 *
 * Attempts to load the named file, populating the data and length fields of the GMF_Data and zeroing the rest.
 * Once loaded, the data must be validated.
 */
static BOOL gmf_ReadFile(
    char const* filename,
    GMF_Data* pGMFData
) {
    BPTR    hGamePropsFH = DOSFALSE;
    BOOL    bResult = FALSE;

    dputs("\tgmf_ReadFile()");

    do {
        if (!filename || !pGMFData) {
            dprintf("Invalid parameters %s %p\n", filename, pGMFData);
            break;
        }

        hGamePropsFH = Open(filename, MODE_OLDFILE);
        if (DOSFALSE == hGamePropsFH) {
            dprintf("Unable to open %s for reading\n", filename);
            break;
        }

        ExamineFH(hGamePropsFH, &io_FileInfoBlock);
        if (
            io_FileInfoBlock.fib_DirEntryType >= 0 ||
            io_FileInfoBlock.fib_Size < (LONG)MIN_GMF_SIZE
        ) {
            dprintf("Invalid modification file %s\n", filename);
            break;
        }

        LONG iLength = io_FileInfoBlock.fib_Size;
        UBYTE* pBuffer = (UBYTE*)AllocVec(iLength, MEMF_ANY|MEMF_CLEAR);
        if (!pBuffer) {
            dprintf("Couldn't allocate %d bytes for file %s data\n", iLength, filename);
            break;
        }

        LONG iRead = Read(hGamePropsFH, pBuffer, iLength);
        if (iRead != iLength) {
            dprintf("Incorrect length read, %d bytes instead of %d for file %s data\n", iRead, iLength, filename);
            FreeVec(pBuffer);
            break;
        }

        pGMFData->gmd_Data      = pBuffer;
        pGMFData->gmd_Length    = iLength;
        pGMFData->gmd_Header    = NULL;
        pGMFData->gmd_Index     = NULL;
        pGMFData->gmd_IndexSize = 0;
        pGMFData->gmd_Strings   = NULL;
        bResult = TRUE;
        dputs("\tSuccess");

    } while (FALSE);

    if (hGamePropsFH != DOSFALSE) {
        Close(hGamePropsFH);
    }
    return bResult;
}

/**
 * gmf_ProcessDefaultChunks()
 *
 * Handles parsing the default chunks common to all Game Modification Format files, i.e. the Index and String
 * chunks.
 */
static BOOL gmf_ProcessDefaultChunks(GMF_Data* pGMFData)
{
    dputs("\tgmf_ProcessDefaultChunks()");
    GMF_ChunkHeader const* pIndexHeader = (GMF_ChunkHeader const*)(pGMFData->gmd_Data + sizeof(GMF_Header));
    if (
        pIndexHeader->ch_Ident.id_Value != IDENT_INDX ||
        pIndexHeader->ch_Length < (sizeof(GMF_ChunkHeader) + sizeof(GMF_IndexEntry))
    ) {
        return FALSE;
    }
    int iNumEntries = (pIndexHeader->ch_Length - sizeof(GMF_ChunkHeader))/sizeof(GMF_IndexEntry);

    GMF_IndexEntry* pIndexEntry = (GMF_IndexEntry*)(((UBYTE*)pIndexHeader) + sizeof(GMF_ChunkHeader));
    pGMFData->gmd_IndexSize = iNumEntries;
    pGMFData->gmd_Index     = pIndexEntry;
    pGMFData->gmd_Strings   = NULL;

    /**
     * Convert the offsets in the index to their actual addresses
     */
    for (int i = 0; i < iNumEntries; ++i) {
        pIndexEntry[i].ie_Offset.do_ByteAddress = pGMFData->gmd_Data + pIndexEntry[i].ie_Offset.do_Offset;

        /* Quick sanity check - ensure the index ident is a match for the in memory location */
        GMF_Ident const* pChunkIdent = (GMF_Ident const*)pIndexEntry[i].ie_Offset.do_ByteAddress;
        if (pIndexEntry[i].ie_Ident.id_Value != pChunkIdent->id_Value) {
            dprintf(
                "Index entry %d ident mismatch. Index: %.*s => Chunk: %.*s\n",
                i,
                4, pIndexEntry[i].ie_Ident.id_Text,
                4, pChunkIdent->id_Text
            );
            return FALSE;
        }

        if (pIndexEntry[i].ie_Ident.id_Value == IDENT_STRH) {
            pGMFData->gmd_Strings = pIndexEntry[i].ie_Offset.do_Text;
        }
    }

    if (!pGMFData->gmd_Strings) {
        dprintf("String Heap not found in Index\n");
        return FALSE;
    }

    /* Patch the description locaton */
    GMF_Header* pHeader = (GMF_Header*)pGMFData->gmd_Data;
    pHeader->h_Description.do_Text = pGMFData->gmd_Strings + pHeader->h_Description.do_Offset;
    pGMFData->gmd_Header = pHeader;
    return TRUE;
}

/**
 * GMF_LocateChunk()
 *
 * Returns the first encountered instance of a chunk with the supplied index. It is assumed that a game modification
 * file only contains one of each chunk type.
 */
GMF_ChunkHeader const* GMF_LocateChunk(
    GMF_Data const* pGMFData,
    ULONG iIdentValue
) {
    //dprintf("GMF_LocateChunk(%p, 0x%08X) [Index Size %u]\n", pGMFData, iIdentValue, (int)pGMFData->gmd_IndexSize);
    for (ULONG i = 0; i < pGMFData->gmd_IndexSize; ++i) {

        //dprintf("\t%u: 0x%08X\n", i, pGMFData->gmd_Index[i].ie_Ident.id_Value);

        if (pGMFData->gmd_Index[i].ie_Ident.id_Value == iIdentValue) {
            //dputs("\tMatched!");
            return (GMF_ChunkHeader const *)pGMFData->gmd_Index[i].ie_Offset.do_ByteAddress;
        }
    }
    //dputs("\tNo matches.");
    return NULL;
}

/**
 * GMF_LoadFile()
 *
 * Attempts to load the specified Game Modification File and process with a null terminated list of user supplied
 * parsers for any custom chunk types that are present.
 */
GMF_Data* GMF_LoadFile(
    char const* filename,
    GMF_Header const* pCheckHeader,
    GMF_ParserEntry const* pCustomParsers
) {
    dputs("GMF_LoadFile()");

    GMF_Data* pGMFData = NULL;
    do {
        if (!filename || !pCheckHeader) {
            dprintf("Invalid parameters %p %p\n", filename, pCheckHeader);
            break;
        }
        pGMFData = (GMF_Data*)AllocVec(sizeof(GMF_Data), MEMF_ANY|MEMF_CLEAR);
        if (!pGMFData) {
            break;
        }
        if (
            !gmf_ReadFile(filename, pGMFData) ||
            !gmf_CheckData(pGMFData, pCheckHeader) ||
            !gmf_ProcessDefaultChunks(pGMFData)
        ) {
            FreeVec(pGMFData);
            pGMFData = NULL;
            break;
        }

        if (pCustomParsers) {
            GMF_ChunkHeader const* pChunkHeader = NULL;
            while (
                pCustomParsers->pe_Ident &&
                pCustomParsers->pe_Parser
            ) {
                if ( (pChunkHeader = GMF_LocateChunk(pGMFData, pCustomParsers->pe_Ident)) ) {
                    pCustomParsers->pe_Parser(pChunkHeader, pGMFData);
                }
                ++pCustomParsers;
            }
        }
    } while (FALSE);

    return pGMFData;
}

/**
 * GMF_Free()
 *
 * Releases a GMF_Data instance and any associated data.
 */
void GMF_Free(GMF_Data const* pGMFData)
{
    dputs("GMF_Free()");
    if (pGMFData) {
        if (pGMFData->gmd_Data) {
            FreeVec(pGMFData->gmd_Data);
        }
        FreeVec((void*)pGMFData);
    }
}
