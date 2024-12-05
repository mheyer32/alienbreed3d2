#ifndef MATH_25D_H
#define MATH_25D_H

#include "asm_align.h"

/**
 * Simple 2 compoment XZ vector, 16 bit precision
 */
typedef struct {
    WORD v_X;
    WORD v_Z;
} ASM_ALIGN(sizeof(WORD)) Vec2W;

/**
 * Simple 2 compoment XZ vector, 32 bit precision
 */
typedef struct {
    LONG v_X;
    LONG v_Z;
} ASM_ALIGN(sizeof(LONG)) Vec2L;

/**
 * Simple 3 compoment XYZ vector, 32 bit precision
 */
typedef struct {
    WORD v_X;
    WORD v_Y;
    WORD v_Z;
} ASM_ALIGN(sizeof(LONG)) Vec3W;

#define SINTAB_SIZE 8192

extern WORD const SinCosTable_vw[SINTAB_SIZE];

static inline WORD sinw(WORD a) {
    return SinCosTable_vw[(a & (SINTAB_SIZE - 2)) >> 1];
}

static inline WORD cosw(WORD a) {
    return SinCosTable_vw[((a + SINTAB_SIZE / 4) & (SINTAB_SIZE - 2)) >> 1];
}

/**
 * Simple method for determinining which side of a vector defined by an origin+direction a given point is on.
 * Our direction vector will invariably be the fixed returns from sinw()/cosw(). Based on dot product.
 */
static inline int sideOfDirection(Vec2W const* org, Vec2W const* dir, Vec2W const* point) {
    return (int)dir->v_X * (int)(point->v_Z - org->v_Z) -
           (int)dir->v_Z * (int)(point->v_X - org->v_X);
}


#endif // ZONE_H
