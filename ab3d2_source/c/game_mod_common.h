#ifndef _TKG_GMOD_COMMON_H_
#   define _TKG_GMOD_COMMON_H_

/**
 * This header contains definitions that are common to multiple modification asset files:
 *
 * - Main Game Modification
 * - Player Progression
 */

#include "defs.h"
#include "game_mod_format.h"
#include "inventory.h"

enum {
    IDENT_INVL = 0x494E564C,
    IDENT_WADJ = 0x5741444A,
};

/**
 * GMod_WeaponAdjustment
 *
 * Defines a behavioural adjustment for a weapon.
 */
typedef struct {
    UWORD wadj_SlotID;
    WORD  wadj_XOffset;
    WORD  wadj_YOffset;
    WORD  wadj_Recoil;
    WORD  wadj_Spray;
    UWORD wadj_BurstLimit;
    UWORD wadj_CoolDown;
    UWORD wadj_Flags;
} ASM_ALIGN(sizeof(UWORD)) GMod_WeaponAdjustment; // 16 bytes

/**
 * GMod_WeaponAdjustment.wa_Flags
 */
#define WAF_NO_RUN            0x0001
#define WAF_NO_CROUCH         0x0002
#define WAF_NO_FLY            0x0004
#define WAF_NO_FIRE_SUBMERGED 0x0008

#endif
