#ifndef MATH_25D_H
#define MATH_25D_H

typedef struct {
    WORD v_X;
    WORD v_Z;
}  __attribute__((packed)) __attribute__ ((aligned (2))) Vec2W;

typedef struct {
    LONG v_X;
    LONG v_Z;
}  __attribute__((packed)) __attribute__ ((aligned (4))) Vec2L;


typedef struct {
    WORD v_X;
    WORD v_Y;
    WORD v_Z;
}  __attribute__((packed)) __attribute__ ((aligned (2))) Vec3W;

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
