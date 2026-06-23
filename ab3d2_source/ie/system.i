
				output	/system.gs

				include	funcdef.i
				include	"ie/ie_system.i"

CALLEXEC		MACRO
				move.l	#FAKE_LIB_BASE,a6
				jsr		_LVO\1(a6)
				ENDM

CALLINT			MACRO
				move.l	#FAKE_LIB_BASE,a6
				jsr		_LVO\1(a6)
				ENDM

INTNAME			MACRO
				dc.b	'intuition.library',0
				ENDM

CALLGRAF		MACRO
				move.l	#FAKE_LIB_BASE,a6
				jsr		_LVO\1(a6)
				ENDM

GRAFNAME		MACRO
				dc.b	'graphics.library',0
				ENDM

DOSNAME			MACRO
				dc.b	'dos.library',0
				ENDM

MISCNAME		MACRO
				dc.b	'misc.resource',0
				ENDM

POTGONAME		MACRO
				dc.b	'potgo.resource',0
				ENDM

CALLDOS			MACRO
				move.l	#FAKE_LIB_BASE,a6
				jsr		_LVO\1(a6)
				ENDM

CALLMISC		MACRO
				move.l	#FAKE_LIB_BASE,a6
				jsr		_LVO\1(a6)
				ENDM

CALLPOTGO		MACRO
				move.l	#FAKE_LIB_BASE,a6
				jsr		_LVO\1(a6)
				ENDM
