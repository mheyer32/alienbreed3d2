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
// Warning: Sys_FatalError can only be called startup()
extern void Sys_FatalError(REG(a0, const char* format), ...);

extern void Sys_MemFillLong(REG(a0, void* buffer), REG(d0, ULONG value), REG(d1, WORD size));

static inline void* Sys_GetTemporaryWorkspace()
{
    extern ULONG Sys_Workspace_vl[];
    return Sys_Workspace_vl;
}

/**
 * Check to see if a given time is greater than or equal to another
 */
static inline BOOL Sys_CheckTimeGE(const struct EClockVal* now, const struct EClockVal* mark)
{
    return now->ev_hi > mark->ev_hi || (
        now->ev_hi == mark->ev_hi && now->ev_lo >= mark->ev_lo
    );
}

static inline void Sys_AddTime(struct EClockVal* mark, ULONG ticks)
{
    *((uint64_t*)mark) += (uint64_t) ticks;
}

#ifdef FIXED_C_MOUSE
extern void Sys_ReadMouse();
#endif

extern void Sys_ClearKeyboard();
extern BOOL Sys_OpenLibs(void);
extern void Sys_CloseLibs(void);

extern ULONG Sys_EClockRate;

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
