ItsANasty:

 tst.b NASTY
 bne .yesnas
 move.w #-1,12(a0)
 rts
.yesnas:


 move.w #$1f1f,14(a0)

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
 move.l #80*128,thingheight
 move.l #4,deadframe
 move.w #0,screamsound
 move.w #40,nasheight
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
 beq.s .notintop
 move.l ToUpperFloor(a1),d0
.notintop:
 asr.l #7,d0
 sub.w #64,d0
 move.w d0,4(a0)
 move.w 12(a0),GraphicRoom(a0)
 rts
 
.dyinganim:
 dcb.w 11,33
 dcb.w 15,32


.notdying: 

 tst.b 17(a0)
 beq.s .cantseeplayer
 tst.w ThirdTimer(a0)
 ble NastyAttack
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

 jsr ViewpointToDraw

 asl.l #2,d0
 add.l alframe,d0

 move.l d0,8(a0)

 move.w 4(a0),d0
 sub.w #40,d0
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
 
 move.l #%111111110111100001,CollideFlags
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
 beq.s .notintopp
 move.l ToUpperFloor(a2),d0
.notintopp:
 asr.l #7,d0
 sub.w #40,d0
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
 PROTICHECK a1
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
 
NastyAttack:

 move.w 12(a0),d2
 move.l ZoneAdds,a5
 move.l (a5,d2.w*4),d0
 add.l LEVELDATA,d0
 move.l d0,objroom
 jsr ViewpointToDraw
 asl.l #2,d0
 add.l alframe,d0
 move.l d0,8(a0)
 
 btst #0,17(a0)
 beq NastyAttackPLR2
 btst #1,17(a0)
 beq NastyAttackPLR1

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
 ble NastyAttackPLR2
 
 
NastyAttackPLR1:
 
 move.w 12(a0),FromZone
 bsr CheckTeleport
 tst.b OKTEL
 beq.s .notel
 move.l floortemp,d0
 asr.l #7,d0
 add.w d0,4(a0)
 bra .NoMunch
.notel:
 
 move.w PLR1_xoff,newx
 move.w PLR1_zoff,newz
 move.w PLR1_sinval,tempsin
 move.w PLR1_cosval,tempcos
 move.w p1_xoff,tempx
 move.w p1_zoff,tempz
 jsr RunAround
 
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
 move.w #160,Range
 move.w 4(a0),d0
 ext.l d0
 asl.l #7,d0
 sub.l #40*128,d0
 move.l d0,newy
 move.l d0,oldy

 move.b ObjInTop(a0),StoodInTop
 movem.l d0/a0/a1/a3/a4/d7,-(a7)
 clr.b canshove
 clr.b GotThere
 jsr HeadTowardsAng
 move.w #%1000000000,wallflags
 
 move.l #%100000,CollideFlags
 jsr Collision
 tst.b hitwall
 beq.s .nothitplayer
 
 move.w oldx,newx
 move.w oldz,newz
 st GotThere
 movem.l (a7)+,d0/a0/a1/a3/a4/d7
 bra .hitathing
 
.nothitplayer:

 move.l #%11111111110111000001,CollideFlags
 jsr Collision
 tst.b hitwall
 beq.s .canmove
 
 move.w oldx,newx
 move.w oldz,newz
 movem.l (a7)+,d0/a0/a1/a3/a4/d7
 bra .hitathing
 
.canmove:
 
 clr.b wallbounce
 Jsr MoveObject
 movem.l (a7)+,d0/a0/a1/a3/a4/d7
 move.b StoodInTop,ObjInTop(a0)
 
 move.w AngRet,Facing(a0)
 
.hitathing:
 
 tst.b GotThere 
 beq.s .NoMunch
 tst.w FourthTimer(a0)
 ble.s .OKtomunch
 move.w TempFrames,d0
 sub.w d0,FourthTimer(a0)
 bra.s .NoMunch
.OKtomunch:
 move.w #20,FourthTimer(a0)
 move.l PLR1_Obj,a2
 add.b #2,damagetaken(a2)
 
.NoMunch: 

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
 sub.l #40*128,d0
 asr.l #7,d0
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
 PROTLCHECK a5
 movem.l (a7)+,d0-d7/a0-a6
 
 cmp.b #40,d2
 blt .notgone
 
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
 
.notgone:
 move.b #0,numlives(a0)
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
 move.w #800,Noisevol
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

*************************************************

NastyAttackPLR2:
 
 move.w 12(a0),FromZone
 bsr CheckTeleport
 tst.b OKTEL
 beq.s .notel2
 move.l floortemp,d0
 asr.l #7,d0
 add.w d0,4(a0)
 bra .NoMunch2
.notel2:
 
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
 sub.l #40*128,d0
 move.l d0,newy
 move.l d0,oldy

 move.b ObjInTop(a0),StoodInTop
 movem.l d0/a0/a1/a3/a4/d7,-(a7)
 clr.b canshove
 clr.b GotThere
 jsr HeadTowardsAng
 move.w #%1000000000,wallflags
 
 move.l #%100000,CollideFlags
 jsr Collision
 tst.b hitwall
 beq.s .nothitplayer
 
 move.w oldx,newx
 move.w oldz,newz
 st GotThere
 movem.l (a7)+,d0/a0/a1/a3/a4/d7
 bra .hitathing
 
.nothitplayer:

 move.l #%11111111110111000001,CollideFlags
 jsr Collision
 tst.b hitwall
 beq.s .canmove
 
 move.w oldx,newx
 move.w oldz,newz
 movem.l (a7)+,d0/a0/a1/a3/a4/d7
 bra .hitathing
 
.canmove:
 
 clr.b wallbounce
 Jsr MoveObject
 movem.l (a7)+,d0/a0/a1/a3/a4/d7
 move.b StoodInTop,ObjInTop(a0)
 
 move.w AngRet,Facing(a0)
 
.hitathing:
 
 tst.b GotThere 
 beq.s .NoMunch2
 tst.w FourthTimer(a0)
 ble.s .OKtomunch2
 move.w TempFrames,d0
 sub.w d0,FourthTimer(a0)
 bra.s .NoMunch2
.OKtomunch2:
 move.w #20,FourthTimer(a0)
 move.l PLR2_Obj,a2
 add.b #2,damagetaken(a2)
 
.NoMunch2: 

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
 sub.l #40*128,d0
 asr.l #7,d0
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
 move.w #7,d2
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
 move.w #800,Noisevol
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


