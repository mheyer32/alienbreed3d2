
currzone: dc.w 0

ty3d: dc.l -100*1024
by3d: dc.l 1*1024

TOPOFROOM: dc.l 0
BOTOFROOM: dc.l 0
AFTERWATTOP: dc.l 0
AFTERWATBOT: dc.l 0
BEFOREWATTOP: dc.l 0
BEFOREWATBOT: dc.l 0
ROOMBACK: dc.l 0

objclipt: dc.w 0
objclipb: dc.w 0
rightclipb: dc.w 0
leftclipb: dc.w 0

ObjDraw:

 move.w (a0)+,d0
 cmp.w #1,d0
 blt.s beforewat
 beq.s afterwat
 bgt.s fullroom
 
beforewat:
 move.l BEFOREWATTOP,ty3d
 move.l BEFOREWATBOT,by3d
 bra.s donetopbot

afterwat:
 move.l AFTERWATTOP,ty3d
 move.l AFTERWATBOT,by3d
 bra.s donetopbot

fullroom:
 move.l TOPOFROOM(pc),ty3d
 move.l BOTOFROOM(pc),by3d

donetopbot:

; move.l (a0)+,by3d
; move.l (a0)+,ty3d
 
 movem.l d0-d7/a1-a6,-(a7)

 move.w rightclip,d0
 sub.w leftclip,d0
 subq #1,d0
 ble doneallinfront 

; CACHE_ON d6

 move.l ObjectData,a1
 move.l #ObjRotated,a2
 move.l #depthtable,a3
 move.l a3,a4
 move.w #79,d7
emptytab:
 move.l #$80010000,(a3)+
 dbra d7,emptytab
 
 moveq #0,d0
insertanobj
 move.w (a1),d1
 blt sortedall
 move.w GraphicRoom(a1),d2
 cmp.w currzone(pc),d2
 beq.s itsinthiszone 

notinthiszone:
 adda.w #64,a1
 addq #1,d0
 bra insertanobj

itsinthiszone:

 move.b DOUPPER,d4
 move.b ObjInTop(a1),d3
 eor.b d4,d3
 bne.s notinthiszone

 move.w 2(a2,d1.w*8),d1	; zpos

 move.l #depthtable-4,a4
stillinfront:
 addq #4,a4
 cmp.w (a4),d1
 blt stillinfront
 move.l #enddepthtab-4,a5
finishedshift
 move.l -(a5),4(a5)
 cmp.l a4,a5
 bgt.s finishedshift

 move.w d1,(a4)
 move.w d0,2(a4)
 
 adda.w #64,a1
 addq #1,d0
 
 bra insertanobj
 
sortedall:

 move.l #depthtable,a3

gobackanddoanother
 move.w (a3)+,d0
 blt.s doneallinfront
 
 move.w (a3)+,d0
 bsr DrawtheObject
 bra gobackanddoanother

doneallinfront
 
 movem.l (a7)+,d0-d7/a1-a6
 rts
 
depthtable: ds.l 80
enddepthtab:

DrawtheObject:

 movem.l d0-d7/a0-a6,-(a7)
  
 move.l ObjectData,a0
 move.l #ObjRotated,a1
 asl.w #6,d0
 adda.w d0,a0
 
 move.b ObjInTop(a0),IMINTHETOPDAD
 
 move.w (a0),d0
 move.w 2(a1,d0.w*8),d1	; z pos

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
 
 move.w leftclip,d0
 asr.w #1,d0
 move.w d0,leftclipb
 move.w rightclip,d0
 asr.w #1,d0
 move.w d0,rightclipb
 
 cmp.b #$ff,6(a0)
 bne BitMapObj

 bsr PolygonObj
 movem.l (a7)+,d0-d7/a0-a6
 rts

glassobj:
 move.w (a0)+,d0	;pt num
 move.w 2(a1,d0.w*8),d1
 cmp.w #25,d1
 ble objbehind
 
 move.w topclip,d2
 move.w botclip,d3
 
 move.l ty3d,d6
 sub.l yoff,d6
 divs d1,d6
 add.w MIDDLEY,d6
 cmp.w d3,d6
 bge objbehind
 cmp.w d2,d6
 bge.s .okobtc
 move.w d2,d6
.okobtc:
 move.w d6,objclipt

 move.l by3d,d6
 sub.l yoff,d6
 divs d1,d6
 add.w MIDDLEY,d6
 cmp.w d2,d6
 ble objbehind
 cmp.w d3,d6
 ble.s .okobbc
 move.w d3,d6
.okobbc:
 move.w d6,objclipb

 move.l 4(a1,d0.w*8),d0
 move.l (a0)+,d2	; height
 ext.l d2
 asl.l #7,d2
 sub.l yoff,d2
 divs d1,d2	
 add.w MIDDLEY,d2
 
 divs d1,d0
 add.w MIDDLEX,d0	;x pos of middle

; Need to calculate:
; Width of object in pixels
; height of object in pixels
; horizontal constants
; vertical constants.

 move.l #consttab,a3

 moveq #0,d3
 moveq #0,d4
 move.b (a0)+,d3
 move.b (a0)+,d4
 asl.w #7,d3
 asl.w #7,d4
 divs d1,d3 ;width in pixels
 divs d1,d4 ;height in pixels
 sub.w d4,d2
 sub.w d3,d0
 cmp.w rightclipb,d0
 bge objbehind
 add.w d3,d3
 cmp.w objclipb,d2
 bge objbehind
 
 add.w d4,d4
 
 move.w d3,realwidth
 move.w d4,realheight
 
* OBTAIN POINTERS TO HORIZ AND VERT
* CONSTANTS FOR MOVING ACROSS AND
* DOWN THE OBJECT GRAPHIC.
 
 move.w d1,d7
 moveq #0,d6
 move.b 6(a0),d6
 add.w d6,d6
 mulu d6,d7
 move.b -2(a0),d6
 divu d6,d7
 swap d7
 clr.w d7
 swap d7

 lea (a3,d7.l*8),a2	; pointer to
			; horiz const
 move.w d1,d7
 move.b 7(a0),d6
 add.w d6,d6
 mulu d6,d7
 move.b -1(a0),d6
 divu d6,d7
 swap d7
 clr.w d7
 swap d7
 lea (a3,d7.l*8),a3	; pointer to
 			; vertical c.

* CLIP OBJECT TO TOP AND BOTTOM
* OF THE VISIBLE DISPLAY

 moveq #0,d7
 cmp.w objclipt,d2
 bge.s .objfitsontop

 sub.w objclipt,d2
 add.w d2,d4	;new height in
		;pixels
 ble objbehind  ; nothing to draw

 move.w d2,d7
 neg.w d7	; factor to mult.
 		; constants by
 		; at top of obj.
 move.w objclipt,d2

.objfitsontop:

 move.w objclipb,d6
 sub.w d2,d6
 cmp.w d6,d4
 ble.s .objfitsonbot
 
 move.w d6,d4

.objfitsonbot:

 subq #1,d4
 blt objbehind

 move.l #ontoscr,a6
 move.l (a6,d2.w*4),d2

 add.l FASTBUFFER,d2
 move.l d2,toppt

 move.l #WorkSpace,a5
 move.l #glassball,a4
 cmp.w leftclipb,d0
 bge.s .okonleft

 sub.w leftclipb,d0
 add.w d0,d3
 ble objbehind
 
 move.w (a2),d1
 move.w 2(a2),d2
 neg.w d0
 muls d0,d1
 mulu d0,d2
 swap d2
 add.w d2,d1
 asl.w #7,d1
 lea (a5,d1.w),a5
 lea (a4,d1.w),a4
 
 move.w leftclipb,d0

.okonleft:

 move.w d0,d6
 add.w d3,d6
 sub.w rightclipb,d6
 blt.s .okrightside

 sub.w #1,d3
 sub.w d6,d3

.okrightside:

 move.l #objintocop,a1
 sub.l a1,a1
 move.w d0,a1
 add.w a1,a1

 move.w (a3),d5
 move.w 2(a3),d6
 muls d7,d5
 mulu d7,d6
 swap d6
 add.w d6,d5
; add.w 2(a0),d5	;d5 contains
 		;top offset into
 		;each strip.
 add.l #$80000000,d5
 	
 move.l (a2),d6
 moveq.l #0,d7
 move.l a5,midobj
 move.l a4,midglass
 move.l (a3),d2
 swap d2
 move.l #times128,a0

 movem.l d0-d7/a0-a6,-(a7)
 
 move.w d3,d1
 ext.l d1
 swap d1
 move.w d4,d2
 ext.l d2
 swap d2
 asr.l #6,d1
 asr.l #6,d2
 move.w d1,d5
 move.w d2,d6
 swap d1
 swap d2

 muls #320,d2
 
 move.l #WorkSpace,a0

 move.w #63,d0
.readinto:
 swap d0
 move.w #63,d0
 move.l toppt(pc),a6
 adda.w a1,a6
 add.w d1,a1
 add.w d5,d7
 bcc.s .noadmoreh
 addq #1,a1
.noadmoreh:
 swap d7
 move.w #0,d7 
.readintodown:
 move.w (a6),d3
 move.w d3,(a0)+
 add.w d2,a6
 add.w d6,d7
 bcc.s .noadmore
 adda.w #320,a6
.noadmore:
 dbra d0,.readintodown
 swap d0
 swap d7
 dbra d0,.readinto
 
 
; Want to zoom an area d3*d4
; in size up to 64*64 in size.
; move.l #WorkSpace,a0
; move.l frompt,a2
; move.w #104*4,d3
; move.w #1,d6
;.ribl
; move.w #31,d0
;.readinto
; move.w #15,d1
; move.l a2,a1
;.readintodown
; move.w (a1),(a0)+
; adda.w d3,a1
; move.w (a1),(a0)+
; adda.w d3,a1
; move.w (a1),(a0)+
; adda.w d3,a1
; move.w (a1),(a0)+
; adda.w d3,a1
; dbra d1,.readintodown
;; add.w #256-128,a0
; addq #4,a2
; dbra d0,.readinto
; addq #4,a2
; dbra d6,.ribl

 movem.l (a7)+,d0-d7/a0-a6

 move.l #darkentab,a2
 move.l toppt,d1
 add.l a1,d1
 move.l d1,toppt
 move.l d6,a1
 moveq #0,d6

.drawrightside:
 swap d7
 move.l midglass(pc),a4
 adda.w (a0,d7.w*2),a4
 swap d7
 add.l a1,d7
 move.l toppt(pc),a6
 addq.l #1,toppt

 move.l d5,d1
 move.w d4,-(a7)
 swap d3
.drawavertstrip
 move.w (a4,d1.w*2),d3
 blt.s .itsbackground
 move.b (a5,d3.w*2),d6
 move.b (a2,d6.w),(a6)
.itsbackground
 adda.w #320,a6
 addx.l d2,d1
 dbra d4,.drawavertstrip
 swap d3
 move.w (a7)+,d4

 dbra d3,.drawrightside
 movem.l (a7)+,d0-d7/a0-a6

 rts
 
realwidth: dc.w 0
realheight: dc.w 0
 
AUXX: dc.w 0
AUXY: dc.w 0
 
midglass:
 dc.l 0
times128:
val SET 0
 REPT 100
 dc.w val*128
val SET val+1
 ENDR

BRIGHTTOADD: dc.w 0

glareobj:


 move.w (a0)+,d0	;pt num
 move.w 2(a1,d0.w*8),d1
 cmp.w #25,d1
 ble objbehind
 
 move.w topclip,d2
 move.w botclip,d3
 
 move.l ty3d,d6
 sub.l yoff,d6
 divs d1,d6
 add.w MIDDLEY,d6
 cmp.w d3,d6
 bge objbehind
 cmp.w d2,d6
 bge.s .okobtc
 move.w d2,d6
.okobtc:
 move.w d6,objclipt

 move.l by3d,d6
 sub.l yoff,d6
 divs d1,d6
 add.w MIDDLEY,d6
 cmp.w d2,d6
 ble objbehind
 cmp.w d3,d6
 ble.s .okobbc
 move.w d3,d6
.okobbc:
 move.w d6,objclipb

 move.l 4(a1,d0.w*8),d0
 move.w AUXX,d2
 ext.l d2
 asl.l #7,d2
 add.l d2,d0
 addq #2,a0
 move.l #SHADINGTABLE-512,a4
 
 move.w (a0)+,d2	; height
 add.w AUXY,d2
 ext.l d2
 asl.l #7,d2
 sub.l yoff,d2
 divs d1,d2	
 add.w MIDDLEY,d2
 
 divs d1,d0
 add.w MIDDLEX,d0	;x pos of middle

; Need to calculate:
; Width of object in pixels
; height of object in pixels
; horizontal constants
; vertical constants.
 move.l LINKFILE,a6
 lea FrameData(a6),a6
 move.l #Objects,a5
 move.w 2(a0),d7
 neg.w d7
 asl.w #4,d7
 adda.w d7,a5
 asl.w #4,d7
 adda.w d7,a6

 move.w 4(a0),d7
 lea (a6,d7.w*8),a6

 move.l #consttab,a3

 moveq #0,d3
 moveq #0,d4
 move.b (a0)+,d3
 move.b (a0)+,d4
 lsl.l #7,d3
 lsl.l #7,d4
 divs d1,d3 ;width in pixels
 divs d1,d4 ;height in pixels
 
 sub.w d4,d2
 sub.w d3,d0
 cmp.w rightclipb,d0
 bge objbehind
 add.w d3,d3
 cmp.w objclipb,d2
 bge objbehind
 
 add.w d4,d4
 
* OBTAIN POINTERS TO HORIZ AND VERT
* CONSTANTS FOR MOVING ACROSS AND
* DOWN THE OBJECT GRAPHIC.

 move.l (a5)+,WAD_PTR
 move.l (a5)+,PTR_PTR
 
 move.l (a6),d7
 move.w d7,DOWN_STRIP
 move.l PTR_PTR,a5
 swap d7
 asl.w #2,d7
 adda.w d7,a5

 move.w d1,d7
 moveq #0,d6
 move.w 4(a6),d6
 add.w d6,d6
 subq #1,d6
 mulu d6,d7
 moveq #0,d6
 move.b -2(a0),d6
 beq objbehind
 divu d6,d7
 swap d7
 clr.w d7
 swap d7
 lea (a3,d7.l*8),a2	; pointer to
			; horiz const
 move.w d1,d7
 move.w 6(a6),d6
 add.w d6,d6
 subq #1,d6
 mulu d6,d7
 moveq #0,d6
 move.b -1(a0),d6
 beq objbehind
 divu d6,d7
 swap d7
 clr.w d7
 swap d7
 lea (a3,d7.l*8),a3	; pointer to
 			; vertical c.

* CLIP OBJECT TO TOP AND BOTTOM
* OF THE VISIBLE DISPLAY

 moveq #0,d7
 cmp.w objclipt,d2
 bge.s objfitsontopGLARE

 sub.w objclipt,d2
 add.w d2,d4	;new height in
		;pixels
 ble objbehind  ; nothing to draw

 move.w d2,d7
 neg.w d7	; factor to mult.
 		; constants by
 		; at top of obj.
 move.w objclipt,d2

objfitsontopGLARE:

 move.w objclipb,d6
 sub.w d2,d6
 cmp.w d6,d4
 ble.s objfitsonbotGLARE
 
 move.w d6,d4

objfitsonbotGLARE:

 subq #1,d4
 blt objbehind

 move.l #ontoscr,a6
 move.l (a6,d2.w*4),d2
 add.l FASTBUFFER,d2
 move.l d2,toppt

 cmp.w leftclipb,d0
 bge.s okonleftGLARE

 sub.w leftclipb,d0
 add.w d0,d3
 ble objbehind
 
 move.w (a2),d1
 move.w 2(a2),d2
 neg.w d0
 muls d0,d1
 mulu d0,d2
 swap d2
 add.w d2,d1
 lea (a5,d1.w*4),a5
 
 move.w leftclipb,d0

okonleftGLARE:

 move.w d0,d6
 add.w d3,d6
 sub.w rightclipb,d6
 blt.s okrightsideGLARE

 sub.w #1,d3
 sub.w d6,d3

okrightsideGLARE:

 ext.l d0
 add.l d0,toppt


 move.w (a3),d5
 move.w 2(a3),d6
 muls d7,d5
 mulu d7,d6
 swap d6
 add.w d6,d5
 add.w DOWN_STRIP(PC),d5	;d5 contains
 		;top offset into
 		;each strip.
 add.l #$80000000,d5
 	
 move.l (a2),a2
 moveq.l #0,d7
 move.l a5,midobj
 move.l (a3),d2
 swap d2
 
 move.l #0,a1
 

drawrightsideGLARE:
 swap d7
 move.l midobj(pc),a5
 lea (a5,d7.w*4),a5
 swap d7
 add.l a2,d7
 move.l WAD_PTR(PC),a0
 
 move.l toppt(pc),a6
 adda.w a1,a6
 addq #1,a1
 move.l (a5),d1
 beq blankstripGLARE
 
 and.l #$ffffff,d1
 add.l d1,a0

 move.b (a5),d1
 cmp.b #1,d1
 bgt.s ThirdThirdGLARE
 beq.s SecThirdGLARE
 move.l d5,d6
 move.l d5,d1
 move.w d4,-(a7)
.drawavertstrip
 move.b 1(a0,d1.w*2),d0
 and.b #%00011111,d0
 beq.s .dontplotthisoneitsblack
 lsl.w #8,d0
 move.b (a6),d0
 move.b (a4,d0.w*2),(a6)
.dontplotthisoneitsblack:
 adda.w #320,a6
 add.l d2,d6
 addx.w d2,d1
 dbra d4,.drawavertstrip
 move.w (a7)+,d4
blankstripGLARE:
 dbra d3,drawrightsideGLARE
 bra objbehind

SecThirdGLARE:
 move.l d5,d1
 move.l d5,d6
 move.w d4,-(a7)
.drawavertstrip
 move.w (a0,d1.w*2),d0
 lsr.w #5,d0
 and.w #%11111,d0
 beq.s .dontplotthisoneitsblack
 lsl.w #8,d0
 move.b (a6),d0
 move.b (a4,d0.w*2),(a6)
.dontplotthisoneitsblack:
 adda.w #320,a6
 add.l d2,d6
 addx.w d2,d1
 dbra d4,.drawavertstrip
 move.w (a7)+,d4
 dbra d3,drawrightsideGLARE
 bra objbehind

ThirdThirdGLARE:
 move.l d5,d1
 move.l d5,d6
 move.w d4,-(a7)
.drawavertstrip
 move.b (a0,d1.w*2),d0
 lsr.b #2,d0
 and.b #%11111,d0
 beq.s .dontplotthisoneitsblack
 lsl.w #8,d0
 move.b (a6),d0
 move.b (a4,d0.w*2),(a6)
.dontplotthisoneitsblack:
 adda.w #320,a6
 add.l d2,d6
 addx.w d2,d1
 dbra d4,.drawavertstrip
 move.w (a7)+,d4
 dbra d3,drawrightsideGLARE
 
 movem.l (a7)+,d0-d7/a0-a6
 rts



BitMapObj:
 move.l #0,AUXX

 cmp.b #3,16(a0)
 bne.s .NOTAUX
 
 move.w auxxoff(a0),AUXX
 move.w auxyoff(a0),AUXY
  
.NOTAUX:

 tst.l 8(a0)
 blt glareobj
 
 move.w Facing(a0),FACINGANG
 
 move.w (a0)+,d0	;pt num
 
 move.l ObjectPoints,a4
 
 move.w (a4,d0.w*8),thisxpos
 move.w 4(a4,d0.w*8),thiszpos
 
 move.w 2(a1,d0.w*8),d1
 cmp.w #25,d1
 ble objbehind
 
 move.w topclip,d2
 asr.w #1,d2
 move.w botclip,d3
 asr.w #1,d3
 
 move.l ty3d,d6
 sub.l yoff,d6
 divs d1,d6
 add.w d6,d6
 add.w MIDDLEY,d6
 asr.w #1,d6
 cmp.w d3,d6
 bge objbehind
 cmp.w d2,d6
 bge.s .okobtc
 move.w d2,d6
.okobtc:
 move.w d6,objclipt

 move.l by3d,d6
 sub.l yoff,d6
 divs d1,d6
 add.w d6,d6
 add.w MIDDLEY,d6
 asr.w #1,d6
 cmp.w d2,d6
 ble objbehind
 cmp.w d3,d6
 ble.s .okobbc
 move.w d3,d6
.okobbc:
 move.w d6,objclipb

 move.l 4(a1,d0.w*8),d0
 move.w AUXX,d2
 ext.l d2
 asl.l #7,d2
 add.l d2,d0
 move.w d1,d6
 asr.w #6,d6
 add.w (a0)+,d6
 move.w d6,BRIGHTTOADD
 
 bge.s brighttoonot
 moveq #0,d6
brighttoonot
 sub.l a4,a4
 move.w objscalecols(pc,d6.w*2),a4
 bra pastobjscale

objscalecols:
 dcb.w  2,64*0
 dcb.w  4,64*1
 dcb.w  4,64*2
 dcb.w  4,64*3
 dcb.w  4,64*4
 dcb.w  4,64*5
 dcb.w  4,64*6
 dcb.w  4,64*7
 dcb.w  4,64*8
 dcb.w  4,64*9
 dcb.w  4,64*10
 dcb.w  4,64*11
 dcb.w  4,64*12
 dcb.w  4,64*13
 dcb.w  20,64*14
 
WHICHLIGHTPAL: dc.w 0
FLIPIT: dc.w 0
FLIPPEDIT: dc.w 0
LIGHTIT: dc.w 0
ADDITIVE: dc.w 0
BASEPAL: dc.l 0
 
pastobjscale:
 
 move.w (a0)+,d2	; height
 
 add.w AUXY,d2
 ext.l d2
 asl.l #7,d2
 sub.l yoff,d2
 divs d1,d2	
 add.w d2,d2
 add.w MIDDLEY,d2
 asr.w #1,d2

 divs d1,d0
 add.w d0,d0
 add.w MIDDLEX,d0	;x pos of middle
 asr.w #1,d0

; Need to calculate:
; Width of object in pixels
; height of object in pixels
; horizontal constants
; vertical constants.

 move.l LINKFILE,a6
 lea FrameData(a6),a6
 move.l #Objects,a5
 move.w 2(a0),d7
 asl.w #4,d7
 adda.w d7,a5
 asl.w #4,d7
 adda.w d7,a6

 clr.b LIGHTIT
 clr.b ADDITIVE
 move.b 4(a0),d7
 btst #7,d7
 sne FLIPIT
 and.b #127,d7
 sub.b #2,d7
 blt.s .NOTALIGHT
 
 cmp.b #4,d7
 blt.s .isalight
 
 st ADDITIVE
 bra.s .NOTALIGHT
.isalight:
 
 st LIGHTIT
 move.b d7,WHICHLIGHTPAL
 
.NOTALIGHT:

 moveq #0,d7
 move.b 5(a0),d7
 lea (a6,d7.w*8),a6
 
 move.l #consttab,a3

 moveq #0,d3
 moveq #0,d4
 move.b (a0)+,d3
 move.b (a0)+,d4
 lsl.l #7,d3
 lsl.l #7,d4
 divs d1,d3 ;width in pixels
 divs d1,d4 ;height in pixels
 
 sub.w d4,d2
 sub.w d3,d0
 cmp.w rightclipb,d0
 bge objbehind
 add.w d3,d3
 cmp.w objclipb,d2
 bge objbehind
 
 add.w d4,d4
 
* OBTAIN POINTERS TO HORIZ AND VERT
* CONSTANTS FOR MOVING ACROSS AND
* DOWN THE OBJECT GRAPHIC.

 move.l (a5)+,WAD_PTR
 move.l (a5)+,PTR_PTR
 add.l 4(a5),a4
 move.l 4(a5),BASEPAL
 
 move.l (a6),d7
 move.w d7,DOWN_STRIP
 move.l PTR_PTR,a5
 
 tst.b FLIPIT
 beq.s .nfl1
 
 move.w 4(a6),d6
 add.w d6,d6
 subq #1,d6
 lea (a5,d6.w*4),a5
 
.nfl1:
 swap d7
 asl.w #2,d7
 adda.w d7,a5
fl1:
 
 move.w d1,d7
 moveq #0,d6
 move.w 4(a6),d6
 add.w d6,d6
 subq #1,d6
 mulu d6,d7
 moveq #0,d6
 move.b -2(a0),d6
 beq objbehind
 divu d6,d7
 swap d7
 clr.w d7
 swap d7
 lea (a3,d7.l*8),a2	; pointer to
			; horiz const
 move.w d1,d7
 move.w 6(a6),d6
 add.w d6,d6
 subq #1,d6
 mulu d6,d7
 moveq #0,d6
 move.b -1(a0),d6
 beq objbehind
 divu d6,d7
 swap d7
 clr.w d7
 swap d7
 lea (a3,d7.l*8),a3	; pointer to
 			; vertical c.

* CLIP OBJECT TO TOP AND BOTTOM
* OF THE VISIBLE DISPLAY

 moveq #0,d7
 cmp.w objclipt,d2
 bge.s objfitsontop

 sub.w objclipt,d2
 add.w d2,d4	;new height in
		;pixels
 ble objbehind  ; nothing to draw

 move.w d2,d7
 neg.w d7	; factor to mult.
 		; constants by
 		; at top of obj.
 move.w objclipt,d2

objfitsontop:

 move.w objclipb,d6
 sub.w d2,d6
 cmp.w d6,d4
 ble.s objfitsonbot
 
 move.w d6,d4

objfitsonbot:

 subq #1,d4
 blt objbehind

 move.l #ontoscr,a6
 move.l (a6,d2.w*4),d2
 add.l frompt,d2
 move.l d2,toppt

 cmp.w leftclipb,d0
 bge.s okonleft

 sub.w leftclipb,d0
 add.w d0,d3
 ble objbehind
 
 move.w (a2),d1
 move.w 2(a2),d2
 neg.w d0
 muls d0,d1
 mulu d0,d2
 swap d2
 add.w d2,d1
 move.w leftclipb,d0
 
 asl.w #2,d1
 tst.b FLIPIT
 beq.s .nfl2
 
 suba.w d1,a5
 suba.w d1,a5

.nfl2:

 adda.w d1,a5 

okonleft:

 move.w d0,d6
 add.w d3,d6
 sub.w rightclipb,d6
 blt.s okrightside

 sub.w #1,d3
 sub.w d6,d3

okrightside:

 move.l #objintocop,a1
 lea (a1,d0.w*2),a1
; ext.l d0
; add.l d0,toppt

 move.w (a3),d5
 move.w 2(a3),d6
 muls d7,d5
 mulu d7,d6
 swap d6
 add.w d6,d5
 add.w DOWN_STRIP(PC),d5	;d5 contains
 		;top offset into
 		;each strip.
 add.l #$80000000,d5
 	
 move.l (a2),d7
 tst.b FLIPIT
 beq.s .nfl3
 neg.l d7
.nfl3:
 move.l d7,a2
 moveq.l #0,d7
 move.l a5,midobj
 move.l (a3),d2
 swap d2
 
; move.l #0,a1
 
 tst.b LIGHTIT
 bne DRAWITLIGHTED
 
 tst.b ADDITIVE
 bne DRAWITADDED

drawrightside:
 swap d7
 move.l midobj(pc),a5
 lea (a5,d7.w*4),a5
 swap d7
 add.l a2,d7
 move.l WAD_PTR(PC),a0
 
 move.l toppt(pc),a6
 adda.w (a1)+,a6
; addq #1,a1
 move.l (a5),d1
 beq blankstrip
 
 and.l #$ffffff,d1
 add.l d1,a0

 move.b (a5),d1
 cmp.b #1,d1
 bgt.s ThirdThird
 beq.s SecThird
 move.l d5,d6
 move.l d5,d1
 move.w d4,-(a7)
.drawavertstrip
 move.b 1(a0,d1.w*2),d0
 and.b #%00011111,d0
 beq.s .dontplotthisoneitsblack
 move.w (a4,d0.w*2),(a6)
.dontplotthisoneitsblack:
 adda.w #104*4,a6
 add.l d2,d6
 addx.w d2,d1
 dbra d4,.drawavertstrip
 move.w (a7)+,d4
blankstrip:
 dbra d3,drawrightside
 bra.s objbehind

SecThird:
 move.l d5,d1
 move.l d5,d6
 move.w d4,-(a7)
.drawavertstrip
 move.w (a0,d1.w*2),d0
 lsr.w #5,d0
 and.w #%11111,d0
 beq.s .dontplotthisoneitsblack
 move.w (a4,d0.w*2),(a6)
.dontplotthisoneitsblack:
 adda.w #104*4,a6
 add.l d2,d6
 addx.w d2,d1
 dbra d4,.drawavertstrip
 move.w (a7)+,d4
 dbra d3,drawrightside
 bra.s objbehind

ThirdThird:
 move.l d5,d1
 move.l d5,d6
 move.w d4,-(a7)
.drawavertstrip
 move.b (a0,d1.w*2),d0
 lsr.b #2,d0
 and.b #%11111,d0
 beq.s .dontplotthisoneitsblack
 move.w (a4,d0.w*2),(a6)
.dontplotthisoneitsblack:
 adda.w #104*4,a6
 add.l d2,d6
 addx.w d2,d1
 dbra d4,.drawavertstrip
 move.w (a7)+,d4
 dbra d3,drawrightside
 
objbehind:
 movem.l (a7)+,d0-d7/a0-a6
 rts
 
DRAWITADDED:
 move.l BASEPAL,a4
 
drawrightsideADD:
 swap d7
 move.l midobj(pc),a5
 lea (a5,d7.w*4),a5
 swap d7
 add.l a2,d7
 move.l WAD_PTR(PC),a0
 
 move.l toppt(pc),a6
 adda.w a1,a6
 addq #1,a1
 move.l (a5),d1
 beq blankstripADD
 
 and.l #$ffffff,d1
 add.l d1,a0

 move.b (a5),d1
 cmp.b #1,d1
 bgt.s ThirdThirdADD
 beq.s SecThirdADD
 move.l d5,d6
 move.l d5,d1
 move.w d4,-(a7)
.drawavertstrip
 move.b 1(a0,d1.w*2),d0
 and.b #%00011111,d0
 lsl.w #8,d0
 move.b (a6),d0
 move.b (a4,d0.w),(a6)
 adda.w #320,a6
 add.l d2,d6
 addx.w d2,d1
 dbra d4,.drawavertstrip
 move.w (a7)+,d4
blankstripADD:
 dbra d3,drawrightsideADD
 bra objbehind

SecThirdADD:
 move.l d5,d1
 move.l d5,d6
 move.w d4,-(a7)
.drawavertstrip
 move.w (a0,d1.w*2),d0
 lsr.w #5,d0
 and.w #%11111,d0
 lsl.w #8,d0
 move.b (a6),d0
 move.b (a4,d0.w),(a6)
 adda.w #320,a6
 add.l d2,d6
 addx.w d2,d1
 dbra d4,.drawavertstrip
 move.w (a7)+,d4
 dbra d3,drawrightsideADD
 bra objbehind

ThirdThirdADD:
 move.l d5,d1
 move.l d5,d6
 move.w d4,-(a7)
.drawavertstrip
 move.b (a0,d1.w*2),d0
 lsr.b #2,d0
 and.b #%11111,d0
 lsl.w #8,d0
 move.b (a6),d0
 move.b (a4,d0.w),(a6)
.dontplotthisoneitsblack:
 adda.w #320,a6
 add.l d2,d6
 addx.w d2,d1
 dbra d4,.drawavertstrip
 move.w (a7)+,d4
 dbra d3,drawrightsideADD
 
 bra objbehind
 
DRAWITLIGHTED:

; Make up lighting values

 movem.l d0-d7/a0-a6,-(a7)

 move.l #ANGLEBRIGHTS,a2
 move.l #$80808080,(a2)
 move.l #$80808080,4(a2)
 move.l #$80808080,8(a2)
 move.l #$80808080,12(a2)
 move.l #$80808080,16(a2)
 move.l #$80808080,20(a2)
 move.l #$80808080,24(a2)
 move.l #$80808080,28(a2)
 
 move.l #$80808080,32(a2)
 move.l #$80808080,36(a2)
 move.l #$80808080,40(a2)
 move.l #$80808080,44(a2)
 move.l #$80808080,48(a2)
 move.l #$80808080,52(a2)
 move.l #$80808080,56(a2)
 move.l #$80808080,60(a2)

 move.w currzone(pc),d0
 bsr CALCBRIGHTSINZONE

 move.l #ANGLEBRIGHTS+32,a2

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

 move.l #xzangs,a0
 move.l #ANGLEBRIGHTS,a1
 move.w #15,d7
 sub.l a2,a2
 sub.l a3,a3
 sub.l a4,a4
 sub.l a5,a5
 moveq #00,d0
 moveq #00,d1
averageangle:

 moveq #0,d4
 move.b 16(a1),d4
 cmp.b #$80,d4
 beq.s .nobright
 
 neg.w d4
 add.w #48,d4
 cmp.b d1,d4
 ble.s .nobrightest
 move.b d4,d1
.nobrightest:


 move.w (a0),d5
 move.w 2(a0),d6
 muls d4,d5
 muls d4,d6
 add.l d5,a2
 add.l d6,a3
 
.nobright:

BOTTYL:

 moveq #0,d4
 move.b (a1),d4
 cmp.b #$80,d4
 beq.s .nobright 
 neg.w d4
 add.w #48,d4
 cmp.b d0,d4
 blt.s .nobrightest
 move.b d4,d0
.nobrightest:
 
 move.w (a0),d5
 move.w 2(a0),d6
 muls d4,d5
 muls d4,d6
 add.l d5,a4
 add.l d6,a5

.nobright:
 addq #4,a0
 addq #1,a1

 dbra d7,averageangle

 move.l a2,d2
 move.l a3,d3
 move.l a4,d4
 move.l a5,d5

 add.l d2,d4
 add.l d3,d5	; bright dir.

 bsr FINDROUGHANG
 
foundang:
 
 move.w #7,d2
 move.w d1,d3 
 cmp.w d0,d1
 beq.s INMIDDLE
 bgt.s .okpicked
 move.w d0,d3
.okpicked
 
 move.w d0,d2
 add.w d1,d2	; total brightness

 muls #16,d1
 subq #1,d1
 divs d2,d1
 move.w d1,d2
 
INMIDDLE:
 ; d2=y distance from middle of brightest pt.
 ; d3=brightness
 neg.w d3
 add.w #48,d3
 
 move.l #willy,a0
 move.l #guff,a1
 add.l guffptr,a1
; add.l #16*7,guffptr
; cmp.l #16*7*15,guffptr
; ble.s .noreguff
; move.l #0,guffptr
;.noreguff:
 
 muls #7*16,d2
 add.l d2,a1
 
 move.w p1_angpos,d0
 neg.w d0
 add.w #4096,d0
 and.w #8191,d0
 asr.w #8,d0
 asr.w #1,d0
 
 sub.b #3,d0
 add.b d4,d0
 and.w #15,d0
 move.w #6,d1
.across:
 move.w #6,d2
 move.w d0,d5
.down
 move.b (a1,d5),d4
 add.b d3,d4
 ext.w d4
 move.w d4,(a0)+
 addq #1,d5
 and.w #15,d5
 dbra d2,.down
 add.w #16,a1
 dbra d1,.across

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


 move.w BRIGHTTOADD,d0
 move.l #willy,a0
 move.l #willybright,a1
 move.w #48,d1
ADDITIN:

 move.w d0,d2
 add.w (a1)+,d2
 ble.s .nopos
 
 moveq #0,d2
 
.nopos:

 add.w d2,(a0)+

 dbra d1,ADDITIN



 tst.b FLIPIT
 beq.s LEFTTORIGHT

 move.l #Brights2,a0
 bra DONERIGHTTOLEFT

LEFTTORIGHT:

 move.l #Brights,a0
DONERIGHTTOLEFT:
 move.l #willy,a2
 move.l BASEPAL,a1
 move.b WHICHLIGHTPAL,d0
 asl.w #8,d0
 add.w d0,a1 
 move.l #PALS,a3
 move.w #28,d0
makepals:

 move.w (a0)+,d1
 move.w (a2,d1.w*2),d1
 bge.s .okpos
 moveq #0,d1
.okpos: 
 cmp.w #31,d1
 blt.s .okneg
 move.w #31,d1
.okneg:
 
 move.l (a1,d1.w*8),(a3)+
 move.b #0,-4(a3)
 move.l 4(a1,d1.w*8),(a3)+

 dbra d0,makepals
 
 movem.l (a7)+,d0-d7/a0-a6
 
 move.l #PALS,a4

drawlightlop
 swap d7
 move.l midobj(pc),a5
 lea (a5,d7.w*4),a5
 swap d7
 add.l a2,d7
 move.l WAD_PTR(PC),a0
 
 move.l toppt(pc),a6
 adda.w a1,a6
 addq #1,a1
 move.l (a5),d1
 beq .blankstrip
 
 add.l d1,a0

 move.l d5,d6
 move.l d5,d1
 move.w d4,-(a7)
.drawavertstrip
 move.b (a0,d1.w),d0
 beq.s .dontplotthisoneitsblack
 move.b (a4,d0.w),(a6)
.dontplotthisoneitsblack:
 adda.w #320,a6
 add.l d2,d6
 addx.w d2,d1
 dbra d4,.drawavertstrip
 move.w (a7)+,d4
.blankstrip:
 dbra d3,drawlightlop
 bra objbehind

*********************************************
FINDROUGHANG:
 neg.l d5
 moveq #0,d7
 tst.l d4
 bge.s .no8
 add.w #8,d7
 neg.l d4
.no8
 tst.l d5
 bge.s .no4
 neg.l d5
 add.w #4,d7
.no4
 cmp.l d5,d4
 bge.s .no2
 addq #2,d7
 exg d4,d5
.no2:
 asr.l #1,d4
 cmp.l d5,d4
 bge.s .no1
 addq #1,d7
.no1

 move.w maptoang(pc,d7.w*2),d4	; retun angle
 rts
 
maptoang:
 dc.w 3,2,0,1,4,5,7,6
 dc.w 12,13,15,14,11,10,8,9

guffptr: dc.l 0

*********************************************
CALCBRIGHTRINGS:
 move.l #ANGLEBRIGHTS,a2
 move.l #$80808080,(a2)
 move.l #$80808080,4(a2)
 move.l #$80808080,8(a2)
 move.l #$80808080,12(a2)
 move.l #$80808080,16(a2)
 move.l #$80808080,20(a2)
 move.l #$80808080,24(a2)
 move.l #$80808080,28(a2)
 
 move.l #$80808080,32(a2)
 move.l #$80808080,36(a2)
 move.l #$80808080,40(a2)
 move.l #$80808080,44(a2)
 move.l #$80808080,48(a2)
 move.l #$80808080,52(a2)
 move.l #$80808080,56(a2)
 move.l #$80808080,60(a2)

 move.w currzone(pc),d0
 bsr CALCBRIGHTSINZONE

 move.l #ANGLEBRIGHTS+32,a2

; Now do the brightnesses of surrounding
; zones:

 move.l FloorLines,a1
 move.w currzone,d0
 move.l ZoneAdds,a4
 move.l (a4,d0.w*4),a4
 add.l LEVELDATA,a4
 move.l a4,a5
 
 adda.w ToExitList(a4),a5
 
.doallwalls
 move.w (a5)+,d0
 blt .nomorewalls

 asl.w #4,d0
 lea (a1,d0.w),a3
 
 move.w 8(a3),d0
 blt.s .solidwall ; a wall not an exit.
 
 movem.l a1/a4/a5,-(a7) 
 bsr CALCBRIGHTSINZONE
 movem.l (a7)+,a1/a4/a5
 bra .doallwalls

.solidwall:
 move.w 4(a3),d1
 move.w 6(a3),d2
 
 move.w oldx,newx
 move.w oldz,newz
 sub.w d2,newx
 add.w d1,newz

 movem.l d0-d7/a0-a6,-(a7)
 jsr HeadTowardsAng
 movem.l (a7)+,d0-d7/a0-a6
 move.w AngRet,d1
 neg.w d1
 and.w #8191,d1
 asr.w #8,d1
 asr.w #1,d1

 move.b #48,(a2,d1.w)
 move.b #48,16(a2,d1.w)
 bra .doallwalls 

.nomorewalls:


; move.b #0,(a2)
; move.b #20,8(a2)
; move.b #0,16(a2)
; move.b #20,24(a2)

 move.l #ANGLEBRIGHTS,a0
 bsr TWEENBRIGHTS
 move.l #ANGLEBRIGHTS+16,a0
 bsr TWEENBRIGHTS
 move.l #ANGLEBRIGHTS+32,a0
 bsr TWEENBRIGHTS
 move.l #ANGLEBRIGHTS+48,a0
 bsr TWEENBRIGHTS
 
 move.l #ANGLEBRIGHTS,a0
 move.b #15,d0
ADDBRIGHTS

 moveq #0,d3
 moveq #0,d4
 move.b 32(a0),d3
 move.b 48(a0),d4
 neg.w d3
 add.w #48,d3
 neg.w d4
 add.w #48,d4
 asr.w #1,d4
 asr.w #1,d3
 
 move.b 16(a0),d5
 sub.b d5,d4
 ble.s .ok2
 moveq #0,d4
.ok2:
 move.b (a0),d5
 sub.b d5,d3
 ble.s .ok1
 moveq #0,d3
.ok1:
 neg.b d3
 neg.b d4
 
 move.b d4,16(a0)
 move.b d3,(a0)+ 

 dbra d0,ADDBRIGHTS

 rts

**********************************************

TWEENBRIGHTS:

 moveq #0,d0
.backinto:
 cmp.b #-128,(a0,d0.w)
 bne.s .okbr
 addq #1,d0
 bra.s .backinto

.okbr:

 move.b d0,d7 ;starting pos
 move.b d0,d1 ;previous pos

; tween to next value
.findnext
 addq #1,d0
 and.w #15,d0
 cmp.b #-128,(a0,d0.w)
 beq.s .findnext

 moveq #0,d2
 moveq #0,d3
 move.b (a0,d1.w),d2
 move.b (a0,d0.w),d3
 sub.w d2,d3
 
 move.w d0,d4
 sub.w d1,d4
 bgt.s .okpos
 add.w #16,d4
.okpos:

 swap d2
 swap d3
 ext.l d4
 divs.l d4,d3

 subq #1,d4 ; number of tweens

.putintween
 swap d2
 move.b d2,(a0,d1.w)
 swap d2
 add.l d3,d2
 addq #1,d1
 and.w #15,d1
 dbra d4,.putintween
 
 cmp.b d0,d7
 beq.s .doneall
 
 move.w d0,d1
 bra .findnext
 
.doneall

 rts

IMINTHETOPDAD: dc.w 0

*************************************
CALCBRIGHTSINZONE:
 move.w d0,d1
 muls #20,d1
 move.l ZoneBorderPts,a1
 add.l d1,a1
 move.l #CurrentPointBrights,a0
 lea (a0,d1.l*4),a0
 
 tst.b IMINTHETOPDAD
 beq.s .notintopdad
 adda.w #4,a0
.notintopdad
 
; A0 points at the brightnesses of the zone points.
; a1 points at the border points of the zone.
; list is terminated with -1.

 move.l Points,a3

 move.w thisxpos,oldx
 move.w thiszpos,oldz
 move.w #10,speed
 move.w #0,Range
 
DOPTBR
 move.w (a1)+,d0	;pt number
 blt DONEPTBR
 
 move.w (a3,d0.w*4),newx
 move.w 2(a3,d0.w*4),newz

 movem.l d0-d7/a0-a6,-(a7)
 jsr HeadTowardsAng
 movem.l (a7)+,d0-d7/a0-a6
 
 move.w AngRet,d1
 neg.w d1
 and.w #8191,d1
 asr.w #8,d1
 asr.w #1,d1
 
 move.w (a0),d0
 bge.s .okpos
 add.w #332,d0
 asr.w #2,d0
 neg.w d0
 add.w #332,d0
 
.okpos
 sub.w #300,d0
 bge.s .okpos3
 move.w #0,d0
.okpos3:
 move.b d0,d2
 asr.b #1,d2
 add.b d2,d0
 move.b d0,(a2,d1.w)
 move.w 2(a0),d0
 bge.s .okpos2
 add.w #332,d0
 asr.w #2,d0
 neg.w d0
 add.w #332,d0
.okpos2
 sub.w #300,d0
 bge.s .okpos4
 move.w #0,d0
.okpos4:
 
 move.b d0,d2
 asr.b #1,d2
 add.b d2,d0
 move.b d0,16(a2,d1.w)
 adda.w #8,a0

 bra DOPTBR
DONEPTBR
 rts

thisxpos: dc.w 0
thiszpos: dc.w 0
FACINGANG: dc.w 0

ANGLEBRIGHTS: ds.l 8*2

Brights:
 dc.w 3
 dc.w 8,9,10,11,12
 dc.w 15,16,17,18,19
 dc.w 21,22,23,24,25,26,27
 dc.w 29,30,31,32,33
 dc.w 36,37,38,39,40
 dc.w 45

Brights2:
 dc.w 3
 dc.w 12,11,10,9,8
 dc.w 19,18,17,16,15
 dc.w 27,26,25,24,23,22,21
 dc.w 33,32,31,30,29
 dc.w 40,39,38,37,36
 dc.w 45


PALS:
 ds.l 2*49

willy:
 dc.w 0,0,0,0,0,0,0
 dc.w 5,5,5,5,5,5,5
 dc.w 10,10,10,10,10,10,10
 dc.w 15,15,15,15,15,15,15
 dc.w 20,20,20,20,20,20,20
 dc.w 25,25,25,25,25,25,25
 dc.w 30,30,30,30,30,30,30

willybright:
 dc.w 30,30,30,30,30,30,30
 dc.w 30,20,20,20,20,20,30
 dc.w 30,20,6,3,6,20,30
 dc.w 30,20,6,0,6,20,30
 dc.w 30,20,6,6,6,20,30
 dc.w 30,20,20,20,20,20,30
 dc.w 30,30,30,30,30,30,30

xzangs:
 dc.w 0,23,10,20,16,16,20,10
 dc.w 23,0,20,-10,16,-16,10,-20
 dc.w 0,-23,-10,-20,-16,-16,-20,-10
 dc.w -23,0,-20,10,-16,16,-10,20

guff:
 incbin "ab3:includes/guff"

midx: dc.w 0
objpixwidth: dc.w 0
tmptst: dc.l 0
toppt: dc.l 0
doneit: dc.w 0
replaceend: dc.w 0
saveend: dc.w 0
midobj: dc.l 0
obadd: dc.l 0 
DOWN_STRIP: dc.w 0
WAD_PTR: dc.l 0
PTR_PTR: dc.l 0

PolyAngPtr: dc.l 0
PointAngPtr: dc.l 0

 ds.w 100
objintocop:
 incbin "ab3:includes/XTOCOPX"
 ds.w 100

   *********************************
***************************************
   ********************************* 
tstddd: dc.l 0 
 
polybehind:
 rts
 
SORTIT: dc.w 0
 
objbright:
 dc.w 0
ObjAng: dc.w 0
 
POLYMIDDLEY: dc.w 0
OBJONOFF: dc.l 0
 
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

 move.w Facing(a0),ObjAng

 move.w MIDDLEY,POLYMIDDLEY

 move.w (a0)+,d0
 move.l ObjectPoints,a4
 
 move.w (a4,d0.w*8),thisxpos
 move.w 4(a4,d0.w*8),thiszpos

 move.w 2(a1,d0.w*8),d1	; zpos of mid
 blt polybehind
 bgt.s .okinfront
 
 move.l a0,a3
 sub.l PLR1_Obj,a3
 cmp.l #130,a3
 bne polybehind
 
 move.w #1,d1
 move.w #80,POLYMIDDLEY
 tst.b FULLSCR
 beq.s .okinfront
 move.w #120,POLYMIDDLEY
.okinfront:
 
 movem.l d0-d7/a0-a6,-(a7)
 
 jsr CALCBRIGHTRINGS
 
 move.l #ANGLEBRIGHTS,a0
 move.l #PointAndPolyBrights,a1
 move.w #15,d7
 move.w #8,d6
MYacross:
 moveq #0,d3
 moveq #0,d4
 
 move.b 16(a0,d6.w),d4
 bge.s .okp2
 moveq #0,d4
.okp2

 move.b (a0,d6.w),d3
 bge.s .okp1
 moveq #0,d3
.okp1

 sub.w d3,d4
 swap d3
 swap d4
 divs.l #8,d4
 moveq #7,d2
 moveq #3*16,d5
.down:
 swap d3
 move.b d3,(a1,d5.w)
 swap d3
 add.w #16,d5
 add.l d4,d3
 dbra d2,.down
 
TOPPART:
 
 moveq #0,d3
 moveq #0,d4
 
 bchg #3,d6
 
 move.b (a0,d6.w),d4
 bge.s .okp2
 moveq #0,d4
.okp2

 bchg #3,d6
 
 move.b (a0,d6.w),d3
 bge.s .okp1
 moveq #0,d3
.okp1

 sub.w d3,d4
 swap d3
 swap d4
 divs.l #8,d4
 asr.l #1,d4	; halfway
 moveq #3,d2
 moveq #3*16,d5
.down:
 swap d3
 move.b d3,(a1,d5.w)
 swap d3
 sub.w #16,d5
 add.l d4,d3
 dbra d2,.down

BOTPART:

 moveq #0,d3
 moveq #0,d4
 
 bchg #3,d6
 
 move.b 16(a0,d6.w),d4
 bge.s .okp2
 moveq #0,d4
.okp2

 bchg #3,d6
 
 move.b 16(a0,d6.w),d3
 bge.s .okp1
 moveq #0,d3
.okp1

 sub.w d3,d4
 swap d3
 swap d4
 divs.l #8,d4
 asr.l #1,d4	; halfway
 moveq #3,d2
 move.w #11*16,d5
.down:
 swap d3
 move.b d3,(a1,d5.w)
 swap d3
 add.w #16,d5
 add.l d4,d3
 dbra d2,.down
 
 
 subq #1,d6
 and.w #$f,d6
 addq #1,a1
 dbra d7,MYacross
 
 movem.l (a7)+,d0-d7/a0-a6
 

 move.w (a0),d2
 move.w d1,d3
 asr.w #7,d3
 add.w d3,d2
 move.w d2,objbright

 move.w topclip,d2
 move.w botclip,d3
 
 asr.w #1,d2
 asr.w #1,d3
 
; move.w #10,d2
; move.w #70,d3
 
; move.w #10,leftclipb
; move.w #85,rightclipb
 
 move.w d2,objclipt
 move.w d3,objclipb

; dont use d1 here.

 move.w 6(a0),d5
 move.l #POLYOBJECTS,a3
 move.l (a3,d5.w*4),a3

 move.w (a3)+,SORTIT

 move.l a3,START_OF_OBJ
 
*******************************************************************
***************************************************************
*****************************************************************

 move.w (a3)+,num_points
 move.w (a3)+,d6	; num_frames
 
 
 move.l a3,POINTER_TO_POINTERS
 lea (a3,d6.w*4),a3

 move.l a3,LinesPtr

 moveq #0,d5
 move.w 8(a0),d5

************************************************
* Just for charles (animate automatically)
; add.w #1,d5
; cmp.w d6,d5
; blt.s okless
; moveq #0,d5
;okless:
; move.w d5,8(a0)
************************************************ 
 
 moveq #0,d2
 move.l POINTER_TO_POINTERS,a4
 move.w (a4,d5.w*4),d2
 add.l START_OF_OBJ,d2
 move.l d2,PtsPtr
 move.w 2(a4,d5.w*4),d5
 add.l START_OF_OBJ,d5
 move.l d5,PolyAngPtr
 move.l d2,a3
 move.w num_points,d5

 move.l (a3)+,OBJONOFF

 move.l a3,PointAngPtr
 move.w d5,d2
 moveq #0,d3
 lsr.w #1,d2
 addx.w d3,d2
 add.w d2,d2
 add.w d2,a3
 subq #1,d5

 move.l #boxrot,a4
 
 move.w ObjAng,d2
 sub.w #2048,d2
 sub.w angpos,d2
 and.w #8191,d2
 move.l #SineTable,a2
 lea (a2,d2.w),a5
 move.l #boxbrights,a6
 	
 move.w (a5),d6
 move.w 2048(a5),d7
 		
rotobj:
 move.w (a3),d2	; xpt
 move.w 2(a3),d3	; ypt
 move.w 4(a3),d4	; zpt
 
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
 
 muls d7,d4
 muls d6,d2
 sub.l d4,d2
 asr.l #8,d2
 asr.l #2,d2
 move.l d2,(a4)+
 ext.l d3
 asl.l #5,d3
 move.l d3,(a4)+
 move.w (a3),d2
 move.w 4(a3),d4
 muls d6,d4
 muls d7,d2
 add.l d2,d4
; add.l d4,d4
 swap d4
 move.w d4,(a4)+

 addq #6,a3
 dbra d5,rotobj
 
 

 move.l 4(a1,d0.w*8),d0	; xpos of mid

 move.w num_points,d7
 move.l #boxrot,a2
 move.l #boxonscr,a3
 move.l #boxbrights,a6
 move.w 2(a0),d2
 subq #1,d7
 
 tst.b FULLSCR
 beq.s smallconv

 move.w d1,d3
 asl.w #1,d1
 add.w d3,d1

 ext.l d2
 asl.l #7,d2
 sub.l yoff,d2
 asl.l #1,d2
.convtoscr
 move.l (a2),d3
 add.l d0,d3
 move.l d3,(a2)+
 move.l (a2),d4
 add.l d2,d4
 move.l d4,(a2)+
 move.w (a2),d5
 add.w d1,d5
 ble .ptbehind
 move.w d5,(a2)+
 add.w d5,d5
 
 move.l d3,d6
 add.l d6,d6
 add.l d6,d3
 move.l d4,d6
 add.l d6,d6
 add.l d6,d4
 
 divs d5,d3
 divs d5,d4
 add.w MIDDLEX,d3
 add.w d4,d4
 add.w POLYMIDDLEY,d4
 asr.w #1,d4
 move.w d3,(a3)+
 move.w d4,(a3)+
 
 dbra d7,.convtoscr
 bra DONECONV

.ptbehind:
 move.w d5,(a2)+
 move.w #32767,(a3)+
 move.w #32767,(a3)+
 dbra d7,.convtoscr
 bra DONECONV
 
smallconv:
 
; asl.w #1,d1
 ext.l d2
 asl.l #7,d2
 sub.l yoff,d2
; asl.l #1,d2 
.convtoscr
 move.l (a2),d3
 add.l d0,d3
 move.l d3,(a2)+
 move.l (a2),d4
 add.l d2,d4
 move.l d4,(a2)+
 move.w (a2),d5
 add.w d1,d5
 ble .ptbehind2
 move.w d5,(a2)+
 divs d5,d3
 divs d5,d4
 add.w d3,d3
 add.w MIDDLEX,d3
 asr.w #1,d3
 add.w d4,d4
 add.w POLYMIDDLEY,d4
 asr.w #1,d4
 move.w d3,(a3)+
 move.w d4,(a3)+

 dbra d7,.convtoscr

 bra DONECONV

.ptbehind2:
 move.w d5,(a2)+
 move.w #32767,(a3)+
 move.w #32767,(a3)+
 dbra d7,.convtoscr

DONECONV

**************************
 move.w num_points,d7
 
 move.l #boxbrights,a6
 subq #1,d7
 move.l PointAngPtr,a0
 move.l #PointAndPolyBrights,a2
 move.w ObjAng,d2
 asr.w #8,d2
 asr.w #1,d2
 st d5
 
calcpointangbrights:

 moveq #0,d0
 move.b (a0)+,d0
 move.b d0,d3
 add.w d2,d3
 and.w #$f,d3
 and.w #$f0,d0
 add.w d3,d0
 
 moveq #0,d1
 move.b (a2,d0.w),d1
 bge.s .okpos
 moveq #0,d1
.okpos:

 cmp.w #31,d1
 ble.s .oksmall
 move.w #31,d1
.oksmall:
 
 move.w d1,(a6)+

 dbra d7,calcpointangbrights

*************************



 move.l LinesPtr,a1
 
; Now need to sort parts of object
; into order.

 move.l #PartBuffer,a0
 move.l a0,a2
 move.w #63,d0
clrpartbuff:

 move.l #$80000001,(a2)
 addq #4,a2

 dbra d0,clrpartbuff
 
 move.l #boxrot,a2

 move.l OBJONOFF,d5
 
 tst.w SORTIT
 bne.s PutinParts

 
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
 move.w d7,(a0)
 addq #4,a0
 
 bra putinunsorted
 
 
PutinParts
 move.w (a1)+,d7
 blt doneallparts

 lsr.l #1,d5
 bcs.s .yeson
 addq #2,a1
 bra PutinParts
.yeson:

 move.w (a1)+,d6
 move.l (a2,d6.w),d0
 asr.l #7,d0
 muls d0,d0
 move.l 4(a2,d6.w),d2
 asr.l #7,d2
 muls d2,d2
 add.l d2,d0 
 move.w 8(a2,d6.w),d2
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

 bra PutinParts

doneallparts:

 move.l #PartBuffer,a0

Partloop:
 move.l (a0)+,d7
 blt nomoreparts

 moveq #0,d0
 move.w (a0),d0
 addq #4,a0
 add.l START_OF_OBJ,d0
 move.l d0,a1
 move.w #0,firstpt

polyloo:

 tst.w (a1)
 blt.s nomorepolys
 movem.l a0/a1/d7,-(a7)
 bsr doapoly
 movem.l (a7)+,a0/a1/d7
 
 move.w (a1),d0
 lea 18(a1,d0.w*4),a1
 
 bra.s polyloo
nomorepolys
 
 bra Partloop

nomoreparts:
 rts
 
firstpt: dc.w 0

PartBuffer:
 ds.w 4*32
endparttab:

polybright: dc.l 0
PolyAng: dc.w 0

doapoly:
 
 move.w #960,Left
 move.w #-10,Right
 
 move.w (a1)+,d7	; lines to draw 
 move.w (a1)+,preholes
 move.w 12(a1,d7.w*4),pregour
 move.l #boxonscr,a3

 movem.l d0-d7/a0-a6,-(a7)
* Check for any of these points behind...

checkbeh:
 move.w (a1),d0
 
 cmp.w #32767,(a3,d0.w*4)
 bne.s .notbeh
 cmp.w #32767,2(a3,d0.w*4)
 bne.s .notbeh
 
 movem.l (a7)+,d0-d7/a0-a6
 bra polybehind
 
.notbeh:
 
 addq #4,a1
 dbra d7,checkbeh


 movem.l (a7)+,d0-d7/a0-a6


 move.w (a1),d0
 move.w 4(a1),d1
 move.w 8(a1),d2
 move.w 2(a3,d0.w*4),d3
 move.w 2(a3,d1.w*4),d4
 move.w 2(a3,d2.w*4),d5
 move.w (a3,d0.w*4),d0
 move.w (a3,d1.w*4),d1
 move.w (a3,d2.w*4),d2

 sub.w d1,d0	;x1
 sub.w d1,d2	;x2
 sub.w d4,d3	;y1
 sub.w d4,d5	;y2

 muls d3,d2
 muls d5,d0
 sub.l d0,d2
 ble polybehind
 
 move.l #boxrot,a3
 move.w (a1),d0
 move.w d0,d1
 asl.w #2,d0
 add.w d1,d0
 move.w 4(a1),d1
 move.l d1,d2
 asl.w #2,d1
 add.w d2,d1
 move.w 8(a1),d2
 move.w d2,d3
 asl.w #2,d2
 add.w d3,d2
 move.l 4(a3,d0.w*2),d3
 move.l 4(a3,d1.w*2),d4
 move.l 4(a3,d2.w*2),d5
 move.l (a3,d0.w*2),d0
 move.l (a3,d1.w*2),d1
 move.l (a3,d2.w*2),d2

 sub.l d1,d0	;x1
 sub.l d1,d2	;x2
 sub.l d4,d3	;y1
 sub.l d4,d5	;y2

 asr.l #7,d0
 asr.l #7,d2
 asr.l #7,d3
 asr.l #7,d5

 muls d3,d2
 muls d5,d0
 sub.l d0,d2
 
 move.l d2,polybright
 move.l #boxonscr,a3

 clr.b drawit

 tst.b Gouraud(pc)
 bne.s usegour
 bsr putinlines
 bra.s dontusegour
usegour:
 bsr putingourlines
dontusegour:

 move.w #104*4,linedir
 move.l frompt,a6

 tst.b drawit(pc)
 beq polybehind

 move.l #PolyTopTab,a4
 move.w Left(pc),d1
 move.w Right(pc),d7

 move.w leftclipb,d3
 move.w rightclipb,d4
 cmp.w d3,d7
 ble polybehind
 cmp.w d4,d1
 bge polybehind
 cmp.w d3,d1
 bge .notop
 move.w d3,d1
.notop
 cmp.w d4,d7
 ble .nobot
 move.w d4,d7
.nobot

 add.w d1,d1 
 lea (a4,d1.w*8),a4
 asr.w #1,d1
 sub.w d1,d7
 ble polybehind
; move.w d1,a2
 move.l #objintocop,a2
 lea (a2,d1.w*2),a2
 moveq #0,d0
 
 move.l TextureMaps,a0
 move.w (a1)+,d0
 ifeq CHEESEY
 bge.s .notsec
 and.w #$7fff,d0
 add.l #65536,a0
.notsec
 endc
 
 ifne CHEESEY
 
 bge.s .notsec
 and.w #$7fff,d0
 add.w #%0000010000000000,d0

.notsec:
 
 moveq #0,d1
 move.w d0,d1   ; 00000XXX 000000YY
 lsr.w #6,d0
 add.w d0,d1	; 00000XXX 000XXXYY
 and.b #%111,d1 ; 00000XXX 00000XYY
 add.b d1,d1	; 00000XXX 0000XYY0
 lsl.w #4,d1	; 0XXX0000 XYY00000
 and.w #%0110000011100000,d1
 move.w d1,d0

 endc
 
 add.w d0,a0
 moveq #0,d0
 moveq #0,d1
 move.b (a1)+,d1

 asl.w #5,d1
 ext.l d1
 divs #100,d1
 neg.w d1
 add.w #31,d1

 
 tst.b Holes
 bne gotholesin
 tst.b Gouraud(pc)
 bne gotlurvelyshading

 move.w ObjAng,d4
 asr.w #8,d4
 asr.w #1,d4
 
 moveq #0,d2
 moveq #0,d3
 move.b (a1)+,d2 
 move.l PolyAngPtr,a1
 move.b (a1,d2.w),d2
 
 move.b d2,d3
 add.w d4,d3
 and.w #$f,d3
 and.w #$f0,d2
 add.b d3,d2
 
 move.l #PointAndPolyBrights,a1
 moveq #0,d5
 move.b (a1,d2.w),d5
 
 add.w d5,d1

 
 move.l #objscalecols,a1
; move.w objbright(pc),d0
; add.w d0,d1
 tst.w d1
 bge.s toobright
 move.w #0,d1
toobright:
 cmp.w #31,d1
 blt.s .toodark
 moveq #31,d1
.toodark:

 asl.w #8,d1
; move.w (a1,d1.w*2),d1
; asl.w #3,d1
 move.l TexturePal,a1
 lea (a1,d1.w*2),a1
 tst.b pregour
 bne predoglare
 
dopoly:

 move.w #0,offtopby
 move.l a6,a3
 adda.w (a2)+,a3
; addq #1,a2
 move.w (a4),d1
 cmp.w objclipb,d1
 bge nodl
 move.w PolyBotTab-PolyTopTab(a4),d2
 cmp.w objclipt,d2
 ble nodl
 cmp.w objclipt,d1
 bge.s nocl
 move.w objclipt,d3
 sub.w d1,d3
 move.w d3,offtopby
 move.w objclipt,d1
nocl: 
 move.w d2,d0
 cmp.w objclipb,d2
 ble.s nocr
 move.w objclipb,d2
nocr:

	; d1=top end
	; d2=bot end
	
 move.l 2+PolyBotTab-PolyTopTab(a4),d3
 move.l 6+PolyBotTab-PolyTopTab(a4),d4
	
 move.l 2(a4),d5
 move.l 6(a4),d6
 
 sub.l d5,d3
 sub.l d6,d4
 
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
 
 
 sub.w d1,d2
 ble nodl

 move.w #0,tstdca
 sub.w d1,d0
 tst.w offtopby
 beq.s .notofftop
 move.l d3,-(a7)
 move.l d4,-(a7)
 add.w offtopby,d0
 ext.l d0	
 muls.l offtopby-2,d3
 muls.l offtopby-2,d4
 divs.l d0,d3
 divs.l d0,d4

 add.l d3,d5
 add.l d4,d6

 move.l (a7)+,d4
 move.l (a7)+,d3
.notofftop: 
 ext.l d0

 divs.l d0,d3
 divs.l d0,d4

 add.l ontoscr(pc,d1.w*4),a3


 ifeq CHEESEY
 move.l #$3fffff,d1
 endc
 ifne CHEESEY
 move.l #$1fffff,d1
 endc
 
 move.l d3,a5
 moveq #0,d3
 subq #1,d2
drawpol:
 and.l d1,d5
 and.l d1,d6

 move.l d6,d0
 asr.l #8,d0
 swap d5
 move.b d5,d0
 
 ifeq CHEESEY
 move.b (a0,d0.w*4),d3
 endc
 ifne CHEESEY
 move.b (a0,d0.w),d3
 endc
 
 swap d5
 add.l a5,d5
 add.l d4,d6
 
 
 move.w (a1,d3.w*2),(a3)
 adda.w #104*4,a3
 dbra d2,drawpol

; add.w a5,d3
; addx.l d6,d5
; dbcs d2,drawpol2
; dbcc d2,drawpol
; bra.s pastit
;drawpol2:
; and.w d1,d5
; move.b (a0,d5.w*4),d0
; move.w (a1,d0.w*2),(a3)
; adda.w #320,a3
; add.w a5,d3
; addx.l d4,d5
; dbcs d2,drawpol2
; dbcc d2,drawpol

pastit:

nodl:
 adda.w #16,a4
 dbra d7,dopoly

 rts
 
ontoscr:
val SET 0
 REPT 256
 dc.l val
val SET val+104*4
 ENDR

predoglare:
 move.l #SHADINGTABLE-512,a1

DOGLAREPOLY:

 move.w #0,offtopby
 move.l a6,a3
 adda.w (a2)+,a3
; addq #1,a2
 move.w (a4),d1
 cmp.w objclipb,d1
 bge nodlGL
 move.w PolyBotTab-PolyTopTab(a4),d2
 cmp.w objclipt,d2
 ble nodlGL
 cmp.w objclipt,d1
 bge.s noclGL
 move.w objclipt,d3
 sub.w d1,d3
 move.w d3,offtopby
 move.w objclipt,d1
noclGL:
 move.w d2,d0
 cmp.w objclipb,d2
 ble.s nocrGL
 move.w objclipb,d2
nocrGL:

	; d1=top end
	; d2=bot end
	
 move.l 2+PolyBotTab-PolyTopTab(a4),d3
 move.l 6+PolyBotTab-PolyTopTab(a4),d4
	
 move.l 2(a4),d5
 move.l 6(a4),d6
 
 sub.l d5,d3
 sub.l d6,d4
 
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
 
 
 sub.w d1,d2
 ble nodlGL

 move.w #0,tstdca
 sub.w d1,d0
 tst.w offtopby
 beq.s .notofftop
 move.l d3,-(a7)
 move.l d4,-(a7)
 add.w offtopby,d0
 ext.l d0	
 muls.l offtopby-2,d3
 muls.l offtopby-2,d4
 divs.l d0,d3
 divs.l d0,d4

 add.l d3,d5
 add.l d4,d6

 move.l (a7)+,d4
 move.l (a7)+,d3
.notofftop: 
 ext.l d0

 divs.l d0,d3
 divs.l d0,d4

 add.l ontoscrGL(pc,d1.w*4),a3

 ifeq CHEESEY
 move.l #$3fffff,d1
 endc
 ifne CHEESEY
 move.l #$1fffff,d1
 endc
 
 move.l d3,a5
 moveq #0,d3
 subq #1,d2
drawpolGL:
 and.l d1,d5
 and.l d1,d6

 move.l d6,d0
 asr.l #8,d0
 swap d5
 move.b d5,d0
 
 ifeq CHEESEY
 move.b (a0,d0.w*4),d3
 endc
 ifne CHEESEY
 move.b (a0,d0.w),d3
 endc
 beq.s itsblack
 
 lsl.w #8,d3
 move.b (a3),d3

 swap d5
 add.l a5,d5
 add.l d4,d6
 
 move.w (a1,d3.w*2),(a3)
 adda.w #104*4,a3
 dbra d2,drawpolGL

nodlGL:
 adda.w #16,a4
 dbra d7,DOGLAREPOLY

 rts

itsblack:
 swap d5
 add.l a5,d5
 add.l d4,d6 
 adda.w #104*4,a3
 dbra d2,drawpolGL
 adda.w #16,a4
 dbra d7,DOGLAREPOLY

 rts

ontoscrGL:
val SET 0
 REPT 256
 dc.l val
val SET val+104*4
 ENDR
 
tstdca: dc.l 0
 dc.w 0
offtopby: dc.w 0
LinesPtr: dc.l 0
PtsPtr: dc.l 0

gotlurvelyshading:
 move.l TexturePal,a1
 tst.b pregour
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
 move.l d7,-(a7)
 move.w #0,offtopby
 move.l a6,a3
 adda.w (a2)+,a3
; addq #1,a2
 move.w (a4),d1
 cmp.w objclipb,d1
 bge nodlg
 move.w PolyBotTab-PolyTopTab(a4),d2
 cmp.w objclipt(pc),d2
 ble nodlg
 cmp.w objclipt(pc),d1
 bge.s noclg
 move.w objclipt,d3
 sub.w d1,d3
 move.w d3,offtopby
 move.w objclipt(pc),d1
noclg: 
 move.w d2,d0
 cmp.w objclipb(pc),d2
 ble.s nocrg
 move.w objclipb(pc),d2
nocrg:

	; d1=top end
	; d2=bot end
	
 move.l 2+PolyBotTab-PolyTopTab(a4),d3
 move.l 6+PolyBotTab-PolyTopTab(a4),d4
	
 move.l 2(a4),d5
 move.l 6(a4),d6
 
 sub.l d5,d3
 sub.l d6,d4
 
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
 

 sub.w d1,d2
 ble nodlg

 move.w #0,tstdca
 sub.w d1,d0
 tst.w offtopby
 beq.s .notofftop
 move.l d3,-(a7)
 move.l d4,-(a7)
 add.w offtopby,d0
 ext.l d0
 muls.l offtopby-2,d3
 muls.l offtopby-2,d4
 divs.l d0,d3
 divs.l d0,d4
 
 add.l d3,d5
 add.l d4,d6
 
 move.l (a7)+,d4
 move.l (a7)+,d3
.notofftop
 ext.l d0

 divs.l d0,d3
 divs.l d0,d4

 add.l ontoscrg(pc,d1.w*4),a3
 move.w 10+PolyBotTab-PolyTopTab(a4),d1
 move.w 10(a4),d7
 sub.w d7,d1
 asl.w #8,d7
 swap d1
 clr.w d1
 divs.l d0,d1
 
 asr.l #8,d1
 
 move.l d3,a5
 moveq #0,d3
 
 swap d2
 move.w d1,d2
 swap d2

 ifeq CHEESEY
 move.l #$3fffff,d1
 endc
 ifne CHEESEY
 move.l #$1fffff,d1
 endc
 
 
 subq.w #1,d2
drawpolg:
 and.l d1,d5
 and.l d1,d6

 move.l d6,d0
 asr.l #8,d0
 swap d5
 move.b d5,d0
 
 move.w d7,d3
 
 ifeq CHEESEY
 move.b (a0,d0.w*4),d3
 endc
 ifne CHEESEY
 move.b (a0,d0.w),d3
 endc
 
 swap d2
 swap d5
 add.l a5,d5
 add.l d4,d6
 add.w d2,d7
 swap d2
 move.w (a1,d3.w*2),(a3)
 adda.w #104*4,a3
 dbra d2,drawpolg
 
nodlg:

 move.l (a7)+,d7
 adda.w #16,a4
 dbra d7,dopolyg

 rts

ontoscrg:
val SET 0
 REPT 256
 dc.l val
val SET val+104*4
 ENDR
 
 


gotholesin:
 move.w ObjAng,d4
 asr.w #8,d4
 asr.w #1,d4
 
 moveq #0,d2
 moveq #0,d3
 move.b (a1)+,d2
 
 move.l PolyAngPtr,a1
 move.b (a1,d2.w),d2
 
 move.b d2,d3
 lsr.b #4,d3	;d3=vertical pos
 add.b d4,d2
 and.w #$f,d2
 
 move.l #ANGLEBRIGHTS,a1
 moveq #0,d4
 moveq #0,d5
 move.b (a1,d2.w),d4	;top
 move.b 16(a1,d2.w),d5  ;bottom
 
 sub.w d4,d5
 muls d3,d5
 divs #14,d5
 add.w d4,d5
 
 add.w d5,d1


 move.l #objscalecols,a1

; move.w objbright(pc),d0
; add.w d0,d1
 tst.w d1
 bge.s toobrighth
 move.w #0,d1
toobrighth:
 cmp.w #31,d1
 ble.s toodimh
 move.w #31,d1
toodimh:

 asl.w #8,d1

; move.w (a1,d1.w*2),d1
; asl.w #3,d1
 move.l TexturePal,a1
 lea (a1,d1.w*2),a1
 tst.b pregour
; beq.s .noshiny
; add.l #256*32,a1
;.noshiny:

dopolyh:
 move.w #0,offtopby
 move.l a6,a3
 adda.w (a2)+,a3
; addq #1,a2
 move.w (a4),d1
 cmp.w objclipb,d1
 bge nodlh
 move.w PolyBotTab-PolyTopTab(a4),d2
 cmp.w objclipt,d2
 ble nodlh
 cmp.w objclipt,d1
 bge.s noclh
 move.w objclipt,d3
 sub.w d1,d3
 move.w d3,offtopby
 move.w objclipt,d1
noclh: 
 move.w d2,d0
 cmp.w objclipb,d2
 ble.s nocrh
 move.w objclipb,d2
nocrh:

	; d1=top end
	; d2=bot end
	
 move.l 2+PolyBotTab-PolyTopTab(a4),d3
 move.l 6+PolyBotTab-PolyTopTab(a4),d4
	
 move.l 2(a4),d5
 move.l 6(a4),d6
 
 sub.l d5,d3
 sub.l d6,d4
 
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
 
 
 sub.w d1,d2
 ble nodlh

 move.w #0,tstdca
 sub.w d1,d0
 tst.w offtopby
 beq.s .notofftop
 move.l d3,-(a7)
 move.l d4,-(a7)
 add.w offtopby,d0
 ext.l d0
 muls.l offtopby-2,d3
 muls.l offtopby-2,d4
 divs.l d0,d3
 divs.l d0,d4
 
 add.l d3,d5
 add.l d4,d6
 
 move.l (a7)+,d4
 move.l (a7)+,d3
.notofftop:
 ext.l d0
 
 divs.l d0,d3
 divs.l d0,d4
 
 add.l ontoscrh(pc,d1.w*4),a3
 ifeq CHEESEY
 move.l #$3fffff,d1
 endc
 ifne CHEESEY
 move.l #$1fffff,d1
 endc

 move.l d3,a5
 moveq #0,d3
 subq #1,d2
drawpolh:
 and.l d1,d5
 and.l d1,d6
 
 move.l d6,d0
 asr.l #8,d0
 swap d5
 move.b d5,d0
 
 swap d5
 add.l a5,d5
 add.l d4,d6
 
 ifeq CHEESEY
 move.b (a0,d0.w*4),d3
 endc
 ifne CHEESEY
 move.b (a0,d0.w),d3
 endc
 
 beq.s .dontplot
 move.w (a1,d3.w*2),(a3)
.dontplot
 adda.w #104*4,a3
 dbra d2,drawpolh

pastith:

nodlh:
 adda.w #16,a4
 dbra d7,dopolyh

 rts

ontoscrh:
val SET 0
 REPT 256
 dc.l val
val SET val+104*4
 ENDR

 EVEN
pregour:
 dc.b 0
Gouraud:
 dc.b 0
preholes:
 dc.b 0
Holes: 
 dc.b 0

putinlines:

 move.w (a1),d0
 move.w 4(a1),d1

 move.w (a3,d0.w*4),d2
 move.w 2(a3,d0.w*4),d3
 move.w (a3,d1.w*4),d4
 move.w 2(a3,d1.w*4),d5
 
; d2=x1 d3=y1 d4=x2 d5=y2
 
 cmp.w d2,d4
 beq thislineflat
 bgt thislineontop
 move.l #PolyBotTab,a4
 exg d2,d4
 exg d3,d5
 
 cmp.w rightclipb,d2
 bge thislineflat
 cmp.w leftclipb,d4
 ble thislineflat
 move.w rightclipb,d6
 sub.w d4,d6
 ble.s .clipr
 move.w #0,-(a7)
 cmp.w Right(pc),d4
 ble.s .nonewbot
 move.w d4,Right
 bra.s .nonewbot
 
.clipr
 move.w d6,-(a7)
 move.w rightclipb,Right
 sub.w #1,Right
.nonewbot:
 
 move.w #0,offleftby
 move.w d2,d6
 cmp.w leftclipb,d6
 bge .okt
 move.w leftclipb,d6
 sub.w d2,d6
 move.w d6,offleftby
 add.w d2,d6
.okt:
 
 st drawit
 add.w d6,d6
 lea (a4,d6.w*8),a4
 asr.w #1,d6
 cmp.w Left(pc),d6
 bge.s .nonewtop
 move.w d6,Left
.nonewtop

 sub.w d3,d5	; dy
 swap d3
 clr.w d3	; d2=xpos
 sub.w d2,d4	; dx > 0
 ext.l d4
 swap d5
 clr.w d5
 divs.l d4,d5
 moveq #0,d2
 move.b 2(a1),d2
 ifne CHEESEY
 asr.w #1,d2
 endc
 
 moveq #0,d6
 move.b 6(a1),d6
 ifne CHEESEY
 asr.w #1,d6
 endc
 sub.w d6,d2
 swap d2
 swap d6
 clr.w d2
 clr.w d6	; d6=xbitpos
 divs.l d4,d2
 move.l d5,a5	; a5=dy constant
 move.l d2,a6	; a6=xbitconst

 moveq #0,d5
 move.b 3(a1),d5
 ifne CHEESEY
 asr.w #1,d5
 endc
 moveq #0,d2
 move.b 7(a1),d2
 ifne CHEESEY
 asr.w #1,d2
 endc
 sub.w d2,d5
 swap d2
 swap d5
 clr.w d2	; d3=ybitpos
 clr.w d5
 divs.l d4,d5

 add.w (a7)+,d4
 sub.w offleftby(pc),d4
 blt thislineflat

 tst.w offleftby(pc)
 beq.s .noneoffleft
 move.w d4,-(a7)
 move.w offleftby(pc),d4
 dbra d4,.calcnodraw
 bra .nodrawoffleft
.calcnodraw

 add.l a5,d3
 add.l a6,d6
 add.l d5,d2
 dbra d4,.calcnodraw
.nodrawoffleft:
 move.w (a7)+,d4
.noneoffleft:

.putinline:

 swap d3
 move.w d3,(a4)+
 swap d3
 move.l d6,(a4)+
 move.l d2,(a4)+
 addq #6,a4

 add.l a5,d3
 add.l a6,d6
 add.l d5,d2

 dbra d4,.putinline

 bra thislineflat
 
thislineontop:
 move.l #PolyTopTab,a4
 
 cmp.w rightclipb,d2
 bge thislineflat
 cmp.w leftclipb,d4
 ble thislineflat
 move.w rightclipb,d6
 sub.w d4,d6
 ble.s .clipr
 move.w #0,-(a7)
 cmp.w Right(pc),d4
 ble.s .nonewbot
 move.w d4,Right
 bra.s .nonewbot
 
.clipr
 move.w d6,-(a7)
 move.w rightclipb,Right
 sub.w #1,Right
.nonewbot:

 move.w #0,offleftby
 move.w d2,d6
 cmp.w leftclipb,d6
 bge .okt
 move.w leftclipb,d6
 sub.w d2,d6
 move.w d6,offleftby
 add.w d2,d6
.okt:

 st drawit
 add.w d6,d6
 lea (a4,d6.w*8),a4
 asr.w #1,d6
 cmp.w Left(pc),d6
 bge.s .nonewtop
 move.w d6,Left
.nonewtop
 
 sub.w d3,d5	; dy
 swap d3
 clr.w d3	; d2=xpos
 sub.w d2,d4	; dx > 0
 ext.l d4
 swap d5
 clr.w d5
 divs.l d4,d5
 moveq #0,d2
 move.b 6(a1),d2
 ifne CHEESEY
 asr.w #1,d2
 endc
 moveq #0,d6
 move.b 2(a1),d6
 ifne CHEESEY
 asr.w #1,d6
 endc
 sub.w d6,d2
 swap d2
 swap d6
 clr.w d2
 clr.w d6	; d6=xbitpos
 divs.l d4,d2
 move.l d5,a5	; a5=dy constant
 move.l d2,a6	; a6=xbitconst

 moveq #0,d5
 move.b 7(a1),d5
 ifne CHEESEY
 asr.w #1,d5
 endc
 moveq #0,d2
 move.b 3(a1),d2
 ifne CHEESEY
 asr.w #1,d2
 endc
 sub.w d2,d5
 swap d2
 swap d5
 clr.w d2	; d3=ybitpos
 clr.w d5
 divs.l d4,d5

 add.w (a7)+,d4
 sub.w offleftby(pc),d4
 blt.s thislineflat

 tst.w offleftby(pc)
 beq.s .noneoffleft
 move.w d4,-(a7)
 move.w offleftby(pc),d4
 dbra d4,.calcnodraw
 bra .nodrawoffleft
.calcnodraw

 add.l a5,d3
 add.l a6,d6
 add.l d5,d2
 dbra d4,.calcnodraw
.nodrawoffleft:
 move.w (a7)+,d4
.noneoffleft:


.putinline:

 swap d3
 move.w d3,(a4)+
 swap d3
 move.l d6,(a4)+
 move.l d2,(a4)+
 addq #6,a4

 add.l a5,d3
 add.l a6,d6
 add.l d5,d2

 dbra d4,.putinline

thislineflat:
 addq #4,a1
 dbra d7,putinlines
 addq #4,a1
 rts

putingourlines:

 move.l #boxbrights,a2

piglloop:

 move.w (a1),d0
 move.w 4(a1),d1

 move.w (a3,d0.w*4),d2
 move.w 2(a3,d0.w*4),d3
 move.w (a3,d1.w*4),d4
 move.w 2(a3,d1.w*4),d5
 
 
 
 cmp.w d2,d4
 beq thislineflatgour
 bgt thislineontopgour
 move.l #PolyBotTab,a4
 exg d2,d4
 exg d3,d5
 
 cmp.w rightclipb,d2
 bge thislineflatgour
 cmp.w leftclipb,d4
 ble thislineflatgour
 move.w rightclipb,d6
 sub.w d4,d6
 ble.s .clipr
 move.w #0,-(a7)
 cmp.w Right(pc),d4
 ble.s .nonewbot
 move.w d4,Right
 bra.s .nonewbot
 
.clipr
 move.w d6,-(a7)
 move.w rightclipb,Right
 sub.w #1,Right
.nonewbot:

 move.w #0,offleftby
 move.w d2,d6
 cmp.w leftclipb,d6
 bge .okt
 move.w leftclipb,d6
 sub.w d2,d6
 move.w d6,offleftby
 add.w d2,d6
.okt:
 
 st drawit
 add.w d6,d6
 lea (a4,d6.w*8),a4
 asr.w #1,d6
 cmp.w Left(pc),d6
 bge.s .nonewtop
 move.w d6,Left
.nonewtop

 sub.w d3,d5	; dy
 swap d3
 clr.w d3	; d2=xpos
 sub.w d2,d4	; dx > 0
 ext.l d4
 swap d5
 clr.w d5
 divs.l d4,d5
 moveq #0,d2
 move.b 2(a1),d2
 ifne CHEESEY
 asr.w #1,d2
 endc
 moveq #0,d6
 move.b 6(a1),d6
 ifne CHEESEY
 asr.w #1,d6
 endc
 sub.w d6,d2
 swap d2
 swap d6
 clr.w d2
 clr.w d6	; d6=xbitpos
 divs.l d4,d2
 move.l d5,a5	; a5=dy constant
 move.l d2,a6	; a6=xbitconst

 moveq #0,d5
 move.b 3(a1),d5
 ifne CHEESEY
 asr.w #1,d5
 endc
 moveq #0,d2
 move.b 7(a1),d2
 ifne CHEESEY
 asr.w #1,d2
 endc
 
 sub.w d2,d5
 swap d2
 swap d5
 clr.w d2	; d3=ybitpos
 clr.w d5
 divs.l d4,d5

 move.w (a2,d1.w*2),d1
 move.w (a2,d0.w*2),d0
 sub.w d1,d0
 swap d0
 swap d1
 clr.w d0
 clr.w d1
 divs.l d4,d0

 add.w (a7)+,d4
 sub.w offleftby(pc),d4
 blt thislineflatgour

 tst.w offleftby(pc)
 beq.s .noneoffleft
 move.w d4,-(a7)
 move.w offleftby(pc),d4
 dbra d4,.calcnodraw
 bra .nodrawoffleft
.calcnodraw
 add.l d0,d1
 add.l a5,d3
 add.l a6,d6
 add.l d5,d2
 dbra d4,.calcnodraw
.nodrawoffleft:
 move.w (a7)+,d4
.noneoffleft:

.putinline:

 swap d3
 move.w d3,(a4)+
 swap d3
 move.l d6,(a4)+
 move.l d2,(a4)+
 swap d1
 move.w d1,(a4)
 addq #6,a4
 swap d1

 add.l d0,d1
 add.l a5,d3
 add.l a6,d6
 add.l d5,d2

 dbra d4,.putinline

 bra thislineflatgour
 
thislineontopgour:
 move.l #PolyTopTab,a4
 
 cmp.w rightclipb,d2
 bge thislineflatgour
 cmp.w leftclipb,d4
 ble thislineflatgour
 move.w rightclipb,d6
 sub.w d4,d6
 ble.s .clipr
 move.w #0,-(a7)
 cmp.w Right(pc),d4
 ble.s .nonewbot
 move.w d4,Right
 bra.s .nonewbot
 
.clipr
 move.w d6,-(a7)
 move.w rightclipb,Right
 sub.w #1,Right
.nonewbot:
 
 move.w #0,offleftby
 move.w d2,d6
 cmp.w leftclipb,d6
 bge .okt
 move.w leftclipb,d6
 sub.w d2,d6
 move.w d6,offleftby
 add.w d2,d6
.okt:

 st drawit
 add.w d6,d6
 lea (a4,d6.w*8),a4
 asr.w #1,d6
 cmp.w Left(pc),d6
 bge.s .nonewtop
 move.w d6,Left
.nonewtop
 
 sub.w d3,d5	; dy
 swap d3
 clr.w d3	; d2=xpos
 sub.w d2,d4	; dx > 0
 ext.l d4
 swap d5
 clr.w d5
 divs.l d4,d5
 moveq #0,d2
 move.b 6(a1),d2
 ifne CHEESEY
 asr.w #1,d2
 endc
 moveq #0,d6
 move.b 2(a1),d6
 ifne CHEESEY
 asr.w #1,d6
 endc
 sub.w d6,d2
 swap d2
 swap d6
 clr.w d2
 clr.w d6	; d6=xbitpos
 divs.l d4,d2
 move.l d5,a5	; a5=dy constant
 move.l d2,a6	; a6=xbitconst

 moveq #0,d5
 move.b 7(a1),d5
 ifne CHEESEY
 asr.w #1,d5
 endc
 moveq #0,d2
 move.b 3(a1),d2
 ifne CHEESEY
 asr.w #1,d2
 endc

 sub.w d2,d5
 swap d2
 swap d5
 clr.w d2	; d3=ybitpos
 clr.w d5
 divs.l d4,d5

 move.w (a2,d1.w*2),d1
 move.w (a2,d0.w*2),d0
 sub.w d0,d1
 swap d0
 swap d1
 clr.w d0
 clr.w d1
 divs.l d4,d1

 add.w (a7)+,d4
 sub.w offleftby(pc),d4
 blt.s thislineflatgour

 tst.w offleftby(pc)
 beq.s .noneoffleft
 move.w d4,-(a7)
 move.w offleftby(pc),d4
 dbra d4,.calcnodraw
 bra .nodrawoffleft
.calcnodraw
 add.l d1,d0
 add.l a5,d3
 add.l a6,d6
 add.l d5,d2
 dbra d4,.calcnodraw
.nodrawoffleft:
 move.w (a7)+,d4
.noneoffleft:


.putinline:

 swap d3
 move.w d3,(a4)+
 swap d3
 move.l d6,(a4)+
 move.l d2,(a4)+
 swap d0
 move.w d0,(a4)
 addq #6,a4
 swap d0
 
 add.l d1,d0
 add.l a5,d3
 add.l a6,d6
 add.l d5,d2

 dbra d4,.putinline

thislineflatgour:
 addq #4,a1
 dbra d7,piglloop
 addq #4,a1
 rts

offleftby: dc.w 0
Left: dc.w 0
Right: dc.w 0
 
PointAndPolyBrights:
 ds.l 4*16
 
 
POINTER_TO_POINTERS: dc.l 0
START_OF_OBJ: dc.l 0
num_points: dc.w 0
 
POLYOBJECTS:
 ds.l 40
; dc.l Spider_des
; dc.l Medi_des
; dc.l Exit_des
; dc.l Crate_des
; dc.l Terminal_des
; dc.l Blue_des
; dc.l Green_des
; dc.l Red_des
; dc.l Yellow_des
; dc.l Gas_des
; dc.l Torch_des
 
Spider_des:
; incbin "ab3:vectobj/robot"
 incbin "ab3:vectobj/walllamp"

;Medi_des:
; incbin "ab3:vectobj/testgrill"
;Exit_des:
; incbin "ab3:vectobj/exitsign
;Crate_des:
; incbin "ab3:vectobj/droid"
;Terminal_des:
; incbin "ab3:includes/terminal.vec"
;Blue_des:
; incbin "ab3:vectobj/blueind"
;Green_des:
; incbin "ab3:vectobj/Greenind"
;Red_des:
; incbin "ab3:vectobj/Redind"
;Yellow_des:
; incbin "ab3:vectobj/yellowind"
;Gas_des:
; incbin "ab3:vectobj/gaspipe"
;Torch_des:
; incbin "ab3:vectobj/torch"

boxonscr:
 ds.l 250*2
boxrot: ds.l 3*250

boxbrights: 
	ds.w 250

boxang: dc.w 0 
 
 ds.w 320*4
PolyBotTab: ds.w 320*8
 ds.w 320*4
PolyTopTab: ds.w 320*8
 ds.w 320*4

offset:
 dc.w 0
timer:
 dc.w 0
 
Objects:
; Lookup table for OBJECT GRAPHIC TYPE
; in object data (offset 8)
;0
 dc.l ALIEN_WAD,ALIEN_PTR,ALIEN_FRAMES,ALIEN_PAL
;1
 dc.l PICKUPS_WAD,PICKUPS_PTR,PICKUPS_FRAMES,PICKUPS_PAL
;2
 dc.l BIGBULLET_WAD,BIGBULLET_PTR,BIGBULLET_FRAMES,BIGBULLET_PAL
;3
 dc.l UGLYMONSTER_WAD,UGLYMONSTER_PTR,UGLYMONSTER_FRAMES,UGLYMONSTER_PAL
;4
 dc.l FLYINGMONSTER_WAD,FLYINGMONSTER_PTR,FLYINGMONSTER_FRAMES,FLYINGMONSTER_PAL
;5
 dc.l KEYS_WAD,KEYS_PTR,KEYS_FRAMES,KEYS_PAL
;6
 dc.l ROCKETS_WAD,ROCKETS_PTR,ROCKETS_FRAMES,ROCKETS_PAL
;7
 dc.l BARREL_WAD,BARREL_PTR,BARREL_FRAMES,BARREL_PAL
;8
 dc.l BIGBULLET_WAD,BIGBULLET_PTR,EXPLOSION_FRAMES,EXPLOSION_PAL
;9
 dc.l GUNS_WAD,GUNS_PTR,GUNS_FRAMES,GUNS_PAL
;10:
 dc.l MARINE_WAD,MARINE_PTR,MARINE_FRAMES,MARINE_PAL
;11:
 dc.l BIGALIEN_WAD,BIGALIEN_PTR,BIGALIEN_FRAMES,BIGALIEN_PAL
;12:
 dc.l 0,0,LAMPS_FRAMES,LAMPS_PAL
;13:
 dc.l 0,0,WORM_FRAMES,WORM_PAL
;14:
 dc.l 0,0,BIGCLAWS_FRAMES,BIGCLAWS_PAL
;15:
 dc.l 0,0,TREE_FRAMES,TREE_PAL
;16:
 dc.l 0,0,TOUGHMARINE_FRAMES,TOUGHMARINE_PAL
;17:
 dc.l 0,0,FLAMEMARINE_FRAMES,FLAMEMARINE_PAL
;18:
 dc.l 0,0,GLARE_FRAMES,0
 ds.l 4*20

GLARE_FRAMES:
 dc.w 0,0
 dc.w 32*4,0
 dc.w 32*4*2,0
 dc.w 32*4*3,0
 
 dc.w 0,32
 dc.w 32*4,32
 dc.w 32*4*2,32
 dc.w 32*4*3,32

ALIEN_WAD:
; incbin "ALIEN2.wad"
ALIEN_PTR:
; incbin "ALIEN2.ptr"
ALIEN_FRAMES:
; walking=0-3
 dc.w 0,0
 dc.w 64*4,0 
 dc.w 64*4*2,0
 dc.w 64*4*3,0
 dc.w 64*4*4,0
 dc.w 64*4*5,0
 dc.w 64*4*6,0
 dc.w 64*4*7,0
 dc.w 64*4*8,0
 dc.w 64*4*9,0
 dc.w 64*4*10,0
 dc.w 64*4*11,0
 dc.w 64*4*12,0
 dc.w 64*4*13,0
 dc.w 64*4*14,0
 dc.w 64*4*15,0
;Exploding=16-31
 dc.w 4*(64*16),0
 dc.w 4*(64*16+16),0
 dc.w 4*(64*16+32),0
 dc.w 4*(64*16+48),0
 
 dc.w 4*(64*16),16
 dc.w 4*(64*16+16),16
 dc.w 4*(64*16+32),16
 dc.w 4*(64*16+48),16
 
 dc.w 4*(64*16),32
 dc.w 4*(64*16+16),32
 dc.w 4*(64*16+32),32
 dc.w 4*(64*16+48),32
 
 dc.w 4*(64*16),48
 dc.w 4*(64*16+16),48
 dc.w 4*(64*16+32),48
 dc.w 4*(64*16+48),48
;dying=32-33
 dc.w 64*4*17,0
 dc.w 64*4*18,0

 
ALIEN_PAL:
; incbin "alien2.256pal"

PICKUPS_WAD:
; incbin "Pickups.wad"
PICKUPS_PTR:
; incbin "PICKUPS.ptr"
PICKUPS_FRAMES:
; medikit=0
 dc.w 0,0
; big gun=1
 dc.w 0,32
; bullet=2
 dc.w 64*4,32
; Ammo=3
 dc.w 32*4,0 
;battery=4
 dc.w 64*4,0
;Rockets=5
 dc.w 192*4,0
;gunpop=6-16
 dc.w 128*4,0
 dc.w (128+16)*4,0
 dc.w (128+32)*4,0
 dc.w (128+48)*4,0
 dc.w 128*4,16
 dc.w (128+16)*4,16
 dc.w (128+32)*4,16
 dc.w (128+48)*4,16
 dc.w 128*4,32
 dc.w (128+16)*4,32
 dc.w (128+32)*4,32
 dc.w (64+16)*4,32
 dc.w (64*4),48
 dc.w (64+16)*4,48

; RocketLauncher=20
 dc.w (64+32)*4,0
 
;grenade = 21-24
 dc.w 64*4,32
 dc.w (64+16)*4,32
 dc.w (64+16)*4,48
 dc.w 64*4,48

; shotgun = 25
 dc.w 128*4,32

; grenade launcher =26
 dc.w 256*4,0

; shotgun shells*4=27
 dc.w 64*3*4,32
; shotgun shells*20=28
 dc.w (64*3+32)*4,0
; grenade clip=29
 dc.w (64*3+32)*4,32
 
 
PICKUPS_PAL:
; incbin "PICKUPS.256pal"

BIGBULLET_WAD:
; incbin "bigbullet.wad"
BIGBULLET_PTR:
; incbin "bigbullet.ptr"
BIGBULLET_FRAMES:
 dc.w 0,0
 dc.w 0,32
 dc.w 32*4,0
 dc.w 32*4,32
 dc.w 64*4,0
 dc.w 64*4,32
 dc.w 96*4,0
 dc.w 96*4,32
 
 dc.w 128*4,0
 dc.w 128*4,32
 dc.w 32*5*4,0
 dc.w 32*5*4,32
 dc.w 32*6*4,0
 dc.w 32*6*4,32
 dc.w 32*7*4,0
 dc.w 32*7*4,32
 dc.w 32*8*4,0
 dc.w 32*8*4,32
 dc.w 32*9*4,0
 dc.w 32*9*4,32
BIGBULLET_PAL
; incbin "bigbullet.256pal"

EXPLOSION_FRAMES:
 dc.w 0,0
 dc.w 64*4,0
 dc.w 64*4*2,0
 dc.w 64*4*3,0
 dc.w 64*4*4,0
 dc.w 64*4*5,0
 dc.w 64*4*6,0
 dc.w 64*4*7,0
 dc.w 64*4*8,0

EXPLOSION_PAL
; incbin "explosion.256pal"

UGLYMONSTER_WAD:
; incbin "uglymonster.wad"
UGLYMONSTER_PTR:
; incbin "uglymonster.ptr"
UGLYMONSTER_FRAMES:
 dc.w 0,0
UGLYMONSTER_PAL:
; incbin "uglymonster.pal"
 
FLYINGMONSTER_WAD:
; incbin "FLYINGalien.wad"
FLYINGMONSTER_PTR:
; incbin "FLYINGalien.ptr"
FLYINGMONSTER_FRAMES:
 dc.w 0,0
 dc.w 64*4,0 
 dc.w 64*4*2,0 
 dc.w 64*4*3,0 
 dc.w 64*4*4,0 
 dc.w 64*4*5,0 
 dc.w 64*4*6,0 
 dc.w 64*4*7,0 
 dc.w 64*4*8,0 
 dc.w 64*4*9,0 
 dc.w 64*4*10,0 
 dc.w 64*4*11,0 
 dc.w 64*4*12,0 
 dc.w 64*4*13,0 
 dc.w 64*4*14,0 
 dc.w 64*4*15,0 
 dc.w 64*4*16,0 
 dc.w 64*4*17,0 
 dc.w 64*4*18,0 
 dc.w 64*4*19,0 
 dc.w 64*4*20,0 
 
FLYINGMONSTER_PAL:
; incbin "FLYINGalien.256pal"

KEYS_WAD:
; incbin "keys.wad"
KEYS_PTR:
; incbin "KEYS.PTR"
KEYS_FRAMES:
 dc.w 0,0
 dc.w 0,32
 dc.w 32*4,0
 dc.w 32*4,32
KEYS_PAL:
; incbin "keys.256pal"

ROCKETS_WAD:
; incbin "ROCKETS.wad"
ROCKETS_PTR:
; incbin "ROCKETS.ptr"
ROCKETS_FRAMES:
;rockets=0 to 3
 dc.w 0,0
 dc.w 32*4,0
 dc.w 0,32
 dc.w 32*4,32

;Green bullets = 4 to 7
 dc.w 64*4,0
 dc.w (64+32)*4,0
 dc.w 64*4,32
 dc.w (64+32)*4,32

;Blue Bullets = 8 to 11
 dc.w 128*4,0
 dc.w (128+32)*4,0
 dc.w 128*4,32
 dc.w (128+32)*4,32
 
 
ROCKETS_PAL:
; incbin "ROCKETS.256pal"
 
BARREL_WAD:
; incbin "BARREL.wad"
BARREL_PTR:
; incbin "BARREL.ptr"
BARREL_FRAMES:
 dc.w 0,0
 
BARREL_PAL: 
;incbin "BARREL.256pal"
 
GUNS_WAD:
; incbin "guns.wad"
GUNS_PTR:
; incbin "GUNS.PTR"
GUNS_FRAMES:

 dc.w 96*4*20,0
 dc.w 96*4*21,0
 dc.w 96*4*22,0
 dc.w 96*4*23,0
 
 dc.w 96*4*4,0
 dc.w 96*4*5,0
 dc.w 96*4*6,0
 dc.w 96*4*7,0

 dc.w 96*4*16,0
 dc.w 96*4*17,0
 dc.w 96*4*18,0
 dc.w 96*4*19,0

 dc.w 96*4*12,0
 dc.w 96*4*13,0
 dc.w 96*4*14,0
 dc.w 96*4*15,0
 
 dc.w 96*4*24,0
 dc.w 96*4*25,0
 dc.w 96*4*26,0
 dc.w 96*4*27,0

 dc.w 0,0
 dc.w 0,0
 dc.w 0,0
 dc.w 0,0

 dc.w 0,0
 dc.w 0,0
 dc.w 0,0
 dc.w 0,0

 dc.w 96*4*0,0
 dc.w 96*4*1,0
 dc.w 96*4*2,0
 dc.w 96*4*3,0 

GUNS_PAL:
; incbin "newgunsinhand.256pal"
 
MARINE_WAD:
; incbin "newMarine.wad"
MARINE_PTR:
; incbin "newMARINE.ptr"
MARINE_FRAMES:
 dc.w 0,0
 dc.w 64*4,0
 dc.w (64*2)*4,0
 dc.w (64*3)*4,0
 dc.w (64*4)*4,0
 dc.w (64*5)*4,0
 dc.w (64*6)*4,0
 dc.w (64*7)*4,0
 dc.w (64*8)*4,0
 dc.w (64*9)*4,0
 dc.w (64*10)*4,0
 dc.w (64*11)*4,0
 dc.w (64*12)*4,0
 dc.w (64*13)*4,0
 dc.w (64*14)*4,0
 dc.w (64*15)*4,0
 dc.w (64*16)*4,0
 dc.w (64*17)*4,0
 dc.w (64*18)*4,0
MARINE_PAL:
; incbin "newmarine.256pal"
TOUGHMARINE_FRAMES:
 dc.w 0,0
 dc.w 64*4,0
 dc.w (64*2)*4,0
 dc.w (64*3)*4,0
 dc.w (64*4)*4,0
 dc.w (64*5)*4,0
 dc.w (64*6)*4,0
 dc.w (64*7)*4,0
 dc.w (64*8)*4,0
 dc.w (64*9)*4,0
 dc.w (64*10)*4,0
 dc.w (64*11)*4,0
 dc.w (64*12)*4,0
 dc.w (64*13)*4,0
 dc.w (64*14)*4,0
 dc.w (64*15)*4,0
 dc.w (64*16)*4,0
 dc.w (64*17)*4,0
 dc.w (64*18)*4,0
TOUGHMARINE_PAL:
; incbin "toughmutant.256pal"
FLAMEMARINE_FRAMES:
 dc.w 0,0
 dc.w 64*4,0
 dc.w (64*2)*4,0
 dc.w (64*3)*4,0
 dc.w (64*4)*4,0
 dc.w (64*5)*4,0
 dc.w (64*6)*4,0
 dc.w (64*7)*4,0
 dc.w (64*8)*4,0
 dc.w (64*9)*4,0
 dc.w (64*10)*4,0
 dc.w (64*11)*4,0
 dc.w (64*12)*4,0
 dc.w (64*13)*4,0
 dc.w (64*14)*4,0
 dc.w (64*15)*4,0
 dc.w (64*16)*4,0
 dc.w (64*17)*4,0
 dc.w (64*18)*4,0
FLAMEMARINE_PAL:
; incbin "flamemutant.256pal"


BIGALIEN_WAD:
; incbin "BIGSCARYALIEN.wad"
BIGALIEN_PTR:
; incbin "BIGSCARYALIEN.ptr"
BIGALIEN_FRAMES:
; walking=0-3
 dc.w 0,0
 dc.w 128*4,0
 dc.w 128*4*2,0
 dc.w 128*4*3,0
BIGALIEN_PAL:
; incbin "BIGSCARYALIEN.256pal"

LAMPS_FRAMES:
 dc.w 0,0
LAMPS_PAL:
; incbin "LAMPS.256pal"
 
WORM_FRAMES:
 dc.w 0,0
 dc.w 90*4,0
 dc.w 90*4*2,0
 dc.w 90*4*3,0
 dc.w 90*4*4,0
 dc.w 90*4*5,0
 dc.w 90*4*6,0
 dc.w 90*4*7,0
 dc.w 90*4*8,0
 dc.w 90*4*9,0
 dc.w 90*4*10,0
 dc.w 90*4*11,0
 dc.w 90*4*12,0
 dc.w 90*4*13,0
 dc.w 90*4*14,0
 dc.w 90*4*15,0
 dc.w 90*4*16,0
 dc.w 90*4*17,0
 dc.w 90*4*18,0
 dc.w 90*4*19,0
 dc.w 90*4*20,0
WORM_PAL:
; incbin "worm.256pal"
 
BIGCLAWS_FRAMES:
 dc.w 0,0
 dc.w 128*4,0
 dc.w 128*4*2,0
 dc.w 128*4*3,0
 dc.w 128*4*4,0
 dc.w 128*4*5,0
 dc.w 128*4*6,0
 dc.w 128*4*7,0
 dc.w 128*4*8,0
 dc.w 128*4*9,0
 dc.w 128*4*10,0
 dc.w 128*4*11,0
 dc.w 128*4*12,0
 dc.w 128*4*13,0
 dc.w 128*4*14,0
 dc.w 128*4*15,0
 dc.w 128*4*16,0
 dc.w 128*4*17,0
BIGCLAWS_PAL:
; incbin "bigclaws.256pal"
 
TREE_FRAMES:
 dc.w 0,0
 dc.w 64*4,0
 dc.w 64*2*4,0
 dc.w 64*3*4,0

 dc.w 0,0
 dc.w 64*4,0
 dc.w 64*2*4,0
 dc.w 64*3*4,0


 dc.w 0,0
 dc.w 64*4,0
 dc.w 64*2*4,0
 dc.w 64*3*4,0


 dc.w 0,0
 dc.w 64*4,0
 dc.w 64*2*4,0
 dc.w 64*3*4,0
 
 dc.w 0,0
 dc.w 0,0
 
 dc.w 32*8*4,0
 dc.w 32*9*4,0
 dc.w 32*10*4,0
 dc.w 32*11*4,0
 
TREE_PAL:
; incbin "tree.256pal"

 
 even
ObAdds:
; incbin "ALIEN1.ptr"
objpal:
; incbin "ALIEN1.256pal"
TextureMaps:
 dc.l 0
; incbin "ab3:includes/newTexturemaps"
TexturePal:
 dc.l 0
; incbin "ab3:includes/texture256pal"
 
testval: dc.l 0