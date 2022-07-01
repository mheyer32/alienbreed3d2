start: dc.l 0
end: dc.l 0
data: dc.l 0
hof: dc.w 0

 lea start(pc),a0
 move.l (a0),a1
 move.l 4(a0),a2
 move.l 8(a0),a3
 moveq #0,d7
 move.w 12(a0),d7
 move.l #0,d2
 move.l #-1,d3

findlop:
 move.l a1,a4
 move.l a3,a5
 move.w d7,d0
 asr.w #2,d0
 subq #1,d0
tstlop:
 move.l (a4)+,d1
 cmp.l (a5)+,d1
 bne.s notsame
 dbra d0,tstlop
 move.l d2,(a0)
 rts

notsame:
 add.l d7,d2
 adda.w d7,a1
 cmp.l a2,a1
 blt.s findlop
 move.l d3,(a0)
 rts
 