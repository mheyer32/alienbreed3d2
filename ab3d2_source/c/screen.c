#include "screen.h"

#include <exec/ports.h>
#include <graphics/copper.h>
#include <graphics/gfx.h>
#include <graphics/gfxmacros.h>
#include <graphics/videocontrol.h>
#include <graphics/view.h>

#include <intuition/screens.h>
#include <proto/exec.h>
#include <proto/graphics.h>
#include <proto/intuition.h>
#include <exec/types.h>

#define ALIB_HARDWARE_CUSTOM
#include <proto/alib.h>

#include <SDI_compiler.h>

#include <stdio.h>

#define SCREEN_TITLEBAR_HACK


static PLANEPTR rasters[2];
struct BitMap bitmaps[2];


static CHIP WORD emptySprite[6];
static struct UCopList doubleHeightCopList;

void Vid_CloseMainScreen();

BOOL Vid_OpenMainScreen(void)
{
    LOCAL_SYSBASE();
    LOCAL_INTUITION();
    LOCAL_GFX();

    printf("%p %p %p\n", SysBase, IntuitionBase, GfxBase);

    for (int i = 0; i < 2; ++i) {
        if (!(rasters[i] = AllocRaster(SCREEN_WIDTH, SCREEN_HEIGHT * 8 + 1))) {
            goto fail;
        }
        InitBitMap(&bitmaps[i], 8, SCREEN_WIDTH, SCREEN_HEIGHT);

        PLANEPTR ptr = (PLANEPTR)(((ULONG)rasters[i] + 7) & ~7);
        for (int p = 0; p < 8; ++p) {
            bitmaps[i].Planes[p] = ptr;
            ptr += SCREEN_WIDTH * SCREEN_HEIGHT / 8;
        }
    }

    Vid_Screen1Ptr_l = bitmaps[0].Planes[0];
    Vid_Screen2Ptr_l = bitmaps[1].Planes[0];

    if (!(Vid_MainScreen_l =
              OpenScreenTags(NULL, SA_Width, SCREEN_WIDTH, SA_Height, SCREEN_HEIGHT, SA_Depth, 8, SA_BitMap,
                             (Tag)&bitmaps[0], SA_Type, CUSTOMSCREEN, SA_Quiet, 1,
#ifdef SCREEN_TITLEBAR_HACK
                             SA_ShowTitle, 0,
#else
                             SA_ShowTitle, 1,
#endif
                             SA_AutoScroll, 0, SA_FullPalette, 1, SA_DisplayID, PAL_MONITOR_ID, TAG_END, 0))) {
        goto fail;
    };

    Vid_DisplayMsgPort_l = CreateMsgPort();

    for (int s = 0; s < 2; ++s) {
        Vid_ScreenBuffers_vl[s] = AllocScreenBuffer(Vid_MainScreen_l, &bitmaps[s], 0);
        Vid_ScreenBuffers_vl[s]->sb_DBufInfo->dbi_DispMessage.mn_ReplyPort = Vid_DisplayMsgPort_l;
    }

    if (!(Vid_MainWindow_l = OpenWindowTags(NULL, WA_Left, 0, WA_Top, 0, WA_Width, SCREEN_WIDTH, WA_Height,
                                            SCREEN_HEIGHT, WA_CustomScreen, (Tag)Vid_MainScreen_l, WA_Activate, 1,
                                            WA_Borderless, 1, WA_RMBTrap, 1,  // prevent menu rendering
                                            WA_NoCareRefresh, 1, WA_SimpleRefresh, 1, WA_Backdrop, 1, TAG_END, 0))) {
        goto fail;
    }

    SetPointer(Vid_MainWindow_l, emptySprite, 1, 0, 0, 0);
    CallAsm(&LoadMainPalette);

    struct ViewPort *vp = ViewPortAddress(Vid_MainWindow_l);
    VideoControlTags(vp->ColorMap, VTAG_USERCLIP_SET, 1, VTAG_END_CM, 0);

    const LONG RepeatLineModulo = -SCREEN_WIDTH / 8 - 8;
    const LONG SkipLineModulo = SCREEN_WIDTH / 8 - 8;

// There is a problem with the NDK. custom.h defines all custom chip registers
// as volatile, but CMove takes a non-volatile pointer, resulting in
// "error: initialization discards 'volatile' qualifier from pointer target type "
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wdiscarded-qualifiers"
    CINIT(&doubleHeightCopList, 116 * 6 + 4);  // 232 modulos

    int line;
    for (line = 0; line < 232;) {
        CWAIT(&doubleHeightCopList, line, 0);
        CMOVE(&doubleHeightCopList, bpl1mod, RepeatLineModulo);
        CMOVE(&doubleHeightCopList, bpl2mod, RepeatLineModulo);
        ++line;
        CWAIT(&doubleHeightCopList, line, 0);
        CMOVE(&doubleHeightCopList, bpl1mod, SkipLineModulo);
        CMOVE(&doubleHeightCopList, bpl2mod, SkipLineModulo);
        ++line;
    }
    CWAIT(&doubleHeightCopList, line, 0);
    CMOVE(&doubleHeightCopList, bpl1mod, -8);
    CMOVE(&doubleHeightCopList, bpl2mod, -8);
    CEND(&doubleHeightCopList);
#pragma GCC diagnostic pop

    return TRUE;

fail:

    Vid_CloseMainScreen();
    return FALSE;
}

void Vid_CloseMainScreen()
{
    LOCAL_INTUITION();
    LOCAL_GFX();
    if (Vid_MainWindow_l) {

        struct ViewPort *viewPort = ViewPortAddress(Vid_MainWindow_l);
        if (NULL != viewPort->UCopIns)
        {
            /*  Free the memory allocated for the Copper.  */
            FreeVPortCopLists(viewPort);
            RemakeDisplay();
        }

        CloseWindow(Vid_MainWindow_l);
        Vid_MainWindow_l = NULL;
    }

    for (int i = 0; i < 2; ++i) {
        if (Vid_ScreenBuffers_vl[i]) {
            FreeScreenBuffer(Vid_MainScreen_l, Vid_ScreenBuffers_vl[i]);
            Vid_ScreenBuffers_vl[i] = 0;
        }
    }

    if (Vid_MainScreen_l) {
        CloseScreen(Vid_MainScreen_l);
        Vid_MainScreen_l = NULL;
    }

    for (int i = 0; i < 2; ++i) {
        FreeRaster(rasters[i], SCREEN_WIDTH, SCREEN_HEIGHT * 8 + 1);
    }
}

void vid_SetupDoubleheightCopperlist(void)
{
//    LOCAL_SYSBASE();
//    LOCAL_INTUITION();

    struct ViewPort *vp = ViewPortAddress(Vid_MainWindow_l);
    Forbid();
    vp->UCopIns = (Vid_DoubleHeight_b ? &doubleHeightCopList : NULL);
    Permit();
    RethinkDisplay();
}
