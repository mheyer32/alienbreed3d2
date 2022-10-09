
; The game has been finished!

; Deallocate all memory, ask for scroll screen
; memory. Load end of game music (whatever that
; is). Print top 16 lines of text then fade up.
;  After a few seconds, scroll it upwards with
; the text following....

 move.l LEVELDATA,d1
 move.l d1,a1
 move.l #120000,d0
 move.l 4.w,a6
 jsr -210(a6)

 move.l TEXTSCRN,d1
 move.l d1,a1
 move.l #10240*2,d0
 move.l 4.w,a6
 jsr -210(a6)
 
 jsr RELEASEWALLMEM
 jsr RELEASESAMPMEM
 jsr RELEASEFLOORMEM
 jsr RELEASEOBJMEM

 move.l #2,d1	
 move.l #10240*4,d0
 move.l 4.w,a6
 jsr -198(a6)
 move.l d0,TEXTSCRN

 move.w d0,TSPTl
 swap d0
 move.w d0,TSPTh
 swap d0
 move.w d0,TSPTl2
 swap d0
 move.w d0,TSPTh2
 
 clr.b DOSCROLLING

 move.w #0,TXTCOLL
 move.w #0,BOTLET
 move.w #0,ALLTEXT

 move.l #$dff000,a6    ; a6 points at the first custom chip register.
 move.l #TEXTCOP,$80(a6)    ; Point the copper at our copperlist.

 move.l #SCROLLINTER,$6c.w

 move.w #$a201,TSCP

 move.w #$20,$1dc(a6) 

 jsr CLRTWEENSCRN
 add.l #20480,TEXTSCRN
 jsr CLRTWEENSCRN
 sub.l #20480,TEXTSCRN

 move.l #ENDGAMETEXT,a0
 move.w #0,d0
 moveq #15,d7
PUTONS
 move.l TEXTSCRN,a1
 bsr DRAWLINEOFTEXT 
 add.w #82,a0
 addq #1,d0
 dbra d7,PUTONS
 
 move.w #$000,d0
 move.w #15,d1
.fdup2
 move.w #15,d3
 move.w #0,d2
.fdup
 move.w d0,ALLTEXT
 move.w d2,ALLTEXTLOW
 add.w #$111,d2
.wtframe:
 btst #5,$dff000+intreqrl
 beq.s .wtframe
 move.w #$0020,$dff000+intreq
 dbra d3,.fdup
 add.w #$111,d0
 dbra d1,.fdup2
 
 move.w #400,d3
.fdupwt
.wtframet:
 btst #5,$dff000+intreqrl
 beq.s .wtframet
 move.w #$0020,$dff000+intreq
 dbra d3,.fdupwt
 
 move.w #0,SCROLLPOS
 move.l #ENDOFGAMESCROLL,SCROLLPT
 move.l #ENDOFGAMESCROLL,OLDSCROLL
 move.w #17,NEXTLINE
 move.w #17,LASTLINE
 
 st DOSCROLLING

SCROLLINGLOOP:
 tst.b DONEXTLINE
 beq.s SCROLLINGLOOP
 clr.b DONEXTLINE
 
 move.l SCROLLPT,a0
 move.l a0,OLDSCROLL
 tst.b (a0)
 blt.s .notex
 add.w #80,a0
.notex
 adda.w #2,a0
 cmp.l #ENDOFEND,a0
 blt.s .nostartscroll
 move.l #ENDOFGAMESCROLL,a0
.nostartscroll:
 move.l a0,SCROLLPT
 
 move.w NEXTLINE,d0
 move.l TEXTSCRN,a1
 bsr CLEARLINEOFTEXT
 tst.b (a0)
 blt.s .okitsaline
 bsr DRAWLINEOFTEXT
.okitsaline:
 
 move.l OLDSCROLL,a0
 move.w LASTLINE,d0
 move.l TEXTSCRN,a1
 bsr CLEARLINEOFTEXT
 tst.b (a0)
 blt.s .okitsatwo
 bsr DRAWLINEOFTEXT
.okitsatwo:

 move.w NEXTLINE,d0
 sub.w #16,d0
 move.w d0,LASTLINE
 add.w #1,d0
 and.w #15,d0
 add.w #16,d0
 move.w d0,NEXTLINE
 bra SCROLLINGLOOP
 
SCROLLINTER:
 move.w #$0010,$dff000+intreq

 tst.b DOSCROLLING
 bne.s dosome
 rte
 
CLEARLINEOFTEXT:
 move.l d0,-(a7)
 
 muls #80*16,d0
 moveq #0,d1
 move.l TEXTSCRN,a2
 add.l d0,a2
 move.w #(20*2),d0
CLRIT:
 move.l d1,(a2)+
 move.l d1,(a2)+
 move.l d1,(a2)+
 move.l d1,(a2)+
 move.l d1,(a2)+
 move.l d1,(a2)+
 move.l d1,(a2)+
 move.l d1,(a2)+
 dbra d0,CLRIT
 
 move.l (a7)+,d0
 rts
 

dosome:

 movem.l d0/d1,-(a7)

 move.w TOPLET,d0
 move.w BOTLET,d1
 sub.w #$222,d1
 add.w #$222,d0
 move.w d0,TOPLET
 move.w d1,BOTLET
 
 sub.w #1,scrolldownaline
 bgt.s .noline

 sub.w #1,LINESLEFTTOSCROLL
 bgt.s .NONOTHERLINE
 move.w #16,LINESLEFTTOSCROLL
 st DONEXTLINE
.NONOTHERLINE

 move.w #$333,TOPLET
 move.w #$ccc,BOTLET

 move.w SCROLLPOS,d0
 move.w d0,d1
 add.w #1,d0
 and.w #255,d0
 move.w d0,SCROLLPOS

 muls #80,d0
 muls #80,d1
 add.l TEXTSCRN,d0
 add.l TEXTSCRN,d1
 move.w d0,TSPTl
 swap d0
 move.w d0,TSPTh
 move.w d1,TSPTl2
 swap d1
 move.w d1,TSPTh2
 
 move.w #3,scrolldownaline
 
.noline:
 movem.l (a7)+,d0/d1
 rte

LINESLEFTTOSCROLL:
 dc.w 14

DONEXTLINE:
 dc.w 0
scrolldownaline:
 dc.w 3
SCROLLPOS: dc.w 0
DOSCROLLING: dc.w 0
SCROLLPT: Dc.l 0
OLDSCROLL: dc.l 0
NEXTLINE: dc.w 0
LASTLINE: dc.w 0

