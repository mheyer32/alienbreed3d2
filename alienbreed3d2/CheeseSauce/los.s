VALS:
 dc.w 0
;2
 dc.w 0
;4
 dc.w 0
;6
 dc.w 0
;8
 dc.l 0
;12
 dc.w 0
;14
 
START:
 lea VALS(pc),a0
 move.w (a0),d0
 move.w 2(a0),d1
 move.w 4(a0),d2
 move.w 6(a0),d3
 
 move.l 8(a0),a1
 
 sub.w d0,d2	;dx
 bne.s .okzer

 cmp.w d1,d3
 beq nothingin
 
.okzer
 sub.w d1,d3 	;dy
 
 move.w d2,d4
 bge.s .okpos1
 neg.w d4
.okpos1:
 
 move.w d3,d5
 bge.s .okpos2
 neg.w d5
.okpos2:

 cmp.w d4,d5
 bge.s YBIG
 
XBIG:
 move.w d4,d5
YBIG:
 move.w d5,d7
 move.w d5,d6
 
checkthing:
 move.w d2,d4
 move.w d3,d5
 muls d7,d4
 muls d7,d5
 divs d6,d4
 divs d6,d5
 add.w d0,d4
 add.w d1,d5
 asl.w #5,d5
 add.w d4,d5
 tst.b (a1,d5.w)
 bne.s somethingin
 
 dbra d7,checkthing
 
 nothingin:
 st 12(a0)
 rts
 
somethingin: 
 clr.b 12(a0)
 rts
