#ifndef MESSAGE_H
#define MESSAGE_H

/**
 * These define the length of limits of existing messages. The original game used a 640 wide slice with an 8*8
 * fixed font at the bottom of the display, with two lines per message. We use the same font, but rendered
 * proportionally.
 */
#define MSG_SINGLE_LINE_LENGTH 80
#define MSG_MAX_LENGTH (MSG_SINGLE_LINE_LENGTH * 2)

/**
 * There are a maximum of ten custom message texts per level
 */
#define MSG_MAX_CUSTOM 10

/**
 * Defines how quickly messages scroll out of view. This is achieved by pushing null lines on a regular period.
 *
 * Messages are timed based on EClock. The values here are converted into ticks based on the EClock rate.
 */
#define MSG_SCROLL_PERIOD_MS 2000

/**
 * Defines how much time must have elapsed before a message that's a duplicate of the last entry can be added
 * again.
 */
#define MSG_DEDUPLICATION_PERIOD_MS 2000

/**
 * Initialise the in-game message system. This should be called at the start of each level.
 *
 * Messages use a tick system (currently just coupled to the frame number) to determine how long messages are
 * displayed.
 */
extern void Msg_Init(void);

/**
 * Push a message. The message string is not copied. Length is assumed to fit already. This depends on
 * Draw_CalcPropTextSplit() for messages that are expected to be too long to fit in a single line.
 */
extern void Msg_PushLine(REG(a0, const char* textPtr), REG(d0, UWORD length));

/**
 * Push a message, if not a duplicate of the last (unless after a duration of MSG_DEDUPLICATION_PERIOD_MS)
 */
extern void Msg_PushLineDedupLast(REG(a0, const char* textPtr), REG(d0, UWORD length));

/**
 * Retrieve the previous message (TODO)
 */
extern void Msg_PullLast(void);

/**
 * Render the messages in the buffer. This depends on Draw_ChunkyTextProp() to render the lines. This should
 * be called immediately prior to display update.
 */
extern void Msg_Render(void);


#endif // MESSAGE_H
