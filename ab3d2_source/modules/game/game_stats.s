
; *****************************************************************************
; *
; * modules/game/game_preferences.s
; *
; * Handles the persistence of game statistics
; *
; *****************************************************************************

				IFND BUILD_WITH_C
				align 4

Game_LoadStats:
				movem.l	d0-d4/a6,-(a7)

				move.l	#Game_StatsFile_vb,d1
				move.l	#MODE_OLDFILE,d2
				CALLDOS	Open

				move.l	d0,d1 ; file handle handle in d1
				beq.s	.io_error

				move.l	d0,d4 ; backup handle in d4

				move.l	#Game_Stats,d2
				move.l	#GStatT_SizeOf_l,d3

				CALLDOS	Read

				;move.l	d0,d2 ; bytes read - todo checks and things

				move.l	d4,d1 ; d1 trashed by read
				CALLDOS Close

.io_error:
				movem.l	(a7)+,d0-d4/a6
				rts


Game_SaveStats:
				movem.l	d0-d4/a6,-(a7)

				move.l	#Game_StatsFile_vb,d1
				move.l	#MODE_READWRITE,d2
				CALLDOS	Open

				move.l	d0,d1 ; file handle handle in d1
				beq.s	.io_error

				move.l	d0,d4

				move.l	#Game_Stats,d2
				move.l	#Game_StatsEnd,d3
				sub.l	d2,d3 ; size in d3

				CALLDOS	Write

				;move.l	d0,d2 ; bytes written - what can we even do if this went wrong?

				move.l	d4,d1 ; d1 trashed by read
				CALLDOS Close

.io_error:
				movem.l	(a7)+,d0-d4/a6
				rts

				ELSE

				ENDIF

