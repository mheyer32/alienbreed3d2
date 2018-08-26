
SP EQU 1
SPM EQU 1
BS EQU 1
BP EQU 1
SH EQU 0
PH EQU 1
MB EQU 0
AA EQU 0
DQ EQU 1
DB EQU 1
PDQ EQU 1

ScreenWidth EQU 320

LARGESCREEN equ 0


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

SPECULAR EQU SP
SPECMAP EQU SPM
BUMPSPEC EQU BS
BUMPPHONG EQU BP
SHADOWMAP EQU SH
SHADING EQU PH
MOTIONBLUR EQU MB
ANTIALIAS EQU AA
DEPTHQUEUE EQU DQ
DEPTHBALL EQU DB
POLYGONDEPTH EQU PDQ


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
	
 move.l 4.w,a6
 move.l #doslibname,a1
 moveq #0,d0
 jsr -552(a6)
 move.l d0,doslib

 move.l doslib,a6
 move.l #OBJNAME,d1
 move.l #1005,d2
 jsr -30(a6)
 move.l d0,ROTATEDPTS

 move.l doslib,a6
 move.l d0,d1
 move.l #POLYGONDATA,d2
 move.l #30000,d3
 jsr -42(a6)

 move.l doslib,a6
 move.l ROTATEDPTS,d1
 jsr -36(a6)
 
loop:

 move.w #0,temp
 
 move.l #POLYGONDATA,a3
 move.w (a3)+,SORTIT
 move.l a3,START_OF_OBJECT
	
 move.w (a3)+,num_points
 move.w (a3)+,d6
 move.w d6,num_frames
 move.l a3,POINTER_TO_POINTERS
 lea (a3,d6.w*4),a3
 move.l a3,LinesPtr
 moveq #0,d5
 moveq #0,d2
 
 move.l POINTER_TO_POINTERS,a4
 move.w (a4,d5.w*4),d2
 add.l START_OF_OBJECT,d2
 move.l d2,PtsPtr
 move.w 2(a4,d5.w*4),d5
 add.l START_OF_OBJECT,d5
 move.l d5,PolyAngPtr
 move.l d2,a3
 move.w num_points,d5
 
 move.l (a3)+,OBJONOFF
 
 move.l a3,PointAngPtr
 add.w d5,d5
 move.w d5,d2
 add.w d5,d5
 add.w d5,d2
 add.w d2,a3
 move.l a3,PtsPtr
 
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
 divs #320,d0
 add.w d0,YANG
 and.w #8190,YANG
 muls #8190,d1
 divs #320,d1
 and.w #8190,d1
 add.w d1,XANG
 and.w #8190,XANG
 
; add.w #40,AANG
; add.w #70,BANG
; and.w #8191,AANG
; and.w #8191,BANG

; add.w #60,CANG
; add.w #90,DANG
; and.w #8191,CANG
; and.w #8191,DANG

 
 bra .ROTABOUT
.SHIFTABOUT

  muls #8190,d0
 divs #320,d0
 add.w d0,BANG
 and.w #8190,BANG
 muls #8190,d1
 divs #320,d1
 and.w #8190,d1
 add.w d1,AANG
 and.w #8190,AANG

 
.ROTABOUT

 move.w AANG,d1
 move.w BANG,d3
; cmp.w #2,d6
; bne.s .notsecrot
; move.w CANG,d1
; move.w DANG,d3
;.notsecrot
 move.l #SINETABLE,a1
 move.w (a1,d1.w),XSIN	;xsin
 move.w (a1,d3.w),YSIN	;ysin
 
 add.w #2048,a1
 move.w (a1,d1.w),XCOS	;xcos
 move.w (a1,d3.w),YCOS	;ycos

 move.w XANG,d1
 move.w YANG,d3
; cmp.w #2,d6
; bne.s .notsecrot
; move.w CANG,d1
; move.w DANG,d3
;.notsecrot
 move.l #SINETABLE,a1
 move.w (a1,d1.w),XSIN2	;xsin
 move.w (a1,d3.w),YSIN2	;ysin
 
 add.w #2048,a1
 move.w (a1,d1.w),XCOS2	;xcos
 move.w (a1,d3.w),YCOS2	;ycos


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


; First, calculate the normal brightnesses
; for points. NB: -1,-1,-1 = this point not used
; in gouraud shading.

 move.l #NORMBRIGHTS,a2
 move.l PointAngPtr,a0
 move.w num_points,d7
 
 move.l #NORMVECTS,a5
 
 subq #1,d7
 
CALCNORMBRIGHTS:

 move.w (a0)+,d0
 move.w (a0)+,d1
 move.w (a0)+,d2
 
 move.w #0,d6
 
 cmp.w #-1,d0
 bne.s .notnot
 cmp.w #-1,d1
 bne.s .notnot
 cmp.w #-1,d2
 bne.s .notnot
 
 move.w #-1,x1
 move.w #-1,y1
 move.w #-1,z1
 bra .dontbother
 
.notnot:
 neg.w d1
 
 move.w d0,d3
 move.w d2,d5

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

 muls YCOS2,d0
 muls YSIN2,d2
 sub.l d2,d0
 add.l d0,d0
 swap d0
 
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
 add.l d1,d1
 swap d1
 
 muls XSIN2,d4
 muls XCOS2,d5
 add.l d5,d4
 add.l d4,d4
 swap d4

 move.w d0,x1
 move.w d1,y1
 move.w d4,z1

 tst.w y1
 blt.s .okpos
 
 move.w x1,d1	; 0-1024
 asr.w #4,d1	; 0-64
 move.w z1,d2	; 0-1024
 asr.w #4,d2	; 0-64
 
 muls d1,d1
 muls d2,d2
 add.l d1,d2
 jsr CALCSQROOT
 tst.w d2
 beq.s .okpos
 
 move.w d2,d3	; 0-64
 neg.w d3
 add.w #127,d3	; 64-127
 
 move.w z1,d4
 muls d3,d4
 divs d2,d4
 
 move.w x1,d0
 muls d3,d0
 divs d2,d0
 
; asr.w #1,d4
; asr.w #1,d0
 
; neg.w y3
 
.okpos

 asr.w #4,d4
 add.w #128,d4
 move.b d4,d6
 lsl.w #8,d6
 asr.w #4,d0
 add.w #128,d0
 move.b d0,d6
 
; move.w d1,d6	; new y 
;
; asr.w #4,d6
; add.w #20,d6
; 
; ble.s .okokok
; 
; moveq #0,d6
; 
;.okokok:
; add.w #$1c,d6
; cmp.w #1,d6
; bge.s .okokokok
; moveq #1,d6
;.okokokok:
 
; add.w #64,d6
; 
; cmp.w #28,d6
; blt.s .okbig
; move.w #28,d6
;.okbig
 
.dontbother:
 move.w x1,(a5)+
 move.w y1,(a5)+
 move.w z1,(a5)+
 move.w d6,(a2)+

 dbra d7,CALCNORMBRIGHTS


; Next, calculate the point coords for
; the shadow buffer.

 move.l #SHADOWPTS,a2
 move.l PtsPtr,a0
 move.w num_points,d7
 subq #1,d7

ROTPTLOPSHAD:
 move.w (a0)+,d0
 move.w d0,d3
 move.w (a0)+,d1
 move.w (a0)+,d2
 move.w d2,d5

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

 ext.l d2
 
 move.w XOFF,d5
 ext.l d5
 asl.l #8,d5
 add.l d5,d5
 add.l d5,d0
 
 move.l d0,(a2)+
 move.l d1,(a2)+
 move.w d2,(a2)+
 
 dbra d7,ROTPTLOPSHAD



***************************************
* Calculate viewer position for specularity..

 move.w #0,d0
 move.w #0,d1
 move.w #-1024,d2
 
; move.w d0,d3
; move.w d2,d5
;
; muls YCOS,d0
; muls YSIN,d2
; sub.l d2,d0
; add.l d0,d0
; swap d0
; asr.l #6,d0	; new x*512
; 
; muls YSIN,d3
; muls YCOS,d5
; add.l d5,d3
; add.l d3,d3
; swap d3
; move.w d3,d2	; new z
;
; move.w d1,d4
; move.w d2,d5
; muls XCOS,d1
; muls XSIN,d2
; sub.l d2,d1
; add.l d1,d1
; swap d1
; 
; muls XSIN,d4
; muls XCOS,d5
; add.l d5,d4
; add.l d4,d4
; swap d4
; move.w d4,d2	; new z
 
 move.w d0,d3
 move.w d2,d5

 muls YCOS2,d0
 muls YSIN2,d2
 sub.l d2,d0
 add.l d0,d0
 swap d0
 
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
 add.l d1,d1
 swap d1
; asr.l #6,d1	; new y*512
 
 muls XSIN2,d4
 muls XCOS2,d5
 add.l d5,d4
 add.l d4,d4
 swap d4
 
 move.w d0,x2b
 move.w d1,y2b
 move.w d4,z2b

; Now the specular highlight efforts....

 move.l #SPECBRIGHTS,a2
 move.l #NORMVECTS,a1
 
 move.l #SHADOWPTS,a5
 
 move.w num_points,d7
 subq #1,d7
 
CALCSPECBRIGHTS:

 move.w (a1)+,x1
 move.w (a1)+,y1
 move.w (a1)+,z1
 
 move.w x2b,d0
 move.l (a5)+,d1
 asr.l #8,d1
 asr.l #1,d1
 sub.w d1,d0
 move.w d0,x2
 move.w y2b,d0
 move.l (a5)+,d1
 asr.l #8,d1
 asr.l #1,d1
 sub.w d1,d0
 move.w d0,y2
 move.w z2b,d0
 sub.w (a5)+,d0
 move.w d0,z2
 
 move.w #0,d6
 
 cmp.w #-1,x1
 bne.s .notnot
 cmp.w #-1,y1
 bne.s .notnot
 cmp.w #-1,z1
 beq .dontbother
.notnot: 

 move.w x2,d2
 muls d2,d2
 move.w y2,d1
 muls d1,d1
 add.l d1,d2
 move.w z2,d1
 muls d1,d1
 add.l d1,d2
 
 jsr CALCSQROOT
 
 move.w d2,l2

 move.w y1,d0
 muls z2,d0
 move.w y2,d1
 muls z1,d1
 sub.l d1,d0	; x4

 move.w z1,d1
 muls x2,d1
 move.w z2,d2
 muls x1,d2
 sub.l d2,d1	; y4

 move.w x1,d2
 muls y2,d2
 move.w x2,d3
 muls y1,d3
 sub.l d3,d2	; z4

 asr.l #8,d0
 asr.l #8,d1
 asr.l #8,d2
 asr.l #2,d0
 asr.l #2,d1
 asr.l #2,d2

 move.w x1,d3
 muls d1,d3
 move.w y1,d4
 muls d0,d4
 sub.l d4,d3
 asr.l #8,d3
 asr.l #1,d3
 add.w z2,d3

 muls #1024,d3
 divs l2,d3

 move.w d3,z3

 move.w y1,d3
 muls d2,d3
 move.w z1,d4
 muls d1,d4
 sub.l d4,d3
 asr.l #8,d3
 asr.l #1,d3
 add.w x2,d3
 muls #1024,d3
 divs l2,d3
 
 move.w d3,x3

 move.w z1,d3
 muls d0,d3
 move.w x1,d4
 muls d2,d4
 sub.l d4,d3
 asr.l #8,d3
 asr.l #1,d3
 add.w y2,d3
 muls #1024,d3
 divs l2,d3

 move.w d3,y3
 
 move.w z3,d3
 asr.w #4,d3
 add.w #128,d3

 move.b d3,d6
 lsl.w #8,d6

 move.w x3,d3
 asr.w #4,d3
 add.w #128,d3
 move.b d3,d6
  
 tst.w y3
 blt.s .okpos
 
 move.w x3,d1
 asr.w #4,d1
 move.w z3,d2
 asr.w #4,d2
 
 muls d1,d1
 muls d2,d2
 add.l d1,d2
 jsr CALCSQROOT
 tst.w d2
 beq.s .okpos
 
 move.w d2,d3
 neg.w d3
 add.w #127,d3
 
 move.w z3,d4
 muls d3,d4
 divs d2,d4
 asr.w #4,d4
 add.w #128,d4
 move.b d4,d6
 lsl.w #8,d6
 
 move.w x3,d4
 muls d3,d4
 divs d2,d4
 asr.w #4,d4
 add.w #128,d4
 move.b d4,d6
 
; neg.w y3
 
.okpos
  
; add.w y2,d3
;
; move.w d3,d6
;
; asr.w #4,d6
; 
; add.w #30,d6
; 
; ble.s .okokok
; 
; moveq #0,d6
; 
;.okokok:
; add.w #$1c,d6
;
; cmp.w #1,d6
; bge.s .okokokok
; moveq #1,d6
;.okokokok:
 
; 
; cmp.w #28,d6
; blt.s .okbig
; move.w #28,d6
;.okbig
 
.dontbother:
 move.w d6,(a2)+
 move.w y3,(a2)+

 dbra d7,CALCSPECBRIGHTS




* NOW THE POINTS FOR ON-SCREENNESS

 move.l #ROTATEDPTS,a2
 move.l PtsPtr,a0
 move.w num_points,d7
 subq #1,d7

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
 move.w d2,(a2)+
 
 dbra d7,ROTPTLOP
 
; Now convert the rotated points to the screen:

 move.l #ROTATEDPTS,a0
 move.l #ONSCREENPTS,a2
 move.w num_points,d7
 subq #1,d7
CONVERTTOSCREEN:
 move.l (a0)+,d0
 move.l (a0)+,d1
 move.w (a0)+,d2
; asr.w #1,d2

 add.w ZOFF,d2
 ext.l d2

 move.l d0,d3
 asr.l #1,d3
 add.l d3,d0 
 move.l d1,d3
 asr.l #1,d3
 add.l d3,d1 

 divs d2,d0
 divs d2,d1
 add.w #160*4,d0
 add.w #128*4,d1
 move.w d0,(a2)+
 move.w d1,(a2)+
 dbra d7,CONVERTTOSCREEN
 
 move.w #254,HIGHPOLY
 
 move.l LinesPtr,a1
 move.l #PartBuffer,a0
 move.l a0,a2
 move.w #15,d0
clrpartbuffSHAD:
 move.l #$80000001,(a2)+
 move.l #$80000001,(a2)+
 move.l #$80000001,(a2)+
 move.l #$80000001,(a2)+
 dbra d0,clrpartbuffSHAD
 
 move.l #SHADOWPTS,a2
 move.l OBJONOFF,d5

 move.w #0,d4
 tst.w SORTIT
 bne.s PutInPartsSHAD
 
 
putinunsortedSHAD:
 move.w (a1)+,d7
 blt doneallpartsSHAD
 lsr.l #1,d5
 bcs.s .yeson
 addq #2,a1
 bra putinunsortedSHAD
.yeson:

 move.w (a1)+,d6
 move.l #0,(a0)+
 move.w d7,(a0)+
 move.w d4,(a0)+
 addq #1,d4
 bra putinunsortedSHAD
 
PutInPartsSHAD
 move.w (a1)+,d7
 blt doneallpartsSHAD
 
 lsr.l #1,d5
 bcs.s .yeson
 addq #2,a1
 bra PutInPartsSHAD
.yeson:

 move.w (a1)+,d6
 move.l 4(a2,d6.w),d0
 add.l #200000,d0
 
 move.l #PartBuffer-8,a0
 
stillfrontSHAD
 addq #8,a0
 cmp.l (a0),d0
 blt stillfrontSHAD
 move.l #endparttab-8,a5
domoreshiftSHAD:
 move.l -8(a5),(a5)
 move.l -4(a5),4(a5)
 subq #8,a5
 cmp.l a0,a5
 bgt.s domoreshiftSHAD

 move.l d0,(a0)
 move.w d7,4(a0)
 move.w d4,6(a0)
 addq #1,d4
 bra PutInPartsSHAD

doneallpartsSHAD:

 move.l #PartBuffer,a0

 ifne SHADOWMAP

PartLoopSHAD
 move.l (a0)+,d7
 blt nomorepartsSHAD
 
 move.l #SAVEHIGHS,a2
 move.w 2(a0),d0
 move.w HIGHPOLY,(a2,d0.w*2)
 
 moveq #0,d0
 move.w (a0),d0
 addq #4,a0
 add.l START_OF_OBJECT,d0
 move.l d0,a1
 
polylooSHAD:

 tst.w (a1)
 blt.s nomorepolysSHAD
 movem.l a0/a1/d7,-(a7)
 bsr doaSHADEpoly
 movem.l (a7)+,a0/a1/d7
 
 move.w (a1),d0
 lea 18(a1,d0.w*4),a1

 bra.s polylooSHAD
nomorepolysSHAD:
 sub.w #1,HIGHPOLY
 bra PartLoopSHAD
nomorepartsSHAD:

 endc

*******************************************
* Now the on-screen bit...
*******************************************

 move.l LinesPtr,a1
 move.l #PartBuffer,a0
 move.l a0,a2
 move.w #15,d0
clrpartbuff:
 move.l #$80000001,(a2)+
 move.l #$80000001,(a2)+
 move.l #$80000001,(a2)+
 move.l #$80000001,(a2)+
 dbra d0,clrpartbuff

 move.l #ROTATEDPTS,a2
 move.l OBJONOFF,d5

 moveq #0,d4

 tst.w SORTIT
 bne.s PutInParts
 
putinunsorted:
 move.w (a1)+,d7
 blt doneallparts
 lsr.l #1,d5
 bcs.s .yeson
 addq #2,a1
 bra putinunsorted
.yeson:

 move.w (a1)+,d6
 move.l #0,(a0)+
 move.w d7,(a0)+
 move.w d4,(a0)+
 
 addq #1,d4
 bra putinunsorted
 
PutInParts
 move.w (a1)+,d7
 blt doneallparts
 
 lsr.l #1,d5
 bcs.s .yeson
 addq #2,a1
 bra PutInParts
.yeson:

 move.w (a1)+,d6
 move.l (a2,d6.w),d0
 asr.l #8,d0
 asr.l #2,d0
 muls d0,d0
 move.l 4(a2,d6.w),d2
 asr.l #8,d2
 asr.l #2,d2
 muls d2,d2
 add.l d2,d0 
 move.w 8(a2,d6.w),d2
 add.w #1024,d2
 muls d2,d2
 add.l d2,d0
 
 move.l #PartBuffer-8,a0
 
stillfront
 addq #8,a0
 cmp.l (a0),d0
 blt stillfront
 move.l #endparttab-8,a5
domoreshift:
 move.l -8(a5),(a5)
 move.l -4(a5),4(a5)
 subq #8,a5
 cmp.l a0,a5
 bgt.s domoreshift

 move.l d0,(a0)
 move.w d7,4(a0)
 move.w d4,6(a0)
 addq #1,d4
 bra PutInParts

doneallparts:

 move.l #PartBuffer,a0

PartLoop
 move.l (a0)+,d7
 blt nomoreparts

 move.l #SAVEHIGHS,a2
 move.w 2(a0),d0
 move.w (a2,d0.w*2),HIGHPOLY
 
 moveq #0,d0
 move.w (a0),d0
 addq #4,a0
 add.l START_OF_OBJECT,d0
 move.l d0,a1
 
polyloo:

 tst.w (a1)
 blt.s nomorepolys
 movem.l a0/a1/d7,-(a7)
 bsr doapoly
 movem.l (a7)+,a0/a1/d7
 
 move.w (a1),d0
 lea 18(a1,d0.w*4),a1

 bra.s polyloo
nomorepolys:
 sub.w #1,HIGHPOLY
 bra PartLoop
nomoreparts:

NOPOLYS:



********************************************

 ifne DEPTHBALL


 move.l #BALLXOFF,a5
 move.l #BALLXANGPOS,a6
 
BALLLOOP

 move.l FASTBUFFER,a0
 move.l #BALL,a1
 move.l #DEPTHBUFFER,a2

 add.l #320*(128-32),a0
 add.l #320*4*(128-32),a2
 
 add.l #(160-32),a0
 add.l #(160-32)*4,a2
 
 move.w (a5),d0
 
 cmp.w #999,d0
 beq NOMOREBALLS
 
 add.w d0,a0
 lea (a2,d0.w*4),a2
 
 move.w 2(a5),d0
 muls #320,d0
 add.l d0,a0
 lea (a2,d0.l*4),a2

 move.l #$7ffffff,d6

 move.l #GOURPAL,a3

 move.w 4(a5),d7
 
 move.w #63,d0
.balldown
 move.w #63,d1
.ballacross

 move.w d7,d4
 moveq #0,d2
 move.b (a1)+,d2
 asl.w #2,d2
 beq.s .nopixel
 sub.w d2,d4
 move.l (a2)+,d3
 swap d3
 sub.w d4,d3
 ble.s .noplot

 asr.w #1,d3
 asr.w #1,d2

 cmp.w d2,d3
 blt.s .okthick
 move.w d2,d3
.okthick:

 cmp.w #31,d3
 ble.s .okv
 move.w #31,d3
.okv:

 asl.w #8,d3
 
 move.b (a0),d3
 
 move.b (a3,d3.w),(a0)
; move.b #15,(a0)
 
.noplot
 addq #1,a0
 dbra d1,.ballacross
 
 add.l #(320-64),a0
 add.l #(320-64)*4,a2
 
 dbra d0,.balldown

 bra DONEBALL

.nopixel:
 addq #4,a2
 addq #1,a0
 dbra d1,.ballacross
 
 add.l #(320-64),a0
 add.l #(320-64)*4,a2
 
 dbra d0,.balldown


DONEBALL:

 move.w 2(a6),d0
 move.l #SINETABLE,a0
 move.w (a0,d0.w),d1
 add.w (a6)+,d0
 and.w #8190,d0
 move.w d0,(a6)+
 ext.l d1
 asl.l #7,d1
 swap d1
 move.w d1,(a5)+

 move.w 2(a6),d0
 move.l #SINETABLE,a0
 move.w (a0,d0.w),d1
 add.w (a6)+,d0
 and.w #8190,d0
 move.w d0,(a6)+
 ext.l d1
 asl.l #6,d1
 swap d1
 move.w d1,(a5)+

 move.w 2(a6),d0
 move.l #SINETABLE,a0
 move.w (a0,d0.w),d1
 add.w (a6)+,d0
 and.w #8190,d0
 move.w d0,(a6)+
 ext.l d1
 asl.l #1,d1
 asl.l #8,d1
 swap d1
 move.w d1,(a5)+
 

 bra BALLLOOP

NOMOREBALLS:

 endc

 ifne POLYGONDEPTH!DEPTHBALL

 move.l #DEPTHBUFFER+280*256*4,a0
 move.l #$7ffffff,d0
 move.l d0,d1
 move.l d0,d2
 move.l d0,d3
 move.l d0,d4
 move.l d0,d5
 move.l d0,d6
 move.l d0,a1
 
 move.w #(320*176)/8,d7

.clrbuff:
 movem.l  d0-d6/a1,-(a0)
 dbra d7,.clrbuff


 endc
 

********************************************

; btst #6,$bfe001
; beq.s .SHOWSHADOW

 ifne MOTIONBLUR
 
 move.l FASTBUFFER,d0
 cmp.l #fasty,d0
 bne SHOWNSCRN
 
 move.l #fasty,a0
 move.l #fasty2,a1
 add.l #40*320+64,a0
 add.l #40*320+64,a1
 move.l #BLUR,a2
 move.w #175,d0
 moveq #0,d6
.blurchunk:
 move.w #(192/4)-1,d1
.blurline:

 move.l (a0),d2
 move.l d2,d4
 swap d4
 move.l (a1)+,d3
 move.l d3,d5
 swap d5
  
 lsr.w #8,d5
 move.b d5,d4
 move.w d4,d6
 move.b (a2,d6.l),d7
 
 lsl.l #8,d7
 lsl.l #8,d2
 lsl.l #8,d3
 move.l d2,d4
 move.l d3,d5
 swap d4
 swap d5
 lsr.w #8,d5
 move.b d5,d4
 move.w d4,d6
 move.b (a2,d6.l),d7

 lsl.l #8,d7
 lsl.l #8,d2
 lsl.l #8,d3
 move.l d2,d4
 move.l d3,d5
 swap d4
 swap d5
 lsr.l #8,d5
 move.b d5,d4
 move.w d4,d6
 move.b (a2,d6.l),d7

 lsl.l #8,d7
 lsl.l #8,d2
 lsl.l #8,d3
 move.l d2,d4
 move.l d3,d5
 swap d4
 swap d5
 lsr.l #8,d5
 move.b d5,d4
 move.w d4,d6
 move.b (a2,d6.l),d7

 move.l d7,(a0)+

 dbra d1,.blurline
 
 add.w #(320-192),a1
 add.w #(320-192),a0
 dbra d0,.blurchunk
 
 endc

FASF:

 ifne ANTIALIAS
 
 
 move.l #fasty,a0
 move.l #fasty,a1
 add.l #40*320+64,a0
 add.l #41*320+65,a1
 move.l #BLUR,a2
 move.w #175,d0
 moveq #0,d6
.blurchunk:
 move.w #(192/4)-1,d1
.blurline:

 move.l (a0),d2
 move.l d2,d4
 swap d4
 move.l (a1)+,d3
 move.l d3,d5
 swap d5
  
 lsr.w #8,d5
 move.b d5,d4
 move.w d4,d6
 move.b (a2,d6.l),d7
 
 lsl.l #8,d7
 lsl.l #8,d2
 lsl.l #8,d3
 move.l d2,d4
 move.l d3,d5
 swap d4
 swap d5
 lsr.w #8,d5
 move.b d5,d4
 move.w d4,d6
 move.b (a2,d6.l),d7

 lsl.l #8,d7
 lsl.l #8,d2
 lsl.l #8,d3
 move.l d2,d4
 move.l d3,d5
 swap d4
 swap d5
 lsr.l #8,d5
 move.b d5,d4
 move.w d4,d6
 move.b (a2,d6.l),d7

 lsl.l #8,d7
 lsl.l #8,d2
 lsl.l #8,d3
 move.l d2,d4
 move.l d3,d5
 swap d4
 swap d5
 lsr.l #8,d5
 move.b d5,d4
 move.w d4,d6
 move.b (a2,d6.l),d7

 move.l d7,(a0)+

 dbra d1,.blurline
 
 add.w #(320-192),a1
 add.w #(320-192),a0
 dbra d0,.blurchunk
 
 endc


 ifeq LARGESCREEN

 move.l FASTBUFFER,a0 
 add.l #40*320+64,a0
 move.l #RAWSCRN,a1
 add.l #40*40+8,a1
 move.l #(24)-1,d0
 move.l #175,d1
 move.w #128,d2
 move.w #16,d3
 moveq #0,d4
 moveq #0,d5
 jsr CHUNKYTOPLANAR 

 endc

 ifne LARGESCREEN

 move.l FASTBUFFER,a0 
 move.l #RAWSCRN,a1
 move.l #39,d0
 move.l #255,d1
 move.w #0,d2
 move.w #0,d3
 moveq #0,d4
 moveq #0,d5
 jsr CHUNKYTOPLANAR 

 endc


 bra SHOWNSCRN

.SHOWSHADOW

 move.l #SHADOWBUFFER,a0
 add.l #40*256,a0
 move.l #RAWSCRN,a1
 add.l #40*40,a1
 move.l #(256/8)-1,d0
 move.l #175,d1
 move.w #0,d2
 move.w #8,d3
 moveq #0,d4
 moveq #0,d5
 jsr CHUNKYTOPLANAR 

SHOWNSCRN:
 
 ifne MOTIONBLUR
 
 move.l #fasty2,d1
 move.l FASTBUFFER,d0
 cmp.l #fasty,d0
 beq.s .ok2
 move.l #fasty,d1
.ok2:
 move.l d1,FASTBUFFER 
 
 endc
 
 move.l FASTBUFFER,a0
 move.l #NEBBIE,a1
 ifeq LARGESCREEN
 add.l #40*320+64,a0
 endc
 
 move.l #BLUR,a2
 ifeq LARGESCREEN
 moveq #0,d6
 move.w #175,d0
 endc
 ifne LARGESCREEN
 move.l #$e5e5e5e5,d6
 move.w #511,d0
 endc
 
clrchunk:

 ifeq LARGESCREEN
 REPT 192/4
 move.l (a1)+,(a0)+
 endr
 add.w #(320-192),a0
 endc

 ifne LARGESCREEN
 REPT 160/4
 move.l d6,(a0)+
 endr
 endc
 
 dbra d0,clrchunk
 
 move.l #SHADOWBUFFER,a0
 move.l #-1,d1
 move.l #-1,d2
 move.w #15,d0
;clrshad:
; move.w #15,d5
;innner
; move.l d2,(a0)+
; move.l d2,(a0)+
; move.l d2,(a0)+
; move.l d2,(a0)+
; move.l d1,(a0)+
; move.l d1,(a0)+
; move.l d1,(a0)+
; move.l d1,(a0)+
; move.l d2,(a0)+
; move.l d2,(a0)+
; move.l d2,(a0)+
; move.l d2,(a0)+
; move.l d1,(a0)+
; move.l d1,(a0)+
; move.l d1,(a0)+
; move.l d1,(a0)+
; move.l d2,(a0)+
; move.l d2,(a0)+
; move.l d2,(a0)+
; move.l d2,(a0)+
; move.l d1,(a0)+
; move.l d1,(a0)+
; move.l d1,(a0)+
; move.l d1,(a0)+
; move.l d2,(a0)+
; move.l d2,(a0)+
; move.l d2,(a0)+
; move.l d2,(a0)+
; move.l d1,(a0)+
; move.l d1,(a0)+
; move.l d1,(a0)+
; move.l d1,(a0)+
; move.l d2,(a0)+
; move.l d2,(a0)+
; move.l d2,(a0)+
; move.l d2,(a0)+
; move.l d1,(a0)+
; move.l d1,(a0)+
; move.l d1,(a0)+
; move.l d1,(a0)+
; move.l d2,(a0)+
; move.l d2,(a0)+
; move.l d2,(a0)+
; move.l d2,(a0)+
; move.l d1,(a0)+
; move.l d1,(a0)+
; move.l d1,(a0)+
; move.l d1,(a0)+
; move.l d2,(a0)+
; move.l d2,(a0)+
; move.l d2,(a0)+
; move.l d2,(a0)+
; move.l d1,(a0)+
; move.l d1,(a0)+
; move.l d1,(a0)+
; move.l d1,(a0)+
; move.l d2,(a0)+
; move.l d2,(a0)+
; move.l d2,(a0)+
; move.l d2,(a0)+
; move.l d1,(a0)+
; move.l d1,(a0)+
; move.l d1,(a0)+
; move.l d1,(a0)+
; dbra d5,innner
; exg d1,d2
;
; dbra d0,clrshad

 

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

TESTTAB: ds.w 30

************************************************
* SUBROUTINES HERE. ****************************
************************************************


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


doaSHADEpoly:

 move.w (a1)+,d7	; sides to draw
 addq #2,a1		; avoid holes
 
 move.l #SHADOWPTS,a3
 
 move.w (a1),d0
 move.w 4(a1),d1
 move.w 8(a1),d2
 muls #10,d0
 muls #10,d1
 muls #10,d2
 move.w 8(a3,d0.w),d3
 move.w 8(a3,d1.w),d4
 move.w 8(a3,d2.w),d5
 move.l (a3,d0.w),d0
 move.l (a3,d1.w),d1
 move.l (a3,d2.w),d2
 asr.l #8,d0
 asr.l #8,d1
 asr.l #8,d2
 asr.l #1,d0
 asr.l #1,d1
 asr.l #1,d2

 sub.w d1,d0
 sub.w d1,d2
 sub.w d4,d3
 sub.w d4,d5
 muls d3,d2
 muls d5,d0
 sub.l d0,d2
 bge SHADpolybehind
 
 
 
 move.w #20000,d4	; top
 move.w #-20000,d5	; bottom
 move.l #UVCOORDS,a4

putinlinesSHAD:
 move.w (a1),d0
 move.w 4(a1),d1
 
 moveq #0,d2
 move.b 2(a1),d2	; one end U
 move.w d2,2(a4,d0.w*4)
 move.b 3(a1),d2	; one end V
 move.w d2,(a4,d0.w*4)
 move.b 6(a1),d2	; two end U
 move.w d2,2(a4,d1.w*4)
 move.b 7(a1),d2	; two end V
 move.w d2,(a4,d1.w*4)
 
 move.w d0,d2
 muls #10,d2
 move.w 8(a3,d2.w),d2	; Z
 
 cmp.w d2,d4
 ble.s .oktop
 move.w d2,d4
.oktop
 cmp.w d2,d5
 bge.s .okbot
 move.w d2,d5
.okbot
 
 movem.l d4/d5/d7/a1/a3/a4,-(a7)
 bsr SIMPLESHADLINE
 movem.l (a7)+,d4/d5/d7/a1/a3/a4
 addq #4,a1
 dbra d7,putinlinesSHAD
 addq #4,a1
  
 move.w (a1)+,TEXTUREADD

 asr.w #2,d4
 asr.w #2,d5
 add.w #128,d4
 add.w #128,d5
 move.w d4,TOPLINE
 move.w d5,BOTLINE

* Now draw the shadow polygon....

 move.l #SHADOWBUFFER,a2
 move.l #LEFTUVS,a0
 move.w TOPLINE,d0
 move.w BOTLINE,d1
 sub.w d0,d1
 asl.w #3,d0
 add.w d0,a0
 muls #(512/8),d0
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
 lea (a2,d7.w*2),a2
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
 bge.s .okaddtes3
 and.w #$7fff,d7
 add.l #65536*4,a0
.okaddtes3:
 ext.l d7
; add.l d7,d7
 asl.l #8,d7
 add.l d7,a0
 move.w #0,d7

 subq #1,d0
 
; d0=xdist
; d4=U  a5=DU
; d5=V  a6=DV
; d6=Y  a3=DY
 moveq #0,d1

 swap d6

PLOTADOT:

.across

; swap d4
; swap d5
; move.w d4,d2
; lsl.w #8,d2
; swap d4
; move.b d5,d2
; add.l a5,d4
; swap d5
; add.l a6,d5

 
; swap d6
; move.b (a2)+,d1
; tst.b 1(a0,d2.w*8)
; beq.s .noplottt
 move.b d6,(a2)
 addq #2,a2

 dbra d0,.across
 bra.s .plaster
 
.noplottt:
 addq #1,a2
 dbra d0,.across
 
.plaster:
 
 move.l (a7)+,d1
 move.l (a7)+,a0
 move.l (a7)+,a2
 
.noline:
 add.w #512,a2
 
 swap d1
 dbra d1,DOAHORLINESHAD

NOPOLYGONSHAD:

SHADpolybehind:
 rts


************************************************

LU: dc.w 0
LV: dc.w 0
RU: dc.w 0
RV: dc.w 0
	
SIMPLESHADLINE:
 move.l #SHADOWPTS,a1
 
 move.l #UVCOORDS,a2
 move.w (a2,d0.w*4),LU
 move.w 2(a2,d0.w*4),LV
 move.w (a2,d1.w*4),RU
 move.w 2(a2,d1.w*4),RV

 muls #10,d0
 muls #10,d1
 move.w 8(a1,d0.w),d2		;fz
 move.w 8(a1,d1.w),d7		;sz
 ext.l d2
 ext.l d7
 
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

 move.l LU,d5
 move.l RU,LU
 move.l d5,RU
 
.lineonright:

 sub.w d2,d7
 add.w #128,d2
 lea (a3,d2.w*8),a3
 
 move.w d7,YDIFF
 
 move.l (a1,d0.w),d3		;fx
 move.l (a1,d1.w),d7		;sx

 asl.l #5,d3
 asl.l #5,d7
 
 sub.l d3,d7
 divs.l YDIFF-2,d7
 move.l d7,a0	; dx
 
 move.l #ROTATEDPTS,a1
 
 move.w LU,d4
 move.w LV,d5
 move.w RU,d6
 move.w RV,d7
 
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
 
 move.l 4(a1,d0.w),d6
 move.l 4(a1,d1.w),d7
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

BCOS: dc.w 0
BSIN: dc.w 0
ACOS: dc.w 0
ASIN: dc.w 0

CCOS: dc.w 0
CSIN: dc.w 0
DCOS: dc.w 0
DSIN: dc.w 0
ECOS: dc.w 0
ESIN: dc.w 0

FSX: dc.w 0
FSY: dc.w 0
SSX: dc.w 0
SSY: dc.w 0

**************************************************

doapoly:

 move.w (a1)+,d7	; sides to draw
 addq #2,a1		; avoid holes
 move.w 12(a1,d7.w*4),pregour
 
 move.l #ONSCREENPTS,a3
 
 move.w (a1),d0
 move.w 4(a1),d1
 move.w 8(a1),d2
 move.w 2(a3,d0.w*4),d3
 move.w 2(a3,d1.w*4),d4
 move.w 2(a3,d2.w*4),d5
 move.w (a3,d0.w*4),d0
 move.w (a3,d1.w*4),d1
 move.w (a3,d2.w*4),d2

 sub.w d1,d0
 sub.w d1,d2
 sub.w d4,d3
 sub.w d4,d5
 muls d3,d2
 muls d5,d0
 sub.l d0,d2
 ble polybehind
 
; Now we must rotate the polygons coordinates in
; the specular map so that the texturemap is vertical
; relative to the specular map and so that bump-
; mapping can take place unerroneously!

; movem.l d0-d7/a0-a6,-(a7)

 move.w #0,BCOS
 move.w #128*128,ACOS
 move.w #0,BSIN
 move.w #0,ASIN

 moveq #0,d3
 move.b 2(a1),d3
 moveq #0,d4
 move.b 3(a1),d4
 moveq #0,d5
 move.b 2+4(a1),d5
 moveq #0,d6
 move.b 3+4(a1),d6

 sub.w d3,d5
 sub.w d4,d6

 move.w d5,d1
 move.w d6,d2
 muls d1,d1
 muls d2,d2
 add.l d1,d2
 jsr CALCSQROOT
 tst.w d2
 beq .NOROT
 
 ext.l d5
 ext.l d6
 asl.l #7,d5
 asl.l #7,d6
 divs d2,d5
 divs d2,d6
 move.w d5,ECOS
 move.w d6,ESIN

 move.w ECOS,d0
 asl.w #7,d0
 move.w d0,ACOS
 move.w ESIN,d0
 asl.w #7,d0
 move.w d0,ASIN
 
 move.l #SPECBRIGHTS,a3

 move.w (a1),d0
 moveq #0,d5
 moveq #0,d6
 move.b (a3,d0.w*4),d5
 move.b 1(a3,d0.w*4),d6
 move.w 4(a1),d0
 moveq #0,d3
 moveq #0,d4
 move.b (a3,d0.w*4),d3
 move.b 1(a3,d0.w*4),d4
 sub.w d5,d3
 sub.w d6,d4

 move.w d3,d1
 move.w d4,d2
 muls d1,d1
 muls d2,d2
 add.l d1,d2
 jsr CALCSQROOT
 tst.w d2
 beq .NOROT1

 ext.l d3
 asl.l #7,d3
 ext.l d4
 asl.l #7,d4
 divs d2,d3
 divs d2,d4
 move.w d3,BCOS
 neg.w d4
 move.w d4,BSIN
 
 move.w ECOS,d4
 move.w ESIN,d5
 move.w d4,d2
 move.w d5,d3
 muls BCOS,d2
 muls BSIN,d3
 sub.l d3,d2
 muls BSIN,d4
 muls BCOS,d5
 add.l d5,d4
 move.w d2,ACOS
 move.w d4,ASIN
 
.NOROT1
 
 move.w #0,DCOS
 move.w #0,DSIN
 move.w ECOS,d0
 asl.w #7,d0
 move.w d0,CCOS
 move.w ESIN,d0
 asl.w #7,d0
 move.w d0,CSIN

; bra .NOROT

; First calculate angle B

 move.l #NORMBRIGHTS,a3
 
 movem.l d7/a1,-(a7)
 
.findnonzer:

 move.w (a1),d0
 moveq #0,d5
 moveq #0,d6
 move.b (a3,d0.w*2),d5
 move.b 1(a3,d0.w*2),d6
 move.w 4(a1),d0
 moveq #0,d3
 moveq #0,d4
 move.b (a3,d0.w*2),d3
 move.b 1(a3,d0.w*2),d4
 sub.w d5,d3
 sub.w d6,d4
 bne.s .okok
 tst.w d3
 bne.s .okok
 
 addq #4,a1
 
 dbra d7,.findnonzer
 
 movem.l (a7)+,d7/a1
 bra .NOROT
 
.okok:

 moveq #0,d3
 move.b 2(a1),d3
 moveq #0,d4
 move.b 3(a1),d4
 moveq #0,d5
 move.b 2+4(a1),d5
 moveq #0,d6
 move.b 3+4(a1),d6

 sub.w d3,d5
 sub.w d4,d6

 move.w d5,d1
 move.w d6,d2
 muls d1,d1
 muls d2,d2
 add.l d1,d2
 jsr CALCSQROOT
 tst.w d2
 beq .NOROT8
 
 ext.l d5
 ext.l d6
 asl.l #7,d5
 asl.l #7,d6
 divs d2,d5
 divs d2,d6
 move.w d5,ECOS
 neg.w d6
 move.w d6,ESIN
 move.w ECOS,d0
 asl.w #7,d0
 move.w d0,CCOS
 move.w ESIN,d0
 asl.w #7,d0
 neg.w d0
 move.w d0,CSIN

.NOROT8:

 movem.l (a7)+,d7/a1

 move.w d3,d1
 move.w d4,d2
 muls d1,d1
 muls d2,d2
 add.l d1,d2
 jsr CALCSQROOT
 tst.w d2
 beq .NOROT

 ext.l d3
 asl.l #7,d3
 ext.l d4
 asl.l #7,d4
 divs d2,d3
 divs d2,d4
 move.w d3,DCOS
 neg.w d4
 move.w d4,DSIN

 move.w ECOS,d4
 move.w ESIN,d5
 move.w d4,d2
 move.w d5,d3
 muls DCOS,d2
 muls DSIN,d3
 sub.l d3,d2
 muls DSIN,d4
 muls DCOS,d5
 add.l d5,d4
 move.w d2,CCOS
 move.w d4,CSIN

 
.NOROT:

; movem.l (a7)+,d0-d7/a0-a6
 
 move.l #ONSCREENPTS,a3
 
 move.w #20000,d4	; top
 move.w #-20000,d5	; bottom
 move.l #UVCOORDS,a4

 move.l a1,a0

putinlines:
 move.w (a1),d0
 move.w 4(a1),d1
 
 moveq #0,d2
 move.b 2(a1),d2	; one end U
 move.w d2,2(a4,d0.w*4)
 move.b 3(a1),d2	; one end V
 move.w d2,(a4,d0.w*4)
 move.b 6(a1),d2	; two end U
 move.w d2,2(a4,d1.w*4)
 move.b 7(a1),d2	; two end V
 move.w d2,(a4,d1.w*4)
 
 move.w 2(a3,d0.w*4),d2	; Z
 
 cmp.w d2,d4
 ble.s .oktop
 move.w d2,d4
.oktop
 cmp.w d2,d5
 bge.s .okbot
 move.w d2,d5
.okbot
 
 movem.l a0/d4/d5/d7/a1/a3/a4,-(a7)
 jsr SIMPLECALCLINE
 movem.l (a7)+,a0/d4/d5/d7/a1/a3/a4
 addq #4,a1
 dbra d7,putinlines
 addq #4,a1 
 
 move.w (a1)+,TEXTUREADD

 asr.w #2,d4
 asr.w #2,d5
; add.w #128,d4
; add.w #128,d5
 move.w d4,TOPLINE
 move.w d5,BOTLINE
  
 move.l #SHADOWPTS,a1
 move.w (a0),d0
 move.w 4(a0),d1
 move.w 8(a0),d2

CHECKVALS:

 muls #10,d0
 muls #10,d1
 muls #10,d2
 
 lea (a1,d0.w),a0
 lea (a1,d2.w),a2
 lea (a1,d1.w),a1
 
 move.l (a0),d3
 sub.l (a1),d3
 asr.l #8,d3
 asr.l #1,d3
 move.l 4(a0),d4
 sub.l 4(a1),d4
 asr.l #8,d4
 asr.l #1,d4
 move.w 8(a0),d5
 sub.w 8(a1),d5
 
 move.w d3,d6
 muls d6,d6
 move.w d4,d7
 muls d7,d7
 add.l d7,d6
 move.w d5,d7
 muls d7,d7
 add.l d7,d6
 move.l d6,d2
 jsr CALCSQROOT
 move.w d2,LEN1

 move.l (a2),d0
 sub.l (a1),d0
 asr.l #8,d0
 asr.l #1,d0
 move.l 4(a2),d1
 sub.l 4(a1),d1
 asr.l #8,d1
 asr.l #1,d1
 move.w 8(a2),d2
 sub.w 8(a1),d2
 
 muls d2,d3
 muls d0,d5
 sub.l d3,d5	; length
 muls.l #$4c,d5
 
 muls d0,d0
 muls d1,d1
 muls d2,d2
 add.l d0,d1
 add.l d1,d2
 jsr CALCSQROOT
 
 muls LEN1,d2
 bgt.s .ok
 moveq #1,d2
.ok
 
 divs.l d2,d5

 add.l #16,d5

 tst.l d5
 ble.s .okbr
 moveq #0,d5
.okbr:
 add.w #$5c,d5
 bge.s .okbr2
 moveq #0,d5
.okbr2:
 
 move.w d5,d0
 
 asl.w #8,d5
 move.w d5,BRIGHTNESS+2

 sub.w #$5c,d0
 asr.w #1,d0
 add.w #$5c,d0
 asl.w #8,d0
 move.w d0,BRIGHTNESS


***********************************************
* Draw the polygon (shadowed).
 
 move.l FASTBUFFER,a2
 move.l #LEFTUVS,a0
 move.w TOPLINE,d0
 move.w BOTLINE,d1
 sub.w d0,d1
 move.l #LEFTZS,a3
 lea (a3,d0.w*2),a3
 move.l a3,ZSPTR
 
 move.w d0,d2
 muls #20,d2
 add.l d2,a0
 muls #320,d0
 add.l d0,a2	; pointer to screen line.

 move.l #DEPTHBUFFER,a3
 lea (a3,d0.l*4),a3	; pointer to depth buff line
 move.l a3,DEPTHPTR

 subq #1,d1
 blt NOPOLYGON
 
 tst.b Gouraud
 bne GOURPOLY
 
DOAHORLINE:
 swap d1

 move.w RIGHTUVS-LEFTUVS(a0),d0
 move.w (a0)+,d7
 asr.w #2,d0
 asr.w #2,d7
 sub.w d7,d0
 bge.s .okflibble
 
 add.w #14,a0
 add.w #320,a2
 swap d1
 dbra d1,DOAHORLINE
 bra NOPOLYGON
 
.okflibble:
 
 move.l a2,-(a7)
 
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
 bge.s .okaddtes3
 and.w #$7fff,d7
 add.l #65536*4,a0
.okaddtes3:
 ext.l d7
; add.l d7,d7
 asl.l #8,d7
 add.l d7,a0
 move.w #0,d7
 
 move.l BRIGHTNESS,a6
 
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

 moveq #0,d1
 swap d6
 move.w d6,d1
 lsl.w #8,d1
 swap d4
 move.b d4,d1
 swap d4
 swap d6
 
 moveq #0,d7
 move.b (a7,d1.l),d7
 cmp.w d7,d5
 ble INTHELIGHT
 bra.s INTHEDARK

PENUMBRA:
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
 move.b (a7,d1.l),d7
 cmp.w d7,d5
 ble INTOLIGHT
 bra.s INTODARK
 
 
INTHEDARK:
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
 move.b (a7,d1.l),d7
 cmp.w d7,d5
 ble.s INTOPENUM
INTODARK:
 move.w #$5c00,d7
 swap d2
 move.w d2,d1
 asl.w #8,d1
 swap d3
 move.b d3,d1
 swap d2
 swap d3
 add.l a1,d2
 add.l a4,d3
 
; move.b (a0,d1.w*4),d7
; beq.s .noplottt

 move.b TEXTUREPAL-256(pc,d7.w),(a2)+
 dbra d0,INTHEDARK
 bra.s PASTAC 

.noplottt
 addq #1,a2
 dbra d0,INTHEDARK
 bra.s PASTAC

INTOPENUM:
 move.l a6,d7
 swap d7
 swap d2
 move.w d2,d1
 asl.w #8,d1
 swap d3
 move.b d3,d1
 swap d2
 swap d3
 add.l a1,d2
 add.l a4,d3
 
; move.b (a0,d1.w*4),d7
; beq.s .noplottt

 move.b TEXTUREPAL(pc,d7.w),(a2)+
 dbra d0,PENUMBRA
 bra.s PASTAC 
 
.noplottt
 addq #1,a2
 dbra d0,PENUMBRA
 bra.s PASTAC

INTHELIGHT:

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
 move.b (a7,d1.l),d7
 cmp.w d7,d5
 bgt.s INTOPENUM
INTOLIGHT:
 move.w a6,d7
 swap d2
 move.w d2,d1
 asl.w #8,d1
 swap d3
 move.b d3,d1
 swap d2
 swap d3
 add.l a1,d2
 add.l a4,d3
 
; move.b (a0,d1.w*4),d7
; beq.s .noplottt

 move.b TEXTUREPAL(pc,d7.w),(a2)+
 dbra d0,INTHELIGHT
 bra.s PASTAC 
 
.noplottt:
 addq #1,a2
 dbra d0,INTHELIGHT
 
PASTAC
 
 move.l SAVESTACK,a7
 
 move.l (a7)+,d1
 move.l (a7)+,a0
 move.l (a7)+,a2
 
.noline:
 add.w #320,a2
 
 swap d1
 dbra d1,DOAHORLINE
 
NOPOLYGON:
polybehind:
 rts

TEXTUREPAL:

SAVESTACK: dc.l 0
HIGHPOLY: dc.w 0
LEN1: dc.w 0
BRIGHTNESS: dc.l 0
TRANSTEXT: dc.w 0
AANG: dc.w 0
BANG: dc.w 0
CANG: dc.w 0
DANG: dc.w 0

 include "ab3:print.s"
 
 temp: dc.w 0

DEPTHPTR: dc.l 0
LEFTX: dc.w 0
ZSPTR: dc.l 0

GOURPOLY: 
 
DOAHORLINEGOUR:
 swap d1

 ifeq SHADING
 move.w #128,16(a0)
 move.w #128,16+RIGHTUVS-LEFTUVS(a0)
 move.w #128,4+RIGHTUVS-LEFTUVS(a0)
 move.w #128,4(a0)
 endc

 move.w RIGHTUVS-LEFTUVS(a0),d0
 move.w (a0)+,d7
 asr.w #2,d0
 
 
 asr.w #2,d7
 move.w d7,LEFTX
 sub.w d7,d0
 bge.s .okflibble
 
 add.w #18,a0
 add.w #320,a2
 add.l #320*4,DEPTHPTR
 swap d1
 dbra d1,DOAHORLINEGOUR
 bra NOPOLYGON
 
.okflibble:
 
 move.l a2,-(a7)
 
 ifne POLYGONDEPTH
 move.l #LINEBUFFER,a2
 
 endc
 
 add.w d7,a2
 ext.l d0
 addq #1,d0
 
 move.b RIGHTUVS-LEFTUVS(a0),d3
 move.b (a0),d2
 
 ext.w d3
 ext.w d2
 
 tst.w d2
 blt .bothtowards

; bgt .firstaway
 tst.w d3
 blt .bothtowards
 bra .bothaway
 
.firsttowards:
 tst.w d3
 ble .bothtowards

; First is towards and second away...

 move.w d0,d7	; total length
 move.w d0,d6
 neg.w d2
 add.w d2,d3
 muls d2,d6
 divs d3,d6	; length of first bit
 sub.w d6,d7	; length of second bit
 move.w d6,FIRSTLEN
 move.w d7,LASTLEN
 
 tst.w FIRSTLEN
 beq .bothaway
 tst.w LASTLEN
 beq .bothtowards

 moveq #0,d2
 moveq #0,d3
 moveq #0,d4
 moveq #0,d5
 move.b 6(a0),d2
 move.b 7(a0),d3
 
 move.w d2,FIRSTU
 move.w d3,FIRSTV
 
 move.w d2,d4
 move.w d3,d5
 sub.w #128,d2
 sub.w #128,d3
 muls d2,d2
 muls d3,d3
 add.l d3,d2
 jsr CALCSQROOT

 tst.w d2
 beq.s .nochng

 sub.w #128,d4
 sub.w #128,d5
 muls #127,d4
 muls #127,d5
 divs d2,d4
 divs d2,d5
 add.w #128,d4
 add.w #128,d5
 
.nochng:
 
 move.w d4,MIDU
 move.w d5,MIDV
 
 move.b 6+RIGHTUVS-LEFTUVS(a0),d4
 move.b 7+RIGHTUVS-LEFTUVS(a0),d5
 move.w d4,SECU
 move.w d5,SECV
 
 move.w d4,d2
 move.w d5,d3

 sub.w #128,d2
 sub.w #128,d3
 muls d2,d2
 muls d3,d3
 add.l d3,d2
 jsr CALCSQROOT

 tst.w d2
 beq.s .nochng2

 sub.w #128,d4
 sub.w #128,d5
 muls #127,d4
 muls #127,d5
 divs d2,d4
 divs d2,d5
 add.w #128,d4
 add.w #128,d5
 
.nochng2:

 add.w MIDU,d4
 add.w MIDV,d5
 asr.w #1,d4
 asr.w #1,d5
 move.w d4,MIDU
 move.w d5,MIDV 
 
 move.l RIGHTUVS-LEFTUVS(a0),d7
 move.l (a0)+,d2 
 
 and.l #$ffffff,d2
 and.l #$ffffff,d7
 
 moveq #0,d3
 moveq #0,d5
 move.w d2,d3
; bge.s .okp1
; moveq #0,d3
;.okp1
 move.w d7,d5
; bge.s .okp2
; moveq #0,d5
;.okp2
 
 swap d3
 swap d5
 sub.l d3,d5
 divs.l d0,d5
 asr.l #8,d5
 move.w d5,RIGHTBRIGHT
 asr.l #8,d3
 move.w d3,LEFTBRIGHT
 
 clr.w d2
 clr.w d7
 sub.l d2,d7
 asl.l #8,d2
 divs.l d0,d7
 asl.l #8,d7

 move.l RIGHTUVS-LEFTUVS(a0),d6 
 move.l (a0)+,d3

 moveq #0,d4
 moveq #0,d5
 
; move.w d6,d5
; move.w d3,d4
; move.b #0,d4
; move.b #0,d5
 
 move.w FIRSTU,d4
 move.w MIDU,d5
 lsl.l #8,d4
 lsl.l #8,d5
 
 sub.l d4,d5
 divs.l FIRSTLEN-2,d5
 
 move.w d4,d2
 move.w d5,d7
 move.l d7,a1
 moveq #0,d4
 moveq #0,d5

; move.b d6,d5
; move.b d3,d4

; swap d5
; swap d4

 move.w FIRSTV,d4
 move.w MIDV,d5
 swap d4
 swap d5

 sub.l d4,d5
 divs.l FIRSTLEN-2,d5
 
 move.l d5,a3
 move.l d4,d5
  
 clr.w d3
 clr.w d6
 sub.l d3,d6
 divs.l d0,d6
 move.l d6,a4
 
 move.w RIGHTUVS-LEFTUVS(a0),d7
 move.w (a0)+,d4
 swap d7
 clr.w d7
 swap d4
 clr.w d4
 sub.l d4,d7
 divs.l d0,d7
 move.l d7,a5
 
; move.w RIGHTUVS-LEFTUVS(a0),d7
; swap d7
; clr.w d7
 move.w (a0)+,d7
; swap d5
; clr.w d5
; sub.l d5,d7
; divs.l d0,d7
; move.l d7,a6
 
 move.w RIGHTUVS-LEFTUVS(a0),d7
 swap d7
 clr.w d7
 move.w (a0)+,d6
 swap d6
 clr.w d6
 sub.l d6,d7
 divs.l d0,d7
 
 lsl.l #8,d6
 lsl.l #8,d7
 
 move.w RIGHTBRIGHT,d7
 move.l d7,a6
 
 
 move.l a0,-(a7)
 move.l d1,-(a7)
 move.l #TEXTURES,a0
 move.w TEXTUREADD,d7
 bge.s .okaddtes3
 and.w #$7fff,d7
 add.l #65536*4,a0
.okaddtes3:
 ext.l d7
; add.l d7,d7
 asl.l #8,d7
 add.l d7,a0
 move.w #0,d7
 
 move.w LEFTBRIGHT,d6
 
 subq #1,d0
 swap d0
 move.w HIGHPOLY,d0
 swap d0
 
 
; d0=xdist
; d2=U	a1=DU
; d3=V  a4=DV
; d4=X  a5=DX
; d5=Y  a6=DY
; d6=Z  a3=DZ
 
; d0= polynum : polynum : counter : counter
; d1= scratch : scratch : scratch : scratch
; d2= u : uacc : sv : svacc
; d3= v : v : vacc : vacc
; d4= x : x : xacc : xacc
; d5= su : su : suacc : suacc
; d6= z : zacc : bright : brightacc
; d7= scratch : scratch : scratch : scratch

; a0= textures
; a1= uspeed : uspeed : suspeed : suspeed
; a2= screen pointer
; a3= svspeed : svspeed : svspeed : svspeed
; a4= vspeed : vspeed : vspeed : vspeed
; a5= xspeed : xspeed : xspeed : xspeed
; a6= zspeed : zspeed :brightspeed : brightspeed
; a7= shadowmap pointer


 move.w FIRSTLEN,d0
 sub.w #1,d0
 bsr STARTLINE
 
 move.l #0,d5
 move.w #0,d2
 move.l #0,a3

 move.w LASTLEN,d0
 sub.w #1,d0

 bsr STARTLINE
 
 
 move.l (a7)+,d1
 move.l (a7)+,a0
 move.l (a7)+,a2
 
 bra .noline
 
.firstaway:
 tst.w d3
 bge .bothaway
 
 
; first is away and second is towards...

; this really isn't going to work...

 move.w d0,d7	; total length
 move.w d0,d6
 neg.w d3
 add.w d2,d3
 muls d2,d6
 divs d3,d6	; length of first bit
 sub.w d6,d7	; length of second bit
 move.w d6,FIRSTLEN
 move.w d7,LASTLEN
 
 tst.w FIRSTLEN
 beq .bothaway
 tst.w LASTLEN
 beq .bothtowards

 moveq #0,d2
 moveq #0,d3
 moveq #0,d4
 moveq #0,d5
 move.b 6(a0),d2
 move.b 7(a0),d3
 
 move.w d2,FIRSTU
 move.w d3,FIRSTV
 
 move.w d2,d4
 move.w d3,d5
 sub.w #128,d2
 sub.w #128,d3
 muls d2,d2
 muls d3,d3
 add.l d3,d2
 jsr CALCSQROOT

 tst.w d2
 beq.s .nochng22

 sub.w #128,d4
 sub.w #128,d5
 muls #127,d4
 muls #127,d5
 divs d2,d4
 divs d2,d5
 add.w #128,d4
 add.w #128,d5
 
.nochng22:
 
 move.w d4,MIDU
 move.w d5,MIDV
 
 moveq #0,d4
 moveq #0,d5
 move.b 6+RIGHTUVS-LEFTUVS(a0),d4
 move.b 7+RIGHTUVS-LEFTUVS(a0),d5
 move.w d4,SECU
 move.w d5,SECV
 
 move.w d4,d2
 move.w d5,d3

 sub.w #128,d2
 sub.w #128,d3
 muls d2,d2
 muls d3,d3
 add.l d3,d2
 jsr CALCSQROOT

 tst.w d2
 beq.s .nochng222

 sub.w #128,d4
 sub.w #128,d5
 muls #127,d4
 muls #127,d5
 divs d2,d4
 divs d2,d5
 add.w #128,d4
 add.w #128,d5
 
.nochng222:

 add.w MIDU,d4
 add.w MIDV,d5
 asr.w #1,d4
 asr.w #1,d5
 move.w d4,MIDU
 move.w d5,MIDV
 
 
 move.l RIGHTUVS-LEFTUVS(a0),d7
 move.l (a0)+,d2 
 
 and.l #$ffffff,d2
 and.l #$ffffff,d7
 
 moveq #0,d3
 moveq #0,d5
 move.w d2,d3
 move.w d7,d5
 swap d3
 swap d5
 sub.l d3,d5
 divs.l d0,d5
 asr.l #8,d5
 move.w d5,RIGHTBRIGHT
 asr.l #8,d3
 move.w d3,LEFTBRIGHT
 
 clr.w d2
 clr.w d7
 sub.l d2,d7
 asl.l #8,d2
 divs.l d0,d7
 asl.l #8,d7

 move.l RIGHTUVS-LEFTUVS(a0),d6 
 move.l (a0)+,d3

 moveq #0,d4
 moveq #0,d5
 
 move.w MIDU,d4
 move.w SECU,d5
 lsl.w #8,d4
 lsl.w #8,d5
 
; move.w d6,d5
; move.w d3,d4
; move.b #0,d4
; move.b #0,d5
 
 sub.l d4,d5
 divs.l LASTLEN-2,d5
 
 move.w d4,d2
 move.w d5,d7
 move.l d7,a1
 moveq #0,d4
 moveq #0,d5

 move.w MIDV,d4
 move.w SECV,d5

 swap d5
 swap d4

 sub.l d4,d5
 divs.l LASTLEN-2,d5
 
 move.l d5,a3
 move.l d4,d5

 clr.w d3
 clr.w d6
 sub.l d3,d6
 divs.l d0,d6
 move.l d6,a4
 
 move.w RIGHTUVS-LEFTUVS(a0),d7
 move.w (a0)+,d4
 swap d7
 clr.w d7
 swap d4
 clr.w d4
 sub.l d4,d7
 divs.l d0,d7
 move.l d7,a5
 
; move.w RIGHTUVS-LEFTUVS(a0),d7
; swap d7
; clr.w d7
 move.w (a0)+,d7
; swap d5
; clr.w d5
; sub.l d5,d7
; divs.l d0,d7
; move.l d7,a6
 
 move.w RIGHTUVS-LEFTUVS(a0),d7
 swap d7
 clr.w d7
 move.w (a0)+,d6
 swap d6
 clr.w d6
 sub.l d6,d7
 divs.l d0,d7
 
 lsl.l #8,d6
 lsl.l #8,d7
 
 move.w RIGHTBRIGHT,d7
 move.l d7,a6
 
 move.l a0,-(a7)
 move.l d1,-(a7)
 move.l #TEXTURES,a0
 move.w TEXTUREADD,d7
 bge.s .okaddtes4
 and.w #$7fff,d7
 add.l #65536*4,a0
.okaddtes4:
 ext.l d7
; add.l d7,d7
 asl.l #8,d7
 add.l d7,a0
 move.w #0,d7
 
 move.w LEFTBRIGHT,d6
 
 
 subq #1,d0
 swap d0
 move.w HIGHPOLY,d0
 swap d0
 
 
; d0=xdist
; d2=U	a1=DU
; d3=V  a4=DV
; d4=X  a5=DX
; d5=Y  a6=DY
; d6=Z  a3=DZ
 
; d0= polynum : polynum : counter : counter
; d1= scratch : scratch : scratch : scratch
; d2= u : uacc : sv : svacc
; d3= v : v : vacc : vacc
; d4= x : x : xacc : xacc
; d5= su : su : suacc : suacc
; d6= z : zacc : bright : brightacc
; d7= scratch : scratch : scratch : scratch

; a0= textures
; a1= uspeed : uspeed : suspeed : suspeed
; a2= screen pointer
; a3= svspeed : svspeed : svspeed : svspeed
; a4= vspeed : vspeed : vspeed : vspeed
; a5= xspeed : xspeed : xspeed : xspeed
; a6= zspeed : zspeed :brightspeed : brightspeed
; a7= shadowmap pointer

 move.w d2,-(a7)
 move.l d5,-(a7)
 move.l a3,-(a7)

 move.w #0,d2
 move.l #0,d5
 move.l #0,a3
 
 move.w FIRSTLEN,d0
 subq #1,d0
 bsr STARTLINE
 
 
 move.l (a7)+,a3
 move.l (a7)+,d5
 move.w (a7)+,d2
 
 move.w LASTLEN,d0
 subq #1,d0

 bsr STARTLINE
 
 
 move.l (a7)+,d1
 move.l (a7)+,a0
 move.l (a7)+,a2
 
 bra .noline

 
.bothaway:

 move.w #0,6+RIGHTUVS-LEFTUVS(a0)
 move.w #0,6(a0)

.bothtowards:
 
 ifne PH
 tst.w 16+RIGHTUVS-LEFTUVS(a0)
 blt.s .okone
 tst.w 16(a0)
 blt.s .okone
 
 move.w #0,2(a0)
 move.w #0,2+RIGHTUVS-LEFTUVS(a0)
 move.w #0,14(a0)
 move.w #0,14+RIGHTUVS-LEFTUVS(a0)
 
.okone:
 endc
 
 move.l RIGHTUVS-LEFTUVS(a0),d7
 move.l (a0)+,d2 
 
 and.l #$ffffff,d2
 and.l #$ffffff,d7
 
 moveq #0,d3
 moveq #0,d5
 move.w d2,d3
 move.w d7,d5
 swap d3
 swap d5
 sub.l d3,d5
 divs.l d0,d5
 asr.l #8,d5
 move.w d5,RIGHTBRIGHT
 asr.l #8,d3
 move.w d3,LEFTBRIGHT
 
 clr.w d2
 clr.w d7
 sub.l d2,d7
 asl.l #8,d2
 divs.l d0,d7
 asl.l #8,d7

 move.l RIGHTUVS-LEFTUVS(a0),d6 
 move.l (a0)+,d3

 moveq #0,d4
 moveq #0,d5
 
 move.w d6,d5
 move.w d3,d4
 move.b #0,d4
 move.b #0,d5
 
 sub.l d4,d5
 divs.l d0,d5
 
 move.w d4,d2
 move.w d5,d7
 move.l d7,a1
 moveq #0,d4
 moveq #0,d5

 move.b d6,d5
 move.b d3,d4

 swap d5
 swap d4

 sub.l d4,d5
 divs.l d0,d5
 
 move.l d5,a3
 move.l d4,d5

  
 clr.w d3
 clr.w d6
 sub.l d3,d6
 divs.l d0,d6
 
 asr.l #8,d3		; XX XX vpos vacc
 asr.l #8,d6 		; XX XX vspeed vspeed
 
; move.l d6,a4
 
 move.w RIGHTUVS-LEFTUVS(a0),d7
 move.w (a0)+,d4
 swap d7
 clr.w d7
 swap d4
 clr.w d4
 sub.l d4,d7
 divs.l d0,d7
 asl.l #8,d4
 asl.l #8,d7
 move.w d3,d4
 move.w d6,d7
 move.l d7,a5
 
; move.w RIGHTUVS-LEFTUVS(a0),d7
; swap d7
; clr.w d7
 move.w (a0)+,d7
; swap d5
; clr.w d5
; sub.l d5,d7
; divs.l d0,d7
; move.l d7,a6
 
 move.w RIGHTUVS-LEFTUVS(a0),d7
 swap d7
 clr.w d7
 move.w (a0)+,d6
 swap d6
 clr.w d6
 sub.l d6,d7
 divs.l d0,d7
 
 lsl.l #8,d6
 lsl.l #8,d7
 
 move.w RIGHTBRIGHT,d7
 move.l d7,a6
 
 moveq #0,d7
 moveq #0,d3
 move.w RIGHTUVS-LEFTUVS(a0),d7
 move.w (a0)+,d3
 
 addq #2,a0
 
 sub.w d3,d7
 swap d3
 swap d7
 divs.l d0,d7
 
 move.l d7,a4
 
 
 move.l a0,-(a7)
 move.l d1,-(a7)
 move.l #TEXTURES,a0
 move.w TEXTUREADD,d7
 bge.s .okaddtes5
 and.w #$7fff,d7
 add.l #65536*4,a0
.okaddtes5:
 ext.l d7
 asl.l #8,d7
 add.l d7,a0
 move.w #0,d7
 
 move.w LEFTBRIGHT,d6
 
 subq #1,d0
 swap d0
 move.w HIGHPOLY,d0
 swap d0
 
 
; d0=xdist
; d2=U	a1=DU
; d3=V  a4=DV
; d4=X  a5=DX
; d5=Y  a6=DY
; d6=Z  a3=DZ
 
; d0= polynum : polynum : counter : counter
; d1= scratch : scratch : scratch : scratch
; d2= u : uacc : sv : svacc
; d3= pxpos : pxpos : pxacc : pxacc
; d4= x : xacc : v : vacc
; d5= su : su : suacc : suacc
; d6= z : zacc : pypos : pyacc
; d7= scratch : scratch : scratch : scratch

; a0= textures
; a1= uspeed : uspeed : suspeed : suspeed
; a2= screen pointer
; a3= svspeed : svspeed : svspeed : svspeed
; a4= pxspd : pxspd : pxspd : pxspd
; a5= xspeed : xspeed : vspeed : vspeed
; a6= zspeed : zspeed : pyspeed : pyspeed
; a7= shadowmap pointer

 move.w d0,-(a7)
;
 bsr STARTLINE
 
 move.w (a7)+,d0
 move.l (a7)+,d1
 move.l (a7)+,a0
 move.l (a7)+,a2
 
 ifne DEPTHBALL!POLYGONDEPTH
 
 move.l a2,a5
 move.l DEPTHPTR,a3
 move.l #LINEBUFFER,a6
 move.w LEFTX,d4
 add.w d4,a6
 add.w d4,a5
 lea (a3,d4.w*4),a3
 
 move.l ZSPTR,a4
 move.w RIGHTZS-LEFTZS(a4),d7
 move.w (a4)+,d2
 move.l a4,ZSPTR
 
 
 sub.w d2,d7
 swap d2
 swap d7
 clr.w d2
 clr.w d7
 addq #1,d0
 ext.l d0
 
 divs.l d0,d7
 
 subq #1,d0
 
.dodepth:

 ifne POLYGONDEPTH
 
 move.l (a3)+,d6
 cmp.l d2,d6
 blt.s .dontplot

 move.l d2,-4(a3)
 move.b (a6),(a5)
 
.dontplot:
 addq #1,a6
 addq #1,a5
 
 endc
 ifeq POLYGONDEPTH

 move.l d2,(a3)+
 
 endc
 add.l d7,d2
 dbra d0,.dodepth
 
 endc
 
.noline:
 add.l #320*4,DEPTHPTR
 add.w #320,a2
 
 swap d1
 dbra d1,DOAHORLINEGOUR
 
 bra NOPOLYGON





*******************************
STARTLINE:

 move.l a7,SAVESTACK
 move.l #SHADOWBUFFER,a7

 moveq #0,d1
 swap d6
 move.w d6,d1
 move.l d4,d7
 swap d7
 lsr.w #8,d7
 move.b d7,d1
 swap d6
 
 swap d0
 moveq #0,d7
 move.b (a7,d1.l*2),d7
 cmp.w d7,d0
 ble .startlight
 swap d0
 bra INTHEDARKGOUR
.startlight:
 swap d0
 bra INTHELIGHTGOUR 
.startdark:
***********************************



PENUMBRAGOUR:
 moveq #0,d1
 swap d6
 move.w d6,d1
 move.l d4,d7
 lsr.l #8,d7
 swap d7
 move.b d7,d1
 swap d6
 add.l a5,d4
 add.l a6,d6
 add.l a3,d5

 swap d0
 moveq #0,d7
 move.b (a7,d1.l*2),d7
 cmp.w d7,d0
 ifne SHADOWMAP
 ble INTOLIGHTGOUR
 endc
 ifeq SHADOWMAP
 bra INTOLIGHTGOUR
 endc
 bra.s INTODARKGOUR
 
INTHEDARKGOUR:
 moveq #0,d1
 swap d6
 move.w d6,d1
 move.l d4,d7
 swap d7
 asr.w #8,d7
 move.b d7,d1
 swap d6
 add.l a5,d4
 add.l a6,d6
 add.l a3,d5

 swap d0
 moveq #0,d7
 move.b (a7,d1.l*2),d7
 cmp.w d7,d0
 ifne SHADOWMAP
 ble.s INTOPENUMGOUR
 endc
 ifeq SHADOWMAP
 bra INTOLIGHTGOUR
 endc
INTODARKGOUR:
 swap d0
 
;**********************
; moveq #0,d7
;********************** 
 
 swap d2
 move.w d2,d1
 move.w d4,d7
 lsr.w #8,d7
 move.b d7,d1
 swap d2
 add.l a1,d2
 add.l a4,d3
 
 move.l #(31*32*256),d7
 move.b 1(a0,d1.w*4),d7
 bra DARKplottt

.noplottt
 addq #1,a2
 dbra d0,INTHEDARKGOUR
 bra DONEDONEBUM

INTOPENUMGOUR:
 swap d0
 
*********************
; moveq #0,d7
*****************
 
 swap d2
 move.w d2,d1
 move.w d4,d7
 lsr.w #8,d7
 move.b d7,d1
 swap d2
 add.l a1,d2
 add.l a4,d3
 
 move.l (a0,d1.w*4),d1
 moveq #0,d7
 move.w d6,d7
 swap d3
 move.b d3,d7
 add.w d1,d7
 swap d3
 
 move.b 1(a7,d7.l*2),d7
 lsl.w #8,d7
 
; sub.w #$1c00,d7
 asr.w #1,d7
; add.w #$1c00,d7
 neg.w d7
 add.w #$1f00,d7
 sub.b d7,d7

 asl.l #5,d7
 swap d1
 move.b d1,d7
 
 
 bra.s PENUMplottt

.noplottt
 addq #1,a2
 dbra d0,PENUMBRAGOUR
 bra DONEDONEBUM


INTHELIGHTGOUR:

 moveq #0,d1
 swap d6
 move.w d6,d1
 move.l d4,d7
 swap d7
 lsr.w #8,d7
 move.b d7,d1
 swap d6
 add.l a5,d4
 add.l a6,d6
 add.l a3,d5

 swap d0
 moveq #0,d7
 move.b (a7,d1.l*2),d7
 cmp.w d7,d0
 
 
 ifne SHADOWMAP
 bgt.s INTOPENUMGOUR
 endc
 
INTOLIGHTGOUR:
 swap d0
 
 swap d2
 move.w d2,d1
 move.w d4,d7
 asr.w #8,d7
 move.b d7,d1
 swap d2

 move.l (a0,d1.w*4),d1		; SPEC COL OFX OFY
 
 add.l a1,d2
 add.l a4,d3

 bra.s LIGHTPLOTT
.noplottt:
 addq #1,a2
 dbra d0,INTHELIGHTGOUR
FLIBBLEY:
 bra.s DONEDONEBUM

PENUMplottt
 move.b GOURPAL(pc,d7.l),(a2)+
 dbra d0,PENUMBRAGOUR
 bra.s DONEDONEBUM

DARKplottt
 move.b GOURPAL(pc,d7.l),(a2)+
 dbra d0,INTHEDARKGOUR
 bra.s DONEDONEBUM

LIGHTPLOTT:
 moveq #0,d7
 
 move.w d2,d7
 swap d5
 move.b d5,d7
 swap d5
 
 ifne BUMPSPEC
 add.w d1,d7	; coord in spec map
 endc

 swap d1
 ifeq SPECMAP
 and.w #$ff,d1
 endc

 move.b 1(a7,d7.l*2),d7	; specular value of point.
 lsl.w #8,d7

 ifne SPECULAR 
 add.w d7,d1
 endc
 
 ifeq SPECULAR
 tst.w d1
 endc
 
 bgt.s .okshiney
 and.w #$ff,d1
.okshiney

 move.w d6,d7
 swap d3
 move.b d3,d7
 swap d1
 
 ifne BUMPPHONG
 add.w d1,d7
 endc
 
 clr.w d1
 swap d1
 move.b 1(a7,d7.l*2),d7 ; brightness of point
 neg.b d7
 add.b #31,d7
 and.w #$ff,d7
 swap d7
 lsr.l #3,d7
 swap d3
 add.l d7,d1
 
 move.b GOURPAL(pc,d1.l),(a2)+
 dbra d0,INTHELIGHTGOUR
DONEDONEBUM:
 move.l SAVESTACK,a7
 rts
 
GOURPAL: incbin "ab3:includes/bigshadow.pal"
 



LEFTSHINEV: dc.l 0
RIGHTSHINEV: dc.l 0
LEFTSHINEU: dc.l 0
RIGHTSHINEU: dc.l 0

TOPPTR: dc.l 0
TOPPTNUM: dc.w 0
BOTPTNUM: dc.w 0
LEFTBRIGHT: dc.w 0
RIGHTBRIGHT: dc.l 0
LEFTSPEC: dc.w 0
RIGHTSPEC: dc.w 0

***********************************************
	
SIMPLECALCLINE:

 ifne DEPTHQUEUE

 movem.l d0/d1,-(a7)

 move.l #ONSCREENPTS,a1

 move.w 2(a1,d0.w*4),d2		;fy
 move.w 2(a1,d1.w*4),d7		;sy

 move.l #RIGHTZS,a3
 asr.w #2,d2
 asr.w #2,d7
 cmp.w d2,d7
 beq .noline
 bgt.s .lineonright
 
 move.l #LEFTZS,a3
 exg d0,d1
 exg d2,d7 
.lineonright:

 move.l #ROTATEDPTS,a2
 muls #10,d0
 muls #10,d1
 move.w 8(a2,d0.w),d3
 move.w 8(a2,d1.w),d4
 
 sub.w d3,d4
 sub.w d2,d7
 
 ext.l d7
 swap d3
 clr.w d3
 swap d4
 clr.w d4
 divs.l d7,d4
 
 subq #1,d7
 lea (a3,d2.w*2),a3
 
.putindist:
 swap d3
 move.w d3,(a3)+
 swap d3
 add.l d4,d3
 dbra d7,.putindist

 movem.l (a7)+,d0/d1

 bra RESTOFDATA
 
.noline:
 movem.l (a7)+,d0/d1
 rts

RESTOFDATA:

 endc

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
 move.w d0,TOPPTNUM
 move.w d1,BOTPTNUM

 sub.w d2,d7
 move.w d2,d3
 muls #20,d3
 asl.w #4,d2
 add.w d3,a3
 move.l a3,TOPPTR
 
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
 move.l #SHADOWPTS,a1
 
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
 
 muls #10,d0
 muls #10,d1
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
 
 move.w 8(a1,d0.w),d0
 move.w 8(a1,d1.w),d1
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
 addq #4,a3
 swap d0
 add.l a1,d0
 dbra d1,.PUTINLINE
 
 tst.b Gouraud
 beq .noline
 
 move.w TOPPTNUM,d0
 move.w BOTPTNUM,d1
 move.l TOPPTR,a3
 moveq #0,d6
 move.w YDIFF,d6
 
 move.l #SPECBRIGHTS,a2
 
 moveq #0,d2
 moveq #0,d3
 move.b (a2,d0.w*4),d2
 move.b 1(a2,d0.w*4),d3
 sub.w #128,d2
 sub.w #128,d3
 
 move.w d2,d4
 move.w d3,d5
 muls ACOS,d2
 muls ASIN,d3
 sub.l d3,d2
 muls ASIN,d4
 muls ACOS,d5
 add.l d5,d4
 asl.l #2,d2
 swap d2
 asl.l #2,d4
 swap d4
 
 add.w #128,d2
 add.w #128,d4
 move.w d2,FSX
 move.w d4,FSY

 moveq #0,d2
 moveq #0,d3
 move.b (a2,d1.w*4),d2
 move.b 1(a2,d1.w*4),d3
 sub.w #128,d2
 sub.w #128,d3
 
 move.w d2,d4
 move.w d3,d5
 muls ACOS,d2
 muls ASIN,d3
 sub.l d3,d2
 muls ASIN,d4
 muls ACOS,d5
 add.l d5,d4
 asl.l #2,d2
 swap d2
 asl.l #2,d4
 swap d4
 
 add.w #128,d2
 add.w #128,d4
 move.w d2,SSX
 move.w d4,SSY

 
 move.w 2(a2,d0.w*4),d2
 move.w 2(a2,d1.w*4),d3
 
 asr.w #4,d2
 asr.w #4,d3
 
 bra .bothtowards
 
 tst.w d2
 blt .firsttowards
 bgt.s .firstaway

 tst.w d3
 ble .bothtowards
 bra .bothaway
 
.firstaway
 tst.w d3
 blt .sectowards
 bra .bothaway
 
.firsttowards:
 tst.w d3
 ble .bothtowards

; First one is towards, the second away.
; Do the line in two bits: one heading
; from the first point to the rim, the
; other heading from the rim to the second
; point and flagged as behind.

 move.w d6,d7	; total length to draw
 move.w d2,FIRSTY
 move.w d3,LASTY

 neg.w d2
 add.w d2,d3 	; total change in Y

 bra.s .onetowards
 
.sectowards:
 move.w d6,d7	; total length to draw
 move.w d2,FIRSTY
 move.w d3,LASTY
 neg.w d3
 add.w d2,d3

.onetowards:
 
 muls d2,d6
 divs d3,d6	; length of first bit of line.

 ext.l d6
 ext.l d7

 move.w d6,FIRSTLEN
 sub.l d6,d7
 move.w d7,LASTLEN

 add.l d7,d6

 move.w FIRSTY,d2
 move.w LASTY,d3
 swap d2
 clr.w d2
 swap d3
 clr.w d3
 sub.l d2,d3
 divs.l d6,d3
 move.l d3,a6
 move.l d2,d7
 
 moveq #0,d2
 moveq #0,d3
 moveq #0,d4
 moveq #0,d5
 move.b (a2,d0.w*4),d2
 move.b 1(a2,d0.w*4),d3
 
 move.w d2,FIRSTU
 move.w d3,FIRSTV
 
 move.w d2,d4
 move.w d3,d5
 sub.w #128,d2
 sub.w #128,d3
 muls d2,d2
 muls d3,d3
 add.l d3,d2
 jsr CALCSQROOT

 tst.w d2
 beq.s .nochng

 sub.w #128,d4
 sub.w #128,d5
 muls #127,d4
 muls #127,d5
 divs d2,d4
 divs d2,d5
 add.w #128,d4
 add.w #128,d5
 
.nochng:
 
 move.w d4,MIDU
 move.w d5,MIDV
 
 move.b (a2,d1.w*4),d4
 move.b 1(a2,d1.w*4),d5
 move.w d4,SECU
 move.w d5,SECV
 
; move.w d4,d2
; move.w d5,d3
;
; sub.w #128,d2
; sub.w #128,d3
; muls d2,d2
; muls d3,d3
; add.l d3,d2
; jsr CALCSQROOT
;
; tst.w d2
; beq.s .nochng2
;
; sub.w #128,d4
; sub.w #128,d5
; muls #127,d4
; muls #127,d5
; divs d2,d4
; divs d2,d5
; add.w #128,d4
; add.w #128,d5
; 
;.nochng2:
;
; add.w MIDU,d4
; add.w MIDV,d5
; asr.w #1,d4
; asr.w #1,d5
; move.w d4,MIDU
; move.w d4,MIDV
 
 move.l #NORMBRIGHTS,a2
 move.w (a2,d0.w*2),d0
 move.w (a2,d1.w*2),d1
 
 sub.w d0,d1
 swap d1
 swap d0
 divs.l d6,d1

 move.w FIRSTLEN,d6
 beq.s .nofirstbit
 ext.l d6

 moveq #0,d2
 moveq #0,d3
 moveq #0,d4
 moveq #0,d5
 move.w FIRSTU,d2
 move.w MIDU,d3
 move.w FIRSTV,d4
 move.w MIDV,d5

 sub.w d2,d3
 swap d2
 swap d3
 divs.l d6,d3
 move.l d3,a4

 sub.w d4,d5
 swap d4
 swap d5
 divs.l d6,d5
 move.l d5,a5
 
 bsr DOABITOFLINE
.nofirstbit:

 move.w LASTLEN,d6
 beq.s .nosecbit
 ext.l d6

 moveq #0,d2
 moveq #0,d3
 moveq #0,d4
 moveq #0,d5
 move.w MIDU,d2
 move.w SECU,d3
 move.w MIDV,d4
 move.w SECV,d5

 sub.w d2,d3
 swap d2
 swap d3
 divs.l d6,d3
 move.l d3,a4

 sub.w d4,d5
 swap d4
 swap d5
 divs.l d6,d5
 move.l d5,a5
 
 bsr DOABITOFLINE
.nosecbit:

 bra .noline

.bothaway
 
; Both are away, so do it simply.
 
.bothtowards:

; Both are towards, so do it simply and flag all
; points as towards.
 
 swap d2
 clr.w d2
 swap d3
 clr.w d3
 sub.l d2,d3
 divs.l d6,d3
 move.l d3,a6
 move.l d2,d7
 
 moveq #0,d2
 moveq #0,d3
 moveq #0,d4
 moveq #0,d5
; move.b (a2,d0.w*4),d2
; move.b (a2,d1.w*4),d3
; move.b 1(a2,d0.w*4),d4
; move.b 1(a2,d1.w*4),d5
 
 move.w FSX,d2
 move.w SSX,d3
 move.w FSY,d4
 move.w SSY,d5
 
 sub.w d2,d3
 swap d2
 swap d3
 divs.l d6,d3
 move.l d3,a4

 sub.w d4,d5
 swap d4
 swap d5
 divs.l d6,d5
 move.l d5,a5

 move.l #NORMBRIGHTS,a2
 movem.l d2/d4,-(a7)
 
 moveq #0,d2
 moveq #0,d3
 move.b (a2,d0.w*2),d2
 move.b 1(a2,d0.w*2),d3
 sub.w #128,d2
 sub.w #128,d3
 
 move.w d2,d4
 move.w d3,d5
 muls ACOS,d2
 muls ASIN,d3
 sub.l d3,d2
 muls ASIN,d4
 muls ACOS,d5
 add.l d5,d4
 asl.l #2,d2
 swap d2
 asl.l #2,d4
 swap d4
 
 add.w #128,d2
 add.w #128,d4
 move.w d2,FSX
 move.w d4,FSY

 moveq #0,d2
 moveq #0,d3
 move.b (a2,d1.w*2),d2
 move.b 1(a2,d1.w*2),d3
 sub.w #128,d2
 sub.w #128,d3
 
 move.w d2,d4
 move.w d3,d5
 muls ACOS,d2
 muls ASIN,d3
 sub.l d3,d2
 muls ASIN,d4
 muls ACOS,d5
 add.l d5,d4
 asl.l #2,d2
 swap d2
 asl.l #2,d4
 swap d4
 
 add.w #128,d2
 add.w #128,d4
 move.w d2,SSX
 move.w d4,SSY

 moveq #0,d0
 moveq #0,d1
 moveq #0,d3
 moveq #0,d5
 
 move.w FSY,d3
 move.w SSY,d5
 move.w FSX,d0
 move.w SSX,d1

 ext.l d0
 ext.l d1
 sub.w d0,d1
 swap d1
 swap d0
 divs.l d6,d1

 ext.l d3
 ext.l d5
 sub.w d3,d5
 swap d5
 swap d3
 divs.l d6,d5
 
 movem.l (a7)+,d2/d4

 move.l d6,-(a7)
 bsr DOABITOFLINE
 move.l (a7)+,d6

 move.w TOPPTNUM,d0
 move.w BOTPTNUM,d1
 move.l TOPPTR,a3
 move.l #NORMVECTS,a2
 muls #6,d0
 muls #6,d1
 moveq #0,d2
 moveq #0,d3
 move.w 2(a2,d0.w),d2	; firsty
 move.w 2(a2,d1.w),d3	; secy
 sub.w d2,d3
 swap d3
 swap d2
 divs.l d6,d3

 subq #1,d6
.stickiny
 swap d2
 move.w d2,18(a3)
 swap d2
 add.l d3,d2
 add.w #20,a3
 dbra d6,.stickiny
 
.noline:
 rts

 DOABITOFLINE:
 subq #1,d6

.STICKINGOUR:
 swap d7
 move.b d7,2(a3)
 swap d7
 add.l a6,d7
 swap d0
 move.w d0,4(a3)
 swap d0
 add.l d1,d0
 swap d2
 move.b d2,8(a3)
 swap d4
 move.b d4,9(a3)
 swap d4
 swap d3
 move.w d3,16(a3)
 swap d3
 add.l d5,d3
 
 adda.w #20,a3
 swap d2
 add.l a4,d2
 add.l a5,d4
 dbra d6,.STICKINGOUR

 rts

FIRSTY: dc.w 0
LASTY: dc.w 0
FIRSTU: dc.w 0
SECU: dc.w 0
FIRSTV: dc.w 0
SECV: dc.w 0
	dc.w 0
FIRSTLEN: dc.w 0
	dc.w 0
LASTLEN: dc.w 0
MIDU: dc.w 0
MIDV: dc.w 0

*!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!



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
 
 move.w d3,TOPLINE
 move.w d4,BOTLINE
 
 


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
**********************	************************
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


**********************************************************

UVCOORDS: ds.l 250
ROTATEDPTS: ds.l 250*4
SHADOWPTS: ds.l 250*4
ONSCREENPTS: ds.l 250

ZOFF:
 ifeq LARGESCREEN
 dc.w 768
 endc
 ifne LARGESCREEN
 dc.w 300
 endc
 
BALLXOFF: dc.w 0
BALLYOFF: dc.w 0
BALLZOFF: dc.w 0
	dc.w 999,0,0

	dc.w 0,0,0
	dc.w 0,0,0
	dc.w 0,0,0
	dc.w 0,0,0


BALLXANGPOS: dc.w 100,0
BALLYANGPOS: dc.w 150,0
BALLZANGPOS: dc.w 120,0

	dc.w 80,2000,100,200,100,1000
	dc.w 40,200,220,2000,150,1000
	dc.w 180,20,100,200,120,100
	dc.w 280,200,50,2000,170,100

LEFTRIGHT: ds.l 256

POLYGONDATA:
 ds.b 30000

OBJNAME: dc.b "ab3:vectobj/testcube",0
 even
doslibname: dc.b 'dos.library',0
 even
doslib: dc.l 0

****************************
 
SINETABLE:
 incbin "ab3:includes/bigsine"
 
 
YANG: dc.w 0
XANG: dc.w 0


xmouse: dc.w 0
ymouse: dc.w 0

spleen: dc.w 0
lastspleen: dc.w 0

COPIEDPAL:
 dc.w 256,0
 ds.l 3*256
 ds.l 10

SHADOWBUFFER:
HIGHLIGHT: incbin "work:temp/HIGHLIGHT"

PALETTEBIT:
; incbin "256palette"
; dc.w $ffff,$fffe
 
 incbin "ab3:shadowtex/shadowpal"

 include "ab3:source_4000/chunky.s"

willy: ds.w 48


PALS:
 ds.l 2*49

pregour: dc.b 0
Gouraud: dc.b 0

PointAngPtr: dc.l 0
FRAMENUM: dc.w 0
PolyAngPtr: dc.l 0
PtsPtr: dc.l 0
LinesPtr: dc.l 0
POINTER_TO_POINTERS: dc.l 0
FRAME: dc.w 4
FLIBBLE: dc.w 0
START_OF_OBJECT: dc.l 0
num_points: dc.w 0
num_frames: dc.w 0
SORTIT: dc.w 0
PartBuffer: ds.l 2*32
endparttab:

x1: dc.w 0
y1: dc.w 0
z1: dc.w 0
x2: dc.w 0
y2: dc.w 0
z2: dc.w 0
x2b: dc.w 0
y2b: dc.w 0
z2b: dc.w 0

x3: dc.w 0
y3: dc.w 0
z3: dc.w 0

l1: dc.w 0
l2: dc.w 0

OBJONOFF: dc.l 0

SAVEHIGHS: ds.w 30

FASTBUFFER:
 dc.l fasty
 
 DS.B 64*256
fasty: ds.b 320*256
 ds.b 64*256

; ifne MOTIONBLUR
fasty2:
 ds.b 320*256
; endc

NORMBRIGHTS: ds.w 250

SPECBRIGHTS:
 dcb.l 100,31

ENDNORM:

LEFTUVS: ds.w 10*256
RIGHTUVS: ds.w 10*256

LEFTZS: ds.w 256
RIGHTZS: ds.w 256

NORMVECTS: ds.w 3*250
 
;WORLD: incbin "ab3:includes/world"

;TWEEN: incbin "ab3:includes/tweenbrightfile"
 
LINEBUFFER: ds.b 320
 
NEBBIE: incbin "work:temp/nebbieroar"
	ds.l (192/4)*16
 
 SECTION blib,code_f
 
TEXTURES:
 incbin "ab3:shadowtex/shadowmaps"
 even

BLUR:
 ifne MOTIONBLUR!ANTIALIAS
 incbin "ab3:shadowtex/blurfile"
 endc
 
FIREPAL: incbin "ab3:includes/spleen.256pal"
 
DEPTHBUFFER: ds.l 320*256
 
BALL: incbin "ab3:includes/ballzbuff"
 
Font: dc.l fontplace

fontplace: incbin "ab3:XENFONT.bin"
 
 SECTION BGDROP,code_c
 
RAWSCRN:
 ds.l 2560*8

