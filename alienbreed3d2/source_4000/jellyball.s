VARPTRS: 
 dc.l 0
 dc.l 0
 dc.w 0
 dc.l 0

START:

 lea VARPTRS(pc),a6
 move.l (a6),a0
 move.l 4(a6),a1
 move.w 8(a6),d7		; num points
 move.l 10(a6),a4
 
 move.w d7,d6
 sub.w #2,d6
 
OUTERLOP:
 lea.l 12(a0),a2
 lea.l 12(a1),a3

 move.w d6,d7

INNERLOP:
 move.l a4,d3

 move.l (a2),d0
 sub.l (a0),d0
 
 cmp.l d0,d3
 blt.s outrange
 neg.l d3
 cmp.l d0,d3
 bgt.s outrange
 neg.l d3
 
 move.l 4(a2),d1
 sub.l 4(a0),d1

 cmp.l d1,d3
 blt.s outrange
 neg.l d3
 cmp.l d1,d3
 bgt.s outrange
 neg.l d3

 move.l 8(a2),d2
 sub.l 8(a0),d2

 cmp.l d2,d3
 blt.s outrange
 neg.l d3
 cmp.l d2,d3
 bgt.s outrange
 neg.l d3

 move.l d0,d3
 move.l d1,d4
 move.l d2,d5

 muls d0,d0
 muls d1,d1
 muls d2,d2
 add.l d0,d1
 add.l d1,d2
 
 bsr CALCSQROOT
 move.l a4,d0
 cmp.l d0,d2
 bgt outrange
 
 sub.l d2,d0	; md-d
 add.l d2,d2
 muls d0,d3
 divs d2,d3
 ext.l d3
 sub.l d3,(a1)
 add.l d3,(a3)
 
 muls d0,d4
 divs d2,d4
 ext.l d4
 sub.l d4,4(a1)
 add.l d4,4(a3)
 
 muls d0,d5
 divs d2,d5
 ext.l d5 
 sub.l d5,8(a1)
 add.l d5,8(a3)
 
outrange:

 adda.w #12,a2 
 adda.w #12,a3 

 dbra d7,INNERLOP
 
 adda.w #12,a0
 adda.w #12,a1
 
 dbra d6,OUTERLOP
 
 move.w 8(a6),d7
 move.l (a6),a0
 move.l 4(a6),a1
 
 subq #1,d7
 
MOVEANDNORM:

 move.l (a1),d0
 add.l (a0),d0
 move.l 4(a1),d1
 add.l 4(a0),d1
 move.l 8(a1),d2
 add.l 8(a0),d2

 move.l d0,d3
 move.l d1,d4
 move.l d2,d5

 muls d0,d0
 muls d1,d1
 muls d2,d2
 add.l d0,d1
 add.l d1,d2
 bsr CALCSQROOT
 
 muls #10000,d3
 muls #10000,d4
 muls #10000,d5
 divs d2,d3
 divs d2,d4
 divs d2,d5
 
 ext.l d3
 ext.l d4
 ext.l d5
 
 move.l d3,(a0)+
 move.l d4,(a0)+
 move.l d5,(a0)+

 REPT 3
 move.l (a1),d0
 muls #240,d0
 asr.l #8,d0
 move.l d0,(a1)+
 endr


 dbra d7,MOVEANDNORM
 
 
 rts
 
CALCSQROOT:

 tst.l d2
 beq .oksqr

 movem.l d0/d1/d3-d7/a0-a6,-(a7)

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

 move.w d0,d1
 muls d1,d1	; x*x
 sub.l d2,d1	; x*x-a
 asr.l #1,d1	; (x*x-a)/2
 divs d0,d1	; (x*x-a)/2x
 sub.w d1,d0	; second approx
 bgt .stillnot0
 move.w #1,d0
.stillnot0

 move.w d0,d1
 muls d1,d1
 sub.l d2,d1
 asr.l #1,d1
 divs d0,d1
 sub.w d1,d0	; second approx
 bgt .stillnot02
 move.w #1,d0
.stillnot02

 move.w d0,d1
 muls d1,d1
 sub.l d2,d1
 asr.l #1,d1
 divs d0,d1
 sub.w d1,d0	; second approx
 bgt .stillnot03
 move.w #1,d0
.stillnot03

 move.w d0,d2
 ext.l d2

 movem.l (a7)+,d0/d1/d3-d7/a0-a6
 
.oksqr
 rts

