
;	opt	O+,D+,L+,P=68020


;	INCDIR	include:
;	include workbench:utilities/devpac/system.gs"
				INCLUDE	libraries/lowlevel.i
;	INCLUDE	exec/exec_lib.i

_LVOReadJoyPort	EQU		-$1e


;	XDEF	_InitLowLevel

_InitLowLevel
				lea		_lowlevel(pc),a1
				moveq	#1,d0
				CALLEXEC OpenLibrary
				tst.l	d0
				beq.s	.NoLowLib
				move.l	d0,_LowBase
				rts

.NoLowLib
				moveq	#-1,d0
				rts


;	XDEF	_CloseLowLevel

_CloseLowLevel
				move.l	_LowBase(pc),a1
				tst.l	a1
				beq.s	.Exit
				CALLEXEC CloseLibrary
.Exit
				rts



; pass port number in d0 0-3

;	XDEF	_ReadJoy
_ReadJoy1
				move.l	a6,-(a7)
				move.l	#1,d0
				move.l	_LowBase(pc),a6
				jsr		_LVOReadJoyPort(a6)

				move.l	(a7)+,a6
				move.l	d0,d1
;	and.l #$00FF000F,d0

				and.l	#JP_TYPE_MASK,d1
;
; bits in d1
;
;
				cmp.l	#JP_TYPE_NOTAVAIL,d1
				beq.b	.Empty

				cmp.l	#JP_TYPE_GAMECTLR,d1
				beq.b	.GameCtrl

				cmp.l	#JP_TYPE_MOUSE,d1
				beq		.Mouse

				cmp.l	#JP_TYPE_JOYSTK,d1
				beq		.Joystick

;	cmp.l	#JP_TYPE_UNKNOWN,d1
;
;
; type is an unknown type
;
.Empty
;
				rts
;
.GameCtrl

;	these are the bit defs..
;
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

				move.l	#KeyMap_vb,a5
				moveq	#0,d5
				move.b	forward_key,d5
				move.l	d0,d1
				and.l	#JPF_JOY_UP,d0
				sne		(a5,d5.w)
				move.b	backward_key,d5
				move.l	d1,d0
				and.l	#JPF_JOY_DOWN,d0
				sne		(a5,d5.w)
				move.b	turn_left_key,d5
				move.l	d1,d0
				and.l	#JPF_JOY_LEFT,d0
				sne		(a5,d5.w)
				move.b	turn_right_key,d5
				move.l	d1,d0
				and.l	#JPF_JOY_RIGHT,d0
				sne		(a5,d5.w)

				move.b	fire_key,d5
				move.l	d1,d0
				and.l	#JPF_BUTTON_GREEN,d0
				sne		(a5,d5.w)

				move.b	operate_key,d5
				move.l	d1,d0
				and.l	#JPF_BUTTON_YELLOW,d0
				sne		(a5,d5.w)

				move.b	run_key,d5
				move.l	d1,d0
				and.l	#JPF_BUTTON_RED,d0
				sne		(a5,d5.w)

				move.b	duck_key,d5
				move.l	d1,d0
				and.l	#JPF_BUTTON_BLUE,d0
				beq.s	.notduckbutpre
				tst.b	.ducklast
				bne.s	.notduckbut
				st		(a5,d5.w)
				st		.ducklast
				bra.s	.notduckbut
.notduckbutpre:
				clr.b	.ducklast
.notduckbut:

				move.b	force_sidestep_key,d5
				move.l	d1,d0
				and.l	#JPF_BUTTON_FORWARD,d0
				sne		(a5,d5.w)

				move.b	jump_key,d5
				move.l	d1,d0
				and.l	#JPF_BUTTON_REVERSE,d0
				sne		(a5,d5.w)

				move.l	d1,d0
				and.l	#JPF_BUTTON_PLAY,d0
				beq.s	.nonextweappre

				tst.b	PLR1_GunFrame
				bne.s	.nonextweappre

				tst.b	.heldlast
				bne.s	.nonextweap
				st		.heldlast

				moveq	#0,d0
				move.b	Plr1_GunSelected_b,d0
				move.l	#Plr1_Weapons_vb,a0


.findnext
				addq	#1,d0
				cmp.w	#9,d0
				ble.s	.okgun
				moveq	#0,d0
.okgun:
				tst.w	(a0,d0.w*2)
				beq.s	.findnext

				move.b	d0,Plr1_GunSelected_b
				jsr		SHOWPLR1GUNNAME

				bra		.nonextweap

.nonextweappre:
				clr.b	.heldlast
.nonextweap:


				rts

.heldlast:		dc.b	0
.ducklast:		dc.b	0

.Joystick

				move.l	#KeyMap_vb,a5
				move.l	#SinCosTable_vw,a0

				btst	#1,$dff00c
				sne		d0
				btst	#1,$dff00d
				sne		d1
				btst	#0,$dff00c
				sne		d2
				btst	#0,$dff00d
				sne		d3
				moveq	#0,d5
				move.b	fire_key,d5
				btst	#7,$bfe001
				seq		(a5,d5.w)

				move.b	turn_left_key,d5
				move.b	d0,(a5,d5.w)
				move.b	turn_right_key,d5
				move.b	d1,(a5,d5.w)
				eor.b	d0,d2
				move.b	forward_key,d5
				move.b	d2,(a5,d5.w)
				eor.b	d1,d3
				move.b	backward_key,d5
				move.b	d3,(a5,d5.w)
				rts

.Mouse
				rts




_ReadJoy2
				move.l	a6,-(a7)
				move.l	#1,d0
				move.l	_LowBase(pc),a6
				jsr		_LVOReadJoyPort(a6)

				move.l	(a7)+,a6
				move.l	d0,d1
;	and.l #$00FF000F,d0

				and.l	#JP_TYPE_MASK,d1
;
; bits in d1
;
;
				cmp.l	#JP_TYPE_NOTAVAIL,d1
				beq.b	.Empty

				cmp.l	#JP_TYPE_GAMECTLR,d1
				beq.b	.GameCtrl

				cmp.l	#JP_TYPE_MOUSE,d1
				beq		.Mouse

				cmp.l	#JP_TYPE_JOYSTK,d1
				beq		.Joystick

;	cmp.l	#JP_TYPE_UNKNOWN,d1
;
;
; type is an unknown type
;
.Empty
;
				rts
;
.GameCtrl

;	these are the bit defs..
;
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

				move.l	#KeyMap_vb,a5
				moveq	#0,d5
				move.b	forward_key,d5
				move.l	d0,d1
				and.l	#JPF_JOY_UP,d0
				sne		(a5,d5.w)
				move.b	backward_key,d5
				move.l	d1,d0
				and.l	#JPF_JOY_DOWN,d0
				sne		(a5,d5.w)
				move.b	turn_left_key,d5
				move.l	d1,d0
				and.l	#JPF_JOY_LEFT,d0
				sne		(a5,d5.w)
				move.b	turn_right_key,d5
				move.l	d1,d0
				and.l	#JPF_JOY_RIGHT,d0
				sne		(a5,d5.w)

				move.b	fire_key,d5
				move.l	d1,d0
				and.l	#JPF_BUTTON_GREEN,d0
				sne		(a5,d5.w)

				move.b	operate_key,d5
				move.l	d1,d0
				and.l	#JPF_BUTTON_YELLOW,d0
				sne		(a5,d5.w)

				move.b	run_key,d5
				move.l	d1,d0
				and.l	#JPF_BUTTON_RED,d0
				sne		(a5,d5.w)

				move.b	duck_key,d5
				move.l	d1,d0
				and.l	#JPF_BUTTON_BLUE,d0
				beq.s	.notduckbutpre
				tst.b	.ducklast
				bne.s	.notduckbut
				st		.ducklast
				st		(a5,d5.w)
				bra		.notduckbut
.notduckbutpre:
				clr.b	.ducklast
.notduckbut:


				move.b	jump_key,d5
				move.l	d1,d0
				and.l	#JPF_BUTTON_REVERSE,d0
				sne		(a5,d5.w)

				move.b	force_sidestep_key,d5
				move.l	d1,d0
				and.l	#JPF_BUTTON_FORWARD,d0
				sne		(a5,d5.w)

				move.l	d1,d0
				and.l	#JPF_BUTTON_PLAY,d0
				beq.s	.nonextweappre

				tst.b	PLR2_GunFrame
				bne.s	.nonextweappre

				tst.b	.heldlast
				bne.s	.nonextweap
				st		.heldlast

				moveq	#0,d0
				move.b	Plr2_GunSelected_b,d0
				move.l	#Plr2_Weapons_vb,a0

.findnext
				addq	#1,d0
				cmp.w	#9,d0
				ble.s	.okgun
				moveq	#0,d0
.okgun:
				tst.w	(a0,d0.w*2)
				beq.s	.findnext

				move.b	d0,Plr2_GunSelected_b
				jsr		SHOWPLR2GUNNAME

				bra		.nonextweap

.nonextweappre:
				clr.b	.heldlast
.nonextweap:


				rts

.heldlast:		dc.b	0
.ducklast:		dc.b	0

.Joystick

				move.l	#KeyMap_vb,a5
				move.l	#SinCosTable_vw,a0

				btst	#1,$dff00c
				sne		d0
				btst	#1,$dff00d
				sne		d1
				btst	#0,$dff00c
				sne		d2
				btst	#0,$dff00d
				sne		d3
				moveq	#0,d5
				move.b	fire_key,d5
				btst	#7,$bfe001
				seq		(a5,d5.w)

				move.b	turn_left_key,d5
				move.b	d0,(a5,d5.w)
				move.b	turn_right_key,d5
				move.b	d1,(a5,d5.w)
				eor.b	d0,d2
				move.b	forward_key,d5
				move.b	d2,(a5,d5.w)
				eor.b	d1,d3
				move.b	backward_key,d5
				move.b	d3,(a5,d5.w)
				rts

.Mouse
				rts


;BUTVALS
; dc.l JPF_BUTTON_BLUE         Blue - Stop
; dc.l JPF_BUTTON_RED          Red - Select
; dc.l JPF_BUTTON_YELLOW       Yellow - Repeat
; dc.l JPF_BUTTON_GREEN        Green - Shuffle
; dc.l JPF_BUTTON_FORWARD      Charcoal - Forward
; dc.l JPF_BUTTON_REVERSE      Charcoal - Reverse
; dc.l JPF_BUTTON_PLAY         Grey - Play/Pause
; dc.l JPF_JOY_UP              Up
; dc.l JPF_JOY_DOWN            Down
; dc.l JPF_JOY_LEFT            Left
; dc.l JPF_JOY_RIGHT           Right

_LowBase
				dc.l	0

_lowlevel
				dc.b	'lowlevel.library',0
				even

;	END

