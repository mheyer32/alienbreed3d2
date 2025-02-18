;
; Main C2P entry points
;

C2P_FS_HEIGHT equ FS_HEIGHT-FS_HEIGHT_C2P_DIFF

; Regular C2P modes will only be 320x256 for now
C2P_BPL_WIDTH			equ SCREEN_WIDTH
C2P_BPL_HEIGHT			equ 256
C2P_BPL_ROWBYTES		equ (SCREEN_WIDTH/8)
C2P_BPL_SIZE			equ (C2P_BPL_ROWBYTES*C2P_BPL_HEIGHT)
C2P_BPL_SMALL_ROWBYTES	equ (SMALL_WIDTH/8)
C2P_SMALL_BPL_OFFSET	equ (C2P_BPL_ROWBYTES*20+(64/8))
C2P_SMALL_MOD_PIXELS	equ (SCREEN_WIDTH-SMALL_WIDTH)
C2P_SMALL_MOD_BYTES		equ (C2P_SMALL_MOD_PIXELS/8)
C2P_SMALL_WIDTH_LONGS	equ (SMALL_WIDTH/32)

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
c2p_SetParamsPtrs_vl:									; Akiko:030:Teleport
				dc.l	c2p_SetParams040Ptrs_vl			; 000
				dc.l	c2p_SetParamsTeleFxPtrs_vl		; 001
				IFD CPU_ALL
				dc.l	c2p_SetParams030Ptrs_vl			; 010
				dc.l	c2p_SetParamsTeleFxPtrs_vl		; 011
				dc.l	c2p_SetParamsAkikoPtrs_vl		; 100
				dc.l	c2p_SetParamsTeleFxPtrs_vl		; 101
				dc.l	c2p_SetParamsAkikoPtrs_vl		; 110
				dc.l	c2p_SetParamsTeleFxPtrs_vl		; 111
				ENDC

c2p_ConvertPtrs_vl:
				dc.l	c2p_Convert040Ptrs_vl			; 000
				dc.l	c2p_ConvertTeleFxPtrs_vl		; 001
				IFD CPU_ALL
				dc.l	c2p_Convert030Ptrs_vl			; 010
				dc.l	c2p_ConvertTeleFxPtrs_vl		; 011
				dc.l	c2p_ConvertAkikoPtrs_vl			; 100 ; Choosing Akiko > 040, lol
				dc.l	c2p_ConvertTeleFxPtrs_vl		; 101
				dc.l	c2p_ConvertAkikoPtrs_vl			; 110
				dc.l	c2p_ConvertTeleFxPtrs_vl		; 111
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
 				not.b	d0    ; We want to set the 030 flag, 040+ is default.
				and.b	#2,d0
				or.b	d0,d1

				move.b	Sys_C2P_Akiko_b,d0 ; Akiko detected
				and.b	C2P_UseAkiko_b,d0  ; Akiko preferred
				andi.b	#4,d0
				or.b	d0,d1

				ENDC

				IFD		DEV
				move.w	d1,C2P_Family_w ; debugging
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

				IFD		DEV
				move.w	d1,C2P_Mode_w ; debugging
				ENDC

				; d1 should now contain all the bits needed to select the variant
				move.l	(a0,d1.w*4),Vid_C2PSetParamsPtr_l
				move.l	(a1,d1.w*4),Vid_C2PConvertPtr_l
				st		C2P_NeedsSetParam_b
				clr.b	C2P_NeedsInit_b

				IFD DEV
				CALLC	C2P_DebugInit
				ENDC

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
				jsr		(a0)

				clr.b	C2P_NeedsSetParam_b

.no_set_param:
				move.l	Vid_C2PConvertPtr_l,a0
				jsr		(a0)
				rts

				IFD DEV
	DCLC C2P_Family_w
				dc.w	0
	DCLC C2P_Mode_w
				dc.w	0
				ENDC

c2p_ChunkyOffset_w:			dc.w	0 ; contains the offset into the chunky buffer to start at
c2p_PlanarOffset_w:			dc.w	0 ; contains the offset into the planar buffer to start at

	; These properties are manipulated via C preferences, so keep them in all builds.
	DCLC C2P_UseAkiko_b,	dc.b,	0
	DCLC C2P_AkikoMirror_b,	dc.b,	0
	DCLC C2P_AkikoCACR_b,	dc.b,	0

C2P_NeedsInit_b:
				dc.b	1	; Options that need the whole C2P to be reinit should set this
C2P_NeedsSetParam_b:
				dc.b	1	; Options that only need params resetting should set this
C2P_Teleporting_b:
				dc.b	0

				even
