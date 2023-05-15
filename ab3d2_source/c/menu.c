#include "menu.h"

#include "screen.h"
#include "system.h"

#include <graphics/gfx.h>
#include <hardware/blit.h>
#include <hardware/custom.h>
#include <proto/graphics.h>
#include <proto/intuition.h>

#include <SDI_compiler.h>

#include <stdlib.h>  //abort

#define ALIB_HARDWARE_CUSTOM
#include <proto/alib.h>

extern CHIP UBYTE mnu_morescreen[];
extern CHIP UBYTE mnu_screen[];
extern UBYTE mnu_background[];

extern struct Screen *MenuScreen;
extern struct Window *MenuWindow;
extern UWORD mnu_fadefactor;

extern ULONG mnu_palette[256];  // 24bit colors 0x00RRGGBB
extern ULONG mnu_backpal[4];
extern ULONG mnu_firepal[8];
extern ULONG mnu_fontpal[8];
extern volatile UBYTE mnu_bltbusy;
extern ULONG main_counter;

extern UWORD mnu_rnd;
extern APTR mnu_rndptr;


extern void (*main_vblint)(void);
extern void mnu_vblint(void);
extern void mnu_init(void);
extern void mnu_fadein(void);
extern void mnu_fadeout(void);
extern void mnu_initrnd(void);
extern void mnu_createpalette(void);
extern void mnu_dofire(void);
extern void getrnd(void);

static void mnu_fade(UWORD fadeFactor);

static CHIP WORD emptySprite[6];
static struct BitMap bm;

static LONG mnu_subtract;
static UWORD mnu_count;

#define mnu_speed 1
#define mnu_size 256  // Menu screen height?
#define ROWSIZE (SCREEN_WIDTH / 8)
#define PLANESIZE (ROWSIZE * (SCREEN_HEIGHT))

//static APTR mnu_rndptr = mnu_morescreen + 6 * PLANESIZE;
static PLANEPTR mnu_sourceptrs[] = {mnu_morescreen + 3 * PLANESIZE + mnu_speed * ROWSIZE,
                                    mnu_morescreen + 4 * PLANESIZE + mnu_speed *ROWSIZE,
                                    mnu_morescreen + 5 * PLANESIZE + mnu_speed *ROWSIZE};

typedef int (*BltFuncPtr)();

static int SAVEDS mnu_pass2(REG(a0, volatile struct Custom *custom), REG(a1, struct bltnode *node));
static int SAVEDS mnu_pass3(REG(a0, volatile struct Custom *custom), REG(a1, struct bltnode *node));
static int SAVEDS mnu_pass4(REG(a0, volatile struct Custom *custom), REG(a1, struct bltnode *node));

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
    mnu_fade(0);
    main_vblint = &mnu_vblint;
    mnu_fadein();

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
    mnu_createpalette();

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
    while (mnu_bltbusy) {
    };
}

void mnu_clearscreen(void)
{
    LOCAL_GFX();
    LOCAL_INTUITION();

    mnu_fadeout();
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

static void mnu_fade(UWORD fadeFactor)
{
    ULONG outPal[768 + 2];
    outPal[0] = 256 << 16 | 0;

    for (int c = 0; c < 256; ++c) {
        UWORD r = (mnu_palette[c] >> 16);
        r *= fadeFactor;
        outPal[c * 3 + 1] = r << 16;
        ULONG g = (mnu_palette[c] >> 8) & 0xFF;
        g *= fadeFactor;
        outPal[c * 3 + 2] = g << 16;
        ULONG b = mnu_palette[c] & 0xFF;
        b *= fadeFactor;
        outPal[c * 3 + 3] = b << 16;
    }
    outPal[769] = 0;
    LoadRGB32(&MenuScreen->ViewPort, outPal);
}

static const UWORD mnu_fadespeed = 16;

void mnu_fadein(void)
{
    LOCAL_GFX();
    UWORD fadefactor = 0;
    UWORD steps = 256 / mnu_fadespeed;
    for (UWORD i = 0; i < steps; ++i) {
        WaitTOF();
        mnu_fade(fadefactor);
        fadefactor += mnu_fadespeed;
    }
    // One pass to make sure we're hitting the RGB * 1.0 case
    WaitTOF();
    mnu_fade(256);
}

void mnu_fadeout(void)
{
    LOCAL_GFX();
    UWORD fadefactor = 256;
    UWORD steps = 256 / mnu_fadespeed;
    for (UWORD i = 0; i < steps; ++i) {
        WaitTOF();
        mnu_fade(fadefactor);
        fadefactor -= mnu_fadespeed;
    }
    // One pass to make sure we're hitting the RGB * 0.0 case
    WaitTOF();
    mnu_fade(0);
}

void mnu_createpalette(void)
{
    for (WORD c = 0; c < 256; ++c) {
        if (c & 0xe0) {
            mnu_palette[c] = mnu_fontpal[c >> 5];
        } else {
            if (c & 0x1c) {
                ULONG c1 = mnu_firepal[(c & 0x1c) >> 2];
                ULONG c2 = mnu_firepal[c & 3];

                ULONG r = (c1 >> 16) + (c2 >> 16);
                if (r > 255) {
                    r = 255;
                }
                ULONG g = (((c1 >> 8) & 0xFF) * 3) / 4 + ((c2 >> 8) & 0xFF);
                if (g > 255) {
                    g = 255;
                }
                ULONG b = (c1 & 0xFF) + (c2 & 0xFF);
                if (b > 255) {
                    b = 255;
                }
                mnu_palette[c] = (ULONG)(r << 16) | (g << 8) | b;
            } else {
                mnu_palette[c] = mnu_backpal[c & 3];
            }
        }
    }
}

static int SAVEDS mnu_pass1(REG(a0, volatile struct Custom *custom), REG(a1, struct bltnode *node))
{
    CallAsm(&getrnd);
    WORD cnt = mnu_count++ & 3;

    mnu_subtract = 0;

    switch (cnt) {
    case 0:
        *(ULONG *)&custom->bltcon0 = 0x1ff80000;
        break;
    case 1:
        mnu_subtract = -2;
        *(ULONG *)&custom->bltcon0 = 0xfff80000;
        break;
    default:
        *(ULONG *)&custom->bltcon0 = 0x0ff80000;
    }
    *(ULONG *)&custom->bltafwm = 0xffffffff;
    *(ULONG *)&custom->bltamod = 0x00000000;
    *(ULONG *)&custom->bltcmod = 0x00000000;
    custom->bltapt = mnu_sourceptrs[0] - mnu_subtract;
    custom->bltbpt = mnu_rndptr;
    custom->bltcpt = mnu_morescreen + mnu_speed * ROWSIZE;
    custom->bltdpt = mnu_morescreen;
    custom->bltsize = ((mnu_size - mnu_speed) << 6) | (ROWSIZE / 2);
    node->function = (BltFuncPtr)&mnu_pass2;
    return TRUE;
}

static int SAVEDS mnu_pass2(REG(a0, volatile struct Custom *custom), REG(a1, struct bltnode *node))
{
    CallAsm(&getrnd);
    custom->bltapt = mnu_sourceptrs[1] - mnu_subtract;
    custom->bltbpt = mnu_rndptr;
    custom->bltcpt = mnu_morescreen + PLANESIZE + mnu_speed * ROWSIZE;
    custom->bltdpt = mnu_morescreen + PLANESIZE;
    custom->bltsize = ((mnu_size - mnu_speed) << 6) | (ROWSIZE / 2);
    node->function = (BltFuncPtr)&mnu_pass3;
    return TRUE;
}

static int SAVEDS mnu_pass3(REG(a0, volatile struct Custom *custom), REG(a1, struct bltnode *node))
{
    CallAsm(&getrnd);
    custom->bltapt = mnu_sourceptrs[2] - mnu_subtract;
    custom->bltbpt = mnu_rndptr;
    custom->bltcpt = mnu_morescreen + PLANESIZE * 2 + mnu_speed * ROWSIZE;
    custom->bltdpt = mnu_morescreen + PLANESIZE * 2;
    custom->bltsize = ((mnu_size - mnu_speed) << 6) | (ROWSIZE / 2);
    node->function = (BltFuncPtr)&mnu_pass4;

    return TRUE;
}

static int SAVEDS mnu_pass4(REG(a0, volatile struct Custom *custom), REG(a1, struct bltnode *node))
{
    node->function = (BltFuncPtr)&mnu_pass1;
    mnu_bltbusy = FALSE;
    return FALSE;
}

void mnu_dofire()
{
    if (main_counter & 1) {
        return;
    }
    mnu_rnd += vhposr;

    if (mnu_bltbusy) {
        return;
    }

    mnu_bltbusy = TRUE;

    APTR x = mnu_sourceptrs[0];
    mnu_sourceptrs[0] = mnu_sourceptrs[1];
    mnu_sourceptrs[1] = mnu_sourceptrs[2];
    mnu_sourceptrs[2] = x;

    static struct bltnode BltNode = {0, (BltFuncPtr)&mnu_pass1};
    QBSBlit(&BltNode);
}
