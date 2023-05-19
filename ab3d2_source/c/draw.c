#include "draw.h"
#include "screen.h"
#include "system.h"

#include <cybergraphics/cybergraphics.h>
#include <proto/cybergraphics.h>
#include <graphics/gfx.h>
#include <intuition/intuition.h>
#include <SDI_compiler.h>
#include <string.h> //memset

extern void unLHA(REG(a0, void* dst), REG(d0, const void* src), REG(d1, ULONG length), REG(a1, void* workspace),
                  REG(a2, void* X));
extern const UBYTE draw_BorderPacked_vb[];
extern ULONG Sys_Workspace_vl[];

void Draw_ResetGameDisplay()
{
    if (!vid_isRTG) {
        unLHA(Vid_Screen1Ptr_l, draw_BorderPacked_vb, 0, Sys_Workspace_vl, NULL);
        unLHA(Vid_Screen2Ptr_l, draw_BorderPacked_vb, 0, Sys_Workspace_vl, NULL);
    } else {
        LOCAL_CYBERGFX();

        memset(Vid_FastBufferPtr_l, 0, SCREEN_WIDTH * SCREEN_HEIGHT);

        ULONG bytesPerRow;
        ULONG bmHeight;
        APTR  baseAdress;

        APTR bmHandle =
            LockBitMapTags(Vid_MainScreen_l->ViewPort.RasInfo->BitMap, LBMI_BYTESPERROW, (ULONG)&bytesPerRow,
                           LBMI_BASEADDRESS, (ULONG)&baseAdress, LBMI_HEIGHT, (ULONG)&bmHeight, TAG_DONE);
        if (bmHandle) {
            memset(baseAdress, 0, bytesPerRow * bmHeight);
            UnLockBitMap(bmHandle);
        }
    }
}

void Draw_LineOfText(REG(a0, const char *ptr), REG(a1, APTR screenPointer), REG(d0,  ULONG xxxx))
{

}


void Draw_BorderAmmoBar()
{

}


void Draw_BorderEnergyBar()
{

}
