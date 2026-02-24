; ie_input.s - Intuition Engine input bridge

	xdef ie_input_init
	xdef ie_poll_keyboard
	xdef ie_poll_mouse
	xdef Sys_ReadMouse
	xdef _Sys_ReadMouse
	xdef Sys_ClearKeyboard
	xdef _Sys_ClearKeyboard
	xdef Sys_MouseY
	xdef ie_keymap
	xdef KeyMap_vb
	xdef ie_mouse_dx
	xdef ie_mouse_dy
	xdef ie_mouse_buttons
	xdef ie_mouse_relative_ok

ie_input_init:
	bsr	ie_init_scancode_map

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

	; Clear key state map.
	lea	KeyMap_vb,a0
	move.w	#255,d0
.clear_keys:
	clr.b	(a0)+
	dbra	d0,.clear_keys
	rts

ie_poll_keyboard:
	lea	ie_keymap,a0
	lea	ie_scancode_to_rawkey,a1
.drain:
	move.l	$F0744,d0
	andi.l	#1,d0
	beq.s	.done

	move.l	$F0740,d0
	move.l	d0,d1
	andi.l	#$7F,d1
	moveq	#0,d2
	move.b	0(a1,d1.w),d2
	; 0xFF in map means "ignore this scancode".
	cmpi.b	#$FF,d2
	beq.s	.drain
	btst	#7,d0
	bne.s	.release
	move.b	#$FF,0(a0,d2.w)
	bra.s	.drain
.release:
	clr.b	0(a0,d2.w)
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

; Compatibility shim for existing game control code.
; Updates Sys_MouseY as an accumulated axis from IE mouse deltas.
Sys_ReadMouse:
_Sys_ReadMouse:
	bsr	ie_poll_mouse
	move.w	ie_mouse_dy,d0
	add.w	d0,Sys_MouseY
	rts

Sys_ClearKeyboard:
_Sys_ClearKeyboard:
	lea	KeyMap_vb,a0
	move.w	#255,d0
.clear_loop:
	clr.b	(a0)+
	dbra	d0,.clear_loop
	rts

ie_keymap:
KeyMap_vb:
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

Sys_MouseY:
	dc.w	0

; Initialize scancode->RAWKEY map.
; Default is identity (ST set mostly matches RAWKEY indices), with optional
; per-key overrides patched after the identity pass.
ie_init_scancode_map:
	lea	ie_scancode_to_rawkey,a0
	moveq	#0,d0
	move.w	#127,d7
.id_loop:
	move.b	d0,(a0)+
	addq.b	#1,d0
	dbra	d7,.id_loop

	; Example override slots (expand as differences are identified):
	; unmapped/ignored example:
	; move.b #$FF,ie_scancode_to_rawkey+<scan>

	rts

ie_scancode_to_rawkey:
	dcb.b	128,0
