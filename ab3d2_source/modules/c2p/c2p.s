;
; Main C2P entry points
;
;

				section .text,code

				align 4

FS_C2P_HEIGHT equ FS_HEIGHT-FS_HEIGHT_C2P_DIFF


; Main C2P Initialisation
	DCLC C2P_Init

				tst.b	Vid_FullScreenTemp_b
				beq.s	.small


				move.l	#c2p_SetParamsFull1x2Opt030,Vid_C2PSetParamsPtr_l
				move.l	#c2p_ConvertFull1x2Opt030,Vid_C2PConvertPtr_l
				bra.s	.done_size
.small:
				move.l	#c2p_SetParamsSmall1x2Opt030,Vid_C2PSetParamsPtr_l
				move.l	#c2p_ConvertSmall1x2Opt030,Vid_C2PConvertPtr_l

.done_size:
				st		C2P_NeedsSetParam_b
				clr.b	C2P_NeedsInit_b
				rts




; C2P Conversion
	DCLC C2P_Convert
				tst.b	C2P_NeedsInit_b
				beq.s	.no_init

				bsr		C2P_Init

.no_init:
				tst.b	C2P_NeedsSetParam_b
				beq.s	.no_set_param

				move.l	Vid_C2PSetParamsPtr_l,a0
				jsr	(a0)

				clr.b	C2P_NeedsSetParam_b

.no_set_param:
				move.l	Vid_C2PConvertPtr_l,a0
				jsr	(a0)
				rts

				include "modules/c2p/68030/c2p.s"

C2P_NeedsInit_b:		dc.b	1	; Options that need the whole C2P to be reinit should set this
C2P_NeedsSetParam_b:	dc.b	1	; Options that only need params resetting should set this

MODUL:			dc.w	0
HTC:			dc.w	0
WTC:			dc.w	0
SCRMOD:			dc.w	0
Game_TeleportFrame_w:			dc.w	0

SCREENPTRFLIG:	dc.l	0

STARTSHIM:		dc.l	0
