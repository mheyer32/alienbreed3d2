ROBFRAME: dc.w 0

ItsARobot:

*******************************
; cmp.b #4,numlives(a0)
; blt.s .oklives
; move.b #4,numlives(a0)
;.oklives
*******************************

 tst.b NASTY
 bne .yesnas
 move.w #-1,12(a0)
 rts
.yesnas:

 move.w Facing(a0),d0
 sub.w #2048,d0
 and.w #8190,d0
 move.w d0,Facing(a0)

 move.w #100,d0
 jsr FindCloseRoom
 clr.b exitfirst

 sub.b #1,worry(a0)

 move.w #160,extlen
 move.b #2,awayfromwall

 move.l #20*256,StepUpVal
 move.l #160*128,thingheight
 move.l #20*256,StepDownVal

 move.w 12(a0),d2
 bge.s .stillalive
.notthisone:
 rts
.stillalive:

 tst.b numlives(a0)
 bgt.s .notdying

 move.b #0,numlives(a0)

.onfloordead:
 move.b #-1,16(a0)
 rts

.notdying: 

;
; 
; movem.l d0-d7/a0-a6,-(a7)
;
; move.w (a0),d0
; move.l #ObjRotated,a1
; move.l (a1,d0.w*8),Noisex
; move.w #400,Noisevol
; move.w #7,Samplenum
; move.b #1,chanpick
; move.b 1(a0),IDNUM
; clr.b notifplaying
; jsr MakeSomeNoise
; movem.l (a7)+,d0-d7/a0-a6
;
;.nosound:

 move.w #10,maxspd(a0)

 move.w ROBFRAME,d0
 add.w TempFrames,d0
 cmp.w #43,d0
 blt.s .noresanim
 moveq #0,d0
.noresanim:
 move.w d0,ROBFRAME
 asr.w #1,d0
 move.w d0,10(a0)

 move.w #70,nasheight
 
 tst.b 17(a0)
 beq.s .cantseeplayer
  
 tst.w ThirdTimer(a0)
 ble ROBAttack_Player
 move.w TempFrames,d0
 sub.w d0,ThirdTimer(a0)
 bge .waitandsee
 move.w #0,ThirdTimer(a0)
 bra .waitandsee
 
.cantseeplayer 
 
 jsr GetRand
 lsr.w #4,d0
 and.w #63,d0
 add.w #20,d0
 move.w d0,ThirdTimer(a0)

.waitandsee:
 
 move.w #30,FourthTimer(a0)
 
 move.l ZoneAdds,a5
 move.l (a5,d2.w*4),d0
 add.l LEVELDATA,d0
 move.l d0,objroom

 move.w TempFrames,d0
 sub.w d0,ObjTimer(a0)
 bgt.s .nonewdir

 tst.b 17(a0)
 beq.s .keepwandering

 bra ROBAttack_Player
 
.keepwandering

 jsr GetRand
 and.w #8190,d0
 move.w d0,CurrCPt(a0)

 jsr GetRand
 and.w #63,d0
 add.w #100,d0
 move.w d0,ObjTimer(a0)

.nonewdir

 move.w CurrCPt(a0),d3
 move.l #SineTable,a2
 add.w d3,a2
 move.w (a2),d2
 move.w 2048(a2),d1

 move.w Facing(a0),d3
 move.l #SineTable,a2
 move.w 120(a2),d6
 swap d6
 clr.w d6
 asr.l #1,d6
 lea (a2,d3.w),a2
 move.w (a2),d4	; sin
 move.w 2048(a2),d5 ; cos
 muls d2,d5
 muls d1,d4
 
 moveq #0,d3
 
 sub.l d5,d4
 blt.s .turnrighty
.turnlefty:

 cmp.l d4,d6
 bgt.s .doneturn

 move.w #-120,d3

 bra.s .doneturn
.turnrighty:

 neg.l d4
 cmp.l d4,d6
 bgt.s .doneturn

 move.w #120,d3

.doneturn:


 muls 2048(a2),d1
 muls (a2),d2
 add.l d2,d1
 cmp.l #$20000000,d1
 bgt.s .canwalk
 move.w #0,maxspd(a0)
 
 add.w d3,d3
 bne.s .canwalk
 move.w #240,d3

.canwalk:

 add.w Facing(a0),d3
 
 and.w #8191,d3

 move.w d3,Facing(a0)

 move.w (a0),d1
 move.l ObjectPoints,a1
 lea (a1,d1.w*8),a1
 move.w (a1),oldx 
 move.w 4(a1),oldz

 move.w maxspd(a0),d2
 muls TempFrames,d2
 move.w d2,speed
 move.w #300,Range

 move.w 4(a0),d0
 ext.l d0
 asl.l #7,d0
 sub.w #40*128,d0
 move.l d0,newy
 move.l d0,oldy
 
 move.b ObjInTop(a0),StoodInTop
 
 movem.l a6/d0/a0/a1/a3/a4/d7,-(a7)
 clr.b canshove
 move.w Facing(a0),d0
 jsr GoInDirection
 move.w #%1000000000,wallflags
 clr.b wallbounce
 Jsr MoveObject
 movem.l (a7)+,a6/d0/a0/a1/a3/a4/d7
 
 move.b StoodInTop,ObjInTop(a0)
 
 tst.b hitwall
 beq.s .nochangedir
 move.w #-1,ObjTimer(a0)
.nochangedir:
 
 move.l objroom,a2
 move.w (a2),d0
 move.w d0,12(a0)
 move.l #ZoneBrightTable,a5
 move.l (a5,d0.w*4),d0
 tst.b ObjInTop(a0)
 bne.s .okbit
 swap d0
.okbit:
 move.w d0,2(a0)
 
 move.w newx,(a1)
 move.w newz,4(a1)

 move.l ToZoneFloor(a2),d0
 tst.b ObjInTop(a0)
 beq.s .notintop
 move.l ToUpperFloor(a2),d0
.notintop:
 asr.l #7,d0
 sub.w #120,d0
 move.w d0,4(a0)

 moveq #0,d2
 move.b damagetaken(a0),d2
 asr.b #4,d2
 beq .noscream
 
 sub.b d2,numlives(a0)
 bgt.s .notdeadyet

 movem.l d0-d7/a0-a6,-(a7)
 sub.l ObjectPoints,a1
 add.l #ObjRotated,a1
 move.l (a1),Noisex
 move.w #400,Noisevol
 move.w #15,Samplenum
 move.b #1,chanpick
 clr.b notifplaying
 st backbeat
 move.b 1(a0),IDNUM
 jsr MakeSomeNoise
 
 move.w #120,d0
 bsr ComputeBlast
 
 movem.l (a7)+,d0-d7/a0-a6

 move.b #4,16(a0)
 move.b #%1000,17(a0)
 move.l #$50003,8(a0)
 move.w #$2020,6(a0)
 move.w #$1010,14(a0)
 
 
 rts
 
.notdeadyet:
 clr.b damagetaken(a0)
 
 movem.l d0-d7/a0-a6,-(a7)
 sub.l ObjectPoints,a1
 add.l #ObjRotated,a1
 move.l (a1),Noisex
 move.w #200,Noisevol
 move.w #8,Samplenum
 move.b #1,chanpick
 clr.b notifplaying
 move.b 1(a0),IDNUM
 st backbeat
 jsr MakeSomeNoise
 movem.l (a7)+,d0-d7/a0-a6
 
.noscream

 move.b ObjInTop(a0),ViewerTop
 move.b PLR1_StoodInTop,TargetTop
 move.l PLR1_Roompt,ToRoom
 move.l objroom,FromRoom
 move.w newx,Viewerx
 move.w newz,Viewerz
 move.b ObjInTop(a0),ViewerTop
 move.b PLR1_StoodInTop,TargetTop
 move.w PLR1_xoff,Targetx
 move.w PLR1_zoff,Targetz
 
 move.l PLR1_yoff,d0
 asr.l #7,d0
 move.w d0,Targety
 
 move.w 4(a0),Viewery
 
 move.w Facing(a0),Facedir
 jsr CanItBeSeen
 
 tst.b CanSee
 beq .carryonprowling

 move.b #1,17(a0)

.carryonprowling:

 move.b ObjInTop(a0),ViewerTop
 move.b PLR2_StoodInTop,TargetTop
 move.l PLR2_Roompt,ToRoom
 move.l objroom,FromRoom
 move.w newx,Viewerx
 move.w newz,Viewerz
 move.w p2_xoff,Targetx
 move.w p2_zoff,Targetz
 move.b ObjInTop(a0),ViewerTop
 move.b PLR2_StoodInTop,TargetTop
 move.l p2_yoff,d0
 asr.l #7,d0
 move.w d0,Targety
 move.w 4(a0),Viewery
 jsr CanItBeSeen
 
 tst.b CanSee
 beq .carryonprowling2

 or.b #2,17(a0)

.carryonprowling2:

 move.w Facing(a0),d0
 add.w #2048,d0
 and.w #8190,d0
 move.w d0,Facing(a0)


.thisonedead:
 rts

p_xoff: dc.l 0
p_zoff: dc.l 0
p_yoff: dc.l 0
p_Roompt: dc.l 0

ROBAttack_Player:

 move.w TempFrames,d0
 sub.w d0,FourthTimer(a0)

 btst #0,17(a0)
 beq MUSTPLR2
 btst #1,17(a0)
 bne.s COULDBE
 
 bra MUSTPLR1
 
COULDBE:
 move.l ObjectPoints,a1
 move.w (a0),d0
 move.w (a1,d0.w*8),d1
 move.w 4(a1,d0.w*8),d2
 
 move.w PLR1_xoff,d3
 move.w PLR1_zoff,d4
 
 sub.w d1,d3
 sub.w d2,d4
 
 muls d3,d3
 muls d4,d4
 add.l d4,d3
 move.w PLR2_xoff,d4
 move.w PLR2_zoff,d5
 sub.w d1,d4
 sub.w d2,d5
 muls d4,d4
 muls d5,d5
 add.l d5,d4
 cmp.l d3,d4
 ble MUSTPLR2

MUSTPLR1:

 move.w 12(a0),d2
 move.l ZoneAdds,a5
 move.l (a5,d2.w*4),d0
 add.l LEVELDATA,d0
 move.l d0,objroom
 
 move.w PLR1_xoff,newx
 move.w PLR1_zoff,newz
 move.w (a0),d1
 move.l #ObjRotated,a6
 move.l ObjectPoints,a1
 lea (a1,d1.w*8),a1
 lea (a6,d1.w*8),a6
 move.w (a1),oldx
 move.w 4(a1),oldz
 move.w maxspd(a0),d2
 muls.w TempFrames,d2
 move.w d2,speed
 move.w #300,Range
 move.w 4(a0),d0
 ext.l d0
 asl.l #7,d0
 sub.l #40*128,d0
 move.l d0,newy
 move.l d0,oldy

 move.b ObjInTop(a0),StoodInTop
 movem.l a6/d0/a0/a1/a3/a4/d7,-(a7)
 clr.b canshove
 clr.b GotThere
 jsr HeadTowardsAng
 move.w #%1000000000,wallflags
 clr.b wallbounce
 Jsr MoveObject
 movem.l (a7)+,a6/d0/a0/a1/a3/a4/d7
 move.b StoodInTop,ObjInTop(a0)
 
 move.w CosRet,d1
 move.w SinRet,d2
 move.w Facing(a0),d3
 move.l #SineTable,a2
 move.w 120(a2),d6
 swap d6
 clr.w d6
 asr.l #1,d6
 lea (a2,d3.w),a2
 move.w (a2),d4	; sin
 move.w 2048(a2),d5 ; cos
 muls d2,d5
 muls d1,d4
 
 moveq #0,d3
 
 sub.l d5,d4
 blt.s .turnrighty2
.turnlefty2:

 cmp.l d4,d6
 bgt.s .doneturn2

 move.w #-240,d3

 bra.s .doneturn2
.turnrighty2:

 neg.l d4
 cmp.l d4,d6
 bgt.s .doneturn2

 move.w #240,d3

.doneturn2:

 move.w #4,maxspd(a0)

 muls 2048(a2),d1
 muls (a2),d2
 add.l d2,d1
 cmp.l #$20000000,d1
 sgt.s canshootgun
 bgt.s .canwalk2
 move.w #0,maxspd(a0)
 
 add.w d3,d3
 bne.s .canwalk2
 move.w #480,d3

.canwalk2:

 add.w Facing(a0),d3
 
 and.w #8191,d3

 move.w d3,Facing(a0)
 
 
 move.l objroom,a2
 move.w (a2),d0
 move.w d0,12(a0)
 move.l #ZoneBrightTable,a5
 move.l (a5,d0.w*4),d0
 tst.b ObjInTop(a0)
 bne.s .okbit2
 swap d0
.okbit2:
 sub.w #5,d0
 move.w d0,2(a0)
 
 move.w newx,(a1)
 move.w newz,4(a1)

 move.l ToZoneFloor(a2),d0
 tst.b ObjInTop(a0)
 beq.s .notintop2
 move.l ToUpperFloor(a2),d0
.notintop2:
 asr.l #7,d0
 sub.w #120,d0
 move.w d0,4(a0)
 
 move.b damagetaken(a0),d2
 asr.b #4,d2
 beq .noscream2
 
 sub.b d2,numlives(a0)
 bgt.s .notdeadyet2

 movem.l d0-d7/a0-a6,-(a7)
 sub.l ObjectPoints,a1
 add.l #ObjRotated,a1
 move.l (a1),Noisex
 move.w #400,Noisevol
 move.w #15,Samplenum
 move.b #1,chanpick
 clr.b notifplaying
 st backbeat
 move.b 1(a0),IDNUM
 jsr MakeSomeNoise
 
 move.w #400,d0
 bsr ComputeBlast
 
 movem.l (a7)+,d0-d7/a0-a6

 move.b #4,16(a0)
 move.b #%1000,17(a0)
 move.l #$50003,8(a0)
 move.w #$2020,6(a0)
 move.w #$1010,14(a0)
 
 
 rts 
 
.notdeadyet2:
 clr.b damagetaken(a0)
 
 movem.l d0-d7/a0-a6,-(a7)
 move.l (a6),Noisex
 move.w #200,Noisevol
 move.w #8,Samplenum
 move.b #1,chanpick
 clr.b notifplaying
 st backbeat
 move.b 1(a0),IDNUM
 jsr MakeSomeNoise
 movem.l (a7)+,d0-d7/a0-a6

 bra .cantshoot
 
.noscream2:

 tst.b canshootgun
 beq .cantshoot

 cmp.w #20,FourthTimer(a0)
 bge .cantshoot
 
 move.w #50,FourthTimer(a0)
 
 move.w ThirdTimer(a0),d0
 sub.w #1,d0
 cmp.w #-1,d0
 bge.s .noreset
 
 jsr GetRand
 lsr.w #4,d0
 and.w #127,d0
 add.w #150,d0

.noreset:
 move.w d0,ThirdTimer(a0)

 move.w #9,Samplenum
 move.b #4,SHOTTYPE
 move.b #10,SHOTPOWER
 move.w #16,SHOTSPEED
 move.w #3,SHOTSHIFT
 move.w #0,SHOTOFFMULT
 move.l #0*128,SHOTYOFF
 move.w #-100,2(a0)

 jsr FireAtPlayer1
 
.cantshoot:
 
 move.b #0,17(a0)

 move.l PLR1_Roompt,ToRoom
 move.l objroom,FromRoom
 move.w newx,Viewerx
 move.w newz,Viewerz
 move.w p1_xoff,Targetx
 move.w p1_zoff,Targetz
 move.b ObjInTop(a0),ViewerTop
 move.b PLR1_StoodInTop,TargetTop
 move.w Facing(a0),Facedir
 move.l p1_yoff,d0
 asr.l #7,d0
 move.w d0,Targety
 
 move.w 4(a0),Viewery

 jsr CanItBeSeen
 
 tst.b CanSee
 beq .carryonattack

 move.b #1,17(a0)

.carryonattack:

 move.l PLR2_Roompt,ToRoom
 move.l objroom,FromRoom
 move.w newx,Viewerx
 move.w newz,Viewerz
 move.w p2_xoff,Targetx
 move.w p2_zoff,Targetz
 move.w Facing(a0),Facedir
 move.b ObjInTop(a0),ViewerTop
 move.b PLR2_StoodInTop,TargetTop
 move.l p2_yoff,d0
 asr.l #7,d0
 move.w d0,Targety
 
 move.w 4(a0),Viewery

 jsr CanItBeSeen
 
 tst.b CanSee
 beq .carryonattack2

 or.b #2,17(a0)

.carryonattack2:
 move.w Facing(a0),d0
 add.w #2048,d0
 and.w #8190,d0
 move.w d0,Facing(a0)

 rts

MUSTPLR2:

 move.w 12(a0),d2
 move.l ZoneAdds,a5
 move.l (a5,d2.w*4),d0
 add.l LEVELDATA,d0
 move.l d0,objroom
 
 move.w PLR2_xoff,newx
 move.w PLR2_zoff,newz
 move.w (a0),d1
 move.l #ObjRotated,a6
 move.l ObjectPoints,a1
 lea (a1,d1.w*8),a1
 lea (a6,d1.w*8),a6
 move.w (a1),oldx
 move.w 4(a1),oldz
 move.w maxspd(a0),d2
 muls.w TempFrames,d2
 move.w d2,speed
 move.w #300,Range
 move.w 4(a0),d0
 ext.l d0
 asl.l #7,d0
 sub.l #80*128,d0
 move.l d0,newy
 move.l d0,oldy

 move.b ObjInTop(a0),StoodInTop
 movem.l a6/d0/a0/a1/a3/a4/d7,-(a7)
 clr.b canshove
 clr.b GotThere
 jsr HeadTowardsAng
 move.w #%1000000000,wallflags
 clr.b wallbounce
 Jsr MoveObject
 movem.l (a7)+,a6/d0/a0/a1/a3/a4/d7
 move.b StoodInTop,ObjInTop(a0)
 
 move.w CosRet,d1
 move.w SinRet,d2
 move.w Facing(a0),d3
 move.l #SineTable,a2
 move.w 120(a2),d6
 swap d6
 clr.w d6
 asr.l #1,d6
 lea (a2,d3.w),a2
 move.w (a2),d4	; sin
 move.w 2048(a2),d5 ; cos
 muls d2,d5
 muls d1,d4
 
 moveq #0,d3
 
 sub.l d5,d4
 blt.s .turnrighty2
.turnlefty2:

 cmp.l d4,d6
 bgt.s .doneturn2

 move.w #-120,d3

 bra.s .doneturn2
.turnrighty2:

 neg.l d4
 cmp.l d4,d6
 bgt.s .doneturn2

 move.w #120,d3

.doneturn2:

 move.w #4,maxspd(a0)

 muls 2048(a2),d1
 muls (a2),d2
 add.l d2,d1
 cmp.l #$20000000,d1
 sgt.s canshootgun
 bgt.s .canwalk2
 move.w #0,maxspd(a0)
 
 add.w d3,d3
 bne.s .canwalk2
 move.w #240,d3

.canwalk2:

 add.w Facing(a0),d3
 
 and.w #8191,d3

 move.w d3,Facing(a0)
 
 
 move.l objroom,a2
 move.w (a2),d0
 move.w d0,12(a0)
 move.l #ZoneBrightTable,a5
 move.l (a5,d0.w*4),d0
 tst.b ObjInTop(a0)
 bne.s .okbit2
 swap d0
.okbit2:
 sub.w #5,d0
 move.w d0,2(a0)
 
 move.w newx,(a1)
 move.w newz,4(a1)

 move.l ToZoneFloor(a2),d0
 tst.b ObjInTop(a0)
 beq.s .notintop2
 move.l ToUpperFloor(a2),d0
.notintop2:
 asr.l #7,d0
 sub.w #120,d0
 move.w d0,4(a0)
 
 move.b damagetaken(a0),d2
 asr.b #4,d2
 beq .noscream2
 
 sub.b d2,numlives(a0)
 bgt.s .notdeadyet2

 movem.l d0-d7/a0-a6,-(a7)
 sub.l ObjectPoints,a1
 add.l #ObjRotated,a1
 move.l (a1),Noisex
 move.w #400,Noisevol
 move.w #15,Samplenum
 move.b #1,chanpick
 clr.b notifplaying
 st backbeat
 move.b 1(a0),IDNUM
 jsr MakeSomeNoise
 
 move.w #400,d0
 bsr ComputeBlast
 
 movem.l (a7)+,d0-d7/a0-a6
 
 move.b #4,16(a0)
 move.b #%1000,17(a0)
 move.l #$50003,8(a0)
 move.w #$2020,6(a0)
 move.w #$1010,14(a0)
 
 rts 
 
.notdeadyet2:
 clr.b damagetaken(a0)
 
 movem.l d0-d7/a0-a6,-(a7)
 move.l (a6),Noisex
 move.w #200,Noisevol
 move.w #8,Samplenum
 move.b #1,chanpick
 clr.b notifplaying
 st backbeat
 move.b 1(a0),IDNUM
 jsr MakeSomeNoise
 movem.l (a7)+,d0-d7/a0-a6

 bra .cantshoot
 
.noscream2:

 tst.b canshootgun
 beq .cantshoot

 cmp.w #20,FourthTimer(a0)
 bge .cantshoot
 
 move.w #50,FourthTimer(a0)
 
 move.w ThirdTimer(a0),d0
 sub.w #1,d0
 cmp.w #-2,d0
 bge.s .noreset
 
 jsr GetRand
 and.w #127,d0
 add.w #100,d0

.noreset:
 move.w d0,ThirdTimer(a0)

 move.w #9,Samplenum
 move.b #4,SHOTTYPE
 move.b #10,SHOTPOWER
 move.w #16,SHOTSPEED
 move.w #3,SHOTSHIFT
 move.w #0,SHOTOFFMULT
 move.l #0*128,SHOTYOFF
 move.w #-100,2(a0)

 jsr FireAtPlayer2
 
.cantshoot:
  
 move.b #0,17(a0)

 move.l PLR1_Roompt,ToRoom
 move.l objroom,FromRoom
 move.w newx,Viewerx
 move.w newz,Viewerz
 move.w p1_xoff,Targetx
 move.w p1_zoff,Targetz
 move.b ObjInTop(a0),ViewerTop
 move.b PLR1_StoodInTop,TargetTop
 move.w Facing(a0),Facedir
 move.l p1_yoff,d0
 asr.l #7,d0
 move.w d0,Targety
 
 move.w 4(a0),Viewery

 jsr CanItBeSeen
 
 tst.b CanSee
 beq .carryonattack

 move.b #1,17(a0)

.carryonattack:

 move.l PLR2_Roompt,ToRoom
 move.l objroom,FromRoom
 move.w newx,Viewerx
 move.w newz,Viewerz
 move.w p2_xoff,Targetx
 move.w p2_zoff,Targetz
 move.b ObjInTop(a0),ViewerTop
 move.b PLR2_StoodInTop,TargetTop
 move.w Facing(a0),Facedir
 move.l p2_yoff,d0
 asr.l #7,d0
 move.w d0,Targety
 
 move.w 4(a0),Viewery

 jsr CanItBeSeen
 
 tst.b CanSee
 beq .carryonattack2

 or.b #2,17(a0)

.carryonattack2:
 move.w Facing(a0),d0
 add.w #2048,d0
 and.w #8190,d0
 move.w d0,Facing(a0)

 rts


canshootgun: dc.w 0