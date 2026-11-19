#ifndef _TKG_LMOD_H_
#   define _TKG_LMOD_H_

#include "game_mod_format.h"

/**
 * Chunk ident values for level mod file components
 */
enum {
    IDENT_PVSD = 0x50565344,
    IDENT_BCKD = 0x42434B44,
    IDENT_ZMSG = 0x5A4D5347,
    IDENT_OMSG = 0x4F4D5347,
};

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
    UWORD       lm_ZoneID;
    UWORD       lm_Attributes;
    char const* lm_TextPtr;
} ASM_ALIGN(sizeof(WORD)) LevelMessage;

/**
 * LMod_LevelProperties structure holds the level modification data (if any)
 */
typedef struct {
    GMF_Data const* lmod_LoadedPtr;
    WORD const*     lmod_PVSErrataPtr;
    WORD const*     lmod_BCKDErrataPtr;
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
