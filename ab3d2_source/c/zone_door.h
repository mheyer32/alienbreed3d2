#ifndef ZONE_DOOR_H
#define ZONE_DOOR_H

#define LVL_MAX_DOOR_ZONES 16
#define NOT_A_DOOR -1

typedef enum {
    DOOR_RAISE_PLAYER_USE   = 0,
    DOOR_RAISE_PLAYER_TOUCH = 1,
    DOOR_RAISE_BULLET_TOUCH = 2,
    DOOR_RAISE_ALIEN_TOUCH  = 3,
    DOOR_RAISE_ON_TIMEOUT   = 4,
    DOOR_RAISE_NEVER        = 5,
} ASM_ALIGN(sizeof(UBYTE)) DoorRaise;


typedef enum {
    DOOR_LOWER_ON_TIMEOUT = 0,
    DOOR_LOWER_NEVER      = 1,
} ASM_ALIGN(sizeof(UBYTE)) DoorLower;

/**
 */
typedef struct {
    WORD  zdr_Bottom;//  0, 2
    WORD  zdr_Top;//  2, 2
    WORD  zdr_OpeningSpeed;//  4, 2
    WORD  zdr_ClosingSpeed;//  6, 2
    WORD  zdr_OpenDuration;//  8, 2
    WORD  zdr_OpeningSoundFX;// 10, 2
    WORD  zdr_ClosingSoundFX;// 12, 2
    WORD  zdr_OpenedSoundFX;// 14, 2
    WORD  zdr_ClosedSoundFX;// 16, 2
    WORD  zdr_Word9;// 18, 2 - something X coordinate related
    WORD  zdr_Word10;// 20, 2 - something Z coordinate related
    WORD  zdr_Word11;// 22, 2
    WORD  zdr_Word12;// 24, 2
    LONG  zdr_GraphicsOffset;// 26, 4
    WORD  zdr_ZoneID;// 30, 2
    WORD  zdr_Word16;// 32, 2
    UBYTE zdr_RaiseCondition;// 34, 1
    UBYTE zdr_LowerCondition;// 35, 1
}  ASM_ALIGN(sizeof(WORD)) ZDoor;

/**
 * TODO - Figure this out. There are two of these records per raise wall
 */
typedef struct {
    WORD  zdw_EdgeID;         //  0, 2
    LONG  zdw_GraphicsOffset; //  2, 4
    LONG  zdw_Long1;          //  6, 4 - Something to do with the vertical texture displacement?
} ASM_ALIGN(sizeof(WORD)) ZDoorWall;

/**
 * Data stream: The Door definition, is followed by 2N ZDoorWall records, followed by a -1 word
 * that represents the end of the door wall list.
 *
 * The door list itself is terminated with the magic number 999
 *
 * [{ ZDoor, ZDoorWall[N*2], -1 }, { ZDoor, ZDoorWall[N*2], -1 }..., 999]
 */



extern ZDoor* Lvl_DoorDataPtr_l;

/**
 * List of the ZoneID for each door. Any door not associated to a zone is assigned ID -1.
 */
extern WORD Zone_DoorList_vw[LVL_MAX_DOOR_ZONES];

/**
 * Bitmap of zones, where a set bit indicates the corresponding zone has a door.
 */
extern UBYTE Zone_DoorMap_vb[];

void Zone_InitDoorList(void);

/**
 * Get the Door ID for the given ZoneID. Returns NOT_A_DOOR if the zone is not a door.
 */
WORD Zone_GetDoorID(WORD zoneID);

#endif // ZONE_DOOR_H
