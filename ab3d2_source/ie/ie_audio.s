; ie_audio.s - Intuition Engine audio bridge stubs (WIP)

	xdef ie_audio_init
	xdef ie_mod_start
	xdef ie_play_sfx

ie_audio_init:
	rts

ie_mod_start:
	; TODO: stage MOD ptr/len and write start control at 0xF0BC0 region
	rts

ie_play_sfx:
	; TODO: choose SFX channel (0xF2380 stride 0x10) and write ptr/len/ctrl
	rts
