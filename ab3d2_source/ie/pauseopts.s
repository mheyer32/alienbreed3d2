				align 4
Game_Pause:

.waitpress:
				IFD		IS_IE
				jsr		ie_wait_vblank
				jsr		ie_poll_input
				ENDC
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
				IFND	IS_IE
				btst	#7,$bfe001
				bne.s	.waitpress
				ENDC
				IFD		IS_IE
				bra.s	.waitpress
				ENDC

.unp:
.wr2:
				IFD		IS_IE
				jsr		ie_wait_vblank
				jsr		ie_poll_input
				ENDC
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

				IFND	IS_IE
				btst	#7,$bfe001
				beq.s	.wr2
				ENDC

				rts


PAUSETEXT:
;      12345678901234567890123456789012345678901234567890123456789012345678901234567890
				dc.b	'                                  * PAUSED *                                    '
ENDPAUSETEXT:

TOPPOPT:		dc.w	0
;BOTPOPT:		dc.w	0
