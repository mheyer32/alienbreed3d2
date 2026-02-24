; ie_hal.s - Intuition Engine HAL core routines

	xdef ie_init
	xdef ie_wait_vblank
	xdef ie_poll_input
	xdef ie_present
	xdef Vid_Present
	xdef _Vid_Present
	xdef Vid_OpenMainScreen
	xdef _Vid_OpenMainScreen
	xdef Vid_CloseMainScreen
	xdef _Vid_CloseMainScreen
	xdef Sys_WaitVBL
	xdef _Sys_WaitVBL
	xdef Sys_EvalFPS
	xdef _Sys_EvalFPS
	xdef Sys_FrameLap
	xdef _Sys_FrameLap
	xdef _InitLowLevel
	xdef __InitLowLevel
	xdef _CloseLowLevel
	xdef __CloseLowLevel

ie_init:
	bsr	ie_palette_init
	bsr	ie_input_init
	bsr	ie_audio_init
	bsr	ie_res_init
	bsr	ie_res_bootstrap_assets
	rts

ie_wait_vblank:
	; Wait until beam is active (not in vblank).
.wait_not_vblank:
	move.l	$F0008,d0
	andi.l	#2,d0
	bne.s	.wait_not_vblank
	; Wait for start of next vblank.
.wait_vblank:
	move.l	$F0008,d0
	andi.l	#2,d0
	beq.s	.wait_vblank
	rts

ie_poll_input:
	bsr	ie_poll_keyboard
	bsr	ie_poll_mouse
	rts

ie_present:
	bsr	ie_present_frame
	rts

; Legacy-compatible entrypoints used by existing game code.
Vid_Present:
_Vid_Present:
	bsr	ie_present_frame
	rts

Vid_OpenMainScreen:
_Vid_OpenMainScreen:
	; Ensure video path is enabled and in 640x480 mode.
	move.l	#1,$F0000
	move.l	#0,$F0004
	moveq	#1,d0
	rts

Vid_CloseMainScreen:
_Vid_CloseMainScreen:
	; Keep MMIO state simple for now: disable video output.
	move.l	#0,$F0000
	rts

Sys_WaitVBL:
_Sys_WaitVBL:
	bsr	ie_wait_vblank
	rts

; FPS accounting is emulator-side for now.
Sys_EvalFPS:
_Sys_EvalFPS:
	rts

Sys_FrameLap:
_Sys_FrameLap:
	rts

_InitLowLevel:
__InitLowLevel:
	rts

_CloseLowLevel:
__CloseLowLevel:
	rts
