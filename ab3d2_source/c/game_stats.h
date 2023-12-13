#ifndef GAME_STATS_H
#define GAME_STATS_H

#include "defs.h"

typedef struct {
    /** Total number of times the player has attempted a level */
    UWORD gs_LevelPlayCounts[NUM_LEVELS];

    /** Total number of times the player has beaten a level */
    UWORD gs_LevelWonCounts[NUM_LEVELS];

    /** Total number of times the player failed a level */
    UWORD gs_LevelFailCounts[NUM_LEVELS];

    /** Total number of times the player has killed each class of alien */
    UWORD gs_AlienKills[NUM_ALIEN_DEFS];

} Game_Stats;

extern void Game_LoadStats(void);
extern void Game_SaveStats(void);

#endif // GAME_STATS_H
