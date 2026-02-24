; ie_input.s - Intuition Engine input bridge

	xdef ie_input_init
	xdef ie_poll_keyboard
	xdef ie_poll_mouse
	xdef ie_keymap
	xdef ie_mouse_dx
	xdef ie_mouse_dy
	xdef ie_mouse_buttons

ie_input_init:
	; Enable relative mouse mode for FPS look.
	move.l	#1,$F074C
	clr.l	ie_mouse_dx
	clr.l	ie_mouse_dy
	clr.l	ie_mouse_buttons
	rts

ie_poll_keyboard:
	lea	ie_keymap,a0
.drain:
	move.l	$F0744,d0
	andi.l	#1,d0
	beq.s	.done

	move.l	$F0740,d0
	move.l	d0,d1
	andi.l	#$7F,d1
	btst	#7,d0
	bne.s	.release
	move.b	#$FF,0(a0,d1.w)
	bra.s	.drain
.release:
	clr.b	0(a0,d1.w)
	bra.s	.drain
.done:
	rts

ie_poll_mouse:
	move.l	$F0730,d0
	move.l	$F0734,d1
	move.l	$F0738,d2
	move.l	d0,ie_mouse_dx
	move.l	d1,ie_mouse_dy
	move.l	d2,ie_mouse_buttons
	rts

ie_keymap:
	dcb.b	256,0

ie_mouse_dx:
	dc.l	0
ie_mouse_dy:
	dc.l	0
ie_mouse_buttons:
	dc.l	0
