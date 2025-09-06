#include <stdio.h>
#include <proto/exec.h>
#include "defs.h"
#include "system.h"
#include "zone.h"
#include "zone_liftable.h"
#include "zone_inline.h"

void zone_DumpLiftable(ZLiftable const* liftable, int index, char const* type)
{
    dprintf(
        "%s #%d d @%p [%d] {\n"
        "\tzl_Bottom = %d\n"        //  0, 2
        "\tzl_Top = %d\n"           //  2, 2
        "\tzl_OpeningSpeed = %d\n"  //  4, 2
        "\tzl_ClosingSpeed = %d\n"  //  6, 2
        "\tzl_OpenDuration = %d\n", //  8, 2
        type,
        index,
        liftable,
        (int)sizeof(ZLiftable),
        (int)liftable->zl_Bottom,
        (int)liftable->zl_Top,
        (int)liftable->zl_OpeningSpeed,
        (int)liftable->zl_ClosingSpeed,
        (int)liftable->zl_OpenDuration
    );
    dprintf(
        "\tzl_OpeningSoundFX = %d\n" // 10, 2
        "\tzl_ClosingSoundFX = %d\n" // 12, 2
        "\tzl_OpenedSoundFX = %d\n"  // 14, 2
        "\tzl_ClosedSoundFX = %d\n", // 16, 2
        (int)liftable->zl_OpeningSoundFX,
        (int)liftable->zl_ClosingSoundFX,
        (int)liftable->zl_OpenedSoundFX,
        (int)liftable->zl_ClosedSoundFX
    );
    dprintf(
        "\tzl_Word9  = %d\n"  // 18, 2 - something X coordinate related
        "\tzl_Word10 = %d\n" // 20, 2 - something Z coordinate related
        "\tzl_Word11 = %d [0x%04X]\n" // 22, 2
        "\tzl_Word12 = %d [0x%04X]\n" // 24, 2
        "\tzl_GraphicsOffset = %d\n",  // 26, 4
        (int)liftable->zl_Word9,
        (int)liftable->zl_Word10,
        (int)liftable->zl_Word11, (unsigned)liftable->zl_Word11,
        (int)liftable->zl_Word12, (unsigned)liftable->zl_Word12,
        (int)liftable->zl_GraphicsOffset
    );
    dprintf(
        "\tzl_ZoneID = %d\n"  // 30, 2
        "\tzl_Word16 = %d [0x%04X]\n"  // 32, 2
        "\tzl_RaiseConidtion = %d\n"  // 34, 2
        "\tzl_LowerCondition = %d\n}\n", // 36, 2
        (int)liftable->zl_ZoneID,
        (int)liftable->zl_Word16, (unsigned)liftable->zl_Word16,
        (int)liftable->zl_RaiseCondition,// 34, 1
        (int)liftable->zl_LowerCondition// 35, 1
    );
}

/**
 * Number of doors in the level
 */
static WORD zone_NumDoorDefs = 0;

/**
 * Initialise the compact door list array. The level contains a fixed number of door definitions but not
 * all doors are assigned to a valid zone since it is not necessary to use all available doors.
 *
 * Note that the door data doesn't contain any gaps, so if a level defines only 3 doors, no matter which
 * letter number is assigned, the indexes of the 3 doors will always be 0, 1, 2.
 *
 * We construct the list and also set the zone_NumDoorDefs
 */
void Zone_InitDoorList()
{
    dprintf("Zone_InitDoorList()\n");
    for (WORD i = 0; i < Lvl_NumZones_w/8; ++i) {
        Zone_DoorMap_vb[i] = 0;
    }

    DoorDataPtr doorDataPtr;
    doorDataPtr.marker = Lvl_DoorDataPtr_l;

    WORD doorIndex = 0;
    while (*doorDataPtr.marker != END_OF_DOOR_LIST && doorIndex < LVL_MAX_DOOR_ZONES) {
        WORD zoneID = doorDataPtr.door->zl_ZoneID;
        if (Zone_IsValidZoneID(zoneID)) {
            //zone_DumpLiftable(doorDataPtr.door, doorIndex, "Door");
            dprintf("Door %2d => Zone %3d\n", (int)doorIndex, (int)zoneID);
            Zone_DoorList_vw[doorIndex++] = zoneID;
            Zone_DoorMap_vb[zoneID >> 3] |= (1 << (zoneID & 7));
        }
        doorDataPtr.door++;
        while (*doorDataPtr.marker++ != END_OF_DOOR_WALL_LIST) {
            // skip over the wall data for the moment
        }
    }

    // Record the actual door count
    zone_NumDoorDefs = doorIndex;

    // Make sure the rest of the list is initialised with
    while (doorIndex < LVL_MAX_DOOR_ZONES) {
        Zone_DoorList_vw[doorIndex++] = ZONE_ID_LIST_END;
    }
}

/**
 * Returns the Door Index for a given zone. Uses the door map to quickly eliminate all the zones that are
 * not doors, before attempting to match one of the entries. Nothing clever, just a linear search.
 */
WORD Zone_GetDoorID(WORD zoneID)
{
    if (Zone_IsDoor(zoneID)) {
        for (WORD i = 0; i < zone_NumDoorDefs; ++i) {
            if (zoneID == Zone_DoorList_vw[i]) {
                return i;
            }
        }
    }
    return NOT_A_DOOR;
}
