				align 2
; Byte data
Anim_LightingEnabled_b:	dc.b	$ff
anim_LiftAtTop_b:		dc.b	0
anim_LiftAtBottom_b:	dc.b	0
anim_DoorOpen_b:		dc.b	0
anim_DoorClosed_b:		dc.b	0

BRIGHT_ANIM_LIST_END	equ	-1
BRIGHT_ANIM_END			equ	999

				align 4
anim_BrightessAnimPtrs_vl:							; 0 - no animation
				dc.l	anim_BrightPulse1_vw		; 1
				dc.l	anim_BrightPulse2_vw		; 2
				dc.l	anim_BrightPulse3_vw		; 3
				dc.l	anim_BrightPulse4_vw		; 4
				dc.l	anim_BrightPulse5_vw		; 5
				dc.l	anim_BrightFlicker1_vw		; 6
				dc.l	anim_BrightFlicker2_vw		; 7

				; ABADCAFE - The list is -1 terminated and processed sequentially. I previously thought there
				; was a potential out of bounds access because 15 animations are defined but it's not these
				; tables that are indexed by the light point animation, it's Anim_BrightTable_vw

				; We can add our own animations, up to 15
				;dc.l	anim_BrightPulse1_vw		; 8    ; todo - find a way to define these in a mod file
				;dc.l	anim_BrightPulse1_vw		; 9    ; so that mods can have custom lighting animations
				;dc.l	anim_BrightPulse1_vw		; 10
				;dc.l	anim_BrightPulse1_vw		; 11
				;dc.l	anim_BrightPulse1_vw		; 12
				;dc.l	anim_BrightPulse1_vw		; 13
				;dc.l	anim_BrightPulse1_vw		; 14
				;dc.l	anim_BrightPulse1_vw		; 15
				dc.l	BRIGHT_ANIM_LIST_END

anim_BrightnessAnimStartPtrs_vl:					; 0 - No animation
				dc.l	anim_BrightPulse1_vw		; 1
				dc.l	anim_BrightPulse2_vw		; 2
				dc.l	anim_BrightPulse3_vw		; 3
				dc.l	anim_BrightPulse4_vw		; 4
				dc.l	anim_BrightPulse5_vw		; 5
				dc.l	anim_BrightFlicker1_vw		; 6
				dc.l	anim_BrightFlicker2_vw		; 7

				;dc.l	anim_BrightPulse1_vw		; 8    ; todo - find a way to define these in a mod file
				;dc.l	anim_BrightPulse1_vw		; 9    ; so that mods can have custom lighting animations
				;dc.l	anim_BrightPulse1_vw		; 10
				;dc.l	anim_BrightPulse1_vw		; 11
				;dc.l	anim_BrightPulse1_vw		; 12
				;dc.l	anim_BrightPulse1_vw		; 13
				;dc.l	anim_BrightPulse1_vw		; 14
				;dc.l	anim_BrightPulse1_vw		; 15


; TODO - could these be bytes?
anim_BrightPulse1_vw:
				dc.w	1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20
				dc.w	20,19,18,17,16,15,14,13,12,11,10,9,8,7,6,5,4,3,2,1
				dc.w	BRIGHT_ANIM_END

anim_BrightPulse2_vw:
				dc.w	9,10,11,12,13,14,15,16,17,18,19,20
				dc.w	20,19,18,17,16,15,14,13,12,11,10,9,8,7,6,5,4,3,2,1
				dc.w	1,2,3,4,5,6,7,8
				dc.w	BRIGHT_ANIM_END

anim_BrightPulse3_vw:
				dc.w	17,18,19,20
				dc.w	20,19,18,17,16,15,14,13,12,11,10,9,8,7,6,5,4,3,2,1
				dc.w	1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16
				dc.w	BRIGHT_ANIM_END

anim_BrightPulse4_vw:
				dc.w	16,15,14,13,12,11,10,9,8,7,6,5,4,3,2,1
				dc.w	1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,20,19,18,17
				dc.w	BRIGHT_ANIM_END

anim_BrightPulse5_vw:
				dc.w	8,7,6,5,4,3,2,1
				dc.w	1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,20,19,18,17,16,15,14,13,12,11,10,9
				dc.w	BRIGHT_ANIM_END

anim_BrightFlicker1_vw: ; hard transition, lamp flicker
				dcb.w	20,20
				dc.w	1
				dcb.w	30,20
				dc.w	1
				dcb.w	5,20
				dc.w	1
				dc.w	BRIGHT_ANIM_END

anim_BrightFlicker2_vw: ; soft flicker, like flame
				dc.w	-10,-9,-6,-10,-6,-5,-5,-7,-5,-10,-9,-8,-7,-5,-5,-5,-5
				dc.w	-5,-5,-5,-5,-6,-7,-8,-9,-5,-10,-9,-10,-6,-5,-5,-5,-5,-5
				dc.w	-5,-5
				dc.w	BRIGHT_ANIM_END

				even
anim_BrightenPoints:
				tst.b	Anim_LightingEnabled_b
				bne.s	.dolight

				rts

.dolight:
				; d0=brightness value
				; d1=XPOS
				; d2=ZPOS
				; d3=ROOMNUMBER
				tst.w	d0
				bgt		darken_points

				movem.l	d0-d7/a0-a6,-(a7)
				move.l	Lvl_ZoneAddsPtr_l,a0
				move.l	(a0,d3.w*4),a0
				add.l	Lvl_DataPtr_l,a0
				move.l	#CurrentPointBrights_vl,a2
				move.l	Lvl_PointsPtr_l,a3
				move.l	Lvl_ZoneBorderPointsPtr_l,a4
				lea		ZoneT_ListOfGraph_w(a0),a1

bright_points:
				move.w	(a1),d4
				blt		bright_all

				move.l	Lvl_ZoneAddsPtr_l,a0
				move.l	(a0,d4.w*4),a0
				add.l	Lvl_DataPtr_l,a0
				add.w	#8,a1
				moveq	#9,d7
				muls	#20,d4
				lea		(a4,d4.w),a5
				move.l	#CurrentPointBrights_vl,a2
				lea		(a2,d4.w*4),a2

; Do a room.
room_point_loop:
				move.w	(a5)+,d4
				blt		bright_points

				move.w	(a3,d4.w*4),d5
				move.w	2(a3,d4.w*4),d6
				sub.w	d1,d5
				bgt.s	.okpos1

				neg.w	d5

.okpos1:
				sub.w	d2,d6
				bgt.s	.okpos2

				neg.w	d6
.okpos2:
				add.w	d6,d5
				move.l	Anim_BrightY_l,d4
				cmp.l	ZoneT_Floor_l(a0),d4
				bgt		.noBRIGHT1

				cmp.l	ZoneT_Roof_l(a0),d4
				blt		.noBRIGHT1

				move.w	d5,d6
				move.l	ZoneT_Roof_l(a0),d4
				sub.l	Anim_BrightY_l,d4
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

.noBRIGHT2:
				move.w	d5,d6
				move.l	ZoneT_Floor_l(a0),d4
				sub.l	Anim_BrightY_l,d4
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

.noBRIGHT1:
				move.l	Anim_BrightY_l,d4
				cmp.l	ZoneT_UpperFloor_l(a0),d4
				bgt		.noBRIGHT4

				cmp.l	ZoneT_UpperRoof_l(a0),d4
				blt		.noBRIGHT4

				move.w	d5,d6
				move.l	ZoneT_UpperFloor_l(a0),d4
				sub.l	Anim_BrightY_l,d4
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

.noBRIGHT3:
				move.w	d5,d6
				move.l	ZoneT_UpperRoof_l(a0),d4
				sub.l	Anim_BrightY_l,d4
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

.noBRIGHT4:
				addq	#8,a2
				dbra	d7,room_point_loop

				bra		bright_points

bright_all:
				movem.l	(a7)+,d0-d7/a0-a6
				rts


Anim_BrightenPointsAngle:
				; d0=brightness value
				; d1=XPOS
				; d2=ZPOS
				; d3=ROOMNUMBER
				; d4=ANGLE

				tst.b	Anim_LightingEnabled_b
				bne.s	.dolight

				rts

.dolight:
				movem.l	d0-d7/a0-a6,-(a7)
				move.l	#SinCosTable_vw,a0
				lea		(a0,d4.w),a6
				move.l	Lvl_ZoneAddsPtr_l,a0
				move.l	(a0,d3.w*4),a0
				add.l	Lvl_DataPtr_l,a0
				move.l	#CurrentPointBrights_vl,a2
				move.l	Lvl_PointsPtr_l,a3
				move.l	Lvl_ZoneBorderPointsPtr_l,a4
				lea		ZoneT_ListOfGraph_w(a0),a1

bright_points_A:
				move.w	(a1),d4
				blt		bright_all_A

				move.l	Lvl_ZoneAddsPtr_l,a0
				move.l	(a0,d4.w*4),a0
				add.l	Lvl_DataPtr_l,a0
				add.w	#8,a1
				moveq	#9,d3
				muls	#20,d4
				lea		(a4,d4.w),a5
				move.l	#CurrentPointBrights_vl,a2
				lea		(a2,d4.w*4),a2

room_point_loop_A:
				move.w	(a5)+,d4
				blt		bright_points_A

				move.w	2(a3,d4.w*4),d5
				move.w	(a3,d4.w*4),d4
				sub.w	d1,d4
				move.w	d4,d6
				bgt.s	.okpos1

				neg.w	d4

.okpos1:
				sub.w	d2,d5
				move.w	d5,d7
				bgt.s	.okpos2

				neg.w	d5

.okpos2:
				movem.l	d0/d1/d2/d3/d4/d5,-(a7)
				move.w	(a6),d0
				move.w	2048(a6),d1
				muls	d7,d1
				muls	d6,d0
				add.l	d0,d1
				ble		behind_point

				move.l	d1,d5
				neg.l	d5
				add.l	#30*65536,d5
				bge.s	.okkkkk

				moveq	#0,d5

.okkkkk:
				move.w	(a6),d0
				move.w	2048(a6),d1
				muls	d0,d7
				muls	d1,d6
				sub.l	d6,d7
				bgt.s	.okkk

				neg.l	d7

.okkk:
				add.l	d5,d7
				asl.l	#2,d7
				swap	d7
				movem.l	(a7)+,d0/d1/d2/d3/d4/d5
				add.w	d7,d5
				add.w	d4,d5
				move.l	Anim_BrightY_l,d4
				cmp.l	ZoneT_Floor_l(a0),d4
				bgt		.noBRIGHT1

				cmp.l	ZoneT_Roof_l(a0),d4
				blt		.noBRIGHT1

				move.w	d5,d6
				move.l	ZoneT_Roof_l(a0),d4
				sub.l	Anim_BrightY_l,d4
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

.noBRIGHT2:
				move.w	d5,d6
				move.l	ZoneT_Floor_l(a0),d4
				sub.l	Anim_BrightY_l,d4
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

.noBRIGHT1:
				move.l	Anim_BrightY_l,d4
				cmp.l	ZoneT_UpperFloor_l(a0),d4
				bgt		.noBRIGHT4

				cmp.l	ZoneT_UpperRoof_l(a0),d4
				blt		.noBRIGHT4

				move.w	d5,d6
				move.l	ZoneT_UpperFloor_l(a0),d4
				sub.l	Anim_BrightY_l,d4
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

.noBRIGHT3:
				move.w	d5,d6
				move.l	ZoneT_UpperRoof_l(a0),d4
				sub.l	Anim_BrightY_l,d4
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

.noBRIGHT4:
				addq	#8,a2
				dbra	d3,room_point_loop_A

				bra		bright_points

behind_point:
				movem.l	(a7)+,d0/d1/d2/d3/d4/d5
				addq	#8,a2
				dbra	d7,room_point_loop_A

				bra		bright_points_A

bright_all_A:
				movem.l	(a7)+,d0-d7/a0-a6
				rts

darken_points:
				movem.l	d0-d7/a0-a6,-(a7)
				move.l	Lvl_ZoneAddsPtr_l,a0
				move.l	(a0,d3.w*4),a0
				add.l	Lvl_DataPtr_l,a0
				move.l	#CurrentPointBrights_vl,a2
				move.l	Lvl_PointsPtr_l,a3
				move.l	a0,a1
				add.w	ZoneT_Points_w(a0),a1

dark_points:
				move.w	(a1)+,d4
				blt.s	dark_all

				move.w	(a3,d4.w*4),d5
				move.w	2(a3,d4.w*4),d6
				sub.w	d1,d5
				bgt.s	.okpos1

				neg.w	d5

.okpos1:
				sub.w	d2,d6
				bgt.s	.okpos2

				neg.w	d6

.okpos2:
				add.w	d5,d6
				asr.w	#5,d6
				add.w	d0,d6
				ble.s	dark_points

				add.w	d6,(a2,d4.w*4)
				add.w	d6,2(a2,d4.w*4)
				bra.s	dark_points

dark_all:
				movem.l	(a7)+,d0-d7/a0-a6
				rts

Flash:

; D0=number of a zone, D1=brightness change

				cmp.w	#-20,d1
				bgt.s	.okflash

				move.w	#-20,d1

.okflash:
				movem.l	d0/a0/a1,-(a7)
				move.l	#CurrentPointBrights_vl,a1
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
				move.l	#Zone_BrightTable_vl,a1
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

;prot2:			dc.w	0
anim_ExpRadius_w:	dc.w	0

Anim_ExplodeIntoBits:
				move.w	d3,anim_ExpRadius_w
				cmp.w	#7,d2
				ble.s	.oksplut
				move.w	#7,d2

.oksplut:
				move.l	NastyShotDataPtr_l,a5
				move.w	#19,d1

.findeight:
				move.w	12(a5),d0
				blt.s	.gotonehere

				adda.w	#64,a5
				dbra	d1,.findeight

				rts

.gotonehere:
				move.b	#0,ShotT_Power_w(a5)
				move.l	Lvl_ObjectPointsPtr_l,a2
				move.w	(a5),d3
				lea		(a2,d3.w*8),a2
				move.w	newx,d0
				move.w	d0,(a2)
				move.w	newz,d0
				move.w	d0,4(a2)
				move.b	#2,16(a2)
				jsr		GetRand

				and.w	#8190,d0
				move.l	#SinCosTable_vw,a2
				adda.w	d0,a2
				move.w	(a2),d3
				move.w	2048(a2),d4
				jsr		GetRand

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
				move.w	4(a0),d0
				move.w	d0,4(a5)
				add.w	#6,d0
				ext.l	d0
				asl.l	#7,d0
				move.l	d0,ShotT_AccYPos_w(a5)
				move.b	Anim_SplatType_w,ShotT_Size_b(a5)

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

.gotemall:
				rts

brightanim:
				move.l	#Anim_BrightTable_vw,a1
				move.l	#anim_BrightessAnimPtrs_vl,a3
				move.l	#anim_BrightnessAnimStartPtrs_vl,a4

.dobrightanims:
				move.l	(a3),d0
				blt		.nomoreanims

				move.l	d0,a2
				move.w	(a2)+,d0
				cmp.w	#BRIGHT_ANIM_END,d0
				bne.s	.itsabright

				move.l	(a4),a2
				move.w	(a2)+,d0

.itsabright:
				move.l	a2,(a3)+
				addq	#4,a4
				move.w	d0,(a1)+
				bra.s	.dobrightanims

.nomoreanims:
				rts

BACKSFX:
				move.w	Anim_TempFrames_w,d0
				sub.w	d0,anim_TimeToNoise_w
				bgt		.nosfx

				jsr		GetRand

				lsr.w	#3,d0
				and.w	#127,d0
				add.w	#100,d0
				move.w	d0,anim_TimeToNoise_w
				move.l	RoomPtr_l,a0
				add.w	anim_OddEven_w,a0
				move.w	#2,d0
				sub.w	anim_OddEven_w,d0
				move.w	d0,anim_OddEven_w
				move.w	ZoneT_BackSFXMask_w(a0),d1		; mask for sfx
				beq		.nosfx

				jsr		GetRand

				lsr.w	#3,d0

.notfound:
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

				bsr		Plr1_Shot

				bsr		Plr2_Shot

; bsr SwitchRoutine

				bsr		ObjectHandler

				bsr		DoorRoutine

				move.w	#0,Plr1_FloorSpd_w
				move.w	#0,plr2_FloorSpd_w
				bsr		LiftRoutine

				cmp	#0,Anim_Timer_w		;Anim_Timer_w decriment moved to VBlankInterrupt:
				bgt.s	.notzero

				bsr		brightanim

				move.w	#5,Anim_Timer_w	;was 2 AL
				move.l	otherrip,d0		;what are these for?
				move.l	RipTear,otherrip	;""
				move.l	d0,RipTear		;""

.notzero:
				rts

DoWaterAnims:
				move.w	#20,d0

wateranimlop:
				move.l	(a0)+,d1
				move.l	(a0)+,d2
				move.l	(a0),d3
				move.w	4(a0),d4
				move.w	d4,d5
				muls	Anim_TempFrames_w,d5
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

LiftRoutine:
				move.w	#-1,anim_ThisDoor_w
				move.l	Lvl_LiftDataPtr_l,a0
				move.l	#anim_LiftHeightTable_vw,a6

doalift:
				add.w	#1,anim_ThisDoor_w
				move.w	(a0)+,d0				; bottom of lift movement
				cmp.w	#999,d0
				bne		notallliftsdone

				move.w	#999,(a6)
				move.w	#0,anim_LiftOnlyLocks_w
				bsr		DoWaterAnims

				rts

notallliftsdone:
				move.w	(a0)+,d1				; top of lift movement.
				move.w	(a0)+,anim_OpeningSpeed_w
				neg.w	anim_OpeningSpeed_w
				move.w	(a0)+,anim_ClosingSpeed_w
				move.w	(a0)+,anim_OpenDuration_w
				move.w	(a0)+,anim_OpeningSoundFX_w
				move.w	(a0)+,anim_ClosingSoundFX_w
				move.w	(a0)+,anim_OpenedSoundFX_w
				move.w	(a0)+,anim_ClosedSoundFX_w
				subq.w	#1,anim_OpeningSoundFX_w
				subq.w	#1,anim_ClosingSoundFX_w
				subq.w	#1,anim_OpenedSoundFX_w
				subq.w	#1,anim_ClosedSoundFX_w
				move.w	(a0)+,d2
				move.w	(a0)+,d3
				sub.w	Plr1_TmpXOff_l,d2
				sub.w	Plr1_TmpZOff_l,d3
				move.w	Temp_CosVal_w,d4
				move.w	Temp_SinVal_w,d5
				muls	d2,d4
				muls	d3,d5
				sub.l	d5,d4
				add.l	d4,d4
				swap	d4
				move.w	d4,Noisex
				move.w	Temp_SinVal_w,d4
				move.w	Temp_CosVal_w,d5
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
				move.w	d2,anim_FloorMoveSpeed_w
				muls	Anim_TempFrames_w,d2
				add.w	d2,d3
				move.w	d7,d2
				cmp.w	d3,d0
				sle		anim_LiftAtBottom_b
				bgt.s	.nolower

				tst.w	d2
				beq.s	.nonoise3

				move.w	#50,Noisevol
				move.w	anim_ClosedSoundFX_w,Samplenum
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
				sge		anim_LiftAtTop_b
				blt.s	.noraise

				tst.w	d2
				beq.s	.nonoise

				move.w	#0,(a6)
				move.w	#50,Noisevol
				move.w	anim_OpenedSoundFX_w,Samplenum
				blt.s	.nonoise

				move.b	#1,chanpick
				clr.b	notifplaying
				move.w	#$fffd,IDNUM

				movem.l	a0/a3/d0/d1/d2/d3/d6/d7,-(a7)
				jsr		MakeSomeNoise
				movem.l	(a7)+,a0/a3/d0/d1/d2/d3/d6/d7

.nonoise:
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
				; 0xABADCAFE - come back to the overflow here
				;ext.l	d3	; Safety - sign extend before shift
				;asl.l	#8,d3
				move.w	(a0)+,d5
				move.l	Lvl_ZoneAddsPtr_l,a1
				move.l	(a1,d5.w*4),a1
				add.l	Lvl_DataPtr_l,a1
				move.w	(a1),d5
				move.l	Plr1_RoomPtr_l,a3
				move.l	d3,2(a1)
				neg.w	d0
				cmp.w	(a3),d5
				seq		plr1_StoodOnLift_b
				bne.s	.nosetfloorspd1

				move.w	anim_FloorMoveSpeed_w,Plr1_FloorSpd_w

.nosetfloorspd1:
				move.l	Plr2_RoomPtr_l,a3
				cmp.w	(a3),d5
				seq		plr2_StoodOnLift_b
				bne.s	.nosetfloorspd2

				move.w	anim_FloorMoveSpeed_w,plr2_FloorSpd_w

.nosetfloorspd2:
				move.w	(a0)+,d2				; conditions
; and.w Conditions,d2
; cmp.w -2(a0),d2
				move.w	anim_ThisDoor_w,d2
				move.w	anim_LiftOnlyLocks_w,d5
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
				tst.b	anim_LiftAtTop_b
				bne		tstliftlower

				tst.b	anim_LiftAtBottom_b
				bne		tstliftraise

				move.w	#0,d1

backfromlift:
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
				move.w	anim_ActionSoundFX_w,Samplenum
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

nomoreliftwalls:
				bra		doalift

				rts

tstliftlower:
				move.w	anim_ClosingSoundFX_w,anim_ActionSoundFX_w
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
				move.w	anim_ClosingSpeed_w,d7
				tst.b	plr1_StoodOnLift_b
				beq.s	.noplr1

				move.w	#$8000,d1
				bra		backfromlift

.noplr1:
				tst.b	Plr2_TmpSpcTap_b
				beq.s	.noplr2

				or.w	#%100000000000,d1
				move.w	anim_ClosingSpeed_w,d7
				tst.b	plr2_StoodOnLift_b
				beq.s	.noplr2

				move.w	#$8000,d1
				bra		backfromlift

.noplr2:
				bra		backfromlift

lift1:
				move.w	anim_ClosingSpeed_w,d7
				tst.b	plr1_StoodOnLift_b
				bne.s	lift1b

				tst.b	plr2_StoodOnLift_b
				bne.s	lift1b

				move.w	#%100100000000,d1
				bra		backfromlift

lift1b:
				move.w	#$8000,d1
				bra		backfromlift

lift2:
				move.w	#$8000,d1
				move.w	anim_ClosingSpeed_w,d7
				bra		backfromlift

lift3:
				move.w	#$0,d1
				bra		backfromlift

tstliftraise:
				move.w	anim_OpeningSoundFX_w,anim_ActionSoundFX_w
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
				move.w	anim_OpeningSpeed_w,d7
				tst.b	plr1_StoodOnLift_b
				beq.s	.noplr1

				move.w	#$8000,d1
				bra		backfromlift

.noplr1:
				tst.b	Plr2_TmpSpcTap_b
				beq.s	.noplr2

				or.w	#%100000000000,d1
				move.w	anim_OpeningSpeed_w,d7
				tst.b	plr2_StoodOnLift_b
				beq.s	.noplr2

				move.w	#$8000,d1
				bra		backfromlift

.noplr2:
				bra		backfromlift

rlift1:
				move.w	anim_OpeningSpeed_w,d7
				tst.b	plr1_StoodOnLift_b
				bne.s	rlift1b

				tst.b	plr2_StoodOnLift_b
				bne.s	rlift1b

				move.w	#%100100000000,d1
				bra		backfromlift

rlift1b:
				move.w	#$8000,d1
				bra		backfromlift

rlift2:
				move.w	#$8000,d1
				move.w	anim_OpeningSpeed_w,d7
				bra		backfromlift

rlift3:
				move.w	#$0,d1
				bra		backfromlift



				even
DoorRoutine:
				move.l	#anim_DoorHeightTable_vw,a6
				move.l	Lvl_DoorDataPtr_l,a0
				move.w	#-1,anim_ThisDoor_w

doadoor:
				add.w	#1,anim_ThisDoor_w
				move.w	(a0)+,d0				; bottom of door movement
				cmp.w	#999,d0
				bne		notalldoorsdone

				move.w	#999,(a6)
				move.w	#0,Anim_DoorAndLiftLocks_l
				rts

notalldoorsdone:
				move.w	(a0)+,d1				; top of door movement.
				move.w	(a0)+,anim_OpeningSpeed_w
				neg.w	anim_OpeningSpeed_w
				move.w	(a0)+,anim_ClosingSpeed_w
				move.w	(a0)+,anim_OpenDuration_w
				move.w	(a0)+,anim_OpeningSoundFX_w
				move.w	(a0)+,anim_ClosingSoundFX_w
				move.w	(a0)+,anim_OpenedSoundFX_w
				move.w	(a0)+,anim_ClosedSoundFX_w
				subq.w	#1,anim_OpeningSoundFX_w
				subq.w	#1,anim_ClosingSoundFX_w
				subq.w	#1,anim_OpenedSoundFX_w
				subq.w	#1,anim_ClosedSoundFX_w
				move.w	(a0)+,d2
				move.w	(a0)+,d3
				sub.w	Plr1_TmpXOff_l,d2
				sub.w	Plr1_TmpZOff_l,d3
				move.w	Temp_CosVal_w,d4
				move.w	Temp_SinVal_w,d5
				muls	d2,d4
				muls	d3,d5
				sub.l	d5,d4
				add.l	d4,d4
				swap	d4
				move.w	d4,Noisex
				move.w	Temp_SinVal_w,d4
				move.w	Temp_CosVal_w,d5
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
				muls	Anim_TempFrames_w,d2
				add.w	d2,d3
				move.w	2(a0),d2
				cmp.w	d3,d0
				sle		anim_DoorClosed_b
				bgt.s	nolower

				tst.w	d2
				beq.s	.nonoise
				move.w	#50,Noisevol
				move.w	anim_ClosedSoundFX_w,Samplenum
				blt.s	.nonoise

				move.b	#1,chanpick
				clr.b	notifplaying
				move.w	#$fffd,IDNUM
				movem.l	a0/a3/d0/d1/d2/d3/d6/d7,-(a7)
				jsr		MakeSomeNoise

				movem.l	(a7)+,a0/a3/d0/d1/d2/d3/d6/d7
.nonoise:
				moveq	#0,d2
				move.w	d3,d0

nolower:
				cmp.w	d3,d1
				sge		anim_DoorOpen_b
				blt.s	noraise

				tst.w	d2
				beq.s	.nonoise

				move.w	#0,(a6)
				move.w	#50,Noisevol
				move.w	anim_OpenedSoundFX_w,Samplenum
				blt.s	.nonoise

				move.b	#1,chanpick
				clr.b	notifplaying
				move.w	#$fffd,IDNUM
				movem.l	a0/a3/d0/d1/d2/d3/d6/d7,-(a7)
				jsr		MakeSomeNoise

				movem.l	(a7)+,a0/a3/d0/d1/d2/d3/d6/d7

.nonoise:
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
				;ext.l	d3		; Safety: Sign extend before shift
				;asl.l	#8,d3

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
				tst.b	anim_DoorOpen_b
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
				move.w	anim_ThisDoor_w,d2
				move.w	Anim_DoorAndLiftLocks_l,d5
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
				tst.b	anim_DoorOpen_b
				bne		tstdoortoclose

				tst.b	anim_DoorClosed_b
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
				move.w	anim_ActionSoundFX_w,Samplenum
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

nomoredoorwalls:
				addq	#2,a6
				bra		doadoor

				rts

tstdoortoopen:
				move.w	anim_OpeningSoundFX_w,anim_ActionSoundFX_w
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
				move.w	anim_OpeningSpeed_w,d7
				bra		backfromtst

door1:
				move.w	#%100100000000,d1
				move.w	anim_OpeningSpeed_w,d7
				bra		backfromtst

door2:
				move.w	#%10000000000,d1
				move.w	anim_OpeningSpeed_w,d7
				bra		backfromtst

door3:
				move.w	#%1000000000,d1
				move.w	anim_OpeningSpeed_w,d7
				bra		backfromtst

door4:
				move.w	#$8000,d1
				move.w	anim_OpeningSpeed_w,d7
				bra		backfromtst

door5:
				move.w	#$0,d1
				bra		backfromtst

tstdoortoclose:
				move.w	Anim_TempFrames_w,d1
				add.w	(a6),d1
				move.w	d1,(a6)
				cmp.w	anim_OpenDuration_w,d1
				bge.s	.oktoclose

				move.w	#1,d4

.oktoclose:
				move.w	anim_ClosingSoundFX_w,anim_ActionSoundFX_w
				tst.w	d4
				beq.s	dclose0

				bra.s	dclose1

dclose0:
				move.w	anim_ClosingSpeed_w,d7
				move.w	#$8000,d1
				bra		backfromtst

dclose1:
				move.w	#$0,d1
				bra		backfromtst

SwitchRoutine:
				move.l	Lvl_SwitchDataPtr_l,a0
				move.w	#7,d0
				move.l	Lvl_PointsPtr_l,a1

CheckSwitches:
				tst.b	Plr1_TmpSpcTap_b
				bne		p1_SpaceIsPressed

backtop2:
				tst.b	Plr2_TmpSpcTap_b
				bne		p2_SpaceIsPressed

backtoend:
				tst.b	2(a0)
				beq		nobutt

				tst.b	10(a0)
				beq		nobutt

				move.w	Anim_TempFrames_w,d1
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

				align 4
tempxoff:		dc.w	0
tempzoff:		dc.w	0
tempRoompt:		dc.l	0

bulyspd:		dc.w	0
closedist:		dc.w	0

				include	"newplayershoot.s"


NUMZONES:		dc.w	0

ObjectHandler:
				move.l	#ObjectWorkspace_vl,WorkspacePtr_l
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
				add.l	#8,WorkspacePtr_l
				add.l	#2,AI_DamagePtr_l
				add.l	#8,AI_BoredomPtr_l
				bra		Objectloop

doneallobj:
				rts

JUMPALIEN:
				tst.w	12(a0)
				blt.s	.dontworry

				tst.b	EntT_NumLives_b(a0)
				beq.s	.nolock

				move.l	EntT_DoorsHeld_w(a0),d0
				or.l	d0,Anim_DoorAndLiftLocks_l

.nolock:
				tst.b	ShotT_Worry_b(a0)
				beq		.dontworry
				jsr		ItsAnAlien

				tst.w	12-64(a0)
				blt.s	.notanaux
				move.w	12(a0),12-64(a0)
				move.w	12(a0),EntT_GraphicRoom_w-64(a0)

.notanaux:
.dontworry:
				bra		doneobj

JUMPOBJECT:
				tst.w	12(a0)
				blt.s	.dontworry

				jsr		ItsAnObject

.dontworry:
				bra		doneobj

JUMPBULLET:
				jsr		ItsABullet
				bra		doneobj

;ItsAGasPipe:
;				clr.b	ShotT_Worry_b(a0)
;				move.w	Anim_TempFrames_w,d0
;				tst.w	EntT_Timer3_w(a0)
;				ble.s	maybeflame

;				sub.w	d0,EntT_Timer3_w(a0)
;				move.w	#5,EntT_Timer2_w(a0)
;				move.w	#10,EntT_Timer4_w(a0)
;				rts

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

.findonefree:
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
				move.l	#SinCosTable_vw,a1
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

				include	"newaliencontrol.s"

;nextCPt:		dc.w	0

RipTear:		dc.l	256*17*65536
otherrip:		dc.l	256*18*65536
Conditions:		dc.l	0

; Keep this comment, animation format is probably the same
; Format of animations:
; Size (-1 = and of anim) (w)
; Address of Frame. (l)
; height offset (w)

;tsta:			dc.l	0
timeout:		dc.w	0
anim_Brightness_w:		dc.w	0

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
				move.w	Anim_TempFrames_w,d2
				add.w	d2,ShotT_Lifetime_w(a0)

infinite:
noworrylife:
				move.w	#0,Obj_ExtLen_w
				move.b	#$ff,Obj_AwayFromWall_b
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
				move.b	5(a1,d1.w),anim_Brightness_w
				bra.s	.donegraph

.bitmapgraph:
				move.b	(a1,d1.w),9(a0)
				move.b	1(a1,d1.w),11(a0)
				move.w	2(a1,d1.w),6(a0)
				move.b	5(a1,d1.w),anim_Brightness_w
				bra.s	.donegraph

.glaregraph:
				move.b	(a1,d1.w),d0
				ext.w	d0
				neg.w	d0
				move.w	d0,8(a0)
				move.b	1(a1,d1.w),11(a0)
				move.w	2(a1,d1.w),6(a0)
				move.b	5(a1,d1.w),anim_Brightness_w

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
				move.b	anim_Brightness_w,d0
				beq.s	.nobright

				neg.w	d0
				move.w	(a0),d2
				move.l	Lvl_ObjectPointsPtr_l,a2
				move.w	(a2,d2.w*8),d1
				move.w	4(a2,d2.w*8),d2
				move.w	4(a0),d3
				ext.l	d3
				asl.l	#7,d3
				move.l	d3,Anim_BrightY_l
				move.w	12(a0),d3
				jsr		anim_BrightenPoints

.nobright:
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
				move.b	5(a1,d1.w),anim_Brightness_w
				bra.s	.donegraph

.bitmapgraph:
				move.b	(a1,d1.w),9(a0)
				move.b	1(a1,d1.w),11(a0)
				move.w	2(a1,d1.w),6(a0)
				move.b	5(a1,d1.w),anim_Brightness_w
				bra.s	.donegraph

.glaregraph:
				move.b	(a1,d1.w),d0
				ext.w	d0
				neg.w	d0
				move.w	d0,8(a0)
				move.b	1(a1,d1.w),11(a0)
				move.w	2(a1,d1.w),6(a0)
				move.b	5(a1,d1.w),anim_Brightness_w

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
				move.l	Lvl_ObjectPointsPtr_l,a1
				move.w	(a0),d1
				lea		(a1,d1.w*8),a1
				move.l	(a1),d2
				move.l	d2,oldx
				move.l	ShotT_VelocityX_w(a0),d3
				move.w	d3,d4
				swap	d3
				move.w	Anim_TempFrames_w,d5
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
				muls	Anim_TempFrames_w,d3
				move.l	BulT_Gravity_l(a6),d5
				beq.s	nograv

				muls	Anim_TempFrames_w,d5
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
				sne		Obj_WallBounce_b
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

				move.w	#1,WallLength_w

lalal:
				st		MOVING
				movem.l	d0/d7/a0/a1/a2/a4/a5/a6,-(a7)
				jsr		MoveObject

				moveq	#0,d0
				move.b	anim_Brightness_w,d0
				beq.s	.nobright

				neg.w	d0
				move.w	newx,d1
				move.w	newz,d2
				move.l	newy,Anim_BrightY_l
				move.l	objroom,a0
				move.w	(a0),d3
				jsr		anim_BrightenPoints

.nobright:
				movem.l	(a7)+,d0/d7/a0/a1/a2/a4/a5/a6

nomovebul:
				move.b	StoodInTop,ShotT_InUpperZone_b(a0)
				tst.b	Obj_WallBounce_b
				beq.s	.notabouncything

				tst.b	hitwall
				beq		.nothitwall

; we have hit a wall....
				move.w	ShotT_VelocityZ_w(a0),d0
				muls	WallXSize_w,d0
				move.w	ShotT_VelocityX_w(a0),d1
				muls	WallZSize_w,d1
				sub.l	d1,d0
				divs	WallLength_w,d0
				move.w	ShotT_VelocityX_w(a0),d1
				move.w	WallZSize_w,d2
				add.w	d2,d2
				muls	d0,d2
				divs	WallLength_w,d2
				add.w	d2,d1
				move.w	d1,ShotT_VelocityX_w(a0)
				move.w	ShotT_VelocityZ_w(a0),d1
				move.w	WallXSize_w,d2
				add.w	d2,d2
				muls	d0,d2
				divs	WallLength_w,d2
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

.hitsomething:
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
;************
;* Check if hit a nasty

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
.oksqr:
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
.checkedall:
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
				rts

****************************************

putinbackdrop:
				move.l	a0,-(a7)
				move.w	tmpangpos,d5
				and.w	#4095,d5
				muls	#648,d5

				; 0xABADCAFE - division pogrom
				;divs	#4096,d5

				asr.l	#8,d5
				asr.l	#4,d5
				muls	#240,d5

; CACHE_ON d1
				tst.b	Vid_FullScreen_b
				bne		BIGBACK

				move.l	Vid_FastBufferPtr_l,a0
				move.l	Draw_BackdropImagePtr_l,a5
				move.l	a5,a3
				add.l	#155520,a3
				add.l	#240,a5
; move.l #EndBackPicture,a3
; move.l #Draw_BackdropImagePtr_l+240,a5
				move.l	Draw_BackdropImagePtr_l,a1
; lea.l Draw_BackdropImagePtr_l,a1
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
				move.b	d0,SCREEN_WIDTH(a2)
				addq	#1,a4
				move.b	(a4)+,d0
				move.b	d0,SCREEN_WIDTH*2(a2)
				move.b	(a4)+,d0
				move.b	d0,SCREEN_WIDTH*3(a2)
				adda.w	#SCREEN_WIDTH*4,a2
				dbra	d3,vertline

				add.w	d1,a1
				cmp.l	a1,a3
				bgt.s	.noend

				move.l	a5,a1

.noend:
				exg		d1,d2
				exg		d2,d5
				addq.w	#1,a0
				dbra	d4,horline

				move.l	(a7)+,a0
				rts

BIGBACK:
				move.l	Vid_FastBufferPtr_l,a0
				move.l	Draw_BackdropImagePtr_l,a5
				move.l	a5,a3
				add.l	#155520,a3
				add.l	#240,a5
; move.l #EndBackPicture,a3
; move.l #Draw_BackdropImagePtr_l+240,a5
				move.l	Draw_BackdropImagePtr_l,a1
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
				move.b	d0,SCREEN_WIDTH*3(a2)
				swap	d0
				move.b	d0,SCREEN_WIDTH(a2)
				lsr.l	#8,d0
				move.b	d0,(a2)
				swap	d0
				move.b	d0,SCREEN_WIDTH*2(a2)
				adda.w	#SCREEN_WIDTH*4,a2
				dbra	d3,.vertline

				add.w	#240,a1
				cmp.l	a1,a3
				bgt.s	.noend

				move.l	a5,a1

.noend:
				addq.w	#1,a0
				dbra	d4,.horline
				move.l	(a7)+,a0
				rts




ComputeBlast:
				clr.w	anim_DoneFlames_w
				move.w	d0,d6
				move.w	d0,anim_MaxDamage_w
				move.w	d0,d1
				ext.l	d6
				neg.w	d1
				move.w	12(a0),d0
; jsr Flash

				move.l	Lvl_ZoneAddsPtr_l,a2
				move.l	(a2,d0.w*4),a2
				add.l	Lvl_DataPtr_l,a2
				move.l	a2,anim_MiddleRoom_l
				move.l	Lvl_ObjectDataPtr_l,a2
				suba.w	#64,a2
				ext.l	d6
				move.l	a0,-(a7)

HitObjLoop:
				move.l	anim_MiddleRoom_l,FromRoom
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

.checkalien:
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

.findhigh:
				btst	d4,d2
				dbne	d4,.findhigh

.foundhigh:
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

.stillnot0:
				move.w	d4,d3
				muls	d1,d3
				sub.l	d2,d3
				asr.l	#1,d3
				divs	d4,d3
				sub.w	d3,d4					; second approx
				bgt		.stillnot02

				move.w	#1,d4

.stillnot02:
				move.w	d4,d3
				muls	d3,d3
				sub.l	d2,d3
				asr.l	#1,d3
				divs	d4,d3
				sub.w	d3,d4					; second approx
				bgt		.stillnot03

				move.w	#1,d4

.stillnot03:
.oksqr:
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
				cmp.w	anim_MaxDamage_w,d5
				blt.s	okdamage

				move.w	anim_MaxDamage_w,d5

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

.okbl:
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

.okbl2:
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
				move.w	d1,anim_MiddleX_w
				move.w	d2,anim_MiddleZ_w
				move.w	#9,d7
				clr.b	exitfirst
				st.b	Obj_WallBounce_b
				move.w	12(a0),d0
				move.l	Lvl_ZoneAddsPtr_l,a3
				move.l	(a3,d0.w*4),a3
				add.l	Lvl_DataPtr_l,a3
				move.l	a3,anim_MiddleRoom_l
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

.findonefree:
				move.w	12(a3),d2
				blt.s	.foundonefree

				adda.w	#64,a3
				dbra	d1,.findonefree

				rts

.foundonefree:
				move.b	#2,16(a3)
				move.w	d1,NUMTOCHECK
				add.w	#1,anim_DoneFlames_w
				move.w	anim_MiddleX_w,d1
				move.w	anim_MiddleZ_w,d2
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
				move.l	anim_MiddleRoom_l,objroom

				movem.l	d5/d6/a0/a1/a3/d7/a6,-(a7)
				move.w	#80,Obj_ExtLen_w
				move.b	#1,Obj_AwayFromWall_b
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
