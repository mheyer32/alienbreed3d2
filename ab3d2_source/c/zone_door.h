#ifndef ZONE_DOOR_H
#define ZONE_DOOR_H

#define LVL_MAX_DOOR_ZONES 16
#define NOT_A_DOOR -1

/**
 * TODO - Figure out the nameless fields
 */

typedef struct {
    UWORD zdr_Bottom;//  0, 2
    UWORD zdr_Top;//  2, 2
    UWORD zdr_OpeningSpeed;//  4, 2
    UWORD zdr_ClosingSpeed;//  6, 2
    UWORD zdr_OpenDuration;//  8, 2
    UWORD zdr_OpeningSoundFX;// 10, 2
    UWORD zdr_ClosingSoundFX;// 12, 2
    UWORD zdr_OpenedSoundFX;// 14, 2
    UWORD zdr_ClosedSoundFX;// 16, 2
    UWORD zdr_Word9;// 18, 2 - something X coordinate related
    UWORD zdr_Word10;// 20, 2 - something Z coordinate related
    UWORD zdr_Word11;// 22, 2
    UWORD zdr_Word12;// 24, 2
    UWORD zdr_Long;// 26, 4
    UWORD zdr_ZoneID;// 30, 2
    UWORD zdr_Word16;// 32, 2
    UWORD zdr_Word17;// 34, 2
    UWORD zdr_Word18;// 36, 2
}  ASM_ALIGN(sizeof(WORD)) ZDoor;


extern ZDoor* Lvl_DoorDataPtr_l;

/**
 * List of the ZoneID for each door. Any door not associated to a zone is assigned ID -1.
 */
extern WORD Zone_DoorList_vw[LVL_MAX_DOOR_ZONES];

void Zone_InitDoorList(void);

/**
 * Get the Door ID for the given ZoneID. Returns NOT_A_DOOR if the zone is not a door.
 */
WORD Zone_GetDoorID(WORD zoneID);

#endif // ZONE_DOOR_H
