
currzone:		dc.w	0

ty3d:			dc.l	-100*1024
by3d:			dc.l	1*1024

TOPOFROOM:		dc.l	0
BOTOFROOM:		dc.l	0
AFTERWATTOP:	dc.l	0
AFTERWATBOT:	dc.l	0
BEFOREWATTOP:	dc.l	0
BEFOREWATBOT:	dc.l	0
ROOMBACK:		dc.l	0

objclipt:		dc.w	0
objclipb:		dc.w	0
rightclipb:		dc.w	0
leftclipb:		dc.w	0
whichdoing:		dc.w	0

********************************************************************************

ObjDraw:
				move.w	(a0)+,d0
				cmp.w	#1,d0
				blt.s	beforewat
				beq.s	afterwat
				bgt.s	fullroom

beforewat:
				move.l	BEFOREWATTOP,ty3d
				move.l	BEFOREWATBOT,by3d
				move.b	#1,whichdoing
				bra.s	donetopbot

afterwat:
				move.l	AFTERWATTOP,ty3d
				move.l	AFTERWATBOT,by3d
				move.b	#0,whichdoing
				bra.s	donetopbot

fullroom:
				move.l	TOPOFROOM(pc),ty3d
				move.l	BOTOFROOM(pc),by3d
				move.b	#0,whichdoing

donetopbot:

; move.l (a0)+,by3d
; move.l (a0)+,ty3d

				movem.l	d0-d7/a1-a6,-(a7)

				move.w	rightclip,d0
				sub.w	leftclip,d0
				subq	#1,d0
				ble		doneallinfront

; CACHE_ON d6

				move.l	ObjectData,a1
				move.l	#ObjRotated,a2
				move.l	#depthtable,a3
				move.l	a3,a4
				move.w	#79,d7
emptytab:
				move.l	#$80010000,(a3)+
				dbra	d7,emptytab

				moveq	#0,d0
insertanobj
				move.w	(a1),d1
				blt		sortedall
				move.w	AI_EntT_GraphicRoom_w(a1),d2
				cmp.w	currzone(pc),d2
				beq.s	itsinthiszone

notinthiszone:
				adda.w	#64,a1
				addq	#1,d0
				bra		insertanobj

itsinthiszone:

				move.b	DOUPPER,d4
				move.b	ObjInTop(a1),d3
				eor.b	d4,d3
				bne.s	notinthiszone

				move.w	2(a2,d1.w*8),d1			; zpos

				move.l	#depthtable-4,a4
stillinfront:
				addq	#4,a4
				cmp.w	(a4),d1
				blt		stillinfront
				move.l	#enddepthtab-4,a5
finishedshift
				move.l	-(a5),4(a5)
				cmp.l	a4,a5
				bgt.s	finishedshift

				move.w	d1,(a4)
				move.w	d0,2(a4)

				adda.w	#64,a1
				addq	#1,d0

				bra		insertanobj

sortedall:

				move.l	#depthtable,a3

gobackanddoanother
				move.w	(a3)+,d0
				blt.s	doneallinfront

				move.w	(a3)+,d0
				bsr		DrawtheObject
				bra		gobackanddoanother

doneallinfront

				movem.l	(a7)+,d0-d7/a1-a6
				rts

depthtable:		ds.l	80
enddepthtab:

********************************************************************************

DrawtheObject:


				movem.l	d0-d7/a0-a6,-(a7)


				move.l	ObjectData,a0
				move.l	#ObjRotated,a1
				asl.w	#6,d0
				adda.w	d0,a0

				move.b	ObjInTop(a0),IMINTHETOPDAD

				move.w	(a0),d0
				move.w	2(a1,d0.w*8),d1			; z pos

; Go through clip pts to see which
; apply.

; move.w #0,d2	; leftclip
; move.w #96,d3  ; rightclip

; move.l EndOfClipPt,a6
;checkclips:
; subq #8,a6
; cmp.l #ClipTable,a6
; blt outofcheckclips

; cmp.w 2(a6),d1
; bgt.s cantleft
; move.w (a6),d4
; cmp.w d4,d2
; bgt.s cantleft
; move.w d4,d2
;cantleft:

; cmp.w 6(a6),d1
; bgt.s cantright
; move.w 4(a6),d4
; cmp.w d4,d3
; blt.s cantright
; move.w d4,d3
;cantright:

;outofcheckclips:

; move.w d2,leftclipb
; move.w d3,rightclipb

				move.w	leftclip,leftclipb
				move.w	rightclip,rightclipb

				cmp.b	#$ff,6(a0)
				bne		BitMapObj

				bsr		PolygonObj
				movem.l	(a7)+,d0-d7/a0-a6
				rts

********************************************************************************
* Glass objects are not suported and likely broken
;				IFNE	0
;glassobj:
;				move.w	(a0)+,d0				;pt num
;				move.w	2(a1,d0.w*8),d1
;				cmp.w	#25,d1
;				ble		objbehind
;
;				move.w	topclip,d2
;				move.w	botclip,d3
;
;				move.l	ty3d,d6
;				sub.l	yoff,d6
;				divs	d1,d6
;				add.w	MIDDLEY,d6
;				cmp.w	d3,d6
;				bge		objbehind
;				cmp.w	d2,d6
;				bge.s	.okobtc
;				move.w	d2,d6
;.okobtc:
;				move.w	d6,objclipt
;
;				move.l	by3d,d6
;				sub.l	yoff,d6
;				divs	d1,d6
;				add.w	MIDDLEY,d6
;				cmp.w	d2,d6
;				ble		objbehind
;				cmp.w	d3,d6
;				ble.s	.okobbc
;				move.w	d3,d6
;.okobbc:
;				move.w	d6,objclipb
;
;				move.l	4(a1,d0.w*8),d0
;				move.l	(a0)+,d2				; height
;				ext.l	d2
;				asl.l	#7,d2
;				sub.l	yoff,d2
;				divs	d1,d2
;				add.w	MIDDLEY,d2
;
;				divs	d1,d0
;				asr.w	d0						; DOUBLEWIDTH test
;
;				add.w	MIDDLEX,d0				;x pos of middle
;
;; Need to calculate:
;; Width of object in pixels
;; height of object in pixels
;; horizontal constants
;; vertical constants.
;
;				move.l	#consttab,a3
;
;				moveq	#0,d3
;				moveq	#0,d4
;				move.b	(a0)+,d3
;				move.b	(a0)+,d4
;				asl.w	#7,d3
;				asl.w	#7,d4
;				divs	d1,d3					;width in pixels
;				divs	d1,d4					;height in pixels
;				sub.w	d4,d2
;				sub.w	d3,d0
;				cmp.w	rightclipb,d0
;				bge		objbehind
;				add.w	d3,d3
;				cmp.w	objclipb,d2
;				bge		objbehind
;
;				add.w	d4,d4
;
;				move.w	d3,realwidth
;				move.w	d4,realheight
;
;* OBTAIN POINTERS TO HORIZ AND VERT
;* CONSTANTS FOR MOVING ACROSS AND
;* DOWN THE OBJECT GRAPHIC.
;
;				move.w	d1,d7
;				moveq	#0,d6
;				move.b	6(a0),d6
;				add.w	d6,d6
;				mulu	d6,d7
;				move.b	-2(a0),d6
;				divu	d6,d7
;				swap	d7
;				clr.w	d7
;				swap	d7
;
;				lea		(a3,d7.l*8),a2			; pointer to
;; horiz const
;				move.w	d1,d7
;				move.b	7(a0),d6
;				add.w	d6,d6
;				mulu	d6,d7
;				move.b	-1(a0),d6
;				divu	d6,d7
;				swap	d7
;				clr.w	d7
;				swap	d7
;				lea		(a3,d7.l*8),a3			; pointer to
;; vertical c.
;
;* CLIP OBJECT TO TOP AND BOTTOM
;* OF THE VISIBLE DISPLAY
;
;				moveq	#0,d7
;				cmp.w	objclipt,d2
;				bge.s	.objfitsontop
;
;				sub.w	objclipt,d2
;				add.w	d2,d4					;new height in
;;pixels
;				ble		objbehind				; nothing to draw
;
;				move.w	d2,d7
;				neg.w	d7						; factor to mult.
;; constants by
;; at top of obj.
;				move.w	objclipt,d2
;
;.objfitsontop:
;
;				move.w	objclipb,d6
;				sub.w	d2,d6
;				cmp.w	d6,d4
;				ble.s	.objfitsonbot
;
;				move.w	d6,d4
;
;.objfitsonbot:
;
;				subq	#1,d4
;				blt		objbehind
;
;				move.l	#ontoscr,a6
;				move.l	(a6,d2.w*4),d2
;
;				add.l	FASTBUFFER,d2
;				move.l	d2,toppt
;
;				move.l	#WorkSpace,a5
;				move.l	#glassball,a4
;				cmp.w	leftclipb,d0
;				bge.s	.okonleft
;
;				sub.w	leftclipb,d0
;				add.w	d0,d3
;				ble		objbehind
;
;				move.w	(a2),d1
;				move.w	2(a2),d2
;				neg.w	d0
;				muls	d0,d1
;				mulu	d0,d2
;				swap	d2
;				add.w	d2,d1
;				asl.w	#7,d1
;				lea		(a5,d1.w),a5
;				lea		(a4,d1.w),a4
;
;				move.w	leftclipb,d0
;
;.okonleft:
;
;				move.w	d0,d6
;				add.w	d3,d6
;				sub.w	rightclipb,d6
;				blt.s	.okrightside
;
;				sub.w	#1,d3
;				sub.w	d6,d3
;
;.okrightside:
;				move.w	d0,a1
;				add.w	a1,a1
;
;				move.w	(a3),d5
;				move.w	2(a3),d6
;				muls	d7,d5
;				mulu	d7,d6
;				swap	d6
;				add.w	d6,d5
;; add.w 2(a0),d5	;d5 contains
;;top offset into
;;each strip.
;				add.l	#$80000000,d5
;
;				move.l	(a2),d6
;				moveq.l	#0,d7
;				move.l	a5,midobj
;				move.l	a4,midglass
;				move.l	(a3),d2
;				swap	d2
;				move.l	#times128,a0
;
;				movem.l	d0-d7/a0-a6,-(a7)
;
;				move.w	d3,d1
;				ext.l	d1
;				swap	d1
;				move.w	d4,d2
;				ext.l	d2
;				swap	d2
;				asr.l	#6,d1
;				asr.l	#6,d2
;				move.w	d1,d5
;				move.w	d2,d6
;				swap	d1
;				swap	d2
;
;				muls	#SCREENWIDTH,d2
;
;				move.l	#WorkSpace,a0
;
;				move.w	#63,d0
;.readinto:
;				swap	d0
;				move.w	#63,d0
;				move.l	toppt(pc),a6
;				adda.w	a1,a6
;				add.w	d1,a1
;				add.w	d5,d7
;				bcc.s	.noadmoreh
;				addq	#1,a1
;.noadmoreh:
;				swap	d7
;				move.w	#0,d7
;.readintodown:
;				move.w	(a6),d3
;				move.w	d3,(a0)+
;				add.w	d2,a6
;				add.w	d6,d7
;				bcc.s	.noadmore
;				adda.w	#SCREENWIDTH,a6
;.noadmore:
;				dbra	d0,.readintodown
;				swap	d0
;				swap	d7
;				dbra	d0,.readinto
;
;
;; Want to zoom an area d3*d4
;; in size up to 64*64 in size.
;; move.l #WorkSpace,a0
;; move.l frompt,a2
;; move.w #104*4,d3
;; move.w #1,d6
;;.ribl
;; move.w #31,d0
;;.readinto
;; move.w #15,d1
;; move.l a2,a1
;;.readintodown
;; move.w (a1),(a0)+
;; adda.w d3,a1
;; move.w (a1),(a0)+
;; adda.w d3,a1
;; move.w (a1),(a0)+
;; adda.w d3,a1
;; move.w (a1),(a0)+
;; adda.w d3,a1
;; dbra d1,.readintodown
;;; add.w #256-128,a0
;; addq #4,a2
;; dbra d0,.readinto
;; addq #4,a2
;; dbra d6,.ribl
;
;				movem.l	(a7)+,d0-d7/a0-a6
;
;				move.l	#darkentab,a2
;				move.l	toppt,d1
;				add.l	a1,d1
;				move.l	d1,toppt
;				move.l	d6,a1
;				moveq	#0,d6
;
;.drawrightside:
;				swap	d7
;				move.l	midglass(pc),a4
;				adda.w	(a0,d7.w*2),a4
;				swap	d7
;				add.l	a1,d7
;				move.l	toppt(pc),a6
;				addq.l	#1,toppt
;
;				move.l	d5,d1
;				move.w	d4,-(a7)
;				swap	d3
;.drawavertstrip
;				move.w	(a4,d1.w*2),d3
;				blt.s	.itsbackground
;				move.b	(a5,d3.w*2),d6
;				move.b	(a2,d6.w),(a6)
;.itsbackground
;				adda.w	#SCREENWIDTH,a6
;				addx.l	d2,d1
;				dbra	d4,.drawavertstrip
;				swap	d3
;				move.w	(a7)+,d4
;
;				dbra	d3,.drawrightside
;				movem.l	(a7)+,d0-d7/a0-a6
;
;				rts
;
;				ENDC

********************************************************************************

realwidth:		dc.w	0
realheight:		dc.w	0

AUXX:			dc.w	0
AUXY:			dc.w	0

midglass:
				dc.l	0
times128:
val				SET		0
				REPT	100
				dc.w	val*128
val				SET		val+1
				ENDR

BRIGHTTOADD:	dc.w	0

glareobj:


				move.w	(a0)+,d0				;pt num
				move.w	2(a1,d0.w*8),d1
				cmp.w	#25,d1
				ble		objbehind

				move.w	topclip,d2
				move.w	botclip,d3

				move.l	ty3d,d6
				sub.l	yoff,d6
				divs	d1,d6
				add.w	MIDDLEY,d6
				cmp.w	d3,d6
				bge		objbehind
				cmp.w	d2,d6
				bge.s	.okobtc
				move.w	d2,d6
.okobtc:
				move.w	d6,objclipt

				move.l	by3d,d6
				sub.l	yoff,d6
				divs	d1,d6
				add.w	MIDDLEY,d6
				cmp.w	d2,d6
				ble		objbehind
				cmp.w	d3,d6
				ble.s	.okobbc
				move.w	d3,d6
.okobbc:
				move.w	d6,objclipb
				move.l	4(a1,d0.w*8),d0

				move.w	AUXX,d2
				ext.l	d2
				asl.l	#7,d2
				add.l	d2,d0
				addq	#2,a0
				move.l	TexturePal,a4
				sub.l	#512,a4

				move.w	(a0)+,d2				; height
				add.w	AUXY,d2
				ext.l	d2
				asl.l	#7,d2
				sub.l	yoff,d2
				divs	d1,d2
				add.w	MIDDLEY,d2

				divs	d1,d0
				add.w	MIDDLEX,d0				;x pos of middle

; Need to calculate:
; Width of object in pixels
; height of object in pixels
; horizontal constants
; vertical constants.
				move.l	LINKFILE,a6
				lea		FrameData(a6),a6
				move.l	#Objects,a5
				move.w	2(a0),d7
				neg.w	d7
				asl.w	#4,d7
				adda.w	d7,a5
				asl.w	#4,d7
				adda.w	d7,a6

				move.w	4(a0),d7
				lea		(a6,d7.w*8),a6

				move.l	#consttab,a3

				moveq	#0,d3
				moveq	#0,d4
				move.b	(a0)+,d3
				move.b	(a0)+,d4
				lsl.l	#7,d3
				lsl.l	#7,d4
				divs	d1,d3					;width in pixels
				divs	d1,d4					;height in pixels

				sub.w	d4,d2
				sub.w	d3,d0
				cmp.w	rightclipb,d0
				bge		objbehind
				add.w	d3,d3
				cmp.w	objclipb,d2
				bge		objbehind

				add.w	d4,d4

* OBTAIN POINTERS TO HORIZ AND VERT
* CONSTANTS FOR MOVING ACROSS AND
* DOWN THE OBJECT GRAPHIC.

				move.l	(a5)+,WAD_PTR
				move.l	(a5)+,PTR_PTR

				move.l	(a6),d7
				move.w	d7,DOWN_STRIP
				move.l	PTR_PTR,a5
				swap	d7
				asl.w	#2,d7
				adda.w	d7,a5

				move.w	d1,d7
				moveq	#0,d6
				move.w	4(a6),d6
				add.w	d6,d6
				subq	#1,d6
				mulu	d6,d7
				moveq	#0,d6
				move.b	-2(a0),d6
				beq		objbehind
				divu	d6,d7
				swap	d7
				clr.w	d7
				swap	d7
				lea		(a3,d7.l*8),a2			; pointer to
; horiz const
				move.w	d1,d7
				move.w	6(a6),d6
				add.w	d6,d6
				subq	#1,d6
				mulu	d6,d7
				moveq	#0,d6
				move.b	-1(a0),d6
				beq		objbehind
				divu	d6,d7
				swap	d7
				clr.w	d7
				swap	d7

				lea		(a3,d7.l*8),a3			; pointer to vertical c.

* CLIP OBJECT TO TOP AND BOTTOM
* OF THE VISIBLE DISPLAY

				moveq	#0,d7
				cmp.w	objclipt,d2
				bge.s	objfitsontopGLARE

				sub.w	objclipt,d2
				add.w	d2,d4					;new height in pixels
				ble		objbehind				; nothing to draw

				move.w	d2,d7
				neg.w	d7						; factor to mult.
; constants by
; at top of obj.
				move.w	objclipt,d2

objfitsontopGLARE:

				move.w	objclipb,d6
				sub.w	d2,d6
				cmp.w	d6,d4
				ble.s	objfitsonbotGLARE

				move.w	d6,d4

objfitsonbotGLARE:

				subq	#1,d4
				blt		objbehind

				move.l	#ontoscr,a6
				move.l	(a6,d2.w*4),d2
				add.l	FASTBUFFER,d2
				move.l	d2,toppt

				cmp.w	leftclipb,d0
				bge.s	okonleftGLARE

				sub.w	leftclipb,d0
				add.w	d0,d3
				ble		objbehind

				move.w	(a2),d1
				move.w	2(a2),d2
				neg.w	d0
				muls	d0,d1
				mulu	d0,d2
				swap	d2
				add.w	d2,d1
				lea		(a5,d1.w*4),a5

				move.w	leftclipb,d0

okonleftGLARE:

				move.w	d0,d6
				add.w	d3,d6
				sub.w	rightclipb,d6
				blt.s	okrightsideGLARE

				sub.w	#1,d3
				sub.w	d6,d3

okrightsideGLARE:

				ext.l	d0
				add.l	d0,toppt


				move.w	(a3),d5
				move.w	2(a3),d6
				muls	d7,d5
				mulu	d7,d6
				swap	d6
				add.w	d6,d5
				add.w	DOWN_STRIP(PC),d5		;d5 contains
;top offset into
;each strip.
				add.l	#$80000000,d5

				move.l	(a2),a2
				moveq.l	#0,d7
				move.l	a5,midobj
				move.l	(a3),d2
				swap	d2

				move.l	#0,a1


drawrightsideGLARE:
				swap	d7
				move.l	midobj(pc),a5
				lea		(a5,d7.w*4),a5
				swap	d7
				add.l	a2,d7					; step fractional column


				move.l	WAD_PTR(PC),a0

				move.l	toppt(pc),a6
				adda.w	a1,a6
				addq	#1,a1
				move.l	(a5),d1
				beq		blankstripGLARE

				and.l	#$ffffff,d1
				add.l	d1,a0

				move.b	(a5),d1
				cmp.b	#1,d1
				bgt.s	ThirdThirdGLARE
				beq.s	SecThirdGLARE
				move.l	d5,d6
				move.l	d5,d1
				move.w	d4,-(a7)
.drawavertstrip
				move.b	1(a0,d1.w*2),d0
				and.b	#%00011111,d0
				beq.s	.dontplotthisoneitsblack
				lsl.w	#8,d0
				add.w	d0,d0
				move.b	(a6),d0
				move.b	(a4,d0.w),(a6)
.dontplotthisoneitsblack:
				adda.w	#SCREENWIDTH,a6
				add.l	d2,d6
				addx.w	d2,d1
				dbra	d4,.drawavertstrip
				move.w	(a7)+,d4
blankstripGLARE:
				dbra	d3,drawrightsideGLARE
				bra		objbehind

SecThirdGLARE:
				move.l	d5,d1
				move.l	d5,d6
				move.w	d4,-(a7)
.drawavertstrip
				move.w	(a0,d1.w*2),d0
				lsr.w	#5,d0
				and.w	#%11111,d0
				beq.s	.dontplotthisoneitsblack
				lsl.w	#8,d0
				add.w	d0,d0
				move.b	(a6),d0
				move.b	(a4,d0.w),(a6)
.dontplotthisoneitsblack:
				adda.w	#SCREENWIDTH,a6
				add.l	d2,d6
				addx.w	d2,d1
				dbra	d4,.drawavertstrip
				move.w	(a7)+,d4
				dbra	d3,drawrightsideGLARE
				bra		objbehind

ThirdThirdGLARE:
				move.l	d5,d1
				move.l	d5,d6
				move.w	d4,-(a7)
.drawavertstrip
				move.b	(a0,d1.w*2),d0
				lsr.b	#2,d0
				and.b	#%11111,d0
				beq.s	.dontplotthisoneitsblack
				lsl.w	#8,d0
				add.w	d0,d0
				move.b	(a6),d0
				move.b	(a4,d0.w),(a6)
.dontplotthisoneitsblack:
				adda.w	#SCREENWIDTH,a6
				add.l	d2,d6
				addx.w	d2,d1
				dbra	d4,.drawavertstrip
				move.w	(a7)+,d4
				dbra	d3,drawrightsideGLARE

				movem.l	(a7)+,d0-d7/a0-a6
				rts



BitMapObj:
				move.l	#0,AUXX

				cmp.b	#3,16(a0)
				bne.s	.NOTAUX

				move.w	auxxoff(a0),AUXX
				move.w	auxyoff(a0),AUXY

.NOTAUX:

				tst.l	8(a0)
				blt		glareobj

				move.w	AI_EntT_CurrentAngle_w(a0),FACINGANG

				move.w	(a0)+,d0				;pt num

				move.l	ObjectPoints,a4

				move.w	(a4,d0.w*8),thisxpos
				move.w	4(a4,d0.w*8),thiszpos

				move.w	2(a1,d0.w*8),d1
				cmp.w	#25,d1
				ble		objbehind

				move.w	topclip,d2
				move.w	botclip,d3

				move.l	ty3d,d6
				sub.l	yoff,d6
				divs	d1,d6
				add.w	MIDDLEY,d6

				cmp.w	d3,d6
				bge		objbehind

				cmp.w	d2,d6
				bge.s	.okobtc
				move.w	d2,d6
.okobtc:
				move.w	d6,objclipt				; top object clip

				move.l	by3d,d6
				sub.l	yoff,d6
				divs	d1,d6
				add.w	MIDDLEY,d6
				cmp.w	d2,d6					; bottom of object over top of screen?

				ble		objbehind
				cmp.w	d3,d6
				ble.s	.okobbc
				move.w	d3,d6					; clip bottom of object to lower clip
.okobbc:
				move.w	d6,objclipb				; bottom object clip

				move.l	4(a1,d0.w*8),d0
				move.w	AUXX,d2
				ext.l	d2
				asl.l	#7,d2
				add.l	d2,d0

				move.w	d1,d6
				asr.w	#6,d6
				add.w	(a0)+,d6
				move.w	d6,BRIGHTTOADD

				bge.s	brighttoonot
				moveq	#0,d6
brighttoonot
				sub.l	a4,a4
				move.w	objscalecols(pc,d6.w*2),a4 ; is this the table that scales vertically?
				bra		pastobjscale

objscalecols:
				dcb.w	1,64*0
				dcb.w	2,64*1
				dcb.w	2,64*2
				dcb.w	2,64*3
				dcb.w	2,64*4
				dcb.w	2,64*5
				dcb.w	2,64*6
				dcb.w	2,64*7
				dcb.w	2,64*8
				dcb.w	2,64*9
				dcb.w	2,64*10
				dcb.w	2,64*11
				dcb.w	2,64*12
				dcb.w	2,64*13
				dcb.w	2,64*14
				dcb.w	2,64*15
				dcb.w	2,64*16
				dcb.w	2,64*17
				dcb.w	2,64*18
				dcb.w	2,64*19
				dcb.w	2,64*20
				dcb.w	2,64*21
				dcb.w	2,64*22
				dcb.w	2,64*23
				dcb.w	2,64*24
				dcb.w	2,64*25
				dcb.w	2,64*26
				dcb.w	2,64*27
				dcb.w	2,64*28
				dcb.w	2,64*29
				dcb.w	2,64*30
				dcb.w	20,64*31

WHICHLIGHTPAL:	dc.w	0
FLIPIT:			dc.w	0						; BOOL flip on/off
FLIPPEDIT:		dc.w	0
LIGHTIT:		dc.w	0						; BOOL Lighting for object on/off
ADDITIVE:		dc.w	0						; BOOL Additive translucency for object on/off
BASEPAL:		dc.l	0

pastobjscale:

				move.w	(a0)+,d2				; height
				add.w	AUXY,d2
				ext.l	d2
				asl.l	#7,d2
				sub.l	yoff,d2
				divs	d1,d2
				add.w	MIDDLEY,d2


				divs	d1,d0
				add.w	MIDDLEX,d0				;x pos of middle

; Need to calculate:
; Width of object in pixels
; height of object in pixels
; horizontal constants
; vertical constants.

				move.l	LINKFILE,a6
				lea		FrameData(a6),a6
				move.l	#Objects,a5
				move.w	2(a0),d7
				asl.w	#4,d7
				adda.w	d7,a5					; a5 pointing to?
				asl.w	#4,d7
				adda.w	d7,a6					; a6 pointing to?

				clr.b	LIGHTIT
				clr.b	ADDITIVE
				move.b	4(a0),d7
				btst	#7,d7
				sne		FLIPIT
				and.b	#127,d7
				sub.b	#2,d7
				blt.s	.NOTALIGHT

				cmp.b	#4,d7
				blt.s	.isalight

				st		ADDITIVE
				bra.s	.NOTALIGHT
.isalight:

				st		LIGHTIT
				move.b	d7,WHICHLIGHTPAL

.NOTALIGHT:

				moveq	#0,d7
				move.b	5(a0),d7				; current frame of animation
				lea		(a6,d7.w*8),a6			; a6 pointing to frame?

				move.l	#consttab,a3

				moveq	#0,d3
				moveq	#0,d4
				move.b	(a0)+,d3
				move.b	(a0)+,d4
				lsl.l	#7,d3
				lsl.l	#7,d4
				divs	d1,d3					;width in pixels
				divs	d1,d4					;height in pixels

				sub.w	d4,d2
				sub.w	d3,d0
				cmp.w	rightclipb,d0
				bge		objbehind
				add.w	d3,d3
				cmp.w	objclipb,d2
				bge		objbehind

				add.w	d4,d4

* OBTAIN POINTERS TO HORIZ AND VERT
* CONSTANTS FOR MOVING ACROSS AND
* DOWN THE OBJECT GRAPHIC.

				move.l	(a5)+,WAD_PTR
				move.l	(a5)+,PTR_PTR
				add.l	4(a5),a4				; a5: #Objects
				move.l	4(a5),BASEPAL

				move.l	(a6),d7					; pointer to current frame
				move.w	d7,DOWN_STRIP			; leftmost strip?
				move.l	PTR_PTR,a5

				tst.b	FLIPIT
				beq.s	.nfl1

				move.w	4(a6),d6				; mhhm, somehow this flips the frame?
				add.w	d6,d6					; go to next frame and subtract
				subq	#1,d6
				lea		(a5,d6.w*4),a5

.nfl1:
				swap	d7
				asl.w	#2,d7
				adda.w	d7,a5
fl1:

				move.w	d1,d7
				moveq	#0,d6
				move.w	4(a6),d6
				add.w	d6,d6
				subq	#1,d6
				mulu	d6,d7
				moveq	#0,d6
				move.b	-2(a0),d6
				beq		objbehind
				divu	d6,d7
				swap	d7
				clr.w	d7
				swap	d7
				lea		(a3,d7.l*8),a2			; pointer to
; horiz const
				move.w	d1,d7
				move.w	6(a6),d6
				add.w	d6,d6
				subq	#1,d6
				mulu	d6,d7
				moveq	#0,d6
				move.b	-1(a0),d6
				beq		objbehind
				divu	d6,d7

				swap	d7
				clr.w	d7
				swap	d7
				lea		(a3,d7.l*8),a3			; pointer to vertical scale table?
; vertical c.

* CLIP OBJECT TO TOP AND BOTTOM
* OF THE VISIBLE DISPLAY

				moveq	#0,d7
				cmp.w	objclipt,d2
				bge.s	objfitsontop

				sub.w	objclipt,d2
				add.w	d2,d4					;new height in
;pixels
				ble		objbehind				; nothing to draw

				move.w	d2,d7
				neg.w	d7						; factor to mult.
; constants by
; at top of obj.
				move.w	objclipt,d2

objfitsontop:

				move.w	objclipb,d6
				sub.w	d2,d6
				cmp.w	d6,d4
				ble.s	objfitsonbot

				move.w	d6,d4

objfitsonbot:

				subq	#1,d4
				blt		objbehind

				move.l	#ontoscr,a6
				move.l	(a6,d2.w*4),d2
				add.l	FASTBUFFER,d2
				move.l	d2,toppt

				cmp.w	leftclipb,d0
				bge.s	okonleft

				sub.w	leftclipb,d0
				add.w	d0,d3
				ble		objbehind

				move.w	(a2),d1
				move.w	2(a2),d2
				neg.w	d0
				muls	d0,d1
				mulu	d0,d2
				swap	d2
				add.w	d2,d1
				move.w	leftclipb,d0

				asl.w	#2,d1
				tst.b	FLIPIT
				beq.s	.nfl2

				suba.w	d1,a5
				suba.w	d1,a5

.nfl2:

				adda.w	d1,a5

okonleft:

				move.w	d0,d6
				add.w	d3,d6
				sub.w	rightclipb,d6
				blt.s	okrightside

				sub.w	#1,d3
				sub.w	d6,d3

okrightside:

				ext.l	d0
				add.l	d0,toppt

				move.w	(a3),d5
				move.w	2(a3),d6
				muls	d7,d5
				mulu	d7,d6
				swap	d6
				add.w	d6,d5
				add.w	DOWN_STRIP(PC),d5		;d5 contains
											;top offset into
											;strip?
				add.l	#$80000000,d5

				move.l	(a2),d7					; what is a2 pointing to?
				tst.b	FLIPIT
				beq.s	.nfl3
				neg.l	d7
.nfl3:
				move.l	d7,a2					; store fractional column offset
				moveq.l	#0,d7
				move.l	a5,midobj
				move.l	(a3),d2
				swap	d2

				move.l	#0,a1

				tst.b	LIGHTIT
				bne		DRAWITLIGHTED

				tst.b	ADDITIVE
				bne		DRAWITADDED

drawrightside:
				swap	d7
				move.l	midobj(pc),a5
				lea		(a5,d7.w*4),a5
				swap	d7
				add.l	a2,d7					; fractional column advance?

				move.l	WAD_PTR(PC),a0

				move.l	toppt(pc),a6
				adda.w	a1,a6
				addq	#1,a1
				move.l	(a5),d1
				beq		blankstrip

				and.l	#$ffffff,d1
				add.l	d1,a0

				move.b	(a5),d1
				; I think the vertical strips are stored as 5 bit (32cols)
				; To not waste memory, 3 strips are stored in 16bit words
				; Here we decide which strip to extract
				cmp.b	#1,d1
				bgt.s	ThirdThird
				beq.s	SecThird
				move.l	d5,d6
				move.l	d5,d1
				move.w	d4,-(a7)
				; Inner loops of 2D object drawing
.drawavertstrip
				move.b	1(a0,d1.w*2),d0
				and.b	#%00011111,d0
				beq.s	.dontplotthisoneitsblack
				move.b	(a4,d0.w*2),(a6)
.dontplotthisoneitsblack:
				adda.w	#SCREENWIDTH,a6
				add.l	d2,d6					; is d2 the vertical step, fraction|integer?
				addx.w	d2,d1
				dbra	d4,.drawavertstrip
				move.w	(a7)+,d4
blankstrip:
				dbra	d3,drawrightside
				bra.s	objbehind

SecThird:
				move.l	d5,d1
				move.l	d5,d6
				move.w	d4,-(a7)
.drawavertstrip
				move.w	(a0,d1.w*2),d0
				lsr.w	#5,d0
				and.w	#%11111,d0
				beq.s	.dontplotthisoneitsblack
				move.b	(a4,d0.w*2),(a6)
.dontplotthisoneitsblack:
				adda.w	#SCREENWIDTH,a6			; next line on screen
				add.l	d2,d6
				addx.w	d2,d1					; is d2 the vertical step, fraction|integer?
				dbra	d4,.drawavertstrip
				move.w	(a7)+,d4
				dbra	d3,drawrightside
				bra.s	objbehind

ThirdThird:
				move.l	d5,d1
				move.l	d5,d6
				move.w	d4,-(a7)
.drawavertstrip
				move.b	(a0,d1.w*2),d0
				lsr.b	#2,d0
				and.b	#%11111,d0
				beq.s	.dontplotthisoneitsblack
				move.b	(a4,d0.w*2),(a6)
.dontplotthisoneitsblack:
				adda.w	#SCREENWIDTH,a6
				add.l	d2,d6
				addx.w	d2,d1					; is d2 the vertical dy/dt step, fraction|integer?
				dbra	d4,.drawavertstrip
				move.w	(a7)+,d4
				dbra	d3,drawrightside

objbehind:
				movem.l	(a7)+,d0-d7/a0-a6
				rts

DRAWITADDED:
				move.l	BASEPAL,a4

drawrightsideADD:
				swap	d7
				move.l	midobj(pc),a5
				lea		(a5,d7.w*4),a5
				swap	d7
				add.l	a2,d7
				move.l	WAD_PTR(PC),a0

				move.l	toppt(pc),a6
				adda.w	a1,a6
				addq	#1,a1
				move.l	(a5),d1
				beq		blankstripADD

				and.l	#$ffffff,d1
				add.l	d1,a0

				move.b	(a5),d1
				cmp.b	#1,d1
				bgt.s	ThirdThirdADD
				beq.s	SecThirdADD
				move.l	d5,d6
				move.l	d5,d1
				move.w	d4,-(a7)
.drawavertstrip
				move.b	1(a0,d1.w*2),d0
				and.b	#%00011111,d0
				lsl.w	#8,d0
				move.b	(a6),d0
				move.b	(a4,d0.w),(a6)
				adda.w	#SCREENWIDTH,a6
				add.l	d2,d6
				addx.w	d2,d1
				dbra	d4,.drawavertstrip
				move.w	(a7)+,d4
blankstripADD:
				dbra	d3,drawrightsideADD
				bra		objbehind

SecThirdADD:
				move.l	d5,d1
				move.l	d5,d6
				move.w	d4,-(a7)
.drawavertstrip
				move.w	(a0,d1.w*2),d0
				lsr.w	#5,d0
				and.w	#%11111,d0
				lsl.w	#8,d0
				move.b	(a6),d0
				move.b	(a4,d0.w),(a6)
				adda.w	#SCREENWIDTH,a6
				add.l	d2,d6
				addx.w	d2,d1
				dbra	d4,.drawavertstrip
				move.w	(a7)+,d4
				dbra	d3,drawrightsideADD
				bra		objbehind

ThirdThirdADD:
				move.l	d5,d1
				move.l	d5,d6
				move.w	d4,-(a7)
.drawavertstrip
				move.b	(a0,d1.w*2),d0
				lsr.b	#2,d0
				and.b	#%11111,d0
				lsl.w	#8,d0
				move.b	(a6),d0
				move.b	(a4,d0.w),(a6)
.dontplotthisoneitsblack:
				adda.w	#SCREENWIDTH,a6
				add.l	d2,d6
				addx.w	d2,d1
				dbra	d4,.drawavertstrip
				move.w	(a7)+,d4
				dbra	d3,drawrightsideADD

				bra		objbehind

DRAWITLIGHTED:

; Make up lighting values

				movem.l	d0-d7/a0-a6,-(a7)

				move.l	#ANGLEBRIGHTS,a2
				move.l	#$80808080,(a2)
				move.l	#$80808080,4(a2)
				move.l	#$80808080,8(a2)
				move.l	#$80808080,12(a2)
				move.l	#$80808080,16(a2)
				move.l	#$80808080,20(a2)
				move.l	#$80808080,24(a2)
				move.l	#$80808080,28(a2)

				move.l	#$80808080,32(a2)
				move.l	#$80808080,36(a2)
				move.l	#$80808080,40(a2)
				move.l	#$80808080,44(a2)
				move.l	#$80808080,48(a2)
				move.l	#$80808080,52(a2)
				move.l	#$80808080,56(a2)
				move.l	#$80808080,60(a2)

				move.w	currzone(pc),d0
				bsr		CALCBRIGHTSINZONE

				move.l	#ANGLEBRIGHTS+32,a2

; Now do the brightnesses of surrounding
; zones:

; move.l FloorLines,a1
; move.w currzone,d0
; move.l ZoneAdds,a4
; move.l (a4,d0.w*4),a4
; add.l LEVELDATA,a4
; move.l a4,a5
;
; adda.w ToExitList(a4),a5
;
;.doallwalls
; move.w (a5)+,d0
; blt .nomorewalls
;
; asl.w #4,d0
; lea (a1,d0.w),a3
;
; move.w 8(a3),d0
; blt.s .solidwall ; a wall not an exit.
;
; movem.l a1/a4/a5,-(a7)
; bsr CALCBRIGHTSINZONE
; movem.l (a7)+,a1/a4/a5
; bra .doallwalls
;
;.solidwall:
; move.w 4(a3),d1
; move.w 6(a3),d2
;
; move.w oldx,newx
; move.w oldz,newz
; sub.w d2,newx
; add.w d1,newz
;
; movem.l d0-d7/a0-a6,-(a7)
; jsr HeadTowardsAng
; movem.l (a7)+,d0-d7/a0-a6
; move.w AngRet,d1
; neg.w d1
; and.w #8191,d1
; asr.w #8,d1
; asr.w #1,d1

; move.b #48,(a2,d1.w)
; move.b #48,16(a2,d1.w)
; bra .doallwalls
;
;.nomorewalls:

				move.l	#xzangs,a0
				move.l	#ANGLEBRIGHTS,a1
				move.w	#15,d7
				sub.l	a2,a2
				sub.l	a3,a3
				sub.l	a4,a4
				sub.l	a5,a5
				moveq	#00,d0
				moveq	#00,d1
averageangle:

				moveq	#0,d4
				move.b	16(a1),d4
				cmp.b	#$80,d4
				beq.s	.nobright

				neg.w	d4
				add.w	#48,d4
				cmp.b	d1,d4
				ble.s	.nobrightest
				move.b	d4,d1
.nobrightest:


				move.w	(a0),d5
				move.w	2(a0),d6
				muls	d4,d5
				muls	d4,d6
				add.l	d5,a2
				add.l	d6,a3

.nobright:

BOTTYL:

				moveq	#0,d4
				move.b	(a1),d4
				cmp.b	#$80,d4
				beq.s	.nobright
				neg.w	d4
				add.w	#48,d4
				cmp.b	d0,d4
				blt.s	.nobrightest
				move.b	d4,d0
.nobrightest:

				move.w	(a0),d5
				move.w	2(a0),d6
				muls	d4,d5
				muls	d4,d6
				add.l	d5,a4
				add.l	d6,a5

.nobright:
				addq	#4,a0
				addq	#1,a1

				dbra	d7,averageangle

				move.l	a2,d2
				move.l	a3,d3
				move.l	a4,d4
				move.l	a5,d5

				add.l	d2,d4
				add.l	d3,d5					; bright dir.

				bsr		FINDROUGHANG

foundang:

				move.w	#7,d2
				move.w	d1,d3
				cmp.w	d0,d1
				beq.s	INMIDDLE
				bgt.s	.okpicked
				move.w	d0,d3
.okpicked

				move.w	d0,d2
				add.w	d1,d2					; total brightness

				muls	#16,d1
				subq	#1,d1
				divs	d2,d1
				move.w	d1,d2

INMIDDLE:
; d2=y distance from middle of brightest pt.
; d3=brightness
				neg.w	d3
				add.w	#48,d3

				move.l	#willy,a0
				move.l	#guff,a1
				add.l	guffptr,a1
; add.l #16*7,guffptr
; cmp.l #16*7*15,guffptr
; ble.s .noreguff
; move.l #0,guffptr
;.noreguff:

				muls	#7*16,d2
				add.l	d2,a1

				move.w	p1_angpos,d0
				neg.w	d0
				add.w	#4096,d0
				and.w	#8191,d0
				asr.w	#8,d0
				asr.w	#1,d0

				sub.b	#3,d0
				add.b	d4,d0
				and.w	#15,d0
				move.w	#6,d1
.across:
				move.w	#6,d2
				move.w	d0,d5
.down
				move.b	(a1,d5),d4
				add.b	d3,d4
				ext.w	d4
				move.w	d4,(a0)+
				addq	#1,d5
				and.w	#15,d5
				dbra	d2,.down
				add.w	#16,a1
				dbra	d1,.across

; jsr CALCBRIGHTRINGS

; Need to scan around zone points putting in
; brightnesses.


; move.w PLR1_xoff,newx
; move.w PLR1_zoff,newz
; move.w thisxpos,oldx
; move.w thiszpos,oldz
; movem.l d0-d7/a0-a6,-(a7)
; jsr HeadTowardsAng
; movem.l (a7)+,d0-d7/a0-a6


; move.w #0,d0
; move.w AngRet,d0
; move.w p1_angpos,d0
; neg.w d0
; add.w #4096,d0
; and.w #8191,d0
; asr.w #8,d0
; asr.w #1,d0
;
; sub.b #6,d0
; and.b #15,d0
; move.l #ANGLEBRIGHTS,a1
;
; move.l #willy,a0
; moveq #6,d1
;.across:
; moveq #0,d3
; moveq #0,d4
; move.b (a1,d0.w),d4
; bge.s .okp1
; moveq #0,d4
;.okp1
;
; move.b 16(a1,d0.w),d3
; bge.s .okp2
; moveq #0,d3
;.okp2
; sub.w d3,d4
; swap d3
; swap d4
; divs.l #7,d4
; moveq #6,d2
; moveq #0,d5
;.down:
; swap d3
; move.w d3,(a0,d5.w*2)
; swap d3
; addq #7,d5
; add.l d4,d3
; dbra d2,.down
; addq #2,d0
; and.w #15,d0
; addq #2,a0
; dbra d1,.across


				move.w	BRIGHTTOADD,d0
				move.l	#willy,a0
				move.l	#willybright,a1
				move.w	#48,d1
ADDITIN:

				move.w	d0,d2
				add.w	(a1)+,d2
				ble.s	.nopos

				moveq	#0,d2

.nopos:

				add.w	d2,(a0)+

				dbra	d1,ADDITIN



				tst.b	FLIPIT
				beq.s	LEFTTORIGHT

				move.l	#Brights2,a0
				bra		DONERIGHTTOLEFT

LEFTTORIGHT:

				move.l	#Brights,a0
DONERIGHTTOLEFT:
				move.l	#willy,a2
				move.l	BASEPAL,a1
				move.b	WHICHLIGHTPAL,d0
				asl.w	#8,d0
				add.w	d0,a1
				move.l	#PALS,a3
				move.w	#28,d0
makepals:

				move.w	(a0)+,d1
				move.w	(a2,d1.w*2),d1
				bge.s	.okpos
				moveq	#0,d1
.okpos:
				cmp.w	#31,d1
				blt.s	.okneg
				move.w	#31,d1
.okneg:

				move.l	(a1,d1.w*8),(a3)+
				move.b	#0,-4(a3)
				move.l	4(a1,d1.w*8),(a3)+

				dbra	d0,makepals

				movem.l	(a7)+,d0-d7/a0-a6

				move.l	#PALS,a4
				clr.w	d0

drawlightlop
				swap	d7
				move.l	midobj(pc),a5
				lea		(a5,d7.w*4),a5
				swap	d7
				add.l	a2,d7
				move.l	WAD_PTR(PC),a0			; is this not always right? Seems to be connected to
												; dead body of the blue priests, first seen in level C

				move.l	toppt(pc),a6
				adda.w	a1,a6
				addq	#1,a1
				move.l	(a5),d1
				beq		.blankstrip

				add.l	d1,a0

				move.l	d5,d6
				move.l	d5,d1
				move.w	d4,-(a7)
.drawavertstrip
				move.b	(a0,d1.w),d0				; a0 can be broken here
				beq.s	.dontplotthisoneitsblack
				move.b	(a4,d0.w),(a6)				; FIXME: causing enforcer hits in Level C, illegal reads
.dontplotthisoneitsblack:
				adda.w	#SCREENWIDTH,a6
				add.l	d2,d6
				addx.w	d2,d1
				dbra	d4,.drawavertstrip
				move.w	(a7)+,d4
.blankstrip:
				dbra	d3,drawlightlop
				bra		objbehind

*********************************************
FINDROUGHANG:
				neg.l	d5
				moveq	#0,d7
				tst.l	d4
				bge.s	.no8
				add.w	#8,d7
				neg.l	d4
.no8
				tst.l	d5
				bge.s	.no4
				neg.l	d5
				add.w	#4,d7
.no4
				cmp.l	d5,d4
				bge.s	.no2
				addq	#2,d7
				exg		d4,d5
.no2:
				asr.l	#1,d4
				cmp.l	d5,d4
				bge.s	.no1
				addq	#1,d7
.no1

				move.w	maptoang(pc,d7.w*2),d4	; retun angle
				rts

maptoang:
				dc.w	3,2,0,1,4,5,7,6
				dc.w	12,13,15,14,11,10,8,9

guffptr:		dc.l	0

*********************************************
CALCBRIGHTRINGS:
				move.l	#ANGLEBRIGHTS,a2
				move.l	#$80808080,(a2)
				move.l	#$80808080,4(a2)
				move.l	#$80808080,8(a2)
				move.l	#$80808080,12(a2)
				move.l	#$80808080,16(a2)
				move.l	#$80808080,20(a2)
				move.l	#$80808080,24(a2)
				move.l	#$80808080,28(a2)

				move.l	#$80808080,32(a2)
				move.l	#$80808080,36(a2)
				move.l	#$80808080,40(a2)
				move.l	#$80808080,44(a2)
				move.l	#$80808080,48(a2)
				move.l	#$80808080,52(a2)
				move.l	#$80808080,56(a2)
				move.l	#$80808080,60(a2)

				move.w	currzone(pc),d0
				bsr		CALCBRIGHTSINZONE

				move.l	#ANGLEBRIGHTS+32,a2

; Now do the brightnesses of surrounding
; zones:

				move.l	FloorLines,a1
				move.w	currzone,d0
				move.l	ZoneAdds,a4
				move.l	(a4,d0.w*4),a4
				add.l	LEVELDATA,a4
				move.l	a4,a5

				adda.w	ToExitList(a4),a5

.doallwalls
				move.w	(a5)+,d0
				blt		.nomorewalls

				asl.w	#4,d0
				lea		(a1,d0.w),a3

				move.w	8(a3),d0
				blt.s	.solidwall				; a wall not an exit.

				movem.l	a1/a4/a5,-(a7)
				bsr		CALCBRIGHTSINZONE
				movem.l	(a7)+,a1/a4/a5
				bra		.doallwalls

.solidwall:
				move.w	4(a3),d1
				move.w	6(a3),d2

				move.w	oldx,newx
				move.w	oldz,newz
				sub.w	d2,newx
				add.w	d1,newz

				movem.l	d0-d7/a0-a6,-(a7)
				jsr		HeadTowardsAng
				movem.l	(a7)+,d0-d7/a0-a6
				move.w	AngRet,d1
				neg.w	d1
				and.w	#8191,d1
				asr.w	#8,d1
				asr.w	#1,d1

				move.b	#48,(a2,d1.w)
				move.b	#48,16(a2,d1.w)
				bra		.doallwalls

.nomorewalls:


; move.b #0,(a2)
; move.b #20,8(a2)
; move.b #0,16(a2)
; move.b #20,24(a2)

				move.l	#ANGLEBRIGHTS,a0
				bsr		TWEENBRIGHTS
				move.l	#ANGLEBRIGHTS+16,a0
				bsr		TWEENBRIGHTS
				move.l	#ANGLEBRIGHTS+32,a0
				bsr		TWEENBRIGHTS
				move.l	#ANGLEBRIGHTS+48,a0
				bsr		TWEENBRIGHTS

				move.l	#ANGLEBRIGHTS,a0
				move.b	#15,d0
ADDBRIGHTS

				moveq	#0,d3
				moveq	#0,d4
				move.b	32(a0),d3
				move.b	48(a0),d4
				neg.w	d3
				add.w	#48,d3
				neg.w	d4
				add.w	#48,d4
				asr.w	#1,d4
				asr.w	#1,d3

				move.b	16(a0),d5
				sub.b	d5,d4
				ble.s	.ok2
				moveq	#0,d4
.ok2:
				move.b	(a0),d5
				sub.b	d5,d3
				ble.s	.ok1
				moveq	#0,d3
.ok1:
				neg.b	d3
				neg.b	d4

				move.b	d4,16(a0)
				move.b	d3,(a0)+

				dbra	d0,ADDBRIGHTS

				rts

**********************************************

TWEENBRIGHTS:

				moveq	#0,d0
.backinto:
				cmp.b	#-128,(a0,d0.w)
				bne.s	.okbr
				addq	#1,d0
				bra.s	.backinto

.okbr:

				move.b	d0,d7					;starting pos
				move.b	d0,d1					;previous pos

; tween to next value
.findnext
				addq	#1,d0
				and.w	#15,d0
				cmp.b	#-128,(a0,d0.w)
				beq.s	.findnext

				moveq	#0,d2
				moveq	#0,d3
				move.b	(a0,d1.w),d2
				move.b	(a0,d0.w),d3
				sub.w	d2,d3

				move.w	d0,d4
				sub.w	d1,d4
				bgt.s	.okpos
				add.w	#16,d4
.okpos:

				swap	d2
				swap	d3
				ext.l	d4
				divs.l	d4,d3

				subq	#1,d4					; number of tweens

.putintween
				swap	d2
				move.b	d2,(a0,d1.w)
				swap	d2
				add.l	d3,d2
				addq	#1,d1
				and.w	#15,d1
				dbra	d4,.putintween

				cmp.b	d0,d7
				beq.s	.doneall

				move.w	d0,d1
				bra		.findnext

.doneall

				rts

IMINTHETOPDAD:	dc.w	0

*************************************
CALCBRIGHTSINZONE:
				move.w	d0,d1
				muls	#20,d1
				move.l	ZoneBorderPts,a1
				add.l	d1,a1
				move.l	#CurrentPointBrights,a0
				lea		(a0,d1.l*4),a0

				tst.b	IMINTHETOPDAD
				beq.s	.notintopdad
				adda.w	#4,a0
.notintopdad

; A0 points at the brightnesses of the zone points.
; a1 points at the border points of the zone.
; list is terminated with -1.

				move.l	Points,a3

				move.w	thisxpos,oldx
				move.w	thiszpos,oldz
				move.w	#10,speed
				move.w	#0,Range

DOPTBR
				move.w	(a1)+,d0				;pt number
				blt		DONEPTBR

				move.w	(a3,d0.w*4),newx
				move.w	2(a3,d0.w*4),newz

				movem.l	d0-d7/a0-a6,-(a7)
				jsr		HeadTowardsAng
				movem.l	(a7)+,d0-d7/a0-a6

				move.w	AngRet,d1
				neg.w	d1
				and.w	#8191,d1
				asr.w	#8,d1
				asr.w	#1,d1

				move.w	(a0),d0
				bge.s	.okpos
				add.w	#332,d0
				asr.w	#2,d0
				neg.w	d0
				add.w	#332,d0

.okpos
				sub.w	#300,d0
				bge.s	.okpos3
				move.w	#0,d0
.okpos3:
				move.b	d0,d2
				asr.b	#1,d2
				add.b	d2,d0
				move.b	d0,(a2,d1.w)
				move.w	2(a0),d0
				bge.s	.okpos2
				add.w	#332,d0
				asr.w	#2,d0
				neg.w	d0
				add.w	#332,d0
.okpos2
				sub.w	#300,d0
				bge.s	.okpos4
				move.w	#0,d0
.okpos4:

				move.b	d0,d2
				asr.b	#1,d2
				add.b	d2,d0
				move.b	d0,16(a2,d1.w)
				adda.w	#8,a0

				bra		DOPTBR
DONEPTBR
				rts

thisxpos:		dc.w	0
thiszpos:		dc.w	0
FACINGANG:		dc.w	0

ANGLEBRIGHTS:	ds.l	8*2

Brights:
				dc.w	3
				dc.w	8,9,10,11,12
				dc.w	15,16,17,18,19
				dc.w	21,22,23,24,25,26,27
				dc.w	29,30,31,32,33
				dc.w	36,37,38,39,40
				dc.w	45

Brights2:
				dc.w	3
				dc.w	12,11,10,9,8
				dc.w	19,18,17,16,15
				dc.w	27,26,25,24,23,22,21
				dc.w	33,32,31,30,29
				dc.w	40,39,38,37,36
				dc.w	45


PALS:
				ds.l	2*49

willy:
				dc.w	0,0,0,0,0,0,0
				dc.w	5,5,5,5,5,5,5
				dc.w	10,10,10,10,10,10,10
				dc.w	15,15,15,15,15,15,15
				dc.w	20,20,20,20,20,20,20
				dc.w	25,25,25,25,25,25,25
				dc.w	30,30,30,30,30,30,30

willybright:
				dc.w	30,30,30,30,30,30,30
				dc.w	30,20,20,20,20,20,30
				dc.w	30,20,6,3,6,20,30
				dc.w	30,20,6,0,6,20,30
				dc.w	30,20,6,6,6,20,30
				dc.w	30,20,20,20,20,20,30
				dc.w	30,30,30,30,30,30,30

xzangs:
				dc.w	0,23,10,20,16,16,20,10
				dc.w	23,0,20,-10,16,-16,10,-20
				dc.w	0,-23,-10,-20,-16,-16,-20,-10
				dc.w	-23,0,-20,10,-16,16,-10,20

guff:
				incbin	"includes/guff"

midx:			dc.w	0
objpixwidth:	dc.w	0
tmptst:			dc.l	0
toppt:			dc.l	0
doneit:			dc.w	0
replaceend:		dc.w	0
saveend:		dc.w	0
midobj:			dc.l	0
obadd:			dc.l	0
DOWN_STRIP:		dc.w	0
WAD_PTR:		dc.l	0
PTR_PTR:		dc.l	0

PolyAngPtr:		dc.l	0
PointAngPtr:	dc.l	0

				ds.w	100

*********************************
***************************************
*********************************
tstddd:			dc.l	0

polybehind:
				rts

SORTIT:			dc.w	0

objbright:
				dc.w	0
ObjAng:			dc.w	0

POLYMIDDLEY:	dc.w	0
OBJONOFF:		dc.l	0



;  Polygonal Object rendering
; a0 : object ; struct object {short id,x,y,z}
; a1 : view?
; struct ObjectPoints {short x,y,z}
PolygonObj:

************************

; move.w 4(a0),d0	; ypos
; move.w 2(a0),d1
; add.w #2,d1
; add.w d1,d0
; cmp.w #-48,d0
; blt nobounce
; neg.w d1
; add.w d1,d0
;nobounce:
; move.w d1,2(a0)
; move.w d0,4(a0)

; add.w #80*2,boxang
; and.w #8191,boxang

************************

				move.w	AI_EntT_CurrentAngle_w(a0),ObjAng

				move.w	MIDDLEY,POLYMIDDLEY

				move.w	(a0)+,d0				; object Id?
				move.l	ObjectPoints,a4

				move.w	(a4,d0.w*8),thisxpos
				move.w	4(a4,d0.w*8),thiszpos

				move.w	2(a1,d0.w*8),d1			; zpos of mid; is this the view position ?
				blt		polybehind
				bgt.s	.okinfront

				move.l	a0,a3
				sub.l	PLR1_Obj,a3
				cmp.l	#130,a3
				bne		polybehind

				tst.b	whichdoing
				bne		polybehind

				move.w	#1,d1
				; FIMXE: the original values here were 80 and 120
				; which sets weapons slighly lower in the view
				move.w	#SMALL_HEIGHT/2,POLYMIDDLEY
				tst.b	FULLSCR
				beq.s	.okinfront
				move.w	#FS_HEIGHT/2,POLYMIDDLEY
.okinfront:

				movem.l	d0-d7/a0-a6,-(a7)

				jsr		CALCBRIGHTRINGS

				move.l	#ANGLEBRIGHTS,a0
				move.l	#PointAndPolyBrights,a1
				move.w	#15,d7
				move.w	#8,d6
MYacross:
				moveq	#0,d3
				moveq	#0,d4

				move.b	16(a0,d6.w),d4
				bge.s	.okp2
				moveq	#0,d4
.okp2

				move.b	(a0,d6.w),d3
				bge.s	.okp1
				moveq	#0,d3
.okp1

				sub.w	d3,d4
				swap	d3
				swap	d4
				asr.l	#3,d4
				moveq	#7,d2
				moveq	#3*16,d5
.down:
				swap	d3
				move.b	d3,(a1,d5.w)
				swap	d3
				add.w	#16,d5
				add.l	d4,d3
				dbra	d2,.down

TOPPART:

				moveq	#0,d3
				moveq	#0,d4

				bchg	#3,d6

				move.b	(a0,d6.w),d4
				bge.s	.okp2
				moveq	#0,d4
.okp2

				bchg	#3,d6

				move.b	(a0,d6.w),d3
				bge.s	.okp1
				moveq	#0,d3
.okp1

				sub.w	d3,d4
				swap	d3
				swap	d4
				asr.l	#4,d4 ; d4/8, then midpoint d4/2 => d4/16
				moveq	#3,d2
				moveq	#3*16,d5
.down:
				swap	d3
				move.b	d3,(a1,d5.w)
				swap	d3
				sub.w	#16,d5
				add.l	d4,d3
				dbra	d2,.down

BOTPART:

				moveq	#0,d3
				moveq	#0,d4

				bchg	#3,d6

				move.b	16(a0,d6.w),d4
				bge.s	.okp2
				moveq	#0,d4
.okp2

				bchg	#3,d6

				move.b	16(a0,d6.w),d3
				bge.s	.okp1
				moveq	#0,d3
.okp1

				sub.w	d3,d4
				swap	d3
				swap	d4
				asr.l	#4,d4 ; d4/8, then midpoint d4/2 => d4/16
				moveq	#3,d2
				move.w	#11*16,d5
.down:
				swap	d3
				move.b	d3,(a1,d5.w)
				swap	d3
				add.w	#16,d5
				add.l	d4,d3
				dbra	d2,.down


				subq	#1,d6
				and.w	#$f,d6
				addq	#1,a1
				dbra	d7,MYacross

				movem.l	(a7)+,d0-d7/a0-a6


				move.w	(a0),d2
				move.w	d1,d3
				asr.w	#7,d3
				add.w	d3,d2
				move.w	d2,objbright

				move.w	topclip,d2
				move.w	botclip,d3

				move.w	d2,objclipt
				move.w	d3,objclipb

; dont use d1 here.

				move.w	6(a0),d5
				move.l	#POLYOBJECTS,a3
				move.l	(a3,d5.w*4),a3

				move.w	(a3)+,SORTIT

				move.l	a3,START_OF_OBJ

*******************************************************************
***************************************************************
*****************************************************************

				move.w	(a3)+,num_points
				move.w	(a3)+,d6				; num_frames


				move.l	a3,POINTER_TO_POINTERS
				lea		(a3,d6.w*4),a3

				move.l	a3,LinesPtr

				moveq	#0,d5
				move.w	8(a0),d5

************************************************
* Just for charles (animate automatically)
; add.w #1,d5
; cmp.w d6,d5
; blt.s okless
; moveq #0,d5
;okless:
; move.w d5,8(a0)
************************************************

				moveq	#0,d2
				move.l	POINTER_TO_POINTERS,a4
				move.w	(a4,d5.w*4),d2
				add.l	START_OF_OBJ,d2
				move.l	d2,PtsPtr
				move.w	2(a4,d5.w*4),d5
				add.l	START_OF_OBJ,d5
				move.l	d5,PolyAngPtr
				move.l	d2,a3
				move.w	num_points,d5

				move.l	(a3)+,OBJONOFF

				move.l	a3,PointAngPtr
				move.w	d5,d2
				moveq	#0,d3
				lsr.w	#1,d2
				addx.w	d3,d2
				add.w	d2,d2
				add.w	d2,a3
				subq	#1,d5

				move.l	#boxrot,a4				; temp storage for rotated points?

				move.w	ObjAng,d2
				sub.w	#2048,d2				; 90deg
				sub.w	angpos,d2				; view angle
				and.w	#8191,d2				; wrap 360deg
				move.l	#SineTable,a2
				lea		(a2,d2.w),a5			; sine of object rotation wrt view
				move.l	#boxbrights,a6

				move.w	(a5),d6					; sine of object rottaion
				move.w	2048(a5),d7				; cosine of object rotation. WHY DOES IT NOT NEED OOB/WRAP CHECK?
										; bigsine is 16kb, so 8192 words
										; this may mean the table is covering 4pi/720deg
rotobj:
				move.w	(a3),d2					; xpt
				move.w	2(a3),d3				; ypt
				move.w	4(a3),d4				; zpt

; add.w d2,d2
; add.w d3,d3
; add.w d4,d4

; first rotate around z axis.

; move.w d2,d6
; move.w d3,d7
; muls 2048(a2),d3
; muls (a2),d2
; sub.l d3,d2	; newx
; muls (a2),d7
; muls 2048(a2),d6
; add.l d7,d6	; newy
; add.l d6,d6
; swap d6
; add.l d2,d2
; swap d2
; move.w d6,d3	; newy

				muls	d7,d4					; z * cos
				muls	d6,d2					; x * (sin << 16)
				sub.l	d4,d2
				asr.l	#8,d2
				asr.l	#1,d2					; ((z * cos - x * sin) << 16) >> 9 = (z * cos - x * sin) * 128
				move.l	d2,(a4)+				; store x' in boxpts
				ext.l	d3
				asl.l	#6,d3					; y * 64
				move.l	d3,(a4)+
				move.w	(a3),d2					; PtsPtr -> xpt
				move.w	4(a3),d4				; PtsPtr -> zpt
				muls	d6,d4					; z * sin
				muls	d7,d2					; x * cos
				add.l	d2,d4					; (z * sin  + x * cos) << 16
; add.l d4,d4
				swap	d4						; (z * sin  + x * cos)
				move.w	d4,(a4)+				; store z' in boxpts

				addq	#6,a3					; next point
				dbra	d5,rotobj


				move.l	4(a1,d0.w*8),d0			; xpos of mid; is this the object position?

				move.w	num_points,d7
				move.l	#boxrot,a2
				move.l	#boxonscr,a3
				move.l	#boxbrights,a6
				move.w	2(a0),d2				; object y pos?
				subq	#1,d7

				asl.l	#1,d0					;
; Projection for polygonal objects to screen here?
				tst.b	FULLSCR
				beq.s	smallconv

				move.w	d1,d3
				asl.w	#1,d1
				add.w	d3,d1					; d1 * 3  because 288 is ~1.5times larger than 196?
									; if I change this, 3d objects start "swimming" with regard to the world

				ext.l	d2
				asl.l	#7,d2					; (view_ypos *128 - yoff) *2
				sub.l	yoff,d2
				asl.l	#1,d2
.convtoscr
				move.l	(a2),d3					;
				add.l	d0,d3					; x'' = xpos_of_view + x
				move.l	d3,(a2)+				; '
				move.l	(a2),d4					;
				add.l	d2,d4					; y'' = y' + ypos_obj
				move.l	d4,(a2)+				;
				move.w	(a2),d5					; z'
				add.w	d1,d5					; z'' = z' + zpos_of_view
				ble		.ptbehind
				move.w	d5,(a2)+

				; FIXME: can we factor the 3/2 scaling into Z somewhere else?
				add.w	d5,d5					; z'' * 2  to achieve  3/2 scaling for fullscreen

				move.l	d4,d6
				add.l	d6,d6
				add.l	d6,d4					; y'' * 3
				divs	d5,d4					; ys = (x*3)/(z*2)

				move.l	d3,d6					;
				add.l	d6,d6
				add.l	d6,d3		; x'' * 3
				divs	d5,d3		; xs = (x*3)/(z*2)
				add.w	MIDDLEX,d3	; mid_x of screen
				add.w	POLYMIDDLEY,d4	; mid_y of screen
				move.w	d3,(a3)+	; store xs,ys in boxonscr
				move.w	d4,(a3)+

				dbra	d7,.convtoscr
				bra		DONECONV

.ptbehind:
				move.w	d5,(a2)+
				move.w	#32767,(a3)+
				move.w	#32767,(a3)+
				dbra	d7,.convtoscr
				bra		DONECONV

smallconv
				asl.w	#1,d1					; d1 * 2
				ext.l	d2
				asl.l	#7,d2
				sub.l	yoff,d2
				asl.l	#1,d2					; (d2*128 - yoff) *2
.convtoscr
				move.l	(a2),d3
				add.l	d0,d3
				move.l	d3,(a2)+
				move.l	(a2),d4
				add.l	d2,d4
				move.l	d4,(a2)+
				move.w	(a2),d5
				add.w	d1,d5
				ble		.ptbehind2
				move.w	d5,(a2)+
				divs	d5,d3
				divs	d5,d4

				add.w	MIDDLEX,d3

				add.w	POLYMIDDLEY,d4
				move.w	d3,(a3)+
				move.w	d4,(a3)+

				dbra	d7,.convtoscr

				bra		DONECONV

.ptbehind2:
				move.w	d5,(a2)+
				move.w	#32767,(a3)+
				move.w	#32767,(a3)+
				dbra	d7,.convtoscr

DONECONV

**************************
				move.w	num_points,d7

				move.l	#boxbrights,a6
				subq	#1,d7
				move.l	PointAngPtr,a0
				move.l	#PointAndPolyBrights,a2
				move.w	ObjAng,d2
				asr.w	#8,d2
				asr.w	#1,d2
				st		d5

calcpointangbrights:

				moveq	#0,d0
				move.b	(a0)+,d0
				move.b	d0,d3
				add.w	d2,d3
				and.w	#$f,d3
				and.w	#$f0,d0
				add.w	d3,d0

				moveq	#0,d1
				move.b	(a2,d0.w),d1
				bge.s	.okpos
				moveq	#0,d1
.okpos:

				cmp.w	#31,d1
				ble.s	.oksmall
				move.w	#31,d1
.oksmall:

				move.w	d1,(a6)+

				dbra	d7,calcpointangbrights

*************************



				move.l	LinesPtr,a1

; Now need to sort parts of object
; into order.

				move.l	#PartBuffer,a0
				move.l	a0,a2
				move.w	#63,d0
clrpartbuff:

				move.l	#$80000001,(a2)
				addq	#4,a2

				dbra	d0,clrpartbuff

				move.l	#boxrot,a2

				move.l	OBJONOFF,d5

				tst.w	SORTIT
				bne.s	PutinParts


putinunsorted:

				move.w	(a1)+,d7


				blt		doneallparts

				lsr.l	#1,d5
				bcs.s	.yeson
				addq	#2,a1
				bra		putinunsorted
.yeson:


				move.w	(a1)+,d6
				move.l	#0,(a0)+
				move.w	d7,(a0)
				addq	#4,a0

				bra		putinunsorted


PutinParts
				move.w	(a1)+,d7
				blt		doneallparts

				lsr.l	#1,d5
				bcs.s	.yeson
				addq	#2,a1
				bra		PutinParts
.yeson:

				move.w	(a1)+,d6
				move.l	(a2,d6.w),d0
				asr.l	#7,d0
				muls	d0,d0
				move.l	4(a2,d6.w),d2
				asr.l	#7,d2
				muls	d2,d2
				add.l	d2,d0
				move.w	8(a2,d6.w),d2
				muls	d2,d2
				add.l	d2,d0
				move.l	#PartBuffer-8,a0

stillfront
				addq	#8,a0
				cmp.l	(a0),d0
				blt		stillfront
				move.l	#endparttab-8,a5
domoreshift:
				move.l	-8(a5),(a5)
				move.l	-4(a5),4(a5)
				subq	#8,a5
				cmp.l	a0,a5
				bgt.s	domoreshift

				move.l	d0,(a0)
				move.w	d7,4(a0)

				bra		PutinParts

doneallparts:

				move.l	#PartBuffer,a0

Partloop:
				move.l	(a0)+,d7
				blt		nomoreparts

				moveq	#0,d0
				move.w	(a0),d0
				addq	#4,a0
				add.l	START_OF_OBJ,d0
				move.l	d0,a1
				move.w	#0,firstpt

polyloo:

				tst.w	(a1)
				blt.s	nomorepolys
				movem.l	a0/a1/d7,-(a7)
				bsr		doapoly
				movem.l	(a7)+,a0/a1/d7

				move.w	(a1),d0
				lea		18(a1,d0.w*4),a1

				bra.s	polyloo
nomorepolys

				bra		Partloop

nomoreparts:
				rts

firstpt:		dc.w	0

PartBuffer:
				ds.w	4*32
endparttab:

polybright:		dc.l	0
PolyAng:		dc.w	0

doapoly:

				move.w	#960,Left
				move.w	#-10,Right

				move.w	(a1)+,d7				; lines to draw
				move.w	(a1)+,preholes
				move.w	12(a1,d7.w*4),pregour
				move.l	#boxonscr,a3

				movem.l	d0-d7/a0-a6,-(a7)
* Check for any of these points behind...

checkbeh:
				move.w	(a1),d0

				cmp.w	#32767,(a3,d0.w*4)
				bne.s	.notbeh
				cmp.w	#32767,2(a3,d0.w*4)
				bne.s	.notbeh

				movem.l	(a7)+,d0-d7/a0-a6
				bra		polybehind

.notbeh:

				addq	#4,a1
				dbra	d7,checkbeh


				movem.l	(a7)+,d0-d7/a0-a6


				move.w	(a1),d0
				move.w	4(a1),d1
				move.w	8(a1),d2
				move.w	2(a3,d0.w*4),d3
				move.w	2(a3,d1.w*4),d4
				move.w	2(a3,d2.w*4),d5
				move.w	(a3,d0.w*4),d0
				move.w	(a3,d1.w*4),d1
				move.w	(a3,d2.w*4),d2

				sub.w	d1,d0					;x1
				sub.w	d1,d2					;x2
				sub.w	d4,d3					;y1
				sub.w	d4,d5					;y2

				muls	d3,d2
				muls	d5,d0
				sub.l	d0,d2
				ble		polybehind

				move.l	#boxrot,a3
				move.w	(a1),d0
				move.w	d0,d1
				asl.w	#2,d0
				add.w	d1,d0
				move.w	4(a1),d1
				move.l	d1,d2
				asl.w	#2,d1
				add.w	d2,d1
				move.w	8(a1),d2
				move.w	d2,d3
				asl.w	#2,d2
				add.w	d3,d2
				move.l	4(a3,d0.w*2),d3
				move.l	4(a3,d1.w*2),d4
				move.l	4(a3,d2.w*2),d5
				move.l	(a3,d0.w*2),d0
				move.l	(a3,d1.w*2),d1
				move.l	(a3,d2.w*2),d2

				sub.l	d1,d0					;x1
				sub.l	d1,d2					;x2
				sub.l	d4,d3					;y1
				sub.l	d4,d5					;y2

				asr.l	#7,d0
				asr.l	#7,d2
				asr.l	#7,d3
				asr.l	#7,d5

				muls	d3,d2
				muls	d5,d0
				sub.l	d0,d2

				move.l	d2,polybright
				move.l	#boxonscr,a3

				clr.b	drawit

				tst.b	Gouraud(pc)
				bne.s	usegour
				bsr		putinlines
				bra.s	dontusegour
usegour:
				bsr		putingourlines
dontusegour:

				move.w	#SCREENWIDTH,linedir
				move.l	FASTBUFFER,a6

				tst.b	drawit(pc)
				beq		polybehind

				move.l	#PolyTopTab,a4
				move.w	Left(pc),d1
				move.w	Right(pc),d7

				move.w	leftclipb,d3
				move.w	rightclipb,d4
				cmp.w	d3,d7
				ble		polybehind
				cmp.w	d4,d1
				bge		polybehind
				cmp.w	d3,d1
				bge		.notop
				move.w	d3,d1
.notop
				cmp.w	d4,d7
				ble		.nobot
				move.w	d4,d7
.nobot

				add.w	d1,d1
				lea		(a4,d1.w*8),a4
				asr.w	#1,d1
				sub.w	d1,d7
				ble		polybehind
				move.w	d1,a2
				moveq	#0,d0

				move.l	TextureMaps,a0
				move.w	(a1)+,d0
				bge.s	.notsec
				and.w	#$7fff,d0
				add.l	#65536,a0

.notsec
				add.w	d0,a0
				moveq	#0,d0
				moveq	#0,d1
				move.b	(a1)+,d1

				asl.w	#5,d1
				ext.l	d1
				divs	#100,d1
				neg.w	d1
				add.w	#31,d1


				tst.b	Holes
				bne		gotholesin
				tst.b	Gouraud(pc)
				bne		gotlurvelyshading

				move.w	ObjAng,d4
				asr.w	#8,d4
				asr.w	#1,d4

				moveq	#0,d2
				moveq	#0,d3
				move.b	(a1)+,d2
				move.l	PolyAngPtr,a1
				move.b	(a1,d2.w),d2

				move.b	d2,d3
				add.w	d4,d3
				and.w	#$f,d3
				and.w	#$f0,d2
				add.b	d3,d2

				move.l	#PointAndPolyBrights,a1
				moveq	#0,d5
				move.b	(a1,d2.w),d5

				add.w	d5,d1


				move.l	#objscalecols,a1
; move.w objbright(pc),d0
; add.w d0,d1
				tst.w	d1
				bge.s	toobright
				move.w	#0,d1
toobright:
				cmp.w	#31,d1
				blt.s	.toodark
				moveq	#31,d1
.toodark:

				asl.w	#8,d1
; move.w (a1,d1.w*2),d1
; asl.w #3,d1
				move.l	TexturePal,a1
				add.l	#256*32,a1
				lea		(a1,d1.w),a1
				tst.b	pregour
				bne		predoglare

dopoly:

				move.w	#0,offtopby
				move.l	a6,a3
				adda.w	a2,a3
				addq	#1,a2
				move.w	(a4),d1
				cmp.w	objclipb,d1
				bge		nodl
				move.w	PolyBotTab-PolyTopTab(a4),d2
				cmp.w	objclipt,d2
				ble		nodl
				cmp.w	objclipt,d1
				bge.s	nocl
				move.w	objclipt,d3
				sub.w	d1,d3
				move.w	d3,offtopby
				move.w	objclipt,d1
nocl:
				move.w	d2,d0
				cmp.w	objclipb,d2
				ble.s	nocr
				move.w	objclipb,d2
nocr:

; d1=top end
; d2=bot end

				move.l	2+PolyBotTab-PolyTopTab(a4),d3
				move.l	6+PolyBotTab-PolyTopTab(a4),d4

				move.l	2(a4),d5
				move.l	6(a4),d6

				sub.l	d5,d3
				sub.l	d6,d4

; asl.w #8,d3
; asl.w #8,d4
; ext.l d3
; ext.l d4

; and.b #63,d5
; and.b #63,d6
; lsl.w #8,d6
; move.b d5,d6	; starting pos
; moveq.l #0,d5
; move.w d6,d5


				sub.w	d1,d2
				ble		nodl

				move.w	#0,tstdca
				sub.w	d1,d0
				tst.w	offtopby
				beq.s	.notofftop
				move.l	d3,-(a7)
				move.l	d4,-(a7)
				add.w	offtopby,d0
				ext.l	d0
				muls.l	offtopby-2,d3
				muls.l	offtopby-2,d4
				divs.l	d0,d3
				divs.l	d0,d4

				add.l	d3,d5
				add.l	d4,d6

				move.l	(a7)+,d4
				move.l	(a7)+,d3
.notofftop:
				ext.l	d0

				divs.l	d0,d3
				divs.l	d0,d4

				add.l	ontoscr(pc,d1.w*4),a3

				move.l	#$3fffff,d1

				move.l	d3,a5
				moveq	#0,d3
				subq	#1,d2
drawpol:
				and.l	d1,d5
				and.l	d1,d6

				move.l	d6,d0
				asr.l	#8,d0
				swap	d5
				move.b	d5,d0

				move.b	(a0,d0.w*4),d3

				swap	d5
				add.l	a5,d5
				add.l	d4,d6

				move.b	(a1,d3.w),(a3)
				adda.w	#SCREENWIDTH,a3
				dbra	d2,drawpol

; add.w a5,d3
; addx.l d6,d5
; dbcs d2,drawpol2
; dbcc d2,drawpol
; bra.s pastit
;drawpol2:
; and.w d1,d5
; move.b (a0,d5.w*4),d0
; move.w (a1,d0.w*2),(a3)
; adda.w #SCREENWIDTH,a3
; add.w a5,d3
; addx.l d4,d5
; dbcs d2,drawpol2
; dbcc d2,drawpol

pastit:

nodl:
				adda.w	#16,a4
				dbra	d7,dopoly

				rts

ontoscr:
val				SET		0
				REPT	256
				dc.l	val
val				SET		val+SCREENWIDTH
				ENDR

predoglare:
				move.l	TexturePal,a1
				sub.w	#512,a1

DOGLAREPOLY:

				move.w	#0,offtopby
				move.l	a6,a3
				adda.w	a2,a3
				addq	#1,a2
				move.w	(a4),d1
				cmp.w	objclipb,d1
				bge		nodlGL
				move.w	PolyBotTab-PolyTopTab(a4),d2
				cmp.w	objclipt,d2
				ble		nodlGL
				cmp.w	objclipt,d1
				bge.s	noclGL
				move.w	objclipt,d3
				sub.w	d1,d3
				move.w	d3,offtopby
				move.w	objclipt,d1
noclGL:
				move.w	d2,d0
				cmp.w	objclipb,d2
				ble.s	nocrGL
				move.w	objclipb,d2
nocrGL:

; d1=top end
; d2=bot end

				move.l	2+PolyBotTab-PolyTopTab(a4),d3
				move.l	6+PolyBotTab-PolyTopTab(a4),d4

				move.l	2(a4),d5
				move.l	6(a4),d6

				sub.l	d5,d3
				sub.l	d6,d4

; asl.w #8,d3
; asl.w #8,d4
; ext.l d3
; ext.l d4

; and.b #63,d5
; and.b #63,d6
; lsl.w #8,d6
; move.b d5,d6	; starting pos
; moveq.l #0,d5
; move.w d6,d5


				sub.w	d1,d2
				ble		nodlGL

				move.w	#0,tstdca
				sub.w	d1,d0
				tst.w	offtopby
				beq.s	.notofftop
				move.l	d3,-(a7)
				move.l	d4,-(a7)
				add.w	offtopby,d0
				ext.l	d0
				muls.l	offtopby-2,d3
				muls.l	offtopby-2,d4
				divs.l	d0,d3
				divs.l	d0,d4

				add.l	d3,d5
				add.l	d4,d6

				move.l	(a7)+,d4
				move.l	(a7)+,d3
.notofftop:
				ext.l	d0

				divs.l	d0,d3
				divs.l	d0,d4

				add.l	ontoscrGL(pc,d1.w*4),a3

				move.l	#$3fffff,d1

				move.l	d3,a5
				moveq	#0,d3
				subq	#1,d2
drawpolGL:
				and.l	d1,d5
				and.l	d1,d6

				move.l	d6,d0
				asr.l	#8,d0
				swap	d5
				move.b	d5,d0

				move.b	(a0,d0.w*4),d3
				beq.s	itsblack

				lsl.w	#8,d3
				add.w	d3,d3
				move.b	(a3),d3

				swap	d5
				add.l	a5,d5
				add.l	d4,d6

				move.b	(a1,d3.w),(a3)
				adda.w	#SCREENWIDTH,a3
				dbra	d2,drawpolGL

nodlGL:
				adda.w	#16,a4
				dbra	d7,DOGLAREPOLY

				rts

itsblack:
				swap	d5
				add.l	a5,d5
				add.l	d4,d6
				adda.w	#SCREENWIDTH,a3
				dbra	d2,drawpolGL
				adda.w	#16,a4
				dbra	d7,DOGLAREPOLY

				rts

ontoscrGL:
val				SET		0
				REPT	256
				dc.l	val
val				SET		val+SCREENWIDTH
				ENDR

tstdca:			dc.l	0
				dc.w	0
offtopby:		dc.w	0
LinesPtr:		dc.l	0
PtsPtr:			dc.l	0

gotlurvelyshading:
				move.l	TexturePal,a1
				add.l	#256*32,a1
				tst.b	pregour
; beq.s .noshiny
; add.l #256*32,a1
;.noshiny:
; neg.w d1
; add.w #14,d1
; bge.s toobrightg
; move.w #0,d1
;toobrightg:
; asl.w #8,d1
; lea (a1,d1.w*2),a1

dopolyg:
				move.l	d7,-(a7)
				move.w	#0,offtopby
				move.l	a6,a3
				adda.w	a2,a3
				addq	#1,a2
				move.w	(a4),d1
				cmp.w	objclipb,d1
				bge		nodlg
				move.w	PolyBotTab-PolyTopTab(a4),d2
				cmp.w	objclipt(pc),d2
				ble		nodlg
				cmp.w	objclipt(pc),d1
				bge.s	noclg
				move.w	objclipt,d3
				sub.w	d1,d3
				move.w	d3,offtopby
				move.w	objclipt(pc),d1
noclg:
				move.w	d2,d0
				cmp.w	objclipb(pc),d2
				ble.s	nocrg
				move.w	objclipb(pc),d2
nocrg:

; d1=top end
; d2=bot end

				move.l	2+PolyBotTab-PolyTopTab(a4),d3
				move.l	6+PolyBotTab-PolyTopTab(a4),d4

				move.l	2(a4),d5
				move.l	6(a4),d6

				sub.l	d5,d3
				sub.l	d6,d4

; asl.w #8,d3
; asl.w #8,d4
; ext.l d3
; ext.l d4

; and.b #63,d5
; and.b #63,d6
; lsl.w #8,d6
; move.b d5,d6	; starting pos
; moveq.l #0,d5
; move.w d6,d5


				sub.w	d1,d2
				ble		nodlg

				move.w	#0,tstdca
				sub.w	d1,d0
				tst.w	offtopby
				beq.s	.notofftop
				move.l	d3,-(a7)
				move.l	d4,-(a7)
				add.w	offtopby,d0
				ext.l	d0
				muls.l	offtopby-2,d3
				muls.l	offtopby-2,d4
				divs.l	d0,d3
				divs.l	d0,d4

				add.l	d3,d5
				add.l	d4,d6

				move.l	(a7)+,d4
				move.l	(a7)+,d3
.notofftop
				ext.l	d0

				divs.l	d0,d3
				divs.l	d0,d4

				add.l	ontoscrg(pc,d1.w*4),a3
				move.w	10+PolyBotTab-PolyTopTab(a4),d1
				move.w	10(a4),d7
				sub.w	d7,d1
				asl.w	#8,d7
				swap	d1
				clr.w	d1
				divs.l	d0,d1

				asr.l	#8,d1

				move.l	d3,a5
				moveq	#0,d3

				swap	d2
				move.w	d1,d2
				swap	d2

				move.l	#$3fffff,d1

				subq.w	#1,d2
drawpolg:
				and.l	d1,d5
				and.l	d1,d6

				move.l	d6,d0
				asr.l	#8,d0
				swap	d5
				move.b	d5,d0

				move.w	d7,d3

				move.b	(a0,d0.w*4),d3

				swap	d2
				swap	d5
				add.l	a5,d5
				add.l	d4,d6
				add.w	d2,d7
				swap	d2
				move.b	(a1,d3.w),(a3)
				adda.w	#SCREENWIDTH,a3
				dbra	d2,drawpolg

nodlg:

				move.l	(a7)+,d7
				adda.w	#16,a4
				dbra	d7,dopolyg

				rts

ontoscrg:
val				SET		0
				REPT	256
				dc.l	val
val				SET		val+SCREENWIDTH
				ENDR




gotholesin:
				move.w	ObjAng,d4
				asr.w	#8,d4
				asr.w	#1,d4

				moveq	#0,d2
				moveq	#0,d3
				move.b	(a1)+,d2

				move.l	PolyAngPtr,a1
				move.b	(a1,d2.w),d2

				move.b	d2,d3
				lsr.b	#4,d3					;d3=vertical pos
				add.b	d4,d2
				and.w	#$f,d2

				move.l	#ANGLEBRIGHTS,a1
				moveq	#0,d4
				moveq	#0,d5
				move.b	(a1,d2.w),d4			;top
				move.b	16(a1,d2.w),d5			;bottom

				sub.w	d4,d5
				muls	d3,d5
				divs	#14,d5
				add.w	d4,d5

				add.w	d5,d1


				move.l	#objscalecols,a1

; move.w objbright(pc),d0
; add.w d0,d1
				tst.w	d1
				bge.s	toobrighth
				move.w	#0,d1
toobrighth:
				cmp.w	#31,d1
				ble.s	toodimh
				move.w	#31,d1
toodimh:

				asl.w	#8,d1

; move.w (a1,d1.w*2),d1
; asl.w #3,d1
				move.l	TexturePal,a1
				add.l	#256*32,a1
				add.w	d1,a1
				tst.b	pregour
; beq.s .noshiny
; add.l #256*32,a1
;.noshiny:

dopolyh:
				move.w	#0,offtopby
				move.l	a6,a3
				adda.w	a2,a3
				addq	#1,a2
				move.w	(a4),d1
				cmp.w	objclipb,d1
				bge		nodlh
				move.w	PolyBotTab-PolyTopTab(a4),d2
				cmp.w	objclipt,d2
				ble		nodlh
				cmp.w	objclipt,d1
				bge.s	noclh
				move.w	objclipt,d3
				sub.w	d1,d3
				move.w	d3,offtopby
				move.w	objclipt,d1
noclh:
				move.w	d2,d0
				cmp.w	objclipb,d2
				ble.s	nocrh
				move.w	objclipb,d2
nocrh:

; d1=top end
; d2=bot end

				move.l	2+PolyBotTab-PolyTopTab(a4),d3
				move.l	6+PolyBotTab-PolyTopTab(a4),d4

				move.l	2(a4),d5
				move.l	6(a4),d6

				sub.l	d5,d3
				sub.l	d6,d4

; asl.w #8,d3
; asl.w #8,d4
; ext.l d3
; ext.l d4

; and.b #63,d5
; and.b #63,d6
; lsl.w #8,d6
; move.b d5,d6	; starting pos
; moveq #-1,d5
; lsr.l #1,d5
; move.w d6,d5


				sub.w	d1,d2
				ble		nodlh

				move.w	#0,tstdca
				sub.w	d1,d0
				tst.w	offtopby
				beq.s	.notofftop
				move.l	d3,-(a7)
				move.l	d4,-(a7)
				add.w	offtopby,d0
				ext.l	d0
				muls.l	offtopby-2,d3
				muls.l	offtopby-2,d4
				divs.l	d0,d3
				divs.l	d0,d4

				add.l	d3,d5
				add.l	d4,d6

				move.l	(a7)+,d4
				move.l	(a7)+,d3
.notofftop:
				ext.l	d0

				divs.l	d0,d3
				divs.l	d0,d4

				add.l	ontoscrh(pc,d1.w*4),a3
				move.l	#$3fffff,d1

				move.l	d3,a5
				moveq	#0,d3
				subq	#1,d2
drawpolh:
				and.l	d1,d5
				and.l	d1,d6

				move.l	d6,d0
				asr.l	#8,d0
				swap	d5
				move.b	d5,d0

				swap	d5
				add.l	a5,d5
				add.l	d4,d6

				move.b	(a0,d0.w*4),d3

				beq.s	.dontplot
				move.b	(a1,d3.w),(a3)
.dontplot
				adda.w	#SCREENWIDTH,a3
				dbra	d2,drawpolh

pastith:

nodlh:
				adda.w	#16,a4
				dbra	d7,dopolyh

				rts

ontoscrh:
val				SET		0
				REPT	256
				dc.l	val
val				SET		val+SCREENWIDTH
				ENDR

				EVEN
pregour:
				dc.b	0
Gouraud:
				dc.b	0
preholes:
				dc.b	0
Holes:
				dc.b	0

putinlines:

				move.w	(a1),d0
				move.w	4(a1),d1

				move.w	(a3,d0.w*4),d2
				move.w	2(a3,d0.w*4),d3
				move.w	(a3,d1.w*4),d4
				move.w	2(a3,d1.w*4),d5

; d2=x1 d3=y1 d4=x2 d5=y2

				cmp.w	d2,d4
				beq		thislineflat
				bgt		thislineontop
				move.l	#PolyBotTab,a4
				exg		d2,d4
				exg		d3,d5

				cmp.w	rightclipb,d2
				bge		thislineflat
				cmp.w	leftclipb,d4
				ble		thislineflat
				move.w	rightclipb,d6
				sub.w	d4,d6
				ble.s	.clipr
				move.w	#0,-(a7)
				cmp.w	Right(pc),d4
				ble.s	.nonewbot
				move.w	d4,Right
				bra.s	.nonewbot

.clipr
				move.w	d6,-(a7)
				move.w	rightclipb,Right
				sub.w	#1,Right
.nonewbot:

				move.w	#0,offleftby
				move.w	d2,d6
				cmp.w	leftclipb,d6
				bge		.okt
				move.w	leftclipb,d6
				sub.w	d2,d6
				move.w	d6,offleftby
				add.w	d2,d6
.okt:

				st		drawit
				add.w	d6,d6
				lea		(a4,d6.w*8),a4
				asr.w	#1,d6
				cmp.w	Left(pc),d6
				bge.s	.nonewtop
				move.w	d6,Left
.nonewtop

				sub.w	d3,d5					; dy
				swap	d3
				clr.w	d3						; d2=xpos
				sub.w	d2,d4					; dx > 0
				ext.l	d4
				swap	d5
				clr.w	d5
				divs.l	d4,d5
				moveq	#0,d2
				move.b	2(a1),d2

				moveq	#0,d6
				move.b	6(a1),d6
				sub.w	d6,d2
				swap	d2
				swap	d6
				clr.w	d2
				clr.w	d6						; d6=xbitpos
				divs.l	d4,d2
				move.l	d5,a5					; a5=dy constant
				move.l	d2,a6					; a6=xbitconst

				moveq	#0,d5
				move.b	3(a1),d5
				moveq	#0,d2
				move.b	7(a1),d2
				sub.w	d2,d5
				swap	d2
				swap	d5
				clr.w	d2						; d3=ybitpos
				clr.w	d5
				divs.l	d4,d5

				add.w	(a7)+,d4
				sub.w	offleftby(pc),d4
				blt		thislineflat

				tst.w	offleftby(pc)
				beq.s	.noneoffleft
				move.w	d4,-(a7)
				move.w	offleftby(pc),d4
				dbra	d4,.calcnodraw
				bra		.nodrawoffleft
.calcnodraw

				add.l	a5,d3
				add.l	a6,d6
				add.l	d5,d2
				dbra	d4,.calcnodraw
.nodrawoffleft:
				move.w	(a7)+,d4
.noneoffleft:

.putinline:

				swap	d3
				move.w	d3,(a4)+
				swap	d3
				move.l	d6,(a4)+
				move.l	d2,(a4)+
				addq	#6,a4

				add.l	a5,d3
				add.l	a6,d6
				add.l	d5,d2

				dbra	d4,.putinline

				bra		thislineflat

thislineontop:
				move.l	#PolyTopTab,a4

				cmp.w	rightclipb,d2
				bge		thislineflat
				cmp.w	leftclipb,d4
				ble		thislineflat
				move.w	rightclipb,d6
				sub.w	d4,d6
				ble.s	.clipr
				move.w	#0,-(a7)
				cmp.w	Right(pc),d4
				ble.s	.nonewbot
				move.w	d4,Right
				bra.s	.nonewbot

.clipr
				move.w	d6,-(a7)
				move.w	rightclipb,Right
				sub.w	#1,Right
.nonewbot:

				move.w	#0,offleftby
				move.w	d2,d6
				cmp.w	leftclipb,d6
				bge		.okt
				move.w	leftclipb,d6
				sub.w	d2,d6
				move.w	d6,offleftby
				add.w	d2,d6
.okt:

				st		drawit
				add.w	d6,d6
				lea		(a4,d6.w*8),a4
				asr.w	#1,d6
				cmp.w	Left(pc),d6
				bge.s	.nonewtop
				move.w	d6,Left
.nonewtop

				sub.w	d3,d5					; dy
				swap	d3
				clr.w	d3						; d2=xpos
				sub.w	d2,d4					; dx > 0
				ext.l	d4
				swap	d5
				clr.w	d5
				divs.l	d4,d5
				moveq	#0,d2
				move.b	6(a1),d2
				moveq	#0,d6
				move.b	2(a1),d6
				sub.w	d6,d2
				swap	d2
				swap	d6
				clr.w	d2
				clr.w	d6						; d6=xbitpos
				divs.l	d4,d2
				move.l	d5,a5					; a5=dy constant
				move.l	d2,a6					; a6=xbitconst

				moveq	#0,d5
				move.b	7(a1),d5
				moveq	#0,d2
				move.b	3(a1),d2
				sub.w	d2,d5
				swap	d2
				swap	d5
				clr.w	d2						; d3=ybitpos
				clr.w	d5
				divs.l	d4,d5

				add.w	(a7)+,d4
				sub.w	offleftby(pc),d4
				blt.s	thislineflat

				tst.w	offleftby(pc)
				beq.s	.noneoffleft
				move.w	d4,-(a7)
				move.w	offleftby(pc),d4
				dbra	d4,.calcnodraw
				bra		.nodrawoffleft
.calcnodraw

				add.l	a5,d3
				add.l	a6,d6
				add.l	d5,d2
				dbra	d4,.calcnodraw
.nodrawoffleft:
				move.w	(a7)+,d4
.noneoffleft:


.putinline:

				swap	d3
				move.w	d3,(a4)+
				swap	d3
				move.l	d6,(a4)+
				move.l	d2,(a4)+
				addq	#6,a4

				add.l	a5,d3
				add.l	a6,d6
				add.l	d5,d2

				dbra	d4,.putinline

thislineflat:
				addq	#4,a1
				dbra	d7,putinlines
				addq	#4,a1
				rts

putingourlines:

				move.l	#boxbrights,a2

piglloop:

				move.w	(a1),d0
				move.w	4(a1),d1

				move.w	(a3,d0.w*4),d2
				move.w	2(a3,d0.w*4),d3
				move.w	(a3,d1.w*4),d4
				move.w	2(a3,d1.w*4),d5



				cmp.w	d2,d4
				beq		thislineflatgour
				bgt		thislineontopgour
				move.l	#PolyBotTab,a4
				exg		d2,d4
				exg		d3,d5

				cmp.w	rightclipb,d2
				bge		thislineflatgour
				cmp.w	leftclipb,d4
				ble		thislineflatgour
				move.w	rightclipb,d6
				sub.w	d4,d6
				ble.s	.clipr
				move.w	#0,-(a7)
				cmp.w	Right(pc),d4
				ble.s	.nonewbot
				move.w	d4,Right
				bra.s	.nonewbot

.clipr
				move.w	d6,-(a7)
				move.w	rightclipb,Right
				sub.w	#1,Right
.nonewbot:

				move.w	#0,offleftby
				move.w	d2,d6
				cmp.w	leftclipb,d6
				bge		.okt
				move.w	leftclipb,d6
				sub.w	d2,d6
				move.w	d6,offleftby
				add.w	d2,d6
.okt:

				st		drawit
				add.w	d6,d6
				lea		(a4,d6.w*8),a4
				asr.w	#1,d6
				cmp.w	Left(pc),d6
				bge.s	.nonewtop
				move.w	d6,Left
.nonewtop

				sub.w	d3,d5					; dy
				swap	d3
				clr.w	d3						; d2=xpos
				sub.w	d2,d4					; dx > 0
				ext.l	d4
				swap	d5
				clr.w	d5
				divs.l	d4,d5
				moveq	#0,d2
				move.b	2(a1),d2
				moveq	#0,d6
				move.b	6(a1),d6
				sub.w	d6,d2
				swap	d2
				swap	d6
				clr.w	d2
				clr.w	d6						; d6=xbitpos
				divs.l	d4,d2
				move.l	d5,a5					; a5=dy constant
				move.l	d2,a6					; a6=xbitconst

				moveq	#0,d5
				move.b	3(a1),d5
				moveq	#0,d2
				move.b	7(a1),d2

				sub.w	d2,d5
				swap	d2
				swap	d5
				clr.w	d2						; d3=ybitpos
				clr.w	d5
				divs.l	d4,d5

				move.w	(a2,d1.w*2),d1
				move.w	(a2,d0.w*2),d0
				sub.w	d1,d0
				swap	d0
				swap	d1
				clr.w	d0
				clr.w	d1
				divs.l	d4,d0

				add.w	(a7)+,d4
				sub.w	offleftby(pc),d4
				blt		thislineflatgour

				tst.w	offleftby(pc)
				beq.s	.noneoffleft
				move.w	d4,-(a7)
				move.w	offleftby(pc),d4
				dbra	d4,.calcnodraw
				bra		.nodrawoffleft
.calcnodraw
				add.l	d0,d1
				add.l	a5,d3
				add.l	a6,d6
				add.l	d5,d2
				dbra	d4,.calcnodraw
.nodrawoffleft:
				move.w	(a7)+,d4
.noneoffleft:

.putinline:

				swap	d3
				move.w	d3,(a4)+
				swap	d3
				move.l	d6,(a4)+
				move.l	d2,(a4)+
				swap	d1
				move.w	d1,(a4)
				addq	#6,a4
				swap	d1

				add.l	d0,d1
				add.l	a5,d3
				add.l	a6,d6
				add.l	d5,d2

				dbra	d4,.putinline

				bra		thislineflatgour

thislineontopgour:
				move.l	#PolyTopTab,a4

				cmp.w	rightclipb,d2
				bge		thislineflatgour
				cmp.w	leftclipb,d4
				ble		thislineflatgour
				move.w	rightclipb,d6
				sub.w	d4,d6
				ble.s	.clipr
				move.w	#0,-(a7)
				cmp.w	Right(pc),d4
				ble.s	.nonewbot
				move.w	d4,Right
				bra.s	.nonewbot

.clipr
				move.w	d6,-(a7)
				move.w	rightclipb,Right
				sub.w	#1,Right
.nonewbot:

				move.w	#0,offleftby
				move.w	d2,d6
				cmp.w	leftclipb,d6
				bge		.okt
				move.w	leftclipb,d6
				sub.w	d2,d6
				move.w	d6,offleftby
				add.w	d2,d6
.okt:

				st		drawit
				add.w	d6,d6
				lea		(a4,d6.w*8),a4
				asr.w	#1,d6
				cmp.w	Left(pc),d6
				bge.s	.nonewtop
				move.w	d6,Left
.nonewtop

				sub.w	d3,d5					; dy
				swap	d3
				clr.w	d3						; d2=xpos
				sub.w	d2,d4					; dx > 0
				ext.l	d4
				swap	d5
				clr.w	d5
				divs.l	d4,d5
				moveq	#0,d2
				move.b	6(a1),d2
				moveq	#0,d6
				move.b	2(a1),d6
				sub.w	d6,d2
				swap	d2
				swap	d6
				clr.w	d2
				clr.w	d6						; d6=xbitpos
				divs.l	d4,d2
				move.l	d5,a5					; a5=dy constant
				move.l	d2,a6					; a6=xbitconst

				moveq	#0,d5
				move.b	7(a1),d5
				moveq	#0,d2
				move.b	3(a1),d2

				sub.w	d2,d5
				swap	d2
				swap	d5
				clr.w	d2						; d3=ybitpos
				clr.w	d5
				divs.l	d4,d5

				move.w	(a2,d1.w*2),d1
				move.w	(a2,d0.w*2),d0
				sub.w	d0,d1
				swap	d0
				swap	d1
				clr.w	d0
				clr.w	d1
				divs.l	d4,d1

				add.w	(a7)+,d4
				sub.w	offleftby(pc),d4
				blt.s	thislineflatgour

				tst.w	offleftby(pc)
				beq.s	.noneoffleft
				move.w	d4,-(a7)
				move.w	offleftby(pc),d4
				dbra	d4,.calcnodraw
				bra		.nodrawoffleft
.calcnodraw
				add.l	d1,d0
				add.l	a5,d3
				add.l	a6,d6
				add.l	d5,d2
				dbra	d4,.calcnodraw
.nodrawoffleft:
				move.w	(a7)+,d4
.noneoffleft:


.putinline:

				swap	d3
				move.w	d3,(a4)+
				swap	d3
				move.l	d6,(a4)+
				move.l	d2,(a4)+
				swap	d0
				move.w	d0,(a4)
				addq	#6,a4
				swap	d0

				add.l	d1,d0
				add.l	a5,d3
				add.l	a6,d6
				add.l	d5,d2

				dbra	d4,.putinline

thislineflatgour:
				addq	#4,a1
				dbra	d7,piglloop
				addq	#4,a1
				rts

offleftby:		ds.w	1
Left:			ds.w	1
Right:			ds.w	1

				section	bss,bss

PointAndPolyBrights:
				ds.l	4*16


POINTER_TO_POINTERS: ds.l 1
START_OF_OBJ:	ds.l	1
num_points:		ds.w	1

POLYOBJECTS:
				ds.l	40

			; FIMXE: screenconv stores word sized points, why are they using ds.l here?
boxonscr:		ds.l	250*2					; projected 2D points in screenspace
boxrot:			ds.l	250*3					; rotated 3D points in X/Z plane (y pointing up)

boxbrights:		ds.w	250

boxang:			ds.w	1

				ds.w	SCREENWIDTH*4
PolyBotTab:		ds.w	SCREENWIDTH*8
				ds.w	SCREENWIDTH*4
PolyTopTab:		ds.w	SCREENWIDTH*8
				ds.w	SCREENWIDTH*4

;offset:
;				ds.w	1
;timer:
;				ds.w	1

Objects:		ds.l	38*4

TextureMaps:	ds.l	1
TexturePal:		ds.l	1

testval:		ds.l	1

				section	code,code
