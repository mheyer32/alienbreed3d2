mt_init:
				move.l	#2,$F0BC8
				move.l	#2,$F0E28
				lea		ie_sid_music_name,a0
				jsr		IO_LoadFileOptional
				tst.l	d0
				beq.s	.done
				move.l	d0,$F0E20
				move.l	d1,$F0E24
				move.l	#1,$F0E28
.done:
				st		reachedend
				rts

mt_end:
				move.l	#2,$F0E28
				move.l	#2,$F0BC8
				rts

mt_music:
				st		reachedend
				rts

reachedend:		dc.b	0
				align	4
mt_data:		dc.l	0
mt_size:		dc.l	0

ie_sid_music_name:
				dc.b	'media/includes/At_Dooms_Gate_E1M1.sid',0
				even
