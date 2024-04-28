
; 68060 tuned inner wall rendering loop by @paraj
drawwallS060_loop	MACRO
val SET \2
.loop\<val>:
				; grab packed texel
				IFEQ    \1-0
				moveq   #%00011111,d1
				and.b   1(a5,d4.w*2),d1
				ENDC
				IFEQ    \1-1
				move.w  (a5,d4.w*2),d1
				lsr.w   #5,d1
				and.w   #%00011111,d1
				ENDC
				IFEQ    \1-2
				moveq   #%01111100,d1
				and.b   (a5,d4.w*2),d1
				lsr.b   #2,d1
				ENDC

				; v step (fractional first, then integer part)
				add.l   d3,d4
				addx.w  d2,d4
				and.w   d7,d4

				; store through palette lookup (note: alternates between a2 and a4)
				IFEQ \2
				move.b  (a2,d1.w*2),(a3)
				ELSE
				move.b  (a4,d1.w*2),(a3)
				ENDC

				; dest += width
				adda.w  d0,a3
val SET val^1
				dbf     d6,.loop\<val>
				rts
				ENDM

drawwallS060	MACRO
				and.w   d7,d4   ; make sure offset is masked
				drawwallS060_loop \1,0
				drawwallS060_loop \1,1
				ENDM

drawwallPACK0:	drawwallS060 0
drawwallPACK1:	drawwallS060 1
drawwallPACK2:	drawwallS060 2
