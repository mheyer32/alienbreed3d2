;;;=======================================================================
;;; Filename:      keyboard.s
;;; Author:        Dave Dixon
;;; Date Started:  Sat 20 Feb 1993
;;; Revision:      $Revision: 1.6 $
;;; Comments:
;;;		   Initialize keyboard interrupt. 
;;;=======================================================================


_keycode_	equ	1	; this file contains keycode!

		include	"cmacros.i"
		include	"chipmap.i"
		include "lvo.i"
		incdir	include:
		include "hardware/intbits.i"
		include "exec/nodes.i"
		
		XDEF	_keycode
		XDEF	_keypressed
		XDEF	_scan_2_ascii
		XDEF	_shift_scan_2_ascii
		XDEF	_caps_scan_2_ascii

		XREF	_atexit

		SECTION	"text",code

;
; checksum calculator
;

	PROC	GetSum
	USES	d4
	moveq	#0,d0
	moveq	#0,d4

	subq	#1,d1			; for dbra
.chunk
	add.b	(a0)+,d0		; chk1(d3) += byte 
	add.b	d0,d4			; chk2(d4) += chk1

	subq.l	#1,d1
	bcc.b	.chunk

	lsl.w	#8,d4
	or.w	d4,d0			; return in AX(d3)
	ret




;-------------------------------------------------------------------------
; Initialize our keyboard interrupt
;-------------------------------------------------------------------------

		PROC	InitKeybd
		USES	a2-a6/d2-d7

		cmp.b	#1,KFlag		; Is our keyboard routine already installed ?
		beq.s	.already_installed
	
		move.l	4.w,a6
		lea	KEYInt(pc),a1
		moveq	#0,d0
		move.b	#INTB_PORTS,d0
		jsr	_LVOAddIntServer(a6)

		move.b	#0,_keycode		; Blank keycode
		pea	_RestoreKeybd		; atexit(RestoreKeybd)
		jsr	_atexit
		lea.l	4(sp),sp		; Take parameters off the stack
		move.b	#1,KFlag
.already_installed
		ret



;-------------------------------------------------------------------------
; Restore the system interrupt handler 
;-------------------------------------------------------------------------

		PROC	RestoreKeybd
		USES	d2-d7/a2-a6

		cmp.b	#1,KFlag
		bne.s	.not_installed

;;; Make sure none of the keys are still pressed when we restore the keyboard vector


.loop		moveq	#0,d0
		lea.l	_keypressed(pc),a0
		move.w	#128-1,d7
.check_key_loop
		cmp.b	#0,(a0)+
		beq.s	.key_not_pressed
		add.b	#1,d0
.key_not_pressed
		dbra	d7,.check_key_loop
		tst.b	d0
		bne.b	.loop

;;; Now that none of them are pressed we can restore the vector

		move.l	4.w,a6
		lea	KEYInt(pc),a1
		moveq	#INTB_PORTS,d0
		jsr	_LVORemIntServer(a6)

		move.b	#0,KFlag
.not_installed
		ret

;-------------------------------------------------------------------------
; Keyboard interrupt 
;-------------------------------------------------------------------------


key_interrupt:
		movem.l	d0-d7/a0-a6,-(sp)

;		move.w	INTREQR,d0
;		btst	#3,d0
;		beq	.not_key

		move.b	$bfdd00,d0
		btst	#0,d0
		bne	.key_cont
;		move.b	$bfed01,d0
;		btst	#0,d0
;		bne	.key_cont
	
;		btst	#3,d0
;		beq	.key_cont

		move.b	$bfec01,d0
		clr.b	$bfec01

		tst.b	d0
		beq	.key_cont

;		bset	#6,$bfee01
;		move.b	#$f0,$bfe401
;		move.b	#$00,$bfe501
;		bset	#0,$bfee01


		not.b	d0
		ror.b	#1,d0
		lea.l	_keypressed(pc),a0
		tst.b	d0
		bmi.b	.key_up
		and.w	#$7f,d0
		add.w	#1,d0
		move.b	#$ff,(a0,d0.w)
		move.b	d0,_keycode

		bra.b	.key_cont2
.key_up:
		and.w	#$7f,d0
		add.w	#1,d0
		move.b	#$00,(a0,d0.w)

.key_cont2
;		btst	#0,$bfed01
;		beq	.key_cont2
;		move.b	#%00000000,$bfee01
;		move.b	#%10001000,$bfed01

;alt keys should not be independent so overlay ralt on lalt

		
.key_cont

;		move.w	#$0008,INTREQ
.not_key:	;lea.l	$dff000,a5

;		lea.l	_keypressed(pc),a0
;		move.b	101(a0),d0	;read LALT
;		or.b	102(a0),d0	;blend it with RALT
;		move.b	d0,127(a0)	;save in combined position

		movem.l	(sp)+,d0-d7/a0-a6

		rts

KFlag
	dc.b	0,0

	cnop	0,4
KEYInt
	dc.l	0,0
	dc.b	NT_INTERRUPT,127		; type,priority
	dc.l	KEYIntName
	dc.l	0
	dc.l	key_interrupt

KEYIntName
	dc.b	'KeyInt',0
	even

	xdef	_keyptr
_keyptr
	dc.l	_keycode

_keypressed	DS.B	128
_keycode	DC.B	$ff
old_keyboard	DS.L	1

_scan_2_ascii
	DC.B	" `1234567890-=\ 0qwertyuiop[] 123asdfghjkl;#  456 zxcvbnm,./ .789 "
_shift_scan_2_ascii
	DC.B	" ~! £$%^&*()_+| 0QWERTYUIOP{} 123ASDFGHJKL:@  456 ZXCVBNM<>? .789 "
_caps_scan_2_ascii
	DC.B	" `1234567890-=\ 0QWERTYUIOP[] 123ASDFGHJKL;#  456 ZXCVBNM,./ .789 "

		END