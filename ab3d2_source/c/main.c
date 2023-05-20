#include "system.h"
#include "screen.h"

#include <graphics/modeid.h>
#include <proto/cybergraphics.h>

#include <stdio.h>

extern void startup(void);

const long __nocommandline=1;

int main(int argc, char *argv[])
{
    int rval = 10;
    if (!sys_OpenLibs())
    {
        goto fail;
    }
    Vid_ScreenMode = GetScreenMode();
    if (Vid_ScreenMode == INVALID_ID)
    {
        printf("Invalid Screenmode");
        goto fail;
    }
    if (CyberGfxBase)
    {
        Vid_isRTG = IsCyberModeID(Vid_ScreenMode);
    }

    rval = 0;

    startup();

fail:
    sys_CloseLibs();
    return rval;
}
