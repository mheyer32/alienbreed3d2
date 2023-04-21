
; *****************************************************************************
; *
; * modules/player.s
; *
; * Common code for player control.
; *
; *****************************************************************************

;******************************************************************************
;*
;* Initialise player positions (both players)
;*
;******************************************************************************
Plr_Initialise:
				move.l	Lvl_DataPtr_l,a1
				add.l	#160*10,a1
				move.w	4(a1),d0
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
				add.l	#160*10,a1
				move.w	10(a1),d0
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
				move.w	(a1),Plr1_SnapXOff_l
				move.w	2(a1),Plr1_SnapZOff_l
				move.w	(a1),Plr1_XOff_l
				move.w	2(a1),Plr1_ZOff_l
				move.w	6(a1),Plr2_SnapXOff_l
				move.w	8(a1),Plr2_SnapZOff_l
				move.w	6(a1),Plr2_XOff_l
				move.w	8(a1),Plr2_ZOff_l

				; Set up the default enemy flags for projectile logic
				move.l	#%100011,plr1_DefaultEnemyFlags_l ; Bit 5 is player 2 ?
				move.l	#%010011,plr2_DefaultEnemyFlags_l ; Bit 4 is player 1 ?

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
				jsr		Sys_ReadMouse

				move.l	(a7)+,a0
				move.l	#SinCosTable_vw,a1
				move.w	PlrT_SnapAngSpd_w(a0),d1
				move.w	angpos,d0
				and.w	#8190,d0
				move.w	d0,PlrT_SnapAngPos_w(a0)
				move.w	(a1,d0.w),PlrT_SnapSinVal_w(a0)
				adda.w	#2048,a1
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

				st		PlrT_Keys_b(a0)
				clr.b	PlrT_Path_b(a0)
				clr.b	PlrT_Mouse_b(a0)
				clr.b	PlrT_Joystick_b(a0)

.notselkey:
				tst.b	RAWKEY_J(a5)
				beq.s	.notseljoy

				clr.b	PlrT_Keys_b(a0)
				clr.b	PlrT_Path_b(a0)
				clr.b	PlrT_Mouse_b(a0)
				st		PlrT_Joystick_b(a0)

.notseljoy:
				tst.b	RAWKEY_M(a5)
				beq.s	.notselmouse

				clr.b	PlrT_Keys_b(a0)
				clr.b	PlrT_Path_b(a0)
				st		PlrT_Mouse_b(a0)
				clr.b	PlrT_Joystick_b(a0)

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

				; todo - why does this change for player 1 and 2?
				cmp.l	Plr1_Data,a0
				bne.s	.use_player_2_timer

.use_player_1_timer:
				move.w	#0,EntT_Timer1_w+128(a3)
				bsr		plr_ShowGunName

				bra.s	.go

.use_player_2_timer:
				move.w	#0,EntT_Timer1_w+64(a3)
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
				move.w	#35,d1
				move.w	#2,d2
				move.w	#10,Plr_TurnSpeed_w
				moveq	#0,d7
				move.b	run_key,d7
				tst.b	(a5,d7.w)
				beq.s	.skip_run

				move.w	#60,d1
				move.w	#3,d2
				move.w	#14,Plr_TurnSpeed_w

.skip_run:
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
				and.w	#8191,d0
				move.w	d0,PlrT_SnapAngPos_w(a0)
				move.w	(a1,d0.w),PlrT_SnapSinVal_w(a0)
				adda.w	#2048,a1
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
				moveq	#0,d2
				move.b	PlrT_GunSelected_b(a0),d2
				move.l	GLF_DatabasePtr_l,a4
				add.l	#GLFT_GunNames_l,a4
				muls	#20,d2
				add.l	d2,a4
				move.l	#TempMessageBuffer_vb,a2
				move.w	#19,d2

.copyname:
				move.b	(a4)+,d3
				bne.s	.oklet
				move.b	#32,d3

.oklet:
				move.b	d3,(a2)+
				dbra	d2,.copyname

				move.l	#TempMessageBuffer_vb,d0
				jsr		Game_PushTempMessage

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
				and.w	#8190,d3
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
				and.w	#8190,d3
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
				move.w	#6,Samplenum ; todo define a constant for this
				move.w	#0,Noisex
				move.w	#100,Noisez
				move.w	#80,Noisevol
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
				move.w	d0,Samplenum
				move.w	#0,Noisex
				move.w	#100,Noisez
				move.w	#80,Noisevol
				move.w	#$fff8,IDNUM
				clr.b	notifplaying
				move.b	PlrT_Echo_b(a0),SourceEcho
				jsr		MakeSomeNoise

.no_foot_sound:
				movem.l	(a7)+,d0-d7/a0-a6
				rts

;******************************************************************************
;*
;* Determine which objects are in line with the player for shot mechanics. This
;* seems to process all objects in the level which seems inefficient. TODO See
;* if this can be applied to a list of potentially visible objects only.
;*
;* Pointer to player data in a0
;*
;******************************************************************************
				align 4
Plr_CalcInLine:
				move.w	PlrT_SinVal_w(a0),d5
				move.w	PlrT_CosVal_w(a0),d6
				lea		PlrT_ObjectsInLine_vb(a0),a2
				lea		PlrT_ObjectDistances_vw(a0),a3
				move.l	Lvl_ObjectDataPtr_l,a4

				move.l	Lvl_ObjectPointsPtr_l,a1
				move.w	Lvl_NumObjectPoints_w,d7

.obj_point_rotate_loop:
				cmp.b	#3,16(a4)
				beq.s	.itaux

				move.w	(a1),d0
				sub.w	PlrT_XOff_l(a0),d0
				move.w	4(a1),d1
				addq	#8,a1

				tst.w	12(a4)
				blt		.noworkout

				moveq	#0,d2
				move.b	16(a4),d2

				sub.w	PlrT_ZOff_l(a0),d1
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
				ble.s	.not_inline

				asr.w	#1,d2
				cmp.w	#80,d2 ; get this from object?
				bgt.s	.not_inline

				st		d3
.not_inline:
				move.b	d3,(a2)+
				move.w	d1,(a3)+

				add.w	#64,a4
				dbra	d7,.obj_point_rotate_loop

				rts

.itaux:
				add.w	#64,a4
				bra.s	.obj_point_rotate_loop

.noworkout:
				move.b	#0,(a2)+
				move.w	#0,(a3)+
				add.w	#64,a4
				dbra	d7,.obj_point_rotate_loop

				rts

;******************************************************************************
;*
;* Handle player shot mechanics.
;*
;* Pointer to player data in a0.
;*
;******************************************************************************
				align 4

Plr_Shot:
				tst.w	PlrT_TimeToShoot_w(a0)
				beq.s	.can_fire

				move.w	Anim_TempFrames_w,d0
				sub.w	d0,PlrT_TimeToShoot_w(a0)
				bge		.no_fire

				move.w	#0,PlrT_TimeToShoot_w(a0)

.no_fire:		; early out
				rts

.can_fire:
				; relocate player pointer to a3 as there's a lot of temporary register clobbering
				move.l	a0,a3
				moveq	#0,d0
				move.b	PlrT_TmpGunSelected_b(a3),d0
				move.b	d0,plr_TempGun_b
				move.l	GLF_DatabasePtr_l,a6
				lea		GLFT_ShootDefs_l(a6),a6
				lea		GLFT_BulletDefs_l-GLFT_ShootDefs_l(a6),a5
				lea		(a6,d0.w*8),a6
				move.w	ShootT_BulType_w(a6),d0		; bullet type
				move.w	d0,plr_BulletType_w
				lea		PlrT_AmmoCounts_vw(a3),a0
				move.w	(a0,d0.w*2),plr_AmmoInMyGun_w
				muls	#BulT_SizeOf_l,d0
				add.w	d0,a5
				move.w	BulT_Speed_l+2(a5),plr_BulletSpeed_w
				tst.b	PlrT_TmpFire_b(a3)
				beq		.no_fire

				move.w	PlrT_AngPos_w(a3),d0
				move.w	d0,plr_TempAnglePos_w
				move.l	#SinCosTable_vw,a0
				lea		(a0,d0.w),a0
				move.w	(a0),plr_TempXDir_w
				move.w	2048(a0),plr_TempZDir_w
				move.w	PlrT_XOff_l(a3),tempxoff
				move.w	PlrT_ZOff_l(a3),tempzoff
				move.l	PlrT_YOff_l(a3),plr_TempYOffset_l
				add.l	#10*128,plr_TempYOffset_l
				move.b	PlrT_StoodInTop_b(a3),plr_TempStoodInTop_b
				move.l	PlrT_ZonePtr_l(a3),tempRoompt
				move.l	PlrT_DefaultEnemyFlags_l(a3),d7
				move.w	#-1,d0
				move.l	#0,plr_TargetYDiff_l
				move.l	#$7fff,d1
				lea		PlrT_ObjectsInLine_vb(a3),a1
				move.l	Lvl_ObjectDataPtr_l,a0
				lea		PlrT_ObjectDistances_vw(a3),a2

				; object pointed to by a0
.find_closest_in_line:
				tst.w	(a0)
				blt		.out_of_line

				cmp.b	#3,16(a0)
				beq		.not_lined_up

				tst.b	(a1)+
				beq.s	.not_lined_up

				btst	#0,17(a0)
				beq.s	.not_lined_up

				tst.w	12(a0)
				blt.s	.not_lined_up

				move.b	16(a0),d6
				btst	d6,d7
				beq.s	.not_lined_up

				tst.b	EntT_NumLives_b(a0)
				beq.s	.not_lined_up

				move.w	(a0),d5
				move.w	(a2,d5.w*2),d6
				move.w	4(a0),d2
				ext.l	d2
				asl.l	#7,d2
				sub.l	PlrT_YOff_l(a3),d2
				move.l	d2,d3
				bge.s	.not_negative

				neg.l	d2

.not_negative:
				;0xABADCAFE division pogrom
				;divs	#44,d2 ; Hitscanning doesnt work without this. But why 44?

				; Approximate 1/44 as 93/4096
				muls	#93,d2 ; todo - maybe needs to be muls.l ?
				asr.l	#8,d2
				asr.l	#4,d2

				cmp.w	d6,d2
				bgt.s	.not_lined_up

				cmp.w	d6,d1
				blt.s	.not_lined_up

				move.w	d6,d1
				move.l	a0,a4

				; We have a closer enemy lined up.
				move.l	d3,plr_TargetYDiff_l
				move.w	d5,d0

.not_lined_up:
				add.w	#64,a0
				bra		.find_closest_in_line

.out_of_line:
				move.w	d1,plr_TargetDistance_w
				move.l	plr_TargetYDiff_l,d5
				sub.l	PlrT_Height_l(a3),d5
				add.l	#18*256,d5
				move.w	d1,closedist
				move.w	plr_BulletSpeed_w,d2
				asr.w	d2,d1
				tst.w	d1
				bgt.s	.distance_ok

				moveq	#1,d1

.distance_ok:
				divs	d1,d5
				move.w	d5,bulyspd
				move.w	plr_AmmoInMyGun_w,d2
				move.w	ShootT_BulCount_w(a6),d1
				cmp.w	d1,d2
				bge.s	.okcanshoot

				move.l	PlrT_ObjectPtr_l(a3),a2
				move.w	(a2),d0
				move.l	#ObjRotated_vl,a2
				move.l	(a2,d0.w*8),Noisex
				move.w	#100,Noisevol
				move.w	#100,AI_Player1NoiseVol_w
				move.w	#12,Samplenum
				clr.b	notifplaying
				move.b	#$fb,IDNUM
				jsr		MakeSomeNoise

				rts

.okcanshoot:
				cmp.b	#PLR_SLAVE,Plr_MultiplayerType_b
				beq.s	.notplr1
				move.l	PlrT_ObjectPtr_l(a3),a2

				; todo - understand why this is different for player 2 code...
				move.w	#1,EntT_Timer1_w+128(a2)

.notplr1:
				move.w	ShootT_Delay_w(a6),PlrT_TimeToShoot_w(a3)
				move.b	plr_MaxGunFrame_b,PlrT_GunFrame_w(a3)
				sub.w	d1,d2
				lea		PlrT_AmmoCounts_vw(a3),a2
				add.w	plr_BulletType_w,a2
				add.w	plr_BulletType_w,a2
				move.w	d2,(a2)
				move.l	PlrT_ObjectPtr_l(a3),a2
				move.w	(a2),d2
				move.l	#ObjRotated_vl,a2
				move.l	(a2,d2.w*8),Noisex
				move.w	#100,AI_Player1NoiseVol_w
				move.w	#300,Noisevol
				move.w	ShootT_SFX_w(a6),Samplenum
				move.b	#2,chanpick
				clr.b	notifplaying
				movem.l	d0/a0/d5/d6/d7/a6/a4/a5/a3,-(a7)
				move.b	#$fb,IDNUM
				jsr		MakeSomeNoise

				movem.l	(a7)+,d0/a0/d5/d6/d7/a6/a4/a5/a3
				tst.w	d0
				blt		.nothing_to_shoot

				tst.l	BulT_Gravity_l(a5)
				beq.s	.skip_aim

				move.w	PlrT_AimSpeed_l(a3),d2
				move.w	#8,d1
				sub.w	plr_BulletSpeed_w,d1
				asr.w	d1,d2
				move.w	d2,bulyspd

.skip_aim:
				tst.w	BulT_IsHitScan_l+2(a5)
				beq		plr_FireProjectile

				move.w	ShootT_BulCount_w(a6),d7

.fire_hitscanned_bullets:
				movem.l	a0/a1/d7/d0/a4/a5/a3,-(a7)
				jsr		GetRand

				move.l	Lvl_ObjectPointsPtr_l,a1
				move.w	(a4),d1
				lea		(a1,d1.w*8),a1

				and.w	#$7fff,d0
				move.w	(a1),d1
				sub.w	PlrT_XOff_l(a3),d1
				muls	d1,d1
				move.w	4(a1),d2
				sub.w	PlrT_ZOff_l(a3),d2
				muls	d2,d2
				add.l	d2,d1
				asr.l	#6,d1
				ext.l	d0
				asl.l	#1,d0
				cmp.l	d1,d0
				bgt.s	.hit

				movem.l	(a7)+,a0/a1/d7/d0/a5/a4/a3
				move.l	d0,-(a7)
				bsr		plr_HitscanFailed

				move.l	(a7)+,d0
				bra.s	.missed

.hit:
				movem.l	(a7)+,a0/a1/d7/d0/a5/a4/a3
				move.l	d0,-(a7)
				bsr		plr_HitscanSucceded

				move.l	(a7)+,d0

.missed:
				subq	#1,d7
				bgt.s	.fire_hitscanned_bullets

				rts

.nothing_to_shoot:
				move.w	PlrT_AimSpeed_l(a3),d0
				move.w	#8,d1
				sub.w	plr_BulletSpeed_w,d1
				asr.w	d1,d0
				move.w	d0,bulyspd
				tst.w	BulT_IsHitScan_l+2(a5)
				beq		plr_FireProjectile

				move.w	#0,bulyspd
				move.w	PlrT_XOff_l(a3),oldx
				move.w	PlrT_ZOff_l(a3),oldz
				move.w	PlrT_SinVal_w(a3),d0
				asr.w	#7,d0
				add.w	oldx,d0
				move.w	d0,newx
				move.w	PlrT_CosVal_w(a3),d0
				asr.w	#7,d0
				add.w	oldz,d0
				move.w	d0,newz
				move.l	PlrT_YOff_l(a3),d0
				add.l	#10*128,d0
				move.l	d0,oldy
				move.l	d0,d1
				jsr		GetRand

				and.w	#$fff,d0
				sub.w	#$800,d0
				ext.l	d0
				add.l	d0,d1
				move.l	d1,newy
				st		exitfirst
				clr.b	Obj_WallBounce_b
				move.w	#0,Obj_ExtLen_w
				move.b	#$ff,Obj_AwayFromWall_b
				move.w	#%0000010000000000,wallflags
				move.l	#0,StepUpVal
				move.l	#$1000000,StepDownVal
				move.l	#0,thingheight
				move.l	PlrT_ZonePtr_l(a3),objroom
				movem.l	d0-d7/a0-a6,-(a7)

.again:
				jsr		MoveObject

				tst.b	hitwall
				bne.s	.nofurther
				move.w	newx,d0
				sub.w	oldx,d0
				add.w	d0,oldx
				add.w	d0,newx
				move.w	newz,d0
				sub.w	oldz,d0
				add.w	d0,oldz
				add.w	d0,newz
				move.l	newy,d0
				sub.l	oldy,d0
				add.l	d0,oldy
				add.l	d0,newy
				bra		.again

.nofurther:
				movem.l	(a7)+,d0-d7/a0-a6
				move.l	Plr_ShotDataPtr_l,a0
				move.w	#19,d1

.findonefree2:
				move.w	12(a0),d2
				blt.s	.foundonefree2
				adda.w	#64,a0
				dbra	d1,.findonefree2

				rts

.foundonefree2:
				move.l	Lvl_ObjectPointsPtr_l,a1
				move.w	(a0),d2
				move.w	newx,(a1,d2.w*8)
				move.w	newz,4(a1,d2.w*8)
				move.b	#1,ShotT_Status_b(a0)
				move.w	#0,ShotT_Gravity_w(a0)
				move.b	plr_BulletType_w+1,ShotT_Size_b(a0)
				move.b	#0,ShotT_Anim_b(a0)
				move.l	objroom,a1
				move.w	(a1),12(a0)
				st		ShotT_Worry_b(a0)
				move.l	wallhitheight,d0
				move.l	d0,ShotT_AccYPos_w(a0)
				asr.l	#7,d0
				move.w	d0,4(a0)
				rts

;******************************************************************************
;*
;* Launch projectile
;*
;* player data in a3
;*
;******************************************************************************
plr_FireProjectile:
				move.l	PlrT_DefaultEnemyFlags_l(a3),d7
				move.b	plr_MaxGunFrame_b,PlrT_GunFrame_w(a3)
				move.l	PlrT_ObjectPtr_l(a3),a2
				move.w	ShootT_BulCount_w(a6),d5
				move.w	d5,d6
				subq.w	#1,d6

				;muls	#128,d6
				asl.w	#7,d6

				neg.w	d6
				add.w	plr_TempAnglePos_w,d6
				and.w	#8190,d6

.firefive:
				move.l	Plr_ShotDataPtr_l,a0
				move.w	#19,d1

.findonefree:
				move.w	12(a0),d0
				blt.s	.foundonefree
				adda.w	#64,a0
				dbra	d1,.findonefree

				rts

.foundonefree:
				move.w	BulT_Gravity_l+2(a5),ShotT_Gravity_w(a0)
				move.b	BulT_BounceHoriz_l+3(a5),ShotT_Flags_w(a0)
				move.b	BulT_BounceVert_l+3(a5),ShotT_Flags_w+1(a0)
				move.w	bulyspd,d0
				cmp.w	#20*128,d0
				blt.s	.okdownspd

				move.w	#20*128,d0

.okdownspd:
				cmp.w	#-20*128,d0
				bgt.s	.okupspd

				move.w	#-20*128,d0

.okupspd:

; add.w G_InitialYVel(a6),d0

				move.w	d0,bulyspd
				move.l	#ObjRotated_vl,a2
				move.b	plr_BulletType_w+1,ShotT_Size_b(a0)
				move.b	BulT_HitDamage_l+3(a5),ShotT_Power_w(a0)

				move.l	Lvl_ObjectPointsPtr_l,a1
				move.w	(a0),d1
				lea		(a1,d1.w*8),a1
				move.w	tempxoff,(a1)
				move.w	tempzoff,4(a1)

				move.l	#SinCosTable_vw,a1
				move.w	(a1,d6.w),d0
				ext.l	d0
				add.w	#2048,a1
				move.w	(a1,d6.w),d2
				ext.l	d2

				add.w	#256,d6
				and.w	#8190,d6

				move.w	plr_BulletSpeed_w,d1
				asl.l	d1,d0
				move.l	d0,ShotT_VelocityX_w(a0)
				ext.l	d2
				asl.l	d1,d2
				move.b	#2,16(a0)
				move.l	d2,ShotT_VelocityZ_w(a0)
				move.w	bulyspd,ShotT_VelocityY_w(a0)
				move.b	plr_TempStoodInTop_b,ShotT_InUpperZone_b(a0)
				move.w	#0,ShotT_Lifetime_w(a0)
				move.l	d7,EntT_EnemyFlags_l(a0)
				move.l	tempRoompt,a2
				move.w	(a2),12(a0)
				move.l	plr_TempYOffset_l,d0
				add.l	#20*128,d0
				move.l	d0,ShotT_AccYPos_w(a0)
				st		ShotT_Worry_b(a0)
				asr.l	#7,d0
				move.w	d0,4(a0)

				sub.w	#1,d5
				bgt		.firefive

				rts

;******************************************************************************
;*
;* Handle failed hitscan
;*
;* player data in a3
;*
;******************************************************************************
plr_HitscanFailed:
				move.w	PlrT_XOff_l(a3),oldx
				move.w	PlrT_ZOff_l(a3),oldz
				move.l	PlrT_YOff_l(a3),d1
				add.l	#10*128,d1
				move.l	d1,oldy

				move.w	(a4),d0
				move.l	Lvl_ObjectPointsPtr_l,a1
				move.w	(a1,d0.w*8),d2
				sub.w	oldx,d2
				asr.w	#1,d2
				add.w	oldx,d2
				move.w	d2,newx
				move.w	4(a1,d0.w*8),d2
				sub.w	oldz,d2
				asr.w	#1,d2
				add.w	oldz,d2
				move.w	d2,newz

				move.w	4(a0),d2
				ext.l	d2
				asl.l	#7,d2
				move.l	d2,newy

				st		exitfirst
				clr.b	Obj_WallBounce_b
				move.w	#0,Obj_ExtLen_w
				move.b	#$ff,Obj_AwayFromWall_b
				move.w	#%0000010000000000,wallflags
				move.l	#0,StepUpVal
				move.l	#$1000000,StepDownVal
				move.l	#0,thingheight
				move.l	PlrT_ZonePtr_l(a3),objroom
				movem.l	d0-d7/a0-a6,-(a7)

.again:
				jsr		MoveObject

				tst.b	hitwall
				bne.s	.nofurther

				move.w	newx,d1
				sub.w	oldx,d1
				add.w	d1,oldx
				add.w	d1,newx
				move.w	newz,d1
				sub.w	oldz,d1
				add.w	d1,oldz
				add.w	d1,newz
				move.l	newy,d1
				sub.l	oldy,d1
				add.l	d1,oldy
				add.l	d1,newy
				bra		.again

.nofurther:
				movem.l	(a7)+,d0-d7/a0-a6
				move.l	Plr_ShotDataPtr_l,a0
				move.w	#19,d1

.findonefree2:
				move.w	12(a0),d2
				blt.s	.foundonefree2

				adda.w	#64,a0
				dbra	d1,.findonefree2

				rts

.foundonefree2:
				move.b	#2,16(a0)
				move.l	Lvl_ObjectPointsPtr_l,a1
				move.w	(a0),d2
				move.w	newx,(a1,d2.w*8)
				move.w	newz,4(a1,d2.w*8)
				move.b	#1,ShotT_Status_b(a0)
				move.w	#0,ShotT_Gravity_w(a0)
				move.b	plr_BulletType_w+1,ShotT_Size_b(a0)
				move.b	#0,ShotT_Anim_b(a0)

				move.l	objroom,a1
				move.w	(a1),12(a0)
				st		ShotT_Worry_b(a0)
				move.l	newy,d1
				move.l	d1,ShotT_AccYPos_w(a0)
				asr.l	#7,d1
				move.w	d1,4(a0)

				rts


;******************************************************************************
;*
;* Handle successful hitscan
;*
;* Pointer to player data in a0
;*
;******************************************************************************
plr_HitscanSucceded:
				; Just blow it up.
				move.l	Plr_ShotDataPtr_l,a0
				move.w	#19,d1
.find_one_free:
				move.w	12(a0),d2
				blt.s	.found_one_free

				adda.w	#64,a0
				dbra	d1,.find_one_free

				rts

.found_one_free:
				move.b	#2,16(a0)
				move.l	Lvl_ObjectPointsPtr_l,a1
				move.w	(a0),d2
				move.l	(a1,d0.w*8),(a1,d2.w*8)
				move.l	4(a1,d0.w*8),4(a1,d2.w*8)
				move.b	#1,ShotT_Status_b(a0)
				move.w	#0,ShotT_Gravity_w(a0)
				move.b	plr_BulletType_w+1,ShotT_Size_b(a0)
				move.b	#0,ShotT_Anim_b(a0)

				move.w	4(a4),d1
				ext.l	d1
				asl.l	#7,d1
				move.l	d1,ShotT_AccYPos_w(a0)
				move.w	12(a4),12(a0)
				st		ShotT_Worry_b(a0)
				move.w	4(a4),4(a0)

				move.w	BulT_HitDamage_l+2(a5),d0
				add.b	d0,EntT_DamageTaken_b(a4)

				move.w	plr_TempXDir_w,d1
				ext.l	d1
				asl.l	#3,d1
				swap	d1
				move.w	d1,EntT_ImpactX_w(a4)
				move.w	plr_TempZDir_w,d1
				ext.l	d1
				asl.l	#3,d1
				swap	d1
				move.w	d1,EntT_ImpactZ_w(a4)

				rts
