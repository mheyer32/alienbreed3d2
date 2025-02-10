#include "screen.h"

#include "draw.h"
#include "system.h"
#include "message.h"

#include <exec/ports.h>
#include <graphics/copper.h>
#include <graphics/gfx.h>
#include <graphics/gfxmacros.h>
#include <graphics/videocontrol.h>
#include <graphics/view.h>

#include <cybergraphics/cybergraphics.h>
#include <exec/types.h>
#include <intuition/screens.h>
#include <libraries/asl.h>
#include <proto/asl.h>
#include <proto/cybergraphics.h>
#include <proto/exec.h>
#include <proto/graphics.h>
#include <proto/intuition.h>
#include <string.h> // memset

#ifdef USE_DEBUG_LIB
#include <clib/debug_protos.h>
#endif

#define ALIB_HARDWARE_CUSTOM
#include <proto/alib.h>

#include <SDI_compiler.h>

#define SCREEN_TITLEBAR_HACK

#ifdef SCREEN_TITLEBAR_HACK
    #define SHOW_TITLE_STATE 0
#else
    #define SHOW_TITLE_STATE 1
#endif

#define TEXT_PLANE_SIZE (MSG_MAX_LINES_SMALL + 1) * (DRAW_MSG_CHAR_H + DRAW_TEXT_Y_SPACING) * (SCREEN_WIDTH / 8)

extern UWORD draw_Palette_vw[3 * 256];
extern ULONG Vid_LoadRGB32Struct_vl[3 * 256 + 2];

static PLANEPTR rasters[2];
struct BitMap bitmaps[2];

static CHIP WORD emptySprite[6];

/** Copper lists for double height modes */
static struct UCopList* doubleHeightCopList;

extern UBYTE Vid_FullScreen_b;
extern UWORD Vid_LetterBoxMarginHeight_w;

extern void Draw_UpdateBorder_RTG(APTR bmBaseAdress, ULONG bmBytesPerRow);
extern void Draw_UpdateBorder_Planar(void);

WORD Vid_ScreenHeight;
WORD Vid_ScreenWidth;

ULONG Vid_ScreenMode;
BOOL Vid_isRTG;

extern void C2P_Init(void);

void Vid_Present();
void C2P_Convert();
void Vid_CloseMainScreen();

void Vid_OpenMainScreen(void)
{
    LOCAL_SYSBASE();
    LOCAL_INTUITION();
    LOCAL_GFX();

    if (!Vid_isRTG) {
        CallAsm(&C2P_Init);
        for (int i = 0; i < 2; ++i) {
            if (!(rasters[i] = AllocRaster(SCREEN_WIDTH, SCREEN_HEIGHT * 8 + 1))) {
                Sys_FatalError("AllocRaster failed");
            }
            InitBitMap(&bitmaps[i], 8, SCREEN_WIDTH, SCREEN_HEIGHT);

            PLANEPTR ptr = (PLANEPTR)(((ULONG)rasters[i] + 7) & ~7);
            for (int p = 0; p < 8; ++p) {
                bitmaps[i].Planes[p] = ptr;
                ptr += SCREEN_WIDTH * SCREEN_HEIGHT / 8;
            }
        }

        Vid_Screen1Ptr_l = bitmaps[0].Planes[0];
        Vid_Screen2Ptr_l = bitmaps[1].Planes[0];

        if (!(Vid_MainScreen_l = OpenScreenTags(
            NULL,
            /* Tags */
            SA_Width, SCREEN_WIDTH,
            SA_Height, SCREEN_HEIGHT,
            SA_Depth, 8,
            SA_BitMap, (Tag)&bitmaps[0],
            SA_Type, CUSTOMSCREEN,
            SA_Quiet, 1,
            SA_ShowTitle, SHOW_TITLE_STATE,
            SA_AutoScroll, 0,
            SA_FullPalette, 1,
            SA_DisplayID,
            Vid_ScreenMode,
            TAG_END, 0))
        ) {
            Sys_FatalError("Failed to open screen for mode %ld", Vid_ScreenMode);
        }

        Vid_ScreenWidth = SCREEN_WIDTH;
        Vid_ScreenHeight = SCREEN_HEIGHT;

        Vid_DisplayMsgPort_l = CreateMsgPort();

        for (int s = 0; s < 2; ++s) {
            Vid_ScreenBuffers_vl[s] = AllocScreenBuffer(Vid_MainScreen_l, &bitmaps[s], 0);
            Vid_ScreenBuffers_vl[s]->sb_DBufInfo->dbi_DispMessage.mn_ReplyPort = Vid_DisplayMsgPort_l;
        }

    } else {
        if (!(Vid_MainScreen_l = OpenScreenTags(
            NULL,
            /* Tags */
            SA_Width, SCREEN_WIDTH,
            SA_Height, SCREEN_HEIGHT,
            SA_Depth, 8,
            SA_Type, CUSTOMSCREEN,
            SA_Quiet, 1,
            SA_ShowTitle, SHOW_TITLE_STATE,
            SA_AutoScroll, 0,
            SA_FullPalette, 1,
            SA_DisplayID, Vid_ScreenMode,
            TAG_END, 0))
        ) {
            Sys_FatalError("Failed to open screen for mode %ld", Vid_ScreenMode);
        }


//        struct NameInfo nameInfo;
//        GetDisplayInfoData(NULL, &nameInfo, sizeof(nameInfo), DTAG_NAME, Vid_ScreenMode);

        Vid_ScreenWidth = SCREEN_WIDTH;
        Vid_ScreenHeight = SCREEN_HEIGHT;

        struct DimensionInfo dimInfo;
        if (GetDisplayInfoData(NULL, &dimInfo, sizeof(dimInfo), DTAG_DIMS, Vid_ScreenMode)) {
            Vid_ScreenHeight = dimInfo.Nominal.MaxY + 1 - dimInfo.Nominal.MinY;
        }
    }

    if (!(Vid_MainWindow_l = OpenWindowTags(
        NULL,
        /* Tags */
        WA_Left, 0,
        WA_Top, 0,
        WA_Width, SCREEN_WIDTH,
        WA_Height, SCREEN_HEIGHT,
        WA_CustomScreen, (Tag)Vid_MainScreen_l,
        WA_Activate, 1,
        WA_Borderless, 1,
        WA_RMBTrap, 1,  // prevent menu rendering
        WA_NoCareRefresh, 1,
        WA_SimpleRefresh, 1,
        WA_Backdrop, 1,
        TAG_END, 0))
    ) {
        Sys_FatalError("Could not open window");
    }

    if (!Vid_isRTG) {
        struct ViewPort *vp = ViewPortAddress(Vid_MainWindow_l);
        VideoControlTags(vp->ColorMap, VTAG_USERCLIP_SET, 1, VTAG_END_CM, 0);

        // FreeVPortCopLists/CloseScreen assumes UCopList's are allocated with AllocMem
        // See note in Vid_CloseMainScreen
        doubleHeightCopList = AllocMem(sizeof(*doubleHeightCopList), MEMF_PUBLIC | MEMF_CLEAR);
        if (!doubleHeightCopList) {
            Sys_FatalError("Could not allocate memory for fullscreen copperlist");
        }
    }

    SetAPen(&Vid_MainScreen_l->RastPort, 255);
    SetPointer(Vid_MainWindow_l, emptySprite, 1, 0, 0, 0);
    Vid_LoadMainPalette();
}

void Vid_CloseMainScreen()
{
    LOCAL_INTUITION();
    LOCAL_GFX();
    if (Vid_MainWindow_l) {
        struct ViewPort *viewPort = ViewPortAddress(Vid_MainWindow_l);
        // Ugly stuff.
        // http://amigadev.elowar.com/read/ADCD_2.1/Libraries_Manual_guide/node036A.html
        // http://amigadev.elowar.com/read/ADCD_2.1/Libraries_Manual_guide/node036B.html
        //
        // To get rid of a CINIT'ed pointer (which has to be AllocMem'ed ) we have to use
        // either FreeVPortCopLists or CloseScreen.
        viewPort->UCopIns   = doubleHeightCopList;
        doubleHeightCopList = NULL;

        CloseWindow(Vid_MainWindow_l);
        Vid_MainWindow_l = NULL;
    }

    if (!Vid_isRTG) {
        for (int i = 0; i < 2; ++i) {
            if (Vid_ScreenBuffers_vl[i]) {
                FreeScreenBuffer(Vid_MainScreen_l, Vid_ScreenBuffers_vl[i]);
                Vid_ScreenBuffers_vl[i] = 0;
            }
        }
        if (Vid_DisplayMsgPort_l) {
            DeleteMsgPort(Vid_DisplayMsgPort_l);
            Vid_DisplayMsgPort_l = NULL;
        }
    }

    if (Vid_MainScreen_l) {
        CloseScreen(Vid_MainScreen_l);
        Vid_MainScreen_l = NULL;
    }

    if (!Vid_isRTG) {
        for (int i = 0; i < 2; ++i) {
            FreeRaster(rasters[i], SCREEN_WIDTH, SCREEN_HEIGHT * 8 + 1);
        }
    }
}

void vid_SetupDoubleheightCopperlist(void)
{
    if (Vid_isRTG) {
        return;
    }

    LOCAL_SYSBASE();
    LOCAL_INTUITION();

    // Modulos are hardcoded for 320x256 as we are allocating the bitmap ourselves.
    const LONG RepeatLineModulo = -SCREEN_WIDTH / 8 - 8;
    const LONG SkipLineModulo   = SCREEN_WIDTH / 8 - 8;

// There is a problem with the NDK. custom.h defines all custom chip registers
// as volatile, but CMove takes a non-volatile pointer, resulting in
// "error: initialization discards 'volatile' qualifier from pointer target type "
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wdiscarded-qualifiers"

    WORD startLine = Vid_LetterBoxMarginHeight_w + (Vid_FullScreen_b ? 0 : SMALL_YPOS);
    WORD endLine   = -Vid_LetterBoxMarginHeight_w + (Vid_FullScreen_b ? C2P_FS_HEIGHT : SMALL_YPOS + SMALL_HEIGHT);

    startLine = startLine & ~1;
    endLine   = (endLine + 1) & ~1;

    // HACK: The prototype for CINIT (UCopperListInit) says it accepts the number
    // of copper instructions as an UWORD, but KS3.1 actually expects an ULONG!
    volatile ULONG CopperListLength = 9;
    CINIT(doubleHeightCopList, CopperListLength);

    CWAIT(doubleHeightCopList, startLine, 0);
    // repeat odd lines
    CMOVE(doubleHeightCopList, custom.bpl1mod, RepeatLineModulo);
    // skip even lines
    CMOVE(doubleHeightCopList, custom.bpl2mod, SkipLineModulo);
    // BSCAN2 | BPAGEM | BLP32
    CMOVE(doubleHeightCopList, custom.fmode, 0x4003);

    // set back to normal modulo at start of HUD
    CWAIT(doubleHeightCopList, endLine, 0);
    // BPAGEM | BLP32
    CMOVE(doubleHeightCopList, custom.fmode, 0x0003);
    CMOVE(doubleHeightCopList, custom.bpl1mod, -8);
    CMOVE(doubleHeightCopList, custom.bpl2mod, -8);

    CEND(doubleHeightCopList);

#pragma GCC diagnostic pop

    struct ViewPort *vp = ViewPortAddress(Vid_MainWindow_l);
    Forbid();
    vp->UCopIns = (Vid_DoubleHeight_b ? doubleHeightCopList : NULL);
    Permit();
    RethinkDisplay();
}

void Vid_LoadMainPalette()
{
    extern UBYTE const Vid_GammaIncTables_vb[256 * 8];
    extern UWORD Vid_ContrastAdjust_w;
    extern WORD  Vid_BrightnessOffset_w;
    extern UBYTE Vid_GammaLevel_b;
    LONG gun = 0;
    int c = 0;

    Vid_LoadRGB32Struct_vl[0] = (256 << 16) | 0;  // 256 entries, starting at index 0

    if (Vid_GammaLevel_b > 0) {
        UBYTE const* gamma = Vid_GammaIncTables_vb + (((UWORD)((Vid_GammaLevel_b - 1) & 7)) << 8);
        for (; c < 768; ++c) {
            gun = gamma[draw_Palette_vw[c]] * Vid_ContrastAdjust_w + Vid_BrightnessOffset_w;
            gun = gun < 0 ? 0 : (gun > 65535 ? 65535 : gun);
            Vid_LoadRGB32Struct_vl[c + 1] = (ULONG)gun << 16 | gun;
        }
    } else {
        for (; c < 768; ++c) {
            /* splat the 8-bit value into all 32 */
            gun = draw_Palette_vw[c] * Vid_ContrastAdjust_w + Vid_BrightnessOffset_w;
            gun = gun < 0 ? 0 : (gun > 65535 ? 65535 : gun);
            Vid_LoadRGB32Struct_vl[c + 1] = (ULONG)gun << 16 | gun;
        }
    }

    Vid_LoadRGB32Struct_vl[c + 1] = 0;
    LoadRGB32(ViewPortAddress(Vid_MainWindow_l), Vid_LoadRGB32Struct_vl);
}

ULONG GetScreenMode()
{
    struct Screen *scr;
    struct ScreenModeRequester *req;
    ULONG rc = INVALID_ID;
    ULONG propertymask;
    WORD wx, wy, sx, sy;

    struct List mydisplaylist;

    //    struct DisplayMode mydisplaymode2;
    //    struct DisplayMode mydisplaymode3;
    //    struct DisplayMode mydisplaymode4;
    //    struct DisplayMode mydisplaymode5;
    //    mydisplaymode2 = mydisplaymode;
    //    mydisplaymode3 = mydisplaymode;
    //    mydisplaymode4 = mydisplaymode;
    //    mydisplaymode5 = mydisplaymode;

    //    mydisplaymode.dm_Node.ln_Name = " *** WINDOW ON WORKBENCH SCREEN ***";
    //    mydisplaymode2.dm_Node.ln_Name = " *** WINDOW ON DEF. PUB. SCREEN ***";
    //    mydisplaymode3.dm_Node.ln_Name = "GRAFFITI: PAL";
    //    mydisplaymode4.dm_Node.ln_Name = "GRAFFITI: NTSC";
    //    mydisplaymode5.dm_Node.ln_Name = "  ";
    //    mydisplaymode5.dm_Node.ln_Name[1] = (char)160;

    //    mydisplaymode2.dm_DimensionInfo.Header.DisplayID = 0xFFFFFFFD;        for (int i = 0; i < 2; ++i) {
    //    mydisplaymode3.dm_DimensionInfo.Header.DisplayID = 0xFFFFFFFC;
    //    mydisplaymode4.dm_DimensionInfo.Header.DisplayID = 0xFFFFFFFB;

    NewList(&mydisplaylist);
    //    AddTail(&mydisplaylist, (struct Node *)&mydisplaymode);
    //    AddTail(&mydisplaylist, (struct Node *)&mydisplaymode2);
    //    AddTail(&mydisplaylist, (struct Node *)&mydisplaymode3);
    //    AddTail(&mydisplaylist, (struct Node *)&mydisplaymode4);
    //    AddTail(&mydisplaylist, (struct Node *)&mydisplaymode5);

    if (!AslBase)
        AslBase = OpenLibrary("asl.library", 39);

    if (AslBase) {
        if ((req = AllocAslRequest(ASL_ScreenModeRequest, NULL))) {
            if ((scr = LockPubScreen(0))) {
                //                CalcVisibleSize(scr, &sx, &sy);
                //                sx = sx / 2;
                //                sy = sy * 3 / 4;
                //                CalcCenteredWin(scr, sx, sy, &wx, &wy);

                propertymask = DIPF_IS_EXTRAHALFBRITE | DIPF_IS_DUALPF | DIPF_IS_HAM;
                rc = BestModeID(
                    BIDTAG_NominalWidth, SCREEN_WIDTH,
                    BIDTAG_NominalHeight, SCREEN_HEIGHT,
                    BIDTAG_Depth, 8,
                    BIDTAG_DIPFMustNotHave, propertymask,
                    TAG_DONE
                );

                //                ASLSM_InitialLeftEdge, wx,
                //                    ASLSM_InitialTopEdge, wy, ASLSM_InitialWidth, sx, ASLSM_InitialHeight, sy,

                if (AslRequestTags(
                    req,
                    ASLSM_TitleText, (int)"The Killing Grounds",
                    ASLSM_Screen, (int)scr,
                    ASLSM_InitialDisplayID, rc,
                    ASLSM_MinWidth, SCREEN_WIDTH,
                    ASLSM_MaxWidth, SCREEN_WIDTH,
                    ASLSM_MinHeight, 240,
                    ASLSM_MinDepth, 8,
                    ASLSM_MaxDepth, 8,
                    ASLSM_PropertyFlags, 0,
                    ASLSM_PropertyMask, propertymask,
                    ASLSM_CustomSMList, (int)&mydisplaylist,
                    TAG_DONE
                )) {
                    rc = req->sm_DisplayID;
                } else {
                    rc = INVALID_ID;
                }
                UnlockPubScreen(0, scr);
            }
            FreeAslRequest(req);
        }
        CloseLibrary(AslBase);
        AslBase = NULL;
    }

    return rc;
}

static void CopyFrameBuffer(UBYTE *dst, const UBYTE *src, WORD dstBytesPerRow, WORD width, WORD height)
{
    if (Vid_DoubleHeight_b) {
        if (Vid_DoubleWidth_b) {
            UWORD numLongWords = width / 4;

            for (WORD y = 0; y < height; ++y) {
                const ULONG *srcL = (ULONG *)src;
                {
                    ULONG *dstL = (ULONG *)dst;
                    for (WORD x = 0; x < numLongWords; ++x) {
                        ULONG c = srcL[x];
                        c = c | (c >> 8);
                        dstL[x] = c;
                    }
                }
                dst += dstBytesPerRow;
                {
                    ULONG *dstL = (ULONG *)dst;
                    for (WORD x = 0; x < numLongWords; ++x) {
                        ULONG c = srcL[x];
                        c = c | (c >> 8);
                        dstL[x] = c;
                    }
                }
                src += SCREEN_WIDTH * 2;
                dst += dstBytesPerRow;
            }

        } else {
            for (WORD y = 0; y < height / 2; ++y) {
                CopyMem(src, dst, width);
                dst += dstBytesPerRow;
                CopyMem(src, dst, width);
                src += SCREEN_WIDTH * 2;
                dst += dstBytesPerRow;
            }
        }
    } else {
        if (Vid_DoubleWidth_b) {
            UWORD numLongWords = width / 4;
            for (WORD y = 0; y < height; ++y) {
                const ULONG *srcL = (ULONG *)src;
                const ULONG *dstL = (ULONG *)dst;
                for (WORD x = 0; x < numLongWords; ++x) {
                    ULONG c = *src++;
                    c = c | (c >> 8);
                    *dst++ = c;
                }
                dst += dstBytesPerRow;
                src += SCREEN_WIDTH;
            }

        } else {
            for (WORD y = 0; y < height; ++y) {
                CopyMem(src, dst, width);
                src += SCREEN_WIDTH;
                dst += dstBytesPerRow;
            }
        }
    }
}

void Vid_Present()
{
    BOOL vid_FullRes = ~(Vid_DoubleHeight_b | Vid_DoubleWidth_b);

    /** For full screen, full 1x1 resolution, render onto the chunky buffer */
    if (Vid_FullScreen_b && vid_FullRes && Msg_Enabled()) {
        /** Render any buffered up messages before we submit the screen */
        Msg_RenderFullsccreenBuffer();
    }
    if (Vid_isRTG) {
        LOCAL_CYBERGFX();

        UBYTE *bmPixelData;
        ULONG bmBytesPerRow;
        ULONG bmHeight;
        APTR bmHandle = LockBitMapTags(
            Vid_MainScreen_l->ViewPort.RasInfo->BitMap,
            LBMI_BYTESPERROW, (ULONG)&bmBytesPerRow,
            LBMI_BASEADDRESS, (ULONG)&bmPixelData,
            LBMI_HEIGHT, (ULONG)&bmHeight,
            TAG_DONE
        );
        if (bmHandle) {
            if (Vid_FullScreen_b) {
                WORD height     = C2P_FS_HEIGHT - Vid_LetterBoxMarginHeight_w * 2;
                const BYTE *src = Vid_FastBufferPtr_l + SCREEN_WIDTH * Vid_LetterBoxMarginHeight_w;
                BYTE *dst       = bmPixelData + bmBytesPerRow * Vid_LetterBoxMarginHeight_w;

                if (
                    (FS_WIDTH == SCREEN_WIDTH) &&
                    (bmBytesPerRow == SCREEN_WIDTH) &&
                    vid_FullRes
                ) {
                    CopyMemQuick(src, dst, SCREEN_WIDTH * height);
                } else {
                    CopyFrameBuffer(dst, src, bmBytesPerRow, SCREEN_WIDTH, height);
                }

                if (!vid_FullRes && Msg_Enabled()) {
                    Msg_RenderFullscreenRTG(bmPixelData, bmBytesPerRow);
                }
            } else {
                WORD height     = SMALL_HEIGHT - Vid_LetterBoxMarginHeight_w * 2;
                BYTE *dst       = bmPixelData + bmBytesPerRow * (Vid_LetterBoxMarginHeight_w + SMALL_YPOS) + SMALL_XPOS;
                const BYTE *src = Vid_FastBufferPtr_l + SCREEN_WIDTH * Vid_LetterBoxMarginHeight_w;

                CopyFrameBuffer(dst, src, bmBytesPerRow, SMALL_WIDTH, height);

                if (Msg_Enabled() && Msg_SmallScreenNeedsRedraw()) {
                    Msg_RenderSmallScreenRTG(bmPixelData, bmBytesPerRow);
                }
            }

            Draw_UpdateBorder_RTG(bmPixelData, bmBytesPerRow);

            UnLockBitMap(bmHandle);
        }
#ifdef USE_DEBUG_LIB
        else {
            KPrintF("Could not lock bitmap\n");
        }
#endif
    } else {
        CallAsm(&C2P_Convert);
        if (!Vid_FullScreen_b && Msg_Enabled() && Msg_SmallScreenNeedsRedraw()) {
            PLANEPTR planes[3] = {
                Draw_FastRamPlanePtr,
                &Vid_Screen1Ptr_l[PLANE_OFFSET(DRAW_TEXT_PLANE_NUM) + DRAW_TEXT_SMALL_PLANE_OFFSET ],
                &Vid_Screen2Ptr_l[PLANE_OFFSET(DRAW_TEXT_PLANE_NUM) + DRAW_TEXT_SMALL_PLANE_OFFSET ]
            };
            Msg_RenderSmallScreenPlanar(planes[0]);

            /* restore the borders of the plane */
            Draw_RepairTextPlaneBorders();

            for (UWORD p = 1; p < 3; ++p) {;
                CopyMemQuick(planes[0], planes[p], TEXT_PLANE_SIZE);
            }
        }
        Draw_UpdateBorder_Planar();
    }
    if (Msg_Enabled()) {
        Msg_Tick();
    }
}

#ifdef DEV
#include <stdio.h>
extern UWORD C2P_Family_w;
extern UWORD C2P_Mode_w;
extern UBYTE C2P_AkikoMirror_b;
extern UBYTE C2P_AkikoCACR_b;
extern UBYTE Sys_CPU_68030_b;


static char const* c2p_Families[] = {
    "040/060",
    "030",
    "Akiko"
};

static char const* c2p_Modes[] = {
    "1x1 2/3",
    "1x2 2/3",
    "2x1 2/3",
    "2x2 2/3",
    "1x1 Full",
    "1x2 Full",
    "2x1 Full",
    "2x2 Full",
};

static char const* on  = "On";
static char const* off = "Off";

void C2P_DebugInit(void) {
    if (C2P_Family_w & 1) {
        printf("C2P Family TeleFx, Mode: %s\n", c2p_Modes[C2P_Mode_w]);
    } else {
        printf("C2P Family %s, Mode: %s\n", c2p_Families[C2P_Family_w >> 1], c2p_Modes[C2P_Mode_w]);
        if (C2P_Family_w == 4) {
            printf(
                "\t030 Fix: %s\n\tMirror: %s\n",
                Sys_CPU_68030_b ? (C2P_AkikoCACR_b ? on : off) : "N/A",
                C2P_AkikoMirror_b ? on : off
            );
        }
    }
}
#endif
