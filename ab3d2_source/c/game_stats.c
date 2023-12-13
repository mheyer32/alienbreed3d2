
#include <exec/types.h>
#include <dos/dos.h>
#include <proto/dos.h>
#include "game_stats.h"

extern char const Game_StatsFile[];

extern Game_Stats game_Stats;

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
