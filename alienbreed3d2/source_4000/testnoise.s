 
**************************************
* I want a routine to calculate all the
* info needed for the sound player to
* work, given say position of noise, volume
* and sample number.


 move.w #100,Noisevol
 move.w #1,Samplenum
 move.w #100,Noisex
 move.w #0,Noisez
 move.b #1,IDNUM
 bsr MakeSomeNoise
 
 move.w #100,Noisevol
 move.w #1,Samplenum
 move.w #100,Noisex
 move.w #0,Noisez
 move.b #2,IDNUM
 bsr MakeSomeNoise

 move.w #100,Noisevol
 move.w #1,Samplenum
 move.w #100,Noisex
 move.w #0,Noisez
 move.b #3,IDNUM
 bsr MakeSomeNoise

 move.w #100,Noisevol
 move.w #1,Samplenum
 move.w #0,Noisex
 move.w #0,Noisez
 move.b #4,IDNUM
 bsr MakeSomeNoise

testit:
 move.w #200,Noisevol
 move.w #1,Samplenum
 move.w #100,Noisex
 move.w #0,Noisez
 move.b #2,IDNUM
 bsr MakeSomeNoise

 
 rts

 
MakeSomeNoise:

; Plan for new sound handler:
; It is sent a sample number,
; a position relative to the
; player, an id number and a volume.
; Also notifplaying.

; indirect inputs are the available
; channel flags and whether or not
; stereo sound is selected.

; the algorithm must decide
; whether the new sound is more
; important than the ones already
; playing. Thus an 'importance'
; must be calculated, probably
; using volume.

; The output needs to be:

; Write the pointers and volumes of
; the sound channels


 tst.b notifplaying
 beq.s dontworry

; find if we are already playing

 move.b IDNUM,d0
 move.w #7,d1
 lea CHANNELDATA,a3
findsameasme
 tst.b (a3)
 bne.s notavail
 cmp.b 1(a3),d0
 beq SameAsMe
notavail:
 add.w #4,a3
 dbra d1,findsameasme
 bra dontworry
SameAsMe
 rts

noiseloud: dc.w 0

dontworry:

; Ok its fine for us to play a sound.
; So calculate left/right volume.

 move.w Noisex,d1
 muls d1,d1
 move.w Noisez,d2
 muls d2,d2
 move.w #64,d3
 move.w #32767,noiseloud
 moveq #1,d0
 add.l d1,d2
 beq pastcalc

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

 move.w d0,d3
 muls d3,d3	; x*x
 sub.l d2,d3	; x*x-a
 asr.l #1,d3	; (x*x-a)/2
 divs d0,d3	; (x*x-a)/2x
 sub.w d3,d0	; second approx
 bgt .stillnot0
 move.w #1,d0
.stillnot0

 move.w d0,d3
 muls d3,d3
 sub.l d2,d3
 asr.l #1,d3
 divs d0,d3
 sub.w d3,d0	; second approx
 bgt .stillnot02
 move.w #1,d0
.stillnot02
 
 move.w Noisevol,d3
 ext.l d3
 asl.l #6,d3
 cmp.l #32767,d3
 ble.s .nnnn
 move.l #32767,d3
.nnnn
 
 asr.w #2,d0
 addq #1,d0
 divs d0,d3
 
 move.w d3,noiseloud

 cmp.w #64,d3
 ble.s notooloud
 move.w #64,d3
notooloud:

pastcalc:

	; d3 contains volume of noise.
	
 move.w d3,d4
 tst.b STEREO
 beq NOSTEREO
 
 move.w d3,d2
 muls Noisex,d2
 asl.w #2,d0
 divs d0,d2
 
 bgt.s quietleft
 add.w d2,d4
 bge.s donequiet
 move.w #0,d4
 bra.s donequiet
quietleft:
 sub.w d2,d3
 bge.s donequiet
 move.w #0,d3
donequiet:

; d3=leftvol?
; d4=rightvol?

 clr.w needleft

 cmp.b d3,d4
 bgt.s RightLouder
 
; Left is louder; is it MUCH louder?

 st needleft
 move.w d3,d2
 sub.w d4,d2
 cmp.w #32,d2
 slt needright
 bra aboutsame
 
RightLouder:
 st needright
 move.w d4,d2
 sub.w d3,d2
 cmp.w #32,d2
 slt needleft
 
aboutsame:


; Find least important sound on left

 move.l #0,a2
 move.l #0,d5
 move.w #32767,d2
 move.b IDNUM,d0
 lea LEFTCHANDATA,a3
 move.w #3,d1
FindLeftChannel
 tst.b (a3)
 bne.s .notactive
 cmp.b 1(a3),d0
 beq.s FOUNDLEFT
 cmp.w 2(a3),d2
 blt.s .notactive
 move.w 2(a3),d2
 move.l a3,a2
 move.w d5,d6

.notactive:
 add.w #4,a3
 add.w #1,d5
 dbra d1,FindLeftChannel
 move.l a2,a3
 bra.s gopastleft
FOUNDLEFT:
 move.w d5,d6
gopastleft:
 tst.l a3
 bne.s FOUNDALEFT
NONOISE:
 rts
FOUNDALEFT:

 cmp.w noiseloud,d3
 bge.s NONOISE

; d6 = channel number
 move.b d0,1(a3)
 move.w d3,2(a3)

 move.w Samplenum,d5
 move.l #SampleList,a3
 move.l (a3,d5.w*8),a1
 move.l 4(a3,d5.w*8),a2

 tst.b d6
 seq NoiseMade0LEFT
 beq.s .chan0
 cmp.b #2,d6
 slt NoiseMade1LEFT
 blt .chan1
 seq NoiseMade2LEFT
 beq .chan2
 st NoiseMade3LEFT

 move.b d5,LEFTPLAYEDTAB+9
 move.b d3,LEFTPLAYEDTAB+1+9
 move.b d4,LEFTPLAYEDTAB+2+9
 move.b d3,vol3left
 move.l a1,pos3LEFT
 move.l a2,Samp3endLEFT
 bra dorightchan
 
.chan0: 
 move.b d5,LEFTPLAYEDTAB
 move.b d3,LEFTPLAYEDTAB+1
 move.b d4,LEFTPLAYEDTAB+2
 move.l a1,pos0LEFT
 move.l a2,Samp0endLEFT
 move.b d3,vol0left
 bra dorightchan
 
.chan1:
 move.b d5,LEFTPLAYEDTAB+3
 move.b d3,LEFTPLAYEDTAB+1+3
 move.b d4,LEFTPLAYEDTAB+2+3
 move.b d3,vol1left
 move.l a1,pos1LEFT
 move.l a2,Samp1endLEFT
 bra dorightchan

.chan2: 
 move.b d5,LEFTPLAYEDTAB+6
 move.b d3,LEFTPLAYEDTAB+1+6
 move.b d4,LEFTPLAYEDTAB+2+6
 move.l a1,pos2LEFT
 move.l a2,Samp2endLEFT
 move.b d3,vol2left
 
dorightchan:

; Find least important sound on right

 move.l #0,a2
 move.l #0,d5
 move.w #10000,d2
 move.b IDNUM,d0
 lea RIGHTCHANDATA,a3
 move.w #3,d1
FindRightChannel
 tst.b (a3)
 bne.s .notactive
 cmp.b 1(a3),d0
 beq.s FOUNDRIGHT
 cmp.w 2(a3),d2
 blt.s .notactive
 move.w 2(a3),d2
 move.l a3,a2
 move.w d5,d6

.notactive:
 add.w #4,a3
 add.w #1,d5
 dbra d1,FindRightChannel
 move.l a2,a3
 bra.s gopastright
FOUNDRIGHT:
 move.w d5,d6
gopastright:
 tst.l a3
 bne.s FOUNDARIGHT
 rts
FOUNDARIGHT:

; d6 = channel number
 move.b d0,1(a3)
 move.w d3,2(a3)

 move.w Samplenum,d5
 move.l #SampleList,a3
 move.l (a3,d5.w*8),a1
 move.l 4(a3,d5.w*8),a2

 tst.b d6
 seq NoiseMade0RIGHT
 beq.s .chan0
 cmp.b #2,d6
 slt NoiseMade1RIGHT
 blt .chan1
 seq NoiseMade2RIGHT
 beq .chan2
 st NoiseMade3RIGHT

 move.b d5,RIGHTPLAYEDTAB+9
 move.b d3,RIGHTPLAYEDTAB+1+9
 move.b d4,RIGHTPLAYEDTAB+2+9
 move.b d4,vol3right
 move.l a1,pos3RIGHT
 move.l a2,Samp3endRIGHT
 rts
 
.chan0: 
 move.b d5,RIGHTPLAYEDTAB
 move.b d3,RIGHTPLAYEDTAB+1
 move.b d4,RIGHTPLAYEDTAB+2
 move.l a1,pos0RIGHT
 move.l a2,Samp0endRIGHT
 move.b d4,vol0right
 rts
 
.chan1:
 move.b d5,RIGHTPLAYEDTAB+3
 move.b d3,RIGHTPLAYEDTAB+1+3
 move.b d4,RIGHTPLAYEDTAB+2+3
 move.b d3,vol1right
 move.l a1,pos1RIGHT
 move.l a2,Samp1endRIGHT
 rts

.chan2: 
 move.b d5,RIGHTPLAYEDTAB+6
 move.b d3,RIGHTPLAYEDTAB+1+6
 move.b d4,RIGHTPLAYEDTAB+2+6
 move.l a1,pos2RIGHT
 move.l a2,Samp2endRIGHT
 move.b d3,vol2right
 rts

NOSTEREO:
 move.l #0,a2
 move.l #-1,d5
 move.w #32767,d2
 move.b IDNUM,d0
 lea CHANNELDATA,a3
 move.w #7,d1
FindChannel
 tst.b (a3)
 bne.s .notactive
 cmp.b 1(a3),d0
 beq.s FOUNDCHAN
 cmp.w 2(a3),d2
 blt.s .notactive
 move.w 2(a3),d2
 move.l a3,a2
 move.w d5,d6
 add.w #1,d6

.notactive:
 add.w #4,a3
 add.w #1,d5
 dbra d1,FindChannel
 
 move.l a2,a3
 bra.s gopastchan
FOUNDCHAN:
 move.w d5,d6
 add.w #1,d6
gopastchan:
 tst.w d6
 bge.s FOUNDACHAN
tooquiet:
 rts
FOUNDMYCHAN:
 move.w 2(a3),d2

FOUNDACHAN:

; d6 = channel number

 cmp.w noiseloud,d2
 bgt.s tooquiet

 move.b d0,1(a3)
 move.w noiseloud,2(a3)

 move.w Samplenum,d5
 move.l #SampleList,a3
 move.l (a3,d5.w*8),a1
 move.l 4(a3,d5.w*8),a2

 tst.b d6
 beq .chan0
 cmp.b #2,d6
 blt .chan1
 beq .chan2
 cmp.b #4,d6
 blt .chan3
 beq .chan4
 cmp.b #6,d6
 blt .chan5
 beq .chan6
 st NoiseMade3RIGHT

 move.b d5,RIGHTPLAYEDTAB+9
 move.b d3,RIGHTPLAYEDTAB+1+9
 move.b d4,RIGHTPLAYEDTAB+2+9
 move.b d4,vol3right
 move.l a1,pos3RIGHT
 move.l a2,Samp3endRIGHT
 rts

.chan3:
 st NoiseMade3LEFT
 move.b d5,LEFTPLAYEDTAB+9
 move.b d3,LEFTPLAYEDTAB+1+9
 move.b d4,LEFTPLAYEDTAB+2+9
 move.b d3,vol3left
 move.l a1,pos3LEFT
 move.l a2,Samp3endLEFT
 bra dorightchan
 
.chan0: 
 st NoiseMade0LEFT
 move.b d5,LEFTPLAYEDTAB
 move.b d3,LEFTPLAYEDTAB+1
 move.b d4,LEFTPLAYEDTAB+2
 move.l a1,pos0LEFT
 move.l a2,Samp0endLEFT
 move.b d3,vol0left
 rts
 
.chan1:
 st NoiseMade1LEFT
 move.b d5,LEFTPLAYEDTAB+3
 move.b d3,LEFTPLAYEDTAB+1+3
 move.b d4,LEFTPLAYEDTAB+2+3
 move.b d3,vol1left
 move.l a1,pos1LEFT
 move.l a2,Samp1endLEFT
 rts

.chan2: 
 st NoiseMade2LEFT
 move.b d5,LEFTPLAYEDTAB+6
 move.b d3,LEFTPLAYEDTAB+1+6
 move.b d4,LEFTPLAYEDTAB+2+6
 move.l a1,pos2LEFT
 move.l a2,Samp2endLEFT
 move.b d3,vol2left
 rts
 
.chan4: 
 st NoiseMade0RIGHT
 move.b d5,RIGHTPLAYEDTAB
 move.b d3,RIGHTPLAYEDTAB+1
 move.b d4,RIGHTPLAYEDTAB+2
 move.l a1,pos0RIGHT
 move.l a2,Samp0endRIGHT
 move.b d4,vol0right
 rts
 
.chan5:
 st NoiseMade1RIGHT
 move.b d5,RIGHTPLAYEDTAB+3
 move.b d3,RIGHTPLAYEDTAB+1+3
 move.b d4,RIGHTPLAYEDTAB+2+3
 move.b d3,vol1right
 move.l a1,pos1RIGHT
 move.l a2,Samp1endRIGHT
 rts

.chan6: 
 st NoiseMade2RIGHT
 move.b d5,RIGHTPLAYEDTAB+6
 move.b d3,RIGHTPLAYEDTAB+1+6
 move.b d4,RIGHTPLAYEDTAB+2+6
 move.l a1,pos2RIGHT
 move.l a2,Samp2endRIGHT
 move.b d3,vol2right
 rts


audpos1: dc.w 0
audpos1b: dc.w 0
audpos2: dc.w 0
audpos2b: dc.w 0
audpos3: dc.w 0
audpos3b: dc.w 0
audpos4: dc.w 0
audpos4b: dc.w 0

vol0left: dc.w 0
vol0right: dc.w 0
vol1left: dc.w 0
vol1right: dc.w 0
vol2left: dc.w 0
vol2right: dc.w 0
vol3left: dc.w 0
vol3right: dc.w 0

pos: dc.l 0

pos0LEFT: dc.l empty
pos1LEFT: dc.l empty
pos2LEFT: dc.l empty
pos3LEFT: dc.l empty
pos0RIGHT: dc.l empty
pos1RIGHT: dc.l empty
pos2RIGHT: dc.l empty
pos3RIGHT: dc.l empty


empty: ds.l 100
emptyend:


playnull0: dc.w 0
playnull1: dc.w 0
playnull2: dc.w 0
playnull3: dc.w 0

Samp0endRIGHT: dc.l emptyend
Samp1endRIGHT: dc.l emptyend
Samp2endRIGHT: dc.l emptyend
Samp3endRIGHT: dc.l emptyend
Samp0endLEFT: dc.l emptyend
Samp1endLEFT: dc.l emptyend
Samp2endLEFT: dc.l emptyend
Samp3endLEFT: dc.l emptyend

null: ds.b 500
null2: ds.b 500
null3: ds.b 500
null4: ds.b 500

Aupt0: dc.l null
Auback0: dc.l null+500
Aupt2: dc.l null3
Auback2: dc.l null3+500
Aupt3: dc.l null4
Auback3: dc.l null4+500
Aupt1: dc.l null2
Auback1: dc.l null2+500

NoiseMade0LEFT: dc.b 0
NoiseMade1LEFT: dc.b 0
NoiseMade2LEFT: dc.b 0
NoiseMade3LEFT: dc.b 0
NoiseMade0pLEFT: dc.b 0
NoiseMade1pLEFT: dc.b 0
NoiseMade2pLEFT: dc.b 0
NoiseMade3pLEFT: dc.b 0
NoiseMade0RIGHT: dc.b 0
NoiseMade1RIGHT: dc.b 0
NoiseMade2RIGHT: dc.b 0
NoiseMade3RIGHT: dc.b 0
NoiseMade0pRIGHT: dc.b 0
NoiseMade1pRIGHT: dc.b 0
NoiseMade2pRIGHT: dc.b 0
NoiseMade3pRIGHT: dc.b 0

SampleList:
 dc.l 0,0
 dc.l 0,0
 dc.l 0,0
 dc.l 0,0
 dc.l 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
 dc.l 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
 dc.l 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
 dc.l 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0

 dc.l 0
Samplenum: dc.w 0
Noisex: dc.w 0
Noisez: dc.w 0
Noisevol: dc.w 0
chanpick: dc.w 0
IDNUM: dc.w 0
needleft: dc.b 0
needright: dc.b 0
notifplaying: dc.w 0
STEREO: dc.b $0
even
prot6: dc.w 0

 even
 
CHANNELDATA:
LEFTCHANDATA:
 dc.l $00000000
 dc.l $00000000
 dc.l $FF000000
 dc.l $FF000000
RIGHTCHANDATA:
 dc.l $00000000
 dc.l $00000000
 dc.l $FF000000
 dc.l $FF000000
 
RIGHTPLAYEDTAB: ds.l 20
LEFTPLAYEDTAB: ds.l 20
achan