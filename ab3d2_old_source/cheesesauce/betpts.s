;0
Darray: dc.l 0
;4
PXarray: dc.l 0
;8
PYarray: dc.l 0
;12
ZWT:
LParray:
x1: dc.w 0
y1: dc.w 0
;16
RParray:
x2: dc.w 0
y2: dc.w 0
;20
VCPL:
x3: dc.w 0
VCPR:
y3: dc.w 0
x4: dc.w 0
y4: dc.w 0
PTS: dc.w 0
PWarray: dc.l 0
PUarray: dc.l 0
FL: dc.w 0
;40
OP: dc.w 0
;42
FOarray: dc.l 0
;46
ZOarray: dc.l 0
;50
FP: dc.w 0
;52
ZP: dc.w 0
;54
Start:

 movem.l d0-d7/a0-a6,-(a7)
 
 move.w OP(pc),d0
 cmp.w #1,d0
 blt BETPTS
 beq CALCORD
 cmp.w #3,d0
 blt CHKINVIS
 beq ELIMINLEFT

ELIMINRIGHT:
 
 lea sol(pc),a5
 move.l LParray(pc),a0
 move.l PXarray(pc),a2
 move.l PYarray(pc),a3
 move.w VCPL(pc),d7
 subq #1,d7
.outer
 move.w VCPL(pc),d6
 subq #1,d6
 sub.w d7,d6
 move.w d7,-(a7)

 move.l (a0)+,d0
 blt .notthis
 move.l (a3,d0.w*4),d1
 move.l (a2,d0.w*4),d0
 move.l a0,a1

.inner
 move.w #0,(a5)
 move.l (a1)+,d2
 blt.s .notinn
 move.l (a3,d2.w*4),d3
 move.l (a2,d2.w*4),d2
 sub.w d1,d3
 sub.w d0,d2
 
 move.w ZP(pc),d7
 move.l ZOarray(pc),a4
.dest:
 move.l (a4)+,d4
 move.l (a3,d4.w*4),d5
 move.l (a2,d4.w*4),d4
 sub.w d0,d4
 sub.w d1,d5
 muls d2,d5
 muls d3,d4
 sub.l d4,d5
 beq.s .neither
 bgt.s .ssor
 st (a5)
 bra.s .neither
.ssor:
 st 1(a5)
.neither:
 dbra d7,.dest

 move.b (a5),d4
 move.b 1(a5),d5
 tst.b d4
 beq.s .nol
 tst.b d5
 bne.s .onboth
 move.l #-1,-4(a1)
 bra.s .onboth 

.nol:
 tst.b d5
 beq.s .onboth
 move.l #-1,-4(a0)

.onboth:

.notinn:
 dbra d6,.inner

.notthis:

 move.w (a7)+,d7
 dbra d7,.outer

 move.l LParray(pc),a0
 move.w VCPL(pc),d0
 move.l a0,a1
 move.w #0,d1
.elim:
 move.l (a0)+,d2
 blt.s .doit
 move.l d2,(a1)+
 addq #1,d1
.doit:
 dbra d0,.elim

 lea OP(pc),a0
 move.w d1,(a0)

 movem.l (a7)+,d0-d7/a0-a6
 rts


ELIMINLEFT:
 
 lea sol(pc),a5
 move.l LParray(pc),a0
 move.l PXarray(pc),a2
 move.l PYarray(pc),a3
 move.w #0,d7
.outer
 move.w d7,d6
 addq #1,d6
 move.w d7,-(a7)

 move.l (a0)+,d0
 blt .notthis
 move.l (a3,d0.w*4),d1
 move.l (a2,d0.w*4),d0
 move.l a0,a1

.inner
 move.w #0,(a5)
 move.l (a1)+,d2
 blt.s .notinn
 move.l (a3,d2.w*4),d3
 move.l (a2,d2.w*4),d2
 sub.w d1,d3
 sub.w d0,d2
 
 move.w ZP(pc),d7
 move.l ZOarray(pc),a4
.dest:
 move.l (a4)+,d4
 move.l (a3,d4.w*4),d5
 move.l (a2,d4.w*4),d4
 sub.w d0,d4
 sub.w d1,d5
 muls d2,d5
 muls d3,d4
 sub.l d4,d5
 beq.s .neither
 bgt.s .ssor
 st (a5)
 bra.s .neither
.ssor:
 st 1(a5)
.neither:
 dbra d7,.dest

 move.b (a5),d4
 move.b 1(a5),d5
 tst.b d4
 beq.s .nol
 tst.b d5
 bne.s .onboth
 move.l #-1,-4(a0)
 bra.s .onboth 

.nol:
 tst.b d5
 beq.s .onboth
 move.l #-1,-4(a1)

.onboth:

.notinn:
 add.w #1,d6
 move.w VCPL(pc),d5
 subq #1,d5
 cmp.w d5,d6
 ble .inner

.notthis:

 move.w (a7)+,d7
 addq #1,d7
 move.w VCPL(pc),d5
 sub.w #2,d5
 cmp.w d5,d7
 ble .outer

 move.l LParray(pc),a0
 move.w VCPL(pc),d0
 sub #1,d0
 move.l a0,a1
 move.w #0,d1
.elim:
 move.l (a0)+,d2
 blt.s .doit
 move.l d2,(a1)+
 addq #1,d1
.doit:
 dbra d0,.elim

 lea OP(pc),a0
 move.w d1,(a0)

 movem.l (a7)+,d0-d7/a0-a6
 rts

CHKINVIS:
 
 move.l LParray(pc),a0
 move.l PXarray(pc),a2
 move.l PYarray(pc),a3
 move.w VCPL(pc),d7

.outer:
 move.w d7,-(a7)

 move.l (a0)+,d0
 move.l (a3,d0.w*4),d1
 move.l (a2,d0.w*4),a5
 move.l RParray(pc),a1
 move.w VCPR(pc),d7
.inner:
 move.l (a1)+,d2
 move.l (a3,d2.w*4),d3
 move.l (a2,d2.w*4),d2
 sub.w a5,d2
 sub.w d1,d3

 move.l FOarray(pc),a4
 move.w FP(pc),d6

.source:
 move.l (a4)+,d4
 move.l (a3,d4.w*4),d5
 move.l (a2,d4.w*4),d4
 sub.w a5,d4
 sub.w d1,d5
 muls d2,d5
 muls d3,d4
 sub.l d4,d5
 sgt d0
 dbgt d6,.source

.outsource:
 
 tst.b d0
 bne.s .notinvis1
 lea OP(pc),a0
 move.w #1,(a0)
 move.w (a7)+,d7
 bra .missout
 
.notinvis1:

 move.l ZOarray(pc),a4
 move.w ZP(pc),d6

.dest:
 move.l (a4)+,d4
 move.l (a3,d4.w*4),d5
 move.l (a2,d4.w*4),d4
 sub.w a5,d4
 sub.w d1,d5
 muls d2,d5
 muls d3,d4
 sub.l d4,d5
 slt d0
 dblt d6,.dest

.outdest:
 
 tst.b d0
 bne.s .notinvis2
 lea OP(pc),a0
 move.w #1,(a0)
 move.w (a7)+,d7
 bra .missout
 
.notinvis2:

 dbra d7,.inner
 
 move.w (a7)+,d7
 dbra d7,.outer

 lea OP(pc),a0
 move.w #0,(a0)
 
.missout: 
 
 movem.l (a7)+,d0-d7/a0-a6
 rts

CALCORD:

 move.l ZWT(pc),a4
 move.l ZOarray(pc),a1
 move.l PXarray(pc),a2
 move.l PYarray(pc),a3
 move.w ZP(pc),d7
 lea sol(pc),a5

 moveq #0,d0
 moveq #1,d1

.outer:

 move.w d7,-(a7)

 move.l (a1)+,d3
 cmp.l #1,(a4)+
 beq .wallnotline
 move.w FP(pc),d6
 move.l FOarray(pc),a0
 
 move.l (a1),d2
 move.l (a2,d3.w*4),d7
 move.l (a3,d3.w*4),a6
 move.l (a3,d2.w*4),d3
 move.l (a2,d2.w*4),d2
 sub.w d7,d2
 sub.w a6,d3
 clr.w (a5)
 
.inner:
 move.l (a0)+,d4
 move.l (a3,d4.w*4),d5
 move.l (a2,d4.w*4),d4
 sub.w d7,d4
 sub.w a6,d5
 muls d2,d5
 muls d3,d4
 sub.l d4,d5
 beq.s .noset
 bgt.s .setr
 st (a5)
 bra.s .noset
.setr:
 st 1(a5) 
.noset:

 dbra d6,.inner
 
 tst.b (a5)
 beq.s .nosol
 tst.b 1(a5)
 bne.s .nothing
 bset d1,d0
 bra.s .nothing
 
.nosol:
 tst.b 1(a5)
 beq.s .nothing 
 bset d1,d0
 addq #1,d1
 bset d1,d0
 subq #1,d1

.nothing:

.wallnotline:
 
 addq #3,d1
 
 move.w (a7)+,d7
 dbra d7,.outer
 
 lea FP(pc),a0
 move.l d0,(a0)
 
 movem.l (a7)+,d0-d7/a0-a6
 rts

sol: dc.b 0
sor: dc.b 0

BETPTS: 
 move.w #16,d6
 move.l Darray(pc),a0
 move.l PXarray(pc),a1
 move.l PYarray(pc),a2
 move.l PWarray(pc),a4
 lea x1(pc),a3
 move.w PTS(pc),d7

 move.w 4(a3),d2
 move.w (a3),d0
 sub.w d0,d2
 move.w 6(a3),d3
 move.w 2(a3),d1
 sub.w d1,d3

calcd1loop:
 move.l (a1)+,d4
 move.l (a2)+,d5
 tst.l (a4)+
 beq.s no1
 sub.w d0,d4
 sub.w d1,d5
 muls d2,d5
 muls d3,d4
 sub.l d4,d5
 move.l d5,(a0)
no1:
 adda.w d6,a0
 dbra d7,calcd1loop

 move.l Darray(pc),a0
 addq.l #4,a0
 move.l PXarray(pc),a1
 move.l PYarray(pc),a2
 move.l PWarray(pc),a4
 move.w PTS(pc),d7

 move.w 8(a3),d2
 move.w 4(a3),d0
 sub.w d0,d2
 move.w 10(a3),d3
 move.w 6(a3),d1
 sub.w d1,d3

calcd2loop:
 move.l (a1)+,d4
 move.l (a2)+,d5
 tst.l (a4)+
 beq.s no2
 sub.w d0,d4
 sub.w d1,d5
 muls d2,d5
 muls d3,d4
 sub.l d4,d5
 move.l d5,(a0)
no2:
 adda.w d6,a0
 dbra d7,calcd2loop


 move.l Darray(pc),a0
 addq #8,a0
 move.l PXarray(pc),a1
 move.l PYarray(pc),a2
 move.l PWarray(pc),a4
 move.w PTS(pc),d7

 move.w 12(a3),d2
 move.w 8(a3),d0
 sub.w d0,d2
 move.w 14(a3),d3
 move.w 10(a3),d1
 sub.w d1,d3

calcd3loop:
 move.l (a1)+,d4
 move.l (a2)+,d5
 tst.l (a4)+
 beq.s no3
 sub.w d0,d4
 sub.w d1,d5
 muls d2,d5
 muls d3,d4
 sub.l d4,d5
 move.l d5,(a0)
no3:
 add.w d6,a0
 dbra d7,calcd3loop

 move.l Darray(pc),a0
 adda.w #12,a0
 move.l PXarray(pc),a1
 move.l PYarray(pc),a2
 move.l PWarray(pc),a4
 move.w PTS(pc),d7

 move.w (a3),d2
 move.w 12(a3),d0
 sub.w d0,d2
 move.w 2(a3),d3
 move.w 14(a3),d1
 sub.w d1,d3

calcd4loop:
 move.l (a1)+,d4
 move.l (a2)+,d5
 tst.l (a4)+
 beq.s no4
 
 sub.w d0,d4
 sub.w d1,d5
 muls d2,d5
 muls d3,d4
 sub.l d4,d5
 move.l d5,(a0)
no4:
 add.w d6,a0
 dbra d7,calcd4loop
 
 move.w PTS(pc),d7
 move.l Darray(pc),a0
 move.l PWarray(pc),a1
 move.l PUarray(pc),a2
 move.w FL(pc),d0
 cmp.w #1,d0
 beq FLFR
 bgt TLTR

.chck

 moveq #0,d5
 tst.l (a1)+
 beq.s .no

; If all d>0:
; =-3

*
; if d0<=0
; =-4
; if d1<=0 or d3<=0
; =5

*

; if d2<=0
; =-2
; if d1<=0 or d3<=0
; =-1

 move.l (a0),d0
 sle d0
 move.l 4(a0),d1
 sle d1
 move.l 8(a0),d2
 sle d2
 move.l 12(a0),d3
 sle d3

 moveq #-3,d5

 move.b d0,d4
 or.b d1,d4
 or.b d2,d4
 or.b d3,d4
 beq.s .allok
 moveq #0,d5

 tst.b d0
 beq.s .notf
 moveq #-4,d5
 or.b d1,d3
 beq.s .allok
 moveq #-5,d5 
 bra.s .allok
.notf:

 tst.b d2
 beq.s .nots
 moveq #-2,d5
 or.b d1,d3
 beq.s .allok
 moveq #-1,d5
.nots
 
.allok:
 
.no
 move.l d5,(a2)+
 adda.w d6,a0
 dbra d7,.chck
 
 movem.l (a7)+,d0-d7/a0-a6
 rts
 
FLFR:

.chck
 moveq #0,d5
 tst.l (a1)+
 beq.s .no
 
 move.l (a0),d0
 sle d0
 move.l 4(a0),d1
 sle d1
 move.l 8(a0),d2
 sle d2

 moveq #-3,d5

 move.b d0,d3
 or.b d1,d3
 or.b d2,d3
 beq.s .allok
 moveq #0,d5
 
 tst.b d0
 beq.s .notf
 moveq #-4,d5
 or.b d1,d2
 beq.s .allok
 moveq #0,d5
 bra.s .allok
.notf

 tst.b d2
 beq.s .nots
 moveq #-2,d5
 or.b d1,d0
 beq.s .allok
 moveq #0,d5
.nots
 
.allok
 
.no
 move.l d5,(a2)+
 adda.w d6,a0
 dbra d7,.chck
 movem.l (a7)+,d0-d7/a0-a6
 rts

TLTR:
.chck
 moveq #0,d5
 tst.l (a1)+
 beq.s .no

 move.l (a0),d0
 sle d0
 move.l 12(a0),d1
 sle d1
 move.l 8(a0),d2
 sle d2

 moveq #-3,d5

 move.b d0,d3
 or.b d1,d3
 or.b d2,d3
 beq.s .allok
 moveq #0,d5
 
 tst.b d0
 beq.s .notf
 moveq #-4,d5
 or.b d1,d2
 beq.s .allok
 moveq #0,d5
 bra.s .allok
.notf

 tst.b d2
 beq.s .nots
 moveq #-2,d5
 or.b d1,d0
 beq.s .allok
 moveq #0,d5
.nots
 
.allok
 
 
.no
 move.l d5,(a2)+
 adda.w d6,a0
 dbra d7,.chck
 movem.l (a7)+,d0-d7/a0-a6
 rts
