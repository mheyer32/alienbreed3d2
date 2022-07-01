CHUNKYTOPLANAR
 move.w d2,MODUL
 move.w d0,WTC
 
 move.w d1,HTC
 move.w d3,SCRMOD
 
 add.l #10240*7,a1
 lea -10240(a1),a2
 lea -10240(a2),a3
 lea -10240(a3),a4
 move.l a4,a5
 sub.l #20480,a5
 move.l a5,a6
 sub.l #20480,a6
outconv:

convlop:
 swap d7
 move.l (a0)+,d0

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
 move.b d4,10240(a5)
 
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
 move.b d6,10240(a6)

 rol.w #1,d7
 move.b d7,(a6)+
 subq #1,WTC
 bgt.s convlop

 add.w MODUL,a0
 move.w SCRMOD,d0
 add.w d0,a1
 add.w d0,a2
 add.w d0,a3
 add.w d0,a4
 add.w d0,a5
 add.w d0,a6

 subq #1,HTC
 bgt outconv

 rts

MODUL: dc.w 0
HTC: dc.w 0
WTC: dc.w 0
SCRMOD: dc.w 0