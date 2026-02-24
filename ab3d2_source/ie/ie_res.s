; ie_res.s - Intuition Engine resource helper routines
;
; These helpers provide a thin bridge between file I/O compatibility
; entrypoints and IE palette/SFX registration APIs.

	xdef ie_res_init
	xdef _ie_res_init
	xdef ie_res_load_palette_file
	xdef _ie_res_load_palette_file
	xdef ie_res_load_sfx_file
	xdef _ie_res_load_sfx_file

; Initialize resource helper state.
ie_res_init:
_ie_res_init:
	bsr		IO_InitQueue
	bsr		ie_sfx_clear_samples
	rts

; Load RGB8 palette file and set as active texture palette source.
; in: a0 -> filename
; out: d0 = 1 on success, 0 on failure
ie_res_load_palette_file:
_ie_res_load_palette_file:
	bsr		IO_LoadFileOptional
	tst.l	d0
	beq.s	.fail
	move.l	d0,a0
	bsr		ie_palette_set_texture_ptr
	moveq	#1,d0
	rts
.fail:
	moveq	#0,d0
	rts

; Load SFX sample file and register into Aud_SampleList_vl slot.
; in: d0 = sample index (0..63), a0 -> filename
; out: d0 = 1 on success, 0 on failure
ie_res_load_sfx_file:
_ie_res_load_sfx_file:
	move.l	d0,d4
	bsr		IO_LoadFileOptional	; d0=ptr, d1=len
	tst.l	d0
	beq.s	.fail_sfx
	move.l	d0,d2				; ptr
	move.l	d1,d3				; len
	move.l	d4,d0				; sample index
	move.l	d2,d1				; ptr
	move.l	d3,d2				; len
	bsr		ie_sfx_set_sample
	moveq	#1,d0
	rts
.fail_sfx:
	moveq	#0,d0
	rts
