#include "system.h"
#include "zone.h"
#include <proto/exec.h>
#include <stdio.h>

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
 * TODO these should be allocated dynamically or reserved from the general workspace buffer.
 */
//static WORD zone_PVSCurrentZoneIDs[256];
//static WORD zone_PVSVisitedZoneIDs[256];

/**
 * Returns a buffer holding a list of Zone ID values for the PVS of the Zone currently under
 * evaluation. This list is in the same order as the PVS ZPVSRecords. Entries in this list
 * that match the given errata list, the corresponding entry in the list will be set to
 * ZONE_ID_REMOVED_MANUAL. The list is terminated by ZONE_ID_LIST_END.
 */
static __inline WORD* zone_GetCurrentPVSBuffer() {
    return (WORD*)Sys_GetTemporaryWorkspace();
}

/**
 * Returns a buffer holding a list of the Zone ID values that have been visited by traversal
 * of the zones in the PVS via connected edges. This will exclude any zones that are disconnected
 * as a consequence of explicit removal of one or more entries.
 */
static __inline WORD* zone_GetVisitedPVSBuffer() {
    return ((WORD*)Sys_GetTemporaryWorkspace()) + 1024;
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
static int zone_SideOfEdge(ZEdge const* edgePtr, WORD const* coordPtr) {
    return (int)edgePtr->e_XLen * (int)(coordPtr[1] - edgePtr->e_ZPos) -
           (int)edgePtr->e_ZLen * (int)(coordPtr[0] - edgePtr->e_XPos);
}

/**
 * Initialise the current Zone PVS buffer. We copy the list of Zone ID from the PVSRecord
 * tuples to our buffer and check each value against a list of zones to remove. This list is
 * termonated by a ZONE_ID_LIST_END value. Any matches from the PVSRecord data are replaced
 * with ZONE_ID_REMOVED_MANUAL in the current PVS buffer.
 */
void zone_InitCurrentPVS(Zone const* zonePtr, WORD const* removeListPtr) {
    ZPVSRecord const* zonePVSPtr = zonePtr->z_PotVisibleZoneList;
    WORD* pvsCurrentZonePtr      = zone_GetCurrentPVSBuffer();
    WORD  zoneID;

    //dprintf("Building PVS List for Zone %d: ", (int)zonePtr->z_ZoneID);

    int runaway = PVS_TRAVERSE_LIMIT;
    while ((zoneID = zonePVSPtr->pvs_ZoneID) > ZONE_ID_LIST_END && runaway-- > 0) {

        //dprintf("%d", zoneID);

        ++zonePVSPtr;
        WORD const* removePtr = removeListPtr;
        while (removePtr && zone_IsValidZoneID(*removePtr)) {
            if (*removePtr++ == zoneID) {
                zoneID = ZONE_ID_REMOVED_MANUAL;
                //dputchar('*');
                break;
            }
        }
        *pvsCurrentZonePtr++ = zoneID;

        //dputchar(',');
    }
    *pvsCurrentZonePtr = ZONE_ID_LIST_END; // Terminate

    #ifdef ZONE_DEBUG
    if (runaway <= 0) {
        dputs("zone_InitCurrentPVS() Runaway");
    }
    #endif

    //dputchar('\n');
}

/**
 * Checks if the provided Zone ID is in the current PVS list or not.
 */
BOOL zone_CheckInCurrentPVSList(WORD zoneID) {
    WORD const* pvsCurrentZonePtr = zone_GetCurrentPVSBuffer();
    WORD nextZoneID;

    int runaway = PVS_TRAVERSE_LIMIT;

    while ((nextZoneID = *pvsCurrentZonePtr++) != ZONE_ID_LIST_END && runaway-- > 0) {
        if (zoneID == nextZoneID) {
            return TRUE;
        }
    }

    #ifdef ZONE_DEBUG
    if (runaway <= 0) {
        dputs("zone_CheckInCurrentPVSList() Runaway");
    }
    #endif

    return FALSE;
}

/**
 * Check if the zone is not already in the visited list. This version is used when building
 * the visited list which is not yet terminated by ZONE_ID_LIST_END and only needs to be
 * tested as far as the most recently added value.
 */
BOOL zone_CheckIsNotInVisitedPVSList(WORD zoneID, WORD const* endPtr) {
    WORD* visitedPVSPtr = zone_GetVisitedPVSBuffer();

    int runaway = PVS_TRAVERSE_LIMIT;

    while (visitedPVSPtr < endPtr && runaway-- > 0) {
        if (zoneID == *visitedPVSPtr++) {
            return FALSE;
        }
    }

    #ifdef ZONE_DEBUG
    if (runaway <= 0) {
        dputs("zone_CheckIsNotInVisitedPVSList() Runaway");
    }
    #endif

    return TRUE;
}

/**
 * For an input zone ID that is valid, returns either the same ID or ZONE_ID_REMOVED_AUTO if the ID
 * is not in the visited list.
 */
WORD zone_GetVisitedZoneID(WORD zoneID) {
    if (zone_IsValidZoneID(zoneID)) {
        WORD const* visitedPVSPtr = zone_GetVisitedPVSBuffer();
        WORD visitedZoneID;
        while ( (visitedZoneID = *visitedPVSPtr++) != ZONE_ID_LIST_END ) {
            if (zoneID == visitedZoneID) {
                return zoneID;
            }
        }
        return ZONE_ID_REMOVED_AUTO;
    }
    return zoneID;
}

/**
 * Travrses the set of connected zones via their explicit edge relationships in order to build
 * the list of zones in the original PVS that are still form a connected set.
 */
void zone_BuildVisitedPVS(Zone* zonePtr) {
    WORD* visitedPVSPtr  = zone_GetVisitedPVSBuffer();
    WORD  nextZoneID;

    // Starting at the current zone, add those that are accessible via the edges
    *visitedPVSPtr++ = zonePtr->z_ZoneID;
    *visitedPVSPtr   = ZONE_ID_LIST_END;

    WORD* nextPVSPtr = visitedPVSPtr;
    do {
        // Get the edge lists for the current zone and
        WORD const* edgeIndexPtr = zone_GetEdgeList(zonePtr);
        WORD edgeID;
        WORD zonesAdded;
        int runaway = PVS_TRAVERSE_LIMIT;

        //dprintf("\tEdges of %d: ", (int)zonePtr->z_ZoneID);

        do {
            zonesAdded = 0;

            int runaway2 = EDGE_TRAVERSE_LIMIT;

            // This loop may add multiple zones to the visited list, but we need to keep track of the first
            // that was added
            while (zone_IsValidEdgeID( (edgeID = *edgeIndexPtr++) ) && runaway2-- > 0) {

                //dprintf("%d", (int)edgeID);

                // If the edge joins a zone, e_JoinZoneID says which one, otherwhise it's negative.
                WORD joinZoneID = Lvl_ZoneEdgePtr_l[edgeID].e_JoinZoneID;
                if (
                    zone_IsValidZoneID(joinZoneID) &&
                    zone_CheckIsNotInVisitedPVSList(joinZoneID, visitedPVSPtr) &&
                    zone_CheckInCurrentPVSList(joinZoneID)
                ) {
                    *visitedPVSPtr++ = joinZoneID;
                    *visitedPVSPtr   = ZONE_ID_LIST_END;
                    ++zonesAdded;
                    //dprintf("%d [z:%d],", (int)edgeID, (int)joinZoneID);
                }
            }

            if (runaway2 <= 0) {
                dputs("zone_BuildVisitedPVS() Runaway 2");
                return;
            }

        } while (zonesAdded && runaway-- > 0);

        //dputchar('\n');
        if (runaway <= 0) {
            dputs("zone_BuildVisitedPVS() Runaway");
            return;
        }

        zonePtr = NULL;
        nextZoneID = *nextPVSPtr++;
        if (zone_IsValidZoneID(nextZoneID)) {
            zonePtr = Lvl_ZonePtrsPtr_l[nextZoneID];
        }

    } while (zonePtr);

    *visitedPVSPtr = ZONE_ID_LIST_END;

    // #ifdef ZONE_DEBUG
    // dprintf("Visited Zone List: ");
    // visitedPVSPtr  = zone_GetVisitedPVSBuffer();
    // do {
    //     nextZoneID = *visitedPVSPtr++;
    //     dprintf("%d,", nextZoneID);
    // } while (nextZoneID != ZONE_ID_LIST_END);
    // dputchar('\n');
    // #endif
}

/**
 * Uses the Visited PVS zone list data to amend the original PVS zone ID list and rewrites the
 * actual PVSRecord array for the zone by collapsing out the entries that were not in the amended
 * set of zones.
 */
void zone_RebuildCurrentPVS(Zone* zonePtr) {
    //dprintf("Rebuilding Current PVS for Zone %d: ", zonePtr->z_ZoneID);
    WORD* pvsCurrentZonePtr = zone_GetCurrentPVSBuffer();
    WORD nextZoneID;
    do {
        nextZoneID = zone_GetVisitedZoneID(*pvsCurrentZonePtr);
        //dprintf("%d,", nextZoneID);
        *pvsCurrentZonePtr++ = nextZoneID;
    } while (nextZoneID != ZONE_ID_LIST_END);
    //dputchar('\n');

    pvsCurrentZonePtr = zone_GetCurrentPVSBuffer();
    ZPVSRecord*       pvsWritePtr = zonePtr->z_PotVisibleZoneList;
    ZPVSRecord const* pvsReadPtr  = pvsWritePtr;

    // Collapse the original PVS list
    while ((nextZoneID = *pvsCurrentZonePtr++) != ZONE_ID_LIST_END) {
        if (nextZoneID >= 0) {
            if (pvsReadPtr != pvsWritePtr) {
                *pvsWritePtr = *pvsReadPtr;
            }
            ++pvsWritePtr;
        }
        ++pvsReadPtr;
    }
    pvsWritePtr->pvs_ZoneID = ZONE_ID_LIST_END;
}

/**
 * Apply the zone PVS Errata
 *
 * The errata is a stream of words that are varying length lists that each begin with the
 * zone ID the errata applies to, followed by a ZONE_ID_LIST_END terminated list of IDs of
 * potentially visible zones to be removed from the PVS list for the starting zone. The errata
 * list itself is terminated by ZONE_ID_LIST_END, i.e. the word list ends with a double
 * ZONE_ID_LIST_END pair.
 *
 */
void Zone_ApplyPVSErrata(REG(a0, WORD const* zonePVSErrataPtr)) {
    if (zonePVSErrataPtr) {
        dputs("Zone_ApplyPVSErrata()...");
        WORD numZones = 0;
        WORD zoneID;
        while (zone_IsValidZoneID(zoneID = *zonePVSErrataPtr++)) {
            Zone* zonePtr = Lvl_ZonePtrsPtr_l[zoneID];
            //dprintf("\tZone %d [%p]: ", (int)zoneID, zonePtr);
            WORD const* removeListPtr = zonePVSErrataPtr;
            while (zone_IsValidZoneID( (zoneID = *zonePVSErrataPtr++) )) {
                //dprintf("%d, ", (int)zoneID);
            }
            //dputchar('\n');
            zone_InitCurrentPVS(zonePtr, removeListPtr);
            zone_BuildVisitedPVS(zonePtr);
            zone_RebuildCurrentPVS(zonePtr);
            ++numZones;
        }
        dprintf("\tDone. %d PVS lists amended\n", (int)numZones);
    }
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
            if (zone_IsValidZoneID(Lvl_ZoneEdgePtr_l[edgeId].e_JoinZoneID)) {
                currentEdgePVSPtr->zep_EdgeIDList[edgeIndex++] = edgeId;
                dprintf("%d ", (int)edgeId);
            }
        }
        dputs("}");
        currentEdgePVSPtr = (ZEdgePVSHeader*)((UBYTE*)currentEdgePVSPtr + dataSize);
    }

    currentEdgePVSPtr = zonePtrBasePtr[0];
    for (WORD i = 0; i < currentEdgePVSPtr->zep_EdgeCount; ++i) {
        ZEdge const* edgePtr = Lvl_ZoneEdgePtr_l + currentEdgePVSPtr->zep_EdgeIDList[i];
        dprintf(
            "%p : [%d %d, %d, %d]\n",
            edgePtr,
            (int)edgePtr->e_XPos,
            (int)edgePtr->e_ZPos,
            (int)edgePtr->e_XLen,
            (int)edgePtr->e_ZLen
        );
    }
}

void Zone_FillEdgePVS() {

}

void Zone_FreeEdgePVS() {
    if (Lvl_PerEdgePVSDataPtr_l) {
        FreeVec(Lvl_PerEdgePVSDataPtr_l);
        Lvl_PerEdgePVSDataPtr_l = NULL;
        dputs("Zone_FreeEdgePVS()");
    }
}
