#include "system.h"
#include "zone.h"
#include "zone_inline.h"
#include <proto/exec.h>
#include <stdio.h>

/**
 * zone_errata.c
 *
 * Handles the application of per zone errata data.
 */


/**
 * Returns a buffer holding a list of Zone ID values for the PVS of the Zone currently under
 * evaluation. This list is in the same order as the PVS ZPVSRecords. Entries in this list
 * that match the given errata list, the corresponding entry in the list will be set to
 * ZONE_ID_REMOVED_MANUAL. The list is terminated by ZONE_ID_LIST_END.
 */
static inline WORD* zone_GetCurrentPVSBuffer()
{
    return (WORD*)Sys_GetTemporaryWorkspace();
}

/**
 * Returns a buffer holding a list of the Zone ID values that have been visited by traversal
 * of the zones in the PVS via connected edges. This will exclude any zones that are disconnected
 * as a consequence of explicit removal of one or more entries.
 */
static inline WORD* zone_GetVisitedPVSBuffer()
{
    return ((WORD*)Sys_GetTemporaryWorkspace()) + 1024;
}

/**
 * Initialise the current Zone PVS buffer. We copy the list of Zone ID from the PVSRecord
 * tuples to our buffer and check each value against a list of zones to remove. This list is
 * termonated by a ZONE_ID_LIST_END value. Any matches from the PVSRecord data are replaced
 * with ZONE_ID_REMOVED_MANUAL in the current PVS buffer.
 */
void zone_InitCurrentPVS(Zone const* zonePtr, WORD const* removeListPtr)
{
    ZPVSRecord const* zonePVSPtr = zonePtr->z_PotVisibleZoneList;
    WORD* pvsCurrentZonePtr      = zone_GetCurrentPVSBuffer();
    WORD  zoneID;

    //dprintf("Building PVS List for Zone %d: ", (int)zonePtr->z_ZoneID);

    int runaway = PVS_TRAVERSE_LIMIT;
    while ((zoneID = zonePVSPtr->pvs_ZoneID) > ZONE_ID_LIST_END && runaway-- > 0) {

        //dprintf("%d", zoneID);

        ++zonePVSPtr;
        WORD const* removePtr = removeListPtr;
        while (removePtr && Zone_IsValidZoneID(*removePtr)) {
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
BOOL zone_CheckInCurrentPVSList(WORD zoneID)
{
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
BOOL zone_CheckIsNotInVisitedPVSList(WORD zoneID, WORD const* endPtr)
{
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
WORD zone_GetVisitedZoneID(WORD zoneID)
{
    if (Zone_IsValidZoneID(zoneID)) {
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
void zone_BuildVisitedPVS(Zone* zonePtr)
{
    WORD* visitedPVSPtr  = zone_GetVisitedPVSBuffer();
    WORD  nextZoneID;

    // Starting at the current zone, add those that are accessible via the edges
    *visitedPVSPtr++ = zonePtr->z_ZoneID;
    *visitedPVSPtr   = ZONE_ID_LIST_END;

    WORD* nextPVSPtr = visitedPVSPtr;
    do {
        // Get the edge lists for the current zone and
        WORD const* edgeIndexPtr = Zone_GetEdgeList(zonePtr);
        WORD edgeID;
        WORD zonesAdded;
        int runaway = PVS_TRAVERSE_LIMIT;

        //dprintf("\tEdges of %d: ", (int)zonePtr->z_ZoneID);

        do {
            zonesAdded = 0;

            int runaway2 = EDGE_TRAVERSE_LIMIT;

            // This loop may add multiple zones to the visited list, but we need to keep track of the first
            // that was added
            while (Zone_IsValidEdgeID( (edgeID = *edgeIndexPtr++) ) && runaway2-- > 0) {

                //dprintf("%d", (int)edgeID);

                // If the edge joins a zone, e_JoinZoneID says which one, otherwhise it's negative.
                WORD joinZoneID = Lvl_ZoneEdgePtr_l[edgeID].e_JoinZoneID;
                if (
                    Zone_IsValidZoneID(joinZoneID) &&
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
        if (Zone_IsValidZoneID(nextZoneID)) {
            zonePtr = Lvl_ZonePtrsPtr_l[nextZoneID];
        }

    } while (zonePtr);

    *visitedPVSPtr = ZONE_ID_LIST_END;
}

/**
 * Uses the Visited PVS zone list data to amend the original PVS zone ID list and rewrites the
 * actual PVSRecord array for the zone by collapsing out the entries that were not in the amended
 * set of zones.
 */
void zone_RebuildCurrentPVS(Zone* zonePtr)
{
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
void Zone_ApplyPVSErrata(REG(a0, WORD const* zonePVSErrataPtr))
{
    if (zonePVSErrataPtr) {
        dputs("Zone_ApplyPVSErrata()...");
        WORD numZones = 0;
        WORD zoneID;
        while (Zone_IsValidZoneID(zoneID = *zonePVSErrataPtr++)) {
            Zone* zonePtr = Lvl_ZonePtrsPtr_l[zoneID];
            //dprintf("\tZone %d [%p]: ", (int)zoneID, zonePtr);
            WORD const* removeListPtr = zonePVSErrataPtr;
            while (Zone_IsValidZoneID( (zoneID = *zonePVSErrataPtr++) )) {
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
