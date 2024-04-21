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
				move.l	a7,sys_RecoveryStack	; Save stack pointer for Sys_FatalError

				move.b	#PLR_SINGLE,Plr_MultiplayerType_b
				CALLC	Vid_OpenMainScreen

				move.l	#GLF_DatabaseName_vb,a0
				jsr		IO_LoadFile
				move.l	d0,GLF_DatabasePtr_l

				move.l	#Game_StoryFile_vb,a0
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
				jsr		Res_LoadFloorsAndTextures
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

game_BackToMenu:
				CALLC	Sys_ClearKeyboard

				cmp.b	#PLR_SLAVE,Plr_MultiplayerType_b
				beq.s	game_BackToSlave

				cmp.b	#PLR_MASTER,Plr_MultiplayerType_b
				beq.s	game_BackToMaster

				bsr		game_ReadMainMenu

				bra		game_DoneMenu

game_BackToMaster:
				bsr		game_MasterMenu

				bra		game_DoneMenu

game_BackToSlave:
				bsr		game_SlaveMenu

game_DoneMenu:
				tst.b	Game_ShouldQuit_b
				bne		Game_Quit

				moveq	#1,d0 ; Fade out
				CALLC	mnu_clearscreen

				;	bsr		game_WaitForMenuKey

				FILTER

				clr.b	Game_FinishedLevel_b
				clr.w	Plr1_SnapAngPos_w
				clr.w	Plr2_SnapAngPos_w
				clr.w	Plr1_AngPos_w
				clr.w	Plr2_AngPos_w
				clr.b	Plr1_GunSelected_b
				clr.b	Plr2_GunSelected_b

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

				bra		game_BackToMenu

Game_Quit:
				moveq	#0,d0 ; No fading
				CALLC	mnu_clearscreen ; Maybe No-op

				move.l	Lvl_DataPtr_l,a1
				CALLEXEC FreeVec

				CALLC	Vid_CloseMainScreen

				jsr		Res_FreeWallTextures
				jsr		Res_FreeSoundFx
				jsr		Res_FreeFloorsAndTextures
				jsr		Res_FreeObjects

				jsr		_CloseLowLevel

				move.l	#0,d0

				rts

; PREFERENCES (TODO - SHIP OUT):

                align 4

; TODO - this should be a strucutre definition.
_Prefs_Persisted::
Prefsfile:
                    dc.b	'k8nx'

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
spare_key:          dc.b    0

	DECLC	Prefs_FullScreen_b
		dc.b	0

	DECLC	Prefs_PixelMode_b
		dc.b	0

	DECLC	Prefs_VertMargin_b
		dc.b	0

	DECLC	Prefs_SimpleLighting_b
		dc.b	0

	DECLC	Prefs_FPSLimit_b
		dc.b	0

	DECLC	Prefs_DynamicLights_b
		dc.b	0

	DECLC	Prefs_RenderQuality_b
		dc.b	0

; Padding
Prefs_Unused_b:	dc.b	0

	DECLC	Prefs_ContrastAdjust_AGA_w
		dc.w	$0100

	DECLC	Prefs_ContrastAdjust_RTG_w
		dc.w	$0100

	DECLC	Prefs_BrightnessOffset_AGA_w
		dc.w	0

	DECLC	Prefs_BrightnessOffset_RTG_w
		dc.w	0

	DECLC	Prefs_GammaLevel_AGA_b
		dc.b	0

	DECLC	Prefs_GammaLevel_RTG_b
		dc.b	0

    ; Moved here to be included in the persisted preferences
Prefs_CustomOptionsBuffer_vb:
Prefs_OriginalMouse_b:		dc.b	0
Prefs_AlwaysRun_b:			dc.b	0

                align 4
_Prefs_PersistedEnd::
PrefsfileEnd:

templeftkey:	dc.b	0
temprightkey:	dc.b	0
tempslkey:		dc.b	0
tempsrkey:		dc.b	0

				even

GETSTATS:
; CHANGE PASSWORD INTO RAW DATA

				rts


SETPLAYERS:
				; 0xABADCAFE - Set level file names. TODO - this should probably be moved to a helper
				move.w	Game_LevelNumber_w,d0
				add.b	#'a',d0
				move.b	d0,Lvl_BinFilenameX_vb
				move.b	d0,Lvl_GfxFilenameX_vb
				move.b	d0,Lvl_ClipsFilenameX_vb
				move.b	d0,Lvl_MapFilenameX_vb
				move.b	d0,Lvl_FlyMapFilenameX_vb

				; Optional files - floor tile override and level properties
				move.b	d0,Lvl_FloorFilenameX_vb
				move.b	d0,Lvl_WallFilenameX_vb
				move.b	d0,Lvl_ModPropsFilenameX_vb

				cmp.b	#PLR_SLAVE,Plr_MultiplayerType_b
				beq		Plr_InitSlave
				cmp.b	#PLR_MASTER,Plr_MultiplayerType_b
				beq		Plr_InitMaster
				st		AI_NoEnemies_b
onepla:
				rts

Plr_InitMaster:
				clr.b	AI_NoEnemies_b
				move.w	Game_LevelNumber_w,d0
				jsr		SENDFIRST

				move.w	Rand1,d0
				jsr		SENDFIRST

				bsr		TWOPLAYER
				rts

Plr_InitSlave:
				clr.b	AI_NoEnemies_b
				jsr		RECFIRST
				move.w	d0,Game_LevelNumber_w
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

game_ReadMainMenu:
				move.b	#PLR_SINGLE,Plr_MultiplayerType_b
				move.w	Game_MaxLevelNumber_w,d0
				move.l	#mnu_CURRENTLEVELLINE,a1
				muls	#40,d0
				move.l	GLF_DatabasePtr_l,a0
				add.l	#GLFT_LevelNames_l,a0
				add.l	d0,a0
				bsr		game_MenuSetLevelName

; Stay here until 'play game' is selected.

				lea		mnu_MYMAINMENU,a0
				bsr		game_OpenMenu

.rdlop:
				lea		mnu_MYMAINMENU,a0
				bsr		game_CheckMenu

***************************************************************
				tst.w	d0
				beq		playgame
***************************************************************
				cmp.w	#1,d0
				bne		.noopt

				bra		game_MasterMenu

.noopt:
***************************************************************
				cmp.w	#2,d0
				bne.s	.nonextlev

				bsr	levelMenu;cycleLevel

				lea		mnu_MYMAINMENU,a0
				bsr		game_OpenMenu

				bsr		game_WaitForMenuKey
				bra		game_ReadMainMenu

.nonextlev:
***************************************************************
				cmp.w	#3,d0
				bne		.nocontrol

				bsr		CHANGECONTROLS

				lea		mnu_MYMAINMENU,a0
				bsr		game_OpenMenu

				bsr		game_WaitForMenuKey
				bra		.rdlop

.nocontrol:
***************************************************************
				cmp.w	#4,d0
				bne		.nocred

				;jsr		mnu_viewcredz
				lea		mnu_MYMAINMENU,a0
				bsr		game_OpenMenu

				bra		.rdlop

.nocred:
***************************************************************
				cmp.w	#5,d0
				bne		.noload

				jsr		game_LoadPosition

				lea		mnu_MYMAINMENU,a0
				bsr		game_OpenMenu

				bsr		game_WaitForMenuKey
				bra		.rdlop

.noload:
***************************************************************
				cmp.w	#6,d0
				bne		.nosave
				bsr		game_WaitForMenuKey

				jsr		game_SavePosition

				lea		mnu_MYMAINMENU,a0
				bsr		game_OpenMenu

				bsr		game_WaitForMenuKey
				bra		.rdlop
.nosave:
***************************************************************
				cmp.w	#7,d0
				bne		playgame
				bsr		game_WaitForMenuKey

				bsr		customOptions

				lea		mnu_MYMAINMENU,a0
				bsr		game_OpenMenu

				bsr		game_WaitForMenuKey
				bra		.rdlop
***************************************************************

;fixme: there are better ways to do this, but it works.AL
levelMenu:
				lea		mnu_MYLEVELMENU,a0
				bsr		game_OpenMenu

				lea		mnu_MYLEVELMENU,a0
				bsr		game_CheckMenu

				cmp.w	#8,d0
				beq		levelMenu2
				SAVEREGS
				;bsr	DEFAULTGAME
				not.b	LOADEXT
				bsr		DEFGAME
				GETREGS
				move	d0,Game_MaxLevelNumber_w

				rts

levelMenu2:
				lea		mnu_MYLEVELMENU2,a0
				bsr		game_OpenMenu

				lea		mnu_MYLEVELMENU2,a0
				bsr		game_CheckMenu

				cmp.w	#8,d0
				beq	.levelSelectDone
				SAVEREGS
				;bsr	DEFAULTGAME
				not.b	LOADEXT
				add	#8,d0
				bsr	DEFGAME
				GETREGS
				move	d0,Game_MaxLevelNumber_w
				add	#8,Game_MaxLevelNumber_w

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
				move.w	(a0)+,Game_MaxLevelNumber_w

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

customOptions:
;fixme: there are better ways to do this, but it works (of sorts).AL
.redraw:
; copy current setting over to menu
				move.l	#Prefs_CustomOptionsBuffer_vb,a0
				move.l	#optionLines+17,a1
				moveq	#1,d1
.copyOpts:
				move.b	(a0)+,d0

				bne.s   .enabled
				move.b  #'N',d0
				bra.s   .copy
.enabled:
                move.b  #'Y',d0

				;add.b	#132,d0		;start of the keyboard layout
				;add.b	#24,d0		;cos i and o look like 1 and 0 in the menu font

.copy:
				move.b	d0,(a1)
				add.l	#21,a1		;end of the line/start of next i guess
				dbra	d1,.copyOpts

				lea		mnu_MYCUSTOMOPTSMENU,a0
				bsr		game_OpenMenu
.rdloop:
				lea		mnu_MYCUSTOMOPTSMENU,a0
				bsr		game_CheckMenu

				cmp.w	#8,d0
				beq	.customOptionsDone

				cmp.w	#0,d0
				bne.s	.co2
				not.b	Prefs_OriginalMouse_b
				bra	.w8
.co2:
				cmp.w	#1,d0
				bne.s	.co3
				not.b	Prefs_AlwaysRun_b
				bra	.w8
.co3:
				cmp.w	#2,d0
				bne.s	.co4
				bra	.w8
.co4:
				cmp.w	#3,d0
				bne.s	.co5
				bra	.w8
.co5:
				cmp.w	#4,d0
				bne.s	.co6
				;opt5
				bra	.w8
.co6:
				cmp.w	#5,d0
				bne.s	.co7
				;opt6
				bra	.w8
.co7:
				cmp.w	#6,d0
				bne.s	.co8
				;opt7
				bra	.w8
.co8:
				cmp.w	#7,d0
				bne.s	.w8
				;opt8
.w8:
				lea		mnu_MYCUSTOMOPTSMENU,a0
				jsr		mnu_redraw
				bra		.redraw

.customOptionsDone:
				rts
***************************************************************
playgame:
				move.w	Game_MaxLevelNumber_w,Game_LevelNumber_w
				rts

Game_ShouldQuit_b:		dc.w	0

game_LevelSelected_w:
				dc.w	0

game_MasterMenu:
				move.b	#PLR_MASTER,Plr_MultiplayerType_b
				move.w	#0,game_LevelSelected_w
				move.w	#0,d0
				move.l	#mnu_CURRENTLEVELLINEM,a1
				muls	#40,d0
				move.l	GLF_DatabasePtr_l,a0
				add.l	#GLFT_LevelNames_l,a0
				add.l	d0,a0
				bsr		game_MenuSetLevelName

; Stay here until 'play game' is selected.

				lea		mnu_MYMASTERMENU,a0
				bsr		game_OpenMenu

.rdlop:
				lea		mnu_MYMASTERMENU,a0
				bsr		game_CheckMenu

				cmp.w	#1,d0
				bne.s	.nonextlev

				move.w	game_LevelSelected_w,d0
				add.w	#1,d0
				cmp.w	Game_MaxLevelNumber_w,d0
				blt		.nowrap
				moveq	#0,d0
.nowrap:
; and.w #$f,d0
				move.w	d0,game_LevelSelected_w
				move.l	#mnu_CURRENTLEVELLINEM,a1
				muls	#40,d0
				move.l	GLF_DatabasePtr_l,a0
				add.l	#GLFT_LevelNames_l,a0
				add.l	d0,a0
				bsr		game_MenuSetLevelName

				lea		mnu_MYMASTERMENU,a0
				jsr		mnu_redraw

				bra		.rdlop

.nonextlev:

				cmp.w	#2,d0
				beq		.playgame

				cmp.w	#0,d0
				bne		.noopt

				bra		game_SlaveMenu

.noopt:
				cmp.w	#3,d0
				bne		.nocontrol

				bsr		CHANGECONTROLS

				lea		mnu_MYMASTERMENU,a0
				bsr		game_OpenMenu

				bra		.rdlop

.nocontrol:

.playgame:

				move.w	game_LevelSelected_w,Game_LevelNumber_w
				rts

game_SlaveMenu:

				move.b	#PLR_SLAVE,Plr_MultiplayerType_b

; Stay here until 'play game' is selected.

				lea		mnu_MYSLAVEMENU,a0
				bsr		game_OpenMenu

.rdlop:
				lea		mnu_MYSLAVEMENU,a0
				bsr		game_CheckMenu
				tst.w	d0
				blt.s	.rdlop
				bsr		game_WaitForMenuKey

				cmp.w	#1,d0
				beq		.playgame

				cmp.w	#0,d0
				bne		.noopt

				bra		game_ReadMainMenu

.noopt:

				cmp.w	#2,d0
				bne		.nocontrol

				bsr		CHANGECONTROLS

				lea		mnu_MYSLAVEMENU,a0
				bsr		game_OpenMenu


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
				move.w	#NUM_BULLET_DEFS-1,d1
.putinvals:
				jsr		GetRand
				and.w	#63,d0
				add.w	#5,d0
				move.w	d0,(a0)+
				move.w	d0,(a1)+
				dbra	d1,.putinvals

				rts

				; this entire bit seems unreachable?
				; ASM build only
				move.w	#127,draw_DisplayEnergyCount_w
				move.w	#0,draw_DisplayAmmoCount_w

				IFND BUILD_WITH_C
				jsr		Draw_BorderEnergyBar
				jsr		Draw_BorderAmmoBar
				ENDIF

				move.b	#0,Plr1_GunSelected_b
				move.b	#0,Plr2_GunSelected_b
				rts

newdum:
				rts

DEFAULTGAME:
				move.w	#0,Game_MaxLevelNumber_w

				move.l	#Plr_Health_w,a0
				move.l	#Plr_Shield_w,a1

				REPT	11
				clr.l	(a0)+
				ENDR

				REPT	6
				clr.l	(a1)+
				ENDR

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
				bsr		game_OpenMenu

.rdlop:
				lea		mnu_MYCONTROLSONE,a0
				bsr		game_CheckMenu

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
				bsr		game_OpenMenu

.rdlop:
				lea		mnu_MYCONTROLSTWO,a0
				bsr		game_CheckMenu

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

**************************************************


Game_MaxLevelNumber_w:		dc.w	0


game_WaitForMenuKey:
				movem.l	d0/d1/d2/d3,-(a7)

				move.l	#KeyMap_vb,a5
.wait_loop:
				; Should this yield a bit?
				;moveq	#1,d1
				;CALLDOS Delay
				btst	#7,$bfe001 ; cia
				beq.s	.wait_loop

				IFEQ	CD32VER
				tst.b	RAWKEY_SPACEBAR(a5)
				bne.s	.wait_loop
				tst.b	RAWKEY_ENTER(a5)
				bne.s	.wait_loop
				tst.b	RAWKEY_UP(a5)
				bne.s	.wait_loop
				tst.b	RAWKEY_DOWN(a5)
				bne.s	.wait_loop
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
				bne.s	.wait_loop
				tst.b	d3
				bne.s	.wait_loop

				movem.l	(a7)+,d0/d1/d2/d3
				rts

game_MenuSetLevelName:
				moveq	#19,d0
.loop:
				move.b	(a0)+,(a1)+
				dbra	d0,.loop
				rts

game_OpenMenu:
.redraw:
				move.l	a0,-(a7)
				jsr		mnu_openmenu			; Open new menu

				move.l	(a7)+,a0
				rts

game_CheckMenu:
				move.b	#0,lastpressed

.loop:
				move.l	a0,-(a7)
				jsr		mnu_update

				jsr		mnu_waitmenu			; Wait for option

				move.l	(a7)+,a0
				moveq.l	#0,d2
				move.w	mnu_row,d2
				divu	14(a0),d2
				swap.w	d2
				move.w	d2,mnu_currentsel
				move.w	d2,d0					; option number
				rts

game_SavedGameSlotPtr_l:	dc.l	0
game_SavedGameSlotSize_l:	dc.l	0

game_LoadPosition:
				move.l	#Game_SavedGamesName_vb,a0
				move.l	#game_SavedGameSlotPtr_l,d0
				move.l	#game_SavedGameSlotSize_l,d1
				jsr		IO_InitQueue
				jsr		IO_QueueFile
				jsr		IO_FlushQueue

				move.l	game_SavedGameSlotPtr_l,a2			; address of first saved game.
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
				bsr		game_MenuSetLevelName

				add.l	#21,a4
				add.w	#2+(22*2)+(12*2),a3

				dbra	d7,.findlevs

				lea		mnu_MYLOADMENU,a0
				bsr		game_OpenMenu

.rdlop:
				lea		mnu_MYLOADMENU,a0
				bsr		game_CheckMenu

				cmp.w	#6,d0
				beq.s	.noload

				move.l	game_SavedGameSlotPtr_l,a0
				muls	#2+(22*2)+(12*2),d0
				add.l	d0,a0

; 0xABADCAFE - This is where the inventory is loaded from the saved game slot
.load_player_inventory:
				move.l	#Plr_Health_w,a1
				move.w	(a0)+,Game_MaxLevelNumber_w

				REPT	11
				move.l	(a0)+,(a1)+
				ENDR
				REPT	6
				move.l	(a0)+,(a1)+
				ENDR

				move.l  #Plr_Health_w,a0
				CALLC   Game_ApplyInventoryLimits

				move.w	Game_MaxLevelNumber_w,d0
				move.l	#mnu_CURRENTLEVELLINE,a1
				muls	#40,d0
				move.l	GLF_DatabasePtr_l,a0
				add.l	#GLFT_LevelNames_l,a0
				add.l	d0,a0
				bsr		game_MenuSetLevelName

.noload:
				move.l	game_SavedGameSlotPtr_l,a1
				CALLEXEC FreeVec

				rts

game_SavePosition:
				move.l	#Game_SavedGamesName_vb,a0
				move.l	#game_SavedGameSlotPtr_l,d0
				move.l	#game_SavedGameSlotSize_l,d1
				jsr		IO_InitQueue
				jsr		IO_QueueFile
				jsr		IO_FlushQueue

				move.l	game_SavedGameSlotPtr_l,a2			; address of first saved game.

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
				bsr		game_MenuSetLevelName
				add.l	#21,a4
				add.w	#2+(22*2)+(12*2),a3

				dbra	d7,.findlevs

				lea		mnu_MYSAVEMENU,a0
				bsr		game_OpenMenu

.rdlop:
				lea		mnu_MYSAVEMENU,a0
				bsr		game_CheckMenu

				cmp.w	#5,d0
				beq		.nosave

				move.l	d0,-(a7)
				move.l	(a7)+,d0
				addq	#1,d0
				move.l	game_SavedGameSlotPtr_l,a0
				muls	#2+(22*2)+(12*2),d0
				add.l	d0,a0
				move.l	#Plr_Health_w,a1
				move.w	Game_MaxLevelNumber_w,(a0)+

				REPT	11
				move.l	(a1)+,(a0)+
				ENDR
				REPT	6
				move.l	(a1)+,(a0)+
				ENDR

				move.l	#Game_SavedGamesName_vb,d1
				move.l	#MODE_NEWFILE,d2
				CALLDOS	Open
				move.l	d0,IO_DOSFileHandle_l

				move.l	game_SavedGameSlotPtr_l,d2
				move.l	IO_DOSFileHandle_l,d1
				move.l	game_SavedGameSlotSize_l,d3
				CALLDOS	Write

				move.l	IO_DOSFileHandle_l,d1
				CALLDOS	Close

;				move.l	#200,d1
;				CALLDOS	Delay

.nosave:

				move.l	game_SavedGameSlotPtr_l,a1
				CALLEXEC FreeVec

				rts

_Game_LevelNumber::
Game_LevelNumber_w:		dc.w	0


FADEAMOUNT:		dc.w	0
FADEVAL:		dc.w	0

Game_StoryFile_vb:
				dc.b	'ab3:includes/TEXT_FILE'

				even

Lvl_IntroTextPtr_l:
				dc.l	0

				include	"menu/menunb.s"
