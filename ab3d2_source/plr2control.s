; *****************************************************************************
; *
; * Stubs for Player 2
; *
; * Code has been generalised and moved to modules/player.s
; *
; *****************************************************************************

Plr2_ShowGunName:
				lea		Plr2_Data,a0
				bra		plr_ShowGunName

Plr2_MouseControl:
				lea		Plr2_Data,a0
				jsr		plr_MouseControl
				; fall through

Plr2_KeyboardControl:
				lea		Plr2_Data,a0
				jsr		plr_KeyboardControl

				jsr		Plr2_Fall

				rts

Plr2_JoystickControl:
				jsr		_ReadJoy2
				bra.s	Plr2_KeyboardControl

Plr2_FootstepFX:
				lea		Plr1_Data,a0
				bra		plr_DoFootstepFX

Plr2_Fall:
				lea		Plr2_Data,a0
				bra		plr_Fall
