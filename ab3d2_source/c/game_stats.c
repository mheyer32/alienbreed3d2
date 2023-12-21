
#include <exec/types.h>
#include <dos/dos.h>
#include <proto/dos.h>
#include "game_stats.h"
#include "message.h"

extern char const Game_StatsFile[];

extern Game_Stats game_Stats;
extern ULONG Game_CheckStatsEvent;
void Game_LoadStats(void) {
    BPTR gameStatsFH = Open(Game_StatsFile, MODE_OLDFILE);
    if (DOSFALSE == gameStatsFH) {
        return;
    }

    Read(gameStatsFH, &game_Stats, sizeof(Game_Stats));

    Close(gameStatsFH);
}

void Game_SaveStats(void) {
    BPTR gameStatsFH = Open(Game_StatsFile, MODE_READWRITE);
    if (DOSFALSE == gameStatsFH) {
        return;
    }

    Write(gameStatsFH, &game_Stats, sizeof(Game_Stats));
    Close(gameStatsFH);
}

static inline BOOL game_CheckAchieved(UWORD i) {
	return game_Stats.gs_Achieved[(i >> 3)] & (1 << (i & 7));
}

static inline BOOL game_MarkAchieved(UWORD i) {
	return game_Stats.gs_Achieved[(i >> 3)] |= (1 << (i & 7));
}

#define PARAM_WORD(w) ((w) >> 8),((w) & 0xFF)
#define PARAM_LONG(w) ((w) >> 24),(((w) >> 16) & 0xFF),(((w) >> 8) & 0xFF),((w) & 0xFF)

static BOOL game_AchievementRuleKillCount(struct Achievement const* achievement) {
	UWORD const * ac_Params = (UWORD const *)&(achievement->ac_UByte[0]);
	return game_Stats.gs_AlienKills[ac_Params[0]] >= ac_Params[1];
}

static BOOL game_AchievementRuleGroupKillCount(struct Achievement const* achievement) {
	ULONG enemyMask = *(ULONG const*)&(achievement->ac_UByte[0]) & ((1 << NUM_ALIEN_DEFS) - 1);
	UWORD count     = *(UWORD const*)&(achievement->ac_UByte[sizeof(ULONG)]);

	for (UWORD id = 0; id < NUM_ALIEN_DEFS; ++id) {
		if (
			enemyMask & (1 << id) &&
			game_Stats.gs_AlienKills[id] >= count
		) {
			return TRUE;
		}
	}
	return FALSE;
}


/**
 * TODO - Incorporate this structure type into the mod properties with an ID in place of the rule, which will be
 *        swapped for the correct function pointer after loading up.
 */
struct Achievement test[] = {
	{
		// Kill 10 beasts
		"Achievement: Beast Bashin' (Pest control 10/200)",
		game_AchievementRuleKillCount,
		{PARAM_WORD(0),PARAM_WORD(10)} // alien type, count
	},

	{
		// kill 50 beasts
		"Achievement: Alien Bleed (Pest control 50/200)",
		game_AchievementRuleKillCount,
		{PARAM_WORD(0),PARAM_WORD(50)} // alien type, count
	},

	{
		// kill 100 beasts
		"Achievement: Endangered Species (Pest control 100/200)",
		game_AchievementRuleKillCount,
		{PARAM_WORD(0),PARAM_WORD(100)} // alien type, count
	},

	{
		// Kill 200 beasts
		"Achievement: Xenocide (Pest control 200/200)",
		game_AchievementRuleKillCount,
		{PARAM_WORD(0),PARAM_WORD(200)} // alien type, count
	},


	{
		// Kill 10 security drones
		"Achievement: Light 'Em Up",
		game_AchievementRuleKillCount,
		{PARAM_WORD(14),PARAM_WORD(10)}
	},


	{
		// Kill 20 flying things
		"Achievement: Death From Below!",
		game_AchievementRuleGroupKillCount,
		{
			PARAM_LONG(    // alien type mask
				1 << 4  |
				1 << 7  |
				1 << 14 |
				1 << 15
			),
			PARAM_WORD(20) // count
		}
 	}
};

void Game_CheckStats(void) {

	// TODO - track ID range rather than all achievements
	//      - tag achivements by event type to speed up skipping

	for (UWORD id = 0; id < sizeof(test)/sizeof(struct Achievement); ++id) {
		if (
			!game_CheckAchieved(id) &&
			test[id].ac_Rule(&test[id])
		) {
			Msg_PushLine(test[id].ac_Name, MSG_TAG_OPTIONS|80);
			game_MarkAchieved(id);
		}
	}

   Game_CheckStatsEvent = 0;
}
