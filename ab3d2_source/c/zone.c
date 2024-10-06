#include "system.h"
#include "zone.h"

/**
 * TODO these should be allocated dynamically or reserved from the general workspace buffer
 */
static WORD zone_PVSCurrentZoneIDs[256];
static WORD zone_PVSVisitedZoneIDs[256];


enum {
    ZONE_ID_LIST_END       = -1,
    ZONE_ID_REMOVED_MANUAL = -2,
    ZONE_ID_REMOVED_AUTO   = -3,
};

static __inline WORD* zone_GetCurrentPVSBuffer() {
    return zone_PVSCurrentZoneIDs;
}

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
    WORD  zoneId;
    while ((zoneId = zonePVSPtr->pvs_Zone) > ZONE_ID_LIST_END) {
        WORD const* removePtr = removeListPtr;
        while (removePtr && *removePtr >= 0) {
            if (*removePtr++ == zoneId) {
                zoneId = ZONE_ID_REMOVED_MANUAL;
                break;
            }
        }
        *pvsCurrentZonePtr++ = zoneId;
    }
    *pvsCurrentZonePtr = ZONE_ID_LIST_END; // Terminate
}

/**
 * Checks if the provided Zone ID is in the current PVS list or not.
 */
BOOL zone_CheckInCurrentPVSList(WORD zoneId) {
    WORD const* pvsCurrentZonePtr = zone_GetCurrentPVSBuffer();
    WORD nextZoneId;
    while ((nextZoneId = *pvsCurrentZonePtr++) != ZONE_ID_LIST_END) {
        if (zoneId == nextZoneId) {
            return TRUE;
        }
    }
    return FALSE;
}

/**
 * Check if the zone is not already in the visited list.
 */
BOOL zone_CheckIsNotInVisitedPVSList(WORD zoneId, WORD const* endPtr) {
    WORD* visitedPVSPtr = zone_GetVisitedPVSBuffer();
    while (visitedPVSPtr < endPtr) {
        if (zoneId == *visitedPVSPtr++) {
            return FALSE;
        }
    }
    return TRUE;
}

void Zone_ProcessPVS(REG(a0, Zone* zonePtr)) {
    // Create the initial zone list for the PVS
    zone_InitCurrentPVS(zonePtr, NULL);

    WORD* visitedPVSPtr = zone_GetVisitedPVSBuffer();

    // Get the edge lists for the current zone and
    WORD const* edgeIndexPtr = zone_GetEdgeList(zonePtr);
    WORD edgeId;
    BOOL zonesAdded;
    do {
        zonesAdded = FALSE;
        while ((edgeId = *edgeIndexPtr++) >= 0) {
            // If the edge joins a zone, e_JoinZone says which one, otherwhise it's negative.
            WORD joinZoneId = Lvl_ZoneEdgePtr_l[edgeId].e_JoinZone;
            if (
                joinZoneId >= 0 &&
                zone_CheckInCurrentPVSList(joinZoneId) &&
                zone_CheckIsNotInVisitedPVSList(joinZoneId, visitedPVSPtr)
            ) {
                *visitedPVSPtr++ = joinZoneId;
                zonesAdded = TRUE;
            }
        }
    } while (zonesAdded);
}
