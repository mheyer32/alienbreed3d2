ItsAFlyingNasty:

 tst.b NASTY
 bne .yesnas
 move.w #-1,12(a0)
 rts
.yesnas:

 move.w #$1f1f,14(a0)

 clr.b exitfirst

 move.b worry(a0),d0
 move.b d0,d1
 and.w #128,d1
 and.b #127,d0
 sub.b #1,d0
 bge.s .oknn
 move.b #0,d0
.oknn: 
 
 add.b d0,d1
 move.b d1,worry(a0)

 move.w (a0),CollId
 move.w #160,extlen
 move.b #2,awayfromwall

 move.l #0,StepUpVal
 move.l #$1000000,StepDownVal
 move.l #96*128,thingheight
 move.w #8,screamsound
 move.w #64,nasheight
 
 move.w #$6060,6(a0)
 
 clr.b gotgun
 move.w 12(a0),d2
 bge.s .stillalive
.notthisone:
 rts
.stillalive:

 tst.b numlives(a0)
 bgt .notdying
 move.b #0,numlives(a0)
 move.l ZoneAdds,a1
 move.l (a1,d2.w*4),a1
 add.l LEVELDATA,a1
 move.l ToZoneFloor(a1),d0
 tst.b ObjInTop(a0)
 beq.s .notintopp
 move.l ToUpperFloor(a1),d0
.notintopp:
 asr.l #7,d0
 sub.w nasheight,d0
 cmp.w 4(a0),d0
 ble.s .putitin
 move.w TempFrames,d0
 asl.w #4,d0
 add.w d0,4(a0)
 add.w d0,FourthTimer(a0)
 bra .nosplatch

.putitin:
 move.w d0,4(a0)
 
 cmp.w #20,10(a0)
 bne.s .notyet
 move.w #80,d0
 jsr FindCloseRoom
 rts
.notyet:
 
 move.w FourthTimer(a0),d0
 asr.w #4,d0
 add.w #1,d0
 move.w d0,d2
 
 move.w (a0),d0
 move.l ObjectPoints,a1
 move.w (a1,d0.w*8),newx
 move.w 4(a1,d0.w*8),newz
 
 movem.l d0-d7/a0-a6,-(a7)
 move.w #0,d0
 move.w #31,d3
 jsr ExplodeIntoBits
 movem.l (a7)+,d0-d7/a0-a6
 move.w #20,10(a0)
 move.w #80,d0
 jsr FindCloseRoom

 rts
.nosplatch

 move.w TempFrames,d0
 sub.w d0,ThirdTimer(a0)
 bge.s .onfloordead
 move.w #20,ThirdTimer(a0)
 
 move.w 10(a0),d0
 cmp.w #19,d0
 bge .onfloordead
 add.w #1,10(a0)
 move.w #80,d0
 jsr FindCloseRoom

 rts

.onfloordead:
 move.w #80,d0
 jsr FindCloseRoom

 rts

.notdying: 

 tst.b 17(a0)
 beq.s .cantseeplayer
 tst.w ThirdTimer(a0)
 ble FlyingBallAttack
 move.w TempFrames,d0
 sub.w d0,ThirdTimer(a0)
 bra .waitandsee
 
.cantseeplayer:

 jsr GetRand
 lsr.w #4,d0
 and.w #31,d0
 add.w #10,d0
 move.w d0,ThirdTimer(a0)

.waitandsee:

 move.w #30,FourthTimer(a0)

 move.w 12(a0),d2
 move.l ZoneAdds,a5
 move.l (a5,d2.w*4),d0
 add.l LEVELDATA,d0
 move.l d0,objroom

 jsr ViewpointToDraw

 asl.l #2,d0
 add.l alframe,d0
 add.l #$40000,d0
 move.l d0,8(a0)

 move.w TurnSpeed(a0),d0
 add.w Facing(a0),d0
 and.w #8190,d0
 move.w d0,Facing(a0)

 move.w 4(a0),d0
 ext.l d0
 asl.l #7,d0
 sub.l #48*128,d0
 move.l d0,newy
 move.l d0,oldy

 move.w 12(a0),FromZone
 bsr CheckTeleport
 tst.b OKTEL
 beq.s .notel
 move.l floortemp,d0
 asr.l #7,d0
 add.w d0,4(a0)
 bra .nochangedir
.notel:

 
 move.w maxspd(a0),d2
 muls TempFrames,d2
 move.w d2,speed
 move.w Facing(a0),d0
 move.b ObjInTop(a0),StoodInTop
 movem.l a6/d0/a0/a1/a3/a4/d7,-(a7)
 jsr GoInDirection
 move.w #%1000000000,wallflags
 
 move.l #%11111111110111100001,CollideFlags
 jsr Collision
 tst.b hitwall
 beq.s .okcanmove
 
 move.w oldx,newx
 move.w oldz,newz
 movem.l (a7)+,a6/d0/a0/a1/a3/a4/d7
 bra.s .hitathing
 
.okcanmove:
 
 clr.b wallbounce
 jsr MoveObject
 movem.l (a7)+,a6/d0/a0/a1/a3/a4/d7
 move.b StoodInTop,ObjInTop(a0)

.hitathing:

; tst.b hitwall
; beq.s .nochangedir
; move.w #-1,ObjTimer(a0)
.nochangedir

 move.l objroom,a2
 move.w (a2),12(a0)
 move.w newx,(a1)
 move.w newz,4(a1)

 move.w (a2),d0
 move.l #ZoneBrightTable,a5
 move.l (a5,d0.w*4),d0
 tst.b ObjInTop(a0)
 bne.s .okbit
 swap d0
.okbit:
 move.w d0,2(a0)
 
 move.l ToZoneFloor(a2),d0
 move.l ToZoneRoof(a2),d1
 tst.b ObjInTop(a0)
 beq.s .notintop
 move.l ToUpperFloor(a2),d0
 move.l ToUpperRoof(a2),d1
.notintop:

 move.w objyvel(a0),d2
 add.w d2,4(a0)

 move.w 4(a0),d2
 ext.l d2
 asl.l #7,d2
 move.l d2,d3
 add.l #48*256,d2
 sub.l #48*256,d3
 
 cmp.l d0,d2
 blt.s .botnohit
 move.l d0,d2
 move.l d2,d3
 neg.w objyvel(a0)
 sub.l #96*256,d3
.botnohit:

 cmp.l d1,d3
 bgt.s .topnohit
 move.l d1,d3
 neg.w objyvel(a0)
.topnohit:

 add.l #48*256,d3
 asr.l #7,d3
 move.w d3,4(a0)

 move.b damagetaken(a0),d2
 beq .noscream
 
 sub.b d2,numlives(a0)
 bgt .notdeadyet

 cmp.b #40,d2
 ble.s .noexplode

 movem.l d0-d7/a0-a6,-(a7)
 sub.l ObjectPoints,a1
 add.l #ObjRotated,a1
 move.l (a1),Noisex
 move.w #400,Noisevol
 move.w #14,Samplenum
 move.b #1,chanpick
 clr.b notifplaying
 st backbeat
 move.b 1(a0),IDNUM
 jsr MakeSomeNoise
 movem.l (a7)+,d0-d7/a0-a6

 movem.l d0-d7/a0-a6,-(a7)
 move.w #0,d0
 move.w #9,d2
 move.w #31,d3
 jsr ExplodeIntoBits
 movem.l (a7)+,d0-d7/a0-a6
 move.w #-1,12(a0)
 rts

.noexplode:

 movem.l d0-d7/a0-a6,-(a7)
 sub.l ObjectPoints,a1
 add.l #ObjRotated,a1
 move.l (a1),Noisex
 move.w #200,Noisevol
 move.w screamsound,Samplenum
 move.b #1,chanpick
 clr.b notifplaying
 st backbeat
 move.b 1(a0),IDNUM
 jsr MakeSomeNoise
 movem.l (a7)+,d0-d7/a0-a6
 move.w #18,10(a0)
 move.w #30,ThirdTimer(a0)
 move.w #0,FourthTimer(a0)
 move.w #80,d0
 jsr FindCloseRoom
 rts
 
.notdeadyet:
 clr.b damagetaken(a0)
 movem.l d0-d7/a0-a6,-(a7)
 sub.l ObjectPoints,a1
 add.l #ObjRotated,a1
 move.l (a1),Noisex
 move.w #200,Noisevol
 move.w screamsound,Samplenum
 move.b #1,chanpick
 clr.b notifplaying
 move.b 1(a0),IDNUM
 st backbeat
 jsr MakeSomeNoise
 movem.l (a7)+,d0-d7/a0-a6
 
.noscream

 
 move.w TempFrames,d0
 sub.w d0,ObjTimer(a0)
 bge.s .keepsamedir
 
 jsr GetRand
 lsr.w #4,d0
 and.w #255,d0
 sub.w #128,d0
 add.w d0,d0
 move.w d0,TurnSpeed(a0)
 move.w #50,ObjTimer(a0)
 
 jsr GetRand
 lsr.w #4,d0
 and.w #7,d0
 sub.w #3,d0
 move.w d0,d1
 jsr GetRand
 lsr.w #5,d0
 and.w #1,d0
 sub.w d0,d1
 move.w d1,objyvel(a0)
 
.keepsamedir:

 move.w TempFrames,d0
 sub.w d0,SecTimer(a0)
 bge.s .nohiss

 movem.l d0-d7/a0-a6,-(a7)
 sub.l ObjectPoints,a1
 add.l #ObjRotated,a1
 move.l (a1),Noisex
 move.w #100,Noisevol
 move.w #16,Samplenum
 move.b #1,chanpick
 clr.b notifplaying
 move.b 1(a0),IDNUM
 st backbeat
 jsr MakeSomeNoise
 movem.l (a7)+,d0-d7/a0-a6
 
 Jsr GetRand
 lsr.w #6,d0
 and.w #255,d0
 add.w #300,d0
 move.w d0,SecTimer(a0)

.nohiss:

 move.b ObjInTop(a0),ViewerTop
 move.b PLR1_StoodInTop,TargetTop
 move.l PLR1_Roompt,ToRoom
 move.l objroom,FromRoom
 move.w newx,Viewerx
 move.w newz,Viewerz
 move.w PLR1_xoff,Targetx
 move.w PLR1_zoff,Targetz
 move.l PLR1_yoff,d0
 asr.l #7,d0
 move.w d0,Targety
 move.w 4(a0),Viewery
 jsr CanItBeSeen
 
 clr.b 17(a0)
 tst.b CanSee
 beq .carryonprowling

 move.b #1,17(a0)

.carryonprowling:

 cmp.b #'n',mors
 beq.s .carryonprowling2

 move.b ObjInTop(a0),ViewerTop
 move.b PLR2_StoodInTop,TargetTop
 move.l PLR2_Roompt,ToRoom
 move.l objroom,FromRoom
 move.w newx,Viewerx
 move.w newz,Viewerz
 move.w PLR2_xoff,Targetx
 move.w PLR2_zoff,Targetz
 move.l PLR2_yoff,d0
 asr.l #7,d0
 move.w d0,Targety
 move.w 4(a0),Viewery
 jsr CanItBeSeen
 
 tst.b CanSee
 beq .carryonprowling2

 or.b #2,17(a0)

.carryonprowling2:

 move.w #80,d0
 jsr FindCloseRoom

 rts
 
FlyingBallAttack:

 btst #0,17(a0)
 beq FlyingBallAttackPLR2
 btst #1,17(a0)
 beq FlyingBallAttackPLR1

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
 bgt FlyingBallAttackPLR1

FlyingBallAttackPLR2:

 move.w TempFrames,d0
 sub.w d0,FourthTimer(a0)
 bgt.s .oktoshoot
 move.w #50,ThirdTimer(a0)
.oktoshoot:
 
 move.w 12(a0),d2
 move.l ZoneAdds,a5
 move.l (a5,d2.w*4),d0
 add.l LEVELDATA,d0
 move.l d0,objroom

 jsr ViewpointToDraw

 asl.l #2,d0
 bne.s .nofacing
 move.l #16,d0
 bra .facing
.nofacing:
 
 add.l alframe,d0
.facing
 add.l #$40000,d0
 move.l d0,8(a0)

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
 move.w #120,Range
 move.w 4(a0),d0
 ext.l d0
 asl.l #7,d0
 sub.l #48*256,d0
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
 
 move.w AngRet,Facing(a0)
 
 move.l objroom,a2
 move.w (a2),12(a0)
 move.w oldx,(a1)
 move.w oldz,4(a1)

 move.w (a2),d0
 move.l #ZoneBrightTable,a5
 move.l (a5,d0.w*4),d0
 tst.b ObjInTop(a0)
 bne.s .okbit
 swap d0
.okbit:
 move.w d0,2(a0)
 
 move.l ToZoneFloor(a2),d0
 move.l ToZoneRoof(a2),d1
 tst.b ObjInTop(a0)
 beq.s .notintop
 move.l ToUpperFloor(a2),d0
 move.l ToUpperRoof(a2),d1
.notintop:

 move.w objyvel(a0),d2
 add.w d2,4(a0)

 move.w 4(a0),d2
 ext.l d2
 asl.l #7,d2
 move.l d2,d3
 add.l #48*256,d2
 sub.l #48*256,d3
 
 cmp.l d0,d2
 blt.s .botnohit
 move.l d0,d2
 move.l d2,d3
 neg.w objyvel(a0)
 sub.l #96*256,d3
.botnohit:

 cmp.l d1,d3
 bgt.s .topnohit
 move.l d1,d3
 neg.w objyvel(a0)
.topnohit:

 add.l #48*256,d3
 asr.l #7,d3
 move.w d3,4(a0)

 move.b damagetaken(a0),d2
 beq .noscream
 
 sub.b d2,numlives(a0)
 bgt .notdeadyet

 cmp.b #40,d2
 ble.s .noexplode

 movem.l d0-d7/a0-a6,-(a7)
 sub.l ObjectPoints,a1
 add.l #ObjRotated,a1
 move.l (a1),Noisex
 move.w #400,Noisevol
 move.w #14,Samplenum
 move.b #1,chanpick
 clr.b notifplaying
 st backbeat
 move.b 1(a0),IDNUM
 jsr MakeSomeNoise
 movem.l (a7)+,d0-d7/a0-a6

 movem.l d0-d7/a0-a6,-(a7)
 move.w #0,d0
 move.w #9,d2
 move.w #31,d3
 jsr ExplodeIntoBits
 movem.l (a7)+,d0-d7/a0-a6
 move.w #-1,12(a0)
 rts

.noexplode:

 movem.l d0-d7/a0-a6,-(a7)
 sub.l ObjectPoints,a1
 add.l #ObjRotated,a1
 move.l (a1),Noisex
 move.w #200,Noisevol
 move.w screamsound,Samplenum
 move.b #1,chanpick
 clr.b notifplaying
 st backbeat
 move.b 1(a0),IDNUM
 jsr MakeSomeNoise
 movem.l (a7)+,d0-d7/a0-a6
 move.w #18,10(a0)
 move.w #80,d0
 jsr FindCloseRoom
 rts
 
.notdeadyet:
 clr.b damagetaken(a0)
 movem.l d0-d7/a0-a6,-(a7)
 sub.l ObjectPoints,a1
 add.l #ObjRotated,a1
 move.l (a1),Noisex
 move.w #200,Noisevol
 move.w screamsound,Samplenum
 move.b #1,chanpick
 clr.b notifplaying
 move.b 1(a0),IDNUM
 st backbeat
 jsr MakeSomeNoise
 movem.l (a7)+,d0-d7/a0-a6
 
.noscream

; tst.b canshootgun
; beq .cantshoot
 cmp.w #20,FourthTimer(a0)
 bge .cantshoot
 
  move.w #50,ThirdTimer(a0)
 
 move.w #17,10(a0)
 

 move.w #20,Samplenum
 move.b #0,SHOTTYPE
 move.b #5,SHOTPOWER
 move.w #16,SHOTSPEED
 move.w #3,SHOTSHIFT
 move.b ObjInTop(a0),SHOTINTOP
 move.w #0,SHOTOFFMULT
 move.w #-10,2(a0)
 move.l #0,SHOTYOFF
 jsr FireAtPlayer2

.cantshoot:

 
 move.w TempFrames,d0
 sub.w d0,SecTimer(a0)
 bge.s .nohiss

 movem.l d0-d7/a0-a6,-(a7)
 sub.l ObjectPoints,a1
 add.l #ObjRotated,a1
 move.l (a1),Noisex
 move.w #100,Noisevol
 move.w #16,Samplenum
 move.b #1,chanpick
 clr.b notifplaying
 move.b 1(a0),IDNUM
 st backbeat
 jsr MakeSomeNoise
 movem.l (a7)+,d0-d7/a0-a6
 
 Jsr GetRand
 lsr.w #6,d0
 and.w #255,d0
 add.w #300,d0
 move.w d0,SecTimer(a0)

.nohiss:

 move.b ObjInTop(a0),ViewerTop
 move.b PLR1_StoodInTop,TargetTop
 move.l PLR1_Roompt,ToRoom
 move.l objroom,FromRoom
 move.w newx,Viewerx
 move.w newz,Viewerz
 move.w PLR1_xoff,Targetx
 move.w PLR1_zoff,Targetz
 move.l PLR1_yoff,d0
 asr.l #7,d0
 move.w d0,Targety
 move.w 4(a0),Viewery
 jsr CanItBeSeen
 
 clr.b 17(a0)
 tst.b CanSee
 beq .carryonprowling

 move.b #1,17(a0)

.carryonprowling:

 cmp.b #'n',mors
 beq.s .carryonprowling2


 move.b ObjInTop(a0),ViewerTop
 move.b PLR2_StoodInTop,TargetTop
 move.l PLR2_Roompt,ToRoom
 move.l objroom,FromRoom
 move.w newx,Viewerx
 move.w newz,Viewerz
 move.w PLR2_xoff,Targetx
 move.w PLR2_zoff,Targetz
 move.l PLR2_yoff,d0
 asr.l #7,d0
 move.w d0,Targety
 move.w 4(a0),Viewery
 jsr CanItBeSeen
 
 tst.b CanSee
 beq .carryonprowling2

 or.b #2,17(a0)

.carryonprowling2:
 move.w #80,d0
 jsr FindCloseRoom

 rts


FlyingBallAttackPLR1:
 
 move.w TempFrames,d0
 sub.w d0,FourthTimer(a0)
 bgt.s .oktoshoot
 move.w #50,ThirdTimer(a0)
.oktoshoot:
 
 move.w 12(a0),d2
 move.l ZoneAdds,a5
 move.l (a5,d2.w*4),d0
 add.l LEVELDATA,d0
 move.l d0,objroom

 jsr ViewpointToDraw

 asl.l #2,d0
 bne.s .nofacing
 move.l #16,d0
 bra .facing
.nofacing:
 
 add.l alframe,d0
.facing
 add.l #$40000,d0
 move.l d0,8(a0)

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
 move.w #120,Range
 move.w 4(a0),d0
 ext.l d0
 asl.l #7,d0
 sub.l #20*256,d0
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
 
 move.w AngRet,Facing(a0)
 
 move.l objroom,a2
 move.w (a2),12(a0)
 move.w oldx,(a1)
 move.w oldz,4(a1)

 move.w (a2),d0
 move.l #ZoneBrightTable,a5
 move.l (a5,d0.w*4),d0
 tst.b ObjInTop(a0)
 bne.s .okbit
 swap d0
.okbit:
 move.w d0,2(a0)
 
 move.l ToZoneFloor(a2),d0
 move.l ToZoneRoof(a2),d1
 tst.b ObjInTop(a0)
 beq.s .notintop
 move.l ToUpperFloor(a2),d0
 move.l ToUpperRoof(a2),d1
.notintop:

 move.w objyvel(a0),d2
 add.w d2,4(a0)

 move.w 4(a0),d2
 ext.l d2
 asl.l #7,d2
 move.l d2,d3
 add.l #48*256,d2
 sub.l #48*256,d3
 
 cmp.l d0,d2
 blt.s .botnohit
 move.l d0,d2
 move.l d2,d3
 neg.w objyvel(a0)
 sub.l #96*256,d3
.botnohit:

 cmp.l d1,d3
 bgt.s .topnohit
 move.l d1,d3
 neg.w objyvel(a0)
.topnohit:

 add.l #48*256,d3
 asr.l #7,d3
 move.w d3,4(a0)

 move.b damagetaken(a0),d2
 beq .noscream
 
 sub.b d2,numlives(a0)
 bgt .notdeadyet

 cmp.b #40,d2
 ble.s .noexplode

 movem.l d0-d7/a0-a6,-(a7)
 sub.l ObjectPoints,a1
 add.l #ObjRotated,a1
 move.l (a1),Noisex
 move.w #400,Noisevol
 move.w #14,Samplenum
 move.b #1,chanpick
 clr.b notifplaying
 st backbeat
 move.b 1(a0),IDNUM
 jsr MakeSomeNoise
 movem.l (a7)+,d0-d7/a0-a6

 movem.l d0-d7/a0-a6,-(a7)
 move.w #0,d0
 move.w #9,d2
 move.w #31,d3
 jsr ExplodeIntoBits
 movem.l (a7)+,d0-d7/a0-a6
 move.w #-1,12(a0)
 rts

.noexplode:

 movem.l d0-d7/a0-a6,-(a7)
 sub.l ObjectPoints,a1
 add.l #ObjRotated,a1
 move.l (a1),Noisex
 move.w #200,Noisevol
 move.w screamsound,Samplenum
 move.b #1,chanpick
 clr.b notifplaying
 st backbeat
 move.b 1(a0),IDNUM
 jsr MakeSomeNoise
 movem.l (a7)+,d0-d7/a0-a6
 move.w #18,10(a0)
 move.w #80,d0
 jsr FindCloseRoom
 rts
 
.notdeadyet:
 clr.b damagetaken(a0)
 movem.l d0-d7/a0-a6,-(a7)
 sub.l ObjectPoints,a1
 add.l #ObjRotated,a1
 move.l (a1),Noisex
 move.w #200,Noisevol
 move.w screamsound,Samplenum
 move.b #1,chanpick
 clr.b notifplaying
 move.b 1(a0),IDNUM
 st backbeat
 jsr MakeSomeNoise
 movem.l (a7)+,d0-d7/a0-a6
 
.noscream

; tst.b canshootgun
; beq .cantshoot
 cmp.w #20,FourthTimer(a0)
 bge .cantshoot

 move.w #50,ThirdTimer(a0)
 
 move.w #17,10(a0)
 

 move.w #20,Samplenum
 move.b #0,SHOTTYPE
 move.b #5,SHOTPOWER
 move.w #16,SHOTSPEED
 move.w #3,SHOTSHIFT
 move.b ObjInTop(a0),SHOTINTOP
 move.w #0,SHOTOFFMULT
 move.w #-10,2(a0)
 move.l #0,SHOTYOFF
 jsr FireAtPlayer1

.cantshoot:

 
 move.w TempFrames,d0
 sub.w d0,SecTimer(a0)
 bge.s .nohiss

 movem.l d0-d7/a0-a6,-(a7)
 sub.l ObjectPoints,a1
 add.l #ObjRotated,a1
 move.l (a1),Noisex
 move.w #100,Noisevol
 move.w #16,Samplenum
 move.b #1,chanpick
 clr.b notifplaying
 move.b 1(a0),IDNUM
 st backbeat
 jsr MakeSomeNoise
 movem.l (a7)+,d0-d7/a0-a6
 
 Jsr GetRand
 lsr.w #6,d0
 and.w #255,d0
 add.w #300,d0
 move.w d0,SecTimer(a0)

.nohiss:

 move.b ObjInTop(a0),ViewerTop
 move.b PLR1_StoodInTop,TargetTop
 move.l PLR1_Roompt,ToRoom
 move.l objroom,FromRoom
 move.w newx,Viewerx
 move.w newz,Viewerz
 move.w PLR1_xoff,Targetx
 move.w PLR1_zoff,Targetz
 move.l PLR1_yoff,d0
 asr.l #7,d0
 move.w d0,Targety
 move.w 4(a0),Viewery
 jsr CanItBeSeen
 
 clr.b 17(a0)
 tst.b CanSee
 beq .carryonprowling

 move.b #1,17(a0)

.carryonprowling:

 cmp.b #'n',mors
 beq.s .carryonprowling2


 move.b ObjInTop(a0),ViewerTop
 move.b PLR2_StoodInTop,TargetTop
 move.l PLR2_Roompt,ToRoom
 move.l objroom,FromRoom
 move.w newx,Viewerx
 move.w newz,Viewerz
 move.w PLR2_xoff,Targetx
 move.w PLR2_zoff,Targetz
 move.l PLR2_yoff,d0
 asr.l #7,d0
 move.w d0,Targety
 move.w 4(a0),Viewery
 jsr CanItBeSeen
 
 tst.b CanSee
 beq .carryonprowling2

 or.b #2,17(a0)

.carryonprowling2:
 move.w #80,d0
 jsr FindCloseRoom

 rts
 