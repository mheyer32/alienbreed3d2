
; 68020+ generc inner wall rendering loop

drawwalldimPACK0:
				and.w	d7,d4
				move.b	1(a5,d4.w*2),d1			; fetch texel
				and.b	#31,d1					; pull out right part
				add.l	d3,d4					; add fractional part?
				move.b	(a4,d1.w*2),(a3)
				adda.w	d0,a3					; next line in screen
				addx.w	d2,d4					; texture Y + dy
				dbra	d6,drawwallPACK0
				rts

				;CNOP	0,128
				align 4
drawwallPACK0:
				and.w	d7,d4
				move.b	1(a5,d4.w*2),d1
				and.b	#31,d1
				add.l	d3,d4
				move.b	(a2,d1.w*2),(a3)
				adda.w	d0,a3
				addx.w	d2,d4
				dbra	d6,drawwalldimPACK0

nostrip:
				rts

				align 4
drawwalldimPACK1:
				and.w	d7,d4
				move.w	(a5,d4.w*2),d1
				lsr.w	#5,d1
				and.w	#31,d1
				add.l	d3,d4
				move.b	(a4,d1.w*2),(a3)
				adda.w	d0,a3
				addx.w	d2,d4
				dbra	d6,drawwallPACK1
				rts

				align 4
drawwallPACK1:
				and.w	d7,d4
				move.w	(a5,d4.w*2),d1
				lsr.w	#5,d1
				and.w	#31,d1
				add.l	d3,d4
				move.b	(a2,d1.w*2),(a3)
				adda.w	d0,a3
				addx.w	d2,d4
				dbra	d6,drawwalldimPACK1

				rts

				align 4
drawwalldimPACK2:
				and.w	d7,d4
				move.b	(a5,d4.w*2),d1
				lsr.b	#2,d1
				add.l	d3,d4
				move.b	(a4,d1.w*2),(a3)
				adda.w	d0,a3
				addx.w	d2,d4
				dbra	d6,drawwallPACK2
				rts

				align 4
drawwallPACK2:
				and.w	d7,d4
				move.b	(a5,d4.w*2),d1
				lsr.b	#2,d1
				add.l	d3,d4
				move.b	(a2,d1.w*2),(a3)
				adda.w	d0,a3
				addx.w	d2,d4
				dbra	d6,drawwalldimPACK2
				rts

