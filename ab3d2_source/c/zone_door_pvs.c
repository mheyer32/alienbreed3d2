#include <stdio.h>
#include <proto/exec.h>
#include "defs.h"
#include "system.h"
#include "zone.h"
#include "zone_door.h"
#include "zone_inline.h"

void zone_DumpDoor(ZDoor const* door, int doorIndex)
{
    dprintf(
        "Door #%d d @%p [%d] {\n"
        "\tzdr_Bottom = %d\n"        //  0, 2
        "\tzdr_Top = %d\n"           //  2, 2
        "\tzdr_OpeningSpeed = %d\n"  //  4, 2
        "\tzdr_ClosingSpeed = %d\n"  //  6, 2
        "\tzdr_OpenDuration = %d\n", //  8, 2
        doorIndex,
        door,
        (int)sizeof(ZDoor),
        (int)door->zdr_Bottom,
        (int)door->zdr_Top,
        (int)door->zdr_OpeningSpeed,
        (int)door->zdr_ClosingSpeed,
        (int)door->zdr_OpenDuration
    );
    dprintf(
        "\tzdr_OpeningSoundFX = %d\n" // 10, 2
        "\tzdr_ClosingSoundFX = %d\n" // 12, 2
        "\tzdr_OpenedSoundFX = %d\n"  // 14, 2
        "\tzdr_ClosedSoundFX = %d\n", // 16, 2
        (int)door->zdr_OpeningSoundFX,
        (int)door->zdr_ClosingSoundFX,
        (int)door->zdr_OpenedSoundFX,
        (int)door->zdr_ClosedSoundFX
    );
    dprintf(
        "\tzdr_Word9  = %d\n"  // 18, 2 - something X coordinate related
        "\tzdr_Word10 = %d\n" // 20, 2 - something Z coordinate related
        "\tzdr_Word11 = %d [0x%04X]\n" // 22, 2
        "\tzdr_Word12 = %d [0x%04X]\n" // 24, 2
        "\tzdr_GraphicsOffset = %d\n",  // 26, 4
        (int)door->zdr_Word9,
        (int)door->zdr_Word10,
        (int)door->zdr_Word11, (unsigned)door->zdr_Word11,
        (int)door->zdr_Word12, (unsigned)door->zdr_Word12,
        (int)door->zdr_GraphicsOffset
    );
    dprintf(
        "\tzdr_ZoneID = %d\n"  // 30, 2
        "\tzdr_Word16 = %d [0x%04X]\n"  // 32, 2
        "\tzdr_RaiseConidtion = %d\n"  // 34, 2
        "\tzdr_LowerCondition = %d\n}\n", // 36, 2
        (int)door->zdr_ZoneID,
        (int)door->zdr_Word16, (unsigned)door->zdr_Word16,
        (int)door->zdr_RaiseCondition,// 34, 1
        (int)door->zdr_LowerCondition// 35, 1
    );
}

WORD zone_NumDoorDefs = 0;

/**
 * Initialise the compact door list array. The level contains a fixed number of door definitions but not
 * all doors are assigned to a valid zone since it is not necessary to use all available doors.
 *
 * Note that the door data doesn't contain any gaps, so if a level defines only 3 doors, no matter which
 * letter number is assigned, the indexes of the 3 doors will always be 0, 1, 2.
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
        WORD zoneID = doorDataPtr.door->zdr_ZoneID;
        if (Zone_IsValidZoneID(zoneID)) {
            //zone_DumpDoor(doorDataPtr.door, doorIndex);
            dprintf("Door %2d => Zone %3d\n", (int)doorIndex, (int)zoneID);
            Zone_DoorList_vw[doorIndex++] = zoneID;
            Zone_DoorMap_vb[zoneID >> 3] |= (1 << (zoneID & 7));
        }
        doorDataPtr.door++;
        while (*doorDataPtr.marker++ != END_OF_DOOR_WALL_LIST) {
            // skip over the wall data for the moment
        }
    }

    zone_NumDoorDefs = doorIndex;

    while (doorIndex < LVL_MAX_DOOR_ZONES) {
        Zone_DoorList_vw[doorIndex++] = ZONE_ID_LIST_END;
    }
}

/**
 * Returns the Door Index for a given zone. Uses the door map to quickly eliminate all the zones that are
 * not doors, before matching.
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
