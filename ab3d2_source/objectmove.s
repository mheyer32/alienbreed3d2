			align 4
obj_RoomPathPtr_l:	dc.l	0
Obj_ExtLen_w:		dc.w	0
WallXSize_w:		dc.w	0
WallZSize_w:		dc.w	0
WallLength_w:		dc.w	0
obj_QuitLimit_w:	dc.w	0
Obj_AwayFromWall_b:	dc.b	0 ; accessed as byte
Obj_WallBounce_b:	dc.b	0 ; accessed as byte

MoveObject:
				move.l	Obj_ZonePtr_l,obj_ZoneBackupPtr_l
				move.w	#50,obj_QuitLimit_w
				move.l	#Obj_RoomPath_vw,obj_RoomPathPtr_l
				sf		hitwall
				move.w	Obj_NewX_w,d0
				sub.w	Obj_OldX_w,d0
				move.w	d0,Obj_XDiff_w
				move.w	Obj_NewZ_w,d0
				sub.w	Obj_OldZ_w,d0
				move.w	d0,Obj_ZDiff_w
				tst.w	Obj_XDiff_w
				bne.s	.moving

				tst.w	Obj_ZDiff_w
				bne.s	.moving
				rts

.moving:
				move.l	Obj_NewY_w,wallhitheight
				move.l	Obj_ZonePtr_l,a0

gobackanddoitallagain:
				move.l	a0,a5
				adda.w	ZoneT_EdgeListOffset_w(a5),a0
				move.l	a0,test
				move.l	Lvl_ZoneEdgePtr_l,a1

checkwalls:
				move.w	(a0)+,d0
				blt		no_more_walls

				asl.w	#4,d0
				lea		(a1,d0.w),a2

;*********************************
;* Check if we are within exit limits
;* of zone.
;*********************************

; A2 contains current EdgeT address

				move.l	#-65536*256,d0
				move.l	d0,LowerRoofHeight
				move.l	d0,UpperRoofHeight
				move.l	d0,LowerFloorHeight
				move.l	d0,UpperFloorHeight
				moveq	#0,d1
				move.w	EdgeT_JoinZone_w(a2),d1
				blt		thisisawall2

				move.l	Lvl_ZonePtrsPtr_l,a4
				move.l	(a4,d1.w*4),a4
				move.l	ZoneT_Floor_l(a4),d1
				move.l	d1,LowerFloorHeight
				move.l	ZoneT_Roof_l(a4),d2
				move.l	d2,LowerRoofHeight
				bra		thisisawall1

				; Unreachable code?
				sub.l	d2,d1
				cmp.l	thingheight,d1
				ble		thisisawall1

				move.l	Obj_OldY_w,d0
				move.l	d0,d1
				add.l	thingheight,d1
				sub.l	ZoneT_Floor_l(a4),d1
				bgt.s	chkstepup

				neg.l	d1
				cmp.l	StepDownVal,d1
				blt.s	botinsidebot

chkstepup:
				cmp.l	StepUpVal,d1
				blt.s	botinsidebot

; We have a wall!
				bra		thisisawall1

botinsidebot:
				sub.l	ZoneT_Roof_l(a4),d0
				blt.s	thisisawall1

				bra		checkwalls

thisisawall1:
				move.l	ZoneT_UpperFloor_l(a4),d1
				move.l	d1,UpperFloorHeight
				move.l	ZoneT_UpperRoof_l(a4),d2
				sub.l	d2,d1
				move.l	d2,UpperRoofHeight
				bra		thisisawall2

				; Unreachable ?
				cmp.l	thingheight,d1
				ble		thisisawall2

				move.l	Obj_OldY_w,d0
				move.l	d0,d1
				add.l	thingheight,d1
				sub.l	ZoneT_UpperFloor_l(a4),d1
				bgt.s	chkstepup2

				neg.l	d1
				cmp.l	StepDownVal,d1
				blt.s	botinsidebot2
				bra.s	thisisawall2

chkstepup2:
				cmp.l	StepUpVal,d1
				blt.s	botinsidebot2

; We have a wall!
				bra		thisisawall2

botinsidebot2:
				sub.l	ZoneT_UpperRoof_l(a4),d0
				blt.s	thisisawall2

				bra		checkwalls

thisisawall2:
				move.l	#0,a4
				move.l	#0,a6
				move.b	Obj_AwayFromWall_b,d3
				blt.s	.notomatoes

				move.b	EdgeT_RotNormalX_b(a2),d2
				ext.w	d2

				move.b	EdgeT_RotNormalZ_b(a2),d4
				ext.w	d4

				tst.b	d3
				beq.s	.noshift
				asl.w	d3,d2
				asl.w	d3,d4

.noshift:
				move.w	d2,a4
				move.w	d4,a6

.notomatoes:
				move.w	Obj_NewX_w,d0
				move.w	Obj_NewZ_w,d1
				sub.w	(a2),d0 ; EdgeT_XPos_w
				sub.w	EdgeT_ZPos_w(a2),d1
				sub.w	a4,d0
				sub.w	a6,d1
				move.w	EdgeT_XLen_w(a2),d2
				sub.w	a4,d2
				sub.w	a6,d2
				muls	d2,d1
				move.w	EdgeT_ZLen_w(a2),d5
				add.w	a4,d5
				sub.w	a6,d5
				muls	d5,d0
				sub.l	d1,d0
				ble		chkhttt

				move.w	EdgeT_Length_w(a2),d3
				add.w	Obj_ExtLen_w,d3
				divs	d3,d0
				cmp.w	#32,d0
				bge		oknothitwall

				move.w	wallflags(pc),d0
				or.w	d0,EdgeT_Flags_w(a2)
				bra		oknothitwall

chkhttt:
				;move.w	d2,WALLXLEN
				;move.w	d5,WALLZLEN

				move.l	d0,d7
				move.w	EdgeT_Length_w(a2),d3
				add.w	Obj_ExtLen_w,d3
				divs	d3,d7					;  d

				move.l	Obj_NewY_w,d4
				sub.l	Obj_OldY_w,d4
; beq .dontworryhit

				move.w	Obj_OldX_w,d0
				move.w	Obj_OldZ_w,d1
				sub.w	(a2),d0 ; EdgeT_XPos_w
				sub.w	EdgeT_ZPos_w(a2),d1
				sub.w	a4,d0
				sub.w	a6,d1
				muls	d2,d1
				muls	d5,d0
				sub.l	d1,d0
				divs	d3,d0					; otherd
				sub.w	d7,d0					; total distance travelled across wall
				bgt.s	.ohbugger
				moveq	#1,d0

.ohbugger:

; We now have ratio to multiply x,z and y differences
; by. Check y=0 since that's quite common.

				move.l	d4,d1
				beq.s	.dontworryhit

				divs	d0,d1
				muls	d7,d1

.dontworryhit:
				add.l	Obj_NewY_w,d1					; height at point of crossing wall.
				move.l	d1,d6
				add.l	thingheight,d6
				sub.l	StepUpVal,d6
				cmp.l	LowerFloorHeight,d6
				bge.s	.yeshit

				cmp.l	LowerRoofHeight,d1
				bgt		oknothitwall

				cmp.l	UpperRoofHeight,d1
				blt.s	.yeshit
				cmp.l	UpperFloorHeight,d6
				blt		oknothitwall

.yeshit:
				move.l	d1,wallhitheight
				tst.b	Obj_WallBounce_b
				bne.s	.calcbounce

				tst.b	exitfirst(pc)
				beq.s	.calcalong
				bne.s	.calcwherehit

.calcbounce:

; For simplicity (possibility!) the
; bounce routine will:
; Place the object at wall contact
; point
; Supply wall data to reflect the
; movement direction of the object

				move.w	d2,WallXSize_w
				move.w	d5,WallZSize_w
				move.w	d3,WallLength_w

.calcwherehit:

; add.w #20,d7
				move.w	Obj_NewX_w,d6
				sub.w	Obj_OldX_w,d6
				muls	d7,d6
				divs	d0,d6
				add.w	Obj_NewX_w,d6
				move.w	Obj_NewZ_w,d1
				sub.w	Obj_OldZ_w,d1
				muls	d7,d1
				divs	d0,d1
				add.w	Obj_NewZ_w,d1
				move.w	d6,d0
				move.w	d1,d7
				bra.s	.calcedhit

.calcalong:

; sub.w #3,d7
				move.w	d7,d6
				muls	d5,d6
				muls	d2,d7
				divs	d3,d6
				divs	d3,d7
				neg.w	d6
				add.w	Obj_NewX_w,d6					; point on wall
				add.w	Obj_NewZ_w,d7
				move.w	d6,d0
				move.w	d7,d1
				bra.s	othercheck

.calcedhit:
				move.w	Obj_NewX_w,d6
				move.w	Obj_NewZ_w,d7
				sub.w	Obj_OldX_w,d6
				sub.w	Obj_OldZ_w,d7
				move.w	(a2),d4 ; EdgeT_XPos_w
				add.w	a4,d4
				sub.w	Obj_OldX_w,d4
				muls	d4,d7;					negative if on left
				move.w	EdgeT_ZPos_w(a2),d4
				add.w	a6,d4
				sub.w	Obj_OldZ_w,d4
				muls	d4,d6
				sub.l	d6,d7
				bgt		oknothitwall

				move.w	d0,d6
				move.w	d1,d7
				move.w	Obj_NewX_w,d6
				move.w	Obj_NewZ_w,d7
				sub.w	Obj_OldX_w,d6
				sub.w	Obj_OldZ_w,d7
				move.w	(a2),d4 ; EdgeT_XPos_w
				add.w	a4,d4
				add.w	d2,d4
				sub.w	Obj_OldX_w,d4
				muls	d4,d7;					negative if on left
				move.w	EdgeT_ZPos_w(a2),d4
				add.w	a6,d4
				add.w	d5,d4
				sub.w	Obj_OldZ_w,d4
				muls	d4,d6
				sub.l	d6,d7
				blt		oknothitwall
				bra		hitthewall

othercheck:
				sub.w	(a2),d6 ; EdgeT_XPos_w
				sub.w	EdgeT_ZPos_w(a2),d7
				sub.w	a4,d6
				sub.w	a6,d7
				move.w	d2,d4
				bge.s	okplus1

				neg.w	d4
okplus1:
				move.w	d5,d3
				bge.s	okplus2

				neg.w	d3
okplus2:
				cmp.w	d4,d3
				bgt.s	UseZ

; Use the x coord!

				tst.w	d6
				bgt.s	xispos

				move.w	d2,d7
				cmp.w	#4,d7
				bgt.s	oknothitwall

				sub.w	#4,d7
				cmp.w	d7,d6
				blt.s	oknothitwall

				bra.s	hitthewall

xispos:
				move.w	d2,d7
				cmp.w	#-4,d7
				blt.s	oknothitwall
				add.w	#4,d7
				cmp.w	d7,d6
				bgt.s	oknothitwall

				bra.s	hitthewall

UseZ:
				tst.w	d7
				bgt.s	zispos

				move.w	d5,d6
				cmp.w	#4,d6
				bgt.s	oknothitwall

				sub.w	#4,d6
				cmp.w	d6,d7
				blt.s	oknothitwall

				bra.s	hitthewall

zispos:
				move.w	d5,d6
				cmp.w	#-4,d6
				blt.s	oknothitwall

				add.w	#4,d6
				cmp.w	d6,d7
				bgt.s	oknothitwall

hitthewall:
				move.w	d0,Obj_NewX_w
				move.w	d1,Obj_NewZ_w
				move.w	wallflags(pc),d0
				or.w	d0,EdgeT_Flags_w(a2)
				st		hitwall
				tst.b	exitfirst(pc)
				bne		stopandleave

oknothitwall:
				bra		checkwalls
no_more_walls:
				tst.w	Obj_ExtLen_w
				beq		NOOTHERWALLSNEEDED

				tst.w	Obj_XDiff_w
				bne.s	notstill

				tst.w	Obj_ZDiff_w
				bne.s	notstill

				move.l	Obj_ZonePtr_l,a0
				bra		mustbeinsameroom

notstill:
				move.l	a5,a0
				add.w	ZoneT_EdgeListOffset_w(a0),a0

checkotherwalls:
				move.w	(a0)+,d0
				bge		anotherwalls

				cmp.w	#-2,d0
				beq		nomoreotherwalls
				bra		checkotherwalls

anotherwalls:
				asl.w	#4,d0
				lea		(a1,d0.w),a2

*********************************
* Check if we are within exit limits
* of zone.
*********************************

; tst.b 9(a2)
; bne .thisisawall2

				moveq	#0,d1
				move.w	EdgeT_JoinZone_w(a2),d1
				blt		.thisisawall2

				move.l	Lvl_ZonePtrsPtr_l,a4
				move.l	(a4,d1.w*4),a4
				move.l	ZoneT_Floor_l(a4),d1
				sub.l	ZoneT_Roof_l(a4),d1
				cmp.l	thingheight,d1
				ble		.thisisawall1

				move.l	Obj_NewY_w,d0
				move.l	d0,d1
				add.l	thingheight,d1
				sub.l	ZoneT_Floor_l(a4),d1
				bgt.s	.chkstepup

				neg.l	d1
				cmp.l	StepDownVal,d1
				blt.s	.botinsidebot
				bra.s	.thisisawall1

.chkstepup:
				cmp.l	StepUpVal,d1
				blt.s	.botinsidebot

; We have a wall!
				bra		.thisisawall1

.botinsidebot:
				sub.l	ZoneT_Roof_l(a4),d0
				blt.s	.thisisawall1

				bra		checkotherwalls

.thisisawall1:
				move.l	ZoneT_UpperFloor_l(a4),d1
				sub.l	ZoneT_UpperRoof_l(a4),d1
				cmp.l	thingheight,d1
				ble		.thisisawall2

				move.l	Obj_NewY_w,d0
				move.l	d0,d1
				add.l	thingheight,d1
				sub.l	ZoneT_UpperFloor_l(a4),d1
				bgt.s	.chkstepup2

				neg.l	d1
				cmp.l	StepDownVal,d1
				blt.s	.botinsidebot2
				bra.s	.thisisawall2

.chkstepup2:
				cmp.l	StepUpVal,d1
				blt.s	.botinsidebot2

; We have a wall!
				bra		.thisisawall2

.botinsidebot2:
				sub.l	ZoneT_UpperRoof_l(a4),d0
				blt.s	.thisisawall2

				bra		checkotherwalls

.thisisawall2:
				move.l	#0,a4
				move.l	#0,a6
				move.b	Obj_AwayFromWall_b,d3
				blt.s	.notomatoes

				move.b	EdgeT_RotNormalX_b(a2),d2
				ext.w	d2
				move.b	EdgeT_RotNormalZ_b(a2),d4
				ext.w	d4
				tst.b	d3
				beq.s	.noshift
				asl.w	d3,d2
				asl.w	d3,d4

.noshift:
				move.w	d2,a4
				move.w	d4,a6

.notomatoes:
				move.w	EdgeT_XLen_w(a2),d2
				sub.w	a4,d2
				sub.w	a6,d2
				move.w	d2,obj_DeltaX_w
				move.w	EdgeT_ZLen_w(a2),d5
				add.w	a4,d5
				sub.w	a6,d5
				move.w	Obj_NewX_w,d0
				move.w	Obj_NewZ_w,d1
				sub.w	(a2),d0 ; EdgeT_XPos_w
				sub.w	EdgeT_ZPos_w(a2),d1
				sub.w	a4,d0
				sub.w	a6,d1
				muls	obj_DeltaX_w,d1
				muls	d5,d0
				sub.l	d1,d0
				bge		.oknothitwall

				move.l	d0,d7
				move.w	Obj_OldX_w,d1
				move.w	Obj_NewX_w,d3
				sub.w	d1,d3
				sub.w	(a2),d1 ; EdgeT_XPos_w
				sub.w	a4,d1					;e-a=d1
				move.w	EdgeT_ZPos_w(a2),d2
				add.w	a6,d2
				sub.w	Obj_OldZ_w,d2					;b-f=d2
				move.w	Obj_NewZ_w,d4
				sub.w	Obj_OldZ_w,d4
				muls	d4,d1
				muls	d3,d2
				add.l	d2,d1					; h(e-a)+g(b-f)
				muls	obj_DeltaX_w,d4
				muls	d5,d3
				sub.l	d3,d4
				beq		.oknothitwall
				bgt.s	.botpos

.botneg:
				tst.l	d1
				bgt		.oknothitwall

				cmp.l	d1,d4
				ble		.mighthit
				bra		.oknothitwall

.botpos:
				tst.l	d1
				blt		.oknothitwall

				cmp.l	d1,d4
				blt		.oknothitwall

.mighthit:
				move.w	EdgeT_Length_w(a2),d0
				add.w	Obj_ExtLen_w,d0
				divs	d0,d7					;  d
				sub.w	#3,d7
				move.w	d7,d6
				muls	d5,d6
				muls	obj_DeltaX_w,d7
				divs	d0,d6
				divs	d0,d7
				neg.w	d6
				add.w	Obj_NewX_w,d6					; point on wall
				add.w	Obj_NewZ_w,d7
				move.w	Obj_OldX_w,d0
				move.w	Obj_OldZ_w,d1
				sub.w	(a2),d0 ; EdgeT_XPos_w
				sub.w	EdgeT_ZPos_w(a2),d1
				sub.w	a4,d0
				sub.w	a6,d1
				muls	obj_DeltaX_w,d1
				muls	d5,d0
				sub.l	d1,d0
				blt		.oknothitwall

				move.w	d6,d0
				move.w	d7,d1

				bra		.hitthewall

				; Unreachable ?
				sub.w	(a2),d6 ; EdgeT_XPos_w
				sub.w	EdgeT_ZPos_w(a2),d7
				move.w	d6,d4
				bge.s	.okplus1
				neg.w	d4

.okplus1:
				move.w	d7,d3
				bge.s	.okplus2
				neg.w	d3

.okplus2:
				cmp.w	d4,d3
				bgt.s	.UseZ

; Use the x coord!
				tst.w	d6
				bgt.s	.xispos

				move.w	obj_DeltaX_w,d7
				bgt.s	.oknothitwall

				cmp.w	d7,d6
				blt.s	.oknothitwall

				bra.s	.hitthewall

.xispos:
				move.w	obj_DeltaX_w,d7
				blt.s	.oknothitwall

				cmp.w	d7,d6
				bgt.s	.oknothitwall

				bra.s	.hitthewall

.UseZ:
				tst.w	d7
				bgt.s	.zispos

				move.w	d5,d6
				bgt.s	.oknothitwall

				cmp.w	d6,d7
				blt.s	.oknothitwall

				bra.s	.hitthewall

.zispos:
				move.w	d5,d6
				blt.s	.oknothitwall

				cmp.w	d6,d7
				bgt.s	.oknothitwall

.hitthewall:
				move.w	d0,Obj_NewX_w
				move.w	d1,Obj_NewZ_w
				move.w	wallflags(pc),d0
				or.w	d0,EdgeT_Flags_w(a2)
				st		hitwall
				tst.b	exitfirst(pc)
				bne		stopandleave

.oknothitwall:
				bra		checkotherwalls

nomoreotherwalls:
NOOTHERWALLSNEEDED:

*****************************************************
* FIND ROOM WE'RE STANDING IN ***********************
*****************************************************

				move.l	a5,a0
				adda.w	ZoneT_EdgeListOffset_w(a5),a0
				move.l	Lvl_ZoneEdgePtr_l,a1

CheckMoreFloorLines:
				move.w	(a0)+,d0				; Either a floor line or -1
				blt		NoMoreFloorLines

				asl.w	#4,d0
				lea		(a1,d0.w),a2

				tst.w	EdgeT_JoinZone_w(a2)
				blt.s	CheckMoreFloorLines

				;sf		CrossIntoTop

				moveq	#0,d1
				move.w	EdgeT_JoinZone_w(a2),d1
				move.l	Lvl_ZonePtrsPtr_l,a4
				move.l	(a4,d1.w*4),a4
				move.l	ZoneT_Roof_l(a4),LowerRoofHeight

okthebottom:
				move.w	Obj_NewX_w,d0
				move.w	Obj_NewZ_w,d1
				sub.w	(a2),d0	; EdgeT_XPos_w				;a
				sub.w	EdgeT_ZPos_w(a2),d1				;b
				muls	EdgeT_XLen_w(a2),d1
				muls	EdgeT_ZLen_w(a2),d0
				moveq	#0,d3
				move.w	EdgeT_JoinZone_w(a2),d3
				move.l	Lvl_ZonePtrsPtr_l,a3
				move.l	(a3,d3.w*4),a3
				sub.l	d1,d0
				bge		StillSameSide

* Player is now on the left side of this line.
* Where was he before?

OnRightsideofline:
* Player is now on the right side of the line.
* Where was he last time?

checkifcrossed:

*Player used to be on other side of this line.
*Need to check if he crossed it.

				move.l	d0,billy
				move.w	Obj_NewX_w,d6
				move.w	Obj_NewZ_w,d7
				sub.w	Obj_OldX_w,d6
				sub.w	Obj_OldZ_w,d7
				move.w	(a2),d4 ; EdgeT_XPos_w
				sub.w	Obj_OldX_w,d4
				muls	d4,d7;					negative if on left
				move.w	EdgeT_ZPos_w(a2),d4
				sub.w	Obj_OldZ_w,d4
				muls	d4,d6
				sub.l	d6,d7
				bgt		StillSameSide

				move.w	d0,d6
				move.w	d1,d7
				move.w	Obj_NewX_w,d6
				move.w	Obj_NewZ_w,d7
				sub.w	Obj_OldX_w,d6
				sub.w	Obj_OldZ_w,d7
				move.w	(a2),d4 ; EdgeT_XPos_w
				add.w	EdgeT_XLen_w(a2),d4
				sub.w	Obj_OldX_w,d4
				muls	d4,d7;					negative if on left
				move.w	EdgeT_ZPos_w(a2),d4
				add.w	EdgeT_ZLen_w(a2),d4
				sub.w	Obj_OldZ_w,d4
				muls	d4,d6
				sub.l	d6,d7
				blt		StillSameSide

; Find height at crossing point:

				move.l	billy,d7
				divs	EdgeT_Length_w(a2),d7
				move.w	Obj_OldX_w,d0
				move.w	Obj_OldZ_w,d1
				sub.w	(a2),d0 ; EdgeT_XPos_w
				sub.w	EdgeT_ZPos_w(a2),d1
				muls	EdgeT_XLen_w(a2),d1
				muls	EdgeT_ZLen_w(a2),d0
				sub.l	d1,d0
				divs	EdgeT_Length_w(a2),d0
				sub.w	d7,d0
				bgt.s	.ohbugger

				moveq	#1,d0

.ohbugger:
				move.l	Obj_NewY_w,d4
				sub.l	Obj_OldY_w,d4
				divs	d0,d4
				muls	d7,d4
				add.l	Obj_NewY_w,d4
				cmp.l	LowerRoofHeight,d4
				slt		StoodInTop
				move.l	a3,a5
				move.l	obj_RoomPathPtr_l,a0
				move.w	(a3),(a0)+
				move.l	a0,obj_RoomPathPtr_l
				move.l	a3,a0
				move.l	a5,Obj_ZonePtr_l
				move.w	obj_QuitLimit_w,d0
				sub.w	#1,d0
				beq.s	ERRORINMOVEMENT

				move.w	d0,obj_QuitLimit_w
				bra		gobackanddoitallagain

; bra.s donefloorline

StillSameSide:
donefloorline:
				bra		CheckMoreFloorLines

NoMoreFloorLines:
				move.l	a5,a0
				move.l	a5,Obj_ZonePtr_l

mustbeinsameroom:
stopandleave:
				move.l	obj_RoomPathPtr_l,a0
				move.w	#-1,(a0)+

				rts

ERRORINMOVEMENT:
				move.w	Obj_OldX_w,Obj_NewX_w
				move.w	Obj_OldZ_w,Obj_NewZ_w
				move.l	Obj_OldY_w,Obj_NewY_w
				move.l	obj_ZoneBackupPtr_l,Obj_ZonePtr_l
				st		hitwall
				rts

				align 4

;tstxval:		dc.l	0
; TODO - these are not really long values but have some holdover initialisation from long in the level data.
Obj_OldX_w:			dc.l	0
Obj_OldZ_w:			dc.l	0
Obj_OldY_w:			dc.l	0
Obj_NewX_w:			dc.l	0	; This is really a union because level data has 32-bit values, but on;ly the msw is used
Obj_NewZ_w:			dc.l	0	; also here
Obj_NewY_w:			dc.l	0	; and here

Obj_XDiff_w:			dc.l	0
Obj_ZDiff_w:			dc.l	0
Obj_ZonePtr_l:			dc.l	0
obj_ZoneBackupPtr_l:	dc.l	0

obj_DeltaX_w:			dc.w	0
speed:			dc.w	0
wallflags:		dc.w	0
distaway:		dc.w	0

thingheight:	dc.l	0
StepUpVal:		dc.l	0
StepDownVal:	dc.l	0
wallhitheight:	dc.l	0
;seclot:			dc.b	0

;WALLXLEN:		dc.w	0	; write only?
;WALLZLEN:		dc.w	0	; write only?
;onwallx:		dc.w	0
;onwallz:		dc.w	0
;slidex:			dc.w	0
;slidez:			dc.w	0

LowerFloorHeight:	dc.l	0
LowerRoofHeight:	dc.l	0
UpperFloorHeight:	dc.l	0
UpperRoofHeight:	dc.l	0
billy:				dc.l	0,0

;CrossIntoTop:	dc.b	0	; write only ?
StoodInTop:		dc.b	0
hitwall:		dc.b	0
exitfirst:		dc.b	0


				even

HeadTowards:
				move.w	Obj_NewX_w,d1
				sub.w	Obj_OldX_w,d1
				move.w	d1,Obj_XDiff_w
				move.w	Obj_NewZ_w,d2
				sub.w	Obj_OldZ_w,d2
				move.w	d2,Obj_ZDiff_w
				muls	d1,d1
				muls	d2,d2
				move.w	#0,d0
				move.w	d0,distaway
				add.l	d1,d2
				beq		nochange

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
				move.w	d0,distaway

; d0=perpdist

				cmp.w	Range,d0
				sle		GotThere
				bgt.s	faraway

				move.w	Obj_XDiff_w,d1
				move.w	Obj_ZDiff_w,d2
				muls	Range,d1
				muls	Range,d2
				divs	d0,d1
				divs	d0,d2
				neg.w	d1
				neg.w	d2
				add.w	d1,Obj_NewX_w
				add.w	d2,Obj_NewZ_w
				bra		nochange

faraway:
				move.w	speed,d3
				add.w	Range,d3
				cmp.w	d0,d3
				blt.s	.notoofast

				move.w	d0,d3
				st		GotThere

.notoofast:
				sub.w	Range,d3
				move.w	Obj_XDiff_w,d1
				muls	d3,d1
				divs	d0,d1
				move.w	Obj_ZDiff_w,d2
				muls	d3,d2
				divs	d0,d2
				add.w	Obj_OldX_w,d1
				move.w	d1,Obj_NewX_w
				add.w	Obj_OldZ_w,d2
				move.w	d2,Obj_NewZ_w

nochange:
				rts


CalcDist:
				move.w	Obj_NewX_w,d1
				sub.w	Obj_OldX_w,d1
				move.w	d1,Obj_XDiff_w
				move.w	Obj_NewZ_w,d2
				sub.w	Obj_OldZ_w,d2
				move.w	d2,Obj_ZDiff_w
				muls	d1,d1
				muls	d2,d2
				move.w	#0,d0
				move.w	d0,distaway
				add.l	d1,d2
				beq		.nochange

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
				move.w	d0,distaway

.nochange:
				rts


counterer:		dc.w	0
CosRet:			dc.w	0
SinRet:			dc.w	0

HeadTowardsAng:
				move.w	Obj_NewX_w,d1
				sub.w	Obj_OldX_w,d1
				move.w	d1,Obj_XDiff_w
				move.w	Obj_NewZ_w,d2
				sub.w	Obj_OldZ_w,d2
				move.w	d2,Obj_ZDiff_w
				muls	d1,d1
				muls	d2,d2
				move.w	#0,d0
				add.l	d1,d2
				seq		GotThere
				beq		.nochange

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
; d0=perpdist
				cmp.w	Range,d0
				sle		GotThere
				bgt		.faraway

				move.w	Obj_OldX_w,Obj_NewX_w
				move.w	Obj_OldZ_w,Obj_NewZ_w
				bra		.nochange

				; Unreachable ?
				move.w	Obj_XDiff_w,d1
				move.w	Obj_ZDiff_w,d2
				muls	Range,d1
				muls	Range,d2
				addq	#3,d0
				divs	d0,d1
				divs	d0,d2
				subq	#3,d0
				neg.w	d1
				neg.w	d2
				add.w	d1,Obj_NewX_w
				add.w	d2,Obj_NewZ_w
				tst.b	canshove
				beq		.nochange
				move.w	PLR1_opushx(pc),d1
				add.w	PLR2_opushx(pc),d1
				sub.w	d1,Obj_NewX_w
				move.w	PLR1_opushz(pc),d1
				add.w	PLR2_opushz(pc),d1
				sub.w	d1,Obj_NewZ_w
				move.w	Obj_XDiff_w,d1
				move.w	Obj_ZDiff_w,d2
				move.w	Range,d3
				sub.w	d0,d3
				muls	d3,d1
				muls	d3,d2
				divs	d0,d1
				divs	d0,d2
				move.w	d1,shovex
				move.w	d2,shovez
				bra		.nochange

.faraway:
				move.w	speed,d3
				add.w	Range,d3
				cmp.w	d0,d3
				blt.s	.notoofast
				move.w	d0,d3
				st		GotThere

.notoofast:
				sub.w	Range,d3
				move.w	Obj_XDiff_w,d1
				muls	d3,d1
				divs	d0,d1
				move.w	Obj_ZDiff_w,d2
				muls	d3,d2
				divs	d0,d2
				add.w	Obj_OldX_w,d1
				move.w	d1,Obj_NewX_w
				add.w	Obj_OldZ_w,d2
				move.w	d2,Obj_NewZ_w

.nochange:
				tst.w	d0
				beq.s	nocossin

				add.w	#1,d0
				move.w	Obj_XDiff_w,d1
				swap	d1
				clr.w	d1
				asr.l	#1,d1
				divs	d0,d1
				move.w	d1,SinRet
				move.w	Obj_ZDiff_w,d1
				swap	d1
				clr.w	d1
				asr.l	#1,d1
				divs	d0,d1
				move.w	d1,CosRet
				move.w	SinRet,d0
				move.w	#0,d2
				move.l	#SinCosTable_vw,a2
				lea		COSINE_OFS(a2),a3
				move.w	#3,d5
				move.w	#COSINE_OFS,d6

findanglop:
				move.w	(a2,d2.w*2),d3
				move.w	(a3,d2.w*2),d4
				muls	d0,d4
				muls	d1,d3
				sub.l	d3,d4
				blt.s	subang
				add.w	d6,d2
				add.w	d6,d2

subang:
				sub.w	d6,d2
				and.w	#4095,d2
				asr.w	#1,d6
				dbra	d5,findanglop
				add.w	d2,d2
				move.w	d2,AngRet

nocossin:
				rts

				align 4
AngRet:			dc.w	0
Range:			dc.w	0
GotThere:		dc.w	0
shovex:			dc.w	0
shovez:			dc.w	0
canshove:		dc.w	0
PLR2_pushx:		dc.l	0
PLR2_pushz:		dc.l	0
PLR2_opushx:	dc.l	0
PLR2_opushz:	dc.l	0
PLR1_pushx:		dc.l	0
PLR1_pushz:		dc.l	0
PLR1_opushx:	dc.l	0
PLR1_opushz:	dc.l	0

CheckHit:
				move.w	Obj_NewX_w,d0
				sub.w	Obj_OldX_w,d0
				move.w	Obj_NewZ_w,d1
				sub.w	Obj_OldZ_w,d1
				muls	d1,d1
				muls	d0,d0
				add.l	d0,d1
				cmp.l	d2,d1
				slt		hitwall
				rts

ONLYSEE:		dc.w	0

GetNextCPt:
				sf		ONLYSEE
				cmp.w	d0,d1
				beq.s	noneedforhassle

				muls.w	#100,d0
				ext.l	d1
				add.l	d1,d0
				move.l	a0,-(a7)
				move.l	Lvl_WalkLinksPtr_l,a0
				tst.b	AI_FlyABit_w
				beq.s	.walklink

				move.l	Lvl_FlyLinksPtr_l,a0

.walklink:
				move.b	(a0,d0.w),d0
				move.b	d0,d1
				and.b	#$7f,d0
				and.b	#$80,d1
				sne		ONLYSEE
				ext.w	d0
				move.l	(a7)+,a0

noneedforhassle:
				rts

				align 4
Obj_FromZonePtr_l:	dc.l	0
Obj_ToZonePtr_l:	dc.l	0
CanSee:			dc.w	0
Facedir:		dc.w	0
				even

CanItBeSeenAng:
				SAVEREGS

				move.w	Facedir,d0
				move.l	#SinCosTable_vw,a0
				add.w	d0,a0
				move.w	(a0),d0 ; SINE_OFS
				move.w	COSINE_OFS(a0),d1
				move.w	Obj_TargetX_w,d2
				sub.w	Obj_ViewerX_w,d2
				move.w	Obj_TargetZ_w,d3
				sub.w	Obj_ViewerZ_w,d3
				muls	d1,d2
				muls	d0,d3
				sub.l	d3,d2
				bgt.s	ItMightBeSeen

				sf		CanSee

				GETREGS
				rts

ItMightBeSeen:
				move.l	Obj_ToZonePtr_l,a0
				move.w	(a0),d0
				move.l	Obj_FromZonePtr_l,a0
				adda.w	#ZoneT_PotVisibleZoneList_vw,a0
				bra.s	InList

				align 4
Obj_ViewerX_w:				dc.w	0
Obj_ViewerZ_w:				dc.w	0
Obj_TargetX_w:				dc.w	0
Obj_TargetZ_w:				dc.w	0
Obj_ViewerInUpperZone_b:	dc.b	0
Obj_TargetInUpperZone_b:	dc.b	0
Obj_ViewerY_w:				dc.w	0
Obj_TargetY_w:				dc.w	0

				even

insameroom:
				st		CanSee
				move.b	Obj_ViewerInUpperZone_b,d0
				move.b	Obj_TargetInUpperZone_b,d1
				eor.b	d0,d1
				bne		outlist

				GETREGS

				rts

CanItBeSeen:
				SAVEREGS

				move.l	Obj_ToZonePtr_l,a1
				move.w	(a1),d0
				move.l	Obj_FromZonePtr_l,a0
				cmp.l	a0,a1
				beq.s	insameroom

				adda.w	#ZoneT_PotVisibleZoneList_vw,a0

InList:
				move.w	(a0),d1 ; PVST_Zone_w
				tst.w	d1 ; redundant?
				blt		outlist

				move.l	Lvl_ZoneGraphAddsPtr_l,a1
				move.l	(a1,d1.w*8),a1
				add.l	Lvl_GraphicsPtr_l,a1
				adda.w	#PVST_SizeOf_l,a0
				cmp.w	(a1),d0
				beq		isinlist

				bra.s	InList

isinlist:
; We have found the dest room in the
; list of rooms visible from the
; source room.

; TODO - can we reuse edge PVS data here?

; Do line of sight!

				st		CanSee
				move.l	Lvl_PointsPtr_l,a2
				move.w	Obj_TargetX_w,d1
				move.w	Obj_TargetZ_w,d2
				sub.w	Obj_ViewerX_w,d1
				sub.w	Obj_ViewerZ_w,d2
				moveq	#0,d3
				move.w	-6(a0),d3
				blt		nomorerclips

				move.l	Lvl_ClipsPtr_l,a1
				lea		(a1,d3.l*2),a1
				move.l	a1,clipstocheck

checklcliploop:
				tst.w	(a1)
				blt		nomorelclips

				move.w	(a1),d0
				blt.s	noleftone

				move.l	(a2,d0.w*4),d3
				move.w	d3,d4
				sub.w	Obj_ViewerZ_w,d4
				swap	d3
				sub.w	Obj_ViewerX_w,d3
				muls	d2,d3
				muls	d1,d4
				sub.l	d3,d4
				ble		outlist

noleftone:
				addq	#2,a1
				bra		checklcliploop

nomorelclips:
				addq	#2,a1

checkrcliploop:
				tst.w	(a1)
				blt		nomorerclips

				move.w	(a1),d0
				blt.s	norightone
				move.l	(a2,d0.w*4),d3
				move.w	d3,d4
				sub.w	Obj_ViewerZ_w,d4
				swap	d3
				sub.w	Obj_ViewerX_w,d3
				muls	d2,d3
				muls	d1,d4
				sub.l	d3,d4
				bge		outlist

norightone:
				addq	#2,a1
				bra		checkrcliploop

nomorerclips:
; No clipping points in the way; got to do the
; vertical working out now.

				move.w	Obj_TargetX_w,d0
				move.w	Obj_TargetZ_w,d1
				sub.w	Obj_ViewerX_w,d0
				sub.w	Obj_ViewerZ_w,d1
				move.l	Obj_FromZonePtr_l,a5
				move.l	Lvl_ZoneEdgePtr_l,a1
				move.b	Obj_ViewerInUpperZone_b,d2
				move.w	Obj_TargetY_w,d7
				sub.w	Obj_ViewerY_w,d7

GoThroughZones:
				move.l	a5,a0
				adda.w	ZoneT_EdgeListOffset_w(a0),a0

; Deduplication opportunity.

FindWayOut:
				move.w	(a0)+,d5
				blt		outlist
				asl.w	#4,d5
				lea		(a1,d5.w),a2
				move.w	(a2),d3 ; EdgeT_XPos_w
				move.w	EdgeT_ZPos_w(a2),d4
				sub.w	Obj_ViewerX_w,d3
				sub.w	Obj_ViewerZ_w,d4
				move.w	d3,d5
				move.w	d4,d6
				muls	d1,d3
				muls	d0,d4
				sub.l	d3,d4
				ble		FindWayOut

				add.w	EdgeT_XLen_w(a2),d5
				add.w	EdgeT_ZLen_w(a2),d6
				muls	d0,d6
				muls	d1,d5
				sub.l	d5,d6
				bge		FindWayOut

				tst.w	EdgeT_JoinZone_w(a2)
				blt		outlist

; Here is the exit from the room. Calculate the height at which
; we meet it.

				move.w	Obj_TargetX_w,d3
				move.w	Obj_TargetZ_w,d4
				sub.w	(a2),d3 ; EdgeT_XPos_w
				sub.w	EdgeT_ZPos_w(a2),d4
				muls	EdgeT_XLen_w(a2),d4
				muls	EdgeT_ZLen_w(a2),d3
				sub.l	d3,d4					; positive
				move.w	Obj_ViewerX_w,d5
				move.w	Obj_ViewerZ_w,d6
				sub.w	(a2),d5 ; EdgeT_XPos_w
				sub.w	EdgeT_ZPos_w(a2),d6
				muls	EdgeT_XLen_w(a2),d6
				muls	EdgeT_ZLen_w(a2),d5
				sub.l	d6,d5					; positive
				divs	EdgeT_Length_w(a2),d4
				divs	EdgeT_Length_w(a2),d5
				add.w	d5,d4
				beq.s	sameheight
				muls	d7,d5
				divs	d4,d5

sameheight:
				add.w	Obj_ViewerY_w,d5				; height at which we cross wall
				ext.l	d5
				asl.l	#7,d5
				tst.b	d2
				beq.s	comparewithbottom

				cmp.l	ZoneT_UpperRoof_l(a5),d5
				blt		outlist

				cmp.l	ZoneT_UpperFloor_l(a5),d5
				bgt		outlist
				bra.s	madeit

comparewithbottom:
				cmp.l	ZoneT_Roof_l(a5),d5
				blt		outlist

				cmp.l	ZoneT_Floor_l(a5),d5
				bgt		outlist

madeit:
				st		donessomething
				moveq	#0,d3
				move.w	EdgeT_JoinZone_w(a2),d3
				move.l	Lvl_ZonePtrsPtr_l,a3
				move.l	(a3,d3.w*4),a5
				sf		d2
				cmp.l	ZoneT_Floor_l(a5),d5
				bgt		outlist

				cmp.l	ZoneT_Roof_l(a5),d5
				bgt.s	GotIn

				st		d2
				cmp.l	ZoneT_UpperFloor_l(a5),d5
				bgt		outlist

				cmp.l	ZoneT_UpperRoof_l(a5),d5
				blt		outlist

GotIn:
				cmp.l	Obj_ToZonePtr_l,a5
				bne		GoThroughZones

				move.b	Obj_TargetInUpperZone_b,d3
				eor.b	d2,d3
				bne		outlist

				GETREGS

				rts

clipstocheck:	dc.l	0
donessomething:	dc.w	0

outlist:
				sf		CanSee

				GETREGS

				rts

FindCollisionPt:
				SAVEREGS

				move.w	Obj_TargetX_w,d0
				move.w	Obj_TargetZ_w,d1
				sub.w	Obj_ViewerX_w,d0
				sub.w	Obj_ViewerZ_w,d1
				move.l	Obj_FromZonePtr_l,a5
				move.l	Lvl_ZoneEdgePtr_l,a1
				move.b	Obj_ViewerInUpperZone_b,d2
				move.w	Obj_TargetY_w,d7
				sub.w	Obj_ViewerY_w,d7

.GoThroughZones:
				move.l	a5,a0
				adda.w	ZoneT_EdgeListOffset_w(a0),a0

.FindWayOut:
				move.w	(a0)+,d5
				blt		outlist
				asl.w	#4,d5
				lea		(a1,d5.w),a2
				move.w	(a2),d3 ; EdgeT_XPos_w
				move.w	EdgeT_ZPos_w(a2),d4
				sub.w	Obj_ViewerX_w,d3
				sub.w	Obj_ViewerZ_w,d4
				move.w	d3,d5
				move.w	d4,d6
				muls	d1,d3
				muls	d0,d4
				sub.l	d3,d4
				ble		.FindWayOut

				add.w	EdgeT_XLen_w(a2),d5
				add.w	EdgeT_ZLen_w(a2),d6
				muls	d0,d6
				muls	d1,d5
				sub.l	d5,d6
				bge		.FindWayOut

; Here is the exit from the room. Calculate the height at which
; we meet it.

				move.w	Obj_TargetX_w,d3
				move.w	Obj_TargetZ_w,d4
				sub.w	(a2),d3 ; EdgeT_XPos_w
				sub.w	EdgeT_ZPos_w(a2),d4
				muls	EdgeT_XLen_w(a2),d4
				muls	EdgeT_ZLen_w(a2),d3
				sub.l	d3,d4					; positive
				move.w	Obj_ViewerX_w,d5
				move.w	Obj_ViewerZ_w,d6
				sub.w	(a2),d5 ; EdgeT_XPos_w
				sub.w	EdgeT_ZPos_w(a2),d6
				muls	EdgeT_XLen_w(a2),d6
				muls	EdgeT_ZLen_w(a2),d5
				sub.l	d6,d5					; positive
				divs	EdgeT_Length_w(a2),d4
				divs	EdgeT_Length_w(a2),d5
				move.w	d5,d6 ; needed ?
				add.w	d5,d4
				beq.s	.sameheight
				muls	d7,d5
				divs	d4,d5

.sameheight:
				add.w	Obj_ViewerY_w,d5				; height at which we cross wall
				ext.l	d5
				asl.l	#7,d5
				moveq	#0,d3
				move.w	EdgeT_JoinZone_w(a2),d3
				blt		foundpt

				move.l	Lvl_ZonePtrsPtr_l,a3
				move.l	(a3,d3.w*4),a5
				sf		d2
				cmp.l	ZoneT_Floor_l(a5),d5
				bgt		foundpt

				cmp.l	ZoneT_Roof_l(a5),d5
				bgt.s	.GotIn

				st		d2
				cmp.l	ZoneT_UpperFloor_l(a5),d5
				bgt		foundpt

				cmp.l	ZoneT_UpperRoof_l(a5),d5
				blt		foundpt

.GotIn:
				bra		.GoThroughZones

				; Unreachable ?
				;tst.w	d4
				;beq.s	foundpt
				;muls	d6,d0
				;divs	d4,d0
				;muls	d6,d1
				;divs	d4,d1
				;add.w	Obj_ViewerX_w,d0
				;add.w	Obj_ViewerZ_w,d1
				;move.w	d0,Obj_TargetX_w
				;move.w	d1,Obj_TargetZ_w
				;move.l	d5,Obj_TargetY_w ; TODO is this a bug?

foundpt:
				GETREGS

				rts

GetRand:
				move.w	Rand1,d0
				rol.w	#3,d0
				add.w	#$2343,d0
				move.w	d0,Rand1
				rts

Rand1:			dc.w	234

GoInDirection:
				move.l	#SinCosTable_vw,a0
				lea		(a0,d0.w),a0
				move.w	(a0),d1
				move.w	COSINE_OFS(a0),d2
				muls	speed,d1
				add.l	d1,d1
				muls	speed,d2
				add.l	d2,d2
				swap	d1
				swap	d2
				add.w	Obj_OldX_w,d1
				add.w	Obj_OldZ_w,d2
				move.w	d1,Obj_NewX_w
				move.w	d2,Obj_NewZ_w
				rts

Obj_CollideFlags_l:	dc.l	0

Obj_DoCollision:
				move.l	Lvl_ObjectDataPtr_l,a0
				move.w	CollId,d0
				asl.w	#6,d0
				move.w	ObjT_ZoneID_w(a0,d0.w),.tmp_zone_id_w
				move.b	ObjT_TypeID_b(a0,d0.w),d0
				ext.w	d0

				PREV_OBJ	a0

				move.l	Lvl_ObjectPointsPtr_l,a1
				move.l	Obj_CollideFlags_l,d7
				move.b	StoodInTop,d6
				move.l	Obj_NewY_w,d4
				move.l	d4,d5
				add.l	thingheight,d5
				asr.l	#7,d4
				asr.l	#7,d5
				sf		hitwall

.check_collide:
				NEXT_OBJ	a0
				move.w	(a0),d0
				blt		.checked_all_collide

				cmp.w	CollId,d0
				beq.s	.check_collide

				tst.w	ObjT_ZoneID_w(a0)
				blt.s	.check_collide

				move.w	.tmp_zone_id_w,d1
				cmp.w	ObjT_ZoneID_w(a0),d1
				bne.s	.check_collide

				tst.b	EntT_HitPoints_b(a0)
				beq.s	.check_collide

				move.b	ShotT_InUpperZone_b(a0),d1
				eor.b	d6,d1
				bne		.check_collide

				moveq	#0,d3
				move.b	ObjT_TypeID_b(a0),d3
				blt		.check_collide
				beq		.ycol

				cmp.b	#1,d3
				bne		.check_collide

				move.l	GLF_DatabasePtr_l,a4
				add.l	#GLFT_ObjectDefs,a4
				moveq	#0,d1
				move.b	EntT_Type_b(a0),d1
				muls	#ODefT_SizeOf_l,d1
				cmp.w	#2,ODefT_Behaviour_w(a4,d1.w)
				blt		.check_collide
				bgt		.ycol

				tst.b	EntT_HitPoints_b(a0)
				ble		.check_collide

.ycol:

; btst d3,d7
; beq .check_collide

				move.w	ObjT_ZPos_l(a0),d1
				sub.w	2(a2,d3.w*8),d1
				cmp.w	d1,d5
				blt		.check_collide

				add.w	4(a2,d3.w*8),d1
				cmp.w	d1,d4
				bgt		.check_collide

				move.w	(a1,d0.w*8),d1
				move.w	4(a1,d0.w*8),d2
				sub.w	Obj_NewX_w,d1
				bge.s	.xnoneg

				neg.w	d1
.xnoneg:
				sub.w	Obj_NewZ_w,d2
				bge.s	.znoneg

				neg.w	d2
.znoneg:
				cmp.w	d1,d2
				ble.s	.checkx
				sub.w	#80,d2
				cmp.w	#80,d2
				bgt		.check_collide
				st		hitwall
				bra		.checked_all_collide
.checkx:
				sub.w	#80,d1
				cmp.w	#80,d1
				bgt		.check_collide

				move.w	(a1,d0.w*8),d1
				move.w	4(a1,d0.w*8),d2
				move.w	d1,d6
				move.w	d2,d7
				sub.w	Obj_NewX_w,d6
				sub.w	Obj_NewZ_w,d7
				muls	d6,d6
				muls	d7,d7
				add.l	d6,d7
				sub.w	Obj_OldX_w,d1
				sub.w	Obj_OldZ_w,d2
				muls	d1,d1
				muls	d2,d2
				add.l	d1,d2
				cmp.l	d2,d7
				bgt		.check_collide

				st		hitwall
;				bra		.checked_all_collide

; bra .check_collide

.checked_all_collide:
				rts
.tmp_zone_id_w:
				dc.w	0

FromZone:		dc.w	0
OKTEL:			dc.w	0
floortemp:		dc.l	0

CheckTeleport:
				sf		OKTEL
				move.w	FromZone,d0
				move.l	Lvl_ZonePtrsPtr_l,a2
				move.l	(a2,d0.w*4),a2
				tst.w	ZoneT_TelZone_w(a2)
				bge.s	ITSATEL
				rts

ITSATEL:
				move.l	ZoneT_Floor_l(a2),floortemp
				move.w	ZoneT_TelZone_w(a2),d0
				move.l	Lvl_ZonePtrsPtr_l,a3
				move.l	(a3,d0.w*4),a3
				move.l	ZoneT_Floor_l(a3),d0
				sub.l	floortemp,d0
				move.l	d0,floortemp
				add.l	d0,Obj_NewY_w
				move.w	ZoneT_TelX_w(a2),Obj_NewX_w
				move.w	ZoneT_TelZ_w(a2),Obj_NewZ_w
				move.l	#%1111111111111111111,Obj_CollideFlags_l
				movem.l	a0/a1/a2,-(a7)
				bsr		Obj_DoCollision
				movem.l	(a7)+,a0/a1/a2
				move.l	floortemp,d0
				sub.l	d0,Obj_NewY_w
				tst.b	hitwall
				seq		OKTEL
				beq.s	.teleport

				rts

.teleport:
				move.w	ZoneT_TelZone_w(a2),d0
				move.l	Lvl_ZonePtrsPtr_l,a2
				move.l	(a2,d0.w*4),a2
				move.l	a2,Obj_ZonePtr_l

				rts

FindCloseRoom:
; d0 is distance.

				move.w	ObjT_ZPos_l(a0),d1
				ext.l	d1
				asl.l	#7,d1
				move.l	d1,Obj_OldY_w
				move.l	d1,Obj_NewY_w
				move.w	(a0),d1
				move.l	Lvl_ObjectPointsPtr_l,a1
				lea		(a1,d1.w*8),a1
				move.w	(a1),Obj_OldX_w
				move.w	ObjT_ZPos_l(a1),Obj_OldZ_w
				move.w	ObjT_ZoneID_w(a0),d2
				move.l	Lvl_ZonePtrsPtr_l,a5
				move.l	(a5,d2.w*4),d2
				move.l	d2,Obj_ZonePtr_l
				move.w	THISPLRxoff,Obj_NewX_w
				move.w	THISPLRzoff,Obj_NewZ_w
				move.w	d0,speed
				movem.l	a0/a1,-(a7)
				jsr		HeadTowards

				movem.l	(a7)+,a0/a1
				move.w	Obj_NewX_w,d0
				sub.w	Obj_OldX_w,d0
				move.w	Obj_OldZ_w,d1
				sub.w	Obj_NewZ_w,d1
				move.w	d1,xd
				move.w	d0,zd
				move.l	#100000,StepUpVal
				move.l	#100000,StepDownVal
				move.w	#0,thingheight
				st		exitfirst
				add.w	Obj_OldX_w,d1
				add.w	Obj_OldZ_w,d0
				move.w	d1,Obj_NewX_w
				move.w	d0,Obj_NewZ_w

				SAVEREGS

				sf		Obj_WallBounce_b
				jsr		MoveObject

				GETREGS

				move.l	#Obj_RoomPath_vw,a2
				move.l	#possclose,a3
				move.w	ObjT_ZoneID_w(a0),(a3)+

putinmore:
				move.w	(a2)+,(a3)+
				bge.s	putinmore

				subq	#2,a3
				move.w	Obj_OldX_w,d0
				sub.w	xd,d0
				move.w	Obj_OldZ_w,d1
				sub.w	zd,d1
				move.w	d0,Obj_NewX_w
				move.w	d1,Obj_NewZ_w

				SAVEREGS

				sf		Obj_WallBounce_b
				jsr		MoveObject

				GETREGS

				move.l	#Obj_RoomPath_vw,a2

putinmore2:
				move.w	(a2)+,d0 ; why are we going via d0 here?
				move.w	d0,(a3)+
				tst.w	d0
				bge.s	putinmore2

; ok a3 points at list of rooms passed through.
				move.w	#-1,(a3)+
				move.w	ObjT_ZoneID_w(a0),d7
				move.l	Zone_EndOfListPtr_l,a3

FINDCLOSELOOP:
				move.l	#possclose,a2
				move.w	-(a3),d0
				blt		foundclose

findinner:
				move.w	(a2)+,d1
				blt.s	outin

				cmp.w	d0,d1
				bne.s	findinner

				move.w	d0,d7

outin:
				bra.s	FINDCLOSELOOP

foundclose:
				move.w	d7,ObjT_ZoneID_w(a0)
				rts

xd:				dc.w	0
zd:				dc.w	0

possclose:
				ds.w	100
