
				align 4
targetydiff:	dc.l	0
targdist:		dc.w	0
tempangpos:		dc.w	0
MaxFrame:		dc.w	0
BULTYPE:		dc.w	0
AmmoInMyGun:	dc.w	0

Plr1_Shot:
				tst.w	Plr1_TimeToShoot_w
				beq.s	.can_fire

				move.w	Anim_TempFrames_w,d0
				sub.w	d0,Plr1_TimeToShoot_w
				bge		.no_fire

				move.w	#0,Plr1_TimeToShoot_w

.no_fire:		; early out
				rts

.can_fire:
				moveq	#0,d0
				move.b	Plr1_TmpGunSelected_b,d0
				move.b	d0,tempgun
				move.l	GLF_DatabasePtr_l,a6
				lea		GLFT_ShootDefs_l(a6),a6
				lea		GLFT_BulletDefs_l-GLFT_ShootDefs_l(a6),a5
				lea		(a6,d0.w*8),a6
				move.w	ShootT_BulType_w(a6),d0		; bullet type
				move.w	d0,BULTYPE
				move.l	#Plr1_AmmoCounts_vw,a0
				move.w	(a0,d0.w*2),AmmoInMyGun
				muls	#BulT_SizeOf_l,d0
				add.w	d0,a5
				move.w	BulT_Speed_l+2(a5),BulletSpd

				tst.b	Plr1_TmpFire_b
				beq		.no_fire

				move.w	Plr1_AngPos_w,d0
				move.w	d0,tempangpos
				move.l	#SinCosTable_vw,a0
				lea		(a0,d0.w),a0
				move.w	(a0),tempxdir
				move.w	COSINE_OFS(a0),tempzdir
				move.w	Plr1_XOff_l,tempxoff
				move.w	Plr1_ZOff_l,tempzoff
				move.l	Plr1_YOff_l,tempyoff
				add.l	#10*128,tempyoff
				move.b	Plr1_StoodInTop_b,tempStoodInTop
				move.l	Plr1_ZonePtr_l,tempRoompt
				move.l	#%100011,d7
				move.w	#-1,d0
				move.l	#0,targetydiff
				move.l	#$7fff,d1

				;move.l	Lvl_ZoneAddsPtr_l,a3

				move.l	#Plr1_ObsInLine_vb,a1
				move.l	Lvl_ObjectDataPtr_l,a0
				move.l	#Plr1_ObjectDistances_vw,a2

.find_closest_in_line:
				tst.w	(a0)
				blt		.out_of_line

				cmp.b	#OBJ_TYPE_AUX,ObjT_TypeID_b(a0) ; AUX not targetable
				beq		.not_lined_up

				tst.b	(a1)+
				beq.s	.not_lined_up

				btst	#0,ObjT_SeePlayer_b(a0) ; Line of sight?
				beq.s	.not_lined_up

				tst.w	ObjT_ZoneID_w(a0) ; removed if zone id is negative
				blt.s	.not_lined_up

				move.b	ObjT_TypeID_b(a0),d6
				btst	d6,d7               ; shotflags, but what?
				beq.s	.not_lined_up

				tst.b	EntT_HitPoints_b(a0) ; already dead
				beq.s	.not_lined_up

				move.w	(a0),d5
				move.w	(a2,d5.w*2),d6
				move.w	4(a0),d2
				ext.l	d2
				asl.l	#7,d2
				sub.l	Plr1_YOff_l,d2
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
				move.l	d3,targetydiff
				move.w	d5,d0

.not_lined_up:
				add.w	#ENT_NEXT,a0
				bra		.find_closest_in_line

.out_of_line:
				move.w	d1,targdist
				move.l	targetydiff,d5
				sub.l	Plr1_Height_l,d5
				add.l	#18*256,d5
				move.w	d1,closedist
				move.w	BulletSpd,d2
				asr.w	d2,d1
				tst.w	d1
				bgt.s	.distance_ok

				moveq	#1,d1

.distance_ok:
				divs	d1,d5
				move.w	d5,bulyspd
				move.w	AmmoInMyGun,d2
				move.w	ShootT_BulCount_w(a6),d1
				cmp.w	d1,d2
				bge.s	.okcanshoot

				move.l	Plr1_ObjectPtr_l,a2
				move.w	(a2),d0
				move.l	#ObjRotated_vl,a2
				move.l	(a2,d0.w*8),Aud_NoiseX_w
				move.w	#100,Aud_NoiseVol_w
				move.w	#100,Plr1_NoiseVol_w
				move.w	#12,Aud_SampleNum_w
				clr.b	notifplaying
				move.b	#$fb,IDNUM
				jsr		MakeSomeNoise

				rts

.okcanshoot:
				cmp.b	#PLR_SLAVE,Plr_MultiplayerType_b
				beq.s	.notplr1

				; update the viewport weapon entity timer
				move.l	Plr1_ObjectPtr_l,a2
				move.w	#1,ENT_NEXT_2+EntT_Timer1_w(a2)

.notplr1:
				move.w	ShootT_Delay_w(a6),Plr1_TimeToShoot_w
				move.b	MaxFrame,Plr1_GunFrame_w
				sub.w	d1,d2
				move.l	#Plr1_AmmoCounts_vw,a2
				add.w	BULTYPE,a2
				add.w	BULTYPE,a2
				move.w	d2,(a2)
				move.l	Plr1_ObjectPtr_l,a2
				move.w	(a2),d2
				move.l	#ObjRotated_vl,a2
				move.l	(a2,d2.w*8),Aud_NoiseX_w
				move.w	#100,Plr1_NoiseVol_w
				move.w	#300,Aud_NoiseVol_w
				move.w	ShootT_SFX_w(a6),Aud_SampleNum_w
				move.b	#2,Aud_ChannelPick_b
				clr.b	notifplaying
				movem.l	d0/a0/d5/d6/d7/a6/a4/a5,-(a7)
				move.b	#$fb,IDNUM
				jsr		MakeSomeNoise

				movem.l	(a7)+,d0/a0/d5/d6/d7/a6/a4/a5
				tst.w	d0
				blt		.nothing_to_shoot

				tst.l	BulT_Gravity_l(a5)
				beq.s	.skip_aim
				move.w	Plr1_AimSpeed_l,d2
				move.w	#8,d1
				sub.w	BulletSpd,d1
				asr.w	d1,d2
				move.w	d2,bulyspd

.skip_aim:
				tst.w	BulT_IsHitScan_l+2(a5)
				beq		plr1_FireProjectile

				move.w	ShootT_BulCount_w(a6),d7

.fire_hitscanned_bullets:
				movem.l	a0/a1/d7/d0/a4/a5,-(a7)
				jsr		GetRand

				move.l	Lvl_ObjectPointsPtr_l,a1
				move.w	(a4),d1
				lea		(a1,d1.w*8),a1

				and.w	#$7fff,d0
				move.w	(a1),d1
				sub.w	Plr1_XOff_l,d1
				muls	d1,d1
				move.w	4(a1),d2
				sub.w	Plr1_ZOff_l,d2
				muls	d2,d2
				add.l	d2,d1
				asr.l	#6,d1
				ext.l	d0
				asl.l	#1,d0
				cmp.l	d1,d0
				bgt.s	.hit

				movem.l	(a7)+,a0/a1/d7/d0/a5/a4
				move.l	d0,-(a7)
				bsr		plr1_HitscanFailed

				move.l	(a7)+,d0
				bra.s	.missed

.hit:
				movem.l	(a7)+,a0/a1/d7/d0/a5/a4
				move.l	d0,-(a7)
				bsr		plr1_HitscanSucceded

				move.l	(a7)+,d0

.missed:
				subq	#1,d7
				bgt.s	.fire_hitscanned_bullets

				rts

.nothing_to_shoot:
				move.w	Plr1_AimSpeed_l,d0
				move.w	#8,d1
				sub.w	BulletSpd,d1
				asr.w	d1,d0
				move.w	d0,bulyspd
				tst.w	BulT_IsHitScan_l+2(a5)
				beq		plr1_FireProjectile

				move.w	#0,bulyspd
				move.w	Plr1_XOff_l,oldx
				move.w	Plr1_ZOff_l,oldz
				move.w	Plr1_SinVal_w,d0
				asr.w	#7,d0
				add.w	oldx,d0
				move.w	d0,newx
				move.w	Plr1_CosVal_w,d0
				asr.w	#7,d0
				add.w	oldz,d0
				move.w	d0,newz
				move.l	Plr1_YOff_l,d0
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
				move.l	Plr1_ZonePtr_l,objroom
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
				move.w	#NUM_PLR_SHOT_DATA-1,d1

.findonefree2:
				move.w  ObjT_ZoneID_w(a0),d0
				blt.s	.foundonefree2

				NEXT_OBJ    a0
				dbra	d1,.findonefree2

				rts

.foundonefree2:
				move.l	Lvl_ObjectPointsPtr_l,a1
				move.w	(a0),d2
				move.w	newx,(a1,d2.w*8)
				move.w	newz,4(a1,d2.w*8)
				move.b	#1,ShotT_Status_b(a0)
				move.w	#0,ShotT_Gravity_w(a0)
				move.b	BULTYPE+1,ShotT_Size_b(a0)
				move.b	#0,ShotT_Anim_b(a0)
				move.l	objroom,a1
				move.w	(a1),ObjT_ZoneID_w(a0)
				st		ShotT_Worry_b(a0)
				move.l	wallhitheight,d0
				move.l	d0,ShotT_AccYPos_w(a0)
				asr.l	#7,d0
				move.w	d0,4(a0)
				rts

Plr2_Shot:
				tst.w	Plr2_TimeToShoot_w
				beq.s	.can_fire

				move.w	Anim_TempFrames_w,d0
				sub.w	d0,Plr2_TimeToShoot_w
				bge		.no_fire

				move.w	#0,Plr2_TimeToShoot_w

.no_fire:		; early out
				rts

.can_fire:
				moveq	#0,d0
				move.b	Plr2_TmpGunSelected_b,d0
				move.b	d0,tempgun
				move.l	GLF_DatabasePtr_l,a6
				lea		GLFT_ShootDefs_l(a6),a6
				lea		GLFT_BulletDefs_l-GLFT_ShootDefs_l(a6),a5
				lea		(a6,d0.w*8),a6
				move.w	ShootT_BulType_w(a6),d0		; bullet type
				move.w	d0,BULTYPE
				move.l	#Plr2_AmmoCounts_vw,a0
				move.w	(a0,d0.w*2),AmmoInMyGun
				muls	#BulT_SizeOf_l,d0
				add.w	d0,a5
				move.w	BulT_Speed_l+2(a5),BulletSpd
				tst.b	Plr2_TmpFire_b
				beq		.no_fire

				move.w	Plr2_AngPos_w,d0
				move.w	d0,tempangpos
				move.l	#SinCosTable_vw,a0
				lea		(a0,d0.w),a0
				move.w	(a0),tempxdir
				move.w	COSINE_OFS(a0),tempzdir
				move.w	Plr2_XOff_l,tempxoff
				move.w	Plr2_ZOff_l,tempzoff
				move.l	Plr2_YOff_l,tempyoff
				add.l	#10*128,tempyoff
				move.b	Plr2_StoodInTop_b,tempStoodInTop
				move.l	Plr2_ZonePtr_l,tempRoompt
				move.l	#%10011,d7
				move.w	#-1,d0
				move.l	#0,targetydiff
				move.l	#$7fff,d1

				;move.l	Lvl_ZoneAddsPtr_l,a3

				move.l	#Plr2_ObsInLine_vb,a1
				move.l	Lvl_ObjectDataPtr_l,a0
				move.l	#Plr2_ObjectDistances_vw,a2

.find_closest_in_line:
				tst.w	(a0)
				blt		.out_of_line

				cmp.b	#OBJ_TYPE_AUX,ObjT_TypeID_b(a0)
				beq		.not_lined_up

				tst.b	(a1)+
				beq.s	.not_lined_up

				btst	#1,17(a0)
				beq.s	.not_lined_up

				tst.w	ObjT_ZoneID_w(a0)
				blt.s	.not_lined_up

				move.b	ObjT_TypeID_b(a0),d6
				btst	d6,d7
				beq.s	.not_lined_up

				tst.b	EntT_HitPoints_b(a0)
				beq.s	.not_lined_up

				move.w	(a0),d5
				move.w	(a2,d5.w*2),d6
				move.w	4(a0),d2
				ext.l	d2
				asl.l	#7,d2
				sub.l	Plr2_YOff_l,d2
				move.l	d2,d3
				bge.s	.not_negative

				neg.l	d2

.not_negative:
				; 0xABADCAFE division pogrom
				;divs	#44,d2 ; Hitscanning doesnt work without this. Why 44?

				; Approximate 1/44 as 93/4096
				muls	#93,d2 ; todo - maybe needs to be muls.l
				asr.l	#8,d2
				asr.l	#4,d2

				cmp.w	d6,d2
				bgt.s	.not_lined_up

				cmp.w	d6,d1
				blt.s	.not_lined_up
				move.w	d6,d1
				move.l	a0,a4

; We have a closer enemy lined up.
				move.l	d3,targetydiff
				move.w	d5,d0

.not_lined_up:
				NEXT_OBJ    a0
				bra		.find_closest_in_line

.out_of_line:
				move.w	d1,targdist
				move.l	targetydiff,d5
				sub.l	Plr2_Height_l,d5
				add.l	#18*256,d5
				move.w	d1,closedist
				move.w	BulletSpd,d2
				asr.w	d2,d1
				tst.w	d1
				bgt.s	.distance_ok
				moveq	#1,d1

.distance_ok:
				divs	d1,d5
				move.w	d5,bulyspd

				move.w	AmmoInMyGun,d2
				move.w	ShootT_BulCount_w(a6),d1
				cmp.w	d1,d2
				bge.s	.okcanshoot

				move.l	Plr2_ObjectPtr_l,a2
				move.w	(a2),d0
				move.l	#ObjRotated_vl,a2
				move.l	(a2,d0.w*8),Aud_NoiseX_w
				move.w	#300,Aud_NoiseVol_w
				move.w	#100,Plr2_NoiseVol_w
				move.w	#12,Aud_SampleNum_w
				clr.b	notifplaying
				move.b	#$fb,IDNUM
				jsr		MakeSomeNoise

				rts

.okcanshoot:
				cmp.b	#PLR_SLAVE,Plr_MultiplayerType_b
				bne.s	.notplr2

				; update the viewport weapon entity timer
				move.l	Plr1_ObjectPtr_l,a2
				move.w	#1,ENT_NEXT_2+EntT_Timer1_w(a2)

.notplr2:
				move.w	ShootT_Delay_w(a6),Plr2_TimeToShoot_w
				move.b	MaxFrame,Plr2_GunFrame_w
				sub.w	d1,d2
				move.l	#Plr2_AmmoCounts_vw,a2
				add.w	BULTYPE,a2
				add.w	BULTYPE,a2
				move.w	d2,(a2)
				move.l	Plr2_ObjectPtr_l,a2
				move.w	(a2),d2
				move.l	#ObjRotated_vl,a2
				move.l	(a2,d2.w*8),Aud_NoiseX_w
				move.w	#100,Plr2_NoiseVol_w
				move.w	#300,Aud_NoiseVol_w
				move.w	ShootT_SFX_w(a6),Aud_SampleNum_w
				move.b	#2,Aud_ChannelPick_b
				clr.b	notifplaying

				movem.l	d0/a0/d5/d6/d7/a6/a4/a5,-(a7)
				move.b	#$fb,IDNUM
				jsr		MakeSomeNoise

				movem.l	(a7)+,d0/a0/d5/d6/d7/a6/a4/a5

				tst.w	d0
				blt		.nothing_to_shoot

				tst.l	BulT_Gravity_l(a5)
				beq.s	.skip_aim
				move.w	Plr2_AimSpeed_l,d2
				move.w	#8,d1
				sub.w	BulletSpd,d1
				asr.w	d1,d2
				move.w	d2,bulyspd

.skip_aim:
				tst.w	BulT_IsHitScan_l+2(a5)
				beq		plr2_FireProjectile

				move.w	ShootT_BulCount_w(a6),d7

.fire_hitscanned_bullets:
				movem.l	a0/a1/d7/d0/a4/a5,-(a7)
				jsr		GetRand

				move.l	Lvl_ObjectPointsPtr_l,a1
				move.w	(a4),d1
				lea		(a1,d1.w*8),a1
				and.w	#$7fff,d0
				move.w	(a1),d1
				sub.w	Plr2_XOff_l,d1
				muls	d1,d1
				move.w	4(a1),d2
				sub.w	Plr2_ZOff_l,d2
				muls	d2,d2
				add.l	d2,d1
				asr.l	#6,d1
				ext.l	d0
				asl.l	#1,d0
				cmp.l	d1,d0
				bgt.s	.hit

				movem.l	(a7)+,a0/a1/d7/d0/a5/a4
				move.l	d0,-(a7)
				bsr		plr2_HitscanFailed

				move.l	(a7)+,d0
				bra.s	.missed

.hit:
				movem.l	(a7)+,a0/a1/d7/d0/a5/a4
				move.l	d0,-(a7)
				bsr		plr2_HitscanSucceded

				move.l	(a7)+,d0

.missed:
				subq	#1,d7
				bgt.s	.fire_hitscanned_bullets

				rts

.nothing_to_shoot:
				move.w	Plr2_AimSpeed_l,d0
				move.w	#8,d1
				sub.w	BulletSpd,d1
				asr.w	d1,d0
				move.w	d0,bulyspd
				tst.w	BulT_IsHitScan_l+2(a5)
				beq		plr2_FireProjectile

				move.w	#0,bulyspd
				move.w	Plr2_XOff_l,oldx
				move.w	Plr2_ZOff_l,oldz
				move.w	Plr2_SinVal_w,d0
				asr.w	#7,d0
				add.w	oldx,d0
				move.w	d0,newx
				move.w	Plr2_CosVal_w,d0
				asr.w	#7,d0
				add.w	oldz,d0
				move.w	d0,newz
				move.l	Plr2_YOff_l,d0
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
				move.l	Plr2_ZonePtr_l,objroom
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
				move.w	#NUM_PLR_SHOT_DATA-1,d1

.findonefree2:
				move.w  ObjT_ZoneID_w(a0),d2
				blt.s	.foundonefree2

				NEXT_OBJ    a0
				dbra	d1,.findonefree2

				rts

.foundonefree2:
				move.l	Lvl_ObjectPointsPtr_l,a1
				move.w	(a0),d2
				move.w	newx,(a1,d2.w*8)
				move.w	newz,4(a1,d2.w*8)
				move.b	#1,ShotT_Status_b(a0)
				move.w	#0,ShotT_Gravity_w(a0)
				move.b	BULTYPE+1,ShotT_Size_b(a0)
				move.b	#0,ShotT_Anim_b(a0)
				move.l	objroom,a1
				move.w  (a1),ObjT_ZoneID_w(a0)
				st		ShotT_Worry_b(a0)
				move.l	wallhitheight,d0
				move.l	d0,ShotT_AccYPos_w(a0)
				asr.l	#7,d0
				move.w	d0,4(a0)
				rts

*******************************************************
				align 4
tempyoff:		dc.l	0
BulletSpd:		dc.w	0
tempStoodInTop:	dc.w	0
tempxdir:		dc.w	0
tempzdir:		dc.w	0
tempgun:		dc.w	0
tstfire:		dc.w	0

plr1_FireProjectile:
				move.l	#%100011,d7
				move.b	MaxFrame,Plr1_GunFrame_w
				move.l	Plr1_ObjectPtr_l,a2
				move.w	ShootT_BulCount_w(a6),d5
				move.w	d5,d6
				subq	#1,d6
				asl.w	#7,d6 ; was muls #128
				neg.w	d6
				add.w	tempangpos,d6
				AMOD_A	d6
				bra		firefive

plr2_FireProjectile:
				move.l	#%10011,d7
				move.b	MaxFrame,Plr2_GunFrame_w
				move.l	Plr2_ObjectPtr_l,a2
				move.w	ShootT_BulCount_w(a6),d5
				move.w	d5,d6
				subq	#1,d6
				asl.w	#7,d6 ; was muls #128
				neg.w	d6
				add.w	tempangpos,d6
				AMOD_A	d6

firefive:
				move.l	Plr_ShotDataPtr_l,a0
				move.w	#NUM_PLR_SHOT_DATA-1,d1

.findonefree:
				move.w  ObjT_ZoneID_w(a0),d0
				blt.s	.foundonefree

				NEXT_OBJ    a0
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
				move.b	BULTYPE+1,ShotT_Size_b(a0)
				move.b	BulT_HitDamage_l+3(a5),ShotT_Power_w(a0)

				move.l	Lvl_ObjectPointsPtr_l,a1
				move.w	(a0),d1
				lea		(a1,d1.w*8),a1
				move.w	tempxoff,(a1)
				move.w	tempzoff,4(a1)

				move.l	#SinCosTable_vw,a1
				move.w	(a1,d6.w),d0
				ext.l	d0
				add.w	#COSINE_OFS,a1
				move.w	(a1,d6.w),d2
				ext.l	d2

				add.w	#256,d6
				AMOD_A	d6

				move.w	BulletSpd,d1
				asl.l	d1,d0
				move.l	d0,ShotT_VelocityX_w(a0)
				ext.l	d2
				asl.l	d1,d2
				move.b	#OBJ_TYPE_PROJECTILE,ObjT_TypeID_b(a0)
				move.l	d2,ShotT_VelocityZ_w(a0)
				move.w	bulyspd,ShotT_VelocityY_w(a0)
				move.b	tempStoodInTop,ShotT_InUpperZone_b(a0)
				move.w	#0,ShotT_Lifetime_w(a0)
				move.l	d7,EntT_EnemyFlags_l(a0)
				move.l	tempRoompt,a2
				move.w	(a2),ObjT_ZoneID_w(a0)
				move.l	tempyoff,d0
				add.l	#20*128,d0
				move.l	d0,ShotT_AccYPos_w(a0)
				st		ShotT_Worry_b(a0)
				asr.l	#7,d0
				move.w	d0,4(a0)

				sub.w	#1,d5
				bgt		firefive

				rts

plr1_HitscanSucceded:
; Just blow it up.

				move.l	Plr_ShotDataPtr_l,a0
				move.w	#NUM_PLR_SHOT_DATA-1,d1
.findonefree:
				move.w  ObjT_ZoneID_w(a0),d2
				blt.s	.foundonefree

				NEXT_OBJ    a0
				dbra	d1,.findonefree

				rts

.foundonefree:
				move.b  #OBJ_TYPE_PROJECTILE,ObjT_TypeID_b(a0)
				move.l	Lvl_ObjectPointsPtr_l,a1
				move.w	(a0),d2
				move.l	(a1,d0.w*8),(a1,d2.w*8)
				move.l	4(a1,d0.w*8),4(a1,d2.w*8)
				move.b	#1,ShotT_Status_b(a0)
				move.w	#0,ShotT_Gravity_w(a0)
				move.b	BULTYPE+1,ShotT_Size_b(a0)
				move.b	#0,ShotT_Anim_b(a0)

				move.w	4(a4),d1
				ext.l	d1
				asl.l	#7,d1
				move.l	d1,ShotT_AccYPos_w(a0)
				move.w	ObjT_ZoneID_w(a4),ObjT_ZoneID_w(a0)
				st		ShotT_Worry_b(a0)
				move.w	4(a4),4(a0)

				move.w	BulT_HitDamage_l+2(a5),d0
				add.b	d0,EntT_DamageTaken_b(a4)

				move.w	tempxdir,d1
				ext.l	d1
				asl.l	#3,d1
				swap	d1
				move.w	d1,EntT_ImpactX_w(a4)
				move.w	tempzdir,d1
				ext.l	d1
				asl.l	#3,d1
				swap	d1
				move.w	d1,EntT_ImpactZ_w(a4)

				rts

plr1_HitscanFailed:

				move.w	Plr1_XOff_l,oldx
				move.w	Plr1_ZOff_l,oldz
				move.l	Plr1_YOff_l,d1
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
				move.l	Plr1_ZonePtr_l,objroom
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
				move.w	#NUM_PLR_SHOT_DATA-1,d1
.findonefree2:
				move.w  ObjT_ZoneID_w(a0),d2
				blt.s	.foundonefree2

				NEXT_OBJ    a0
				dbra	d1,.findonefree2

				rts

.foundonefree2:
				move.b  #OBJ_TYPE_PROJECTILE,ObjT_TypeID_b(a0)
				move.l	Lvl_ObjectPointsPtr_l,a1
				move.w	(a0),d2
				move.w	newx,(a1,d2.w*8)
				move.w	newz,4(a1,d2.w*8)
				move.b	#1,ShotT_Status_b(a0)
				move.w	#0,ShotT_Gravity_w(a0)
				move.b	BULTYPE+1,ShotT_Size_b(a0)
				move.b	#0,ShotT_Anim_b(a0)

				move.l	objroom,a1
				move.w  (a1),ObjT_ZoneID_w(a0)
				st		ShotT_Worry_b(a0)
				move.l	newy,d1
				move.l	d1,ShotT_AccYPos_w(a0)
				asr.l	#7,d1
				move.w	d1,4(a0)

				rts


plr2_HitscanSucceded:

; Just blow it up.

				move.l	Plr_ShotDataPtr_l,a0
				move.w	#NUM_PLR_SHOT_DATA-1,d1
.findonefree:
				move.w  ObjT_ZoneID_w(a0),d2
				blt.s	.foundonefree

				NEXT_OBJ    a0
				dbra	d1,.findonefree

				rts

.foundonefree:
				move.b  #OBJ_TYPE_PROJECTILE,ObjT_TypeID_b(a0)
				move.l	Lvl_ObjectPointsPtr_l,a1
				move.w	(a0),d2
				move.l	(a1,d0.w*8),(a1,d2.w*8)
				move.l	4(a1,d0.w*8),4(a1,d2.w*8)
				move.b	#1,ShotT_Status_b(a0)
				move.w	#0,ShotT_Gravity_w(a0)
				move.b	BULTYPE+1,ShotT_Size_b(a0)
				move.b	#0,ShotT_Anim_b(a0)

				move.w	4(a4),d1
				ext.l	d1
				asl.l	#7,d1
				move.l	d1,ShotT_AccYPos_w(a0)
				move.w	ObjT_ZoneID_w(a4),ObjT_ZoneID_w(a0)
				st		ShotT_Worry_b(a0)
				move.w	4(a4),4(a0)

				move.w	BulT_HitDamage_l+2(a5),d0
				add.b	d0,EntT_DamageTaken_b(a4)

				move.w	tempxdir,d1
				ext.l	d1
				asl.l	#3,d1
				swap	d1
				move.w	d1,EntT_ImpactX_w(a4)
				move.w	tempzdir,d1
				ext.l	d1
				asl.l	#3,d1
				swap	d1
				move.w	d1,EntT_ImpactZ_w(a4)

				rts

plr2_HitscanFailed:
				move.w	Plr2_XOff_l,oldx
				move.w	Plr2_ZOff_l,oldz
				move.l	Plr2_YOff_l,d1
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
				move.l	Plr2_ZonePtr_l,objroom
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
				move.w	#NUM_PLR_SHOT_DATA-1,d1

.findonefree2:
				move.w  ObjT_ZoneID_w(a0),d2
				blt.s	.foundonefree2

				NEXT_OBJ    a0
				dbra	d1,.findonefree2

				rts

.foundonefree2:
				move.b  #OBJ_TYPE_PROJECTILE,ObjT_TypeID_b(a0)
				move.l	Lvl_ObjectPointsPtr_l,a1
				move.w	(a0),d2
				move.w	newx,(a1,d2.w*8)
				move.w	newz,4(a1,d2.w*8)
				move.b	#1,ShotT_Status_b(a0)
				move.w	#0,ShotT_Gravity_w(a0)
				move.b	BULTYPE+1,ShotT_Size_b(a0)
				move.b	#0,ShotT_Anim_b(a0)

				move.l	objroom,a1
				move.w	(a1),ObjT_ZoneID_w(a0)
				st		ShotT_Worry_b(a0)
				move.l	newy,d1
				move.l	d1,ShotT_AccYPos_w(a0)
				asr.l	#7,d1
				move.w	d1,4(a0)

				rts
