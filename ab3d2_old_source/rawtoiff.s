
* the 'Hello World' program in 68000 Assembler
* the C version can be found in the Intuition manual

* this source code (C) HiSoft 1992 All Rights Reserved

* for Devpac Amiga Version 2 the following symbols were changed
* to avoid clashes with the new include files:
* Screen->MyScreen, NewScreen->MyNewScreen
* Window->MyWindow, NewWindow->MyNewWindow

	opt	c+,d+

	include	system.i			use pre-assembled header
	include	exec/exec_lib.i
	include	intuition/intuition.i
	include	intuition/intuition_lib.i
	include	lvo/graphics_lib.i
	include	graphics/text.i

INTUITION_REV	equ	31		v1.1
GRAPHICS_REV	equ	31		v1.1

* Open the intuition library

 move.l #PALETTEBIT,a0
 move.l #COPIEDPAL+4,a1
 move.w #255,d0

copydown:
 move.b 1(a0),(a1)
 move.b 3(a0),4(a1)
 move.b 5(a0),8(a1)
 add.w #6,a0
 add.w #12,a1
 dbra d0,copydown

	moveq	#100,d4			default error return code

	moveq	#INTUITION_REV,d0	version
	lea	int_name(pc),a1
	CALLEXEC OpenLibrary
	tst.l	d0
	beq	exit_false		if failed then quit
	move.l	d0,_IntuitionBase	else save the pointer

	moveq	#GRAPHICS_REV,d0
	lea	graf_name(pc),a1
	CALLEXEC OpenLibrary
	tst.l	d0
;	beq	exit_closeint		if failed then close Int, exit
	move.l	d0,_GfxBase

	lea	MyNewScreen(pc),a0
	CALLINT	OpenScreen		open a screen
	tst.l	d0
;	beq	exit_closeall		if failed the close both, exit
	move.l	d0,MyScreen

	move.l MyScreen,a0
	lea sc_BitMap(a0),a0
	lea bm_Planes(a0),a0
	move.l #RAWSCRN,(a0)
	move.l #RAWSCRN+10240,4(a0)
	move.l #RAWSCRN+10240*2,8(a0)
	move.l #RAWSCRN+10240*3,12(a0)
	move.l #RAWSCRN+10240*4,16(a0)
	move.l #RAWSCRN+10240*5,20(a0)
	move.l #RAWSCRN+10240*6,24(a0)
	move.l #RAWSCRN+10240*7,28(a0)

* now initialise a NewWindow structure. This is normally easier to
* do with dc.w/dc.l statement etc, but for comparison with the C
* version we do it like this
	lea	MyNewWindow(pc),a0	good place to start
	move.w	#20,nw_LeftEdge(a0)
	move.w	#20,nw_TopEdge(a0)
	move.w	#300,nw_Width(a0)
	move.w	#100,nw_Height(a0)
	move.b	#0,nw_DetailPen(a0)
	move.b	#1,nw_BlockPen(a0)
	move.l	#window_title,nw_Title(a0)
_temp	set	WINDOWCLOSE!SMART_REFRESH!ACTIVATE!WINDOWSIZING
	move.l	#_temp!WINDOWDRAG!WINDOWDEPTH,nw_Flags(a0)
	move.l	#CLOSEWINDOW,nw_IDCMPFlags(a0)
	move.w	#CUSTOMSCREEN,nw_Type(a0)
	clr.l	nw_FirstGadget(a0)
	clr.l	nw_CheckMark(a0)
	move.l	MyScreen(pc),nw_Screen(a0)
	clr.l	nw_BitMap(a0)
	move.w	#100,nw_MinWidth(a0)
	move.w	#25,nw_MinHeight(a0)
	move.w	#640,nw_MaxWidth(a0)
	move.w	#200,nw_MaxHeight(a0)

 move.w #256,COPIEDPAL
 move.w #0,COPIEDPAL+2
LOOKFORME:
 move.l MyScreen,a0
 lea sc_ViewPort(a0),a0
 move.l #COPIEDPAL,a1
 move.l _GfxBase,a6
 jsr -$372(a6)
 

* thats it set up, now open the window (a0=NewWindow already)
;	CALLINT	OpenWindow
;	tst.l	d0
;	beq	exit_closescr			if failed
;	move.l	d0,MyWindow			save it
;
;	move.l	d0,a1				window
;	move.l	wd_RPort(a1),a1			rastport
;	moveq	#20,d0				X
;	moveq	#20,d1				Y
;	CALLGRAF Move				move the cursor
;
;	move.l	MyWindow(pc),a0
;	move.l	wd_RPort(a0),a1			rastport
;	lea	hello_message(pc),a0
;	moveq	#11,d0
;	CALLGRAF Text				print something
;
;	move.l	MyWindow(pc),a0
;	move.l	wd_UserPort(a0),a0
;	move.b	MP_SIGBIT(a0),d1		(misprint in manual)
;	moveq	#0,d0
;	bset	d1,d0				do a shift
;	CALLEXEC Wait

;	moveq	#0,d4				return code

* various exit routines that do tidying up, given a return code in d4

;	move.l	MyWindow(pc),a0
;	CALLINT CloseWindow

;exit_closescr
;	move.l	MyScreen(pc),a0
;	CALLINT CloseScreen

;exit_closeall
;	move.l	_GfxBase(pc),a1
;	CALLEXEC CloseLibrary

;exit_closeint
;	move.l	_IntuitionBase(pc),a1
;	CALLEXEC CloseLibrary

;done:
;	bra done

exit_false
	moveq #0,d4
	move.l	d4,d0				return code
	rts

* the definition of the screen - note that in assembler you
* MUST get the sizes of these fields correct, by consulting either
* the RKM or the header files

MyNewScreen	dc.w	0,0		left, top
		dc.w	320,256		width, height
		dc.w	8		depth
		dc.b	0,1		pens
		dc.w	0		viewmodes
		dc.w	CUSTOMSCREEN	type
		dc.l	MyFont		font
		dc.l	screen_title	title
		dc.l	0		gadgets
		dc.l	0		bitmap

* my font definition
MyFont	dc.l	font_name
	dc.w	TOPAZ_SIXTY
	dc.b	FS_NORMAL
	dc.b	FPF_ROMFONT

* the variables
_IntuitionBase	dc.l	0		Intuition lib pointer
_GfxBase	dc.l	0		graphics lib pointer
MyScreen		dc.l	0
MyWindow		dc.l	0
MyNewWindow	ds.b	nw_SIZE		a buffer


* some strings
int_name	INTNAME
graf_name	GRAFNAME
hello_message	dc.b	'Hello World'

* these are C strings, so have to be null terminated
screen_title	dc.b	'My Own Screen',0
font_name	dc.b	'topaz.font',0
window_title	dc.b	'A Simple Window',0

 even

COPIEDPAL:
 dc.w 256,0
 ds.l 3*256
 ds.l 10

PALETTEBIT:
; incbin "256palette"
; dc.w $ffff,$fffe
 
 incbin "includes/256pal"

 
 
 SECTION BGDROP,code_c
 
RAWSCRN:
 incbin "rawscrnd"

