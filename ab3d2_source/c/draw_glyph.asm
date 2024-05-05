	idnt	"draw_glyph.c"
	machine	68040
	opt o+,ol+,op+,oc+,ot+,oj+,ob+,om+,a-
	section	"CODE",code
	public	_draw_ChunkyGlyph
	cnop	0,4
_draw_ChunkyGlyph
	movem.l	l52,-(a7)
	move.b	d0,d6
	moveq	#0,d1
	move.b	d6,d1
	and.l	#65535,d1
	lsl.l	#3,d1
	lea	_draw_ScrollChars_vb,a2
	add.l	d1,a2
	moveq	#0,d1
	move.b	d6,d1
	and.l	#65535,d1
	lea	_draw_GlyphSpacing_vb,a1
	moveq	#7,d5
	and.b	(0,a1,d1.l),d5
	moveq	#0,d1
	move.b	d6,d1
	and.l	#65535,d1
	lea	_draw_GlyphSpacing_vb,a1
	add.l	d1,a1
	move.b	(a1),d1
	lsr.b	#4,d1
	move.b	d1,d4
	subq.b	#1,d4
	moveq	#0,d3
	cmp.w	#8,d3
	bcc	l51
l50
	move.l	a2,a1
	addq.l	#1,a2
	move.b	(a1),d2
	move.b	d4,d0
	tst.b	d2
	beq	l48
	move.b	d5,d1
	moveq	#0,d7
	move.b	d1,d7
	cmp.w	#7,d7
	bhi	l48
	move.l	l55(pc,d7.w*4),a1
	jmp	(a1)
	cnop	0,4
l55
	dc.l	l10
	dc.l	l14
	dc.l	l19
	dc.l	l24
	dc.l	l29
	dc.l	l34
	dc.l	l39
	dc.l	l44
l10
	move.b	#128,d1
	and.b	d2,d1
	beq	l12
	move.b	_draw_TextPen,(a0)
l12
	subq.b	#1,d0
	beq	l48
l14
	moveq	#64,d1
	and.b	d2,d1
	beq	l17
	move.b	_draw_TextPen,(1,a0)
l17
	subq.b	#1,d0
	beq	l48
l19
	moveq	#32,d1
	and.b	d2,d1
	beq	l22
	move.b	_draw_TextPen,(2,a0)
l22
	subq.b	#1,d0
	beq	l48
l24
	moveq	#16,d1
	and.b	d2,d1
	beq	l27
	move.b	_draw_TextPen,(3,a0)
l27
	subq.b	#1,d0
	beq	l48
l29
	moveq	#8,d1
	and.b	d2,d1
	beq	l32
	move.b	_draw_TextPen,(4,a0)
l32
	subq.b	#1,d0
	beq	l48
l34
	moveq	#4,d1
	and.b	d2,d1
	beq	l37
	move.b	_draw_TextPen,(5,a0)
l37
	subq.b	#1,d0
	beq	l48
l39
	moveq	#2,d1
	and.b	d2,d1
	beq	l42
	move.b	_draw_TextPen,(6,a0)
l42
	subq.b	#1,d0
	beq	l48
l44
	moveq	#1,d1
	and.b	d2,d1
	beq	l47
	move.b	_draw_TextPen,(7,a0)
l47
	subq.b	#1,d0
l48
	moveq	#0,d1
	move.w	_draw_TextPixelSpan,d1
	add.l	d1,a0
	addq.w	#1,d3
	cmp.w	#8,d3
	bcs	l50
l51
l52	reg	a2/d2/d3/d4/d5/d6/d7
	movem.l	(a7)+,a2/d2/d3/d4/d5/d6/d7
l54	equ	28
	rts
; stacksize=28
	public	_draw_ScrollChars_vb
	public	_draw_TextPixelSpan
	public	_draw_GlyphSpacing_vb
	public	_draw_TextPen
