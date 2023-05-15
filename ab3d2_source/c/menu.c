#include "menu.h"

#include "screen.h"
#include "system.h"

#include <proto/graphics.h>
#include <proto/intuition.h>
#include <graphics/gfx.h>

#include <SDI_compiler.h>

#include <stdlib.h> //abort

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

static CHIP WORD emptySprite[6];

BOOL mnu_setscreen()
{
    LOCAL_GFX();
    LOCAL_INTUITION();

    static struct BitMap bm;
    InitBitMap(&bm, 8, SCREEN_WIDTH, SCREEN_HEIGHT);
    for (int p =0 ; p < 8; ++p)
    {
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

    CallAsm(mnu_init);
    mnu_fadefactor = 0;
    CallAsm(mnu_fade);
    main_vblint = &mnu_vblint;
    CallAsm(mnu_fadein);

    return TRUE;

fail:
    abort();
}
