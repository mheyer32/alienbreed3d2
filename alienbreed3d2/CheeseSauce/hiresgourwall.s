
*********************************** 
 
* The screendivide routine is simpler
* using a0=left pixel
* a2= right pixel
* d0= left dist
* d2= right dist
* d4 = left strip
* d5 = right strip

* (a0)=leftx
* 2(a0)=rightx

* 4(a0)=leftbm
* 6(a0)=rightbm

* 8(a0)=leftdist
* 10(a0)=rightdist

* 12(a0)=lefttop
* 14(a0)=righttop

* 16(a0)=leftbot
* 18(a0)=rightbot


DoleftendGOUR:

 move.w leftclip,d0
 sub.w #1,d0
 move.w d0,leftclipandlast


 move.w (a0),d0
 move.w 2(a0),d1
 sub.w d0,d1
 bge.s sometodrawG
 rts
sometodrawG:
 move.w itertabG(pc,d1.w*4),d7
 swap d0
 move.w itertabG+2(pc,d1.w*4),d6
 clr.w d0
 swap d1
 clr.w d1
 asr.l d6,d1
 move.l d1,(a0)

 bra pstitG

itertabG:
 incbin "ab3:includes/iterfile"

pstitG:

 moveq #0,d1
 move.w 4(a0),d1
 moveq #0,d2
 move.w 6(a0),d2
 sub.w d1,d2
 swap d1
 swap d2
 asr.l d6,d2
 move.l d2,4(a0)
 
 moveq #0,d2
 move.w 8(a0),d2
 moveq #0,d3
 move.w 10(a0),d3
 sub.w d2,d3
 swap d2
 swap d3
 asr.l d6,d3
 move.l d3,8(a0)

 moveq #0,d3
 move.w 12(a0),d3
 moveq #0,d4
 move.w 14(a0),d4
 sub.w d3,d4
 swap d3
 swap d4
 asr.l d6,d4
 move.l d4,12(a0)
 
 moveq #0,d4
 move.w 16(a0),d4
 moveq #0,d5
 move.w 18(a0),d5
 sub.w d4,d5
 swap d4
 swap d5
 asr.l d6,d5
 move.l d5,16(a0)
 
 
*** Gouraud shading ***
 moveq #0,d5
 move.w 26(a0),d5
 sub.w 24(a0),d5
 add.w d5,d5
 swap d5
 asr.l d6,d5
 move.l d5,28(a0)
 moveq #0,d5
 move.w 24(a0),d5
 add.w d5,d5
 swap d5
 move.l d5,24(a0)

*** Extra Gouraud Shading ***

 moveq #0,d5
 move.w 34(a0),d5
 sub.w 32(a0),d5
 add.w d5,d5
 swap d5
 asr.l d6,d5
 move.l d5,36(a0)
 moveq #0,d5
 move.w 32(a0),d5
 add.w d5,d5
 swap d5
 move.l d5,32(a0)

 bra screendivideGOUR

TOPBRCOUNT: dc.l 0
BOTBRCOUNT: dc.l 0

screendivideGOUR:

 or.l #$ffff0000,d7
 move.w leftclipandlast(pc),d6
 move.l #WorkSpace,a2

 move.l (a0),a3
 move.l 4(a0),a4
 move.l 8(a0),a5
 move.l 12(a0),a6
 move.l 16(a0),a1
 
 
scrdivlopG:

 swap d0
 cmp.w d6,d0
 bgt scrnotoffleftG
 swap d0
 add.l a4,d1
 add.l a5,d2
 add.l a6,d3
 add.l a1,d4
 add.l a3,d0
 move.l 28(a0),d5
 add.l d5,24(a0)
 move.l 36(a0),d5
 add.l d5,32(a0)
 
 dbra d7,scrdivlopG
 rts
 
scrnotoffleftG:

 move.w d0,d6

 cmp.w rightclip(pc),d0
 bge.s outofcalcG
 
scrnotoffrightG:

 
 move.w d0,(a2)+
 move.l d1,(a2)+
 move.l d2,(a2)+
 move.l d3,(a2)+
 move.l d4,(a2)+
 move.l 24(a0),(a2)+
 move.l 32(a0),(a2)+
 swap d0
 add.l a3,d0
 add.l a4,d1
 add.l a5,d2
 add.l a6,d3
 add.l a1,d4
 move.l 28(a0),d5
 add.l d5,24(a0)
 move.l 36(a0),d5
 add.l d5,32(a0)
 add.l #$10000,d7
 dbra d7,scrdivlopG
 
outofcalcG:
 swap d7
 tst.w d7
 bge.s .somethingtodraw
 rts
.somethingtodraw:

 move.l #consttab,a1
 move.l #WorkSpace,a0

; tst.b seethru
; bne screendividethru

 tst.b FULLSCR
 bne scrdrawlopGB

 tst.b DOUBLEWIDTH
 bne scrdrawlopGDOUB

scrdrawlopG:

 move.w (a0)+,d0
 move.l FASTBUFFER,a3
 lea (a3,d0.w),a3
 move.l (a0)+,d1
 
; bra pastscrinto
;
; 
;pastscrinto 

 swap d1

 move.w d1,d6
 and.w HORAND,d6
 move.l (a0)+,d2
 swap d2
 add.w fromtile(pc),d6
 add.w d6,d6
 move.w d6,a5
 move.l (a0)+,d3
 swap d3
 add.l #divthreetab,a5
 move.w (a5),StripData

 move.l ChunkAddr,a5
 moveq #0,d6
 move.b StripData,d6
 add.w d6,d6
 move.w VALSHIFT,d4
 asl.l d4,d6
 add.l d6,a5
 move.l (a0)+,d4
 swap d4
 addq #1,d4
 move.w d2,d6
***************************
* old version
 asr.w #7,d6
***************************
; asr.w #3,d6
; sub.w #4,d6
; cmp.w #6,d6
; blt.s tstbrbr
; move.w #6,d6
;tstbrbr:
***************************
 move.l (a0)+,d5
 swap d5
 move.w d7,-(a7)
 ext.w d5
 move.w d6,d7
 add.w d5,d7
 bge.s .brnotneg
 moveq #0,d7
.brnotneg
 cmp.w #62,d7
 blt.s .brnotpos
 move.w #62,d7
.brnotpos

 move.l (a0)+,d5
 swap d5
 ext.w d5
 add.w d5,d6
 bge.s .brnotneg2
 moveq #0,d6
.brnotneg2
 cmp.w #62,d6
 blt.s .brnotpos2
 move.w #62,d6
.brnotpos2

 asr.w #1,d6
 asr.w #1,d7
 sub.w d6,d7

 move.l PaletteAddr,a4
; move.l a2,a4
; add.w ffscrpickhowbright(pc,d6*2),a2
; and.b #$fe,d6
; add.w ffscrpickhowbright(pc,d6*2),a4

; btst #0,d0
; beq .nobrightswap
; exg a2,a4
;.nobrightswap:

 bsr ScreenWallstripdrawGOUR
 move.w (a7)+,d7
 
toosmallG:
 
 dbra d7,scrdrawlopG
 
 rts

itsoddy:
 add.w #4+4+4+4+4+4,a0
 dbra d7,scrdrawlopGDOUB
 rts

scrdrawlopGDOUB:

 move.w (a0)+,d0
 btst #0,d0
 bne.s itsoddy
 move.l FASTBUFFER,a3
 lea (a3,d0.w),a3
 move.l (a0)+,d1
 
; bra pastscrinto
;
; 
;pastscrinto 

 swap d1

 move.w d1,d6
 and.w HORAND,d6
 move.l (a0)+,d2
 swap d2
 add.w fromtile(pc),d6
 add.w d6,d6
 move.w d6,a5
 move.l (a0)+,d3
 swap d3
 add.l #divthreetab,a5
 move.w (a5),StripData

 move.l ChunkAddr,a5
 moveq #0,d6
 move.b StripData,d6
 add.w d6,d6
 move.w VALSHIFT,d4
 asl.l d4,d6
 add.l d6,a5
 move.l (a0)+,d4
 swap d4
 addq #1,d4
 move.w d2,d6
***************************
* old version
 asr.w #7,d6
***************************
; asr.w #3,d6
; sub.w #4,d6
; cmp.w #6,d6
; blt.s tstbrbr
; move.w #6,d6
;tstbrbr:
***************************
 move.l (a0)+,d5
 swap d5
 move.w d7,-(a7)
 ext.w d5
 move.w d6,d7
 add.w d5,d7
 bge.s .brnotneg
 moveq #0,d7
.brnotneg
 cmp.w #62,d7
 blt.s .brnotpos
 move.w #62,d7
.brnotpos

 move.l (a0)+,d5
 swap d5
 ext.w d5
 add.w d5,d6
 bge.s .brnotneg2
 moveq #0,d6
.brnotneg2
 cmp.w #62,d6
 blt.s .brnotpos2
 move.w #62,d6
.brnotpos2

 asr.w #1,d6
 asr.w #1,d7
 sub.w d6,d7

 move.l PaletteAddr,a4
; move.l a2,a4
; add.w ffscrpickhowbright(pc,d6*2),a2
; and.b #$fe,d6
; add.w ffscrpickhowbright(pc,d6*2),a4

; btst #0,d0
; beq .nobrightswap
; exg a2,a4
;.nobrightswap:

 bsr ScreenWallstripdrawGOUR
 move.w (a7)+,d7
 
 dbra d7,scrdrawlopGDOUB
 
 rts


scrdrawlopGB:

 move.w (a0)+,d0
 move.l FASTBUFFER,a3
 lea (a3,d0.w),a3
 move.l (a0)+,d1
 
; bra pastscrinto
;
; 
;pastscrinto 

 swap d1

 move.w d1,d6
 and.w HORAND,d6
 move.l (a0)+,d2
 swap d2
 add.w fromtile(pc),d6
 add.w d6,d6
 move.w d6,a5
 move.l (a0)+,d3
 swap d3
 add.l #divthreetab,a5
 move.w (a5),StripData

 move.l ChunkAddr,a5
 moveq #0,d6
 move.b StripData,d6
 add.w d6,d6
 move.w VALSHIFT,d4
 asl.l d4,d6
 add.l d6,a5
 move.l (a0)+,d4
 swap d4
 addq #1,d4
 move.w d2,d6
***************************
* old version
 asr.w #7,d6
***************************
; asr.w #3,d6
; sub.w #4,d6
; cmp.w #6,d6
; blt.s tstbrbr
; move.w #6,d6
;tstbrbr:
***************************
 move.l (a0)+,d5
 swap d5
 move.w d7,-(a7)
 ext.w d5
 move.w d6,d7
 add.w d5,d7
 bge.s .brnotneg
 moveq #0,d7
.brnotneg
 cmp.w #62,d7
 blt.s .brnotpos
 move.w #62,d7
.brnotpos

 move.l (a0)+,d5
 swap d5
 ext.w d5
 add.w d5,d6
 bge.s .brnotneg2
 moveq #0,d6
.brnotneg2
 cmp.w #62,d6
 blt.s .brnotpos2
 move.w #62,d6
.brnotpos2

 asr.w #1,d6
 asr.w #1,d7
 sub.w d6,d7

 move.l PaletteAddr,a4
; move.l a2,a4
; add.w ffscrpickhowbright(pc,d6*2),a2
; and.b #$fe,d6
; add.w ffscrpickhowbright(pc,d6*2),a4

; btst #0,d0
; beq .nobrightswap
; exg a2,a4
;.nobrightswap:

 bsr ScreenWallstripdrawGOURB
 move.w (a7)+,d7
 
 dbra d7,scrdrawlopGB
 
 rts

itsbilloddy:
 add.w #4+4+4+4+4+4,a0
 dbra d7,scrdrawlopGDOUB
 rts

scrdrawlopGBDOUB:

 move.w (a0)+,d0
 btst #0,d0
 bne.s itsbilloddy
 move.l FASTBUFFER,a3
 lea (a3,d0.w),a3
 move.l (a0)+,d1
 
; bra pastscrinto
;
; 
;pastscrinto 

 swap d1

 move.w d1,d6
 and.w HORAND,d6
 move.l (a0)+,d2
 swap d2
 add.w fromtile(pc),d6
 add.w d6,d6
 move.w d6,a5
 move.l (a0)+,d3
 swap d3
 add.l #divthreetab,a5
 move.w (a5),StripData

 move.l ChunkAddr,a5
 moveq #0,d6
 move.b StripData,d6
 add.w d6,d6
 move.w VALSHIFT,d4
 asl.l d4,d6
 add.l d6,a5
 move.l (a0)+,d4
 swap d4
 addq #1,d4
 move.w d2,d6
***************************
* old version
 asr.w #7,d6
***************************
; asr.w #3,d6
; sub.w #4,d6
; cmp.w #6,d6
; blt.s tstbrbr
; move.w #6,d6
;tstbrbr:
***************************
 move.l (a0)+,d5
 swap d5
 move.w d7,-(a7)
 ext.w d5
 move.w d6,d7
 add.w d5,d7
 bge.s .brnotneg
 moveq #0,d7
.brnotneg
 cmp.w #62,d7
 blt.s .brnotpos
 move.w #62,d7
.brnotpos

 move.l (a0)+,d5
 swap d5
 ext.w d5
 add.w d5,d6
 bge.s .brnotneg2
 moveq #0,d6
.brnotneg2
 cmp.w #62,d6
 blt.s .brnotpos2
 move.w #62,d6
.brnotpos2

 asr.w #1,d6
 asr.w #1,d7
 sub.w d6,d7

 move.l PaletteAddr,a4
; move.l a2,a4
; add.w ffscrpickhowbright(pc,d6*2),a2
; and.b #$fe,d6
; add.w ffscrpickhowbright(pc,d6*2),a4

; btst #0,d0
; beq .nobrightswap
; exg a2,a4
;.nobrightswap:

 bsr ScreenWallstripdrawGOURB
 move.w (a7)+,d7
 
 dbra d7,scrdrawlopGBDOUB
 
 rts

walldrawGOUR:

 tst.w d1
 bgt.s oneinfront1G
 tst.w d3
 bgt.s oneinfrontG
 rts

oneinfront1G
 tst.w d3
 ble.s oneinfrontG
; Bothinfront!

 nop

oneinfrontG

 move.w #64,d7
 move.w #4,d6
 
 move.w d3,d0
 sub.w d1,d0
 bge.s notnegzdiffG
 neg.w d0
notnegzdiffG
; cmp.w #1024,d0
; blt.s nd01G
; add.w d7,d7
; add.w #1,d6
;nd01G:
 cmp.w #512,d0
 blt.s nd0G 
 add.w d7,d7
 add.w #1,d6
 bra nhaG
nd0G:

 cmp.w #256,d0
 bgt.s nh1G
 asr.w #1,d7
 subq #1,d6
nh1G:
 cmp.w #128,d0
 bgt.s nh2G
 asr.w #1,d7
 subq #1,d6
nh2G:

nhaG:

 move.w d3,d0
 cmp.w d1,d3
 blt.s rightnearestG
 move.w d1,d0
rightnearestG:
 cmp.w #64,d0
 bgt.s nd1G
 addq #1,d6
 add.w d7,d7
nd1G:

 cmp.w #128,d0
 blt.s nh3G
 asr.w #1,d7
 subq #1,d6
 blt.s nh3G
 cmp.w #256,d0
 blt.s nh3G
 asr.w #1,d7
 subq #1,d6
nh3G:
 move.w d6,iters
 subq #1,d7
 move.w d7,multcount

 move.l #databuffer,a3
 move.l a0,d0
 move.l a2,d2

 move.l d0,(a3)+
 add.l d2,d0
 move.w d1,(a3)+
 move.w leftwallTOPbright,d7
 move.w d7,(a3)+
 asr.l #1,d0
 move.w d4,(a3)+

 move.w leftwallbright,d6
 move.w d6,(a3)+
 
 add.w d5,d4
 move.l d0,(a3)+
 add.w d3,d1
 asr.w #1,d1
 move.w d1,(a3)+

 add.w rightwallTOPbright,d7
 asr.w #1,d7
 move.w d7,(a3)+

 asr.w #1,d4
 move.w d4,(a3)+
 
 add.w rightwallbright,d6
 asr.w #1,d6
 move.w d6,(a3)+
 
 
 move.l d2,(a3)+
 move.w d3,(a3)+
 move.w rightwallTOPbright,(a3)+
 move.w d5,(a3)+
 move.w rightwallbright,(a3)+
 
 ; We now have the two endpoints and the midpoint
 ; so we need to perform 1 iteration of the inner
 ; loop, the first time.
 
* Decide how often to subdivide by how far away the wall is, and
* how perp. it is to the player.

 move.l #databuffer,a0
 move.l #databuffer2,a1
 
 swap d7
 move.w iters,d7
 blt noitersG
 move.l #1,a2
 
iterloopG:
 move.l a0,a3
 move.l a1,a4
 swap d7
 move.w a2,d7
 exg a0,a1

 move.l (a3)+,d0
 move.l (a3)+,d1
 move.l (a3)+,d2
middleloopG:
 move.l d0,(a4)+
 move.l (a3)+,d3
 add.l d3,d0
 move.l d1,(a4)+
 asr.l #1,d0
 move.l (a3)+,d4
 add.l d4,d1
 move.l d2,(a4)+
 asr.l #1,d1
 and.w #$7fff,d1
 move.l (a3)+,d5
 add.l d5,d2
 move.l d0,(a4)+
 asr.l #1,d2
 move.l d1,(a4)+
 move.l d2,(a4)+
 
 move.l d3,(a4)+
 move.l (a3)+,d0
 add.l d0,d3
 
 move.l d4,(a4)+
 asr.l #1,d3
 move.l (a3)+,d1
 add.l d1,d4
 move.l d5,(a4)+
 asr.l #1,d4
 and.w #$7fff,d4
 move.l (a3)+,d2
 add.l d2,d5
 move.l d3,(a4)+
 asr.l #1,d5
 move.l d4,(a4)+
 move.l d5,(a4)+

 subq #1,d7
 bgt.s middleloopG
 move.l d0,(a4)+
 move.l d1,(a4)+
 move.l d2,(a4)+
 
 add.w a2,a2
 
 swap d7
 dbra d7,iterloopG
 
noitersG:
 
CalcAndDrawG:
 
; CACHE_ON d2
 
 move.l a0,a1
 move.w multcount,d7
.findfirstinfront:
 move.l (a1)+,d1
 move.w (a1)+,d0
 bgt.s .foundinfront
 move.l (a1)+,d4
 move.w (a1)+,d4
 dbra d7,.findfirstinfront
 rts	; no two points were in front
 
.foundinfront:
 move.w (a1)+,tlbr
 move.w (a1)+,d4
 move.w (a1)+,lbr
 ; d1=left x, d4=left end, d0=left dist 
 
 divs d0,d1
 add.w MIDDLEX,d1
 
 move.l topofwall(pc),d5
 divs d0,d5
 add.w MIDDLEY,d5
 move.w d5,strtop
 move.l botofwall(pc),d5
 divs d0,d5
 add.w MIDDLEY,d5
 move.w d5,strbot
 
.computeloop:
 move.w 4(a1),d2
 bgt.s .infront
 rts

.infront:
 move.l #store,a0
 move.l (a1),d3
 divs d2,d3
 move.w 8(a1),d5
 add.w MIDDLEX,d3
 move.w strtop(pc),12(a0)
 move.l topofwall(pc),d6
 divs d2,d6
 move.w strbot(pc),16(a0)
 add.w MIDDLEY,d6
 move.w d6,strtop
 move.w d6,14(a0)
 move.l botofwall(pc),d6
 divs d2,d6
 add.w MIDDLEY,d6
 move.w d6,strbot
 move.w d6,18(a0)
 move.w d3,2(a1)
 cmp.w leftclip(pc),d3
 blt .alloffleft
 cmp.w rightclip(pc),d1
; cmp.w #95,d1
 bge .alloffright

 movem.l d0/d1/d2/d3/a0,-(a7)

 moveq #0,d0
 move.b WALLIDENT,d0
 blt.s .noputinmap
 
 move.b d0,d3
 and.b #15,d0
 move.l COMPACTPTR,a0
 moveq #0,d1
 move.w d0,d2
 add.w d0,d0
 add.w d2,d0
 bset d0,d1
 btst #4,d3
 beq.s .nodoor
 addq #2,d0
 bset d0,d1
.nodoor:
 
 or.l d1,(a0)
 move.l BIGPTR,a0
 
 move.w wallleftpt,(a0,d2.w*4) 
 move.w wallrightpt,2(a0,d2.w*4) 

.noputinmap

 movem.l (a7)+,d0/d1/d2/d3/a0

 bra OTHERHALFG


.alloffleft:

 move.l (a1)+,d1
 move.w (a1)+,d0
 move.w (a1)+,tlbr
 move.w (a1)+,d4
 move.w (a1)+,lbr

 dbra d7,.computeloop
 rts

.alloffright:
 rts
 
computeloop2G:
 move.w 4(a1),d2
 bgt.s .infront
 rts

.infront:
 move.l #store,a0
 move.l (a1),d3
 divs d2,d3
 move.w 8(a1),d5
 add.w MIDDLEX,d3
 move.w strtop(pc),12(a0)
 move.l topofwall(pc),d6
 divs d2,d6
 move.w strbot(pc),16(a0)
 add.w MIDDLEY,d6
 move.w d6,strtop
 move.w d6,14(a0)
 move.l botofwall(pc),d6
 divs d2,d6
 add.w MIDDLEY,d6
 move.w d6,strbot
 move.w d6,18(a0)
 move.w d3,2(a1)
 cmp.w leftclip(pc),d3
 blt.s alloffleft2G
 cmp.w rightclip(pc),d1
; cmp.w #95,d1
 bge.s alloffright2G

OTHERHALFG:

 move.w d1,(a0)
 move.w d3,2(a0)
 move.w d4,4(a0)
 move.w d5,6(a0)
 move.w d0,8(a0)
 move.w d2,10(a0)
 
 move.w lbr,d5
 sub.w #300,d5
 ext.w d5
 move.w d5,24(a0)
 move.w 10(a1),d5
 sub.w #300,d5
 ext.w d5
 move.w d5,26(a0)

 move.w tlbr,d5
 sub.w #300,d5
 ext.w d5
 move.w d5,32(a0)
 move.w 6(a1),d5
 sub.w #300,d5
 ext.w d5
 move.w d5,34(a0)

 movem.l d7/a1,-(a7)
 move.w #maxscrdiv,d7
 bsr DoleftendGOUR
 movem.l (a7)+,d7/a1

alloffleft2G:

 move.l (a1)+,d1
 move.w (a1)+,d0
 move.w (a1)+,tlbr
 move.w (a1)+,d4
 move.w (a1)+,lbr

 dbra d7,computeloop2G

 rts
 
alloffright2G:
 rts


***********************************

* Need a routine which takes...?
* Top Y (3d)
* Bottom Y (3d)
* distance
* height of each tile (number and routine addr)
* And produces the appropriate strip on the
* screen.

 
nostripqG:
 rts
 
STARTGOUR: dc.l 0
 
ScreenWallstripdrawGOUR:

 swap d6
 clr.w d6
 move.l d6,STARTGOUR

 swap d7
 clr.w d7
 
 move.w d4,d6
 sub.w d3,d6
 beq.s nostripqG
 ext.l d6

 divs.l d6,d7	; speed through gouraud table.

 move.w d4,d6
 cmp.w topclip(pc),d6
 blt.s nostripqG
 cmp.w botclip(pc),d3
 bgt.s nostripqG
 
 cmp.w botclip(pc),d6
 ble.s noclipbotG
 move.w botclip(pc),d6
noclipbotG:
 
 move.w d3,d5
 cmp.w topclip(pc),d5
 bge.s nocliptopG

 sub.w topclip(pc),d5
 neg.w d5
 ext.l d5
 move.l d7,d0
 muls.l d5,d0
 add.l d0,STARTGOUR
 
 move.w topclip(pc),d5
 
 
; bra gotoendG
; 
nocliptopG:
; 
 
 bra gotoendG
 
 CNOP 0,128 
drawwallPACK0G:
 swap d4
 and.w d7,d4
 move.l d3,d2
 swap d2
 move.b 1(a5,d4.w*2),d1
 and.w #%1111111111100000,d2
 swap d4
 and.b #31,d1
 add.w d1,d2
 move.b (a4,d2.w*2),(a3)
 adda.w d0,a3
 add.l d5,d3
 add.l a2,d4
 dbra d6,drawwallPACK0G

nostripG:
 rts


 CNOP 0,4 
drawwallPACK1G:
 swap d4
 and.w d7,d4
 move.l d3,d2
 swap d2
 move.w (a5,d4.w*2),d1
 and.w #%1111111111100000,d2
 swap d4
 lsr.w #5,d1
 and.w #31,d1
 add.b d1,d2
 move.b (a4,d2.w*2),(a3)
 adda.w d0,a3
 add.l d5,d3
 add.l a2,d4
 dbra d6,drawwallPACK1G

 rts


 CNOP 0,4 
drawwallPACK2G:
 swap d4
 and.w d7,d4
 move.l d3,d2
 swap d2
 move.b (a5,d4.w*2),d1
 and.w #%1111111111100000,d2
 swap d4
 lsr.b #2,d1
 and.w #31,d1
 add.b d1,d2
 move.b (a4,d2.w*2),(a3)
 adda.w d0,a3
 add.l d5,d3
 add.l a2,d4
 dbra d6,drawwallPACK2G
 rts


usesimpleG:
 mulu d3,d4
 
 add.l d0,d4
 swap d4
 add.w totalyoff(pc),d4

cliptopusesimpleG
 move.w VALAND,d7
 move.w #320,d0
 moveq #0,d1

 swap d2
 
 ifne CHEESEY
 asr.l #1,d2
 endc
 move.l d2,a2
 swap d4
 ifne CHEESEY
 asr.l #1,d4
 endc
 
 move.l GOURSPEED,d5
 asl.l #5,d5
 move.l STARTGOUR,d3
 asl.l #5,d3
 
 cmp.b #1,StripData+1
 dbge d6,simplewalliPACK0G
 dbne d6,simplewalliPACK1G
 dble d6,simplewalliPACK2G
 rts

 CNOP 0,4
simplewalliPACK0G:
 swap d4
 and.w d7,d4
 move.l d3,d2
 swap d2
 move.b 1(a5,d4.w*2),d1
 and.w #%1111111111100000,d2
 swap d4
 and.b #31,d1
 add.b d1,d2
 move.b (a2,d2.w*2),d3
simplewallPACK0G:
 move.b d3,(a3)
 adda.w d0,a3
 add.l a2,d4
 bcc.s .noread
 addq #1,d4
 and.w d7,d4
 move.b 1(a5,d4.w*2),d1
 and.b #31,d1
 move.b (a2,d1.w*2),d3
.noread:
 dbra d6,simplewallPACK0G
 rts

 CNOP 0,4
simplewalliPACK1G:
 swap d4
 and.w d7,d4
 move.l d3,d2
 swap d2
 move.w (a5,d4.w*2),d1
 lsr.w #5,d1
 and.w #31,d1
 move.b (a2,d1.w*2),d3
simplewallPACK1G:
 move.b d3,(a3)
 adda.w d0,a3
 add.l d5,d4
 bcc.s .noread
 addq #1,d4
 and.w d7,d4
 move.w (a5,d4.w*2),d1
 lsr.w #5,d1
 and.w #31,d1
 move.b (a2,d1.w*2),d3
.noread:
 dbra d6,simplewallPACK1G
 rts

 CNOP 0,4
simplewalliPACK2G:
 move.b (a5,d4.w*2),d1
 lsr.b #2,d1
 and.b #31,d1
 move.b (a2,d1.w*2),d3
simplewallPACK2G:
 move.b d3,(a3)
 adda.w d0,a3
 add.l d5,d4
 bcc.s .noread
 addq #1,d4
 and.w d7,d4
 move.b (a5,d4.w*2),d1
 lsr.b #2,d1
 move.b (a2,d1.w*2),d3
.noread:
 dbra d6,simplewallPACK2G
 rts
 
;gotoendnomult:
; movem.l d0/d1/d2/d3/d4/d7,-(a7)
; add.l timeslarge(pc,d5.w*4),a3 
; move.w d5,d4
; move.l 4(a1,d2.w*8),d0
; move.l (a1,d2.w*8),d2
; moveq #0,d3
; move.w d2,d3
; swap d2
; tst.w d2
; move.w wallyoff(pc),d4
; add.w #44,d4
; bne.s .notsimple
; cmp.l #$b000,d3
; ble cliptopusesimple
;.notsimple:
; bra cliptop

GOURSPEED: dc.l 0

gotoendG:
 tst.b DOUBLEHEIGHT
 bne doubwallGOUR

 sub.w d5,d6	; height to draw.
 ble nostripqG

 move.l d7,GOURSPEED

 add.l timeslargeG(pc,d5.w*4),a3 
 
 add.w d2,d2
 
 move.l 4(a1,d2.w*8),d0
 add.w TOPOFFSET(pc),d5
 move.w d5,d4
 
 move.l (a1,d2.w*4),d2
 moveq #0,d3
; move.w d2,d3
; swap d2
; tst.w d2
; bne.s .notsimple
; cmp.l #$b000,d3
; ble usesimple
;.notsimple:
 
 ext.l d5
 move.l d2,d4
 muls.l d5,d4
 
; mulu d3,d4
; muls d2,d5
 add.l d0,d4
 ifne CHEESEY
 asr.l #1,d4
 endc
 swap d4
; add.w d5,d4
 add.w totalyoff(pc),d4
cliptopG
 move.w VALAND,d7
 and.w d7,d4
 move.w #320,d0
 moveq #0,d1

 ifne CHEESEY
 asr.l #1,d2
 endc
 move.l d2,a2
 swap d4
 
 move.l GOURSPEED,d5
 asl.l #5,d5
 move.l STARTGOUR,d3
 asl.l #5,d3

 cmp.b #1,StripData+1
 dbge d6,drawwallPACK0G
 dbne d6,drawwallPACK1G
 dble d6,drawwallPACK2G
 rts

timeslargeG:
val SET 0
 REPT 256
 dc.l val
val SET val+320
 ENDR

doubwallGOUR:

 moveq #0,d0
 asr.w #1,d5
 addx.w d0,d5
 add.w d5,d5

 sub.w d5,d6	; height to draw.
 asr.w #1,d6
 ble nostripqG

 move.l d7,GOURSPEED

 add.l timeslargeGDOUB(pc,d5.w*4),a3 
 
 add.w d2,d2
 
 move.l 4(a1,d2.w*8),d0
 add.w TOPOFFSET(pc),d5
 move.w d5,d4
 
 move.l (a1,d2.w*4),d2
 moveq #0,d3
; move.w d2,d3
; swap d2
; tst.w d2
; bne.s .notsimple
; cmp.l #$b000,d3
; ble usesimple
;.notsimple:
 
 ext.l d5
 move.l d2,d4
 muls.l d5,d4
 
; mulu d3,d4
; muls d2,d5
 add.l d0,d4
 ifne CHEESEY
 asr.l #1,d4
 endc
 swap d4
; add.w d5,d4
 add.w totalyoff(pc),d4
 move.w VALAND,d7
 and.w d7,d4
 move.w #640,d0
 moveq #0,d1

 ifeq CHEESEY
 add.l d2,d2
 endc
 move.l d2,a2
 swap d4
 
 move.l GOURSPEED,d5
 asl.l #6,d5
 move.l STARTGOUR,d3
 asl.l #5,d3

 cmp.b #1,StripData+1
 dbge d6,drawwallPACK0G
 dbne d6,drawwallPACK1G
 dble d6,drawwallPACK2G
 rts

timeslargeGDOUB:
val SET 0
 REPT 256
 dc.l val
val SET val+320
 ENDR



ScreenWallstripdrawGOURB:

 swap d6
 clr.w d6
 move.l d6,STARTGOUR

 swap d7
 clr.w d7
 
 move.w d4,d6
 sub.w d3,d6
 beq nostripqG
 ext.l d6

 divs.l d6,d7	; speed through gouraud table.

 move.w d4,d6
 cmp.w topclip(pc),d6
 blt nostripqG
 cmp.w botclip(pc),d3
 bgt nostripqG
 
 cmp.w botclip(pc),d6
 ble.s noclipbotGb
 move.w botclip(pc),d6
noclipbotGb:
 
 move.w d3,d5
 cmp.w topclip(pc),d5
 bge.s nocliptopGB
 
 sub.w topclip(pc),d5
 neg.w d5
 ext.l d5
 move.l d7,d0
 muls.l d5,d0
 add.l d0,STARTGOUR
 
 move.w topclip(pc),d5
 
nocliptopGB:
 
 

gotoendGB:

 tst.b DOUBLEHEIGHT
 bne doubwallGOURBIG

 sub.w d5,d6	; height to draw.
 ble nostripqG
 move.l d7,GOURSPEED

 add.l timeslargeGB(pc,d5.w*4),a3 
 
 move.w d2,d4
 add.w d2,d2
 add.w d2,d4
 
 move.l 4(a1,d4.w*8),d0
 add.w TOPOFFSET(pc),d5
 move.w d5,d4
 
 move.l (a1,d2.w*4),d2
 moveq #0,d3
; move.w d2,d3
; swap d2
; tst.w d2
; bne.s .notsimple
; cmp.l #$b000,d3
; ble usesimple
;.notsimple:
 
 ext.l d5
 move.l d2,d4
 muls.l d5,d4
 
; mulu d3,d4
; muls d2,d5
 add.l d0,d4
 ifne CHEESEY
 asr.l #1,d4
 endc
 swap d4
; add.w d5,d4
 add.w totalyoff(pc),d4
 move.w VALAND,d7
 and.w d7,d4
 move.w #320,d0
 moveq #0,d1

 ifne CHEESEY
 asr.l #1,d2
 endc

 move.l d2,a2
 swap d4

 
 move.l GOURSPEED,d5
 asl.l #5,d5
 move.l STARTGOUR,d3
 asl.l #5,d3

 cmp.b #1,StripData+1
 dbge d6,drawwallPACK0G
 dbne d6,drawwallPACK1G
 dble d6,drawwallPACK2G
 rts

timeslargeGB:
val SET 0
 REPT 256
 dc.l val
val SET val+320
 ENDR


doubwallGOURBIG:

 moveq #0,d0
 asr.w #1,d5
 addx.w d0,d5
 add.w d5,d5

 sub.w d5,d6	; height to draw.
 asr.w #1,d6
 ble nostripqG
 move.l d7,GOURSPEED

 add.l timeslargeGBDOUB(pc,d5.w*4),a3 
 
 move.w d2,d4
 add.w d2,d2
 add.w d2,d4
 
 move.l 4(a1,d4.w*8),d0
 add.w TOPOFFSET(pc),d5
 move.w d5,d4
 
 move.l (a1,d2.w*4),d2
 moveq #0,d3
; move.w d2,d3
; swap d2
; tst.w d2
; bne.s .notsimple
; cmp.l #$b000,d3
; ble usesimple
;.notsimple:
 
 ext.l d5
 move.l d2,d4
 muls.l d5,d4
 
; mulu d3,d4
; muls d2,d5
 add.l d0,d4
 ifne CHEESEY
 asr.l #1,d4
 endc
 swap d4
; add.w d5,d4
 add.w totalyoff(pc),d4
 move.w VALAND,d7

 and.w d7,d4
 move.w #640,d0
 moveq #0,d1

 ifeq CHEESEY
 add.l d2,d2
 endc
 move.l d2,a2
 swap d4
 
 
 move.l GOURSPEED,d5
 asl.l #6,d5
 move.l STARTGOUR,d3
 asl.l #5,d3

 cmp.b #1,StripData+1
 dbge d6,drawwallPACK0G
 dbne d6,drawwallPACK1G
 dble d6,drawwallPACK2G
 rts

timeslargeGBDOUB:
val SET 0
 REPT 256
 dc.l val
val SET val+320
 ENDR
