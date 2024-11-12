#include "system.h"
#include "zone.h"
#include <proto/exec.h>
#include <stdio.h>

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
static __inline int zone_SideOfEdge(ZEdge const* edgePtr, WORD const* coordPtr) {
    return (int)edgePtr->e_XLen * (int)(coordPtr[1] - edgePtr->e_ZPos) -
           (int)edgePtr->e_ZLen * (int)(coordPtr[0] - edgePtr->e_XPos);
}

/**
 * Return the (unterminated) count of the number of PVS entries for the given zone
 */
static WORD zone_CountPVS(Zone const* zonePtr) {
    ZPVSRecord const* pvsPtr = &zonePtr->z_PotVisibleZoneList[0];
    while (zone_IsValidZoneID(pvsPtr->pvs_ZoneID)) {
        ++pvsPtr;
    }
    return (WORD)(pvsPtr - &zonePtr->z_PotVisibleZoneList[0]);
}

/**
 * Copy the IDs of the Zone's ZPVSRecord set to a buffer of just the IDs, terminaged with ZONE_ID_LIST_END.
 */
static void zone_MakePVSZoneIDList(Zone const* zonePtr, WORD* bufferPtr) {
    ZPVSRecord const* pvsPtr = &zonePtr->z_PotVisibleZoneList[0];
    while (zone_IsValidZoneID(pvsPtr->pvs_ZoneID)) {
        *bufferPtr++ = pvsPtr->pvs_ZoneID;
        ++pvsPtr;
    }
    *bufferPtr = ZONE_ID_LIST_END;
}


/**
 * Return the number of joining edges for the current zone
 */
static WORD zone_CountJoiningEdges(Zone const* zonePtr) {
    WORD numEdges = 0;
    WORD const* zEdgeList = zone_GetEdgeList(zonePtr);
    WORD edgeID;
    while (zone_IsValidEdgeID( (edgeID = *zEdgeList++) )) {
        if (zone_IsValidZoneID(Lvl_ZoneEdgePtr_l[edgeID].e_JoinZoneID)) {
            ++numEdges;
        }
    }
    return numEdges;
}

/**
 * Calculates the allocation data size for the per-edge PVS data, returning the total allocation size,
 * including the base pointer requirements. The infoPairBufferPtr points to a buffer that is populated with the
 * edge count and PVS length pairs for each of the Zones and the elementSize parameter specifies how
 * big each element to in the per edge PVS data should be.
 */
static ULONG zone_CalcEdgePVSDataSize(WORD* infoPairBufferPtr) {
    /* Begin with the assumption we need as many pointers as zones */
    ULONG totalSize = Lvl_NumZones_w * sizeof(ZEdgePVSHeader*);

    for (WORD zoneID = 0, *infoPairPtr = infoPairBufferPtr; zoneID < Lvl_NumZones_w; ++zoneID) {
        Zone const* zonePtr = Lvl_ZonePtrsPtr_l[zoneID];
        WORD joinCount      = zone_CountJoiningEdges(zonePtr);
        WORD pvsSize        = zone_CountPVS(zonePtr);
        *infoPairPtr++      = pvsSize;
        *infoPairPtr++      = joinCount;

        // The size of ZEdgePVSDataSet includes one edge id entry already...
        ULONG dataSize   = sizeof(ZEdgePVSHeader) - sizeof(WORD) +
            (ULONG)joinCount * (sizeof(WORD) + (ULONG)pvsSize);

        // Ensure that the data remains aligned to a word bounary
        dataSize = (dataSize + 1) & ~1;
        totalSize += dataSize;
    }

    return totalSize;
}



/**
 * Allocates and initialises the per-edge PVS daa
 */
void Zone_InitEdgePVS() {
    // Store the per zone facts ready for the second step.
    WORD* infoPairPtr  = (WORD*)Sys_GetTemporaryWorkspace();
    ULONG totalSize    = zone_CalcEdgePVSDataSize(infoPairPtr);

    dprintf(
        "Zone_InitEdgePVS() Processed %d Zones, Required data size: %u\n",
        (int)Lvl_NumZones_w,
        totalSize
    );

    // Round off the allocation to 4 bytes
    totalSize = (totalSize + 3) & ~3;

    Lvl_PerEdgePVSDataPtr_l = AllocVec(totalSize, MEMF_ANY);

    // For convenience, use a byte addressable pointer
    UBYTE* rawBufferPtr = (UBYTE*)Lvl_PerEdgePVSDataPtr_l;

    // Set up the list of pointers at the beginning
    ZEdgePVSHeader** zonePtrBasePtr = (ZEdgePVSHeader**)rawBufferPtr;

    // Set up the initial ZEdgePVSDataSet
    ZEdgePVSHeader*  currentEdgePVSPtr = (ZEdgePVSHeader*)(rawBufferPtr + Lvl_NumZones_w * sizeof(ZEdgePVSHeader*));

    ULONG dataSize;

    // First Pass - build the ZEdgePVSHeader data and populate the edge indexes
    for (WORD zoneID = 0; zoneID < Lvl_NumZones_w; ++zoneID) {
        currentEdgePVSPtr->zep_ZoneID    = zoneID;
        currentEdgePVSPtr->zep_ListSize  = *infoPairPtr++;
        currentEdgePVSPtr->zep_EdgeCount = *infoPairPtr++;
        zonePtrBasePtr[zoneID]           = currentEdgePVSPtr;

        // The size of ZEdgePVSDataSet includes one ZEdgePVSIndex entry...
        dataSize = sizeof(ZEdgePVSHeader) - sizeof(WORD) +
            (ULONG)currentEdgePVSPtr->zep_EdgeCount * (sizeof(WORD) +
            (ULONG)currentEdgePVSPtr->zep_ListSize);

        // Ensure we stay word aligned here...
        dataSize = (dataSize + 1) & ~1;

        // dprintf(
        //     "%p [%u] %d %d %d {",
        //     currentEdgePVSPtr,
        //     dataSize,
        //     (int)currentEdgePVSPtr->zep_ZoneID,
        //     (int)currentEdgePVSPtr->zep_ListSize,
        //     (int)currentEdgePVSPtr->zep_EdgeCount
        // );

        Zone const* zonePtr   = Lvl_ZonePtrsPtr_l[zoneID];
        WORD const* zEdgeList = zone_GetEdgeList(zonePtr);

        // Byte addressible offset from the beginning of the ZEdgePVSDataSet structure to the list data
        WORD edgeIndex  = 0;
        WORD edgeID;
        while (zone_IsValidEdgeID( (edgeID = *zEdgeList++) )) {
            if (zone_IsValidZoneID(Lvl_ZoneEdgePtr_l[edgeID].e_JoinZoneID)) {
                currentEdgePVSPtr->zep_EdgeIDList[edgeIndex++] = edgeID;
                //dprintf("%d ", (int)edgeID);
            }
        }
        //dputs("}");
        currentEdgePVSPtr = (ZEdgePVSHeader*)((UBYTE*)currentEdgePVSPtr + dataSize);
    }
    Zone_FillEdgePVS();
}



/**
 * Algorithm required for per-edge PVS fine tuning:
 *
 * foreach Zones as Zone
 *     mark zone as visited
 *     foreach Connecting Edge
 *         Clear edge PVS data
 *         Calculate the centre coordinate as reference point
 *         Invoke recursive Zone traversal starting at the adjoining zone
 *
 * Algorithm required for the recursive traversal
 *
 * mark Zone in edge PVS data as visible
 * mark Zone as visited
 * foreach Connecting Edge
 *     if edge is front-facing to reference point
 *         Recurse
 *
 */

/**
 * Data structure used to keep track of key information during the recursive evaluation of
 * the per-edge PVS data for a zone.
 */
static struct {

    /**
     * Pointer to the list of pointers to the ZEdgePVSHeader data per sone.
     */
    ZEdgePVSHeader** zre_EdgePVSHeaderListPtr;

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
     * Pointer to a ZONE_ID_LIST_END terminated list of the zones that have been visited during
     * traversale of the edge.
     */
    WORD* zre_VisitedListPtr;

    /**
     * Pointer to the specific edge list dataset under evaluation. For now, this is a list of
     * truthy bytes that indicate whether or not a ZPVSRecord of zre_rootZonePtr should be drawn
     * or skipped when considering only this edge.
     */
    UBYTE* zre_EdgePVSList;
    /**
     * Viewpoint for the evaluation of edge facing towards/away. This is the centre point of
     * the edge that connects the zre_rootZonePtr to the an immediate child. Every zone connected
     * via that child is tested by evaluating whether or not the edges connecting them are still
     * front facing from this point.
     */
    WORD  zre_ViewX;
    WORD  zre_ViewZ;
} Zone_EdgePVSState;

/**
 * Utility method to determine the index position of a zone ID in the zre_FullPVSListPtr. Returns ZONE_ID_LIST_END
 * if the zoneID is not found in the list.
 */
static WORD zone_GetIndexInPVSList(WORD zoneID) {
    WORD *nextIDPtr = Zone_EdgePVSState.zre_FullPVSListPtr;
    while (zone_IsValidZoneID(*nextIDPtr) ) {
        if (zoneID == *nextIDPtr) {
            return nextIDPtr - Zone_EdgePVSState.zre_FullPVSListPtr;
            ++nextIDPtr;
        }
    }
    return ZONE_ID_LIST_END;
}

void Zone_RecurseEdgePVS(WORD zoneID) {
    dprintf(
        "\tRecursing Zone %d\n",
        (int)zoneID
    );

    // Get the list of joining edges for this zone.
    ZEdgePVSHeader* currentEdgePVSPtr = Zone_EdgePVSState.zre_EdgePVSHeaderListPtr[zoneID];

    //
    for (WORD edgeNum = 0; edgeNum < currentEdgePVSPtr->zep_EdgeCount; ++edgeNum) {
        ZEdge const* edgePtr = &Lvl_ZoneEdgePtr_l[currentEdgePVSPtr->zep_EdgeIDList[edgeNum]];
        WORD nextZoneID = edgePtr->e_JoinZoneID;

        // Tests needed
        //
        // Is the zone on the joining edge in the visited list? If so, skip
        // Is the zone on the joining edge in the current full PVS list? If so continue
        // Is the joining edge front facing relative to the view point? If so mark as included

        WORD indexInPVS = zone_GetIndexInPVSList(nextZoneID);
        if (indexInPVS > ZONE_ID_LIST_END) {
            //Zone_RecurseEdgePVS(nextZoneID);
            dprintf("\t\t %d\n", (int)nextZoneID);
        }
    }
}

void Zone_FillEdgePVS() {

    Zone_EdgePVSState.zre_EdgePVSHeaderListPtr = (ZEdgePVSHeader**)Lvl_PerEdgePVSDataPtr_l;

    for (WORD zoneID = 0; zoneID < Lvl_NumZones_w; ++zoneID) {
        Zone_EdgePVSState.zre_rootZonePtr    = Lvl_ZonePtrsPtr_l[zoneID];
        Zone_EdgePVSState.zre_FullPVSListPtr = (WORD*)Sys_GetTemporaryWorkspace();

        // Fill the buffer with the list of zones in the PVS for our zone
        zone_MakePVSZoneIDList(
            Zone_EdgePVSState.zre_rootZonePtr,
            Zone_EdgePVSState.zre_FullPVSListPtr
        );

        ZEdgePVSHeader* currentEdgePVSPtr = Zone_EdgePVSState.zre_EdgePVSHeaderListPtr[zoneID];

        Zone_EdgePVSState.zre_EdgePVSList = zone_GetEdgePVSListBase(currentEdgePVSPtr);

        dprintf(
            "Zone: %d [Joins: %d, List Size: %d]\n",
            (int)zoneID,
            (int)currentEdgePVSPtr->zep_EdgeCount,
            (int)currentEdgePVSPtr->zep_ListSize
        );

        // For each edge, calculate the centre point as a viewpoint, then enter the zone
        // In the entered zone explore each front facing edge and descend depth first
        // Need to mark each distinct visited zone as "potentially visible"

        for (WORD edgeNum = 0; edgeNum < currentEdgePVSPtr->zep_EdgeCount; ++edgeNum) {
            ZEdge const* edgePtr = &Lvl_ZoneEdgePtr_l[currentEdgePVSPtr->zep_EdgeIDList[edgeNum]];

            Zone_EdgePVSState.zre_ViewX = ((edgePtr->e_XPos << 1) + edgePtr->e_XLen) >> 1;
            Zone_EdgePVSState.zre_ViewZ = ((edgePtr->e_ZPos << 1) + edgePtr->e_ZLen) >> 1;

            // dprintf(
            //     "\tEdge #%d [%d] - C %d, %d list %p\n",
            //     (int)edgeNum,
            //     currentEdgePVSPtr->zep_EdgeIDList[edgeNum],
            //     (int)Zone_EdgePVSState.zre_ViewX,
            //     (int)Zone_EdgePVSState.zre_ViewZ,
            //     Zone_EdgePVSState.zre_EdgePVSList
            // );

            Zone_RecurseEdgePVS(edgePtr->e_JoinZoneID);

            Zone_EdgePVSState.zre_EdgePVSList += currentEdgePVSPtr->zep_ListSize;
        }
    }
}

void Zone_FreeEdgePVS() {
    if (Lvl_PerEdgePVSDataPtr_l) {
        FreeVec(Lvl_PerEdgePVSDataPtr_l);
        Lvl_PerEdgePVSDataPtr_l = NULL;
        dputs("Zone_FreeEdgePVS()");
    }
}
