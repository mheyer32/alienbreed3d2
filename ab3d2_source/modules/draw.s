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
Energy:			dc.w	191
OldEnergy:		dc.w	191
Ammo:			dc.w	63
OldAmmo:		dc.w	63

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
				jsr		.draw_ResetGameDisplay

				move.l	Vid_Screen2Ptr_l,a0
				jsr		.draw_ResetGameDisplay

				rts

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
;* Deprecated for RTG
;*
;******************************************************************************
Draw_LineOfText:
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

.addup:
				addq	#1,d5
				move.b	(a4)+,d2
				move.b	-32(a3,d2.w),d4
				add.w	d4,d3
				cmp.b	#32,d2
				beq.s	.dont_put_in

				move.w	d5,d6
				move.w	d3,d1

.dont_put_in:
				dbra	d0,.addup
				asr.w	#1,d1
				neg.w	d1
				add.w	#SCREEN_WIDTH,d1			; horiz pos of start x

.not_centred:
				move.w	d6,d7

.do_char:
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
				dbra	d7,.do_char
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

				move.w	Ammo,d0

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
				cmp.w	#10,Ammo
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
				move.w	Energy,d0
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
				cmp.w	#10,Energy
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

				move.l	Vid_DisplayScreen_Ptr_l,a1
				add.l	#34+238*40,a1
				move.b	firstdigit_b,d0
				move.w	#6,d1
				bsr		draw_BorderDigit

				move.l	Vid_DisplayScreen_Ptr_l,a1
				add.l	#35+238*40,a1
				move.b	secdigit_b,d0
				move.w	#6,d1
				bsr		draw_BorderDigit

				move.l	Vid_DisplayScreen_Ptr_l,a1
				add.l	#36+238*40,a1
				move.b	thirddigit_b,d0
				move.w	#6,d1
				bsr		draw_BorderDigit

				rts


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

				add.w	#10*8,a2
				add.w	#40,a1
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

				move.w	SCROLLTIMER,d0
				subq	#1,d0
				move.w	d0,SCROLLTIMER
				cmp.w	#40,d0
				bge		.NOCHARYET
				tst.w	d0
				bge.s	.okcha

				move.w	#150,SCROLLTIMER
				bra		.NOCHARYET

.okcha:
				; FIMXE: need to redirect this to teh actual screen
				move.l	#SCROLLSCRN,a0
				add.w	SCROLLXPOS,a0

				moveq	#1,d7
.doachar:

				move.l	SCROLLPOINTER,a1
				moveq	#0,d1
				move.b	(a1)+,d1				; character
				move.l	a1,d2
				cmp.l	ENDSCROLL,d2
				blt.s	.notrestartscroll
				move.l	#BLANKSCROLL,a1
				move.l	#BLANKSCROLL+80,ENDSCROLL

.notrestartscroll:
				move.l	a1,SCROLLPOINTER

				move.l	#draw_ScrollChars_vb,a1
				asl.w	#3,d1
				add.w	d1,a1

				move.b	(a1)+,(a0)
				move.b	(a1)+,80(a0)
				move.b	(a1)+,80*2(a0)
				move.b	(a1)+,80*3(a0)
				move.b	(a1)+,80*4(a0)
				move.b	(a1)+,80*5(a0)
				move.b	(a1)+,80*6(a0)
				move.b	(a1)+,80*7(a0)

				addq	#1,a0
				dbra	d7,.doachar

				move.w	SCROLLXPOS,d0
				addq	#2,d0
				move.w	d0,SCROLLXPOS
				cmp.w	#80,d0
				blt		.NOCHARYET
				move.w	#0,SCROLLXPOS

.NOCHARYET:
				rts



