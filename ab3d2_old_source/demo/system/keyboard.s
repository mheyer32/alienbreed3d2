*************************************************************************
* Non OS readkeyboard routine by Equalizer/TBL (Hints from Sag) 	*
* With:	- keymap translation (Raw to ASCII, Keyboard definer in AMOS)	*
*	- keyboard buffering (255 chars)				*
*	- keyboard repetition						*
*************************************************************************

key_shift	=	$01
key_ctrl	=	$02
key_alt		=	$04
key_lamiga	=	$08
key_ramiga	=	$10

;------------------------------------------------------- KeyBoard interrupts --

key_kbdlevel3:;------------------------------------- Level 3 (VBL) interrupt --
		tst.b	key_keypressed
		beq.s	.rts
		move.w	key_repttimerw,d0
		bne.s	.wait
		move.w	key_repttimers,d0
		bne.s	.waitspeed
		move.w	key_reptspeed,key_repttimers
		move.w	key_asciikey,d0
		bsr.w	key_insertkey
		bra.s	.rts
.waitspeed:	subq.w	#1,d0
		move.w	d0,key_repttimers
		bra.s	.rts
.wait:		subq.w	#1,d0
		move.w	d0,key_repttimerw
.rts:		rts

key_kbdlevel2:
	
		btst	#3,$bfed01
		beq	.quit
		move.b	$bfec01,d0
		move.b	d0,key_realraw
		move.b	#0,key_keypressed
		move.w	key_reptwait,key_repttimerw
		move.w	key_reptspeed,key_repttimers

		not.b d0
		ror.b #1,d0
		tst.b d0
		bmi.s	.skippa
		move.b	#1,key_keypressed
.skippa:	
		and.w	#$7f,d0
		move.b	d0,key_rawkey
		
		tst.b key_keypressed
		sne	 d1
		lea KeyMap,a0
		move.b d1,(a0,d0.w)
		
		
.skip:		lea	key_flagcodes,a0
		moveq.l	#7,d1		
.cloop:		cmp.b	(a0)+,d0
		bne.s	.noflagset
		bset.b	d1,key_realflags		; Set flag bit
.noflagset:	cmp.b	8-1(a0),d0
		bne.s	.noflagsclr
		bclr.b	d1,key_realflags		; Clear flag bit
.noflagsclr:	dbra	d1,.cloop
.noflag:	lea	$dff006,a6
		bsr	.waitrow
		bset	#6,$bfee01
		bsr	.waitrow
		move.b	#0,$bfec01
		bsr	.waitrow
		bclr	#6,$bfee01
		bsr	.waitrow
;-------------------------------------------------------- Raw to asciibuffer --
		moveq.l	#0,d3
		move.b	key_rawkey,d3
		cmp.w	#128,d3
		bge.w	.exit			; Strange rawcode?
		cmp.w	#0,d3
		beq.w	.exit
		moveq.l	#0,d1			; Flags.
		moveq.l	#0,d2
		move.b	key_realflags,d2	; KeyB Flags
		btst	#0,d2			; Caps
		beq.s	.skip0
		or.b	#$1,d1
.skip0:		btst	#1,d2			; Ctrl
		beq.s	.skip1
		or.b	#$2,d1
.skip1:		btst	#2,d2			; LShift
		beq.s	.skip2
		or.b	#$1,d1
.skip2:		btst	#3,d2			; LAlt
		beq.s	.skip3
		or.b	#$4,d1			
.skip3:		btst	#4,d2			; LAmiga
		beq.s	.skip4
		or.b	#$8,d1			
.skip4:		btst	#5,d2			; RAmiga
		beq.s	.skip5
		or.b	#$10,d1			
.skip5:		btst	#6,d2			; RAlt
		beq.s	.skip6
		or.b	#$4,d1			
.skip6:		btst	#7,d2			; RShift
		beq.s	.skip7
		or.b	#$1,d1			
.skip7:		move.b	d1,key_flags
		lsl.w	#7,d1
		add.w	d3,d1
		lsl.l	#1,d1
		add.l	key_keymapptr,d1
		move.l	key_keymapptr,d7
		bne.s	.qqq
		add.l	#key_keydefault,d1
.qqq:		move.l	d1,a1
		move.w	(a1),d2
		move.w	d2,key_asciikey
		move.w	d2,d0
		bsr.w	key_insertkey
.exit:		move.l	key_customptr,d0
		beq.s	.quit
		move.l	d0,a0
		jsr	(a0)
.quit:
		move.w #0,d0
		tst.w d0
		rts
.waitrow:	move.b	(a6),d0
		addq.w	#2,d0
.loop:		cmp.b	(a6),d0
		bne.s	.loop
 		rts
;----------------------------------------------------- Ascii buffer routines --

*************************************************************************
key_setascii:	; Changes an ascii value for a special RAW code		*
*		in:	d0.w,d1.w,d2.w=Raw value,Flags,New ASCII	*
*************************************************************************
		move.l	key_keymapptr,d3
		bne.s	.skip
		move.l	#key_keydefault,d3
.skip:		move.l	d3,a0
		and.l	#$1f,d1
		lsl.w	#7,d1
		add.w	d0,d1
		lsl.l	#1,d1
		and.w	#$ff,d2
		move.w	d2,(a0,d1.l)
		rts

*************************************************************************
key_setmacro:; 	Sets a macro for a special RAW code			*
*		in:	d0.w,d1.w,d2.l=Raw value,Flags,String ptr 	*
*************************************************************************
		move.l	key_keymapptr,d3
		bne.s	.skip
		move.l	#key_keydefault,d3
.skip:		move.l	d3,a0
		and.l	#$1f,d1
		lsl.w	#7,d1
		add.w	d0,d1
		move.w	d1,d3
		or.w	#$8000,d3
		lsl.l	#1,d1
		move.w	d3,(a0,d1.l)
		lsl.l	#1,d1
		move.l	key_macroptr,d3
		beq.s	.skip1
		move.l	d3,a0
		move.l	d2,(a0,d1.l)
.skip1:		rts

*************************************************************************
key_setcode:; 	Sets a code for a special RAW code			*
*		in:	d0.w,d1.w,d2.l=Raw value,Flags,Code ptr 	*
*************************************************************************
		or.l	#$80000000,d2		; Special codeptr
		bra.s	key_setmacro


*************************************************************************
key_insertkey:	;Inserts an ASCII-code into the keyboard buffer		*
*		in:	d0=ASCII-code					*
*************************************************************************
		move.w	d0,d2
.inkey:		lea	key_buffer,a0
		moveq.l	#0,d0
		moveq.l	#0,d1
		move.b	(a0)+,d0		; d0=head ptr
		move.b	(a0)+,d1		; d1=tail ptr
		addq.w	#2,d0
		andi.w	#$ff,d0
		cmp.w	d0,d1			; head=tail=full !!
		beq.w	.exit
		subq.w	#1,d0
		andi.w	#$ff,d0
		move.b	d0,-2(a0)		; Save new head
		lsl.w	#1,d0
		move.w	d2,(a0,d0.w)
.exit:		rts

*************************************************************************
key_readkey:	; Reads an ASCII-code form keyboard buffer		*
*		Out:	d0=ASCII-code	(0=No key)			*
*************************************************************************
		movem.l	d1-a6,-(a7)
.next:		moveq.l	#0,d0	
		tst.b	key_macroread
		bne.s	.domacro
		lea	key_buffer,a0
		move.b	(a0)+,d1
		move.b	(a0)+,d2
		cmp.b	d1,d2
		beq.s	.rts			; Equal=Empty
		addq.w	#1,d2
		and.w	#$ff,d2
		move.b	d2,-1(a0)
		lsl.w	#1,d2
		move.w	(a0,d2.w),d0
		move.w	d0,d2
		and.w	#$3fff,d0
		lsr.w	#8,d2
		lsr.w	#6,d2
		cmp.w	#%10,d2		
		beq.s	.fixmacro
		and.w	#$ff,d0
.rts:		movem.l	(a7)+,d1-a6
		rts
.fixmacro:	move.w	d0,d2
		and.l	#$3fff,d2
		move.l	key_macroptr,d1
		beq.s	.skipmacall
		lsl.l	#2,d2
		move.l	d1,a0
		move.l	(a0,d2.l),d1
		beq.s	.rts
		btst	#31,d1
		bne.s	.codemacro
		move.l	d1,key_macropos
.domacro:	move.l	key_macropos,a0
		clr.b	key_macroread
		moveq.l	#0,d0
		move.b	(a0)+,d0
		beq.w	.next
		st.b	key_macroread
		move.l	a0,key_macropos
		bra.s	.rts
.codemacro:	and.l	#$7fffffff,d1
		move.l	d1,a5
		movem.l	d0-a6,-(a7)
		jsr	(a5)
		movem.l	(a7)+,d0-a6
.skipmacall:	bra.w	.next

*************************************************************************
key_flushbuffer:	; Clears keyboard buffer			*
*************************************************************************
		move.b	key_buffer,key_buffer+1	
		rts

*****************************************************************
* RAW-Code for some special function keys.			*
*	help    $5f						*
*	up      $4c						*
*	down    $4d						*
*	left    $4f						*
*	right   $4e						*
*	return  $44						*
*	space   $40						*
*	esc     $45						*
*	enter   $43						*
*	tab     $42						*
*****************************************************************

;----------------------------------------------------------- Keyboard data --

; MH uncommented these two functions
key_kbdinit:	move.l	main_vbrbase,a0
		move.l	$68(a0),key_oldlevel2
		move.l	#key_kbdlevel2,$68(a0)
		move.w	#$8008,$dff09a
		rts
;
key_kbdexit:	move.l	main_vbrbase,a0
		move.l	key_oldlevel2,$68(a0)
		move.w	#$0008,$dff09a
		rts

key_oldlevel2:	dc.l	0		; For saving level 2
key_reptwait:	dc.w	10		; VBL's until rept
key_reptspeed:	dc.w	0		; Rept speed
key_repttimerw:	dc.w	0		; Timer for rept wait
key_repttimers:	dc.w	0		; Timer for rept speed
key_flagcodes:	dc.b	$61,$65,$67,$66,$64,$60,$63,$62
		dc.b	$e1,$e5,$e7,$e6,$e4,$e0,$e3,$e2
key_realflags:	dc.b	0		; Cps,Ctl,LSh,LAlt,LAm,RAm,RAlt,RSh
key_flags:	dc.b	0
key_realraw:	dc.b	0		; Input real raw
key_rawkey:	dc.b	0		; The raw value of the keypress
key_keypressed:	dc.b	0		; Keypressed flag, 0=Not pressed
key_macroread:	dc.b	0		; Read from macro buffer flag.
key_macropos:	dc.l	0		; Macro read pos
key_asciikey:	dc.w	0		; Last ascii code
key_customptr:	dc.l	0		; Custom routine on every key event
key_keymapptr:	dc.l	0		; Ptr to keymap (0=Default)
key_macroptr:	dc.l	0		; Ptr to macro list (0=No macros)
key_keydefault:	dc.l	$00600031,$00320033,$00340035,$00360037
		dc.l	$00380039,$0030002b,$0027005c,$00000030
		dc.l	$00710077,$00650072,$00740079,$00750069
		dc.l	$006f0070,$00e500a8,$00000031,$00320033
		dc.l	$00610073,$00640066,$00670068,$006a006b
		dc.l	$006c00f6,$00e40027,$00000034,$00350036
		dc.l	$003c007a,$00780063,$00760062,$006e006d
		dc.l	$002c002e,$002d0000,$002e0037,$00380039
		dc.l	$00200008,$0009000d,$000d001b,$007f0000
		dc.l	$00000000,$002d0000,$00800081,$00830082
		dc.l	$00000000,$00000000,$00000000,$00000000
		dc.l	$00000000,$005b005d,$002f002a,$002b00a0
		dc.l	$00000000,$00000000,$00000000,$00000000
		dc.l	$00000000,$00000000,$00000000,$00000000
		dc.l	$00000000,$00000000,$00000000,$00000000
		dc.l	$00000000,$00000000,$00000000,$00000000
		dc.l	$007e0021,$002200a3,$00240025,$0026002f
		dc.l	$00280029,$003d003f,$006000a6,$00000030
		dc.l	$00510057,$00450052,$00540059,$00550049
		dc.l	$004f0050,$00c2005e,$00000000,$00000000
		dc.l	$00410053,$00440046,$00470048,$004a004b
		dc.l	$004c00d6,$00c4002a,$00000000,$00000000
		dc.l	$003e005a,$00580043,$00560042,$004e004d
		dc.l	$003b003a,$005f0000,$002e0000,$00000000
		dc.l	$00200000,$00090000,$000d001b,$009e0000
		dc.l	$00000000,$002d0000,$00840085,$00870086
		dc.l	$00000000,$00000000,$00000000,$00000000
		dc.l	$00000000,$007b007d,$002f002a,$002b00a1
		dc.l	$00000000,$00000000,$00000000,$00000000
		dc.l	$00000000,$00000000,$00000000,$00000000
		dc.l	$00000000,$00000000,$00000000,$00000000
		dc.l	$00000000,$00000000,$00000000,$00000000
		dc.l	$00600031,$00320033,$00340035,$00360037
		dc.l	$00380039,$0030002b,$0027005c,$00000000
		dc.l	$00710077,$00650072,$00740079,$00750069
		dc.l	$006f0070,$00e500a8,$00000000,$00000000
		dc.l	$00610073,$00640066,$00670068,$006a006b
		dc.l	$006c00f6,$00e40027,$00000000,$00000000
		dc.l	$003c007a,$00780063,$00760062,$006e006d
		dc.l	$002c002e,$002d0000,$00000000,$00000000
		dc.l	$00000000,$00000000,$00000000,$00000000
		dc.l	$00000000,$00000000,$00880089,$008b008a
		dc.l	$00000000,$00000000,$00000000,$00000000
		dc.l	$00000000,$00000000,$00000000,$000000a2
		dc.l	$00000000,$00000000,$00000000,$00000000
		dc.l	$00000000,$00000000,$00000000,$00000000
		dc.l	$00000000,$00000000,$00000000,$00000000
		dc.l	$00000000,$00000000,$00000000,$00000000
		dc.l	$00000000,$00000000,$00000000,$00000000
		dc.l	$00000000,$00000000,$00000000,$00000000
		dc.l	$00000000,$00000000,$00000000,$00000000
		dc.l	$00000000,$00000000,$00000000,$00000000
		dc.l	$00000000,$00000000,$00000000,$00000000
		dc.l	$00000000,$00000000,$00000000,$00000000
		dc.l	$00000000,$00000000,$00000000,$00000000
		dc.l	$00000000,$00000000,$00000000,$00000000
		dc.l	$00000000,$00000000,$00000000,$00000000
		dc.l	$00000000,$00000000,$00000000,$00000000
		dc.l	$00000000,$00000000,$00000000,$00000000
		dc.l	$00000000,$00000000,$00000000,$00000000
		dc.l	$00000000,$00000000,$00000000,$00000000
		dc.l	$00000000,$00000000,$00000000,$00000000
		dc.l	$00000000,$00000000,$00000000,$00000000
		dc.l	$00000000,$00000000,$00000000,$00000000
		dc.l	$006000a1,$00b200b3,$00a40000,$00000000
		dc.l	$00000000,$000000bf,$003d0000,$00000000
		dc.l	$00710077,$00e900ae,$00740079,$00750069
		dc.l	$006f0070,$00e5005e,$00000000,$00000000
		dc.l	$00bc00bd,$00be0066,$00670068,$006a006b
		dc.l	$006c002c,$002700b7,$00000000,$00000000
		dc.l	$003e007a,$007800a9,$00760062,$006e006d
		dc.l	$00ab00bb,$002f0000,$00000000,$00000000
		dc.l	$00000000,$00000000,$000d0000,$009f0000
		dc.l	$00000000,$00000000,$00960097,$00990098
		dc.l	$00000000,$00000000,$00000000,$00000000
		dc.l	$00000000,$00000000,$00000000,$000000a3
		dc.l	$00000000,$00000000,$00000000,$00000000
		dc.l	$00000000,$00000000,$00000000,$00000000
		dc.l	$00000000,$00000000,$00000000,$00000000
		dc.l	$00000000,$00000000,$00000000,$00000000
		dc.l	$007e0021,$00400023,$00240025,$005e0026
		dc.l	$002a0028,$0029005f,$002b00a6,$00000000
		dc.l	$00000000,$00c90000,$00000000,$00000000
		dc.l	$00000000,$00c5005e,$00000000,$00000000
		dc.l	$00000000,$00000000,$00000000,$00000000
		dc.l	$0000003a,$0022002a,$00000000,$00000000
		dc.l	$003e0000,$00000000,$00000000,$00000000
		dc.l	$003c003e,$003f0000,$00000000,$00000000
		dc.l	$00000000,$00000000,$00000000,$009e0000
		dc.l	$00000000,$00000000,$009a009b,$009d009c
		dc.l	$00000000,$00000000,$00000000,$00000000
		dc.l	$00000000,$00000000,$00000000,$000000a4
		ds.b	6720

key_buffer:	dc.b	0,0		; Head & Tail ptr
		ds.w	256		; Buffer

