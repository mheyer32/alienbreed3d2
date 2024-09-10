#ifndef PREFS_MISC_H
#define PREFS_MISC_H

    {
        "misc.original_mouse",
        &Prefs_OriginalMouse_b,
        CFG_PARAM_TYPE_BOOL,
        CFG_VAR_TYPE_UBYTE
    },
    {
        "misc.always_run",
        &Prefs_AlwaysRun_b,
        CFG_PARAM_TYPE_BOOL,
        CFG_VAR_TYPE_UBYTE
    },
    {
        "misc.disable_auto_aim",
        &Prefs_NoAutoAim_b,
        CFG_PARAM_TYPE_BOOL,
        CFG_VAR_TYPE_UBYTE
    },
    {
        "misc.crosshair_colour",
        &Prefs_CrossHairColour_b,
        CFG_PARAM_TYPE_INT,
        CFG_VAR_TYPE_UBYTE
    },
    {
        "misc.disable_messages",
        &Prefs_ShowMessages_b,
        CFG_PARAM_TYPE_BOOL_INV,
        CFG_VAR_TYPE_UBYTE
    },


#endif // PREFS_VID_H
