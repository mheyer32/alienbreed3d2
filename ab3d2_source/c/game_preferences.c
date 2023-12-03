#include "system.h"
#include "screen.h"
#include "game_preferences.h"
#include <dos/dos.h>
#include <proto/dos.h>

extern struct FileInfoBlock io_FileInfoBlock;

extern UBYTE Prefs_Persisted[];
extern UBYTE Prefs_PersistedEnd[];

extern UBYTE Prefs_FullScreen;
extern UBYTE Prefs_PixelMode;
extern UBYTE Prefs_VertMargin;
extern UBYTE Prefs_SimpleLighting;

extern UBYTE Vid_FullScreenTemp_b;
// Extreme MVP version

void Game_ApplyPreferences(void) {
    Vid_FullScreenTemp_b = Vid_FullScreen_b = Prefs_FullScreen;
    Vid_DoubleHeight_b = Prefs_PixelMode;
}

void Game_LoadPreferences(void) {
    BPTR gamePrefsFH = Open(GAME_PREFS_PATH, MODE_OLDFILE);
    if (DOSFALSE == gamePrefsFH) {
        return;
    }
    Read(gamePrefsFH, Prefs_Persisted, (Prefs_PersistedEnd - Prefs_Persisted));
    Close(gamePrefsFH);
    Game_ApplyPreferences();
}

void Game_SavePreferences(void) {
    BPTR gamePrefsFH = Open(GAME_PREFS_PATH, MODE_READWRITE);
    if (DOSFALSE == gamePrefsFH) {
        return;
    }

    Prefs_FullScreen = Vid_FullScreen_b;
    Prefs_PixelMode  = Vid_DoubleHeight_b;
    Write(gamePrefsFH, Prefs_Persisted, (Prefs_PersistedEnd - Prefs_Persisted));
    Close(gamePrefsFH);
}
