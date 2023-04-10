
Plr1_Fall:
				move.l	Plr1_SnapTYOff_l,d0
				move.l	Plr1_SnapYOff_l,d1
				move.l	Plr1_SnapYVel_l,d2
				cmp.l	d1,d0
				bgt		.above_ground
				beq.s	.on_ground

				st		Plr_Decelerate_b

; we are under the ground.

; move.l #0,d2
				sub.l	d1,d0
				cmp.l	#-512,d0
				bge.s	.not_too_big

				move.l	#-512,d0

.not_too_big:
				add.l	d0,d1
				bra		.proceed

.on_ground:
				move.w	Plr1_FloorSpd_w,d2
				ext.l	d2
				asl.l	#6,d2
				move.l	#Plr1_ObjectPtr_l,a4
				move.w	plr_FallDamage_w,d3
				sub.w	#100,d3 ; TODO - this should depend on the distance fallen.
				ble.s	.skip_damage

				add.b	d3,EntT_DamageTaken_b(a4)

.skip_damage:
				st		Plr_Decelerate_b
				move.w	#0,plr_FallDamage_w
				move.w	ADDTOBOBBLE,d3
				move.w	d3,d4
				add.w	Plr1_Bobble_w,d3
				and.w	#8190,d3
				move.w	d3,Plr1_Bobble_w
				add.w	plr1_WalkSFXTime_w,d4
				move.w	d4,d3
				and.w	#4095,d4
				move.w	d4,plr1_WalkSFXTime_w
				and.w	#-4096,d3
				beq.s	.skip_footstep_fx

				bsr		Plr1_FootstepFX

.skip_footstep_fx:
				move.l	#-1024,plr_JumpSpeed_l

				move.l	Plr1_ZonePtr_l,a2
				move.l	ZoneT_Water_l(a2),d0
				cmp.l	d0,d1
				blt.s	.not_in_water
				move.l	#-512,plr_JumpSpeed_l

.not_in_water:
				tst.w	Plr1_Health_w
				ble.s	.no_thrust

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
				tst.w	Plr1_Jetpack_w
				beq.s	.not_flying

				tst.w	Plr1_JetpackFuel_w
				beq.s	.not_flying

				cmp.w	#250,Plr1_JetpackFuel_w
				ble.s	.have_jetpack_fuel

				move.w	#250,Plr1_JetpackFuel_w

.have_jetpack_fuel:
				st		Plr_Decelerate_b
				move.l	#-128,plr_JumpSpeed_l
				move.l	#KeyMap_vb,a5
				moveq	#0,d7
				move.b	jump_key,d7
				tst.b	(a5,d7.w)
				beq.s	.not_flying

				sub.w	#1,Plr1_JetpackFuel_w
				add.l	plr_JumpSpeed_l,d2
				move.w	#0,plr_FallDamage_w
				move.w	#40,d3
				add.w	Plr1_Bobble_w,d3
				and.w	#8190,d3
				move.w	d3,Plr1_Bobble_w

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
				move.l	Plr1_ObjectPtr_l,a4
				add.b	d3,EntT_DamageTaken_b(a4)

.skip_damage_2:
				move.w	#0,plr_FallDamage_w
				move.w	Plr1_FloorSpd_w,d2
				ext.l	d2
				asl.l	#6,d2
				bra		.proceed

.still_above:
				add.l	#64,d2
				add.w	#1,plr_FallDamage_w

				move.l	Plr1_ZonePtr_l,a2
				move.l	ZoneT_Water_l(a2),d0
				cmp.l	d0,d1
				blt.s	.proceed

				cmp.l	plr_OldHeight_l,d0
				blt.s	.no_splash_fx

				movem.l	d0-d7/a0-a6,-(a7)
				move.w	#6,Samplenum
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
				move.l	Plr1_ZonePtr_l,a2
				move.l	ZoneT_Roof_l(a2),d3
				tst.b	Plr1_StoodInTop_b
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
				move.l	d2,Plr1_SnapYVel_l
				move.l	d1,Plr1_SnapYOff_l
				rts

;ARSE:
;				sub.l	d1,d0
;				slt		plr_CanJump_b
;				bgt.s	.above_ground
;				beq.s	.notfast
;				sub.l	#512,d2
;				blt.s	.notfast
;				move.l	#0,d2
;
;.notfast:
;				add.l	d2,d1
;				sub.l	d2,d0
;				blt.s	.pastitall
;				move.l	#0,d2
;				move.l	Plr1_SnapTYOff_l,d1
;				bra.s	.pastitall
;
;.above_ground:
;				add.l	d2,d1
;				add.l	#64,d2
;				move.l	#-1024,plr_JumpSpeed_l
;				move.l	Plr1_ZonePtr_l,a2
;				move.l	ZoneT_Water_l(a2),d0
;				cmp.l	d0,d1
;				blt.s	.pastitall
;
;				move.l	#-512,plr_JumpSpeed_l
;				cmp.l	#256*2,d2
;				blt.s	.pastitall
;				move.l	#256*2,d2
;
;.pastitall:
;				move.l	d2,Plr1_SnapYVel_l
;				move.l	d1,Plr1_SnapYOff_l
;				move.l	#KeyMap_vb,a5
;				tst.b	RAWKEY_NUM_1(a5) ; is this a dead code path? That's a weapon button
;				beq.s	.no_thrust_2
;
;				tst.b	plr_CanJump_b
;				beq.s	.no_thrust_2
;
;				move.l	plr_JumpSpeed_l,Plr1_SnapYVel_l
;
;.no_thrust_2:
;				move.l	Plr1_ZonePtr_l,a5
;				move.l	ZoneT_Roof_l(a5),d0
;				tst.b	Plr1_StoodInTop_b
;				beq.s	.use_bottom
;				move.l	ZoneT_UpperRoof_l(a5),d0
;
;.use_bottom:
;				move.l	Plr1_SnapYOff_l,d1
;				move.l	Plr1_SnapYVel_l,d2
;				sub.l	Plr1_SnapHeight_l,d1
;				sub.l	#10*256,d1
;				cmp.l	d1,d0
;				blt.s	.not_in_roof
;
;				move.l	d0,d1
;				tst.l	d2
;				bge.s	.not_in_roof
;
;				moveq	#0,d2
;
;.not_in_roof:
;				add.l	#10*256,d1
;				add.l	Plr1_SnapHeight_l,d1
;				move.l	d1,Plr1_SnapYOff_l
;				move.l	d2,Plr1_SnapYVel_l
;				rts

Plr2_Fall:
				move.l	Plr2_SnapTYOff_l,d0
				move.l	Plr2_SnapYOff_l,d1
				move.l	Plr2_SnapYVel_l,d2
				cmp.l	d1,d0
				bgt		.above_ground
				beq.s	.on_ground

				st		Plr_Decelerate_b ; // TODO - should this be a separate variable?
; we are under the ground.

				move.l	#0,d2
				sub.l	d1,d0
				cmp.l	#-512,d0
				bge.s	.not_too_big
				move.l	#-512,d0

.not_too_big:
				add.l	d0,d1
				bra		.proceed

.on_ground:
				move.w	plr_FallDamage_w,d3
				sub.w	#100,d3
				ble.s	.skip_damage
				move.l	Plr2_ObjectPtr_l,a4
				add.b	d3,EntT_DamageTaken_b(a4)

.skip_damage:
				move.w	#0,plr_FallDamage_w
				st		Plr_Decelerate_b

				move.w	ADDTOBOBBLE,d3
				move.w	d3,d4
				add.w	Plr2_Bobble_w,d3
				and.w	#8190,d3
				move.w	d3,Plr2_Bobble_w
				add.w	PLR2_clumptime,d4
				move.w	d4,d3
				and.w	#4095,d4
				move.w	d4,PLR2_clumptime
				and.w	#-4096,d3
				beq.s	.skip_footstep_fx

				bsr		PLR2clump

.skip_footstep_fx:
				move.l	#-1024,plr_JumpSpeed_l
				move.l	Plr2_ZonePtr_l,a2
				move.l	ZoneT_Water_l(a2),d0
				cmp.l	d0,d1
				blt.s	.not_in_water

				move.l	#-512,plr_JumpSpeed_l

.not_in_water:
				tst.w	Plr2_Health_w
				ble.s	.no_thrust
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
; need to fall down (possibly).

				tst.w	Plr2_Jetpack_w
				beq.s	.not_flying

				tst.w	Plr2_JetpackFuel_w
				beq.s	.not_flying

				cmp.w	#250,Plr2_JetpackFuel_w
				ble.s	.have_jetpack_fuel

				move.w	#250,Plr2_JetpackFuel_w

.have_jetpack_fuel:
				st		Plr_Decelerate_b
				move.l	#-128,plr_JumpSpeed_l
				move.l	#KeyMap_vb,a5
				moveq	#0,d7
				move.b	jump_key,d7
				tst.b	(a5,d7.w)
				beq.s	.not_flying

				add.l	plr_JumpSpeed_l,d2
				move.w	#0,plr_FallDamage_w
				sub.w	#1,Plr2_JetpackFuel_w
				move.w	#40,d3
				add.w	Plr2_Bobble_w,d3
				and.w	#8190,d3
				move.w	d3,Plr2_Bobble_w

.not_flying:
				move.l	d1,plr_OldHeight_l
				add.l	d2,d1
				cmp.l	d1,d0
				bgt.s	.still_above

				move.w	plr_FallDamage_w,d3
				sub.w	#100,d3
				ble.s	.skip_damage_2

				move.l	Plr2_ObjectPtr_l,a4
				add.b	d3,EntT_DamageTaken_b(a4)

.skip_damage_2:
				move.w	#0,plr_FallDamage_w
				move.l	#0,d2
				bra		.proceed

.still_above:
				add.l	#64,d2
				add.w	#1,plr_FallDamage_w
				move.l	Plr2_ZonePtr_l,a2
				move.l	ZoneT_Water_l(a2),d0
				cmp.l	d0,d1
				blt.s	.proceed

				cmp.l	plr_OldHeight_l,d0
				blt.s	.no_splash_fx

				movem.l	d0-d7/a0-a6,-(a7)
				move.w	#6,Samplenum
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

				move.l	#512,d2

.proceed:
				move.l	Plr2_ZonePtr_l,a2
				move.l	ZoneT_Roof_l(a2),d3
				tst.b	Plr2_StoodInTop_b
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
				move.l	d2,Plr2_SnapYVel_l
				move.l	d1,Plr2_SnapYOff_l
				rts



