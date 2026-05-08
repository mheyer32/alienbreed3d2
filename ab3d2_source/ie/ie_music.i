ie_LoadLevelMusic:
				moveq	#0,d1
				move.b	Lvl_BinFilenameX_vb,d1
				sub.b	#'a',d1
				lsl.w	#6,d1
				move.l	GLF_DatabasePtr_l,a0
				lea		GLFT_LevelMusic_l(a0),a0
				adda.w	d1,a0
				move.l	#MEMF_ANY,IO_MemType_l
				jsr		IO_LoadFileOptional
				move.l	d0,Lvl_MusicPtr_l
				move.l	d1,mt_size
				rts

mt_init:
				move.l	#2,$F0BC8
				move.l	#2,$F0E28
				move.l	mt_data,d0
				bne.s	.have_level_music
				bsr		ie_LoadLevelMusic
				move.l	d0,mt_data
.have_level_music:
				beq.s	.try_sid_fallback
				move.l	d0,$F0BC0
				move.l	mt_size,d1
				tst.l	d1
				beq.s	.try_sid_fallback
				move.l	d1,$F0BC4
				move.l	#5,$F0BC8
				clr.b	reachedend
				rts
.try_sid_fallback:
				IFD		IE_ENABLE_SID_MUSIC
				lea		ie_sid_music_name,a0
				jsr		IO_LoadFileOptional
				tst.l	d0
				beq.s	.done
				move.l	d0,$F0E20
				move.l	d1,$F0E24
				move.l	d1,mt_size
				move.l	#5,$F0E28
				clr.b	reachedend
				rts
				ENDC
.done:
				st		reachedend
				rts

mt_end:
				move.l	#2,$F0E28
				move.l	#2,$F0BC8
				clr.l	mt_size
				rts

mt_music:
				rts

reachedend:		dc.b	0
				align	4
mt_data:		dc.l	0
mt_size:		dc.l	0

				IFD		IE_ENABLE_SID_MUSIC
ie_sid_music_name:
				dc.b	'ie/at_dooms_gate_e1m1.sid',0
				even
				ENDC
