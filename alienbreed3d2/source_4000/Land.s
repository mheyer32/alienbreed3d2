
 


maxscrdiv EQU 8
max3ddiv EQU 5

zsinval EQU 8	;w
zcosval EQU 10	;w
ztox EQU 12	;l
xsinval EQU 16	;w
xcosval EQU 18	;w
xspd EQU 20	;w
zspd EQU 22	;w
mapx EQU 24	;b
mapz EQU 25	;b
whichtile EQU 26 ;b
xofflight EQU 28	;w
zofflight EQU 30	;w
offlight EQU 32		;w
zlinestore EQU 34
zlinedir EQU 38
zposdir EQU 40
zposstore EQU 42
xdiststore EQU 44
xdistdir EQU 46
zwallfound EQU 48

xlinestore EQU 50
xlinedir EQU 54
xposdir EQU 56
xposstore EQU 58
zdiststore EQU 60
zdistdir EQU 62
xwallfound EQU 64


midoffset EQU 104*4*40

 SECTION Scrn,CODE_F

OpenLib         equ -552        ; Offset for OpenLibrary.
CloseLib        equ -414        ; Offset for CloseLibrary.

vhposr		equ $006
vhposrl		equ $007 
bltcon0		equ $40
bltcon1		equ $42
bltcpt		equ $48
bltbpt		equ $4c
bltapt		equ $50
spr0ctl		equ $142
spr1ctl		equ $14a
spr2ctl		equ $152
spr3ctl		equ $15a
spr4ctl		equ $162
spr5ctl		equ $16a
spr6ctl		equ $172
spr7ctl		equ $17a
spr0pos		equ $140
spr1pos		equ $148
spr2pos		equ $150
spr3pos		equ $158
spr4pos		equ $160
spr5pos		equ $168
spr6pos		equ $170
spr7pos		equ $178
bltdpt     	equ $54
bltafwm		equ $44
bltalwm		equ $46
bltsize     	equ $58
bltcmod     	equ $60
bltbmod     	equ $62
bltamod     	equ $64
bltdmod     	equ $66
diwstart        equ $8e         ; Screen hardware registers.
diwstop         equ $90
ddfstart        equ $92
ddfstop         equ $94
bplcon0         equ $100
bplcon1         equ $102
col0            equ $180
col1            equ $182
col2		equ $184
col3		equ $186
col4		equ $188
col5		equ $18a
col6		equ $18c
col7		equ $18e
col8            equ $190
col9            equ $192
col10           equ $194
dmacon		equ $96
dmaconr		equ $002
intenar		equ $01c
intena		equ $09a
intreq		equ $09c
intreqr		equ $01e
intreqrl	equ $01f
bpl1pth         equ $e0
bpl1ptl         equ $e2
bpl2pth		equ $e4
bpl2ptl		equ $e6
bpl3pth		equ $e8
bpl3ptl		equ $ea
bpl4pth		equ $ec
bpl4ptl		equ $ee
bpl5pth		equ $f0
bpl5ptl		equ $f2
bpl6pth		equ $f4
bpl6ptl		equ $f6
bpl7pth		equ $f8
bpl7ptl		equ $fa

** This waits for the blitter to finish before allowing program
** execution to continue.

WB MACRO
\@bf:
 btst #6,dmaconr(a6)
 bne.s \@bf
 ENDM

*Another version for when d6 <> dff000

WBSLOW MACRO
\@bf:
 btst #6,$dff000+dmaconr
 bne.s \@bf
 ENDM

 
**

 include "macros.i"

 move.w (a0),option

 jmp stuff
endstuff:

 move.l #$dff000,a6    ; NB V. IMPORTANT: A6=CUSTOM BASE
 move.w #$87c0,dmacon(a6)
 move.w #$0020,dmacon(a6)
 move.w intenar(a6),saveinters
 move.w #$7fff,intena(a6)
 move.w #$c010,intena(a6)

*** Put myself in supervisor mode

 move.w #$20,$dff1dc

 jmp blag

; move.l #blag,$80
; trap #0
; rts
 
saveit: dc.l 0

blag:
 move.w #$10,intreq(a6)
 move.w #$7fff,intena(a6)


 move.l #bigfield,$dff080    ; Point the copper at our copperlist.
 move.l #$dff000,a6    ; a6 points at the first custom chip register.

 move.w #0,d0

 move.l #scrn,d0
 move.w d0,pl1l
 swap d0
 move.w d0,pl1h

 move.l #scrn+40,d0
 move.w d0,pl2l
 swap d0
 move.w d0,pl2h

 move.l #scrn+80,d0
 move.w d0,pl3l
 swap d0
 move.w d0,pl3h

 move.l #scrn+120,d0
 move.w d0,pl4l
 swap d0
 move.w d0,pl4h

 move.l #scrn+160,d0
 move.w d0,pl5l
 swap d0
 move.w d0,pl5h

 move.l #scrn+200,d0
 move.w d0,pl6l
 swap d0
 move.w d0,pl6h

 move.l #scrn+240,d0
 move.w d0,pl7l
 swap d0
 move.w d0,pl7h

 move.l #colbars,a0
 move.l #colbars2,a2
 move.w #127,d0
 move.l #0,d6
 move.w #0,d3
 move.w #$2bdf,startwait
 move.w #$2d01,endwait
fillcop
 move.w #$180,d1

 move.l a0,a1
 move.l a2,a3
 move.w #$10c,(a1)+
 move.w #$10c,(a3)+
 move.w d3,(a1)+
 move.w d3,(a3)+
 eor.w #$8000,d3

 move.w #$106,(a1)+
 move.w #$106,(a3)+
 move.w #$2c40,d5
 or.w d3,d5
 move.w d5,(a1)+
 move.w d5,(a3)+
 bsr do32

 move.w #$106,(a1)+
 move.w #$106,(a3)+
 move.w #$4c40,d5
 or.w d3,d5
 move.w d5,(a1)+
 move.w d5,(a3)+
 bsr do32

 move.w #$106,(a1)+
 move.w #$106,(a3)+
 move.w #$6c40,d5
 or.w d3,d5
 move.w d5,(a1)+
 move.w d5,(a3)+
 bsr do32
 
**********************************

 cmp.b #'s',option
 beq.s smallscrn

 move.w startwait,(a1)+
 move.w #$fffe,(a1)+
 move.w endwait,(a1)+
 move.w #$ff00,(a1)+
 move.w startwait,(a3)+
 move.w #$fffe,(a3)+
 move.w endwait,(a3)+
 move.w #$ff00,(a3)+
 
 add.w #$300,startwait
 add.w #$300,endwait
 
smallscrn: 
**********************************

 adda.w #104*4,a0
 adda.w #104*4,a2

 dbra d0,fillcop

**********************************
 cmp.b #'s',option
 beq smallnotlarge
 move.w #$38,fetchstart
 move.w #$b8,fetchstop
 move.w #$2c81,winstart
 move.w #$2cc1,winstop
 move.w #-40,modulo
 move.w #-40,modulo+4
 
 move.l #scrn+40,a0
 move.l #scrn+160,a1
 move.l #scrn+280,a2
 move.l #scrntab,a3
 move.w #319,d7	; counter
 move.w #0,d1	; xpos
plotscrnloop:
 move.b (a3)+,d0
 move.w d1,d2
 asr.w #3,d2
 move.b d1,d3
 not.b d3
 bclr.b d3,-40(a0,d2.w)
 bclr.b d3,(a0,d2.w)
 bclr.b d3,40(a0,d2.w)
 bclr.b d3,-40(a1,d2.w)
 bclr.b d3,(a1,d2.w)
 bclr.b d3,40(a1,d2.w)
 bclr.b d3,-40(a2,d2.w)
 btst #0,d0
 beq.s nobp1
 bset.b d3,-40(a0,d2.w)
nobp1:
 btst #1,d0
 beq.s nobp2
 bset.b d3,(a0,d2.w)
nobp2:
 btst #2,d0
 beq.s nobp3
 bset.b d3,40(a0,d2.w)
nobp3:
 btst #3,d0
 beq.s nobp4
 bset.b d3,-40(a1,d2.w)
nobp4:
 btst #4,d0
 beq.s nobp5
 bset.b d3,(a1,d2.w)
nobp5:
 btst #5,d0
 beq.s nobp6
 bset.b d3,40(a1,d2.w)
nobp6:
 btst #6,d0
 beq.s nobp7
 bset.b d3,-40(a2,d2.w)
nobp7:

 addq #1,d1

 dbra d7,plotscrnloop

smallnotlarge:

**********************************

****************************
; bsr initobjpos
****************************
 
lop: 

 move.l #$dff000,a6

waitfortop:
 btst.b #0,intreqrl(a6)
 beq waitfortop
 move.w #$1,intreq(a6)


 move.l drawpt,d0
 move.l olddrawpt,drawpt
 move.l d0,olddrawpt
 move.l d0,$dff084
 move.l drawpt,a3
 adda.w #10,a3
 move.l a3,frompt
 add.l #104*4*40,a3
 move.l a3,midpt

 move.l #landfile,a1
 move.l #landpic,a5
 move.l frompt,a0
 move.l #104*4,d0
 move.l #landcheat+(48+90)*4,a2
 
 move.w angspd,d1
 move.w ang,d0

 move.w #2,d7

 move.w d1,d2
 neg.w d2
 cmp.w d7,d2
 ble.s okslow
 move.w d7,d2
okslow
 neg.w d7
 cmp.w d7,d2
 bge.s okslo
 move.w d7,d2
okslo:

 asr.w #1,d7

 btst #1,$d(a6)
 sne d3
 beq.s notleft
 move.w d7,d2
 neg.w d2
; tst.w d1
; bge.s notleft
; moveq #0,d1
notleft

 btst #1,$c(a6)
 sne d4
 beq.s notright
 move.w d7,d2
; tst.w d1
; ble.s notright
; moveq #0,d1
notright

 move.w #0,Spd

 btst #0,$dff00c
 sne d5
 eor.b d4,d5
 beq.s notup
 move.w #4,Spd
notup:

 btst #0,$dff00d
 sne d5
 eor.b d3,d5
 beq.s notdown
 move.w #-4,Spd
notdown:

 move.w Spd,d7

 add.w d2,d1
 cmp.w #-10,d1
 bge.s okspdlft
 move.w #-10,d1
okspdlft:
 cmp.w #10,d1
 ble.s okspdrgt
 move.w #10,d1
okspdrgt:

 move.w d1,angspd
 add.w d1,d0
 ext.l d0
 add.l #360,d0
 divs #360,d0
 swap d0
 move.w d0,ang
 
 lea (a2,d0.w*4),a2
 move.l (a2),d0
 asr.l #8,d0
 move.w d0,tempx

 muls d0,d7
 add.w d7,zpos
 
 suba.w #90*4,a2
 move.l (a2),temp
 suba.w #48*4,a2
 
 move.w Spd,d7
 add.w d7,d7
 move.l temp,d0
 asr.l #1,d0
 muls d0,d7
 asr.l #8,d7
 add.w d7,xpos
 
 move.w zpos,d7
 move.b xpos,d7
 move.w d7,zoff

 move.w #2,d7
 moveq #0,d4
 moveq #0,d1
 moveq #0,d6
 move.w zoff,d6
 moveq #0,d0
 move.b (a1,d6.l),d0
 sub.b #160,d0
 
; d0 = targyoff

 move.w yoff,d1
 sub.w d1,d0
 bgt.s notinfloor
 add.w d0,d1
 asl.w #1,d0
 
 cmp.w yvel,d0
 bge.s nopushup
 
 move.w d0,yvel
nopushup:
notinfloor:
 move.w yvel,d0
 asr.w #2,d0
 add.w d0,d1
 
 bge.s okoffset
 move.w #0,d1
okoffset:
 
 and.w #$ff,d1
 move.w d1,yoff
 
 add.w #4,yvel

donemovey
 
 move.l #heightcheat,a6
 move.w yoff,d0
 sub.w d0,a6
 move.w #256,d5
 move.l frompt,a4
 add.l #100*104*4,a4

 move.l #skypic,skyaddr
 
 move.w ang,d2
 
 muls #320,d2
 add.l d2,skyaddr

 move.l #landpal+512*5,a3

 bsr doblock
 addq #4,a4
 bsr doblock
 addq #4,a4
 bsr doblock

 move.l #$dff000,a6

 btst #6,$bfe001
 beq end

 bra lop
 
end:
 move.w #$f8e,$dff1dc
 jmp closeeverything 

spd: dc.w 0
ang: dc.w 0
angspd: dc.w 0
tempx: dc.l 0
zoff: dc.w 0
option: dc.w 0
temp: dc.l 0

yvel: dc.w 0

xpos: dc.w 0
zpos: dc.w 0

doblock:
 move.w #31,d3
acrossl:
 move.l 90*4(a2),d5
 asr.l #8,d5
 move.l (a2)+,a0
 add.l temp(pc),a0
 add.w tempx(pc),d5
 moveq #0,d7
 swap d3
 move.w zoff(pc),d3
 move.w d6,-(a7)
 moveq #0,d4
 swap d6
 clr.w d6
 move.l a6,-(a7)
 move.l a4,-(a7)
 swap d5
 move.w #14,d5
 moveq.l #89,d2
outerland:
 swap d5
putinland:
 move.w d3,d4
 swap d6
 move.b d6,d4
 swap d6
 add.l a0,d6
 add.w d5,d3
 move.b (a1,d4.l),d1
 move.b (a6,d1.w),d0
 	
 sub.b d7,d0
 ble.s allbehind 
 swap d2
 add.b d0,d7
 move.b (a5,d4.l),d2
 move.w (a3,d2.w*2),d4
upstrip
 move.w d4,(a4)
 suba.w #104*4,a4
 subq #1,d0
 bgt.s upstrip
 swap d2

allbehind:
 adda.w #256,a6
 dbra d2,putinland 

 swap d5
 moveq.l #3,d2
 adda.w #512,a3
 dbra d5,outerland
 
 move.l #landpal,a3

 move.l skyaddr(pc),a6
 move.w #99,d2
 sub.w d7,d2
 ble.s noclrbit
 lea (a6,d2.w*2),a6
clrbit:
 move.w -(a6),(a4)
 suba.w #104*4,a4
 subq #1,d2
 bgt.s clrbit
noclrbit:
 
 move.l skyaddr,d2
 add.l #160,d2
 cmp.l #endsky,d2
 blt.s nobacktobeginning

 move.l #skypic,d2

nobacktobeginning:
 move.l d2,skyaddr
 
 move.l (a7)+,a4
 move.l (a7)+,a6
 move.w (a7)+,d6
 addq #4,a4
 swap d3
 dbra d3,acrossl
 rts

skyaddr: dc.l 0

do32:
 move.w #31,d7
 move.w #$180,d1
across:
 move.w d1,(a1)+
 move.w d1,(a3)+
 move.w #0,(a1)+
 move.w #0,(a3)+
 add.w #2,d1
 dbra d7,across
 rts


 
*************************************
* Set left and right clip values
*************************************
 

everyframe:

 move.w #$0010,$dff000+intreq

 rte

saveinters:  
 dc.w 0

z: dc.w 10
midpt: dc.l 0

test: dc.l 0
 ds.l 30

drawpt: dc.l colbars2
olddrawpt: dc.l colbars
frompt: dc.l colbars2 

Spd:
angpos: dc.w 0
wallyoff: dc.w 0
flooryoff: dc.w 0
xoff: dc.l 0
yoff: dc.w 255-160
tyoff: dc.l 0


liftanimtab:

endliftanimtab:

Roompt: dc.l 0
OldRoompt: dc.l 0

wallpt: dc.l 0
floorpt: dc.l 0

Rotated:
 ds.l 800 

OnScreen:
 ds.l 800 
 
startwait: dc.w 0
endwait: dc.w 0


landcheat: incbin "work:inc/smallcheatfile"
landfile: incbin "work:inc/landfile"
heightcheat: incbin "work:inc/heightcheat"
landpic: incbin "work:inc/landpic"
landpal: incbin "work:inc/landpal"

skypic: dcb.w 160*360,$742
endsky:
 
 SECTION ffff,CODE_C

bigfield:                    ; Start of our copper list.

 dc.w intreq,$8001
 dc.w $1fc,$3
 dc.w diwstart
winstart: dc.w $2cb1
 dc.w diwstop
winstop: dc.w $2c91
 dc.w ddfstart
fetchstart: dc.w $48
 dc.w ddfstop
fetchstop: dc.w $88

 dc.w bplcon0,$7201
 dc.w bplcon1
smoff:
 dc.w $0

 dc.w col0,0

 dc.w $108
modulo: dc.w -24
 dc.w $10a,-24

 dc.w bpl1pth
pl1h
 dc.w 0

 dc.w bpl1ptl
pl1l
 dc.w 0

 dc.w bpl2pth
pl2h
 dc.w 0

 dc.w bpl2ptl
pl2l
 dc.w 0

 dc.w bpl3pth
pl3h
 dc.w 0

 dc.w bpl3ptl
pl3l
 dc.w 0

 dc.w bpl4pth
pl4h
 dc.w 0

 dc.w bpl4ptl
pl4l
 dc.w 0

 dc.w bpl5pth
pl5h
 dc.w 0

 dc.w bpl5ptl
pl5l
 dc.w 0

 dc.w bpl6pth
pl6h
 dc.w 0

 dc.w bpl6ptl
pl6l
 dc.w 0

 dc.w bpl7pth
pl7h
 dc.w 0

 dc.w bpl7ptl
pl7l
 dc.w 0


 dc.w $1001,$ff00
 dc.w intreq,$1
yposcop:
 dc.w $2a11,$fffe
 dc.w $8a,0
 
 dcb.l 104*40,$1fe0000
colbars:
val SET $2a
 dcb.l 104*128,$1fe0000
 
 dc.w $ffff,$fffe       ; End copper list.

old dc.l 0

 dcb.l 104*40,$1fe0000

colbars2:
val SET $2a
 dcb.l 104*128,$1fe0000
 
 dc.w $106,$c40
 dc.w $180
signal: dc.w 0
 
 dc.w $ffff,$fffe       ; End copper list.

 dc.w $0


********************************************
* Stuff you don't have to worry about yet. *
********************************************

closeeverything:
 move.l old,$dff080     ; Restore old copper list.
 move.w #$8020,dmacon(a6)
 move.w saveinters,d0
 or.w #$c000,d0
 move.w d0,intena(a6)
 clr.w $dff0a8
 clr.w $dff0b8
 clr.w $dff0c8
 clr.w $dff0d8
 rts

stuff:
 move.l 4.w,a6          ; Get EXECBASE.
 lea gfxname(PC),a1     ; Point to 'graphics.library' string.
 moveq #0,d0            ; Ignore version number.
 jsr OpenLib(a6)        ; Open the library.
 move.l d0,a1           ; Store library address.
 move.l 38(a1),old      ; Store workbench copper address.
 move.l 4.w,a6          ; Get EXECBASE again.	
 jsr CloseLib(a6)       ; Close the library.

 jmp endstuff

gfxname dc.b "graphics.library",0

scrntab:
 ds.b 16
val SET 32
 REPT 96
 dc.b val,val,val
val SET val+1
 ENDR
 ds.b 16

 cnop 0,64
scrn:

 dcb.l 8,$33333333
 dc.l 0
 dc.l 0
 
 dcb.l 8,$0f0f0f0f
 dc.l 0
 dc.l 0

 dcb.l 8,$00ff00ff
 dc.l 0
 dc.l 0
 
 dcb.l 8,$0000ffff
 dc.l 0
 dc.l 0
 
 dc.l 0,-1,0,-1,0,-1,0,-1
 dc.l 0
 dc.l 0
 
 dc.l -1,-1,0,0,-1,-1,0,0
 dc.l 0
 dc.l 0
 
 dc.l 0,0,-1,-1,-1,-1,-1,-1
 dc.l 0
 dc.l 0
 


