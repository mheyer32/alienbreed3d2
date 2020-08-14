
PLR1_clicked: dc.b 0
PLR2_clicked: dc.b 0
popping: ds.l 5*4
targdist: dc.w 0
targetydiff: dc.l 0
PLR1_TimeToShoot: dc.w 0
PLR2_TimeToShoot: dc.w 0

MaxFrame: dc.w 0

Player1Shot:

 tst.w PLR1_TimeToShoot
 beq.s okcanfire
 
 move.w TempFrames,d0
 sub.w d0,PLR1_TimeToShoot
 bge PLR1_nofire
 move.w #0,PLR1_TimeToShoot
 bra PLR1_nofire
 
okcanfire:

 lea PLR1_GunData,a6
 moveq #0,d0
 move.b p1_gunselected,d0
 move.b d0,tempgun
 
 move.l #GunAnims,a0
 move.b 7(a0,d0.w*8),MaxFrame
 
 lsl.w #2,d0
 lea (a6,d0.w*8),a6
 move.w 14(a6),BulletSpd
 
 tst.w 12(a6)
 beq.s .itsaclick

 tst.b p1_fire
 beq PLR1_nofire
 bra .itsahold

.itsaclick:
 tst.b p1_clicked
 beq PLR1_nofire

.itsahold:

 move.w PLR1_angpos,d0
 move.l #SineTable,a0
 lea (a0,d0.w),a0
 move.w (a0),tempxdir 
 move.w 2048(a0),tempzdir
 move.w PLR1_xoff,tempxoff
 move.w PLR1_zoff,tempzoff
 move.l PLR1_yoff,tempyoff
 add.l #20*128,tempyoff
 move.b PLR1_StoodInTop,tempStoodInTop
 move.l PLR1_Roompt,tempRoompt
 move.l #%1111111111110111000001,d7
 move.w #-1,d0
 move.l #0,targetydiff
 move.l #$7fff,d1

 move.l ZoneAdds,a3

 move.l #PLR1_ObsInLine,a1
 move.l ObjectData,a0
 move.l #PLR1_ObjDists,a2
findclosestinline
 tst.w (a0)
 blt outofline
 tst.b (a1)+
 beq.s notlinedup
 btst #0,17(a0)
 beq.s notlinedup
 tst.w 12(a0)
 blt.s notlinedup
 move.b 16(a0),d6
 btst d6,d7
 beq.s notlinedup
 tst.b numlives(a0)
 beq.s notlinedup
 move.w (a0),d5
 move.w (a2,d5.w*2),d6
 move.w 4(a0),d2
 ext.l d2
 asl.l #7,d2
 sub.l PLR1_yoff,d2
 move.l d2,d3
 bge.s .oknotneg
 neg.l d2
.oknotneg:
 divs #44,d2
 cmp.w d6,d2
 bgt.s notlinedup
 
 cmp.w d6,d1
 blt.s notlinedup
 move.w d6,d1
 move.l a0,a5
 
; We have a closer enemy lined up.
 move.l d3,targetydiff 
 move.w d5,d0

notlinedup:
 add.w #64,a0
 bra findclosestinline

outofline:

 
 move.w d1,targdist
 
 move.l targetydiff,d5
 sub.l PLR1_height,d5
 add.l #18*256,d5
 move.w d1,closedist
 
 move.w BulletSpd,d2
 asr.w d2,d1
 tst.w d1
 bgt.s okdistthing
 moveq #1,d1
okdistthing
 divs d1,d5
 move.w d5,bulyspd

 move.w (a6),d2
 moveq #0,d1
 move.b 2(a6),d1
 cmp.w d1,d2
 bge.s .okcanshoot
 
 move.l PLR1_Obj,a2
 move.w (a2),d0
 move.l #ObjRotated,a2
 move.l (a2,d0.w*8),Noisex
 move.w #300,Noisevol
 move.w #100,PLAYERNOISEVOL
 move.b #12,Samplenum+1
 clr.b notifplaying
 move.b #$fb,IDNUM
 jsr MakeSomeNoise
 
 rts

.okcanshoot:

 move.w 8(a6),PLR1_TimeToShoot

 move.b MaxFrame,PLR1_GunFrame
 sub.w d1,d2
 move.w d2,(a6)

 move.l PLR1_Obj,a2
 move.w (a2),d2
 move.l #ObjRotated,a2
 move.l (a2,d2.w*8),Noisex
 move.w #100,PLAYERNOISEVOL
 move.w #300,Noisevol
 move.b 3(a6),Samplenum+1
 move.b #2,chanpick
 clr.b notifplaying
 movem.l d0/a0/d5/d6/d7/a6/a5,-(a7)
 move.b #$fb,IDNUM
 jsr MakeSomeNoise
 movem.l (a7)+,d0/a0/d5/d6/d7/a6/a5

 tst.w d0
 blt nothingtoshoot

 tst.b 5(a6)
 beq PLR1FIREBULLET
 
; instant effect: check for hitting:

 move.w 22(a6),d7

FIREBULLETS:

 movem.l a0/a1/d7/d0/a5,-(a7)
 jsr GetRand
 
 move.l ObjectPoints,a1
 move.w (a5),d1
 lea (a1,d1.w*8),a1
 
 and.w #$7fff,d0
 move.w (a1),d1
 sub.w PLR1_xoff,d1
 muls d1,d1
 move.w 4(a1),d2
 sub.w PLR1_zoff,d2
 muls d2,d2
 add.l d2,d1
 asr.l #6,d1
 ext.l d0
 asl.l #1,d0
 cmp.l d1,d0
 bgt.s .hitplr
 
 movem.l (a7)+,a0/a1/d7/d0/a5
 move.l d0,-(a7)
 bsr PLR1MISSINSTANT
 move.l (a7)+,d0
 
 bra.s .missplr
.hitplr: 

 movem.l (a7)+,a0/a1/d7/d0/a5
 move.l d0,-(a7)
 bsr PLR1HITINSTANT
 move.l (a7)+,d0

.missplr:

 subq #1,d7
 bgt.s FIREBULLETS
 
 rts
 
nothingtoshoot:
 move.w #0,bulyspd
 tst.b 5(a6)
 beq PLR1FIREBULLET

 move.w #0,bulyspd

 move.w PLR1_xoff,oldx
 move.w PLR1_zoff,oldz
 move.w PLR1_sinval,d0
 asr.w #7,d0
 add.w oldx,d0
 move.w d0,newx
 move.w PLR1_cosval,d0
 asr.w #7,d0
 add.w oldz,d0
 move.w d0,newz
 move.l PLR1_yoff,d0
 add.l #20*128,d0
 move.l d0,oldy
 
 move.l d0,d1
 jsr GetRand
 and.w #$fff,d0
 sub.w #$800,d0
 ext.l d0
 add.l d0,d1
 
 move.l oldy,TESTY
 
 move.l d1,newy
 move.l newy,TESTY+4
 
 st exitfirst
 clr.b wallbounce
 move.w #0,extlen
 move.b #$ff,awayfromwall
 move.w #%0000010000000000,wallflags
 move.l #0,StepUpVal
 move.l #$1000000,StepDownVal
 move.l #0,thingheight
 move.l PLR1_Roompt,objroom
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
 
 movem.l (a7)+,d0-d7/a0-a6

 move.l PlayerShotData,a0
 move.w #19,d1
.findonefree2
 move.w 12(a0),d2
 blt.s .foundonefree2
 adda.w #64,a0
 dbra d1,.findonefree2

 rts

.foundonefree2:

 move.l ObjectPoints,a1
 move.w (a0),d2
 move.w newx,(a1,d2.w*8)
 move.w newz,4(a1,d2.w*8)
 move.b #1,shotstatus(a0)
 move.w #0,shotgrav(a0)
 move.b p1_gunselected,shotsize(a0)
 move.b #0,shotanim(a0)
 
 move.l objroom,a1
 move.w (a1),12(a0)
 st worry(a0)
 move.l wallhitheight,d0
 move.l newy,TESTY+8
 move.l d0,TESTY+12
 move.l d0,accypos(a0)
 asr.l #7,d0
 move.w d0,4(a0)

 rts
 
PLR1_nofire:

 rts

TESTY: dc.l 0,0,0,0

Player2Shot:

 tst.w PLR2_TimeToShoot
 beq.s okcanfire2
 
 move.w TempFrames,d0
 sub.w d0,PLR2_TimeToShoot
 bge PLR2_nofire
 move.w #0,PLR2_TimeToShoot
 bra PLR2_nofire
 
okcanfire2:


 lea PLR2_GunData,a6
 moveq #0,d0
 move.b p2_gunselected,d0
 move.b d0,tempgun
 
 move.l #GunAnims,a0
 move.b 7(a0,d0.w*8),MaxFrame
 
 lsl.w #2,d0
 lea (a6,d0.w*8),a6
 move.w 14(a6),BulletSpd
 
 tst.w 12(a6)
 beq.s .itsaclick

 tst.b p2_fire
 beq PLR2_nofire
 bra .itsahold

.itsaclick:
 tst.b p2_clicked
 beq PLR2_nofire

.itsahold:

 move.w PLR2_angpos,d0
 move.l #SineTable,a0
 lea (a0,d0.w),a0
 move.w (a0),tempxdir 
 move.w 2048(a0),tempzdir
 move.w PLR2_xoff,tempxoff
 move.w PLR2_zoff,tempzoff
 move.l PLR2_yoff,tempyoff
 add.l #20*128,tempyoff
 move.b PLR2_StoodInTop,tempStoodInTop
 move.l PLR2_Roompt,tempRoompt
 move.l #%1111111111010111100001,d7
 move.w #-1,d0
 move.l #0,targetydiff
 move.l #$7fff,d1

 move.l ZoneAdds,a3

 move.l #PLR2_ObsInLine,a1
 move.l ObjectData,a0
 move.l #PLR2_ObjDists,a2
findclosestinline2
 tst.w (a0)
 blt outofline2
 tst.b (a1)+
 beq.s notlinedup2
 btst #1,17(a0)
 beq.s notlinedup2
 tst.w 12(a0)
 blt.s notlinedup2
 move.b 16(a0),d6
 btst d6,d7
 beq.s notlinedup2
 tst.b numlives(a0)
 beq.s notlinedup2
 move.w (a0),d5
 move.w (a2,d5.w*2),d6
 move.w 4(a0),d2
 ext.l d2
 asl.l #7,d2
 sub.l PLR2_yoff,d2
 move.l d2,d3
 bge.s .oknotneg
 neg.l d2
.oknotneg:
 divs #44,d2
 cmp.w d6,d2
 bgt.s notlinedup2
 
 cmp.w d6,d1
 blt.s notlinedup2
 move.w d6,d1
 move.l a0,a5
 
; We have a closer enemy lined up.
 move.l d3,targetydiff 
 move.w d5,d0

notlinedup2:
 add.w #64,a0
 bra findclosestinline2

outofline2:

 
 move.w d1,targdist
 
 move.l targetydiff,d5
 sub.l PLR2_height,d5
 add.l #18*256,d5
 move.w d1,closedist
 
 move.w BulletSpd,d2
 asr.w d2,d1
 tst.w d1
 bgt.s okdistthing2
 moveq #1,d1
okdistthing2
 divs d1,d5
 move.w d5,bulyspd

 move.w (a6),d2
 moveq #0,d1
 move.b 2(a6),d1
 cmp.w d1,d2
 bge.s .okcanshoot
 
 move.l PLR2_Obj,a2
 move.w (a2),d0
 move.l #ObjRotated,a2
 move.l (a2,d0.w*8),Noisex
 move.w #300,Noisevol
 move.b #12,Samplenum+1
 clr.b notifplaying
 move.b #$fb,IDNUM
 jsr MakeSomeNoise
 
 rts

.okcanshoot:

 move.w 8(a6),PLR2_TimeToShoot

 move.b MaxFrame,PLR2_GunFrame
 sub.w d1,d2
 move.w d2,(a6)

 move.l PLR2_Obj,a2
 move.w (a2),d2
 move.l #ObjRotated,a2
 move.l (a2,d2.w*8),Noisex
 move.w #300,Noisevol
 move.b 3(a6),Samplenum+1
 move.b #2,chanpick
 clr.b notifplaying
 movem.l d0/a0/d5/d6/d7/a6/a5,-(a7)
 move.b #$fb,IDNUM
 jsr MakeSomeNoise
 movem.l (a7)+,d0/a0/d5/d6/d7/a6/a5

 tst.w d0
 blt nothingtoshoot2

 tst.b 5(a6)
 beq PLR2FIREBULLET
 
; instant effect: check for hitting:

 move.w 22(a6),d7

FIREBULLETS2:

 movem.l a0/a1/d7/d0/a5,-(a7)
 jsr GetRand
 
 move.l ObjectPoints,a1
 move.w (a5),d1
 lea (a1,d1.w*8),a1
 
 and.w #$7fff,d0
 move.w (a1),d1
 sub.w PLR2_xoff,d1
 muls d1,d1
 move.w 4(a1),d2
 sub.w PLR2_zoff,d2
 muls d2,d2
 add.l d2,d1
 asr.l #6,d1
 ext.l d0
 asl.l #1,d0
 cmp.l d1,d0
 bgt.s .hitplr
 
 movem.l (a7)+,a0/a1/d7/d0/a5
 move.l d0,-(a7)
 bsr PLR2MISSINSTANT
 move.l (a7)+,d0
 
 bra.s .missplr
.hitplr: 

 movem.l (a7)+,a0/a1/d7/d0/a5
 move.l d0,-(a7)
 bsr PLR2HITINSTANT
 move.l (a7)+,d0

.missplr:

 subq #1,d7
 bgt.s FIREBULLETS2
 
 rts
 
nothingtoshoot2:
 move.w #0,bulyspd
 tst.b 5(a6)
 beq PLR2FIREBULLET

 move.w #0,bulyspd

 move.w PLR2_xoff,oldx
 move.w PLR2_zoff,oldz
 move.w PLR2_sinval,d0
 asr.w #7,d0
 add.w oldx,d0
 move.w d0,newx
 move.w PLR2_cosval,d0
 asr.w #7,d0
 add.w oldz,d0
 move.w d0,newz
 move.l PLR2_yoff,d0
 add.l #20*128,d0
 move.l d0,oldy
 
 move.l d0,d1
 jsr GetRand
 and.w #$fff,d0
 sub.w #$800,d0
 ext.l d0
 add.l d0,d1
 
 move.l d1,newy
 
 st exitfirst
 clr.b wallbounce
 move.w #0,extlen
 move.b #$ff,awayfromwall
 move.w #%0000010000000000,wallflags
 move.l #0,StepUpVal
 move.l #$1000000,StepDownVal
 move.l #0,thingheight
 move.l PLR2_Roompt,objroom
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
 
 movem.l (a7)+,d0-d7/a0-a6

 move.l PlayerShotData,a0
 move.w #19,d1
.findonefree2
 move.w 12(a0),d2
 blt.s .foundonefree2
 adda.w #64,a0
 dbra d1,.findonefree2

 rts

.foundonefree2:

 move.l ObjectPoints,a1
 move.w (a0),d2
 move.w newx,(a1,d2.w*8)
 move.w newz,4(a1,d2.w*8)
 move.b #1,shotstatus(a0)
 move.w #0,shotgrav(a0)
 move.b p2_gunselected,shotsize(a0)
 move.b #0,shotanim(a0)
 
 move.l objroom,a1
 move.w (a1),12(a0)
 st worry(a0)
 move.l wallhitheight,d0
 move.l d0,accypos(a0)
 asr.l #7,d0
 move.w d0,4(a0)

 rts
 
PLR2_nofire:

 rts


BulletSpd: dc.w 0

*******************************************************
 
tempyoff: dc.l 0
tempStoodInTop: dc.w 0
tempangpos: dc.w 0
tempxdir: dc.w 0
tempzdir: dc.w 0
tempgun: dc.w 0
tstfire: dc.w 0
PLR1FIREBULLET:

 move.w #256,d6
 move.w #256,d5
 
 move.b MaxFrame,PLR1_GunFrame
 move.l PLR1_Obj,a2
 bra firefive
 
PLR2FIREBULLET:

 move.b MaxFrame,PLR2_GunFrame
 move.l PLR2_Obj,a2

firefive:

 move.l PlayerShotData,a0
 move.w #19,d1
.findonefree
 move.w 12(a0),d0
 blt.s .foundonefree
 adda.w #64,a0
 dbra d1,.findonefree

 rts

.foundonefree
 move.w 16(a6),shotgrav(a0)
 move.w 18(a6),shotflags(a0)
 
 move.w bulyspd,d0
 
 cmp.w #20*128,d0
 blt.s .okdownspd
 move.w #20*128,d0
.okdownspd:

 cmp.w #-20*128,d0
 bgt.s .okupspd
 move.w #-20*128,d0
.okupspd:

 add.w 20(a6),d0

 move.w d0,bulyspd

 move.l #ObjRotated,a2
 move.b tempgun,shotsize(a0)
 move.b 6(a6),shotpower(a0)

 move.l ObjectPoints,a1
 move.w (a0),d1
 lea (a1,d1.w*8),a1
 move.w tempxoff,(a1)
 move.w tempzoff,4(a1)
 move.w tempxdir,d0
 ext.l d0
 
 move.w BulletSpd,d1
 asl.l d1,d0
 move.l d0,shotxvel(a0)
 move.w tempzdir,d0
 ext.l d0
 asl.l d1,d0
 move.l d0,shotzvel(a0)
 move.w bulyspd,shotyvel(a0)
 move.b tempStoodInTop,ObjInTop(a0)
 move.w #0,shotlife(a0)
 move.l #%11,EnemyFlags(a0)
 move.l tempRoompt,a2
 move.w (a2),12(a0)
 move.l tempyoff,d0
 add.l #20*128,d0
 move.l d0,accypos(a0)
 st worry(a0)
 asr.l #7,d0
 move.w d0,4(a0)
 
 rts

PLR1HITINSTANT:

; Just blow it up.

 move.l PlayerShotData,a0
 move.w #19,d1
.findonefree
 move.w 12(a0),d2
 blt.s .foundonefree
 adda.w #64,a0
 dbra d1,.findonefree

 rts

.foundonefree:

 move.l ObjectPoints,a1
 move.w (a0),d2
 move.l (a1,d0.w*8),(a1,d2.w*8)
 move.l 4(a1,d0.w*8),4(a1,d2.w*8)
 move.b #1,shotstatus(a0)
 move.w #0,shotgrav(a0)
 move.b p1_gunselected,shotsize(a0)
 move.b #0,shotanim(a0)
 
 move.w 4(a5),d1
 ext.l d1
 asl.l #7,d1
 move.l d1,accypos(a0)
 move.w 12(a5),12(a0)
 st worry(a0)
 move.w 4(a5),4(a0)
 
 move.b 6(a6),d0
 add.b d0,damagetaken(a5)
 
 move.w tempxdir,d1
 ext.l d1
 asl.l #3,d1
 swap d1
 move.w d1,ImpactX(a5)
 move.w tempzdir,d1
 ext.l d1
 asl.l #3,d1
 swap d1
 move.w d1,ImpactZ(a5)

 rts

PLR1MISSINSTANT: 

 move.w PLR1_xoff,oldx
 move.w PLR1_zoff,oldz
 move.l PLR1_yoff,d1
 add.l #20*128,d1
 move.l d1,oldy

 move.w (a5),d0
 move.l ObjectPoints,a1
 move.w (a1,d0.w*8),d2
 sub.w oldx,d2
 asr.w #1,d2
 add.w oldx,d2
 move.w d2,newx
 move.w 4(a1,d0.w*8),d2
 sub.w oldz,d2
 asr.w #1,d2
 add.w oldz,d2
 move.w d2,newz
 
 move.w 4(a0),d2
 ext.l d2
 asl.l #7,d2
 move.l d2,newy
 
 st exitfirst
 clr.b wallbounce
 move.w #0,extlen
 move.b #$ff,awayfromwall
 move.w #%0000010000000000,wallflags
 move.l #0,StepUpVal
 move.l #$1000000,StepDownVal
 move.l #0,thingheight
 move.l PLR1_Roompt,objroom
 movem.l d0-d7/a0-a6,-(a7)

.again:
 jsr MoveObject
 tst.b hitwall
 bne.s .nofurther
 move.w newx,d1
 sub.w oldx,d1
 add.w d1,oldx
 add.w d1,newx
 move.w newz,d1
 sub.w oldz,d1
 add.w d1,oldz
 add.w d1,newz
 move.l newy,d1
 sub.l oldy,d1
 add.l d1,oldy
 add.l d1,newy
 bra .again

.nofurther:
 
 movem.l (a7)+,d0-d7/a0-a6

 move.l PlayerShotData,a0
 move.w #19,d1
.findonefree2
 move.w 12(a0),d2
 blt.s .foundonefree2
 adda.w #64,a0
 dbra d1,.findonefree2

 rts

.foundonefree2:

 move.l ObjectPoints,a1
 move.w (a0),d2
 move.w newx,(a1,d2.w*8)
 move.w newz,4(a1,d2.w*8)
 move.b #1,shotstatus(a0)
 move.w #0,shotgrav(a0)
 move.b p1_gunselected,shotsize(a0)
 move.b #0,shotanim(a0)
 
 move.l objroom,a1
 move.w (a1),12(a0)
 st worry(a0)
 move.l newy,d1
 move.l d1,accypos(a0)
 asr.l #7,d1
 move.w d1,4(a0)
 
 rts


PLR2HITINSTANT:

; Just blow it up.

 move.l PlayerShotData,a0
 move.w #19,d1
.findonefree
 move.w 12(a0),d2
 blt.s .foundonefree
 adda.w #64,a0
 dbra d1,.findonefree

 rts

.foundonefree:

 move.l ObjectPoints,a1
 move.w (a0),d2
 move.l (a1,d0.w*8),(a1,d2.w*8)
 move.l 4(a1,d0.w*8),4(a1,d2.w*8)
 move.b #1,shotstatus(a0)
 move.w #0,shotgrav(a0)
 move.b p2_gunselected,shotsize(a0)
 move.b #0,shotanim(a0)
 
 move.w 4(a5),d1
 ext.l d1
 asl.l #7,d1
 move.l d1,accypos(a0)
 move.w 12(a5),12(a0)
 st worry(a0)
 move.w 4(a5),4(a0)
 
 move.b 6(a6),d0
 add.b d0,damagetaken(a5)
 
 move.w tempxdir,d1
 ext.l d1
 asl.l #3,d1
 swap d1
 move.w d1,ImpactX(a5)
 move.w tempzdir,d1
 ext.l d1
 asl.l #3,d1
 swap d1
 move.w d1,ImpactZ(a5)

 rts

PLR2MISSINSTANT: 

 move.w PLR2_xoff,oldx
 move.w PLR2_zoff,oldz
 move.l PLR2_yoff,d1
 add.l #20*128,d1
 move.l d1,oldy

 move.w (a5),d0
 move.l ObjectPoints,a1
 move.w (a1,d0.w*8),d2
 sub.w oldx,d2
 asr.w #1,d2
 add.w oldx,d2
 move.w d2,newx
 move.w 4(a1,d0.w*8),d2
 sub.w oldz,d2
 asr.w #1,d2
 add.w oldz,d2
 move.w d2,newz
 move.w 4(a0),d2
 ext.l d2
 asl.l #7,d2
 move.l d2,newy
 
 st exitfirst
 clr.b wallbounce
 move.w #0,extlen
 move.b #$ff,awayfromwall
 move.w #%0000010000000000,wallflags
 move.l #0,StepUpVal
 move.l #$1000000,StepDownVal
 move.l #0,thingheight
 move.l PLR2_Roompt,objroom
 movem.l d0-d7/a0-a6,-(a7)

.again:
 jsr MoveObject
 tst.b hitwall
 bne.s .nofurther
 move.w newx,d1
 sub.w oldx,d1
 add.w d1,oldx
 add.w d1,newx
 move.w newz,d1
 sub.w oldz,d1
 add.w d1,oldz
 add.w d1,newz
 move.l newy,d1
 sub.l oldy,d1
 add.l d1,oldy
 add.l d1,newy
 bra .again

.nofurther:
 
 movem.l (a7)+,d0-d7/a0-a6

 move.l PlayerShotData,a0
 move.w #19,d1
.findonefree2
 move.w 12(a0),d2
 blt.s .foundonefree2
 adda.w #64,a0
 dbra d1,.findonefree2

 rts

.foundonefree2:

 move.l ObjectPoints,a1
 move.w (a0),d2
 move.w newx,(a1,d2.w*8)
 move.w newz,4(a1,d2.w*8)
 move.b #1,shotstatus(a0)
 move.w #0,shotgrav(a0)
 move.b p2_gunselected,shotsize(a0)
 move.b #0,shotanim(a0)
 
 move.l objroom,a1
 move.w (a1),12(a0)
 st worry(a0)
 move.l newy,d1
 move.l d1,accypos(a0)
 asr.l #7,d1
 move.w d1,4(a0)
 
 rts
