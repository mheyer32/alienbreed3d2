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
    /** Ring buffer of text line pointers */
    const char* lineTextPtrs[MSG_LINE_BUFFER_SIZE];

    /** Ring buffer of text line char lengths */
    UWORD       lineLengths[MSG_LINE_BUFFER_SIZE];

    /** The earliest tick value to allow a sequential duplicate message to be added to the buffer */
    LONG        nextDuplicateTick;

    /** Pointer to the most recently pushed message */
    const char* lastMessagePtr;

    /** Current line number (cyclic) */
    WORD        lineNumber;

    /** Length below which a text string is guaranteed to fit */
    UWORD       guranteedTextFitLimit;
} msg_Buffer;

/**
 * Take a message string, which will tend to be a fixed length, potentially space padded
 * and compress out excess space so that there is a maximum of one space between words and
 * there is no leading or trailing spaces. Compacts in-place, adds a trailing null (if the
 * size decreases) and returns the new string length. The intention of this method is to
 * preprocess level strings.
 */
static UWORD msg_CompactString(char* bufferPtr, UWORD bufferLen);

static __inline WORD msg_NextLineNumber(WORD lineNumber) {
    return (lineNumber + 1) & MSG_LINE_BUFFER_MASK;
}

static __inline void msg_PushLineRaw(const char* textPtr, UWORD length)
{
    WORD lineNumber = msg_NextLineNumber(msg_Buffer.lineNumber);
    msg_Buffer.lineTextPtrs[lineNumber] = textPtr;
    msg_Buffer.lineLengths[lineNumber]  = length;
    msg_Buffer.lineNumber = lineNumber;
}

void Msg_Init(void)
{
    memset(&msg_Buffer, 0, sizeof(msg_Buffer));
    msg_Buffer.lineNumber = -1;
    msg_Buffer.guranteedTextFitLimit = (SCREEN_WIDTH / DRAW_MSG_CHAR_W) - 2;

    /** TODO - preprocess level messages */
    msg_PushLineRaw("Msg_Init() completed", 20);
}

void Msg_PushLine(REG(a0, const char* textPtr), REG(d0, UWORD length))
{
    if (
        textPtr != msg_Buffer.lastMessagePtr ||
        Vid_VBLCount_l > msg_Buffer.nextDuplicateTick
    ) {
        if (length <= msg_Buffer.guranteedTextFitLimit) {
            msg_PushLineRaw(textPtr, length);
        } else {
            const char* nextTextPtr = textPtr;
            int lines = 4;
            do {
                UWORD fitLength = Draw_CalcPropTextSplit(
                    &nextTextPtr,
                    length,
                    SCREEN_WIDTH - (2 * DRAW_MSG_CHAR_W)
                );
                msg_PushLineRaw(textPtr, fitLength);
                textPtr = nextTextPtr;
                length -= fitLength;
            } while (nextTextPtr && lines--);
        }
        msg_Buffer.lastMessagePtr    = textPtr;
        msg_Buffer.nextDuplicateTick = Vid_VBLCount_l + MSG_DEBOUNCE_LIMIT;
    }
}

void Msg_Render(void) {
    if (!Vid_FullScreen_b) {
        /* TODO - handle various display */
        return;
    }

    WORD lastLine = msg_NextLineNumber(msg_Buffer.lineNumber);
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
        nextLine = msg_NextLineNumber(nextLine);
    } while (nextLine != lastLine);

    /* TODO - base this on actual elapsed time */
    if (!(Vid_VBLCount_l & 15)) {
        msg_PushLineRaw(NULL, 0);
    }
}



UWORD msg_CompactString(char* bufferPtr, UWORD bufferLen)
{
    char* readPtr  = bufferPtr;
    char* writePtr = bufferPtr;
    char* lastPtr  = bufferPtr + bufferLen;
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

    /* If we are skip state here, the last character was a space. Back up one. */
    if (skip) {
        --writePtr;
    }

    /* If we are shorter than the original buffer, null terminate */
    if (writePtr < lastPtr) {
        *writePtr = 0;
    }
    return (UWORD)(writePtr - bufferPtr);
}
