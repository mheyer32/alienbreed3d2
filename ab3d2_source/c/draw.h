#ifndef DRAW_H
#define DRAW_H

#include <exec/types.h>
#include "screen.h"

/**
 * These are the positions in the border for the ammo and health glyphs to be rendered
 *
 * Negative values are relative to the right / bottom of the display.
 */
#define DRAW_HUD_AMMO_COUNT_X 160
#define DRAW_HUD_AMMO_COUNT_Y -18
#define DRAW_HUD_ENERGY_COUNT_X 272
#define DRAW_HUD_ENERGY_COUNT_Y -18
#define DRAW_HUD_ITEM_SLOTS_X 24
#define DRAW_HUD_ITEM_SLOTS_Y -16

/* These define spacing used for text rendering. */
#define DRAW_TEXT_MARGIN 4
#define DRAW_TEXT_Y_SPACING 2

/* For 2/3 screen planar text rendering, this is the bit plane to draw into */
#define DRAW_TEXT_PLANE_NUM 4

/** For 2/3 screen planar text rendering , how far into the bitplane the text area is */
#define DRAW_TEXT_SMALL_PLANE_OFFSET ((SMALL_HEIGHT + SMALL_YPOS + DRAW_TEXT_Y_SPACING) * SCREEN_WIDTH / 8)

/* These define the size of characters used in in game message display */
#define DRAW_MSG_CHAR_W 8
#define DRAW_MSG_CHAR_H 8

/* These define the size of the digits used in the ammo/energy display */
#define DRAW_HUD_CHAR_W 8
#define DRAW_HUD_CHAR_H 7

/* These define the size of the digits used in the item list display */
#define DRAW_HUD_CHAR_SMALL_W 8
#define DRAW_HUD_CHAR_SMALL_H 5

#define DRAW_COUNT_W (3 * DRAW_HUD_CHAR_W)
#define DRAW_NUM_WEAPON_SLOTS 10

/* These define limits for when the displayed count*/
#define LOW_AMMO_COUNT_WARN_LIMIT 9
#define LOW_ENERGY_COUNT_WARN_LIMIT 9
#define DISPLAY_COUNT_LIMIT 999

/** For planar graphics, this is a type pun for the 8 bitplane pointers */
typedef PLANEPTR BitPlanes[SCREEN_DEPTH];

/** For planar screens, the offset to a given bitplane */
#define PLANE_OFFSET(n) ((n) * SCREEN_WIDTH * SCREEN_HEIGHT / SCREEN_DEPTH)

extern void Draw_ResetGameDisplay(void);
extern BOOL Draw_Init(void);
extern void Draw_Shutdown(void);
extern void Draw_UpdateBorder_RTG(APTR bmHandle, ULONG bmBytesPerRow);
extern void Draw_UpdateBorder_Planar(void);

extern void Draw_RepairTextPlaneBorders(void);

static __inline BOOL Draw_IsPrintable(UBYTE charCode) {
    return (charCode > 0x20 && charCode < 0x7F) || (charCode > 0xA0);
}

/**
 * These functions allow plotting the fixed text characters to a chunky buffer
 *
 * drawPtr  points to destination chunky buffer.
 * drawSpan defines the distance, in pixels, from one row of the chunky buffer to the next.
 * maxLen   defines the maximum number of characters to draw.
 * textPtr  ppoints to the string of text to draw. Will render up to maxLen characters or the first NULL byte.
 * xPos     defines the starting x coordinate in the chunky buffer
 * yPos     defines the starting y coordinate in the chunky buffer
 * fgPen    defines the palette index of the text rendering colour.
 * bgPen    defines the palette index of the background rendering colour (when using background).
 *
 * Returns a pointer to the next character to render, or null, if the end of the string was reached.
 */
extern const char* Draw_ChunkyText(
    UBYTE *drawPtr,
    UWORD drawSpan,
    UWORD maxLen,
    const char *textPtr,
    UWORD xPos,
    UWORD yPos,
    UBYTE pen
);

extern const char* Draw_ChunkyTextProp(
    UBYTE *drawPtr,
    UWORD drawSpan,
    UWORD maxLen,
    const char *textPtr,
    UWORD xPos,
    UWORD yPos,
    UBYTE pen
);

const char* Draw_PlanarTextProp(
    PLANEPTR drawPtr,
    UWORD maxLen,
    const char *textPtr,
    UWORD xPos,
    UWORD yPos
);

#ifdef GEN_GLYPH_DATA
extern UWORD Draw_MaxPropCharWidth;
#define MAX_PROP_CHAR_WIDTH Draw_MaxPropCharWidth
#else
// Calculated last time...
#define MAX_PROP_CHAR_WIDTH 7
#endif

/**
 * Calculate the expected pixel width of the provided string (up to the maximum length provided) based on proportional
 * size information.
 */
extern ULONG Draw_CalcPropWidth(const char *textPtr, UWORD maxLen);

/**
 * Evaluate the maximum number of characters from an input string that can be rendered proportionally in a given
 * width.
 *
 * Returns the number of characters that will fit and updates nextTextPtr to the position witin the input that
 * was reached.
 *
 */
extern UWORD Draw_CalcPropTextSplit(const char** nextTextPtr, UWORD txtLength, UWORD width);

extern UBYTE *Vid_FastBufferPtr_l;

extern void Draw_ClearRect(UWORD x1, UWORD y1, UWORD x2, UWORD y2);

extern PLANEPTR Draw_FastRamPlanePtr;
extern PLANEPTR Draw_BorderEdgeBackupPtr;

#endif // DRAW_H
