#ifndef PREFS_GFX_H
#define PREFS_GFX_H

    /* Graphics Options */

    {
        "gfx.simple_walls",
        &Prefs_SimpleLighting_b,
        CFG_PARAM_TYPE_BOOL,
        CFG_VAR_TYPE_UBYTE
    },

    {
        "gfx.reduced_quality",
        &Prefs_RenderQuality_b,
        CFG_PARAM_TYPE_BOOL_INV,
        CFG_VAR_TYPE_UBYTE
    },

    {
        "gfx.disable_dynamic_lights",
        &Prefs_DynamicLights_b,
        CFG_PARAM_TYPE_BOOL_INV,
        CFG_VAR_TYPE_UBYTE
    },

#endif // PREFS_VID_H
