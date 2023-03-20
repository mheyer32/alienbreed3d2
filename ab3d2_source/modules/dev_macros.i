;
; *****************************************************************************
; *
; * modules/dev_macros.i
; *
; * Developer mode instrumentation
; *
; *****************************************************************************

; DEVMODE INSTRUMENTATION MACROS

				IFD	DEV

DEV_GRAPH_BUFFER_DIM 			equ 6
DEV_GRAPH_BUFFER_SIZE 			equ 64
DEV_GRAPH_BUFFER_MASK 			equ 63
DEV_GRAPH_DRAW_TIME_COLOUR		equ 255
DEV_GRAPH_OBJECT_COUNT_COLOUR	equ 31

CALLDEV			MACRO
				jsr	Dev_\1
				ENDM

; Macros for increasing/decreasing a dev counter. The ability to decrease is included to allow for simpler injection
; points where it's easier to increment on entry to something and decrement in some common early out.
; Example uses:
;				DEV_INC.w	VisibleFlats - calling on an entry to floor drawing
;				DEV_DEC.w	VisibleFlats - calling in early out of floor drawing

DEV_INC			MACRO
				addq.\0	#1,dev_\1_\0
				ENDM

DEV_DEC			MACRO
				subq.\0	#1,dev_\1_\0
				ENDM

; Macros for saving register state.
DEV_SAVE		MACRO
				movem.l	\1,-(sp)
				ENDM

DEV_RESTORE		MACRO
				movem.l	(sp)+,\1
				ENDM

; For the release build, all the macros are empty
				ELSE

CALLDEV			MACRO
				ENDM

DEV_ELAPSED32	MACRO
				ENDM

DEV_INC			MACRO
				ENDM

DEV_DEC			MACRO
				ENDM

DEV_SAVE		MACRO
				ENDM

DEV_RESTORE		MACRO
				ENDM

				ENDC
