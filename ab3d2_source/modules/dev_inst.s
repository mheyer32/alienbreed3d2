;
; *****************************************************************************
; *
; * modules/dev_inst.s
; *
; * Developer mode instrumentation
; *
; *****************************************************************************

; DEVMODE INSTRUMENTATION

				IFD	DEV

DEV_GRAPH_BUFFER_DIM equ 6
DEV_GRAPH_BUFFER_SIZE equ 1 << DEV_GRAPH_BUFFER_DIM
DEV_GRAPH_BUFFER_MASK equ DEV_GRAPH_BUFFER_SIZE - 1

				section bss,bss
				align 4

dev_GraphBuffer_vl:		ds.l	DEV_GRAPH_BUFFER_SIZE

dev_EClockRate_l:		ds.l	1

; EClockVal stamps
dev_ECVFrameBegin_q:	ds.l	2	; timestamp at the start of the frame
dev_ECVFrameEnd_q:		ds.l	2	; timestamp at the end of the frame

; EClockVal stamps
dev_fps_1st_q:		ds.l	2
dev_fps_2nd_q:		ds.l	2
dev_c2p_1st_q:		ds.l	2
dev_c2p_2nd_q:		ds.l	2
dev_render_1st_q:	ds.l	2
dev_render_2nd_q:	ds.l	2

; Time differences (assumes ev differences fit in 32-bits)
dev_fps_prev_l:		ds.l	1
dev_frametime_l:	ds.l	1
dev_c2p_time_l:		ds.l	1
dev_render_time_l:	ds.l	1

; Character buffer for printing
dev_CharBuffer_vb:	dcb.b	32
dev_FrameIndex_b:	ds.b	1

				section code,code
				align 4

; Initialise the developer options
Dev_Init:
				lea		timername,a0
				lea		timerrequest,a1
				moveq	#0,d0
				moveq	#0,d1
				CALLEXEC OpenDevice

				move.l	timerrequest+IO_DEVICE,_TimerBase
				move.l	d0,timerflag

				; Grab the EClockRate for later
				lea		dev_ECVFrameBegin_q,a0
				jsr		Dev_TimeStamp
				move.l	d0,dev_EClockRate_l
				rts

; Generic text output, buffer in a0, length in d0. Prints at the bottom of the screen, just above the
; Status bar
Dev_Print:
				movem.l	d2/a6,-(sp)
				move.l	Vid_MainScreen_l,a1
				lea		sc_RastPort(a1),a1
				move.l	d0,d2
				clr.l	d0
				move.l	#SCREEN_HEIGHT-30,d1
				CALLGRAF Move

				move.l	d2,d0
				jsr		_LVOText(a6)

				movem.l	(sp)+,d2/a6
				rts

; Dirty macro for truncated 32-bit precision difference between two timestamps
DEV_ELAPSED32	MACRO
				move.l	4(a1),\1
				sub.l	4(a0),\1
				ENDM

; Subtract two timestamps, First pointed to by a0, second by a1. Full return in d0 (upper) : d1(lower)
dev_Elapsed:
				move.l	d2,-(sp)
				move.l	(a1),d0
				move.l	4(a1),d1
				move.l	(a0),d2
				sub.l	4(a0),d1
				subx.l	d2,d0
				move.l	(sp)+,d2
				rts

; Generic timestamp, uses EClockVal in a0
Dev_TimeStamp:
				move.l	a6,-(sp)
				move.l	_TimerBase,a6
				jsr		_LVOReadEClock(a6)
				move.l	(sp)+,a6
				rts

; Mark the beginning of a new frame.
Dev_FrameBegin:
				move.b	dev_FrameIndex_b,d0
				add.b	#1,d0
				and.b	#DEV_GRAPH_BUFFER_MASK,d0
				move.b	d0,dev_FrameIndex_b
				lea		dev_ECVFrameBegin_q,a0
				bra.s	Dev_TimeStamp

; Mark the end of the frame
Dev_FrameEnd:
				lea		dev_ECVFrameEnd_q,a0
				bra.s	Dev_TimeStamp


;fps counter c/o Grond
Dev_FPSMark:
				move.l	a6,-(sp)
				move.l	_TimerBase,a6
				lea		dev_fps_1st_q,a0
				jsr		_LVOReadEClock(a6)

				move.l	(sp)+,a6
				rts

Dev_FPSReport:
				movem.l	d2/a2/a6,-(sp)
				move.l	_TimerBase,a6
				lea		dev_fps_2nd_q,a0
				jsr		_LVOReadEClock(a6)

				move.l	d0,d2
				lea		dev_fps_2nd_q,a0
				lea		dev_fps_1st_q,a1
				jsr		_LVOSubTime(a6)

				move.l	d1,dev_frametime_l

; average:
				move.l	dev_fps_prev_l,d1
				bne	.skip

				add.l	4(a0),d1
.skip:
				add.l	4(a0),d1
				asr.l	#1,d1
				move.l	d1,dev_fps_prev_l
				move.l	d2,d0
				mulu.l	#1000,d0
				divu.l	d1,d0
				lea		FPS_outputstring,a0
				move.l	#10000,d1
				divu.w	d1,d0
				move.b	d0,d2
				beq		.leadingzero

				add.b	#"0",d2			; convert to ASCII
				move.b	d2,(a0)+
				bra		.next

.leadingzero:
				move.b	#" ",(a0)+
.next:
				sub.w	d0,d0
				swap	d0
				divu.w	#10,d1
				divu.w	d1,d0
				move.b	d0,d2
				add.b	#"0",d2			; convert to ASCII
				move.b	d2,(a0)+
				move.b	#".",(a0)+
				sub.w	d0,d0
				swap	d0
				divu.w	#10,d1
				divu.w	d1,d0
				move.b	d0,d2
				add.b	#"0",d2			; convert to ASCII
				move.b	d2,(a0)+
				move.l	#" fps",(a0)+
				move.l	Vid_MainScreen_l,a0
				lea		sc_RastPort(a0),a1
				lea		sc_ViewPort(a0),a0
				move.l	vp_RasInfo(a0),a0
				move.w	ri_RyOffset(a0),d1
				move.l	a1,a2
				clr.l	d0
				add.w	#10,d1
				ext.l	d1
				CALLGRAF Move

				lea	FPS_outputstring,a0
				move.l	a2,a1
				moveq	#8,d0
				CALLGRAF Text

				movem.l	(sp)+,d2/a2/a6
				rts

Dev_C2PElapsed:
				movem.l	d2/a2/a6,-(sp)
				move.l	_TimerBase,a6
				lea		dev_c2p_2nd_q,a0
				jsr		_LVOReadEClock(a6)

				; c2p ends where rendering begins... Save a library call
				lea		dev_render_1st_q,a1
				move.l	(a0),(a1)
				move.l	4(a0),4(a1)

				move.l	d0,d2
				lea		dev_c2p_1st_q,a1
				jsr		_LVOSubTime(a6)

				move.l	d1,dev_c2p_time_l
				lea     dev_time_outbuffer_vb,a0	; pointer to the buffer
				move.l  dev_c2p_time_l,d1			; data to convert
				bsr		deci_4

				movem.l	(sp)+,d2/a2/a6
				rts

Dev_C2PReport:
				movem.l	d2/a2/a6,-(sp)
				move.l	Vid_MainScreen_l,a0
				lea		sc_RastPort(a0),a1
				lea		sc_ViewPort(a0),a0
				move.l	vp_RasInfo(a0),a0
				move.w	ri_RyOffset(a0),d1
				move.l	a1,a2
				clr.l	d0
				add.w	#40,d1
				ext.l	d1
				CALLGRAF Move

				lea		dev_time_outbuffer_vb,a0
				move.l	a2,a1
				moveq	#8,d0
				CALLGRAF Text

				movem.l	(sp)+,d2/a2/a6
				rts

deci_4:			; subroutine-four digit numbers
				mulu.l	#10000,d1
				divu.l	#7094,d1
				divu.l	#1000,d1	; divide by 1000
				swap	d1
				bsr.b	.digit		; evaluate result-move remainder

				divu	#100,d1		; divide by 100
				bsr.b	.digit		; evaluate result and move

				divu	#10,d1		; divide by 10
				bsr		.digit		; evaluate result-move remainder

									; evaluate the remainder directly
.digit:
				add		#$30,d1		; convert result into ASCII
				move.b	d1,(a0)+	; move it into buffer
				clr		d1			; erase lower word
				swap	d1			; move the remainder down
				rts					; return

Dev_RenderMark:
				move.l	a6,-(sp)
				move.l	_TimerBase,a6
				lea		dev_render_1st_q,a0
				jsr		_LVOReadEClock(a6)

				move.l	(sp)+,a6
				rts

Dev_RenderElapsed:
				movem.l	d2/a2/a6,-(sp)
				move.l	_TimerBase,a6
				lea		dev_render_2nd_q,a0
				jsr		_LVOReadEClock(a6) ; a0/a1 are unchanged

				; c2p begins where rendering ends... Save a library call
				lea		dev_c2p_1st_q,a1
				move.l	(a0),(a1)
				move.l	4(a0),4(a1)

				move.l	d0,d2
				lea		dev_render_1st_q,a1
				jsr		_LVOSubTime(a6)

				move.l	d1,dev_render_time_l
				lea     MY_timer_outputstring2,a0	; pointer to the buffer
				move.l  dev_render_time_l,d1		; data to convert
				bsr		deci_4

				movem.l	(sp)+,d2/a2/a6
				rts

Dev_RenderReport:
				movem.l	d2/a2/a6,-(sp)
				move.l	Vid_MainScreen_l,a0
				lea		sc_RastPort(a0),a1
				lea		sc_ViewPort(a0),a0
				move.l	vp_RasInfo(a0),a0
				move.w	ri_RyOffset(a0),d1
				move.l	a1,a2
				clr.l	d0
				add.w	#30,d1
				ext.l	d1
				CALLGRAF Move

				lea		MY_timer_outputstring2,a0
				move.l	a2,a1
				moveq	#8,d0
				CALLGRAF Text

				movem.l	(sp)+,d2/a2/a6
				rts

Dev_FrameReport:
				movem.l	d2/a2/a6,-(sp)
				lea		Frame_outputstring,a0		;pointer to the buffer
				move.l	dev_frametime_l,d1			;data to convert
				bsr		deci_4

				move.l	Vid_MainScreen_l,a0
				lea		sc_RastPort(a0),a1
				lea		sc_ViewPort(a0),a0
				move.l	vp_RasInfo(a0),a0
				move.w	ri_RyOffset(a0),d1
				move.l	a1,a2
				clr.l	d0
				add.w	#20,d1
				ext.l	d1
				CALLGRAF Move

				lea	Frame_outputstring,a0
				move.l	a2,a1
				moveq	#8,d0
				CALLGRAF Text

				movem.l	(sp)+,d2/a2/a6
				rts

; END DEVMODE INSTRUMENTATION

				align 4
timerrequest:				ds.b	IOTV_SIZE
timername:					dc.b	"timer.device",0
; todo - probably some of these can be merged
FPS_outputstring:			dcb.b	10
Frame_outputstring:			dc.b	'    '
Frame_outputstringX:		dc.b	' tot'
dev_time_outbuffer_vb:		dc.b	'    '
MY_timer_outputstringX:		dc.b	' c2p',0
MY_timer_outputstring2:		dc.b	'    '
MY_timer_outputstring2X:	dc.b	' lop'

				align	4
_TimerBase:		dc.l	0
timerflag:		dc.l	-1

				ENDC