INPUTS:
 dc.l 0
 dc.l 0
 dc.l 0
 dc.l 0
 dc.l 0
 
START:

 lea INPUTS(pc),a0
 
 move.l (a0),a1
 move.l 16(a0),a2
 
 move.w #0,d0
PALOP:
 move.w #0,d1
ALOP:
 move.w #32,d2
 sub.w d1,d2
 move.w #7,d3
 move.l 12(a0),a6
 move.l 8(a0),a5
 move.l 4(a0),a4
 move.w d0,d4
 move.w d0,-(a7)
 asl.w #5,d4
 add.w d4,a6
 add.w d4,a5
 add.w d4,a4
QLOP:
 move.l (a4)+,d4
 move.l (a5)+,d5
 move.l (a6)+,d6
 muls d2,d4
 muls d2,d5
 muls d2,d6
 asr.l #5,d4
 asr.l #5,d5
 asr.l #5,d6
 move.l #10000000,d7
 movem.l d1/d2/d3/a1,-(a7)
 
 move.w #255,d0
findbest:

 move.l (a1)+,d1
 sub.l d4,d1
 muls d1,d1
 move.l (a1)+,d2
 sub.l d5,d2
 muls d2,d2
 move.l (a1)+,d3
 sub.l d6,d3
 muls d3,d3
 
 add.l d3,d2
 add.l d2,d1
 
 cmp.l d1,d7
 blt.s .notnewbest
 
 move.l d1,d7
 move.b d0,d1
 swap d0
 move.w d1,d0
 swap d0
 
.notnewbest: 
 dbra d0,findbest
 
 movem.l (a7)+,d1/d2/d3/a1
 
 swap d0
 not.b d0
 move.b d0,(a2)+
 
 dbra d3,QLOP
 move.w (a7)+,d0
 addq #1,d1
 cmp.w #32,d1
 blt ALOP
 addq #1,d0
 cmp.w #4,d0
 blt PALOP

 rts