#ifndef ZONE_LIFTABLE_H
#define ZONE_LIFTABLE_H

#define LVL_MAX_DOOR_ZONES 16
#define LVL_MAX_LIFT_ZONES 16
#define NOT_A_LIFTABLE -1
#define END_OF_LIFTABLE_LIST 999
#define END_OF_LIFTABLE_WALL_LIST -1

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
    WORD  zl_Bottom;            //  0, 2
    WORD  zl_Top;               //  2, 2
    WORD  zl_OpeningSpeed;      //  4, 2
    WORD  zl_ClosingSpeed;      //  6, 2
    WORD  zl_OpenDuration;      //  8, 2
    WORD  zl_OpeningSoundFX;    // 10, 2
    WORD  zl_ClosingSoundFX;    // 12, 2
    WORD  zl_OpenedSoundFX;     // 14, 2
    WORD  zl_ClosedSoundFX;     // 16, 2
    Vec2W zl_SoundOrigin;       // 18, [2, 2]
    WORD  zl_EndOfTravel;       // 22, 2 For doors: zl_Bottom, for lifts: zl_Top
    WORD  zl_Word12;            // 24, 2 TODO - determone purpose
    LONG  zl_GraphicsOffset;    // 26, 4
    WORD  zl_ZoneID;            // 30, 2
    WORD  zl_Word16;            // 32, 2 TODO - determine purpose
    UBYTE zl_RaiseCondition;    // 34, 1
    UBYTE zl_LowerCondition;    // 35, 1
}  ASM_ALIGN(sizeof(WORD)) ZLiftable;

/**
 * Data stream: The ZLiftable definition, is followed by 2N ZLiftableWall records, followed by a -1 word
 * that represents the end of the door wall list.
 *
 * The door list itself is terminated with the magic number 999
 *
 * [{ ZLiftable, ZLiftableWall[N*2], -1 }, { ZLiftable, ZLiftableWall[N*2], -1 }..., 999]
 */
typedef struct {
    WORD  zlw_EdgeID;         //  0, 2
    LONG  zlw_GraphicsOffset; //  2, 4
    LONG  zlw_Long1;          //  6, 4 - TODO - Something to do with the vertical texture displacement?
} ASM_ALIGN(sizeof(WORD)) ZLiftableWall;



/**
 * Simple structure for read-only door data stream navigation
 */
typedef union {
    WORD          const* marker;
    ZLiftable     const* data;
    ZLiftable*    dataInit; // Dirty hack to permit patching of data durng init.
    ZLiftableWall const* wall;
} LiftableDataPtr;

extern WORD* Lvl_DoorDataPtr_l;
extern WORD* Lvl_LiftDataPtr_l;

/**
 * List of the ZoneID for each door. Any door not associated to a zone is assigned ID -1.
 */
extern WORD Zone_DoorList_vw[LVL_MAX_DOOR_ZONES];

/**
 * List of the ZoneID for each door. Any door not associated to a zone is assigned ID -1.
 */
extern WORD Zone_LiftList_vw[LVL_MAX_LIFT_ZONES];

/**
 * Bitmap of Zone IDs, where a set bit indicates the corresponding zone has a door.
 */
extern UBYTE Zone_DoorMap_vb[];

/**
 * Bitmap of Zones IDs, where a set bit indicates the corresponding zone has a lift.
 */
extern UBYTE Zone_LiftMap_vb[];

/**
 * Get the Door ID for the given ZoneID. Returns NOT_A_LIFTABLE if the zone is not a door.
 */
WORD Zone_GetDoorID(WORD zoneID);

/**
 * Get the Lift ID for the given ZoneID. Returns NOT_A_LIFTABLE if the zone is not a lift.
 */
WORD Zone_GetLiftID(WORD zoneID);

/**
 * Level start initialisation routines
 */
void Zone_InitDoorList(void);
void Zone_InitLiftList(void);

#endif // ZONE_DOOR_H
