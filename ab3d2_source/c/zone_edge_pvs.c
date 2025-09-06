#include <stdio.h>
#include <proto/exec.h>
#include "defs.h"
#include "system.h"
#include "zone.h"
#include "zone_liftable.h"
#include "zone_inline.h"

extern Vec2W const* Lvl_PointsPtr_l;
extern WORD Lvl_NumPoints_w;

extern ZDoorListMask Zone_CurrentDoorState_w;
extern ZDoorListMask Zone_RenderDoorState_w;

static char buffer[256]; // just for debugging

/**
 * Temporary statistics structure used when determining the data size required for the EdgePVS Data.
 */
typedef struct {
    WORD  numZones; // How many zones there are in the the PVS
    WORD  numJoins; // How many joining edges there are from the root of the PVS
    UWORD features; // Features present in the PVS, eg. doors, lifts, etc
    UWORD dataSize; // Required data size for allocation
} ZPVSCount;

#define PVSCF_DOOR 1
#define PVSCF_LIFT 2

/**
 * Data structure used to keep track of key information during the recursive evaluation of
 * the per-edge PVS data for a zone. This data is accessed by recursive code, limiting the
 * amount of information required on the stack.
 */
static struct {

    /**
     * Pointer to the Zone the edge PVS data are being determined for.
     */
    Zone const* zre_rootZonePtr;

    /**
     * Pointer to a ZONE_ID_LIST_END terminated list of the ID values of each
     * of the Zones in the PVS lost for zre_rootZonePtr.
     */
    WORD* zre_FullPVSListPtr;

    /**
     * Pointer to the specific edge list dataset under evaluation. This is a list of truthy bytes that
     * have the same indexing as the zre_FullPVSListPtr list. Where an entry is truthy, the zone at
     * the index position is potentially visible via the edge. Otherwise, it isn't.
     */
    UBYTE* zre_EdgePVSList;

    /**
     * Pointer to the specific door list mask under evaluation, if there is one.
     */
    ZDoorListMask* zre_DoorMaskList;

    /**
     * Recursion depth tracker.
     */
    WORD zre_RecursionDepth;
    WORD zre_MaxRecursionDepth;
    LONG zre_OperationCount;

    /**
     * These are the start and end coordinates of the edge for which the PVS is being evaluated.
     */
    Vec2W zre_ViewPoint1;
    Vec2W zre_ViewPoint2;

} Zone_EdgePVSState;


/**
 * Copy the IDs of the Zone's ZPVSRecord set to a buffer of just the IDs, terminated with
 * ZONE_ID_LIST_END. Returns the address of the end of the list.
 */
static WORD* zone_MakePVSZoneIDList(Zone const* zonePtr, WORD* bufferPtr)
{
    ZPVSRecord const* pvsPtr = &zonePtr->z_PotVisibleZoneList[0];
    while (Zone_IsValidZoneID(pvsPtr->pvs_ZoneID)) {
        *bufferPtr++ = pvsPtr->pvs_ZoneID;
        ++pvsPtr;
    }
    *bufferPtr++ = ZONE_ID_LIST_END;
    return bufferPtr;
}


/**
 * Return the number of joining edges for the given zone. An edge is considered joining
 * when:
 *   The edge ID is valid.
 *   The adjoining zone ID of the edge is valid.
 *   The zone heights contain an overlap.
 */
static WORD zone_CountJoiningEdges(Zone const* zonePtr)
{
    WORD numEdges = 0;
    WORD const* zEdgeList = Zone_GetEdgeList(zonePtr);
    WORD edgeID;
    while (Zone_IsValidEdgeID( (edgeID = *zEdgeList++) )) {
        WORD nextZoneID;
        if (Zone_IsValidZoneID( (nextZoneID = Lvl_ZoneEdgePtr_l[edgeID].e_JoinZoneID)) ) {
            ZoneCrossing crossing = Zone_DetermineCrossing(
                zonePtr,
                Lvl_ZonePtrsPtr_l[nextZoneID]
            );
            if (crossing != NO_PATH) {
                ++numEdges;
            }
        }
    }
    return numEdges;
}


/**
 * Gathers key facts about the PVS of the specific Zone:
 *
 *     Number of zones in the PVS
 *     Number of joining edges
 *     Whether the PVS contains a door
 *     Whether the PVS contaisn a lift
 *     Total required datasize for the per-edge data
 */
static void zone_CountPVS(Zone const* zonePtr, ZPVSCount* pvsCountPtr)
{
    ZPVSRecord const* pvsPtr = &zonePtr->z_PotVisibleZoneList[0];
    pvsCountPtr->features = 0;
    while (Zone_IsValidZoneID(pvsPtr->pvs_ZoneID)) {
        if (!(pvsCountPtr->features & PVSCF_DOOR) && Zone_IsDoor(pvsPtr->pvs_ZoneID)) {
            pvsCountPtr->features |= PVSCF_DOOR;
        }
        ++pvsPtr;
    }
    pvsCountPtr->numZones = (WORD)(pvsPtr - &zonePtr->z_PotVisibleZoneList[0]);
    pvsCountPtr->numJoins = zone_CountJoiningEdges(zonePtr);

    // The size of ZEdgePVSDataSet includes one edge id entry already...
    ULONG dataSize = sizeof(ZEdgePVSHeader) - sizeof(ZEdgeInfo) +

        // For each joining edge, we have a header, plus the zone mask as a minimum requirement
        (ULONG)pvsCountPtr->numJoins * (
            sizeof(ZEdgeInfo) + (ULONG)pvsCountPtr->numZones // The zone mask is 1 byte per zone, so use the count
        );

    // We may need additional memory for features that require masks, e.g. doors, lifts etc.
    if (pvsCountPtr->features & PVSCF_DOOR) {
        dataSize += pvsCountPtr->numZones * pvsCountPtr->numJoins * sizeof(ZDoorListMask);
    }
    // TODO - Same again for lifts

    // TODO - maybe assert() dataSize fits a UWORD, using blind faith here

    // Ensure that the data remains aligned to a word boundary.
    pvsCountPtr->dataSize = (UWORD)Sys_Round2(dataSize);

//     dprintf(
//         "Zone %d ZPVSCount { numZones:%d, numJoins:%d, features:0x%04X, dataSize:%d }\n",
//         (int)zonePtr->z_ZoneID,
//         (int)pvsCountPtr->numZones,
//         (int)pvsCountPtr->numJoins,
//         (unsigned)pvsCountPtr->features,
//         (int)pvsCountPtr->dataSize
//     );

}


/**
 * Calculates the allocation data size for the per-edge PVS data, returning the total allocation
 * size, including the base pointer requirements.
 *
 * This fills the pvsCountBufferPtr with the per-zone facts as it goes. We need that later.
 */
static ULONG zone_CalcEdgePVSDataSize(ZPVSCount* pvsCountBufferPtr)
{
    /* Begin with the assumption we need as many pointers as zones */
    ULONG totalSize = Lvl_NumZones_w * sizeof(ZEdgePVSHeader*);
    for (WORD zoneID = 0; zoneID < Lvl_NumZones_w; ++zoneID) {
        Zone const* zonePtr = Lvl_ZonePtrsPtr_l[zoneID];
        zone_CountPVS(zonePtr, pvsCountBufferPtr);
        totalSize += pvsCountBufferPtr->dataSize;
        ++pvsCountBufferPtr;
    }
    return totalSize;
}


/**
 * Calculates the required memory for the Edge PVS data and allocates it. In the process of
 * calculating the size.
 */
static ZEdgePVSHeader** zone_AllocEdgePVS(ZPVSCount* pvsCountBufferPtr)
{
    ULONG totalSize = zone_CalcEdgePVSDataSize(pvsCountBufferPtr);

    dprintf(
        "zone_AllocEdgePVS() Processed %d Zones, Size: %u\n",
        (int)Lvl_NumZones_w,
        totalSize
    );

    // Round off the allocation to 4 bytes
    totalSize = Sys_Round4(totalSize);

    // Allocate the space for the pointer table and the data.
    return (ZEdgePVSHeader**)AllocVec(totalSize, MEMF_ANY);
}

/**
 * Calculate the offset fields for a given ZEdgePVSHeader once the size/edges/features are known
 */
static void zone_CalcZEdgePVSHeaderOffsets(ZEdgePVSHeader* currentEdgePVSPtr, UWORD features)
{
    // First the offset to the edge mask. This immediately follows the the array of ZEdgeInfo
    size_t offset = (sizeof(ZEdgePVSHeader) - sizeof(ZEdgeInfo)) +
        currentEdgePVSPtr->zep_EdgeCount * sizeof(ZEdgeInfo);

    currentEdgePVSPtr->zep_ZoneMaskOffset = (WORD)offset;

    // If there are doors, comes after the edge mask. As the edge mask is byte based, the offset
    // is subject to rounding before we get to the doors.
    if (features & PVSCF_DOOR) {
        offset += Sys_Round2(currentEdgePVSPtr->zep_ListSize * currentEdgePVSPtr->zep_EdgeCount);
        currentEdgePVSPtr->zep_DoorMaskOffset = (WORD)offset;
    } else {
        currentEdgePVSPtr->zep_DoorMaskOffset = 0;
    }

    // TODO lifts
    currentEdgePVSPtr->zep_LiftMaskOffset = 0;
}

/**
 * Builds up the pointer table with the location for each ZEdgePVSHeader and populates
 * the ZEdgePVSHeader structure fields.
 */
static void zone_FillZEdgePVSHeaders(ZEdgePVSHeader* currentEdgePVSPtr, ZPVSCount const* pvsCountBufferPtr)
{
    // First Pass - build the ZEdgePVSHeader data and populate the edge indexes.
    for (WORD zoneID = 0; zoneID < Lvl_NumZones_w; ++zoneID) {

        currentEdgePVSPtr->zep_ZoneID    = zoneID;
        currentEdgePVSPtr->zep_ListSize  = pvsCountBufferPtr->numZones;
        currentEdgePVSPtr->zep_EdgeCount = pvsCountBufferPtr->numJoins;

        zone_CalcZEdgePVSHeaderOffsets(currentEdgePVSPtr, pvsCountBufferPtr->features);

        Lvl_ZEdgePVSHeaderPtrsPtr_l[zoneID]  = currentEdgePVSPtr;

        Zone const* zonePtr   = Lvl_ZonePtrsPtr_l[zoneID];
        WORD const* zEdgeList = Zone_GetEdgeList(zonePtr);

        // Byte addressible offset from the beginning of the ZEdgePVSDataSet structure to the list data
        WORD edgeIndex  = 0;
        WORD edgeID;
        WORD nextZoneID;
        while (Zone_IsValidEdgeID( (edgeID = *zEdgeList++) )) {
            if (Zone_IsValidZoneID( (nextZoneID = Lvl_ZoneEdgePtr_l[edgeID].e_JoinZoneID)) ) {

                ZoneCrossing crossing = Zone_DetermineCrossing(
                    zonePtr,
                    Lvl_ZonePtrsPtr_l[nextZoneID]
                );

                if (crossing != NO_PATH) {
                    currentEdgePVSPtr->zep_EdgeInfoList[edgeIndex++].zei_EdgeID = edgeID;
                }
            }
        }
/*
        dprintf(
            "ZEdgePVSHeader {\n"
            "\tzep_ZoneID: %d,\n"
            "\tzep_ListSize: %d,\n"
            "\tzep_EdgeCount: %d,\n"
            "\tzep_ZoneMaskOffset: %d\n"
            "\tzep_DoorMaskOffset: %d\n"
            "\tzep_LiftMaskOffset: %d\n"
            "}\n",
            (int)currentEdgePVSPtr->zep_ZoneID,
            (int)currentEdgePVSPtr->zep_ListSize,
            (int)currentEdgePVSPtr->zep_EdgeCount,
            (int)currentEdgePVSPtr->zep_ZoneMaskOffset,
            (int)currentEdgePVSPtr->zep_DoorMaskOffset,
            (int)currentEdgePVSPtr->zep_LiftMaskOffset
        );
*/
        currentEdgePVSPtr = (ZEdgePVSHeader*)((UBYTE*)currentEdgePVSPtr + pvsCountBufferPtr->dataSize);
        ++pvsCountBufferPtr;
    }
}

/**
 * Utility method to determine the index position of a zone ID in the zre_FullPVSListPtr.
 * Returns ZONE_ID_LIST_END if the zoneID is not found in the list.
 */
static WORD zone_GetIndexInPVSList(WORD zoneID)
{
    WORD *nextIDPtr = Zone_EdgePVSState.zre_FullPVSListPtr;
    while (Zone_IsValidZoneID(*nextIDPtr) ) {
        if (zoneID == *nextIDPtr) {
            return nextIDPtr - Zone_EdgePVSState.zre_FullPVSListPtr;
        }
        ++nextIDPtr;
    }
    return ZONE_ID_LIST_END;
}

static ZDoorListMask zone_GetInitialDoorMask(WORD zoneID)
{
    WORD doorIndex = Zone_GetDoorID(zoneID);
    if (doorIndex != NOT_A_DOOR) {
        return 1 << doorIndex;
    }
    return 0;
}


/**
 * Recurses zones using the index position in the PVS. This is so that we only need to calculate this
 * once per visit as the code is already a looping frenzy!
 *
 * We only enter adjoining zones that are on edges facing the viewpoint, construcing our PVS subset
 * as we go.
 */
static void zone_RecurseEdgePVS(WORD indexInPVS, ZDoorListMask doorMask)
{
    if (++Zone_EdgePVSState.zre_RecursionDepth > Zone_EdgePVSState.zre_MaxRecursionDepth) {
        Zone_EdgePVSState.zre_MaxRecursionDepth = Zone_EdgePVSState.zre_RecursionDepth;
    }
    ++Zone_EdgePVSState.zre_OperationCount;

    WORD zoneID = Zone_EdgePVSState.zre_FullPVSListPtr[indexInPVS];

    WORD visType = ZVIS_DIRECT;

    // Mark as visited and thus visible in the PVS
    Zone_EdgePVSState.zre_EdgePVSList[indexInPVS] = ZVIS_DIRECT;

    if (Zone_EdgePVSState.zre_DoorMaskList) {
        ZDoorListMask myDoorMask = zone_GetInitialDoorMask(zoneID);
        if (myDoorMask) {
            doorMask |= myDoorMask;
            visType = ZVIS_DOOR;
        } else if (doorMask) {
            visType = ZVIS_COND;
        }

        Zone_EdgePVSState.zre_DoorMaskList[indexInPVS] = doorMask;
    }

    Zone_EdgePVSState.zre_EdgePVSList[indexInPVS] = visType;

    // Get the list of known joining edges for this zone.
    ZEdgePVSHeader* currentEdgePVSPtr = Lvl_ZEdgePVSHeaderPtrsPtr_l[zoneID];

    for (WORD edgeNum = 0; edgeNum < currentEdgePVSPtr->zep_EdgeCount; ++edgeNum) {
        ZEdge const* edgePtr = &Lvl_ZoneEdgePtr_l[currentEdgePVSPtr->zep_EdgeInfoList[edgeNum].zei_EdgeID];

        WORD nextZoneID = edgePtr->e_JoinZoneID;

        // Get the index position of the adjoining zone in the PVS list
        indexInPVS = zone_GetIndexInPVSList(nextZoneID);

        // Is the adjoining zone not in the PVS list? Skip.
        if (indexInPVS == ZONE_ID_LIST_END) {
            continue;
        }

        WORD nextVis = Zone_EdgePVSState.zre_EdgePVSList[indexInPVS];
        // Have we visited this zone already?
        // This is an MVP version of visibility upgrade.
        if (nextVis >= ZVIS_DOOR) {
            // Can't upgrade visibility because the zone is either a door/lift or already directly visible.
            // A door or lift zone can always be obscured, even when in a direct line of sight.
            continue;
        } else if (nextVis > ZVIS_NONE && visType < ZVIS_DIRECT) {
            // Can't upgrade visibility because our visibilty isn't a better class
            continue;
        }

        // Is the view point facing the edge?
        // < 0 facing towards, > 0 facing away, 0 colinear with
        // Only visit the adjoining zone if it's strictly facing
        // TODO - include colinear?
        // TODO - Other tests - what about impassible height differences?

        // Test both ends of the edge.
        if (
            Zone_SideOfEdge(edgePtr, &Zone_EdgePVSState.zre_ViewPoint1) < 0 ||
            Zone_SideOfEdge(edgePtr, &Zone_EdgePVSState.zre_ViewPoint2) < 0
        ) {
            zone_RecurseEdgePVS(indexInPVS, doorMask);
        }
    }

    --Zone_EdgePVSState.zre_RecursionDepth;
}

/**
 * Populate the per-edge PVS data. This uses a recursive mechanism to grind through the
 * existing zone graph data.
 */
static void zone_FillZEdgePVSListData()
{
    Zone_EdgePVSState.zre_FullPVSListPtr    = (WORD*)Sys_GetTemporaryWorkspace();
    Zone_EdgePVSState.zre_RecursionDepth    = 0;
    Zone_EdgePVSState.zre_MaxRecursionDepth = 0;
    Zone_EdgePVSState.zre_OperationCount    = 0;
    for (WORD zoneID = 0; zoneID < Lvl_NumZones_w; ++zoneID) {

        Zone_EdgePVSState.zre_rootZonePtr    = Lvl_ZonePtrsPtr_l[zoneID];

        // Fill the buffer with the list of zones in the PVS for our zone
        zone_MakePVSZoneIDList(
            Zone_EdgePVSState.zre_rootZonePtr,
            Zone_EdgePVSState.zre_FullPVSListPtr
        );

        ZEdgePVSHeader* currentEdgePVSPtr  = Lvl_ZEdgePVSHeaderPtrsPtr_l[zoneID];

        // Can never be null
        Zone_EdgePVSState.zre_EdgePVSList  = Zone_GetEdgePVSListBase(currentEdgePVSPtr);

        // Note, might be null
        Zone_EdgePVSState.zre_DoorMaskList = Zone_GetEdgePVSDoorListBase(currentEdgePVSPtr);

        if (currentEdgePVSPtr->zep_EdgeCount > 10) {
            dprintf(
                "Error: Zone %d reports %d edges, skip\n", (int)zoneID, (int)currentEdgePVSPtr->zep_EdgeCount
            );
            continue;
        }

        // For each edge, calculate the centre point as a viewpoint, then enter the zone
        // In the entered zone explore each front facing edge and descend depth first
        // Need to mark each distinct visited zone as "potentially visible"

        ZDoorListMask doorMask = zone_GetInitialDoorMask(zoneID);

        // Walk the set of shared edges
        for (WORD edgeNum = 0; edgeNum < currentEdgePVSPtr->zep_EdgeCount; ++edgeNum) {
            ZEdge const* edgePtr = &Lvl_ZoneEdgePtr_l[currentEdgePVSPtr->zep_EdgeInfoList[edgeNum].zei_EdgeID];

            Zone_EdgePVSState.zre_ViewPoint1.v_X = edgePtr->e_Pos.v_X;
            Zone_EdgePVSState.zre_ViewPoint1.v_Z = edgePtr->e_Pos.v_Z;

            Zone_EdgePVSState.zre_ViewPoint2.v_X = edgePtr->e_Pos.v_X + edgePtr->e_Len.v_X;
            Zone_EdgePVSState.zre_ViewPoint2.v_Z = edgePtr->e_Pos.v_Z + edgePtr->e_Len.v_Z;

            // Clear the visited index buffer, which requires a count of longwords
            // Sys_MemFillLong(
            //     Zone_EdgePVSState.zre_VisitedIndexPtr,
            //     0,
            //     (currentEdgePVSPtr->zep_ListSize + 3) >> 2
            // );

            // Mark the root zone as already visited
            Zone_EdgePVSState.zre_EdgePVSList[0] = ZVIS_DIRECT;

            // Set the root zone door mask, if relevant
            if (Zone_EdgePVSState.zre_DoorMaskList) {
                Zone_EdgePVSState.zre_DoorMaskList[0] = doorMask;
            }
            // Mark the rest as clear. They will be set true for every zone we enter during
            // the recursion.
            // TODO - why is mem fill not working here?
            for (WORD i = 1; i < currentEdgePVSPtr->zep_ListSize; ++i) {
                Zone_EdgePVSState.zre_EdgePVSList[i] = 0;
            }

            WORD indexInPVS = zone_GetIndexInPVSList(edgePtr->e_JoinZoneID);

            if (indexInPVS > ZONE_ID_LIST_END) {
                zone_RecurseEdgePVS(indexInPVS, doorMask);
            }

            if (Zone_EdgePVSState.zre_DoorMaskList) {
/*
#if defined(ZONE_DEBUG)
                char const* doorIDNames = "0123456789ABCDEF";
                dprintf(
                    "Zone %d Edge %d {\n",
                    (int)zoneID,
                    (int)edgeNum
                );
                for (WORD i = 0; i < currentEdgePVSPtr->zep_ListSize; ++i) {
                    if (Zone_EdgePVSState.zre_EdgePVSList[i]) {
                        WORD mask = Zone_EdgePVSState.zre_DoorMaskList[i];
                        for (WORD j = 0; j < 16; ++j) {
                            buffer[j] = (mask & (1 << j)) ? doorIDNames[j] : '-';
                        }
                        buffer[16] = 0;
                        dprintf(
                            "\t%3d: %s\n",
                            (int)Zone_EdgePVSState.zre_FullPVSListPtr[i],
                            buffer
                        );
                    }
                }
                dputs("}\n");
#endif
*/
                Zone_EdgePVSState.zre_DoorMaskList += currentEdgePVSPtr->zep_ListSize;
            }
            Zone_EdgePVSState.zre_EdgePVSList += currentEdgePVSPtr->zep_ListSize;
        }
    }
    dprintf(
        "Edge List Data generated. Max Depth %d, Max Operations %d\n",
        (int)Zone_EdgePVSState.zre_MaxRecursionDepth,
        (int)Zone_EdgePVSState.zre_OperationCount
    );
}

/**
 * Accepts a coordinate and attempts to locate it in the set of points in the level. Returns the index of
 * the point, if found, or -1 if not. Does the matching by considering the points as pure longwords.
 */
static WORD zone_GetPointIndex(Vec2W const* p)
{
    ULONG const* pointPtr = (ULONG const*)Lvl_PointsPtr_l;
    ULONG match = *((ULONG const*)p);
    for (WORD i = 0; i < Lvl_NumPoints_w; ++i) {
        if (match == pointPtr[i]) {
            return i;
        }
    }
    return -1;
}

/**
 * Once we have built the initial edge PVS data, we need to find the index of their end coordinetes in the
 * level point data. These indexes are preserved across transformation and this allows us to find their
 * post-transformation screen space horizontal extent. This in turn allows us to address the fairly frequent
 * edge case that we are looking through a single edge that is going to go unclipped.
 */
static void zone_FillEdgePointIndexes(void)
{
    Vec2W end;
    for (WORD zoneID = 0; zoneID < Lvl_NumZones_w; ++zoneID) {
        ZEdgePVSHeader* edgePVSPtr = Lvl_ZEdgePVSHeaderPtrsPtr_l[zoneID];
        for (WORD i = 0; i < edgePVSPtr->zep_EdgeCount; ++i) {
            ZEdge const* edgePtr = &Lvl_ZoneEdgePtr_l[edgePVSPtr->zep_EdgeInfoList[i].zei_EdgeID];
            end.v_X = edgePtr->e_Pos.v_X + edgePtr->e_Len.v_X;
            end.v_Z = edgePtr->e_Pos.v_Z + edgePtr->e_Len.v_Z;
            edgePVSPtr->zep_EdgeInfoList[i].zei_StartPointID = zone_GetPointIndex(&edgePtr->e_Pos);
            edgePVSPtr->zep_EdgeInfoList[i].zei_EndPointID   = zone_GetPointIndex(&end);
        }
    }
}

#if defined(ZONE_DEBUG)
/**
 * Utility function for dumping the per edge PVS data
 */
static void zone_DumpPerEdgePVS(void)
{
    for (WORD zoneID = 0; zoneID < Lvl_NumZones_w; ++zoneID) {
        ZEdgePVSHeader const* edgePVSPtr = Lvl_ZEdgePVSHeaderPtrsPtr_l[zoneID];
        printf(
            "Zone %d: Edges: %d, PVS Size: %d\n",
            (int)zoneID,
            (int)edgePVSPtr->zep_EdgeCount,
            (int)edgePVSPtr->zep_ListSize
        );
        UBYTE* edgePVSListPtr = Zone_GetEdgePVSListBase(edgePVSPtr);
        for (WORD edgeNum = 0; edgeNum < edgePVSPtr->zep_EdgeCount; ++edgeNum) {
            printf("\tEdge: #%d ", edgeNum);

            for (WORD i = 0; i < edgePVSPtr->zep_ListSize; ++i) {
                buffer[i] = edgePVSListPtr[i] ? '+' : '-';
            }
            buffer[edgePVSPtr->zep_ListSize] = 0;
            puts(buffer);
            edgePVSListPtr += edgePVSPtr->zep_ListSize;
        }
    }
}
#endif

/**
 * Allocates and initialises the per-edge PVS data.
 */
void Zone_InitEdgePVS()
{
    #if defined(ZONE_DEBUG)
    union {
        struct EClockVal ev;
        uint64_t u64;
    } start;
    union {
        struct EClockVal ev;
        uint64_t u64;
    } end;
    Sys_MarkTime(&start.ev);
    #endif

    Zone_InitDoorList();

    ULONG infoTupleBufferSize = (ULONG)Lvl_NumZones_w * 3 * sizeof(WORD);

    dprintf("Zone_InitEdgePVS() need %u bytes for info buffer\n", infoTupleBufferSize);

    // Store the per zone list size / edge count ready for the second step.
    ZPVSCount* pvsCountBufferPtr = (ZPVSCount*)Sys_GetTemporaryWorkspace();

    // Allocate the space for the pointer table and the data.
    Lvl_ZEdgePVSHeaderPtrsPtr_l = zone_AllocEdgePVS(pvsCountBufferPtr);

    // Fill in the ZEdgePVS Header Structures
    zone_FillZEdgePVSHeaders(
        Zone_ZEdgePVSHeaderBase(Lvl_ZEdgePVSHeaderPtrsPtr_l),
        pvsCountBufferPtr
    );

    // Fill in the ZEdgePVS body list data
    zone_FillZEdgePVSListData();

    zone_FillEdgePointIndexes();

    // Assume doors closed on level start
    Zone_CurrentDoorState_w =
    Zone_RenderDoorState_w = 0;

    #if defined(ZONE_DEBUG)
    //zone_DumpPerEdgePVS();
    Sys_MarkTime(&end.ev);

    ULONG ticks = (ULONG)(end.u64 - start.u64);
    dprintf("Built PVS dataset, took %lu EClock ticks\n", ticks);
    #endif
}

/**
 * Frees up the data
 */
void Zone_FreeEdgePVS()
{
    if (Lvl_ZEdgePVSHeaderPtrsPtr_l) {
        FreeVec(Lvl_ZEdgePVSHeaderPtrsPtr_l);
        Lvl_ZEdgePVSHeaderPtrsPtr_l = NULL;
        dputs("Zone_FreeEdgePVS()");
    }
}

// The Player position data are long algined word values
#define POS_X 0
#define POS_Z 4
extern WORD Plr1_Position_vl[];
extern WORD Plr2_Position_vl[];

#define DIR_COS 0
#define DIR_SIN 1
#define DIR_ANG 2
extern WORD Plr1_Direction_vw[];

/**
 * 2048 = 90 degrees, in game fov is about 79
 */
#define FOV 1800

/**
 *  This can be overridden in by config
 */
WORD Zone_PVSFieldOfView = FOV;

static Vec2W zone_ViewPoint;
static Vec2W zone_PerpDir;
static Vec2W zone_LeftFOVDir;
static Vec2W zone_RightFOVDir;

extern WORD Zone_VisJoins_w;
extern WORD Zone_TotJoins_w;

extern WORD Vis_CosVal_w;
extern WORD Vis_SinVal_w;
extern WORD Vis_AngPos_w;

void Zone_UpdateVectors()
{
    // Forwards vector is      z: DIR_COS, x: DIR_SIN
    // Perpendicular vector is z: DIR_SIN, x: -DIR_COS
    //dputs("Zone_UpdateVectors()");
    if (Plr_MultiplayerType_b == MULTIPLAYER_SLAVE) {
        zone_ViewPoint.v_X   = Plr2_Position_vl[POS_X];
        zone_ViewPoint.v_Z   = Plr2_Position_vl[POS_Z];
    } else {
        zone_ViewPoint.v_X   = Plr1_Position_vl[POS_X];
        zone_ViewPoint.v_Z   = Plr1_Position_vl[POS_Z];
    }
    zone_PerpDir.v_X     = -Vis_CosVal_w;
    zone_PerpDir.v_Z     = Vis_SinVal_w;

    // Get the direction vectors for the left and right field of view
    WORD fovAngle        = Vis_AngPos_w - (Zone_PVSFieldOfView >> 1);
    zone_LeftFOVDir.v_X  = sinw(fovAngle);
    zone_LeftFOVDir.v_Z  = cosw(fovAngle);

    fovAngle += Zone_PVSFieldOfView;
    zone_RightFOVDir.v_X = sinw(fovAngle);
    zone_RightFOVDir.v_Z = cosw(fovAngle);
}

#define BIT_FRONT 1
#define BIT_LEFT  2
#define BIT_RIGHT 4

extern LONG Sys_FrameNumber_l;
extern WORD  Zone_PVSList_vw[];
extern UBYTE Zone_PVSMask_vb[];

extern ZPVSRecord* Lvl_ListOfGraphRoomsPtr_l;


void zone_ClearEdgePVSBuffer(WORD size)
{
    Zone_PVSMask_vb[0] = 0xFF;
    for (WORD i = 1; i < size; ++i) {
        Zone_PVSMask_vb[i] = 0;
    }
}

void zone_MergeEdgePVS(UBYTE const* zoneMaskPtr, ZDoorListMask const* doorListMaskPtr, WORD size)
{
    if (doorListMaskPtr) {
        ZDoorListMask mask = Zone_RenderDoorState_w;
        for (WORD i = 1; i < size; ++i) {
            Zone_PVSMask_vb[i] |= (
                (doorListMaskPtr[i] & mask) == doorListMaskPtr[i]
            ) ? zoneMaskPtr[i] : 0;
        }
    } else {
        for (WORD i = 1; i < size; ++i) {
            Zone_PVSMask_vb[i] |= zoneMaskPtr[i];
        }
    }
}

void zone_MarkVisibleViaEdges(WORD size)
{
    WORD zoneID = Lvl_ListOfGraphRoomsPtr_l->pvs_ZoneID;
    zone_MakePVSZoneIDList(Lvl_ZonePtrsPtr_l[zoneID], &Zone_PVSList_vw[0]);

    for (WORD i = 0; i < size; ++i) {
        Lvl_ZonePtrsPtr_l[Zone_PVSList_vw[i]]->z_Unused = Zone_PVSMask_vb[i];
    }
}

/**
 * TODO - debug fully and port to asm
 */

// -1 terminated buffer of edge point indexes that must be transformed
extern WORD Zone_EdgePointIndexes_vw[];
extern UWORD Zone_VisJoinMask_w;

void Zone_CheckVisibleEdges(void)
{
    WORD zoneID = Lvl_ListOfGraphRoomsPtr_l->pvs_ZoneID;

    ZEdgePVSHeader const* edgePVSPtr = Lvl_ZEdgePVSHeaderPtrsPtr_l[zoneID];
    UBYTE const* edgePVSListPtr = Zone_GetEdgePVSListBase(edgePVSPtr);
    ZDoorListMask const* doorListMaskPtr = Zone_GetEdgePVSDoorListBase(edgePVSPtr);
    Vec2W endPoint;
    WORD  startFlags;
    WORD  endFlags;
    WORD  numVisible   = 0;
    WORD  edgeID;
    UWORD visJoinMask  = 0;
    WORD  doorListStep = doorListMaskPtr ? edgePVSPtr->zep_ListSize : 0;

    Zone_UpdateVectors();
    zone_ClearEdgePVSBuffer(edgePVSPtr->zep_ListSize);

    // Snapshot the door state to prevent interrupt changes messing with us.
    Zone_RenderDoorState_w = Zone_CurrentDoorState_w;

    WORD* edgePointIndex = &Zone_EdgePointIndexes_vw[0];

    for (WORD i = 0; i < edgePVSPtr->zep_EdgeCount; ++i, edgePVSListPtr += edgePVSPtr->zep_ListSize, doorListMaskPtr += doorListStep) {

        edgeID = edgePVSPtr->zep_EdgeInfoList[i].zei_EdgeID;

        ZEdge const* edgePtr = &Lvl_ZoneEdgePtr_l[edgeID];

        startFlags = (sideOfDirection(
            &zone_ViewPoint,
            &zone_PerpDir,
            &edgePtr->e_Pos
        ) < 0) ? BIT_FRONT : 0;

        startFlags |= (sideOfDirection(
            &zone_ViewPoint,
            &zone_LeftFOVDir,
            &edgePtr->e_Pos
        ) <= 0) ? BIT_LEFT : 0;

        startFlags |= (sideOfDirection(
            &zone_ViewPoint,
            &zone_RightFOVDir,
            &edgePtr->e_Pos
        ) >= 0) ? BIT_RIGHT : 0;

        if (startFlags == (BIT_FRONT|BIT_LEFT|BIT_RIGHT)) {
            visJoinMask |= 1 << i;
            ++numVisible;
            zone_MergeEdgePVS(edgePVSListPtr, doorListMaskPtr, edgePVSPtr->zep_ListSize);
            *edgePointIndex++ = edgePVSPtr->zep_EdgeInfoList[i].zei_StartPointID;
            *edgePointIndex++ = edgePVSPtr->zep_EdgeInfoList[i].zei_EndPointID;
            continue;
        }

        endPoint.v_X = edgePtr->e_Pos.v_X + edgePtr->e_Len.v_X;
        endPoint.v_Z = edgePtr->e_Pos.v_Z + edgePtr->e_Len.v_Z;

        endFlags = (sideOfDirection(
            &zone_ViewPoint,
            &zone_PerpDir,
            &endPoint
        ) < 0) ? BIT_FRONT : 0;

        endFlags |= (sideOfDirection(
            &zone_ViewPoint,
            &zone_LeftFOVDir,
            &endPoint
        ) <= 0) ? BIT_LEFT : 0;

        endFlags |= (sideOfDirection(
            &zone_ViewPoint,
            &zone_RightFOVDir,
            &endPoint
        ) >= 0) ? BIT_RIGHT : 0;

        if (endFlags == (BIT_FRONT|BIT_LEFT|BIT_RIGHT)) {
            visJoinMask |= 1 << i;
            ++numVisible;
            zone_MergeEdgePVS(edgePVSListPtr, doorListMaskPtr, edgePVSPtr->zep_ListSize);
            *edgePointIndex++ = edgePVSPtr->zep_EdgeInfoList[i].zei_StartPointID;
            *edgePointIndex++ = edgePVSPtr->zep_EdgeInfoList[i].zei_EndPointID;
            continue;
        }

        if (
            ((startFlags|endFlags) & BIT_FRONT) &&
            (startFlags & BIT_LEFT) == 0 &&
            (endFlags & BIT_RIGHT) == 0
        ) {
            visJoinMask |= 1 << i;
            //dprintf("\tSpan. Start: %d End: %d\n", (int)startFlags, (int)endFlags);
            ++numVisible;
            zone_MergeEdgePVS(edgePVSListPtr, doorListMaskPtr, edgePVSPtr->zep_ListSize);
            *edgePointIndex++ = edgePVSPtr->zep_EdgeInfoList[i].zei_StartPointID;
            *edgePointIndex++ = edgePVSPtr->zep_EdgeInfoList[i].zei_EndPointID;
            continue;
        }
    }

    *edgePointIndex = EDGE_POINT_ID_LIST_END;

    Zone_VisJoinMask_w = visJoinMask;

    Zone_VisJoins_w = numVisible;
    Zone_TotJoins_w = edgePVSPtr->zep_EdgeCount;

    zone_MarkVisibleViaEdges(edgePVSPtr->zep_ListSize);
}

extern WORD Draw_CurrentZone_w;
extern WORD OnScreen_vl[];
extern WORD Vid_RightX_w;
extern UBYTE Draw_ForceZoneSkip_b;

/**
 * Called from within the sub room loop in assembler.
 */
void Zone_SetupEdgeClipping(void)
{
    // If we have one visible join and we are not in the root zone, lookup and set the single edge
    // clip extents.
    Draw_ZoneClipL_w = 0;
    Draw_ZoneClipR_w = Vid_RightX_w;
    Draw_ForceZoneSkip_b = 0;

    WORD minL = Vid_RightX_w;
    WORD maxR = 0;
    if (Zone_VisJoins_w > 0 && Lvl_ListOfGraphRoomsPtr_l->pvs_ZoneID != Draw_CurrentZone_w) {
        for (WORD i = 0; i < (Zone_VisJoins_w << 1); i += 2) {
            WORD scrL = OnScreen_vl[Zone_EdgePointIndexes_vw[i]];
            WORD scrR = OnScreen_vl[Zone_EdgePointIndexes_vw[i + 1]];

            // Deal with conversion overflow issues
            if (scrL > scrR) {
                scrL = 0;
                scrR = Vid_RightX_w;
            }

            // Tracm min/max
            if (scrL < minL) {
                minL = scrL;
            }
            if (scrR > maxR) {
                maxR = scrR;
            }
        }
        if (minL < 0) {
            minL = 0;
        }
        if (maxR > Vid_RightX_w) {
            maxR = Vid_RightX_w;
        }

        Draw_ZoneClipL_w = minL;
        Draw_ZoneClipR_w = maxR;
    }
}

ZoneCrossing Zone_DetermineCrossing(Zone const* from, Zone const* to)
{

    ZoneCrossing result = zone_LevelOverlap(
        zone_GetLowerLevel(from),
        zone_GetLowerLevel(to)
    ) ? LOWER_TO_LOWER : NO_PATH;

    WORD test = (zone_HasUpper(from) ? 1 : 0) | (zone_HasUpper(to) ? 2 : 0);

    switch (test) {

        case 1:
            // from has upper and lower, to has lower only.
            result |= zone_LevelOverlap(
                zone_GetUpperLevel(from),
                zone_GetLowerLevel(to)
            ) ? UPPER_TO_LOWER : NO_PATH;
            break;

        case 2:
            // from has lower, to has lower and upper.
            result |= zone_LevelOverlap(
                zone_GetLowerLevel(from),
                zone_GetUpperLevel(to)
            ) ? LOWER_TO_UPPER : NO_PATH;
            break;

        case 3:
            result |= zone_LevelOverlap(
                zone_GetUpperLevel(from),
                zone_GetLowerLevel(to)
            ) ? UPPER_TO_LOWER : NO_PATH;
            result |= zone_LevelOverlap(
                zone_GetLowerLevel(from),
                zone_GetUpperLevel(to)
            ) ? LOWER_TO_UPPER : NO_PATH;
            result |= zone_LevelOverlap(
                zone_GetUpperLevel(from),
                zone_GetUpperLevel(to)
            ) ? UPPER_TO_UPPER : NO_PATH;
            break;

        default:
            break;
    }

    if (result == NO_PATH) {
        dprintf(
            "\t%d -> %d: No Zone Crossing. Case %d failed\n",
            (int)from->z_ZoneID,
            (int)to->z_ZoneID,
            (int)test
        );
    }

    return result;
}
