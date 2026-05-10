#ifndef SCREEN_C
#define SCREEN_C

#include <graphics/gfx.h>

#define SCREEN_WIDTH (UWORD)320
#define SCREEN_HEIGHT (UWORD)256
#define SCREEN_DEPTH 8
#define SCREEN_DEPTH_EXP 3

#define HUD_BORDER_WIDTH 16

/**
 * Define GFX_LONG_ALIGNED if you expect to perform 32-bit access vram/chip only
 */
#define GFX_LONG_ALIGNED

#ifndef FS_HEIGHT_HACK
#define FS_HEIGHT (SCREEN_HEIGHT - (UWORD)16)
#define FS_HEIGHT_C2P_DIFF (UWORD)8
#else
#define FS_HEIGHT (SCREEN_HEIGHT - (UWORD)24)
#define FS_HEIGHT_C2P_DIFF (UWORD)0
#endif

#define FS_WIDTH SCREEN_WIDTH
#define SMALL_WIDTH (UWORD)192
#define SMALL_HEIGHT (UWORD)160
#define C2P_FS_HEIGHT (FS_HEIGHT - FS_HEIGHT_C2P_DIFF)

/**
 * Rows between C2P output height and FS_HEIGHT — legacy in-frame message band (engine draws here on chunky RAM;
 * RTG fullscreen can copy them). Matches hires.s FS_HEIGHT − (FS_HEIGHT − FS_HEIGHT_C2P_DIFF).
 */
#define VID_FS_LEGACY_MESSAGE_STRIP_LINES ((WORD)((FS_HEIGHT) - (C2P_FS_HEIGHT)))

/** Rows of chunky border artwork below the FS_HEIGHT baseline (indices FS_HEIGHT..SCREEN_HEIGHT−1). */
#define VID_BORDER_CHROME_LINES_BELOW_FS ((WORD)((SCREEN_HEIGHT) - (FS_HEIGHT)))

/** 2/3 screensize offsets */
//#define SMALL_YPOS 20
#define SMALL_XPOS 64
#define SMALL_YPOS_DEFAULT 20

extern WORD SMALL_YPOS;

extern struct MsgPort *Vid_DisplayMsgPort_l;
extern UBYTE Vid_WaitForDisplayMsg_b;
extern struct ScreenBuffer *Vid_ScreenBuffers_vl[2];
extern struct Screen *Vid_MainScreen_l;
extern struct Window *Vid_MainWindow_l;
extern BYTE Vid_DoubleHeight_b;
extern BYTE Vid_DoubleWidth_b;
extern PLANEPTR Vid_Screen1Ptr_l;
extern PLANEPTR Vid_Screen2Ptr_l;
extern ULONG Vid_ScreenMode;
extern BOOL Vid_isRTG;

extern WORD Vid_ScreenHeight;
extern WORD Vid_ScreenWidth;
extern WORD Vid_VisibleHeight_w;
extern WORD Vid_FullscreenRenderHeight_w;
extern WORD Vid_SmallRenderTopOffset_w;

/**
 * Vertical shift n for HUD and border — legacy message strip reclaimed into the 3D area.
 * Border blit samples a virtual border shifted down by n; HUD uses +n on bottom-relative Y.
 */
extern WORD Vid_BorderReclaimShift_w;

/**
 * The game renders into a 320×SCREEN_HEIGHT logical framebuffer at the top-left of the RTG bitmap.
 * Tall RTG modes report Vid_ScreenHeight greater than SCREEN_HEIGHT; HUD placement must use this clamp.
 */
static __inline WORD Vid_LogicalHeight(void)
{
    WORD h = Vid_VisibleHeight_w ? Vid_VisibleHeight_w : Vid_ScreenHeight;
    return h > (WORD)SCREEN_HEIGHT ? (WORD)SCREEN_HEIGHT : h;
}

static __inline WORD Vid_VisibleBottom(void)
{
    return Vid_LogicalHeight();
}

static __inline WORD Vid_LogicalWidth(void)
{
    WORD w = Vid_ScreenWidth;
    return w > (WORD)SCREEN_WIDTH ? (WORD)SCREEN_WIDTH : w;
}

extern UBYTE Vid_FullScreen_b;

extern void Vid_LoadMainPalette(void);
extern void Vid_OpenMainScreen(void);
extern void vid_SetupDoubleheightCopperlist(void);
extern void Vid_CloseMainScreen(void);
extern void Vid_LoadMainPalette(void);
extern ULONG GetScreenMode();

#endif  // SCREEN_C

