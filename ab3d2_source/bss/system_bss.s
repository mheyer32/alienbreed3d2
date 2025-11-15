
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

							xref _DOSBase
_GfxBase::					ds.l	1
_IntuitionBase::			ds.l	1
_MiscBase::                 ds.l	1
_PotgoBase::                ds.l	1
_TimerBase::				ds.l	1

; Chunks of statically allocated data for various calculations
		DCLC Sys_Workspace_vl,			ds.l,	8192
		DCLC Sys_SerialBuffer_vl,		ds.l,	2000
		DCLC sys_OldWindowPtr,			ds.l,	1

sys_RecoveryStack:						ds.l	1
sys_ErrorBuffer_vb:						ds.b	256 ; 255
sys_ErrorHeight_b:						ds.w	1			; Also signals that an error occured


; System FPS
			align 4

; Keep this pair together
		DCLC Sys_FrameTimeECV_q,		ds.l,	2		; EClock of Lap
		DCLC Sys_PrevFrameTimeECV_q,	ds.l,	2		; EClock of last Lap

		DCLC Sys_FrameTimes_vl,			ds.l,	8		; last 8 frame times, in ms
		DCLC Sys_FrameNumber_l,			ds.l,	1		; monotonically increasing frame number
		DCLC Sys_ECVToMsFactor_l,		ds.l,	1   	; factor for converting EClock value differences to ms

; Keep these values together
		DCLC Sys_FPSIntAvg_w,			ds.w,	1
		DCLC Sys_FPSFracAvg_w,			ds.w,	1
		DCLC Sys_FPSLimit_w,			ds.w,	1

			align 4
		DCLC sys_TimerRequest,			ds.b,	IOTV_SIZE	; TimeRequest structure

		DCLC Sys_Move16_b,				ds.b,	1 		; Set if we have move16 available (060. 040)
		DCLC Sys_FPU_b,					ds.b,	1 		; Set if we have FPU available
		DCLC Sys_CPU_68060_b,			ds.b,	1		; Set if we have a 68060 specifically
		DCLC Sys_C2P_Akiko_b,			ds.b,	1		; Set if we have Akiko available
		DCLC Sys_CPU_68030_b,			ds.b,	1		; Set if we have 68030 specifically

			align 4

