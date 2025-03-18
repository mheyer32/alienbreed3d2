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
extern BYTE  Prefs_FPSLimit_b;
extern UBYTE Prefs_DynamicLights_b;
extern UBYTE Prefs_RenderQuality_b;
extern UBYTE Vid_FullScreenTemp_b;
extern UBYTE Draw_ForceSimpleWalls_b;
extern UBYTE Draw_GoodRender_b;
extern UBYTE Anim_LightingEnabled_b;
extern WORD  Sys_FPSLimit_w;
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
extern UBYTE C2P_UseAkiko_b;
extern UBYTE C2P_AkikoMirror_b;
extern UBYTE C2P_AkikoCACR_b;

extern UBYTE Prefs_OriginalMouse_b;
extern UBYTE Prefs_AlwaysRun_b;
extern UBYTE Prefs_NoAutoAim_b;
extern UBYTE Prefs_CrossHairColour_b;
extern UBYTE Prefs_ShowMessages_b;
extern UBYTE Prefs_ShowWeapon_b;

extern UBYTE Draw_MapTransparent_b;
extern UWORD Draw_MapZoomLevel_w;

extern ULONG Zone_MovementMask_l;
#ifdef DEV
extern ULONG Dev_DebugFlags_l;
#endif

extern WORD Zone_PVSFieldOfView;

extern UBYTE Prefs_DisplayFPS_b;

void Cfg_ParsePreferencesFile(char const*);
void Cfg_WritePreferencesFile(char const*);

static UBYTE Prefs_OrderZoneSensitivity = 4;

// Extreme MVP version

void game_ApplyPreferences(void)
{
    Vid_FullScreenTemp_b        = Vid_FullScreen_b = Prefs_FullScreen_b;
        Vid_DoubleHeight_b      = Prefs_PixelMode_b;
    if (Vid_isRTG) {
        Vid_ContrastAdjust_w    = Prefs_ContrastAdjust_RTG_w;
        Vid_BrightnessOffset_w  = Prefs_BrightnessOffset_RTG_w;
        Vid_GammaLevel_b        = Prefs_GammaLevel_RTG_b;
    } else {
        Vid_ContrastAdjust_w    = Prefs_ContrastAdjust_AGA_w;
        Vid_BrightnessOffset_w  = Prefs_BrightnessOffset_AGA_w;
        Vid_GammaLevel_b        = Prefs_GammaLevel_AGA_b;
    }
    Draw_ForceSimpleWalls_b     = Prefs_SimpleLighting_b;
    Sys_FPSLimit_w              = Prefs_FPSLimit_b;
    Vid_LetterBoxMarginHeight_w = Prefs_VertMargin_b;
    Anim_LightingEnabled_b      = Prefs_DynamicLights_b;
    Draw_GoodRender_b           = Prefs_RenderQuality_b;

    // Map zoom is 0-7. TODO - this should be defined somewhere
    Draw_MapZoomLevel_w &= 7;

    // Zone ordering sensitivity
    Prefs_OrderZoneSensitivity &= 7;

    UWORD mask = ~((1 << Prefs_OrderZoneSensitivity) - 1);

    Zone_MovementMask_l = ((ULONG)mask << 16) | mask;
}

void game_LoadPreferences(void)
{
    Cfg_ParsePreferencesFile(game_PreferencesFile);
}

void game_SavePreferences(void)
{
    Cfg_WritePreferencesFile(game_PreferencesFile);
}

/**
 * Textfile configurartion
 *
 * TODO - Switch to DOS library for IO
 *      - Maybe load the whole text file into memory and parse in place
 *      - Hand rolled functions for string match / atoi
 */

#include <stdio.h>
#include <stdlib.h>
#include <memory.h>

#include "key_defs.h"

/**
 * Enumerate the types expected in the file
 */
enum Cfg_ParamType {
    CFG_PARAM_TYPE_BOOL     = 0,
    CFG_PARAM_TYPE_BOOL_INV = 1,
    CFG_PARAM_TYPE_INT      = 2,
    CFG_PARAM_TYPE_KEY      = 3,
};

/**
 * Enumerate the in-memory types of target values
 */
enum Cfg_VarType {
    CFG_VAR_TYPE_UBYTE     = 0,
    CFG_VAR_TYPE_BYTE      = 1,
    CFG_VAR_TYPE_UWORD     = 2,
    CFG_VAR_TYPE_WORD      = 3,
    CFG_VAR_TYPE_ULONG     = 4,
    CFG_VAR_TYPE_LONG      = 5,
    CFG_VAR_TYPE_UBYTE_BIT = 6,
    CFG_VAR_TYPE_UWORD_BIT = 7,
    CFG_VAR_TYPE_ULONG_BIT = 8,
};


/**
 * Cfg_Setting
 *
 * Links a parameter name tod the address of the target and defines the expected text file and target types
 */
typedef struct {
    char const *p_name; // The parameter name
    void       *v_data; // The in-memory location of the value to read/write
    UWORD      p_type;  // Cfg_ParamType, or the bit number for a flag based VarType
    UWORD      v_type;  // Cfg_VarType
} Cfg_Setting;

static char const* s_true  = "true";
static char const* s_false = "false";

/**
 * Defines the settings.
 */
static Cfg_Setting const cfg_options[] = {
    #include "prefs_keys.h"
    #include "prefs_vid.h"
    #include "prefs_gfx.h"
    #include "prefs_misc.h"
    #include "prefs_dev.h"
};

/**
 * Cfg_Parser - converts parameter to value
 */
typedef int (*Cfg_Parser)(char const*);

/**
 * Parses a bool. Only "true" is accepted as true, everything else false
 *
 * TODO - add support for "on", "enabled" etc?
 */
static int cfg_ParseBool(char const* buffer) {
    return 0 == strcmp(s_true, buffer) ? 255 : 0;
}

/**
 * Some of our flags are "true" by default but actually make more sense as an inverse from
 * a configuration perspective, e.g. "disable messages". We can specify those as having an
 * inverted boolean input
 */
static int cfg_ParseBoolInv(char const* buffer) {
    return 0 != strcmp(s_true, buffer) ? 255 : 0;
}


/**
 * Parses a basic integer.
 *
 */
static int cfg_ParseInt(char const* buffer) {
    return atoi(buffer);
}

/**
 * Parses a key name, for the custom key settings. Returns the raw key code, or -1 for no match
 */
static int cfg_ParseKey(char const* buffer) {

    if (0 == buffer[1]) {
        // Single char key name
        for (unsigned int i = 0; i < sizeof(char_keys) / sizeof(CharKey); ++i) {
            if (char_keys[i].name == buffer[0]) {
                return char_keys[i].raw_code;
            }
        }
    } else {
        // Text key name
        for (unsigned int i = 0; i < sizeof(special_keys) / sizeof(SpecialKey); ++i) {
            if (0 == strcmp(special_keys[i].name, buffer)) {
                return special_keys[i].raw_code;
            }
        }
    }

    // No match was found
    return -1;
}

/**
 * Cfg_Parser per Cfg_ParamType
 */
Cfg_Parser cfg_parsers[] = {
    cfg_ParseBool,
    cfg_ParseBoolInv,
    cfg_ParseInt,
    cfg_ParseKey,
};

/**
 * Cfg_Setter - set an in memory value for an option
 */
typedef void (*Cfg_Setter)(Cfg_Setting const*, char const*);

static inline int clamp(int value, int min, int max) {
    return value < min ? min : value > max ? max : value;
}

/**
 * Sets a UBYTE configurartion option
 */
static void cfg_SetUByte(Cfg_Setting const* option, char const* param) {
    *((UBYTE*)option->v_data) = clamp(
        cfg_parsers[option->p_type](param),
        0,
        255
    );
}

/**
 * Sets a BYTE configurartion option
 */
static void cfg_SetByte(Cfg_Setting const* option, char const* param) {
    *((BYTE*)option->v_data) = clamp(
        cfg_parsers[option->p_type](param),
        -128,
        127
    );
}

/**
 * Sets a UWORD configurartion option
 */
static void cfg_SetUWord(Cfg_Setting const* option, char const* param) {
    *((UWORD*)option->v_data) = clamp(
        cfg_parsers[option->p_type](param),
        0,
        65535
    );
}

/**
 * Sets a WORD configurartion option
 */
static void cfg_SetWord(Cfg_Setting const* option, char const* param) {
    *((WORD*)option->v_data) = clamp(
        cfg_parsers[option->p_type](param),
        -32768,
        32767
    );
}

/**
 * Sets a LONG (or ULONG) configurartion option
 */
static void cfg_SetLong(Cfg_Setting const* option, char const* param) {
    *((LONG*)option->v_data) = cfg_parsers[option->p_type](param);
}

static void cfg_SetUByteBit(Cfg_Setting const* option, char const* param) {
    UBYTE* p = (UBYTE*)option->v_data;
    UBYTE  v = 1 << (option->p_type & 7);
    if (cfg_ParseBool(param)) {
        *p |= v;
    } else {
        *p &= ~v;
    }
}

static void cfg_SetUWordBit(Cfg_Setting const* option, char const* param) {
    UWORD* p = (UWORD*)option->v_data;
    UWORD  v = 1 << (option->p_type & 15);
    if (cfg_ParseBool(param)) {
        *p |= v;
    } else {
        *p &= ~v;
    }
}

static void cfg_SetULongBit(Cfg_Setting const* option, char const* param) {
    ULONG* p = (ULONG*)option->v_data;
    ULONG  v = 1 << (option->p_type & 31);
    if (cfg_ParseBool(param)) {
        *p |= v;
    } else {
        *p &= ~v;
    }
}

/**
 * Cfg_Setter per Cfg_VarType
 */
Cfg_Setter cfg_setters[] = {
    cfg_SetUByte,
    cfg_SetByte,
    cfg_SetUWord,
    cfg_SetWord,
    cfg_SetLong,
    cfg_SetLong,
    cfg_SetUByteBit,
    cfg_SetUWordBit,
    cfg_SetULongBit,
};

/**
 * Reads the next word from the config file. This is anything that's not whitespace.
 * Anything beginning with a colon is ignored until the next newline
 *
 * TODO - Rework to use vanilla DOS library?
 */
static char const* cfg_ExtractString(FILE* fp) {
    static char buffer[128];

    buffer[0] = 0;
    while (!feof(fp)) {
        if (0 == fscanf(fp, "%s", buffer)) {
            return 0;
        }
        if (buffer[0] == ':') {
            while (!feof(fp) && fgetc(fp) != '\n');
        } else {
            return buffer;
        }
    }
    return 0;
}

/**
 * Try to match the parameter name to a known option and process it
 */
void cfg_ProcessSettings(char const* name, FILE* fp) {
    for (unsigned int i = 0; i < sizeof(cfg_options) / sizeof(Cfg_Setting); ++i) {
        if (0 == strcmp(name, cfg_options[i].p_name)) {
            cfg_setters[cfg_options[i].v_type](
                &cfg_options[i],
                cfg_ExtractString(fp)
            );
        }
    }
}

/**
 * This is the main entry point. Takes the path of the file name and processes it.
 *
 * TODO - Rework for use with vanilla DOS library
 *
 */
void Cfg_ParsePreferencesFile(char const* file) {
    FILE* fp;
    if ( (fp = fopen(file, "rb")) ) {
        char const* next;
        while ((next = cfg_ExtractString(fp))) {
            cfg_ProcessSettings(next, fp);
        }
        fclose(fp);
        game_ApplyPreferences();
    }
}

char const* cfg_GetKeyName(UBYTE raw_code) {
    static char name[2] = {0, 0};
    for (unsigned i = 0; i < sizeof(special_keys)/sizeof(SpecialKey); ++i) {
        if (special_keys[i].raw_code == raw_code) {
            return special_keys[i].name;
        }
    }
    for (unsigned i = 0; i < sizeof(char_keys)/sizeof(CharKey); ++i) {
        if (char_keys[i].raw_code == raw_code) {
            name[0] = (char)char_keys[i].name;
            return name;
        }
    }
    return "<none>";
}

void Cfg_WritePreferencesFile(char const* file) {
    FILE* fp;
    if ( (fp = fopen(file, "wb")) ) {
        Prefs_FullScreen_b     = Vid_FullScreen_b;
        Prefs_PixelMode_b      = Vid_DoubleHeight_b;
        Prefs_SimpleLighting_b = Draw_ForceSimpleWalls_b;
        Prefs_FPSLimit_b       = (BYTE)Sys_FPSLimit_w;
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

        for (unsigned int i = 0; i < sizeof(cfg_options) / sizeof(Cfg_Setting); ++i) {
            LONG val = 0;
            UWORD type = cfg_options[i].p_type;
            switch (cfg_options[i].v_type) {
                case CFG_VAR_TYPE_UBYTE:
                    val = *((UBYTE*)cfg_options[i].v_data);
                    break;

                case CFG_VAR_TYPE_BYTE:
                    val = *((BYTE*)cfg_options[i].v_data);
                    break;

                case CFG_VAR_TYPE_UWORD:
                    val = *((UWORD*)cfg_options[i].v_data);
                    break;

                case CFG_VAR_TYPE_WORD:
                    val = *((WORD*)cfg_options[i].v_data);
                    break;

                case CFG_VAR_TYPE_ULONG:
                case CFG_VAR_TYPE_LONG:
                    val = *((LONG*)cfg_options[i].v_data);
                    break;

                case CFG_VAR_TYPE_UBYTE_BIT:
                    val = *((UBYTE*)cfg_options[i].v_data);
                    val &= 1 << (type & 7);
                    type = CFG_PARAM_TYPE_BOOL;
                    break;

                case CFG_VAR_TYPE_UWORD_BIT:
                    val = *((UWORD*)cfg_options[i].v_data);
                    val &= 1 << (type & 15);
                    type = CFG_PARAM_TYPE_BOOL;
                    break;

                case CFG_VAR_TYPE_ULONG_BIT:
                    val = *((LONG*)cfg_options[i].v_data);
                    val &= 1 << (type & 31);
                    type = CFG_PARAM_TYPE_BOOL;
                    break;

                default:
                    continue;
            }

            switch (type) {
                case CFG_PARAM_TYPE_BOOL_INV:
                    val = (~val) & 0xFF;

                case CFG_PARAM_TYPE_BOOL:
                    fprintf(fp, "%-26s %s\n", cfg_options[i].p_name, (val ? s_true : s_false));
                    break;

                case CFG_PARAM_TYPE_KEY:
                    fprintf(fp, "%-26s %s\n", cfg_options[i].p_name, cfg_GetKeyName(val));
                    break;

                default:
                    fprintf(fp, "%-26s %d\n", cfg_options[i].p_name, val);
                    break;
            }

        }
        fclose(fp);
    }
}
