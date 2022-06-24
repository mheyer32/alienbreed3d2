	SECTION Proggy,CODE

SERPER	equ	$032
SERDATR	equ	$018
SERDAT	equ	$030
INTREQ	equ	$09C
INTENA	equ	$09A
INTENAR	equ	$01C
DMACON	equ	$096
BPLCON0	equ	$100
BPLCON1	equ	$102
COL0	equ	$180
OPENLIB		equ	-552
CLOSELIB	equ	-414

WM MACRO
\@waituntilpressed:
	btst	#6,$bfe001
	bne.s	\@waituntilpressed
\@waituntilreleased:
	btst	#6,$bfe001
	beq.s	\@waituntilreleased
	ENDM
	
	
	;first we get the command line
	move.b	(a0),commandline
	
	;then we must turn off the system
	move.l	4.w,a6		;get execbase
	move.l	#gfxname,a1	;point to 'graphics.library'
	moveq	#0,d0
	jsr	OPENLIB(a6)
	move.l	d0,a1
	move.l	38(a1),old	;store workbench copper list
	move.l	4.w,a6
	jsr	CLOSELIB(a6)
	move.l	#$dff000,a6	;get custom address
	move.w	#$87c0,DMACON(a6)
	move.w	#$0020,DMACON(a6)
	move.w	INTENAR(a6),saveinters
	move.w	#$7fff,INTENA(a6)
	move.l	#copper,$dff080
	
	move.w	#184,SERPER(a6)	;19200 baud, 8 bits, no parity
	move.w	#$f00,COLOUR
	WM
	move.b	commandline,d1		;get command line
	cmp.b	#"r",d1
	beq.s	RECIEVEMODE
SENDMODE:
	move.w	#$0ff,COLOUR
	move.l	#senddata,a0
	move.l	#recdata,a1
	move.l	(a0)+,d0
	bsr	SENDFIRST
	move.l	d0,(a1)+
	move.l	(a0)+,d0
	bsr	SENDFIRST
	move.l	d0,(a1)+
	move.l	(a0)+,d0
	bsr	SENDFIRST
	move.l	d0,(a1)+
	move.w	#$0f0,COLOUR
	bra.s	ENDOFPROG
RECIEVEMODE:
	move.w	#$ff0,COLOUR
	move.l	#senddata,a0
	move.l	#recdata,a1
	move.l	(a0)+,d0
	bsr	RECEIVEFIRST
	move.l	d0,(a1)+
	move.l	(a0)+,d0
	bsr	RECEIVEFIRST
	move.l	d0,(a1)+
	move.l	(a0)+,d0
	bsr	RECEIVEFIRST
	move.l	d0,(a1)+
	move.w	#$00f,COLOUR
	
ENDOFPROG:
	WM
	move.w	#$000,COLOUR
	;this little bit of code restores the system
	;first we must wait and make sure any serial transfer has finished
	;(we don't want the system jumping in and stopping things)
SERFINWAIT:
	btst	#4,SERDATR(a6)
	beq.s	SERFINWAIT
	move.l	old,$dff080	;restore the workbench copper list
	move.w	#$8020,DMACON(a6)
	move.w	saveinters,d0
	or.w	#$c000,d0
	move.w	d0,INTENA(a6)
	clr.w	$dff0a8
	clr.w	$dff0b8
	clr.w	$dff0c8
	clr.w	$dff0d8
	rts
	
	include "serial.inc"
		
old:		dc.l	0
saveinters:	dc.w	0
senddata:	dc.b	"Hello World",0
	even
recdata:	ds.b	100
gfxname:	dc.b	"graphics.library",0
commandline:	dc.b	0

	SECTION Copper_List,CODE_C
;here is our copper list (what there is of it)
copper:
	dc.w	BPLCON0,$0201	;turn of all bitplanes
	dc.w	BPLCON1,0
	dc.w	COL0
COLOUR:	dc.w	0
	dc.w	$ffff,$fffe
