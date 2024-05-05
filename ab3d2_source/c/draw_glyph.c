typedef unsigned char UBYTE;
typedef unsigned short UWORD;

#define DRAW_MSG_CHAR_H 8

/* These are the fixed with planar glyphs used for in-game messages */
extern UBYTE draw_ScrollChars_vb[];
extern UWORD draw_TextPixelSpan;
extern UBYTE draw_GlyphSpacing_vb[256];
extern UBYTE draw_TextPen;

void draw_ChunkyGlyph(__reg("a0") UBYTE *drawPtr, __reg("d0") UBYTE charCode)
{
    UBYTE *planarPtr    = &draw_ScrollChars_vb[(UWORD)charCode << 3];
    UBYTE  glyphSpacing = draw_GlyphSpacing_vb[charCode] & 0x7;
    UBYTE  glyphWidth   = (draw_GlyphSpacing_vb[charCode] >> 4) - 1;
    for (UWORD row = 0; row < DRAW_MSG_CHAR_H; ++row) {
        UBYTE plane = *planarPtr++;
        UBYTE width = glyphWidth;
        if (plane) {
            switch (glyphSpacing) {
                case 0: if (plane & 128) drawPtr[0] = draw_TextPen; if (!--width) break;
                case 1: if (plane & 64)  drawPtr[1] = draw_TextPen; if (!--width) break;
                case 2: if (plane & 32)  drawPtr[2] = draw_TextPen; if (!--width) break;
                case 3: if (plane & 16)  drawPtr[3] = draw_TextPen; if (!--width) break;
                case 4: if (plane & 8)   drawPtr[4] = draw_TextPen; if (!--width) break;
                case 5: if (plane & 4)   drawPtr[5] = draw_TextPen; if (!--width) break;
                case 6: if (plane & 2)   drawPtr[6] = draw_TextPen; if (!--width) break;
                case 7: if (plane & 1)   drawPtr[7] = draw_TextPen; if (!--width) break;
            }
        }
        drawPtr += draw_TextPixelSpan;
    }
}

