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
 * Return the number of joining edges for the current zone
 */
static WORD zone_CountJoiningEdges(Zone const* zonePtr) {
    WORD numEdges = 0;
    WORD const* zEdgeList = zone_GetEdgeList(zonePtr);
    WORD edgeId;
    while (zone_IsValidEdgeID( (edgeId = *zEdgeList++) )) {
        if (zone_IsValidZoneID(Lvl_ZoneEdgePtr_l[edgeId].e_JoinZoneID)) {
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

        dprintf(
            "%p [%u] %d %d %d {",
            currentEdgePVSPtr,
            dataSize,
            (int)currentEdgePVSPtr->zep_ZoneID,
            (int)currentEdgePVSPtr->zep_ListSize,
            (int)currentEdgePVSPtr->zep_EdgeCount
        );

        Zone const* zonePtr   = Lvl_ZonePtrsPtr_l[zoneID];
        WORD const* zEdgeList = zone_GetEdgeList(zonePtr);

        // Byte addressible offset from the beginning of the ZEdgePVSDataSet structure to the list data
        WORD edgeIndex  = 0;
        WORD edgeId;
        while (zone_IsValidEdgeID( (edgeId = *zEdgeList++) )) {
            ZEdge const* edgePtr = &Lvl_ZoneEdgePtr_l[edgeId];
            if (zone_IsValidZoneID(edgePtr->e_JoinZoneID)) {
                currentEdgePVSPtr->zep_EdgeIDList[edgeIndex++] = edgeId;

                // Calculate the centre point along the edge
                WORD centreX = ((edgePtr->e_XPos << 1) + edgePtr->e_XLen) >> 1;
                WORD centreZ = ((edgePtr->e_ZPos << 1) + edgePtr->e_ZLen) >> 1;
                dprintf("%d [cx:%d,cz:%d]", (int)edgeId, (int)centreX, (int)centreZ);

            }
        }
        dputs("}");
        currentEdgePVSPtr = (ZEdgePVSHeader*)((UBYTE*)currentEdgePVSPtr + dataSize);
    }

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

void Zone_FillEdgePVS(Zone* const zonePtr) {

}

void Zone_FreeEdgePVS() {
    if (Lvl_PerEdgePVSDataPtr_l) {
        FreeVec(Lvl_PerEdgePVSDataPtr_l);
        Lvl_PerEdgePVSDataPtr_l = NULL;
        dputs("Zone_FreeEdgePVS()");
    }
}
