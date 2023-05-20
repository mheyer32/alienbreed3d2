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
; 6: LOOP Game_Start
; 7. Option select screens
; 8. Free music mem, allocate level mem.
; 9. Load level
;10. Play level with options selected
;11. Reload title music
;12. Reload title screen
;13. goto 6


				align 4
OPTSPRADDR:
				dc.l	0

Game_FinishedLevel_b:
				dc.w	0

				align	4


Game_Start:
				move.b	#PLR_SINGLE,Plr_MultiplayerType_b
				CALLC	Vid_OpenMainScreen

				move.l	#GLF_DatabaseName_vb,a0
				jsr		IO_LoadFile
				move.l	d0,GLF_DatabasePtr_l

				move.l	#LEVELTEXTNAME,a0
				jsr		IO_LoadFile
				move.l	d0,Lvl_IntroTextPtr_l

				jsr		_InitLowLevel

				;jsr		mnu_start	; For some reason this doesn't work
										; Shows the wrong menu

				jsr		mnu_copycredz

				CALLC	mnu_setscreen
				move.l	a7,mnu_mainstack	; not sure if this is the right thing or even in use...

				jsr		IO_InitQueue

				;move.w	#0,FADEVAL
				;move.w	#31,FADEAMOUNT
				;bsr		FADEUPTITLE

				jsr		Res_LoadSoundFx
				jsr		Res_LoadWallTextures
				jsr		Res_LoadFloorTextures
				jsr		Res_LoadObjects

				move.l	#draw_BackdropImageName_vb,a0
				move.l	#Draw_BackdropImagePtr_l,d0
				move.l	#0,d1
				jsr		IO_QueueFile

; jsr _StopPlayer
; jsr _RemPlayer


***********************************************
				jsr		IO_FlushQueue
***********************************************

				jsr		Res_PatchSoundFx

				;move.w	#23,FADEAMOUNT
				;bsr		FADEDOWNTITLE

; bsr ASKFORDISK

				IFNE	CD32VER
				move.l	#115,d1
				CALLDOS	Delay
				ENDC

				bsr		DEFAULTGAME

BACKTOMENU:
				CALLC	Sys_ClearKeyboard

				cmp.b	#PLR_SLAVE,Plr_MultiplayerType_b
				beq.s	BACKTOSLAVE
				cmp.b	#PLR_MASTER,Plr_MultiplayerType_b
				beq.s	BACKTOMASTER
				bsr		READMAINMENU
				bra		DONEMENU
BACKTOMASTER:
				bsr		MASTERMENU
				bra		DONEMENU
BACKTOSLAVE:
				bsr		SLAVEMENU
DONEMENU:


				CALLC	mnu_clearscreen

				;	bsr		WAITREL

				FILTER

				tst.b	SHOULDQUIT
				bne		QUITTT

				clr.b	Game_FinishedLevel_b

				move.w	#0,Plr1_SnapAngPos_w
				move.w	#0,Plr2_SnapAngPos_w
				move.w	#0,Plr1_AngPos_w
				move.w	#0,Plr2_AngPos_w
				move.b	#0,Plr1_GunSelected_b
				move.b	#0,Plr2_GunSelected_b

***************************
				clr.b	AI_NoEnemies_b
***************************

				move.l	#Plr_Health_w,a0
				move.l	#Plr_Shield_w,a1
				move.l	#Plr1_Health_w,a2
				move.l	#Plr1_Shield_w,a3
				move.l	#Plr2_Health_w,a4
				move.l	#Plr2_Shield_w,a5

				REPT	11						; copy Plr_Health_w and
				move.l	(a0),(a2)+				; Plr_AmmoCounts_vw
				move.l	(a0)+,(a4)+
				ENDR

				REPT	6						; copy Plr_Shield_w and
				move.l	(a1),(a3)+				; Plr_Weapons_vw
				move.l	(a1)+,(a5)+
				ENDR

*************************************
				jsr		IO_InitQueue

				CALLC	Draw_ResetGameDisplay

*************************************

				jsr		Game_Begin

*************************************

				tst.b	Game_FinishedLevel_b
				beq		dontusestats

				move.l	#Plr_Health_w,a0
				move.l	#Plr_Shield_w,a1
				move.l	#Plr1_Health_w,a2
				move.l	#Plr1_Shield_w,a3

				REPT	11
				move.l	(a2)+,(a0)+
				ENDR

				REPT	6
				move.l	(a3)+,(a1)+
				ENDR

dontusestats:
				CALLC	mnu_setscreen


				bra		BACKTOMENU

QUITTT:
				move.l	Lvl_DataPtr_l,a1
				CALLEXEC FreeVec

				IFND BUILD_WITH_C

				move.l	Vid_FastBufferAllocPtr_l,a1
				CALLEXEC FreeVec

				move.l	Vid_MyRaster0_l,a0
				move.w	#SCREEN_WIDTH,d0
				move.w	#SCREEN_HEIGHT*8+1,d1
				CALLGRAF FreeRaster

				move.l	Vid_MyRaster1_l,a0
				move.w	#SCREEN_WIDTH,d0
				move.w	#SCREEN_HEIGHT*8+1,d1
				CALLGRAF FreeRaster

				ELSE

				CALLC Vid_CloseMainScreen

				ENDIF

; jsr Res_FreeWallTextures
				jsr		Res_FreeSoundFx
				jsr		Res_FreeFloorTextures
				jsr		Res_FreeObjects

				CALLC	Sys_Done

				move.l	#0,d0

				rts

; KEY OPTIONS:
AssignableKeys_vb:
turn_left_key:		dc.b	RAWKEY_LEFT
turn_right_key:		dc.b	RAWKEY_RIGHT
forward_key:		dc.b	RAWKEY_W
backward_key:		dc.b	RAWKEY_S
fire_key:			dc.b	RAWKEY_CTRL
operate_key:		dc.b	RAWKEY_F
run_key:			dc.b	RAWKEY_LSHIFT
force_sidestep_key:	dc.b	RAWKEY_LALT
sidestep_left_key:	dc.b	RAWKEY_A
sidestep_right_key:	dc.b	RAWKEY_D
duck_key:			dc.b	RAWKEY_C
look_behind_key:	dc.b	RAWKEY_L
jump_key:			dc.b	RAWKEY_SPACEBAR
look_up_key:		dc.b	RAWKEY_EQUAL
look_down_key:		dc.b	RAWKEY_UNDERSCORE
centre_view_key:	dc.b	RAWKEY_SEMICOLON
next_weapon_key:	dc.b	RAWKEY_BSLASH


				IFD	DEV

				ENDC

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
				move.b	d0,Lvl_BinFilenameX_vb
				move.b	d0,Lvl_GfxFilenameX_vb
				move.b	d0,Lvl_ClipsFilenameX_vb
				move.b	d0,Lvl_MapFilenameX_vb
				move.b	d0,Lvl_FlyMapFilenameX_vb

				cmp.b	#PLR_SLAVE,Plr_MultiplayerType_b
				beq		Plr_InitSlave
				cmp.b	#PLR_MASTER,Plr_MultiplayerType_b
				beq		Plr_InitMaster
				st		AI_NoEnemies_b
onepla:
				rts

Plr_InitMaster:
				clr.b	AI_NoEnemies_b
				move.w	PLOPT,d0
				jsr		SENDFIRST

				move.w	Rand1,d0
				jsr		SENDFIRST

				bsr		TWOPLAYER
				rts

Plr_InitSlave:
				clr.b	AI_NoEnemies_b
				jsr		RECFIRST
				move.w	d0,PLOPT
				add.b	#'a',d0
				move.b	d0,Lvl_BinFilenameX_vb
				move.b	d0,Lvl_GfxFilenameX_vb
				move.b	d0,Lvl_ClipsFilenameX_vb
				move.b	d0,Lvl_MapFilenameX_vb
				move.b	d0,Lvl_FlyMapFilenameX_vb

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

********************************************************

READMAINMENU:

				move.b	#PLR_SINGLE,Plr_MultiplayerType_b

				move.w	MAXLEVEL,d0


				move.l	#mnu_CURRENTLEVELLINE,a1
				muls	#40,d0
				move.l	GLF_DatabasePtr_l,a0
				add.l	#GLFT_LevelNames_l,a0
				add.l	d0,a0
				bsr		PUTINLINE

; Stay here until 'play game' is selected.

				lea		mnu_MYMAINMENU,a0
				bsr		MYOPENMENU

.rdlop:
				lea		mnu_MYMAINMENU,a0
				bsr		CHECKMENU

***************************************************************
				tst.w	d0
				beq		playgame
***************************************************************
				cmp.w	#1,d0
				bne		.noopt

				bra		MASTERMENU

.noopt:
***************************************************************
				cmp.w	#2,d0
				bne.s	.nonextlev

				bsr	levelMenu;cycleLevel

				lea		mnu_MYMAINMENU,a0
				bsr		MYOPENMENU

				bsr		WAITREL
				bra		READMAINMENU;.rdlop

.nonextlev:
***************************************************************
				cmp.w	#3,d0
				bne		.nocontrol

				bsr		CHANGECONTROLS

				lea		mnu_MYMAINMENU,a0
				bsr		MYOPENMENU

				bsr		WAITREL
				bra		.rdlop

.nocontrol:
***************************************************************
				cmp.w	#4,d0
				bne		.nocred

				;jsr		mnu_viewcredz
				lea		mnu_MYMAINMENU,a0
				bsr		MYOPENMENU

				bra		.rdlop

.nocred:
***************************************************************
				cmp.w	#5,d0
				bne		.noload

				jsr		LOADPOSITION

				lea		mnu_MYMAINMENU,a0
				bsr		MYOPENMENU

				bsr		WAITREL
				bra		.rdlop

.noload:
***************************************************************
				cmp.w	#6,d0
				bne		.nosave
				bsr		WAITREL

				jsr		SAVEPOSITION

				lea		mnu_MYMAINMENU,a0
				bsr		MYOPENMENU

				bsr		WAITREL
				bra		.rdlop
.nosave:
***************************************************************
;				cmp.w	#7,d0
;				bne		playgame
;				bsr		WAITREL

;				bsr		customOptions

;				lea		mnu_MYMAINMENU,a0
;				bsr		MYOPENMENU

				bsr		WAITREL
				bra		.rdlop
***************************************************************

;fixme: there are better ways to do this, but it works.AL
levelMenu:
				lea		mnu_MYLEVELMENU,a0
				bsr		MYOPENMENU

				lea		mnu_MYLEVELMENU,a0
				bsr		CHECKMENU

				cmp.w	#8,d0
				beq		levelMenu2
				SAVEREGS
				;bsr	DEFAULTGAME
				not.b	LOADEXT
				bsr		DEFGAME
				GETREGS
				move	d0,MAXLEVEL

				rts

levelMenu2:
				lea		mnu_MYLEVELMENU2,a0
				bsr		MYOPENMENU

				lea		mnu_MYLEVELMENU2,a0
				bsr		CHECKMENU

				cmp.w	#8,d0
				beq	.levelSelectDone
				SAVEREGS
				;bsr	DEFAULTGAME
				not.b	LOADEXT
				add	#8,d0
				bsr	DEFGAME
				GETREGS
				move	d0,MAXLEVEL
				add	#8,MAXLEVEL

.levelSelectDone
				rts
***************************************************************
Lvl_DefFilename_vb:		dc.b	'ab3:levels/level_'
Lvl_DefFilenameX_vb:	dc.b	'a/deflev.dat',0
LOADEXT:				dc.b	0
				even
DEFGAMEPOS:	dc.l	0
DEFGAMELEN:	dc.l	0
***************************************************************
DEFGAME:
				add.b	#'a',d0
				move.b	d0,Lvl_DefFilenameX_vb
				;move.l	#MEMF_ANY,IO_MemType_l;		 should I have left this in?
				move.l	#Lvl_DefFilename_vb,a0
				move.l	#DEFGAMEPOS,d0
				move.l	#DEFGAMELEN,d1
				jsr		IO_InitQueue
				jsr		IO_QueueFile
				jsr		IO_FlushQueue

				tst.b	d6;				 can use this now
				bne	.error_nodef;			 can use this now

				move.l	DEFGAMEPOS,a0			; address of first saved game.

				move.l	#Plr_Health_w,a1
				move.l	#Plr_Shield_w,a2
				move.w	(a0)+,MAXLEVEL

				REPT	11
				move.l	(a0)+,(a1)+
				ENDR
				REPT	6
				move.l	(a0)+,(a2)+
				ENDR

				move.l	DEFGAMEPOS,a1;		req?
				CALLEXEC FreeVec;		req?

				bra	.defloaded;			 can use this now

.error_nodef;								 can use this now
				bsr	DEFAULTGAME;			 can use this now

.defloaded;								 can use this now
				not.b	LOADEXT;			 reset for next load
				rts
***************************************************************
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

.NODELETE:
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

				move.b	#PLR_MASTER,Plr_MultiplayerType_b

				move.w	#0,LEVELSELECTED

				move.w	#0,d0
				move.l	#mnu_CURRENTLEVELLINEM,a1
				muls	#40,d0
				move.l	GLF_DatabasePtr_l,a0
				add.l	#GLFT_LevelNames_l,a0
				add.l	d0,a0
				bsr		PUTINLINE

; Stay here until 'play game' is selected.

				lea		mnu_MYMASTERMENU,a0
				bsr		MYOPENMENU

.rdlop:
				lea		mnu_MYMASTERMENU,a0
				bsr		CHECKMENU

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
				move.l	GLF_DatabasePtr_l,a0
				add.l	#GLFT_LevelNames_l,a0
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

				lea		mnu_MYMASTERMENU,a0
				bsr		MYOPENMENU

				bra		.rdlop

.nocontrol:

.playgame

				move.w	LEVELSELECTED,PLOPT
				rts

SLAVEMENU:

				move.b	#PLR_SLAVE,Plr_MultiplayerType_b

; Stay here until 'play game' is selected.

				lea		mnu_MYSLAVEMENU,a0
				bsr		MYOPENMENU

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

				lea		mnu_MYSLAVEMENU,a0
				bsr		MYOPENMENU


				bra		.rdlop

.nocontrol:
.playgame:

				rts

STATBACK:		ds.w	34

TWOPLAYER:

				move.w	#200,Plr1_Health_w
				move.w	#200,Plr2_Health_w

				move.w	#0,Plr1_JetpackFuel_w

				st.b	Plr1_Weapons_vb+1
				st.b	Plr1_Weapons_vb+3
				st.b	Plr1_Weapons_vb+5
				st.b	Plr1_Weapons_vb+7
				st.b	Plr1_Weapons_vb+9
				st.b	Plr1_Weapons_vb+11
				st.b	Plr1_Weapons_vb+13
				st.b	Plr1_Weapons_vb+15
				st.b	Plr1_Weapons_vb+17
				st.b	Plr1_Weapons_vb+19

				st.b	Plr1_Jetpack_w+1

				st.b	Plr2_Weapons_vb+1
				st.b	Plr2_Weapons_vb+3
				st.b	Plr2_Weapons_vb+5
				st.b	Plr2_Weapons_vb+7
				st.b	Plr2_Weapons_vb+9
				st.b	Plr2_Weapons_vb+11
				st.b	Plr2_Weapons_vb+13
				st.b	Plr2_Weapons_vb+15
				st.b	Plr2_Weapons_vb+17
				st.b	Plr2_Weapons_vb+19

				move.w	#0,Plr2_JetpackFuel_w

				st.b	Plr2_Jetpack_w+1

				move.l	#Plr1_AmmoCounts_vw,a0
				move.l	#Plr2_AmmoCounts_vw,a1
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
				CALLC	Draw_BorderEnergyBar

				move.w	#63,OldAmmo
				move.w	#0,Ammo
				CALLC	Draw_BorderAmmoBar
				move.w	#0,OldAmmo

				move.b	#0,Plr1_GunSelected_b

				move.b	#0,Plr2_GunSelected_b
				rts

newdum:
				rts

DEFAULTGAME:
				move.w	#0,MAXLEVEL

				move.l	#Plr_Health_w,a0
				move.l	#Plr_Shield_w,a1
				clr.l	(a0)+
				clr.l	(a0)+
				clr.l	(a0)+
				clr.l	(a0)+
				clr.l	(a0)+
				clr.l	(a0)+
				clr.l	(a0)+
				clr.l	(a0)+
				clr.l	(a0)+
				clr.l	(a0)+
				clr.l	(a0)+

				clr.l	(a1)+
				clr.l	(a1)+
				clr.l	(a1)+
				clr.l	(a1)+
				clr.l	(a1)+
				clr.l	(a1)+

				move.w	#200,Plr_Health_w
				move.w	#$ff,Plr_Weapons_vw

				move.l	GLF_DatabasePtr_l,a5
				add.l	#GLFT_ShootDefs_l,a5
				move.w	(a5),d0

				move.l	#Plr_AmmoCounts_vw,a5
				move.w	#20,(a5,d0.w*2)

				rts


**************************************************

CHANGECONTROLS:

; copy current setting over to menu
				move.l	#AssignableKeys_vb,a0
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

				move.l	#AssignableKeys_vb,a1
				moveq	#0,d1
				move.b	d0,d1

				movem.l	(a7)+,d0/a0

				move.b	d1,(a1,d0.w)
				add.w	#132,d1
				move.b	d1,1(a0)
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

				move.l	#AssignableKeys_vb+11,a1
				moveq	#0,d1
				move.b	d0,d1

				movem.l	(a7)+,d0/a0

				move.b	d1,(a1,d0.w)
				add.w	#132,d1
				move.b	d1,1(a0)
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

				move.l	#KeyMap_vb,a5
WAITREL2:
				btst	#7,$bfe001
				beq.s	WAITREL2

				IFEQ	CD32VER
				tst.b	RAWKEY_SPACEBAR(a5)
				bne.s	WAITREL2
				tst.b	RAWKEY_ENTER(a5)
				bne.s	WAITREL2
				tst.b	RAWKEY_UP(a5)
				bne.s	WAITREL2
				tst.b	RAWKEY_DOWN(a5)
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
.pill:
				move.b	(a0)+,(a1)+
				dbra	d0,.pill
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

SAVEGAMENAME:	dc.b	"ab3:boot.dat",0
				even

SAVEGAMEPOS:	dc.l	0
SAVEGAMELEN:	dc.l	0

LOADPOSITION:

				move.l	#SAVEGAMENAME,a0
				move.l	#SAVEGAMEPOS,d0
				move.l	#SAVEGAMELEN,d1
				jsr		IO_InitQueue
				jsr		IO_QueueFile
				jsr		IO_FlushQueue

				move.l	SAVEGAMEPOS,a2			; address of first saved game.

				move.l	#mnu_LSLOTA+21,a4

				move.l	a2,a3
				add.w	#2+(22*2)+(12*2),a3
				move.w	#4,d7
.findlevs:

				move.l	a4,a1
				move.w	(a3),d1
				muls	#40,d1
				move.l	GLF_DatabasePtr_l,a0
				add.l	#GLFT_LevelNames_l,a0
				add.l	d1,a0
				jsr		PUTINLINE
				add.l	#21,a4
				add.w	#2+(22*2)+(12*2),a3

				dbra	d7,.findlevs

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

				move.l	#Plr_Health_w,a1
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
				move.l	GLF_DatabasePtr_l,a0
				add.l	#GLFT_LevelNames_l,a0
				add.l	d0,a0
				bsr		PUTINLINE

.noload:

				move.l	SAVEGAMEPOS,a1
				CALLEXEC FreeVec

				rts

SAVEPOSITION:

				move.l	#SAVEGAMENAME,a0
				move.l	#SAVEGAMEPOS,d0
				move.l	#SAVEGAMELEN,d1
				jsr		IO_InitQueue
				jsr		IO_QueueFile
				jsr		IO_FlushQueue

				move.l	SAVEGAMEPOS,a2			; address of first saved game.

				add.w	#2+(22*2)+(12*2),a2

				move.l	#mnu_SSLOTA,a4

				move.l	a2,a3
				move.w	#4,d7
.findlevs:
				move.l	a4,a1
				move.w	(a3),d1
				muls	#40,d1
				move.l	GLF_DatabasePtr_l,a0
				add.l	#GLFT_LevelNames_l,a0
				add.l	d1,a0
				jsr		PUTINLINE
				add.l	#21,a4
				add.w	#2+(22*2)+(12*2),a3

				dbra	d7,.findlevs

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

				move.l	#Plr_Health_w,a1
				move.w	MAXLEVEL,(a0)+

				REPT	11
				move.l	(a1)+,(a0)+
				ENDR
				REPT	6
				move.l	(a1)+,(a0)+
				ENDR

				move.l	#SAVEGAMENAME,d1
				move.l	#MODE_NEWFILE,d2
				CALLDOS	Open
				move.l	d0,IO_DOSFileHandle_l

				move.l	SAVEGAMEPOS,d2
				move.l	IO_DOSFileHandle_l,d1
				move.l	SAVEGAMELEN,d3
				CALLDOS	Write

				move.l	IO_DOSFileHandle_l,d1
				CALLDOS	Close

;				move.l	#200,d1
;				CALLDOS	Delay

.nosave:

				move.l	SAVEGAMEPOS,a1
				CALLEXEC FreeVec

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
;SSLOTA:
;				dc.b	'                                        ' ;9
;				dc.b	'                                        ' ;0
;SSLOTB:
;				dc.b	'                                        ' ;1
;				dc.b	'                                        ' ;2
;SSLOTC:
;				dc.b	'                                        ' ;3
;				dc.b	'                                        ' ;4
;SSLOTD:
;				dc.b	'                                        ' ;5
;				dc.b	'                                        ' ;6
;SSLOTE:
;				dc.b	'                                        ' ;7
;				dc.b	'                                        ' ;8
;SSLOTF:
;				dc.b	'                                        ' ;9
;				dc.b	'                                        ' ;0
;				dc.b	'               * CANCEL *               ' ;1
;				dc.b	'                                        ' ;2
;				dc.b	'                                        ' ;3
;				dc.b	'                                        ' ;4
;				dc.b	'                                        ' ;5
;				dc.b	'                                        ' ;6
;				dc.b	'                                        ' ;7
;				dc.b	'                                        ' ;8
;				dc.b	'                                        ' ;9
;				dc.b	'                                        ' ;0
;				dc.b	'                                        ' ;1

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
;VOLLINE:
;				dc.b	'                                        ' ;9
;				dc.b	'                                        ' ;9
;				dc.b	'          PRESS MOUSE BUTTON            ' ;5
;				dc.b	'          WHEN DISK ACTIVITY            ' ;6
;				dc.b	'               FINISHES                 ' ;7
;				dc.b	'                                        ' ;8
;				dc.b	'                                        ' ;1
;				dc.b	'                                        ' ;2
;				dc.b	'                                        ' ;3
;				dc.b	'                                        ' ;4
;				dc.b	'                                        ' ;5
;				dc.b	'                                        ' ;6
;				dc.b	'                                        ' ;7
;				dc.b	'                                        ' ;8
;				dc.b	'                                        ' ;9
;				dc.b	'                                        ' ;0
;				dc.b	'                                        ' ;1

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


**************************************

FADEAMOUNT:		dc.w	0
FADEVAL:		dc.w	0

LEVELTEXTNAME:	dc.b	'ab3:includes/TEXT_FILE'

				even

Lvl_IntroTextPtr_l:
				dc.l	0

font:
				incbin	"starquake.font.bin"

				include	"menu/menunb.s"
