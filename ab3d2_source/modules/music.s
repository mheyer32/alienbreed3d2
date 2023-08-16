
mt_init:
				move.l	mt_data,a0
				move.l	a0,a1
				add.l	#$3b8,a1
				moveq	#$7f,d0
				moveq	#0,d1
mt_loop:		move.l	d1,d2
				subq.w	#1,d0
mt_lop2:		move.b	(a1)+,d1
				cmp.b	d2,d1
				bgt.s	mt_loop
				dbf		d0,mt_lop2
				addq.b	#1,d2

				lea		mt_samplestarts(pc),a1
				asl.l	#8,d2
				asl.l	#2,d2
				add.l	#$43c,d2
				add.l	a0,d2
				move.l	d2,a2
				moveq	#$1e,d0
mt_lop3:
				moveq	#0,d1
				move.w	42(a0),d1
				; Avoid writing past end of allocated buffer
				; for empty (last) samples
				beq		.empty
				clr.l	(a2)
				move.l	a2,(a1)+
				bra		.next
.empty:
				move.l	#nullsample,(a1)+
.next:
				asl.l	#1,d1
				add.l	d1,a2
				add.l	#$1e,a0
				dbf		d0,mt_lop3

				or.b	#$2,$bfe001
				move.b	#$6,mt_speed
				clr.w	$dff0a8
				clr.w	$dff0b8
				clr.w	$dff0c8
				clr.w	$dff0d8
				clr.b	mt_songpos
				clr.b	mt_counter
				clr.w	mt_pattpos
				rts

mt_end:			clr.w	$dff0a8
				clr.w	$dff0b8
				clr.w	$dff0c8
				clr.w	$dff0d8
				move.w	#$f,$dff096
				rts

mt_music:
				movem.l	d0-d4/a0-a3/a5-a6,-(a7)
				move.l	mt_data,a0
				addq.b	#$1,mt_counter
				move.b	mt_counter,D0
				cmp.b	mt_speed,D0
				blt.s	mt_nonew
				clr.b	mt_counter
				bra		mt_getnew

mt_nonew:
				lea		mt_voice1(pc),a6
				lea		$dff0a0,a5
				bsr		mt_checkcom
				tst.b	UseAllChannels
				beq		mt_endr
				lea		mt_voice2(pc),a6
				lea		$dff0b0,a5
				bsr		mt_checkcom
				lea		mt_voice3(pc),a6
				lea		$dff0c0,a5
				bsr		mt_checkcom
				lea		mt_voice4(pc),a6
				lea		$dff0d0,a5
				bsr		mt_checkcom
				bra		mt_endr

mt_arpeggio:
				moveq	#0,d0
				move.b	mt_counter,d0
				divs	#$3,d0
				swap	d0
				cmp.w	#$0,d0
				beq.s	mt_arp2
				cmp.w	#$2,d0
				beq.s	mt_arp1

				moveq	#0,d0
				move.b	$3(a6),d0
				lsr.b	#4,d0
				bra.s	mt_arp3
mt_arp1:		moveq	#0,d0
				move.b	$3(a6),d0
				and.b	#$f,d0
				bra.s	mt_arp3
mt_arp2:		move.w	$10(a6),d2
				bra.s	mt_arp4
mt_arp3:		asl.w	#1,d0
				moveq	#0,d1
				move.w	$10(a6),d1
				lea		mt_periods(pc),a0
				moveq	#$24,d7
mt_arploop:
				move.w	(a0,d0.w),d2
				cmp.w	(a0),d1
				bge.s	mt_arp4
				addq.l	#2,a0
				dbf		d7,mt_arploop
				rts
mt_arp4:		move.w	d2,$6(a5)
				rts

mt_getnew:
				move.l	mt_data,a0
				move.l	a0,a3
				move.l	a0,a2
				add.l	#$c,a3
				add.l	#$3b8,a2
				add.l	#$43c,a0

				moveq	#0,d0
				move.l	d0,d1
				move.b	mt_songpos,d0
				move.b	(a2,d0.w),d1
				asl.l	#8,d1
				asl.l	#2,d1
				add.w	mt_pattpos,d1
				clr.w	mt_dmacon

				lea		$dff0a0,a5
				lea		mt_voice1(pc),a6
				bsr		mt_playvoice
				tst.b	UseAllChannels
				beq		mt_setdma
				lea		$dff0b0,a5
				lea		mt_voice2(pc),a6
				bsr		mt_playvoice
				lea		$dff0c0,a5
				lea		mt_voice3(pc),a6
				bsr		mt_playvoice
				lea		$dff0d0,a5
				lea		mt_voice4(pc),a6
				bsr		mt_playvoice
				bra		mt_setdma

mt_playvoice:
				move.l	(a0,d1.l),(a6)
				addq.l	#4,d1
				moveq	#0,d2
				move.b	$2(a6),d2
				and.b	#$f0,d2
				lsr.b	#4,d2
				move.b	(a6),d0
				and.b	#$f0,d0
				or.b	d0,d2
				tst.b	d2
				beq.s	mt_setregs
				moveq	#0,d3
				lea		mt_samplestarts(pc),a1
				move.l	d2,d4
				subq.l	#$1,d2
				asl.l	#2,d2
				mulu	#$1e,d4
				move.l	(a1,d2.l),$4(a6)
				move.w	(a3,d4.l),$8(a6)
				move.w	$2(a3,d4.l),$12(a6)
				move.w	$4(a3,d4.l),d3
				tst.w	d3
				beq.s	mt_noloop
				move.l	$4(a6),d2
				asl.w	#1,d3
				add.l	d3,d2
				move.l	d2,$a(a6)
				move.w	$4(a3,d4.l),d0
				add.w	$6(a3,d4.l),d0
				move.w	d0,8(a6)
				move.w	$6(a3,d4.l),$e(a6)
				move.w	$12(a6),d0
				move.w	d0,$8(a5)
				bra.s	mt_setregs
mt_noloop:
				move.l	$4(a6),d2
				add.l	d3,d2
				move.l	d2,$a(a6)
				move.w	$6(a3,d4.l),$e(a6)
				move.w	$12(a6),d0
				move.w	d0,$8(a5)
mt_setregs:
				move.w	(a6),d0
				and.w	#$fff,d0
				beq		mt_checkcom2
				move.b	$2(a6),d0
				and.b	#$F,d0
				cmp.b	#$3,d0
				bne.s	mt_setperiod
				bsr		mt_setmyport
				bra		mt_checkcom2
mt_setperiod:
				move.w	(a6),$10(a6)
				and.w	#$fff,$10(a6)
				move.w	$14(a6),d0
				move.w	d0,$dff096
				clr.b	$1b(a6)

				move.l	$4(a6),(a5)
				move.w	$8(a6),$4(a5)
				move.w	$10(a6),d0
				and.w	#$fff,d0
				move.w	d0,$6(a5)
				move.w	$14(a6),d0
				or.w	d0,mt_dmacon
				bra		mt_checkcom2

mt_setdma:
				move.w	#250,d0
mt_wait:
				add.w	#1,testchip
				dbra	d0,mt_wait
				move.w	mt_dmacon,d0
				or.w	#$8000,d0
				tst.b	UseAllChannels
				bne.s	.splib
				and.w	#%1111111111110001,d0
.splib
				move.w	d0,$dff096
				move.w	#250,d0
mt_wait2:
				add.w	#1,testchip
				dbra	d0,mt_wait2
				lea		$dff000,a5
				tst.b	UseAllChannels
				beq.s	noall
				lea		mt_voice4(pc),a6
				move.l	$a(a6),$d0(a5)
				move.w	$e(a6),$d4(a5)
				lea		mt_voice3(pc),a6
				move.l	$a(a6),$c0(a5)
				move.w	$e(a6),$c4(a5)
				lea		mt_voice2(pc),a6
				move.l	$a(a6),$b0(a5)
				move.w	$e(a6),$b4(a5)
noall:
				lea		mt_voice1(pc),a6
				move.l	$a(a6),$a0(a5)
				move.w	$e(a6),$a4(a5)

				add.w	#$10,mt_pattpos
				cmp.w	#$400,mt_pattpos
				bne.s	mt_endr
mt_nex:			clr.w	mt_pattpos
				clr.b	mt_break
				addq.b	#1,mt_songpos
				and.b	#$7f,mt_songpos
				move.b	mt_songpos,d1
;	cmp.b	mt_data+$3b6,d1
;	bne.s	mt_endr
;	move.b	mt_data+$3b7,mt_songpos
mt_endr:		tst.b	mt_break
				bne.s	mt_nex
				movem.l	(a7)+,d0-d4/a0-a3/a5-a6
				rts

mt_setmyport:
				move.w	(a6),d2
				and.w	#$fff,d2
				move.w	d2,$18(a6)
				move.w	$10(a6),d0
				clr.b	$16(a6)
				cmp.w	d0,d2
				beq.s	mt_clrport
				bge.s	mt_rt
				move.b	#$1,$16(a6)
				rts
mt_clrport:
				clr.w	$18(a6)
mt_rt:			rts

;CODESTORE:		dc.l	0

mt_myport:
				move.b	$3(a6),d0
				beq.s	mt_myslide
				move.b	d0,$17(a6)
				clr.b	$3(a6)
mt_myslide:
				tst.w	$18(a6)
				beq.s	mt_rt
				moveq	#0,d0
				move.b	$17(a6),d0
				tst.b	$16(a6)
				bne.s	mt_mysub
				add.w	d0,$10(a6)
				move.w	$18(a6),d0
				cmp.w	$10(a6),d0
				bgt.s	mt_myok
				move.w	$18(a6),$10(a6)
				clr.w	$18(a6)
mt_myok:		move.w	$10(a6),$6(a5)
				rts
mt_mysub:
				sub.w	d0,$10(a6)
				move.w	$18(a6),d0
				cmp.w	$10(a6),d0
				blt.s	mt_myok
				move.w	$18(a6),$10(a6)
				clr.w	$18(a6)
				move.w	$10(a6),$6(a5)
				rts

mt_vib:			move.b	$3(a6),d0
				beq.s	mt_vi
				move.b	d0,$1a(a6)

mt_vi:			move.b	$1b(a6),d0
				lea		mt_sin(pc),a4
				lsr.w	#$2,d0
				and.w	#$1f,d0
				moveq	#0,d2
				move.b	(a4,d0.w),d2
				move.b	$1a(a6),d0
				and.w	#$f,d0
				mulu	d0,d2
				lsr.w	#$6,d2
				move.w	$10(a6),d0
				tst.b	$1b(a6)
				bmi.s	mt_vibmin
				add.w	d2,d0
				bra.s	mt_vib2
mt_vibmin:
				sub.w	d2,d0
mt_vib2:		move.w	d0,$6(a5)
				move.b	$1a(a6),d0
				lsr.w	#$2,d0
				and.w	#$3c,d0
				add.b	d0,$1b(a6)
				rts

mt_nop:			move.w	$10(a6),$6(a5)
				rts


mt_checkcom:
				move.w	$2(a6),d0
				and.w	#$fff,d0
				beq.s	mt_nop
				move.b	$2(a6),d0
				and.b	#$f,d0
				tst.b	d0
				beq		mt_arpeggio
				cmp.b	#$1,d0
				beq.s	mt_portup
				cmp.b	#$2,d0
				beq		mt_portdown
				cmp.b	#$3,d0
				beq		mt_myport
				cmp.b	#$4,d0
				beq		mt_vib
				move.w	$10(a6),$6(a5)
				cmp.b	#$a,d0
				beq.s	mt_volslide
				rts

mt_volslide:
				moveq	#0,d0
				move.b	$3(a6),d0
				lsr.b	#4,d0
				tst.b	d0
				beq.s	mt_voldown
				add.w	d0,$12(a6)
				cmp.w	#$40,$12(a6)
				bmi.s	mt_vol2
				move.w	#$40,$12(a6)
mt_vol2:		move.w	$12(a6),d0
				move.w	d0,$8(a5)
				rts

mt_voldown:
				moveq	#0,d0
				move.b	$3(a6),d0
				and.b	#$f,d0
				sub.w	d0,$12(a6)
				bpl.s	mt_vol3
				clr.w	$12(a6)
mt_vol3:		move.w	$12(a6),d0
				move.w	d0,$8(a5)
				rts

mt_portup:
				moveq	#0,d0
				move.b	$3(a6),d0
				sub.w	d0,$10(a6)
				move.w	$10(a6),d0
				and.w	#$fff,d0
				cmp.w	#$71,d0
				bpl.s	mt_por2
				and.w	#$f000,$10(a6)
				or.w	#$71,$10(a6)
mt_por2:		move.w	$10(a6),d0
				and.w	#$fff,d0
				move.w	d0,$6(a5)
				rts

mt_portdown:
				clr.w	d0
				move.b	$3(a6),d0
				add.w	d0,$10(a6)
				move.w	$10(a6),d0
				and.w	#$fff,d0
				cmp.w	#$358,d0
				bmi.s	mt_por3
				and.w	#$f000,$10(a6)
				or.w	#$358,$10(a6)
mt_por3:		move.w	$10(a6),d0
				and.w	#$fff,d0
				move.w	d0,$6(a5)
				rts

mt_checkcom2:
				move.b	$2(a6),d0
				and.b	#$f,d0
				cmp.b	#$e,d0
				beq.s	mt_setfilt
				cmp.b	#$d,d0
				beq.s	mt_pattbreak
				cmp.b	#$b,d0
				beq.s	mt_posjmp
				cmp.b	#$c,d0
				beq.s	mt_setvol
				cmp.b	#$f,d0
				beq.s	mt_setspeed
				rts

mt_setfilt:
				move.b	$3(a6),d0
				and.b	#$1,d0
				asl.b	#$1,d0
				and.b	#$fd,$bfe001
				or.b	d0,$bfe001
				rts
mt_pattbreak:
				not.b	mt_break
				rts
mt_posjmp:
				st		reachedend
				move.b	$3(a6),d0
				subq.b	#$1,d0
				move.b	d0,mt_songpos
				not.b	mt_break
				rts
mt_setvol:
				cmp.b	#$40,$3(a6)
				ble.s	mt_vol4
				move.b	#$40,$3(a6)
mt_vol4:		move.b	$3(a6),d0
				move.w	d0,$8(a5)
				rts
mt_setspeed:
				cmp.b	#$1f,$3(a6)
				ble.s	mt_sets
				move.b	#$1f,$3(a6)
mt_sets:		move.b	$3(a6),d0
				beq.s	mt_rts2
				move.b	d0,mt_speed
				clr.b	mt_counter
mt_rts2:		rts

mt_sin:
				dc.b	$00,$18,$31,$4a,$61,$78,$8d,$a1,$b4,$c5,$d4,$e0,$eb,$f4,$fa,$fd
				dc.b	$ff,$fd,$fa,$f4,$eb,$e0,$d4,$c5,$b4,$a1,$8d,$78,$61,$4a,$31,$18

mt_periods:
				dc.w	$0358,$0328,$02fa,$02d0,$02a6,$0280,$025c,$023a,$021a,$01fc,$01e0
				dc.w	$01c5,$01ac,$0194,$017d,$0168,$0153,$0140,$012e,$011d,$010d,$00fe
				dc.w	$00f0,$00e2,$00d6,$00ca,$00be,$00b4,$00aa,$00a0,$0097,$008f,$0087
				dc.w	$007f,$0078,$0071,$0000,$0000

reachedend:		dc.b	0
mt_speed:		dc.b	6
mt_songpos:		dc.b	0
				align 2
mt_pattpos:		dc.w	0
mt_counter:		dc.b	0

mt_break:		dc.b	0
mt_dmacon:		dc.w	0
mt_samplestarts:ds.l $1f
mt_voice1:		ds.w	10
				dc.w	1
				ds.w	3
mt_voice2:		ds.w	10
				dc.w	2
				ds.w	3
mt_voice3:		ds.w	10
				dc.w	4
				ds.w	3
mt_voice4:		ds.w	10
				dc.w	8
				ds.w	3

;/* End of File */
mt_data:		dc.l	0
