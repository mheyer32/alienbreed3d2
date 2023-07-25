#include "draw.h"
#include "system.h"

#include <SDI_compiler.h>
#include <cybergraphics/cybergraphics.h>
#include <graphics/gfx.h>
#include <intuition/intuition.h>
#include <proto/cybergraphics.h>
#include <proto/exec.h>
#include <string.h>  //memset

/**
 * TODO - dynamically allocate chunky buffers for RTG along with the main display.
 */

#define MULTIPLAYER_SLAVE  ((BYTE)'s')
#define MULTIPLAYER_MASTER ((BYTE)'m')

#define VID_FAST_BUFFER_SIZE (SCREEN_WIDTH * SCREEN_HEIGHT + 4095)
#define PLANESIZE (SCREEN_WIDTH / 8 * SCREEN_HEIGHT)

extern void unLHA(REG(a0, void *dst), REG(d0, const void *src), REG(d1, ULONG length), REG(a1, void *workspace),
                  REG(a2, void *X));

/* Externally declared buffers */
extern ULONG Sys_Workspace_vl[];
extern const UBYTE draw_BorderPacked_vb[];
extern UBYTE draw_BorderChars_vb[];
static UBYTE draw_Border[SCREEN_WIDTH * SCREEN_HEIGHT];

/* Values used to track changes to the counters */
extern UWORD draw_DisplayEnergyCount_w;
extern UWORD draw_DisplayAmmoCount_w;
extern UWORD draw_LastDisplayAmmoCount_w;
extern UWORD draw_LastDisplayEnergyCount_w;
extern BYTE  Plr_MultiplayerType_b;
extern UBYTE Plr1_TmpGunSelected_b;
extern UBYTE Plr2_TmpGunSelected_b;
extern UWORD Plr1_Weapons_vb[DRAW_NUM_WEAPON_SLOTS];
extern UWORD Plr2_Weapons_vb[DRAW_NUM_WEAPON_SLOTS];

typedef PLANEPTR BitPlanes[8];

/* Border digits when not low on ammo/health */
static UBYTE draw_BorderDigitsGood[DRAW_HUD_CHAR_W * DRAW_HUD_CHAR_H * 10];

/* Border digits when low on ammo/health */
static UBYTE draw_BorderDigitsWarn[DRAW_HUD_CHAR_W * DRAW_HUD_CHAR_H * 10];

/** Border digits for items not yet located */
static UBYTE draw_BorderDigitsItem[DRAW_HUD_CHAR_SMALL_W * DRAW_HUD_CHAR_SMALL_H * 10];

/** Border digits for items located */
static UBYTE draw_BorderDigitsItemFound[DRAW_HUD_CHAR_SMALL_W * DRAW_HUD_CHAR_SMALL_H * 10];

/** Border digits for item selected */
static UBYTE draw_BorderDigitsItemSelected[DRAW_HUD_CHAR_SMALL_W * DRAW_HUD_CHAR_SMALL_H * 10];

static UWORD draw_LastItemList      = 0xFFFF;
static UWORD draw_LastItemSelected  = 0xFFFF;

/* Small buffer for rendering digit displays into */
static UBYTE draw_BorderDigitsBuffer[DRAW_HUD_CHAR_SMALL_H * DRAW_HUD_CHAR_SMALL_W * 10];

static UBYTE *FastBufferAllocPtr;

static void draw_PlanarToChunky(UBYTE *chunky, const PLANEPTR *planes, ULONG numPixels);
static void draw_ValueToDigits(UWORD value, UWORD digits[3]);
static void draw_ConvertPlanarDigits(UBYTE* chunky, const UBYTE *planar, UWORD width, UWORD height);
static void draw_RenderCounterDigit_RTG(UBYTE *drawPtr, const UBYTE *glyphs, UWORD digit, UWORD span);
static void draw_RenderItemDigit_RTG(UBYTE *drawPtr, const UBYTE *glyphs, UWORD digit, UWORD span);

static void draw_UpdateCounter_RTG(
    APTR bmBaseAddress,
    ULONG bmBytesPerRow,
    UWORD count,
    UWORD limit,
    UWORD xPos,
    UWORD yPos
);

static void draw_UpdateItems_RTG(
    APTR bmBaseAddress,
    ULONG bmBytesPerRow,
    const UWORD* itemSlots,
    UWORD itemSelected,
    UWORD xPos,
    UWORD yPos
);

/**
 * Reset the counters used to determine if the HUD has changed.
 */
static __inline void draw_ResetHUDCounters(void)
{
    draw_LastItemList =
    draw_LastItemSelected =
    draw_LastDisplayAmmoCount_w =
    draw_LastDisplayEnergyCount_w = 0xFFFF;
}

/**********************************************************************************************************************/

/**
 * Main initialisation. Get buffers, do any preconversion needed, etc.
 */
BOOL Draw_Init()
{
    if (!(FastBufferAllocPtr = AllocVec(VID_FAST_BUFFER_SIZE, MEMF_FAST))) {
        goto fail;
    }

    Vid_FastBufferPtr_l = (UBYTE *)(((ULONG)FastBufferAllocPtr + 15) & ~15);

    if (Vid_isRTG) {
        BitPlanes planes;
        unLHA(Vid_FastBufferPtr_l, draw_BorderPacked_vb, 0, Sys_Workspace_vl, NULL);

        for (int p = 0; p < 8; ++p) {
            planes[p] = Vid_FastBufferPtr_l + PLANESIZE * p;
        };

        /* The image we have has a fixed size */
        draw_PlanarToChunky(draw_Border, planes, SCREEN_WIDTH * SCREEN_HEIGHT);

        /* Convert the "low ammo/health" counter digits */
        draw_ConvertPlanarDigits(
            draw_BorderDigitsWarn,
            draw_BorderChars_vb + 15 * DRAW_HUD_CHAR_W * 10,
            DRAW_HUD_CHAR_W,
            DRAW_HUD_CHAR_H
        );

        /* Convert the normal counter digits */
        draw_ConvertPlanarDigits(
            draw_BorderDigitsGood,
            draw_BorderChars_vb + 15 * DRAW_HUD_CHAR_W * 10 + DRAW_HUD_CHAR_H * DRAW_HUD_CHAR_W * 10,
            DRAW_HUD_CHAR_W,
            DRAW_HUD_CHAR_H
        );

        /* Convert the unavailable item digits */
        draw_ConvertPlanarDigits(
            draw_BorderDigitsItem,
            draw_BorderChars_vb,
            DRAW_HUD_CHAR_SMALL_W,
            DRAW_HUD_CHAR_SMALL_H
        );

        /* Convert the available item digits */
        draw_ConvertPlanarDigits(
            draw_BorderDigitsItemFound,
            draw_BorderChars_vb + DRAW_HUD_CHAR_SMALL_H * 10 * DRAW_HUD_CHAR_SMALL_W,
            DRAW_HUD_CHAR_SMALL_W,
            DRAW_HUD_CHAR_SMALL_H
        );

        /* Convert the selected item digits */
        draw_ConvertPlanarDigits(
            draw_BorderDigitsItemSelected,
            draw_BorderChars_vb + DRAW_HUD_CHAR_SMALL_H * 10 * DRAW_HUD_CHAR_SMALL_W * 2,
            DRAW_HUD_CHAR_SMALL_W,
            DRAW_HUD_CHAR_SMALL_H
        );

    }

    draw_ResetHUDCounters();
    return TRUE;

fail:
    Draw_Shutdown();
    return FALSE;
}

/**
 * All done.
 */
void Draw_Shutdown()
{
    if (FastBufferAllocPtr) {
        FreeVec(FastBufferAllocPtr);
        FastBufferAllocPtr = NULL;
    }
}

/**
 * Re initialise the game display, clear out the previous view, reset HUD, etc.
 */
void Draw_ResetGameDisplay()
{
    if (!Vid_isRTG) {
        unLHA(Vid_Screen1Ptr_l, draw_BorderPacked_vb, 0, Sys_Workspace_vl, NULL);
        unLHA(Vid_Screen2Ptr_l, draw_BorderPacked_vb, 0, Sys_Workspace_vl, NULL);
    } else {
        LOCAL_CYBERGFX();

        memset(Vid_FastBufferPtr_l, 0, SCREEN_WIDTH * SCREEN_HEIGHT);

        ULONG bmBytesPerRow;
        APTR bmBaseAddress;

        APTR bmHandle = LockBitMapTags(Vid_MainScreen_l->ViewPort.RasInfo->BitMap,
                                       LBMI_BYTESPERROW, (ULONG)&bmBytesPerRow,
                                       LBMI_BASEADDRESS, (ULONG)&bmBaseAddress,
                                       TAG_DONE);
        if (bmHandle) {
            const UBYTE *src = draw_Border;
            WORD height = Vid_ScreenHeight < SCREEN_HEIGHT ? Vid_ScreenHeight : SCREEN_HEIGHT;
            src += (SCREEN_HEIGHT - height) * SCREEN_WIDTH;

            if (bmBytesPerRow == SCREEN_WIDTH) {
                memcpy(bmBaseAddress, src, SCREEN_WIDTH * height);
            } else {
                for (WORD y = 0; y < height; ++y) {
                    memcpy(bmBaseAddress, src, SCREEN_WIDTH);
                    bmBaseAddress += bmBytesPerRow;
                    src += SCREEN_WIDTH;
                }
            }

            /* Retrigger the counters */
            draw_ResetHUDCounters();
            Draw_UpdateBorder_RTG(bmBaseAddress, bmBytesPerRow);

            UnLockBitMap(bmHandle);
        }
    }
}

/**
 * Todo
 */
void Draw_LineOfText(REG(a0, const char *ptr), REG(a1, APTR screenPointer), REG(d0,  ULONG xxxx))
{

}

/**
 * Todo - implement AGA planar version of the HUD update
 */
void Draw_BorderAmmoBar()
{

}

/**
 * Todo - implement AGA planar version of the HUD update
 */
void Draw_BorderEnergyBar()
{

}

/**********************************************************************************************************************/

static __inline WORD draw_ScreenXPos(WORD xPos) {
    return xPos >= 0 ? xPos : Vid_ScreenWidth + xPos;
}

static __inline WORD draw_ScreenYPos(WORD yPos) {
    return yPos >= 0 ? yPos : Vid_ScreenHeight + yPos;
}

/**
 * Called during Vid_Present on the RTG codepath to update the border within the main bitmap lock. Also called when
 * resizing the display.
 */
void Draw_UpdateBorder_RTG(APTR bmBaseAddress, ULONG bmBytesPerRow)
{
    const UWORD* itemSlots;
    UWORD itemSelected;
    UWORD itemList = 0;

    if (Plr_MultiplayerType_b == MULTIPLAYER_SLAVE) {
        itemSlots    = Plr2_Weapons_vb;
        itemSelected = Plr2_TmpGunSelected_b;
    }
    else {
        itemSlots    = Plr1_Weapons_vb;
        itemSelected = Plr1_TmpGunSelected_b;
    }

    /**
     * Convert the item list to a simple bitfield for comparison.
     *
     * TODO We should come back and do the same thing to the original data in the assembler code, having a word per gun
     * is silly since ammo counts are tracked separately anyway. We can just use a bitfield as there are only 10 types
     * (provided we don't intend to extend that beyond say 32).
     */
    for (UWORD i = 0; i < DRAW_NUM_WEAPON_SLOTS; ++i) {
        itemList |= (itemSlots[i]) ? (1 << i) : 0;
    }

    if (itemSelected != draw_LastItemSelected || itemList != draw_LastItemList) {
        draw_LastItemSelected = itemSelected;
        draw_LastItemList     = itemList;

        /* Inventory */
        draw_UpdateItems_RTG(
            bmBaseAddress,
            bmBytesPerRow,
            itemSlots,
            itemSelected,
            draw_ScreenXPos(DRAW_HUD_ITEM_SLOTS_X),
            draw_ScreenYPos(DRAW_HUD_ITEM_SLOTS_Y)
        );
    }
    /* Ammunition */
    if (draw_LastDisplayAmmoCount_w != draw_DisplayAmmoCount_w) {
        draw_LastDisplayAmmoCount_w = draw_DisplayAmmoCount_w;
        draw_UpdateCounter_RTG(
            bmBaseAddress,
            bmBytesPerRow,
            draw_DisplayAmmoCount_w,
            LOW_AMMO_COUNT_WARN_LIMIT,
            draw_ScreenXPos(DRAW_HUD_AMMO_COUNT_X),
            draw_ScreenYPos(DRAW_HUD_AMMO_COUNT_Y)
        );
    }

    /* Energy */
    if (draw_LastDisplayEnergyCount_w != draw_DisplayEnergyCount_w) {
        draw_LastDisplayEnergyCount_w = draw_DisplayEnergyCount_w;
        draw_UpdateCounter_RTG(
            bmBaseAddress,
            bmBytesPerRow,
            draw_DisplayEnergyCount_w,
            LOW_ENERGY_COUNT_WARN_LIMIT,
            draw_ScreenXPos(DRAW_HUD_ENERGY_COUNT_X),
            draw_ScreenYPos(DRAW_HUD_ENERGY_COUNT_Y)
        );
    }
}

/**
 * Convert planar graphics to chunky
 */
static void draw_PlanarToChunky(UBYTE *chunkyPtr, const PLANEPTR *planePtrs, ULONG numPixels)
{
    BitPlanes pptr;
    for (UWORD p = 0; p < 8; ++p) {
        pptr[p] = planePtrs[p];
    }

    for (ULONG x = 0; x < numPixels / 8; ++x) {
        for (BYTE p = 0; p < 8; ++p) {
            chunkyPtr[p] = 0;
            UBYTE bit = 1 << (7 - p);
            for (BYTE b = 0; b < 8; ++b) {
                if (*pptr[b] & bit) {
                    chunkyPtr[p] |= 1 << b;
                }
            }
        }
        chunkyPtr += 8;
        for (UWORD p = 0; p < 8; ++p) {
            pptr[p]++;
        }
    }
}

/**
 * Converts the border digits used for ammo/health from their initial planar representation to a chunky one
 */
static void draw_ConvertPlanarDigits(UBYTE* chunkyPtr, const UBYTE *planarBasePtr, UWORD width, UWORD height) {
    BitPlanes planes;
    const UBYTE *base_digit = planarBasePtr;
    UBYTE *out_digit  = chunkyPtr;
    for (UWORD d = 0; d < 10; ++d) {
        const UBYTE *digit = base_digit + d;
        for (UWORD p = 0; p < 8; ++p) {
            planes[p] = (PLANEPTR)(digit + p * 10);
        }

        for (UWORD y = 0; y <  height; ++y) {
            draw_PlanarToChunky(out_digit, planes, width);
            for (UWORD p = 0; p < 8; ++p) {
                planes[p] += width * 10;
            }
            out_digit += width;
        }
    }
}

/**
 * Render a counter (3-digit) into
 */
static void draw_UpdateCounter_RTG(APTR bmBaseAddress, ULONG bmBytesPerRow, UWORD count, UWORD limit, UWORD xPos, UWORD yPos)
{
    UWORD digits[3];
    draw_ValueToDigits(count, digits);

    const UBYTE *glyphPtr = count > limit ?
        draw_BorderDigitsGood :
        draw_BorderDigitsWarn;

    /* Render the digits into the mini buffer */
    UBYTE* bufferPtr = draw_BorderDigitsBuffer;
    for (UWORD d = 0; d < 3; ++d, bufferPtr += DRAW_HUD_CHAR_W) {
        draw_RenderCounterDigit_RTG(bufferPtr, glyphPtr, digits[d], DRAW_COUNT_W);
    }

    /* Copy the mini buffer to the bitmap */
    UBYTE* drawPtr = ((UBYTE*)bmBaseAddress) + xPos + yPos * bmBytesPerRow;

    bufferPtr = draw_BorderDigitsBuffer;
    for (UWORD y = 0; y < DRAW_HUD_CHAR_H; ++y, drawPtr += bmBytesPerRow, bufferPtr += DRAW_COUNT_W) {

#ifdef RTG_LONG_ALIGNED
        CopyMemQuick(bufferPtr, drawPtr, DRAW_COUNT_W);
#else
        memcpy(drawPtr, bufferPtr, DRAW_COUNT_W);
#endif
    }
}

static void draw_UpdateItems_RTG(APTR bmBaseAddress, ULONG bmBytesPerRow, const UWORD* itemSlots, UWORD itemSelected, UWORD xPos, UWORD yPos) {
    UBYTE* drawPtr = ((UBYTE*)bmBaseAddress) + xPos + yPos * bmBytesPerRow;

    /* Render into the minibuffer */
    UBYTE *bufferPtr = draw_BorderDigitsBuffer;
    for (UWORD i = 0; i < DRAW_NUM_WEAPON_SLOTS; ++i, bufferPtr += DRAW_HUD_CHAR_SMALL_W) {
        const UBYTE *glyphPtr = itemSelected == i ?
            draw_BorderDigitsItemSelected :
            itemSlots[i] ?
                draw_BorderDigitsItemFound :
                draw_BorderDigitsItem;

        draw_RenderItemDigit_RTG(bufferPtr, glyphPtr, i, DRAW_HUD_CHAR_SMALL_W * 10);
    }

    /* Copy the mini buffer to the bitmap */
    bufferPtr = draw_BorderDigitsBuffer;
    for (UWORD i = 0; i < DRAW_HUD_CHAR_SMALL_H; ++i, drawPtr += bmBytesPerRow, bufferPtr += DRAW_HUD_CHAR_SMALL_W * 10) {

#ifdef RTG_LONG_ALIGNED
        CopyMemQuick(bufferPtr, drawPtr, DRAW_HUD_CHAR_SMALL_W * 10);
#else
        memcpy(drawPtr, bufferPtr, DRAW_HUD_CHAR_SMALL_W * 10);
#endif
    }

}

/**
 * Render a counter single digit
 */
static void draw_RenderCounterDigit_RTG(UBYTE *drawPtr, const UBYTE *glyphPtr, UWORD digit, UWORD span) {

#ifdef RTG_LONG_ALIGNED
    const ULONG *digitPtr = (ULONG*)&glyphPtr[digit * DRAW_HUD_CHAR_W * DRAW_HUD_CHAR_H];
    ULONG *drawPtr32 = (ULONG*)drawPtr;
    span >>= 2;
    for (UWORD y = 0; y < DRAW_HUD_CHAR_H; ++y) {
        for (UWORD x = 0; x < DRAW_HUD_CHAR_W / sizeof(ULONG); ++x) {
            drawPtr32[x] = *digitPtr++;
        }
        drawPtr32 += span;
    }
#else
    const UBYTE *digitPtr = &glyphPtr[digit * DRAW_HUD_CHAR_W * DRAW_HUD_CHAR_H];
    for (UWORD y = 0; y < DRAW_HUD_CHAR_H; ++y) {
        for (UWORD x = 0; x < DRAW_HUD_CHAR_W; ++x) {
            drawPtr[x] = *digitPtr++;
        }
        drawPtr += span;
    }
#endif
}

/**
 * Render a counter single digit
 */
static void draw_RenderItemDigit_RTG(UBYTE *drawPtr, const UBYTE *glyphPtr, UWORD digit, UWORD span) {

#ifdef RTG_LONG_ALIGNED
    const ULONG *digitPtr = (ULONG*)&glyphPtr[digit * DRAW_HUD_CHAR_SMALL_W * DRAW_HUD_CHAR_SMALL_H];
    ULONG *drawPtr32 = (ULONG*)drawPtr;
    span >>= 2;
    for (UWORD y = 0; y < DRAW_HUD_CHAR_SMALL_H; ++y) {
        for (UWORD x = 0; x < DRAW_HUD_CHAR_SMALL_W / sizeof(ULONG); ++x) {
            drawPtr32[x] = *digitPtr++;
        }
        drawPtr32 += span;
    }
#else
    const UBYTE *digitPtr = &glyphPtr[digit * DRAW_HUD_CHAR_SMALL_W * DRAW_HUD_CHAR_SMALL_H];
    for (UWORD y = 0; y < DRAW_HUD_CHAR_SMALL_H; ++y) {
        for (UWORD x = 0; x < DRAW_HUD_CHAR_SMALL_W; ++x) {
            drawPtr[x] = *digitPtr++;
        }
        drawPtr += span;
    }
#endif
}


static void draw_ValueToDigits(UWORD value, UWORD digits[3]) {
    if (value > DISPLAY_COUNT_LIMIT) {
        value = DISPLAY_COUNT_LIMIT;
    }
    // Simple, ugly, decimation.
    digits[2] = value % 10; value /= 10;
    digits[1] = value % 10; value /= 10;
    digits[0] = value;
}
