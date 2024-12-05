#ifndef ASM_ALIGN_H
#define ASM_ALIGN_H

/**
 * Utility macro for defining the alignment of structures defined in or shared with the asm code.
 */
#define ASM_ALIGN(n) __attribute__((packed)) __attribute__ ((aligned (n)))

#endif // ASM_ALIGN_H
