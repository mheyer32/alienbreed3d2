
 jsr InitParMaster
 
 jsr ParSendFirst
 
 move.w #0,$dff180
 
 rts


;Before calling either of the transmission routines, the
;appropriate initialisation routine must be called
;(only once).
;The master _MUST_ use the ParSendFirst routine, and the
;slave _MUST_ use the ParRecFirst routine.

InitParSlave:
	move.b	#%00000001,$bfd200
	rts
	
InitParMaster:
	move.b	#%00000010,$bfd200
	rts

SENDPAR:	
ParSendFirst:
	move.w	#3,d2
slp1:	btst	#1,$bfd000
	beq.s	slp1
	move.b	#$ff,$bfe301
	move.b	d0,$bfe101
	bset	#0,$bfd000
slp2:	btst	#1,$bfd000
	bne.s	slp2
	move.b	#0,$bfe301
	bclr	#0,$bfd000
slp3:	btst	#1,$bfd000
	beq.s	slp3
	move.b	$bfe101,d1
	bset	#0,$bfd000
slp4:	btst	#1,$bfd000
	bne.s	slp4
	bclr	#0,$bfd000
	lsr.l	#8,d0
	ror.l	#8,d1
	dbra	d2,slp1
	move.l d1,d0
	rts

RECPAR:	
ParRecFirst:
	move.w	#3,d2
rlp1:	move.b	#0,$bfe301
	bset	#1,$bfd000
rlp2:	btst	#0,$bfd000
	beq.s	rlp2
	move.b	$bfe101,d1
	bclr	#1,$bfd000
rlp3:	btst	#0,$bfd000
	bne.s	rlp3
	move.b	#$ff,$bfe301
	move.b	d0,$bfe101
	bset	#1,$bfd000
rlp4:	btst	#0,$bfd000
	beq.s	rlp4
	move.b	#0,$bfe301
	bclr	#1,$bfd000
rlp5:	btst	#0,$bfd000
	bne.s	rlp5
	
	lsr.l #8,d0
	ror.l #8,d1
	
	dbra	d2,rlp1
	move.l d1,d0
	rts