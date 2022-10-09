
PLR1_fall
 move.l PLR1s_tyoff,d0
 move.l PLR1s_yoff,d1
 move.l PLR1s_yvel,d2
 sub.l d1,d0
 bgt.s .aboveground
 sub.l #512,d2
 blt.s .notfast
 move.l #0,d2
.notfast:
 add.l d2,d1
 sub.l d2,d0
 blt.s .pastitall
 move.l #0,d2
 add.l d0,d1
 bra.s .pastitall

.aboveground:
 add.l d2,d1
 add.l #256,d2
 
 move.l PLR1_Roompt,a2
 move.l ToZoneWater(a2),d0
 cmp.l d0,d1
 blt.s .pastitall

 cmp.l #256*2,d2
 blt.s .pastitall
 move.l #256*2,d2
 
.pastitall:

 move.l d2,PLR1s_yvel
 move.l d1,PLR1s_yoff

 rts


PLR2_fall
 move.l PLR2s_tyoff,d0
 move.l PLR2s_yoff,d1
 move.l PLR2s_yvel,d2
 sub.l d1,d0
 bgt.s .aboveground
 sub.l #512,d2
 blt.s .notfast
 move.l #0,d2
.notfast:
 add.l d2,d1
 sub.l d2,d0
 blt.s .pastitall
 move.l #0,d2
 add.l d0,d1
 bra.s .pastitall

.aboveground:
 add.l d2,d1
 add.l #256,d2
.pastitall:

 move.l d2,PLR2s_yvel
 move.l d1,PLR2s_yoff

 rts

