;sends the lower byte of d1 accross serial port
;corrupts bit 8 of d1
SERSEND:
				btst.b	#5,serdatr(a6)
				beq.s	SERSEND					;wait until last byte sent
				and.w	#$00FF,d1
				bset.l	#8,d1					;add stop bit
				move.w	d1,serdat(a6)
				rts

;waits for serial data and returns it in
;lower byte of d1
SERREC:
				btst.b	#6,serdatr(a6)
				beq.s	SERREC
				move.w	serdatr(a6),d1
				move.w	#$0800,intreq(a6)
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
RECFIRST:
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
				bsr		SERSEND
				ror.l	#8,d2
				bsr.s	SERREC
				move.b	d1,d2
				lsr.w	#8,d0
				move.b	d0,d1
				bsr		SERSEND
				ror.l	#8,d2
				move.l	d2,d0
				rts

PAUSE			MACRO
				move.l	#0,tstchip
				move.l	#0,tstchip
				move.l	#0,tstchip
				move.l	#0,tstchip
				move.l	#0,tstchip
				move.l	#0,tstchip
				move.l	#0,tstchip
				ENDM

INITSEND:
				move.l	#$bfd000,a0
				move.w	#15,d7
				move.l	#$bfe001,a3
				rts

SENDLONG:
				bset	#6,(a0)
				PAUSE
				WT
				move.w	d7,d6
SENDLOOP:
				add.l	d0,d0
				bcc.s	SENDZERO
				bset	#7,(a0)
				bra.s	SEND1
SENDZERO:
				bclr	#7,(a0)
SEND1:
				PAUSE
				bclr	#6,(a0)
				PAUSE
				WTNOT
				add.l	d0,d0
				bcc.s	SENDZERO2
				bset	#7,(a0)
				bra.s	SEND12
SENDZERO2:
				bclr	#7,(a0)
SEND12:
				PAUSE
				bset	#6,(a0)
				PAUSE
				WT
				dbra	d6,SENDLOOP

				bclr	#7,(a0)
				bclr	#6,(a0)
balls:
				btst	#3,(a0)
				beq.s	balls
				rts

SENDLAST:
				bset	#6,(a0)
				PAUSE
				WT
				move.w	d7,d6
SENDLOOPLAST:
				add.l	d0,d0
				bcc.s	SENDZEROLAST
				bset	#7,(a0)
				bra.s	SEND1LAST
SENDZEROLAST:
				bclr	#7,(a0)
SEND1LAST:
				PAUSE
				bclr	#6,(a0)
				PAUSE
				WTNOT

				add.l	d0,d0
				bcc.s	SENDZERO2LAST
				bset	#7,(a0)
				bra.s	SEND12LAST
SENDZERO2LAST:
				bclr	#7,(a0)
SEND12LAST:
				PAUSE
				bset	#6,(a0)
				PAUSE
				WT
				dbra	d6,SENDLOOPLAST

				bset	#7,(a0)
				PAUSE
				bclr	#6,(a0)
				PAUSE
ballsLAST:
				btst	#3,(a0)
				beq.s	ballsLAST
				rts


INITREC:
				move.l	#$bfd000,a0
				move.l	#Sys_SerialBuffer_vl,a1
				move.w	#15,d7
				move.l	#$bfe001,a3
				rts

BACKRECEIVE
				PAUSE
				bclr	#6,(a0)
				PAUSE
				bset	#7,(a0)
				move.l	d0,(a1)+

RECEIVE:
				PAUSE
				WT
				bclr.b	#7,(a0)
				move.w	d7,d6
RECIEVELOOP:
				bset	#6,(a0)
				PAUSE
				WTNOT
				add.l	d0,d0
				btst	#3,(a0)
				beq.s	noadd1
				addq	#1,d0
noadd1:
				PAUSE
				bclr	#6,(a0)
				PAUSE
				WT
				PAUSE
				add.l	d0,d0
				btst	#3,(a0)
				beq.s	noadd2
				addq	#1,d0
noadd2:
				dbra	d6,RECIEVELOOP
				PAUSE
				bset	#6,(a0)
				PAUSE
				WTNOT
				PAUSE
				btst	#3,(a0)
				beq		BACKRECEIVE
				PAUSE
				bset	#7,(a0)
				bclr	#6,(a0)
				move.l	d0,(a1)+
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
slp1:			btst	#1,$bfd000
				beq.s	slp1
				move.b	#$ff,$bfe301
				move.b	d0,$bfe101
				bset	#0,$bfd000
slp2:			btst	#1,$bfd000
				bne.s	slp2
				move.b	#0,$bfe301
				bclr	#0,$bfd000
slp3:			btst	#1,$bfd000
				beq.s	slp3
				move.b	$bfe101,d1
				bset	#0,$bfd000
slp4:			btst	#1,$bfd000
				bne.s	slp4
				bclr	#0,$bfd000
				lsr.l	#8,d0
				ror.l	#8,d1
				dbra	d2,slp1
				move.l	d1,d0
				rts

RECPAR:
ParRecFirst:
				move.w	#3,d2
rlp1:			move.b	#0,$bfe301
				bset	#1,$bfd000
rlp2:			btst	#0,$bfd000
				beq.s	rlp2
				move.b	$bfe101,d1
				bclr	#1,$bfd000
rlp3:			btst	#0,$bfd000
				bne.s	rlp3
				move.b	#$ff,$bfe301
				move.b	d0,$bfe101
				bset	#1,$bfd000
rlp4:			btst	#0,$bfd000
				beq.s	rlp4
				move.b	#0,$bfe301
				bclr	#1,$bfd000
rlp5:			btst	#0,$bfd000
				bne.s	rlp5

				lsr.l	#8,d0
				ror.l	#8,d1

				dbra	d2,rlp1
				move.l	d1,d0
				rts
