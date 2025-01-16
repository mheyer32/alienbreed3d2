;
; Main C2P entry points
;


FS_C2P_HEIGHT equ FS_HEIGHT-FS_HEIGHT_C2P_DIFF

; Table structure for C2P callbacks

; Bit#   3                2                   1                  0
; < 040+ / 030 > | < Full / Small > | < Double Width > | < Double Height >

				section .data,data
				align 4

c2p_SetParamsPtrs_vl:
				; Only include 030 code for the generic target
				IFND OPT060
				IFND OPT040

				dc.l	c2p_SetParamsSmall1x1Opt030		; 0000
				dc.l	c2p_SetParamsSmall1x2Opt030		; 0001
				dc.l	c2p_SetParamsNull				; 0010
				dc.l	c2p_SetParamsNull				; 0011
				dc.l	c2p_SetParamsFull1x1Opt030		; 0100
				dc.l	c2p_SetParamsFull1x2Opt030		; 0101
				dc.l	c2p_SetParamsNull				; 0110
				dc.l	c2p_SetParamsNull				; 0111

				ENDC
				ENDC

				dc.l	c2p_SetParamsSmall1x1Opt040		; 1000
				dc.l	c2p_SetParamsSmall1x2Opt040		; 1001
				dc.l	c2p_SetParamsNull				; 1010
				dc.l	c2p_SetParamsNull				; 1011
				dc.l	c2p_SetParamsFull1x1Opt040		; 1100
				dc.l	c2p_SetParamsFull1x2Opt040		; 1101
				dc.l	c2p_SetParamsNull				; 1110
				dc.l	c2p_SetParamsNull				; 1111

c2p_ConvertPtrs_vl:
				IFND OPT060
				IFND OPT040

				; Only include 030 code for the generic target
				dc.l	c2p_ConvertSmall1x1Opt030		; 0000
				dc.l	c2p_ConvertSmall1x2Opt030		; 0001
				dc.l	c2p_ConvertNull					; 0010
				dc.l	c2p_ConvertNull					; 0011
				dc.l	c2p_ConvertFull1x1Opt030		; 0100
				dc.l	c2p_ConvertFull1x2Opt030		; 0101
				dc.l	c2p_ConvertNull					; 0110
				dc.l	c2p_ConvertNull					; 0111

				ENDC
				ENDC

				dc.l	c2p_ConvertSmall1x1Opt040		; 1000
				dc.l	c2p_ConvertSmall1x2Opt040		; 1001
				dc.l	c2p_ConvertNull					; 1010
				dc.l	c2p_ConvertNull					; 1011
				dc.l	c2p_ConvertFull1x1Opt040		; 1100
				dc.l	c2p_ConvertFull1x2Opt040		; 1101
				dc.l	c2p_ConvertNull					; 1110
				dc.l	c2p_ConvertNull					; 1111

				section .text,code

c2p_SetParamsNull:
c2p_ConvertNull:
				rts


; Main C2P Initialisation
	DCLC C2P_Init
				moveq	#0,d1
				move.b	Vid_DoubleHeight_b,d1
				andi.b	#1,d1
				move.b	Vid_DoubleWidth_b,d0
				andi.b	#2,d0
				or.b	d0,d1
				move.b	Vid_FullScreenTemp_b,d0
				andi.b	#4,d0
				or.b	d0,d1

				; Only perform CPU check in the generic target, else use 040+ always
				IFND OPT060
				IFND OPT040

				move.b	Sys_Move16_b,d0
				andi.b	#8,d0
				or.b	d0,d1

				ENDC
				ENDC

				; d1 should now contain all the bits needed to select the variant
				move.l	#c2p_SetParamsPtrs_vl,a0
				move.l	(a0,d1.w*4),Vid_C2PSetParamsPtr_l
				move.l	#c2p_ConvertPtrs_vl,a0
				move.l	(a0,d1.w*4),Vid_C2PConvertPtr_l
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

				IFND OPT060
				IFND OPT040

				include "modules/c2p/68030/c2p.s"

				ENDC
				ENDC

				include "modules/c2p/68040/c2p.s"

C2P_NeedsInit_b:
				dc.b	1	; Options that need the whole C2P to be reinit should set this
C2P_NeedsSetParam_b:
				dc.b	1	; Options that only need params resetting should set this

MODUL:			dc.w	0
HTC:			dc.w	0
WTC:			dc.w	0
SCRMOD:			dc.w	0

Game_TeleportFrame_w:
				dc.w	0

SCREENPTRFLIG:	dc.l	0

STARTSHIM:		dc.l	0
