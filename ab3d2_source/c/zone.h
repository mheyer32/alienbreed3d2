#ifndef ZONE_H
#define ZONE_H

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

/**
 * This structure contains information about a potentially visible zone. A list of these
 * is appended to each Zone structure. The final record has pvs_ZoneID set to -1.
 */
typedef struct {
    WORD pvs_ZoneID;
    WORD pvs_SortVal;
    WORD pvs_Word2; // TODO
    WORD pvs_Word3; // TODO
} __attribute__((packed)) __attribute__ ((aligned (2))) ZPVSRecord;

/**
 * Edge structure.
 */
typedef struct {
    WORD  e_XPos;       // X coordinate
    WORD  e_ZPos;       // Z coordinate
    WORD  e_XLen;       // Length in X direction
    WORD  e_ZLen;       // Length in Z direction
    WORD  e_JoinZoneID; // Zone the edge joins to, or -1 for a solid wall
    WORD  e_Word_5;     // TODO
    BYTE  e_Byte_12;    // TODO
    BYTE  e_Byte_13;    // TODO
    UWORD e_Flags;
} __attribute__((packed)) __attribute__ ((aligned (2))) ZEdge;

/**
 * Main zone structure. Note that the long fields in here can be 2-byte aligned.
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

static __inline WORD const* zone_GetEdgeList(Zone const* zonePtr) {
    return (WORD const*)(((BYTE const*)zonePtr) + zonePtr->z_EdgeListOffset);
}

static __inline BOOL zone_IsValidID(WORD id) {
    return (id >= 0);
}

void Zone_ProcessPVS(REG(a0, Zone* zonePtr));

extern Zone** Lvl_ZonePtrsPtr_l;
extern ZEdge* Lvl_ZoneEdgePtr_l;

#endif // ZONE_H
