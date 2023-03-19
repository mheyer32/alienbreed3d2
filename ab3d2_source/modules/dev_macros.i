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


; Macro for increasing a dev counter
; Example use
;				DEV_INC.w	VisibleObjCount
;
DEV_INC			MACRO
				move.l	d0,-(sp)
				moveq	#1,d0
				add.\0	d0,dev_\1_\0
				move.l	(sp)+,d0
				ENDM

; Macro for increasing a dev counter, quick version. Requires a scratch register parameter, register is trashed.
; Example use
;				DEV_INCQ.w	VisibleObjCount,d7
;
DEV_INCQ		MACRO
				moveq	#1,\2
				add.\0	\2,dev_\1_\0
				ENDM


; For the release build, all the macros are empty
				ELSE

CALLDEV			MACRO
				ENDM

DEV_ELAPSED32	MACRO
				ENDM

DEV_INC			MACRO
				ENDM

DEV_INCQ		MACRO
				ENDM

				ENDC
