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

/**
 * Textfile configurartion
 *
 * TODO - migrate IO to DOS library?
 */

#include <stdio.h>
#include <stdlib.h>
#include <memory.h>

#include "key_defs.h"

/**
 * Enumerate the types expected in the file
 */
enum CFGParamType {
    CFG_PARAM_TYPE_BOOL    = 0,
    CFG_PARAM_TYPE_INT     = 1,
    CFG_PARAM_TYPE_KEY     = 2,
};

/**
 * Enumerate the in-memory types of target values
 */
enum CFGVarType {
    CFG_VAR_TYPE_UBYTE = 0,
    CFG_VAR_TYPE_BYTE  = 1,
    CFG_VAR_TYPE_UWORD = 2,
    CFG_VAR_TYPE_WORD  = 3,
    CFG_VAR_TYPE_ULONG = 4,
    CFG_VAR_TYPE_LONG  = 5
};

/**
 * CFGOption
 *
 * Links a parameter name tod the address of the target and defines the expected text file and target types
 */
typedef struct {
    char const *p_name; // The parameter name
    void       *v_data; // The in-memory location of the value
    UWORD      p_type;  // CFGParamType
    UWORD      v_type;  // CFGMapType
} CFGOption;


/**
 * Defines the set of optioms.
 */
static CFGOption const options[] = {

    #include "prefs_keys.h"
    #include "prefs_vid.h"



};

/**
 * Parser - converts parameter to value
 */
typedef int (*Parser)(char const*);

/**
 * Parses a bool. Only "true" is accepted as true, everything else false
 *
 * TODO - add support for "on", "enabled" etc?
 */
static int parse_bool(char const* buffer) {
    return 0 == strcmp("true", buffer) ? 255 : 0;
}

/**
 * Parses a basic integer.
 *
 */
static int parse_int(char const* buffer) {
    return atoi(buffer);
}

/**
 * Parses a key name, for the custom key settings. Returns the raw key code, or -1 for no match
 */
static int parse_key(char const* buffer) {

    // Single char
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
 * Parser per CFGType
 */
Parser parsers[] = {
    parse_bool,
    parse_int,
    parse_key
};

/**
 * Setter - set an in memory value for an option
 */
typedef void (*Setter)(CFGOption const*, char const*);

static inline int clamp(int value, int min, int max) {
    return value < min ? min : value > max ? max : value;
}

/**
 * Sets a UBYTE configurartion option
 */
static void set_ubyte(CFGOption const* option, char const* param) {
    *((UBYTE*)option->v_data) = clamp(
        parsers[option->p_type](param),
        0,
        255
    );
}

/**
 * Sets a BYTE configurartion option
 */
static void set_byte(CFGOption const* option, char const* param) {
    *((BYTE*)option->v_data) = clamp(
        parsers[option->p_type](param),
        -128,
        127
    );
}

/**
 * Sets a UWORD configurartion option
 */
static void set_uword(CFGOption const* option, char const* param) {
    *((UBYTE*)option->v_data) = clamp(
        parsers[option->p_type](param),
        0,
        65535
    );
}

/**
 * Sets a WORD configurartion option
 */
static void set_word(CFGOption const* option, char const* param) {
    *((BYTE*)option->v_data) = clamp(
        parsers[option->p_type](param),
        -32768,
        32767
    );
}

/**
 * Sets a LONG (or ULONG) configurartion option
 */
static void set_long(CFGOption const* option, char const* param) {
    *((LONG*)option->v_data) = parsers[option->p_type](param);
}

/**
 * Setter per CFGMapType
 */
Setter setters[] = {
    set_ubyte,
    set_byte,
    set_uword,
    set_word,
    set_long,
    set_long
};

/**
 * Reads the next word from the config file. This is anything that's not whitespace.
 * Anything beginning with a semicolon is ignored until the next newline
 *
 * TODO - Rework to use vanilla DOS library?
 */
static char const* read_word(FILE* fp) {
    static char buffer[128];

    buffer[0] = 0;
    while (!feof(fp)) {
        if (0 == fscanf(fp, "%s", buffer)) {
            return 0;
        }
        if (buffer[0] == ';') {
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
void process_config(char const* name, FILE* fp) {
    for (unsigned int i = 0; i < sizeof(options) / sizeof(CFGOption); ++i) {
        if (0 == strcmp(name, options[i].p_name)) {
            setters[options[i].v_type](
                &options[i],
                read_word(fp)
            );
        }
    }
}

/**
 * This is the main entry point. Takes the path of the file name and processes it.
 *
 * TODO - Rework for use with vanilla DOS library
 *
 * Example structure:

; This is a comment. Anything after a ; is ignored until the end of the line
; Settings are key value pairs. These are any non-whitespace characters and are matched and processed by
; the parser.

; Video options...
vid.aga.fullscreen true
vid.aga.margin     0
vid.rtg.fullscreen 0
vid.rtg.margin     0

; Keybindings...
key.walk  W
key.back  S
key.left  A
key.right D
key.duck  C
key.jump  SPACE


; Gameplay
play.input          mouse   ; mouse, keys, joystick
play.auto_aim       false   ; shoot where I point, please
play.use_crosshair  true
play.show_messages  true

; ...

 *
 */
void game_CFGParseOptionsFile(char const* file) {
    FILE* fp;
    if ( (fp = fopen(file, "rb")) ) {
        char const* next;
        while ((next = read_word(fp))) {
            process_config(next, fp);
        }
        fclose(fp);
    }
}
