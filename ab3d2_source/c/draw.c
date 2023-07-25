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
 * TODO We do a lot of things here on the assumption that we are going to be using an RTG display, but that is a runtime
 * determined fact. We should only allocate and convert chunky representations of planar assets if, and only if, we are
 * on an RTG screen.
 */

#define RTG_LONG_ALIGNED

#define MULTIPLAYER_SLAVE  ((BYTE)'s')
#define MULTIPLAYER_MASTER ((BYTE)'m')


#define VID_FAST_BUFFER_SIZE (SCREEN_WIDTH * SCREEN_HEIGHT + 4095)
#define PLANESIZE (SCREEN_WIDTH / 8 * SCREEN_HEIGHT)

/* These define limits for when the displayed count*/
#define LOW_AMMO_COUNT_WARN_LIMIT 9
#define LOW_ENERGY_COUNT_WARN_LIMIT 9
#define DISPLAY_COUNT_LIMIT 999

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


/* Small buffer for rendering digit displays into */
static UBYTE draw_BorderDigitsBuffer[DRAW_HUD_CHAR_SMALL_H * DRAW_HUD_CHAR_SMALL_W * 10];

static UBYTE *FastBufferAllocPtr;

static void draw_PlanarToChunky(UBYTE *chunky, const PLANEPTR *planes, ULONG numPixels);
static void draw_ValueToDigits(UWORD value, UWORD digits[3]);
static void draw_GenerateCounterDigits_RTG(UBYTE* chunky, const UBYTE *planar, UWORD height);
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

/**********************************************************************************************************************/

BOOL Draw_Init()
{
    if (!(FastBufferAllocPtr = AllocVec(VID_FAST_BUFFER_SIZE, MEMF_FAST))) {
        goto fail;
    }

    Vid_FastBufferPtr_l = (UBYTE *)(((ULONG)FastBufferAllocPtr + 15) & ~15);

    unLHA(Vid_FastBufferPtr_l, draw_BorderPacked_vb, 0, Sys_Workspace_vl, NULL);

    BitPlanes planes;

    for (int p = 0; p < 8; ++p) {
        planes[p] = Vid_FastBufferPtr_l + PLANESIZE * p;
    };

    // The image we have has a fixed size
    draw_PlanarToChunky(draw_Border, planes, SCREEN_WIDTH * SCREEN_HEIGHT);

    draw_GenerateCounterDigits_RTG(
        draw_BorderDigitsWarn,
        draw_BorderChars_vb + 15 * DRAW_HUD_CHAR_W * 10,
        DRAW_HUD_CHAR_H
    );

    draw_GenerateCounterDigits_RTG(
        draw_BorderDigitsGood,
        draw_BorderChars_vb + 15 * DRAW_HUD_CHAR_W * 10 + DRAW_HUD_CHAR_H*DRAW_HUD_CHAR_W * 10,
        DRAW_HUD_CHAR_H
    );

    draw_GenerateCounterDigits_RTG(
        draw_BorderDigitsItem,
        draw_BorderChars_vb,
        DRAW_HUD_CHAR_SMALL_H
    );

    draw_GenerateCounterDigits_RTG(
        draw_BorderDigitsItemFound,
        draw_BorderChars_vb + DRAW_HUD_CHAR_SMALL_H * 10 * DRAW_HUD_CHAR_SMALL_W,
        DRAW_HUD_CHAR_SMALL_H
    );

    draw_GenerateCounterDigits_RTG(
        draw_BorderDigitsItemSelected,
        draw_BorderChars_vb + DRAW_HUD_CHAR_SMALL_H * 10 * DRAW_HUD_CHAR_SMALL_W * 2,
        DRAW_HUD_CHAR_SMALL_H
    );

    draw_LastDisplayAmmoCount_w =
    draw_LastDisplayEnergyCount_w = 0xFFFF;

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
        APTR bmBaseAddress;

        APTR bmHandle = LockBitMapTags(
            Vid_MainScreen_l->ViewPort.RasInfo->BitMap,
            LBMI_BYTESPERROW,
            (ULONG)&bmBytesPerRow,
            LBMI_BASEADDRESS,
            (ULONG)&bmBaseAddress,
            TAG_DONE
        );
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
            draw_LastDisplayAmmoCount_w   =
            draw_LastDisplayEnergyCount_w = 0xFFFF;
            Draw_UpdateBorder_RTG(bmBaseAddress, bmBytesPerRow);

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
void Draw_UpdateBorder_RTG(APTR bmBaseAddress, ULONG bmBytesPerRow)
{
    const UWORD* itemSlots;
    UWORD itemSelected;

    if (Plr_MultiplayerType_b == MULTIPLAYER_SLAVE) {
        itemSlots    = Plr2_Weapons_vb;
        itemSelected = Plr2_TmpGunSelected_b;
    }
    else {
        itemSlots    = Plr1_Weapons_vb;
        itemSelected = Plr1_TmpGunSelected_b;
    }

    draw_UpdateItems_RTG(
        bmBaseAddress,
        bmBytesPerRow,
        itemSlots,
        itemSelected,
        DRAW_HUD_ITEM_SLOTS_X,
        DRAW_HUD_ITEM_SLOTS_Y
    );

    /* Ammunition */
    if (draw_LastDisplayAmmoCount_w != draw_DisplayAmmoCount_w) {
        draw_LastDisplayAmmoCount_w = draw_DisplayAmmoCount_w;
        draw_UpdateCounter_RTG(
            bmBaseAddress,
            bmBytesPerRow,
            draw_DisplayAmmoCount_w,
            LOW_AMMO_COUNT_WARN_LIMIT,
            DRAW_HUD_AMMO_COUNT_X,
            DRAW_HUD_AMMO_COUNT_Y
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
            DRAW_HUD_ENERGY_COUNT_X,
            DRAW_HUD_ENERGY_COUNT_Y
        );
    }
}

/**
 * Convert planar assets to chunky
 */
static void draw_PlanarToChunky(UBYTE *chunkyPtr, PLANEPTR const *planePtrs, ULONG numPixels)
{
    BitPlanes pptr;
    for (BYTE p = 0; p < 8; ++p) {
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
        for (BYTE p = 0; p < 8; ++p) {
            pptr[p]++;
        }
    }
}

/**
 * Converts the border digits used for ammo/health from their initial planar representation to a chunky one
 */
static void draw_GenerateCounterDigits_RTG(UBYTE* chunkyPtr, const UBYTE *planarBasePtr, UWORD height) {
    BitPlanes planes;
    const UBYTE *base_digit = planarBasePtr;
    UBYTE *out_digit  = chunkyPtr;
    for (int d = 0; d < 10; ++d) {
        const UBYTE *digit = base_digit + d;
        for (int p = 0; p < 8; ++p) {
            planes[p] = (PLANEPTR)(digit + p * 10);
        }

        for (UWORD y = 0; y <  height; ++y) {
            draw_PlanarToChunky(out_digit, planes, DRAW_HUD_CHAR_W);
            for (int p = 0; p < 8; ++p) {
                planes[p] += DRAW_HUD_CHAR_W * 10;
            }
            out_digit += DRAW_HUD_CHAR_W;
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
    for (int i = 0; i < 3; ++i, bufferPtr += DRAW_HUD_CHAR_W) {
        draw_RenderCounterDigit_RTG(bufferPtr, glyphPtr, digits[i], DRAW_COUNT_W);
    }

    /* Copy the mini buffer to the bitmap */
    UBYTE* drawPtr = ((UBYTE*)bmBaseAddress) + xPos + yPos * bmBytesPerRow;

    bufferPtr = draw_BorderDigitsBuffer;
    for (int i = 0; i < DRAW_HUD_CHAR_H; ++i, drawPtr += bmBytesPerRow, bufferPtr += DRAW_COUNT_W) {

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
    for (UBYTE i=0; i < DRAW_NUM_WEAPON_SLOTS; ++i, bufferPtr += DRAW_HUD_CHAR_SMALL_W) {
        const UBYTE *glyphPtr = itemSelected == i ?
            draw_BorderDigitsItemSelected :
            itemSlots[i] ?
                draw_BorderDigitsItemFound :
                draw_BorderDigitsItem;
        draw_RenderItemDigit_RTG(bufferPtr, glyphPtr, i, DRAW_HUD_CHAR_SMALL_W*10);
    }

    /* Copy the mini buffer to the bitmap */
    bufferPtr = draw_BorderDigitsBuffer;
    for (int i = 0; i < DRAW_HUD_CHAR_SMALL_H; ++i, drawPtr += bmBytesPerRow, bufferPtr += DRAW_HUD_CHAR_SMALL_W*10) {

#ifdef RTG_LONG_ALIGNED
        CopyMemQuick(bufferPtr, drawPtr, DRAW_HUD_CHAR_SMALL_W*10);
#else
        memcpy(drawPtr, bufferPtr, DRAW_HUD_CHAR_SMALL_W*10);
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
    for (int y = 0; y < DRAW_HUD_CHAR_H; ++y) {
        for (int x = 0; x < DRAW_HUD_CHAR_W/sizeof(ULONG); ++x) {
            drawPtr32[x] = *digitPtr++;
        }
        drawPtr32 += span;
    }
#else
    const UBYTE *digitPtr = &glyphPtr[digit * DRAW_HUD_CHAR_W * DRAW_HUD_CHAR_H];
    for (int y = 0; y < DRAW_HUD_CHAR_H; ++y) {
        for (int x = 0; x < DRAW_HUD_CHAR_W; ++x) {
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
    for (int y = 0; y < DRAW_HUD_CHAR_SMALL_H; ++y) {
        for (int x = 0; x < DRAW_HUD_CHAR_SMALL_W/sizeof(ULONG); ++x) {
            drawPtr32[x] = *digitPtr++;
        }
        drawPtr32 += span;
    }
#else
    const UBYTE *digitPtr = &glyphPtr[digit * DRAW_HUD_CHAR_SMALL_W * DRAW_HUD_CHAR_SMALL_H];
    for (int y = 0; y < DRAW_HUD_CHAR_SMALL_H; ++y) {
        for (int x = 0; x < DRAW_HUD_CHAR_SMALL_W; ++x) {
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
