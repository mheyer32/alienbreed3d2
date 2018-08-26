;
; cd.s - cd player for AB3D (C)opyright 1995 Team17 Ltd - Charlie
; $Log: $
;
;


	opt	O+,P=68020

	include "workbench:utilities/devpac/system.gs"

;	INCLUDE utils:sysinc/exec_lib.i		; change this for your path!.
	INCLUDE utils:sysinc/exec/io.i
	INCLUDE utils:sysinc/devices/cd.i

	INCLUDE utils:sysinc/exec/lists.i


_test
	bsr	_InitCD
	move.l d0,doneit
	tst.l	d0
	beq.s	.BadOpen

	moveq	#1,d0
	bsr	_PlayCD
	
.waitforstop:
	btst #6,$bfe001
	bne.s .waitforstop
	
	bsr	_StopCD
	bsr	_CloseCD

	moveq	#0,d0


.BadOpen
	rts


; end test routine..

doneit: dc.l 0


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



_CreatePort
	movem.l	d2-d5/a2,-(sp)
	move.l	$18(sp),d3
	move.b	$1F(sp),d2
	moveq	#-1,d5
	move.l	d5,d0
	move.l	_ExecBase(pc),a6
	jsr	_LVOAllocSignal(a6)

	move.l	d0,d4
	ble.s	.L6

	move.l	#$10001,d1
	moveq	#$22,d0
	jsr	_LVOAllocMem(a6)

	move.l	d0,a2
	move.l	a2,d5
	beq.s	.L7

	move.l	d3,10(a2)
	move.b	d2,9(a2)
	move.b	#4,8(a2)
	clr.b	14(a2)
	move.b	d4,15(a2)
	sub.l	a1,a1
	jsr	_LVOFindTask(a6)

	move.l	d0,$10(a2)
	tst.l	d3
	beq.s	.L4

	move.l	a2,a1
	jsr	_LVOAddPort(a6)

	bra.s	.L12

.L4
	move.l	$14(a2),a0
	NEWLIST a0

.L12
	move.l	a2,d0
	bra.s	.L1

.L7
	move.l	d4,d0
	jsr	_LVOFreeSignal(a6)

.L6
	moveq	#0,d0
.L1
	movem.l	(sp)+,d2-d5/a2
	rts

_DeletePort
	move.l	a2,-(sp)
	move.l	8(sp),a2
	tst.l	10(a2)
	beq.s	.L14

	move.l	a2,a1
	move.l	_ExecBase(pc),a6
	jsr	_LVORemPort(a6)

.L14
	move.b	#$FF,8(a2)
	moveq	#-1,d0
	move.l	d0,$14(a2)
	moveq	#0,d0
	move.b	15(a2),d0
	jsr	_LVOFreeSignal(a6)

	move.l	#$22,a1
	move.l	a2,d0

	jsr	_LVOFreeMem(a6)

	move.l	(sp)+,a2
	rts


_CreateExtIO
	movem.l	d2-d4,-(sp)
	move.l	$10(sp),d2
	move.l	$14(sp),d3
	tst.l	d2
	beq.s	.L3

	move.l	#$10001,d1
	move.l	d3,d0
	move.l	_ExecBase(pc),a6
	jsr	_LVOAllocMem(a6)

	move.l	d0,a0
	move.l	a0,d4
	beq.s	.L3

	move.b	#7,8(a0)
	move.w	d3,$12(a0)
	move.l	d2,14(a0)
	move.l	a0,d0
	bra.s	.L1

.L3
	moveq	#0,d0
.L1
	movem.l	(sp)+,d2-d4
	rts

_DeleteExtIO
	move.l	4(sp),a0
	move.l	a0,d0
	beq.s	.L10
	moveq	#-1,d0
	move.l	d0,(a0)
	moveq	#-1,d0
	move.l	d0,$14(a0)
	moveq	#0,d0
	move.w	$12(a0),d0
	move.l	a0,a1

	move.l	_ExecBase(pc),a6
	jsr	_LVOFreeMem(a6)

.L10
	rts


;            Data Section

Data
	CNOP	0,4

_ExecBase
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
	dcb.b	10000,0

_CDDev:
	dc.b	"cd.device",0

	END
