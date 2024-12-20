#ifndef PLAYER_H
#define PLAYER_H

#include "math25d.h"

/*
 * These structures are managed by the assembler side and the alignment constraints are to preven the compiler
 * from padding them further for alignment purposes. It does not mean that the structures themselves are only
 * aligned to a 2 byte boundary,
 */
typedef struct {
    /* Note that we have separate named fields here, but we regard the struct as equivalent to UWORD[]*/
    UWORD ic_Health;
    UWORD ic_JetpackFuel;
    UWORD ic_AmmoCounts[NUM_BULLET_DEFS];
} ASM_ALIGN(sizeof(WORD)) InventoryConsumables;

typedef struct {
    /* Note that we have separate named fields here, but we regard the struct as equivalent to UWORD[]*/
    UWORD ii_Shield;
    UWORD ii_Jetpack;
    UWORD ii_Weapons[NUM_GUN_DEFS];
} ASM_ALIGN(sizeof(WORD))  InventoryItems;

typedef struct {
    InventoryConsumables inv_Consumables;
    InventoryItems       inv_Items;
} ASM_ALIGN(sizeof(WORD))  Inventory;

// Player Definition (runtime)
typedef struct {
    // Long fields
    ObjBase*    plr_ObjectPtr; //   0, 4

    LONG        plr_XOff; //  4, 4 - sometimes accessed as w - todo understand real size
    LONG        plr_YOff; //  8, 4
    LONG        plr_ZOff; // 12, 4 - sometimes accessed as w - todo understand real size
    Zone*       plr_ZonePtr; // 16, 4
    LONG        plr_Height; // 20, 4
    LONG        plr_AimSpeed; // 24, 4
    LONG        plr_SnapXOff; // 28, 4
    LONG        plr_SnapYOff; // 32, 4
    LONG        plr_SnapYVel; // 36, 4
    LONG        plr_SnapZOff; // 40, 4
    LONG        plr_SnapTYOff; // 44, 4
    LONG        plr_SnapXSpdVal; // 48, 4
    LONG        plr_SnapZSpdVal; // 52, 4
    LONG        plr_SnapHeight; // 56, 4
    LONG        plr_SnapTargHeight; // 60, 4
    LONG        plr_TmpXOff; // 64, 4 - also accessed as w, todo determine correct size
    LONG        plr_TmpZOff; // 68, 4
    LONG        plr_TmpYOff; // 72, 4

    // Private
    ULONG       plr_ListOfGraphRoomsPtr; // 76, 4
    ULONG       plr_PointsToRotatePtr; // 80, 4
    LONG        plr_BobbleY; // 84, 4
    LONG        plr_TmpHeight; // 88, 4
    LONG        plr_OldX; // 92, 4
    LONG        plr_OldZ; // 96, 4
    Zone*       plr_OldRoomPtr; // 100, 4
    LONG        plr_SnapSquishedHeight; // 104, 4
    LONG        plr_DefaultEnemyFlags; // 108, 4


    // Word fields
    WORD        plr_Energy; // 112, 2
    WORD        plr_CosVal; // 114, 2
    WORD        plr_SinVal; // 116, 2
    WORD        plr_AngPos; // 118, 2
    WORD        plr_ZoneID; // 120, 2
    WORD        plr_FloorSpd; // 122, 2
    WORD        plr_RoomBright; // 124, 2
    WORD        plr_Bobble; // 126, 2
    WORD        plr_SnapAngPos; // 128, 2
    WORD        plr_SnapAngSpd; // 130, 2
    WORD        plr_TmpAngPos; // 132, 2
    WORD        plr_TimeToShoot; //134, 2

    // Inventory
    Inventory plr_Inventory;

/*
    UWORD plr_GunFrame_w				; 204, 2
    UWORD plr_NoiseVol_w				; 206, 2
    ; Private

    UWORD plr_TmpHoldDown_w			; 208, 2
    UWORD plr_TmpBobble_w				; 210, 2
    UWORD plr_SnapCosVal_w				; 212, 2
    UWORD plr_SnapSinVal_w				; 214, 2
    UWORD plr_WalkSFXTime_w			; 216, 2

    ; Byte data
    UBYTE plr_Keys_b					; 218
    UBYTE plr_Path_b					; 219
    UBYTE plr_Mouse_b					; 220
    UBYTE plr_Joystick_b				; 221
    UBYTE plr_GunSelected_b			; 222
    UBYTE plr_StoodInTop_b				; 223
    UBYTE plr_Ducked_b					; 224
    UBYTE plr_Squished_b				; 225
    UBYTE plr_Echo_b					; 226
    UBYTE plr_Fire_b					; 227
    UBYTE plr_Clicked_b				; 228
    UBYTE plr_Used_b					; 229
    UBYTE plr_TmpClicked_b				; 230
    UBYTE plr_TmpSpcTap_b				; 231
    UBYTE plr_TmpGunSelected_b			; 232
    UBYTE plr_TmpFire_b				; 233

    ; Private
    UBYTE plr_Teleported_b				; 234
    UBYTE plr_Dead_b					; 235
    UBYTE plr_TmpDucked_b				; 236
    UBYTE plr_StoodOnLift_b			; 237

    UBYTE plr_InvMouse_b				; 238
    UBYTE plr_Reserved2_b				; 239
*/

} ASM_ALIGN(sizeof(WORD))  Player;

#define MULTIPLAYER_SLAVE  ((BYTE)'s')
#define MULTIPLAYER_MASTER ((BYTE)'m')

extern BYTE  Plr_MultiplayerType_b;
extern Player Plr1_Data;
extern Player Plr2_Data;

/**
 * Returns a reference to the local Player
 */
inline Player* Player_GetLocal(void)
{
    if (Plr_MultiplayerType_b == MULTIPLAYER_SLAVE) {
        return &Plr2_Data;
    }
    return &Plr1_Data;
}

/**
 * Returns a reference to the remote player. If not in a two player game, returns NULL.
 */
inline Player* Player_GetRemote(void)
{
    if (Plr_MultiplayerType_b == MULTIPLAYER_SLAVE) {
        return &Plr1_Data;
    }
    else if (Plr_MultiplayerType_b == MULTIPLAYER_MASTER) {
        return &Plr2_Data;
    }
    return NULL;
}

#endif // PLAYER_H
