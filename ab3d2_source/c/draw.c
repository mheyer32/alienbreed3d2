#include "draw.h"
#include "screen.h"
#include "system.h"

#include <SDI_compiler.h>
#include <cybergraphics/cybergraphics.h>
#include <graphics/gfx.h>
#include <intuition/intuition.h>
#include <proto/cybergraphics.h>
#include <proto/exec.h>
#include <string.h>  //memset

#define RTG_LONG_ALIGNED

#define VID_FAST_BUFFER_SIZE (SCREEN_WIDTH * SCREEN_HEIGHT + 4095)
#define PLANESIZE (SCREEN_WIDTH / 8 * SCREEN_HEIGHT)

/* These are the positions in the border for the ammo and health glyphs to be rendered */
#define AMMO_COUNT_X_COORD 160
#define AMMO_COUNT_Y_COORD (SCREEN_HEIGHT - 18)
#define ENERGY_COUNT_X_COORD 272
#define ENERGY_COUNT_Y_COORD (SCREEN_HEIGHT - 18)

/* These define the size of the digits used in the ammo/energy display */
#define BORDER_CHAR_WIDTH 8
#define BORDER_CHAR_HEIGHT 7
#define DISPLAY_COUNT_WIDTH (3 * BORDER_CHAR_WIDTH)

/* These define limits for when the displayed count*/
#define LOW_AMMO_COUNT_WARN_LIMIT 9
#define LOW_ENERGY_COUNT_WARN_LIMIT 9
#define DISPLAY_COUNT_LIMIT 999

extern void unLHA(REG(a0, void *dst), REG(d0, const void *src), REG(d1, ULONG length), REG(a1, void *workspace),
                  REG(a2, void *X));

extern ULONG Sys_Workspace_vl[];
extern const UBYTE draw_BorderPacked_vb[];
extern UBYTE draw_BorderChars_vb[];
extern UWORD draw_DisplayEnergyCount_w;
extern UWORD draw_DisplayAmmoCount_w;

static UBYTE draw_Border[SCREEN_WIDTH * SCREEN_HEIGHT];

/* Border digits when not low on ammo/health */
static UBYTE draw_BorderDigitsGood[BORDER_CHAR_WIDTH * BORDER_CHAR_HEIGHT * 10];

/* Border digits when low on ammo/health */
static UBYTE draw_BorderDigitsWarn[BORDER_CHAR_WIDTH * BORDER_CHAR_HEIGHT * 10];

/* Small buffer for rendering the 3 digit counters into */
static UBYTE draw_BorderDigitsBuffer[DISPLAY_COUNT_WIDTH * BORDER_CHAR_HEIGHT];

static UBYTE *FastBufferAllocPtr;

/* Values used to track changes to the counters */
static UWORD draw_LastDisplayAmmoCount   = 0xFFFF;
static UWORD draw_LastDisplayEnergyCount = 0xFFFF;

static void draw_PlanarToChunky(UBYTE *chunky, const PLANEPTR *planes, ULONG numPixels);
static void draw_ValueToDigits(UWORD value, UWORD digits[3]);
static void draw_GenerateCounterDigits_RTG(UBYTE* chunky, const UBYTE *planar);
static void draw_RenderCounterDigit_RTG(UBYTE *drawPtr, const UBYTE *glyphs, UWORD digit, UWORD span);
static void draw_UpdateCounter_RTG(APTR bmBaseAdress, ULONG bmBytesPerRow, UWORD count, UWORD limit, UWORD xPos, UWORD yPos);

/**********************************************************************************************************************/

BOOL Draw_Init()
{
    if (!(FastBufferAllocPtr = AllocVec(VID_FAST_BUFFER_SIZE, MEMF_ANY))) {
        goto fail;
    }

    Vid_FastBufferPtr_l = (UBYTE *)(((ULONG)FastBufferAllocPtr + 15) & ~15);

    unLHA(Vid_FastBufferPtr_l, draw_BorderPacked_vb, 0, Sys_Workspace_vl, NULL);

    PLANEPTR planes[8];

    for (int p = 0; p < 8; ++p) {
        planes[p] = Vid_FastBufferPtr_l + PLANESIZE * p;
    };

    // The image we have has a fixed size
    draw_PlanarToChunky(draw_Border, planes, SCREEN_WIDTH * SCREEN_HEIGHT);

	draw_GenerateCounterDigits_RTG(
		draw_BorderDigitsWarn,
		draw_BorderChars_vb + 15 * BORDER_CHAR_WIDTH * 10
	);

	draw_GenerateCounterDigits_RTG(
		draw_BorderDigitsGood,
		draw_BorderChars_vb + 15 * BORDER_CHAR_WIDTH * 10 + BORDER_CHAR_HEIGHT*BORDER_CHAR_WIDTH * 10
	);

    return TRUE;

fail:
    Draw_Shutdown();
    return FALSE;
}

void Draw_Shutdown()
{
    if (FastBufferAllocPtr) {
        FreeVec(FastBufferAllocPtr);
        FastBufferAllocPtr = NULL;
    }
}

void Draw_ResetGameDisplay()
{
    if (!Vid_isRTG) {
        unLHA(Vid_Screen1Ptr_l, draw_BorderPacked_vb, 0, Sys_Workspace_vl, NULL);
        unLHA(Vid_Screen2Ptr_l, draw_BorderPacked_vb, 0, Sys_Workspace_vl, NULL);
    } else {
        LOCAL_CYBERGFX();

        memset(Vid_FastBufferPtr_l, 0, SCREEN_WIDTH * SCREEN_HEIGHT);

        ULONG bmBytesPerRow;
        APTR bmBaseAdress;

        APTR bmHandle = LockBitMapTags(
            Vid_MainScreen_l->ViewPort.RasInfo->BitMap,
            LBMI_BYTESPERROW,
            (ULONG)&bmBytesPerRow,
            LBMI_BASEADDRESS,
            (ULONG)&bmBaseAdress,
            TAG_DONE
        );
        if (bmHandle) {
            const UBYTE *src = draw_Border;
            WORD height = Vid_ScreenHeight < SCREEN_HEIGHT ? Vid_ScreenHeight : SCREEN_HEIGHT;
            src += (SCREEN_HEIGHT - height) * SCREEN_WIDTH;

            if (bmBytesPerRow == SCREEN_WIDTH) {
                memcpy(bmBaseAdress, src, SCREEN_WIDTH * height);
            } else {
                for (WORD y = 0; y < height; ++y) {
                    memcpy(bmBaseAdress, src, SCREEN_WIDTH);
                    bmBaseAdress += bmBytesPerRow;
                    src += SCREEN_WIDTH;
                }
            }

            /* Retrigger the counters */
            draw_LastDisplayAmmoCount   = 0xFFFF;
            draw_LastDisplayEnergyCount = 0xFFFF;
            Draw_UpdateBorder_RTG(bmBaseAdress, bmBytesPerRow);

            UnLockBitMap(bmHandle);
        }
    }
}


void Draw_LineOfText(REG(a0, const char *ptr), REG(a1, APTR screenPointer), REG(d0,  ULONG xxxx))
{

}

void Draw_BorderAmmoBar()
{

}


void Draw_BorderEnergyBar()
{

}

/**********************************************************************************************************************/

/**
 * Called during Vid_Present on the RTG codepath to update the border within the main bitmap lock. Also called when
 * resizing the display.
 */
void Draw_UpdateBorder_RTG(APTR bmBaseAdress, ULONG bmBytesPerRow)
{
    /* TODO weapon slots */

    /* Ammunition */
    if (draw_LastDisplayAmmoCount != draw_DisplayAmmoCount_w) {
        draw_LastDisplayAmmoCount = draw_DisplayAmmoCount_w;
        draw_UpdateCounter_RTG(
            bmBaseAdress,
            bmBytesPerRow,
            draw_DisplayAmmoCount_w,
            LOW_AMMO_COUNT_WARN_LIMIT,
            AMMO_COUNT_X_COORD,
            AMMO_COUNT_Y_COORD
        );
    }

    /* Energy */
    if (draw_LastDisplayEnergyCount != draw_DisplayEnergyCount_w) {
        draw_LastDisplayEnergyCount = draw_DisplayEnergyCount_w;
        draw_UpdateCounter_RTG(
            bmBaseAdress,
            bmBytesPerRow,
            draw_DisplayEnergyCount_w,
            LOW_ENERGY_COUNT_WARN_LIMIT,
            ENERGY_COUNT_X_COORD,
            ENERGY_COUNT_Y_COORD
        );
    }
}

/**
 * Convert planar assets to chunky
 */
static void draw_PlanarToChunky(UBYTE *chunkyPtr, PLANEPTR const *planePtrs, ULONG numPixels)
{
    PLANEPTR pptr[8];
    memcpy(pptr, planePtrs, sizeof(pptr));

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
        for (BYTE p = 0; p < 8; ++p) {
            pptr[p]++;
        }
    }
}

/**
 * Converts the border digits used for ammo/health from their initial planar representation to a chunky one
 */
static void draw_GenerateCounterDigits_RTG(UBYTE* chunkyPtr, const UBYTE *planarBasePtr) {
    PLANEPTR planes[8];
    const UBYTE *base_digit = planarBasePtr;
    UBYTE *out_digit  = chunkyPtr;
    for (int d = 0; d < 10; ++d) {
        const UBYTE *digit = base_digit + d;
        for (int p = 0; p < 8; ++p) {
            planes[p] = (PLANEPTR)(digit + p * 10);
        }

        for (int y = 0; y <  BORDER_CHAR_HEIGHT; ++y) {
            draw_PlanarToChunky(out_digit, planes, BORDER_CHAR_WIDTH);
            for (int p = 0; p < 8; ++p) {
                planes[p] += BORDER_CHAR_WIDTH * 10;
            }
            out_digit += BORDER_CHAR_WIDTH;
        }
    }
}

/**
 * Render a counter (3-digit) into
 */
static void draw_UpdateCounter_RTG(APTR bmBaseAdress, ULONG bmBytesPerRow, UWORD count, UWORD limit, UWORD xPos, UWORD yPos)
{
    UWORD digits[3];

    draw_ValueToDigits(count, digits);

    const UBYTE *glyphPtr = count > limit ?
        draw_BorderDigitsGood :
        draw_BorderDigitsWarn;

    /* Render the digits into the mini buffer */
    UBYTE* bufferPtr = draw_BorderDigitsBuffer;
    for (int i = 0; i < 3; ++i, bufferPtr += BORDER_CHAR_WIDTH) {
        draw_RenderCounterDigit_RTG(bufferPtr, glyphPtr, digits[i], DISPLAY_COUNT_WIDTH);
    }

    /* Copy the mini buffer to the bitmap */
    UBYTE* drawPtr = ((UBYTE*)bmBaseAdress) + xPos + yPos * bmBytesPerRow;

    bufferPtr = draw_BorderDigitsBuffer;
    for (int i = 0; i < BORDER_CHAR_HEIGHT; ++i, drawPtr += bmBytesPerRow, bufferPtr += DISPLAY_COUNT_WIDTH) {

#ifdef RTG_LONG_ALIGNED
        CopyMemQuick(bufferPtr, drawPtr, DISPLAY_COUNT_WIDTH);
#else
        memcpy(drawPtr, bufferPtr, DISPLAY_COUNT_WIDTH);
#endif
    }
}

/*
 * Render a counter single digit
 */
static void draw_RenderCounterDigit_RTG(UBYTE *drawPtr, const UBYTE *glyphPtr, UWORD digit, UWORD span) {

#ifdef RTG_LONG_ALIGNED
    const ULONG *digitPtr = (ULONG*)&glyphPtr[digit * BORDER_CHAR_WIDTH * BORDER_CHAR_HEIGHT];
    ULONG *drawPtr32 = (ULONG*)drawPtr;
    span >>= 2;
    for (int y = 0; y < BORDER_CHAR_HEIGHT; ++y) {
        for (int x = 0; x < BORDER_CHAR_WIDTH/sizeof(ULONG); ++x) {
            drawPtr32[x] = *digitPtr++;
        }
        drawPtr32 += span;
    }
#else
    const UBYTE *digitPtr = &glyphPtr[digit * BORDER_CHAR_WIDTH * BORDER_CHAR_HEIGHT];
    for (int y = 0; y < BORDER_CHAR_HEIGHT; ++y) {
        for (int x = 0; x < BORDER_CHAR_WIDTH; ++x) {
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
