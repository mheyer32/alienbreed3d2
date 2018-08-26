
 moveq #0,d3
 move.w d1,d3
 move.l d3,d1
 lsr.w #8,d3
 divu #50,d1
 swap d1
 addq #1,d1
 swap d2
 clr.w d2
 swap d2
 divu #17,d2
 swap d2
 divu #7,d3
 swap d3

 move.l #PROTLINE+14-20000,a0
 move.w #32,20000(a0)
 move.w d3,d0
 add.w #'A',d0
 move.b d0,20001(a0)
 move.l #PROTLINE+21-20000,a0
 move.w d1,d0
 bsr PUTINNUM
 move.l #PROTLINE+31-20000,a0
 move.w d2,d0
 add.w #'A',d0
 move.w #32,20000(a0)
 move.b d0,20001(a0)
 
 move.w #7,OptScrn
 movem.l d0-d7/a0-a6,-(a7)
 jsr DRAWOPTSCRN
 movem.l (a7)+,d0-d7/a0-a6
 
 move.l #PROTLINE+80+18-10000,a0
 lea 10000(a0),a5
 bsr GETDIGIT
 moveq #0,d0
 add.w d7,d0
 add.b #'0',d7
 move.b d7,10000(a0)
 movem.l d0-d7/a0-a6,-(a7)
 jsr JUSTDRAWIT
 movem.l (a7)+,d0-d7/a0-a6
 muls #10,d0
 lea 10001(a0),a5
 bsr GETDIGIT
 add.w d7,d0
 add.b #'0',d7
 move.b d7,10001(a0)
 movem.l d0-d7/a0-a6,-(a7)
 jsr JUSTDRAWIT
 movem.l (a7)+,d0-d7/a0-a6
 muls #10,d0
 lea 10002(a0),a5
 bsr GETDIGIT
 add.w d7,d0 
 add.b #'0',d7
 move.b d7,10002(a0)
 movem.l d0-d7/a0-a6,-(a7)
 jsr JUSTDRAWIT
 movem.l (a7)+,d0-d7/a0-a6
 
 rts
 
PUTINNUM:
 add.l #20000,a0
 ext.l d0
 divs #10,d0
 add.b #'0',d0
 move.b d0,(a0)+
 swap d0
 add.b #'0',d0
 move.b d0,(a0)+
 rts

GETDIGIT:
 IFEQ CD32VER
 clr.b lastpressed
.wtnum
 tst.b lastpressed
 beq.s .wtnum
 moveq #0,d7
 move.b lastpressed,d7
 cmp.b #1,d7
 blt.s GETDIGIT
 cmp.b #10,d7
 bgt.s GETDIGIT
 beq.s retzero
 rts
retzero:
 clr.b d7
 rts
 ENDC
 IFNE CD32VER
 moveq #0,d7
 move.b #'0',(a5)
 movem.l d0-d7/a0-a6,-(a7)
 jsr JUSTDRAWIT
 movem.l (a7)+,d0-d7/a0-a6

.wtnum:
 btst #1,$dff00c
 sne d1
 btst #1,$dff00d
 sne d2
 btst #0,$dff00c
 sne d3
 btst #0,$dff00d
 sne d4
 
 eor.b d1,d3
 eor.b d2,d4

 tst.b d4
 bne.s .PREVNUM
 tst.b d3
 bne.s .NEXTNUM
 btst #7,$bfe001
 bne.s .wtnum
 bsr WAITFORNOPRESS
 rts

.PREVNUM:
 subq #1,d7
 bge.s .nonegg
 moveq #9,d7
.nonegg:
 move.b d7,d1
 add.b #'0',d1
 move.b d1,(a5)
 movem.l d0-d7/a0-a6,-(a7)
 jsr JUSTDRAWIT
 movem.l (a7)+,d0-d7/a0-a6
 
 bsr WAITFORNOPRESS
 
 bra .wtnum

.NEXTNUM:
 addq #1,d7
 cmp.w #9,d7
 ble.s .nobigg
 moveq #0,d7
.nobigg:
 move.b d7,d1
 add.b #'0',d1
 move.b d1,(a5)
 movem.l d0-d7/a0-a6,-(a7)
 jsr JUSTDRAWIT
 movem.l (a7)+,d0-d7/a0-a6
 bsr WAITFORNOPRESS
 bra .wtnum
 rts
CHARTOPICK:
 dc.w 0
 ENDC

WAITFORNOPRESS 
 btst #1,$dff00c
 sne d1
 btst #1,$dff00d
 sne d2
 btst #0,$dff00c
 sne d3
 btst #0,$dff00d
 sne d4
 eor.b d1,d3
 eor.b d2,d4
 tst.b d3
 bne.s WAITFORNOPRESS
 tst.b d4
 bne.s WAITFORNOPRESS
 btst #7,$bfe001
 beq.s WAITFORNOPRESS
 tst.b d1
 bne.s WAITFORNOPRESS
 rts