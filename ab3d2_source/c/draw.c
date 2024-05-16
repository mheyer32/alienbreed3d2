#include "draw.h"
#include "system.h"

/* We need to know the number of message lines to display in 2/3 planar */
#include "message.h"

#include <SDI_compiler.h>
#include <cybergraphics/cybergraphics.h>
#include <graphics/gfx.h>
#include <intuition/intuition.h>
#include <proto/cybergraphics.h>
#include <proto/exec.h>
#include <proto/graphics.h>

#include <string.h>

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
extern const UBYTE draw_BorderPacked_vb[];
extern UBYTE draw_BorderChars_vb[];
static UBYTE draw_Border[SCREEN_WIDTH * SCREEN_HEIGHT];

/* These are the fixed with planar glyphs used for in-game messages */
extern UBYTE draw_ScrollChars_vb[];

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
extern UBYTE draw_GlyphSpacing_vb[256];

/* Pointer to planar display */
extern APTR Vid_DisplayScreenPtr_l;

#ifdef GFX_LONG_ALIGNED
    #define COPY(s, d, c) CopyMemQuick((s), (d), (c))
#else
    #define COPY(s, d, c) CopyMem((s), (d), (c))
#endif

PLANEPTR Draw_FastRamPlanePtr      = NULL;
PLANEPTR Draw_BorderEdgeBackupPtr  = NULL;

/**
 * Border digits when not low on ammo/health
 *
 * In RTG modes, this contains chunky data. In native modes, this contains planar data reorganised so that all data for
 * each digit is sequentially arranged.
 */
static UBYTE draw_BorderDigitsGood[DRAW_HUD_CHAR_W * DRAW_HUD_CHAR_H * 10];

/**
 * Border digits when low on ammo/health
 *
 * In RTG modes, this contains chunky data. In native modes, this contains planar data reorganised so that all data for
 * each digit is sequentially arranged.
 */
static UBYTE draw_BorderDigitsWarn[DRAW_HUD_CHAR_W * DRAW_HUD_CHAR_H * 10];

/**
 * Border digits for items not yet located
 *
 * In RTG modes, this contains chunky data. In native modes, this contains planar data reorganised so that all data for
 * each digit is sequentially arranged.
 */
static UBYTE draw_BorderDigitsItem[DRAW_HUD_CHAR_SMALL_W * DRAW_HUD_CHAR_SMALL_H * 10];

/**
 * Border digits for items located
 *
 * In RTG modes, this contains chunky data. In native modes, this contains planar data reorganised so that all data for
 * each digit is sequentially arranged.
 */
static UBYTE draw_BorderDigitsItemFound[DRAW_HUD_CHAR_SMALL_W * DRAW_HUD_CHAR_SMALL_H * 10];

/**
 * Border digits for item selected
 *
 * In RTG modes, this contains chunky data. In native modes, this contains planar data reorganised so that all data for
 * each digit is sequentially arranged.
 */
static UBYTE draw_BorderDigitsItemSelected[DRAW_HUD_CHAR_SMALL_W * DRAW_HUD_CHAR_SMALL_H * 10];

static UWORD draw_LastItemList      = 0xFFFF;
static UWORD draw_LastItemSelected  = 0xFFFF;

/* Small buffer for rendering digit displays into */
static UBYTE draw_BorderDigitsBuffer[DRAW_HUD_CHAR_SMALL_H * DRAW_HUD_CHAR_SMALL_W * 10];

static UBYTE *FastBufferAllocPtr;

/**********************************************************************************************************************/

static void draw_PlanarToChunky(UBYTE *chunkyPtr, const PLANEPTR *planePtrs, ULONG numPixels);
static void draw_ValueToDigits(UWORD value, UWORD digits[3]);
static void draw_ConvertBorderDigitsToChunky(UBYTE* chunkyPtr, const UBYTE *planarBasePtr, UWORD width, UWORD height);
static void draw_ReorderBorderDigits(UBYTE* toPlanarPtr, const UBYTE *planarBasePtr, UWORD width, UWORD height);
static void draw_ChunkyGlyph(UBYTE *drawPtr, UWORD drawSpan, UBYTE charCode, UBYTE pen);

static void draw_UpdateCounter_RTG(
    APTR bmBaseAddress,
    ULONG bmBytesPerRow,
    UWORD count,
    UWORD limit,
    UWORD xPos,
    UWORD yPos
);

static void draw_UpdateCounter_Planar(
    APTR  planes,
    ULONG bytesPerRow,
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

static void draw_UpdateItems_Planar(
    APTR  planes,
    ULONG bytesPerRow,
    const UWORD* itemSlots,
    UWORD itemSelected,
    UWORD xPos,
    UWORD yPos
);

#ifdef GEN_GLYPH_DATA
UWORD Draw_MaxPropCharWidth = 0;
static void draw_CalculateGlyphSpacing(void);
#endif

#include "draw_inline.h"

/**********************************************************************************************************************/

/**
 * Main initialisation. Get buffers, do any preconversion needed, etc.
 */
BOOL Draw_Init()
{
    if (!(FastBufferAllocPtr = AllocVec(VID_FAST_BUFFER_SIZE, MEMF_ANY))) {
        goto fail;
    }

    Vid_FastBufferPtr_l = (UBYTE *)(((ULONG)FastBufferAllocPtr + 15) & ~15);


    void (*border_convert)(UBYTE* to, const UBYTE *from, UWORD width, UWORD height);

    if (Vid_isRTG) {
        BitPlanes planes;
        unLHA(Vid_FastBufferPtr_l, draw_BorderPacked_vb, 0, Sys_GetTemporaryWorkspace(), NULL);

        for (int p = 0; p < SCREEN_DEPTH; ++p) {
            planes[p] = Vid_FastBufferPtr_l + PLANESIZE * p;
        };

        /* The image we have has a fixed size */
        draw_PlanarToChunky(draw_Border, planes, SCREEN_WIDTH * SCREEN_HEIGHT);

        border_convert = draw_ConvertBorderDigitsToChunky;
    } else {
        border_convert = draw_ReorderBorderDigits;
    }

    /* Convert the "low ammo/health" counter digits */
    border_convert(
        draw_BorderDigitsWarn,
        draw_BorderChars_vb + 15 * DRAW_HUD_CHAR_W * 10,
        DRAW_HUD_CHAR_W,
        DRAW_HUD_CHAR_H
    );

    /* Convert the normal counter digits */
    border_convert(
        draw_BorderDigitsGood,
        draw_BorderChars_vb + 15 * DRAW_HUD_CHAR_W * 10 + DRAW_HUD_CHAR_H * DRAW_HUD_CHAR_W * 10,
        DRAW_HUD_CHAR_W,
        DRAW_HUD_CHAR_H
    );

    /* Convert the unavailable item digits */
    border_convert(
        draw_BorderDigitsItem,
        draw_BorderChars_vb,
        DRAW_HUD_CHAR_SMALL_W,
        DRAW_HUD_CHAR_SMALL_H
    );

    /* Convert the available item digits */
    border_convert(
        draw_BorderDigitsItemFound,
        draw_BorderChars_vb + DRAW_HUD_CHAR_SMALL_H * 10 * DRAW_HUD_CHAR_SMALL_W,
        DRAW_HUD_CHAR_SMALL_W,
        DRAW_HUD_CHAR_SMALL_H
    );

    /* Convert the selected item digits */
    border_convert(
        draw_BorderDigitsItemSelected,
        draw_BorderChars_vb + DRAW_HUD_CHAR_SMALL_H * 10 * DRAW_HUD_CHAR_SMALL_W * 2,
        DRAW_HUD_CHAR_SMALL_W,
        DRAW_HUD_CHAR_SMALL_H
    );

#ifdef GEN_GLYPH_DATA
    draw_CalculateGlyphSpacing();
#endif
    draw_ResetHUDCounters();

    return TRUE;

fail:
    Draw_Shutdown();
    return FALSE;
}

/**********************************************************************************************************************/

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

/**********************************************************************************************************************/

#define MSG_PLANE_H (DRAW_MSG_CHAR_H + DRAW_TEXT_Y_SPACING) * (MSG_MAX_LINES_SMALL + 1)

/**
 * Repairs the border area of the fast ram plane in planar text mode by copying back the
 * bits of the background image that were saved off during Draw_ResetGameDisplay().
 */
void Draw_RepairTextPlaneBorders()
{
    UWORD* src = (UWORD*)Draw_BorderEdgeBackupPtr;
    UWORD* dst = (UWORD*)Draw_FastRamPlanePtr;

    UWORD lines = MSG_PLANE_H;
    while (lines--) {
        // left edge
        dst[0] = *src++;
        // right edge
        dst[(SCREEN_WIDTH / 16) - 1] = *src++;
        dst += SCREEN_WIDTH / 16;
    }
}

static void draw_ConfigureTextPlane(void) {
    /*
     * For 2/3 screensize, use the end of the chunky buffer for the text plane. We need
     * enough space for the maximum number of lines (currently MSG_MAX_LINES_SMALL + 1)
     * at full width:
     *
     * SCREEN_WIDTH * (DRAW_MSG_CHAR_H + DRAW_TEXT_Y_SPACING) bits per text line.
     *
     * This is safe because the chunky buffer is always full screen size.
     */
    ULONG size = SCREEN_WIDTH * MSG_PLANE_H / 8;

    Draw_FastRamPlanePtr   = (PLANEPTR)(
        Vid_FastBufferPtr_l + (SCREEN_WIDTH * SCREEN_HEIGHT) - size
    );

    /**
     * We want to back up the left and right edge of the border for the bitplane we will
     * be writing into. The borders are 16 pixels wide, so we need 16 bits * 2 = 4 bytes
     * for each line of the plane.
     */

    size = 4 * MSG_PLANE_H;
    Draw_BorderEdgeBackupPtr  = Draw_FastRamPlanePtr - size;

    UWORD* dst = (UWORD*)Draw_BorderEdgeBackupPtr;
    UWORD* src = (UWORD*)&Vid_Screen2Ptr_l[PLANE_OFFSET(DRAW_TEXT_PLANE_NUM) + DRAW_TEXT_SMALL_PLANE_OFFSET];

    UWORD lines = MSG_PLANE_H;
    while (lines--) {
        // left edge
        *dst++ = src[0];
        // right edge
        *dst++ = src[(SCREEN_WIDTH / 16) - 1];
        src += SCREEN_WIDTH / 16;
    }
}

/**
 * Re initialise the game display, clear out the previous view, reset HUD, etc.
 */
void Draw_ResetGameDisplay()
{
    /* Retrigger the counters */
    draw_ResetHUDCounters();
    if (!Vid_isRTG) {
        unLHA(Vid_Screen1Ptr_l, draw_BorderPacked_vb, 0, Sys_GetTemporaryWorkspace(), NULL);
        unLHA(Vid_Screen2Ptr_l, draw_BorderPacked_vb, 0, Sys_GetTemporaryWorkspace(), NULL);
        Draw_UpdateBorder_Planar();
        if (!Vid_FullScreen_b) {
            draw_ConfigureTextPlane();
        }
    } else {
        LOCAL_CYBERGFX();

        Sys_MemFillLong(Vid_FastBufferPtr_l, 0, (SCREEN_WIDTH * SCREEN_HEIGHT) >> 2);

        ULONG bmBytesPerRow;
        APTR bmBaseAddress;

        APTR bmHandle = LockBitMapTags(
            Vid_MainScreen_l->ViewPort.RasInfo->BitMap,
            LBMI_BYTESPERROW, (ULONG)&bmBytesPerRow,
            LBMI_BASEADDRESS, (ULONG)&bmBaseAddress,
            TAG_DONE
        );
        if (bmHandle) {
            const UBYTE *src = draw_Border;
            WORD height = Vid_ScreenHeight < SCREEN_HEIGHT ? Vid_ScreenHeight : SCREEN_HEIGHT;
            src += (SCREEN_HEIGHT - height) * SCREEN_WIDTH;

            if (bmBytesPerRow == SCREEN_WIDTH) {
                COPY(src, bmBaseAddress, SCREEN_WIDTH * height);
            } else {
                for (WORD y = 0; y < height; ++y) {
                    COPY(src, bmBaseAddress, SCREEN_WIDTH);
                    bmBaseAddress += bmBytesPerRow;
                    src += SCREEN_WIDTH;
                }
            }
            Draw_UpdateBorder_RTG(bmBaseAddress, bmBytesPerRow);
            UnLockBitMap(bmHandle);
        }
    }
}


/**********************************************************************************************************************/

void Draw_ClearRect(UWORD x1, UWORD y1, UWORD x2, UWORD y2)
{
    SetAPen(&Vid_MainScreen_l->RastPort, 0);
    RectFill(&Vid_MainScreen_l->RastPort, x1, y1, x2, y2);
    SetAPen(&Vid_MainScreen_l->RastPort, 255);
}

/**********************************************************************************************************************/

/**
 * Draw a line of proportional text on the level intro screen
 *
 * TODO this is a relic now and will probably never be implemented
 */
void Draw_LineOfText(REG(a0, const char *ptr), REG(a1, APTR screenPointer), REG(d0,  ULONG xxxx))
{

}

/**********************************************************************************************************************/

/**
 * Calculate the pixel width of a string (up to maxLen or null, whichever comes first) when using proportional
 * rendering.
 */
ULONG Draw_CalcPropWidth(const char *textPtr, UWORD maxLen) {
    ULONG width = 0;
    UBYTE charCode;
    while ( (charCode = (UBYTE)*textPtr++) && maxLen-- > 0 ) {
        width += draw_GlyphSpacing_vb[charCode] >> 4;
    }
    return width;
}

UWORD Draw_CalcPropTextSplit(const char** nextTextPtr, UWORD txtLength, UWORD fitWidth) {

    /** Early out if the text length using the widest character possible is less than the fit width */
    if ((txtLength * DRAW_MSG_CHAR_W) <= fitWidth) {
        *nextTextPtr = NULL;
        return txtLength;
    }

    const char* textPtr            = *nextTextPtr;
    const char* lastNonPrintingPtr = NULL;
    UWORD width     = 0;
    UWORD charsLeft = txtLength;
    UBYTE charCode;

    /** Add up the width of the characters until we've used them all or overshot the width. Halt on null. */
    while ( charsLeft && width < fitWidth && (charCode = (UBYTE)*textPtr)) {
        if (!Draw_IsPrintable(charCode)) {
            lastNonPrintingPtr = textPtr;
        }
        width += draw_GlyphSpacing_vb[charCode] >> 4;
        --charsLeft;
        ++textPtr;
    }

    /**
     * Deal with width overshoot on the processed character. This is a bit dirty, but allows the main loop to be
     * simpler. If the loop exceeded the fitWidth, back up one char.
     */
    if (width > fitWidth) {
        charCode = *(--textPtr);
        ++charsLeft;
    }

    /** Avoid splitting words */
    if (lastNonPrintingPtr && charsLeft > 1 && Draw_IsPrintable(charCode)) {
        textPtr = lastNonPrintingPtr + 1;
    }

    /** Determine the width (in chars) of the text that fits */
    width = (UWORD)(textPtr - *nextTextPtr);

    /** If we hit a null or all characters were consumed, there is no text left to process */
    if (!charCode || !charsLeft) {
        textPtr = NULL;
    }

    /** Avoid space at the start of the next split */
    if (textPtr) {
        while (charsLeft > 0 && !Draw_IsPrintable(*textPtr)) {
            ++textPtr;
            --charsLeft;
        }
    }

    /** Update the source text pointer and return the width of the current segment */
    *nextTextPtr = textPtr;
    return width;
}

/**********************************************************************************************************************/

/**
 * Draw a glyph into the target buffer, filling only the set pixels with the desired pen. There are probably lots
 * of ways this can be optimised. Suitable for any chunky buffer.
 */
static void draw_ChunkyGlyph(UBYTE *drawPtr, UWORD drawSpan, UBYTE charCode, UBYTE pen)
{
    UBYTE *glyphPtr     = &draw_ScrollChars_vb[(UWORD)charCode << 3];
    UBYTE  glyphLMargin = draw_GlyphSpacing_vb[charCode] & 0x7;
    UBYTE  glyphWidth   = (draw_GlyphSpacing_vb[charCode] >> 4) - 1;
    for (UWORD row = 0; row < DRAW_MSG_CHAR_H; ++row) {
        UBYTE plane = *glyphPtr++;
        UBYTE width = glyphWidth;
        if (plane) {
            switch (glyphLMargin) {
                case 0: if (plane & 128) drawPtr[0] = pen; if (!--width) break;
                case 1: if (plane & 64)  drawPtr[1] = pen; if (!--width) break;
                case 2: if (plane & 32)  drawPtr[2] = pen; if (!--width) break;
                case 3: if (plane & 16)  drawPtr[3] = pen; if (!--width) break;
                case 4: if (plane & 8)   drawPtr[4] = pen; if (!--width) break;
                case 5: if (plane & 4)   drawPtr[5] = pen; if (!--width) break;
                case 6: if (plane & 2)   drawPtr[6] = pen; if (!--width) break;
                case 7: if (plane & 1)   drawPtr[7] = pen; if (!--width) break;
            }
        }
        drawPtr += drawSpan;
    }
}

/**********************************************************************************************************************/

/**
 * Draw a length limited, null terminated string of fixed glyphs at a given coordinate. Suitable for any chunky
 * buffer.
 */
const char* Draw_ChunkyText(
    UBYTE *drawPtr,
    UWORD drawSpan,
    UWORD maxLen,
    const char *textPtr,
    UWORD xPos,
    UWORD yPos,
    UBYTE pen
) {
    drawPtr += drawSpan * yPos + xPos;
    UBYTE charCode;
    while ( (charCode = (UBYTE)*textPtr++) && maxLen-- > 0 ) {
        /* Skip over all non-printing or blank. Assume ECMA-94 Latin 1 8-bit for Amiga 3.x */
        if (Draw_IsPrintable(charCode)) {
            draw_ChunkyGlyph(drawPtr, drawSpan, charCode, pen);
        }
        drawPtr += DRAW_MSG_CHAR_W;
    }
    return charCode ? textPtr : (const char*)NULL;
}

/**********************************************************************************************************************/

/**
 * Draw a length limited, null terminated string of proportional glyphs at a given coordinate. Suitable for any
 * chunky buffer.
 */
const char* Draw_ChunkyTextProp(
    UBYTE *drawPtr,
    UWORD drawSpan,
    UWORD maxLen,
    const char *textPtr,
    UWORD xPos,
    UWORD yPos,
    UBYTE pen
) {
    drawPtr += drawSpan * yPos + xPos;
    UBYTE charCode;
    while ( (charCode = (UBYTE)*textPtr++) && maxLen-- > 0 ) {
        UBYTE glyphSpacing = draw_GlyphSpacing_vb[charCode];
        /* Skip over all non-printing or blank. Assume ECMA-94 Latin 1 8-bit for Amiga 3.x */
        if (Draw_IsPrintable(charCode)) {
            draw_ChunkyGlyph(drawPtr - (glyphSpacing & 0xF), drawSpan, charCode, pen);
        }
        drawPtr += glyphSpacing >> 4;
    }
    return charCode ? textPtr : (const char*)NULL;
}

/**********************************************************************************************************************
 *
 * Border HUD stuff, RTG mode.
 *
 *********************************************************************************************************************/

/**
 * Render a counter single digit
 */
static void draw_RenderCounterDigit_RTG(UBYTE *drawPtr, const UBYTE *glyphPtr, UWORD digit, UWORD span) {

#ifdef GFX_LONG_ALIGNED
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

/**********************************************************************************************************************/

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
        COPY(bufferPtr, drawPtr, DRAW_COUNT_W);
    }
}

/**********************************************************************************************************************/

/**
 * Render a counter single digit
 */
static void draw_RenderItemDigit_RTG(UBYTE *drawPtr, const UBYTE *glyphPtr, UWORD digit, UWORD span) {

#ifdef GFX_LONG_ALIGNED
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

/**********************************************************************************************************************/

static void draw_UpdateItems_RTG(
    APTR bmBaseAddress,
    ULONG bmBytesPerRow,
    const UWORD* itemSlots,
    UWORD itemSelected,
    UWORD xPos,
    UWORD yPos
) {
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
        COPY(bufferPtr, drawPtr, DRAW_HUD_CHAR_SMALL_W * 10);
    }

}

/**********************************************************************************************************************/

/**
 * Called during Vid_Present on the RTG codepath to update the border within the main bitmap lock. Also called when
 * resizing the display.
 */
void Draw_UpdateBorder_RTG(APTR bmBaseAddress, ULONG bmBytesPerRow)
{
    INIT_ITEMS();

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

/**********************************************************************************************************************/

/**********************************************************************************************************************
 *
 * PLANAR MCPLANEFACE
 *
 * TODO - these routines can all be reimplemented as pure ASM as they can likely be improved significantly and will be
 *        needed by the ASM/AGA only build in any case.
 *
 **********************************************************************************************************************/

static __inline UWORD ror16(UWORD v, WORD s) {
    return (v >> s) | (v << (16 - s));
}

static void draw_PlanarGlyph(PLANEPTR drawPtr, WORD xPos, UBYTE charCode) {
    UBYTE *glyphPtr     = &draw_ScrollChars_vb[(UWORD)charCode << 3];
    BYTE   glyphLMargin = draw_GlyphSpacing_vb[charCode] & 0x7;
    BYTE   glyphWidth   = draw_GlyphSpacing_vb[charCode] >> 4;

    drawPtr += (xPos >> 3);
    xPos = (xPos & 7) - glyphLMargin;
    if (xPos < 0) {
        xPos = -xPos;
        drawPtr[0]                     |= glyphPtr[0] << xPos;
        drawPtr[SCREEN_WIDTH >> 3]     |= glyphPtr[1] << xPos;
        drawPtr[(2*SCREEN_WIDTH) >> 3] |= glyphPtr[2] << xPos;
        drawPtr[(3*SCREEN_WIDTH) >> 3] |= glyphPtr[3] << xPos;
        drawPtr[(4*SCREEN_WIDTH) >> 3] |= glyphPtr[4] << xPos;
        drawPtr[(5*SCREEN_WIDTH) >> 3] |= glyphPtr[5] << xPos;
        drawPtr[(6*SCREEN_WIDTH) >> 3] |= glyphPtr[6] << xPos;
        drawPtr[(7*SCREEN_WIDTH) >> 3] |= glyphPtr[7] << xPos;
    } else if (xPos == 0) {
        drawPtr[0]                     |= glyphPtr[0];
        drawPtr[SCREEN_WIDTH >> 3]     |= glyphPtr[1];
        drawPtr[(2*SCREEN_WIDTH) >> 3] |= glyphPtr[2];
        drawPtr[(3*SCREEN_WIDTH) >> 3] |= glyphPtr[3];
        drawPtr[(4*SCREEN_WIDTH) >> 3] |= glyphPtr[4];
        drawPtr[(5*SCREEN_WIDTH) >> 3] |= glyphPtr[5];
        drawPtr[(6*SCREEN_WIDTH) >> 3] |= glyphPtr[6];
        drawPtr[(7*SCREEN_WIDTH) >> 3] |= glyphPtr[7];
    } else if (xPos + glyphWidth >= DRAW_MSG_CHAR_W) {
        for (UWORD row = 0; row < DRAW_MSG_CHAR_H; ++row) {
            UWORD rot = ror16(glyphPtr[row], xPos);
            drawPtr[0] |= rot;
            drawPtr[1] |= rot >> 8;
            drawPtr += SCREEN_WIDTH >> 3;
        }
    } else {
        drawPtr[0]                     |= glyphPtr[0] >> xPos;
        drawPtr[SCREEN_WIDTH >> 3]     |= glyphPtr[1] >> xPos;
        drawPtr[(2*SCREEN_WIDTH) >> 3] |= glyphPtr[2] >> xPos;
        drawPtr[(3*SCREEN_WIDTH) >> 3] |= glyphPtr[3] >> xPos;
        drawPtr[(4*SCREEN_WIDTH) >> 3] |= glyphPtr[4] >> xPos;
        drawPtr[(5*SCREEN_WIDTH) >> 3] |= glyphPtr[5] >> xPos;
        drawPtr[(6*SCREEN_WIDTH) >> 3] |= glyphPtr[6] >> xPos;
        drawPtr[(7*SCREEN_WIDTH) >> 3] |= glyphPtr[7] >> xPos;
    }
}

/**
 * Draw a length limited, null terminated string of proportional glyphs at a given coordinate into a single
 * bitplane. The idea here is that for AGA only, we will render into a fast buffer and then copy that to a
 * target bitplane in chip ram so that the only chip ram accesses are long writes.
 */
const char* Draw_PlanarTextProp(
    PLANEPTR drawPtr,
    UWORD maxLen,
    const char *textPtr,
    UWORD xPos,
    UWORD yPos
) {

    // Advance into the target bitplane by the y position. x position is handled  in the glyph plotting
    // which needs it to work out bit shifts as well as basic byte offset.
    drawPtr += yPos * (SCREEN_WIDTH >> 3);

    UBYTE charCode;
    while ( (charCode = (UBYTE)*textPtr++) && maxLen-- > 0 ) {
        UBYTE glyphSpacing = draw_GlyphSpacing_vb[charCode];
        /* Skip over all non-printing or blank. Assume ECMA-94 Latin 1 8-bit for Amiga 3.x */
        if (Draw_IsPrintable(charCode)) {
            draw_PlanarGlyph(drawPtr, xPos, charCode);
        }
        xPos += glyphSpacing >> 4;
    }
    return charCode ? textPtr : (const char*)NULL;
}

/**********************************************************************************************************************
 *
 * Border HUD stuff, AGA mode.
 *
 *********************************************************************************************************************/

/**
 * Render a single item digit
 */
static void draw_RenderItemDigit_Planar(ULONG offset, const UBYTE *glyphPtr, UWORD digit, ULONG bytesPerRow) {
    const UBYTE *digitPtrBase = &glyphPtr[digit * DRAW_HUD_CHAR_SMALL_W * DRAW_HUD_CHAR_SMALL_H];
    PLANEPTR planes[2] = {
        Vid_Screen1Ptr_l,
        Vid_Screen2Ptr_l
    };

    for (UWORD p = 0; p < 2; ++p) {
        PLANEPTR drawPtr = planes[p] + offset;
        const UBYTE *digitPtr = digitPtrBase;
        for (UWORD y = 0; y < DRAW_HUD_CHAR_SMALL_H; ++y) {
            drawPtr[PLANE_OFFSET(0)] = *digitPtr++;
            drawPtr[PLANE_OFFSET(1)] = *digitPtr++;
            drawPtr[PLANE_OFFSET(2)] = *digitPtr++;
            drawPtr[PLANE_OFFSET(3)] = *digitPtr++;
            drawPtr[PLANE_OFFSET(4)] = *digitPtr++;
            drawPtr[PLANE_OFFSET(5)] = *digitPtr++;
            drawPtr[PLANE_OFFSET(6)] = *digitPtr++;
            drawPtr[PLANE_OFFSET(7)] = *digitPtr++;
            drawPtr += bytesPerRow;
        }
    }
}

/**********************************************************************************************************************/

static void draw_UpdateItems_Planar(APTR planes, ULONG bytesPerRow, const UWORD* itemSlots, UWORD itemSelected, UWORD xPos, UWORD yPos)
{
    /* TODO - fix up the buffer selection so that input planes is the required render target */

    ULONG offset = ((xPos + yPos * SCREEN_WIDTH) >> SCREEN_DEPTH_EXP);

    for (UWORD i = 0; i < DRAW_NUM_WEAPON_SLOTS; ++i, offset += (DRAW_HUD_CHAR_SMALL_W >> SCREEN_DEPTH_EXP)) {
        const UBYTE *glyphPtr = itemSelected == i ?
            draw_BorderDigitsItemSelected :
            itemSlots[i] ?
                draw_BorderDigitsItemFound :
                draw_BorderDigitsItem;

        draw_RenderItemDigit_Planar(offset, glyphPtr, i, bytesPerRow);
   }
}

/**********************************************************************************************************************/

/**
 * Render a single counter digit
 */
static void draw_RenderCounterDigit_Planar(ULONG offset, const UBYTE *glyphPtr, UWORD digit, ULONG bytesPerRow) {

    const UBYTE *digitPtrBase = &glyphPtr[digit * DRAW_HUD_CHAR_W * DRAW_HUD_CHAR_H];
    PLANEPTR planes[2] = {
        Vid_Screen1Ptr_l,
        Vid_Screen2Ptr_l
    };

    for (UWORD p = 0; p < 2; ++p) {
        PLANEPTR drawPtr = planes[p] + offset;
        const UBYTE *digitPtr = digitPtrBase;
        for (UWORD y = 0; y < DRAW_HUD_CHAR_H; ++y) {
            drawPtr[PLANE_OFFSET(0)] = *digitPtr++;
            drawPtr[PLANE_OFFSET(1)] = *digitPtr++;
            drawPtr[PLANE_OFFSET(2)] = *digitPtr++;
            drawPtr[PLANE_OFFSET(3)] = *digitPtr++;
            drawPtr[PLANE_OFFSET(4)] = *digitPtr++;
            drawPtr[PLANE_OFFSET(5)] = *digitPtr++;
            drawPtr[PLANE_OFFSET(6)] = *digitPtr++;
            drawPtr[PLANE_OFFSET(7)] = *digitPtr++;
            drawPtr += bytesPerRow;
        }
    }
}

static void draw_UpdateCounter_Planar(APTR planes, ULONG bytesPerRow, UWORD count, UWORD limit, UWORD xPos, UWORD yPos)
{
    UWORD digits[3];
    draw_ValueToDigits(count, digits);

    const UBYTE *glyphPtr = count > limit ?
        draw_BorderDigitsGood :
        draw_BorderDigitsWarn;

    ULONG offset = ((xPos + yPos * SCREEN_WIDTH) >> SCREEN_DEPTH_EXP);

    for (UWORD d = 0; d < 3; ++d, offset += DRAW_HUD_CHAR_W >> SCREEN_DEPTH_EXP) {
        draw_RenderCounterDigit_Planar(offset, glyphPtr, digits[d], bytesPerRow);
    }
}

void Draw_UpdateBorder_Planar(void)
{
    INIT_ITEMS();

    /* TODO - Determine the correct render target and rely on the pointer. For now, we ignore it and render to both */

    if (itemSelected != draw_LastItemSelected || itemList != draw_LastItemList) {
        draw_LastItemSelected = itemSelected;
        draw_LastItemList     = itemList;

        /* Inventory */
        draw_UpdateItems_Planar(
            Vid_DisplayScreenPtr_l,
            SCREEN_WIDTH / SCREEN_DEPTH,
            itemSlots,
            itemSelected,
            draw_ScreenXPos(DRAW_HUD_ITEM_SLOTS_X),
            draw_ScreenYPos(DRAW_HUD_ITEM_SLOTS_Y)
        );
    }
    /* Ammunition */
    if (draw_LastDisplayAmmoCount_w != draw_DisplayAmmoCount_w) {
        draw_LastDisplayAmmoCount_w = draw_DisplayAmmoCount_w;
        draw_UpdateCounter_Planar(
            Vid_DisplayScreenPtr_l,
            SCREEN_WIDTH / SCREEN_DEPTH,
            draw_DisplayAmmoCount_w,
            LOW_AMMO_COUNT_WARN_LIMIT,
            draw_ScreenXPos(DRAW_HUD_AMMO_COUNT_X),
            draw_ScreenYPos(DRAW_HUD_AMMO_COUNT_Y)
        );
    }

    /* Energy */
    if (draw_LastDisplayEnergyCount_w != draw_DisplayEnergyCount_w) {
        draw_LastDisplayEnergyCount_w = draw_DisplayEnergyCount_w;
        draw_UpdateCounter_Planar(
            Vid_DisplayScreenPtr_l,
            SCREEN_WIDTH / SCREEN_DEPTH,
            draw_DisplayEnergyCount_w,
            LOW_ENERGY_COUNT_WARN_LIMIT,
            draw_ScreenXPos(DRAW_HUD_ENERGY_COUNT_X),
            draw_ScreenYPos(DRAW_HUD_ENERGY_COUNT_Y)
        );
    }
}

/**********************************************************************************************************************/

/* Lower level utility functions */

/**
 * Decimate a display value into 3 digits for the display counter.
 */
static void draw_ValueToDigits(UWORD value, UWORD digits[3]) {
    if (value > DISPLAY_COUNT_LIMIT) {
        value = DISPLAY_COUNT_LIMIT;
    }
    // Simple, ugly, decimation.
    digits[2] = value % 10; value /= 10;
    digits[1] = value % 10; value /= 10;
    digits[0] = value;
}

/**********************************************************************************************************************/

/**
 * Converts the border digits used for ammo/health from their initial planar representation to a chunky one
 */
static void draw_ConvertBorderDigitsToChunky(UBYTE* chunkyPtr, const UBYTE *planarBasePtr, UWORD width, UWORD height) {
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
 * Reorganises the planar data so that the data for all digits are stored consecutively. Each digit is stored as
 * 8 bytes per row, each byte representing a single bitplane.
 */
static void draw_ReorderBorderDigits(UBYTE* toPlanarPtr, const UBYTE *planarBasePtr, UWORD width, UWORD height) {
    BitPlanes planes;
    const UBYTE *base_digit = planarBasePtr;
    for (UWORD d = 0; d < 10; ++d) {
        const UBYTE *digit = base_digit + d;
        for (UWORD p = 0; p < 8; ++p) {
            planes[p] = (PLANEPTR)(digit + p * 10);
        }

        for (UWORD y = 0; y <  height; ++y) {
            for (UWORD p = 0; p < 8; ++p) {
                *toPlanarPtr++ = *planes[p];
                planes[p] += width * 10;
            }
        }
    }
}

/**********************************************************************************************************************/

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

/**********************************************************************************************************************/

#ifdef GEN_GLYPH_DATA

/**********************************************************************************************************************
 *
 * If compiled with GEN_GLYPH_DATA, we Calculate the char spacing data on initialisation and dump it. We can then
 * reuse the dumped file as a binary include afterwards.
 *
 **********************************************************************************************************************/


#include <stdio.h>

/**
 * Very simple algorithm to scan the fixed with 8x8 font and determine some offset/width properties based on the glyph
 * bit patterns. We scan and populate draw_GlyphSpacing_vb with that data so that we can render the glyphs fixed or
 * proportionally.
 *
 * The algorithm isn't particularly optimised but we only do it once.
 */
static void draw_CalculateGlyphSpacing() {
    UBYTE *glyphPtr = draw_ScrollChars_vb;
    for (UWORD i = 0; i < 256; ++i, glyphPtr += 8) {
        UBYTE left  = 0;
        UBYTE width = 4;

        /* OR together the 8 planes to get a single value that has the largest width set */
        UBYTE mask  = glyphPtr[0] | glyphPtr[1] | glyphPtr[2] | glyphPtr[3] |
                      glyphPtr[4] | glyphPtr[5] | glyphPtr[6] | glyphPtr[7];

        /* If the mask is zero, it means the glyph is empty. Assume the same space as the space glyph */
        if (mask) {
            UBYTE tmp = mask;
            while (!(tmp & 0x80)) {
                ++left;
                tmp <<= 1;
            }
            tmp = 0;
            while (!(mask & 0x01)) {
                ++tmp;
                mask >>= 1;
            }
            width = 9 - left - tmp;
        }
        if (width > Draw_MaxPropCharWidth) {
            Draw_MaxPropCharWidth = width;
        }

        draw_GlyphSpacing_vb[i] = width << 4 | left;
    }

    // Dump the generated table.
    FILE* handle = fopen("RAM:glyph_spacing.bin", "wb");
    if (handle) {
        fwrite(draw_GlyphSpacing_vb, 1, 256, handle);
        fclose(handle);
    }
    printf("MAX_PROP_CHAR_WIDTH %d\n", (int)Draw_MaxPropCharWidth);
}

#endif // GEN_GLYPH_DATA





