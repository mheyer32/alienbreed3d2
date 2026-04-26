#include "game.h"
#include "game_mod.h"
extern void game_LoadModProperties(void);
extern void game_LoadPreferences(void);
extern void game_LoadPlayerProgression(void);
extern void game_SavePreferences(void);
extern void game_SavePlayerProgression(void);
extern void game_FreeAchievementsData();


/**
 * Startup
 *
 * Load the mod properties, progress and prefs
 */
void Game_Init(void) {
    GMod_Init();
    game_LoadModProperties();
    game_LoadPreferences();
    game_LoadPlayerProgression();
}

/**
 * Shutdown
 *
 * Persist progress and prefs, then free up any loaded stuff
 */
void Game_Done(void) {
    game_SavePlayerProgression();
    game_SavePreferences();
    game_FreeAchievementsData();
    GMod_Done();
}
