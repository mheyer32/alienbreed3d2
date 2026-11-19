#ifndef _TKG_GMF_H_
#   define _TKG_GMF_H_

/**
 * This header defines the structures and base methods for loading and decoding the game modification files:
 *
 * - Main Game Modification (GMOD)
 * - Level Modification (LMOD)
 * - Progression (GPRG)
 */
#include "defs.h"
#include <stddef.h>
/**
 * Standard Ident values
 */
enum {
    IDENT_TKGD = 0x544b4744,    // Main header Ident
    IDENT_GMOD = 0x474d4f44,    // Subformat Game Modification Data
    IDENT_LMOD = 0x4C4D4F44,    // Subformat Level Modification Data
    IDENT_GPRG = 0x47505247,    // Subformat Progression Data
    IDENT_INDX = 0x494e4458,    // Index Chunk
    IDENT_STRH = 0x53545248,    // String Chunk
};

/**
 * GMF_DataOffset
 *
 * Represents an offset in the file that is to be resolved to an actual address during parsing.
 */
typedef union {
    ULONG       do_Offset;
    char const* do_TextPtr;
    UBYTE*      do_BytePtr;
} ASM_ALIGN(sizeof(ULONG)) GMF_DataOffset;

/**
 * GMF_Version
 *
 * Basic major.minor version tuple used for version checks.
 */
typedef struct {
    UWORD       v_Major;
    UWORD       v_Minor;
} ASM_ALIGN(sizeof(ULONG)) GMF_Version;

/**
 * GMF_Ident
 *
 * Basic 4-byte ident. Accessible either as a 32-bit word or as 4 characters. Big endian layout.
 */
typedef union {
    char  id_Text[4];
    ULONG id_Value;
} ASM_ALIGN(sizeof(ULONG)) GMF_Ident;

/**
 * GMF_Header
 *
 * Main game modification file header.
 */
typedef struct {
    GMF_Ident      h_Ident;
    GMF_Ident      h_SubFormat;
    GMF_Version    h_RequiresVersion;
    GMF_Version    h_Version;
    GMF_DataOffset h_Description;
} ASM_ALIGN(sizeof(ULONG)) GMF_Header;

/**
 * GMF_ChunkHeader
 *
 * Minimalist header for each Chunk.
 */
typedef struct {
    GMF_Ident ch_Ident;
    ULONG     ch_Length;
} ASM_ALIGN(sizeof(ULONG)) GMF_ChunkHeader;

/**
 * GMF_IndexEntry
 *
 * Basic Ident/Offset pair for the common Index chunk.
 */
typedef struct {
    GMF_Ident      ie_Ident;
    GMF_DataOffset ie_Offset;
} ASM_ALIGN(sizeof(ULONG)) GMF_IndexEntry;

/**
 * GMF_Data
 *
 * Main structure for loaded Game Modification Files.
 */
typedef struct {
    UBYTE*                gmd_DataPtr;
    ULONG                 gmd_Length;
    ULONG                 gmd_IndexSize;
    GMF_Header const*     gmd_HeaderPtr;
    GMF_IndexEntry const* gmd_IndexPtr;
    char const*           gmd_StringsPtr;
} ASM_ALIGN(sizeof(ULONG)) GMF_Data;


/**
 * GMF_ChunkParser
 *
 * Callable type for parsing chunks after loading.
 */
typedef BOOL (*GMF_ChunkParser)(GMF_ChunkHeader const* chunkHeaderPtr, GMF_Data* GMFDataPtr);

/**
 * GMF_ParserEntry
 *
 * Basic Ident/Parser pair for associating a parser to a particular chunk type.
 */
typedef struct {
    ULONG           pe_Ident;
    GMF_ChunkParser pe_Parser;
} ASM_ALIGN(sizeof(ULONG)) GMF_ParserEntry;


/**
 * GMF_ResolveString()
 *
 * For a given initial string reference, resolves an offset to the actual in-memory location within the common
 * string chunk.
 */
inline const char* GMF_ResolveString(char const* string, GMF_Data const* GMFDataPtr)
{
    return (string < GMFDataPtr->gmd_StringsPtr) ? GMFDataPtr->gmd_StringsPtr + (size_t)string : string;
}

/**
 * GMF_ChunkData()
 *
 * Returns the start of the chunk body data for a given header. This is simply the data immediately following.
 * Assumes the returned data requires modification.
 */
inline void* GMF_ChunkData(GMF_ChunkHeader const* headerPtr)
{
    return ((UBYTE*)headerPtr) + sizeof(GMF_ChunkHeader);
}

/**
 * GMF_LocateChunk()
 *
 * Returns the first encountered instance of a chunk with the supplied index. It is assumed that a game modification
 * file only contains one of each chunk type.
 */
extern GMF_ChunkHeader const* GMF_LocateChunk(GMF_Data const* GMFDataPtr, ULONG iIdentValue);

/**
 * GMF_LoadFile()
 *
 * Attempts to load the specified Game Modification File and process with a null terminated list of user supplied
 * parsers for any custom chunk types that are present.
 */
extern GMF_Data* GMF_LoadFile(
    char const*            filename,
    GMF_Header const*      referenceHeaderPtr,
    GMF_ParserEntry const* customParserListPtr
);

/**
 * GMF_Free()
 *
 * Releases a GMF_Data instance and any associated data.
 */
extern void GMF_Free(GMF_Data const* GMFDataPtr);

/**
 * Quick and dirty macro to get the count of fixed size records from a chunk
 */
#define GMF_ChunkRecordCount(chunkPtr, type) (ULONG)((chunkPtr->ch_Length - sizeof(GMF_ChunkHeader))/sizeof(type))

#endif /* _TKG_GMF_H_ */
