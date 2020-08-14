VALS:
 dc.l 0
 dc.l 0
 
Start:


 lea VALS(pc),a0
 move.l (a0)+,a1	; dest buffer
 move.l (a0)+,a2	; palette data

 move.w #32,d6
BRIGHTLOOP

 move.w #31,d7		; specular counter
 move.w #0,d4		; specular amount
SPECLOOP

 move.w #31,d4
 sub.w d7,d4
 move.w d4,d1
 muls d4,d4
 muls d1,d4
 asr.l #5,d4
 
 swap d7

 move.w #255,d5		; colour counter
 move.l a2,a0		; colour pointer
COLOURLOOP:
 moveq #0,d0
 moveq #0,d1
 moveq #0,d2


 move.w (a0)+,d0	; r
 move.w (a0)+,d1	; g
 move.w (a0)+,d2	; b
 
 cmp.w #8,d5
 ble.s .nodark
 
 add.w #10,d6
 muls d6,d0
 divs #42,d0

 muls d6,d1
 divs #42,d1

 muls d6,d2
 divs #42,d2
 sub.w #10,d6
.nodark:

 move.w d0,a4		; r
 move.w d1,a5		; g
 move.w d2,a6		; b
 
 neg.w d0
 neg.w d1
 neg.w d2
 add.w #255,d0
 add.w #255,d1
 add.w #255,d2
 
 muls d4,d0
 divs #24*32,d0
 muls d4,d1
 divs #24*32,d1
 muls d4,d2
 divs #24*32,d2
 
 add.w a4,d0
 add.w a5,d1
 add.w a6,d2

 cmp.w #255,d0
 blt .okred
 move.w #255,d0
.okred
 cmp.w #255,d1
 blt .okgreen
 move.w #255,d1
.okgreen
 cmp.w #255,d2
 blt .okblue
 move.w #255,d2
.okblue

 nop
 nop

 move.w d0,a4		; r
 move.w d1,a5		; g
 move.w d2,a6		; b
 
 move.l #1000000,d3
 move.w #255,d0
 move.l a2,a3
findclose:

 move.w (a3)+,d1	; r
 sub.w a4,d1
 muls.w d1,d1
; muls.w d1,d1
 move.w (a3)+,d2	; g
 sub.w a5,d2
 muls.w d2,d2
; muls.w d2,d2
 add.l d2,d1
 move.w (a3)+,d2	; b
 sub.w a6,d2
 muls.w d2,d2
; muls.w d2,d2
 add.l d2,d1
 
 cmp.l d1,d3
 ble.s .notcloser
 
 move.l d1,d3
 move.w d0,d7
 
.notcloser:
 dbra d0,findclose
 
 neg.w d7
 add.w #255,d7
 move.b d7,(a1)+

 dbra d5,COLOURLOOP

 add.w #8,d4
 swap d7
 dbra d7,SPECLOOP

 subq #1,d6
 bgt BRIGHTLOOP

 rts
 