#include "system.h"
#include "message.h"
#include "draw.h"
#include <string.h>

#define MSG_LINE_BUFFER_EXP 3
#define MSG_LINE_BUFFER_SIZE (1 << MSG_LINE_BUFFER_EXP)
#define MSG_LINE_BUFFER_MASK (MSG_LINE_BUFFER_SIZE - 1)

extern UBYTE Vid_FullScreen_b;
extern UWORD Vid_LetterBoxMarginHeight_w;

extern volatile LONG Vid_VBLCount_l;

static struct {
    CONST_STRPTR lineTextPtrs[MSG_LINE_BUFFER_SIZE];
    UWORD        lineLengths[MSG_LINE_BUFFER_SIZE];
    LONG         nextDuplicateTick;
    CONST_STRPTR lastMessagePtr;
    WORD         lineNumber;
} msg_Buffer;

static __inline WORD msg_NextSlot(WORD lineNumber) {
    return (lineNumber + 1) & MSG_LINE_BUFFER_MASK;
}

static __inline void msg_PushLineRaw(CONST_STRPTR textPtr, UWORD length)
{
    WORD lineNumber = msg_NextSlot(msg_Buffer.lineNumber);
    msg_Buffer.lineTextPtrs[lineNumber] = textPtr;
    msg_Buffer.lineLengths[lineNumber]  = length;
    msg_Buffer.lineNumber = lineNumber;
}

void Msg_Init(void)
{
    memset(&msg_Buffer, 0, sizeof(msg_Buffer));
    msg_Buffer.lineNumber = -1;
    Msg_PushLine("Msg_Init() completed", 20);
}

void Msg_PushLine(REG(a0, CONST_STRPTR textPtr), REG(d0, UWORD length))
{
    if (
        textPtr != msg_Buffer.lastMessagePtr ||
        Vid_VBLCount_l > msg_Buffer.nextDuplicateTick
    ) {
        msg_PushLineRaw(textPtr, length);
        msg_Buffer.lastMessagePtr    = textPtr;
        msg_Buffer.nextDuplicateTick = Vid_VBLCount_l + MSG_DEBOUNCE_LIMIT;
    }
}

void Msg_Render(void) {
    if (!Vid_FullScreen_b) {
        // TODO - handle various display
        return;
    }

    WORD lastLine = msg_NextSlot(msg_Buffer.lineNumber);
    WORD nextLine = lastLine;

    UWORD yPos = Vid_LetterBoxMarginHeight_w + 4;

    do {
        if (NULL != msg_Buffer.lineTextPtrs[nextLine]) {
            Draw_ChunkyTextProp(
                Vid_FastBufferPtr_l,
                SCREEN_WIDTH,
                msg_Buffer.lineLengths[nextLine],
                msg_Buffer.lineTextPtrs[nextLine],
                4,
                yPos,
                255
            );
            yPos += DRAW_MSG_CHAR_H;
        }
        nextLine = msg_NextSlot(nextLine);
    } while (nextLine != lastLine);

    // TODO - base this on actual elapsed time
    if (!(Vid_VBLCount_l & 15)) {
        msg_PushLineRaw(NULL, 0);
    }
}


/**
 * Take a message string, which will tend to be a fixed length, potentially space padded
 * and compress out excess space so that there is a maximum of one space between words and
 * there is no leading or trailing spaces. Compacts in-place, adds a trailing null (if the
 * size decreases) and returns the new string length. The intention of this method is to
 * preprocess level strings.
 */
static UWORD msg_CompactString(STRPTR bufferPtr, UWORD bufferLen);

UWORD msg_CompactString(STRPTR bufferPtr, UWORD bufferLen)
{
    STRPTR readPtr  = bufferPtr;
    STRPTR writePtr = bufferPtr;
    STRPTR lastPtr  = bufferPtr + bufferLen;
    BOOL   skip     = TRUE;

    while (bufferLen--) {
        UBYTE charCode = (UBYTE)*readPtr++;
        /* Skip over all non-printing or blank. Assume ECMA-94 Latin 1 8-bit for Amiga 3.x */
        if ( (charCode > 0x20 && charCode < 0x7F) || charCode > 0xA0 ) {
            skip = FALSE;
        } else if (!skip) {
            skip = TRUE;
        } else {
            continue;
        }
        *writePtr++ = charCode;
    }

    // If we are skip state here, the last character was a space.
    // Back up one.
    if (skip) {
        --writePtr;
    }

    // If we are shorter than the original buffer, null terminate
    if (writePtr < lastPtr) {
        *writePtr = 0;
    }
    return (UWORD)(writePtr - bufferPtr);
}
