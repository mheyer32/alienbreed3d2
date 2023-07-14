; Generic Gouraud Floor Routine

draw_GoraudFloor:
				move.w	leftbright,d0
				move.l	d1,d4
				move.w	brightspd,d1

				move.w	d7,d3
				asr.w	#1,d7
				btst	#0,d3
				beq.s	.nosingle1

				move.w	d5,d3					; d3 = S
				move.l	d5,d6
				lsr.w	#8,d3
				swap	d6						; d6 = T
				move.b	d3,d6					; T * 256 + S

				move.w	d0,d3					; line X

				move.b	(a0,d6.w*4),d3			; fetch floor texel; but why d6*4?

				add.w	d1,d0					;
				add.l	d2,d5
				and.l	d4,d5
				move.b	(a1,d3.w),(a3)+			; map through palette and write to renderbuffer

.nosingle1:
				move.w	d7,d3
				asr.w	#1,d7
				btst	#0,d3
				beq.s	.nosingle2
				move.w	d5,d3
				move.l	d5,d6
				lsr.w	#8,d3
				swap	d6
				move.b	d3,d6
				move.w	d0,d3
				move.b	(a0,d6.w*4),d3
				add.w	d1,d0
				add.l	d2,d5
				and.l	d4,d5
				move.l	d5,d6
				swap	d6
				move.b	(a1,d3.w),(a3)+
				move.w	d5,d3
				lsr.w	#8,d3
				move.b	d3,d6
				move.w	d0,d3
				move.b	(a0,d6.w*4),d3
				add.w	d1,d0
				add.l	d2,d5
				and.l	d4,d5
				move.b	(a1,d3.w),(a3)+

.nosingle2:
				move.l	d5,d6
				swap	d6

				dbra	d7,acrossscrngour
				rts

				CNOP	0,4

acrossscrngour:
				move.w	d5,d3
				lsr.w	#8,d3
				move.b	d3,d6
				move.w	d0,d3
				move.b	(a0,d6.w*4),d3
				add.w	d1,d0
				add.l	d2,d5
				and.l	d4,d5
				move.l	d5,d6
				swap	d6
				move.b	(a1,d3.w),(a3)+
				move.w	d5,d3
				lsr.w	#8,d3
				move.b	d3,d6
				move.w	d0,d3
				move.b	(a0,d6.w*4),d3
				add.w	d1,d0
				add.l	d2,d5
				and.l	d4,d5
				move.l	d5,d6
				swap	d6
				move.b	(a1,d3.w),(a3)+
				move.w	d5,d3
				lsr.w	#8,d3
				move.b	d3,d6
				move.w	d0,d3
				move.b	(a0,d6.w*4),d3
				add.w	d1,d0
				add.l	d2,d5
				and.l	d4,d5
				move.l	d5,d6
				swap	d6
				move.b	(a1,d3.w),(a3)+
				move.w	d5,d3
				lsr.w	#8,d3
				move.b	d3,d6
				move.w	d0,d3
				move.b	(a0,d6.w*4),d3
				add.w	d1,d0
				add.l	d2,d5
				and.l	d4,d5
				move.l	d5,d6
				swap	d6
				move.b	(a1,d3.w),(a3)+
				dbra	d7,acrossscrngour

				rts
