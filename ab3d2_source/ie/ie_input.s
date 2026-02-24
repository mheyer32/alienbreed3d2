; ie_input.s - Intuition Engine input bridge

	xdef ie_input_init
	xdef ie_poll_keyboard
	xdef ie_poll_mouse
	xdef ie_keymap
	xdef ie_mouse_dx
	xdef ie_mouse_dy
	xdef ie_mouse_buttons
	xdef ie_mouse_relative_ok

ie_input_init:
	; Enable relative mouse mode for FPS look.
	move.l	#1,$F074C
	move.l	$F074C,d0
	cmpi.l	#1,d0
	beq.s	.rel_ok
	clr.l	ie_mouse_relative_ok
	move.l	$F0730,ie_mouse_last_abs_x
	move.l	$F0734,ie_mouse_last_abs_y
	bra.s	.init_done
.rel_ok:
	move.l	#1,ie_mouse_relative_ok
.init_done:
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
	tst.l	ie_mouse_relative_ok
	beq.s	.abs_mode
	move.l	$F0730,d0
	move.l	$F0734,d1
	bra.s	.store_mouse

.abs_mode:
	move.l	$F0730,d4
	move.l	$F0734,d5
	move.l	d4,d0
	sub.l	ie_mouse_last_abs_x,d0
	move.l	d5,d1
	sub.l	ie_mouse_last_abs_y,d1
	move.l	d4,ie_mouse_last_abs_x
	move.l	d5,ie_mouse_last_abs_y

.store_mouse:
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
ie_mouse_relative_ok:
	dc.l	0
ie_mouse_last_abs_x:
	dc.l	0
ie_mouse_last_abs_y:
	dc.l	0
