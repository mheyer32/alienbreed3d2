#ifndef GAME_PREFERENCES_H
#define GAME_PREFERENCES_H

#include "defs.h"

#define GAME_PREFS_PATH "ab3:game.prefs"

extern void Game_LoadPreferences(void);
extern void Game_SavePreferences(void);

extern void Game_ApplyPreferences(void);

#endif // GAME_PREFERENCES_H
