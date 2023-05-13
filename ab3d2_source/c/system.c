#include "system.h"

#include <proto/exec.h>
#include <proto/dos.h>
#include <proto/graphics.h>
#include <proto/intuition.h>
#include <proto/timer.h>
#include <proto/potgo.h>
#include <proto/lowlevel.h>
#include <proto/misc.h>
#include <resources/misc.h>
#include <resources/potgo.h>
#include <graphics/gfxbase.h>
#include <devices/timer.h>
#include <exec/exec.h>
#include <hardware/intbits.h>

#include <dos/dos.h>

#define INTUITIONNAME "intuition.library"

extern struct TimeRequest sys_TimerRequest;

extern BOOL Sys_Move16_b;
extern BOOL Vid_FullScreenTemp_b;
extern const char AppName[];

static BOOL gotSerialPort;
static BOOL gotSerialBits;
static UWORD allocPotBits;

extern VOID VBlankInterrupt(void);
extern VOID key_interrupt(void);

static struct Interrupt VBLANKInt = {{NULL, NULL, NT_INTERRUPT, 9, AppName}, 0, VBlankInterrupt};
static struct Interrupt KBInt = {NULL, NULL, NT_INTERRUPT, 127, AppName, 0, key_interrupt};

static BOOL sys_OpenLibs(void);
static void sys_CloseLibs(void);
static BOOL sys_InitHardware();
static void sys_ReleaseHardware();
static void sys_InstallInterrupts();
static void sys_RemoveInterrupts();

BOOL Sys_Init()
{
    if (!sys_OpenLibs()){
        goto fail;
    }
    if (!sys_InitHardware())
    {
        goto fail;
    }
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
    if (!(DOSBase = (struct DosLibrary*)OpenLibrary(DOSNAME, 0)))
    {
        goto fail;
    }
    if (!(GfxBase = (struct GfxBase*)OpenLibrary(GRAPHICSNAME, 36)))
    {
        goto fail;
    }
    if (!(IntuitionBase = (struct IntuitionBase*)OpenLibrary(INTUITIONNAME, 36)))
    {
        goto fail;
    }
    if (!(MiscBase = OpenResource(MISCNAME)))
    {
        goto fail;
    }
    if (!(PotgoBase = OpenResource(POTGONAME)))
    {
        goto fail;
    }
    if (OpenDevice(TIMERNAME, 0, &sys_TimerRequest.tr_node, 0) != 0)
    {
        goto fail;
    }
    TimerBase = &sys_TimerRequest.tr_node;

    return TRUE;

fail:
    sys_CloseLibs();
    return FALSE;
}

#define CLOSELIB(lib) if (lib) { CloseLibrary(lib); lib = NULL; }

void sys_CloseLibs(void)
{
    if (TimerBase){
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
    if (SysBase->AttnFlags & AFF_68040)
    {
        Sys_Move16_b = ~Sys_Move16_b;
        Vid_FullScreenTemp_b = ~Vid_FullScreenTemp_b;
    }

    if (AllocMiscResource(MR_SERIALPORT, AppName))
    {
        goto fail;
    }
    gotSerialPort = TRUE;
    if (AllocMiscResource(MR_SERIALBITS, AppName))
    {
        goto fail;
    }
    gotSerialBits = TRUE;

    //FIXME: is this really necessary? Are we doing anything with the Potgo register?
    // Is this for the joystick/mouse firebuttons?
    allocPotBits = AllocPotBits(0b110000000000);

    return TRUE;

fail:
    sys_ReleaseHardware();
    return FALSE;
}


void sys_ReleaseHardware()
{
    if (gotSerialBits)
    {
        FreeMiscResource(MR_SERIALBITS);
        gotSerialBits = FALSE;
    }
    if (gotSerialPort)
    {
        FreeMiscResource(MR_SERIALPORT);
        gotSerialPort = FALSE;
    }

    FreePotBits(allocPotBits);
}

void sys_InstallInterrupts()
{
//    AddVBlankInt(VBlankInterrupt, 0); // lowlevel.library
    AddIntServer(INTB_VERTB, &VBLANKInt);
    AddIntServer(INTB_PORTS, &KBInt);
}

void sys_RemoveInterrupts()
{
    RemIntServer(INTB_VERTB, &VBLANKInt);
    RemIntServer(INTB_PORTS, &KBInt);
}
