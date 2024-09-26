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
 * This structure may have some long aligned data penalties.
 */
typedef struct {
    WORD z_ID;                       //  2, 2
    LONG z_Floor;                    //  2, 4
    LONG z_Roof;                     //  6, 4
    LONG z_UpperFloor;               // 10, 4
    LONG z_UpperRoof;                // 14, 4
    LONG z_Water;                    // 18, 4
    WORD z_Brightness;               // 22, 2
    WORD z_UpperBrightness;          // 24, 2
    WORD z_ControlPoint;             // 26, 2 really UBYTE[2]
    WORD z_BackSFXMask;              // 28, 2 Originally long but always accessed as word
    WORD z_Unused;                   // 30, 2 so this is the unused half
    WORD z_EdgeListOffset;                 // 32, 2
    WORD z_Points;                   // 34, 2
    UBYTE z_Back;                    // 36, 1 unused
    UBYTE z_Echo;                    // 37, 1
    WORD z_TelZone;                  // 38, 2
    WORD z_TelX;                     // 40, 2
    WORD z_TelZ;                     // 42, 2
    WORD z_FloorNoise;               // 44, 2
    WORD z_UpperFloorNoise;          // 46, 2
    WORD z_PotVisibleZoneList[1];    // 48, 2 Assumed vector, varying length
}  __attribute__((packed)) __attribute__ ((aligned (2))) Zone;

typedef struct {
    WORD e_XPos;       // X coordinate
    WORD e_ZPos;       // Z coordinate
    WORD e_XLen;       // Length in X direction
    WORD e_ZLen;       // Length in Z direction
    WORD e_JoinZone;   // Zone the edge joins to, or -1 for a solid wall
    WORD e_Word_5;     // TODO
    BYTE e_Byte_12;    // TODO
    BYTE e_Byte_13;    // TODO
    WORD e_Flags;
} __attribute__((packed)) __attribute__ ((aligned (2))) ZEdge;

extern Zone** Lvl_ZonePtrsPtr_l;

extern ZEdge* Lvl_ZoneEdgePtr_l;

#endif // ZONE_DEBUG_H
