lastx EQU 0
lasty EQU 2
lastzone EQU 4
lastcpt EQU 6
SEENBY equ 8
DAMAGEDONE equ 10
DAMAGETAKEN equ 12

DEFAULTMODE: dc.w 0
RESPONSEMODE: dc.w 0
FOLLOWUPMODE: dc.w 0
RETREATMODE: dc.w 0
CURRENTMODE: dc.w 0
prowlspeed: dc.w 0
responsespeed: dc.w 0
retreatspeed: dc.w 0
followupspeed: dc.w 0
FOLLOWUPTIMER: dc.w 0
REACTIONTIME: dc.w 0
MIDDLECPT: dc.w 0
VECOBJ: dc.w 0

PLAYERONENOISEVOL: dc.w 0
PLAYERTWONOISEVOL: dc.w 0

AIROUTINE:

 move.w #-20,2(a0)

; bsr CHECKDAMAGE
; tst.b numlives(a0)
; bgt.s .notdeadyet
; rts
;.notdeadyet:

 cmp.b #1,currentmode(a0)
 blt DODEFAULT
 beq DORESPONSE

 cmp.b #3,currentmode(a0)
 blt DOFOLLOWUP
 beq DORETREAT
 
 cmp.b #5,currentmode(a0)
 beq DODIE

DOTAKEDAMAGE:

 jsr WALKANIM
 move.w 4(a0),-(a7)
 bsr GETROOMSTATSSTILL

 move.w (a7)+,d0
 cmp.w #1,DEFAULTMODE
 blt .notflying

 move.w d0,4(a0)
.notflying

 tst.b FINISHEDANIM
 beq.s stillhurting
 move.b #0,currentmode(a0)
 move.b #0,WhichAnim(a0)
 move.w #0,SecTimer(a0)

stillhurting:

 bsr DOTORCH
 
 tst.w 12-64(a0)
 blt.s .nocopyin
 move.w 12(a0),12-64(a0)
 move.w GraphicRoom(a0),GraphicRoom-64(a0)
.nocopyin:

 movem.l d0-d7/a0-a6,-(a7)
 move.w PLR1_xoff,newx
 move.w PLR1_zoff,newz
 move.w (a0),d1
 move.l ObjectPoints,a1
 lea (a1,d1.w*8),a1
 move.w (a1),oldx
 move.w 4(a1),oldz
 move.w #-20,Range
 move.w #20,speed
 jsr HeadTowardsAng
 move.w AngRet,d0
 add.w ANIMFACING,d0
 move.w d0,Facing(a0)
 movem.l (a7)+,d0-d7/a0-a6

 rts
 
DODIE:
 jsr WALKANIM
 bsr GETROOMSTATSSTILL
 tst.b FINISHEDANIM
 beq.s stilldying
 move.w #-1,12(a0)
 move.w #-1,GraphicRoom(a0)
 move.b #0,16(a0)
 clr.b worry(a0)
 st getout
stilldying:
 move.b #0,numlives(a0)
 tst.w 12-64(a0)
 blt.s .nocopyin
 move.w 12(a0),12-64(a0)
 move.w GraphicRoom(a0),GraphicRoom-64(a0)
.nocopyin:


 rts

TAKEDAMAGE:

 clr.b getout
 moveq #0,d0
 move.b damagetaken(a0),d0
 move.l DAMAGEPTR,a2
 add.w d0,(a2)
 move.w (a2),d0
 
 asr.w #2,d0	; divide by 4
 
 moveq #0,d1
 move.b numlives(a0),d1

 move.b #0,damagetaken(a0)
 cmp.w d0,d1
 ble JUSTDIED
 move.w #0,ObjTimer(a0)
 move.w #0,SecTimer(a0)

 jsr GetRand
 and.w #3,d0
 beq.s .dodododo
 
 move.l WORKPTR,a5
 st 1(a5)
 
 move.b #1,currentmode(a0)
 move.w #0,SecTimer(a0)
 move.w #0,ObjTimer(a0)
 move.b #1,WhichAnim(a0)
 
 move.w (a0),d0
 move.l ObjectPoints,a1
 move.w (a1,d0.w*8),oldx
 move.w 4(a1,d0.w*8),oldz
 move.w PLR1_xoff,newx
 move.w PLR1_zoff,newz
 
 move.w #100,speed
 move.w #-20,Range
 jsr HeadTowardsAng
 move.w AngRet,Facing(a0)
 
 st getout
 
 rts
.dodododo

; asr.w #2,d2
; cmp.w d0,d2
; bgt.s .nostop
 
 move.b #4,currentmode(a0)	; do take damage.
 move.b #2,WhichAnim(a0)	; get hit anim.
 move.l WORKPTR,a5
 st 1(a5)

 st getout
 rts
.nostop:
 rts 
 
getout: dc.w 0
 
JUSTDIED:

 move.b #0,numlives(a0)

 move.w TextToShow(a0),d0
 blt.s .notext
 
 muls #160,d0
 add.l LEVELDATA,d0
 jsr SENDMESSAGE
; move.w #0,SCROLLXPOS
; move.l d0,SCROLLPOINTER
; add.l #160,d0
; move.l d0,ENDSCROLL
; move.w #40,SCROLLTIMER
 
.notext:


 move.l ObjectPoints,a2
 move.w (a0),d3
 move.w (a2,d3.w*8),newx
 move.w 4(a2,d3.w*8),newz

 moveq #0,d0
 move.b TypeOfThing(a0),d0
 muls #AlienStatLen,d0
 move.l LINKFILE,a2
 lea AlienStats(a2),a2
 add.l d0,a2
 
 move.b A_TypeOfSplat+1(a2),d0
 move.b d0,TypeOfSplat
 cmp.b #20,d0
 blt gosplutch

 sub.b #20,TypeOfSplat
 sub.b #20,d0
 ext.w d0
 
 move.l LINKFILE,a2
 add.l #AlienStats,a2
 muls #AlienStatLen,d0
 add.l d0,a2
 move.l a2,a4

* Spawn some smaller aliens...
 
 move.w #2,d7	; number to do.

 move.l OtherNastyData,a2
 add.l #64,a2
 
 move.l ObjectPoints,a1
 move.w (a0),d1
 move.l (a1,d1.w*8),d0
 move.l 4(a1,d1.w*8),d1
 move.w #9,d3
 
spawny:
 
.findonefree
 move.w 12(a2),d2
 blt.s .foundonefree
 tst.b numlives(a2)
 beq.s .foundonefree
 
 adda.w #128,a2
 dbra d3,.findonefree
 bra .cantshoot

.foundonefree

 move.b A_HitPoints+1(a4),numlives(a2)
 move.b TypeOfSplat,TypeOfThing(a2)
 move.b #-1,TextToShow(a2)
 move.b #0,16(a2)
 move.w (a2),d4
 move.l d0,(a1,d4.w*8)
 move.l d1,4(a1,d4.w*8)
 move.w 4(a0),4(a2)
 move.w 12(a0),12(a2)
 move.w 12(a0),GraphicRoom(a2)
 move.w #-1,12-64(a2)
 move.w CurrCPt(a0),CurrCPt(a2)
 move.w CurrCPt(a0),TargCPt(a2)
 move.b #-1,teamnumber(a2)
 move.w Facing(a0),Facing(a2)
 move.b #0,currentmode(a2)
 move.b #0,WhichAnim(a2)
 move.w #0,SecTimer(a2)
 move.b #0,damagetaken(a2)
 move.w #0,ObjTimer(a2)
 move.w #0,ImpactX(a2)
 move.w #0,ImpactZ(a2)
 move.w #0,ImpactY(a2)
 move.b A_HitPoints+1(a4),18(a2)
 move.b #0,19(a2)
 move.l DoorsHeld(a0),DoorsHeld(a2)
 move.b ObjInTop(a0),ObjInTop(a2)
 move.b #3,16-64(a2)

 dbra d7,spawny
.cantshoot
 
 bra spawned
 
gosplutch:

 move.w #8,d2
 jsr ExplodeIntoBits

spawned:
 move.b #5,currentmode(a0)
 move.b #3,WhichAnim(a0)
 move.w #0,SecTimer(a0)
 move.l WORKPTR,a5
 st 1(a5)
 st getout
 rts
 
DORETREAT

 rts

DODEFAULT:

 cmp.w #1,DEFAULTMODE
 blt PROWLRANDOM
 beq PROWLRANDOMFLYING

 rts

DORESPONSE:

 cmp.w #1,RESPONSEMODE
 blt CHARGE
 beq CHARGETOSIDE
 
 cmp.w #3,RESPONSEMODE
 blt ATTACKWITHGUN
 beq CHARGEFLYING
 
 cmp.w #5,RESPONSEMODE
 blt CHARGETOSIDEFLYING
 beq ATTACKWITHGUNFLYING

 rts
 
DOFOLLOWUP:
 cmp.w #1,FOLLOWUPMODE
 blt PAUSEBRIEFLY
 beq APPROACH

 cmp.w #3,FOLLOWUPMODE
 blt APPROACHTOSIDE
 beq APPROACHFLYING
 
 cmp.w #5,FOLLOWUPMODE
 blt APPROACHTOSIDEFLYING

 rts
 
***************************************************
*** DEFAULT MOVEMENTS *****************************
***************************************************
 
; Need a FLYING prowl routine

FLYABIT: dc.w 0

PROWLRANDOMFLYING:

 move.l #1000*256,StepDownVal

 st FLYABIT
 bra PROWLFLY
 
PROWLRANDOM:

 clr.b FLYABIT
 move.l #30*256,StepDownVal

PROWLFLY:

 move.l #20*256,StepUpVal

 tst.b damagetaken(a0)
 beq.s .nodamage
 
 bsr TAKEDAMAGE
 tst.b getout
 beq.s .nodamage
 rts
 
.nodamage:

 jsr WALKANIM

 move.l BOREDOMPTR,a1

 move.w 2(a1),d1
 move.w 4(a1),d2
 
 move.l ObjectPoints,a2
 move.w (a0),d3
 move.w 4(a2,d3.w*8),d4
 move.w (a2,d3.w*8),d3
 
 move.w d3,d5
 move.w d4,d6
 
 sub.w d1,d3
 bge.s .okp1
 neg.w d3
.okp1:

 sub.w d2,d4
 bge.s .okp2
 neg.w d4
.okp2

 add.w d3,d4	; dist away
 
 cmp.w #50,d4
 blt.s .NONEWSTORE
 
 move.w d5,2(a1)
 move.w d6,4(a1)
 move.w #100,(a1)
 bra .NEWSTORE
 
.NONEWSTORE

 sub.w #1,(a1)
 bgt.s .NEWSTORE

 bsr GETROOMCPT

 jsr GetRand
 moveq #0,d1
 move.w d0,d1
 divs.w NumCPts,d1
 swap d1
 move.w #7,d7
 
.tryagain:
 move.w d1,TargCPt(a0)
 move.w CurrCPt(a0),d0
 jsr GetNextCPt
 cmp.w CurrCPt(a0),d0
 beq.s .plusagain
 cmp.b #$7f,d0
 bne.s .okaway2
.plusagain:
 move.w TargCPt(a0),d1
 add.w #1,d1
 cmp.w NumCPts,d1
 blt .nobin
 moveq #0,d1
.nobin
 dbra d7,.tryagain
.okaway2

 move.w #50,(a1)

.NEWSTORE

WIDGET:
 
 tst.w PLAYERONENOISEVOL
 beq.s .noplayernoise

 move.l PLR1_Roompt,a1
 tst.b PLR1_StoodInTop
 beq.s .pnotintop
 
 addq #1,a1
 
.pnotintop:
 
 moveq #0,d1
 move.b ToZoneCpt(a1),d1
 
 move.w CurrCPt(a0),d0
 jsr GetNextCPt
 
 cmp.b #$7f,d0
 bne.s .okaway
 move.w CurrCPt(a0),d0
.okaway

 move.w d0,TargCPt(a0)

.noplayernoise:

 moveq #0,d0
 move.b teamnumber(a0),d0
 blt.s .noteam

 lea TEAMWORK(pc),a2
 asl.w #4,d0
 add.w d0,a2
 tst.w SEENBY(a2)
 blt.s .noteam
 move.w (a0),d0
 cmp.w SEENBY(a2),d0
 bne.s .noremove
 move.w #-1,SEENBY(a2)
 bra.s .noteam
.noremove:

 asl.w #4,d0
 lea NASTYWORK(pc),a1
 add.w d0,a1
 move.w #0,DAMAGEDONE(a1)
 move.w #0,DAMAGETAKEN(a1)
 move.l (a2),(a1)
 move.l 4(a2),4(a1)
 move.l 8(a2),8(a1)
 move.l 12(a2),12(a1)
 move.w lastcpt(a1),TargCPt(a0)
 move.w #-1,lastzone(a1)
 bra.s .notseen

.noteam:

 move.w (a0),d0
 asl.w #4,d0
 lea NASTYWORK(pc),a1
 add.w d0,a1
 move.w #0,DAMAGEDONE(a1)
 move.w #0,DAMAGETAKEN(a1)
 tst.w lastzone(a1)
 blt.s .notseen
 move.w lastcpt(a1),TargCPt(a0)
 move.w #-1,lastzone(a1)
.notseen:


 move.w CurrCPt(a0),d0	; where the alien is now.
 move.w TargCPt(a0),d1
 jsr GetNextCPt
 cmp.b #$7f,d0
 beq.s .yesrand
 tst.b FLYABIT
 bne.s .norand
 tst.b ONLYSEE
 beq.s .norand
.yesrand
 jsr GetRand
 moveq #0,d1
 move.w d0,d1
 divs.w NumCPts,d1
 swap d1
 move.w #7,d7
 
.tryagain:
 move.w d1,TargCPt(a0)
 move.w CurrCPt(a0),d0
 jsr GetNextCPt
 cmp.w CurrCPt(a0),d0
 beq.s .plusagain
 cmp.b #$7f,d0
 bne.s .okaway2
.plusagain:
 move.w TargCPt(a0),d1
 add.w #1,d1
 cmp.w NumCPts,d1
 blt .nobin
 moveq #0,d1
.nobin
 dbra d7,.tryagain
.okaway2

 
.norand: 

 
 move.w d0,MIDDLECPT

 move.l CPtPos,a1
 move.w (a1,d0.w*8),newx
 move.w 2(a1,d0.w*8),newz
 
 asl.w #2,d0
 add.w (a0),d0
 muls #$1347,d0
 and.w #4095,d0
 move.l #SineTable,a1
 move.w (a1,d0.w*2),d1
 move.l #SineTable+2048,a1
 move.w (a1,d0.w*2),d2
 ext.l d1
 ext.l d2
 asl.l #4,d2
 swap d2
 asl.l #4,d1
 swap d1
 add.w d1,newx
 add.w d2,newz

 move.w (a0),d1
 move.l #ObjRotated,a6
 move.l ObjectPoints,a1
 lea (a1,d1.w*8),a1
 lea (a6,d1.w*8),a6
 move.w (a1),oldx
 move.w 4(a1),oldz
 move.w #0,speed
 tst.b DoAction
 beq.s .nospeed
 moveq #0,d2
 move.b DoAction,d2
 asl.w #2,d2
 
 muls.w prowlspeed,d2
 move.w d2,speed
.nospeed:
 move.w #40,Range
 move.w 4(a0),d0
 ext.l d0
 asl.l #7,d0
 move.l thingheight,d2
 asr.l #1,d2
 sub.l d2,d0
 move.l d0,newy
 move.l d0,oldy

 move.b ObjInTop(a0),StoodInTop
 movem.l d0/a0/a1/a3/a4/d7,-(a7)
 clr.b canshove
 clr.b GotThere
 jsr HeadTowardsAng
 move.w AngRet,Facing(a0)
 
; add.w #100,Facing(a0)
; and.w #8190,Facing(a0)
 
 tst.b GotThere
 beq.s .notnextcpt
 
 move.w MIDDLECPT,d0
 move.w d0,CurrCPt(a0)
 cmp.w TargCPt(a0),d0
 bne .notnextcpt

* We have arrived at the target contol pt. Pick a
* random one and go to that...

 jsr GetRand
 moveq #0,d1
 move.w d0,d1
 divs.w NumCPts,d1
 swap d1
 move.w d1,TargCPt(a0)
 
.notnextcpt:
 
 move.w #%1000000000,wallflags
 move.l #%00001000110010000010,CollideFlags
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
 
 
.hitathing:
 tst.w 12-64(a0)
 blt.s .nocopyin
 move.w 12(a0),12-64(a0)
 move.w GraphicRoom(a0),GraphicRoom-64(a0)
.nocopyin:

 move.w 4(a0),-(a7)
 bsr GETROOMSTATS
 move.w (a7)+,d0

 tst.b FLYABIT
 beq.s .noflymove
 move.w d0,4(a0)
 bsr FLYTOCPTHEIGHT
.noflymove:

 bsr DOTORCH
 
 move.b #0,currentmode(a0)
 bsr LOOKFORPLAYER1
 move.b #0,WhichAnim(a0)
 tst.b 17(a0)
 beq.s .nosee
 bsr CHECKINFRONT
 tst.b d0
 beq.s .nosee
 
 move.w TempFrames,d0
 sub.w d0,ObjTimer(a0)
 bgt.s .notreacted
 bsr CHECKFORDARK
 tst.b d0
 beq.s .nosee
 
; We have seen the player and reacted; can we attack him?

 tst.b FLYABIT
 bne.s .yesattack

 cmp.w #2,RESPONSEMODE
 beq.s .yesattack
 cmp.w #5,RESPONSEMODE
 beq.s .yesattack

 bsr CHECKATTACKONGROUND
 tst.b d0
 bne.s .yesattack
 
; We can see the player

 bsr STOREPLAYERPOS
 
; but we can't get to him
 bra.s .nosee
 
.yesattack:
 move.w #0,SecTimer(a0)
 move.b #1,currentmode(a0)
 move.b #1,WhichAnim(a0)
.notreacted:
 move.w ANIMFACING,d0
 add.w d0,Facing(a0)
 rts
.nosee:
 move.w REACTIONTIME,ObjTimer(a0)

 move.w ANIMFACING,d0
 add.w d0,Facing(a0)

 rts

***********************************************
** RESPONSE MOVEMENTS *************************
***********************************************

CHARGETOSIDE:
 clr.b FLYABIT
 st TOSIDE
 move.l #30*256,StepDownVal
 bra INTOCHA

CHARGE:
 clr.b FLYABIT
 clr.b TOSIDE
 move.l #30*256,StepDownVal

INTOCHA:

 tst.b damagetaken(a0)
 beq.s .nodamage
 
 bsr TAKEDAMAGE
 tst.b getout
 beq.s .nodamage
 rts
 
.nodamage:

 jsr ATTACKANIM
; tst.b FINISHEDANIM
; beq.s .notfinishedattacking
; move.b #2,currentmode(a0)
; move.w FOLLOWUPTIMER,ObjTimer(a0)
; move.w #0,SecTimer(a0)
; rts
;.notfinishedattacking:

 move.w 12(a0),FromZone
 jsr CheckTeleport
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
 tst.b TOSIDE
 beq.s .noside
 jsr RunAround
.noside:

 
 move.w (a0),d1
 move.l #ObjRotated,a6
 move.l ObjectPoints,a1
 lea (a1,d1.w*8),a1
 lea (a6,d1.w*8),a6
 move.w (a1),oldx
 move.w 4(a1),oldz
 move.w responsespeed,d2
 muls.w TempFrames,d2
 move.w d2,speed
 move.w #160,Range
 move.w 4(a0),d0
 ext.l d0
 asl.l #7,d0
 move.l thingheight,d2
 asr.l #1,d2
 sub.l d2,d0
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

 move.l #%11111111110111000010,CollideFlags
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
 tst.w 12-64(a0)
 blt.s .nocopyin
 move.w 12(a0),12-64(a0)
 move.w GraphicRoom(a0),GraphicRoom-64(a0)
.nocopyin:
 
 tst.b GotThere 
 beq.s .NoMunch
 tst.b DoAction
 beq.s .NoMunch
 move.l PLR1_Obj,a5
 move.b DoAction,d0
 asl.w #1,d0
 add.b d0,damagetaken(a5)
 
 move.w newx,d0
 sub.w oldx,d0
 ext.l d0
 divs TempFrames,d0
 add.w d0,ImpactX(a5)
 move.w newz,d0
 sub.w oldz,d0
 ext.l d0
 divs TempFrames,d0
 add.w d0,ImpactZ(a5)
 
.NoMunch: 

 bsr STOREPLAYERPOS

 bsr GETROOMSTATS

 bsr GETROOMCPT 
 
 bsr DOTORCH

 bsr LOOKFORPLAYER1
 move.b #0,currentmode(a0)
 tst.b 17(a0)
 beq.s .nosee
 bsr CHECKINFRONT
 tst.b d0
 beq.s .nosee
 tst.b FLYABIT
 bne.s .yesattack

 bsr CHECKATTACKONGROUND
 tst.b d0
 bne.s .yesattack
 
 bra.s .nosee
 
.yesattack
 move.w ANIMFACING,d0
 add.w d0,Facing(a0)
 move.b #1,currentmode(a0)
 move.b #1,WhichAnim(a0)
 rts
.nosee:
 move.b #0,WhichAnim(a0)
 move.w #0,SecTimer(a0)
 move.w ANIMFACING,d0
 add.w d0,Facing(a0)
 rts


ATTACKWITHGUNFLYING
 st FLYABIT
 bra intoatt

ATTACKWITHGUN:
 clr.b FLYABIT
intoatt:



 move.l LINKFILE,a1
 lea AlienStats(a1),a1
 moveq #0,d0
 move.b TypeOfThing(a0),d0
 muls #AlienStatLen,d0
 add.w d0,a1
 move.w A_BulletType(a1),d0
 move.b d0,SHOTTYPE 
 
 move.l LINKFILE,a1
 lea BulletAnimData(a1),a1
 muls #B_BulStatLen,d0
 add.l d0,a1

 move.l B_DamageToTarget(a1),d0
 move.b d0,SHOTPOWER
 clr.l d1
 move.l B_MovementSpeed(a1),d0
 bset d0,d1
 move.w d1,SHOTSPEED
 sub.w #1,d0
 move.w d0,SHOTSHIFT

 
 tst.l B_VisibleOrInstant(a1)
 beq ATTACKWITHBULLETGUN
 
ATTACKWITHINSTANTGUN:

 tst.b damagetaken(a0)
 beq.s .nodamage
 
 move.b #4,currentmode(a0)
 bsr TAKEDAMAGE
 tst.b getout
 beq.s .nodamage
; move.w ANIMFACING,d0
; add.w d0,Facing(a0)
 rts
 
.nodamage:

 jsr ATTACKANIM

 movem.l d0-d7/a0-a6,-(a7)
 move.w PLR1_xoff,newx
 move.w PLR1_zoff,newz
 move.w (a0),d1
 move.l ObjectPoints,a1
 lea (a1,d1.w*8),a1
 move.w (a1),oldx
 move.w 4(a1),oldz
 move.w #-20,Range
 move.w #20,speed
 jsr HeadTowardsAng
 move.w AngRet,Facing(a0)
 movem.l (a7)+,d0-d7/a0-a6


 bsr STOREPLAYERPOS

 bsr LOOKFORPLAYER1
 move.b #0,currentmode(a0)
 tst.b 17(a0)
 beq.s .nosee
 bsr CHECKINFRONT
 tst.b d0
 beq.s .nosee

 move.b #1,currentmode(a0)
 move.b #1,WhichAnim(a0)
 move.w ANIMFACING,d0
 add.w d0,Facing(a0)
 bra .yessee
.nosee:
 move.b #0,WhichAnim(a0)
 move.w #0,SecTimer(a0)
 move.w FOLLOWUPTIMER,ObjTimer(a0)
 move.w #0,SecTimer(a0)
 move.w ANIMFACING,d0
 add.w d0,Facing(a0)
 rts

.yessee:
 
 tst.b DoAction
 beq .noshootythang
 
 move.w (a0),d1
 move.l #ObjRotated,a6
 move.l ObjectPoints,a1
 lea (a1,d1.w*8),a1
 lea (a6,d1.w*8),a6

 movem.l a0/a1,-(a7)
 jsr GetRand
 
 move.l #ObjRotated,a6
 move.w (a0),d1
 lea (a6,d1.w*8),a6

; move.l (a6),Noisex
; move.w #200,Noisevol
; move.w #3,Samplenum
; move.b #1,chanpick
; clr.b notifplaying
; movem.l d0-d7/a0-a6,-(a7)
; move.b 1(a0),IDNUM
; jsr MakeSomeNoise
; movem.l (a7)+,d0-d7/a0-a6
 
 and.w #$7fff,d0
 move.w (a6),d1
 muls d1,d1
 move.w 2(a6),d2
 muls d2,d2
 add.l d2,d1
 asr.l #6,d1
 ext.l d0
 asl.l #2,d0
 cmp.l d1,d0
 bgt.s .hitplr
 jsr SHOOTPLAYER1
 bra.s .missplr
.hitplr: 
 move.l PLR1_Obj,a1
 move.b SHOTPOWER,d0
 add.b d0,damagetaken(a1)
 
 sub.l #ObjRotated,a6
 add.l ObjectPoints,a6
 move.w (a6),d0
 sub.w p1_xoff,d0	;dx
 move.w 4(a6),d1
 sub.w p1_zoff,d1	;dz

 move.w d0,d2
 move.w d1,d3
 muls d2,d2
 muls d3,d3
 add.l d3,d2
 jsr CALCSQROOT
 add.l d2,d2
 
 moveq #0,d3
 move.b SHOTPOWER,d3

 
 muls d3,d0
 divs d2,d0
 muls d3,d1
 divs d2,d1
 
 sub.w d0,ImpactX(a1)
 sub.w d1,ImpactZ(a1)
 
.missplr:
 movem.l (a7)+,a0/a1
 

.noshootythang:

 move.w (a0),d1
 move.l ObjectPoints,a1
 lea (a1,d1.w*8),a1
 
 move.w (a1),newx
 move.w 4(a1),newz
 
 bsr DOTORCH

 tst.b FINISHEDANIM
 beq.s .notfinishedattacking
 move.b #0,WhichAnim(a0)
 move.b #2,currentmode(a0)
 move.w FOLLOWUPTIMER,ObjTimer(a0)
 move.w #0,SecTimer(a0)
 move.w ANIMFACING,d0
 add.w d0,Facing(a0)
 rts
.notfinishedattacking:

 rts
 
ATTACKWITHBULLETGUN:

 tst.b damagetaken(a0)
 beq.s .nodamage
 
 move.b #4,currentmode(a0)
 bsr TAKEDAMAGE
 tst.b getout
 beq.s .nodamage
; move.w ANIMFACING,d0
; add.w d0,Facing(a0)
 rts
 
.nodamage:


 jsr ATTACKANIM
 
 movem.l d0-d7/a0-a6,-(a7)
 move.w PLR1_xoff,newx
 move.w PLR1_zoff,newz
 move.w (a0),d1
 move.l ObjectPoints,a1
 lea (a1,d1.w*8),a1
 move.w (a1),oldx
 move.w 4(a1),oldz
 move.w #-20,Range
 move.w #20,speed
 jsr HeadTowardsAng
 move.w AngRet,Facing(a0)
 movem.l (a7)+,d0-d7/a0-a6

 bsr STOREPLAYERPOS
 
 tst.b DoAction
 beq.s .noshootythang
  
 movem.l d0-d7/a0-a6,-(a7)
  
 move.w (a0),d1
 move.l ObjectPoints,a1
 lea (a1,d1.w*8),a1

 move.b ObjInTop(a0),SHOTINTOP

 jsr FireAtPlayer1
 movem.l (a7)+,d0-d7/a0-a6  
.noshootythang:

 move.w (a0),d1
 move.l ObjectPoints,a1
 lea (a1,d1.w*8),a1
 
 move.w (a1),newx
 move.w 4(a1),newz
 
 bsr DOTORCH


 tst.b FINISHEDANIM
 beq.s .notfinishedattacking
 move.b #0,WhichAnim(a0)
 move.b #2,currentmode(a0)
 move.w FOLLOWUPTIMER,ObjTimer(a0)
 move.w #0,SecTimer(a0)
 move.w ANIMFACING,d0
 add.w d0,Facing(a0)
 rts
.notfinishedattacking:

 bsr LOOKFORPLAYER1
 move.b #0,currentmode(a0)
 tst.b 17(a0)
 beq.s .nosee
 bsr CHECKINFRONT
 tst.b d0
 beq.s .nosee
 move.b #1,WhichAnim(a0)
 move.b #1,currentmode(a0)
 move.w ANIMFACING,d0
 add.w d0,Facing(a0)
 rts
.nosee:
 move.b #0,WhichAnim(a0)
 move.w #0,SecTimer(a0)
 move.w FOLLOWUPTIMER,ObjTimer(a0)
 move.w #0,SecTimer(a0)
 move.w ANIMFACING,d0
 add.w d0,Facing(a0)
 rts
 
CHARGETOSIDEFLYING:
 st FLYABIT
 st TOSIDE
 move.l #1000*256,StepDownVal
 bra INTOCHAFLY
 
CHARGEFLYING: 
 clr.b TOSIDE
 st FLYABIT

 move.l #1000*256,StepDownVal

INTOCHAFLY:

 tst.b damagetaken(a0)
 beq.s .nodamage
 
 bsr TAKEDAMAGE
 tst.b getout
 beq.s .nodamage
; move.w ANIMFACING,d0
; add.w d0,Facing(a0)
 rts
 
.nodamage:


 jsr ATTACKANIM
; tst.b FINISHEDANIM
; beq.s .notfinishedattacking
; move.b #2,currentmode(a0)
; move.w FOLLOWUPTIMER,ObjTimer(a0)
; move.w #0,SecTimer(a0)
; rts
;.notfinishedattacking:

 move.w 12(a0),FromZone
 jsr CheckTeleport
 tst.b OKTEL
 beq.s .notel
 move.l floortemp,d0
 asr.l #7,d0
 add.w d0,4(a0)
 bra .NoMunch
.notel:
 
 move.w (a0),d1
 move.l #ObjRotated,a6
 move.l ObjectPoints,a1
 lea (a1,d1.w*8),a1
 lea (a6,d1.w*8),a6
 move.w (a1),oldx
 move.w 4(a1),oldz
 move.w PLR1_xoff,newx
 move.w PLR1_zoff,newz
 move.w PLR1_sinval,tempsin
 move.w PLR1_cosval,tempcos
 move.w p1_xoff,tempx
 move.w p1_zoff,tempz
 tst.b TOSIDE
 beq.s .noside
 jsr RunAround
.noside:
 
 move.w responsespeed,d2
 muls.w TempFrames,d2
 move.w d2,speed
 move.w #160,Range
 move.w 4(a0),d0
 ext.l d0
 asl.l #7,d0
 move.l thingheight,d2
 asr.l #1,d2
 sub.l d2,d0
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

 move.l #%11111111110111000010,CollideFlags
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
 tst.b DoAction
 beq.s .NoMunch
 move.l PLR1_Obj,a5
 move.b DoAction,d0
 asl.w #1,d0
 add.b d0,damagetaken(a5)
.NoMunch: 

 bsr STOREPLAYERPOS

 move.w 4(a0),-(a7)
 bsr GETROOMSTATS
 move.w (a7)+,4(a0)

 bsr GETROOMCPT

 bsr FLYTOPLAYERHEIGHT

 bsr DOTORCH
 
 bsr LOOKFORPLAYER1
 move.b #0,currentmode(a0)
 tst.b 17(a0)
 beq.s .nosee
 bsr CHECKINFRONT
 tst.b d0
 beq.s .nosee
 move.b #1,currentmode(a0)
 move.b #1,WhichAnim(a0)
 move.w ANIMFACING,d0
 add.w d0,Facing(a0)
 rts
.nosee:
 move.b #0,WhichAnim(a0)
 move.w #0,SecTimer(a0)
 move.w ANIMFACING,d0
 add.w d0,Facing(a0)
 rts
 
 
***********************************************
** Retreat Movements **************************
***********************************************

***********************************************
** Followup Movements *************************
***********************************************
 
PAUSEBRIEFLY

 tst.b damagetaken(a0)
 beq.s .nodamage
 
 bsr TAKEDAMAGE
 tst.b getout
 beq.s .nodamage
; move.w ANIMFACING,d0
; add.w d0,Facing(a0)
 rts
 
.nodamage:

 move.w #0,SecTimer(a0)
 jsr WALKANIM

 move.w TempFrames,d0
 sub.w d0,ObjTimer(a0)
 bgt.s .stillwaiting

 move.w (a0),d1
 move.l ObjectPoints,a1
 lea (a1,d1.w*8),a1
 
 move.w (a1),newx
 move.w 4(a1),newz
 
 bsr DOTORCH
 
 bsr LOOKFORPLAYER1
 move.b #0,currentmode(a0)
 tst.b 17(a0)
 beq.s .nosee
 bsr CHECKINFRONT
 tst.b d0
 beq.s .nosee
 bsr CHECKFORDARK
 tst.b d0
 beq.s .nosee
 move.b #1,WhichAnim(a0)
 move.b #1,currentmode(a0)
 move.w ANIMFACING,d0
 add.w d0,Facing(a0)
 rts
.nosee:
 move.b #0,WhichAnim(a0)
 move.w ANIMFACING,d0
 add.w d0,Facing(a0)
 rts
 
.stillwaiting:
 move.w ANIMFACING,d0
 add.w d0,Facing(a0)
 rts
 
TOSIDE: dc.w 0
 
APPROACH:
 clr.b FLYABIT
 move.l #30*256,StepDownVal
 clr.b TOSIDE
 bra INTOAPP

APPROACHFLYING:
 st FLYABIT
 move.l #1000*256,StepDownVal
 clr.b TOSIDE
 bra INTOAPP
 
APPROACHTOSIDEFLYING:
 st FLYABIT
 move.l #1000*256,StepDownVal
 st TOSIDE
 bra INTOAPP
 
APPROACHTOSIDE:
 st TOSIDE
 clr.b FLYABIT
 move.l #30*256,StepDownVal
 
INTOAPP:

 tst.b damagetaken(a0)
 beq.s .nodamage
 
 bsr TAKEDAMAGE
 tst.b getout
 beq.s .nodamage
 rts
 
.nodamage:

 jsr WALKANIM

 move.w 12(a0),FromZone
 jsr CheckTeleport
 tst.b OKTEL
 beq.s .notel
 move.l floortemp,d0
 asr.l #7,d0
 add.w d0,4(a0)
 bra .NoMunch
.notel:

 move.w (a0),d1
 move.l #ObjRotated,a6
 move.l ObjectPoints,a1
 lea (a1,d1.w*8),a1
 lea (a6,d1.w*8),a6
 move.w (a1),oldx
 move.w 4(a1),oldz

 move.w PLR1_xoff,newx
 move.w PLR1_zoff,newz
 move.w PLR1_sinval,tempsin
 move.w PLR1_cosval,tempcos
 move.w p1_xoff,tempx
 move.w p1_zoff,tempz
 tst.b TOSIDE
 beq.s .noside
 jsr RunAround
.noside:
 
 move.w #0,speed
 tst.b DoAction
 beq.s .nospeed
 moveq #0,d2
 move.b DoAction,d2
 asl.w #2,d2
 muls.w followupspeed,d2
 move.w d2,speed
.nospeed:
 move.w #160,Range
 move.w 4(a0),d0
 ext.l d0
 asl.l #7,d0
 move.l thingheight,d2
 asr.l #1,d2
 sub.l d2,d0
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

 move.l #%11111111110111000010,CollideFlags
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

 tst.w 12-64(a0)
 blt.s .nocopyin
 move.w 12(a0),12-64(a0)
 move.w GraphicRoom(a0),GraphicRoom-64(a0)
.nocopyin:
 
; tst.b GotThere 
; beq.s .NoMunch
; tst.w FourthTimer(a0)
; ble.s .OKtomunch
; move.w TempFrames,d0
; sub.w d0,FourthTimer(a0)
; bra.s .NoMunch
;.OKtomunch:
; move.w #40,FourthTimer(a0)
; move.l PLR1_Obj,a5
; add.b #2,damagetaken(a5)
; 
.NoMunch: 

 bsr STOREPLAYERPOS
 
 tst.b FLYABIT
 beq.s .notfl
 
 bsr FLYTOPLAYERHEIGHT
.notfl:

 move.w 4(a0),-(a7)
 bsr GETROOMSTATS
 move.w (a7)+,d0
 tst.b FLYABIT
 beq.s .notflying
 move.w d0,4(a0)
.notflying:
 
 bsr GETROOMCPT

 bsr DOTORCH

 move.b #0,currentmode(a0)
 tst.b FLYABIT
 bne.s .inair
 bsr CHECKATTACKONGROUND
 tst.b d0
 beq .nosee
.inair:
 
 bsr LOOKFORPLAYER1
 tst.b 17(a0)
 beq.s .nosee
 bsr CHECKINFRONT
 tst.b d0
 beq.s .nosee
 move.b #2,currentmode(a0)
 move.w TempFrames,d0
 sub.w d0,ObjTimer(a0)
 bgt.s .nosee
 bsr CHECKFORDARK
 tst.b d0
 beq.s .nosee
 move.b #1,currentmode(a0)
 move.w #0,SecTimer(a0)
 move.b #1,WhichAnim(a0)
 move.w ANIMFACING,d0
 add.w d0,Facing(a0)
 rts
.nosee:
 move.b #0,WhichAnim(a0)
 move.w ANIMFACING,d0
 add.w d0,Facing(a0)
 rts
 
***********************************************
** GENERIC ROUTINES ***************************
***********************************************

FLYTOCPTHEIGHT

 move.w MIDDLECPT,d0
 move.l CPtPos,a1
 move.w 4(a1,d0.w*8),d1

 bra intoflytoheight

FLYTOPLAYERHEIGHT:
 move.l PLR1_yoff,d1
 asr.l #7,d1
 
intoflytoheight:
 move.w 4(a0),d0
 cmp.w d0,d1
 bgt.s .flydown

 move.w objyvel(a0),d2

 sub.w #2,d2
 cmp.w #-32,d2
 bgt.s .nofastup
 move.w #-32,d2
.nofastup

 move.w d2,objyvel(a0)
 add.w d2,4(a0)
 
 bra CHECKFLOORCEILING

.flydown
 move.w objyvel(a0),d2

 add.w #2,d2
 cmp.w #32,d2
 blt.s .nofastdown
 move.w #32,d2
.nofastdown

 move.w d2,objyvel(a0)
 add.w d2,4(a0)

CHECKFLOORCEILING:

 move.w 4(a0),d2
 move.l thingheight,d4
 asr.l #8,d4
 move.w d2,d3
 sub.w d4,d2
 add.w d4,d3
 
 move.l objroom,a2
 
 move.l ToZoneFloor(a2),d0
 move.l ToZoneRoof(a2),d1
 tst.b ObjInTop(a0)
 beq.s .notintop
 move.l ToUpperFloor(a2),d0
 move.l ToUpperRoof(a2),d1
.notintop:
 
 asr.l #7,d0
 asr.l #7,d1
 
 cmp.w d0,d3
 blt.s .botnohit
 move.w d0,d3
 move.w d3,d2
 sub.w d4,d2
 sub.w d4,d2
.botnohit

 cmp.w d1,d2
 bgt.s .topnohit
 move.w d1,d2
 move.w d2,d3
 add.w d4,d3
 add.w d4,d3
.topnohit

 sub.w d4,d3
 move.w d3,4(a0)
 
 rts

STOREPLAYERPOS:
 move.w (a0),d0
 move.l #NASTYWORK,a2
 asl.w #4,d0
 add.w d0,a2
 move.w PLR1_xoff,lastx(a2)
 move.w PLR1_zoff,lasty(a2)
 move.l PLR1_Roompt,a3
 move.w (a3),lastzone(a2)
 
 moveq #0,d0
 move.b ToZoneCpt(a3),d0
 tst.b PLR1_StoodInTop
 beq.s .pnotintop
 move.b ToZoneCpt+1(a3),d0
.pnotintop:
 
 move.w d0,lastcpt(a2)
 
 move.b teamnumber(a0),d0
 blt.s .noteam
 move.l #TEAMWORK,a2
 asl.w #4,d0
 add.w d0,a2
 move.w PLR1_xoff,lastx(a2)
 move.w PLR1_zoff,lasty(a2)
 move.l PLR1_Roompt,a3
 move.w (a3),lastzone(a2)
 moveq #0,d0
 move.b ToZoneCpt(a3),d0
 tst.b PLR1_StoodInTop
 beq.s .pnotintop2
 move.b ToZoneCpt+1(a3),d0
.pnotintop2:
 move.w d0,lastcpt(a2)
 move.w (a0),SEENBY(a2)
 
.noteam:
 rts

GETROOMSTATS:
 
 move.w (a0),d0
 move.l ObjectPoints,a1
 lea (a1,d0.w*8),a1
 move.w newx,(a1)
 move.w newz,4(a1)

GETROOMSTATSSTILL: 
 move.l objroom,a2
 move.w (a2),12(a0)

; move.w (a2),d0
; move.l #ZoneBrightTable,a5
; move.l (a5,d0.w*4),d0
; tst.b ObjInTop(a0)
; bne.s .okbit
; swap d0
;.okbit:
; move.w d0,2(a0)
 
 move.l ToZoneFloor(a2),d0
 tst.b ObjInTop(a0)
 beq.s .notintop2
 move.l ToUpperFloor(a2),d0
.notintop2:
 move.l thingheight,d2
 asr.l #1,d2
 sub.l d2,d0
 asr.l #7,d0
 move.w d0,4(a0)

 move.w 12(a0),GraphicRoom(a0)

 rts

CHECKFORDARK:

 move.w (a0),d0
 move.l PLR1_Roompt,a3
 move.w (a3),d1
 cmp.w d1,d0
 beq.s NOTINDARK

 jsr GetRand
 and.w #31,d0
 cmp.w PLR1_RoomBright,d0
 bge.s NOTINDARK
 
INDARK:
 moveq #0,d0
 rts

NOTINDARK:
 moveq #-1,d0
 rts
 
CHECKINFRONT:

; clr.b 17(a0)
; rts

 move.w (a0),d0
 move.l ObjectPoints,a1
 move.w (a1,d0.w*8),newx
 move.w 4(a1,d0.w*8),newz
 
 move.w p1_xoff,d0
 sub.w newx,d0
 move.w p1_zoff,d1
 sub.w newz,d1
 
 move.w Facing(a0),d2
 and.w #8190,d2
 move.l #SineTable,a3
 move.w (a3,d2.w),d3
 add.l #2048,d2
 move.w (a3,d2.w),d4
 
 muls d3,d0
 muls d4,d1
 add.l d0,d1
 sgt.s d0
 rts
 
ANIMFACING: dc.w 0
 
LOOKFORPLAYER1:
 
 clr.b 17(a0)
 clr.b CanSee
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
 
 
 tst.b CanSee
 beq .carryonprowling

 move.b #1,17(a0)
.carryonprowling:
 rts

CLRNASTYMEM:
 move.l #NASTYWORK,a0
 move.l #299,d0
.lopp
 move.l #0,(a0)
 move.l #-1,4(a0)
 move.l #-1,8(a0)
 add.w #16,a0
 dbra d0,.lopp

 move.l #TEAMWORK,a0
 move.l #29,d0
.lopp2
 move.l #0,(a0)
 move.l #-1,4(a0)
 move.l #-1,8(a0)
 add.w #16,a0
 dbra d0,.lopp2

 rts

CHECKDAMAGE:

 moveq #0,d2
 move.b damagetaken(a0),d2
 beq .noscream
 
 sub.b d2,numlives(a0)
 bgt .notdeadyet
 
 moveq #0,d0
 move.b teamnumber(a0),d0
 blt.s .noteam

 lea TEAMWORK(pc),a2
 asl.w #4,d0
 add.w d0,a2
 move.w (a0),d0
 cmp.w SEENBY(a2),d0
 bne.s .noteam
 move.w #-1,SEENBY(a2)
.noteam

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
 move.w (a0),IDNUM
 move.b ALIENECHO,Echo
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
 move.w (a0),IDNUM
 move.b ALIENECHO,Echo
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
 move.w (a0),IDNUM
 st backbeat
 move.b ALIENECHO,Echo
 jsr MakeSomeNoise
 movem.l (a7)+,d0-d7/a0-a6


.noscream

 rts

 
SPLIBBLE:
 
 move.l ANIMPOINTER,a6
 
 jsr ViewpointToDraw
 add.l d0,d0

 cmp.b #1,VECOBJ
 bne.s .NOSIDES
 moveq #0,d0
 
.NOSIDES:

 muls #A_OptLen,d0
 add.w d0,a6

 move.w SecTimer(a0),d1
 add.w #1,d1
 move.w d1,d2
 muls #A_FrameLen,d1
 tst.b (a6,d1.w)
 bge.s .noendanim
 moveq #0,d2
 moveq #0,d1
.noendanim
 move.w d2,SecTimer(a0)

 move.l #0,8(a0)
 move.b (a6,d1.w),9(a0)
 move.b 1(a6,d1.w),11(a0)

 move.w #-1,6(a0)
 cmp.b #1,VECOBJ
 beq.s .nosize
 move.w 2(a6,d1.w),6(a0)
.nosize

 moveq #0,d0
 move.b 5(a6,d1.w),d0
 beq.s .nosoundmake
 
 movem.l d0-d7/a0-a6,-(a7)
 subq #1,d0
 move.w d0,Samplenum
 clr.b notifplaying
 move.w (a0),IDNUM
 move.w #200,Noisevol
 move.l #ObjRotated,a1
 move.w (a0),d0
 lea (a1,d0.w*8),a1
 move.l (a1),Noisex
 move.b ALIENECHO,Echo
 jsr MakeSomeNoise
 movem.l (a7)+,d0-d7/a0-a6
.nosoundmake

 move.b 6(a6,d1.w),d0
 sne DoAction

 rts


DOTORCH:
 move.w ALIENBRIGHT,d0
 bge.s .nobright
 
 move.w newx,d1
 move.w newz,d2
 move.w 4(a0),d3
 ext.l d3
 asl.l #7,d3
 move.l d3,BRIGHTY
 move.w Facing(a0),d4
 
 move.w 12(a0),d3
 
 jsr BRIGHTENPOINTSANGLE
  
.nobright:
 rts

FOIBLE:
WALKANIM:
ATTACKANIM:
 
 move.l d0,-(a7)
 
 move.l ANIMPOINTER,a6
 
 move.l WORKPTR,a5

 moveq #0,d1
 move.b 2(a5),d1
 bne.s .notview

 moveq #0,d1
 
 cmp.b #1,VECOBJ
 beq.s .notview
 
 jsr ViewpointToDraw
 add.w d0,d0
 move.w d0,d1
 
.notview
 
 muls #A_OptLen,d1
 add.l d1,a6

 move.w SecTimer(a0),d1
 tst.b 1(a5)
 blt.s .nospec
 
 move.b 1(a5),d1
 
.nospec:

 muls #A_FrameLen,d1

 st 1(a5)
 move.b (a5),DoAction
 clr.b (a5)
 move.b 3(a5),FINISHEDANIM
 clr.b 3(a5)

 move.l #0,8(a0)
 move.b (a6,d1.w),9(a0)
 move.b 1(a6,d1.w),d0
 ext.w d0
 bgt.s .noflip
 move.b #128,10(a0)
 neg.w d0
.noflip:
 sub.w #1,d0
 move.b d0,11(a0)
 
 
 move.w #0,ANIMFACING
 cmp.b #1,VECOBJ
 bne.s .noanimface
 move.w 2(a6,d1.w),ANIMFACING
.noanimface:

******************************************
 move.w #-1,GraphicRoom-64(a0)
 move.w #-1,12-64(a0)

 move.w AUXOBJ,d3
 blt .noaux

 move.b 8(a6,d1.w),d0
 blt .noaux
 
 move.w 12(a0),12-64(a0)
 move.w 12(a0),GraphicRoom-64(a0)
 move.w 4(a0),4-64(a0)
 move.b ObjInTop(a0),ObjInTop-64(a0)
 
 move.b 9(a6,d1.w),d4
 move.b 10(a6,d1.w),d5

 ext.w d4
 ext.w d5
 add.w d4,d4
 add.w d5,d5
 
 move.w d4,auxxoff-64(a0)
 move.w d5,auxyoff-64(a0)

 move.l LINKFILE,a4
 move.l a4,a2
 add.l #ObjectDefAnims,a4
 add.l #ObjectStats,a2

 move.w d3,d4
 muls #O_AnimSize,d3
 muls #ObjectStatLen,d4
 add.l d4,a2
 add.l d3,a4
 
 muls #O_FrameStoreSize,d0

 cmp.w #1,O_GFXType(a2)
 blt.s .bitmap
 beq.s .vector
 
.glare:
 move.l #0,8-64(a0)
 move.b (a4,d0.w),d3
 ext.w d3
 neg.w d3
 move.w d3,8-64(a0)
 move.b 1(a4,d0.w),11-64(a0)
 move.w 2(a4,d0.w),6-64(a0)
 
; move.b 4(a3,d0.w),d1 
; ext.w d1
; add.w d1,d1
; add.w d1,4(a0)
 
; moveq #0,d1
; move.b 5(a3,d0.w),d1
; move.w d1,ObjTimer(a0)
 
 bra .noaux
 
.vector:
 move.l #0,8-64(a0)
 move.b (a4,d0.w),9-64(a0)
 move.b 1(a4,d0.w),11-64(a0)
 move.w #$ffff,6-64(a0)
; move.b 4(a3,d0.w),d1 
; ext.w d1
; add.w d1,d1
; add.w d1,4(a0)

; moveq #0,d1
; move.b 5(a3,d0.w),d1
; move.w d1,ObjTimer(a0)
 
 bra .noaux
 
.bitmap:

 move.l #0,8-64(a0)
 move.b (a4,d0.w),9-64(a0)
 move.b 1(a4,d0.w),11-64(a0)
 move.w 2(a4,d0.w),6-64(a0)
; move.b 4(a4,d0.w),d1 
; ext.w d1
; add.w d1,d1
; add.w d1,4(a0)
 
; moveq #0,d1
; move.b 5(a3,d0.w),d1
; move.w d1,ObjTimer(a0)

.noaux:

******************************************


 move.w #-1,6(a0)
 cmp.b #1,VECOBJ
 beq.s .nosize
 bgt.s .setlight
 move.w 2(a6,d1.w),6(a0)
 move.l (a7)+,d0
 rts

.nosize

; move.l #$00090001,8(a0)
 
 move.l (a7)+,d0
 rts
 
.setlight:
 move.w 2(a6,d1.w),6(a0)

 move.b VECOBJ,d1
 or.b d1,10(a0)

 move.l (a7)+,d0
 rts

BLIBBLE:
 
 move.l ANIMPOINTER,a6
 
 move.w #8,d0

 muls #A_OptLen,d0
 add.w d0,a6

 move.w SecTimer(a0),d1
 move.w d1,d2
 add.w #1,d2
 muls #A_FrameLen,d1
 tst.b A_FrameLen(a6,d1.w)
 slt FINISHEDANIM
 bge.s .noendanim
 moveq #0,d2
.noendanim
 move.w d2,SecTimer(a0)

 move.l #0,8(a0)
 move.b (a6,d1.w),9(a0)
 move.b 1(a6,d1.w),11(a0)

 move.w #-1,6(a0)
 cmp.b #1,VECOBJ
 beq.s .nosize
 move.w 2(a6,d1.w),6(a0)
.nosize

 moveq #0,d0
 move.b 5(a6,d1.w),d0
 beq.s .nosoundmake
 
 movem.l d0-d7/a0-a6,-(a7)
 subq #1,d0
 move.w d0,Samplenum
 clr.b notifplaying
 move.w (a0),IDNUM
 move.w #200,Noisevol
 move.l #ObjRotated,a1
 move.w (a0),d0
 lea (a1,d0.w*8),a1
 move.l (a1),Noisex
 move.b ALIENECHO,Echo
 jsr MakeSomeNoise
 movem.l (a7)+,d0-d7/a0-a6
.nosoundmake

 move.b 6(a6,d1.w),d0
 sne DoAction

 rts
 
CHECKATTACKONGROUND:

 move.l PLR1_Roompt,a3
 moveq #0,d1
 move.b ToZoneCpt(a3),d1
 tst.b PLR1_StoodInTop
 beq.s .pnotintop
 move.b ToZoneCpt+1(a3),d1
.pnotintop:

 move.w d1,d3

 move.w CurrCPt(a0),d0
 
 cmp.w d0,d1
 beq.s .yesattack
 
 jsr GetNextCPt
 
 cmp.w d0,d3
 beq.s .yesattack
 
.noattack:

 clr.b d0
 rts
 
.yesattack:

 st d0
 
 rts

GETROOMCPT: 
 move.l objroom,a2
 moveq #0,d0
 move.b ToZoneCpt(a2),d0
 tst.b ObjInTop(a0)
 beq.s .pnotintop
 move.b ToZoneCpt+1(a2),d0
.pnotintop:
 
 move.w d0,CurrCPt(a0)
 rts


CALCSQROOT:
 tst.l d2
 beq .oksqr

 movem.l d0/d1/d3-d7/a0-a6,-(a7)

 move.w #31,d0
.findhigh
 btst d0,d2
 bne .foundhigh
 dbra d0,.findhigh
.foundhigh
 asr.w #1,d0
 clr.l d3
 bset d0,d3
 move.l d3,d0

 move.w d0,d1
 muls d1,d1	; x*x
 sub.l d2,d1	; x*x-a
 asr.l #1,d1	; (x*x-a)/2
 divs d0,d1	; (x*x-a)/2x
 sub.w d1,d0	; second approx
 bgt .stillnot0
 move.w #1,d0
.stillnot0

 move.w d0,d1
 muls d1,d1
 sub.l d2,d1
 asr.l #1,d1
 divs d0,d1
 sub.w d1,d0	; second approx
 bgt .stillnot02
 move.w #1,d0
.stillnot02

 move.w d0,d1
 muls d1,d1
 sub.l d2,d1
 asr.l #1,d1
 divs d0,d1
 sub.w d1,d0	; second approx
 bgt .stillnot03
 move.w #1,d0
.stillnot03

 move.w d0,d2
 ext.l d2

 movem.l (a7)+,d0/d1/d3-d7/a0-a6
 
.oksqr
 rts



DoAction: dc.b 0
FINISHEDANIM: dc.b 0
NASTYWORK: ds.l 4*300
TEAMWORK: ds.l 4*30
DAMAGED: ds.w 300
DAMAGEPTR: dc.l 0

BOREDOMPTR: dc.l 0
BOREDOMSPACE: ds.l 2*300
