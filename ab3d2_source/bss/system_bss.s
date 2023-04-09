
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

sys_ECVToMsFactor_l:		ds.l	1   		; factor for converting EClock value differences to ms
sys_TimerRequest:			ds.b	IOTV_SIZE	; TimeRequest structure

			align 4
Sys_Move16_b:				ds.b	1 			; Set if we have move16 available
Sys_FPU_b:					ds.b	1 			; Set if we have FPU available

