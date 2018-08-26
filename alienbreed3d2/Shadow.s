
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
 
; btst #6,$bfe001
; beq.s .SHIFTABOUT
 
 
 
 muls #8190,d0
 divs #160,d0
 add.w d0,YANG
 and.w #8190,YANG
 muls #8190,d1
 divs #160,d1
 and.w #8190,d1
 add.w d1,XANG
 and.w #8190,XANG
 
 add.w #40,AANG
 add.w #70,BANG
 and.w #8191,AANG
 and.w #8191,BANG

 add.w #60,CANG
 add.w #90,DANG
 and.w #8191,CANG
 and.w #8191,DANG

 
 bra .ROTABOUT
.SHIFTABOUT

 add.w d0,XOFF
 add.w d1,ZOFF
 
 
.ROTABOUT

************************************************
************************************************
************************************************
************************************************
************************************************
************************************************
************************************************
************************************************
************************************************
************************************************
************************************************
************************************************
************************************************
************************************************

*SHADOW BUFFER CALCULATION

 move.w #254,HIGHPOLY

 move.l #POLYGONDATA,a0
 move.w (a0)+,d7	; number of polys
POLYGONLOOPSHAD:
 move.l d7,-(a7)

 move.w (a0)+,TEXTUREADD
 move.w (a0)+,d6
 move.w (a0)+,TRANSTEXT
 
 move.l #ROTATEDPTS,a2
 move.l #UVCOORDS,a3

 move.w AANG,d1
 move.w BANG,d3
 cmp.w #2,d6
 bne.s .notsecrot
 move.w CANG,d1
 move.w DANG,d3
.notsecrot
 move.l #SINETABLE,a1
 move.w (a1,d1.w),XSIN	;xsin
 move.w (a1,d3.w),YSIN	;ysin
 
 add.w #2048,a1
 move.w (a1,d1.w),XCOS	;xcos
 move.w (a1,d3.w),YCOS	;ycos
 
 moveq #3,d7
 tst.w d6
 beq NOROTATESHAD
 
ROTPTLOPSHAD:

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

 dbra d7,ROTPTLOPSHAD

 bra ROTATEDSHAD
 
NOROTATESHAD:
 move.w (a0)+,d0
 move.w (a0)+,d1
 move.w (a0)+,d2
 
 ext.l d0
 ext.l d1
 ext.l d2
 asl.l #8,d0
 asl.l #8,d1
 asl.l #1,d0
 asl.l #1,d1
 move.l d0,(a2)+
 move.l d1,(a2)+
 move.l d2,(a2)+
 addq #4,a2
 move.l (a0)+,(a3)+
 
 dbra d7,NOROTATESHAD

ROTATEDSHAD:
 

 move.l a0,-(a7)

 moveq #3,d7
 move.l #ROTATEDPTS,a0
 
 move.l #20000,d3	;top
 move.l #-20000,d4	;bottom
 
 move.l #-5000,d5
 
FINDTB:

 move.l 8(a0),d0
 asr.l #2,d0
 cmp.l d0,d3
 ble.s .oktop
 move.l d0,d3
.oktop:
 cmp.l d0,d4
 bge.s .okbot
 move.l d0,d4
.okbot:

 move.l 4(a0),d0
 asr.l #8,d0
 asr.l #3,d0
 cmp.l d0,d5
 bgt.s .okhigh
 move.l d0,d5
.okhigh:

 adda.w #16,a0

 dbra d7,FINDTB
 
; add.w #128,d5
; move.w d5,HIGHPOLY
 
 add.w #128,d3
 add.w #128,d4
 move.w d3,TOPLINE
 move.w d4,BOTLINE
 
 move.w #0,d0
 move.w #1,d1
 bsr SIMPLESHADLINE
 move.w #1,d0
 move.w #2,d1
 bsr SIMPLESHADLINE
 move.w #2,d0
 move.w #3,d1
 bsr SIMPLESHADLINE
 move.w #3,d0
 move.w #0,d1
 bsr SIMPLESHADLINE

***********************************************
* Draw the shadow polygon

 move.l #SHADOWBUFFER,a2
 move.l #LEFTUVS,a0
 move.w TOPLINE,d0
 move.w BOTLINE,d1
 sub.w d0,d1
 asl.w #3,d0
 add.w d0,a0
 muls #(256/8),d0
 add.l d0,a2	; pointer to screen line.

 subq #1,d1
 blt NOPOLYGONSHAD
 
DOAHORLINESHAD:
 swap d1

 move.w RIGHTUVS-LEFTUVS(a0),d0
 move.w (a0)+,d7
 sub.w d7,d0
 blt NOPOLYGONSHAD
 
 move.l a2,-(a7)
 
; asr.w #2,d0
; asr.w #2,d7
 add.w d7,a2
 ext.l d0
 addq #1,d0
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 move.w RIGHTUVS-LEFTUVS(a0),d7
 move.w (a0)+,d4
 swap d7
 clr.w d7
 swap d4
 clr.w d4
 sub.l d4,d7
 divs.l d0,d7
 move.l d7,a5
 
 move.w RIGHTUVS-LEFTUVS(a0),d7
 swap d7
 clr.w d7
 move.w (a0)+,d5
 swap d5
 clr.w d5
 sub.l d5,d7
 divs.l d0,d7
 move.l d7,a6
 
 move.w RIGHTUVS-LEFTUVS(a0),d7
 swap d7
 clr.w d7
 move.w (a0)+,d6
 swap d6
 clr.w d6
 sub.l d6,d7
 divs.l d0,d7
 move.l d7,a3
 
 move.l a0,-(a7)
 move.l d1,-(a7)
 move.l #TEXTURES,a0
 move.w TEXTUREADD,d7
 bge.s .okaddtes
 and.w #$7fff,d7
 add.l #65536,a0
.okaddtes:
 add.w d7,a0
 move.w #0,d7
 
 subq #1,d0
 
; d0=xdist
; d4=U  a5=DU
; d5=V  a6=DV
; d6=Y  a3=DY
 moveq #0,d1

PLOTADOT:

.across

 swap d4
 swap d5
 move.w d4,d2
 lsl.w #8,d2
 swap d4
 move.b d5,d2
 add.l a5,d4
 swap d5
 add.l a6,d5

 
 swap d6
 move.b (a2)+,d1
 tst.b (a0,d2.w*4)
 beq.s .noplt
 cmp.w d1,d6
 bgt.s .noplt
 move.b d6,-1(a2)
.noplt:
 swap d6
.noplty
 add.l a3,d6

 dbra d0,.across
 
 move.l (a7)+,d1
 move.l (a7)+,a0
 move.l (a7)+,a2
 
.noline:
 add.w #256,a2
 
 swap d1
 dbra d1,DOAHORLINESHAD

NOPOLYGONSHAD:

***********************************************
 move.l (a7)+,a0
 move.l (a7)+,d7
 
 sub.w #1,HIGHPOLY
 dbra d7,POLYGONLOOPSHAD




************************************************
************************************************
************************************************
************************************************
************************************************
************************************************
************************************************
************************************************
************************************************
************************************************
************************************************
************************************************
************************************************
************************************************
************************************************
************************************************
************************************************

 move.w #254,HIGHPOLY

 move.l #POLYGONDATA,a0
 move.w (a0)+,d7	; number of polys
POLYGONLOOP:
 move.l d7,-(a7)

 move.w (a0)+,TEXTUREADD
 move.w (a0)+,d6
 move.w d6,SPINAROUND
 move.w (a0)+,TRANSTEXT
 move.l #ROTATEDPTS,a2
 move.l #UVCOORDS,a3



 move.w AANG,d1
 move.w BANG,d3
 cmp.w #2,d6
 bne.s .notsecrot
 move.w CANG,d1
 move.w DANG,d3
.notsecrot
 move.l #SINETABLE,a1
 move.w (a1,d1.w),XSIN	;xsin
 move.w (a1,d3.w),YSIN	;ysin
 
 add.w #2048,a1
 move.w (a1,d1.w),XCOS	;xcos
 move.w (a1,d3.w),YCOS	;ycos

 moveq #3,d7
 move.w d6,d0
 move.l #-5000,d6
 tst.w d0
 beq NOROTATE


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

 move.l d1,d5
 asr.l #8,d5
 asr.l #3,d5
 cmp.w d5,d6
 bgt.s .okhigh
 move.w d5,d6
.okhigh:

 
 move.l (a0)+,(a3)+

 dbra d7,ROTPTLOP

 bra ROTATED
 
NOROTATE:
 move.w (a0)+,d0
 move.w (a0)+,d1
 move.w (a0)+,d2
 
 ext.l d0
 ext.l d1
 ext.l d2
 asl.l #8,d0
 asl.l #8,d1
 asl.l #1,d0
 asl.l #1,d1
 move.l d0,(a2)+
 move.l d1,(a2)+
 move.l d2,(a2)+
 addq #4,a2
 move.l (a0)+,(a3)+
 
 move.l d1,d5
 asr.l #8,d5
 asr.l #3,d5
 cmp.w d5,d6
 bgt.s .okhigh
 move.w d5,d6
.okhigh:
 
 dbra d7,NOROTATE

ROTATED:

; add.w #128,d6
; move.w d6,HIGHPOLY

 move.l a0,-(a7)

 sub.l #10*4,a0

 move.w XANG,d1
 move.w YANG,d3
 move.l #SINETABLE,a1
 move.w (a1,d1.w),XSIN2	;xsin
 move.w (a1,d3.w),YSIN2	;ysin
 
 add.w #2048,a1
 move.w (a1,d1.w),XCOS2	;xcos
 move.w (a1,d3.w),YCOS2	;ycos



 moveq #3,d7
; move.l #ROTATEDPTS,a0
 move.l #ONSCREENPTS,a1
 move.l FASTBUFFER,a2
 
 move.w #20000,d3	;top
 move.w #-20000,d4	;bottom
 move.w #-5000,d5
 
CONVTOSCREEN:

 movem.l d3-d5,-(a7)

 move.w (a0)+,d0
 move.w d0,d3
 move.w (a0)+,d1
 move.w (a0)+,d2
 addq #4,a0
 move.w d2,d5
 
 tst.w SPINAROUND
 beq.s .NOSPIN

 muls YCOS,d0
 muls YSIN,d2
 sub.l d2,d0
 add.l d0,d0
 swap d0
; asr.l #6,d0	; new x*512
 
 
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
 add.l d1,d1
 swap d1
 
 muls XSIN,d4
 muls XCOS,d5
 add.l d5,d4
 add.l d4,d4
 swap d4
 move.w d4,d2	; new z
 
 move.w d0,d3
 move.w d2,d5
 
.NOSPIN

 muls YCOS2,d0
 muls YSIN2,d2
 sub.l d2,d0
 asr.l #6,d0	; new x*512
 
 muls YSIN2,d3
 muls YCOS2,d5
 add.l d5,d3
 add.l d3,d3
 swap d3
 move.w d3,d2	; new z

 move.w d1,d4
 move.w d2,d5
 muls XCOS2,d1
 muls XSIN2,d2
 sub.l d2,d1
 asr.l #6,d1	; new y*512
 
 muls XSIN2,d4
 muls XCOS2,d5
 add.l d5,d4
 add.l d4,d4
 swap d4
 move.w d4,d2	; new z

; 3 7 15 21 35 45

 ext.l d2
 movem.l (a7)+,d3-d5

; move.l (a0)+,d0
; move.l (a0)+,d1
; move.l (a0)+,d2
 
; move.l d1,d6
; asr.l #8,d6
; asr.l #3,d6
; cmp.w d6,d5
; bgt.s .okhigh
; move.w d6,d5
;.okhigh:
 
 add.w ZOFF,d2
 ext.l d2
; addq #4,a0  

 add.l d0,d0
 add.l d1,d1

 divs d2,d0
 divs d2,d1
 add.w #160*4,d0
 add.w #128*4,d1
 move.w d0,(a1)+
 move.w d1,(a1)+
 
 asr.w #2,d1
 
 cmp.w d1,d3
 ble.s .oktop
 move.w d1,d3
.oktop

 cmp.w d1,d4
 bge.s .okbot
 move.w d1,d4
.okbot:
 
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
 
 
 move.w d3,TOPLINE
 move.w d4,BOTLINE
 
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
 
 move.l #ROTATEDPTS,a1
 move.l (a1),d3
 sub.l 16(a1),d3
 asr.l #8,d3
 asr.l #1,d3
 move.l 4(a1),d4
 sub.l 16+4(a1),d4
 asr.l #8,d4
 asr.l #1,d4
 move.l 8(a1),d5
 sub.l 16+8(a1),d5
 
 move.w d3,d6
 muls d6,d6
 move.w d4,d7
 muls d7,d7
 add.l d7,d6
 move.w d5,d7
 muls d7,d7
 add.l d7,d6
 move.l d6,d2
 bsr CALCSQROOT
 move.w d2,LEN1

 move.l 32(a1),d0
 sub.l 16(a1),d0
 asr.l #8,d0
 asr.l #1,d0
 move.l 32+4(a1),d1
 sub.l 16+4(a1),d1
 asr.l #8,d1
 asr.l #1,d1
 move.l 32+8(a1),d2
 sub.l 16+8(a1),d2
 
 muls d2,d3
 muls d0,d5
 sub.l d3,d5	; length
 muls.l #25,d5
 
 muls d0,d0
 muls d1,d1
 muls d2,d2
 add.l d0,d1
 add.l d1,d2
 bsr CALCSQROOT
 
 muls LEN1,d2
 divs.l d2,d5

 tst.l d5
 ble.s .okbr
 moveq #0,d5
.okbr:
 add.w #25,d5
 
 asl.w #8,d5
 move.w d5,BRIGHTNESS

 move.w #0,d0
 move.w #1,d1
 bsr SIMPLECALCLINE
 move.w #1,d0
 move.w #2,d1
 bsr SIMPLECALCLINE
 move.w #2,d0
 move.w #3,d1
 bsr SIMPLECALCLINE
 move.w #3,d0
 move.w #0,d1
 bsr SIMPLECALCLINE
 
 

***********************************************
* Draw the polygon (shadowed).

 move.l FASTBUFFER,a2
 move.l #LEFTUVS,a0
 move.w TOPLINE,d0
 move.w BOTLINE,d1
 sub.w d0,d1
 asl.w #4,d0
 add.w d0,a0
 muls #(320/16),d0
 add.l d0,a2	; pointer to screen line.

 subq #1,d1
 blt NOPOLYGON
 
DOAHORLINE:
 swap d1

 move.w RIGHTUVS-LEFTUVS(a0),d0
 move.w (a0)+,d7
 sub.w d7,d0
 bge.s .okflibble
 
 add.w #14,a0
 add.w #320,a2
 swap d1
 dbra d1,DOAHORLINE
 bra NOPOLYGON
 
.okflibble:
 
 move.l a2,-(a7)
 
 asr.w #2,d0
 asr.w #2,d7
 add.w d7,a2
 ext.l d0
 addq #1,d0
 
 move.l RIGHTUVS-LEFTUVS(a0),d7
 move.l (a0)+,d2 
 sub.l d2,d7
 divs.l d0,d7
 move.l d7,a1

 move.l RIGHTUVS-LEFTUVS(a0),d7 
 move.l (a0)+,d3 
 sub.l d3,d7
 divs.l d0,d7
 move.l d7,a4
 
 move.w RIGHTUVS-LEFTUVS(a0),d7
 move.w (a0)+,d4
 swap d7
 clr.w d7
 swap d4
 clr.w d4
 sub.l d4,d7
 divs.l d0,d7
 move.l d7,a5
 
 move.w RIGHTUVS-LEFTUVS(a0),d7
 swap d7
 clr.w d7
 move.w (a0)+,d5
 swap d5
 clr.w d5
 sub.l d5,d7
 divs.l d0,d7
 move.l d7,a6
 
 move.w RIGHTUVS-LEFTUVS(a0),d7
 swap d7
 clr.w d7
 move.w (a0)+,d6
 swap d6
 clr.w d6
 sub.l d6,d7
 divs.l d0,d7
 move.l d7,a3
 
 move.l a0,-(a7)
 move.l d1,-(a7)
 move.l #TEXTURES,a0
 move.w TEXTUREADD,d7
 bge.s .okaddtes
 and.w #$7fff,d7
 add.l #65536,a0
.okaddtes:
 add.w d7,a0
 move.w #0,d7
 
 move.w BRIGHTNESS,a6
 
 move.l a7,SAVESTACK
 move.l #SHADOWBUFFER,a7
 
 subq #1,d0
 
; d0=xdist
; d2=U	a1=DU
; d3=V  a4=DV
; d4=X  a5=DX
; d5=Y  a6=DY
; d6=Z  a3=DZ
 move.w HIGHPOLY,d5

.across

 moveq #0,d1
 swap d6
 move.w d6,d1
 lsl.w #8,d1
 swap d4
 move.b d4,d1
 swap d4
 swap d6
 add.l a5,d4
 add.l a3,d6

 moveq #0,d7
; swap d5
 move.b (a7,d1.l),d7
 cmp.w d7,d5
 ble.s .noshad
 move.w #$1900,d7
 swap d2
 move.w d2,d1
 asl.w #8,d1
 swap d3
 move.b d3,d1
 swap d2
; and.w #$3f3f,d1
 swap d3
 add.l a1,d2
 add.l a4,d3
 
 move.b (a0,d1.w*4),d7
 beq.s .noplottt

 move.b TEXTUREPAL(pc,d7.w),(a2)+
 dbra d0,.across
 bra.s .PASTAC 
 
.noshad:
; swap d5
; add.l a6,d5
 move.w a6,d7
 swap d2
 move.w d2,d1
 asl.w #8,d1
 swap d3
 move.b d3,d1
 swap d2
 and.w #$3f3f,d1
 swap d3
 add.l a1,d2
 add.l a4,d3
 
 move.b (a0,d1.w*4),d7
 beq.s .noplottt

 move.b TEXTUREPAL(pc,d7.w),(a2)+
 dbra d0,.across

 bra.s .PASTAC

.noplottt:
 addq #1,a2
 dbra d0,.across
 
.PASTAC
 
 move.l SAVESTACK,a7
 
 move.l (a7)+,d1
 move.l (a7)+,a0
 move.l (a7)+,a2
 
.noline:
 add.w #320,a2
 
 swap d1
 dbra d1,DOAHORLINE
 

 bra NOPOLYGON

TEXTUREPAL: incbin "ab3:includes/newtexturemaps.pal"

SAVESTACK: dc.l 0
HIGHPOLY: dc.w 0
LEN1: dc.w 0
BRIGHTNESS: dc.l 0
TRANSTEXT: dc.w 0
AANG: dc.w 0
BANG: dc.w 0
CANG: dc.w 0
DANG: dc.w 0

NOPOLYGON:

***********************************************
 move.l (a7)+,a0
 move.l (a7)+,d7
 
 sub.w #1,HIGHPOLY
 
 dbra d7,POLYGONLOOP

 btst #6,$bfe001
 beq.s .SHOWSHADOW

 move.l FASTBUFFER,a0
 add.l #40*320+64,a0
 move.l #RAWSCRN+40*40+8,a1
 move.l #(24)-1,d0
 move.l #175,d1
 move.w #128,d2
 move.w #16,d3
 moveq #0,d4
 moveq #0,d5
 jsr CHUNKYTOPLANAR 

 bra .SHOWNSCRN

.SHOWSHADOW

 move.l #SHADOWBUFFER,a0
 add.l #40*256,a0
 move.l #RAWSCRN+40*40,a1
 move.l #(256/8)-1,d0
 move.l #175,d1
 move.w #0,d2
 move.w #8,d3
 moveq #0,d4
 moveq #0,d5
 jsr CHUNKYTOPLANAR 

.SHOWNSCRN:
 
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
 
 move.l #SHADOWBUFFER,a0
 move.l #-1,d1
 move.l #-1,d2
 move.w #15,d0
clrshad:
 move.w #15,d5
innner
 move.l d2,(a0)+
 move.l d2,(a0)+
 move.l d2,(a0)+
 move.l d2,(a0)+
 move.l d1,(a0)+
 move.l d1,(a0)+
 move.l d1,(a0)+
 move.l d1,(a0)+
 move.l d2,(a0)+
 move.l d2,(a0)+
 move.l d2,(a0)+
 move.l d2,(a0)+
 move.l d1,(a0)+
 move.l d1,(a0)+
 move.l d1,(a0)+
 move.l d1,(a0)+
 move.l d2,(a0)+
 move.l d2,(a0)+
 move.l d2,(a0)+
 move.l d2,(a0)+
 move.l d1,(a0)+
 move.l d1,(a0)+
 move.l d1,(a0)+
 move.l d1,(a0)+
 move.l d2,(a0)+
 move.l d2,(a0)+
 move.l d2,(a0)+
 move.l d2,(a0)+
 move.l d1,(a0)+
 move.l d1,(a0)+
 move.l d1,(a0)+
 move.l d1,(a0)+
 move.l d2,(a0)+
 move.l d2,(a0)+
 move.l d2,(a0)+
 move.l d2,(a0)+
 move.l d1,(a0)+
 move.l d1,(a0)+
 move.l d1,(a0)+
 move.l d1,(a0)+
 move.l d2,(a0)+
 move.l d2,(a0)+
 move.l d2,(a0)+
 move.l d2,(a0)+
 move.l d1,(a0)+
 move.l d1,(a0)+
 move.l d1,(a0)+
 move.l d1,(a0)+
 move.l d2,(a0)+
 move.l d2,(a0)+
 move.l d2,(a0)+
 move.l d2,(a0)+
 move.l d1,(a0)+
 move.l d1,(a0)+
 move.l d1,(a0)+
 move.l d1,(a0)+
 move.l d2,(a0)+
 move.l d2,(a0)+
 move.l d2,(a0)+
 move.l d2,(a0)+
 move.l d1,(a0)+
 move.l d1,(a0)+
 move.l d1,(a0)+
 move.l d1,(a0)+
 dbra d5,innner
 exg d1,d2

 dbra d0,clrshad

 

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

*********************************************

CALCSQROOT:
 tst.l d2
 beq .oksqr

 movem.l d0/d1/d3-d7/a0-a6,-(a7)

 move.w #31,d0
.findhigh
 btst d0,d2
 bne .foundhigh
 dbra d0,.findhigh
.foundhigh
 asr.w #1,d0
 clr.l d3
 bset d0,d3
 move.l d3,d0

 move.w d0,d1
 muls d1,d1	; x*x
 sub.l d2,d1	; x*x-a
 asr.l #1,d1	; (x*x-a)/2
 divs d0,d1	; (x*x-a)/2x
 sub.w d1,d0	; second approx
 bgt .stillnot0
 move.w #1,d0
.stillnot0

 move.w d0,d1
 muls d1,d1
 sub.l d2,d1
 asr.l #1,d1
 divs d0,d1
 sub.w d1,d0	; second approx
 bgt .stillnot02
 move.w #1,d0
.stillnot02

 move.w d0,d1
 muls d1,d1
 sub.l d2,d1
 asr.l #1,d1
 divs d0,d1
 sub.w d1,d0	; second approx
 bgt .stillnot03
 move.w #1,d0
.stillnot03

 move.w d0,d2
 ext.l d2

 movem.l (a7)+,d0/d1/d3-d7/a0-a6
 
.oksqr
 rts


**********************************************
**********************************************
**********************************************
**********************************************
**********************************************
**********************************************
**********************************************
**********************************************
**********************************************
**********************************************
**********************************************
**********************************************
**********************************************
**********************************************
**********************************************
**********************************************
**********************************************
**********************************************
**********************************************
	
SIMPLECALCLINE:
 move.l #ONSCREENPTS,a1
 move.w 2(a1,d0.w*4),d2		;fy
 move.w 2(a1,d1.w*4),d7		;sy

 move.l #RIGHTUVS,a3
 asr.w #2,d2
 asr.w #2,d7
 cmp.w d2,d7 
 beq .noline
 
 bgt.s .lineonright
.lineonleft:
 move.l #LEFTUVS,a3
 exg d0,d1
 exg d2,d7
 
.lineonright:

 sub.w d2,d7
 asl.w #4,d2
 add.w d2,a3
 
 move.w d7,YDIFF
 
 move.w (a1,d0.w*4),d3		;fx
 move.w (a1,d1.w*4),d7		;sx

 sub.w d3,d7
 swap d3
 swap d7
 clr.w d3
 clr.w d7
 divs.l YDIFF-2,d7
 move.l d7,a0	; dx
 
 move.l #UVCOORDS,a2
 move.l #ROTATEDPTS,a1
 
 move.w (a2,d0.w*4),d4
 move.w 2(a2,d0.w*4),d5
 move.w (a2,d1.w*4),d6
 move.w 2(a2,d1.w*4),d7
 
 sub.w d4,d6
 sub.w d5,d7
 swap d4
 swap d5
 clr.w d4
 clr.w d5
 swap d6
 swap d7
 clr.w d6
 clr.w d7
 
 divs.l YDIFF-2,d6
 divs.l YDIFF-2,d7
 
 move.l d6,a4
 move.l d7,a5
 
 asl.w #4,d0
 asl.w #4,d1
 move.l (a1,d0.w),d6
 
 move.l (a1,d1.w),d7
 asl.l #5,d6
 asl.l #5,d7
 sub.l d6,d7
 divs.l YDIFF-2,d7
 move.l d7,a2
 move.l d6,a6
 
 move.l 4(a1,d0.w),d6
 move.l 4(a1,d1.w),d7
 asl.l #5,d6
 asl.l #5,d7
 sub.l d6,d7
 divs.l YDIFF-2,d7
 exg d7,a6
 exg d7,d6
 
 move.l 8(a1,d0.w),d0
 move.l 8(a1,d1.w),d1
 swap d0
 swap d1
 clr.w d0
 clr.w d1
 asr.l #2,d0
 asr.l #2,d1
 sub.l d0,d1
 divs.l YDIFF-2,d1
 move.l d1,a1
 move.l YDIFF-2,d1
 subq #1,d1
 
; d3=sx a0=dsx
; d4=u a4=du
; d5=v a5=dv
; d6=x a2=dx
; d7=y a6=dy
; d0=z a1=dz
; d1=dsy


 add.l #128*65536,d6
 add.l #128*65536,d7
 add.l #128*65536,d0

.PUTINLINE:
 swap d3
 move.w d3,(a3)+
 swap d3
 add.l a0,d3
 move.l d4,(a3)+
 add.l a4,d4
 move.l d5,(a3)+
 swap d6
 add.l a5,d5
 move.w d6,(a3)+
 swap d6
 swap d7
 add.l a2,d6
 move.w d7,(a3)+
 swap d7
 swap d0
 add.l a6,d7
 move.w d0,(a3)+
 swap d0
 add.l a1,d0
 dbra d1,.PUTINLINE
 
.noline:
 rts
 
TOPLINE: dc.w 0
BOTLINE: dc.w 0



**********************************************
**********************************************
**********************************************
**********************************************
**********************************************
**********************************************
**********************************************
**********************************************
**********************************************
**********************************************
**********************************************
**********************************************
**********************************************
**********************************************
**********************************************
**********************************************
**********************************************
**********************************************
**********************************************
	
SIMPLESHADLINE:
 move.l #ROTATEDPTS,a1
 asl.l #2,d0
 asl.l #2,d1
 move.l 8(a1,d0.w*4),d2		;fz
 move.l 8(a1,d1.w*4),d7		;sz
 
 move.l #LEFTUVS,a3
 asr.l #2,d2
 asr.l #2,d7
 cmp.l d2,d7 
 beq .noline
 
 bgt.s .lineonright
.lineonleft:
 move.l #RIGHTUVS,a3
 exg d0,d1
 exg d2,d7
 
.lineonright:

 sub.w d2,d7
 add.w #128,d2
 lea (a3,d2.w*8),a3
 
 move.w d7,YDIFF
 
 move.l (a1,d0.w*4),d3		;fx
 move.l (a1,d1.w*4),d7		;sx

 asl.l #5,d3
 asl.l #5,d7
 
 sub.l d3,d7
 divs.l YDIFF-2,d7
 move.l d7,a0	; dx
 
 move.l #UVCOORDS,a2
 move.l #ROTATEDPTS,a1
 
 move.w (a2,d0.w),d4
 move.w 2(a2,d0.w),d5
 move.w (a2,d1.w),d6
 move.w 2(a2,d1.w),d7
 
 sub.w d4,d6
 sub.w d5,d7
 swap d4
 swap d5
 clr.w d4
 clr.w d5
 swap d6
 swap d7
 clr.w d6
 clr.w d7
 
 divs.l YDIFF-2,d6
 divs.l YDIFF-2,d7
 
 move.l d6,a4
 move.l d7,a5
 
; asl.w #4,d0
; asl.w #4,d1
 
 move.l 4(a1,d0.w*4),d6
 move.l 4(a1,d1.w*4),d7
 asl.l #5,d6
 asl.l #5,d7
 sub.l d6,d7
 divs.l YDIFF-2,d7
 exg d7,a6
 exg d7,d6
 
 move.l YDIFF-2,d1
 subq #1,d1
 
; d3=x a0=dx
; d4=u a4=du
; d5=v a5=dv
; d7=y a6=dy
; d1=dz

 move.w HIGHPOLY,d7

 add.l #128*65536,d3
; add.l #128*65536,d7

.PUTINLINE:
 swap d3
 move.w d3,(a3)+
 swap d3
 add.l a0,d3
 swap d4
 move.w d4,(a3)+
 swap d4
 swap d5
 add.l a4,d4
 move.w d5,(a3)+
 swap d5
 add.l a5,d5
; swap d7
 move.w d7,(a3)+
; swap d7
; add.l a6,d7
 dbra d1,.PUTINLINE
 
.noline:
 rts
 
	
 dc.w 0
YDIFF: dc.w 0

SPINAROUND: dc.w 0	
XCOS: dc.w 0
YCOS: dc.w 0
XSIN: dc.w 0
YSIN: dc.w 0
XCOS3: dc.w 0
YCOS3: dc.w 0
XSIN3: dc.w 0
YSIN3: dc.w 0
XCOS2: dc.w 0
YCOS2: dc.w 0
XSIN2: dc.w 0
YSIN2: dc.w 0
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

ZOFF: dc.w 1024

LEFTRIGHT: ds.l 256

POLYGONDATA:

 dc.w 27
 
 dc.w $8000+1*256+0
 dc.w 0,0
 dc.w -200,150,200,0,0
 dc.w 0,200,200,63,0
 dc.w 0,250,0,63,63
 dc.w -200,200,0,0,63

 dc.w $8000+0*256+3
 dc.w 0,0
 dc.w 0,200,200,0,0
 dc.w 200,150,200,63,0
 dc.w 200,200,0,63,63
 dc.w 0,250,0,0,63

 dc.w $8000+0*256+3
 dc.w 0,0
 dc.w -200,200,0,0,0
 dc.w 0,250,0,63,0
 dc.w 0,200,-200,63,63
 dc.w -200,150,-200,0,63

 dc.w $8000+1*256+0
 dc.w 0,0
 dc.w 0,250,0,0,0
 dc.w 200,200,0,63,0
 dc.w 200,150,-200,63,63
 dc.w 0,200,-200,0,63

cr EQU 120

****************************


 dc.w 3*256+3
 dc.w 2,0
 dc.w -cr,cr,cr,0,0
 dc.w cr,cr,cr,63,0
 dc.w cr,cr,-cr,63,63
 dc.w -cr,cr,-cr,0,63

; dc.w $8000+0*256+2
; dc.w 2,0
; dc.w cr,-cr,cr,0,0
; dc.w -cr,-cr,cr,63,0
; dc.w -cr,-cr,-cr,63,63
; dc.w cr,-cr,-cr,0,63

 dc.w $8000+0*256+2
 dc.w 2,0
 dc.w cr,cr,cr,16,16
 dc.w cr,-cr,cr,48,16
 dc.w cr,-cr,-cr,48,48
 dc.w cr,cr,-cr,16,48

 dc.w $8000+0*256+2
 dc.w 2,0
 dc.w -cr,-cr,cr,16,16
 dc.w -cr,cr,cr,48,16
 dc.w -cr,cr,-cr,48,48
 dc.w -cr,-cr,-cr,16,48

 dc.w $8000+0*256+2
 dc.w 2,0
 dc.w -cr,-cr,cr,16,16
 dc.w cr,-cr,cr,48,16
 dc.w cr,cr,cr,48,48
 dc.w -cr,cr,cr,16,48

 dc.w $8000+0*256+2
 dc.w 2,0
 dc.w cr,-cr,-cr,16,16
 dc.w -cr,-cr,-cr,48,16
 dc.w -cr,cr,-cr,48,48
 dc.w cr,cr,-cr,16,48

****************************


th equ 40
ir equ 40
ot equ 80

*****************************

; dc.w 3*256+2
; dc.w 1,0
; dc.w -ir,-ir,-th,0,0
; dc.w ir,-ir,-th,63,0
; dc.w ir,-ir,th,63,15
; dc.w -ir,-ir,th,0,15

 dc.w 3*256+2
 dc.w 1,0
 dc.w ir,-ot,-th,0,0
 dc.w ir,ir,-th,63,0
 dc.w ir,ir,th,63,15
 dc.w ir,-ot,th,0,15


 dc.w 3*256+2
 dc.w 1,0
 dc.w ir,ir,-th,0,0
 dc.w -ir,ir,-th,63,0
 dc.w -ir,ir,th,63,15
 dc.w ir,ir,th,0,15


 dc.w 3*256+2
 dc.w 1,0
 dc.w -ir,ir,-th,0,0
 dc.w -ir,-ot,-th,63,0
 dc.w -ir,-ot,th,63,15
 dc.w -ir,ir,th,0,15


*****************************

*******************
; dc.w 3*256+2
; dc.w 1,0
; dc.w -ot,-ot,-th,0,0
; dc.w ot,-ot,-th,63,0
; dc.w ir,-ir,-th,55,7
; dc.w -ir,-ir,-th,7,7

 dc.w 3*256+2
 dc.w 1,0
 dc.w ot,-ot,-th,63,0
 dc.w ot,ot,-th,63,63
 dc.w ir,ir,-th,56,55
 dc.w ir,-ot,-th,56,0

 dc.w 3*256+2
 dc.w 1,0
 dc.w ot,ot,-th,63,63
 dc.w -ot,ot,-th,0,63
 dc.w -ir,ir,-th,8,55
 dc.w ir,ir,-th,55,55

 dc.w 3*256+2
 dc.w 1,0
 dc.w -ot,ot,-th,0,63
 dc.w -ot,-ot,-th,0,0
 dc.w -ir,-ot,-th,7,0
 dc.w -ir,ir,-th,7,55
**********************

*******************
; dc.w 3*256+2
; dc.w 1,0
; dc.w ot,-ot,th,0,0
; dc.w -ot,-ot,th,63,0
; dc.w -ir,-ir,th,55,7
; dc.w ir,-ir,th,7,7

 dc.w 3*256+2
 dc.w 1,0
 dc.w -ot,-ot,th,63,0
 dc.w -ot,ot,th,63,63
 dc.w -ir,ir,th,56,55
 dc.w -ir,-ot,th,56,0

 dc.w 3*256+2
 dc.w 1,0
 dc.w -ot,ot,th,63,63
 dc.w ot,ot,th,0,63
 dc.w ir,ir,th,8,55
 dc.w -ir,ir,th,55,55

 dc.w 3*256+2
 dc.w 1,0
 dc.w ot,ot,th,0,63
 dc.w ot,-ot,th,0,0
 dc.w ir,-ot,th,7,0
 dc.w ir,ir,th,7,55
**********************

*****************************

 dc.w 3*256+2
 dc.w 1,0
 dc.w -ot,ot,-th,0,0
 dc.w ot,ot,-th,63,0
 dc.w ot,ot,th,63,15
 dc.w -ot,ot,th,0,15

 dc.w 3*256+2
 dc.w 1,0
 dc.w -ot,-ot,-th,0,0
 dc.w -ot,ot,-th,63,0
 dc.w -ot,ot,th,63,15
 dc.w -ot,-ot,th,0,15

 dc.w 3*256+2
 dc.w 1,0
 dc.w ot,-ot,-th,0,0
 dc.w ir,-ot,-th,63,0
 dc.w ir,-ot,th,63,15
 dc.w ot,-ot,th,0,15

 dc.w 3*256+2
 dc.w 1,0
 dc.w -ir,-ot,-th,0,0
 dc.w -ot,-ot,-th,63,0
 dc.w -ot,-ot,th,63,15
 dc.w -ir,-ot,th,0,15

 dc.w 3*256+2
 dc.w 1,0
 dc.w ot,ot,-th,0,0
 dc.w ot,-ot,-th,63,0
 dc.w ot,-ot,th,63,15
 dc.w ot,ot,th,0,15


*****************************

****************************


; dc.w $8000+0*256+2
; dc.w 2,0
; dc.w -cr,-cr,cr,0,0
; dc.w cr,-cr,cr,63,0
; dc.w cr,-cr,-cr,63,63
; dc.w -cr,-cr,-cr,0,63

 dc.w 3*256+3
 dc.w 2,0
 dc.w cr,cr,cr,0,0
 dc.w -cr,cr,cr,63,0
 dc.w -cr,cr,-cr,63,63
 dc.w cr,cr,-cr,0,63

 dc.w $8000+0*256+2
 dc.w 2,0
 dc.w -cr,cr,cr,16,16
 dc.w -cr,-cr,cr,48,16
 dc.w -cr,-cr,-cr,48,48
 dc.w -cr,cr,-cr,16,48

 dc.w $8000+0*256+2
 dc.w 2,0
 dc.w cr,-cr,cr,16,16
 dc.w cr,cr,cr,48,16
 dc.w cr,cr,-cr,48,48
 dc.w cr,-cr,-cr,16,48

 dc.w $8000+0*256+2
 dc.w 2,0
 dc.w -cr,-cr,-cr,16,16
 dc.w cr,-cr,-cr,48,16
 dc.w cr,cr,-cr,48,48
 dc.w -cr,cr,-cr,16,48

 dc.w $8000+0*256+2
 dc.w 2,0
 dc.w cr,-cr,cr,16,16
 dc.w -cr,-cr,cr,48,16
 dc.w -cr,cr,cr,48,48
 dc.w cr,cr,cr,16,48


****************************

 
SINETABLE:
 incbin "ab3:includes/bigsine"
 
 
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

SHADOWBUFFER: ds.l 65536/4

PALETTEBIT:
; incbin "256palette"
; dc.w $ffff,$fffe
 
 incbin "ab3:includes/256pal"

 include "ab3:source_4000/chunky.s"

willy: ds.w 48


PALS:
 ds.l 2*49

 
FRAME: dc.w 4
FLIBBLE: dc.w 0

FASTBUFFER:
 dc.l fasty
 
fasty: ds.b 320*256


SUBSTACK: ds.l 10*10*10

LEFTUVS: ds.w 8*256
RIGHTUVS: ds.w 8*256
 
WORLD: incbin "ab3:includes/world"

TWEEN: incbin "ab3:includes/tweenbrightfile"
 
TEXTURES: incbin "ab3:includes/newtexturemaps"
 
 SECTION BGDROP,code_c
 
RAWSCRN:
 ds.l 2560*8
