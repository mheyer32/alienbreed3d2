#include <stdio.h>
#include <proto/exec.h>
#include "defs.h"
#include "system.h"
#include "zone.h"
#include "zone_door.h"
#include "zone_inline.h"

/**
 * Initialise the compact door list array. The level contains a fixed number of door definitions but not
 * all doors are assigned to a valid zone since it is not necessary to use all available doors.
 */
void Zone_InitDoorList()
{
    for (WORD i = 0; i < LVL_MAX_DOOR_ZONES; ++i) {
        WORD zoneID = Lvl_DoorDataPtr_l[i].zdr_ZoneID;
        if (Zone_IsValidZoneID(zoneID)) {
            Zone_DoorList_vw[i] = zoneID;
        } else {
            Zone_DoorList_vw[i] = ZONE_ID_LIST_END;
        }
    }
}

WORD Zone_GetDoorID(WORD zoneID)
{
    if (Zone_IsValidZoneID(zoneID)) {
        for (WORD i = 0; i < LVL_MAX_DOOR_ZONES; ++i) {
            if (zoneID == Zone_DoorList_vw[i]) {
                return i;
            }
        }
    }
    return NOT_A_DOOR;
}
