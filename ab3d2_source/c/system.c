#include "system.h"
#include "screen.h"
#include "draw.h"

#include <SDI_compiler.h>
#include <SDI_misc.h>
#include <cybergraphics/cybergraphics.h>
#include <devices/timer.h>
#include <dos/dos.h>
#include <exec/exec.h>
#include <graphics/gfxbase.h>
#include <hardware/intbits.h>
#include <proto/cybergraphics.h>
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
#include <clib/alib_protos.h>
#include <proto/alib.h>

#define INTUITIONNAME "intuition.library"

extern struct TimeRequest sys_TimerRequest;
extern struct EClockVal Sys_FrameTimeECV_q[2];
extern ULONG Sys_ECVToMsFactor_l;
extern ULONG Sys_FrameTimes_vl[8];
extern ULONG Sys_FrameNumber_l;
extern UWORD Sys_FPSIntAvg_w;
extern UWORD Sys_FPSFracAvg_w;

extern UBYTE Sys_Move16_b;
extern UBYTE Vid_FullScreenTemp_b;
extern UBYTE Sys_CPU_68060_b;

extern struct EClockVal _Sys_FrameTimeECV_q[2];

extern UWORD angpos;
extern WORD Sys_MouseY;

extern UBYTE KeyMap_vb[256];

static BOOL gotSerialPort;
static BOOL gotSerialBits;
static UWORD allocPotBits;

struct Library *CYBERGFX_BASE_NAME = NULL;

extern VOID VBlankInterrupt(void);
extern VOID key_interrupt(void);

static const char AppName[] = "TheKillingGrounds";
static struct Interrupt VBLANKInt = {{NULL, NULL, NT_INTERRUPT, 9, (char *)AppName}, 0, VBlankInterrupt};
static struct Interrupt KBInt = {NULL, NULL, NT_INTERRUPT, 127, (char *)AppName, 0, key_interrupt};

static struct MsgPort vblPort;
static struct VBLData
{
    volatile ULONG tsi_Flag;
    struct MsgPort *tsi_Port;
} vblData = {0, &vblPort};

static BOOL SAVEDS FakeVBlankInterrupt(REG(a1, struct VBLData *data));

static struct Interrupt PseudoVBLANKInt = {
    NULL, NULL, NT_INTERRUPT, 0, (char *)AppName, &vblData, &FakeVBlankInterrupt};

static BOOL sys_InitHardware();
static void sys_ReleaseHardware();
static void sys_InstallInterrupts();
static void sys_RemoveInterrupts();

BOOL Sys_Init()
{
    if (!sys_InitHardware()) {
        goto fail;
    }

    ULONG freq = Sys_MarkTime(&Sys_FrameTimeECV_q[1]);
    Sys_ECVToMsFactor_l = (1000 << 16) / freq;

    sys_InstallInterrupts();

    if (!Draw_Init()) {
        goto fail;
    }

    return TRUE;

fail:
    sys_ReleaseHardware();
    return FALSE;
}

void Sys_Done()
{
    Draw_Shutdown();
    sys_RemoveInterrupts();
    sys_ReleaseHardware();
}

BOOL Sys_OpenLibs(void)
{
    LOCAL_SYSBASE();

    if (!(DOSBase = (struct DosLibrary *)OpenLibrary(DOSNAME, 0))) {
        goto fail;
    }
    if (!(GfxBase = (struct GfxBase *)OpenLibrary(GRAPHICSNAME, 36))) {
        goto fail;
    }
    if (!(IntuitionBase = (struct IntuitionBase *)OpenLibrary(INTUITIONNAME, 36))) {
        goto fail;
    }
    if (!(MiscBase = OpenResource(MISCNAME))) {
        goto fail;
    }
    if (!(PotgoBase = OpenResource(POTGONAME))) {
        goto fail;
    }

    {
        /* Set up the (software)interrupt structure. Note that this task runs at  */
        /* priority 0. Software interrupts may only be priority -32, -16, 0, +16, */
        /* +32. Also not that the correct node type for a software interrupt is   */
        /* NT_INTERRUPT. (NT_SOFTINT is an internal Exec flag). This is the same  */
        /* setup as that for a software interrupt which you Cause(). If our       */
        /* interrupt code was in assembler, you could initialize is_Data here to  */
        /* contain a pointer to shared data structures. An assembler software     */
        /* interrupt routine would receive the is_Data in A1.                     */

        vblPort.mp_Node.ln_Type = NT_MSGPORT;  /* Set up the PA_SOFTINT message port  */
        vblPort.mp_Flags = PA_SOFTINT;         /* (no need to make this port public). */
        vblPort.mp_SigTask = &PseudoVBLANKInt; /* pointer to interrupt structure */
        NewList(&(vblPort.mp_MsgList));        /* Initialize message list */

        struct Message *rplyMsg = &sys_TimerRequest.tr_node.io_Message;
        rplyMsg->mn_Node.ln_Type = NT_REPLYMSG;
        rplyMsg->mn_ReplyPort = &vblPort;
        rplyMsg->mn_Length = sizeof(struct TimeRequest);

        if (OpenDevice(TIMERNAME, UNIT_MICROHZ, &sys_TimerRequest.tr_node, 0) != 0) {
            goto fail;
        }
        TimerBase = sys_TimerRequest.tr_node.io_Device;
    }

    // optional
    CyberGfxBase = OpenLibrary(CYBERGFXNAME, CYBERGFX_INCLUDE_VERSION);

    return TRUE;

fail:
    Sys_CloseLibs();
    return FALSE;
}

#define CLOSELIB(lib)                       \
    if (lib) {                              \
        CloseLibrary((struct Library*)lib); \
        lib = NULL;                         \
    }

void Sys_CloseLibs(void)
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
    CLOSELIB(CyberGfxBase);
}

BOOL sys_InitHardware()
{
    LOCAL_SYSBASE();

    Vid_FullScreenTemp_b =
    Sys_Move16_b    = (SysBase->AttnFlags & (AFF_68040|AFF_68060)) ? 0xFF : 0;
    Sys_CPU_68060_b = (SysBase->AttnFlags & AFF_68060) ? 0xFF : 0;


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

#define OFF 0
#define ON 1
#define STOPPED 2

static void RemoveFakeVBlankInterrupt(void);

static BOOL InstallFakeVBlankInterrupt(void)
{
    vblData.tsi_Flag = ON; /* Init data structure to share globally. */
    vblData.tsi_Port = &vblPort;

    /* Send of the first timerequest to start. IMPORTANT: Do NOT   */
    /* BeginIO() to any device other than audio or timer from      */
    /* within a software or hardware interrupt. The BeginIO() code */
    /* may allocate memory, wait or perform other functions which  */
    /* are illegal or dangerous during interrupts.                 */
    sys_TimerRequest.tr_node.io_Command = TR_ADDREQUEST; /* Initial iorequest to start */
    sys_TimerRequest.tr_time.tv_micro = 20000;           /* 50Hz software interrupt.        */
    BeginIO(&sys_TimerRequest.tr_node);

    return TRUE;
fail:
    RemoveFakeVBlankInterrupt();

    return FALSE;
}

static void RemoveFakeVBlankInterrupt(void)
{
    LOCAL_SYSBASE();

    if (vblData.tsi_Flag == ON) {
        // Wait for interrupt to cease creating new IO requests
        vblData.tsi_Flag = OFF;
        while (vblData.tsi_Flag != STOPPED) {
            Delay(1);
        };
        vblData.tsi_Flag = OFF;
    }
}

static BOOL SAVEDS FakeVBlankInterrupt(REG(a1, struct VBLData *data))
{
    LOCAL_SYSBASE();

    struct timerequest *tr;

    /* Remove the message from the port. */
    tr = (struct timerequest *)GetMsg(data->tsi_Port);

    /* Keep on going if flag hasn't been set to OFF. */
    if ((tr) && (data->tsi_Flag == ON)) {
        /* Re-send timerequest--IMPORTANT: This         */
        /* self-perpetuating technique of calling BeginIO() during a software */
        /* interrupt may only be used with the audio and timer device.        */
        tr->tr_node.io_Command = TR_ADDREQUEST;
        tr->tr_time.tv_micro = 20000;
        BeginIO((struct IORequest *)tr);

        CallAsm(&VBlankInterrupt);
    } else {
        data->tsi_Flag = STOPPED;
    }

    return TRUE;
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
    if (!Vid_isRTG) {
        AddIntServer(INTB_VERTB, &VBLANKInt);
    } else {
        InstallFakeVBlankInterrupt();
    }
    AddIntServer(INTB_PORTS, &KBInt);
}

void sys_RemoveInterrupts()
{
    LOCAL_SYSBASE();
    if (!Vid_isRTG) {
        RemIntServer(INTB_VERTB, &VBLANKInt);
    } else {
        RemoveFakeVBlankInterrupt();
    }
    RemIntServer(INTB_PORTS, &KBInt);
}

ULONG Sys_MarkTime(REG(a0, struct EClockVal* dest))
{
    return ReadEClock(dest);
}

uint64_t Sys_TimeDiff(REG(a0, struct EClockVal* start), REG(a1, struct EClockVal* end))
{
    uint64_t diff = *(uint64_t*)end - *(uint64_t*)start;
    return diff;
}

void Sys_FrameLap()
{
    ReadEClock(&Sys_FrameTimeECV_q[0]);
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

    Sys_FPSFracAvg_w = ((UWORD)1000 % (UWORD)avg)/10;
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
    static WORD oldMouseY;
    WORD diffY = joy0dat >> 8;
    diffY -= oldMouseY;
    if (diffY >= 127)
        diffY -= 255;
    else if (diffY < -127)
        diffY += 255;
    // Emulate weird add.b stuff in original code
    oldMouseY = (oldMouseY & 0xff00) | ((diffY+oldMouseY) & 0xff);
    Sys_MouseY += diffY;

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
