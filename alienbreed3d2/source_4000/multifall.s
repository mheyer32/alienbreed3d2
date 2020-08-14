
PLR1_fall
 move.l PLR1s_tyoff,d0
 move.l PLR1s_yoff,d1
 move.l PLR1s_yvel,d2
 
 cmp.l d1,d0
 bgt .aboveground
 beq.s .onground

 st SLOWDOWN
 
; we are under the ground.

; move.l #0,d2
 sub.l d1,d0
 cmp.l #-512,d0
 bge.s .notoobig
 move.l #-512,d0
.notoobig:
 add.l d0,d1
 
 bra CARRYON

.onground:
 move.w PLR1_FloorSpd,d2
 ext.l d2
 asl.l #6,d2

 move.l #PLR1_Obj,a4
 move.w DAMAGEWHENHIT,d3
 sub.w #100,d3
 ble.s .nodam
 add.b d3,damagetaken(a4)
.nodam

 st SLOWDOWN
 move.w #0,DAMAGEWHENHIT

 move.w ADDTOBOBBLE,d3
 move.w d3,d4
 add.w PLR1_bobble,d3
 and.w #8190,d3
 move.w d3,PLR1_bobble
 add.w PLR1_clumptime,d4
 move.w d4,d3
 and.w #4095,d4
 move.w d4,PLR1_clumptime
 and.w #-4096,d3
 beq.s .noclump
 
 bsr PLR1clump
 
.noclump


 move.l #-1024,JUMPSPD
 
 move.l PLR1_Roompt,a2
 move.l ToZoneWater(a2),d0
 cmp.l d0,d1
 blt.s .notinwater
 
 move.l #-512,JUMPSPD
 
.notinwater:

 tst.w PLAYERONEHEALTH
 ble.s .nothrust

 move.l #KeyMap,a5
 moveq #0,d7
 move.b jump_key,d7
 tst.b (a5,d7.w)
 beq.s .nothrust
 move.l JUMPSPD,d2
.nothrust:
 
 tst.l d2
 ble.s .nodown
 
 moveq #0,d2
.nodown:
 add.l d2,d1
 bra CARRYON

.aboveground

 clr.b SLOWDOWN

 tst.w PLAYERONEJETPACK
 beq.s .nofly
 
 tst.w PLAYERONEFUEL
 beq.s .nofly
 
 cmp.w #250,PLAYERONEFUEL
 ble.s .okfuel
 
 move.w #250,PLAYERONEFUEL
 
.okfuel:
 
 st SLOWDOWN
 move.l #-128,JUMPSPD
 move.l #KeyMap,a5
 moveq #0,d7
 move.b jump_key,d7
 tst.b (a5,d7.w)
 beq.s .nofly
 sub.w #1,PLAYERONEFUEL
 add.l JUMPSPD,d2
 move.w #0,DAMAGEWHENHIT
 move.w #40,d3
 add.w PLR1_bobble,d3
 and.w #8190,d3
 move.w d3,PLR1_bobble
.nofly:

 move.l d0,d3
 sub.l d1,d3
 cmp.l #16*64,d3
 bgt.s .nonearmove
 
 st SLOWDOWN
 
.nonearmove:


; need to fall down (possibly).

 add.l d2,d1
 cmp.l d1,d0
 bgt.s .stillabove

 move.w DAMAGEWHENHIT,d3
 sub.w #100,d3
 ble.s .nodam2
 move.l PLR1_Obj,a4
 add.b d3,damagetaken(a4)
.nodam2
 move.w #0,DAMAGEWHENHIT
 
 move.w PLR1_FloorSpd,d2
 ext.l d2
 asl.l #6,d2
 
 bra CARRYON
 
.stillabove:
 add.l #64,d2
 add.w #1,DAMAGEWHENHIT
 
 move.l PLR1_Roompt,a2
 move.l ToZoneWater(a2),d0
 cmp.l d0,d1
 blt.s CARRYON
 
 cmp.l oldheight,d0
 blt.s .nosplash
 
 movem.l d0-d7/a0-a6,-(a7)
 move.w #6,Samplenum
 move.w #0,Noisex
 move.w #100,Noisez
 move.w #80,Noisevol
 move.w #$fff8,IDNUM
 clr.b notifplaying
 jsr MakeSomeNoise
 movem.l (a7)+,d0-d7/a0-a6
 
.nosplash:
 
 st SLOWDOWN
 move.w #0,DAMAGEWHENHIT
 cmp.l #512,d2 
 blt.s CARRYON 
 move.l #512,d2 	; reached terminal velocity.
CARRYON:

 move.l PLR1_Roompt,a2
 move.l ToZoneRoof(a2),d3
 tst.b PLR1_StoodInTop
 beq.s .okbot
 move.l ToUpperRoof(a2),d3
.okbot:

 add.l #10*256,d3
 cmp.l d1,d3
 blt.s .okroof
 move.l d3,d1
 tst.l d2
 bge.s .okroof
 moveq #0,d2
.okroof:

 move.l d2,PLR1s_yvel
 move.l d1,PLR1s_yoff
 
 rts
 
ARSE:
 
 sub.l d1,d0
 slt.s CANJUMP
 bgt.s .aboveground
 beq.s .notfast
 sub.l #512,d2
 blt.s .notfast
 move.l #0,d2
.notfast:
 add.l d2,d1
 sub.l d2,d0
 blt.s .pastitall
 move.l #0,d2
 move.l PLR1s_tyoff,d1
 bra.s .pastitall

.aboveground:
 add.l d2,d1
 add.l #64,d2
 
 move.l #-1024,JUMPSPD
 
 move.l PLR1_Roompt,a2
 move.l ToZoneWater(a2),d0
 cmp.l d0,d1
 blt.s .pastitall

 move.l #-512,JUMPSPD
 cmp.l #256*2,d2
 blt.s .pastitall
 move.l #256*2,d2
 
.pastitall:

 move.l d2,PLR1s_yvel
 move.l d1,PLR1s_yoff
 
 move.l #KeyMap,a5
 tst.b $1d(a5)
 beq.s nothrust2
 tst.b CANJUMP
 beq.s nothrust2
 move.l JUMPSPD,PLR1s_yvel
nothrust2:

 move.l PLR1_Roompt,a5
 move.l ToZoneRoof(a5),d0
 tst.b PLR1_StoodInTop
 beq.s .usebottom
 move.l ToUpperRoof(a5),d0
.usebottom:

 move.l PLR1s_yoff,d1
 move.l PLR1s_yvel,d2

 sub.l PLR1s_height,d1
 sub.l #10*256,d1
 cmp.l d1,d0
 blt.s .notinroof
 move.l d0,d1
 tst.l d2
 bge.s .notinroof
 moveq #0,d2
.notinroof
 add.l #10*256,d1
 add.l PLR1s_height,d1
 move.l d1,PLR1s_yoff

 move.l d2,PLR1s_yvel

 rts

PLR2_fall
 move.l PLR2s_tyoff,d0
 move.l PLR2s_yoff,d1
 move.l PLR2s_yvel,d2
 
 cmp.l d1,d0
 bgt .aboveground
 beq.s .onground
 
 st SLOWDOWN
; we are under the ground.

 move.l #0,d2
 sub.l d1,d0
 cmp.l #-512,d0
 bge.s .notoobig
 move.l #-512,d0
.notoobig:
 add.l d0,d1
 
 bra CARRYON2

.onground:

 move.w DAMAGEWHENHIT,d3
 sub.w #100,d3
 ble.s .nodam
 move.l PLR2_Obj,a4
 add.b d3,damagetaken(a4)
.nodam
 move.w #0,DAMAGEWHENHIT
 
 st SLOWDOWN

 move.w ADDTOBOBBLE,d3
 move.w d3,d4
 add.w PLR2_bobble,d3
 and.w #8190,d3
 move.w d3,PLR2_bobble
 add.w PLR2_clumptime,d4
 move.w d4,d3
 and.w #4095,d4
 move.w d4,PLR2_clumptime
 and.w #-4096,d3
 beq.s .noclump
 
 bsr PLR2clump
 
.noclump

 move.l #-1024,JUMPSPD
 
 move.l PLR2_Roompt,a2
 move.l ToZoneWater(a2),d0
 cmp.l d0,d1
 blt.s .notinwater
 
 move.l #-512,JUMPSPD
 
.notinwater:

 tst.w PLAYERTWOHEALTH
 ble.s .nothrust
 move.l #KeyMap,a5
 moveq #0,d7
 move.b jump_key,d7
 tst.b (a5,d7.w)
 beq.s .nothrust
 move.l JUMPSPD,d2
.nothrust:
 
 tst.l d2
 ble.s .nodown
 
 moveq #0,d2
.nodown:
 add.l d2,d1
 bra CARRYON2

.aboveground

 clr.b SLOWDOWN
; need to fall down (possibly).

 tst.w PLAYERTWOJETPACK
 beq.s .nofly
 
 tst.w PLAYERTWOFUEL
 beq.s .nofly
 
 cmp.w #250,PLAYERTWOFUEL
 ble.s .okfuel
 
 move.w #250,PLAYERTWOFUEL
 
.okfuel:
 
 st SLOWDOWN
 
 move.l #-128,JUMPSPD
 move.l #KeyMap,a5
 moveq #0,d7
 move.b jump_key,d7
 tst.b (a5,d7.w)
 beq.s .nofly
 add.l JUMPSPD,d2
 move.w #0,DAMAGEWHENHIT
 sub.w #1,PLAYERTWOFUEL
 move.w #40,d3
 add.w PLR2_bobble,d3
 and.w #8190,d3
 move.w d3,PLR2_bobble
 
.nofly:

 move.l d1,oldheight

 add.l d2,d1
 cmp.l d1,d0
 bgt.s .stillabove

 move.w DAMAGEWHENHIT,d3
 sub.w #100,d3
 ble.s .nodam2
 move.l PLR2_Obj,a4
 add.b d3,damagetaken(a4)
.nodam2
 move.w #0,DAMAGEWHENHIT

 move.l #0,d2
 bra CARRYON2
 
.stillabove:
 add.l #64,d2
 
 add.w #1,DAMAGEWHENHIT
 
 move.l PLR2_Roompt,a2
 move.l ToZoneWater(a2),d0
 cmp.l d0,d1
 blt.s CARRYON2
 
 cmp.l oldheight,d0
 blt.s .nosplash
 
 movem.l d0-d7/a0-a6,-(a7)
 move.w #6,Samplenum
 move.w #0,Noisex
 move.w #100,Noisez
 move.w #80,Noisevol
 move.w #$fff8,IDNUM
 clr.b notifplaying
 jsr MakeSomeNoise
 movem.l (a7)+,d0-d7/a0-a6
 
.nosplash:


 st SLOWDOWN
 move.w #0,DAMAGEWHENHIT
 
 cmp.l #512,d2
 blt.s CARRYON2
 
 move.l #512,d2 

CARRYON2:

 move.l PLR2_Roompt,a2
 move.l ToZoneRoof(a2),d3
 tst.b PLR2_StoodInTop
 beq.s .okbot
 move.l ToUpperRoof(a2),d3
.okbot:

 add.l #10*256,d3
 cmp.l d1,d3
 blt.s .okroof
 move.l d3,d1
 tst.l d2
 bge.s .okroof
 moveq #0,d2
.okroof:

 move.l d2,PLR2s_yvel
 move.l d1,PLR2s_yoff
 
 rts

PLR3_fall:
 move.l PLR3s_tyoff,d0
 move.l PLR3s_yoff,d1
 move.l PLR3s_yvel,d2
 
 cmp.l d1,d0
 bgt .aboveground
 beq.s .onground
 
 st SLOWDOWN
; we are under the ground.

 move.l #0,d2
 sub.l d1,d0
 cmp.l #-512,d0
 bge.s .notoobig
 move.l #-512,d0
.notoobig:
 add.l d0,d1
 
 bra CARRYON3

.onground:

 move.w DAMAGEWHENHIT,d3
 sub.w #100,d3
 ble.s .nodam
 move.l PLR3_Obj,a4
 add.b d3,damagetaken(a4)
.nodam
 move.w #0,DAMAGEWHENHIT
 
 st SLOWDOWN

 move.w ADDTOBOBBLE,d3
 move.w d3,d4
 add.w PLR3_bobble,d3
 and.w #8190,d3
 move.w d3,PLR3_bobble
 add.w PLR3_clumptime,d4
 move.w d4,d3
 and.w #4095,d4
 move.w d4,PLR3_clumptime
 and.w #-4096,d3
 beq.s .noclump
 
 bsr PLR3clump
 
.noclump

 move.l #-1024,JUMPSPD
 
 move.l PLR3_Roompt,a2
 move.l ToZoneWater(a2),d0
 cmp.l d0,d1
 blt.s .notinwater
 
 move.l #-512,JUMPSPD
 
.notinwater:

 tst.w PLAYERTHREEHEALTH
 ble.s .nothrust
 move.l #KeyMap,a5
 moveq #0,d7
 move.b jump_key,d7
 tst.b (a5,d7.w)
 beq.s .nothrust
 move.l JUMPSPD,d2
.nothrust:
 
 tst.l d2
 ble.s .nodown
 
 moveq #0,d2
.nodown:
 add.l d2,d1
 bra CARRYON3

.aboveground

 clr.b SLOWDOWN
; need to fall down (possibly).

 tst.w PLAYERTHREEJETPACK
 beq.s .nofly
 
 tst.w PLAYERTHREEFUEL
 beq.s .nofly
 
 cmp.w #250,PLAYERTHREEFUEL
 ble.s .okfuel
 
 move.w #250,PLAYERTHREEFUEL
 
.okfuel:
 
 st SLOWDOWN
 
 move.l #-128,JUMPSPD
 move.l #KeyMap,a5
 moveq #0,d7
 move.b jump_key,d7
 tst.b (a5,d7.w)
 beq.s .nofly
 add.l JUMPSPD,d2
 move.w #0,DAMAGEWHENHIT
 sub.w #1,PLAYERTWOFUEL
 move.w #40,d3
 add.w PLR3_bobble,d3
 and.w #8190,d3
 move.w d3,PLR3_bobble
 
.nofly:

 move.l d1,oldheight

 add.l d2,d1
 cmp.l d1,d0
 bgt.s .stillabove

 move.w DAMAGEWHENHIT,d3
 sub.w #100,d3
 ble.s .nodam3
 move.l PLR3_Obj,a4
 add.b d3,damagetaken(a4)
.nodam3
 move.w #0,DAMAGEWHENHIT

 move.l #0,d2
 bra CARRYON3
 
.stillabove:
 add.l #64,d2
 
 add.w #1,DAMAGEWHENHIT
 
 move.l PLR3_Roompt,a2
 move.l ToZoneWater(a2),d0
 cmp.l d0,d1
 blt.s CARRYON3
 
 cmp.l oldheight,d0
 blt.s .nosplash
 
 movem.l d0-d7/a0-a6,-(a7)
 move.w #6,Samplenum
 move.w #0,Noisex
 move.w #100,Noisez
 move.w #80,Noisevol
 move.w #$fff8,IDNUM
 clr.b notifplaying
 jsr MakeSomeNoise
 movem.l (a7)+,d0-d7/a0-a6
 
.nosplash:


 st SLOWDOWN
 move.w #0,DAMAGEWHENHIT
 
 cmp.l #512,d2
 blt.s CARRYON3
 
 move.l #512,d2 

CARRYON3:

 move.l PLR3_Roompt,a2
 move.l ToZoneRoof(a2),d3
 tst.b PLR3_StoodInTop
 beq.s .okbot
 move.l ToUpperRoof(a2),d3
.okbot:

 add.l #10*256,d3
 cmp.l d1,d3
 blt.s .okroof
 move.l d3,d1
 tst.l d2
 bge.s .okroof
 moveq #0,d2
.okroof:

 move.l d2,PLR3s_yvel
 move.l d1,PLR3s_yoff
 
 rts

 
CANJUMP: dc.w 0
JUMPSPD: dc.l 0
SLOWDOWN: dc.w 0
DAMAGEWHENHIT: dc.w 0
oldheight: dc.l 0