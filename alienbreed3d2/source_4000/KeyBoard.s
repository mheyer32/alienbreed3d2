*---------------------------------------------------------------------------*
KInt_Init	;VBR Assumed $0
*---------------------------------------------------------------------------*
		Move.l	#KInt_Main,$68.w	Install Interrupt 
		And.b	#$3f,$bfe201		Set Timers
		Move.b	#$7f,$bfed01
		Move.b	$bfed01,d0
		Move.b	#$88,$bfed01
*---------------------------------------------------------------------------*
		Lea	KInt_States(pc),a0	Map Of Key States (Up/Down)
		Clr.l	(a0)+			Clear It (All Up)
		Clr.l	(a0)+			
		Clr.l	(a0)+			
		Clr.l	(a0)+			
*---------------------------------------------------------------------------*
		St.b	KInt_CCode		
		Move.b	#$a0,$bfee01		Start Timey Thing
		Rts				And return
*---------------------------------------------------------------------------*
KInt_Main	
*---------------------------------------------------------------------------*
		Movem.l	d0/d1/a0/a1/a6,-(a7)	Stack everything
		Move.w	#8,$dff09a		Temp Disable Int.
		Move.w	$dff01e,d0		Intreqr
		And.w	#8,d0			Mask Out All X^ K_Int
	Beq	KInt_End			Not Keyboard Interrupt
*---------------------------------------------------------------------------*
		Lea	$bfed01,a6
		Move.w	#$8,$dff09c		Clear Int.Request
		Move.b	-$100(a6),d0		Move Raw Keyboard value
		Ror.b	#1,d0			Roll to correct
		Not.b	d0			
		Move.b	d0,KInt_CCode		Save Corrected Keycode
*---------------------------------------------------------------------------*
.HandShake	Move.b	#8,(a6)
		Move.b	#7,-$900(a6)
		Move.b	#0,-$800(a6)
		Move.b	#0,-$100(a6)
		Move.b	#$d1,$100(a6)		
		Tst.b	(a6)	
.wait		Btst	#0,(a6)
	Beq.s	.wait
		Move.b	#$a0,$100(a6)		
		Move.b	(a6),d0		
		Move.b	#$88,(a6)
*---------------------------------------------------------------------------*
		Lea	KInt_2Ascii(pc),a0
		Lea	KInt_KeyMap(pc),a1
		Lea	KInt_States(pc),a6
		Moveq.w	#0,d0
		Move.b	KInt_CCode(pc),d0
	Bmi.s	KInt_KeyUp			neg if up 
*---------------------------------------------------------------------------*
KInt_KeyDown
*---------------------------------------------------------------------------*
		Move.w	#$f00,$dff180		**Temp ColFlash
		Move.b	(a0,d0.w),KInt_Askey	Ascii Value On Down Press
		Moveq.w	#7,d1
		And.w	d0,d1
		Lsr.w	#3,d0
		Not.w	d1
		Btst.b	d1,(a1,d0.w)		Keymap Wether Key Included?
	Bne.s	KInt_End
		Bset.b	d1,(a6,d0.w)		
	Bra	KInt_End
*---------------------------------------------------------------------------*
KInt_KeyUp
*---------------------------------------------------------------------------*
		Move.w	#$0f0,$dff180		**Temp ColFlash
		And.w	#$7f,d0			Make code Positive
		Moveq.w	#7,d1
		And.w	d0,d1
		Lsr.w	#3,d0
		Not.w	d1
		Btst.b	d1,(a1,d0.w)
	Bne.s	KInt_End
		Bclr.b	d1,(a6,d0.w)		If Key up Set Corr. State
KInt_End	Movem.l	(a7)+,d0/d1/a0/a1/a6	Unstack Everything
		Move.w	#$8008,$dff09a		Re-enable Int.
		Rte
*---------------------------------------------------------------------------*
KInt_CCode	Ds.b	1
KInt_Askey	Ds.b	1
KInt_OCode	Ds.w	1

KInt_States	Ds.b	16		On/Off States Of Keys Bitwise
KInt_KeyMap	Ds.b	16		Bitwise To Include In Any Processing
KInt_2Ascii	;Change KeyCode To Ascii 
		Dc.b	" `  "," 1  "," 2  "," 3  "
		dc.b	" 4  "," 5  "," 6  "," 7  "
		dc.b	" 8  "," 9  "
		Dc.b	" 0  "," -  "," +  "," \  "
		dc.b 	'    ','    '," q  "," w  "
		dc.b	" e  "," r  "
		Dc.b	" t  "," y  "," u  "," i  "
		dc.b	" o  "," p  "," [  "," ]  "
		dc.b	'    ','    '
		Dc.b	'    ','    '," a  "," s  "
		dc.b	" d  "," f  "," g  "," h  "
		dc.b	" j  "," k  "
		Dc.b	" l  "," ;  "," '  ",'    '
		dc.b	'    ','    ','    ','    '
		dc.b	'    '," z  "
		Dc.b	" x  "," c  "," v  "," b  "
		dc.b	" n  "," m  "," ,  "," .  "
		dc.b 	" /  ",'    '
		Dc.b	'    ','    ','    ','    '
		dc.b	" ",'    ','    ','    '
		dc.b	'    ','    '
		
		Dc.b	'    ','    ','    ','    '
		dc.b	'SPC ','<-- ','TAB ','    '
		dc.b	'RTN ','ESC '
		Dc.b	'DEL ','    ','    ','    '
		dc.b	'    ','    ','[[[ ',']]] '
		dc.b	'{{{ ','}}} '
		Dc.b	'FK1 ','FK2 ','FK3 ','FK4 '
		dc.b	'FK5 ','FK6 ','FK7 ','FK8 '
		dc.b	'FK9 ','FK0 '
		Dc.b	'    ','    ','    ','    '
		dc.b	'HLP ','LSH ','RSH ','    '
		dc.b	'CPL ','CTL '
		Dc.b	'LAL ','RAL ','LAM ','RAM '
		dc.b	'    ','    ','    ','    '
		dc.b	'    ','    '
		Dc.b	'    ','    ','    ','    '
		dc.b	'    ','    ','    ','    '
		dc.b	'    ','    '


