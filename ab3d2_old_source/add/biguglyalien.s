ItsABigNasty:

 move.l #20*256,StepUpVal
 move.l #50*256,thingheight

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

 move.l #3*65536,deadframe
 move.l #3*65536,8(a0)
 move.w #8,screamsound
 move.w #70,nasheight
 
 tst.b 17(a0)
 beq.s .cantseeplayer
  
 tst.w ObjTimer(a0)
 bgt.s .cantseeplayer
 
 jsr GetRand
 and.w #255,d0
 cmp.w #250,d0
 bgt.s .cantseeplayer
  
 bra .Attack_Player
 
.cantseeplayer 
 
 move.l ZoneAdds,a5
 move.l (a5,d2.w*4),d0
 add.l #LEVELDATA,d0
 move.l d0,objroom

 move.w TempFrames,d0
 sub.w d0,ObjTimer(a0)
 bgt.s .nonewdir

 tst.b 17(a0)
 beq.s .keepwandering

 bra .Attack_Player
 
.keepwandering

 jsr GetRand
 and.w #8190,d0
 move.w d0,Facing(a0)

 jsr GetRand
 and.w #15,d0
 add.w #20,d0
 move.w d0,ObjTimer(a0)

.nonewdir

 move.w (a0),d1
 move.l ObjectPoints,a1
 lea (a1,d1.w*8),a1
 move.w (a1),oldx 
 move.w 4(a1),oldz

 move.w maxspd(a0),d2
 muls TempFrames,d2
 move.w d2,speed
 move.w #20,Range

 move.w 4(a0),d0
 ext.l d0
 asl.l #7,d0
 move.l d0,newy
 
 movem.l d0/a0/a1/a3/a4/d7,-(a7)
 clr.b canshove
 move.w Facing(a0),d0
 jsr GoInDirection
 move.w #%1000000000,wallflags
 Jsr MoveObject
 movem.l (a7)+,d0/a0/a1/a3/a4/d7
 
 tst.b hitwall
 beq.s .nochangedir
 move.w #-1,ObjTimer(a0)
.nochangedir:
 
 move.l objroom,a2
 move.w (a2),12(a0)
 
 move.w newx,(a1)
 move.w newz,4(a1)

 move.w 10(a2),2(a0)
 move.l 2(a2),d0
 asr.l #7,d0
 sub.w #70,d0
 move.w d0,4(a0)

 move.b damagetaken(a0),d2
 beq .noscream
 
 sub.b d2,numlives(a0)
 bgt.s .notdeadyet

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

 move.l PLR1_Roompt,ToRoom
 move.l objroom,FromRoom
 move.w newx,oldx
 move.w newz,oldz
 move.w PLR1_xoff,newx
 move.w PLR1_zoff,newz
 jsr CanItBeSeen
 
 tst.b CanSee
 beq .carryonprowling

 move.b #1,17(a0)

.carryonprowling:
 
.thisonedead:
 rts

.Attack_Player:

 move.l ZoneAdds,a5
 move.l (a5,d2.w*4),d0
 add.l #LEVELDATA,d0
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
 move.w #80,Range
 move.w 4(a0),d0
 ext.l d0
 asl.l #7,d0
 move.l d0,newy

 movem.l d0/a0/a1/a3/a4/d7,-(a7)
 clr.b canshove
 clr.b GotThere
 jsr HeadTowards
 move.w #%1000000000,wallflags
 Jsr MoveObject
 movem.l (a7)+,d0/a0/a1/a3/a4/d7
 
 move.l objroom,a2
 move.w (a2),12(a0)
 move.w 12(a2),CurrCPt(a0)
 
 move.w newx,(a1)
 move.w newz,4(a1)
 move.w 10(a2),2(a0)
 move.l 2(a2),d0
 asr.l #7,d0
 sub.w #70,d0
 move.w d0,4(a0)
 
 move.b damagetaken(a0),d2
 beq .noscream2
 
 sub.b d2,numlives(a0)
 bgt.s .notdeadyet2

 movem.l d0-d7/a0-a6,-(a7)
 move.l (a6),Noisex
 move.w #200,Noisevol
 move.w screamsound,Samplenum
 move.b #1,chanpick
 clr.b notifplaying
 st backbeat
 move.b 1(a0),IDNUM
 jsr MakeSomeNoise
 movem.l (a7)+,d0-d7/a0-a6
 move.l deadframe,8(a0)
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

 tst.w SecTimer(a0)
 blt.s .canshoot
 move.w TempFrames,d0
 sub.w d0,SecTimer(a0)
 bra .cantshoot
.canshoot:
 move.l NastyShotData,a5
 move.w #19,d1
.findonefree
 move.w 12(a5),d0
 blt.s .foundonefree
 adda.w #64,a5
 dbra d1,.findonefree

 bra .cantshoot

.foundonefree:

 move.l (a6),Noisex
 move.w #200,Noisevol
 move.w #9,Samplenum
 move.b #1,chanpick
 clr.b notifplaying
 move.b #1,shotsize(a5)
 move.b #10,shotpower(a5)
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
 move.w #16,speed
 move.w #0,Range
 movem.l a5/a0,-(a7)
 jsr HeadTowards
 movem.l (a7)+,a5/a0
 move.w newx,d0
 move.w d0,(a2)
 sub.w oldx,d0
 move.w d0,shotxvel(a5)
 move.w newz,d0
 move.w d0,4(a2)
 sub.w oldz,d0
 move.w d0,shotzvel(a5)
 
 move.l #%00100000,EnemyFlags(a5)
 move.w 12(a0),12(a5)
 move.w 4(a0),d0
 add.w #6,d0
 move.w d0,4(a5)
 ext.l d0
 asl.l #7,d0
 move.l d0,accypos(a5)
 move.l PLR1_yoff,d1
 sub.l d0,d1
 move.w distaway,d0
 asr.w #4,d0
 bgt.s .okokokok
 moveq #1,d0
.okokokok
 divs d0,d1
 move.w d1,shotyvel(a5)
 jsr GetRand
 and.w #7,d0
 add.w #50,d0
 move.w d0,SecTimer(a0)
 
.cantshoot:
 
 tst.b GotThere
 beq.s .noteatyou

 move.b #1,chanpick
 move.w (a6),Noisex
 move.w 2(a6),Noisez
 move.w #50,Noisevol
 move.w #2,Samplenum
 st notifplaying
 move.l a0,-(a7)
 move.b 1(a0),IDNUM
 jsr MakeSomeNoise
 move.l (a7)+,a0
 
 move.l #Cheese,FacesPtr
 move.w #3,Cheese
 move.w #-1,FacesCounter
 move.w TempFrames,d0
 sub.w d0,Energy
 bra .carryonattack
.noteatyou:

 move.l PLR1_Roompt,ToRoom
 move.l objroom,FromRoom
 move.w newx,oldx
 move.w newz,oldz
 move.w PLR1_xoff,newx
 move.w PLR1_zoff,newz
 jsr CanItBeSeen
 
 tst.b CanSee
 bne .carryonattack

 move.b #0,17(a0)

.carryonattack:

 rts

