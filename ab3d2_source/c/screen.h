#ifndef SCREEN_C
#define SCREEN_C

#include <graphics/gfx.h>

const int SCREEN_WIDTH = 320;
const int SCREEN_HEIGHT = 256;

extern struct MsgPort *Vid_DisplayMsgPort_l;
extern struct ScreenBuffer *Vid_ScreenBuffers_vl[2];
extern struct Screen *Vid_MainScreen_l;
extern struct Window *Vid_MainWindow_l;
extern BYTE Vid_DoubleHeight_b;
extern PLANEPTR Vid_Screen1Ptr_l;
extern PLANEPTR Vid_Screen2Ptr_l;

extern void LoadMainPalette(void);
extern BOOL Vid_OpenMainScreen(void);
extern void vid_SetupDoubleheightCopperlist(void);


static inline struct ExecBase *getSysBase(void)
{
    extern struct ExecBase * SysBase;
    return SysBase;
}
#define LOCAL_SYSBASE() struct ExecBase *const SysBase = getSysBase()

static inline struct IntuitionBase *getIntuitionBase(void)
{
    extern struct IntuitionBase * IntuitionBase;
    return IntuitionBase;
}
#define LOCAL_INTUITION() struct IntuitionBase *const IntuitionBase = getIntuitionBase()

static inline struct GfxBase *getGfxBase(void)
{
    extern struct GfxBase * GfxBase;
    return GfxBase;
}
#define LOCAL_GFX() struct GfxBase *const GfxBase = getGfxBase()

static inline void CallAsm(void *func)
{
    __asm __volatile("\t movem.l d2-d7/a2-a6,-(a7)\n"
                     "\tjsr (%0)\n"
                     "\t movem.l (a7)+,d2-d7/a2-a6\n"
                     : /* no result */
                     : "a"(func)
                     : "d0", "d1", "a0", "a1", "memory");
}

#endif  // SCREEN_C
