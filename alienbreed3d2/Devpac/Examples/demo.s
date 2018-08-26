***
*** THIS PROGRAM INCLUDES DELIBERATE ERRORS; IT IS DESIGNED FOR USE
*** IN CONJUNCTION WITH THE TUTORIAL IN THE MANUAL!!!
***

	opt	l-,c+,d+		nolink,case dependant,debug
	opt	e-			disable Even checks

* this source code (C) HiSoft 1992 All Rights Reserved
* a simple demo program to print a message on the screen then quit
* it uses the DOS and EXEC libraries.


	include	/system			use the pre-assembled header

* start by opening the DOS library
start	move.l	dosname,a1
	moveq	#0,d0			any version
	CALLEXEC OpenLibrary
	tst.l	d0
	beq	quit_fast		quit if cant

	move.l	d0,_DOSBase		save pointer

* now find our output handle
	CALLDOS	Output
	move.l	d0,d4			d4=output handle

* and print a message
	move.l	d4,d1			file handle
	move.l	#string,d2		address of message
	moveq	#stringlen,d3		length
	CALLDOS	Write			and send it

* dont close the output handle otherwise the CLI bombs!


* finished so close DOS library
	mov.l	_DOSBase,a1
	CALLEXEC CloseLibrary

quit_fast
	rts				and finish

_DOSBase	dc.l	0		space for pointer

* strings here

string	dc.b	'A Program written with HiSoft''s Devpac Amiga',10
stringlen	equ	*-string

* this defines the name of the DOS library
dosname	DOSNAME

	even
