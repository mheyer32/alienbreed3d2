
PLR3_mouse_control
 jsr ReadMouse
 
 move.l #SineTable,a0
 move.w PLR3s_angspd,d1
 move.w angpos,d0
 and.w #8190,d0
 move.w d0,PLR3s_angpos
 move.w (a0,d0.w),PLR3s_sinval
 adda.w #2048,a0
 move.w (a0,d0.w),PLR3s_cosval

 move.l PLR3s_xspdval,d6
 move.l PLR3s_zspdval,d7

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
; ble.s .nofastfor
; move.w #50,d3
;.nofastfor:
; cmp.w #-50,d3
; bge.s .nofastback
; move.w #-50,d3
;.nofastback:

 move.w STOPOFFSET,d0
 move.w d3,d2
 asl.w #7,d2
 
 add.w d2,PLR3_AIMSPD
 add.w d3,d0
 cmp.w #-80,d0
 bgt.s .nolookup
 move.w #-512*20,PLR3_AIMSPD
 move.w #-80,d0
.nolookup:
 cmp.w #80,d0
 blt.s .nolookdown
 move.w #512*20,PLR3_AIMSPD
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

 bra PLR3_keyboard_control

 move.w #-20,d2

 tst.b PLR2_Squished
 bne.s .halve
 tst.b PLR2_Ducked
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

 move.w PLR2s_sinval,d1
 move.w PLR2s_cosval,d2
 
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
 add.l d6,PLR2s_xspdval
 add.l d7,PLR2s_zspdval
 move.l PLR2s_xspdval,d6
 move.l PLR2s_zspdval,d7
 add.l d6,PLR2s_xoff
 add.l d7,PLR2s_zoff

 tst.b PLR2_fire
 beq.s .firenotpressed
; fire was pressed last time.
 btst #6,$bfe001
 bne.s .firenownotpressed
; fire is still pressed this time.
 st PLR2_fire
 bra .donePLR2
 
.firenownotpressed:
; fire has been released.
 clr.b PLR2_fire
 bra .donePLR2
 
.firenotpressed

; fire was not pressed last frame...

 btst #6,$bfe001
; if it has still not been pressed, go back above
 bne.s .firenownotpressed
; fire was not pressed last time, and was this time, so has
; been clicked.
 st PLR2_clicked
 st PLR2_fire

.donePLR2:

 bsr PLR2_fall
 
 rts



























PLR3_alwayskeys
 move.l #KeyMap,a5
 moveq #0,d7

 move.b next_weapon_key,d7
 tst.b (a5,d7.w)
 beq.s .nonextweappre

; tst.b PLR2_GunFrame
; bne.s .nonextweappre

 tst.b gunheldlast
 bne.s .nonextweap
 st gunheldlast

 moveq #0,d0
 move.b PLR3_GunSelected,d0
 move.l #PLAYERTHREEGUNS,a0

.findnext
 addq #1,d0
 cmp.w #9,d0
 ble.s .okgun
 moveq #0,d0
.okgun:
 tst.w (a0,d0.w*2)
 beq.s .findnext
 
 move.b d0,PLR3_GunSelected 
 bsr SHOWPLR3GUNNAME
  
 bra .nonextweap
 
.nonextweappre:
 clr.b gunheldlast
.nonextweap:


 move.b operate_key,d7
 move.b (a5,d7.w),d1
 beq.s .nottapped
 tst.b OldSpace
 bne.s .nottapped
 st PLR3_SPCTAP
.nottapped:
 move.b d1,OldSpace

 move.b duck_key,d7
 tst.b (a5,d7.w)
 beq.s .notduck
 clr.b (a5,d7.w)
 move.l #playerheight,PLR3s_targheight
 not.b PLR3_Ducked
 beq.s .notduck
 move.l #playercrouched,PLR3s_targheight
.notduck:

 move.l PLR3_Roompt,a4
 move.l ToZoneFloor(a4),d0
 sub.l ToZoneRoof(a4),d0
 tst.b PLR3_StoodInTop
 beq.s .usebottom
 move.l ToUpperFloor(a4),d0
 sub.l ToUpperRoof(a4),d0
.usebottom:

 clr.b PLR3_Squished
 move.l #playerheight,PLR3s_SquishedHeight

 cmp.l #playerheight+3*1024,d0
 bgt.s oktostand3
 st PLR3_Squished
 move.l #playercrouched,PLR3s_SquishedHeight
oktostand3:

 move.l PLR3s_targheight,d1
 move.l PLR3s_SquishedHeight,d0
 cmp.l d0,d1
 blt.s .notsqu
 move.l d0,d1
.notsqu:

 move.l PLR3s_height,d0
 cmp.l d1,d0
 beq.s .noupordown
 bgt.s .crouch
 add.l #1024,d0
 bra .noupordown
.crouch:
 sub.l #1024,d0
.noupordown:
 move.l d0,PLR3s_height

 tst.b $27(a5)
 beq.s .notselkey
 st PLR3KEYS
 clr.b PLR3PATH
 clr.b PLR3MOUSE
 clr.b PLR3JOY
.notselkey:

 tst.b $26(a5)
 beq.s .notseljoy
 clr.b PLR3KEYS
 clr.b PLR3PATH
 clr.b PLR3MOUSE
 st PLR3JOY
.notseljoy:

 tst.b $37(a5)
 beq.s .notselmouse
 clr.b PLR3KEYS
 clr.b PLR3PATH
 st PLR3MOUSE
 clr.b PLR3JOY
.notselmouse:

 lea 1(a5),a4
 move.l #PLAYERTHREEGUNS,a2
 move.l GUN_OBJ,a3
 move.w #9,d1
 move.w #0,d2
pickweap3
 move.w (a2)+,d0
 and.b (a4)+,d0
 beq.s notgotweap3
 move.b d2,PLR3_GunSelected
 move.w #0,ObjTimer(a3)

; move.l #TEMPSCROLL,SCROLLPOINTER
; move.w #0,SCROLLXPOS
; move.l #TEMPSCROLL+160,ENDSCROLL
; move.w #40,SCROLLTIMER
 
; d2=number of gun.

 bsr SHOWPLR3GUNNAME

 bra.s gogogogog3

notgotweap3
 addq #1,d2
 dbra d1,pickweap3

gogogogog3:

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

SHOWPLR3GUNNAME:
 moveq #0,d2
 move.b PLR3_GunSelected,d2

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













































PLR3_keyboard_control:

 move.l #SineTable,a0
 
 jsr PLR3_alwayskeys
 move.l #KeyMap,a5

 move.w STOPOFFSET,d0
 moveq #0,d7
 move.b look_up_key,d7
 tst.b (a5,d7.w)
 beq.s .nolookup
 
 sub.w #512,PLR3_AIMSPD
 sub.w #4,d0
 cmp.w #-80,d0
 bgt.s .nolookup
 move.w #-512*20,PLR3_AIMSPD
 move.w #-80,d0
.nolookup:
 moveq #0,d7
 move.b look_down_key,d7
 tst.b (a5,d7.w)
 beq.s .nolookdown
 add.w #512,PLR3_AIMSPD
 add.w #4,d0
 cmp.w #80,d0
 blt.s .nolookdown
 move.w #512*20,PLR3_AIMSPD
 move.w #80,d0
.nolookdown:

 move.b centre_view_key,d7
 tst.b (a5,d7.w)
 beq.s .nocent
 
 tst.b OLDCENT
 bne.s .nocent3
 st OLDCENT
 
 move.w #0,d0
 move.w #0,PLR3_AIMSPD
 
 bra.s .nocent3
 
.nocent:
 clr.b OLDCENT
.nocent3:


 move.w d0,STOPOFFSET
 neg.w d0
 add.w TOTHEMIDDLE,d0
 move.w d0,SMIDDLEY
 muls #320,d0
 move.l d0,SBIGMIDDLEY
 
 move.w PLR3s_angpos,d0
 move.w PLR3s_angspd,d3
 move.w #35,d1
 move.w #2,d2
 move.w #10,TURNSPD
 moveq #0,d7
 move.b run_key,d7
 tst.b (a5,d7.w)
 beq.s .nofaster
 move.w #60,d1
 move.w #3,d2
 move.w #14,TURNSPD
.nofaster:
 tst.b PLR3_Squished
 bne.s .halve
 tst.b PLR3_Ducked
 beq.s .nohalve
.halve:
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
 beq.s noturnposs3
 
 
 move.b templeftkey,d7
 tst.b (a5,d7.w)
 beq.s .noleftturn
 sub.w TURNSPD,d3
.noleftturn
 move.l #KeyMap,a5
 move.b temprightkey,d7
 tst.b (a5,d7.w)
 beq.s .norightturn
 add.w TURNSPD,d3
.norightturn
 
 cmp.w d1,d3
 ble.s .okrspd
 move.w d1,d3
.okrspd:
 neg.w d1
 cmp.w d1,d3
 bge.s .oklspd
 move.w d1,d3
.oklspd:
 
noturnposs3:
 
 add.w d3,d0
 add.w d3,d0
 move.w d3,PLR3s_angspd
 
 move.b tempslkey,d7
 tst.b (a5,d7.w)
 beq.s .noleftslide
 add.w d2,d4
 add.w d2,d4
 asr.w #1,d4
.noleftslide
 move.l #KeyMap,a5
 move.b tempsrkey,d7
 tst.b (a5,d7.w)
 beq.s .norightslide
 add.w d2,d4
 add.w d2,d4
 asr.w #1,d4
 neg.w d4
.norightslide
  
noslide3:
  
 and.w #8191,d0
 move.w d0,PLR3s_angpos
 
 move.w (a0,d0.w),PLR3s_sinval
 adda.w #2048,a0
 move.w (a0,d0.w),PLR3s_cosval

 move.l PLR3s_xspdval,d6
 move.l PLR3s_zspdval,d7

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

.nofriction

 moveq #0,d3
 
 moveq #0,d5
 move.b forward_key,d5
 tst.b (a5,d5.w)
 beq.s .noforward
 neg.w d2
 move.w d2,d3
 
.noforward:
 move.b backward_key,d5
 tst.b (a5,d5.w)
 beq.s .nobackward
 move.w d2,d3
.nobackward:
 
 move.w d3,d2
 asl.w #6,d2
 move.w d2,d1
; add.w d2,d1
; add.w d2,d1
 move.w d1,ADDTOBOBBLE
 
 move.w PLR3s_sinval,d1
 muls d3,d1
 move.w PLR3s_cosval,d2
 muls d3,d2

 sub.l d1,d6
 sub.l d2,d7
 move.w PLR3s_sinval,d1
 muls d4,d1
 move.w PLR3s_cosval,d2
 muls d4,d2
 sub.l d2,d6
 add.l d1,d7
 
 tst.b SLOWDOWN
 beq.s .nocontrolposs
 add.l d6,PLR3s_xspdval
 add.l d7,PLR3s_zspdval
.nocontrolposs:
 move.l PLR3s_xspdval,d6
 move.l PLR3s_zspdval,d7
 add.l d6,PLR3s_xoff
 add.l d7,PLR3s_zoff
 
 move.b fire_key,d5
 tst.b PLR3_fire
 beq.s .firenotpressed
; fire was pressed last time.
 tst.b (a5,d5.w)
 beq.s .firenownotpressed
; fire is still pressed this time.
 st PLR3_fire
 bra .doneplr3
 
.firenownotpressed:
; fire has been released.
 clr.b PLR3_fire
 bra .doneplr3
 
.firenotpressed

; fire was not pressed last frame...

 tst.b (a5,d5.w)
; if it has still not been pressed, go back above
 beq.s .firenownotpressed
; fire was not pressed last time, and was this time, so has
; been clicked.
 st PLR3_clicked
 st PLR3_fire

.doneplr3:

 bsr PLR3_fall

 rts
 
 
  
PLR3_JoyStick_control:

; jsr _ReadJoy3
 bra PLR3_keyboard_control
 
PLR3_clumptime: dc.w 0
 
PLR3clump:

 movem.l d0-d7/a0-a6,-(a7)
 move.l PLR3_Roompt,a0
 move.w ToFloorNoise(a0),d0

 move.l ToZoneWater(a0),d1
 cmp.l ToZoneFloor(a0),d1
 bge.s THERESNOWATER3
 
 cmp.l PLR3_yoff,d1
 blt.s THERESNOWATER3
 
 tst.b PLR3_StoodInTop
 bne.s THERESNOWATER3
 
 move.w #6,d0
 bra.s THERESWATER3

THERESNOWATER3:

 tst.b PLR3_StoodInTop
 beq.s .okinbot
 move.w ToUpperFloorNoise(a0),d0
.okinbot:

 move.l LINKFILE,a0
 add.l #FloorData,a0
 move.w 2(a0,d0.w*4),d0	; sample number.

 subq #1,d0
 blt.s nofootsound3

THERESWATER3:
 move.w d0,Samplenum
 move.w #0,Noisex
 move.w #100,Noisez
 move.w #80,Noisevol
 move.w #$fff8,IDNUM
 clr.b notifplaying
 move.b PLR3_Echo,SourceEcho
 jsr MakeSomeNoise
 
nofootsound3:
 movem.l (a7)+,d0-d7/a0-a6

 rts