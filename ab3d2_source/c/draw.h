#ifndef DRAW_H
#define DRAW_H

#include <exec/types.h>

extern void Draw_ResetGameDisplay(void);
extern BOOL Draw_Init(void);
extern void Draw_Shutdown(void);

extern UBYTE *Vid_FastBufferPtr_l;

#endif // DRAW_H
