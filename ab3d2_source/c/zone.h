#ifndef ZONE_H
#define ZONE_H

//#define DEBUG_ZONE_ERRATA

#if defined(ZONE_DEBUG)
    #define dputchar(c) putchar(c)
    #define dputs(msg) puts(msg)
    #define dprintf(fmt, ...) printf(fmt, ## __VA_ARGS__)
#else
    #define dputchar(c)
    #define dputs(msg)
    #define dprintf()
#endif

/**
 * @see defs.i
 *
 *
 * z_EdgeListOffset is a negative address offset preceding the structure instance. This is a list of words
 * representing edge definitions. The list contains each enumerated wall, followed by a -1 terminator.
 * Following that is what appears to be another list of walls of that share edges, terminated by -2.
 *
 * The end of the structure is a -1 terminated list of zone ID of the potentially visible set of zones
 * that could be visible from the current zone.
 *
 * These structures may have some long aligned data penalties.
 */

enum {
    ZONE_ID_LIST_END       = -1,
    ZONE_ID_REMOVED_MANUAL = -2,
    ZONE_ID_REMOVED_AUTO   = -3,
};

#define PVS_TRAVERSE_LIMIT 100
#define EDGE_TRAVERSE_LIMIT 16

/**
 * This structure contains information about a potentially visible zone. A list of these
 * is appended to each Zone structure in the loaded data. The final record has pvs_ZoneID
 * set to -1.
 *
 * TODO - we ideally need to tag in here somewhere a flag that represents the visibility
 * based on the current edge determination.
 */
typedef struct {
    WORD pvs_ZoneID;
    WORD pvs_SortVal;
    WORD pvs_Word2; // TODO figure out what this is
    WORD pvs_Word3; // TODO figure out what this is
} __attribute__((packed)) __attribute__ ((aligned (2))) ZPVSRecord;

/**
 * Edge structure. These are stored in a large array loaded from disk and are referenced by
 * ID. Each Zone structure is preceded by a list of 16-bit word indexes into the array, that
 * is accessed by subtracting an offset stored in the Zone structure from the Zone address.
 */
typedef struct {
    WORD  e_XPos;       // X coordinate
    WORD  e_ZPos;       // Z coordinate
    WORD  e_XLen;       // Length in X direction
    WORD  e_ZLen;       // Length in Z direction
    WORD  e_JoinZoneID; // Zone the edge joins to, or -1 for a solid wall
    WORD  e_Word_5;     // TODO figure out what this is
    BYTE  e_Byte_12;    // TODO figure out what this is
    BYTE  e_Byte_13;    // TODO figure out what this is
    UWORD e_Flags;
} __attribute__((packed)) __attribute__ ((aligned (2))) ZEdge;

/**
 * Main zone structure. Note that the long fields in here can be 2-byte aligned due to the
 * way in which the loaded data works, e.g:
 *
 * [list of zone edge indexes] [zone structure] [list of zone PVS record data]
 *
 */
typedef struct {
    WORD  z_ZoneID;                   //  2, 2
    LONG  z_Floor;                    //  2, 4
    LONG  z_Roof;                     //  6, 4
    LONG  z_UpperFloor;               // 10, 4
    LONG  z_UpperRoof;                // 14, 4
    LONG  z_Water;                    // 18, 4
    WORD  z_Brightness;               // 22, 2
    WORD  z_UpperBrightness;          // 24, 2
    WORD  z_ControlPoint;             // 26, 2 really UBYTE[2]
    WORD  z_BackSFXMask;              // 28, 2 Originally long but always accessed as word
    WORD  z_Unused;                   // 30, 2 so this is the unused half
    WORD  z_EdgeListOffset;           // 32, 2
    WORD  z_Points;                   // 34, 2
    UBYTE z_DrawBackdrop;             // 36, 1
    UBYTE z_Echo;                     // 37, 1
    WORD  z_TelZone;                  // 38, 2
    WORD  z_TelX;                     // 40, 2
    WORD  z_TelZ;                     // 42, 2
    WORD  z_FloorNoise;               // 44, 2
    WORD  z_UpperFloorNoise;          // 46, 2
    ZPVSRecord  z_PotVisibleZoneList[1];    // 48, 2 Vector, varying length
}  __attribute__((packed)) __attribute__ ((aligned (2))) Zone;

/**
 * Zone PVS Errata
 *
 * The errata is a stream of words that are varying length lists that each begin with the
 * zone ID the errata applies to, followed by a ZONE_ID_LIST_END terminated list of IDs of
 * potentially visible zones to be removed from the PVS list for the starting zone. The errata
 * list itself is terminated by ZONEvoid Zone_InitEdgePVS(void);_ID_LIST_END, i.e. the word list ends with a double
 * ZONE_ID_LIST_END pair.
 *
 */
void Zone_ApplyPVSErrata(REG(a0, WORD const* zonePVSErrataPtr));
void Zone_InitEdgePVS(void);
void Zone_FreeEdgePVS(void);
void Zone_FillEdgePVS(void);

/**
 * Zone ID indexed array of Zone pointers
 */
extern Zone** Lvl_ZonePtrsPtr_l;

/**
 * Edge ID indexed array of ZEdge pointers
 */
extern ZEdge* Lvl_ZoneEdgePtr_l;

/**
 * Number of zones defined in the loaded level
 */
extern WORD   Lvl_NumZones_w;

/**
 *  Check if a Zone ID is valid. Must be between 0 and Lvl_NumZones_w-1
 */
static __inline BOOL zone_IsValidZoneID(WORD id) {
    return id >= 0 && id < Lvl_NumZones_w;
}

/**
 *  Check if am Edge ID is valid.
 *
 *  TODO find and expose the maximum edge ID for proper range checking
 */
static __inline BOOL zone_IsValidEdgeID(WORD id) {
    return id >= 0;
}

/**
 * Obtain the address of the list of edges for the current zone. This is obtained by
 * adding the (negative) z_EdgeListOffset to the Zone address.
 */
static __inline WORD const* zone_GetEdgeList(Zone const* zonePtr) {
    return (WORD const*)(((BYTE const*)zonePtr) + zonePtr->z_EdgeListOffset);
}

/**
 * Structure for the per-edge PVS data header:
 *
 * [Zone ID][Num Edges][Num PVS][EdgeID 0]...[EdgeID N][PVS List 0] ... [PVS List N]
 */
typedef struct {
    WORD zep_ZoneID;
    WORD zep_ListSize;
    WORD zep_EdgeCount;
    WORD zep_EdgeIDList[1]; // zep_EdgeCount in length, followed by zep_EdgeCount sets of data
}  __attribute__((packed)) __attribute__ ((aligned (2))) ZEdgePVSHeader;

/**
 * Returns the address of the start of the actual EdgePVSList. This immediately follows the
 * ZEdgePVSHeader.zep_EdgeIDList array, which is zep_EdgeCount elements long.
 */
static __inline UBYTE* zone_GetEdgePVSListBase(ZEdgePVSHeader const* zepPtr) {
    return (UBYTE*)(&zepPtr->zep_EdgeIDList[zepPtr->zep_EdgeCount]);
}

extern ZEdgePVSHeader** Lvl_ZEdgePVSHeaderPtrsPtr_l;

#endif // ZONE_H
