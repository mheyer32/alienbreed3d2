

;******************************************************************************
;*
;* Initialise player positions
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

;the right mouse button triggers the next_weapon key
				move.b	next_weapon_key,d7
				btst	#2,$dff000+potinp		; right button
				seq		(a5,d7.w)

; the left mouse button triggers the fire key
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
				muls	#SCREEN_WIDTH,d0
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
				bne.s	.crouch

				tst.b	PlrT_Ducked_b(a0)
				beq.s	.skip_crouch
.crouch:
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

				move.w	plr1_SnapSinVal_w,d1
				muls	d3,d1
				move.w	plr1_SnapCosVal_w,d2
				muls	d3,d2

				sub.l	d1,d6
				sub.l	d2,d7
				move.w	plr1_SnapSinVal_w,d1
				muls	d4,d1
				move.w	plr1_SnapCosVal_w,d2
				muls	d4,d2
				sub.l	d2,d6
				add.l	d1,d7

				tst.b	Plr_Decelerate_b
				beq.s	.nocontrolposs
				add.l	d6,PlrT_SnapXSpdVal_l(a0)
				add.l	d7,PlrT_SnapZSpdVal_l(a0)

.nocontrolposs:
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
				bra		.doneplr1

.firenownotpressed:
; fire has been released.
				clr.b	PlrT_Fire_b(a0)
				bra		.doneplr1

.firenotpressed:

; fire was not pressed last frame...

				tst.b	(a5,d5.w)
; if it has still not been pressed, go back above
				beq.s	.firenownotpressed
; fire was not pressed last time, and was this time, so has
; been clicked.
				st		PlrT_Clicked_b(a0)
				st		PlrT_Fire_b(a0)

.doneplr1:
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
