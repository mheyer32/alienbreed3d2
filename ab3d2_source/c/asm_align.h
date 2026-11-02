#ifndef ASM_ALIGN_H
#define ASM_ALIGN_H

/**
 * Utility macros for defining the layout of structures shared with the asm code.
 * Apply to the struct/union/enum tag (before '{'), not after the typedef name —
 * GCC ignores aligned when packed+aligned are attached to a typedef.
 */
#define ASM_ALIGN(n) __attribute__((packed, aligned(n)))
#define ASM_PACKED   __attribute__((packed))

#endif // ASM_ALIGN_H
