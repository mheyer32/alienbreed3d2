;
; *****************************************************************************
; *
; * modules/ai.s
; *
; * Definitions specific to game AI
; *
; * Refactored from airoutine.s
; *
; *****************************************************************************

	; Workspace structure
	STRUCTURE AI_WorkT,0
		UWORD	AI_WorkT_LastX_w
		UWORD	AI_WorkT_LastY_w
		UWORD	AI_WorkT_LastZone_w
		UWORD	AI_WorkT_LastControlPoint_w
		UWORD	AI_WorkT_SeenBy_w
		UWORD	AI_WorkT_DamageDone_w
		UWORD	AI_WorkT_DamageTaken_w

; Code
AI_MainRoutine:
				move.w	#-20,2(a0)


				cmp.b	#1,EntT_CurrentMode_b(a0)
				blt		ai_DoDefault
				beq		ai_DoResponse

				cmp.b	#3,EntT_CurrentMode_b(a0)
				blt		ai_DoFollowup
				beq		ai_DoRetreat

				cmp.b	#5,EntT_CurrentMode_b(a0)
				beq		ai_DoDie

ai_DoTakeDamage:
				jsr		ai_DoWalkAnim
				move.w	4(a0),-(a7)
				bsr		ai_GetRoomStatsStill

				move.w	(a7)+,d0
				cmp.w	#1,AI_DefaultMode_w
				blt		.not_flying

				move.w	d0,4(a0)

.not_flying:
				tst.b	ai_FinishedAnim_b
				beq.s	.still_hurting

				move.b	#0,EntT_CurrentMode_b(a0)
				move.b	#0,EntT_WhichAnim_b(a0)
				move.w	#0,EntT_Timer2_w(a0)

.still_hurting:
				bsr		ai_DoTorch

				tst.w	ObjT_ZoneID_w+ENT_PREV(a0)
				blt.s	.no_copy_in

				move.w	ObjT_ZoneID_w(a0),ObjT_ZoneID_w+ENT_PREV(a0)
				move.w	EntT_ZoneID_w(a0),EntT_ZoneID_w+ENT_PREV(a0)

.no_copy_in:
				movem.l	d0-d7/a0-a6,-(a7)
				move.w	Plr1_XOff_l,newx
				move.w	Plr1_ZOff_l,newz
				move.w	(a0),d1
				move.l	Lvl_ObjectPointsPtr_l,a1
				lea		(a1,d1.w*8),a1
				move.w	(a1),oldx
				move.w	4(a1),oldz
				move.w	#-20,Range
				move.w	#20,speed
				jsr		HeadTowardsAng

				move.w	AngRet,d0
				add.w	ai_AnimFacing_w,d0
				move.w	d0,EntT_CurrentAngle_w(a0)
				movem.l	(a7)+,d0-d7/a0-a6
				rts

ai_DoDie:
				jsr		ai_DoWalkAnim

				bsr		ai_GetRoomStatsStill

				tst.b	ai_FinishedAnim_b
				beq.s	.still_dying

				FREE_ENT	a0

				move.b	#OBJ_TYPE_ALIEN,ObjT_TypeID_b(a0)
				clr.b	ShotT_Worry_b(a0)
				st		ai_GetOut_w

.still_dying:
				move.b	#0,EntT_HitPoints_b(a0)
				tst.w	ObjT_ZoneID_w+ENT_PREV(a0)
				blt.s	.no_copy_in

				move.w	ObjT_ZoneID_w(a0),ObjT_ZoneID_w+ENT_PREV(a0)
				move.w	EntT_ZoneID_w(a0),EntT_ZoneID_w+ENT_PREV(a0)

.no_copy_in:
				rts

ai_TakeDamage:
				clr.b	ai_GetOut_w
				moveq	#0,d0
				move.b	EntT_DamageTaken_b(a0),d0
				move.l	AI_DamagePtr_l,a2
				add.w	d0,(a2)
				move.w	(a2),d0
				asr.w	#2,d0					; divide by 4
				moveq	#0,d1
				move.b	EntT_HitPoints_b(a0),d1
				move.b	#0,EntT_DamageTaken_b(a0)
				cmp.w	d0,d1
				ble		ai_JustDied

				move.w	#0,EntT_Timer1_w(a0)
				move.w	#0,EntT_Timer2_w(a0)
				jsr		GetRand

				and.w	#3,d0
				beq.s	.dodododo

				move.l	WorkspacePtr_l,a5
				st		1(a5)
				move.b	#1,EntT_CurrentMode_b(a0)
				move.w	#0,EntT_Timer2_w(a0)
				move.w	#0,EntT_Timer1_w(a0)
				move.b	#1,EntT_WhichAnim_b(a0)
				move.w	(a0),d0
				move.l	Lvl_ObjectPointsPtr_l,a1
				move.w	(a1,d0.w*8),oldx
				move.w	4(a1,d0.w*8),oldz
				move.w	Plr1_XOff_l,newx
				move.w	Plr1_ZOff_l,newz
				move.w	#100,speed
				move.w	#-20,Range
				jsr		HeadTowardsAng

				move.w	AngRet,EntT_CurrentAngle_w(a0)
				st		ai_GetOut_w
				rts

.dodododo:
				move.b	#4,EntT_CurrentMode_b(a0)		; do take damage.
				move.b	#2,EntT_WhichAnim_b(a0)		; get hit anim.
				move.l	WorkspacePtr_l,a5
				st		1(a5)
				st		ai_GetOut_w
				rts

.no_stop:
				rts

ai_JustDied:
				move.b	#0,EntT_HitPoints_b(a0)
				move.w	EntT_DisplayText_w(a0),d0
				blt.s	.no_text

				muls	#LVLT_MESSAGE_LENGTH,d0
				add.l	Lvl_DataPtr_l,d0
				move.l	a0,-(sp)
				move.l	d0,a0
				move.w	#LVLT_MESSAGE_LENGTH|MSG_TAG_NARRATIVE,d0
				CALLC	Msg_PushLine

				move.l	(sp)+,a0

.no_text:
				move.l	Lvl_ObjectPointsPtr_l,a2
				move.w	(a0),d3
				move.w	(a2,d3.w*8),newx
				move.w	4(a2,d3.w*8),newz
				moveq	#0,d0
				move.b	EntT_Type_b(a0),d0

				; Record the (messy) kill...
				STATS_KILL

				muls	#AlienT_SizeOf_l,d0
				move.l	GLF_DatabasePtr_l,a2
				lea		GLFT_AlienDefs_l(a2),a2
				add.l	d0,a2
				move.b	AlienT_SplatType_w+1(a2),d0
				move.b	d0,Anim_SplatType_w
				cmp.b	#NUM_BULLET_DEFS,d0					; Projectile type 0-19
				blt		.go_splutch

				sub.b	#NUM_BULLET_DEFS,Anim_SplatType_w	; Spawned alien type 0-19
				sub.b	#NUM_BULLET_DEFS,d0
				ext.w	d0
				move.l	GLF_DatabasePtr_l,a2
				add.l	#GLFT_AlienDefs_l,a2
				muls	#AlienT_SizeOf_l,d0
				add.l	d0,a2
				move.l	a2,a4

				; * Spawn some smaller aliens...
				move.w	#2,d7					; number to do.
				move.l	AI_OtherAlienDataPtrs_vl,a2
				NEXT_OBJ    a2
				move.l	Lvl_ObjectPointsPtr_l,a1
				move.w	(a0),d1
				move.l	(a1,d1.w*8),d0
				move.l	4(a1,d1.w*8),d1
				move.w	#9,d3

.spawn_loop:
.find_one_free:
				move.w	ObjT_ZoneID_w(a2),d2
				blt.s	.found_one_free

				tst.b	EntT_HitPoints_b(a2)
				beq.s	.found_one_free

				adda.w	#ENT_NEXT_2,a2 ; todo - why two slots here?
				dbra	d3,.find_one_free
				bra		.cant_shoot

.found_one_free:
				move.b	AlienT_HitPoints_w+1(a4),EntT_HitPoints_b(a2)
				move.b	Anim_SplatType_w,EntT_Type_b(a2)
				move.b	#-1,EntT_DisplayText_w(a2)
				move.b	#0,16(a2)
				move.w	(a2),d4
				move.l	d0,(a1,d4.w*8)
				move.l	d1,4(a1,d4.w*8)
				move.w	4(a0),4(a2)
				move.w	ObjT_ZoneID_w(a0),ObjT_ZoneID_w(a2)
				move.w	ObjT_ZoneID_w(a0),EntT_ZoneID_w(a2)
				move.w	#-1,ObjT_ZoneID_w+ENT_PREV(a2)
				move.w	EntT_CurrentControlPoint_w(a0),EntT_CurrentControlPoint_w(a2)
				move.w	EntT_CurrentControlPoint_w(a0),EntT_TargetControlPoint_w(a2)
				move.b	#-1,EntT_TeamNumber_b(a2)
				move.w	EntT_CurrentAngle_w(a0),EntT_CurrentAngle_w(a2)
				move.b	#0,EntT_CurrentMode_b(a2)
				move.b	#0,EntT_WhichAnim_b(a2)
				move.w	#0,EntT_Timer2_w(a2)
				move.b	#0,EntT_DamageTaken_b(a2)
				move.w	#0,EntT_Timer1_w(a2)
				move.w	#0,EntT_ImpactX_w(a2)
				move.w	#0,EntT_ImpactZ_w(a2)
				move.w	#0,EntT_ImpactY_w(a2)
				move.b	AlienT_HitPoints_w+1(a4),EntT_HitPoints_b(a2)
				move.b	#0,EntT_DamageTaken_b(a2)
				move.l	EntT_DoorsAndLiftsHeld_l(a0),EntT_DoorsAndLiftsHeld_l(a2)
				move.b	ShotT_InUpperZone_b(a0),ShotT_InUpperZone_b(a2)
				move.b  #OBJ_TYPE_AUX,ObjT_TypeID_b+ENT_PREV(a2)
				dbra	d7,.spawn_loop

.cant_shoot:
				bra		.spawned

.go_splutch:
				move.w	#8,d2
				jsr		Anim_ExplodeIntoBits

.spawned:
				move.b	#5,EntT_CurrentMode_b(a0)
				move.b	#3,EntT_WhichAnim_b(a0)
				move.w	#0,EntT_Timer2_w(a0)
				move.l	WorkspacePtr_l,a5
				st		1(a5)
				st		ai_GetOut_w
				rts

ai_DoRetreat:
				rts

ai_DoDefault:
				cmp.w	#1,AI_DefaultMode_w
				blt		ai_ProwlRandom
				beq		ai_ProwlRandomFlying

				rts

ai_DoResponse:
				DEV_CHECK	AI_ATTACK,ai_DoDefault
				cmp.w	#1,AI_ResponseMode_w
				blt		ai_Charge
				beq		ai_ChargeToSide

				cmp.w	#3,AI_ResponseMode_w
				blt		ai_AttackWithGun
				beq		ai_ChargeFlying

				cmp.w	#5,AI_ResponseMode_w
				blt		ai_ChargeToSideFlying
				beq		ai_AttackWithGunFlying

				rts

ai_DoFollowup:
				cmp.w	#1,AI_FollowupMode_w
				blt		ai_PauseBriefly
				beq		ai_Approach

				cmp.w	#3,AI_FollowupMode_w
				blt		ai_ApproachToSide
				beq		ai_ApproachFlying

				cmp.w	#5,AI_FollowupMode_w
				blt		ai_ApproachToSideFlying

				rts

***************************************************
*** DEFAULT MOVEMENTS *****************************
***************************************************

; Need a FLYING prowl routine

ai_ProwlRandomFlying:
				move.l	#1000*256,StepDownVal
				st		AI_FlyABit_w
				bra		ai_ProwlFly

ai_ProwlRandom:
				clr.b	AI_FlyABit_w
				move.l	#30*256,StepDownVal

ai_ProwlFly:
				move.l	#20*256,StepUpVal
				tst.b	EntT_DamageTaken_b(a0)
				beq.s	.no_damage

				bsr		ai_TakeDamage

				tst.b	ai_GetOut_w
				beq.s	.no_damage

				rts

.no_damage:
				jsr		ai_DoWalkAnim

				move.l	AI_BoredomPtr_l,a1
				move.w	2(a1),d1
				move.w	4(a1),d2
				move.l	Lvl_ObjectPointsPtr_l,a2
				move.w	(a0),d3
				move.w	4(a2,d3.w*8),d4
				move.w	(a2,d3.w*8),d3
				move.w	d3,d5
				move.w	d4,d6
				sub.w	d1,d3
				bge.s	.okp1
				neg.w	d3

.okp1:
				sub.w	d2,d4
				bge.s	.okp2
				neg.w	d4

.okp2:
				add.w	d3,d4					; dist away
				cmp.w	#50,d4
				blt.s	.no_new_store

				move.w	d5,2(a1)
				move.w	d6,4(a1)
				move.w	#100,(a1)
				bra		.new_store

.no_new_store:
				sub.w	#1,(a1)
				bgt.s	.new_store

				bsr		ai_GetRoomCPT

				jsr		GetRand

				moveq	#0,d1
				move.w	d0,d1
				divs.w	Lvl_NumControlPoints_w,d1
				swap	d1
				move.w	#7,d7

.try_again:
				move.w	d1,EntT_TargetControlPoint_w(a0)
				move.w	EntT_CurrentControlPoint_w(a0),d0
				jsr		GetNextCPt

				cmp.w	EntT_CurrentControlPoint_w(a0),d0
				beq.s	.plus_again

				cmp.b	#$7f,d0
				bne.s	.okaway2

.plus_again:
				move.w	EntT_TargetControlPoint_w(a0),d1
				add.w	#1,d1
				cmp.w	Lvl_NumControlPoints_w,d1
				blt		.no_bin

				moveq	#0,d1

.no_bin:
				dbra	d7,.try_again

.okaway2:
				move.w	#50,(a1)


.new_store:
ai_Widget:
				tst.w	Plr1_NoiseVol_w
				beq.s	.no_player_noise

				move.l	Plr1_ZonePtr_l,a1
				tst.b	Plr1_StoodInTop_b
				beq.s	.player_not_in_top

				addq	#1,a1

.player_not_in_top:
				moveq	#0,d1
				move.b	ZoneT_ControlPoint_w(a1),d1

				move.w	EntT_CurrentControlPoint_w(a0),d0
				jsr		GetNextCPt

				cmp.b	#$7f,d0
				bne.s	.okaway
				move.w	EntT_CurrentControlPoint_w(a0),d0

.okaway:
				move.w	d0,EntT_TargetControlPoint_w(a0)

.no_player_noise:
				moveq	#0,d0
				move.b	EntT_TeamNumber_b(a0),d0
				blt.s	.no_team
				move.l	#AI_AlienTeamWorkspace_vl,a2
				asl.w	#4,d0
				add.w	d0,a2
				tst.w	AI_WorkT_SeenBy_w(a2)
				blt.s	.no_team
				move.w	(a0),d0
				cmp.w	AI_WorkT_SeenBy_w(a2),d0
				bne.s	.no_remove
				move.w	#-1,AI_WorkT_SeenBy_w(a2)
				bra.s	.no_team

.no_remove:
				asl.w	#4,d0
				move.l	#ai_AlienWorkspace_vl,a1
				add.w	d0,a1
				move.w	#0,AI_WorkT_DamageDone_w(a1)
				move.w	#0,AI_WorkT_DamageTaken_w(a1)
				move.l	(a2),(a1)
				move.l	4(a2),4(a1)
				move.l	8(a2),8(a1)
				move.l	12(a2),12(a1)
				move.w	AI_WorkT_LastControlPoint_w(a1),EntT_TargetControlPoint_w(a0)
				move.w	#-1,AI_WorkT_LastZone_w(a1)
				bra.s	.not_seen

.no_team:
				move.w	(a0),d0
				asl.w	#4,d0
				move.l	#ai_AlienWorkspace_vl,a1
				add.w	d0,a1
				move.w	#0,AI_WorkT_DamageDone_w(a1)
				move.w	#0,AI_WorkT_DamageTaken_w(a1)
				tst.w	AI_WorkT_LastZone_w(a1)
				blt.s	.not_seen
				move.w	AI_WorkT_LastControlPoint_w(a1),EntT_TargetControlPoint_w(a0)
				move.w	#-1,AI_WorkT_LastZone_w(a1)

.not_seen:
				move.w	EntT_CurrentControlPoint_w(a0),d0			; where the alien is now.
				move.w	EntT_TargetControlPoint_w(a0),d1
				jsr		GetNextCPt
				cmp.b	#$7f,d0
				beq.s	.yes_rand
				tst.b	AI_FlyABit_w
				bne.s	.no_rand
				tst.b	ONLYSEE
				beq.s	.no_rand

.yes_rand:
				jsr		GetRand
				moveq	#0,d1
				move.w	d0,d1
				divs.w	Lvl_NumControlPoints_w,d1
				swap	d1
				move.w	#7,d7

.try_again:
				move.w	d1,EntT_TargetControlPoint_w(a0)
				move.w	EntT_CurrentControlPoint_w(a0),d0
				jsr		GetNextCPt
				cmp.w	EntT_CurrentControlPoint_w(a0),d0
				beq.s	.plus_again
				cmp.b	#$7f,d0
				bne.s	.okaway2

.plus_again:
				move.w	EntT_TargetControlPoint_w(a0),d1
				add.w	#1,d1
				cmp.w	Lvl_NumControlPoints_w,d1
				blt		.no_bin
				moveq	#0,d1

.no_bin:
				dbra	d7,.try_again

.okaway2:
.no_rand:
				move.w	d0,ai_MiddleCPT_w

				move.l	Lvl_ControlPointCoordsPtr_l,a1
				move.w	(a1,d0.w*8),newx
				move.w	2(a1,d0.w*8),newz

				asl.w	#2,d0
				add.w	(a0),d0
				muls	#$1347,d0
				and.w	#4095,d0
				move.l	#SinCosTable_vw,a1
				move.w	(a1,d0.w*2),d1
				move.l	#SinCosTable_vw+2048,a1
				move.w	(a1,d0.w*2),d2
				ext.l	d1
				ext.l	d2
				asl.l	#4,d2
				swap	d2
				asl.l	#4,d1
				swap	d1
				add.w	d1,newx
				add.w	d2,newz

				move.w	(a0),d1
				move.l	#ObjRotated_vl,a6
				move.l	Lvl_ObjectPointsPtr_l,a1
				lea		(a1,d1.w*8),a1
				lea		(a6,d1.w*8),a6
				move.w	(a1),oldx
				move.w	4(a1),oldz
				move.w	#0,speed
				tst.b	ai_DoAction_b
				beq.s	.no_speed
				moveq	#0,d2
				move.b	ai_DoAction_b,d2
				asl.w	#2,d2

				muls.w	AI_ProwlSpeed_w,d2
				move.w	d2,speed

.no_speed:
				move.w	#40,Range
				move.w	4(a0),d0
				ext.l	d0
				asl.l	#7,d0
				move.l	thingheight,d2
				asr.l	#1,d2
				sub.l	d2,d0
				move.l	d0,newy
				move.l	d0,oldy

				move.b	ShotT_InUpperZone_b(a0),StoodInTop
				movem.l	d0/a0/a1/a3/a4/d7,-(a7)
				clr.b	canshove
				clr.b	GotThere
				jsr		HeadTowardsAng
				move.w	AngRet,EntT_CurrentAngle_w(a0)

				tst.b	GotThere
				beq.s	.not_next_cpt

				move.w	ai_MiddleCPT_w,d0
				move.w	d0,EntT_CurrentControlPoint_w(a0)
				cmp.w	EntT_TargetControlPoint_w(a0),d0
				bne		.not_next_cpt

* We have arrived at the target contol pt. Pick a
* random one and go to that...

				jsr		GetRand
				moveq	#0,d1
				move.w	d0,d1
				divs.w	Lvl_NumControlPoints_w,d1
				swap	d1
				move.w	d1,EntT_TargetControlPoint_w(a0)

.not_next_cpt:
				move.w	#%1000000000,wallflags
				move.l	#%00001000110010000010,Obj_CollideFlags_l
				jsr		Obj_DoCollision
				tst.b	hitwall
				beq.s	.can_move

				move.w	oldx,newx
				move.w	oldz,newz
				movem.l	(a7)+,d0/a0/a1/a3/a4/d7
				bra		.hit_something

.can_move:
				clr.b	Obj_WallBounce_b
				jsr		MoveObject
				movem.l	(a7)+,d0/a0/a1/a3/a4/d7
				move.b	StoodInTop,ShotT_InUpperZone_b(a0)


.hit_something:
				tst.w	ObjT_ZoneID_w+ENT_PREV(a0)
				blt.s	.no_copy_in

				move.w	ObjT_ZoneID_w(a0),ObjT_ZoneID_w+ENT_PREV(a0)
				move.w	EntT_ZoneID_w(a0),EntT_ZoneID_w+ENT_PREV(a0)

.no_copy_in:
				move.w	4(a0),-(a7)
				bsr		ai_GetRoomStats
				move.w	(a7)+,d0

				tst.b	AI_FlyABit_w
				beq.s	.noflymove
				move.w	d0,4(a0)
				bsr		ai_FlyToCPTHeight

.noflymove:
				bsr		ai_DoTorch

				move.b	#0,EntT_CurrentMode_b(a0)
				bsr		AI_LookForPlayer1
				move.b	#0,EntT_WhichAnim_b(a0)
				tst.b	ObjT_SeePlayer_b(a0)
				beq.s	.cant_see_player

				bsr		ai_CheckInFront
				tst.b	d0
				beq.s	.cant_see_player

				move.w	Anim_TempFrames_w,d0
				sub.w	d0,EntT_Timer1_w(a0)
				bgt.s	.notreacted
				bsr		ai_CheckForDark
				tst.b	d0
				beq.s	.cant_see_player

; We have seen the player and reacted; can we attack him?

				tst.b	AI_FlyABit_w
				bne.s	.attack_player

				cmp.w	#2,AI_ResponseMode_w
				beq.s	.attack_player
				cmp.w	#5,AI_ResponseMode_w
				beq.s	.attack_player

				bsr		ai_CheckAttackOnGround
				tst.b	d0
				bne.s	.attack_player

; We can see the player

				bsr		ai_StorePlayerPosition

; but we can't get to him
				bra.s	.cant_see_player

.attack_player:
				move.w	#0,EntT_Timer2_w(a0)
				move.b	#1,EntT_CurrentMode_b(a0)
				move.b	#1,EntT_WhichAnim_b(a0)

.notreacted:
				move.w	ai_AnimFacing_w,d0
				add.w	d0,EntT_CurrentAngle_w(a0)
				rts

.cant_see_player:
				move.w	AI_ReactionTime_w,EntT_Timer1_w(a0)
				move.w	ai_AnimFacing_w,d0
				add.w	d0,EntT_CurrentAngle_w(a0)
				rts

***********************************************
** RESPONSE MOVEMENTS *************************
***********************************************

ai_ChargeToSide:
				clr.b	AI_FlyABit_w
				st		ai_ToSide_w
				move.l	#30*256,StepDownVal
				bra		ai_ChargeCommon

ai_Charge:
				clr.b	AI_FlyABit_w
				clr.b	ai_ToSide_w
				move.l	#30*256,StepDownVal

ai_ChargeCommon:
				tst.b	EntT_DamageTaken_b(a0)
				beq.s	.no_damage
				bsr		ai_TakeDamage
				tst.b	ai_GetOut_w
				beq.s	.no_damage
				rts

.no_damage:
				jsr		ai_DoAttackAnim

				move.w	ObjT_ZoneID_w(a0),FromZone
				jsr		CheckTeleport
				tst.b	OKTEL
				beq.s	.no_teleport
				move.l	floortemp,d0
				asr.l	#7,d0
				add.w	d0,4(a0)
				bra		.no_munch

.no_teleport:
				move.w	Plr1_XOff_l,newx
				move.w	Plr1_ZOff_l,newz
				move.w	Plr1_SinVal_w,tempsin
				move.w	Plr1_CosVal_w,tempcos
				move.w	Plr1_TmpXOff_l,tempx
				move.w	Plr1_TmpZOff_l,tempz
				tst.b	ai_ToSide_w
				beq.s	.no_side
				jsr		RunAround

.no_side:
				move.w	(a0),d1
				move.l	#ObjRotated_vl,a6
				move.l	Lvl_ObjectPointsPtr_l,a1
				lea		(a1,d1.w*8),a1
				lea		(a6,d1.w*8),a6
				move.w	(a1),oldx
				move.w	4(a1),oldz
				move.w	AI_ResponseSpeed_w,d2
				muls.w	Anim_TempFrames_w,d2
				move.w	d2,speed
				move.w	#160,Range
				move.w	4(a0),d0
				ext.l	d0
				asl.l	#7,d0
				move.l	thingheight,d2
				asr.l	#1,d2
				sub.l	d2,d0
				move.l	d0,newy
				move.l	d0,oldy

				move.b	ShotT_InUpperZone_b(a0),StoodInTop
				movem.l	d0/a0/a1/a3/a4/d7,-(a7)
				clr.b	canshove
				clr.b	GotThere
				jsr		HeadTowardsAng
				move.w	#%1000000000,wallflags

				move.l	#%100000,Obj_CollideFlags_l
				jsr		Obj_DoCollision
				tst.b	hitwall
				beq.s	.not_hit_player

				move.w	oldx,newx
				move.w	oldz,newz
				st		GotThere
				movem.l	(a7)+,d0/a0/a1/a3/a4/d7
				bra		.hit_something

.not_hit_player:
				move.l	#%11111111110111000010,Obj_CollideFlags_l
				jsr		Obj_DoCollision
				tst.b	hitwall
				beq.s	.can_move

				move.w	oldx,newx
				move.w	oldz,newz
				movem.l	(a7)+,d0/a0/a1/a3/a4/d7
				bra		.hit_something

.can_move:
				clr.b	Obj_WallBounce_b
				jsr		MoveObject
				movem.l	(a7)+,d0/a0/a1/a3/a4/d7
				move.b	StoodInTop,ShotT_InUpperZone_b(a0)
				move.w	AngRet,EntT_CurrentAngle_w(a0)

.hit_something:
				tst.w   ObjT_ZoneID_w+ENT_PREV(a0)
				blt.s	.no_copy_in

				move.w	ObjT_ZoneID_w(a0),ObjT_ZoneID_w+ENT_PREV(a0)
				move.w	EntT_ZoneID_w(a0),EntT_ZoneID_w+ENT_PREV(a0)

.no_copy_in:
				tst.b	GotThere
				beq.s	.no_munch
				tst.b	ai_DoAction_b
				beq.s	.no_munch
				move.l	Plr1_ObjectPtr_l,a5
				move.b	ai_DoAction_b,d0
				asl.w	#1,d0
				add.b	d0,EntT_DamageTaken_b(a5)
				move.w	newx,d0
				sub.w	oldx,d0
				ext.l	d0
				divs	Anim_TempFrames_w,d0
				add.w	d0,EntT_ImpactX_w(a5)
				move.w	newz,d0
				sub.w	oldz,d0
				ext.l	d0
				divs	Anim_TempFrames_w,d0
				add.w	d0,EntT_ImpactZ_w(a5)

.no_munch:
				bsr		ai_StorePlayerPosition
				bsr		ai_GetRoomStats
				bsr		ai_GetRoomCPT
				bsr		ai_DoTorch
				bsr		AI_LookForPlayer1
				move.b	#0,EntT_CurrentMode_b(a0)
				tst.b	ObjT_SeePlayer_b(a0)
				beq.s	.cant_see_player

				bsr		ai_CheckInFront
				tst.b	d0
				beq.s	.cant_see_player
				tst.b	AI_FlyABit_w
				bne.s	.attack_player

				bsr		ai_CheckAttackOnGround
				tst.b	d0
				bne.s	.attack_player

				bra.s	.cant_see_player

.attack_player:
				move.w	ai_AnimFacing_w,d0
				add.w	d0,EntT_CurrentAngle_w(a0)
				move.b	#1,EntT_CurrentMode_b(a0)
				move.b	#1,EntT_WhichAnim_b(a0)
				rts

.cant_see_player:
				move.b	#0,EntT_WhichAnim_b(a0)
				move.w	#0,EntT_Timer2_w(a0)
				move.w	ai_AnimFacing_w,d0
				add.w	d0,EntT_CurrentAngle_w(a0)
				rts

ai_AttackWithGunFlying:
				st		AI_FlyABit_w
				bra		ai_AttackCommon

ai_AttackWithGun:
				clr.b	AI_FlyABit_w

ai_AttackCommon:
				move.l	GLF_DatabasePtr_l,a1
				lea		GLFT_AlienDefs_l(a1),a1
				moveq	#0,d0
				move.b	EntT_Type_b(a0),d0
				muls	#AlienT_SizeOf_l,d0
				add.w	d0,a1
				move.w	AlienT_BulType_w(a1),d0
				move.b	d0,SHOTTYPE
				move.l	GLF_DatabasePtr_l,a1
				lea		GLFT_BulletDefs_l(a1),a1
				muls	#BulT_SizeOf_l,d0
				add.l	d0,a1
				move.l	BulT_HitDamage_l(a1),d0
				move.b	d0,SHOTPOWER
				clr.l	d1
				move.l	BulT_Speed_l(a1),d0
				bset	d0,d1
				move.w	d1,SHOTSPEED
				sub.w	#1,d0
				move.w	d0,SHOTSHIFT
				tst.l	BulT_IsHitScan_l(a1)
				beq		ai_AttackWithProjectile

ai_AttackWithHitScan:
				tst.b	EntT_DamageTaken_b(a0)
				beq.s	.no_damage

				move.b	#4,EntT_CurrentMode_b(a0)
				bsr		ai_TakeDamage
				tst.b	ai_GetOut_w
				beq.s	.no_damage
; move.w ai_AnimFacing_w,d0
; add.w d0,EntT_CurrentAngle_w(a0)
				rts

.no_damage:
				jsr		ai_DoAttackAnim

				movem.l	d0-d7/a0-a6,-(a7)
				move.w	Plr1_XOff_l,newx
				move.w	Plr1_ZOff_l,newz
				move.w	(a0),d1
				move.l	Lvl_ObjectPointsPtr_l,a1
				lea		(a1,d1.w*8),a1
				move.w	(a1),oldx
				move.w	4(a1),oldz
				move.w	#-20,Range
				move.w	#20,speed
				jsr		HeadTowardsAng
				move.w	AngRet,EntT_CurrentAngle_w(a0)
				movem.l	(a7)+,d0-d7/a0-a6

				bsr		ai_StorePlayerPosition

				bsr		AI_LookForPlayer1

				move.b	#0,EntT_CurrentMode_b(a0)
				tst.b	ObjT_SeePlayer_b(a0)
				beq.s	.cant_see_player

				bsr		ai_CheckInFront
				tst.b	d0
				beq.s	.cant_see_player

				move.b	#1,EntT_CurrentMode_b(a0)
				move.b	#1,EntT_WhichAnim_b(a0)
				move.w	ai_AnimFacing_w,d0
				add.w	d0,EntT_CurrentAngle_w(a0)
				bra		.can_see_player

.cant_see_player:
				move.b	#0,EntT_WhichAnim_b(a0)
				move.w	#0,EntT_Timer2_w(a0)
				move.w	AI_FollowupTimer_w,EntT_Timer1_w(a0)
				move.w	#0,EntT_Timer2_w(a0)
				move.w	ai_AnimFacing_w,d0
				add.w	d0,EntT_CurrentAngle_w(a0)
				rts

.can_see_player:
				tst.b	ai_DoAction_b
				beq		.no_shooty_thang

				move.w	(a0),d1
				move.l	#ObjRotated_vl,a6
				move.l	Lvl_ObjectPointsPtr_l,a1
				lea		(a1,d1.w*8),a1
				lea		(a6,d1.w*8),a6

				movem.l	a0/a1,-(a7)
				jsr		GetRand

				move.l	#ObjRotated_vl,a6
				move.w	(a0),d1
				lea		(a6,d1.w*8),a6

				and.w	#$7fff,d0
				move.w	(a6),d1
				muls	d1,d1
				move.w	2(a6),d2
				muls	d2,d2
				add.l	d2,d1
				asr.l	#6,d1
				ext.l	d0
				asl.l	#2,d0
				cmp.l	d1,d0
				bgt.s	.hit_player
				jsr		SHOOTPLAYER1
				bra.s	.missed_player

.hit_player:
				move.l	Plr1_ObjectPtr_l,a1
				move.b	SHOTPOWER,d0
				add.b	d0,EntT_DamageTaken_b(a1)

				sub.l	#ObjRotated_vl,a6
				add.l	Lvl_ObjectPointsPtr_l,a6
				move.w	(a6),d0
				sub.w	Plr1_TmpXOff_l,d0				;dx
				move.w	4(a6),d1
				sub.w	Plr1_TmpZOff_l,d1				;dz

				move.w	d0,d2
				move.w	d1,d3
				muls	d2,d2
				muls	d3,d3
				add.l	d3,d2
				jsr		ai_CalcSqrt
				add.l	d2,d2

				moveq	#0,d3
				move.b	SHOTPOWER,d3

				muls	d3,d0
				divs	d2,d0
				muls	d3,d1
				divs	d2,d1

				sub.w	d0,EntT_ImpactX_w(a1)
				sub.w	d1,EntT_ImpactZ_w(a1)

.missed_player:
				movem.l	(a7)+,a0/a1

.no_shooty_thang:
				move.w	(a0),d1
				move.l	Lvl_ObjectPointsPtr_l,a1
				lea		(a1,d1.w*8),a1

				move.w	(a1),newx
				move.w	4(a1),newz

				bsr		ai_DoTorch

				tst.b	ai_FinishedAnim_b
				beq.s	.not_finished_attacking
				move.b	#0,EntT_WhichAnim_b(a0)
				move.b	#2,EntT_CurrentMode_b(a0)
				move.w	AI_FollowupTimer_w,EntT_Timer1_w(a0)
				move.w	#0,EntT_Timer2_w(a0)
				move.w	ai_AnimFacing_w,d0
				add.w	d0,EntT_CurrentAngle_w(a0)
				rts

.not_finished_attacking:
				rts

ai_AttackWithProjectile:
				tst.b	EntT_DamageTaken_b(a0)
				beq.s	.no_damage

				move.b	#4,EntT_CurrentMode_b(a0)
				bsr		ai_TakeDamage
				tst.b	ai_GetOut_w
				beq.s	.no_damage
; move.w ai_AnimFacing_w,d0
; add.w d0,EntT_CurrentAngle_w(a0)
				rts

.no_damage:
				jsr		ai_DoAttackAnim

				movem.l	d0-d7/a0-a6,-(a7)
				move.w	Plr1_XOff_l,newx
				move.w	Plr1_ZOff_l,newz
				move.w	(a0),d1
				move.l	Lvl_ObjectPointsPtr_l,a1
				lea		(a1,d1.w*8),a1
				move.w	(a1),oldx
				move.w	4(a1),oldz
				move.w	#-20,Range
				move.w	#20,speed
				jsr		HeadTowardsAng
				move.w	AngRet,EntT_CurrentAngle_w(a0)
				movem.l	(a7)+,d0-d7/a0-a6

				bsr		ai_StorePlayerPosition

				tst.b	ai_DoAction_b
				beq.s	.no_shooty_thang

				movem.l	d0-d7/a0-a6,-(a7)

				move.w	(a0),d1
				move.l	Lvl_ObjectPointsPtr_l,a1
				lea		(a1,d1.w*8),a1

				move.b	ShotT_InUpperZone_b(a0),SHOTINTOP

				jsr		FireAtPlayer1
				movem.l	(a7)+,d0-d7/a0-a6

.no_shooty_thang:
				move.w	(a0),d1
				move.l	Lvl_ObjectPointsPtr_l,a1
				lea		(a1,d1.w*8),a1

				move.w	(a1),newx
				move.w	4(a1),newz

				bsr		ai_DoTorch

				tst.b	ai_FinishedAnim_b
				beq.s	.not_finished_attacking
				move.b	#0,EntT_WhichAnim_b(a0)
				move.b	#2,EntT_CurrentMode_b(a0)
				move.w	AI_FollowupTimer_w,EntT_Timer1_w(a0)
				move.w	#0,EntT_Timer2_w(a0)
				move.w	ai_AnimFacing_w,d0
				add.w	d0,EntT_CurrentAngle_w(a0)
				rts

.not_finished_attacking:
				bsr		AI_LookForPlayer1
				move.b	#0,EntT_CurrentMode_b(a0)
				tst.b	ObjT_SeePlayer_b(a0)
				beq.s	.cant_see_player

				bsr		ai_CheckInFront
				tst.b	d0
				beq.s	.cant_see_player

				move.b	#1,EntT_WhichAnim_b(a0)
				move.b	#1,EntT_CurrentMode_b(a0)
				move.w	ai_AnimFacing_w,d0
				add.w	d0,EntT_CurrentAngle_w(a0)
				rts

.cant_see_player:
				move.b	#0,EntT_WhichAnim_b(a0)
				move.w	#0,EntT_Timer2_w(a0)
				move.w	AI_FollowupTimer_w,EntT_Timer1_w(a0)
				move.w	#0,EntT_Timer2_w(a0)
				move.w	ai_AnimFacing_w,d0
				add.w	d0,EntT_CurrentAngle_w(a0)
				rts

ai_ChargeToSideFlying:
				st		AI_FlyABit_w
				st		ai_ToSide_w
				move.l	#1000*256,StepDownVal
				bra		ai_ChargeFlyingCommon

ai_ChargeFlying:
				clr.b	ai_ToSide_w
				st		AI_FlyABit_w
				move.l	#1000*256,StepDownVal

ai_ChargeFlyingCommon:
				tst.b	EntT_DamageTaken_b(a0)
				beq.s	.no_damage

				bsr		ai_TakeDamage
				tst.b	ai_GetOut_w
				beq.s	.no_damage
; move.w ai_AnimFacing_w,d0
; add.w d0,EntT_CurrentAngle_w(a0)
				rts

.no_damage:
				jsr		ai_DoAttackAnim

				move.w	ObjT_ZoneID_w(a0),FromZone
				jsr		CheckTeleport

				tst.b	OKTEL
				beq.s	.no_teleport

				move.l	floortemp,d0
				asr.l	#7,d0
				add.w	d0,4(a0)
				bra		.no_munch

.no_teleport:
				move.w	(a0),d1
				move.l	#ObjRotated_vl,a6
				move.l	Lvl_ObjectPointsPtr_l,a1
				lea		(a1,d1.w*8),a1
				lea		(a6,d1.w*8),a6
				move.w	(a1),oldx
				move.w	4(a1),oldz
				move.w	Plr1_XOff_l,newx
				move.w	Plr1_ZOff_l,newz
				move.w	Plr1_SinVal_w,tempsin
				move.w	Plr1_CosVal_w,tempcos
				move.w	Plr1_TmpXOff_l,tempx
				move.w	Plr1_TmpZOff_l,tempz
				tst.b	ai_ToSide_w
				beq.s	.no_side
				jsr		RunAround

.no_side:
				move.w	AI_ResponseSpeed_w,d2
				muls.w	Anim_TempFrames_w,d2
				move.w	d2,speed
				move.w	#160,Range
				move.w	4(a0),d0
				ext.l	d0
				asl.l	#7,d0
				move.l	thingheight,d2
				asr.l	#1,d2
				sub.l	d2,d0
				move.l	d0,newy
				move.l	d0,oldy

				move.b	ShotT_InUpperZone_b(a0),StoodInTop
				movem.l	d0/a0/a1/a3/a4/d7,-(a7)
				clr.b	canshove
				clr.b	GotThere
				jsr		HeadTowardsAng
				move.w	#%1000000000,wallflags

				move.l	#%100000,Obj_CollideFlags_l
				jsr		Obj_DoCollision
				tst.b	hitwall
				beq.s	.not_hit_player

				move.w	oldx,newx
				move.w	oldz,newz
				st		GotThere
				movem.l	(a7)+,d0/a0/a1/a3/a4/d7
				bra		.hit_something

.not_hit_player:
				move.l	#%11111111110111000010,Obj_CollideFlags_l
				jsr		Obj_DoCollision
				tst.b	hitwall
				beq.s	.can_move

				move.w	oldx,newx
				move.w	oldz,newz
				movem.l	(a7)+,d0/a0/a1/a3/a4/d7
				bra		.hit_something

.can_move:
				clr.b	Obj_WallBounce_b
				jsr		MoveObject
				movem.l	(a7)+,d0/a0/a1/a3/a4/d7
				move.b	StoodInTop,ShotT_InUpperZone_b(a0)
				move.w	AngRet,EntT_CurrentAngle_w(a0)

.hit_something:
				tst.b	GotThere
				beq.s	.no_munch
				tst.b	ai_DoAction_b
				beq.s	.no_munch
				move.l	Plr1_ObjectPtr_l,a5
				move.b	ai_DoAction_b,d0
				asl.w	#1,d0
				add.b	d0,EntT_DamageTaken_b(a5)

.no_munch:
				bsr		ai_StorePlayerPosition

				move.w	4(a0),-(a7)
				bsr		ai_GetRoomStats
				move.w	(a7)+,4(a0)

				bsr		ai_GetRoomCPT
				bsr		ai_FlyToPlayerHeight
				bsr		ai_DoTorch
				bsr		AI_LookForPlayer1
				move.b	#0,EntT_CurrentMode_b(a0)
				tst.b	ObjT_SeePlayer_b(a0)
				beq.s	.cant_see_player

				bsr		ai_CheckInFront
				tst.b	d0
				beq.s	.cant_see_player
				move.b	#1,EntT_CurrentMode_b(a0)
				move.b	#1,EntT_WhichAnim_b(a0)
				move.w	ai_AnimFacing_w,d0
				add.w	d0,EntT_CurrentAngle_w(a0)
				rts
.cant_see_player:
				move.b	#0,EntT_WhichAnim_b(a0)
				move.w	#0,EntT_Timer2_w(a0)
				move.w	ai_AnimFacing_w,d0
				add.w	d0,EntT_CurrentAngle_w(a0)
				rts


***********************************************
** Retreat Movements **************************
***********************************************

***********************************************
** Followup Movements *************************
***********************************************

ai_PauseBriefly:
				tst.b	EntT_DamageTaken_b(a0)
				beq.s	.no_damage

				bsr		ai_TakeDamage
				tst.b	ai_GetOut_w
				beq.s	.no_damage

; move.w ai_AnimFacing_w,d0
; add.w d0,EntT_CurrentAngle_w(a0)
				rts

.no_damage:
				move.w	#0,EntT_Timer2_w(a0)
				jsr		ai_DoWalkAnim

				move.w	Anim_TempFrames_w,d0
				sub.w	d0,EntT_Timer1_w(a0)
				bgt.s	.stillwaiting

				move.w	(a0),d1
				move.l	Lvl_ObjectPointsPtr_l,a1
				lea		(a1,d1.w*8),a1

				move.w	(a1),newx
				move.w	4(a1),newz
				bsr		ai_DoTorch

				bsr		AI_LookForPlayer1

				move.b	#0,EntT_CurrentMode_b(a0)
				tst.b	ObjT_SeePlayer_b(a0)
				beq.s	.cant_see_player

				bsr		ai_CheckInFront
				tst.b	d0
				beq.s	.cant_see_player
				bsr		ai_CheckForDark
				tst.b	d0
				beq.s	.cant_see_player
				move.b	#1,EntT_WhichAnim_b(a0)
				move.b	#1,EntT_CurrentMode_b(a0)
				move.w	ai_AnimFacing_w,d0
				add.w	d0,EntT_CurrentAngle_w(a0)
				rts

.cant_see_player:
				move.b	#0,EntT_WhichAnim_b(a0)
				move.w	ai_AnimFacing_w,d0
				add.w	d0,EntT_CurrentAngle_w(a0)
				rts

.stillwaiting:
				move.w	ai_AnimFacing_w,d0
				add.w	d0,EntT_CurrentAngle_w(a0)
				rts



ai_Approach:
				clr.b	AI_FlyABit_w
				move.l	#30*256,StepDownVal
				clr.b	ai_ToSide_w
				bra		ai_ApproachCommon

ai_ApproachFlying:
				st		AI_FlyABit_w
				move.l	#1000*256,StepDownVal
				clr.b	ai_ToSide_w
				bra		ai_ApproachCommon

ai_ApproachToSideFlying:
				st		AI_FlyABit_w
				move.l	#1000*256,StepDownVal
				st		ai_ToSide_w
				bra		ai_ApproachCommon

ai_ApproachToSide:
				st		ai_ToSide_w
				clr.b	AI_FlyABit_w
				move.l	#30*256,StepDownVal

ai_ApproachCommon:
				tst.b	EntT_DamageTaken_b(a0)
				beq.s	.no_damage
				bsr		ai_TakeDamage
				tst.b	ai_GetOut_w
				beq.s	.no_damage
				rts

.no_damage:
				jsr		ai_DoWalkAnim

				move.w	ObjT_ZoneID_w(a0),FromZone
				jsr		CheckTeleport

				tst.b	OKTEL
				beq.s	.no_teleport

				move.l	floortemp,d0
				asr.l	#7,d0
				add.w	d0,4(a0)
				bra		.no_munch

.no_teleport:
				move.w	(a0),d1
				move.l	#ObjRotated_vl,a6
				move.l	Lvl_ObjectPointsPtr_l,a1
				lea		(a1,d1.w*8),a1
				lea		(a6,d1.w*8),a6
				move.w	(a1),oldx
				move.w	4(a1),oldz

				move.w	Plr1_XOff_l,newx
				move.w	Plr1_ZOff_l,newz
				move.w	Plr1_SinVal_w,tempsin
				move.w	Plr1_CosVal_w,tempcos
				move.w	Plr1_TmpXOff_l,tempx
				move.w	Plr1_TmpZOff_l,tempz
				tst.b	ai_ToSide_w
				beq.s	.no_side
				jsr		RunAround

.no_side:
				move.w	#0,speed
				tst.b	ai_DoAction_b
				beq.s	.no_speed
				moveq	#0,d2
				move.b	ai_DoAction_b,d2
				asl.w	#2,d2
				muls.w	AI_FollowupSpeed_w,d2
				move.w	d2,speed

.no_speed:
				move.w	#160,Range
				move.w	4(a0),d0
				ext.l	d0
				asl.l	#7,d0
				move.l	thingheight,d2
				asr.l	#1,d2
				sub.l	d2,d0
				move.l	d0,newy
				move.l	d0,oldy

				move.b	ShotT_InUpperZone_b(a0),StoodInTop
				movem.l	d0/a0/a1/a3/a4/d7,-(a7)
				clr.b	canshove
				clr.b	GotThere
				jsr		HeadTowardsAng
				move.w	#%1000000000,wallflags

				move.l	#%100000,Obj_CollideFlags_l
				jsr		Obj_DoCollision
				tst.b	hitwall
				beq.s	.not_hit_player

				move.w	oldx,newx
				move.w	oldz,newz
				st		GotThere
				movem.l	(a7)+,d0/a0/a1/a3/a4/d7
				bra		.hit_something

.not_hit_player:
				move.l	#%11111111110111000010,Obj_CollideFlags_l
				jsr		Obj_DoCollision
				tst.b	hitwall
				beq.s	.can_move

				move.w	oldx,newx
				move.w	oldz,newz
				movem.l	(a7)+,d0/a0/a1/a3/a4/d7
				bra		.hit_something

.can_move:
				clr.b	Obj_WallBounce_b
				jsr		MoveObject
				movem.l	(a7)+,d0/a0/a1/a3/a4/d7
				move.b	StoodInTop,ShotT_InUpperZone_b(a0)
				move.w	AngRet,EntT_CurrentAngle_w(a0)

.hit_something:
				tst.w	ObjT_ZoneID_w+ENT_PREV(a0)
				blt.s	.no_copy_in

				move.w	ObjT_ZoneID_w(a0),ObjT_ZoneID_w+ENT_PREV(a0)
				move.w	EntT_ZoneID_w(a0),EntT_ZoneID_w+ENT_PREV(a0)

.no_copy_in:
.no_munch:
				bsr		ai_StorePlayerPosition

				tst.b	AI_FlyABit_w
				beq.s	.notfl

				bsr		ai_FlyToPlayerHeight

.notfl:
				move.w	4(a0),-(a7)
				bsr		ai_GetRoomStats
				move.w	(a7)+,d0
				tst.b	AI_FlyABit_w
				beq.s	.not_flying
				move.w	d0,4(a0)

.not_flying:
				bsr		ai_GetRoomCPT
				bsr		ai_DoTorch

				move.b	#0,EntT_CurrentMode_b(a0)
				tst.b	AI_FlyABit_w
				bne.s	.is_flying
				bsr		ai_CheckAttackOnGround
				tst.b	d0
				beq		.cant_see_player

.is_flying:
				bsr		AI_LookForPlayer1
				tst.b	ObjT_SeePlayer_b(a0)
				beq.s	.cant_see_player

				bsr		ai_CheckInFront
				tst.b	d0
				beq.s	.cant_see_player
				move.b	#2,EntT_CurrentMode_b(a0)
				move.w	Anim_TempFrames_w,d0
				sub.w	d0,EntT_Timer1_w(a0)
				bgt.s	.cant_see_player
				bsr		ai_CheckForDark
				tst.b	d0
				beq.s	.cant_see_player
				move.b	#1,EntT_CurrentMode_b(a0)
				move.w	#0,EntT_Timer2_w(a0)
				move.b	#1,EntT_WhichAnim_b(a0)
				move.w	ai_AnimFacing_w,d0
				add.w	d0,EntT_CurrentAngle_w(a0)
				rts

.cant_see_player:
				move.b	#0,EntT_WhichAnim_b(a0)
				move.w	ai_AnimFacing_w,d0
				add.w	d0,EntT_CurrentAngle_w(a0)
				rts

***********************************************
** GENERIC ROUTINES ***************************
***********************************************

ai_FlyToCPTHeight:
				move.w	ai_MiddleCPT_w,d0
				move.l	Lvl_ControlPointCoordsPtr_l,a1
				move.w	4(a1,d0.w*8),d1
				bra		ai_FlyToHeightCommon

ai_FlyToPlayerHeight:
				move.l	Plr1_YOff_l,d1
				asr.l	#7,d1

ai_FlyToHeightCommon:
				move.w	4(a0),d0
				cmp.w	d0,d1
				bgt.s	.fly_down
				move.w	EntT_VelocityY_w(a0),d2
				sub.w	#2,d2
				cmp.w	#-32,d2
				bgt.s	.no_fast_up
				move.w	#-32,d2

.no_fast_up
				move.w	d2,EntT_VelocityY_w(a0)
				add.w	d2,4(a0)
				bra		ai_CheckFloorCeiling

.fly_down
				move.w	EntT_VelocityY_w(a0),d2
				add.w	#2,d2
				cmp.w	#32,d2
				blt.s	.no_fast_down
				move.w	#32,d2

.no_fast_down
				move.w	d2,EntT_VelocityY_w(a0)
				add.w	d2,4(a0)

ai_CheckFloorCeiling:
				move.w	4(a0),d2
				move.l	thingheight,d4
				asr.l	#8,d4
				move.w	d2,d3
				sub.w	d4,d2
				add.w	d4,d3

				move.l	objroom,a2

				move.l	ZoneT_Floor_l(a2),d0
				move.l	ZoneT_Roof_l(a2),d1
				tst.b	ShotT_InUpperZone_b(a0)
				beq.s	.not_in_top
				move.l	ZoneT_UpperFloor_l(a2),d0
				move.l	ZoneT_UpperRoof_l(a2),d1

.not_in_top:
				asr.l	#7,d0
				asr.l	#7,d1
				cmp.w	d0,d3
				blt.s	.bottom_no_hit
				move.w	d0,d3
				move.w	d3,d2
				sub.w	d4,d2
				sub.w	d4,d2

.bottom_no_hit:
				cmp.w	d1,d2
				bgt.s	.top_no_hit
				move.w	d1,d2
				move.w	d2,d3
				add.w	d4,d3
				add.w	d4,d3

.top_no_hit:
				sub.w	d4,d3
				move.w	d3,4(a0)
				rts

ai_StorePlayerPosition:
				move.w	(a0),d0
				move.l	#ai_AlienWorkspace_vl,a2
				asl.w	#4,d0
				add.w	d0,a2
				move.w	Plr1_XOff_l,AI_WorkT_LastX_w(a2)
				move.w	Plr1_ZOff_l,AI_WorkT_LastY_w(a2)
				move.l	Plr1_ZonePtr_l,a3
				move.w	(a3),AI_WorkT_LastZone_w(a2)
				moveq	#0,d0
				move.b	ZoneT_ControlPoint_w(a3),d0
				tst.b	Plr1_StoodInTop_b
				beq.s	.player_not_in_top
				move.b	ZoneT_ControlPoint_w+1(a3),d0

.player_not_in_top:
				move.w	d0,AI_WorkT_LastControlPoint_w(a2)
				move.b	EntT_TeamNumber_b(a0),d0
				blt.s	.no_team
				move.l	#AI_AlienTeamWorkspace_vl,a2
				asl.w	#4,d0
				add.w	d0,a2
				move.w	Plr1_XOff_l,AI_WorkT_LastX_w(a2)
				move.w	Plr1_ZOff_l,AI_WorkT_LastY_w(a2)
				move.l	Plr1_ZonePtr_l,a3
				move.w	(a3),AI_WorkT_LastZone_w(a2)
				moveq	#0,d0
				move.b	ZoneT_ControlPoint_w(a3),d0
				tst.b	Plr1_StoodInTop_b
				beq.s	.player_not_in_top2
				move.b	ZoneT_ControlPoint_w+1(a3),d0

.player_not_in_top2:
				move.w	d0,AI_WorkT_LastControlPoint_w(a2)
				move.w	(a0),AI_WorkT_SeenBy_w(a2)

.no_team:
				rts

ai_GetRoomStats:
				move.w	(a0),d0
				move.l	Lvl_ObjectPointsPtr_l,a1
				lea		(a1,d0.w*8),a1
				move.w	newx,(a1)
				move.w	newz,4(a1)

ai_GetRoomStatsStill:
				move.l	objroom,a2
				move.w	(a2),12(a0)

				move.l	ZoneT_Floor_l(a2),d0
				tst.b	ShotT_InUpperZone_b(a0)
				beq.s	.not_in_top2
				move.l	ZoneT_UpperFloor_l(a2),d0

.not_in_top2:
				move.l	thingheight,d2
				asr.l	#1,d2
				sub.l	d2,d0
				asr.l	#7,d0
				move.w	d0,4(a0)
				move.w	ObjT_ZoneID_w(a0),EntT_ZoneID_w(a0)
				rts

ai_CheckForDark:
				move.w	(a0),d0
				move.l	Plr1_ZonePtr_l,a3
				move.w	(a3),d1
				cmp.w	d1,d0
				beq.s	.not_in_dark

				jsr		GetRand
				and.w	#31,d0
				cmp.w	Plr1_RoomBright_w,d0
				bge.s	.not_in_dark

.in_dark:
				moveq	#0,d0
				rts

.not_in_dark:
				moveq	#-1,d0
				rts

ai_CheckInFront:

; clr.b ObjT_SeePlayer_b(a0)
; rts

				move.w	(a0),d0
				move.l	Lvl_ObjectPointsPtr_l,a1
				move.w	(a1,d0.w*8),newx
				move.w	4(a1,d0.w*8),newz

				move.w	Plr1_TmpXOff_l,d0
				sub.w	newx,d0
				move.w	Plr1_TmpZOff_l,d1
				sub.w	newz,d1

				move.w	EntT_CurrentAngle_w(a0),d2
				AMOD_A	d2
				move.l	#SinCosTable_vw,a3
				move.w	(a3,d2.w),d3
				add.l	#COSINE_OFS,d2
				move.w	(a3,d2.w),d4

				muls	d3,d0
				muls	d4,d1
				add.l	d0,d1
				sgt		d0
				rts

AI_LookForPlayer1:
				clr.b	ObjT_SeePlayer_b(a0)
				clr.b	CanSee
				move.b	ShotT_InUpperZone_b(a0),ViewerTop
				move.b	Plr1_StoodInTop_b,TargetTop
				move.l	Plr1_ZonePtr_l,ToRoom
				move.l	objroom,FromRoom
				move.w	newx,Viewerx
				move.w	newz,Viewerz
				move.w	Plr1_XOff_l,Targetx
				move.w	Plr1_ZOff_l,Targetz
				move.l	Plr1_YOff_l,d0
				asr.l	#7,d0
				move.w	d0,Targety
				move.w	4(a0),Viewery
				jsr		CanItBeSeen

				tst.b	CanSee
				beq		.carryonprowling

				move.b	#1,ObjT_SeePlayer_b(a0)

.carryonprowling:
				rts

AI_InitAlienWorkspace:
				move.l	#ai_AlienWorkspace_vl,a0
				move.l	#299,d0

.loop:
				move.l	#0,(a0)
				move.l	#-1,4(a0)
				move.l	#-1,8(a0)
				add.w	#16,a0
				dbra	d0,.loop

				move.l	#AI_AlienTeamWorkspace_vl,a0
				move.l	#29,d0
.loop2:
				move.l	#0,(a0)
				move.l	#-1,4(a0)
				move.l	#-1,8(a0)
				add.w	#16,a0
				dbra	d0,.loop2

				rts

ai_CheckDamage:
				moveq	#0,d2
				move.b	EntT_DamageTaken_b(a0),d2
				beq		.noscream

				sub.b	d2,EntT_HitPoints_b(a0)
				bgt		.not_dead_yet

				moveq	#0,d0
				move.b	EntT_TeamNumber_b(a0),d0
				blt.s	.no_team

				move.l	#AI_AlienTeamWorkspace_vl,a2
				asl.w	#4,d0
				add.w	d0,a2
				move.w	(a0),d0
				cmp.w	AI_WorkT_SeenBy_w(a2),d0
				bne.s	.no_team
				move.w	#-1,AI_WorkT_SeenBy_w(a2)

.no_team:
				cmp.b	#1,d2
				ble		.noexplode

				movem.l	d0-d7/a0-a6,-(a7)
				sub.l	Lvl_ObjectPointsPtr_l,a1
				add.l	#ObjRotated_vl,a1
				move.l	(a1),Aud_NoiseX_w
				move.w	#400,Aud_NoiseVol_w
				move.w	#14,Aud_SampleNum_w
				move.b	#1,Aud_ChannelPick_b
				clr.b	notifplaying
				st		backbeat
				move.w	(a0),IDNUM
				move.b	ALIENECHO,PlayEcho
				jsr		MakeSomeNoise

				movem.l	(a7)+,d0-d7/a0-a6
				movem.l	d0-d7/a0-a6,-(a7)
				move.w	#0,d0
				asr.w	#2,d2
				tst.w	d2
				bgt.s	.ko

				moveq	#1,d2

.ko:
				move.w	#31,d3
				jsr		Anim_ExplodeIntoBits

				movem.l	(a7)+,d0-d7/a0-a6
				cmp.b	#40,d2
				blt		.noexplode

				FREE_ENT	a0

				rts

.noexplode:
				movem.l	d0-d7/a0-a6,-(a7)
				sub.l	Lvl_ObjectPointsPtr_l,a1
				add.l	#ObjRotated_vl,a1
				move.l	(a1),Aud_NoiseX_w
				move.w	#200,Aud_NoiseVol_w
				move.w	screamsound,Aud_SampleNum_w
				move.b	#1,Aud_ChannelPick_b
				clr.b	notifplaying
				st		backbeat
				move.w	(a0),IDNUM
				move.b	ALIENECHO,PlayEcho
				jsr		MakeSomeNoise
				movem.l	(a7)+,d0-d7/a0-a6

				move.w	#25,EntT_Timer3_w(a0)
				move.w	ObjT_ZoneID_w(a0),EntT_ZoneID_w(a0)
				rts

.not_dead_yet:
				clr.b	EntT_DamageTaken_b(a0)
				movem.l	d0-d7/a0-a6,-(a7)
				sub.l	Lvl_ObjectPointsPtr_l,a1
				add.l	#ObjRotated_vl,a1
				move.l	(a1),Aud_NoiseX_w
				move.w	#200,Aud_NoiseVol_w
				move.w	screamsound,Aud_SampleNum_w
				move.b	#1,Aud_ChannelPick_b
				clr.b	notifplaying
				move.w	(a0),IDNUM
				st		backbeat
				move.b	ALIENECHO,PlayEcho
				jsr		MakeSomeNoise

				movem.l	(a7)+,d0-d7/a0-a6

.noscream:
				rts


ai_DoTorch:
				move.w	ALIENBRIGHT,d0
				bge.s	.nobright

				move.w	newx,d1
				move.w	newz,d2
				move.w	4(a0),d3
				ext.l	d3
				asl.l	#7,d3
				move.l	d3,Anim_BrightY_l
				move.w	EntT_CurrentAngle_w(a0),d4
				move.w	ObjT_ZoneID_w(a0),d3

				jsr		Anim_BrightenPointsAngle

.nobright:
				rts

ai_DoWalkAnim:
ai_DoAttackAnim:
				move.l	d0,-(a7)
				move.l	AlienAnimPtr_l,a6
				move.l	WorkspacePtr_l,a5
				moveq	#0,d1
				move.b	2(a5),d1
				bne.s	.notview

				moveq	#0,d1
				cmp.b	#1,AI_VecObj_w
				beq.s	.notview

				jsr		ViewpointToDraw

				add.w	d0,d0
				move.w	d0,d1

.notview:
				muls	#A_OptLen,d1
				add.l	d1,a6
				move.w	EntT_Timer2_w(a0),d1
				tst.b	1(a5)
				blt.s	.nospec

				move.b	1(a5),d1

.nospec:
				muls	#A_FrameLen,d1
				st		1(a5)
				move.b	(a5),ai_DoAction_b
				clr.b	(a5)
				move.b	3(a5),ai_FinishedAnim_b
				clr.b	3(a5)
				move.l	#0,8(a0)
				move.b	(a6,d1.w),9(a0)
				move.b	1(a6,d1.w),d0
				ext.w	d0
				bgt.s	.noflip
				move.b	#128,10(a0)
				neg.w	d0

.noflip:
				sub.w	#1,d0
				move.b	d0,11(a0)
				move.w	#0,ai_AnimFacing_w
				cmp.b	#1,AI_VecObj_w
				bne.s	.noanimface
				move.w	2(a6,d1.w),ai_AnimFacing_w

.noanimface:
				FREE_ENT_2	a0,ENT_PREV

				move.w	AUXOBJ,d3
				blt		.noaux

				move.b	8(a6,d1.w),d0
				blt		.noaux

				move.w	ObjT_ZoneID_w(a0),ObjT_ZoneID_w+ENT_PREV(a0)
				move.w	ObjT_ZoneID_w(a0),EntT_ZoneID_w+ENT_PREV(a0)
				move.w	4(a0),4+ENT_PREV(a0)
				move.b	ShotT_InUpperZone_b(a0),ShotT_InUpperZone_b+ENT_PREV(a0)
				move.b	9(a6,d1.w),d4
				move.b	10(a6,d1.w),d5
				ext.w	d4
				ext.w	d5
				add.w	d4,d4
				add.w	d5,d5
				move.w	d4,ShotT_AuxOffsetX_w+ENT_PREV(a0)
				move.w	d5,ShotT_AuxOffsetY_w+ENT_PREV(a0)
				move.l	GLF_DatabasePtr_l,a4
				move.l	a4,a2
				add.l	#GLFT_ObjectDefAnims_l,a4
				add.l	#GLFT_ObjectDefs,a2
				move.w	d3,d4
				muls	#O_AnimSize,d3
				muls	#ODefT_SizeOf_l,d4
				add.l	d4,a2
				add.l	d3,a4
				muls	#O_FrameStoreSize,d0
				cmp.w	#1,ODefT_GFXType_w(a2)
				blt.s	.bitmap
				beq.s	.vector

.glare:
				move.l  #0,OBJ_PREV+ObjT_YPos_l(a0) ; why if we are overwriting later?
				move.b	(a4,d0.w),d3
				ext.w	d3
				neg.w	d3
				move.w  d3,OBJ_PREV+ObjT_YPos_l(a0)
				move.b	1(a4,d0.w),OBJ_PREV+11(a0) ; hacks ?
				move.w	2(a4,d0.w),OBJ_PREV+6(a0)  ; hacks ?
				bra		.noaux

.vector:
				move.l  #0,OBJ_PREV+ObjT_YPos_l(a0)
				move.b	(a4,d0.w),OBJ_PREV+9(a0)    ; hacks?
				move.b	1(a4,d0.w),OBJ_PREV+11(a0)  ; hacks?
				move.w	#$ffff,OBJ_PREV+6(a0)
				bra		.noaux

.bitmap:
				move.l  #0,OBJ_PREV+ObjT_YPos_l(a0)
				move.b	(a4,d0.w),OBJ_PREV+9(a0)
				move.b	1(a4,d0.w),OBJ_PREV+11(a0)
				move.w	2(a4,d0.w),OBJ_PREV+6(a0)

.noaux:
				move.w	#-1,6(a0)
				cmp.b	#1,AI_VecObj_w
				beq.s	.nosize
				bgt.s	.setlight
				move.w	2(a6,d1.w),6(a0)
				move.l	(a7)+,d0
				rts

.nosize:

; move.l #$00090001,8(a0)

				move.l	(a7)+,d0
				rts

.setlight:
				move.w	2(a6,d1.w),6(a0)
				move.b	AI_VecObj_w,d1
				or.b	d1,10(a0)
				move.l	(a7)+,d0
				rts


ai_CheckAttackOnGround:
				move.l	Plr1_ZonePtr_l,a3
				moveq	#0,d1
				move.b	ZoneT_ControlPoint_w(a3),d1
				tst.b	Plr1_StoodInTop_b
				beq.s	.player_not_in_top
				move.b	ZoneT_ControlPoint_w+1(a3),d1

.player_not_in_top:
				move.w	d1,d3
				move.w	EntT_CurrentControlPoint_w(a0),d0
				cmp.w	d0,d1
				beq.s	.attack_player

				jsr		GetNextCPt

				cmp.w	d0,d3
				beq.s	.attack_player

.dont_attack_player:
				clr.b	d0
				rts

.attack_player:
				st		d0
				rts

ai_GetRoomCPT:
				move.l	objroom,a2
				moveq	#0,d0
				move.b	ZoneT_ControlPoint_w(a2),d0
				tst.b	ShotT_InUpperZone_b(a0)
				beq.s	.player_not_in_top

				move.b	ZoneT_ControlPoint_w+1(a2),d0

.player_not_in_top:
				move.w	d0,EntT_CurrentControlPoint_w(a0)
				rts


ai_CalcSqrt:
				tst.l	d2
				beq		.oksqr

				movem.l	d0/d1/d3-d7/a0-a6,-(a7)
				move.w	#31,d0

.findhigh:
				btst	d0,d2
				bne		.foundhigh
				dbra	d0,.findhigh

.foundhigh:
				asr.w	#1,d0
				clr.l	d3
				bset	d0,d3
				move.l	d3,d0

				move.w	d0,d1
				muls	d1,d1					; x*x
				sub.l	d2,d1					; x*x-a
				asr.l	#1,d1					; (x*x-a)/2
				divs	d0,d1					; (x*x-a)/2x
				sub.w	d1,d0					; second approx
				bgt		.stillnot0
				move.w	#1,d0

.stillnot0:
				move.w	d0,d1
				muls	d1,d1
				sub.l	d2,d1
				asr.l	#1,d1
				divs	d0,d1
				sub.w	d1,d0					; second approx
				bgt		.stillnot02
				move.w	#1,d0

.stillnot02:
				move.w	d0,d1
				muls	d1,d1
				sub.l	d2,d1
				asr.l	#1,d1
				divs	d0,d1
				sub.w	d1,d0					; second approx
				bgt		.stillnot03
				move.w	#1,d0

.stillnot03:
				move.w	d0,d2
				ext.l	d2
				movem.l	(a7)+,d0/d1/d3-d7/a0-a6

.oksqr:
				rts
