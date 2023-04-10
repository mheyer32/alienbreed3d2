
			section bss,bss

; BSS data - to be included in BSS section
			align 4

; System resource pointers
_DOSBase:					ds.l	1
_GfxBase:					ds.l	1
_IntuitionBase:				ds.l	1
_MiscResourceBase:			ds.l	1
_PotgoResourceBase:			ds.l	1
_TimerBase:					ds.l	1

; Chunk of statically allocated data for various calculations
Sys_Workspace_vl:			ds.l	8192

Sys_SerialBuffer_vl:		ds.l	2000

; System FPS
; Keep this pair together
Sys_FrameTimeECV_q:			ds.l	2			; EClock of Lap
Sys_PrevFrameTimeECV_q:		ds.l	2			; EClock of last Lap

Sys_FrameTimes_vl:			ds.l	8			; last 8 frame times, in ms
Sys_FrameNumber_l:			ds.l	1			; monotonically increasing frame number
Sys_ECVToMsFactor_l:		ds.l	1   		; factor for converting EClock value differences to ms

; Keep this pair together together
Sys_FPSIntAvg_w:			ds.w	1
Sys_FPSFracAvg_w:			ds.w	1


sys_TimerRequest:			ds.b	IOTV_SIZE	; TimeRequest structure

			align 4
Sys_Move16_b:				ds.b	1 			; Set if we have move16 available
Sys_FPU_b:					ds.b	1 			; Set if we have FPU available

