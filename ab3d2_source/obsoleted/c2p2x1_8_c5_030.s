;
; 1999-01-08
;
; c2p2x1_8_c5_030
;
; 0.83vbl [all dma off] on Blizzard 1230-IV@50MHz
;

	IFND	BPLX
BPLX	EQU	320
	ENDC
	IFND	BPLY
BPLY	EQU	256
	ENDC
	IFND	BPLSIZE
BPLSIZE	EQU	BPLX*BPLY/8
	ENDC
	IFND	CHUNKYXMAX
CHUNKYXMAX EQU	BPLX
	ENDC
	IFND	CHUNKYYMAX
CHUNKYYMAX EQU	BPLY
	ENDC

	section	.text,code

; d0.w	chunkyx [chunky-pixels]
; d1.w	chunkyy [chunky-pixels]
; d2.w	(scroffsx) [screen-pixels]
; d3.w	scroffsy [screen-pixels]
; d4.w	(rowlen) [bytes] -- offset between one row and the next in a bpl
; d5.l	(bplsize) [bytes] -- offset between one row in one bpl and the next bpl

	XDEF	_c2p2x1_8_c5_030_init
	XDEF	c2p2x1_8_c5_030_init
_c2p2x1_8_c5_030_init
c2p2x1_8_c5_030_init
	movem.l	d2-d3,-(sp)
	andi.l	#$ffff,d0
	mulu.w	d0,d3
	lsr.l	#3,d3
	move.l	d3,c2p2x1_8_c5_030_scroffs
	mulu.w	d0,d1
	move.l	d1,c2p2x1_8_c5_030_pixels
	movem.l	(sp)+,d2-d3
	rts

; a0	c2pscreen
; a1	bitplanes

	XDEF	_c2p2x1_8_c5_030
	XDEF	c2p2x1_8_c5_030
_c2p2x1_8_c5_030
c2p2x1_8_c5_030
	movem.l	d2-d7/a2-a6,-(sp)

	add.w	#BPLSIZE,a1
	add.l	c2p2x1_8_c5_030_scroffs,a1

	move.l	#$55555555,d5

	move.l	#$00ff00ff,a6

	move.l	c2p2x1_8_c5_030_pixels,a5
	add.l	a0,a5
	move.l	a1,a2
	add.l	#BPLSIZE*4,a2
	cmpa.l	a0,a5
	beq	.none

	move.l	(a0)+,d0
	move.l	(a0)+,d1
	move.l	(a0)+,d2
	move.l	(a0)+,d3

	move.w	d2,d7			; Swap 16x2
	move.w	d0,d2
	swap	d2
	move.w	d2,d0
	move.w	d7,d2

	move.w	d3,d7
	move.w	d1,d3
	swap	d3
	move.w	d3,d1
	move.w	d7,d3

	move.l	#$0f0f0f0f,d6
	move.l	d2,d7			; Swap 4x2
	lsr.l	#4,d7
	eor.l	d0,d7
	and.l	d6,d7
	eor.l	d7,d0
	lsl.l	#4,d7
	eor.l	d7,d2

	move.l	d3,d7
	lsr.l	#4,d7
	eor.l	d1,d7
	and.l	d6,d7
	eor.l	d7,d1
	lsl.l	#4,d7
	eor.l	d7,d3

	move.l	a6,d6
	move.l	d1,d7			; Swap 8x1, part 1
	lsr.l	#8,d7
	eor.l	d0,d7
	and.l	d6,d7
	eor.l	d7,d0
	lsl.l	#8,d7
	eor.l	d7,d1

	bra	.start
.x
	move.l	(a0)+,d0
	move.l	(a0)+,d1
	move.l	(a0)+,d2
	move.l	(a0)+,d3
	move.l	d7,(a2)+
	eor.l	d4,d7
	add.l	d4,d4
	eor.l	d7,d4

	move.w	d2,d7			; Swap 16x2
	move.w	d0,d2
	swap	d2
	move.w	d2,d0
	move.w	d7,d2

	move.l	d4,-BPLSIZE-4(a2)

	move.w	d3,d7
	move.w	d1,d3
	swap	d3
	move.w	d3,d1
	move.w	d7,d3

	move.l	a3,d4
	move.l	d4,d7
	lsr.l	d7
	eor.l	d4,d7
	and.l	d5,d7
	eor.l	d7,d4
	move.l	d4,BPLSIZE*2(a1)
	eor.l	d7,d4
	add.l	d7,d7
	eor.l	d7,d4

	move.l	#$0f0f0f0f,d6
	move.l	d2,d7			; Swap 4x2
	lsr.l	#4,d7
	eor.l	d0,d7
	and.l	d6,d7
	eor.l	d7,d0
	lsl.l	#4,d7
	eor.l	d7,d2
	move.l	d4,BPLSIZE(a1)

	move.l	d3,d7
	lsr.l	#4,d7
	eor.l	d1,d7
	and.l	d6,d7
	eor.l	d7,d1
	lsl.l	#4,d7
	eor.l	d7,d3

	move.l	a4,d4
	move.l	d4,d7
	lsr.l	d7
	eor.l	d4,d7
	and.l	d5,d7
	eor.l	d7,d4
	move.l	d4,(a1)+
	eor.l	d7,d4
	add.l	d7,d7
	eor.l	d7,d4

	move.l	a6,d6
	move.l	d1,d7			; Swap 8x1, part 1
	lsr.l	#8,d7
	eor.l	d0,d7
	and.l	d6,d7
	eor.l	d7,d0
	lsl.l	#8,d7
	eor.l	d7,d1
	move.l	d4,-BPLSIZE-4(a1)
.start

	move.l	#$33333333,d6
	move.l	d1,d7			; Swap 2x1, part 1
	lsr.l	#2,d7
	eor.l	d0,d7
	and.l	d6,d7
	eor.l	d7,d0
	lsl.l	#2,d7
	eor.l	d1,d7

	move.l	d0,d4
	lsr.l	d4
	eor.l	d0,d4
	and.l	d5,d4
	eor.l	d4,d0
	move.l	d0,BPLSIZE*2(a2)
	eor.l	d4,d0
	add.l	d4,d4
	eor.l	d4,d0

	move.l	a6,d6
	move.l	d3,d1			; Swap 8x1, part 2
	lsr.l	#8,d1
	eor.l	d2,d1
	and.l	d6,d1
	eor.l	d1,d2
	lsl.l	#8,d1
	eor.l	d1,d3

	move.l	d0,BPLSIZE(a2)

	move.l	#$33333333,d6
	move.l	d3,d1			; Swap 2x1, part 2
	lsr.l	#2,d1
	eor.l	d2,d1
	and.l	d6,d1
	eor.l	d1,d2
	lsl.l	#2,d1
	eor.l	d1,d3
	move.l	d2,a3
	move.l	d3,a4

	move.l	d7,d4
	lsr.l	d4
	eor.l	d7,d4
	and.l	d5,d4
	eor.l	d4,d7

	cmp.l	a0,a5
	bne	.x
.x2
	move.l	d7,(a2)+
	eor.l	d4,d7
	add.l	d4,d4
	eor.l	d7,d4
	move.l	d4,-BPLSIZE-4(a2)

	move.l	a3,d4
	move.l	d4,d7
	lsr.l	d7
	eor.l	d4,d7
	and.l	d5,d7
	eor.l	d7,d4
	move.l	d4,BPLSIZE*2(a1)
	eor.l	d7,d4
	add.l	d7,d7
	eor.l	d7,d4
	move.l	d4,BPLSIZE(a1)

	move.l	a4,d4
	move.l	d4,d7
	lsr.l	d7
	eor.l	d4,d7
	and.l	d5,d7
	eor.l	d7,d4
	move.l	d4,(a1)+
	eor.l	d7,d4
	add.l	d7,d7
	eor.l	d7,d4
	move.l	d4,-BPLSIZE-4(a1)

.none
	movem.l	(sp)+,d2-d7/a2-a6
	rts

	section	.bss,bss

c2p2x1_8_c5_030_scroffs	ds.l	1
c2p2x1_8_c5_030_pixels	ds.l	1
