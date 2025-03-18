#ifndef PREFS_VID_H
#define PREFS_VID_H

    /* Video Options */
    {
        "vid.contrast.aga",
        &Prefs_ContrastAdjust_AGA_w,
        CFG_PARAM_TYPE_INT,
        CFG_VAR_TYPE_UWORD
    },
    {
        "vid.contrast.rtg",
        &Prefs_ContrastAdjust_RTG_w,
        CFG_PARAM_TYPE_INT,
        CFG_VAR_TYPE_UWORD
    },

    {
        "vid.brightness.aga",
        &Prefs_BrightnessOffset_AGA_w,
        CFG_PARAM_TYPE_INT,
        CFG_VAR_TYPE_WORD
    },
    {
        "vid.brightness.rtg",
        &Prefs_BrightnessOffset_RTG_w,
        CFG_PARAM_TYPE_INT,
        CFG_VAR_TYPE_WORD
    },

    {
        "vid.gamma.aga",
        &Prefs_GammaLevel_AGA_b,
        CFG_PARAM_TYPE_INT,
        CFG_VAR_TYPE_UBYTE
    },
    {
        "vid.gamma.rtg",
        &Prefs_GammaLevel_RTG_b,
        CFG_PARAM_TYPE_INT,
        CFG_VAR_TYPE_UBYTE
    },

    {
        "vid.fullscreen",
        &Prefs_FullScreen_b,
        CFG_PARAM_TYPE_BOOL,
        CFG_VAR_TYPE_UBYTE
    },
    {
        "vid.pixel1x2",
        &Prefs_PixelMode_b,
        CFG_PARAM_TYPE_BOOL,
        CFG_VAR_TYPE_UBYTE
    },
    {
        "vid.vert_margin",
        &Prefs_VertMargin_b,
        CFG_PARAM_TYPE_INT,
        CFG_VAR_TYPE_UBYTE
    },
    {
        "vid.frame_skip",
        &Prefs_FPSLimit_b,
        CFG_PARAM_TYPE_INT,
        CFG_VAR_TYPE_BYTE
    },

    {
        "vid.prefer_akiko",
        &C2P_UseAkiko_b,
        CFG_PARAM_TYPE_BOOL,
        CFG_VAR_TYPE_UBYTE
    },

    {
        "vid.akiko_mirror",
        &C2P_AkikoMirror_b,
        CFG_PARAM_TYPE_BOOL,
        CFG_VAR_TYPE_UBYTE
    },

    {
        "vid.akiko_030_fix",
        &C2P_AkikoCACR_b,
        CFG_PARAM_TYPE_BOOL,
        CFG_VAR_TYPE_UBYTE
    },

#endif // PREFS_VID_H
