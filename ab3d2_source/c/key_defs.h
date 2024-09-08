#ifndef KEY_DEFS_H
#define KEY_DEFS_H

#include <exec/types.h>

/**
 * The array of assigned keys is defined in asm
 */
extern UBYTE Prefs_AssignableKeys_vb[];

/**
 * Enumerates the offset of the assignable key in Prefs_AssignableKeys_vb
 */
typedef enum {
    KEY_TURN_LEFT  = 0,
    KEY_TURN_RIGHT,
    KEY_FORWARDS,
    KEY_BACKWARDS,
    KEY_FIRE,
    KEY_USE,
    KEY_RUN,
    KEY_FORCE_SIDESTEP,
    KEY_STEP_LEFT,
    KEY_STEP_RIGHT,
    KEY_DUCK,
    KEY_LOOK_BEHIND,
    KEY_JUMP,
    KEY_LOOK_UP,
    KEY_LOOK_DOWN,
    KEY_CENTRE_VIEW,
    KEY_NEXT_WEAPON,
    KEY_SPARE,
} AssignableKey;

/**
 * For printable keys, we map the char to the raw code
 */
typedef struct {
    UBYTE name;
    UBYTE raw_code;
} CharKey;

/**
 * For non-printable keys, we map the string to the raw code
 */
typedef struct {
    char const* name;
    int raw_code;
} SpecialKey;

/**
 * Printable key names, 1 char each. Assignable keys only
 */
static CharKey char_keys[] = {

    /* second row */
    { '`',    0x00 },
    { '_',    0x0B },
    { '=',    0x0C },
    { '\\',   0x0D },
    { 'Q',    0x10 },
    { 'W',    0x11 },
    { 'E',    0x12 },
    { 'R',    0x13 },
    { 'T',    0x14 },
    { 'Y',    0x15 },
    { 'U',    0x16 },
    { 'I',    0x17 },
    { 'O',    0x18 },
    { 'P',    0x19 },
    { '[',    0x1A },
    { ']',    0x1B },
    { 'A',    0x20 },
    { 'S',    0x21 },
    { 'D',    0x22 },
    { 'F',    0x23 },
    { 'G',    0x24 },
    { 'H',    0x25 },
    { 'J',    0x26 },
    { 'K',    0x27 },
    { 'L',    0x28 },
    { '#',    0x2A },
    { 'Z',    0x31 },
    { 'X',    0x32 },
    { 'C',    0x33 },
    { 'V',    0x34 },
    { 'B',    0x35 },
    { 'N',    0x36 },
    { 'M',    0x37 },
    { ',',    0x38 },
    { '.',    0x39 },
    { '/',    0x3A },

};

/**
 * Non-printable keys. Assignable keys only.
 */
static SpecialKey special_keys[] = {
    { "bspc",   0x41 }, //
    { "ent",    0x44 },
    { "ctrl",   0x63 },
    { "caps",   0x62 },
    { "semi",   0x29 },
    { "r?",     0x2B }, // right mystery key
    { "lshft",  0x60 },
    { "l?",     0x30 }, // left mystery key
    { "rshft",  0x61 },
    { "alt",    0x64 }, // same for left and right :(
    { "lamiga", 0x66 },
    { "spc",    0x40 },
    { "ramiga", 0x67 },
    { "del",    0x46 },
    { "help",   0x5F },
    { "up",     0x4C },
    { "left",   0x4F },
    { "down",   0x4D },
    { "right",  0x4E },
};


#endif // KEY_DEFS_H
