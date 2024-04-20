#include "game.h"

#include <exec/types.h>
#include <dos/dos.h>
#include <proto/dos.h>
#include "screen.h"

extern struct FileInfoBlock io_FileInfoBlock;
extern char const game_PreferencesFile[];
extern UBYTE Prefs_Persisted[];
extern UBYTE Prefs_PersistedEnd[];
extern UBYTE Prefs_FullScreen_b;
extern UBYTE Prefs_PixelMode_b;
extern UBYTE Prefs_VertMargin_b;
extern UBYTE Prefs_SimpleLighting_b;
extern UBYTE Prefs_FPSLimit_b;
extern UBYTE Prefs_DynamicLights_b;
extern UBYTE Prefs_RenderQuality_b;
extern UBYTE Vid_FullScreenTemp_b;
extern UBYTE Draw_ForceSimpleWalls_b;
extern UBYTE Draw_GoodRender_b;
extern UBYTE Anim_LightingEnabled_b;
extern LONG  Vid_FPSLimit_l;
extern WORD  Vid_LetterBoxMarginHeight_w;

extern UWORD Prefs_ContrastAdjust_AGA_w;
extern UWORD Prefs_ContrastAdjust_RTG_w;
extern WORD  Prefs_BrightnessOffset_AGA_w;
extern WORD  Prefs_BrightnessOffset_RTG_w;
extern UBYTE Prefs_GammaLevel_AGA_b;
extern UBYTE Prefs_GammaLevel_RTG_b;
extern UWORD Vid_ContrastAdjust_w;
extern UWORD Vid_BrightnessOffset_w;
extern UBYTE Vid_GammaLevel_b;

// Extreme MVP version

void game_ApplyPreferences(void)
{
    Vid_FullScreenTemp_b        = Vid_FullScreen_b = Prefs_FullScreen_b;
    if (Vid_isRTG) {
        Vid_DoubleHeight_b      = Prefs_PixelMode_b;
        Vid_ContrastAdjust_w    = Prefs_ContrastAdjust_RTG_w;
        Vid_BrightnessOffset_w  = Prefs_BrightnessOffset_RTG_w;
        Vid_GammaLevel_b        = Prefs_GammaLevel_RTG_b;
    } else {
        Vid_ContrastAdjust_w    = Prefs_ContrastAdjust_AGA_w;
        Vid_BrightnessOffset_w  = Prefs_BrightnessOffset_AGA_w;
        Vid_GammaLevel_b        = Prefs_GammaLevel_AGA_b;
    }
    Draw_ForceSimpleWalls_b     = Prefs_SimpleLighting_b;
    Vid_FPSLimit_l              = Prefs_FPSLimit_b;
    Vid_LetterBoxMarginHeight_w = Prefs_VertMargin_b;
    Anim_LightingEnabled_b      = Prefs_DynamicLights_b;
    Draw_GoodRender_b           = Prefs_RenderQuality_b;
}

void game_LoadPreferences(void)
{
    BPTR gamePrefsFH = Open(game_PreferencesFile, MODE_OLDFILE);
    if (DOSFALSE == gamePrefsFH) {
        return;
    }
    LONG size = (Prefs_PersistedEnd - Prefs_Persisted);
    if (size == Read(gamePrefsFH, Prefs_Persisted, size)) {
        game_ApplyPreferences();
    }
    Close(gamePrefsFH);
}

void game_SavePreferences(void)
{
    BPTR gamePrefsFH = Open(game_PreferencesFile, MODE_READWRITE);
    if (DOSFALSE == gamePrefsFH) {
        return;
    }

    Prefs_FullScreen_b     = Vid_FullScreen_b;
    Prefs_PixelMode_b      = Vid_DoubleHeight_b;
    Prefs_SimpleLighting_b = Draw_ForceSimpleWalls_b;
    Prefs_FPSLimit_b       = (UBYTE)Vid_FPSLimit_l;
    Prefs_VertMargin_b     = (UBYTE)Vid_LetterBoxMarginHeight_w;
    Prefs_DynamicLights_b  = Anim_LightingEnabled_b;
    Prefs_RenderQuality_b  = Draw_GoodRender_b;

    if (Vid_isRTG) {
        Prefs_ContrastAdjust_RTG_w   = Vid_ContrastAdjust_w;
        Prefs_BrightnessOffset_RTG_w = Vid_BrightnessOffset_w;
        Prefs_GammaLevel_RTG_b       = Vid_GammaLevel_b;
    } else {
        Prefs_ContrastAdjust_AGA_w   = Vid_ContrastAdjust_w;
        Prefs_BrightnessOffset_AGA_w = Vid_BrightnessOffset_w;
        Prefs_GammaLevel_AGA_b       = Vid_GammaLevel_b;
    }

    Write(gamePrefsFH, Prefs_Persisted, (Prefs_PersistedEnd - Prefs_Persisted));
    Close(gamePrefsFH);
}
