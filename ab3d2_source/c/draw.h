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

extern void Draw_ResetGameDisplay(void);
extern BOOL Draw_Init(void);
extern void Draw_Shutdown(void);
extern void Draw_UpdateBorder_RTG(APTR bmHandle, ULONG bmBytesPerRow);
extern void Draw_UpdateBorder_Planar(void);

extern UBYTE *Vid_FastBufferPtr_l;

#endif // DRAW_H
