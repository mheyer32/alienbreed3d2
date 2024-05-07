
; *****************************************************************************
; *
; * modules/message.s
; *
; * TODO - For the assembler only build, implement these
; *
; *****************************************************************************

				IFND BUILD_WITH_C
				align 4

Msg_Init:
Msg_PushLine:
Msg_PushLineDedupLast:
Msg_PullLast:
Msg_RenderFullscreen:
				rts

				ENDIF
