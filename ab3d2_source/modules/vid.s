
; *****************************************************************************
; *
; * modules/vid.s
; *
; *****************************************************************************

VID_BRIGHT_ADJ_STEP EQU 128
VID_BRIGHT_ADJ_MIN	EQU -4096
VID_BRIGHT_ADJ_MAX	EQU	5120


				align 4

;_C2P_Init::
;C2P_Init:
;				IFND OPT060
;				IFND OPT040
;
;				; Generic build
;				; Runtime detection which C2P routines to use
;				tst.b	Sys_Move16_b ; if set, we have an 040 or 060
;				beq.s	.use_030
;
;				; Opt for Kalm's 040/060 C2P routines
;				move.l	#c2p1x1_8_c5_040_init,Vid_C2PSetParamsPtr_l
;				move.l	#c2p1x1_8_c5_040,Vid_C2PConvertPtr_l
;				rts
;
;.use_030:
;				; Otherwise use the v2 030 C2P routine
;				move.l	#c2p1x1_8_c5_030_2_init,Vid_C2PSetParamsPtr_l
;				move.l	#c2p1x1_8_c5_030_2,Vid_C2PConvertPtr_l
;
;				ELSE ; OPT040
;				move.l	#c2p1x1_8_c5_040_init,Vid_C2PSetParamsPtr_l
;				move.l	#c2p1x1_8_c5_040,Vid_C2PConvertPtr_l
;				ENDC
;				ELSE ; OPT060
;				move.l	#c2p1x1_8_c5_040_init,Vid_C2PSetParamsPtr_l
;				move.l	#c2p1x1_8_c5_040,Vid_C2PConvertPtr_l
;				ENDC
;
;				rts

				;
; a5 contains keyboard state. No regs clobbered.
;
Vid_CheckSettingsAdjust:
				clr.b	Vid_UpdatePalette_b
; Brightness offset (black point)
.dec_bright_offset:
				tst.b	RAWKEY_NUM_1(a5)
				beq.s	.res_bright_offset

				clr.b	RAWKEY_NUM_1(a5)

				cmpi.w	#VID_BRIGHT_ADJ_MIN,Vid_BrightnessOffset_w
				ble		.skip_update_palette

				sub.w	#VID_BRIGHT_ADJ_STEP,Vid_BrightnessOffset_w
				bra		.update_palette

.res_bright_offset:
				tst.b	RAWKEY_NUM_2(a5)
				beq.s	.inc_bright_offset

				clr.b	RAWKEY_NUM_2(a5)
				clr.w	Vid_BrightnessOffset_w
				bra		.update_palette

.inc_bright_offset:
				tst.b	RAWKEY_NUM_3(a5)
				beq.s	.dec_contrast_adjust

				clr.b	RAWKEY_NUM_3(a5)
				cmpi.w	#VID_BRIGHT_ADJ_MAX,Vid_BrightnessOffset_w
				bge		.skip_update_palette

				add.w	#VID_BRIGHT_ADJ_STEP,Vid_BrightnessOffset_w
				bra		.update_palette

; Contrast
.dec_contrast_adjust:
				tst.b	RAWKEY_NUM_4(a5)
				beq		.res_contrast_adjust

				clr.b	RAWKEY_NUM_4(a5)
				cmpi.w	#VID_CONTRAST_ADJ_MIN,Vid_ContrastAdjust_w

				ble		.skip_update_palette

				sub.w	#VID_CONTRAST_ADJ_STEP,Vid_ContrastAdjust_w
				bra		.update_palette

.res_contrast_adjust:
				tst.b	RAWKEY_NUM_5(a5)
				beq.s	.inc_contrast_adjust

				clr.b	RAWKEY_NUM_5(a5)
				move.w	#VID_CONTRAST_ADJ_DEF,Vid_ContrastAdjust_w
				bra		.update_palette

.inc_contrast_adjust:
				tst.b	RAWKEY_NUM_6(a5)
				beq.s	.dec_gamma

				clr.b	RAWKEY_NUM_6(a5)

				cmpi.w	#VID_CONTRAST_ADJ_MAX,Vid_ContrastAdjust_w
				bge		.skip_update_palette

				add.w	#VID_CONTRAST_ADJ_STEP,Vid_ContrastAdjust_w
				bra		.update_palette

; Gamma
.dec_gamma:
				tst.b	RAWKEY_NUM_7(a5)
				beq.s	.res_gamma

				clr.b	RAWKEY_NUM_7(a5)

				tst.b	Vid_GammaLevel_b
				beq		.skip_update_palette

				sub.b	#1,Vid_GammaLevel_b
				bra.s	.update_palette

.res_gamma:
				tst.b	RAWKEY_NUM_8(a5)
				beq.s	.inc_gamma

				clr.b	RAWKEY_NUM_8(a5)
				clr.b	Vid_GammaLevel_b
				bra.s	.update_palette

.inc_gamma:
				tst.b	RAWKEY_NUM_9(a5)
				beq		.skip_update_palette

				clr.b	RAWKEY_NUM_9(a5)
				cmpi.b	#8,Vid_GammaLevel_b
				bge.s	.skip_update_palette

				add.b	#1,Vid_GammaLevel_b

.update_palette:
				st		Vid_UpdatePalette_b

.skip_update_palette:
				rts

