
gotgun: dc.w 0

ANIMPOINTER: dc.l 0

ASKFORPROT:
 include "ab3:source_4000/askforprot.s"

ALIENBRIGHT: dc.w 0

ItsAnAlien:

 tst.b NASTY
 beq.s .NONASIES

 move.l #32*256,StepUpVal
 move.l #32*256,StepDownVal
 
; move.l #4,deadframe
; move.w #0,screamsound
; move.w #160,nasheight
 
 move.w 12(a0),GraphicRoom(a0)
 move.w 12(a0),d2
 bge.s .okalive

 
 rts


.NONASIES:
 move.w #-1,12(a0)
 rts
 
.okalive:
 
 move.l ZoneAdds,a5
 move.l (a5,d2.w*4),d0
 add.l LEVELDATA,d0
 move.l d0,objroom
 
 move.l d0,a6
 move.b ToEcho(a6),ALIENECHO

 moveq #0,d0
 move.l LINKFILE,a6
 move.l a6,a5
 move.b TypeOfThing(a0),d0
 add.l #AlienBrights,a5
 move.w (a5,d0.w*2),d1
 neg.w d1
 move.w d1,ALIENBRIGHT
 muls #A_AnimLen,d0
 add.l #AlienAnimData,a6
 add.l d0,a6

 move.l a6,ANIMPOINTER

 move.l LINKFILE,a1
 move.l a1,a2
 add.l #AlienShotOffsets,a2
 
 lea AlienStats(a1),a1
 moveq #0,d0
 move.b TypeOfThing(a0),d0
 
 move.l (a2,d0.w*8),d1
 asl.l #7,d1
 move.l d1,SHOTYOFF
 move.w 6(a2,d0.w*8),d1
 neg.w d1
 asl.w #2,d1
 move.w d1,SHOTOFFMULT
 
 muls #AlienStatLen,d0
 add.w d0,a1 ; ptr to alien stats

 move.w A_Height(a1),d0
 ext.l d0
 asl.l #7,d0
 move.l d0,thingheight
 
 move.w A_Auxilliary(a1),AUXOBJ
 
 move.w (a0),CollId

 move.b 1(a1),VECOBJ
 move.w A_ReactionTime(a1),REACTIONTIME
 move.w A_DefBeh(a1),DEFAULTMODE
 move.w A_ResBeh(a1),RESPONSEMODE
 move.w A_RetBeh(a1),RETREATMODE
 move.w A_FolBeh(a1),FOLLOWUPMODE
 move.w A_DefSpeed(a1),prowlspeed
 move.w A_ResSpeed(a1),responsespeed
 move.w A_RetSpeed(a1),retreatspeed
 move.w A_FolSpeed(a1),followupspeed
 move.w A_FolTimeout(a1),FOLLOWUPTIMER
 move.w A_WallCollDist(a1),d0
 move.b diststowall+1(pc,d0.w*4),awayfromwall
 move.w diststowall+2(pc,d0.w*4),extlen
  
 jsr AIROUTINE

 rts
 
ALIENECHO: dc.w 0
 
diststowall:
 dc.w 0,40
 dc.w 1,80
 dc.w 2,160
 
ItsAnObject:

 move.l LINKFILE,a1
 lea ObjectStats(a1),a1
 moveq #0,d0
 move.b TypeOfThing(a0),d0
 muls #ObjectStatLen,d0
 add.w d0,a1 ; pointer to obj stats.

 move.l a1,StatPointer

 move.w (a1),d0
 cmp.w #1,d0
 blt Collectable
 beq Activatable
 cmp.w #3,d0
 blt Destructable
 beq Decoration

 rts
 
GUNHELD:

; This is a player gun in his hand.

 move.l a1,a2
 jsr ACTANIMOBJ

 rts
 
Collectable:

 move.w 12(a0),d0
 bge.s .okinroom
 rts
.okinroom

 tst.b WhichAnim(a0)
 bne.s GUNHELD

 move.w d0,GraphicRoom(a0)
 
 tst.b NASTY
 beq.s .nolocks
 move.l DoorsHeld(a0),d1
 or.l d1,DoorLocks
.nolocks:
 tst.b worry(a0)
 bne.s .worryaboot
 rts
.worryaboot:

 and.b #$80,worry(a0)
 move.l a1,a2

 move.l ZoneAdds,a1
 move.l (a1,d0.w*4),a1
 add.l LEVELDATA,a1

 tst.w O_FloorCeiling(a2)
 beq.s .onfloor
 move.l ToZoneRoof(a1),d0
 tst.b ObjInTop(a0)
 beq.s .okinbotc
 move.l ToUpperRoof(a1),d0
.okinbotc:

 bra.s .onceiling

.onfloor
 move.l ToZoneFloor(a1),d0
 tst.b ObjInTop(a0)
 beq.s .okinbot
 move.l ToUpperFloor(a1),d0
.okinbot:
.onceiling

 asr.l #7,d0
 move.w d0,4(a0)

 bsr DEFANIMOBJ
 
 bsr CHECKNEARBYONE
 tst.b d0
 beq.s .NotCollected1

 bsr PLR1CollectObject
 move.w #-1,12(a0)
 clr.b worry(a0)

.NotCollected1

 cmp.b #'n',mors
 beq.s .NotCollected2
 bsr CHECKNEARBYTWO
 tst.b d0
 beq.s .NotCollected2

 bsr PLR2CollectObject
 move.w #-1,12(a0)
 clr.b worry(a0)

.NotCollected2
 

 rts
 
Activatable:

 move.w 12(a0),d0
 bge.s .okinroom
 rts
.okinroom

 tst.b WhichAnim(a0)
 bne ACTIVATED

 move.w d0,GraphicRoom(a0)
 tst.b NASTY
 beq.s .nolocks
 move.l DoorsHeld(a0),d1
 or.l d1,DoorLocks
.nolocks
 tst.b worry(a0)
 bne.s .worryaboot
 rts
.worryaboot:

 and.b #$80,worry(a0)
 move.l a1,a2

 move.l ZoneAdds,a1
 move.l (a1,d0.w*4),a1
 add.l LEVELDATA,a1

 tst.w O_FloorCeiling(a2)
 beq.s .onfloor
 move.l ToZoneRoof(a1),d0
 tst.b ObjInTop(a0)
 beq.s .okinbotc
 move.l ToUpperRoof(a1),d0
.okinbotc:

 bra.s .onceiling

.onfloor
 move.l ToZoneFloor(a1),d0
 tst.b ObjInTop(a0)
 beq.s .okinbot
 move.l ToUpperFloor(a1),d0
.okinbot:
.onceiling

 asr.l #7,d0
 move.w d0,4(a0)

 bsr DEFANIMOBJ
 
 bsr CHECKNEARBYONE
 tst.b d0
 beq.s .NotActivated1

 tst.b p1_spctap
 beq.s .NotActivated1

; The player has pressed the spacebar
; within range of the object.

 bsr PLR1CollectObject


 move.w #0,ObjTimer(a0)
 st WhichAnim(a0)
 move.w #0,SecTimer(a0)
 rts

.NotActivated1:


 cmp.b #'n',mors
 beq .NotActivated2
 bsr CHECKNEARBYTWO
 tst.b d0
 beq.s .NotActivated2

 tst.b p2_spctap
 beq.s .NotActivated2

; The player has pressed the spacebar
; within range of the object.
 bsr PLR2CollectObject


 move.w #0,ObjTimer(a0)
 st WhichAnim(a0)
 move.w #0,SecTimer(a0)
 rts

.NotActivated2:

 rts
 
ACTIVATED:

 move.w d0,GraphicRoom(a0)
; move.l DoorsHeld(a0),d1
; or.l d1,DoorLocks
 tst.b worry(a0)
 bne.s .worryaboot
 rts
.worryaboot:

 and.b #$80,worry(a0)
 move.l a1,a2

 move.l ZoneAdds,a1
 move.l (a1,d0.w*4),a1
 add.l LEVELDATA,a1

 tst.w O_FloorCeiling(a2)
 beq.s .onfloor
 move.l ToZoneRoof(a1),d0
 tst.b ObjInTop(a0)
 beq.s .okinbotc
 move.l ToUpperRoof(a1),d0
.okinbotc:

 bra.s .onceiling

.onfloor
 move.l ToZoneFloor(a1),d0
 tst.b ObjInTop(a0)
 beq.s .okinbot
 move.l ToUpperFloor(a1),d0
.okinbot:
.onceiling

 asr.l #7,d0
 move.w d0,4(a0)

 bsr ACTANIMOBJ
 
 move.w TempFrames,d0
 add.w d0,SecTimer(a0)
 move.w O_ActiveTimeout(a2),d0
 blt.s .nottimeout
 
 cmp.w SecTimer(a0),d0
 ble.s .DEACTIVATE
 
.nottimeout:
 
 bsr CHECKNEARBYONE
 tst.b d0
 beq.s .NotDeactivated1

 tst.b p1_spctap
 beq.s .NotDeactivated1

; The player has pressed the spacebar
; within range of the object.

.DEACTIVATE:

 move.w #0,ObjTimer(a0)
 clr.b WhichAnim(a0)
 rts

.NotDeactivated1:

 cmp.b #'n',mors
 beq.s .NotDeactivated2

 bsr CHECKNEARBYTWO
 tst.b d0
 beq.s .NotDeactivated2

 tst.b p2_spctap
 beq.s .NotDeactivated2

; The player has pressed the spacebar
; within range of the object.

 move.w #0,ObjTimer(a0)
 clr.b WhichAnim(a0)
 rts

.NotDeactivated2:

 rts
 
Destructable:

 move.l LINKFILE,a3
 add.l #ObjectStats,a3
 moveq #0,d0
 move.b TypeOfThing(a0),d0
 muls #ObjectStatLen,d0
 add.l d0,a3

 moveq #0,d0
 move.b damagetaken(a0),d0
 cmp.w O_HitPoints(a3),d0
 blt StillHere
 
 tst.b numlives(a0)
 beq.s .alreadydead

 cmp.b #'n',mors
 bne.s .notext

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
 
 move.w #0,ObjTimer(a0)
 
.alreadydead
 
 move.b #0,numlives(a0)

 move.w 12(a0),d0
 bge.s .okinroom
 rts
.okinroom

 tst.b worry(a0)
 bne.s .worryaboot
 rts
.worryaboot:

 move.l a1,a2

 move.l ZoneAdds,a1
 move.l (a1,d0.w*4),a1
 add.l LEVELDATA,a1
 
 tst.w O_FloorCeiling(a2)
 beq.s .onfloor
 move.l ToZoneRoof(a1),d0
 tst.b ObjInTop(a0)
 beq.s .okinbotc
 move.l ToUpperRoof(a1),d0
.okinbotc:

 bra.s .onceiling

.onfloor
 move.l ToZoneFloor(a1),d0
 tst.b ObjInTop(a0)
 beq.s .okinbot
 move.l ToUpperFloor(a1),d0
.okinbot:
.onceiling

 asr.l #7,d0
 move.w d0,4(a0)

 bsr ACTANIMOBJ
 
 rts
 
StillHere:
 move.w 12(a0),d0
 bge.s .okinroom
 rts
.okinroom
 move.b #1,numlives(a0)

 tst.b NASTY
 beq.s .nolocks
 move.l DoorsHeld(a0),d1
 or.l d1,DoorLocks
.nolocks

 tst.b worry(a0)
 bne.s .worryaboot
 rts
.worryaboot:

 movem.l d0-d7/a0-a6,-(a7)

 move.w 12(a0),d2
 move.l ZoneAdds,a5
 move.l (a5,d2.w*4),d0
 add.l LEVELDATA,d0
 move.l d0,objroom

 move.w (a0),d0
 move.l ObjectPoints,a1
 move.w (a1,d0.w*8),newx
 move.w 4(a1,d0.w*8),newz

 jsr LOOKFORPLAYER1
 movem.l (a7)+,d0-d7/a0-a6

Decoration

 move.w 12(a0),d0
 bge.s .okinroom
 rts
.okinroom

 tst.b worry(a0)
 bne.s .worryaboot
 rts
.worryaboot:

 
intodeco:
 move.l a1,a2

 move.l ZoneAdds,a1
 move.l (a1,d0.w*4),a1
 add.l LEVELDATA,a1
 
 tst.w O_FloorCeiling(a2)
 beq.s .onfloor
 move.l ToZoneRoof(a1),d0
 tst.b ObjInTop(a0)
 beq.s .okinbotc
 move.l ToUpperRoof(a1),d0
.okinbotc:

 bra.s .onceiling

.onfloor
 move.l ToZoneFloor(a1),d0
 tst.b ObjInTop(a0)
 beq.s .okinbot
 move.l ToUpperFloor(a1),d0
.okinbot:
.onceiling

 asr.l #7,d0
 move.w d0,4(a0)

 bsr DEFANIMOBJ
 
 rts

PLR1CollectObject:

 cmp.b #'n',mors
 bne.s .nodeftext

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
 
 bra .nodeftext
 
.notext:

 cmp.b #'s',mors
 beq.s .nodeftext

 moveq #0,d2
 move.b TypeOfThing(a0),d2
 move.l LINKFILE,a4
 add.l #ObjectNames,a4
 muls #20,d2
 add.l d2,a4
 move.l #TEMPSCROLL,a2
 move.w #19,d2
 
.copyname:
 move.b (a4)+,d3
 bne.s .oklet
 move.b #32,d3
.oklet:
 move.b d3,(a2)+
 
 dbra d2,.copyname
 
 move.l #TEMPSCROLL,d0
 jsr SENDMESSAGENORET
 
.nodeftext:

 move.l LINKFILE,a2
 lea AmmoGive(a2),a3
 add.l #GunGive,a2
 moveq #0,d0
 move.b TypeOfThing(a0),d0
 move.w d0,d1
 muls #AmmoGiveLen,d0
 muls #GunGiveLen,d1
 add.w d1,a2
 add.w d0,a3

; Check if player has max of all ammo types:
 
 bsr CHECKPLAYERGOT
 tst.b d0
 beq dontcollect

 move.w #21,d0
 move.l #PLAYERONEHEALTH,a1
GiveAmmo:
 move.w (a3)+,d1
 add.w d1,(a1)+
 dbra d0,GiveAmmo

 move.w #11,d0
 move.l #PLAYERONESHIELD,a1
GiveGuns:
 move.w (a2)+,d1
 or.w d1,(a1)+
 dbra d0,GiveGuns
 
 move.l LINKFILE,a3
 add.l #ObjectStats,a3
 moveq #0,d0
 move.b TypeOfThing(a0),d0
 muls #ObjectStatLen,d0
 add.l d0,a3
 
 move.w O_SoundEffect(a3),d0
 blt.s .nosoundmake
 
 movem.l d0-d7/a0-a6,-(a7)
 move.w d0,Samplenum
 clr.b notifplaying
 move.w (a0),IDNUM
 move.w #80,Noisevol
 move.l #ObjRotated,a1
 move.w (a0),d0
 lea (a1,d0.w*8),a1
 move.l (a1),Noisex
 jsr MakeSomeNoise
 movem.l (a7)+,d0-d7/a0-a6
.nosoundmake
 

dontcollect:
 rts 

PLR2CollectObject:

 move.l LINKFILE,a2
 lea AmmoGive(a2),a3
 add.l #GunGive,a2
 moveq #0,d0
 move.b TypeOfThing(a0),d0
 move.w d0,d1
 muls #AmmoGiveLen,d0
 muls #GunGiveLen,d1
 add.w d1,a2
 add.w d0,a3

; Check if player has max of all ammo types:
 
 bsr CHECKPLAYERGOT
 tst.b d0
 beq dontcollect2

 move.w #21,d0
 move.l #PLAYERTWOHEALTH,a1
GiveAmmo2:
 move.w (a3)+,d1
 add.w d1,(a1)+
 dbra d0,GiveAmmo2

 move.w #11,d0
 move.l #PLAYERTWOSHIELD,a1
GiveGuns2:
 move.w (a2)+,d1
 or.w d1,(a1)+
 dbra d0,GiveGuns2
 
 move.l LINKFILE,a3
 add.l #ObjectStats,a3
 moveq #0,d0
 move.b TypeOfThing(a0),d0
 muls #ObjectStatLen,d0
 add.l d0,a3
 
 move.w O_SoundEffect(a3),d0
 blt.s .nosoundmake
 
 movem.l d0-d7/a0-a6,-(a7)
 move.w d0,Samplenum
 clr.b notifplaying
 move.w (a0),IDNUM
 move.w #80,Noisevol
 move.l #ObjRotated,a1
 move.w (a0),d0
 lea (a1,d0.w*8),a1
 move.l (a1),Noisex
 move.b #0,Echo
 jsr MakeSomeNoise
 movem.l (a7)+,d0-d7/a0-a6
.nosoundmake
 
 move.w #-1,12(a0)
 clr.b worry(a0)

dontcollect2:
 rts 

PLAYERONEHEALTH:
  dc.w 0
PLAYERONEFUEL:
  dc.w 0
PLAYERONEAMMO:
 ds.w 20

PLAYERONESHIELD:
 dc.w 0
PLAYERONEJETPACK:
 dc.w 0
PLAYERONEGUNS:
 dcb.w 10,0

PLAYERTWOHEALTH:
  dc.w 0
PLAYERTWOFUEL:
  dc.w 0
PLAYERTWOAMMO:
 ds.w 20

PLAYERTWOSHIELD:
 dc.w 0
PLAYERTWOJETPACK:
 dc.w 0
PLAYERTWOGUNS:
 dcb.w 10,0

  
CHECKPLAYERGOT:
 move.b #1,d0
 rts
 
CHECKNEARBYONE:

 move.l StatPointer,a2
 move.b PLR1_StoodInTop,d0
 move.b ObjInTop(a0),d1
 eor.b d0,d1
 bne .NotSameZone

 move.w PLR1_xoff,oldx
 move.w PLR1_zoff,oldz
 move.w PLR1_Zone,d7
 
 cmp.w 12(a0),d7
 bne .NotSameZone
 
 move.l PLR1_yoff,d7
 move.l PLR1_height,d6
 asr.l #1,d6
 add.l d6,d7
 asr.l #7,d7
 sub.w 4(a0),d7
 bgt.s .okpos
 neg.w d7
.okpos

 cmp.w O_ColBoxHeight(a2),d7
 bgt .NotSameZone
 
 move.w (a0),d0
 move.l ObjectPoints,a1
 move.w (a1,d0.w*8),newx
 move.w 4(a1,d0.w*8),newz
 move.w O_ColBoxRad(a2),d2
 muls d2,d2
 jsr CheckHit
 move.b hitwall,d0
 rts
.NotSameZone
 moveq #0,d0
 rts 

CHECKNEARBYTWO:

 move.l StatPointer,a2
 move.b PLR2_StoodInTop,d0
 move.b ObjInTop(a0),d1
 eor.b d0,d1
 bne .NotSameZone

 move.w PLR2_xoff,oldx
 move.w PLR2_zoff,oldz
 move.w PLR2_Zone,d7
 
 cmp.w 12(a0),d7
 bne .NotSameZone
 
 move.l PLR2_yoff,d7
 move.l PLR2_height,d6
 asr.l #1,d6
 add.l d6,d7
 asr.l #7,d7
 sub.w 4(a0),d7
 bgt.s .okpos
 neg.w d7
.okpos

 cmp.w O_ColBoxHeight(a2),d7
 bgt .NotSameZone
 
 move.w (a0),d0
 move.l ObjectPoints,a1
 move.w (a1,d0.w*8),newx
 move.w 4(a1,d0.w*8),newz
 move.w O_ColBoxRad(a2),d2
 muls d2,d2
 jsr CheckHit
 move.b hitwall,d0
 rts
.NotSameZone
 moveq #0,d0
 rts 

StatPointer: dc.l 0
 
DEFANIMOBJ:

 move.l LINKFILE,a3
 lea ObjectDefAnims(a3),a3
 moveq #0,d0
 move.b TypeOfThing(a0),d0
 muls #O_AnimSize,d0
 add.w d0,a3
 move.w ObjTimer(a0),d0
 
 move.w d0,d1
 add.w d0,d0
 asl.w #2,d1
 add.w d1,d0	;*6
 
 cmp.w #1,O_GFXType(a2)
 blt.s .bitmap
 beq.s .vector
 
.glare:
 move.l #0,8(a0)
 move.b (a3,d0.w),d1
 ext.w d1
 neg.w d1
 move.w d1,8(a0)
 move.b 1(a3,d0.w),11(a0)
 move.w 2(a3,d0.w),6(a0)
 
 move.b 4(a3,d0.w),d1 
 ext.w d1
 add.w d1,d1
 add.w d1,4(a0)
 
 moveq #0,d1
 move.b 5(a3,d0.w),d1
 move.w d1,ObjTimer(a0)
 rts
 
.vector:

 move.l #0,8(a0)
 move.b (a3,d0.w),9(a0)
 move.b 1(a3,d0.w),11(a0)
 
 move.w #$ffff,6(a0)
 move.b 4(a3,d0.w),d1 
 ext.w d1
 add.w d1,d1
 add.w d1,4(a0)
 move.w 2(a3,d0.w),d1
 add.w d1,Facing(a0)

 moveq #0,d1
 move.b 5(a3,d0.w),d1
 move.w d1,ObjTimer(a0)
 
 rts
 
.bitmap:

 move.l #0,8(a0)
 move.b (a3,d0.w),9(a0)
 move.b 1(a3,d0.w),11(a0)
 move.w 2(a3,d0.w),6(a0)
 move.b 4(a3,d0.w),d1 
 ext.w d1
 add.w d1,d1
 add.w d1,4(a0)
 
 moveq #0,d1
 move.b 5(a3,d0.w),d1
 move.w d1,ObjTimer(a0)
 
 rts
 
ACTANIMOBJ:

 move.l LINKFILE,a3
 lea ObjectActAnims(a3),a3
 moveq #0,d0
 move.b TypeOfThing(a0),d0
 muls #O_AnimSize,d0
 add.w d0,a3
 move.w ObjTimer(a0),d0
 
 move.w d0,d1
 add.w d0,d0
 asl.w #2,d1
 add.w d1,d0	;*6
 
 cmp.w #1,O_GFXType(a2)
 blt.s .bitmap
 beq.s .vector
 
.glare:
 move.l #0,8(a0)
 move.b (a3,d0.w),d1
 ext.w d1
 neg.w d1
 move.w d1,8(a0)
 move.b 1(a3,d0.w),11(a0)
 move.w 2(a3,d0.w),6(a0)
 
 move.b 4(a3,d0.w),d1 
 ext.w d1
 add.w d1,d1
 add.w d1,4(a0)
 
 moveq #0,d1
 move.b 5(a3,d0.w),d1
 move.w d1,ObjTimer(a0)
 
 rts
 
.vector:
 move.l #0,8(a0)
 move.b (a3,d0.w),9(a0)
 move.b 1(a3,d0.w),11(a0)
 move.w #$ffff,6(a0)
 move.b 4(a3,d0.w),d1 
 ext.w d1
 add.w d1,d1
 add.w d1,4(a0)
 
 move.w 2(a3,d0.w),d1
 add.w d1,Facing(a0)

 moveq #0,d1
 move.b 5(a3,d0.w),d1
 move.w d1,ObjTimer(a0)
 
 rts
 
.bitmap:

 move.l #0,8(a0)
 move.b (a3,d0.w),9(a0)
 move.b 1(a3,d0.w),11(a0)
 move.w 2(a3,d0.w),6(a0)
 move.b 4(a3,d0.w),d1 
 ext.w d1
 add.w d1,d1
 add.w d1,4(a0)
 
 moveq #0,d1
 move.b 5(a3,d0.w),d1
 move.w d1,ObjTimer(a0)
 
 rts

 
THISPLRxoff: dc.w 0
THISPLRzoff: dc.w 0
 
ViewpointToDraw:
; Calculate which side to display:

; move.l ObjectPoints,a1
; move.w (a0),d1
; lea (a1,d1.w*8),a1	; ptr to points 
 
; move.w (a1),oldx
; move.w 4(a1),oldz
; move.w THISPLRxoff,newx
; move.w THISPLRzoff,newz
; move.w #64,speed
; move.w #-60,Range
; movem.l a0/a1,-(a7)
; jsr HeadTowards
; movem.l (a7)+,a0/a1
; 
; move.w newx,d0
; sub.w oldx,d0
; move.w newz,d1
; sub.w oldz,d1

 move.w Facing(a0),d3
 sub.w angpos,d3 
 
; add.w #2048,d3
 and.w #8190,d3
 move.l #SineTable,a2
 move.w (a2,d3.w),d2
 adda.w #2048,a2
 move.w (a2,d3.w),d3

; move.w d0,d4
; move.w d1,d5
; muls d3,d4
; muls d2,d5
; sub.l d5,d4
; muls d3,d1
; muls d2,d0
; add.l d1,d0

 ext.l d2
 ext.l d3
 move.l d3,d0
 move.l d2,d4
 neg.l d0

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
 move.w newz,fsz

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
 move.w fsz,newz

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
 move.w fsz,newz


 rts

futurex: dc.w 0
futurez: dc.w 0

FireAtPlayer1:

 move.l ObjectPoints,a1
 move.w (a0),d1
 lea (a1,d1.w*8),a1

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
 move.b ALIENECHO,Echo
 move.b SHOTPOWER,shotpower(a5)
 movem.l a5/a1/a0,-(a7)
 move.w (a0),IDNUM
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
 
 move.l #%110010,EnemyFlags(a5)
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
 move.w (a0),IDNUM
 move.b ALIENECHO,Echo
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
 
 move.l #%110010,EnemyFlags(a5)
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