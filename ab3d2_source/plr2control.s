
Plr2_MouseControl
				jsr		Sys_ReadMouse

				move.l	#SinCosTable_vw,a0
				move.w	Plr2_SnapAngSpd_w,d1
				move.w	angpos,d0
				and.w	#8190,d0
				move.w	d0,Plr2_SnapAngPos_w
				move.w	(a0,d0.w),plr2_SnapSinVal_w
				adda.w	#2048,a0
				move.w	(a0,d0.w),plr2_SnapCosVal_w

				move.l	Plr2_SnapXSpdVal_l,d6
				move.l	Plr2_SnapZSpdVal_l,d7

				neg.l	d6
				ble.s	.nobug1
				asr.l	#1,d6
				add.l	#1,d6
				bra.s	.bug1
.nobug1
				asr.l	#1,d6
.bug1:

				neg.l	d7
				ble.s	.nobug2
				asr.l	#1,d7
				add.l	#1,d7
				bra.s	.bug2
.nobug2
				asr.l	#1,d7
.bug2:

				move.w	ymouse,d3
				sub.w	oldymouse,d3
				add.w	d3,oldymouse

				move.w	STOPOFFSET,d0
				move.w	d3,d2
				asl.w	#7,d2

				add.w	d2,Plr2_AimSpeed_l
				add.w	d3,d0
				cmp.w	#-80,d0
				bgt.s	.skip_look_up
				move.w	#-512*20,Plr2_AimSpeed_l
				move.w	#-80,d0
.skip_look_up:
				cmp.w	#80,d0
				blt.s	.skip_look_down
				move.w	#512*20,Plr2_AimSpeed_l
				move.w	#80,d0
.skip_look_down

				move.w	d0,STOPOFFSET
				neg.w	d0
				add.w	TOTHEMIDDLE,d0
				move.w	d0,SMIDDLEY
				muls	#SCREEN_WIDTH,d0
				move.l	d0,SBIGMIDDLEY

				move.l	#KeyMap_vb,a5
				moveq	#0,d7
				move.b	forward_key,d7

				btst	#6,$bfe001
				seq		(a5,d7.w)

				move.b	fire_key,d7
				btst	#2,$dff016
				seq		(a5,d7.w)

				bra		PLR2_keyboard_control

				move.w	#-20,d2

				tst.b	Plr2_Squished_b
				bne.s	.crouch
				tst.b	Plr2_Ducked_b
				beq.s	.skip_crouch
.crouch
				asr.w	#1,d2
.skip_crouch

				btst	#6,$bfe001
				beq.s	.moving
				moveq	#0,d2
.moving:

				move.w	d2,d3
				asl.w	#4,d2
				move.w	d2,d1

				move.w	d1,ADDTOBOBBLE

				move.w	plr2_SnapSinVal_w,d1
				move.w	plr2_SnapCosVal_w,d2

				move.w	d2,d4
				move.w	d1,d5
				muls	lrs,d4
				muls	lrs,d5

				muls	d3,d2
				muls	d3,d1
				sub.l	d4,d1
				add.l	d5,d2

				sub.l	d1,d6
				sub.l	d2,d7
				add.l	d6,Plr2_SnapXSpdVal_l
				add.l	d7,Plr2_SnapZSpdVal_l
				move.l	Plr2_SnapXSpdVal_l,d6
				move.l	Plr2_SnapZSpdVal_l,d7
				add.l	d6,Plr2_SnapXOff_l
				add.l	d7,Plr2_SnapZOff_l

				tst.b	Plr2_Fire_b
				beq.s	.firenotpressed
; fire was pressed last time.
				btst	#6,$bfe001
				bne.s	.firenownotpressed
; fire is still pressed this time.
				st		Plr2_Fire_b
				bra		.donePLR2

.firenownotpressed:
; fire has been released.
				clr.b	Plr2_Fire_b
				bra		.donePLR2

.firenotpressed

; fire was not pressed last frame...

				btst	#6,$bfe001
; if it has still not been pressed, go back above
				bne.s	.firenownotpressed
; fire was not pressed last time, and was this time, so has
; been clicked.
				st		Plr2_Clicked_b
				st		Plr2_Fire_b

.donePLR2:

				bsr		Plr2_Fall

				rts

Plr2_AlwaysKeys
				move.l	#KeyMap_vb,a5
				moveq	#0,d7

				move.b	next_weapon_key,d7
				tst.b	(a5,d7.w)
				beq.s	.nonextweappre

; tst.b Plr2_GunFrame_w
; bne.s .nonextweappre

				tst.b	gunheldlast
				bne.s	.nonextweap
				st		gunheldlast

				moveq	#0,d0
				move.b	Plr2_GunSelected_b,d0
				move.l	#Plr2_Weapons_vb,a0

.findnext
				addq	#1,d0
				cmp.w	#9,d0
				ble.s	.okgun
				moveq	#0,d0
.okgun:
				tst.w	(a0,d0.w*2)
				beq.s	.findnext

				move.b	d0,Plr2_GunSelected_b
				bsr		SHOWPLR2GUNNAME

				bra		.nonextweap

.nonextweappre:
				clr.b	gunheldlast
.nonextweap:


				move.b	operate_key,d7
				move.b	(a5,d7.w),d1
				beq.s	.nottapped
				tst.b	OldSpace
				bne.s	.nottapped
				st		PLR2_SPCTAP
.nottapped:
				move.b	d1,OldSpace

				move.b	duck_key,d7
				tst.b	(a5,d7.w)
				beq.s	.notduck
				clr.b	(a5,d7.w)
				move.l	#PLR_STAND_HEIGHT,Plr2_SnapTargHeight_l
				not.b	Plr2_Ducked_b
				beq.s	.notduck
				move.l	#PLR_CROUCH_HEIGHT,Plr2_SnapTargHeight_l
.notduck:

				move.l	Plr2_RoomPtr_l,a4
				move.l	ZoneT_Floor_l(a4),d0
				sub.l	ZoneT_Roof_l(a4),d0
				tst.b	Plr2_StoodInTop_b
				beq.s	.use_bottom
				move.l	ZoneT_UpperFloor_l(a4),d0
				sub.l	ZoneT_UpperRoof_l(a4),d0
.use_bottom:

				clr.b	Plr2_Squished_b
				move.l	#PLR_STAND_HEIGHT,plr2_SnapSquishedHeight_l

				cmp.l	#PLR_STAND_HEIGHT+3*1024,d0
				bgt.s	oktostand2
				st		Plr2_Squished_b
				move.l	#PLR_CROUCH_HEIGHT,plr2_SnapSquishedHeight_l
oktostand2:

				move.l	Plr2_SnapTargHeight_l,d1
				move.l	plr2_SnapSquishedHeight_l,d0
				cmp.l	d0,d1
				blt.s	.notsqu
				move.l	d0,d1
.notsqu:

				move.l	Plr2_SnapHeight_l,d0
				cmp.l	d1,d0
				beq.s	.noupordown
				bgt.s	.crouch
				add.l	#1024,d0
				bra		.noupordown
.crouch:
				sub.l	#1024,d0
.noupordown:
				move.l	d0,Plr2_SnapHeight_l

				tst.b	RAWKEY_K(a5)
				beq.s	.notselkey
				st		Plr2_Keys_b
				clr.b	Plr2_Path_b
				clr.b	Plr2_Mouse_b
				clr.b	Plr2_Joystick_b
.notselkey:

				tst.b	RAWKEY_J(a5)
				beq.s	.notseljoy
				clr.b	Plr2_Keys_b
				clr.b	Plr2_Path_b
				clr.b	Plr2_Mouse_b
				st		Plr2_Joystick_b
.notseljoy:

				tst.b	RAWKEY_M(a5)
				beq.s	.notselmouse
				clr.b	Plr2_Keys_b
				clr.b	Plr2_Path_b
				st		Plr2_Mouse_b
				clr.b	Plr2_Joystick_b

.notselmouse:
				lea		1(a5),a4
				move.l	#Plr2_Weapons_vb,a2
				move.l	Plr2_ObjectPtr_l,a3
				move.w	#9,d1
				move.w	#0,d2
pickweap2
				move.w	(a2)+,d0
				and.b	(a4)+,d0
				beq.s	notgotweap2
				move.b	d2,Plr2_GunSelected_b
				move.w	#0,EntT_Timer1_w+64(a3)

; d2=number of gun.

				bsr		SHOWPLR2GUNNAME

				bra.s	gogogogog

notgotweap2:
				addq	#1,d2
				dbra	d1,pickweap2

gogogogog:
				tst.b	RAWKEY_NUM_ENTER(a5)
				beq.s	.notswapscr
				tst.b	lastscr
				bne.s	.notswapscr2
				st		lastscr

				not.b	Vid_FullScreenTemp_b

				bra.s	.notswapscr2

.notswapscr:
				clr.b	lastscr
.notswapscr2:
				rts

SHOWPLR2GUNNAME:
				moveq	#0,d2
				move.b	Plr2_GunSelected_b,d2

				move.l	GLF_DatabasePtr_l,a4
				add.l	#GLFT_GunNames_l,a4
				muls	#20,d2
				add.l	d2,a4
				move.l	#TEMPSCROLL,a2
				move.w	#19,d2

.copyname:
				move.b	(a4)+,d3
				bne.s	.oklet
				move.b	#32,d3
.oklet:
				move.b	d3,(a2)+

				dbra	d2,.copyname

				move.l	#TEMPSCROLL,d0
				jsr		SENDMESSAGENORET
				rts

TURNSPD:		dc.w	0

PLR2_keyboard_control:

				move.l	#SinCosTable_vw,a0

				jsr		Plr2_AlwaysKeys
				move.l	#KeyMap_vb,a5

				move.w	STOPOFFSET,d0
				moveq	#0,d7
				move.b	look_up_key,d7
				tst.b	(a5,d7.w)
				beq.s	.skip_look_up

				sub.w	#512,Plr2_AimSpeed_l
				sub.w	#4,d0
				cmp.w	#-80,d0
				bgt.s	.skip_look_up
				move.w	#-512*20,Plr2_AimSpeed_l
				move.w	#-80,d0
.skip_look_up:
				moveq	#0,d7
				move.b	look_down_key,d7
				tst.b	(a5,d7.w)
				beq.s	.skip_look_down
				add.w	#512,Plr2_AimSpeed_l
				add.w	#4,d0
				cmp.w	#80,d0
				blt.s	.skip_look_down
				move.w	#512*20,Plr2_AimSpeed_l
				move.w	#80,d0

.skip_look_down:
				move.b	centre_view_key,d7
				tst.b	(a5,d7.w)
				beq.s	.skip_centre_look

				tst.b	Plr_OldCentre_b
				bne.s	.skip_centre_look_2
				st		Plr_OldCentre_b

				move.w	#0,d0
				move.w	#0,Plr2_AimSpeed_l

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
				move.w	Plr2_SnapAngPos_w,d0
				move.w	Plr2_SnapAngSpd_w,d3
				move.w	#35,d1
				move.w	#2,d2
				move.w	#10,TURNSPD
				moveq	#0,d7
				move.b	run_key,d7
				tst.b	(a5,d7.w)
				beq.s	.skip_run

				move.w	#60,d1
				move.w	#3,d2
				move.w	#14,TURNSPD
.skip_run:
				tst.b	Plr2_Squished_b
				bne.s	.crouch

				tst.b	Plr2_Ducked_b
				beq.s	.skip_crouch
.crouch:
				asr.w	#1,d2
.skip_crouch

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
				beq.s	noturnposs2


				move.b	templeftkey,d7
				tst.b	(a5,d7.w)
				beq.s	.skip_turn_left
				sub.w	TURNSPD,d3
.skip_turn_left
				move.l	#KeyMap_vb,a5
				move.b	temprightkey,d7
				tst.b	(a5,d7.w)
				beq.s	.skip_turn_right
				add.w	TURNSPD,d3
.skip_turn_right

				cmp.w	d1,d3
				ble.s	.right_speed_ok
				move.w	d1,d3
.right_speed_ok:
				neg.w	d1
				cmp.w	d1,d3
				bge.s	.left_speed_ok
				move.w	d1,d3
.left_speed_ok:

noturnposs2:

				add.w	d3,d0
				add.w	d3,d0
				move.w	d3,Plr2_SnapAngSpd_w

				move.b	tempslkey,d7
				tst.b	(a5,d7.w)
				beq.s	.skip_step_left
				add.w	d2,d4
				add.w	d2,d4
				asr.w	#1,d4
.skip_step_left
				move.l	#KeyMap_vb,a5
				move.b	tempsrkey,d7
				tst.b	(a5,d7.w)
				beq.s	.skip_step_right
				add.w	d2,d4
				add.w	d2,d4
				asr.w	#1,d4
				neg.w	d4
.skip_step_right

noslide2:

				and.w	#8191,d0
				move.w	d0,Plr2_SnapAngPos_w

				move.w	(a0,d0.w),plr2_SnapSinVal_w
				adda.w	#2048,a0
				move.w	(a0,d0.w),plr2_SnapCosVal_w

				move.l	Plr2_SnapXSpdVal_l,d6
				move.l	Plr2_SnapZSpdVal_l,d7

				tst.b	Plr_Decelerate_b
				beq.s	.skip_friction

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

.skip_friction

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
				move.w	d1,ADDTOBOBBLE

				move.w	plr2_SnapSinVal_w,d1
				muls	d3,d1
				move.w	plr2_SnapCosVal_w,d2
				muls	d3,d2

				sub.l	d1,d6
				sub.l	d2,d7
				move.w	plr2_SnapSinVal_w,d1
				muls	d4,d1
				move.w	plr2_SnapCosVal_w,d2
				muls	d4,d2
				sub.l	d2,d6
				add.l	d1,d7

				tst.b	Plr_Decelerate_b
				beq.s	.nocontrolposs
				add.l	d6,Plr2_SnapXSpdVal_l
				add.l	d7,Plr2_SnapZSpdVal_l
.nocontrolposs:
				move.l	Plr2_SnapXSpdVal_l,d6
				move.l	Plr2_SnapZSpdVal_l,d7
				add.l	d6,Plr2_SnapXOff_l
				add.l	d7,Plr2_SnapZOff_l

				move.b	fire_key,d5
				tst.b	Plr2_Fire_b
				beq.s	.firenotpressed
; fire was pressed last time.
				tst.b	(a5,d5.w)
				beq.s	.firenownotpressed
; fire is still pressed this time.
				st		Plr2_Fire_b
				bra		.doneplr2

.firenownotpressed:
; fire has been released.
				clr.b	Plr2_Fire_b
				bra		.doneplr2

.firenotpressed

; fire was not pressed last frame...

				tst.b	(a5,d5.w)
; if it has still not been pressed, go back above
				beq.s	.firenownotpressed
; fire was not pressed last time, and was this time, so has
; been clicked.
				st		Plr2_Clicked_b
				st		Plr2_Fire_b

.doneplr2:

				bsr		Plr2_Fall

				rts



PLR2_JoyStick_control:

				jsr		_ReadJoy2
				bra		PLR2_keyboard_control

PLR2_clumptime:	dc.w	0

PLR2clump:

				movem.l	d0-d7/a0-a6,-(a7)
				move.l	Plr2_RoomPtr_l,a0
				move.w	ZoneT_FloorNoise_w(a0),d0

				move.l	ZoneT_Water_l(a0),d1
				cmp.l	ZoneT_Floor_l(a0),d1
				bge.s	THERESNOWATER2

				cmp.l	Plr2_YOff_l,d1
				blt.s	THERESNOWATER2

				tst.b	Plr2_StoodInTop_b
				bne.s	THERESNOWATER2

				move.w	#6,d0
				bra.s	THERESWATER2

THERESNOWATER2:

				tst.b	Plr2_StoodInTop_b
				beq.s	.okinbot
				move.w	ZoneT_UpperFloorNoise_w(a0),d0
.okinbot:

				move.l	GLF_DatabasePtr_l,a0
				add.l	#GLFT_FloorData_l,a0
				move.w	2(a0,d0.w*4),d0			; sample number.

				subq	#1,d0
				blt.s	nofootsound2

THERESWATER2:
				move.w	d0,Samplenum
				move.w	#0,Noisex
				move.w	#100,Noisez
				move.w	#80,Noisevol
				move.w	#$fff8,IDNUM
				clr.b	notifplaying
				move.b	Plr2_Echo_b,SourceEcho
				jsr		MakeSomeNoise

nofootsound2:
				movem.l	(a7)+,d0-d7/a0-a6

				rts
