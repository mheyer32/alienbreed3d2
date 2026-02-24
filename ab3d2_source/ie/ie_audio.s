; ie_audio.s - Intuition Engine audio bridge
; Calling convention (current WIP):
;   ie_mod_start: d0=mod_ptr, d1=mod_len, d2=ctrl (0 => start)
;   ie_play_sfx:  d0=sfx_ptr, d1=sfx_len, d2=ctrl (0 => start), d3=channel 0-3

	xdef ie_audio_init
	xdef ie_mod_start
	xdef ie_play_sfx
	xdef ie_mod_set_data
	xdef ie_sfx_set_sample
	xdef ie_sfx_get_sample
	xdef ie_sfx_clear_samples
	xdef mt_init
	xdef _mt_init
	xdef mt_music
	xdef _mt_music
	xdef mt_end
	xdef _mt_end
	xdef Aud_PlaySound
	xdef _Aud_PlaySound
	xdef MakeSomeNoise
	xdef _MakeSomeNoise
	xdef ie_mod_data_ptr
	xdef ie_mod_data_len
	xdef ie_sfx_ptr
	xdef ie_sfx_len
	xdef ie_sfx_ctrl
	xdef ie_sfx_channel
	xdef ie_next_sfx_channel
	xdef Aud_SampleList_vl
	xdef Aud_SampleNum_w
	xdef Aud_NoiseVol_w
	xdef Aud_ChannelPick_b
	xdef Aud_NoiseX_w
	xdef Aud_NoiseZ_w
	xdef IDNUM
	xdef notifplaying

ie_audio_init:
	rts

; Configure default MOD payload source for mt_init compatibility.
; in: d0=mod_ptr, d1=mod_len
ie_mod_set_data:
	move.l	d0,ie_mod_data_ptr
	move.l	d1,ie_mod_data_len
	rts

; Register one SFX sample in legacy Aud_SampleList_vl.
; in: d0=sample_index (0..63), d1=ptr, d2=len
ie_sfx_set_sample:
	andi.l	#$3F,d0
	lsl.l	#3,d0
	lea		Aud_SampleList_vl,a0
	move.l	d1,0(a0,d0.l)
	move.l	d2,4(a0,d0.l)
	rts

; Query one SFX sample entry from Aud_SampleList_vl.
; in: d0=sample_index (0..63)
; out: d1=ptr, d2=len
ie_sfx_get_sample:
	andi.l	#$3F,d0
	lsl.l	#3,d0
	lea		Aud_SampleList_vl,a0
	move.l	0(a0,d0.l),d1
	move.l	4(a0,d0.l),d2
	rts

; Clear the first 64 legacy SFX entries (ptr/len pairs).
ie_sfx_clear_samples:
	lea		Aud_SampleList_vl,a0
	move.w	#127,d7
.clr_samples:
	clr.l	(a0)+
	dbra	d7,.clr_samples
	rts

ie_mod_start:
	move.l	d0,$F0BC0
	move.l	d1,$F0BC4
	tst.l	d2
	bne.s	.write_ctrl
	moveq	#1,d2
.write_ctrl:
	move.l	d2,$F0BC8
	rts

ie_play_sfx:
	andi.l	#3,d3
	lsl.l	#4,d3
	move.l	#$F2380,a0
	adda.l	d3,a0
	move.l	d0,(a0)
	move.l	d1,4(a0)
	tst.l	d2
	bne.s	.sfx_write_ctrl
	moveq	#1,d2
.sfx_write_ctrl:
	move.l	d2,8(a0)
	rts

; Legacy music entrypoints (ProTracker API compatibility).
; mt_init starts playback from configured ie_mod_data_{ptr,len}.
mt_init:
_mt_init:
	move.l	ie_mod_data_ptr,d0
	move.l	ie_mod_data_len,d1
	moveq	#1,d2
	bsr	ie_mod_start
	rts

; IE MOD playback is autonomous; no per-frame tick is required.
mt_music:
_mt_music:
	rts

; Stop MOD playback.
mt_end:
_mt_end:
	move.l	#2,$F0BC8
	rts

; Compatibility wrappers for legacy SFX call sites.
Aud_PlaySound:
_Aud_PlaySound:
	bsr	MakeSomeNoise
	rts

MakeSomeNoise:
_MakeSomeNoise:
	; Resolve sample ptr/len from legacy sample table by sample id.
	moveq	#0,d5
	move.w	Aud_SampleNum_w,d5
	lsl.l	#3,d5
	lea		Aud_SampleList_vl,a3
	move.l	0(a3,d5.l),d0
	move.l	4(a3,d5.l),d1

	; Accept both table encodings:
	;   1) {ptr, len}
	;   2) {ptr, end_ptr} after Res_PatchSoundFx
	; If second field is above ptr, treat as end_ptr and convert to len.
	move.l	d1,d6
	sub.l	d0,d6
	bcs.s	.keep_len
	move.l	d6,d1
.keep_len:

	; Volume: clamp to 0..255 and pack in ctrl high byte.
	moveq	#0,d4
	move.w	Aud_NoiseVol_w,d4
	tst.l	d4
	bge.s	.vol_nonneg
	moveq	#0,d4
.vol_nonneg:
	cmpi.l	#255,d4
	ble.s	.vol_ok
	move.l	#255,d4
.vol_ok:
	move.l	d4,d2
	lsl.l	#8,d2
	ori.l	#1,d2

	; Channel pick:
	;   0 -> round-robin 0..3
	;   n -> map to (n-1)&3
	moveq	#0,d3
	move.w	Aud_ChannelPick_b,d3
	andi.l	#$FF,d3
	beq.s	.round_robin
	subq.l	#1,d3
	andi.l	#3,d3
	bra.s	.have_channel
.round_robin:
	moveq	#0,d3
	move.b	ie_next_sfx_channel,d3
	andi.l	#3,d3
	addq.b	#1,ie_next_sfx_channel
.have_channel:
	bsr	ie_play_sfx
	rts

ie_mod_data_ptr:
	dc.l	0
ie_mod_data_len:
	dc.l	0

ie_sfx_ptr:
	dc.l	0
ie_sfx_len:
	dc.l	0
ie_sfx_ctrl:
	dc.l	0
ie_sfx_channel:
	dc.b	0
	dc.b	0
	dc.b	0
	dc.b	0
ie_next_sfx_channel:
	dc.b	0
	dc.b	0
	dc.b	0
	dc.b	0

; Legacy audio state symbols used by existing game code.
Aud_SampleNum_w:
	dc.w	0
Aud_NoiseX_w:
	dc.w	0
Aud_NoiseZ_w:
	dc.w	0
Aud_NoiseVol_w:
	dc.w	0
Aud_ChannelPick_b:
	dc.w	0
IDNUM:
	dc.w	0
notifplaying:
	dc.b	0
	dc.b	0

Aud_SampleList_vl:
	dcb.l	128,0
