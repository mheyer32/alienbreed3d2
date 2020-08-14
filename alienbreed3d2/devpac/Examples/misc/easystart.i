
* some startup code to make a Workbench execute look like the CLI
* based loosely on RKM Vol 1 page 4-36

* Include this at the front of your program
* after any other includes
* note that this needs exec/exec_lib.i

	IFND	LIBRARIES_DOSEXTENS_I
	include	libraries/dosextens.i
	ENDC


	movem.l	d0/a0,-(sp)		save initial values
	clr.l	returnMsg

	sub.l	a1,a1
	CALLEXEC FindTask		find us
	move.l	d0,a4

	tst.l	pr_CLI(a4)
	beq.s	fromWorkbench

* we were called from the CLI
	movem.l	(sp)+,d0/a0		restore regs
	bra.s	end_startup		and run the user prog

* we were called from the Workbench
fromWorkbench
	lea	pr_MsgPort(a4),a0
	CALLEXEC WaitPort		wait for a message
	lea	pr_MsgPort(a4),a0
	CALLEXEC GetMsg			then get it
	move.l	d0,returnMsg		save it for later reply

* do some other stuff here like the command line etc
	nop

	movem.l	(sp)+,d0/a0		restore
end_startup
	bsr.s	_main			call our program

* returns to here with exit code in d0
	move.l	d0,-(sp)		save it

	tst.l	returnMsg
	beq.s	exitToDOS		if I was a CLI

	CALLEXEC Forbid
	move.l	returnMsg(pc),a1
	CALLEXEC ReplyMsg

exitToDOS
	move.l	(sp)+,d0		exit code
	rts

* startup code variable
returnMsg	dc.l	0

* the program starts here
	even
_main
