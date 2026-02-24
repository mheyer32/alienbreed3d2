; ie_audio.s - Intuition Engine audio bridge
; Calling convention (current WIP):
;   ie_mod_start: d0=mod_ptr, d1=mod_len, d2=ctrl (0 => start)
;   ie_play_sfx:  d0=sfx_ptr, d1=sfx_len, d2=ctrl (0 => start), d3=channel 0-3

	xdef ie_audio_init
	xdef ie_mod_start
	xdef ie_play_sfx
	xdef ie_mod_set_data
	xdef mt_init
	xdef mt_music
	xdef mt_end
	xdef Aud_PlaySound
	xdef MakeSomeNoise
	xdef ie_mod_data_ptr
	xdef ie_mod_data_len
	xdef ie_sfx_ptr
	xdef ie_sfx_len
	xdef ie_sfx_ctrl
	xdef ie_sfx_channel

ie_audio_init:
	rts

; Configure default MOD payload source for mt_init compatibility.
; in: d0=mod_ptr, d1=mod_len
ie_mod_set_data:
	move.l	d0,ie_mod_data_ptr
	move.l	d1,ie_mod_data_len
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
	move.l	ie_mod_data_ptr,d0
	move.l	ie_mod_data_len,d1
	moveq	#1,d2
	bsr	ie_mod_start
	rts

; IE MOD playback is autonomous; no per-frame tick is required.
mt_music:
	rts

; Stop MOD playback.
mt_end:
	move.l	#2,$F0BC8
	rts

; Compatibility wrappers for legacy SFX call sites.
Aud_PlaySound:
	bsr	MakeSomeNoise
	rts

MakeSomeNoise:
	move.l	ie_sfx_ptr,d0
	move.l	ie_sfx_len,d1
	move.l	ie_sfx_ctrl,d2
	moveq	#0,d3
	move.b	ie_sfx_channel,d3
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
