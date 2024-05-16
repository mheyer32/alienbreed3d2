;
; *****************************************************************************
; *
; * modules/draw.s
; *
; * Ad hoc drawing routines
; *
; * Refactored from various places
; *
; *****************************************************************************

				align	4
draw_NarrateTextTime_w:
				dc.w	5

; move me
firstdigit_b:	dc.b	0
secdigit_b:		dc.b	0
thirddigit_b:	dc.b	0
gunny_b:		dc.b	0

				align 4

;******************************************************************************
;*
;* Initialise system dependencies
;*
;* a0 points to destination memory
;*
;******************************************************************************
				IFND BUILD_WITH_C
Draw_ResetGameDisplay:
				move.l	Vid_Screen1Ptr_l,a0
				bsr		.draw_ResetGameDisplay

				move.l	Vid_Screen2Ptr_l,a0
				; fall through

.draw_ResetGameDisplay:
				move.l	#draw_BorderPacked_vb,d0
				moveq	#0,d1
				lea		Sys_Workspace_vl,a1
				lea		$0,a2
				jsr		unLHA

				rts

;******************************************************************************
;*
;* This renders a line of text to the planar screen.
;*
;* Deprecated for RTG. Called only from the level intro text loop
;*
;* Deduced parameters
;*   a0 text address (80 chars), with 2 byte header:
;*      - Byte 0 is the font selection from #draw_FontPtrs_vl (only 0 used)
;*      - Byte 1 indicates justification (0 none, 1 centred)
;*   a1 planar screen ptr
;*   d0 is line number (0-15)
;*
;******************************************************************************
Draw_LineOfText:
				movem.l	d0/a0/d7,-(a7)
				muls	#80*16,d0
				add.l	d0,a1					; screen pointer
				move.l	#draw_FontPtrs_vl,a3
				moveq	#0,d0
				move.b	(a0)+,d0                ; first text byte in d0 is...
				move.l	(a3,d0.w*8),a2          ; Font Glyph poined to by a2
				move.l	4(a3,d0.w*8),a3         ; Char width pointed to in a3
				moveq	#0,d4
				moveq	#0,d1                   ; width counter:
				move.w	#79,d6                  ; number of characters
				tst.b	(a0)+                   ; second text byte is justification
				beq.s	.not_centred

				moveq	#-1,d5
				move.l	a0,a4                   ; actual string in a4 now
				moveq	#0,d2
				moveq	#0,d3                   ; total width in pixels
				move.w	#79,d0                  ; number of chars

.addup:
				addq	#1,d5
				move.b	(a4)+,d2                ; next char in d2
				move.b	-32(a3,d2.w),d4         ; width of char in d4 (no widths for non-printing 0-31)
				add.w	d4,d3                   ; sum width
				cmp.b	#32,d2                  ; don't include space character in width calculation
				beq.s	.dont_put_in

				move.w	d5,d6
				move.w	d3,d1

.dont_put_in:
				dbra	d0,.addup
				asr.w	#1,d1                   ; Calculate x coordinate for centred string
				neg.w	d1
				add.w	#SCREEN_WIDTH,d1        ; horiz pos of start x

.not_centred:
				move.w	d6,d7

.do_char:
				moveq	#0,d2
				move.b	(a0)+,d2                 ; char code in d2
				sub.w	#32,d2                   ; -32 for glyph index
				moveq	#0,d6
				move.b	(a3,d2.w),d6             ; glyph width in d6
				asl.w	#5,d2                    ;
				lea		(a2,d2.w),a4			 ; glyph data ptr is a4 + 32*glyph index
val				SET		0
				REPT	16                       ; glyph bitmap is 16 pixels tall (?)
				move.w	(a4)+,d0                 ; glyph bitmap is 16 pixels wide
				bfins	d0,val(a1){d1:d6}        ; use bitfield insertion, d1 contains x position, d6 with
val				SET		val+80                   ; next span
				ENDR
				add.w	d6,d1                    ; increment x offset by width
				dbra	d7,.do_char              ; rinse and repeat.
				movem.l	(a7)+,d0/a0/d7
				rts



Draw_BorderAmmoBar:
; Do guns first.
				move.l	#draw_BorderChars_vb,a4
				move.b	Plr1_TmpGunSelected_b,d0
				move.l	#Plr1_Weapons_vb,a5
				cmp.b	#PLR_SLAVE,Plr_MultiplayerType_b
				bne.s	.notplr2
				move.l	#Plr2_Weapons_vb,a5
				move.b	Plr2_TmpGunSelected_b,d0
.notplr2:

				move.b	d0,gunny_b

				move.w	#9,d2
				moveq	#0,d0
.putingunnums:
				move.w	#4,d1
				move.l	a4,a0
				cmp.b	gunny_b,d0
				bne.s	.notsel
				add.l	#5*10*8*2,a0
				addq	#2,a5
				bra.s	.donesel
.notsel:
				tst.w	(a5)+
				beq.s	.donesel
				add.l	#5*10*8,a0
.donesel:
				move.l	Vid_DrawScreenPtr_l,a1
				add.w	d0,a1
				add.l	#3+(240*40),a1
				bsr		draw_BorderDigit
				addq	#1,d0
				dbra	d2,.putingunnums

				move.w	draw_DisplayAmmoCount_w,d0

				cmp.w	#999,d0
				blt.s	.okammo
				move.w	#999,d0

.okammo:
				ext.l	d0
				divs	#10,d0
				swap	d0
				move.b	d0,thirddigit_b
				swap	d0
				ext.l	d0
				divs	#10,d0
				move.b	d0,firstdigit_b
				swap	d0
				move.b	d0,secdigit_b

				move.l	#draw_BorderChars_vb+15*8*10,a0
				cmp.w	#10,draw_DisplayAmmoCount_w
				blt.s	.notsmallamo
				add.l	#7*8*10,a0
.notsmallamo:

				move.l	Vid_DrawScreenPtr_l,a1
				add.l	#20+238*40,a1
				move.b	firstdigit_b,d0
				move.w	#6,d1
				bsr		draw_BorderDigit

				move.l	Vid_DrawScreenPtr_l,a1
				add.l	#21+238*40,a1
				move.b	secdigit_b,d0
				move.w	#6,d1
				bsr		draw_BorderDigit

				move.l	Vid_DrawScreenPtr_l,a1
				add.l	#22+238*40,a1
				move.b	thirddigit_b,d0
				move.w	#6,d1
				bsr		draw_BorderDigit

				rts


;
Draw_BorderEnergyBar:
				move.w	draw_DisplayEnergyCount_w,d0
				bge.s	.okpo
				moveq	#0,d0
.okpo:

				cmp.w	#999,d0
				blt.s	.okenergy
				move.w	#999,d0

.okenergy:
				ext.l	d0
				divs	#10,d0
				swap	d0
				move.b	d0,thirddigit_b
				swap	d0
				ext.l	d0
				divs	#10,d0
				move.b	d0,firstdigit_b
				swap	d0
				move.b	d0,secdigit_b

				move.l	#draw_BorderChars_vb+15*8*10,a0
				cmp.w	#10,draw_DisplayEnergyCount_w
				blt.s	.notsmallamo
				add.l	#7*8*10,a0
.notsmallamo:

				move.l	Vid_DrawScreenPtr_l,a1
				add.l	#34+238*40,a1
				move.b	firstdigit_b,d0
				move.w	#6,d1
				bsr		draw_BorderDigit

				move.l	Vid_DrawScreenPtr_l,a1
				add.l	#35+238*40,a1
				move.b	secdigit_b,d0
				move.w	#6,d1
				bsr		draw_BorderDigit

				move.l	Vid_DrawScreenPtr_l,a1
				add.l	#36+238*40,a1
				move.b	thirddigit_b,d0
				move.w	#6,d1
				bsr		draw_BorderDigit

				move.l	Vid_DisplayScreenPtr_l,a1
				add.l	#34+238*40,a1
				move.b	firstdigit_b,d0
				move.w	#6,d1
				bsr		draw_BorderDigit

				move.l	Vid_DisplayScreenPtr_l,a1
				add.l	#35+238*40,a1
				move.b	secdigit_b,d0
				move.w	#6,d1
				bsr		draw_BorderDigit

				move.l	Vid_DisplayScreenPtr_l,a1
				add.l	#36+238*40,a1
				move.b	thirddigit_b,d0
				move.w	#6,d1
				bsr		draw_BorderDigit

				rts

; Draws an 8x7 (?) digit for the draw_DisplayAmmoCount_w / Health counters
; a1 points to first plane offset (coordinates are aligned to byte locations)
; a2 points to source digit defintion on the first plane
; d0 contains the digit
; d1 contains the pixel height of the glyph
;
; Destination planes are separated by 320 * 256 / 8 = 10240 bytes
; Source planes are separated by 80 bytes
draw_BorderDigit:
				ext.w	d0
				lea		(a0,d0.w),a2

.charlines:
				lea		30720(a1),a3
				move.b	(a2),(a1)
				move.b	10(a2),10240(a1)
				move.b	20(a2),20480(a1)
				move.b	30(a2),(a3)
				move.b	40(a2),10240(a3)
				move.b	50(a2),20480(a3)
				lea		30720(a3),a3
				move.b	60(a2),(a3)
				move.b	70(a2),10240(a3)

				add.w	#10*8,a2 ; next source scanline
				add.w	#40,a1   ; next destination scanline
				dbra	d1,.charlines

				rts

				ENDIF

Draw_NarrateText:

; sub.w #1,draw_NarrateTextTime_w
; bge .NOCHARYET
; move.w #3,draw_NarrateTextTime_w

; FIXME: pixel scrolling for status line  was achieved via actual scroll registers
;				move.l	#SCROLLSCRN,d1
;				move.w	d1,scroll
;				swap	d1
;				move.w	d1,scrolh

				move.w	draw_GameMessageTimer_w,d0
				subq	#1,d0
				move.w	d0,draw_GameMessageTimer_w
				cmp.w	#40,d0
				bge		.NOCHARYET
				tst.w	d0
				bge.s	.okcha

				move.w	#500,draw_GameMessageTimer_w
				bra		.NOCHARYET

.okcha:
				; FIMXE: need to redirect this to the actual screen
				move.l	#SCROLLSCRN,a0
				add.w	draw_GameMessageXPos_w,a0
				moveq	#1,d7

.doachar:
				move.l	draw_GameMessagePtr_l,a1
				moveq	#0,d1
				move.b	(a1)+,d1				; character
				move.l	a1,d2
				cmp.l	draw_GameMessageEnd_l,d2
				blt.s	.notrestartscroll
				move.l	#draw_BlankMessage_vb,a1
				move.l	#draw_BlankMessage_vb+80,draw_GameMessageEnd_l

.notrestartscroll:
				move.l	a1,draw_GameMessagePtr_l
				move.l	#draw_ScrollChars_vb,a1
				asl.w	#3,d1  ; each character glyph is 8 bytes
				add.w	d1,a1  ; address of character glyph

				; render into planes
				move.b	(a1)+,(a0)
				move.b	(a1)+,80(a0)
				move.b	(a1)+,80*2(a0)
				move.b	(a1)+,80*3(a0)
				move.b	(a1)+,80*4(a0)
				move.b	(a1)+,80*5(a0)
				move.b	(a1)+,80*6(a0)
				move.b	(a1)+,80*7(a0)

				addq	#1,a0 ; advance a character position
				dbra	d7,.doachar

				move.w	draw_GameMessageXPos_w,d0
				addq	#2,d0
				move.w	d0,draw_GameMessageXPos_w
				cmp.w	#80,d0
				blt		.NOCHARYET

				move.w	#0,draw_GameMessageXPos_w

.NOCHARYET:
				rts

