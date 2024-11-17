#include "system.h"
#include "zone.h"
#include <proto/exec.h>
#include <stdio.h>

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
     * Recursion depth tracker.
     */
    LONG zre_RecursionDepth;

    /**
     * Viewpoint for the evaluation of edge facing towards/away. This is the centre point of
     * the edge that connects the zre_rootZonePtr to the an immediate child. Every zone connected
     * via that child is tested by evaluating whether or not the edges connecting them are still
     * front facing from this point.
     */
    WORD  zre_ViewX;
    WORD  zre_ViewZ;
} Zone_EdgePVSState;

static char buffer[256]; // just for debugging

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
static inline int zone_SideOfEdge(ZEdge const* edgePtr, WORD const* coordPtr) {
    return (int)edgePtr->e_XLen * (int)(coordPtr[1] - edgePtr->e_ZPos) -
           (int)edgePtr->e_ZLen * (int)(coordPtr[0] - edgePtr->e_XPos);
}

/**
 * Return the (unterminated) count of the number of PVS entries for the given zone.
 */
static WORD zone_CountPVS(Zone const* zonePtr) {
    ZPVSRecord const* pvsPtr = &zonePtr->z_PotVisibleZoneList[0];
    while (zone_IsValidZoneID(pvsPtr->pvs_ZoneID)) {
        ++pvsPtr;
    }
    return (WORD)(pvsPtr - &zonePtr->z_PotVisibleZoneList[0]);
}

/**
 * Copy the IDs of the Zone's ZPVSRecord set to a buffer of just the IDs, terminated with
 * ZONE_ID_LIST_END. Returns the address of the end of the list.
 */
static WORD* zone_MakePVSZoneIDList(Zone const* zonePtr, WORD* bufferPtr) {
    ZPVSRecord const* pvsPtr = &zonePtr->z_PotVisibleZoneList[0];
    while (zone_IsValidZoneID(pvsPtr->pvs_ZoneID)) {
        *bufferPtr++ = pvsPtr->pvs_ZoneID;
        ++pvsPtr;
    }
    *bufferPtr++ = ZONE_ID_LIST_END;
    return bufferPtr;
}


/**
 * Return the number of joining edges for the current zone.
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
 * Calculates the allocation data size for the per-edge PVS data, returning the total allocation
 * size, including the base pointer requirements.
 * The infoPairBufferPtr points to a buffer that is populated with the edge count and PVS length
 * pairs for each of the Zones.
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

        // Ensure that the data remains aligned to a word bounary.
        dataSize = Sys_Round2(dataSize);
        totalSize += dataSize;
    }
    return totalSize;
}

/**
 * Returns the address of the zeroth ZEdgePVSHeader in the set.
 */
static inline ZEdgePVSHeader* zone_ZEdgePVSHeaderBase(void const* basePtr) {
    return (ZEdgePVSHeader*)((UBYTE*)basePtr) +
        Lvl_NumZones_w * sizeof(ZEdgePVSHeader*);
}

/**
 * Calculateds the required memory for the Edge PVS data and allocates it. In the process of
 * calculating the size, populates an array of PVS Size / Connecting Edge Count pairs, the
 * location of which is passed in.
 */
static ZEdgePVSHeader** zone_AllocEdgePVS(WORD* infoPairPtr) {
    ULONG totalSize = zone_CalcEdgePVSDataSize(infoPairPtr);

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
 * Builds up the pointer table with the location for each ZEdgePVSHeader and populates
 * the ZEdgePVSHeader structure fields.
 */
static void zone_FillZEdgePVSHeaders(ZEdgePVSHeader* currentEdgePVSPtr, WORD const* infoPairPtr) {

    // First Pass - build the ZEdgePVSHeader data and populate the edge indexes.
    for (WORD zoneID = 0; zoneID < Lvl_NumZones_w; ++zoneID) {
        currentEdgePVSPtr->zep_ZoneID    = zoneID;
        currentEdgePVSPtr->zep_ListSize  = *infoPairPtr++;
        currentEdgePVSPtr->zep_EdgeCount = *infoPairPtr++;
        Lvl_ZEdgePVSHeaderPtrsPtr_l[zoneID]  = currentEdgePVSPtr;

        // The size of ZEdgePVSDataSet includes one ZEdgePVSIndex entry...
        ULONG dataSize = Sys_Round2(sizeof(ZEdgePVSHeader) - sizeof(WORD) +
            (ULONG)currentEdgePVSPtr->zep_EdgeCount * (sizeof(WORD) +
            (ULONG)currentEdgePVSPtr->zep_ListSize)
        );

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
}

/**
 * Utility method to determine the index position of a zone ID in the zre_FullPVSListPtr.
 * Returns ZONE_ID_LIST_END if the zoneID is not found in the list.
 */
static WORD zone_GetIndexInPVSList(WORD zoneID) {
    WORD *nextIDPtr = Zone_EdgePVSState.zre_FullPVSListPtr;
    while (zone_IsValidZoneID(*nextIDPtr) ) {
        if (zoneID == *nextIDPtr) {
            return nextIDPtr - Zone_EdgePVSState.zre_FullPVSListPtr;
        }
        ++nextIDPtr;
    }
    return ZONE_ID_LIST_END;
}

/**
 * Recurses zones using the index position in the PVS. This is so that we only need to calculate this
 * once per visit as the code is already a looping frenzy!
 *
 * We only enter adjoining zones that are on edges facing the viewpoint, construcing our PVS subset
 * as we go.
 */
static void zone_RecurseEdgePVS(WORD indexInPVS) {
    ++Zone_EdgePVSState.zre_RecursionDepth;

    // Mark as visited and thus visible in the PVS
    Zone_EdgePVSState.zre_EdgePVSList[indexInPVS] = 0xFF;

    WORD zoneID = Zone_EdgePVSState.zre_FullPVSListPtr[indexInPVS];

    // Get the list of known joining edges for this zone.
    ZEdgePVSHeader* currentEdgePVSPtr = Lvl_ZEdgePVSHeaderPtrsPtr_l[zoneID];

    for (WORD edgeNum = 0; edgeNum < currentEdgePVSPtr->zep_EdgeCount; ++edgeNum) {
        ZEdge const* edgePtr = &Lvl_ZoneEdgePtr_l[currentEdgePVSPtr->zep_EdgeIDList[edgeNum]];
        WORD nextZoneID = edgePtr->e_JoinZoneID;

        // Get the index position of the adjoining zone in the PVS list
        indexInPVS = zone_GetIndexInPVSList(nextZoneID);

        // Is the adjoining zone not in the PVS list? Skip.
        if (indexInPVS == ZONE_ID_LIST_END) {
            continue;
        }

        // Have we visited this zone already? Skip.
        if (Zone_EdgePVSState.zre_EdgePVSList[indexInPVS]) {
            continue;
        }

        // Is the view point facing the edge?
        // < 0 facing towards, > 0 facing away, 0 colinear with
        // Only visit the adjoining zone if it's strictly facing
        // TODO - include colinear?

        // TODO - Other tests - what about impassible height differences?

        if (zone_SideOfEdge(edgePtr, &Zone_EdgePVSState.zre_ViewX) < 0) {
            zone_RecurseEdgePVS(indexInPVS);
        }
    }
    --Zone_EdgePVSState.zre_RecursionDepth;
}

/**
 * Populate the per-edge PVS data. This uses a recursive mechanism to grind through the
 * existing zone graph data.
 */
static void zone_FillZEdgePVSListData() {
    Zone_EdgePVSState.zre_FullPVSListPtr = (WORD*)Sys_GetTemporaryWorkspace();
    Zone_EdgePVSState.zre_RecursionDepth = 0;
    for (WORD zoneID = 0; zoneID < Lvl_NumZones_w; ++zoneID) {
        Zone_EdgePVSState.zre_rootZonePtr    = Lvl_ZonePtrsPtr_l[zoneID];

        // Fill the buffer with the list of zones in the PVS for our zone
        WORD* endPtr = zone_MakePVSZoneIDList(
            Zone_EdgePVSState.zre_rootZonePtr,
            Zone_EdgePVSState.zre_FullPVSListPtr
        );

        ZEdgePVSHeader* currentEdgePVSPtr = Lvl_ZEdgePVSHeaderPtrsPtr_l[zoneID];
        Zone_EdgePVSState.zre_EdgePVSList = zone_GetEdgePVSListBase(currentEdgePVSPtr);

        // dprintf(
        //     "Zone: %d [Joins: %d, List Size: %d]\n",
        //     (int)zoneID,
        //     (int)currentEdgePVSPtr->zep_EdgeCount,
        //     (int)currentEdgePVSPtr->zep_ListSize
        // );

        // For each edge, calculate the centre point as a viewpoint, then enter the zone
        // In the entered zone explore each front facing edge and descend depth first
        // Need to mark each distinct visited zone as "potentially visible"

        for (WORD edgeNum = 0; edgeNum < currentEdgePVSPtr->zep_EdgeCount; ++edgeNum) {
            ZEdge const* edgePtr = &Lvl_ZoneEdgePtr_l[currentEdgePVSPtr->zep_EdgeIDList[edgeNum]];

            Zone_EdgePVSState.zre_ViewX = ((edgePtr->e_XPos << 1) + edgePtr->e_XLen) >> 1;
            Zone_EdgePVSState.zre_ViewZ = ((edgePtr->e_ZPos << 1) + edgePtr->e_ZLen) >> 1;

            // Clear the visited index buffer, which requires a count of longwords
            // Sys_MemFillLong(
            //     Zone_EdgePVSState.zre_VisitedIndexPtr,
            //     0,
            //     (currentEdgePVSPtr->zep_ListSize + 3) >> 2
            // );

            // Mark the root zone as already visited
            Zone_EdgePVSState.zre_EdgePVSList[0] = 0xFF;

            // Mark the rest as clear. They will be set true for every zone we enter during
            // the recursion.
            // TODO - why is mem fill not working here?
            for (WORD i = 1; i < currentEdgePVSPtr->zep_ListSize; ++i) {
                Zone_EdgePVSState.zre_EdgePVSList[i] = 0;
            }

            WORD indexInPVS = zone_GetIndexInPVSList(edgePtr->e_JoinZoneID);
            if (indexInPVS > ZONE_ID_LIST_END) {
                zone_RecurseEdgePVS(indexInPVS);
            }
            Zone_EdgePVSState.zre_EdgePVSList += currentEdgePVSPtr->zep_ListSize;
        }
    }
}

#if defined(ZONE_DEBUG)
/**
 * Utility function for dumping the per edge PVS data
 */
static void zone_DumpPerEdgePVS(void) {
    for (WORD zoneID = 0; zoneID < Lvl_NumZones_w; ++zoneID) {
        ZEdgePVSHeader const* edgePVSPtr = Lvl_ZEdgePVSHeaderPtrsPtr_l[zoneID];
        printf(
            "Zone %d: Edges: %d, PVS Size: %d\n",
            (int)zoneID,
            (int)edgePVSPtr->zep_EdgeCount,
            (int)edgePVSPtr->zep_ListSize
        );
        UBYTE* edgePVSListPtr = zone_GetEdgePVSListBase(edgePVSPtr);
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
void Zone_InitEdgePVS() {
    // Store the per zone list size / edge count ready for the second step.
    WORD* infoPairPtr  = (WORD*)Sys_GetTemporaryWorkspace();

    // Allocate the space for the pointer table and the data.
    Lvl_ZEdgePVSHeaderPtrsPtr_l = zone_AllocEdgePVS(infoPairPtr);

    // Fill in the ZEdgePVS Header Structures
    zone_FillZEdgePVSHeaders(
        zone_ZEdgePVSHeaderBase(Lvl_ZEdgePVSHeaderPtrsPtr_l),
        infoPairPtr
    );

    // Fill in the ZEdgePVS body list data
    zone_FillZEdgePVSListData();

    #if defined(ZONE_DEBUG)
    zone_DumpPerEdgePVS();
    #endif
}

/**
 * Frees up the data
 */
void Zone_FreeEdgePVS() {
    if (Lvl_ZEdgePVSHeaderPtrsPtr_l) {
        FreeVec(Lvl_ZEdgePVSHeaderPtrsPtr_l);
        Lvl_ZEdgePVSHeaderPtrsPtr_l = NULL;
        dputs("Zone_FreeEdgePVS()");
    }
}

extern WORD Plr1_Direction_vw[];

void Zone_CheckVisibleEdges(WORD zoneID) {
    ZEdgePVSHeader const* edgePVSPtr = Lvl_ZEdgePVSHeaderPtrsPtr_l[zoneID];



    for (WORD i = 0; i < edgePVSPtr->zep_EdgeCount; ++i) {
        WORD edgeID = edgePVSPtr->zep_EdgeIDList[i];
    }
}
