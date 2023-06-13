#ifndef SYSTEM_H
#define SYSTEM_H

#include <exec/types.h>
#include <devices/timer.h>
#include <SDI_compiler.h>

#include <stdint.h>

extern BOOL Sys_Init(void);
extern void Sys_Done(void);
extern ULONG Sys_MarkTime(REG(a0, struct EClockVal *dest));
extern uint64_t Sys_TimeDiff(REG(a0, struct EClockVal* end), REG(a1, struct EClockVal* start));
extern void Sys_ShowFPS();
extern void Sys_EvalFPS();
extern void Sys_FrameLap();

#ifdef FIXED_C_MOUSE
extern void Sys_ReadMouse();
#endif

extern void Sys_ClearKeyboard();
extern BOOL Sys_OpenLibs(void);
extern void Sys_CloseLibs(void);

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

static inline struct Library *getCyberGfxBase(void)
{
    extern struct Library * CyberGfxBase;
    return CyberGfxBase;
}
#define LOCAL_CYBERGFX() struct Library *const CyberGfxBase = getCyberGfxBase()

static inline void CallAsm(void *func)
{
    __asm __volatile("\t movem.l d2-d7/a2-a6,-(a7)\n"
        "\t jsr (%0)\n"
        "\t movem.l (a7)+,d2-d7/a2-a6\n"
        : /* no result */
        : "a"(func)
        : "d0", "d1", "a0", "a1", "memory");
}

#endif // SYSTEM_H
