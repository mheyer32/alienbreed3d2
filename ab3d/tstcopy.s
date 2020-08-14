
 include "macros.i"

 move.l #blag,$80
 trap #0
 rts

blag:

 CACHE_ON d0
 CACHE_FREEZE_OFF d0
 move.l #one,a0
 bsr rout
 CACHE_FREEZE_ON d0
 move.w #((endrout-rout)/4)-1,d0
 move.l #rout,a0
clr:
 not.l (a0)+
 dbra d0,clr
 move.l #blag,a0
 move.l #0,d0
 move.w #(endblag-blag)/2-1,d1
 endblag:
clr2:
 move.w d0,(a0)+
 dbra d1,clr2
 move.l d0,(a0)+
 move.l d0,(a0)+
 move.l d0,(a0)+
 
 move.l #two,a0
 bsr rout
 rte

 CNOP 0,4
rout:
 move.w #1,(a0)
 rts
 CNOP 0,4
endrout:

one: dc.w 0
two: dc.w 0