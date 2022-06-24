conaddr: dc.l 0
linkaddr: dc.l 0
distaddr: dc.l 0
num: dc.w 0

start:
 lea conaddr(pc),a0
 move.w 12(a0),d7
 move.l 8(a0),a2
 move.l 4(a0),a1
 move.l (a0),a0

 move.l a1,a3
 move.l a2,a4
 move.w d7,d0
 muls d0,d0
 subq #1,d0
initloop:
 move.b #-1,(a3)+
 move.w #1000,(a4)+
 dbra d0,initloop

* Now link all those ones connected
* directly

 move.l a0,a3
 move.l a1,a4
 move.l a2,a5
 move.w d7,d0
 move.w #0,d2
downlink:
 move.w d7,d1
 move.w #0,d3
acrosslink:

 tst.b (a3)+
 beq.s nolink
 move.b d3,(a4)
 move.w #1,(a5)
nolink:
 addq #1,a4
 addq #2,a5

 addq #1,d3
 subq #1,d1
 bgt.s acrosslink

 addq #1,d2
 subq #1,d0
 bgt.s downlink

* Now repeatedly branch to a routine
* which links up the indirect ones.

 move.w d7,d6
repeat:

 movem.l d0-d7/a0-a6,-(a7)
 bsr indirect
 movem.l (a7)+,d0-d7/a0-a6

 subq.w #1,d6
 bgt.s repeat
 
 rts

indirect:

 moveq #0,d0
 moveq #0,d1
 move.l a1,a4
 move.l a2,a5

downind:
 moveq #0,d1
 move.l a0,a3
 
acrossind:

 tst.b (a0)+
 bne.s alreadydone
 tst.w (a1)
 bge.s alreadydone

 moveq #0,d2
 move.w #1000,d3
 move.w #-1,d6
 movem.l a3/a4/a5,-(a7)

lookthroughloop:
 tst.b (a3)+
 beq.s notcon
 move.w d2,d4
 muls d7,d4
 ext.l d1
 add.l d1,d4
 tst.b (a4,d4.l)
 blt.s notcon
 
 cmp.w (a5,d4.l*2),d3
 blt.s notcon

 move.w (a5,d4.l*2),d3
 move.b d2,d6

notcon:
 
 addq #1,d2
 cmp.w d7,d2
 blt.s lookthroughloop
 
 tst.b d6
 blt.s notfoundone

 move.b d6,(a1)
 add.w #1,d3
 move.w d3,(a2)

notfoundone:
 
 movem.l (a7)+,a3/a4/a5

alreadydone:
 addq #1,a1
 addq #2,a2

 addq #1,d1
 cmp.w d7,d1
 blt.s acrossind
 addq #1,d0
 cmp.w d7,d0
 blt.s downind
 
 rts
 