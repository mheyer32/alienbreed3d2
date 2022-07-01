ItsAToughMarine:

 tst.b NASTY
 bne .yesnas
 move.w #-1,12(a0)
 rts
.yesnas:

 move.w #$1f1f,14(a0)
 move.w #$4545,6(a0)

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
 move.w #80,extlen
 move.b #1,awayfromwall

 move.l #20*256,StepUpVal
 move.l #20*256,StepDownVal
 move.l #128*128,thingheight
 move.l #4,deadframe
 move.w #0,screamsound
 move.w #64,nasheight
 clr.b gotgun
 move.w 12(a0),d2
 bge.s .stillalive
.notthisone:
 move.w 12(a0),GraphicRoom(a0)
 rts
.stillalive:

 tst.b numlives(a0)
 bgt .notdying

 move.w ThirdTimer(a0),d1
 sub.w TempFrames,d1
 bge.s .noneg
 move.w #0,d1
.noneg:
 move.w d1,ThirdTimer(a0)
 
 move.w .dyinganim(pc,d1.w*2),10(a0)
 
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
 sub.w #64,d0
 move.w d0,4(a0)
 
 move.w 12(a0),GraphicRoom(a0)
 rts
 
.dyinganim:
 dcb.w 6,18
 dcb.w 10,17
 dcb.w 10,16


.notdying: 

 tst.b 17(a0)
 beq.s .cantseeplayer
 tst.w ThirdTimer(a0)
 ble ToughMarineAttack
 move.w TempFrames,d0
 sub.w d0,ThirdTimer(a0)
 bra .waitandsee
 
.cantseeplayer:

 jsr GetRand
 lsr.w #4,d0
 and.w #63,d0
 add.w #20,d0
 move.w d0,ThirdTimer(a0)

.waitandsee:

 move.w #25,FourthTimer(a0)

 move.w 12(a0),d2
 move.l ZoneAdds,a5
 move.l (a5,d2.w*4),d0
 add.l LEVELDATA,d0
 move.l d0,objroom

 bsr ViewpointToDraw

 asl.l #2,d0
 add.w alframe+2,d0
 add.l #$00100000,d0
 move.l d0,8(a0)

 move.w 4(a0),d0
 sub.w #64,d0
 ext.l d0
 asl.l #7,d0
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
 movem.l d0/a0/a1/a3/a4/d7,-(a7)
 jsr GoInDirection
 move.w #%1000000000,wallflags
 
 move.l #%11111111110111100001,CollideFlags
 bsr Collision
 tst.b hitwall
 beq.s .canmove
 
 move.w oldx,newx
 move.w oldz,newz
 movem.l (a7)+,d0/a0/a1/a3/a4/d7
 bra .hitathing
 
.canmove:
 
 clr.b wallbounce
 jsr MoveObject
 movem.l (a7)+,d0/a0/a1/a3/a4/d7
 move.b StoodInTop,ObjInTop(a0)

.hitathing:

 tst.b hitwall
 beq.s .nochangedir
 move.w #-1,ObjTimer(a0)
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
 tst.b ObjInTop(a0)
 beq.s .notintop
 move.l ToUpperFloor(a2),d0
.notintop:
 asr.l #7,d0
 sub.w #64,d0
 move.w d0,4(a0)


 moveq #0,d2
 move.b damagetaken(a0),d2
 beq .noscream
 
 sub.b d2,numlives(a0)
 bgt .notdeadyet

 cmp.b #1,d2
 ble .noexplode

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
 asr.w #2,d2
 tst.w d2
 bgt.s .ko
 moveq #1,d2
.ko:
 move.w #31,d3
 jsr ExplodeIntoBits
 movem.l (a7)+,d0-d7/a0-a6
 
 cmp.b #40,d2
 blt .noexplode
 
 move.w #-1,12(a0)
 move.w 12(a0),GraphicRoom(a0)
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
 
 move.w #25,ThirdTimer(a0)
 
 move.w 12(a0),GraphicRoom(a0)
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
 and.w #8190,d0
 move.w d0,Facing(a0)
 move.w #50,ObjTimer(a0)
 
.keepsamedir:

 move.w TempFrames,d0
 sub.w d0,SecTimer(a0)
 bge.s .nohiss

 jsr GetRand
 lsr.w #6,d0
 and.w #1,d0
 add.w #17,d0
 movem.l d0-d7/a0-a6,-(a7)
 sub.l ObjectPoints,a1
 add.l #ObjRotated,a1
 move.l (a1),Noisex
 move.w #100,Noisevol
 move.w d0,Samplenum
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


 move.w 12(a0),GraphicRoom(a0)
 rts
 
ToughMarineAttack:

 move.w 12(a0),d2
 move.l ZoneAdds,a5
 move.l (a5,d2.w*4),d0
 add.l LEVELDATA,d0
 move.l d0,objroom
 bsr ViewpointToDraw
 asl.l #2,d0
 add.w alframe+2,d0
 add.l #$00100000,d0
 move.l d0,8(a0)
 
 btst #0,17(a0)
 beq ToughMarineAttackPLR2
 btst #1,17(a0)
 beq ToughMarineAttackPLR1

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
 ble ToughMarineAttackPLR2
 
 
ToughMarineAttackPLR1:

 
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

 bsr ViewpointToDraw

 asl.l #2,d0
 add.l #$100000,d0
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
 move.w #80,Range
 move.w 4(a0),d0
 ext.l d0
 asl.l #7,d0
 sub.l #64*128,d0
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
 tst.b ObjInTop(a0)
 beq.s .notintop
 move.l ToUpperFloor(a2),d0
.notintop:
 asr.l #7,d0
 sub.w #64,d0
 move.w d0,4(a0)


 moveq #0,d2
 move.b damagetaken(a0),d2
 beq .noscream
 
 sub.b d2,numlives(a0)
 bgt .notdeadyet

 cmp.b #1,d2
 ble .noexplode

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
 asr.w #2,d2
 tst.w d2
 bgt.s .ko
 moveq #1,d2
.ko:
 move.w #31,d3
 jsr ExplodeIntoBits
 movem.l (a7)+,d0-d7/a0-a6
 
 cmp.b #40,d2
 blt .noexplode
 
 move.w #-1,12(a0)
 move.w 12(a0),GraphicRoom(a0)
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
 
 move.w #25,ThirdTimer(a0)
 
 move.w 12(a0),GraphicRoom(a0)
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
 
 cmp.w #20,FourthTimer(a0)
 bge .cantshoot

 jsr GetRand
 and.w #31,d0
 add.w #50,d0
 move.w d0,ThirdTimer(a0)
 
 PROTLCHECK a5

 move.w #1,Samplenum
 move.b #6,SHOTTYPE
 move.b #7,SHOTPOWER
 move.w #32,SHOTSPEED
 move.w #4,SHOTSHIFT
 move.w #0,SHOTOFFMULT
 move.b ObjInTop(a0),SHOTINTOP
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


 move.w 12(a0),GraphicRoom(a0)
 rts

*************************************************

ToughMarineAttackPLR2:
 

 
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

 bsr ViewpointToDraw

 asl.l #2,d0
 add.l #$100000,d0
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
 move.w #80,Range
 move.w 4(a0),d0
 ext.l d0
 asl.l #7,d0
 sub.l #64*128,d0
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
 tst.b ObjInTop(a0)
 beq.s .notintop
 move.l ToUpperFloor(a2),d0
.notintop:
 asr.l #7,d0
 sub.w #64,d0
 move.w d0,4(a0)

 move.b damagetaken(a0),d2
 beq .noscream
 
 sub.b d2,numlives(a0)
 bgt .notdeadyet

; cmp.b #1,d2
; ble.s .noexplode

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
 move.w 12(a0),GraphicRoom(a0)
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
 move.l deadframe,8(a0)
 move.w 12(a0),GraphicRoom(a0)
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
 
 cmp.w #20,FourthTimer(a0)
 bge .cantshoot

 jsr GetRand
 and.w #31,d0
 add.w #50,d0
 move.w d0,ThirdTimer(a0)
 

 move.w #1,Samplenum
 move.b #6,SHOTTYPE
 move.b #7,SHOTPOWER
 move.w #32,SHOTSPEED
 move.w #4,SHOTSHIFT
 move.w #0,SHOTOFFMULT
 move.b ObjInTop(a0),SHOTINTOP
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


 move.w 12(a0),GraphicRoom(a0)
 rts


