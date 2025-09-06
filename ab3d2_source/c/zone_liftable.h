#ifndef ZONE_DOOR_H
#define ZONE_DOOR_H

#define LVL_MAX_DOOR_ZONES 16
#define NOT_A_DOOR -1
#define END_OF_DOOR_LIST 999
#define END_OF_DOOR_WALL_LIST -1

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
 * ZLiftable defintion. Applies to both Door and Lift, which share the same basic
 * data structure but are handled differently.
 *
 * For Doors, it is the ceiling that moves between the Zone floor and ceiling extents.
 * For Lifts, it is the floor that moves between the Zone floor and upper lift extents.
 *
 * Doors have the property that they are either fully closed or not. Lifts are more
 * complicated in that junctions with adjoining sones may or may not be open.
 */
typedef struct {
    WORD  zl_Bottom;//  0, 2
    WORD  zl_Top;//  2, 2
    WORD  zl_OpeningSpeed;//  4, 2
    WORD  zl_ClosingSpeed;//  6, 2
    WORD  zl_OpenDuration;//  8, 2
    WORD  zl_OpeningSoundFX;// 10, 2
    WORD  zl_ClosingSoundFX;// 12, 2
    WORD  zl_OpenedSoundFX;// 14, 2
    WORD  zl_ClosedSoundFX;// 16, 2
    WORD  zl_Word9;// 18, 2 - something X coordinate related
    WORD  zl_Word10;// 20, 2 - something Z coordinate related
    WORD  zl_Word11;// 22, 2
    WORD  zl_Word12;// 24, 2
    LONG  zl_GraphicsOffset;// 26, 4
    WORD  zl_ZoneID;// 30, 2
    WORD  zl_Word16;// 32, 2
    UBYTE zl_RaiseCondition;// 34, 1
    UBYTE zl_LowerCondition;// 35, 1
}  ASM_ALIGN(sizeof(WORD)) ZLiftable;

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
 * [{ ZLiftable, ZDoorWall[N*2], -1 }, { ZLiftable, ZDoorWall[N*2], -1 }..., 999]
 */

/**
 * Simple structure for read-only door data stream navigation
 */
typedef union {
    WORD      const* marker;
    ZLiftable const* door;
    ZDoorWall const* wall;
} DoorDataPtr;

extern WORD* Lvl_DoorDataPtr_l;

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
