#include "game.h"

extern void game_LoadModProperties(void);
extern void game_LoadPreferences(void);
extern void game_LoadPlayerProgression(void);
extern void game_SavePreferences(void);
extern void game_SavePlayerProgression(void);

/**
 * Startup
 *
 * Load the mod properties, progress and prefs
 */
void Game_Init(void) {
    game_LoadModProperties();
    game_LoadPreferences();
    game_LoadPlayerProgression();
}

/**
 * Shutdown
 *
 * Persist progress and prefs
 */
void Game_Done(void) {
    game_SavePlayerProgression();
    game_SavePreferences();
}
