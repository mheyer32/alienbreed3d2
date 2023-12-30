#include "system.h"
#include "screen.h"

#include <graphics/modeid.h>
#include <proto/cybergraphics.h>
#include <proto/dos.h>

extern void startup(void);

const long __nocommandline=1;

int main(int argc, char *argv[])
{
    int rval = 10;
    if (!Sys_OpenLibs())
    {
        goto fail;
    }

    Vid_ScreenMode = INVALID_ID;

    enum {
        OPT_SCREENMODE,
        OPT_COUNT
    };
    LONG options[OPT_COUNT] = { 0 };
    struct RDArgs* args;
    if ((args = ReadArgs("SCREENMODE/N", options, NULL)) != NULL)
    {
        if (options[OPT_SCREENMODE])
        {
            Vid_ScreenMode = *(int *)options[OPT_SCREENMODE];
        }
        FreeArgs(args);
    }

    if (Vid_ScreenMode == INVALID_ID)
    {
        Vid_ScreenMode = GetScreenMode();
    }

    if (Vid_ScreenMode == INVALID_ID)
    {
        PutStr("Invalid Screenmode\n");
        goto fail;
    }
    if (CyberGfxBase)
    {
        Vid_isRTG = IsCyberModeID(Vid_ScreenMode);
    }

    rval = 0;

    startup();

fail:
    Sys_CloseLibs();
    return rval;
}
