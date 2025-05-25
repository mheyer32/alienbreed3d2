#ifdef ZONE_DEBUG
#include "system.h"
#include "zone_inline.h"
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

extern WORD const* Lvl_ClipsPtr_l;

extern Vec2W const* Lvl_PointsPtr_l;
extern Vec2L const Rotated_vl[];
extern WORD OnScreen_vl[];

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

extern WORD Zone_EdgePointIndexes_vw[];

void ZDbg_Init(void)
{
    zdbg_TraceFlags |= ZDBG_TRACE_RUNNING|ZDBG_TRACE_LIST_PVS;
    printf(
        "Draw_Zone_Graph()\n"
        "\tFrame: %d\n"
        "\tDebug: 0x%08X\n"
        "\tPlayer {X:%d, Z:%d}, {cos:%d, sin:%d, ang:%d}\n\tPlayer in zone %d\n"
        "\tVis Joining Edges %d\n",
        Sys_FrameNumber_l,
        Dev_DebugFlags_l,
        Plr1_Position_vl[0] >> 16,
        Plr1_Position_vl[2] >> 16,
        (int)Plr1_Direction_vw[0], // sine
        (int)Plr1_Direction_vw[1], // cosine
        (int)Plr1_Direction_vw[2], // angle
        (int)Plr1_Zone,
        (int)Zone_VisJoins_w
    );

    for (WORD i = 0; i < (Zone_VisJoins_w << 1); ++i) {
        printf(
            "%d: IDX:%d, Rot: {%d, %d}, OSV:%d\n",
            (int)i,
            (int)Zone_EdgePointIndexes_vw[i],
            Rotated_vl[Zone_EdgePointIndexes_vw[i]].v_X,
            Rotated_vl[Zone_EdgePointIndexes_vw[i]].v_Z,
            (int)OnScreen_vl[Zone_EdgePointIndexes_vw[i]]
        );
    }


    // if (1 == Zone_VisJoins_w) {
    //     printf(
    //         "\tVis Edge: ID: {L:%d, R:%d}, OS:{L:%d, R:%d}, ZC:{L:%d, R:%d}, DC:{L:%d, R:%d}\n",
    //         (int)Zone_EdgeClipIndexes_vw[0], (int)Zone_EdgeClipIndexes_vw[1],
    //         (int)OnScreen_vl[Zone_EdgeClipIndexes_vw[0]],(int)OnScreen_vl[Zone_EdgeClipIndexes_vw[1]],
    //         (int)Draw_ZoneClipL_w, (int)Draw_ZoneClipR_w,
    //         (int)Draw_LeftClip_w, (int)Draw_RightClip_w
    //     );
    // }

    // WORD const errata[] = {
    //     9, 7, 8, 129, ZONE_ID_LIST_END, // For zone 9, remove 7, 8 and 129
    //     ZONE_ID_LIST_END                // Errata list end
    // };
    //
    // Zone_ApplyPVSErrata(errata);

    // Fully dump the player's zone first with the PVS tree displayed
    // but not for the remaining zones traversed.
    ZDbg_DumpZone(Lvl_ZonePtrsPtr_l[Plr1_Zone]);
    zdbg_TraceFlags &= ~ZDBG_TRACE_LIST_PVS;

    // puts("Point data (index, level, rotated, onscreen)");
    // for (WORD i = 0; i < 20; ++i) {
    //     printf(
    //         "\t%3d: {%6d, %6d} => {%6d, %6d} : %6d\n",
    //         (int)i,
    //         (int)Lvl_PointsPtr_l[i].v_X,
    //         (int)Lvl_PointsPtr_l[i].v_Z,
    //         (int)Rotated_vl[i].v_X,
    //         (int)Rotated_vl[i].v_Z,
    //         (int)OnScreen_vl[i]
    //     );
    // }

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
        "\nDECISION: PASS ZONE %3d [L:%d/%d R:%d/%d]\n",
        (int)Draw_CurrentZone_w,
        Draw_LeftClip_l,
        (int)Draw_ZoneClipL_w,
        Draw_RightClip_l,
        (int)Draw_ZoneClipR_w
    );
}

void ZDbg_Skip(void)
{
    if (!(zdbg_TraceFlags & ZDBG_TRACE_RUNNING)) {
        return;
    }
    printf(
        "\nDECISION: SKIP ZONE %3d [L:%d/%d R:%d/%d]\n",
        (int)Draw_CurrentZone_w,
        Draw_LeftClip_l,
        (int)Draw_ZoneClipL_w,
        Draw_RightClip_l,
        (int)Draw_ZoneClipR_w
    );
}

void ZDbg_SkipEdge(void)
{
    if (!(zdbg_TraceFlags & ZDBG_TRACE_RUNNING)) {
        return;
    }
    printf(
        "\nDECISION: SKIP ZONE %3d (Edge PVS)\n",
        (int)Draw_CurrentZone_w
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
        "\tLeft Clip: %d [L:%d/%d R:%d/%d]\n",
        (int)SetClipStage_w,
        (int)Draw_LeftClip_w,
        (int)Draw_ZoneClipL_w,
        (int)Draw_RightClip_w,
        (int)Draw_ZoneClipR_w
    );
}

void ZDbg_RightClip(void)
{
    if (!(zdbg_TraceFlags & ZDBG_TRACE_RUNNING)) {
        return;
    }
    printf(
        "\tRight Clip: %d [L:%d/%d R:%d/%d]\n",
        (int)SetClipStage_w,
        (int)Draw_LeftClip_w,
        (int)Draw_ZoneClipL_w,
        (int)Draw_RightClip_w,
        (int)Draw_ZoneClipR_w
    );
}



void ZDbg_DumpZone(REG(a0, Zone* zonePtr)) {
    printf(
        "Zone %d {\n"
        "\tHeights: [LF:%d LC:%d UF:%d UC:%d WL:%d]\n",
        (int)zonePtr->z_ZoneID,
        // Note that heights appear to be 16.8, so scale down to give values
        // congruent with the editor.
        zonePtr->z_Floor >> 8,
        zonePtr->z_Roof >> 8,
        zonePtr->z_UpperFloor >> 8,
        zonePtr->z_UpperRoof >> 8,
        zonePtr->z_Water >> 8
    );

    ZPVSRecord const* p = zonePtr->z_PotVisibleZoneList;

    if (zdbg_TraceFlags & ZDBG_TRACE_LIST_PVS) {
        puts(
            "\tPVS Zones:\n"
            "\t\t| ID  | Clip   | ...... | ...... | EdgeVis |\n"
            "\t\t+-----+--------+--------+--------+---------+"
        );
        int zone;
        do {
            zone = (int)p->pvs_ZoneID;
            printf(
                "\t\t| %3d | %6d | %6d | %6d | %6d |\n",
                zone,
                (int)(p->pvs_ClipID >= 0 ? Lvl_ClipsPtr_l[p->pvs_ClipID] : -1 ),
                (int)p->pvs_Word2, // significant?
                (int)p->pvs_Word2,  // significant?
                (int)(zone >= 0 ? Lvl_ZonePtrsPtr_l[zone]->z_Unused : 0)
            );
            ++p;
        } while (zone > -1);
    }

    printf(
        "\n\tEdge List: (Offset: %d)\n"
        "\t\t| Idx |  XPos  |  ZPos  |  XLen  |  ZLen  | JZn | ...... | ... | ... | Flag |\n"
        "\t\t+-----+--------+--------+--------+--------+-----+--------+-----+-----+------+\n",
        (int)zonePtr->z_EdgeListOffset
    );
    // ExitList is an address offset prior to the zone
    WORD const* zList = Zone_GetEdgeList(zonePtr);

    do {
        int edge = (int)*zList;
        if (edge >= 0) {
            ZEdge* edgePtr = Lvl_ZoneEdgePtr_l + edge;
            printf(
                "\t\t| %3d | %6d | %6d | %6d | %6d | %3d | %6d | %3d | %3d | %04X |\n",
                edge,
                (int)edgePtr->e_Pos.v_X,     (int)edgePtr->e_Pos.v_Z,
                (int)edgePtr->e_Len.v_X,     (int)edgePtr->e_Len.v_Z,
                (int)edgePtr->e_JoinZoneID, (int)edgePtr->e_Word_5,
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
