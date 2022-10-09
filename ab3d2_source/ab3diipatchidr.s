;Patch to cancel any Error Report from DOS
; FIXME: this causes us to open intuition.library twice
FuncToPatch		equ		_LVOEasyRequestArgs
MakePatch:
				move.l	#IntuiName,a1
				move.l	#36,d0
				CALLEXEC OpenLibrary
				move.l	d0,IntuiBase
				beq.s	IntuiError

				move.l	IntuiBase,a1
				move.l	#FuncToPatch,a0
				move.l	#NewFunction,d0
				jsr		_LVOSetFunction(a6)

IntuiError:
				rts

NewFunction:
				move.l	#0,d0
				rts

IntuiBase:		dc.l	0
IntuiName:		dc.b	"intuition.library",0
				even
