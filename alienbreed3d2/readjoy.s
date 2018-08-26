
	opt	O+,D+,L+,P=68020


	INCDIR	utils:sysinc
	include "workbench:utilities/devpac/system.gs"
	INCLUDE	libraries/lowlevel.i
;	INCLUDE	exec/exec_lib.i

_LVOReadJoyPort	EQU	-$1e


	XDEF	_InitLowLevel

_InitLowLevel
	lea	_lowlevel(pc),a1
	moveq	#1,d0
	move.l	4.w,a6
	jsr	_LVOOpenLibrary(a6)
	tst.l	d0
	beq.s	.NoLowLib
	move.l	d0,_LowBase

	rts

.NoLowLib
	moveq	#-1,d0
	rts


	XDEF	_CloseLowLevel

_CloseLowLevel
	move.l	_LowBase(pc),a1
	tst.l	a1
	beq.s	.Exit
	move.l	4.w,a6
	jsr	_LVOCloseLibrary(a6)
.Exit
	rts



; pass port number in d0 0-3

	XDEF	_ReadJoy
_ReadJoy

	move.l	_LowBase(pc),a6
	jsr	_LVOReadJoyPort(a6)

	move.l	d0,d1

	and.l	#JP_TYPE_MASK,d1

; bits in d1


	cmp.l	#JP_TYPE_NOTAVAIL,d1 	
	beq.b	.Empty

	cmp.l	#JP_TYPE_GAMECTLR,d1 
	beq.b	.GameCtrl



	cmp.l	#JP_TYPE_MOUSE,d1    
	beq.b	.Mouse

	cmp.l	#JP_TYPE_JOYSTK,d1   
	beq.b	.Joystick


;	cmp.l	#JP_TYPE_UNKNOWN,d1  


; type is an unknown type 

.Empty

	rts

.GameCtrl

;	these are the bit defs..

;     JPF_BUTTON_BLUE         Blue - Stop
;     JPF_BUTTON_RED          Red - Select
;     JPF_BUTTON_YELLOW       Yellow - Repeat
;     JPF_BUTTON_GREEN        Green - Shuffle
;     JPF_BUTTON_FORWARD      Charcoal - Forward
;     JPF_BUTTON_REVERSE      Charcoal - Reverse
;     JPF_BUTTON_PLAY         Grey - Play/Pause
;     JPF_JOY_UP              Up
;     JPF_JOY_DOWN            Down
;     JPF_JOY_LEFT            Left
;     JPF_JOY_RIGHT           Right

.Joystick

.Mouse
	rts



Data:

_LowBase
	dc.l	0

_lowlevel
	dc.b	'lowlevel.library',0
	even

	END
	