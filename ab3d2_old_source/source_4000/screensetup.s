; Format of copperlist:

COPSCRNBUFF:
 dc.l 0

;104*80 lots of $1fe0000 initially.

;$106,$c42
;$80
;pch: 0
;$82
;pcl: 0
;
;$88,$0
;
;Length= (104*80*4)+16

INITCOPPERSCRN:
; Get Screen memory

; move.l #2,d1
; move.l #(104*80*4)+16,d0
; move.l 4.w,a6
; jsr -198(a6)
; move.l d0,COPSCRN1
 
; move.l #2,d1
; move.l #(104*80*4)+16,d0
; move.l 4.w,a6
; jsr -198(a6)
; move.l d0,COPSCRN2

; move.l #1,d1
; move.l #(104*80*4)+16,d0
; move.l 4.w,a6
; jsr -198(a6)
; move.l d0,COPSCRNBUFF
 
; move.l COPSCRN1,a1
; move.l COPSCRN2,a2
 
; move.w #(104*80)-1,d0
; move.l #$1fe0000,d1
;clrcop:
; move.l d1,(a1)+
; move.l d1,(a2)+
; dbra d0,clrcop
 
; add.l #104*4*80,a1
; add.l #104*4*80,a2
; move.l #$1060c42,(a1)+
; move.l #$1060c42,(a2)+
; move.w #$80,(a1)+
; move.w #$80,(a2)+
;
; move.l #PanelCop,d0
; swap d0
; move.w d0,(a1)+
; move.w d0,(a2)+
; move.w #$82,(a1)+
; move.w #$82,(a2)+
; swap d0
; move.w d0,(a1)+
; move.w d0,(a2)+
; move.l #$880000,(a1)+
; move.l #$880000,(a2)+
; clr.b BIGsmall
; jsr putinsmallscr
 rts

