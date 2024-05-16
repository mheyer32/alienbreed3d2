#include "system.h"
#include "message.h"
#include "draw.h"

#define MSG_LINE_BUFFER_EXP 3
#define MSG_LINE_BUFFER_SIZE (1 << MSG_LINE_BUFFER_EXP)
#define MSG_LINE_BUFFER_MASK (MSG_LINE_BUFFER_SIZE - 1)

#define MSG_LENGTH_MASK 0x3FFF
#define MSG_TAG_SHIFT 14

extern UBYTE Vid_FullScreen_b;
extern UWORD Vid_LetterBoxMarginHeight_w;
extern void* Lvl_DataPtr_l;

static UBYTE msg_TagPens[4] = {
    255, /* MSG_TAG_NARRATIVE - intense green */
    254, /* MSG_TAG_DEFAULT - half green */
    125, /* MSG_TAG_OPTIONS - grey-blue */
    252  /* MSG_TAG_OTHER - half grey */
};

/**
 * Sys_FrameTimeECV_q[0] is the current EClock time, updated per frame.
 */
extern struct EClockVal Sys_FrameTimeECV_q[2];

/**
 * Data for our messaging system
 *
 */
static struct {

    /** EClock Timestamp for the next tick */
    struct EClockVal nextTickECV;

    /** Eclock Timestamp for the deduplication */
    struct EClockVal nextDuplicateTickECV;


    ULONG  tickPeriod;
    ULONG  deduplicationPeriod;

    /** Ring buffer of text line pointers */
    const char* lineTextPtrs[MSG_LINE_BUFFER_SIZE];

    /** Ring buffer of text line char lengths (including tags) */
    UWORD       lineLengths[MSG_LINE_BUFFER_SIZE];

    /** Pointer to the most recently pushed message */
    const char* lastMessagePtr;

    /** Current line number (cyclic) */
    WORD        lineNumber;

    /** Length below which a text string is guaranteed to fit */
    UWORD       guranteedTextFitLimitFullScreen;
    UWORD       guranteedTextFitLimitSmallScreen;

    /** For the small screen mode, the number of times to redraw. This should equal the number of screen buffers... */
    UBYTE       redrawCount;

    /** Basic indication that lines are visible */
    UBYTE       linesVis;

} msg_Buffer __attribute__ ((aligned (4))); /* Shouldn't be needed but just in case */

extern BOOL Msg_SmallScreenNeedsRedraw(void) {
    return msg_Buffer.redrawCount > 0 && msg_Buffer.linesVis;
}


/**
 * Take a message string, which will tend to be a fixed length, potentially space padded
 * and compress out excess space so that there is a maximum of one space between words and
 * there is no leading or trailing spaces. Compacts in-place, adds a trailing null (if the
 * size decreases) and returns the new string length. The intention of this method is to
 * preprocess level strings.
 */
static UWORD msg_CompactString(char* bufferPtr, UWORD bufferLen);

/**
 * The original message system used a fixed width buffer of 80 chars to display a single line.
 * Consequently it is not uncommon for there to be no space between the end of the first 80 char
 * line and the start of the next. As we are going to reflow the text for display, we need to
 * care about that.
 */
static void msg_NudgeString(char* bufferPtr, UWORD bufferLen);

/**
 * Get the line number after the given one, cyclically.
 */
static __inline WORD msg_NextLineNumber(WORD lineNumber)
{
    if (Vid_FullScreen_b) {
        return (lineNumber + 1) & MSG_LINE_BUFFER_MASK;
    }
    return (lineNumber < MSG_MAX_LINES_SMALL) ? lineNumber + 1 : 0;
}

/**
 * Push a message line into the buffer.
 */
static __inline void msg_PushLineRaw(const char* textPtr, UWORD lengthAndTag)
{
    WORD lineNumber = msg_NextLineNumber(msg_Buffer.lineNumber);
    msg_Buffer.lineTextPtrs[lineNumber] = textPtr;
    msg_Buffer.lineLengths[lineNumber]  = lengthAndTag;
    msg_Buffer.lineNumber = lineNumber;
    if (textPtr) {
        msg_Buffer.linesVis = 1;
    }
}

/**
 * Initialise the message display system. Called at the start of each level.
 */
void Msg_Init(void)
{
    Sys_MemFillLong(&msg_Buffer, 0, sizeof(msg_Buffer)/sizeof(ULONG));

    msg_Buffer.lineNumber = MSG_LINE_BUFFER_SIZE - 1;
    msg_Buffer.redrawCount = 1;

    /* Since we use proportional text rendering, base the guaranteed fit on the widest char */
    msg_Buffer.guranteedTextFitLimitFullScreen  = (SCREEN_WIDTH / MAX_PROP_CHAR_WIDTH) - 2;
    msg_Buffer.guranteedTextFitLimitSmallScreen = ((SCREEN_WIDTH - (HUD_BORDER_WIDTH * 2) ) / MAX_PROP_CHAR_WIDTH) - 2;

    /** Calculate the tick periods in EClocks from the ms values, based on the reported EClock rate */
    msg_Buffer.tickPeriod          = (Sys_EClockRate * MSG_SCROLL_PERIOD_MS) / 1000;
    msg_Buffer.deduplicationPeriod = (Sys_EClockRate * MSG_DEDUPLICATION_PERIOD_MS) / 1000;

    /** If the level text pointer is set, make sure to preprocess the text. */
    char* levelTextPtr = (char*)Lvl_DataPtr_l;
    if (levelTextPtr) {
        for (int i = 0; i < MSG_MAX_CUSTOM; ++i, levelTextPtr += MSG_MAX_LENGTH) {
            if (
                Draw_IsPrintable(levelTextPtr[MSG_SINGLE_LINE_LENGTH - 1]) &&
                Draw_IsPrintable(levelTextPtr[MSG_SINGLE_LINE_LENGTH])
            ) {
                msg_NudgeString(levelTextPtr + MSG_SINGLE_LINE_LENGTH, MSG_SINGLE_LINE_LENGTH - 1);
            }
            msg_CompactString(levelTextPtr, MSG_MAX_LENGTH);
        }
    }
}

/**
 * Pushes a message line to the buffer, segmenting longer messages into multiple lines. This is sensitive
 * to the screen size as the fit width changes.
 */
void Msg_PushLine(REG(a0, const char* textPtr), REG(d0, UWORD lengthAndTag))
{
    UWORD textLength = lengthAndTag & MSG_LENGTH_MASK;
    UWORD maxFit     = Vid_FullScreen_b ?
        msg_Buffer.guranteedTextFitLimitFullScreen :
        msg_Buffer.guranteedTextFitLimitSmallScreen;

    msg_Buffer.redrawCount = 1;

    if (textLength <= maxFit) {
        msg_PushLineRaw(textPtr, lengthAndTag);
    } else {
        const char* nextTextPtr = textPtr;
        int   lines   = MSG_MAX_LINES_SMALL;
        UWORD textTag = lengthAndTag & ~MSG_LENGTH_MASK;
        maxFit        = Vid_FullScreen_b ?
            SCREEN_WIDTH - (2 * DRAW_MSG_CHAR_W) :
            SCREEN_WIDTH - (2 * (HUD_BORDER_WIDTH + DRAW_MSG_CHAR_W));

        do {
            UWORD fitLength = Draw_CalcPropTextSplit(
                &nextTextPtr,
                textLength,
                maxFit
            );
            msg_PushLineRaw(textPtr, fitLength|textTag);
            textPtr     = nextTextPtr;
            textLength -= fitLength;
        } while (nextTextPtr && lines--);
    }
    msg_Buffer.lastMessagePtr = NULL;
}


/**
 * Pushes a message, provided it's not the same as the last, unless enough time has elapsed.
 */
void Msg_PushLineDedupLast(REG(a0, const char* textPtr), REG(d0, UWORD lengthAndTag))
{
    if (
        textPtr != msg_Buffer.lastMessagePtr ||
        Sys_CheckTimeGE(&Sys_FrameTimeECV_q[0], &msg_Buffer.nextDuplicateTickECV)
    ) {
        msg_Buffer.nextDuplicateTickECV = Sys_FrameTimeECV_q[0];
        Sys_AddTime(&msg_Buffer.nextDuplicateTickECV, msg_Buffer.deduplicationPeriod);
        Msg_PushLine(textPtr, lengthAndTag);
        msg_Buffer.lastMessagePtr = textPtr;
        msg_Buffer.redrawCount = 1;
    }
}

/**
 * TODO
 */
void Msg_PullLast(void)
{

}

/**
 * Called to advance the text buffer
 */
void Msg_Tick(void) {
    if (Sys_CheckTimeGE(&Sys_FrameTimeECV_q[0], &msg_Buffer.nextTickECV)) {
        msg_Buffer.nextTickECV = Sys_FrameTimeECV_q[0];
        Sys_AddTime(&msg_Buffer.nextTickECV, msg_Buffer.tickPeriod);
        msg_PushLineRaw(NULL, 0);
        msg_Buffer.redrawCount = 1; // 2;
    }
}

/**
 * Render the message buffer directly into the fullscreen buffer. This works for AGA and RTG as the text is
 * overlaid onto the game display.
 */
void Msg_RenderFullscreen()
{
    // Fullscreen rendering happens in the chunky buffer...
    WORD  lastLine = msg_NextLineNumber(msg_Buffer.lineNumber);
    WORD  nextLine = lastLine;
    UWORD yPos = Vid_LetterBoxMarginHeight_w + DRAW_TEXT_MARGIN;

    do {
        if (NULL != msg_Buffer.lineTextPtrs[nextLine]) {
            Draw_ChunkyTextProp(
                Vid_FastBufferPtr_l,
                SCREEN_WIDTH,
                msg_Buffer.lineLengths[nextLine] & MSG_LENGTH_MASK,
                msg_Buffer.lineTextPtrs[nextLine],
                DRAW_TEXT_MARGIN,
                yPos,
                msg_TagPens[msg_Buffer.lineLengths[nextLine] >> MSG_TAG_SHIFT]
            );
            yPos += DRAW_MSG_CHAR_H + DRAW_TEXT_Y_SPACING;
        }
        nextLine = msg_NextLineNumber(nextLine);
    } while (nextLine != lastLine);
}

/**
 * Perform chunky text rendering to the provided locked bitmap. This is for RTG in small screen mode and
 * renders outside the game area.
 */
void Msg_RenderSmallScreenRTG(UBYTE* bmBaseAddr, ULONG bmBytesPerRow) {

    /*
     * In small screen mode, we make use of the fact that whatever we draw om the bitmap outside the 3D area
     * will remain visible until we explicitly replace it. Therefore we can skip rendering. The one caveat
     * we do have is that we need to make sure the text is rendered to both buffers.
     *
     * This is a lazy implementation that relies on redrawCount being set to the number of bitmaps. A better
     * solution might be to render once then do a blit operation to copy it to the other buffers. That said,
     * we are in a lock here.
     *
     * TODO - Robustly enure that after rendering no text, avoid doing anything here until there's something
     * new to render.
     */

    /* Small screen rendering is direct to the bitmap */
    WORD  lastLine = msg_NextLineNumber(msg_Buffer.lineNumber);
    WORD  nextLine = lastLine;
    UWORD yPos     = SMALL_HEIGHT + SMALL_YPOS + DRAW_TEXT_MARGIN;

    msg_Buffer.linesVis = 0;

    /* Clear out the text area */
    Draw_ClearRect(
        HUD_BORDER_WIDTH,
        yPos,
        SCREEN_WIDTH - HUD_BORDER_WIDTH - 1,
        SCREEN_HEIGHT - HUD_BORDER_WIDTH - 8
    );

    do {
        if (NULL != msg_Buffer.lineTextPtrs[nextLine]) {
            Draw_ChunkyTextProp(
                bmBaseAddr,
                bmBytesPerRow,
                msg_Buffer.lineLengths[nextLine] & MSG_LENGTH_MASK,
                msg_Buffer.lineTextPtrs[nextLine],
                DRAW_TEXT_MARGIN + HUD_BORDER_WIDTH,
                yPos,
                msg_TagPens[msg_Buffer.lineLengths[nextLine] >> MSG_TAG_SHIFT]
            );
            yPos += DRAW_MSG_CHAR_H + DRAW_TEXT_Y_SPACING;
            ++msg_Buffer.linesVis;
        }
        nextLine = msg_NextLineNumber(nextLine);
    } while (nextLine != lastLine);
    --msg_Buffer.redrawCount;
}

/**
 * Perform planar text rendering to the provided bitplane. This is for AGA mode. The caller provides the bitplane
 * to render to, which is assued to be clear.
 */
void Msg_RenderSmallScreenPlanar(UBYTE* plane) {
    WORD  lastLine = msg_NextLineNumber(msg_Buffer.lineNumber);
    WORD  nextLine = lastLine;
    UWORD yPos = 0;
    msg_Buffer.linesVis = 0;

    /** clear out the text area */
    Sys_MemFillLong(plane, 0, SCREEN_WIDTH * 4);
    do {
        if (NULL != msg_Buffer.lineTextPtrs[nextLine]) {
            Draw_PlanarTextProp(
                plane,
                msg_Buffer.lineLengths[nextLine] & MSG_LENGTH_MASK,
                msg_Buffer.lineTextPtrs[nextLine],
                DRAW_TEXT_MARGIN + HUD_BORDER_WIDTH,
                yPos
            );
            yPos += DRAW_MSG_CHAR_H + DRAW_TEXT_Y_SPACING;
            ++msg_Buffer.linesVis;
        }
        nextLine = msg_NextLineNumber(nextLine);
    } while (nextLine != lastLine);
    --msg_Buffer.redrawCount;
}

void msg_NudgeString(char* bufferPtr, UWORD bufferLen)
{
    char* toPtr   = bufferPtr + bufferLen;
    char* fromPtr = toPtr - 1;
    while (fromPtr > bufferPtr) {
        *--toPtr = *--fromPtr;
    }
    *bufferPtr = (char)' ';
}

UWORD msg_CompactString(char* bufferPtr, UWORD bufferLen)
{
    char* readPtr  = bufferPtr;
    char* writePtr = bufferPtr;
    char* lastPtr  = bufferPtr + bufferLen;
    BOOL  skip     = TRUE;

    while (bufferLen--) {
        UBYTE charCode = (UBYTE)*readPtr++;
        /* Skip over all non-printing or blank. */
        if (Draw_IsPrintable(charCode)) {
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
