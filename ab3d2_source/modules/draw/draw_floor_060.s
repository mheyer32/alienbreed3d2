; 68060 optimised Gouraud Floor routine by @paraj / @saimo

draw_GoraudFloor060:
				moveq   #0,d0
				move.w	leftbright,d0
				move.w  brightspd,d4
				move.l  d2,a2

				and.l   d1,d5
				move.l  d5,d6
				lsr.l   #8,d6
				move.l  d6,d2
				lsr.l   #8,d6
				move.b  d2,d6   ; d6 ready for first iteration
.loop:
				move.l  d0,d3           ; d3=00Cc
				move.b  (a0,d6.l*4),d3  ; d3=00CT
				add.w   d4,d0           ; c += dcdx
				add.l   a2,d5           ; uv += duvdx
				and.l   d1,d5           ; uv &= uvmask
				move.l  d5,d6           ; d6=VvUu
				lsr.l   #8,d6           ; d6=0VvU
				move.l  d6,d2           ; d2=0VvU
				lsr.l   #8,d6           ; d6=00Vv
				move.b  d2,d6           ; d6=00VU
				move.b  (a1,d3.l),(a3)+
				subq.w  #1,d7
				bne.b   .loop
				rts
