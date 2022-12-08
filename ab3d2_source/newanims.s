TypeOfSplat:	dc.w	0
BRIGHTY:		dc.l	0

BRIGHTENPOINTS:

				tst.b	LIGHTING
				bne.s	.dolight
				rts
.dolight:

; d0=brightness value
; d1=XPOS
; d2=ZPOS
; d3=ROOMNUMBER

				tst.w	d0
				bgt		DARKENPOINTS

				movem.l	d0-d7/a0-a6,-(a7)

				move.l	Lvl_ZoneAddsPtr_l,a0
				move.l	(a0,d3.w*4),a0
				add.l	Lvl_DataPtr_l,a0
				move.l	#CurrentPointBrights,a2
				move.l	Lvl_PointsPtr_l,a3
				move.l	Lvl_ZoneBorderPointsPtr_l,a4

				lea		ZoneT_ListOfGraph_w(a0),a1
BRIGHTPTS:
				move.w	(a1),d4
				blt		brightall

				move.l	Lvl_ZoneAddsPtr_l,a0
				move.l	(a0,d4.w*4),a0
				add.l	Lvl_DataPtr_l,a0

				add.w	#8,a1
				moveq	#9,d7

				muls	#20,d4

				lea		(a4,d4.w),a5
				move.l	#CurrentPointBrights,a2
				lea		(a2,d4.w*4),a2

; Do a room.

ROOMPTLOP
				move.w	(a5)+,d4
				blt		BRIGHTPTS

				move.w	(a3,d4.w*4),d5
				move.w	2(a3,d4.w*4),d6
				sub.w	d1,d5
				bgt.s	.okpos1
				neg.w	d5
.okpos1

				sub.w	d2,d6
				bgt.s	.okpos2
				neg.w	d6
.okpos2

				add.w	d6,d5

				move.l	BRIGHTY,d4
				cmp.l	ZoneT_Floor_l(a0),d4
				bgt		.noBRIGHT1
				cmp.l	ZoneT_Roof_l(a0),d4
				blt		.noBRIGHT1

				move.w	d5,d6
				move.l	ZoneT_Roof_l(a0),d4
				sub.l	BRIGHTY,d4
				bgt.s	.noBRIGHT2
				neg.l	d4
				asr.l	#7,d4
				add.w	d4,d6

				asr.w	#5,d6
				add.w	d0,d6

				bge.s	.noBRIGHT2
				tst.w	2(a2)
				bge.s	.okbr2
				neg.w	2(a2)
.okbr2:

				add.w	2(a2),d6
				cmp.w	#300,d6
				bge.s	.notoobr2
				move.w	#300,d6
.notoobr2:
				move.w	d6,2(a2)

.noBRIGHT2

				move.w	d5,d6
				move.l	ZoneT_Floor_l(a0),d4
				sub.l	BRIGHTY,d4
				blt.s	.noBRIGHT1
				asr.l	#7,d4
				add.w	d4,d6

				asr.w	#5,d6
				add.w	d0,d6

				bge.s	.noBRIGHT1
				tst.w	(a2)
				bge.s	.okbr1
				neg.w	(a2)
.okbr1:

				add.w	(a2),d6
				cmp.w	#300,d6
				bge.s	.notoobr1
				move.w	#300,d6
.notoobr1:
				move.w	d6,(a2)


.noBRIGHT1

				move.l	BRIGHTY,d4
				cmp.l	ZoneT_UpperFloor_l(a0),d4
				bgt		.noBRIGHT4
				cmp.l	ZoneT_UpperRoof_l(a0),d4
				blt		.noBRIGHT4

				move.w	d5,d6
				move.l	ZoneT_UpperFloor_l(a0),d4
				sub.l	BRIGHTY,d4
				blt.s	.noBRIGHT3
				asr.l	#7,d4
				add.w	d4,d6

				asr.w	#5,d6
				add.w	d0,d6

				bge.s	.noBRIGHT3
				tst.w	4(a2)
				bge.s	.okbr3
				neg.w	4(a2)
.okbr3:

				add.w	4(a2),d6
				cmp.w	#300,d6
				bge.s	.notoobr3
				move.w	#300,d6
.notoobr3:
				move.w	d6,4(a2)


.noBRIGHT3


				move.w	d5,d6
				move.l	ZoneT_UpperRoof_l(a0),d4
				sub.l	BRIGHTY,d4
				bgt.s	.noBRIGHT4
				neg.l	d4
				asr.l	#7,d4
				add.w	d4,d6

				asr.w	#5,d6
				add.w	d0,d6

				bge.s	.noBRIGHT4
				tst.w	6(a2)
				bge.s	.okbr4
				neg.w	6(a2)
.okbr4:

				add.w	6(a2),d6
				cmp.w	#300,d6
				bge.s	.notoobr4
				move.w	#300,d6
.notoobr4:
				move.w	d6,6(a2)

.noBRIGHT4

				addq	#8,a2

				dbra	d7,ROOMPTLOP

				bra		BRIGHTPTS

brightall:

				movem.l	(a7)+,d0-d7/a0-a6
				rts


BRIGHTENPOINTSANGLE:
; d0=brightness value
; d1=XPOS
; d2=ZPOS
; d3=ROOMNUMBER
; d4=ANGLE

				tst.b	LIGHTING
				bne.s	.dolight
				rts
.dolight:

				movem.l	d0-d7/a0-a6,-(a7)

				move.l	#SineTable,a0
				lea		(a0,d4.w),a6

				move.l	Lvl_ZoneAddsPtr_l,a0
				move.l	(a0,d3.w*4),a0
				add.l	Lvl_DataPtr_l,a0
				move.l	#CurrentPointBrights,a2
				move.l	Lvl_PointsPtr_l,a3
				move.l	Lvl_ZoneBorderPointsPtr_l,a4

				lea		ZoneT_ListOfGraph_w(a0),a1

BRIGHTPTSA:
				move.w	(a1),d4
				blt		brightallA
				move.l	Lvl_ZoneAddsPtr_l,a0
				move.l	(a0,d4.w*4),a0
				add.l	Lvl_DataPtr_l,a0

				add.w	#8,a1
				moveq	#9,d3

				muls	#20,d4

				lea		(a4,d4.w),a5
				move.l	#CurrentPointBrights,a2
				lea		(a2,d4.w*4),a2

ROOMPTLOPA
				move.w	(a5)+,d4
				blt		BRIGHTPTSA
				move.w	2(a3,d4.w*4),d5
				move.w	(a3,d4.w*4),d4

				sub.w	d1,d4
				move.w	d4,d6
				bgt.s	.okpos1
				neg.w	d4
.okpos1

				sub.w	d2,d5
				move.w	d5,d7
				bgt.s	.okpos2
				neg.w	d5
.okpos2

				movem.l	d0/d1/d2/d3/d4/d5,-(a7)

				move.w	(a6),d0
				move.w	2048(a6),d1
				muls	d7,d1
				muls	d6,d0
				add.l	d0,d1
				ble		BEHINDPT
				move.l	d1,d5
				neg.l	d5
				add.l	#30*65536,d5
				bge.s	.okkkkk
				moveq	#0,d5
.okkkkk

				move.w	(a6),d0
				move.w	2048(a6),d1
; ext.l d0
; ext.l d1
; asl.l #6,d1
; asl.l #6,d0
; swap d0
; swap d1
; neg.w d0
; neg.w d1
; add.w d6,d0
; add.w d7,d1

				muls	d0,d7
				muls	d1,d6
				sub.l	d6,d7
				bgt.s	.okkk
				neg.l	d7
.okkk

				add.l	d5,d7
				asl.l	#2,d7
				swap	d7

				movem.l	(a7)+,d0/d1/d2/d3/d4/d5

				add.w	d7,d5
				add.w	d4,d5

				move.l	BRIGHTY,d4
				cmp.l	ZoneT_Floor_l(a0),d4
				bgt		.noBRIGHT1
				cmp.l	ZoneT_Roof_l(a0),d4
				blt		.noBRIGHT1

				move.w	d5,d6
				move.l	ZoneT_Roof_l(a0),d4
				sub.l	BRIGHTY,d4
				bgt.s	.noBRIGHT2
				neg.l	d4
				asr.l	#7,d4
				add.w	d4,d6

				asr.w	#5,d6
				add.w	d0,d6

				bge.s	.noBRIGHT2
				tst.w	2(a2)
				bge.s	.okbr2
				neg.w	2(a2)
.okbr2:
				add.w	2(a2),d6
				cmp.w	#300,d6
				bge.s	.notoobr2
				move.w	#300,d6
.notoobr2:
				move.w	d6,2(a2)
.noBRIGHT2


				move.w	d5,d6
				move.l	ZoneT_Floor_l(a0),d4
				sub.l	BRIGHTY,d4
				blt.s	.noBRIGHT1
				asr.l	#7,d4
				add.w	d4,d6

				asr.w	#5,d6
				add.w	d0,d6

				bge.s	.noBRIGHT1
				tst.w	(a2)
				bge.s	.okbr1
				neg.w	(a2)
.okbr1:
				add.w	(a2),d6
				cmp.w	#300,d6
				bge.s	.notoobr1
				move.w	#300,d6
.notoobr1:
				move.w	d6,(a2)
.noBRIGHT1

				move.l	BRIGHTY,d4
				cmp.l	ZoneT_UpperFloor_l(a0),d4
				bgt		.noBRIGHT4
				cmp.l	ZoneT_UpperRoof_l(a0),d4
				blt		.noBRIGHT4

				move.w	d5,d6
				move.l	ZoneT_UpperFloor_l(a0),d4
				sub.l	BRIGHTY,d4
				blt.s	.noBRIGHT3

				asr.l	#7,d4
				add.w	d4,d6

				asr.w	#5,d6
				add.w	d0,d6

				bge.s	.noBRIGHT3
				tst.w	4(a2)
				bge.s	.okbr3
				neg.w	4(a2)
.okbr3:
				add.w	4(a2),d6
				cmp.w	#300,d6
				bge.s	.notoobr3
				move.w	#300,d6
.notoobr3:
				move.w	d6,4(a2)
.noBRIGHT3


				move.w	d5,d6
				move.l	ZoneT_UpperRoof_l(a0),d4
				sub.l	BRIGHTY,d4
				bgt.s	.noBRIGHT4
				neg.l	d4
				asr.l	#7,d4
				add.w	d4,d6

				asr.w	#5,d6
				add.w	d0,d6

				bge.s	.noBRIGHT4
				tst.w	6(a2)
				bge.s	.okbr4
				neg.w	6(a2)
.okbr4:
				add.w	6(a2),d6
				cmp.w	#300,d6
				bge.s	.notoobr4
				move.w	#300,d6
.notoobr4:
				move.w	d6,6(a2)
.noBRIGHT4

				addq	#8,a2

				dbra	d3,ROOMPTLOPA

				bra		BRIGHTPTS

BEHINDPT:
				movem.l	(a7)+,d0/d1/d2/d3/d4/d5
				addq	#8,a2

				dbra	d7,ROOMPTLOPA

				bra		BRIGHTPTSA

brightallA:

				movem.l	(a7)+,d0-d7/a0-a6
				rts

DARKENPOINTS
				movem.l	d0-d7/a0-a6,-(a7)

				move.l	Lvl_ZoneAddsPtr_l,a0
				move.l	(a0,d3.w*4),a0
				add.l	Lvl_DataPtr_l,a0
				move.l	#CurrentPointBrights,a2
				move.l	Lvl_PointsPtr_l,a3

				move.l	a0,a1
				add.w	ZoneT_Points_w(a0),a1
DARKPTS:
				move.w	(a1)+,d4
				blt.s	DARKall
				move.w	(a3,d4.w*4),d5
				move.w	2(a3,d4.w*4),d6
				sub.w	d1,d5
				bgt.s	.okpos1
				neg.w	d5
.okpos1

				sub.w	d2,d6
				bgt.s	.okpos2
				neg.w	d6
.okpos2

				add.w	d5,d6
				asr.w	#5,d6
				add.w	d0,d6
				ble.s	DARKPTS

				add.w	d6,(a2,d4.w*4)
				add.w	d6,2(a2,d4.w*4)
				bra.s	DARKPTS

DARKall:

				movem.l	(a7)+,d0-d7/a0-a6
				rts

Flash:

; D0=number of a zone, D1=brightness change

				cmp.w	#-20,d1
				bgt.s	.okflash
				move.w	#-20,d1
.okflash:

				movem.l	d0/a0/a1,-(a7)

				move.l	#CurrentPointBrights,a1

				move.l	Lvl_ZoneAddsPtr_l,a0
				move.l	(a0,d0.w*4),a0
				add.l	Lvl_DataPtr_l,a0

				move.l	a0,-(a7)

				add.w	ZoneT_Points_w(a0),a0
flashpts:
				move.w	(a0)+,d2
				blt.s	flashedall
				add.w	d1,(a1,d2.w*4)
				add.w	d1,2(a1,d2.w*4)
				bra		flashpts

flashedall:
				move.l	(a7)+,a0

				move.l	#ZoneBrightTable,a1
				add.w	d1,(a1,d0.w*4)
				add.w	d1,2(a1,d0.w*4)

				add.l	#ZoneT_ListOfGraph_w,a0

doemall:
				move.w	(a0),d0
				blt.s	doneemall
				add.w	d1,(a1,d0.w*4)
				add.w	d1,2(a1,d0.w*4)
				addq	#8,a0
				bra.s	doemall

doneemall:
				movem.l	(a7)+,d0/a0/a1

				rts

prot2:			dc.w	0

radius:			dc.w	0

ExplodeIntoBits:

				move.w	d3,radius

				cmp.w	#7,d2
				ble.s	.oksplut
				move.w	#7,d2
.oksplut:

				move.l	NastyShotDataPtr_l,a5
				move.w	#19,d1
.findeight
				move.w	12(a5),d0
				blt.s	.gotonehere
				adda.w	#64,a5
				dbra	d1,.findeight
				rts

.gotonehere

				move.b	#0,ShotT_Power_w(a5)


				move.l	Lvl_ObjectPointsPtr_l,a2
				move.w	(a5),d3
				lea		(a2,d3.w*8),a2
; jsr GetRand
; lsr.w #4,d0
; move.w radius,d1
; and.w d1,d0
; asr.w #1,d1
; sub.w d1,d0
				move.w	newx,d0
				move.w	d0,(a2)
; jsr GetRand
; lsr.w #4,d0
; move.w radius,d1
; and.w d1,d0
; asr.w #1,d1
; sub.w d1,d0
				move.w	newz,d0
				move.w	d0,4(a2)

				move.b	#2,16(a2)

				jsr		GetRand
				and.w	#8190,d0
				move.l	#SineTable,a2
				adda.w	d0,a2
				move.w	(a2),d3
				move.w	2048(a2),d4
				Jsr		GetRand
				and.w	#3,d0
				add.w	#1,d0
				ext.l	d3
				ext.l	d4
				asl.l	d0,d3
				asl.l	d0,d4
				move.l	EntT_ImpactX_w(a0),d0
				swap	d4
				asr.w	#1,d0
				add.w	d0,d4
				swap	d0
				move.w	d4,ShotT_VelocityZ_w(a5)
				swap	d3
				asr.w	#1,d0
				add.w	d0,d3
				move.w	d3,ShotT_VelocityX_w(a5)
				jsr		GetRand
				and.w	#1023,d0
				add.w	#2*128,d0
				neg.w	d0
				move.w	d0,ShotT_VelocityY_w(a5)
				move.l	#0,EntT_EnemyFlags_l(a5)
				move.w	12(a0),12(a5)

; jsr GetRand
; lsr.w #4,d0
; move.w radius,d1
; and.w d1,d0
; asr.w #1,d1
; sub.w d1,d0
				move.w	4(a0),d0
				move.w	d0,4(a5)
				add.w	#6,d0
				ext.l	d0
				asl.l	#7,d0

				move.l	d0,ShotT_AccYPos_w(a5)
; move.w d2,d0
; and.w #3,d0
; add.w #50,d0
				move.b	TypeOfSplat,ShotT_Size_b(a5)
; move.w #40,ShotT_Gravity_w(a5)
				move.w	#0,ShotT_Flags_w(a5)
				move.w	#0,ShotT_Lifetime_w(a5)
				clr.b	ShotT_Status_b(a5)
				move.b	ShotT_InUpperZone_b(a0),ShotT_InUpperZone_b(a5)
				st		ShotT_Worry_b(a5)
				adda.w	#64,a5
				sub.w	#1,d2
				blt.s	.gotemall
				dbra	d1,.findeight

.gotemall

				rts

brightanim:

				move.l	#BrightAnimTable,a1
				move.l	#BrightAnimPtrs,a3
				move.l	#BrightAnimStarts,a4
dobrightanims
				move.l	(a3),d0
				blt		nomoreanims
				move.l	d0,a2
				move.w	(a2)+,d0
				cmp.w	#999,d0
				bne.s	itsabright
				move.l	(a4),a2
				move.w	(a2)+,d0
itsabright:
				move.l	a2,(a3)+
				addq	#4,a4
				move.w	d0,(a1)+
				bra.s	dobrightanims

nomoreanims:
				rts

BrightAnimTable: ds.w	20
BrightAnimPtrs:
				dc.l	PulseANIM1
				dc.l	PulseANIM2
				dc.l	PulseANIM3
				dc.l	PulseANIM4
				dc.l	PulseANIM5
				dc.l	FlickerANIM
				dc.l	FireFlickerANIM
				dc.l	-1

BrightAnimStarts:
				dc.l	PulseANIM1
				dc.l	PulseANIM2
				dc.l	PulseANIM3
				dc.l	PulseANIM4
				dc.l	PulseANIM5
				dc.l	FlickerANIM
				dc.l	FireFlickerANIM

PulseANIM1:
				dc.w	1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20
				dc.w	20,19,18,17,16,15,14,13,12,11,10,9,8,7,6,5,4,3,2,1
				dc.w	999

PulseANIM2:
				dc.w	9,10,11,12,13,14,15,16,17,18,19,20
				dc.w	20,19,18,17,16,15,14,13,12,11,10,9,8,7,6,5,4,3,2,1
				dc.w	1,2,3,4,5,6,7,8
				dc.w	999

PulseANIM3:
				dc.w	17,18,19,20
				dc.w	20,19,18,17,16,15,14,13,12,11,10,9,8,7,6,5,4,3,2,1
				dc.w	1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16
				dc.w	999


PulseANIM4:

				dc.w	16,15,14,13,12,11,10,9,8,7,6,5,4,3,2,1
				dc.w	1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,20,19,18,17

				dc.w	999

PulseANIM5:

				dc.w	8,7,6,5,4,3,2,1
				dc.w	1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,20,19,18,17,16,15,14,13,12,11,10,9
				dc.w	999


FlickerANIM:
				dcb.w	20,20
				dc.w	1
				dcb.w	30,20
				dc.w	1
				dcb.w	5,20
				dc.w	1
				dc.w	999

FireFlickerANIM:
				dc.w	-10,-9,-6,-10,-6,-5,-5,-7,-5,-10,-9,-8,-7,-5,-5,-5,-5
				dc.w	-5,-5,-5,-5,-6,-7,-8,-9,-5,-10,-9,-10,-6,-5,-5,-5,-5,-5
				dc.w	-5,-5
				dc.w	999

;realtab:
; dc.l prot1-78935450
; dc.l prot2-78935450
; dc.l prot3-78935450
; dc.l prot4-78935450
; dc.l prot5-78935450
; dc.l prot6-78935450
; dc.l prot7-78935450
; dc.l prot8-78935450
; dc.l prot9-78935450
; dc.l protA-78935450

objvels:		ds.l	8

FramesToDraw:	dc.w	0
TempFrames:		dc.w	0

TimeToNoise:	dc.w	0

ODDEVEN:		dc.w	0

BACKSFX:

				move.w	TempFrames,d0
				sub.w	d0,TimeToNoise
				bgt		.nosfx

				jsr		GetRand
				lsr.w	#3,d0
				and.w	#127,d0
				add.w	#100,d0
				move.w	d0,TimeToNoise

				move.l	Roompt,a0

				add.w	ODDEVEN,a0

				move.w	#2,d0
				sub.w	ODDEVEN,d0
				move.w	d0,ODDEVEN

				move.w	ZoneT_BackSFXMask_w(a0),d1		; mask for sfx
				beq		.nosfx

				jsr		GetRand
				lsr.w	#3,d0

.notfound
				addq	#1,d0
				and.w	#15,d0
				btst	d0,d1
				beq.s	.notfound

				move.l	GLF_DatabasePtr_l,a0
				add.l	#GLFT_AmbientSFX_l,a0
				move.w	(a0,d0.w*2),Samplenum
				move.w	#$fff0,IDNUM
				st.b	notifplaying
				move.l	#0,Noisex
				move.b	#0,PlayEcho
				jsr		GetRand
				and.w	#15,d0
				add.w	#32,d0
				move.w	d0,Noisevol

				jsr		MakeSomeNoise

.nosfx:

				rts

objmoveanim:

				move.l	Plr1_RoomPtr_l,a0
				move.w	(a0),Plr1_Zone_w
				move.l	Plr2_RoomPtr_l,a0
				move.w	(a0),Plr2_Zone_w

				cmp.b	#PLR_SINGLE,Plr_MultiplayerType_b
				bne.s	.okp2
				move.w	#-5,Plr2_Zone_w
.okp2:

				move.w	#0,AI_Player1NoiseVol_w
				move.w	#0,AI_Player2NoiseVol_w

				move.l	#AI_BoredomSpace_vl,AI_BoredomPtr_l

				bsr		BACKSFX

				bsr		Player1Shot
				bsr		Player2Shot
; bsr SwitchRoutine
				bsr		ObjectHandler
				bsr		DoorRoutine


				move.w	#0,Plr1_FloorSpd_w
				move.w	#0,Plr2_FloorSpd_w

				bsr		LiftRoutine
				cmp	#0,animtimer		;animtimer decriment moved to VBlankInterrupt:
				bgt.s	.notzero
				bsr		brightanim
				move.w	#5,animtimer	;was 2 AL
				move.l	otherrip,d0		;what are these for?
				move.l	RipTear,otherrip	;""
				move.l	d0,RipTear		;""
.notzero:

				rts

******************************

tstdir:			dc.w	0

liftheighttab:	ds.w	40
doorheighttab:	ds.w	40
PLR1_stoodonlift: dc.b	0
PLR2_stoodonlift: dc.b	0
liftattop:		dc.b	0
liftatbot:		dc.b	0


DoorLocks:		dc.w	0
LiftLocks:		dc.w	0

ZoneBrightTable:
				ds.l	300

DoWaterAnims:

				move.w	#20,d0
wateranimlop:
				move.l	(a0)+,d1
				move.l	(a0)+,d2
				move.l	(a0),d3
				move.w	4(a0),d4
				move.w	d4,d5
				muls	TempFrames,d5
				add.l	d5,d3
				cmp.l	d1,d3
				bgt.s	waternotattop

				move.l	d1,d3
				move.w	#128,d4
				bra		waterdone

waternotattop:

				cmp.l	d2,d3
				blt.s	waterdone

				move.l	d2,d3
				move.w	#-128,d4

waterdone:

				move.l	d3,(a0)+
				move.w	d4,(a0)+
				move.l	d3,d1
morezones:
				move.w	(a0)+,d2
				bge.s	okzone


				dbra	d0,wateranimlop
				rts

okzone:

				move.l	(a0)+,a1
				add.l	Lvl_GraphicsPtr_l,a1
				move.l	d1,d3
				asr.l	#6,d3
				move.w	d3,2(a1)
				move.l	Lvl_ZoneAddsPtr_l,a1
				move.l	(a1,d2.w*4),a1
				add.l	Lvl_DataPtr_l,a1
				move.l	d1,ZoneT_Water_l(a1)

				bra.s	morezones

				rts

FLOORMOVESPD:	dc.w	0

				even
LiftRoutine:

				move.w	#-1,ThisDoor
				move.l	Lvl_LiftDataPtr_l,a0
				move.l	#liftheighttab,a6

doalift:
				add.w	#1,ThisDoor
				move.w	(a0)+,d0				; bottom of lift movement
				cmp.w	#999,d0
				bne		notallliftsdone
				move.w	#999,(a6)

				move.w	#0,LiftLocks

				bsr		DoWaterAnims

				rts

notallliftsdone:
				move.w	(a0)+,d1				; top of lift movement.

				move.w	(a0)+,OPENINGSPEED
				neg.w	OPENINGSPEED
				move.w	(a0)+,CLOSINGSPEED
				move.w	(a0)+,STAYOPENFOR
				move.w	(a0)+,OPENINGSFX
				move.w	(a0)+,CLOSINGSFX
				move.w	(a0)+,OPENSFX
				move.w	(a0)+,CLOSEDSFX
				subq.w	#1,OPENINGSFX
				subq.w	#1,CLOSINGSFX
				subq.w	#1,OPENSFX
				subq.w	#1,CLOSEDSFX
				move.w	(a0)+,d2
				move.w	(a0)+,d3
				sub.w	Plr1_TmpXOff_l,d2
				sub.w	Plr1_TmpZOff_l,d3
				move.w	cosval,d4
				move.w	sinval,d5

				muls	d2,d4
				muls	d3,d5
				sub.l	d5,d4
				add.l	d4,d4
				swap	d4
				move.w	d4,Noisex

				move.w	sinval,d4
				move.w	cosval,d5

				muls	d2,d4
				muls	d3,d5
				sub.l	d5,d4
				add.l	d4,d4
				swap	d4
				move.w	d4,Noisez

				move.w	(a0),d3
				move.w	d3,(a6)+
				move.w	2(a0),d2

				move.w	8(a0),d7
				move.l	Lvl_ZoneAddsPtr_l,a1
				move.l	(a1,d7.w*4),a1
				add.l	Lvl_DataPtr_l,a1
				move.b	ZoneT_Echo_b(a1),PlayEcho

				move.w	d2,d7					; speed of movement.

				move.w	d2,FLOORMOVESPD

				muls	TempFrames,d2
				add.w	d2,d3
				move.w	d7,d2
				cmp.w	d3,d0
				sle		liftatbot
				bgt.s	.nolower

				tst.w	d2
				beq.s	.nonoise3
				move.w	#50,Noisevol
				move.w	CLOSEDSFX,Samplenum
				blt.s	.nonoise3
				move.b	#1,chanpick
				clr.b	notifplaying
				move.w	#$fffd,IDNUM
				movem.l	a0/a3/d0/d1/d2/d3/d6/d7,-(a7)
				jsr		MakeSomeNoise
				movem.l	(a7)+,a0/a3/d0/d1/d2/d3/d6/d7
.nonoise3:

				moveq	#0,d2
				move.w	d0,d3
.nolower:

				cmp.w	d3,d1
				sge		liftattop
				blt.s	.noraise

				tst.w	d2
				beq.s	.nonoise
				move.w	#0,(a6)
				move.w	#50,Noisevol
				move.w	OPENSFX,Samplenum
				blt.s	.nonoise
				move.b	#1,chanpick
				clr.b	notifplaying
				move.w	#$fffd,IDNUM
				movem.l	a0/a3/d0/d1/d2/d3/d6/d7,-(a7)
				jsr		MakeSomeNoise
				movem.l	(a7)+,a0/a3/d0/d1/d2/d3/d6/d7
.nonoise

				moveq	#0,d2
				move.w	d1,d3
.noraise:

				sub.w	d3,d0
				cmp.w	#15*16,d0
				slt		d6

				move.w	d3,(a0)+
				move.l	a0,a5
				move.w	d2,(a0)+
				move.w	d2,d7

				move.l	(a0)+,a1
				add.l	Lvl_GraphicsPtr_l,a1
				asr.w	#2,d3
				move.w	d3,d0
				asl.w	#2,d0
				move.w	d0,2(a1)
				move.w	d3,d0
				muls	#256,d3
				move.w	(a0)+,d5

				move.l	Lvl_ZoneAddsPtr_l,a1
				move.l	(a1,d5.w*4),a1
				add.l	Lvl_DataPtr_l,a1
				move.w	(a1),d5
				move.l	Plr1_RoomPtr_l,a3
				move.l	d3,2(a1)
				neg.w	d0

				cmp.w	(a3),d5
				seq		PLR1_stoodonlift
				bne.s	.nosetfloorspd1

				move.w	FLOORMOVESPD,Plr1_FloorSpd_w

.nosetfloorspd1:

				move.l	Plr2_RoomPtr_l,a3
				cmp.w	(a3),d5
				seq		PLR2_stoodonlift
				bne.s	.nosetfloorspd2

				move.w	FLOORMOVESPD,Plr2_FloorSpd_w

.nosetfloorspd2:

				move.w	(a0)+,d2				; conditions
; and.w Conditions,d2
; cmp.w -2(a0),d2
				move.w	ThisDoor,d2
				move.w	LiftLocks,d5
				btst	d2,d5
				beq.s	.satisfied

				move.w	(a0)+,d5

.dothesimplething:
				move.l	Lvl_FloorLinesPtr_l,a3
.simplecheck:
				move.w	(a0)+,d5
				blt		nomoreliftwalls
				asl.w	#4,d5
				lea		(a3,d5.w),a4
				move.w	#0,14(a4)
				move.l	(a0)+,a1
				add.l	Lvl_GraphicsPtr_l,a1
				move.l	(a0)+,a2
				adda.w	d0,a2
				move.l	a2,10(a1)
				move.l	d3,20(a1)
				bra.s	.simplecheck
				bra		nomoreliftwalls

.satisfied:

				move.l	Lvl_FloorLinesPtr_l,a3
				moveq	#0,d4
				moveq	#0,d5
				move.b	(a0)+,d4
				move.b	(a0)+,d5
				tst.b	liftattop
				bne		tstliftlower
				tst.b	liftatbot
				bne		tstliftraise
				move.w	#0,d1

backfromlift

				and.w	#255,d0

liftwalls:
				move.w	(a0)+,d5
				blt		nomoreliftwalls

				asl.w	#4,d5
				lea		(a3,d5.w),a4
				move.w	14(a4),d4
				move.w	#$8000,14(a4)
				and.w	d1,d4
				beq.s	.nothinghit
				move.w	d7,(a5)
				move.w	#50,Noisevol
				move.w	ACTIONNOISE,Samplenum
				blt.s	.nothinghit
				move.b	#1,chanpick
				st		notifplaying
				move.w	#$fffe,IDNUM
				movem.l	a0/a3/a4/d0/d1/d2/d3/d6/d7,-(a7)
				jsr		MakeSomeNoise
				movem.l	(a7)+,a0/a3/a4/d0/d1/d2/d3/d6/d7
.nothinghit:
				move.l	(a0)+,a1
				add.l	Lvl_GraphicsPtr_l,a1
				move.l	(a0)+,a2
				adda.w	d0,a2
				move.l	a2,10(a1)
				move.l	d3,20(a1)
				bra		liftwalls

nomoreliftwalls
				bra		doalift

				rts

tstliftlower:
				move.w	CLOSINGSFX,ACTIONNOISE
				cmp.b	#1,d5
				blt.s	lift0
				beq.s	lift1
				cmp.b	#3,d5
				blt.s	lift2
				beq.s	lift3

lift0:

				moveq	#0,d1
				tst.b	Plr1_TmpSpcTap_b
				beq.s	.noplr1
				move.w	#%100000000,d1
				move.w	CLOSINGSPEED,d7
				tst.b	PLR1_stoodonlift
				beq.s	.noplr1
				move.w	#$8000,d1
				bra		backfromlift

.noplr1:
				tst.b	Plr2_TmpSpcTap_b
				beq.s	.noplr2
				or.w	#%100000000000,d1
				move.w	CLOSINGSPEED,d7
				tst.b	PLR2_stoodonlift
				beq.s	.noplr2
				move.w	#$8000,d1
				bra		backfromlift

.noplr2:
				bra		backfromlift

lift1:
				move.w	CLOSINGSPEED,d7
				tst.b	PLR1_stoodonlift
				bne.s	lift1b
				tst.b	PLR2_stoodonlift
				bne.s	lift1b
				move.w	#%100100000000,d1
				bra		backfromlift
lift1b:
				move.w	#$8000,d1
				bra		backfromlift

lift2:
				move.w	#$8000,d1
				move.w	CLOSINGSPEED,d7
				bra		backfromlift

lift3:
				move.w	#$0,d1
				bra		backfromlift

tstliftraise:
				move.w	OPENINGSFX,ACTIONNOISE
				cmp.b	#1,d4
				blt.s	rlift0
				beq.s	rlift1
				cmp.b	#3,d4
				blt.s	rlift2
				beq.s	rlift3

rlift0:

				moveq	#0,d1
				tst.b	Plr1_TmpSpcTap_b
				beq.s	.noplr1
				move.w	#%100000000,d1
				move.w	OPENINGSPEED,d7
				tst.b	PLR1_stoodonlift
				beq.s	.noplr1
				move.w	#$8000,d1
				bra		backfromlift

.noplr1:
				tst.b	Plr2_TmpSpcTap_b
				beq.s	.noplr2
				or.w	#%100000000000,d1
				move.w	OPENINGSPEED,d7
				tst.b	PLR2_stoodonlift
				beq.s	.noplr2
				move.w	#$8000,d1
				bra		backfromlift

.noplr2:

				bra		backfromlift

rlift1:
				move.w	OPENINGSPEED,d7
				tst.b	PLR1_stoodonlift
				bne.s	rlift1b
				tst.b	PLR2_stoodonlift
				bne.s	rlift1b
				move.w	#%100100000000,d1
				bra		backfromlift
rlift1b:
				move.w	#$8000,d1
				bra		backfromlift

rlift2:
				move.w	#$8000,d1
				move.w	OPENINGSPEED,d7
				bra		backfromlift

rlift3:
				move.w	#$0,d1
				bra		backfromlift


animtimer:		dc.w	0


doordir:		dc.w	-1
doorpos:		dc.w	-9
dooropen:		dc.b	0
doorclosed:		dc.b	0
ThisDoor:		dc.w	0
OPENINGSPEED:	dc.w	0
CLOSINGSPEED:	dc.w	0
STAYOPENFOR:	dc.w	0
OPENINGSFX:		dc.w	0
CLOSINGSFX:		dc.w	0
OPENSFX:		dc.w	0
CLOSEDSFX:		dc.w	0

				even
				DoorRoutine:

				move.l	#doorheighttab,a6
				move.l	Lvl_DoorDataPtr_l,a0
				move.w	#-1,ThisDoor

doadoor:

				add.w	#1,ThisDoor
				move.w	(a0)+,d0				; bottom of door movement
				cmp.w	#999,d0
				bne		notalldoorsdone
				move.w	#999,(a6)
				move.w	#0,DoorLocks
				rts
notalldoorsdone:
				move.w	(a0)+,d1				; top of door movement.

				move.w	(a0)+,OPENINGSPEED
				neg.w	OPENINGSPEED
				move.w	(a0)+,CLOSINGSPEED
				move.w	(a0)+,STAYOPENFOR
				move.w	(a0)+,OPENINGSFX
				move.w	(a0)+,CLOSINGSFX
				move.w	(a0)+,OPENSFX
				move.w	(a0)+,CLOSEDSFX
				subq.w	#1,OPENINGSFX
				subq.w	#1,CLOSINGSFX
				subq.w	#1,OPENSFX
				subq.w	#1,CLOSEDSFX
				move.w	(a0)+,d2
				move.w	(a0)+,d3
				sub.w	Plr1_TmpXOff_l,d2
				sub.w	Plr1_TmpZOff_l,d3
				move.w	cosval,d4
				move.w	sinval,d5

				muls	d2,d4
				muls	d3,d5
				sub.l	d5,d4
				add.l	d4,d4
				swap	d4
				move.w	d4,Noisex

				move.w	sinval,d4
				move.w	cosval,d5

				muls	d2,d4
				muls	d3,d5
				sub.l	d5,d4
				add.l	d4,d4
				swap	d4
				move.w	d4,Noisez

				move.w	(a0),d3
				move.w	2(a0),d2

				move.w	8(a0),d7
				move.l	Lvl_ZoneAddsPtr_l,a1
				move.l	(a1,d7.w*4),a1
				add.l	Lvl_DataPtr_l,a1
				move.b	ZoneT_Echo_b(a1),PlayEcho

				muls	TempFrames,d2
				add.w	d2,d3
				move.w	2(a0),d2
				cmp.w	d3,d0
				sle		doorclosed
				bgt.s	nolower

				tst.w	d2
				beq.s	.nonoise
				move.w	#50,Noisevol
				move.w	CLOSEDSFX,Samplenum
				blt.s	.nonoise
				move.b	#1,chanpick
				clr.b	notifplaying
				move.w	#$fffd,IDNUM
				movem.l	a0/a3/d0/d1/d2/d3/d6/d7,-(a7)
				jsr		MakeSomeNoise
				movem.l	(a7)+,a0/a3/d0/d1/d2/d3/d6/d7
.nonoise

				moveq	#0,d2
				move.w	d3,d0

nolower:

				cmp.w	d3,d1
				sge		dooropen
				blt.s	noraise


				tst.w	d2
				beq.s	.nonoise
				move.w	#0,(a6)
				move.w	#50,Noisevol
				move.w	OPENSFX,Samplenum
				blt.s	.nonoise
				move.b	#1,chanpick
				clr.b	notifplaying
				move.w	#$fffd,IDNUM
				movem.l	a0/a3/d0/d1/d2/d3/d6/d7,-(a7)
				jsr		MakeSomeNoise
				movem.l	(a7)+,a0/a3/d0/d1/d2/d3/d6/d7
.nonoise

				move.w	d1,d3
				moveq	#0,d2
noraise:

NOTMOVING:

				sub.w	d3,d0
				cmp.w	#15*16,d0
				sge		d6

				move.w	d3,(a0)+
				move.l	a0,a5
				move.w	d2,(a0)+
				move.w	d2,d7

				move.l	(a0)+,a1
				add.l	Lvl_GraphicsPtr_l,a1
				asr.w	#2,d3
				move.w	d3,d0
				asl.w	#2,d0
				move.w	d0,2(a1)
				move.w	d3,d0
				muls	#256,d3
				move.l	Lvl_ZoneAddsPtr_l,a1
				move.w	(a0)+,d5


				move.l	(a1,d5.w*4),a1
				add.l	Lvl_DataPtr_l,a1
				move.l	d3,6(a1)
				neg.w	d0
				and.w	#255,d0
; add.w #64,d0

				cmp.w	Plr2_Zone_w,d5
				beq.s	.gobackup
				cmp.w	Plr1_Zone_w,d5
				bne.s	NotGoBackUp
.gobackup:
				tst.b	dooropen
				bne.s	NotGoBackUp
				tst.w	d2
				blt.s	NotGoBackUp
				move.w	#-16,d7
				move.w	#$8000,d1
				move.w	(a0)+,d2
				move.w	(a0)+,d5
				bra		backfromtst
NotGoBackUp:

				move.w	(a0)+,d2				; conditions
; and.w Conditions,d2
				move.w	ThisDoor,d2
				move.w	DoorLocks,d5
				btst	d2,d5
				beq.s	satisfied

				move.w	(a0)+,d5

dothesimplething:
				move.l	Lvl_FloorLinesPtr_l,a3
simplecheck:
				move.w	(a0)+,d5
				blt		nomoredoorwalls
				asl.w	#4,d5
				lea		(a3,d5.w),a4
				move.w	#0,14(a4)
				move.l	(a0)+,a1
				add.l	Lvl_GraphicsPtr_l,a1
				move.l	(a0)+,a2
				adda.w	d0,a2
				move.l	a2,10(a1)
				move.l	d3,24(a1)
				bra.s	simplecheck
				bra		nomoredoorwalls


satisfied:

				moveq	#0,d4
				moveq	#0,d5
				move.b	(a0)+,d5
				move.b	(a0)+,d4
				tst.b	dooropen
				bne		tstdoortoclose
				tst.b	doorclosed
				bne		tstdoortoopen
				move.w	#$0,d1

backfromtst:

				move.l	Lvl_FloorLinesPtr_l,a3

doorwalls:
				move.w	(a0)+,d5
				blt.s	nomoredoorwalls
				asl.w	#4,d5
				lea		(a3,d5.w),a4
				move.w	14(a4),d4
				move.w	#$8000,14(a4)
				and.w	d1,d4
				beq.s	nothinghit
				move.w	d7,(a5)
				move.w	#50,Noisevol
				move.w	ACTIONNOISE,Samplenum
				blt.s	nothinghit
				move.b	#1,chanpick
				clr.b	notifplaying
				move.w	#$fffd,IDNUM
				movem.l	a0/a3/d0/d1/d2/d3/d6/d7,-(a7)
				jsr		MakeSomeNoise
				movem.l	(a7)+,a0/a3/d0/d1/d2/d3/d6/d7
nothinghit:
				move.l	(a0)+,a1
				add.l	Lvl_GraphicsPtr_l,a1
				move.l	(a0)+,a2
				adda.w	d0,a2
				move.l	a2,10(a1)
				move.l	d3,24(a1)
				bra.s	doorwalls

nomoredoorwalls
				addq	#2,a6
				bra		doadoor

				rts

ACTIONNOISE:	dc.w	0

tstdoortoopen:
				move.w	OPENINGSFX,ACTIONNOISE

				cmp.w	#1,d5
				blt.s	door0
				beq.s	door1
				cmp.w	#3,d5
				blt.s	door2
				beq.s	door3
				cmp.w	#5,d5
				blt.s	door4
				beq.s	door5

door0:

				move.w	#$0,d1
				tst.b	Plr1_TmpSpcTap_b
				beq.s	.noplr1
				move.w	#%100000000,d1
.noplr1:
				tst.b	Plr2_TmpSpcTap_b
				beq.s	.noplr2
				or.w	#%100000000000,d1
.noplr2:
				move.w	OPENINGSPEED,d7
				bra		backfromtst

door1:
				move.w	#%100100000000,d1
				move.w	OPENINGSPEED,d7
				bra		backfromtst

door2:
				move.w	#%10000000000,d1
				move.w	OPENINGSPEED,d7
				bra		backfromtst

door3:
				move.w	#%1000000000,d1
				move.w	OPENINGSPEED,d7
				bra		backfromtst

door4:
				move.w	#$8000,d1
				move.w	OPENINGSPEED,d7
				bra		backfromtst

door5:
				move.w	#$0,d1
				bra		backfromtst

tstdoortoclose:
				move.w	TempFrames,d1
				add.w	(a6),d1
				move.w	d1,(a6)
				cmp.w	STAYOPENFOR,d1
				bge.s	.oktoclose
				move.w	#1,d4

.oktoclose:

				move.w	CLOSINGSFX,ACTIONNOISE
				tst.w	d4
				beq.s	dclose0
				bra.s	dclose1

dclose0:
				move.w	CLOSINGSPEED,d7
				move.w	#$8000,d1
				bra		backfromtst

dclose1:
				move.w	#$0,d1
				bra		backfromtst

SwitchRoutine:

				move.l	Lvl_SwitchDataPtr_l,a0
				move.w	#7,d0
				move.l	Lvl_PointsPtr_l,a1
CheckSwitches

				tst.b	Plr1_TmpSpcTap_b
				bne		p1_SpaceIsPressed
backtop2
				tst.b	Plr2_TmpSpcTap_b
				bne		p2_SpaceIsPressed
backtoend

				tst.b	2(a0)
				beq		nobutt

				tst.b	10(a0)
				beq		nobutt

				move.w	TempFrames,d1
				add.w	d1,d1
				add.w	d1,d1
				sub.b	d1,3(a0)
				bne		nobutt

				move.b	#0,10(a0)
				move.l	6(a0),a3
				add.l	Lvl_GraphicsPtr_l,a3
				move.w	#11,4(a3)
				move.w	(a3),d3
				and.w	#%00000111100,d3
				move.w	d3,(a3)
				move.w	#7,d3
				sub.w	d0,d3
				addq	#4,d3
				move.w	Conditions,d4
				bclr	d3,d4
				move.w	d4,Conditions
				move.w	#0,Noisex
				move.w	#0,Noisez
				move.w	#50,Noisevol
				move.w	#10,Samplenum
				move.b	#1,chanpick
				st		notifplaying
				move.w	#$fffc,IDNUM
				movem.l	a0/a3/d0/d1/d2/d3/d6/d7,-(a7)
				jsr		MakeSomeNoise
				movem.l	(a7)+,a0/a3/d0/d1/d2/d3/d6/d7

nobutt:

				adda.w	#14,a0
				dbra	d0,CheckSwitches
				rts

p1_SpaceIsPressed:
				move.w	Plr1_TmpXOff_l,d1
				move.w	Plr1_TmpZOff_l,d2
				move.w	(a0),d3
				blt		.NotCloseEnough
				move.w	4(a0),d3
				lea		(a1,d3.w*4),a2
				move.w	(a2),d3
				add.w	4(a2),d3
				asr.w	#1,d3
				move.w	2(a2),d4
				add.w	6(a2),d4
				asr.w	#1,d4
				sub.w	d1,d3
				muls	d3,d3
				sub.w	d2,d4
				muls	d4,d4
				add.l	d3,d4
				cmp.l	#60*60,d4
				bge		.NotCloseEnough
				move.l	6(a0),a3
				add.l	Lvl_GraphicsPtr_l,a3
				move.w	#11,4(a3)
				move.w	(a3),d3
				and.w	#%00000111100,d3
				not.b	10(a0)
				beq.s	.switchoff
				or.w	#2,d3
.switchoff:
				move.w	d3,(a3)
				move.w	#7,d3
				sub.w	d0,d3
				addq	#4,d3
				move.w	Conditions,d4
				bchg	d3,d4
				move.w	d4,Conditions
				move.b	#0,3(a0)
				move.w	#0,Noisex
				move.w	#0,Noisez
				move.w	#50,Noisevol
				move.w	#10,Samplenum
				move.b	#1,chanpick
				st		notifplaying
				move.w	#$fffc,IDNUM
				movem.l	a0/a3/d0/d1/d2/d3/d6/d7,-(a7)
				jsr		MakeSomeNoise
				movem.l	(a7)+,a0/a3/d0/d1/d2/d3/d6/d7

.NotCloseEnough:
				bra		backtop2

p2_SpaceIsPressed:
				move.w	Plr2_TmpXOff_l,d1
				move.w	Plr2_TmpZOff_l,d2
				move.w	(a0),d3
				blt		.NotCloseEnough
				move.w	4(a0),d3
				lea		(a1,d3.w*4),a2
				move.w	(a2),d3
				add.w	4(a2),d3
				asr.w	#1,d3
				move.w	2(a2),d4
				add.w	6(a2),d4
				asr.w	#1,d4
				sub.w	d1,d3
				muls	d3,d3
				sub.w	d2,d4
				muls	d4,d4
				add.l	d3,d4
				cmp.l	#60*60,d4
				bge		.NotCloseEnough
				move.l	6(a0),a3
				add.l	Lvl_GraphicsPtr_l,a3
				move.w	#11,4(a3)
				move.w	(a3),d3
				and.w	#%00000111100,d3
				not.b	10(a0)
				beq.s	.switchoff
				or.w	#2,d3
.switchoff:
				move.w	d3,(a3)
				move.w	#7,d3
				sub.w	d0,d3
				addq	#4,d3
				move.w	Conditions,d4
				bchg	d3,d4
				move.w	d4,Conditions
				movem.l	a0/a1/d0,-(a7)
				move.w	#0,Noisex
				move.w	#0,Noisez
				move.w	#50,Noisevol
				move.w	#10,Samplenum
				move.b	#1,chanpick
				st		notifplaying
				move.w	#$fffc,IDNUM
				movem.l	a0/a3/d0/d1/d2/d3/d6/d7,-(a7)
				jsr		MakeSomeNoise
				movem.l	(a7)+,a0/a3/d0/d1/d2/d3/d6/d7

				movem.l	(a7)+,a0/a1/d0

.NotCloseEnough:
				bra		backtoend

prot1:			dc.w	0

tempGotBigGun:	dc.w	0
tempGunDamage:	dc.w	0
tempGunNoise:	dc.w	1
tempxoff:		dc.w	0
tempzoff:		dc.w	0
tempRoompt:		dc.l	0

PLR1_GotBigGun:	dc.w	0
PLR1_GunDamage:	dc.w	0
PLR1_GunNoise:	dc.w	0
PLR2_GotBigGun:	dc.w	0
PLR2_GunDamage:	dc.w	0
PLR2_GunNoise:	dc.w	0
bulyspd:		dc.w	0
closedist:		dc.w	0

PLR1_ObsInLine:
				ds.b	400
PLR2_ObsInLine:
				ds.b	400

rotcount:
				dc.w	0

shotvels:		ds.l	20

				include	"newplayershoot.s"

PLR1_GunFrame:	dc.w	0
PLR2_GunFrame:	dc.w	0
NUMZONES:		dc.w	0

duh:			dc.w	0
double:			dc.w	0
ivescreamed:	dc.w	0

ObjectHandler:

				move.l	#ObjWork,WORKPTR
				move.l	#AI_Damaged_vw,AI_DamagePtr_l

				move.l	Lvl_ObjectDataPtr_l,a0
Objectloop:
				tst.w	(a0)
				blt		doneallobj
				move.w	12(a0),EntT_GraphicRoom_w(a0)

				move.b	16(a0),d0
				cmp.b	#1,d0
				blt		JUMPALIEN
				beq		JUMPOBJECT
				cmp.b	#2,d0
				beq		JUMPBULLET

doneobj:

dontworryyourprettyhead:
				adda.w	#64,a0
				add.l	#8,WORKPTR
				add.l	#2,AI_DamagePtr_l
				add.l	#8,AI_BoredomPtr_l
				bra		Objectloop

doneallobj:
				rts

JUMPALIEN
				tst.w	12(a0)
				blt.s	.dontworry

				tst.b	EntT_NumLives_b(a0)
				beq.s	.nolock
				move.l	EntT_DoorsHeld_w(a0),d0
				or.l	d0,DoorLocks
.nolock

				tst.b	ShotT_Worry_b(a0)
				beq		.dontworry
				jsr		ItsAnAlien

				tst.w	12-64(a0)
				blt.s	.notanaux
				move.w	12(a0),12-64(a0)
				move.w	12(a0),EntT_GraphicRoom_w-64(a0)
.notanaux:

.dontworry
				bra		doneobj

JUMPOBJECT
				tst.w	12(a0)
				blt.s	.dontworry
				jsr		ItsAnObject
.dontworry
				bra		doneobj
JUMPBULLET:
				jsr		ItsABullet
				bra		doneobj

ItsAGasPipe:

				clr.b	ShotT_Worry_b(a0)

				move.w	TempFrames,d0
				tst.w	EntT_Timer3_w(a0)
				ble.s	maybeflame

				sub.w	d0,EntT_Timer3_w(a0)
				move.w	#5,EntT_Timer2_w(a0)
				move.w	#10,EntT_Timer4_w(a0)
				rts

maybeflame:

				sub.w	d0,EntT_Timer4_w(a0)
				blt.s	yesflame
				rts

yesflame:
				move.w	#10,EntT_Timer4_w(a0)
				sub.w	#1,EntT_Timer2_w(a0)
				bgt.s	notdoneflame

				move.w	EntT_Timer1_w(a0),EntT_Timer3_w(a0)

notdoneflame:

				cmp.w	#4,EntT_Timer2_w(a0)
				bne.s	.nowhoosh

				movem.l	d0-d7/a0-a6,-(a7)
				move.l	#ObjRotated_vl,a1
				move.w	(a0),d0
				lea		(a1,d0.w*8),a1
				move.l	(a1),Noisex
				move.w	#200,Noisevol
				move.w	#22,Samplenum
				move.b	#1,chanpick
				clr.b	notifplaying
				move.w	(a0),IDNUM
				jsr		MakeSomeNoise
				movem.l	(a7)+,d0-d7/a0-a6

.nowhoosh:

; Gas pipe: facing direction is given by
; leved (perpendicular to wall) so
; just continuously spray out flame!
				move.l	NastyShotDataPtr_l,a5
				move.w	#19,d1
.findonefree
				move.w	12(a5),d0
				blt.s	.foundonefree
				adda.w	#64,a5
				dbra	d1,.findonefree

				rts

.foundonefree:

				move.b	#2,16(a5)
				move.w	12(a0),12(a5)
				move.w	4(a0),d0
				sub.w	#80,d0
				move.w	d0,4(a5)
				ext.l	d0
				asl.l	#7,d0
				move.l	d0,ShotT_AccYPos_w(a5)
				clr.b	ShotT_Status_b(a5)
				move.w	#0,ShotT_VelocityY_w(a5)
				move.w	(a0),d0
				move.w	(a5),d1
				move.l	Lvl_ObjectPointsPtr_l,a1
				move.l	(a1,d0.w*8),(a1,d1.w*8)
				move.l	4(a1,d0.w*8),4(a1,d1.w*8)
				move.b	#3,ShotT_Size_b(a5)
				move.w	#0,ShotT_Flags_w(a5)
				move.w	#0,ShotT_Gravity_w(a5)
				move.b	#7,ShotT_Power_w(a5)
				move.l	#%100000100000,EntT_EnemyFlags_l(a5)
				move.w	#0,ShotT_Anim_b(a5)
				move.w	#0,ShotT_Lifetime_w(a5)
				move.l	#SineTable,a1
				move.w	EntT_CurrentAngle_w(a0),d0
				move.w	(a1,d0.w),d1
				adda.w	#2048,a1
				move.w	(a1,d0.w),d2
				ext.l	d1
				ext.l	d2
				asl.l	#4,d1
				asl.l	#4,d2
				swap	d1
				swap	d2
				move.w	d1,ShotT_VelocityX_w(a5)
				move.w	d2,ShotT_VelocityZ_w(a5)
				st		ShotT_Worry_b(a5)

				rts

; include "ai.s"

ItsABarrel:

				clr.b	ShotT_Worry_b(a0)
				move.w	12(a0),EntT_GraphicRoom_w(a0)

				cmp.w	#8,8(a0)
				bne.s	notexploding

				add.w	#$404,6(a0)

				move.w	10(a0),d0
				add.w	#1,d0
				cmp.w	#8,d0
				bne.s	.notdone

				move.w	#-1,12(a0)
				move.w	#-1,EntT_GraphicRoom_w(a0)
				rts

.notdone:
				move.w	d0,10(a0)
				rts

notexploding:

				move.w	#$1f1f,14(a0)

				move.w	12(a0),d0
				move.l	Lvl_ZoneAddsPtr_l,a1
				move.l	(a1,d0.w*4),a1
				add.l	Lvl_DataPtr_l,a1
				move.l	ZoneT_Floor_l(a1),d0
				tst.b	ShotT_InUpperZone_b(a0)
				beq.s	.okinbot
				move.l	ZoneT_UpperFloor_l(a1),d0
.okinbot:
				asr.l	#7,d0
				sub.w	#60,d0
				move.w	d0,4(a0)

				moveq	#0,d2
				move.b	EntT_DamageTaken_b(a0),d2
				beq.s	nodamage
				move.b	#0,EntT_DamageTaken_b(a0)
				sub.b	d2,EntT_NumLives_b(a0)
				bgt.s	nodamage
				move.b	#0,EntT_NumLives_b(a0)

				movem.l	d0-d7/a0-a6,-(a7)

				move.w	(a0),d0
				move.l	Lvl_ObjectPointsPtr_l,a1
				move.w	(a1,d0.w*8),Viewerx
				move.w	4(a1,d0.w*8),Viewerz
				move.w	#40,d0
				jsr		ComputeBlast

				move.w	(a0),d0
				move.l	#ObjRotated_vl,a1
				move.l	(a1,d0.w*8),Noisex
				move.w	#300,Noisevol
				move.w	#15,Samplenum
				jsr		MakeSomeNoise

				movem.l	(a7)+,d0-d7/a0-a6
				move.w	#8,8(a0)
				move.w	#0,10(a0)
				move.w	#$2020,14(a0)
				move.w	#-30,2(a0)

				rts

nodamage:

				move.w	(a0),d0
				move.l	Lvl_ObjectPointsPtr_l,a1
				move.w	(a1,d0.w*8),Viewerx
				move.w	4(a1,d0.w*8),Viewerz
				move.b	ShotT_InUpperZone_b(a0),ViewerTop
				move.b	Plr1_StoodInTop_b,TargetTop
				move.l	Plr1_RoomPtr_l,ToRoom

				move.w	12(a0),d0
				move.l	Lvl_ZoneAddsPtr_l,a1
				move.l	(a1,d0.w*4),a1
				add.l	Lvl_DataPtr_l,a1
				move.l	a1,FromRoom

				move.w	Plr1_XOff_l,Targetx
				move.w	Plr1_ZOff_l,Targetz
				move.l	Plr1_YOff_l,d0
				asr.l	#7,d0
				move.w	d0,Targety
				move.w	4(a0),Viewery
				jsr		CanItBeSeen

				clr.b	17(a0)
				tst.b	CanSee
				beq		.noseeplr1
				move.b	#1,17(a0)

.noseeplr1:

				move.b	Plr2_StoodInTop_b,TargetTop
				move.l	Plr2_RoomPtr_l,ToRoom
				move.w	Plr2_XOff_l,Targetx
				move.w	Plr2_ZOff_l,Targetz
				move.l	Plr2_YOff_l,d0
				asr.l	#7,d0
				move.w	d0,Targety
				move.w	4(a0),Viewery
				jsr		CanItBeSeen

				tst.b	CanSee
				beq		.noseeplr2
				or.b	#2,17(a0)

.noseeplr2:


				rts

				include	"newaliencontrol.s"

nextCPt:		dc.w	0

RipTear:		dc.l	256*17*65536
otherrip:		dc.l	256*18*65536

ItsAMediKit:

				clr.b	ShotT_Worry_b(a0)
				move.w	12(a0),EntT_GraphicRoom_w(a0)

				move.w	12(a0),d0
				move.l	Lvl_ZoneAddsPtr_l,a1
				move.l	(a1,d0.w*4),a1
				add.l	Lvl_DataPtr_l,a1
				move.l	ZoneT_Floor_l(a1),d0
				tst.b	ShotT_InUpperZone_b(a0)
				beq.s	.okinbot
				move.l	ZoneT_UpperFloor_l(a1),d0
.okinbot:
				asr.l	#7,d0
				sub.w	#32,d0
				move.w	d0,4(a0)


HealFactor		EQU		18


				cmp.w	#127,Plr1_Energy_w
				bge		.NotSameZone

				move.b	Plr1_StoodInTop_b,d0
				move.b	ShotT_InUpperZone_b(a0),d1
				eor.b	d1,d0
				bne		.NotSameZone

				move.w	Plr1_XOff_l,oldx
				move.w	Plr1_ZOff_l,oldz
				move.w	Plr1_Zone_w,d7

				cmp.w	12(a0),d7
				bne		.NotSameZone
				move.w	(a0),d0
				move.l	Lvl_ObjectPointsPtr_l,a1
				move.w	(a1,d0.w*8),newx
				move.w	4(a1,d0.w*8),newz
				move.l	#100*100,d2
				jsr		CheckHit
				tst.b	hitwall
				beq		.NotPickedUp

				move.l	Plr1_ObjectPtr_l,a2
				move.w	(a2),d0
				move.l	#ObjRotated_vl,a2
				move.l	(a2,d0.w*8),Noisex
				move.w	#50,Noisevol
				move.w	#4,Samplenum
				move.b	#2,chanpick
				clr.b	notifplaying
				move.w	(a0),IDNUM
				movem.l	a0/a1/d2/d6/d7,-(a7)
				jsr		MakeSomeNoise
				movem.l	(a7)+,a0/a1/d2/d6/d7

				move.w	#-1,12(a0)
				move.w	#-1,EntT_GraphicRoom_w(a0)
				move.w	HealFactor(a0),d0
				add.w	Plr1_Energy_w,d0
				cmp.w	#127,d0
				ble.s	.okokokokokok
				move.w	#127,d0
.okokokokokok:
				move.w	d0,Plr1_Energy_w

.NotPickedUp:

.NotSameZone:

MEDIPLR2

				cmp.w	#127,Plr2_Energy_w
				bge		.NotSameZone

				move.b	Plr2_StoodInTop_b,d0
				move.b	ShotT_InUpperZone_b(a0),d1
				eor.b	d1,d0
				bne		.NotSameZone

				move.w	Plr2_XOff_l,oldx
				move.w	Plr2_ZOff_l,oldz
				move.w	Plr2_Zone_w,d7
				move.w	12(a0),d0

				cmp.w	12(a0),d7
				bne		.NotSameZone
				move.w	(a0),d0
				move.l	Lvl_ObjectPointsPtr_l,a1
				move.w	(a1,d0.w*8),newx
				move.w	4(a1,d0.w*8),newz
				move.l	#100*100,d2
				jsr		CheckHit
				tst.b	hitwall
				beq		.NotPickedUp

				move.l	Plr2_ObjectPtr_l,a2
				move.w	(a2),d0
				move.l	#ObjRotated_vl,a2
				move.l	(a2,d0.w*8),Noisex
				move.w	#50,Noisevol
				move.w	#4,Samplenum
				move.b	#2,chanpick
				clr.b	notifplaying
				move.w	(a0),IDNUM
				movem.l	a0/a1/d2/d6/d7,-(a7)
				jsr		MakeSomeNoise
				movem.l	(a7)+,a0/a1/d2/d6/d7

				move.w	#-1,12(a0)
				move.w	#-1,EntT_GraphicRoom_w(a0)
				move.w	HealFactor(a0),d0
				add.w	Plr2_Energy_w,d0
				cmp.w	#127,d0
				ble.s	.okokokokokok
				move.w	#127,d0
.okokokokokok:
				move.w	d0,Plr2_Energy_w

.NotPickedUp:

.NotSameZone:


				rts


OFFSETTOGRAPH:
				dc.l	(40*8)*43+10
				dc.l	(40*8)*11+12
				dc.l	(40*8)*11+22
				dc.l	(40*8)*43+24

AmmoInGuns:
				dc.w	0
				dc.w	5
				dc.w	1
				dc.w	0
				dc.w	1
				dc.w	0
				dc.w	0
				dc.w	5

ItsAKey:

				move.w	#$0f0f,14(a0)

				tst.b	NASTY
				bne		.yesnas
				move.w	#-1,12(a0)
				rts
.yesnas:

				move.w	12(a0),EntT_GraphicRoom_w(a0)
				clr.b	ShotT_Worry_b(a0)

				move.b	Plr1_StoodInTop_b,d0
				move.b	ShotT_InUpperZone_b(a0),d1
				eor.b	d1,d0
				bne		.NotSameZone

				move.w	Plr1_XOff_l,oldx
				move.w	Plr1_ZOff_l,oldz
				move.w	Plr1_Zone_w,d7
				move.w	12(a0),d0
				move.l	Lvl_ZoneAddsPtr_l,a1
				move.l	(a1,d0.w*4),a1
				add.l	Lvl_DataPtr_l,a1
				move.l	2(a1),d0
				asr.l	#7,d0
				sub.w	#16,d0
				move.w	d0,4(a0)
				cmp.w	12(a0),d7
				bne		.NotSameZone
				move.w	(a0),d0
				move.l	Lvl_ObjectPointsPtr_l,a1
				move.w	(a1,d0.w*8),newx
				move.w	4(a1,d0.w*8),newz
				move.l	#100*100,d2
				jsr		CheckHit
				tst.b	hitwall
				beq		.NotPickedUp

				move.w	#0,Noisex
				move.w	#0,Noisez
				move.w	#50,Noisevol
				move.w	#4,Samplenum
				move.b	#2,chanpick
				clr.b	notifplaying
				move.w	(a0),IDNUM
				movem.l	a0/a1/d2/d6/d7,-(a7)
				jsr		MakeSomeNoise
				movem.l	(a7)+,a0/a1/d2/d6/d7

				move.w	#-1,12(a0)
				move.w	#-1,EntT_GraphicRoom_w(a0)
				move.b	17(a0),d0
				or.b	d0,Conditions+1

				move.l	Panel,a2
				moveq	#0,d1
				lsr.b	#1,d0
				bcs.s	.done
				addq	#1,d1
				lsr.b	#1,d0
				bcs.s	.done
				addq	#1,d1
				lsr.b	#1,d0
				bcs.s	.done
				addq	#1,d1
.done

				move.l	#OFFSETTOGRAPH,a1
				add.l	(a1,d1.w*4),a2
				move.l	#PanelKeys,a1

				muls	#6*22*8,d1

				adda.w	d1,a1

				move.w	#22*8-1,d0				;lines
.lines:

				move.l	(a1)+,d1
				or.l	d1,(a2)
				move.w	(a1)+,d1
				or.w	d1,4(a2)
				adda.w	#40,a2

				dbra	d0,.lines


.NotPickedUp:

.NotSameZone:

				rts

Conditions:		dc.l	0

; Format of animations:
; Size (-1 = and of anim) (w)
; Address of Frame. (l)
; height offset (w)

Bul1Anim:
				dc.w	20*256+15
				dc.w	6,8
				dc.w	0
				dc.w	17*256+17
				dc.w	6,9
				dc.w	0
				dc.w	15*256+20
				dc.w	6,10
				dc.w	0
				dc.w	17*256+17
				dc.w	6,11
				dc.w	0
				dc.l	-1

Bul1Pop
				dc.b	25,25
				dc.w	1,6
				dc.w	0
				dc.b	25,25
				dc.w	1,7
				dc.w	-4
				dc.b	25,25
				dc.w	1,8
				dc.w	-4
				dc.b	25,25
				dc.w	1,9
				dc.w	-4
				dc.b	25,25
				dc.w	1,10
				dc.w	-4
				dc.b	25,25
				dc.w	1,11
				dc.w	-4
				dc.b	25,25
				dc.w	1,12
				dc.w	-4
				dc.b	25,25
				dc.w	1,13
				dc.w	-4
				dc.b	25,25
				dc.w	1,14
				dc.w	-4
				dc.b	25,25
				dc.w	1,15
				dc.w	-4
				dc.b	25,25
				dc.w	1,16
				dc.w	-4
				dc.l	-1

Bul3Anim:
				dc.b	25,25
				dc.w	0,12
				dc.w	0
				dc.b	25,25
				dc.w	0,13
				dc.w	0
				dc.b	25,25
				dc.w	0,14
				dc.w	0
				dc.b	25,25
				dc.w	0,15
				dc.w	0
				dc.l	-1

Bul3Pop:
				dc.l	-1

Bul4Anim:
				dc.b	25,25
				dc.w	6,4
				dc.w	0
				dc.b	25,25
				dc.w	6,5
				dc.w	0
				dc.b	25,25
				dc.w	6,6
				dc.w	0
				dc.b	25,25
				dc.w	6,7
				dc.w	0
				dc.l	-1

Bul4Pop:
				dc.b	20,20
				dc.w	6,4
				dc.w	0
				dc.b	15,15
				dc.w	6,5
				dc.w	0
				dc.b	10,10
				dc.w	6,6
				dc.w	0
				dc.b	5,5
				dc.w	6,7
				dc.w	0
				dc.l	-1

Bul5Anim:
				dc.b	10,10
				dc.w	6,4
				dc.w	0
				dc.b	10,10
				dc.w	6,5
				dc.w	0
				dc.b	10,10
				dc.w	6,6
				dc.w	0
				dc.b	10,10
				dc.w	6,7
				dc.w	0
				dc.l	-1

Bul5Pop:
				dc.b	8,8
				dc.w	6,4
				dc.w	0
				dc.b	6,6
				dc.w	6,5
				dc.w	0
				dc.b	4,4
				dc.w	6,6
				dc.w	0
				dc.l	-1

grenAnim:
				dc.b	25,25
				dc.w	1,21
				dc.w	0
				dc.b	25,25
				dc.w	1,22
				dc.w	0
				dc.b	25,25
				dc.w	1,23
				dc.w	0
				dc.b	25,25
				dc.w	1,24
				dc.w	0
				dc.l	-1

Bul2Anim:
				dc.b	25,25
				dc.w	-18,4
				dc.w	0
				dc.b	25,25
				dc.w	-18,5
				dc.w	0
				dc.b	25,25
				dc.w	-18,6
				dc.w	0
				dc.b	25,25
				dc.w	-18,7
				dc.w	0
				dc.b	25,25
				dc.w	-18,4
				dc.w	0
				dc.b	25,25
				dc.w	-18,5
				dc.w	0
				dc.b	25,25
				dc.w	-18,6
				dc.w	0
				dc.b	25,25
				dc.w	-18,7
				dc.w	0
				dc.w	-1


Bul2Pop:
				dc.b	25,25
				dc.w	2,8
				dc.w	-4
				dc.b	29,29
				dc.w	2,9
				dc.w	-4
				dc.b	33,33
				dc.w	2,10
				dc.w	-4
				dc.b	37,37
				dc.w	2,11
				dc.w	-4
				dc.b	41,41
				dc.w	2,12
				dc.w	-4
				dc.b	45,45
				dc.w	2,13
				dc.w	-4
				dc.b	49,49
				dc.w	2,14
				dc.w	-4
				dc.b	53,53
				dc.w	2,15
				dc.w	-4
				dc.b	57,57
				dc.w	2,16
				dc.w	-4
				dc.b	61,61
				dc.w	2,17
				dc.w	-4
				dc.b	65,65
				dc.w	2,18
				dc.w	-4
				dc.b	69,69
				dc.w	2,19
				dc.w	-4
				dc.w	-1

RockAnim:
				dc.b	16,16
				dc.w	6,0
				dc.w	0
				dc.b	16,16
				dc.w	6,1
				dc.w	0
				dc.b	16,16
				dc.w	6,2
				dc.w	0
				dc.b	16,16
				dc.w	6,3
				dc.w	0
				dc.l	-1

val				SET		100

RockPop:
				dc.b	val,val
				dc.w	8,0
				dc.w	-4
val				SET		val+10
				dc.b	val,val
				dc.w	8,1
				dc.w	0
val				SET		val+10
				dc.b	val,val
				dc.w	8,2
				dc.w	-4
val				SET		val+10
				dc.b	val,val
				dc.w	8,3
				dc.w	-4
val				SET		val+10
				dc.b	val,val
				dc.w	8,4
				dc.w	-4
val				SET		val+10
				dc.b	val,val
				dc.w	8,4
				dc.w	-4
val				SET		val+10
				dc.b	val,val
				dc.w	8,5
				dc.w	-4
val				SET		val+10
				dc.b	val,val
				dc.w	8,5
				dc.w	-4
val				SET		val+10
				dc.b	val,val
				dc.w	8,6
				dc.w	-4
val				SET		val+10
				dc.b	val,val
				dc.w	8,6
				dc.w	-4
val				SET		val+10
				dc.b	val,val
				dc.w	8,7
				dc.w	-4
val				SET		val+10
				dc.b	val,val
				dc.w	8,7
				dc.w	-4
val				SET		val+10
				dc.b	val,val
				dc.w	8,8
				dc.w	-4
val				SET		val+10
				dc.b	val,val
				dc.w	8,8
				dc.w	-4
				dc.l	-1


val				SET		5

FlameAnim:

				dc.b	val,val
				dc.w	8,0
				dc.w	0
val				SET		val+4
				dc.b	val,val
				dc.w	8,1
				dc.w	0
val				SET		val+4
				dc.b	val,val
				dc.w	8,2
				dc.w	0
val				SET		val+4
				dc.b	val,val
				dc.w	8,3
				dc.w	0
val				SET		val+4
				dc.b	val,val
				dc.w	8,4
				dc.w	0
val				SET		val+4
				dc.b	val,val
				dc.w	8,4
				dc.w	0
val				SET		val+4
				dc.b	val,val
				dc.w	8,5
				dc.w	0
val				SET		val+4
				dc.b	val,val
				dc.w	8,5
				dc.w	0
val				SET		val+4
				dc.b	val,val
				dc.w	8,5
				dc.w	0
val				SET		val+4
				dc.b	val,val
				dc.w	8,6
				dc.w	0
val				SET		val+4
				dc.b	val,val
				dc.w	8,6
				dc.w	0
val				SET		val+4
				dc.b	val,val
				dc.w	8,6
				dc.w	0
val				SET		val+6
				dc.b	val,val
				dc.w	8,7
				dc.w	0
val				SET		val+8
				dc.b	val,val
				dc.w	8,7
				dc.w	0
val				SET		val+8
				dc.b	val,val
				dc.w	8,7
				dc.w	0
val				SET		val+8
				dc.b	val,val
				dc.w	8,7
				dc.w	0
val				SET		val+8
				dc.b	val,val
				dc.w	8,8
				dc.w	0
val				SET		val+8
				dc.b	val,val
				dc.w	8,8
				dc.w	0
val				SET		val+8
				dc.b	val,val
				dc.w	8,8
				dc.w	0

				dc.l	-1

FlamePop:
val				SET		4*35
				dc.b	val,val
				dc.w	8,7
				dc.w	0
val				SET		val+4
				dc.b	val,val
				dc.w	8,7
				dc.w	0
val				SET		val+4
				dc.b	val,val
				dc.w	8,7
				dc.w	0
val				SET		val+4
				dc.b	val,val
				dc.w	8,8
				dc.w	0
val				SET		val+4
				dc.b	val,val
				dc.w	8,8
				dc.w	0
val				SET		val+4
				dc.b	val,val
				dc.w	8,8
				dc.w	0

				dc.l	-1

Explode1Anim:
				dc.b	25,25
				dc.w	0,16
				dc.w	0
				dc.b	25,25
				dc.w	0,17
				dc.w	0
				dc.b	25,25
				dc.w	0,18
				dc.w	0
				dc.b	25,25
				dc.w	0,19
				dc.w	0
				dc.l	-1

Explode1Pop:
				dc.b	20,20
				dc.w	0,16
				dc.w	1
				dc.b	20,20
				dc.w	0,16
				dc.w	1
				dc.b	20,20
				dc.w	0,16
				dc.w	1
				dc.b	20,20
				dc.w	0,16
				dc.w	1
				dc.b	20,20
				dc.w	0,16
				dc.w	1
				dc.b	20,20
				dc.w	0,16
				dc.w	1
				dc.b	20,20
				dc.w	0,16
				dc.w	1
				dc.b	20,20
				dc.w	0,16
				dc.w	1

				dc.b	17,17
				dc.w	0,16
				dc.w	1

				dc.b	13,13
				dc.w	0,16
				dc.w	1

				dc.b	9,9
				dc.w	0,16
				dc.w	1

				dc.l	-1

Explode2Anim:
				dc.b	20,20
				dc.w	0,20
				dc.w	0
				dc.b	20,20
				dc.w	0,21
				dc.w	0
				dc.b	20,20
				dc.w	0,22
				dc.w	0
				dc.b	20,20
				dc.w	0,23
				dc.w	0
				dc.l	-1

Explode2Pop:
				dc.b	20,20
				dc.w	0,20
				dc.w	1
				dc.b	20,20
				dc.w	0,20
				dc.w	1
				dc.b	20,20
				dc.w	0,20
				dc.w	1
				dc.b	20,20
				dc.w	0,20
				dc.w	1
				dc.b	20,20
				dc.w	0,20
				dc.w	1
				dc.b	20,20
				dc.w	0,20
				dc.w	1
				dc.b	20,20
				dc.w	0,20
				dc.w	1
				dc.b	20,20
				dc.w	0,20
				dc.w	1

				dc.b	17,17
				dc.w	0,20
				dc.w	1

				dc.b	13,13
				dc.w	0,20
				dc.w	1

				dc.b	9,9
				dc.w	0,20
				dc.w	1

				dc.l	-1


Explode3Anim:
				dc.b	20,20
				dc.w	0,24
				dc.w	0
				dc.b	20,20
				dc.w	0,25
				dc.w	0
				dc.b	20,20
				dc.w	0,26
				dc.w	0
				dc.b	20,20
				dc.w	0,27
				dc.w	0
				dc.l	-1

Explode3Pop:

				dc.b	17,17
				dc.w	0,24
				dc.w	1
				dc.b	17,17
				dc.w	0,24
				dc.w	1
				dc.b	17,17
				dc.w	0,24
				dc.w	1
				dc.b	17,17
				dc.w	0,24
				dc.w	1
				dc.b	17,17
				dc.w	0,24
				dc.w	1
				dc.b	17,17
				dc.w	0,24
				dc.w	1
				dc.b	17,17
				dc.w	0,24
				dc.w	1
				dc.b	17,17
				dc.w	0,24
				dc.w	1

				dc.b	13,13
				dc.w	0,24
				dc.w	1

				dc.b	9,9
				dc.w	0,24
				dc.w	1

				dc.l	-1

Explode4Anim:
				dc.b	30,30
				dc.w	0,28
				dc.w	0
				dc.b	30,30
				dc.w	0,29
				dc.w	0
				dc.b	30,30
				dc.w	0,30
				dc.w	0
				dc.b	30,30
				dc.w	0,31
				dc.w	0
				dc.l	-1

Explode4Pop:

				dc.b	20,20
				dc.w	0,28
				dc.w	0
				dc.b	20,20
				dc.w	0,28
				dc.w	1
				dc.b	20,20
				dc.w	0,28
				dc.w	1
				dc.b	20,20
				dc.w	0,28
				dc.w	1
				dc.b	20,20
				dc.w	0,28
				dc.w	1
				dc.b	20,20
				dc.w	0,28
				dc.w	1
				dc.b	20,20
				dc.w	0,28
				dc.w	1
				dc.b	20,20
				dc.w	0,28
				dc.w	1

				dc.b	17,17
				dc.w	0,28
				dc.w	1

				dc.b	13,13
				dc.w	0,28
				dc.w	1

				dc.b	9,9
				dc.w	0,28
				dc.w	1

				dc.l	-1

BulletSizes:
				dc.w	$0f0f,$707
				dc.w	$0f0f,$f0f
				dc.w	$0f0f,$1f1f
				dc.w	$1f1f,$1f1f
				dc.w	$0707,$1f1f
				dc.w	$0f0f,$0f0f
				dc.w	$0f0f,$0f0f
				dc.w	$707,$707
				dc.w	0,0,0,0
;10
				dc.w	0,0,0,0,0,0,0,0,0,0
				dc.w	0,0,0,0,0,0,0,0,0,0
;20
				dc.w	0,0,0,0,0,0,0,0,0,0
				dc.w	0,0,0,0,0,0,0,0,0,0
;30
				dc.w	0,0,0,0,0,0,0,0,0,0
				dc.w	0,0,0,0,0,0,0,0,0,0
;40
				dc.w	0,0,0,0,0,0,0,0,0,0
				dc.w	0,0,0,0,0,0,0,0,0,0
;50
				dc.w	$0707,$0707,$0707,$0707
				dc.w	$0707,$0707,$0707,$0707

HitNoises:
; dc.l -1,-1
				dc.w	15,200
				dc.w	15,200
				dc.l	-1
				dc.w	15,200
				dc.l	-1,-1,-1,-1,-1
				dc.l	-1,-1,-1,-1,-1,-1,-1,-1,-1,-1
				dc.l	-1,-1,-1,-1,-1,-1,-1,-1,-1,-1
				dc.l	-1,-1,-1,-1,-1,-1,-1,-1,-1,-1
				dc.l	-1,-1,-1,-1,-1,-1,-1,-1,-1,-1

				dc.w	13,50,13,50,13,50,13,50

ExplosiveForce:
				dc.w	0,0,64,0,40,0,0,0,0,0
				dc.w	0,0,0,0,0,0,0,0,0,0
				dc.w	0,0,0,0,0,0,0,0,0,0
				dc.w	0,0,0,0,0,0,0,0,0,0
				dc.w	0,0,0,0,0,0,0,0,0,0
				dc.w	0,0,0,0

BulletTypes:
				dc.l	Bul1Anim,Bul1Pop
				dc.l	Bul2Anim,Bul2Pop
				dc.l	RockAnim,RockPop
				dc.l	FlameAnim,FlamePop
				dc.l	grenAnim,RockPop
				dc.l	Bul4Anim,Bul4Pop
				dc.l	Bul5Anim,Bul5Pop
				dc.l	Bul1Anim,Bul1Pop
				dc.l	0,0
				dc.l	0,0

				dc.l	0,0
				dc.l	0,0
				dc.l	0,0
				dc.l	0,0
				dc.l	0,0
				dc.l	0,0
				dc.l	0,0
				dc.l	0,0
				dc.l	0,0
				dc.l	0,0

				dc.l	0,0
				dc.l	0,0
				dc.l	0,0
				dc.l	0,0
				dc.l	0,0
				dc.l	0,0
				dc.l	0,0
				dc.l	0,0
				dc.l	0,0
				dc.l	0,0

				dc.l	0,0
				dc.l	0,0
				dc.l	0,0
				dc.l	0,0
				dc.l	0,0
				dc.l	0,0
				dc.l	0,0
				dc.l	0,0
				dc.l	0,0
				dc.l	0,0

				dc.l	0,0
				dc.l	0,0
				dc.l	0,0
				dc.l	0,0
				dc.l	0,0
				dc.l	0,0
				dc.l	0,0
				dc.l	0,0
				dc.l	0,0
				dc.l	0,0

				dc.l	Explode1Anim,Explode1Pop
				dc.l	Explode2Anim,Explode2Pop
				dc.l	Explode3Anim,Explode3Pop
				dc.l	Explode4Anim,Explode4Pop

tsta:			dc.l	0
timeout:		dc.w	0
BRIGHTNESS:		dc.w	0

ItsABullet:

				move.b	#0,timeout
				move.w	12(a0),d0
				move.w	d0,EntT_GraphicRoom_w(a0)
				blt		doneshot

				moveq	#0,d1
				move.b	ShotT_Size_b(a0),d1
				muls	#BulT_SizeOf_l,d1
				move.l	GLF_DatabasePtr_l,a6
				lea		GLFT_BulletDefs_l(a6),a6
				add.l	d1,a6

				tst.b	ShotT_Status_b(a0)
				bne.s	noworrylife

; a6 points at bullet data.

				move.w	ShotT_Lifetime_w(a0),d2
				blt.s	infinite

				move.l	BulT_Lifetime_l(a6),d1
				blt.s	infinite

				cmp.w	d2,d1
				bge.s	notdone

				st		timeout
				bra.s	infinite

notdone:

				move.w	TempFrames,d2
				add.w	d2,ShotT_Lifetime_w(a0)

infinite:

noworrylife:

				move.w	#0,extlen
				move.b	#$ff,awayfromwall


				tst.b	ShotT_Status_b(a0)
				beq		notpopping

				lea		BulT_PopData_vb(a6),a1
				moveq	#0,d1
				move.b	ShotT_Anim_b(a0),d1

				move.w	d1,d2
				add.w	d1,d1
				add.w	d2,d1
				add.w	d1,d1

				move.l	#0,8(a0)

				cmp.l	#1,BulT_ImpactGraphicType_l(a6)
				blt.s	.bitmapgraph
				beq.s	.glaregraph
.additivegraph:
				move.b	(a1,d1.w),9(a0)
				move.b	1(a1,d1.w),11(a0)
				move.b	#6,10(a0)
				move.w	2(a1,d1.w),6(a0)
				move.b	5(a1,d1.w),BRIGHTNESS

				bra.s	.donegraph
.bitmapgraph:
				move.b	(a1,d1.w),9(a0)
				move.b	1(a1,d1.w),11(a0)
				move.w	2(a1,d1.w),6(a0)
				move.b	5(a1,d1.w),BRIGHTNESS

				bra.s	.donegraph
.glaregraph:
				move.b	(a1,d1.w),d0
				ext.w	d0
				neg.w	d0
				move.w	d0,8(a0)
				move.b	1(a1,d1.w),11(a0)
				move.w	2(a1,d1.w),6(a0)
				move.b	5(a1,d1.w),BRIGHTNESS

.donegraph:

				addq	#1,d2
				cmp.w	BulT_PopFrames_l+2(a6),d2
				ble.s	notdonepopping

				move.w	#-1,12(a0)
				move.w	#-1,EntT_GraphicRoom_w(a0)
				clr.b	ShotT_Status_b(a0)
				move.b	#0,ShotT_Anim_b(a0)
				rts
notdonepopping:

				move.b	d2,ShotT_Anim_b(a0)
				moveq	#0,d0
				move.b	BRIGHTNESS,d0
				beq.s	.nobright
				neg.w	d0
				move.w	(a0),d2
				move.l	Lvl_ObjectPointsPtr_l,a2
				move.w	(a2,d2.w*8),d1
				move.w	4(a2,d2.w*8),d2
				move.w	4(a0),d3
				ext.l	d3
				asl.l	#7,d3
				move.l	d3,BRIGHTY
				move.w	12(a0),d3
				jsr		BRIGHTENPOINTS
.nobright
				rts

BLOODYGREATBOMB: dc.w	0

notpopping:

				move.b	ShotT_Size_b(a0),BLOODYGREATBOMB

				lea		BulT_AnimData_vb(a6),a1
				moveq	#0,d1
				move.b	ShotT_Anim_b(a0),d1

				add.w	d1,d1
				move.w	d1,d2
				add.w	d1,d1
				add.w	d2,d1

				move.l	#0,8(a0)

				cmp.l	#1,BulT_GraphicType_l(a6)
				blt.s	.bitmapgraph
				beq.s	.glaregraph
.additivegraph:
				move.b	(a1,d1.w),9(a0)
				move.b	1(a1,d1.w),11(a0)
				move.b	#6,10(a0)
				move.w	2(a1,d1.w),6(a0)
				move.b	5(a1,d1.w),BRIGHTNESS

				bra.s	.donegraph
.bitmapgraph:
				move.b	(a1,d1.w),9(a0)
				move.b	1(a1,d1.w),11(a0)
				move.w	2(a1,d1.w),6(a0)
				move.b	5(a1,d1.w),BRIGHTNESS

				bra.s	.donegraph
.glaregraph:
				move.b	(a1,d1.w),d0
				ext.w	d0
				neg.w	d0
				move.w	d0,8(a0)
				move.b	1(a1,d1.w),11(a0)
				move.w	2(a1,d1.w),6(a0)
				move.b	5(a1,d1.w),BRIGHTNESS

.donegraph:

				addq	#1,d2
				cmp.w	BulT_AnimFrames_l+2(a6),d2
				ble.s	notdoneanim

				move.w	#0,d2

notdoneanim:

				move.b	d2,ShotT_Anim_b(a0)

				move.l	Lvl_ZoneAddsPtr_l,a2
				move.l	(a2,d0.w*4),d0
				add.l	Lvl_DataPtr_l,d0
				move.l	d0,objroom

********************************
				move.l	objroom,a3
				move.b	ZoneT_Echo_b(a3),PlayEcho

				tst.b	ShotT_InUpperZone_b(a0)
				beq.s	.notintop
				adda.w	#8,a3
.notintop:

				move.l	6(a3),d0
				sub.l	ShotT_AccYPos_w(a0),d0
				cmp.l	#10*128,d0
				blt		.nohitroof

				btst	#0,ShotT_Flags_w+1(a0)
				beq.s	.nobounce

				neg.w	ShotT_VelocityY_w(a0)

				move.l	6(a3),d0
				add.l	#10*128,d0
				move.l	d0,ShotT_AccYPos_w(a0)

				tst.l	BulT_Gravity_l(a6)
				beq		.nohitroof

; btst #1,ShotT_Flags_w+1(a0)
; beq .nohitroof

				move.l	ShotT_VelocityX_w(a0),d0
				asr.l	#1,d0
				move.l	d0,ShotT_VelocityX_w(a0)
				move.l	ShotT_VelocityZ_w(a0),d0
				asr.l	#1,d0
				move.l	d0,ShotT_VelocityZ_w(a0)

				bra		.nohitroof

.nobounce:

				move.b	#0,ShotT_Anim_b(a0)
				move.b	#1,ShotT_Status_b(a0)

				move.l	BulT_ImpactSFX_l(a6),d0
				subq.l	#1,d0
				blt.s	.nohitnoise

				move.l	#ObjRotated_vl,a1
				move.w	(a0),d1
				move.l	(a1,d1.w*8),Noisex
; move.w d0,Noisevol
; swap d0
				move.w	#200,Noisevol
				move.w	d0,Samplenum
				move.w	d1,IDNUM
				movem.l	d0-d7/a0-a6,-(a7)
				jsr		MakeSomeNoise
				movem.l	(a7)+,d0-d7/a0-a6

.nohitnoise:

				move.l	BulT_ExplosiveForce_l(a6),d0
				beq.s	.noexplosion

				move.w	newx,Viewerx
				move.w	newz,Viewerz

				move.w	4(a0),Viewery
				move.b	ShotT_InUpperZone_b(a0),ViewerTop

				movem.l	d0-d7/a0-a6,-(a7)
				bsr		ComputeBlast
				movem.l	(a7)+,d0-d7/a0-a6

.noexplosion:

.nohitroof:

				move.l	2(a3),d0
				sub.l	ShotT_AccYPos_w(a0),d0
				cmp.l	#10*128,d0
				bgt		.nohitfloor

				tst.l	BulT_BounceVert_l(a6)
				beq.s	.nobounceup

				tst.w	ShotT_VelocityY_w(a0)
				blt		.nohitfloor

				moveq	#0,d0
				move.w	ShotT_VelocityY_w(a0),d0
				asr.w	#1,d0
				neg.w	d0
				move.w	d0,ShotT_VelocityY_w(a0)

				move.l	2(a3),d0
				sub.l	#10*128,d0
				move.l	d0,ShotT_AccYPos_w(a0)

; btst #1,ShotT_Flags_w+1(a0)
; beq .nohitfloor
				tst.l	BulT_Gravity_l(a6)
				beq		.nohitfloor

				move.l	ShotT_VelocityX_w(a0),d0
				asr.l	#1,d0
				move.l	d0,ShotT_VelocityX_w(a0)
				move.l	ShotT_VelocityZ_w(a0),d0
				asr.l	#1,d0
				move.l	d0,ShotT_VelocityZ_w(a0)


				bra		.nohitfloor
.nobounceup:


				move.b	#0,ShotT_Anim_b(a0)
				move.b	#1,ShotT_Status_b(a0)
				move.l	BulT_ImpactSFX_l(a6),d0
				subq.l	#1,d0
				blt.s	.nohitnoise2

				move.l	#ObjRotated_vl,a1
				move.w	(a0),d1
				move.l	(a1,d1.w*8),Noisex
				move.w	#200,Noisevol
				move.w	d0,Samplenum
				move.w	d1,IDNUM
				movem.l	d0-d7/a0-a6,-(a7)
				jsr		MakeSomeNoise
				movem.l	(a7)+,d0-d7/a0-a6
.nohitnoise2:
				moveq	#0,d0
				move.l	BulT_ExplosiveForce_l(a6),d0
				beq.s	.noexplosion2

				move.w	4(a0),Viewery
				move.w	newx,Viewerx
				move.w	newz,Viewerz
				move.b	ShotT_InUpperZone_b(a0),ViewerTop
				movem.l	d0-d7/a0-a6,-(a7)
				bsr		ComputeBlast
				movem.l	(a7)+,d0-d7/a0-a6

.noexplosion2:
.nohitfloor:
********************



				move.l	Lvl_ObjectPointsPtr_l,a1
				move.w	(a0),d1
				lea		(a1,d1.w*8),a1
				move.l	(a1),d2
				move.l	d2,oldx
				move.l	ShotT_VelocityX_w(a0),d3
				move.w	d3,d4
				swap	d3
				move.w	TempFrames,d5
				muls	d5,d3
				mulu	d5,d4
				swap	d3
				clr.w	d3
				add.l	d4,d3
				add.l	d3,d2
				move.l	d2,newx
				move.l	4(a1),d2
				move.l	d2,oldz
				move.l	ShotT_VelocityZ_w(a0),d3
				move.w	d3,d4
				swap	d3
				muls	d5,d3
				mulu	d5,d4
				swap	d3
				clr.w	d3
				add.l	d4,d3
				add.l	d3,d2
				move.l	d2,newz
				move.l	ShotT_AccYPos_w(a0),oldy

				move.w	ShotT_VelocityY_w(a0),d3
				muls	TempFrames,d3
				move.l	BulT_Gravity_l(a6),d5
				beq.s	nograv
				muls	TempFrames,d5
				add.l	d5,d3
				move.w	ShotT_VelocityY_w(a0),d6
				ext.l	d6
				add.l	d5,d6
				cmp.l	#10*256,d6
				blt.s	okgrav
				move.l	#10*256,d6
				okgrav:
				move.w	d6,ShotT_VelocityY_w(a0)
nograv:
				move.l	ShotT_AccYPos_w(a0),d4
				add.l	d3,d4


				move.l	d4,ShotT_AccYPos_w(a0)
				sub.l	#5*128,d4
				move.l	d4,newy
				add.l	#5*128,d4
				asr.l	#7,d4
				move.w	d4,4(a0)
				tst.l	BulT_BounceHoriz_l(a6)
				sne		wallbounce
				seq		exitfirst

				clr.b	MOVING

				clr.b	hitwall
				move.b	ShotT_InUpperZone_b(a0),StoodInTop
				move.w	#%0000010000000000,wallflags
				move.l	#0,StepUpVal
				move.l	#$1000000,StepDownVal
				move.l	#10*128,thingheight
				move.w	oldx,d0
				cmp.w	newx,d0
				bne.s	lalal
				move.w	oldz,d0
				cmp.w	newz,d0
				beq.s	nomovebul
				move.w	#1,walllength

lalal:
				st		MOVING
				movem.l	d0/d7/a0/a1/a2/a4/a5/a6,-(a7)
				jsr		MoveObject

				moveq	#0,d0
				move.b	BRIGHTNESS,d0
				beq.s	.nobright
				neg.w	d0
				move.w	newx,d1
				move.w	newz,d2
				move.l	newy,BRIGHTY
				move.l	objroom,a0
				move.w	(a0),d3
				jsr		BRIGHTENPOINTS

.nobright:

				movem.l	(a7)+,d0/d7/a0/a1/a2/a4/a5/a6
nomovebul:
				move.b	StoodInTop,ShotT_InUpperZone_b(a0)

				tst.b	wallbounce
				beq.s	.notabouncything

				tst.b	hitwall
				beq		.nothitwall

; we have hit a wall....

				move.w	ShotT_VelocityZ_w(a0),d0
				muls	wallxsize,d0
				move.w	ShotT_VelocityX_w(a0),d1
				muls	wallzsize,d1
				sub.l	d1,d0
				divs	walllength,d0

				move.w	ShotT_VelocityX_w(a0),d1
				move.w	wallzsize,d2
				add.w	d2,d2
				muls	d0,d2
				divs	walllength,d2
				add.w	d2,d1
				move.w	d1,ShotT_VelocityX_w(a0)

				move.w	ShotT_VelocityZ_w(a0),d1
				move.w	wallxsize,d2
				add.w	d2,d2
				muls	d0,d2
				divs	walllength,d2
				sub.w	d2,d1
				move.w	d1,ShotT_VelocityZ_w(a0)

; btst #1,ShotT_Flags_w+1(a0)
; beq .nothitwall

				tst.l	BulT_Gravity_l(a6)
				beq		.nothitwall

				move.l	ShotT_VelocityX_w(a0),d0
				asr.l	#1,d0
				move.l	d0,ShotT_VelocityX_w(a0)
				move.l	ShotT_VelocityZ_w(a0),d0
				asr.l	#1,d0
				move.l	d0,ShotT_VelocityZ_w(a0)


				bra		.nothitwall

.notabouncything:

				tst.b	hitwall
				beq		.nothitwall

				move.l	wallhitheight,d4
				move.l	d4,ShotT_AccYPos_w(a0)
				asr.l	#7,d4
				move.w	d4,4(a0)

.hitsomething
				clr.b	timeout
				move.b	#0,ShotT_Anim_b(a0)
				move.b	#1,ShotT_Status_b(a0)

				move.l	BulT_ImpactSFX_l(a6),d0
				subq.l	#1,d0
				blt.s	.nohitnoise

				move.l	#ObjRotated_vl,a1
				move.w	(a0),d1
				move.l	(a1,d1.w*8),Noisex
				move.w	#200,Noisevol
				move.w	d0,Samplenum
				move.w	d1,IDNUM
				movem.l	d0-d7/a0-a6,-(a7)
				jsr		MakeSomeNoise
				movem.l	(a7)+,d0-d7/a0-a6

.nohitnoise:

				move.l	BulT_ExplosiveForce_l(a6),d0
				beq.s	.noexplosion

				move.w	newx,Viewerx
				move.w	newz,Viewerz
				move.w	4(a0),Viewery
				move.b	ShotT_InUpperZone_b(a0),ViewerTop
				movem.l	d0-d7/a0-a6,-(a7)
				bsr		ComputeBlast
				movem.l	(a7)+,d0-d7/a0-a6

.noexplosion:


; bra doneshot

; rts

.nothitwall:

				tst.b	timeout
				bne		.hitsomething

lab:


				move.l	objroom,a3
				move.w	(a3),12(a0)
				move.w	(a3),EntT_GraphicRoom_w(a0)
				move.l	newx,(a1)
				move.l	newz,4(a1)
************
* Check if hit a nasty

				tst.l	EntT_EnemyFlags_l(a0)
				bne.s	notasplut
				rts
notasplut:


				move.l	Lvl_ObjectDataPtr_l,a3
				move.l	Lvl_ObjectPointsPtr_l,a1
				move.w	newx,d2
				sub.w	oldx,d2
				move.w	d2,xdiff
				move.w	newz,d1
				sub.w	oldz,d1
				move.w	d1,zdiff
				move.w	d1,d3
				move.w	d2,d4
				muls	d2,d2
				muls	d1,d1
				move.l	#1,d0
				add.l	d1,d2
				beq		.oksqr

				move.w	#31,d0
.findhigh
				btst	d0,d2
				bne		.foundhigh
				dbra	d0,.findhigh
.foundhigh
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
.stillnot0

				move.w	d0,d1
				muls	d1,d1
				sub.l	d2,d1
				asr.l	#1,d1
				divs	d0,d1
				sub.w	d1,d0					; second approx
				bgt		.stillnot02
				move.w	#1,d0
.stillnot02

				move.w	d0,d1
				muls	d1,d1
				sub.l	d2,d1
				asr.l	#1,d1
				divs	d0,d1
				sub.w	d1,d0					; second approx
				bgt		.stillnot03
				move.w	#1,d0
.stillnot03

.oksqr
				move.w	d0,Range
				add.w	#80,d0
				muls	d0,d0
				move.l	d0,sqrnum

.checkloop:
				tst.w	(a3)
				blt		.checkedall
				tst.w	12(a3)
				blt		.notanasty

				move.b	ShotT_InUpperZone_b(a0),d1
				move.b	ShotT_InUpperZone_b(a3),d2
				eor.b	d2,d1
				bne		.notanasty

				moveq	#0,d1
				move.b	16(a3),d1

				move.l	EntT_EnemyFlags_l(a0),d7
				btst	d1,d7
				beq		.notanasty

				cmp.b	#1,d1
				bne.s	.notanobj

				move.l	GLF_DatabasePtr_l,a4
				add.l	#GLFT_ObjectDefs,a4
				move.b	EntT_Type_b(a3),d1
				muls	#ObjT_SizeOf_l,d1
				cmp.w	#2,ObjT_Behaviour_w(a4,d1.w)
				bne		.notanasty

.notanobj:

				tst.b	EntT_NumLives_b(a3)
				beq		.notanasty

; move.l #ColBoxTable,a6
; lea (a6,d1.w*8),a6

				move.w	4(a3),d1
				move.w	4(a0),d2
				sub.w	d1,d2
				bge		.okh
				neg.w	d2
.okh:

; cmp.w 2(a6),d2

				tst.b	MOVING
				beq.s	.ignoreheight

				cmp.w	#50,d2
				bgt		.notanasty

.ignoreheight:

				move.w	(a3),d1
				move.w	(a1,d1.w*8),d2
				move.w	d2,d4
				move.w	4(a1,d1.w*8),d3
				move.w	d3,d5
				sub.w	newx,d4
				sub.w	oldx,d2
				move.w	d2,d6
				sub.w	newz,d5
				sub.w	oldz,d3
				move.w	d3,d7
				muls	zdiff,d6
				muls	xdiff,d7
				sub.l	d7,d6
				bgt.s	.pos
				neg.l	d6
.pos:
				divs	Range,d6

				move.w	#80,d7
				cmp.b	#1,16(a3)
				ble.s	.okbig

				move.w	#40,d7

.okbig:

				cmp.w	d7,d6
; cmp.w (a6),d6
				bgt		.stillgoing

				muls	d2,d2
				muls	d3,d3
				add.l	d3,d2
				cmp.l	sqrnum,d2
				bgt		.stillgoing
				muls	d4,d4
				muls	d5,d5
				add.l	d5,d4
				cmp.l	sqrnum,d4
				bgt		.stillgoing

				move.b	ShotT_Power_w(a0),d6
				add.b	d6,EntT_DamageTaken_b(a3)
				move.w	ShotT_VelocityX_w(a0),EntT_ImpactX_w(a3)
				move.w	ShotT_VelocityZ_w(a0),EntT_ImpactZ_w(a3)
				move.b	#0,ShotT_Anim_b(a0)
				move.b	#1,ShotT_Status_b(a0)

				move.l	BulT_ImpactSFX_l(a6),d0
				subq.l	#1,d0
				blt.s	.nohitnoise3

				move.l	#ObjRotated_vl,a1
				move.w	(a0),d1
				move.l	(a1,d1.w*8),Noisex
				move.w	#200,Noisevol
				move.w	d0,Samplenum
				move.w	d1,IDNUM
				movem.l	d0-d7/a0-a6,-(a7)
				jsr		MakeSomeNoise
				movem.l	(a7)+,d0-d7/a0-a6
.nohitnoise3:
				move.l	BulT_ExplosiveForce_l(a6),d0
				beq.s	.noexplosion3

				move.w	4(a0),Viewery
				move.w	newx,Viewerx
				move.w	newz,Viewerz
				movem.l	d0-d7/a0-a6,-(a7)
				bsr		ComputeBlast
				movem.l	(a7)+,d0-d7/a0-a6

.noexplosion3:


				bra		.hitnasty
.stillgoing:
.notanasty:
				add.w	#64,a3
				bra		.checkloop
.hitnasty:
.checkedall

doneshot:
				rts

MOVING:			dc.w	0
tmpnewx:		dc.l	0
tmpnewz:		dc.l	0
hithit:			dc.l	0
sqrnum:			dc.l	0
tmpangpos:		dc.l	0
allbars:		dc.l	0
backrout:		ds.b	800
NUMTOCHECK:		dc.w	0

MAKEBACKROUT:
; move.l #backrout+256,d0
; clr.b d0
; move.l d0,allbars
; move.l d0,a1
; move.l #fromback,a0
; move.w #400,d0
;putinback:
; move.b (a0)+,(a1)+
; dbra d0,putinback
				rts

****************************************

putinbackdrop:
				move.l	a0,-(a7)

				move.w	tmpangpos,d5
				and.w	#4095,d5
				muls	#648,d5
				divs	#4096,d5
				muls	#240,d5

; CACHE_ON d1

				tst.b	Vid_FullScreen_b
				bne		BIGBACK

				move.l	Vid_FastBufferPtr_l,a0
				move.l	BackPicture,a5
				move.l	a5,a3
				add.l	#155520,a3
				add.l	#240,a5
; move.l #EndBackPicture,a3
; move.l #BackPicture+240,a5
				move.l	BackPicture,a1
; lea.l BackPicture,a1
				add.l	d5,a1
				add.w	#240,a1

				move.w	Vid_CentreY_w,d7

				move.w	d7,d6
				move.w	d6,d5
				asr.w	#1,d5
				add.w	d5,d6
				sub.w	d6,a1
				sub.w	d6,a5

				asr.w	#2,d7

				move.w	#240,d1
				move.w	#240,d2
				move.w	#480,d5
				move.w	#191,d4

horline:
				move.w	d7,d3
				move.l	a0,a2
				move.l	a1,a4

vertline:
				move.w	(a4)+,d0
				move.b	d0,(a2)
				move.b	(a4)+,d0
				move.b	d0,SCREENWIDTH(a2)
				addq	#1,a4
				move.b	(a4)+,d0
				move.b	d0,SCREENWIDTH*2(a2)
				move.b	(a4)+,d0
				move.b	d0,SCREENWIDTH*3(a2)

				adda.w	#SCREENWIDTH*4,a2
				dbra	d3,vertline

				add.w	d1,a1
				cmp.l	a1,a3
				bgt.s	.noend
				move.l	a5,a1
.noend
				exg		d1,d2
				exg		d2,d5

				addq.w	#1,a0

				dbra	d4,horline

				move.l	(a7)+,a0
				rts

BIGBACK:
				move.l	Vid_FastBufferPtr_l,a0
				move.l	BackPicture,a5
				move.l	a5,a3
				add.l	#155520,a3
				add.l	#240,a5
; move.l #EndBackPicture,a3
; move.l #BackPicture+240,a5
				move.l	BackPicture,a1
				add.l	d5,a1
				add.w	#240,a1

				move.w	Vid_CentreY_w,d7

				move.w	d7,d6
				sub.w	d6,a1
				sub.w	d6,a5

				asr.w	#2,d7
				move.w	#FS_WIDTH-1,d4

.horline:
				move.w	d7,d3
				move.l	a0,a2
				move.l	a1,a4

.vertline:
				move.l	(a4)+,d0
				move.b	d0,SCREENWIDTH*3(a2)
				swap	d0
				move.b	d0,SCREENWIDTH(a2)
				lsr.l	#8,d0
				move.b	d0,(a2)
				swap	d0
				move.b	d0,SCREENWIDTH*2(a2)

				adda.w	#SCREENWIDTH*4,a2
				dbra	d3,.vertline

				add.w	#240,a1
				cmp.l	a1,a3
				bgt.s	.noend
				move.l	a5,a1

.noend
				addq.w	#1,a0
				dbra	d4,.horline
				move.l	(a7)+,a0
				rts


MaxDamage:		dc.w	0

ComputeBlast:
				clr.w	doneflames

				move.w	d0,d6
				move.w	d0,MaxDamage
				move.w	d0,d1
				ext.l	d6
				neg.w	d1
				move.w	12(a0),d0
; jsr Flash

				move.l	Lvl_ZoneAddsPtr_l,a2
				move.l	(a2,d0.w*4),a2
				add.l	Lvl_DataPtr_l,a2
				move.l	a2,MiddleRoom

				move.l	Lvl_ObjectDataPtr_l,a2
				suba.w	#64,a2
				ext.l	d6
				move.l	a0,-(a7)

HitObjLoop:
				move.l	MiddleRoom,FromRoom
				add.w	#64,a2
				move.w	(a2),d0
				blt		CheckedEmAll
				tst.w	12(a2)
				blt.s	HitObjLoop
				moveq	#0,d1
				move.b	16(a2),d1
				cmp.b	#1,d1
				beq.s	HitObjLoop
				blt.s	.checkalien
				cmp.b	#3,d1
				beq.s	HitObjLoop
				bgt.s	.checkalien

; check bullet
				moveq	#0,d7
				move.b	ShotT_Size_b(a2),d7
				move.l	GLF_DatabasePtr_l,a3
				muls	#BulT_SizeOf_l,d7
				add.l	#GLFT_BulletDefs_l,a3
				add.l	d7,a3
				tst.l	BulT_Gravity_l(a3)
				beq.s	HitObjLoop
				bra.s	.okblast

.checkalien
				tst.b	EntT_NumLives_b(a2)
				beq.s	HitObjLoop

.okblast:
				move.w	12(a2),d1
				move.l	Lvl_ZoneAddsPtr_l,a3
				move.l	(a3,d1.w*4),a3
				add.l	Lvl_DataPtr_l,a3
				move.l	a3,ToRoom
				move.l	Lvl_ObjectPointsPtr_l,a3
				move.w	(a3,d0.w*8),Targetx
				move.w	4(a3,d0.w*8),Targetz
				move.w	4(a2),Targety
				move.b	ShotT_InUpperZone_b(a2),TargetTop
				jsr		CanItBeSeen
				tst.b	CanSee
				beq		HitObjLoop

				move.w	Targetx,d0
				sub.w	Viewerx,d0
				move.w	d0,d2
				move.w	Targetz,d1
				sub.w	Viewerz,d1
				move.w	d1,d3
				muls	d2,d2
				muls	d3,d3
				move.w	#1,d4
				add.l	d3,d2
				beq		.oksqr
				move.w	#31,d4

.findhigh
				btst	d4,d2
				dbne	d4,.findhigh

.foundhigh
				asr.w	#1,d4
				clr.l	d3
				bset	d4,d3
				move.l	d3,d4

				move.w	d4,d3
				muls	d3,d3					; x*x
				sub.l	d2,d3					; x*x-a
				asr.l	#1,d3					; (x*x-a)/2
				divs	d4,d3					; (x*x-a)/2x
				sub.w	d3,d4					; second approx
				bgt		.stillnot0
				move.w	#1,d4

.stillnot0
				move.w	d4,d3
				muls	d1,d3
				sub.l	d2,d3
				asr.l	#1,d3
				divs	d4,d3
				sub.w	d3,d4					; second approx
				bgt		.stillnot02
				move.w	#1,d4

.stillnot02
				move.w	d4,d3
				muls	d3,d3
				sub.l	d2,d3
				asr.l	#1,d3
				divs	d4,d3
				sub.w	d3,d4					; second approx
				bgt		.stillnot03
				move.w	#1,d4
.stillnot03

.oksqr
				move.w	d4,d3
				move.w	d3,d7
				cmp.w	#256,d7
				bge.s	.okd
				move.w	#256,d7

.okd:
				asr.w	#3,d3
				sub.w	#4,d3
				bge.s	OkItsnotzero
				moveq	#0,d3

OkItsnotzero:
				cmp.w	#64,d3
				bgt		HitObjLoop
				neg.w	d3
				add.w	#64,d3

				move.w	d6,d5
				muls	d3,d5
				asr.l	#5,d5
				cmp.w	MaxDamage,d5
				blt.s	okdamage
				move.w	MaxDamage,d5

okdamage:
				add.b	d5,EntT_DamageTaken_b(a2)
				ext.l	d0
				ext.l	d1
				muls.l	d6,d0
				muls.l	d6,d1
; asl.l #2,d0
; asl.l #2,d1
				divs	d7,d0
				divs	d7,d1

				move.b	16(a2),d2
				cmp.b	#2,d2
				bne.s	.impactalien

				add.w	d0,ShotT_VelocityX_w(a2)
				add.w	d1,ShotT_VelocityZ_w(a2)

				move.l	d6,d1
				asl.l	#8,d1
				asl.l	#4,d1
				divs	d7,d1

				neg.w	d1
				cmp.w	#-8*256,d1
				bge.s	.okbl
				move.w	#-8*256,d1

.okbl
				add.w	d1,ShotT_VelocityY_w(a2)
				bra.s	.impactedbul

.impactalien:
				move.w	d0,EntT_ImpactX_w(a2)
				move.w	d1,EntT_ImpactZ_w(a2)
				move.l	d6,d1
				asl.l	#4,d1
				divs	d7,d1

; move.w 4(a2),d0
; sub.w 4(a0),d0	;dy
; bge.s .above
				neg.w	d1
;.above
				cmp.w	#-8,d1
				bge.s	.okbl2
				move.w	#-8,d1

.okbl2
				move.w	d1,EntT_ImpactY_w(a2)

.impactedbul:
				bra		HitObjLoop

CheckedEmAll:

; Now put in the flames!
				move.l	(a7)+,a0

				move.w	(a0),d0
				move.l	Lvl_ObjectPointsPtr_l,a2
				move.w	(a2,d0.w*8),d1
				move.w	4(a2,d0.w*8),d2

				move.w	d1,middlex
				move.w	d2,middlez

				move.w	#9,d7

				clr.b	exitfirst
				st.b	wallbounce
				move.w	12(a0),d0
				move.l	Lvl_ZoneAddsPtr_l,a3
				move.l	(a3,d0.w*4),a3
				add.l	Lvl_DataPtr_l,a3
				move.l	a3,MiddleRoom

				move.l	Plr_ShotDataPtr_l,a3
				move.w	4(a0),d0
				ext.l	d0
				asl.l	#7,d0
				move.l	d0,oldy

				moveq	#2,d5
				move.w	#19,NUMTOCHECK

				move.w	#2,d6

radiusloop:
				move.w	#1,d7

DOFLAMES:
				move.w	NUMTOCHECK,d1
.findonefree
				move.w	12(a3),d2
				blt.s	.foundonefree
				adda.w	#64,a3
				dbra	d1,.findonefree
				rts

.foundonefree
				move.b	#2,16(a3)
				move.w	d1,NUMTOCHECK
				add.w	#1,doneflames
				move.w	middlex,d1
				move.w	middlez,d2
				move.w	d1,oldx
				move.w	d2,oldz
				move.b	ShotT_InUpperZone_b(a0),StoodInTop

				jsr		GetRand
				ext.w	d0
				muls	d5,d0
				asr.w	#1,d0
				bne.s	.xnz
				moveq	#2,d0

.xnz:
				add.w	d0,d1
				jsr		GetRand
				ext.w	d0
				muls	d5,d0
				asr.w	#1,d0
				bne.s	.znz
				moveq	#2,d0

.znz:
				add.w	d0,d2
				move.l	oldy,d3
				jsr		GetRand
				muls	d5,d0
				asr.l	#3,d0
				add.l	d0,d3
				move.l	d3,newy

				move.w	d1,newx
				move.w	d2,newz
				move.l	MiddleRoom,objroom

				movem.l	d5/d6/a0/a1/a3/d7/a6,-(a7)
				move.w	#80,extlen
				move.b	#1,awayfromwall
				jsr		MoveObject
				movem.l	(a7)+,d5/d6/a0/a1/a3/d7/a6

				move.l	objroom,a2
				move.w	(a2),12(a3)

				move.l	newy,d0

				move.l	ZoneT_Floor_l(a2),d1
				move.l	ZoneT_Roof_l(a2),d2
				tst.b	ShotT_InUpperZone_b(a0)
				beq.s	.okinbot
				move.l	ZoneT_UpperFloor_l(a2),d1
				move.l	ZoneT_UpperRoof_l(a2),d2

.okinbot:
				cmp.l	d0,d1
				bgt.s	.abovefloor
				move.l	d1,d0

.abovefloor:
				cmp.l	d0,d2
				blt.s	.belowroof
				move.l	d2,d0

.belowroof:
				move.l	d0,ShotT_AccYPos_w(a3)
				asr.l	#7,d0
				move.w	d0,4(a3)
				move.b	#2,16(a3)
				move.b	#0,ShotT_Anim_b(a3)
; sub.b d5,ShotT_Anim_b(a3)
				st		ShotT_Status_b(a3)
				move.b	StoodInTop,ShotT_InUpperZone_b(a3)
				move.b	BLOODYGREATBOMB,ShotT_Size_b(a3)
				st		ShotT_Worry_b(a3)
				move.w	(a3),d0
				move.l	Lvl_ObjectPointsPtr_l,a2
				move.w	newx,(a2,d0.w*8)
				move.w	newz,4(a2,d0.w*8)

				adda.w	#64,a3
				sub.w	#1,NUMTOCHECK
				blt.s	.nomore

				dbra	d7,DOFLAMES
				add.w	#2,d5
				dbra	d6,radiusloop

.nomore:
				rts

MiddleRoom:		dc.l	0
middlex:		dc.w	0
middlez:		dc.w	0
doneflames:		dc.w	0
