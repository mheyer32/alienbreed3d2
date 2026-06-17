#ifndef _TKG_LMOD_H_
#   define _TKG_LMOD_H_

#include "game_mod_format.h"

/**
 * ZoneDeletions is used for both PVS and Backdrop deletions
 */
typedef struct {
    UWORD zd_Data[1];
} ASM_ALIGN(sizeof(WORD)) ZoneDeletions;

/**
 * LevelMessage is used for both Zone and Object messages
 */
typedef struct {
    UWORD lm_ZoneID;
    UWORD lm_Attributes;
    char const* lm_Text;
} ASM_ALIGN(sizeof(WORD)) LevelMessage;

enum {
    IDENT_PVSD = 0x50565344,
    IDENT_BCKD = 0x424B4444,
    IDENT_ZMSG = 0x5A4D5347,
    IDENT_OMSG = 0x4F4D5347,
};

typedef struct {
    GMF_Data const* lmod_Loaded;
    WORD const* lmod_PVSErrata;

} LMod_LevelProperties;

extern LMod_LevelProperties LMod_Properties;

/**
 * LMod_LoadModificationData
 *
 * Attempts to load the modification data for the current level.
 */
extern void LMod_LoadModificationData(void);

/**
 * LMod_FreeModificationData
 *
 * Releases the loaded data for the current level.
 */
extern void LMod_FreeModificationData(void);

#endif
