leftclip: dc.w 0
rightclip: dc.w 0
deftopclip: dc.w 0
defbotclip: dc.w 0
leftclipandlast: dc.w 0

SCALE MACRO
 dc.w 64*0
 dc.w 64*1
 dc.w 64*1
 dc.w 64*2
 dc.w 64*2
 dc.w 64*3
 dc.w 64*3
 dc.w 64*4
 dc.w 64*4
 dc.w 64*5
 dc.w 64*5
 dc.w 64*6
 dc.w 64*6
 dc.w 64*7
 dc.w 64*7
 dc.w 64*8
 dc.w 64*8
 dc.w 64*9
 dc.w 64*9
 dc.w 64*10
 dc.w 64*10
 dc.w 64*11
 dc.w 64*11
 dc.w 64*12
 dc.w 64*12
 dc.w 64*13
 dc.w 64*13
 dc.w 64*14
 dc.w 64*14
 dc.w 64*15
 dc.w 64*15
 dc.w 64*16
 dc.w 64*16
 dc.w 64*17
 dc.w 64*17
 dc.w 64*18
 dc.w 64*18
 dc.w 64*19
 dc.w 64*19
 dc.w 64*20
 dc.w 64*20
 dc.w 64*21
 dc.w 64*21
 dc.w 64*22
 dc.w 64*22
 dc.w 64*23
 dc.w 64*23
 dc.w 64*24
 dc.w 64*24
 dc.w 64*25
 dc.w 64*25
 dc.w 64*26
 dc.w 64*26
 dc.w 64*27
 dc.w 64*27
 dc.w 64*28
 dc.w 64*28
 dc.w 64*29
 dc.w 64*29
 dc.w 64*30
 dc.w 64*30
 dc.w 64*31
 dc.w 64*31
 dc.w 64*31
 dc.w 64*31
 dc.w 64*31
 dc.w 64*31
 dc.w 64*31
 dc.w 64*31
 dc.w 64*31
 dc.w 64*31
 dc.w 64*31
 dc.w 64*31
 dc.w 64*31
 dc.w 64*31
 dc.w 64*31
 dc.w 64*31
 dc.w 64*31
 dc.w 64*31
 dc.w 64*31
 dc.w 64*31
 ENDM

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


Doleftend:

 move.w leftclip,d0
 sub.w #1,d0
 move.w d0,leftclipandlast


 move.w (a0),d0
 move.w 2(a0),d1
 sub.w d0,d1
 bge.s sometodraw
 rts
sometodraw:
 move.w itertab(pc,d1.w*4),d7
 swap d0
 move.w itertab+2(pc,d1.w*4),d6
 clr.w d0
 swap d1
 clr.w d1
 asr.l d6,d1
 move.l d1,(a0)

 bra pstit

itertab:
 incbin "iterfile"

pstit:

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
 
 bra screendivide

itercount: dc.w 0

screendividethru:

.scrdrawlop:

 move.w (a0)+,d0
 move.l FASTBUFFER,a3
 move.l (a0)+,d1
 
 bra .pastscrinto

.scrintocop:
 incbin "XTOCOPX"

.pastscrinto 

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
 asl.w d4,d6
 add.w d6,a5
 move.l (a0)+,d4
 swap d4
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
 add.w angbright(pc),d6
 bge.s .brnotneg
 moveq #0,d6
.brnotneg
 cmp.w #32,d6
 blt.s .brnotpos
 move.w #32,d6
.brnotpos
 move.l PaletteAddr,a2
 move.l a2,a4
 add.w .ffscrpickhowbright(pc,d6*2),a2
; and.b #$fe,d6
; add.w .ffscrpickhowbright(pc,d6*2),a4

; btst #0,d0
; beq .nobrightswap
; exg a2,a4
;.nobrightswap:

 move.w d7,-(a7)
 bsr ScreenWallstripdrawthru
 move.w (a7)+,d7
 
 dbra d7,.scrdrawlop
 rts

.ffscrpickhowbright:
 SCALE


***************************

screendivide:

 or.l #$ffff0000,d7
 move.w leftclipandlast(pc),d6
 move.l #WorkSpace,a2

 move.l (a0),a3
 move.l 4(a0),a4
 move.l 8(a0),a5
 move.l 12(a0),a6
 move.l 16(a0),a1
 move.l 28(a0),a0
 
scrdivlop:

 swap d0
 cmp.w d6,d0
 bgt scrnotoffleft
 swap d0
 add.l a4,d1
 add.l a5,d2
 add.l a6,d3
 add.l a1,d4
 add.l a3,d0
 add.l a0,d5
 dbra d7,scrdivlop
 rts
 
scrnotoffleft:

 move.w d0,d6

 cmp.w rightclip(pc),d0
 bge.s outofcalc
 
scrnotoffright:

 
 move.w d0,(a2)+
 move.l d1,(a2)+
 move.l d2,(a2)+
 move.l d3,(a2)+
 move.l d4,(a2)+
 move.l d5,(a2)+
 swap d0
 add.l a3,d0
 add.l a4,d1
 add.l a5,d2
 add.l a6,d3
 add.l a1,d4
 add.l a0,d5
 add.l #$10000,d7
 dbra d7,scrdivlop
 
outofcalc:
 swap d7
 tst.w d7
 bge.s .somethingtodraw
 rts
.somethingtodraw:

 move.l #consttab,a1
 move.l #WorkSpace,a0

 tst.b FULLSCR
 bne screendivideFULL

; tst.b seethru
; bne screendividethru

scrdrawlop:

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
 asl.w d4,d6
 add.w d6,a5
 move.l (a0)+,d4
 swap d4
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
 ext.w d5
 add.w d5,d6
 bge.s .brnotneg
 moveq #0,d6
.brnotneg
 cmp.w #64,d6
 blt.s .brnotpos
 move.w #64,d6
.brnotpos
 move.l PaletteAddr,a2
 move.l a2,a4
 add.w ffscrpickhowbright(pc,d6*2),a2
 and.b #$fe,d6
 add.w ffscrpickhowbright(pc,d6*2),a4

 btst #0,d0
 beq .nobrightswap
 exg a2,a4
.nobrightswap:

 move.w d7,-(a7)
 bsr ScreenWallstripdraw
 move.w (a7)+,d7
 
toosmall:
 
 dbra d7,scrdrawlop
 
 rts

middleline:
 dc.w 0

;scrintocop:
; incbin "XTOCOPX"
prot4: dc.w 0

fromtile: dc.l 0
fromquartertile: dc.l 0
swapbrights: dc.w 0
angbright: dc.w 0

leftside: dc.b 0
rightside: dc.b 0
firstleft: dc.w 0

ffscrpickhowbright:
 SCALE

screendivideFULL:

scrdrawlopFULL:

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
 asl.w d4,d6
 add.w d6,a5
 move.l (a0)+,d4
 swap d4
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
 ext.w d5
 add.w d5,d6
 bge.s .brnotneg
 moveq #0,d6
.brnotneg
 cmp.w #64,d6
 blt.s .brnotpos
 move.w #64,d6
.brnotpos
 move.l PaletteAddr,a2
 move.l a2,a4
 add.w ffscrpickhowbrightFULL(pc,d6*2),a2
 and.b #$fe,d6
 add.w ffscrpickhowbrightFULL(pc,d6*2),a4

 btst #0,d0
 beq .nobrightswap
 exg a2,a4
.nobrightswap:

 move.w d7,-(a7)
 bsr ScreenWallstripdrawBIG
 move.w (a7)+,d7
 
 dbra d7,scrdrawlopFULL
 
 rts

ffscrpickhowbrightFULL:
 SCALE

divthreetab:
val SET 0
 REPT 130
 dc.b val,0
 dc.b val,1
 dc.b val,2
val SET val+1
 ENDR

StripData: dc.w 0

* using a0=left pixel
* a2= right pixel
* d0= left height
* d2= right height
* d4 = left strip
* d5 = right strip


* Routine to draw a wall;
* pass it X and Z coords of the endpoints
* and the start and end length, and a number
* representing the number of the wall.

* a0=x1 d1=z1 a2=x2 d3=z2
* d4=sl d5=el
* a1 = strip buffer

store: ds.l 500

******************************************************************

* Curve drawing routine. We have to know:
* The top and bottom of the wall
* The point defining the centre of the arc
* the point defining the starting point of the arc
* the start and end angles of the arc
* The start and end positions along the bitmap of the arc
* Which bitmap to use for the arc

xmiddle: dc.w 0
zmiddle SET 2
 dc.w 0
xradius SET 4
 dc.w 0
zradius SET 6
 dc.w 0
startbitmap SET 8
 dc.w 0
bitmapcounter SET 10
 dc.w 0
brightmult SET 12
 dc.w 0
angadd SET 14
 dc.l 0
xmiddlebig SET 18
 dc.l 0
basebright SET 22
 dc.w 0
shift SET 24
 dc.w 0
count SET 26
 dc.w 0

subdividevals:
 dc.w 2,4
 dc.w 3,8
 dc.w 4,16
 dc.w 5,32
 dc.w 6,64

CurveDraw:

 move.w (a0)+,d0	; centre of rotation
 move.w (a0)+,d1	; point on arc
 move.l #Rotated,a1
 move.l #xmiddle,a2
 move.l (a1,d0.w*8),d2
 move.l d2,18(a2)
 asr.l #7,d2
 move.l (a1,d1.w*8),d4
 asr.l #7,d4
 sub.w d2,d4
 move.w d2,(a2)
 move.w d4,4(a2)
 move.w 6(a1,d0.w*8),d2
 move.w 6(a1,d1.w*8),d4
 sub.w d2,d4
 move.w d2,2(a2)
 asr.w #1,d4
 move.w d4,6(a2)
 move.w (a0)+,d4	; start of bitmap
 move.w (a0)+,d5	; end of bitmap
 move.w d4,8(a2)
 sub.w d4,d5
 move.w d5,10(a2)
 move.w (a0)+,d4
 ext.l d4
 move.l d4,14(a2)
 move.w (a0)+,d4
 move.l #subdividevals,a3
 move.l (a3,d4.w*4),shift(a2)
 
 move.l #walltiles,a3
 add.l (a0)+,a3
 adda.w wallyoff,a3
 move.l a3,fromtile
 move.w (a0)+,basebright(a2)
 move.w (a0)+,brightmult(a2)
 move.l (a0)+,topofwall
 move.l (a0)+,botofwall
 move.l yoff,d6
 sub.l d6,topofwall
 sub.l d6,botofwall

 move.l #databuffer,a1
 move.l #SineTable,a3
 lea 2048(a3),a4
 moveq #0,d0
 moveq #0,d1
 move.w count(a2),d7
DivideCurve
 move.l d0,d2
 move.w shift(a2),d4
 asr.l d4,d2
 move.w (a3,d2.w*2),d4
 move.w d4,d5
 move.w (a4,d2.w*2),d3
 move.w d3,d6
 muls.w 4(a2),d3
 muls.w 6(a2),d4
 muls.w 4(a2),d5
 muls.w 6(a2),d6
 sub.l d4,d3
 add.l d6,d5
 asl.l #2,d5
 asr.l #8,d3
 add.l 18(a2),d3
 swap d5
 move.w basebright(a2),d6
 move.w brightmult(a2),d4
 muls d5,d4
 swap d4
 add.w d4,d6
 
 add.w 2(a2),d5
 move.l d3,(a1)+
 move.w d5,(a1)+
 move.w d1,d2
 move.w shift(a2),d4
 asr.w d4,d2
 add.w 8(a2),d2
 move.w d2,(a1)+
 move.w d6,(a1)+

 add.l 14(a2),d0  
 add.w 10(a2),d1
 dbra d7,DivideCurve
 
 move.l a0,-(a7)

; move.w #31,d6
; move.l #0,d3
; move.l #stripbuffer,a4
;.emptylop:
; move.l d3,(a4)+
; dbra d6,.emptylop

 bsr curvecalc

 move.l (a7)+,a0

 rts

prot3: dc.w 0
 
curvecalc:
 move.l #databuffer,a1
 move.w count(a2),d7
 subq #1,d7
.findfirstinfront:
 move.l (a1)+,d1
 move.w (a1)+,d0
 bgt.s .foundinfront
 move.w (a1)+,d4
 move.w (a1)+,d6
 dbra d7,.findfirstinfront
; CACHE_ON d2
 rts	; no two points were in front
 
.foundinfront:
 move.w (a1)+,d4
 move.w (a1)+,d6
 ; d1=left x, d4=left end, d0=left dist
 ; d6=left angbright 
 
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
 
; CACHE_OFF d2
 
.computeloop:
 move.w 4(a1),d2
 bgt.s .infront
 
; addq #8,a1
; dbra d7,.findfirstinfront
 
; CACHE_ON d2
 rts

.infront:
 move.l #store,a0
 move.l (a1),d3
 move.w 6(a1),d5
 add.w 8(a1),d6
 asr.w #1,d6
 move.w d6,angbright
 divs d2,d3
 add.w MIDDLEX,d3
 move.w strtop(pc),12(a0)
 move.w strbot(pc),16(a0)
 move.l topofwall(pc),d6
 divs d2,d6
 add.w MIDDLEY,d6
 move.w d6,strtop
 move.w d6,14(a0)
 move.l botofwall(pc),d6
 divs d2,d6
 add.w MIDDLEY,d6
 move.w d6,strbot
 move.w d6,18(a0)
 move.w d3,2(a1)
 blt.s .alloffleft
 cmp.w RIGHTX,d1
 bgt.s .alloffleft

 cmp.w d1,d3
 blt.s .alloffleft

 move.w d1,(a0)
 move.w d3,2(a0)
 move.w d4,4(a0)
 move.w d5,6(a0)
 move.w d0,8(a0)
 move.w d2,10(a0)
 move.w d7,-(a7)
 move.w #maxscrdiv,d7
 bsr Doleftend
 move.w (a7)+,d7

.alloffleft:

 move.l (a1)+,d1
 move.w (a1)+,d0
 move.w (a1)+,d4
 move.w (a1)+,d6

 dbra d7,.computeloop
 
.alloffright:
; CACHE_ON d2
 rts

;protcheck:
; sub.l #53624,a3
; add.l #2345215,a2
; lea passspace-$30000(pc),a1
; add.l #$30000,a1
; lea startpass(pc),a5
; move.w #endpass-startpass-1,d1
;copypass:
; move.b (a5)+,(a1)+
; dbra d1,copypass
; sub.l a5,a5
; lea passspace-$30000(pc),a1
; add.l #$30000,a1
; jsr (a1)
; lea passspace-$30000(pc),a1
; add.l #$30000,a1
; lea startpass(pc),a5
; move.w #(endpass-startpass)/2-1,d1
;erasepass:
; move.w -(a5),(a1)+
; dbra d1,erasepass
; sub.l a5,a5
; sub.l a1,a1
; eor.l #$af594c72,d0
; sub.l #123453986,a4
; move.l d0,(a4)
; add.l #123453986,a4
; move.l #0,d0
; sub.l #2345215,a2
; jsr (a2)
; sub.l a2,a2
; eor.l #$af594c72,d0
; sub.l #123453986,a4
; move.l (a4),d1
; add.l #123453986,a4
; cmp.l d1,d0
; bne.s notrightt
; add.l #53624,a3
; move.w #9,d7
;sayitsok:
; move.l (a3)+,a2
; add.l #78935450,a2
; st (a2)
; dbra d7,sayitsok
;notrightt:
; sub.l a3,a3
;nullit:
; rts
; 
; incbin "ab3:includes/protroutencoded"

endprot:

******************************************************************

iters: dc.w 0
multcount: dc.w 0

walldraw:

 tst.w d1
 bgt.s oneinfront1
 tst.w d3
 bgt.s oneinfront
 rts

oneinfront1
 tst.w d3
 ble.s oneinfront
; Bothinfront!

 nop

oneinfront

 move.w #32,d7
 move.w #3,d6
 
 move.w d3,d0
 sub.w d1,d0
 bge.s notnegzdiff
 neg.w d0
notnegzdiff
; cmp.w #1024,d0
; blt.s nd01
; add.w d7,d7
; add.w #1,d6
;nd01:
 cmp.w #512,d0
 blt.s nd0 
 add.w d7,d7
 add.w #1,d6
 bra nha
nd0:

 cmp.w #256,d0
 bgt.s nh1
 asr.w #1,d7
 subq #1,d6
nh1:
 cmp.w #128,d0
 bgt.s nh2
 asr.w #1,d7
 subq #1,d6
nh2:

nha:

 move.w d3,d0
 cmp.w d1,d3
 blt.s rightnearest
 move.w d1,d0
rightnearest:
 cmp.w #64,d0
 bgt.s nd1
 addq #1,d6
 add.w d7,d7
nd1:

 cmp.w #128,d0
 blt.s nh3
 asr.w #1,d7
 subq #1,d6
 blt.s nh3
 cmp.w #256,d0
 blt.s nh3
 asr.w #1,d7
 subq #1,d6
nh3:
 move.w d6,iters
 subq #1,d7
 move.w d7,multcount

 move.l #databuffer,a3
 move.l a0,d0
 move.l a2,d2
 
 swap d1
 clr.w d1
 swap d4
 clr.w d4
 swap d5
 clr.w d5
 swap d3
 clr.w d3

 move.l d0,(a3)+
 add.l d2,d0
 move.l d1,(a3)+
 asr.l #1,d0
 move.l d4,(a3)+

 move.w leftwallbright,d6
 move.w d6,(a3)+
 
 add.l d5,d4
 move.l d0,(a3)+
 add.l d3,d1
 asr.l #1,d1
 move.l d1,(a3)+
 asr.l #1,d4
 move.l d4,(a3)+
 
 add.w rightwallbright,d6
 asr.w #1,d6
 move.w d6,(a3)+
 
 move.l d2,(a3)+
 move.l d3,(a3)+
 move.l d5,(a3)+
 move.w rightwallbright,(a3)+
 
 ; We now have the two endpoints and the midpoint
 ; so we need to perform 1 iteration of the inner
 ; loop, the first time.
 
* Decide how often to subdivide by how far away the wall is, and
* how perp. it is to the player.

 move.l #databuffer,a0
 move.l #databuffer2,a1
 
 move.w iters,d6
 blt noiters
 move.l #1,a2
 
iterloop:
 move.l a0,a3
 move.l a1,a4
 move.w a2,d7
 exg a0,a1

 move.l (a3)+,d0
 move.l (a3)+,d1
 move.l (a3)+,d2
 move.w (a3)+,d3
middleloop:

 move.l d0,(a4)+
 move.l d1,(a4)+
 move.l d2,(a4)+
 move.w d3,(a4)+
 
 add.l (a3),d0
 add.l 4(a3),d1
 add.l 8(a3),d2
 add.w 12(a3),d3
 
 asr.l #1,d0
 asr.l #1,d1
 asr.l #1,d2
 asr.w #1,d3

 move.l d0,(a4)+
 move.l d1,(a4)+
 move.l d2,(a4)+
 move.w d3,(a4)+

 move.l (a3)+,d0
 move.l d0,(a4)+
 move.l (a3)+,d1
 move.l d1,(a4)+
 move.l (a3)+,d2
 move.l d2,(a4)+
 move.w (a3)+,d3
 move.w d3,(a4)+

 move.l d0,d4
 move.l (a3)+,d0
 add.l d0,d4
 asr.l #1,d4
 move.l d4,(a4)+
 move.l d1,d4
 move.l (a3)+,d1
 add.l d1,d4
 asr.l #1,d4
 move.l d4,(a4)+
 move.l d2,d4
 move.l (a3)+,d2
 add.l d2,d4
 asr.l #1,d4
 move.l d4,(a4)+
 move.w d3,d4
 move.w (a3)+,d3
 add.w d3,d4
 asr.w #1,d4
 move.w d4,(a4)+


 subq #1,d7
 bgt.s middleloop
 move.l d0,(a4)+
 move.l d1,(a4)+
 move.l d2,(a4)+
 move.w d3,(a4)+
 
 add.w a2,a2
 
 dbra d6,iterloop
 
noiters:
 
CalcAndDraw:
 
; CACHE_ON d2
 
 move.l a0,a1
 move.w multcount,d7
.findfirstinfront:
 move.l (a1)+,d1
 move.w (a1)+,d0
 bgt.s .foundinfront
 move.l (a1)+,d4
 dbra d7,.findfirstinfront
 rts	; no two points were in front
 
.foundinfront:
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
 move.w 6(a1),d5
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

 bra OTHERHALF


.alloffleft:

 move.l (a1)+,d1
 move.w (a1)+,d0
 move.w (a1)+,d4
 move.w (a1)+,lbr

 dbra d7,.computeloop
 rts

.alloffright:
 rts
 
computeloop2:
 move.w 4(a1),d2
 bgt.s .infront
 rts

.infront:
 move.l #store,a0
 move.l (a1),d3
 divs d2,d3
 move.w 6(a1),d5
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
 blt.s alloffleft2
 cmp.w rightclip(pc),d1
; cmp.w #95,d1
 bge.s alloffright2

OTHERHALF:

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
 move.w 8(a1),d5
 sub.w #300,d5
 ext.w d5
 move.w d5,26(a0)
 
 movem.l d7/a1,-(a7)
 move.w #maxscrdiv,d7
 bsr Doleftend
 movem.l (a7)+,d7/a1

alloffleft2:

 move.l (a1)+,d1
 move.w (a1)+,d0
 move.w (a1)+,d4
 move.w (a1)+,lbr

 dbra d7,computeloop2

 rts
 
alloffright2:
 rts

lbr: dc.w 0
tlbr: dc.w 0
leftwallbright: dc.w 0
rightwallbright: dc.w 0
leftwallTOPbright: dc.w 0
rightwallTOPbright: dc.w 0
strtop: dc.w 0
strbot: dc.w 0
 
databuffer:
 ds.l 1600
databuffer2:
 ds.l 1600

***********************************

* Need a routine which takes...?
* Top Y (3d)
* Bottom Y (3d)
* distance
* height of each tile (number and routine addr)
* And produces the appropriate strip on the
* screen.

topofwall: dc.l 0
botofwall: dc.l 0
 
nostripq:
 rts
 
ScreenWallstripdraw:

 move.w d4,d6
 cmp.w topclip(pc),d6
 blt.s nostripq
 cmp.w botclip(pc),d3
 bgt.s nostripq
 
 cmp.w botclip(pc),d6
 ble.s noclipbot
 move.w botclip(pc),d6
noclipbot:
 
 move.w d3,d5
 cmp.w topclip(pc),d5
 bge.s nocliptop
 move.w topclip(pc),d5
 btst #0,d5
 beq.s .nsbd
 exg a2,a4
.nsbd:
 
 sub.w d5,d6	; height to draw.
 ble.s nostripq
 
 bra gotoend
 
nocliptop:

 btst #0,d5
 beq.s .nsbd
 exg a2,a4
.nsbd:
 
 sub.w d5,d6	; height to draw.
 ble.s nostripq
 
 bra gotoend
 
wlcnt: dc.w 0
 
 CNOP 0,4
drawwalldimPACK0:
 and.w d7,d4
 move.b 1(a5,d4.w*2),d1
 and.b #31,d1
 add.l d3,d4
 move.b (a4,d1.w*2),(a3)
 adda.w d0,a3
 addx.w d2,d4
 dbra d6,drawwallPACK0
 rts

 CNOP 0,128 
drawwallPACK0:
 and.w d7,d4
 move.b 1(a5,d4.w*2),d1
 and.b #31,d1
 add.l d3,d4
 move.b (a2,d1.w*2),(a3)
 adda.w d0,a3
 addx.w d2,d4
 dbra d6,drawwalldimPACK0

nostrip:
 rts

 CNOP 0,4
drawwalldimPACK1:
 and.w d7,d4
 move.w (a5,d4.w*2),d1
 lsr.w #5,d1
 and.w #31,d1
 add.l d3,d4
 move.b (a4,d1.w*2),(a3)
 adda.w d0,a3
 addx.w d2,d4
 dbra d6,drawwallPACK1
 rts

 CNOP 0,4 
drawwallPACK1:
 and.w d7,d4
 move.w (a5,d4.w*2),d1
 lsr.w #5,d1
 and.w #31,d1
 add.l d3,d4
 move.b (a2,d1.w*2),(a3)
 adda.w d0,a3
 addx.w d2,d4
 dbra d6,drawwalldimPACK1

 rts

 CNOP 0,4
drawwalldimPACK2:
 and.w d7,d4
 move.b (a5,d4.w*2),d1
 lsr.b #2,d1
 add.l d3,d4
 move.b (a4,d1.w*2),(a3)
 adda.w d0,a3
 addx.w d2,d4
 dbra d6,drawwallPACK2
 rts

 CNOP 0,4 
drawwallPACK2:
 and.w d7,d4
 move.b (a5,d4.w*2),d1
 lsr.b #2,d1
 add.l d3,d4
 move.b (a2,d1.w*2),(a3)
 adda.w d0,a3
 addx.w d2,d4
 dbra d6,drawwalldimPACK2
 rts


usesimple:
 mulu d3,d4
 
 add.l d0,d4
 swap d4
 add.w totalyoff(pc),d4

cliptopusesimple
 move.w VALAND,d7
 move.w #320,d0
 moveq #0,d1
 cmp.l a4,a2
 blt.s usea2
 move.l a4,a2
usea2:

 and.w d7,d4
 
 move.l d2,d5
 clr.w d5
 cmp.b #1,StripData+1
 dbge d6,simplewalliPACK0
 dbne d6,simplewalliPACK1
 dble d6,simplewalliPACK2
 rts

 CNOP 0,4
simplewalliPACK0:
 move.b 1(a5,d4.w*2),d1
 and.b #31,d1
 move.b (a2,d1.w*2),d3
simplewallPACK0:
 move.b d3,(a3)
 adda.w d0,a3
 add.l d2,d4
 bcc.s .noread
 addq #1,d4
 and.w d7,d4
 move.b 1(a5,d4.w*2),d1
 and.b #31,d1
 move.b (a2,d1.w*2),d3
.noread:
 dbra d6,simplewallPACK0
 rts

 CNOP 0,4
simplewalliPACK1:
 move.w (a5,d4.w*2),d1
 lsr.w #5,d1
 and.w #31,d1
 move.b (a2,d1.w*2),d3
simplewallPACK1:
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
 dbra d6,simplewallPACK1
 rts

 CNOP 0,4
simplewalliPACK2:
 move.b (a5,d4.w*2),d1
 lsr.b #2,d1
 and.b #31,d1
 move.b (a2,d1.w*2),d3
simplewallPACK2:
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
 dbra d6,simplewallPACK2
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

MIDDLEY: dc.w 120
BIGMIDDLEY: dc.l 320*120
TOPOFFSET: dc.w 0
SMIDDLEY: dc.w 120
SBIGMIDDLEY: dc.l 320*120
STOPOFFSET: dc.w 0

gotoend:

 add.l timeslarge(pc,d5.w*4),a3 
 
 add.w d2,d2
 
 move.l 4(a1,d2.w*8),d0
 add.w TOPOFFSET(pc),d5
 move.w d5,d4
 
 move.l (a1,d2.w*4),d2
; moveq #0,d3
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

 add.l d0,d4
 swap d4

; mulu d3,d4
; muls d2,d5
; add.l d0,d4
; swap d4
; add.w d5,d4
 add.w totalyoff(pc),d4
 move.w VALAND,d7
 and.w d7,d4
 move.w #320,d0
 moveq #0,d1

 swap d2
 move.l d2,d3
 clr.w d3

 cmp.b #1,StripData+1
 dbge d6,drawwallPACK0
 dbne d6,drawwallPACK1
 dble d6,drawwallPACK2
 rts

timeslarge:

val SET 0
 REPT 256
 dc.l val
val SET val+320
 ENDR

 ds.l 100



ScreenWallstripdrawBIG:

 move.w d4,d6
 cmp.w topclip(pc),d6
 blt nostripq
 cmp.w botclip(pc),d3
 bgt nostripq
 
 cmp.w botclip(pc),d6
 ble.s .noclipbot
 move.w botclip(pc),d6
.noclipbot:
 
 move.w d3,d5
 cmp.w topclip(pc),d5
 bge.s .nocliptop
 move.w topclip(pc),d5
 btst #0,d5
 beq.s .nsbd
 exg a2,a4
.nsbd:
 
 sub.w d5,d6	; height to draw.
 ble nostripq
 
 bra gotoendBIG
 
.nocliptop:

 btst #0,d5
 beq.s .nsbd2
 exg a2,a4
.nsbd2:
 
 sub.w d5,d6	; height to draw.
 ble nostripq
 
gotoendBIG
 
 add.l timeslargeBIG(pc,d5.w*4),a3 
 
 move.w d2,d4
 add.w d2,d2
 add.w d2,d4
 
 move.l 4(a1,d4.w*8),d0
 add.w TOPOFFSET(pc),d5
 move.w d5,d4
 
 move.l (a1,d2.w*4),d2
; moveq #0,d3
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

 add.l d0,d4
 swap d4

; mulu d3,d4
; muls d2,d5
; add.l d0,d4
; swap d4
; add.w d5,d4
 add.w totalyoff(pc),d4
 move.w VALAND,d7
 and.w d7,d4
 move.w #320,d0
 moveq #0,d1

 swap d2
 move.l d2,d3
 clr.w d3

 cmp.b #1,StripData+1
 dbge d6,drawwallPACK0
 dbne d6,drawwallPACK1
 dble d6,drawwallPACK2
 rts

timeslargeBIG:

val SET 0
 REPT 256
 dc.l val
val SET val+320
 ENDR

nostripqthru:
 rts



ScreenWallstripdrawthru:

 move.w d4,d6
 cmp.w topclip(pc),d6
 blt.s nostripqthru
 cmp.w botclip(pc),d3
 bgt.s nostripqthru
 
 cmp.w botclip(pc),d6
 ble.s .noclipbot
 move.w botclip(pc),d6
.noclipbot:
 
 move.w d3,d5
 cmp.w topclip(pc),d5
 bge.s .nocliptop
 move.w topclip(pc),d5
 btst #0,d5
 beq.s .nsbd
 exg a2,a4
.nsbd:
 
 sub.w d5,d6	; height to draw.
 ble.s nostripqthru
 
 bra gotoendthru
 
.nocliptop:

 btst #0,d5
 beq.s .nsbdthru
 exg a2,a4
.nsbdthru:
 
 sub.w d5,d6	; height to draw.
 ble.s nostripqthru
 
 bra gotoendthru
 
 CNOP 0,4
drawwalldimthruPACK0:
 and.w d7,d4
 move.b 1(a5,d4.w*2),d1
 and.b #31,d1
 beq.s .holey
 move.w (a4,d1.w*2),(a3)
.holey:
 adda.w d0,a3
 add.l d3,d4
 addx.w d2,d4
 dbra d6,drawwallthruPACK0
 rts
 CNOP 0,4
drawwallthruPACK0:
 and.w d7,d4
 move.b 1(a5,d4.w*2),d1
 and.b #31,d1
 beq.s .holey
 move.w (a2,d1.w*2),(a3)
.holey:
 adda.w d0,a3
 add.l d3,d4
 addx.w d2,d4
 dbra d6,drawwalldimthruPACK0
nostripthru:
 rts

 CNOP 0,4
drawwalldimthruPACK1:
 and.w d7,d4
 move.w (a5,d4.w*2),d1
 lsr.w #5,d1
 and.w #31,d1
 beq.s .holey
 move.w (a4,d1.w*2),(a3)
.holey:
 adda.w d0,a3
 add.l d3,d4
 addx.w d2,d4
 dbra d6,drawwallthruPACK1
 rts
 CNOP 0,4
drawwallthruPACK1:
 and.w d7,d4
 move.w (a5,d4.w*2),d1
 lsr.w #5,d1
 and.w #31,d1
 beq.s .holey
 move.w (a2,d1.w*2),(a3)
.holey:
 adda.w d0,a3
 add.l d3,d4
 addx.w d2,d4
 dbra d6,drawwalldimthruPACK1
 rts

 CNOP 0,4
drawwalldimthruPACK2:
 and.w d7,d4
 move.b (a5,d4.w*2),d1
 lsr.b #2,d1
 and.b #31,d1
 beq.s .holey
 move.w (a4,d1.w*2),(a3)
.holey:
 adda.w d0,a3
 add.l d3,d4
 addx.w d2,d4
 dbra d6,drawwallthruPACK2
 rts
 CNOP 0,4
drawwallthruPACK2:
 and.w d7,d4
 move.b (a5,d4.w*2),d1
 lsr.b #2,d1
 and.b #31,d1
 beq.s .holey
 move.w (a2,d1.w*2),(a3)
.holey:
 adda.w d0,a3
 add.l d3,d4
 addx.w d2,d4
 dbra d6,drawwalldimthruPACK2
 rts


usesimplethru:
 mulu d3,d4
 
 add.l d0,d4
 swap d4
 add.w totalyoff(pc),d4
 
cliptopusesimplethru
 moveq #63,d7
 move.w #104*4,d0
 moveq #0,d1
 cmp.l a4,a2
 blt.s usea2thru
 move.l a4,a2
usea2thru:
 and.w d7,d4
 
 move.l d2,d5
 clr.w d5
 
 cmp.b #1,StripData+1
 dbge d6,simplewallthruiPACK0
 dbne d6,simplewallthruiPACK1
 dble d6,simplewallthruiPACK2
 rts

 CNOP 0,4
simplewallthruiPACK0:
 move.b 1(a5,d4.w*2),d1
 and.b #31,d1
 move.w (a2,d1.w*2),d3
simplewallthruPACK0:
 move.w d3,(a3)
 adda.w d0,a3
 add.l d5,d4
 bcc.s noreadthruPACK0
maybeholePACK0
 addx.w d2,d4
 and.w d7,d4
 move.b 1(a5,d4.w*2),d1
 and.b #31,d1
 beq.s holeysimplePACK0
 move.w (a2,d1.w*2),d3
 dbra d6,simplewallthruPACK0
 rts
noreadthruPACK0:
 addx.w d2,d4
 dbra d6,simplewallthruPACK0
 rts

 CNOP 0,4
simplewallholePACK0:
 adda.w d0,a3
 add.l d5,d4
 bcs.s maybeholePACK0
 addx.w d2,d4
holeysimplePACK0
 and.w d7,d4
 dbra d6,simplewallholePACK0
 rts

 CNOP 0,4
simplewallthruiPACK1:
 move.w (a5,d4.w*2),d1
 lsr.w #5,d1
 and.w #31,d1
 move.w (a2,d1.w*2),d3
 simplewallthruPACK1:
 move.w d3,(a3)
 adda.w d0,a3
 add.l d5,d4
 bcc.s noreadthruPACK1
maybeholePACK1
 addx.w d2,d4
 and.w d7,d4
 move.w (a5,d4.w*2),d1
 lsr.w #5,d1
 and.w #31,d1
 beq.s holeysimplePACK1
 move.w (a2,d1.w*2),d3
 dbra d6,simplewallthruPACK1
 rts
noreadthruPACK1:
 addx.w d2,d4
 dbra d6,simplewallthruPACK1
 rts

 CNOP 0,4
simplewallholePACK1:
 adda.w d0,a3
 add.l d5,d4
 bcs.s maybeholePACK1
 addx.w d5,d4
holeysimplePACK1
 and.w d7,d4
 dbra d6,simplewallholePACK1
 rts


 CNOP 0,4
simplewallthruiPACK2:
 move.b (a5,d4.w*2),d1
 lsr.b #2,d1
 and.b #31,d1
 move.w (a2,d1.w*2),d3
simplewallthruPACK2:
 move.w d3,(a3)
 adda.w d0,a3
 add.l d5,d4
 bcc.s noreadthruPACK2
maybeholePACK2
 addx.w d2,d4
 and.w d7,d4
 move.b (a5,d4.w*2),d1
 lsr.b #2,d1
 and.b #31,d1
 beq.s holeysimplePACK2
 move.w (a2,d1.w*2),d3
 dbra d6,simplewallthruPACK2
 rts
noreadthruPACK2:
 addx.w d2,d4
 dbra d6,simplewallthruPACK2
 rts

 CNOP 0,4
simplewallholePACK2
 adda.w d0,a3
 add.l d5,d4
 bcs.s maybeholePACK2
 addx.w d2,d4
holeysimplePACK2
 and.w d7,d4
 dbra d6,simplewallholePACK2
 rts


gotoendthru:
 add.l timeslargethru(pc,d5.w*4),a3 
 move.w d5,d4
 move.l 4(a1,d2.w*8),d0
 move.l (a1,d2.w*8),d2
 moveq #0,d3
 move.w d2,d3
 swap d2
 tst.w d2
 bne.s .notsimple
 cmp.l #$b000,d3
 ble usesimplethru
.notsimple:
 
 mulu d3,d4
 muls d2,d5
 add.l d0,d4
 swap d4
 add.w d5,d4
 add.w wallyoff(pc),d4
cliptopthru
 moveq #63,d7
 move.w #104*4,d0
 moveq #0,d1
 
 move.l d2,d3
 clr.w d3

 cmp.b #1,StripData+1
 dbge d6,drawwallthruPACK0
 dbne d6,drawwallthruPACK1
 dble d6,drawwallthruPACK2
 
 rts

timeslargethru:

val SET 104*4
 REPT 80
 dc.l val
val SET val+104*4
 ENDR

totalyoff: dc.w 0
wallyoff: dc.w 0

******************************************
* Wall polygon
leftend: dc.w 0
wallbrightoff: dc.w 0
wallleftpt: dc.w 0
wallrightpt: dc.w 0
WHICHPBR: dc.w 0
WHICHLEFTPT: dc.w 0
WHICHRIGHTPT: dc.w 0
OTHERZONE: dc.w 0

itsawalldraw:

 move.l #Rotated,a5
 move.l #OnScreen,a6
 
 move.w (a0)+,d0
 move.w (a0)+,d2
 
 move.w d0,wallleftpt
 move.w d2,wallrightpt
 
 move.b (a0)+,WHICHLEFTPT+1
 move.b (a0)+,WHICHRIGHTPT+1
 move.w #0,leftend
 moveq #0,d5
 move.w (a0)+,d5
 move.w (a0)+,d1
 asl.w #4,d1
 move.w d1,fromtile
 
 move.w (a0)+,d1
 move.w d1,totalyoff
 
 move.w (a0)+,d1
 move.l #walltiles,a3
 move.l (a3,d1.w*4),a3
 move.l a3,PaletteAddr
 add.l #64*32,a3
 move.l a3,ChunkAddr
 
 ;move.w (a0)+,d1
 ;add.w ZoneBright,d1
 move.w ZoneBright,angbright
 ;move.w (a0)+,d1
 ;move.w (a0)+,d4
 move.l yoff,d6
 
 move.b (a0)+,VALAND+1
 move.b (a0)+,VALSHIFT+1
 moveq #0,d1
 move.b (a0)+,d1
 move.w d1,HORAND
 move.b (a0)+,WHICHPBR
 
 move.w totalyoff,d1
 add.w wallyoff,d1
 and.w VALAND,d1
 move.w d1,totalyoff
 
 move.l (a0)+,topofwall
 sub.l d6,topofwall
 move.l (a0)+,botofwall
 sub.l d6,botofwall
 
 
 move.b (a0)+,wallbrightoff
 move.b (a0)+,OTHERZONE+1

 move.l topofwall,d3
 cmp.l botofwall,d3
 bge wallfacingaway

 
 tst.w 6(a5,d0*8)
 bgt.s cantell
 tst.w 6(a5,d2*8)
 ble wallfacingaway
 bra cliptotestfirstbehind
cantell:
 tst.w 6(a5,d2*8)
 ble.s cliptotestsecbehind
 bra pastclip
cliptotestfirstbehind:

 move.l (a5,d0*8),d3
 sub.l (a5,d2*8),d3
 move.w 6(a5,d0*8),d6
 sub.w 6(a5,d2*8),d6
 divs d6,d3
 muls 6(a5,d2*8),d3
 neg.l d3
 add.l (a5,d2*8),d3
 move.w (a6,d2*2),d6
 sub.w MIDDLEX,d6
 ext.l d6
 cmp.l d6,d3
 bge wallfacingaway
 bra cant_tell
 bra pastclip
 
cliptotestsecbehind:

 move.l (a5,d2*8),d3
 sub.l (a5,d0*8),d3
 move.w 6(a5,d2*8),d6
 sub.w 6(a5,d0*8),d6
 divs d6,d3
 muls 6(a5,d0*8),d3
 neg.l d3
 add.l (a5,d0*8),d3
 move.w (a6,d0*2),d6
 sub.w MIDDLEX,d6
 ext.l d6
 cmp.l d6,d3
 ble wallfacingaway
 bra cant_tell

pastclip:
 
 move.w (a6,d0*2),d3
 cmp.w RIGHTX,d3
 bge wallfacingaway
 cmp.w (a6,d2*2),d3
 bge wallfacingaway
 tst.w (a6,d2*2)
 blt wallfacingaway

cant_tell:

; move.l a1,a4
; move.w #31,d6
; move.l #0,d3
;.emptylop:
; move.l d3,(a4)+
; dbra d6,.emptylop

; move.w rightclip(pc),d6
; st (a1,d6)
; move.w leftclip(pc),d6
; st -1(a1,d6)
 
; muls sinval(pc),d1
; muls cosval(pc),d4
; add.l d1,d4
; add.l d4,d4
; swap d4
; neg.w d4
; move.w d4,d6
; asr.w #1,d4
; sub.w d4,angbright
; and.b #$fe,d4
; asl.w #2,d4
; asl.w #2,d6
 
 movem.l d7/a0/a5/a6,-(a7)
 move.l (a5,d0*8),a0
; add.l a0,a0
 move.w 6(a5,d0*8),d1
 move.l (a5,d2*8),a2
; add.l a2,a2
 move.w 6(a5,d2*8),d3
 
 move.l #CurrentPointBrights,a5
 
 move.w currzone,d0
 move.b WHICHPBR,d4
 btst #3,d4
 beq.s .nototherzone 
 move.w OTHERZONE,d0
.nototherzone

 and.w #7,d4
 muls #40,d0
 add.w d0,d4

 move.w WHICHLEFTPT,d0
 asl.w #2,d0
 add.w d4,d0

 move.w (a5,d0.w*2),d0
 add.w #300,d0
 add.w wallbrightoff,d0
 move.w d0,leftwallbright

 move.w WHICHRIGHTPT,d0
 asl.w #2,d0
 add.w d4,d0
 move.w (a5,d0.w*2),d0
 add.w #300,d0
 add.w wallbrightoff,d0
 move.w d0,rightwallbright

 move.w currzone,d0
 move.b WHICHPBR,d4
 lsr.w #4,d4
 btst #3,d4
 beq.s .nototherzone2 
 move.w OTHERZONE,d0
.nototherzone2

 and.w #7,d4
 muls #40,d0
 add.w d0,d4

 move.w WHICHLEFTPT,d0
 asl.w #2,d0
 add.w d4,d0

 move.w (a5,d0.w*2),d0
 add.w #300,d0
 add.w wallbrightoff,d0
 move.w d0,leftwallTOPbright

 move.w WHICHRIGHTPT,d0
 asl.w #2,d0
 add.w d4,d0
 move.w (a5,d0.w*2),d0
 add.w #300,d0
 add.w wallbrightoff,d0
 move.w d0,rightwallTOPbright

 move.w leftend(pc),d4
 move.l #max3ddiv,d7

 move.w rightwallTOPbright,d0
 cmp.w rightwallbright,d0
 bne.s gottagour
 move.w leftwallTOPbright,d0
 cmp.w leftwallbright,d0
 bne.s gottagour
 
 bsr walldraw
 bra.s nottagour
 
gottagour:
 bsr walldrawGOUR
nottagour:
 movem.l (a7)+,d7/a0/a5/a6

wallfacingaway:

 rts

PointBrightsPtr: dc.l 0
midpt: dc.l 0
dist1: dc.l 0
dist2: dc.l 0
VALAND: dc.w 0
VALSHIFT: dc.w 0
HORAND: dc.w 0

sinval: dc.w 0
cosval: dc.w 0

oldxoff: dc.w 0
oldzoff: dc.w 0

topclip: dc.w 0
botclip: dc.w 0
seethru: dc.w 0
