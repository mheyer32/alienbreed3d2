
; *****************************************************************************
; *
; * modules/message.s
; *
; * TODO - For the assembler only build, implement these
; *
; *****************************************************************************

				IFND BUILD_WITH_C
				align 4

; a0 UBYTE *drawPtr
; d0 UBYTE charCode

xdraw_ChunkyGlyph:

; d0 : glyph span
; d1 : pen
; d2 : width

PLOTBIT			MACRO
.bit_\0:
				btst	#\0,d0
				beq.s	.bit_\0_skip

				move.b	d1,7-\0(a0)

.bit_\0_skip:
				subq.l	#1,d2
				beq.s	.span
				ENDM

.bit7:
				btst	#7,d0
				beq.s	.bit7_skip

				move.b	d1,(a0)

.bit7_skip:
				subq.l	#1,d2
				beq.s	.span

.bit6:
				btst	#6,d0
				beq.s	.bit6_skip

				move.b	d1,1(a0)

.bit6_skip:
				subq.l	#1,d2
				beq.s	.span

.bit5:
				btst	#5,d0
				beq.s	.bit5_skip

				move.b	d1,2(a0)

.bit5_skip:
				subq.l	#1,d2
				beq.s	.span


.bit4:
				btst	#4,d0
				beq.s	.bit4_skip

				move.b	d1,3(a0)

.bit4_skip:
				subq.l	#1,d2
				beq.s	.span


.bit3:
				btst	#3,d0
				beq.s	.bit3_skip

				move.b	d1,4(a0)

.bit3_skip:
				subq.l	#1,d2
				beq.s	.span

.bit2:
				btst	#2,d0

.bit1:
				btst	#1,d0

.bit0:
				btst	#0,d0

.span:
				rts

				ENDIF
