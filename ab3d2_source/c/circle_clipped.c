#include "defs.h"
#include "draw.h"
#include "system.h"


/***
 * Clipped Partials
 *
 * The code here focuses on drawing various quadrants of the circle with clipping. There are two key
 * use cases here:
 *    1. Drawing the quadrants of a circle centred inside the viewport but intersecting the edge. Here
 *       the quadrants of the circle that are completely inside the viewport have been rendered already.
 *    2. Drawing the quadrants of a circle centred outside teh viewport. In this case, these are the only
 *       quadrantes rendered at all.
 *
 * TODO this code is still pretty awful
 */

extern LONG draw_RenderBufferStrideTable_vl[];
extern WORD Vid_RightX_w;
extern WORD Vid_BottomY_w;

#define QUADRANT_BIT_BR 1
#define QUADRANT_BIT_BL 2
#define QUADRANT_BIT_TL 4
#define QUADRANT_BIT_TR 8
#define QUADRANT_MASK 15

static inline void putPixel(WORD x, WORD y, const uint8_t* restrict pShade, uint8_t* restrict pDraw)
{
    if (x >= 0 && x < Vid_RightX_w && y >= 0 && y < Vid_BottomY_w) {
        UBYTE* pDest = pDraw + draw_RenderBufferStrideTable_vl[y] + x;
        *pDest = pShade[*pDest];
    }
}

#define JESKO_STEP(x, y, err) \
    if (err <= 0) { \
        y++; \
        err += (y << 1) + 1; \
    } \
    if (err > 0) { \
        x--; \
        err -= (x << 1) + 1; \
    }

// Colours for debug plotting
#define DBG_QUADRANT_RED 46
#define DBG_QUADRANT_GREEN 255
#define DBG_QUADRANT_BLUE 69
#define DBG_QUADRANT_YELLOW 190
#define DBG_QUADRANT_YELLOW 190

static inline void putPixelR(WORD x, WORD y, const uint8_t* restrict pShade, uint8_t* restrict pDraw)
{
    if (x >= 0 && x < Vid_RightX_w && y >= 0 && y < Vid_BottomY_w) {
        UBYTE* pDest = pDraw + draw_RenderBufferStrideTable_vl[y] + x;
        *pDest = DBG_QUADRANT_RED;
    }
}

static inline void putPixelG(WORD x, WORD y, const uint8_t* restrict pShade, uint8_t* restrict pDraw)
{
    if (x >= 0 && x < Vid_RightX_w && y >= 0 && y < Vid_BottomY_w) {
        UBYTE* pDest = pDraw + draw_RenderBufferStrideTable_vl[y] + x;
        *pDest = DBG_QUADRANT_GREEN;
    }
}

static inline void putPixelB(WORD x, WORD y, const uint8_t* restrict pShade, uint8_t* restrict pDraw)
{
    if (x >= 0 && x < Vid_RightX_w && y >= 0 && y < Vid_BottomY_w) {
        UBYTE* pDest = pDraw + draw_RenderBufferStrideTable_vl[y] + x;
        *pDest = DBG_QUADRANT_BLUE;
    }
}

static inline void putPixelY(WORD x, WORD y, const uint8_t* restrict pShade, uint8_t* restrict pDraw)
{
    if (x >= 0 && x < Vid_RightX_w && y >= 0 && y < Vid_BottomY_w) {
        UBYTE* pDest = pDraw + draw_RenderBufferStrideTable_vl[y] + x;
        *pDest = DBG_QUADRANT_YELLOW;
    }
}

/**
 * This is our ugly unoptimised version. Since we're dealing with edge cases (no pun intended) I don't
 * plan to worry about this too much.
 *
 * The quadrants bitmask parameter dictates the quadrants of the circle that will be plotted.
 */
void draw_SCUPartialClipped(
    REG(d0, WORD x0),
    REG(d1, WORD y0),
    REG(d2, WORD radius),
    REG(d3, UWORD quadrants),
    REG(a0, UBYTE const* restrict pShade)
)
{
    if (!quadrants) {
        return;
    }
    UBYTE * restrict pDraw = Vid_FastBufferPtr_l;
    WORD x = radius, y = 0, err = 1 - radius;

    // Render only the selected quadrants
    switch (quadrants) {
        // corners
        case QUADRANT_BIT_BR: // Bottom Right
            while (x >= y) {
                WORD px_p = x0 + x, py_p = y0 + y;
                putPixel(px_p, py_p, pShade, pDraw);
                if (x != y && y != 0) {
                    WORD qx_p = x0 + y, qy_p = y0 + x;
                    putPixel(qx_p, qy_p, pShade, pDraw);
                } /*else if (y == 0 && x != 0) {
                    putPixelR(x0, y0 + x, pShade, pDraw);
                    putPixelB(x0, y0 - x, pShade, pDraw);
                }*/
                JESKO_STEP(x, y, err);
            }
            break;

        case QUADRANT_BIT_BL: // Bottom Left
            while (x >= y) {
                WORD px_m = x0 - x, py_p = y0 + y;
                putPixel(px_m, py_p, pShade, pDraw);
                if (x != y && y != 0) {
                    WORD qx_m = x0 - y, qy_p = y0 + x;
                    putPixel(qx_m, qy_p, pShade, pDraw);
                }/*else if (y == 0 && x != 0) {
                    putPixelR(x0, y0 + x, pShade, pDraw);
                    putPixelB(x0, y0 - x, pShade, pDraw);
                }*/
                JESKO_STEP(x, y, err);
            }
            break;

        case QUADRANT_BIT_TL: // Top Left
            while (x >= y) {
                WORD px_m = x0 - x, py_m = y0 - y;
                putPixel(px_m, py_m, pShade, pDraw);

                if (x != y && y != 0) {
                    WORD qx_m = x0 - y, qy_m = y0 - x;
                    putPixel(qx_m, qy_m, pShade, pDraw);
                } /*else if (y == 0 && x != 0) {
                    putPixelR(x0, y0 + x, pShade, pDraw);
                    putPixelB(x0, y0 - x, pShade, pDraw);
                } */
                JESKO_STEP(x, y, err);
            }
            break;

        case QUADRANT_BIT_TR: // Top Right
            while (x >= y) {
                WORD px_p = x0 + x, py_m = y0 - y;
                putPixel(px_p, py_m, pShade, pDraw);

                if (x != y && y != 0) {
                    WORD qx_p = x0 + y, qy_m = y0 - x;
                    putPixel(qx_p, qy_m, pShade, pDraw);
                } /*else if (y == 0 && x != 0) {
                    putPixelR(x0, y0 + x, pShade, pDraw);
                    putPixelB(x0, y0 - x, pShade, pDraw);
                } */
                JESKO_STEP(x, y, err);
            }
            break;

        // halves
        case QUADRANT_BIT_BR|QUADRANT_BIT_BL: // Bottom
            while (x >= y) {
                WORD px_p = x0 + x, px_m = x0 - x, py_p = y0 + y;
                putPixel(px_p, py_p, pShade, pDraw);
                putPixel(px_m, py_p, pShade, pDraw);

                if (x != y && y != 0) {
                    WORD qx_p = x0 + y, qx_m = x0 - y, qy_p = y0 + x;
                    putPixel(qx_p, qy_p, pShade, pDraw);
                    putPixel(qx_m, qy_p, pShade, pDraw);
                } else if (y == 0 && x != 0) {
                    putPixel(x0, y0 + x, pShade, pDraw);
                    //putPixelB(x0, y0 - x, pShade, pDraw);
                }
                JESKO_STEP(x, y, err);
            }
            break;

        case QUADRANT_BIT_TR|QUADRANT_BIT_TL: // Top
            while (x >= y) {
                WORD px_p = x0 + x, px_m = x0 - x, py_m = y0 - y;
                putPixel(px_m, py_m, pShade, pDraw);
                putPixel(px_p, py_m, pShade, pDraw);

                if (x != y && y != 0) {
                    WORD qx_p = x0 + y, qx_m = x0 - y, qy_m = y0 - x;
                    putPixel(qx_m, qy_m, pShade, pDraw);
                    putPixel(qx_p, qy_m, pShade, pDraw);
                } else if (y == 0 && x != 0) {
                    //putPixelR(x0, y0 + x, pShade, pDraw);
                    putPixel(x0, y0 - x, pShade, pDraw);
                }
                JESKO_STEP(x, y, err);
            }
            break;

        case QUADRANT_BIT_BL|QUADRANT_BIT_TL: // Left
            while (x >= y) {
                WORD px_m = x0 - x, py_p = y0 + y, py_m = y0 - y;
                if (y != 0) { // avoid double horizontal
                    putPixel(px_m, py_p, pShade, pDraw);
                }
                putPixel(px_m, py_m, pShade, pDraw);

                if (x != y && y != 0) {
                    WORD qx_m = x0 - y, qy_p = y0 + x, qy_m = y0 - x;
                    putPixel(qx_m, qy_p, pShade, pDraw);
                    putPixel(qx_m, qy_m, pShade, pDraw);
                } /*else if (y == 0 && x != 0) {
                    putPixelR(x0, y0 + x, pShade, pDraw);
                    putPixelB(x0, y0 - x, pShade, pDraw);
                } */
                JESKO_STEP(x, y, err);
            }
            break;

        case QUADRANT_BIT_BR|QUADRANT_BIT_TR: // Right
            while (x >= y) {
                WORD px_p = x0 + x, py_p = y0 + y, py_m = y0 - y;
                putPixel(px_p, py_p, pShade, pDraw);
                if (y != 0) { // avoid double horizontal
                    putPixel(px_p, py_m, pShade, pDraw);
                }
                if (x != y && y != 0) {
                    WORD qx_p = x0 + y, qy_p = y0 + x, qy_m = y0 - x;
                    putPixel(qx_p, qy_p, pShade, pDraw);
                    putPixel(qx_p, qy_m, pShade, pDraw);
                } else if (y == 0 && x != 0) {
                    // ASM left side doesn't include the zero axis
                    putPixel(x0, y0 + x, pShade, pDraw);
                    putPixel(x0, y0 - x, pShade, pDraw);
                }
                JESKO_STEP(x, y, err);
            }
            break;

        // Diagonal Pairs
        case QUADRANT_BIT_BR|QUADRANT_BIT_TL:
            while (x >= y) {
                WORD px_p = x0 + x, px_m = x0 - x, py_p = y0 + y, py_m = y0 - y;
                putPixel(px_p, py_p, pShade, pDraw);
                putPixel(px_m, py_m, pShade, pDraw);

                if (x != y && y != 0) {
                    WORD qx_p = x0 + y, qx_m = x0 - y, qy_p = y0 + x, qy_m = y0 - x;
                    putPixel(qx_p, qy_p, pShade, pDraw);
                    putPixel(qx_m, qy_m, pShade, pDraw);
                } /*else if (y == 0 && x != 0) {
                    putPixelR(x0, y0 + x, pShade, pDraw);
                    putPixelB(x0, y0 - x, pShade, pDraw);
                }*/
                JESKO_STEP(x, y, err);
            }
            break;

        case QUADRANT_BIT_BL|QUADRANT_BIT_TR:
            while (x >= y) {
                WORD px_p = x0 + x, px_m = x0 - x, py_p = y0 + y, py_m = y0 - y;
                putPixel(px_m, py_p, pShade, pDraw);
                putPixel(px_p, py_m, pShade, pDraw);

                if (x != y && y != 0) {
                    WORD qx_p = x0 + y, qx_m = x0 - y, qy_p = y0 + x, qy_m = y0 - x;
                    putPixel(qx_m, qy_p, pShade, pDraw);
                    putPixel(qx_p, qy_m, pShade, pDraw);
                } /*else if (y == 0 && x != 0) {
                    putPixelR(x0, y0 + x, pShade, pDraw);
                    putPixelB(x0, y0 - x, pShade, pDraw);
                }*/
                JESKO_STEP(x, y, err);
            }
            break;

        // All but corners
        case (~QUADRANT_BIT_BR) & QUADRANT_MASK: // All but bottom right
            while (x >= y) {
                WORD px_p = x0 + x, px_m = x0 - x, py_p = y0 + y, py_m = y0 - y;
                putPixel(px_m, py_p, pShade, pDraw);
                putPixel(px_m, py_m, pShade, pDraw);
                putPixel(px_p, py_m, pShade, pDraw);

                if (x != y && y != 0) {
                    WORD qx_p = x0 + y, qx_m = x0 - y, qy_p = y0 + x, qy_m = y0 - x;
                    putPixel(qx_m, qy_p, pShade, pDraw);
                    putPixel(qx_m, qy_m, pShade, pDraw);
                    putPixel(qx_p, qy_m, pShade, pDraw);
                } /*else if (y == 0 && x != 0) {
                    putPixelR(x0, y0 + x, pShade, pDraw);
                    putPixelB(x0, y0 - x, pShade, pDraw);
                }*/
                JESKO_STEP(x, y, err);
            }
            break;

        case (~QUADRANT_BIT_BL) & QUADRANT_MASK: // All but bottom left
            while (x >= y) {
                WORD px_p = x0 + x, px_m = x0 - x, py_p = y0 + y, py_m = y0 - y;
                putPixel(px_p, py_p, pShade, pDraw);
                putPixel(px_m, py_m, pShade, pDraw);
                putPixel(px_p, py_m, pShade, pDraw);

                if (x != y && y != 0) {
                    WORD qx_p = x0 + y, qx_m = x0 - y, qy_p = y0 + x, qy_m = y0 - x;
                    putPixel(qx_p, qy_p, pShade, pDraw);
                    putPixel(qx_m, qy_m, pShade, pDraw);
                    putPixel(qx_p, qy_m, pShade, pDraw);
                } /*else if (y == 0 && x != 0) {
                    putPixelR(x0, y0 + x, pShade, pDraw);
                    putPixelB(x0, y0 - x, pShade, pDraw);
                } */
                JESKO_STEP(x, y, err);
            }
            break;

        case (~QUADRANT_BIT_TL) & QUADRANT_MASK: // All but top right
            while (x >= y) {
                WORD px_p = x0 + x, px_m = x0 - x, py_p = y0 + y, py_m = y0 - y;
                putPixel(px_p, py_p, pShade, pDraw);
                putPixel(px_m, py_p, pShade, pDraw);
                putPixel(px_p, py_m, pShade, pDraw);

                if (x != y && y != 0) {
                    WORD qx_p = x0 + y, qx_m = x0 - y, qy_p = y0 + x, qy_m = y0 - x;
                    putPixel(qx_p, qy_p, pShade, pDraw);
                    putPixel(qx_m, qy_p, pShade, pDraw);
                    putPixel(qx_p, qy_m, pShade, pDraw);
                } /*else if (y == 0 && x != 0) {
                    putPixelR(x0, y0 + x, pShade, pDraw);
                    putPixelB(x0, y0 - x, pShade, pDraw);
                } */
                JESKO_STEP(x, y, err);
            }
            break;

        case (~QUADRANT_BIT_TR) & QUADRANT_MASK: // All but top left
            while (x >= y) {
                WORD px_p = x0 + x, px_m = x0 - x, py_p = y0 + y, py_m = y0 - y;
                putPixel(px_p, py_p, pShade, pDraw);
                putPixel(px_m, py_p, pShade, pDraw);
                putPixel(px_m, py_m, pShade, pDraw);

                if (x != y && y != 0) {
                    WORD qx_p = x0 + y, qx_m = x0 - y, qy_p = y0 + x, qy_m = y0 - x;
                    putPixel(qx_p, qy_p, pShade, pDraw);
                    putPixel(qx_m, qy_p, pShade, pDraw);
                    putPixel(qx_m, qy_m, pShade, pDraw);
                } /*else if (y == 0 && x != 0) {
                    putPixelR(x0, y0 + x, pShade, pDraw);
                    putPixelB(x0, y0 - x, pShade, pDraw);
                } */
                JESKO_STEP(x, y, err);
            }
            break;


        default:
            while (x >= y) {
                WORD px_p = x0 + x, px_m = x0 - x, py_p = y0 + y, py_m = y0 - y;
                putPixel(px_p, py_p, pShade, pDraw);
                putPixel(px_m, py_p, pShade, pDraw);
                putPixel(px_m, py_m, pShade, pDraw);
                putPixel(px_p, py_m, pShade, pDraw);

                if (x != y && y != 0) {
                    WORD qx_p = x0 + y, qx_m = x0 - y, qy_p = y0 + x, qy_m = y0 - x;
                    putPixel(qx_p, qy_p, pShade, pDraw);
                    putPixel(qx_m, qy_p, pShade, pDraw);
                    putPixel(qx_m, qy_m, pShade, pDraw);
                    putPixel(qx_p, qy_m, pShade, pDraw);
                } /*else if (y == 0 && x != 0) {
                    putPixelR(x0, y0 + x, pShade, pDraw);
                    putPixelB(x0, y0 - x, pShade, pDraw);
                } */
                JESKO_STEP(x, y, err);
            }
            break;
    }
}
