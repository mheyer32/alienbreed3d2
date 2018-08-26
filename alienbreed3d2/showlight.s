
* the 'Hello World' program in 68000 Assembler
* the C version can be found in the Intuition manual

* this source code (C) HiSoft 1992 All Rights Reserved

* for Devpac Amiga Version 2 the following symbols were changed
* to avoid clashes with the new include files:
* Screen->MyScreen, NewScreen->MyNewScreen
* Window->MyWindow, NewWindow->MyNewWindow

	opt	c+,d+

	include	workbench:utilities/devpac/system			use pre-assembled header
	include	exec/exec_lib.i
	include	intuition/intuition.i
	include	intuition/intuition_lib.i
	include	graphics/graphics_lib.i
	include	graphics/text.i

INTUITION_REV	equ	31		v1.1
GRAPHICS_REV	equ	31		v1.1

* Open the intuition library

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

 move.w #256,COPIEDPAL
 move.w #0,COPIEDPAL+2
LOOKFORME:
 move.l MyScreen,a0
 lea sc_ViewPort(a0),a0
 move.l #COPIEDPAL,a1
 move.l _GfxBase,a6
 jsr -$372(a6)
	
loop:

 sub.w #1,FRAME
 bge.s .nofr
 
 move.w #4,FRAME
 add.w #50*4,FLIBBLE
 cmp.w #50*4*3,FLIBBLE
 blt .nofr
 move.w #0,FLIBBLE
 
.nofr:


 move.l MyScreen,a4
 move.w sc_MouseX(a4),d0
 move.w sc_MouseY(a4),d1
 
 btst #6,$bfe001
 beq.s .hitspleen
 
 clr.b lastspleen
 bra.s .nospleen
 
.hitspleen
 tst.b lastspleen
 bne.s .nospleen
 
 add.w #1,spleen
 st lastspleen
 
 cmp.w #2,spleen
 ble.s .nospleen
 move.w #0,spleen
 
.nospleen: 
 
 sub.w #160,d0
 sub.w #128,d1
 muls #48*2,d0
 muls #48*2,d1
 divs #160,d0
 divs #128,d1
 
 
 move.w d0,xmouse
 move.w d1,ymouse

; move.w spleen,d7
; addq #1,d7

 move.w #4,d7
LOOKHERE:

 move.l #willy,a0
 move.w #-3,d0
 move.w #6,d2
makebright
 move.w #-3,d1
 move.w #6,d3
acbr:

 move.w d0,d5
 move.w d1,d4
 asl.w #4,d4
 asl.w #4,d5
 sub.w xmouse,d4
 bge.s .okpos1
 neg.w d4
.okpos1
 
 sub.w ymouse,d5
 bge.s .okpos2
 neg.w d5
.okpos2:

 add.w d4,d5 ; distance
 ext.l d5
 divs d7,d5
 
 cmp.w #31,d5
 ble.s .oksmall
 
 move.w #31,d5
 
.oksmall:

 move.w d5,(a0)+

 addq #1,d1
 dbra d3,acbr
 
 addq #1,d0
 dbra d2,makebright


 move.l #Brights,a0
 move.l #willy,a2
 move.l #CMP,a1
 move.l #PALS,a3
 move.w #28,d0
makepals:

 move.w (a0)+,d1
 move.w (a2,d1.w*2),d1
 
 move.l (a1,d1.w*8),(a3)+
 move.b #0,-4(a3)
 move.l 4(a1,d1.w*8),(a3)+

 dbra d0,makepals


 move.l #PALS,a0
 move.l #PTR,a1
 adda.w FLIBBLE,a1
 
 move.w spleen,d0
 muls #50*4*3,d0
 add.l d0,a1
 
 move.l #WAD,a2
 
 move.l FASTBUFFER,a4
 
 move.w #127,d0
 move.w #49,d1
 move.w #320*2,d4
 moveq #0,d3
across:
 move.w d0,d2
 move.l a4,a3
 move.l a2,a5
 add.l (a1)+,a5
down:

 move.b (a5)+,d3
 move.b (a0,d3.w),(a3)
.black:
 add.w d4,a3


 dbra d2,down
 addq #2,a4
 
 dbra d1,across


 move.l FASTBUFFER,a0
 move.l #RAWSCRN,a1
 add.l #10+40*64,a1
 move.l #(160/8)-1,d0
 move.l #127,d1
 move.w #(320-160)*2,d2
 move.w #40-20,d3
donebigconv
 jsr CHUNKYTOPLANAR 

	bra loop

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

xmouse: dc.w 0
ymouse: dc.w 0

spleen: dc.w 0
lastspleen: dc.w 0

COPIEDPAL:
 dc.w 256,0
 ds.l 3*256
 ds.l 10

PALETTEBIT:
; incbin "256palette"
; dc.w $ffff,$fffe
 
 incbin "ab3:includes/256pal"


CHUNKYTOPLANAR

 move.w d2,MODUL
 move.w d0,WTC
 
 move.w d1,HTC
 move.w d3,SCRMOD
 
 add.l #10240*7,a1
 lea -10240(a1),a2
 lea -10240(a2),a3
 lea -10240(a3),a4
 move.l a4,a5
 sub.l #20480,a5
 move.l a5,a6
 sub.l #20480,a6
outconv:
 move.w WTC,d7

convlop:
 swap d7
 move.l (a0)+,d0
 move.w d0,d1
 swap d0
 move.l (a0)+,d2
 move.w d2,d3
 swap d2
 move.l (a0)+,d4
 move.w d4,d5
 swap d4
 move.w (a0)+,d6
 move.w (a0)+,d7

 add.w d0,d0
 addx.w d0,d0
 addx.w d1,d1
 addx.w d0,d0
 addx.w d2,d2
 addx.w d0,d0
 addx.w d3,d3
 addx.w d0,d0
 addx.w d4,d4
 addx.w d0,d0
 addx.w d5,d5
 addx.w d0,d0
 addx.w d6,d6
 addx.w d0,d0
 addx.w d7,d7
 addx.w d0,d0
 move.b d0,(a1)+
 
 move.b d1,d0
 add.w d1,d1
 move.b d0,d1
 addx.w d1,d1
 addx.w d2,d2
 addx.w d1,d1
 addx.w d3,d3
 addx.w d1,d1
 addx.w d4,d4
 addx.w d1,d1
 addx.w d5,d5
 addx.w d1,d1
 addx.w d6,d6
 addx.w d1,d1
 addx.w d7,d7
 addx.w d1,d1
 move.b d1,(a2)+
 
 move.w d2,d0
 add.w d2,d2
 move.b d0,d2
 addx.w d2,d2
 addx.w d3,d3
 addx.w d2,d2
 addx.w d4,d4
 addx.w d2,d2
 addx.w d5,d5
 addx.w d2,d2
 addx.w d6,d6
 addx.w d2,d2
 addx.w d7,d7
 addx.w d2,d2
 move.b d2,(a3)+
 
 move.w d3,d0
 add.w d3,d3
 move.b d0,d3
 addx.w d3,d3
 addx.w d4,d4
 addx.w d3,d3
 addx.w d5,d5
 addx.w d3,d3
 addx.w d6,d6
 addx.w d3,d3
 addx.w d7,d7
 addx.w d3,d3
 move.b d3,(a4)+
 
 move.b d4,d0
 add.w d4,d4
 move.b d0,d4
 addx.w d4,d4
 addx.w d5,d5
 addx.w d4,d4
 addx.w d6,d6
 addx.w d4,d4
 addx.w d7,d7
 addx.w d4,d4
 move.b d4,10240(a5)
 
 move.b d5,d0
 add.w d5,d5
 move.b d0,d5
 addx.w d5,d5
 addx.w d6,d6
 addx.w d5,d5
 addx.w d7,d7
 addx.w d5,d5
 move.b d5,(a5)+
 
 move.b d6,d0
 add.w d6,d6
 move.b d0,d6
 addx.w d6,d6
 addx.w d7,d7
 addx.w d6,d6
 move.b d6,10240(a6)

 rol.w #1,d7
 move.b d7,(a6)+
 swap d7
 dbra d7,convlop

 add.w MODUL,a0
 move.w SCRMOD,d0
 add.w d0,a1
 add.w d0,a2
 add.w d0,a3
 add.w d0,a4
 add.w d0,a5
 add.w d0,a6

 subq #1,HTC
 bgt outconv

 rts

MODUL: dc.w 0
HTC: dc.w 0
WTC: dc.w 0
SCRMOD: dc.w 0

willy: ds.w 49

Brights:
 dc.w 3
 dc.w 8,9,10,11,12
 dc.w 15,16,17,18,19
 dc.w 21,22,23,24,25,26,27
 dc.w 29,30,31,32,33
 dc.w 36,37,38,39,40
 dc.w 45
 
; dc.w AA,AA,AA,00,AA,AA,AA	0
; dc.w AA,01,02,03,04,05,AA	7
; dc.w AA,06,07,08,09,10,AA	14
; dc.w 11,12,13,14,15,16,17	21
; dc.w AA,18,19,20,21,22,AA	28
; dc.w AA,23,24,25,26,27,AA	35
; dc.w AA,AA,AA,28,AA,AA,AA	42

PALS:
 ds.l 2*49

 
FRAME: dc.w 4
FLIBBLE: dc.w 0
 
FASTBUFFER:
 dc.l fasty
 
fasty: ds.w 320*256

WAD: incbin "ab3:hqn/priest.wad"
PTR: incbin "ab3:hqn/priest.ptr"
CMP: incbin "ab3:hqn/priest.256pal"
 
 SECTION BGDROP,code_c
 
RAWSCRN:
 ds.l 2560*8

