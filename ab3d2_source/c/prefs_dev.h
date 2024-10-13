#ifndef PREFS_DEV_H
#define PREFS_DEV_H
#ifdef DEV
    #define DEV_SKIP_FLATS					0
    #define DEV_SKIP_SIMPLE_WALLS			1
    #define DEV_SKIP_SHADED_WALLS			2
    #define DEV_SKIP_BITMAPS				3
    #define DEV_SKIP_GLARE_BITMAPS			4
    #define DEV_SKIP_ADDITIVE_BITMAPS		5
    #define DEV_SKIP_LIGHTSOURCED_BITMAPS	6
    #define DEV_SKIP_POLYGON_MODELS			7
    #define DEV_SKIP_FASTBUFFER_CLEAR		8
    #define DEV_SKIP_AI_ATTACK				9
    #define DEV_SKIP_TIMEGRAPH				10
    #define DEV_SKIP_LIGHTING				11
    #define DEV_SKIP_DUMP_BG_DISABLE		12
    #define DEV_ZONE_TRACE					13
    #define DEV_SKIP_PVS_AMEND				14
    #define DEV_SKIP_OVERLAY				31

    {
        "dev.no_flats",
        &Dev_DebugFlags_l,
        DEV_SKIP_FLATS,
        CFG_VAR_TYPE_ULONG_BIT
    },
    {
        "dev.no_simple_walls",
        &Dev_DebugFlags_l,
        DEV_SKIP_SIMPLE_WALLS,
        CFG_VAR_TYPE_ULONG_BIT
    },
    {
        "dev.no_shaded_walls",
        &Dev_DebugFlags_l,
        DEV_SKIP_SHADED_WALLS,
        CFG_VAR_TYPE_ULONG_BIT
    },
    {
        "dev.no_simple_bm",
        &Dev_DebugFlags_l,
        DEV_SKIP_BITMAPS,
        CFG_VAR_TYPE_ULONG_BIT
    },
    {
        "dev.no_glare_bm",
        &Dev_DebugFlags_l,
        DEV_SKIP_GLARE_BITMAPS,
        CFG_VAR_TYPE_ULONG_BIT
    },
    {
        "dev.no_trans_bm",
        &Dev_DebugFlags_l,
        DEV_SKIP_ADDITIVE_BITMAPS,
        CFG_VAR_TYPE_ULONG_BIT
    },
    {
        "dev.no_bumped_bm",
        &Dev_DebugFlags_l,
        DEV_SKIP_LIGHTSOURCED_BITMAPS,
        CFG_VAR_TYPE_ULONG_BIT
    },
    {
        "dev.no_vectors",
        &Dev_DebugFlags_l,
        DEV_SKIP_POLYGON_MODELS,
        CFG_VAR_TYPE_ULONG_BIT
    },
    {
        "dev.no_clear",
        &Dev_DebugFlags_l,
        DEV_SKIP_FASTBUFFER_CLEAR,
        CFG_VAR_TYPE_ULONG_BIT
    },
    {
        "dev.no_attack",
        &Dev_DebugFlags_l,
        DEV_SKIP_AI_ATTACK,
        CFG_VAR_TYPE_ULONG_BIT
    },
    {
        "dev.no_chart",
        &Dev_DebugFlags_l,
        DEV_SKIP_TIMEGRAPH,
        CFG_VAR_TYPE_ULONG_BIT
    },
    {
        "dev.no_lighting",
        &Dev_DebugFlags_l,
        DEV_SKIP_LIGHTING,
        CFG_VAR_TYPE_ULONG_BIT
    },
    {
        "dev.no_pvs_amend",
        &Dev_DebugFlags_l,
        DEV_SKIP_PVS_AMEND,
        CFG_VAR_TYPE_ULONG_BIT
    },

    {
        "dev.no_overlay",
        &Dev_DebugFlags_l,
        DEV_SKIP_OVERLAY,
        CFG_VAR_TYPE_ULONG_BIT
    },


#endif
#endif // PREFS_DEV_H
