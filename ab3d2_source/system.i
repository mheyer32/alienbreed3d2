
				output	/system.gs

				include	funcdef.i

				include	devices/inputevent.i
				include	devices/timer.i

				include	exec/io.i
				include	exec/libraries.i
				include	exec/lists.i
				include	exec/memory.i
				include	exec/nodes.i
				include	exec/ports.i
				include	exec/semaphores.i
				include	exec/tasks.i
				include	exec/types.i
				include exec/execbase.i

				include	graphics/clip.i
				include	graphics/copper.i
				include	graphics/gfx.i
				include	graphics/layers.i
				include	graphics/rastport.i
				include	graphics/text.i
				include graphics/videocontrol.i
				include	graphics/view.i

				include	hardware/blit.i
				include	hardware/cia.i
				include	hardware/custom.i
				include	hardware/dmabits.i
				include	hardware/intbits.i

				include	intuition/intuition.i
				include	intuition/intuitionbase.i
				include	intuition/preferences.i
				include	intuition/screens.i

				include	libraries/dos.i
				include	libraries/dosextens.i

				include	lvo/dos_lib.i
				include	lvo/exec_lib.i
				include	lvo/graphics_lib.i
				include	lvo/intuition_lib.i
				include	lvo/misc_lib.i
				include	lvo/potgo_lib.i

				include	resources/misc.i
				include	resources/potgo.i

				include	utility/tagitem.i

				include	workbench/startup.i

CALLEXEC		MACRO
				move.l	4.w,a6
				jsr		_LVO\1(a6)
				ENDM

CALLINT			MACRO
				move.l	_IntuitionBase,a6
				jsr		_LVO\1(a6)
				ENDM

INTNAME			MACRO
				dc.b	'intuition.library',0
				ENDM

CALLGRAF		MACRO
				move.l	_GfxBase,a6
				jsr		_LVO\1(a6)
				ENDM

GRAFNAME		MACRO
				dc.b	'graphics.library',0
				ENDM

CALLDOS			MACRO
				move.l	_DOSBase,a6
				jsr		_LVO\1(a6)
				ENDM

CALLMISC		MACRO
				move.l	_MiscResourceBase,a6
				jsr		_LVO\1(a6)
				ENDM

CALLPOTGO		MACRO
				move.l	_PotgoResourceBase,a6
				jsr		_LVO\1(a6)
				ENDM
