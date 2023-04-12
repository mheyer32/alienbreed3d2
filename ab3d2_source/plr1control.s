
;Plr1_AlwaysKeys:
;				move.l	#KeyMap_vb,a5
;				moveq	#0,d7
;
;				move.b	next_weapon_key,d7
;				tst.b	(a5,d7.w)
;				beq.s	.nonextweappre
;
;				tst.b	gunheldlast
;				bne.s	.nonextweap
;				st		gunheldlast
;				moveq	#0,d0
;				move.b	Plr1_GunSelected_b,d0
;				move.l	#Plr1_Weapons_vb,a0
;
;.findnext:
;				addq	#1,d0
;				cmp.w	#9,d0
;				ble.s	.okgun
;				moveq	#0,d0
;
;.okgun:
;				tst.w	(a0,d0.w*2)
;				beq.s	.findnext
;
;				move.b	d0,Plr1_GunSelected_b
;				bsr		Plr1_ShowGunName
;
;				bra		.nonextweap
;
;.nonextweappre:
;				clr.b	gunheldlast
;
;.nonextweap:
;				move.b	operate_key,d7
;				move.b	(a5,d7.w),d1
;				beq.s	.nottapped
;				tst.b	OldSpace
;				bne.s	.nottapped
;				st		Plr1_Used_b
;
;.nottapped:
;				move.b	d1,OldSpace
;
;				move.b	duck_key,d7
;				tst.b	(a5,d7.w)
;				beq.s	.notduck
;				clr.b	(a5,d7.w)
;				move.l	#PLR_STAND_HEIGHT,Plr1_SnapTargHeight_l
;				not.b	Plr1_Ducked_b
;				beq.s	.notduck
;				move.l	#PLR_CROUCH_HEIGHT,Plr1_SnapTargHeight_l
;
;.notduck:
;				move.l	Plr1_ZonePtr_l,a4
;				move.l	ZoneT_Floor_l(a4),d0
;				sub.l	ZoneT_Roof_l(a4),d0
;				tst.b	Plr1_StoodInTop_b
;				beq.s	.use_bottom
;				move.l	ZoneT_UpperFloor_l(a4),d0
;				sub.l	ZoneT_UpperRoof_l(a4),d0
;
;.use_bottom:
;				clr.b	Plr1_Squished_b
;				move.l	#PLR_STAND_HEIGHT,plr1_SnapSquishedHeight_l
;
;				cmp.l	#PLR_STAND_HEIGHT+3*1024,d0
;				bgt.s	.oktostand
;				st		Plr1_Squished_b
;				move.l	#PLR_CROUCH_HEIGHT,plr1_SnapSquishedHeight_l
;
;.oktostand:
;				move.l	Plr1_SnapTargHeight_l,d1
;				move.l	plr1_SnapSquishedHeight_l,d0
;				cmp.l	d0,d1
;				blt.s	.notsqu
;				move.l	d0,d1
;
;.notsqu:
;				move.l	Plr1_SnapHeight_l,d0
;				cmp.l	d1,d0
;				beq.s	.noupordown
;				bgt.s	.crouch
;				add.l	#1024,d0
;				bra		.noupordown
;
;.crouch:
;				sub.l	#1024,d0
;
;.noupordown:
;				move.l	d0,Plr1_SnapHeight_l
;
;				tst.b	RAWKEY_K(a5)
;				beq.s	.notselkey
;				st		Plr1_Keys_b
;				clr.b	Plr1_Path_b
;				clr.b	Plr1_Mouse_b
;				clr.b	Plr1_Joystick_b
;
;.notselkey:
;				tst.b	RAWKEY_J(a5)
;				beq.s	.notseljoy
;				clr.b	Plr1_Keys_b
;				clr.b	Plr1_Path_b
;				clr.b	Plr1_Mouse_b
;				st		Plr1_Joystick_b
;
;.notseljoy:
;				tst.b	RAWKEY_M(a5)
;				beq.s	.notselmouse
;				clr.b	Plr1_Keys_b
;				clr.b	Plr1_Path_b
;				st		Plr1_Mouse_b
;				clr.b	Plr1_Joystick_b
;
;.notselmouse:
;				lea		1(a5),a4
;				move.l	#Plr1_Weapons_vb,a2
;				move.l	Plr1_ObjectPtr_l,a3
;				move.w	#9,d1
;				move.w	#0,d2
;
;.pickweap:
;				move.w	(a2)+,d0
;				and.b	(a4)+,d0
;				beq.s	.notgotweap
;				move.b	d2,Plr1_GunSelected_b
;				move.w	#0,EntT_Timer1_w+128(a3)
;
; d2=number of gun.
;
;				bsr		Plr1_ShowGunName
;
;				bra.s	.gogog
;
;.notgotweap:
;				addq	#1,d2
;				dbra	d1,.pickweap
;
;.gogog:
;				tst.b	RAWKEY_F10(a5)
;				beq.s	.notswapscr
;				tst.b	lastscr
;				bne.s	.notswapscr2
;				st		lastscr
;
;				not.b	Vid_FullScreenTemp_b
;
;				bra.s	.notswapscr2
;
;.notswapscr:
;				clr.b	lastscr
;
;.notswapscr2:
;				tst.b	RAWKEY_F7(a5)
;				beq.s	.noframelimit
;				clr.b	RAWKEY_F7(a5)
;				cmp.l	#5,Vid_FPSLimit_l
;				beq.s	.resetfpslimit
;				addq.l	#1,Vid_FPSLimit_l
;				bra.s	.noframelimit
;
;.resetfpslimit:
;				clr.l	Vid_FPSLimit_l
;
;.noframelimit:
;				; Developer toggles
;				DEV_CHECK_KEY	RAWKEY_E,SIMPLE_WALLS
;				DEV_CHECK_KEY	RAWKEY_R,SHADED_WALLS
;				DEV_CHECK_KEY	RAWKEY_T,BITMAPS
;				DEV_CHECK_KEY	RAWKEY_Y,GLARE_BITMAPS
;				DEV_CHECK_KEY	RAWKEY_U,ADDITIVE_BITMAPS
;				DEV_CHECK_KEY	RAWKEY_I,LIGHTSOURCED_BITMAPS
;				DEV_CHECK_KEY	RAWKEY_O,POLYGON_MODELS
;				DEV_CHECK_KEY	RAWKEY_G,FLATS
;				DEV_CHECK_KEY	RAWKEY_Q,FASTBUFFER_CLEAR
;				DEV_CHECK_KEY	RAWKEY_N,AI_ATTACK
;				rts

Plr1_ShowGunName:
				moveq	#0,d2
				move.b	Plr1_GunSelected_b,d2
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

Plr1_MouseControl:
				lea		Plr1_Data,a0
				jsr		plr_MouseControl

Plr1_KeyboardControl:
				;jsr		Plr1_AlwaysKeys
				lea		Plr1_Data,a0
				jsr		plr_CheckKeys
				jsr		plr_KeyboardControl

				jsr		Plr1_Fall

				rts

Plr1_JoystickControl:
				jsr		_ReadJoy1
				bra		Plr1_KeyboardControl

Plr1_FootstepFX:
				lea		Plr1_Data,a0
				bra		plr_DoFootstepFX

Plr1_FollowPath:
				move.l	pathpt,a0
				move.w	(a0),d1
				move.w	d1,Plr1_SnapXOff_l
				move.w	2(a0),d1
				move.w	d1,Plr1_SnapZOff_l
				move.w	4(a0),d0
				add.w	d0,d0
				and.w	#8190,d0
				move.w	d0,Plr1_AngPos_w
				move.w	Anim_TempFrames_w,d0
				asl.w	#3,d0
				adda.w	d0,a0
				cmp.l	#endpath,a0
				blt		.notrestartpath

				move.l	#Path,a0
.notrestartpath:
				move.l	a0,pathpt

				rts
