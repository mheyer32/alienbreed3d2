
gotgun: dc.w 0

 INCLUDE "ab3:source_4000/NEWALIEN.s"
**************************************
 INCLUDE "ab3:source_4000/FlyingScalyBall.s"
**************************************
 INCLUDE "ab3:source_4000/BigUglyAlien.s"
**************************************
 INCLUDE "ab3:source_4000/MutantMarine.s"
**************************************
 INCLUDE "ab3:source_4000/ToughMarine.s"
ASKFORPROT:
 include "ab3:source_4000/askforprot.s"
 
**************************************
 INCLUDE "ab3:source_4000/halfworm.s"
**************************************
 INCLUDE "ab3:source_4000/bigredthing.s"
**************************************
 INCLUDE "ab3:source_4000/tree.s"
**************************************
 INCLUDE "ab3:source_4000/EyeBall.s"
**************************************
 INCLUDE "ab3:source_4000/FlameMarine.s"


**************************************
 INCLUDE "ab3:source_4000/Robot.s"
 
THISPLRxoff: dc.w 0
THISPLRzoff: dc.w 0
 
ViewpointToDraw:
; Calculate which side to display:

 move.l ObjectPoints,a1
 move.w (a0),d1
 lea (a1,d1.w*8),a1	; ptr to points 
 
 move.w (a1),oldx
 move.w 4(a1),oldz
 move.w THISPLRxoff,newx
 move.w THISPLRzoff,newz
 move.w #64,speed
 move.w #-60,Range
 movem.l a0/a1,-(a7)
 jsr HeadTowards
 movem.l (a7)+,a0/a1
 
 move.w newx,d0
 sub.w oldx,d0
 move.w newz,d1
 sub.w oldz,d1
 move.w Facing(a0),d3
 add.w #1024,d3
 and.w #8190,d3
 move.l #SineTable,a2
 move.w (a2,d3.w),d2
 adda.w #2048,a2
 move.w (a2,d3.w),d3

 move.w d0,d4
 move.w d1,d5
 muls d3,d4
 muls d2,d5
 sub.l d5,d4
 muls d3,d1
 muls d2,d0
 add.l d1,d0

 tst.l d0
 bgt.s FacingTowardsPlayer
FAP:
 tst.l d4
 bgt.s FAPR
 cmp.l d4,d0
 bgt.s LEFTFRAME
 bra.s AWAYFRAME

FAPR:
 neg.l d0
 cmp.l d0,d4
 bgt.s RIGHTFRAME
 bra.s AWAYFRAME

FacingTowardsPlayer
 
 tst.l d4
 bgt.s FTPR
 neg.l d4
 cmp.l d0,d4
 bgt.s LEFTFRAME
 bra.s TOWARDSFRAME

FTPR:
 cmp.l d0,d4
 bgt.s RIGHTFRAME
TOWARDSFRAME:
 move.l #0,d0
 rts
RIGHTFRAME:
 move.l #1,d0
 rts
LEFTFRAME:
 move.l #3,d0
 rts
AWAYFRAME:
 move.l #2,d0
 rts
 
deadframe: dc.l 0
screamsound: dc.w 0
nasheight: dc.w 0
tempcos: dc.w 0
tempsin: dc.w 0
tempx: dc.w 0
tempz: dc.w 0
 
RunAround:

 movem.l d0/d1/d2/d3/a0/a1,-(a7)

 move.w oldx,d0
 sub.w newx,d0	; dx
 asr.w #1,d0
 move.w oldz,d1
 sub.w newz,d1	; dz
 asr.w #1,d1
 
 move.l ObjectPoints,a1
 move.w (a0),d2
 lea (a1,d2.w*8),a1
 move.w (a1),d2
 sub.w tempx,d2
 move.w 4(a1),d3
 sub.w tempz,d3
 
 muls tempcos,d2
 muls tempsin,d3
 sub.l d3,d2
 
 blt.s headleft
 neg.w d0
 neg.w d1
headleft:
 sub.w d1,newx
 add.w d0,newz

 movem.l (a7)+,d0/d1/d2/d3/a0/a1
 rts
 
bbbb: dc.w 0
tsx: dc.w 0
tsz: dc.w 0
fsx: dc.w 0
fsz: dc.w 0
 
SHOOTPLAYER1

 move.w oldx,tsx
 move.w oldz,tsz
 move.w newx,fsx
 move.w oldx,fsz

 move.w p1_xoff,newx
 move.w p1_zoff,newz
 move.w (a1),oldx
 move.w 4(a1),oldz

 move.w newx,d1
 sub.w oldx,d1
 move.w newz,d2
 sub.w oldz,d2
 jsr GetRand
 asr.w #4,d0
 muls d0,d1
 muls d0,d2
 swap d1
 swap d2
 add.w d1,newz
 sub.w d2,newx
 
 move.l p1_yoff,d1
 add.l #15*128,d1
 asr.l #7,d1
 move.w d1,d2
 muls d0,d2
 swap d2
 add.w d2,d1
 ext.l d1
 asl.l #7,d1
 move.l d1,newy
 move.w 4(a0),d1
 ext.l d1
 asl.l #7,d1
 move.l d1,oldy
 
 move.b ObjInTop(a0),StoodInTop
 
 st exitfirst
 move.w #0,extlen
 move.b #$ff,awayfromwall
 move.w #%0000010000000000,wallflags
 move.l #0,StepUpVal
 move.l #$1000000,StepDownVal
 move.l #0,thingheight
 move.l objroom,-(a7)
 movem.l d0-d7/a0-a6,-(a7)

.again:
 jsr MoveObject
 tst.b hitwall
 bne.s .nofurther
 move.w newx,d0
 sub.w oldx,d0
 add.w d0,oldx
 add.w d0,newx
 move.w newz,d0
 sub.w oldz,d0
 add.w d0,oldz
 add.w d0,newz
 move.l newy,d0
 sub.l oldy,d0
 add.l d0,oldy
 add.l d0,newy
 bra .again

.nofurther:
 
 move.l objroom,backroom
 
 movem.l (a7)+,d0-d7/a0-a6
 move.l (a7)+,objroom

 move.l PlayerShotData,a0
 move.w #19,d1
.findonefree2
 move.w 12(a0),d2
 blt.s .foundonefree2
 adda.w #64,a0
 dbra d1,.findonefree2

 move.w tsx,oldx
 move.w tsz,oldz
 move.w fsx,newx
 move.w fsz,oldx

 rts

.foundonefree2:

 move.l ObjectPoints,a1
 move.w (a0),d2
 move.w newx,(a1,d2.w*8)
 move.w newz,4(a1,d2.w*8)
 move.b #1,shotstatus(a0)
 move.w #0,shotgrav(a0)
 move.b #0,shotsize(a0)
 move.b #0,shotanim(a0)
 
 move.l backroom,a1
 move.w (a1),12(a0)
 st worry(a0)
 move.l wallhitheight,d0
 move.l d0,accypos(a0)
 asr.l #7,d0
 move.w d0,4(a0)

 move.w tsx,oldx
 move.w tsz,oldz
 move.w fsx,newx
 move.w fsz,oldx

 rts

futurex: dc.w 0
futurez: dc.w 0

FireAtPlayer1:
 move.l NastyShotData,a5
 move.w #19,d1
.findonefree
 move.w 12(a5),d0
 blt.s .foundonefree
 adda.w #64,a5
 dbra d1,.findonefree

 bra .cantshoot

.foundonefree:

 move.b #2,16(a5)

 move.l #ObjRotated,a6
 move.w (a0),d0
 lea (a6,d0.w*8),a6

 move.l (a6),Noisex
 move.w #100,Noisevol
 move.b #1,chanpick
 clr.b notifplaying
 move.b SHOTTYPE,d0
 move.w #0,shotlife(a5)
 move.b d0,shotsize(a5)
 move.b SHOTPOWER,shotpower(a5)
 movem.l a5/a1/a0,-(a7)
 move.b 1(a0),IDNUM
 jsr MakeSomeNoise
 movem.l (a7)+,a5/a1/a0

 move.l ObjectPoints,a2
 move.w (a5),d1
 lea (a2,d1.w*8),a2
 move.w (a1),oldx
 move.w 4(a1),oldz
 move.w PLR1_xoff,newx
 move.w PLR1_zoff,newz

 jsr CalcDist
 move.w XDIFF1,d6
 muls distaway,d6
 divs SHOTSPEED,d6
 asr.w #4,d6
 add.w d6,newx
 move.w ZDIFF1,d6
 muls distaway,d6
 divs SHOTSPEED,d6
 asr.w #4,d6
 add.w d6,newz
 move.w newx,futurex
 move.w newz,futurez

 move.w SHOTSPEED,speed
 move.w #0,Range
 jsr HeadTowards

 move.w newx,d0
 sub.w oldx,d0
 move.w newz,d1
 sub.w oldz,d1
 move.w SHOTOFFMULT,d2
 beq.s .nooffset

 muls d2,d0
 muls d2,d1
 asr.l #8,d0
 asr.l #8,d1
 add.w d1,oldx
 sub.w d0,oldz
 move.w futurex,newx
 move.w futurez,newz
 jsr HeadTowards

.nooffset:

 move.w newx,d0
 move.w d0,(a2)
 sub.w oldx,d0
 move.w d0,shotxvel(a5)
 move.w newz,d0
 move.w d0,4(a2)
 sub.w oldz,d0
 move.w d0,shotzvel(a5)
 
 move.l #%100000100000,EnemyFlags(a5)
 move.w 12(a0),12(a5)
 move.w 4(a0),d0
 move.w d0,4(a5)
 ext.l d0
 asl.l #7,d0
 add.l SHOTYOFF,d0
 move.l d0,accypos(a5)
 move.b SHOTINTOP,ObjInTop(a5)
 move.l PLR1_Obj,a2
 move.w 4(a2),d1
 sub.w #20,d1
 ext.l d1
 asl.l #7,d1
 sub.l d0,d1
 add.l d1,d1
 move.w distaway,d0 
  
 move.w SHOTSHIFT,d2
 asr.w d2,d0
 tst.w d0
 bgt.s .okokokok
 moveq #1,d0
.okokokok

 divs d0,d1
 move.w d1,shotyvel(a5)
 st worry(a5)

 move.l GunData,a6
 moveq #0,d0
 move.b SHOTTYPE,d0 
 asl.w #5,d0
 add.w d0,a6
 move.w 16(a6),shotgrav(a5)
 move.w 18(a6),shotflags(a5)
; move.w 20(a6),d0
; add.w d0,shotyvel(a5)

.cantshoot
 rts

 
SHOOTPLAYER2

 move.w oldx,tsx
 move.w oldz,tsz
 move.w newx,fsx
 move.w oldx,fsz

 move.w p2_xoff,newx
 move.w p2_zoff,newz
 move.w (a1),oldx
 move.w 4(a1),oldz

 move.w newx,d1
 sub.w oldx,d1
 move.w newz,d2
 sub.w oldz,d2
 jsr GetRand
 asr.w #4,d0
 muls d0,d1
 muls d0,d2
 swap d1
 swap d2
 add.w d1,newz
 sub.w d2,newx
 
 move.l p2_yoff,d1
 add.l #15*128,d1
 asr.l #7,d1
 move.w d1,d2
 muls d0,d2
 swap d2
 add.w d2,d1
 ext.l d1
 asl.l #7,d1
 move.l d1,newy
 move.w 4(a0),d1
 ext.l d1
 asl.l #7,d1
 move.l d1,oldy
 move.b ObjInTop(a0),StoodInTop
 
 st exitfirst
 move.w #0,extlen
 move.b #$ff,awayfromwall
 move.w #%0000010000000000,wallflags
 move.l #0,StepUpVal
 move.l #$1000000,StepDownVal
 move.l #0,thingheight
 move.l objroom,-(a7)
 movem.l d0-d7/a0-a6,-(a7)

.again:
 jsr MoveObject
 tst.b hitwall
 bne.s .nofurther
 move.w newx,d0
 sub.w oldx,d0
 add.w d0,oldx
 add.w d0,newx
 move.w newz,d0
 sub.w oldz,d0
 add.w d0,oldz
 add.w d0,newz
 move.l newy,d0
 sub.l oldy,d0
 add.l d0,oldy
 add.l d0,newy
 bra .again

.nofurther:
 
 move.l objroom,backroom
 
 movem.l (a7)+,d0-d7/a0-a6
 move.l (a7)+,objroom

 move.l NastyShotData,a0
 move.w #19,d1
.findonefree2
 move.w 12(a0),d2
 blt.s .foundonefree2
 adda.w #64,a0
 dbra d1,.findonefree2

 move.w tsx,oldx
 move.w tsz,oldz
 move.w fsx,newx
 move.w fsz,oldx

 rts

.foundonefree2:

 move.l ObjectPoints,a1
 move.w (a0),d2
 move.w newx,(a1,d2.w*8)
 move.w newz,4(a1,d2.w*8)
 move.b #1,shotstatus(a0)
 move.w #0,shotgrav(a0)
 move.b #0,shotsize(a0)
 move.b #0,shotanim(a0)
 
 move.l backroom,a1
 move.w (a1),12(a0)
 st worry(a0)
 move.l wallhitheight,d0
 move.l d0,accypos(a0)
 asr.l #7,d0
 move.w d0,4(a0)

 move.w tsx,oldx
 move.w tsz,oldz
 move.w fsx,newx
 move.w fsz,oldx

 rts

FireAtPlayer2:
 move.l NastyShotData,a5
 move.w #19,d1
.findonefree
 move.w 12(a5),d0
 blt.s .foundonefree
 adda.w #64,a5
 dbra d1,.findonefree

 bra .cantshoot

.foundonefree:

 move.b #2,16(a5)

 move.l #ObjRotated,a6
 move.w (a0),d0
 lea (a6,d0.w*8),a6

 move.l (a6),Noisex
 move.w #100,Noisevol
 move.b #1,chanpick
 clr.b notifplaying
 move.b SHOTPOWER,d0
 move.w #0,shotlife(a5)
 move.b d0,shotsize(a5)
 move.b SHOTPOWER,shotpower(a5)
 movem.l a5/a1/a0,-(a7)
 move.b 1(a0),IDNUM
 jsr MakeSomeNoise
 movem.l (a7)+,a5/a1/a0

 move.l ObjectPoints,a2
 move.w (a5),d1
 lea (a2,d1.w*8),a2
 move.w (a1),oldx
 move.w 4(a1),oldz
 move.w PLR2_xoff,newx
 move.w PLR2_zoff,newz
 move.w SHOTSPEED,speed
 move.w #0,Range
 jsr HeadTowards

 move.w newx,d0
 sub.w oldx,d0
 move.w newz,d1
 sub.w oldz,d1
 move.w SHOTOFFMULT,d2
 beq.s .nooffset

 muls d2,d0
 muls d2,d1
 asr.l #8,d0
 asr.l #8,d1
 add.w d1,oldx
 sub.w d0,oldz
 move.w PLR2_xoff,newx
 move.w PLR2_zoff,newz
 jsr HeadTowards

.nooffset:


 move.w newx,d0
 move.w d0,(a2)
 sub.w oldx,d0
 move.w d0,shotxvel(a5)
 move.w newz,d0
 move.w d0,4(a2)
 sub.w oldz,d0
 move.w d0,shotzvel(a5)
 
 move.l #%100000100000,EnemyFlags(a5)
 move.w 12(a0),12(a5)
 move.w 4(a0),d0
 move.w d0,4(a5)
 ext.l d0
 asl.l #7,d0
 add.l SHOTYOFF,d0
 move.l d0,accypos(a5)
 move.b SHOTINTOP,ObjInTop(a5)
 move.l PLR2_Obj,a2
 move.w 4(a2),d1
 sub.w #20,d1
 ext.l d1
 asl.l #7,d1
 sub.l d0,d1
 add.l d1,d1
 move.w distaway,d0
 move.w SHOTSHIFT,d2
 asr.w d2,d0
 tst.w d0
 bgt.s .okokokok
 moveq #1,d0
.okokokok
 divs d0,d1
 move.w d1,shotyvel(a5)
 st worry(a5)
 move.w #0,shotgrav(a5)
.cantshoot
 rts

SHOTYOFF: dc.l 0
SHOTTYPE: dc.w 0
SHOTPOWER: dc.w 0
SHOTSPEED: dc.w 0
SHOTOFFMULT: dc.w 0
SHOTSHIFT: dc.w 0
SHOTINTOP: dc.w 0

backroom: dc.l 0