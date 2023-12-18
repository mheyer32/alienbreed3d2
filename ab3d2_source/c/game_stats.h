#ifndef GAME_STATS_H
#define GAME_STATS_H
#include <SDI_compiler.h>
#include "defs.h"

#define MAX_ACHIEVEMENTS 128

typedef struct {
    /** Total number of times the player has attempted a level */
    UWORD gs_LevelPlayCounts[NUM_LEVELS];

    /** Total number of times the player has beaten a level */
    UWORD gs_LevelWonCounts[NUM_LEVELS];

    /** Total number of times the player failed a level */
    UWORD gs_LevelFailCounts[NUM_LEVELS];

    /** Total number of times the player has killed each class of alien */
    UWORD gs_AlienKills[NUM_ALIEN_DEFS];

    /** Bitmap of achievements. A mod may define up to MAX_ACHIEVEMENTS */
    UBYTE gs_Achieved[MAX_ACHIEVEMENTS/8];

} Game_Stats;

extern void Game_LoadStats(void);
extern void Game_SaveStats(void);

#endif // GAME_STATS_H
