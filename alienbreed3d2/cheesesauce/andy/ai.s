Aggression: dc.w 0
Movement: dc.w 0
Cooperation: dc.w 0
GunType: dc.w 0
Ident: dc.w 0
friends: dc.l 0
enemies: dc.l 0
numfriends: dc.w 0
numenemies: dc.w 0
disttofriend: dc.l 0
disttoenemy: dc.l 0
closefriend: dc.l 0
closeenemy: dc.l 0
Armed: dc.w 0

VisibleTab: ds.l 100

AIControl:

; First need to see if any enemy are
; visible, so make a list of which
; objects are visible to this
; particular creature.

 move.l #ObjectData,a1
 move.l #VisibleTab,a2
 move.l #ZoneAdds,a3
 move.w 12(a0),d0
 move.l (a3,d0.w*4),FromRoom
 move.w (a0),d0
 move.l #ObjectPoints,a4
 move.w (a4,d0.w*8),oldx
 move.w 4(a4,d0.w*8),oldz

 move.l #$7fffffff,d0
 move.l d0,disttofriend
 move.l d0,disttoenemy
 move.w #1,numfriends
 move.w #0,numenemies

BuildVisibleList:
 tst.w (a1)
 blt BuiltList
 clr.b (a2)
 cmp.l a1,a0
 beq myself

 tst.b 16(a1)
 blt myself
 move.b Ident,d0
; cmp.b 16(a1),d0
; beq myself
 move.w 12(a1),d0
 blt notvisible
 move.l (a3,d0.w*4),ToRoom
 move.w (a1),d0
 move.w (a4,d0.w*8),newx
 move.w 4(a4,d0.w*8),newz
 movem.l a0/a1/a2/a3/a4,-(a7)
 jsr CanItBeSeen
 movem.l (a7)+,a0/a1/a2/a3/a4
 move.b CanSee,(a2)
 beq.s notvisible

 move.b 16(a1),d0
 moveq #0,d1
 bset d0,d1
 move.l d1,d0
 and.l friends(pc),d0
 beq.s notafriend
 addq.w #1,numfriends
 move.w xdiff,d0
 move.w zdiff,d1
 muls d0,d0
 muls d1,d1
 add.l d0,d1
 cmp.l disttofriend(PC),d1
 bgt.s notclosestfriend
 move.l d1,disttofriend
 move.l a1,closefriend
notclosestfriend:

 move.l d1,2(a2)
 bra.s isafriend

notafriend:
 and.l enemies(pc),d1
 beq.s notanenemy
 addq.w #1,numenemies
 move.w xdiff,d0
 move.w zdiff,d1
 muls d0,d0
 muls d1,d1
 add.l d0,d1
 cmp.l disttoenemy(PC),d1
 bgt.s notclosestenemy
 move.l d1,disttoenemy
 move.l a1,closeenemy
notclosestenemy:

 move.l d1,2(a2)

notanenemy:
isafriend:

notvisible:

myself:
 adda.w #64,a1
 addq #6,a2
 bra BuildVisibleList

BuiltList: 

 tst.w numenemies
 beq NonCombatant

Combatant:

* The thing can see some enemies
* so do something about it, depending
* upon aggression, movement and
* cooperation stats.

 move.w Aggression,d0
 move.w Movement,d1
 move.w Cooperation,d2
 move.w numenemies,d3
 sub.w numfriends,d3 
 
* What does the thing do?
* If very unaggressive, or 
* outnumbered, head for
* the last place it could see no
* enemy, and shoot if armed.

* If medium aggression and not
* outnumbered, run towards and
* attack the enemy (unarmed) or stand
* and shoot (armed)

* If very high aggression, run
* towards and attack the enemy, if
* no gun, otherwise move forward
* shooting.

 cmp.w #10,d0
 ble CNA
 cmp.w #20,d0
 bgt CA
 tst.w d3
 bgt CNA
 ble CA
 rts

CA:

; The thing is combatant and very 
; aggressive.
; If it is cooperative it will only
; attack if alone, otherwise it will
; follow its leader.

 cmp.w #1,numfriends
 ble.s mustattack
 cmp.w #20,d1
 bge CAC
mustattack:

 move.l closeenemy,a2
 move.w (a2),d0
 lea (a4,d0.w*8),a1
 move.w (a1),newx
 move.w 4(a1),newz
 move.w maxspd(a0),d2
 muls TempFrames,d2
 
 tst.b Armed
 beq.s .unarmed
 asr.w #1,d2
.unarmed
 move.w d2,speed
 move.w #20,Range
 move.l FromRoom,objroom
 
 movem.l a0/a1/a4,-(a7)
 
 jsr HeadTowardsAng
 jsr MoveObject
 
 movem.l (a7)+,a0/a1/a4
 

 move.w (a0),d0
 lea (a4,d0.w*8),a1
 move.w newx,(a1)
 move.w newz,4(a1)
 move.l objroom,a2
 move.w (a2),12(a0)

 tst.b Armed
 beq.s .nofire

 move.l a0,-(a7)

 move.w (a1),tempxoff
 move.w 4(a1),tempzoff
 move.w SinRet(pc),tempxdir
 move.w CosRet(pc),tempzdir
 move.w #3,tempGunNoise
 move.b #0,tempGotBigGun
 move.b #1,tempGunDamage
 move.l objroom,tempRoompt
 bsr pressedfire 
 move.l (a7)+,a0
.nofire:

 rts
 
CAC:
; the thing should stay with its
; group, but shoot if it is armed.
 
 bsr FollowOthers
 
 tst.b Armed
 beq.s .nofire

 move.l a0,-(a7)

 move.w (a1),tempxoff
 move.w 4(a1),tempzoff
 move.w SinRet(pc),tempxdir
 move.w CosRet(pc),tempzdir
 move.w #3,tempGunNoise
 move.b #0,tempGotBigGun
 move.b #1,tempGunDamage
 move.l objroom,tempRoompt
 bsr pressedfire 
 move.l (a7)+,a0
.nofire:

 rts


CNA:

; The thing is in a combatant situation
; but is extremely unaggressive. It
; should therefore retreat from the
; enemy unless cooperative enough
; and there are people around to follow.

 cmp.w #1,numfriends
 blt.s mustretreat

 cmp.w #10,d2
 bgt.s CNAC

mustretreat:

; The thing is combatant but
; unaggressive, and so should run away,
; at a speed dependant upon movement.
; The thing is so unaggressive it will
; not fire weapons if armed.

 move.l closeenemy,a2
 move.w (a2),d0
 lea (a4,d0.w*8),a1
 move.w (a1),newx
 move.w 4(a1),newz
 move.w maxspd(a0),d2
 muls TempFrames,d2
 neg.w d2
 cmp.w #10,d1
 bge.s .topspeed
 tst.w d3
 bgt.s .topspeed
 asr.w #1,d2
.topspeed
 move.w d2,speed
 move.w #20,Range
 move.l FromRoom,objroom
 
 movem.l a0/a1/a4,-(a7)
 
 jsr HeadTowardsAng
 jsr MoveObject
 
 movem.l (a7)+,a0/a1/a4
 
 move.w (a0),d0
 lea (a4,d0.w*8),a1
 move.w newx,(a1)
 move.w newz,4(a1)
 move.l objroom,a2
 move.w (a2),12(a0)

 rts

CNAC:
; Combatant, cooperative but unaggressive
; means it should head in a direction
; away from the enemy but towards
; its leader, if there is one.
; It should also not fire if armed.

; for now use followothers

 bra FollowOthers



 tst.b Armed
 beq.s .nofire

 move.l a0,-(a7)
 move.w (a1),tempxoff
 move.w 4(a1),tempzoff
 move.w SinRet(pc),tempxdir
 move.w CosRet(pc),tempzdir
 move.w #3,tempGunNoise
 move.b #0,tempGotBigGun
 move.b #1,tempGunDamage
 move.l objroom,tempRoompt
 bsr pressedfire 
 move.l (a7)+,a0
.nofire:

 rts

 
NonCombatant:

; No enemy is visible so we need
; to make the creature behave
; appropriately. This could be
; staying still and looking around,
; following noises, or wandering
; around looking for trouble.

 move.w Aggression,d0
 move.w Movement,d1
 move.w Cooperation,d2

; If high cooperation, follow the
; nearest visible leader or thing of
; equal status, otherwise
; behave independantly.

 tst.w numfriends
 beq noonetofollow
 cmp.w #10,d2
 bgt FollowOthers

noonetofollow:

 rts
 
FollowOthers:
 move.l #VisibleTab,a1
 move.l #ObjectData,a3

 move.w Lead(a0),d0
 move.w #1000,d7

findleader:
 tst.w (a3)
 blt.s nomore
 tst.b (a1)
 beq.s .notvis
 
 move.w Lead(a3),d1
 cmp.w d1,d0
 bgt.s .notgoodenough
 cmp.w d7,d1
 bgt.s .toogood
 
 move.w d1,d7
 move.l a3,a5
 
.toogood
.notgoodenough:
 
.notvis:

 adda.w #64,a3
 addq #6,a1
 bra findleader
nomore:
 
 move.l FromRoom,objroom
 move.w d7,d0
 blt noonetofollow
 
 move.w d0,tstlead
 
 move.w (a5),d0
 lea (a4,d0.w*8),a1
 move.w (a1),newx
 move.w 4(a1),newz
 move.w maxspd(a0),d2
 muls TempFrames,d2
 move.w d2,speed
 move.w #100,Range
 
 movem.l a0/a1/a4,-(a7)
 
 jsr HeadTowardsAng
 jsr MoveObject
 
 movem.l (a7)+,a0/a1/a4

 move.w (a0),d0
 lea (a4,d0.w*8),a1
 move.w newx,(a1)
 move.w newz,4(a1)
 move.l objroom,a2
 move.w (a2),12(a0)

 rts
 
tstlead: dc.w 0