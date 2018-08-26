

maxscrdiv EQU 8
max3ddiv EQU 5
playerheight EQU 12*1024
scrheight EQU 80

xpos EQU 0	;l
zpos EQU 4	;l
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

 SECTION Scrn,CODE 
OpenLib         equ -552
CloseLib        equ -414

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
spr0pth		equ $120
spr0ptl		equ $122
spr1pth		equ $124
spr1ptl		equ $126
spr2pth		equ $128
spr2ptl		equ $12a
spr3pth		equ $12c
spr3ptl		equ $12e
spr4pth		equ $130
spr4ptl		equ $132
spr5pth		equ $134
spr5ptl		equ $136
spr6pth		equ $138
spr6ptl		equ $13a
spr7pth		equ $13c
spr7ptl		equ $13e


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
 include "ab3:source/defs.i"

 move.w (a0)+,option
 move.w (a0)+,option+2

* Load level into buffers.
 move.l 4.w,a6
 move.l #doslibname,a1
 moveq #0,d0
 jsr -552(a6)
 move.l d0,doslib

 move.l d0,a6
 move.l #LDname,d1
 move.l #1005,d2
 jsr -30(a6)
 move.l d0,LDhandle

 move.l doslib,a6
 move.l d0,d1
 move.l #LEVELDATA,d2
 move.l #50000,d3
 jsr -42(a6)

 move.l doslib,a6
 move.l LDhandle,d1
 jsr -36(a6)

********

 move.l doslib,a6
 move.l #LGname,d1
 move.l #1005,d2
 jsr -30(a6)
 move.l d0,LGhandle

 move.l doslib,a6
 move.l d0,d1
 move.l #LEVELGRAPHICS,d2
 move.l #15000,d3
 jsr -42(a6)

 move.l doslib,a6
 move.l LGhandle,d1
 jsr -36(a6)

********

 move.l doslib,a6
 move.l #LCname,d1
 move.l #1005,d2
 jsr -30(a6)
 move.l d0,LChandle

 move.l doslib,a6
 move.l d0,d1
 move.l #LEVELCLIPS,d2
 move.l #34000,d3
 jsr -42(a6)

 move.l doslib,a6
 move.l LChandle,d1
 jsr -36(a6)

*******

 move.l doslib,d0
 move.l d0,a1
 move.l 4.w,a6
 jsr CloseLib(a6)


 jmp stuff
endstuff:

 move.l #$dff000,a6    ; NB V. IMPORTANT: A6=CUSTOM BASE
 move.w #$87c0,dmacon(a6)
 move.w #$8020,dmacon(a6)
 move.w intenar(a6),saveinters
 move.w #$7fff,intena(a6)
 move.w #$00ff,$dff09e

*** Put myself in supervisor mode

 move.l #blag,$80
 trap #0
; move.l $6c,d0
; move.l #blag,$6c
; move.w #$8010,intreq(a6)

 rts
 
saveit: ds.l 10
doslibname: dc.b 'dos.library',0
 even
doslib: dc.l 0

LDname: dc.b 'ab3:includes/newlev.bin',0
 even
LDhandle: dc.l 0
LGname: dc.b 'ab3:includes/newlev.graph.bin',0
 even
LGhandle: dc.l 0
LCname: dc.b 'ab3:includes/newlev.clips',0
 even
LChandle: dc.l 0

blag:
; move.w #$10,intreq(a6)
; move.l d0,$6c
; move.w #$7fff,intena(a6)

 move.w #$20,$dff1dc

 move.l $6c,saveit
 move.l #Chan0inter,$6c
 jsr KInt_Init
 

 
****************************
* Initialize level
****************************
* Poke all clip offsets into
* correct bit of level data.
****************************
 lea.l LEVELGRAPHICS,a0
 move.l 12(a0),a1
 add.l a0,a1
 move.l a1,ZoneGraphAdds
 move.l (a0),a1
 add.l a0,a1
 move.l a1,DoorData
 move.l 4(a0),a1
 add.l a0,a1
 move.l a1,LiftData
 move.l 8(a0),a1
 add.l a0,a1
 move.l a1,SwitchData
 adda.w #16,a0
 move.l a0,ZoneAdds

 lea.l LEVELDATA,a1
 move.l 16(a1),a2
 add.l a1,a2
 move.l a2,Points
 move.l 20(a1),a2
 add.l a1,a2
 move.l a2,FloorLines
 move.l 24(a1),a2
 add.l a1,a2
 move.l a2,ObjectData
 move.l 28(a1),a2
 add.l a1,a2
 move.l a2,PlayerShotData
 move.l 32(a1),a2
 add.l a1,a2
 move.l a2,NastyShotData
 move.l 36(a1),a2
 add.l a1,a2
 move.l a2,ObjectPoints  
 move.l 40(a1),a2
 add.l a1,a2
 move.l a2,PLR1_Obj
 move.l 44(a1),a2
 add.l a1,a2
 move.l a2,PLR2_Obj
 move.w 14(a1),NumObjectPoints

; bra noclips
  
 lea.l LEVELCLIPS,a2
 moveq #0,d0
 move.w 10(a1),d7	;numzones
assignclips:
 move.l (a0)+,a3
 add.l a1,a3	; pointer to a zone
 adda.w #ToListOfGraph,a3 ; pointer to zonelist
dowholezone:
 tst.w (a3)
 blt.s nomorethiszone
 tst.w 2(a3)
 blt.s thisonenull

 move.l d0,d1
 asr.l #2,d1
 move.w d1,2(a3)

findnextclip:
 tst.l (a2,d0)
 beq.s foundnextclip
 addq #8,d0
 bra.s findnextclip
foundnextclip
 addq #8,d0
thisonenull:
 addq #8,a3 
 bra.s dowholezone
nomorethiszone:
 dbra d7,assignclips
 
noclips:

************************************
 
 cmp.b #'k',option+3
 bne.s nkb
 st PLR1KEYS
 clr.b PLR1PATH
 clr.b PLR1MOUSE
nkb:
 cmp.b #'m',option+3
 bne.s nmc
 clr.b PLR1KEYS
 clr.b PLR1PATH
 st PLR1MOUSE
nmc:
 cmp.b #'p',option+3
 bne.s nfp
 clr.b PLR1KEYS
 st.b PLR1PATH
 clr.b PLR1MOUSE
nfp:
 
 move.l #empty,pos1
 move.l #empty,pos2
 move.l #emptyend,Samp0end
 move.l #emptyend,Samp1end
 
 move.l #nullspr,d0
 move.w d0,s4l
 move.w d0,s5l
 move.w d0,s6l
 move.w d0,s7l
 swap d0
 move.w d0,s4h
 move.w d0,s5h
 move.w d0,s6h
 move.w d0,s7h 
 
 move.l #Panel,d0
 move.w d0,p1l
 swap d0
 move.w d0,p1h
 move.l #Panel+80*24,d0
 move.w d0,p2l
 swap d0
 move.w d0,p2h
 move.l #Panel+80*24*2,d0
 move.w d0,p3l
 swap d0
 move.w d0,p3h
 move.l #Panel+80*24*3,d0
 move.w d0,p4l
 swap d0
 move.w d0,p4h
 move.l #Panel+80*24*4,d0
 move.w d0,p5l
 swap d0
 move.w d0,p5h
 
*******************************
* TIMER SCREEN SETUP
 move.l #TimerScr,d0
 move.w d0,p1l
 swap d0
 move.w d0,p1h
 move.w #$1201,Panelcon

 move.l #borders,d0
 move.w d0,s0l
 swap d0
 move.w d0,s0h
 move.l #borders+2064,d0
 move.w d0,s1l
 swap d0
 move.w d0,s1h
 move.l #borders+2064*2,d0
 move.w d0,s2l
 swap d0
 move.w d0,s2h
 move.l #borders+2064*3,d0
 move.w d0,s3l
 swap d0
 move.w d0,s3h
 
 move.w #42*256+80,borders
 move.w #42*256+2,borders+4
 move.w #42*256+80,borders+2064
 move.w #42*256+130,borders+4+2064
 move.w #42*256+192,borders+2064*2
 move.w #42*256+2,borders+4+2064*2
 move.w #42*256+192,borders+2064*3
 move.w #42*256+130,borders+4+2064*3
 
 move.l #FacePlace,d0
 move.w d0,f1l
 swap d0
 move.w d0,f1h
 move.l #FacePlace+32*24,d0
 move.w d0,f2l
 swap d0
 move.w d0,f2h
 move.l #FacePlace+32*24*2,d0
 move.w d0,f3l
 swap d0
 move.w d0,f3h
 move.l #FacePlace+32*24*3,d0
 move.w d0,f4l
 swap d0
 move.w d0,f4h
 move.l #FacePlace+32*24*4,d0
 move.w d0,f5l
 swap d0
 move.w d0,f5h
 
 move.l #Blurb,d0
 move.w d0,bl1l
 swap d0
 move.w d0,bl1h
 
 move.l #PanelCop,d0
 move.w d0,pcl1
 move.w d0,pcl2
 swap d0
 move.w d0,pch1
 move.w d0,pch2
 
 move.l #bigfield,d0
 move.w d0,ocl
 swap d0
 move.w d0,och

 bset.b #1,$bfe001

 move.l #bigfield,$dff080    ; Point the copper at our copperlist.
 move.l #$dff000,a6    ; a6 points at the first custom chip register.
 move.w #$00ff,$dff09e

; move.l #Blurbfield,$dff080

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
 move.w #scrheight-1,d0
 move.l #0,d6
 move.w #1,d3
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
 move.w #$2c42,d5
 or.w d3,d5
 and.w #$fffe,d5
 move.w d5,(a1)+
 move.w d5,(a3)+
 bsr do32

 move.w #$106,(a1)+
 move.w #$106,(a3)+
 move.w #$4c42,d5
 or.w d3,d5
 and.w #$fffe,d5
 move.w d5,(a1)+
 move.w d5,(a3)+
 bsr do32

 move.w #$106,(a1)+
 move.w #$106,(a3)+
 move.w #$6c42,d5
 or.w d3,d5
 and.w #$fffe,d5
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
 jsr INITPLAYER
; bsr initobjpos
****************************
 
 move.l #null,$dff0a0
 move.w #100,$dff0a4
 move.w #443,$dff0a6
 move.w #63,$dff0a8

 move.l #null2,$dff0b0
 move.w #100,$dff0b4
 move.w #443,$dff0b6
 move.w #63,$dff0b8

 move.l #null4,$dff0c0
 move.w #100,$dff0c4
 move.w #443,$dff0c6
 move.w #63,$dff0c8

 move.l #null3,$dff0d0
 move.w #100,$dff0d4
 move.w #443,$dff0d6
 move.w #63,$dff0d8

 move.l #tab,a1
 move.w #64,d7
 move.w #0,d6
outerlop
 move.l #pretab,a0
 move.w #255,d5
scaledownlop:
 move.b (a0)+,d0
 ext.w d0
 ext.l d0
 muls d6,d0
 asr.l #6,d0
 move.b d0,(a1)+
 dbra d5,scaledownlop
 addq #1,d6
 dbra d7,outerlop
 
 move.l #$dff000,a6

 move.w #$c018,intena(a6)
 
 move.w #$f,dmacon(a6)
 move.w #$820f,dmacon(a6)
 
 bsr FullEnergy
 move.b #1,PLR1_GunDamage
 move.b #1,PLR2_GunDamage
 move.w #3,PLR1_GunNoise
 move.w #3,PLR2_GunNoise
 
; move.w #$20,$1dc(a6)
 
 move.w #$0,$dff034
 move.w #0,Conditions
 
 
lop: 

 move.l #$dff000,a6

 move.l drawpt,d0
 move.l olddrawpt,drawpt
 move.l d0,olddrawpt
 move.l d0,$dff084
 move.l drawpt,a3
 adda.w #10,a3
 move.l a3,frompt
 add.l #104*4*40,a3
 move.l a3,midpt

waitfortop:
 btst.b #0,intreqrl(a6)
 beq waitfortop
 move.w #$1,intreq(a6)

 move.b SpaceTapped,SPCTAP
 clr.b SpaceTapped

 move.l waterpt,a0
 move.l (a0)+,watertouse
 cmp.l #endwaterlist,a0
 blt.s okwat
 move.l #waterlist,a0
okwat:
 move.l a0,waterpt

 add.w #640,wtan
 and.w #8191,wtan
 add.w #1,wateroff
 and.w #63,wateroff

 move.w FramesToDraw,TempFrames
 move.w #0,FramesToDraw

 JSR INITTIMER

 bsr PlaceFace
 bsr EnergyBar

 move.l RECORDPTR,a0
 move.b TempFrames+1,d7
 or.b d7,1(a0)

 bsr PLR1_Control

; bsr PLR2_Control 

******************************************
 jsr objmoveanim
 clr.b PLR1_clicked
 clr.b PLR2_clicked
******************************************

 move.l ObjectPoints,a1
 move.l PLR1_Obj,a0
 move.b damagetaken(a0),d2
 beq notbeenshot
 ext.w d2
 sub.w d2,Energy
 move.b #0,damagetaken(a0)
 move.l #Cheese,FacesPtr
 move.w #3,Cheese
 move.w #-1,FacesCounter
notbeenshot:
 move.b Energy+1,numlives(a0)

 move.w (a0),d0
 move.l PLR1_xoff,(a1,d0.w*8)
 move.l PLR1_zoff,4(a1,d0.w*8)
 move.l PLR1_Roompt,a1
 move.w (a1),12(a0)
 move.l PLR1_yoff,d0
 add.l #playerheight+128*24,d0
 asr.l #7,d0
 move.w d0,4(a0)

 move.l ObjectPoints,a1
 move.l PLR2_Obj,a0
 move.w (a0),d0
 move.l PLR2_xoff,(a1,d0.w*8)
 move.l PLR2_zoff,4(a1,d0.w*8)
 move.l PLR2_Roompt,a1
************************
 move.w (a1),12(a0)
 move.w 10(a1),2(a0)
************************
 move.l PLR2_yoff,d0
 add.l #playerheight+128*24,d0
 asr.l #7,d0
 move.w d0,4(a0)
 

 move.w #0,scaleval

 move.l PLR1_xoff,xoff
 move.l PLR1_yoff,yoff
 move.l PLR1_zoff,zoff
 move.w PLR1_angpos,angpos
 move.l PLR1_ListOfGraphRooms,ListOfGraphRooms
 move.l PLR1_PointsToRotatePtr,PointsToRotatePtr
 move.l PLR1_Roompt,Roompt

 move.w #0,leftclip
 move.w #96,rightclip
 move.w #0,deftopclip
 move.w #79,defbotclip
 move.w #0,topclip
 move.w #79,botclip
; sub.l #10*104*4,frompt
; sub.l #10*104*4,midpt

* Subroom loop

 bsr DrawDisplay
 
 bra noglass
 
************************************
* Test glass routine:
************************************

 move.l #WorkSpace,a0
 move.l frompt,a2
 move.w #104*4,d3
 move.w #1,d6
ribl
 move.w #31,d0
readinto
 move.w #15,d1
 move.l a2,a1
readintodown
 move.w (a1),(a0)+
 adda.w d3,a1
 move.w (a1),(a0)+
 adda.w d3,a1
 move.w (a1),(a0)+
 adda.w d3,a1
 move.w (a1),(a0)+
 adda.w d3,a1
 dbra d1,readintodown
; add.w #256-128,a0
 addq #4,a2
 dbra d0,readinto
 addq #4,a2
 dbra d6,ribl
 
* We now have the screen in a buffer
* for squidging.

 move.l frompt,a2
 move.l #WorkSpace,a0
 move.l glassballpt,a3
 move.w #$fff,d7
 move.w #1,d6 
rfbl:
 move.w #31,d0
readoutfrom:
 move.w #15,d1
 move.l a2,a1
 moveq.w #0,d5
readoutfromdown:
 move.w (a3)+,d2
 beq.s nono1
; add.w d5,d2
 move.w (a0,d2.w*2),d2
 and.w d7,d2
 move.w d2,(a1)
nono1:
 addq #1,d5
 add.w d3,a1
 move.w (a3)+,d2
 beq.s nono2
; add.w d5,d2
 move.w (a0,d2.w*2),d2
 and.w d7,d2
 move.w d2,(a1)
nono2:
 addq #1,d5
 add.w d3,a1
 move.w (a3)+,d2
 beq.s nono3
; add.w d5,d2
 move.w (a0,d2.w*2),d2
 and.w d7,d2
 move.w d2,(a1)
nono3:
 addq #1,d5
 add.w d3,a1
 move.w (a3)+,d2
 beq.s nono4
; add.w d5,d2
 move.w (a0,d2.w*2),d2
 and.w d7,d2
 move.w d2,(a1)
nono4:
 addq #1,d5
 add.w d3,a1
 dbra d1,readoutfromdown
 addq #4,a2
; adda.w #128,a0
 dbra d0,readoutfrom
 addq #4,a2
 dbra d6,rfbl
 
 move.l glassballpt,d0
 add.l #64*64*2,d0
 cmp.l #endglass,d0
 blt notoffglass
 move.l #glassball,d0
notoffglass
 move.l d0,glassballpt
 
noglass:
 
 tst.b PLR2
 bra.s nodrawp2
 
 
 move.l PLR2_xoff,xoff
 move.l PLR2_yoff,yoff
 move.l PLR2_zoff,zoff
 move.w PLR2_angpos,angpos
 move.l PLR2_ListOfGraphRooms,ListOfGraphRooms
 move.l PLR2_PointsToRotatePtr,PointsToRotatePtr

 move.w #0,leftclip
 move.w #96,rightclip
 move.w #10,deftopclip
 move.w #69,defbotclip
 add.l #68*104*4,frompt
 add.l #68*104*4,midpt

 bsr DrawDisplay


nodrawp2:
 
; move.l #brightentab,a0
; move.l frompt,a3
; adda.w #(4*33)+(104*4*20),a3
; move.w #20,d7
; move.w #20,d6
;horl:
; move.w d6,d5
; move.l a3,a1
;vertl
; move.w (a1),d0
; move.w (a0,d0.w*2),(a1)
; addq #4,a1
; dbra d5,vertl
; adda.w #104*4,a3
; dbra d7,horl

 move.l #$dff000,a6

; move.w #$300,col0(a6)


 btst #6,$bfe001
 bne.s noend
waitrel
 btst #6,$bfe001
 beq.s waitrel
 bra end
noend:
 
 tst.w Energy
 bge noendd
 move.w #10,Energy
noendd:
 
 JSR STOPTIMER
 
 bra lop

***************************************************************************
***************************************************************************
****************** End of Main Loop here ********************************** 
***************************************************************************
***************************************************************************

Path:
; incbin "testpath"
endpath:
pathpt: dc.l Path

PLR1KEYS: dc.b 0
PLR1PATH: dc.b 0
PLR1MOUSE: dc.b -1
 
 even

Bobble: dc.w 0
xwobble: dc.l 0
xwobxoff: dc.w 0
xwobzoff: dc.w 0

PLR1_Control:

; Take a snapshot of everything.

 move.l PLR1_xoff,d2
 move.l d2,PLR1_oldxoff
 move.l d2,oldx
 move.l PLR1_zoff,d3
 move.l d3,PLR1_oldzoff
 move.l d3,oldz
 move.l PLR1s_xoff,d0
 move.l d0,PLR1_xoff
 move.l d0,newx
 move.l PLR1s_zoff,d1
 move.l d1,newz
 move.l d1,PLR1_zoff
 sub.l d2,d0
 sub.l d3,d1
 move.l d0,xdiff
 move.l d1,zdiff
 move.w PLR1s_sinval,PLR1_sinval
 move.w PLR1s_cosval,PLR1_cosval
 move.w PLR1s_angpos,PLR1_angpos
 move.l PLR1s_yoff,d0
 move.l #SineTable,a1
 move.w Bobble,d1
 move.w (a1,d1.w),d1
 move.w d1,d3
 ble.s notnegative
 neg.w d1
notnegative:
 add.w #16384,d1
 asr.w #5,d1
 move.w d1,d2
 add.w d1,d1
 add.w d2,d1
 ext.l d1
 add.l d1,d0
 
 asr.w #5,d3
 ext.l d3
 move.l d3,xwobble
 move.w PLR1_sinval,d1
 muls d3,d1
 move.w PLR1_cosval,d2
 muls d3,d2
 swap d1
 swap d2
 asr.w #6,d1
 move.w d1,xwobxoff
 asr.w #6,d2
 neg.w d2
 move.w d2,xwobzoff
 
 
 move.l d0,PLR1_yoff
 move.l d0,newy
 move.l #playerheight,thingheight
 move.l #40*256,StepUpVal
 
 move.l PLR1_Roompt,objroom
 move.w #%100000000,wallflags

 bsr MoveObject
 move.w #0,wallflags
 move.l objroom,PLR1_Roompt
 move.w newx,PLR1_xoff
 move.w newz,PLR1_zoff
 move.l PLR1_xoff,PLR1s_xoff
 move.l PLR1_zoff,PLR1s_zoff
 
 move.l PLR1_Roompt,a0
 move.l 2(a0),d0
 adda.w #ToZonePts,a0
 sub.l #playerheight,d0
 move.l d0,PLR1s_tyoff

; move.l (a0),a0		; jump to viewpoint list
 * A0 is pointing at a pointer to list of points to rotate
 move.w (a0)+,d1
 ext.l d1
 add.l PLR1_Roompt,d1
 move.l d1,PLR1_PointsToRotatePtr
 tst.w (a0)+
 beq.s nobackgraphics
 move.l a0,-(a7)
 jsr putinbackdrop 
 move.l (a7)+,a0
nobackgraphics:
 move.l a0,PLR1_ListOfGraphRooms

*****************************************************

 rts

KeyMap: ds.b 256

PLR2_Control:
 move.l #SineTable,a0

 bsr turnleftright

 move.w PLR2_angspd,d1
 move.w PLR2_angpos,d0
 move.w (a0,d0.w),PLR2_sinval
 adda.w #2048,a0
 move.w (a0,d0.w),PLR2_cosval

 move.l PLR2_xspdval,d6
 move.l PLR2_zspdval,d7

 move.w PLR2_xoff,oldxoff
 move.w PLR2_zoff,oldzoff

 neg.l d6
 ble.s .nobug1
 asr.l #1,d6
 add.l #1,d6
 bra.s .bug1
.nobug1
 asr.l #1,d6
.bug1:

; beq.s goinnowhere
; blt.s goinfor
; cmp.l #4*65536,d6
; ble.s goinnowhere
; move.l #4*65536,d6
;goinfor:
; cmp.l #-4*65536,d6
; bge.s goinnowhere
; move.l #-4*65536,d6
;goinnowhere:

 neg.l d7
 ble.s .nobug2
 asr.l #1,d7
 add.l #1,d7
 bra.s .bug2
.nobug2
 asr.l #1,d7
.bug2: 
 
; beq.s goinnowhere2
; blt.s goinfor2
; cmp.l #4*65536,d7
; ble.s goinnowhere2
; move.l #4*65536,d7
;goinfor2:
; cmp.l #-4*65536,d7
; bge.s goinnowhere2
; move.l #-4*65536,d7
;goinnowhere2:

 move.w PLR2_sinval,d1
 move.w PLR2_cosval,d2
 move.w PLR2_ForwardSpd,d3
 
 muls d3,d2
 muls d3,d1

 sub.l d1,d6
 sub.l d2,d7
 add.l PLR2_pushx,d6
 add.l PLR2_pushz,d7 
 add.l d6,PLR2_xspdval
 add.l d7,PLR2_zspdval
 move.l PLR2_xspdval,d6
 move.l PLR2_zspdval,d7
 add.l d6,PLR2_xoff
 add.l d7,PLR2_zoff

 move.w PLR2_xoff,newx
 move.w PLR2_zoff,newz
 move.w oldxoff,oldx
 move.w oldzoff,oldz
 move.l PLR2_xspdval,xdiff
 move.l PLR2_zspdval,zdiff
 move.l PLR2_Roompt,objroom
 move.w #%100000000,wallflags
 bsr MoveObject
 move.w #0,wallflags
 move.l objroom,PLR2_Roompt
 move.w newx,PLR2_xoff
 move.w newz,PLR2_zoff
 
 move.l PLR2_xoff,d0
 move.l PLR2_zoff,d1
 sub.l oldxoff,d0
 sub.l oldzoff,d1
 move.l #0,PLR2_pushx
 move.l #0,PLR2_pushz
 move.l d0,PLR2_opushx
 move.l d1,PLR2_opushz

 move.l PLR2_Roompt,a0
 move.l 2(a0),d0
 sub.l #playerheight,d0
 move.l d0,PLR2_tyoff
 adda.w #22,a0

; move.l (a0),a0		; jump to viewpoint list
 * A0 is pointing at a pointer to list of points to rotate
 move.l (a0)+,PLR2_PointsToRotatePtr
 move.l a0,PLR2_ListOfGraphRooms

*****************************************************

 move.l PLR2_tyoff,d0
 move.l PLR2_yoff,d1
 move.l PLR2_yvel,d2
 add.l d2,d1
 add.l #1024,d2
 sub.l d1,d0
 bgt.s .shouldfall
 move.l #0,d2
 add.l d0,d1
.shouldfall:
 move.l d2,PLR2_yvel
 move.l d1,PLR2_yoff
 rts


DrawDisplay:

 move.l #SineTable,a0
 move.w angpos,d0
 move.w (a0,d0.w),d6
 adda.w #2048,a0
 move.w (a0,d0.w),d7
 move.w d6,sinval
 move.w d7,cosval

 move.l yoff,d0
 asr.l #8,d0
 move.w d0,d1
 and.w #63,d1
 move.w d1,wallyoff
 asl.w #2,d0
 move.w d0,flooryoff
 
 move.w xoff,d6
 move.w d6,d3
 asr.w #1,d3
 add.w d3,d6
 asr.w #1,d6
 move.w d6,xoff34
 
 move.w zoff,d6
 move.w d6,d3
 asr.w #1,d3
 add.w d3,d6
 asr.w #1,d6
 move.w d6,zoff34

 bsr RotateLevelPts
 bsr RotateObjectPts
 bsr OrderZones

 move.l ListOfGraphRooms,a0

 move.l endoflist,a0
subroomloop:
 move.w -(a0),d7
 blt jumpoutofrooms
 
; bsr setlrclip
; move.w leftclip,d0
; cmp.w rightclip,d0
; bge subroomloop
 move.l a0,-(a7)
 move.l ZoneGraphAdds,a0
 move.l (a0,d7.w*4),a0
 add.l #LEVELGRAPHICS,a0
 move.l a0,ThisRoomToDraw

 move.l ListOfGraphRooms,a1
 
finditit:
 tst.w (a1)
 blt nomoretodoatall
 cmp.w (a1),d7
 beq outoffind
 adda.w #8,a1
 bra finditit
 
outoffind:

 move.l a1,-(a7)

 move.w #0,leftclip
 move.w #96,rightclip
 move.w 2(a1),d7
 blt.s outofcliplop
 move.l #LEVELCLIPS,a0
 lea (a0,d7.w*4),a0
 	
 tst.l (a0)
 beq outofcliplop
 
 bsr NEWsetlrclip
 
intocliplop:		; clips
 tst.l (a0)
 beq outofcliplop
 
 bsr NEWsetlrclip 
 bra intocliplop
 
outofcliplop:
 
 move.l ThisRoomToDraw,a0
 move.w leftclip,d0
 cmp.w #95,d0
 bge dontbothercantseeit
 move.w rightclip,d1
 blt dontbothercantseeit
 cmp.w d1,d0
 bge dontbothercantseeit

 bsr dothisroom
 
dontbothercantseeit:
pastemp:

 move.l (a7)+,a1
 move.l ThisRoomToDraw,a0
 move.w (a0),d7
 adda.w #8,a1
 bra finditit
 
nomoretodoatall:
 
 move.l (a7)+,a0
 
 bra subroomloop

jumpoutofrooms:

 rts
 
TempBuffer: ds.l 100 

ClipTable: ds.l 30
EndOfClipPt: dc.l 0

dothisroom

 move.w (a0)+,d0
 move.w d0,currzone
 move.l ZoneAdds,a1
 move.l (a1,d0.w*4),a1
 add.l #LEVELDATA,a1
 move.w 10(a1),ZoneBright

polyloop:
 move.w (a0)+,d0
 blt jumpoutofloop
 beq itsawall
 cmp.w #3,d0
 beq itsasetclip
 blt itsafloor
 cmp.w #4,d0
 beq itsanobject
 cmp.w #5,d0
 beq.s itsanarc
 cmp.w #6,d0
 beq itsalightbeam
 cmp.w #7,d0
 beq.s itswater
 cmp.w #9,d0
 ble itsachunkyfloor
 cmp.w #11,d0
 ble.s itsabumpyfloor
 cmp.w #12,d0
 beq.s itsbackdrop
 cmp.w #13,d0
 beq.s itsaseewall
 
 bra polyloop
 
itsaseewall:
 st seethru
 move.l #stripbufferthru,a1
 jsr itsawalldraw
 bra polyloop
 
itsbackdrop:
 jsr putinbackdrop
 bra polyloop
 
itswater:
 move.w #1,d0
 move.l #FloorLine,LineToUse
 st usewater
 clr.b usebumps
 jsr itsafloordraw
 bra polyloop
 
itsanarc:
 jsr CurveDraw
 bra polyloop
itsanobject:
 jsr ObjDraw
 bra polyloop
itsalightbeam:
 jsr LightDraw
 bra polyloop
 
itsabumpyfloor:
 sub.w #9,d0
 st usebumps
 st smoothbumps
 clr.b usewater
 move.l #BumpLine,LineToUse
 jsr itsafloordraw
 bra polyloop
 
itsachunkyfloor:
 subq.w #7,d0
 st usebumps
 sub.w #12,topclip
; add.w #10,botclip
 clr.b smoothbumps
 clr.b usewater
 move.l #BumpLine,LineToUse
 jsr itsafloordraw
 add.w #12,topclip
; sub.w #10,botclip
 bra polyloop 
 
itsafloor:

 move.l #FloorLine,LineToUse
* 1,2 = floor/roof
 clr.b usewater
 clr.b usebumps
 jsr itsafloordraw
 bra polyloop
itsasetclip:
 bra polyloop
itsawall:
 clr.b seethru
 move.l #stripbuffer,a1
 jsr itsawalldraw
 bra polyloop

jumpoutofloop:
 rts

ThisRoomToDraw: dc.l 0

 include "ab3:source/OrderZones"

ReadMouse:
 clr.l d0
 clr.l d1
 move.w $a(a6),d0
 lsr.w #8,d0
 ext.l d0
 move.w d0,d3
 move.w oldy,d2
 sub.w d2,d0

 cmp.w #127,d0
 blt nonegy
 move.w #255,d1
 sub.w d0,d1
 move.w d1,d0
 neg.w d0
nonegy:

 cmp.w #-127,d0
 bge nonegy2
 move.w #255,d1
 add.w d0,d1
 move.w d1,d0
nonegy2:

 add.b d0,d2
 add.w d0,oldy2
 move.w d2,oldy
 move.w d2,d0

 move.w oldy2,d0
 move.w d0,ymouse

 clr.l d0
 clr.l d1
 move.w $a(a6),d0
 ext.w d0
 ext.l d0
 move.w d0,d3
 move.w oldmx,d2
 sub.w d2,d0

 cmp.w #127,d0
 blt nonegx
 move.w #255,d1
 sub.w d0,d1
 move.w d1,d0
 neg.w d0
nonegx:

 cmp.w #-127,d0
 bge nonegx2
 move.w #255,d1
 add.w d0,d1
 move.w d1,d0
nonegx2:

 add.b d0,d2
 move.w d0,d1
 move.w d2,oldmx


 move.w #$0,$dff034
 btst #2,$dff016
 beq.s noturn

 add.w d0,oldx2
 move.w oldx2,d0
 and.w #2047,d0
 move.w d0,oldx2
 
 asl.w #2,d0
 sub.w prevx,d0
 add.w d0,prevx
 add.w d0,PLR1s_angpos
 move.w #0,lrs
 rts

noturn:

; got to move lr instead. 

; d1 = speed moved l/r

 move.w d1,lrs

 rts
 
lrs: dc.w 0
prevx: dc.w 0
 
mang: dc.w 0
oldymouse: dc.w 0
xmouse: dc.w 0
ymouse: dc.w 0
oldx2: dc.w 0
oldmx: dc.w 0
oldy: dc.w 0
oldy2: dc.w 0

RotateLevelPts:

 move.w sinval,d6
 swap d6
 move.w cosval,d6

 move.l PointsToRotatePtr,a0
 move.l Points,a3
 move.l #Rotated,a1
 move.l #OnScreen,a2
 move.w xoff,d4
 move.w zoff,d5
 
; move.w #$c40,$dff106
; move.w #$f00,$dff180
 
pointrotlop:
 move.w (a0)+,d7
 blt.s outofpointrot
 
 move.w (a3,d7*4),d0
 sub.w d4,d0
 move.w d0,d2
 move.w 2(a3,d7*4),d1
 sub.w d5,d1
 muls d6,d2
 swap d6
 move.w d1,d3
 muls d6,d3
 sub.l d3,d2
 add.l d2,d2
 swap d2
 ext.l d2
 asl.l #7,d2
 add.l xwobble,d2
 move.l d2,(a1,d7*8)

 muls d6,d0
 swap d6
 muls d6,d1
 add.l d0,d1
 asl.l #2,d1
 swap d1
 move.l d1,4(a1,d7*8)

 tst.w d1
 bgt.s ptnotbehind
 tst.w d2
 bgt.s onrightsomewhere
 move.w #0,d2
 bra putin
onrightsomewhere:
 move.w #96,d2
 bra putin
ptnotbehind:

 divs d1,d2
 add.w #47,d2
putin:
 move.w d2,(a2,d7*2)
 
 bra pointrotlop
outofpointrot:

; move.w #$c40,$dff106
; move.w #$ff0,$dff180

 rts

RotateObjectPts:

 move.w sinval,d5
 move.w cosval,d6

 move.l ObjectPoints,a0
 move.w NumObjectPoints,d7
 move.l #ObjRotated,a1
 move.l #ObsInLine,a2
objpointrotlop:
 
 move.w (a0),d0
 sub.w xoff,d0
 move.w 4(a0),d1
 addq #8,a0
 sub.w zoff,d1
 move.w d0,d2
 muls d6,d2
 move.w d1,d3
 muls d5,d3
 sub.l d3,d2
 add.l d2,d2
 swap d2
 move.w d2,(a1)+
 
 muls d5,d0
 muls d6,d1
 add.l d0,d1
 asl.l #2,d1
 swap d1
 moveq #0,d3
 
 move.w d1,(a1)+
 ext.l d2
 asl.l #7,d2
 add.l xwobble,d2
 move.l d2,(a1)+
 sub.l xwobble,d2
 tst.w d1
 ble.s notinline

 cmp.l #-60*128,d2
 blt.s notinline
 cmp.l #60*128,d2
 sle d3
notinline
 move.b d3,(a2)+

 dbra d7,objpointrotlop

 rts

LightDraw:

 move.w (a0)+,d0
 move.w (a0)+,d1
 move.l #Rotated,a1
 move.w 6(a1,d0.w*8),d2
 ble.s oneendbehind
 move.w 6(a1,d1.w*8),d3
 bgt.s bothendsinfront

oneendbehind:
 rts
bothendsinfront:
 
 move.l #OnScreen,a2
 move.w (a2,d0.w*2),d0
 bge.s okleftend
 moveq #0,d0
okleftend:
 move.w (a2,d1.w*2),d1
 bgt.s somevis
 rts
somevis:
 cmp.w #95,d0
 ble.s somevis2
 rts
somevis2:
 cmp.w #95,d1
 ble.s okrightend
 move.w #95,d1
okrightend:

 sub.w d0,d1
 blt.s wrongbloodywayround
 move.l #brightentab,a4
 move.l #objintocop,a1
 lea (a1,d0.w*2),a1
 
 move.l frompt,a3
 move.w #104*4,d6
 move.w #79,d2
lacross:
 move.w d2,d3
 move.l a3,a2
 adda.w (a1)+,a2
ldown:
 add.w d6,a2
 move.w (a2),d7
 move.w (a4,d7.w*2),(a2)
 dbra d3,ldown
 dbra d1,lacross
 
wrongbloodywayround:
 
 rts

FaceToPlace: dc.w 0

Cheese:
 dc.w 4,15

FacesList:
 dc.w 0,4*4
 dc.w 1,2*4
 dc.w 0,2*4
 dc.w 2,2*4
 dc.w 0,2*4
 dc.w 1,3*4
 dc.w 0,2*4
 dc.w 2,3*4
 dc.w 0,5*4
 dc.w 1,2*4
 dc.w 0,2*4
 dc.w 2,2*4
 dc.w 0,2*4
 dc.w 1,2*4
 dc.w 0,2*4
 dc.w 2,3*4
 dc.w 0,1*4
 dc.w 1,3*4
 dc.w 0,1*4
 dc.w 2,3*4
 dc.w 0,1*4

EndOfFacesList:

FacesPtr:
 dc.l FacesList
FacesCounter:
 dc.w 0
Expression:
 dc.w 0

PlaceFace:

 move.w FacesCounter,d0
 subq #1,d0
 bgt.s NoNewFace

 move.l FacesPtr,a0
 
 move.w 2(a0),d0
 move.w (a0),Expression
 addq #4,a0
 cmp.l #EndOfFacesList,a0
 blt.s NotFirstFace

 move.l #FacesList,a0

NotFirstFace
 move.l a0,FacesPtr

NoNewFace:

 move.w d0,FacesCounter

 Move.w FaceToPlace,d0
 muls #5,d0
 add.w Expression,d0
 move.l #FacePlace+10,a0
 move.l #Faces,a1
 muls #(4*32*5),d0
 adda.w d0,a1
 move.w #4,d0
 move.w #24,d1
 
 move.w #4,d3
bitplaneloop:
 move.w #31,d2
PlaceFaceToPlaceInFacePlaceLoop:
 move.l (a1),(a0)
 adda.w d0,a1
 adda.w d1,a0
 dbra d2,PlaceFaceToPlaceInFacePlaceLoop
 dbra d3,bitplaneloop
 
 rts
 
Energy:
 dc.w 191
OldEnergy:
 dc.w 191

FullEnergy:
 move.w #191,Energy
 move.w #191,OldEnergy
 move.l #Panel+41*24,a0
 move.w #6*6-1,d0
fillbar:
 move.l #$fefefefe,(a0)+
 dbra d0,fillbar
 rts
 
EnergyBar:

 move.w Energy,d0
 move.w #192,d1
 sub.w d0,d1
 ext.l d1
 divs #39,d1
 move.w d1,FaceToPlace
 cmp.w OldEnergy,d0
 bne.s gottochange
 
NoChange
 rts
 
gottochange:
  
 blt LessEnergy
 cmp.w #191,Energy
 blt.s NotMax
 move.w #191,Energy
NotMax:

 move.w Energy,d0
 move.w OldEnergy,d2
 sub.w d0,d2
 beq.s NoChange
 neg.w d2
 
 move.w OldEnergy,d3
 
 move.l #Panel+41*24,a0
EnergyRise:
 move.w d3,d0
 move.b d0,d1
 not.b d1
 and.b #7,d1
 beq.s noplot
 asr.w #3,d0
 lea (a0,d0.w),a1
 bset.b d1,(a1)
 bset.b d1,24(a1)
 bset.b d1,24*2(a1)
 bset.b d1,24*3(a1)
 bset.b d1,24*4(a1)
 bset.b d1,24*5(a1)
noplot:
 addq #1,d3
 subq #1,d2
 bgt.s EnergyRise

 move.w Energy,OldEnergy

 rts 


LessEnergy: 
 move.w OldEnergy,d2
 sub.w d0,d2
 
 move.w OldEnergy,d3
 
 move.l #Panel+41*24,a0
EnergyDrain:
 move.w d3,d0
 move.b d0,d1
 not.b d1
 asr.w #3,d0
 lea (a0,d0.w),a1
 bclr.b d1,(a1)
 bclr.b d1,24(a1)
 bclr.b d1,24*2(a1)
 bclr.b d1,24*3(a1)
 bclr.b d1,24*4(a1)
 bclr.b d1,24*5(a1)
 subq #1,d3
 subq #1,d2
 bgt.s EnergyDrain

 move.w Energy,OldEnergy

 rts 
 
end:
 jmp closeeverything 

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
 
 

NEWsetlrclip:
 move.l #OnScreen,a1
 move.l #Rotated,a2
 
 move.w (a0),d0
 bge.s .notignoreleft
 
; move.l #0,(a6)
 
 bra .leftnotoktoclip
.notignoreleft:

 move.w 6(a2,d0*8),d3	; left z val
 bgt.s .leftclipinfront

 move.w 4(a0),d0
 blt.s .ignoreboth
 tst.w 6(a2,d0*8)
 bgt.s .leftnotoktoclip
.ignoreboth:
; move.l #0,(a6)
; move.l #96*65536,4(a6)
 move.w #0,leftclip
 move.w #96,rightclip
 addq #8,a6
 addq #8,a0
 rts

.leftclipinfront:
 move.w (a1,d0*2),d1	; left x on screen
 move.w 2(a0),d2
 move.w (a1,d2.w*2),d2
 cmp.w d1,d2
 bgt.s .leftnotoktoclip

; move.w d1,(a6)
; move.w d3,2(a6)
 cmp.w leftclip(pc),d1
 ble.s .leftnotoktoclip
 move.w d1,leftclip
.leftnotoktoclip:

 move.w 4(a0),d0
 bge.s .notignoreright
; move.w #96,4(a6)
; move.w #0,6(a6)
 move.w #0,d4
 bra .rightnotoktoclip
.notignoreright:
 move.w 6(a2,d0*8),d4	; right z val
 bgt.s .rightclipinfront
; move.w #96,4(a6)
; move.w #0,6(a6)
 bra.s .rightnotoktoclip

.rightclipinfront:
 move.w (a1,d0*2),d1	; right x on screen
 move.w 6(a0),d2
 move.w (a1,d2.w*2),d2
 cmp.w d1,d2
 blt.s .rightnotoktoclip
; move.w d1,4(a6)
; move.w d4,6(a6)

 cmp.w rightclip(pc),d1
 bge.s .rightnotoktoclip
 addq #1,d1
 move.w d1,rightclip
.rightnotoktoclip:
 addq #8,a6
 addq #8,a0
 rts

FIRSTsetlrclip:
 move.l #OnScreen,a1
 move.l #Rotated,a2
 
 move.w (a0)+,d0
 bge.s .notignoreleft
 bra .leftnotoktoclip
.notignoreleft:

 move.w 6(a2,d0*8),d3	; left z val
 bgt.s .leftclipinfront

 move.w (a0),d0
 blt.s .ignoreboth
 tst.w 6(a2,d0*8)
 bgt.s .leftnotoktoclip
.ignoreboth
 move.w #96,rightclip
 move.w #0,leftclip
 addq #2,a0
 rts

.leftclipinfront:
 move.w (a1,d0*2),d1	; left x on screen
 cmp.w leftclip(pc),d1
 ble.s .leftnotoktoclip
 move.w d1,leftclip
.leftnotoktoclip:

 move.w (a0)+,d0
 bge.s .notignoreright
 move.w #0,d4
 bra .rightnotoktoclip
.notignoreright:
 move.w 6(a2,d0*8),d4	; right z val
 ble.s .rightnotoktoclip

.rightclipinfront:
 move.w (a1,d0*2),d1	; right x on screen
 cmp.w rightclip(pc),d1
 bge.s .rightnotoktoclip
 addq #1,d1
 move.w d1,rightclip
.rightnotoktoclip:

; move.w leftclip,d0
; move.w rightclip,d1
; cmp.w d0,d1
; bge.s .noswap
; move.w #96,rightclip
; move.w #0,leftclip
;.noswap:

 rts


leftclip2: dc.w 0
rightclip2: dc.w 0
ZoneBright: dc.w 0
 
npolys: dc.w 0

PLR1_fire: dc.b 0
PLR2_fire: dc.b 0

turnleftright:

 move.w PLR2_angspd,d1
 move.w PLR2_angpos,d0

 move.w #120,d7
 muls TempFrames,d7

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

 move.w #0,PLR2_ForwardSpd

 btst #0,$dff00c
 sne d5
 eor.b d4,d5
 beq.s notup
 move.w TempFrames,d7
 neg.w d7
 asl.w #2,d7
 move.w d7,PLR2_ForwardSpd
notup:

 btst #0,$dff00d
 sne d5
 eor.b d3,d5
 beq.s notdown
 move.w TempFrames,d7
 asl.w #2,d7
 move.w d7,PLR2_ForwardSpd
notdown:

 add.w d2,d1
 cmp.w #-360,d1
 bge.s okspdlft
 move.w #-360,d1
okspdlft:
 cmp.w #360,d1
 ble.s okspdrgt
 move.w #360,d1
okspdrgt:

 move.w d1,PLR2_angspd
 add.w d1,d0
 and.w #8191,d0
 move.w d0,PLR2_angpos
 rts

*****************************************************

 include "ab3:source/ObjectMove"

pastdata:
***********************************
* This routine animates brightnesses.

 
liftpt: dc.l liftanimtab

brightpt:
 dc.l brightanimtab

liftanim:
 rts

******************************
 include "ab3:source/Anims"
******************************

rotanimpt: dc.w 0
xradd: dc.w 5
yradd: dc.w 8
xrpos: dc.w 320
yrpos: dc.w 320

rotanim:
 rts
 
option:
 dc.l 0

********** WALL STUFF *******************************

 include "AB3:source/wallroutine3.chipmem"

*****************************************************

******************************************
* floor polygon

numsidestd: dc.w 0
bottomline: dc.w 0

NewCornerBuff:
 ds.l 100

itsafloordraw:

* If D0 =1 then its a floor otherwise (=2) it's
* a roof.

 move.w #0,above
 move.w (a0)+,d6	; ypos of poly
 
 move.w leftclip(pc),d7
 cmp.w rightclip(pc),d7
 bge.s dontdrawreturn
 
 move.w botclip,d7
 sub.w #40,d7
 ble.s dontdrawreturn
 sub.w flooryoff,d6
 bgt.s below
 blt.s aboveplayer
dontdrawreturn:
 move.w (a0)+,d6	; sides-1
 add.w d6,d6
 add.w d6,a0
 add.w #4+6,a0
 rts
aboveplayer:
 cmp.w #2,d0
 bne.s dontdrawreturn
 move.w #40,d7
 sub.w topclip,d7 
 blt.s dontdrawreturn
 move.w #1,d0
 move.w d0,above
 neg.w d6
below:
 cmp.w #1,d0
 bne.s dontdrawreturn
 move.w d6,distaddr
 muls #64,d6
 move.l d6,ypos
 divs d7,d6		; zpos of bottom
			; visible line
 move.w d6,minz
 move.w d7,bottomline

; Go round each point finding out
; if it should be visible or not.

 move.l a0,-(a7)

 move.w (a0)+,d7	; number of sides
 move.l #Rotated,a1
 move.l #OnScreen,a2
 move.l #NewCornerBuff,a3
 moveq #0,d4
 moveq #0,d5
 moveq #0,d6
 clr.b anyclipping
 
cornerprocessloop:

 move.w (a0)+,d0
 move.w 6(a1,d0.w*8),d1
 ble  .canttell
 
 move.w (a2,d0.w*2),d3
 cmp.w leftclip,d3
 bgt.s .nol
 st d4
 st anyclipping
 bra.s .nos
.nol:
 cmp.w rightclip,d3
 blt.s .nor
 st d6
 st anyclipping
 bra.s .nos
.nor:
 st d5
.nos:
 bra .cantell

.canttell:
 st d5
 st anyclipping

.cantell:


 dbra d7,cornerprocessloop
 
 move.l (a7)+,a0
 tst.b d5
 bne.s somefloortodraw
 eor.b d4,d6
 bne dontdrawreturn

somefloortodraw:

 move.w #80,top
 move.w #-1,bottom
 move.w #0,drawit
 move.l #Rotated,a1
 move.l #OnScreen,a2
 move.w (a0)+,d7	; no of sides
sideloop:
 move.w minz,d6
 move.w (a0)+,d1
 move.w (a0),d3
 move.w 6(a1,d1*8),d4	;first z
 cmp.w d6,d4
 bgt firstinfront
 move.w 6(a1,d3*8),d5	; sec z
 cmp.w d6,d5
 ble bothbehind
** line must be on left and partially behind.
 sub.w d5,d4
 move.l (a1,d1*8),d0
 sub.l (a1,d3*8),d0
 asr.l #7,d0
 sub.w d5,d6
 muls d6,d0	; new x coord
 divs d4,d0
 ext.l d0
 asl.l #7,d0

 add.l (a1,d3*8),d0
 move.w minz,d4
 move.w (a2,d3*2),d2
 divs d4,d0
 add.w #47,d0
 move.l ypos,d3
 divs d5,d3
 move.w bottomline,d1 
 bra lineclipped

firstinfront:
 move.w 6(a1,d3*8),d5	; sec z
 cmp.w d6,d5
 bgt bothinfront
** line must be on right and partially behind.
 sub.w d4,d5	; dz
 move.l (a1,d3*8),d2
 sub.l (a1,d1*8),d2	; dx
 sub.w d4,d6
 asr.l #7,d2
 muls d6,d2	; new x coord
 divs d5,d2
 ext.l d2
 asl.l #7,d2
 add.l (a1,d1*8),d2
 move.w minz,d5
 move.w (a2,d1*2),d0
 divs d5,d2
 add.w #47,d2
 move.l ypos,d1
 divs d4,d1
 move.w bottomline,d3 
 bra lineclipped

bothinfront:

* Also, usefully enough, both are on-screen
* so no bottom clipping is needed.

 move.w (a2,d1*2),d0	; first x
 move.w (a2,d3*2),d2	; second x
 move.l ypos,d1
 move.l d1,d3
 divs d4,d1		; first y
 divs d5,d3		; second y
lineclipped:
 move.l #rightsidetab,a3
 cmp.w d1,d3
 beq lineflat
 st drawit
 bgt lineonright
 move.l #leftsidetab,a3
 exg d1,d3
 exg d0,d2
 
 lea (a3,d1*2),a3
 
 cmp.w top(pc),d1
 bge.s .nonewtop
 move.w d1,top
.nonewtop:
 cmp.w bottom(pc),d3
 ble.s .nonewbot
 move.w d3,bottom
.nonewbot:

 sub.w d1,d3	; dy
 sub.w d0,d2	; dx
 
 blt .linegoingleft
 sub.w #1,d0

 ext.l d2
 divs d3,d2
 move.w d2,d6
 swap d2

; moveq #0,d6
; sub.w d3,d2
; blt.s .noco
;.makeco
; addq #1,d6
; sub.w d3,d2
; bge.s .makeco
;.noco
; add.w d3,d2
 
 move.w d3,d4
 move.w d3,d5
 subq #1,d5
 move.w d6,d1
 addq #1,d1

.pixlopright:
 move.w d0,(a3)+
 sub.w d2,d4
 bge.s .nobigstep
 add.w d1,d0
 add.w d3,d4
 dbra d5,.pixlopright
 bra lineflat
.nobigstep
 add.w d6,d0
 dbra d5,.pixlopright
 bra lineflat

.linegoingleft:

 sub.w #1,d0
 
 neg.w d2

 ext.l d2
 divs d3,d2
 move.w d2,d6
 swap d2


; moveq #0,d6
; sub.w d3,d2
; blt.s .nocol
;.makecol
; addq #1,d6
; sub.w d3,d2
; bge.s .makecol
;.nocol
; add.w d3,d2


 
 move.w d3,d4
 move.w d3,d5
 subq #1,d5

 move.w d6,d1
 addq #1,d1

.pixlopleft:
 sub.w d2,d4
 bge.s .nobigstepl
 sub.w d1,d0
 add.w d3,d4
 move.w d0,(a3)+
 dbra d5,.pixlopleft
 bra lineflat
 
.nobigstepl
 sub.w d6,d0
 move.w d0,(a3)+
 dbra d5,.pixlopleft
 bra lineflat
 
lineonright:

 lea (a3,d1*2),a3
 
 cmp.w top(pc),d1
 bge.s .nonewtop
 move.w d1,top
.nonewtop:
 cmp.w bottom(pc),d3
 ble.s .nonewbot
 move.w d3,bottom
.nonewbot:

 sub.w d1,d3	; dy
 sub.w d0,d2	; dx
 blt .linegoingleft
; addq #1,d0
 ext.l d2
 divs d3,d2
 move.w d2,d6
 swap d2

; moveq #0,d6
; sub.w d3,d2
; blt.s .noco
;.makeco
; addq #1,d6
; sub.w d3,d2
; bge.s .makeco
;.noco
; add.w d3,d2
 
 move.w d3,d4
 move.w d3,d5
 subq #1,d5
 move.w d6,d1
 addq #1,d1

.pixlopright:
 sub.w d2,d4
 bge.s .nobigstep
 add.w d1,d0
 add.w d3,d4
 move.w d0,(a3)+
 dbra d5,.pixlopright
 bra lineflat
 
.nobigstep
 add.w d6,d0
 move.w d0,(a3)+
 dbra d5,.pixlopright
 bra lineflat

.linegoingleft:
; addq #1,d0
 neg.w d2

 ext.l d2
 divs d3,d2
 move.w d2,d6
 swap d2


; moveq #0,d6
; sub.w d3,d2
; blt.s .nocol
;.makecol
; addq #1,d6
; sub.w d3,d2
; bge.s .makecol
;.nocol
; add.w d3,d2

 move.w d3,d4
 move.w d3,d5
 subq #1,d5
 move.w d6,d1
 addq #1,d1

.pixlopleft:
 move.w d0,(a3)+
 sub.w d2,d4
 bge.s .nobigstepl
 sub.w d1,d0
 add.w d3,d4
 dbra d5,.pixlopleft
 bra lineflat
 
.nobigstepl
 sub.w d6,d0
 dbra d5,.pixlopleft

lineflat:
 
bothbehind:
 dbra d7,sideloop

pastsides:


 addq #2,a0
 
 move.w #104*4,linedir
 move.l frompt,a6
 add.l #104*4*41,a6
 move.w (a0)+,scaleval
 move.w (a0)+,whichtile
 move.w (a0)+,d6
 add.w ZoneBright,d6
 move.w d6,lighttype
 move.w above(pc),d6
 beq groundfloor
* on ceiling:
 move.w #-104*4,linedir
 suba.w #104*4,a6
groundfloor:

 move.w xoff,d6
 move.w zoff,d7
 add.w xwobxoff,d7
 add.w xwobzoff,d6
 move.w scaleval,d3
 move.l scaleprogfrom(pc,d3.w*4),scaleprog
 tst.w d3
 beq.s .samescale
 bgt.s .scaledown
 neg.w d3
 asr.l d3,d7
 asr.l d3,d6
 bra.s .samescale
.scaledown:
 asl.l d3,d6
 asl.l d3,d7
.samescale
 asl.w #8,d7
 move.w d6,sxoff
 move.w d7,szoff
 bra pastscale 

 asr.l #3,d1
 asr.l #3,d2
 asr.l #2,d1
 asr.l #2,d2
 asr.l #1,d1
 asr.l #1,d2
scaleprogfrom
 nop
 nop
 asl.l #1,d1
 asl.l #1,d2
 asl.l #2,d1
 asl.l #2,d2
 asl.l #3,d1
 asl.l #3,d2

top: dc.w 0
bottom: dc.w 0
ypos: dc.l 0
nfloors: dc.w 0
lighttype: dc.w 0
above: dc.w 0 
linedir: dc.w 0
distaddr: dc.w 0
 
minz: dc.w 0
leftsidetab:
 ds.w 80
rightsidetab:
 ds.w 80
leftsideclip:
 ds.w 80
rightsideclip:
 ds.w 80

movespd: dc.w 0
largespd: dc.l 0

pastscale:

 tst.b drawit(pc)
 beq dontdrawfloor

 move.l a0,-(a7)

 move.l #leftsidetab,a4
 move.w top(pc),d1
 move.w bottom(pc),d7
 tst.w above
 beq.s clipfloor
 
 move.w #40,d3
 move.w d3,d4
 sub.w topclip,d3
 sub.w botclip,d4
 cmp.w d3,d1
 bge predontdrawfloor
 cmp.w d4,d7
 blt predontdrawfloor
 cmp.w d4,d1
 bge.s .nocliptoproof
 move.w d4,d1
.nocliptoproof
 cmp.w d3,d7
 blt doneclip
 move.w d3,d7
 bra doneclip
 
clipfloor:
 move.w botclip,d4
 sub.w #40,d4
 cmp.w d4,d1
 bge predontdrawfloor
 move.w topclip,d3
 sub.w #40,d3
 cmp.w d3,d1
 bge.s .nocliptopfloor
 move.w d3,d1
.nocliptopfloor 
 cmp.w d3,d7
 ble predontdrawfloor
 cmp.w d4,d7
 blt.s .noclipbotfloor
 move.w d4,d7
.noclipbotfloor:

doneclip:

 lea (a4,d1*2),a4
; move.l #dists,a2
 move.w distaddr,d0
 muls #64,d0
 move.l d0,a2
; muls #25,d0
; adda.w d0,a2
; lea (a2,d1*2),a2
 sub.w d1,d7
 ble predontdrawfloor 
 move.w d1,d0
 bne.s .notzero
 moveq #1,d0
.notzero
 muls linedir,d1
 add.l d1,a6
 move.l #floorscalecols,a1
 move.l LineToUse,a5
 
 tst.b anyclipping
 beq dofloornoclip
 
dofloor:
; move.w (a2)+,d0
 move.w leftclip(pc),d3
 move.w rightclip(pc),d4
 move.w rightsidetab-leftsidetab(a4),d2
 addq #1,d2
 cmp.w d3,d2
 ble.s nodrawline
 cmp.w d4,d2
 ble.s noclipright
 move.w d4,d2
noclipright:
 move.w (a4),d1
 cmp.w d4,d1
 bge.s nodrawline
 cmp.w d3,d1
 bge.s noclipleft
 move.w d3,d1
noclipleft:
 cmp.w d1,d2
 ble.s nodrawline

 move.w d1,leftedge
 move.w d2,rightedge
 
 move.l a6,a3
 movem.l d0/d7/a2/a4/a5/a6,-(a7)
 move.l a2,d7
 divs d0,d7
 move.w d7,d0
 jsr (a5)
 movem.l (a7)+,d0/d7/a2/a4/a5/a6
nodrawline
 adda.w linedir(pc),a6
 addq #2,a4
 addq #1,d0
 subq #1,d7
 bgt dofloor

predontdrawfloor
 move.l (a7)+,a0

dontdrawfloor:

 CACHE_FREEZE_OFF d2
 rts

anyclipping: dc.w 0

dofloornoclip:
; move.w (a2)+,d0
 move.w rightsidetab-leftsidetab(a4),d2
 addq #1,d2
 move.w (a4)+,leftedge
 move.w d2,rightedge

 move.l a6,a3
 movem.l d0/d7/a2/a4/a5/a6,-(a7)
 move.l a2,d7
 divs d0,d7
 move.w d7,d0
 jsr (a5)
 movem.l (a7)+,d0/d7/a2/a4/a5/a6
 adda.w linedir(pc),a6
 addq #1,d0
 subq #1,d7
 bgt dofloornoclip

 bra predontdrawfloor


dists:
; incbin "floordists"
drawit: dc.w 0

LineToUse: dc.l 0

***************************
* Right then, time for the floor
* routine...
* For test purposes, give it
* a3 = point to screen
* d0= z distance away
* and sinval+cosval must be set up.
***************************

leftedge: dc.w 0
rightedge: dc.w 0

rndpt: dc.l rndtab

WaterFloorLine:

 CACHE_OFF d2

 move.l rndpt,a2
 move.w (a2)+,d1
 move.w (a2)+,d2
 move.w (a2)+,d3
 cmp.l #endrnd-4,a2
 blt.s okrnd
 suba.w #98,a2
okrnd: 
 move.l a2,rndpt

 asr.w #6,d0
 move.w d0,d1
 move.w d0,d2
 move.w d0,d3
 move.l clipd(pc,d1.w*4),d1
 move.l clipd(pc,d2.w*4),d2
 move.l clipd(pc,d3.w*4),d3
 bra pcli

 dc.l 0
clipd:
 dc.l 0
 dc.l 512
 dc.l 512*2
 dc.l 512*3
 dc.l 512*4
 dc.l 512*5
 dc.l 512*6
 dc.l 512*7
 dc.l 512*8
 dc.l 512*9
 dc.l 512*10
 dc.l 512*11
 dc.l 512*12
 dc.l 512*13
 dc.l 512*14
 dc.l 512*15
 dc.l 512*15
 dc.l 512*15
 dc.l 512*15
 dc.l 512*15
 dc.l 512*15
 dc.l 512*15
 dc.l 512*15
 dc.l 512*15
 dc.l 512*15
 dc.l 512*15
 dc.l 512*15

pcli:

 move.l #brightentab,a2
 move.l a2,a4
 move.l a4,a5
 add.l d1,a2
 add.l d2,a4
 add.l d3,a5

 move.l #doacrossline,a1
 move.w leftedge(pc),d1
 move.w rightedge(pc),d2
 sub.w d1,d2
 move.w time(pc,d1.w*2),d1
 move.w time(pc,d2.w*2),d2
 lea (a1,d1.w),a1
 move.w (a1,d2.w),d4
 move.w #$4e75,(a1,d2.w)

 moveq #0,d0
 jsr (a1)
 move.w d4,(a1,d2.w)

 CACHE_ON d2

 rts
 
time:
val SET 0
 REPT 100
 dc.w val
val SET val+10
 ENDR
 
storeit: dc.l 0

doacrossline:
 incbin "Doacrossline"
 rts

dst: dc.w 0

FloorLine:

 move.l #floortile,a0
 adda.w whichtile,a0
 move.w lighttype,d1
 
 move.w d0,dst
 
 move.w d0,d2
*********************
* Old version
 asr.w #6,d2
 add.w #5,d1
*********************
; asr.w #3,d2
; sub.w #4,d2
; cmp.w #6,d2
; blt.s flbrbr
; move.w #6,d2
;flbrbr:
*********************
 add.w d2,d1
 bge.s .fixedbright
 moveq #0,d1
.fixedbright:
 cmp.w #28,d1
 ble.s .smallbright
 move.w #28,d1
.smallbright:
 lea floorscalecols,a1
 add.l floorbright(pc,d1.w*4),a1
 bra pastfloorbright
 
ConstCol: dc.w 0
 
BumpLine:

 tst.b smoothbumps
 beq.s Chunky
 
 move.l #SmoothTile,a0
 lea Smoothscalecols,a1
 bra pastast
 
Chunky:

 moveq #0,d2
 move.l #Bumptile,a0
 move.w whichtile,d2
 adda.w d2,a0
 ror.l #2,d2
 lsr.w #6,d2
 rol.l #2,d2
 and.w #15,d2
 move.l #ConstCols,a1
 move.w (a1,d2.w*2),ConstCol
 lea Bumpscalecols,a1
 
pastast:
 move.w lighttype,d1
 
 move.w d0,dst
 
 move.w d0,d2
*********************
* Old version
 asr.w #6,d2
 add.w #5,d1
*********************
; asr.w #3,d2
; sub.w #4,d2
; cmp.w #6,d2
; blt.s flbrbr
; move.w #6,d2
;flbrbr:
*********************
 add.w d2,d1
 bge.s .fixedbright
 moveq #0,d1
.fixedbright:
 cmp.w #28,d1
 ble.s .smallbright
 move.w #28,d1
.smallbright:
 add.l floorbright(pc,d1.w*4),a1
 bra pastfloorbright
 

floorbright:
 dc.l 512*0
 dc.l 512*1
 dc.l 512*1
 dc.l 512*2
 dc.l 512*2
 
 dc.l 512*3
 dc.l 512*3
 dc.l 512*4
 dc.l 512*4
 dc.l 512*5
 
 dc.l 512*5
 dc.l 512*6
 dc.l 512*6
 dc.l 512*7
 dc.l 512*7
 
 dc.l 512*8
 dc.l 512*8
 dc.l 512*9
 dc.l 512*9
 dc.l 512*10
 
 dc.l 512*10
 dc.l 512*11
 dc.l 512*11
 dc.l 512*12
 dc.l 512*12
 
 dc.l 512*13
 dc.l 512*13
 dc.l 512*14
 dc.l 512*14

widthleft: dc.w 0
scaleval: dc.w 0
sxoff: dc.w 0
szoff: dc.w 0
xoff34: dc.w 0
zoff34: dc.w 0
scosval: dc.w 0
ssinval: dc.w 0


floorsetbright:
 move.l #walltiles,a0

pastfloorbright


 move.w d0,d1
 muls cosval,d1	; change in x across whole width
 move.w d0,d2
 muls sinval,d2	; change in z across whole width
 neg.l d2
scaleprog:
 asr.l #1,d1
 asr.l #1,d2

 move.l d1,d3 ;	z cos
 move.l d3,d6
 move.l d3,d5
 asr.l #1,d6
 add.l d6,d3
 asr.l #1,d3

 move.l d2,d4	; z sin
 move.l d4,d6
 asr.l #1,d6
 add.l d4,d6
 add.l d3,d4
 neg.l d4	; start x
 
 asr.l #1,d6	; zsin/2
 sub.l d6,d5	; start z
 
 move.w d4,startsmoothx
 move.w d5,startsmoothz
 
 swap d4
 asr.l #8,d5
 add.w szoff,d5
 add.w sxoff,d4
 and.w #63,d4
 and.w #63*256,d5
 move.b d4,d5

 asr.l #6,d1
 asr.l #6,d2
 move.w leftedge(pc),d6
 beq.s nomultleft
 
 move.l d1,d3
 asr.l #6,d3
 muls d6,d3
 asl.l #6,d3
 swap d3
 add.b d3,d5

 move.l d2,d3
 asr.l #6,d3
 muls d6,d3
 asl.l #6,d3
 swap d3
 lsl.w #8,d3
 add.w d3,d5
 
nomultleft:

 move.w d1,a4
 move.w d2,a5
 asr.l #8,d2
 and.w #%0011111100000000,d2
 swap d1
 add.w d1,d2
 move.w #%11111100111111,d1
 and.w d1,d5
 swap d5
 move.w startsmoothz,d5
 swap d5
 swap d2
 move.w a5,d2
 swap d2
 
***********************************
 
 move.w d6,a2
 move.l d2,d6
 add.w #256,d6
 
 moveq #0,d0

 tst.w a2
 beq startatleftedge
 
 move.w widthleft(pc),d4
 
 move.w rightedge(pc),d3
 
 cmp.w #31,a2
 bgt.s notinfirststrip
 lea (a3,a2.w*4),a3
 cmp.w #32,d3
 ble.s allinfirststrip
 move.w #32,d7
 sub.w d7,d3
 sub.w a2,d7
 bra intofirststrip

allinfirststrip
 sub.w a2,d3
 move.w d3,d7
 move.w #0,d4
 bra allintofirst

notinfirststrip:
 sub.w #32,a2
 sub.w #32,d3
 adda.w #33*4,a3
 cmp.w #31,a2
 bgt.s notstartinsec
 lea (a3,a2.w*4),a3
 cmp.w #32,d3
 ble.s allinsecstrip
 move.w #32,d7
 sub.w d7,d3
 sub.w a2,d7
 move.w d3,d4
 bra tstwat

allinsecstrip
 sub.w a2,d3
 move.w d3,d7
 move.w #0,d4
 bra tstwat
 rts
 
notstartinsec:
 sub.w #32,a2
 sub.w #32,d3
 adda.w #33*4,a3
 lea (a3,a2.w*4),a3
 cmp.w #32,d3
 ble.s allinthirdstrip
 move.w #32,d7
 sub.w d7,d3
 sub.w a2,d7
 move.w d3,d4
 bra tstwat
 rts

allinthirdstrip
 sub.w a2,d3
 move.w d3,d7
 move.w #0,d4
 bra tstwat
 rts

startatleftedge:

 move.w rightedge(pc),d3
 sub.w a2,d3
 
 move.w d3,d7
 cmp.w #32,d7
 ble.s .notoowide
 move.w #32,d7
.notoowide:
 sub.w d7,d3
intofirststrip:

 move.w d3,d4
allintofirst:

 move.w startsmoothx,d3

tstwat:

 tst.b usewater
 bne texturedwater
 
 
******************************
* BumpMap the floor/ceiling! *
 tst.b usebumps
 bne.s BumpMap
******************************
 
ordinary:
 moveq #0,d0

 dbra d7,acrossscrn
 rts
 
usebumps: dc.w $0
smoothbumps: dc.w $0
 
 include "ab3:source/bumpmap.s"

 CNOP 0,4
backbefore:
 and.w d1,d5
 move.b (a0,d5.w*4),d0
 move.w (a1,d0.w*2),(a3)
 addq #4,a3
 add.w a4,d3
 addx.l d6,d5
 dbcs d7,acrossscrn
 dbcc d7,backbefore
 bcc.s past1
 add.w #256,d5 
 bra.s past1
 
acrossscrn:
 and.w d1,d5
 move.b (a0,d5.w*4),d0
 move.w (a1,d0.w*2),(a3)
 addq #4,a3
 add.w a4,d3
 addx.l d2,d5
 dbcs d7,acrossscrn
 dbcc d7,backbefore
 bcc.s past1
 add.w #256,d5 
past1:

 move.w d4,d7
 bne.s .notdoneyet
 CACHE_FREEZE_ON d2
 rts
.notdoneyet:

 cmp.w #32,d7
 ble.s .notoowide
 move.w #32,d7
.notoowide
 sub.w d7,d4  
 addq #4,a3
 
 dbra d7,acrossscrn
 CACHE_FREEZE_ON d2
 rts
 
waterpt: dc.l waterlist

waterlist:
 dc.l waterfile
 dc.l waterfile+2
 dc.l waterfile+256
 dc.l waterfile+256+2
 dc.l waterfile+512
 dc.l waterfile+512+2
 dc.l waterfile+768
 dc.l waterfile+768+2
; dc.l waterfile+768
; dc.l waterfile+512+2
; dc.l waterfile+512
; dc.l waterfile+256+2
; dc.l waterfile+256
; dc.l waterfile+2
endwaterlist:
 
watertouse: dc.l waterfile
 
wtan: dc.w 0
wateroff: dc.w 0
 
texturedwater:

 add.w wateroff,d5

 move.l #brightentab,a1
 move.w dst,d0
 clr.b d0
 add.w d0,d0
 adda.w d0,a1

 move.w dst,d0
 asl.w #7,d0
 add.w wtan,d0
 and.w #8191,d0
 move.l #SineTable,a0
 move.w (a0,d0.w),d0
 ext.l d0
 move.w dst,d3
 add.w #300,d3
 divs d3,d0
 asr.w #6,d0
 add.w #2,d0
 
 move.w dst,d3
 asr.w #7,d3
 add.w d3,d0
 
 muls #104*4,d0
 move.w d0,a6

 move.l watertouse,a0

 move.w startsmoothx,d3
 dbra d7,acrossscrnw
 rts

backbeforew:
 and.w d1,d5
 move.w (a0,d5.w*4),d0
 move.b 1(a3,a6.w),d0
 move.w (a1,d0.w*2),(a3)
 addq #4,a3
 add.w a4,d3
 addx.l d6,d5
 dbcs d7,acrossscrnw
 dbcc d7,backbeforew
 bcc.s past1w
 add.w #256,d5 
 bra.s past1w
 
acrossscrnw:
 and.w d1,d5
 move.w (a0,d5.w*4),d0
 move.b 1(a3,a6.w),d0
 move.w (a1,d0.w*2),(a3)
 addq #4,a3
 add.w a4,d3
 addx.l d2,d5
 dbcs d7,acrossscrnw
 dbcc d7,backbeforew
 bcc.s past1w
 add.w #256,d5 
past1w:

 move.w d4,d7
 bne.s .notdoneyet
 rts
.notdoneyet:

 cmp.w #32,d7
 ble.s .notoowide
 move.w #32,d7
.notoowide
 sub.w d7,d4  
 addq #4,a3
 
 dbra d7,acrossscrnw
 CACHE_FREEZE_ON d2
 rts

usewater: dc.w 0
startsmoothx: dc.w 0
startsmoothz: dc.w 0

********************************
*
 include "AB3:source/ObjDraw3.chipram"
*
********************************

numframes:
 dc.w 0

alframe: dc.l Objects+4096
 
alan:
 dcb.l 6,0
 dcb.l 6,1
 dcb.l 6,2
 dcb.l 6,3
endalan:

alanptr: dc.l alan

Time2: dc.l 0
dispco:
 dc.w 0

KInt_Init	;VBR Assumed $0
		move.l $68.w,OLDKINT
		Move.l	#KInt_Main,$68.w	Install Interrupt 
		And.b	#$3f,$bfe201		Set Timers
		Move.b	#$7f,$bfed01
		Move.b	$bfed01,d0
		Move.b	#$88,$bfed01
		St.b	KInt_CCode		
		Move.b	#$a0,$bfee01		Start Timey Thing
		Rts				And return

OLDKINT: dc.l 0

KInt_Main	
		Movem.l	d0/d1/a0/a1/a6,-(a7)	Stack everything
		Move.w	#8,$dff09a		Temp Disable Int.
		Move.w	$dff01e,d0		Intreqr
		And.w	#8,d0			Mask Out All X^ K_Int
	Beq	KInt_End			Not Keyboard Interrupt
		Lea	$bfed01,a6
		Move.w	#$8,$dff09c		Clear Int.Request
		Move.b	-$100(a6),d0		Move Raw Keyboard value
		Ror.b	#1,d0			Roll to correct
		Not.b	d0			
		Move.b	d0,KInt_CCode		Save Corrected Keycode
.HandShake	Move.b	#8,(a6)
		Move.b	#7,-$900(a6)
		Move.b	#0,-$800(a6)
		Move.b	#0,-$100(a6)
		Move.b	#$d1,$100(a6)		
		Tst.b	(a6)	
.wait		Btst	#0,(a6)
	Beq.s	.wait
		Move.b	#$a0,$100(a6)		
		Move.b	(a6),d0		
		Move.b	#$88,(a6)
		Lea	KeyMap,a1
		Moveq.w	#0,d0
		Move.b	KInt_CCode(pc),d0
	Bmi.s	KInt_KeyUp			neg if up 

KInt_KeyDown
		st (a1,d0.w)
	Bra	KInt_End

KInt_KeyUp
		And.w	#$7f,d0			Make code Positive
		clr.b (a1,d0.w)
KInt_End	Movem.l	(a7)+,d0/d1/a0/a1/a6	Unstack Everything
	
		Move.w	#$8008,$dff09a		Re-enable Int.
		Rte

KInt_CCode	Ds.b	1
KInt_Askey	Ds.b	1
KInt_OCode	Ds.w	1

 
PLR1_mouse_control
 jsr ReadMouse
 move.l #SineTable,a0
 move.w PLR1s_angspd,d1
 move.w PLR1s_angpos,d0
 move.w (a0,d0.w),PLR1s_sinval
 adda.w #2048,a0
 move.w (a0,d0.w),PLR1s_cosval

 move.l PLR1s_xspdval,d6
 move.l PLR1s_zspdval,d7

 neg.l d6
 ble.s .nobug1
 asr.l #1,d6
 add.l #1,d6
 bra.s .bug1
.nobug1
 asr.l #1,d6
.bug1:

 neg.l d7
 ble.s .nobug2
 asr.l #1,d7
 add.l #1,d7
 bra.s .bug2
.nobug2
 asr.l #1,d7
.bug2: 

 move.w PLR1s_sinval,d1
 move.w PLR1s_cosval,d2
 
 move.w d2,d4
 move.w d1,d5
 muls lrs,d4
 muls lrs,d5
 
 move.w ymouse,d3
 sub.w oldymouse,d3
 add.w d3,oldymouse
 asr.w #1,d3
 cmp.w #50,d3
 ble.s nofastfor
 move.w #50,d3
nofastfor:
 cmp.w #-50,d3
 bge.s nofastback
 move.w #-50,d3
nofastback:

 muls d3,d2
 muls d3,d1
 sub.l d4,d1
 add.l d5,d2

 sub.l d1,d6
 sub.l d2,d7
 add.l d6,PLR1s_xspdval
 add.l d7,PLR1s_zspdval
 move.l PLR1s_xspdval,d6
 move.l PLR1s_zspdval,d7
 add.l d6,PLR1s_xoff
 add.l d7,PLR1s_zoff

 tst.b PLR1_fire
 beq.s .firenotpressed
; fire was pressed last time.
 btst #6,$bfe001
 bne.s .firenownotpressed
; fire is still pressed this time.
 st PLR1_fire
 bra .doneplr1
 
.firenownotpressed:
; fire has been released.
 clr.b PLR1_fire
 bra .doneplr1
 
.firenotpressed

; fire was not pressed last frame...

 btst #6,$bfe001
; if it has still not been pressed, go back above
 bne.s .firenownotpressed
; fire was not pressed last time, and was this time, so has
; been clicked.
 st PLR1_clicked
 st PLR1_fire

.doneplr1:
 move.l PLR1s_tyoff,d0
 move.l PLR1s_yoff,d1
 move.l PLR1s_yvel,d2
 sub.l d1,d0
 bgt.s .aboveground
 sub.l #1024,d2
 blt.s .notfast
 sub.l #2048,d2
.notfast:
 add.l d2,d1
 sub.l d2,d0
 blt.s .pastitall
 move.l #0,d2
 add.l d0,d1
 bra.s .pastitall

.aboveground:
 add.l d2,d1
 add.l #1024,d2
.pastitall:

 move.l d2,PLR1s_yvel
 move.l d1,PLR1s_yoff
 
 rts

PLR1_follow_path:

 move.l pathpt,a0
 move.w (a0),d1
 move.w d1,PLR1s_xoff
 move.w 2(a0),d1
 move.w d1,PLR1s_zoff
 move.w 4(a0),d0
 add.w d0,d0
 and.w #8190,d0
 move.w d0,PLR1_angpos

 move.w TempFrames,d0
 asl.w #3,d0
 adda.w d0,a0
 
 cmp.l #endpath,a0
 blt notrestartpath
 move.l #Path,a0
notrestartpath:
 move.l a0,pathpt

 rts
 
OldSpace: dc.b 0
SpaceTapped: dc.b 0
SPCTAP: dc.b 0
 even

PLR1_keyboard_control:

 move.l #SineTable,a0
 move.w PLR1s_angpos,d0
 
 move.l #KeyMap,a5
 move.b $40(a5),d1
 beq.s nottapped
 tst.b OldSpace
 bne.s nottapped
 st SpaceTapped
nottapped:
 move.b d1,OldSpace

 move.w #70,d1
 move.w #7,d2
 tst.b $61(a5)
 beq.s nofaster
 move.w #120,d1
 move.w #10,d2
nofaster:

 moveq #0,d4 
; tst.b $67(a5)
; bne.s slidelr
 
 tst.b $4f(a5)
 beq.s noleftturn
 sub.w d1,d0
noleftturn
 move.l #KeyMap,a5
 tst.b $4e(a5)
 beq.s norightturn
 add.w d1,d0
norightturn
; bra.s noslide

slidelr:
 tst.b $39(a5)
 beq.s noleftslide
 move.w d2,d4
 asr.w #1,d4
noleftslide
 move.l #KeyMap,a5
 tst.b $3a(a5)
 beq.s norightslide
 sub.w d2,d4
 asr.w #1,d4
norightslide
  
noslide:
  
 and.w #8191,d0
 move.w d0,PLR1s_angpos
 
 move.w (a0,d0.w),PLR1s_sinval
 adda.w #2048,a0
 move.w (a0,d0.w),PLR1s_cosval

 move.l PLR1s_xspdval,d6
 move.l PLR1s_zspdval,d7

 neg.l d6
 ble.s .nobug1
 asr.l #1,d6
 add.l #1,d6
 bra.s .bug1
.nobug1
 asr.l #1,d6
.bug1:

 neg.l d7
 ble.s .nobug2
 asr.l #1,d7
 add.l #1,d7
 bra.s .bug2
.nobug2
 asr.l #1,d7
.bug2: 

 moveq #0,d3
 
 tst.b $4c(a5)
 beq.s noforward
 neg.w d2
 move.w d2,d3
 
noforward:
 tst.b $4d(a5)
 beq.s nobackward
 move.w d2,d3
nobackward:
 
 move.w d3,d2
 asl.w #3,d2
 move.w d2,d1
 add.w d2,d1
 add.w d2,d1
 add.w Bobble,d1
 and.w #8190,d1
 move.w d1,Bobble
 
 move.w PLR1s_sinval,d1
 muls d3,d1
 move.w PLR1s_cosval,d2
 muls d3,d2

 sub.l d1,d6
 sub.l d2,d7
 move.w PLR1s_sinval,d1
 muls d4,d1
 move.w PLR1s_cosval,d2
 muls d4,d2
 sub.l d2,d6
 add.l d1,d7
 
 add.l d6,PLR1s_xspdval
 add.l d7,PLR1s_zspdval
 move.l PLR1s_xspdval,d6
 move.l PLR1s_zspdval,d7
 add.l d6,PLR1s_xoff
 add.l d7,PLR1s_zoff
 
 tst.b PLR1_fire
 beq.s .firenotpressed
; fire was pressed last time.
 tst.b $65(a5)
 beq.s .firenownotpressed
; fire is still pressed this time.
 st PLR1_fire
 bra .doneplr1
 
.firenownotpressed:
; fire has been released.
 clr.b PLR1_fire
 bra .doneplr1
 
.firenotpressed

; fire was not pressed last frame...

 tst.b $65(a5)
; if it has still not been pressed, go back above
 beq.s .firenownotpressed
; fire was not pressed last time, and was this time, so has
; been clicked.
 st PLR1_clicked
 st PLR1_fire

.doneplr1:

 move.l PLR1s_tyoff,d0
 move.l PLR1s_yoff,d1
 move.l PLR1s_yvel,d2
 sub.l d1,d0
 bgt.s .aboveground
 sub.l #1024,d2
 blt.s .notfast
 sub.l #2048,d2
.notfast:
 add.l d2,d1
 sub.l d2,d0
 blt.s .pastitall
 move.l #0,d2
 add.l d0,d1
 bra.s .pastitall

.aboveground:
 add.l d2,d1
 add.l #1024,d2
.pastitall:

 move.l d2,PLR1s_yvel
 move.l d1,PLR1s_yoff

 rts


Chan0inter:

 move.w #$0010,$dff000+intreq

 addq.w #1,FramesToDraw
 tst.b counting
 beq nostopcounter
 JSR STOPCOUNTNOADD
nostopcounter:
 movem.l d0-d7/a0-a6,-(a7)
 
 moveq #0,d7
 move.l #KeyMap,a5
 tst.b $4f(a5)
 beq.s nop1
 bset #0,d7
nop1:
 tst.b $4e(a5)
 beq.s nop2
 bset #1,d7
nop2:
 tst.b $4c(a5)
 beq.s nop3
 bset #2,d7
nop3:
 tst.b $4d(a5)
 beq.s nop4
 bset #3,d7
nop4:
 tst.b $39(a5)
 beq.s nop5
 bset #4,d7
nop5:
 tst.b $3a(a5)
 beq.s nop6
 bset #5,d7
nop6:
 tst.b $61(a5)
 beq.s nop7
 bset #6,d7
nop7:
 tst.b $65(a5)
 beq.s nop8
 bset #7,d7
nop8:
 move.l RECORDPTR,a0
 move.b d7,(a0)
 
 clr.b d7
 tst.b $40(a5)
 beq.s nop9
 bset #7,d7
nop9:
 or.b d7,1(a0)
 
 addq #2,a0
 move.l a0,RECORDPTR
 
 tst.b oktodisplay
 beq dontshowtime
 clr.b oktodisplay
 subq.w #1,dispco
 bgt dontshowtime
 move.w #10,dispco
 
 move.l #TimerScr+10,a0
 move.l TimeCount,d0
 bge.s timenotneg
 move.l #1111*256,d0
timenotneg:
 asr.l #8,d0
 move.l #digits,a1
 move.w #7,d2
digitlop
 divs #10,d0
 swap d0
 lea (a1,d0.w*8),a2
 move.b (a2)+,(a0)
 move.b (a2)+,24(a0)
 move.b (a2)+,24*2(a0)
 move.b (a2)+,24*3(a0)
 move.b (a2)+,24*4(a0)
 move.b (a2)+,24*5(a0)
 move.b (a2)+,24*6(a0)
 move.b (a2)+,24*7(a0)
 subq #1,a0
 swap d0
 ext.l d0
 dbra d2,digitlop

 move.l #TimerScr+10+24*10,a0
 move.l NumTimes,d0
 move.l #digits,a1
 move.w #3,d2
digitlop2
 divs #10,d0
 swap d0
 lea (a1,d0.w*8),a2
 move.b (a2)+,(a0)
 move.b (a2)+,24(a0)
 move.b (a2)+,24*2(a0)
 move.b (a2)+,24*3(a0)
 move.b (a2)+,24*4(a0)
 move.b (a2)+,24*5(a0)
 move.b (a2)+,24*6(a0)
 move.b (a2)+,24*7(a0)
 subq #1,a0
 swap d0
 ext.l d0
 dbra d2,digitlop2

 move.l #TimerScr+10+24*20,a0
 moveq #0,d0
 move.w FramesToDraw,d0
 move.l #digits,a1
 move.w #2,d2
digitlop3
 divs #10,d0
 swap d0
 lea (a1,d0.w*8),a2
 move.b (a2)+,(a0)
 move.b (a2)+,24(a0)
 move.b (a2)+,24*2(a0)
 move.b (a2)+,24*3(a0)
 move.b (a2)+,24*4(a0)
 move.b (a2)+,24*5(a0)
 move.b (a2)+,24*6(a0)
 move.b (a2)+,24*7(a0)
 subq #1,a0
 swap d0
 ext.l d0
 dbra d2,digitlop3

dontshowtime:

 move.w Robotanimpos,d0
 add.w #6*38,d0
 cmp.w #6*38*64,d0
 blt.s norebot
 move.w #0,d0
norebot:
 move.w d0,Robotanimpos
 
 tst.w d0
 seq d1
 cmp.w #6*32*38,d0
 seq d2
 or.b d2,d1
 or.b d1,clump
 
 move.w Robotarmpos,d0
 add.w #6*14,d0
 cmp.w #6*14*64,d0
 blt.s norebot2
 move.w #0,d0
norebot2:
 move.w d0,Robotarmpos
 
 move.l alanptr,a0
 move.l (a0)+,alframe
 cmp.l #endalan,a0
 blt.s nostartalan
 move.l #alan,a0
nostartalan:
 move.l a0,alanptr
 
 move.l #$dff000,a6

 cmp.b #'4',option+2
 bne.s nomuckabout
 
 move.w #$0,d0 
 tst.b NoiseMade0
 beq.s noturnoff0
 move.w #1,d0
noturnoff0:
 tst.b NoiseMade1
 beq.s noturnoff1
 or.w #2,d0
noturnoff1:
 tst.b NoiseMade2
 beq.s noturnoff2
 or.w #4,d0
noturnoff2:
 tst.b NoiseMade3
 beq.s noturnoff3
 or.w #8,d0
noturnoff3:
 move.w d0,dmacon(a6)
 
nomuckabout:

 tst.b PLR1MOUSE
 beq.s PLR1_nomouse
 bsr PLR1_mouse_control
PLR1_nomouse:
 tst.b PLR1KEYS
 beq.s PLR1_nokeys
 bsr PLR1_keyboard_control
PLR1_nokeys:
 tst.b PLR1PATH
 beq.s PLR1_nopath
 bsr PLR1_follow_path
PLR1_nopath:
 
 
 tst.b PLR2_fire
 beq.s firenotpressed2
; fire was pressed last time.
 btst #7,$bfe001
 bne.s firenownotpressed2
; fire is still pressed this time.
 st PLR2_fire
 bra dointer
 
firenownotpressed2:
; fire has been released.
 clr.b PLR2_fire
 bra dointer
 
firenotpressed2

; fire was not pressed last frame...

 btst #7,$bfe001
; if it has still not been pressed, go back above
 bne.s firenownotpressed2
; fire was not pressed last time, and was this time, so has
; been clicked.
 st PLR2_clicked
 st PLR2_fire
 
dointer
 
 cmp.b #'4',option+2
 beq fourchannel
 
 btst #7,$dff000+intreqrl
 bne.s newsampbitl

 movem.l (a7)+,d0-d7/a0-a6
 tst.b counting
 beq .nostartcounter
 JSR STARTCOUNT
.nostartcounter:
noneed:
 
 rte
 
swappedem: dc.w 0
 
newsampbitl:

 move.w #$820f,$dff000+dmacon

 move.w #$80,$dff000+intreq
 
 move.l pos0,a0
 move.l pos1,a1

 move.l #tab,a2
 
 moveq #0,d0
 moveq #0,d1
 move.b vol0left,d0
 move.b vol1left,d1
 cmp.b d1,d0
 bge.s fbig0

; d1 is bigger so scale d0 and use d1
; as audiochannel volume.

 exg a0,a1
 asl.w #6,d0
 divs d1,d0
 lsl.w #8,d0
 adda.w d0,a2
 move.w d1,$dff0a8
 bra.s donechan0

fbig0:
 tst.w d0
 beq.s donechan0
 asl.w #6,d1
 divs d0,d1
 lsl.w #8,d1
 adda.w d1,a2
 move.w d0,$dff0a8

donechan0:
 
 
 move.l Aupt0,a3
 move.l a3,$dff0a0
 move.l Auback0,Aupt0
 move.l a3,Auback0
 
 move.l Auback0,a3
 
 moveq #0,d0
 moveq #0,d1
 moveq #0,d2
 moveq #0,d3
 moveq #0,d4
 moveq #0,d5
 move.w #49,d7
loop:
 move.l (a0)+,d0
 move.b (a1)+,d1
 move.b (a1)+,d2
 move.b (a1)+,d3
 move.b (a1)+,d4
 move.b (a2,d3.w),d5
 swap d5
 move.b (a2,d1.w),d5
 asl.l #8,d5
 move.b (a2,d2.w),d5
 swap d5
 move.b (a2,d4.w),d5
 add.l d5,d0
 move.l d0,(a3)+
 dbra d7,loop
 
 move.l pos0,a0
 move.l pos1,a1

 move.l Aupt1,a3
 move.l a3,$dff0b0
 move.l Auback1,Aupt1
 move.l a3,Auback1

 move.l #tab,a2
 
 moveq #0,d0
 moveq #0,d1
 move.b vol0right,d0
 move.b vol1right,d1
 cmp.b d1,d0
 slt swappedem
 bge.s fbig1

; d1 is bigger so scale d0 and use d1
; as audiochannel volume.

 exg a0,a1
 asl.w #6,d0
 divs d1,d0
 lsl.w #8,d0
 adda.w d0,a2
 move.w d1,$dff0b8
 bra.s donechan1

fbig1:
 tst.w d0
 beq.s donechan1
 asl.w #6,d1
 divs d0,d1
 lsl.w #8,d1
 adda.w d1,a2
 move.w d0,$dff0b8

donechan1:
 moveq #0,d0
 moveq #0,d1
 moveq #0,d2
 moveq #0,d3
 moveq #0,d4
 moveq #0,d5
 move.w #49,d7
loop2:
 move.l (a0)+,d0
 move.b (a1)+,d1
 move.b (a1)+,d2
 move.b (a1)+,d3
 move.b (a1)+,d4
 move.b (a2,d3.w),d5
 swap d5
 move.b (a2,d1.w),d5
 asl.l #8,d5
 move.b (a2,d2.w),d5
 swap d5
 move.b (a2,d4.w),d5
 add.l d5,d0
 move.l d0,(a3)+
 dbra d7,loop2
 
 tst.b swappedem
 beq.s ok01
 exg a0,a1
ok01:
 
 cmp.l Samp0end,a0
 blt.s notoffendsamp1
 move.l #bass,a0
 move.l #bassend,Samp0end
 move.b #64,vol0left
 move.b #64,vol0right
 tst.b backbeat
 bne.s playbeat
 move.l #empty,a0
 move.l #emptyend,Samp0end
 move.b #0,vol0left
 move.b #0,vol0right
playbeat:
notoffendsamp1:

 cmp.l Samp1end,a1
 blt.s notoffendsamp2
 move.l #empty,a1
 move.l #emptyend,Samp1end
 move.b #0,vol1left
 move.b #0,vol1right
notoffendsamp2:

 move.l a0,pos0
 move.l a1,pos1

******************* Other two channels

 move.l pos2,a0
 move.l pos3,a1

 move.l #tab,a2
 
 moveq #0,d0
 moveq #0,d1
 move.b vol2left,d0
 move.b vol3left,d1
 cmp.b d1,d0
 bge.s fbig2

; d1 is bigger so scale d0 and use d1
; as audiochannel volume.

 exg a0,a1
 asl.w #6,d0
 divs d1,d0
 lsl.w #8,d0
 adda.w d0,a2
 move.w d1,$dff0d8
 bra.s donechan2

fbig2:
 tst.w d0
 beq.s donechan2
 asl.w #6,d1
 divs d0,d1
 lsl.w #8,d1
 adda.w d1,a2
 move.w d0,$dff0d8

donechan2:

 move.l Aupt2,a3
 move.l a3,$dff0d0
 move.l Auback2,Aupt2
 move.l a3,Auback2
 
 moveq #0,d0
 moveq #0,d1
 moveq #0,d2
 moveq #0,d3
 moveq #0,d4
 moveq #0,d5
 move.w #49,d7
loop3:
 move.l (a0)+,d0
 move.b (a1)+,d1
 move.b (a1)+,d2
 move.b (a1)+,d3
 move.b (a1)+,d4
 move.b (a2,d3.w),d5
 swap d5
 move.b (a2,d1.w),d5
 asl.l #8,d5
 move.b (a2,d2.w),d5
 swap d5
 move.b (a2,d4.w),d5
 add.l d5,d0
 move.l d0,(a3)+
 dbra d7,loop3
 
 move.l pos2,a0
 move.l pos3,a1

 move.l Aupt3,a3
 move.l a3,$dff0c0
 move.l Auback3,Aupt3
 move.l a3,Auback3

 move.l #tab,a2
 
 moveq #0,d0
 moveq #0,d1
 move.b vol2right,d0
 move.b vol3right,d1
 cmp.b d1,d0
 slt.s swappedem
 bge.s fbig3

 exg a0,a1
 asl.w #6,d0
 divs d1,d0
 lsl.w #8,d0
 adda.w d0,a2
 move.w d1,$dff0c8
 bra.s donechan3

fbig3:
 tst.w d0
 beq.s donechan3
 asl.w #6,d1
 divs d0,d1
 lsl.w #8,d1
 adda.w d1,a2
 move.w d0,$dff0c8
donechan3:

 moveq #0,d0
 moveq #0,d1
 moveq #0,d2
 moveq #0,d3
 moveq #0,d4
 moveq #0,d5
 move.w #49,d7
loop4:
 move.l (a0)+,d0
 move.b (a1)+,d1
 move.b (a1)+,d2
 move.b (a1)+,d3
 move.b (a1)+,d4
 move.b (a2,d3.w),d5
 swap d5
 move.b (a2,d1.w),d5
 asl.l #8,d5
 move.b (a2,d2.w),d5
 swap d5
 move.b (a2,d4.w),d5
 add.l d5,d0
 move.l d0,(a3)+
 dbra d7,loop4
 
 tst.b swappedem
 beq.s ok23
 exg a0,a1
ok23:
 
 cmp.l Samp2end,a0
 blt.s notoffendsamp3
 move.l #empty,a0
 move.l #emptyend,Samp2end
 move.b #0,vol2left
 move.b #0,vol2right
notoffendsamp3:

 cmp.l Samp3end,a1
 blt.s notoffendsamp4
 move.l #empty,a1
 move.l #emptyend,Samp3end
 move.b #0,vol3left
 move.b #0,vol3right
notoffendsamp4:

 move.l a0,pos2
 move.l a1,pos3

 movem.l (a7)+,d0-d7/a0-a6
 tst.b counting
 beq .nostartcounter
 JSR STARTCOUNT
.nostartcounter:

 rte
 
***********************************
* 4 channel sound routine
***********************************

fourchannel:

 move.l #$dff000,a6

 btst #7,intreqrl(a6)
 beq.s nofinish0
 move.l #null,$a0(a6)
 move.w #100,$a4(a6)
 tst.b backbeat
 beq.s nobeat

 move.l #bass,$a0(a6)
 move.w #18370/2,$a4(a6)
 move.w #64,$a8(a6)
 
nobeat:
 
 move.w #$0080,intreq(a6)
nofinish0:

 
 tst.b NoiseMade0p
 beq.s NoChan0sound

 move.l Samp0end,d0
 move.l pos0,d1
 sub.l d1,d0
 asr.w #1,d0
 move.w d0,$a4(a6)
 move.l d1,$a0(a6)
 move.w #$8201,dmacon(a6)
 moveq #0,d0
 move.b vol0left,d0
 add.b vol0right,d0
 asr.b #1,d0
 move.w d0,$a8(a6)

NoChan0sound:

 btst #0,intreqr(a6)
 beq.s nofinish1
 move.l #null,$b0(a6)
 move.w #100,$b4(a6)
 move.w #$0100,intreq(a6)
nofinish1:

 tst.b NoiseMade1p
 beq.s NoChan1sound

 move.l Samp1end,d0
 move.l pos1,d1
 sub.l d1,d0
 asr.w #1,d0
 move.w d0,$b4(a6)
 move.l d1,$b0(a6)
 move.w #$8202,dmacon(a6)
 moveq #0,d0
 move.b vol1left,d0
 add.b vol1right,d0
 asr.b #1,d0
 move.w d0,$b8(a6)

NoChan1sound:


 btst #1,intreqr(a6)
 beq.s nofinish2
 move.l #null,$c0(a6)
 move.w #100,$c4(a6)
 move.w #$0200,intreq(a6)
nofinish2:

 tst.b NoiseMade2p
 beq.s NoChan2sound

 move.l Samp2end,d0
 move.l pos2,d1
 sub.l d1,d0
 asr.w #1,d0
 move.w d0,$c4(a6)
 move.l d1,$c0(a6)
 move.w #$8204,dmacon(a6)
 moveq #0,d0
 move.b vol2left,d0
 add.b vol2right,d0
 asr.b #1,d0
 move.w d0,$c8(a6)

NoChan2sound:

 btst #2,intreqr(a6)
 beq.s nofinish3
 move.l #null,$d0(a6)
 move.w #100,$d4(a6)
 move.w #$0400,intreq(a6)
nofinish3:

 tst.b NoiseMade3p
 beq.s NoChan3sound

 move.l Samp3end,d0
 move.l pos3,d1
 sub.l d1,d0
 asr.w #1,d0
 move.w d0,$d4(a6)
 move.l d1,$d0(a6)
 move.w #$8208,dmacon(a6)
 moveq #0,d0
 move.b vol2left,d0
 add.b vol2right,d0
 asr.b #1,d0
 move.w d0,$d8(a6)
 
NoChan3sound:
 
nomorechannels:

 move.l NoiseMade0,NoiseMade0p
 move.l #0,NoiseMade0

 movem.l (a7)+,d0-d7/a0-a6
 tst.b counting
 beq .nostartcounter
 JSR STARTCOUNT
.nostartcounter:

 rte
 
backbeat: dc.w 0

Samp0end: dc.l emptyend
Samp1end: dc.l emptyend
Samp2end: dc.l emptyend
Samp3end: dc.l emptyend

Aupt0: dc.l null
Auback0: dc.l null+500
Aupt2: dc.l null3
Auback2: dc.l null3+500
Aupt3: dc.l null4
Auback3: dc.l null4+500
Aupt1: dc.l null2
Auback1: dc.l null2+500

NoiseMade0: dc.b 0
NoiseMade1: dc.b 0
NoiseMade2: dc.b 0
NoiseMade3: dc.b 0
NoiseMade0p: dc.b 0
NoiseMade1p: dc.b 0
NoiseMade2p: dc.b 0
NoiseMade3p: dc.b 0

empty: ds.l 100
emptyend:
 
**************************************
* I want a routine to calculate all the
* info needed for the sound player to
* work, given say position of noise, volume
* and sample number.

Samplenum: dc.w 0
Noisex: dc.w 0
Noisez: dc.w 0
Noisevol: dc.w 0
chanpick: dc.w 0
 
PLAYEDTAB: ds.l 20
 
MakeSomeNoise:

 move.w Noisex,d1
 muls d1,d1
 move.w Noisez,d2
 muls d2,d2
 move.w #64,d3
 moveq #1,d0
 add.l d1,d2
 beq pastcalc

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

 move.w d0,d3
 muls d3,d3	; x*x
 sub.l d2,d3	; x*x-a
 asr.l #1,d3	; (x*x-a)/2
 divs d0,d3	; (x*x-a)/2x
 sub.w d3,d0	; second approx
 bgt .stillnot0
 move.w #1,d0
.stillnot0

 move.w d0,d3
 muls d3,d3
 sub.l d2,d3
 asr.l #1,d3
 divs d0,d3
 sub.w d3,d0	; second approx
 bgt .stillnot02
 move.w #1,d0
.stillnot02
 
 move.w #64,d3
 muls Noisevol,d3
 asr.w #1,d0
 addq #1,d0
 divs d0,d3

 cmp.w #64,d3
 ble.s notooloud
 move.w #64,d3
notooloud:

pastcalc:

	; d3 contains volume of noise.
	
 move.w d3,d4
 
 move.w d3,d2
 muls Noisex,d2
 add.w d0,d0
 divs d0,d2
 
 bgt.s quietleft
 add.w d2,d4
 bge.s donequiet
 move.w #0,d4
 bra.s donequiet
quietleft:
 sub.w d2,d3
 bge.s donequiet
 move.w #0,d3
donequiet:

; d3=leftvol?
; d4=rightvol?

 move.l #SampleList,a3

 tst.b chanpick
 seq NoiseMade0
 beq.s chan0
 cmp.b #1,chanpick
 seq NoiseMade1
 beq chan1
 cmp.b #2,chanpick
 seq NoiseMade2
 beq chan2
 st NoiseMade3

 move.w Samplenum,d0
 move.l (a3,d0.w*8),a1
 move.l 4(a3,d0.w*8),a2
 
 tst.b notifplaying
 beq.s .play
 cmp.l Samp3end,a2
 bne.s .play
 rts
.play
 
 move.b d0,PLAYEDTAB+9
 move.b d3,PLAYEDTAB+1+9
 move.b d4,PLAYEDTAB+2+9
 move.b d3,vol3left
 move.b d4,vol3right
 move.l a1,pos3
 move.l a2,Samp3end

 rts
 
chan0: 
 move.w Samplenum,d0
 
 move.l (a3,d0.w*8),a1
 move.l 4(a3,d0.w*8),a2
 tst.b notifplaying
 beq.s .play
 cmp.l Samp0end,a2
 bne.s .play
 rts
.play
 move.b d0,PLAYEDTAB
 move.b d3,PLAYEDTAB+1
 move.b d4,PLAYEDTAB+2
 move.l a1,pos0
 move.l a2,Samp0end
 move.b d3,vol0left
 move.b d4,vol0right
 
 rts
 
chan1:
 
 move.w Samplenum,d0
 move.l (a3,d0.w*8),a1
 move.l 4(a3,d0.w*8),a2
 tst.b notifplaying
 beq.s .play
 cmp.l Samp1end,a2
 bne.s .play
 rts
.play
 move.b d0,PLAYEDTAB+3
 move.b d3,PLAYEDTAB+1+3
 move.b d4,PLAYEDTAB+2+3
 move.b d3,vol1left
 move.b d4,vol1right
 move.l a1,pos1
 move.l a2,Samp1end

 rts

chan2: 
 move.w Samplenum,d0
 move.l (a3,d0.w*8),a1
 move.l 4(a3,d0.w*8),a2
 tst.b notifplaying
 beq.s .play
 cmp.l Samp1end,a2
 bne.s .play
 rts
.play
 move.b d0,PLAYEDTAB+6
 move.b d3,PLAYEDTAB+1+6
 move.b d4,PLAYEDTAB+2+6
 move.l a1,pos2
 move.l a2,Samp2end
 move.b d3,vol2left
 move.b d4,vol2right
 
 rts

SampleList
 dc.l Scream,EndScream
 dc.l Shoot,EndShoot
 dc.l Munch,EndMunch
 dc.l PooGun,EndPooGun
 dc.l Collect,EndCollect
 dc.l DoorNoise,EndDoorNoise
 dc.l bass,bassend
 dc.l Stomp,EndStomp
 dc.l LowScream,EndLowScream
 dc.l BaddieGun,EndBaddieGun
 dc.l SwitchNoise,EndSwitch

saveinters:  
 dc.w 0

z: dc.w 10

notifplaying:
 dc.w 0

audpos1: dc.w 0
audpos1b: dc.w 0
audpos2: dc.w 0
audpos2b: dc.w 0
audpos3: dc.w 0
audpos3b: dc.w 0
audpos4: dc.w 0
audpos4b: dc.w 0

vol0left: dc.w 0
vol0right: dc.w 0
vol1left: dc.w 0
vol1right: dc.w 0
vol2left: dc.w 0
vol2right: dc.w 0
vol3left: dc.w 0
vol3right: dc.w 0

pos: dc.l 0

pos0: dc.l empty
pos1: dc.l empty
pos2: dc.l empty
pos3: dc.l empty


numtodo dc.w 0

npt: dc.w 0

pretab:
val SET 0
 REPT 128
 dc.b val
val SET val+1
 ENDR
val SET -128
 REPT 128
 dc.b val
val SET val+1
 ENDR 

tab:
 ds.b 256*65


test: dc.l 0
 ds.l 30

 even
ConstCols:
 incbin "ConstCols"
 even
Smoothscalecols:
; incbin "smoothbumppalscaled"
 even
SmoothTile:
; incbin "smoothbumptile"
 even
Bumpscalecols:
 incbin "Bumppalscaled"
 even
Bumptile:
 incbin "bumptile"
 even
scalecols: incbin "bytepixpalscaled"
 even
floorscalecols: incbin "floorpalscaled"
 even
walltiles:
 incbin "bytepixfile"
 even
floortile:
 incbin "floortile" 
 even
wallrouts:
; incbin "2x2WallDraw" 
 CNOP 0,64
BackPicture:
 incbin "backfile"
EndBackPicture:

drawpt: dc.l colbars2
olddrawpt: dc.l colbars
frompt: dc.l 0 
 
SineTable:
 incbin "bigsine"

angpos: dc.w 0
angspd: dc.w 0
flooryoff: dc.w 0
xoff: dc.l 0
yoff: dc.l 0
yvel: dc.l 0
zoff: dc.l 0
tyoff: dc.l 0
xspdval: dc.l 0
zspdval: dc.l 0
Zone: dc.w 0

PLR1: dc.b $ff
 even
PLR1_cosval: dc.w 0
PLR1_sinval: dc.w 0
PLR1_angpos: dc.w 0
PLR1_angspd: dc.w 0
PLR1_xoff: dc.l 0
PLR1_yoff: dc.l 0
PLR1_yvel: dc.l 0
PLR1_zoff: dc.l 0
PLR1_tyoff: dc.l 0
PLR1_xspdval: dc.l 0
PLR1_zspdval: dc.l 0
PLR1_Zone: dc.w 0
PLR1_Roompt: dc.l 0
PLR1_OldRoompt: dc.l 0
PLR1_PointsToRotatePtr: dc.l 0
PLR1_ListOfGraphRooms: dc.l 0
PLR1_oldxoff: dc.l 0
PLR1_oldzoff: dc.l 0

 ds.w 4

PLR1s_cosval: dc.w 0
PLR1s_sinval: dc.w 0
PLR1s_angpos: dc.w 0
PLR1s_angspd: dc.w 0
PLR1s_xoff: dc.l 0
PLR1s_yoff: dc.l 0
PLR1s_yvel: dc.l 0
PLR1s_zoff: dc.l 0
PLR1s_tyoff: dc.l 0
PLR1s_xspdval: dc.l 0
PLR1s_zspdval: dc.l 0
PLR1s_Zone: dc.w 0
PLR1s_Roompt: dc.l 0
PLR1s_OldRoompt: dc.l 0
PLR1s_PointsToRotatePtr: dc.l 0
PLR1s_ListOfGraphRooms: dc.l 0
PLR1s_oldxoff: dc.l 0
PLR1s_oldzoff: dc.l 0

 ds.w 4

PLR2: dc.b $0
 even
PLR2_cosval: dc.w 0
PLR2_sinval: dc.w 0
PLR2_angpos: dc.w 0
PLR2_angspd: dc.w 0
PLR2_xoff: dc.l 0
PLR2_yoff: dc.l 0
PLR2_yvel: dc.l 0
PLR2_zoff: dc.l 0
PLR2_tyoff: dc.l 0
PLR2_xspdval: dc.l 0
PLR2_zspdval: dc.l 0
PLR2_Zone: dc.w 0
PLR2_Roompt: dc.l 0
PLR2_OldRoompt: dc.l 0
PLR2_PointsToRotatePtr: dc.l 0
PLR2_ListOfGraphRooms: dc.l 0
PLR2_ForwardSpd: dc.w 0

liftanimtab:

endliftanimtab:
 
glassball: incbin "glassball.inc"
endglass
glassballpt: dc.l glassball
 
rndtab: ; incbin "randfile"
endrnd: 
 
brightanimtab:
 dcb.w 200,20
 dc.w 5
 dc.w 10,20
 dc.w 5
 dcb.w 30,20
 dc.w 7,10,10,5,10,0,5,6,5,6,5,6,5,6,0
 dcb.w 40,0
 dc.w 1,2,3,2,3,2,3,2,3,2,3,2,3,0
 dcb.w 300,0
 dc.w 1,0,1,0,2,2,2,5,5,5,5,5,5,5,5,5,6,10
 dc.w -1

Roompt: dc.l 0
OldRoompt: dc.l 0

*****************************************************************
 *
 include "AB3:source/LevelData2"
 *
*****************************************************************


wallpt: dc.l 0
floorpt: dc.l 0

Rotated:
 ds.l 800 
ObjRotated:
 ds.l 800

OnScreen:
 ds.l 800 
 
startwait: dc.w 0
endwait: dc.w 0

Faces: incbin "faces2raw"

*******************************************************************

consttab:
 incbin "constantfile"

*******************************************************************
 
darkentab: incbin "darkenedcols"
brightentab: incbin "brightenfile"
WorkSpace:
 ds.l 8192 
waterfile: incbin "waterfile"

RECORDPTR: dc.l RECORDBUFFER

RECORDBUFFER: ds.b 50*1000

 SECTION ffff,CODE_C

nullspr: dc.l 0
 
 cnop 0,8
borders:
 incbin "borderspr"

null: ds.w 500
null2: ds.w 500
null3: ds.w 500
null4: ds.w 500


Blurbfield:

 dc.w bpl1ptl
bl1l: dc.w 0
 dc.w bpl1pth
bl1h: dc.w 0

 dc.w diwstart,$2c81
 dc.w diwstop,$1cc1
 dc.w ddfstart,$38
 dc.w ddfstop,$b8
 dc.w bplcon0,$9201
 dc.w bplcon1,0
 dc.w $106,$c40
blcols:
 dc.w col0,0
 dc.w col1,$fff

 dc.w $108,0
 dc.w $10a,0

 dc.w $ffff,$fffe
 dc.w $ffff,$fffe

bigfield:    
                ; Start of our copper list.

 dc.w dmacon,$8020
 dc.w intreq,$8011
 dc.w $1fc,$7
 dc.w diwstart
winstart: dc.w $2cb1
 dc.w diwstop
winstop: dc.w $2c91
 dc.w ddfstart
fetchstart: dc.w $48
 dc.w ddfstop
fetchstop: dc.w $88

 dc.w spr0ptl
s0l:
 dc.w 0
 dc.w spr0pth
s0h:
 dc.w 0
 dc.w spr1ptl
s1l:
 dc.w 0
 dc.w spr1pth
s1h:
 dc.w 0
 dc.w spr2ptl
s2l:
 dc.w 0
 dc.w spr2pth
s2h:
 dc.w 0
 dc.w spr3ptl
s3l:
 dc.w 0
 dc.w spr3pth
s3h:
 dc.w 0
 dc.w spr4ptl
s4l:
 dc.w 0
 dc.w spr4pth
s4h:
 dc.w 0
 dc.w spr5ptl
s5l:
 dc.w 0
 dc.w spr5pth
s5h:
 dc.w 0
 dc.w spr6ptl
s6l:
 dc.w 0
 dc.w spr6pth
s6h:
 dc.w 0
 dc.w spr7ptl
s7l:
 dc.w 0
 dc.w spr7pth
s7h:
 dc.w 0

 dc.w $106,$8c42
 dc.w col0,$0
 dc.w $106,$c42
 dc.w col0,0

 dc.w $106,$c42
 incbin "borderpal"

 dc.w bplcon0,$7201
 dc.w bplcon1
smoff:
 dc.w $0

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
 dc.w intreq,$11
yposcop:
 dc.w $2a11,$fffe
 dc.w $8a,0
 
 ds.l 104*12
 
colbars:
val SET $2a
 dcb.l 104*scrheight,$1fe0000
 dc.w $106,$c42
 
 dc.w $80
pch1:
 dc.w 0
 dc.w $82
pcl1:
 dc.w 0 
 dc.w $88,0
 
 dc.w $ffff,$fffe       ; End copper list.

 ds.l 104*12

colbars2:
val SET $2a
 dcb.l 104*scrheight,$1fe0000
 
 dc.w $106,$c42
 
 dc.w $80
pch2:
 dc.w 0
 dc.w $82
pcl2:
 dc.w 0
 
 dc.w $88,0
 
 dc.w $ffff,$fffe       ; End copper list.

 ds.l 104*10

old: dc.l 0

PanelCop:

 dc.w bplcon0,1

 dc.w $106,$c42
 dc.w $10c,1
 dc.w $10e,0

 incbin "Panelcols"

 dc.w $108,0
 dc.w $10a,0

 dc.w bpl1pth
p1h
 dc.w 0

 dc.w bpl1ptl
p1l
 dc.w 0

 dc.w bpl2pth
p2h
 dc.w 0

 dc.w bpl2ptl
p2l
 dc.w 0

 dc.w bpl3pth
p3h
 dc.w 0

 dc.w bpl3ptl
p3l
 dc.w 0

 dc.w bpl4pth
p4h
 dc.w 0
 dc.w bpl4ptl
p4l
 dc.w 0
 dc.w bpl5pth
p5h
 dc.w 0
 dc.w bpl5ptl
p5l
 dc.w 0
 
 dc.w $80
och:
 dc.w 0
 dc.w $82
ocl:
 dc.w 0

 dc.w $106,$2c40
 incbin "borderpal"
 dc.w $10c,$3
 dc.w $106,$c40
 
 dc.w $cf01,$ff00
 dc.w bplcon0
Panelcon: dc.w $5201
 dc.w $180,$fff

 dc.w $f801,$ff00
 dc.w col1,$50
 dc.w $f901,$ff00
 dc.w col1,$90
 dc.w $fa01,$ff00
 dc.w col1,$f0
 dc.w $fb01,$ff00
 dc.w col1,$f0
 dc.w $fc01,$ff00
 dc.w col1,$90
 dc.w $fd01,$ff00
 dc.w col1,$50

 dc.w $fe01,$ff00
 dc.w col1,$fff
 
 dc.w $ffdf,$fffe
 dc.w $a01,$ff00
 dc.w bplcon0,$201
 
 incbin "faces2cols"
 dc.w bpl1pth
f1h
 dc.w 0

 dc.w bpl1ptl
f1l
 dc.w 0

 dc.w bpl2pth
f2h
 dc.w 0

 dc.w bpl2ptl
f2l
 dc.w 0

 dc.w bpl3pth
f3h
 dc.w 0

 dc.w bpl3ptl
f3l
 dc.w 0

 dc.w bpl4pth
f4h
 dc.w 0
 dc.w bpl4ptl
f4l
 dc.w 0

 dc.w bpl5pth
f5h
 dc.w 0
 dc.w bpl5ptl
f5l
 dc.w 0
 
 dc.w $0c01,$ff00
 dc.w bplcon0,$5201
  
 dc.w $ffff,$fffe

 cnop 0,64
FacePlace:
 ds.l 6*32*5


********************************************
* Stuff you don't have to worry about yet. *
********************************************

closeeverything:

 move.l #$dff000,a6
 move.l old,$dff080     ; Restore old copper list.
 move.l old,d0
 move.w d0,ocl
 swap d0
 move.w d0,och
 move.w #$8020,dmacon(a6)
 move.w #$f,dmacon(a6)
 move.l saveit,$6c.w
 move.l OLDKINT,$68.w
 move.w saveinters,d0
 or.w #$c000,d0
 move.w d0,intena(a6)
 clr.w $dff0a8
 clr.w $dff0b8
 clr.w $dff0c8
 clr.w $dff0d8

; move.w #3,d0
;nonewvbl
; btst #5,intreqrl(a6)
; beq.s nonewvbl
; move.w #$20,intreq(a6)
; dbra d0,nonewvbl

; move.l oldview,a1
; move.l a1,d0
; move.l gfxbase,a6
; jsr -$de(a6)
 
 move.l gfxbase,d0
 move.l d0,a1
 move.l 4.w,a6
 jsr CloseLib(a6)
 
 cmp.b #'t',option+1
 beq.s leaveold
 move.w #$f8e,$dff1dc
leaveold:

 move.l 4.w,a6
 move.l #doslibname,a1
 moveq #0,d0
 jsr -552(a6)
 move.l d0,doslib

 move.l d0,a6
 move.l #RECname,d1
 move.l #1006,d2
 jsr -30(a6)
 move.l d0,REChandle

 move.l doslib,a6
 move.l d0,d1
 move.l #RECORDBUFFER,d2
 move.l #50000,d3
 jsr -48(a6)

 move.l doslib,a6
 move.l REChandle,d1
 jsr -36(a6)

 move.l doslib,d0
 move.l d0,a1
 move.l 4.w,a6
 jsr CloseLib(a6)

 
 rte

RECname: dc.b 'ab3:includes/RECORDING',0
 even
REChandle: dc.l 0
gfxbase: dc.l 0
oldview: dc.l 0

stuff:

	Lea	gfxname(pc),a1	
	Moveq.l	#0,d0
	Move.l	$4.w,a6	
	Jsr	-$228(a6)
	Move.l 	d0,gfxbase
	Move.l	d0,a6				Use As Base Reg
	Move.l	34(a6),oldview
	move.l 38(a6),old

 jmp endstuff

gfxname dc.b "graphics.library",0

 even


 cnop 0,64

Panel:
 incbin "PanelRaw"

Blurb: incbin "blurbpic"

TimerScr: ds.b 40*64

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
 
NumTimes: dc.l 0
TimeCount: dc.l 0
oldtime: dc.l 0
counting: dc.b 0
oktodisplay: dc.b 0

INITTIMER:
 move.l #0,TimeCount
 move.l #0,NumTimes
 rts
 
STARTCOUNT:
 move.l d0,-(a7)
 move.l $dff004,d0
 and.l #$1ffff,d0
 move.l d0,oldtime
 st counting
 move.l (a7)+,d0
 rts

STOPCOUNT:
 move.l d0,-(a7)
 move.l $dff004,d0
 and.l #$1ffff,d0
 
 sub.l oldtime,d0
 cmp.l #-256,d0
 bge.s okcount
 add.l #313*256,d0
okcount:
 add.l d0,TimeCount
 addq.l #1,NumTimes
 clr.b counting
 move.l (a7)+,d0
 rts

STOPCOUNTNOADD:
 move.l d0,-(a7)
 move.l $dff004,d0
 and.l #$1ffff,d0
 
 sub.l oldtime,d0
 cmp.l #-256,d0
 bge.s okcount2
 add.l #313*256,d0
okcount2:
 add.l d0,TimeCount
 clr.b counting
 move.l (a7)+,d0
 rts

maxbot: dc.w 0
tstneg: dc.l 0

STOPTIMER:
 st oktodisplay
 rts
 
digits: incbin "numbers.inc"

 
 Section Sounds,CODE_C

Scream: incbin "ab3:sounds/Scream"
 ds.w 100
EndScream:
LowScream: incbin "ab3:sounds/LowScream"
 ds.w 100
EndLowScream:
BaddieGun: incbin "ab3:sounds/BaddieGun"
EndBaddieGun:
bass: incbin "ab3:sounds/backbass+drum"
bassend:
Shoot: incbin "ab3:sounds/fire!"
EndShoot:
Munch: incbin "ab3:sounds/munch"
EndMunch:
PooGun: incbin "ab3:sounds/shoot.dm"
EndPooGun:
Collect: incbin "ab3:sounds/collect"
EndCollect:
DoorNoise: incbin "ab3:sounds/newdoor"
EndDoorNoise:
Stomp: incbin "ab3:sounds/footstep3"
EndStomp:
SwitchNoise: incbin "ab3:sounds/switch"
EndSwitch:
