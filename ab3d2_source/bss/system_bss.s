
			section .bss,bss

; BSS data - to be included in BSS section
			align 4

; System resource pointers

; There is a conundrum with DOSBase. If the linker sees that you're defining _DOSBase
; in your own code, it will take dos.library off the auto-lib list and thus
; not open DOSBase before it calls into ___initstdio. But ___initstdio is using DOS functions!
; We'll never have a chance to open dos.library, though, and thus the program crashes before
; reaching main()
; To workaround this, make it so that C build will add dos.library to the auto-open list by
; just referencing, but not providing _DOSBase

						IFD BUILD_WITH_C
							xref _DOSBase
						ELSE
_DOSBase:					ds.l	1
						ENDIF
_GfxBase::					ds.l	1
_IntuitionBase::			ds.l	1
_MiscResourceBase::			ds.l	1
_PotgoResourceBase::		ds.l	1
_TimerBase::				ds.l	1

; Chunk of statically allocated data for various calculations
_Sys_Workspace_vl::
Sys_Workspace_vl:			ds.l	8192

Sys_SerialBuffer_vl:		ds.l	2000

_sys_OldWindowPtr::
sys_OldWindowPtr:			ds.l	1

sys_RecoveryStack:			ds.l	1
sys_ErrorBuffer_vb:			ds.b	255
sys_ErrorHeight_b:			ds.w	1			; Also signals that an error occured
							align 4

; System FPS
; Keep this pair together
_Sys_FrameTimeECV_q::
Sys_FrameTimeECV_q:			ds.l	2			; EClock of Lap
_Sys_PrevFrameTimeECV_q::
Sys_PrevFrameTimeECV_q:		ds.l	2			; EClock of last Lap

_Sys_FrameTimes_vl::
Sys_FrameTimes_vl:			ds.l	8			; last 8 frame times, in ms
_Sys_FrameNumber_l::
Sys_FrameNumber_l:			ds.l	1			; monotonically increasing frame number
_Sys_ECVToMsFactor_l::
Sys_ECVToMsFactor_l:		ds.l	1   		; factor for converting EClock value differences to ms

; Keep this pair together together
_Sys_FPSIntAvg_w::
Sys_FPSIntAvg_w:			ds.w	1
_Sys_FPSFracAvg_w::
Sys_FPSFracAvg_w:			ds.w	1


_sys_TimerRequest::
sys_TimerRequest:			ds.b	IOTV_SIZE	; TimeRequest structure

			align 4
_Sys_Move16_b::
Sys_Move16_b:				ds.b	1 			; Set if we have move16 available (060. 040)
Sys_FPU_b:					ds.b	1 			; Set if we have FPU available
_Sys_CPU_68060_b::
Sys_CPU_68060_b:			ds.b	1			; set if we have a 68060 specifically
