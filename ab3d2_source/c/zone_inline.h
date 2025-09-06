#ifndef ZONE_INLINE_H
#define ZONE_INLINE_H

#include "zone.h"
#include "zone_liftable.h"

/**
 *  Check if a Zone ID is valid. Must be between 0 and Lvl_NumZones_w-1
 */
static inline BOOL Zone_IsValidZoneID(WORD id)
{
    return id >= 0 && id < Lvl_NumZones_w;
}

/**
 *  Check if am Edge ID is valid.
 *
 *  TODO find and expose the maximum edge ID for proper range checking
 */
static inline BOOL Zone_IsValidEdgeID(WORD id)
{
    return id >= 0;
}

/**
 * Checks if a Zone is a door or not. This relies on the bitmap lookup.
 */
static inline BOOL Zone_IsDoor(WORD zoneID)
{
    return Zone_IsValidZoneID(zoneID) && ( Zone_DoorMap_vb[zoneID >> 3] & (1 << (zoneID & 7)) );
}

/**
 * Obtain the address of the list of edges for the current zone. This is obtained by
 * adding the (negative) z_EdgeListOffset to the Zone address.
 */
static inline WORD const* Zone_GetEdgeList(Zone const* zonePtr)
{
    return (WORD const*)(((BYTE const*)zonePtr) + zonePtr->z_EdgeListOffset);
}

static inline WORD const* Zone_GetPointIndexList(Zone const* zonePtr)
{
    return (WORD const*)(((BYTE const*)zonePtr) + zonePtr->z_Points);
}


/**
 * Returns the address of the start of the actual EdgePVSList. This immediately follows the
 * ZEdgePVSHeader.zep_EdgeIDList array, which is zep_EdgeCount elements long.
 */
static inline UBYTE* Zone_GetEdgePVSListBase(ZEdgePVSHeader const* zepPtr)
{
    //return (UBYTE*)(&zepPtr->zep_EdgeInfoList[zepPtr->zep_EdgeCount]);
    return ((UBYTE*)zepPtr) + zepPtr->zep_ZoneMaskOffset;
}

/**
 * Returns the address of the start of the Door Mask List. This will return null if the PVS doesn't
 * contain a door.
 */
static inline ZDoorListMask* Zone_GetEdgePVSDoorListBase(ZEdgePVSHeader const* zepPtr)
{
    if (zepPtr->zep_DoorMaskOffset) {
        return (ZDoorListMask*)(((UBYTE*)zepPtr) + zepPtr->zep_DoorMaskOffset);
    }
    return NULL;
}

/**
 * Returns the address of the start of the Lift Mask List. This will return null if the PVS doesn't
 * contain a lift.
 */
static inline ZLiftListMask* Zone_GetEdgePVSLiftListBase(ZEdgePVSHeader const* zepPtr)
{
    if (zepPtr->zep_LiftMaskOffset) {
        return (ZLiftListMask*)(((UBYTE*)zepPtr) + zepPtr->zep_LiftMaskOffset);
    }
    return NULL;
}
/**
 * Returns which side of an edge a coordinate is on.
 *
 * For a vector AB and a point P:
 *
 *   d = (B.x - A.x) * (P.z - A.z) - (B.z - A.z) * (P.x - A.x)
 *
 * For our ZEdge structure, the B - A terms are given by the e_XLen and e_ZLen members.
 *
 * Where d is 0, P is on the line of AB. Positive values are one one side, negative the other.
 *
 */
static inline int Zone_SideOfEdge(ZEdge const* edgePtr, Vec2W const* coordPtr)
{
    return (int)edgePtr->e_Len.v_X * (int)(coordPtr->v_Z - edgePtr->e_Pos.v_Z) -
           (int)edgePtr->e_Len.v_Z * (int)(coordPtr->v_X - edgePtr->e_Pos.v_X);
}

/**
 * Returns the address of the zeroth ZEdgePVSHeader in the set.
 */
static inline ZEdgePVSHeader* Zone_ZEdgePVSHeaderBase(void const* basePtr)
{
    return (ZEdgePVSHeader*)(
        ((UBYTE*)basePtr) + Lvl_NumZones_w * sizeof(ZEdgePVSHeader*)
    );
}

/**
 * Returns the canonical height of a level as reported in the editor. It is unclear if there are
 * variations in the lower 8 bits at runtime, so we define this function to return a straight
 * word value havine discarded the lower 8 bits.
 *
 * TODO - figure out if the shift is really necessary and remove if not
 */
static inline WORD heightOf(LONG level)
{
    return (WORD)(level >> 8);
}

/**
 * Test if a Zone has an upper level.
 */
static inline BOOL zone_HasUpper(Zone const* zone)
{
    WORD floor = heightOf(zone->z_UpperFloor);
    return floor < DISABLED_HEIGHT && floor > heightOf(zone->z_UpperRoof);
}

static inline Zone_LevelPair const* zone_GetLowerLevel(Zone const* zone)
{
    return (Zone_LevelPair const*)&zone->z_Floor;
}

static inline Zone_LevelPair const* zone_GetUpperLevel(Zone const* zone)
{
    return (Zone_LevelPair const*)&zone->z_UpperFloor;
}

/**
 * Check if there is any overlap between given pair of Zone_LevelPair
 *
 * Remember: height values are inverted - smaller values are higher than larger ones.
 */
static inline BOOL zone_LevelOverlap(Zone_LevelPair const* z1, Zone_LevelPair const* z2)
{
    WORD floor = heightOf(z2->zlp_Floor);
    WORD roof  = heightOf(z1->zlp_Roof);
    if (roof >= floor) {
        return FALSE;
    }

    floor = heightOf(z1->zlp_Floor);
    roof  = heightOf(z2->zlp_Roof);
    if (roof >= floor) {
        return FALSE;
    }

    // I think this is sufficient?
    return TRUE;
}



#endif // ZONE_INLINE_H
