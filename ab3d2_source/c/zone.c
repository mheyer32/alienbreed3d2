#include "system.h"
#include "zone.h"
#include <stdio.h>

#ifdef ZONE_DEBUG
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
static WORD zone_PVSCurrentZoneIDs[256];
static WORD zone_PVSVisitedZoneIDs[256];

/**
 * Returns a buffer holding a list of Zone ID values for the PVS of the Zone currently under
 * evaluation. This list is in the same order as the PVS ZPVSRecords. Entries in this list
 * that match the given errata list, the corresponding entry in the list will be set to
 * ZONE_ID_REMOVED_MANUAL. The list is terminated by ZONE_ID_LIST_END.
 */
static __inline WORD* zone_GetCurrentPVSBuffer() {
    return zone_PVSCurrentZoneIDs;
}

/**
 * Returns a buffer holding a list of the Zone ID values
 */
static __inline WORD* zone_GetVisitedPVSBuffer() {
    return zone_PVSVisitedZoneIDs;
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

    dprintf("Building PVS List for Zone %d: ", (int)zonePtr->z_ZoneID);

    int runaway = PVS_TRAVERSE_LIMIT;
    while ((zoneID = zonePVSPtr->pvs_ZoneID) > ZONE_ID_LIST_END && runaway-- > 0) {

        dprintf("%d", zoneID);

        ++zonePVSPtr;
        WORD const* removePtr = removeListPtr;
        while (removePtr && zone_IsValidID(*removePtr)) {
            if (*removePtr++ == zoneID) {
                zoneID = ZONE_ID_REMOVED_MANUAL;
                dputchar('*');
                break;
            }
        }
        *pvsCurrentZonePtr++ = zoneID;

        dputchar(',');
    }
    *pvsCurrentZonePtr = ZONE_ID_LIST_END; // Terminate

    #ifdef ZONE_DEBUG
    if (runaway <= 0) {
        dputs("\tRunaway");
    }
    #endif

    dputchar('\n');
}

/**
 * Checks if the provided Zone ID is in the current PVS list or not.
 */
BOOL zone_CheckInCurrentPVSList(WORD zoneID) {
    WORD const* pvsCurrentZonePtr = zone_GetCurrentPVSBuffer();
    WORD nextZoneId;

    int runaway = PVS_TRAVERSE_LIMIT;

    while ((nextZoneId = *pvsCurrentZonePtr++) != ZONE_ID_LIST_END && runaway-- > 0) {
        if (zoneID == nextZoneId) {
            return TRUE;
        }
    }

    #ifdef ZONE_DEBUG
    if (runaway <= 0) {
        dputs("zone_CheckInCurrentPVSList()\n\tRunaway");
    }
    #endif

    return FALSE;
}

/**
 * Check if the zone is not already in the visited list.
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
        dputs("zone_CheckIsNotInVisitedPVSList()\n\tRunaway");
    }
    #endif

    return TRUE;
}

void zone_BuildVisitedPVS(Zone* zonePtr) {
    WORD* visitedPVSPtr  = zone_GetVisitedPVSBuffer();
    WORD  nextZoneId;

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

        dprintf("\tEdges of %d: ", (int)zonePtr->z_ZoneID);

        do {
            zonesAdded = 0;

            int runaway2 = EDGE_TRAVERSE_LIMIT;

            // This loop may add multiple zones to the visited list, but we need to keep track of the first
            // that was added
            while (zone_IsValidID( (edgeID = *edgeIndexPtr++) ) && runaway2-- > 0) {

                dprintf("%d", (int)edgeID);

                // If the edge joins a zone, e_JoinZoneID says which one, otherwhise it's negative.
                WORD joinZoneID = Lvl_ZoneEdgePtr_l[edgeID].e_JoinZoneID;
                if (
                    zone_IsValidID(joinZoneID) &&
                    zone_CheckIsNotInVisitedPVSList(joinZoneID, visitedPVSPtr) &&
                    zone_CheckInCurrentPVSList(joinZoneID)
                ) {
                    *visitedPVSPtr++ = joinZoneID;
                    *visitedPVSPtr   = ZONE_ID_LIST_END;
                    ++zonesAdded;
                    dprintf(" [z:%d]", (int)joinZoneID);
                }
                dputchar(',');
            }

            if (runaway2 <= 0) {
                dputs("Runaway 2");
                return;
            }

        } while (zonesAdded && runaway-- > 0);

        dputchar('\n');
        if (runaway <= 0) {
            dputs("\tRunaway");
            return;
        }

        zonePtr = NULL;
        nextZoneId = *nextPVSPtr++;
        if (zone_IsValidID(nextZoneId)) {
            zonePtr = Lvl_ZonePtrsPtr_l[nextZoneId];
        }

    } while (zonePtr);

    *visitedPVSPtr = ZONE_ID_LIST_END;

    #ifdef ZONE_DEBUG
    dprintf("Visited Zone List: ");
    visitedPVSPtr  = zone_GetVisitedPVSBuffer();
    do {
        nextZoneId = *visitedPVSPtr++;
        dprintf("%d,", nextZoneId);
    } while (nextZoneId != ZONE_ID_LIST_END);
    dputchar('\n');
    #endif
}

/**
 * This is the main analysis step. Starting with our Zone of interest, we explore the edge list
 * and each edge that connects to a zone that's not in our current pvs list we add it to the
 * list of zones to visit, if not already in that list.
 */
void Zone_ProcessPVS(REG(a0, Zone* zonePtr)) {
    // Create the initial zone list for the PVS
    //WORD test[] = {7, 8, 129, ZONE_ID_LIST_END}; // simulate zone 2 as being removed

    zone_InitCurrentPVS(zonePtr, NULL);
    zone_BuildVisitedPVS(zonePtr);
}
