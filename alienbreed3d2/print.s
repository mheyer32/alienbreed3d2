***************************************************
*   Print null-terminated text pointed to by a0   *
*   at coords (d0,d1)                             *
***************************************************
Print:
	movem.l	a0-a3/d0-d3,-(sp)
	move.l	FASTBUFFER,a1
	muls.w	#ScreenWidth,d1
	asl.l	#3,d1
	ext.l	d0
	add.l	d0,d0
	move.l	d0,d2
	add.l	d0,d0
	add.l	d2,d0
	add.l	d0,d1
	lea	(a1,d1.l),a1
	move.l	Font,a2
.NextChar:
	move.l	a1,a3
	add.l	#6,a1
	move.w	#0,d0
	move.b	(a0)+,d0
	beq.s	.DoneText
	lsl.w	#6,d0
	move.w	#0,d3
.NextYPoint:
	move.w	#0,d2
.NextXPoint:
	move.b	(a2,d0.w),d1
	beq.s	.NoPoint
	move.b	#255,(a3,d2.w)
.NoPoint:
	addq.w	#1,d0
	addq.w	#1,d2
	cmp.w	#8,d2
	blt.s	.NextXPoint
	add.l	#ScreenWidth,a3
	addq.w	#1,d3
	cmp.w	#8,d3
	blt.s	.NextYPoint
	bra.s	.NextChar
.DoneText:
	movem.l	(sp)+,a0-a3/d0-d3
	rts

***************************************
*   Print value passed in PVal at     *
*   coords passed in PXpos and PYos   *
***************************************
PrintVal:
	movem.l	a0-a1/d0-d4,-(sp)
	move.l	PVal,d0
	move.l	PXpos,d1
	move.l	PYpos,d2
	move.l	#.NumBuffer+8,a0
	move.l	#.CharBuffer,a1
	move.w	#7,d4
.MakeTextLoop:
	move.b	d0,d3
	and.w	#$000f,d3
	move.b	(a1,d3.w),-(a0)
	lsr.l	#4,d0
	dbra	d4,.MakeTextLoop
	move.l	d1,d0
	move.l	d2,d1
	bsr	Print
	movem.l	(sp)+,a0-a1/d0-d4
	rts

.NumBuffer:	ds.b	8
		dc.b	0
.CharBuffer:	dc.b	"0123456789ABCDEF"
	even
PXpos:		dc.l	0
PYpos:		dc.l	0
PVal:		dc.l	0
