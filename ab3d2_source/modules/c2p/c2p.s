;
; Main C2P entry points
;

FS_C2P_HEIGHT equ FS_HEIGHT-FS_HEIGHT_C2P_DIFF

				IFND OPT060
				IFND OPT040
CPU_ALL
				ENDC
				ENDC

				IFD CPU_ALL
				include "modules/c2p/68030/routines.s"
				include "modules/c2p/akiko/routines.s"
				ENDC

				include "modules/c2p/68040/routines.s"
				include "modules/c2p/teleport_fx/routines.s"

				section .data,data
				align 4

				; Table Pointer Table...
c2p_SetParamsPtrs_vl:								; Akiko:030:Teleport
				dc.l c2p_SetParams040Ptrs_vl		; 000
				dc.l c2p_SetParamsTeleFxPtrs_vl		; 001
				IFD CPU_ALL
				dc.l c2p_SetParams030Ptrs_vl		; 010
				dc.l c2p_SetParamsTeleFxPtrs_vl		; 011
				dc.l c2p_SetParamsAkikoPtrs_vl		; 100
				dc.l c2p_SetParamsTeleFxPtrs_vl		; 101
				dc.l c2p_SetParamsAkikoPtrs_vl		; 110
				dc.l c2p_SetParamsTeleFxPtrs_vl		; 111
				ENDC

c2p_ConvertPtrs_vl:
				dc.l c2p_Convert040Ptrs_vl			; 000
				dc.l c2p_ConvertTeleFxPtrs_vl		; 001
				IFD CPU_ALL
				dc.l c2p_Convert030Ptrs_vl			; 010
				dc.l c2p_ConvertTeleFxPtrs_vl		; 011
				dc.l c2p_ConvertAkikoPtrs_vl		; 100 ; Choosing Akiko > 040, lol
				dc.l c2p_ConvertTeleFxPtrs_vl		; 101
				dc.l c2p_ConvertAkikoPtrs_vl		; 110
				dc.l c2p_ConvertTeleFxPtrs_vl		; 111
				ENDC

				section .text,code
				align 4

c2p_SetParamsNull:
c2p_ConvertNull:
				rts

; Main C2P Initialisation
	DCLC C2P_Init
				moveq	#0,d1

				; Check if we are teleporting
				move.b	C2P_Teleporting_b,d1
				andi.b	#1,d1

				IFD CPU_ALL

				; CPU Class
				move.b	Sys_Move16_b,d0
; 				not.b	d0    ; We want to set the 030 flag, 040 is default.
				and.b	#2,d0
				or.b	d0,d1

				;TODO - Akiko
				;move.b Sys_HaveAkiko,d0
				;andi.b	#4.d0
				;or.b	d0,d1

				ENDC

				; d1 now contains the index for the device tuned code
				; TODO - get pointer. Is a1 OK?

				move.l	#c2p_SetParamsPtrs_vl,a0
				move.l	#c2p_ConvertPtrs_vl,a1
				move.l	(a0,d1.w*4),a0 ; a0 now points at device tuned SetParams table
				move.l	(a1,d1.w*4),a1 ; a1 now points at device tuned Convert table

				move.b	Vid_DoubleHeight_b,d1
				andi.b	#1,d1
				move.b	Vid_DoubleWidth_b,d0
				andi.b	#2,d0
				or.b	d0,d1
				move.b	Vid_FullScreenTemp_b,d0
				andi.b	#4,d0
				or.b	d0,d1

				; d1 should now contain all the bits needed to select the variant
				move.l	(a0,d1.w*4),Vid_C2PSetParamsPtr_l
				move.l	(a1,d1.w*4),Vid_C2PConvertPtr_l
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

C2P_NeedsInit_b:
				dc.b	1	; Options that need the whole C2P to be reinit should set this
C2P_NeedsSetParam_b:
				dc.b	1	; Options that only need params resetting should set this
C2P_Teleporting_b:
				dc.b	0

