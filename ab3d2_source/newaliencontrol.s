
				align 4
AlienAnimPtr_l:	dc.l	0

ALIENBRIGHT:	dc.w	0

ItsAnAlien:

				tst.b	AI_NoEnemies_b
				beq.s	.NONASIES

				move.l	#32*256,StepUpVal
				move.l	#32*256,StepDownVal

				move.w	12(a0),EntT_GraphicRoom_w(a0)
				move.w	12(a0),d2
				bge.s	.okalive

				rts

.NONASIES:
				move.w	#-1,12(a0)
				rts

.okalive:

				move.l	Lvl_ZoneAddsPtr_l,a5
				move.l	(a5,d2.w*4),d0
				add.l	Lvl_DataPtr_l,d0
				move.l	d0,objroom

				move.l	d0,a6
				move.b	ZoneT_Echo_b(a6),ALIENECHO

				moveq	#0,d0
				move.l	GLF_DatabasePtr_l,a6
				move.l	a6,a5
				move.b	EntT_Type_b(a0),d0
				add.l	#GLFT_AlienBrights_l,a5
				move.w	(a5,d0.w*2),d1
				neg.w	d1
				move.w	d1,ALIENBRIGHT
				muls	#A_AnimLen,d0
				add.l	#GLFT_AlienAnims_l,a6
				add.l	d0,a6

				move.l	a6,AlienAnimPtr_l

				move.l	GLF_DatabasePtr_l,a1
				move.l	a1,a2
				add.l	#GLFT_AlienShootDefs_l,a2

				lea		GLFT_AlienDefs_l(a1),a1
				moveq	#0,d0
				move.b	EntT_Type_b(a0),d0

				move.l	(a2,d0.w*8),d1
				asl.l	#7,d1
				move.l	d1,SHOTYOFF
				move.w	6(a2,d0.w*8),d1
				neg.w	d1
				asl.w	#2,d1
				move.w	d1,SHOTOFFMULT
				muls	#AlienT_SizeOf_l,d0
				add.w	d0,a1					; ptr to alien stats
				move.w	AlienT_Height_w(a1),d0
				ext.l	d0
				asl.l	#7,d0
				move.l	d0,thingheight
				move.w	AlienT_Auxilliary_w(a1),AUXOBJ
				move.w	(a0),CollId
				move.b	1(a1),AI_VecObj_w
				move.w	AlienT_ReactionTime_w(a1),AI_ReactionTime_w
				move.w	AlienT_DefaultBehaviour_w(a1),AI_DefaultMode_w
				move.w	AlienT_ResponseBehaviour_w(a1),AI_ResponseMode_w
				move.w	AlienT_RetreatBehaviour_w(a1),AI_RetreatMode_w
				move.w	AlienT_FollowupBehaviour_w(a1),AI_FollowupMode_w
				move.w	AlienT_DefaultSpeed_w(a1),AI_ProwlSpeed_w
				move.w	AlienT_ResponseSpeed_w(a1),AI_ResponseSpeed_w
				move.w	AlienT_RetreatSpeed_w(a1),AI_RetreatSpeed_w
				move.w	AlienT_FollowupSpeed_w(a1),AI_FollowupSpeed_w
				move.w	AlienT_FollowupTimeout_w(a1),AI_FollowupTimer_w
				move.w	AlienT_Girth_w(a1),d0
				move.b	diststowall+1(pc,d0.w*4),Obj_AwayFromWall_b
				move.w	diststowall+2(pc,d0.w*4),Obj_ExtLen_w
				jsr		AI_MainRoutine

				rts

ALIENECHO:		dc.w	0

diststowall:
				dc.w	0,40
				dc.w	1,80
				dc.w	2,160

ItsAnObject:
				move.l	GLF_DatabasePtr_l,a1
				lea		GLFT_ObjectDefs(a1),a1
				moveq	#0,d0
				move.b	EntT_Type_b(a0),d0
				muls	#ObjT_SizeOf_l,d0
				add.w	d0,a1					; pointer to obj stats.

				move.l	a1,StatPointer

				move.w	(a1),d0
				cmp.w	#1,d0
				blt		Collectable
				beq		Activatable
				cmp.w	#3,d0
				blt		Destructable
				beq		Decoration

				rts

GUNHELD:

; This is a player gun in his hand.

				move.l	a1,a2
				jsr		ACTANIMOBJ

				rts

Collectable:

				move.w	12(a0),d0
				bge.s	.okinroom
				rts
.okinroom

				tst.b	EntT_WhichAnim_b(a0)
				bne.s	GUNHELD

				move.w	d0,EntT_GraphicRoom_w(a0)

				tst.b	AI_NoEnemies_b
				beq.s	.nolocks
				move.l	EntT_DoorsHeld_w(a0),d1
				or.l	d1,Anim_DoorAndLiftLocks_l
.nolocks:
				tst.b	ShotT_Worry_b(a0)
				bne.s	.worryaboot
				rts
.worryaboot:

				and.b	#$80,ShotT_Worry_b(a0)
				move.l	a1,a2

				move.l	Lvl_ZoneAddsPtr_l,a1
				move.l	(a1,d0.w*4),a1
				add.l	Lvl_DataPtr_l,a1

				tst.w	ObjT_FloorCeiling_w(a2)
				beq.s	.onfloor
				move.l	ZoneT_Roof_l(a1),d0
				tst.b	ShotT_InUpperZone_b(a0)
				beq.s	.okinbotc
				move.l	ZoneT_UpperRoof_l(a1),d0
.okinbotc:

				bra.s	.onceiling

.onfloor
				move.l	ZoneT_Floor_l(a1),d0
				tst.b	ShotT_InUpperZone_b(a0)
				beq.s	.okinbot
				move.l	ZoneT_UpperFloor_l(a1),d0
.okinbot:
.onceiling

				asr.l	#7,d0
				move.w	d0,4(a0)

				bsr		DEFANIMOBJ

				bsr		Plr1_CheckObjectCollide
				tst.b	d0
				beq.s	.NotCollected1

				bsr		Plr1_CollectItem
				move.w	#-1,12(a0)
				clr.b	ShotT_Worry_b(a0)

.NotCollected1

				cmp.b	#PLR_SINGLE,Plr_MultiplayerType_b
				beq.s	.NotCollected2
				bsr		Plr2_CheckObjectCollide
				tst.b	d0
				beq.s	.NotCollected2

				bsr		Plr2_CollectItem
				move.w	#-1,12(a0)
				clr.b	ShotT_Worry_b(a0)

.NotCollected2


				rts

Activatable:

				move.w	12(a0),d0
				bge.s	.okinroom
				rts
.okinroom

				tst.b	EntT_WhichAnim_b(a0)
				bne		ACTIVATED

				move.w	d0,EntT_GraphicRoom_w(a0)
				tst.b	AI_NoEnemies_b
				beq.s	.nolocks
				move.l	EntT_DoorsHeld_w(a0),d1
				or.l	d1,Anim_DoorAndLiftLocks_l
.nolocks
				tst.b	ShotT_Worry_b(a0)
				bne.s	.worryaboot
				rts
.worryaboot:

				and.b	#$80,ShotT_Worry_b(a0)
				move.l	a1,a2

				move.l	Lvl_ZoneAddsPtr_l,a1
				move.l	(a1,d0.w*4),a1
				add.l	Lvl_DataPtr_l,a1

				tst.w	ObjT_FloorCeiling_w(a2)
				beq.s	.onfloor
				move.l	ZoneT_Roof_l(a1),d0
				tst.b	ShotT_InUpperZone_b(a0)
				beq.s	.okinbotc
				move.l	ZoneT_UpperRoof_l(a1),d0
.okinbotc:

				bra.s	.onceiling

.onfloor
				move.l	ZoneT_Floor_l(a1),d0
				tst.b	ShotT_InUpperZone_b(a0)
				beq.s	.okinbot
				move.l	ZoneT_UpperFloor_l(a1),d0
.okinbot:
.onceiling

				asr.l	#7,d0
				move.w	d0,4(a0)

				bsr		DEFANIMOBJ

				bsr		Plr1_CheckObjectCollide
				tst.b	d0
				beq.s	.NotActivated1

				tst.b	Plr1_TmpSpcTap_b
				beq.s	.NotActivated1

; The player has pressed the spacebar
; within range of the object.

				bsr		Plr1_CollectItem


				move.w	#0,EntT_Timer1_w(a0)
				st		EntT_WhichAnim_b(a0)
				move.w	#0,EntT_Timer2_w(a0)
				rts

.NotActivated1:


				cmp.b	#PLR_SINGLE,Plr_MultiplayerType_b
				beq		.NotActivated2
				bsr		Plr2_CheckObjectCollide
				tst.b	d0
				beq.s	.NotActivated2

				tst.b	Plr2_TmpSpcTap_b
				beq.s	.NotActivated2

; The player has pressed the spacebar
; within range of the object.
				bsr		Plr2_CollectItem


				move.w	#0,EntT_Timer1_w(a0)
				st		EntT_WhichAnim_b(a0)
				move.w	#0,EntT_Timer2_w(a0)
				rts

.NotActivated2:

				rts

ACTIVATED:

				move.w	d0,EntT_GraphicRoom_w(a0)
; move.l EntT_DoorsHeld_w(a0),d1
; or.l d1,Anim_DoorAndLiftLocks_l
				tst.b	ShotT_Worry_b(a0)
				bne.s	.worryaboot
				rts
.worryaboot:

				and.b	#$80,ShotT_Worry_b(a0)
				move.l	a1,a2

				move.l	Lvl_ZoneAddsPtr_l,a1
				move.l	(a1,d0.w*4),a1
				add.l	Lvl_DataPtr_l,a1

				tst.w	ObjT_FloorCeiling_w(a2)
				beq.s	.onfloor
				move.l	ZoneT_Roof_l(a1),d0
				tst.b	ShotT_InUpperZone_b(a0)
				beq.s	.okinbotc
				move.l	ZoneT_UpperRoof_l(a1),d0
.okinbotc:

				bra.s	.onceiling

.onfloor
				move.l	ZoneT_Floor_l(a1),d0
				tst.b	ShotT_InUpperZone_b(a0)
				beq.s	.okinbot
				move.l	ZoneT_UpperFloor_l(a1),d0
.okinbot:
.onceiling

				asr.l	#7,d0
				move.w	d0,4(a0)

				bsr		ACTANIMOBJ

				move.w	Anim_TempFrames_w,d0
				add.w	d0,EntT_Timer2_w(a0)
				move.w	ObjT_ActiveTimeout_w(a2),d0
				blt.s	.nottimeout

				cmp.w	EntT_Timer2_w(a0),d0
				ble.s	.DEACTIVATE

.nottimeout:

				bsr		Plr1_CheckObjectCollide
				tst.b	d0
				beq.s	.NotDeactivated1

				tst.b	Plr1_TmpSpcTap_b
				beq.s	.NotDeactivated1

; The player has pressed the spacebar
; within range of the object.

.DEACTIVATE:

				move.w	#0,EntT_Timer1_w(a0)
				clr.b	EntT_WhichAnim_b(a0)
				rts

.NotDeactivated1:

				cmp.b	#PLR_SINGLE,Plr_MultiplayerType_b
				beq.s	.NotDeactivated2

				bsr		Plr2_CheckObjectCollide
				tst.b	d0
				beq.s	.NotDeactivated2

				tst.b	Plr2_TmpSpcTap_b
				beq.s	.NotDeactivated2

; The player has pressed the spacebar
; within range of the object.

				move.w	#0,EntT_Timer1_w(a0)
				clr.b	EntT_WhichAnim_b(a0)
				rts

.NotDeactivated2:

				rts

Destructable:

				move.l	GLF_DatabasePtr_l,a3
				add.l	#GLFT_ObjectDefs,a3
				moveq	#0,d0
				move.b	EntT_Type_b(a0),d0
				muls	#ObjT_SizeOf_l,d0
				add.l	d0,a3

				moveq	#0,d0
				move.b	EntT_DamageTaken_b(a0),d0
				cmp.w	ObjT_HitPoints_w(a3),d0
				blt		StillHere

				tst.b	EntT_NumLives_b(a0)
				beq.s	.alreadydead

				cmp.b	#PLR_SINGLE,Plr_MultiplayerType_b
				bne.s	.notext

				move.w	EntT_DisplayText_w(a0),d0
				blt.s	.notext

				muls	#160,d0
				add.l	Lvl_DataPtr_l,d0
				jsr		SENDMESSAGE

.notext:

				move.w	#0,EntT_Timer1_w(a0)

.alreadydead

				move.b	#0,EntT_NumLives_b(a0)

				move.w	12(a0),d0
				bge.s	.okinroom
				rts
.okinroom

				tst.b	ShotT_Worry_b(a0)
				bne.s	.worryaboot
				rts
.worryaboot:

				move.l	a1,a2

				move.l	Lvl_ZoneAddsPtr_l,a1
				move.l	(a1,d0.w*4),a1
				add.l	Lvl_DataPtr_l,a1

				tst.w	ObjT_FloorCeiling_w(a2)
				beq.s	.onfloor
				move.l	ZoneT_Roof_l(a1),d0
				tst.b	ShotT_InUpperZone_b(a0)
				beq.s	.okinbotc
				move.l	ZoneT_UpperRoof_l(a1),d0
.okinbotc:

				bra.s	.onceiling

.onfloor
				move.l	ZoneT_Floor_l(a1),d0
				tst.b	ShotT_InUpperZone_b(a0)
				beq.s	.okinbot
				move.l	ZoneT_UpperFloor_l(a1),d0
.okinbot:
.onceiling

				asr.l	#7,d0
				move.w	d0,4(a0)

				bsr		ACTANIMOBJ

				rts

StillHere:
				move.w	12(a0),d0
				bge.s	.okinroom
				rts
.okinroom
				move.b	#1,EntT_NumLives_b(a0)

				tst.b	AI_NoEnemies_b
				beq.s	.nolocks
				move.l	EntT_DoorsHeld_w(a0),d1
				or.l	d1,Anim_DoorAndLiftLocks_l
.nolocks

				tst.b	ShotT_Worry_b(a0)
				bne.s	.worryaboot
				rts
.worryaboot:

				movem.l	d0-d7/a0-a6,-(a7)

				move.w	12(a0),d2
				move.l	Lvl_ZoneAddsPtr_l,a5
				move.l	(a5,d2.w*4),d0
				add.l	Lvl_DataPtr_l,d0
				move.l	d0,objroom

				move.w	(a0),d0
				move.l	Lvl_ObjectPointsPtr_l,a1
				move.w	(a1,d0.w*8),newx
				move.w	4(a1,d0.w*8),newz

				jsr		AI_LookForPlayer1
				movem.l	(a7)+,d0-d7/a0-a6

Decoration

				move.w	12(a0),d0
				bge.s	.okinroom
				rts
.okinroom

				tst.b	ShotT_Worry_b(a0)
				bne.s	.worryaboot
				rts
.worryaboot:


intodeco:
				move.l	a1,a2

				move.l	Lvl_ZoneAddsPtr_l,a1
				move.l	(a1,d0.w*4),a1
				add.l	Lvl_DataPtr_l,a1

				tst.w	ObjT_FloorCeiling_w(a2)
				beq.s	.onfloor
				move.l	ZoneT_Roof_l(a1),d0
				tst.b	ShotT_InUpperZone_b(a0)
				beq.s	.okinbotc
				move.l	ZoneT_UpperRoof_l(a1),d0
.okinbotc:

				bra.s	.onceiling

.onfloor
				move.l	ZoneT_Floor_l(a1),d0
				tst.b	ShotT_InUpperZone_b(a0)
				beq.s	.okinbot
				move.l	ZoneT_UpperFloor_l(a1),d0
.okinbot:
.onceiling

				asr.l	#7,d0
				move.w	d0,4(a0)

				bsr		DEFANIMOBJ

				rts

Plr1_CollectItem:
				cmp.b	#PLR_SINGLE,Plr_MultiplayerType_b
				bne.s	.nodeftext

				move.w	EntT_DisplayText_w(a0),d0
				blt.s	.notext

				muls	#160,d0
				add.l	Lvl_DataPtr_l,d0
				jsr		SENDMESSAGE

				bra		.nodeftext

.notext:

				cmp.b	#PLR_SLAVE,Plr_MultiplayerType_b
				beq.s	.nodeftext

				moveq	#0,d2
				move.b	EntT_Type_b(a0),d2
				move.l	GLF_DatabasePtr_l,a4
				add.l	#GLFT_ObjectNames_l,a4
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

.nodeftext:

				move.l	GLF_DatabasePtr_l,a2
				lea		GLFT_AmmoGive_l(a2),a3
				add.l	#GLFT_GunGive_l,a2
				moveq	#0,d0
				move.b	EntT_Type_b(a0),d0
				move.w	d0,d1
				muls	#AmmoGiveLen,d0
				muls	#GunGiveLen,d1
				add.w	d1,a2
				add.w	d0,a3

; Check if player has max of all ammo types:

;				bsr		CHECKPLAYERGOT
;				tst.b	d0
;				beq		.no_collect

				move.w	#21,d0
				move.l	#Plr1_Health_w,a1
.add_ammo:
				move.w	(a3)+,d1
				add.w	d1,(a1)+
				dbra	d0,.add_ammo

				move.w	#11,d0
				move.l	#Plr1_Shield_w,a1
.add_weapons:
				move.w	(a2)+,d1
				or.w	d1,(a1)+
				dbra	d0,.add_weapons

				move.l	GLF_DatabasePtr_l,a3
				add.l	#GLFT_ObjectDefs,a3
				moveq	#0,d0
				move.b	EntT_Type_b(a0),d0
				muls	#ObjT_SizeOf_l,d0
				add.l	d0,a3
				move.w	ObjT_SFX_w(a3),d0
				blt.s	.nosoundmake

				movem.l	d0-d7/a0-a6,-(a7)
				move.w	d0,Samplenum
				clr.b	notifplaying
				move.w	(a0),IDNUM
				move.w	#80,Noisevol
				move.l	#ObjRotated_vl,a1
				move.w	(a0),d0
				lea		(a1,d0.w*8),a1
				move.l	(a1),Noisex
				jsr		MakeSomeNoise
				movem.l	(a7)+,d0-d7/a0-a6

.nosoundmake:
.no_collect:
				rts

Plr2_CollectItem:
				move.l	GLF_DatabasePtr_l,a2
				lea		GLFT_AmmoGive_l(a2),a3
				add.l	#GLFT_GunGive_l,a2
				moveq	#0,d0
				move.b	EntT_Type_b(a0),d0
				move.w	d0,d1
				muls	#AmmoGiveLen,d0
				muls	#GunGiveLen,d1
				add.w	d1,a2
				add.w	d0,a3

; Check if player has max of all ammo types:
;				bsr		CHECKPLAYERGOT
;				tst.b	d0
;				beq		.no_collect

				move.w	#21,d0
				move.l	#Plr2_Health_w,a1
.add_ammo:
				move.w	(a3)+,d1
				add.w	d1,(a1)+
				dbra	d0,.add_ammo

				move.w	#11,d0
				move.l	#Plr2_Shield_w,a1 ; Armour!
.add_weapons:
				move.w	(a2)+,d1
				or.w	d1,(a1)+
				dbra	d0,.add_weapons

				move.l	GLF_DatabasePtr_l,a3
				add.l	#GLFT_ObjectDefs,a3
				moveq	#0,d0
				move.b	EntT_Type_b(a0),d0
				muls	#ObjT_SizeOf_l,d0
				add.l	d0,a3

				move.w	ObjT_SFX_w(a3),d0
				blt.s	.nosoundmake

				movem.l	d0-d7/a0-a6,-(a7)
				move.w	d0,Samplenum
				clr.b	notifplaying
				move.w	(a0),IDNUM
				move.w	#80,Noisevol
				move.l	#ObjRotated_vl,a1
				move.w	(a0),d0
				lea		(a1,d0.w*8),a1
				move.l	(a1),Noisex
				move.b	#0,PlayEcho
				jsr		MakeSomeNoise
				movem.l	(a7)+,d0-d7/a0-a6

.nosoundmake:
				move.w	#-1,12(a0)
				clr.b	ShotT_Worry_b(a0)

.no_collect:
				rts

CHECKPLAYERGOT:
				move.b	#1,d0
				rts

Plr1_CheckObjectCollide:
				move.l	StatPointer,a2
				move.b	Plr1_StoodInTop_b,d0
				move.b	ShotT_InUpperZone_b(a0),d1
				eor.b	d0,d1
				bne		.NotSameZone

				move.w	Plr1_XOff_l,oldx
				move.w	Plr1_ZOff_l,oldz
				move.w	Plr1_Zone_w,d7

				cmp.w	12(a0),d7
				bne		.NotSameZone

				move.l	Plr1_YOff_l,d7
				move.l	Plr1_Height_l,d6
				asr.l	#1,d6
				add.l	d6,d7
				asr.l	#7,d7
				sub.w	4(a0),d7
				bgt.s	.okpos
				neg.w	d7
.okpos

				cmp.w	ObjT_CollideHeight_w(a2),d7
				bgt		.NotSameZone

				move.w	(a0),d0
				move.l	Lvl_ObjectPointsPtr_l,a1
				move.w	(a1,d0.w*8),newx
				move.w	4(a1,d0.w*8),newz
				move.w	ObjT_CollideRadius_w(a2),d2
				muls	d2,d2
				jsr		CheckHit
				move.b	hitwall,d0
				rts
.NotSameZone
				moveq	#0,d0
				rts

Plr2_CheckObjectCollide:
				move.l	StatPointer,a2
				move.b	Plr2_StoodInTop_b,d0
				move.b	ShotT_InUpperZone_b(a0),d1
				eor.b	d0,d1
				bne		.NotSameZone

				move.w	Plr2_XOff_l,oldx
				move.w	Plr2_ZOff_l,oldz
				move.w	Plr2_Zone_w,d7

				cmp.w	12(a0),d7
				bne		.NotSameZone

				move.l	Plr2_YOff_l,d7
				move.l	Plr2_Height_l,d6
				asr.l	#1,d6
				add.l	d6,d7
				asr.l	#7,d7
				sub.w	4(a0),d7
				bgt.s	.okpos
				neg.w	d7
.okpos

				cmp.w	ObjT_CollideHeight_w(a2),d7
				bgt		.NotSameZone

				move.w	(a0),d0
				move.l	Lvl_ObjectPointsPtr_l,a1
				move.w	(a1,d0.w*8),newx
				move.w	4(a1,d0.w*8),newz
				move.w	ObjT_CollideRadius_w(a2),d2
				muls	d2,d2
				jsr		CheckHit
				move.b	hitwall,d0
				rts
.NotSameZone
				moveq	#0,d0
				rts

StatPointer:	dc.l	0

DEFANIMOBJ:

				move.l	GLF_DatabasePtr_l,a3
				lea		GLFT_ObjectDefAnims_l(a3),a3
				moveq	#0,d0
				move.b	EntT_Type_b(a0),d0
				muls	#O_AnimSize,d0
				add.w	d0,a3
				move.w	EntT_Timer1_w(a0),d0

				move.w	d0,d1
				add.w	d0,d0
				asl.w	#2,d1
				add.w	d1,d0					;*6

				cmp.w	#1,ObjT_GFXType_w(a2)
				blt.s	.bitmap
				beq.s	.vector

.glare:
				move.l	#0,8(a0)
				move.b	(a3,d0.w),d1
				ext.w	d1
				neg.w	d1
				move.w	d1,8(a0)
				move.b	1(a3,d0.w),11(a0)
				move.w	2(a3,d0.w),6(a0)

				move.b	4(a3,d0.w),d1
				ext.w	d1
				add.w	d1,d1
				add.w	d1,4(a0)

				moveq	#0,d1
				move.b	5(a3,d0.w),d1
				move.w	d1,EntT_Timer1_w(a0)
				rts

.vector:

				move.l	#0,8(a0)
				move.b	(a3,d0.w),9(a0)
				move.b	1(a3,d0.w),11(a0)

				move.w	#$ffff,6(a0)
				move.b	4(a3,d0.w),d1
				ext.w	d1
				add.w	d1,d1
				add.w	d1,4(a0)
				move.w	2(a3,d0.w),d1
				add.w	d1,EntT_CurrentAngle_w(a0)

				moveq	#0,d1
				move.b	5(a3,d0.w),d1
				move.w	d1,EntT_Timer1_w(a0)

				rts

.bitmap:

				move.l	#0,8(a0)
				move.b	(a3,d0.w),9(a0)
				move.b	1(a3,d0.w),11(a0)
				move.w	2(a3,d0.w),6(a0)
				move.b	4(a3,d0.w),d1
				ext.w	d1
				add.w	d1,d1
				add.w	d1,4(a0)

				moveq	#0,d1
				move.b	5(a3,d0.w),d1
				move.w	d1,EntT_Timer1_w(a0)

				rts

ACTANIMOBJ:

				move.l	GLF_DatabasePtr_l,a3
				lea		GLFT_ObjectActAnims_l(a3),a3
				moveq	#0,d0
				move.b	EntT_Type_b(a0),d0
				muls	#O_AnimSize,d0
				add.w	d0,a3
				move.w	EntT_Timer1_w(a0),d0

				move.w	d0,d1
				add.w	d0,d0
				asl.w	#2,d1
				add.w	d1,d0					;*6

				cmp.w	#1,ObjT_GFXType_w(a2)
				blt.s	.bitmap
				beq.s	.vector

.glare:
				move.l	#0,8(a0)
				move.b	(a3,d0.w),d1
				ext.w	d1
				neg.w	d1
				move.w	d1,8(a0)
				move.b	1(a3,d0.w),11(a0)
				move.w	2(a3,d0.w),6(a0)

				move.b	4(a3,d0.w),d1
				ext.w	d1
				add.w	d1,d1
				add.w	d1,4(a0)

				moveq	#0,d1
				move.b	5(a3,d0.w),d1
				move.w	d1,EntT_Timer1_w(a0)

				rts

.vector:
				move.l	#0,8(a0)
				move.b	(a3,d0.w),9(a0)
				move.b	1(a3,d0.w),11(a0)
				move.w	#$ffff,6(a0)
				move.b	4(a3,d0.w),d1
				ext.w	d1
				add.w	d1,d1
				add.w	d1,4(a0)

				move.w	2(a3,d0.w),d1
				add.w	d1,EntT_CurrentAngle_w(a0)

				moveq	#0,d1
				move.b	5(a3,d0.w),d1
				move.w	d1,EntT_Timer1_w(a0)

				rts

.bitmap:

				move.l	#0,8(a0)
				move.b	(a3,d0.w),9(a0)
				move.b	1(a3,d0.w),11(a0)
				move.w	2(a3,d0.w),6(a0)
				move.b	4(a3,d0.w),d1
				ext.w	d1
				add.w	d1,d1
				add.w	d1,4(a0)

				moveq	#0,d1
				move.b	5(a3,d0.w),d1
				move.w	d1,EntT_Timer1_w(a0)

				rts


THISPLRxoff:	dc.w	0
THISPLRzoff:	dc.w	0

ViewpointToDraw:
				move.w	EntT_CurrentAngle_w(a0),d3
				sub.w	angpos,d3

				and.w	#8190,d3
				move.l	#SinCosTable_vw,a2
				move.w	(a2,d3.w),d2
				adda.w	#2048,a2
				move.w	(a2,d3.w),d3

				ext.l	d2
				ext.l	d3
				move.l	d3,d0
				move.l	d2,d4
				neg.l	d0

				tst.l	d0
				bgt.s	FacingTowardsPlayer
FAP:
				tst.l	d4
				bgt.s	FAPR
				cmp.l	d4,d0
				bgt.s	LEFTFRAME
				bra.s	AWAYFRAME

FAPR:
				neg.l	d0
				cmp.l	d0,d4
				bgt.s	RIGHTFRAME
				bra.s	AWAYFRAME

FacingTowardsPlayer

				tst.l	d4
				bgt.s	FTPR
				neg.l	d4
				cmp.l	d0,d4
				bgt.s	LEFTFRAME
				bra.s	TOWARDSFRAME

FTPR:
				cmp.l	d0,d4
				bgt.s	RIGHTFRAME
TOWARDSFRAME:
				move.l	#0,d0
				rts
RIGHTFRAME:
				move.l	#1,d0
				rts
LEFTFRAME:
				move.l	#3,d0
				rts
AWAYFRAME:
				move.l	#2,d0
				rts

deadframe:		dc.l	0
screamsound:	dc.w	0
nasheight:		dc.w	0
tempcos:		dc.w	0
tempsin:		dc.w	0
tempx:			dc.w	0
tempz:			dc.w	0

RunAround:
				movem.l	d0/d1/d2/d3/a0/a1,-(a7)

				move.w	oldx,d0
				sub.w	newx,d0					; dx
				asr.w	#1,d0
				move.w	oldz,d1
				sub.w	newz,d1					; dz
				asr.w	#1,d1

				move.l	Lvl_ObjectPointsPtr_l,a1
				move.w	(a0),d2
				lea		(a1,d2.w*8),a1
				move.w	(a1),d2
				sub.w	tempx,d2
				move.w	4(a1),d3
				sub.w	tempz,d3

				muls	tempcos,d2
				muls	tempsin,d3
				sub.l	d3,d2

				blt.s	headleft
				neg.w	d0
				neg.w	d1
headleft:
				sub.w	d1,newx
				add.w	d0,newz

				movem.l	(a7)+,d0/d1/d2/d3/a0/a1
				rts

bbbb:			dc.w	0
tsx:			dc.w	0
tsz:			dc.w	0
fsx:			dc.w	0
fsz:			dc.w	0

SHOOTPLAYER1:
				move.w	oldx,tsx
				move.w	oldz,tsz
				move.w	newx,fsx
				move.w	newz,fsz

				move.w	Plr1_TmpXOff_l,newx
				move.w	Plr1_TmpZOff_l,newz
				move.w	(a1),oldx
				move.w	4(a1),oldz

				move.w	newx,d1
				sub.w	oldx,d1
				move.w	newz,d2
				sub.w	oldz,d2
				jsr		GetRand
				asr.w	#4,d0
				muls	d0,d1
				muls	d0,d2
				swap	d1
				swap	d2
				add.w	d1,newz
				sub.w	d2,newx

				move.l	Plr1_TmpYOff_l,d1
				add.l	#15*128,d1
				asr.l	#7,d1
				move.w	d1,d2
				muls	d0,d2
				swap	d2
				add.w	d2,d1
				ext.l	d1
				asl.l	#7,d1
				move.l	d1,newy
				move.w	4(a0),d1
				ext.l	d1
				asl.l	#7,d1
				move.l	d1,oldy

				move.b	ShotT_InUpperZone_b(a0),StoodInTop

				st		exitfirst
				move.w	#0,Obj_ExtLen_w
				move.b	#$ff,Obj_AwayFromWall_b
				move.w	#%0000010000000000,wallflags
				move.l	#0,StepUpVal
				move.l	#$1000000,StepDownVal
				move.l	#0,thingheight
				move.l	objroom,-(a7)
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
				move.l	objroom,backroom

				movem.l	(a7)+,d0-d7/a0-a6
				move.l	(a7)+,objroom

				move.l	Plr_ShotDataPtr_l,a0
				move.w	#19,d1

.findonefree2:
				move.w	12(a0),d2
				blt.s	.foundonefree2
				adda.w	#64,a0
				dbra	d1,.findonefree2

				move.w	tsx,oldx
				move.w	tsz,oldz
				move.w	fsx,newx
				move.w	fsz,newz

				rts

.foundonefree2:
				move.l	Lvl_ObjectPointsPtr_l,a1
				move.w	(a0),d2
				move.w	newx,(a1,d2.w*8)
				move.w	newz,4(a1,d2.w*8)
				move.b	#1,ShotT_Status_b(a0)
				move.w	#0,ShotT_Gravity_w(a0)
				move.b	#0,ShotT_Size_b(a0)
				move.b	#0,ShotT_Anim_b(a0)

				move.l	backroom,a1
				move.w	(a1),12(a0)
				st		ShotT_Worry_b(a0)
				move.l	wallhitheight,d0
				move.l	d0,ShotT_AccYPos_w(a0)
				asr.l	#7,d0
				move.w	d0,4(a0)

				move.w	tsx,oldx
				move.w	tsz,oldz
				move.w	fsx,newx
				move.w	fsz,newz


				rts

futurex:		dc.w	0
futurez:		dc.w	0

FireAtPlayer1:

				move.l	Lvl_ObjectPointsPtr_l,a1
				move.w	(a0),d1
				lea		(a1,d1.w*8),a1

				move.l	NastyShotDataPtr_l,a5
				move.w	#19,d1
.findonefree
				move.w	12(a5),d0
				blt.s	.foundonefree
				adda.w	#64,a5
				dbra	d1,.findonefree

				bra		.cantshoot

.foundonefree:
				move.b	#2,16(a5)

				move.l	#ObjRotated_vl,a6
				move.w	(a0),d0
				lea		(a6,d0.w*8),a6

				move.l	(a6),Noisex
				move.w	#100,Noisevol
				move.b	#1,chanpick
				clr.b	notifplaying
				move.b	SHOTTYPE,d0
				move.w	#0,ShotT_Lifetime_w(a5)
				move.b	d0,ShotT_Size_b(a5)
				move.b	ALIENECHO,PlayEcho
				move.b	SHOTPOWER,ShotT_Power_w(a5)
				movem.l	a5/a1/a0,-(a7)
				move.w	(a0),IDNUM
				jsr		MakeSomeNoise
				movem.l	(a7)+,a5/a1/a0

				move.l	Lvl_ObjectPointsPtr_l,a2
				move.w	(a5),d1
				lea		(a2,d1.w*8),a2
				move.w	(a1),oldx
				move.w	4(a1),oldz
				move.w	Plr1_XOff_l,newx
				move.w	Plr1_ZOff_l,newz

				jsr		CalcDist
				move.w	XDiff_w,d6
				muls	distaway,d6
				divs	SHOTSPEED,d6
				asr.w	#4,d6
				add.w	d6,newx
				move.w	ZDiff_w,d6
				muls	distaway,d6
				divs	SHOTSPEED,d6
				asr.w	#4,d6
				add.w	d6,newz
				move.w	newx,futurex
				move.w	newz,futurez

				move.w	SHOTSPEED,speed
				move.w	#0,Range
				jsr		HeadTowards

				move.w	newx,d0
				sub.w	oldx,d0
				move.w	newz,d1
				sub.w	oldz,d1
				move.w	SHOTOFFMULT,d2
				beq.s	.nooffset

				muls	d2,d0
				muls	d2,d1
				asr.l	#8,d0
				asr.l	#8,d1
				add.w	d1,oldx
				sub.w	d0,oldz
				move.w	futurex,newx
				move.w	futurez,newz
				jsr		HeadTowards

.nooffset:
				move.w	newx,d0
				move.w	d0,(a2)
				sub.w	oldx,d0
				move.w	d0,ShotT_VelocityX_w(a5)
				move.w	newz,d0
				move.w	d0,4(a2)
				sub.w	oldz,d0
				move.w	d0,ShotT_VelocityZ_w(a5)

				move.l	#%110010,EntT_EnemyFlags_l(a5)
				move.w	12(a0),12(a5)
				move.w	4(a0),d0
				move.w	d0,4(a5)
				ext.l	d0
				asl.l	#7,d0
				add.l	SHOTYOFF,d0
				move.l	d0,ShotT_AccYPos_w(a5)
				move.b	SHOTINTOP,ShotT_InUpperZone_b(a5)
				move.l	Plr1_ObjectPtr_l,a2
				move.w	4(a2),d1
				sub.w	#20,d1
				ext.l	d1
				asl.l	#7,d1
				sub.l	d0,d1
				add.l	d1,d1
				move.w	distaway,d0

				move.w	SHOTSHIFT,d2
				asr.w	d2,d0
				tst.w	d0
				bgt.s	.okokokok
				moveq	#1,d0
.okokokok

				divs	d0,d1
				move.w	d1,ShotT_VelocityY_w(a5)
				st		ShotT_Worry_b(a5)

; FIXME: this is causing Enforcer hits. It looks like the places that put a
; value into Plr_GunDataPtr_l are all commented out. On the other hand, most other places
; writing to ShotT_Gravity_w just write a 0. Maybe no alien weapon has gravity applied?
; similar with ShotT_Flags_w
;				move.l	Plr_GunDataPtr_l,a6
;				moveq	#0,d0
;				move.b	SHOTTYPE,d0
;				asl.w	#5,d0
;				add.w	d0,a6
;				move.w	16(a6),ShotT_Gravity_w(a5)
;				move.w	18(a6),ShotT_Flags_w(a5)


; move.w 20(a6),d0
; add.w d0,ShotT_VelocityY_w(a5)

.cantshoot
				rts


SHOOTPLAYER2
				move.w	oldx,tsx
				move.w	oldz,tsz
				move.w	newx,fsx
				move.w	oldx,fsz

				move.w	Plr2_TmpXOff_l,newx
				move.w	Plr2_TmpZOff_l,newz
				move.w	(a1),oldx
				move.w	4(a1),oldz

				move.w	newx,d1
				sub.w	oldx,d1
				move.w	newz,d2
				sub.w	oldz,d2
				jsr		GetRand
				asr.w	#4,d0
				muls	d0,d1
				muls	d0,d2
				swap	d1
				swap	d2
				add.w	d1,newz
				sub.w	d2,newx

				move.l	Plr2_TmpYOff_l,d1
				add.l	#15*128,d1
				asr.l	#7,d1
				move.w	d1,d2
				muls	d0,d2
				swap	d2
				add.w	d2,d1
				ext.l	d1
				asl.l	#7,d1
				move.l	d1,newy
				move.w	4(a0),d1
				ext.l	d1
				asl.l	#7,d1
				move.l	d1,oldy
				move.b	ShotT_InUpperZone_b(a0),StoodInTop

				st		exitfirst
				move.w	#0,Obj_ExtLen_w
				move.b	#$ff,Obj_AwayFromWall_b
				move.w	#%0000010000000000,wallflags
				move.l	#0,StepUpVal
				move.l	#$1000000,StepDownVal
				move.l	#0,thingheight
				move.l	objroom,-(a7)
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

				move.l	objroom,backroom

				movem.l	(a7)+,d0-d7/a0-a6
				move.l	(a7)+,objroom

				move.l	NastyShotDataPtr_l,a0
				move.w	#19,d1
.findonefree2
				move.w	12(a0),d2
				blt.s	.foundonefree2
				adda.w	#64,a0
				dbra	d1,.findonefree2

				move.w	tsx,oldx
				move.w	tsz,oldz
				move.w	fsx,newx
				move.w	fsz,oldx

				rts

.foundonefree2:

				move.l	Lvl_ObjectPointsPtr_l,a1
				move.w	(a0),d2
				move.w	newx,(a1,d2.w*8)
				move.w	newz,4(a1,d2.w*8)
				move.b	#1,ShotT_Status_b(a0)
				move.w	#0,ShotT_Gravity_w(a0)
				move.b	#0,ShotT_Size_b(a0)
				move.b	#0,ShotT_Anim_b(a0)

				move.l	backroom,a1
				move.w	(a1),12(a0)
				st		ShotT_Worry_b(a0)
				move.l	wallhitheight,d0
				move.l	d0,ShotT_AccYPos_w(a0)
				asr.l	#7,d0
				move.w	d0,4(a0)

				move.w	tsx,oldx
				move.w	tsz,oldz
				move.w	fsx,newx
				move.w	fsz,oldx

				rts

FireAtPlayer2:
				move.l	NastyShotDataPtr_l,a5
				move.w	#19,d1
.findonefree
				move.w	12(a5),d0
				blt.s	.foundonefree
				adda.w	#64,a5
				dbra	d1,.findonefree

				bra		.cantshoot

.foundonefree:

				move.b	#2,16(a5)

				move.l	#ObjRotated_vl,a6
				move.w	(a0),d0
				lea		(a6,d0.w*8),a6

				move.l	(a6),Noisex
				move.w	#100,Noisevol
				move.b	#1,chanpick
				clr.b	notifplaying
				move.b	SHOTPOWER,d0
				move.w	#0,ShotT_Lifetime_w(a5)
				move.b	d0,ShotT_Size_b(a5)
				move.b	SHOTPOWER,ShotT_Power_w(a5)
				movem.l	a5/a1/a0,-(a7)
				move.w	(a0),IDNUM
				move.b	ALIENECHO,PlayEcho
				jsr		MakeSomeNoise
				movem.l	(a7)+,a5/a1/a0

				move.l	Lvl_ObjectPointsPtr_l,a2
				move.w	(a5),d1
				lea		(a2,d1.w*8),a2
				move.w	(a1),oldx
				move.w	4(a1),oldz
				move.w	Plr2_XOff_l,newx
				move.w	Plr2_ZOff_l,newz
				move.w	SHOTSPEED,speed
				move.w	#0,Range
				jsr		HeadTowards

				move.w	newx,d0
				sub.w	oldx,d0
				move.w	newz,d1
				sub.w	oldz,d1
				move.w	SHOTOFFMULT,d2
				beq.s	.nooffset

				muls	d2,d0
				muls	d2,d1
				asr.l	#8,d0
				asr.l	#8,d1
				add.w	d1,oldx
				sub.w	d0,oldz
				move.w	Plr2_XOff_l,newx
				move.w	Plr2_ZOff_l,newz
				jsr		HeadTowards

.nooffset:
				move.w	newx,d0
				move.w	d0,(a2)
				sub.w	oldx,d0
				move.w	d0,ShotT_VelocityX_w(a5)
				move.w	newz,d0
				move.w	d0,4(a2)
				sub.w	oldz,d0
				move.w	d0,ShotT_VelocityZ_w(a5)

				move.l	#%110010,EntT_EnemyFlags_l(a5)
				move.w	12(a0),12(a5)
				move.w	4(a0),d0
				move.w	d0,4(a5)
				ext.l	d0
				asl.l	#7,d0
				add.l	SHOTYOFF,d0
				move.l	d0,ShotT_AccYPos_w(a5)
				move.b	SHOTINTOP,ShotT_InUpperZone_b(a5)
				move.l	Plr2_ObjectPtr_l,a2
				move.w	4(a2),d1
				sub.w	#20,d1
				ext.l	d1
				asl.l	#7,d1
				sub.l	d0,d1
				add.l	d1,d1
				move.w	distaway,d0
				move.w	SHOTSHIFT,d2
				asr.w	d2,d0
				tst.w	d0
				bgt.s	.okokokok
				moveq	#1,d0
.okokokok
				divs	d0,d1
				move.w	d1,ShotT_VelocityY_w(a5)
				st		ShotT_Worry_b(a5)
				move.w	#0,ShotT_Gravity_w(a5)
.cantshoot
				rts

				align 4
backroom:		dc.l	0
SHOTYOFF:		dc.l	0
SHOTTYPE:		dc.w	0
SHOTPOWER:		dc.w	0
SHOTSPEED:		dc.w	0
SHOTOFFMULT:	dc.w	0
SHOTSHIFT:		dc.w	0
SHOTINTOP:		dc.w	0

