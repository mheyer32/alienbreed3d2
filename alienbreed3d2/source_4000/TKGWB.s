  

*************************************************
* Stuff to do to get a C2P version:
* Change copperlist
* Change wall drawing
* change floor drawing
* change object drawing
* change polygon drawing (ugh)
* Write a palette generator program in AMOS
* to provide a good 256 colour palette and
* convert all graphics files specified
* (possibly included in the game linker
* program).
* Possibly change the wall/floor/object
* palettes to look nicer with more shades.
* RE-implement stippling (if not present)
* as it will look gorgeous now.
*************************************************

;MIDDLEX set 96
;RIGHTX set 191
;BOTTOMY set 160 

;MIDDLEX set 96
;RIGHTX set 191
;BOTTOMY set 160

_break	macro
;	bkpt	\1
	endm


FILTER	macro
;	move.l	d0,-(sp)
;	move.l	#65000,d0
;.loop\@
;	bchg	#1,$bfe001
;	dbra	d0,.loop\@
;	move.l	(sp)+,d0
	endm

BLACK	macro
	move.w	#0,$dff180
	endm

RED	macro
	move.w	#$f00,$dff180
	endm

FLASHER macro
;	movem.l	d1,-(sp)
;	move.w	#-1,d1
;
;loop3\@
;;	move.w	#\1,$dff180
;	nop
;	nop
;	move.w	#\2,$dff180
;	nop
;	nop
;	dbra	d1,loop3\@

;	movem.l	(sp)+,d1

	endm

GREEN	macro
	move.w	#$0f0,$dff180
	endm

BLUE	macro
	move.w	#$f,$dff180
	endm

DataCacheOff macro
	movem.l	a0-a6/d0-d7,-(sp)
	move.l	4.w,a6
	moveq	#0,d0
	move.l	#%0000000100000000,d1
	jsr	_LVOCacheControl(a6)
	movem.l	(sp)+,a0-a6/d0-d7
	endm

DataCacheOn macro
	movem.l	a0-a6/d0-d7,-(sp)
	move.l	4.w,a6
	moveq	#-1,d0
	move.l	#%0000000100000000,d1
	jsr	_LVOCacheControl(a6)
	movem.l	(sp)+,a0-a6/d0-d7
	endm

	opt	P=68020

	include utils:sysinc/hardware/intbits.i
	include	workbench:utilities/devpac/system			use pre-assembled header
	include	exec/exec_lib.i
	include	intuition/intuition.i
	include	intuition/intuition_lib.i
	include	graphics/graphics_lib.i
	include	graphics/text.i


CD32VER equ 0

maxscrdiv EQU 8
max3ddiv EQU 5
playerheight EQU 12*1024
playercrouched EQU 8*1024
scrheight EQU 80

; k/j/m

; 4/8
; s/x
; b/n

midoffset EQU 104*4*40


 SECTION Scrn,CODE
OpenLib       equ -552
CloseLib      equ -414

INTREQ		equ	$09C
INTENA		equ	$09A
INTENAR	equ	$01C
DMACON		equ	$096

SERPER		equ	$032
SERDATR	equ	$018
SERDAT		equ	$030
vhposr		equ $006	
vhposrl	equ $007 

bltcon0	equ $40 
bltcon1	equ $42
bltcpt		equ $48
bltbpt		equ $4c
bltapt		equ $50
spr0ctl	equ $142
spr1ctl	equ $14a
spr2ctl	equ $152
spr3ctl	equ $15a
spr4ctl	equ $162
spr5ctl	equ $16a
spr6ctl	equ $172
spr7ctl	equ $17a
spr0pos	equ $140
spr1pos	equ $148
spr2pos	equ $150
spr3pos	equ $158
spr4pos	equ $160
spr5pos	equ $168
spr6pos	equ $170
spr7pos	equ $178
bltdpt     	equ $54
bltafwm	equ $44
bltalwm	equ $46
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
col11           equ $196
col12           equ $198
col13           equ $19a
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
bpl8pth		equ $fc
bpl8ptl		equ $fe
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
adkcon	    equ   $09E


; move.l #length,d0
; moveq.l #2,d1	; chipmem
; move.l 4.w,a6
; jsr allocmem(a6) = -198

; tst.l d0
; beq.s ohbugger
; move.l d0,memaddr


; move.l 4.w,a6
; move.l memaddr,a1
; move.l #size,d0
; jsr freemem(a6) =-210


** This waits for the blitter to finish before allowing program
** execution to continue.

 
 include "ab3:source_4000/protsetupdecode"

SAVEREGS MACRO
 movem.l d0-d7/a0-a6,-(a7)
 ENDM

GETREGS MACRO
 movem.l (a7)+,d0-d7/a0-a6
 ENDM


WB MACRO
\@bf:
 btst #6,dmaconr(a6)
 bne.s \@bf
 ENDM

WBa MACRO
\@bf:
 move.w #\2,$dff180

 btst #6,$bfe001
 bne.s \@bf
\@bz:

 move.w #$f0f,$dff180

 btst #6,$bfe001
 beq.s \@bz

 ENDM

*Another version for when a6 <> dff000

WBSLOW MACRO
\@bf:
 btst #6,$dff000+dmaconr
 bne.s \@bf
 ENDM

WT MACRO
\@bf:
 btst #6,(a3)
 bne.s \@bd
 rts
\@bd: 
 btst #4,(a0)
 beq.s \@bf
 ENDM

WTNOT MACRO
\@bf:
 btst #6,(a3)
 bne.s \@bd
 rts
\@bd: 
 btst #4,(a0)
 bne.s \@bf
 ENDM
 
**

 include "ab3:source_4000/ProtectionProtection"
 include "macros.i"
 include "ab3:source_4000/defs.i"

 move.w (a0)+,mors

;	FLASHER $0f0,$fff

; PROTFCALC
; PROTGCALC
; PROTHCALC
; PROTICALC
; PROTKCALC
; PROTLCALC
; PROTMCALC

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

 move.l 4.w,a6
 lea VBLANKInt(pc),a1
 moveq #INTB_VERTB,d0
 jsr _LVOAddIntServer(a6)


 move.l #$dff000,a6    ; NB V. IMPORTANT: A6=CUSTOM BASE
 move.w intenar(a6),_storeint
 and.w #$c000,_storeint

 move.w #13,SERPER(a6)	;19200 baud, 8 bits, no parity


 st GOURSEL


	IFEQ CD32VER
; move.l 4.w,a6
; lea KEYInt(pc),a1
; moveq #INTB_PORTS,d0
; jsr _LVOAddIntServer(a6)
	ENDC

 IFNE CD32VER
 clr.b PLR1KEYS
 clr.b PLR1PATH
 clr.b PLR1MOUSE
 st PLR1JOY
 clr.b PLR2KEYS
 clr.b PLR2PATH
 clr.b PLR2MOUSE
 st PLR2JOY
 ELSE
 st PLR1KEYS
 clr.b PLR1PATH
 clr.b PLR1MOUSE
 clr.b PLR1JOY
 st PLR2KEYS
 clr.b PLR2PATH
 clr.b PLR2MOUSE
 clr.b PLR2JOY
 ENDC

 PRSDO

 move.l #2,d1	
 move.l #10240*2,d0
 move.l 4.w,a6
 jsr -198(a6)
 move.l d0,TEXTSCRN
 move.w d0,TSPTl
 swap d0
 move.w d0,TSPTh

 move.l #nullspr,d0
 move.w d0,txs0l
 move.w d0,txs1l
 move.w d0,txs2l
 move.w d0,txs3l
 move.w d0,txs4l
 move.w d0,txs5l
 move.w d0,txs6l
 move.w d0,txs7l
 swap d0
 move.w d0,txs0h
 move.w d0,txs1h
 move.w d0,txs2h
 move.w d0,txs3h
 move.w d0,txs4h
 move.w d0,txs5h
 move.w d0,txs6h
 move.w d0,txs7h 

 move.l #MEMF_FAST,d1	
 move.l #120000,d0
 move.l 4.w,a6
 jsr -198(a6)
 move.l d0,LEVELDATA

 move.l #MEMF_FAST,d1	
 move.l #2*320*256,d0
 move.l 4.w,a6
 jsr -198(a6)
 move.l d0,FASTBUFFER

 jsr START

 rts
 
FASTBUFFER: dc.l 0
_storeint
	dc.w 0

* Load level into buffers.
 clr.b doanything
 clr.b dosounds

; DRAW TEXT SCREEN

TWEENTEXT:

 move.l #LEVELTEXT,a0
 move.w PLOPT,d0
 muls #82*16,d0
 add.l d0,a0
 
 move.w #14,d7
 move.w #0,d0
DOWNTEXT:
 move.l TEXTSCRN,a1
 jsr DRAWLINEOFTEXT
 addq #1,d0
 add.w #82,a0
 dbra d7,DOWNTEXT
 rts

FONTADDRS:
 dc.l ENDFONT0,CHARWIDTHS0
 dc.l ENDFONT1,CHARWIDTHS1
 dc.l ENDFONT2,CHARWIDTHS2
 
ENDFONT0:
 incbin "endfont0"
CHARWIDTHS0:
 incbin "charwidths0"
ENDFONT1:
 incbin "endfont1"
CHARWIDTHS1:
 incbin "charwidths1"
ENDFONT2:
 incbin "endfont2"
CHARWIDTHS2:
 incbin "charwidths2"
 
 even
 
DRAWLINEOFTEXT:
 movem.l d0/a0/d7,-(a7)

 muls #80*16,d0
 add.l d0,a1	; screen pointer
 
 move.l #FONTADDRS,a3
 moveq #0,d0
 move.b (a0)+,d0
 move.l (a3,d0.w*8),a2
 move.l 4(a3,d0.w*8),a3
 
 moveq #0,d1	; width counter:
 move.w #79,d6
 tst.b (a0)+
 beq.s NOTCENTRED
 moveq #-1,d5
 move.l a0,a4
 moveq #0,d2
 moveq #0,d3
 move.w #79,d0	; number of chars
.addup:
 addq #1,d5
 move.b (a4)+,d2
 move.b -32(a3,d2.w),d4
 add.w d4,d3
 cmp.b #32,d2
 beq.s .DONTPUTIN
 move.w d5,d6
 move.w d3,d1
.DONTPUTIN:
 dbra d0,.addup
 asr.w #1,d1
 neg.w d1
 add.w #320,d1	; horiz pos of start x

NOTCENTRED:
 move.w d6,d7
DOACHAR:
 moveq #0,d2
 move.b (a0)+,d2
 sub.w #32,d2
 moveq #0,d6
 move.b (a3,d2.w),d6
 asl.w #5,d2
 lea (a2,d2.w),a4	; char font
val SET 0
 REPT 16
 move.w (a4)+,d0
 bfins d0,val(a1){d1:d6}
val SET val+80
 ENDR
 add.w d6,d1
 dbra d7,DOACHAR
 movem.l (a7)+,d0/a0/d7
 rts 
 

CLRTWEENSCRN:
 move.l TEXTSCRN,a0
 move.w #(10240/16)-1,d0
 move.l #$0,d1
.lll
 move.l d1,(a0)+
 move.l d1,(a0)+
 move.l d1,(a0)+
 move.l d1,(a0)+
 move.l d1,(a0)+
 move.l d1,(a0)+
 move.l d1,(a0)+
 move.l d1,(a0)+
 dbra d0,.lll
 rts

PLAYTHEGAME:

 move.w #0,TXTCOLL

 bsr CLRTWEENSCRN

 cmp.b #'n',mors
 bne.s .notext
 bsr TWEENTEXT
.notext

;charlie 
; move.l #TEXTCOP,$dff080

 move.w #$10,d0
 move.w #7,d1
 
;.fdup
; move.w d0,TXTCOLL
; add.w #$121,d0
;.wtframe:
; btst #5,$dff000+intreqrl
; beq.s .wtframe
; move.w #$0020,$dff000+intreq
; dbra d1,.fdup
;
; jsr INITCOPPERSCRN
 
; Get level memory.
 
 move.l #1,d1
 move.l #50000,d0
 move.l 4.w,a6
 jsr -198(a6)
 move.l d0,LEVELGRAPHICS

 move.l #1,d1
 move.l #40000,d0
 move.l 4.w,a6
 jsr -198(a6)
 move.l d0,LEVELCLIPS

 move.l #$dff000,a6
 jsr SETPLAYERS

; move.l #LEVELDATAD,LEVELDATA
; move.l #LEVELGRAPHICSD,LEVELGRAPHICS
; move.l #LEVELCLIPSD,LEVELCLIPS

; bra noload

*********************************

 move.l doslib,a6
 move.l #LLname,d1
 move.l #1005,d2
 jsr -30(a6)
 move.l d0,LLhandle

 move.l doslib,a6
 move.l d0,d1
 move.l #LINKS,d2
 move.l #10000,d3
 jsr -42(a6)

 move.l doslib,a6
 move.l LLhandle,d1
 jsr -36(a6)
 
 ********************************

 move.l doslib,a6
 move.l #LLFname,d1
 move.l #1005,d2
 jsr -30(a6)
 move.l d0,LLhandle

 move.l doslib,a6
 move.l d0,d1
 move.l #FLYLINKS,d2
 move.l #10000,d3
 jsr -42(a6)

 move.l doslib,a6
 move.l LLhandle,d1
 jsr -36(a6)
 
 ********************************


 move.l doslib,a6
 move.l #LDname,d1
 move.l #1005,d2
 jsr -30(a6)
 move.l d0,LDhandle

 move.l doslib,a6
 move.l d0,d1
 move.l LEVELCLIPS,d2
 move.l #40000,d3
 jsr -42(a6)

 move.l doslib,a6
 move.l LDhandle,d1
 jsr -36(a6)

*************************************
	move.l	LEVELCLIPS,d0
	moveq	#0,d1
	move.l LEVELDATA,a0
	lea	WorkSpace,a1
	lea	$0,a2
	jsr	unLHA
*************************************

********

 move.l doslib,a6
 move.l #LGname,d1
 move.l #1005,d2
 jsr -30(a6)
 move.l d0,LGhandle

 move.l doslib,a6
 move.l d0,d1
 move.l LEVELCLIPS,d2
 move.l #40000,d3
 jsr -42(a6)

 move.l doslib,a6
 move.l LGhandle,d1
 jsr -36(a6)

*************************************
	move.l	LEVELCLIPS,d0
	moveq	#0,d1
	move.l LEVELGRAPHICS,a0
	lea	WorkSpace,a1
	lea	$0,a2
	jsr	unLHA
*************************************

********

 move.l doslib,a6
 move.l #LCname,d1
 move.l #1005,d2
 jsr -30(a6)
 move.l d0,LChandle

 move.l doslib,a6
 move.l d0,d1
 move.l #WorkSpace+16384,d2
 move.l #16000,d3
 jsr -42(a6)

 move.l doslib,a6
 move.l LChandle,d1
 jsr -36(a6)

*************************************
	move.l	#WorkSpace+16384,d0
	moveq	#0,d1
	move.l LEVELCLIPS,a0
	lea	WorkSpace,a1
	lea	$0,a2
	jsr	unLHA
*************************************


*******

noload:

********

; move.l doslib,a6
; move.l #Prefsname,d1
; move.l #1005,d2
; jsr -30(a6)
; move.l d0,Prefshandle

; move.l doslib,a6
; move.l d0,d1
; move.l #Prefsfile,d2
; move.l #50,d3
; jsr -42(a6)

; move.l doslib,a6
; move.l Prefshandle,d1
; jsr -36(a6)

*******

 IFNE CD32VER
 move.l doslib,a6
 move.l #115,d1
 jsr -198(a6)
 ENDC


; move.l doslib,d0
; move.l d0,a1
; move.l 4.w,a6
; jsr CloseLib(a6)

 move.l #$dff000,a6

charlie:
; jmp  ENDGAMESCROLL

	move.w #$87c0,dmacon(a6)

	move.w	#%1000000000100000,dmacon(a6)

; move.w intenar(a6),saveinters
	
;	move.w #%00101111,intena(a6)

	move.w #255,adkcon(a6)


*** Put myself in supervisor mode

 bra blag
; move.l $6c,d0
; move.l #blag,$6c
; move.w #$8010,intreq(a6)

 rts
 
saveit: ds.l 10
doslibname: dc.b 'dos.library',0
 even
doslib: dc.l 0

mors: dc.w 0

LDname: dc.b 'ab3:levels/level_'
LEVA:
 dc.b 'a/twolev.bin',0
 even
LDhandle: dc.l 0
LGname: dc.b 'ab3:levels/level_'
LEVB:
 dc.b 'a/twolev.graph.bin',0
 even
LGhandle: dc.l 0
LCname: dc.b 'ab3:levels/level_'
LEVC:
 dc.b 'a/twolev.clips',0
 even
LChandle: dc.l 0
LLname: dc.b 'ab3:levels/level_'
LEVD:
 dc.b 'a/twolev.map',0
 even
LLFname: dc.b 'ab3:levels/level_'
LEVE:
 dc.b 'a/twolev.flymap',0
 even
LLhandle: dc.l 0

	cnop	0,4

Prefsname: dc.b 'ram:prefs',0
 even
Prefshandle: dc.l 0

Prefsfile:
 dc.b 'k4nx'
 ds.b 50
 
 even

 cnop 0,4

VBLANKInt
 dc.l 0,0
 dc.b NT_INTERRUPT,9
 dc.l Prefsname
 dc.l 0
 dc.l Chan0inter


KEYInt
 dc.l 0,0
 dc.b NT_INTERRUPT,127
 dc.l Prefsname
 dc.l 0
 dc.l key_interrupt


blag:

 move.l 4.w,a6
 move.l #0,a1
 jsr _LVOFindTask(a6)
 move.l d0,a1
 move.l #6,d0
 
 move.l 4.w,a6
 jsr _LVOSetTaskPri(a6)

; move.w #$10,intreq(a6)
; move.l d0,$6c
; move.w #$7fff,intena(a6)

; move.w #$20,$dff1dc

; move.l 4.w,a6
; lea VBLANKInt(pc),a1
; moveq #INTB_COPER,d0
; jsr _LVOAddIntServer(a6)



****************************
* Initialize level
****************************
* Poke all clip offsets into
* correct bit of level data.
****************************
 move.l LEVELGRAPHICS,a0
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

 move.l LEVELDATA,a4
 lea 160*10(a4),a1
 
 lea 54(a1),a2
 move.l a2,CPtPos
 move.w 12(a1),NumCPts
 move.w 14(a1),NumLevPts
 
 move.l 16+6(a1),a2
 add.l a4,a2
 move.l a2,Points
 move.w 8+6(a1),d0
 lea 4(a2,d0.w*4),a2
 move.l a2,PointBrights
 move.w 16(a1),d0
 addq #1,d0
 muls #80,d0
 add.l d0,a2
 move.l a2,ZoneBorderPts
 
 move.l 20+6(a1),a2
 add.l a4,a2
 move.l a2,FloorLines
 move.w -2(a2),ENDZONE
 move.l 24+6(a1),a2
 add.l a4,a2
 move.l a2,ObjectData
*****************************************
* Just for charles

; move.w #$6060,6(a2)
; move.l #$d0000,8(a2)
; sub.w #40,4(a2)
; move.w #45*256+45,14(a2)
****************************************
 move.l 28+6(a1),a2
 add.l a4,a2
 move.l a2,PlayerShotData
 move.l 32+6(a1),a2
 add.l a4,a2
 move.l a2,NastyShotData
 
 add.l #64*20,a2
 move.l a2,OtherNastyData
 
 move.l 36+6(a1),a2
 add.l a4,a2
 move.l a2,ObjectPoints  
 move.l 40+6(a1),a2
 add.l a4,a2
 move.l a2,PLR1_Obj
 move.l 44+6(a1),a2
 add.l a4,a2
 move.l a2,PLR2_Obj
 move.w 14+6(a1),NumObjectPoints

; bra noclips
  
 move.l LEVELCLIPS,a2
 moveq #0,d0
 move.w 10+6(a1),d7	;numzones
 move.w d7,NUMZONES
assignclips:
 move.l (a0)+,a3
 add.l a4,a3	; pointer to a zone
 adda.w #ToListOfGraph,a3 ; pointer to zonelist
dowholezone:
 tst.w (a3)
 blt.s nomorethiszone
 tst.w 2(a3)
 blt.s thisonenull

 move.l d0,d1
 asr.l #1,d1
 move.w d1,2(a3)

findnextclip:
 cmp.w #-2,(a2,d0.l)
 beq.s foundnextclip
 addq.l #2,d0
 bra.s findnextclip
foundnextclip
 addq.l #2,d0

thisonenull:
 addq #8,a3 
 bra.s dowholezone
nomorethiszone:
 dbra d7,assignclips
 
 lea (a2,d0.l),a2
 move.l a2,CONNECT_TABLE
 
noclips:

* Put in addresses of glowything


************************************
 
; cmp.b #'k',Prefsfile
; bne.s nkb
 
;nkb:
; cmp.b #'m',Prefsfile
; bne.s nmc
; clr.b PLR1KEYS
; clr.b PLR1PATH
; st PLR1MOUSE
; clr.b PLR1JOY
;nmc:
; cmp.b #'j',Prefsfile
; bne.s njc
; clr.b PLR1KEYS
; clr.b PLR1PATH
; clr.b PLR1MOUSE
; st PLR1JOY
;njc:
 
 clr.b PLR1_StoodInTop
 move.l #playerheight,PLR1s_height
 
 move.l #empty,pos1LEFT
 move.l #empty,pos2LEFT
 move.l #empty,pos1RIGHT
 move.l #empty,pos2RIGHT
 move.l #empty,pos0LEFT
 move.l #empty,pos3LEFT
 move.l #empty,pos0RIGHT
 move.l #empty,pos3RIGHT
 move.l #emptyend,Samp0endLEFT
 move.l #emptyend,Samp1endLEFT
 move.l #emptyend,Samp0endRIGHT
 move.l #emptyend,Samp1endRIGHT
 move.l #emptyend,Samp2endLEFT
 move.l #emptyend,Samp3endLEFT
 move.l #emptyend,Samp2endRIGHT
 move.l #emptyend,Samp3endRIGHT
 
 
 move.l #nullline,d0
 move.w d0,n1l
 swap d0
 move.w d0,n1h
 
 move.l Panel,d0
 move.w d0,p1l
 swap d0
 move.w d0,p1h
 swap d0
 add.l #40,d0
 move.w d0,p2l
 swap d0
 move.w d0,p2h
 swap d0
 add.l #40,d0
 move.w d0,p3l
 swap d0
 move.w d0,p3h
 swap d0
 add.l #40,d0
 move.w d0,p4l
 swap d0
 move.w d0,p4h
 swap d0
 add.l #40,d0
 move.w d0,p5l
 swap d0
 move.w d0,p5h
 swap d0
 add.l #40,d0
 move.w d0,p6l
 swap d0
 move.w d0,p6h
 swap d0
 add.l #40,d0
 move.w d0,p7l
 swap d0
 move.w d0,p7h
 swap d0
 add.l #40,d0
 move.w d0,p8l
 swap d0
 move.w d0,p8h
 
*******************************
* TIMER SCREEN SETUP
; move.l #TimerScr,d0
; move.w d0,p1l
; swap d0
; move.w d0,p1h
; move.w #$1201,Panelcon

 move.l #borders,d0
 move.w d0,s0l
 swap d0
 move.w d0,s0h
 move.l #borders+2592,d0
 move.w d0,s1l
 swap d0
 move.w d0,s1h
 move.l #borders+2592*2,d0
 move.w d0,s2l
 swap d0
 move.w d0,s2h
 move.l #borders+2592*3,d0
 move.w d0,s3l
 swap d0
 move.w d0,s3h
 
 move.l #nullspr,d0
 move.w d0,s0l
 move.w d0,s1l
 move.w d0,s2l
 move.w d0,s3l
 
 move.w d0,s4l
 move.w d0,s5l
 move.w d0,s6l
 move.w d0,s7l
 swap d0
 
 move.w d0,s0h
 move.w d0,s1h
 move.w d0,s2h
 move.w d0,s3h
 
 move.w d0,s4h
 move.w d0,s5h
 move.w d0,s6h
 move.w d0,s7h 
 
 
 move.w #52*256+64,borders
 move.w #212*256+0,borders+8
 move.w #52*256+64,borders+2592
 move.w #212*256+128,borders+8+2592
 move.w #52*256+192,borders+2592*2
 move.w #212*256+0,borders+8+2592*2
 move.w #52*256+192,borders+2592*3
 move.w #212*256+128,borders+8+2592*3
 
  
 
; move.l #bigfield,d0
; move.w d0,ocl
; swap d0
; move.w d0,och

 bset.b #1,$bfe001
 
; jmp stuff
;endstuff:

; move.w #$00ff,$dff09e

; move.l #Blurbfield,$dff080

 move.w #0,d0



****************************
 jsr INITPLAYER
; bsr initobjpos
****************************

 
 move.l #$dff000,a6
 
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
 
; bsr protinit
 
 
; move.w #$20,$1dc(a6)
 
 move.w #$0,$dff034
 move.w #0,Conditions
 
 cmp.b #'n',mors
 beq.s .nokeys
 move.w #%111111111111,Conditions
.nokeys:
 
 move.l #KeyMap,a5
 clr.b $45(a5)
 
 move.l #ingame,mt_data
 clr.b UseAllChannels

; cmp.b #'b',Prefsfile+3
; bne.s .noback
; jsr mt_init
;.noback:
;
; clr.b CHANNELDATA
; clr.b CHANNELDATA+8
; clr.b CHANNELDATA+16
; clr.b CHANNELDATA+24
;
; cmp.b #'b',Prefsfile+3
; bne.s noreserve
;
; st CHANNELDATA
; st CHANNELDATA+8
; st CHANNELDATA+16
; st CHANNELDATA+24
;noreserve: 
 
; st CHANNELDATA
; st CHANNELDATA+8
 
 move.l SampleList+6*8,pos0LEFT
 move.l SampleList+6*8+4,Samp0endLEFT
 move.l #playerheight,PLR1s_targheight
 move.l #playerheight,PLR1s_height
 move.l #playerheight,PLR2s_targheight
 move.l #playerheight,PLR2s_height

; cmp.b #'n',mors
; beq.s nohandshake
;
; move.b #%11011000,$bfd200
; move.b #%00010000,$bfd000
;waitloop:
; btst.b #4,$bfd000
; bne.s waitloop
; move.b #%11000000,$bfd200
 
;wtmouse:
; btst #6,$bfe001
; bne.s wtmouse
 
;nohandshake:
 
; jmp end
 
; move.l COPSCRN1,drawpt
; move.l COPSCRN2,olddrawpt

 jsr CLEARKEYBOARD
; jsr MAKEBACKROUT

 clr.b MASTERQUITTING
 
 cmp.b #'n',mors
 seq SLAVEQUITTING

 move.w #127,PLR2_energy
 move.w #200,PLAYERONEHEALTH
 
; move.l #ANOTHERSUP,$80
; trap #0
; rts
;
;ANOTHERSUP:

; move.l $4.w,a6
; jsr _LVOSuperState(a6)
; move.l d0,SSTACK

; CACHE_FREEZE_OFF d2

; charlie
; DATA_CACHE_ON d2

; DataCacheOn

; move.l $4.w,a6
; move.l SSTACK,d0
; jsr _LVOUserState(a6)

 move.l #0,hitcol
 
 cmp.b #'n',mors
 bne.s NOCLTXT
 
; move.b #0,lastpressed
;.wtpress
; btst #6,$bfe001
; beq.s CLOSETXT
; btst #7,$bfe001
; beq.s CLOSETXT
; tst.b lastpressed
; beq.s .wtpress

CLOSETXT:

 move.w #$8f8,d0
 move.w #7,d1
 
.fdup
 move.w d0,TXTCOLL
 sub.w #$121,d0
.wtframe:
; btst #5,$dff000+intreqrl
; beq.s .wtframe
; move.w #$0020,$dff000+intreq
 dbra d1,.fdup

 move.w #0,TXTCOLL
 
NOCLTXT:
 


	move.l	4.w,a6
	jsr	_LVOForbid(a6)
;	jsr	_LVODisable(a6)


;	move.w	#%0111111111111111,intena+$dff000
;	move.w	#%1000000011111111,intena+$dff000


;charlie 
; move.l #PALETTEBIT,$dff084
; move.l #bigfield,$dff080    ; Point the copper at our copperlist.


 clr.b PLR1_Ducked
 clr.b PLR2_Ducked
 clr.b p1_ducked
 clr.b p2_ducked

********************************************

;	jmp docredits

********************************************


 st doanything
 st dosounds

 jsr CLRNASTYMEM

 move.l #COMPACTMAP,a0
 move.l a0,LASTZONE
 move.w #255,d0
.clrmap
 move.l #0,(a0)+
 dbra d0,.clrmap

 move.l #COMPACTMAP,a0
 move.l #BIGMAP,a1

 bra NOALLWALLS

 move.l ZoneGraphAdds,a2
DOALLWALLS:
 move.l (a2),d0
 beq.s nomorezones
 move.l d0,a3

 addq #8,a2

 add.l LEVELGRAPHICS,a3
 addq #2,a3
 move.l a1,a4
 
; DOLOWERROOM

innerwalls:
 move.b (a3),d1
 move.b 1(a3),d0
 bne doneinner
 
 tst.b d1
 blt noid
 
 move.b d1,d3
 and.w #15,d1

 moveq #0,d0
 move.w d1,d2
 add.w d1,d1
 add.w d2,d1
 addq #1,d1
 bset d1,d0
 btst #4,d3
 beq.s .nodoor
 addq #1,d1
 bset d1,d0
.nodoor

 or.l d0,(a0)

 move.w 2(a3),(a4)
 move.w 4(a3),2(a4)

noid:
 
 add.w #30,a3
 addq #4,a4
 
 bra innerwalls

doneinner:

 add.w #40,a1
 addq #4,a0

 bra DOALLWALLS
nomorezones:

NOALLWALLS

 move.w #96,MIDDLEX
 move.w #192,RIGHTX
 move.w #160,BOTTOMY
 move.w #80,TOTHEMIDDLE
 clr.b FULLSCR
 st PLAYERONEGUNS+1
**************************************
 clr.b PLR1KEYS
 clr.b PLR1PATH
 st PLR1MOUSE
 clr.b PLR1JOY
**************************************
lop:

 move.b FULLSCRTEMP,d0
 move.b FULLSCR,d1
 eor.b d1,d0
 beq.s .notswapscr2
 
 move.b FULLSCRTEMP,FULLSCR
 beq.s .notswapscr3
 
 move.w #144,MIDDLEX
 move.w #288,RIGHTX
 move.w #232,BOTTOMY
 move.w #120,TOTHEMIDDLE
 move.l SCRNSHOWPT,a0
 jsr WIPEDISPLAY
 move.l SCRNDRAWPT,a0
 jsr WIPEDISPLAY
 
 bra.s .notswapscr2

.notswapscr3:
 move.w #96,MIDDLEX
 move.w #192,RIGHTX
 move.w #160,BOTTOMY
 move.w #80,TOTHEMIDDLE
 move.l SCRNSHOWPT,a0
 jsr WIPEDISPLAY
 move.l SCRNDRAWPT,a0
 jsr WIPEDISPLAY
.notswapscr2:


 btst #6,$bfe001
;charlie bne.b .nocop

;charlie move.l #bigfield,$dff080    ; Point the copper at our copperlist.

.nocop

 move.l #KeyMap,a5

 cmp.b #'n',mors
 bne .nopause
 tst.b $19(a5)
 bra .nopause
 beq.s .nopause
 clr.b doanything
 
.waitrel:

 tst.b PLR1JOY
 beq.s .NOJOY
 jsr _ReadJoy1
.NOJOY

 tst.b $19(a5)
 bne.s .waitrel
 
 bsr PAUSEOPTS
 
 
 st doanything
.nopause: 

 move.l hitcol,d0
 move.l d0,d1
 add.l #PALETTEBIT,d1
 tst.l d0
 beq.s nofadedownhc
 sub.l #2116,d0
 move.l d0,hitcol
nofadedownhc:

 move.l d1,a0
 move.l #PALETTESPACE,a1
 move.l #(2116/4)-2,d0
putinpal:
 move.l (a0)+,(a1)+
 dbra d0,putinpal

 st READCONTROLS
 move.l #$dff000,a6


 cmp.b #'n',mors
 beq .nopause

 move.b SLAVEPAUSE,d0
 or.b MASTERPAUSE,d0
 beq.s .nopause
 clr.b doanything
 
 move.l #KeyMap,a5
.waitrel:


 cmp.b #'s',mors
 beq.s .RE2
 tst.b PLR1JOY
 beq.s .NOJOY
 jsr _ReadJoy1
 bra .RE1
.RE2:
 tst.b PLR2JOY
 beq.s .NOJOY
 jsr _ReadJoy2
.RE1
.NOJOY:
 tst.b $19(a5)
 bne.s .waitrel
 
 bsr PAUSEOPTS
 
 cmp.b #'m',mors
 bne.s .slavelast
 Jsr SENDFIRST
 bra .masfirst
.slavelast
 Jsr RECFIRST
.masfirst:
 clr.b SLAVEPAUSE
 clr.b MASTERPAUSE
 st doanything

.nopause: 

 movem.l d0-d7/a0-a6,-(a7)
 move.w #256,COPIEDPAL
 move.w #0,COPIEDPAL+2
LOOKFORME:
 move.l MyScreen,a0
 lea sc_ViewPort(a0),a0
 move.l #COPIEDPAL,a1
 move.l _GfxBase,a6
 jsr -$372(a6)
 movem.l (a7)+,d0-d7/a0-a6

 move.l BMPtr,d0
 move.l BMPtr2,BMPtr
 move.l d0,BMPtr2
 
 move.l BMPtr2,a1
 
 move.l MyScreen,a0
 
 
 lea sc_RastPort(a0),a2
 move.l a1,rp_BitMap(a2)
 move.l rp_BitMap(a2),a2
 lea sc_ViewPort(a0),a0
 move.l vp_RasInfo(a0),a0
 move.l a1,ri_BitMap(a0)
 
 move.l MyScreen,a0
 lea sc_BitMap(a0),a0
 addq #8,a1
 move.l (a1)+,(a0)+
 move.l (a1)+,(a0)+
 move.l (a1)+,(a0)+
 move.l (a1)+,(a0)+
 move.l (a1)+,(a0)+
 move.l (a1)+,(a0)+
 move.l (a1)+,(a0)+
 move.l (a1)+,(a0)+
 
 move.l MyScreen,a0
 move.l _IntuitionBase,a6
 jsr _LVOMakeScreen(a6)

 move.l _IntuitionBase,a6
 jsr _LVORethinkDisplay(a6)

; move.l drawpt,d0
; move.l olddrawpt,drawpt
; move.l d0,olddrawpt
 
 move.l SCRNDRAWPT,d0
 move.l SCRNSHOWPT,SCRNDRAWPT
 move.l d0,SCRNSHOWPT
 
; move.l d0,$dff084	
 move.l drawpt,a3
; move.l COPSCRNBUFF,a3
 adda.w #10,a3
 move.l a3,frompt
 add.l #104*4*40,a3
 move.l a3,midpt

 cmp.b #'s',mors
 beq.s nowaitslave

waitfortop:

; btst.b #0,intreqrl(a6)
; beq.b waitfortop

; move.w #$1,intreq(a6)
 move.l #PLR1_GunData,GunData
 move.b PLR1_GunSelected,GunSelected
 bra waitmaster
 
nowaitslave:
 move.l #PLR2_GunData,GunData
 move.b PLR2_GunSelected,GunSelected
waitmaster:
 
 move.l #SMIDDLEY,a0
 movem.l (a0)+,d0/d1
 move.l d0,MIDDLEY
 move.l d1,MIDDLEY+4

 move.l waterpt,a0
 move.l (a0)+,watertouse
 cmp.l #endwaterlist,a0
 blt.s okwat
 move.l #waterlist,a0
okwat:
 move.l a0,waterpt

 add.w #640,wtan
 and.w #8191,wtan
 add.l #1,wateroff
 and.l #$3fff3fff,wateroff

 moveq #0,d0
 move.b GunSelected,d0
 move.l LINKFILE,a6
 add.l #GunBulletTypes,a6
 move.w (a6,d0.w*8),d0
 
 move.l #PLAYERONEAMMO,a6
 move.w (a6,d0.w*2),d0
 move.w d0,Ammo
 
 move.l PLR1_xoff,OLDX1
 move.l PLR1_zoff,OLDZ1
 move.l PLR2_xoff,OLDX2
 move.l PLR2_zoff,OLDZ2

 move.l #$dff000,a6

 cmp.b #'s',mors
 beq ASlaveShouldWaitOnHisMaster

 cmp.b #'n',mors
 bne NotOnePlayer
 
 move.w PLAYERONEHEALTH,Energy
 move.w FramesToDraw,TempFrames
 cmp.w #15,TempFrames
 blt.s .okframe
 move.w #15,TempFrames
.okframe:
 move.w #0,FramesToDraw

*********************************************
*********** TAKE THIS OUT *******************
*********************************************

 move.l CHEATPTR,a4
 add.l #200000,a4
 moveq #0,d0
 move.b (a4),d0

 move.l #KeyMap,a5
 tst.b (a5,d0.w)
 beq.s .nocheat
 
 addq #1,a4
 cmp.l #ENDCHEAT,a4
 blt.s .nocheat
 cmp.w #0,CHEATNUM
 beq.s .nocheat
 sub.w #1,CHEATNUM
 move.l #CHEATFRAME,a4
 move.w #127,PLR1_energy
 jsr EnergyBar
.nocheat

 sub.l #200000,a4
 move.l a4,CHEATPTR

**********************************************
**********************************************
**********************************************

 move.l PLR1s_xoff,p1_xoff
 move.l PLR1s_zoff,p1_zoff
 move.l PLR1s_yoff,p1_yoff
 move.l PLR1s_height,p1_height
 move.w PLR1s_angpos,p1_angpos
 move.w PLR1_bobble,p1_bobble
 move.b PLR1_clicked,p1_clicked
 move.b PLR1_fire,p1_fire
 clr.b PLR1_clicked
 move.b PLR1_SPCTAP,p1_spctap
 clr.b PLR1_SPCTAP
 move.b PLR1_Ducked,p1_ducked
 move.b PLR1_GunSelected,p1_gunselected

 bsr PLR1_Control

 move.l PLR1_Roompt,a0
 move.l ToZoneRoof(a0),SplitHeight
 move.w p1_xoff,THISPLRxoff
 move.w p1_zoff,THISPLRzoff
 
 
 move.l #$60000,p2_yoff
 move.l PLR2_Obj,a0
 move.w #-1,GraphicRoom(a0)
 move.w #-1,12(a0)
 move.b #0,17(a0)
 move.l #BollocksRoom,PLR2_Roompt
 
 bra donetalking
 
NotOnePlayer:
 move.l #KeyMap,a5
 tst.b $19(a5)
 sne MASTERPAUSE

*********************************
 move.w PLAYERONEHEALTH,Energy
; change this back
*********************************

 jsr SENDFIRST

 move.w FramesToDraw,TempFrames
 cmp.w #15,TempFrames
 blt.s .okframe
 move.w #15,TempFrames
.okframe:
 move.w #0,FramesToDraw
 
 move.l PLR1s_xoff,p1_xoff
 move.l PLR1s_zoff,p1_zoff
 move.l PLR1s_yoff,p1_yoff
 move.l PLR1s_height,p1_height
 move.w PLR1s_angpos,p1_angpos
 move.w PLR1_bobble,p1_bobble
 move.b PLR1_clicked,p1_clicked
 clr.b PLR1_clicked
 move.b PLR1_fire,p1_fire
 move.b PLR1_SPCTAP,p1_spctap
 clr.b PLR1_SPCTAP
 move.b PLR1_Ducked,p1_ducked
 move.b PLR1_GunSelected,p1_gunselected
 
 move.l p1_xoff,d0
 jsr SENDFIRST
 move.l d0,p2_xoff
 
 move.l p1_zoff,d0
 jsr SENDFIRST
 move.l d0,p2_zoff 
 
 move.l p1_yoff,d0
 jsr SENDFIRST
 move.l d0,p2_yoff
  
 move.l p1_height,d0
 jsr SENDFIRST
 move.l d0,p2_height
 
 move.w p1_angpos,d0
 swap d0
 move.w p1_bobble,d0
 jsr SENDFIRST
 move.w d0,p2_bobble
 swap d0
 move.w d0,p2_angpos
 
 
 move.w TempFrames,d0
 swap d0
 move.b p1_spctap,d0
 lsl.w #8,d0
 move.b p1_clicked,d0
 jsr SENDFIRST
 move.b d0,p2_clicked
 lsr.w #8,d0
 move.b d0,p2_spctap
 
 
 move.w Rand1,d0
 swap d0
 move.b p1_ducked,d0
 lsl.w #8,d0
 move.b p1_gunselected,d0
 jsr SENDFIRST
 move.b d0,p2_gunselected
 lsr.w #8,d0
 move.b d0,p2_ducked
 
 move.b p1_fire,d0
 lsl.w #8,d0
 move.b MASTERQUITTING,d0
 or.b d0,SLAVEQUITTING
 swap d0
 move.b MASTERPAUSE,d0
 or.b d0,SLAVEPAUSE
 jsr SENDFIRST
 or.b d0,MASTERPAUSE
 or.b d0,SLAVEPAUSE
 swap d0
 or.b d0,SLAVEQUITTING
 or.b d0,MASTERQUITTING
 lsr.w #8,d0
 move.b d0,p2_fire
 
 bsr PLR1_Control
 bsr PLR2_Control
 move.l PLR1_Roompt,a0
 move.l ToZoneRoof(a0),SplitHeight
 move.w p1_xoff,THISPLRxoff
 move.w p1_zoff,THISPLRzoff
 
 bra donetalking

ASlaveShouldWaitOnHisMaster:

 move.l #KeyMap,a5
 tst.b $19(a5)
 sne SLAVEPAUSE


 move.w PLR2_energy,Energy

 jsr RECFIRST

 move.l PLR2s_xoff,p2_xoff
 move.l PLR2s_zoff,p2_zoff
 move.l PLR2s_yoff,p2_yoff
 move.l PLR2s_height,p2_height
 move.w PLR2s_angpos,p2_angpos
 move.w PLR2_bobble,p2_bobble
 move.b PLR2_clicked,p2_clicked
 clr.b PLR2_clicked
 move.b PLR2_fire,p2_fire
 move.b PLR2_SPCTAP,p2_spctap
 clr.b PLR2_SPCTAP
 move.b PLR2_Ducked,p2_ducked
 move.b PLR2_GunSelected,p2_gunselected

 move.l p2_xoff,d0
 jsr RECFIRST
 move.l d0,p1_xoff
 
 move.l p2_zoff,d0
 jsr RECFIRST
 move.l d0,p1_zoff
 
 move.l p2_yoff,d0
 jsr RECFIRST
 move.l d0,p1_yoff
 
 move.l p2_height,d0
 jsr RECFIRST
 move.l d0,p1_height
 
 move.w p2_angpos,d0
 swap d0
 move.w p2_bobble,d0
 jsr RECFIRST
 move.w d0,p1_bobble
 swap d0
 move.w d0,p1_angpos
 
 
 move.b p2_spctap,d0
 lsl.w #8,d0
 move.b p2_clicked,d0
 jsr RECFIRST
 move.b d0,p1_clicked
 lsr.w #8,d0
 move.b d0,p1_spctap
 swap d0
 move.w d0,TempFrames
 
 
 move.b p2_ducked,d0
 lsl.w #8,d0
 move.b p2_gunselected,d0
 jsr RECFIRST
 move.b d0,p1_gunselected
 lsr.w #8,d0
 move.b d0,p1_ducked
 swap d0
 move.w d0,Rand1
 
 move.b p2_fire,d0
 lsl.w #8,d0
 move.b SLAVEQUITTING,d0
 or.b d0,MASTERQUITTING
 swap d0
 move.b SLAVEPAUSE,d0
 or.b d0,MASTERPAUSE
 jsr RECFIRST
 or.b d0,MASTERPAUSE
 or.b d0,SLAVEPAUSE
 swap d0
 or.b d0,SLAVEQUITTING
 or.b d0,MASTERQUITTING
 lsr.w #8,d0
 move.b d0,p1_fire
 

 bsr PLR1_Control
 bsr PLR2_Control
 move.w p2_xoff,THISPLRxoff
 move.w p2_zoff,THISPLRzoff
 move.l PLR2_Roompt,a0
 move.l ToZoneRoof(a0),SplitHeight

donetalking:



 move.l #ZoneBrightTable,a1
 move.l ZoneAdds,a2
 move.l PLR2_ListOfGraphRooms,a0
; move.l PLR2_PointsToRotatePtr,a5
 move.l a0,a5
 cmp.b #'s',mors
 beq.s doallz
 move.l PLR1_ListOfGraphRooms,a0
; move.l PLR1_PointsToRotatePtr,a5
 move.l a0,a5 
doallz
 move.w (a0),d0
 blt.s doneallz
 add.w #8,a0
 
 move.l (a2,d0.w*4),a3
 add.l LEVELDATA,a3
 move.w ToZoneBrightness(a3),d2

 blt.s justbright
 move.w d2,d3
 lsr.w #8,d3
 tst.b d3
 beq.s justbright

 move.l #BrightAnimTable,a4
 move.w -2(a4,d3.w*2),d2
 
justbright:
 muls #32,d2
 divs #20,d2
 move.w d2,(a1,d0.w*4)

 move.w ToUpperBrightness(a3),d2

 blt.s justbright2
 move.w d2,d3
 lsr.w #8,d3
 tst.b d3
 beq.s justbright2

 move.l #BrightAnimTable,a4
 move.w -2(a4,d3.w*2),d2
 
justbright2:

 muls #32,d2
 divs #20,d2
 move.w d2,2(a1,d0.w*4)

 bra doallz

doneallz:
 
 move.l PointBrights,a2
 move.l #CurrentPointBrights,a3
justtheone:
 move.w (a5),d0
 blt whythehell
 addq #8,a5

 muls #40,d0
 
 move.w #39,d7
 
allinzone:
 move.w (a2,d0.w*2),d2
 
 tst.b d2
 blt.s .justbright
 move.w d2,d3
 lsr.w #8,d3
 tst.b d3
 beq.s .justbright

 move.w d3,d4
 and.w #$f,d3
 lsr.w #4,d4
 add.w #1,d4
 move.l #BrightAnimTable,a0
 move.w -2(a0,d3.w*2),d3
 ext.w d2
 sub.w d2,d3
 muls d4,d3
 asr.w #4,d3
 add.w d3,d2

.justbright:
 ext.w d2

 muls #31,d2
 divs #20,d2
 bge.s .itspos
 sub.w #600,d2
.itspos:
 add.w #300,d2

 move.w d2,(a3,d0.w*2)
 addq #1,d0
 dbra d7,allinzone

 bra justtheone
 
whythehell:

 move.l PLR1_Roompt,a0
 move.l #CurrentPointBrights,a1
 move.l ZoneBorderPts,a2
 move.w (a0),d0
 muls #10,d0
 lea (a2,d0.w*2),a2
 lea (a1,d0.w*8),a1
 
 moveq #9,d7
 moveq #0,d0
 moveq #0,d1
findaverage:
 tst.w (a2)+
 blt.s .foundaverage
 addq #1,d0
 move.w (a1)+,d2
 bge.s .okpos
 neg.w d2
.okpos:
 add.w d2,d1

 dbra d7,findaverage

.foundaverage:

 ext.l d1
 divs d0,d1
 sub.w #300,d1
 move.w d1,PLR1_RoomBright

 cmp.b #'n',mors
 beq nosee

 move.l PLR1_Roompt,FromRoom
 move.l PLR2_Roompt,ToRoom
 move.w p1_xoff,Viewerx
 move.w p1_zoff,Viewerz
 move.l p1_yoff,d0
 asr.l #7,d0
 move.w d0,Viewery
 move.w p2_xoff,Targetx
 move.w p2_zoff,Targetz
 move.l p2_yoff,d0
 asr.l #7,d0
 move.w d0,Targety
 move.b PLR1_StoodInTop,ViewerTop
 move.b PLR2_StoodInTop,TargetTop
 jsr CanItBeSeen
 
 move.l PLR1_Obj,a0
 move.b CanSee,d0
 and.b #2,d0
 move.b d0,17(a0)
 move.l PLR2_Obj,a0
 move.b CanSee,d0
 and.b #1,d0
 move.b d0,17(a0)

nosee:

 move.l PLR1_Obj,a0
 move.b #5,16(a0)
 move.l PLR2_Obj,a0
 move.b #11,16(a0)

 move.w TempFrames,d0
 add.w d0,p1_holddown
 cmp.w #30,p1_holddown
 blt.s oklength
 move.w #30,p1_holddown
oklength:

 tst.b p1_fire
 bne.s okstillheld
 sub.w d0,p1_holddown
 bge.s okstillheld
 move.w #0,p1_holddown
 
okstillheld:

 move.w TempFrames,d0
 add.w d0,p2_holddown
 
 cmp.w #30,p2_holddown
 blt.s oklength2
 move.w #30,p2_holddown
oklength2:
 
 
 tst.b p2_fire
 bne.s okstillheld2
 sub.w d0,p2_holddown
 bge.s okstillheld2
 move.w #0,p2_holddown
okstillheld2:

***** CHECKING LIGHT *********

; move.w #-20,d0
; move.w PLR1_xoff,d1
; move.w PLR1_zoff,d2
; move.l PLR1_Roompt,a0
; move.w (a0),d3
; move.w PLR1_angpos,d4
;
; jsr BRIGHTENPOINTSANGLE

******************************

; move.l #PLR1_GunData,a1
; move.w p1_holddown,d0
; move.w #50,10+32*3(a1)
; move.l #PLR2_GunData,a1
; move.w p2_holddown,d0
; move.w #50,10+32*3(a1)
 
******************************************
******************************************
 
 move.w TempFrames,d1
 bgt.s noze
 moveq #1,d1
noze:
 
 move.w PLR1_xoff,d0
 sub.w OLDX1,d0
 asl.w #4,d0
 ext.l d0
 divs d1,d0
 move.w d0,XDIFF1
 move.w PLR2_xoff,d0
 sub.w OLDX2,d0
 asl.w #4,d0
 ext.l d0
 divs d1,d0
 move.w d0,XDIFF2
 move.w PLR1_zoff,d0
 sub.w OLDZ1,d0
 asl.w #4,d0
 ext.l d0
 divs d1,d0
 move.w d0,ZDIFF1
 move.w PLR2_zoff,d0
 sub.w OLDZ2,d0
 asl.w #4,d0
 ext.l d0
 divs d1,d0
 move.w d0,ZDIFF2

 cmp.b #'s',mors
 beq.s ImPlayer2OhYesIAm
 bsr USEPLR1
 bra IWasPlayer1
 
ImPlayer2OhYesIAm:
 bsr USEPLR2
IWasPlayer1:
 

 cmp.b #'s',mors
 beq drawplayer2
 
 move.w #0,scaleval
 
 move.l PLR1_xoff,xoff
 move.l PLR1_yoff,yoff
 move.l PLR1_zoff,zoff
 move.w PLR1_angpos,angpos
 move.w PLR1_cosval,cosval
 move.w PLR1_sinval,sinval
 
 
 move.l PLR1_ListOfGraphRooms,ListOfGraphRooms
 move.l PLR1_PointsToRotatePtr,PointsToRotatePtr
 move.l PLR1_Roompt,Roompt

 bsr OrderZones
 jsr objmoveanim
 jsr EnergyBar
 jsr AmmoBar

;********************************************
;************* Do reflection ****************
;
; move.l ListOfGraphRooms,a0
; move.l ZoneAdds,a1
;checkwaterheights
; move.w (a0),d0
; blt allzonesdone
; addq #8,a0
; move.l (a1,d0.w*4),a2
; 
; add.l LEVELDATA,a2
; 
; move.l ToZoneWater(a2),d0
; cmp.l ToZoneFloor(a2),d0
; blt.s WEHAVEAHEIGHT
; 
; bra.s checkwaterheights
;
;WEHAVEAHEIGHT:
;
; sub.l yoff,d0
; blt.s underwater
; 
; add.l d0,d0
; add.l d0,yoff
; 
; move.l FASTBUFFER2,FASTBUFFER
; move.w #0,leftclip
; move.w RIGHTX,rightclip
; move.w #0,deftopclip
; move.w #BOTTOMY/2,defbotclip
; move.w #0,topclip
; move.w #BOTTOMY/2,botclip
;
; clr.b DOANYWATER 
; 
; bsr DrawDisplay
; 
;allzonesdone:
;underwater:

********************************************

 st DOANYWATER

 move.l PLR1_yoff,yoff

 move.w #0,leftclip
 move.w RIGHTX,rightclip
 move.w #0,deftopclip
 move.w WIDESCRN,d0
 add.w d0,deftopclip
 
 move.w BOTTOMY,defbotclip
 sub.w d0,defbotclip
 move.w #0,topclip
 add.w d0,topclip
 move.w BOTTOMY,botclip
 sub.w d0,botclip
; sub.l #10*104*4,frompt
; sub.l #10*104*4,midpt

* Subroom loop

 bsr DrawDisplay 

 bra nodrawp2
 
drawplayer2
 
 move.w #0,scaleval
 move.l PLR2_xoff,xoff
 move.l PLR2_yoff,yoff
 move.l PLR2_zoff,zoff
 move.w PLR2_angpos,angpos
 move.w PLR2_cosval,cosval
 move.w PLR2_sinval,sinval 



 move.l PLR2_ListOfGraphRooms,ListOfGraphRooms
 move.l PLR2_PointsToRotatePtr,PointsToRotatePtr
 move.l PLR2_Roompt,Roompt


 bsr OrderZones
 jsr objmoveanim
 jsr EnergyBar
 jsr AmmoBar
 
 move.w WIDESCRN,d0

 move.w #0,leftclip
 move.w RIGHTX,rightclip
 move.w #0,deftopclip
 add.w d0,deftopclip
 move.w BOTTOMY,defbotclip
 sub.w d0,defbotclip
 move.w #0,topclip
 add.w d0,topclip
 move.w BOTTOMY,botclip
 sub.w d0,botclip

 bsr DrawDisplay

nodrawp2:
 
***************************************** 
* Copy from copbuff to chip ram
 
 
; move.l drawpt,a3
; adda.w #10,a3
; move.l COPSCRNBUFF,a2
; move.w #2,d6
; adda.w #10,a2
;COPYOUT
; move.w #31,d0
;COPYDOWN1:
; move.w #3,d1
; move.l a2,a4
; move.l a3,a5
;.inlop1:
;val SET 0
; REPT 20
; move.w val(a4),val(a5)
;val SET val+104*4
; ENDR
; adda.l #104*4*20,a4
; adda.l #104*4*20,a5
; dbra d1,.inlop1
; addq #4,a2
; addq #4,a3
; dbra d0,COPYDOWN1
; addq #4,a2
; addq #4,a3
; dbra d6,COPYOUT 
 
 tst.b MAPON
 beq.s .nomap
 bsr DoTheMapWotNastyCharlesIsForcingMeToDo
.nomap

 move.w WIDESCRN,d7
 
 tst.b FULLSCR
 beq nobigconv

 move.l FASTBUFFER,a0
; add.l #320*2*20,a0
 move.w d7,d6
 muls #320,d6
 add.l d6,a0
 move.l SCRNDRAWPT,a1
 move.w d7,d6
 muls #40,d6
 add.l d6,a1
 add.l #2,a1
 move.l #(288/8)-1,d0
 move.l #231,d1
 sub.w d7,d1
 sub.w d7,d1
 blt nochunk
 move.w #(320-288),d2
 move.w #4,d3
 
 bra donebigconv
 
nobigconv:

 move.l FASTBUFFER,a0
 move.w d7,d6
 muls #320,d6
 add.l d6,a0
 move.l SCRNDRAWPT,a1
 add.l #8+40*20,a1
 move.w d7,d6
 muls #40,d6
 add.l d6,a1
 move.l #(192/8)-1,d0
 move.l #159,d1
 sub.w d7,d1
 sub.w d7,d1
 blt nochunk
 move.w #(320-192),d2
 move.w #16,d3
donebigconv

 tst.b DOUBLEHEIGHT
 beq.s .nodoub
 asr.w #1,d1
 blt nochunk
 add.w #320,d2
 add.w #40,d3
.nodoub:

 move.b DOUBLEWIDTH,d4
 move.b PLR1_TELEPORTED,d5
 clr.b PLR1_TELEPORTED
 jsr CHUNKYTOPLANAR 
 
nochunk:
 
 move.l #KeyMap,a5
 tst.b $4a(a5)
 beq .nosmallscr
 
 move.l #0,d7
 move.l #0,d6
 tst.b FULLSCR
 bne.s .attop
 move.l #40*20,d7
 move.l #40*60,d6
.attop:
 
 move.w WIDESCRN,d0
 move.l SCRNDRAWPT,a0
 add.l d7,a0
 muls #40,d0
 add.l d0,a0
 bsr CLRTWOLINES
 move.w WIDESCRN,d0
 move.l SCRNSHOWPT,a0
 add.l d7,a0
 muls #40,d0
 add.l d0,a0
 bsr CLRTWOLINES
 
 add.w #2,WIDESCRN

 move.l SCRNDRAWPT,a0
 add.l #232*40,a0
 sub.l d6,a0
 move.w WIDESCRN,d0
 muls #40,d0
 sub.l d0,a0
 bsr CLRTWOLINES
 move.l SCRNSHOWPT,a0
 sub.l d6,a0
 add.l #232*40,a0
 move.w WIDESCRN,d0
 muls #40,d0
 sub.l d0,a0
 bsr CLRTWOLINES

.nosmallscr

 tst.b $5e(a5)
 beq.s .nobigscr
 tst.w WIDESCRN
 ble.s .nobigscr
 
 sub.w #2,WIDESCRN

.nobigscr

 
 tst.b (a5)
 beq.s .nosavescrn

 not.b USEDOUG

 jsr SAVETHESCREEN

.nosavescrn:

 tst.b $5b(a5)
 beq notdoubheight
 tst.b LASTDH
 bne notdoubheight2
 st LASTDH 
 
 move.w #0,d0
 move.w #0,d1
 
 not.b DOUBLEHEIGHT
 beq.s singlepixheight
 move.w #-40,d0
 move.w #40,d1
 
singlepixheight:

 move.l #SCRMODULOS,a0
 move.w #115,d2
putinmode:
 move.w d0,6(a0)
 move.w d0,6+4(a0)
 move.w d1,6+16(a0)
 move.w d1,6+16+4(a0)
 add.w #32,a0
 dbra d2,putinmode

 bra notdoubheight2
 
notdoubheight:
 clr.b LASTDH
notdoubheight2
 
 tst.b $5a(a5)
 beq.s notdoubwidth
 tst.b LASTDW
 bne notdoubwidth2
 st LASTDW
 not.b DOUBLEWIDTH
 bra.s notdoubwidth2
 
notdoubwidth:
 clr.b LASTDW
notdoubwidth2:
 
***************************************** 
 move.l PLR2_Roompt,a0
 move.l #WorkSpace,a1
 clr.l (a1)
 clr.l 4(a1)
 clr.l 8(a1)
 clr.l 12(a1)
 clr.l 16(a1)
 clr.l 20(a1)
 clr.l 24(a1)
 clr.l 28(a1)
 
 cmp.b #'n',mors
 beq.s plr1only
 
 lea ToListOfGraph(a0),a0
.doallrooms:
 move.w (a0),d0
 blt.s .allroomsdone
 addq #8,a0
 move.w d0,d1
 asr.w #3,d0
 bset d1,(a1,d0.w)
 bra .doallrooms
.allroomsdone:

plr1only:

 move.l PLR1_Roompt,a0
 lea ToListOfGraph(a0),a0
.doallrooms2:
 move.w (a0),d0
 blt.s .allroomsdone2
 addq #8,a0
 move.w d0,d1
 asr.w #3,d0
 bset d1,(a1,d0.w)
 bra .doallrooms2
.allroomsdone2:

 move.l #%000001,d7
 lea TEAMWORK,a2
 move.l ObjectData,a0
 sub.w #64,a0
.doallobs:
 add.w #64,a0
 move.w (a0),d0
 blt.s .allobsdone
 move.w 12(a0),d0
 blt.s .doallobs
 move.w d0,d1
 asr.w #3,d0
 btst d1,(a1,d0.w)
 bne.s .worryobj
 move.b 16(a0),d0
 btst d0,d7
 beq.s .doallobs
 moveq #0,d0
 move.b teamnumber(a0),d0
 blt.s .doallobs
 asl.w #4,d0
 tst.w SEENBY(a2,d0.w)
 blt.s .doallobs
.worryobj:
 or.b #127,worry(a0)
 bra.s .doallobs
.allobsdone:
 
 
 
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

 move.l #KeyMap,a5
 tst.b $45(a5)
 beq.s noend
 
 cmp.b #'s',mors
 beq plr2quit 

 st MASTERQUITTING
 bra noend

plr2quit:
 st SLAVEQUITTING
noend:

 tst.b MASTERQUITTING
 beq.s .noquit
 tst.b SLAVEQUITTING
 beq.s .noquit
 jmp endnomusic
.noquit

 cmp.b #'n',mors
 bne.s noexit
 move.l PLR1_Roompt,a0
 move.w (a0),d0
; move.w PLOPT,d1
; move.l #ENDZONES,a0
; cmp.w (a0,d1.w*2),d0

 cmp.w ENDZONE,d0

; change this for quick exit, charlie
zzzz:
; bra end

 bne.s noexit
 jmp end
noexit:
 
 tst.w PLAYERONEHEALTH
 bgt nnoend1
 jmp end
nnoend1:
 tst.w PLR2_energy
 bgt nnoend2
 jmp end
nnoend2:

; move.l SwitchData,a0
; tst.b 24+8(a0)
; bne end
  
; JSR STOPTIMER
 
 
 bra lop
 
CLRTWOLINES:

 moveq #0,d1
 move.w #7,d2
.ccc
 move.l d1,2(a0)
 move.l d1,6(a0)
 move.l d1,10(a0)
 move.l d1,14(a0)
 move.l d1,18(a0)
 move.l d1,22(a0)
 move.l d1,26(a0)
 move.l d1,30(a0)
 move.l d1,34(a0)
 move.l d1,2+40(a0)
 move.l d1,6+40(a0)
 move.l d1,10+40(a0)
 move.l d1,14+40(a0)
 move.l d1,18+40(a0)
 move.l d1,22+40(a0)
 move.l d1,26+40(a0)
 move.l d1,30+40(a0)
 move.l d1,34+40(a0)
 add.l #10240,a0
 dbra d2,.ccc
 rts
 
 
LASTDH: dc.b 0
LASTDW: dc.b 0
WIDESCRN: dc.w 0
TRRANS: dc.w 0
DOANYWATER: dc.w 0
 
DoTheMapWotNastyCharlesIsForcingMeToDo:

 move.l #SHADINGTABLE,a4
; add.w MAPBRIGHT,a4

 move.l #KeyMap,a5
 tst.b $50(a5)
 beq.s .nobrighter
 tst.w MAPBRIGHT
 beq.s .nobrighter
 
 sub.w #1,MAPBRIGHT

.nobrighter:

 tst.b $51(a5)
 beq.s .nodimmer
 cmp.w #7,MAPBRIGHT
 bge.s .nodimmer
 
 add.w #1,MAPBRIGHT

.nodimmer:

 move.l #Rotated,a1
 move.l #COMPACTMAP,a2
 move.l #BIGMAP-40,a3

preshow:
 add.w #40,a3

SHOWMAP:
 move.l (a2)+,d5
 move.l a2,d7
 cmp.l LASTZONE,d7
 bgt shownmap

 tst.l d5
 beq.s preshow

 move.w #9,d7
wallsofzone

 asr.l #1,d5
 bcs.s WALLSEEN

 asr.l #1,d5
 bcs.s WALLMAPPED

 asr.l #1,d5
 addq #4,a3
 bra.s DECIDEDWALL

WALLMAPPED:
 move.w #$b00,d4
 asr.l #1,d5
 bcc.s .notadoor
 move.w #$e00,d4
.notadoor

 st TRRANS

 bra.s DECIDEDCOLOUR

WALLSEEN:

 clr.b TRRANS

 move.w #255,d4
 asr.l #2,d5
 bcc.s .notadoor
 move.w #254,d4
.notadoor
DECIDEDCOLOUR:
 move.w (a3)+,d6
 move.l (a1,d6.w*8),d0
 asr.l #7,d0
 add.w mapxoff,d0
 move.w 6(a1,d6.w*8),d1
 add.w mapzoff,d1
 move.w (a3)+,d6
 move.l (a1,d6.w*8),d2
 asr.l #7,d2
 add.w mapxoff,d2
 move.w 6(a1,d6.w*8),d3
 add.w mapzoff,d3

 neg.w d1
 neg.w d3
 
 movem.l d7/d5,-(a7)
 bsr CLIPANDDRAW
 movem.l (a7)+,d7/d5

DECIDEDWALL:
 
 dbra d7,wallsofzone
 bra SHOWMAP
 
shownmap:

 clr.b TRRANS

 move.w mapxoff,d0
 move.w mapzoff,d1
 neg.w d1
 move.w d0,d2
 move.w d1,d3
 sub.w #128,d1
 add.w #128,d3
 move.w #250,d4
 bsr CLIPANDDRAW

 move.w mapxoff,d0
 move.w mapzoff,d1
 neg.w d1
 move.w d0,d2
 move.w d1,d3
 sub.w #128,d1
 sub.w #32,d3
 sub.w #64,d2
 move.w #250,d4
 bsr CLIPANDDRAW

 move.w mapxoff,d0
 move.w mapzoff,d1
 neg.w d1
 move.w d0,d2
 move.w d1,d3
 sub.w #128,d1
 sub.w #32,d3
 add.w #64,d2
 move.w #250,d4
 bsr CLIPANDDRAW
 rts
 

CLIPANDDRAW:
 
 tst.b FULLSCR
 beq.s .nodov
 
 add.w d0,d0
 add.w d2,d2
 ext.l d0
 ext.l d2
 divs #3,d0
 divs #3,d2
 
.nodov:
 
 move.w MAPBRIGHT,d5
 asr.w d5,d0
 asr.w d5,d1
 asr.w d5,d2
 asr.w d5,d3
 
NOSCALING:
 add.w #96,d0
 bge p1xpos

 add.w #96,d2
 blt OFFSCREEN
 
x1nx2p:

 move.w d3,d5
 sub.w d1,d5
 move.w d2,d6
 sub.w d0,d6
 beq OFFSCREEN

 muls d0,d5
 divs d6,d5
 sub.w d5,d1
 move.w #0,d0
 
 bra doneleftclip
 
p1xpos:

 add.w #96,d2
 bge doneleftclip

 move.w d1,d5
 sub.w d3,d5
 move.w d0,d6
 sub.w d2,d6
 beq OFFSCREEN
 
 muls d2,d5
 divs d6,d5
 sub.w d5,d3
 move.w #0,d2

doneleftclip:

 cmp.w #191,d0
 ble p1xneg

 cmp.w #191,d2
 bgt OFFSCREEN

 move.w d0,d6
 sub.w d2,d6
 beq OFFSCREEN
 sub.w #191,d0
 move.w d3,d5
 sub.w d1,d5

 muls d5,d0
 divs d6,d0
 add.w d0,d1
 move.w #191,d0
 
 bra donerightclip
 
p1xneg:

 cmp.w #191,d2
 ble donerightclip
 
 move.w d2,d6
 sub.w d0,d6
 beq OFFSCREEN
 sub.w #191,d2
 move.w d1,d5
 sub.w d3,d5

 muls d5,d2
 divs d6,d2
 add.w d2,d3
 move.w #191,d2
 
donerightclip:

*********************************

 add.w #80,d1
 bge p1ypos

 add.w #80,d3
 blt OFFSCREEN
 
 move.w d2,d5
 sub.w d0,d5
 move.w d3,d6
 sub.w d1,d6
 beq OFFSCREEN

 muls d1,d5
 divs d6,d5
 sub.w d5,d0
 move.w #0,d1
 
 bra donetopclip
 
p1ypos:

 add.w #80,d3
 bge donetopclip

 move.w d0,d5
 sub.w d2,d5
 move.w d1,d6
 sub.w d3,d6
 beq OFFSCREEN

 muls d3,d5
 divs d6,d5
 sub.w d5,d2
 move.w #0,d3

donetopclip:

 cmp.w #159,d1
 ble p1yneg

 cmp.w #159,d3
 bgt OFFSCREEN

 move.w d1,d6
 sub.w d3,d6
 beq OFFSCREEN
 sub.w #159,d1
 move.w d2,d5
 sub.w d0,d5

 muls d5,d1
 divs d6,d1
 add.w d1,d0
 move.w #159,d1
 
 bra donebotclip
 
p1yneg:

 cmp.w #159,d3
 ble donebotclip
 
 move.w d3,d6
 sub.w d1,d6
 beq OFFSCREEN
 sub.w #159,d3
 move.w d0,d5
 sub.w d2,d5

 muls d5,d3
 divs d6,d3
 add.w d3,d2
 move.w #159,d3
 
donebotclip:
 
 tst.b TRRANS
 bne DRAWAtransLINE
 bra DRAWAMAPLINE
 
OFFSCREEN:
NOLINEtrans:
 rts
 
MAPBRIGHT:
 dc.w 0
mapxoff: dc.w 0
mapzoff: dc.w 0

DRAWAtransLINE:

 move.l FASTBUFFER,a0	; screen to render to.
 
 tst.b FULLSCR
 beq.s .nooffset
  
 add.l #(320*40)+(48*2),a0
  
.nooffset:
 
 cmp.w d1,d3
 bgt.s .okdown
 bne.s .aline
 cmp.w d0,d2
 beq.s NOLINEtrans 
.aline
 exg d0,d2
 exg d1,d3
.okdown

 move.w d1,d5
 muls #320,d5
 add.l d5,a0
 lea (a0,d0.w*2),a0

 sub.w d1,d3

 sub.w d0,d2
 bge.s downrighttrans
 
downlefttrans:
 neg.w d2
 cmp.w d2,d3
 bgt.s downmorelefttrans

downleftmoretrans:
 move.w #320,d6
 move.w d2,d0
 move.w d2,d7

.linelop:
 move.b (a0),d4
 move.b (a4,d4.w*2),(a0)
 subq #1,a0
 sub.w d3,d0
 bgt.s .noextra
 add.w d2,d0
 add.w d6,a0
.noextra:
 dbra d7,.linelop
 rts

downmorelefttrans:
 move.w #320,d6
 move.w d3,d0
 move.w d3,d7

.linelop:
 move.b (a0),d4
 move.b (a4,d4.w*2),(a0)
 add.w d6,a0
 sub.w d2,d0
 bgt.s .noextra
 add.w d3,d0
 subq #1,a0
.noextra:
 dbra d7,.linelop

 rts
 
downrighttrans:
 
 cmp.w d2,d3
 bgt.s downmorerighttrans
 
downrightmoretrans:
 move.w #320,d6
 move.w d2,d0
 move.w d2,d7

.linelop:
 move.b (a0),d4
 move.b (a4,d4.w*2),(a0)+
 sub.w d3,d0
 bgt.s .noextra
 add.w d2,d0
 add.w d6,a0
.noextra:
 dbra d7,.linelop

 rts

downmorerighttrans:
 move.w #320,d6
 move.w d3,d0
 move.w d3,d7

.linelop:
 move.b (a0),d4
 move.b (a4,d4.w*2),(a0)
 add.w d6,a0
 sub.w d2,d0
 bgt.s .noextra
 add.w d3,d0
 addq #1,a0
.noextra:
 dbra d7,.linelop
 
 rts
 
NOLINE:
 rts
 
DRAWAMAPLINE:
 
 
 move.l FASTBUFFER,a0	; screen to render to.
 cmp.w d1,d3
 bgt.s .okdown
 bne.s .aline
 cmp.w d0,d2
 beq.s NOLINE 
.aline
 exg d0,d2
 exg d1,d3
.okdown

 move.w d1,d5
 muls #320,d5
 add.l d5,a0
 lea (a0,d0.w),a0

 sub.w d1,d3

 sub.w d0,d2
 bge.s downright
 
downleft:
 neg.w d2
 cmp.w d2,d3
 bgt.s downmoreleft

downleftmore:
 move.w #320,d6
 move.w d2,d0
 move.w d2,d7
 addq #1,a0

.linelop:
 move.b d4,-(a0)
 sub.w d3,d0
 bgt.s .noextra
 add.w d2,d0
 add.w d6,a0
.noextra:
 dbra d7,.linelop
 rts

downmoreleft:
 move.w #320,d6
 move.w d3,d0
 move.w d3,d7

.linelop:
 move.b d4,(a0)
 add.w d6,a0
 sub.w d2,d0
 bgt.s .noextra
 add.w d3,d0
 subq #1,a0
.noextra:
 dbra d7,.linelop

 rts
 
downright:
 
 cmp.w d2,d3
 bgt.s downmoreright
 
downrightmore:
 move.w #320,d6
 move.w d2,d0
 move.w d2,d7

.linelop:
 move.b d4,(a0)+
 sub.w d3,d0
 bgt.s .noextra
 add.w d2,d0
 add.w d6,a0
.noextra:
 dbra d7,.linelop

 rts

downmoreright:
 move.w #320,d6
 move.w d3,d0
 move.w d3,d7

.linelop:
 move.b d4,(a0)
 add.w d6,a0
 sub.w d2,d0
 bgt.s .noextra
 add.w d3,d0
 addq #1,a0
.noextra:
 dbra d7,.linelop
 
 rts
 
SAVETHESCREEN:

 move.l old,$dff080
 move.w #$8020,$dff000+intena

 move.l doslib,a6
 move.l #SAVENAME,d1
 move.l #1006,d2
 jsr -30(a6)
 move.l d0,handle

 move.l doslib,a6
 move.l #scrn,d2
 move.l handle,d1
 move.l #10240*8,d3
 jsr _LVOWrite(a6)
 
 move.l doslib,a6
 move.l handle,d1
 jsr -36(a6)
 
 move.l doslib,a6
 move.l #200,d1
 jsr -198(a6) 
 
 move.w #$0020,$dff000+intena
 move.l #bigfield,$dff080
 
 add.b #1,SAVELETTER

 rts
 
SAVENAME: dc.b 'df0:rawscrn'
SAVELETTER: dc.b 'd',0

 even
 
 include "ab3:source_4000/CHUNKY.s"
 
 
MASTERQUITTING: dc.b 0
SLAVEQUITTING: dc.b 0
MASTERPAUSE: dc.b 0
SLAVEPAUSE: dc.b 0

PAUSEOPTS:
 include "ab3:source_4000/pauseopts"

ENDZONE: dc.w 0

ENDZONES:
; LEVEL 1
 dc.w -1
; dc.w 55
; LEVEL 2
 dc.w 149
; LEVEL 3
 dc.w 155
; LEVEL 4
 dc.w 107
; LEVEL 5
 dc.w 67
; LEVEL 6
 dc.w 132
; LEVEL 7
 dc.w 203
; LEVEL 8
 dc.w 166
; LEVEL 9
 dc.w 118
; LEVEL 10
 dc.w 102
; LEVEL 11
 dc.w 103
; LEVEL 12
 dc.w 2
; LEVEL 13
 dc.w 98
; LEVEL 14
 dc.w 0
; LEVEL 15
 dc.w 148
; LEVEL 16
 dc.w 103

***************************************************************************
***************************************************************************
****************** End of Main Loop here ********************************** 
***************************************************************************
***************************************************************************

putinsmallscr:

 rts

 move.l #$1fe0000,statskip
 move.l #$1fe0000,statskip+4

 move.l #healthpal,a5
; move.l COPSCRN1,a0
; move.l COPSCRN2,a2
 move.w #scrheight-1,d0
 move.l #0,d6
 move.w #0,d3
 move.w #$2bdf,startwait
 move.w #$2d01,endwait
.fillcop
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
 

 move.l #$1060c42,(a1)+
 move.l #$1060c42,(a3)+
 move.w #$19e,(a1)+
 move.w (a5),(a1)+
 move.w #$19e,(a3)+
 move.w (a5)+,(a3)+

**********************************

 adda.w #104*4,a0
 adda.w #104*4,a2
 dbra d0,.fillcop

 move.w #$48,fetchstart
 move.w #$88,fetchstop
 move.w #$2cb1,winstart
 move.w #$2c91,winstop
 move.w #-24,modulo
 move.w #-24,modulo+4

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

 move.l #borders,d0
 move.w d0,s0l
 swap d0
 move.w d0,s0h
 move.l #borders+2592,d0
 move.w d0,s1l
 swap d0
 move.w d0,s1h
 move.l #borders+2592*2,d0
 move.w d0,s2l
 swap d0
 move.w d0,s2h
 move.l #borders+2592*3,d0
 move.w d0,s3l
 swap d0
 move.w d0,s3h

 
 move.l #scrn+40,a0
 move.l #scrn+160,a1
 move.l #scrn+280,a2
 move.l #smallscrntab,a3
 move.w #191,d7	; counter
 move.w #0,d1	; xpos
.plotscrnloop:
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
 beq.s .nobp1
 bset.b d3,-40(a0,d2.w)
.nobp1:
 btst #1,d0
 beq.s .nobp2
 bset.b d3,(a0,d2.w)
.nobp2:
 btst #2,d0
 beq.s .nobp3
 bset.b d3,40(a0,d2.w)
.nobp3:
 btst #3,d0
 beq.s .nobp4
 bset.b d3,-40(a1,d2.w)
.nobp4:
 btst #4,d0
 beq.s .nobp5
 bset.b d3,(a1,d2.w)
.nobp5:
 btst #5,d0
 beq.s .nobp6
 bset.b d3,40(a1,d2.w)
.nobp6:
 btst #6,d0
 beq.s .nobp7
 bset.b d3,-40(a2,d2.w)
.nobp7:

 addq #1,d1

 dbra d7,.plotscrnloop


 rts

putinlargescr:

 move.l #$1000000,statskip
 move.l #$fffffffe,statskip+4

 move.l #healthpal,a5
; move.l COPSCRN1,a0
; move.l COPSCRN2,a2
 move.w #scrheight-1,d0
 move.l #0,d6
 move.w #0,d3
 move.w #$29df,startwait
 move.w #$2b01,endwait
.fillcop
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
 
 move.w startwait,(a1)+
 move.w #$fffe,(a1)+
 move.w endwait,(a1)+
 move.w #$ff00,(a1)+
 move.w startwait,(a3)+
 move.w #$fffe,(a3)+
 move.w endwait,(a3)+
 move.w #$ff00,(a3)+

; move.l $1fe0000,(a1)+
; move.l $1fe0000,(a3)+
; move.l $1fe0000,(a1)+
; move.l $1fe0000,(a3)+
 
 
 add.w #$300,startwait
 add.w #$300,endwait

; move.l #$1060c42,(a1)+
; move.l #$1060c42,(a3)+
; move.w #$19e,(a1)+
; move.w (a5),(a1)+
; move.w #$19e,(a3)+
; move.w (a5)+,(a3)+

**********************************

 adda.w #104*4,a0
 adda.w #104*4,a2
 dbra d0,.fillcop

 move.w #$38,fetchstart
 move.w #$b8,fetchstop
 move.w #$2c81,winstart
 move.w #$2cc1,winstop
 move.w #-40,modulo
 move.w #-40,modulo+4

 move.l #nullspr,d0
 move.w d0,s0l
 move.w d0,s1l
 move.w d0,s2l
 move.w d0,s3l
 move.w d0,s4l
 move.w d0,s5l
 move.w d0,s6l
 move.w d0,s7l
 swap d0
 move.w d0,s0h
 move.w d0,s1h
 move.w d0,s2h
 move.w d0,s3h
 move.w d0,s4h
 move.w d0,s5h
 move.w d0,s6h
 move.w d0,s7h 
 
 move.l #scrn+40,a0
 move.l #scrn+160,a1
 move.l #scrn+280,a2
 move.l #scrntab,a3
 move.w #319,d7	; counter
 move.w #0,d1	; xpos
.plotscrnloop:
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
 beq.s .nobp1
 bset.b d3,-40(a0,d2.w)
.nobp1:
 btst #1,d0
 beq.s .nobp2
 bset.b d3,(a0,d2.w)
.nobp2:
 btst #2,d0
 beq.s .nobp3
 bset.b d3,40(a0,d2.w)
.nobp3:
 btst #3,d0
 beq.s .nobp4
 bset.b d3,-40(a1,d2.w)
.nobp4:
 btst #4,d0
 beq.s .nobp5
 bset.b d3,(a1,d2.w)
.nobp5:
 btst #5,d0
 beq.s .nobp6
 bset.b d3,40(a1,d2.w)
.nobp6:
 btst #6,d0
 beq.s .nobp7
 bset.b d3,-40(a2,d2.w)
.nobp7:
 
 addq #1,d1

 dbra d7,.plotscrnloop

 rts
 
CLEARKEYBOARD:
 move.l #KeyMap,a5
 moveq #0,d0
 move.w #15,d1
clrloo:
 move.l d0,(a5)+
 move.l d0,(a5)+
 move.l d0,(a5)+
 move.l d0,(a5)+
 dbra d1,clrloo
 rts

READCONTROLS: dc.w 0

tstststst: dc.w 0

BollocksRoom:
 dc.w -1
 ds.l 50
 
GUNYOFFS:
 dc.w 20
 dc.w 20
 dc.w 0
 dc.w 20
 dc.w 20
 dc.w 0
 dc.w 0
 dc.w 20
 
PLR1_BOBBLEY: dc.l 0

USEPLR1:

***********************************

 move.l PLR1_Obj,a0 
 move.l ObjectPoints,a1
 move.l #ObjRotated,a2
 move.w (a0),d0
 move.l PLR1_xoff,(a1,d0.w*8)
 move.l PLR1_zoff,4(a1,d0.w*8)
 move.l PLR1_Roompt,a1

 moveq #0,d2
 move.b damagetaken(a0),d2
 beq .notbeenshot
 move.l #7*2116,hitcol
 sub.w d2,PLAYERONEHEALTH
 movem.l d0-d7/a0-a6,-(a7)
 move.b #$fb,IDNUM
 move.w #19,Samplenum
 clr.b notifplaying
 move.w #0,Noisex
 move.w #0,Noisez
 move.w #100,Noisevol
 jsr MakeSomeNoise
 
 movem.l (a7)+,d0-d7/a0-a6

.notbeenshot
 move.b #0,damagetaken(a0)
 move.b #10,numlives(a0)

 move.w p1_angpos,Facing(a0)
 move.b PLR1_StoodInTop,ObjInTop(a0)
 
 move.w (a1),12(a0)
 move.w (a1),d2
 move.l #ZoneBrightTable,a1
 move.l (a1,d2.w*4),d2
 tst.b PLR1_StoodInTop
 bne.s .okinbott
 swap d2
.okinbott:

 move.w d2,2(a0)
 
 move.l p1_yoff,d0
 move.l p1_height,d1
 asr.l #1,d1
 add.l d1,d0
 asr.l #7,d0
 move.w d0,4(a0)

***********************************

 move.l PLR2_Obj,a0 
 
 move.w PLR2_angpos,d0
 and.w #8190,d0
 move.w d0,Facing(a0)
 
 jsr ViewpointToDraw
 asl.w #2,d0
 moveq #0,d1
 move.b p2_bobble,d1
 not.b d1
 lsr.b #3,d1
 and.b #$3,d1
 add.w d1,d0
 move.w d0,10(a0)
 move.w #10,8(a0)
 
 move.l ObjectPoints,a1
 move.l #ObjRotated,a2
 move.w (a0),d0
 move.l PLR2_xoff,(a1,d0.w*8)
 move.l PLR2_zoff,4(a1,d0.w*8)
 move.l PLR2_Roompt,a1

 moveq #0,d2
 move.b damagetaken(a0),d2
 beq .notbeenshot2
 sub.w d2,PLR2_energy
.notbeenshot2
 move.b #0,damagetaken(a0)
 move.b #10,numlives(a0)

 move.b PLR2_StoodInTop,ObjInTop(a0)
 
 move.w (a1),12(a0)
 move.w (a1),d2
 move.l #ZoneBrightTable,a1
 move.l (a1,d2.w*4),d2
 tst.b PLR2_StoodInTop
 bne.s .okinbott2
 swap d2
.okinbott2:

 move.w d2,2(a0)
 
 move.l p2_yoff,d0
 move.l p2_height,d1
 asr.l #1,d1
 add.l d1,d0
 asr.l #7,d0
 move.w d0,4(a0)

**********************************

 move.l PLR1_Obj,a0
 move.l PLR1_Roompt,a1
 
 move.w Facing(a0),d0
 add.w #4096,d0
 and.w #8190,d0
 move.w d0,Facing+128(a0)
 
 move.w (a1),12+128(a0)
 move.w (a1),GraphicRoom+128(a0)

 moveq #0,d0
 move.b p1_gunselected,d0

 move.l LINKFILE,a1
 add.l #GunObjects,a1
 move.w (a1,d0.w*2),d0
 
 move.b d0,TypeOfThing+128(a0)
 move.b #1,128+16(a0)
 
 move.w (a0),d0
 move.w 128(a0),d1
 move.l ObjectPoints,a1
 move.l (a1,d0.w*8),(a1,d1.w*8)
 move.l 4(a1,d0.w*8),4(a1,d1.w*8)

 st WhichAnim+128(a0)

 move.l p1_yoff,d0
 move.l p1_height,d1
 asr.l #2,d1
 add.l #10*128,d1
 add.l d1,d0
 asr.l #7,d0
 move.w d0,4+128(a0)
 move.l PLR1_BOBBLEY,d1
 asr.l #8,d1
 move.l d1,d0
 asr.l #1,d0
 add.l d0,d1
 add.w d1,4+128(a0)
 
 move.b ObjInTop(a0),ObjInTop+128(a0)

 rts
 
DRAWINGUN:
 move.l #Objects+9*16,a0
 move.l 4(a0),a5	; ptr
 move.l 8(a0),a2	; frames
 move.l 12(a0),a4	; pal
 move.l (a0),a0		; wad
 
 move.l #GunAnims,a1
 move.l (a1,d0.w*8),a1
 move.w (a1,d1.w*2),d5	; frame of anim
 
 move.l #GUNYOFFS,a1
 move.w (a1,d0.w*2),d7	; yoff
 move.l FASTBUFFER,a6
 move.w d7,d6
 muls #320*2,d6
 add.l d6,a6	; screen pointer

 asl.w #2,d0
 add.w d5,d0	; frame
 move.w (a2,d0.w*4),d1	; xoff

 lea (a5,d1.w),a5	; right ptr
 
 move.w #95,d0
 bsr DRAWCHUNK
; addq.w #4,a6
; move.w #31,d0
; bsr DRAWCHUNK
; addq.w #4,a6
; move.w #31,d0
; bsr DRAWCHUNK
 rts
 
 
DRAWCHUNK:
 move.w #78,d3
 sub.w d7,d3
 move.l a6,a3
 move.b (a5),d2
 move.l (a5)+,d1
 bne.s .noblank
 addq #4,a6
 dbra d0,DRAWCHUNK 
 rts
 
.noblank:
 and.l #$ffffff,d1
 lea (a0,d1.l),a1
 cmp.b #1,d2
 bgt.s thirdd
 beq.s secc
.drawdown:
 move.w (a1)+,d2
 and.w #%11111,d2
 beq.s .itsblank
 move.w (a4,d2.w*2),d4
 move.w d4,d5
 swap d4
 move.w d5,d4
 move.l d4,(a3)
 move.l d4,320(a3)
.itsblank
 add.w #320*2,a3
 dbra d3,.drawdown

 addq #2,a6
 dbra d0,DRAWCHUNK
 rts

secc:
.drawdown:
 move.w (a1)+,d2
 lsr.w #5,d2
 and.w #%11111,d2
 beq.s .itsblank
 move.w (a4,d2.w*2),d4
 move.w d4,d5
 swap d4
 move.w d5,d4
 move.l d4,(a3)
 move.l d4,320*2(a3)
.itsblank
 add.w #320*2*2,a3
 dbra d3,.drawdown

 addq #4,a6
 dbra d0,DRAWCHUNK
 rts

thirdd:
.drawdown:
 move.b (a1),d2
 addq #2,a1
 lsr.b #2,d2
 and.w #%11111,d2
 beq.s .itsblank
 move.w (a4,d2.w*2),d4
 move.w d4,d5
 swap d4
 move.w d5,d4
 move.l d4,(a3)
 move.l d4,320*2(a3)
.itsblank
 add.w #320*2*2,a3
 dbra d3,.drawdown

 addq #4,a6
 dbra d0,DRAWCHUNK
 rts

 

***************************************************
**************************************************

USEPLR2:

 PROTKCHECK a0

***********************************

 move.l PLR2_Obj,a0 
 move.l ObjectPoints,a1
 move.l #ObjRotated,a2
 move.w (a0),d0
 move.l PLR2_xoff,(a1,d0.w*8)
 move.l PLR2_zoff,4(a1,d0.w*8)
 move.l PLR2_Roompt,a1

 moveq #0,d2
 move.b damagetaken(a0),d2
 beq .notbeenshot
 move.l #7*2116,hitcol
 sub.w d2,PLR2_energy
 movem.l d0-d7/a0-a6,-(a7)
 move.w #19,Samplenum
 clr.b notifplaying
 move.b #$fb,IDNUM
 move.w #0,Noisex
 move.w #0,Noisez
 move.w #100,Noisevol
 jsr MakeSomeNoise
 
 movem.l (a7)+,d0-d7/a0-a6

.notbeenshot
 move.b #0,damagetaken(a0)
 move.b #10,numlives(a0)

 move.b PLR2_StoodInTop,ObjInTop(a0)
 
 move.w (a1),12(a0)
 move.w (a1),d2
 move.l #ZoneBrightTable,a1
 move.l (a1,d2.w*4),d2
 tst.b PLR2_StoodInTop
 bne.s .okinbott
 swap d2
.okinbott:

 move.w d2,2(a0)
 
 move.l PLR2_yoff,d0
 move.l p2_height,d1
 asr.l #1,d1
 add.l d1,d0
 asr.l #7,d0
 move.w d0,4(a0)

***********************************

 move.l PLR1_Obj,a0 

 move.w PLR1_angpos,d0
 and.w #8190,d0
 move.w d0,Facing(a0)
 
 jsr ViewpointToDraw
 asl.w #2,d0
 moveq #0,d1
 move.b p1_bobble,d1
 not.b d1
 lsr.b #3,d1
 and.b #$3,d1
 add.w d1,d0
 move.w d0,10(a0)
 move.w #10,8(a0)

 move.l ObjectPoints,a1
 move.l #ObjRotated,a2
 move.w (a0),d0
 move.l PLR1_xoff,(a1,d0.w*8)
 move.l PLR1_zoff,4(a1,d0.w*8)
 move.l PLR1_Roompt,a1

 moveq #0,d2
 move.b damagetaken(a0),d2
 beq .notbeenshot2
 sub.w d2,PLAYERONEHEALTH
.notbeenshot2
 move.b #0,damagetaken(a0)
 move.b #10,numlives(a0)

 move.b PLR1_StoodInTop,ObjInTop(a0)
 
 move.w (a1),12(a0)
 move.w (a1),d2
 move.l #ZoneBrightTable,a1
 move.l (a1,d2.w*4),d2
 tst.b PLR1_StoodInTop
 bne.s .okinbott2
 swap d2
.okinbott2:

 move.w d2,2(a0)
 
 move.l PLR1_yoff,d0
 move.l p1_height,d1
 asr.l #1,d1
 add.l d1,d0
 asr.l #7,d0
 move.w d0,4(a0)

**********************************

 move.l PLR2_Obj,a0
 move.w #-1,12+64(a0)

 rts


GunSelected: dc.b 0
 even
 
GunAnims:
 dc.l MachineAnim,3
 dc.l PlasmaAnim,5
 dc.l RocketAnim,5
 dc.l FlameThrowerAnim,5
 dc.l GrenadeAnim,12
 dc.l 0,0
 dc.l 0,0
 dc.l ShotGunAnim,12+19+11+20+1
 
MachineAnim:
 dc.w 0,1,2,3
PlasmaAnim:
 dc.w 0,1,2,3,3,3
RocketAnim:
 dc.w 0,1,2,3,3,3
FlameThrowerAnim:
 dc.w 0,1,2,3,3,3
GrenadeAnim:
 dc.w 0,1,1,1,1
 dc.w 2,2,2,2,3
 dc.w 3,3,3
ShotGunAnim:
 dc.w 0
 dcb.w 12,2
 dcb.w 19,1
 dcb.w 11,2
 dcb.w 20,0
 dc.w 3

GunData: dc.l 0

PLR1_GunData:
; 0=Pistol 1=Big Gun
; ammoleft,ammopershot(b),gunnoise(b),ammoinclip(b)

; VISIBLE/INSTANT (0/FF)
; damage,gotgun(b)
; Delay (w), Lifetime of bullet (w)
; Click or hold down (0,1)
; BulSpd: (w)

;0
 dc.w 0
;2
 dc.b 8,3
;4
 dc.b 15
;5
 dc.b -1
;6
 dc.b 4,$ff
;8
 dc.w 5,-1,1,0
;16
 dc.w 0,0,0
;22
 dc.w 1
 
 ds.w 4
 
;PlasmaGun
 
 dc.w 0
 dc.b 8,1
 dc.b 20
 dc.b 0
 dc.b 16,0
 dc.w 10,-1,0,5
 dc.w 0,0,0
 dc.w 1

 ds.w 4
 
;RocketLauncher

 dc.w 0
 dc.b 8,9
 dc.b 2
 dc.b 0
 dc.b 12,0
 dc.w 30,-1,0,5
 dc.w 0,0,0
 dc.w 1
 
 
 ds.w 4

; FlameThrower
 
 dc.w 90*8
 dc.b 1,22
 dc.b 40
 dc.b 0
 dc.b 8,$0	
 dc.w 5,50,1,4
 dc.w 0,0,0
 dc.w 1
 
 ds.w 4

;Grenade launcher


 dc.w 0
 dc.b 8,9
 dc.b 6
 dc.b 0
 dc.b 8,0
 dc.w 50,100,1,5
 dc.w 60,3
 dc.w -1000
 dc.w 1
 
 ds.w 4
 
; WORMGUN

 dc.w 0
 dc.b 0,0
 dc.b 0
 dc.b 0,0
 dc.w 0,-1,0,5
 dc.w 0,0
 dc.w 0
 dc.w 1
 ds.w 4

; ToughMarineGun

 dc.w 0
 dc.b 0,0
 dc.b 0
 dc.b 0,0
 dc.w 0,-1,0,5
 dc.w 0,0
 dc.w 0
 dc.w 1
 ds.w 4

; Shotgun

;0
 dc.w 0
;2
 dc.b 8,21
;4
 dc.b 15
;5
 dc.b -1
;6
 dc.b 4,0
;8
 dc.w 50,-1,1,0
;16
 dc.w 0,0,0
;22
 dc.w 7
 
 ds.w 4

PLR2_GunData:
; 0=Pistol 1=Big Gun
; ammoleft,ammopershot(b),gunnoise(b),ammoinclip(b)

; VISIBLE/INSTANT (0/FF)
; damage,gotgun(b)
; Delay (w)

;0
 dc.w 0
;2
 dc.b 8,3
;4
 dc.b 15
;5
 dc.b -1
;6
 dc.b 4,$ff
;8
 dc.w 5,-1,1,0
;16
 dc.w 0,0,0
;22
 dc.w 1
 
 ds.w 4
 
;PlasmaGun
 
 dc.w 0
 dc.b 8,1
 dc.b 20
 dc.b 0
 dc.b 16,0
 dc.w 10,-1,0,5
 dc.w 0,0,0
 dc.w 1

 ds.w 4
 
;RocketLauncher

 dc.w 0
 dc.b 8,9
 dc.b 2
 dc.b 0
 dc.b 12,0
 dc.w 30,-1,0,5
 dc.w 0,0,0
 dc.w 1
 
 
 ds.w 4

; FlameThrower
 
 dc.w 90*8
 dc.b 1,22
 dc.b 40
 dc.b 0
 dc.b 8,$0	
 dc.w 5,50,1,4
 dc.w 0,0,0
 dc.w 1
 
 ds.w 4

;Grenade launcher


 dc.w 0
 dc.b 8,9
 dc.b 6
 dc.b 0
 dc.b 8,0
 dc.w 50,100,1,5
 dc.w 60,3
 dc.w -1000
 dc.w 1
 
 ds.w 4
 
; WORMGUN

 dc.w 0
 dc.b 0,0
 dc.b 0
 dc.b 0,0
 dc.w 0,-1,0,5
 dc.w 0,0
 dc.w 0
 dc.w 1
 ds.w 4

; ToughMarineGun

 dc.w 0
 dc.b 0,0
 dc.b 0
 dc.b 0,0
 dc.w 0,-1,0,5
 dc.w 0,0
 dc.w 0
 dc.w 1
 ds.w 4

; Shotgun

;0
 dc.w 0
;2
 dc.b 8,21
;4
 dc.b 15
;5
 dc.b -1
;6
 dc.b 4,0
;8
 dc.w 50,-1,1,0
;16
 dc.w 0,0,0
;22
 dc.w 7
 
 ds.w 4



protA: dc.w 0

Path:
; incbin "testpath"
endpath:
pathpt: dc.l Path


PLR1KEYS: dc.b 0
PLR1PATH: dc.b 0
PLR1MOUSE: dc.b -1
PLR1JOY: dc.b 0
PLR2KEYS: dc.b 0
PLR2PATH: dc.b 0
PLR2MOUSE: dc.b -1
PLR2JOY: dc.b 0
 
 even

PLR1_bobble: dc.w 0
PLR2_bobble: dc.w 0
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
 move.l p1_xoff,d0
 move.l d0,PLR1_xoff
 move.l d0,newx
 move.l p1_zoff,d1
 move.l d1,newz
 move.l d1,PLR1_zoff

 move.l p1_height,PLR1_height
 
 sub.l d2,d0
 sub.l d3,d1
 move.l d0,xdiff
 move.l d1,zdiff
 move.w p1_angpos,d0
 move.w d0,PLR1_angpos
 
 move.l #SineTable,a1
 move.w (a1,d0.w),PLR1_sinval
 add.w #2048,d0
 and.w #8190,d0
 move.w (a1,d0.w),PLR1_cosval

 move.l p1_yoff,d0
 move.w p1_bobble,d1
 move.w (a1,d1.w),d1
 move.w d1,d3
 ble.s notnegative
 neg.w d1
notnegative:
 add.w #16384,d1
 asr.w #4,d1

 tst.b PLR1_Ducked
 bne.s .notdouble
 add.w d1,d1
.notdouble
 ext.l d1
 
 move.l d1,PLR1_BOBBLEY
 
 move.l PLR1_height,d4
 sub.l d1,d4
 add.l d1,d0
 
 cmp.b #'s',mors
 beq.s .otherwob
 asr.w #6,d3
 ext.l d3
 move.l d3,xwobble
 move.w PLR1_sinval,d1
 muls d3,d1
 move.w PLR1_cosval,d2
 muls d3,d2
 swap d1
 swap d2
 asr.w #7,d1
 move.w d1,xwobxoff
 asr.w #7,d2
 neg.w d2
 move.w d2,xwobzoff
.otherwob
 
 move.l d0,PLR1_yoff
 move.l d0,newy
 move.l d0,oldy
 
 move.l d4,thingheight
 move.l #40*256,StepUpVal
 tst.b PLR1_Ducked
 beq.s .okbigstep
 move.l #10*256,StepUpVal
.okbigstep:
 
 move.l #$1000000,StepDownVal
 
 move.l PLR1_Roompt,a0
 move.w ToTelZone(a0),d0
 blt .noteleport
 
 move.w ToTelX(a0),newx
 move.w ToTelZ(a0),newz
 move.w #-1,CollId
 move.l #%111111111111111111,CollideFlags
 bsr Collision
 tst.b hitwall
 beq.s .teleport
 
 move.w PLR1_xoff,newx
 move.w PLR1_zoff,newz
 bra .noteleport
 
.teleport:

 st PLR1_TELEPORTED

 move.l PLR1_Roompt,a0
 move.w ToTelZone(a0),d0
 move.w ToTelX(a0),PLR1_xoff
 move.w ToTelZ(a0),PLR1_zoff
 move.l PLR1_yoff,d1
 sub.l ToZoneFloor(a0),d1
 move.l ZoneAdds,a0
 move.l (a0,d0.w*4),a0
 add.l LEVELDATA,a0
 move.l a0,PLR1_Roompt
 add.l ToZoneFloor(a0),d1
 move.l d1,PLR1s_yoff
 move.l d1,PLR1_yoff
 move.l d1,PLR1s_tyoff
 move.l PLR1_xoff,PLR1s_xoff
 move.l PLR1_zoff,PLR1s_zoff
 
 SAVEREGS
 move.w #0,Noisex
 move.w #0,Noisez
 move.w #26,Samplenum
 move.w #100,Noisevol
 move.b #$fa,IDNUM
 jsr MakeSomeNoise
 GETREGS
 
 bra .cantmove
 
.noteleport:
 
 move.l PLR1_Roompt,objroom
 move.w #%100000000,wallflags
 move.b PLR1_StoodInTop,StoodInTop

 move.l #%1011111110111000011,CollideFlags
 move.w #-1,CollId

 bsr Collision
 tst.b hitwall
 beq.s .nothitanything
 move.w oldx,PLR1_xoff
 move.w oldz,PLR1_zoff
 move.l PLR1_xoff,PLR1s_xoff
 move.l PLR1_zoff,PLR1s_zoff
 bra .cantmove
.nothitanything:

 move.w #40,extlen
 move.b #0,awayfromwall

 clr.b exitfirst
 clr.b wallbounce
 bsr MoveObject
 move.b StoodInTop,PLR1_StoodInTop
 move.l objroom,PLR1_Roompt
 move.w newx,PLR1_xoff
 move.w newz,PLR1_zoff
 move.l PLR1_xoff,PLR1s_xoff
 move.l PLR1_zoff,PLR1s_zoff
 
.cantmove:
 
 move.l PLR1_Roompt,a0
 
 move.l ToZoneFloor(a0),d0
 tst.b PLR1_StoodInTop
 beq.s notintop
 move.l ToUpperFloor(a0),d0
notintop:

 adda.w #ToZonePts,a0
 sub.l PLR1_height,d0
 move.l d0,PLR1s_tyoff
 move.w p1_angpos,tmpangpos

; move.l (a0),a0		; jump to viewpoint list
 * A0 is pointing at a pointer to list of points to rotate
 move.w (a0)+,d1
 ext.l d1
 add.l PLR1_Roompt,d1
 move.l d1,PLR1_PointsToRotatePtr
 tst.w (a0)+
 sne.s DRAWNGRAPHTOP
 beq.s nobackgraphics
 cmp.b #'s',mors
 beq.s nobackgraphics
 move.l a0,-(a7)
 jsr putinbackdrop 
 move.l (a7)+,a0
nobackgraphics:
 adda.w #10,a0
 move.l a0,PLR1_ListOfGraphRooms

*************************************************
 rts

DRAWNGRAPHTOP
 dc.w 0 
tstzone: dc.l 0
CollId: dc.w 0

PLR2_Control:

 PROTLCHECK a0

; Take a snapshot of everything.

 move.l PLR2_xoff,d2
 move.l d2,PLR2_oldxoff
 move.l d2,oldx
 move.l PLR2_zoff,d3
 move.l d3,PLR2_oldzoff
 move.l d3,oldz
 move.l p2_xoff,d0
 move.l d0,PLR2_xoff
 move.l d0,newx
 move.l p2_zoff,d1
 move.l d1,newz
 move.l d1,PLR2_zoff

 move.l p2_height,PLR2_height
 
 sub.l d2,d0
 sub.l d3,d1
 move.l d0,xdiff
 move.l d1,zdiff
 move.w p2_angpos,d0
 move.w d0,PLR2_angpos
 
 move.l #SineTable,a1
 move.w (a1,d0.w),PLR2_sinval
 add.w #2048,d0
 and.w #8190,d0
 move.w (a1,d0.w),PLR2_cosval
 
 move.l p2_yoff,d0
 move.w p2_bobble,d1
 move.w (a1,d1.w),d1
 move.w d1,d3
 ble.s .notnegative
 neg.w d1
.notnegative:
 add.w #16384,d1
 asr.w #4,d1
 add.w d1,d1
 ext.l d1
 move.l PLR2_height,d4
 sub.l d1,d4
 add.l d1,d0
 
 cmp.b #'s',mors
 bne.s .otherwob
 asr.w #6,d3
 ext.l d3
 move.l d3,xwobble
 move.w PLR2_sinval,d1
 muls d3,d1
 move.w PLR2_cosval,d2
 muls d3,d2
 swap d1
 swap d2
 asr.w #7,d1
 move.w d1,xwobxoff
 asr.w #7,d2
 neg.w d2
 move.w d2,xwobzoff
.otherwob
 
 move.l d0,PLR2_yoff
 move.l d0,newy
 move.l d0,oldy
 
 move.l d4,thingheight
 move.l #40*256,StepUpVal
 tst.b PLR2_Ducked
 beq.s .okbigstep
 move.l #10*256,StepUpVal
.okbigstep:

 move.l #$1000000,StepDownVal

 move.l PLR2_Roompt,a0
 move.w ToTelZone(a0),d0
 blt .noteleport
 
 move.w ToTelX(a0),newx
 move.w ToTelZ(a0),newz
 move.w #-1,CollId
 move.l #%111111111111111111,CollideFlags
 bsr Collision
 tst.b hitwall
 beq.s .teleport
 
 move.w PLR2_xoff,newx
 move.w PLR2_zoff,newz
 bra .noteleport
 
.teleport:

 move.l PLR2_Roompt,a0
 move.w ToTelZone(a0),d0
 move.w ToTelX(a0),PLR2_xoff
 move.w ToTelZ(a0),PLR2_zoff
 move.l PLR2_yoff,d1
 sub.l ToZoneFloor(a0),d1
 move.l ZoneAdds,a0
 move.l (a0,d0.w*4),a0
 add.l LEVELDATA,a0
 move.l a0,PLR2_Roompt
 add.l ToZoneFloor(a0),d1
 move.l d1,PLR2s_yoff
 move.l d1,PLR2_yoff
 move.l d1,PLR2s_tyoff
 move.l PLR2_xoff,PLR2s_xoff
 move.l PLR2_zoff,PLR2s_zoff
 
 SAVEREGS
 move.w #0,Noisex
 move.w #0,Noisez
 move.w #26,Samplenum
 move.w #100,Noisevol
 move.b #$fa,IDNUM
 jsr MakeSomeNoise
 GETREGS
 
 bra .cantmove
 
.noteleport:
 
 move.l PLR2_Roompt,objroom
 move.w #%100000000000,wallflags
 move.b PLR2_StoodInTop,StoodInTop

 move.l #%1011111010111100011,CollideFlags
 move.w #-1,CollId

 bsr Collision
 tst.b hitwall
 beq.s .nothitanything
 move.w oldx,PLR2_xoff
 move.w oldz,PLR2_zoff
 move.l PLR2_xoff,PLR2s_xoff
 move.l PLR2_zoff,PLR2s_zoff
 bra .cantmove
.nothitanything:

 move.w #40,extlen
 move.b #0,awayfromwall

 clr.b exitfirst
 clr.b wallbounce
 bsr MoveObject
 move.b StoodInTop,PLR2_StoodInTop
 move.l objroom,PLR2_Roompt
 move.w newx,PLR2_xoff
 move.w newz,PLR2_zoff
 move.l PLR2_xoff,PLR2s_xoff
 move.l PLR2_zoff,PLR2s_zoff
 
.cantmove
 
 move.l PLR2_Roompt,a0
 
 move.l ToZoneFloor(a0),d0
 tst.b PLR2_StoodInTop
 beq.s .notintop
 move.l ToUpperFloor(a0),d0
.notintop:

 adda.w #ToZonePts,a0
 sub.l PLR2_height,d0
 move.l d0,PLR2s_tyoff
 move.w p2_angpos,tmpangpos

; move.l (a0),a0		; jump to viewpoint list
 * A0 is pointing at a pointer to list of points to rotate
 move.w (a0)+,d1
 ext.l d1
 add.l PLR2_Roompt,d1
 move.l d1,PLR2_PointsToRotatePtr
 tst.w (a0)+
 beq.s .nobackgraphics
 cmp.b #'s',mors
 bne.s .nobackgraphics
 move.l a0,-(a7)
 jsr putinbackdrop 
 move.l (a7)+,a0
.nobackgraphics:
 adda.w #10,a0
 move.l a0,PLR2_ListOfGraphRooms

*****************************************************

 rts


KeyMap: ds.b 256

fillscrnwater:
 dc.w 0
DONTDOGUN:
 dc.w 0
 
temptemp: ds.l 200
temptempptr: dc.l 0

DrawDisplay:

 move.l #temptemp,temptempptr

 clr.b fillscrnwater

 move.l #SineTable,a0
 move.w angpos,d0
 move.w (a0,d0.w),d6
 adda.w #2048,a0
 move.w (a0,d0.w),d7
 move.w d6,sinval
 move.w d7,cosval

 move.l #KeyMap,a5
 moveq #0,d5
 move.b look_behind_key,d5
 tst.b (a5,d5.w)
 sne DONTDOGUN
 beq.s .nolookback
 neg.w cosval
 neg.w sinval
.nolookback:


 move.l yoff,d0
 asr.l #8,d0
 move.w d0,d1
 add.w #256-32,d1
 and.w #255,d1
 move.w d1,wallyoff
 move.l yoff,d0
 asr.l #6,d0
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
 bsr CalcPLR1InLine
 
 
 cmp.b #'n',mors
 bne.s doplr2too
 move.l PLR2_Obj,a0
 move.w #-1,12(a0)
 move.w #-1,GraphicRoom(a0)
 bra noplr2either

doplr2too:
 bsr CalcPLR2InLine
noplr2either:

 move.l endoflist,a0
subroomloop:
 move.w -(a0),d7
 blt jumpoutofrooms
 
; bsr setlrclip
; move.w leftclip,d0
; cmp.w rightclip,d0
; bge subroomloop
 move.l a0,-(a7)
 
 move.l ZoneAdds,a0
 move.l (a0,d7.w*4),a0
 add.l LEVELDATA,a0
 move.l ToZoneRoof(a0),SplitHeight
 move.l a0,ROOMBACK
 
 move.l ZoneGraphAdds,a0
 move.l 4(a0,d7.w*8),a2
 move.l (a0,d7.w*8),a0
 
 add.l LEVELGRAPHICS,a0
 add.l LEVELGRAPHICS,a2
 move.l a2,ThisRoomToDraw+4
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
 move.w RIGHTX,rightclip
 moveq #0,d7
 move.w 2(a1),d7
 blt.s outofrcliplop
 move.l LEVELCLIPS,a0
 lea (a0,d7.l*2),a0

 tst.w (a0)
 blt outoflcliplop
 
 bsr NEWsetlclip
 
intolcliplop:		; clips
 tst.w (a0)
 blt outoflcliplop
 
 bsr NEWsetlclip 
 bra intolcliplop
 
outoflcliplop:

 addq #2,a0

 tst.w (a0)
 blt outofrcliplop
 
 bsr NEWsetrclip
 
intorcliplop:		; clips
 tst.w (a0)
 blt outofrcliplop
 
 bsr NEWsetrclip 
 bra intorcliplop
 
outofrcliplop:
 
 
 move.w leftclip,d0
 cmp.w RIGHTX,d0
 bge dontbothercantseeit
 move.w rightclip,d1
 blt dontbothercantseeit
 cmp.w d1,d0
 bge dontbothercantseeit
 
 move.l yoff,d0
 cmp.l SplitHeight,d0
 blt botfirst
 
 move.l ThisRoomToDraw+4,a0
 cmp.l LEVELGRAPHICS,a0
 beq.s noupperroom
 st DOUPPER
 
 move.l ROOMBACK,a1
 move.l ToUpperRoof(a1),TOPOFROOM
 move.l ToUpperFloor(a1),BOTOFROOM
 
 move.l #CurrentPointBrights+4,PointBrightsPtr
 bsr dothisroom
noupperroom:
 move.l ThisRoomToDraw,a0
 clr.b DOUPPER
 move.l #CurrentPointBrights,PointBrightsPtr

 move.l ROOMBACK,a1
 move.l ToZoneRoof(a1),d0
 move.l d0,TOPOFROOM
 move.l ToZoneFloor(a1),d1
 move.l d1,BOTOFROOM

 move.l ToZoneWater(a1),d2
 cmp.l yoff,d2
 blt.s .abovefirst
 move.l d2,BEFOREWATTOP
 move.l d1,BEFOREWATBOT
 move.l d2,AFTERWATBOT
 move.l d0,AFTERWATTOP
 bra.s .belowfirst
.abovefirst:
 move.l d0,BEFOREWATTOP
 move.l d2,BEFOREWATBOT
 move.l d1,AFTERWATBOT
 move.l d2,AFTERWATTOP
.belowfirst:

 bsr dothisroom
 
 bra dontbothercantseeit
botfirst:

 move.l ThisRoomToDraw,a0
 clr.b DOUPPER
 move.l #CurrentPointBrights,PointBrightsPtr

 move.l ROOMBACK,a1
 move.l ToZoneRoof(a1),d0
 move.l d0,TOPOFROOM
 move.l ToZoneFloor(a1),d1
 move.l d1,BOTOFROOM

 move.l ToZoneWater(a1),d2
 cmp.l yoff,d2
 blt.s .abovefirst
 move.l d2,BEFOREWATTOP
 move.l d1,BEFOREWATBOT
 move.l d2,AFTERWATBOT
 move.l d0,AFTERWATTOP
 bra.s .belowfirst
.abovefirst:
 move.l d0,BEFOREWATTOP
 move.l d2,BEFOREWATBOT
 move.l d1,AFTERWATBOT
 move.l d2,AFTERWATTOP
.belowfirst:


 bsr dothisroom
 move.l ThisRoomToDraw+4,a0
 cmp.l LEVELGRAPHICS,a0
 beq.s noupperroom2
 move.l #CurrentPointBrights+4,PointBrightsPtr

 move.l ROOMBACK,a1
 move.l ToUpperRoof(a1),TOPOFROOM
 move.l ToUpperFloor(a1),BOTOFROOM

 st DOUPPER
 bsr dothisroom
noupperroom2:
 
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


 tst.b DONTDOGUN
 bne NOGUNLOOK

 cmp.b #'s',mors
 beq.s drawslavegun

 moveq #0,d0
 move.b PLR1_GunSelected,d0
 moveq #0,d1
 move.b PLR1_GunFrame,d1
; bsr DRAWINGUN
 bra drawngun

drawslavegun
 moveq #0,d0
 move.b PLR2_GunSelected,d0
 moveq #0,d1
 move.b PLR2_GunFrame,d1
; bsr DRAWINGUN

drawngun:
 
NOGUNLOOK:
 
 moveq #0,d1
 move.b PLR1_GunFrame,d1
 sub.w TempFrames,d1
 bgt.s .nn
 moveq #0,d1
.nn
 move.b d1,PLR1_GunFrame
 
 ble.s .donefire
 sub.b #1,PLR1_GunFrame
.donefire:

 moveq #0,d1
 move.b PLR2_GunFrame,d1
 sub.w TempFrames,d1
 bgt.s .nn2
 moveq #0,d1
.nn2
 move.b d2,PLR2_GunFrame
 
 ble.s .donefire2
 sub.b #1,PLR2_GunFrame
.donefire2:

 tst.b DOANYWATER
 beq.s nowaterfull

 move.w #239,d0
 move.l FASTBUFFER,a0
 tst.b fillscrnwater
 beq nowaterfull
 bgt oknothalf
 moveq #119,d0
 add.l #320*120*2,a0
oknothalf:

 bclr.b #1,$bfe001

 move.l #brightentab+512*4,a2
 moveq #0,d2

fw:
 move.w #287,d1
fwa:
 move.b (a0),d2
 move.w (a2,d2.w*2),(a0)+
 dbra d1,fwa
 add.w #32*2,a0
 dbra d0,fw
 
; move.l frompt,a0
; add.l #104*4*60,a0
; 
; move.w #31,d0
;fw:
; move.w d5,d1
; move.l a0,a1
;fwd:
;val SET 104*4*19
; REPT 20
; and.w #$ff,val(a1)
;val SET val-104*4
; ENDR
; sub.l #104*4*20,a1
; dbra d1,fwd
; addq #4,a0
; dbra d0,fw
;
; addq #4,a0
;
; move.w #31,d0
;sw:
; move.w d5,d1
; move.l a0,a1
;swd:
;val SET 104*4*19
; REPT 20
; and.w #$ff,val(a1)
;val SET val-104*4
; ENDR
; sub.l #104*4*20,a1
; dbra d1,swd
; addq #4,a0
; dbra d0,sw
;
; addq #4,a0
;
; move.w #31,d0
;tw:
; move.w d5,d1
; move.l a0,a1
;twd:
;val SET 104*4*19
; REPT 20
; and.w #$ff,val(a1)
;val SET val-104*4
; ENDR
; sub.l #104*4*20,a1
; dbra d1,twd
; addq #4,a0
; dbra d0,tw
;
 rts

nowaterfull:
 bset.b #1,$bfe001
 rts
 
prot9: dc.w 0
 
TempBuffer: ds.l 100 

prot8: dc.w 0

ClipTable: ds.l 30
EndOfClipPt: dc.l 0
DOUPPER: dc.w 0

RealTable:
 dc.l prot1-78935450
 dc.l prot2-78935450
 dc.l prot3-78935450
 dc.l prot4-78935450
 dc.l prot5-78935450
 dc.l prot6-78935450
 dc.l prot7-78935450
 dc.l prot8-78935450
 dc.l prot9-78935450
 dc.l protA-78935450

dothisroom

 move.w (a0)+,d0
 move.w d0,currzone
 move.w d0,d1
 muls #40,d1
 add.l #BIGMAP,d1
 move.l d1,BIGPTR
 move.w d0,d1
 ext.l d1
 asl.w #2,d1
 add.l #COMPACTMAP,d1
 move.l d1,COMPACTPTR
 add.l #4,d1
 cmp.l LASTZONE,d1
 ble.s .nochange
 move.l d1,LASTZONE
.nochange:
 
 move.l #ZoneBrightTable,a1
 move.l (a1,d0.w*4),d1
 tst.b DOUPPER
 bne.s .okbot
 swap d1
.okbot:
 move.w d1,ZoneBright

polyloop:
 move.w (a0)+,d0
 move.w d0,WALLIDENT
 and.w #$ff,d0
 tst.b d0
 blt jumpoutofloop
 beq itsawall
 cmp.w #3,d0
 beq itsasetclip
 blt itsafloor
 cmp.w #4,d0
 beq itsanobject
 cmp.w #5,d0
 beq itsanarc
 cmp.w #6,d0
 beq itsalightbeam
 cmp.w #7,d0
 beq.s itswater
 cmp.w #9,d0
 ble itsachunkyfloor
 cmp.w #11,d0
 ble itsabumpyfloor
 cmp.w #12,d0
 beq.s itsbackdrop
 cmp.w #13,d0
 beq.s itsaseewall
 
 bra polyloop
 
itsaseewall:
 st seethru
 jsr itsawalldraw
 bra polyloop
 
itsbackdrop:
 jsr putinbackdrop
 bra polyloop
 
itswater:
 PROTHCHECK
 move.w #2,SMALLIT
 move.w #3,d0
 clr.b gourfloor
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
 move.w #1,SMALLIT
 sub.w #9,d0
 st usebumps
 st smoothbumps
 clr.b usewater
 move.l #BumpLine,LineToUse
 jsr itsafloordraw
 bra polyloop
 
itsachunkyfloor:
 move.w #1,SMALLIT
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

 move.l PointBrightsPtr,FloorPtBrights

 move.w currzone,d1
 muls #80,d1

 cmp.w #2,d0
 bne.s .nfl
 add.l #2,d1
.nfl
 add.l d1,FloorPtBrights

 move.w #1,SMALLIT

 movem.l a0/d0,-(a7)
 move.l $4.w,a6
 jsr _LVOSuperState(a6)
 move.l d0,SSTACK
 movem.l (a7)+,a0/d0

 move.l #FloorLine,LineToUse
* 1,2 = floor/roof
 clr.b usewater
 clr.b usebumps
 move.b GOURSEL,gourfloor	
 jsr itsafloordraw
 move.l a0,-(a7)
 move.l $4.w,a6
 move.l SSTACK,d0
 jsr _LVOUserState(a6)
 move.l (a7)+,a0
 bra polyloop
itsasetclip:
 bra polyloop
itsawall:
 clr.b seethru
; move.l #stripbuffer,a1
 jsr itsawalldraw
 bra polyloop

jumpoutofloop:
 rts

LASTZONE: dc.l 0
COMPACTPTR: dc.l 0
BIGPTR: dc.l 0
WALLIDENT: dc.w 0
SMALLIT: dc.w 0
GOURSEL: dc.w 0
ThisRoomToDraw: dc.l 0,0
SplitHeight: dc.l 0

 include "ab3:source_4000/OrderZones"

ReadMouse:
 move.l #$dff000,a6
 clr.l d0
 clr.l d1
 move.w $a(a6),d0
 lsr.w #8,d0
 ext.l d0
 move.w d0,d3
 move.w oldmy,d2
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
 move.w d2,oldmy
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

 add.w d0,oldx2
 move.w oldx2,d0
 and.w #2047,d0
 move.w d0,oldx2
 
 asl.w #2,d0
 sub.w prevx,d0
 add.w d0,prevx
 asr.w #1,d0
 move.w d0,d1
 bge.s .okpos
 neg.w d1
.okpos:
 muls d1,d0
 add.w d0,angpos
 move.w #0,lrs
 rts

noturn:

; got to move lr instead. 

; d1 = speed moved l/r

 move.w d1,lrs

 rts
 
lrs: dc.w 0
prevx: dc.w 0
 
angpos: dc.w 0
mang: dc.w 0
oldymouse: dc.w 0
xmouse: dc.w 0
ymouse: dc.w 0
oldx2: dc.w 0
oldmx: dc.w 0
oldmy: dc.w 0
oldy2: dc.w 0

MAPON: dc.w $ffff

RotateLevelPts:

 tst.b MAPON
 beq ONLYTHELONELY
 
 move.w sinval,d6
 swap d6
 move.w cosval,d6
 move.l Points,a3
 move.l #Rotated,a1
 move.l #OnScreen,a2
 move.w xoff,d4
 move.w zoff,d5
 
; move.w #$c40,$dff106
; move.w #$f00,$dff180
 
 move.w NumLevPts,d7

 tst.b FULLSCR
 bne BIGALL
 
pointrotlop2:
 move.w (a3)+,d0
 sub.w d4,d0
 move.w d0,d2
 move.w (a3)+,d1
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
 move.l d2,(a1)+

 muls d6,d0
 swap d6
 muls d6,d1
 add.l d0,d1
 asl.l #1,d1
 swap d1
; ext.l d1
; divs #3,d1
 move.l d1,(a1)+

 tst.w d1
 bgt.s ptnotbehind
 tst.w d2
 bgt.s onrightsomewhere
 move.w #0,d2
 bra putin
onrightsomewhere:
 move.w RIGHTX,d2
 bra putin
ptnotbehind:

 divs d1,d2
 add.w MIDDLEX,d2
putin:
 move.w d2,(a2)+
 
 dbra d7,pointrotlop2
outofpointrot:
  rts
 

BIGALL:
 
pointrotlop2B:
 move.w (a3)+,d0
 sub.w d4,d0
 move.w d0,d2
 move.w (a3)+,d1
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
 move.l d2,(a1)+

 muls d6,d0
 swap d6
 muls d6,d1
 add.l d0,d1
 asl.l #2,d1
 swap d1
 ext.l d1
 divs #3,d1
 move.l d1,(a1)+

 tst.w d1
 bgt.s ptnotbehindB
 tst.w d2
 bgt.s onrightsomewhereB
 move.w #0,d2
 bra putinB
onrightsomewhereB:
 move.w RIGHTX,d2
 bra putinB
ptnotbehindB:

 divs d1,d2
 add.w MIDDLEX,d2
putinB:
 move.w d2,(a2)+
 
 dbra d7,pointrotlop2B
  rts


ONLYTHELONELY:

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
 
 tst.b FULLSCR
 bne BIGLONELY
 
pointrotlop:
 move.w (a0)+,d7
 blt outofpointrot
 
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
 asl.l #1,d1
 swap d1
; ext.l d1
; divs #3,d1
 move.l d1,4(a1,d7*8)

 tst.w d1
 bgt.s .ptnotbehind
 tst.w d2
 bgt.s .onrightsomewhere
 move.w #0,d2
 bra .putin
.onrightsomewhere:
 move.w RIGHTX,d2
 bra .putin
.ptnotbehind:

 divs d1,d2
 add.w MIDDLEX,d2
.putin:
 move.w d2,(a2,d7*2)
 
 bra pointrotlop

; move.w #$c40,$dff106
; move.w #$ff0,$dff180

 rts

BIGLONELY:

.pointrotlop:
 move.w (a0)+,d7
 blt.s .outofpointrot
 
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
 ext.l d1
 divs #3,d1
 move.l d1,4(a1,d7*8)

 tst.w d1
 bgt.s .ptnotbehind
 tst.w d2
 bgt.s .onrightsomewhere
 move.w #0,d2
 bra .putin
.onrightsomewhere:
 move.w RIGHTX,d2
 bra .putin
.ptnotbehind:

 divs d1,d2
 add.w MIDDLEX,d2
.putin:
 move.w d2,(a2,d7*2)
 
 bra .pointrotlop

.outofpointrot:
; move.w #$c40,$dff106
; move.w #$ff0,$dff180

 rts


PLR1_ObjDists
 ds.w 250
PLR2_ObjDists
 ds.w 250

CalcPLR1InLine:

 move.w PLR1_sinval,d5
 move.w PLR1_cosval,d6
 move.l ObjectData,a4
 move.l ObjectPoints,a0
 move.w NumObjectPoints,d7
 move.l #PLR1_ObsInLine,a2
 move.l #PLR1_ObjDists,a3

.objpointrotlop:
 
 cmp.b #3,16(a4)
 beq.s .itaux
 
 move.w (a0),d0
 sub.w PLR1_xoff,d0
 move.w 4(a0),d1
 addq #8,a0
 
 tst.w 12(a4)
 blt .noworkout
 
 moveq #0,d2
 move.b 16(a4),d2
 ;move.l #ColBoxTable,a6
 ;lea (a6,d2.w*8),a6
 
 sub.w PLR1_zoff,d1
 move.w d0,d2
 muls d6,d2
 move.w d1,d3
 muls d5,d3
 sub.l d3,d2
 add.l d2,d2
 
 bgt.s .okh
 neg.l d2
.okh:
 swap d2
 
 muls d5,d0
 muls d6,d1
 add.l d0,d1
 asl.l #2,d1
 swap d1
 moveq #0,d3
 
 tst.w d1
 ble.s .notinline
 asr.w #1,d2
 cmp.w #80,d2
 bgt.s .notinline
 
 st d3
.notinline
 move.b d3,(a2)+

 move.w d1,(a3)+

 add.w #64,a4
 dbra d7,.objpointrotlop

 rts
 
.itaux:
 add.w #64,a4
 bra .objpointrotlop

 
.noworkout:
 move.b #0,(a2)+
 move.w #0,(a3)+
 add.w #64,a4
 dbra d7,.objpointrotlop
 rts
 

CalcPLR2InLine:

 move.w PLR2_sinval,d5
 move.w PLR2_cosval,d6
 move.l ObjectData,a4
 move.l ObjectPoints,a0
 move.w NumObjectPoints,d7
 move.l #PLR2_ObsInLine,a2
 move.l #PLR2_ObjDists,a3

.objpointrotlop:
 
 move.w (a0),d0
 sub.w PLR2_xoff,d0
 move.w 4(a0),d1
 addq #8,a0
 
 tst.w 12(a4)
 blt .noworkout
 
 moveq #0,d2
 move.b 16(a4),d2
 move.l #ColBoxTable,a6
 lea (a6,d2.w*8),a6
 
 sub.w PLR2_zoff,d1
 move.w d0,d2
 muls d6,d2
 move.w d1,d3
 muls d5,d3
 sub.l d3,d2
 add.l d2,d2

 bgt.s .okh
 neg.l d2
.okh:
 swap d2

 muls d5,d0
 muls d6,d1
 add.l d0,d1
 asl.l #2,d1
 swap d1
 moveq #0,d3

 tst.w d1
 ble.s .notinline
 asr.w #1,d2
 cmp.w (a6),d2
 bgt.s .notinline
 
 st d3
.notinline
 move.b d3,(a2)+

 move.w d1,(a3)+

 add.w #64,a4
 dbra d7,.objpointrotlop

 rts
 
.noworkout:
 move.w #0,(a3)+
 move.b #0,(a2)+
 add.w #64,a4
 dbra d7,.objpointrotlop
 rts
 

RotateObjectPts:

 move.w sinval,d5
 move.w cosval,d6

 move.l ObjectData,a4
 move.l ObjectPoints,a0
 move.w NumObjectPoints,d7
 move.l #ObjRotated,a1
 
 tst.b FULLSCR
 bne BIGOBJPTS
 
 
.objpointrotlop:
 
 cmp.b #3,16(a4)
 beq.s .itaux
 
 move.w (a0),d0
 sub.w xoff,d0
 move.w 4(a0),d1
 addq #8,a0
 
 tst.w 12(a4)
 blt .noworkout
 
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
 asl.l #1,d1
 swap d1
; ext.l d1
; divs #3,d1
 moveq #0,d3
 
 move.w d1,(a1)+
 ext.l d2
 asl.l #7,d2
 add.l xwobble,d2
 move.l d2,(a1)+

 dbra d7,.objpointrotlop

 rts

.itaux:
 add.w #64,a4
 bra .objpointrotlop
 
.noworkout:
  move.l #0,(a1)+
  move.l #0,(a1)+
  add.w #64,a4
  dbra d7,.objpointrotlop
  rts
  
BIGOBJPTS:

.objpointrotlop:
 
 cmp.b #3,16(a4)
 beq.s .itaux
 
 move.w (a0),d0
 sub.w xoff,d0
 move.w 4(a0),d1
 addq #8,a0
 
 tst.w 12(a4)
 blt .noworkout
 
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
 ext.l d1
 divs #3,d1
 moveq #0,d3
 
 move.w d1,(a1)+
 ext.l d2
 asl.l #7,d2
 add.l xwobble,d2
 move.l d2,(a1)+
 sub.l xwobble,d2

 add.w #64,a4
 dbra d7,.objpointrotlop

 rts

.itaux:
 add.w #64,a4
 bra .objpointrotlop
 
.noworkout:
  move.l #0,(a1)+
  move.l #0,(a1)+
  add.w #64,a4
  dbra d7,.objpointrotlop
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
 cmp.w RIGHTX,d0
 blt.s somevis2
 rts
somevis2:
 cmp.w RIGHTX,d1
 blt.s okrightend
 move.w RIGHTX,d1
 subq #1,d1
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
Ammo: dc.w 63
OldAmmo: dc.w 63

FullEnergy:
 move.w #127,Energy
 move.w #127,OldEnergy
 move.l #health,a0
 move.l #borders,a1
 add.l #25*8*2+6,a1
 lea 2592(a1),a2
 move.w #127,d0
PutInFull:
 move.b (a0)+,(a1)
 move.b (a0)+,8(a1)
 add.w #16,a1
 move.b (a0)+,(a2)
 move.b (a0)+,8(a2)
 add.w #16,a2
 dbra d0,PutInFull
 
 rts
 
;EnergyBar:

 move.w Energy,d0
 bgt.s .noeneg
 move.w #0,d0
.noeneg:
 move.w d0,Energy
 
 cmp.w OldEnergy,d0
 bne.s gottochange
 
NoChange
 rts
 
gottochange:
  
 blt LessEnergy
 cmp.w #127,Energy
 blt.s NotMax
 move.w #127,Energy
NotMax:

 move.w Energy,d0
 move.w OldEnergy,d2
 sub.w d0,d2
 beq.s NoChange	
 neg.w d2
 
 move.w #127,d3
 sub.w d0,d3
 
 move.l #health,a0
 lea (a0,d3.w*4),a0
 move.l #borders+25*16+6,a1
 lsl.w #4,d3
 add.w d3,a1
 lea 2592(a1),a2
 
EnergyRise:
 move.b (a0)+,(a1)
 move.b (a0)+,8(a1)
 add.w #16,a1
 move.b (a0)+,(a2)
 move.b (a0)+,8(a2)
 add.w #16,a2
 subq #1,d2
 bgt.s EnergyRise

 move.w Energy,OldEnergy

 rts 

LessEnergy: 
 move.w OldEnergy,d2
 sub.w d0,d2
 
 move.w #127,d3
 sub.w OldEnergy,d3
 
 move.l #borders+25*16+6,a1
 asl.w #4,d3
 add.w d3,a1
 lea 2592(a1),a2

EnergyDrain:
 move.b #0,(a1)
 move.b #0,8(a1)
 move.b #0,(a2)
 move.b #0,8(a2)
 add.w #16,a1
 add.w #16,a2
 subq #1,d2
 bgt.s EnergyDrain

 move.w Energy,OldEnergy

 rts 

firstdigit: dc.b 0
secdigit: dc.b 0
thirddigit: dc.b 0

 even

AmmoBar:

* Do guns first.

 move.l #borderchars,a4
 move.l #PLAYERONEGUNS,a5
 move.w #9,d2
 moveq #0,d0
putingunnums:
 move.w #4,d1
 move.l a4,a0
 cmp.b p1_gunselected,d0
 bne.s .notsel
 add.l #5*10*8*2,a0
 addq #2,a5
 bra.s .donesel
.notsel:
 tst.w (a5)+
 beq.s .donesel
 add.l #5*10*8,a0
.donesel:
 move.l SCRNDRAWPT,a1
 add.w d0,a1
 add.l #3+(240*40),a1
 bsr DRAWDIGIT
 addq #1,d0
 dbra d2,putingunnums

 move.w Ammo,d0
 ext.l d0
 divs #10,d0
 swap d0
 move.b d0,thirddigit
 swap d0
 ext.l d0
 divs #10,d0
 move.b d0,firstdigit
 swap d0
 move.b d0,secdigit

 move.l #borderchars+15*8*10,a0
 cmp.w #10,Ammo
 blt.s .notsmallamo
 add.l #7*8*10,a0
.notsmallamo:

 move.l SCRNDRAWPT,a1
 add.l #20+238*40,a1
 move.b firstdigit,d0
 move.w #6,d1
 bsr DRAWDIGIT

 move.l SCRNDRAWPT,a1
 add.l #21+238*40,a1
 move.b secdigit,d0
 move.w #6,d1
 bsr DRAWDIGIT

 move.l SCRNDRAWPT,a1
 add.l #22+238*40,a1
 move.b thirddigit,d0
 move.w #6,d1
 bsr DRAWDIGIT

 rts

EnergyBar:
 move.w Energy,d0
 bge.s .okpo
 moveq #0,d0 
.okpo:
 
 ext.l d0
 divs #10,d0
 swap d0
 move.b d0,thirddigit
 swap d0
 ext.l d0
 divs #10,d0
 move.b d0,firstdigit
 swap d0
 move.b d0,secdigit

 move.l #borderchars+15*8*10,a0
 cmp.w #10,Energy
 blt.s .notsmallamo
 add.l #7*8*10,a0
.notsmallamo:

 move.l SCRNDRAWPT,a1
 add.l #34+238*40,a1
 move.b firstdigit,d0
 move.w #6,d1
 bsr DRAWDIGIT

 move.l SCRNDRAWPT,a1
 add.l #35+238*40,a1
 move.b secdigit,d0
 move.w #6,d1
 bsr DRAWDIGIT

 move.l SCRNDRAWPT,a1
 add.l #36+238*40,a1
 move.b thirddigit,d0
 move.w #6,d1
 bsr DRAWDIGIT

 move.l SCRNSHOWPT,a1
 add.l #34+238*40,a1
 move.b firstdigit,d0
 move.w #6,d1
 bsr DRAWDIGIT

 move.l SCRNSHOWPT,a1
 add.l #35+238*40,a1
 move.b secdigit,d0
 move.w #6,d1
 bsr DRAWDIGIT

 move.l SCRNSHOWPT,a1
 add.l #36+238*40,a1
 move.b thirddigit,d0
 move.w #6,d1
 bsr DRAWDIGIT


 rts


DRAWDIGIT:
 ext.w d0
 lea (a0,d0.w),a2
charlines:
 lea 30720(a1),a3 
 move.b (a2),(a1)
 move.b 10(a2),10240(a1)
 move.b 20(a2),20480(a1)
 move.b 30(a2),(a3)
 move.b 40(a2),10240(a3)
 move.b 50(a2),20480(a3)
 lea 30720(a3),a3
 move.b 60(a2),(a3)
 move.b 70(a2),10240(a3)
 
 add.w #10*8,a2
 add.w #40,a1
 dbra d1,charlines
 
 rts
 
borderchars: incbin "ab3:includes/bordercharsRAW"

NARRATOR:

; sub.w #1,NARRTIME
; bge .NOCHARYET
; move.w #3,NARRTIME

 move.l #SCROLLSCRN,d1
 move.w d1,scroll
 swap d1
 move.w d1,scrolh

 move.w SCROLLTIMER,d0
 subq #1,d0
 move.w d0,SCROLLTIMER
 cmp.w #40,d0
 bge .NOCHARYET
 tst.w d0
 bge.s .okcha
 
 move.w #150,SCROLLTIMER
 bra .NOCHARYET
 
.okcha:

 move.l #SCROLLSCRN,a0
 add.w SCROLLXPOS,a0

 moveq #1,d7
.doachar: 
 
 move.l SCROLLPOINTER,a1
 moveq #0,d1
 move.b (a1)+,d1	; character
 move.l a1,d2
 cmp.l ENDSCROLL,d2
 blt.s .notrestartscroll
 move.l #BLANKSCROLL,a1
 move.l #BLANKSCROLL+80,ENDSCROLL
.notrestartscroll
 move.l a1,SCROLLPOINTER
 
 move.l #SCROLLCHARS,a1
 asl.w #3,d1
 add.w d1,a1
 
 move.b (a1)+,(a0)
 move.b (a1)+,80(a0)
 move.b (a1)+,80*2(a0)
 move.b (a1)+,80*3(a0)
 move.b (a1)+,80*4(a0)
 move.b (a1)+,80*5(a0)
 move.b (a1)+,80*6(a0)
 move.b (a1)+,80*7(a0)
 
 addq #1,a0
 dbra d7,.doachar
 
 move.w SCROLLXPOS,d0
 addq #2,d0
 move.w d0,SCROLLXPOS
 cmp.w #80,d0
 blt .NOCHARYET
 move.w #0,SCROLLXPOS
 
.NOCHARYET:
 rts

; cmp.w OldAmmo,d0
; bne.s .gottochange
; 

NARRTIME: dc.w 5

SCROLLCHARS: incbin "ab3:includes/scrollfont"

.NoChange
 rts
 
.gottochange:
  
 blt LessAmmo
 cmp.w #63,Ammo
 blt.s .NotMax
 move.w #63,Ammo
.NotMax:

 move.w Ammo,d0
 move.w OldAmmo,d2
 sub.w d0,d2
 beq.s .NoChange
 neg.w d2
 
 move.w #63,d3
 sub.w d0,d3
 
 move.l #Ammunition,a0
 lea (a0,d3.w*8),a0
 move.l #borders+5184+25*16+1,a1
 lsl.w #5,d3
 add.w d3,a1
 lea 2592(a1),a2
 
AmmoRise:
 move.b (a0)+,(a1)
 move.b (a0)+,8(a1)
 add.w #16,a1
 move.b (a0)+,(a2)
 move.b (a0)+,8(a2)
 add.w #16,a2
 move.b (a0)+,(a1)
 move.b (a0)+,8(a1)
 add.w #16,a1
 move.b (a0)+,(a2)
 move.b (a0)+,8(a2)
 add.w #16,a2
 subq #1,d2
 bgt.s AmmoRise

 move.w Ammo,OldAmmo

 rts 


LessAmmo: 
 move.w OldAmmo,d2
 sub.w d0,d2
 
 move.w #63,d3
 sub.w OldAmmo,d3
 
 move.l #borders++5184+25*16+1,a1
 asl.w #5,d3
 add.w d3,a1
 lea 2592(a1),a2

AmmoDrain:
 move.b #0,(a1)
 move.b #0,8(a1)
 move.b #0,(a2)
 move.b #0,8(a2)
 add.w #16,a1
 add.w #16,a2
 move.b #0,(a1)
 move.b #0,8(a1)
 move.b #0,(a2)
 move.b #0,8(a2)
 add.w #16,a1
 add.w #16,a2
 subq #1,d2
 bgt.s AmmoDrain

 move.w Ammo,OldAmmo

 rts 

nulop:
 move.w #$0010,$dff000+intreq
 rte
 
doanything: dc.w 0
 
end:
; 	_break #0

 clr.b dosounds
 clr.b doanything

 move.w PLAYERONEHEALTH,Energy
 cmp.b #'s',mors
 bne.s .notsl
 move.w PLR2_energy,Energy
.notsl:

 
 move.l drawpt,d0
 move.l olddrawpt,drawpt
 move.l d0,olddrawpt
 move.l d0,$dff084


 cmp.b #'b',Prefsfile+3
 bne.s .noback
 jsr mt_end
.noback
 tst.w Energy
 bgt.s wevewon
 move.w #0,Energy
 bsr EnergyBar

 move.l #gameover,mt_data
 st UseAllChannels
 clr.b reachedend
 jsr mt_init
playgameover:
 move.l #$dff000,a6
waitfortop2:

	
 btst.b #0,intreqrl(a6)
 beq waitfortop2
 move.w #$1,intreq(a6)

	
 jsr mt_music


	
 tst.b reachedend
 beq.s playgameover
 
 bra wevelost
 
 
wevewon:
 bsr EnergyBar

 cmp.b #'n',mors
 bne.s .nonextlev
 add.w #1,MAXLEVEL
 st FINISHEDLEVEL
.nonextlev:

 move.l #welldone,mt_data
 st UseAllChannels
 clr.b reachedend
 jsr mt_init
playwelldone:
 move.l #$dff000,a6
waitfortop3:
 btst.b #0,intreqrl(a6)
 beq waitfortop3
 move.w #$1,intreq(a6)

 jsr mt_music

 tst.b reachedend
 beq.s playwelldone
 
wevelost:

 PROTICHECK a0

 jmp closeeverything 

endnomusic
 clr.b doanything
 cmp.b #'b',Prefsfile+3
 bne.s .noback
 jsr mt_end
.noback
*******************************
; cmp.b #'n',mors
; bne.s .nonextlev
; cmp.w #15,MAXLEVEL
; bge.s .nonextlev
; add.w #1,MAXLEVEL
; st FINISHEDLEVEL
;.nonextlev:
******************************

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

string:
	dc.b	'credits',0
 
ENDGAMESCROLL:

	move.l	4.w,a6
	move.l	#string,d1
	moveq	#0,d2
	moveq	#0,d3
	jsr	_LVOExecute(a6)

; include "endscroll.s"

***********************************
 include "ab3:source_4000/CD32JOY"


 
*************************************
* Set left and right clip values
*************************************
 
 

NEWsetlclip:
 move.l #OnScreen,a1
 move.l #Rotated,a2
 move.l CONNECT_TABLE,a3
 
 move.w (a0),d0
 bge.s .notignoreleft
 
; move.l #0,(a6)
 
 bra .leftnotoktoclip
.notignoreleft:

 move.w 6(a2,d0*8),d3	; left z val
 bgt.s .leftclipinfront
 addq #2,a0
 rts

 tst.w 6(a2,d0*8)
 bgt.s .leftnotoktoclip
.ignoreboth:
; move.l #0,(a6)
; move.l #96*65536,4(a6)
 move.w #0,leftclip
 move.w RIGHTX,rightclip
 addq #8,a6
 addq #2,a0
 rts

.leftclipinfront:
 move.w (a1,d0*2),d1	; left x on screen
 move.w (a0),d2
 move.w 2(a3,d2.w*4),d2
 move.w (a1,d2.w*2),d2
 cmp.w d1,d2
 bgt.s .leftnotoktoclip

; move.w d1,(a6)
; move.w d3,2(a6)
 cmp.w leftclip,d1
 ble.s .leftnotoktoclip
 move.w d1,leftclip
.leftnotoktoclip:

 addq #2,a0

 rts

NEWsetrclip
 move.l #OnScreen,a1
 move.l #Rotated,a2
 move.l CONNECT_TABLE,a3
 move.w (a0),d0
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
 move.w (a0),d2
 move.w (a3,d2.w*4),d2
 move.w (a1,d2.w*2),d2
 cmp.w d1,d2
 blt.s .rightnotoktoclip
; move.w d1,4(a6)
; move.w d4,6(a6)

 cmp.w rightclip,d1
 bge.s .rightnotoktoclip
 addq #1,d1
 move.w d1,rightclip
.rightnotoktoclip:
 addq #8,a6
 addq #2,a0
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
 move.w RIGHTX,rightclip
 move.w #0,leftclip
 addq #2,a0
 rts

.leftclipinfront:
 move.w (a1,d0*2),d1	; left x on screen
 cmp.w leftclip,d1
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
 addq #1,d1
 cmp.w rightclip,d1
 bge.s .rightnotoktoclip
 move.w d1,rightclip
.rightnotoktoclip:

; move.w leftclip,d0
; move.w rightclip,d1
; cmp.w d0,d1
; bge.s .noswap
; move.w #192,rightclip
; move.w #0,leftclip
;.noswap:

 rts


leftclip2: dc.w 0
rightclip2: dc.w 0
ZoneBright: dc.w 0
 
npolys: dc.w 0

PLR1_fire: dc.b 0
PLR2_fire: dc.b 0

*****************************************************


pastdata:
***********************************
* This routine animates brightnesses.

 
liftpt: dc.l liftanimtab

brightpt:
 dc.l brightanimtab


liftanim:
 rts

******************************
 include "ab3:source_4000/ObjectMove"
 include "ab3:source_4000/newAnims"
 include "ab3:source_4000/airoutine.s"
******************************
startpass:
; include "ab3:source_4000/password_reloc.s"
endpass:

rotanimpt: dc.w 0
xradd: dc.w 5
yradd: dc.w 8
xrpos: dc.w 320
yrpos: dc.w 320

rotanim:
 rts
 
option:
 dc.l 0,0

********** WALL STUFF *******************************

 include "AB3:source_4000/hireswall.s"
 include "AB3:source_4000/hiresgourwall.s"

*****************************************************

******************************************
* floor polygon

numsidestd: dc.w 0
bottomline: dc.w 0

checkforwater:
 tst.b usewater
 beq.s .notwater
 
 move.l Roompt,a1
 move.w (a1),d7
 cmp.w currzone,d7
 bne.s .notwater
 
 move.b #$f,fillscrnwater

.notwater:
 move.w (a0)+,d6	; sides-1
 add.w d6,d6
 add.w d6,a0
 add.w #4+6,a0
 rts

 rts

NewCornerBuff:
 ds.l 100
CLRNOFLOOR: dc.w 0

itsafloordraw:

* If D0 =1 then its a floor otherwise (=2) it's
* a roof.

 move.w #0,above
 move.w (a0)+,d6	; ypos of poly
 
 tst.b usewater
 beq.s .oknon
 tst.b DOANYWATER
 beq dontdrawreturn
.oknon
 
 move.w d6,d7
 ext.l d7
 asl.l #6,d7
 cmp.l TOPOFROOM,d7
 blt checkforwater
 cmp.l BOTOFROOM,d7
 bgt.s dontdrawreturn
 
 move.w leftclip,d7
 cmp.w rightclip,d7
 bge.s dontdrawreturn
 
 sub.w flooryoff,d6
 bgt.s below
 blt.s aboveplayer

 tst.b usewater
 beq.s .notwater
 
 move.l Roompt,a1
 move.w (a1),d7
 cmp.w currzone,d7
 
 bne.s .notwater
 
 st fillscrnwater

.notwater:
 
 
dontdrawreturn:
 move.w (a0)+,d6	; sides-1
 add.w d6,d6
 add.w d6,a0
 add.w #4+6,a0
 rts
aboveplayer:

 tst.b usewater
 beq.s .notwater
 
 move.l Roompt,a1
 move.w (a1),d7
 cmp.w currzone,d7
 bne.s .notwater
 
 move.b #$f,fillscrnwater

.notwater:

 btst #1,d0
 beq.s dontdrawreturn
 move.w MIDDLEY,d7
 sub.w topclip,d7 
 ble.s dontdrawreturn
 move.w #1,d0
 move.w d0,above
 neg.w d6
 bra.s notbelow
below:
 move.w botclip,d7
 sub.w MIDDLEY,d7
 ble.s dontdrawreturn
notbelow:
 btst #0,d0
 beq.s dontdrawreturn
 move.w d6,distaddr
 muls #64,d6
 move.l d6,ypos
 ext.l d7
 divs.l d7,d6		; zpos of bottom
			; visible line

 beq dontdrawreturn

 cmp.l #32767,d6
 bgt dontdrawreturn
			
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
 and.w #$fff,d0
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

 tst.b gourfloor
 bne goursides

 move.w #300,top
 move.w #-1,bottom
 move.w #0,drawit
 move.l #Rotated,a1
 move.l #OnScreen,a2
 move.w (a0)+,d7	; no of sides
sideloop:
 move.w minz,d6
 move.w (a0)+,d1
 move.w (a0),d3
 and.w #$fff,d1
 and.w #$fff,d3

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
 add.w MIDDLEX,d0
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
 add.w MIDDLEX,d2
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
 bra pastsides
 
fbr: dc.w 0
sbr: dc.w 0
FloorPtBrights: dc.l 0

goursides:

 move.w #300,top
 move.w #-1,bottom
 move.w #0,drawit
 move.l #Rotated,a1
 move.l #OnScreen,a2
 move.w (a0)+,d7	; no of sides
sideloopGOUR:
 move.w minz,d6
 move.w (a0)+,d1
 move.w (a0),d3
 
 move.w d1,d4
 move.w d3,d5
 and.w #$0fff,d1
 and.w #$0fff,d3
 
 rol.w #4,d4
 rol.w #4,d5
 and.w #$f,d4
 and.w #$f,d5

 move.l FloorPtBrights,a4
 move.w (a4,d4.w*8),d4
 bge.s .okpos1
 neg.w d4
.okpos1:
 sub.w #300,d4
 move.w d4,fbr
 move.w (a4,d5.w*8),d4
 bge.s .okpos2
 neg.w d4
.okpos2:
 sub.w #300,d4
 move.w d4,sbr
 
 move.w 6(a1,d1*8),d4	;first z
 cmp.w d6,d4
 bgt firstinfrontGOUR
 move.w 6(a1,d3*8),d5	; sec z
 cmp.w d6,d5
 ble bothbehindGOUR
** line must be on left and partially behind.
 sub.w d5,d4
 
 move.w fbr,d0
 sub.w sbr,d0
 sub.w d5,d6
 muls d6,d0
 divs d4,d0
 add.w sbr,d0
 move.w d0,fbr
 
 move.l (a1,d1*8),d0
 sub.l (a1,d3*8),d0
 asr.l #7,d0
 muls d6,d0	; new x coord
 divs d4,d0
 ext.l d0
 asl.l #7,d0

 add.l (a1,d3*8),d0
 move.w minz,d4
 move.w (a2,d3*2),d2
 divs d4,d0
 add.w MIDDLEX,d0
 move.l ypos,d3
 divs d5,d3
 
 move.w bottomline,d1 
 bra lineclippedGOUR

firstinfrontGOUR:
 move.w 6(a1,d3*8),d5	; sec z
 cmp.w d6,d5
 bgt bothinfrontGOUR
** line must be on right and partially behind.
 sub.w d4,d5	; dz

 move.w sbr,d2
 sub.w fbr,d2
 sub.w d4,d6
 muls d6,d2
 divs d5,d2
 add.w fbr,d2
 move.w d2,sbr

 move.l (a1,d3*8),d2
 sub.l (a1,d1*8),d2	; dx
 asr.l #7,d2
 muls d6,d2	; new x coord
 divs d5,d2
 ext.l d2
 asl.l #7,d2
 add.l (a1,d1*8),d2
 move.w minz,d5
 move.w (a2,d1*2),d0
 divs d5,d2
 add.w MIDDLEX,d2
 move.l ypos,d1
 divs d4,d1
 move.w bottomline,d3 
 bra lineclippedGOUR

bothinfrontGOUR:

* Also, usefully enough, both are on-screen
* so no bottom clipping is needed.

 move.w (a2,d1*2),d0	; first x
 move.w (a2,d3*2),d2	; second x
 move.l ypos,d1
 move.l d1,d3
 divs d4,d1		; first y
 divs d5,d3		; second y
lineclippedGOUR:
 move.l #rightsidetab,a3
 cmp.w d1,d3
 bne linenotflatGOUR
 
; move.w fbr,d4
; move.w sbr,d5
; cmp.w d0,d2
; bgt.s .nsw
; exg d4,d5
;.nsw:

; move.l #leftbrighttab,a3
; move.w d4,(a3,d3.w)
; move.l #rightbrighttab,a3
; move.w d5,(a3,d3.w) 
 bra lineflatGOUR
 
linenotflatGOUR
 st drawit
 bgt lineonrightGOUR
 move.l #leftsidetab,a3
 exg d1,d3
 exg d0,d2
 
 lea (a3,d1*2),a3
 lea leftbrighttab-leftsidetab(a3),a4
 
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

 ext.l d2
 divs d3,d2
 move.w d2,d6
 swap d2
 move.w d2,a5

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
 move.w d1,a6

 moveq #0,d1
 move.w sbr,d1
 move.w fbr,d2
 sub.w d1,d2
 ext.l d2
 asl.w #8,d2
 asl.w #2,d2
 divs d3,d2 
 ext.l d2
 asl.l #6,d2
 swap d1
 
.pixlopright:
 move.w d0,(a3)+
 swap d1
 move.w d1,(a4)+
 swap d1
 add.l d2,d1

 sub.w a5,d4
 bge.s .nobigstep
 add.w a6,d0
 add.w d3,d4
 dbra d5,.pixlopright
 bra lineflatGOUR
.nobigstep

 add.w d6,d0
 dbra d5,.pixlopright
 bra lineflatGOUR

.linegoingleft:

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
 move.w d1,a6
 move.w d2,a5

 moveq #0,d1
 move.w sbr,d1
 move.w fbr,d2
 sub.w d1,d2
 ext.l d2
 asl.w #8,d2
 asl.w #2,d2
 divs d3,d2 
 ext.l d2
 asl.l #6,d2
 swap d1

.pixlopleft:

 swap d1
 move.w d1,(a4)+
 swap d1
 add.l d2,d1

 sub.w a5,d4
 bge.s .nobigstepl
 sub.w a6,d0
 add.w d3,d4
 move.w d0,(a3)+
 dbra d5,.pixlopleft
 bra lineflatGOUR
 
.nobigstepl
 sub.w d6,d0
 move.w d0,(a3)+
 dbra d5,.pixlopleft
 bra lineflatGOUR
 
lineonrightGOUR:

 lea (a3,d1*2),a3
 
 lea rightbrighttab-rightsidetab(a3),a4
 
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

 move.w d1,a6
 move.w d2,a5

 moveq #0,d1
 move.w fbr,d1
 move.w sbr,d2
 sub.w d1,d2
 ext.l d2
 asl.w #8,d2
 asl.w #2,d2
 divs d3,d2 
 ext.l d2
 asl.l #6,d2
 swap d1

.pixlopright:

 swap d1
 move.w d1,(a4)+
 swap d1
 add.l d2,d1

 sub.w a5,d4
 bge.s .nobigstep
 add.w a6,d0
 add.w d3,d4
 move.w d0,(a3)+
 dbra d5,.pixlopright
 bra lineflatGOUR
 
.nobigstep
 add.w d6,d0
 move.w d0,(a3)+
 dbra d5,.pixlopright
 bra lineflatGOUR

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
 move.w d1,a6
 move.w d2,a5

 moveq #0,d1
 move.w fbr,d1
 move.w sbr,d2
 sub.w d1,d2
 ext.l d2
 asl.w #8,d2
 asl.w #2,d2
 divs d3,d2 
 ext.l d2
 asl.l #6,d2
 swap d1

.pixlopleft:

 swap d1
 move.w d1,(a4)+
 swap d1
 add.l d2,d1

 move.w d0,(a3)+
 sub.w a5,d4
 bge.s .nobigstepl
 sub.w a6,d0
 add.w d3,d4
 dbra d5,.pixlopleft
 bra lineflatGOUR
 
.nobigstepl
 sub.w d6,d0
 dbra d5,.pixlopleft

lineflatGOUR:
 
bothbehindGOUR:
 dbra d7,sideloopGOUR
 
pastsides:

 addq #2,a0
 
 move.w #320,linedir
 
; move.l FASTBUFFER2,a6
; add.l BIGMIDDLEY,a6
; move.l a6,REFPTR
 
 move.l FASTBUFFER,a6
 add.l BIGMIDDLEY,a6
 move.w (a0)+,d6
 add.w SMALLIT,d6
 move.w d6,scaleval
 move.w (a0)+,whichtile
 move.w (a0)+,d6
 add.w ZoneBright,d6
 move.w d6,lighttype
 move.w above(pc),d6
 beq groundfloor
* on ceiling:
 move.w #-320,linedir
 suba.w #320,a6
groundfloor:

 move.w xoff,d6
 move.w zoff,d7
 add.w xwobxoff,d7
 add.w xwobzoff,d6
 ext.l d6
 ext.l d7
 
 tst.b FULLSCR
 beq.s .shiftit
 
 asl.l #2,d6
 asl.l #2,d7
 divs #3,d6
 divs #3,d7
 swap d6
 swap d7
 clr.w d6
 clr.w d7
 asr.l #2,d6
 asr.l #2,d7
 bra.s .donsht

.shiftit
 
; divs #3,d6
; divs #3,d7
 swap d6
 swap d7
 clr.w d6
 clr.w d7
 asr.l #1,d6
 asr.l #1,d7
.donsht:
 move.w scaleval(pc),d3
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
 move.l d6,sxoff
 move.l d7,szoff
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
 
minz: dc.l 0

leftsidetab:
 ds.w 512*2
rightsidetab:
 ds.w 512*2
leftbrighttab:
 ds.w 512*2
rightbrighttab:
 ds.w 512*2
 
PointBrights:
 dc.l 0
CurrentPointBrights:
 ds.l 2*256*10

movespd: dc.w 0
largespd: dc.l 0
disttobot: dc.w 0

pastscale:


 tst.b drawit(pc)
 beq dontdrawfloor

 tst.b DOUBLEHEIGHT
 beq pix1h
 
 move.l a0,-(a7)
 move.w linedir,d1
 add.w d1,linedir

 move.l #leftsidetab,a4
 move.w top(pc),d1
 tst.w above
 beq.s .clipfloor
 
 sub.w #320,a6
 
 move.w MIDDLEY,d7
 subq #1,d7
 sub.w d1,d7
 move.w d7,disttobot
 
 move.w bottom(pc),d7
 move.w MIDDLEY,d3
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
 blt .doneclip
 move.w d3,d7
 bra .doneclip
 
.clipfloor:
 move.w BOTTOMY,d7
 sub.w MIDDLEY,d7
 subq #1,d7
 sub.w d1,d7
 move.w d7,disttobot
 
 move.w bottom(pc),d7
 move.w botclip,d4
 sub.w MIDDLEY,d4
 cmp.w d4,d1
 bge predontdrawfloor
 move.w topclip,d3
 sub.w MIDDLEY,d3
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

.doneclip:

 lea (a4,d1*2),a4
 addq #1,d7
 sub.w d1,d7

;moveq #0,d0
 asr.w #1,d1
; addx d0,d1
 
; move.l #dists,a2
 move.w distaddr,d0
 muls #64,d0
 move.l d0,a2
; muls #25,d0
; adda.w d0,a2
; lea (a2,d1*2),a2
 asr.w #1,d7
 ble predontdrawfloor 
 move.w d1,d0
 bne.s .notzero
 moveq #1,d0
.notzero
 add.w d0,d0
 muls linedir,d1
 add.l d1,a6
; sub.l d1,REFPTR
 move.l #floorscalecols,a1
 move.l LineToUse,a5
 
 move.w #4,tonextline
 
 bra pix2h
 
pix1h:

 move.l a0,-(a7)

 move.l #leftsidetab,a4
 move.w top(pc),d1
  
 tst.w above
 beq.s clipfloor
 
 move.w MIDDLEY,d7
 subq #1,d7
 sub.w d1,d7
 move.w d7,disttobot
 
 move.w bottom(pc),d7
 move.w MIDDLEY,d3
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
 move.w BOTTOMY,d7
 sub.w MIDDLEY,d7
 subq #1,d7
 sub.w d1,d7
 move.w d7,disttobot
 
 move.w bottom(pc),d7
 move.w botclip,d4
 sub.w MIDDLEY,d4
 cmp.w d4,d1
 bge predontdrawfloor
 move.w topclip,d3
 sub.w MIDDLEY,d3
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
; sub.l d1,REFPTR
 move.l #floorscalecols,a1
 move.l LineToUse,a5
 
 move.w #2,tonextline
 
pix2h:
 
 tst.b gourfloor
 bne dogourfloor
 
 tst.b anyclipping
 beq dofloornoclip
 
dofloor:
; move.w (a2)+,d0
 move.w leftclip,d3
 move.w rightclip,d4
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
 
; moveq #0,d1
; moveq #0,d3
; move.w leftbrighttab-leftsidetab(a4),d1
; bge.s .okbl
; moveq #0,d1
;.okbl:
 
; move.w rightbrighttab-leftsidetab(a4),d3
; bge.s .okbr
; moveq #0,d3
;.okbr:
 
; sub.w d1,d3
; asl.w #8,d1
; move.l d1,leftbright
; swap d3
; asr.l #5,d3
; divs d5,d3
; move.w d3,d5
; muls.w d6,d5
; asr.l #3,d5
; clr.b d5
; add.w d5,leftbright+2
 
; ext.l d3
; asl.l #5,d3
; swap d3
; asl.w #8,d3
; move.l d3,brightspd
 
 move.l a6,a3
 movem.l d0/d7/a2/a4/a5/a6,-(a7)
 move.l a2,d7
 asl.l #2,d7
 ext.l d0
 divs.l d0,d7
 move.l d7,d0
 jsr (a5)
 movem.l (a7)+,d0/d7/a2/a4/a5/a6
nodrawline
 sub.w #1,disttobot
 move.w linedir(pc),d3
 adda.w d3,a6
; ext.l d3
; sub.l d3,REFPTR
 move.w tonextline,d3
 add.w d3,a4
 asr.w #1,d3
 add.w d3,d0
 subq #1,d7
 bgt dofloor

predontdrawfloor
 move.l (a7)+,a0

dontdrawfloor:

 rts

tonextline: dc.w 0
anyclipping: dc.w 0

dofloornoclip:
; move.w (a2)+,d0
 move.w rightsidetab-leftsidetab(a4),d2
 addq #1,d2
 move.w (a4),d1
 move.w d1,leftedge
 move.w d2,rightedge

; sub.w d1,d2

; moveq #0,d1
; moveq #0,d3
; move.w leftbrighttab-leftsidetab(a4),d1
; bge.s .okbl
; moveq #0,d1
;.okbl:
 
; move.w rightbrighttab-leftsidetab(a4),d3
; bge.s .okbr
; moveq #0,d3
;.okbr:
 
; sub.w d1,d3
; asl.w #8,d1
; move.l d1,leftbright
; swap d3
; asr.l #5,d3
; divs d2,d3
; ext.l d3
; asl.l #5,d3
; swap d3
; asl.w #8,d3
; move.l d3,brightspd

 move.l a6,a3
 movem.l d0/d7/a2/a4/a5/a6,-(a7)
 move.l a2,d7
 asl.l #2,d7
 ext.l d0
 divs.l d0,d7
 move.l d7,d0
 jsr (a5)
 movem.l (a7)+,d0/d7/a2/a4/a5/a6
 sub.w #1,disttobot
 move.w linedir(pc),d3
 adda.w d3,a6
; ext.l d3
; sub.l d3,REFPTR
 move.w tonextline,d3
 add.w d3,a4
 asr.w #1,d3
 add.w d3,d0
 subq #1,d7
 bgt dofloornoclip

 bra predontdrawfloor

dogourfloor:
 tst.b anyclipping
 beq dofloornoclipGOUR
 
dofloorGOUR:
; move.w (a2)+,d0
 move.w leftclip,d3
 move.w rightclip,d4
 move.w rightsidetab-leftsidetab(a4),d2

 move.w d2,d5
 sub.w (a4),d5
 addq #1,d5
 moveq #0,d6
 
 addq #1,d2
 cmp.w d3,d2
 ble nodrawlineGOUR
 cmp.w d4,d2
 ble.s nocliprightGOUR
 move.w d4,d2
nocliprightGOUR:
 move.w (a4),d1
 cmp.w d4,d1
 bge nodrawlineGOUR
 cmp.w d3,d1
 bge.s noclipleftGOUR
 move.w d3,d6
 subq #1,d6
 sub.w d1,d6
 move.w d3,d1
noclipleftGOUR:
 cmp.w d1,d2
 ble nodrawlineGOUR

 move.w d1,leftedge
 move.w d2,rightedge

 move.l a2,d2
 asl.l #2,d2
 ext.l d0
 divs.l d0,d2
 move.l d2,dst
 asr.l #7,d2
 asr.l #2,d2
; addq #5,d2
; add.w lighttype,d2
 
 moveq #0,d1
 moveq #0,d3
 move.w leftbrighttab-leftsidetab(a4),d1
 add.w d2,d1
 bge.s .okbl
 moveq #0,d1
.okbl:
; asr.w #1,d1
 cmp.w #31,d1
 ble.s .okdl
 move.w #31,d1
.okdl:
 
 move.w rightbrighttab-leftsidetab(a4),d3
 add.w d2,d3
 bge.s .okbr
 moveq #0,d3
.okbr:
; asr.w #1,d3
 cmp.w #31,d3
 ble.s .okdr
 move.w #31,d3
.okdr:
 
 sub.w d1,d3
 asl.w #8,d1
 move.w d1,leftbright
 swap d3
 tst.l d3
 bgt.s .OKITSPOSALREADY 
 neg.l d3
 asr.l #6,d3
 divs d5,d3
 neg.w d3
 bra.s .OKNOWITSNEG
 
.OKITSPOSALREADY
 asr.l #6,d3
 divs d5,d3
.OKNOWITSNEG
 muls d3,d6
 add.w #256*4,d6
 asr.w #2,d6
 clr.b d6
 add.w leftbright,d6
 bge.s .oklbnn
 moveq #0,d6
.oklbnn:
 move.w d6,leftbright
 
 ext.l d3
 asr.l #2,d3
; swap d3
; asl.w #8,d3
 move.w d3,brightspd
 
 move.l a6,a3
 movem.l d0/d7/a2/a4/a5/a6,-(a7)
 move.l dst,d0
 lea floorscalecols,a1
 move.l floortile,a0
 adda.w whichtile,a0
 jsr pastfloorbright
 movem.l (a7)+,d0/d7/a2/a4/a5/a6
nodrawlineGOUR

 sub.w #1,disttobot

 move.w linedir(pc),d3
 adda.w d3,a6
; ext.l d3
; sub.l d3,REFPTR
 move.w tonextline,d3
 add.w d3,a4
 asr.w #1,d3
 add.w d3,d0
 subq #1,d7
 bgt dofloorGOUR

predontdrawfloorGOUR
 move.l (a7)+,a0

dontdrawfloorGOUR:

 rts

REFPTR: dc.l 0

dofloornoclipGOUR:
; move.w (a2)+,d0
 move.w rightsidetab-leftsidetab(a4),d2
 addq #1,d2
 move.w (a4),d1
 move.w d1,leftedge
 move.w d2,rightedge

 sub.w d1,d2

 move.l a2,d6
 asl.l #2,d6
 ext.l d0
 divs.l d0,d6
 move.l d6,d5
 asr.l #7,d5
 asr.l #2,d5
; addq #5,d5
; add.w lighttype,d5

 moveq #0,d1
 moveq #0,d3
 move.w leftbrighttab-leftsidetab(a4),d1
 add.w d5,d1
 bge.s .okbl
 moveq #0,d1
.okbl:
; asr.w #1,d1
 cmp.w #31,d1
 ble.s .okdl
 move.w #31,d1
.okdl:
 
 move.w rightbrighttab-leftsidetab(a4),d3
 add.w d5,d3
 bge.s .okbr
 moveq #0,d3
.okbr:
; asr.w #1,d3
 cmp.w #31,d3
 ble.s .okdr
 move.w #31,d3
.okdr:
 
; sub.w d1,d3
; asl.w #8,d1
; move.l d1,leftbright
; swap d3
; asr.l #5,d3
; divs d2,d3
; ext.l d3
; asl.l #5,d3
; swap d3
; asl.w #8,d3
; move.l d3,brightspd

 sub.w d1,d3
 asl.w #8,d1
 move.w d1,leftbright
 swap d3
 ext.l d2
 divs.l d2,d3
 asr.l #8,d3
 move.w d3,brightspd

 move.l a6,a3
 movem.l d0/d7/a2/a4/a5/a6,-(a7)
 move.l d6,d0
 move.l d0,dst
 lea floorscalecols,a1
 move.l floortile,a0
 adda.w whichtile,a0
 jsr pastfloorbright
 movem.l (a7)+,d0/d7/a2/a4/a5/a6
 sub.w #1,disttobot

 move.w linedir(pc),d3
 adda.w d3,a6
; ext.l d3
; sub.l d3,REFPTR

 move.w tonextline,d3
 add.w d3,a4
 asr.w #1,d3
 add.w d3,d0
 subq #1,d7
 bgt dofloornoclipGOUR

 bra predontdrawfloorGOUR



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

BLACKFLOOR:
 moveq #0,d0
 bra.s DOBLACK

SimpleFloorLine:

 CACHE_OFF d2

 move.l #doacrossline,a1
 move.w leftedge(pc),d1
 move.w rightedge(pc),d3
 sub.w d1,d3
 lea (a1,d1.w*4),a1
 move.w (a1,d3.w*4),d4
 move.w #$4e75,(a1,d3.w*4)

 tst.b CLRNOFLOOR
 bne.s BLACKFLOOR

 move.l #PLAINSCALE,a2
 
 move.w d0,d2
 move.w lighttype,d1
 asr.w #8,d2
 add.w #5,d1
 add.w d2,d1
 bge.s .fixedbright
 moveq #0,d1
.fixedbright:
 cmp.w #28,d1
 ble.s .smallbright
 move.w #28,d1
.smallbright:
 lea (a2,d1.w*2),a2
 
 move.w whichtile,d0
 move.w d0,d1
 and.w #$3,d1
 and.w #$300,d0
 lsl.b #6,d1
 move.b d1,d0
 move.w d0,tstwhich
 move.w (a2,d0.w),d0
 
DOBLACK:
 jsr (a1)
 move.w d4,(a1,d3.w*4)

 CACHE_ON d2

 rts
 
tstwhich: dc.w 0
whichtile: dc.w 0
  
PLAINSCALE: incbin "ab3:includes/plainscale"
  
storeit: dc.l 0

doacrossline:
val SET 0
 REPT 32
 move.w d0,val(a3)
val SET val+4
 ENDR
val SET val+4
 REPT 32
 move.w d0,val(a3)
val SET val+4
 ENDR
val SET val+4
 REPT 32
 move.w d0,val(a3)
val SET val+4
 ENDR
 rts


leftedge: dc.w 0
rightedge: dc.w 0

rndpt: dc.l rndtab


dst: dc.l 0

FloorLine:

 move.l floortile,a0
 adda.w whichtile,a0
 move.w lighttype,d1
 move.l d0,dst	; *4
 move.l d0,d2	; *4
*********************
* Old version
 asr.l #2,d2
 asr.l #8,d2
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
 
 move.l d0,dst
 
 move.l d0,d2
*********************
* Old version
 asr.l #2,d2
 asr.l #8,d2
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
 cmp.w #31,d1
 ble.s .smallbright
 move.w #31,d1
.smallbright:
 add.l floorbright(pc,d1.w*4),a1
 bra pastfloorbright
 

floorbright:
 dc.l 512*0
 dc.l 512*1
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
 dc.l 512*16
 dc.l 512*17
 dc.l 512*18
 dc.l 512*19
 
 dc.l 512*20
 dc.l 512*21
 dc.l 512*22
 dc.l 512*23
 dc.l 512*24
 
 dc.l 512*25
 dc.l 512*26
 dc.l 512*27
 dc.l 512*28
 dc.l 512*29

 dc.l 512*30
 dc.l 512*31

widthleft: dc.w 0
scaleval: dc.w 0
sxoff: dc.l 0
szoff: dc.l 0
xoff34: dc.w 0
zoff34: dc.w 0
scosval: dc.w 0
ssinval: dc.w 0


floorsetbright:
 move.l #walltiles,a0

pastfloorbright:
 
 move.l d0,d1
 muls cosval,d1	; change in x across whole width
 move.l d0,d2
 muls sinval,d2	; change in z across whole width
 neg.l d2
 asr.l #2,d2
 asr.l #2,d1
scaleprog:
 move.w scaleval(pc),d3
 beq.s .samescale
 bgt.s .scaledown
 neg.w d3
 asr.l d3,d1
 asr.l d3,d2
 bra.s .samescale
.scaledown:
 asl.l d3,d1
 asl.l d3,d2
.samescale


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
 
 add.l sxoff,d4
 add.l szoff,d5
 
 tst.b FULLSCR
 beq.s .nob

 moveq #0,d6
 move.w leftedge(pc),d6
 beq.s .nomultleftB

 add.l d6,d6
 divs #3,d6
 ext.l d6
 
 move.l d1,a4
 move.l d2,a5
 
 muls.l d6,d1
 asr.l #7,d1
 add.l d1,d4

 muls.l d6,d2
 asr.l #7,d2
 add.l d2,d5
 move.l a4,d1
 move.l a5,d2
 
 move.w leftedge(pc),d6
 
.nomultleftB:

 move.w d4,startsmoothx
 move.w d5,startsmoothz

 asr.l #8,d4
 asl.l #8,d5
; add.w szoff,d5
; add.w sxoff,d4
; and.w #63,d4
; and.w #63*256,d5

 move.w d4,d5

 asr.l #6,d1
 asr.l #6,d2
 divs.l #3,d1
 divs.l #3,d2
 
 bra.s doneallmult
 
.nob 

 moveq #0,d6
 move.w leftedge(pc),d6
 beq.s nomultleft
 
 move.l d1,a4
 move.l d2,a5
 
 muls.l d6,d1
 asr.l #7,d1
 add.l d1,d4

 muls.l d6,d2
 asr.l #7,d2
 add.l d2,d5
 move.l a4,d1
 move.l a5,d2
 
 move.w leftedge(pc),d6
 
nomultleft:

 move.w d4,startsmoothx
 move.w d5,startsmoothz

 asr.l #8,d4
 asl.l #8,d5
; add.w szoff,d5
; add.w sxoff,d4
; and.w #63,d4
; and.w #63*256,d5

 move.w d4,d5

 asr.l #7,d1
 asr.l #7,d2
; divs.l #3,d1
; divs.l #3,d2

doneallmult:

 move.w d1,a4
 move.w d2,a5
 asl.l #8,d2
; and.w #%0011111100000000,d2
 asr.l #8,d1
 move.w d1,d2
 move.l #$3fff3fff,d1
 and.l d1,d5
; swap d5
; move.w startsmoothz,d5
; swap d5
; swap d2
; move.w a5,d2
; swap d2
 
***********************************
 
 tst.b DOUBLEWIDTH
 beq.s .nodoub
 
 and.b #$fe,d6
 
 move.w d6,a2
 moveq #0,d0 
 move.w rightedge(pc),d3 
 lea (a3,a2.w),a3 
 move.w d3,d7
 sub.w a2,d7
 asr.w #1,d7
 move.w startsmoothx,d3

 tst.b usewater
 bne texturedwaterDOUB
; tst.b gourfloor
 bra gouraudfloorDOUB
 
.nodoub:
 
 move.w d6,a2
 moveq #0,d0 
 move.w rightedge(pc),d3 
 lea (a3,a2.w),a3 
 move.w d3,d7
 sub.w a2,d7
 
intofirststrip:
allintofirst:

 move.w startsmoothx,d3

tstwat:

 tst.b usewater
 bne texturedwater
; tst.b gourfloor
 bra gouraudfloor


 
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
gourfloor: dc.w 0
 
 include "ab3:source_4000/bumpmap.s"

 CNOP 0,4
backbefore:
 and.w d1,d5
 move.b (a0,d5.w*4),d0
 add.w a4,d3
 addx.l d6,d5
 move.w (a1,d0.w*2),(a3)
 addq #4,a3
 dbcs d7,acrossscrn
 dbcc d7,backbefore
 bra.s past1
 
acrossscrn:
 and.w d1,d5
 move.b (a0,d5.w*4),d0
 add.w a4,d3
 addx.l d2,d5
 move.w (a1,d0.w*2),(a3)
 addq #4,a3
 dbcs d7,acrossscrn
 dbcc d7,backbefore
past1:
 bcc.s gotoacross

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
 
 dbra d7,backbefore
 rts


gotoacross:

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
 
 dbra d7,acrossscrn
 rts

leftbright: dc.l 0
brightspd: dc.l 0

gouraudfloor:

 move.w leftbright,d0
 move.l d1,d4
 move.w brightspd,d1
 
 move.w d7,d3
 asr.w #1,d7
 btst #0,d3
 beq.s .nosingle1
 move.w d5,d3
 move.l d5,d6
 lsr.w #8,d3
 swap d6
 move.b d3,d6
 move.w d0,d3
 move.b (a0,d6.w*4),d3
 add.w d1,d0
 add.l d2,d5
 and.l d4,d5
 move.b (a1,d3.w*2),(a3)+
.nosingle1

 move.w d7,d3
 asr.w #1,d7
 btst #0,d3
 beq.s .nosingle2
 move.w d5,d3
 move.l d5,d6
 lsr.w #8,d3
 swap d6
 move.b d3,d6
 move.w d0,d3
 move.b (a0,d6.w*4),d3
 add.w d1,d0
 add.l d2,d5
 and.l d4,d5
 move.l d5,d6
 swap d6
 move.b (a1,d3.w*2),(a3)+
 move.w d5,d3
 lsr.w #8,d3
 move.b d3,d6
 move.w d0,d3
 move.b (a0,d6.w*4),d3
 add.w d1,d0
 add.l d2,d5
 and.l d4,d5
 move.b (a1,d3.w*2),(a3)+

.nosingle2
 
 move.l d5,d6
 swap d6
 
 dbra d7,acrossscrngour
 rts

 CNOP 0,4
 
acrossscrngour:
 move.w d5,d3
 lsr.w #8,d3
 move.b d3,d6
 move.w d0,d3
 move.b (a0,d6.w*4),d3
 add.w d1,d0
 add.l d2,d5
 and.l d4,d5
 move.l d5,d6
 swap d6
 move.b (a1,d3.w*2),(a3)+
 move.w d5,d3
 lsr.w #8,d3
 move.b d3,d6
 move.w d0,d3
 move.b (a0,d6.w*4),d3
 add.w d1,d0
 add.l d2,d5
 and.l d4,d5
 move.l d5,d6
 swap d6
 move.b (a1,d3.w*2),(a3)+
 move.w d5,d3
 lsr.w #8,d3
 move.b d3,d6
 move.w d0,d3
 move.b (a0,d6.w*4),d3
 add.w d1,d0
 add.l d2,d5
 and.l d4,d5
 move.l d5,d6
 swap d6
 move.b (a1,d3.w*2),(a3)+
 move.w d5,d3
 lsr.w #8,d3
 move.b d3,d6
 move.w d0,d3
 move.b (a0,d6.w*4),d3
 add.w d1,d0
 add.l d2,d5
 and.l d4,d5
 move.l d5,d6
 swap d6
 move.b (a1,d3.w*2),(a3)+
 dbra d7,acrossscrngour

 rts
 
 
gouraudfloorDOUB:

 move.w leftbright,d0
 move.l d1,d4
 move.w brightspd,d1
 add.w d1,d1
 add.l d2,d2
 
 move.w d7,d3
 asr.w #1,d7
 btst #0,d3
 beq.s .nosingle1
 move.w d5,d3
 move.l d5,d6
 lsr.w #8,d3
 swap d6
 move.b d3,d6
 move.w d0,d3
 move.b (a0,d6.w*4),d3
 add.w d1,d0
 add.l d2,d5
 and.l d4,d5
 move.w (a1,d3.w*2),(a3)+
.nosingle1

 move.w d7,d3
 asr.w #1,d7
 btst #0,d3
 beq.s .nosingle2
 move.w d5,d3
 move.l d5,d6
 lsr.w #8,d3
 swap d6
 move.b d3,d6
 move.w d0,d3
 move.b (a0,d6.w*4),d3
 add.w d1,d0
 add.l d2,d5
 and.l d4,d5
 move.l d5,d6
 swap d6
 move.w (a1,d3.w*2),(a3)+
 move.w d5,d3
 lsr.w #8,d3
 move.b d3,d6
 move.w d0,d3
 move.b (a0,d6.w*4),d3
 add.w d1,d0
 add.l d2,d5
 and.l d4,d5
 move.w (a1,d3.w*2),(a3)+

.nosingle2
 
 move.l d5,d6
 swap d6
 
 dbra d7,acrossscrngourD
 rts

 CNOP 0,4
 
acrossscrngourD:
 move.w d5,d3
 lsr.w #8,d3
 move.b d3,d6
 move.w d0,d3
 move.b (a0,d6.w*4),d3
 add.w d1,d0
 add.l d2,d5
 and.l d4,d5
 move.l d5,d6
 swap d6
 move.w (a1,d3.w*2),(a3)+
 move.w d5,d3
 lsr.w #8,d3
 move.b d3,d6
 move.w d0,d3
 move.b (a0,d6.w*4),d3
 add.w d1,d0
 add.l d2,d5
 and.l d4,d5
 move.l d5,d6
 swap d6
 move.w (a1,d3.w*2),(a3)+
 move.w d5,d3
 lsr.w #8,d3
 move.b d3,d6
 move.w d0,d3
 move.b (a0,d6.w*4),d3
 add.w d1,d0
 add.l d2,d5
 and.l d4,d5
 move.l d5,d6
 swap d6
 move.w (a1,d3.w*2),(a3)+
 move.w d5,d3
 lsr.w #8,d3
 move.b d3,d6
 move.w d0,d3
 move.b (a0,d6.w*4),d3
 add.w d1,d0
 add.l d2,d5
 and.l d4,d5
 move.l d5,d6
 swap d6
 move.w (a1,d3.w*2),(a3)+
 dbra d7,acrossscrngourD

 rts

 
;backbeforegour:
; and.w #63*256+63,d5
; move.b (a0,d5.w*4),d0
; add.l d1,d0
; bcc.s .nomoreb
; add.w #256,d0
;.nomoreb:
; add.w a4,d3
; move.w (a1,d0.w*2),(a3)+
; addx.l d6,d5
; dbcs d7,acrossscrngour
; dbcc d7,backbeforegour
; rts
; bra.s past1gour
 
;acrossscrngour:
; and.l #$3f3f,d5 
; move.b (a0,d5.w*4),d0
; add.l d1,d0
; bcc.s .nomoreb
; add.w #256,d0
;.nomoreb:
; add.w a4,d3
; move.w (a1,d0.w*2),(a3)+
; addx.l d2,d5
; dbcs d7,acrossscrngour
; dbcc d7,backbeforegour
;past1gour:
; rts

 move.w d4,d7
 bne.s .notdoneyet
 move.l d0,leftbright
 
 rts
.notdoneyet:

 cmp.w #32,d7
 ble.s .notoowide
 move.w #32,d7
.notoowide
 sub.w d7,d4  
 addq #4,a3
 
; dbra d7,backbeforegour
 rts


gotoacrossgour:

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
 
 dbra d7,acrossscrngour
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
wateroff: dc.l 0
 
REFLECTIONWATER:

 move.l d1,d4

 add.l wateroff,d5

 move.l #brightentab,a1
 move.l dst,d0
 clr.b d0
 
 add.w d0,d0
 cmp.w #12*512,d0
 blt.s .notoowater
 move.w #12*512,d0
 
.notoowater:
  
 adda.w d0,a1

 move.l dst,d0
 asl.w #7,d0
 add.w wtan,d0
 and.w #8191,d0
 move.l #SineTable,a0
 move.w (a0,d0.w),d0
 ext.l d0
 
 move.l dst,d3
 add.w #300,d3
 divs d3,d0
 asr.w #5,d0
 addq #4,d0
 cmp.w disttobot,d0
 blt.s oknotoffbotototr

 move.w disttobot,d0
 subq #1,d0

oknotoffbotototr
 
; move.w dst,d3
; asr.w #7,d3
; add.w d3,d0
 
 muls #320,d0
 tst.w above
 beq.s nonnnnnegr
 neg.l d0

nonnnnnegr:
 
 move.l d0,a6

 move.l watertouse,a0

; move.l #mixtab,a5
 
 moveq #0,d1

 move.w startsmoothx,d3
 dbra d7,acrossscrnwr
 rts

backbeforewr:
 and.w d1,d5 
 move.w (a0,d5.w*4),d0
 move.b (a3,a6.w),d0
 move.w (a1,d0.w*2),(a3)+
 add.w a4,d3
 addx.l d6,d5
 dbcs d7,acrossscrnwr
 dbcc d7,backbeforewr
 rts
 
acrossscrnwr:
 move.w d5,d3
 move.l d5,d6
 lsr.w #8,d3
 swap d6
 move.b d3,d6
 move.w (a0,d6.w*4),d0
 add.l d2,d5
 move.w (a4,a6.w),d1
 addq #2,a4
 move.b (a3,a6.w),d1
 move.b (a5,d1.l),d0
 and.l d4,d5
 move.w (a1,d0.w*2),(a3)+
 dbra d7,acrossscrnwr
 rts
 
texturedwater:

 move.l d1,d4

 add.l wateroff,d5

 move.l #brightentab,a1
 move.l dst,d0
 clr.b d0
 
 add.w d0,d0
 cmp.w #11*512,d0
 blt.s .notoowater
 move.w #11*512,d0
.notoowater:
  
 adda.w d0,a1

 move.l dst,d0
 asl.w #7,d0
 add.w wtan,d0
 and.w #8191,d0
 move.l #SineTable,a0
 move.w (a0,d0.w),d0
 ext.l d0
 
 move.l dst,d3
 add.w #300,d3
 divs d3,d0
 asr.w #5,d0
 addq #4,d0
 cmp.w disttobot,d0
 blt.s oknotoffbototot

 move.w disttobot,d0
 subq #1,d0

oknotoffbototot
 
; move.w dst,d3
; asr.w #7,d3
; add.w d3,d0
 
 tst.b DOUBLEHEIGHT
 beq.s .nodoub
 and.b #$fe,d0
.nodoub:
 
 muls #320,d0
 tst.w above
 beq.s nonnnnneg
 neg.l d0

nonnnnneg:
 
 move.l d0,a6

 move.l watertouse,a0

 move.w startsmoothx,d3
 dbra d7,acrossscrnw
 rts

backbeforew:
 and.w d1,d5
 move.w (a0,d5.w*4),d0
 move.b (a3,a6.w),d0
 move.b (a1,d0.w*2),(a3)+
 add.w a4,d3
 addx.l d6,d5
 dbcs d7,acrossscrnw
 dbcc d7,backbeforew
 rts
 
acrossscrnw:
 move.w d5,d3
 move.l d5,d6
 lsr.w #8,d3
 swap d6
 move.b d3,d6
 move.w (a0,d6.w*4),d0
 add.l d2,d5
 move.b (a3,a6.w),d0
 and.l d4,d5
 move.b (a1,d0.w*2),(a3)+
 dbra d7,acrossscrnw
 rts


texturedwaterDOUB:

 move.l d1,d4

 add.l wateroff,d5

 move.l #brightentab,a1
 move.l dst,d0
 clr.b d0
 
 add.w d0,d0
 cmp.w #11*512,d0
 blt.s .notoowater
 move.w #11*512,d0
.notoowater:
  
 adda.w d0,a1

 move.l dst,d0
 asl.w #7,d0
 add.w wtan,d0
 and.w #8191,d0
 move.l #SineTable,a0
 move.w (a0,d0.w),d0
 ext.l d0
 
 move.l dst,d3
 add.w #300,d3
 divs d3,d0
 asr.w #5,d0
 addq #4,d0
 cmp.w disttobot,d0
 blt.s .oknotoffbototot

 move.w disttobot,d0
 subq #1,d0

.oknotoffbototot
 
; move.w dst,d3
; asr.w #7,d3
; add.w d3,d0
 
 tst.b DOUBLEHEIGHT
 beq.s .nodoub
 and.b #$fe,d0
.nodoub:
 
 muls #320,d0
 tst.w above
 beq.s .nonnnnneg
 neg.l d0

.nonnnnneg:
 
 move.l d0,a6

 move.l watertouse,a0
 
 add.l d2,d2
 
 move.w startsmoothx,d3
 dbra d7,acrossscrnwD
 rts

 
acrossscrnwD:
 move.w d5,d3
 move.l d5,d6
 lsr.w #8,d3
 swap d6
 move.b d3,d6
 move.w (a0,d6.w*4),d0
 add.l d2,d5
 move.b (a3,a6.w),d0
 and.l d4,d5
 move.w (a1,d0.w*2),(a3)+
 dbra d7,acrossscrnwD
 rts


usewater: dc.w 0
 dc.w 0
startsmoothx: dc.w 0
 dc.w 0
startsmoothz: dc.w 0

********************************
*
 include "AB3:source_4000/ObjDrawHIRES.s"
*
********************************

numframes:
 dc.w 0

alframe: dc.l 0
 
alan:
 dcb.l 8,0
 dcb.l 8,1
 dcb.l 8,2
 dcb.l 8,3
endalan:

alanptr: dc.l alan

Time2: dc.l 0
dispco:
 dc.w 0


key_interrupt:
		movem.l	d0-d7/a0-a6,-(sp)

;		move.w	INTREQR,d0
;		btst	#3,d0
;		beq	.not_key

		move.b	$bfdd00,d0
		btst	#0,d0
		bne	.key_cont
;		move.b	$bfed01,d0
;		btst	#0,d0
;		bne	.key_cont
	
;		btst	#3,d0
;		beq	.key_cont

		move.b	$bfec01,d0
		clr.b	$bfec01

		tst.b	d0
		beq	.key_cont

;		bset	#6,$bfee01
;		move.b	#$f0,$bfe401
;		move.b	#$00,$bfe501
;		bset	#0,$bfee01


		not.b	d0
		ror.b	#1,d0
		lea.l	KeyMap,a0
		tst.b	d0
		bmi.b	.key_up
		and.w	#$7f,d0
;		add.w	#1,d0
		move.b	#$ff,(a0,d0.w)
		move.b	d0,lastpressed

		bra.b	.key_cont2
.key_up:
		and.w	#$7f,d0
;		add.w	#1,d0
		move.b	#$00,(a0,d0.w)

.key_cont2
;		btst	#0,$bfed01
;		beq	.key_cont2
;		move.b	#%00000000,$bfee01
;		move.b	#%10001000,$bfed01

;alt keys should not be independent so overlay ralt on lalt

		
.key_cont

;		move.w	#$0008,INTREQ
.not_key:	;lea.l	$dff000,a5

;		lea.l	_keypressed(pc),a0
;		move.b	101(a0),d0	;read LALT
;		or.b	102(a0),d0	;blend it with RALT
;		move.b	d0,127(a0)	;save in combined position

		movem.l	(sp)+,d0-d7/a0-a6

		rts

lastpressed:	dc.b 0
KInt_CCode	Ds.b	1
KInt_Askey	Ds.b	1
KInt_OCode	Ds.w	1

 
OldSpace: dc.b 0
SpaceTapped: dc.b 0
PLR1_SPCTAP: dc.b 0
PLR2_SPCTAP: dc.b 0
PLR1_Ducked: dc.b 0
PLR2_Ducked: dc.b 0
 even

 include "ab3:source_4000/PLR1CONTROL.s"
 include "ab3:source_4000/PLR2CONTROL.s"
 include "ab3:source_4000/FALL.s"

prot7: dc.w 0
 
GOTTOSEND: dc.w 0

OtherInter:
 move.w #$0010,$dff000+intreq
 movem.l d0-d7/a0-a6,-(a7)
 bra justshake

	cnop 0,4

Chan0inter:

	SAVEREGS
	jsr	.routine
	GETREGS

;	move.w	#1024+'.',$dff030
	
	moveq #0,d0
	rts

.routine

	
;w move.w #$0010,$dff000+intreq

 tst.b doanything
 bne dosomething
 
 movem.l d0-d7/a0-a6,-(a7)
 bra JUSTSOUNDS

 rts
 
tabheld: dc.w 0
ObjWork: ds.l 512
WORKPTR: dc.l 0
thistime: dc.w 0
 
DOALLANIMS:

 sub.b #1,thistime
 ble.s .okdosome
 rts
 
.okdosome:
 move.b #5,thistime


 move.l #ObjWork,a5
 move.l ObjectData,a0
Objectloop2:
 tst.w (a0)
 blt doneallobj2
 move.w 12(a0),d0
 blt doneobj2
 move.w d0,GraphicRoom(a0)
 tst.b worry(a0)
 beq.s doneobj2

 move.b 16(a0),d0
 cmp.b #1,d0
 blt JUMPALIENANIM
 beq JUMPOBJECTANIM
; cmp.b #2,d0
; beq JUMPBULLET

doneobj2:

 adda.w #64,a0
 addq #8,a5
 bra Objectloop2

doneallobj2:
 rts
 
JUMPALIENANIM:

 moveq #0,d0
 move.b WhichAnim(a0),d0
; 0=walking
; 1=attacking
; 2=getting hit
; 3=dying

 cmp.b #1,d0
 blt.s ALWALK
 beq.s ALATTACK
 
 cmp.b #3,d0
 blt ALGETHIT
 beq ALDIE
 
 bra doneobj2

ALDIE
 move.l #10,d0
 bra intowalk

ALGETHIT:
 move.l #9,d0
 bra intowalk

ALATTACK:
 move.l #8,d0
 bra intowalk
 
AUXOBJ: dc.w 0
 
ALWALK:
 
 jsr ViewpointToDraw
 add.l d0,d0
 
 move.l LINKFILE,a6
 add.l #AlienStats,a6
 moveq #0,d1
 move.b TypeOfThing(a0),d1
 muls #AlienStatLen,d1
 add.l d1,a6
 cmp.w #1,A_GFXType(a6)
 bne.s NOSIDES2
 
 moveq #0,d0
intowalk:
 
NOSIDES2:

 move.b d0,2(a5)
 move.l LINKFILE,a6
 
 add.l #AlienAnimData,a6
 
 moveq #0,d1
 move.b TypeOfThing(a0),d1
 muls #A_AnimLen,d1
 add.l d1,a6

; move.l ANIMPOINTER,a6

 muls #A_OptLen,d0
 add.w d0,a6

 move.w SecTimer(a0),d1
 move.w d1,d2
 muls #A_FrameLen,d1

 moveq #0,d0
 move.b 5(a6,d1.w),d0
 beq.s .nosoundmake
 
 movem.l d0-d7/a0-a6,-(a7)
 subq #1,d0
 move.w d0,Samplenum
 clr.b notifplaying
 move.b 1(a0),IDNUM
 move.w #80,Noisevol
 move.l #ObjRotated,a1
 move.w (a0),d0
 lea (a1,d0.w*8),a1
 move.l (a1),Noisex
 jsr MakeSomeNoise
 movem.l (a7)+,d0-d7/a0-a6
.nosoundmake

 move.b 6(a6,d1.w),d0
 beq.s .noaction
 add.b #1,(a5)
 move.b d2,1(a5)
.noaction

 addq #1,d2
 
 moveq #0,d0
 move.b 7(a6,d1.w),d0
 beq.s .nospecial

 move.b d0,d3
 and.w #63,d3
 lsr.w #6,d0
 cmp.w #2,d0
 blt.s .storeval
 beq.s .randval
 
 sub.b #1,4(a5)
 beq.s .nospecial

 move.w d3,d2
 bra.s .nospecial
 
.randval:
 jsr GetRand
 divs d3,d0
 swap d0
 move.w d0,d3
 
.storeval:
 move.b d3,4(a5)
.nospecial:

 move.w d2,d3
 muls #A_FrameLen,d3
 tst.b (a6,d3.w)
 bge.s .noendanim
 st 3(a5)
 move.w #0,d2
.noendanim
 move.w d2,SecTimer(a0)

 bra doneobj2


JUMPOBJECTANIM:
 bra doneobj2

 
dosomething:


 addq.w #1,FramesToDraw
 movem.l d0-d7/a0-a6,-(a7)
 jsr NARRATOR
 
 bsr DOALLANIMS
 
 move.l #KeyMap,a5
 
 tst.b $42(a5)
 bne.s .tabprsd
 clr.b tabheld
 bra.s .noswitch

.tabprsd:
 tst.b tabheld
 bne.s .noswitch
 not.b MAPON
 st tabheld
.noswitch
 
 tst.b $3e(a5)
 sne d0
 tst.b $1e(a5)
 sne d1
 tst.b $2d(a5)
 sne d2
 tst.b $2f(a5)
 sne d3
 
 tst.b $3d(a5)
 sne d4
 tst.b $3f(a5)
 sne d5
 tst.b $1d(a5)
 sne d6
 tst.b $1f(a5)
 sne d7
 
 or.b d4,d0
 or.b d5,d0
 or.b d6,d1
 or.b d7,d1
 or.b d4,d2
 or.b d6,d2
 or.b d7,d3
 or.b d5,d3

 move.w MAPBRIGHT,d4
 add.w #2,d4
 clr.l d5
 bset d4,d5

 tst.b d0
 beq.s .nomapup
 sub.w d5,mapzoff
.nomapup 

 tst.b d1
 beq.s .nomapdown
 add.w d5,mapzoff
.nomapdown 

 tst.b d2
 beq.s .nomapleft
 add.w d5,mapxoff
.nomapleft 

 tst.b d3
 beq.s .nomapright
 sub.w d5,mapxoff
.nomapright 

 tst.b $2e(a5)
 beq.s .nomapcentre
 
 move.w #0,mapxoff
 move.w #0,mapzoff
 
.nomapcentre

; move.w STOPOFFSET,d0
; tst.b 27(a5)
; beq.s .nolookup
; sub.w #5,d0
; cmp.w #-80,d0
; bgt.s .nolookup
; move.w #-80,d0
;.nolookup:
; tst.b 42(a5)
; beq.s .nolookdown
; add.w #5,d0
; cmp.w #80,d0
; blt.s .nolookdown
; move.w #80,d0
;.nolookdown:
;
; move.w d0,STOPOFFSET
; neg.w d0
; add.w #120,d0
; move.w d0,SMIDDLEY
; muls #320*2,d0
; move.l d0,SBIGMIDDLEY


 
; jsr INITREC
; jsr RECEIVE
 
; tst.l BUFFER
; beq.s justshake
; st GOTTOSEND
; move.l #OtherInter,$6c

justshake:
 
 cmp.b #'b',Prefsfile+3
 bne.s .noback
 jsr mt_music
.noback:
 
 bra dontshowtime
 
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

 
 move.l alanptr,a0
 move.l (a0)+,alframe
 cmp.l #endalan,a0
 blt.s nostartalan
 move.l #alan,a0
nostartalan:
 move.l a0,alanptr
 

 tst.b READCONTROLS
 beq.s nocontrols

 cmp.b #'s',mors
 beq.s control2

 tst.b PLR1MOUSE
 beq.s PLR1_nomouse
 bsr PLR1_mouse_control
PLR1_nomouse:
 tst.b PLR1KEYS
 beq.s PLR1_nokeys
 bsr PLR1_keyboard_control
PLR1_nokeys:
; tst.b PLR1PATH
; beq.s PLR1_nopath
; bsr PLR1_follow_path
;PLR1_nopath:
 tst.b PLR1JOY
 beq.s PLR1_nojoy
 bsr PLR1_JoyStick_control
PLR1_nojoy: 
 bra.s nocontrols

control2:
 tst.b PLR2MOUSE
 beq.s PLR2_nomouse
 bsr PLR2_mouse_control
PLR2_nomouse:
 tst.b PLR2KEYS
 beq.s PLR2_nokeys
 bsr PLR2_keyboard_control
PLR2_nokeys:
; tst.b PLR2PATH
; beq.s PLR2_nopath
; bsr PLR1_follow_path
;PLR2_nopath:
 tst.b PLR2JOY
 beq.s PLR2_nojoy
 bsr PLR2_JoyStick_control
PLR2_nojoy: 


nocontrols:

 move.l #$dff000,a6

 cmp.b #'4',Prefsfile+1
 bne.s nomuckabout
 
 move.w #$0,d0 
 tst.b NoiseMade0LEFT
 beq.s noturnoff0
 move.w #1,d0
noturnoff0:
 tst.b NoiseMade0RIGHT
 beq.s noturnoff1
 or.w #2,d0
noturnoff1:
 tst.b NoiseMade1RIGHT
 beq.s noturnoff2
 or.w #4,d0
noturnoff2:
 tst.b NoiseMade1LEFT
 beq.s noturnoff3
 or.w #8,d0
noturnoff3:
	move.w d0,dmacon(a6)
 
nomuckabout:

 
; tst.b PLR2_fire
; beq.s firenotpressed2
; fire was pressed last time.
; btst #7,$bfe001
; bne.s firenownotpressed2
; fire is still pressed this time.
; st PLR2_fire
; bra dointer
 
firenownotpressed2:
; fire has been released.
; clr.b PLR2_fire
; bra dointer
 
firenotpressed2

; fire was not pressed last frame...

; btst #7,$bfe001
; if it has still not been pressed, go back above
; bne.s firenownotpressed2
; fire was not pressed last time, and was this time, so has
; been clicked.
; st PLR2_clicked
; st PLR2_fire
 
dointer
 
JUSTSOUNDS:
 
 tst.b dosounds
 beq.s .notthing
 
 cmp.b #'4',Prefsfile+1
	beq fourchannel
 
 btst #1,$dff000+intreqr
	bne.s newsampbitl

.notthing:

 movem.l (a7)+,d0-d7/a0-a6
 
 moveq #0,d0
 rts
 
 
dosounds: dc.w 0
 
swappedem: dc.w 0
 
newsampbitl:

 move.w #$820f,$dff000+dmacon

 move.w #$200,$dff000+intreq
 
; tst.b CHANNELDATA
; bne nochannel0
 
 move.l pos0LEFT,a0
 move.l pos2LEFT,a1

 move.l #tab,a2
 
 moveq #0,d0
 moveq #0,d1
 move.b vol0left,d0
 move.b vol2left,d1
 cmp.b d1,d0
 slt swappedem
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

 tst.b swappedem
 beq.s .ok23
 exg a0,a1
.ok23:
 
 cmp.l Samp0endLEFT,a0
 blt.s .notoffendsamp1
 move.l #empty,a0
 move.l #emptyend,Samp0endLEFT
 move.b #0,vol0left
 st LEFTCHANDATA+1
 move.w #0,LEFTCHANDATA+2
.notoffendsamp1:

 cmp.l Samp2endLEFT,a1
 blt.s .notoffendsamp2
 move.l #empty,a1
 move.l #emptyend,Samp2endLEFT
 move.b #0,vol2left
 st LEFTCHANDATA+1+8
 move.w #0,LEFTCHANDATA+2+8
.notoffendsamp2:
 
 move.l a0,pos0LEFT
 move.l a1,pos2LEFT

nochannel0:

 tst.b CHANNELDATA+16
 bne nochannel1

 
 move.l pos0RIGHT,a0
 move.l pos2RIGHT,a1

 move.l Aupt1,a3
 move.l a3,$dff0b0
 move.l Auback1,Aupt1
 move.l a3,Auback1

 move.l #tab,a2
 
 moveq #0,d0
 moveq #0,d1
 move.b vol0right,d0
 move.b vol2right,d1
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
 
 cmp.l Samp0endRIGHT,a0
 blt.s .notoffendsamp1
 move.l #empty,a0
 move.l #emptyend,Samp0endRIGHT
 move.b #0,vol0right
 st RIGHTCHANDATA+1
 move.w #0,RIGHTCHANDATA+2
.notoffendsamp1:

 cmp.l Samp2endRIGHT,a1
 blt.s .notoffendsamp2
 move.l #empty,a1
 move.l #emptyend,Samp2endRIGHT
 move.b #0,vol2right
 st RIGHTCHANDATA+1+8
 move.w #0,RIGHTCHANDATA+2+8
.notoffendsamp2:

 move.l a0,pos0RIGHT
 move.l a1,pos2RIGHT

nochannel1:

******************* Other two channels

 move.l pos1LEFT,a0
 move.l pos3LEFT,a1

 move.l #tab,a2
 
 moveq #0,d0
 moveq #0,d1
 move.b vol1left,d0
 move.b vol3left,d1
 cmp.b d1,d0
 slt swappedem
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

 tst.b swappedem
 beq.s .ok23
 exg a0,a1
.ok23:

 cmp.l Samp1endLEFT,a0
 blt.s .notoffendsamp3
 move.l #empty,a0
 move.l #emptyend,Samp1endLEFT
 move.b #0,vol1left
 st LEFTCHANDATA+1+4
 move.w #0,LEFTCHANDATA+2+4
.notoffendsamp3:

 cmp.l Samp3endLEFT,a1
 blt.s .notoffendsamp4
 move.l #empty,a1
 move.l #emptyend,Samp3endLEFT
 move.b #0,vol3left
 st LEFTCHANDATA+1+12
 move.w #0,LEFTCHANDATA+2+12
.notoffendsamp4:

 move.l a0,pos1LEFT
 move.l a1,pos3LEFT
 
 move.l pos1RIGHT,a0
 move.l pos3RIGHT,a1

 move.l Aupt3,a3
 move.l a3,$dff0c0
 move.l Auback3,Aupt3
 move.l a3,Auback3

 move.l #tab,a2
 
 moveq #0,d0
 moveq #0,d1
 move.b vol1right,d0
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
 beq.s .ok23
 exg a0,a1
.ok23:
 
 cmp.l Samp1endRIGHT,a0
 blt.s notoffendsamp3
 move.l #empty,a0
 move.l #emptyend,Samp1endRIGHT
 move.b #0,vol1right
 st RIGHTCHANDATA+1+4
 move.w #0,RIGHTCHANDATA+2+4
notoffendsamp3:

 cmp.l Samp3endRIGHT,a1
 blt.s notoffendsamp4
 move.l #empty,a1
 move.l #emptyend,Samp3endRIGHT
 move.b #0,vol3right
 st RIGHTCHANDATA+1+12
 move.w #0,RIGHTCHANDATA+2+12
notoffendsamp4:

 move.l a0,pos1RIGHT
 move.l a1,pos3RIGHT

 movem.l (a7)+,d0-d7/a0-a6
 tst.b counting
 beq .nostartcounter
 JSR STARTCOUNT
.nostartcounter:

 moveq #0,d0
 rts
 
***********************************
* 4 channel sound routine
***********************************

fourchannel:

 move.l #$dff000,a6

 btst #7,intreqrl(a6)
 beq.s nofinish0
; move.w #0,LEFTCHANDATA+2
; st LEFTCHANDATA+1
 move.l #null,$a0(a6)
 move.w #100,$a4(a6) 
 move.w #$0080,intreq(a6)
nofinish0:
 
 tst.b NoiseMade0pLEFT
 beq.s NoChan0sound

 move.l Samp0endLEFT,d0
 move.l pos0LEFT,d1
 sub.l d1,d0
 lsr.l #1,d0
 move.w d0,$a4(a6)
 move.l d1,$a0(a6)
 move.w #$8201,dmacon(a6)
 moveq #0,d0
 move.b vol0left,d0
 move.w d0,$a8(a6)

NoChan0sound:

*****************************************
*****************************************

 btst #0,intreqr(a6)
 beq.s nofinish1
 move.l #null,$b0(a6)
 move.w #100,$b4(a6)
 move.w #$0100,intreq(a6)
nofinish1:

 tst.b NoiseMade0pRIGHT
 beq.s NoChan1sound

 move.l Samp0endRIGHT,d0
 move.l pos0RIGHT,d1
 sub.l d1,d0
 lsr.l #1,d0
 move.w d0,$b4(a6)
 move.l d1,$b0(a6)
 move.w d0,playnull1
 move.w #$8202,dmacon(a6)
 moveq #0,d0
 move.b vol0right,d0
 move.w d0,$b8(a6)

NoChan1sound:

*****************************************
*****************************************

 btst #1,intreqr(a6)
 beq.s nofinish2
 move.l #null,$c0(a6)
 move.w #100,$c4(a6)
 move.w #$0200,intreq(a6)
nofinish2:

 tst.b NoiseMade1pRIGHT
 beq.s NoChan2sound

 move.l Samp1endRIGHT,d0
 move.l pos1RIGHT,d1
 sub.l d1,d0
 lsr.l #1,d0
 move.w d0,$c4(a6)
 move.w d0,playnull2
 
 move.l d1,$c0(a6)
 move.w #$8204,dmacon(a6)
 moveq #0,d0
 move.b vol1right,d0
 move.w d0,$c8(a6)

NoChan2sound:

*****************************************
*****************************************

 btst #2,intreqr(a6)
 beq.s nofinish3
 move.l #null,$d0(a6)
 move.w #100,$d4(a6)
 move.w #$0400,intreq(a6)
nofinish3:

 tst.b NoiseMade1pLEFT
 beq.s NoChan3sound

 move.l Samp1endLEFT,d0
 move.l pos1LEFT,d1
 sub.l d1,d0
 lsr.l #1,d0
 move.w d0,$d4(a6)
 move.w d0,playnull3
 move.l d1,$d0(a6)
 move.w #$8208,dmacon(a6)
 moveq #0,d0
 move.b vol1left,d0
 move.w d0,$d8(a6)
 
NoChan3sound:
 
nomorechannels:

 move.l NoiseMade0LEFT,NoiseMade0pLEFT
 move.l #0,NoiseMade0LEFT
 move.l NoiseMade0RIGHT,NoiseMade0pRIGHT
 move.l #0,NoiseMade0RIGHT

; tst.b playnull0
; beq.s .nnul
; sub.b #1,playnull0
; bra.s chan0still
;.nnul:
; 
;chan0still:

 tst.b NoiseMade0pLEFT
 bne.s chan0still
 tst.w playnull0
 beq.s nnul0
 sub.w #100,playnull0
 bra.s chan0still
nnul0:
 move.w #0,LEFTCHANDATA+2
 st LEFTCHANDATA+1
chan0still:

 tst.b NoiseMade0pRIGHT
 bne.s chan1still
 tst.w playnull1
 beq.s nnul1
 sub.w #100,playnull1
 bra.s chan1still
nnul1:
 move.w #0,RIGHTCHANDATA+2
 st RIGHTCHANDATA+1
chan1still:

 tst.b NoiseMade1pRIGHT
 bne.s chan2still
 tst.w playnull2
 beq.s nnul2
 sub.w #100,playnull2
 bra.s chan2still
nnul2:
 move.w #0,RIGHTCHANDATA+2+4
 st RIGHTCHANDATA+1+4
chan2still:

 tst.b NoiseMade1pLEFT
 bne.s chan3still
 tst.w playnull3
 beq.s nnul3
 sub.w #100,playnull3
 bra.s chan3still
nnul3:
 move.w #0,LEFTCHANDATA+2+4
 st LEFTCHANDATA+1+4
 
chan3still:


 movem.l (a7)+,d0-d7/a0-a6

 moveq #0,d0
 rts
 
backbeat: dc.w 0

playnull0: dc.w 0
playnull1: dc.w 0
playnull2: dc.w 0
playnull3: dc.w 0

Samp0endRIGHT: dc.l emptyend
Samp1endRIGHT: dc.l emptyend
Samp2endRIGHT: dc.l emptyend
Samp3endRIGHT: dc.l emptyend
Samp0endLEFT: dc.l emptyend
Samp1endLEFT: dc.l emptyend
Samp2endLEFT: dc.l emptyend
Samp3endLEFT: dc.l emptyend

Aupt0: dc.l null
Auback0: dc.l null+500
Aupt2: dc.l null3
Auback2: dc.l null3+500
Aupt3: dc.l null4
Auback3: dc.l null4+500
Aupt1: dc.l null2
Auback1: dc.l null2+500

NoiseMade0LEFT: dc.b 0
NoiseMade1LEFT: dc.b 0
NoiseMade2LEFT: dc.b 0
NoiseMade3LEFT: dc.b 0
NoiseMade0pLEFT: dc.b 0
NoiseMade1pLEFT: dc.b 0
NoiseMade2pLEFT: dc.b 0
NoiseMade3pLEFT: dc.b 0
NoiseMade0RIGHT: dc.b 0
NoiseMade1RIGHT: dc.b 0
NoiseMade2RIGHT: dc.b 0
NoiseMade3RIGHT: dc.b 0
NoiseMade0pRIGHT: dc.b 0
NoiseMade1pRIGHT: dc.b 0
NoiseMade2pRIGHT: dc.b 0
NoiseMade3pRIGHT: dc.b 0

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
IDNUM: dc.w 0
needleft: dc.b 0
needright: dc.b 0
STEREO: dc.b $0
even
prot6: dc.w 0

 even
 
CHANNELDATA:
LEFTCHANDATA:
 dc.l $00000000
 dc.l $00000000
 dc.l $FF000000
 dc.l $FF000000
RIGHTCHANDATA:
 dc.l $00000000
 dc.l $00000000
 dc.l $FF000000
 dc.l $FF000000
 
RIGHTPLAYEDTAB: ds.l 20
LEFTPLAYEDTAB: ds.l 20
 
MakeSomeNoise:

; Plan for new sound handler:
; It is sent a sample number,
; a position relative to the
; player, an id number and a volume.
; Also notifplaying.

; indirect inputs are the available
; channel flags and whether or not
; stereo sound is selected.

; the algorithm must decide
; whether the new sound is more
; important than the ones already
; playing. Thus an 'importance'
; must be calculated, probably
; using volume.

; The output needs to be:

; Write the pointers and volumes of
; the sound channels


 tst.b notifplaying
 beq.s dontworry

; find if we are already playing

 move.b IDNUM,d0
 move.w #7,d1
 lea CHANNELDATA,a3
findsameasme
 tst.b (a3)
 bne.s notavail
 cmp.b 1(a3),d0
 beq SameAsMe
notavail:
 add.w #4,a3
 dbra d1,findsameasme
 bra dontworry
SameAsMe
 rts

noiseloud: dc.w 0

dontworry:

; Ok its fine for us to play a sound.
; So calculate left/right volume.

 move.w Noisex,d1
 muls d1,d1
 move.w Noisez,d2
 muls d2,d2
 move.w #64,d3
 move.w #32767,noiseloud
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
 
 move.w Noisevol,d3
 ext.l d3
 asl.l #6,d3
 cmp.l #32767,d3
 ble.s .nnnn
 move.l #32767,d3
.nnnn
 
 asr.w #2,d0
 addq #1,d0
 divs d0,d3
 
 move.w d3,noiseloud

 cmp.w #64,d3
 ble.s notooloud
 move.w #64,d3
notooloud:

pastcalc:

	; d3 contains volume of noise.
	
 move.w d3,d4
 tst.b STEREO
 beq NOSTEREO
 
 move.w d3,d2
 muls Noisex,d2
 asl.w #2,d0
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

 clr.w needleft

 cmp.b d3,d4
 bgt.s RightLouder
 
; Left is louder; is it MUCH louder?

 st needleft
 move.w d3,d2
 sub.w d4,d2
 cmp.w #32,d2
 slt needright
 bra aboutsame
 
RightLouder:
 st needright
 move.w d4,d2
 sub.w d3,d2
 cmp.w #32,d2
 slt needleft
 
aboutsame:


; Find least important sound on left

 move.l #0,a2
 move.l #0,d5
 move.w #32767,d2
 move.b IDNUM,d0
 lea LEFTCHANDATA,a3
 move.w #3,d1
FindLeftChannel
 tst.b (a3)
 bne.s .notactive
 cmp.b 1(a3),d0
 beq.s FOUNDLEFT
 cmp.w 2(a3),d2
 blt.s .notactive
 move.w 2(a3),d2
 move.l a3,a2
 move.w d5,d6

.notactive:
 add.w #4,a3
 add.w #1,d5
 dbra d1,FindLeftChannel
 move.l a2,a3
 bra.s gopastleft
FOUNDLEFT:
 move.w d5,d6
gopastleft:
 tst.l a3
 bne.s FOUNDALEFT
 rts
FOUNDALEFT:

; d6 = channel number
 move.b d0,1(a3)
 move.w d3,2(a3)

 move.w Samplenum,d5
 move.l #SampleList,a3
 move.l (a3,d5.w*8),a1
 move.l 4(a3,d5.w*8),a2

 tst.b d6
 seq NoiseMade0LEFT
 beq.s .chan0
 cmp.b #2,d6
 slt NoiseMade1LEFT
 blt .chan1
 seq NoiseMade2LEFT
 beq .chan2
 st NoiseMade3LEFT

 move.b d5,LEFTPLAYEDTAB+9
 move.b d3,LEFTPLAYEDTAB+1+9
 move.b d4,LEFTPLAYEDTAB+2+9
 move.b d3,vol3left
 move.l a1,pos3LEFT
 move.l a2,Samp3endLEFT
 bra dorightchan
 
.chan0: 
 move.b d5,LEFTPLAYEDTAB
 move.b d3,LEFTPLAYEDTAB+1
 move.b d4,LEFTPLAYEDTAB+2
 move.l a1,pos0LEFT
 move.l a2,Samp0endLEFT
 move.b d3,vol0left
 bra dorightchan
 
.chan1:
 move.b d5,LEFTPLAYEDTAB+3
 move.b d3,LEFTPLAYEDTAB+1+3
 move.b d4,LEFTPLAYEDTAB+2+3
 move.b d3,vol1left
 move.l a1,pos1LEFT
 move.l a2,Samp1endLEFT
 bra dorightchan

.chan2: 
 move.b d5,LEFTPLAYEDTAB+6
 move.b d3,LEFTPLAYEDTAB+1+6
 move.b d4,LEFTPLAYEDTAB+2+6
 move.l a1,pos2LEFT
 move.l a2,Samp2endLEFT
 move.b d3,vol2left
 
dorightchan:

; Find least important sound on right

 move.l #0,a2
 move.l #0,d5
 move.w #10000,d2
 move.b IDNUM,d0
 lea RIGHTCHANDATA,a3
 move.w #3,d1
FindRightChannel
 tst.b (a3)
 bne.s .notactive
 cmp.b 1(a3),d0
 beq.s FOUNDRIGHT
 cmp.w 2(a3),d2
 blt.s .notactive
 move.w 2(a3),d2
 move.l a3,a2
 move.w d5,d6

.notactive:
 add.w #4,a3
 add.w #1,d5
 dbra d1,FindRightChannel
 move.l a2,a3
 bra.s gopastright
FOUNDRIGHT:
 move.w d5,d6
gopastright:
 tst.l a3
 bne.s FOUNDARIGHT
 rts
FOUNDARIGHT:

; d6 = channel number
 move.b d0,1(a3)
 move.w d3,2(a3)

 move.w Samplenum,d5
 move.l #SampleList,a3
 move.l (a3,d5.w*8),a1
 move.l 4(a3,d5.w*8),a2

 tst.b d6
 seq NoiseMade0RIGHT
 beq.s .chan0
 cmp.b #2,d6
 slt NoiseMade1RIGHT
 blt .chan1
 seq NoiseMade2RIGHT
 beq .chan2
 st NoiseMade3RIGHT

 move.b d5,RIGHTPLAYEDTAB+9
 move.b d3,RIGHTPLAYEDTAB+1+9
 move.b d4,RIGHTPLAYEDTAB+2+9
 move.b d4,vol3right
 move.l a1,pos3RIGHT
 move.l a2,Samp3endRIGHT
 rts
 
.chan0: 
 move.b d5,RIGHTPLAYEDTAB
 move.b d3,RIGHTPLAYEDTAB+1
 move.b d4,RIGHTPLAYEDTAB+2
 move.l a1,pos0RIGHT
 move.l a2,Samp0endRIGHT
 move.b d4,vol0right
 rts
 
.chan1:
 move.b d5,RIGHTPLAYEDTAB+3
 move.b d3,RIGHTPLAYEDTAB+1+3
 move.b d4,RIGHTPLAYEDTAB+2+3
 move.b d3,vol1right
 move.l a1,pos1RIGHT
 move.l a2,Samp1endRIGHT
 rts

.chan2: 
 move.b d5,RIGHTPLAYEDTAB+6
 move.b d3,RIGHTPLAYEDTAB+1+6
 move.b d4,RIGHTPLAYEDTAB+2+6
 move.l a1,pos2RIGHT
 move.l a2,Samp2endRIGHT
 move.b d3,vol2right
 rts

NOSTEREO:
 move.l #0,a2
 move.l #-1,d5
 move.w #32767,d2
 move.b IDNUM,d0
 lea CHANNELDATA,a3
 move.w #7,d1
FindChannel
 tst.b (a3)
 bne.s .notactive
 cmp.b 1(a3),d0
 beq.s FOUNDCHAN
 cmp.w 2(a3),d2
 blt.s .notactive
 move.w 2(a3),d2
 move.l a3,a2
 move.w d5,d6
 add.w #1,d6

.notactive:
 add.w #4,a3
 add.w #1,d5
 dbra d1,FindChannel
 
 move.l a2,a3
 bra.s gopastchan
FOUNDCHAN:
 move.w d5,d6
 add.w #1,d6
gopastchan:
 tst.w d6
 bge.s FOUNDACHAN
tooquiet:
 rts
FOUNDACHAN:

; d6 = channel number

 cmp.w noiseloud,d2
 bgt.s tooquiet

 move.b d0,1(a3)
 move.w noiseloud,2(a3)

 move.w Samplenum,d5
 move.l #SampleList,a3
 move.l (a3,d5.w*8),a1
 move.l 4(a3,d5.w*8),a2

 tst.b d6
 beq .chan0
 cmp.b #2,d6
 blt .chan1
 beq .chan2
 cmp.b #4,d6
 blt .chan3
 beq .chan4
 cmp.b #6,d6
 blt .chan5
 beq .chan6
 st NoiseMade3RIGHT

 move.b d5,RIGHTPLAYEDTAB+9
 move.b d3,RIGHTPLAYEDTAB+1+9
 move.b d4,RIGHTPLAYEDTAB+2+9
 move.b d4,vol3right
 move.l a1,pos3RIGHT
 move.l a2,Samp3endRIGHT
 rts

.chan3:
 st NoiseMade3LEFT
 move.b d5,LEFTPLAYEDTAB+9
 move.b d3,LEFTPLAYEDTAB+1+9
 move.b d4,LEFTPLAYEDTAB+2+9
 move.b d3,vol3left
 move.l a1,pos3LEFT
 move.l a2,Samp3endLEFT
 bra dorightchan
 
.chan0: 
 st NoiseMade0LEFT
 move.b d5,LEFTPLAYEDTAB
 move.b d3,LEFTPLAYEDTAB+1
 move.b d4,LEFTPLAYEDTAB+2
 move.l a1,pos0LEFT
 move.l a2,Samp0endLEFT
 move.b d3,vol0left
 rts
 
.chan1:
 st NoiseMade1LEFT
 move.b d5,LEFTPLAYEDTAB+3
 move.b d3,LEFTPLAYEDTAB+1+3
 move.b d4,LEFTPLAYEDTAB+2+3
 move.b d3,vol1left
 move.l a1,pos1LEFT
 move.l a2,Samp1endLEFT
 rts

.chan2: 
 st NoiseMade2LEFT
 move.b d5,LEFTPLAYEDTAB+6
 move.b d3,LEFTPLAYEDTAB+1+6
 move.b d4,LEFTPLAYEDTAB+2+6
 move.l a1,pos2LEFT
 move.l a2,Samp2endLEFT
 move.b d3,vol2left
 rts
 
.chan4: 
 st NoiseMade0RIGHT
 move.b d5,RIGHTPLAYEDTAB
 move.b d3,RIGHTPLAYEDTAB+1
 move.b d4,RIGHTPLAYEDTAB+2
 move.l a1,pos0RIGHT
 move.l a2,Samp0endRIGHT
 move.b d4,vol0right
 rts
 
.chan5:
 st NoiseMade1RIGHT
 move.b d5,RIGHTPLAYEDTAB+3
 move.b d3,RIGHTPLAYEDTAB+1+3
 move.b d4,RIGHTPLAYEDTAB+2+3
 move.b d3,vol1right
 move.l a1,pos1RIGHT
 move.l a2,Samp1endRIGHT
 rts

.chan6: 
 st NoiseMade2RIGHT
 move.b d5,RIGHTPLAYEDTAB+6
 move.b d3,RIGHTPLAYEDTAB+1+6
 move.b d4,RIGHTPLAYEDTAB+2+6
 move.l a1,pos2RIGHT
 move.l a2,Samp2endRIGHT
 move.b d3,vol2right
 rts

SampleList:
 dc.l Scream,EndScream
 dc.l Shoot,EndShoot
 dc.l Munch,EndMunch
 dc.l PooGun,EndPooGun
 dc.l Collect,EndCollect
;5
 dc.l DoorNoise,EndDoorNoise
 dc.l 0,0
 dc.l Stomp,EndStomp
 dc.l LowScream,EndLowScream
 dc.l BaddieGun,EndBaddieGun
;10
 dc.l SwitchNoise,EndSwitch
 dc.l Reload,EndReload
 dc.l NoAmmo,EndNoAmmo
 dc.l Splotch,EndSplotch
 dc.l SplatPop,EndSplatPop
;15
 dc.l Boom,EndBoom
 dc.l Hiss,EndHiss
 dc.l Howl1,EndHowl1
 dc.l Howl2,EndHowl2
 dc.l Pant,EndPant
;20
 dc.l Whoosh,EndWhoosh
 dc.l ROAR,EndROAR
 dc.l whoosh,Endwhoosh
 dc.l 0,0
 dc.l 0,0
 dc.l 0,0
 dc.l 0,0
 dc.l 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
 dc.l 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
 dc.l 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
 dc.l 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0

 dc.l 0
 
storeval: dc.w 0

 include "ab3:source_4000/wallchunk.s"
 include "ab3:source_4000/newloadfromdisk.s"
 include "ab3:source_4000/screensetup.s"
 include "ab3:source_4000/NEWWBCONTROLLOOP.s"
 include "ab3:source_4000/WBSETUP"



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

pos0LEFT: dc.l empty
pos1LEFT: dc.l empty
pos2LEFT: dc.l empty
pos3LEFT: dc.l empty
pos0RIGHT: dc.l empty
pos1RIGHT: dc.l empty
pos2RIGHT: dc.l empty
pos3RIGHT: dc.l empty

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
; incbin "ConstCols"
 even
Smoothscalecols:
; incbin "smoothbumppalscaled"
 even
SmoothTile:
; incbin "smoothbumptile"
 even
Bumpscalecols:
; incbin "Bumppalscaled"
 even
Bumptile:
; incbin "bumptile"
 even
scalecols: ;incbin "bytepixpalscaled"
 even
floorscalecols:
 incbin "floor256pal"
 ds.w 256*4

 even
PaletteAddr: dc.l 0
ChunkAddr: dc.l 0
;walltiles:
; dc.l GreenMechanicWALL
; dc.l BlueGreyMetalWALL
; dc.l TechnoDetailWALL
; dc.l BlueStoneWALL
; dc.l RedAlertWALL
; dc.l RockWALL
;
;GreenMechanicWALL: incbin "ab3:includes/walls/greenmechanic.wad"
;BlueGreyMetalWALL: incbin "ab3:includes/walls/BlueGreyMetal.wad"
;TechnoDetailWALL: incbin "ab3:includes/walls/TechnoDetail.wad"
;BlueStoneWALL: incbin "ab3:includes/walls/bluestone.wad"
;RedAlertWALL: incbin "ab3:includes/walls/redalert.wad"
;RockWALL: incbin "ab3:includes/walls/rock.wad"
 
floortile:
 dc.l 0
; incbin "floortile" 
 even
wallrouts:
; incbin "2x2WallDraw" 
 CNOP 0,64
BackPicture:
 incbin "rawback"
EndBackPicture:

drawpt: dc.l 0
olddrawpt: dc.l 0
frompt: dc.l 0 
 
SineTable:
 incbin "bigsine"

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
PLR1_energy: dc.w 191
PLR1_GunSelected: dc.w 0
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
PLR1_StoodInTop: dc.b 0
 even
PLR1_height: dc.l 0
PLR1_RoomBright: dc.w 0

DOUBLEWIDTH: dc.b $0,0
DOUBLEHEIGHT: dc.b 0,0
PLR1_TELEPORTED: dc.w 0

 ds.w 4
 
OLDX1: dc.l 0
OLDX2: dc.l 0
OLDZ1: dc.l 0
OLDZ2: dc.l 0

XDIFF1: dc.l 0
ZDIFF1: dc.l 0
XDIFF2: dc.l 0
ZDIFF2: dc.l 0

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
PLR1s_height: dc.l 0
PLR1s_targheight: dc.l 0

p1_xoff: dc.l 0
p1_zoff: dc.l 0
p1_yoff: dc.l 0
p1_height: dc.l 0
p1_angpos: dc.w 0
p1_bobble: dc.w 0
p1_clicked: dc.b 0
p1_spctap: dc.b 0
p1_ducked: dc.b 0
p1_gunselected: dc.b 0
p1_fire: dc.b 0
 even
p1_holddown: dc.w 0

 ds.w 4

PLR2: dc.b $ff
 even
PLR2_GunSelected: dc.w 0
PLR2_energy: dc.w 191
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
PLR2_oldxoff: dc.l 0
PLR2_oldzoff: dc.l 0
PLR2_StoodInTop: dc.b 0
 even
PLR2_height: dc.l 0

 ds.w 4

PLR2s_cosval: dc.w 0
PLR2s_sinval: dc.w 0
PLR2s_angpos: dc.w 0
PLR2s_angspd: dc.w 0
PLR2s_xoff: dc.l 0
PLR2s_yoff: dc.l 0
PLR2s_yvel: dc.l 0
PLR2s_zoff: dc.l 0
PLR2s_tyoff: dc.l 0
PLR2s_xspdval: dc.l 0
PLR2s_zspdval: dc.l 0
PLR2s_Zone: dc.w 0
PLR2s_Roompt: dc.l 0
PLR2s_OldRoompt: dc.l 0
PLR2s_PointsToRotatePtr: dc.l 0
PLR2s_ListOfGraphRooms: dc.l 0
PLR2s_oldxoff: dc.l 0
PLR2s_oldzoff: dc.l 0
PLR2s_height: dc.l 0
PLR2s_targheight: dc.l 0

 ds.w 4

p2_xoff: dc.l 0
p2_zoff: dc.l 0
p2_yoff: dc.l 0
p2_height: dc.l 0
p2_angpos: dc.w 0
p2_bobble: dc.w 0
p2_clicked: dc.b 0
p2_spctap: dc.b 0
p2_ducked: dc.b 0
p2_gunselected: dc.b 0
p2_fire: dc.b 0
 even
p2_holddown: dc.w 0

liftanimtab:

endliftanimtab:
 
glassball:
; incbin "glassball.inc"

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
 include "AB3:source_4000/LevelData2"
 *
*****************************************************************


wallpt: dc.l 0
floorpt: dc.l 0

Rotated:
 ds.l 2*800 
ObjRotated:
 ds.l 2*500

OnScreen:
 ds.l 2*800 
 
startwait: dc.w 0
endwait: dc.w 0

Faces:; incbin "faces2raw"

LINKS: ds.b 10000
FLYLINKS: ds.b 10000
*******************************************************************

consttab:
 incbin "constantfile"

*******************************************************************
 
 

*********************************

; include "ab3:source_4000/loadmod.a"
; include "ab3:source_4000/proplayer.a"

 
darkentab: 
;val SET 0
; REPT 256
; dc.b val
;val SET val+1
; ENDR
 incbin "darkenfile"

MIDDLEX: dc.w 0
RIGHTX: dc.w 192
FULLSCR: dc.w 0

SHADINGTABLE: incbin "SHADEFILE" 
 
******************************************
* Link file !*****************************
******************************************

LINKSPACE:
 ds.l 22500
; incbin "ab3:includes/test.lnk"

LINKname:
 dc.b "ab3:includes/test.lnk",0

LINKFILE:
 dc.l LINKSPACE

******************************************
 
 
brightentab: incbin "brightenfile"
WorkSpace:
 ds.l 8192 
waterfile: incbin "waterfile"

 SECTION ffff,CODE_C

nullspr: dc.l 0
 
 cnop 0,8
borders:
 incbin "newleftbord"
 incbin "newrightbord"

health: incbin "healthstrip"
Ammunition: incbin "ammostrip"
healthpal: incbin "healthpal"
PanelKeys: incbin "greenkey"
 incbin "redkey"
 incbin "yellowkey"
 incbin "bluekey"

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

nullline:
 ds.b 80	

 include "ab3:source_4000/titlecop.s"

bigfield:    
                ; Start of our copper list.
 dc.w dmacon,$8020
 dc.w intreq,$8011
 dc.w $1fc,$f
 dc.w diwstart
winstart: dc.w $2c81
 dc.w diwstop
winstop: dc.w $2cc1
 dc.w ddfstart
fetchstart: dc.w $38
 dc.w ddfstop
fetchstop: dc.w $b8

bordercols:
 incbin "borderpal"

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

; dc.w $106,$c42
; incbin "borderpal"

 dc.w $106,$c42

 dc.w bplcon0,$0211
 dc.w bplcon1
smoff:
 dc.w $0

 dc.w $108
modulo: dc.w 0
 dc.w $10a,0

 dc.w $1001,$ff00
 dc.w intreq,$11

PALETTESPACE:
 dcb.l 528,$1fe0000

 dc.w $2001,$ff00

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

 dc.w bpl8pth
pl8h
 dc.w 0

 dc.w bpl8ptl
pl8l
 dc.w 0


val SET $2c
SCRMODULOS:
 REPT 232
 dc.b val,1,$ff,$fe
 dc.w $108,0
 dc.w $10a,0
 dc.b val,$df,$ff,$fe
val SET (val+1)&$ff
 ENDR

 dc.w $108,0,$10a,0
 dc.w $2401,$ff00
 dc.w ddfstop,$c8
 dc.w bplcon0,$9201
 dc.w bpl1ptl
scroll:
 dc.w 0
 dc.w bpl1pth
scrolh:
 dc.w 0

 dc.w $106,$c40
 dc.w $180,0
 dc.w $182,$f0
; dc.w $108,40
; dc.w $10a,40

; dc.w $80
;JUMPBACKH:
; dc.w 0
; dc.w $82
;JUMPBACKL:
; dc.w 0
 
; dc.w $8a,0
 
 dc.w $ffff,$fffe
 dc.w $ffff,$fffe


COPIEDPAL:
 dc.w 256,0
 ds.l 3*256
 ds.l 10

PALETTEBIT:
; incbin "256palette"
; dc.w $ffff,$fffe


 incbin "ab3:includes/256pal"

 
yposcop:
; dc.w $2a11,$fffe
; dc.w $8a,0
 
; ds.l 104*12
 
;colbars:
;val SET $2a
; dcb.l 104*80,$1fe0000
; dc.w $106,$c42
; 
; dc.w $80
;pch1:
; dc.w 0
; dc.w $82
;pcl1:
; dc.w 0 
; 
; dc.w $88,0
; 
; dc.w $ffff,$fffe       ; End copper list.

; ds.l 104*12


;colbars2:
;val SET $2a
; dcb.l 104*80,$1fe0000
; 
; dc.w $106,$c42
; 
; dc.w $80
;pch2:
; dc.w 0
; dc.w $82
;pcl2:
; dc.w 0
; 
; dc.w $88,0
; 
; dc.w $ffff,$fffe       ; End copper list.

; ds.l 104*10

NullCopper:
 dc.w $ffff,$fffe

hitcol: dc.l 0

old: dc.l 0

 CNOP 0,64
SCROLLSCRN: ds.l 20*16

SCROLLOFFSET: dc.w 0
SCROLLTIMER: dc.w 100
SCROLLDIRECTION: dc.w 1
SCROLLXPOS: dc.w 0
SCROLLPOINTER: dc.l testscroll
ENDSCROLL: dc.l endtestscroll

testscroll:
;      12345678901234567890123456789012345678901234567890123456789012345678901234567890
; dc.b "The Quick Brown Fox Jumped Over The Lazy Dog!                                   "
; dc.b "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ                            "
; dc.b "The Quick Brown Fox Jumped Over The Lazy Dog!                                   "

BLANKSCROLL:
 dc.b "                                                                                "
endtestscroll: 

prot5: dc.w 0
PanelCop:

 dc.w $80
och:
 dc.w 0
 dc.w $82
ocl:
 dc.w 0

statskip:
 dc.w $1fe,0
 dc.w $1fe,0

 dc.w $10c,0
 dc.w bplcon0,$1201
 dc.w bpl1ptl
n1l:
 dc.w 0
 dc.w bpl1pth
n1h:
 dc.w 0
 dc.w $108,-24
 incbin "Panelpal"

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
 dc.w bpl6pth
p6h
 dc.w 0
 dc.w bpl6ptl
p6l
 dc.w 0
 dc.w bpl7pth
p7h
 dc.w 0
 dc.w bpl7ptl
p7l
 dc.w 0
 dc.w bpl8pth
p8h
 dc.w 0
 dc.w bpl8ptl
p8l
 dc.w 0
 

 dc.w ddfstart,$38
 dc.w ddfstop,$b8
 dc.w diwstart,$2c81
 dc.w diwstop,$2cc1
 
 dc.w bplcon0
Panelcon: dc.w $0211
 dc.w bpl1pth
p1h
 dc.w 0

 dc.w bpl1ptl
p1l
 dc.w 0


 dc.w $108,40*7
 dc.w $10a,40*7

 dc.w $ffff,$fffe

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
; ds.l 6*32*5

TEXTSCRN: dc.l 0

TEXTCOP:
 dc.w intreq,$8030

 dc.w spr0ptl
txs0l:
 dc.w 0
 dc.w spr0pth
txs0h:
 dc.w 0
 dc.w spr1ptl
txs1l:
 dc.w 0
 dc.w spr1pth
txs1h:
 dc.w 0
 dc.w spr2ptl
txs2l:
 dc.w 0
 dc.w spr2pth
txs2h:
 dc.w 0
 dc.w spr3ptl
txs3l:
 dc.w 0
 dc.w spr3pth
txs3h:
 dc.w 0
 dc.w spr4ptl
txs4l:
 dc.w 0
 dc.w spr4pth
txs4h:
 dc.w 0
 dc.w spr5ptl
txs5l:
 dc.w 0
 dc.w spr5pth
txs5h:
 dc.w 0
 dc.w spr6ptl
txs6l:
 dc.w 0
 dc.w spr6pth
txs6h:
 dc.w 0
 dc.w spr7ptl
txs7l:
 dc.w 0
 dc.w spr7pth
txs7h:
 dc.w 0


 dc.w $10c,$0088

 dc.w $1fc,$f
 dc.w diwstart,$2c81    ; Top left corner of screen.
 dc.w diwstop,$2cc1     ; Bottom right corner of screen.
 dc.w ddfstart,$38      ; Data fetch start.
 dc.w ddfstop,$c8       ; Data fetch stop.

 dc.w bplcon0
TSCP:
 dc.w $9201

 dc.w $106,$c40

 dc.w $2a01,$ff00

 dc.w col0,0
 dc.w col1
TOPLET:
TXTCOLL:
 dc.w 0
  dc.w col2
BOTLET:
 dc.w 0
 dc.w col3
ALLTEXT:
 dc.w $fff
 dc.w $106,$e40
 dc.w col3
ALLTEXTLOW:
 dc.w $0


 dc.w bpl1pth
TSPTh:
 dc.w 0
 dc.w bpl1ptl
TSPTl:
 dc.w 0

 dc.w bpl2pth
TSPTh2:
 dc.w 0
 dc.w bpl2ptl
TSPTl2:
 dc.w 0

 
 dc.w $108,0
 dc.w $10a,0

 dc.w $ffff,$fffe

********************************************
* Stuff you don't have to worry about yet. *
********************************************

closeeverything:

 jsr mt_end
 
 move.l #nullcop,d0
; move.l old,d0


;charlie  
 move.l d0,$dff080     ; Restore old copper list.
 move.w d0,ocl
 swap d0
 move.w d0,och

; move.l doslib,a6
; move.l #4,d1
; jsr -198(a6)

; move.l doslib,d0
; move.l d0,a1
; move.l 4.w,a6
; jsr CloseLib(a6)

 move.l #$dff000,a6
 move.w #$8020,dmacon(a6)
 move.w #$f,dmacon(a6)
 
; move.l 4.w,a6
; lea VBLANKInt,a1
; moveq #INTB_COPER,d0
; jsr _LVORemIntServer(a6)
 
; IFEQ CD32VER
; move.l OLDKINT,$68.w
; ENDC
; move.w saveinters,d0
; or.w #$c000,d0
; move.w d0,intena(a6)
 clr.w $dff0a8
 clr.w $dff0b8
 clr.w $dff0c8
 clr.w $dff0d8


; move.l oldview,a1
; move.l a1,d0
; move.l gfxbase,a6
; jsr -$de(a6)
 
; cmp.b #'s',mors
; beq.s leaveold
; move.w #$f8e,$dff1dc
;leaveold:
 
 jsr RELEASELEVELMEM
 jsr RELEASESCRNMEM

 move.l #0,d0
 
 rts

 

intbase: dc.l 0
gfxbase: dc.l 0
oldview: dc.l 0

stuff:

	PRSDL
	Lea	gfxname(pc),a1	
	Moveq.l	#0,d0
	Move.l	$4.w,a6	
	Jsr	-$228(a6)
	add.w d1,RVAL1
	Move.l 	d0,gfxbase
	Move.l	d0,a6				Use As Base Reg
	Move.l	34(a6),oldview
	move.l 38(a6),old
	rts

gfxname dc.b "graphics.library",0
 even
INTUNAME	dc.b	"intuition.library",0

 even


 cnop 0,64

Panel:
 dc.l 0

TimerScr: 
;ds.b 40*64

scrntab:
 ds.b 16
val SET 32
 REPT 96
 dc.b val,val,val
val SET val+1
 ENDR
 ds.b 16
 
smallscrntab:
val SET 32
 REPT 96
 dc.b val,val
val SET val+1
 ENDR

 cnop 0,64
scrn:
 incbin "ab3:includes/newborderRAW"
 ds.b 80
scrn2:
 incbin "ab3:includes/newborderRAW"
 ds.b 80


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

COMPACTMAP: ds.l 257

BIGMAP: ds.l 256*10
 
 Section Sounds,CODE_C

nullcop:
 dc.w $106,$c40
 dc.w $180,0 
 dc.w $100,$0
 dc.w $ffff,$fffe

Scream:
; incbin "ab3:sounds/Scream"
; ds.w 100
EndScream:
LowScream:
; incbin "ab3:sounds/LowScream"
; ds.w 100
EndLowScream:
BaddieGun:
; incbin "ab3:sounds/BaddieGun"
EndBaddieGun:
bass:
; incbin "ab3:sounds/backbass+drum"
bassend:
Shoot:
; incbin "ab3:sounds/fire!"
EndShoot:
Munch:
; incbin "ab3:sounds/munch"
EndMunch:
PooGun:
; incbin "ab3:sounds/shoot.dm"
EndPooGun:
Collect:
; incbin "ab3:sounds/collect"
EndCollect:
DoorNoise:
; incbin "ab3:sounds/newdoor"
EndDoorNoise:
Stomp:
; incbin "ab3:sounds/footstep3"
EndStomp:
SwitchNoise:
; incbin "ab3:sounds/switch"
EndSwitch:
Reload:
; incbin "ab3:sounds/switch1.SFX"
EndReload:

CHEATFRAME:
 dc.b 26,20,33,27,17,12
ENDCHEAT:

NoAmmo:
; incbin "ab3:sounds/noammo"
EndNoAmmo:
Splotch:
; incbin "ab3:sounds/splotch"
EndSplotch:
SplatPop:
; incbin "ab3:sounds/splatpop"
EndSplatPop:
Boom:
; incbin "ab3:sounds/boom"
EndBoom:
Hiss:
; incbin "ab3:sounds/newhiss"
EndHiss:
Howl1:
; incbin "ab3:sounds/howl1"
EndHowl1:
Howl2:
; incbin "ab3:sounds/howl2"
EndHowl2:
Pant:
; incbin "ab3:sounds/pant"
EndPant:
Whoosh:
; incbin "ab3:sounds/whoosh"
EndWhoosh:
ROAR:
; incbin "ab3:sounds/bigscream"
EndROAR
whoosh:
; incbin "ab3:sounds/flame"
Endwhoosh:
 SECTION music,code_c

UseAllChannels: dc.w 0

mt_init:move.l	mt_data,a0
	move.l	a0,a1
	add.l	#$3b8,a1
	moveq	#$7f,d0
	moveq	#0,d1
mt_loop:move.l	d1,d2
	subq.w	#1,d0
mt_lop2:move.b	(a1)+,d1
	cmp.b	d2,d1
	bgt.s	mt_loop
	dbf	d0,mt_lop2
	addq.b	#1,d2

	lea	mt_samplestarts(pc),a1
	asl.l	#8,d2
	asl.l	#2,d2
	add.l	#$43c,d2
	add.l	a0,d2
	move.l	d2,a2
	moveq	#$1e,d0
mt_lop3:clr.l	(a2)
	move.l	a2,(a1)+
	moveq	#0,d1
	move.w	42(a0),d1
	asl.l	#1,d1
	add.l	d1,a2
	add.l	#$1e,a0
	dbf	d0,mt_lop3

	or.b	#$2,$bfe001
	move.b	#$6,mt_speed
	clr.w	$dff0a8
	clr.w	$dff0b8
	clr.w	$dff0c8
	clr.w	$dff0d8
	clr.b	mt_songpos
	clr.b	mt_counter
	clr.w	mt_pattpos
	rts

mt_end:	clr.w	$dff0a8
	clr.w	$dff0b8
	clr.w	$dff0c8
	clr.w	$dff0d8
	move.w	#$f,$dff096
	rts

mt_music:
	movem.l	d0-d4/a0-a3/a5-a6,-(a7)
	move.l	mt_data,a0
	addq.b	#$1,mt_counter
	move.b	mt_counter,D0
	cmp.b	mt_speed,D0
	blt.s	mt_nonew
	clr.b	mt_counter
	bra	mt_getnew

mt_nonew:
	lea	mt_voice1(pc),a6
	lea	$dff0a0,a5
	bsr	mt_checkcom
	lea	mt_voice2(pc),a6
	lea	$dff0b0,a5
	bsr	mt_checkcom
	tst.b UseAllChannels
	beq mt_endr
 	lea	mt_voice3(pc),a6
	lea	$dff0c0,a5
	bsr	mt_checkcom
	lea	mt_voice4(pc),a6
	lea	$dff0d0,a5
	bsr	mt_checkcom
	bra	mt_endr

mt_arpeggio:
	moveq	#0,d0
	move.b	mt_counter,d0
	divs	#$3,d0
	swap	d0
	cmp.w	#$0,d0
	beq.s	mt_arp2
	cmp.w	#$2,d0
	beq.s	mt_arp1

	moveq	#0,d0
	move.b	$3(a6),d0
	lsr.b	#4,d0
	bra.s	mt_arp3
mt_arp1:moveq	#0,d0
	move.b	$3(a6),d0
	and.b	#$f,d0
	bra.s	mt_arp3
mt_arp2:move.w	$10(a6),d2
	bra.s	mt_arp4
mt_arp3:asl.w	#1,d0
	moveq	#0,d1
	move.w	$10(a6),d1
	lea	mt_periods(pc),a0
	moveq	#$24,d7
mt_arploop:
	move.w	(a0,d0.w),d2
	cmp.w	(a0),d1
	bge.s	mt_arp4
	addq.l	#2,a0
	dbf	d7,mt_arploop
	rts
mt_arp4:move.w	d2,$6(a5)
	rts

mt_getnew:
	move.l	mt_data,a0
	move.l	a0,a3
	move.l	a0,a2
	add.l	#$c,a3
	add.l	#$3b8,a2
	add.l	#$43c,a0

	moveq	#0,d0
	move.l	d0,d1
	move.b	mt_songpos,d0
	move.b	(a2,d0.w),d1
	asl.l	#8,d1
	asl.l	#2,d1
	add.w	mt_pattpos,d1
	clr.w	mt_dmacon

	lea	$dff0a0,a5
	lea	mt_voice1(pc),a6
	bsr	mt_playvoice
	lea	$dff0b0,a5
	lea	mt_voice2(pc),a6
	bsr	mt_playvoice
	tst.b UseAllChannels
	beq mt_setdma
	lea	$dff0c0,a5
	lea	mt_voice3(pc),a6
	bsr	mt_playvoice
	lea	$dff0d0,a5
	lea	mt_voice4(pc),a6
	bsr	mt_playvoice
	bra	mt_setdma

PROTCALC:
;	include "ab3:source_4000/protcalc.s"
	incbin "ab3:includes/protcalc.bin"
ENDPROTCALC:

mt_playvoice:
	move.l	(a0,d1.l),(a6)
	addq.l	#4,d1
	moveq	#0,d2
	move.b	$2(a6),d2
	and.b	#$f0,d2
	lsr.b	#4,d2
	move.b	(a6),d0
	and.b	#$f0,d0
	or.b	d0,d2
	tst.b	d2
	beq.s	mt_setregs
	moveq	#0,d3
	lea	mt_samplestarts(pc),a1
	move.l	d2,d4
	subq.l	#$1,d2
	asl.l	#2,d2
	mulu	#$1e,d4
	move.l	(a1,d2.l),$4(a6)
	move.w	(a3,d4.l),$8(a6)
	move.w	$2(a3,d4.l),$12(a6)
	move.w	$4(a3,d4.l),d3
	tst.w	d3
	beq.s	mt_noloop
	move.l	$4(a6),d2
	asl.w	#1,d3
	add.l	d3,d2
	move.l	d2,$a(a6)
	move.w	$4(a3,d4.l),d0
	add.w	$6(a3,d4.l),d0
	move.w	d0,8(a6)
	move.w	$6(a3,d4.l),$e(a6)
	move.w	$12(a6),d0
	asr.w #2,d0
	move.w d0,$8(a5)
	bra.s	mt_setregs
mt_noloop:
	move.l	$4(a6),d2
	add.l	d3,d2
	move.l	d2,$a(a6)
	move.w	$6(a3,d4.l),$e(a6)
	move.w	$12(a6),d0
	asr.w #2,d0
	move.w d0,$8(a5)
mt_setregs:
	move.w	(a6),d0
	and.w	#$fff,d0
	beq	mt_checkcom2
	move.b	$2(a6),d0
	and.b	#$F,d0
	cmp.b	#$3,d0
	bne.s	mt_setperiod
	bsr	mt_setmyport
	bra	mt_checkcom2
mt_setperiod:
	move.w	(a6),$10(a6)
	and.w	#$fff,$10(a6)
	move.w	$14(a6),d0
	move.w	d0,$dff096
	clr.b	$1b(a6)

	move.l	$4(a6),(a5)
	move.w	$8(a6),$4(a5)
	move.w	$10(a6),d0
	and.w	#$fff,d0
	move.w	d0,$6(a5)
	move.w	$14(a6),d0
	or.w	d0,mt_dmacon
	bra	mt_checkcom2

mt_setdma:
 	move.w #250,d0
mt_wait:
 	add.w #1,testchip
 	dbra d0,mt_wait
	move.w	mt_dmacon,d0
	or.w	#$8000,d0
	and.w #%1111111111110011,d0
	move.w	d0,$dff096
	move.w #250,d0
mt_wait2:
	add.w #1,testchip
	dbra	d0,mt_wait2
	lea	$dff000,a5
	tst.b UseAllChannels
	beq.s noall
	lea	mt_voice4(pc),a6
	move.l	$a(a6),$d0(a5)
	move.w	$e(a6),$d4(a5)
	lea	mt_voice3(pc),a6
	move.l	$a(a6),$c0(a5)
	move.w	$e(a6),$c4(a5)
noall:
	lea	mt_voice2(pc),a6
	move.l	$a(a6),$b0(a5)
	move.w	$e(a6),$b4(a5)
	lea	mt_voice1(pc),a6
	move.l	$a(a6),$a0(a5)
	move.w	$e(a6),$a4(a5)

	add.w	#$10,mt_pattpos
	cmp.w	#$400,mt_pattpos
	bne.s	mt_endr
mt_nex:	clr.w	mt_pattpos
	clr.b	mt_break
	addq.b	#1,mt_songpos
	and.b	#$7f,mt_songpos
	move.b	mt_songpos,d1
;	cmp.b	mt_data+$3b6,d1
;	bne.s	mt_endr
;	move.b	mt_data+$3b7,mt_songpos
mt_endr:tst.b	mt_break
	bne.s	mt_nex
	movem.l	(a7)+,d0-d4/a0-a3/a5-a6
	rts

mt_setmyport:
	move.w	(a6),d2
	and.w	#$fff,d2
	move.w	d2,$18(a6)
	move.w	$10(a6),d0
	clr.b	$16(a6)
	cmp.w	d0,d2
	beq.s	mt_clrport
	bge.s	mt_rt
	move.b	#$1,$16(a6)
	rts
mt_clrport:
	clr.w	$18(a6)
mt_rt:	rts

CODESTORE: dc.l 0

mt_myport:
	move.b	$3(a6),d0
	beq.s	mt_myslide
	move.b	d0,$17(a6)
	clr.b	$3(a6)
mt_myslide:
	tst.w	$18(a6)
	beq.s	mt_rt
	moveq	#0,d0
	move.b	$17(a6),d0
	tst.b	$16(a6)
	bne.s	mt_mysub
	add.w	d0,$10(a6)
	move.w	$18(a6),d0
	cmp.w	$10(a6),d0
	bgt.s	mt_myok
	move.w	$18(a6),$10(a6)
	clr.w	$18(a6)
mt_myok:move.w	$10(a6),$6(a5)
	rts
mt_mysub:
	sub.w	d0,$10(a6)
	move.w	$18(a6),d0
	cmp.w	$10(a6),d0
	blt.s	mt_myok
	move.w	$18(a6),$10(a6)
	clr.w	$18(a6)
	move.w	$10(a6),$6(a5)
	rts

mt_vib:	move.b	$3(a6),d0
	beq.s	mt_vi
	move.b	d0,$1a(a6)

mt_vi:	move.b	$1b(a6),d0
	lea	mt_sin(pc),a4
	lsr.w	#$2,d0
	and.w	#$1f,d0
	moveq	#0,d2
	move.b	(a4,d0.w),d2
	move.b	$1a(a6),d0
	and.w	#$f,d0
	mulu	d0,d2
	lsr.w	#$6,d2
	move.w	$10(a6),d0
	tst.b	$1b(a6)
	bmi.s	mt_vibmin
	add.w	d2,d0
	bra.s	mt_vib2
mt_vibmin:
	sub.w	d2,d0
mt_vib2:move.w	d0,$6(a5)
	move.b	$1a(a6),d0
	lsr.w	#$2,d0
	and.w	#$3c,d0
	add.b	d0,$1b(a6)
	rts

mt_nop:	move.w	$10(a6),$6(a5)
	rts


mt_checkcom:
	move.w	$2(a6),d0
	and.w	#$fff,d0
	beq.s	mt_nop
	move.b	$2(a6),d0
	and.b	#$f,d0
	tst.b	d0
	beq	mt_arpeggio
	cmp.b	#$1,d0
	beq.s	mt_portup
	cmp.b	#$2,d0
	beq	mt_portdown
	cmp.b	#$3,d0
	beq	mt_myport
	cmp.b	#$4,d0
	beq	mt_vib
	move.w	$10(a6),$6(a5)
	cmp.b	#$a,d0
	beq.s	mt_volslide
	rts

mt_volslide:
	moveq	#0,d0
	move.b	$3(a6),d0
	lsr.b	#4,d0
	tst.b	d0
	beq.s	mt_voldown
	add.w	d0,$12(a6)
	cmp.w	#$40,$12(a6)
	bmi.s	mt_vol2
	move.w	#$40,$12(a6)
mt_vol2:move.w	$12(a6),d0
	asr.w #2,d0
	move.w d0,$8(a5)
	rts

mt_voldown:
	moveq	#0,d0
	move.b	$3(a6),d0
	and.b	#$f,d0
	sub.w	d0,$12(a6)
	bpl.s	mt_vol3
	clr.w	$12(a6)
mt_vol3:move.w	$12(a6),d0
	asr.w #2,d0
	move.w d0,$8(a5)
	rts

mt_portup:
	moveq	#0,d0
	move.b	$3(a6),d0
	sub.w	d0,$10(a6)
	move.w	$10(a6),d0
	and.w	#$fff,d0
	cmp.w	#$71,d0
	bpl.s	mt_por2
	and.w	#$f000,$10(a6)
	or.w	#$71,$10(a6)
mt_por2:move.w	$10(a6),d0
	and.w	#$fff,d0
	move.w	d0,$6(a5)
	rts

mt_portdown:
	clr.w	d0
	move.b	$3(a6),d0
	add.w	d0,$10(a6)
	move.w	$10(a6),d0
	and.w	#$fff,d0
	cmp.w	#$358,d0
	bmi.s	mt_por3
	and.w	#$f000,$10(a6)
	or.w	#$358,$10(a6)
mt_por3:move.w	$10(a6),d0
	and.w	#$fff,d0
	move.w	d0,$6(a5)
	rts

mt_checkcom2:
	move.b	$2(a6),d0
	and.b	#$f,d0
	cmp.b	#$e,d0
	beq.s	mt_setfilt
	cmp.b	#$d,d0
	beq.s	mt_pattbreak
	cmp.b	#$b,d0
	beq.s	mt_posjmp
	cmp.b	#$c,d0
	beq.s	mt_setvol
	cmp.b	#$f,d0
	beq.s	mt_setspeed
	rts

mt_setfilt:
	move.b	$3(a6),d0
	and.b	#$1,d0
	asl.b	#$1,d0
	and.b	#$fd,$bfe001
	or.b	d0,$bfe001
	rts
mt_pattbreak:
	not.b	mt_break
	rts
mt_posjmp:
	st reachedend
	move.b	$3(a6),d0
	subq.b	#$1,d0
	move.b	d0,mt_songpos
	not.b	mt_break
	rts
mt_setvol:
	cmp.b	#$40,$3(a6)
	ble.s	mt_vol4
	move.b	#$40,$3(a6)
mt_vol4:move.b	$3(a6),d0
	asr.w #2,d0
	move.w d0,$8(a5)
	rts
mt_setspeed:
	cmp.b	#$1f,$3(a6)
	ble.s	mt_sets
	move.b	#$1f,$3(a6)
mt_sets:move.b	$3(a6),d0
	beq.s	mt_rts2
	move.b	d0,mt_speed
	clr.b	mt_counter
mt_rts2:rts

mt_sin:
 DC.b $00,$18,$31,$4a,$61,$78,$8d,$a1,$b4,$c5,$d4,$e0,$eb,$f4,$fa,$fd
 DC.b $ff,$fd,$fa,$f4,$eb,$e0,$d4,$c5,$b4,$a1,$8d,$78,$61,$4a,$31,$18

mt_periods:
 DC.w $0358,$0328,$02fa,$02d0,$02a6,$0280,$025c,$023a,$021a,$01fc,$01e0
 DC.w $01c5,$01ac,$0194,$017d,$0168,$0153,$0140,$012e,$011d,$010d,$00fe
 DC.w $00f0,$00e2,$00d6,$00ca,$00be,$00b4,$00aa,$00a0,$0097,$008f,$0087
 DC.w $007f,$0078,$0071,$0000,$0000

reachedend: dc.b 0
mt_speed:	DC.b	6
mt_songpos:	DC.b	0
mt_pattpos:	DC.w	0
mt_counter:	DC.b	0

mt_break:	DC.b	0
mt_dmacon:	DC.w	0
mt_samplestarts:DS.L	$1f
mt_voice1:	DS.w	10
		DC.w	1
		DS.w	3
mt_voice2:	DS.w	10
		DC.w	2
		DS.w	3
mt_voice3:	DS.w	10
		DC.w	4
		DS.w	3
mt_voice4:	DS.w	10
		DC.w	8
		DS.w	3

CHEATPTR: dc.l 0
CHEATNUM: dc.l 0

testchip: dc.w 0

;/* End of File */
mt_data: dc.l 0
tstchip: dc.l 0
 include "SERIAL_NIGHTMARE"

ingame:
; incbin "ab3:includes/ingame"
gameover: incbin "ab3:includes/gameover"
welldone: incbin "ab3:includes/welldone"


