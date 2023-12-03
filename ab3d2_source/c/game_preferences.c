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
extern UBYTE Prefs_FPSLimit;

extern UBYTE Vid_FullScreenTemp_b;
extern UBYTE Draw_ForceSimpleWalls_b;

extern LONG  Vid_FPSLimit_l;
extern WORD  Vid_LetterBoxMarginHeight_w;

// Extreme MVP version

void Game_ApplyPreferences(void) {
    Vid_FullScreenTemp_b        = Vid_FullScreen_b = Prefs_FullScreen;
    Vid_DoubleHeight_b          = Prefs_PixelMode;
    Draw_ForceSimpleWalls_b     = Prefs_SimpleLighting;
    Vid_FPSLimit_l              = Prefs_FPSLimit;
    Vid_LetterBoxMarginHeight_w = Prefs_VertMargin;
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

    Prefs_FullScreen     = Vid_FullScreen_b;
    Prefs_PixelMode      = Vid_DoubleHeight_b;
    Prefs_SimpleLighting = Draw_ForceSimpleWalls_b;
    Prefs_FPSLimit       = (UBYTE)Vid_FPSLimit_l;
    Prefs_VertMargin     = (UBYTE)Vid_LetterBoxMarginHeight_w;

    Write(gamePrefsFH, Prefs_Persisted, (Prefs_PersistedEnd - Prefs_Persisted));
    Close(gamePrefsFH);
}
