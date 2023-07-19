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

#define VID_FAST_BUFFER_SIZE (SCREEN_WIDTH * SCREEN_HEIGHT + 4095)
#define PLANESIZE (SCREEN_WIDTH / 8 * SCREEN_HEIGHT)

#define AMMO_COUNT_X_COORD = 160
#define AMMO_COUNT_Y_COORD = (SCREEN_HEIGHT - 18);

#define ENERGY_COUNT_X_COORD = 160
#define ENERGY_COUNT_Y_COORD = (SCREEN_HEIGHT - 18);

/* These define the size of the digits used in the ammo/energy display */
#define BORDER_CHAR_WIDTH 8
#define BORDER_CHAR_HEIGHT 7

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

static UBYTE *FastBufferAllocPtr;


static void draw_ConvertLargeBorderDigits(UBYTE* chunky, const UBYTE *planar);
static void draw_PlanarToChunky(UBYTE *chunky, const PLANEPTR *planes, ULONG numPixels);
static void draw_ValueToDigits(UWORD value, UWORD digits[3]);
static void draw_LargeBorderDigitRTG(UBYTE* drawPtr, const UBYTE *glyphs, ULONG digit);

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

	draw_ConvertLargeBorderDigits(
		draw_BorderDigitsWarn,
		draw_BorderChars_vb + 15 * BORDER_CHAR_WIDTH * 10
	);

	draw_ConvertLargeBorderDigits(
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
            UnLockBitMap(bmHandle);
        }
    }
}

void Draw_LineOfText(REG(a0, const char *ptr), REG(a1, APTR screenPointer), REG(d0,  ULONG xxxx))
{

}

void Draw_BorderAmmoBar()
{
    if (!Vid_isRTG) {
		return;
	}
	LOCAL_CYBERGFX();

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
		UWORD digits[3];

		draw_ValueToDigits(draw_DisplayAmmoCount_w, digits);
		const UBYTE *glyphs = draw_DisplayAmmoCount_w > 9 ? draw_BorderDigitsGood : draw_BorderDigitsWarn;

		ULONG offset = AMMO_COUNT_X_COORD + AMMO_COUNT_Y_COORD * SCREEN_WIDTH;

		UBYTE *drawPtr = (UBYTE*)bmBaseAdress;

		for (int i=0; i < 3; ++i, offset += 8) {
			draw_LargeBorderDigitRTG(drawPtr + offset, glyphs, digits[i]);
		}
		UnLockBitMap(bmHandle);
	}
}


void Draw_BorderEnergyBar()
{

}

/**********************************************************************************************************************/

static void draw_PlanarToChunky(UBYTE *chunky, PLANEPTR const *planes, ULONG numPixels)
{
    PLANEPTR pptr[8];
    memcpy(pptr, planes, sizeof(pptr));

    for (ULONG x = 0; x < numPixels / 8; ++x) {
        for (BYTE p = 0; p < 8; ++p) {
            chunky[p] = 0;
            UBYTE bit = 1 << (7 - p);
            for (BYTE b = 0; b < 8; ++b) {
                if (*pptr[b] & bit) {
                    chunky[p] |= 1 << b;
                }
            }
        }
        chunky += 8;
        for (BYTE p = 0; p < 8; ++p) {
            pptr[p]++;
        }
    }
}

/**
 * Converts the border digits used for ammo/health from their initial planar representation to a chunky one
 */
static void draw_ConvertLargeBorderDigits(UBYTE* chunky_output, const UBYTE *planar_input) {

    PLANEPTR planes[8];

	const UBYTE *base_digit = planar_input;
	UBYTE *out_digit  = chunky_output;
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

static void draw_LargeBorderDigitRTG(UBYTE* drawPtr, const UBYTE *glyphs, ULONG digit) {
	const UBYTE *digitPtr = &glyphs[digit * BORDER_CHAR_WIDTH * BORDER_CHAR_HEIGHT];
	for (int y = 0; y < BORDER_CHAR_HEIGHT; ++y) {
	    for (int x=0; x < BORDER_CHAR_WIDTH; ++x) {
		    drawPtr[x] = *digitPtr++;
		}
		drawPtr += SCREEN_WIDTH;
	}
}

static void draw_ValueToDigits(UWORD value, UWORD digits[3]) {
	if (value > 999) {
		value = 999;
	}
	digits[2] = value % 10; value /= 10;
	digits[1] = value % 10; value /= 10;
	digits[0] = value;
}
