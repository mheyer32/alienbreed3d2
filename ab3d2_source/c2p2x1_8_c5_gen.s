;
; Date: 1999-12-06			Mikael Kalms (Scout/C-Lous & more)
;					Email: mikael@kalms.org
;
; About:
;   2x1 8bpl cpu5 C2P for contigous bitplanes. Modulo supported
;
;   This routine is intended for use on all 68020-68060 systems.
;   (The conversion is mainly speed-limited by the chipbus; therefore,
;    only cpu4blit1 would make the CPU pass go faster -- but then again,
;    the blitter pass will be slow, so you probably want to use
;    this routine anyhow.)
;
;   This routine is released into the public domain. It may be freely used
;   for non-commercial as well as commercial purposes. A short notice via
;   email is always appreciated, though.
;
; Timings:
;   Estimated to run near copyspeed on 030-50 and 040-25
;   Estimated to run at copyspeed on 040-40 and 060
;
; Features:
;   Modulo support
;   Handles bitplanes of virtually any size (4GB)
;   Position-independent (PC-relative) code
;
;
; c2p2x1_8_c5_gen_init			sets conversion parameters
; c2p2x1_8_c5_gen			performs the actual c2p conversion


	xdef	_c2p2x1_8_c5_gen_init
	xdef	_c2p2x1_8_c5_gen


				rsreset
C2P2X1_8_C5_GEN_SCROFFS		rs.l	1
C2P2X1_8_C5_GEN_CHUNKYROWLEN	rs.l	1
C2P2X1_8_C5_GEN_CHUNKYROWMOD	rs.l	1
C2P2X1_8_C5_GEN_CHUNKYROWEND	rs.l	1
C2P2X1_8_C5_GEN_BPLROWMOD	rs.l	1
C2P2X1_8_C5_GEN_BPLSIZE		rs.l	1
C2P2X1_8_C5_GEN_CHUNKYY		rs.l	1
C2P2X1_8_C5_GEN_DATASIZE	rs.b	0


	section	.text,code

; d0.w	chunkyx [chunky-pixels] (even multiple of 32)
; d1.w	chunkyy [chunky-pixels]
; d2.w	scroffsx [screen-pixels] (even multiple of 8)
; d3.w	scroffsy [screen-pixels]
; d4.l	rowlen [bytes] -- offset between one row and the next in a bpl
; d5.l	bplsize [bytes] -- offset between one row in one bpl and the next bpl
; d6.l	chunkylen [bytes] -- offset between one row and the next in chunkybuf

	XDEF	_c2p2x1_8_c5_gen_init
	XDEF	c2p2x1_8_c5_gen_init
_c2p2x1_8_c5_gen_init
c2p2x1_8_c5_gen_init
	movem.l	d2-d6,-(sp)

	lea	c2p2x1_8_c5_gen_data(pc),a0

	and.l	#$ffff,d1
	move.l	d1,C2P2X1_8_C5_GEN_CHUNKYY(a0)

	move.l	d5,C2P2X1_8_C5_GEN_BPLSIZE(a0)
	move.l	d6,C2P2X1_8_C5_GEN_CHUNKYROWLEN(a0)

	and.l	#$ffe0,d0
	move.l	d0,C2P2X1_8_C5_GEN_CHUNKYROWEND(a0)
	sub.l	d0,d6
	move.l	d6,C2P2X1_8_C5_GEN_CHUNKYROWMOD(a0)

	and.l	#$fff8,d2
	and.l	#$ffff,d3
	lsr.l	#3,d2
	mulu.l	d4,d3
	add.l	d2,d3
	move.l	d3,C2P2X1_8_C5_GEN_SCROFFS(a0)

	move.l	d0,d2
	lsr.l	#2,d2
	sub.l	d2,d4
	move.l	d4,C2P2X1_8_C5_GEN_BPLROWMOD(a0)

	movem.l	(sp)+,d2-d6
	rts


; a0	chunkybuffer
; a1	bitplanes

	XDEF	_c2p2x1_8_c5_gen
	XDEF	c2p2x1_8_c5_gen
_c2p2x1_8_c5_gen
c2p2x1_8_c5_gen
	movem.l	d2-d7/a2-a6,-(sp)
	move.l	#$55555555,d4

	lea	c2p2x1_8_c5_gen_data(pc),a6

	move.l	C2P2X1_8_C5_GEN_CHUNKYROWEND(a6),a2
	add.l	a0,a2

	add.l	C2P2X1_8_C5_GEN_SCROFFS(a6),a1

	move.l	C2P2X1_8_C5_GEN_BPLSIZE(a6),a3
	lea	(a1,a3.l*8),a1
	sub.l	a3,a1

	move.l	C2P2X1_8_C5_GEN_CHUNKYY(a6),-(sp)

	move.l	(a0)+,d0
	move.l	(a0)+,d1
	move.l	(a0)+,d2
	move.l	(a0)+,d3

; a7a6a5a4a3a2a1a0 b7b6b5b4b3b2b1b0 c7c6c5c4c3c2c1c0 d7d6d5d4d3d2d1d0
; e7e6e5e4e3e2e1e0 f7f6f5f4f3f2f1f0 g7g6g5g4g3g2g1g0 h7h6h5h4h3h2h1h0
; i7i6i5i4i3i2i1i0 j7j6j5j4j3j2j1j0 k7k6k5k4k3k2k1k0 l7l6l5l4l3l2l1l0
; m7m6m5m4m3m2m1m0 n7n6n5n4n3n2n1n0 o7o6o5o4o3o2o1o0 p7p6p5p4p3p2p1p0

	move.w	d2,d6			; Swap 16x2
	move.w	d3,d7
	move.w	d0,d2
	move.w	d1,d3
	swap	d2
	swap	d3
	move.w	d2,d0
	move.w	d3,d1
	move.w	d6,d2
	move.w	d7,d3

; a7a6a5a4a3a2a1a0 b7b6b5b4b3b2b1b0 i7i6i5i4i3i2i1i0 j7j6j5j4j3j2j1j0
; e7e6e5e4e3e2e1e0 f7f6f5f4f3f2f1f0 m7m6m5m4m3m2m1m0 n7n6n5n4n3n2n1n0
; c7c6c5c4c3c2c1c0 d7d6d5d4d3d2d1d0 k7k6k5k4k3k2k1k0 l7l6l5l4l3l2l1l0
; g7g6g5g4g3g2g1g0 h7h6h5h4h3h2h1h0 o7o6o5o4o3o2o1o0 p7p6p5p4p3p2p1p0

	move.l	#$0f0f0f0f,d5		; Swap 4x2
	move.l	d2,d6
	move.l	d3,d7
	lsr.l	#4,d6
	lsr.l	#4,d7
	eor.l	d0,d6
	eor.l	d1,d7
	and.l	d5,d6
	and.l	d5,d7
	eor.l	d6,d0
	eor.l	d7,d1
	lsl.l	#4,d6
	lsl.l	#4,d7
	eor.l	d6,d2
	eor.l	d7,d3

; a7a6a5a4c7c6c5c4 b7b6b5b4d7d6d5d4 i7i6i5i4k7k6k5k4 j7j6j5j4l7l6l5l4
; e7e6e5e4g7g6g5g4 f7f6f5f4h7h6h5h4 m7m6m5m4o7o6o5o4 n7n6n5n4p7p6p5p4
; a3a2a1a0c3c2c1c0 b3b2b1b0d3d2d1d0 i3i2i1i0k3k2k1k0 j3j2j1j0l3l2l1l0
; e3e2e1e0g3g2g1g0 f3f2f1f0h3h2h1h0 m3m2m1m0o3o2o1o0 n3n2n1n0p3p2p1p0

	move.l	#$00ff00ff,d5		; Swap 8x1
	move.l	d1,d6
	move.l	d3,d7
	lsr.l	#8,d6
	lsr.l	#8,d7
	eor.l	d0,d6
	eor.l	d2,d7
	and.l	d5,d6
	and.l	d5,d7
	eor.l	d6,d0
	eor.l	d7,d2
	lsl.l	#8,d6
	lsl.l	#8,d7
	eor.l	d6,d1
	eor.l	d7,d3

; a7a6a5a4c7c6c5c4 e7e6e5e4g7g6g5g4 i7i6i5i4k7k6k5k4 m7m6m5m4o7o6o5o4
; b7b6b5b4d7d6d5d4 f7f6f5f4h7h6h5h4 j7j6j5j4l7l6l5l4 n7n6n5n4p7p6p5p4
; a3a2a1a0c3c2c1c0 e3e2e1e0g3g2g1g0 i3i2i1i0k3k2k1k0 m3m2m1m0o3o2o1o0
; b3b2b1b0d3d2d1d0 f3f2f1f0h3h2h1h0 j3j2j1j0l3l2l1l0 n3n2n1n0p3p2p1p0

	move.l	#$33333333,d5		; Swap 2x1
	move.l	d1,d6
	move.l	d3,d7
	lsr.l	#2,d6
	lsr.l	#2,d7
	eor.l	d0,d6
	eor.l	d2,d7
	and.l	d5,d6
	and.l	d5,d7
	eor.l	d6,d0
	eor.l	d7,d2
	lsl.l	#2,d6
	lsl.l	#2,d7
	eor.l	d6,d1
	eor.l	d7,d3

; a7a6b7b6c7c6d7d6 e7e6f7f6g7g6h7h6 i7i6j7j6k7k6l7l6 m7m6n7n6o7o6p7p6
; a5a4b5b4c5c4d5d4 e5e4f5f4g5g4h5h4 i5i4j5j4k5k4l5l4 m5m4n5n4o5o4p5p4
; a3a2b3b2c3c2d3d2 e3e2f3f2g3g2h3h2 i3i2j3j2k3k2l3l2 m3m2n3n2o3o2p3p2
; a1a0b1b0c1c0d1d0 e1e0f1f0g1g0h1h0 i1i0j1j0k1k0l1l0 m1m0n1n0o1o0p1p0

	bra	.framestart

.row
	subq.l	#1,(sp)
	beq	.done

	add.l	c2p2x1_8_c5_gen_data+C2P2X1_8_C5_GEN_CHUNKYROWLEN(pc),a2
	add.l	c2p2x1_8_c5_gen_data+C2P2X1_8_C5_GEN_BPLROWMOD(pc),a1

.x16
	move.l	(a0)+,d0
	move.l	(a0)+,d1
	move.l	(a0)+,d2
	move.l	(a0)+,d3

	move.l	d6,(a1)			; Extend 1x1, part 1b
	eor.l	d7,d6
	sub.l	a3,a1
	add.l	d7,d7
	eor.l	d6,d7
	move.l	d7,(a1)

	move.l	a4,d6			; Extend 1x1, part 2
	move.l	a4,d7
	sub.l	a3,a1
	lsr.l	#1,d7
	eor.l	d6,d7
	and.l	d4,d7
	eor.l	d7,d6
	move.l	d6,(a1)
	eor.l	d7,d6
	sub.l	a3,a1
	add.l	d7,d7
	eor.l	d7,d6
	move.l	d6,a4

; a7a6a5a4a3a2a1a0 b7b6b5b4b3b2b1b0 c7c6c5c4c3c2c1c0 d7d6d5d4d3d2d1d0
; e7e6e5e4e3e2e1e0 f7f6f5f4f3f2f1f0 g7g6g5g4g3g2g1g0 h7h6h5h4h3h2h1h0
; i7i6i5i4i3i2i1i0 j7j6j5j4j3j2j1j0 k7k6k5k4k3k2k1k0 l7l6l5l4l3l2l1l0
; m7m6m5m4m3m2m1m0 n7n6n5n4n3n2n1n0 o7o6o5o4o3o2o1o0 p7p6p5p4p3p2p1p0

	move.w	d2,d6			; Swap 16x2
	move.w	d3,d7
	move.w	d0,d2
	move.w	d1,d3
	swap	d2
	swap	d3
	move.w	d2,d0
	move.w	d3,d1
	move.w	d6,d2
	move.w	d7,d3

; a7a6a5a4a3a2a1a0 b7b6b5b4b3b2b1b0 i7i6i5i4i3i2i1i0 j7j6j5j4j3j2j1j0
; e7e6e5e4e3e2e1e0 f7f6f5f4f3f2f1f0 m7m6m5m4m3m2m1m0 n7n6n5n4n3n2n1n0
; c7c6c5c4c3c2c1c0 d7d6d5d4d3d2d1d0 k7k6k5k4k3k2k1k0 l7l6l5l4l3l2l1l0
; g7g6g5g4g3g2g1g0 h7h6h5h4h3h2h1h0 o7o6o5o4o3o2o1o0 p7p6p5p4p3p2p1p0

	move.l	a4,(a1)
	move.l	#$0f0f0f0f,d5		; Swap 4x2
	sub.l	a3,a1
	move.l	d2,d6
	move.l	d3,d7
	lsr.l	#4,d6
	lsr.l	#4,d7
	eor.l	d0,d6
	eor.l	d1,d7
	and.l	d5,d6
	and.l	d5,d7
	eor.l	d6,d0
	eor.l	d7,d1
	lsl.l	#4,d6
	lsl.l	#4,d7
	eor.l	d6,d2
	eor.l	d7,d3

	move.l	a5,d6			; Extend 1x1, part 3
	move.l	a5,d7
	lsr.l	#1,d7
	eor.l	d6,d7
	and.l	d4,d7
	eor.l	d7,d6
	move.l	d6,(a1)
	eor.l	d7,d6
	sub.l	a3,a1
	add.l	d7,d7
	eor.l	d7,d6
	move.l	d6,a5


; a7a6a5a4c7c6c5c4 b7b6b5b4d7d6d5d4 i7i6i5i4k7k6k5k4 j7j6j5j4l7l6l5l4
; e7e6e5e4g7g6g5g4 f7f6f5f4h7h6h5h4 m7m6m5m4o7o6o5o4 n7n6n5n4p7p6p5p4
; a3a2a1a0c3c2c1c0 b3b2b1b0d3d2d1d0 i3i2i1i0k3k2k1k0 j3j2j1j0l3l2l1l0
; e3e2e1e0g3g2g1g0 f3f2f1f0h3h2h1h0 m3m2m1m0o3o2o1o0 n3n2n1n0p3p2p1p0

	move.l	#$00ff00ff,d5		; Swap 8x1
	move.l	d1,d6
	move.l	d3,d7
	lsr.l	#8,d6
	lsr.l	#8,d7
	eor.l	d0,d6
	eor.l	d2,d7
	and.l	d5,d6
	and.l	d5,d7
	eor.l	d6,d0
	eor.l	d7,d2
	move.l	a5,(a1)
	lsl.l	#8,d6
	sub.l	a3,a1
	lsl.l	#8,d7
	eor.l	d6,d1
	eor.l	d7,d3

	move.l	a6,d6			; Extend 1x1, part 4
	move.l	a6,d7
	lsr.l	#1,d7
	eor.l	d6,d7
	and.l	d4,d7
	eor.l	d7,d6
	move.l	d6,(a1)
	eor.l	d7,d6
	sub.l	a3,a1
	add.l	d7,d7
	eor.l	d7,d6
	move.l	d6,a6

; a7a6a5a4c7c6c5c4 e7e6e5e4g7g6g5g4 i7i6i5i4k7k6k5k4 m7m6m5m4o7o6o5o4
; b7b6b5b4d7d6d5d4 f7f6f5f4h7h6h5h4 j7j6j5j4l7l6l5l4 n7n6n5n4p7p6p5p4
; a3a2a1a0c3c2c1c0 e3e2e1e0g3g2g1g0 i3i2i1i0k3k2k1k0 m3m2m1m0o3o2o1o0
; b3b2b1b0d3d2d1d0 f3f2f1f0h3h2h1h0 j3j2j1j0l3l2l1l0 n3n2n1n0p3p2p1p0

	move.l	#$33333333,d5		; Swap 2x1
	move.l	d1,d6
	move.l	d3,d7
	lsr.l	#2,d6
	lsr.l	#2,d7
	eor.l	d0,d6
	eor.l	d2,d7
	and.l	d5,d6
	and.l	d5,d7
	move.l	a6,(a1)
	eor.l	d6,d0
	eor.l	d7,d2
	lea	4(a1,a3.l*8),a1
	lsl.l	#2,d6
	sub.l	a3,a1
	lsl.l	#2,d7
	eor.l	d6,d1
	eor.l	d7,d3

; a7a6b7b6c7c6d7d6 e7e6f7f6g7g6h7h6 i7i6j7j6k7k6l7l6 m7m6n7n6o7o6p7p6
; a5a4b5b4c5c4d5d4 e5e4f5f4g5g4h5h4 i5i4j5j4k5k4l5l4 m5m4n5n4o5o4p5p4
; a3a2b3b2c3c2d3d2 e3e2f3f2g3g2h3h2 i3i2j3j2k3k2l3l2 m3m2n3n2o3o2p3p2
; a1a0b1b0c1c0d1d0 e1e0f1f0g1g0h1h0 i1i0j1j0k1k0l1l0 m1m0n1n0o1o0p1p0

.framestart
	move.l	d0,d6			; Extend 1x1, part 1a
	move.l	d0,d7
	lsr.l	#1,d7
	eor.l	d6,d7
	and.l	d4,d7
	eor.l	d7,d6

	move.l	d1,a4
	move.l	d2,a5
	move.l	d3,a6

	cmp.l	a0,a2
	bhi	.x16
	blo	.row
	add.l	c2p2x1_8_c5_gen_data+C2P2X1_8_C5_GEN_CHUNKYROWMOD(pc),a0
	bra	.x16

.done
	addq.l	#4,sp

	movem.l	(sp)+,d2-d7/a2-a6
	rts


	cnop	0,4

c2p2x1_8_c5_gen_data	ds.b	C2P2X1_8_C5_GEN_DATASIZE

	cnop	0,4
