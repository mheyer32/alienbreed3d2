;
; *****************************************************************************
; *
; * modules/system.s
; *
; * system initialisation code
; *
; * Refactored from dev_inst.s, hires.s etc.
; *
; *****************************************************************************

				align	4

; Initialise system dependencies
Sys_Init:
				rts

Sys_Done:
				rts

; Generic timestamp, uses EClockVal in a0
;Sys_TimeStamp:
;				move.l	a6,-(sp)
;				move.l	_TimerBase,a6
;				jsr		_LVOReadEClock(a6)
;				move.l	(sp)+,a6
;				rts

; Subtract two full timestamps, First pointed to by a0, second by a1. Full return in d1 (upper) : d0(lower)
; Generally we don't care about the upper, but it's calculated in case we want it.
;Time_Diff:
;				move.l	d2,-(sp)
;				move.l	(a1),d1
;				move.l	4(a1),d0
;				move.l	(a0),d2
;				sub.l	4(a0),d0
;				subx.l	d2,d1
;				move.l	(sp)+,d2
;				rts
