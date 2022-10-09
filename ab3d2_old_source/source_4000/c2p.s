 
 move.l #CBUFF,a0

convlop:
 move.l (a0)+,d1
 move.w d1,d0
 swap d1
 move.l (a0)+,d3
 move.w d3,d2
 swap d3
 move.l (a0)+,d5
 move.w d5,d4
 swap d4
 move.l (a0)+,d7
 move.w d7,d6
 swap d7
 
 cmp.l #ENDCBUFF,a0
 beq DONEALL

 add.w d0,d0
 addx.w d0,d0
 addx.w d1,d1
 addx.w d0,d0
 addx.w d2,d2
 addx.w d0,d0
 addx.w d3,d3
 addx.w d0,d0
 addx.w d4,d4
 addx.w d0,d0
 addx.w d5,d5
 addx.w d0,d0
 addx.w d6,d6
 addx.w d0,d0
 addx.w d7,d7
 addx.w d0,d0
 move.b d0,(a1)+
 move.b d1,d0
 add.w d1,d1
 move.b d0,d1
 addx.w d1,d1
 addx.w d2,d2
 addx.w d1,d1
 addx.w d3,d3
 addx.w d1,d1
 addx.w d4,d4
 addx.w d1,d1
 addx.w d5,d5
 addx.w d1,d1
 addx.w d6,d6
 addx.w d1,d1
 addx.w d7,d7
 addx.w d1,d1
 move.b d1,(a2)+
 
 move.w d2,d0
 add.w d2,d2
 move.b d0,d2
 addx.w d2,d2
 addx.w d3,d3
 addx.w d2,d2
 addx.w d4,d4
 addx.w d2,d2
 addx.w d5,d5
 addx.w d2,d2
 addx.w d6,d6
 addx.w d2,d2
 addx.w d7,d7
 addx.w d2,d2
 move.b d2,(a3)+
 
 move.w d3,d0
 add.w d3,d3
 move.b d0,d3
 addx.w d3,d3
 addx.w d4,d4
 addx.w d3,d3
 addx.w d5,d5
 addx.w d3,d3
 addx.w d6,d6
 addx.w d3,d3
 addx.w d7,d7
 addx.w d3,d3
 move.b d3,(a4)+
 
 move.b d4,d0
 add.w d4,d4
 move.b d0,d4
 addx.w d4,d4
 addx.w d5,d5
 addx.w d4,d4
 addx.w d6,d6
 addx.w d4,d4
 addx.w d7,d7
 addx.w d4,d4
 move.b d4,-40(a5)
 
 move.b d5,d0
 add.w d5,d5
 move.b d0,d5
 addx.w d5,d5
 addx.w d6,d6
 addx.w d5,d5
 addx.w d7,d7
 addx.w d5,d5
 move.b d5,(a5)+
 
 move.b d6,d0
 add.w d6,d6
 move.b d0,d6
 addx.w d6,d6
 addx.w d7,d7
 addx.w d6,d6
 move.b d6,-40(a6)

 rol.w #1,d7
 move.b d7,(a6)+
 
 bra convlop

DONEALL:
 
byte0: dc.l 0,0

