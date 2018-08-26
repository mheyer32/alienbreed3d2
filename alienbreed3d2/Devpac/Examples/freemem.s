
* file examples/freemem2.s - Workbench version

* a sample Intuition program to display a window constantly showing
* the free memory figure, until it's closed

* this source code (C) HiSoft 1992 All Rights Reserved

* both source and binary are FreeWare and may be distributed free of charge
* so long as copyright messages are not removed

* revision history:
* 7th June 86	written
* 22nd Sept 86	changed includes
* 18th Dec 86	uses easystart for workbench version
* 27th Feb 92	now includes pre-assembled header

* ensure case dependent and debug
	opt	c+,d+

* firstly get the required constants and macros
	include	/system
	include	intuition/intuition.i
	include	intuition/intuition_lib.i
	include	exec/exec_lib.i
	include	graphics/graphics_lib.i
	include	exec/memory.i
	include	libraries/dos_lib.i
	include	libraries/dos.i

	include	misc/easystart.i

* constant for frequency of re-display
timeout	equ	25				in 50ths of a second

* firstly open the intuition library
	lea	intname(pc),a1
	moveq	#0,d0				dont care which version
	CALLEXEC OpenLibrary
	tst.l	d0
	beq	goawayfast			if didnt open

	move.l	d0,_IntuitionBase		store lib pointer

* and open the graphics library
	lea	grafname(pc),a1
	moveq	#0,d0
	CALLEXEC OpenLibrary
	tst.l	d0
	beq	goawaycloseint
	move.l	d0,_GfxBase

* and open a DOS library
	lea	dosname(pc),a1
	moveq	#0,d0
	CALLEXEC OpenLibrary
	tst.l	d0
	beq	goawayclosegraf
	move.l	d0,_DOSBase

* open a window next
	lea	windowdef(pc),a0
	CALLINT	OpenWindow
	tst.l	d0
	beq	goawaycloseall			if no window
	move.l	d0,windowptr			store the pointer

	move.l	#-1,oldfreemem

* the main loop - display the figure, then wait, then loop
mainloop
	moveq	#MEMF_PUBLIC,d1
	CALLEXEC AvailMem			get the figure

* got free mem, see if changed since last time
	cmp.l	oldfreemem,d0
	beq	messagetest			dont print if the same

	move.l	d0,oldfreemem

* free memory in d0.l, so convert to a hex string
* converting to decimal is left as an exercise to the reader!

	lea	thestring(pc),a0
	bsr	hexconvert

* replace leading zeros with spaces
	lea	thestring(pc),a0
	moveq	#7-1,d0				max to do
convspaces
	cmp.b	#'0',(a0)
	bne.s	noconvspaces
	move.b	#' ',(a0)+
	dbf	d0,convspaces			convert them
noconvspaces

* move the cursor to a suitable place
	moveq	#4,d0				x posn
	moveq	#20,d1				y posn
	move.l	windowptr(pc),a1
	move.l	wd_RPort(a1),a1			get rastport for window
	CALLGRAF Move

* and print the string
	move.l	windowptr(pc),a1
	move.l	wd_RPort(a1),a1
	lea	thestring(pc),a0		string
	moveq	#thestringlen,d0		length
	CALLGRAF Text

* now see if a message is waiting for me
messagetest
	move.l	windowptr(pc),a0
	move.l	wd_UserPort(a0),a0		windows message port
	CALLEXEC GetMsg
	tst.l	d0
	beq.s	nomessage
* there was a message, which in our case must be CLOSEWINDOW,
* so we should reply then go away
	move.l	d0,a1
	CALLEXEC ReplyMsg
	bra.s	closewindow

* no messages waiting, so suspend myself for a short while then
* do it all agaun
nomessage
	move.l	#timeout,d1
	CALLDOS	Delay				wait a while
	bra	mainloop

* close clicked so close the window
closewindow
	move.l	windowptr(pc),a0
	CALLINT	CloseWindow

* close all the libraries
goawaycloseall
	move.l	_DOSBase,a1
	CALLEXEC CloseLibrary

* close the graphics library
goawayclosegraf
	move.l	_GfxBase,a1
	CALLEXEC CloseLibrary

* finished so close Intuition library
goawaycloseint
	move.l	_IntuitionBase,a1
	CALLEXEC CloseLibrary

goawayfast
	moveq	#0,d0
	rts

* convert d0.l into a string at (a0) onwards in hex
hexconvert
	moveq	#8-1,d1			digit count
hexclp	rol.l	#4,d0
	move.l	d0,d2			save it
	and.b	#$f,d0
	cmp.b	#9,d0
	ble.s	hexdig
	addq.b	#7,d0
hexdig	add.b	#'0',d0
	move.b	d0,(a0)+		do a digit
	move.l	d2,d0			restore long
	dbf	d1,hexclp		do all of the digits
	rts


* window definition here
windowdef	dc.w	50,50			x posn, y posn
	dc.w	200,25				width,height
	dc.b	-1,-1				default pens
	dc.l	CLOSEWINDOW			easy IDCMP flag
	dc.l	WINDOWDEPTH!WINDOWCLOSE!SMART_REFRESH!ACTIVATE!WINDOWDRAG
	dc.l	0				no gadgets
	dc.l	0				no checkmarks
	dc.l	windowtitle			title of window
	dc.l	0				no screen
	dc.l	0				no bitmap
	dc.w	0,0,0,0				minimum, irrelevant as no sizing gadget
	dc.w	WBENCHSCREEN			in workbench

* strings here
intname		INTNAME				name of intuition lib
grafname	GRAFNAME			name of graphics library
dosname		DOSNAME				name of dos library

windowtitle	dc.b	' ',$a9,' HiSoft 1992 ',0
thestring	dc.b	'00000000 bytes free'
thestringlen	equ	*-thestring

* variables here
_IntuitionBase	dc.l	0			for int library
_GfxBase	dc.l	0			for graphics library
_DOSBase	dc.l	0			for dos library
windowptr	dc.l	0			for window ptr
oldfreemem	dc.l	0			for freemem
