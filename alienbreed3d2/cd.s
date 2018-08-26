;
; cd.s - cd player for AB3D (C)opyright 1995 Team17 Ltd - Charlie
; $Log: $
;
;


	opt	L-,O+,P=68020

	INCDIR	utils:sysinc/
	INCLUDE exec/exec_lib.i		; change this for your path!.
	INCLUDE exec/io.i
	INCLUDE devices/cd.i


	XREF	_CreatePort
	XREF	_CreateExtIO
	XREF	_DeleteExtIO
	
	XREF	_DOSBase			; Need _DOSBase defined and Filled!
	XDEF	_SysBase



_test
	bsr	_InitCD
	tst.l	d0
	beq.s	.BadOpen

	moveq	#1,d0
	bsr	_PlayCD
	bsr	_StopCD
	bsr	_CloseCD

	moveq	#0,d0


.BadOpen
	rts


; end test routine..



	XDEF	_InitCD

_InitCD

; setup execbase 

	lea	Data(pc),a4
	move.l	4.w,_ExecBase-Data(a4)
	move.l	_ExecBase(pc),a6

; setup port 

	sub.l	a0,a0
	moveq	#0,d0
	jsr	_CreatePort
	tst.l	d0
	beq.b	.PortError

	move.l	d0,_CDPort-Data(a4)		; MsgPort for cd.device

; Create first extended io port

	move.l	d0,a0
	moveq	#IOSTD_SIZE,d0		; sizeof strct IORequest
	jsr	_CreateExtIO
	tst.l	d0
	beq.b	.PortError

	move.l	d0,_CDReq0-Data(a4)

; Create second extended io port

	move.l	_CDPort(pc),a0
	moveq	#IOSTD_SIZE,d0
	jsr	_CreateExtIO
	tst.l	d0
	beq.b	.PortError

	move.l	d0,_CDReq1-Data(a4)		; second EXTIO

; open device..

	lea	_CDDev(pc),a0
	moveq	#0,d0				; unit number
	move.l	_CDReq0(pc),a1
	moveq	#0,d1				; flags.
	jsr	_LVOOpenDevice(a6)
	tst.l	d0
	beq.b	.PortOk
	bra.b	.PortError

.PortOk
	move.l	_CDReq0(pc),a0
	move.l	_CDReq0(pc),a1

; copy _CDReq0 -> _CDReq1

	moveq	#20/4,d0
.loop
	move.l	(a0),(a1)
	dbra	d0,.loop


	moveq	#1,d0				; return value
	move.l	d0,_CDAvail-Data(a4)
	rts

.PortError
	moveq	#0,d0				; return value for error..
	move.l	d0,_CDAvail-Data(a4)
	rts


	XDEF	_PlayCD

_PlayCD

	lea	Data(pc),a4


	cmp.l	#0,_CDAvail-Data(a4)
	bne.b	.CDOk

	moveq	#0,d0
	rts

.CDOk
	move.l	d0,-(sp)

; kill any current activity..

	bsr.b	_StopCD

	move.l	_CDReq0(pc),a1
	move.w	#CD_PLAYTRACK,IO_COMMAND(a1)
	move.l	(sp)+,d0

	move.l	d0,IO_OFFSET(a1)		; play from
	move.l	#1,IO_LENGTH(a1)		; number of tracks to play for

	move.l	_ExecBase(pc),a6
	jsr	_LVOSendIO(a6)


	rts


	XDEF	_StopCD

_StopCD

	lea	Data(pc),a4

; check if CDReq0 is being used or not...

	move.l	_CDReq0(pc),a1
	move.l	_ExecBase(pc),a6
	jsr	_LVOCheckIO(a6)
	tst.l	d0
	bne.b	.NotUsed

	jsr	_LVOAbortIO(a6)
.NotUsed


	rts


	XDEF	_CloseCD

_CloseCD

	move.l	_CDReq0(pc),a1
	move.l	_ExecBase(pc),a6
	jsr	_LVOCloseDevice(a6)

	move.l	_CDReq0(pc),a0
	jsr	_DeleteExtIO
	
	rts

	XDEF	_CDPos

_CDPos
	lea	Data(pc),a4

; check if CDReq0 is being used or not...

	move.l	_CDReq0(pc),a1
	move.l	_ExecBase(pc),a6
	jsr	_LVOCheckIO(a6)
	tst.l	d0
	bne.b	.NotUsed
	moveq	#-1,d0

.NotUsed
		
	rts

;            Data Section

Data
	CNOP	0,4

_ExecBase
_SysBase
	dc.l	0

_CDAvail
	dc.l	0

_CDPort
	dc.l	0

_CDReq0
	dc.l	0

_CDReq1
	dc.l	0

_QCode
	dcb.b	1000,0

_CDDev:
	dc.b	"cd.device",0

	END
