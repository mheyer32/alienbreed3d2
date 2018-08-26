main_sysinfooff
main_reqinfooff
main_endinfooff
main_disabledos
main_playeroff
main_meteroff

		include	"demo:System/Main_V3.82.S"
		
		

mnu_start:	

		bsr.w	mnu_saveframe
		bsr.w	mnu_copycredz
		bsr.w	mnu_setscreen
		move.l	a7,mnu_mainstack



		bsr.w	mnu_viewcredz
mnu_loop:	lea	mnu_mainmenu,a0
		bsr.w	mnu_domenu

		lea	mnu_quitmenu,a0
		bsr.w	mnu_domenu
		bra.w	mnu_loop

;		bsr.w	mnu_getrawvalue
;		move.l	d0,test

mnu_exit:	bsr.w	mnu_clearscreen
		rts

mnu_saveframe:	lea	mnu_frame,a0
		lea	mnu_savedcredz,a1
		move.l	#10*256*3-1,d0
.loop:		move.l	(a0)+,(a1)+
		dbra	d0,.loop		
		lea	mnu_frame+40*32+4,a0
		moveq.l	#8,d3
		moveq.l	#0,d0
		move.w	#191,d1
.loop1:		moveq.l	#7,d2
.loop2:		move.l	d0,(a0)+
		move.l	d0,40*256-4(a0)
		move.l	d0,40*2*256-4(a0)
		dbra	d2,.loop2
		add.l	d3,a0
		dbra	d1,.loop1
		rts

mnu_viewcredz:	clr.l	counter
		bsr.w	mnu_copycredz
.w8key:		bsr.w	key_readkey
		cmp.l	#50*10,counter
		beq.s	.exit
		tst.w	d0
		beq.s	.w8key
.exit:		rts

mnu_copycredz:	lea	mnu_savedcredz,a0
		lea	mnu_morescreen+40*256*3,a1
		move.w	#10*256-1,d0
.loop:		move.l	(a0)+,(a1)+
		move.l	40*256-4(a0),40*256-4(a1)
		move.l	2*40*256-4(a0),2*40*256-4(a1)
		dbra	d0,.loop		
		rts
		
mnu_clearscreen:bsr.w	mnu_fadeout
		clr.l	main_vblint
.loop1:		tst.w	mnu_bltbusy
		bne.s	.loop1
		bsr.w	key_kbdexit
		clr.l	main_bltint
		macro_sync
		move.w	#$7de0,$dff096
		rts

mnu_setscreen:	bsr.w	mnu_init
		macro_sync
		move.w	#$7de0,$dff096
		move.w	#$8200!%110000000,$dff096
		move.l	#mnu_copper,$dff080
		move.w	#0,$dff088
		bsr.w	key_kbdinit
		move.l	#mnu_vblint,main_vblint		
		bsr.w	mnu_fadein
		rts

mnu_vblint:	bsr.w	mnu_movescreen
		bsr.w	mnu_dofire
		bsr.w	key_kbdlevel3
		bsr.w	mnu_animcursor
		bsr.w	mnu_plot
		rts

mnu_init:	bsr.w	mnu_initrnd		; Uses palette buffer
		bsr.w	mnu_createpalette
		tst.w	.cp
		bne.s	.skipfs
		lea	mnu_screen,a0
		lea	mnu_screen+40*256,a1
		lea	mnu_screen+40*256*2,a2
		lea	mnu_screen+40*256*3,a3
		move.w	#40*256/4-1,d1
.fsloop:	move.l	(a1),d0
		move.l	d0,(a2)+
		move.l	d0,(a3)+
		move.l	(a0)+,(a1)+
		dbra	d1,.fsloop
.skipfs:	st.b	.cp
;-------------------------------------------------------------- Clear screen --
		lea	mnu_morescreen,a0
		move.l	#40*256*3/16-1,d0
		moveq.l	#0,d1
.clrloop:	
		REPT	4
		move.l	d1,(a0)+
		ENDR
		dbra	d0,.clrloop				
		bsr.w	mnu_cls
;--------------------------------------------------------------- Set bplptrs --
		lea	mnu_bplptrs+2,a0
		move.l	#mnu_screen,d0
		moveq.l	#0,d1
		bsr.w	.setbplptrs
		move.l	#mnu_screen+40*256*2,d0
		moveq.l	#0,d1
		bsr.w	.setbplptrs
		move.l	#mnu_morescreen,d0
		moveq.l	#5,d1
		bsr.s	.setbplptrs
;-------------------------------------------------------------- Init palette --
		lea	mnu_palette,a2
		moveq.l	#7,d0			; #of banks-1
		move.l	#$01060000,d6
		move.l	#$01060200,d7
		lea	mnu_colptrs,a0
		lea	mnu_colptrs+33*4,a1
.bankloop:	moveq.l	#31,d1			; d1=#of colour/bank
		move.l	d6,(a0)+
		move.l	d7,(a1)+
		move.w	#$0180,d5
.colloop:	;move.l	(a2)+,d2
		clr.l	d2
		move.l	d2,d3
		and.l	#$f0f0f0,d2
		lsr.l	#4,d2			; x0x0x
		lsl.b	#4,d2			; x0xx0
		lsl.w	#4,d2			; xxx00
		lsr.l	#8,d2			; 00xxx
		and.l	#$f0f0f,d3
		lsl.b	#4,d3			; x0xx0
		lsl.w	#4,d3			; xxx00
		lsr.l	#8,d3			; 00xxx
		move.w	d5,(a0)+
		move.w	d2,(a0)+
		move.w	d5,(a1)+
		move.w	d3,(a1)+
		addq.w	#2,d5
		dbra	d1,.colloop
		add.l	#33*4,a0
		add.l	#33*4,a1
		add.l	#$2000,d6
		add.l	#$2000,d7
		dbra	d0,.bankloop
		move.l	#-2,(a0)
		rts
.setbplptrs:	swap.w	d0
		move.w	d0,(a0)
		swap.w	d0
		move.w	d0,4(a0)
		addq.l	#8,a0
		add.l	#40*256,d0
		dbra	d1,.setbplptrs
		rts
.cp:		dc.w	0		

mnu_initrnd:	lea	mnu_palette+256,a1
		move.w	#255,d0
.parityloop:	move.b	d0,d1
		and.w	#$1,d1
		move.b	d0,d2
		lsr.w	#2,d2
		and.w	#$1,d2
		eor.w	d2,d1
		move.b	d0,d2
		lsr.w	#3,d2
		and.w	#$1,d2
		eor.w	d2,d1
		move.b	d0,d2
		lsr.w	#5,d2
		and.w	#$1,d2
		eor.w	d2,d1
		move.b	d1,-(a1)
		dbra	d0,.parityloop
		move.l	a1,a4			; a4=Parity buffer
		move.l	#'TBL!',d3		; Random seed
		lea	mnu_morescreen+6*40*256,a0
		move.w	#40*256+8192-1,d0
.loop:		moveq.l	#0,d1		; d1=0
		move.l	d3,d2		; d2=Random seed
		move.b	d2,d1		
		and.b	#$fe,d2
		move.b	(a4,d1.l),d1
		or.b	d1,d2
		ror.w	#1,d2
		swap.w	d2
		move.b	d2,d1		
		and.b	#$fe,d2
		move.b	(a4,d1.l),d1
		or.b	d1,d2
		ror.w	#1,d2
		move.l	d2,d3
		move.w	d2,d1
		lsr.w	#8,d1
		or.w	d1,d2
		move.l	d2,d1
		swap.w	d1
		or.w	d1,d2
		move.b	d2,(a0)+
		dbra	d0,.loop
		rts

mnu_movescreen:	move.w	mnu_screenpos,d0
		and.w	#$ff,d0
		mulu	#40,d0
		add.l	#mnu_screen,d0
		lea	mnu_bplptrs+2,a0
		moveq.l	#1,d1
.loop:		swap.w	d0
		move.w	d0,(a0)
		swap.w	d0
		move.w	d0,4(a0)
		addq.l	#8,a0
		add.l	#40*256*2,d0
		dbra	d1,.loop
		subq.w	#1,mnu_screenpos
		rts

mnu_createpalette:
		lea	mnu_backpal,a0
		lea	mnu_firepal,a1
		lea	mnu_fontpal,a2
		lea	mnu_palette+256*4,a3
		move.w	#255,d0
.loop:		move.w	d0,d1
		and.w	#$e0,d1		
		beq.s	.next
		lsr.w	#5,d1
		move.l	(a2,d1.w*4),-(a3)
		bra.s	.cont
.next:		move.w	d0,d1
		and.w	#$1c,d1	
		beq.s	.next1
		lsr.w	#2,d1
		move.l	(a1,d1.w*4),-(a3)
		bra.s	.cont
.next1:		move.w	d0,d1
		and.w	#$3,d1
		move.l	(a0,d1.w*4),-(a3)
.cont:		dbra	d0,.loop
		rts	


mnu_fadespeed	=	16

mnu_fadein:	clr.w	mnu_fadefactor
		moveq.l	#256/mnu_fadespeed-1,d0
.loop:		move.l	d0,-(a7)
.wsync:		cmp.b	#$80,$dff006
		blt.s	.wsync
		cmp.b	#$90,$dff006
		bgt.s	.wsync
		bsr.w	mnu_fade
.wsync2:	cmp.b	#$a0,$dff006
		blt.s	.wsync2
		add.w	#mnu_fadespeed,mnu_fadefactor
		move.l	(a7)+,d0
		dbra	d0,.loop
		move.w	#255,mnu_fadefactor
.wsync3:	cmp.b	#$80,$dff006
		blt.s	.wsync3
		cmp.b	#$90,$dff006
		bgt.s	.wsync3
		bsr.w	mnu_fade
		rts

mnu_fadeout:	move.w	#255,mnu_fadefactor
		moveq.l	#256/mnu_fadespeed-1,d0
.loop:		move.l	d0,-(a7)
		bsr.w	mnu_docursor
.wsync:		cmp.b	#$80,$dff006
		blt.s	.wsync
		cmp.b	#$90,$dff006
		bgt.s	.wsync
		bsr.w	mnu_fade
.wsync2:	cmp.b	#$a0,$dff006
		blt.s	.wsync2
		sub.w	#mnu_fadespeed,mnu_fadefactor
		move.l	(a7)+,d0
		dbra	d0,.loop
		clr.w	mnu_fadefactor
.wsync3:	cmp.b	#$80,$dff006
		blt.s	.wsync3
		cmp.b	#$90,$dff006
		bgt.s	.wsync3
		bsr.w	mnu_fade
		rts

mnu_fadefactor:	dc.w	0

mnu_fade:	lea	mnu_palette,a2
		moveq.l	#7,d0
		lea	mnu_colptrs+2,a0
		lea	mnu_colptrs+2+33*4,a1
		move.w	mnu_fadefactor,d7
		move.l	#$f0f0f0,d5
		move.l	#$ff,d6
.bankloop:	moveq.l	#31,d1
		addq.l	#4,a0
		addq.l	#4,a1
.colloop:	moveq.l	#0,d4
		move.l	(a2)+,d2

	REPT	2
		move.l	d2,d3
		and.w	d6,d3
		mulu	d7,d3
		divu	d6,d3
		move.b	d3,d4
		ror.l	#8,d4
		ror.l	#8,d2
	ENDR
		move.l	d2,d3
		and.w	d6,d3
		mulu	d7,d3
		divu	d6,d3
		move.b	d3,d4
		ror.l	#8,d4
		ror.l	#8,d4
		move.l	d4,d3
		and.l	d5,d3
		lsr.l	#4,d3			; x0x0x
		lsl.b	#4,d3			; x0xx0
		lsl.w	#4,d3			; xxx00
		lsr.l	#8,d3			; 00xxx
		and.l	#$f0f0f,d4
		move.w	d3,(a0)
		lsl.b	#4,d4			; x0xx0
		lsl.w	#4,d4			; xxx00
		lsr.l	#8,d4			; 00xxx
		addq.l	#4,a0
		move.w	d4,(a1)
		addq.l	#4,a1
		dbra	d1,.colloop
		add.l	#33*4,a0
		add.l	#33*4,a1
		dbra	d0,.bankloop
		rts




mnu_printxy:;in:a0,d0,d1=Text ptr,XPos,YPos	(XPos in words YPos in pixels)
		lea	mnu_font,a3
		lea	mnu_font+176*40,a4
		lea	mnu_font+176*40*2,a5
		moveq.l	#40,d7
		moveq.l	#20,d6
		move.l	#40*16,d5
		mulu	d7,d1
		add.w	d0,d1
		add.l	#mnu_morescreen+40*256*3,d1
		move.l	d1,a1			; a1=Ptr
		move.l	a1,a2
.loop:		move.b	(a0)+,d2
		beq.s	.exit
		move.l	mnu_printdelay,timer
.w8a:		tst.l	timer
		bne.s	.w8a
		and.l	#$ff,d2
		sub.w	#32,d2
		bge.s	.ok
		move.l	a2,a1
		add.l	#20*40,a1
		move.l	a1,a2
		bra.s	.loop
.ok:		divu	d6,d2
		move.w	d2,d3		; d3=Y
		swap.w	d2		; d2=X
		mulu	d5,d3		; d3=Y Addy
		lsl.w	#1,d2
		add.w	d2,d3		; d3=Addy Offset
		move.l	a1,a6
		moveq.l	#15,d2
.yloop:		move.w	(a3,d3.l),(a6)
		move.w	(a4,d3.l),40*256(a6)
		move.w	(a5,d3.l),40*256*2(a6)
		add.l	d7,d3
		add.l	d7,a6
		dbra	d2,.yloop
		addq.l	#2,a1
		bra.s	.loop
.exit:		rts

mnu_dofire:	btst.b	#0,main_counter+3
		beq.s	.skip
		rts
.skip:		move.l	#mnu_bltint,main_bltint
		move.w	$dff006,d0
		add.w	d0,mnu_rnd
		tst.b	$dff002
.w8:		tst.w	mnu_bltbusy
		bne.s	.w8
		btst.b	#6,$dff002
		bne.s	.w8
		lea	mnu_sourceptrs,a0
		move.l	(a0),d0
		move.l	4(a0),(a0)
		move.l	8(a0),4(a0)
		move.l	d0,8(a0)
		lea	$dff000,a6
		st.b	mnu_bltbusy
		move.w	#$0040,$9c(a6)			; Clear BLT req
		move.w	#$8040,$9a(a6)			; Enable BLT int
		move.w	#$8200!%1000000,$96(a6)		; Enable blitter dma
		bsr.w	mnu_bltint
		rts

mnu_bltint:	bsr.w	.getrnd
		lea	$dff000,a6
		move.l	.passptr,a0
		move.l	(a0),d0
		beq.s	.last
		addq.l	#4,.passptr
		move.l	d0,a0
		jmp	(a0)
.last:		move.w	#$0040,$9a(a6)			; Disable BLT int
		move.w	#%1000000,$96(a6)		; Disable blitter dma
		move.l	#.passlist,.passptr
		clr.w	mnu_bltbusy
		rts
.getrnd:	moveq.l	#0,d0
		move.w	mnu_rnd,d0
		and.l	#8190,d0
		add.l	#mnu_morescreen+6*40*256,d0
		move.l	d0,mnu_rndptr
		addq.w	#5,mnu_rnd
		rts
.rnd:		dc.w	0
.passptr:	dc.l	.passlist
.passlist:	dc.l	mnu_pass1
		dc.l	mnu_pass2
		dc.l	mnu_pass3
		dc.l	0

mnu_rnd:	dc.w	0
mnu_bltbusy:	dc.w	0

mnu_speed	=	1
mnu_size	=	256

mnu_subtract:	dc.l	0
mnu_count:	dc.w	0

mnu_pass1:	clr.l	mnu_subtract
		move.w	mnu_count,d0
		addq.w	#1,mnu_count
		and.w	#$3,d0
		beq.s	.l1
		cmp.w	#1,d0
		bne.s	.normal
		move.l	#-2,mnu_subtract
		move.l	#$fff80000,$40(a6)		; D=A+BC
		bra.s	.cont
.l1:		move.l	#$1ff80000,$40(a6)		; D=A+BC
		bra.s	.cont
.normal:	move.l	#$0ff80000,$40(a6)		; D=A+BC
.cont:		move.l	#$ffffffff,$44(a6)		; Masks A
		move.l	#$00000000,$60(a6)		; CB modulo
		move.l	#$00000000,$64(a6)		; AD modulo
		move.l	#mnu_morescreen+mnu_speed*40,$48(a6) ; Source C
		move.l	mnu_rndptr,$4c(a6)		; Source B
		move.l	mnu_sourceptrs,d0
		sub.l	mnu_subtract,d0
		move.l	d0,$50(a6)			; Source A
		move.l	#mnu_morescreen,$54(a6)		; Dest D
		move.w	#(mnu_size-mnu_speed)*64+20,$58(a6)	; Size and trigger
		rts

mnu_pass2:;	move.l	#$0ff80000,$40(a6)		; D=A+BC
;		move.l	#$ffffffff,$44(a6)		; Masks A
;		move.l	#$00000000,$60(a6)		; CB modulo
;		move.l	#$00000000,$64(a6)		; AD modulo
		move.l	#mnu_morescreen+40*256+mnu_speed*40,$48(a6) ; Source C
		move.l	mnu_rndptr,$4c(a6)		; Source B
		move.l	mnu_sourceptrs+4,d0
		sub.l	mnu_subtract,d0
		move.l	d0,$50(a6)			; Source A
		move.l	#mnu_morescreen+40*256,$54(a6)		; Dest D
		move.w	#(mnu_size-mnu_speed)*64+20,$58(a6)	; Size and trigger
		rts


mnu_pass3:;	move.l	#$0ff80000,$40(a6)		; D=A+BC
;		move.l	#$ffffffff,$44(a6)		; Masks A
;		move.l	#$00000000,$60(a6)		; CB modulo
;		move.l	#$00000000,$64(a6)		; AD modulo
		move.l	#mnu_morescreen+40*256*2+mnu_speed*40,$48(a6) ; Source C
		move.l	mnu_rndptr,$4c(a6)		; Source B
		move.l	mnu_sourceptrs+8,d0
		sub.l	mnu_subtract,d0
		move.l	d0,$50(a6)			; Source A
		move.l	#mnu_morescreen+40*256*2,$54(a6)		; Dest D
		move.w	#(mnu_size-mnu_speed)*64+20,$58(a6)	; Size and trigger
		rts
		
mnu_cls:	lea	mnu_frame+40*256*3,a0
		lea	mnu_morescreen+40*256*6,a1
		move.w	#40*256*3/16-1,d0
.loop:		
		REPT	4
		move.l	-(a0),-(a1)
		ENDR				
		dbra	d0,.loop
		rts

mnu_animcursor:	btst	#0,main_counter+3
		beq.s	.skip
		move.l	mnu_frameptr,a0
		move.b	(a0),mnu_arrow
		tst.b	1(a0)
		beq.s	.skip
		cmp.b	#40,1(a0)
		bhi.s	.ok
		moveq.l	#0,d0
		move.b	1(a0),d0
		sub.l	d0,mnu_frameptr
.ok:		addq.l	#1,mnu_frameptr
.skip:		rts

mnu_domenu:;in:	a0=Menu ptr
		bsr.w	key_flushbuffer
.redraw:	move.l	a0,-(a7)
		bsr.w	mnu_openmenu		; Open new menu
		move.l	(a7)+,a0
.loop:		movem.l	a0,-(a7)
		bsr.w	mnu_update
		movem.l	(a7)+,a0
		move.l	a0,-(a7)
		bsr.w	mnu_waitmenu		; Wait for option
		move.l	(a7)+,a0
		moveq.l	#0,d2
		move.w	mnu_row,d2
		divu	14(a0),d2
		swap.w	d2
		move.w	d2,mnu_currentsel
		tst.l	d1
		beq.s	.ok
		cmp.w	#42,d1
		beq.w	.left
		cmp.w	#41,d1
		beq.w	.right
.ok:		cmp.w	#-1,d0			; Esc ???
		beq.w	.exit			; Yepp exit
		move.l	16(a0,d0.w*8),d1	; Get option type
		tst.l	d1			; 0=Do Nothing ???
		beq.s	.loop		
		cmp.l	#1,d1			; 1=Sub menu
		beq.w	.newmenu
		cmp.l	#2,d1			; 2=Exit sub
		beq.w	.exit
		cmp.l	#3,d1
		beq.w	.bsr
		cmp.l	#4,d1
		beq.w	.left
		cmp.l	#5,d1
		beq.w	.leftsl
		cmp.l	#6,d1
		beq.w	.jump
		cmp.l	#7,d1
		beq.w	.changemenu
		cmp.l	#8,d1
		beq.w	.doraw
		cmp.l	#9,d1
		beq.w	.doload
		cmp.l	#10,d1
		beq.w	.dosave
.wrong:		move.l	#mnu_errcursanim,mnu_frameptr
		bra.w	.loop			; Strange option ??? Loop
.dosave:	movem.l	d0-a6,-(a7)
		move.l	20(a0,d0.w*8),a0
		move.w	mnu_currentlevel,(a0)
		bsr.w	mnu_savelevel
		movem.l	(a7)+,d0-a6
	;	bra.w	.loop
	bra.w	.exit
.doload:	movem.l	d0-a6,-(a7)
		move.l	20(a0,d0.w*8),a0
		move.w	(a0),mnu_currentlevel
		bsr.w	mnu_loadlevel
		movem.l	(a7)+,d0-a6
	;bra.w	.loop
	bra.w	.exit
.doraw:		movem.l	d0-a6,-(a7)
		move.l	#mnu_buttonanim,mnu_frameptr
		move.l	20(a0,d0.w*8),a0
.rawloop:	move.l	a0,-(a7)
		bsr.w	mnu_getrawvalue
		move.l	(a7)+,a0
		cmp.w	(a0),d0
		beq.s	.rawcont
		cmp.w	#69,d0
		beq.s	.rawcont
		lea	mnu_rawkeys,a1
.tstraw:	move.w	(a1)+,d1
		cmp.w	#$ffff,d1
		beq.s	.rawok
		cmp.w	d0,d1
		bne.s	.tstraw
		move.l	#mnu_errbutanim,mnu_frameptr
		bra.s	.rawloop
.rawok:		move.w	d0,(a0)
.rawcont:	move.l	#mnu_cursanim,mnu_frameptr
		movem.l	(a7)+,d0-a6
		bra.w	.loop
.bsr:		movem.l	d0-a6,-(a7)
		move.l	20(a0,d0.w*8),a0
		jsr	(a0)
		movem.l	(a7)+,d0-a6
		bra.w	.redraw
.jump:		move.l	20(a0,d0.w*8),a0
		move.l	mnu_mainstack,a7
		jmp	(a0)
;---------------------------------------------------------------------------
.left:		move.l	16(a0,d0.w*8),d1
		cmp.l	#4,d1
		bne.s	.leftsl		
		move.l	20(a0,d0.w*8),a1
		move.l	10(a1),a2
		move.w	8(a1),d0
		add.w	d0,(a2)
		bra.w	.loop
.leftsl:	cmp.l	#5,d1
		bne.w	.wrong
		move.l	20(a0,d0.w*8),a1
		move.l	6(a1),a2
		addq.w	#1,(a2)
		bra.w	.loop		
.right:		move.l	16(a0,d0.w*8),d1
		cmp.l	#4,d1
		bne.s	.rightsl		
		move.l	20(a0,d0.w*8),a1
		move.l	10(a1),a2
		move.w	8(a1),d0
		sub.w	d0,(a2)
		bra.w	.loop
.rightsl:	cmp.l	#5,d1
		bne.w	.wrong
		move.l	20(a0,d0.w*8),a1
		move.l	6(a1),a2
		subq.w	#1,(a2)
		bra.w	.loop
;------------------------------------------------------------------ New menu --
.changemenu:	move.l	20(a0,d0.w*8),a0
		bra.w	.redraw
.newmenu:	move.l	a0,-(a7)
		move.l	20(a0,d0.w*8),a0	; Set new menu
		bsr.w	mnu_domenu
		move.l	(a7)+,a0
		bra.w	.redraw
.exit:		rts

mnu_openmenu:;in:a0=Ptr to menu
		bsr.w	key_flushbuffer
		move.w	mnu_currentlevel,d0
		add.w	#65,d0
		move.b	d0,mnu_mainleveltext
		move.l	a0,-(a7)
		move.l	#0,mnu_printdelay
		bsr.w	mnu_cls
		move.l	#35,timer
.w8a:		tst.l	timer
		bne.s	.w8a		
		move.l	(a7)+,a0
		move.l	a0,-(a7)
		move.w	(a0),d0
		move.w	2(a0),d1
		move.l	4(a0),a0
		bsr.w	mnu_printxy
		move.l	(a7)+,a0
		move.w	8(a0),mnu_curx
		move.w	10(a0),mnu_cury
		move.w	12(a0),mnu_spread
		move.w	14(a0),mnu_items
		move.w	14(a0),d0
		mulu	#3000,d0
		move.w	d0,mnu_row
		move.w	d0,mnu_oldrow
		bsr.w	mnu_update
		rts

mnu_waitmenu:;out:	d0=Selection number
;		move.l	#mnu_cursanim,mnu_frameptr
		clr.l	mnu_printdelay

.loop:		moveq.l	#0,d1
		move.w	mnu_oldrow,d1
		cmp.w	mnu_row,d1
		beq.s	.skip
;		move.l	#mnu_cursanim,mnu_frameptr
		divu	mnu_items,d1
		swap.w	d1
		mulu	mnu_spread,d1
		add.w	mnu_cury,d1
		move.w	mnu_curx,d0
		lea	mnu_cleararrow,a0
		bsr.w	mnu_printxy
.skip:

.w8key:		bsr.w	mnu_docursor
		bsr.w	key_readkey
		tst.w	d0
		beq.s	.w8key
		cmp.b	#27,d0
		beq.s	.exit
		cmp.b	#129,d0		; Down Arrow
		beq.s	.down
		cmp.b	#128,d0
		beq.s	.up
		cmp.b	#13,d0
		beq.s	.quit
		cmp.b	#32,d0
		beq.s	.quit
		cmp.b	#130,d0
		beq.s	.sliderr
		cmp.b	#131,d0
		beq.s	.sliderl
		move.l	#mnu_errcursanim,mnu_frameptr
		bra.w	.loop
.exit:		moveq.l	#-1,d0		; Esc key
		moveq.l	#0,d1
		rts
.sliderr:	moveq.l	#41,d1
		bra.s	.cpcont
.sliderl:	moveq.l	#42,d1
		bra.s	.cpcont
.quit:		moveq.l	#0,d1
.cpcont:	move.w	mnu_row,d0
		divu	mnu_items,d0
		swap.w	d0
		and.l	#$ffff,d0
		rts
.down:		addq.w	#1,mnu_row
		bra.w	.loop
.up:		subq.w	#1,mnu_row
		bra.w	.loop

mnu_docursor:	moveq.l	#0,d1
		move.w	mnu_row,d1
		move.w	d1,mnu_oldrow
		divu	mnu_items,d1
		swap.w	d1
		mulu	mnu_spread,d1
		add.w	mnu_cury,d1
		move.w	mnu_curx,d0
		lea	mnu_arrow,a0
		bsr.w	mnu_printxy
		rts

mnu_docursor1:	moveq.l	#0,d1
		move.w	mnu_row,d1
		divu	mnu_items,d1
		swap.w	d1
		mulu	mnu_spread,d1
		add.w	mnu_cury,d1
		move.w	mnu_curx,d0
		lea	mnu_arrow,a0
		bsr.w	mnu_printxy
		rts

mnu_update:;in: a0=Ptr to menu
		move.w	14(a0),d7
		subq.w	#1,d7
		move.w	10(a0),d1		; d1=YPos
		move.w	8(a0),d0
		move.l	a0,a1
		add.l	#16,a1
.itemloop:	move.l	(a1)+,d2
		cmp.l	#4,d2			; Slider ?
		beq.s	.doslider
		cmp.l	#5,d2			; Slider ?
		beq.s	.docycler
		cmp.l	#8,d2
		beq.s	.dorawkey
		cmp.l	#9,d2
		beq.s	.doloadlevel
		cmp.l	#10,d2
		beq.s	.doloadlevel
.continue:	add.w	12(a0),d1
		addq.l	#4,a1
		dbra	d7,.itemloop
		rts
.doslider:	movem.l	d0-a6,-(a7)
		move.l	(a1),a0			; a0=Slider ptr
		bsr.w	mnu_putslider	
		movem.l	(a7)+,d0-a6
		bra.s	.continue		
.docycler:	movem.l	d0-a6,-(a7)
		move.l	(a1),a0			; a0=Cycler ptr
		bsr.w	mnu_putcycler	
		movem.l	(a7)+,d0-a6
		bra.s	.continue
.dorawkey:	movem.l	d0-a6,-(a7)
		move.l	(a1),a0			; a0=Ptr to value
		move.w	(a0),d3
		add.w	#132,d3
		add.w	#2,d0
		move.b	d3,mnu_rawprint
		lea	mnu_rawprint,a0
		bsr.w	mnu_printxy
		movem.l	(a7)+,d0-a6
		bra.s	.continue
.doloadlevel:	movem.l	d0-a6,-(a7)
		move.l	(a1),a0
		move.w	(a0),d2			; d0=Level no
		add.w	#65,d2
		move.b	d2,mnu_levelno
		addq.w	#2,d0
		lea	mnu_leveltext,a0
		bsr.w	mnu_printxy
		movem.l	(a7)+,d0-a6
		bra.s	.continue

mnu_putslider:;in:	d0,d1,d7,a0=Xpos,Ypos,Spread,Slider ptr
		add.w	(a0),d0
		add.w	2(a0),d1
		move.w	d0,.xpos
		movem.l	d0-d1/a0,-(a7)
		lea	mnu_leftslider,a0
		bsr.w	mnu_printxy
		movem.l	(a7)+,d0-d1/a0
		addq.w	#2,d0
		move.w	6(a0),d2
		lsr.w	#4,d2
		tst.w	d2
		beq.s	.skip
		move.w	d2,d4
		movem.l	d0-d1/a0,-(a7)
		lea	mnu_sliderspace,a0
		move.l	a0,a1
		subq.w	#1,d2
.loop:		move.b	#59,(a1)+
		dbra	d2,.loop
		clr.b	(a1)
		bsr.w	mnu_printxy
		movem.l	(a7)+,d0-d1/a0
		add.w	d4,d0
		add.w	d4,d0
.skip:		move.w	6(a0),d2
		and.w	#$f,d2
		beq.w	.skip2
		move.w	d2,d5
		subq.w	#1,d2
		moveq.l	#0,d3
.loop1:		ror.w	#1,d3
		or.w	#$8000,d3
		dbra	d2,.loop1
		movem.l	d0-d1,-(a7)
		mulu	d7,d1
		add.w	d0,d1
		add.l	#mnu_morescreen+40*256*3,d1
		move.l	d1,a4			; a4=Screen Ptr
		movem.l	(a7)+,d0-d1
		swap.w	d3
		clr.w	d3
		moveq.l	#15,d2
		move.l	a4,a5
		move.l	mnu_sliddat,a3
.loop2:		move.l	(a3),d4
		and.l	d3,d4
		move.l	d4,(a4)
		move.l	176*40(a3),d4
		and.l	d3,d4
		move.l	d4,40*256(a4)
		move.l	176*40*2(a3),d4
		and.l	d3,d4
		move.l	d4,40*256*2(a4)
		add.l	#40,a3
		add.l	#40,a4
		dbra	d2,.loop2
		move.l	a5,a4
		moveq.l	#15,d2
		move.l	mnu_sliddat,a3
.loop3:		move.l	2(a3),d4
		lsr.l	d5,d4
		or.l	d4,(a4)
		move.l	2+176*40(a3),d4
		lsr.l	d5,d4
		or.l	d4,40*256(a4)
		move.l	2+176*40*2(a3),d4
		lsr.l	d5,d4
		or.l	d4,40*256*2(a4)
		add.l	#40,a3
		add.l	#40,a4
		dbra	d2,.loop3
		bra.s	.cont1
.skip2:		movem.l	d0/d1/a0,-(a7)
		lea	mnu_rightslider,a0
		bsr.w	mnu_printxy
		movem.l	(a7)+,d0/d1/a0
.cont1:		move.l	10(a0),a1		; Value 2 change ptr
		move.w	(a1),d0
		cmp.w	#0,d0
		bge.s	.ok1
		moveq.l	#0,d0
.ok1:		cmp.w	4(a0),d0
		ble.s	.ok2
		move.w	4(a0),d0
.ok2:		move.w	d0,(a1)
		mulu	6(a0),d0
		divu	4(a0),d0		; d0=Slider position X
		sub.w	mnu_sliderwidth,d0
		move.w	.xpos,d2
		lsl.w	#3,d2
		add.w	d2,d0
		move.w	d0,d2
		and.l	#$f,d2
		lsr.w	#4,d0
		lsl.w	#1,d0
		addq.w	#2,d0
		and.l	#$ffff,d0
		mulu	d7,d1
		add.l	d0,d1
		add.l	#mnu_morescreen+40*256*3,d1
		move.l	d1,a4			; a1=Screen ptr
		moveq.l	#15,d3
		move.l	mnu_sliddat,a3
.loop4:		move.l	6(a3),d4
		lsr.l	d2,d4
		or.l	d4,(a4)
		move.l	6+176*40(a3),d4
		lsr.l	d2,d4
		or.l	d4,40*256(a4)
		move.l	6+176*40*2(a3),d4
		lsr.l	d2,d4
		or.l	d4,40*256*2(a4)
		add.l	#40,a3
		add.l	#40,a4
		dbra	d3,.loop4
		rts
.xpos:		dc.w	0

mnu_putcycler:;in:	d0,d1,a0=Xpos,Ypos,Spread,Cycler ptr
		add.w	(a0),d0
		add.w	2(a0),d1
		move.l	6(a0),a1
		moveq.l	#0,d2
		move.w	(a1),d2
		divu	4(a0),d2
		swap.w	d2
		move.w	d2,(a1)
		move.l	10(a0,d2.w*4),a0
		bsr.w	mnu_printxy
		rts

mnu_plot:	lea	mnu_sines,a0
		move.w	mnu_xsine0,d0
		and.w	#1022,d0
		move.w	(a0,d0.w),d1
		move.w	mnu_xsine1,d0
		and.w	#1022,d0
		add.w	(a0,d0.w),d1
		asr.w	#4,d1
		add.w	#160,d1
		move.w	mnu_ysine0,d0
		and.w	#1022,d0
		move.w	(a0,d0.w),d2
		move.w	mnu_ysine1,d0
		and.w	#1022,d0
		add.w	(a0,d0.w),d2
		asr.w	#4,d2
		add.w	#128,d2
		mulu	#40,d2
		move.w	d1,d0
		lsr.w	#3,d1
		add.w	d1,d2
		neg.w	d0
		addq.w	#$7,d0
		add.l	#mnu_morescreen,d2
		move.l	d2,a0
		bset.b	d0,(a0)
		bset.b	d0,40*256(a0)
		bset.b	d0,40*256*2(a0)
		addq.w	#3,mnu_xsine0
		subq.w	#4,mnu_xsine1
		addq.w	#5,mnu_ysine0
		subq.w	#2,mnu_ysine1
		rts

mnu_getrawvalue:;out:	d0=Raw value
		; Waits until a key is pressed the returns the raw value
		bsr.w	mnu_docursor1
		tst.b	key_keypressed
		bne.s	mnu_getrawvalue
.loop:		bsr.w	mnu_docursor1
		tst.b	key_keypressed
		beq.s	.loop
		move.b	key_rawkey,d0
		and.l	#$ff,d0
		move.l	d0,-(a7)
.oloop:		bsr.w	mnu_docursor1
		tst.b	key_keypressed
		bne.s	.oloop
		bsr.w	key_flushbuffer
		move.w	#$ffff,mnu_oldrow
		move.l	(a7)+,d0
		rts

mnu_test4quit:	clr.w	mnu_quitflag
		bsr.w	mnu_docursor
		bsr.w	key_readkey
		cmp.w	#27,d0
		beq.s	.quit
		cmp.w	#13,d0
		beq.s	.quit
		cmp.w	#32,d0
		beq.s	.quit
		tst.w	d0
		beq.s	.skip
		move.l	#mnu_errcursanim,mnu_frameptr
.skip:		moveq.l	#-1,d0
		tst.w	d0
		rts
.quit:		st.b	mnu_quitflag
		moveq.l	#0,d0
		tst.w	d0
		rts		

mnu_quitflag:	dc.w	0

mnu_playgame:	cmp.w	#1,mnu_playtype		; Is it 2 player master ???
		bne.w	.noplayermaster
		lea	mnu_2pmastermenu,a0
		bsr.w	mnu_domenu
		cmp.w	#1,mnu_currentsel
		bne.s	.rts
		bsr.w	mnu_cls
		lea	mnu_slavewaittext,a0
		moveq.l	#6,d0
		moveq.l	#60,d1
		bsr.w	mnu_printxy
		clr.w	mnu_spread
		move.w	#4,mnu_curx
		move.w	#140,mnu_cury
		bsr.w	mnu_wait4slave
		tst.w	mnu_quitflag
		beq.s	.playgame
.rts:		rts
.noplayermaster:cmp.w	#2,mnu_playtype
		bne.w	.playgame
		bsr.w	mnu_cls
		lea	mnu_masterwaittext,a0
		moveq.l	#6,d0
		moveq.l	#60,d1
		bsr.w	mnu_printxy
		clr.w	mnu_spread
		move.w	#4,mnu_curx
		move.w	#140,mnu_cury
		bsr.w	mnu_wait4master
		tst.w	mnu_quitflag
		beq.s	.playgame
		rts
.playgame:	bsr.w	mnu_clearscreen
		;-------------------------------------- Jump to game here !! --
		move.w	mnu_playtype,d0
		lea	.playtypeptr,a0
		move.l	(a0,d0.w*4),a0
		jsr	(a0)
		bsr.w	mnu_setscreen
		rts
.playtypeptr:	dc.l	mnu_play1p
		dc.l	mnu_play2pMaster
		dc.l	mnu_play2pSlave


*******************************************************************************
*******************************************************************************
*******************************************************************************
*******************************************************************************

mnu_wait4slave:	; Wait for the slave to connect.
.loop:		bsr.w	mnu_test4quit		; Check for "cancel" (and cursor)
		beq.s	.rts			; Cancel key was selected

;.............. Do your tests here .................................
;.............. if the slave connects just exit with a rts .........

	btst	#6,$bfe001
	bne.s	.loop
.loop1:	btst	#6,$bfe001
	beq.s	.loop1

.rts:		rts

*******************************************************************************

mnu_wait4master:; Wait for the master to connect.
.loop:		bsr.w	mnu_test4quit		; Check for "cancel" (and cursor)
		beq.s	.rts			; Cancel key was selected

;.............. Do your tests here ..................................
;.............. if the master connects just exit with a rts .........

	btst	#6,$bfe001
	bne.s	.loop
.loop1:	btst	#6,$bfe001
	beq.s	.loop1

.rts:		rts

*******************************************************************************

mnu_play1p:	; Do the 1 player game stuff here

.loop:	btst	#6,$bfe001
	bne.s	.loop

		rts

*******************************************************************************

mnu_play2pMaster:; Do the 2 player master game stuff here

.loop:	btst	#6,$bfe001
	bne.s	.loop

		rts

*******************************************************************************

mnu_play2pSlave:; Do the 2 player slave game stuff here

.loop:	btst	#6,$bfe001
	bne.s	.loop

		rts

*******************************************************************************

mnu_loadlevel:	; Level to load is in mnu_currentlevel.w
		; Current menu item is in mnu_currentsel.w (0 based)
		rts

*******************************************************************************

mnu_savelevel:	; Level to save is in mnu_currentlevel.w
	   	; Current menu item is in mnu_currentsel.w (0 based)
	      	; Or all saved levels in the mnu_levellist+n*2.w
		rts

*******************************************************************************

		include	"demo:System/KeyBoard.S"

****************************************************************** Variables **

mnu_2plevel:	dc.w	0
mnu_currentsel:	dc.w	0	; Containes the current menu item
mnu_currentlevel:
mnu_level:	dc.w	0	; Current level choosen. 0=A,1=B...

mnu_playtype:	dc.w	0	; Selected type of game. 0=1 player
				;			 1=2 player master
				;			 2=2 player slave
;------------------------------------------------- Rawcodes for control keys --
mnu_rawkeys:	;----------------------------- Here are all defined raw keys --
mnu_key00:	dc.w	$4f	; Turn left
mnu_key01:	dc.w	$4e	; Turn right
mnu_key02:	dc.w	$4c	; Forwards
mnu_key03:	dc.w	$4d	; Backwards
mnu_key04:	dc.w	101	; Fire
mnu_key05:	dc.w	$40	; Operate door
mnu_key06:	dc.w	97	; Run
mnu_key07:	dc.w	103	; Force sidestep
mnu_key08:	dc.w	57	; Sidestep left
mnu_key09:	dc.w	58	; Sidestep right
mnu_key10:	dc.w	34	; Duck
mnu_key11:	dc.w	40	; Look behind
mnu_key12:	dc.w	15	; Jump
mnu_key13:	dc.w	27	; Look up
mnu_key14:	dc.w	42	; Look down
mnu_key15:	dc.w	41	; Centre view
;------------------------------------------- Put other reserved keys here !! --
		dc.w	69	; Escape
		dc.w	1,2,3,4,5,6,7,8,9,10	; Weapon selects
		dc.w	80	; Zoom in on map
		dc.w	81	; Zoom out on map
		dc.w	82	; 4/8 Channel sound
		dc.w	83	; Mono/Stereo sound
		dc.w	84	; Recall message
		dc.w	85	; Render quality
		dc.w	29	; Map down left
		dc.w	30	; Map down
		dc.w	31	; Map down right
		dc.w	45	; Map left
		dc.w	46	; Center map
		dc.w	47	; Map right
		dc.w	61	; Map up left
		dc.w	62	; Map up
		dc.w	63	; Map up right
		dc.w	-1	; End list with -1

mnu_levellist:;----------------------------- Current levels in the save list --
mnu_saved0:	dc.w	0		; Level number for saved pos 0
mnu_saved1:	dc.w	1		
mnu_saved2:	dc.w	3
mnu_saved3:	dc.w	8
mnu_saved4:	dc.w	4
mnu_saved5:	dc.w	11

mnu_xsine0:	dc.w	0
mnu_xsine1:	dc.w	0
mnu_ysine0:	dc.w	0
mnu_ysine1:	dc.w	0

mnu_sines:
	dc.w	$0006,$0013,$001f,$002c,$0038,$0045,$0052,$005e,$006b,$0077
	dc.w	$0083,$0090,$009c,$00a9,$00b5,$00c1,$00ce,$00da,$00e6,$00f2
	dc.w	$00ff,$010b,$0117,$0123,$012f,$013b,$0147,$0153,$015f,$016a
	dc.w	$0176,$0182,$018d,$0199,$01a4,$01b0,$01bb,$01c6,$01d2,$01dd
	dc.w	$01e8,$01f3,$01fe,$0209,$0213,$021e,$0229,$0233,$023e,$0248
	dc.w	$0252,$025c,$0266,$0270,$027a,$0284,$028e,$0297,$02a1,$02aa
	dc.w	$02b4,$02bd,$02c6,$02cf,$02d8,$02e1,$02e9,$02f2,$02fa,$0303
	dc.w	$030b,$0313,$031b,$0323,$032a,$0332,$0339,$0341,$0348,$034f
	dc.w	$0356,$035d,$0364,$036a,$0371,$0377,$037d,$0383,$0389,$038f
	dc.w	$0395,$039a,$039f,$03a5,$03aa,$03af,$03b4,$03b8,$03bd,$03c1
	dc.w	$03c5,$03c9,$03cd,$03d1,$03d5,$03d8,$03dc,$03df,$03e2,$03e5
	dc.w	$03e7,$03ea,$03ed,$03ef,$03f1,$03f3,$03f5,$03f7,$03f8,$03f9
	dc.w	$03fb,$03fc,$03fd,$03fd,$03fe,$03ff,$03ff,$03ff,$03ff,$03ff
	dc.w	$03ff,$03fe,$03fd,$03fd,$03fc,$03fb,$03f9,$03f8,$03f7,$03f5
	dc.w	$03f3,$03f1,$03ef,$03ed,$03ea,$03e7,$03e5,$03e2,$03df,$03dc
	dc.w	$03d8,$03d5,$03d1,$03cd,$03c9,$03c5,$03c1,$03bd,$03b8,$03b4
	dc.w	$03af,$03aa,$03a5,$039f,$039a,$0395,$038f,$0389,$0383,$037d
	dc.w	$0377,$0371,$036a,$0364,$035d,$0356,$034f,$0348,$0341,$0339
	dc.w	$0332,$032a,$0323,$031b,$0313,$030b,$0303,$02fa,$02f2,$02e9
	dc.w	$02e1,$02d8,$02cf,$02c6,$02bd,$02b4,$02aa,$02a1,$0297,$028e
	dc.w	$0284,$027a,$0270,$0266,$025c,$0252,$0248,$023e,$0233,$0229
	dc.w	$021e,$0213,$0209,$01fe,$01f3,$01e8,$01dd,$01d2,$01c6,$01bb
	dc.w	$01b0,$01a4,$0199,$018d,$0182,$0176,$016a,$015f,$0153,$0147
	dc.w	$013b,$012f,$0123,$0117,$010b,$00ff,$00f2,$00e6,$00da,$00ce
	dc.w	$00c1,$00b5,$00a9,$009c,$0090,$0083,$0077,$006b,$005e,$0052
	dc.w	$0045,$0038,$002c,$001f,$0013,$0006,$fffa,$ffed,$ffe1,$ffd4
	dc.w	$ffc8,$ffbb,$ffae,$ffa2,$ff95,$ff89,$ff7d,$ff70,$ff64,$ff57
	dc.w	$ff4b,$ff3f,$ff32,$ff26,$ff1a,$ff0e,$ff01,$fef5,$fee9,$fedd
	dc.w	$fed1,$fec5,$feb9,$fead,$fea1,$fe96,$fe8a,$fe7e,$fe73,$fe67
	dc.w	$fe5c,$fe50,$fe45,$fe3a,$fe2e,$fe23,$fe18,$fe0d,$fe02,$fdf7
	dc.w	$fded,$fde2,$fdd7,$fdcd,$fdc2,$fdb8,$fdae,$fda4,$fd9a,$fd90
	dc.w	$fd86,$fd7c,$fd72,$fd69,$fd5f,$fd56,$fd4c,$fd43,$fd3a,$fd31
	dc.w	$fd28,$fd1f,$fd17,$fd0e,$fd06,$fcfd,$fcf5,$fced,$fce5,$fcdd
	dc.w	$fcd6,$fcce,$fcc7,$fcbf,$fcb8,$fcb1,$fcaa,$fca3,$fc9c,$fc96
	dc.w	$fc8f,$fc89,$fc83,$fc7d,$fc77,$fc71,$fc6b,$fc66,$fc61,$fc5b
	dc.w	$fc56,$fc51,$fc4c,$fc48,$fc43,$fc3f,$fc3b,$fc37,$fc33,$fc2f
	dc.w	$fc2b,$fc28,$fc24,$fc21,$fc1e,$fc1b,$fc18,$fc16,$fc13,$fc11
	dc.w	$fc0f,$fc0d,$fc0b,$fc09,$fc08,$fc07,$fc05,$fc04,$fc03,$fc03
	dc.w	$fc02,$fc01,$fc01,$fc01,$fc01,$fc01,$fc01,$fc02,$fc03,$fc03
	dc.w	$fc04,$fc05,$fc07,$fc08,$fc09,$fc0b,$fc0d,$fc0f,$fc11,$fc13
	dc.w	$fc16,$fc19,$fc1b,$fc1e,$fc21,$fc24,$fc28,$fc2b,$fc2f,$fc33
	dc.w	$fc37,$fc3b,$fc3f,$fc43,$fc48,$fc4c,$fc51,$fc56,$fc5b,$fc61
	dc.w	$fc66,$fc6b,$fc71,$fc77,$fc7d,$fc83,$fc89,$fc8f,$fc96,$fc9c
	dc.w	$fca3,$fcaa,$fcb1,$fcb8,$fcbf,$fcc7,$fcce,$fcd6,$fcdd,$fce5
	dc.w	$fced,$fcf5,$fcfd,$fd06,$fd0e,$fd17,$fd1f,$fd28,$fd31,$fd3a
	dc.w	$fd43,$fd4c,$fd56,$fd5f,$fd69,$fd72,$fd7c,$fd86,$fd90,$fd9a
	dc.w	$fda4,$fdae,$fdb8,$fdc2,$fdcd,$fdd7,$fde2,$fded,$fdf7,$fe02
	dc.w	$fe0d,$fe18,$fe23,$fe2e,$fe3a,$fe45,$fe50,$fe5c,$fe67,$fe73
	dc.w	$fe7e,$fe8a,$fe96,$fea1,$fead,$feb9,$fec5,$fed1,$fedd,$fee9
	dc.w	$fef5,$ff01,$ff0e,$ff1a,$ff26,$ff32,$ff3f,$ff4b,$ff57,$ff64
	dc.w	$ff70,$ff7d,$ff89,$ff95,$ffa2,$ffae,$ffbb,$ffc8,$ffd4,$ffe1
	dc.w	$ffed,$fffa

mnu_mainstack:	dc.l	0

;--------------------------------------------------------------- Slider data --

mnu_sliderwidth:dc.w	6
mnu_sliddat:	dc.l	mnu_font+40*16+7*2
mnu_leftslider:	dc.b	58,0
mnu_sliderspace:blk.b	20,0
mnu_rightslider:dc.b	60,0
mnu_rawprint:	dc.b	0,0
		even
;----------------------------------------------------------------- Menu data --

mnu_curx:	dc.w	5
mnu_cury:	dc.w	78
mnu_spread:	dc.w	40
mnu_items:	dc.w	3

mnu_arrow:	dc.b	' ',0
mnu_cleararrow:	dc.b	' ',0
mnu_row:	dc.w	30000
mnu_oldrow:	dc.w	30000
mnu_screenpos:	dc.w	0

mnu_printdelay:	dc.l	2

;----------------------------------------------------------------- Fire data --

mnu_rndptr:	dc.l	mnu_morescreen+6*40*256
mnu_sourceptrs:	dc.l	mnu_morescreen+3*40*256+mnu_speed*40
		dc.l	mnu_morescreen+4*40*256+mnu_speed*40
		dc.l	mnu_morescreen+5*40*256+mnu_speed*40

;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Menues %%

; Types:	0 = Do nothing
;		1 = Sub menu
;		2 = Exit sub menu
;		3 = Execute subroutine
;               4 = Slider
;               5 = Cycler
;		6 = Branch (SP) set to value in mnu_mainstack
;		7 = Change menu
;		8 = Get raw key
;		9 = Level Load
;              10 = Level Save

mnu_mainmenu:	dc.w	6,12			; X,Y
		dc.l	mnu_maintext		; Text ptr
		dc.w	4,70			; XCursor,YCursor
		dc.w	20			; Spread
		dc.w	7			; Items
		dc.l	5,mnu_playercycler	; Change player type
		dc.l	3,mnu_playgame
		dc.l	1,mnu_controlmenu0
		dc.l	3,mnu_viewcredz
		dc.l	1,mnu_loadmenu
		dc.l	1,mnu_savemenu
		dc.l	2,0			; 2=Exit sub menu (Esc)

mnu_controlmenu0:dc.w	6,32			; X,Y
		dc.l	mnu_controltext0	; Text ptr
		dc.w	4,50			; XCursor,YCursor
		dc.w	20			; Spread
		dc.w	9			; Items
		dc.l	8,mnu_key00
		dc.l	8,mnu_key01
		dc.l	8,mnu_key02
		dc.l	8,mnu_key03
		dc.l	8,mnu_key04
		dc.l	8,mnu_key05
		dc.l	8,mnu_key06
		dc.l	8,mnu_key07
		dc.l	7,mnu_controlmenu1

mnu_controlmenu1:dc.w	6,32			; X,Y
		dc.l	mnu_controltext1	; Text ptr
		dc.w	4,50			; XCursor,YCursor
		dc.w	20			; Spread
		dc.w	9			; Items
		dc.l	8,mnu_key08
		dc.l	8,mnu_key09
		dc.l	8,mnu_key10
		dc.l	8,mnu_key11
		dc.l	8,mnu_key12
		dc.l	8,mnu_key13
		dc.l	8,mnu_key14
		dc.l	8,mnu_key15
		dc.l	7,mnu_controlmenu2

mnu_controlmenu2:dc.w	4,12			; X,Y
		dc.l	mnu_controltext2	; Text ptr
		dc.w	4,210			; XCursor,YCursor
		dc.w	20			; Spread
		dc.w	1			; Items
		dc.l	7,mnu_controlmenu0

mnu_loadmenu:	dc.w	4,42
		dc.l	mnu_loadmenutext
		dc.w	4,80			; XCursor,YCursor
		dc.w	20			; Spread
		dc.w	7			; Items
		dc.l	9,mnu_saved0
		dc.l	9,mnu_saved1
		dc.l	9,mnu_saved2
		dc.l	9,mnu_saved3
		dc.l	9,mnu_saved4
		dc.l	9,mnu_saved5
		dc.l	2,0

mnu_savemenu:	dc.w	4,42
		dc.l	mnu_savemenutext
		dc.w	4,80			; XCursor,YCursor
		dc.w	20			; Spread
		dc.w	7			; Items
		dc.l	10,mnu_saved0
		dc.l	10,mnu_saved1
		dc.l	10,mnu_saved2
		dc.l	10,mnu_saved3
		dc.l	10,mnu_saved4
		dc.l	10,mnu_saved5
		dc.l	2,0

mnu_quitmenu:	dc.w	4,82
		dc.l	mnu_quitmenutext
		dc.w	4,120			; XCursor,YCursor
		dc.w	20			; Spread
		dc.w	2			; Items
		dc.l	6,mnu_loop
		dc.l	6,mnu_exit

mnu_2pmastermenu:
		dc.w	4,82
		dc.l	mnu_2pmastertext
		dc.w	4,120			; XCursor,YCursor
		dc.w	20			; Spread
		dc.w	3			; Items
		dc.l	5,mnu_levelcycler
		dc.l	2,0
		dc.l	2,0

;--------------------------------------------------------------------- Texts --
mnu_slavewaittext:
		dc.b	'Waiting for ',1
		dc.b	'your opponent',1
		dc.b	'to respond...',1,1
		dc.b	58,58,'Cancel',0

mnu_masterwaittext:
		dc.b	'Waiting for ',1
		dc.b	'your opponent',1
		dc.b	'to respond...',1,1
		dc.b	58,58,'Cancel',0

mnu_maintext:	dc.b	1,1
		dc.b	60,'Level '
mnu_mainleveltext:dc.b	'A',58,1		
		dc.b	1
		dc.b	'Play game',1
		dc.b	'Control options',1
		dc.b	'Game credits',1
		dc.b	'Load position',1
		dc.b	'Save position',1
'		dc.b	'Quit',1
		dc.b	0

mnu_quitmenutext:dc.b	' Quit game',131,131,131,1,1
		dc.b	' No,I',39,'m addicted',1
		dc.b	' Yes! Let me OUT',1
		dc.b	0

mnu_2pmastertext:dc.b	' 2 Player master',1,1
		dc.b	' Play level',1
		dc.b	' Start game',1
		dc.b	' ',58,58,'Cancel',1
		dc.b	0

mnu_loadmenutext:dc.b	' Load game',1,1
		dc.b	1,1,1,1,1,1
		dc.b	' ',58,58,'Cancel',58,58,0

mnu_savemenutext:dc.b	' Save game',1,1
		dc.b	1,1,1,1,1,1
		dc.b	' ',58,58,'Cancel',58,58,0
		
mnu_controltext0:dc.b	1
		dc.b	' Turn left',1
		dc.b	' Turn right',1
		dc.b	' Forwards',1
		dc.b	' Backwards',1
		dc.b	' Fire',1
		dc.b	' Operate door',1
		dc.b	' Run',1
		dc.b	' Sidestep',1
		dc.b	60,60,'More',60,60,1
		dc.b	0

mnu_controltext1:dc.b	1
		dc.b	' Sidestep left',1
		dc.b	' Sidestep right',1
		dc.b	' Duck',1
		dc.b	' Look behind',1
		dc.b	' Jump',1
		dc.b	' Look up',1
		dc.b	' Look down',1
		dc.b	' Centre view',1
		dc.b	60,60,'Others',60,60,1
		dc.b	0

mnu_controltext2:dc.b	1
		dc.b	157,'Pause',1
		dc.b	212,'Zoom in on map',1
		dc.b	213,'Zoom out on map',1
		dc.b	214,'4/8 Ch. sound',1
		dc.b	215,'Mono/Stereo snd',1
		dc.b	216,'Recall message',1
		dc.b	217,'Render quality',1
		dc.b	133,'-',142,'Select weapon',1
		dc.b	161,'-',195,'Scroll map',1
		dc.b	' ',58,58,'Back',58,58,1
		dc.b	0

mnu_leveltext:	dc.b	'Level '
mnu_levelno:	dc.b	'A',0

		even
;------------------------------------------------------- Cyclers and sliders --

mnu_level0:	dc.b	'A',0
mnu_level1:	dc.b	'B',0
mnu_level2:	dc.b	'C',0
mnu_level3:	dc.b	'D',0
mnu_level4:	dc.b	'E',0
mnu_level5:	dc.b	'F',0
mnu_level6:	dc.b	'G',0
mnu_level7:	dc.b	'H',0
mnu_level8:	dc.b	'I',0
mnu_level9:	dc.b	'J',0
mnu_level10:	dc.b	'K',0
mnu_level11:	dc.b	'L',0
mnu_level12:	dc.b	'M',0
mnu_level13:	dc.b	'N',0
mnu_level14:	dc.b	'O',0
mnu_level15:	dc.b	'P',0
		even

mnu_levelcycler:dc.w	24,2			; X,Y Add
		dc.w	16			; #of items
		dc.l	mnu_2plevel		; Value to effect
		dc.l	mnu_level0
		dc.l	mnu_level1
		dc.l	mnu_level2
		dc.l	mnu_level3
		dc.l	mnu_level4
		dc.l	mnu_level5
		dc.l	mnu_level6
		dc.l	mnu_level7
		dc.l	mnu_level8
		dc.l	mnu_level9
		dc.l	mnu_level10
		dc.l	mnu_level11
		dc.l	mnu_level12
		dc.l	mnu_level13
		dc.l	mnu_level14
		dc.l	mnu_level15
		even

mnu_playercycler:dc.w	2,2			; X,Y Add
		dc.w	3			; #of items
		dc.l	mnu_playtype		; Value to effect
		dc.l	mnu_playtype0
		dc.l	mnu_playtype1
		dc.l	mnu_playtype2
		even

mnu_playtype0:	dc.b	'1 Player       ',0
mnu_playtype1:	dc.b	'2 Player master',0
mnu_playtype2:	dc.b	'2 Player slave ',0

;----------------------------------------------------------------- Animation --
		
mnu_frameptr:	dc.l	mnu_cursanim

mnu_errcursanim:dc.b	240,240,241,241,242,242,243,243
		dc.b	240,240,241,241,242,242,243,243
		dc.b	240,240,241,241,242,242,243,243
		dc.b	240,240,241,241,242,242,243,243
mnu_cursanim:	dc.b	130,129,128,127,126,125,124,123,8
		even

mnu_errbutanim:	dc.b	240,240,241,241,242,242,243,243
		dc.b	240,240,241,241,242,242,243,243
		dc.b	240,240,241,241,242,242,243,243
		dc.b	240,240,241,241,242,242,243,243
mnu_buttonanim:	dc.b	236,236,236 ,236
		dc.b	237,237,237,237
		dc.b	238,238,238,238
		dc.b	239,239,239,239
		dc.b	238,238,238,238
		dc.b	237,237,237,237
		dc.b	24

		even
mnu_font:	incbin	"demo:Menu/Font16x16.Raw2"
mnu_fontpal:	incbin	"demo:Menu/Font16x16.Pal2"
mnu_firepal:	incbin	"Demo:Menu/FirePal.Pal2"
mnu_backpal:	incbin	"demo:Menu/Back.Pal"

mnu_palette:	blk.l	256

mnu_frame:	incbin	"demo:Menu/Credits.Raw"

		section	data_b,bss

mnu_savedcredz:	ds.b	40*256*3

		section	data_c,data_c

mnu_copper:	dc.l	$01000211,$01020000,$01040000
		dc.l	$0108fff8,$010afff8,$010c0000
		dc.l	$01fc0003
		dc.l	$008e2881,$009028c1,$00920038,$009400d0
mnu_bplptrs:	dc.l	$00e00000,$00e20000,$00e40000,$00e60000
		dc.l	$00e80000,$00ea0000,$00ec0000,$00ee0000
		dc.l	$00f00000,$00f20000,$00f40000,$00f60000
		dc.l	$00f80000,$00fa0000,$00fc0000,$00fe0000
mnu_colptrs:	blk.l	(32+1)*8*2+1
		cnop	64,64

mnu_screen:	incbin	"Demo:Menu/Back2.Raw"
		ds.b	40*256*2

mnu_morescreen:	ds.b	40*256*8
