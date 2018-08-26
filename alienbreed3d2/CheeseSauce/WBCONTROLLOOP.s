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

INTROTUNEADDR: dc.l 0
INTROTUNENAME: dc.b 'ab3:sounds/abreed3d.med',0
 even
TITLESCRNADDR: dc.l 0
TITLESCRNNAME: dc.b 'AB3D1:includes/titlescrnraw',0
 even
TITLESCRNNAME2: dc.b 'AB3D2:includes/titlescrnraw1',0
 even
OPTSPRADDR: dc.l 0



ProtValA: dc.l 0
ProtValB: dc.l 0
ProtValC: dc.l 0
ProtValD: dc.l 0
ProtValE: dc.l 0
ProtValF: dc.l 0
ProtValG: dc.l 0
ProtValH: dc.l 0
ProtValI: dc.l 0
ProtValJ: dc.l 0
ProtValK: dc.l 0
ProtValL: dc.l 0
ProtValM: dc.l 0
ProtValN: dc.l 0


KVALTOASC:
		Dc.b	" `  "," 1  "," 2  "," 3  "
		dc.b	" 4  "," 5  "," 6  "," 7  "
		dc.b	" 8  "," 9  "
; 10
		Dc.b	" 0  "," -  "," +  "," \  "
		dc.b 	'    ','    '," Q  "," W  "
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
		dc.b 	" /  ",'    '
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
		dc.b    'KP+ ','HLP ','LSH ','RSH '
		dc.b	'CPL ','CTL '
;100
		Dc.b	'LAL ','RAL ','LAM ','RAM '
		dc.b	'    ','    ','    ','    '
		dc.b	'    ','    '
		Dc.b	'    ','    ','    ','    '
		dc.b	'    ','    ','    ','    '
		dc.b	'    ','    '

 even

FINISHEDLEVEL: dc.w 0


START:

 move.b #'n',mors  

************************************88
* TAKE OUT WHEN PLAYING MODULE AGAIN
********************************
ProtChkBLev1:
	PRSDF
	PRSDE
************************************

; move.l #PROTCALLENC,a0
; move.l #(ENDPROT-PROTCALLENC)/4-1,d1
; move.l #$75055345,d0
;codeitup:
; sub.l d0,(a0)+
; ror.l #1,d0
; dbra d1,codeitup
; rts

 jsr Open256Screen

ProtChkCLev1:
 PRSDA

; move.w #$7201,titleplanes
 
 move.l 4.w,a6
 move.l #doslibname,a1
 moveq #0,d0
 jsr -552(a6)
 move.l d0,doslib
 PRSDS
; jsr stuff
 
 jsr _InitLowLevel
 
; jsr CLEARTITLEPAL
 
ProtChkDLev1:
 PRSDT
 
; move.w #$20,$dff1dc
; move.l #titlecop,$dff080
 PRSDV
; move.w #$87c0,$dff000+dmacon
; move.w #$8020,$dff000+dmacon
ProtChkMLev1:
 move.w $dff006,d0
 lea RVAL2-100(pc),a0
 add.w d0,100(a0)
 
 bsr GETTITLEMEM
ProtChkELev1:
 PRSDU
; bsr CLROPTSCRN
 
; bsr SETUPTITLESCRN
 
; jsr _InitPlayer

; move.l #INTROTUNENAME,a0
; jsr _LoadModule
; move.l d0,INTROTUNEADDR
 PRSDY
; move.l d0,a0
; jsr _InitModule
 
; move.l INTROTUNEADDR,a0
; jsr _PlayModule
ProtChkFLev1:
 PRSDa
; bsr LOADTITLESCRN2

 FLASHER $0f0,$fff

 move.w #0,FADEVAL
 move.w #63,FADEAMOUNT
 bsr FADEUPTITLE
 PRSDB
 jsr LOADWALLS
 jsr LOADFLOOR
 jsr LOADOBS
 PRSDZ

 move.w #31,FADEAMOUNT
 PRSDC
 bsr FADEDOWNTITLE 

; IFEQ CD32VER 
; bsr ASKFORDISK
; ENDC
; IFNE CD32VER
 PRSDD
; ENDC

 jsr LOAD_SFX
; jsr _StopPlayer
 PRSDW
 PRSDX
; jsr _RemPlayer


 IFNE CD32VER
 move.l doslib,a6
 move.l #115,d1
 jsr -198(a6)
 ENDC

; move.l #newblag,$80
; trap #0
; bra JUMPPASTIT
; rts
;
;newblag:


ProtChkGLev1:
; bsr PROTSETUP
 bsr DEFAULTGAME
 
; move.l INTROTUNEADDR,a0
; jsr _UnLoadModule

; IFEQ CD32VER
; jsr KInt_Init
; ENDC
ProtChkHLev1:
; rte
;
;JUMPPASTIT:
; 

BACKTOMENU:

 jsr CLEARKEYBOARD

; cmp.b #'s',mors
; beq.s BACKTOSLAVE
; cmp.b #'m',mors
; beq.s BACKTOMASTER
; bsr READMAINMENU
; bra DONEMENU
;BACKTOMASTER:
; bsr MASTERMENU
; bra DONEMENU
;BACKTOSLAVE:
; bsr SLAVEMENU
;DONEMENU:


 bsr WAITREL

; IFEQ CD32VER
; move.l OLDKINT,$68.w
; ENDC
 
 bsr CLRSPRITES
 
 move.w #31,FADEAMOUNT
 bsr FADEUPTITLE
 move.w #63,FADEAMOUNT
 bsr FADEDOWNTITLE
 
 move.w #$0201,titleplanes

	FILTER
	
 tst.b SHOULDQUIT
 bne QUITTT

 bsr RELEASETITLEMEM

  
; jsr LOADBOTPIC

  
 clr.b FINISHEDLEVEL
 
 move.w #0,PLR1s_angpos
 move.w #0,PLR2s_angpos
 move.w #0,PLR1_angpos
 move.w #0,PLR2_angpos
 move.b #0,PLR1_GunSelected
 move.b #0,PLR2_GunSelected
 
**************************8
 clr.b NASTY
*************************** 


	jsr PLAYTHEGAME

; bsr FREEBOTMEM 

; bra QUITTT
 
 tst.b FINISHEDLEVEL
 beq dontusestats
 bsr CALCPASSWORD
dontusestats:
 bsr PASSLINETOGAME
 bsr GETSTATS
 
 bsr GETTITLEMEM
; bsr CLROPTSCRN
; bsr SETUPTITLESCRN
 
; bsr LOADTITLESCRN2
; move.w #$7201,titleplanes

; move.w #$20,$dff1dc
; move.l #titlecop,$dff080
; move.w #$87c0,$dff000+dmacon
; move.w #$8020,$dff000+dmacon 

 move.w #0,FADEVAL
 move.w #63,FADEAMOUNT
 bsr FADEUPTITLE

 move.w #31,FADEAMOUNT
 bsr FADEDOWNTITLE 

; IFEQ CD32VER
; jsr KInt_Init
; ENDC

 bra BACKTOMENU

QUITTT:

 move.l LEVELDATA,d1
 move.l d1,a1
 move.l #120000,d0
 move.l 4.w,a6
 jsr -210(a6)

 move.l TEXTSCRN,d1
 move.l d1,a1
 move.l #10240*2,d0
 move.l 4.w,a6
 jsr -210(a6)

 move.l FASTBUFFER,d1	
 move.l #2*320*256,d0
 move.l 4.w,a6
 jsr -210(a6)
 
 jsr RELEASEWALLMEM
 jsr RELEASESAMPMEM
 jsr RELEASEFLOORMEM
 jsr RELEASEOBJMEM
  
 move.l old,$dff080
 move.l 4.w,a6
 lea VBLANKInt,a1
 moveq #INTB_COPER,d0
 jsr _LVORemIntServer(a6)

 move.l 4.w,a6
 lea KEYInt,a1
 moveq #INTB_PORTS,d0
 jsr _LVORemIntServer(a6)

; move.w #$f8e,$dff1dc
;
; move.l old,$dff080
; move.w _storeint,d0
; or.w d0,$dff000+intena

; move.l	4.w,a6
; jsr	_LVOPermit(a6)
 
 move.l #0,d0

 rts
 
SSTACK: dc.l 0
 
; KEY OPTIONS:
CONTROLBUFFER:
turn_left_key:
 dc.b $4f
turn_right_key:
 dc.b $4e
forward_key:
 dc.b $4c
backward_key:
 dc.b $4d
fire_key:
 dc.b $65
operate_key:
 dc.b $40
run_key:
 dc.b $61
force_sidestep_key:
 dc.b $67
sidestep_left_key:
 dc.b $39
sidestep_right_key:
 dc.b $3a
duck_key:
 dc.b $22
look_behind_key:
 dc.b $28

templeftkey: dc.b 0
temprightkey: dc.b 0
tempslkey: dc.b 0 
tempsrkey: dc.b 0
 
 even 
 
GETSTATS:
; CHANGE PASSWORD INTO RAW DATA

 move.b PASSBUFFER,d0
 and.w #$7f,d0
 move.w d0,PLR1_energy
 move.b PASSBUFFER+1,d0
 btst #7,d0
 sne PLR1_GunData+32+7
 btst #6,d0
 sne PLR1_GunData+32*2+7
 btst #5,d0
 sne PLR1_GunData+32*4+7
 btst #4,d0
 sne PLR1_GunData+32*7+7
 and.w #%1111,d0
 move.w d0,MAXLEVEL
 move.b PASSBUFFER+2,d0
 and.w #$7f,d0
 lsl.w #3,d0
 move.w d0,PLR1_GunData
 move.b PASSBUFFER+3,d0
 and.w #$7f,d0
 lsl.w #3,d0
 move.w d0,PLR1_GunData+32
 move.b PASSBUFFER+4,d0
 and.w #$7f,d0
 lsl.w #3,d0
 move.w d0,PLR1_GunData+32*2
 move.b PASSBUFFER+5,d0
 and.w #$7f,d0
 lsl.w #3,d0
 move.w d0,PLR1_GunData+32*4
 move.b PASSBUFFER+6,d0
 and.w #$7f,d0
 lsl.w #3,d0
 move.w d0,PLR1_GunData+32*7
 rts


SETPLAYERS:

 move.w PLOPT,d0
 add.b #'a',d0
 move.b d0,LEVA
 move.b d0,LEVB
 move.b d0,LEVC
 move.b d0,LEVD

 cmp.b #'s',mors
 beq SLAVESETUP
 cmp.b #'m',mors
 beq MASTERSETUP
 st NASTY
onepla:
 rts

NASTY: dc.w 0
 
MASTERSETUP:
 bsr TWOPLAYER
 clr.b NASTY
 move.w PLOPT,d0
 jsr SENDFIRST
 rts

SLAVESETUP:
 bsr TWOPLAYER
 CLR.B NASTY
 jsr RECFIRST
 move.w d0,PLOPT
 add.b #'a',d0
 move.b d0,LEVA
 move.b d0,LEVB
 move.b d0,LEVC
 rts
 	
********************************************************

ASKFORDISK:
 lea RVAL1+300(pc),a0
 lea RVAL2+900(pc),a1
 PRSDD
 move.w #3,OptScrn
 bsr DRAWOPTSCRN

ProtChkNLev1:
.wtrel:
 btst #7,$bfe001
 beq.s .wtrel

wtclick:
 add.w #$235,-300(a0)
 add.w #$4533,-900(a0)
 btst #6,$bfe001
 bne.s wtclick
 
 rts

CLRSPRITES: 
 move.l #nullspr,d0
 move.w d0,tsp0l
 move.w d0,tsp1l
 move.w d0,tsp2l
 move.w d0,tsp3l
 move.w d0,tsp4l
 move.w d0,tsp5l
 move.w d0,tsp6l
 move.w d0,tsp7l
 swap d0
 move.w d0,tsp0h
 move.w d0,tsp1h
 move.w d0,tsp2h
 move.w d0,tsp3h
 move.w d0,tsp4h
 move.w d0,tsp5h
 move.w d0,tsp6h
 move.w d0,tsp7h 
 rts

********************************************************

READMAINMENU:

 
 move.b #'n',mors

 move.w MAXLEVEL,d0
 
 move.l #CURRENTLEVELLINE,a1
 muls #40,d0
 move.l #LEVEL_OPTS,a0
 add.l d0,a0
 bsr PUTINLINE



; Stay here until 'play game' is selected.

 move.w #0,OptScrn
 bsr DRAWOPTSCRN
 move.w #1,OPTNUM

 bsr HIGHLIGHT



 bsr WAITREL
.rdlop:

 bsr CHECKMENU
 tst.w d0
 blt.s .rdlop
 
 bne .noopt
 
 bra MASTERMENU
 
.noopt:

 cmp.w #5,d0
 bne.s .noqui
 st SHOULDQUIT
 bra playgame
.noqui

 cmp.w #1,d0
 beq playgame

 cmp.w #2,d0
 bne .nocontrol
 
 bsr CHANGECONTROLS

 move.w #0,OptScrn
 bsr DRAWOPTSCRN
 move.w #0,OPTNUM

 bsr HIGHLIGHT

 bsr WAITREL
 bra .rdlop
 
.nocontrol:

 cmp.w #3,d0
 bne .nocred
 bsr SHOWCREDITS
 move.w #0,OptScrn
 bsr DRAWOPTSCRN
 move.w #1,OPTNUM

 bsr HIGHLIGHT

 bsr WAITREL
 bra .rdlop
 
 
.nocred:

 cmp.w #4,d0
 bne playgame
 bsr WAITREL

 move.l #PASSWORDLINE+12,a0
 moveq #15,d2
.clrline:
 move.b #32,(a0)+
 dbra d2,.clrline 
 move.w #0,OptScrn
 bsr DRAWOPTSCRN

 IFEQ CD32VER
 clr.b lastpressed
 move.l #PASSWORDLINE+12,a0
 move.w #0,d1
.ENTERPASS:
 tst.b lastpressed
 beq .ENTERPASS
 move.b lastpressed,d2
 move.b #0,lastpressed
 move.l #KVALTOASC,a1
 
 cmp.l #'<-- ',(a1,d2.w*4)
 bne .nodel

 tst.b d1
 beq .nodel

 subq #1,d1
 move.b #32,-(a0)
 movem.l d0-d7/a0-a6,-(a7)
 bsr JUSTDRAWIT
 movem.l (a7)+,d0-d7/a0-a6
 bra .ENTERPASS

.nodel:
 
 cmp.l #'RTN ',(a1,d2.w*4)
 beq .FORGETIT
 cmp.l #'ESC ',(a1,d2.w*4)
 beq .FORGETIT
 move.b 1(a1,d2.w*4),d2
 cmp.b #65,d2
 blt .ENTERPASS
 cmp.b #'Z',d2
 bgt .ENTERPASS
 move.b d2,(a0)+
 move.w #0,OptScrn
 movem.l d0-d7/a0-a6,-(a7)
 bsr JUSTDRAWIT
 movem.l (a7)+,d0-d7/a0-a6
 add.w #1,d1
 cmp.w #16,d1
 blt .ENTERPASS

 ENDC
 IFNE CD32VER
 move.l #PASSWORDLINE+12,a0
 move.w #15,d0
.ENTERPASS:
 bsr GETACHAR
 dbra d0,.ENTERPASS
 ENDC

 bsr PASSLINETOGAME
 tst.w d0
 bne .FORGETIT
 
 bsr GETSTATS
 move.w MAXLEVEL,d0
 move.l #CURRENTLEVELLINE,a1
 muls #40,d0
 move.l #LEVEL_OPTS,a0
 add.l d0,a0
 bsr PUTINLINE

.FORGETIT:
 bsr WAITREL
 bsr CALCPASSWORD

 move.w #0,OptScrn
 bsr DRAWOPTSCRN

 move.w #1,OPTNUM

 bsr HIGHLIGHT

 bra .rdlop 
 
playgame:
 move.w MAXLEVEL,PLOPT
 rts
 
SHOULDQUIT: dc.w 0
 
LEVELSELECTED:
 dc.w 0
 
 IFNE CD32VER
GETACHAR:
 moveq #0,d7
 move.b #'A',(a0)
 movem.l d0-d7/a0-a6,-(a7)
 jsr JUSTDRAWIT
 movem.l (a7)+,d0-d7/a0-a6

.wtnum:
 btst #1,$dff00c
 sne d1
 btst #1,$dff00d
 sne d2
 btst #0,$dff00c
 sne d3
 btst #0,$dff00d
 sne d4
 
 eor.b d1,d3
 eor.b d2,d4
 
 tst.b d1
 beq.s .NODELETE
 cmp.w #15,d0
 beq.s .NODELETE
 move.b #32,(a0)
 subq #1,a0
 addq #1,d0
 move.b (a0),d7
 sub.b #'A',d7
 movem.l d0-d7/a0-a6,-(a7)
 jsr JUSTDRAWIT
 movem.l (a7)+,d0-d7/a0-a6
 jsr WAITFORNOPRESS
 bra .wtnum
.NODELETE

 tst.b d4
 bne.s .PREVNUM
 tst.b d3
 bne.s .NEXTNUM
 btst #7,$bfe001
 bne.s .wtnum
 addq #1,a0
 jsr WAITFORNOPRESS
 rts

.PREVNUM:
 subq #1,d7
 bge.s .nonegg
 moveq #15,d7
.nonegg:
 move.b d7,d1
 add.b #'A',d1
 move.b d1,(a0)
 movem.l d0-d7/a0-a6,-(a7)
 jsr JUSTDRAWIT
 movem.l (a7)+,d0-d7/a0-a6
 
 jsr WAITFORNOPRESS
 
 bra .wtnum

.NEXTNUM:
 addq #1,d7
 cmp.w #15,d7
 ble.s .nobigg
 moveq #0,d7
.nobigg:
 move.b d7,d1
 add.b #'A',d1
 move.b d1,(a0)
 movem.l d0-d7/a0-a6,-(a7)
 jsr JUSTDRAWIT
 movem.l (a7)+,d0-d7/a0-a6
 jsr WAITFORNOPRESS
 bra .wtnum
 rts
 ENDC
 
 
MASTERMENU:

 move.b #'m',mors

 move.w #0,LEVELSELECTED

 move.w #0,d0 
 move.l #CURRENTLEVELLINEM,a1
 muls #40,d0
 move.l #LEVEL_OPTS,a0
 add.l d0,a0
 bsr PUTINLINE

; Stay here until 'play game' is selected.

 move.w #4,OptScrn
 bsr DRAWOPTSCRN
 move.w #1,OPTNUM

 bsr HIGHLIGHT

 bsr WAITREL
.rdlop:
 bsr CHECKMENU
 tst.w d0
 blt.s .rdlop
 bsr WAITREL

 cmp.w #1,d0
 bne.s .nonextlev
 
 move.w LEVELSELECTED,d0
 add.w #1,d0
 cmp.w MAXLEVEL,d0
 blt .nowrap
 moveq #0,d0
.nowrap:
 move.w d0,LEVELSELECTED
 move.l #CURRENTLEVELLINEM,a1
 muls #40,d0
 move.l #LEVEL_OPTS,a0
 add.l d0,a0
 bsr PUTINLINE
 bsr JUSTDRAWIT
 bra .rdlop
 
.nonextlev:
 cmp.w #2,d0
 beq .playgame
 
 cmp.w #0,d0
 bne .noopt
 
 bra SLAVEMENU
 
.noopt:

 cmp.w #3,d0
 bne .nocontrol
 
 bsr CHANGECONTROLS

 move.w #4,OptScrn
 bsr DRAWOPTSCRN
 move.w #0,OPTNUM

 bsr HIGHLIGHT

 bsr WAITREL
 bra .rdlop
 
.nocontrol:

.playgame

 move.w LEVELSELECTED,PLOPT
 rts
 
SLAVEMENU:

 move.b #'s',mors

; Stay here until 'play game' is selected.

 move.w #5,OptScrn
 bsr DRAWOPTSCRN
 move.w #1,OPTNUM

 bsr HIGHLIGHT

 bsr WAITREL
.rdlop:
 bsr CHECKMENU
 tst.w d0
 blt.s .rdlop
 bsr WAITREL

 cmp.w #1,d0
 beq .playgame

 cmp.w #0,d0
 bne .noopt
 
 bra READMAINMENU
 
.noopt:

 cmp.w #2,d0
 bne .nocontrol
 
 bsr CHANGECONTROLS

 move.w #0,OptScrn
 bsr DRAWOPTSCRN
 move.w #0,OPTNUM

 bsr HIGHLIGHT

 bsr WAITREL
 bra .rdlop
 
.nocontrol:
.playgame:

 rts

TWOPLAYER:
 move.w #0,OldEnergy
 move.w #127,Energy
 jsr EnergyBar
 
 move.w #63,OldAmmo
 move.w #0,Ammo
 jsr AmmoBar
 move.w #0,OldAmmo
 
 move.w #127,PLR1_energy
 move.w #127,PLR2_energy 
 move.w #160,PLR1_GunData	; 10 shots pistol
 st PLR1_GunData+7
 
 st.b PLR1_GunData+32+7
 move.w #80*4,PLR1_GunData+32
 
 st.b PLR1_GunData+64+7
 move.w #80*4,PLR1_GunData+64
 
 st.b PLR1_GunData+32*3+7
 move.w #80*4,PLR1_GunData+32*3
 
 st.b PLR1_GunData+32*4+7
 move.w #80*4,PLR1_GunData+32*4
 
 st.b PLR1_GunData+32*7+7
 move.w #80*4,PLR1_GunData+32*7
 
 move.b #0,PLR1_GunSelected
 
 move.w #160,PLR2_GunData	; 10 shots pistol
 st PLR2_GunData+7
 st.b PLR2_GunData+32+7
 move.w #80*4,PLR2_GunData+32
 
 st.b PLR2_GunData+64+7
 move.w #80*4,PLR2_GunData+64
 
 st.b PLR2_GunData+32*3+7
 move.w #80*4,PLR2_GunData+32*3
 
 st.b PLR2_GunData+32*4+7
 move.w #80*4,PLR2_GunData+32*4
 
 st.b PLR2_GunData+32*7+7
 move.w #80*4,PLR2_GunData+32*7
 move.b #0,PLR2_GunSelected
 rts

newdum:
 rts
 
DEFAULTGAME:
 move.w #0,MAXLEVEL
 move.w #5,CHEATNUM
 move.l #CHEATFRAME-200000,CHEATPTR
 
 move.w #0,OldEnergy
 move.w #127,Energy
 jsr EnergyBar
 
 move.w #63,OldAmmo
 move.w #0,Ammo
 jsr AmmoBar
 move.w #0,OldAmmo
 
 move.w #127,PLR1_energy
 move.w #127,PLR2_energy 
 move.w #160,PLR1_GunData	; 10 shots pistol
 st PLR1_GunData+7
 clr.b PLR1_GunData+32+7
 clr.w PLR1_GunData+32
 clr.b PLR1_GunData+64+7
 clr.w PLR1_GunData+64
 clr.b PLR1_GunData+32*3+7
 clr.w PLR1_GunData+32*3
 clr.b PLR1_GunData+32*4+7
 clr.w PLR1_GunData+32*4
 clr.b PLR1_GunData+32*7+7
 clr.w PLR1_GunData+32*7
 move.b #0,PLR1_GunSelected

ProtChkILev1:
************************************************
* TEMPORARY MEASURE: REMOVE BEFORE RELEASE *****
************************************************


************************************************

 move.w #160,PLR2_GunData	; 10 shots pistol
 st PLR2_GunData+7
 clr.b PLR2_GunData+32+7
 clr.w PLR2_GunData+32
 clr.b PLR2_GunData+64+7
 clr.w PLR2_GunData+64
 clr.b PLR2_GunData+32*3+7
 clr.w PLR2_GunData+32*3
 clr.b PLR2_GunData+32*4+7
 clr.w PLR2_GunData+32*4
 clr.b PLR2_GunData+32*7+7
 clr.w PLR2_GunData+32*7
 move.b #0,PLR2_GunSelected
 
 bsr CALCPASSWORD
 
 rts
 
CHKPROT: dc.w 0
 
GETPARITY:
 move.w #6,d3
.calcparity:
 btst d3,d0
 beq.s .nochange
 bchg #7,d0
.nochange:
 dbra d3,.calcparity
 rts

CHECKPARITY:
 move.w #6,d3
 move.b #$0,d2
.calcparity:
 btst d3,d0
 beq.s .nochange
 bchg #7,d2
.nochange:
 dbra d3,.calcparity
 move.b d0,d1
 and.b #$80,d1
 eor.b d1,d2
 sne.s d5
 rts
 
CALCPASSWORD:
 move.b PLR1_energy+1,d0
 bsr GETPARITY
 move.b d0,PASSBUFFER
 moveq #0,d0
 tst.b PLR1_GunData+32+7
 sne d0
 lsl.w #1,d0
 tst.b PLR1_GunData+64+7
 sne d0
 lsl.w #1,d0
 tst.b PLR1_GunData+32*4+7
 sne d0
 lsl.w #1,d0
 tst.b PLR1_GunData+32*7+7
 sne d0
 lsr.w #3,d0
 and.b #%11110000,d0
 or.b MAXLEVEL+1,d0
 move.b d0,PASSBUFFER+1
 eor.b #%10110101,d0
 neg.b d0
 add.b #50,d0
 move.b d0,PASSBUFFER+7
 
 move.w PLR1_GunData,d0
 lsr.w #3,d0
 bsr GETPARITY
 move.b d0,PASSBUFFER+2
 move.w PLR1_GunData+32,d0
 lsr.w #3,d0
 bsr GETPARITY
 move.b d0,PASSBUFFER+3
 move.w PLR1_GunData+32*2,d0
 lsr.w #3,d0
 bsr GETPARITY
 move.b d0,PASSBUFFER+4
 move.w PLR1_GunData+32*4,d0
 lsr.w #3,d0
 bsr GETPARITY
 move.b d0,PASSBUFFER+5
 move.w PLR1_GunData+32*7,d0
 lsr.w #3,d0
 bsr GETPARITY
 move.b d0,PASSBUFFER+6

 move.w #3,d0
 move.l #PASSBUFFER,a0
 move.l #PASSBUFFER+8,a1
 move.l #PASS,a2
 moveq #0,d4
mixemup:
 move.b (a0)+,d1
 move.b -(a1),d2
 not.b d2
 moveq #0,d3
 lsr.b #1,d1
 addx.w d3,d3
 lsr.b #1,d2
 addx.w d3,d3
 lsr.b #1,d1
 addx.w d3,d3
 lsr.b #1,d2
 addx.w d3,d3
 lsr.b #1,d1
 addx.w d3,d3
 lsr.b #1,d2
 addx.w d3,d3
 lsr.b #1,d1
 addx.w d3,d3
 lsr.b #1,d2
 addx.w d3,d3
 lsr.b #1,d1
 addx.w d3,d3
 lsr.b #1,d2
 addx.w d3,d3
 lsr.b #1,d1
 addx.w d3,d3
 lsr.b #1,d2
 addx.w d3,d3
 lsr.b #1,d1
 addx.w d3,d3
 lsr.b #1,d2
 addx.w d3,d3
 lsr.b #1,d1
 addx.w d3,d3
 lsr.b #1,d2
 addx.w d3,d3
 move.w d3,(a2)+

 dbra d0,mixemup
 
 move.l #PASSWORDLINE+12,a0
 move.l #PASS,a1
 move.w #7,d0
putinpassline:
 move.b (a1),d1
 and.b #%1111,d1
 add.b #65,d1
 move.b d1,(a0)+
 move.b (a1)+,d1
 lsr.b #4,d1
 and.b #%1111,d1
 add.b #65,d1
 move.b d1,(a0)+
 dbra d0,putinpassline
 rts
 
PASSLINETOGAME:
 move.l #PASSWORDLINE+12,a0
 move.l #PASS,a1
 move.w #7,d0
getbuff:
 move.b (a0)+,d1
 move.b (a0)+,d2
 sub.b #65,d1
 sub.b #65,d2
 and.b #%1111,d1
 and.b #%1111,d2
 lsl.b #4,d2
 or.b d2,d1
 move.b d1,(a1)+
 dbra d0,getbuff
 
 move.l #PASS,a0
 move.l #PASSBUFFER,a1
 move.l #PASSBUFFER+8,a2
 move.w #3,d0
 moveq #0,d4
unmix:
 move.w (a0)+,d1
 moveq #0,d2
 moveq #0,d3
 lsr.w #1,d1
 addx.w d3,d3
 lsr.w #1,d1
 addx.w d2,d2
 lsr.w #1,d1
 addx.w d3,d3
 lsr.w #1,d1
 addx.w d2,d2
 lsr.w #1,d1
 addx.w d3,d3
 lsr.w #1,d1
 addx.w d2,d2
 lsr.w #1,d1
 addx.w d3,d3
 lsr.w #1,d1
 addx.w d2,d2
 lsr.w #1,d1
 addx.w d3,d3
 lsr.w #1,d1
 addx.w d2,d2
 lsr.w #1,d1
 addx.w d3,d3
 lsr.w #1,d1
 addx.w d2,d2
 lsr.w #1,d1
 addx.w d3,d3
 lsr.w #1,d1
 addx.w d2,d2
 lsr.w #1,d1
 addx.w d3,d3
 lsr.w #1,d1
 addx.w d2,d2
 not.b d3
 move.b d3,-(a2)
 move.b d2,(a1)+
 dbra d0,unmix
 
 move.b PASSBUFFER,d0
 bsr CHECKPARITY
 tst.b d5
 bne illega
 move.b PASSBUFFER+2,d0
 bsr CHECKPARITY
 tst.b d5
 bne illega
 move.b PASSBUFFER+3,d0
 bsr CHECKPARITY
 tst.b d5
 bne illega
 move.b PASSBUFFER+4,d0
 bsr CHECKPARITY
 tst.b d5
 bne illega
 move.b PASSBUFFER+5,d0
 bsr CHECKPARITY
 tst.b d5
 bne illega
 move.b PASSBUFFER+6,d0
 bsr CHECKPARITY
 tst.b d5
 bne illega
 
 move.b PASSBUFFER+1,d0
 eor.b #%10110101,d0
 neg.b d0
 add.b #50,d0
 cmp.b PASSBUFFER+7,d0
 bne illega
 
 move.w #0,d0
 rts
 
illega:

 move.w #-1,d0

 rts

PASSBUFFER:
 ds.b 8
 
CHECKBUFFER: ds.b 8
 
PASS:
 ds.b 16

**************************************************

CHANGECONTROLS:

 move.w #6,OptScrn
 bsr DRAWOPTSCRN
 move.w #0,OPTNUM
 bsr HIGHLIGHT
 bsr WAITREL
 
.rdlop:
 bsr CHECKMENU
 tst.w d0
 blt.s .rdlop

 cmp.w #12,d0
 beq .backtomain

 move.l #KEY_LINES,a0
 move.w d0,d1
 muls #40,d1
 add.l d1,a0
 add.w #32,a0
 move.l #$20202020,(a0)
 movem.l d0/a0,-(a7)
 bsr JUSTDRAWIT
 movem.l (a7)+,d0/a0 

 clr.b lastpressed

.wtkey
 tst.b lastpressed
 beq .wtkey
 
 move.l #CONTROLBUFFER,a1
 moveq #0,d1
 move.b lastpressed,d1
 move.b d1,(a1,d0.w)
 move.l #KVALTOASC,a1
 move.l (a1,d1.w*4),(a0)
 bsr JUSTDRAWIT
 bsr WAITREL
 bra .rdlop

.backtomain:
 rts

**************************************************

 
MAXLEVEL: dc.w 0
 
SHOWCREDITS:
 move.w #2,OptScrn
 bsr DRAWOPTSCRN
 move.w #0,OPTNUM
 bsr HIGHLIGHT

 bsr WAITREL

.rdlop:
 bsr CHECKMENU
 tst.w d0
 blt.s .rdlop
 
 bra READMAINMENU
 
HELDDOWN:
 dc.w 0

WAITREL:

 movem.l d0/d1/d2/d3,-(a7)

 move.l #KeyMap,a5
WAITREL2:
 btst #7,$bfe001
 beq.s WAITREL2
 
 IFEQ CD32VER
 tst.b $40(a5)
 bne.s WAITREL2
 tst.b $44(a5)
 bne.s WAITREL2
 tst.b $4c(a5)
 bne.s WAITREL2
 tst.b $4d(a5)
 bne.s WAITREL2
 ENDC

 btst #1,$dff00c
 sne d0
 btst #1,$dff00d
 sne d1
 btst #0,$dff00c
 sne d2
 btst #0,$dff00d
 sne d3
 
 eor.b d0,d2
 eor.b d1,d3
 tst.b d2
 bne.s WAITREL2
 tst.b d3
 bne.s WAITREL2

 
 movem.l (a7)+,d0/d1/d2/d3
 rts
 
PUTINLINE:
 moveq #39,d0
pill
 move.b (a0)+,(a1)+
 dbra d0,pill
 rts

CHECKMENU:
 btst #1,$dff00c
 sne d0
 btst #1,$dff00d
 sne d1
 btst #0,$dff00c
 sne d2
 btst #0,$dff00d
 sne d3
 
 eor.b d0,d2
 eor.b d1,d3
 
 move.l #KeyMap,a5
 move.b $4c(a5),d0
 move.b $4d(a5),d1
 or.b d1,d3
 or.b d0,d2

 move.w OptScrn,d0
 move.l #MENUDATA,a0
 move.l 4(a0,d0.w*8),a0	; opt data

 move.w OPTNUM,d0

 tst.b d2
 beq.s NOPREV
 
 
 sub.w #1,d0
 bge.s NOPREV
 
 move.w #0,d0 

NOPREV:

 tst.b d3
 beq.s NONEXT
 
 bsr WAITREL
 
 add.w #1,d0
 tst.w (a0,d0.w*8)
 bge.s NONEXT
 
 subq #1,d0
 
NONEXT:

 cmp.w OPTNUM,d0
 beq.s .nochange

 bsr HIGHLIGHT
 move.w d0,OPTNUM
 bsr HIGHLIGHT
 bsr WAITREL
 
.nochange:
 
 move.w #-1,d0
 
 btst #7,$bfe001
 beq.s select
 move.b $40(a5),d1
 or.b $44(a5),d1
 tst.b d1
 beq.s noselect
 
select:
 bsr WAITREL
 move.w OPTNUM,d0
noselect:
 
 rts
 
HIGHLIGHT:

 SAVEREGS
 
 move.w OptScrn,d0
 move.l #MENUDATA,a0
 move.l 4(a0,d0.w*8),a0
 move.w OPTNUM,d0
 lea (a0,d0.w*8),a0
 move.w (a0)+,d0	;left
 move.w (a0)+,d1	;top
 move.w (a0)+,d2	;width

 muls #16*8,d1
 move.l OPTSPRADDR,a1
 add.w d1,a1
 add.w #8+16,a1
 move.l #SCRTOSPR2,a5
 adda.w d0,a5
 adda.w d0,a5
 
NOTLOP:

 move.w (a5)+,d3
 lea (a1,d3.w),a2
 not.b (a2)
 not.b 16(a2)
 not.b 32(a2)
 not.b 48(a2)
 not.b 64(a2)
 not.b 80(a2)
 not.b 96(a2)
 not.b 112(a2)
 not.b 128(a2)
 subq #1,d2
 bgt.s NOTLOP
 
 GETREGS
 rts
 
SCRTOSPR2:
val SET 0
 REPT 6
 dc.w val+0
 dc.w val+1
 dc.w val+2
 dc.w val+3
 dc.w val+4
 dc.w val+5
 dc.w val+6
 dc.w val+7
val SET val+258*16
 ENDR
 
CLROPTSCRN:

 move.l #$2cdfea,d0
 move.w (a4,d0.l),d0
 add.w d0,RVAL2

 move.l OPTSPRADDR,a0
 lea 16(a0),a1
 lea 16+(258*16)(a0),a2
 lea 16+(258*16*2)(a0),a3
 lea 16+(258*16*3)(a0),a4
 lea 258*16(a4),a0
 
 move.w #256,d0
 moveq #0,d1
CLRLOP:
 move.l d1,(a0)+
 move.l d1,(a0)+
 move.l d1,(a0)+
 move.l d1,(a0)+
 move.l d1,(a1)+
 move.l d1,(a1)+
 move.l d1,(a1)+
 move.l d1,(a1)+
 move.l d1,(a2)+
 move.l d1,(a2)+
 move.l d1,(a2)+
 move.l d1,(a2)+
 move.l d1,(a3)+
 move.l d1,(a3)+
 move.l d1,(a3)+
 move.l d1,(a3)+
 move.l d1,(a4)+
 move.l d1,(a4)+
 move.l d1,(a4)+
 move.l d1,(a4)+
 dbra d0,CLRLOP

 move.l OPTSPRADDR,a0
 move.w #44*256+64,(a0)
 move.w #44*256+2,8(a0)
 add.l #258*16,a0

 move.w #44*256+96,(a0)
 move.w #44*256+2,8(a0)
 add.l #258*16,a0

 move.w #44*256+128,(a0)
 move.w #44*256+2,8(a0)
 add.l #258*16,a0

 move.w #44*256+160,(a0)
 move.w #44*256+2,8(a0)
 add.l #258*16,a0

 move.w #44*256+192,(a0)
 move.w #44*256+2,8(a0)

 rts

DRAWOPTSCRN:

 bsr CLROPTSCRN

JUSTDRAWIT:

 move.l #font,a0
 move.l #MENUDATA,a1
 move.w OptScrn,d0
 move.l (a1,d0.w*8),a1
 
 move.l OPTSPRADDR,a3
 add.l #16,a3
 moveq #0,d2
 
 move.w #31,d0
linelop:
 move.w #39,d1
 move.l #SCRTOSPR,a4
 move.l a3,a2
charlop:
 move.b (a1)+,d2
 lea (a0,d2.w*8),a5
 move.b (a5)+,(a2)
 move.b (a5)+,16(a2)
 move.b (a5)+,32(a2)
 move.b (a5)+,48(a2)
 move.b (a5)+,64(a2)
 move.b (a5)+,80(a2)
 move.b (a5)+,96(a2)
 move.b (a5),112(a2)
 add.w (a4)+,a2
 dbra d1,charlop
 add.w #16*8,a3
 dbra d0,linelop
 
 rts
  
SCRTOSPR:
 dc.w 1,1,1,1,1,1,1,258*16-7
 dc.w 1,1,1,1,1,1,1,258*16-7
 dc.w 1,1,1,1,1,1,1,258*16-7
 dc.w 1,1,1,1,1,1,1,258*16-7
 dc.w 1,1,1,1,1,1,1,258*16-7
 dc.w 1,1,1,1,1,1,1,258*16-7
  
OPTNUM: dc.w 0
OptScrn: dc.w 0
 
MENUDATA:
;0
 dc.l ONEPLAYERMENU_TXT
 dc.l ONEPLAYERMENU_OPTS
;1
 dc.l INSTRUCTIONS_TXT
 dc.l INSTRUCTIONS_OPTS
;2
 dc.l CREDITMENU_TXT
 dc.l CREDITMENU_OPTS
;3
 dc.l ASKFORDISK_TXT
 dc.l ASKFORDISK_OPTS
;4
; dc.l ONEPLAYERMENU_TXT
; dc.l ONEPLAYERMENU_OPTS
 dc.l MASTERPLAYERMENU_TXT
 dc.l MASTERPLAYERMENU_OPTS
;5
 dc.l SLAVEPLAYERMENU_TXT
 dc.l SLAVEPLAYERMENU_OPTS
;6
 dc.l CONTROL_TXT
 dc.l CONTROL_OPTS
;7
 dc.l PROTMENU_TXT
 dc.l CONTROL_OPTS
 
ASKFORDISK_TXT:
;      0123456789012345678901234567890123456789
 dc.b '                                        ' ;0
 dc.b '                                        ' ;1
 dc.b '                                        ' ;2
 dc.b '                                        ' ;3
 dc.b '                                        ' ;4
 dc.b '                                        ' ;5
 dc.b '                                        ' ;6
 dc.b '                                        ' ;7
 dc.b '                                        ' ;8
 dc.b '                                        ' ;9
 dc.b '                                        ' ;0
 dc.b '                                        ' ;1
 dc.b '                                        ' ;2
 dc.b '          INSERT LEVEL DISK             ' ;3
 dc.b '                                        ' ;4
 dc.b '          PRESS MOUSE BUTTON            ' ;5
 dc.b '          WHEN DISK ACTIVITY            ' ;6
 dc.b '               FINISHES                 ' ;7
 dc.b '                                        ' ;8
 dc.b '                                        ' ;9
 dc.b '                                        ' ;0
 dc.b '                                        ' ;1
 dc.b '                                        ' ;2
 dc.b '                                        ' ;3
 dc.b '                                        ' ;4
 dc.b '                                        ' ;5
 dc.b '                                        ' ;6
 dc.b '                                        ' ;7
 dc.b '                                        ' ;8
 dc.b '                                        ' ;9
 dc.b '                                        ' ;0
 dc.b '                                        ' ;1

ASKFORDISK_OPTS:
 dc.w -1
 
 
ONEPLAYERMENU_TXT:
;      0123456789012345678901234567890123456789
 dc.b '                                        ' ;0
 dc.b '                                        ' ;1
 dc.b '                                        ' ;2
 dc.b '                                        ' ;3
 dc.b '                                        ' ;4
 dc.b '                                        ' ;5
 dc.b '                                        ' ;6
 dc.b '                                        ' ;7
 dc.b '                                        ' ;8
 dc.b '                                        ' ;9
 dc.b '                                        ' ;0
CURRENTLEVELLINE:
 dc.b '         *** A.F DEMO LEVEL ***         ' ;1 
 dc.b '                                        ' ;2
 dc.b '                1 PLAYER                ' ;3
 dc.b '                                        ' ;4
 dc.b '               PLAY  GAME               ' ;5
 dc.b '                                        ' ;6
 dc.b '            CONTROL  OPTIONS            ' ;7
 dc.b '                                        ' ;8
 dc.b '              GAME CREDITS              ' ;9
 dc.b '                                        ' ;0
 dc.b '                PASSWORD                ' ;1
 dc.b '                                        ' ;2
PASSWORDLINE:
 dc.b '                                        ' ;3
 dc.b '                                        ' ;4
 dc.b '                  QUIT                  ' ;5
 dc.b '                                        ' ;6
 dc.b '                                        ' ;7
 dc.b '                                        ' ;8
 dc.b '                                        ' ;9
 dc.b '                                        ' ;0
 dc.b '                                        ' ;1

ONEPLAYERMENU_OPTS:
 dc.w 16,13,8,1
 dc.w 15,15,10,1
 dc.w 12,17,16,1
 dc.w 14,19,12,1
 dc.w 12,23,16,1
 dc.w 18,25,4,1
 dc.w -1


MASTERPLAYERMENU_TXT:
;      0123456789012345678901234567890123456789
 dc.b '                                        ' ;0
 dc.b '                                        ' ;1
 dc.b '                                        ' ;2
 dc.b '                                        ' ;3
 dc.b '                                        ' ;4
 dc.b '                                        ' ;5
 dc.b '                                        ' ;6
 dc.b '                                        ' ;7
 dc.b '                                        ' ;8
 dc.b '                                        ' ;9
 dc.b '                                        ' ;0
 dc.b '                                        ' ;1
 dc.b '            2 PLAYER  MASTER            ' ;2
 dc.b '                                        ' ;3
CURRENTLEVELLINEM:
 dc.b '           LEVEL 1 : THE GATE           ' ;4 
 dc.b '                                        ' ;5
 dc.b '               PLAY  GAME               ' ;6
 dc.b '                                        ' ;7
 dc.b '            CONTROL  OPTIONS            ' ;8
 dc.b '                                        ' ;9
 dc.b '                                        ' ;0
 dc.b '                                        ' ;1
 dc.b '                                        ' ;2
 dc.b '                                        ' ;3
 dc.b '                                        ' ;4
 dc.b '                                        ' ;5
 dc.b '                                        ' ;6
 dc.b '                                        ' ;7
 dc.b '                                        ' ;8
 dc.b '                                        ' ;9
 dc.b '                                        ' ;0
 dc.b '                                        ' ;1

MASTERPLAYERMENU_OPTS:
 dc.w 12,12,16,1
 dc.w 6,14,28,1
 dc.w 15,16,10,1
 dc.w 12,18,16,1
 dc.w -1

SLAVEPLAYERMENU_TXT:
;      0123456789012345678901234567890123456789
 dc.b '                                        ' ;0
 dc.b '                                        ' ;1
 dc.b '                                        ' ;2
 dc.b '                                        ' ;3
 dc.b '                                        ' ;4
 dc.b '                                        ' ;5
 dc.b '                                        ' ;6
 dc.b '                                        ' ;7
 dc.b '                                        ' ;8
 dc.b '                                        ' ;9
 dc.b '                                        ' ;9
 dc.b '                                        ' ;1
 dc.b '             2 PLAYER SLAVE             ' ;4
 dc.b '                                        ' ;3
 dc.b '               PLAY  GAME               ' ;2
 dc.b '                                        ' ;5
 dc.b '            CONTROL  OPTIONS            ' ;0
 dc.b '                                        ' ;1
 dc.b '                                        ' ;3
 dc.b '                                        ' ;7
 dc.b '                                        ' ;7
 dc.b '                                        ' ;3
 dc.b '                                        ' ;3
 dc.b '                                        ' ;3
 dc.b '                                        ' ;4
 dc.b '                                        ' ;5
 dc.b '                                        ' ;6
 dc.b '                                        ' ;7
 dc.b '                                        ' ;9
 dc.b '                                        ' ;9
 dc.b '                                        ' ;9
 dc.b '                                        ' ;9


PROTMENU_TXT:
;      0123456789012345678901234567890123456789
 dc.b '                                        ' ;0
 dc.b '                                        ' ;1
 dc.b '                                        ' ;2
 dc.b '                                        ' ;3
 dc.b '                                        ' ;4
 dc.b '                                        ' ;5
 dc.b '                                        ' ;6
 dc.b '                                        ' ;7
 dc.b '                                        ' ;8
 dc.b '                                        ' ;9
 dc.b '                                        ' ;0
 dc.b '                                        ' ;1
 dc.b ' TYPE IN THREE DIGIT CODE FROM MANUAL : ' ;2
 dc.b '                                        ' ;3
PROTLINE:
 dc.b '        TABLE 00 ROW 00 COLUMN 00       ' ;4
 dc.b '                                        ' ;5
 dc.b '                                        ' ;6
 dc.b '                                        ' ;7
 dc.b '                                        ' ;8
 dc.b '                                        ' ;9
 dc.b '                                        ' ;0
 dc.b '                                        ' ;1
 dc.b '                                        ' ;2
 dc.b '                                        ' ;3
 dc.b '                                        ' ;4
 dc.b '                                        ' ;5
 dc.b '                                        ' ;6
 dc.b '                                        ' ;7
 dc.b '                                        ' ;9
 dc.b '                                        ' ;0
 dc.b '                                        ' ;1



SLAVEPLAYERMENU_OPTS:
 dc.w 12,12,16,1
 dc.w 15,14,10,1
 dc.w 12,16,16,1
 dc.w -1

 
PLAYER_OPTS:
;      0123456789012345678901234567890123456789
 dc.b '                 1 PLAYER               '
 dc.b '             2  PLAYER MASTER           '
 dc.b '              2 PLAYER SLAVE            '
 
LEVEL_OPTS:
;      0123456789012345678901234567890123456789
 dc.b '      LEVEL  1 :          THE GATE      '
 dc.b '      LEVEL  2 :       STORAGE BAY      '
 dc.b '      LEVEL  3 :     SEWER NETWORK      '
 dc.b '      LEVEL  4 :     THE COURTYARD      '
 dc.b '      LEVEL  5 :      SYSTEM PURGE      '
 dc.b '      LEVEL  6 :         THE MINES      '
 dc.b '      LEVEL  7 :       THE FURNACE      '
 dc.b '      LEVEL  8 :  TEST ARENA GAMMA      '
 dc.b '      LEVEL  9 :      SURFACE ZONE      '
 dc.b '      LEVEL 10 :     TRAINING AREA      '
 dc.b '      LEVEL 11 :       ADMIN BLOCK      '
 dc.b '      LEVEL 12 :           THE PIT      '
 dc.b '      LEVEL 13 :            STRATA      '
 dc.b '      LEVEL 14 :      REACTOR CORE      '
 dc.b '      LEVEL 15 :     COOLING TOWER      '
 dc.b '      LEVEL 16 :    COMMAND CENTRE      '

CONTROL_TXT:
;      0123456789012345678901234567890123456789
 dc.b '                                        ' ;0
 dc.b '                                        ' ;1
 dc.b '                                        ' ;2
 dc.b '                                        ' ;3
 dc.b '            DEFINE  CONTROLS            ' ;4
 dc.b '                                        ' ;5
KEY_LINES:
 dc.b '     TURN LEFT                  LCK     ' ;6
 dc.b '     TURN RIGHT                 RCK     ' ;7
 dc.b '     FORWARDS                   UCK     ' ;8
 dc.b '     BACKWARDS                  DCK     ' ;9
 dc.b '     FIRE                       RAL     ' ;0
 dc.b '     OPERATE DOOR/LIFT/SWITCH   SPC     ' ;1
 dc.b '     RUN                        RSH     ' ;2
 dc.b '     FORCE SIDESTEP             RAM     ' ;3
 dc.b '     SIDESTEP LEFT               .      ' ;4
 dc.b '     SIDESTEP RIGHT              /      ' ;5
 dc.b '     DUCK                        D      ' ;6
 dc.b '     LOOK BEHIND                 L      ' ;7
 dc.b '                                        ' ;8
 dc.b '             OTHER CONTROLS             ' ;9
 dc.b '                                        ' ;0
 dc.b ' PULSE RIFLE      1  PAUSE            P ' ;1
 dc.b ' SHOTGUN          2  QUIT           ESC ' ;2
 dc.b ' PLASMA GUN       3  MOUSE CONTROL    M ' ;3
 dc.b ' GRENADE LAUNCHER 4  JOYSTICK CONTROL J ' ;4
 dc.b ' ROCKET LAUNCHER  5  KEYBOARD CONTROL K ' ;5
 dc.b '                                        ' ;6
 dc.b '               MAIN  MENU               ' ;7
 dc.b '                                        ' ;8
 dc.b '                                        ' ;9
 dc.b '                                        ' ;0
 dc.b '                                        ' ;1

CONTROL_OPTS:
 dc.w 5,6,30,1
 dc.w 5,7,30,1
 dc.w 5,8,30,1
 dc.w 5,9,30,1
 dc.w 5,10,30,1
 dc.w 5,11,30,1
 dc.w 5,12,30,1
 dc.w 5,13,30,1
 dc.w 5,14,30,1
 dc.w 5,15,30,1
 dc.w 5,16,30,1
 dc.w 5,17,30,1
 dc.w 15,27,10,1
 dc.w -1

PLOPT: dc.w 0

INSTRUCTIONS_TXT:
;      0123456789012345678901234567890123456789
 dc.b 'Main controls:                          ' ;1
 dc.b '                                        ' ;2
 dc.b 'Curs Keys = Forward / Backward          ' ;3
 dc.b '            Turn left / right           ' ;4
 dc.b '          Right Alt = Fire              ' ;5
 dc.b '        Right Shift = Run               ' ;6
 dc.b '                  > = Slide Left        ' ;7
 dc.b '                  ? = Slide Right       ' ;8
 dc.b '              SPACE = Operate Door/Lift ' ;9
 dc.b '                  D = Duck              ' ;0
 dc.b '                  J = Joystick Control  ' ;1
 dc.b '                  K = Keyboard Control  ' ;2
 dc.b '                                        ' ;3
 dc.b '              1,2,3 = Select weapon     ' ;4
 dc.b '              ENTER = Toggle screen size' ;5
 dc.b '                ESC = Quit              ' ;6
 dc.b '                                        ' ;7
 dc.b '                                        ' ;8
 dc.b 'The one player game has no objective and' ;9
 dc.b 'the only way to finish is to die or quit' ;0
 dc.b '                                        ' ;1
 dc.b 'The two-player game is supposed to be a ' ;2
 dc.b 'fight to the death but will probably be ' ;3
 dc.b 'a fight-till-we-find-the-rocket-launcher' ;4
 dc.b 'then-blow-ourselves-up type game.       ' ;5
 dc.b '                                        ' ;6
 dc.b 'LOOK OUT FOR TELEPORTERS: They usually  ' ;7
 dc.b 'have glowing red walls and overhead     ' ;8
 dc.b 'lights. Useful for getting behind your  ' ;9
 dc.b ' opponent!                              ' ;0
 dc.b '  Just a taster of what is to come....  ' ;1
 dc.b '                                        ' ;0

INSTRUCTIONS_OPTS:
 dc.w 0,0,0,1
 dc.w -1

CREDITMENU_TXT:

;      0123456789012345678901234567890123456789
 dc.b '    Programming, Game Code, Graphics    ' ;0
 dc.b '         Game Design and Manual         ' ;1
 dc.b '            Andrew Clitheroe            ' ;2
 dc.b '                                        ' ;3
 dc.b '             Alien Graphics             ' ;4
 dc.b '             Michael  Green             ' ;5
 dc.b '                                        ' ;6
 dc.b '           3D Object Designer           ' ;7
 dc.b '            Charles Blessing            ' ;8
 dc.b '                                        ' ;9
 dc.b '              Level Design              ' ;0
 dc.b 'Michael Green  Ben Chanter   Jackie Lang' ;1
 dc.b '     Kai Barrett Charles Blessing       ' ;2
 dc.b '                                        ' ;3
 dc.b '           Creative  Director           ' ;4
 dc.b '              Martyn Brown              ' ;5
 dc.b '                                        ' ;6
 dc.b '       Project Manager and Manual       ' ;7
 dc.b "            Martin O'Donnell            " ;8
 dc.b '                                        ' ;9
 dc.b '              Music + SFX               ' ;0
 dc.b '              Bjorn Lynne               ' ;1
 dc.b '                                        ' ;2
 dc.b '      Cover Illustration and Logo       ' ;3
 dc.b '             Kevin Jenkins              ' ;4
 dc.b '                                        ' ;5
 dc.b '      Packaging and Manual Design       ' ;6
 dc.b '               Paul Sharp               ' ;7
 dc.b '                                        ' ;8
 dc.b '             QA and Playtest            ' ;9
 dc.b '           Phil and The Wolves          ' ;0
 dc.b '                                        ' ;1
 
 dc.b '    Serial Link and 3D Object Editor:   ' ;4
 dc.b '                   by                   ' ;5
 dc.b '            Charles Blessing            ' ;6
 dc.b '                                        ' ;7
 dc.b '                Graphics:               ' ;8
 dc.b '                   by                   ' ;9
 dc.b '              Mike  Oakley              ' ;0
 dc.b '                                        ' ;1
 dc.b '             Title  Picture             ' ;2
 dc.b '                   by                   ' ;3
 dc.b '               Mike Green               ' ;4
 dc.b '                                        ' ;5
 dc.b ' Inspiration, incentive, moral support, ' ;6
 dc.b '     level design and plenty of tea     ' ;7
 dc.b '         generously supplied by         ' ;8
 dc.b '                                        ' ;9
 dc.b '              Jackie  Lang              ' ;0
 dc.b '                                        ' ;1
 dc.b '    Music for the last demo composed    ' ;2
 dc.b '       by the inexpressibly evil:       ' ;3
 dc.b '                                        ' ;8
 dc.b '            *BAD* BEN CHANTER           ' ;9
 dc.b '                                        ' ;0
 dc.b '    Sadly no room for music this time   ' ;1
 dc.b '                                        ' ;7
 dc.b '                                        ' ;7

CREDITMENU_OPTS:
 dc.w 0,0,1,1
 dc.w -1


;      0123456789012345678901234567890123456789
 dc.b '                                        ' ;0
 dc.b '                                        ' ;1
 dc.b '                                        ' ;2
 dc.b '                                        ' ;3
 dc.b '                                        ' ;4
 dc.b '                                        ' ;5
 dc.b '                                        ' ;6
 dc.b '                                        ' ;7
 dc.b '                                        ' ;8
 dc.b '                                        ' ;9
 dc.b '                                        ' ;0
 dc.b '                                        ' ;1
 dc.b '                                        ' ;2
 dc.b '                                        ' ;3
 dc.b '                                        ' ;4
 dc.b '                                        ' ;5
 dc.b '                                        ' ;6
 dc.b '                                        ' ;7
 dc.b '                                        ' ;8
 dc.b '                                        ' ;9
 dc.b '                                        ' ;0
 dc.b '                                        ' ;1
 dc.b '                                        ' ;2
 dc.b '                                        ' ;3
 dc.b '                                        ' ;4
 dc.b '                                        ' ;5
 dc.b '                                        ' ;6
 dc.b '                                        ' ;7
 dc.b '                                        ' ;8
 dc.b '                                        ' ;9
 dc.b '                                        ' ;0
 dc.b '                                        ' ;1


********************************************************
 
PUTIN32:
 move.w #31,d2
p32loop:
 moveq #0,d5
 move.l (a0)+,d3
 move.w d3,d4
 swap d3
 move.b d4,d5
 lsr.w #8,d4

 muls d0,d3
 muls d0,d4
 muls d0,d5
 lsr.l #8,d3
 lsr.l #8,d4
 lsr.l #8,d5
 move.w d3,d6
 swap d3
 move.w d6,d3
 move.w d4,d6
 swap d4
 move.w d6,d4
 move.w d5,d6
 swap d5
 move.w d6,d5
 and.w #%11110000,d3
 and.w #%11110000,d4
 and.w #%11110000,d5
 lsl.w #4,d3
 add.w d4,d3
 lsr.w #4,d5
 add.w d5,d3
 move.w d3,2(a1)
 swap d3
 swap d4
 swap d5
 and.w #%1111,d3
 and.w #%1111,d4
 and.w #%1111,d5
 lsl.w #8,d3
 lsl.w #4,d4
 add.w d4,d3
 add.w d5,d3
 move.w d3,2+(132*4)(a1)
 addq #4,a1
 dbra d2,p32loop


 rts

**************************************

FADEAMOUNT: dc.w 0
FADEVAL: dc.w 0

FADEUPTITLE:

 move.w FADEVAL,d0
 move.w FADEAMOUNT,d1
fadeuploop:

 move.l #TITLEPAL,a0
 move.l #TITLEPALCOP,a1

wvb:
 btst #5,$dff000+intreqrl
 beq.s wvb
 move.w #$20,$dff000+intreq 

 bsr PUTIN32
 add.w #4,a1
 bsr PUTIN32
 add.w #4,a1
 bsr PUTIN32
 add.w #4,a1
 bsr PUTIN32

 addq.w #4,d0
 dbra d1,fadeuploop

 subq #4,d0
 move.w d0,FADEVAL

 rts
 
CLEARTITLEPAL:
 PRSDP
 move.l #TITLEPALCOP,a0
 move.w #7,d1
clrpal:
 move.w #31,d0
clr32
 move.w #0,2(a0)
 addq #4,a0
 dbra d0,clr32
 addq #4,a0
 dbra d1,clrpal
 PRSDQ
 rts

FADEDOWNTITLE:

 move.w FADEVAL,d0
 move.w FADEAMOUNT,d1
fadedownloop:

 move.l #TITLEPAL,a0
 move.l #TITLEPALCOP,a1

.wvb:
 btst #5,$dff000+intreqrl
 beq.s .wvb
 move.w #$20,$dff000+intreq 

 bsr PUTIN32
 add.w #4,a1
 bsr PUTIN32
 add.w #4,a1
 bsr PUTIN32
 add.w #4,a1
 bsr PUTIN32

 subq.w #4,d0
 dbra d1,fadedownloop

 addq #4,d0
 move.w d0,FADEVAL

 rts

LOADTITLESCRN2:


 move.l #MEMF_CLEAR,d1
 move.l #52400,d0
 move.l 4.w,a6
 jsr    _LVOAllocMem(a6)
 tst.l  d0
 beq    .nomem

 move.l d0,tempptr
 
 move.l #TITLESCRNNAME2,d1
 move.l #1005,d2
 move.l doslib,a6
 jsr -30(a6)
 move.l d0,handle
 move.l d0,d1
 move.l doslib,a6
; move.l TITLESCRNADDR,d2
 move.l tempptr,d2
 move.l #10240*7,d3
 jsr -42(a6)
 move.l doslib,a6
 move.l handle,d1
 jsr -36(a6)

	
 move.l TITLESCRNADDR,a0
 move.l tempptr,d0

 moveq #0,d1
 lea WorkSpace,a1
 lea $0,a2
 jsr unLHA

  move.l tempptr,a1
 move.l #52400,d0
 CALLEXEC FreeMem
  
.nomem
 
 rts

tempptr dc.l 0


GETTITLEMEM:
; move.l #2,d1
; move.l #10240*7,d0
; move.l 4.w,a6
; jsr -198(a6)
; move.l d0,TITLESCRNADDR
; 
 move.l #$dff000-$2cdfe4,a4
 
 move.l #2,d1
 move.l #258*16*5,d0
 move.l 4.w,a6
 jsr -198(a6)
 move.l d0,OPTSPRADDR
 
 rts
 
ProtChkJLev1:

PROTSETUP:
 incbin "ab3:includes/protsetupenc"

; Need to: Decode protection calling
; routine
; use null values to call it and erase
; it from memory
; erase this routine and return.

; include "ab3:source/protsetup"
 

RELEASETITLEMEM:
; move.l TITLESCRNADDR,d1
; move.l d1,a1
; move.l #10240*7,d0
; move.l 4.w,a6
; jsr -210(a6)

 move.l OPTSPRADDR,d1
 move.l d1,a1
 move.l #258*80,d0
 move.l 4.w,a6
 jsr -210(a6)
 rts
 

PROTCALLENC:
; incbin "ab3:source/protcallenc.bin

; one pass, all instructions executed.
; must call protection routine,store
; value somewhere, call ask routine,
; compare returned value, if correct
; set up all values, then return.

 include "ab3:source_cd32/protcallenc"

ENDPROT:
 
LOADTITLESCRN:
 
; move.l #TITLESCRNNAME,d1
; move.l #1005,d2
; move.l doslib,a6
; jsr -30(a6)
; move.l d0,handle
; move.l d0,d1
; move.l doslib,a6
; move.l TITLESCRNADDR,d2
; move.l #10240*7,d3
; jsr -42(a6)
; move.l doslib,a6
; move.l handle,d1
; jsr -36(a6)
 
 rts

RVAL2: dc.w 0

SETUPTITLESCRN:

 rts

 PRSDR
 move.l #OPTCOP,a0
 move.l #rain,a1
 move.w #255,d0
putinrain:
 move.w (a1)+,d1
 move.w d1,6(a0)
 move.w d1,6+4(a0)
 move.w d1,6+8(a0)
 move.w d1,6+12(a0)
 add.w #4*14,a0

 dbra d0,putinrain

; Put addr into copper.
 move.l OPTSPRADDR,d0
 move.w d0,tsp0l
 swap d0
 move.w d0,tsp0h
 swap d0
 add.l #258*16,d0
 move.w d0,tsp1l
 swap d0
 move.w d0,tsp1h
 swap d0
 add.l #258*16,d0
 move.w d0,tsp2l
 swap d0
 move.w d0,tsp2h
 swap d0
 add.l #258*16,d0
 move.w d0,tsp3l
 swap d0
 move.w d0,tsp3h
 swap d0
 add.l #258*16,d0
 move.w d0,tsp4l
 swap d0
 move.w d0,tsp4h
 
 move.l #nullspr,d0
 move.w d0,tsp5l
 move.w d0,tsp6l
 move.w d0,tsp7l
 swap d0
 move.w d0,tsp5h
 move.w d0,tsp6h
 move.w d0,tsp7h 

 move.l TITLESCRNADDR,d0
 move.w d0,ts1l
 swap d0
 move.w d0,ts1h
 swap d0
 add.l #10240,d0
 move.w d0,ts2l
 swap d0
 move.w d0,ts2h
 swap d0
 add.l #10240,d0
 move.w d0,ts3l
 swap d0
 move.w d0,ts3h
 swap d0
 add.l #10240,d0
 move.w d0,ts4l
 swap d0
 move.w d0,ts4h
 swap d0
 add.l #10240,d0
 move.w d0,ts5l
 swap d0
 move.w d0,ts5h
 swap d0
 add.l #10240,d0
 move.w d0,ts6l
 swap d0
 move.w d0,ts6h
 swap d0
 add.l #10240,d0
 move.w d0,ts7l
 swap d0
 move.w d0,ts7h
 rts 

RVAL1: dc.w 0

DummyAdds:
 dc.l dummy-78935450
 dc.l dummy-78935450
 dc.l dummy-78935450
 dc.l dummy-78935450
 dc.l dummy-78935450
 dc.l dummy-78935450
 dc.l dummy-78935450
 dc.l dummy-78935450
 dc.l dummy-78935450
 dc.l dummy-78935450

dummycall
 dc.w $4e75-123
 
protspace: ds.l 200

 include "ab3:source_4000/LEVEL_BLURB"
 
font:
 incbin "ab3:includes/OptFont"

rain: incbin "ab3:includes/optcop"
