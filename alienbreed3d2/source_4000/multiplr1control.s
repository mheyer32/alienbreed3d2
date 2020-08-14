 
PLR1_mouse_control
 jsr ReadMouse

 move.l #SineTable,a0
 move.w PLR1s_angspd,d1
 move.w angpos,d0
 and.w #8190,d0
 move.w d0,PLR1s_angpos
 move.w (a0,d0.w),PLR1s_sinval
 adda.w #2048,a0
 move.w (a0,d0.w),PLR1s_cosval

 move.l PLR1s_xspdval,d6
 move.l PLR1s_zspdval,d7

 neg.l d6
 ble.s .nobug1
 asr.l #1,d6
 add.l #1,d6
 bra.s .bug1
.nobug1
 asr.l #1,d6
.bug1:

 neg.l d7
 ble.s .nobug2
 asr.l #1,d7
 add.l #1,d7
 bra.s .bug2
.nobug2
 asr.l #1,d7
.bug2: 
 
 move.w ymouse,d3
 sub.w oldymouse,d3
 add.w d3,oldymouse
; asr.w #1,d3
; cmp.w #50,d3
; ble.s nofastfor
; move.w #50,d3
;nofastfor:
; cmp.w #-50,d3
; bge.s nofastback
; move.w #-50,d3
;nofastback:

 move.w STOPOFFSET,d0
 move.w d3,d2
 asl.w #7,d2
 
 add.w d2,PLR1_AIMSPD
 add.w d3,d0
 cmp.w #-80,d0
 bgt.s .nolookup
 move.w #-512*20,PLR1_AIMSPD
 move.w #-80,d0
.nolookup:
 cmp.w #80,d0
 blt.s .nolookdown
 move.w #512*20,PLR1_AIMSPD
 move.w #80,d0
.nolookdown

 move.w d0,STOPOFFSET
 neg.w d0
 add.w TOTHEMIDDLE,d0
 move.w d0,SMIDDLEY
 muls #320,d0
 move.l d0,SBIGMIDDLEY

 move.l #KeyMap,a5
 moveq #0,d7
 move.b forward_key,d7

 btst #6,$bfe001
 seq.s (a5,d7.w)

 move.b fire_key,d7
 btst #2,$dff016
 seq.s (a5,d7.w)

 bra PLR1_keyboard_control

 move.w #-20,d2

 tst.b PLR1_Squished
 bne.s .halve
 tst.b PLR1_Ducked
 beq.s .nohalve
.halve
 asr.w #1,d2
.nohalve

 btst #6,$bfe001
 beq.s .moving
 moveq #0,d2
.moving:

 move.w d2,d3
 asl.w #4,d2
 move.w d2,d1
 
 move.w d1,ADDTOBOBBLE

 move.w PLR1s_sinval,d1
 move.w PLR1s_cosval,d2
 
 move.w d2,d4
 move.w d1,d5
 muls lrs,d4
 muls lrs,d5

 muls d3,d2
 muls d3,d1
 sub.l d4,d1
 add.l d5,d2

 sub.l d1,d6
 sub.l d2,d7
 add.l d6,PLR1s_xspdval
 add.l d7,PLR1s_zspdval
 move.l PLR1s_xspdval,d6
 move.l PLR1s_zspdval,d7
 add.l d6,PLR1s_xoff
 add.l d7,PLR1s_zoff

 tst.b PLR1_fire
 beq.s .firenotpressed
; fire was pressed last time.
 btst #7,$bfe001
 bne.s .firenownotpressed
; fire is still pressed this time.
 st PLR1_fire
 bra .doneplr1
 
.firenownotpressed:
; fire has been released.
 clr.b PLR1_fire
 bra .doneplr1
 
.firenotpressed

; fire was not pressed last frame...

 btst #7,$bfe001
; if it has still not been pressed, go back above
 bne.s .firenownotpressed
; fire was not pressed last time, and was this time, so has
; been clicked.
 st PLR1_clicked
 st PLR1_fire

.doneplr1:
 
 bsr PLR1_fall
 
 rts
 
ADDTOBOBBLE: dc.w 0

PLR1_follow_path:

 move.l pathpt,a0
 move.w (a0),d1
 move.w d1,PLR1s_xoff
 move.w 2(a0),d1
 move.w d1,PLR1s_zoff
 move.w 4(a0),d0
 add.w d0,d0
 and.w #8190,d0
 move.w d0,PLR1_angpos

 move.w TempFrames,d0
 asl.w #3,d0
 adda.w d0,a0
 
 cmp.l #endpath,a0
 blt notrestartpath
 move.l #Path,a0
notrestartpath:
 move.l a0,pathpt

 rts

gunheldlast:
 dc.w 0

PLR1_alwayskeys
 move.l #KeyMap,a5
 moveq #0,d7
 
 move.b next_weapon_key,d7
 tst.b (a5,d7.w)
 beq.s .nonextweappre

; tst.w PLR1_TimeToShoot
; bne.s .nonextweappre

 tst.b gunheldlast
 bne.s .nonextweap
 st gunheldlast

 moveq #0,d0
 move.b PLR1_GunSelected,d0
 move.l #PLAYERONEGUNS,a0

.findnext
 addq #1,d0
 cmp.w #9,d0
 ble.s .okgun
 moveq #0,d0
.okgun:
 tst.w (a0,d0.w*2)
 beq.s .findnext
 
 move.b d0,PLR1_GunSelected 
 bsr SHOWPLR1GUNNAME
  
 bra .nonextweap
 
.nonextweappre:
 clr.b gunheldlast
.nonextweap:
 
 
 move.b operate_key,d7
 move.b (a5,d7.w),d1
 beq.s nottapped
 tst.b OldSpace
 bne.s nottapped
 st PLR1_SPCTAP
nottapped:
 move.b d1,OldSpace

 move.b duck_key,d7
 tst.b (a5,d7.w)
 beq.s notduck
 clr.b (a5,d7.w)
 move.l #playerheight,PLR1s_targheight
 not.b PLR1_Ducked
 beq.s notduck
 move.l #playercrouched,PLR1s_targheight
notduck:

 move.l PLR1_Roompt,a4
 move.l ToZoneFloor(a4),d0
 sub.l ToZoneRoof(a4),d0
 tst.b PLR1_StoodInTop
 beq.s usebottom
 move.l ToUpperFloor(a4),d0
 sub.l ToUpperRoof(a4),d0
usebottom:

 clr.b PLR1_Squished
 move.l #playerheight,PLR1s_SquishedHeight

 cmp.l #playerheight+3*1024,d0
 bgt.s oktostand
 st PLR1_Squished
 move.l #playercrouched,PLR1s_SquishedHeight
oktostand:

 move.l PLR1s_targheight,d1
 move.l PLR1s_SquishedHeight,d0
 cmp.l d0,d1
 blt.s .notsqu
 move.l d0,d1
.notsqu:

 move.l PLR1s_height,d0
 cmp.l d1,d0
 beq.s noupordown
 bgt.s crouch
 add.l #1024,d0
 bra noupordown
crouch:
 sub.l #1024,d0
noupordown:
 move.l d0,PLR1s_height

 tst.b $27(a5)
 beq.s notselkey
 st PLR1KEYS
 clr.b PLR1PATH
 clr.b PLR1MOUSE
 clr.b PLR1JOY
notselkey:

 tst.b $26(a5)
 beq.s notseljoy
 clr.b PLR1KEYS
 clr.b PLR1PATH
 clr.b PLR1MOUSE
 st PLR1JOY
notseljoy:

 tst.b $37(a5)
 beq.s notselmouse
 clr.b PLR1KEYS
 clr.b PLR1PATH
 st PLR1MOUSE
 clr.b PLR1JOY
notselmouse:

 lea 1(a5),a4
 move.l #PLAYERONEGUNS,a2
 move.l GUN_OBJ,a3
 move.w #9,d1
 move.w #0,d2
pickweap
 move.w (a2)+,d0
 and.b (a4)+,d0
 beq.s notgotweap
 move.b d2,PLR1_GunSelected
 move.w #0,ObjTimer(a3)
 
 
; SCROLLPOINTER
; move.w #0,SCROLLXPOS
; move.l #TEMPSCROLL+160,ENDSCROLL
; move.w #40,SCROLLTIMER
 
; d2=number of gun.

 bsr SHOWPLR1GUNNAME

 bra.s gogog
 
notgotweap
 addq #1,d2
 dbra d1,pickweap
 
gogog:
 
 ifeq CHEESEY
 tst.b $43(a5)
 beq.s .notswapscr
 tst.b lastscr
 bne.s .notswapscr2
 st lastscr
 
 not.b FULLSCRTEMP

 bra.s .notswapscr2

.notswapscr:
 clr.b lastscr
.notswapscr2:

 endc

 rts
 
FULLSCRTEMP: dc.w 0

WIPEDISPLAY:
 move.l #231,d0
 moveq #0,d1
 
 move.w #7,d2
planel:
 move.l #231,d0

wipe:
 move.l d1,2(a0)
 move.l d1,6(a0)
 move.l d1,10(a0)
 move.l d1,14(a0)
 move.l d1,18(a0)
 move.l d1,22(a0)
 move.l d1,26(a0)
 move.l d1,30(a0)
 move.l d1,34(a0)
 add.w #40,a0
 dbra d0,wipe
 add.w #40*24,a0
 dbra d2,planel

 rts

SHOWPLR1GUNNAME:
 moveq #0,d2
 move.b PLR1_GunSelected,d2

 move.l LINKFILE,a4
 add.l #GunNames,a4
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
 rts

 
GUNVALS: 
; machine gun
 dc.b 0
; shotgun
 dc.b 7
; plasma
 dc.b 1
; grenade
 dc.b 4
; rocket
 dc.b 2
 
TOTHEMIDDLE: dc.w 0
BIGsmall: dc.b 0
lastscr: dc.b 0
BOTTOMY: dc.w 0
 even

PLR1_keyboard_control:

 move.l #SineTable,a0
 
 jsr PLR1_alwayskeys
 move.l #KeyMap,a5

 move.w STOPOFFSET,d0
 moveq #0,d7
 move.b look_up_key,d7
 tst.b (a5,d7.w)
 beq.s .nolookup
 
 sub.w #512,PLR1_AIMSPD
 sub.w #4,d0
 cmp.w #-80,d0
 bgt.s .nolookup
 move.w #-512*20,PLR1_AIMSPD
 move.w #-80,d0
.nolookup:
 moveq #0,d7
 move.b look_down_key,d7
 tst.b (a5,d7.w)
 beq.s .nolookdown
 add.w #512,PLR1_AIMSPD
 add.w #4,d0
 cmp.w #80,d0
 blt.s .nolookdown
 move.w #512*20,PLR1_AIMSPD
 move.w #80,d0
.nolookdown:

 move.b centre_view_key,d7
 tst.b (a5,d7.w)
 beq.s .nocent
 
 tst.b OLDCENT
 bne.s .nocent2
 st OLDCENT
 
 move.w #0,d0
 move.w #0,PLR1_AIMSPD
 
 bra.s .nocent2
 
.nocent:
 clr.b OLDCENT
.nocent2:


 move.w d0,STOPOFFSET
 neg.w d0
 add.w TOTHEMIDDLE,d0
 move.w d0,SMIDDLEY
 muls #320,d0
 move.l d0,SBIGMIDDLEY

 move.w PLR1s_angpos,d0
 move.w PLR1s_angspd,d3
 move.w #35,d1
 move.w #2,d2
 move.w #10,TURNSPD
 moveq #0,d7
 move.b run_key,d7
 tst.b (a5,d7.w)
 beq.s nofaster
 move.w #60,d1
 move.w #3,d2
 move.w #14,TURNSPD
nofaster:
 tst.b PLR1_Squished
 bne.s .halve
 tst.b PLR1_Ducked
 beq.s .nohalve
.halve
 asr.w #1,d2
.nohalve

 moveq #0,d4 
 
 tst.b SLOWDOWN
 beq.s .nofric
 move.w d3,d5
 add.w d5,d5
 add.w d5,d3
 asr.w #2,d3
 bge.s .nneg
 addq #1,d3
.nneg:
.nofric:
 
 move.b turn_left_key,templeftkey
 move.b turn_right_key,temprightkey
 move.b sidestep_left_key,tempslkey
 move.b sidestep_right_key,tempsrkey
 
 move.b force_sidestep_key,d7
 tst.b (a5,d7.w)
 beq .noalwayssidestep
 
 move.b templeftkey,tempslkey
 move.b temprightkey,tempsrkey
 move.b #255,templeftkey
 move.b #255,temprightkey
 
.noalwayssidestep:
 
 tst.b SLOWDOWN
 beq.s noturnposs
 
 
 move.b templeftkey,d7
 tst.b (a5,d7.w)
 beq.s noleftturn
 sub.w TURNSPD,d3
noleftturn
 move.l #KeyMap,a5
 move.b temprightkey,d7
 tst.b (a5,d7.w)
 beq.s norightturn
 add.w TURNSPD,d3
norightturn
 
 cmp.w d1,d3
 ble.s .okrspd
 move.w d1,d3
.okrspd:
 neg.w d1
 cmp.w d1,d3
 bge.s .oklspd
 move.w d1,d3
.oklspd:

noturnposs:
 
 add.w d3,d0
 add.w d3,d0
 move.w d3,PLR1s_angspd
 
 move.b tempslkey,d7
 tst.b (a5,d7.w)
 beq.s noleftslide
 add.w d2,d4
 add.w d2,d4
 asr.w #1,d4
noleftslide
 move.l #KeyMap,a5
 move.b tempsrkey,d7
 tst.b (a5,d7.w)
 beq.s norightslide
 add.w d2,d4
 add.w d2,d4
 asr.w #1,d4
 neg.w d4
norightslide
  
noslide:
  
 and.w #8191,d0
 move.w d0,PLR1s_angpos
 
 move.w (a0,d0.w),PLR1s_sinval
 adda.w #2048,a0
 move.w (a0,d0.w),PLR1s_cosval

 move.l PLR1s_xspdval,d6
 move.l PLR1s_zspdval,d7

 tst.b SLOWDOWN
 beq.s .nofriction

 neg.l d6
 ble.s .nobug1
 asr.l #3,d6
 add.l #1,d6
 bra.s .bug1
.nobug1
 asr.l #3,d6
.bug1:

 neg.l d7
 ble.s .nobug2
 asr.l #3,d7
 add.l #1,d7
 bra.s .bug2
.nobug2
 asr.l #3,d7
.bug2: 

.nofriction:

 moveq #0,d3
 
 moveq #0,d5
 move.b forward_key,d5
 tst.b (a5,d5.w)
 beq.s noforward
 neg.w d2
 move.w d2,d3
 
noforward:
 move.b backward_key,d5
 tst.b (a5,d5.w)
 beq.s nobackward
 move.w d2,d3
nobackward:
 
 move.w d3,d2
 asl.w #6,d2
 move.w d2,d1
; add.w d2,d1
; add.w d2,d1
 move.w d1,ADDTOBOBBLE

 move.w PLR1s_sinval,d1
 muls d3,d1
 move.w PLR1s_cosval,d2
 muls d3,d2

 sub.l d1,d6
 sub.l d2,d7
 move.w PLR1s_sinval,d1
 muls d4,d1
 move.w PLR1s_cosval,d2
 muls d4,d2
 sub.l d2,d6
 add.l d1,d7
 
 tst.b SLOWDOWN
 beq.s .nocontrolposs
 add.l d6,PLR1s_xspdval
 add.l d7,PLR1s_zspdval
.nocontrolposs
 move.l PLR1s_xspdval,d6
 move.l PLR1s_zspdval,d7
 add.l d6,PLR1s_xoff
 add.l d7,PLR1s_zoff
 
 move.b fire_key,d5
 tst.b PLR1_fire
 beq.s .firenotpressed
; fire was pressed last time.
 tst.b (a5,d5.w)
 beq.s .firenownotpressed
; fire is still pressed this time.
 st PLR1_fire
 bra .doneplr1
 
.firenownotpressed:
; fire has been released.
 clr.b PLR1_fire
 bra .doneplr1
 
.firenotpressed

; fire was not pressed last frame...

 tst.b (a5,d5.w)
; if it has still not been pressed, go back above
 beq.s .firenownotpressed
; fire was not pressed last time, and was this time, so has
; been clicked.
 st PLR1_clicked
 st PLR1_fire

.doneplr1:

 bsr PLR1_fall

 rts
 
TEMPSCROLL
 dcb.b 160,32
 
passspace:
 ds.l 400 

PLR1_JoyStick_control:

 jsr _ReadJoy1
 bra PLR1_keyboard_control

PLR1_clumptime: dc.w 0
 
PLR1clump:

 movem.l d0-d7/a0-a6,-(a7)
 move.l PLR1_Roompt,a0
 move.w ToFloorNoise(a0),d0

 move.l ToZoneWater(a0),d1
 cmp.l ToZoneFloor(a0),d1
 bge.s THERESNOWATER
 
 cmp.l PLR1_yoff,d1
 blt.s THERESNOWATER
 
 tst.b PLR1_StoodInTop
 bne.s THERESNOWATER
 
 move.w #6,d0
 bra.s THERESWATER

THERESNOWATER:
 
 tst.b PLR1_StoodInTop
 beq.s .okinbot
 move.w ToUpperFloorNoise(a0),d0
.okinbot:

 move.l LINKFILE,a0
 add.l #FloorData,a0
 move.w 2(a0,d0.w*4),d0	; sample number.

 subq #1,d0
 blt.s nofootsound

THERESWATER:
 move.w d0,Samplenum
 move.w #0,Noisex
 move.w #100,Noisez
 move.w #80,Noisevol
 move.w #$fff8,IDNUM
 clr.b notifplaying
 move.b PLR1_Echo,SourceEcho
 jsr MakeSomeNoise
 
nofootsound:
 movem.l (a7)+,d0-d7/a0-a6

 rts
