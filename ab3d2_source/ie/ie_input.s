; ie_input.s - Intuition Engine input bridge stubs (WIP)

	xdef ie_input_init
	xdef ie_poll_keyboard
	xdef ie_poll_mouse

ie_input_init:
	; TODO: enable relative mouse mode via MOUSE_RELATIVE_MODE (0xF074C)
	rts

ie_poll_keyboard:
	; TODO: drain SCAN_STATUS/SCAN_CODE queue and update KeyMap_vb
	rts

ie_poll_mouse:
	; TODO: read MOUSE_X/Y deltas and button state
	rts
