#include "menu.h"

#include "screen.h"
#include "system.h"

#include <graphics/gfx.h>
#include <proto/graphics.h>
#include <proto/intuition.h>

#include <SDI_compiler.h>

#include <stdlib.h>  //abort

extern CHIP UBYTE mnu_morescreen[];
extern CHIP UBYTE mnu_screen[];
extern UBYTE mnu_background[];

extern struct Screen *MenuScreen;
extern struct Window *MenuWindow;
extern UWORD mnu_fadefactor;

extern void (*main_vblint)(void);
extern void mnu_vblint(void);
extern void mnu_init(void);
extern void mnu_fade(void);
extern void mnu_fadein(void);
extern void mnu_fadeout(void);
extern void mnu_initrnd(void);
extern void mnu_createpalette(void);

static CHIP WORD emptySprite[6];

static struct BitMap bm;

BOOL mnu_setscreen()
{
    LOCAL_GFX();
    LOCAL_INTUITION();

    InitBitMap(&bm, 8, SCREEN_WIDTH, SCREEN_HEIGHT);
    for (int p = 0; p < 8; ++p) {
        bm.Planes[p] = mnu_morescreen;
    }

    if (!(MenuScreen = OpenScreenTags(NULL, SA_Width, SCREEN_WIDTH, SA_Height, SCREEN_HEIGHT, SA_Depth, 8, SA_BitMap,
                                      (Tag)&bm, SA_Type, CUSTOMSCREEN, SA_Quiet, 1, SA_ShowTitle, 0, SA_AutoScroll, 0,
                                      SA_FullPalette, 1, SA_DisplayID, PAL_MONITOR_ID, TAG_END, 0))) {
        goto fail;
    };

    if (!(MenuWindow = OpenWindowTags(NULL, WA_Left, 0, WA_Top, 0, WA_Width, SCREEN_WIDTH, WA_Height, SCREEN_HEIGHT,
                                      WA_CustomScreen, (Tag)MenuScreen, WA_Activate, 1, WA_Borderless, 1, WA_RMBTrap,
                                      1,  // prevent menu rendering
                                      WA_NoCareRefresh, 1, WA_SimpleRefresh, 1, WA_Backdrop, 1, TAG_END, 0))) {
        goto fail;
    }

    SetPointer(MenuWindow, emptySprite, 1, 0, 0, 0);

    mnu_init();
    mnu_fadefactor = 0;
    CallAsm(mnu_fade);
    main_vblint = &mnu_vblint;
    CallAsm(mnu_fadein);

    return TRUE;

fail:
    abort();
}

static void SetBplPtrs(PLANEPTR *planePtr, PLANEPTR plane, UWORD numPlanes)
{
    for (int p = 0; p < numPlanes; ++p) {
        *planePtr++ = plane;
        plane += SCREEN_WIDTH / 8 * SCREEN_HEIGHT;
    }
}

void mnu_init(void)
{
    CallAsm(&mnu_initrnd);
    CallAsm(&mnu_createpalette);

    const int planeSize = SCREEN_WIDTH / 8 * SCREEN_HEIGHT;
    const int planeSizeL = planeSize / 4;

    const ULONG *firstPlane = (ULONG *)mnu_background;
    const ULONG *secondPlane = (ULONG *)(mnu_background + planeSize);

    // The first tow planes of the menu screen are double the height to alllow
    // for the scrolling effect. Copy the menu background over and duplicate it
    // vertically.
    ULONG *outPlanes = (ULONG *)mnu_screen;

    for (int j = 0; j < planeSizeL; ++j) {
        {
            ULONG x = firstPlane[j];
            outPlanes[j] = x;               // upper half first plane
            outPlanes[planeSizeL + j] = x;  // lower half as copy of upper half
        }
        {
            ULONG x = secondPlane[j];
            outPlanes[planeSizeL * 2 + j] = x;
            outPlanes[planeSizeL * 3 + j] = x;
        }
    }

    // 'mnu_morescreen' points to the planes used for the fire effect
    memset(mnu_morescreen, 0, planeSize * 3);

    struct BitMap *bm = MenuScreen->ViewPort.RasInfo->BitMap;
    SetBplPtrs(&bm->Planes[0], (PLANEPTR)mnu_screen, 1);
    SetBplPtrs(&bm->Planes[1], (PLANEPTR)mnu_screen + planeSize * 2, 1);
    SetBplPtrs(&bm->Planes[2], (PLANEPTR)mnu_morescreen, 6);

    ScrollVPort(&MenuScreen->ViewPort);
}

static inline void WaitBlits()
{
    extern volatile UBYTE mnu_bltbusy;
    while (mnu_bltbusy) {
    };
}

void mnu_clearscreen(void)
{
    LOCAL_GFX();
    LOCAL_INTUITION();

    CallAsm(&mnu_fadeout);
    main_vblint = NULL;  // don't kick off new frames/blits
    WaitBlits();         // let current blits finish
    WaitTOF();
    if (MenuWindow) {
        CloseWindow(MenuWindow);
        MenuWindow = NULL;
    }
    if (MenuScreen) {
        CloseScreen(MenuScreen);
        MenuScreen = NULL;
    }
}
