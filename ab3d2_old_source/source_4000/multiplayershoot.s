
PLR1_clicked: dc.b 0
PLR2_clicked: dc.b 0
PLR3_clicked: dc.b 0
popping: ds.l 5*4
targdist: dc.w 0
targetydiff: dc.l 0
PLR1_TimeToShoot: dc.w 0
PLR2_TimeToShoot: dc.w 0
PLR3_TimeToShoot: dc.w 0

tempangpos: dc.w 0

MaxFrame: dc.w 0
BULTYPE: dc.w 0
AmmoInMyGun: dc.w 0

Player1Shot:

 tst.w PLR1_TimeToShoot
 beq.s okcanfire
 
 move.w TempFrames,d0
 sub.w d0,PLR1_TimeToShoot
 bge PLR1_nofire
 move.w #0,PLR1_TimeToShoot
 bra PLR1_nofire
 
okcanfire:

 moveq #0,d0
 move.b p1_gunselected,d0
 move.b d0,tempgun
 
 
 move.l LINKFILE,a6
 lea GunBulletTypes(a6),a6
 lea BulletAnimData-GunBulletTypes(a6),a5
 lea (a6,d0.w*8),a6
 move.w G_BulletType(a6),d0 ; bullet type
 move.w d0,BULTYPE
 move.l #PLAYERONEAMMO,a0
 move.w (a0,d0.w*2),AmmoInMyGun

 muls #B_BulStatLen,d0
 add.w d0,a5
 
 move.w B_MovementSpeed+2(a5),BulletSpd
 
; tst.w (a6)
; beq.s .itsaclick

 tst.b p1_fire
 beq PLR1_nofire
; bra .itsahold
;
;.itsaclick:
; tst.b p1_clicked
; beq PLR1_nofire
;
;.itsahold:

 move.w PLR1_angpos,d0
 move.w d0,tempangpos
 move.l #SineTable,a0
 lea (a0,d0.w),a0
 move.w (a0),tempxdir 
 move.w 2048(a0),tempzdir
 move.w PLR1_xoff,tempxoff
 move.w PLR1_zoff,tempzoff
 move.l PLR1_yoff,tempyoff
 add.l #10*128,tempyoff
 move.b PLR1_StoodInTop,tempStoodInTop
 move.l PLR1_Roompt,tempRoompt
 move.l #%100011,d7
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

 cmp.b #3,16(a0)
 beq notlinedup

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
 move.l a0,a4
 
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

 move.w AmmoInMyGun,d2
 move.w G_BulletsPerShot(a6),d1
 cmp.w d1,d2
 bge.s .okcanshoot
 
 move.l PLR1_Obj,a2
 move.w (a2),d0
 move.l #ObjRotated,a2
 move.l (a2,d0.w*8),Noisex
 move.w #100,Noisevol
 move.w #100,PLAYERONENOISEVOL
 move.w #12,Samplenum
 clr.b notifplaying
 move.b #$fb,IDNUM
 jsr MakeSomeNoise
 
 rts

.okcanshoot:

 cmp.b #'s',mors
 beq.s .notplr1
 move.l PLR1_Obj,a2
 move.w #1,ObjTimer+128(a2)
.notplr1

 move.w G_DelayBetweenShots(a6),PLR1_TimeToShoot

 move.b MaxFrame,PLR1_GunFrame
 sub.w d1,d2
 
 move.l #PLAYERONEAMMO,a2
 add.w BULTYPE,a2
 add.w BULTYPE,a2
 move.w d2,(a2)
 
 move.l PLR1_Obj,a2
 move.w (a2),d2
 move.l #ObjRotated,a2
 move.l (a2,d2.w*8),Noisex
 move.w #100,PLAYERONENOISEVOL
 move.w #300,Noisevol
 move.w G_SoundEffect(a6),Samplenum
 move.b #2,chanpick
 clr.b notifplaying
 movem.l d0/a0/d5/d6/d7/a6/a4/a5,-(a7)
 move.b #$fb,IDNUM
 jsr MakeSomeNoise
 movem.l (a7)+,d0/a0/d5/d6/d7/a6/a4/a5

 tst.w d0
 blt nothingtoshoot

 tst.l B_Gravity(a5)
 beq.s .notuseaim
 move.w PLR1_AIMSPD,d2
 move.w #8,d1
 sub.w BulletSpd,d1
 asr.w d1,d2
 move.w d2,bulyspd
.notuseaim

 tst.w B_VisibleOrInstant+2(a5)
 beq PLR1FIREBULLET

; instant effect: check for hitting:

 move.w G_BulletsPerShot(a6),d7

FIREBULLETS:

 movem.l a0/a1/d7/d0/a4/a5,-(a7)
 jsr GetRand
 
 move.l ObjectPoints,a1
 move.w (a4),d1
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
 
 movem.l (a7)+,a0/a1/d7/d0/a5/a4
 move.l d0,-(a7)
 bsr PLR1MISSINSTANT
 move.l (a7)+,d0
 
 bra.s .missplr
.hitplr: 

 movem.l (a7)+,a0/a1/d7/d0/a5/a4
 move.l d0,-(a7)
 bsr PLR1HITINSTANT
 move.l (a7)+,d0

.missplr:

 subq #1,d7
 bgt.s FIREBULLETS
 
 rts
 
PLR1_AIMSPD: dc.l 0
PLR3_AIMSPD: dc.l 0
 
PLR1_PAUSE: dc.w 0
PLR2_PAUSE: dc.w 0
PLR3_PAUSE: dc.w 0
PLR3_Squished: dc.w 0
 
PLR1QUITTING: dc.w 0
PLR2QUITTING: dc.w 0
PLR3QUITTING: dc.w 0
 
nothingtoshoot:
 move.w PLR1_AIMSPD,d0
 move.w #8,d1
 sub.w BulletSpd,d1
 asr.w d1,d0
 move.w d0,bulyspd
 tst.w B_VisibleOrInstant+2(a5)
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
 add.l #10*128,d0
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
 move.b BULTYPE+1,shotsize(a0)
 move.b #0,shotanim(a0)
 
 move.l objroom,a1
 move.w (a1),12(a0)
 st worry(a0)
 move.l wallhitheight,d0
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
 
 moveq #0,d0
 move.b p2_gunselected,d0
 move.b d0,tempgun
 

 move.l LINKFILE,a6
 lea GunBulletTypes(a6),a6
 lea BulletAnimData-GunBulletTypes(a6),a5
 lea (a6,d0.w*8),a6
 move.w G_BulletType(a6),d0 ; bullet type
 move.w d0,BULTYPE
 move.l #PLAYERTWOAMMO,a0
 move.w (a0,d0.w*2),AmmoInMyGun

 muls #B_BulStatLen,d0
 add.w d0,a5
 
 move.w B_MovementSpeed+2(a5),BulletSpd
 
; tst.w 12(a6)
; beq.s .itsaclick

 tst.b p2_fire
 beq PLR2_nofire
; bra .itsahold
;
;.itsaclick:
; tst.b p2_clicked
; beq PLR2_nofire
;
;.itsahold:

 move.w PLR2_angpos,d0
 move.w d0,tempangpos
 move.l #SineTable,a0
 lea (a0,d0.w),a0
 move.w (a0),tempxdir 
 move.w 2048(a0),tempzdir
 move.w PLR2_xoff,tempxoff
 move.w PLR2_zoff,tempzoff
 move.l PLR2_yoff,tempyoff
 add.l #10*128,tempyoff
 move.b PLR2_StoodInTop,tempStoodInTop
 move.l PLR2_Roompt,tempRoompt
 move.l #%10011,d7
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

 cmp.b #3,16(a0)
 beq notlinedup2

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
 move.l a0,a4
 
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

 move.w AmmoInMyGun,d2
 move.w G_BulletsPerShot(a6),d1
 cmp.w d1,d2
 bge.s .okcanshoot

 move.l PLR2_Obj,a2
 move.w (a2),d0
 move.l #ObjRotated,a2
 move.l (a2,d0.w*8),Noisex
 move.w #300,Noisevol
 move.w #100,PLAYERTWONOISEVOL
 move.w #12,Samplenum
 clr.b notifplaying
 move.b #$fb,IDNUM
 jsr MakeSomeNoise
 
 rts

.okcanshoot:

 cmp.b #'s',mors
 bne.s .notplr2
 move.l PLR1_Obj,a2
 move.w #1,ObjTimer+128(a2)
.notplr2:

 move.w G_DelayBetweenShots(a6),PLR2_TimeToShoot

 move.b MaxFrame,PLR2_GunFrame
 sub.w d1,d2

 move.l #PLAYERTWOAMMO,a2
 add.w BULTYPE,a2
 add.w BULTYPE,a2
 move.w d2,(a2)

 move.l PLR2_Obj,a2
 move.w (a2),d2
 move.l #ObjRotated,a2
 move.l (a2,d2.w*8),Noisex
 move.w #100,PLAYERTWONOISEVOL
 move.w #300,Noisevol
 move.w G_SoundEffect(a6),Samplenum
 move.b #2,chanpick
 clr.b notifplaying
 movem.l d0/a0/d5/d6/d7/a6/a4/a5,-(a7)
 move.b #$fb,IDNUM
 jsr MakeSomeNoise
 movem.l (a7)+,d0/a0/d5/d6/d7/a6/a4/a5

 tst.w d0
 blt nothingtoshoot2

 tst.l B_Gravity(a5)
 beq.s .notuseaim
 move.w PLR2_AIMSPD,d2
 move.w #8,d1
 sub.w BulletSpd,d1
 asr.w d1,d2
 move.w d2,bulyspd
.notuseaim

 tst.w B_VisibleOrInstant+2(a5)
 beq PLR2FIREBULLET
 
; instant effect: check for hitting:

 move.w G_BulletsPerShot(a6),d7

FIREBULLETS2:

 movem.l a0/a1/d7/d0/a4/a5,-(a7)
 jsr GetRand
 
 move.l ObjectPoints,a1
 move.w (a4),d1
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
 
 movem.l (a7)+,a0/a1/d7/d0/a5/a4
 move.l d0,-(a7)
 bsr PLR2MISSINSTANT
 move.l (a7)+,d0
 
 bra.s .missplr
.hitplr: 

 movem.l (a7)+,a0/a1/d7/d0/a5/a4
 move.l d0,-(a7)
 bsr PLR2HITINSTANT
 move.l (a7)+,d0

.missplr:

 subq #1,d7
 bgt.s FIREBULLETS2
 
 rts
 
PLR2_AIMSPD: dc.l 0
 
nothingtoshoot2:
 move.w PLR2_AIMSPD,d0
 move.w #8,d1
 sub.w BulletSpd,d1
 asr.w d1,d0
 move.w d0,bulyspd
 tst.w B_VisibleOrInstant+2(a5)
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
 add.l #10*128,d0
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
 move.b BULTYPE+1,shotsize(a0)
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


***************************************


Player3Shot:

 tst.w PLR3_TimeToShoot
 beq.s okcanfire3
 
 move.w TempFrames,d0
 sub.w d0,PLR3_TimeToShoot
 bge PLR3_nofire
 move.w #0,PLR3_TimeToShoot
 bra PLR3_nofire
 
okcanfire3:
 
 moveq #0,d0
 move.b p3_gunselected,d0
 move.b d0,tempgun
 

 move.l LINKFILE,a6
 lea GunBulletTypes(a6),a6
 lea BulletAnimData-GunBulletTypes(a6),a5
 lea (a6,d0.w*8),a6
 move.w G_BulletType(a6),d0 ; bullet type
 move.w d0,BULTYPE
 move.l #PLAYERTHREEAMMO,a0
 move.w (a0,d0.w*2),AmmoInMyGun

 muls #B_BulStatLen,d0
 add.w d0,a5
 
 move.w B_MovementSpeed+2(a5),BulletSpd
 
; tst.w 12(a6)
; beq.s .itsaclick

 tst.b p3_fire
 beq PLR3_nofire
; bra .itsahold
;
;.itsaclick:
; tst.b p2_clicked
; beq PLR2_nofire
;
;.itsahold:

 move.w PLR3_angpos,d0
 move.w d0,tempangpos
 move.l #SineTable,a0
 lea (a0,d0.w),a0
 move.w (a0),tempxdir 
 move.w 2048(a0),tempzdir
 move.w PLR3_xoff,tempxoff
 move.w PLR3_zoff,tempzoff
 move.l PLR3_yoff,tempyoff
 add.l #10*128,tempyoff
 move.b PLR3_StoodInTop,tempStoodInTop
 move.l PLR3_Roompt,tempRoompt
 move.l #%10011,d7
 move.w #-1,d0
 move.l #0,targetydiff
 move.l #$7fff,d1

 move.l ZoneAdds,a3

 move.l #PLR3_ObsInLine,a1
 move.l ObjectData,a0
 move.l #PLR3_ObjDists,a2
findclosestinline3

 tst.w (a0)
 blt outofline3

 cmp.b #3,16(a0)
 beq notlinedup3

 tst.b (a1)+
 beq.s notlinedup3
 btst #1,17(a0)
 beq.s notlinedup3
 tst.w 12(a0)
 blt.s notlinedup3
 move.b 16(a0),d6
 btst d6,d7
 beq.s notlinedup3
 
 tst.b numlives(a0)
 beq.s notlinedup3
 move.w (a0),d5
 move.w (a2,d5.w*2),d6
 move.w 4(a0),d2
 ext.l d2
 asl.l #7,d2
 sub.l PLR3_yoff,d2
 move.l d2,d3
 bge.s .oknotneg
 neg.l d2
.oknotneg:
 divs #44,d2
 cmp.w d6,d2
 bgt.s notlinedup3
 
 cmp.w d6,d1
 blt.s notlinedup3
 move.w d6,d1
 move.l a0,a4
 
; We have a closer enemy lined up.
 move.l d3,targetydiff 
 move.w d5,d0

notlinedup3:
 add.w #64,a0
 bra findclosestinline3

outofline3:

 
 move.w d1,targdist
 
 move.l targetydiff,d5
 sub.l PLR3_height,d5
 add.l #18*256,d5
 move.w d1,closedist
 
 move.w BulletSpd,d2
 asr.w d2,d1
 tst.w d1
 bgt.s okdistthing3
 moveq #1,d1
okdistthing3
 divs d1,d5
 move.w d5,bulyspd

 move.w AmmoInMyGun,d2
 move.w G_BulletsPerShot(a6),d1
 cmp.w d1,d2
 bge.s .okcanshoot

 move.l PLR3_Obj,a2
 move.w (a2),d0
 move.l #ObjRotated,a2
 move.l (a2,d0.w*8),Noisex
 move.w #300,Noisevol
 move.w #100,PLAYERTHREENOISEVOL
 move.w #12,Samplenum
 clr.b notifplaying
 move.b #$fb,IDNUM
 jsr MakeSomeNoise
 
 rts

.okcanshoot:

 cmp.b #'s',mors
 bne.s .notplr3
 move.l PLR3_Obj,a2
 move.w #1,ObjTimer+128(a2)
.notplr3:

 move.w G_DelayBetweenShots(a6),PLR3_TimeToShoot

 move.b MaxFrame,PLR3_GunFrame
 sub.w d1,d2

 move.l #PLAYERTHREEAMMO,a2
 add.w BULTYPE,a2
 add.w BULTYPE,a2
 move.w d2,(a2)

 move.l PLR3_Obj,a2
 move.w (a2),d2
 move.l #ObjRotated,a2
 move.l (a2,d2.w*8),Noisex
 move.w #100,PLAYERTHREENOISEVOL
 move.w #300,Noisevol
 move.w G_SoundEffect(a6),Samplenum
 move.b #2,chanpick
 clr.b notifplaying
 movem.l d0/a0/d5/d6/d7/a6/a4/a5,-(a7)
 move.b #$fb,IDNUM
 jsr MakeSomeNoise
 movem.l (a7)+,d0/a0/d5/d6/d7/a6/a4/a5

 tst.w d0
 blt nothingtoshoot3

 tst.l B_Gravity(a5)
 beq.s .notuseaim
 move.w PLR3_AIMSPD,d2
 move.w #8,d1
 sub.w BulletSpd,d1
 asr.w d1,d2
 move.w d2,bulyspd
.notuseaim

 tst.w B_VisibleOrInstant+2(a5)
 beq PLR3FIREBULLET
 
; instant effect: check for hitting:

 move.w G_BulletsPerShot(a6),d7

FIREBULLETS3:

 movem.l a0/a1/d7/d0/a4/a5,-(a7)
 jsr GetRand
 
 move.l ObjectPoints,a1
 move.w (a4),d1
 lea (a1,d1.w*8),a1
 
 and.w #$7fff,d0
 move.w (a1),d1
 sub.w PLR3_xoff,d1
 muls d1,d1
 move.w 4(a1),d2
 sub.w PLR3_zoff,d2
 muls d2,d2
 add.l d2,d1
 asr.l #6,d1
 ext.l d0
 asl.l #1,d0
 cmp.l d1,d0
 bgt.s .hitplr
 
 movem.l (a7)+,a0/a1/d7/d0/a5/a4
 move.l d0,-(a7)
 bsr PLR3MISSINSTANT
 move.l (a7)+,d0
 
 bra.s .missplr
.hitplr: 

 movem.l (a7)+,a0/a1/d7/d0/a5/a4
 move.l d0,-(a7)
 bsr PLR3HITINSTANT
 move.l (a7)+,d0

.missplr:

 subq #1,d7
 bgt.s FIREBULLETS3
 
 rts
 
nothingtoshoot3:
 move.w PLR3_AIMSPD,d0
 move.w #8,d1
 sub.w BulletSpd,d1
 asr.w d1,d0
 move.w d0,bulyspd
 tst.w B_VisibleOrInstant+2(a5)
 beq PLR3FIREBULLET
 
 move.w #0,bulyspd

 move.w PLR3_xoff,oldx
 move.w PLR3_zoff,oldz
 move.w PLR3_sinval,d0
 asr.w #7,d0
 add.w oldx,d0
 move.w d0,newx
 move.w PLR3_cosval,d0
 asr.w #7,d0
 add.w oldz,d0
 move.w d0,newz
 move.l PLR3_yoff,d0
 add.l #10*128,d0
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
 move.l PLR3_Roompt,objroom
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
 move.b BULTYPE+1,shotsize(a0)
 move.b #0,shotanim(a0)
 
 move.l objroom,a1
 move.w (a1),12(a0)
 st worry(a0)
 move.l wallhitheight,d0
 move.l d0,accypos(a0)
 asr.l #7,d0
 move.w d0,4(a0)

 rts
 
PLR3_nofire:

 rts


BulletSpd: dc.w 0

*******************************************************
 
tempyoff: dc.l 0
tempStoodInTop: dc.w 0
tempxdir: dc.w 0
tempzdir: dc.w 0
tempgun: dc.w 0
tstfire: dc.w 0
PLR1FIREBULLET:

 move.l #%1100011,d7
 
 move.b MaxFrame,PLR1_GunFrame
 move.l PLR1_Obj,a2
 move.w G_BulletsPerShot(a6),d5
 
 move.w d5,d6
 subq #1,d6
 muls #128,d6
 neg.w d6
 add.w tempangpos,d6
 and.w #8190,d6
 
 bra firefive

PLR3FIREBULLET:

 move.l #%110011,d7
 
 move.b MaxFrame,PLR3_GunFrame
 move.l PLR3_Obj,a2
 move.w G_BulletsPerShot(a6),d5
 
 move.w d5,d6
 subq #1,d6
 muls #128,d6
 neg.w d6
 add.w tempangpos,d6
 and.w #8190,d6
 
 bra firefive

 
PLR2FIREBULLET:
 move.l #%1010011,d7

 move.b MaxFrame,PLR2_GunFrame
 move.l PLR2_Obj,a2
 move.w G_BulletsPerShot(a6),d5
 
 move.w d5,d6
 subq #1,d6
 muls #128,d6
 neg.w d6
 add.w tempangpos,d6
 and.w #8190,d6

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
 move.w B_Gravity+2(a5),shotgrav(a0)
 move.b B_BounceOffWalls+3(a5),shotflags(a0)
 move.b B_BounceOffFloors+3(a5),shotflags+1(a0)
 
 move.w bulyspd,d0
 
 cmp.w #20*128,d0
 blt.s .okdownspd
 move.w #20*128,d0
.okdownspd:

 cmp.w #-20*128,d0
 bgt.s .okupspd
 move.w #-20*128,d0
.okupspd:

; add.w G_InitialYVel(a6),d0

 move.w d0,bulyspd

 move.l #ObjRotated,a2
 move.b BULTYPE+1,shotsize(a0)
 move.b B_DamageToTarget+3(a5),shotpower(a0)

 move.l ObjectPoints,a1
 move.w (a0),d1
 lea (a1,d1.w*8),a1
 move.w tempxoff,(a1)
 move.w tempzoff,4(a1)

 move.l #SineTable,a1
 move.w (a1,d6.w),d0
 ext.l d0
 add.w #2048,a1
 move.w (a1,d6.w),d2
 ext.l d2

 add.w #256,d6
 and.w #8190,d6
 
 move.w BulletSpd,d1
 asl.l d1,d0
 move.l d0,shotxvel(a0)
 ext.l d2
 asl.l d1,d2
 move.b #2,16(a0)
 move.l d2,shotzvel(a0)
 move.w bulyspd,shotyvel(a0)
 move.b tempStoodInTop,ObjInTop(a0)
 move.w #0,shotlife(a0)
 move.l d7,EnemyFlags(a0)
 move.l tempRoompt,a2
 move.w (a2),12(a0)
 move.l tempyoff,d0
 add.l #20*128,d0
 move.l d0,accypos(a0)
 st worry(a0)
 asr.l #7,d0
 move.w d0,4(a0)
 
 sub.w #1,d5
 bgt firefive
 
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

 move.b #2,16(a0)
 move.l ObjectPoints,a1
 move.w (a0),d2
 move.l (a1,d0.w*8),(a1,d2.w*8)
 move.l 4(a1,d0.w*8),4(a1,d2.w*8)
 move.b #1,shotstatus(a0)
 move.w #0,shotgrav(a0)
 move.b BULTYPE+1,shotsize(a0)
 move.b #0,shotanim(a0)
 
 move.w 4(a4),d1
 ext.l d1
 asl.l #7,d1
 move.l d1,accypos(a0)
 move.w 12(a4),12(a0)
 st worry(a0)
 move.w 4(a4),4(a0)
 
 move.w B_DamageToTarget+2(a5),d0
 add.b d0,damagetaken(a4)
 
 move.w tempxdir,d1
 ext.l d1
 asl.l #3,d1
 swap d1
 move.w d1,ImpactX(a4)
 move.w tempzdir,d1
 ext.l d1
 asl.l #3,d1
 swap d1
 move.w d1,ImpactZ(a4)

 rts

PLR1MISSINSTANT: 

 move.w PLR1_xoff,oldx
 move.w PLR1_zoff,oldz
 move.l PLR1_yoff,d1
 add.l #10*128,d1
 move.l d1,oldy

 move.w (a4),d0
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

 move.b #2,16(a0)
 move.l ObjectPoints,a1
 move.w (a0),d2
 move.w newx,(a1,d2.w*8)
 move.w newz,4(a1,d2.w*8)
 move.b #1,shotstatus(a0)
 move.w #0,shotgrav(a0)
 move.b BULTYPE+1,shotsize(a0)
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

 move.b #2,16(a0)
 move.l ObjectPoints,a1
 move.w (a0),d2
 move.l (a1,d0.w*8),(a1,d2.w*8)
 move.l 4(a1,d0.w*8),4(a1,d2.w*8)
 move.b #1,shotstatus(a0)
 move.w #0,shotgrav(a0)
 move.b BULTYPE+1,shotsize(a0)
 move.b #0,shotanim(a0)
 
 move.w 4(a4),d1
 ext.l d1
 asl.l #7,d1
 move.l d1,accypos(a0)
 move.w 12(a4),12(a0)
 st worry(a0)
 move.w 4(a4),4(a0)
 
 move.w B_DamageToTarget+2(a5),d0
 add.b d0,damagetaken(a4)

 move.w tempxdir,d1
 ext.l d1
 asl.l #3,d1
 swap d1
 move.w d1,ImpactX(a4)
 move.w tempzdir,d1
 ext.l d1
 asl.l #3,d1
 swap d1
 move.w d1,ImpactZ(a4)

 rts

PLR2MISSINSTANT: 

 move.w PLR2_xoff,oldx
 move.w PLR2_zoff,oldz
 move.l PLR2_yoff,d1
 add.l #10*128,d1
 move.l d1,oldy

 move.w (a4),d0
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

 move.b #2,16(a0)
 move.l ObjectPoints,a1
 move.w (a0),d2
 move.w newx,(a1,d2.w*8)
 move.w newz,4(a1,d2.w*8)
 move.b #1,shotstatus(a0)
 move.w #0,shotgrav(a0)
 move.b BULTYPE+1,shotsize(a0)
 move.b #0,shotanim(a0)
 
 move.l objroom,a1
 move.w (a1),12(a0)
 st worry(a0)
 move.l newy,d1
 move.l d1,accypos(a0)
 asr.l #7,d1
 move.w d1,4(a0)
 
 rts



PLR3HITINSTANT:

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

 move.b #2,16(a0)
 move.l ObjectPoints,a1
 move.w (a0),d2
 move.l (a1,d0.w*8),(a1,d2.w*8)
 move.l 4(a1,d0.w*8),4(a1,d2.w*8)
 move.b #1,shotstatus(a0)
 move.w #0,shotgrav(a0)
 move.b BULTYPE+1,shotsize(a0)
 move.b #0,shotanim(a0)
 
 move.w 4(a4),d1
 ext.l d1
 asl.l #7,d1
 move.l d1,accypos(a0)
 move.w 12(a4),12(a0)
 st worry(a0)
 move.w 4(a4),4(a0)
 
 move.w B_DamageToTarget+2(a5),d0
 add.b d0,damagetaken(a4)

 move.w tempxdir,d1
 ext.l d1
 asl.l #3,d1
 swap d1
 move.w d1,ImpactX(a4)
 move.w tempzdir,d1
 ext.l d1
 asl.l #3,d1
 swap d1
 move.w d1,ImpactZ(a4)

 rts

PLR3MISSINSTANT: 

 move.w PLR3_xoff,oldx
 move.w PLR3_zoff,oldz
 move.l PLR3_yoff,d1
 add.l #10*128,d1
 move.l d1,oldy

 move.w (a4),d0
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
 move.l PLR3_Roompt,objroom
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

 move.b #2,16(a0)
 move.l ObjectPoints,a1
 move.w (a0),d2
 move.w newx,(a1,d2.w*8)
 move.w newz,4(a1,d2.w*8)
 move.b #1,shotstatus(a0)
 move.w #0,shotgrav(a0)
 move.b BULTYPE+1,shotsize(a0)
 move.b #0,shotanim(a0)
 
 move.l objroom,a1
 move.w (a1),12(a0)
 st worry(a0)
 move.l newy,d1
 move.l d1,accypos(a0)
 asr.l #7,d1
 move.w d1,4(a0)
 
 rts
