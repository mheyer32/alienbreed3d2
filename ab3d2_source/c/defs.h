#ifndef DEFS_H
#define DEFS_H

#include <exec/types.h>
#include <SDI_compiler.h>
#include "asm_align.h"

/**
 * C structure definitions to match the assembler ones in defs.i
 *
 * DO NOT EDIT THIS FILE WITHOUT MAKING THE CORRESPONDING CHANGES IN defs.i
 */

#define MAX_LEVEL_OBJ_DIST_COUNT    (256+32)
#define MAX_OBJS_IN_LINE_COUNT      400
#define LVL_OBJ_DEFINITION_SIZE     64

#define NUM_LEVELS          16
#define NUM_BULLET_DEFS     20
#define NUM_GUN_DEFS        10
#define NUM_ALIEN_DEFS      20
#define NUM_OBJECT_DEFS     30
#define NUM_SFX             64
#define NUM_WALL_TEXTURES   16

/* Maximum number of zones. Note that the game doesn't yet support this limit fully. */
#define LVL_EXPANDED_MAX_ZONE_COUNT 512

/* Maximum number of zones. Once this is fully working, rededine as LVL_EXPANDED_MAX_ZONE_COUNT */
#define LVL_MAX_ZONE_COUNT 256

typedef struct {
    LONG o_XPos;
    LONG o_ZPos;
    LONG o_YPos;
    UWORD o_ZoneID;
    UWORD o_Unused;
    UBYTE o_TypeID;
    UBYTE o_SeePlayer;
} ObjBase;

#include "math25d.h"
#include "zone.h"
#include "zone_door.h"
#include "player.h"
#endif // DEFS_H
