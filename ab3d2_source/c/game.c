#include "game.h"
#include "game_mod.h"
extern void game_LoadPreferences(void);
extern void game_SavePreferences(void);


/**
 * Startup
 *
 * Load the mod properties, progress and prefs
 */
void Game_Init(void) {
    GMod_Init();
    game_LoadPreferences();
}

/**
 * Shutdown
 *
 * Persist progress and prefs, then free up any loaded stuff
 */
void Game_Done(void) {
    game_SavePreferences();
    GMod_Done();
}
