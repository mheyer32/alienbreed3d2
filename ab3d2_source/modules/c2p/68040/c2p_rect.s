
; C2P a rectangular area between equally-sized chunkybuffer and
; destination bitplanes
;
; This routine might look a bit odd and inflexible; that is entirely correct,
; its purpose is to allow "dirty rectangles" updating of the chipbuffer
; (that is, only c2p changed parts of screen), for example in a windowing
; system or a 2d game which has mainly static backgrounds
;
; Optimized for 040+
; By Mikael Kalms, although strongly influenced by Aki's and Azure's
;  040+ routines

	section	.text,code

; d0.w	x [multiple of 32]
; d1.w	y
; d2.w	width [multiple of 32]
; d3.w	height
; d4.w	chunky rowmod
; d5.w	bpl rowmod
; d6.l	bplsize
; a0	chunky, upper-left corner of rect
; a1	bitplanes, upper-left corner of rect

; No error checking is performed!

		rsreset
c2p_chunkyrowmod rs.w	1
c2p_chunkymod	rs.w	1
c2p_bplmod	rs.w	1
c2p_ycount	rs.w	1
c2p_stacksize	rs.b	0

c2p_rect
	movem.l	d2-d7/a2-a6,-(sp)
	subq.l	#c2p_stacksize,sp
	move.w	d1,d7
	andi.l	#$ffff,d0
	mulu.w	d4,d1
	mulu.w	d5,d7
	add.l	d0,d1
	move.w	d4,c2p_chunkyrowmod(sp)
	lsr.l	#3,d0
	add.l	d1,a0
	sub.w	d2,d4
	add.l	d0,d7
	move.l	a0,a4
	add.l	d7,a1
	add.w	d2,a4
	move.l	d6,a3
	lsr.w	#3,d2
	move.w	d4,c2p_chunkymod(sp)
	sub.w	d2,d5
	lea	(a1,a3.l*8),a1
	move.w	d5,c2p_bplmod(sp)
	sub.l	a3,a1
	move.w	d3,c2p_ycount(sp)

	move.l	(a0)+,d0
	move.l	(a0)+,d1
	move.l	(a0)+,d2
	move.l	(a0)+,d3
	move.l	(a0)+,d4
	move.l	(a0)+,d5
	move.l	(a0)+,d6
	move.l	(a0)+,a2

	swap	d4
	swap	d5
	eor.w	d0,d4
	eor.w	d1,d5
	eor.w	d4,d0
	eor.w	d5,d1
	eor.w	d0,d4
	eor.w	d1,d5
	swap	d4
	swap	d5

	move.l	d4,d7
	lsr.l	#2,d7
	eor.l	d0,d7
	and.l	#$33333333,d7
	eor.l	d7,d0
	lsl.l	#2,d7
	eor.l	d7,d4
	move.l	d5,d7
	lsr.l	#2,d7
	eor.l	d1,d7
	and.l	#$33333333,d7
	eor.l	d7,d1
	lsl.l	#2,d7
	eor.l	d7,d5

	exg	d5,a2

	swap	d6
	swap	d5
	eor.w	d2,d6
	eor.w	d3,d5
	eor.w	d6,d2
	eor.w	d5,d3
	eor.w	d2,d6
	eor.w	d3,d5
	swap	d6
	swap	d5

	move.l	d6,d7
	lsr.l	#2,d7
	eor.l	d2,d7
	and.l	#$33333333,d7
	eor.l	d7,d2
	lsl.l	#2,d7
	eor.l	d7,d6
	move.l	d5,d7
	lsr.l	#2,d7
	eor.l	d3,d7
	and.l	#$33333333,d7
	eor.l	d7,d3
	lsl.l	#2,d7
	eor.l	d7,d5

	move.l	d1,d7
	lsr.l	#4,d7
	eor.l	d0,d7
	and.l	#$0f0f0f0f,d7
	eor.l	d7,d0
	lsl.l	#4,d7
	eor.l	d7,d1
	move.l	d3,d7
	lsr.l	#4,d7
	eor.l	d2,d7
	and.l	#$0f0f0f0f,d7
	eor.l	d7,d2
	lsl.l	#4,d7
	eor.l	d7,d3
	bra	.start
.row
	move.l	(a0)+,d0
	move.l	(a0)+,d1
	move.l	(a0)+,d2
	move.l	(a0)+,d3
	move.l	(a0)+,d4
	move.l	(a0)+,d5
	move.l	(a0)+,d6
	tst.l	(a0)

	move.l	d7,(a1)
	swap	d4
	swap	d5
	sub.l	a3,a1
	eor.w	d0,d4
	eor.w	d1,d5
	eor.w	d4,d0
	eor.w	d5,d1
	eor.w	d0,d4
	eor.w	d1,d5
	swap	d4
	swap	d5

	move.l	d4,d7
	lsr.l	#2,d7
	eor.l	d0,d7
	and.l	#$33333333,d7
	eor.l	d7,d0
	lsl.l	#2,d7
	eor.l	d7,d4
	move.l	d5,d7
	lsr.l	#2,d7
	move.l	a2,(a1)
	eor.l	d1,d7
	sub.l	a3,a1
	and.l	#$33333333,d7
	eor.l	d7,d1
	lsl.l	#2,d7
	eor.l	d7,d5
	move.l	d5,a2
	move.l	(a0)+,d5

	swap	d6
	swap	d5
	eor.w	d2,d6
	eor.w	d3,d5
	eor.w	d6,d2
	eor.w	d5,d3
	eor.w	d2,d6
	eor.w	d3,d5
	swap	d6
	swap	d5

	move.l	d6,d7
	lsr.l	#2,d7
	eor.l	d2,d7
	move.l	a5,(a1)
	and.l	#$33333333,d7
	sub.l	a3,a1
	eor.l	d7,d2
	lsl.l	#2,d7
	eor.l	d7,d6
	move.l	d5,d7
	lsr.l	#2,d7
	eor.l	d3,d7
	and.l	#$33333333,d7
	eor.l	d7,d3
	lsl.l	#2,d7
	eor.l	d7,d5

	move.l	d1,d7
	lsr.l	#4,d7
	eor.l	d0,d7
	and.l	#$0f0f0f0f,d7
	eor.l	d7,d0
	lsl.l	#4,d7
	eor.l	d7,d1
	move.l	d3,d7
	move.l	a6,(a1)+
	lsr.l	#4,d7
	lea	(a1,a3.l*8),a1
	eor.l	d2,d7
	sub.l	a3,a1
	and.l	#$0f0f0f0f,d7
	eor.l	d7,d2
	lsl.l	#4,d7
	eor.l	d7,d3

	add.w	c2p_bplmod(sp),a1
	bra	.start
.x
	move.l	(a0)+,d0
	move.l	(a0)+,d1
	move.l	(a0)+,d2
	move.l	(a0)+,d3
	move.l	(a0)+,d4
	move.l	(a0)+,d5
	move.l	(a0)+,d6
	tst.l	(a0)

	move.l	d7,(a1)
	swap	d4
	swap	d5
	sub.l	a3,a1
	eor.w	d0,d4
	eor.w	d1,d5
	eor.w	d4,d0
	eor.w	d5,d1
	eor.w	d0,d4
	eor.w	d1,d5
	swap	d4
	swap	d5

	move.l	d4,d7
	lsr.l	#2,d7
	eor.l	d0,d7
	and.l	#$33333333,d7
	eor.l	d7,d0
	lsl.l	#2,d7
	eor.l	d7,d4
	move.l	d5,d7
	lsr.l	#2,d7
	move.l	a2,(a1)
	eor.l	d1,d7
	sub.l	a3,a1
	and.l	#$33333333,d7
	eor.l	d7,d1
	lsl.l	#2,d7
	eor.l	d7,d5
	move.l	d5,a2
	move.l	(a0)+,d5

	swap	d6
	swap	d5
	eor.w	d2,d6
	eor.w	d3,d5
	eor.w	d6,d2
	eor.w	d5,d3
	eor.w	d2,d6
	eor.w	d3,d5
	swap	d6
	swap	d5

	move.l	d6,d7
	lsr.l	#2,d7
	eor.l	d2,d7
	move.l	a5,(a1)
	and.l	#$33333333,d7
	sub.l	a3,a1
	eor.l	d7,d2
	lsl.l	#2,d7
	eor.l	d7,d6
	move.l	d5,d7
	lsr.l	#2,d7
	eor.l	d3,d7
	and.l	#$33333333,d7
	eor.l	d7,d3
	lsl.l	#2,d7
	eor.l	d7,d5

	move.l	d1,d7
	lsr.l	#4,d7
	eor.l	d0,d7
	and.l	#$0f0f0f0f,d7
	eor.l	d7,d0
	lsl.l	#4,d7
	eor.l	d7,d1
	move.l	d3,d7
	move.l	a6,(a1)+
	lsr.l	#4,d7
	lea	(a1,a3.l*8),a1
	eor.l	d2,d7
	sub.l	a3,a1
	and.l	#$0f0f0f0f,d7
	eor.l	d7,d2
	lsl.l	#4,d7
	eor.l	d7,d3
.start
	move.l	d2,d7
	lsr.l	#8,d7
	eor.l	d0,d7
	and.l	#$00ff00ff,d7
	eor.l	d7,d0
	lsl.l	#8,d7
	eor.l	d7,d2
	move.l	d2,d7
	lsr.l	#1,d7
	eor.l	d0,d7
	and.l	#$55555555,d7
	eor.l	d7,d0
	move.l	d0,(a1)
	add.l	d7,d7
	sub.l	a3,a1
	eor.l	d7,d2
; d0,d2 done				; d0 = bpl7, d2 = bpl6
	move.l	a2,d0

	move.l	d0,d7
	lsr.l	#4,d7
	eor.l	d4,d7
	and.l	#$0f0f0f0f,d7
	eor.l	d7,d4
	lsl.l	#4,d7
	eor.l	d7,d0
	move.l	d5,d7
	lsr.l	#4,d7
	eor.l	d6,d7
	and.l	#$0f0f0f0f,d7
	eor.l	d7,d6
	lsl.l	#4,d7
	eor.l	d7,d5

	move.l	d6,d7
	move.l	d2,(a1)
	lsr.l	#8,d7
	sub.l	a3,a1
	eor.l	d4,d7
	and.l	#$00ff00ff,d7
	eor.l	d7,d4
	lsl.l	#8,d7
	eor.l	d7,d6
	move.l	d6,d7
	lsr.l	#1,d7
	eor.l	d4,d7
	and.l	#$55555555,d7
	eor.l	d7,d4
	add.l	d7,d7
	eor.l	d7,d6
; d4,d6 done				; d4 = bpl5, d6 = bpl4

	move.l	d3,d7
	lsr.l	#8,d7
	eor.l	d1,d7
	move.l	d4,(a1)
	and.l	#$00ff00ff,d7
	sub.l	a3,a1
	eor.l	d7,d1
	lsl.l	#8,d7
	eor.l	d7,d3
	move.l	d3,d7
	lsr.l	#1,d7
	eor.l	d1,d7
	and.l	#$55555555,d7
	eor.l	d7,d1
	add.l	d7,d7
	eor.l	d7,d3
; d1,d3 done				; d1 = bpl3, d3 = bpl2

	move.l	d5,d7
	lsr.l	#8,d7
	eor.l	d0,d7
	and.l	#$00ff00ff,d7
	eor.l	d7,d0
	lsl.l	#8,d7
	move.l	d6,(a1)
	eor.l	d7,d5
	sub.l	a3,a1
	move.l	d5,d7
	lsr.l	#1,d7
	eor.l	d0,d7
	and.l	#$55555555,d7
	eor.l	d7,d0
	add.l	d7,d7
	eor.l	d7,d5
; d0,d5 done				; d0 = bpl1, d5 = bpl0
	move.l	d1,d7
	move.l	d3,a2
	move.l	d0,a5
	move.l	d5,a6

	cmp.l	a0,a4
	bne	.x

	add.w	c2p_chunkymod(sp),a0
	add.w	c2p_chunkyrowmod(sp),a4

	subq.w	#1,c2p_ycount(sp)
	bne	.row

	move.l	d7,(a1)
	sub.l	a3,a1
	move.l	a2,(a1)
	sub.l	a3,a1
	move.l	a5,(a1)
	sub.l	a3,a1
	move.l	a6,(a1)+
	lea	(a1,a3.l*8),a1
	sub.l	a3,a1

	addq.l	#c2p_stacksize,sp
	movem.l	(sp)+,d2-d7/a2-a6
	rts
