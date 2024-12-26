#include <stdio.h>
#include <proto/exec.h>
#include "defs.h"
#include "system.h"
#include "zone.h"
#include "zone_door.h"
#include "zone_inline.h"

void zone_DumpDoor(ZDoor const* door)
{

    // dprintf(
    //     "Door @%p [%d] {\n"
    //     "\tzdr_Bottom = %d\n"        //  0, 2
    //     "\tzdr_Top = %d\n"           //  2, 2
    //     "\tzdr_OpeningSpeed = %d\n"  //  4, 2
    //     "\tzdr_ClosingSpeed = %d\n"  //  6, 2
    //     "\tzdr_OpenDuration = %d\n", //  8, 2
    //     door,
    //     (int)sizeof(ZDoor),
    //     (int)door->zdr_Bottom,
    //     (int)door->zdr_Top,
    //     (int)door->zdr_OpeningSpeed,
    //     (int)door->zdr_ClosingSpeed,
    //     (int)door->zdr_OpenDuration
    // );
    // dprintf(
    //     "\tzdr_OpeningSoundFX = %d\n" // 10, 2
    //     "\tzdr_ClosingSoundFX = %d\n" // 12, 2
    //     "\tzdr_OpenedSoundFX = %d\n"  // 14, 2
    //     "\tzdr_ClosedSoundFX = %d\n", // 16, 2
    //     (int)door->zdr_OpeningSoundFX,
    //     (int)door->zdr_ClosingSoundFX,
    //     (int)door->zdr_OpenedSoundFX,
    //     (int)door->zdr_ClosedSoundFX
    // );
    // dprintf(
    //     "\tzdr_Word9 = %d\n"  // 18, 2 - something X coordinate related
    //     "\tzdr_Word10 = %d\n" // 20, 2 - something Z coordinate related
    //     "\tzdr_Word11 = %d\n" // 22, 2
    //     "\tzdr_Word12 = %d\n" // 24, 2
    //     "\tzdr_GraphicsOffset = %d\n",  // 26, 4
    //     (int)door->zdr_Word9,
    //     (int)door->zdr_Word10,
    //     (int)door->zdr_Word11,
    //     (int)door->zdr_Word12,
    //     (int)door->zdr_GraphicsOffset
    // );
    // dprintf(
    //     "\tzdr_ZoneID = %d\n"  // 30, 2
    //     "\tzdr_Word16 = %d\n"  // 32, 2
    //     "\tzdr_Word17 = %d\n"  // 34, 2
    //     "\tzdr_Word18 = %d\n}\n", // 36, 2
    //     (int)door->zdr_ZoneID,
    //     (int)door->zdr_Word16,
    //     (int)door->zdr_Word17,
    //     (int)door->zdr_Word18
    // );
}

/**
 * Initialise the compact door list array. The level contains a fixed number of door definitions but not
 * all doors are assigned to a valid zone since it is not necessary to use all available doors.
 */
void Zone_InitDoorList()
{
    for (WORD i = 0; i < Lvl_NumZones_w/8; ++i) {
        Zone_DoorMap_vb[i] = 0;
    }

    WORD const* doorDataRawPtr = (WORD const*)Lvl_DoorDataPtr_l;

    dputs("Door Data");

    int i = 0;

    while (*doorDataRawPtr != 999) {
        dprintf(
            "\t%3d: %04X %d\n",
            i,
            (ULONG) *((UWORD const*)doorDataRawPtr),
            (int) *doorDataRawPtr
        );
        ++doorDataRawPtr;
        i += 2;
    }
    dprintf("Size %d\n", i);

    // for (WORD i = 0; i < LVL_MAX_DOOR_ZONES; ++i) {
    //     zone_DumpDoor(&Lvl_DoorDataPtr_l[i]);
    //     WORD zoneID = Lvl_DoorDataPtr_l[i].zdr_ZoneID;
    //     if (Zone_IsValidZoneID(zoneID)) {
    //         Zone_DoorList_vw[i] = zoneID;
    //         Zone_DoorMap_vb[zoneID >> 3] |= (1 << (zoneID & 7));
    //         //dprintf("Door %d: Zone: %d\n", (int)i, (int)zoneID);
    //     } else {
    //         Zone_DoorList_vw[i] = ZONE_ID_LIST_END;
    //         //dprintf("Door %d: Unused [Zone %d]\n", (int)i, (int)zoneID);
    //     }
    // }

}

/**
 * Returns the Door Index for a given zone. Uses the door map to quickly eliminate all the zones that are
 * not doors, before matching.
 */
WORD Zone_GetDoorID(WORD zoneID)
{
    if (Zone_IsValidZoneID(zoneID)) {
        if ( Zone_DoorMap_vb[zoneID >> 3] & (1 << (zoneID & 7)) ) {
            for (WORD i = 0; i < LVL_MAX_DOOR_ZONES; ++i) {
                if (zoneID == Zone_DoorList_vw[i]) {
                    return i;
                }
            }
        }
    }
    return NOT_A_DOOR;
}
