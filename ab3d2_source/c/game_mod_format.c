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
    GMF_Data* GMFDataPtr,
    GMF_Header const* referenceHeaderPtr
) {
    if (!GMFDataPtr || !referenceHeaderPtr || !GMFDataPtr->gmd_DataPtr) {
        return FALSE;
    }
    GMF_Header const* pFrom = (GMF_Header const*)GMFDataPtr->gmd_DataPtr;
    return
        referenceHeaderPtr->h_Ident.id_Value     == pFrom->h_Ident.id_Value &&
        referenceHeaderPtr->h_SubFormat.id_Value == pFrom->h_SubFormat.id_Value &&
        referenceHeaderPtr->h_Version.v_Major    == pFrom->h_RequiresVersion.v_Major &&
        referenceHeaderPtr->h_Version.v_Minor    >= pFrom->h_RequiresVersion.v_Minor &&
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
    GMF_Data* GMFDataPtr
) {
    BPTR    hGamePropsFH = DOSFALSE;
    BOOL    bResult = FALSE;
    do {
        if (!filename || !GMFDataPtr) {
            dprintf("Invalid parameters %s %p\n", filename, GMFDataPtr);
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
        UBYTE* bufferPtr = (UBYTE*)AllocVec(iLength, MEMF_ANY|MEMF_CLEAR);
        if (!bufferPtr) {
            dprintf("Couldn't allocate %d bytes for file %s data\n", iLength, filename);
            break;
        }

        LONG iRead = Read(hGamePropsFH, bufferPtr, iLength);
        if (iRead != iLength) {
            dprintf("Incorrect length read, %d bytes instead of %d for file %s data\n", iRead, iLength, filename);
            FreeVec(bufferPtr);
            break;
        }

        GMFDataPtr->gmd_DataPtr    = bufferPtr;
        GMFDataPtr->gmd_Length     = iLength;
        GMFDataPtr->gmd_HeaderPtr  = NULL;
        GMFDataPtr->gmd_IndexPtr   = NULL;
        GMFDataPtr->gmd_IndexSize  = 0;
        GMFDataPtr->gmd_StringsPtr = NULL;
        bResult = TRUE;
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
static BOOL gmf_ProcessDefaultChunks(GMF_Data* GMFDataPtr)
{
    GMF_ChunkHeader const* pIndexHeader = (GMF_ChunkHeader const*)(GMFDataPtr->gmd_DataPtr + sizeof(GMF_Header));
    if (
        pIndexHeader->ch_Ident.id_Value != IDENT_INDX ||
        pIndexHeader->ch_Length < (sizeof(GMF_ChunkHeader) + sizeof(GMF_IndexEntry))
    ) {
        return FALSE;
    }
    int iNumEntries = (pIndexHeader->ch_Length - sizeof(GMF_ChunkHeader))/sizeof(GMF_IndexEntry);

    GMF_IndexEntry* pIndexEntry = (GMF_IndexEntry*)(((UBYTE*)pIndexHeader) + sizeof(GMF_ChunkHeader));
    GMFDataPtr->gmd_IndexSize   = iNumEntries;
    GMFDataPtr->gmd_IndexPtr    = pIndexEntry;
    GMFDataPtr->gmd_StringsPtr  = NULL;

    /**
     * Convert the offsets in the index to their actual addresses
     */
    for (int i = 0; i < iNumEntries; ++i) {
        pIndexEntry[i].ie_Offset.do_BytePtr = GMFDataPtr->gmd_DataPtr + pIndexEntry[i].ie_Offset.do_Offset;

        /* Quick sanity check - ensure the index ident is a match for the in memory location */
        GMF_Ident const* pChunkIdent = (GMF_Ident const*)pIndexEntry[i].ie_Offset.do_BytePtr;
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
            GMFDataPtr->gmd_StringsPtr = pIndexEntry[i].ie_Offset.do_TextPtr;
        }
    }

    if (!GMFDataPtr->gmd_StringsPtr) {
        dprintf("String Heap not found in Index\n");
        return FALSE;
    }

    /* Patch the description locaton */
    GMF_Header* headerPtr = (GMF_Header*)GMFDataPtr->gmd_DataPtr;
    headerPtr->h_Description.do_TextPtr = GMFDataPtr->gmd_StringsPtr + headerPtr->h_Description.do_Offset;
    GMFDataPtr->gmd_HeaderPtr = headerPtr;
    return TRUE;
}

/**
 * GMF_LocateChunk()
 *
 * Returns the first encountered instance of a chunk with the supplied index. It is assumed that a game modification
 * file only contains one of each chunk type.
 */
GMF_ChunkHeader const* GMF_LocateChunk(
    GMF_Data const* GMFDataPtr,
    ULONG iIdentValue
) {
    //dprintf("GMF_LocateChunk(%p, 0x%08X) [Index Size %u]\n", GMFDataPtr, iIdentValue, (int)GMFDataPtr->gmd_IndexSize);
    for (ULONG i = 0; i < GMFDataPtr->gmd_IndexSize; ++i) {
        if (GMFDataPtr->gmd_IndexPtr[i].ie_Ident.id_Value == iIdentValue) {
            return (GMF_ChunkHeader const *)GMFDataPtr->gmd_IndexPtr[i].ie_Offset.do_BytePtr;
        }
    }
    dprintf("GMF_LocateChunk() Failed to load chunk ident 0x%08X\n", iIdentValue);
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
    GMF_Header const* referenceHeaderPtr,
    GMF_ParserEntry const* customParserListPtr
) {
    GMF_Data* GMFDataPtr = NULL;
    do {
        if (!filename || !referenceHeaderPtr) {
            dprintf("Invalid parameters %p %p\n", filename, referenceHeaderPtr);
            break;
        }
        GMFDataPtr = (GMF_Data*)AllocVec(sizeof(GMF_Data), MEMF_ANY|MEMF_CLEAR);
        if (!GMFDataPtr) {
            dprintf("Failed to allocate %u bytes of memory for GMF_Data\n", sizeof(GMF_Data));
            break;
        }
        if (
            !gmf_ReadFile(filename, GMFDataPtr) ||
            !gmf_CheckData(GMFDataPtr, referenceHeaderPtr) ||
            !gmf_ProcessDefaultChunks(GMFDataPtr)
        ) {
            FreeVec(GMFDataPtr);
            GMFDataPtr = NULL;
            break;
        }

        if (customParserListPtr) {
            GMF_ChunkHeader const* chunkHeaderPtr = NULL;
            while (
                customParserListPtr->pe_Ident &&
                customParserListPtr->pe_Parser
            ) {
                if ( (chunkHeaderPtr = GMF_LocateChunk(GMFDataPtr, customParserListPtr->pe_Ident)) ) {
                    customParserListPtr->pe_Parser(chunkHeaderPtr, GMFDataPtr);
                }
                ++customParserListPtr;
            }
        }
    } while (FALSE);

    return GMFDataPtr;
}

/**
 * GMF_Free()
 *
 * Releases a GMF_Data instance and any associated data.
 */
void GMF_Free(GMF_Data const* GMFDataPtr)
{
    if (GMFDataPtr) {
        if (GMFDataPtr->gmd_DataPtr) {
            FreeVec(GMFDataPtr->gmd_DataPtr);
        }
        FreeVec((void*)GMFDataPtr);
    }
}
