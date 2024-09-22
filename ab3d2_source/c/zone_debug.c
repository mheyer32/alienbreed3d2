#ifdef ZONE_DEBUG
#include "system.h"
#include "zone_debug.h"
#include "message.h"
#include <stdio.h>

extern WORD Draw_CurrentZone_w;
extern LONG Sys_FrameNumber_l;
extern LONG Draw_LeftClip_l;
extern LONG Draw_RightClip_l;

extern WORD Draw_LeftClip_w;
extern WORD Draw_RightClip_w;
extern LONG Plr1_Position_vl[3];
extern WORD Plr1_Direction_vw[4];
extern WORD SetClipStage_w;

extern void* Dev_RegStatePtr_l;

extern ULONG Dev_DebugFlags_l;

#define DEV_ZONE_TRACE_VERBOSE_AF (1<<14)

static void ZDbg_ShowRegs(void)
{
    if (Dev_RegStatePtr_l) {
        ULONG *reg = (ULONG*)Dev_RegStatePtr_l;
        puts("\tRegister Dump");
        for (int i=0; i<8; ++i) {
            UWORD *regw = ((UWORD*)&reg[i])+1;
            UBYTE *regb = ((UBYTE*)&reg[i])+3;
            printf(
                "\t\td%d: 0x%08X | %10u .l | %+11d .l | %5u .w | %+6d .w | %3u .b | %+4d .b |\n",
                i, (unsigned)reg[i], (unsigned)reg[i], (int)reg[i],
                (unsigned)*regw,
                (int)*((WORD*)regw),
                (unsigned)*regb,
                (int)*((BYTE*)regb)
            );
        }
        reg = ((ULONG*)(Dev_RegStatePtr_l))+8;
        for (int i=0; i<7; ++i) {
            printf(
                "\t\ta%d: 0x%08X\n",
                i, (unsigned)reg[i]
            );
        }
        printf(
            "\t\ta7: 0x%08X\n\n",
            (unsigned)Dev_RegStatePtr_l
        );
    }
}

void ZDbg_Init(void)
{
    Msg_PushLine("Dumping PVS trace...", MSG_TAG_OTHER|20);
    printf(
        "Draw_Zone_Graph()\n"
        "\tFrame: %d\n"
        "\tDebug: 0x%08X\n"
        "\tPlayer {X:%d, Y:%d, Z:%d}, {cos:%d, sin:%d, ang:%d}\n",
        Sys_FrameNumber_l,
        Dev_DebugFlags_l,
        Plr1_Position_vl[0]>>16,
        Plr1_Position_vl[1]>>16,
        Plr1_Position_vl[2]>>16,
        (int)Plr1_Direction_vw[0],
        (int)Plr1_Direction_vw[1],
        (int)Plr1_Direction_vw[2],
        (int)Plr1_Direction_vw[3]
    );
}

void ZDbg_First(void)
{
    printf(
        "Beginning PVS at Zone %d\n",
        (int)Draw_CurrentZone_w
    );

    ZDbg_DumpZone(Lvl_ZonePtrsPtr_l[Draw_CurrentZone_w]);

    if (Dev_DebugFlags_l & DEV_ZONE_TRACE_VERBOSE_AF) {
        ZDbg_ShowRegs();
    }
}


void ZDbg_Enter(void)
{
    printf(
        "\nDECISION: RENDER ZONE %3d [L:%d R:%d]\n",
        (int)Draw_CurrentZone_w,
        Draw_LeftClip_l,
        Draw_RightClip_l
    );
    if (Dev_DebugFlags_l & DEV_ZONE_TRACE_VERBOSE_AF) {
        ZDbg_ShowRegs();
    }
}

void ZDbg_Skip(void)
{
    printf(
        "\nDECISION: SKIP ZONE %3d [L:%d R:%d]\n",
        (int)Draw_CurrentZone_w,
        (int)Draw_LeftClip_w,
        (int)Draw_RightClip_w
    );
    if (Dev_DebugFlags_l & DEV_ZONE_TRACE_VERBOSE_AF) {
        ZDbg_ShowRegs();
    }
}


void ZDbg_Done(void)
{
    puts("\tEnd trace");
}

void ZDbg_LeftClip(void)
{
    printf(
        "\tLeft Clip: %d [L:%d R:%d]\n",
        (int)SetClipStage_w,
        (int)Draw_LeftClip_w,
        (int)Draw_RightClip_w
    );
    if (Dev_DebugFlags_l & DEV_ZONE_TRACE_VERBOSE_AF) {
        ZDbg_ShowRegs();
    }
}

void ZDbg_RightClip(void)
{
    printf(
        "\tRight Clip: %d [L:%d R:%d]\n",
        (int)SetClipStage_w,
        (int)Draw_LeftClip_w,
        (int)Draw_RightClip_w
    );
    if (Dev_DebugFlags_l & DEV_ZONE_TRACE_VERBOSE_AF) {
        ZDbg_ShowRegs();
    }
}

void ZDbg_DumpZone(REG(a0, Zone* zonePtr)) {

    printf(
        "Zone {\n"
        "\tID: %d\n"
        "\tHeights: [LF:%d LC:%d UF:%d UC:%d WL:%d]\n"
        "\tPVS Zones: [\n",
        (int)zonePtr->z_ID,
        // Note that heights appear to be 16.8, so scale down to give values
        // congruent with the editor.
        zonePtr->z_Floor >> 8,
        zonePtr->z_Roof >> 8,
        zonePtr->z_UpperFloor >> 8,
        zonePtr->z_UpperRoof >> 8,
        zonePtr->z_Water >> 8
    );

    int iZone = 0;
    WORD const* zList = zonePtr->z_PotVisibleZoneList;
    do {
        iZone = *zList;
        printf(
            "\t\t%3d, %5d, %5d, %5d\n",
            iZone,
            (int)zList[1],
            (int)zList[2], // significant?
            (int)zList[3]  // significant?
        );
        zList += 4; // I have no idea why but these records are 8 bytes apart
    } while (iZone > -1);
    printf("\t]\n\tExitList: (%d) [", (int)zonePtr->z_ExitList);

    zList = ((WORD*)zonePtr) + zonePtr->z_ExitList;
    int i = 0;
    do {
        printf("%s%d,", ((i++ & 7) ? "" : "\n\t\t"), (int)*zList);
    } while (*zList++ >= 0);
    puts("\n\t]\n}\n");
}
#endif // ZONE_DEBUG
