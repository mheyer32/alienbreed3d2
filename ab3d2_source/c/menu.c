#include "menu.h"

#include "screen.h"
#include "system.h"

#include <graphics/gfx.h>
#include <hardware/blit.h>
#include <hardware/custom.h>
#include <proto/dos.h>
#include <proto/exec.h>
#include <proto/graphics.h>
#include <proto/intuition.h>

#include <SDI_compiler.h>

#include <stdlib.h>  //abort

#define ALIB_HARDWARE_CUSTOM
#include <proto/alib.h>
#include <clib/debug_protos.h>

extern CHIP UBYTE mnu_morescreen[];
extern CHIP UBYTE mnu_screen[];
extern UBYTE mnu_background[];

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
static struct BitMap mnu_bitmap;

static LONG mnu_subtract;
static UWORD mnu_count;
static struct ScreenBuffer *mnu_ScreenBuffer;

struct Task *blitTask;
struct Task *mainTask;

static BOOL mnu_Active;

struct BlitMessage
{
    struct Message msg;
    ULONG command;
};

#define mnu_speed 1
#define mnu_size 256  // Menu screen height?
#define ROWSIZE (SCREEN_WIDTH / 8)
#define PLANESIZE (ROWSIZE * (SCREEN_HEIGHT))

// static APTR mnu_rndptr = mnu_morescreen + 6 * PLANESIZE;
static PLANEPTR mnu_sourceptrs[] = {mnu_morescreen + 3 * PLANESIZE + mnu_speed * ROWSIZE,
                                    mnu_morescreen + 4 * PLANESIZE + mnu_speed *ROWSIZE,
                                    mnu_morescreen + 5 * PLANESIZE + mnu_speed *ROWSIZE};

typedef int (*BltFuncPtr)();

static int SAVEDS mnu_pass2(REG(a0, volatile struct Custom *custom), REG(a1, struct bltnode *node));
static int SAVEDS mnu_pass3(REG(a0, volatile struct Custom *custom), REG(a1, struct bltnode *node));
static int SAVEDS mnu_pass4(REG(a0, volatile struct Custom *custom), REG(a1, struct bltnode *node));

static void SetBplPtrs(PLANEPTR *planePtr, PLANEPTR plane, UWORD numPlanes)
{
    for (int p = 0; p < numPlanes; ++p) {
        *planePtr++ = plane;
        plane += PLANESIZE;
    }
}

static BOOL CreateBlitTask(void);
static void DestroyBlitTask(void);

BOOL mnu_setscreen()
{
    LOCAL_GFX();
    LOCAL_INTUITION();

    if (mnu_Active) {
        // Programming error if it happens, but allow
        return TRUE;
    }

    mnu_Active = TRUE;

    mnu_init();

    InitBitMap(&mnu_bitmap, 8, SCREEN_WIDTH, SCREEN_HEIGHT);
    mnu_bitmap.Flags = BMF_STANDARD;

    const int planeSize = SCREEN_WIDTH / 8 * SCREEN_HEIGHT;

    SetBplPtrs(&mnu_bitmap.Planes[0], (PLANEPTR)mnu_screen, 1);
    SetBplPtrs(&mnu_bitmap.Planes[1], (PLANEPTR)mnu_screen + planeSize * 2, 1);
    SetBplPtrs(&mnu_bitmap.Planes[2], (PLANEPTR)mnu_morescreen, 6);

    if (!Vid_isRTG) {
        if (!(mnu_ScreenBuffer = AllocScreenBuffer(Vid_MainScreen_l, &mnu_bitmap, 0))) {
            goto fail;
        }

        while (!ChangeScreenBuffer(Vid_MainScreen_l, mnu_ScreenBuffer)) {
        };

    } else {
        if (!CreateBlitTask()) {
            goto fail;
        }
    }

    mnu_fade(0);
    main_vblint = &mnu_vblint;
    mnu_fadein();

    return TRUE;

fail:
    abort();
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
}

static inline void WaitFireBlits()
{
    while (mnu_bltbusy) {
    };
}

void mnu_clearscreen(REG(d0, BOOL fade))
{
    LOCAL_GFX();
    LOCAL_INTUITION();
    LOCAL_SYSBASE();

    if (!mnu_Active) {
        // This should only happen during shutdown (with fade=FALSE)
        return;
    }

    mnu_Active = FALSE;

    if (fade) {
        mnu_fadeout();
    }
    main_vblint = NULL;  // don't kick off new frames/blits
    WaitFireBlits();     // let current blits finish
    WaitTOF();

    if (!Vid_isRTG) {
        while (!ChangeScreenBuffer(Vid_MainScreen_l, Vid_ScreenBuffers_vl[0])) {
        };
        WaitPort(Vid_DisplayMsgPort_l);
        while (GetMsg(Vid_DisplayMsgPort_l)) {
        };
        Vid_WaitForDisplayMsg_b = FALSE;

        FreeScreenBuffer(Vid_MainScreen_l, mnu_ScreenBuffer);
        mnu_ScreenBuffer = NULL;
    } else {
        DestroyBlitTask();

    }

    Vid_LoadMainPalette();
}


void mnu_movescreen(void)
{
    static UWORD mnu_screenpos = 0;

    ULONG offset = (mnu_screenpos & 255) * ROWSIZE;
    mnu_screenpos++;

    const int planeSize = SCREEN_WIDTH / 8 * SCREEN_HEIGHT;

    if (!Vid_isRTG) {
        SetBplPtrs(&Vid_MainScreen_l->RastPort.BitMap->Planes[0], mnu_screen + offset, 1);
        SetBplPtrs(&Vid_MainScreen_l->RastPort.BitMap->Planes[1], mnu_screen + offset + planeSize * 2, 1);

        ScrollVPort(&Vid_MainScreen_l->ViewPort);
    } else {
        SetBplPtrs(&mnu_bitmap.Planes[0], mnu_screen + offset, 1);
        SetBplPtrs(&mnu_bitmap.Planes[1], mnu_screen + offset + planeSize * 2, 1);

        Signal(blitTask, SIGBREAKF_CTRL_E);
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
    LoadRGB32(&Vid_MainScreen_l->ViewPort, outPal);
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
    if (!Vid_isRTG) {
        QBSBlit(&BltNode);
    } else {
        QBlit(&BltNode);
    }
}

static void SAVEDS BlitTaskProc(void)
{
    LOCAL_SYSBASE();
    LOCAL_GFX();

    Signal(mainTask, SIGBREAKF_CTRL_E);

    while (1) {
        ULONG signal = Wait(SIGBREAKF_CTRL_C|SIGBREAKF_CTRL_E);
        if (!(signal & SIGBREAKF_CTRL_C)) {
            BltBitMapRastPort(&mnu_bitmap, 0, 0, &Vid_MainScreen_l->RastPort, 0, 0, SCREEN_WIDTH, SCREEN_HEIGHT, 0x0C0);
        } else {
            break;
        }
    }

fail:
    Signal(mainTask, SIGBREAKF_CTRL_C);
    Forbid();
}

static void DestroyBlitTask(void)
{
    LOCAL_SYSBASE();

    Delay(1);

    if (blitTask) {
        Signal(blitTask, SIGBREAKF_CTRL_C);
        Wait(SIGBREAKF_CTRL_C);
        blitTask = NULL;
    }
}

static BOOL CreateBlitTask()
{
    LOCAL_SYSBASE();

    mainTask = FindTask(NULL);

    if (!(blitTask = CreateTask("TKG Menu Blitter", -5, BlitTaskProc, 4096))) {
        goto fail;
    }
    if (SIGBREAKF_CTRL_C == Wait(SIGBREAKF_CTRL_C | SIGBREAKF_CTRL_E)) {
        goto fail;
    }

    return TRUE;

fail:
    DestroyBlitTask();
    return FALSE;
}
