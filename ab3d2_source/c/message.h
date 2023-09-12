#ifndef MESSAGE_H
#define MESSAGE_H

#define MSG_SINGLE_LINE_LENGTH 80
#define MSG_MAX_LENGTH (MSG_SINGLE_LINE_LENGTH * 2)
#define MSG_MAX_CUSTOM 10

#define MSG_SCROLL_PERIOD_MS 2000
#define MSG_DEDUPLICATION_PERIOD_MS 2000

/**
 * Initialise the in-game message system. This should be called at the start of each level.
 *
 * Messages use a tick system (currently just coupled to the frame number) to determine how long messages are
 * displayed.
 */
extern void Msg_Init(void);

/**
 * Push a message. The message string is not copied. Length is assumed to fit already.
 *
 * This call debounces repeated calls to display the same message if they happen within MSG_DEBOUNCE_LIMIT
 * ticks.
 */
extern void Msg_PushLine(REG(a0, const char* textPtr), REG(d0, UWORD length));

/**
 * Render the messages. Depends on Draw_ChunkyTextProp() to render the lines. This should be called immediately
 * prior to display update for each frame and advances the tick.
 */
extern void Msg_Render(void);


#endif // MESSAGE_H
