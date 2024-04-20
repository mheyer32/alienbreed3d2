				align 4
Game_Pause:
				move.l	#PAUSETEXT,draw_GameMessagePtr_l
				move.l	#ENDPAUSETEXT,draw_GameMessageEnd_l
				move.w	#0,draw_GameMessageXPos_w
				move.w	#40,draw_GameMessageTimer_w
				move.w	#40,d6
.waitpause:
				jsr		Draw_NarrateText

				dbra	d6,.waitpause

.waitpress:
				cmp.b	#PLR_SLAVE,Plr_MultiplayerType_b
				beq.s	.otherk

				tst.b	Plr1_Joystick_b
				beq.s	.NOJOY

				jsr		_ReadJoy1

				bra		.thisk

.otherk:
				tst.b	Plr2_Joystick_b
				beq.s	.NOJOY
				jsr		_ReadJoy2
.thisk:
.NOJOY:
				tst.b	RAWKEY_P(a5)
				bne.s	.unp
				btst	#7,$bfe001
				bne.s	.waitpress

.unp:
.wr2:
				cmp.b	#PLR_SLAVE,Plr_MultiplayerType_b
				beq.s	.otherk2
				tst.b	Plr1_Joystick_b
				beq.s	.NOJOY2
				jsr		_ReadJoy1
				bra		.thisk2

.otherk2:
				tst.b	Plr2_Joystick_b
				beq.s	.NOJOY2
				jsr		_ReadJoy2

.thisk2:
.NOJOY2:
				tst.b	RAWKEY_P(a5)
				bne.s	.wr2

				btst	#7,$bfe001
				beq.s	.wr2

				move.l	#draw_BlankMessage_vb,draw_GameMessagePtr_l
				move.l	#draw_BlankMessage_vb+80,draw_GameMessageEnd_l
				move.w	#0,draw_GameMessageXPos_w
				move.w	#40,draw_GameMessageTimer_w
				move.w	#40,d6

.waitpause2:
				jsr		Draw_NarrateText
				dbra	d6,.waitpause2

				rts


PAUSETEXT:
;      12345678901234567890123456789012345678901234567890123456789012345678901234567890
				dc.b	'                                  * PAUSED *                                    '
ENDPAUSETEXT:

TOPPOPT:		dc.w	0
;BOTPOPT:		dc.w	0
