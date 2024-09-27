#ifdef ZONE_DEBUG
#include "system.h"
#include "zone_debug.h"
#include "message.h"
#include <stdio.h>

extern WORD Plr1_Zone;
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

#define DEV_ZONE_TRACE            (1<<13)
static ULONG zdbg_TraceFlags = 0;

#define ZDBG_TRACE_RUNNING 1
#define ZDBG_TRACE_LIST_PVS 2
#define ZDBG_TRACE_LIST_EDGES 4

static void ZDbg_ShowRegs(void)
{
    if (Dev_RegStatePtr_l) {
        ULONG *reg = (ULONG*)Dev_RegStatePtr_l;
        puts("\tRegister Dump");
        for (int i = 0; i < 8; ++i) {
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
        for (int i = 0; i < 7; ++i) {
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
    // Note that the debug flags are set durng an interrupt and can therefore become active
    // at any time. We therefore use our own latch here to ensure that once the flag is set,
    // we only start doing stuff after this init function is invoked.

    zdbg_TraceFlags |= ZDBG_TRACE_RUNNING|ZDBG_TRACE_LIST_PVS;
    printf(
        "Draw_Zone_Graph()\n"
        "\tFrame: %d\n"
        "\tDebug: 0x%08X\n"
        "\tPlayer {X:%d, Y:%d, Z:%d}, {cos:%d, sin:%d, ang:%d}\n\tPlayer in zone %d\n",
        Sys_FrameNumber_l,
        Dev_DebugFlags_l,
        Plr1_Position_vl[0] >> 16,
        Plr1_Position_vl[1] >> 16,
        Plr1_Position_vl[2] >> 16,
        (int)Plr1_Direction_vw[0],
        (int)Plr1_Direction_vw[1],
        (int)Plr1_Direction_vw[2],
        (int)Plr1_Direction_vw[3],
        (int)Plr1_Zone
    );

    // Fully dump the player's zone first with the PVS tree displayed
    // but not for the remaining zones traversed.
    ZDbg_DumpZone(Lvl_ZonePtrsPtr_l[Plr1_Zone]);
    zdbg_TraceFlags &= ~ ZDBG_TRACE_LIST_PVS;

    puts("Stepping through PVS zones in order...");
}

void ZDbg_First(void)
{
    if (!(zdbg_TraceFlags & ZDBG_TRACE_RUNNING)) {
        return;
    }
    ZDbg_DumpZone(Lvl_ZonePtrsPtr_l[Draw_CurrentZone_w]);
}


void ZDbg_Enter(void)
{
    if (!(zdbg_TraceFlags & ZDBG_TRACE_RUNNING)) {
        return;
    }
    printf(
        "\nDECISION: PASS ZONE %3d [L:%d R:%d]\n",
        (int)Draw_CurrentZone_w,
        Draw_LeftClip_l,
        Draw_RightClip_l
    );
}

void ZDbg_Skip(void)
{
    if (!(zdbg_TraceFlags & ZDBG_TRACE_RUNNING)) {
        return;
    }
    printf(
        "\nDECISION: SKIP ZONE %3d [L:%d R:%d]\n",
        (int)Draw_CurrentZone_w,
        (int)Draw_LeftClip_w,
        (int)Draw_RightClip_w
    );
}


void ZDbg_Done(void)
{
    if (!(zdbg_TraceFlags & ZDBG_TRACE_RUNNING)) {
        return;
    }
    puts("\tEnd trace");
    zdbg_TraceFlags &= ~ZDBG_TRACE_RUNNING;
    Dev_DebugFlags_l &= ~DEV_ZONE_TRACE;
    Msg_PushLine("Dumped PVS trace...", MSG_TAG_OTHER|20);
}

void ZDbg_LeftClip(void)
{
    if (!(zdbg_TraceFlags & ZDBG_TRACE_RUNNING)) {
        return;
    }
    printf(
        "\tLeft Clip: %d [L:%d R:%d]\n",
        (int)SetClipStage_w,
        (int)Draw_LeftClip_w,
        (int)Draw_RightClip_w
    );
}

void ZDbg_RightClip(void)
{
    if (!(zdbg_TraceFlags & ZDBG_TRACE_RUNNING)) {
        return;
    }
    printf(
        "\tRight Clip: %d [L:%d R:%d]\n",
        (int)SetClipStage_w,
        (int)Draw_LeftClip_w,
        (int)Draw_RightClip_w
    );
}

void ZDbg_DumpZone(REG(a0, Zone* zonePtr)) {
    printf(
        "Zone %d {\n"
        "\tHeights: [LF:%d LC:%d UF:%d UC:%d WL:%d]\n",
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

    if (zdbg_TraceFlags & ZDBG_TRACE_LIST_PVS) {
        puts(
            "\tPVS Zones:\n"
            "\t\t| ID  | Dist   | ...... | ...... |\n"
            "\t\t+-----+--------+--------+--------|"
        );

        do {
            iZone = *zList;
            printf(
                "\t\t| %3d | %6d | %6d | %6d |\n",
                iZone,
                (int)zList[1], // distance
                (int)zList[2], // significant?
                (int)zList[3]  // significant?
            );
            zList += 4; // I have no idea why but these records are 8 bytes apart
        } while (iZone > -1);
    }

    printf(
        "\n\tEdge List: (Offset: %d)\n"
        "\t\t| Idx |  XPos  |  ZPos  |  XLen  |  ZLen  | JZn | ...... | ... | ... | Flag |\n"
        "\t\t+-----+--------+--------+--------+--------+-----+--------+-----+-----+------+\n",
        (int)zonePtr->z_EdgeListOffset
    );
    // ExitList is an address offset prior to the zone
    zList = (WORD*)(((BYTE*)zonePtr) + zonePtr->z_EdgeListOffset);

    do {
        int edge = (int)*zList;
        if (edge >= 0) {
            ZEdge* edgePtr = Lvl_ZoneEdgePtr_l + edge;
            printf(
                "\t\t| %3d | %6d | %6d | %6d | %6d | %3d | %6d | %3d | %3d | %04X |\n",
                edge,
                (int)edgePtr->e_XPos,     (int)edgePtr->e_ZPos,
                (int)edgePtr->e_XLen,     (int)edgePtr->e_ZLen,
                (int)edgePtr->e_JoinZone, (int)edgePtr->e_Word_5,
                (int)edgePtr->e_Byte_12,  (int)edgePtr->e_Byte_13,
                (int)edgePtr->e_Flags
            );
        } else {
            printf(
                "\t\t+(%3d)+--------+--------+--------+--------+-----+--------+-----+-----+------+\n",
                edge
            );
        }
    } while (++zList < ((WORD*)zonePtr));
    puts("}\n");
}
#endif // ZONE_DEBUG
