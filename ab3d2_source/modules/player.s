
; *****************************************************************************
; *
; * modules/player.s
; *
; * Common code for player control.
; *
; *****************************************************************************

; Notes: The entity references for player 1, player 2 and the weapon view model
;        are stored contiguously:
;
; Plr1_Data->ObjectPtr_l + EntT_SizeOf_l == Plr2_Data->ObjectPtr_l
; Plr2_Data->ObjectPtr_l + EntT_SizeOf_l == player weapon entity
;

;******************************************************************************
;*
;* Initialise player positions
;*
;******************************************************************************
Plr_Initialise:
				move.l	Lvl_DataPtr_l,a1
				add.l	#LVLT_MESSAGE_LENGTH*LVLT_MESSAGE_COUNT,a1
				move.w	LvlT_Plr1_Start_ZoneID_w(a1),d0
				move.l	Lvl_ZoneAddsPtr_l,a0
				move.l	(a0,d0.w*4),d0
				add.l	Lvl_DataPtr_l,d0
				move.l	d0,Plr1_ZonePtr_l
				move.l	Plr1_ZonePtr_l,a0
				move.l	ZoneT_Floor_l(a0),d0
				sub.l	#PLR_STAND_HEIGHT,d0
				move.l	d0,Plr1_SnapYOff_l
				move.l	d0,Plr1_YOff_l
				move.l	d0,Plr1_SnapTYOff_l
				move.l	Plr1_ZonePtr_l,plr1_OldRoomPtr_l
				move.l	Lvl_DataPtr_l,a1
				add.l	#LVLT_MESSAGE_LENGTH*LVLT_MESSAGE_COUNT,a1
				move.w	LvlT_Plr2_Start_ZoneID_w(a1),d0
				move.l	Lvl_ZoneAddsPtr_l,a0
				move.l	(a0,d0.w*4),d0
				add.l	Lvl_DataPtr_l,d0
				move.l	d0,Plr2_ZonePtr_l
				move.l	Plr2_ZonePtr_l,a0
				move.l	ZoneT_Floor_l(a0),d0
				sub.l	#PLR_STAND_HEIGHT,d0
				move.l	d0,Plr2_SnapYOff_l
				move.l	d0,Plr2_YOff_l
				move.l	d0,Plr2_SnapTYOff_l
				move.l	d0,Plr2_YOff_l
				move.l	Plr2_ZonePtr_l,plr2_OldRoomPtr_l
				move.w	LvlT_Plr1_StartX_w(a1),Plr1_SnapXOff_l
				move.w	LvlT_Plr1_StartZ_w(a1),Plr1_SnapZOff_l
				move.w	LvlT_Plr1_StartX_w(a1),Plr1_XOff_l
				move.w	LvlT_Plr1_StartZ_w(a1),Plr1_ZOff_l
				move.w	LvlT_Plr2_StartX_w(a1),Plr2_SnapXOff_l
				move.w	LvlT_Plr2_StartZ_w(a1),Plr2_SnapZOff_l
				move.w	LvlT_Plr2_StartX_w(a1),Plr2_XOff_l
				move.w	LvlT_Plr2_StartZ_w(a1),Plr2_ZOff_l

				move.l	#%100011,plr1_DefaultEnemyFlags_l
				move.l	#%010011,plr2_DefaultEnemyFlags_l
				rts

;******************************************************************************
;*
;* Common mouse control
;*
;* Pointer to player data in a0
;*
;******************************************************************************
plr_MouseControl:
				move.l	a0,-(a7)

				IFND BUILD_WITH_C
				bsr		Sys_ReadMouse
				ELSE
				CALLC	Sys_ReadMouse
				ENDIF

				move.l	(a7)+,a0
				move.l	#SinCosTable_vw,a1
				move.w	PlrT_SnapAngSpd_w(a0),d1
				move.w	angpos,d0
				AMOD_A	d0
				move.w	d0,PlrT_SnapAngPos_w(a0)
				move.w	(a1,d0.w),PlrT_SnapSinVal_w(a0)
				adda.w	#COSINE_OFS,a1
				move.w	(a1,d0.w),PlrT_SnapCosVal_w(a0)
				move.l	PlrT_SnapXSpdVal_l(a0),d6
				move.l	PlrT_SnapZSpdVal_l(a0),d7
				neg.l	d6
				ble.s	.nobug1

				asr.l	#1,d6
				add.l	#1,d6
				bra.s	.bug1

.nobug1:
				asr.l	#1,d6

.bug1:
				neg.l	d7
				ble.s	.nobug2
				asr.l	#1,d7
				add.l	#1,d7
				bra.s	.bug2

.nobug2:
				asr.l	#1,d7

.bug2:
				move.w	Sys_MouseY,d3
				tst.b	PlrT_InvMouse_b(a0)
				beq.s	.no_invert
				neg.w	d3
.no_invert:
				sub.w	Sys_OldMouseY,d3
				add.w	d3,Sys_OldMouseY
				move.w	STOPOFFSET,d0
				move.w	d3,d2
				asl.w	#7,d2
				add.w	d2,PlrT_AimSpeed_l(a0)
				add.w	d3,d0
				cmp.w	#-80,d0
				bgt.s	.skip_look_up

				move.w	#-512*20,PlrT_AimSpeed_l(a0)
				move.w	#-80,d0

.skip_look_up:
				cmp.w	#80,d0
				blt.s	.skip_look_down
				move.w	#512*20,PlrT_AimSpeed_l(a0)
				move.w	#80,d0

.skip_look_down:
				move.w	d0,STOPOFFSET
				neg.w	d0
				add.w	TOTHEMIDDLE,d0
				move.w	d0,SMIDDLEY
				muls	#SCREEN_WIDTH,d0
				move.l	d0,SBIGMIDDLEY
				move.l	#KeyMap_vb,a5
				moveq	#0,d7

				; The right mouse button triggers the next_weapon key
				move.b	next_weapon_key,d7
				tst.b	Prefs_OriginalMouse_b
				beq.s	.notQuake
				move.b	forward_key,d7
.notQuake
				btst	#2,$dff000+potinp		; right button
				seq		(a5,d7.w)

				; The left mouse button triggers the fire key
				move.b	fire_key,d7
				btst	#CIAB_GAMEPORT0,$bfe001+ciapra ; left button
				seq		(a5,d7.w)

				rts

;******************************************************************************
;*
;* Common keyboard control
;*
;* Pointer to player data in a0
;*
;******************************************************************************
plr_KeyboardControl:
				move.l	#KeyMap_vb,a5
				moveq	#0,d7

				; Check for quit
				tst.b	QUIT_KEY(a5)
				beq.s	.no_quit
				st		Game_ShouldQuit_b
				st		Game_MasterQuit_b
.no_quit:

				move.b	next_weapon_key,d7
				tst.b	(a5,d7.w)
				beq.s	.no_next_weapon_pre

				tst.b	plr_PrevNextWeaponKeyState_b
				bne.s	.no_next_weapon

				st		plr_PrevNextWeaponKeyState_b
				moveq	#0,d0
				move.b	PlrT_GunSelected_b(a0),d0
				lea		PlrT_Weapons_vb(a0),a1

.find_next_weapon:
				addq	#1,d0
				cmp.w	#9,d0
				ble.s	.weapon_found

				moveq	#0,d0

.weapon_found:
				tst.w	(a1,d0.w*2)
				beq.s	.find_next_weapon

				move.b	d0,PlrT_GunSelected_b(a0)

				bsr		plr_ShowGunName

				bra.s	.no_next_weapon

.no_next_weapon_pre:
				clr.b	plr_PrevNextWeaponKeyState_b

.no_next_weapon:
				move.b	operate_key,d7
				move.b	(a5,d7.w),d1
				beq.s	.nottapped

				tst.b	plr_PrevUseKeyState_b
				bne.s	.nottapped

				st		PlrT_Used_b(a0)

.nottapped:
				move.b	d1,plr_PrevUseKeyState_b
				move.b	duck_key,d7
				tst.b	(a5,d7.w)
				beq.s	.notduck

				clr.b	(a5,d7.w)
				move.l	#PLR_STAND_HEIGHT,PlrT_SnapTargHeight_l(a0)
				not.b	PlrT_Ducked_b(a0)
				beq.s	.notduck

				move.l	#PLR_CROUCH_HEIGHT,PlrT_SnapTargHeight_l(a0)

.notduck:
				move.l	PlrT_ZonePtr_l(a0),a4
				move.l	ZoneT_Floor_l(a4),d0
				sub.l	ZoneT_Roof_l(a4),d0
				tst.b	PlrT_StoodInTop_b(a0)
				beq.s	.use_bottom

				move.l	ZoneT_UpperFloor_l(a4),d0
				sub.l	ZoneT_UpperRoof_l(a4),d0

.use_bottom:
				clr.b	PlrT_Squished_b(a0)
				move.l	#PLR_STAND_HEIGHT,PlrT_SnapSquishedHeight_l(a0)
				cmp.l	#PLR_STAND_HEIGHT+3*1024,d0
				bgt.s	.oktostand

				st		PlrT_Squished_b(a0)
				move.l	#PLR_CROUCH_HEIGHT,PlrT_SnapSquishedHeight_l(a0)

.oktostand:
				move.l	PlrT_SnapTargHeight_l(a0),d1
				move.l	PlrT_SnapSquishedHeight_l(a0),d0
				cmp.l	d0,d1
				blt.s	.notsqu
				move.l	d0,d1

.notsqu:
				move.l	PlrT_SnapHeight_l(a0),d0
				cmp.l	d1,d0
				beq.s	.noupordown
				bgt.s	.crouch
				add.l	#1024,d0
				bra		.noupordown

.crouch:
				sub.l	#1024,d0

.noupordown:
				move.l	d0,PlrT_SnapHeight_l(a0)
				tst.b	RAWKEY_K(a5)
				beq.s	.notselkey

				clr.b	RAWKEY_K(a5)

				st		PlrT_InvMouse_b(a0) ; hack for when mouse is re-selected

				move.l	a0,-(sp)
				move.l	#Game_InputKeyboard_vb,a0
				move.w	#OPTS_MESSAGE_LENGTH|MSG_TAG_OPTIONS,d0
				CALLC	Msg_PushLine

				move.l	(sp)+,a0
				st		PlrT_Keys_b(a0)
				clr.b	PlrT_Path_b(a0)
				clr.b	PlrT_Mouse_b(a0)
				clr.b	PlrT_Joystick_b(a0)

.notselkey:
				tst.b	RAWKEY_J(a5)
				beq.s	.notseljoy

				st		PlrT_InvMouse_b(a0) ; hack for when mouse is re-selected

				clr.b	RAWKEY_J(a5)
				clr.b	PlrT_Keys_b(a0)
				clr.b	PlrT_Path_b(a0)
				clr.b	PlrT_Mouse_b(a0)
				st		PlrT_Joystick_b(a0)

				move.l	a0,-(sp)
				move.l	#Game_InputJoystick_vb,a0
				move.w	#OPTS_MESSAGE_LENGTH|MSG_TAG_OPTIONS,d0
				CALLC	Msg_PushLine

				move.l	(sp)+,a0

.notseljoy:
				tst.b	RAWKEY_M(a5)
				beq.s	.notselmouse

				clr.b	RAWKEY_M(a5)
				clr.b	PlrT_Keys_b(a0)
				clr.b	PlrT_Path_b(a0)
				st		PlrT_Mouse_b(a0)
				clr.b	PlrT_Joystick_b(a0)
				eor.b	#-1,PlrT_InvMouse_b(a0)
				beq.s	.mouse_normal

				move.l	a0,-(sp)
				move.l	#Game_InputMouseInv_vb,a0
				bra.s	.mouse_msg

.mouse_normal:
				move.l	a0,-(sp)
				move.l	#Game_InputMouse_vb,a0
.mouse_msg:
				move.w	#OPTS_MESSAGE_LENGTH|MSG_TAG_OPTIONS,d0
				CALLC	Msg_PushLine
				move.l	(sp)+,a0

.notselmouse:
				lea		1(a5),a4
				lea		PlrT_Weapons_vb(a0),a2
				move.l	PlrT_ObjectPtr_l(a0),a3
				move.w	#9,d1
				move.w	#0,d2

.pickweap:
				move.w	(a2)+,d0
				and.b	(a4)+,d0
				beq.s	.notgotweap

				move.b	d2,PlrT_GunSelected_b(a0)

				; d2=number of gun.

				cmp.l	Plr1_Data,a0
				bne.s	.use_player_2_timer

.use_player_1_timer:
				; for player1, the viewport weapon entity is two along
				move.w	#0,ENT_NEXT_2+EntT_Timer1_w(a3)
				bsr		plr_ShowGunName

				bra.s	.go

.use_player_2_timer:
				; for player2, the viewport weapon entity is one along
				move.w	#0,ENT_NEXT+EntT_Timer1_w(a3)
				bsr		plr_ShowGunName

				bra.s	.go

.notgotweap:
				addq	#1,d2
				dbra	d1,.pickweap

.go:
				tst.b	RAWKEY_F10(a5)
				beq.s	.notswapscr

				tst.b	lastscr
				bne.s	.notswapscr2

				st		lastscr
				not.b	Vid_FullScreenTemp_b

				bra.s	.notswapscr2

.notswapscr:
				clr.b	lastscr

.notswapscr2:
				tst.b	RAWKEY_F7(a5)
				beq.s	.noframelimit

				clr.b	RAWKEY_F7(a5)
				cmp.l	#5,Vid_FPSLimit_l
				beq.s	.resetfpslimit

				addq.l	#1,Vid_FPSLimit_l
				bra.s	.noframelimit

.resetfpslimit:
				clr.l	Vid_FPSLimit_l

.noframelimit:

				IFD DEV

.toggle_skip_sky_for_zone:
				; X toggles the sky background visibility for this zone
				tst.b			RAWKEY_X(a5)
				beq.s			.clear_zone_data

				clr.b			RAWKEY_X(a5)
				lea				Zone_BackdropDisable_vb,a1
				move.w			PlrT_Zone_w(a0),d0
				not.b			(a1,d0.w)

.clear_zone_data:
				tst.b			RAWKEY_Z(a5)
				beq.s			.dev_toggles

				clr.b			RAWKEY_Z(a5)

				move.w			#16-1,d0
				lea				Zone_BackdropDisable_vb,a1

.clear_loop:
				clr.l			(a1)+
				clr.l			(a1)+
				clr.l			(a1)+
				clr.l			(a1)+
				dbra			d0,.clear_loop

.dev_toggles:
				; Developer toggles
				DEV_CHECK_KEY	RAWKEY_E,SIMPLE_WALLS
				DEV_CHECK_KEY	RAWKEY_R,SHADED_WALLS
				DEV_CHECK_KEY	RAWKEY_T,BITMAPS
				DEV_CHECK_KEY	RAWKEY_Y,GLARE_BITMAPS
				DEV_CHECK_KEY	RAWKEY_U,ADDITIVE_BITMAPS
				DEV_CHECK_KEY	RAWKEY_I,LIGHTSOURCED_BITMAPS
				DEV_CHECK_KEY	RAWKEY_O,POLYGON_MODELS
				DEV_CHECK_KEY	RAWKEY_G,FLATS
				DEV_CHECK_KEY	RAWKEY_Q,FASTBUFFER_CLEAR
				DEV_CHECK_KEY	RAWKEY_N,AI_ATTACK
				DEV_CHECK_KEY	RAWKEY_B,LIGHTING
				DEV_CHECK_KEY	RAWKEY_V,SKYFILL
				DEV_CHECK_KEY	RAWKEY_H,OVERLAY

				; change the default floor gouraud state based on the lighting toggle
				; todo - fix floor rendering when goraud is disabled, it's seriously glitched
				;DEV_SEQ	LIGHTING,draw_GouraudFlatsSelected_b

				ENDC

				move.l	#SinCosTable_vw,a1
				move.l	#KeyMap_vb,a5
				move.w	STOPOFFSET,d0
				moveq	#0,d7
				move.b	look_up_key,d7
				tst.b	(a5,d7.w)
				beq.s	.skip_look_up

				sub.w	#512,PlrT_AimSpeed_l(a0)
				sub.w	#4,d0
				cmp.w	#-80,d0
				bgt.s	.skip_look_up

				move.w	#-512*20,PlrT_AimSpeed_l(a0)
				move.w	#-80,d0

.skip_look_up:
				moveq	#0,d7
				move.b	look_down_key,d7
				tst.b	(a5,d7.w)
				beq.s	.skip_look_down

				add.w	#512,PlrT_AimSpeed_l(a0)
				add.w	#4,d0
				cmp.w	#80,d0
				blt.s	.skip_look_down

				move.w	#512*20,PlrT_AimSpeed_l(a0)
				move.w	#80,d0

.skip_look_down:
				move.b	centre_view_key,d7
				tst.b	(a5,d7.w)
				beq.s	.skip_centre_look

				tst.b	Plr_OldCentre_b
				bne.s	.skip_centre_look_2

				st		Plr_OldCentre_b
				move.w	#0,d0
				move.w	#0,PlrT_AimSpeed_l(a0)

				bra.s	.skip_centre_look_2

.skip_centre_look:
				clr.b	Plr_OldCentre_b

.skip_centre_look_2:
				move.w	d0,STOPOFFSET
				neg.w	d0
				add.w	TOTHEMIDDLE,d0
				move.w	d0,SMIDDLEY
				muls.w	#SCREEN_WIDTH,d0
				move.l	d0,SBIGMIDDLEY
				move.w	PlrT_SnapAngPos_w(a0),d0
				move.w	PlrT_SnapAngSpd_w(a0),d3
				tst.b	Prefs_AlwaysRun_b
				bne.s	.always_run

				move.w	#35,d1
				move.w	#2,d2
				move.w	#10,Plr_TurnSpeed_w
				moveq	#0,d7
				move.b	run_key,d7
				tst.b	(a5,d7.w)
				beq.s	.nofaster

				move.w	#60,d1
				move.w	#3,d2
				move.w	#14,Plr_TurnSpeed_w
.nofaster:
				bra	.faster

.always_run:
				move.w	#60,d1
				move.w	#3,d2
				move.w	#14,Plr_TurnSpeed_w

				moveq	#0,d7
				move.b	run_key,d7
				tst.b	(a5,d7.w)

				beq.s	.faster
				move.w	#35,d1
				move.w	#2,d2
				move.w	#10,Plr_TurnSpeed_w
.faster:
***************************************************************
				tst.b	PlrT_Squished_b(a0)
				bne.s	.crouch_2

				tst.b	PlrT_Ducked_b(a0)
				beq.s	.skip_crouch
.crouch_2:
				asr.w	#1,d2

.skip_crouch:
				moveq	#0,d4
				tst.b	Plr_Decelerate_b
				beq.s	.nofric

				move.w	d3,d5
				add.w	d5,d5
				add.w	d5,d3
				asr.w	#2,d3
				bge.s	.nneg

				addq	#1,d3

.nneg:
.nofric:
				move.b	turn_left_key,templeftkey
				move.b	turn_right_key,temprightkey
				move.b	sidestep_left_key,tempslkey
				move.b	sidestep_right_key,tempsrkey
				move.b	force_sidestep_key,d7
				tst.b	(a5,d7.w)
				beq		.skip_force_sidestep

				move.b	templeftkey,tempslkey
				move.b	temprightkey,tempsrkey
				move.b	#255,templeftkey
				move.b	#255,temprightkey

.skip_force_sidestep:
				tst.b	Plr_Decelerate_b
				beq.s	.turn_not_possible

				move.b	templeftkey,d7
				tst.b	(a5,d7.w)
				beq.s	.skip_turn_left

				sub.w	Plr_TurnSpeed_w,d3

.skip_turn_left:
				move.l	#KeyMap_vb,a5
				move.b	temprightkey,d7
				tst.b	(a5,d7.w)
				beq.s	.skip_turn_right

				add.w	Plr_TurnSpeed_w,d3

.skip_turn_right:
				cmp.w	d1,d3
				ble.s	.right_speed_ok

				move.w	d1,d3

.right_speed_ok:
				neg.w	d1
				cmp.w	d1,d3
				bge.s	.left_speed_ok

				move.w	d1,d3

.left_speed_ok:
.turn_not_possible:
				add.w	d3,d0
				add.w	d3,d0
				move.w	d3,PlrT_SnapAngSpd_w(a0)
				move.b	tempslkey,d7
				tst.b	(a5,d7.w)
				beq.s	.skip_step_left

				add.w	d2,d4
				add.w	d2,d4
				asr.w	#1,d4

.skip_step_left:
				move.l	#KeyMap_vb,a5
				move.b	tempsrkey,d7
				tst.b	(a5,d7.w)
				beq.s	.skip_step_right

				add.w	d2,d4
				add.w	d2,d4
				asr.w	#1,d4
				neg.w	d4

.skip_step_right:
				AMOD_I	d0
				move.w	d0,PlrT_SnapAngPos_w(a0)
				move.w	(a1,d0.w),PlrT_SnapSinVal_w(a0)
				adda.w	#COSINE_OFS,a1
				move.w	(a1,d0.w),PlrT_SnapCosVal_w(a0)
				move.l	PlrT_SnapXSpdVal_l(a0),d6
				move.l	PlrT_SnapZSpdVal_l(a0),d7
				tst.b	Plr_Decelerate_b
				beq.s	.skip_friction

				neg.l	d6
				ble.s	.nobug1

				asr.l	#3,d6
				add.l	#1,d6
				bra.s	.bug1

.nobug1:
				asr.l	#3,d6

.bug1:
				neg.l	d7
				ble.s	.nobug2

				asr.l	#3,d7
				add.l	#1,d7
				bra.s	.bug2

.nobug2:
				asr.l	#3,d7

.bug2:
.skip_friction:
				moveq	#0,d3
				moveq	#0,d5
				move.b	forward_key,d5
				tst.b	(a5,d5.w)
				beq.s	.noforward

				neg.w	d2
				move.w	d2,d3

.noforward:
				move.b	backward_key,d5
				tst.b	(a5,d5.w)
				beq.s	.nobackward

				move.w	d2,d3

.nobackward:
				move.w	d3,d2
				asl.w	#6,d2
				move.w	d2,d1
; add.w d2,d1
; add.w d2,d1
				move.w	d1,Plr_AddToBobble_w
				move.w	PlrT_SnapSinVal_w(a0),d1
				muls.w	d3,d1
				move.w	PlrT_SnapCosVal_w(a0),d2
				muls.w	d3,d2
				sub.l	d1,d6
				sub.l	d2,d7
				move.w	PlrT_SnapSinVal_w(a0),d1
				muls.w	d4,d1
				move.w	PlrT_SnapCosVal_w(a0),d2
				muls.w	d4,d2
				sub.l	d2,d6
				add.l	d1,d7
				tst.b	Plr_Decelerate_b
				beq.s	.no_control_possible

				add.l	d6,PlrT_SnapXSpdVal_l(a0)
				add.l	d7,PlrT_SnapZSpdVal_l(a0)

.no_control_possible:
				move.l	PlrT_SnapXSpdVal_l(a0),d6
				move.l	PlrT_SnapZSpdVal_l(a0),d7
				add.l	d6,PlrT_SnapXOff_l(a0)
				add.l	d7,PlrT_SnapZOff_l(a0)
				move.b	fire_key,d5
				tst.b	PlrT_Fire_b(a0)
				beq.s	.firenotpressed

				; fire was pressed last time.
				tst.b	(a5,d5.w)
				beq.s	.firenownotpressed

				; fire is still pressed this time.
				st		PlrT_Fire_b(a0)
				bra		.done

.firenownotpressed:
				; fire has been released.
				clr.b	PlrT_Fire_b(a0)
				bra		.done

.firenotpressed:
				; fire was not pressed last frame...
				; if it has still not been pressed, go back above
				tst.b	(a5,d5.w)
				beq.s	.firenownotpressed

				; fire was not pressed last time, and was this time, so has
				; been clicked.
				st		PlrT_Clicked_b(a0)
				st		PlrT_Fire_b(a0)

.done:
				rts

;******************************************************************************
;*
;* Show gun name
;*
;* Pointer to player data in a0
;*
;******************************************************************************
plr_ShowGunName:
				moveq   #0,d2
				move.b  PlrT_GunSelected_b(a0),d0
;				cmp.b   PlrT_TmpGunSelected_b(a0),d0
;				beq     .done

				move.l  GLF_DatabasePtr_l,a4
				add.l   #GLFT_GunNames_l,a4
				muls    #GLFT_GUN_NAME_LENGTH,d0
				add.l   d0,a4
				exg     a0,a4
				move.w  #GLFT_GUN_NAME_LENGTH|MSG_TAG_OTHER,d0
				CALLC   Msg_PushLineDedupLast
				move.l  a4,a0

.done:
				rts

;******************************************************************************
;*
;* Falling down...
;*
;* Pointer to player data in a0
;*
;******************************************************************************
plr_Fall:
				move.l	PlrT_SnapTYOff_l(a0),d0
				move.l	PlrT_SnapYOff_l(a0),d1
				move.l	PlrT_SnapYVel_l(a0),d2
				cmp.l	d1,d0
				bgt		.above_ground
				beq.s	.on_ground

				st		Plr_Decelerate_b

				; we are under the ground.

				sub.l	d1,d0
				cmp.l	#-512,d0
				bge.s	.not_too_big

				move.l	#-512,d0

.not_too_big:
				add.l	d0,d1
				bra		.proceed

.on_ground:
				move.w	PlrT_FloorSpd_w(a0),d2
				ext.l	d2
				asl.l	#6,d2
				move.l	PlrT_ObjectPtr_l(a0),a4
				move.w	plr_FallDamage_w,d3
				sub.w	#100,d3 ; TODO - this should depend on the distance fallen.
				ble.s	.skip_damage

				add.b	d3,EntT_DamageTaken_b(a4)

.skip_damage:
				st		Plr_Decelerate_b
				move.w	#0,plr_FallDamage_w
				move.w	Plr_AddToBobble_w,d3
				move.w	d3,d4
				add.w	PlrT_Bobble_w(a0),d3
				AMOD_A	d3
				move.w	d3,PlrT_Bobble_w(a0)
				add.w	PlrT_WalkSFXTime_w(a0),d4
				move.w	d4,d3
				and.w	#4095,d4
				move.w	d4,PlrT_WalkSFXTime_w(a0)
				and.w	#-4096,d3
				beq.s	.skip_footstep_fx

				bsr		plr_DoFootstepFX

.skip_footstep_fx:
				move.l	#-1024,plr_JumpSpeed_l

				move.l	PlrT_ZonePtr_l(a0),a2
				move.l	ZoneT_Water_l(a2),d0
				cmp.l	d0,d1
				blt.s	.not_in_water

				move.l	#-512,plr_JumpSpeed_l

.not_in_water:
				tst.w	PlrT_Health_w(a0)
				ble.s	.no_thrust ; dead dudes don't jump

				move.l	#KeyMap_vb,a5
				moveq	#0,d7
				move.b	jump_key,d7
				tst.b	(a5,d7.w)
				beq.s	.no_thrust
				move.l	plr_JumpSpeed_l,d2

.no_thrust:
				tst.l	d2
				ble.s	.no_down

				moveq	#0,d2

.no_down:
				add.l	d2,d1
				bra		.proceed

.above_ground:
				clr.b	Plr_Decelerate_b
				tst.w	PlrT_Jetpack_w(a0)
				beq.s	.not_flying

				tst.w	PlrT_JetpackFuel_w(a0)
				beq.s	.not_flying

				; TODO - Apply the active jetpack fuel cap here
				; cap the fuel. We should make that mod configurable
				cmp.w	#250,PlrT_JetpackFuel_w(a0)
				ble.s	.have_jetpack_fuel

				move.w	#250,PlrT_JetpackFuel_w(a0)

.have_jetpack_fuel:
				st		Plr_Decelerate_b
				move.l	#-128,plr_JumpSpeed_l
				move.l	#KeyMap_vb,a5
				moveq	#0,d7
				move.b	jump_key,d7
				tst.b	(a5,d7.w)
				beq.s	.not_flying

				sub.w	#1,PlrT_JetpackFuel_w(a0)
				add.l	plr_JumpSpeed_l,d2
				move.w	#0,plr_FallDamage_w
				move.w	#40,d3
				add.w	PlrT_Bobble_w(a0),d3
				AMOD_A	d3
				move.w	d3,PlrT_Bobble_w(a0)

.not_flying:
				move.l	d0,d3
				sub.l	d1,d3
				cmp.l	#16*64,d3
				bgt.s	.nonearmove

				st		Plr_Decelerate_b

.nonearmove:
; need to fall down (possibly).
				add.l	d2,d1
				cmp.l	d1,d0
				bgt.s	.still_above

				move.w	plr_FallDamage_w,d3
				sub.w	#100,d3
				ble.s	.skip_damage_2

				move.l	PlrT_ObjectPtr_l(a0),a4
				add.b	d3,EntT_DamageTaken_b(a4)

.skip_damage_2:
				move.w	#0,plr_FallDamage_w
				move.w	PlrT_FloorSpd_w(a0),d2
				ext.l	d2
				asl.l	#6,d2
				bra		.proceed

.still_above:
				add.l	#64,d2
				add.w	#1,plr_FallDamage_w

				move.l	PlrT_ZonePtr_l(a0),a2
				move.l	ZoneT_Water_l(a2),d0
				cmp.l	d0,d1
				blt.s	.proceed

				cmp.l	plr_OldHeight_l,d0
				blt.s	.no_splash_fx

				movem.l	d0-d7/a0-a6,-(a7)
				move.w	#6,Aud_SampleNum_w ; todo define a constant for this
				move.w	#0,Aud_NoiseX_w
				move.w	#100,Aud_NoiseZ_w
				move.w	#80,Aud_NoiseVol_w
				move.w	#$fff8,IDNUM
				clr.b	notifplaying
				jsr		MakeSomeNoise

				movem.l	(a7)+,d0-d7/a0-a6

.no_splash_fx:
				st		Plr_Decelerate_b
				move.w	#0,plr_FallDamage_w
				cmp.l	#512,d2
				blt.s	.proceed

				move.l	#512,d2					; reached terminal velocity.

.proceed:
				move.l	PlrT_ZonePtr_l(a0),a2
				move.l	ZoneT_Roof_l(a2),d3
				tst.b	PlrT_StoodInTop_b(a0)
				beq.s	.ok_bottom

				move.l	ZoneT_UpperRoof_l(a2),d3

.ok_bottom:
				add.l	#10*256,d3
				cmp.l	d1,d3
				blt.s	.ok_ceiling

				move.l	d3,d1
				tst.l	d2
				bge.s	.ok_ceiling

				moveq	#0,d2

.ok_ceiling:
				move.l	d2,PlrT_SnapYVel_l(a0)
				move.l	d1,PlrT_SnapYOff_l(a0)
				rts

;******************************************************************************
;*
;* Do footstep sounds
;*
;* Pointer to player data in a0
;*
;******************************************************************************
plr_DoFootstepFX:
				movem.l	d0-d7/a0-a6,-(a7)
				move.l	PlrT_ZonePtr_l(a0),a1
				move.w	ZoneT_FloorNoise_w(a1),d0
				move.l	ZoneT_Water_l(a1),d1
				cmp.l	ZoneT_Floor_l(a1),d1
				bge.s	.no_water

				cmp.l	PlrT_YOff_l(a0),d1
				blt.s	.no_water

				tst.b	PlrT_StoodInTop_b(a0)
				bne.s	.no_water

				move.w	#6,d0
				bra.s	.have_water

.no_water:
				tst.b	PlrT_StoodInTop_b(a0)
				beq.s	.okinbot
				move.w	ZoneT_UpperFloorNoise_w(a1),d0

.okinbot:
				move.l	GLF_DatabasePtr_l,a1
				add.l	#GLFT_FloorData_l,a1
				move.w	2(a1,d0.w*4),d0			; sample number.

				subq	#1,d0
				blt.s	.no_foot_sound

.have_water:
				move.w	d0,Aud_SampleNum_w
				move.w	#0,Aud_NoiseX_w
				move.w	#100,Aud_NoiseZ_w
				move.w	#80,Aud_NoiseVol_w
				move.w	#$fff8,IDNUM
				clr.b	notifplaying
				move.b	PlrT_Echo_b(a0),SourceEcho
				jsr		MakeSomeNoise

.no_foot_sound:
				movem.l	(a7)+,d0-d7/a0-a6
				rts
