#include "system.h"
#include "screen.h"

#include <SDI_misc.h>
#include <devices/timer.h>
#include <dos/dos.h>
#include <exec/exec.h>
#include <graphics/gfxbase.h>
#include <hardware/intbits.h>
#include <proto/dos.h>
#include <proto/exec.h>
#include <proto/graphics.h>
#include <proto/intuition.h>
#include <proto/lowlevel.h>
#include <proto/misc.h>
#include <proto/potgo.h>
#include <proto/timer.h>
#include <resources/misc.h>
#include <resources/potgo.h>

#define ALIB_HARDWARE_CUSTOM
#include <proto/alib.h>

#define INTUITIONNAME "intuition.library"

extern struct TimeRequest sys_TimerRequest;
extern struct EClockVal Sys_FrameTimeECV_q[2];
extern  ULONG Sys_ECVToMsFactor_l;
extern ULONG Sys_FrameTimes_vl[8];
extern ULONG Sys_FrameNumber_l;
extern UWORD Sys_FPSIntAvg_w;
extern UWORD Sys_FPSFracAvg_w;

extern UBYTE Sys_Move16_b;
extern UBYTE Vid_FullScreenTemp_b;
extern struct EClockVal _Sys_FrameTimeECV_q[2];

extern UWORD angpos;
extern WORD Sys_MouseY;

extern UBYTE KeyMap_vb[256];

static BOOL gotSerialPort;
static BOOL gotSerialBits;
static UWORD allocPotBits;

extern VOID VBlankInterrupt(void);
extern VOID key_interrupt(void);

static const char AppName[] = "TheKillingGrounds";
static struct Interrupt VBLANKInt = {{NULL, NULL, NT_INTERRUPT, 9, (char*)AppName}, 0, VBlankInterrupt};
static struct Interrupt KBInt = {NULL, NULL, NT_INTERRUPT, 127, (char*)AppName, 0, key_interrupt};


static BOOL sys_OpenLibs(void);
static void sys_CloseLibs(void);
static BOOL sys_InitHardware();
static void sys_ReleaseHardware();
static void sys_InstallInterrupts();
static void sys_RemoveInterrupts();

BOOL Sys_Init()
{
    if (!sys_OpenLibs()) {
        goto fail;
    }
    if (!sys_InitHardware()) {
        goto fail;
    }

    ULONG freq = Sys_MarkTime(&Sys_FrameTimeECV_q[1]);
    Sys_ECVToMsFactor_l = (1000 << 16) / freq;

    sys_InstallInterrupts();

    return TRUE;

fail:
    sys_ReleaseHardware();
    sys_CloseLibs();
    return FALSE;
}

void Sys_Done()
{
    sys_RemoveInterrupts();
    sys_ReleaseHardware();
    sys_CloseLibs();
}

BOOL sys_OpenLibs(void)
{
    LOCAL_SYSBASE();

    if (!(DOSBase = (struct DosLibrary*)OpenLibrary(DOSNAME, 0))) {
        goto fail;
    }
    if (!(GfxBase = (struct GfxBase*)OpenLibrary(GRAPHICSNAME, 36))) {
        goto fail;
    }
    if (!(IntuitionBase = (struct IntuitionBase*)OpenLibrary(INTUITIONNAME, 36))) {
        goto fail;
    }
    if (!(MiscBase = OpenResource(MISCNAME))) {
        goto fail;
    }
    if (!(PotgoBase = OpenResource(POTGONAME))) {
        goto fail;
    }
    if (OpenDevice(TIMERNAME, 0, &sys_TimerRequest.tr_node, 0) != 0) {
        goto fail;
    }
    TimerBase = sys_TimerRequest.tr_node.io_Device;

    return TRUE;

fail:
    sys_CloseLibs();
    return FALSE;
}

#define CLOSELIB(lib)                       \
    if (lib) {                              \
        CloseLibrary((struct Library*)lib); \
        lib = NULL;                         \
    }

void sys_CloseLibs(void)
{
    LOCAL_SYSBASE();

    if (TimerBase) {
        CloseDevice(&sys_TimerRequest.tr_node);
        TimerBase = NULL;
    }
    // Resources can't be closed or released
    PotgoBase = NULL;
    MiscBase = NULL;

    CLOSELIB(IntuitionBase);
    CLOSELIB(GfxBase);
    CLOSELIB(DOSBase);
}

BOOL sys_InitHardware()
{
    LOCAL_SYSBASE();
    if (SysBase->AttnFlags & AFF_68040) {
        Sys_Move16_b = ~Sys_Move16_b;
        Vid_FullScreenTemp_b = ~Vid_FullScreenTemp_b;
    }

    if (AllocMiscResource(MR_SERIALPORT, AppName)) {
        goto fail;
    }
    gotSerialPort = TRUE;
    if (AllocMiscResource(MR_SERIALBITS, AppName)) {
        goto fail;
    }
    gotSerialBits = TRUE;

    // FIXME: is this really necessary? Are we doing anything with the Potgo register?
    // Is this for the joystick/mouse firebuttons?
    allocPotBits = AllocPotBits(0b110000000000);

    serper = 31;  // 19200 baud, 8 bits, no parity

    return TRUE;

fail:
    sys_ReleaseHardware();
    return FALSE;
}

void sys_ReleaseHardware()
{
    if (gotSerialBits) {
        FreeMiscResource(MR_SERIALBITS);
        gotSerialBits = FALSE;
    }
    if (gotSerialPort) {
        FreeMiscResource(MR_SERIALPORT);
        gotSerialPort = FALSE;
    }

    FreePotBits(allocPotBits);
}

void sys_InstallInterrupts()
{
    LOCAL_SYSBASE();
    //    AddVBlankInt(VBlankInterrupt, 0); // lowlevel.library
    AddIntServer(INTB_VERTB, &VBLANKInt);
    AddIntServer(INTB_PORTS, &KBInt);
}

void sys_RemoveInterrupts()
{
    LOCAL_SYSBASE();
    RemIntServer(INTB_VERTB, &VBLANKInt);
    RemIntServer(INTB_PORTS, &KBInt);
}

ULONG Sys_MarkTime(REG(a0, struct EClockVal* dest))
{
    return ReadEClock(dest);
}

uint64_t Sys_TimeDiff(REG(a0, struct EClockVal* end), REG(a1, struct EClockVal* start))
{
    uint64_t diff = *(uint64_t*)end - *(uint64_t*)start;
    return diff;
}

void Sys_FrameLap()
{
    (void)Sys_MarkTime(&Sys_FrameTimeECV_q[0]);
    ULONG frameTime = Sys_FrameTimeECV_q[0].ev_lo - Sys_FrameTimeECV_q[1].ev_lo;
    Sys_FrameTimeECV_q[1] = Sys_FrameTimeECV_q[0];
    Sys_FrameTimes_vl[Sys_FrameNumber_l & 7] = frameTime;
    ++Sys_FrameNumber_l;
}

void Sys_EvalFPS()
{
    ULONG avg = 0;
    for (int x = 0; x < 8; ++x) {
        avg += Sys_FrameTimes_vl[x];
    }
    avg = (avg * Sys_ECVToMsFactor_l) >> 19;
    if (!avg) {
        return;
    }
    Sys_FPSFracAvg_w = (UWORD)1000 % (UWORD)avg;
    Sys_FPSIntAvg_w = (UWORD)1000 / (UWORD)avg;
}

static void SAVEDS PutChProc(REG(d0, char c), REG(a3, char** out))
{
    **out = c;
    ++(*out);
}

void Sys_ShowFPS()
{
    char text[16];
    char* outPtr = text;

    RawDoFmt("%2d.%d", &Sys_FPSIntAvg_w, (void (*)()) & PutChProc, &outPtr);
    LOCAL_GFX();
    Move(&Vid_MainScreen_l->RastPort, 0, 8);
    Text(&Vid_MainScreen_l->RastPort, text, outPtr - text - 1);
}

void Sys_ReadMouse()
{
    static UBYTE oldCounterY = 0;
    static UWORD oldMouseY2 = 0;

    UWORD counterY = joy0dat >> 8;
    WORD diffY = counterY - oldCounterY;
    if (diffY >= 127) {
        diffY -= 255;
    }else if (diffY < -127) {
        diffY += 255;
    }

    WORD newMouseY = diffY + oldCounterY;
    oldCounterY = newMouseY;

    Sys_MouseY = newMouseY ; // oldCounterY;

    static UBYTE oldCounterX = 0;
    static UWORD oldMouseX2 = 0;

    UWORD counterX = joy0dat & 0xff;
    WORD diffX = counterX - oldCounterX;
    if (diffX >= 127) {
        diffX -= 255;
    } else if (diffX < -127) {
        diffX += 255;
    }

    WORD newMouseX = diffX + oldCounterX;
    oldCounterX = newMouseX;

    oldMouseX2 = (oldMouseX2 + diffX) & 2047;

    // This directly steers player rotation
    //  the rotation sensitivity can be adjusted here
    angpos += (diffX << 2);

    // FIXME: should use WritePotgo here... what does this even reset?
    // potgo = 0;
}


void Sys_ClearKeyboard()
{
    for(int c = 0; c < 256; ++c)
    {
        KeyMap_vb[c] = 0;
    }
}
