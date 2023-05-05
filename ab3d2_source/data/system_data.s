			section .data,data

; Statically initialised (non-zero) data

			align 4
; Library and Resource Names
DosName:					DOSNAME
MiscResourceName:			MISCNAME
PotgoResourceName:			POTGONAME
IntuitionName:				INTNAME
GraphicsName:				GRAFNAME
TimerName:					dc.b	"timer.device",0

TempMessageBuffer_vb:		dcb.b	160,32

			align 4
sys_TimerFlag_l:			dc.l	-1

INTUITION_REV				EQU	31	;	v1.1
