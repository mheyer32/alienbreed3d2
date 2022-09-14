;
; *****************************************************************************
; *
; * modules/draw.s
; *
; * Miscellaneous drawing definitions
; *
; * Refactored mostly from hires.s
; *
; *****************************************************************************


Draw_FastBufferSize			equ		SCREENWIDTH * 256 + 15	; screen size plus alignment

Draw_FastBufferPtr_l:		dc.l	0						; aligned address
Draw_FastBufferAllocPtr_l:	dc.l	0						; allocated address
Draw_TextScreenPtr_l:		dc.l	0

Draw_Init:
				; allocate chunky render buffer in fastmem
				move.l	#MEMF_ANY,d1
				move.l	#Draw_FastBufferSize,d0
				CALLEXEC AllocVec
				move.l	d0,Draw_FastBufferAllocPtr_l
				;align to 16byte for best C2P perf
				moveq.l	#15,d1
				add.l	d1,d0
				moveq	#-16,d1					; $F0
				and.l	d1,d0
				move.l	d0,Draw_FastBufferPtr_l
				rts

Draw_LevelIntroText:
				move.l	LEVELTEXT,a0
				move.w	PLOPT,d0
				muls	#82*16,d0
				add.l	d0,a0
				move.w	#15,d7
				move.w	#0,d0

.down_text:
				move.l	Draw_TextScreenPtr_l,a1
				jsr		Draw_TextLine
				addq	#1,d0
				add.w	#82,a0
				dbra	d7,.down_text
				rts

Draw_TextLine:
				movem.l	d0/a0/d7,-(a7)

				muls	#80*16,d0
				add.l	d0,a1					; screen pointer

				move.l	#draw_FontPtrs_vl,a3
				moveq	#0,d0
				move.b	(a0)+,d0
				move.l	(a3,d0.w*8),a2
				move.l	4(a3,d0.w*8),a3

				moveq	#0,d4

				moveq	#0,d1					; width counter:
				move.w	#79,d6
				tst.b	(a0)+
				beq.s	.not_centred
				moveq	#-1,d5
				move.l	a0,a4
				moveq	#0,d2
				moveq	#0,d3
				move.w	#79,d0					; number of chars

.add_up:
				addq	#1,d5
				move.b	(a4)+,d2
				move.b	-32(a3,d2.w),d4
				add.w	d4,d3
				cmp.b	#32,d2
				beq.s	.dont_put_in
				move.w	d5,d6
				move.w	d3,d1

.dont_put_in:
				dbra	d0,.add_up
				asr.w	#1,d1
				neg.w	d1
				add.w	#SCREENWIDTH,d1			; horiz pos of start x

.not_centred:
				move.w	d6,d7

.draw_char:
				moveq	#0,d2
				move.b	(a0)+,d2
				sub.w	#32,d2
				moveq	#0,d6
				move.b	(a3,d2.w),d6
				asl.w	#5,d2
				lea		(a2,d2.w),a4			; char font
val				SET		0
				REPT	16
				move.w	(a4)+,d0
				bfins	d0,val(a1){d1:d6}
val				SET		val+80
				ENDR
				add.w	d6,d1
				dbra	d7,.draw_char
				movem.l	(a7)+,d0/a0/d7
				rts

Draw_ClearLevelIntroText:
				move.l	Draw_TextScreenPtr_l,a0
				move.w	#(10240/16)-1,d0
				move.l	#$0,d1

.loop:
				move.l	d1,(a0)+
				move.l	d1,(a0)+
				move.l	d1,(a0)+
				move.l	d1,(a0)+
				move.l	d1,(a0)+
				move.l	d1,(a0)+
				move.l	d1,(a0)+
				move.l	d1,(a0)+
				dbra	d0,.loop
				rts

draw_FontPtrs_vl:
				dc.l	.end_font_0_vb,.char_widths_0_vb
				dc.l	.end_font_1_vb,.char_widths_1_vb
				dc.l	.end_font_2_vb,.char_widths_2_vb

.end_font_0_vb:
				incbin	"endfont0"
.char_widths_0_vb:
				incbin	"charwidths0"
.end_font_1_vb:
; incbin "endfont1"
.char_widths_1_vb:
; incbin "charwidths1"
.end_font_2_vb:
; incbin "endfont2"
.char_widths_2_vb:
; incbin "charwidths2"

				CNOP 0,4
