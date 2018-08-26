
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

 move.l MyScreen,a4
 move.w sc_MouseX(a4),d0
 move.w sc_MouseY(a4),d1
 move.w d0,OLDXM
 move.w d1,OLDYM
	
loop:

 move.l MyScreen,a4
 move.w sc_MouseX(a4),d0
 move.w sc_MouseY(a4),d1
 
 sub.w OLDXM,d0
 sub.w OLDYM,d1
 add.w d0,OLDXM
 add.w d1,OLDYM
 
 btst #6,$bfe001
 beq.s .SHIFTABOUT
 
 
 
 muls #8190,d0
 divs #160,d0
 add.w d0,YANG
 and.w #8190,YANG
 muls #8190,d1
 divs #160,d1
 and.w #8190,d1
 add.w d1,XANG
 and.w #8190,XANG
 bra .ROTABOUT
.SHIFTABOUT

 add.w d0,XOFF
 add.w d1,ZOFF
 
 
.ROTABOUT

 move.l #SOLIDMAP,a0
 move.w #(40*8)-1,d0
 move.l #0,d1
CLRSOLID
 move.l d1,(a0)+
 move.l d1,(a0)+
 move.l d1,(a0)+
 move.l d1,(a0)+
 move.l d1,(a0)+
 move.l d1,(a0)+
 move.l d1,(a0)+
 move.l d1,(a0)+
 move.l d1,(a0)+
 move.l d1,(a0)+
 dbra d0,CLRSOLID

*******************************************
* Calculate the shadows....
*******************************************

 move.w XANG,d1
 move.w YANG,d3
 move.l #SINETABLE,a1
 move.w (a1,d1.w),XSIN	;xsin
 move.w (a1,d3.w),YSIN	;ysin
 
 add.w #2048,a1
 move.w (a1,d1.w),XCOS	;xcos
 move.w (a1,d3.w),YCOS	;ycos

 move.l #POLYGONDATA,a0
 move.w (a0)+,d7	; number of polys
SHADOWLOOP:
 move.w d7,-(a7)
 
 addq #2,a0
 move.l #ROTATEDPTS,a2
 move.l #UVCOORDS,a3

 moveq #3,d7
.ROTPTLOP:

 move.w (a0)+,d0
 move.w d0,d3
 move.w (a0)+,d1
 move.w (a0)+,d2
 move.w d2,d5

 muls YCOS,d0
 muls YSIN,d2
 sub.l d2,d0
 asr.l #6,d0	; new x*512
 
 muls YSIN,d3
 muls YCOS,d5
 add.l d5,d3
 add.l d3,d3
 swap d3
 move.w d3,d2	; new z

 move.w d1,d4
 move.w d2,d5
 muls XCOS,d1
 muls XSIN,d2
 sub.l d2,d1
 asr.l #6,d1	; new y*512
 
 muls XSIN,d4
 muls XCOS,d5
 add.l d5,d4
 add.l d4,d4
 swap d4
 move.w d4,d2	; new z

 add.w ZOFF,d2
 ext.l d2
 
 move.w XOFF,d5
 ext.l d5
 asl.l #8,d5
 add.l d5,d5
 add.l d5,d0
 
 move.l d0,(a2)+
 move.l d1,(a2)+
 move.l d2,(a2)+
 addq #4,a2
 
 move.l (a0)+,(a3)+

 dbra d7,.ROTPTLOP
 
 move.l #SOLIDMAP,a1
 move.l #ROTATEDPTS,a2
 move.l #0,d7
.ACROSS:
 move.w #0,d6
 move.l (0*16)(a2),d0
 move.l (1*16)(a2),d3
 sub.l d0,d3
 move.l 4+(0*16)(a2),d1
 move.l 4+(1*16)(a2),d4
 sub.l d1,d4
 move.l 8+(0*16)(a2),d2
 move.l 8+(1*16)(a2),d5
 sub.l d2,d5
 muls.l d7,d3
 muls.l d7,d4
 muls.l d7,d5
 asr.l #4,d3
 asr.l #4,d4
 asr.l #4,d5
 add.l d3,d0	;tx
 add.l d4,d1	;ty
 add.l d5,d2	;tz

 move.l 3*16(a2),d3
 move.l 2*16(a2),d6
 sub.l d3,d6
 muls.l d7,d6
 asr.l #4,d6
 add.l d6,d3
 
 move.l 4+(3*16)(a2),d4
 move.l 4+(2*16)(a2),d6
 sub.l d4,d6
 muls.l d7,d6
 asr.l #4,d6
 add.l d6,d4
 
 move.l 8+(3*16)(a2),d5
 move.l 8+(2*16)(a2),d6
 sub.l d5,d6
 muls.l d7,d6
 asr.l #4,d6
 add.l d6,d5
 
 asr.l #8,d0
 asr.l #8,d1
 asr.l #8,d3
 asr.l #8,d4
 asr.l #1,d0
 asr.l #1,d1
 asr.l #1,d3
 asr.l #1,d4
 
 sub.l d0,d3
 sub.l d1,d4
 sub.l d2,d5
 sub.w #512,d2
 
 swap d3
 clr.w d3
 swap d4
 clr.w d4
 swap d2
 clr.w d2
 swap d0
 clr.w d0
 swap d1
 clr.w d1
 swap d5
 clr.w d5
 asr.l #8,d5
 asr.l #4,d2
 asr.l #8,d3
 asr.l #4,d0
 asr.l #8,d4
 asr.l #4,d1
 move.l d3,XADD
 move.l d4,YADD
 move.l d5,ZADD
 add.l #20*65536,d0
; add.l lmxoff,d0
 
 add.l #20*65536,d1
 add.l #20*65536,d2

 move.w #0,d6 
 
.DOWN:

 add.l XADD,d0
 add.l YADD,d1
 add.l ZADD,d2
 
 move.l d0,d3
; cmp.l #40*65536,d3
; blt.s .oksm
; sub.l #40*65536,d3
;.oksm:
 move.l d1,d4
 move.l d2,d5
 
 swap d3
 swap d4
 swap d5
 
; muls #40,d5
; add.w d5,d4
 muls #40,d5
 ext.l d3
 add.l d5,d3

 asl.w #3,d3

 move.w d4,d5
 asr.w #3,d5
 add.w d5,d3
 
 not.b d4
 bset.b d4,(a1,d3.w)

 addq #1,d6
 cmp.w #16,d6
 ble .DOWN
 addq #1,d7
 cmp.w #16,d7
 ble .ACROSS

 move.w (a7)+,d7
 dbra d7,SHADOWLOOP

 move.l #SOLIDMAP,a1
; move.l #$80000000,(40*20+20)*8(a1)

 move.l #WORLD,a0
 move.l #SOLIDMAP,a1
 move.w #39,d0
.ZLOOP
 move.w #39,d1
 move.l a0,a3
.XLOOP
 move.l a3,a2
 move.l (a1)+,d2
 move.w #31,d3
 move.w #0,d4
 move.w #0,d5
.shadown1
 move.b d4,(a2)
 add.l d2,d2
 bcc.s .noshad1
 move.w #127,d5
 bra.s .shad1
.noshad1:
 move.w d5,d4
.shad1:
 add.w #40,a2
 dbra d3,.shadown1

 move.l (a1)+,d2
 move.w #7,d3
.shadown2
 move.b d4,(a2)
 add.l d2,d2
 bcc.s .noshad2
 move.w #127,d5
 bra.s .shad2
.noshad2:
 move.w d5,d4
.shad2
 add.w #40,a2
 dbra d3,.shadown2

 add.w #1,a3
 dbra d1,.XLOOP
 
 add.w #1600,a0
 dbra d0,.ZLOOP
 

 move.l #POLYGONDATA,a0
 move.w (a0)+,d7	; number of polys
POLYGONLOOP:
 move.l d7,-(a7)

 move.w (a0)+,TEXTUREADD
 move.l #ROTATEDPTS,a2
 move.l #UVCOORDS,a3

 
 moveq #3,d7
ROTPTLOP:

 move.w (a0)+,d0
 move.w d0,d3
 move.w (a0)+,d1
 move.w (a0)+,d2
 move.w d2,d5

 muls YCOS,d0
 muls YSIN,d2
 sub.l d2,d0
 asr.l #6,d0	; new x*512
 
 muls YSIN,d3
 muls YCOS,d5
 add.l d5,d3
 add.l d3,d3
 swap d3
 move.w d3,d2	; new z

 move.w d1,d4
 move.w d2,d5
 muls XCOS,d1
 muls XSIN,d2
 sub.l d2,d1
 asr.l #6,d1	; new y*512
 
 muls XSIN,d4
 muls XCOS,d5
 add.l d5,d4
 add.l d4,d4
 swap d4
 move.w d4,d2	; new z


 add.w ZOFF,d2
 ext.l d2
 
 move.w XOFF,d5
 ext.l d5
 asl.l #8,d5
 add.l d5,d5
 add.l d5,d0
 
 move.l d0,(a2)+
 move.l d1,(a2)+
 move.l d2,(a2)+
 addq #4,a2
 
 move.l (a0)+,(a3)+

 dbra d7,ROTPTLOP

 move.l a0,-(a7)

 moveq #3,d7
 move.l #ROTATEDPTS,a0
 move.l #ONSCREENPTS,a1
 move.l FASTBUFFER,a2
CONVTOSCREEN:
 move.l (a0)+,d0
 move.l (a0)+,d1
 move.l (a0)+,d2
 addq #4,a0  

 divs d2,d0
 divs d2,d1
 add.w #160*4,d0
 add.w #128*4,d1
 move.w d0,(a1)+
 move.w d1,(a1)+
 
; ext.l d0
; ext.l d1
; asr.l #2,d0
; and.b #%11111100,d1
; asl.l #4,d1
; move.l d1,d2
; asl.l #2,d1
; add.l d2,d1
; add.l d1,d0
;
; move.b #255,(a2,d0.l)

 dbra d7,CONVTOSCREEN
 
 move.l #ONSCREENPTS,a1
 move.w (a1),d0	;x1
 sub.w 4(a1),d0
 move.w 8(a1),d2
 sub.w 4(a1),d2


 move.w 2(a1),d1	;x1
 sub.w 6(a1),d1
 move.w 10(a1),d3
 sub.w 6(a1),d3
 
 muls d2,d1
 muls d0,d3
 sub.l d3,d1
 ble NOPOLYGON

*****************************
* Calculate the light map
 move.l #LIGHTMAP,a0
 move.l #WORLD,a1
 move.l #ROTATEDPTS,a2
 move.l #0,d7
ACROSS:
 move.w #0,d6
 move.l (0*16)(a2),d0
 move.l (1*16)(a2),d3
 sub.l d0,d3
 move.l 4+(0*16)(a2),d1
 move.l 4+(1*16)(a2),d4
 sub.l d1,d4
 move.l 8+(0*16)(a2),d2
 move.l 8+(1*16)(a2),d5
 sub.l d2,d5
 muls.l d7,d3
 muls.l d7,d4
 muls.l d7,d5
 asr.l #3,d3
 asr.l #3,d4
 asr.l #3,d5
 add.l d3,d0	;tx
 add.l d4,d1	;ty
 add.l d5,d2	;tz

 move.l 3*16(a2),d3
 move.l 2*16(a2),d6
 sub.l d3,d6
 muls.l d7,d6
 asr.l #3,d6
 add.l d6,d3
 
 move.l 4+(3*16)(a2),d4
 move.l 4+(2*16)(a2),d6
 sub.l d4,d6
 muls.l d7,d6
 asr.l #3,d6
 add.l d6,d4
 
 move.l 8+(3*16)(a2),d5
 move.l 8+(2*16)(a2),d6
 sub.l d5,d6
 muls.l d7,d6
 asr.l #3,d6
 add.l d6,d5
 
 asr.l #8,d0
 asr.l #8,d1
 asr.l #8,d3
 asr.l #8,d4
 asr.l #1,d0
 asr.l #1,d1
 asr.l #1,d3
 asr.l #1,d4
 
 sub.l d0,d3
 sub.l d1,d4
 sub.l d2,d5
 sub.w #512,d2
 
 swap d3
 clr.w d3
 swap d4
 clr.w d4
 swap d2
 clr.w d2
 swap d0
 clr.w d0
 swap d1
 clr.w d1
 swap d5
 clr.w d5
 asr.l #7,d5
 asr.l #4,d2
 asr.l #7,d3
 asr.l #4,d0
 asr.l #7,d4
 asr.l #4,d1
 move.l d3,XADD
 move.l d4,YADD
 move.l d5,ZADD
 add.l #20*65536,d0
; add.l lmxoff,d0
 
 add.l #20*65536,d1
 add.l #20*65536,d2

 move.w #0,d6 
 
DOWN:

 add.l XADD,d0
 add.l YADD,d1
 add.l ZADD,d2
 
 move.l d0,d3
; cmp.l #40*65536,d3
; blt.s .oksm
; sub.l #40*65536,d3
;.oksm:
 move.l d1,d4
 move.l d2,d5
 
 swap d3
 swap d4
 swap d5
 
 muls #40,d5
 add.w d5,d4
 muls #40,d4
 ext.l d3
 add.l d4,d3
 
 move.w d6,d4
 move.w d7,d5
 asl.w #4,d5
 add.w d4,d5
 
 move.l d7,-(a7)
 lea (a1,d3.l),a5
 
 moveq #0,d3
 moveq #0,d4
 move.b 0(a5),d3		;x,y,z
 
 bra SIMPLE
 
 move.b 1(a5),d4	;x+1,y,z
 sub.w d3,d4
 bge.s .okp1
 neg.w d4
 mulu d0,d4
 neg.l d4
 bra.s .dn1
.okp1
 mulu d0,d4
.dn1
 swap d4
 add.w d4,d3

 moveq #0,d4
 moveq #0,d5
 move.b 0(a5),d4	;x,y+1,z
 move.b 1(a5),d5	;x+1,y+1,z
 sub.w d4,d5
 bge.s .okp2
 neg.w d5
 mulu d0,d5
 neg.l d5
 bra.s .dn2
.okp2
 mulu d0,d5
.dn2
 swap d5
 add.w d5,d4
 
 sub.w d3,d4
 bge.s .okp5
 neg.w d4
 mulu d1,d4
 neg.l d4
 bra.s .dn5
.okp5
 mulu d1,d4
.dn5
 swap d4
 add.w d4,d3

 moveq #0,d4
 moveq #0,d5
 move.b 1600(a5),d4		;x,y,z
 move.b 1601(a5),d5	;x+1,y,z
 sub.w d4,d5
 bge.s .okp3
 neg.w d5
 mulu d0,d5
 neg.l d5
 bra.s .dn3
.okp3
 mulu d0,d5
.dn3
 swap d5
 add.w d5,d4

 moveq #0,d5
 moveq #0,d7
 move.b 1600(a5),d5	;x,y+1,z
 move.b 1601(a5),d7	;x+1,y+1,z
 sub.w d5,d7
 bge.s .okp4
 neg.w d7
 mulu d0,d7
 neg.l d7
 bra.s .dn4
.okp4
 mulu d0,d7
.dn4
 swap d7
 add.w d7,d5

 sub.w d4,d5
 bge.s .okp6
 neg.w d5
 mulu d1,d5
 neg.l d5
 bra.s .dn6
.okp6
 mulu d1,d5
.dn6
 swap d5
 add.w d5,d4

 sub.w d3,d4
 bge.s .okp7
 neg.w d4
 mulu d2,d4
 neg.l d4
 bra.s .dn7
.okp7
 mulu d2,d4
.dn7
 swap d4
 add.w d4,d3
 
SIMPLE:
 
 move.l (a7)+,d7
 move.w d6,d4
 move.w d7,d5
 asl.w #4,d5
 add.w d4,d5

 lsr.b #2,d3
 move.b d3,(a0,d5.w)


 addq #1,d6
 cmp.w #8,d6
 ble DOWN
 addq #1,d7
 cmp.w #8,d7
 ble ACROSS

 move.l #LIGHTMAP,a0
 move.l #SMOOTHLIGHTMAP,a1
 move.w #7,d0
DOWNSQUARES:
 swap d0
 move.w #7,d0
 move.l a0,a2
ACROSSSQUARES:
 moveq #0,d4
 move.b 16(a2),d4	;bl
 moveq #0,d2
 move.b (a2)+,d2	;tl
 moveq #0,d3
 move.b (a2),d3		;tr
 moveq #0,d5
 move.b 16(a2),d5	;br
 sub.w d2,d3
 sub.w d4,d5
 swap d2
 swap d3
 swap d4
 swap d5

 asr.l #3,d3
 asr.l #3,d5
 moveq #7,d7
ACROSSSQUARE
 move.l d2,d1
 move.l d4,d6
 sub.l d1,d6
 asr.l #3,d6

 swap d1
 move.b d1,(a1)+
 swap d1
 add.l d6,d1
 swap d1
 move.b d1,256-1(a1)
 swap d1
 add.l d6,d1
 swap d1
 move.b d1,256*2-1(a1)
 swap d1
 add.l d6,d1
 swap d1
 move.b d1,256*3-1(a1)
 swap d1
 add.l d6,d1
 swap d1
 move.b d1,256*4-1(a1)
 swap d1
 add.l d6,d1
 swap d1
 move.b d1,256*5-1(a1)
 swap d1
 add.l d6,d1
 swap d1
 move.b d1,256*6-1(a1)
 swap d1
 add.l d6,d1
 swap d1
 move.b d1,256*7-1(a1)
 
 add.l d3,d2
 add.l d5,d4
 dbra d7,ACROSSSQUARE

 dbra d0,ACROSSSQUARES
 add.w #16,a0
 add.w #(256*8)-64,a1
 swap d0
 dbra d0,DOWNSQUARES
*****************************


 move.l #LEFTRIGHT,a0
 move.w #15,d0
emptyright:
 move.l #-1,(a0)+
 move.l #-1,(a0)+
 move.l #-1,(a0)+
 move.l #-1,(a0)+
 move.l #-1,(a0)+
 move.l #-1,(a0)+
 move.l #-1,(a0)+
 move.l #-1,(a0)+
 move.l #-1,(a0)+
 move.l #-1,(a0)+
 move.l #-1,(a0)+
 move.l #-1,(a0)+
 move.l #-1,(a0)+
 move.l #-1,(a0)+
 move.l #-1,(a0)+
 move.l #-1,(a0)+
 dbra d0,emptyright

 move.w #0,d0
 move.w #1,d1
 bsr CALCLINE
 move.w #1,d0
 move.w #2,d1
 bsr CALCLINE
 move.w #2,d0
 move.w #3,d1
 bsr CALCLINE
 move.w #3,d0
 move.w #0,d1
 bsr CALCLINE
 
 move.l #LEFTRIGHT,a0
 move.l FASTBUFFER,a1
 move.l #LEFTUVS,a3
 move.l #TEXTURES,a5
 move.w TEXTUREADD,d0
 move.l #SMOOTHLIGHTMAP,a6
 bge.s .okad
 add.l #65536,a5
 and.w #$7fff,d0
.okad:
 add.w d0,a5
 move.w #255,d7
drawpoly:
 move.w (a0)+,d0	;left end*4
 move.w (a0)+,d1	; right end*4
 blt nolineh
 asr.w #2,d0
 blt nolineh
 asr.w #2,d1
 sub.w d0,d1
 blt nolineh

 move.l (a3),d2
 move.l 4(a3),d3
 move.l (RIGHTUVS-LEFTUVS)(a3),d4
 move.l 4+(RIGHTUVS-LEFTUVS)(a3),d5
 
 sub.l d2,d4
 sub.l d3,d5
 addq #1,d1
 ext.l d1
 divs.l d1,d4
 divs.l d1,d5
 move.l d4,a4
 movem.l d7/a1/a3,-(a7)
 move.l d5,a3
 subq #1,d1
 moveq #0,d4

 lea (a1,d0.w),a1
 
; move.l d2,d5
; swap d5
; and.b #%11111000,d5
; add.w d5,d5
; move.l d3,d6
; swap d6
; asr.w #3,d6
; add.w d6,d5
;
; move.w 16(a2,d5.w),d6
; swap d6
; move.w (a2,d5.w),d6

; move.l (a2,d5.w*2),d6
; move.l 32(a2,d5.w*2),d7
; sub.w d6,d7
; swap d6
; swap d7
; sub.w d6,d7
 
DOING:
 
.putline:

; move.l d2,d0
; swap d0
; and.b #%11111000,d0
; add.w d0,d0
; move.l d3,d4
; swap d4
; asr.w #3,d4
; add.w d4,d0
;
; cmp.w d0,d5
; beq.s .noread
; move.w d0,d5
; move.w 16(a2,d5.w),d6	;tr,br
; swap d6
; move.w (a2,d5.w),d6	;tl,bl

; move.l (a2,d5.w*2),d6
; move.l 32(a2,d5.w*2),d7
; sub.w d6,d7
; swap d6
; swap d7
; sub.w d6,d7
.noread:

; move.l d3,d0
; swap d0
; asl.l #5,d0
; and.w #%11100000,d0
; move.w d0,d7
; add.w d6,d0
; move.w (a6,d0.w*2),d4
; swap d6
; add.w d6,d7
; swap d6
; move.b (a6,d7.w*2),d4
; 
; move.l d2,d0
; swap d0
; asl.l #5,d0
; and.w #%11100000,d0
; add.w d0,d4
; move.w (a6,d4.w*2),d4
 
; move.w d0,d4
; muls d7,d0
; asr.w #3,d0
; add.w d6,d0	; top bright
; 
; swap d7
; swap d6
; muls d7,d4
; asr.w #3,d4
; add.w d6,d4	; bot bright
; swap d7
; swap d6
;
; sub.w d0,d4	;bot-top
; move.w d4,d1
;
; move.l d3,d4
; swap d4
; and.b #%111,d4
; muls d1,d4
; asr.w #3,d4
; add.w d0,d4
; lsl.w #8,d4
 
 move.l d2,d0
 lsr.l #8,d0
 swap d3
 move.b d3,d0
 move.b (a6,d0.w),d4
 asl.w #8,d4
 swap d3
 add.l a3,d3
 move.b (a5,d0.w*4),d4
 add.l a4,d2
 move.b TEXTUREPAL(pc,d4.w),(a1)+
 dbra d1,.putline

 movem.l (a7)+,d7/a1/a3
nolineh
 add.w #320,a1
 add.w #16,a3
 dbra d7,drawpoly
 bra PASTIT

TEXTUREPAL: incbin "ab3:includes/newtexturemaps.pal"

PASTIT:
NOPOLYGON:
 move.l (a7)+,a0
 move.l (a7)+,d7
 dbra d7,POLYGONLOOP


 move.l FASTBUFFER,a0
 add.l #40*320,a0
 move.l #RAWSCRN+40*40,a1
 move.l #(320/8)-1,d0
 move.l #175,d1
 move.w #0,d2
 move.w #0,d3
 moveq #0,d4
 moveq #0,d5
donebigconv
 jsr CHUNKYTOPLANAR 
 
 move.l FASTBUFFER,a0
 add.l #40*320,a0
 
 move.w #((320*176)/64)-1,d0
 moveq #0,d1
clrchunk:
 move.l d1,(a0)+
 move.l d1,(a0)+
 move.l d1,(a0)+
 move.l d1,(a0)+
 move.l d1,(a0)+
 move.l d1,(a0)+
 move.l d1,(a0)+
 move.l d1,(a0)+
 move.l d1,(a0)+
 move.l d1,(a0)+
 move.l d1,(a0)+
 move.l d1,(a0)+
 move.l d1,(a0)+
 move.l d1,(a0)+
 move.l d1,(a0)+
 move.l d1,(a0)+
 dbra d0,clrchunk
 

	btst #7,$bfe001
	beq.s exit_closescr


	add.l #$8000,lmxoff
	cmp.l #40*65536,lmxoff
	blt.s .oksm
	sub.l #40*65536,lmxoff	
.oksm

	bra loop
	
lmxoff: dc.l 0

exit_closescr
	move.l	MyScreen(pc),a0
	CALLINT CloseScreen

exit_closeall
	move.l	_GfxBase(pc),a1
	CALLEXEC CloseLibrary

exit_closeint
	move.l	_IntuitionBase(pc),a1
	CALLEXEC CloseLibrary

exit_false
	move.l	#0,d0				return code
	rts
	
XCOS: dc.w 0
YCOS: dc.w 0
XSIN: dc.w 0
YSIN: dc.w 0
XADD: dc.l 0
YADD: dc.l 0
ZADD: dc.l 0
XOFF: dc.w 0
YOFF: dc.w 0
OLDXM: dc.w 0
OLDYM: dc.w 0

TEXTUREADD: dc.w 0

CALCLINE:

 moveq #0,d2
 moveq #0,d3
 moveq #0,d4
 moveq #0,d5
 move.l #UVCOORDS,a0
 move.w (a0,d0.w*4),d2
 swap d2
 move.w 2(a0,d0.w*4),d3
 swap d3
 move.w (a0,d1.w*4),d4
 swap d4
 move.w 2(a0,d1.w*4),d5
 swap d5
 
 move.l #ONSCREENPTS,a1
 move.w 2(a1,d0.w*4),d6	; ly
 move.w 2(a1,d1.w*4),d7	; ry
 
 asr.w #2,d6
 move.l #LEFTRIGHT+2,a2
 move.l #RIGHTUVS,a3
 asr.w #2,d7
 cmp.w d6,d7
 beq .noline
 bgt.s .lineonright
.lineonleft:
 move.l #LEFTUVS,a3
 subq #2,a2
 exg d6,d7
 exg d0,d1
 exg d2,d4
 exg d3,d5 
 
***********
* THROW AWAY ABOVE FOR NOW.
***********
.lineonright:
 sub.w d6,d7
 lea (a2,d6.w*4),a2

 movem.l d0-d7/a0-a6,-(a7)
 move.l #SUBSTACK,a0
 asl.w #2,d0
 asl.w #2,d1
 move.l #ROTATEDPTS,a1
 move.l a0,a2
 move.l 4(a1,d0.w*4),(a2)+	;ty
 move.l 8(a1,d0.w*4),(a2)+	;tz
 move.l 4(a1,d1.w*4),(a2)+	;by
 move.l 8(a1,d1.w*4),(a2)+	;bz
 move.l d2,(a2)+		;tu
 move.l d3,(a2)+		;tv
 move.l d4,(a2)+		;bu
 move.l d5,(a2)+		;bv
 move.l (a1,d0.w*4),(a2)+	;tx
 move.l (a1,d1.w*4),(a2)+	;bx
 move.l #0,a5
 bsr SUBDIVIDE
 move.l a5,MAXSUB

 movem.l (a7)+,d0-d7/a0-a6

 move.w (a1,d0.w*4),d2
 move.w 2(a1,d0.w*4),d3
 move.w (a1,d1.w*4),d4
 move.w 2(a1,d1.w*4),d5
 
 sub.w d2,d4	;dx
 sub.w d3,d5	;dy
 		;d7=ddy
 
 subq #1,d7
 swap d4
 clr.w d4
 swap d2
 clr.w d2
 asl.l #2,d4
 ext.l d5
 divs.l d5,d4	;dx/dy
.putinleftline
 swap d2
 move.w d2,(a2)
 addq #4,a2
 swap d2
 add.l d4,d2
 dbra d7,.putinleftline

.noline:
 rts
 
MAXSUB: dc.l 0
 
SUBDIVIDE:
 add.l #1,a5
 move.l (a0),d0
 move.l d0,d4
 move.l 4(a0),d1
 divs d1,d0
 move.l 8(a0),d2
 add.l d2,d4
 and.b #%11111100,d0
 move.l d2,40+8(a0)
 add.w #128*4,d0
 move.l 12(a0),d3
 asr.l #1,d4	; middle y
 move.l d3,40+12(a0)
 divs d3,d2

 and.b #%11111100,d2
 add.w #128*4,d2

 move.l d1,12(a3,d0.w*4)
 move.l d3,12(a3,d2.w*4)
 add.l d1,d3
 asr.l #1,d3
 
 move.l 16(a0),d5
 move.l d5,(a3,d0.w*4)
 move.l 24(a0),d6
 move.l d6,24+40(a0)
 add.l d6,d5
 asr.l #1,d5
 move.l d5,(a3,d2.w*4)
 
 move.l 20(a0),d6
 move.l d6,4(a3,d0.w*4)
 move.l 28(a0),d7
 move.l d7,28+40(a0)
 add.l d7,d6
 asr.l #1,d6
 move.l d7,4(a3,d2.w*4)
 
 move.l 32(a0),d7
 move.l d7,8(a3,d0.w*4)
 move.l 36(a0),d1
 move.l d1,36+40(a0)
 add.l d1,d7
 asr.l #1,d7
 move.l d1,8(a3,d2.w*4)
 
 sub.w d0,d2
 sub.w #4,d2
 ble.s .nomore

 move.l d4,40(a0)  ;my
 move.l d4,8(a0)
 
 move.l d3,40+4(a0)	;mz
 move.l d3,12(a0)
 move.l d5,40+16(a0)
 move.l d5,16+8(a0)
 move.l d6,40+20(a0)
 move.l d6,20+8(a0)
 move.l d7,40+32(a0)
 move.l d7,36(a0)
 
 add.l #40,a0
 bsr SUBDIVIDE
 sub.l #1,a5
 sub.l #40,a0
 bsr SUBDIVIDE
.nomore
 rts

**********************************************************

UVCOORDS: ds.l 4
ROTATEDPTS: ds.l 4*4
ONSCREENPTS: ds.l 4

ZOFF: dc.w 512

LEFTRIGHT: ds.l 256

POLYGONDATA:

 dc.w 3
 dc.w 3*256+3
 dc.w -256,128,128,0,0
 dc.w 256,128,128,63,0
 dc.w 256,128,-128,63,63
 dc.w -256,128,-128,0,63

 dc.w 3*256+2
 dc.w -256,-128,-128,0,0
 dc.w -256,-128,128,63,0
 dc.w -256,128,128,63,63
 dc.w -256,128,-128,0,63

 dc.w 3*256+2
 dc.w 256,-128,128,0,0
 dc.w 256,-128,-128,63,0
 dc.w 256,128,-128,63,63
 dc.w 256,128,128,0,63

 dc.w 3*256+2
 dc.w 128,-256,128,0,0
 dc.w 128,-256,-128,63,0
 dc.w 256,-128,-128,63,63
 dc.w 256,-128,128,0,63

 
SINETABLE:
 incbin "ab3:includes/bigsine"
 
SHADOWBUFFER: ds.l 65536/4
 
YANG: dc.w 0
XANG: dc.w 0

**********************************************************

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

 include "ab3:source_4000/chunky.s"

willy: ds.w 49


PALS:
 ds.l 2*49

 
FRAME: dc.w 4
FLIBBLE: dc.w 0

LIGHTMAP:
 dc.w 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
 dc.w 0,31,0,31,0,0,0,0,0,0,0,0,0,0,0,0
 dc.w 0,31,31,31,0,0,0,0,0,0,0,0,0,0,0,0
 dc.w 0,31,0,31,0,0,0,0,0,0,0,0,0,0,0,0
 dc.w 0,31,0,31,0,0,0,0,0,0,0,0,0,0,0,0
 dc.w 0,31,0,31,0,0,0,0,0,0,0,0,0,0,0,0
 dc.w 0,31,31,31,0,0,0,0,0,0,0,0,0,0,0,0
 dc.w 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
 dc.w 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
 dc.w 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
 dc.w 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
 dc.w 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
 dc.w 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
 dc.w 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
 dc.w 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
 dc.w 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0

SMOOTHLIGHTMAP:
 ds.b 256*256

SOLIDMAP:
 ds.b 40*40*8

FASTBUFFER:
 dc.l fasty
 
fasty: ds.b 320*256

SUBSTACK: ds.l 10*100

LEFTUVS: ds.l 4*256
RIGHTUVS: ds.l 4*256
 
WORLD: incbin "ab3:includes/world"

TWEEN: incbin "ab3:includes/tweenbrightfile"
 
TEXTURES: incbin "ab3:includes/newtexturemaps"
 
 SECTION BGDROP,code_c
 
RAWSCRN:
 ds.l 2560*8
