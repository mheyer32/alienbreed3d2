
strt:

MODIT MACRO
 divs #800,\1
 swap \1
 ENDM

 moveq #0,d3
 move.w d1,d3
 move.l d3,d1
 divu #50,d1
 lsr.w #8,d3
 swap d1
 swap d2
 clr.w d2
 swap d2
 divu #17,d2
 swap d2
 addq #1,d1
 addq #1,d2
 divu #7,d3
 swap d3
 lea TABLE(pc),a0
 asl.w #4,d3
 add.w d3,a0

 move.w d1,d0	;row
 muls d0,d0	;row*row
 MODIT d0
 move.w d2,d4	;col
 muls d4,d4	;col*col
 MODIT d4	
 move.w d0,d5	;row*row
 muls d5,d5	;row*row*row*row
 MODIT d5 
 move.w d4,d6	;col*col
 muls d6,d6	;col*col*col*col
 MODIT d6	
 muls d5,d6	;row*row*row*row*col*col*col*col
 MODIT d6
 muls (a0),d6	;*var a
 MODIT d6
 
 muls d1,d4
 MODIT d4
 muls d2,d4
 muls 2(a0),d4
 MODIT d4
 add.w d4,d6
 
 move.w d1,d0
 muls d2,d0
 MODIT d0
 muls 4(a0),d0
 MODIT d0
 add.w d0,d6
 muls 6(a0),d1
 MODIT d1
 muls 8(a0),d2
 MODIT d2
 add.w d1,d2
 add.w d2,d6
 add.w 10(a0),d6
 ext.l d6
 MODIT d6
 neg.w d6
 add.w #999,d6
 move.w d6,d0
 rts

TABLE:
 dc.w 14,58,64,25,94,36,0,0
 dc.w 22,9,16,34,65,87,0,0
 dc.w 132,62,97,112,154,38,0,0
 dc.w 174,192,46,36,74,86,0,0
 dc.w 32,62,94,96,66,55,0,0
 dc.w 162,111,98,10,20,31,0,0
 dc.w 58,34,99,35,100,75,0,0

edn:

