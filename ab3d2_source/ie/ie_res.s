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
	xdef ie_res_load_sfx_table
	xdef _ie_res_load_sfx_table
	xdef ie_res_load_sfx_table_ex
	xdef _ie_res_load_sfx_table_ex
	xdef ie_res_load_sfx_table_60
	xdef _ie_res_load_sfx_table_60
	xdef ie_res_set_sfx_filename_table
	xdef _ie_res_set_sfx_filename_table
	xdef Res_LoadSoundFx
	xdef _Res_LoadSoundFx
	xdef Res_PatchSoundFx
	xdef _Res_PatchSoundFx
	xdef Res_FreeSoundFx
	xdef _Res_FreeSoundFx

RES_NUM_SFX	equ	59

; Initialize resource helper state.
ie_res_init:
_ie_res_init:
	bsr		IO_InitQueue
	bsr		ie_sfx_clear_samples
	clr.l	ie_res_sfx_filename_table_ptr
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

; Configure external SFX filename table pointer used by Res_LoadSoundFx.
; in: a0 -> first entry (AB3D2 GLFT_SFXFilenames layout, 60-byte stride)
ie_res_set_sfx_filename_table:
_ie_res_set_sfx_filename_table:
	move.l	a0,ie_res_sfx_filename_table_ptr
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

; Batch-load SFX table with explicit entry stride.
; in:
;   a0 = pointer to first filename entry (fixed-width entries)
;   d0 = entry count
;   d1 = destination sample index start
;   d2 = entry stride in bytes (<=0 -> defaults to 64)
; out:
;   d0 = number of successfully loaded entries
ie_res_load_sfx_table_ex:
_ie_res_load_sfx_table_ex:
	move.l	a0,a2				; current filename entry ptr
	move.l	d0,d6				; remaining entries
	move.l	d1,d7				; current sample index
	move.l	d2,d4				; entry stride
	moveq	#0,d5				; success counter
	tst.l	d4
	bgt.s	.stride_ok
	moveq	#64,d4
.stride_ok:
	tst.l	d6
	ble		.done_tbl

.loop_tbl:
	; Skip empty filename slots.
	tst.b	(a2)
	beq		.next_tbl

	move.l	d7,d0
	move.l	a2,a0
	bsr		ie_res_load_sfx_file
	tst.l	d0
	beq		.next_tbl
	addq.l	#1,d5

.next_tbl:
	adda.l	d4,a2
	addq.l	#1,d7
	subq.l	#1,d6
	bgt		.loop_tbl

.done_tbl:
	move.l	d5,d0
	rts

; Backward-compatible wrapper for the original API used in this port layer.
; Uses 64-byte filename entries.
ie_res_load_sfx_table:
_ie_res_load_sfx_table:
	moveq	#64,d2
	bsr		ie_res_load_sfx_table_ex
	rts

; AB3D2 GLF table wrapper.
; Uses 60-byte filename entries (GLFT_SFXFilenames layout).
ie_res_load_sfx_table_60:
_ie_res_load_sfx_table_60:
	moveq	#60,d2
	bsr		ie_res_load_sfx_table_ex
	rts

; Legacy AB3D2 resource compatibility entrypoints.
; These are no-op safe until ie_res_set_sfx_filename_table is called.
Res_LoadSoundFx:
_Res_LoadSoundFx:
	move.l	ie_res_sfx_filename_table_ptr,a0
	tst.l	a0
	beq.s	.no_table
	moveq	#RES_NUM_SFX,d0
	moveq	#0,d1
	bsr		ie_res_load_sfx_table_60
	rts
.no_table:
	moveq	#0,d0
	rts

; Convert loaded SFX table from {ptr,len} to {ptr,end_ptr} in place.
Res_PatchSoundFx:
_Res_PatchSoundFx:
	move.w	#RES_NUM_SFX-1,d7
	lea		Aud_SampleList_vl,a1
.patch_loop:
	move.l	(a1)+,d0
	add.l	d0,(a1)+
	dbra	d7,.patch_loop
	rts

; IE static-heap model has no per-sample free. Clear table entries instead.
Res_FreeSoundFx:
_Res_FreeSoundFx:
	bsr		ie_sfx_clear_samples
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

ie_res_sfx_filename_table_ptr:
	dc.l	0
