; ie_hal.s - Intuition Engine HAL core routines

	xdef ie_init
	xdef ie_wait_vblank
	xdef ie_poll_input
	xdef ie_present

ie_init:
	bsr	ie_input_init
	bsr	ie_audio_init
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
