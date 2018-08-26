
;		opt o+,l+,d+

		incdir	utils:sysinc/

		include	"exec/execbase.i"
		include "exec/exec.i"
		include	"graphics/graphics_lib.i"
		include "hardware/custom.i"

		xdef	_c2p8_init
		xdef	_c2p8_go

; ---------------------------------------------------------------------

; void __asm c2p8_init (register __a0 UBYTE *chunky,
;			register __a1 UBYTE *chunky_cmp,
;			register __a2 PLANEPTR *planes,
;			register __d0 ULONG signals1,
;			register __d1 ULONG signals2,
;			register __d2 ULONG pixels,     // width*height
;			register __d3 ULONG offset,     // byte offset into plane
;			register __d4 UBYTE *buff2,	// Chip buffer width*height
;			register __d5 UBYTE *buff3,	// Chip buffer width*height
;			register __a3 struct GfxBase *GfxBase);
;
; void c2p8_go();
;
; -------------------------------------------------------------------
;
; Pipelined CPU+blitter 8-plane chunky to planar converter.
; Optimised for 68020/30 with fastmem.
;
; Author: Peter McGavin (e-mail peterm@maths.grace.cri.nz), 21 April 1994
; Based on James McCoull's 4-pass blitter algorithm.
;
; Modified by Conrad Sanderson (g.sanderson@ais.gu.edu.au), 4 June 1994
;
; This code is public domain.
;
; algorithm:
;
; Uses chunky comparison buffer.  Returns immediately if no diffs found.
; Performs first 2 passes (Fast->Chip) with the CPU (in 1 pass).
; Only converts 32-pixel "units" that changed since last time.
; Updates chunky comparison buffer.
; If nothing has changed, signals signals1 and return immediately.
; Waits for previous QBlit() to completely finish (signals2).
; Then launches passes 3 & 4 with QBlit().
; Return immediately after launching passes 3 & 4.
; ** your task can render the next frame while the converter is still going **
; Signals via signals1 (asynchronously) after completion of pass 3.
; Signals via signals2 from CleanUp() on completion of QBlit().
;
; Approx timing for A4000/030, (320x200x8):
;	CPU pass min 13ms, max 37ms, depending how different (then return)
;	Asynchronous blitter passes add 62ms
;	Max framerate (with changes every frame) is 62ms/frame = 16fps
;		occurs when fBUFFER rendering time <= 25ms (= 62ms-37ms)
;
; Approx timing for A1200+fast ram, (320x200x8):
; 	CPU pass min 18ms, max 55ms
;
;
; see c2p8_demo.c for example usage
; -------------------------------------------------------------------


		section chunks,code

_c2p8_init:
		movem.l	d2-d3/a2-a4/a6,-(sp)

		lea	mybltnode(pc),a4

		move.l	a0,chunky-mybltnode(a4)
		move.l	a1,chunky_cmp-mybltnode(a4)
		move.l	a2,planes-mybltnode(a4)
		move.l	d0,signals1-mybltnode(a4)
		move.l	d1,signals2-mybltnode(a4)

		move.l	d2,pixels-mybltnode(a4)
		lsr.l	#1,d2
		move.l	d2,pixels2-mybltnode(a4)
		lsr.l	#1,d2
		move.l	d2,pixels4-mybltnode(a4)
		lsr.l	#1,d2
		move.l	d2,pixels8-mybltnode(a4)
		lsr.l	#1,d2
		move.l	d2,pixels16-mybltnode(a4)
		move.l	d3,offset-mybltnode(a4)
		move.l	d4,tmp_buff2-mybltnode(a4)
		move.l	d5,tmp_buff3-mybltnode(a4)


		move.l	a3,gfxbase-mybltnode(a4)

		move.l	4.w,a6
		move.l	a6,sysbase-mybltnode(a4)

		move.l	ThisTask(a6),task-mybltnode(a4) ; save task ptr

		movem.l	(sp)+,d2-d3/a2-a4/a6
		rts


		cnop	0,4

_c2p8_go:	movem.l	d2-d7/a2-a6,-(sp)

		lea	mybltnode(pc),a2
		move.l	a2,a0

; wait for previous call to c2p4 to finish pass 3

		move.l	signals1-mybltnode(a0),d0
		move.l	sysbase(pc),a6
		jsr	_LVOWait(a6)			  ; signals1 in d0

		move.l	a2,a0
		move.l	chunky-mybltnode(a0),a2
		move.l	chunky_cmp-mybltnode(a0),a3

;-------------------------------------------------
;original chunky data
;0		a7a6a5a4a3a2a1a0 b7b6b5b4b3b2b1b0
;2		c7c6c5c4c3c2c1c0 d7d6d5d4d3d2d1d0
;4		e7e6e5e4e3e2e1e0 f7f6f5f4f3f2f1f0
;6		g7g6g5g4g3g2g1g0 h7h6h5h4h3h2h1h0
;8		i7i6i5i4i3i2i1i0 j7j6j5j4j3j2j1j0
;10		k7k6k5k4k3k2k1k0 l7l6l5l4l3l2l1l0
;12		m7m6m5m4m3m2m1m0 n7n6n5n4n3n2n1n0
;14		o7o6o5o4o3o2o1o0 p7p6p5p4p3p2p1p0
;16		q7q6q5q4q3q2q1q0 r7r6r5r4r3r2r1r0
;18		s7s6s5s4s3s2s1s0 t7t6t5t4t3t2t1t0
;20		u7u6u5u4u3u2u1u0 v7v6v5v4v3v2v1v0
;22		w7w6w5w4w3w2w1w0 x7x6x5x4x3x2x1x0
;24		y7y6y5y4y3y2y1y0 z7z6z5z4z3z2z1z0
;26		A7A6A5A4A3A2A1A0 B7B6B5B4B3B2B1B0
;28		C7C6C5C4C3C2C1C0 D7D6D5D4D3D2D1D0
;30		E7E6E5E4E3E2E1E0 F7F6F5F4F3F2F1F0
;-------------------------------------------------

		move.l	pixels16-mybltnode(a0),d6
		lsr.l	#1,d6		; loop count = pixels/32

		move.l	pixels4-mybltnode(a0),d0
		move.l	tmp_buff2(pc),a0

		lea	(a0,d0.l),a1	; a1 -> buff2+pixels/4
		lea	(a1,d0.l),a4	; a4 -> buff2+pixels/2
		lea	(a4,d0.l),a5	; a5 -> buff2+3*pixels/4

		move.l	#$0f0f0f0f,d7	; constant
		move.l	#$00ff00ff,a6	; constant

		bra.b	end_pass1loop

		cnop	0,4		; align to 32 bits 

; main loop (starts here) processes 32 chunky pixels at a time
; compare next 32 pixels with compare page, looking for differences

initpass1loop:	cmpm.l	(a2)+,(a3)+
		bne.w	fix1
		cmpm.l	(a2)+,(a3)+
		bne.w	fix2
		cmpm.l	(a2)+,(a3)+
		bne.w	fix3
		cmpm.l	(a2)+,(a3)+
		bne.b	fix4
		cmpm.l	(a2)+,(a3)+
		bne.b	fix5
		cmpm.l	(a2)+,(a3)+
		bne.b	fix6
		cmpm.l	(a2)+,(a3)+
		bne.b	fix7
		cmpm.l	(a2)+,(a3)+
		bne.b	fix8

		addq.l	#8,a0		; skip 8 bytes in output
		addq.l	#8,a1		; skip 8 bytes in output
		addq.l	#8,a4		; skip 8 bytes in output
		addq.l	#8,a5		; skip 8 bytes in output

end_pass1loop:	dbra	d6,initpass1loop

		bra.w	done2

		cnop	0,4

; This becomes the main loop after the first difference is found

pass1loop:	cmpm.l	(a2)+,(a3)+
		bne.b	fix1
		cmpm.l	(a2)+,(a3)+
		bne.b	fix2
		cmpm.l	(a2)+,(a3)+
		bne.b	fix3
		cmpm.l	(a2)+,(a3)+
		bne.b	fix4
		cmpm.l	(a2)+,(a3)+
		bne.b	fix5
		cmpm.l	(a2)+,(a3)+
		bne.b	fix6
		cmpm.l	(a2)+,(a3)+
		bne.b	fix7
		cmpm.l	(a2)+,(a3)+
		bne.b	fix8

		addq.l	#8,a0		; skip 8 bytes in output
		addq.l	#8,a1		; skip 8 bytes in output
		addq.l	#8,a4		; skip 8 bytes in output
		addq.l	#8,a5		; skip 8 bytes in output

		dbra	d6,pass1loop

		bra.w	done

		cnop 0,4

; difference found, restore a2 and a3

fix8:		sub.w	#32,a2
		sub.w	#32,a3
		bra.b	go_c2p

fix7:		sub.w	#28,a2
		sub.w	#28,a3
		bra.b	go_c2p

fix6:		sub.w	#24,a2
		sub.w	#24,a3
		bra.b	go_c2p

fix5:		sub.w	#20,a2
		sub.w	#20,a3
		bra.b	go_c2p

fix4:		sub.w	#16,a2
		sub.w	#16,a3
		bra.b	go_c2p

		cnop	0,4

fix3:		subq.l	#4,a2
		subq.l	#4,a3
fix2:		subq.l	#4,a2
		subq.l	#4,a3
fix1:		subq.l	#4,a2
		subq.l	#4,a3

; convert 32 pixels (passes 1 and 2 combined)

go_c2p:		movem.l	(a2)+,d0-d3	; AaBbCcDd EeFfGgHh IiJjKkLl MmNnOoPp

		movem.l	d0-d3,(a3)	; update compare buffer
		adda.w	#16,a3

		exg	d7,a6		; d7=$00ff00ff

		move.l	d0,d4		; AaBbCcDd
		and.l	d7,d4		; ..Bb..Dd
		eor.l	d4,d0		; Aa..Cc..
		lsl.l	#8,d4		; Bb..Dd..

		move.l	d2,d5		; IiJjKkLl
		and.l	d7,d5		; ..Jj..Ll
		eor.l	d5,d2		; Ii..Kk..
		lsr.l	#8,d2		; ..Ii..Kk

		or.l	d2,d0		; AaIiCcKk
		or.l	d5,d4		; BbJjDdLl

		move.l	d1,d2		; EeFfGgHh
		and.l	d7,d2		; ..Ff..Hh
		eor.l	d2,d1		; Ee..Gg..
		lsl.l	#8,d2		; Ff..Hh..

		move.l	d3,d5		; MmNnOoPp
		and.l	d7,d5		; ..Nn..Pp
		eor.l	d5,d3		; Mm..Oo..
		lsr.l	#8,d3		; ..Mm..Oo

		or.l	d3,d1		; EeMmGgOo
		or.l	d5,d2		; FfNnHhPp

		exg	d7,a6		; d7 = $0f0f0f0f

		move.l	d0,d3		; AaIiCcKk
		and.l	d7,d3		; .a.i.c.k
		eor.l	d3,d0		; A.I.C.K.
		lsl.l	#4,d3		; a.i.c.k.

		move.l	d1,d5		; EeMmGgOo
		and.l	d7,d5		; .e.m.g.o

		or.l	d5,d3		; aeimcgko
		move.l	d3,(a4)+

		eor.l	d5,d1		; E.M.G.O.
		lsr.l	#4,d1		; .E.M.G.O

		or.l	d1,d0		; AEIMCGKO
		move.l	d0,(a0)+

		move.l	d4,d1		; BbJjDdLl
		and.l	d7,d1		; .b.j.d.l
		eor.l	d1,d4		; B.J.D.L.
		lsl.l	#4,d1		; b.j.d.l.

		move.l	d2,d5		; FfNnHhPp
		and.l	d7,d5		; .f.n.h.p

		or.l	d5,d1		; bfjndhlp
		move.l	d1,(a5)+

		eor.l	d5,d2		; F.N.H.P.
		lsr.l	#4,d2		; .F.N.H.P

		or.l	d2,d4		; BFJNDHLP
		move.l	d4,(a1)+

		bchg	#16,d6		; repeat inner loop twice
		beq.b	go_c2p

		dbra	d6,pass1loop

; wait until previous QBlit() has completely finished (signals2)
; then start the blitter in the background for passes 3 & 4

done:		lea	mybltnode(pc),a2	; a2->mybltnode
		move.l	sysbase(pc),a6		; a6->SysBase
		move.l	signals2-mybltnode(a2),d0
		jsr	_LVOWait(a6)

		move.l	a2,a1
		move.l	gfxbase-mybltnode(a2),a6
		jsr	_LVOQBlit(a6)

		bra.b	ret


; If we get to here then no difference was found.
; Signal the task (signals1) and return.

		cnop 0,4

done2:		lea	mybltnode(pc),a2
		move.l	signals1-mybltnode(a2),d0
		move.l	d0,d1
		move.l	sysbase(pc),a6	; a6->SysBase
		jsr	_LVOSetSignal(a6)

ret:		movem.l	(sp)+,d2-d7/a2-a6
		rts

;-----------------------------------------------------------------------------
; QBlit functions (called asynchronously)

;-------------------------------------------------
;buff2 after pass 2
;0		a7a6a5a4e7e6e5e4 i7i6i5i4m7m6m5m4
;2		c7c6c5c4g7g6g5g4 k7k6k5k4o7o6o5o4
;4		q7q6q5q4u7u6u5u4 y7y6y5y4C7C6C5C4
;6		s7s6s5s4w7w6w5w4 A7A6A5A4E7E6E5E4
;
;Pixels/4+0	b7b6b5b4f7f6f5f4 j7j6j5j4n7n6n5n4
;Pixels/4+2	d7d6d5d4h7h6h5h4 l7l6l5l4p7p6p5p4
;Pixels/4+4	r7r6r5r4v7v6v5v4 z7z6z5z4D7D6D5D4
;Pixels/4+6	t7t6t5t4x7x6x5x4 B7B6B5B4F7F6F5F4
;
;Pixels/2+0	a3a2a1a0e3e2e1e0 i3i2i1i0m3m2m1m0
;Pixels/2+2	c3c2c1c0g3g2g1g0 k3k2k1k0o3o2o1o0
;Pixels/2+4	q3q2q1q0u3u2u1u0 y3y2y1y0C3C2C1C0
;Pixels/2+6	s3s2s1s0w3w2w1w0 A3A2A1A0E3E2E1E0
;
;3*Pixels/4+0	b3b2b1b0f3f2f1f0 j3j2j1j0n3n2n1n0	
;3*Pixels/4+2	d3d2d1d0h3h2h1h0 l3l2l1l0p3p2p1p0
;3*Pixels/4+4	r3r2r1r0v3v2v1v0 z3z2z1z0D3D2D1D0
;3*Pixels/4+6	t3t2t1t0x3x2x1x0 B3B2B1B0F3F2F1F0
;-------------------------------------------------

;Pass 3, subpass 1
;	apt		Buff2
;	bpt		Buff2+2
;	dpt		Buff3
;	amod		2
;	bmod		2
;	dmod		0
;	cdat		$cccc
;	sizv		Pixels/4
;	sizh		1 word
;	con		D=AC+(B>>2)~C, ascending

		cnop 0,4

blit31:		moveq	#-1,d0
		move.l	d0,(bltafwm,a0)
		move.w	#0,(bltdmod,a0)

		move.l	tmp_buff2(pc),d1
		move.l	d1,bltapt(a0)

		addq.l	#2,d1				; buff2+2
		move.l	d1,bltbpt(a0)


		move.l	tmp_buff3(pc),bltdpt(a0)
		move.w	#2,bltamod(a0)			; 2
		move.w	#2,bltbmod(a0)			; 2
		move.w	pixels4+2-mybltnode(a1),bltsizv(a0)	; pixels/4
		move.w	#$cccc,bltcdat(a0)
		move.l	#$0DE42000,bltcon0(a0)	; D=AC+(B>>2)~C
		move.w	#1,bltsizh(a0)		;do blit
		lea	blit32(pc),a0
		move.l	a0,qblitfunc-mybltnode(a1)
		rts

;Pass 3, subpass 2
;	apt		Buff2+Pixels-2-2
;	bpt		Buff2+Pixels-2
;	dpt		Buff3+Pixels-2
;	amod		2
;	bmod		2
;	dmod		0
;	cdat		$cccc
;	sizv		Pixels/4
;	sizh		1 word
;	con		D=(A<<2)C+B~C, descending

		cnop 0,4

blit32:		move.l	tmp_buff2(pc),d0
		add.l	pixels-mybltnode(a1),d0
		subq.l	#2+2,d0
		move.l	d0,bltapt(a0)		; buff2+pixels-2-2
		addq.l	#2,d0
		move.l	d0,bltbpt(a0)		; buff2+pixels-2

		sub.l	tmp_buff2(pc),d0
		add.l	tmp_buff3(pc),d0

		move.l	d0,bltdpt(a0)		; buff3+pixels-2
		move.l	#$2DE40002,bltcon0(a0)	; D=(A<<2)C+B~C, desc.
		move.w	#1,bltsizh(a0)		;do blit
		lea	blit47(pc),a0
		move.l	a0,qblitfunc-mybltnode(a1)
		rts

;-------------------------------------------------
;buff3 after pass 3
;0		a7a6c7c6e7e6g7g6 i7i6k7k6m7m6o7o6
;2		q7q6s7s6u7u6w7w6 y7y6A7A6C7C6E7E6
;
;Pixels/8+0	b7b6d7d6f7f6h7h6 j7j6l7l6n7n6p7p6
;Pixels/8+2	r7r6t7t6v7v6x7x6 z7z6B7B6D7D6F7F6
;
;Pixels/4+0	a3a2c3c2e3e2g3g2 i3i2k3k2m3m2o3o2
;Pixels/4+2	q3q2s3s2u3u2w3w2 y3y2A3A2C3C2E3E2
;
;3*Pixels/8+0	b3b2d3d2f3f2h3h2 j3j2l3l2n3n2p3p2
;3*Pixels/8+2	r3r2t3t2v3v2x3x2 z3z2B3B2D3D2F3F2
;
;Pixels/2+0	a5a4c5c4e5e4g5g4 i5i4k5k4m5m4o5o4
;Pixels/2+2	q5q4s5s4u5u4w5w4 y5y4A5A4C5C4E5E4
;
;5*Pixels/8+0	b5b4d5d4f5f4h5h4 j5j4l5l4n5n4p5p4
;5*Pixels/8+2	r5r4t5t4v5v4x5x4 z5z4B5B4D5D4F5F4
;
;3*Pixels/4+0	a1a0c1c0e1e0g1g0 i1i0k1k0m1m0o1o0
;3*Pixels/4+2	q1q0s1s0u1u0w1w0 y1y0A1A0C1C0E1E0
;
;7*Pixels/8+0	b1b0d1d0f1f0h1h0 j1j0l1l0n1n0p1p0
;7*Pixels/8+2	r1r0t1t0v1v0x1x0 z1z0B1B0D1D0F1F0
;-------------------------------------------------

;Pass 4, plane 7
;	apt		Buff3+0*pixels/8
;	bpt		Buff3+1*pixels/8
;	dpt		Plane7+offset
;	amod		0
;	bmod		0
;	dmod		0
;	cdat		$aaaa
;	sizv		Pixels/16
;	sizh		1 word
;	con		D=AC+(B>>1)~C, ascending

		cnop 0,4

blit47:		movem.l	a2,-(sp)
		move.l	tmp_buff3(pc),d0
		move.l	d0,bltapt(a0)		; buff3+0*pixels/8
		add.l	pixels8-mybltnode(a1),d0
		move.l	d0,(bltbpt,a0)		; buff3+1*pixels/8
		move.l	planes-mybltnode(a1),a2
		move.l	(7*4,a2),d0
		add.l	offset-mybltnode(a1),d0
		move.l	d0,bltdpt(a0)		; Plane7+offset
		move.w	#0,bltamod(a0)
		move.w	#0,bltbmod(a0)
		move.w	pixels16+2-mybltnode(a1),bltsizv(a0)	; pixels/16
		move.w	#$aaaa,bltcdat(a0)
		move.l	#$0DE41000,bltcon0(a0)	; D=AC+(B>>1)~C
		move.w	#1,bltsizh(a0)		;plane 7

		movem.l	a1/a6,-(sp)
		move.l	signals1-mybltnode(a1),d0
		move.l	task-mybltnode(a1),a1
		move.l	sysbase(pc),a6		; a6->SysBase
		jsr	_LVOSignal(a6)		; signal pass 3 has finished
		movem.l	(sp)+,a1/a6

		lea	blit43(pc),a0
		move.l	a0,qblitfunc-mybltnode(a1)
		movem.l	(sp)+,a2
		rts

;-------------------------------------------------
;Plane7		a7b7c7d7e7f7g7h7 i7j7k7l7m7n7o7p7
;Plane7+2	q7r7s7t7u7v7w7x7 y7z7A7B7C7D7E7F7
;-------------------------------------------------

;Pass 4, plane 3
;	apt		buff3+2*pixels/8
;	bpt		buff3+3*pixels/8
;	dpt		Plane3+offset
;	amod		0
;	bmod		0
;	dmod		0
;	cdat		$aaaa
;	sizv		pixels/16
;	sizh		1 word
;	con		D=AC+(B>>1)~C, ascending

		cnop 0,4

blit43:		move.l	a2,d1			; preserve a2
		move.l	(tmp_buff3,pc),d0
		add.l	pixels4-mybltnode(a1),d0
		move.l	d0,(bltapt,a0)		; buff3+2*pixels/8
		add.l	pixels8-mybltnode(a1),d0
		move.l	d0,(bltbpt,a0)		; buff3+3*pixels/8
		move.l	planes-mybltnode(a1),a2
		move.l	(3*4,a2),d0
		add.l	offset-mybltnode(a1),d0
		move.l	d0,bltdpt(a0)		; Plane3+offset
		move.w	#1,bltsizh(a0)		;plane 3
		lea	blit45(pc),a0
		move.l	a0,qblitfunc-mybltnode(a1)
		move.l	d1,a2			; restore a2
		rts

;-------------------------------------------------
;Plane3		a3b3c3d3e3f3g3h3 i3j3k3l3m3n3o3p3
;Plane3+2	q3r3s3t3u3v3w3x3 y3z3A3B3C3D3E3F3
;-------------------------------------------------

;Pass 4, plane 5
;	apt		buff3+4*pixels/8
;	bpt		buff3+5*pixels/8
;	dpt		Plane5+offset
;	amod		0
;	bmod		0
;	dmod		0
;	cdat		$aaaa
;	sizv		pixels/16
;	sizh		1 word
;	con		D=AC+(B>>1)~C, ascending

		cnop 0,4

blit45:		move.l	a2,d1			; preserve a2
		move.l	tmp_buff3(pc),d0
		add.l	pixels2-mybltnode(a1),d0
		move.l	d0,(bltapt,a0)		; buff3+4*pixels/8
		add.l	pixels8-mybltnode(a1),d0
		move.l	d0,(bltbpt,a0)		; buff3+5*pixels/8
		move.l	planes-mybltnode(a1),a2
		move.l	(5*4,a2),d0
		add.l	offset-mybltnode(a1),d0
		move.l	d0,bltdpt(a0)		; Plane5+offset
		move.w	#1,bltsizh(a0)		;plane 5
		lea	blit41(pc),a0
		move.l	a0,qblitfunc-mybltnode(a1)
		move.l	d1,a2			; restore a2
		rts

;-------------------------------------------------
;Plane5		a5b5c5d5e5f5g5h5 i5j5k5l5m5n5o5p5
;Plane5+2	q5r5s5t5u5v5w5x5 y5z5A5B5C5D5E5F5
;-------------------------------------------------

;Pass 4, plane 1
;	apt		buff3+6*pixels/8
;	bpt		buff3+7*pixels/8
;	dpt		Plane1+offset
;	amod		0
;	bmod		0
;	dmod		0
;	cdat		$aaaa
;	sizv		pixels/16
;	sizh		1 word
;	con		D=AC+(B>>1)~C, ascending

		cnop 0,4

blit41:		move.l	a2,d1			; preserve a2
		move.l	tmp_buff3(pc),d0
		add.l	pixels4-mybltnode(a1),d0
		add.l	pixels2-mybltnode(a1),d0
		move.l	d0,bltapt(a0)		; buff3+6*pixels/8
		add.l	pixels8-mybltnode(a1),d0
		move.l	d0,bltbpt(a0)		; buff3+7*pixels/8
		move.l	planes-mybltnode(a1),a2
		move.l	(1*4,a2),d0
		add.l	offset-mybltnode(a1),d0
		move.l	d0,bltdpt(a0)		; Plane1+offset
		move.w	#1,bltsizh(a0)		;plane 1
		lea	blit46(pc),a0
		move.l	a0,qblitfunc-mybltnode(a1)
		move.l	d1,a2			; restore a2
		rts

;-------------------------------------------------
;Plane1		a1b1c1d1e1f1g1h1 i1j1k1l1m1n1o1p1
;Plane1+2	q1r1s1t1u1v1w1x1 y1z1A1B1C1D1E1F1
;-------------------------------------------------

;Pass 4, plane 6
;	apt		buff3+1*pixels/8-2
;	bpt		buff3+2*pixels/8-2
;	dpt		Plane6+plsiz-2+offset
;	amod		0
;	bmod		0
;	dmod		0
;	cdat		$aaaa
;	sizv		pixels/16
;	sizh		1 word
;	con		D=(A<<1)C+B~C, descending

		cnop 0,4

blit46:		move.l	a2,d1			; preserve a2
		move.l	tmp_buff3(pc),d0
		add.l	pixels8-mybltnode(a1),d0
		subq.l	#2,d0
		move.l	d0,bltapt(a0)		; buff3+1*pixels/8-2
		add.l	pixels8-mybltnode(a1),d0
		move.l	d0,bltbpt(a0)		; buff3+2*pixels/8-2
		move.l	planes-mybltnode(a1),a2
		move.l	(6*4,a2),d0
		add.l	offset-mybltnode(a1),d0
		add.l	pixels8-mybltnode(a1),d0
		subq.l	#2,d0
		move.l	d0,bltdpt(a0)		; Plane6+offset+plsiz-2
		move.l	#$1DE40002,bltcon0(a0)	; D=(A<<1)C+B~C, desc.
		move.w	#1,bltsizh(a0)		;plane 6
		lea	blit42(pc),a0
		move.l	a0,qblitfunc-mybltnode(a1)
		move.l	d1,a2			; restore a2
		rts

;-------------------------------------------------
;Plane6		a6b6c6d6e6f6g6h6 i6j6k6l6m6n6o6p6
;Plane6+2	q6r6s6t6u6v6w6x6 y6z6A6B6C6D6E6F6
;-------------------------------------------------

;Pass 4, plane 2
;	apt		buff3+3*pixels/8-2
;	bpt		buff3+4*pixels/8-2
;	dpt		Plane2+plsiz-2+offset
;	amod		0
;	bmod		0
;	dmod		0
;	cdat		$aaaa
;	sizv		pixels/16
;	sizh		1 word
;	con		D=(A<<1)C+B~C, descending

		cnop 0,4

blit42:		move.l	a2,d1			; preserve a2
		move.l	tmp_buff3(pc),d0
		add.l	pixels2-mybltnode(a1),d0
		subq.l	#2,d0
		move.l	d0,bltbpt(a0)		; buff3+4*pixels/8-2
		sub.l	pixels8-mybltnode(a1),d0
		move.l	d0,(bltapt,a0)		; buff3+3*pixels/8-2
		move.l	planes-mybltnode(a1),a2
		move.l	(2*4,a2),d0
		add.l	offset-mybltnode(a1),d0
		add.l	pixels8-mybltnode(a1),d0
		subq.l	#2,d0
		move.l	d0,bltdpt(a0)		; Plane2+offset+plsiz-2
		move.w	#1,bltsizh(a0)		;plane 2
		lea	(blit44,pc),a0
		move.l	a0,qblitfunc-mybltnode(a1)
		move.l	d1,a2			; restore a2
		rts

;-------------------------------------------------
;Plane2		a2b2c2d2e2f2g2h2 i2j2k2l2m2n2o2p2
;Plane2+2	q2r2s2t2u2v2w2x2 y2z2A2B2C2D2E2F2
;-------------------------------------------------

;Pass 4, plane 4
;	apt		buff3+5*pixels/8-2
;	bpt		buff3+6*pixels/8-2
;	dpt		Plane4+plsiz-2+offset
;	amod		0
;	bmod		0
;	dmod		0
;	cdat		$aaaa
;	sizv		pixels/16
;	sizh		1 word
;	con		D=(A<<1)C+B~C, descending

		cnop 0,4

blit44:		move.l	a2,d1			; preserve a2
		move.l	tmp_buff3(pc),d0
		add.l	pixels2-mybltnode(a1),d0
		add.l	pixels4-mybltnode(a1),d0
		subq.l	#2,d0
		move.l	d0,bltbpt(a0)		; buff3+6*pixels/8-2
		sub.l	pixels8-mybltnode(a1),d0
		move.l	d0,bltapt(a0)		; buff3+5*pixels/8-2
		move.l	planes-mybltnode(a1),a2
		move.l	(4*4,a2),d0
		add.l	offset-mybltnode(a1),d0
		add.l	pixels8-mybltnode(a1),d0
		subq.l	#2,d0
		move.l	d0,bltdpt(a0)		; Plane4+offset+plsiz-2
		move.w	#1,bltsizh(a0)		;plane 4
		lea	blit40(pc),a0
		move.l	a0,qblitfunc-mybltnode(a1)
		move.l	d1,a2			; restore a2
		rts

;-------------------------------------------------
;Plane4		a4b4c4d4e4f4g4h4 i4j4k4l4m4n4o4p4
;Plane4+2	q4r4s4t4u4v4w4x4 y4z4A4B4C4D4E4F4
;-------------------------------------------------

;Pass 4, plane 0
;	apt		buff3+7*pixels/8-2
;	bpt		buff3+8*pixels/8-2
;	dpt		Plane0+plsiz-2+offset
;	amod		0
;	bmod		0
;	dmod		0
;	cdat		$aaaa
;	sizv		pixels/16
;	sizh		1 word
;	con		D=(A<<1)C+B~C, descending

		cnop 0,4

blit40:		move.l	a2,d1			; preserve a2
		move.l	tmp_buff3(pc),d0
		add.l	pixels-mybltnode(a1),d0
		subq.l	#2,d0
		move.l	d0,bltbpt(a0)		; buff3+8*pixels/8-2
		sub.l	pixels8-mybltnode(a1),d0
		move.l	d0,(bltapt,a0)		; buff3+7*pixels/8-2
		move.l	planes-mybltnode(a1),a2
		move.l	(a2),d0
		add.l	offset-mybltnode(a1),d0
		add.l	pixels8-mybltnode(a1),d0
		subq.l	#2,d0
		move.l	d0,bltdpt(a0)		; Plane0+offset+plsiz-2
		move.w	#1,bltsizh(a0)		;plane 0
		lea	blit31(pc),a0
		move.l	a0,qblitfunc-mybltnode(a1)
		move.l	d1,a2			; restore a2
		moveq	#0,d0			; set Z flag
		rts

;-------------------------------------------------
;Plane0		a0b0c0d0e0f0g0h0 i0j0k0l0m0n0o0p0
;Plane0+2	q0r0s0t0u0v0w0x0 y0z0A0B0C0D0E0F0
;-------------------------------------------------

		cnop 0,4

qblitcleanup:	movem.l	a2/a6,-(sp)
		lea	mybltnode(pc),a2
		move.l	task-mybltnode(a2),a1	; signal QBlit() has finished
		move.l	signals2-mybltnode(a2),d0
		move.l	sysbase(pc),a6
		jsr	_LVOSignal(a6)		; may be called from interrupts
		movem.l	(sp)+,a2/a6
		rts


; ----------------------------- data --------------------------------------
; not in a seperate section since some variables can be referred via (pc)

		cnop 0,4		; align to 32 bits

cleanup		equ	$40

mybltnode:	dc.l	0		; next bltnode
qblitfunc:	dc.l	blit31		; ptr to qblitfunc()
		dc.b	cleanup		; stat
		dc.b	0		; filler
		dc.w	0		; blitsize
		dc.w	0		; beamsync
		dc.l	qblitcleanup	; ptr to qblitcleanup()

		cnop 0,4

chunky:		dc.l	0		; ptr to original chunky data
chunky_cmp:	dc.l	0		; ptr to chunky data compare buffer
planes:		dc.l	0		; ptr to list of output plane ptrs
pixels:		dc.l	0		; width*height
pixels2:	dc.l	0		; width*height/2
pixels4:	dc.l	0		; width*height/4
pixels8:	dc.l	0		; width*height/8
pixels16:	dc.l	0		; width*height/16
offset:		dc.l	0		; byte offset into plane
tmp_buff2:	dc.l	0		; pointer to chip buffer
tmp_buff3:	dc.l	0		; pointer to chip buffer
task:		dc.l	0		; ptr to this task
signals1:	dc.l	0		; signals to Signal() after pass 3
signals2:	dc.l	0		; signals to Signal() at cleanup
gfxbase:	dc.l	0		; GfxBase
sysbase:	dc.l	0		; ExecBase

		end

