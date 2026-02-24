; ie_audio.s - Intuition Engine audio bridge
; Calling convention (current WIP):
;   ie_mod_start: d0=mod_ptr, d1=mod_len, d2=ctrl (0 => start)
;   ie_play_sfx:  d0=sfx_ptr, d1=sfx_len, d2=ctrl (0 => start), d3=channel 0-3

	xdef ie_audio_init
	xdef ie_mod_start
	xdef ie_play_sfx

ie_audio_init:
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
