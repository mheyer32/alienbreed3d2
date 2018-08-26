;sends the lower byte of d1 accross serial port
;corrupts bit 8 of d1
SERSEND:
	btst.b	#5,SERDATR(a6)
	beq.s	SERSEND		;wait until last byte sent
	and.w	#$00FF,d1
	bset.l	#8,d1		;add stop bit
	move.w	d1,SERDAT(a6)
	rts
	
;waits for serial data and returns it in 
;lower byte of d1
SERREC:
	btst.b	#6,SERDATR(a6)
	beq.s	SERREC
	move.w	SERDATR(a6),d1
	move.w	#$0800,INTREQ(a6)
	and.w	#$00ff,d1
	rts
	
;sends and receives an interleaved long word
;from d0 into d0 (sends first)
SENDFIRST:
	move.b	d0,d1
	bsr.s	SERSEND
	bsr.s	SERREC
	move.b	d1,d2
	ror.l	#8,d2
	lsr.w	#8,d0
	move.b	d0,d1
	bsr.s	SERSEND
	bsr.s	SERREC
	move.b	d1,d2
	ror.l	#8,d2
	swap	d0
	move.b	d0,d1
	bsr.s	SERSEND
	bsr.s	SERREC
	move.b	d1,d2
	ror.l	#8,d2
	lsr.w	#8,d0
	move.b	d0,d1
	bsr.s	SERSEND
	bsr.s	SERREC
	move.b	d1,d2
	ror.l	#8,d2
	move.l	d2,d0
	rts
	
;sends and receives an interleaved long word
;from d0 into d0 (receives first)
RECEIVEFIRST:
	bsr.s	SERREC
	move.b	d1,d2
	move.b	d0,d1
	bsr.s	SERSEND
	ror.l	#8,d2
	bsr.s	SERREC
	move.b	d1,d2
	lsr.w	#8,d0
	move.b	d0,d1
	bsr.s	SERSEND
	ror.l	#8,d2
	bsr.s	SERREC
	move.b	d1,d2
	swap	d0
	move.b	d0,d1
	bsr.s	SERSEND
	ror.l	#8,d2
	bsr.s	SERREC
	move.b	d1,d2
	lsr.w	#8,d0
	move.b	d0,d1
	bsr	SERSEND
	ror.l	#8,d2
	move.l	d2,d0
	rts