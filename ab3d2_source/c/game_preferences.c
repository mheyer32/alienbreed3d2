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

extern UBYTE Prefs_OriginalMouse_b;
extern UBYTE Prefs_AlwaysRun_b;
extern UBYTE Prefs_NoAutoAim_b;
extern UBYTE Prefs_CrossHairColour_b;
extern UBYTE Prefs_ShowMessages_b;

void Cfg_ParsePreferencesFile(char const*);
void Cfg_WritePreferencesFile(char const*);

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
    CFG_VAR_TYPE_UBYTE = 0,
    CFG_VAR_TYPE_BYTE  = 1,
    CFG_VAR_TYPE_UWORD = 2,
    CFG_VAR_TYPE_WORD  = 3,
    CFG_VAR_TYPE_ULONG = 4,
    CFG_VAR_TYPE_LONG  = 5
};


/**
 * Cfg_Setting
 *
 * Links a parameter name tod the address of the target and defines the expected text file and target types
 */
typedef struct {
    char const *p_name; // The parameter name
    void       *v_data; // The in-memory location of the value to read/write
    UWORD      p_type;  // Cfg_ParamType
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

    // Single char match
    if (0 == buffer[1]) {
        for (unsigned int i = 0; i < sizeof(char_keys) / sizeof(CharKey); ++i) {
            if (char_keys[i].name == buffer[0]) {
                return char_keys[i].raw_code;
            }
        }
    } else {
        for (unsigned int i = 0; i < sizeof(special_keys) / sizeof(SpecialKey); ++i) {
            if (0 == strcmp(special_keys[i].name, buffer)) {
                return char_keys[i].raw_code;
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
    cfg_ParseKey
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
    *((UBYTE*)option->v_data) = clamp(
        cfg_parsers[option->p_type](param),
        0,
        65535
    );
}

/**
 * Sets a WORD configurartion option
 */
static void cfg_SetWord(Cfg_Setting const* option, char const* param) {
    *((BYTE*)option->v_data) = clamp(
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

/**
 * Cfg_Setter per Cfg_VarType
 */
Cfg_Setter cfg_setters[] = {
    cfg_SetUByte,
    cfg_SetByte,
    cfg_SetUWord,
    cfg_SetWord,
    cfg_SetLong,
    cfg_SetLong
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

        for (unsigned int i = 0; i < sizeof(cfg_options) / sizeof(Cfg_Setting); ++i) {
            LONG val = 0;
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

                default:
                    continue;
            }

            switch (cfg_options[i].p_type) {
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
