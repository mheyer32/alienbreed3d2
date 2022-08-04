; Main control loop.
; This is the very outer loop of the program.

; What needs to be done and when?

; Black screen start.
; Load title music
; Load title screen
; Fade up title screen
; Select options
; Play game.

; Playing the game involves allocating screen and
; level memory, loading the level, loading the
; samples, loading the wall graphics, playing the
; level, deallocating the screen memory....

; Control part should therefore:

; 1. Load Title Music
; 2. Load title screen
; 3. Fade up title screen.
; 4. Add 'loading' message
; 5. Load samples and walls
; 6: LOOP START
; 7. Option select screens
; 8. Free music mem, allocate level mem.
; 9. Load level
;10. Play level with options selected
;11. Reload title music
;12. Reload title screen
;13. goto 6

INTROTUNEADDR:	dc.l	0
INTROTUNENAME:	dc.b	'sounds/abreed3d.med',0
				even
TITLESCRNADDR:	dc.l	0
TITLESCRNNAME:	dc.b	'TKG1:includes/titlescrnraw1',0
				even
TITLESCRNNAME2:	dc.b	'TKG2:includes/titlescrnraw1',0
				even
OPTSPRADDR:		dc.l	0
TITLESCRNPTR:	dc.l	0

MASTERPLAYERONEHEALTH:
				dc.w	0
				dc.w	0
MASTERPLAYERONEAMMO:
				ds.w	20

MASTERPLAYERONESHIELD:
				dc.w	0
				dc.w	0
MASTERPLAYERONEGUNS:
				dcb.w	10,0

MASTERPLAYERTWOHEALTH:
				dc.w	0
				dc.w	0
MASTERPLAYERTWOAMMO:
				ds.w	20

MASTERPLAYERTWOSHIELD:
				dc.w	0
				dc.w	0
MASTERPLAYERTWOGUNS:
				dcb.w	10,0

KVALTOASC:
				Dc.b	" `  "," 1  "," 2  "," 3  "
				dc.b	" 4  "," 5  "," 6  "," 7  "
				dc.b	" 8  "," 9  "
; 10
				Dc.b	" 0  "," -  "," +  "," \  "
				dc.b	'    ','    '," Q  "," W  "
				dc.b	" E  "," R  "
; 20
				Dc.b	" T  "," Y  "," U  "," I  "
				dc.b	" O  "," P  "," [  "," ]  "
				dc.b	'    ','KP1 '
; 30
				Dc.b	'KP2 ','KP3 '," A  "," S  "
				dc.b	" D  "," F  "," G  "," H  "
				dc.b	" J  "," K  "
;40
				Dc.b	" L  "," ;  "," #  ",'    '
				dc.b	'    ','KP4 ','KP5 ','KP6 '
				dc.b	'    '," Z  "
;50
				Dc.b	" X  "," C  "," V  "," B  "
				dc.b	" N  "," M  "," ,  "," .  "
				dc.b	" /  ",'    '
;60
				Dc.b	'    ','KP7 ','KP8 ','KP9 '
				dc.b	'SPC ','<-- ','TAB ','ENT '
				dc.b	'RTN ','ESC '
;70
				Dc.b	'DEL ','    ','    ','    '
				dc.b	'KP- ','    ','UCK ','DCK '
				dc.b	'RCK ','LCK '
;80
				Dc.b	'FK1 ','FK2 ','FK3 ','FK4 '
				dc.b	'FK5 ','FK6 ','FK7 ','FK8 '
				dc.b	'FK9 ','FK0 '
;90
				Dc.b	'KP( ','KP) ','KP/ ','KP* '
				dc.b	'KP+ ','HLP ','LSH ','RSH '
				dc.b	'CPL ','CTL '
;100
				Dc.b	'LAL ','RAL ','LAM ','RAM '
				dc.b	'    ','    ','    ','    '
				dc.b	'    ','    '
				Dc.b	'    ','    ','    ','    '
				dc.b	'    ','    ','    ','    '
				dc.b	'    ','    '

				even

FINISHEDLEVEL:	dc.w	0

_IntuitionBase:	dc.l	0

MainScreen:		dc.l	0
MyRaster0		dc.l	0
MyRaster1		dc.l	0

MainScreenTags	dc.l	SA_Width,320
				dc.l	SA_Height,256
				dc.l	SA_Depth,8
				dc.l	SA_BitMap,MainBitmap
				dc.l	SA_Type,CUSTOMSCREEN
				dc.l	SA_Quiet,1
				dc.l	SA_AutoScroll,0
				dc.l	SA_FullPalette,1
				dc.l	TAG_END,0

MainWindowTags	dc.l	WA_Left,0
				dc.l	WA_Top,0
				dc.l	WA_Width,0
				dc.l	WA_Height,0
				dc.l	WA_CustomScreen
MainWTagScreenPtr dc.l	0						; will fill in screen pointer later
				; intution.i states "WA_Flags ;not implemented at present"
				; But I have seen code using it...
				dc.l	WA_Flags,WFLG_ACTIVATE!WFLG_BORDERLESS!WFLG_RMBTRAP!WFLG_SIMPLE_REFRESH!WFLG_BACKDROP!WFLG_NOCAREREFRESH
				; Just to be sure, provide the same info again
				dc.l	WA_Activate,1
				dc.l	WA_Borderless,1
				dc.l	WA_RMBTrap,1			; prevent menu rendering
				dc.l	WA_NoCareRefresh,1
				dc.l	WA_SimpleRefresh,1
				dc.l	WA_Backdrop,1
				dc.l	TAG_END,0

MainWindow		dc.l	0

MainBitmap		dc.w	320/8					; bm_BytesPerRow
				dc.w	256						; bm_Rows
				dc.b	BMF_DISPLAYABLE			; bm_Flags
				dc.b	8						; bm_Depth
				dc.w	0						; bm_Pad
				ds.l	8						; bm_Planes

INTUITION_REV	equ		31						v1.1
int_name		INTNAME
				even


MyAllocRaster:
				move.l	#320,d0					; want all planes in one chunk of memory
				move.l	#(256*8)+1,d1
				CALLGRAF AllocRaster
				tst.l	d0
				rts

START:

				move.b	#'n',mors

				move.l	#doslibname,a1
				moveq	#0,d0
				CALLEXEC OpenLibrary
				move.l	d0,_DOSBase

				moveq	#INTUITION_REV,d0		version
				lea		int_name(pc),a1
				CALLEXEC OpenLibrary
				tst.l	d0
;	beq	exit_false		if failed then quit
				move.l	d0,_IntuitionBase		else save the pointer

				; Open Graphics.library, store old coppper list etc.
				jsr		OpenGraphics

				bsr		MyAllocRaster
;				beq	exit_closeall
				move.l	d0,MyRaster0

				addq.l	#7,d0					; align to 8 byte for FMOD3
				and.l	#~7,d0
				move.l	d0,scrn

				move.l	d0,TEXTSCRN				; FIXME: TEXTSCRN should go

				bsr		MyAllocRaster
;				beq	exit_closeall
				move.l	d0,MyRaster1

				addq.l	#7,d0					; align to 8 byte for FMOD3
				and.l	#~7,d0
				move.l	d0,scrn2

				lea		MainBitmap+bm_Planes,a1
				moveq.l	#7,d1
.storePlanePtr	move.l	d0,(a1)+
				add.l	#(256*(320/8)),d0
				dbra	d1,.storePlanePtr

				sub.l	a0,a0
				lea		MainScreenTags,a1
				CALLINT	OpenScreenTagList
				tst.l	d0
;	beq	exit_closeall		if failed the close both, exit
				move.l	d0,MainScreen

				; need a window to be able to clear out mouse pointer
				; may later also serve as IDCMP input source
				sub.l	a0,a0
				lea		MainWindowTags,a1
				move.l	d0,MainWTagScreenPtr-MainWindowTags(a1) ; WA_CustomScreen
				CALLINT	OpenWindowTagList
				tst.l	d0
;				beq	exit_closeall
				move.l	d0,MainWindow
				move.l	d0,a0
				lea		emptySprite,a1
				moveq	#1,d0
				moveq	#16,d1
				move.l	d0,d2
				move.l	d0,d3
				CALLINT	SetPointer

				move.l	#LINKname,a0
				jsr		LOADAFILE
				move.l	d0,LINKFILE

				move.l	#LEVELTEXTNAME,a0
				jsr		LOADAFILE
				move.l	d0,LEVELTEXT

				jsr		_InitLowLevel

******************************

				;jsr		mnu_start	; For some reason this doesn't work
										; Shows the wrong menu

				jsr		mnu_copycredz
				jsr		mnu_setscreen
				move.l	a7,mnu_mainstack

				jsr		mnu_clearscreen

******************************


**********************************************
				jsr		INITQUEUE
**********************************************

				;move.w	#0,FADEVAL
				;move.w	#31,FADEAMOUNT
				;bsr		FADEUPTITLE

				jsr		LOAD_SFX
				jsr		LOADWALLS
				jsr		LOADFLOOR
				jsr		LOADOBS

				ifeq	CHEESEY
				move.l	#backpicname,a0
				move.l	#BackPicture,d0
				move.l	#0,d1
				jsr		QUEUEFILE
				endc

; jsr _StopPlayer
; jsr _RemPlayer


***********************************************
				jsr		FLUSHQUEUE
***********************************************

				jsr		PATCHSFX

				;move.w	#23,FADEAMOUNT
				;bsr		FADEDOWNTITLE

; bsr ASKFORDISK

				IFNE	CD32VER
				move.l	#115,d1
				CALLDOS	Delay
				ENDC

				bsr		DEFAULTGAME

				jsr		mnu_setscreen
				; jsr mnu_protection

BACKTOMENU:

				jsr		CLEARKEYBOARD


				cmp.b	#'s',mors
				beq.s	BACKTOSLAVE
				cmp.b	#'m',mors
				beq.s	BACKTOMASTER
				bsr		READMAINMENU
				bra		DONEMENU
BACKTOMASTER:
				bsr		MASTERMENU
				bra		DONEMENU
BACKTOSLAVE:
				bsr		SLAVEMENU
DONEMENU:


				jsr		mnu_clearscreen

				;	bsr		WAITREL

				FILTER

				tst.b	SHOULDQUIT
				bne		QUITTT

				clr.b	FINISHEDLEVEL

				move.w	#0,PLR1s_angpos
				move.w	#0,PLR2s_angpos
				move.w	#0,PLR1_angpos
				move.w	#0,PLR2_angpos
				move.b	#0,PLR1_GunSelected
				move.b	#0,PLR2_GunSelected

**************************8
				clr.b	NASTY
***************************

				move.l	#MASTERPLAYERONEHEALTH,a0
				move.l	#MASTERPLAYERONESHIELD,a1
				move.l	#PLAYERONEHEALTH,a2
				move.l	#PLAYERONESHIELD,a3
				move.l	#PLAYERTWOHEALTH,a4
				move.l	#PLAYERTWOSHIELD,a5

				REPT	11
				move.l	(a0),(a2)+
				move.l	(a0)+,(a4)+
				ENDR

				REPT	6
				move.l	(a1),(a3)+
				move.l	(a1)+,(a5)+
				ENDR

*************************************
				jsr		INITQUEUE

				move.l	#borderpacked,d0
				moveq	#0,d1
				move.l	scrn,a0
				lea		WorkSpace,a1
				lea		$0,a2
				jsr		unLHA

				move.l	#borderpacked,d0
				moveq	#0,d1
				move.l	scrn2,a0
				lea		WorkSpace,a1
				lea		$0,a2
				jsr		unLHA

*************************************

				jsr		PLAYTHEGAME

*************************************

				tst.b	FINISHEDLEVEL
				beq		dontusestats

				move.l	#MASTERPLAYERONEHEALTH,a0
				move.l	#MASTERPLAYERONESHIELD,a1
				move.l	#PLAYERONEHEALTH,a2
				move.l	#PLAYERONESHIELD,a3

				REPT	11
				move.l	(a2)+,(a0)+
				ENDR

				REPT	6
				move.l	(a3)+,(a1)+
				ENDR

dontusestats:
				jsr		mnu_setscreen


				bra		BACKTOMENU

QUITTT:
				move.l	LEVELDATA,a1
				move.l	#LEVELDATASize,d0
				CALLEXEC FreeMem

				move.l	FASTBUFFERalloc,a1
				move.l	#FASTBUFFERSize,d0
				CALLEXEC FreeMem

				move.l	MyRaster0,a0
				move.w	#320,d0
				move.w	#256*8+1,d1
				CALLGRAF FreeRaster

				move.l	MyRaster1,a0
				move.w	#320,d0
				move.w	#256*8+1,d1
				CALLGRAF FreeRaster


; jsr RELEASEWALLMEM
				jsr		RELEASESAMPMEM
				jsr		RELEASEFLOORMEM
				jsr		RELEASEOBJMEM

				lea		VBLANKInt,a1
				moveq	#INTB_VERTB,d0
				CALLEXEC RemIntServer

				lea		KEYInt,a1
				moveq	#INTB_PORTS,d0
				CALLEXEC RemIntServer

				move.l	#0,d0

				rts

SSTACK:			dc.l	0

backpicname:	dc.b	"tkg1:includes/rawbackpacked"
				dc.b	0

bordername:		dc.b	"TKG2:includes/newborderRAW",0
				even
borderpacked:	incbin	"includes/newborderpacked"

; KEY OPTIONS:
CONTROLBUFFER:
turn_left_key:
				dc.b	$4f
turn_right_key:
				dc.b	$4e
forward_key:
				dc.b	$11
backward_key:
				dc.b	$21
fire_key:
				dc.b	$63
operate_key:
				dc.b	$23
run_key:
				dc.b	$60
force_sidestep_key:
				dc.b	$64
sidestep_left_key:
				dc.b	$20
sidestep_right_key:
				dc.b	$22
duck_key:
				dc.b	$33
look_behind_key:
				dc.b	$28
jump_key:
				dc.b	$40
look_up_key:
				dc.b	12
look_down_key:
				dc.b	10
centre_view_key:
				dc.b	41
next_weapon_key:
				dc.b	13

templeftkey:	dc.b	0
temprightkey:	dc.b	0
tempslkey:		dc.b	0
tempsrkey:		dc.b	0

				even

GETSTATS:
; CHANGE PASSWORD INTO RAW DATA

				rts


SETPLAYERS:

				move.w	PLOPT,d0
				add.b	#'a',d0
				move.b	d0,LEVA
				move.b	d0,LEVB
				move.b	d0,LEVC
				move.b	d0,LEVD
				move.b	d0,LEVE

				cmp.b	#'s',mors
				beq		SLAVESETUP
				cmp.b	#'m',mors
				beq		MASTERSETUP
				st		NASTY
onepla:
				rts

NASTY:			dc.w	0

MASTERSETUP:
				clr.b	NASTY
				move.w	PLOPT,d0
				jsr		SENDFIRST

				move.w	Rand1,d0
				jsr		SENDFIRST

				bsr		TWOPLAYER
				rts

SLAVESETUP:
				CLR.B	NASTY
				jsr		RECFIRST
				move.w	d0,PLOPT
				add.b	#'a',d0
				move.b	d0,LEVA
				move.b	d0,LEVB
				move.b	d0,LEVC
				move.b	d0,LEVD
				move.b	d0,LEVE

				jsr		RECFIRST
				move.w	d0,Rand1
				bsr		TWOPLAYER


				rts

********************************************************

ASKFORDISK:
;lea RVAL1+300(pc),a0
;lea RVAL2+900(pc),a1
; PRSDD
				move.w	#10,OptScrn
				bsr		DRAWOPTSCRN

ProtChkNLev1:
.wtrel:
				btst	#7,$bfe001
				beq.s	.wtrel

wtclick:
				add.w	#$235,-300(a0)
				add.w	#$4533,-900(a0)
				btst	#6,$bfe001
				bne.s	wtclick

				rts

********************************************************

READMAINMENU:

				move.b	#'n',mors

				move.w	MAXLEVEL,d0


				move.l	#mnu_CURRENTLEVELLINE,a1
				muls	#40,d0
				move.l	LINKFILE,a0
				add.l	#LevelName,a0
				add.l	d0,a0
				bsr		PUTINLINE

; Stay here until 'play game' is selected.

; move.w #0,OptScrn
; bsr DRAWOPTSCRN
; move.w #0,OPTNUM

				lea		mnu_MYMAINMENU,a0
				bsr		MYOPENMENU

.rdlop:
				lea		mnu_MYMAINMENU,a0
				bsr		CHECKMENU

; tst.w d0
; blt.s .rdlop

; tst.w d0
; bne.s .nonextlev
; move.w LEVELSELECTED,d0
; add.w #1,d0
; cmp.w MAXLEVEL,d0
; blt .nowrap
; moveq #0,d0
;.nowrap:
; and.w #$f,d0
; move.w d0,LEVELSELECTED
; move.l #CURRENTLEVELLINE,a1
; muls #40,d0
; move.l #LEVEL_OPTS,a0
; add.l d0,a0
; bsr PUTINLINE
; bsr JUSTDRAWIT
; bra .rdlop

.nonextlev:

				cmp.w	#1,d0
				bne		.noopt

				bra		MASTERMENU

.noopt:

; cmp.w #5,d0
; bne.s .noqui
; st SHOULDQUIT
; bra playgame
;.noqui

				cmp.w	#2,d0
				beq		playgame

				cmp.w	#3,d0
				bne		.nocontrol

				bsr		CHANGECONTROLS

; move.w #0,OptScrn
; bsr DRAWOPTSCRN
; move.w #0,OPTNUM

				lea		mnu_MYMAINMENU,a0
				bsr		MYOPENMENU

				bsr		WAITREL
				bra		.rdlop

.nocontrol:

********************************

				cmp.w	#4,d0
				bne		.nocred
; bsr SHOWCREDITS
; move.w #0,OptScrn
; bsr DRAWOPTSCRN
; move.w #1,OPTNUM
;
; bsr HIGHLIGHT
;
; bsr WAITREL
; bra .rdlop

				;jsr		mnu_viewcredz
				lea		mnu_MYMAINMENU,a0
				bsr		MYOPENMENU

				bra		.rdlop

********************************

.nocred:

				cmp.w	#5,d0
				bne		.noload

				jsr		LOADPOSITION

; move.w #0,OptScrn
; bsr DRAWOPTSCRN
; move.w #1,OPTNUM

				lea		mnu_MYMAINMENU,a0
				bsr		MYOPENMENU

				bsr		WAITREL
				bra		.rdlop

.noload:
				cmp.w	#6,d0
				bne		playgame
				bsr		WAITREL

				jsr		SAVEPOSITION

; move.w #0,OptScrn
; bsr DRAWOPTSCRN
; move.w #1,OPTNUM
;
; bsr HIGHLIGHT

				lea		mnu_MYMAINMENU,a0
				bsr		MYOPENMENU

				bsr		WAITREL
				bra		.rdlop


;
; move.l #PASSWORDLINE+12,a0
; moveq #15,d2
;.clrline:
; move.b #32,(a0)+
; dbra d2,.clrline
; move.w #0,OptScrn
; bsr DRAWOPTSCRN
;
; IFEQ CD32VER
; clr.b lastpressed
; move.l #PASSWORDLINE+12,a0
; move.w #0,d1
;.ENTERPASS:
; tst.b lastpressed
; beq .ENTERPASS
; move.b lastpressed,d2
; move.b #0,lastpressed
; move.l #KVALTOASC,a1
;
; cmp.l #'<-- ',(a1,d2.w*4)
; bne .nodel
;
; tst.b d1
; beq .nodel
;
; subq #1,d1
; move.b #32,-(a0)
; movem.l d0-d7/a0-a6,-(a7)
; bsr JUSTDRAWIT
; movem.l (a7)+,d0-d7/a0-a6
; bra .ENTERPASS
;
;.nodel:
;
; cmp.l #'RTN ',(a1,d2.w*4)
; beq .FORGETIT
; cmp.l #'ESC ',(a1,d2.w*4)
; beq .FORGETIT
; move.b 1(a1,d2.w*4),d2
; cmp.b #65,d2
; blt .ENTERPASS
; cmp.b #'Z',d2
; bgt .ENTERPASS
; move.b d2,(a0)+
; move.w #0,OptScrn
; movem.l d0-d7/a0-a6,-(a7)
; bsr JUSTDRAWIT
; movem.l (a7)+,d0-d7/a0-a6
; add.w #1,d1
; cmp.w #16,d1
; blt .ENTERPASS
;
; ENDC
; IFNE CD32VER
; move.l #PASSWORDLINE+12,a0
; move.w #15,d0
;.ENTERPASS:
; bsr GETACHAR
; dbra d0,.ENTERPASS
; ENDC
;
; bsr PASSLINETOGAME
; tst.w d0
; bne .FORGETIT
;
; bsr GETSTATS
; move.w MAXLEVEL,d0
; move.l #CURRENTLEVELLINE,a1
; muls #40,d0
; move.l #LEVEL_OPTS,a0
; add.l d0,a0
; bsr PUTINLINE
;
;.FORGETIT:
; bsr WAITREL
; bsr CALCPASSWORD
;
; move.w #0,OptScrn
; bsr DRAWOPTSCRN
;
; move.w #1,OPTNUM
;
; bsr HIGHLIGHT
;
; bra .rdlop

playgame:
				move.w	MAXLEVEL,PLOPT
				rts

SHOULDQUIT:		dc.w	0

LEVELSELECTED:
				dc.w	0

				IFNE	CD32VER
GETACHAR:
				moveq	#0,d7
				move.b	#'A',(a0)
				movem.l	d0-d7/a0-a6,-(a7)
				jsr		JUSTDRAWIT
				movem.l	(a7)+,d0-d7/a0-a6

.wtnum:
				btst	#1,_custom+joy1dat
				sne		d1
				btst	#1,_custom+joy1dat+1
				sne		d2
				btst	#0,_custom+joy1dat
				sne		d3
				btst	#0,_custom+joy1dat+1
				sne		d4

				eor.b	d1,d3
				eor.b	d2,d4

				tst.b	d1
				beq.s	.NODELETE
				cmp.w	#15,d0
				beq.s	.NODELETE
				move.b	#32,(a0)
				subq	#1,a0
				addq	#1,d0
				move.b	(a0),d7
				sub.b	#'A',d7
				movem.l	d0-d7/a0-a6,-(a7)
				jsr		JUSTDRAWIT
				movem.l	(a7)+,d0-d7/a0-a6
				jsr		WAITFORNOPRESS
				bra		.wtnum
.NODELETE

				tst.b	d4
				bne.s	.PREVNUM
				tst.b	d3
				bne.s	.NEXTNUM
				btst	#7,$bfe001
				bne.s	.wtnum
				addq	#1,a0
				jsr		WAITFORNOPRESS
				rts

.PREVNUM:
				subq	#1,d7
				bge.s	.nonegg
				moveq	#15,d7
.nonegg:
				move.b	d7,d1
				add.b	#'A',d1
				move.b	d1,(a0)
				movem.l	d0-d7/a0-a6,-(a7)
				jsr		JUSTDRAWIT
				movem.l	(a7)+,d0-d7/a0-a6

				jsr		WAITFORNOPRESS

				bra		.wtnum

.NEXTNUM:
				addq	#1,d7
				cmp.w	#15,d7
				ble.s	.nobigg
				moveq	#0,d7
.nobigg:
				move.b	d7,d1
				add.b	#'A',d1
				move.b	d1,(a0)
				movem.l	d0-d7/a0-a6,-(a7)
				jsr		JUSTDRAWIT
				movem.l	(a7)+,d0-d7/a0-a6
				jsr		WAITFORNOPRESS
				bra		.wtnum
				rts
				ENDC


MASTERMENU:

				move.b	#'m',mors

				move.w	#0,LEVELSELECTED

				move.w	#0,d0
				move.l	#mnu_CURRENTLEVELLINEM,a1
				muls	#40,d0
				move.l	LINKFILE,a0
				add.l	#LevelName,a0
				add.l	d0,a0
				bsr		PUTINLINE

; Stay here until 'play game' is selected.

; move.w #4,OptScrn
; bsr DRAWOPTSCRN
; move.w #1,OPTNUM

; bsr HIGHLIGHT
; bsr WAITREL

				lea		mnu_MYMASTERMENU,a0
				bsr		MYOPENMENU

.rdlop:
				lea		mnu_MYMASTERMENU,a0
				bsr		CHECKMENU
; tst.w d0
; blt.s .rdlop
; bsr WAITREL



				cmp.w	#1,d0
				bne.s	.nonextlev

				move.w	LEVELSELECTED,d0
				add.w	#1,d0
				cmp.w	MAXLEVEL,d0
				blt		.nowrap
				moveq	#0,d0
.nowrap:
; and.w #$f,d0
				move.w	d0,LEVELSELECTED
				move.l	#mnu_CURRENTLEVELLINEM,a1
				muls	#40,d0
				move.l	LINKFILE,a0
				add.l	#LevelName,a0
				add.l	d0,a0
				bsr		PUTINLINE

				lea		mnu_MYMASTERMENU,a0
				jsr		mnu_redraw

				bra		.rdlop

.nonextlev:

				cmp.w	#2,d0
				beq		.playgame

				cmp.w	#0,d0
				bne		.noopt

				bra		SLAVEMENU

.noopt:

				cmp.w	#3,d0
				bne		.nocontrol

				bsr		CHANGECONTROLS

; move.w #4,OptScrn
; bsr DRAWOPTSCRN
; move.w #0,OPTNUM
;
; bsr HIGHLIGHT
;
; bsr WAITREL

				lea		mnu_MYMASTERMENU,a0
				bsr		MYOPENMENU

				bra		.rdlop

.nocontrol:

.playgame

				move.w	LEVELSELECTED,PLOPT
				rts

SLAVEMENU:

				move.b	#'s',mors

; Stay here until 'play game' is selected.

				lea		mnu_MYSLAVEMENU,a0
				bsr		MYOPENMENU

; move.w #5,OptScrn
; bsr DRAWOPTSCRN
; move.w #1,OPTNUM
;
; bsr HIGHLIGHT
;
; bsr WAITREL
.rdlop:
				lea		mnu_MYSLAVEMENU,a0
				bsr		CHECKMENU
				tst.w	d0
				blt.s	.rdlop
				bsr		WAITREL

				cmp.w	#1,d0
				beq		.playgame

				cmp.w	#0,d0
				bne		.noopt

				bra		READMAINMENU

.noopt:

				cmp.w	#2,d0
				bne		.nocontrol

				bsr		CHANGECONTROLS

; move.w #5,OptScrn
; bsr DRAWOPTSCRN
; move.w #0,OPTNUM
;
; bsr HIGHLIGHT
;
; bsr WAITREL

				lea		mnu_MYSLAVEMENU,a0
				bsr		MYOPENMENU


				bra		.rdlop

.nocontrol:
.playgame:

				rts

STATBACK:		ds.w	34

TWOPLAYER:

				move.w	#200,PLAYERONEHEALTH
				move.w	#200,PLAYERTWOHEALTH

				move.w	#0,PLAYERONEFUEL

				st.b	PLAYERONEGUNS+1
				st.b	PLAYERONEGUNS+3
				st.b	PLAYERONEGUNS+5
				st.b	PLAYERONEGUNS+7
				st.b	PLAYERONEGUNS+9
				st.b	PLAYERONEGUNS+11
				st.b	PLAYERONEGUNS+13
				st.b	PLAYERONEGUNS+15
				st.b	PLAYERONEGUNS+17
				st.b	PLAYERONEGUNS+19

				st.b	PLAYERONEJETPACK+1

				st.b	PLAYERTWOGUNS+1
				st.b	PLAYERTWOGUNS+3
				st.b	PLAYERTWOGUNS+5
				st.b	PLAYERTWOGUNS+7
				st.b	PLAYERTWOGUNS+9
				st.b	PLAYERTWOGUNS+11
				st.b	PLAYERTWOGUNS+13
				st.b	PLAYERTWOGUNS+15
				st.b	PLAYERTWOGUNS+17
				st.b	PLAYERTWOGUNS+19

				move.w	#0,PLAYERTWOFUEL

				st.b	PLAYERTWOJETPACK+1

				move.l	#PLAYERONEAMMO,a0
				move.l	#PLAYERTWOAMMO,a1
				move.w	#19,d1
.putinvals
				jsr		GetRand
				and.w	#63,d0
				add.w	#5,d0
				move.w	d0,(a0)+
				move.w	d0,(a1)+
				dbra	d1,.putinvals

				rts

				move.w	#0,OldEnergy
				move.w	#127,Energy
				jsr		EnergyBar

				move.w	#63,OldAmmo
				move.w	#0,Ammo
				jsr		AmmoBar
				move.w	#0,OldAmmo

				move.b	#0,PLR1_GunSelected

				move.b	#0,PLR2_GunSelected
				rts

newdum:
				rts

DEFAULTGAME:
				move.w	#0,MAXLEVEL

				move.l	#MASTERPLAYERONEHEALTH,a0
				move.l	#MASTERPLAYERONESHIELD,a1
				move.l	#0,(a0)+
				move.l	#0,(a0)+
				move.l	#0,(a0)+
				move.l	#0,(a0)+
				move.l	#0,(a0)+
				move.l	#0,(a0)+
				move.l	#0,(a0)+
				move.l	#0,(a0)+
				move.l	#0,(a0)+
				move.l	#0,(a0)+
				move.l	#0,(a0)+

				move.l	#0,(a1)+
				move.l	#0,(a1)+
				move.l	#0,(a1)+
				move.l	#0,(a1)+
				move.l	#0,(a1)+
				move.l	#0,(a1)+

				move.w	#200,MASTERPLAYERONEHEALTH
				move.w	#$ff,MASTERPLAYERONEGUNS

				move.l	LINKFILE,a5
				add.l	#GunBulletTypes,a5
				move.w	(a5),d0

				move.l	#MASTERPLAYERONEAMMO,a5
				move.w	#20,(a5,d0.w*2)

				rts

CHKPROT:		dc.w	0

GETPARITY:
				move.w	#6,d3
.calcparity:
				btst	d3,d0
				beq.s	.nochange
				bchg	#7,d0
.nochange:
				dbra	d3,.calcparity
				rts

CHECKPARITY:
				move.w	#6,d3
				move.b	#$0,d2
.calcparity:
				btst	d3,d0
				beq.s	.nochange
				bchg	#7,d2
.nochange:
				dbra	d3,.calcparity
				move.b	d0,d1
				and.b	#$80,d1
				eor.b	d1,d2
				sne		d5
				rts

CALCPASSWORD:
				rts

PASSLINETOGAME:
				rts

illega:

				move.w	#-1,d0

				rts

PASSBUFFER:
				ds.b	8

CHECKBUFFER:	ds.b	8

PASS:
				ds.b	16

**************************************************

CHANGECONTROLS:

; move.w #6,OptScrn
; bsr DRAWOPTSCRN
; move.w #0,OPTNUM
; bsr HIGHLIGHT
; bsr WAITREL

; copy current setting over to menu
				move.l	#CONTROLBUFFER,a0
				move.l	#KEY_LINES+17,a1
				moveq	#10,d1
.copykeys
				move.b	(a0)+,d0
				add.b	#132,d0
				move.b	d0,(a1)
				add.l	#21,a1
				dbra	d1,.copykeys

				move.l	#KEY_LINES2+17,a1
				moveq	#5,d1
.copykeys2
				move.b	(a0)+,d0
				add.b	#132,d0
				move.b	d0,(a1)
				add.l	#21,a1
				dbra	d1,.copykeys2

				lea		mnu_MYCONTROLSONE,a0
				bsr		MYOPENMENU

.rdlop:
				lea		mnu_MYCONTROLSONE,a0
				bsr		CHECKMENU

; tst.w d0
; blt.s .rdlop

				cmp.w	#11,d0
				beq		CHANGECONTROLS2

				move.l	#KEY_LINES,a0
				move.w	d0,d1
				muls	#21,d1
				add.l	d1,a0
				add.w	#16,a0
				move.w	#$2020,(a0)



				movem.l	a0/d0,-(a7)

				lea		mnu_MYCONTROLSONE,a0
				jsr		mnu_redraw

*********************************************
				move.l	#mnu_buttonanim,mnu_frameptr
				jsr		mnu_getrawvalue
				move.l	#mnu_cursanim,mnu_frameptr
***********************************************

				move.l	#CONTROLBUFFER,a1
				moveq	#0,d1
				move.b	d0,d1

				movem.l	(a7)+,d0/a0

				move.b	d1,(a1,d0.w)
; move.l #KVALTOASC,a1
				add.w	#132,d1
				move.b	d1,1(a0)
; move.l (a1,d1.w*4),(a0)
; bsr JUSTDRAWIT
; bsr WAITREL
				lea		mnu_MYCONTROLSONE,a0
				jsr		mnu_redraw
				bra		.rdlop

.backtomain:
				rts


CHANGECONTROLS2:
				lea		mnu_MYCONTROLSTWO,a0
				bsr		MYOPENMENU

.rdlop:
				lea		mnu_MYCONTROLSTWO,a0
				bsr		CHECKMENU

; tst.w d0
; blt.s .rdlop

				cmp.w	#6,d0
				beq		.backtomain

				move.l	#KEY_LINES2,a0
				move.w	d0,d1
				muls	#21,d1
				add.l	d1,a0
				add.w	#16,a0
				move.w	#$2020,(a0)

				movem.l	a0/d0,-(a7)

				lea		mnu_MYCONTROLSTWO,a0
				jsr		mnu_redraw

**********************************************
				move.l	#mnu_buttonanim,mnu_frameptr
				jsr		mnu_getrawvalue
				move.l	#mnu_cursanim,mnu_frameptr
***********************************************

				move.l	#CONTROLBUFFER+11,a1
				moveq	#0,d1
				move.b	d0,d1

				movem.l	(a7)+,d0/a0

				move.b	d1,(a1,d0.w)
; move.l #KVALTOASC,a1
				add.w	#132,d1
				move.b	d1,1(a0)
; move.l (a1,d1.w*4),(a0)
; bsr JUSTDRAWIT
; bsr WAITREL
				lea		mnu_MYCONTROLSTWO,a0
				jsr		mnu_redraw
				bra		.rdlop

.backtomain:
				rts
				rts

**************************************************


MAXLEVEL:		dc.w	0

SHOWCREDITS:
				move.w	#2,OptScrn
				bsr		DRAWOPTSCRN
				move.w	#0,OPTNUM
				bsr		HIGHLIGHT

				bsr		WAITREL

.rdlop:
				bsr		CHECKMENU
				tst.w	d0
				blt.s	.rdlop

				bra		READMAINMENU

HELDDOWN:
				dc.w	0

WAITREL:

				movem.l	d0/d1/d2/d3,-(a7)

				move.l	#KeyMap,a5
WAITREL2:
				btst	#7,$bfe001
				beq.s	WAITREL2

				IFEQ	CD32VER
				tst.b	$40(a5)
				bne.s	WAITREL2
				tst.b	$44(a5)
				bne.s	WAITREL2
				tst.b	$4c(a5)
				bne.s	WAITREL2
				tst.b	$4d(a5)
				bne.s	WAITREL2
				ENDC

				btst	#1,_custom+joy1dat
				sne		d0
				btst	#1,_custom+joy1dat+1
				sne		d1
				btst	#0,_custom+joy1dat
				sne		d2
				btst	#0,_custom+joy1dat+1
				sne		d3

				eor.b	d0,d2
				eor.b	d1,d3
				tst.b	d2
				bne.s	WAITREL2
				tst.b	d3
				bne.s	WAITREL2


				movem.l	(a7)+,d0/d1/d2/d3
				rts

PUTINLINE:
				moveq	#19,d0
pill
				move.b	(a0)+,(a1)+
				dbra	d0,pill
				rts

MYOPENMENU:
.redraw:		move.l	a0,-(a7)
				jsr		mnu_openmenu			; Open new menu
				move.l	(a7)+,a0
				rts

CHECKMENU:

				move.b	#0,lastpressed

.loop:			movem.l	a0,-(a7)
				jsr		mnu_update
				movem.l	(a7)+,a0
				move.l	a0,-(a7)
				jsr		mnu_waitmenu			; Wait for option
				move.l	(a7)+,a0
				moveq.l	#0,d2
				move.w	mnu_row,d2
				divu	14(a0),d2
				swap.w	d2
				move.w	d2,mnu_currentsel

				move.w	d2,d0					; option number

				rts

HIGHLIGHT:

				SAVEREGS

				move.w	OptScrn,d0
				move.l	#MENUDATA,a0
				move.l	4(a0,d0.w*8),a0
				move.w	OPTNUM,d0
				lea		(a0,d0.w*8),a0
				move.w	(a0)+,d0				;left
				move.w	(a0)+,d1				;top
				move.w	(a0)+,d2				;width

				muls	#16*8,d1
				move.l	OPTSPRADDR,a1
				add.w	d1,a1
				add.w	#8+16,a1
				move.l	#SCRTOSPR2,a5
				adda.w	d0,a5
				adda.w	d0,a5

NOTLOP:

				move.w	(a5)+,d3
				lea		(a1,d3.w),a2
				not.b	(a2)
				not.b	16(a2)
				not.b	32(a2)
				not.b	48(a2)
				not.b	64(a2)
				not.b	80(a2)
				not.b	96(a2)
				not.b	112(a2)
				not.b	128(a2)
				subq	#1,d2
				bgt.s	NOTLOP

				GETREGS
				rts

SCRTOSPR2:
val				SET		0
				REPT	6
				dc.w	val+0
				dc.w	val+1
				dc.w	val+2
				dc.w	val+3
				dc.w	val+4
				dc.w	val+5
				dc.w	val+6
				dc.w	val+7
val				SET		val+258*16
				ENDR

CLROPTSCRN:

; move.l #$2cdfea,d0
; move.w (a4,d0.l),d0
; add.w d0,RVAL2

				move.l	OPTSPRADDR,a0
				lea		16(a0),a1
				lea		16+(258*16)(a0),a2
				lea		16+(258*16*2)(a0),a3
				lea		16+(258*16*3)(a0),a4
				lea		258*16(a4),a0

				move.w	#256,d0
				moveq	#0,d1
CLRLOP:
				move.l	d1,(a0)+
				move.l	d1,(a0)+
				move.l	d1,(a0)+
				move.l	d1,(a0)+
				move.l	d1,(a1)+
				move.l	d1,(a1)+
				move.l	d1,(a1)+
				move.l	d1,(a1)+
				move.l	d1,(a2)+
				move.l	d1,(a2)+
				move.l	d1,(a2)+
				move.l	d1,(a2)+
				move.l	d1,(a3)+
				move.l	d1,(a3)+
				move.l	d1,(a3)+
				move.l	d1,(a3)+
				move.l	d1,(a4)+
				move.l	d1,(a4)+
				move.l	d1,(a4)+
				move.l	d1,(a4)+
				dbra	d0,CLRLOP

				move.l	OPTSPRADDR,a0
				move.w	#44*256+64,(a0)
				move.w	#44*256+2,8(a0)
				add.l	#258*16,a0

				move.w	#44*256+96,(a0)
				move.w	#44*256+2,8(a0)
				add.l	#258*16,a0

				move.w	#44*256+128,(a0)
				move.w	#44*256+2,8(a0)
				add.l	#258*16,a0

				move.w	#44*256+160,(a0)
				move.w	#44*256+2,8(a0)
				add.l	#258*16,a0

				move.w	#44*256+192,(a0)
				move.w	#44*256+2,8(a0)

				rts

DRAWOPTSCRN:
				rts

				bsr		CLROPTSCRN

JUSTDRAWIT:

				move.l	#font,a0
				move.l	#MENUDATA,a1
				move.w	OptScrn,d0
				move.l	(a1,d0.w*8),a1

				move.l	OPTSPRADDR,a3
				add.l	#16,a3
				moveq	#0,d2

				move.w	#31,d0
linelop:
				move.w	#39,d1
				move.l	#SCRTOSPR,a4
				move.l	a3,a2
charlop:
				move.b	(a1)+,d2
				lea		(a0,d2.w*8),a5
				move.b	(a5)+,(a2)
				move.b	(a5)+,16(a2)
				move.b	(a5)+,32(a2)
				move.b	(a5)+,48(a2)
				move.b	(a5)+,64(a2)
				move.b	(a5)+,80(a2)
				move.b	(a5)+,96(a2)
				move.b	(a5),112(a2)
				add.w	(a4)+,a2
				dbra	d1,charlop
				add.w	#16*8,a3
				dbra	d0,linelop

				rts

SCRTOSPR:
				dc.w	1,1,1,1,1,1,1,258*16-7
				dc.w	1,1,1,1,1,1,1,258*16-7
				dc.w	1,1,1,1,1,1,1,258*16-7
				dc.w	1,1,1,1,1,1,1,258*16-7
				dc.w	1,1,1,1,1,1,1,258*16-7
				dc.w	1,1,1,1,1,1,1,258*16-7

OPTNUM:			dc.w	0
OptScrn:		dc.w	0

SAVEGAMENAME:	dc.b	"tkg2:boot.dat",0
				even

SAVEGAMEPOS:	dc.l	0
SAVEGAMELEN:	dc.l	0

LOADPOSITION:

				move.l	#SAVEGAMENAME,a0
				move.l	#SAVEGAMEPOS,d0
				move.l	#SAVEGAMELEN,d1
				jsr		INITQUEUE
				jsr		QUEUEFILE
				jsr		FLUSHQUEUE

				move.l	SAVEGAMEPOS,a2			; address of first saved game.

				move.l	#mnu_LSLOTA+21,a4

				move.l	a2,a3
				add.w	#2+(22*2)+(12*2),a3
				move.w	#4,d7
.findlevs:

				move.l	a4,a1
				move.w	(a3),d1
				muls	#40,d1
				move.l	LINKFILE,a0
				add.l	#LevelName,a0
				add.l	d1,a0
				jsr		PUTINLINE
				add.l	#21,a4
				add.w	#2+(22*2)+(12*2),a3

				dbra	d7,.findlevs

; move.w #8,OptScrn
; move.w #0,OPTNUM

; bsr DRAWOPTSCRN
; bsr HIGHLIGHT
; bsr WAITREL

				lea		mnu_MYLOADMENU,a0
				bsr		MYOPENMENU

.rdlop:
				lea		mnu_MYLOADMENU,a0
				bsr		CHECKMENU

				cmp.w	#6,d0
				beq.s	.noload

				move.l	SAVEGAMEPOS,a0
				muls	#2+(22*2)+(12*2),d0
				add.l	d0,a0

				move.l	#MASTERPLAYERONEHEALTH,a1
				move.w	(a0)+,MAXLEVEL

				REPT	11
				move.l	(a0)+,(a1)+
				ENDR
				REPT	6
				move.l	(a0)+,(a1)+
				ENDR

				move.w	MAXLEVEL,d0
				move.l	#mnu_CURRENTLEVELLINE,a1
				muls	#40,d0
				move.l	LINKFILE,a0
				add.l	#LevelName,a0
				add.l	d0,a0
				bsr		PUTINLINE

.noload:

				move.l	SAVEGAMEPOS,a1
				move.l	SAVEGAMELEN,d0
				CALLEXEC FreeMem

				rts

SAVEPOSITION:

				move.l	#SAVEGAMENAME,a0
				move.l	#SAVEGAMEPOS,d0
				move.l	#SAVEGAMELEN,d1
				jsr		INITQUEUE
				jsr		QUEUEFILE
				jsr		FLUSHQUEUE

				move.l	SAVEGAMEPOS,a2			; address of first saved game.

				add.w	#2+(22*2)+(12*2),a2

				move.l	#mnu_SSLOTA,a4

				move.l	a2,a3
				move.w	#4,d7
.findlevs:

				move.l	a4,a1
				move.w	(a3),d1
				muls	#40,d1
				move.l	LINKFILE,a0
				add.l	#LevelName,a0
				add.l	d1,a0
				jsr		PUTINLINE
				add.l	#21,a4
				add.w	#2+(22*2)+(12*2),a3

				dbra	d7,.findlevs

; move.w #9,OptScrn
; move.w #0,OPTNUM

; bsr DRAWOPTSCRN
; bsr HIGHLIGHT
; bsr WAITREL

				lea		mnu_MYSAVEMENU,a0
				bsr		MYOPENMENU

.rdlop:
				lea		mnu_MYSAVEMENU,a0
				bsr		CHECKMENU

				cmp.w	#5,d0
				beq		.nosave

				move.l	d0,-(a7)

				move.l	(a7)+,d0

				addq	#1,d0

				move.l	SAVEGAMEPOS,a0
				muls	#2+(22*2)+(12*2),d0
				add.l	d0,a0

				move.l	#MASTERPLAYERONEHEALTH,a1
				move.w	MAXLEVEL,(a0)+

				REPT	11
				move.l	(a1)+,(a0)+
				ENDR
				REPT	6
				move.l	(a1)+,(a0)+
				ENDR

				move.l	#SAVEGAMENAME,d1
				move.l	#1006,d2
				CALLDOS	Open
				move.l	d0,handle

				move.l	SAVEGAMEPOS,d2
				move.l	handle,d1
				move.l	SAVEGAMELEN,d3
				CALLDOS	Write

				move.l	handle,d1
				CALLDOS	Close

;				move.l	#200,d1
;				CALLDOS	Delay

.nosave:

				move.l	SAVEGAMEPOS,a1
				move.l	SAVEGAMELEN,d0
				CALLEXEC FreeMem

				rts

MENUDATA:
;0
				dc.l	ONEPLAYERMENU_TXT
				dc.l	ONEPLAYERMENU_OPTS
;1
				dc.l	INSTRUCTIONS_TXT
				dc.l	INSTRUCTIONS_OPTS
;2
				dc.l	CREDITMENU_TXT
				dc.l	CREDITMENU_OPTS
;3
				dc.l	ASKFORDISK_TXT
				dc.l	ASKFORDISK_OPTS
;4
; dc.l ONEPLAYERMENU_TXT
; dc.l ONEPLAYERMENU_OPTS
				dc.l	MASTERPLAYERMENU_TXT
				dc.l	MASTERPLAYERMENU_OPTS
;5
				dc.l	SLAVEPLAYERMENU_TXT
				dc.l	SLAVEPLAYERMENU_OPTS
;6
				dc.l	CONTROL_TXT
				dc.l	CONTROL_OPTS
;7
				dc.l	PROTMENU_TXT
				dc.l	CONTROL_OPTS
;8
				dc.l	LOADMENU_TXT
				dc.l	LOADMENU_OPTS
;9
				dc.l	SAVEMENU_TXT
				dc.l	SAVEMENU_OPTS
;10
				dc.l	LEVELDISK_TXT
				dc.l	ASKFORDISK_OPTS


EMPTYSLOTNAME:
;      0123456789012345678901234567890123456789
				dc.b	'               EMPTY SLOT               '

LOADMENU_TXT:
;      0123456789012345678901234567890123456789
				dc.b	'                                        ' ;0
				dc.b	'                                        ' ;1
				dc.b	'                                        ' ;2
				dc.b	'                                        ' ;3
				dc.b	'         LOAD A SAVED POSITION:         ' ;4
				dc.b	'                                        ' ;5
				dc.b	'                                        ' ;6
				dc.b	'                                        ' ;7
				dc.b	'                                        ' ;8
LSLOTA:
				dc.b	'                                        ' ;9
				dc.b	'                                        ' ;0
LSLOTB:
				dc.b	'                                        ' ;1
				dc.b	'                                        ' ;2
LSLOTC:
				dc.b	'                                        ' ;3
				dc.b	'                                        ' ;4
LSLOTD:
				dc.b	'                                        ' ;5
				dc.b	'                                        ' ;6
LSLOTE:
				dc.b	'                                        ' ;7
				dc.b	'                                        ' ;8
LSLOTF:
				dc.b	'                                        ' ;9
				dc.b	'                                        ' ;0
				dc.b	'               * CANCEL *               ' ;1
				dc.b	'                                        ' ;2
				dc.b	'                                        ' ;3
				dc.b	'                                        ' ;4
				dc.b	'                                        ' ;5
				dc.b	'                                        ' ;6
				dc.b	'                                        ' ;7
				dc.b	'                                        ' ;8
				dc.b	'                                        ' ;9
				dc.b	'                                        ' ;0
				dc.b	'                                        ' ;1

LOADMENU_OPTS:
				dc.w	0,9,40,1
				dc.w	0,11,40,1
				dc.w	0,13,40,1
				dc.w	0,15,40,1
				dc.w	0,17,40,1
				dc.w	0,19,40,1
				dc.w	14,21,12,1
				dc.w	-1

LEVELDISK_TXT:
;      0123456789012345678901234567890123456789
				dc.b	'                                        ' ;0
				dc.b	'                                        ' ;0
				dc.b	'                                        ' ;0
				dc.b	'                                        ' ;0
				dc.b	'                                        ' ;0
				dc.b	'                                        ' ;0
				dc.b	'                                        ' ;0
				dc.b	'                                        ' ;0
				dc.b	'                                        ' ;0
				dc.b	'                                        ' ;0
				dc.b	'                                        ' ;0
				dc.b	'  IF PLAYING FROM DISK, PLEASE INSERT   ' ;0
				dc.b	'       LEVELS DISK IN DRIVE DF0:        ' ;0
				dc.b	'                                        ' ;0
				dc.b	'     PRESS MOUSE BUTTON WHEN READY..    ' ;0
				dc.b	'                                        ' ;0
				dc.b	'                                        ' ;0
				dc.b	'                                        ' ;0
				dc.b	'                                        ' ;0
				dc.b	'                                        ' ;0
				dc.b	'                                        ' ;0
				dc.b	'                                        ' ;0
				dc.b	'                                        ' ;0
				dc.b	'                                        ' ;0
				dc.b	'                                        ' ;0
				dc.b	'                                        ' ;0
				dc.b	'                                        ' ;0
				dc.b	'                                        ' ;0
				dc.b	'                                        ' ;0
				dc.b	'                                        ' ;0
				dc.b	'                                        ' ;0
				dc.b	'                                        ' ;0


SAVEMENU_TXT:
;      0123456789012345678901234567890123456789
				dc.b	'                                        ' ;0
				dc.b	'                                        ' ;1
				dc.b	'                                        ' ;2
				dc.b	'                                        ' ;3
				dc.b	'         SAVE CURRENT POSITION:         ' ;4
				dc.b	'                                        ' ;5
				dc.b	'                                        ' ;6
				dc.b	'                                        ' ;7
				dc.b	'                                        ' ;8
SSLOTA:
				dc.b	'                                        ' ;9
				dc.b	'                                        ' ;0
SSLOTB:
				dc.b	'                                        ' ;1
				dc.b	'                                        ' ;2
SSLOTC:
				dc.b	'                                        ' ;3
				dc.b	'                                        ' ;4
SSLOTD:
				dc.b	'                                        ' ;5
				dc.b	'                                        ' ;6
SSLOTE:
				dc.b	'                                        ' ;7
				dc.b	'                                        ' ;8
SSLOTF:
				dc.b	'                                        ' ;9
				dc.b	'                                        ' ;0
				dc.b	'               * CANCEL *               ' ;1
				dc.b	'                                        ' ;2
				dc.b	'                                        ' ;3
				dc.b	'                                        ' ;4
				dc.b	'                                        ' ;5
				dc.b	'                                        ' ;6
				dc.b	'                                        ' ;7
				dc.b	'                                        ' ;8
				dc.b	'                                        ' ;9
				dc.b	'                                        ' ;0
				dc.b	'                                        ' ;1

SAVEMENU_OPTS:
				dc.w	0,9,40,1
				dc.w	0,11,40,1
				dc.w	0,13,40,1
				dc.w	0,15,40,1
				dc.w	0,17,40,1
				dc.w	0,19,40,1
				dc.w	14,21,12,1
				dc.w	-1


ASKFORDISK_TXT:
;      0123456789012345678901234567890123456789
				dc.b	'                                        ' ;0
				dc.b	'                                        ' ;1
				dc.b	'                                        ' ;2
				dc.b	'                                        ' ;3
				dc.b	'                                        ' ;4
				dc.b	'                                        ' ;5
				dc.b	'                                        ' ;6
				dc.b	'                                        ' ;7
				dc.b	'                                        ' ;8
				dc.b	'                                        ' ;9
				dc.b	'                                        ' ;0
				dc.b	'                                        ' ;1
				dc.b	'                                        ' ;2
				dc.b	'         PLEASE INSERT VOLUME:          ' ;3
				dc.b	'                                        ' ;4
VOLLINE:
				dc.b	'                                        ' ;9
				dc.b	'                                        ' ;9
				dc.b	'          PRESS MOUSE BUTTON            ' ;5
				dc.b	'          WHEN DISK ACTIVITY            ' ;6
				dc.b	'               FINISHES                 ' ;7
				dc.b	'                                        ' ;8
				dc.b	'                                        ' ;1
				dc.b	'                                        ' ;2
				dc.b	'                                        ' ;3
				dc.b	'                                        ' ;4
				dc.b	'                                        ' ;5
				dc.b	'                                        ' ;6
				dc.b	'                                        ' ;7
				dc.b	'                                        ' ;8
				dc.b	'                                        ' ;9
				dc.b	'                                        ' ;0
				dc.b	'                                        ' ;1

ASKFORDISK_OPTS:
				dc.w	-1


ONEPLAYERMENU_TXT:
;      0123456789012345678901234567890123456789
				dc.b	'                                        ' ;0
				dc.b	'                                        ' ;1
				dc.b	'                                        ' ;2
				dc.b	'                                        ' ;3
				dc.b	'                                        ' ;4
				dc.b	'                                        ' ;5
				dc.b	'                                        ' ;6
				dc.b	'                                        ' ;7
				dc.b	'                                        ' ;8
				dc.b	'                                        ' ;9
				dc.b	'                                        ' ;0
CURRENTLEVELLINE:
				dc.b	'         *** A.F DEMO LEVEL ***         ' ;1
				dc.b	'                                        ' ;2
				dc.b	'                1 PLAYER                ' ;3
				dc.b	'                                        ' ;4
				dc.b	'               PLAY  GAME               ' ;5
				dc.b	'                                        ' ;6
				dc.b	'            CONTROL  OPTIONS            ' ;7
				dc.b	'                                        ' ;8
				dc.b	'              GAME CREDITS              ' ;9
				dc.b	'                                        ' ;0
				dc.b	'             LOAD  POSITION             ' ;1
				dc.b	'                                        ' ;2
PASSWORDLINE:
				dc.b	'             SAVE  POSITION             ' ;1
				dc.b	'                                        ' ;4
				dc.b	'                                        ' ;6
				dc.b	'                                        ' ;6
				dc.b	'                                        ' ;7
				dc.b	'                                        ' ;8
				dc.b	'                                        ' ;9
				dc.b	'                                        ' ;0
				dc.b	'                                        ' ;1

ONEPLAYERMENU_OPTS:
				dc.w	0,11,40,1
				dc.w	16,13,8,1
				dc.w	15,15,10,1
				dc.w	12,17,16,1
				dc.w	14,19,12,1
				dc.w	12,21,16,1
				dc.w	12,23,16,1
				dc.w	-1


MASTERPLAYERMENU_TXT:
;      0123456789012345678901234567890123456789
				dc.b	'                                        ' ;0
				dc.b	'                                        ' ;1
				dc.b	'                                        ' ;2
				dc.b	'                                        ' ;3
				dc.b	'                                        ' ;4
				dc.b	'                                        ' ;5
				dc.b	'                                        ' ;6
				dc.b	'                                        ' ;7
				dc.b	'                                        ' ;8
				dc.b	'                                        ' ;9
				dc.b	'                                        ' ;0
				dc.b	'                                        ' ;1
				dc.b	'            2 PLAYER  MASTER            ' ;2
				dc.b	'                                        ' ;3
CURRENTLEVELLINEM:
				dc.b	'           LEVEL 1 : THE GATE           ' ;4
				dc.b	'                                        ' ;5
				dc.b	'               PLAY  GAME               ' ;6
				dc.b	'                                        ' ;7
				dc.b	'            CONTROL  OPTIONS            ' ;8
				dc.b	'                                        ' ;9
				dc.b	'                                        ' ;0
				dc.b	'                                        ' ;1
				dc.b	'                                        ' ;2
				dc.b	'                                        ' ;3
				dc.b	'                                        ' ;4
				dc.b	'                                        ' ;5
				dc.b	'                                        ' ;6
				dc.b	'                                        ' ;7
				dc.b	'                                        ' ;8
				dc.b	'                                        ' ;9
				dc.b	'                                        ' ;0
				dc.b	'                                        ' ;1

MASTERPLAYERMENU_OPTS:
				dc.w	12,12,16,1
				dc.w	6,14,28,1
				dc.w	15,16,10,1
				dc.w	12,18,16,1
				dc.w	-1

SLAVEPLAYERMENU_TXT:
;      0123456789012345678901234567890123456789
				dc.b	'                                        ' ;0
				dc.b	'                                        ' ;1
				dc.b	'                                        ' ;2
				dc.b	'                                        ' ;3
				dc.b	'                                        ' ;4
				dc.b	'                                        ' ;5
				dc.b	'                                        ' ;6
				dc.b	'                                        ' ;7
				dc.b	'                                        ' ;8
				dc.b	'                                        ' ;9
				dc.b	'                                        ' ;9
				dc.b	'                                        ' ;1
				dc.b	'             2 PLAYER SLAVE             ' ;4
				dc.b	'                                        ' ;3
				dc.b	'               PLAY  GAME               ' ;2
				dc.b	'                                        ' ;5
				dc.b	'            CONTROL  OPTIONS            ' ;0
				dc.b	'                                        ' ;1
				dc.b	'                                        ' ;3
				dc.b	'                                        ' ;7
				dc.b	'                                        ' ;7
				dc.b	'                                        ' ;3
				dc.b	'                                        ' ;3
				dc.b	'                                        ' ;3
				dc.b	'                                        ' ;4
				dc.b	'                                        ' ;5
				dc.b	'                                        ' ;6
				dc.b	'                                        ' ;7
				dc.b	'                                        ' ;9
				dc.b	'                                        ' ;9
				dc.b	'                                        ' ;9
				dc.b	'                                        ' ;9


PROTMENU_TXT:
;      0123456789012345678901234567890123456789
				dc.b	'                                        ' ;0
				dc.b	'                                        ' ;1
				dc.b	'                                        ' ;2
				dc.b	'                                        ' ;3
				dc.b	'                                        ' ;4
				dc.b	'                                        ' ;5
				dc.b	'                                        ' ;6
				dc.b	'                                        ' ;7
				dc.b	'                                        ' ;8
				dc.b	'                                        ' ;9
				dc.b	'                                        ' ;0
				dc.b	'                                        ' ;1
				dc.b	' TYPE IN THREE DIGIT CODE FROM MANUAL : ' ;2
				dc.b	'                                        ' ;3
PROTLINE:
				dc.b	'        TABLE 00 ROW 00 COLUMN 00       ' ;4
				dc.b	'                                        ' ;5
				dc.b	'                                        ' ;6
				dc.b	'                                        ' ;7
				dc.b	'                                        ' ;8
				dc.b	'                                        ' ;9
				dc.b	'                                        ' ;0
				dc.b	'                                        ' ;1
				dc.b	'                                        ' ;2
				dc.b	'                                        ' ;3
				dc.b	'                                        ' ;4
				dc.b	'                                        ' ;5
				dc.b	'                                        ' ;6
				dc.b	'                                        ' ;7
				dc.b	'                                        ' ;9
				dc.b	'                                        ' ;0
				dc.b	'                                        ' ;1



SLAVEPLAYERMENU_OPTS:
				dc.w	12,12,16,1
				dc.w	15,14,10,1
				dc.w	12,16,16,1
				dc.w	-1


PLAYER_OPTS:
;      0123456789012345678901234567890123456789
				dc.b	'                 1 PLAYER               '
				dc.b	'             2  PLAYER MASTER           '
				dc.b	'              2 PLAYER SLAVE            '

LEVEL_OPTS:
;      0123456789012345678901234567890123456789
				dc.b	'       CU AMIGA *EXCLUSIVE* DEMO        '
				dc.b	'      LEVEL  2 :       STORAGE BAY      '
				dc.b	'      LEVEL  3 :     SEWER NETWORK      '
				dc.b	'      LEVEL  4 :     THE COURTYARD      '
				dc.b	'      LEVEL  5 :      SYSTEM PURGE      '
				dc.b	'      LEVEL  6 :         THE MINES      '
				dc.b	'      LEVEL  7 :       THE FURNACE      '
				dc.b	'      LEVEL  8 :  TEST ARENA GAMMA      '
				dc.b	'      LEVEL  9 :      SURFACE ZONE      '
				dc.b	'      LEVEL 10 :     TRAINING AREA      '
				dc.b	'      LEVEL 11 :       ADMIN BLOCK      '
				dc.b	'      LEVEL 12 :           THE PIT      '
				dc.b	'      LEVEL 13 :            STRATA      '
				dc.b	'      LEVEL 14 :      REACTOR CORE      '
				dc.b	'      LEVEL 15 :     COOLING TOWER      '
				dc.b	'      LEVEL 16 :    COMMAND CENTRE      '

CONTROL_TXT:
;      0123456789012345678901234567890123456789
				dc.b	'                                        ' ;0
				dc.b	'                                        ' ;1
				dc.b	'            DEFINE  CONTROLS            ' ;2
				dc.b	'                                        ' ;3
;KEY_LINES:
				dc.b	'     TURN LEFT                  LCK     ' ;4
				dc.b	'     TURN RIGHT                 RCK     ' ;5
				dc.b	'     FORWARDS                   UCK     ' ;6
				dc.b	'     BACKWARDS                  DCK     ' ;7
				dc.b	'     FIRE                       RAL     ' ;8
				dc.b	'     OPERATE DOOR/LIFT/SWITCH   SPC     ' ;9
				dc.b	'     RUN                        RSH     ' ;0
				dc.b	'     FORCE SIDESTEP             RAM     ' ;1
				dc.b	'     SIDESTEP LEFT               .      ' ;2
				dc.b	'     SIDESTEP RIGHT              /      ' ;3
				dc.b	'     DUCK                        D      ' ;4
				dc.b	'     LOOK BEHIND                 L      ' ;5
				dc.b	'     JUMP                       KP0     ' ;6
				dc.b	'     LOOK UP                     ]      ' ;7
				dc.b	'     LOOK DOWN                   #      ' ;8
				dc.b	'     CENTRE VIEW                 ;      ' ;9
				dc.b	'     NEXT WEAPON                RET     ' ;9
				dc.b	'                                        ' ;9
				dc.b	'             OTHER CONTROLS             ' ;0
				dc.b	'                                        ' ;1
				dc.b	'1-0   Select Weapon P              Pause' ;2
				dc.b	'F1   Zoom in on map F3 4/8 Channel Sound' ;3
				dc.b	'F2  Zoom out on map F4 Mono/Stereo Sound' ;4
				dc.b	'F5 Recall Message   F6    Render Quality'
				dc.b	'    Keypad 1-9 scroll map, 5 centres    ' ;5
				dc.b	'                                        ' ;7
				dc.b	'               MAIN  MENU               ' ;8
				dc.b	'                                        ' ;1

CONTROL_OPTS:
				dc.w	5,4,30,1
				dc.w	5,5,30,1
				dc.w	5,6,30,1
				dc.w	5,7,30,1
				dc.w	5,8,30,1
				dc.w	5,9,30,1
				dc.w	5,10,30,1
				dc.w	5,11,30,1
				dc.w	5,12,30,1
				dc.w	5,13,30,1
				dc.w	5,14,30,1
				dc.w	5,15,30,1
				dc.w	5,16,30,1
				dc.w	5,17,30,1
				dc.w	5,18,30,1
				dc.w	5,19,30,1
				dc.w	5,20,30,1
				dc.w	15,30,10,1
				dc.w	-1

PLOPT:			dc.w	0

INSTRUCTIONS_TXT:
;      0123456789012345678901234567890123456789
				dc.b	'Main controls:                          ' ;1
				dc.b	'                                        ' ;2
				dc.b	'Curs Keys = Forward / Backward          ' ;3
				dc.b	'            Turn left / right           ' ;4
				dc.b	'          Right Alt = Fire              ' ;5
				dc.b	'        Right Shift = Run               ' ;6
				dc.b	'                  > = Slide Left        ' ;7
				dc.b	'                  ? = Slide Right       ' ;8
				dc.b	'              SPACE = Operate Door/Lift ' ;9
				dc.b	'                  D = Duck              ' ;0
				dc.b	'                  J = Joystick Control  ' ;1
				dc.b	'                  K = Keyboard Control  ' ;2
				dc.b	'                                        ' ;3
				dc.b	'              1,2,3 = Select weapon     ' ;4
				dc.b	'              ENTER = Toggle screen size' ;5
				dc.b	'                ESC = Quit              ' ;6
				dc.b	'                                        ' ;7
				dc.b	'                                        ' ;8
				dc.b	'The one player game has no objective and' ;9
				dc.b	'the only way to finish is to die or quit' ;0
				dc.b	'                                        ' ;1
				dc.b	'The two-player game is supposed to be a ' ;2
				dc.b	'fight to the death but will probably be ' ;3
				dc.b	'a fight-till-we-find-the-rocket-launcher' ;4
				dc.b	'then-blow-ourselves-up type game.       ' ;5
				dc.b	'                                        ' ;6
				dc.b	'LOOK OUT FOR TELEPORTERS: They usually  ' ;7
				dc.b	'have glowing red walls and overhead     ' ;8
				dc.b	'lights. Useful for getting behind your  ' ;9
				dc.b	' opponent!                              ' ;0
				dc.b	'  Just a taster of what is to come....  ' ;1
				dc.b	'                                        ' ;0

INSTRUCTIONS_OPTS:
				dc.w	0,0,0,1
				dc.w	-1

CREDITMENU_TXT:

;      0123456789012345678901234567890123456789
				dc.b	'    Programming, Game Code, Graphics    ' ;0
				dc.b	'         Game Design and Manual         ' ;1
				dc.b	'            Andrew Clitheroe            ' ;2
				dc.b	'                                        ' ;3
				dc.b	'       Alien and Scenery Graphics       ' ;4
				dc.b	'             Michael  Green             ' ;5
				dc.b	'                                        ' ;6
				dc.b	'           3D Object Designer           ' ;7
				dc.b	'            Charles Blessing            ' ;8
				dc.b	'                                        ' ;9
				dc.b	'              Level Design              ' ;0
				dc.b	'Jackie Lang   Michael Green  Ben Chanter' ;1
				dc.b	'                                        ' ;3
				dc.b	'                                        ' ;3
				dc.b	'           Creative  Director           ' ;4
				dc.b	'              Martyn Brown              ' ;5
				dc.b	'                                        ' ;6
				dc.b	'       Project Manager and Manual       ' ;7
				dc.b	'          Phil Quirke-Webster           ' ;8
				dc.b	'                                        ' ;9
				dc.b	'                 Music                  ' ;0
				dc.b	'           Ben "666" Chanter            ' ;1
				dc.b	'                                        ' ;2
				dc.b	'      Cover Illustration and Logo       ' ;3
				dc.b	'             Kevin Jenkins              ' ;4
				dc.b	'                                        ' ;5
				dc.b	'      Packaging and Manual Design       ' ;6
				dc.b	'               Paul Sharp               ' ;7
				dc.b	'                                        ' ;8
				dc.b	'             QA and Playtest            ' ;9
				dc.b	'     Too numerous to mention here!      ' ;0
				dc.b	'                                        ' ;1

				dc.b	'    Serial Link and 3D Object Editor:   ' ;4
				dc.b	'                   by                   ' ;5
				dc.b	'            Charles Blessing            ' ;6
				dc.b	'                                        ' ;7
				dc.b	'                Graphics:               ' ;8
				dc.b	'                   by                   ' ;9
				dc.b	'              Mike  Oakley              ' ;0
				dc.b	'                                        ' ;1
				dc.b	'             Title  Picture             ' ;2
				dc.b	'                   by                   ' ;3
				dc.b	'               Mike Green               ' ;4
				dc.b	'                                        ' ;5
				dc.b	' Inspiration, incentive, moral support, ' ;6
				dc.b	'     level design and plenty of tea     ' ;7
				dc.b	'         generously supplied by         ' ;8
				dc.b	'                                        ' ;9
				dc.b	'              Jackie  Lang              ' ;0
				dc.b	'                                        ' ;1
				dc.b	'    Music for the last demo composed    ' ;2
				dc.b	'       by the inexpressibly evil:       ' ;3
				dc.b	'                                        ' ;8
				dc.b	'            *BAD* BEN CHANTER           ' ;9
				dc.b	'                                        ' ;0
				dc.b	'    Sadly no room for music this time   ' ;1
				dc.b	'                                        ' ;7
				dc.b	'                                        ' ;7

CREDITMENU_OPTS:
				dc.w	0,0,1,1
				dc.w	-1


;      0123456789012345678901234567890123456789
				dc.b	'                                        ' ;0
				dc.b	'                                        ' ;1
				dc.b	'                                        ' ;2
				dc.b	'                                        ' ;3
				dc.b	'                                        ' ;4
				dc.b	'                                        ' ;5
				dc.b	'                                        ' ;6
				dc.b	'                                        ' ;7
				dc.b	'                                        ' ;8
				dc.b	'                                        ' ;9
				dc.b	'                                        ' ;0
				dc.b	'                                        ' ;1
				dc.b	'                                        ' ;2
				dc.b	'                                        ' ;3
				dc.b	'                                        ' ;4
				dc.b	'                                        ' ;5
				dc.b	'                                        ' ;6
				dc.b	'                                        ' ;7
				dc.b	'                                        ' ;8
				dc.b	'                                        ' ;9
				dc.b	'                                        ' ;0
				dc.b	'                                        ' ;1
				dc.b	'                                        ' ;2
				dc.b	'                                        ' ;3
				dc.b	'                                        ' ;4
				dc.b	'                                        ' ;5
				dc.b	'                                        ' ;6
				dc.b	'                                        ' ;7
				dc.b	'                                        ' ;8
				dc.b	'                                        ' ;9
				dc.b	'                                        ' ;0
				dc.b	'                                        ' ;1


********************************************************

PUTIN32:

				moveq	#0,d2
				moveq	#0,d3
				moveq	#0,d4
				moveq	#0,d5
				moveq	#0,d6
				moveq	#0,d7

				move.w	#31,d2
p32loop:
				moveq	#0,d5
				move.l	(a0)+,d3
				move.w	d3,d4
				swap	d3
				move.b	d4,d5
				lsr.w	#8,d4

				muls	d0,d3
				muls	d0,d4
				muls	d0,d5
				lsr.l	#8,d3
				lsr.l	#8,d4
				lsr.l	#8,d5
				move.w	d3,d6
				swap	d3
				move.w	d6,d3
				move.w	d4,d6
				swap	d4
				move.w	d6,d4
				move.w	d5,d6
				swap	d5
				move.w	d6,d5
				and.w	#%11110000,d3
				and.w	#%11110000,d4
				and.w	#%11110000,d5
				lsl.w	#4,d3
				add.w	d4,d3
				lsr.w	#4,d5
				add.w	d5,d3
				move.w	d3,2(a1)
				swap	d3
				swap	d4
				swap	d5
				and.w	#%1111,d3
				and.w	#%1111,d4
				and.w	#%1111,d5
				lsl.w	#8,d3
				lsl.w	#4,d4
				add.w	d4,d3
				add.w	d5,d3
				move.w	d3,2+(132*4)(a1)
				addq	#4,a1
				dbra	d2,p32loop


				rts

**************************************

FADEAMOUNT:		dc.w	0
FADEVAL:		dc.w	0

FADEUPTITLE:

				moveq	#0,d0
				moveq	#0,d1
				move.w	FADEVAL,d0
				move.w	FADEAMOUNT,d1
fadeuploop:

;				move.l	#TITLEPAL,a0
;				move.l	#TITLEPALCOP,a1
;
;wvb:
;				btst	#5,_custom+intreqrl
;				beq.s	wvb
;				move.w	#$20,_custom+intreq
;
;				bsr		PUTIN32
;				add.w	#4,a1
;				bsr		PUTIN32
;				add.w	#4,a1
;				bsr		PUTIN32
;				add.w	#4,a1
;				bsr		PUTIN32
;
;				addq.w	#8,d0
;				dbra	d1,fadeuploop
;
;				subq	#8,d0
;				move.w	d0,FADEVAL

				rts

CLEARTITLEPAL:

				rts

FADEDOWNTITLE:

				move.w	FADEVAL,d0
				move.w	FADEAMOUNT,d1
fadedownloop:

;				move.l	#TITLEPAL,a0
;
;.wvb:
;				btst	#5,_custom+intreqrl
;				beq.s	.wvb
;				move.w	#$20,_custom+intreq
;
;				bsr		PUTIN32
;				add.w	#4,a1
;				bsr		PUTIN32
;				add.w	#4,a1
;				bsr		PUTIN32
;				add.w	#4,a1
;				bsr		PUTIN32
;
;				subq.w	#8,d0
;				dbra	d1,fadedownloop
;
;				addq	#8,d0
;				move.w	d0,FADEVAL

				rts


LEVELTEXTNAME:	dc.b	'TKG1:includes/TEXT_FILE'

				even

LEVELTEXT:
				dc.l	0

font:
				incbin	"starquake.font.bin"

				include	"menu/menunb.s"
