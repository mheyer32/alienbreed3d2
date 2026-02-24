; ie_res.s - Intuition Engine resource helper routines
;
; These helpers provide a thin bridge between file I/O compatibility
; entrypoints and IE palette/SFX/MOD registration APIs.

	xdef ie_res_init
	xdef _ie_res_init
	xdef ie_res_bootstrap_assets
	xdef _ie_res_bootstrap_assets
	xdef ie_res_load_palette_file
	xdef _ie_res_load_palette_file
	xdef ie_res_load_mod_file
	xdef _ie_res_load_mod_file
	xdef ie_res_load_sfx_file
	xdef _ie_res_load_sfx_file

; Initialize resource helper state.
ie_res_init:
_ie_res_init:
	bsr		IO_InitQueue
	bsr		ie_sfx_clear_samples
	rts

; Attempt a larger default bootstrap pass so IE bring-up has real assets
; without requiring manual calls from game code.
ie_res_bootstrap_assets:
_ie_res_bootstrap_assets:
	; 1) Palette: try known candidate names.
	lea		ie_palette_candidates,a0
	bsr		ie_res_try_palette_candidates

	; 2) MOD music: optional, starts playback if load succeeds.
	lea		ie_mod_candidates,a0
	bsr		ie_res_try_mod_candidates
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

; Load MOD file and start playback.
; in: a0 -> filename
; out: d0 = 1 on success, 0 on failure
ie_res_load_mod_file:
_ie_res_load_mod_file:
	bsr		IO_LoadFileOptional	; d0=ptr, d1=len
	tst.l	d0
	beq.s	.mod_fail
	bsr		ie_mod_set_data		; uses d0=ptr, d1=len
	bsr		mt_init
	moveq	#1,d0
	rts
.mod_fail:
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

; Candidate walker helpers
; in: a0 -> table of long pointers to C-strings, terminated by 0
ie_res_try_palette_candidates:
	move.l	a0,a2
.next_pal:
	move.l	(a2)+,a1
	beq.s	.done_pal
	move.l	a1,a0
	bsr		ie_res_load_palette_file
	tst.l	d0
	beq.s	.next_pal
	moveq	#1,d0
	rts
.done_pal:
	moveq	#0,d0
	rts

ie_res_try_mod_candidates:
	move.l	a0,a2
.next_mod:
	move.l	(a2)+,a1
	beq.s	.done_mod
	move.l	a1,a0
	bsr		ie_res_load_mod_file
	tst.l	d0
	beq.s	.next_mod
	moveq	#1,d0
	rts
.done_mod:
	moveq	#0,d0
	rts

; Default asset candidates (all optional).
ie_palette_candidates:
	dc.l	ie_pal_name0
	dc.l	ie_pal_name1
	dc.l	ie_pal_name2
	dc.l	0

ie_mod_candidates:
	dc.l	ie_mod_name0
	dc.l	ie_mod_name1
	dc.l	ie_mod_name2
	dc.l	0

ie_pal_name0:
	dc.b	"AB3:Includes/main.256pal",0
ie_pal_name1:
	dc.b	"includes/main.256pal",0
ie_pal_name2:
	dc.b	"main.256pal",0
	even

ie_mod_name0:
	dc.b	"AB3:Includes/title.mod",0
ie_mod_name1:
	dc.b	"includes/title.mod",0
ie_mod_name2:
	dc.b	"title.mod",0
	even
