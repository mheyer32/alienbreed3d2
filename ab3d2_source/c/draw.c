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

extern void unLHA(REG(a0, void *dst), REG(d0, const void *src), REG(d1, ULONG length), REG(a1, void *workspace),
                  REG(a2, void *X));

extern const UBYTE draw_BorderPacked_vb[];
extern ULONG Sys_Workspace_vl[];

static UBYTE draw_Border[SCREEN_WIDTH * SCREEN_HEIGHT];
static UBYTE *FastBufferAllocPtr;

static void PlanarToChunky(UBYTE *chunky, const PLANEPTR *planes, ULONG numPixels);

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
    PlanarToChunky(draw_Border, planes, SCREEN_WIDTH * SCREEN_HEIGHT);

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

static void PlanarToChunky(UBYTE *chunky, PLANEPTR const *planes, ULONG numPixels)
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

        APTR bmHandle = LockBitMapTags(Vid_MainScreen_l->ViewPort.RasInfo->BitMap, LBMI_BYTESPERROW,
                                       (ULONG)&bmBytesPerRow, LBMI_BASEADDRESS, (ULONG)&bmBaseAdress, TAG_DONE);
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

}


void Draw_BorderEnergyBar()
{

}
