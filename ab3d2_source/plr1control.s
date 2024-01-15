; *****************************************************************************
; *
; * Stubs for Player 1
; *
; * Code has been generalised and moved to modules/player.s
; *
; *****************************************************************************

Plr1_ShowGunName:
				lea		Plr1_Data,a0
				bra		plr_ShowGunName

Plr1_MouseControl:
				lea		Plr1_Data,a0
				jsr		plr_MouseControl
				; fall through

Plr1_KeyboardControl:
				lea		Plr1_Data,a0
				jsr		plr_KeyboardControl

				jsr		Plr1_Fall

				rts

Plr1_JoystickControl:
				jsr		_ReadJoy1
				bra.s	Plr1_KeyboardControl

Plr1_FootstepFX:
				lea		Plr1_Data,a0
				bra		plr_DoFootstepFX

Plr1_Fall:
				lea		Plr1_Data,a0
				bra		plr_Fall



Plr1_FollowPath:
				move.l	pathpt,a0
				move.w	(a0),d1
				move.w	d1,Plr1_SnapXOff_l
				move.w	2(a0),d1
				move.w	d1,Plr1_SnapZOff_l
				move.w	4(a0),d0
				add.w	d0,d0
				AMOD_A	d0
				move.w	d0,Plr1_AngPos_w
				move.w	Anim_TempFrames_w,d0
				asl.w	#3,d0
				adda.w	d0,a0
				cmp.l	#endpath,a0
				blt		.notrestartpath

				move.l	#Path,a0
.notrestartpath:
				move.l	a0,pathpt

				rts
