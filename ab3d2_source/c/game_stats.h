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

typedef enum  {
	KILL_COUNT			= 0, // kill count of a particular enemy class
	KILL_GROUP_COUNT	= 1, // Kill count over a group of enemy classes
} AchievementRule;

struct Achievement;

typedef BOOL (*Rule)(struct Achievement const*);

struct Achievement {
	char const* ac_Name;
	Rule	ac_Rule;
	UBYTE	ac_UByte[8];
};

extern void Game_LoadStats(void);
extern void Game_SaveStats(void);
extern void Game_CheckStats(void);
#endif // GAME_STATS_H
