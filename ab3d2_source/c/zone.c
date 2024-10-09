#include "system.h"
#include "zone.h"
#include <stdio.h>
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

    printf("Building PVS List for Zone %d\n\t", (int)zonePtr->z_ZoneID);

    int runaway = 64;

    while ((zoneID = zonePVSPtr->pvs_ZoneID) > ZONE_ID_LIST_END && runaway-- > 0) {
        printf("%d", zoneID);

        ++zonePVSPtr;
        WORD const* removePtr = removeListPtr;
        while (removePtr && zone_IsValidID(*removePtr)) {
            if (*removePtr++ == zoneID) {
                zoneID = ZONE_ID_REMOVED_MANUAL;
                putchar('*');
                break;
            }
        }
        *pvsCurrentZonePtr++ = zoneID;
        putchar(',');
    }
    *pvsCurrentZonePtr = ZONE_ID_LIST_END; // Terminate

    puts("End");

    if (runaway <= 0) {
        puts("\tRunaway");
    }
}

/**
 * Checks if the provided Zone ID is in the current PVS list or not.
 */
BOOL zone_CheckInCurrentPVSList(WORD zoneID) {
    WORD const* pvsCurrentZonePtr = zone_GetCurrentPVSBuffer();
    WORD nextZoneId;

    int runaway = 16;

    while ((nextZoneId = *pvsCurrentZonePtr++) != ZONE_ID_LIST_END && runaway-- > 0) {
        if (zoneID == nextZoneId) {
            return TRUE;
        }
    }

    if (runaway <= 0) {
        puts("zone_CheckInCurrentPVSList()\n\tRunaway");
    }

    return FALSE;
}

/**
 * Check if the zone is not already in the visited list.
 */
BOOL zone_CheckIsNotInVisitedPVSList(WORD zoneID, WORD const* endPtr) {
    WORD* visitedPVSPtr = zone_GetVisitedPVSBuffer();

    int runaway = 16;

    while (visitedPVSPtr < endPtr && runaway-- > 0) {
        if (zoneID == *visitedPVSPtr++) {
            return FALSE;
        }
    }

    if (runaway <= 0) {
        puts("zone_CheckIsNotInVisitedPVSList()\n\tRunaway");
    }

    return TRUE;
}


/**
 * This is the main analysis step. Starting with our Zone of interest, we explore the edge list
 * and each edge that connects to a zone that's not in our current pvs list we add it to the
 * list of zones to visit, if not already in that list.
 */
void Zone_ProcessPVS(REG(a0, Zone* zonePtr)) {
    // Create the initial zone list for the PVS
    WORD test[] = {7, 8, 129, ZONE_ID_LIST_END}; // simulate zone 2 as being removed

    zone_InitCurrentPVS(zonePtr, test);

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
        int runaway = 16;

        printf("Testing edges of zone %d\n\t", (int)zonePtr->z_ZoneID);

        do {
            zonesAdded = 0;

            int runaway2 = 16;

            // This loop may add multiple zones to the visited list, but we need to keep track of the first
            // that was added
            while (zone_IsValidID( (edgeID = *edgeIndexPtr++) ) && runaway2-- > 0) {

                printf("%d", (int)edgeID);

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
                    printf(" [z:%d]", (int)joinZoneID);
                }
                printf(", ");
            }

            if (runaway2 <= 0) {
                puts("Runaway 2");
                return;
            }

        } while (zonesAdded && runaway-- > 0);
        puts("\n");

        if (runaway <= 0) {
            puts("\tRunaway");
            return;
        }

        zonePtr = NULL;
        nextZoneId = *nextPVSPtr++;
        if (zone_IsValidID(nextZoneId)) {
            zonePtr = Lvl_ZonePtrsPtr_l[nextZoneId];
        }

    } while (zonePtr);

    *visitedPVSPtr = ZONE_ID_LIST_END;

    visitedPVSPtr = zone_GetVisitedPVSBuffer();

    puts("Visited Zone List\n\t");
    do {
        nextZoneId = *visitedPVSPtr++;
        printf("%d, ", nextZoneId);

    } while (nextZoneId != ZONE_ID_LIST_END);

    puts("\nEnd\n");
}
