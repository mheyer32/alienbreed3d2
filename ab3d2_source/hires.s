				include	"system.i"
				include	"macros.i"
				include	"defs.i"

				opt		o+

				xref	_custom
				xref	_ciaa

				IFND	CHEESEY
CHEESEY			equ		0
				ENDC

;*************************************************
;* Stuff to do to get a C2P version:
;* Change copperlist
;* Change wall drawing
;* change floor drawing
;* change object drawing
;* change polygon drawing (ugh)
;* Write a palette generator program in AMOS
;* to provide a good 256 colour palette and
;* convert all graphics files specified
;* (possibly included in the game linker
;* program).
;* Possibly change the wall/floor/object
;* palettes to look nicer with more shades.
;* RE-implement stippling (if not present)
;* as it will look gorgeous now.
;*************************************************

CD32VER			equ		0

FS_WIDTH		equ		320
FS_HEIGHT		equ		232
SMALL_WIDTH		equ		192
SMALL_HEIGHT	equ		160

SCREENWIDTH		equ		320

maxscrdiv		EQU		8
max3ddiv		EQU		5
PLR_HEIGHT	EQU		12*1024
playercrouched	EQU		8*1024
scrheight		EQU		80
intreqrl		equ		$01f

				section code,code

_start:
				movem.l	d1-a6,-(sp)
**************************************************************************************
;ich bin hack  -----  invert FULLSCRTEMP to start game in fullsreen if cpu is 68040 AL
				;movem.l	d0-d1/a0,-(a7)
				move.l	4.w,a0
				move.b	$129(a0),d0
				move.l	#68040,d1	;68040
				btst	#$03,d0
				beq.b	.not040
				not.b	FULLSCRTEMP
.not040
**************************************************************************************

				lea.l	MiscResourceName,a1
				CALLEXEC OpenResource			;Open "misc.resource"
				tst.l	d0
                ;beq.s   fail
				move.l	d0,MiscResourceBase
				move.l	d0,a6

				move.l	#MR_SERIALPORT,d0		;We want these bits
				lea.l	AppName(pc),a1
				jsr		_LVOAllocMiscResource(a6)
				tst.l	d0
                ;beq.s   fail
				move.l	#MR_SERIALBITS,d0
				lea.l	AppName(pc),a1
				jsr		_LVOAllocMiscResource(a6)
				tst.l	d0
                ;beq.s   fail

				; now we have the resource, may poke the hardware bits
				move.w	#31,_custom+serper			;19200 baud, 8 bits, no parity

				lea.l	PotgoResourceName,a1
				CALLEXEC OpenResource			;Open "potgo.resource"
				tst.l	d0
				;beq.s   fail
				move.l	d0,PotgoResourceBase
				move.l	d0,a6

				move.l	#%110000000000,d0		;We want these bits
				jsr		_LVOAllocPotBits(a6)
				tst.l	d0
				;beq.s   fail

				st		GOURSEL

				lea		VBLANKInt(pc),a1
				moveq	#INTB_VERTB,d0
				CALLEXEC AddIntServer

				lea	timername,a0
				lea	timerrequest,a1
				moveq	#0,d0
				moveq	#0,d1
				jsr	_LVOOpenDevice(a6)
				move.l	timerrequest+IO_DEVICE,timerbase
				move.l	d0,timerflag
				;bne	error_exit

				IFEQ	CD32VER
				lea		KEYInt(pc),a1
				moveq	#INTB_PORTS,d0
				CALLEXEC AddIntServer
				ENDC

				; init default control method
				IFNE	CD32VER
				clr.b	Plr1_Keys_b
				clr.b	Plr1_Path_b
				clr.b	Plr1_Mouse_b
				st		Plr1_Joystick_b
				clr.b	Plr2_Keys_b
				clr.b	Plr2_Path_b
				clr.b	Plr2_Mouse_b
				st		Plr2_Joystick_b
				ELSE
				clr.b	Plr1_Keys_b
				clr.b	Plr1_Path_b
				st		Plr1_Mouse_b
				clr.b	Plr1_Joystick_b
				clr.b	Plr2_Keys_b
				clr.b	Plr2_Path_b
				st		Plr2_Mouse_b
				clr.b	Plr2_Joystick_b
				ENDC

				; allocate chunky render buffer in fastmem
				move.l	#MEMF_ANY|MEMF_CLEAR,d1
				move.l	#VID_FAST_BUFFER_SIZE,d0
				CALLEXEC AllocVec
				move.l	d0,Vid_FastBufferAllocPtr_l
				;align to 16byte for best C2P perf
				moveq.l	#15,d1
				add.l	d1,d0
				moveq	#-16,d1					; $F0
				and.l	d1,d0
				move.l	d0,Vid_FastBufferPtr_l

				; Setup constant table
				move.l	#consttab,a0
				moveq	#1,d0
				move.w	#8191,d1

fillconst:
				move.l	#16384*64,d2
				divs.l	d0,d2
; ext.l d2	;c#
				move.l	#64*64*65536,d3
				divs.l	d2,d3
; move.l d3,d4
; asr.l #6,d4
				move.l	d3,(a0)+				;e#

				asr.l	#1,d2					; c#/2.0
				sub.l	#40*64,d2				; d#
				muls.l	d3,d2					; d#*e#

				asr.l	#6,d2
				move.l	d2,(a0)+

				addq	#1,d0

				dbra	d1,fillconst

				jsr		START

				rts

;*******************************************************************************

VID_FAST_BUFFER_SIZE		equ		SCREENWIDTH*256+15		; screen size plus alignment
Vid_FastBufferPtr_l:		dc.l	0	; aligned address
Vid_FastBufferAllocPtr_l:	dc.l	0	; allocated address

;* Load level into buffers.
				clr.b	doanything
				clr.b	dosounds

; DRAW TEXT SCREEN

Game_ShowIntroText:
				move.l	Lvl_IntroTextPtr_l,a0
				move.w	PLOPT,d0
				muls	#82*16,d0
				add.l	d0,a0
				move.w	#15,d7
				move.w	#0,d0

.next_line_loop:
				move.l	Vid_TextScreenPtr_l,a1
				jsr		Draw_LineOfText

				addq	#1,d0
				add.w	#82,a0
				dbra	d7,.next_line_loop
				rts

FONTADDRS:
				dc.l	ENDFONT0,CHARWIDTHS0
				dc.l	ENDFONT1,CHARWIDTHS1
				dc.l	ENDFONT2,CHARWIDTHS2

ENDFONT0:
				incbin	"endfont0"
CHARWIDTHS0:
				incbin	"charwidths0"
ENDFONT1:
; incbin "endfont1"
CHARWIDTHS1:
; incbin "charwidths1"
ENDFONT2:
; incbin "endfont2"
CHARWIDTHS2:
; incbin "charwidths2"

				even

Draw_LineOfText:
				movem.l	d0/a0/d7,-(a7)
				muls	#80*16,d0
				add.l	d0,a1					; screen pointer
				move.l	#FONTADDRS,a3
				moveq	#0,d0
				move.b	(a0)+,d0
				move.l	(a3,d0.w*8),a2
				move.l	4(a3,d0.w*8),a3
				moveq	#0,d4
				moveq	#0,d1					; width counter:
				move.w	#79,d6
				tst.b	(a0)+
				beq.s	.not_centred

				moveq	#-1,d5
				move.l	a0,a4
				moveq	#0,d2
				moveq	#0,d3
				move.w	#79,d0					; number of chars

.addup:
				addq	#1,d5
				move.b	(a4)+,d2
				move.b	-32(a3,d2.w),d4
				add.w	d4,d3
				cmp.b	#32,d2
				beq.s	.dont_put_in

				move.w	d5,d6
				move.w	d3,d1

.dont_put_in:
				dbra	d0,.addup
				asr.w	#1,d1
				neg.w	d1
				add.w	#SCREENWIDTH,d1			; horiz pos of start x

.not_centred:
				move.w	d6,d7

.do_char:
				moveq	#0,d2
				move.b	(a0)+,d2
				sub.w	#32,d2
				moveq	#0,d6
				move.b	(a3,d2.w),d6
				asl.w	#5,d2
				lea		(a2,d2.w),a4			; char font
val				SET		0
				REPT	16
				move.w	(a4)+,d0
				bfins	d0,val(a1){d1:d6}
val				SET		val+80
				ENDR
				add.w	d6,d1
				dbra	d7,.do_char
				movem.l	(a7)+,d0/a0/d7
				rts

Game_ClearIntroText:
				move.l	Vid_TextScreenPtr_l,a0
				move.w	#(10240/16)-1,d0
				move.l	#$0,d1
.lll
				move.l	d1,(a0)+
				move.l	d1,(a0)+
				move.l	d1,(a0)+
				move.l	d1,(a0)+
				move.l	d1,(a0)+
				move.l	d1,(a0)+
				move.l	d1,(a0)+
				move.l	d1,(a0)+
				dbra	d0,.lll
				rts


doslibname:		DOSNAME
MiscResourceName: MISCNAME
PotgoResourceName: POTGONAME

				align	4
COPYLINK:			dc.l	0
_DOSBase:			dc.l	0
MiscResourceBase:	dc.l	0
PotgoResourceBase:	dc.l	0

Plr_MultiplayerType_b:	dc.w	0	; CHAR enum - m(aster), s(lave), n(either)

PLR_MASTER		equ 'm' ; two player master
PLR_SLAVE		equ 's' ; two player slave
PLR_NEITHER		equ 'n' ; Single player?

LDname:			dc.b	'ab3:levels/level_'
LEVA:
				dc.b	'a/twolev.bin',0
				even
LDhandle:		dc.l	0
LGname:			dc.b	'ab3:levels/level_'
LEVB:
				dc.b	'a/twolev.graph.bin',0
				even
LGhandle:		dc.l	0
LCname:			dc.b	'ab3:levels/level_'
LEVC:
				dc.b	'a/twolev.clips',0
				even
LChandle:		dc.l	0
LLname:			dc.b	'ab3:levels/level_'
LEVD:
				dc.b	'a/twolev.map',0
				even
LLFname:		dc.b	'ab3:levels/level_'
LEVE:
				dc.b	'a/twolev.flymap',0
				even
LLhandle:		dc.l	0

				cnop	0,4

Prefsname:		dc.b	'ram:prefs',0
				even
Prefshandle:	dc.l	0

AppName:		dc.b	'TheKillingGrounds',0
				cnop	0,4

VBLANKInt:
				dc.l	0,0						;is_Node ln_Succ, ln_Pred
				dc.b	NT_INTERRUPT,9			;is_Node ln_Type; ln_Pri
				dc.l	AppName					;is_Node ln_Name
				dc.l	0						;is_Data
				dc.l	VBlankInterrupt			;is_Code

KEYInt:
				dc.l	0,0						;is_Node ln_Succ, ln_Pred
				dc.b	NT_INTERRUPT,127		;is_Node ln_Type; ln_Pri
				dc.l	AppName					;is_Node ln_Name
				dc.l	0						;is_Data
				dc.l	key_interrupt			;is_Code


Game_Begin:
;				move.w	#0,TXTCOLL
;				move.w	#0,MIXCOLL
;				move.w	#0,TOPCOLL
;
;				bsr		Game_ClearIntroText
;
;				cmp.b	#PLR_NEITHER,Plr_MultiplayerType_b
;				bne.s	.notext
;				bsr		Game_ShowIntroText
.notext

;charlie
;				move.l	#TEXTCOP,_custom+cop1lc

; Fade in Level Text
;				move.w	#$10,d0
;				move.w	#7,d1

;.fdup
;				move.w	d0,TXTCOLL
;				move.w	d0,MIXCOLL
;				add.w	#$121,d0
;.wtframe:
;				btst	#5,_custom+intreqrl
;				beq.s	.wtframe
;				move.w	#$0020,_custom+intreq
;				dbra	d1,.fdup

				move.l	#_custom,a6
				jsr		SETPLAYERS

				move.l	#MEMF_ANY,IO_MemType_l
				move.l	#LLname,a0
				jsr		IO_LoadFile
				move.l	d0,Lvl_WalkLinksPtr_l
*************************************

				move.l	#MEMF_ANY,IO_MemType_l
				move.l	#LLFname,a0
				jsr		IO_LoadFile
				move.l	d0,Lvl_FlyLinksPtr_l

				moveq	#0,d1
				move.b	LEVA,d1
				sub.b	#'a',d1
				lsl.w	#6,d1
				move.l	GLF_DatabasePtr_l,a0
				lea		GLFT_LevelMusic_l(a0),a0

				move.l	#MEMF_CHIP,IO_MemType_l
				jsr		IO_LoadFile
				move.l	d0,Lvl_MusicPtr_l
*************************************

				move.l	#MEMF_ANY,IO_MemType_l
				move.l	#LDname,a0
				jsr		IO_LoadFile
				move.l	d0,Lvl_DataPtr_l
*************************************

				move.l	#MEMF_ANY,IO_MemType_l
				move.l	#LGname,a0
				jsr		IO_LoadFile
				move.l	d0,Lvl_GraphicsPtr_l
*************************************

				move.l	#MEMF_ANY,IO_MemType_l
				move.l	#LCname,a0
				jsr		IO_LoadFile
				move.l	d0,Lvl_ClipsPtr_l
*************************************

noload:
				; What for?
				IFNE	CD32VER
				move.l	#115,d1
				CALLDOS	Delay
				ENDC

;****************************
;* Initialize level
;****************************
;* Poke all clip offsets into
;* correct bit of level data.
;****************************
				move.l	Lvl_GraphicsPtr_l,a0
				move.l	12(a0),a1
				add.l	a0,a1
				move.l	a1,Lvl_ZoneGraphAddsPtr_l
				move.l	(a0),a1
				add.l	a0,a1
				move.l	a1,Lvl_DoorDataPtr_l
				move.l	4(a0),a1
				add.l	a0,a1
				move.l	a1,Lvl_LiftDataPtr_l
				move.l	8(a0),a1
				add.l	a0,a1
				move.l	a1,Lvl_SwitchDataPtr_l
				adda.w	#16,a0
				move.l	a0,Lvl_ZoneAddsPtr_l

				move.l	Lvl_DataPtr_l,a4
				lea		160*10(a4),a1

				lea		54(a1),a2
				move.l	a2,Lvl_ControlPointCoordsPtr_l
				move.w	12(a1),Lvl_NumControlPoints_w
				move.w	14(a1),Lvl_NumPoints_w

				move.l	16+6(a1),a2
				add.l	a4,a2
				move.l	a2,Lvl_PointsPtr_l
				move.w	8+6(a1),d0
				lea		4(a2,d0.w*4),a2
				move.l	a2,PointBrights
				move.w	16(a1),d0
				addq	#1,d0
				muls	#80,d0
				add.l	d0,a2
				move.l	a2,Lvl_ZoneBorderPointsPtr_l

				move.l	20+6(a1),a2
				add.l	a4,a2
				move.l	a2,Lvl_FloorLinesPtr_l
				move.w	-2(a2),ENDZONE
				move.l	24+6(a1),a2
				add.l	a4,a2
				move.l	a2,Lvl_ObjectDataPtr_l
*****************************************
* Just for charles

; move.w #$6060,6(a2)
; move.l #$d0000,8(a2)
; sub.w #40,4(a2)
; move.w #45*256+45,14(a2)
****************************************
				move.l	28+6(a1),a2
				add.l	a4,a2
				move.l	a2,Plr_ShotDataPtr_l
				move.l	32+6(a1),a2
				add.l	a4,a2
				move.l	a2,NastyShotDataPtr_l

				add.l	#64*20,a2
				move.l	a2,OtherNastyDataPtr_vl

				move.l	36+6(a1),a2
				add.l	a4,a2
				move.l	a2,Lvl_ObjectPointsPtr_l
				move.l	40+6(a1),a2
				add.l	a4,a2
				move.l	a2,Plr1_ObjectPtr_l
				move.l	44+6(a1),a2
				add.l	a4,a2
				move.l	a2,Plr2_ObjectPtr_l
				move.w	14+6(a1),Lvl_NumObjectPoints_w

; bra noclips

				move.l	Lvl_ClipsPtr_l,a2
				moveq	#0,d0
				move.w	10+6(a1),d7				;numzones
				move.w	d7,NUMZONES

assignclips:
				move.l	(a0)+,a3
				add.l	a4,a3					; pointer to a zone
				adda.w	#ZoneT_ListOfGraph_w,a3		; pointer to zonelist

dowholezone:
				tst.w	(a3)
				blt.s	nomorethiszone
				tst.w	2(a3)
				blt.s	thisonenull

				move.l	d0,d1
				asr.l	#1,d1
				move.w	d1,2(a3)

findnextclip:
				cmp.w	#-2,(a2,d0.l)
				beq.s	foundnextclip
				addq.l	#2,d0
				bra.s	findnextclip
foundnextclip:
				addq.l	#2,d0

thisonenull:
				addq	#8,a3
				bra.s	dowholezone
nomorethiszone:
				dbra	d7,assignclips

				lea		(a2,d0.l),a2
				move.l	a2,Lvl_ConnectTablePtr_l

noclips:

************************************

; cmp.b #'k',Prefsfile
; bne.s nkb

;nkb:
; cmp.b #PLR_MASTER,Prefsfile
; bne.s nmc
; clr.b Plr1_Keys_b
; clr.b Plr1_Path_b
; st Plr1_Mouse_b
; clr.b Plr1_Joystick_b
;nmc:
; cmp.b #'j',Prefsfile
; bne.s njc
; clr.b Plr1_Keys_b
; clr.b Plr1_Path_b
; clr.b Plr1_Mouse_b
; st Plr1_Joystick_b
;njc:

				clr.b	Plr1_StoodInTop_b
				move.l	#PLR_HEIGHT,Plr1_SnapHeight_l

				move.l	#empty,pos1LEFT
				move.l	#empty,pos2LEFT
				move.l	#empty,pos1RIGHT
				move.l	#empty,pos2RIGHT
				move.l	#empty,pos0LEFT
				move.l	#empty,pos3LEFT
				move.l	#empty,pos0RIGHT
				move.l	#empty,pos3RIGHT
				move.l	#emptyend,Samp0endLEFT
				move.l	#emptyend,Samp1endLEFT
				move.l	#emptyend,Samp0endRIGHT
				move.l	#emptyend,Samp1endRIGHT
				move.l	#emptyend,Samp2endLEFT
				move.l	#emptyend,Samp3endLEFT
				move.l	#emptyend,Samp2endRIGHT
				move.l	#emptyend,Samp3endRIGHT

				bset.b	#1,$bfe001

; jmp stuff
;endstuff:
				; clear audio modulation settings
				move.w	#$00ff,_custom+adkcon

				; FIXME: reimplement level blurb
; move.l #Blurbfield,$dff080

				clr.w	ScreenBufferIndex

.tryAgain		move.l	ScreenBuffers,a1
				move.l	MainScreen,a0
				CALLINT	ChangeScreenBuffer
				tst.l	d0
				beq.s	.tryAgain

				clr.b	WaitForDisplayMsg

****************************
				jsr		Plr_Initialise
; bsr initobjpos
****************************

				; setup audio channels
				move.l	#$dff000,a6

				move.l	#null,$dff0a0
				move.w	#100,$dff0a4
				move.w	#443,$dff0a6
				move.w	#63,$dff0a8

				move.l	#null2,$dff0b0
				move.w	#100,$dff0b4
				move.w	#443,$dff0b6
				move.w	#63,$dff0b8

				move.l	#null4,$dff0c0
				move.w	#100,$dff0c4
				move.w	#443,$dff0c6
				move.w	#63,$dff0c8

				move.l	#null3,$dff0d0
				move.w	#100,$dff0d4
				move.w	#443,$dff0d6
				move.w	#63,$dff0d8

				move.l	#tab,a1
				move.w	#64,d7
				move.w	#0,d6
outerlop
				move.l	#pretab,a0
				move.w	#255,d5
scaledownlop:
				move.b	(a0)+,d0
				ext.w	d0
				ext.l	d0 ; // ext.b ?
				muls	d6,d0
				asr.l	#6,d0
				move.b	d0,(a1)+
				dbra	d5,scaledownlop
				addq	#1,d6
				dbra	d7,outerlop

				move.l	#$dff000,a6

				; disable audio dma
				move.w	#DMAF_AUDIO,dmacon(a6)
				; enable audio dma
				move.w	#DMAF_SETCLR!DMAF_MASTER!DMAF_AUDIO,dmacon(a6)

				move.w	#$0,potgo(a6)
				move.w	#0,Conditions

				cmp.b	#PLR_NEITHER,Plr_MultiplayerType_b
				beq.s	.nokeys
				move.w	#%111111111111,Conditions
.nokeys:
				move.l	#KeyMap,a5
				clr.b	$45(a5)

				move.l	Lvl_MusicPtr_l,mt_data
				clr.b	UseAllChannels

; cmp.b #'b',Prefsfile+3
; bne.s .noback

*********************************

				st		CHANNELDATA
				jsr		mt_init

*********************************


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
				st		CHANNELDATA
				st		CHANNELDATA+8
; st CHANNELDATA+16
; st CHANNELDATA+24
;noreserve:

; st CHANNELDATA
; st CHANNELDATA+8

				move.l	SampleList+6*8,pos0LEFT
				move.l	SampleList+6*8+4,Samp0endLEFT
				move.l	#PLR_HEIGHT,Plr1_SnapTargHeight_l
				move.l	#PLR_HEIGHT,Plr1_SnapHeight_l
				move.l	#PLR_HEIGHT,Plr2_SnapTargHeight_l
				move.l	#PLR_HEIGHT,Plr2_SnapHeight_l

; cmp.b #PLR_NEITHER,Plr_MultiplayerType_b
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

				jsr		CLEARKEYBOARD
; jsr MAKEBACKROUT

				clr.b	MASTERQUITTING

				cmp.b	#PLR_NEITHER,Plr_MultiplayerType_b
				seq		SLAVEQUITTING

; move.w #200,PLAYERTWOHEALTH
; move.w #200,PLAYERONEHEALTH

				DataCacheOn

				move.l	#0,hitcol

;				cmp.b	#PLR_NEITHER,Plr_MultiplayerType_b 	; 0xABADCAFE - commented out as dependent branch commented out
;				bne.s	NOCLTXT		; 0xABADCAFE - commented out to avoid "branch converted to nop"


; Wait for mouse button, then fade out level text
;				move.b	#0,lastpressed
;.wtpress
;				btst	#6,$bfe001
;				beq.s	CLOSETXT
;				btst	#7,$bfe001
;				beq.s	CLOSETXT
;				tst.b	lastpressed
;				beq.s	.wtpress
;
;CLOSETXT:
;
;
;				move.w	#$8f8,d0
;				move.w	#7,d1
;
;.fdup
;				move.w	d0,TXTCOLL
;				move.w	d0,MIXCOLL
;				sub.w	#$121,d0
;.wtframe:
;				btst	#5,$dff000+intreqrl
;				beq.s	.wtframe
;				move.w	#$0020,$dff000+intreq
;				dbra	d1,.fdup
;
;				move.w	#0,TXTCOLL
;				move.w	#0,MIXCOLL

NOCLTXT:

				;FIXME: need to load the game palette here?

				clr.b	Plr1_Ducked_b
				clr.b	Plr2_Ducked_b
				clr.b	Plr1_TmpDucked_b
				clr.b	Plr2_TmpDucked_b

********************************************

;	jmp docredits

********************************************


				st		doanything
				st		dosounds

				jsr		AI_ClearNastyMem

				move.l	#COMPACTMAP,a0
				move.l	a0,LastZonePtr_l
				move.w	#255,d0

.clear_map_loop:
				move.l	#0,(a0)+
				dbra	d0,.clear_map_loop

				move.l	#COMPACTMAP,a0
				move.l	#BIGMAP,a1

				bra		NOALLWALLS

				move.l	Lvl_ZoneGraphAddsPtr_l,a2
DOALLWALLS:
				move.l	(a2),d0
				beq.s	nomorezones
				move.l	d0,a3

				addq	#8,a2

				add.l	Lvl_GraphicsPtr_l,a3
				addq	#2,a3
				move.l	a1,a4

; DOLOWERROOM

innerwalls:
				move.b	(a3),d1
				move.b	1(a3),d0
				bne		doneinner

				tst.b	d1
				blt		noid

				move.b	d1,d3
				and.w	#15,d1

				moveq	#0,d0
				move.w	d1,d2
				add.w	d1,d1
				add.w	d2,d1
				addq	#1,d1
				bset	d1,d0
				btst	#4,d3
				beq.s	.no_door
				addq	#1,d1
				bset	d1,d0

.no_door:
				or.l	d0,(a0)
				move.w	2(a3),(a4)
				move.w	4(a3),2(a4)

noid:
				add.w	#30,a3
				addq	#4,a4

				bra		innerwalls

doneinner:

				add.w	#40,a1
				addq	#4,a0

				bra		DOALLWALLS
nomorezones:

NOALLWALLS:
				move.w	#SMALL_WIDTH/2,Vid_CentreX_w
				move.w	#SMALL_WIDTH,Vid_RightX_w
				move.w	#SMALL_HEIGHT,Vid_BottomY_w
				move.w	#SMALL_HEIGHT/2,TOTHEMIDDLE
				clr.b	Vid_FullScreen_b
				move.l	scrn,a0
				jsr		WIPEDISPLAY

				move.l	scrn2,a0
				jsr		WIPEDISPLAY

				st		PLAYERONEGUNS+1
				st		PLAYERTWOGUNS+1
				move.w	#100,timetodamage
				move.w	#299,d0
				move.l	#AI_Damaged_vw,a0

CLRDAM:
				move.w	#0,(a0)+
				dbra	d0,CLRDAM

				moveq	#0,d0
				move.w	d0,STOPOFFSET
				neg.w	d0
				add.w	TOTHEMIDDLE,d0
				move.w	d0,SMIDDLEY
				muls	#SCREENWIDTH,d0
				move.l	d0,SBIGMIDDLEY

				move.w	#0,PLR1_AIMSPD
				move.w	#0,PLR2_AIMSPD

; init pointer to chipmem render buffers
				move.l	scrn,SCRNSHOWPT
				move.l	scrn2,SCRNDRAWPT

				move.l	#MESSAGEBUFFER,a0
				move.w	#19,d0
clrmessbuff:
				move.l	#0,(a0)+
				dbra	d0,clrmessbuff

				move.l	#nullmessage,d0
				jsr		SENDMESSAGE

				clr.b	PLR2_fire
				clr.b	Plr2_TmpFire_b
				clr.b	PLR2_SPCTAP
				clr.b	Plr2_TmpSpcTap_b

				clr.b	PLR1_dead
				clr.b	PLR2_dead

				move.l	Plr1_ObjectPtr_l,a0
				move.l	Plr2_ObjectPtr_l,a1
				move.w	#0,EntT_ImpactX_w(a0)
				move.w	#0,EntT_ImpactY_w(a0)
				move.w	#0,EntT_ImpactZ_w(a0)
				move.w	#0,EntT_ImpactX_w(a1)
				move.w	#0,EntT_ImpactY_w(a1)
				move.w	#0,EntT_ImpactZ_w(a1)

				move.l	#0,Plr1_SnapXSpdVal_l
				move.l	#0,Plr1_SnapZSpdVal_l
				move.l	#0,Plr1_SnapYVel_l
				move.l	#0,Plr2_SnapXSpdVal_l
				move.l	#0,Plr2_SnapZSpdVal_l
				move.l	#0,Plr2_SnapYVel_l

				jsr	FPS_time1
lop:
				move.w	#%110000000000,_custom+potgo

				cmp.b	#PLR_MASTER,Plr_MultiplayerType_b
				bne		.notmess
				tst.b	PLR2_dead
				bne		.notmess

				tst.w	PLAYERTWOHEALTH
				bgt		.notmess

				st		PLR2_dead

				jsr		GetRand
				swap	d0
				clr.w	d0
				swap	d0
				divs	#9,d0
				swap	d0
				muls	#160,d0
				add.l	#IVEWONTEXT,d0
				jsr		SENDMESSAGE

				move.l	Plr2_ObjectPtr_l,a0

				move.l	GLF_DatabasePtr_l,a6
				add.l	#GLFT_Player2Graphic_w,a6
				move.w	(a6),d7
				move.w	d7,d1
				move.l	GLF_DatabasePtr_l,a6
				add.l	#GLFT_AlienDefs_l,a6
				muls	#AlienT_SizeOf_l,d1
				add.l	d1,a6

				move.b	AlienT_SplatType_w+1(a6),d0
				move.b	d0,TypeOfSplat

				move.l	Plr2_RoomPtr_l,a1
				move.w	(a1),12(a0)
				move.w	Plr2_TmpXOff_l,newx
				move.w	Plr2_TmpZOff_l,newz
				move.w	#7,d2
				jsr		ExplodeIntoBits
				move.w	#-1,12(a0)

.notmess:

				cmp.b	#PLR_SLAVE,Plr_MultiplayerType_b
				bne		.notmess2
				tst.b	PLR1_dead
				bne		.notmess2

				tst.w	PLAYERONEHEALTH
				bgt		.notmess2

				st		PLR1_dead

				jsr		GetRand
				swap	d0
				clr.w	d0
				swap	d0
				divs	#9,d0
				swap	d0
				muls	#160,d0
				add.l	#IVEWONTEXT,d0
				jsr		SENDMESSAGE

				move.l	Plr1_ObjectPtr_l,a0

				move.l	GLF_DatabasePtr_l,a6
				add.l	#GLFT_Player1Graphic_w,a6
				move.w	(a6),d7
				move.w	d7,d1
				move.l	GLF_DatabasePtr_l,a6
				add.l	#GLFT_AlienDefs_l,a6
				muls	#AlienT_SizeOf_l,d1
				add.l	d1,a6

				move.b	AlienT_SplatType_w+1(a6),d0
				move.b	d0,TypeOfSplat

				move.l	Plr1_RoomPtr_l,a1
				move.w	(a1),12(a0)
				move.w	Plr1_TmpXOff_l,newx
				move.w	Plr1_TmpZOff_l,newz
				move.w	#7,d2
				jsr		ExplodeIntoBits
				move.w	#-1,12(a0)
.notmess2:

				;FIXME: should use _LVOWritePotgo here!
				move.w	#%110000000000,_custom+potgo ; POTGO -start Potentiometer reading
														; FIXME: shouldn't this be in a regular interrupt, like VBL?

; move.w COUNTER,d0
; ext.l d0
; divs #10,d0
; swap d0
; add.b #'0',d0
; move.b d0,COUNTSPACE+2
; swap d0
; ext.l d0
; divs #10,d0
; swap d0
; add.b #'0',d0
; move.b d0,COUNTSPACE+1
; swap d0
; add.b #'0',d0
; move.b d0,COUNTSPACE
;
; move.w COUNTER2,d0
; ext.l d0
; divs #10,d0
; swap d0
; add.b #'0',d0
; move.b d0,COUNTSPACE+5
; swap d0
; ext.l d0
; divs #10,d0
; swap d0
; add.b #'0',d0
; move.b d0,COUNTSPACE+4
; swap d0
; add.b #'0',d0
; move.b d0,COUNTSPACE+3

;
; move.l #COUNTSPACE,d0
; jsr SENDMESSAGE
;
; move.w #0,COUNTER
; move.w #0,COUNTER2

				move.b	MAPON,REALMAPON

				move.b	FULLSCRTEMP,d0
				move.b	Vid_FullScreen_b,d1
				eor.b	d1,d0
				beq		.noFullscreenSwitch

				move.b	FULLSCRTEMP,Vid_FullScreen_b

				bsr		SetupRenderbufferSize

.noFullscreenSwitch

				move.l	#KeyMap,a5

				cmp.b	#PLR_NEITHER,Plr_MultiplayerType_b
				bne		.nopause
				tst.b	$19(a5)
				beq.s	.nopause
				clr.b	doanything

.waitrel:

				tst.b	Plr1_Joystick_b
				beq.s	.NOJOY
				jsr		_ReadJoy1
.NOJOY

				tst.b	$19(a5)
				bne.s	.waitrel

				bsr		PAUSEOPTS

				st		doanything
.nopause:

; FIXME: "player is hit" color handling missing
;				move.l	hitcol,d0		; hitcol seems to "shift" the color palette selection
;				move.l	d0,d1			; into a red palette if the player is hit
;				add.l	#PALETTEBIT,d1
;				tst.l	d0
;				beq.s	nofadedownhc
;				sub.l	#2116,d0
;				move.l	d0,hitcol
nofadedownhc:

				;bsr		LoadMainPalette		; should only reload the palatte when hit

				st		READCONTROLS
				move.l	#$dff000,a6

				cmp.b	#PLR_NEITHER,Plr_MultiplayerType_b
				beq		.nopause

				move.b	SLAVEPAUSE,d0
				or.b	MASTERPAUSE,d0
				beq.s	.nopause
				clr.b	doanything

				move.l	#KeyMap,a5
.waitrel:

				cmp.b	#PLR_SLAVE,Plr_MultiplayerType_b
				beq.s	.RE2
				tst.b	Plr1_Joystick_b
				beq.s	.NOJOY
				jsr		_ReadJoy1
				bra		.RE1
.RE2:
				tst.b	Plr2_Joystick_b
				beq.s	.NOJOY
				jsr		_ReadJoy2
.RE1
.NOJOY:
				tst.b	$19(a5)
				bne.s	.waitrel

				bsr		PAUSEOPTS

				cmp.b	#PLR_MASTER,Plr_MultiplayerType_b
				bne.s	.slavelast
				Jsr		SENDFIRST
				bra		.masfirst
.slavelast
				Jsr		RECFIRST
.masfirst:
				clr.b	SLAVEPAUSE
				clr.b	MASTERPAUSE
				st		doanything

.nopause:

				move.l	VBLCOUNTLAST,d2
				add.l	FPSLIMITER,d2
.waitvbl
				move.l	VBLCOUNT,d3
				cmp.l	d2,d3
				bhi.s	.skipWaitTOF
				CALLGRAF	WaitTOF
				bra.s	.waitvbl
.skipWaitTOF
				move.l	d3,VBLCOUNTLAST

; Swap screen bitmaps
				move.l	SCRNDRAWPT,d0
				move.l	SCRNSHOWPT,SCRNDRAWPT
				move.l	d0,SCRNSHOWPT

				cmp.b	#PLR_SLAVE,Plr_MultiplayerType_b
				beq.s	nowaitslave

				; Waiting for old copperlist interrupt to switch screens?
;waitfortop:
;				btst.b	#0,intreqrl(a6)
;				beq.b	waitfortop
;				move.w	#$1,intreq(a6)

; move.l #PLR1_GunData,GunData
				move.b	Plr1_GunSelected_b,GunSelected
				bra		waitmaster

nowaitslave:
; move.l #PLR2_GunData,GunData
				move.b	Plr2_GunSelected_b,GunSelected
waitmaster:

*****************************************************************


				; Flip screens

				; Wait on prior frame to be displayed.
				; FIXME: this could waste time synchrously waiting on the scanout to happen if we manage
				; to fully produce the next frame before the last frame has been scanned out.
				; We could move the screen flipping into its own thread that flips asynchronously.
				; It does not seem very practical, though as this scenario
				tst.b	WaitForDisplayMsg
				beq.s	.noWait

				move.l	DisplayMsgPort,a0
				move.l	a0,a3
				CALLEXEC WaitPort				; wait for when the old image has been displayed
.clrMsgPort		move.l	a3,a0
				CALLEXEC GetMsg					; clear message port
				tst.l	d0
				bne.s	.clrMsgPort

.noWait			move.w	ScreenBufferIndex,d2
				lea		ScreenBuffers,a1
				eor.w	#1,d2					; flip  screen index
				move.l	(a1,d2.w*4),a1			; grab ScreenBuffer pointer

				move.l	MainScreen,a0
				CALLINT	ChangeScreenBuffer		; DisplayMsgPort will be notified if this image had been fully scanned out

				tst.l	d0
				beq.s	.failed

				move.w	d2,ScreenBufferIndex
				st.b	WaitForDisplayMsg
				bra.s	.screenSwapDone

.failed			clr.b	WaitForDisplayMsg		; last attempt failed, so don't wait for next message

.screenSwapDone
				jsr	FPS_time2				;fps counter c/o Grond
*****************************************************************
				jsr	FPS_time1				;fps counter c/o Grond

				move.l	#SMIDDLEY,a0
				movem.l	(a0)+,d0/d1
				move.l	d0,Vid_CentreY_w
				move.l	d1,Vid_CentreY_w+4

				move.l	waterpt,a0
				move.l	(a0)+,watertouse
				cmp.l	#endwaterlist,a0
				blt.s	okwat
				move.l	#waterlist,a0
okwat:
				move.l	a0,waterpt

				add.w	#640,wtan
				and.w	#8191,wtan
				add.l	#1,wateroff
				and.l	#$3fff3fff,wateroff

				move.l	Plr1_XOff_l,OldX1_l
				move.l	Plr1_ZOff_l,OldZ1_l
				move.l	Plr2_XOff_l,OldX2_l
				move.l	Plr2_ZOff_l,OldZ2_l

				move.l	#$dff000,a6

				cmp.b	#PLR_SLAVE,Plr_MultiplayerType_b
				beq		ASlaveShouldWaitOnHisMaster

				cmp.b	#PLR_NEITHER,Plr_MultiplayerType_b
				bne		NotOnePlayer

				movem.l	d0-d7/a0-a6,-(a7)

				moveq	#0,d0
				move.b	GunSelected,d0
				move.l	GLF_DatabasePtr_l,a6
				add.l	#GLFT_ShootDefs_l,a6
				move.w	(a6,d0.w*8),d0

				move.l	#PLAYERONEAMMO,a6
				move.w	(a6,d0.w*2),d0
				move.w	d0,Ammo
				movem.l	(a7)+,d0-d7/a0-a6

				move.w	PLAYERONEHEALTH,Energy

				move.w	FramesToDraw,TempFrames
				cmp.w	#15,TempFrames
				blt.s	.okframe
				move.w	#15,TempFrames
.okframe:
				move.w	#0,FramesToDraw

*********************************************
*********** TAKE THIS OUT *******************
*********************************************

;				move.l	CHEATPTR,a4
;				add.l	#200000,a4
;				moveq	#0,d0
;				move.b	(a4),d0
;
;				move.l	#KeyMap,a5
;				tst.b	(a5,d0.w)
;				beq.s	.nocheat
;
;				addq	#1,a4
;				cmp.l	#ENDCHEAT,a4
;				blt.s	.nocheat
;				cmp.w	#0,CHEATNUM
;				beq.s	.nocheat
;				sub.w	#1,CHEATNUM
;				move.l	#CHEATFRAME,a4
;				move.w	#127,Plr1_Energy_w
;				jsr		EnergyBar
;.nocheat
;
;				sub.l	#200000,a4
;				move.l	a4,CHEATPTR

**********************************************
**********************************************
**********************************************

				move.l	Plr1_SnapXOff_l,Plr1_TmpXOff_l
				move.l	Plr1_SnapZOff_l,Plr1_TmpZOff_l
				move.l	Plr1_SnapYOff_l,Plr1_TmpYOff_l
				move.l	Plr1_SnapHeight_l,Plr1_TmpHeight_l
				move.w	Plr1_SnapAngPos_w,Plr1_TmpAngPos_w
				move.w	Plr1_Bobble_w,Plr1_TmpBobble_w
				move.b	PLR1_clicked,Plr1_TmpClicked_b
				move.b	PLR1_fire,Plr1_TmpFire_b
				clr.b	PLR1_clicked
				move.b	PLR1_SPCTAP,Plr1_TmpSpcTap_b
				clr.b	PLR1_SPCTAP
				move.b	Plr1_Ducked_b,Plr1_TmpDucked_b
				move.b	Plr1_GunSelected_b,Plr1_TmpGunSelected_b

				bsr		PLR1_Control

				move.l	Plr1_RoomPtr_l,a0
				move.l	ZoneT_Roof_l(a0),SplitHeight
				move.w	Plr1_TmpXOff_l,THISPLRxoff
				move.w	Plr1_TmpZOff_l,THISPLRzoff


				move.l	#$60000,Plr2_TmpYOff_l
				move.l	Plr2_ObjectPtr_l,a0
				move.w	#-1,EntT_GraphicRoom_w(a0)
				move.w	#-1,12(a0)
				move.b	#0,17(a0)
				move.l	#BollocksRoom,Plr2_RoomPtr_l

				bra		donetalking

NotOnePlayer:
				move.l	#KeyMap,a5
				tst.b	$19(a5)
				sne		MASTERPAUSE

*********************************
				move.w	PLAYERONEHEALTH,Energy
; change this back
*********************************
				movem.l	d0-d7/a0-a6,-(a7)

				moveq	#0,d0
				move.b	GunSelected,d0
				move.l	GLF_DatabasePtr_l,a6
				add.l	#GLFT_ShootDefs_l,a6
				move.w	(a6,d0.w*8),d0

				move.l	#PLAYERONEAMMO,a6
				move.w	(a6,d0.w*2),d0
				move.w	d0,Ammo
				movem.l	(a7)+,d0-d7/a0-a6

				jsr		SENDFIRST

				move.w	FramesToDraw,TempFrames
				cmp.w	#15,TempFrames
				blt.s	.okframe
				move.w	#15,TempFrames
.okframe:
				move.w	#0,FramesToDraw

				move.l	Plr1_SnapXOff_l,Plr1_TmpXOff_l
				move.l	Plr1_SnapZOff_l,Plr1_TmpZOff_l
				move.l	Plr1_SnapYOff_l,Plr1_TmpYOff_l
				move.l	Plr1_SnapHeight_l,Plr1_TmpHeight_l
				move.w	Plr1_SnapAngPos_w,Plr1_TmpAngPos_w
				move.w	Plr1_Bobble_w,Plr1_TmpBobble_w
				move.b	PLR1_clicked,Plr1_TmpClicked_b
				clr.b	PLR1_clicked
				move.b	PLR1_fire,Plr1_TmpFire_b
				move.b	PLR1_SPCTAP,Plr1_TmpSpcTap_b
				clr.b	PLR1_SPCTAP
				move.b	Plr1_Ducked_b,Plr1_TmpDucked_b
				move.b	Plr1_GunSelected_b,Plr1_TmpGunSelected_b

				move.l	PLR1_AIMSPD,d0
				jsr		SENDFIRST
				move.l	d0,PLR2_AIMSPD

				move.l	Plr1_TmpXOff_l,d0
				jsr		SENDFIRST
				move.l	d0,Plr2_TmpXOff_l

				move.l	Plr1_TmpZOff_l,d0
				jsr		SENDFIRST
				move.l	d0,Plr2_TmpZOff_l

				move.l	Plr1_TmpYOff_l,d0
				jsr		SENDFIRST
				move.l	d0,Plr2_TmpYOff_l

				move.l	Plr1_TmpHeight_l,d0
				jsr		SENDFIRST
				move.l	d0,Plr2_TmpHeight_l

				move.w	Plr1_TmpAngPos_w,d0
				swap	d0
				move.w	Plr1_TmpBobble_w,d0
				jsr		SENDFIRST
				move.w	d0,Plr2_TmpBobble_w
				swap	d0
				move.w	d0,Plr2_TmpAngPos_w


				move.w	TempFrames,d0
				swap	d0
				move.b	Plr1_TmpSpcTap_b,d0
				lsl.w	#8,d0
				move.b	Plr1_TmpClicked_b,d0
				jsr		SENDFIRST
				move.b	d0,Plr2_TmpClicked_b
				lsr.w	#8,d0
				move.b	d0,Plr2_TmpSpcTap_b

				move.w	Rand1,d0
				swap	d0
				move.b	Plr1_TmpDucked_b,d0
				or.b	Plr1_Squished_b,d0
				lsl.w	#8,d0
				move.b	Plr1_TmpGunSelected_b,d0
				jsr		SENDFIRST
				move.b	d0,Plr2_TmpGunSelected_b
				lsr.w	#8,d0
				move.b	d0,Plr2_TmpDucked_b

				move.b	Plr1_TmpFire_b,d0
				lsl.w	#8,d0
				move.b	MASTERQUITTING,d0
				or.b	d0,SLAVEQUITTING
				swap	d0
				move.b	MASTERPAUSE,d0
				or.b	d0,SLAVEPAUSE
				jsr		SENDFIRST
				or.b	d0,MASTERPAUSE
				or.b	d0,SLAVEPAUSE
				swap	d0
				or.b	d0,SLAVEQUITTING
				or.b	d0,MASTERQUITTING
				lsr.w	#8,d0
				move.b	d0,Plr2_TmpFire_b

				move.w	PLAYERONEHEALTH,d0
				jsr		SENDFIRST
				move.w	d0,PLAYERTWOHEALTH

				bsr		PLR1_Control
				bsr		PLR2_Control
				move.l	Plr1_RoomPtr_l,a0
				move.l	ZoneT_Roof_l(a0),SplitHeight
				move.w	Plr1_TmpXOff_l,THISPLRxoff
				move.w	Plr1_TmpZOff_l,THISPLRzoff

				bra		donetalking

ASlaveShouldWaitOnHisMaster:

				move.l	#KeyMap,a5
				tst.b	$19(a5)
				sne		SLAVEPAUSE

				movem.l	d0-d7/a0-a6,-(a7)

				moveq	#0,d0
				move.b	GunSelected,d0
				move.l	GLF_DatabasePtr_l,a6
				add.l	#GLFT_ShootDefs_l,a6
				move.w	(a6,d0.w*8),d0

				move.l	#PLAYERTWOAMMO,a6
				move.w	(a6,d0.w*2),d0
				move.w	d0,Ammo
				movem.l	(a7)+,d0-d7/a0-a6

				move.w	PLAYERTWOHEALTH,Energy

				jsr		RECFIRST

				move.l	Plr2_SnapXOff_l,Plr2_TmpXOff_l
				move.l	Plr2_SnapZOff_l,Plr2_TmpZOff_l
				move.l	Plr2_SnapYOff_l,Plr2_TmpYOff_l
				move.l	Plr2_SnapHeight_l,Plr2_TmpHeight_l
				move.w	Plr2_SnapAngPos_w,Plr2_TmpAngPos_w
				move.w	Plr2_Bobble_w,Plr2_TmpBobble_w
				move.b	PLR2_clicked,Plr2_TmpClicked_b
				clr.b	PLR2_clicked
				move.b	PLR2_fire,Plr2_TmpFire_b
				move.b	PLR2_SPCTAP,Plr2_TmpSpcTap_b
				clr.b	PLR2_SPCTAP
				move.b	Plr2_Ducked_b,Plr2_TmpDucked_b
				move.b	Plr2_GunSelected_b,Plr2_TmpGunSelected_b

				move.l	PLR2_AIMSPD,d0
				jsr		RECFIRST
				move.l	d0,PLR1_AIMSPD

				move.l	Plr2_TmpXOff_l,d0
				jsr		RECFIRST
				move.l	d0,Plr1_TmpXOff_l

				move.l	Plr2_TmpZOff_l,d0
				jsr		RECFIRST
				move.l	d0,Plr1_TmpZOff_l

				move.l	Plr2_TmpYOff_l,d0
				jsr		RECFIRST
				move.l	d0,Plr1_TmpYOff_l

				move.l	Plr2_TmpHeight_l,d0
				jsr		RECFIRST
				move.l	d0,Plr1_TmpHeight_l

				move.w	Plr2_TmpAngPos_w,d0
				swap	d0
				move.w	Plr2_TmpBobble_w,d0
				jsr		RECFIRST
				move.w	d0,Plr1_TmpBobble_w
				swap	d0
				move.w	d0,Plr1_TmpAngPos_w


				move.b	Plr2_TmpSpcTap_b,d0
				lsl.w	#8,d0
				move.b	Plr2_TmpClicked_b,d0
				jsr		RECFIRST
				move.b	d0,Plr1_TmpClicked_b
				lsr.w	#8,d0
				move.b	d0,Plr1_TmpSpcTap_b
				swap	d0
				move.w	d0,TempFrames

				move.b	Plr2_TmpDucked_b,d0
				or.b	Plr2_Squished_b,d0
				lsl.w	#8,d0
				move.b	Plr2_TmpGunSelected_b,d0
				jsr		RECFIRST
				move.b	d0,Plr1_TmpGunSelected_b
				lsr.w	#8,d0
				move.b	d0,Plr1_TmpDucked_b
				swap	d0
				move.w	d0,Rand1

				move.b	Plr2_TmpFire_b,d0
				lsl.w	#8,d0
				move.b	SLAVEQUITTING,d0
				or.b	d0,MASTERQUITTING
				swap	d0
				move.b	SLAVEPAUSE,d0
				or.b	d0,MASTERPAUSE
				jsr		RECFIRST
				or.b	d0,MASTERPAUSE
				or.b	d0,SLAVEPAUSE
				swap	d0
				or.b	d0,SLAVEQUITTING
				or.b	d0,MASTERQUITTING
				lsr.w	#8,d0
				move.b	d0,Plr1_TmpFire_b

				move.w	PLAYERTWOHEALTH,d0
				jsr		RECFIRST
				move.w	d0,PLAYERONEHEALTH

				bsr		PLR1_Control
				bsr		PLR2_Control
				move.w	Plr2_TmpXOff_l,THISPLRxoff
				move.w	Plr2_TmpZOff_l,THISPLRzoff
				move.l	Plr2_RoomPtr_l,a0
				move.l	ZoneT_Roof_l(a0),SplitHeight

donetalking:
				move.l	#ZoneBrightTable,a1
				move.l	Lvl_ZoneAddsPtr_l,a2
				move.l	Plr2_ListOfGraphRoomsPtr_l,a0
; move.l Plr2_PointsToRotatePtr_l,a5
				move.l	a0,a5
				cmp.b	#PLR_SLAVE,Plr_MultiplayerType_b
				beq.s	doallz
				move.l	Plr1_ListOfGraphRoomsPtr_l,a0
; move.l Plr1_PointsToRotatePtr_l,a5
				move.l	a0,a5
doallz
				move.w	(a0),d0
				blt.s	doneallz
				add.w	#8,a0

				move.l	(a2,d0.w*4),a3
				add.l	Lvl_DataPtr_l,a3
				move.w	ZoneT_Brightness_w(a3),d2

				blt.s	justbright
				move.w	d2,d3
				lsr.w	#8,d3
				tst.b	d3
				beq.s	justbright

				move.l	#BrightAnimTable,a4
				move.w	-2(a4,d3.w*2),d2

justbright:
				muls	#32,d2
				divs	#20,d2
				move.w	d2,(a1,d0.w*4)

				move.w	ZoneT_UpperBrightness_w(a3),d2

				blt.s	justbright2
				move.w	d2,d3
				lsr.w	#8,d3
				tst.b	d3
				beq.s	justbright2

				move.l	#BrightAnimTable,a4
				move.w	-2(a4,d3.w*2),d2

justbright2:

				muls	#32,d2
				divs	#20,d2
				move.w	d2,2(a1,d0.w*4)

				bra		doallz

doneallz:

				move.l	PointBrights,a2
				move.l	#CurrentPointBrights,a3
justtheone:
				move.w	(a5),d0
				blt		whythehell
				addq	#8,a5

				muls	#40,d0

				move.w	#39,d7

allinzone:
				move.w	(a2,d0.w*2),d2

				tst.b	d2
				blt.s	.justbright
				move.w	d2,d3
				lsr.w	#8,d3
				tst.b	d3
				beq.s	.justbright

				move.w	d3,d4
				and.w	#$f,d3
				lsr.w	#4,d4
				add.w	#1,d4
				move.l	#BrightAnimTable,a0
				move.w	-2(a0,d3.w*2),d3
				ext.w	d2
				sub.w	d2,d3
				muls	d4,d3
				asr.w	#4,d3
				add.w	d3,d2

.justbright:
				ext.w	d2

				muls	#31,d2
				divs	#20,d2
				bge.s	.itspos
				sub.w	#600,d2
.itspos:
				add.w	#300,d2

				move.w	d2,(a3,d0.w*2)
				addq	#1,d0
				dbra	d7,allinzone

				bra		justtheone

whythehell:

				move.l	Plr1_RoomPtr_l,a0
				move.l	#CurrentPointBrights,a1
				move.l	Lvl_ZoneBorderPointsPtr_l,a2
				move.w	(a0),d0
				muls	#10,d0
				lea		(a2,d0.w*2),a2
				lea		(a1,d0.w*8),a1

				moveq	#9,d7
				moveq	#0,d0
				moveq	#0,d1
findaverage:
				tst.w	(a2)+
				blt.s	.foundaverage
				addq	#1,d0
				move.w	(a1)+,d2
				bge.s	.okpos
				neg.w	d2
.okpos:
				add.w	d2,d1

				dbra	d7,findaverage

.foundaverage:

				ext.l	d1
				divs	d0,d1
				sub.w	#300,d1
				move.w	d1,Plr1_RoomBright_w

				cmp.b	#PLR_NEITHER,Plr_MultiplayerType_b
				beq		nosee

				move.l	Plr1_RoomPtr_l,FromRoom
				move.l	Plr2_RoomPtr_l,ToRoom
				move.w	Plr1_TmpXOff_l,Viewerx
				move.w	Plr1_TmpZOff_l,Viewerz
				move.l	Plr1_TmpYOff_l,d0
				asr.l	#7,d0
				move.w	d0,Viewery
				move.w	Plr2_TmpXOff_l,Targetx
				move.w	Plr2_TmpZOff_l,Targetz
				move.l	Plr2_TmpYOff_l,d0
				asr.l	#7,d0
				move.w	d0,Targety
				move.b	Plr1_StoodInTop_b,ViewerTop
				move.b	Plr2_StoodInTop_b,TargetTop
				jsr		CanItBeSeen

				move.l	Plr1_ObjectPtr_l,a0
				move.b	CanSee,d0
				and.b	#2,d0
				move.b	d0,17(a0)
				move.l	Plr2_ObjectPtr_l,a0
				move.b	CanSee,d0
				and.b	#1,d0
				move.b	d0,17(a0)

nosee:


				move.w	TempFrames,d0
				add.w	d0,Plr1_TmpHoldDown_w
				cmp.w	#30,Plr1_TmpHoldDown_w
				blt.s	oklength
				move.w	#30,Plr1_TmpHoldDown_w
oklength:

				tst.b	Plr1_TmpFire_b
				bne.s	okstillheld
				sub.w	d0,Plr1_TmpHoldDown_w
				bge.s	okstillheld
				move.w	#0,Plr1_TmpHoldDown_w

okstillheld:

				move.w	TempFrames,d0
				add.w	d0,Plr2_TmpHoldDown_w

				cmp.w	#30,Plr2_TmpHoldDown_w
				blt.s	oklength2
				move.w	#30,Plr2_TmpHoldDown_w
oklength2:


				tst.b	Plr2_TmpFire_b
				bne.s	okstillheld2
				sub.w	d0,Plr2_TmpHoldDown_w
				bge.s	okstillheld2
				move.w	#0,Plr2_TmpHoldDown_w
okstillheld2:

***** CHECKING LIGHT *********

; move.w #-20,d0
; move.w Plr1_XOff_l,d1
; move.w Plr1_ZOff_l,d2
; move.l Plr1_RoomPtr_l,a0
; move.w (a0),d3
; move.w Plr1_AngPos_w,d4
;
; jsr BRIGHTENPOINTSANGLE

******************************

; move.l #PLR1_GunData,a1
; move.w Plr1_TmpHoldDown_w,d0
; move.w #50,10+32*3(a1)
; move.l #PLR2_GunData,a1
; move.w Plr2_TmpHoldDown_w,d0
; move.w #50,10+32*3(a1)

******************************************
******************************************

				move.w	TempFrames,d1
				bgt.s	noze
				moveq	#1,d1
noze:

				move.w	Plr1_XOff_l,d0
				sub.w	OldX1_l,d0
				asl.w	#4,d0
				ext.l	d0
				divs	d1,d0
				move.w	d0,XDiff_w
				move.w	Plr2_XOff_l,d0
				sub.w	OldX2_l,d0
				asl.w	#4,d0
				ext.l	d0
				divs	d1,d0
				move.w	Plr1_ZOff_l,d0
				sub.w	OldZ1_l,d0
				asl.w	#4,d0
				ext.l	d0
				divs	d1,d0
				move.w	d0,ZDiff_w
				move.w	Plr2_ZOff_l,d0
				sub.w	OldZ2_l,d0
				asl.w	#4,d0
				ext.l	d0
				divs	d1,d0

				cmp.b	#PLR_SLAVE,Plr_MultiplayerType_b
				beq.s	ImPlayer2OhYesIAm
				bsr		USEPLR1
				bra		IWasPlayer1

ImPlayer2OhYesIAm:
				bsr		USEPLR2
IWasPlayer1:


				cmp.b	#PLR_SLAVE,Plr_MultiplayerType_b
				beq		drawplayer2

				move.w	#0,scaleval

				move.l	Plr1_XOff_l,xoff
				move.l	Plr1_YOff_l,yoff
				move.l	Plr1_ZOff_l,zoff
				move.w	Plr1_AngPos_w,angpos
				move.w	Plr1_CosVal_w,cosval
				move.w	Plr1_SinVal_w,sinval


				move.l	Plr1_ListOfGraphRoomsPtr_l,Lvl_ListOfGraphRoomsPtr_l
				move.l	Plr1_PointsToRotatePtr_l,PointsToRotatePtr_l
				move.b	Plr1_Echo_b,PLREcho
				move.l	Plr1_RoomPtr_l,Roompt

				move.l	#KeyMap,a5
				moveq	#0,d5
				move.b	look_behind_key,d5
				tst.b	(a5,d5.w)
				beq.s	.nolookback

				move.l	Plr1_ObjectPtr_l,a0
				move.w	#-1,12+128(a0)

				eor.w	#4096,angpos
				neg.w	cosval					; view direction 180deg
				neg.w	sinval
.nolookback:

				jsr		OrderZones
				jsr		objmoveanim
				jsr		EnergyBar
				jsr		AmmoBar


;********************************************
;************* Do reflection ****************
;
; move.l Lvl_ListOfGraphRoomsPtr_l,a0
; move.l Lvl_ZoneAddsPtr_l,a1
;checkwaterheights
; move.w (a0),d0
; blt allzonesdone
; addq #8,a0
; move.l (a1,d0.w*4),a2
;
; add.l Lvl_DataPtr_l,a2
;
; move.l ZoneT_Water_l(a2),d0
; cmp.l ZoneT_Floor_l(a2),d0
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
; move.l FASTBUFFER2,Vid_FastBufferPtr_l
; move.w #0,leftclip
; move.w Vid_RightX_w,rightclip
; move.w #0,deftopclip
; move.w #Vid_BottomY_w/2,defbotclip
; move.w #0,draw_TopClip_w
; move.w #Vid_BottomY_w/2,draw_BottomClip_w
;
; clr.b DOANYWATER
;
; bsr DrawDisplay
;
;allzonesdone:
;underwater:

********************************************

				st		DOANYWATER

				move.l	Plr1_YOff_l,yoff

				move.w	#0,leftclip
				move.w	Vid_RightX_w,rightclip

				move.w	WIDESCRN,d0
				move.w	#0,deftopclip
				add.w	d0,deftopclip
				move.w	Vid_BottomY_w,defbotclip
				sub.w	d0,defbotclip

				move.w	#0,draw_TopClip_w
				add.w	d0,draw_TopClip_w
				move.w	Vid_BottomY_w,draw_BottomClip_w
				sub.w	d0,draw_BottomClip_w
; sub.l #10*104*4,frompt
; sub.l #10*104*4,midpt

* Subroom loop

				bsr		DrawDisplay

				bra		nodrawp2

drawplayer2

				move.w	#0,scaleval
				move.l	Plr2_XOff_l,xoff
				move.l	Plr2_YOff_l,yoff
				move.l	Plr2_ZOff_l,zoff
				move.w	Plr2_AngPos_w,angpos
				move.w	Plr2_CosVal_w,cosval
				move.w	Plr2_SinVal_w,sinval



				move.l	Plr2_ListOfGraphRoomsPtr_l,Lvl_ListOfGraphRoomsPtr_l
				move.l	Plr2_PointsToRotatePtr_l,PointsToRotatePtr_l
				move.b	Plr2_Echo_b,PLREcho
				move.l	Plr2_RoomPtr_l,Roompt

				move.l	#KeyMap,a5
				moveq	#0,d5
				move.b	look_behind_key,d5
				tst.b	(a5,d5.w)
				beq.s	.nolookback

				move.l	Plr1_ObjectPtr_l,a0
				move.w	#-1,12+128(a0)
				eor.w	#4096,angpos

				neg.w	cosval
				neg.w	sinval
.nolookback:

				jsr		OrderZones
				jsr		objmoveanim
				jsr		EnergyBar
				jsr		AmmoBar

				move.w	WIDESCRN,d0

				move.w	#0,leftclip
				move.w	Vid_RightX_w,rightclip

				move.w	#0,deftopclip
				add.w	d0,deftopclip
				move.w	Vid_BottomY_w,defbotclip
				sub.w	d0,defbotclip

				move.w	#0,draw_TopClip_w
				add.w	d0,draw_TopClip_w
				move.w	Vid_BottomY_w,draw_BottomClip_w
				sub.w	d0,draw_BottomClip_w

				st		DOANYWATER
				bsr		DrawDisplay

nodrawp2:

				tst.b	REALMAPON
				beq.s	.nomap
				bsr		DoTheMapWotNastyCharlesIsForcingMeToDo

.nomap
				move.b	Plr1_Teleported_b,d5
				clr.b	Plr1_Teleported_b
				cmp.b	#PLR_SLAVE,Plr_MultiplayerType_b
				bne.s	.notplr2
				move.b	Plr2_Teleported_b,d5
				clr.b	Plr2_Teleported_b
.notplr2
				jsr		CHUNKYTOPLANAR


				move.l	#KeyMap,a5
				tst.b	$4a(a5)
				beq		.nosmallscr

				; clamp wide screen
				move.w	#100,d0					; maximum in fullscreen mode
				tst.b	Vid_FullScreen_b
				bne.s	.isFullscreen
				move.w	#60,d0					; maximum in small screen mode
.isFullscreen:
				cmp.w	WIDESCRN,d0
				blt.s	.clamped

				add.w	#2,WIDESCRN

				move.l	SCRNDRAWPT,a0
				jsr		WIPEDISPLAY
				move.l	SCRNSHOWPT,a0
				jsr		WIPEDISPLAY
.clamped:
.nosmallscr
				tst.b	$5e(a5)
				beq.s	.nobigscr

				tst.w	WIDESCRN
				ble.s	.nobigscr

				sub.w	#2,WIDESCRN
.nobigscr


; tst.b (a5)
; beq.s .nosavescrn
;
; not.b USEDOUG
;
; jsr SAVETHESCREEN
;
;.nosavescrn:

				tst.b	$5b(a5)
				beq		notdoubheight
				tst.b	LASTDH
				bne		notdoubheight2
				st		LASTDH
				move.w	#0,d0
				move.w	#0,d1

				not.b	DOUBLEHEIGHT

				; Check renderbuffer setup variables and clear screen
				bsr		SetupRenderbufferSize
				jsr		SetupDoubleheightCopperlist

				bra		notdoubheight2

notdoubheight:
				clr.b	LASTDH
notdoubheight2

				tst.b	$5a(a5)
				beq.s	notdoubwidth
				tst.b	LASTDW
				bne		notdoubwidth2
				not.b	DOUBLEWIDTH

				bsr		SetupRenderbufferSize

				bra.s	notdoubwidth2

notdoubwidth:
				clr.b	LASTDW
notdoubwidth2:

*****************************************
				move.l	Plr2_RoomPtr_l,a0
				move.l	#WorkSpace,a1
				clr.l	(a1)
				clr.l	4(a1)
				clr.l	8(a1)
				clr.l	12(a1)
				clr.l	16(a1)
				clr.l	20(a1)
				clr.l	24(a1)
				clr.l	28(a1)

				cmp.b	#PLR_NEITHER,Plr_MultiplayerType_b
				beq.s	plr1only

				lea		ZoneT_ListOfGraph_w(a0),a0
.doallrooms:
				move.w	(a0),d0
				blt.s	.allroomsdone
				addq	#8,a0
				move.w	d0,d1
				asr.w	#3,d0
				bset	d1,(a1,d0.w)
				bra		.doallrooms
.allroomsdone:

plr1only:

				move.l	Plr1_RoomPtr_l,a0
				lea		ZoneT_ListOfGraph_w(a0),a0
.doallrooms2:
				move.w	(a0),d0
				blt.s	.allroomsdone2
				addq	#8,a0
				move.w	d0,d1
				asr.w	#3,d0
				bset	d1,(a1,d0.w)
				bra		.doallrooms2
.allroomsdone2:

				move.l	#%000001,d7
				lea		AI_Teamwork_vl,a2
				move.l	Lvl_ObjectDataPtr_l,a0
				sub.w	#64,a0
.doallobs:
				add.w	#64,a0
				move.w	(a0),d0
				blt.s	.allobsdone
				move.w	12(a0),d0
				blt.s	.doallobs
				move.w	d0,d1
				asr.w	#3,d0
				btst	d1,(a1,d0.w)
				bne.s	.worryobj
				move.b	16(a0),d0
				btst	d0,d7
				beq.s	.doallobs
				moveq	#0,d0
				move.b	EntT_TeamNumber_b(a0),d0
				blt.s	.doallobs
				asl.w	#4,d0
				tst.w	AI_WorkT_SeenBy_w(a2,d0.w)
				blt.s	.doallobs
.worryobj:
				or.b	#127,ShotT_Worry_b(a0)
				bra.s	.doallobs
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

				move.l	#KeyMap,a5
				tst.b	$45(a5)
				beq.s	noend

				cmp.b	#PLR_SLAVE,Plr_MultiplayerType_b
				beq		plr2quit

				st		MASTERQUITTING
				bra		noend

plr2quit:
				st		SLAVEQUITTING
noend:

				tst.b	MASTERQUITTING
				beq.s	.noquit
				tst.b	SLAVEQUITTING
				beq.s	.noquit
				jmp		endnomusic
.noquit

				cmp.b	#PLR_NEITHER,Plr_MultiplayerType_b
				bne.s	noexit
				move.l	Plr1_RoomPtr_l,a0
				move.w	(a0),d0

				cmp.w	ENDZONE,d0

; change this for quick exit, charlie
zzzz:
;				 bra end	; immediately return to main menu for testing

				bne.s	noexit
				add.w	#2,TELVAL
				cmp.w	#9,TELVAL
				blt		noexit

				jmp		endlevel
noexit:

				tst.w PLAYERONEHEALTH
				bgt nnoend1
				jmp endlevel
nnoend1:
				tst.w PLAYERTWOHEALTH
				bgt nnoend2
				jmp endlevel
nnoend2:

; move.l Lvl_SwitchDataPtr_l,a0
; tst.b 24+8(a0)
; bne end

; JSR STOPTIMER

; Run the actual game update. FIXME: moving it to here from the VBL makes everything run
; like in slow motion
;				tst.b doanything
;				beq	.donothing
;				jsr dosomething
;.donothing
				bra		lop

; Check renderbuffer setup variables and wipe screen
SetupRenderbufferSize:
				; FIXME dowe need to clamp here again?
				cmp.w	#100,WIDESCRN
				blt.s	.wideScreenOk
				move.w	#100,WIDESCRN

.wideScreenOk
				tst.b	Vid_FullScreen_b
				beq.s	.setupSmallScreen

				move.w	#FS_WIDTH,d0
				tst.b	DOUBLEWIDTH
				beq.s	.noDoubleWidth
				lsr.w	#1,d0
.noDoubleWidth
				move.w	d0,Vid_RightX_w
				lsr.w	#1,d0
				move.w	d0,Vid_CentreX_w
				move.w	#FS_HEIGHT,Vid_BottomY_w
				move.w	#FS_HEIGHT/2,TOTHEMIDDLE
				bra.s	.wipeScreen

.setupSmallScreen:
				move.w	#SMALL_WIDTH,d0
				tst.b	DOUBLEWIDTH
				beq.s	.noDoubleWidth2
				lsr.w	#1,d0
.noDoubleWidth2
				move.w	d0,Vid_RightX_w
				lsr.w	#1,d0
				move.w	d0,Vid_CentreX_w
				move.w	#SMALL_HEIGHT,Vid_BottomY_w
				move.w	#SMALL_HEIGHT/2,TOTHEMIDDLE

.wipeScreen
				move.l	SCRNSHOWPT,a0
				jsr		WIPEDISPLAY
				move.l	SCRNDRAWPT,a0
				jsr		WIPEDISPLAY
				rts

LoadMainPalette:
				sub.l	#256*4*3+2+2+4+4,a7		; reserve stack for 256 color entries + numColors + firstColor
				move.l	a7,a1
				move.l	a7,a0
				lea		Palette,a2
				move.w	#256,(a0)+				; number of entries
				move.w	#0,(a0)+				; start index
				move.w	#256*3-1,d0				; 768 entries

				; Palette stores each entry as word
.setCol			clr.l	d1
				move.w	(a2)+,d1
				ror.l	#8,d1
				move.l	d1,(a0)+
				dbra	d0,.setCol
				clr.l	(a0)					; terminate list

				move.l	MainScreen,a0
				lea		sc_ViewPort(a0),a0
				CALLGRAF LoadRGB32				; a1 still points to start of palette

				add.l	#256*4*3+2+2+4+4,a7		;restore stack
				rts

CLRTWOLINES:

				move.l	d2,-(a7)

				moveq	#0,d1
				move.w	#7,d2
.ccc
				move.l	d1,2(a0)
				move.l	d1,6(a0)
				move.l	d1,10(a0)
				move.l	d1,14(a0)
				move.l	d1,18(a0)
				move.l	d1,22(a0)
				move.l	d1,26(a0)
				move.l	d1,30(a0)
				move.l	d1,34(a0)
				move.l	d1,2+40(a0)
				move.l	d1,6+40(a0)
				move.l	d1,10+40(a0)
				move.l	d1,14+40(a0)
				move.l	d1,18+40(a0)
				move.l	d1,22+40(a0)
				move.l	d1,26+40(a0)
				move.l	d1,30+40(a0)
				move.l	d1,34+40(a0)
				add.l	#10240,a0				; next bitplane
				dbra	d2,.ccc
				move.l	(a7)+,d2
				rts


LASTDH:			dc.b	0
LASTDW:			dc.b	0
WIDESCRN:		dc.w	0						; Letter box rendering, height of black border
TRRANS:			dc.w	0
DOANYWATER:		dc.w	0

DoTheMapWotNastyCharlesIsForcingMeToDo:

				move.l	TexturePal,a4
				add.l	#256*32,a4
; add.w MAPBRIGHT,a4

				move.l	#KeyMap,a5
				tst.b	$50(a5)
				beq.s	.nobrighter
				tst.w	MAPBRIGHT
				beq.s	.nobrighter

				sub.w	#1,MAPBRIGHT

.nobrighter:

				tst.b	$51(a5)
				beq.s	.nodimmer
				cmp.w	#7,MAPBRIGHT
				bge.s	.nodimmer

				add.w	#1,MAPBRIGHT

.nodimmer:

				move.l	#Rotated,a1
				move.l	#COMPACTMAP,a2
				move.l	#BIGMAP-40,a3

preshow:
				add.w	#40,a3

SHOWMAP:
				move.l	(a2)+,d5
				move.l	a2,d7
				cmp.l	LastZonePtr_l,d7
				bgt		shownmap

				tst.l	d5
				beq.s	preshow

				move.w	#9,d7
wallsofzone

				asr.l	#1,d5
				bcs.s	WALLSEEN

				asr.l	#1,d5
				bcs.s	WALLMAPPED

				asr.l	#1,d5
				addq	#4,a3
				bra		DECIDEDWALL

WALLMAPPED:
				move.w	#$b00,d4
				asr.l	#1,d5
				bcc.s	.notadoor
				move.w	#$e00,d4
.notadoor

				st		TRRANS

				bra.s	DECIDEDCOLOUR

WALLSEEN:

				clr.b	TRRANS

				move.w	#255,d4
				asr.l	#2,d5
				bcc.s	.notadoor
				move.w	#254,d4
.notadoor
DECIDEDCOLOUR:
				move.w	(a3)+,d6
				move.l	(a1,d6.w*8),d0
				asr.l	#7,d0
				movem.l	d7/d5,-(a7)
				move.w	mapxoff,d5
				ext.l	d5
				add.l	d5,d0
				move.l	4(a1,d6.w*8),d1
				move.w	mapzoff,d5
				ext.l	d5
				add.l	d5,d1
				move.w	(a3)+,d6
				move.l	(a1,d6.w*8),d2
				move.w	mapxoff,d5
				ext.l	d5
				asr.l	#7,d2
				add.l	d5,d2
				move.l	4(a1,d6.w*8),d3
				move.w	mapzoff,d5
				ext.l	d5
				add.l	d5,d3

				neg.l	d1
				neg.l	d3

				bsr		CLIPANDDRAW
				movem.l	(a7)+,d7/d5

DECIDEDWALL:

				dbra	d7,wallsofzone
				bra		SHOWMAP


				; FIXME: why does map rendering have an effect on wall rendering?
shownmap:

				clr.b	TRRANS					; FIXME seems like there is code for
									; translucent map rendering, check it out

				; Is this drawing the Arrow?
				move.w	mapxoff,d0
				move.w	mapzoff,d1
				neg.w	d1
				move.w	d0,d2
				move.w	d1,d3
				sub.w	#128,d1
				add.w	#128,d3
				move.w	#250,d4
				bsr		CLIPANDDRAW

				move.w	mapxoff,d0
				move.w	mapzoff,d1
				neg.w	d1
				move.w	d0,d2
				move.w	d1,d3
				sub.w	#128,d1
				sub.w	#32,d3
				sub.w	#64,d2
				move.w	#250,d4
				bsr		CLIPANDDRAW

				move.w	mapxoff,d0
				move.w	mapzoff,d1
				neg.w	d1
				move.w	d0,d2
				move.w	d1,d3
				sub.w	#128,d1
				sub.w	#32,d3
				add.w	#64,d2
				move.w	#250,d4
				bsr		CLIPANDDRAW
				rts


CLIPANDDRAW:
				tst.b	Vid_FullScreen_b
				beq.s	.nodov

				; This is scaling the coordinates by 3/5 for Fullscreen (used to be 2/3 for 288 wide)
				; For 320 wide, we are have a 3/5 ratio rather than 2/3
				; use an 11 bit approximation based on 1229/2048
				move.l d1,-(sp) ; todo - find a free register
				move.w #1229,d1
				muls  d1,d0 ; 320 * 3/5 = 192
				muls  d1,d2
				move.l #11,d1
				asr.l d1,d0
				asr.l d1,d2
				move.l (sp)+,d1

.nodov:
				tst.b	DOUBLEWIDTH				; correct aspect ratio for DW/DH
				beq.s	.noDoubleWidth
				asr.w	#1,d0
				asr.w	#1,d2
.noDoubleWidth	tst.b	DOUBLEHEIGHT
				;beq.s	.noDoubleHeight         ; 0xABADCAFE - commented out to avoid branch converted to nop
				;asr.w	#1,d1					; DOUBLEHIGHT renderbuffer is still full height
				;asr.w	#1,d3
.noDoubleHeight
				move.w	MAPBRIGHT,d5			; is this the map zoom?

				asr.w	d5,d0					; I guess, this achieves X*0.5 + 0.5 for centered map rendering?
				asr.w	d5,d1
				asr.w	d5,d2
				asr.w	d5,d3


NOSCALING:		add.w	Vid_CentreX_w,d0
				bge		p1xpos

				add.w	Vid_CentreX_w,d2
				blt		OFFSCREEN

x1nx2p:			;		X1<0					X2>0, clip against X=0
				move.w	d2,d6
				sub.w	d0,d6					; dx
				beq		OFFSCREEN				; dx == 0?

				move.w	d3,d5
				sub.w	d1,d5					; dy

				muls.w	d0,d5					; x1 * dy
				divs.w	d6,d5					; x1 * dy / dx
				sub.w	d5,d1					; y1 = y1 - x * dy / dx
				moveq.l	#0,d0					; x1 = 0

				bra		doneleftclip

p1xpos:
				add.w	Vid_CentreX_w,d2
				bge		doneleftclip

				move.w	d0,d6
				sub.w	d2,d6					; dx
				ble		OFFSCREEN				; dx == 0?

				move.w	d1,d5
				sub.w	d3,d5					; dy

				muls.w	d2,d5					; x2 * dy
				divs.w	d6,d5					; x2 * dy / dx
				sub.w	d5,d3					; y2 = y2 - x2 * dy / dx
				moveq.l	#0,d2					; x2 == 0

doneleftclip:	cmp.w	Vid_RightX_w,d0
				blt		p1xneg

				cmp.w	Vid_RightX_w,d2
				bge		OFFSCREEN

				move.w	d0,d6
				sub.w	d2,d6					; dx
				beq		OFFSCREEN

				move.w	d3,d5
				sub.w	d1,d5					; dy

				sub.w	Vid_RightX_w,d0
				addq.w	#1,d0

				muls.w	d5,d0					; dy * (rightx -x1)
				divs.w	d6,d0					; (dy * (rightx -x1))/dx
				add.w	d0,d1					; y1 + (dy * (rightx -x1))/dx = y1 + dy/dx * (rightx - x1)
				move.w	Vid_RightX_w,d0
				subq.w	#1,d0

				bra		donerightclip

p1xneg:
				cmp.w	Vid_RightX_w,d2
				blt		donerightclip

				move.w	d2,d6
				sub.w	d0,d6
				ble		OFFSCREEN

				sub.w	Vid_RightX_w,d2
				addq.w	#1,d2
				move.w	d1,d5
				sub.w	d3,d5

				muls.w	d5,d2
				divs.w	d6,d2
				add.w	d2,d3
				move.w	Vid_RightX_w,d2
				subq.w	#1,d2

donerightclip:

*********************************

				add.w	TOTHEMIDDLE,d1
				bge		p1ypos

				add.w	TOTHEMIDDLE,d3
				blt		OFFSCREEN

				move.w	d3,d6
				sub.w	d1,d6
				ble		OFFSCREEN

				move.w	d2,d5
				sub.w	d0,d5

				muls.w	d1,d5
				divs.w	d6,d5
				sub.w	d5,d0
				moveq.l	#0,d1

				bra		donetopclip

p1ypos:
				add.w	TOTHEMIDDLE,d3
				bge		donetopclip

				move.w	d1,d6
				sub.w	d3,d6
				ble		OFFSCREEN

				move.w	d0,d5
				sub.w	d2,d5


				muls.w	d3,d5
				divs.w	d6,d5
				sub.w	d5,d2
				moveq.l	#0,d3

donetopclip:

				cmp.w	Vid_BottomY_w,d1
				blt		p1yneg

				cmp.w	Vid_BottomY_w,d3
				bge		OFFSCREEN

				move.w	d1,d6
				sub.w	d3,d6
				ble		OFFSCREEN

				sub.w	Vid_BottomY_w,d1
				addq.w	#1,d1
				move.w	d2,d5
				sub.w	d0,d5

				muls.w	d5,d1
				divs.w	d6,d1
				add.w	d1,d0
				move.w	Vid_BottomY_w,d1
				subq.w	#1,d1

				bra		donebotclip

p1yneg:
				cmp.w	Vid_BottomY_w,d3
				blt		donebotclip

				move.w	d3,d6
				sub.w	d1,d6
				ble		OFFSCREEN
				sub.w	Vid_BottomY_w,d3
				addq.w	#1,d3
				move.w	d0,d5
				sub.w	d2,d5

				muls.w	d5,d3
				divs.w	d6,d3
				add.w	d3,d2
				move.w	Vid_BottomY_w,d3
				subq.w	#1,d3

donebotclip:
				tst.b	TRRANS
				bne		DRAWAtransLINE
				bra		DRAWAMAPLINE

OFFSCREEN:
NOLINEtrans:
				rts

MAPBRIGHT:		dc.w	3						; "Map Brightness?" or "Map Bits Right"?
mapxoff:		dc.w	0
mapzoff:		dc.w	0


				; FIXME: this is probably still on chunky screen
DRAWAtransLINE:

				move.l	Vid_FastBufferPtr_l,a0			; screen to render to.

				tst.b	Vid_FullScreen_b
				beq.s	.nooffset

				add.l	#(SCREENWIDTH*40)+(48*2),a0

.nooffset:

				cmp.w	d1,d3
				bgt.s	.okdown
				bne.s	.aline
				cmp.w	d0,d2
				beq.s	NOLINEtrans
.aline
				exg		d0,d2
				exg		d1,d3
.okdown

				move.w	d1,d5
				muls	#SCREENWIDTH,d5
				add.l	d5,a0
				lea		(a0,d0.w*2),a0

				sub.w	d1,d3

				sub.w	d0,d2
				bge		downrighttrans

downlefttrans:
				neg.w	d2
				cmp.w	d2,d3
				bgt.s	downmorelefttrans

downleftmoretrans:
				move.w	#SCREENWIDTH,d6
				move.w	d2,d0
				move.w	d2,d7

.linelop:
				move.b	(a0),d4
				move.b	(a4,d4.w*2),(a0)
				subq	#1,a0
				sub.w	d3,d0
				bgt.s	.noextra
				add.w	d2,d0
				add.w	d6,a0
.noextra:
				dbra	d7,.linelop
				rts

downmorelefttrans:
				move.w	#SCREENWIDTH,d6
				move.w	d3,d0
				move.w	d3,d7

.linelop:
				move.b	(a0),d4
				move.b	(a4,d4.w*2),(a0)
				add.w	d6,a0
				sub.w	d2,d0
				bgt.s	.noextra
				add.w	d3,d0
				subq	#1,a0
.noextra:
				dbra	d7,.linelop

				rts

downrighttrans:

				cmp.w	d2,d3
				bgt.s	downmorerighttrans

downrightmoretrans:
				move.w	#SCREENWIDTH,d6
				move.w	d2,d0
				move.w	d2,d7

.linelop:
				move.b	(a0),d4
				move.b	(a4,d4.w*2),(a0)+
				sub.w	d3,d0
				bgt.s	.noextra
				add.w	d2,d0
				add.w	d6,a0
.noextra:
				dbra	d7,.linelop

				rts

downmorerighttrans:
				move.w	#SCREENWIDTH,d6
				move.w	d3,d0
				move.w	d3,d7

.linelop:
				move.b	(a0),d4
				move.b	(a4,d4.w*2),(a0)
				add.w	d6,a0
				sub.w	d2,d0
				bgt.s	.noextra
				add.w	d3,d0
				addq	#1,a0
.noextra:
				dbra	d7,.linelop

				rts

NOLINE:
				rts

DRAWAMAPLINE:
;				move.b	DOUBLEHEIGHT,d5
;				or.b	DOUBLEWIDTH,d5
;				tst.b	d5
;				bne		DOITFAT

				move.l	Vid_FastBufferPtr_l,a0			; screen to render to.
				cmp.w	d1,d3
				bgt.s	.okdown
				bne.s	.aline
				cmp.w	d0,d2
				beq.s	NOLINE
.aline
				exg		d0,d2
				exg		d1,d3
.okdown

				move.w	d1,d5
				muls	#SCREENWIDTH,d5
				add.l	d5,a0
				lea		(a0,d0.w),a0

				sub.w	d1,d3

				sub.w	d0,d2
				bge.s	downright

downleft:
				neg.w	d2
				cmp.w	d2,d3
				bgt.s	downmoreleft

downleftmore:
				move.w	#SCREENWIDTH,d6
				move.w	d2,d0
				move.w	d2,d7
				addq	#1,a0

.linelop
				move.b	d4,-(a0)
				sub.w	d3,d0
				bgt.s	.noextra
				add.w	d2,d0
				add.w	d6,a0
.noextra:
				dbra	d7,.linelop
				rts

downmoreleft:
				move.w	#SCREENWIDTH,d6
				move.w	d3,d0
				move.w	d3,d7

.linelop:
				move.b	d4,(a0)
				add.w	d6,a0
				sub.w	d2,d0
				bgt.s	.noextra
				add.w	d3,d0
				subq	#1,a0
.noextra:
				dbra	d7,.linelop

				rts

downright:

				cmp.w	d2,d3
				bgt.s	downmoreright

downrightmore:
				move.w	#SCREENWIDTH,d6
				move.w	d2,d0
				move.w	d2,d7

.linelop:
				move.b	d4,(a0)+
				sub.w	d3,d0
				bgt.s	.noextra
				add.w	d2,d0
				add.w	d6,a0
.noextra:
				dbra	d7,.linelop

				rts

downmoreright:
				move.w	#SCREENWIDTH,d6
				move.w	d3,d0
				move.w	d3,d7

.linelop:
				move.b	d4,(a0)
				add.w	d6,a0
				sub.w	d2,d0
				bgt.s	.noextra
				add.w	d3,d0
				addq	#1,a0
.noextra:
				dbra	d7,.linelop

				rts


DOITFAT:
				move.l	Vid_FastBufferPtr_l,a0			; screen to render to.
				cmp.w	d1,d3
				bgt.s	.okdown
				bne.s	.aline
				cmp.w	d0,d2
				beq		NOLINE
.aline
				exg		d0,d2
				exg		d1,d3
.okdown

				move.w	d1,d5
				muls	#SCREENWIDTH,d5
				add.l	d5,a0
				lea		(a0,d0.w),a0

				sub.w	d1,d3

				sub.w	d0,d2
				bge		downrightFAT

downleftFAT:
				neg.w	d2
				cmp.w	d2,d3
				bgt.s	downmoreleftFAT

downleftmoreFAT:
				move.w	#SCREENWIDTH,d6
				move.w	d2,d0
				move.w	d2,d7
				addq	#1,a0

.linelop
				move.b	d4,319(a0)
				move.b	d4,(a0)
				move.b	d4,-(a0)
				sub.w	d3,d0
				bgt.s	.noextra
				add.w	d2,d0
				add.w	d6,a0
.noextra:
				dbra	d7,.linelop
				rts

downmoreleftFAT:
				move.w	#SCREENWIDTH,d6
				move.w	d3,d0
				move.w	d3,d7

.linelop:
				move.b	d4,SCREENWIDTH(a0)
				move.b	d4,1(a0)
				move.b	d4,(a0)
				add.w	d6,a0
				sub.w	d2,d0
				bgt.s	.noextra
				add.w	d3,d0
				subq	#1,a0
.noextra:
				dbra	d7,.linelop

				rts

downrightFAT:

				cmp.w	d2,d3
				bgt.s	downmorerightFAT

downrightmoreFAT:
				move.w	#SCREENWIDTH,d6
				move.w	d2,d0
				move.w	d2,d7

.linelop:
				move.b	d4,SCREENWIDTH(a0)
				move.b	d4,(a0)+
				move.b	d4,(a0)
				sub.w	d3,d0
				bgt.s	.noextra
				add.w	d2,d0
				add.w	d6,a0
.noextra:
				dbra	d7,.linelop

				rts

downmorerightFAT:
				move.w	#SCREENWIDTH,d6
				move.w	d3,d0
				move.w	d3,d7

.linelop:
				move.b	d4,SCREENWIDTH(a0)
				move.b	d4,1(a0)
				move.b	d4,(a0)
				add.w	d6,a0
				sub.w	d2,d0
				bgt.s	.noextra
				add.w	d3,d0
				addq	#1,a0
.noextra:
				dbra	d7,.linelop

				rts

; Screenshot?
SAVETHESCREEN:

				move.l	#SAVENAME,d1
				move.l	#MODE_NEWFILE,d2
				CALLDOS	Open
				move.l	d0,IO_DOSFileHandle_l

				move.l	SCRNDRAWPT,d2
				move.l	IO_DOSFileHandle_l,d1
				move.l	#10240*8,d3
				CALLDOS	Write

				move.l	IO_DOSFileHandle_l,d1
				CALLDOS	Close

				move.l	#200,d1
				CALLDOS	Delay

				add.b	#1,SAVELETTER

				rts

SAVENAME:		dc.b	'rawscrn'
SAVELETTER:		dc.b	'd',0

				even

				include "screensetup.s"
				include	"chunky.s"


MASTERQUITTING:	dc.b	0
SLAVEQUITTING:	dc.b	0
MASTERPAUSE:	dc.b	0
SLAVEPAUSE:		dc.b	0

PAUSEOPTS:
				include	"pauseopts.s"

ENDZONE:		dc.w	0

***************************************************************************
***************************************************************************
****************** End of Main Loop here **********************************
***************************************************************************
***************************************************************************

CLEARKEYBOARD:
				move.l	#KeyMap,a5
				moveq	#0,d0
				move.w	#15,d1
clrloo:
				move.l	d0,(a5)+
				move.l	d0,(a5)+
				move.l	d0,(a5)+
				move.l	d0,(a5)+
				dbra	d1,clrloo
				rts

READCONTROLS:	dc.w	0

tstststst:		dc.w	0

BollocksRoom:
				dc.w	-1
				ds.l	50

GUNYOFFS:
				dc.w	20
				dc.w	20
				dc.w	0
				dc.w	20
				dc.w	20
				dc.w	0
				dc.w	0
				dc.w	20

PLR1_BOBBLEY:	dc.l	0
PLR2_BOBBLEY:	dc.l	0

IVEWONTEXT:
;      12345678901234567890123456789012345678901234567890123456789012345678901234567890
				dc.b	'Enemy Player Vanquished!                '
				dc.b	'                                        '
				dc.b	'Enemy Player Vanquished!                '
				dc.b	'                                        '

				dc.b	'Oooh, that one must have hurt!          '
				dc.b	'                                        '
				dc.b	'Oooh, that one must have hurt!          '
				dc.b	'                                        '

				dc.b	'Opponent IS toast!                      '
				dc.b	'                                        '
				dc.b	'Opponent IS toast!                      '
				dc.b	'                                        '

				dc.b	'Does it hurt? DOES it? DOES IT?!?       '
				dc.b	'                                        '
				dc.b	'Does it hurt? DOES it? DOES IT?!?       '
				dc.b	'                                        '

				dc.b	"Gosh, I",39,"m dreadfully sorry, old chap; didn't see you there!                     "
				dc.b	"Gosh, I",39,"m dreadfully sorry, old chap; didn't see you there!                     "

				dc.b	'Now go away before I taunt you a second time.                                   '
				dc.b	'Now go away before I taunt you a second time.                                   '

				dc.b	'Eh, sorry about that there mate, didn',39,'t know it was loaded, know worra mean?    '
				dc.b	'Eh, sorry about that there mate, didn',39,'t know it was loaded, know worra mean?    '

				dc.b	'Stand and deliver, your money or...  oh. Never mind.                            '
				dc.b	'Stand and deliver, your money or...  oh. Never mind.                            '

				dc.b	'Thank you for your kind interest, I look forward to your custom in future lives.'
				dc.b	'Thank you for your kind interest, I look forward to your custom in future lives.'


USEPLR1:

***********************************

				move.l	Plr1_ObjectPtr_l,a0
				move.b	#4,16(a0)
				move.l	Lvl_ObjectPointsPtr_l,a1
				move.l	#ObjRotated_vl,a2
				move.w	(a0),d0
				move.l	Plr1_XOff_l,(a1,d0.w*8)
				move.l	Plr1_ZOff_l,4(a1,d0.w*8)
				move.l	Plr1_RoomPtr_l,a1

				moveq	#0,d2
				move.b	EntT_DamageTaken_b(a0),d2
				beq		.notbeenshot

				moveq	#0,d4
				move.w	EntT_ImpactX_w(a0),d3
				beq.s	.notwist
				move.w	d2,d4
.notwist:
				add.w	d3,Plr1_SnapXSpdVal_l
				move.w	EntT_ImpactZ_w(a0),d3
				beq.s	.notwist2
				move.w	d2,d4
.notwist2:
				add.w	d3,Plr1_SnapZSpdVal_l
				move.w	EntT_ImpactY_w(a0),d3
				ext.l	d3
				asl.l	#8,d3
				add.l	d3,Plr1_SnapYVel_l

				move.w	#0,EntT_ImpactX_w(a0)
				move.w	#0,EntT_ImpactY_w(a0)
				move.w	#0,EntT_ImpactZ_w(a0)

				jsr		GetRand
				muls	d4,d0
				asr.l	#8,d0
				asr.l	#4,d0
				add.w	d0,Plr1_SnapAngSpd_w

				move.l	#7*2116,hitcol
				sub.w	d2,PLAYERONEHEALTH
				movem.l	d0-d7/a0-a6,-(a7)
				move.w	#$fffa,IDNUM
				move.w	#19,Samplenum
				clr.b	notifplaying
				move.w	#0,Noisex
				move.w	#0,Noisez
				move.w	#60,Noisevol
				jsr		MakeSomeNoise

				movem.l	(a7)+,d0-d7/a0-a6

.notbeenshot
				move.b	#0,EntT_DamageTaken_b(a0)
				move.b	#10,EntT_NumLives_b(a0)

				move.w	Plr1_TmpAngPos_w,EntT_CurrentAngle_w(a0)
				move.b	Plr1_StoodInTop_b,ShotT_InUpperZone_b(a0)

				move.w	(a1),12(a0)
				move.w	(a1),d2
				move.l	#ZoneBrightTable,a1
				move.l	(a1,d2.w*4),d2
				tst.b	Plr1_StoodInTop_b
				bne.s	.okinbott
				swap	d2
.okinbott:

				move.w	d2,2(a0)


				move.l	Plr1_TmpYOff_l,d0
				move.l	Plr1_TmpHeight_l,d1
				asr.l	#1,d1
				add.l	d1,d0
				asr.l	#7,d0
				move.w	d0,4(a0)

				tst.w	PLAYERONEHEALTH
				bgt.s	.okh1
				move.w	#-1,12(a0)
.okh1:


***********************************

				move.l	Plr2_ObjectPtr_l,a0
				move.b	#5,16(a0)

				move.w	Plr2_TmpAngPos_w,d0
				and.w	#8190,d0
				move.w	d0,EntT_CurrentAngle_w(a0)
;
; jsr ViewpointToDraw
; asl.w #2,d0
; moveq #0,d1
; move.b Plr2_TmpBobble_w,d1
; not.b d1
; lsr.b #3,d1
; and.b #$3,d1
; add.w d1,d0
; move.w d0,10(a0)
; move.w #10,8(a0)
;

				move.l	Lvl_ObjectPointsPtr_l,a1
				move.l	#ObjRotated_vl,a2
				move.w	(a0),d0
				move.l	Plr2_XOff_l,(a1,d0.w*8)
				move.l	Plr2_ZOff_l,4(a1,d0.w*8)
				move.l	Plr2_RoomPtr_l,a1

				moveq	#0,d2
				move.b	EntT_DamageTaken_b(a0),d2
				beq		.notbeenshot2
				move.w	EntT_ImpactX_w(a0),d3
				add.w	d3,Plr2_SnapXSpdVal_l
				move.w	EntT_ImpactZ_w(a0),d3
				add.w	d3,Plr2_SnapZSpdVal_l
				move.w	EntT_ImpactY_w(a0),d3
				ext.l	d3
				asl.l	#8,d3
				add.l	d3,Plr2_SnapYVel_l

				move.w	#0,EntT_ImpactX_w(a0)
				move.w	#0,EntT_ImpactY_w(a0)
				move.w	#0,EntT_ImpactZ_w(a0)

				sub.w	d2,PLAYERTWOHEALTH


.notbeenshot2
				move.b	#0,EntT_DamageTaken_b(a0)
				move.b	#10,EntT_NumLives_b(a0)

				move.b	Plr2_StoodInTop_b,ShotT_InUpperZone_b(a0)

				move.w	(a1),12(a0)
				move.w	(a1),d2
				move.l	#ZoneBrightTable,a1
				move.l	(a1,d2.w*4),d2
				tst.b	Plr2_StoodInTop_b
				bne.s	.okinbott2
				swap	d2
.okinbott2:

				move.w	d2,2(a0)

				move.l	Plr2_TmpYOff_l,d0
				move.l	Plr2_TmpHeight_l,d1
				asr.l	#1,d1
				add.l	d1,d0
				asr.l	#7,d0
				move.w	d0,4(a0)

				jsr		ViewpointToDraw
				add.l	d0,d0

				move.l	GLF_DatabasePtr_l,a6
				add.l	#GLFT_Player2Graphic_w,a6
				move.w	(a6),d7
				move.w	d7,d1

				move.l	GLF_DatabasePtr_l,a6
				add.l	#GLFT_AlienDefs_l,a6
				muls	#AlienT_SizeOf_l,d1
				add.l	d1,a6
				move.b	AlienT_GFXType_w+1(a6),AI_VecObj_w
				cmp.w	#1,AlienT_GFXType_w(a6)
				bne.s	.NOSIDES2

				moveq	#0,d0

.NOSIDES2:

				move.l	GLF_DatabasePtr_l,a6

				add.l	#GLFT_AlienAnims_l,a6

				move.w	d7,d1
				muls	#A_AnimLen,d1
				add.l	d1,a6

; move.l ANIMPOINTER,a6

				muls	#A_OptLen,d0
				add.w	d0,a6

				move.w	EntT_Timer2_w(a0),d1
				move.w	d1,d2
				muls	#A_FrameLen,d1

				addq	#1,d2

				move.w	d2,d3
				muls	#A_FrameLen,d3
				tst.b	(a6,d3.w)
				bge.s	.noendanim
				move.w	#0,d2
.noendanim
				move.w	d2,EntT_Timer2_w(a0)

				move.w	d2,d1

				muls	#A_FrameLen,d1

				move.l	#0,8(a0)
				move.b	(a6,d1.w),9(a0)
				move.b	1(a6,d1.w),d0
				ext.w	d0
				bgt.s	.noflip
				move.b	#128,10(a0)
				neg.w	d0
.noflip:
				sub.w	#1,d0
				move.b	d0,11(a0)

				move.w	#-1,6(a0)
				cmp.b	#1,AI_VecObj_w
				beq.s	.nosize
				bgt.s	.setlight
				move.w	2(a6,d1.w),6(a0)
				bra.s	.ddone

.nosize

; move.l #$00090001,8(a0)

				bra.s	.ddone

.setlight:
				move.w	2(a6,d1.w),6(a0)

				move.b	AI_VecObj_w,d1
				or.b	d1,10(a0)

.ddone:


				tst.w	PLAYERTWOHEALTH
				bgt.s	.okh
				move.w	#-1,12(a0)
.okh:


**********************************

				move.l	Plr1_ObjectPtr_l,a0

				tst.w	PLAYERONEHEALTH
				bgt.s	.notdead

				move.w	#-1,12+128(a0)
				rts

.notdead:
				move.l	Plr1_RoomPtr_l,a1

				move.w	EntT_CurrentAngle_w(a0),d0
				add.w	#4096,d0
				and.w	#8190,d0
				move.w	d0,EntT_CurrentAngle_w+128(a0)

				move.w	(a1),12+128(a0)
				move.w	(a1),EntT_GraphicRoom_w+128(a0)

				moveq	#0,d0
				move.b	Plr1_TmpGunSelected_b,d0

				move.l	GLF_DatabasePtr_l,a1
				add.l	#GLFT_GunObjects_l,a1
				move.w	(a1,d0.w*2),d0

				move.b	d0,EntT_Type_b+128(a0)
				move.b	#1,128+16(a0)

				move.w	(a0),d0
				move.w	128(a0),d1
				move.l	Lvl_ObjectPointsPtr_l,a1
				move.l	(a1,d0.w*8),(a1,d1.w*8)
				move.l	4(a1,d0.w*8),4(a1,d1.w*8)

				st		EntT_WhichAnim_b+128(a0)

				move.l	Plr1_TmpYOff_l,d0
				move.l	Plr1_TmpHeight_l,d1
				asr.l	#2,d1
				add.l	#10*128,d1
				add.l	d1,d0
				asr.l	#7,d0
				move.w	d0,4+128(a0)
				move.l	PLR1_BOBBLEY,d1
				asr.l	#8,d1
				move.l	d1,d0
				asr.l	#1,d0
				add.l	d0,d1
				add.w	d1,4+128(a0)

				move.b	ShotT_InUpperZone_b(a0),ShotT_InUpperZone_b+128(a0)

				rts

***************************************************
**************************************************

USEPLR2:

***********************************

				move.l	Plr2_ObjectPtr_l,a0
				move.b	#5,16(a0)
				move.l	Lvl_ObjectPointsPtr_l,a1
				move.l	#ObjRotated_vl,a2
				move.w	(a0),d0
				move.l	Plr2_XOff_l,(a1,d0.w*8)
				move.l	Plr2_ZOff_l,4(a1,d0.w*8)
				move.l	Plr2_RoomPtr_l,a1

				moveq	#0,d2
				move.b	EntT_DamageTaken_b(a0),d2
				beq		.notbeenshot

				moveq	#0,d4
				move.w	EntT_ImpactX_w(a0),d3
				beq.s	.notwist
				move.w	d2,d4
.notwist:
				add.w	d3,Plr2_SnapXSpdVal_l
				move.w	EntT_ImpactZ_w(a0),d3
				beq.s	.notwist2
				move.w	d2,d4
.notwist2:
				add.w	d3,Plr2_SnapZSpdVal_l

				jsr		GetRand
				muls	d4,d0
				asr.l	#8,d0
				asr.l	#4,d0
				add.w	d0,Plr2_SnapAngSpd_w

				move.l	#7*2116,hitcol
				sub.w	d2,PLAYERTWOHEALTH


				movem.l	d0-d7/a0-a6,-(a7)
				move.w	#19,Samplenum
				clr.b	notifplaying
				move.w	#$fffa,IDNUM
				move.w	#0,Noisex
				move.w	#0,Noisez
				move.w	#60,Noisevol
				jsr		MakeSomeNoise

				movem.l	(a7)+,d0-d7/a0-a6

.notbeenshot
				move.b	#0,EntT_DamageTaken_b(a0)
				move.b	#10,EntT_NumLives_b(a0)

				move.w	Plr2_TmpAngPos_w,EntT_CurrentAngle_w(a0)
				move.b	Plr2_StoodInTop_b,ShotT_InUpperZone_b(a0)

				move.w	(a1),12(a0)
				move.w	(a1),d2
				move.l	#ZoneBrightTable,a1
				move.l	(a1,d2.w*4),d2
				tst.b	Plr2_StoodInTop_b
				bne.s	.okinbott
				swap	d2
.okinbott:

				move.w	d2,2(a0)

				move.l	Plr2_YOff_l,d0
				move.l	Plr2_TmpHeight_l,d1
				asr.l	#1,d1
				add.l	d1,d0
				asr.l	#7,d0
				move.w	d0,4(a0)

				tst.w	PLAYERTWOHEALTH
				bgt.s	.okh55
				move.w	#-1,12(a0)
.okh55:

***********************************

				move.l	Plr1_ObjectPtr_l,a0
				move.b	#4,16(a0)

				move.w	Plr1_AngPos_w,d0
				and.w	#8190,d0
				move.w	d0,EntT_CurrentAngle_w(a0)
;
; jsr ViewpointToDraw
; asl.w #2,d0
; moveq #0,d1
; move.b Plr2_TmpBobble_w,d1
; not.b d1
; lsr.b #3,d1
; and.b #$3,d1
; add.w d1,d0
; move.w d0,10(a0)
; move.w #10,8(a0)
;

				move.l	Lvl_ObjectPointsPtr_l,a1
				move.l	#ObjRotated_vl,a2
				move.w	(a0),d0
				move.l	Plr1_XOff_l,(a1,d0.w*8)
				move.l	Plr1_ZOff_l,4(a1,d0.w*8)
				move.l	Plr1_RoomPtr_l,a1

				moveq	#0,d2
				move.b	EntT_DamageTaken_b(a0),d2
				beq		.notbeenshot2

				move.w	EntT_ImpactX_w(a0),d3
				add.w	d3,Plr1_SnapXSpdVal_l
				move.w	EntT_ImpactZ_w(a0),d3
				add.w	d3,Plr1_SnapZSpdVal_l

				sub.w	d2,PLAYERONEHEALTH


.notbeenshot2
				move.b	#0,EntT_DamageTaken_b(a0)
				move.b	#10,EntT_NumLives_b(a0)

				move.b	Plr1_StoodInTop_b,ShotT_InUpperZone_b(a0)

				move.w	(a1),12(a0)
				move.w	(a1),d2
				move.l	#ZoneBrightTable,a1
				move.l	(a1,d2.w*4),d2
				tst.b	Plr1_StoodInTop_b
				bne.s	.okinbott2
				swap	d2
.okinbott2:

				move.w	d2,2(a0)

				move.l	Plr1_TmpYOff_l,d0
				move.l	Plr1_TmpHeight_l,d1
				asr.l	#1,d1
				add.l	d1,d0
				asr.l	#7,d0
				move.w	d0,4(a0)

				jsr		ViewpointToDraw
				add.l	d0,d0

				move.l	GLF_DatabasePtr_l,a6
				add.l	#GLFT_Player1Graphic_w,a6
				move.w	(a6),d7
				move.w	d7,d1

				move.l	GLF_DatabasePtr_l,a6
				add.l	#GLFT_AlienDefs_l,a6
				muls	#AlienT_SizeOf_l,d1
				add.l	d1,a6
				move.b	AlienT_GFXType_w+1(a6),AI_VecObj_w
				cmp.w	#1,AlienT_GFXType_w(a6)
				bne.s	.NOSIDES2

				moveq	#0,d0

.NOSIDES2:

				move.l	GLF_DatabasePtr_l,a6

				add.l	#GLFT_AlienAnims_l,a6

				move.w	d7,d1
				muls	#A_AnimLen,d1
				add.l	d1,a6

; move.l ANIMPOINTER,a6

				muls	#A_OptLen,d0
				add.w	d0,a6

				move.w	EntT_Timer2_w(a0),d1
				move.w	d1,d2
				muls	#A_FrameLen,d1

				addq	#1,d2

				move.w	d2,d3
				muls	#A_FrameLen,d3
				tst.b	(a6,d3.w)
				bge.s	.noendanim
				move.w	#0,d2
.noendanim
				move.w	d2,EntT_Timer2_w(a0)

				move.w	d2,d1

				muls	#A_FrameLen,d1

				move.l	#0,8(a0)
				move.b	(a6,d1.w),9(a0)
				move.b	1(a6,d1.w),d0
				ext.w	d0
				bgt.s	.noflip
				move.b	#128,10(a0)
				neg.w	d0
.noflip:
				sub.w	#1,d0
				move.b	d0,11(a0)

				move.w	#-1,6(a0)
				cmp.b	#1,AI_VecObj_w
				beq.s	.nosize
				bgt.s	.setlight
				move.w	2(a6,d1.w),6(a0)
				bra.s	.ddone

.nosize

; move.l #$00090001,8(a0)

				bra.s	.ddone

.setlight:
				move.w	2(a6,d1.w),6(a0)

				move.b	AI_VecObj_w,d1
				or.b	d1,10(a0)

.ddone:

				tst.w	PLAYERONEHEALTH
				bgt.s	.okh
				move.w	#-1,12(a0)
.okh:

**********************************

				move.l	Plr2_ObjectPtr_l,a0
				tst.w	PLAYERTWOHEALTH
				bgt.s	.notdead
				move.w	#-1,12+64(a0)
				rts

.notdead:
				move.l	Plr2_RoomPtr_l,a1

				move.w	EntT_CurrentAngle_w(a0),d0
				add.w	#4096,d0
				and.w	#8190,d0
				move.w	d0,EntT_CurrentAngle_w+64(a0)

				move.w	(a1),12+64(a0)
				move.w	(a1),EntT_GraphicRoom_w+64(a0)

				moveq	#0,d0
				move.b	Plr2_TmpGunSelected_b,d0

				move.l	GLF_DatabasePtr_l,a1
				add.l	#GLFT_GunObjects_l,a1
				move.w	(a1,d0.w*2),d0

				move.b	d0,EntT_Type_b+64(a0)
				move.b	#1,64+16(a0)

				move.w	(a0),d0
				move.w	64(a0),d1
				move.l	Lvl_ObjectPointsPtr_l,a1
				move.l	(a1,d0.w*8),(a1,d1.w*8)
				move.l	4(a1,d0.w*8),4(a1,d1.w*8)

				st		EntT_WhichAnim_b+64(a0)

				move.l	Plr2_TmpYOff_l,d0
				move.l	Plr2_TmpHeight_l,d1
				asr.l	#2,d1
				add.l	#10*128,d1
				add.l	d1,d0
				asr.l	#7,d0
				move.w	d0,4+64(a0)
				move.l	PLR2_BOBBLEY,d1
				asr.l	#8,d1
				move.l	d1,d0
				asr.l	#1,d0
				add.l	d0,d1
				add.w	d1,4+64(a0)

				move.b	ShotT_InUpperZone_b(a0),ShotT_InUpperZone_b+64(a0)

				rts

GunSelected:	dc.b	0
				even


GunData:		dc.l	0

Path:
; incbin "testpath"
endpath:
pathpt:			dc.l	Path


Plr1_Keys_b:		dc.b	0
Plr1_Path_b:		dc.b	0
Plr1_Mouse_b:		dc.b	-1
Plr1_Joystick_b:	dc.b	0
Plr2_Keys_b:		dc.b	0
Plr2_Path_b:		dc.b	0
Plr2_Mouse_b:		dc.b	-1
Plr2_Joystick_b:	dc.b	0

				even

Plr1_Bobble_w:	dc.w	0
Plr2_Bobble_w:	dc.w	0
xwobble:		dc.l	0
xwobxoff:		dc.w	0
xwobzoff:		dc.w	0

PLR1_Control:

; Take a snapshot of everything.

				move.l	Plr1_XOff_l,d2
				move.l	d2,oldx
				move.l	Plr1_ZOff_l,d3
				move.l	d3,oldz
				move.l	Plr1_TmpXOff_l,d0
				move.l	d0,Plr1_XOff_l
				move.l	d0,newx
				move.l	Plr1_TmpZOff_l,d1
				move.l	d1,newz
				move.l	d1,Plr1_ZOff_l

				move.l	Plr1_TmpHeight_l,Plr1_Height_l

				sub.l	d2,d0
				sub.l	d3,d1
				move.l	d0,xdiff
				move.l	d1,zdiff
				move.w	Plr1_TmpAngPos_w,d0
				move.w	d0,Plr1_AngPos_w

				move.l	#SineTable,a1
				move.w	(a1,d0.w),Plr1_SinVal_w
				add.w	#2048,d0
				and.w	#8190,d0
				move.w	(a1,d0.w),Plr1_CosVal_w

				move.l	Plr1_TmpYOff_l,d0
				move.w	Plr1_TmpBobble_w,d1
				move.w	(a1,d1.w),d1
				move.w	d1,d3
				ble.s	.notnegative
				neg.w	d1
.notnegative:
				add.w	#16384,d1
				asr.w	#4,d1

				tst.b	Plr1_Ducked_b
				bne.s	.notdouble
				tst.b	Plr1_Squished_b
				bne.s	.notdouble
				add.w	d1,d1
.notdouble
				ext.l	d1

				move.l	d1,PLR1_BOBBLEY

				move.l	Plr1_Height_l,d4
				sub.l	d1,d4
				add.l	d1,d0

				cmp.b	#PLR_SLAVE,Plr_MultiplayerType_b
				beq.s	.otherwob
				asr.w	#6,d3
				ext.l	d3
				move.l	d3,xwobble
				move.w	Plr1_SinVal_w,d1
				muls	d3,d1
				move.w	Plr1_CosVal_w,d2
				muls	d3,d2
				swap	d1
				swap	d2
				asr.w	#7,d1
				move.w	d1,xwobxoff				; xwobble
				asr.w	#7,d2
				neg.w	d2
				move.w	d2,xwobzoff
.otherwob

				move.l	d0,Plr1_YOff_l
				move.l	d0,newy
				move.l	d0,oldy

				move.l	d4,thingheight
				move.l	#40*256,StepUpVal
				tst.b	Plr1_Squished_b
				bne.s	.smallstep
				tst.b	Plr1_Ducked_b
				beq.s	.okbigstep
.smallstep
				move.l	#10*256,StepUpVal
.okbigstep:

				move.l	#$1000000,StepDownVal

				move.l	Plr1_RoomPtr_l,a0
				move.w	ZoneT_TelZone_w(a0),d0
				blt		.noteleport

				move.w	ZoneT_TelX_w(a0),newx
				move.w	ZoneT_TelZ_w(a0),newz

				move.l	Plr1_ObjectPtr_l,a0
				move.w	(a0),CollId

				move.l	#%111111111111111111,CollideFlags
				jsr		Collision
				tst.b	hitwall
				beq.s	.teleport

				move.w	Plr1_XOff_l,newx
				move.w	Plr1_ZOff_l,newz
				bra		.noteleport

.teleport:

				st		Plr1_Teleported_b

				move.l	Plr1_RoomPtr_l,a0
				move.w	ZoneT_TelZone_w(a0),d0
				move.w	ZoneT_TelX_w(a0),Plr1_XOff_l
				move.w	ZoneT_TelZ_w(a0),Plr1_ZOff_l
				move.l	Plr1_YOff_l,d1
				sub.l	ZoneT_Floor_l(a0),d1
				move.l	Lvl_ZoneAddsPtr_l,a0
				move.l	(a0,d0.w*4),a0
				add.l	Lvl_DataPtr_l,a0
				move.l	a0,Plr1_RoomPtr_l
				add.l	ZoneT_Floor_l(a0),d1
				move.l	d1,Plr1_SnapYOff_l
				move.l	d1,Plr1_YOff_l
				move.l	d1,Plr1_SnapTYOff_l
				move.l	Plr1_XOff_l,Plr1_SnapXOff_l
				move.l	Plr1_ZOff_l,Plr1_SnapZOff_l

				SAVEREGS
				move.w	#0,Noisex
				move.w	#0,Noisez
				move.w	#26,Samplenum
				move.w	#100,Noisevol
				move.w	#$fff9,IDNUM
				jsr		MakeSomeNoise
				GETREGS

				bra		.cantmove

.noteleport:

				move.l	Plr1_RoomPtr_l,objroom
				move.w	#%100000000,wallflags
				move.b	Plr1_StoodInTop_b,StoodInTop

				move.l	#%1011111110111000011,CollideFlags
				move.l	Plr1_ObjectPtr_l,a0
				move.w	(a0),CollId

				jsr		Collision
				tst.b	hitwall
				beq.s	.nothitanything
				move.w	oldx,Plr1_XOff_l
				move.w	oldz,Plr1_ZOff_l
				move.l	Plr1_XOff_l,Plr1_SnapXOff_l
				move.l	Plr1_ZOff_l,Plr1_SnapZOff_l
				bra		.cantmove
.nothitanything:

				move.w	#40,extlen
				move.b	#0,awayfromwall

				clr.b	exitfirst
				clr.b	wallbounce
				bsr		MoveObject
				move.b	StoodInTop,Plr1_StoodInTop_b
				move.l	objroom,Plr1_RoomPtr_l
				move.w	newx,Plr1_XOff_l
				move.w	newz,Plr1_ZOff_l
				move.l	Plr1_XOff_l,Plr1_SnapXOff_l
				move.l	Plr1_ZOff_l,Plr1_SnapZOff_l

.cantmove:

				move.l	Plr1_RoomPtr_l,a0

				move.l	ZoneT_Floor_l(a0),d0
				tst.b	Plr1_StoodInTop_b
				beq.s	notintop
				move.l	ZoneT_UpperFloor_l(a0),d0
notintop:

				adda.w	#ZoneT_Points_w,a0
				sub.l	Plr1_Height_l,d0
				move.l	d0,Plr1_SnapTYOff_l
				move.w	Plr1_TmpAngPos_w,tmpangpos

; move.l (a0),a0		; jump to viewpoint list
* A0 is pointing at a pointer to list of points to rotate
				move.w	(a0)+,d1
				ext.l	d1
				add.l	Plr1_RoomPtr_l,d1
				move.l	d1,Plr1_PointsToRotatePtr_l
				tst.b	(a0)+
				sne		DRAWNGRAPHTOP
				beq.s	nobackgraphics
				cmp.b	#PLR_SLAVE,Plr_MultiplayerType_b
				beq.s	nobackgraphics
				move.l	a0,-(a7)
				jsr		putinbackdrop
				move.l	(a7)+,a0
nobackgraphics:

				move.b	(a0)+,Plr1_Echo_b

				adda.w	#10,a0
				move.l	a0,Plr1_ListOfGraphRoomsPtr_l

*************************************************
				rts

DRAWNGRAPHTOP
				dc.w	0
tstzone:		dc.l	0
CollId:			dc.w	0

PLR2_Control:

; Take a snapshot of everything.

				move.l	Plr2_XOff_l,d2

				move.l	d2,oldx
				move.l	Plr2_ZOff_l,d3

				move.l	d3,oldz
				move.l	Plr2_TmpXOff_l,d0
				move.l	d0,Plr2_XOff_l
				move.l	d0,newx
				move.l	Plr2_TmpZOff_l,d1
				move.l	d1,newz
				move.l	d1,Plr2_ZOff_l

				move.l	Plr2_TmpHeight_l,Plr2_Height_l

				sub.l	d2,d0
				sub.l	d3,d1
				move.l	d0,xdiff
				move.l	d1,zdiff
				move.w	Plr2_TmpAngPos_w,d0
				move.w	d0,Plr2_AngPos_w

				move.l	#SineTable,a1
				move.w	(a1,d0.w),Plr2_SinVal_w
				add.w	#2048,d0
				and.w	#8190,d0
				move.w	(a1,d0.w),Plr2_CosVal_w

				move.l	Plr2_TmpYOff_l,d0
				move.w	Plr2_TmpBobble_w,d1
				move.w	(a1,d1.w),d1
				move.w	d1,d3
				ble.s	.notnegative
				neg.w	d1
.notnegative:
				add.w	#16384,d1
				asr.w	#4,d1

				tst.b	Plr2_Ducked_b
				bne.s	.notdouble
				tst.b	Plr2_Squished_b
				bne.s	.notdouble
				add.w	d1,d1
.notdouble
				ext.l	d1

				move.l	d1,PLR2_BOBBLEY

				move.l	Plr2_Height_l,d4
				sub.l	d1,d4
				add.l	d1,d0

				cmp.b	#PLR_SLAVE,Plr_MultiplayerType_b
				bne.s	.otherwob
				asr.w	#6,d3
				ext.l	d3
				move.l	d3,xwobble
				move.w	Plr2_SinVal_w,d1
				muls	d3,d1
				move.w	Plr2_CosVal_w,d2
				muls	d3,d2
				swap	d1
				swap	d2
				asr.w	#7,d1
				move.w	d1,xwobxoff
				asr.w	#7,d2
				neg.w	d2
				move.w	d2,xwobzoff
.otherwob

				move.l	d0,Plr2_YOff_l
				move.l	d0,newy
				move.l	d0,oldy

				move.l	d4,thingheight
				move.l	#40*256,StepUpVal
				tst.b	Plr2_Squished_b
				bne.s	.smallstep
				tst.b	Plr2_Ducked_b
				beq.s	.okbigstep
.smallstep:
				move.l	#10*256,StepUpVal
.okbigstep:

				move.l	#$1000000,StepDownVal

				move.l	Plr2_RoomPtr_l,a0
				move.w	ZoneT_TelZone_w(a0),d0
				blt		.noteleport

				move.w	ZoneT_TelX_w(a0),newx
				move.w	ZoneT_TelZ_w(a0),newz
				move.w	Plr2_ObjectPtr_l,a0 ; 0xABADCAFE - word size - is this a bug?
				move.w	(a0),CollId
				move.l	#%111111111111111111,CollideFlags
				jsr		Collision
				tst.b	hitwall
				beq.s	.teleport

				move.w	Plr2_XOff_l,newx
				move.w	Plr2_ZOff_l,newz
				bra		.noteleport

.teleport:

				st		Plr2_Teleported_b

				move.l	Plr2_RoomPtr_l,a0
				move.w	ZoneT_TelZone_w(a0),d0
				move.w	ZoneT_TelX_w(a0),Plr2_XOff_l
				move.w	ZoneT_TelZ_w(a0),Plr2_ZOff_l
				move.l	Plr2_YOff_l,d1
				sub.l	ZoneT_Floor_l(a0),d1
				move.l	Lvl_ZoneAddsPtr_l,a0
				move.l	(a0,d0.w*4),a0
				add.l	Lvl_DataPtr_l,a0
				move.l	a0,Plr2_RoomPtr_l
				add.l	ZoneT_Floor_l(a0),d1
				move.l	d1,Plr2_SnapYOff_l
				move.l	d1,Plr2_YOff_l
				move.l	d1,Plr2_SnapTYOff_l
				move.l	Plr2_XOff_l,Plr2_SnapXOff_l
				move.l	Plr2_ZOff_l,Plr2_SnapZOff_l

				SAVEREGS
				move.w	#0,Noisex
				move.w	#0,Noisez
				move.w	#26,Samplenum
				move.w	#100,Noisevol
				move.w	#$fff9,IDNUM
				jsr		MakeSomeNoise
				GETREGS

				bra		.cantmove

.noteleport:

				move.l	Plr2_RoomPtr_l,objroom
				move.w	#%100000000000,wallflags
				move.b	Plr2_StoodInTop_b,StoodInTop

				move.l	#%1011111010111100011,CollideFlags
				move.l	Plr2_ObjectPtr_l,a0
				move.w	(a0),CollId

				jsr		Collision
				tst.b	hitwall
				beq.s	.nothitanything
				move.w	oldx,Plr2_XOff_l
				move.w	oldz,Plr2_ZOff_l
				move.l	Plr2_XOff_l,Plr2_SnapXOff_l
				move.l	Plr2_ZOff_l,Plr2_SnapZOff_l
				bra		.cantmove
.nothitanything:

				move.w	#40,extlen
				move.b	#0,awayfromwall

				clr.b	exitfirst
				clr.b	wallbounce
				bsr		MoveObject
				move.b	StoodInTop,Plr2_StoodInTop_b
				move.l	objroom,Plr2_RoomPtr_l
				move.w	newx,Plr2_XOff_l
				move.w	newz,Plr2_ZOff_l
				move.l	Plr2_XOff_l,Plr2_SnapXOff_l
				move.l	Plr2_ZOff_l,Plr2_SnapZOff_l

.cantmove

				move.l	Plr2_RoomPtr_l,a0

				move.l	ZoneT_Floor_l(a0),d0
				tst.b	Plr2_StoodInTop_b
				beq.s	.notintop
				move.l	ZoneT_UpperFloor_l(a0),d0
.notintop:

				adda.w	#ZoneT_Points_w,a0
				sub.l	Plr2_Height_l,d0
				move.l	d0,Plr2_SnapTYOff_l
				move.w	Plr2_TmpAngPos_w,tmpangpos

; move.l (a0),a0		; jump to viewpoint list
* A0 is pointing at a pointer to list of points to rotate
				move.w	(a0)+,d1
				ext.l	d1
				add.l	Plr2_RoomPtr_l,d1
				move.l	d1,Plr2_PointsToRotatePtr_l
				tst.b	(a0)+
				sne		DRAWNGRAPHTOP
				beq.s	.nobackgraphics
				cmp.b	#PLR_SLAVE,Plr_MultiplayerType_b
				bne.s	.nobackgraphics
				move.l	a0,-(a7)
				jsr		putinbackdrop
				move.l	(a7)+,a0
.nobackgraphics:

				move.b	(a0)+,Plr2_Echo_b

				adda.w	#10,a0
				move.l	a0,Plr2_ListOfGraphRoomsPtr_l

*****************************************************
				rts


KeyMap:			ds.b	256

fillscrnwater:
				dc.w	0
DONTDOGUN:
				dc.w	0

;temptemp: ds.l 200
;temptempptr: dc.l 0

DrawDisplay:

; move.l #temptemp,temptempptr

				clr.b	fillscrnwater

				; bignsine is 16kb = 8192 words for 4pi (720deg)
				; --> 4096 words per 2pi
				; --> 1024 words = 2048byte per 90deg

				move.l	#SineTable,a0
				move.w	angpos,d0
				move.w	(a0,d0.w),d6
				adda.w	#2048,a0				; +90 deg?
				move.w	(a0,d0.w),d7
				move.w	d6,sinval
				move.w	d7,cosval

				move.l	yoff,d0
				asr.l	#8,d0					; yoff >> 8
				move.w	d0,d1
				add.w	#256-32,d1				; 224
				and.w	#255,d1
				move.w	d1,wallyoff

				move.l	yoff,d0					; is yoff the viewer's y position << 16?
				asr.l	#6,d0					; yoff << 10
				move.w	d0,flooryoff			; yoff << 10

				move.w	xoff,d6
				move.w	d6,d3
				asr.w	#1,d3					; xoff * 0.5
				add.w	d3,d6					; xoff * 1.5
				asr.w	#1,d6					; xoff * 0.75
				move.w	d6,xoff34				; xoff * 3/4

				move.w	zoff,d6
				move.w	d6,d3
				asr.w	#1,d3
				add.w	d3,d6
				asr.w	#1,d6
				move.w	d6,zoff34				; zoff * 3/4

				bsr		RotateLevelPts
				bsr		RotateObjectPts
				bsr		CalcPLR1InLine

				cmp.b	#PLR_NEITHER,Plr_MultiplayerType_b
				bne.s	doplr2too
				move.l	Plr2_ObjectPtr_l,a0
				move.w	#-1,12(a0)
				move.w	#-1,EntT_GraphicRoom_w(a0)
				bra		noplr2either

doplr2too:
				bsr		CalcPLR2InLine
noplr2either:

				move.l	endoflist,a0
; move.w #-1,(a0)

; move.l #FinalOrder,a0


subroomloop:
; move.w (a0)+,d7
				move.w	-(a0),d7
				blt		jumpoutofrooms

; bsr setlrclip
; move.w leftclip,d0
; cmp.w rightclip,d0
; bge subroomloop
				move.l	a0,-(a7)

				move.l	Lvl_ZoneAddsPtr_l,a0
				move.l	(a0,d7.w*4),a0
				add.l	Lvl_DataPtr_l,a0
				move.l	ZoneT_Roof_l(a0),SplitHeight
				move.l	a0,ROOMBACK

				move.l	Lvl_ZoneGraphAddsPtr_l,a0
				move.l	4(a0,d7.w*8),a2
				move.l	(a0,d7.w*8),a0

				add.l	Lvl_GraphicsPtr_l,a0
				add.l	Lvl_GraphicsPtr_l,a2
				move.l	a2,ThisRoomToDraw+4
				move.l	a0,ThisRoomToDraw

				move.l	Lvl_ListOfGraphRoomsPtr_l,a1



finditit:
				tst.w	(a1)
				blt		nomoretodoatall
				cmp.w	(a1),d7
				beq		outoffind
				adda.w	#8,a1
				bra		finditit

outoffind:

				move.l	a1,-(a7)


				move.w	#0,leftclip
				move.w	Vid_RightX_w,rightclip
				moveq	#0,d7
				move.w	2(a1),d7
				blt.s	outofrcliplop
				move.l	Lvl_ClipsPtr_l,a0
				lea		(a0,d7.l*2),a0

				tst.w	(a0)
				blt		outoflcliplop

				bsr		NEWsetlclip

intolcliplop:	;		clips
				tst.w	(a0)
				blt		outoflcliplop

				bsr		NEWsetlclip
				bra		intolcliplop

outoflcliplop:

				addq	#2,a0

				tst.w	(a0)
				blt		outofrcliplop

				bsr		NEWsetrclip

intorcliplop:	;		clips
				tst.w	(a0)
				blt		outofrcliplop

				bsr		NEWsetrclip
				bra		intorcliplop

outofrcliplop:


				move.w	leftclip,d0
				ext.l	d0
				move.l	d0,leftclip-2

				cmp.w	Vid_RightX_w,d0
				bge		dontbothercantseeit
				move.w	rightclip,d1
				ext.l	d1
				move.l	d1,rightclip-2
				blt		dontbothercantseeit
				cmp.w	d1,d0
				bge		dontbothercantseeit

				move.l	yoff,d0
				cmp.l	SplitHeight,d0
				blt		botfirst

				move.l	ThisRoomToDraw+4,a0
				cmp.l	Lvl_GraphicsPtr_l,a0
				beq.s	noupperroom
				st		DOUPPER

				move.l	ROOMBACK,a1
				move.l	ZoneT_UpperRoof_l(a1),TOPOFROOM
				move.l	ZoneT_UpperFloor_l(a1),BOTOFROOM

				move.l	#CurrentPointBrights+4,PointBrightsPtr
				bsr		dothisroom
noupperroom:
				move.l	ThisRoomToDraw,a0
				clr.b	DOUPPER
				move.l	#CurrentPointBrights,PointBrightsPtr

				move.l	ROOMBACK,a1
				move.l	ZoneT_Roof_l(a1),d0
				move.l	d0,TOPOFROOM
				move.l	ZoneT_Floor_l(a1),d1
				move.l	d1,BOTOFROOM

				move.l	ZoneT_Water_l(a1),d2
				cmp.l	yoff,d2
				blt.s	.abovefirst
				move.l	d2,BEFOREWATTOP
				move.l	d1,BEFOREWATBOT
				move.l	d2,AFTERWATBOT
				move.l	d0,AFTERWATTOP
				bra.s	.belowfirst
.abovefirst:
				move.l	d0,BEFOREWATTOP
				move.l	d2,BEFOREWATBOT
				move.l	d1,AFTERWATBOT
				move.l	d2,AFTERWATTOP
.belowfirst:

				bsr		dothisroom

				bra		dontbothercantseeit
botfirst:

				move.l	ThisRoomToDraw,a0
				clr.b	DOUPPER
				move.l	#CurrentPointBrights,PointBrightsPtr

				move.l	ROOMBACK,a1
				move.l	ZoneT_Roof_l(a1),d0
				move.l	d0,TOPOFROOM
				move.l	ZoneT_Floor_l(a1),d1
				move.l	d1,BOTOFROOM

				move.l	ZoneT_Water_l(a1),d2
				cmp.l	yoff,d2
				blt.s	.abovefirst
				move.l	d2,BEFOREWATTOP
				move.l	d1,BEFOREWATBOT
				move.l	d2,AFTERWATBOT
				move.l	d0,AFTERWATTOP
				bra.s	.belowfirst
.abovefirst:
				move.l	d0,BEFOREWATTOP
				move.l	d2,BEFOREWATBOT
				move.l	d1,AFTERWATBOT
				move.l	d2,AFTERWATTOP
.belowfirst:


				bsr		dothisroom
				move.l	ThisRoomToDraw+4,a0
				cmp.l	Lvl_GraphicsPtr_l,a0
				beq.s	noupperroom2
				move.l	#CurrentPointBrights+4,PointBrightsPtr

				move.l	ROOMBACK,a1
				move.l	ZoneT_UpperRoof_l(a1),TOPOFROOM
				move.l	ZoneT_UpperFloor_l(a1),BOTOFROOM

				st		DOUPPER
				bsr		dothisroom
noupperroom2:

dontbothercantseeit:
pastemp:

				move.l	(a7)+,a1
				move.l	ThisRoomToDraw,a0
				move.w	(a0),d7

				adda.w	#8,a1
				bra		finditit

nomoretodoatall:

				move.l	(a7)+,a0

				bra		subroomloop

jumpoutofrooms:


				tst.b	DONTDOGUN
				bne		NOGUNLOOK

				cmp.b	#PLR_SLAVE,Plr_MultiplayerType_b
				beq.s	drawslavegun

				moveq	#0,d0
				move.b	Plr1_GunSelected_b,d0
				moveq	#0,d1
				move.b	PLR1_GunFrame,d1
; bsr DRAWINGUN
				bra		drawngun

drawslavegun
				moveq	#0,d0
				move.b	Plr2_GunSelected_b,d0
				moveq	#0,d1
				move.b	PLR2_GunFrame,d1
; bsr DRAWINGUN

drawngun:

NOGUNLOOK:

				moveq	#0,d1
				move.b	PLR1_GunFrame,d1
				sub.w	TempFrames,d1
				bgt.s	.nn
				moveq	#0,d1
.nn
				move.b	d1,PLR1_GunFrame

				ble.s	.donefire
				sub.b	#1,PLR1_GunFrame
.donefire:

				moveq	#0,d1
				move.b	PLR2_GunFrame,d1
				sub.w	TempFrames,d1
				bgt.s	.nn2
				moveq	#0,d1
.nn2
				move.b	d2,PLR2_GunFrame

				ble.s	.donefire2
				sub.b	#1,PLR2_GunFrame
.donefire2:

				tst.b	DOANYWATER
				beq.s	nowaterfull

				move.w	#FS_HEIGHT-1,d0
				move.l	Vid_FastBufferPtr_l,a0
				tst.b	fillscrnwater
				beq		nowaterfull
				bgt		oknothalf
				moveq	#FS_HEIGHT/2-1,d0
				add.l	#SCREENWIDTH*FS_HEIGHT/2,a0
oknothalf:

				bclr.b	#1,$bfe001

				move.l	TexturePal,a2
				add.l	#256*40,a2
				moveq	#0,d2

				tst.b	Vid_FullScreen_b
				bne.s	DOALLSCREEN

DOSOMESCREEN:

				move.w	#SMALL_HEIGHT-1,d0
.fw:
				move.w	#SMALL_WIDTH-1,d1
.fwa:
				move.b	(a0),d2
				move.b	(a2,d2.w),(a0)+
				dbra	d1,.fwa
				add.w	#(SCREENWIDTH-SMALL_WIDTH),a0
				dbra	d0,.fw
				rts

DOALLSCREEN:

fw:
				move.w	#FS_WIDTH-1,d1
fwa:
				move.b	(a0),d2
				move.b	(a2,d2.w),(a0)+
				dbra	d1,fwa
				add.w	#(SCREENWIDTH-FS_WIDTH),a0
				dbra	d0,fw

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
				bset.b	#1,$bfe001
				rts

ClipTable:		ds.l	30
EndOfClipPt:	dc.l	0
DOUPPER:		dc.w	0

dothisroom

				move.w	(a0)+,d0
				move.w	d0,Draw_CurrentZone_w
				move.w	d0,d1
				muls	#40,d1
				add.l	#BIGMAP,d1
				move.l	d1,BIGPTR
				move.w	d0,d1
				ext.l	d1
				asl.w	#2,d1
				add.l	#COMPACTMAP,d1
				move.l	d1,COMPACTPTR
				add.l	#4,d1
				cmp.l	LastZonePtr_l,d1
				ble.s	.nochange
				move.l	d1,LastZonePtr_l
.nochange:

				move.l	#ZoneBrightTable,a1
				move.l	(a1,d0.w*4),d1
				tst.b	DOUPPER
				bne.s	.okbot
				swap	d1
.okbot:
				move.w	d1,ZoneBright

polyloop:
				move.w	(a0)+,d0
				move.w	d0,WALLIDENT
				and.w	#$ff,d0
				tst.b	d0
				blt		jumpoutofloop
				beq		itsawall
				cmp.w	#3,d0
				beq		itsasetclip
				blt		itsafloor
				cmp.w	#4,d0
				beq		itsanobject

;				cmp.w	#5,d0
;				beq		itsanarc

;				cmp.w	#6,d0
;				beq		itsalightbeam
				cmp.w	#7,d0
				beq.s	itswater
				cmp.w	#9,d0
				ble		itsachunkyfloor
				cmp.w	#11,d0
				ble		itsabumpyfloor
				cmp.w	#12,d0
				beq.s	itsbackdrop
				cmp.w	#13,d0
				beq.s	itsaseewall

				bra		polyloop

itsaseewall:
				st		seethru
				jsr		itsawalldraw
				bra		polyloop

itsbackdrop:
				jsr		putinbackdrop
				bra		polyloop

itswater:
;PROTHCHECK
				move.w	#2,SMALLIT
				move.w	#3,d0
				clr.b	gourfloor
				move.l	#FloorLine,LineToUse
				st		usewater
				clr.b	usebumps
				jsr		itsafloordraw
				bra		polyloop

;itsanarc:
;				jsr		CurveDraw
;				bra		polyloop

itsanobject:
				jsr		Draw_Object
				bra		polyloop

;itsalightbeam:
;				jsr		LightDraw
;				bra		polyloop

itsabumpyfloor:
				move.w	#1,SMALLIT
				sub.w	#9,d0
				st		usebumps
				st		smoothbumps
				clr.b	usewater
				move.l	#BumpLine,LineToUse
				jsr		itsafloordraw
				bra		polyloop

itsachunkyfloor:
				move.w	#1,SMALLIT
				subq.w	#7,d0
				st		usebumps
				sub.w	#12,draw_TopClip_w
; add.w #10,draw_BottomClip_w
				clr.b	smoothbumps
				clr.b	usewater
				move.l	#BumpLine,LineToUse
				jsr		itsafloordraw
				add.w	#12,draw_TopClip_w
; sub.w #10,draw_BottomClip_w
				bra		polyloop

itsafloor:

				move.l	PointBrightsPtr,FloorPtBrights

				move.w	Draw_CurrentZone_w,d1
				muls	#80,d1

				cmp.w	#2,d0
				bne.s	.nfl
				add.l	#2,d1
.nfl
				add.l	d1,FloorPtBrights

				move.w	#1,SMALLIT

; Its possible that the reason for swithcing into SV mode was to be able to
; manipulate CACR, for instance to disable write-allocation when doing the floor
; tiles. This would make sense as keeping the runtime variable in cache is more important
; than allocating cache lines for the written pixels.

; FIXME: Indeed, it seems for A1200  with no fastram and its 68020, with its tiny
; instruction cache it made sense to freeze the ICache after the first iteration
; of floor drawing to keep the innermost loop in cache and thus require less bus accesses
; when churning out the floor pixels.
;
; I had removed many CACHE_FREEZE_OFF calls from the code - need to reinstate those.
; Not sure how much sense it made for later CPU models, though.

;				movem.l	a0/d0,-(a7)
;				move.l	$4.w,a6
;				jsr		_LVOSuperState(a6)
;				move.l	d0,SSTACK
;				movem.l	(a7)+,a0/d0

				move.l	#FloorLine,LineToUse	;* 1,2 = floor/roof
				clr.b	usewater
				clr.b	usebumps
				move.b	GOURSEL,gourfloor
				jsr		itsafloordraw

;				move.l	a0,-(a7)
;				move.l	$4.w,a6
;				move.l	SSTACK,d0
;				jsr		_LVOUserState(a6)
;				move.l	(a7)+,a0

				bra		polyloop
itsasetclip:
				bra		polyloop
itsawall:
				clr.b	seethru
; move.l #stripbuffer,a1
				jsr		itsawalldraw
				bra		polyloop

jumpoutofloop:
				rts

LastZonePtr_l:		dc.l	0
COMPACTPTR:		dc.l	0
BIGPTR:			dc.l	0
WALLIDENT:		dc.w	0
SMALLIT:		dc.w	0
GOURSEL:		dc.w	0
ThisRoomToDraw:	dc.l	0,0
SplitHeight:	dc.l	0

				include	"orderzones.s"

ReadMouse:
				move.l	#$dff000,a6
				clr.l	d0
				clr.l	d1
				move.w	$a(a6),d0
				lsr.w	#8,d0
				ext.l	d0
				move.w	d0,d3
				move.w	oldmy,d2
				sub.w	d2,d0

				cmp.w	#127,d0
				blt		nonegy
				move.w	#255,d1
				sub.w	d0,d1
				move.w	d1,d0
				neg.w	d0
nonegy:

				cmp.w	#-127,d0
				bge		nonegy2
				move.w	#255,d1
				add.w	d0,d1
				move.w	d1,d0
nonegy2:

				add.b	d0,d2
				add.w	d0,oldy2
				move.w	d2,oldmy
				move.w	d2,d0

				move.w	oldy2,d0
				move.w	d0,ymouse

				clr.l	d0
				clr.l	d1
				move.w	$a(a6),d0
				ext.w	d0
				ext.l	d0
				move.w	d0,d3
				move.w	oldmx,d2
				sub.w	d2,d0

				cmp.w	#127,d0
				blt		nonegx
				move.w	#255,d1
				sub.w	d0,d1
				move.w	d1,d0
				neg.w	d0
nonegx:

				cmp.w	#-127,d0
				bge		nonegx2
				move.w	#255,d1
				add.w	d0,d1
				move.w	d1,d0
nonegx2:

				add.b	d0,d2
				move.w	d0,d1
				move.w	d2,oldmx

				;FIXME: should use _LVOWritePotgo here
				move.w	#$0,_custom+potgo

				add.w	d0,oldx2
				move.w	oldx2,d0
				and.w	#2047,d0
				move.w	d0,oldx2

				asl.w	#2,d0
				sub.w	prevx,d0
				add.w	d0,prevx
				add.w	d0,angpos
				move.w	#0,lrs
				rts

noturn:

; got to move lr instead.

; d1 = speed moved l/r

				move.w	d1,lrs

				rts

lrs:			dc.w	0
prevx:			dc.w	0

angpos:			dc.w	0
mang:			dc.w	0
oldymouse:		dc.w	0
xmouse:			dc.w	0
ymouse:			dc.w	0
oldx2:			dc.w	0
oldmx:			dc.w	0
oldmy:			dc.w	0
oldy2:			dc.w	0

MAPON:			dc.w	$0
REALMAPON:		dc.w	0



RotateLevelPts:	;		Does					this rotate ALL points in the level EVERY frame?

				tst.b	REALMAPON
				beq		ONLYTHELONELY			; When REALMAP is on, we apparently need to transform all level points,
										; otherwise only the visible subset

				; Rotate all level points
				move.w	sinval,d6
				swap	d6
				move.w	cosval,d6

				move.l	Lvl_PointsPtr_l,a3
				move.l	#Rotated,a1				; stores only 2x800 points
				move.l	#OnScreen,a2
				move.w	xoff,d4
				;asr.w	#1,d4
				move.w	zoff,d5
				;asr.w	#1,d5

; move.w #$c40,$dff106
; move.w #$f00,$dff180

				move.w	Lvl_NumPoints_w,d7

				tst.b	Vid_FullScreen_b
				bne		BIGALL

				; rotate all level points, small screen
pointrotlop2:
				move.w	(a3)+,d0
;*				asr.w	#1,d0
				sub.w	d4,d0
				move.w	d0,d2					; view X

				move.w	(a3)+,d1
;*				asr.w	#1,d1
				sub.w	d5,d1					; view Z

				muls	d6,d2					; x' = (cos*viewX)<<16
				swap	d6
				move.w	d1,d3
				muls	d6,d3					; z' = (sin*viewZ) << 16

				sub.l	d3,d2					; x' =  (cos*viewX - sin*viewZ) << 16

 ; add.l d2,d2
 ; swap d2
 ; ext.l d2
 ; asl.l #7,d2   ; (x'*2 >> 16) << 7 == x' << 8

				asr.l	#8,d2					; x' = int(2*x') << 8

				add.l	xwobble,d2
				move.l	d2,(a1)+				; store rotated x'

				muls	d6,d0
				swap	d6
				muls	d6,d1
				add.l	d0,d1

 ; asl.l #1,d1
 ; swap d1
 ; ext.l d1       ; (z' >> 16) * 2 == z' >> 15

				asr.l	#8,d1					;
				asr.l	#7,d1					; z' = int(z') * 2

				move.l	d1,(a1)+				; store rotated z'

				tst.l	d1
				bgt.s	ptnotbehind
				tst.l	d2
				bgt.s	onrightsomewhere
				move.w	#0,d2
				bra		putin
onrightsomewhere:
				move.w	Vid_RightX_w,d2
				bra		putin
ptnotbehind:
				divs.w	d1,d2					; x / z perspective projection
				add.w	Vid_CentreX_w,d2
putin:
				move.w	d2,(a2)+				; store to OnScreen

				dbra	d7,pointrotlop2
outofpointrot:
				rts


BIGALL:

pointrotlop2B:
				move.w	(a3)+,d0				; x
				sub.w	d4,d0					; x/2 - xoff
				move.w	d0,d2					; x = x/2 -xoff

				move.w	(a3)+,d1				; z
				sub.w	d5,d1					; z = z/2 - zoff

				muls.w	d6,d2					; x*cos<<16
				swap	d6
				move.w	d1,d3
				muls.w	d6,d3					; z*sin<<16
				sub.l	d3,d2					; x' = (x * cos - z *sin)<<16
; add.l d2,d2
; swap d2
; ext.l d2
; asl.l #7,d2    ; integer part times 256

				asr.l	#8,d2

				add.l	xwobble,d2				; could the wobble be a shake or some underwater effect?
				move.l	d2,(a1)+				; store x'<<16

				muls	d6,d0					; x * sin<<16
				swap	d6
				muls	d6,d1					; z * cos <<16
				add.l	d0,d1					; z' = (x*sin + z*sin)<<16

				; 0xABADCAFE
				; Use 3/5 rather than 2/3 here for 320 wide - z' * 2 * 3/5 -> z' * 6/5
				; Shift d1 to get 2 extra input bits for our scale by 3/5 approximation
				lsl.l	#2,d1
				swap	d1
				muls	#1229,d1 ; 1229/2048 = 0.600097
				asr.l	#8,d1
				asr.l	#4,d1    ; z' * 6/5

				move.l	d1,(a1)+	; this stores the rotated points, but why does it factor in the scale factor
									; for the screen? Or is storing in view space with aspect ratio applied actually
									; convenient?
									; WOuld here a good opportunity to factor in DOUBLEWIDTH?

				tst.l	d1
				bgt.s	ptnotbehindB
				tst.l	d2
				bgt.s	onrightsomewhereB
				moveq.l	#0,d2
				bra		putinB

onrightsomewhereB:
				move.w	Vid_RightX_w,d2
				bra		putinB
ptnotbehindB:
				divs.w	d1,d2
				add.w	Vid_CentreX_w,d2
putinB:
				move.w	d2,(a2)+				; store fully projected X

				dbra	d7,pointrotlop2B
				rts


				; This only rotates a subset of the points, with indices pointed to at PointsToRotatePtr_l
ONLYTHELONELY:
				move.w	sinval,d6
				swap	d6
				move.w	cosval,d6

				move.l	PointsToRotatePtr_l,a0	; -1 terminated array of point indices to rotate
				move.l	Lvl_PointsPtr_l,a3
				move.l	#Rotated,a1
				move.l	#OnScreen,a2
				move.w	xoff,d4
				move.w	zoff,d5

; move.w #$c40,$dff106
; move.w #$f00,$dff180

				tst.b	Vid_FullScreen_b
				bne		BIGLONELY

pointrotlop:
				move.w	(a0)+,d7
				blt		outofpointrot

				move.w	(a3,d7*4),d0
				sub.w	d4,d0

				move.w	d0,d2
				move.w	2(a3,d7*4),d1

				sub.w	d5,d1
				muls	d6,d2
				swap	d6

				move.w	d1,d3
				muls	d6,d3
				sub.l	d3,d2

;				add.l	d2,d2
;				swap	d2
;				ext.l	d2
;				asl.l	#7,d2

				asr.l	#8,d2					; x' = int(2*x') << 8

				add.l	xwobble,d2
				move.l	d2,(a1,d7*8)

				muls	d6,d0
				swap	d6
				muls	d6,d1
				add.l	d0,d1

;				asl.l #1,d1
;				swap d1
;				ext.l d1       ; (z' >> 16) * 2 == z' >> 15

				asr.l	#8,d1					;
				asr.l	#7,d1					; z' = int(z') * 2

				move.l	d1,4(a1,d7*8)

				tst.w	d1
				bgt.s	.ptnotbehind
				tst.w	d2
				bgt.s	.onrightsomewhere
				move.w	#0,d2
				bra		.putin

.onrightsomewhere:
				move.w	Vid_RightX_w,d2
				bra		.putin

.ptnotbehind:
				divs	d1,d2
				add.w	Vid_CentreX_w,d2
.putin:
				move.w	d2,(a2,d7*2)

				bra		pointrotlop

; move.w #$c40,$dff106
; move.w #$ff0,$dff180

				rts

BIGLONELY:

.pointrotlop:
				move.w	(a0)+,d7
				blt.s	.outofpointrot

				move.w	(a3,d7*4),d0
				sub.w	d4,d0
				move.w	d0,d2

				move.w	2(a3,d7*4),d1
				sub.w	d5,d1
				muls	d6,d2

				swap	d6
				move.w	d1,d3
				muls	d6,d3
				sub.l	d3,d2

;				add.l	d2,d2
;				swap	d2
;				ext.l	d2
;				asl.l	#7,d2

				asr.l	#8,d2					; x' = int(2*x') << 8

				add.l	xwobble,d2
				move.l	d2,(a1,d7*8)

				muls	d6,d0
				swap	d6
				muls	d6,d1
				add.l	d0,d1

				; 0xABADCAFE
				; Use 3/5 rather than 2/3 here for 320 wide - z' * 2 * 3/5 -> z' * 6/5
				; Shift d1 to get 2 extra input bits for our scale by 3/5 approximation
				lsl.l	#2,d1
				swap	d1
				muls	#1229,d1 ; 1229/2048 = 0.600097
				asr.l	#8,d1
				asr.l	#4,d1    ; z' * 6/5

				move.l	d1,4(a1,d7*8)

				tst.w	d1
				bgt.s	.ptnotbehind
				tst.w	d2
				bgt.s	.onrightsomewhere
				move.w	#0,d2
				bra		.putin

.onrightsomewhere:
				move.w	Vid_RightX_w,d2
				bra		.putin

.ptnotbehind:

				divs	d1,d2
				add.w	Vid_CentreX_w,d2
.putin:
				move.w	d2,(a2,d7*2)			; this means the a2 array will also be sparsely written to,
										; but then again doesn't need reindeexing the input indices.
										; maybe it is worthwhile investigating if its possible to re-index
										; and write in a packed manner

				bra		.pointrotlop

.outofpointrot:
; move.w #$c40,$dff106
; move.w #$ff0,$dff180

				rts


PLR1_ObjDists
				ds.w	250
PLR2_ObjDists
				ds.w	250

CalcPLR1InLine:
				move.w	Plr1_SinVal_w,d5
				move.w	Plr1_CosVal_w,d6
				move.l	Lvl_ObjectDataPtr_l,a4
				move.l	Lvl_ObjectPointsPtr_l,a0
				move.w	Lvl_NumObjectPoints_w,d7
				move.l	#PLR1_ObsInLine,a2
				move.l	#PLR1_ObjDists,a3

.objpointrotlop:

				cmp.b	#3,16(a4)
				beq.s	.itaux

				move.w	(a0),d0
				sub.w	Plr1_XOff_l,d0
				move.w	4(a0),d1
				addq	#8,a0

				tst.w	12(a4)
				blt		.noworkout

				moveq	#0,d2
				move.b	16(a4),d2
;move.l #ColBoxTable,a6
;lea (a6,d2.w*8),a6

				sub.w	Plr1_ZOff_l,d1
				move.w	d0,d2
				muls	d6,d2
				move.w	d1,d3
				muls	d5,d3
				sub.l	d3,d2
				add.l	d2,d2

				bgt.s	.okh
				neg.l	d2
.okh:
				swap	d2

				muls	d5,d0
				muls	d6,d1
				add.l	d0,d1
				asl.l	#2,d1
				swap	d1
				moveq	#0,d3

				tst.w	d1
				ble.s	.notinline
				asr.w	#1,d2
				cmp.w	#80,d2
				bgt.s	.notinline

				st		d3
.notinline
				move.b	d3,(a2)+

				move.w	d1,(a3)+

				add.w	#64,a4
				dbra	d7,.objpointrotlop

				rts

.itaux:
				add.w	#64,a4
				bra		.objpointrotlop

.noworkout:
				move.b	#0,(a2)+
				move.w	#0,(a3)+
				add.w	#64,a4
				dbra	d7,.objpointrotlop
				rts

CalcPLR2InLine:
				move.w	Plr2_SinVal_w,d5
				move.w	Plr2_CosVal_w,d6
				move.l	Lvl_ObjectDataPtr_l,a4
				move.l	Lvl_ObjectPointsPtr_l,a0
				move.w	Lvl_NumObjectPoints_w,d7
				move.l	#PLR2_ObsInLine,a2
				move.l	#PLR2_ObjDists,a3

.objpointrotlop:
				cmp.b	#3,16(a4)
				beq.s	.itaux

				move.w	(a0),d0
				sub.w	Plr2_XOff_l,d0
				move.w	4(a0),d1
				addq	#8,a0

				tst.w	12(a4)
				blt		.noworkout

				moveq	#0,d2
				move.b	16(a4),d2
; move.l #ColBoxTable,a6
; lea (a6,d2.w*8),a6

				sub.w	Plr2_ZOff_l,d1
				move.w	d0,d2
				muls	d6,d2
				move.w	d1,d3
				muls	d5,d3
				sub.l	d3,d2
				add.l	d2,d2

				bgt.s	.okh
				neg.l	d2
.okh:
				swap	d2

				muls	d5,d0
				muls	d6,d1
				add.l	d0,d1
				asl.l	#2,d1
				swap	d1
				moveq	#0,d3

				tst.w	d1
				ble.s	.notinline
				asr.w	#1,d2
				cmp.w	(a6),d2
				bgt.s	.notinline

				st		d3
.notinline
				move.b	d3,(a2)+

				move.w	d1,(a3)+

				add.w	#64,a4
				dbra	d7,.objpointrotlop

				rts

.itaux:
				add.w	#64,a4
				bra		.objpointrotlop

.noworkout:
				move.w	#0,(a3)+
				move.b	#0,(a2)+
				add.w	#64,a4
				dbra	d7,.objpointrotlop
				rts


RotateObjectPts:
				move.w	sinval,d5				; fetch sine of rotation
				move.w	cosval,d6				; consine

				move.l	Lvl_ObjectDataPtr_l,a4
				move.l	Lvl_ObjectPointsPtr_l,a0
				move.w	Lvl_NumObjectPoints_w,d7
				move.l	#ObjRotated_vl,a1

				tst.b	Vid_FullScreen_b
				bne		BIGOBJPTS


.objpointrotlop:
				cmp.b	#3,16(a4)
				beq.s	.itaux

				move.w	(a0),d0					; x of object point
				sub.w	xoff,d0					; viewX = X - cam X
				move.w	4(a0),d1				; z of object point
				addq	#8,a0					; next point? or next object?

				tst.w	12(a4)					; Lvl_ObjectDataPtr_l
				blt		.noworkout

				sub.w	zoff,d1					; viewZ = Z - cam Z

				move.w	d0,d2
				muls	d6,d2					; cosx = viewX * (cos << 16)
				move.w	d1,d3					;
				muls	d5,d3					; sinz = viewZ * (sin << 16)

				sub.l	d3,d2					;  x' = cosx - sinz
				add.l	d2,d2					; x'*2
				swap	d2						; x' >> 16
				move.w	d2,(a1)+				; finished rotated x'

				muls	d5,d0					; sinx = viewX * sin <<16
				muls	d6,d1					; cosz = viewZ * cos << 16
				add.l	d0,d1					; z' = sinx + cosz
				add.l	d1,d1					; *2
				swap	d1						; >> 16
; ext.l d1
; divs #3,d1
				moveq	#0,d3					;FIMXE: why?

				move.w	d1,(a1)+				; finished rotated z'

				ext.l	d2						; whats the wobble about?
				asl.l	#7,d2
				add.l	xwobble,d2
				move.l	d2,(a1)+				; no clue

				dbra	d7,.objpointrotlop

				rts

.itaux:
				add.w	#64,a4
				bra		.objpointrotlop

.noworkout:
				move.l	#0,(a1)+
				move.l	#0,(a1)+
				add.w	#64,a4
				dbra	d7,.objpointrotlop
				rts

BIGOBJPTS:

.objpointrotlop:

				cmp.b	#3,16(a4)
				beq.s	.itaux

				move.w	(a0),d0
				sub.w	xoff,d0
				move.w	4(a0),d1
				addq	#8,a0

				tst.w	12(a4)
				blt		.noworkout

				sub.w	zoff,d1
				move.w	d0,d2
				muls	d6,d2
				move.w	d1,d3
				muls	d5,d3
				sub.l	d3,d2


				add.l	d2,d2
				swap	d2
				move.w	d2,(a1)+

				muls	d5,d0
				muls	d6,d1

				add.l	d0,d1
				asl.l	#2,d1
				swap	d1
				ext.l	d1
				divs	#3,d1
				moveq	#0,d3

				move.w	d1,(a1)+
				ext.l	d2
				asl.l	#7,d2
				add.l	xwobble,d2
				move.l	d2,(a1)+
				sub.l	xwobble,d2

				add.w	#64,a4
				dbra	d7,.objpointrotlop

				rts

.itaux:
				add.w	#64,a4
				bra		.objpointrotlop

.noworkout:
				move.l	#0,(a1)+
				move.l	#0,(a1)+
				add.w	#64,a4
				dbra	d7,.objpointrotlop
				rts

				; Is this actually still used?
				; it introduces a dependcy to "objintocop" which I believe
				; is not/should not be used anymore ("object to copper"?)
;LightDraw:
;
;				move.w	(a0)+,d0
;				move.w	(a0)+,d1
;				move.l	#Rotated,a1
;				move.w	6(a1,d0.w*8),d2
;				ble.s	oneendbehind
;				move.w	6(a1,d1.w*8),d3
;				bgt.s	bothendsinfront
;
;oneendbehind:
;				rts
;bothendsinfront:
;
;				move.l	#OnScreen,a2
;				move.w	(a2,d0.w*2),d0
;				bge.s	okleftend
;				moveq	#0,d0
;okleftend:
;				move.w	(a2,d1.w*2),d1
;				bgt.s	somevis
;				rts
;somevis:
;				cmp.w	Vid_RightX_w,d0
;				blt.s	somevis2
;				rts
;somevis2:
;				cmp.w	Vid_RightX_w,d1
;				blt.s	okrightend
;				move.w	Vid_RightX_w,d1
;				subq	#1,d1
;okrightend:
;
;				sub.w	d0,d1
;				blt.s	wrongbloodywayround
;				move.l	TexturePal,a4
;				move.l	#objintocop,a1
;				lea		(a1,d0.w*2),a1
;
;				move.l	frompt,a3
;				move.w	#104*4,d6
;				move.w	#79,d2
;lacross:
;				move.w	d2,d3
;				move.l	a3,a2
;				adda.w	(a1)+,a2
;ldown:
;				add.w	d6,a2
;				move.w	(a2),d7
;				move.w	(a4,d7.w*2),(a2)
;				dbra	d3,ldown
;				dbra	d1,lacross
;
;wrongbloodywayround:
;
;				rts

FaceToPlace:	dc.w	0

Cheese:
				dc.w	4,15

FacesList:
				dc.w	0,4*4
				dc.w	1,2*4
				dc.w	0,2*4
				dc.w	2,2*4
				dc.w	0,2*4
				dc.w	1,3*4
				dc.w	0,2*4
				dc.w	2,3*4
				dc.w	0,5*4
				dc.w	1,2*4
				dc.w	0,2*4
				dc.w	2,2*4
				dc.w	0,2*4
				dc.w	1,2*4
				dc.w	0,2*4
				dc.w	2,3*4
				dc.w	0,1*4
				dc.w	1,3*4
				dc.w	0,1*4
				dc.w	2,3*4
				dc.w	0,1*4

EndOfFacesList:

FacesPtr:
				dc.l	FacesList
FacesCounter:
				dc.w	0
Expression:
				dc.w	0


Energy:
				dc.w	191
OldEnergy:
				dc.w	191
Ammo:			dc.w	63
OldAmmo:		dc.w	63

firstdigit:		dc.b	0
secdigit:		dc.b	0
thirddigit:		dc.b	0

				even

gunny:			dc.w	0

AmmoBar:

* Do guns first.

				move.l	#borderchars,a4
				move.b	Plr1_TmpGunSelected_b,d0
				move.l	#PLAYERONEGUNS,a5
				cmp.b	#PLR_SLAVE,Plr_MultiplayerType_b
				bne.s	.notplr2
				move.l	#PLAYERTWOGUNS,a5
				move.b	Plr2_TmpGunSelected_b,d0
.notplr2:

				move.b	d0,gunny

				move.w	#9,d2
				moveq	#0,d0
putingunnums:
				move.w	#4,d1
				move.l	a4,a0
				cmp.b	gunny,d0
				bne.s	.notsel
				add.l	#5*10*8*2,a0
				addq	#2,a5
				bra.s	.donesel
.notsel:
				tst.w	(a5)+
				beq.s	.donesel
				add.l	#5*10*8,a0
.donesel:
				move.l	SCRNDRAWPT,a1
				add.w	d0,a1
				add.l	#3+(240*40),a1
				bsr		DRAWDIGIT
				addq	#1,d0
				dbra	d2,putingunnums

				move.w	Ammo,d0

				cmp.w	#999,d0
				blt.s	.okammo
				move.w	#999,d0
.okammo


				ext.l	d0
				divs	#10,d0
				swap	d0
				move.b	d0,thirddigit
				swap	d0
				ext.l	d0
				divs	#10,d0
				move.b	d0,firstdigit
				swap	d0
				move.b	d0,secdigit

				move.l	#borderchars+15*8*10,a0
				cmp.w	#10,Ammo
				blt.s	.notsmallamo
				add.l	#7*8*10,a0
.notsmallamo:

				move.l	SCRNDRAWPT,a1
				add.l	#20+238*40,a1
				move.b	firstdigit,d0
				move.w	#6,d1
				bsr		DRAWDIGIT

				move.l	SCRNDRAWPT,a1
				add.l	#21+238*40,a1
				move.b	secdigit,d0
				move.w	#6,d1
				bsr		DRAWDIGIT

				move.l	SCRNDRAWPT,a1
				add.l	#22+238*40,a1
				move.b	thirddigit,d0
				move.w	#6,d1
				bsr		DRAWDIGIT

				rts

EnergyBar:
				move.w	Energy,d0
				bge.s	.okpo
				moveq	#0,d0
.okpo:

				cmp.w	#999,d0
				blt.s	.okenergy
				move.w	#999,d0
.okenergy


				ext.l	d0
				divs	#10,d0
				swap	d0
				move.b	d0,thirddigit
				swap	d0
				ext.l	d0
				divs	#10,d0
				move.b	d0,firstdigit
				swap	d0
				move.b	d0,secdigit

				move.l	#borderchars+15*8*10,a0
				cmp.w	#10,Energy
				blt.s	.notsmallamo
				add.l	#7*8*10,a0
.notsmallamo:

				move.l	SCRNDRAWPT,a1
				add.l	#34+238*40,a1
				move.b	firstdigit,d0
				move.w	#6,d1
				bsr		DRAWDIGIT

				move.l	SCRNDRAWPT,a1
				add.l	#35+238*40,a1
				move.b	secdigit,d0
				move.w	#6,d1
				bsr		DRAWDIGIT

				move.l	SCRNDRAWPT,a1
				add.l	#36+238*40,a1
				move.b	thirddigit,d0
				move.w	#6,d1
				bsr		DRAWDIGIT

				move.l	SCRNSHOWPT,a1
				add.l	#34+238*40,a1
				move.b	firstdigit,d0
				move.w	#6,d1
				bsr		DRAWDIGIT

				move.l	SCRNSHOWPT,a1
				add.l	#35+238*40,a1
				move.b	secdigit,d0
				move.w	#6,d1
				bsr		DRAWDIGIT

				move.l	SCRNSHOWPT,a1
				add.l	#36+238*40,a1
				move.b	thirddigit,d0
				move.w	#6,d1
				bsr		DRAWDIGIT

				rts

DRAWDIGIT:
				ext.w	d0
				lea		(a0,d0.w),a2

charlines:
				lea		30720(a1),a3
				move.b	(a2),(a1)
				move.b	10(a2),10240(a1)
				move.b	20(a2),20480(a1)
				move.b	30(a2),(a3)
				move.b	40(a2),10240(a3)
				move.b	50(a2),20480(a3)
				lea		30720(a3),a3
				move.b	60(a2),(a3)
				move.b	70(a2),10240(a3)

				add.w	#10*8,a2
				add.w	#40,a1
				dbra	d1,charlines

				rts

borderchars:	incbin	"includes/bordercharsraw"

NARRATOR:

; sub.w #1,NARRTIME
; bge .NOCHARYET
; move.w #3,NARRTIME

; FIXME: pixel scrolling for status line  was achieved via actual scroll registers
;				move.l	#SCROLLSCRN,d1
;				move.w	d1,scroll
;				swap	d1
;				move.w	d1,scrolh

				move.w	SCROLLTIMER,d0
				subq	#1,d0
				move.w	d0,SCROLLTIMER
				cmp.w	#40,d0
				bge		.NOCHARYET
				tst.w	d0
				bge.s	.okcha

				move.w	#150,SCROLLTIMER
				bra		.NOCHARYET

.okcha:
				; FIMXE: need to redirect this to teh actual screen
				move.l	#SCROLLSCRN,a0
				add.w	SCROLLXPOS,a0

				moveq	#1,d7
.doachar:

				move.l	SCROLLPOINTER,a1
				moveq	#0,d1
				move.b	(a1)+,d1				; character
				move.l	a1,d2
				cmp.l	ENDSCROLL,d2
				blt.s	.notrestartscroll
				move.l	#BLANKSCROLL,a1
				move.l	#BLANKSCROLL+80,ENDSCROLL
.notrestartscroll
				move.l	a1,SCROLLPOINTER

				move.l	#SCROLLCHARS,a1
				asl.w	#3,d1
				add.w	d1,a1

				move.b	(a1)+,(a0)
				move.b	(a1)+,80(a0)
				move.b	(a1)+,80*2(a0)
				move.b	(a1)+,80*3(a0)
				move.b	(a1)+,80*4(a0)
				move.b	(a1)+,80*5(a0)
				move.b	(a1)+,80*6(a0)
				move.b	(a1)+,80*7(a0)

				addq	#1,a0
				dbra	d7,.doachar

				move.w	SCROLLXPOS,d0
				addq	#2,d0
				move.w	d0,SCROLLXPOS
				cmp.w	#80,d0
				blt		.NOCHARYET
				move.w	#0,SCROLLXPOS

.NOCHARYET:
				rts


NARRTIME:		dc.w	5

SCROLLCHARS:	incbin	"includes/scrollfont"


doanything:		dc.w	0						; does main game run?

endlevel:
; 	_break #0
				clr.b	dosounds
				clr.b	doanything

				; waiting for serial transmit complete?
;waitfortop22:
;				btst.b	#0,intreqrl(a6)
;				beq		waitfortop22
;waitfortop222:
;				btst.b	#0,intreqrl(a6)
;				beq		waitfortop222

				; Audio off
;				move.w	#$f,$dff000+dmacon


				move.w	PLAYERONEHEALTH,Energy
				cmp.b	#PLR_SLAVE,Plr_MultiplayerType_b
				bne.s	.notsl
				move.w	PLAYERTWOHEALTH,Energy
.notsl:

; cmp.b #'b',Prefsfile+3
; bne.s .noback
; jsr mt_end
;.noback

				tst.w	Energy
				bgt.s	wevewon
				move.w	#0,Energy
				bsr		EnergyBar

				move.l	#gameover,mt_data
				st		UseAllChannels
				clr.b	reachedend
				jsr		mt_init

playgameover:
				CALLGRAF WaitTOF

				jsr		mt_music

				tst.b	reachedend
				beq.s	playgameover

				bra		wevelost

wevewon:
				; Disable audio DMA
				move.w	#$f,$dff000+dmacon

				bsr		EnergyBar

				cmp.b	#PLR_NEITHER,Plr_MultiplayerType_b
				bne.s	.nonextlev
				add.w	#1,MAXLEVEL
				st		FINISHEDLEVEL

.nonextlev:

				move.l	#welldone,mt_data
				st		UseAllChannels
				clr.b	reachedend

				jsr		mt_init
playwelldone:
				CALLGRAF WaitTOF

				jsr		mt_music

				tst.b	reachedend
				beq.s	playwelldone

				cmp.b	#PLR_NEITHER,Plr_MultiplayerType_b
				bne.s	wevelost
				cmp.w	#16,MAXLEVEL
				bne.s	wevelost

				jmp		ENDGAMESCROLL

wevelost:
				; disable Audio DMA
				move.w	#$f,$dff000+dmacon

				jmp		closeeverything

endnomusic
				clr.b	doanything


; cmp.b #'b',Prefsfile+3
; bne.s .noback
; jsr mt_end
;.noback
*******************************
; cmp.b #PLR_NEITHER,Plr_MultiplayerType_b
; bne.s .nonextlev
; cmp.w #15,MAXLEVEL
; bge.s .nonextlev
; add.w #1,MAXLEVEL
; st FINISHEDLEVEL
;.nonextlev:
******************************

				jmp		closeeverything

do32:
				move.w	#31,d7
				move.w	#$180,d1
across:
				move.w	d1,(a1)+
				move.w	d1,(a3)+
				move.w	#0,(a1)+
				move.w	#0,(a3)+
				add.w	#2,d1
				dbra	d7,across
				rts

ENDGAMESCROLL:
				move.l	Lvl_MusicPtr_l,mt_data
				clr.b	UseAllChannels
				jsr		mt_init

;				move.w	#$fff,MIXCOLL
;				move.w	#$1cc1,BOTOFTXT

				jsr		Game_ClearIntroText

;				move.l	#TEXTCOP,$dff080

				move.l	#ENDGAMETEXTy,a0


SCROLLUP16LINES:

;				move.w	#15,d0
;
;do16
;				move.l	#$dff000,a6
;
;				move.w	#0,d6
;				move.w	#7,d7
;
;				move.l	#SCROLLSHADES,a5
;
;fadeupp:
;
;				move.w	(a5,d6.w*2),TOPCOLL
;				move.w	(a5,d7.w*2),TXTCOLL
;
;
;.wtup
;				btst	#5,intreqrl(a6)
;				beq.s	.wtup
;				move.w	#$20,intreq(a6)
;
;				jsr		mt_music
;
;				add.w	#1,d6
;				sub.w	#1,d7
;				bne		fadeupp
;
;.wtup2
;				btst	#5,intreqrl(a6)
;				beq.s	.wtup2
;				move.w	#$20,intreq(a6)
;
;				move.w	#0,TOPCOLL
;				move.w	#$fff,TXTCOLL
;
;				WB
;
;				move.l	Vid_TextScreenPtr_l,d1
;				move.l	d1,bltdpt(a6)
;				add.l	#80,d1
;				move.l	d1,bltapt(a6)
;				move.w	#$09f0,bltcon0(a6)
;				move.w	#$0,bltcon1(a6)
;				move.w	#0,bltdmod(a6)
;				move.w	#0,bltamod(a6)
;				move.l	#-1,bltafwm(a6)
;
;				move.w	#255*64+40,bltsize(a6)
;
;				WB
;
;				dbra	d0,do16
;
;				move.l	Vid_TextScreenPtr_l,a1
;				move.w	#15,d0
;				jsr		Draw_LineOfText
;
;				add.l	#82,a0
;				cmp.l	#ENDENDGAMETEXT,a0
;				blt		SCROLLUP16LINES
;
;				move.l	#ENDGAMETEXTy,a0
				bra		SCROLLUP16LINES

SCROLLSHADES:
				dc.w	0
				dc.w	$333
				dc.w	$666
				dc.w	$888
				dc.w	$aaa
				dc.w	$ccc
				dc.w	$ddd
				dc.w	$eee

ENDGAMETEXTy:
				  ;          12345678901234567890123456789012345678901234567890123456789012345678901234567890
				dc.b	0,0,"                                                                                "
				dc.b	0,1,"As the beast and its four servants die, a breathless silence falls, broken      "
				dc.b	0,1,"only by the hammering of my own heart in my chest.                              "
				dc.b	0,1,"I run to the now open exit, and out into the maze of corridors through which I  "
				dc.b	0,1,"came. I encounter many, many aliens, lying twitching on the ground, or utterly  "
				dc.b	0,1,"still with glazed eyes and green froth drying on their lips. Many seem to have  "
				dc.b	0,1,"turned their weapons on themselves, unable to bear either the pain or the       "
				dc.b	0,1,"sudden silence in their minds.                                                  "
				dc.b	0,0,"                                                                                "
				dc.b	0,1,"It takes me several hours to locate a working teleport to take me back aboard   "
				dc.b	0,1,"the orbiting alien ship. The scene there is the same; hordes of aliens, either  "
				dc.b	0,1,"dead or catatonic, I cannot tell.                                               "
				dc.b	0,1,"I walk slowly, exhausted, back to the INDOMITABLE, averting my eyes from the    "
				dc.b	0,1,"pitiful scenes around me. I know that my work is not finished yet.              "
				dc.b	0,1,"Once aboard, I make my way to the bridge. I manage to restart the main power    "
				dc.b	0,1,"generators and get basic navigation back on-line. Working from the memories     "
				dc.b	0,1,"implanted by the dying marine, I painstakingly program the computer to deal     "
				dc.b	0,1,"the killing blow to the enemy. At last the task is finished. The ship hums into "
				dc.b	0,1,"life, accellerating slowly out of orbit, towing the massive alien craft and     "
				dc.b	0,1,"its mindless cargo behind it.                                                   "
				dc.b	0,1,"As the image of the alien sun grows in the viewscreen, I think about what I     "
				dc.b	0,1,"have seen. Fragments of technology, stolen from civilisations - how long ago?   "
				dc.b	0,1,"How long since they were exterminated by these parasites? And how many more     "
				dc.b	0,1,"if they are allowed to continue?                                                "
				dc.b	0,1,"The sun looms hideously large before me, seeming at the last moment to slip to  "
				dc.b	0,1,"one side as the cruiser slingshots itself through the immense gravity well,     "
				dc.b	0,1,"its speed doubling and doubling again. The ship shudders and groans as the      "
				dc.b	0,1,"ponderous mass of the alien ship tries to tear itself free. I feel a distant    "
				dc.b	0,1,"twinge of curiosity as to whether it will succeed.                              "
				dc.b	0,1,"The navigation computer chatters quietly to itself as it makes tiny             "
				dc.b	0,1,"course corrections, bringing the payload to bear on its target. I only sit,     "
				dc.b	0,1,"watching blankly as we hurtle back towards the planet. The navicom beeps        "
				dc.b	0,1,"quietly to signal the blowing of the explosive bolts holding the docking ring.  "
				dc.b	0,1,"So great is our speed that the alien ship does not receed, but simply vanishes  "
				dc.b	0,1,"from sight, tracked only on the readouts of the computers in front of me.       "
				dc.b	0,1,"One readout in particular occupies my attention. Red numbers spin towards zero  "
				dc.b	0,1,"as my invisible agent of destruction spins towards oblivion. Three digits, now  "
				dc.b	0,1,"two, and now only one. I shift my attention to the image of the alien world,    "
				dc.b	0,1,"receeding behind my ship.                                                       "
				dc.b	0,0,"                                                                                "
				dc.b	0,1,"Three...                                                                        "
				dc.b	0,0,"                                                                                "
				dc.b	0,1,"Two...                                                                          "
				dc.b	0,0,"                                                                                "
				dc.b	0,1,"One...                                                                          "
				dc.b	0,0,"                                                                                "
				dc.b	0,1,"Zero.                                                                           "
				dc.b	0,0,"                                                                                "
				dc.b	0,0,"                                                                                "
				dc.b	0,0,"                                                                                "
				dc.b	0,0,"                                                                                "
				dc.b	0,1,"Travelling at nearly a quarter of the speed of light, the alien ship smashed    "
				dc.b	0,1,"into the planet, flashing past the useless orbital defences which should have   "
				dc.b	0,1,"neutralized it millions of miles earlier. It passed through the twenty miles    "
				dc.b	0,1,"of atmosphere in a little more than one ten-thousandth of a second. The air     "
				dc.b	0,1,"directly beneath had no time to be pushed out of the way, and in another        "
				dc.b	0,1,"tenth of a second it was a molecule-thick layer a thousand miles below the      "
				dc.b	0,1,"planet's surface.                                                               "
				dc.b	0,1,"Such was the heat and pressure caused by the impact, that part of the molten    "
				dc.b	0,1,"core of the planet underwent nuclear fusion, vapourising thousands of billions  "
				dc.b	0,1,"of tonnes of surrounding material. This expanding superhot plasma cloud forced  "
				dc.b	0,1,"its way up through the mantle and crust, fracturing the surface of the planet,  "
				dc.b	0,1,"blowing continent-sized chunks into space and heating the tortured atmosphere   "
				dc.b	0,1,"to ignition point. Within two minutes of impact, the doomed planet was a        "
				dc.b	0,1,"misshapen, incandescent ball, with burning fragments spinning deceptively       "
				dc.b	0,1,"slowly in their brief orbits before re-impacting with fantastic, majestic       "
				dc.b	0,1,"force.                                                                          "
				dc.b	0,0,"                                                                                "
				dc.b	0,0,"                                                                                "
				dc.b	0,0,"                                                                                "
				dc.b	0,0,"                                                                                "
				dc.b	0,1,"In a matter of weeks, the small amount of matter which had undergone fusion     "
				dc.b	0,1,"burned itself out, but the planet still glowed sullenly from a million cracks   "
				dc.b	0,1,"and holes in the crust, as it would continue to do for millions of years to     "
				dc.b	0,1,"come. The world was barren and dead, and the creatures who once roamed its      "
				dc.b	0,1,"surface no more than a memory in the mind of one man, sleeping dreamlessly      "
				dc.b	0,1,"as the invisible speck of his ship sped silently on, towards home.              "
				dc.b	0,0,"                                                                                "
				dc.b	0,0,"                                                                                "
				dc.b	0,0,"                                                                                "
				dc.b	0,0,"                                                                                "
				dc.b	0,0,"                                                                                "
				dc.b	0,0,"                                                                                "
				dc.b	0,0,"                                                                                "
				dc.b	0,0,"                                                                                "
				dc.b	0,0,"                                                                                "
				dc.b	0,0,"                                                                                "
				dc.b	0,0,"                                                                                "
				dc.b	0,0,"                                                                                "
				dc.b	0,0,"                                                                                "
				dc.b	0,0,"                                                                                "
				dc.b	0,0,"                                                                                "
				dc.b	0,0,"                                                                                "
				dc.b	0,1,"ALIEN BREED 3D II                                                               "
				dc.b	0,1,"THE KILLING GROUNDS                                                             "
				dc.b	0,0,"                                                                                "
				dc.b	0,0,"                                                                                "
				dc.b	0,1,"A Team 17 Game                                                                  "
				dc.b	0,0,"                                                                                "
				dc.b	0,1,"Produced in association with OCEAN Software                                     "
				dc.b	0,0,"                                                                                "
				dc.b	0,0,"                                                                                "
				dc.b	0,1,"Game Design, Game Code, Editor Code and In-Game Text                            "
				dc.b	0,0,"                                                                                "
				dc.b	0,1,"Andrew Clitheroe                                                                "
				dc.b	0,0,"                                                                                "
				dc.b	0,0,"                                                                                "
				dc.b	0,1,"Graphics                                                                        "
				dc.b	0,0,"                                                                                "
				dc.b	0,1,"Michael Green                                                                   "
				dc.b	0,0,"                                                                                "
				dc.b	0,0,"                                                                                "
				dc.b	0,1,"3D Object Designs, 3D Editors, Serial and OS code                               "
				dc.b	0,0,"                                                                                "
				dc.b	0,1,"Charles Blessing                                                                "
				dc.b	0,0,"                                                                                "
				dc.b	0,0,"                                                                                "
				dc.b	0,1,"Music                                                                           "
				dc.b	0,0,"                                                                                "
				dc.b	0,1,"Ben Chanter                                                                     "
				dc.b	0,0,"                                                                                "
				dc.b	0,0,"                                                                                "
				dc.b	0,1,"Project Manager                                                                 "
				dc.b	0,0,"                                                                                "
				dc.b	0,1,"Phil Quirke-Webster                                                             "
				dc.b	0,0,"                                                                                "
				dc.b	0,0,"                                                                                "
				dc.b	0,1,"Playtesting                                                                     "
				dc.b	0,0,"                                                                                "
				dc.b	0,1,"Phil and the Wolves                                                             "
				dc.b	0,0,"                                                                                "
				dc.b	0,0,"                                                                                "
				dc.b	0,1,"Additional Graphics                                                             "
				dc.b	0,0,"                                                                                "
				dc.b	0,1,"Pete Lyons                                                                      "
				dc.b	0,0,"                                                                                "
				dc.b	0,0,"                                                                                "
ENDENDGAMETEXT:


;
;	move.l	4.w,a6
;	move.l	#string,d1
;	moveq	#0,d2
;	moveq	#0,d3
;	jsr	_LVOExecute(a6)

; include "endscroll.s"

***********************************
				include	"cd32joy.s"



*************************************
* Set left and right clip values
*************************************



NEWsetlclip:
				move.l	#OnScreen,a1
				move.l	#Rotated,a2
				move.l	Lvl_ConnectTablePtr_l,a3
				move.l	Lvl_PointsPtr_l,a4

				move.w	(a0),d0
				bge.s	.notignoreleft

; move.l #0,(a6)

				bra		.leftnotoktoclip
.notignoreleft:

				move.w	6(a2,d0*8),d3			; left z val
				bgt.s	.leftclipinfront
				addq	#2,a0
				rts

				tst.w	6(a2,d0*8)
				bgt.s	.leftnotoktoclip
.ignoreboth:
; move.l #0,(a6)
; move.l #96*65536,4(a6)
				move.w	#0,leftclip
				move.w	Vid_RightX_w,rightclip
				addq	#8,a6
				addq	#2,a0
				rts

.leftclipinfront:
				move.w	(a1,d0*2),d1			; left x on screen
				move.w	(a0),d2
				move.w	2(a3,d2.w*4),d2
				move.w	(a1,d2.w*2),d2
				cmp.w	d1,d2
				bgt.s	.leftnotoktoclip


*************************************

; move.w 2(a3,d0.w*4),d6
;
; move.w (a4,d0.w*4),d2
; move.w 2(a4,d0.w*4),d3
; move.w (a4,d6.w*4),d4
; move.w 2(a4,d6.w*4),d5
;
; sub.w d2,d4	;dx
; sub.w d3,d5	;dz
; move.w xoff,d0
; move.w zoff,d6
;
; sub.w d2,d0
; sub.w d3,d6
;
; muls d0,d4
; muls d6,d5
; add.l d4,d5
; bge.s .leftnotoktoclip

*************************************



; move.w d1,(a6)
; move.w d3,2(a6)
				cmp.w	leftclip,d1
				ble.s	.leftnotoktoclip
				move.w	d1,leftclip
.leftnotoktoclip:

				addq	#2,a0

				rts

NEWsetrclip
				move.l	#OnScreen,a1
				move.l	#Rotated,a2
				move.l	Lvl_ConnectTablePtr_l,a3
				move.w	(a0),d0
				bge.s	.notignoreright
; move.w #96,4(a6)
; move.w #0,6(a6)
				move.w	#0,d4
				bra		.rightnotoktoclip
.notignoreright:
				move.w	6(a2,d0*8),d4			; right z val
				bgt.s	.rightclipinfront
; move.w #96,4(a6)
; move.w #0,6(a6)
				bra.s	.rightnotoktoclip

.rightclipinfront:
				move.w	(a1,d0*2),d1			; right x on screen
				move.w	(a0),d2
				move.w	(a3,d2.w*4),d2
				move.w	(a1,d2.w*2),d2
				cmp.w	d1,d2
				blt.s	.rightnotoktoclip
; move.w d1,4(a6)
; move.w d4,6(a6)


*************************************

; move.w (a3,d0.w*4),d6
;
; move.w (a4,d0.w*4),d2
; move.w 2(a4,d0.w*4),d3
; move.w (a4,d6.w*4),d4
; move.w 2(a4,d6.w*4),d5
;
; sub.w d2,d4	;dx
; sub.w d3,d5	;dz
; move.w xoff,d0
; move.w zoff,d6
;
; sub.w d2,d0
; sub.w d3,d6
;
; muls d0,d4
; muls d6,d5
; add.l d4,d5
; ble.s .rightnotoktoclip

*************************************



				cmp.w	rightclip,d1
				bge.s	.rightnotoktoclip
				addq	#1,d1
				move.w	d1,rightclip
.rightnotoktoclip:
				addq	#8,a6
				addq	#2,a0
				rts

FIRSTsetlrclip:
				move.l	#OnScreen,a1
				move.l	#Rotated,a2

				move.w	(a0)+,d0
				bge.s	.notignoreleft
				bra		.leftnotoktoclip
.notignoreleft:

				move.w	6(a2,d0*8),d3			; left z val
				bgt.s	.leftclipinfront

				move.w	(a0),d0
				blt.s	.ignoreboth
				tst.w	6(a2,d0*8)
				bgt.s	.leftnotoktoclip
.ignoreboth
				move.w	Vid_RightX_w,rightclip
				move.w	#0,leftclip
				addq	#2,a0
				rts

.leftclipinfront:
				move.w	(a1,d0*2),d1			; left x on screen
				cmp.w	leftclip,d1
				ble.s	.leftnotoktoclip
				move.w	d1,leftclip
.leftnotoktoclip:

				move.w	(a0)+,d0
				bge.s	.notignoreright
				move.w	#0,d4
				bra		.rightnotoktoclip
.notignoreright:
				move.w	6(a2,d0*8),d4			; right z val
				ble.s	.rightnotoktoclip

.rightclipinfront:
				move.w	(a1,d0*2),d1			; right x on screen
				addq	#1,d1
				cmp.w	rightclip,d1
				bge.s	.rightnotoktoclip
				move.w	d1,rightclip
.rightnotoktoclip:

; move.w leftclip,d0
; move.w rightclip,d1
; cmp.w d0,d1
; bge.s .noswap
; move.w #SMALL_WIDTH,rightclip
; move.w #0,leftclip
;.noswap:

				rts


leftclip2:		dc.w	0
rightclip2:		dc.w	0
ZoneBright:		dc.w	0

npolys:			dc.w	0

PLR1_fire:		dc.b	0
PLR2_fire:		dc.b	0

*****************************************************

***********************************
* This routine animates brightnesses.


;liftpt:			dc.l	liftanimtab

;brightpt:
				dc.l	brightanimtab

******************************
				include	"objectmove.s"
				include	"newanims.s"
				include	"modules/ai.s"
******************************

********** WALL STUFF *******************************

				include	"hireswall.s"
				include	"hiresgourwall.s"

*****************************************************

******************************************
* floor polygon

numsidestd:		dc.w	0
bottomline:		dc.w	0

checkforwater:
				tst.b	usewater
				beq.s	.notwater

				move.l	Roompt,a1
				move.w	(a1),d7
				cmp.w	Draw_CurrentZone_w,d7
				bne.s	.notwater

				move.b	#$f,fillscrnwater

.notwater:
				move.w	(a0)+,d6				; # sides-1
;				add.w	d6,d6
;				add.w	d6,a0					; a0 + (sides-1)*2
;				add.w	#4+6,a0					; a0 + (sides-1)*2 + 10
				lea		10(a0,d6.w*2),a0
				rts

				rts

;NewCornerBuff:
; ds.l 100
CLRNOFLOOR:		dc.w	0

itsafloordraw:

* If D0 =1 then its a floor otherwise (=2) it's
* a roof.

				move.w	#0,above				; reset 'above'
				move.w	(a0)+,d6				; floorY of floor/ceiling?

				tst.b	usewater
				beq.s	.oknon
				tst.b	DOANYWATER
				beq		dontdrawreturn
.oknon

				move.w	d6,d7
				ext.l	d7
				asl.l	#6,d7					; floorY << 6?

				cmp.l	TOPOFROOM,d7
				blt		checkforwater			;
				cmp.l	BOTOFROOM,d7
				bgt.s	dontdrawreturn

				move.w	leftclip,d7
				cmp.w	rightclip,d7
				bge.s	dontdrawreturn			; don't draw if there's no room betwen left and rightclip

				sub.w	flooryoff,d6			; (floorY - viewerY)

				bgt.s	below					; floor is below
				blt.s	aboveplayer				; floor is above

				tst.b	usewater
				beq.s	.notwater

				move.l	Roompt,a1
				move.w	(a1),d7
				cmp.w	Draw_CurrentZone_w,d7

				bne.s	.notwater

				st		fillscrnwater

.notwater:


dontdrawreturn:
				move.w	(a0)+,d6				; sides-1
				;add.w	d6,d6
				;add.w	d6,a0
				;add.w	#4+6,a0
				lea		10(a0,d6.w*2),a0		; skip sides
				rts
aboveplayer:
				tst.b	usewater
				beq.s	.notwater

				move.l	Roompt,a1
				move.w	(a1),d7
				cmp.w	Draw_CurrentZone_w,d7
				bne.s	.notwater

				move.b	#$f,fillscrnwater

				; Is above camera
.notwater:		btst	#1,d0					; If its above the player and if its not a ceiling (a floor?), skip it
				beq.s	dontdrawreturn

				; its a ceiling
				move.w	Vid_CentreY_w,d7
				sub.w	draw_TopClip_w,d7
				ble.s	dontdrawreturn

				move.w	#1,d0
				move.w	d0,above				; replace with st above? But then also check the various places that tst.w it
				neg.w	d6
				bra.s	notbelow

				; is below camera
below:
				move.w	draw_BottomClip_w,d7
				sub.w	Vid_CentreY_w,d7
				ble.s	dontdrawreturn			; don't draw if no room between screen center amd bottom clip


notbelow:
				btst	#0,d0					; if its below the player and is not a floor, skip it
				beq.s	dontdrawreturn

				move.w	d6,View2FloorDist		; (floorY - ViewerY) in worldspace
				;		|
				;-------+---------------------- Vid_CentreY_w
				;***    |
				;   *** |
				;      *** clipY
				;       |  ***
				;-------------***----------------FloorDist from Viewer
				;>   minZ		<
				;
				; clip Y =  FloorDist/minZ
				; minZ = FloorDist / clipY

				move	d6,d5
				ext.l	d5
				asl.l	#6,d5					; View2FloorDist << 6
				move.l	d5,ypos					; ypos = View2FloorDist * 64

				;ext.l	d7
				;divs.l	d7,d6					; d6 = (floorY - ViewerY) / (Y-clip to middleY)?
												; projects the Y-clip screen coordinate to Z in the world
												; it thus

				mulu.w	OneOverN(pc,d7.w*2),d6
				lsr.l	#8,d6

; visible line

				beq		dontdrawreturn

				cmp.l	#32767,d6
				bgt		dontdrawreturn

				move.w	d6,minz
				move.w	d7,bottomline

; Go round each point finding out
; if it should be visible or not.

				move.l	a0,-(a7)

				move.w	(a0)+,d7				; number of sides
				move.l	#Rotated,a1
				move.l	#OnScreen,a2
; move.l #NewCornerBuff,a3
				moveq	#0,d4					; some points left to left clip
				moveq	#0,d5					; some points fully between left and right clip
				moveq	#0,d6					; some points right of right clip
				clr.b	anyclipping				; some clipping will be necessary?


cornerprocessloop: ;	figure					out if any left/right clipping is necessary
				; this also helps rejecting whole floors, almost in a portal-engine fashion

				move.w	(a0)+,d0				; point index
				and.w	#$fff,d0
				move.w	6(a1,d0.w*8),d1			; fetch prerotated point Z fractional part?
				ble		.canttell

				move.w	(a2,d0.w*2),d3			; fetch projected X coordinate
				cmp.w	leftclip,d3
				bgt.s	.nol					; right of left clip
				st		d4
				st		anyclipping
				bra.s	.nos
.nol:
				cmp.w	rightclip,d3
				blt.s	.nor					; left of right clip
				st		d6
				st		anyclipping
				bra.s	.nos
.nor:
				st		d5
.nos:
				bra		.cantell

.canttell:
				st		d5
				st		anyclipping

.cantell:
				dbra	d7,cornerprocessloop

				move.l	(a7)+,a0
				tst.b	d5						; if this is 0, none of the corner points were inside the clip region
				bne.s	somefloortodraw
				eor.b	d4,d6					; if some were left of left clip and the others right of right clip
											; some floor covers the clip region
											; only if they are all left or all right, nothing needs to be drawn
				bne		dontdrawreturn

somefloortodraw:
				tst.b	gourfloor
				bne		goursides

				move.w	#300,top				; running top clip
				move.w	#-1,bottom				; running bottom clip
				move.w	#0,drawit
				move.l	#Rotated,a1
				move.l	#OnScreen,a2
				move.w	(a0)+,d7				; no of sides

; clip floor polygon against closest possible visible z (due to bottom/top clipping) "minz"
sideloop:
				move.w	minz,d6
				move.w	(a0)+,d1				; floor line point indices
				move.w	(a0),d3
				and.w	#$fff,d1				; mod 4096 , why?
				and.w	#$fff,d3				; mod 4096

				move.w	6(a1,d1*8),d4			; first z
				cmp.w	d6,d4
				bgt		firstinfront

				move.w	6(a1,d3*8),d5			; sec z
				cmp.w	d6,d5
				ble		bothbehind

** line must be on left and partially behind.
				sub.w	d5,d4					; dz
				move.l	(a1,d1*8),d0			; first x
				sub.l	(a1,d3*8),d0			; dx = first x - second x

				asr.l	#7,d0					; dx << 9

				sub.w	d5,d6					; distMinz = minz - z
												; (projecting onto nearplane)

				muls	d6,d0					; x' = dist * dx
				divs	d4,d0					; x' = distMinz * dx/dz
				ext.l	d0
				asl.l	#7,d0

				add.l	(a1,d3*8),d0			; x' = x + distMinz * dx/dz
				move.w	minz,d4					; z' = minZ
				move.w	(a2,d3*2),d2
				divs.w	d4,d0					; x' - x' / minz
				add.w	Vid_CentreX_w,d0

				move.l	ypos,d3
				divs	d5,d3					; y2' = y2 / z2

				move.w	bottomline,d1
				bra		lineclipped

firstinfront:
				move.w	6(a1,d3*8),d5			; sec z
				cmp.w	d6,d5
				bgt		bothinfront

** line must be on right and partially behind.
				sub.w	d4,d5					; dz
				move.l	(a1,d3*8),d2
				sub.l	(a1,d1*8),d2			; dx
				sub.w	d4,d6					; minz - z

				asr.l	#7,d2
				muls	d6,d2					; new x coord
				divs	d5,d2					; x ' = (dx >> 7) * (minz - z) / dz
				ext.l	d2

				asl.l	#7,d2					; x' >> 7
				add.l	(a1,d1*8),d2			; x ' = x1 + x'

				move.w	minz,d5
				move.w	(a2,d1*2),d0
				divs	d5,d2
				add.w	Vid_CentreX_w,d2
				move.l	ypos,d1
				divs	d4,d1
				move.w	bottomline,d3
				bra		lineclipped

bothinfront:

* Also, usefully enough, both are on-screen
* so no bottom clipping is needed.

				move.w	(a2,d1*2),d0			; first x
				move.w	(a2,d3*2),d2			; second x
				move.l	ypos,d1
				move.l	d1,d3
				divs	d4,d1					; ypos / first z
				divs	d5,d3					; ypos / second z

				; line is  now in (d0/d1 )(d2/d3)  x/y
				; now "draw" the projected line into the line buffer which stores X
				; values
lineclipped:
				move.l	#rightsidetab,a3
				cmp.w	d1,d3
				beq		lineflat				; if line is flat, skip

				st		drawit
				bgt		lineonright
				move.l	#leftsidetab,a3

				; switch points to make line sloped downwards
				exg		d1,d3
				exg		d0,d2

				lea		(a3,d1*2),a3			; start of left side buffer

				cmp.w	top(pc),d1
				bge.s	.no_new_top
				move.w	d1,top
.no_new_top:
				cmp.w	bottom(pc),d3
				ble.s	.no_new_bottom
				move.w	d3,bottom
.no_new_bottom:

				sub.w	d1,d3					; dy
				sub.w	d0,d2					; dx

				blt		.linegoingleft

				ext.l	d2
				divs	d3,d2
				move.w	d2,d6					; dx/dy
				swap	d2						; dx mod dy

; moveq #0,d6
; sub.w d3,d2
; blt.s .noco
;.makeco
; addq #1,d6
; sub.w d3,d2
; bge.s .makeco
;.noco
; add.w d3,d2

				move.w	d3,d4					; dy
				move.w	d3,d5
				subq	#1,d5					; dy - 1   loop counter
				move.w	d6,d1
				addq	#1,d1					; dx/dy + 1

				; Is this "drawing" left line into a buffer, using bresenham, storing the X values into a3
.pixlopright:
				move.w	d0,(a3)+				; store x in left side entry buffer
				sub.w	d2,d4					; dy - (dx mod dy)
				bge.s	.nobigstep
				add.w	d1,d0
				add.w	d3,d4
				dbra	d5,.pixlopright
				bra		lineflat
.nobigstep
				add.w	d6,d0
				dbra	d5,.pixlopright
				bra		lineflat

			; line is  now in (d0/d1 )(d2/d3)  x/y
			; now "draw" the projected line into the line buffer which stores X
			; values
.linegoingleft:

				neg.w	d2						; dx = -dx

				ext.l	d2
				divs	d3,d2					; dx/dy
				move.w	d2,d6
				swap	d2						; dx mod dy


; moveq #0,d6
; sub.w d3,d2
; blt.s .nocol
;.makecol
; addq #1,d6
; sub.w d3,d2
; bge.s .makecol
;.nocol
; add.w d3,d2



				move.w	d3,d4
				move.w	d3,d5
				subq	#1,d5

				move.w	d6,d1
				addq	#1,d1

.pixlopleft:
				sub.w	d2,d4
				bge.s	.nobigstepl
				sub.w	d1,d0
				add.w	d3,d4
				move.w	d0,(a3)+				;  store left side entry
				dbra	d5,.pixlopleft
				bra		lineflat

.nobigstepl
				sub.w	d6,d0
				move.w	d0,(a3)+				; store left side entry
				dbra	d5,.pixlopleft
				bra		lineflat

			; Is this "drawing" right line into a buffer, storing the X values into a3
lineonright:

				lea		(a3,d1*2),a3			;right line entry start

				cmp.w	top(pc),d1
				bge.s	.no_new_top
				move.w	d1,top
.no_new_top:
				cmp.w	bottom(pc),d3
				ble.s	.no_new_bottom
				move.w	d3,bottom
.no_new_bottom:

				sub.w	d1,d3					; dy
				sub.w	d0,d2					; dx
				blt		.linegoingleft
; addq #1,d0
				ext.l	d2
				divs	d3,d2
				move.w	d2,d6
				swap	d2

; moveq #0,d6
; sub.w d3,d2
; blt.s .noco
;.makeco
; addq #1,d6
; sub.w d3,d2
; bge.s .makeco
;.noco
; add.w d3,d2

				move.w	d3,d4
				move.w	d3,d5
				subq	#1,d5
				move.w	d6,d1
				addq	#1,d1

.pixlopright:
				sub.w	d2,d4
				bge.s	.nobigstep
				add.w	d1,d0
				add.w	d3,d4
				move.w	d0,(a3)+				; store right entry
				dbra	d5,.pixlopright
				bra		lineflat

.nobigstep
				add.w	d6,d0
				move.w	d0,(a3)+				; store right entry
				dbra	d5,.pixlopright
				bra		lineflat

.linegoingleft:
; addq #1,d0
				neg.w	d2

				ext.l	d2
				divs	d3,d2
				move.w	d2,d6
				swap	d2


; moveq #0,d6
; sub.w d3,d2
; blt.s .nocol
;.makecol
; addq #1,d6
; sub.w d3,d2
; bge.s .makecol
;.nocol
; add.w d3,d2

				move.w	d3,d4
				move.w	d3,d5
				subq	#1,d5
				move.w	d6,d1
				addq	#1,d1

.pixlopleft:
				move.w	d0,(a3)+
				sub.w	d2,d4
				bge.s	.nobigstepl
				sub.w	d1,d0
				add.w	d3,d4
				dbra	d5,.pixlopleft
				bra		lineflat

.nobigstepl
				sub.w	d6,d0
				dbra	d5,.pixlopleft

lineflat:

bothbehind:
				dbra	d7,sideloop
				bra		pastsides

fbr:			dc.w	0
sbr:			dc.w	0
FloorPtBrights:	dc.l	0

goursides:

				move.w	#300,top
				move.w	#-1,bottom
				move.w	#0,drawit
				move.l	#Rotated,a1
				move.l	#OnScreen,a2
				move.w	(a0)+,d7				; no of sides
sideloopGOUR:
				move.w	minz,d6
				move.w	(a0)+,d1
				move.w	(a0),d3

				move.w	d1,d4
				move.w	d3,d5
				and.w	#$0fff,d1
				and.w	#$0fff,d3

				rol.w	#4,d4
				rol.w	#4,d5
				and.w	#$f,d4
				and.w	#$f,d5

				move.l	FloorPtBrights,a4
				move.w	(a4,d4.w*8),d4
				bge.s	.okpos1
				neg.w	d4
.okpos1:
				sub.w	#300,d4
				move.w	d4,fbr
				move.w	(a4,d5.w*8),d4
				bge.s	.okpos2
				neg.w	d4
.okpos2:
				sub.w	#300,d4
				move.w	d4,sbr

				move.w	6(a1,d1*8),d4			;first z
				cmp.w	d6,d4
				bgt		firstinfrontGOUR

				move.w	6(a1,d3*8),d5			; sec z
				cmp.w	d6,d5
				ble		bothbehindGOUR
** line must be on left and partially behind.
				sub.w	d5,d4

				move.w	fbr,d0
				sub.w	sbr,d0
				sub.w	d5,d6
				muls	d6,d0

				divs	d4,d0
				add.w	sbr,d0
				move.w	d0,fbr

				move.l	(a1,d1*8),d0
				sub.l	(a1,d3*8),d0
				asr.l	#7,d0
				muls	d6,d0					; new x coord
				divs	d4,d0

				ext.l	d0
				asl.l	#7,d0

				add.l	(a1,d3*8),d0
				move.w	minz,d4
				move.w	(a2,d3*2),d2
				divs	d4,d0
				add.w	Vid_CentreX_w,d0
				move.l	ypos,d3
				divs	d5,d3

				move.w	bottomline,d1
				bra		lineclippedGOUR

firstinfrontGOUR:
				move.w	6(a1,d3*8),d5			; sec z
				cmp.w	d6,d5
				bgt		bothinfrontGOUR
** line must be on right and partially behind.
				sub.w	d4,d5					; dz

				move.w	sbr,d2
				sub.w	fbr,d2
				sub.w	d4,d6
				muls	d6,d2
				divs	d5,d2
				add.w	fbr,d2
				move.w	d2,sbr

				move.l	(a1,d3*8),d2
				sub.l	(a1,d1*8),d2			; dx
				asr.l	#7,d2
				muls	d6,d2					; new x coord
				divs	d5,d2

				ext.l	d2
				asl.l	#7,d2
				add.l	(a1,d1*8),d2
				move.w	minz,d5					; minz = nearclip distance?
				move.w	(a2,d1*2),d0
				divs	d5,d2
				add.w	Vid_CentreX_w,d2
				move.l	ypos,d1
				divs	d4,d1
				move.w	bottomline,d3
				bra		lineclippedGOUR

bothinfrontGOUR:

* Also, usefully enough, both are on-screen
* so no bottom clipping is needed.

				move.w	(a2,d1*2),d0			; first x
				move.w	(a2,d3*2),d2			; second x


				move.l	ypos,d1
				move.l	d1,d3
				divs	d4,d1					; first y
				divs	d5,d3					; second y


lineclippedGOUR:
				move.l	#rightsidetab,a3
				cmp.w	d1,d3
				bne		linenotflatGOUR

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
				bra		lineflatGOUR

linenotflatGOUR
				st		drawit
				bgt		lineonrightGOUR
				move.l	#leftsidetab,a3
				exg		d1,d3
				exg		d0,d2

				lea		(a3,d1*2),a3			; left side entry
				lea		leftbrighttab-leftsidetab(a3),a4 ; left side brightness entry

				cmp.w	top(pc),d1
				bge.s	.no_new_top
				move.w	d1,top
.no_new_top:
				cmp.w	bottom(pc),d3
				ble.s	.no_new_bottom
				move.w	d3,bottom
.no_new_bottom:

				sub.w	d1,d3					; dy
				sub.w	d0,d2					; dx

				blt		.linegoingleft

				ext.l	d2
				divs	d3,d2
				move.w	d2,d6					; dx/dy
				swap	d2						; dx mod dy?
				move.w	d2,a5

; moveq #0,d6
; sub.w d3,d2
; blt.s .noco
;.makeco
; addq #1,d6
; sub.w d3,d2
; bge.s .makeco
;.noco
; add.w d3,d2

				move.w	d3,d4					; dy
				move.w	d3,d5					; dy
				subq	#1,d5					; dy-1
				move.w	d6,d1
				addq	#1,d1
				move.w	d1,a6

				moveq	#0,d1
				move.w	sbr,d1
				move.w	fbr,d2
				sub.w	d1,d2
				ext.l	d2

				asl.w	#8,d2					; is this some gouraud math?
				asl.w	#2,d2
				divs	d3,d2
				ext.l	d2
				asl.l	#6,d2

				swap	d1

.pixlopright:
				move.w	d0,(a3)+				; store left side entry
				swap	d1
				move.w	d1,(a4)+				; store left side entry brightness
				swap	d1
				add.l	d2,d1

				sub.w	a5,d4
				bge.s	.nobigstep
				add.w	a6,d0
				add.w	d3,d4
				dbra	d5,.pixlopright
				bra		lineflatGOUR
.nobigstep

				add.w	d6,d0
				dbra	d5,.pixlopright
				bra		lineflatGOUR

.linegoingleft:

				neg.w	d2

				ext.l	d2
				divs	d3,d2
				move.w	d2,d6
				swap	d2


; moveq #0,d6
; sub.w d3,d2
; blt.s .nocol
;.makecol
; addq #1,d6
; sub.w d3,d2
; bge.s .makecol
;.nocol
; add.w d3,d2

				move.w	d3,d4
				move.w	d3,d5
				subq	#1,d5

				move.w	d6,d1
				addq	#1,d1
				move.w	d1,a6
				move.w	d2,a5

				moveq	#0,d1
				move.w	sbr,d1
				move.w	fbr,d2
				sub.w	d1,d2
				ext.l	d2
				asl.w	#8,d2
				asl.w	#2,d2
				divs	d3,d2
				ext.l	d2
				asl.l	#6,d2
				swap	d1

.pixlopleft:

				swap	d1
				move.w	d1,(a4)+				; store right side entry brightness
				swap	d1
				add.l	d2,d1

				sub.w	a5,d4
				bge.s	.nobigstepl
				sub.w	a6,d0
				add.w	d3,d4
				move.w	d0,(a3)+				; store left side entry
				dbra	d5,.pixlopleft
				bra		lineflatGOUR

.nobigstepl
				sub.w	d6,d0
				move.w	d0,(a3)+				; store left side entry
				dbra	d5,.pixlopleft
				bra		lineflatGOUR

lineonrightGOUR:

				lea		(a3,d1*2),a3			; left side entry

				lea		rightbrighttab-rightsidetab(a3),a4 ; right brightness entry

				cmp.w	top(pc),d1
				bge.s	.no_new_top
				move.w	d1,top
.no_new_top:
				cmp.w	bottom(pc),d3
				ble.s	.no_new_bottom
				move.w	d3,bottom
.no_new_bottom:

				sub.w	d1,d3					; dy
				sub.w	d0,d2					; dx
				blt		.linegoingleft
; addq #1,d0
				ext.l	d2
				divs	d3,d2
				move.w	d2,d6
				swap	d2

; moveq #0,d6
; sub.w d3,d2
; blt.s .noco
;.makeco
; addq #1,d6
; sub.w d3,d2
; bge.s .makeco
;.noco
; add.w d3,d2

				move.w	d3,d4
				move.w	d3,d5
				subq	#1,d5
				move.w	d6,d1
				addq	#1,d1

				move.w	d1,a6
				move.w	d2,a5

				moveq	#0,d1
				move.w	fbr,d1
				move.w	sbr,d2
				sub.w	d1,d2
				ext.l	d2
				asl.w	#8,d2
				asl.w	#2,d2
				divs	d3,d2
				ext.l	d2
				asl.l	#6,d2
				swap	d1

.pixlopright:

				swap	d1
				move.w	d1,(a4)+				; store right side brightness entry
				swap	d1
				add.l	d2,d1

				sub.w	a5,d4
				bge.s	.nobigstep
				add.w	a6,d0
				add.w	d3,d4
				move.w	d0,(a3)+				; store right side entry
				dbra	d5,.pixlopright
				bra		lineflatGOUR

.nobigstep
				add.w	d6,d0
				move.w	d0,(a3)+				;  store right side entry
				dbra	d5,.pixlopright
				bra		lineflatGOUR

.linegoingleft:
; addq #1,d0
				neg.w	d2

				ext.l	d2
				divs	d3,d2
				move.w	d2,d6
				swap	d2


; moveq #0,d6
; sub.w d3,d2
; blt.s .nocol
;.makecol
; addq #1,d6
; sub.w d3,d2
; bge.s .makecol
;.nocol
; add.w d3,d2

				move.w	d3,d4
				move.w	d3,d5
				subq	#1,d5
				move.w	d6,d1
				addq	#1,d1
				move.w	d1,a6
				move.w	d2,a5

				moveq	#0,d1
				move.w	fbr,d1
				move.w	sbr,d2
				sub.w	d1,d2
				ext.l	d2
				asl.w	#8,d2
				asl.w	#2,d2
				divs	d3,d2
				ext.l	d2
				asl.l	#6,d2
				swap	d1

.pixlopleft:

				swap	d1
				move.w	d1,(a4)+				; store left entry brightness
				swap	d1
				add.l	d2,d1

				move.w	d0,(a3)+				; store left entry x
				sub.w	a5,d4
				bge.s	.nobigstepl
				sub.w	a6,d0
				add.w	d3,d4
				dbra	d5,.pixlopleft
				bra		lineflatGOUR

.nobigstepl
				sub.w	d6,d0
				dbra	d5,.pixlopleft

lineflatGOUR:

bothbehindGOUR:
				dbra	d7,sideloopGOUR


; I think wwhat happens is that the above code records lots of left/right pixel
; pairs in lefttab, leftbrightab, righttab and rightbrighttab by edge-walking the floor polygon.
; Each entry's offset in the tables are hard0-wired to a specific Y position in the rendered
; image. I.e. lighttab[5] is the leftmost X coordinate of the floor on line 5 of the screen.

; Here we setup the actual line drawing
pastsides:

				addq	#2,a0

				move.w	#SCREENWIDTH,linedir	; moving from one horizontal line to the next
												; floors walk downwards

; move.l FASTBUFFER2,a6
; add.l BIGMIDDLEY,a6
; move.l a6,REFPTR

				move.l	Vid_FastBufferPtr_l,a6
				add.l	BIGMIDDLEY,a6			; pointer to middle line of screen
				move.w	(a0)+,d6				; floor scale?
				add.w	SMALLIT,d6
				move.w	d6,scaleval
				move.w	(a0)+,d6
				move.w	d6,whichtile
				move.w	(a0)+,d6
				add.w	ZoneBright,d6
				move.w	d6,lighttype
				move.w	above(pc),d6			; is floor above player (i.e. ceiling)
				beq		groundfloor
* on ceiling:
				move.w	#-SCREENWIDTH,linedir	; ceilings are walked bottom to top
				suba.w	#SCREENWIDTH,a6
groundfloor:

				move.w	xoff,d6
				move.w	zoff,d7
				add.w	xwobxoff,d6				; this was adding xwobxoff to d7, was this a bug?
				add.w	xwobzoff,d7

				tst.b	Vid_FullScreen_b
				beq.s	.shiftit

				;ext.l	d6
				;ext.l	d7
				;asl.l	#2,d6		; Fullscreen : scale world by *4/3,
				;asl.l	#2,d7
				;divs	#3,d6
				;divs	#3,d7
				;swap	d6
				;swap	d7
				;clr.w	d6
				;clr.w	d7
				;asr.l	#2,d6
				;asr.l	#2,d7

				; stll don't really understand why the render aspect ratio gets rolled into here
				; as these are supposed to be the viewer/s position in the world
				muls.w	#21845,d6				; (4/3<<16)/4
				muls.w	#21845,d7

				bra.s	.donsht

.shiftit
; divs #3,d6
; divs #3,d7
				swap	d6
				swap	d7
				clr.w	d6
				clr.w	d7
				asr.l	#1,d6
				asr.l	#1,d7


.donsht:
				move.w	scaleval(pc),d3			; FIMXE: is this an opportunity to scale for DOUBLEWIDTH/DOUBLEHEIGHT?
				beq.s	.samescale
				bgt.s	.scaledown
				neg.w	d3
				asr.l	d3,d7
				asr.l	d3,d6
				bra.s	.samescale
.scaledown:
				asl.l	d3,d6
				asl.l	d3,d7
.samescale
				move.l	d6,sxoff
				move.l	d7,szoff
				bra		pastscale

top:			dc.w	0
bottom:			dc.w	0
ypos:			dc.l	0
nfloors:		dc.w	0
lighttype:		dc.w	0
above:			dc.w	0
linedir:		dc.w	0
View2FloorDist:	dc.w	0

minz:			dc.l	0

leftsidetab:
				ds.w	512*2
rightsidetab:
				ds.w	512*2
leftbrighttab:
				ds.w	512*2
rightbrighttab:
				ds.w	512*2

PointBrights:
				dc.l	0
CurrentPointBrights:
				ds.l	2*256*10

movespd:		dc.w	0
largespd:		dc.l	0
disttobot:		dc.w	0

OneOverN:		; 1/N	* 16384
				dc.w	0						;16384/0 not defined
val				SET		1
				REPT	255
				dc.w	16384/val
val				SET		val+1
				ENDR


********************************************************************************

				; Walk the stored lines and draw them
pastscale:
				tst.b	drawit(pc)
				beq		dontdrawfloor

				tst.b	DOUBLEHEIGHT
				beq		pix1h

				; DOUBLEHEIGHT rendering
				move.l	a0,-(a7)
				move.w	linedir,d1				; line to line in screen
				add.w	d1,linedir				; x2

				move.l	#leftsidetab,a4
				move.w	top(pc),d1
				tst.w	above					; is above camera?
				beq.s	.clipfloor				; no, its a floor!

; Its a ceiling, clip it to top/bottom
; For ceilings, the top and bottom have reversed roles
; The ceiling's +Y goes "up" on the screen, with Vid_CentreY_w of screen mapping to 0.
; That's why there's the gymnastics with ; (Vid_CentreY_w - N) to transform the
; screen clipping coordinates into "ceiling coordinates"
; This turns the 'top' variable actually into the bottommost Y of the ceiling.

				move.w	Vid_CentreY_w,d7
				btst	#0,d7
				bne.s	.evenMiddleRoof
				sub.w	#SCREENWIDTH,a6			; with regular nx1 rendering, we usually start at an odd line for ceiling rendering

.evenMiddleRoof	subq	#1,d7
				sub.w	d1,d7
				move.w	d7,disttobot

				move.w	bottom(pc),d7			; bottom of floor
				move.w	Vid_CentreY_w,d3
				move.w	d3,d4
				sub.w	draw_TopClip_w,d3
				sub.w	draw_BottomClip_w,d4
				cmp.w	d3,d1
				bge		predontdrawfloor		; top_of_floor >= (Vid_CentreY_w-draw_TopClip_w)
				cmp.w	d4,d7
				blt		predontdrawfloor		; bottom_of_floor < (Vid_CentreY_w-draw_BottomClip_w) ?
				cmp.w	d4,d1
				bge.s	.nocliptoproof			; top_of_floor >= (Vid_CentreY_w-draw_BottomClip_w)  ?
				move.w	d4,d1					; clip top_of_floor to (Vid_CentreY_w-draw_BottomClip_w)
.nocliptoproof
				cmp.w	d3,d7
				blt		.doneclip
				move.w	d3,d7

				bra		.doneclip

; Its a floor, clip it to top/bottom
; FIXME: didn't we already clip to the bottom clip (minZ) ?

.clipfloor:
				move.w	Vid_BottomY_w,d7
				move.w	Vid_CentreY_w,d4
				btst	#0,d4
				beq.s	.evenMiddleFloor
				add.w	#SCREENWIDTH,a6

.evenMiddleFloor sub.w	d4,d7
				subq	#1,d7
				sub.w	d1,d7
				move.w	d7,disttobot

				move.w	bottom(pc),d7

				move.w	draw_BottomClip_w,d4
				sub.w	Vid_CentreY_w,d4
				cmp.w	d4,d1
				bge		predontdrawfloor		; top >= (draw_BottomClip_w - Vid_CentreY_w)

				move.w	draw_TopClip_w,d3
				sub.w	Vid_CentreY_w,d3
				cmp.w	d3,d1
				bge.s	.nocliptopfloor			; top >= (draw_TopClip_w - Vid_CentreY_w)

				move.w	d3,d1					; clip top_of_floor to (draw_TopClip_w - Vid_CentreY_w)
.nocliptopfloor
				cmp.w	d3,d7
				ble		predontdrawfloor		; (bottom) <= (draw_TopClip_w - Vid_CentreY_w) : bottom <= draw_TopClip_w (bottom of floor above draw_TopClip_w)
				cmp.w	d4,d7
				blt.s	.noclipbotfloor			; (bottom) < (draw_BottomClip_w)
				move.w	d4,d7					; bottom = draw_BottomClip_w
.noclipbotfloor:


.doneclip:		;addq.w	#1,d1					; snap start of floor to even line - needed?!
				;and.w	#~1,d1

				lea		(a4,d1*2),a4			; adress of first floor/roof line

				addq	#1,d7
				sub.w	d1,d7					; number of lines

				asr.w	#1,d7					; number of lines /2 for DOUBLEHEIGHT
				ble		predontdrawfloor		; nothing left?

				asr.w	#1,d1					; top line/2 for DOUBLEHEIGHT

				move.w	View2FloorDist,d0		; ydist<<6 to floor/ceiling	; distance of viewer to floor
				ext.l	d0
				lsl.l	#6,d0
				move.l	d0,a2					; a2

				move.w	d1,d0
				bne.s	.notzero
				moveq	#1,d0					; always start at line 1?
.notzero
				add.w	d0,d0					; start line# *2 DOUBLEHEIGHT

				muls.w	linedir,d1				; top line in screen times renderwidth (typical 320)
				add.l	d1,a6					; this is where we start writing?

				move.l	TexturePal,a1
				add.l	#256*32,a1
				move.l	LineToUse,a5

				move.w	#4,tonextline			; line tab advance?

				bra		pix2h

				; Regular Nx1 line rendering
pix1h:

				move.l	a0,-(a7)

				move.l	#leftsidetab,a4
				move.w	top(pc),d1

				tst.w	above
				beq.s	clipfloor

				; clip roof?
				move.w	Vid_CentreY_w,d7
				subq	#1,d7
				sub.w	d1,d7
				move.w	d7,disttobot

				move.w	bottom(pc),d7
				move.w	Vid_CentreY_w,d3
				move.w	d3,d4
				sub.w	draw_TopClip_w,d3
				sub.w	draw_BottomClip_w,d4
				cmp.w	d3,d1
				bge		predontdrawfloor		; top >= Vid_CentreY_w - draw_TopClip_w
				cmp.w	d4,d7
				blt		predontdrawfloor		; bottom >= Vid_CentreY_w - bottomclip
				cmp.w	d4,d1
				bge.s	.nocliptoproof			; top >= Vid_CentreY_w - bottomclip
				move.w	d4,d1					; top = Vid_CentreY_w - bottomclip
.nocliptoproof
				cmp.w	d3,d7
				blt		doneclip
				move.w	d3,d7
				bra		doneclip

clipfloor:
				move.w	Vid_BottomY_w,d7
				sub.w	Vid_CentreY_w,d7
				subq	#1,d7
				sub.w	d1,d7
				move.w	d7,disttobot

				move.w	bottom(pc),d7
				move.w	draw_BottomClip_w,d4
				sub.w	Vid_CentreY_w,d4
				cmp.w	d4,d1
				bge		predontdrawfloor		; top >= (draw_BottomClip_w - Vid_CentreY_w)
				move.w	draw_TopClip_w,d3
				sub.w	Vid_CentreY_w,d3
				cmp.w	d3,d1
				bge.s	.nocliptopfloor			; top >= (draw_TopClip_w - Vid_CentreY_w)
				move.w	d3,d1					; top =  (draw_TopClip_w - Vid_CentreY_w)
.nocliptopfloor
				cmp.w	d3,d7
				ble		predontdrawfloor		; bottom <=  (draw_TopClip_w - Vid_CentreY_w)
				cmp.w	d4,d7
				blt.s	.noclipbotfloor			; bottom <= (draw_BottomClip_w - Vid_CentreY_w)
				move.w	d4,d7					; botom = (draw_BottomClip_w - Vid_CentreY_w)
.noclipbotfloor:

doneclip:
				lea		(a4,d1*2),a4			; go to top linetab
; move.l #dists,a2
				move.w	View2FloorDist,d0
				;muls	#64,d0			; FIXME: why muls here? Is this addressing the floor tile row?
				ext.l	d0
				lsl.l	#6,d0
				move.l	d0,a2
; muls #25,d0
; adda.w d0,a2
; lea (a2,d1*2),a2
				sub.w	d1,d7					;  number of lines to draw
				ble		predontdrawfloor
				move.w	d1,d0					; current line
				bne.s	.notzero
				moveq	#1,d0					; at least start at line 1 ?!
												; We later divide  by d0, so make sure its not 0
.notzero
				muls	linedir,d1
				add.l	d1,a6					; renderbuffer start address
; sub.l d1,REFPTR
				move.l	TexturePal,a1
				add.l	#256*32,a1
				move.l	LineToUse,a5			; This function ptr has been stored by the very outermost

				move.w	#2,tonextline			; lefttab/righttab advance?


				;double height rendering
pix2h:

				tst.b	gourfloor
				bne		dogourfloor

				tst.b	anyclipping
				beq		dofloornoclip

dofloor:
; move.w (a2)+,d0
				move.w	leftclip,d3
				move.w	rightclip,d4
				move.w	rightsidetab-leftsidetab(a4),d2 ; get rightside of line

				addq	#1,d2					; why? Is the right side X not inclusive?
				cmp.w	d3,d2					; does this make sense?
				ble.s	nodrawline				; rightside <= leftclip?

				cmp.w	d4,d2
				ble.s	noclipright				; rightclip <= rightside?
				move.w	d4,d2					; clip rightside to rightclip
noclipright:
				move.w	(a4),d1					; leftside x
				cmp.w	d4,d1
				bge.s	nodrawline				; leftside >= rightclip?
				cmp.w	d3,d1
				bge.s	noclipleft				; leftside >= leftclip
				move.w	d3,d1					; leftside = leftclip
noclipleft:
				cmp.w	d1,d2
				ble.s	nodrawline				; rightside <= leftside?

				move.w	d1,leftedge
				move.w	d2,rightedge

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

				move.l	a6,a3

				movem.l	d0/d7/a2/a4/a5/a6,-(a7)

				; perspective correct interpolation of Z over the floor by just looking at
				; the screenspace coordinate and the floor height
				; https://youtu.be/2ZAIIDXoBis?t=1385

				move.l	a2,d7					; View2FloorDist*64 (distance of viewer Y to floor in worldspace)
				;asl.l	#2,d7		; *4 = * 256
				;ext.l	d0
				;divs.w	d0,d7		; View2FloorDist * 256 / currentline
				;ext.l	d7

				lsr.l	#4,d7
				mulu.w	OneOverN(pc,d0.w*2),d7	;  View2FloorDist * 64 * 16384 / currentline
				lsr.l	#8,d7

				; for some reason important to write.l here
				move.l	d7,d0					; Z of current screen line projected to floor

				jsr		(a5)					; Call the horizontal line drawing routine!

				movem.l	(a7)+,d0/d7/a2/a4/a5/a6
nodrawline
				sub.w	#1,disttobot
				move.w	linedir(pc),d3
				adda.w	d3,a6
; ext.l d3
; sub.l d3,REFPTR
				move.w	tonextline,d3
				add.w	d3,a4
				asr.w	#1,d3
				add.w	d3,d0
				subq	#1,d7
				bgt		dofloor

predontdrawfloor
				move.l	(a7)+,a0

dontdrawfloor:

				rts

tonextline:		dc.w	0
anyclipping:	dc.w	0

dofloornoclip:
; move.w (a2)+,d0
				move.w	rightsidetab-leftsidetab(a4),d2 ;offset from leftside table entry to right side table entry
				addq	#1,d2					;

				move.w	(a4),d1
				move.w	d1,leftedge
				move.w	d2,rightedge

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

				move.l	a6,a3
				movem.l	d0/d7/a2/a4/a5/a6,-(a7)

				;move.l	a2,d7
				;asl.l	#2,d7
				;ext.l	d0
				;divs.l	d0,d7

				move.l	 a2,d7
				lsr.l	#4,d7
				mulu.w	OneOverN(pc,d0.w*2),d7	;
				lsr.l	#8,d7

				move.l	d7,d0

				jsr		(a5)

				movem.l	(a7)+,d0/d7/a2/a4/a5/a6
				sub.w	#1,disttobot
				move.w	linedir(pc),d3
				adda.w	d3,a6
; ext.l d3
; sub.l d3,REFPTR
				move.w	tonextline,d3
				add.w	d3,a4
				asr.w	#1,d3
				add.w	d3,d0
				subq	#1,d7
				bgt		dofloornoclip

				bra		predontdrawfloor

dogourfloor:
				tst.b	anyclipping
				beq		dofloornoclipGOUR

dofloorGOUR:
; move.w (a2)+,d0
				move.w	leftclip,d3
				move.w	rightclip,d4
				move.w	rightsidetab-leftsidetab(a4),d2

				move.w	d2,d5
				sub.w	(a4),d5
				addq	#1,d5
				moveq	#0,d6

				addq	#1,d2
				cmp.w	d3,d2
				ble		nodrawlineGOUR
				cmp.w	d4,d2
				ble.s	nocliprightGOUR
				move.w	d4,d2
nocliprightGOUR:
				move.w	(a4),d1
				cmp.w	d4,d1
				bge		nodrawlineGOUR
				cmp.w	d3,d1
				bge.s	noclipleftGOUR
				move.w	d3,d6
				subq	#1,d6
				sub.w	d1,d6
				move.w	d3,d1
noclipleftGOUR:
				cmp.w	d1,d2
				ble		nodrawlineGOUR

				move.w	d1,leftedge
				move.w	d2,rightedge

				move.l	a2,d2

				;asl.l	#2,d2
				;ext.l	d0
				;divs.l	d0,d2
				;move.l	d2,dst
				;asr.l	#7,d2
				;asr.l	#2,d2

				lsr.l	#4,d2
				mulu.w	OneOverN(pc,d0.w*2),d2	;
				lsr.l	#8,d2

				move.l	d2,dst
				asr.l	#7,d2
				asr.l	#2,d2

; addq #5,d2
; add.w lighttype,d2

				moveq	#0,d1
				moveq	#0,d3
				move.w	leftbrighttab-leftsidetab(a4),d1
				add.w	d2,d1
				bge.s	.okbl
				moveq	#0,d1
.okbl:
; asr.w #1,d1
				cmp.w	#30,d1
				ble.s	.okdl
				move.w	#30,d1
.okdl:

				move.w	rightbrighttab-leftsidetab(a4),d3
				add.w	d2,d3
				bge.s	.okbr
				moveq	#0,d3
.okbr:
; asr.w #1,d3
				cmp.w	#30,d3
				ble.s	.okdr
				move.w	#30,d3
.okdr:

				sub.w	d1,d3
				asl.w	#8,d1
				move.w	d1,leftbright
				swap	d3
				tst.l	d3
				bgt.s	.OKITSPOSALREADY
				neg.l	d3
				asr.l	#6,d3
				divs	d5,d3
				neg.w	d3
				bra.s	.OKNOWITSNEG

.OKITSPOSALREADY
				asr.l	#6,d3
				divs	d5,d3
.OKNOWITSNEG
				muls	d3,d6
				add.w	#256*4,d6
				asr.w	#2,d6
				clr.b	d6
				add.w	leftbright,d6
				bge.s	.oklbnn
				moveq	#0,d6
.oklbnn:
				move.w	d6,leftbright

				ext.l	d3
				asr.l	#2,d3
; swap d3
; asl.w #8,d3
				move.w	d3,brightspd

				move.l	a6,a3
				movem.l	d0/d7/a2/a4/a5/a6,-(a7)
				move.l	dst,d0
				move.l	TexturePal,a1
				add.l	#256*32,a1
				move.l	floortile,a0
				adda.w	whichtile,a0
				jsr		pastfloorbright
				movem.l	(a7)+,d0/d7/a2/a4/a5/a6
nodrawlineGOUR

				sub.w	#1,disttobot

				move.w	linedir(pc),d3
				adda.w	d3,a6
; ext.l d3
; sub.l d3,REFPTR
				move.w	tonextline,d3
				add.w	d3,a4
				asr.w	#1,d3
				add.w	d3,d0
				subq	#1,d7
				bgt		dofloorGOUR

predontdrawfloorGOUR
				move.l	(a7)+,a0

dontdrawfloorGOUR:

				rts

REFPTR:			dc.l	0


; Gouraud floor line drawing

dofloornoclipGOUR:
; move.w (a2)+,d0
				move.w	rightsidetab-leftsidetab(a4),d2
				addq	#1,d2
				move.w	(a4),d1
				move.w	d1,leftedge
				move.w	d2,rightedge

				sub.w	d1,d2

				move.l	a2,d6

;				asl.l	#2,d6
;				ext.l	d0
;				divs.l	d0,d6

				asr.l	#4,d6
				mulu.w	OneOverN(pc,d0.w*2),d6
				asr.l	#8,d6	; from n << 20 down to n << 8

				move.l	d6,d5
				asr.l	#7,d5
				asr.l	#2,d5
; addq #5,d5
; add.w lighttype,d5

				moveq	#0,d1
				moveq	#0,d3
				move.w	leftbrighttab-leftsidetab(a4),d1
				add.w	d5,d1
				bge.s	.okbl
				moveq	#0,d1
.okbl:
; asr.w #1,d1
				cmp.w	#30,d1
				ble.s	.okdl
				move.w	#30,d1
.okdl:

				move.w	rightbrighttab-leftsidetab(a4),d3
				add.w	d5,d3
				bge.s	.okbr
				moveq	#0,d3
.okbr:
; asr.w #1,d3
				cmp.w	#30,d3
				ble.s	.okdr
				move.w	#30,d3
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

				sub.w	d1,d3
				asl.w	#8,d1
				move.w	d1,leftbright
				swap	d3
				ext.l	d2
				divs.l	d2,d3
				asr.l	#8,d3
				move.w	d3,brightspd

				move.l	a6,a3
				movem.l	d0/d7/a2/a4/a5/a6,-(a7)
				move.l	d6,d0
				move.l	d0,dst
				move.l	TexturePal,a1
				add.l	#256*32,a1
				move.l	floortile,a0
				adda.w	whichtile,a0
				jsr		pastfloorbright
				movem.l	(a7)+,d0/d7/a2/a4/a5/a6
				sub.w	#1,disttobot

				move.w	linedir(pc),d3
				adda.w	d3,a6
; ext.l d3
; sub.l d3,REFPTR

				move.w	tonextline,d3
				add.w	d3,a4
				asr.w	#1,d3
				add.w	d3,d0
				subq	#1,d7
				bgt		dofloornoclipGOUR

				bra		predontdrawfloorGOUR



dists:
; incbin "floordists"
drawit:			dc.w	0

				align 4
LineToUse:		dc.l	0

***************************
* Right then, time for the floor
* routine...
* For test purposes, give it
* a3 = point to screen
* d0= z distance away
* and sinval+cosval must be set up.
***************************

;BLACKFLOOR:
;				moveq	#0,d0
;				bra.s	DOBLACK

;SimpleFloorLine:
;
;				CACHE_OFF d2
;
;				move.l	#doacrossline,a1
;				move.w	leftedge(pc),d1
;				move.w	rightedge(pc),d3
;				sub.w	d1,d3
;				lea		(a1,d1.w*4),a1
;				move.w	(a1,d3.w*4),d4
;				move.w	#$4e75,(a1,d3.w*4)
;
;				tst.b	CLRNOFLOOR
;				bne.s	BLACKFLOOR
;
;				move.l	#PLAINSCALE,a2
;
;				move.w	d0,d2
;				move.w	lighttype,d1
;				asr.w	#8,d2
;				add.w	#5,d1
;				add.w	d2,d1
;				bge.s	.fixedbright
;				moveq	#0,d1
;.fixedbright:
;				cmp.w	#28,d1
;				ble.s	.smallbright
;				move.w	#28,d1
;.smallbright:
;				lea		(a2,d1.w*2),a2
;
;				move.w	whichtile,d0
;				move.w	d0,d1
;				and.w	#$3,d1
;				and.w	#$300,d0
;				lsl.b	#6,d1
;				move.b	d1,d0
;				move.w	d0,tstwhich
;				move.w	(a2,d0.w),d0
;
;DOBLACK:
;				jsr		(a1)
;				move.w	d4,(a1,d3.w*4)
;
;				;CACHE_ON d2
;
;				rts

tstwhich:		dc.w	0
whichtile:		dc.w	0

PLAINSCALE:
;incbin "includes/plainscale"

storeit:		dc.l	0

doacrossline:
val				SET		0
				REPT	32
				move.w	d0,val(a3)
val				SET		val+4
				ENDR
val				SET		val+4
				REPT	32
				move.w	d0,val(a3)
val				SET		val+4
				ENDR
val				SET		val+4
				REPT	32
				move.w	d0,val(a3)
val				SET		val+4
				ENDR
				rts


leftedge:		dc.w	0
rightedge:		dc.w	0

;rndpt:			dc.l	rndtab


dst:			dc.l	0

********************************************************************************
				; Draw one floor line
FloorLine:

				move.l	floortile,a0
				adda.w	whichtile,a0
				move.w	lighttype,d1
				move.l	d0,dst					; View2FloorDist*64 * 256 / firstline
				move.l	d0,d2					;
				********************
* Old version
				asr.l	#2,d2
				asr.l	#8,d2					; View2FloorDist / 1024

				add.w	#5,d1					; add 5 to lighttype?!
*********************
; asr.w #3,d2
; sub.w #4,d2
; cmp.w #6,d2
; blt.s flbrbr
; move.w #6,d2
;flbrbr:
*********************
				add.w	d2,d1					; clamp lighting on the line
				bge.s	.fixedbright
				moveq	#0,d1					; low clamp
.fixedbright:
				cmp.w	#28,d1
				ble.s	.smallbright
				move.w	#28,d1					; high clamp
.smallbright:
				move.l	TexturePal,a1
				add.l	#256*32,a1
				add.l	floorbright(pc,d1.w*4),a1 ; adjust brightness of line
				bra		pastfloorbright

ConstCol:		dc.w	0

BumpLine:
				tst.b	smoothbumps
				beq.s	Chunky

				move.l	#SmoothTile,a0
				lea		Smoothscalecols,a1
				bra		pastast

Chunky:
				moveq	#0,d2
				move.l	#Bumptile,a0
				move.w	whichtile,d2
				adda.w	d2,a0
				ror.l	#2,d2
				lsr.w	#6,d2
				rol.l	#2,d2
				and.w	#15,d2
				move.l	#ConstCols,a1
				move.w	(a1,d2.w*2),ConstCol
				lea		Bumpscalecols,a1

pastast:
				move.w	lighttype,d1

				move.l	d0,dst

				move.l	d0,d2
*********************
* Old version
				asr.l	#2,d2
				asr.l	#8,d2
				add.w	#5,d1
*********************
; asr.w #3,d2
; sub.w #4,d2
; cmp.w #6,d2
; blt.s flbrbr
; move.w #6,d2
;flbrbr:
*********************
				add.w	d2,d1
				bge.s	.fixedbright
				moveq	#0,d1
.fixedbright:
				cmp.w	#31,d1
				ble.s	.smallbright
				move.w	#31,d1
.smallbright:
				add.l	floorbright(pc,d1.w*4),a1
				bra		pastfloorbright


floorbright:
				dc.l	512*0
				dc.l	512*1
				dc.l	512*2
				dc.l	512*3
				dc.l	512*4

				dc.l	512*5
				dc.l	512*6
				dc.l	512*7
				dc.l	512*8
				dc.l	512*9

				dc.l	512*10
				dc.l	512*11
				dc.l	512*12
				dc.l	512*13
				dc.l	512*14

				dc.l	512*15
				dc.l	512*16
				dc.l	512*17
				dc.l	512*18
				dc.l	512*19

				dc.l	512*20
				dc.l	512*21
				dc.l	512*22
				dc.l	512*23
				dc.l	512*24

				dc.l	512*25
				dc.l	512*26
				dc.l	512*27
				dc.l	512*28
				dc.l	512*29

				dc.l	512*30
				dc.l	512*31

widthleft:		dc.w	0
scaleval:		dc.w	0
sxoff:			dc.l	0						; viewer position in floor texture space?
szoff:			dc.l	0
xoff34:			dc.w	0
zoff34:			dc.w	0
scosval:		dc.w	0
ssinval:		dc.w	0

			; Floor drawing
pastfloorbright:

				; these directly determine the texture gradients
				; as function of the player view direction
				; d0 = distance of line to viewer along Z axis
				move.l	d0,d1					; distance of line to viewer along Z axis
				muls	cosval,d1				; cos * dist
				move.l	d0,d2
				muls	sinval,d2				;
				neg.l	d2						; -sin * width
				asr.l	#2,d2
				asr.l	#2,d1

scaleprog:
				move.w	scaleval(pc),d3
				beq.s	.samescale
				bgt.s	.scaledown
				; scale up
				neg.w	d3
				asr.l	d3,d1
				asr.l	d3,d2
				bra.s	.samescale
.scaledown:
				asl.l	d3,d1					; cos * dist * scale	step size of line through texture at distance 'dist'
				asl.l	d3,d2					; -sin * dist * scale


				; view vector R * (-ViewDist*.75 , ViewDist)^T
				; I think the 0.75 related to the field of view
				; It is supposed to produce left left start coordinate
				; of the line in floor texture coordinates
.samescale
				move.l	d1,d3					; dist * cos * scale
				move.l	d3,d6					; dist * cos * scale
				move.l	d3,d5					; dist * cos * scale
				asr.l	#1,d6					; dist * cos * scale * 0.5
				add.l	d6,d3					; dist * cos * scale * 1.5
				asr.l	#1,d3					; dist * cos * scale * 0.75

				move.l	d2,d4					; -dist * sin * scale
				move.l	d4,d6					; -dist * sin * scale
				asr.l	#1,d6					; -dist * sin * scale * 0.5
				add.l	d4,d6					; -dist * sin * scale * 1.5
				asr.l	#1,d6					; -dist * sin * scale * 0.75

				add.l	d3,d4					; left t = (dist * cos * scale * 0.75) - (dist * sin * scale)
				neg.l	d4						; - start x

				sub.l	d6,d5					; left s= -1 * -1 * (dist * sin * scale * 0.75) + (dist * cos * scale)

				add.l	sxoff,d4				; d4/d5 is the texture starting position?
				add.l	szoff,d5

				tst.b	Vid_FullScreen_b
				beq.s	.nob

				moveq	#0,d6
				move.w	leftedge(pc),d6			; left edge of clipped floor line in screenspace
				beq.s	.nomultleftB

				; if the clipped left edge of the floor line is > 0,
				; need  to inset the start of the floorspace coordinate accordingly

				; 0xABADCAFE - Apply fullscreen multiplier (3/5)), approximating as 1229/2048
				muls	#1229,d6
				asr.l	#8,d6
				asr.l	#3,d6

				move.l	d1,a4					; save width * cos * scale
				move.l	d2,a5					; save width * sin * scale

				muls.l	d6,d1					; ds/dx  * left start
				asr.l	#7,d1					; sin/cos are << 15; this shifts it down to << 8
				add.l	d1,d4					; current floor line start texel s

				muls.l	d6,d2					; dt/dx * left start
				asr.l	#7,d2					; sin/cos are << 15; this shifts it down to << 8
				add.l	d2,d5					; current floor line start texel t

				move.l	a4,d1					; restore
				move.l	a5,d2

				move.w	leftedge(pc),d6

.nomultleftB:

				move.w	d4,startsmoothx
				move.w	d5,startsmoothz

				asr.l	#8,d4
				asl.l	#8,d5
; add.w szoff,d5
; add.w sxoff,d4
; and.w #63,d4
; and.w #63*256,d5

				move.w	d4,d5

				; multiply floor space step ds/dx and dt/dx by Fullscreen multiplier
				asr.l	#6,d1					; don't shift by 7, but 6, to achieve 2/3
				asr.l	#6,d2

				; 0xABADCAFE - Apply fullscreen multiplier (uses 3/5 here)
				; Pipper's fullscreen: Scale factor is 192/320
				; Use quicker evaluation of 3/10, 77/256 => 0.30078125
				muls.l  #77,d1
				muls.l  #77,d2
				asr.l	#8,d1
				asr.l	#8,d2

				bra.s	doneallmult

.nob			;		smallscreen				left edge insetting
				moveq	#0,d6
				move.w	leftedge(pc),d6
				beq.s	nomultleft				; skip if at left screen edge already

				move.l	d1,a4					; save  width * cos * scale
				move.l	d2,a5					; save width * sin * scale

				muls.l	d6,d1					; left start * ds/dx
				asr.l	#7,d1
				add.l	d1,d4					; start texel x

				muls.l	d6,d2					; left start * dt/dx
				asr.l	#7,d2
				add.l	d2,d5					; start texel y

				move.l	a4,d1					; restore
				move.l	a5,d2					; restore

				move.w	leftedge(pc),d6

nomultleft:		;		final					start coordinate in floor texture space
				move.w	d4,startsmoothx
				move.w	d5,startsmoothz

				asr.l	#8,d4					;  s / 256
				asl.l	#8,d5					;  t * 256

; add.w szoff,d5
; add.w sxoff,d4
; and.w #63,d4
; and.w #63*256,d5

				move.w	d4,d5					; move s into lower half of t

				asr.l	#7,d1					; ds/dx / 128 = ds/dx << 8
				asr.l	#7,d2					; dt/dx / 128 = dt/dx << 8
; divs.l #3,d1
; divs.l #3,d2

doneallmult:

				move.w	d1,a4					; save ds/dx and dt/dx
				move.w	d2,a5

				asl.l	#8,d2					;  dt/dx << 16
; and.w #%0011111100000000,d2
				asr.l	#8,d1					;  ds/dx
				move.w	d1,d2					;  move ds/dx into lower half of dt/dx

				move.l	#$3fff3fff,d1
				and.l	d1,d5
; swap d5
; move.w startsmoothz,d5
; swap d5
; swap d2
; move.w a5,d2
; swap d2

***********************************


				;tst.b	DOUBLEWIDTH
				;beq.s	.nodoub
				bra.s	.nodoub

				; old doublewidth rendering
				and.b	#$fe,d6					; remove LSB in lower 8 bit, only draw even columns?

				move.w	d6,a2
				moveq	#0,d0
				move.w	rightedge(pc),d3
				lea		(a3,a2.w),a3
				move.w	d3,d7
				sub.w	a2,d7
				asr.w	#1,d7
				move.w	startsmoothx,d3

				tst.b	usewater
				bne		texturedwaterDOUB
		; tst.b gourfloor
				bra		gouraudfloorDOUB

.nodoub:
				move.w	d6,a2					; left start X
				moveq	#0,d0
				move.w	rightedge(pc),d3
				lea		(a3,a2.w),a3			; start adress in screen
				move.w	d3,d7
				sub.w	a2,d7					; end X - start X : line width

intofirststrip:
allintofirst:

				move.w	startsmoothx,d3

tstwat:

				tst.b	usewater
				bne		texturedwater
; tst.b gourfloor						; FIXME: this effectively disables bumpmapped floors...
										; opportunity to reenable and see what happens
				bra		gouraudfloor



******************************
* BumpMap the floor/ceiling! *
				tst.b	usebumps
				bne.s	BumpMap
******************************

ordinary:
				moveq	#0,d0

				dbra	d7,acrossscrn
				rts

usebumps:		dc.w	$0
smoothbumps:	dc.w	$0
gourfloor:		dc.w	0

				include	"bumpmap.s"

				CNOP	0,4
backbefore:
				and.w	d1,d5
				move.b	(a0,d5.w*4),d0
				add.w	a4,d3
				addx.l	d6,d5
				move.w	(a1,d0.w*2),(a3)
				addq	#4,a3
				dbcs	d7,acrossscrn
				dbcc	d7,backbefore
				bra.s	past1

acrossscrn:
				and.w	d1,d5
				move.b	(a0,d5.w*4),d0
				add.w	a4,d3
				addx.l	d2,d5
				move.w	(a1,d0.w*2),(a3)
				addq	#4,a3
				dbcs	d7,acrossscrn
				dbcc	d7,backbefore
past1:
				bcc.s	gotoacross

				move.w	d4,d7
				bne.s	.notdoneyet
				rts
.notdoneyet:

				cmp.w	#32,d7
				ble.s	.notoowide
				move.w	#32,d7
.notoowide
				sub.w	d7,d4
				addq	#4,a3

				dbra	d7,backbefore
				rts


gotoacross:

				move.w	d4,d7
				bne.s	.notdoneyet
				rts
.notdoneyet:

				cmp.w	#32,d7
				ble.s	.notoowide
				move.w	#32,d7
.notoowide
				sub.w	d7,d4
				addq	#4,a3

				dbra	d7,acrossscrn
				rts

leftbright:		dc.l	0
brightspd:		dc.l	0

gouraudfloor:
				move.w	leftbright,d0
				move.l	d1,d4
				move.w	brightspd,d1

				move.w	d7,d3
				asr.w	#1,d7
				btst	#0,d3
				beq.s	.nosingle1

				move.w	d5,d3					; d3 = S
				move.l	d5,d6
				lsr.w	#8,d3
				swap	d6						; d6 = T
				move.b	d3,d6					; T * 256 + S

				move.w	d0,d3					; line X

				move.b	(a0,d6.w*4),d3			; fetch floor texel; but why d6*4?

				add.w	d1,d0					;
				add.l	d2,d5
				and.l	d4,d5
				move.b	(a1,d3.w),(a3)+			; map through palette and write to renderbuffer

.nosingle1
				move.w	d7,d3
				asr.w	#1,d7
				btst	#0,d3
				beq.s	.nosingle2
				move.w	d5,d3
				move.l	d5,d6
				lsr.w	#8,d3
				swap	d6
				move.b	d3,d6
				move.w	d0,d3
				move.b	(a0,d6.w*4),d3
				add.w	d1,d0
				add.l	d2,d5
				and.l	d4,d5
				move.l	d5,d6
				swap	d6
				move.b	(a1,d3.w),(a3)+
				move.w	d5,d3
				lsr.w	#8,d3
				move.b	d3,d6
				move.w	d0,d3
				move.b	(a0,d6.w*4),d3
				add.w	d1,d0
				add.l	d2,d5
				and.l	d4,d5
				move.b	(a1,d3.w),(a3)+

.nosingle2

				move.l	d5,d6
				swap	d6

				dbra	d7,acrossscrngour
				rts

				CNOP	0,4

acrossscrngour:
				move.w	d5,d3
				lsr.w	#8,d3
				move.b	d3,d6
				move.w	d0,d3
				move.b	(a0,d6.w*4),d3
				add.w	d1,d0
				add.l	d2,d5
				and.l	d4,d5
				move.l	d5,d6
				swap	d6
				move.b	(a1,d3.w),(a3)+
				move.w	d5,d3
				lsr.w	#8,d3
				move.b	d3,d6
				move.w	d0,d3
				move.b	(a0,d6.w*4),d3
				add.w	d1,d0
				add.l	d2,d5
				and.l	d4,d5
				move.l	d5,d6
				swap	d6
				move.b	(a1,d3.w),(a3)+
				move.w	d5,d3
				lsr.w	#8,d3
				move.b	d3,d6
				move.w	d0,d3
				move.b	(a0,d6.w*4),d3
				add.w	d1,d0
				add.l	d2,d5
				and.l	d4,d5
				move.l	d5,d6
				swap	d6
				move.b	(a1,d3.w),(a3)+
				move.w	d5,d3
				lsr.w	#8,d3
				move.b	d3,d6
				move.w	d0,d3
				move.b	(a0,d6.w*4),d3
				add.w	d1,d0
				add.l	d2,d5
				and.l	d4,d5
				move.l	d5,d6
				swap	d6
				move.b	(a1,d3.w),(a3)+
				dbra	d7,acrossscrngour

				rts


gouraudfloorDOUB:
				move.w	leftbright,d0
				move.l	d1,d4
				move.w	brightspd,d1
				add.w	d1,d1
				add.l	d2,d2

				move.w	d7,d3
				asr.w	#1,d7
				btst	#0,d3
				beq.s	.nosingle1
				move.w	d5,d3
				move.l	d5,d6
				lsr.w	#8,d3
				swap	d6
				move.b	d3,d6
				move.w	d0,d3
				move.b	(a0,d6.w*4),d3
				add.w	d1,d0
				add.l	d2,d5
				and.l	d4,d5
				move.w	(a1,d3.w),(a3)+

.nosingle1
				move.w	d7,d3
				asr.w	#1,d7
				btst	#0,d3
				beq.s	.nosingle2
				move.w	d5,d3
				move.l	d5,d6
				lsr.w	#8,d3
				swap	d6
				move.b	d3,d6
				move.w	d0,d3
				move.b	(a0,d6.w*4),d3
				add.w	d1,d0
				add.l	d2,d5
				and.l	d4,d5
				move.l	d5,d6
				swap	d6
				move.w	(a1,d3.w),(a3)+
				move.w	d5,d3
				lsr.w	#8,d3
				move.b	d3,d6
				move.w	d0,d3
				move.b	(a0,d6.w*4),d3
				add.w	d1,d0
				add.l	d2,d5
				and.l	d4,d5
				move.w	(a1,d3.w),(a3)+

.nosingle2
				move.l	d5,d6
				swap	d6
				dbra	d7,acrossscrngourD
				rts

				CNOP	0,4
acrossscrngourD:
				move.w	d5,d3
				lsr.w	#8,d3
				move.b	d3,d6
				move.w	d0,d3
				move.b	(a0,d6.w*4),d3
				add.w	d1,d0
				add.l	d2,d5
				and.l	d4,d5
				move.l	d5,d6
				swap	d6
				move.w	(a1,d3.w),(a3)+
				move.w	d5,d3
				lsr.w	#8,d3
				move.b	d3,d6
				move.w	d0,d3
				move.b	(a0,d6.w*4),d3
				add.w	d1,d0
				add.l	d2,d5
				and.l	d4,d5
				move.l	d5,d6
				swap	d6
				move.w	(a1,d3.w),(a3)+
				move.w	d5,d3
				lsr.w	#8,d3
				move.b	d3,d6
				move.w	d0,d3
				move.b	(a0,d6.w*4),d3
				add.w	d1,d0
				add.l	d2,d5
				and.l	d4,d5
				move.l	d5,d6
				swap	d6
				move.w	(a1,d3.w),(a3)+
				move.w	d5,d3
				lsr.w	#8,d3
				move.b	d3,d6
				move.w	d0,d3
				move.b	(a0,d6.w*4),d3
				add.w	d1,d0
				add.l	d2,d5
				and.l	d4,d5
				move.l	d5,d6
				swap	d6
				move.w	(a1,d3.w),(a3)+
				dbra	d7,acrossscrngourD
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

				move.w	d4,d7
				bne.s	.notdoneyet
				move.l	d0,leftbright

				rts
.notdoneyet:

				cmp.w	#32,d7
				ble.s	.notoowide
				move.w	#32,d7
.notoowide
				sub.w	d7,d4
				addq	#4,a3

; dbra d7,backbeforegour
				rts


gotoacrossgour:

				move.w	d4,d7
				bne.s	.notdoneyet
				rts
.notdoneyet:

				cmp.w	#32,d7
				ble.s	.notoowide
				move.w	#32,d7
.notoowide
				sub.w	d7,d4
				addq	#4,a3

				dbra	d7,acrossscrngour
				rts


waterpt:		dc.l	waterlist

waterlist:
				dc.l	waterfile
				dc.l	waterfile+2
				dc.l	waterfile+256
				dc.l	waterfile+256+2
				dc.l	waterfile+512
				dc.l	waterfile+512+2
				dc.l	waterfile+768
				dc.l	waterfile+768+2
; dc.l waterfile+768
; dc.l waterfile+512+2
; dc.l waterfile+512
; dc.l waterfile+256+2
; dc.l waterfile+256
; dc.l waterfile+2
endwaterlist:

watertouse:		dc.l	waterfile

wtan:			dc.w	0
wateroff:		dc.l	0

REFLECTIONWATER:

				move.l	d1,d4

				add.l	wateroff,d5

				move.l	TexturePal,a1
				add.l	#256*16,a1
				move.l	dst,d0
				clr.b	d0

				add.w	d0,d0
				cmp.w	#12*512,d0
				blt.s	.notoowater
				move.w	#12*512,d0

.notoowater:

				adda.w	d0,a1

				move.l	dst,d0
				asl.w	#7,d0
				add.w	wtan,d0
				and.w	#8191,d0
				move.l	#SineTable,a0
				move.w	(a0,d0.w),d0
				ext.l	d0

				move.l	dst,d3
				add.w	#300,d3
				divs	d3,d0
				asr.w	#5,d0
				addq	#4,d0
				cmp.w	disttobot,d0
				blt.s	oknotoffbotototr

				move.w	disttobot,d0
				subq	#1,d0

oknotoffbotototr

; move.w dst,d3
; asr.w #7,d3
; add.w d3,d0

				muls	#SCREENWIDTH,d0
				tst.w	above
				beq.s	nonnnnnegr
				neg.l	d0

nonnnnnegr:

				move.l	d0,a6

				move.l	watertouse,a0

; move.l #mixtab,a5

				moveq	#0,d1

				move.w	startsmoothx,d3
				dbra	d7,acrossscrnwr
				rts

backbeforewr:
				and.w	d1,d5
				move.w	(a0,d5.w*4),d0
				move.b	(a3,a6.w),d0
				move.w	(a1,d0.w),(a3)+
				add.w	a4,d3
				addx.l	d6,d5
				dbcs	d7,acrossscrnwr
				dbcc	d7,backbeforewr
				rts

acrossscrnwr:
				move.w	d5,d3
				move.l	d5,d6
				lsr.w	#8,d3
				swap	d6
				move.b	d3,d6
				move.w	(a0,d6.w*4),d0
				add.l	d2,d5
				move.w	(a4,a6.w),d1
				addq	#2,a4
				move.b	(a3,a6.w),d1
				move.b	(a5,d1.l),d0
				and.l	d4,d5
				move.w	(a1,d0.w),(a3)+
				dbra	d7,acrossscrnwr
				rts

texturedwater:

				move.l	d1,d4

				add.l	wateroff,d5

				move.l	TexturePal,a1
				add.l	#256*16,a1
				move.l	dst,d0
				asr.l	#2,d0
				clr.b	d0

				add.w	d0,d0
				cmp.w	#9*512,d0
				blt.s	.notoowater
				move.w	#9*512,d0
.notoowater:

				adda.w	d0,a1

				move.l	dst,d0
				asl.w	#7,d0
				add.w	wtan,d0
				and.w	#8191,d0
				move.l	#SineTable,a0
				move.w	(a0,d0.w),d0
				ext.l	d0

				move.l	dst,d3
				add.w	#300,d3
				divs	d3,d0
				asr.w	#5,d0
				addq	#4,d0
				cmp.w	disttobot,d0
				blt.s	oknotoffbototot

				move.w	disttobot,d0
				subq	#1,d0

oknotoffbototot

; move.w dst,d3
; asr.w #7,d3
; add.w d3,d0

				tst.b	DOUBLEHEIGHT
				beq.s	.nodoub
				and.b	#$fe,d0
.nodoub:

				muls	#SCREENWIDTH,d0
				tst.w	above
				beq.s	nonnnnneg
				neg.l	d0

nonnnnneg:

				move.l	d0,a6

				move.l	watertouse,a0

				move.w	startsmoothx,d3
				dbra	d7,acrossscrnw
				rts

backbeforew:
				and.w	d1,d5
				move.w	(a0,d5.w*4),d0
				add.w	d0,d0
				move.b	(a3,a6.w),d0
				move.b	(a1,d0.w),(a3)+
				add.w	a4,d3
				addx.l	d6,d5
				dbcs	d7,acrossscrnw
				dbcc	d7,backbeforew
				rts

acrossscrnw:
				move.w	d5,d3
				move.l	d5,d6
				lsr.w	#8,d3
				swap	d6
				move.b	d3,d6
				move.w	(a0,d6.w*4),d0
				add.w	d0,d0
				add.l	d2,d5
				move.b	(a3,a6.w),d0
				and.l	d4,d5
				move.b	(a1,d0.w),(a3)+
				dbra	d7,acrossscrnw
				rts


texturedwaterDOUB:

				move.l	d1,d4

				add.l	wateroff,d5

				move.l	TexturePal,a1
				add.l	#256*16,a1
				move.l	dst,d0
				asr.l	#2,d0
				clr.b	d0

				add.w	d0,d0
				cmp.w	#9*512,d0
				blt.s	.notoowater
				move.w	#9*512,d0
.notoowater:

				adda.w	d0,a1

				move.l	dst,d0
				asl.w	#7,d0
				add.w	wtan,d0
				and.w	#8191,d0
				move.l	#SineTable,a0
				move.w	(a0,d0.w),d0
				ext.l	d0

				move.l	dst,d3
				add.w	#300,d3
				divs	d3,d0
				asr.w	#5,d0
				addq	#4,d0
				cmp.w	disttobot,d0
				blt.s	.oknotoffbototot

				move.w	disttobot,d0
				subq	#1,d0

.oknotoffbototot

; move.w dst,d3
; asr.w #7,d3
; add.w d3,d0

				tst.b	DOUBLEHEIGHT
				beq.s	.nodoub
				and.b	#$fe,d0
.nodoub:

				muls	#SCREENWIDTH,d0
				tst.w	above
				beq.s	.nonnnnneg
				neg.l	d0

.nonnnnneg:

				move.l	d0,a6

				move.l	watertouse,a0

				add.l	d2,d2

				move.w	startsmoothx,d3
				dbra	d7,acrossscrnwD
				rts


acrossscrnwD:
				move.w	d5,d3
				move.l	d5,d6
				lsr.w	#8,d3
				swap	d6
				move.b	d3,d6
				move.w	(a0,d6.w*4),d0
				add.w	d0,d0
				add.l	d2,d5
				move.b	(a3,a6.w),d0
				and.l	d4,d5
				move.w	(a1,d0.w),(a3)+
				dbra	d7,acrossscrnwD
				rts


usewater:		dc.w	0
				dc.w	0
startsmoothx:	dc.w	0
				dc.w	0
startsmoothz:	dc.w	0

********************************
*
				include	"objdrawhires.s"
*
********************************

numframes:
				dc.w	0

alframe:		dc.l	0

alan:
				dcb.l	8,0
				dcb.l	8,1
				dcb.l	8,2
				dcb.l	8,3
endalan:

alanptr:		dc.l	alan

Time2:			dc.l	0
dispco:
				dc.w	0


key_readkey:
				moveq	#0,d0
				move.b	lastpressed,d0
				move.b	#0,lastpressed
				rts

key_interrupt:
;		movem.l	d0-d7/a0-a6,-(sp)

;		move.w	INTREQR,d0
;		btst	#3,d0
;		beq	.not_key

				move.b	$bfdd00,d0
				btst	#0,d0
				bne		.key_cont
;		move.b	$bfed01,d0
;		btst	#0,d0
;		bne	.key_cont

;		btst	#3,d0
;		beq	.key_cont

				move.b	$bfec01,d0
				clr.b	$bfec01

				tst.b	d0
				beq		.key_cont

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
.not_key:		;lea.l	$dff000,a5

;		lea.l	_keypressed(pc),a0
;		move.b	101(a0),d0	;read LALT
;		or.b	102(a0),d0	;blend it with RALT
;		move.b	d0,127(a0)	;save in combined position

;		movem.l	(sp)+,d0-d7/a0-a6
				move.w	#0,d0
				tst.w	d0

				rts

lastpressed:	dc.b	0
KInt_CCode		ds.b	1
KInt_Askey		ds.b	1
KInt_OCode		ds.w	1


OldSpace:		dc.b	0
SpaceTapped:	dc.b	0
PLR1_SPCTAP:	dc.b	0
PLR2_SPCTAP:	dc.b	0
				even

				include	"plr1control.s"
				include	"plr2control.s"
				include	"fall.s"

*******************************************8

nullmessage:	dcb.b	160,' '

SENDMESSAGENORET
				move.l	a1,-(a7)
				bra		intosend

SENDMESSAGE:

				move.l	a1,-(a7)

				move.l	MESSPTR,a1
				move.l	d0,(a1)+
				cmp.l	#ENDMESSBUFF,a1
				blt.s	.okinbuff
				move.l	#MESSAGEBUFFER,a1
.okinbuff:
				move.l	a1,MESSPTR
				move.l	a1,LASTMESSPTR

intosend:

				move.l	d0,SCROLLPOINTER
				move.w	#0,SCROLLXPOS
				add.l	#160,d0
				move.l	d0,ENDSCROLL
				move.w	#40,SCROLLTIMER

				move.l	(a7)+,a1
				rts

RETRIEVEPREVMESSAGE:

				move.l	LASTMESSPTR,a1
				cmp.l	#MESSAGEBUFFER,a1
				bgt.s	.okinbuff

				move.l	#ENDMESSBUFF,a1

.okinbuff:

				move.l	-(a1),d0
				beq.s	.nomessage

				move.l	d0,SCROLLPOINTER
				move.w	#0,SCROLLXPOS
				add.l	#160,d0
				move.l	d0,ENDSCROLL
				move.w	#40,SCROLLTIMER

				move.l	a1,LASTMESSPTR

.nomessage:


				rts

MESSAGEBUFFER:
				ds.l	20
ENDMESSBUFF:

MESSPTR:		dc.l	MESSAGEBUFFER
LASTMESSPTR:	dc.l	MESSAGEBUFFER

**********************************************



;prot7: dc.w 0

GOTTOSEND:		dc.w	0

COUNTER:		dc.w	0
COUNTER2:		dc.w	0
COUNTSPACE:		ds.b	160

VBLCOUNT:		dc.l	0
VBLCOUNTLAST:		dc.l	0
FPSLIMITER		dc.l	0

OtherInter:
				move.w	#$0010,$dff000+intreq
				movem.l	d0-d7/a0-a6,-(a7)
				bra		justshake

				cnop	0,4

; Main VBlank interrupt
VBlankInterrupt:
				add.l	#1,counter
				add.l	#1,main_counter
				add.l	#1,VBLCOUNT
				subq.w	#1,animtimer

				tst.l	timer					; used by menu system as delay
				beq.s	.nodec
				subq.l	#1,timer
.nodec:
				SAVEREGS
				bsr.s	.routine

				move.l	main_vblint,d0
				beq.s	.noint
				move.l	d0,a0
				jsr		(a0)
.noint:
				GETREGS
				lea		_custom,a0				; place custom base into a0 (See autodocs for AddIntServer)
				moveq	#0,d0					; VERTB interrupt needs to return Z flag set

				rts
.routine
;FIXME:  Wait, does the whole game run as part of the VBLank (formerly copper interrupt)?
				tst.b	doanything
				bne		dosomething

				movem.l	d0-d7/a0-a6,-(a7)
				bra		JUSTSOUNDS

				moveq	#0,d0					; VERTB interrupt needs to return Z flag set
				rts

tabheld:		dc.w	0
ObjWork:		ds.l	600
WORKPTR:		dc.l	0
thistime:		dc.w	0

DOALLANIMS:
				sub.b	#1,thistime
				ble.s	.okdosome
				rts

.okdosome:
				move.b	#5,thistime
				move.l	#ObjWork,a5
				move.l	Lvl_ObjectDataPtr_l,a0

Objectloop2:
				tst.w	(a0)
				blt		doneallobj2
				move.w	12(a0),d0
				blt		doneobj2
				move.w	d0,EntT_GraphicRoom_w(a0)
				tst.b	ShotT_Worry_b(a0)
				beq.s	doneobj2

				move.b	16(a0),d0
				cmp.b	#1,d0
				blt		JUMPALIENANIM
; beq JUMPOBJECTANIM
; cmp.b #2,d0
; beq JUMPBULLET

doneobj2:
				adda.w	#64,a0
				addq	#8,a5
				bra		Objectloop2

doneallobj2:
				rts

JUMPALIENANIM:

				moveq	#0,d0
				move.b	EntT_WhichAnim_b(a0),d0
; 0=walking
; 1=attacking
; 2=getting hit
; 3=dying

				cmp.b	#1,d0
				blt.s	ALWALK
				beq.s	ALATTACK

				cmp.b	#3,d0
				blt		ALGETHIT
				beq		ALDIE

				bra		doneobj2

ALDIE
				move.l	#10,d0
				bra		intowalk

ALGETHIT:
				move.l	#9,d0
				bra		intowalk

ALATTACK:
				move.l	#8,d0
				bra		intowalk

AUXOBJ:			dc.w	0

ALWALK:

; jsr ViewpointToDraw
; add.l d0,d0
;
; move.l GLF_DatabasePtr_l,a6
; add.l #GLFT_AlienDefs_l,a6
; moveq #0,d1
; move.b EntT_Type_b(a0),d1
; muls #AlienT_SizeOf_l,d1
; add.l d1,a6
; cmp.w #1,AlienT_GFXType_w(a6)
; bne.s NOSIDES2

				moveq	#0,d0
intowalk:

NOSIDES2:

				move.b	d0,2(a5)
				move.l	GLF_DatabasePtr_l,a6

				add.l	#GLFT_AlienAnims_l,a6

				moveq	#0,d1
				move.b	EntT_Type_b(a0),d1
				move.w	.valtables+4(pc,d1.w*8),d1
; muls #A_AnimLen,d1
				add.l	d1,a6

; move.l ANIMPOINTER,a6

; muls #A_OptLen,d0
				move.w	.valtables+2(pc,d0.w*8),d0
				add.w	d0,a6

				move.w	EntT_Timer2_w(a0),d1
				move.w	d1,d2
; muls #A_FrameLen,d1
				move.w	.valtables(pc,d1.w*8),d1

				moveq	#0,d0
				move.b	5(a6,d1.w),d0
				beq.s	.nosoundmake

				movem.l	d0-d7/a0-a6,-(a7)
				subq	#1,d0
				move.w	d0,Samplenum
				clr.b	notifplaying
				move.w	(a0),IDNUM
				move.w	#80,Noisevol
				move.l	#ObjRotated_vl,a1
				move.w	(a0),d0
				lea		(a1,d0.w*8),a1
				move.l	(a1),Noisex
				jsr		MakeSomeNoise
				movem.l	(a7)+,d0-d7/a0-a6
.nosoundmake

				move.b	6(a6,d1.w),d0
				beq.s	.noaction
				add.b	#1,(a5)
				move.b	d2,1(a5)
.noaction

				addq	#1,d2

				moveq	#0,d0
				move.b	7(a6,d1.w),d0
				beq		.nospecial
				bra		.special

.valtables:
val				SET		0
				REPT	20
				dc.w	A_FrameLen*val,A_OptLen*val
				dc.w	A_AnimLen*val,0
val				SET		val+1
				ENDR

.special
				move.b	d0,d3
				and.w	#63,d3
				lsr.w	#6,d0
				cmp.w	#2,d0
				blt.s	.storeval
				beq.s	.randval

				sub.b	#1,4(a5)
				beq.s	.nospecial

				move.w	d3,d2
				bra.s	.nospecial

.randval:
				jsr		GetRand
				divs	d3,d0
				swap	d0
				move.w	d0,d3

.storeval:
				move.b	d3,4(a5)
.nospecial:

; move.w d2,d3
				move.w	.valtables2(pc,d2.w*8),d3
; muls #A_FrameLen,d3
				tst.b	(a6,d3.w)
				bge.s	.noendanim
				st		3(a5)
				move.w	#0,d2
.noendanim
				move.w	d2,EntT_Timer2_w(a0)

				bra		doneobj2

.valtables2:
val				SET		0
				REPT	20
				dc.w	A_FrameLen*val,A_OptLen*val
				dc.w	A_AnimLen*val,0
val				SET		val+1
				ENDR


JUMPOBJECTANIM:
				bra		doneobj2

timetodamage:	dc.w	0
SAVESAVE:		dc.w	0

dosomething:
				addq.w	#1,FramesToDraw
				movem.l	d0-d7/a0-a6,-(a7)

				jsr		NARRATOR

				bsr		DOALLANIMS

				sub.w	#1,timetodamage
				bgt		.nodam

				move.w	#100,timetodamage

				move.l	Plr1_RoomPtr_l,a0
				move.l	ZoneT_Water_l(a0),d2      ; Water depth in d2
				move.w	ZoneT_FloorNoise_w(a0),d0
				tst.b	Plr1_StoodInTop_b
				beq.s	.okinbot
				move.w	ZoneT_UpperFloorNoise_w(a0),d0

.okinbot:
				; Issue #1 - Check we are on the floor or swimming before applying any floor damage.
				cmp.l	Plr1_SnapYOff_l,d2
				blt.b   .in_toxic_liquid1

				; Player not in liquid, check if on floor.
				move.l	Plr1_SnapTYOff_l,d1
				cmp.l	Plr1_SnapYOff_l,d1
				bgt.b	.not_on_floor1

.in_toxic_liquid1:
				move.l	GLF_DatabasePtr_l,a0
				add.l	#GLFT_FloorData_l,a0
				move.w	(a0,d0.w*4),d0			; floor damage.
				move.l	Plr1_ObjectPtr_l,a0
				add.b	d0,EntT_DamageTaken_b(a0)

.not_on_floor1:
				move.l	Plr2_RoomPtr_l,a0
				move.l	ZoneT_Water_l(a0),d2      ; Water depth in d2
				move.w	ZoneT_FloorNoise_w(a0),d0
				tst.b	Plr2_StoodInTop_b
				beq.s	.okinbot2
				move.w	ZoneT_UpperFloorNoise_w(a0),d0

.okinbot2:
				; Issue #1 - Check we are on the floor or swimming before applying any floor damage.
				cmp.l	Plr2_SnapYOff_l,d2
				blt.b   .in_toxic_liquid2

				; Player not in liquid, check if on floor.
				move.l	Plr2_SnapTYOff_l,d1
				cmp.l	Plr2_SnapYOff_l,d1
				bgt.b	.not_on_floor2

.in_toxic_liquid2:
				move.l	GLF_DatabasePtr_l,a0
				add.l	#GLFT_FloorData_l,a0
				move.w	(a0,d0.w*4),d0			; floor damage.
				move.l	Plr2_ObjectPtr_l,a0
				add.b	d0,EntT_DamageTaken_b(a0)

.not_on_floor2:
.nodam:
				move.l	#KeyMap,a5

				tst.b	82(a5)					;f3
				beq		notogglesound

				tst.b	lasttogsound
				bne		notogglesound2

				st		lasttogsound

				move.w	TOPPOPT,d0
				addq	#1,d0
				and.w	#3,d0
				move.w	d0,TOPPOPT
				move.b	STEROPT(pc,d0.w*2),STEREO


				move.b	STEROPT+1(pc,d0.w*2),d1
				muls	#160,d0
				add.l	#SOUNDOPTSTEXT,d0
				jsr		SENDMESSAGE


				move.b	d1,Prefsfile+1

				bra		pastster

				STEROPT:
				dc.b	0,4
				dc.b	$FF,4
				dc.b	0,8
				dc.b	$ff,8

lasttogsound:	dc.w	0

SOUNDOPTSTEXT:
;      1234567890123456789012345678901234567890
				dc.b	"Four Channel Mono Selected              "
				dc.b	"                                        "
				dc.b	"                                        "
				dc.b	"                                        "

				dc.b	"Four Channel Stereo Selected            "
				dc.b	"                                        "
				dc.b	"                                        "
				dc.b	"                                        "

				dc.b	"Eight Channel Mono Selected             "
				dc.b	"                                        "
				dc.b	"                                        "
				dc.b	"                                        "

				dc.b	"Eight Channel Stereo Selected           "
				dc.b	"                                        "
				dc.b	"                                        "
				dc.b	"                                        "

LIGHTING:		dc.w	$FFff
OLDLTOG:		dc.w	0

pastster:

				cmp.b	#'4',d1
				seq		CHANNELDATA+8
				seq		CHANNELDATA+12
				seq		CHANNELDATA+24
				seq		CHANNELDATA+28

* Mt_init *********************
				st		CHANNELDATA+8
				st		CHANNELDATA
*******************************

				move.w	#$f,$dff000+dmacon
				move.l	#null,$dff0a0
				move.w	#100,$dff0a4
				move.w	#443,$dff0a6
				move.w	#63,$dff0a8

				move.l	#null2,$dff0b0
				move.w	#100,$dff0b4
				move.w	#443,$dff0b6
				move.w	#63,$dff0b8

				move.l	#null4,$dff0c0
				move.w	#100,$dff0c4
				move.w	#443,$dff0c6
				move.w	#63,$dff0c8

				move.l	#null3,$dff0d0
				move.w	#100,$dff0d4
				move.w	#443,$dff0d6
				move.w	#63,$dff0d8

				move.l	#empty,pos0LEFT
				move.l	#empty,pos1LEFT
				move.l	#empty,pos2LEFT
				move.l	#empty,pos3LEFT
				move.l	#empty,pos0RIGHT
				move.l	#empty,pos1RIGHT
				move.l	#empty,pos2RIGHT
				move.l	#empty,pos3RIGHT
				move.l	#emptyend,Samp0endLEFT
				move.l	#emptyend,Samp1endLEFT
				move.l	#emptyend,Samp2endLEFT
				move.l	#emptyend,Samp3endLEFT
				move.l	#emptyend,Samp0endRIGHT
				move.l	#emptyend,Samp1endRIGHT
				move.l	#emptyend,Samp2endRIGHT
				move.l	#emptyend,Samp3endRIGHT

				move.w	#10,d3
				; See if byt got transmitted overserial
;.willy
;				btst	#0,$dff000+intreqrl
;				beq.s	.willy
;				move.w	#1,$dff000+intreq
;
;				dbra	d3,.willy
;
;				move.w	#$820f,$dff000+dmacon

				bra		notogglesound2

Prefsfile:
				dc.b	'k8nx'

notogglesound:
				clr.b	lasttogsound
notogglesound2:


				tst.b	83(a5)
				beq		nolighttoggle
				tst.b	OLDLTOG
				bne		nolighttoggle2
				st		OLDLTOG

				move.l	#LIGHTINGTEXT,d0
				not.b	LIGHTING
				beq.s	.noon
				add.l	#160,d0
.noon:
				bra		pastlighttext

LIGHTINGTEXT:
				dc.b	"Lighting Effects Deactivated            "
				dc.b	"                                        "
				dc.b	"                                        "
				dc.b	"                                        "

				dc.b	"Lighting Effects Activated              "
				dc.b	"                                        "
				dc.b	"                                        "
				dc.b	"                                        "

OLDRET:			dc.w	0
OLDCENT:		dc.w	0
OLDGOOD:		dc.w	0

GOODRENDERTXT:
				dc.b	"Rendering Quality : High                "
				dc.b	"                                        "
				dc.b	"                                        "
				dc.b	"                                        "
BADRENDERTXT:
				dc.b	"Rendering Quality : Reduced             "
				dc.b	"                                        "
				dc.b	"                                        "
				dc.b	"                                        "

pastlighttext:

				jsr		SENDMESSAGE

; move.l d0,SCROLLPOINTER
; move.w #0,SCROLLXPOS
; add.l #160,d0
; move.l d0,ENDSCROLL
; move.w #40,SCROLLTIMER

				bra		nolighttoggle2

nolighttoggle:
				clr.b	OLDLTOG
nolighttoggle2:


				tst.b	84(a5)
				beq.s	noret
				tst.b	OLDRET
				bne.s	noret2
				st		OLDRET

				jsr		RETRIEVEPREVMESSAGE

				bra		noret2

noret
				clr.b	OLDRET
noret2:

				tst.b	85(a5)
				beq.s	.nogood
				tst.b	OLDGOOD
				bne.s	.nogood2
				st		OLDGOOD

				move.l	#GOODRENDERTXT,d0
				not.b	GOODRENDER
				bne.s	.okgood
				move.l	#BADRENDERTXT,d0
.okgood:

				jsr		SENDMESSAGE

				bra		.nogood2

.nogood
				clr.b	OLDGOOD
.nogood2:


				tst.b	$42(a5)
				bne.s	.tabprsd
				clr.b	tabheld
				bra.s	.noswitch

.tabprsd:
				tst.b	tabheld
				bne.s	.noswitch
				not.b	MAPON
				st		tabheld
.noswitch

				tst.b	$3e(a5)
				sne		d0
				tst.b	$1e(a5)
				sne		d1
				tst.b	$2d(a5)
				sne		d2
				tst.b	$2f(a5)
				sne		d3

				tst.b	$3d(a5)
				sne		d4
				tst.b	$3f(a5)
				sne		d5
				tst.b	$1d(a5)
				sne		d6
				tst.b	$1f(a5)
				sne		d7

				or.b	d4,d0
				or.b	d5,d0
				or.b	d6,d1
				or.b	d7,d1
				or.b	d4,d2
				or.b	d6,d2
				or.b	d7,d3
				or.b	d5,d3

				move.w	MAPBRIGHT,d4
				add.w	#2,d4
				clr.l	d5
				bset	d4,d5

				tst.b	d0
				beq.s	.nomapup
				sub.w	d5,mapzoff
.nomapup

				tst.b	d1
				beq.s	.nomapdown
				add.w	d5,mapzoff
.nomapdown

				tst.b	d2
				beq.s	.nomapleft
				add.w	d5,mapxoff
.nomapleft

				tst.b	d3
				beq.s	.nomapright
				sub.w	d5,mapxoff
.nomapright

				tst.b	$2e(a5)
				beq.s	.nomapcentre

				move.w	#0,mapxoff
				move.w	#0,mapzoff

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
; muls #SCREENWIDTH*2,d0
; move.l d0,SBIGMIDDLEY


; jsr INITREC
; jsr RECEIVE

; tst.l BUFFER
; beq.s justshake
; st GOTTOSEND
; move.l #OtherInter,$6c

justshake:

; cmp.b #'b',Prefsfile+3
; bne.s .noback


				jsr		mt_music



;.noback:

				bra		dontshowtime

				tst.b	oktodisplay
				beq		dontshowtime
				clr.b	oktodisplay
				subq.w	#1,dispco
				bgt		dontshowtime
				move.w	#10,dispco

				move.l	#TimerScr+10,a0
				move.l	TimeCount,d0
				bge.s	timenotneg
				move.l	#1111*256,d0
timenotneg:
				asr.l	#8,d0
				move.l	#digits,a1
				move.w	#7,d2
digitlop
				divs	#10,d0
				swap	d0
				lea		(a1,d0.w*8),a2
				move.b	(a2)+,(a0)
				move.b	(a2)+,24(a0)
				move.b	(a2)+,24*2(a0)
				move.b	(a2)+,24*3(a0)
				move.b	(a2)+,24*4(a0)
				move.b	(a2)+,24*5(a0)
				move.b	(a2)+,24*6(a0)
				move.b	(a2)+,24*7(a0)
				subq	#1,a0
				swap	d0
				ext.l	d0
				dbra	d2,digitlop

				move.l	#TimerScr+10+24*10,a0
				move.l	NumTimes,d0
				move.l	#digits,a1
				move.w	#3,d2
digitlop2
				divs	#10,d0
				swap	d0
				lea		(a1,d0.w*8),a2
				move.b	(a2)+,(a0)
				move.b	(a2)+,24(a0)
				move.b	(a2)+,24*2(a0)
				move.b	(a2)+,24*3(a0)
				move.b	(a2)+,24*4(a0)
				move.b	(a2)+,24*5(a0)
				move.b	(a2)+,24*6(a0)
				move.b	(a2)+,24*7(a0)
				subq	#1,a0
				swap	d0
				ext.l	d0
				dbra	d2,digitlop2

				move.l	#TimerScr+10+24*20,a0
				moveq	#0,d0
				move.w	FramesToDraw,d0
				move.l	#digits,a1
				move.w	#2,d2
digitlop3
				divs	#10,d0
				swap	d0
				lea		(a1,d0.w*8),a2
				move.b	(a2)+,(a0)
				move.b	(a2)+,24(a0)
				move.b	(a2)+,24*2(a0)
				move.b	(a2)+,24*3(a0)
				move.b	(a2)+,24*4(a0)
				move.b	(a2)+,24*5(a0)
				move.b	(a2)+,24*6(a0)
				move.b	(a2)+,24*7(a0)
				subq	#1,a0
				swap	d0
				ext.l	d0
				dbra	d2,digitlop3

dontshowtime:


				move.l	alanptr,a0
				move.l	(a0)+,alframe
				cmp.l	#endalan,a0
				blt.s	nostartalan
				move.l	#alan,a0
nostartalan:
				move.l	a0,alanptr


				tst.b	READCONTROLS
				beq		nocontrols

				cmp.b	#PLR_SLAVE,Plr_MultiplayerType_b
				beq		control2

				tst.w	PLAYERONEHEALTH
				bgt		.propercontrol

				move.l	#7*2116,hitcol
				move.l	Plr1_ObjectPtr_l,a0
				move.w	#-1,12+128(a0)

				clr.b	PLR1_fire
				clr.b	PLR1_clicked
				move.w	#0,ADDTOBOBBLE
				move.l	#playercrouched,Plr1_SnapHeight_l
				move.w	#-80,d0					; Is this related to render buffer height
				move.w	d0,STOPOFFSET
				neg.w	d0
				add.w	TOTHEMIDDLE,d0
				move.w	d0,SMIDDLEY
				muls	#SCREENWIDTH,d0
				move.l	d0,SBIGMIDDLEY
				jsr		PLR1_fall

				move.l	Plr1_SnapXSpdVal_l,d6
				move.l	Plr1_SnapZSpdVal_l,d7

				tst.b	SLOWDOWN
				beq.s	.nofriction

				neg.l	d6
				ble.s	.nobug1
				asr.l	#3,d6
				add.l	#1,d6
				bra.s	.bug1
.nobug1
				asr.l	#3,d6
.bug1:

				neg.l	d7
				ble.s	.nobug2
				asr.l	#3,d7
				add.l	#1,d7
				bra.s	.bug2
.nobug2
				asr.l	#3,d7
.bug2:

				add.l	d6,Plr1_SnapXSpdVal_l
				add.l	d7,Plr1_SnapZSpdVal_l

.nofriction:
				move.l	Plr1_SnapXSpdVal_l,d6
				move.l	Plr1_SnapZSpdVal_l,d7
				add.l	d6,Plr1_SnapXOff_l
				add.l	d7,Plr1_SnapZOff_l

				move.w	Plr1_SnapAngSpd_w,d3
				tst.b	SLOWDOWN
				beq.s	.nofric
				asr.w	#2,d3
				bge.s	.nneg
				addq	#1,d3
.nneg:
.nofric:

				move.w	d3,Plr1_SnapAngSpd_w
				add.w	d3,Plr1_SnapAngPos_w
				add.w	d3,Plr1_SnapAngPos_w
				and.w	#8190,Plr1_SnapAngPos_w

				bra		nocontrols

.propercontrol:

				tst.b	Plr1_Mouse_b
				beq.s	.plr1_no_mouse
				bsr		Plr1_MouseControl
.plr1_no_mouse:
				tst.b	Plr1_Keys_b
				beq.s	.plr1_no_keyboard
				bsr		Plr1_KeyboardControl
.plr1_no_keyboard:
; tst.b Plr1_Path_b
; beq.s PLR1_nopath
; bsr Plr1_FollowPath
;PLR1_nopath:
				tst.b	Plr1_Joystick_b
				beq.s	.plr1_no_joystick
				bsr		Plr1_JoystickControl
.plr1_no_joystick:
				bra		nocontrols

control2:
				tst.w	PLAYERTWOHEALTH
				bgt		.propercontrol

				move.l	#7*2116,hitcol
				move.l	Plr1_ObjectPtr_l,a0
				move.w	#-1,12+128(a0)
				clr.b	PLR2_fire
				move.w	#0,ADDTOBOBBLE
				move.l	#playercrouched,Plr2_SnapHeight_l
				move.w	#-80,d0
				move.w	d0,STOPOFFSET
				neg.w	d0
				add.w	TOTHEMIDDLE,d0
				move.w	d0,SMIDDLEY
				muls	#SCREENWIDTH,d0
				move.l	d0,SBIGMIDDLEY

				jsr		PLR2_fall

				move.l	Plr2_SnapXSpdVal_l,d6
				move.l	Plr2_SnapZSpdVal_l,d7

				tst.b	SLOWDOWN
				beq.s	.nofriction

				neg.l	d6
				ble.s	.nobug1
				asr.l	#3,d6
				add.l	#1,d6
				bra.s	.bug1
.nobug1
				asr.l	#3,d6
.bug1:

				neg.l	d7
				ble.s	.nobug2
				asr.l	#3,d7
				add.l	#1,d7
				bra.s	.bug2
.nobug2
				asr.l	#3,d7
.bug2:

				add.l	d6,Plr2_SnapXSpdVal_l
				add.l	d7,Plr2_SnapZSpdVal_l

.nofriction:
				move.l	Plr2_SnapXSpdVal_l,d6
				move.l	Plr2_SnapZSpdVal_l,d7
				add.l	d6,Plr2_SnapXOff_l
				add.l	d7,Plr2_SnapZOff_l

				move.w	Plr2_SnapAngSpd_w,d3
				tst.b	SLOWDOWN
				beq.s	.nofric
				asr.w	#2,d3
				bge.s	.nneg
				addq	#1,d3

.nneg:
.nofric:
				move.w	d3,Plr2_SnapAngSpd_w
				add.w	d3,Plr2_SnapAngPos_w
				add.w	d3,Plr2_SnapAngPos_w
				and.w	#8190,Plr2_SnapAngPos_w
				bra.s	nocontrols

.propercontrol:
				tst.b	Plr2_Mouse_b
				beq.s	.plr2_no_mouse
				bsr		Plr2_MouseControl
.plr2_no_mouse:
				tst.b	Plr2_Keys_b
				beq.s	.plr2_no_keyboard
				bsr		PLR2_keyboard_control
.plr2_no_keyboard:
; tst.b Plr2_Path_b
; beq.s .plr2_no_path
; bsr Plr1_FollowPath
;.plr2_no_path:
				tst.b	Plr2_Joystick_b
				beq.s	.plr2_no_joystick
				bsr		PLR2_JoyStick_control
.plr2_no_joystick:

nocontrols:
				move.l	#$dff000,a6

				tst.b	dosounds
				beq.s	nomuckabout

				cmp.b	#'4',Prefsfile+1
				bne.s	nomuckabout

				move.w	#$0,d0
				tst.b	NoiseMade0LEFT
				beq.s	noturnoff0
				move.w	#1,d0
noturnoff0:
				tst.b	NoiseMade0RIGHT
				beq.s	noturnoff1
				or.w	#2,d0
noturnoff1:
				tst.b	NoiseMade1RIGHT
				beq.s	noturnoff2
				or.w	#4,d0
noturnoff2:
				tst.b	NoiseMade1LEFT
				beq.s	noturnoff3
				or.w	#8,d0
noturnoff3:

*********************
				and.w	#$fffe,d0
*********************

				move.w	d0,dmacon(a6)

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

				tst.b	dosounds
				beq.s	.notthing

				cmp.b	#'4',Prefsfile+1
				beq		fourchannel

				btst	#1,$dff000+intreqr
				bne.s	newsampbitl

.notthing:

; move.w #$f,$dff000+dmacon

				movem.l	(a7)+,d0-d7/a0-a6

				moveq	#0,d0					; VERTB interrupt needs to return Z flag set
				rts

********************************************************************
* End of VBlank code
********************************************************************


dosounds:		dc.w	0

swappedem:		dc.w	0

newsampbitl:



				move.w	#$200,$dff000+intreq

				tst.b	CHANNELDATA
				bne		nochannel0

				move.l	pos0LEFT,a0
				move.l	pos2LEFT,a1

				move.l	#tab,a2

				moveq	#0,d0
				moveq	#0,d1
				move.b	vol0left,d0
				move.b	vol2left,d1
				cmp.b	d1,d0
				slt		swappedem
				bge.s	fbig0

; d1 is bigger so scale d0 and use d1
; as audiochannel volume.

				exg		a0,a1
				asl.w	#6,d0
				divs	d1,d0
				lsl.w	#8,d0
				adda.w	d0,a2
				move.w	d1,$dff0a8
				bra.s	donechan0

fbig0:
				tst.w	d0
				beq.s	donechan0
				asl.w	#6,d1
				divs	d0,d1
				lsl.w	#8,d1
				adda.w	d1,a2
				move.w	d0,$dff0a8

donechan0:

				move.l	Aupt0,a3
				move.l	a3,$dff0a0
				move.l	Auback0,Aupt0
				move.l	a3,Auback0

				move.l	Auback0,a3

				moveq	#0,d0
				moveq	#0,d1
				moveq	#0,d2
				moveq	#0,d3
				moveq	#0,d4
				moveq	#0,d5
				move.w	#49,d7
loop:
				move.l	(a0)+,d0
				move.b	(a1)+,d1
				move.b	(a1)+,d2
				move.b	(a1)+,d3
				move.b	(a1)+,d4
				move.b	(a2,d3.w),d5
				swap	d5
				move.b	(a2,d1.w),d5
				asl.l	#8,d5
				move.b	(a2,d2.w),d5
				swap	d5
				move.b	(a2,d4.w),d5
				add.l	d5,d0
				move.l	d0,(a3)+
				dbra	d7,loop

				tst.b	swappedem
				beq.s	.ok23
				exg		a0,a1
.ok23:

				cmp.l	Samp0endLEFT,a0
				blt.s	.notoffendsamp1
				move.l	#empty,a0
				move.l	#emptyend,Samp0endLEFT
				move.b	#0,vol0left
				clr.w	LEFTCHANDATA+32
				move.w	#0,LEFTCHANDATA+2
.notoffendsamp1:

				cmp.l	Samp2endLEFT,a1
				blt.s	.notoffendsamp2
				move.l	#empty,a1
				move.l	#emptyend,Samp2endLEFT
				move.b	#0,vol2left
				clr.w	LEFTCHANDATA+32+8
				move.w	#0,LEFTCHANDATA+2+8
.notoffendsamp2:

				move.l	a0,pos0LEFT
				move.l	a1,pos2LEFT

nochannel0:

				tst.b	CHANNELDATA+16
				bne		nochannel1


				move.l	pos0RIGHT,a0
				move.l	pos2RIGHT,a1

				move.l	Aupt1,a3
				move.l	a3,$dff0b0
				move.l	Auback1,Aupt1
				move.l	a3,Auback1

				move.l	#tab,a2

				moveq	#0,d0
				moveq	#0,d1
				move.b	vol0right,d0
				move.b	vol2right,d1
				cmp.b	d1,d0
				slt		swappedem
				bge.s	fbig1

; d1 is bigger so scale d0 and use d1
; as audiochannel volume.

				exg		a0,a1
				asl.w	#6,d0
				divs	d1,d0
				lsl.w	#8,d0
				adda.w	d0,a2
				move.w	d1,$dff0b8
				bra.s	donechan1

fbig1:
				tst.w	d0
				beq.s	donechan1
				asl.w	#6,d1
				divs	d0,d1
				lsl.w	#8,d1
				adda.w	d1,a2
				move.w	d0,$dff0b8

donechan1:
				moveq	#0,d0
				moveq	#0,d1
				moveq	#0,d2
				moveq	#0,d3
				moveq	#0,d4
				moveq	#0,d5
				move.w	#49,d7
loop2:
				move.l	(a0)+,d0
				move.b	(a1)+,d1
				move.b	(a1)+,d2
				move.b	(a1)+,d3
				move.b	(a1)+,d4
				move.b	(a2,d3.w),d5
				swap	d5
				move.b	(a2,d1.w),d5
				asl.l	#8,d5
				move.b	(a2,d2.w),d5
				swap	d5
				move.b	(a2,d4.w),d5
				add.l	d5,d0
				move.l	d0,(a3)+
				dbra	d7,loop2

				tst.b	swappedem
				beq.s	ok01
				exg		a0,a1
ok01:

				cmp.l	Samp0endRIGHT,a0
				blt.s	.notoffendsamp1
				move.l	#empty,a0
				move.l	#emptyend,Samp0endRIGHT
				move.b	#0,vol0right
				clr.w	RIGHTCHANDATA+32
				move.w	#0,RIGHTCHANDATA+2
.notoffendsamp1:

				cmp.l	Samp2endRIGHT,a1
				blt.s	.notoffendsamp2
				move.l	#empty,a1
				move.l	#emptyend,Samp2endRIGHT
				move.b	#0,vol2right
				clr.w	RIGHTCHANDATA+32+8
				move.w	#0,RIGHTCHANDATA+2+8
.notoffendsamp2:

				move.l	a0,pos0RIGHT
				move.l	a1,pos2RIGHT

nochannel1:

******************* Other two channels

				move.l	pos1LEFT,a0
				move.l	pos3LEFT,a1

				move.l	#tab,a2

				moveq	#0,d0
				moveq	#0,d1
				move.b	vol1left,d0
				move.b	vol3left,d1
				cmp.b	d1,d0
				slt		swappedem
				bge.s	fbig2

; d1 is bigger so scale d0 and use d1
; as audiochannel volume.

				exg		a0,a1
				asl.w	#6,d0
				divs	d1,d0
				lsl.w	#8,d0
				adda.w	d0,a2
				move.w	d1,$dff0d8
				bra.s	donechan2

fbig2:
				tst.w	d0
				beq.s	donechan2
				asl.w	#6,d1
				divs	d0,d1
				lsl.w	#8,d1
				adda.w	d1,a2
				move.w	d0,$dff0d8

donechan2:

				move.l	Aupt2,a3
				move.l	a3,$dff0d0
				move.l	Auback2,Aupt2
				move.l	a3,Auback2

				moveq	#0,d0
				moveq	#0,d1
				moveq	#0,d2
				moveq	#0,d3
				moveq	#0,d4
				moveq	#0,d5
				move.w	#49,d7
loop3:											; mixing two channels, 50 * 4
				move.l	(a0)+,d0				; this is sometimes reading past beyond the sample buffer
				move.b	(a1)+,d1
				move.b	(a1)+,d2
				move.b	(a1)+,d3
				move.b	(a1)+,d4
				move.b	(a2,d3.w),d5			; the audio stream in a1 gets scaled via a table?
				swap	d5
				move.b	(a2,d1.w),d5
				asl.l	#8,d5
				move.b	(a2,d2.w),d5
				swap	d5
				move.b	(a2,d4.w),d5
				add.l	d5,d0
				move.l	d0,(a3)+
				dbra	d7,loop3

				tst.b	swappedem
				beq.s	.ok23
				exg		a0,a1
.ok23:

				cmp.l	Samp1endLEFT,a0
				blt.s	.notoffendsamp3
				move.l	#empty,a0
				move.l	#emptyend,Samp1endLEFT
				move.b	#0,vol1left
				clr.w	LEFTCHANDATA+32+4
				move.w	#0,LEFTCHANDATA+2+4
.notoffendsamp3:

				cmp.l	Samp3endLEFT,a1
				blt.s	.notoffendsamp4
				move.l	#empty,a1
				move.l	#emptyend,Samp3endLEFT
				move.b	#0,vol3left
				clr.w	LEFTCHANDATA+32+12
				move.w	#0,LEFTCHANDATA+2+12
.notoffendsamp4:

				move.l	a0,pos1LEFT
				move.l	a1,pos3LEFT

				move.l	pos1RIGHT,a0
				move.l	pos3RIGHT,a1

				move.l	Aupt3,a3
				move.l	a3,$dff0c0
				move.l	Auback3,Aupt3
				move.l	a3,Auback3

				move.l	#tab,a2

				moveq	#0,d0
				moveq	#0,d1
				move.b	vol1right,d0
				move.b	vol3right,d1
				cmp.b	d1,d0
				slt		swappedem
				bge.s	fbig3

				exg		a0,a1
				asl.w	#6,d0
				divs	d1,d0
				lsl.w	#8,d0
				adda.w	d0,a2
				move.w	d1,$dff0c8
				bra.s	donechan3

fbig3:
				tst.w	d0
				beq.s	donechan3
				asl.w	#6,d1
				divs	d0,d1
				lsl.w	#8,d1
				adda.w	d1,a2
				move.w	d0,$dff0c8
donechan3:

				moveq	#0,d0
				moveq	#0,d1
				moveq	#0,d2
				moveq	#0,d3
				moveq	#0,d4
				moveq	#0,d5
				move.w	#49,d7
loop4:
				move.l	(a0)+,d0
				move.b	(a1)+,d1
				move.b	(a1)+,d2
				move.b	(a1)+,d3
				move.b	(a1)+,d4
				move.b	(a2,d3.w),d5
				swap	d5
				move.b	(a2,d1.w),d5
				asl.l	#8,d5
				move.b	(a2,d2.w),d5
				swap	d5
				move.b	(a2,d4.w),d5
				add.l	d5,d0
				move.l	d0,(a3)+
				dbra	d7,loop4

				tst.b	swappedem
				beq.s	.ok23
				exg		a0,a1
.ok23:

				cmp.l	Samp1endRIGHT,a0
				blt.s	notoffendsamp3
				move.l	#empty,a0
				move.l	#emptyend,Samp1endRIGHT
				move.b	#0,vol1right
				clr.w	RIGHTCHANDATA+32+4
				move.w	#0,RIGHTCHANDATA+2+4
notoffendsamp3:

				cmp.l	Samp3endRIGHT,a1
				blt.s	notoffendsamp4
				move.l	#empty,a1
				move.l	#emptyend,Samp3endRIGHT
				move.b	#0,vol3right
				clr.w	RIGHTCHANDATA+32+12
				move.w	#0,RIGHTCHANDATA+2+12
notoffendsamp4:

				move.l	a0,pos1RIGHT
				move.l	a1,pos3RIGHT

				movem.l	(a7)+,d0-d7/a0-a6
; tst.b counting
; beq .nostartcounter
; JSR STARTCOUNT
;.nostartcounter:

				move.w	#$820f,$dff000+dmacon

				moveq	#0,d0					; VERTB interrupt needs to return Z flag set
				rts

***********************************
* 4 channel sound routine
***********************************

fourchannel:

				move.l	#$dff000,a6

				tst.b	LEFTCHANDATA
				bne.s	NoChan0sound

				btst	#7,intreqrl(a6)
				beq.s	nofinish0
; move.w #0,LEFTCHANDATA+2
; st LEFTCHANDATA+1
				move.l	#null,$a0(a6)
				move.w	#100,$a4(a6)
				move.w	#$0080,intreq(a6)
nofinish0:

				tst.b	NoiseMade0pLEFT
				beq.s	NoChan0sound

				move.l	Samp0endLEFT,d0
				move.l	pos0LEFT,d1
				sub.l	d1,d0
				lsr.l	#1,d0
				move.w	d0,$a4(a6)
				move.l	d1,$a0(a6)
				ext.l	d0
				divs	#100,d0
				move.w	d0,playnull0
				move.w	#$8201,dmacon(a6)
				moveq	#0,d0
				move.b	vol0left,d0
				move.w	d0,$a8(a6)

NoChan0sound:

*****************************************
*****************************************

				btst	#0,intreqr(a6)
				beq.s	nofinish1
				move.l	#null,$b0(a6)
				move.w	#100,$b4(a6)
				move.w	#$0100,intreq(a6)
nofinish1:

				tst.b	NoiseMade0pRIGHT
				beq.s	NoChan1sound

				move.l	Samp0endRIGHT,d0
				move.l	pos0RIGHT,d1
				sub.l	d1,d0
				lsr.l	#1,d0
				move.w	d0,$b4(a6)
				move.l	d1,$b0(a6)
				ext.l	d0
				divs	#100,d0
				move.w	d0,playnull1
				move.w	#$8202,dmacon(a6)
				moveq	#0,d0
				move.b	vol0right,d0
				move.w	d0,$b8(a6)

NoChan1sound:

*****************************************
*****************************************

				btst	#1,intreqr(a6)
				beq.s	nofinish2
				move.l	#null,$c0(a6)
				move.w	#100,$c4(a6)
				move.w	#$0200,intreq(a6)
nofinish2:

				tst.b	NoiseMade1pRIGHT
				beq.s	NoChan2sound

				move.l	Samp1endRIGHT,d0
				move.l	pos1RIGHT,d1
				sub.l	d1,d0
				lsr.l	#1,d0
				move.w	d0,$c4(a6)
				ext.l	d0
				divs	#100,d0
				move.w	d0,playnull2

				move.l	d1,$c0(a6)
				move.w	#$8204,dmacon(a6)
				moveq	#0,d0
				move.b	vol1right,d0
				move.w	d0,$c8(a6)

NoChan2sound:

*****************************************
*****************************************

				btst	#2,intreqr(a6)
				beq.s	nofinish3
				move.l	#null,$d0(a6)
				move.w	#100,$d4(a6)
				move.w	#$0400,intreq(a6)
nofinish3:

				tst.b	NoiseMade1pLEFT
				beq.s	NoChan3sound

				move.l	Samp1endLEFT,d0
				move.l	pos1LEFT,d1
				sub.l	d1,d0
				lsr.l	#1,d0
				move.w	d0,$d4(a6)
				ext.l	d0
				divs	#100,d0
				move.w	d0,playnull3
				move.l	d1,$d0(a6)
				move.w	#$8208,dmacon(a6)
				moveq	#0,d0
				move.b	vol1left,d0
				move.w	d0,$d8(a6)

NoChan3sound:

nomorechannels:

				move.l	NoiseMade0LEFT,NoiseMade0pLEFT
				move.l	#0,NoiseMade0LEFT
				move.l	NoiseMade0RIGHT,NoiseMade0pRIGHT
				move.l	#0,NoiseMade0RIGHT

; tst.b playnull0
; beq.s .nnul
; sub.b #1,playnull0
; bra.s chan0still
;.nnul:
;
;chan0still:

				tst.b	NoiseMade0pLEFT
				bne.s	chan0still
				tst.w	playnull0
				beq.s	nnul0
				sub.w	#1,playnull0
				bra.s	chan0still
nnul0:
				move.w	#0,LEFTCHANDATA+2
				clr.w	LEFTCHANDATA+32
chan0still:

				tst.b	NoiseMade0pRIGHT
				bne.s	chan1still				;it'll never work
				tst.w	playnull1
				beq.s	nnul1
				sub.w	#1,playnull1
				bra.s	chan1still
nnul1:
				move.w	#0,RIGHTCHANDATA+2
				clr.w	RIGHTCHANDATA+32
chan1still:

				tst.b	NoiseMade1pRIGHT
				bne.s	chan2still
				tst.w	playnull2
				beq.s	nnul2
				sub.w	#1,playnull2
				bra.s	chan2still
nnul2:
				move.w	#0,RIGHTCHANDATA+2+4
				clr.w	RIGHTCHANDATA+32+4
chan2still:

				tst.b	NoiseMade1pLEFT
				bne.s	chan3still
				tst.w	playnull3
				beq.s	nnul3
				sub.w	#1,playnull3
				bra.s	chan3still
nnul3:
				move.w	#0,LEFTCHANDATA+2+4
				clr.w	LEFTCHANDATA+32+4

chan3still:


				movem.l	(a7)+,d0-d7/a0-a6

				moveq	#0,d0					; VERTB interrupt needs to return Z flag set
				rts

backbeat:		dc.w	0

playnull0:		dc.w	0
playnull1:		dc.w	0
playnull2:		dc.w	0
playnull3:		dc.w	0

Samp0endRIGHT:	dc.l	emptyend
Samp1endRIGHT:	dc.l	emptyend
Samp2endRIGHT:	dc.l	emptyend
Samp3endRIGHT:	dc.l	emptyend
Samp0endLEFT:	dc.l	emptyend
Samp1endLEFT:	dc.l	emptyend
Samp2endLEFT:	dc.l	emptyend
Samp3endLEFT:	dc.l	emptyend

Aupt0:			dc.l	null
Auback0:		dc.l	null+500
Aupt2:			dc.l	null3
Auback2:		dc.l	null3+500
Aupt3:			dc.l	null4
Auback3:		dc.l	null4+500
Aupt1:			dc.l	null2
Auback1:		dc.l	null2+500

NoiseMade0LEFT:	dc.b	0
NoiseMade1LEFT:	dc.b	0
NoiseMade2LEFT:	dc.b	0
NoiseMade3LEFT:	dc.b	0
NoiseMade0pLEFT: dc.b	0
NoiseMade1pLEFT: dc.b	0
NoiseMade2pLEFT: dc.b	0
NoiseMade3pLEFT: dc.b	0
NoiseMade0RIGHT: dc.b	0
NoiseMade1RIGHT: dc.b	0
NoiseMade2RIGHT: dc.b	0
NoiseMade3RIGHT: dc.b	0
NoiseMade0pRIGHT: dc.b	0
NoiseMade1pRIGHT: dc.b	0
NoiseMade2pRIGHT: dc.b	0
NoiseMade3pRIGHT: dc.b	0

empty:			ds.l	100
emptyend:

**************************************
* I want a routine to calculate all the
* info needed for the sound player to
* work, given say position of noise, volume
* and sample number.

Samplenum:		dc.w	0
Noisex:			dc.w	0
Noisez:			dc.w	0
Noisevol:		dc.w	0
chanpick:		dc.w	0
IDNUM:			dc.w	0
needleft:		dc.b	0
needright:		dc.b	0
STEREO:			dc.b	$FF

				even
CHANNELDATA:
LEFTCHANDATA:
				dc.l	$00000000
				dc.l	$00000000
				dc.l	$FF000000
				dc.l	$FF000000
RIGHTCHANDATA:
				dc.l	$00000000
				dc.l	$00000000
				dc.l	$FF000000
				dc.l	$FF000000

				ds.l	8

RIGHTPLAYEDTAB:	ds.l	20
LEFTPLAYEDTAB:	ds.l	20

SourceEcho:		dc.w	0
PLREcho:		dc.w	0


LEFTOFFSET:		dc.l	0
RIGHTOFFSET:	dc.l	0

MakeSomeNoise:

; move.w #$10,$dff000+intena

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

				tst.b	notifplaying
				beq.s	dontworry

; find if we are already playing

				move.w	IDNUM,d0
				cmp.w	#$ffff,d0
				beq.s	dontworry
				move.w	#7,d1
				lea		CHANNELDATA,a3
findsameasme
				tst.b	(a3)
				bne.s	notavail
				cmp.w	32(a3),d0
				beq		SameAsMe
notavail:
				add.w	#4,a3
				dbra	d1,findsameasme
				bra		dontworry
SameAsMe
; move.w #$8010,$dff000+intena
				rts

noiseloud:		dc.w	0

dontworry:

; Ok its fine for us to play a sound.
; So calculate left/right volume.

				move.w	Noisex,d1
				muls	d1,d1
				move.w	Noisez,d2
				muls	d2,d2
				move.w	Noisevol,d3
				move.w	#32767,noiseloud
				moveq	#1,d0
				add.l	d1,d2
				beq		pastcalc

				move.w	#31,d0
.findhigh
				btst	d0,d2
				bne		.foundhigh
				dbra	d0,.findhigh
.foundhigh
				asr.w	#1,d0
				clr.l	d3
				bset	d0,d3
				move.l	d3,d0

				move.w	d0,d3
				muls	d3,d3					; x*x
				sub.l	d2,d3					; x*x-a
				asr.l	#1,d3					; (x*x-a)/2
				divs	d0,d3					; (x*x-a)/2x
				sub.w	d3,d0					; second approx
				bgt		.stillnot0
				move.w	#1,d0
.stillnot0

				move.w	d0,d3
				muls	d3,d3
				sub.l	d2,d3
				asr.l	#1,d3
				divs	d0,d3
				sub.w	d3,d0					; second approx
				bgt		.stillnot02
				move.w	#1,d0
.stillnot02

				move.w	Noisevol,d3
				ext.l	d3
				asl.l	#6,d3
				cmp.l	#32767,d3
				ble.s	.nnnn
				move.l	#32767,d3
.nnnn

				asr.w	#2,d0
				addq	#1,d0
				divs	d0,d3

pastcalc:
				move.w	d3,noiseloud

				cmp.w	#64,d3
				ble.s	notooloud
				move.w	#64,d3
notooloud:

; d3 contains volume of noise.

				move.w	d3,d4
				tst.b	STEREO
				beq		NOSTEREO

				move.w	d3,d2
				muls	Noisex,d2
				asl.w	#2,d0
				divs	d0,d2

				bgt.s	quietleft
				add.w	d2,d4
				bge.s	donequiet
				move.w	#0,d4
				bra.s	donequiet
quietleft:
				sub.w	d2,d3
				bge.s	donequiet
				move.w	#0,d3
donequiet:

; d3=leftvol?
; d4=rightvol?


; d3 contains volume of noise.

				move.w	#$ffff,needleft

				move.l	#0,RIGHTOFFSET
				move.l	#0,LEFTOFFSET

				cmp.b	d3,d4
				bgt.s	RightLouder
				beq.s	NoLouder

				move.l	#4,LEFTOFFSET

; Left is louder; is it MUCH louder?

				st		needleft
				move.w	d3,d2
				sub.w	d4,d2
				cmp.w	#32,d2
				slt		needright
				bra		aboutsame

RightLouder:
				move.l	#4,RIGHTOFFSET
				st		needright
				move.w	d4,d2
				sub.w	d3,d2
				cmp.w	#32,d2
				slt		needleft

aboutsame:
NoLouder:


; Find least important sound on left

				move.l	#0,a2
				move.l	#0,d5
				move.w	#32767,d2
				move.w	IDNUM,d0
				lea		LEFTCHANDATA,a3
				move.w	#3,d1
FindLeftChannel
				tst.b	(a3)
				bne.s	.notactive
				cmp.w	32(a3),d0
				beq.s	FOUNDLEFT
				cmp.w	2(a3),d2
				blt.s	.notactive
				move.w	2(a3),d2
				move.l	a3,a2
				move.w	d5,d6

.notactive:
				add.w	#4,a3
				add.w	#1,d5
				dbra	d1,FindLeftChannel
				move.l	a2,a3
				bra.s	gopastleft
FOUNDLEFT:
				move.w	d5,d6
gopastleft:
				move.l	a3,d5
				tst.l	d5
				bne.s	FOUNDALEFT
NONOISE:
; move.w #$8010,$dff000+intena
				rts
FOUNDALEFT:

				cmp.w	noiseloud,d2
				bge		dorightchan

; d6 = channel number
				cmp.w	#$ffff,d0
				bne.s	.noche
				move.w	#$fffe,d0
.noche:
				move.w	d0,32(a3)
				move.w	noiseloud,2(a3)

				move.w	Samplenum,d5

; tst.b PlayEcho
; bne.s YESECHO
; tst.b SourceEcho
; beq.s NOECHO
;
;YESECHO:
;
; move.l GLF_DatabasePtr_l,a3
; add.l #GLFT_EchoTable_l,a3
; move.b (a3,d5.w),d5
;
;NOECHO:

				move.l	#SampleList,a3
				move.l	(a3,d5.w*8),a1
				add.l	LEFTOFFSET,a1
				move.l	4(a3,d5.w*8),a2
				add.l	LEFTOFFSET,a2

				tst.b	d6
				seq		NoiseMade0LEFT
				beq.s	.chan0
				cmp.b	#2,d6
				slt		NoiseMade1LEFT
				blt		.chan1
				seq		NoiseMade2LEFT
				beq		.chan2
				st		NoiseMade3LEFT

				move.b	d5,LEFTPLAYEDTAB+9
				move.b	d3,LEFTPLAYEDTAB+1+9
				move.b	d4,LEFTPLAYEDTAB+2+9
				move.b	d3,vol3left
				move.l	a1,pos3LEFT
				move.l	a2,Samp3endLEFT
				bra		dorightchan

.chan0:
				move.b	d5,LEFTPLAYEDTAB
				move.b	d3,LEFTPLAYEDTAB+1
				move.b	d4,LEFTPLAYEDTAB+2
				move.l	a1,pos0LEFT
				move.l	a2,Samp0endLEFT
				move.b	d3,vol0left
				bra		dorightchan

.chan1:
				move.b	d5,LEFTPLAYEDTAB+3
				move.b	d3,LEFTPLAYEDTAB+1+3
				move.b	d4,LEFTPLAYEDTAB+2+3
				move.b	d3,vol1left
				move.l	a1,pos1LEFT
				move.l	a2,Samp1endLEFT
				bra		dorightchan

.chan2:
				move.b	d5,LEFTPLAYEDTAB+6
				move.b	d3,LEFTPLAYEDTAB+1+6
				move.b	d4,LEFTPLAYEDTAB+2+6
				move.l	a1,pos2LEFT
				move.l	a2,Samp2endLEFT
				move.b	d3,vol2left

dorightchan:

; Find least important sound on right

				move.l	#0,a2
				move.l	#0,d5
				move.w	#10000,d2
				move.w	IDNUM,d0
				lea		RIGHTCHANDATA,a3
				move.w	#3,d1
FindRightChannel
				tst.b	(a3)
				bne.s	.notactive
				cmp.w	32(a3),d0
				beq.s	FOUNDRIGHT
				cmp.w	2(a3),d2
				blt.s	.notactive
				move.w	2(a3),d2
				move.l	a3,a2
				move.w	d5,d6

.notactive:
				add.w	#4,a3
				add.w	#1,d5
				dbra	d1,FindRightChannel
				move.l	a2,a3
				bra.s	gopastright
FOUNDRIGHT:
				move.w	d5,d6
gopastright:
				move.l	a3,d5
				tst.l	d5
				bne.s	FOUNDARIGHT
tototot:
; move.w #$8010,$dff000+intena
				rts
FOUNDARIGHT:

				cmp.w	noiseloud,d2
				bgt.s	tototot

; d6 = channel number
				cmp.w	#$ffff,d0
				bne.s	.noche
				move.w	#$fffe,d0
.noche:
				move.w	d0,32(a3)
				move.w	noiseloud,2(a3)

				move.w	Samplenum,d5
				move.l	#SampleList,a3
				move.l	(a3,d5.w*8),a1
				move.l	4(a3,d5.w*8),a2
				add.l	RIGHTOFFSET,a1
				add.l	RIGHTOFFSET,a2

				tst.b	d6
				seq		NoiseMade0RIGHT
				beq.s	.chan0
				cmp.b	#2,d6
				slt		NoiseMade1RIGHT
				blt		.chan1
				seq		NoiseMade2RIGHT
				beq		.chan2
				st		NoiseMade3RIGHT

				move.b	d5,RIGHTPLAYEDTAB+9
				move.b	d3,RIGHTPLAYEDTAB+1+9
				move.b	d4,RIGHTPLAYEDTAB+2+9
				move.b	d4,vol3right
				move.l	a1,pos3RIGHT
				move.l	a2,Samp3endRIGHT
; move.w #$8010,$dff000+intena
				rts

.chan0:
				move.b	d5,RIGHTPLAYEDTAB
				move.b	d3,RIGHTPLAYEDTAB+1
				move.b	d4,RIGHTPLAYEDTAB+2
				move.l	a1,pos0RIGHT
				move.l	a2,Samp0endRIGHT
				move.b	d4,vol0right
; move.w #$8010,$dff000+intena
				rts

.chan1:
				move.b	d5,RIGHTPLAYEDTAB+3
				move.b	d3,RIGHTPLAYEDTAB+1+3
				move.b	d4,RIGHTPLAYEDTAB+2+3
				move.b	d3,vol1right
				move.l	a1,pos1RIGHT
				move.l	a2,Samp1endRIGHT
; move.w #$8010,$dff000+intena
				rts

.chan2:
				move.b	d5,RIGHTPLAYEDTAB+6
				move.b	d3,RIGHTPLAYEDTAB+1+6
				move.b	d4,RIGHTPLAYEDTAB+2+6
				move.l	a1,pos2RIGHT
				move.l	a2,Samp2endRIGHT
				move.b	d3,vol2right
; move.w #$8010,$dff000+intena
				rts

NOSTEREO:
				move.l	#0,a2
				move.l	#-1,d5
				move.w	#32767,d2
				move.w	IDNUM,d0
				lea		CHANNELDATA,a3
				move.w	#7,d1
				moveq	#-1,d6

FindChannel
				tst.b	(a3)
				bne.s	.notactive
				cmp.w	32(a3),d0
				beq.s	FOUNDMYCHAN
				cmp.w	2(a3),d2
				blt.s	.notactive
				move.w	2(a3),d2
				move.l	a3,a2
				move.w	d5,d6
				add.w	#1,d6

.notactive:
				add.w	#4,a3
				add.w	#1,d5
				dbra	d1,FindChannel

				move.l	a2,a3
				bra.s	gopastchan

FOUNDMYCHAN:
				move.w	2(a3),d2

FOUNDCHAN:
				move.w	d5,d6
				add.w	#1,d6
gopastchan:
				tst.w	d6
				bge.s	FOUNDACHAN
tooquiet:
; move.w #$8010,$dff000+intena
				rts
FOUNDACHAN:

; d6 = channel number

				cmp.w	noiseloud,d2
				bgt.s	tooquiet

				cmp.w	#$ffff,d0
				bne.s	.noche
				move.w	#$fffe,d0
.noche:
				move.w	d0,32(a3)
				move.w	noiseloud,2(a3)

				move.w	Samplenum,d5

; tst.b PlayEcho
; bne.s YESECHO2
; tst.b SourceEcho
; beq.s NOECHO2
;
;YESECHO2:
;
; move.l GLF_DatabasePtr_l,a3
; add.l #GLFT_EchoTable_l,a3
; move.b (a3,d5.w),d5
;
;NOECHO2:

				move.l	#SampleList,a3
				move.l	(a3,d5.w*8),a1
				move.l	4(a3,d5.w*8),a2

				tst.b	d6
				beq		.chan0
				cmp.b	#2,d6
				blt		.chan1
				beq		.chan2
				cmp.b	#4,d6
				blt		.chan3
				beq		.chan4
				cmp.b	#6,d6
				blt		.chan5
				beq		.chan6
				st		NoiseMade3RIGHT

				move.b	d5,RIGHTPLAYEDTAB+9
				move.b	d3,RIGHTPLAYEDTAB+1+9
				move.b	d4,RIGHTPLAYEDTAB+2+9
				move.b	d4,vol3right
				move.l	a1,pos3RIGHT
				move.l	a2,Samp3endRIGHT
; move.w #$8010,$dff000+intena
				rts

.chan3:
				st		NoiseMade3LEFT
				move.b	d5,LEFTPLAYEDTAB+9
				move.b	d3,LEFTPLAYEDTAB+1+9
				move.b	d4,LEFTPLAYEDTAB+2+9
				move.b	d3,vol3left
				move.l	a1,pos3LEFT
				move.l	a2,Samp3endLEFT
; move.w #$8010,$dff000+intena
				rts

.chan0:
				st		NoiseMade0LEFT
				move.b	d5,LEFTPLAYEDTAB
				move.b	d3,LEFTPLAYEDTAB+1
				move.b	d4,LEFTPLAYEDTAB+2
				move.l	a1,pos0LEFT
				move.l	a2,Samp0endLEFT
				move.b	d3,vol0left
; move.w #$8010,$dff000+intena
				rts

.chan1:
				st		NoiseMade1LEFT
				move.b	d5,LEFTPLAYEDTAB+3
				move.b	d3,LEFTPLAYEDTAB+1+3
				move.b	d4,LEFTPLAYEDTAB+2+3
				move.b	d3,vol1left
				move.l	a1,pos1LEFT
				move.l	a2,Samp1endLEFT
; move.w #$8010,$dff000+intena
				rts

.chan2:
				st		NoiseMade2LEFT
				move.b	d5,LEFTPLAYEDTAB+6
				move.b	d3,LEFTPLAYEDTAB+1+6
				move.b	d4,LEFTPLAYEDTAB+2+6
				move.l	a1,pos2LEFT
				move.l	a2,Samp2endLEFT
				move.b	d3,vol2left
; move.w #$8010,$dff000+intena
				rts

.chan4:
				st		NoiseMade0RIGHT
				move.b	d5,RIGHTPLAYEDTAB
				move.b	d3,RIGHTPLAYEDTAB+1
				move.b	d4,RIGHTPLAYEDTAB+2
				move.l	a1,pos0RIGHT
				move.l	a2,Samp0endRIGHT
				move.b	d4,vol0right
; move.w #$8010,$dff000+intena
				rts

.chan5:
				st		NoiseMade1RIGHT
				move.b	d5,RIGHTPLAYEDTAB+3
				move.b	d3,RIGHTPLAYEDTAB+1+3
				move.b	d4,RIGHTPLAYEDTAB+2+3
				move.b	d3,vol1right
				move.l	a1,pos1RIGHT
				move.l	a2,Samp1endRIGHT
; move.w #$8010,$dff000+intena
				rts

.chan6:
				st		NoiseMade2RIGHT
				move.b	d5,RIGHTPLAYEDTAB+6
				move.b	d3,RIGHTPLAYEDTAB+1+6
				move.b	d4,RIGHTPLAYEDTAB+2+6
				move.l	a1,pos2RIGHT
				move.l	a2,Samp2endRIGHT
				move.b	d3,vol2right
; move.w #$8010,$dff000+intena
				rts

				section bss,bss
SampleList:
				ds.l	133

storeval:		ds.w	1

				section code,code

				include	"modules/res.s"
				include	"modules/file_io.s"
				include	"controlloop.s"


saveinters:
				dc.w	0

z:				dc.w	10

notifplaying:
				dc.w	0

audpos1:		dc.w	0
audpos1b:		dc.w	0
audpos2:		dc.w	0
audpos2b:		dc.w	0
audpos3:		dc.w	0
audpos3b:		dc.w	0
audpos4:		dc.w	0
audpos4b:		dc.w	0

vol0left:		dc.w	0
vol0right:		dc.w	0
vol1left:		dc.w	0
vol1right:		dc.w	0
vol2left:		dc.w	0
vol2right:		dc.w	0
vol3left:		dc.w	0
vol3right:		dc.w	0

pos:			dc.l	0

pos0LEFT:		dc.l	empty
pos1LEFT:		dc.l	empty
pos2LEFT:		dc.l	empty
pos3LEFT:		dc.l	empty
pos0RIGHT:		dc.l	empty
pos1RIGHT:		dc.l	empty
pos2RIGHT:		dc.l	empty
pos3RIGHT:		dc.l	empty

numtodo			dc.w	0

npt:			dc.w	0

pretab:
val				SET		0
				REPT	128
				dc.b	val
val				SET		val+1
				ENDR
val				SET		-128
				REPT	128
				dc.b	val
val				SET		val+1
				ENDR

tab:
				ds.b	256*65

test:			dc.l	0
				ds.l	30


; FIXME: since these are all empty symbols
; it stands to reason that they're all unusable,
; and any code referencing them.
				even
ConstCols:
; incbin "constcols"
				even
Smoothscalecols:
; incbin "smoothbumppalscaled"
				even
SmoothTile:
; incbin "smoothbumptile"
				even
Bumpscalecols:
; incbin "bumppalscaled"
				even
Bumptile:
; incbin "bumptile"
				even
scalecols:		;incbin	"bytepixpalscaled"
				even
;floorscalecols:
; incbin "floor256pal"
; ds.w 256*4

				even
PaletteAddr:	dc.l	0
ChunkAddr:		dc.l	0

floortile:
				dc.l	0
; incbin "floortile"
				even
wallrouts:
; incbin "2x2walldraw"
				CNOP	0,64

BackPicture:				; Is this the skytexture?
				dc.l	0
; incbin "rawback"
EndBackPicture:				; FIXME: this obviously doesn't work anymore, yet is still referfenced

SineTable:
				incbin	"bigsine"				; sine/cosine << 15

;angspd:			dc.w	0
flooryoff:		dc.w	0						; viewer y pos << 6
xoff:			dc.l	0
zoff:			dc.l	0
yoff:			dc.l	0
;yvel:			dc.l	0
;tyoff:			dc.l	0
;xspdval:		dc.l	0
;zspdval:		dc.l	0
;Zone:			dc.w	0

; // READY PLAYER ONE /////////////////////////////////////////////////////////////////////

; Player data definiton - TODO remove unused, tighten definitions, fix alignments
PLR1:			dc.b	$ff
				CNOP 0, 4
; long aligned fields first
Plr1_XOff_l:				dc.l	0 ; sometimes accessed as w - todo understand real size
Plr1_YOff_l:				dc.l	0
Plr1_ZOff_l:				dc.l	0 ; sometimes accessed as w - todo understand real size
Plr1_RoomPtr_l:				dc.l	0
Plr1_OldRoomPtr_l:			dc.l	0
Plr1_PointsToRotatePtr_l:	dc.l	0
Plr1_ListOfGraphRoomsPtr_l:	dc.l	0
Plr1_Height_l:				dc.l	0

; word aligned fields next
Plr1_Energy_w:				dc.w	191
Plr1_CosVal_w:				dc.w	0
Plr1_SinVal_w:				dc.w	0
Plr1_AngPos_w:				dc.w	0
Plr1_Zone_w:				dc.w	0
Plr1_FloorSpd_w:			dc.w	0
Plr1_RoomBright_w: 			dc.w	0

; byte aligned fields next
Plr1_GunSelected_b: 		dc.b	0
Plr1_StoodInTop_b: 			dc.b	0
Plr1_Teleported_b:			dc.b	0
Plr1_Ducked_b:				dc.b	0
Plr1_Squished_b:			dc.b	0
Plr1_Echo_b:				dc.b	0

				CNOP 0,4
; Player 1 snapshot data, long aligned first
Plr1_SnapXOff_l:			dc.l	0
Plr1_SnapYOff_l:			dc.l	0
Plr1_SnapYVel_l:			dc.l	0
Plr1_SnapZOff_l:			dc.l	0
Plr1_SnapTYOff_l:			dc.l	0
Plr1_SnapXSpdVal_l:			dc.l	0
Plr1_SnapZSpdVal_l:			dc.l	0
Plr1_SnapHeight_l:			dc.l	0
Plr1_SnapSquishedHeight_l:	dc.l	0
Plr1_SnapTargHeight_l: 		dc.l	0

; Player 1 snapshot data, word aligned next
Plr1_SnapCosVal_w:			dc.w	0
Plr1_SnapSinVal_w:			dc.w	0
Plr1_SnapAngPos_w:			dc.w	0
Plr1_SnapAngSpd_w:			dc.w	0

; Player 1 temporary data, long aligned first
Plr1_TmpXOff_l:				dc.l	0 ; also accessed as w, todo determine correct size
Plr1_TmpZOff_l:				dc.l	0
Plr1_TmpYOff_l:				dc.l	0
Plr1_TmpHeight_l:			dc.l	0

; Player 1 temporary data, word aligned next
Plr1_TmpAngPos_w:			dc.w	0
Plr1_TmpBobble_w:			dc.w	0
Plr1_TmpHoldDown_w:			dc.w	0

; Player 1 temporary data, byte aligned last
Plr1_TmpClicked_b:			dc.b	0
Plr1_TmpSpcTap_b:			dc.b	0
Plr1_TmpDucked_b:			dc.b	0
Plr1_TmpGunSelected_b:		dc.b	0
Plr1_TmpFire_b:				dc.b	0

; // END PLAYER TWO /////////////////////////////////////////////////////////////////////


; // READY PLAYER TWO /////////////////////////////////////////////////////////////////////

PLR2:			dc.b	$ff
				CNOP 0, 4
; long aligned fields first
Plr2_XOff_l:				dc.l	0
Plr2_YOff_l:				dc.l	0
Plr2_ZOff_l:				dc.l	0
Plr2_RoomPtr_l:				dc.l	0
Plr2_OldRoomPtr_l:			dc.l	0
Plr2_PointsToRotatePtr_l:	dc.l 	0
Plr2_ListOfGraphRoomsPtr_l: dc.l 	0
Plr2_Height_l:				dc.l	0

; word aligned fields next
Plr2_Energy_w:				dc.w	191
Plr2_CosVal_w:				dc.w	0
Plr2_SinVal_w:				dc.w	0
Plr2_AngPos_w:				dc.w	0
Plr2_Zone_w:				dc.w	0
Plr2_FloorSpd_w:			dc.w	0

; byte aligned fields next
Plr2_GunSelected_b:			dc.b	0
Plr2_StoodInTop_b:			dc.b	0
Plr2_Teleported_b:			dc.b	0
Plr2_Ducked_b:				dc.b	0
Plr2_Squished_b:			dc.b	0
Plr2_Echo_b:				dc.b	0

				CNOP 0,4
; Player 2 snapshot data, long aligned first
Plr2_SnapXOff_l:			dc.l	0
Plr2_SnapYOff_l:			dc.l	0
Plr2_SnapYVel_l:			dc.l	0
Plr2_SnapZOff_l:			dc.l	0
Plr2_SnapTYOff_l:			dc.l	0
Plr2_SnapXSpdVal_l:			dc.l	0
Plr2_SnapZSpdVal_l:			dc.l	0
Plr2_SnapHeight_l:			dc.l	0
Plr2_SnapSquishedHeight_l:	dc.l	0
Plr2_SnapTargHeight_l:		dc.l	0

; Player 2 snapshot data, word aligned next
Plr2_SnapCosVal_w:			dc.w	0
Plr2_SnapSinVal_w:			dc.w	0
Plr2_SnapAngPos_w:			dc.w	0
Plr2_SnapAngSpd_w:			dc.w	0

; Player 2 temporary data, long aligned first
Plr2_TmpXOff_l:				dc.l	0
Plr2_TmpZOff_l:				dc.l	0
Plr2_TmpYOff_l:				dc.l	0
Plr2_TmpHeight_l:			dc.l	0

; Player 2 temporary data, word aligned next
Plr2_TmpAngPos_w:			dc.w	0
Plr2_TmpBobble_w:			dc.w	0
Plr2_TmpHoldDown_w:			dc.w	0

; Player 2 temporary data, byte aligned last
Plr2_TmpClicked_b:			dc.b	0
Plr2_TmpSpcTap_b:			dc.b	0
Plr2_TmpDucked_b:			dc.b	0
Plr2_TmpGunSelected_b:		dc.b	0
Plr2_TmpFire_b:				dc.b	0


; // END PLAYER TWO /////////////////////////////////////////////////////////////////////

				even


PlayEcho:		dc.w	0 ; accessed as byte

DOUBLEWIDTH:	dc.b	$0,0
DOUBLEHEIGHT:	dc.b	0,0

				ds.w	4
				CNOP 0, 4

OldX1_l:			dc.l	0
OldX2_l:			dc.l	0
OldZ1_l:			dc.l	0
OldZ2_l:			dc.l	0

XDiff_w:			dc.w	0
ZDiff_w:			dc.w	0

				even

				ds.w	4

;liftanimtab:

;endliftanimtab:

;glassball:
; incbin "glassball.inc"

;endglass
;glassballpt:	dc.l	glassball

;rndtab:			;		incbin					"randfile"
;endrnd:

brightanimtab:
; dcb.w 200,20
; dc.w 5
; dc.w 10,20
; dc.w 5
; dcb.w 30,20
; dc.w 7,10,10,5,10,0,5,6,5,6,5,6,5,6,0
; dcb.w 40,0
; dc.w 1,2,3,2,3,2,3,2,3,2,3,2,3,0
; dcb.w 300,0
; dc.w 1,0,1,0,2,2,2,5,5,5,5,5,5,5,5,5,6,10
; dc.w -1

Roompt:			dc.l	0
OldRoompt:		dc.l	0

*****************************************************************
*
				include	"leveldata2.s"
*
*****************************************************************


wallpt:			dc.l	0
floorpt:		dc.l	0

Rotated:		ds.l	2*800					; store rotated X and Z coordinates with Z scaling applied

ObjRotated_vl:		ds.l	2*500

OnScreen:		ds.l	2*800					; store screen projected X coordinates for rotated points

startwait:		dc.w	0
endwait:		dc.w	0

;Faces:
; incbin "faces2raw"

Lvl_WalkLinksPtr_l:			dc.l	0
Lvl_FlyLinksPtr_l:		dc.l	0
*************************************************************

				section	bss,bss
consttab:
				ds.b	65536

				section	code,code

*******************************************************************



*********************************

; include "loadmod.a"
; include "proplayer.a"

; only used by glassobj: which in turn isn't used.
;darkentab:
;val SET 0
; REPT 256
; dc.b val
;val SET val+1
; ENDR
; incbin "darkenfile"
				dc.l	0
Vid_CentreX_w:		dc.w	SMALL_WIDTH/2
Vid_RightX_w:			dc.w	SMALL_WIDTH
Vid_FullScreen_b:		dc.w	0

;SHADINGTABLE: incbin "shadefile"

******************************************
* Link file !*****************************
******************************************

GLF_DatabaseName_vb:		dc.b	"ab3:includes/test.lnk",0

				CNOP 0,4
GLF_DatabasePtr_l:		dc.l	0

******************************************


;brightentab:
; incbin "brightenfile"
				section	bss,bss
WorkSpace:
				ds.l	8192

				section	data,data
waterfile:
				incbin	"waterfile"

Palette			incbin	"256pal"

				section code,code

hitcol:			dc.l	0

SCROLLOFFSET:	dc.w	0
SCROLLTIMER:	dc.w	100
SCROLLDIRECTION: dc.w	1
SCROLLXPOS:		dc.w	0
SCROLLPOINTER:	dc.l	testscroll
ENDSCROLL:		dc.l	endtestscroll

testscroll:
;      12345678901234567890123456789012345678901234567890123456789012345678901234567890
; dc.b "The Quick Brown Fox Jumped Over The Lazy Dog!                                   "
; dc.b "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ                            "
; dc.b "The Quick Brown Fox Jumped Over The Lazy Dog!                                   "

BLANKSCROLL:
				dc.b	"                                                                                "
endtestscroll:

Vid_TextScreenPtr_l:		dc.l	0


				SECTION	bss_c,bss_c
				cnop	0,8

PanelKeys:		;		I'm pretty sure these are not needed anymore, but there's code referencing it
;incbin "greenkey"
; incbin "redkey"
; incbin "yellowkey"
; incbin "bluekey"

; Audio NULL data
null:			ds.w	500
null2:			ds.w	500
null3:			ds.w	500
null4:			ds.w	500


				CNOP	0,64
SCROLLSCRN:		ds.l	20*16

********************************************
* Stuff you don't have to ShotT_Worry_b about yet. *
********************************************

				section	code,code

				; FIMXE: this is not what I was thinking it is.
				; This does not exit the whole game, but just playing
				; the game. After that it'll return to the main menu.

closeeverything:

				jsr		mt_end

;				move.l	_DOSBase,d0
;				move.l	d0,a1
;				CALLEXEC CloseLibrary
;
;				; FIXME: need to test if it even got installed
;				lea		VBLANKInt,a1
;				moveq	#INTB_VERTB,d0
;				CALLEXEC RemIntServer
;
;				IFEQ	CD32VER
;				lea		KEYInt,a1
;				moveq	#INTB_PORTS,d0
;				CALLEXEC RemIntServer
;				ENDC
;
				jsr		Res_FreeLevelData
				jsr		Res_ReleaseScreenMemory
;
;				move.l	MiscResourceBase,d0
;				beq.s	.noMiscResourceBase
;				move.l	d0,a6
;				; FIXME: would need to check if we actually allocated them successfully
;				move.l	#MR_SERIALPORT,d0
;				jsr		_LVOFreeMiscResource(a6)
;				move.l	#MR_SERIALBITS,d0
;				jsr		_LVOFreeMiscResource(a6)
;
;				clr.l	MiscResourceBase		; Resource library doesn't have a 'close'?
;
;.noMiscResourceBase
;
;				move.l	PotgoResourceBase,d0
;				beq.s	.noPotgoResource
;				move.l	d0,a6
;				move.l	#%110000000000,d0
;				jsr		_LVOFreePotBits(a6)
;
;
;
;.noPotgoResource
;
;				move.l	#0,d0					; FIXME indicate failure
				rts


OpenGraphics:
				lea		gfxname(pc),a1

				moveq.l	#0,d0
				CALLEXEC OpenLibrary

				move.l	d0,_GfxBase
				rts

gfxname			GRAFNAME
				cnop	0,4
_GfxBase:		dc.l	0


Panel:			dc.l	0

				cnop	0,64
TimerScr:		;		Not						needed(?), but still referenced but (inactive?) code
;ds.b 40*64
scrn:			dc.l	0
scrn2:			dc.l	0
SCRNDRAWPT:		dc.l	0
SCRNSHOWPT:		dc.l	0

NumTimes:		dc.l	0
TimeCount:		dc.l	0
oldtime:		dc.l	0
counting:		dc.b	0
oktodisplay:	dc.b	0

INITTIMER:
				move.l	#0,TimeCount
				move.l	#0,NumTimes
				rts

STARTCOUNT:
				move.l	d0,-(a7)
				move.l	$dff004,d0
				and.l	#$1ffff,d0
				move.l	d0,oldtime
				st		counting
				move.l	(a7)+,d0
				rts

STOPCOUNT:
				move.l	d0,-(a7)
				move.l	$dff004,d0
				and.l	#$1ffff,d0

				sub.l	oldtime,d0
				cmp.l	#-256,d0
				bge.s	okcount
				add.l	#313*256,d0
okcount:
				add.l	d0,TimeCount
				addq.l	#1,NumTimes
				clr.b	counting
				move.l	(a7)+,d0
				rts

STOPCOUNTNOADD:
				move.l	d0,-(a7)
				move.l	$dff004,d0
				and.l	#$1ffff,d0

				sub.l	oldtime,d0
				cmp.l	#-256,d0
				bge.s	okcount2
				add.l	#313*256,d0
okcount2:
				add.l	d0,TimeCount
				clr.b	counting
				move.l	(a7)+,d0
				rts

maxbot:			dc.w	0
tstneg:			dc.l	0

STOPTIMER:
				st		oktodisplay
				rts

digits:			incbin	"numbers.inc"

				section bss,bss
COMPACTMAP:		ds.l	257

BIGMAP:			ds.l	256*10
				section code,code

;CHEATFRAME:
;				dc.b	26,20,33,27,17,12
;ENDCHEAT:

UseAllChannels:	dc.w	0

mt_init:
				move.l	mt_data,a0
				move.l	a0,a1
				add.l	#$3b8,a1
				moveq	#$7f,d0
				moveq	#0,d1
mt_loop:		move.l	d1,d2
				subq.w	#1,d0
mt_lop2:		move.b	(a1)+,d1
				cmp.b	d2,d1
				bgt.s	mt_loop
				dbf		d0,mt_lop2
				addq.b	#1,d2

				lea		mt_samplestarts(pc),a1
				asl.l	#8,d2
				asl.l	#2,d2
				add.l	#$43c,d2
				add.l	a0,d2
				move.l	d2,a2
				moveq	#$1e,d0
mt_lop3:
				clr.l	(a2)
				move.l	a2,(a1)+
				moveq	#0,d1
				move.w	42(a0),d1
				asl.l	#1,d1
				add.l	d1,a2
				add.l	#$1e,a0
				dbf		d0,mt_lop3

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

mt_end:			clr.w	$dff0a8
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
				bra		mt_getnew

mt_nonew:
				lea		mt_voice1(pc),a6
				lea		$dff0a0,a5
				bsr		mt_checkcom
				tst.b	UseAllChannels
				beq		mt_endr
				lea		mt_voice2(pc),a6
				lea		$dff0b0,a5
				bsr		mt_checkcom
				lea		mt_voice3(pc),a6
				lea		$dff0c0,a5
				bsr		mt_checkcom
				lea		mt_voice4(pc),a6
				lea		$dff0d0,a5
				bsr		mt_checkcom
				bra		mt_endr

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
mt_arp1:		moveq	#0,d0
				move.b	$3(a6),d0
				and.b	#$f,d0
				bra.s	mt_arp3
mt_arp2:		move.w	$10(a6),d2
				bra.s	mt_arp4
mt_arp3:		asl.w	#1,d0
				moveq	#0,d1
				move.w	$10(a6),d1
				lea		mt_periods(pc),a0
				moveq	#$24,d7
mt_arploop:
				move.w	(a0,d0.w),d2
				cmp.w	(a0),d1
				bge.s	mt_arp4
				addq.l	#2,a0
				dbf		d7,mt_arploop
				rts
mt_arp4:		move.w	d2,$6(a5)
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

				lea		$dff0a0,a5
				lea		mt_voice1(pc),a6
				bsr		mt_playvoice
				tst.b	UseAllChannels
				beq		mt_setdma
				lea		$dff0b0,a5
				lea		mt_voice2(pc),a6
				bsr		mt_playvoice
				lea		$dff0c0,a5
				lea		mt_voice3(pc),a6
				bsr		mt_playvoice
				lea		$dff0d0,a5
				lea		mt_voice4(pc),a6
				bsr		mt_playvoice
				bra		mt_setdma

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
				lea		mt_samplestarts(pc),a1
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
				move.w	d0,$8(a5)
				bra.s	mt_setregs
mt_noloop:
				move.l	$4(a6),d2
				add.l	d3,d2
				move.l	d2,$a(a6)
				move.w	$6(a3,d4.l),$e(a6)
				move.w	$12(a6),d0
				move.w	d0,$8(a5)
mt_setregs:
				move.w	(a6),d0
				and.w	#$fff,d0
				beq		mt_checkcom2
				move.b	$2(a6),d0
				and.b	#$F,d0
				cmp.b	#$3,d0
				bne.s	mt_setperiod
				bsr		mt_setmyport
				bra		mt_checkcom2
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
				bra		mt_checkcom2

mt_setdma:
				move.w	#250,d0
mt_wait:
				add.w	#1,testchip
				dbra	d0,mt_wait
				move.w	mt_dmacon,d0
				or.w	#$8000,d0
				tst.b	UseAllChannels
				bne.s	.splib
				and.w	#%1111111111110001,d0
.splib
				move.w	d0,$dff096
				move.w	#250,d0
mt_wait2:
				add.w	#1,testchip
				dbra	d0,mt_wait2
				lea		$dff000,a5
				tst.b	UseAllChannels
				beq.s	noall
				lea		mt_voice4(pc),a6
				move.l	$a(a6),$d0(a5)
				move.w	$e(a6),$d4(a5)
				lea		mt_voice3(pc),a6
				move.l	$a(a6),$c0(a5)
				move.w	$e(a6),$c4(a5)
				lea		mt_voice2(pc),a6
				move.l	$a(a6),$b0(a5)
				move.w	$e(a6),$b4(a5)
noall:
				lea		mt_voice1(pc),a6
				move.l	$a(a6),$a0(a5)
				move.w	$e(a6),$a4(a5)

				add.w	#$10,mt_pattpos
				cmp.w	#$400,mt_pattpos
				bne.s	mt_endr
mt_nex:			clr.w	mt_pattpos
				clr.b	mt_break
				addq.b	#1,mt_songpos
				and.b	#$7f,mt_songpos
				move.b	mt_songpos,d1
;	cmp.b	mt_data+$3b6,d1
;	bne.s	mt_endr
;	move.b	mt_data+$3b7,mt_songpos
mt_endr:		tst.b	mt_break
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
mt_rt:			rts

CODESTORE:		dc.l	0

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
mt_myok:		move.w	$10(a6),$6(a5)
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

mt_vib:			move.b	$3(a6),d0
				beq.s	mt_vi
				move.b	d0,$1a(a6)

mt_vi:			move.b	$1b(a6),d0
				lea		mt_sin(pc),a4
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
mt_vib2:		move.w	d0,$6(a5)
				move.b	$1a(a6),d0
				lsr.w	#$2,d0
				and.w	#$3c,d0
				add.b	d0,$1b(a6)
				rts

mt_nop:			move.w	$10(a6),$6(a5)
				rts


mt_checkcom:
				move.w	$2(a6),d0
				and.w	#$fff,d0
				beq.s	mt_nop
				move.b	$2(a6),d0
				and.b	#$f,d0
				tst.b	d0
				beq		mt_arpeggio
				cmp.b	#$1,d0
				beq.s	mt_portup
				cmp.b	#$2,d0
				beq		mt_portdown
				cmp.b	#$3,d0
				beq		mt_myport
				cmp.b	#$4,d0
				beq		mt_vib
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
mt_vol2:		move.w	$12(a6),d0
				move.w	d0,$8(a5)
				rts

mt_voldown:
				moveq	#0,d0
				move.b	$3(a6),d0
				and.b	#$f,d0
				sub.w	d0,$12(a6)
				bpl.s	mt_vol3
				clr.w	$12(a6)
mt_vol3:		move.w	$12(a6),d0
				move.w	d0,$8(a5)
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
mt_por2:		move.w	$10(a6),d0
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
mt_por3:		move.w	$10(a6),d0
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
				st		reachedend
				move.b	$3(a6),d0
				subq.b	#$1,d0
				move.b	d0,mt_songpos
				not.b	mt_break
				rts
mt_setvol:
				cmp.b	#$40,$3(a6)
				ble.s	mt_vol4
				move.b	#$40,$3(a6)
mt_vol4:		move.b	$3(a6),d0
				move.w	d0,$8(a5)
				rts
mt_setspeed:
				cmp.b	#$1f,$3(a6)
				ble.s	mt_sets
				move.b	#$1f,$3(a6)
mt_sets:		move.b	$3(a6),d0
				beq.s	mt_rts2
				move.b	d0,mt_speed
				clr.b	mt_counter
mt_rts2:		rts

mt_sin:
				dc.b	$00,$18,$31,$4a,$61,$78,$8d,$a1,$b4,$c5,$d4,$e0,$eb,$f4,$fa,$fd
				dc.b	$ff,$fd,$fa,$f4,$eb,$e0,$d4,$c5,$b4,$a1,$8d,$78,$61,$4a,$31,$18

mt_periods:
				dc.w	$0358,$0328,$02fa,$02d0,$02a6,$0280,$025c,$023a,$021a,$01fc,$01e0
				dc.w	$01c5,$01ac,$0194,$017d,$0168,$0153,$0140,$012e,$011d,$010d,$00fe
				dc.w	$00f0,$00e2,$00d6,$00ca,$00be,$00b4,$00aa,$00a0,$0097,$008f,$0087
				dc.w	$007f,$0078,$0071,$0000,$0000

reachedend:		dc.b	0
mt_speed:		dc.b	6
mt_songpos:		dc.b	0
mt_pattpos:		dc.w	0
mt_counter:		dc.b	0

mt_break:		dc.b	0
mt_dmacon:		dc.w	0
mt_samplestarts:ds.l $1f
mt_voice1:		ds.w	10
				dc.w	1
				ds.w	3
mt_voice2:		ds.w	10
				dc.w	2
				ds.w	3
mt_voice3:		ds.w	10
				dc.w	4
				ds.w	3
mt_voice4:		ds.w	10
				dc.w	8
				ds.w	3

PLR1_dead:		dc.w	0
PLR2_dead:		dc.w	0

CHEATPTR:		dc.l	0
CHEATNUM:		dc.l	0


Lvl_MusicPtr_l:		dc.l	0

;/* End of File */
mt_data:		dc.l	0

				section	data_c,data_c
; not sure what this is; it seems to be used as timing
; device. I.e. by accessing chipmap, we throttle the CPU
tstchip:		dc.l	0
testchip:		dc.w	0

gameover:
				incbin	"includes/gameover"
welldone:
				incbin	"includes/quietwelldone"

				section code,code
				cnop	0,4
				include	"serial_nightmare.s"

				cnop	0,4
				include	"c2p1x1_8_c5_040.s"
				include	"c2p_rect.s"
				include	"c2p2x1_8_c5_gen.s"

