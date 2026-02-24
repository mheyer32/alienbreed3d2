; ie_hires_shim.s
; IE compatibility shims for linking legacy hires.s software renderer.

	xdef _Sys_Init
	xdef _Sys_Done
	xdef _Sys_ClearKeyboard
	xdef _Sys_MarkTime
	xdef _Sys_FrameLap
	xdef _Sys_ShowFPS
	xdef _Sys_EvalFPS
	xdef _Sys_ReadMouse
	xdef _Vid_OpenMainScreen
	xdef _Vid_CloseMainScreen
	xdef _Vid_LoadMainPalette
	xdef _Vid_Present
	xdef _Draw_LineOfText
	xdef _Draw_ResetGameDisplay
	xdef _vid_SetupDoubleheightCopperlist
	xdef _Msg_Init
	xdef _Msg_PushLine
	xdef _Msg_PushLineDedupLast
	xdef _Game_LevelBegin
	xdef _Game_LevelWon
	xdef _Game_LevelFailed
	xdef _Game_UpdatePlayerProgress
	xdef _Game_CheckInventoryLimits
	xdef _Game_AddToInventory
	xdef _Game_ApplyInventoryLimits
	xdef _Zone_InitEdgePVS
	xdef _Zone_ApplyPVSErrata
	xdef _Zone_SetupEdgeClipping
	xdef _Zone_CheckVisibleEdges
	xdef _Zone_FreeEdgePVS
	xdef _mnu_setscreen
	xdef _mnu_clearscreen
	xdef _mnu_movescreen
	xdef _mnu_dofire

	xdef _SysBase
	xdef _DOSBase
	xdef _Vid_isRTG
	xdef _custom
	xdef _ciaa

	xref _Vid_FastBufferPtr_l
	xref _Vid_DrawScreenPtr_l
	xref _Vid_DisplayScreenPtr_l
	xref _Vid_ScreenBuffers_vl
	xref _Vid_ScreenBufferIndex_w
	xref _Vid_LetterBoxMarginHeight_w
	xref _Vid_UpdatePalette_b
	xref _Sys_MouseY
	xref _KeyMap_vb

CHUNKY_BASE	equ	$060000
PALETTE_BASE	equ	$073000
SCRATCH_BASE	equ	$22C000
FRAMEBUF_BASE	equ	$100000
PIXELS_320x240	equ	76800
FAKE_LIB_BASE	equ	$090000
FAKE_VEC_BYTES	equ	$0800

_Sys_Init:
	move.l	#FAKE_LIB_BASE,_DOSBase
	move.l	#FAKE_LIB_BASE,_SysBase
	bsr		ie_init_fake_lib_vectors
	moveq	#1,d0
	rts

_Sys_Done:
	rts

_Sys_ClearKeyboard:
	rts

_Sys_MarkTime:
	tst.l	a0
	beq.s	.no_store
	clr.l	(a0)
	clr.l	4(a0)
.no_store:
	move.l	#60000,d0
	rts

_Sys_FrameLap:
_Sys_ShowFPS:
_Sys_EvalFPS:
	rts

_Sys_ReadMouse:
	bsr		ie_poll_keyboard_shim
	tst.l	ie_mouse_relative_ok
	beq.s	.abs_mode
	move.l	$F0734,d0
	bra.s	.apply_dy
.abs_mode:
	move.l	$F0734,d0
	move.l	d0,d1
	sub.l	ie_mouse_last_abs_y,d1
	move.l	d0,ie_mouse_last_abs_y
	move.l	d1,d0
.apply_dy:
	add.w	d0,_Sys_MouseY
	rts

_Vid_OpenMainScreen:
	move.l	#1,$F0000
	move.l	#0,$F0004
	move.l	#CHUNKY_BASE,_Vid_FastBufferPtr_l
	move.l	#CHUNKY_BASE,_Vid_DrawScreenPtr_l
	move.l	#CHUNKY_BASE,_Vid_DisplayScreenPtr_l
	move.l	#CHUNKY_BASE,_Vid_ScreenBuffers_vl
	move.l	#CHUNKY_BASE,_Vid_ScreenBuffers_vl+4
	clr.w	_Vid_ScreenBufferIndex_w
	clr.w	_Vid_LetterBoxMarginHeight_w
	move.l	#1,$F074C
	move.l	$F074C,d0
	cmpi.l	#1,d0
	beq.s	.rel_ok
	clr.l	ie_mouse_relative_ok
	move.l	$F0734,ie_mouse_last_abs_y
	bra.s	.rel_done
.rel_ok:
	move.l	#1,ie_mouse_relative_ok
.rel_done:
	bsr		_Vid_LoadMainPalette
	moveq	#1,d0
	rts

_Vid_CloseMainScreen:
	move.l	#0,$F0000
	rts

_Vid_LoadMainPalette:
	move.l	#PALETTE_BASE,a1
	moveq	#0,d0
.gray_loop:
	move.l	d0,d1
	lsl.l	#8,d1
	or.l	d0,d1
	lsl.l	#8,d1
	or.l	d0,d1
	lsl.l	#8,d1
	ori.l	#$FF,d1
	move.l	d1,(a1)+
	addq.l	#1,d0
	cmpi.l	#256,d0
	bne.s	.gray_loop
	rts

_Vid_Present:
	; Apply deferred palette uploads from legacy path.
	tst.b	_Vid_UpdatePalette_b
	beq.s	.no_pal
	clr.b	_Vid_UpdatePalette_b
	bsr		_Vid_LoadMainPalette
.no_pal:
	move.l	_Vid_FastBufferPtr_l,a0
	tst.l	a0
	bne.s	.have_src
	move.l	#CHUNKY_BASE,a0
.have_src:
	move.l	#SCRATCH_BASE,a1
	move.l	#PALETTE_BASE,a2
	move.l	#PIXELS_320x240,d7
.convert:
	moveq	#0,d0
	move.b	(a0)+,d0
	lsl.l	#2,d0
	move.l	0(a2,d0.l),(a1)+
	subq.l	#1,d7
	bne.s	.convert

	move.l	#5,$F0020
	move.l	#SCRATCH_BASE,$F0024
	move.l	#FRAMEBUF_BASE,$F0028
	move.l	#640,$F002C
	move.l	#480,$F0030
	move.l	#1280,$F0034
	move.l	#2560,$F0038
	move.l	#0,$F0058
	move.l	#0,$F005C
	move.l	#$00008000,$F0060
	move.l	#0,$F0064
	move.l	#0,$F0068
	move.l	#$00008000,$F006C
	move.l	#511,$F0070
	move.l	#255,$F0074
	move.l	#1,$F001C
	rts

_Draw_LineOfText:
_Draw_ResetGameDisplay:
_vid_SetupDoubleheightCopperlist:
_Msg_Init:
_Msg_PushLine:
_Msg_PushLineDedupLast:
_Game_LevelBegin:
_Game_LevelFailed:
_Game_UpdatePlayerProgress:
_Game_AddToInventory:
_Game_ApplyInventoryLimits:
_Zone_InitEdgePVS:
_Zone_ApplyPVSErrata:
_Zone_SetupEdgeClipping:
_Zone_CheckVisibleEdges:
_Zone_FreeEdgePVS:
_mnu_setscreen:
_mnu_clearscreen:
_mnu_movescreen:
_mnu_dofire:
	rts

_Game_LevelWon:
	rts

_Game_CheckInventoryLimits:
	moveq	#1,d0
	rts

ie_poll_keyboard_shim:
	lea		_KeyMap_vb,a0
.drain:
	move.l	$F0744,d0
	andi.l	#1,d0
	beq.s	.done
	move.l	$F0740,d0
	move.l	d0,d1
	andi.l	#$7F,d1
	btst	#7,d0
	bne.s	.release
	move.b	#$FF,0(a0,d1.w)
	bra.s	.drain
.release:
	clr.b	0(a0,d1.w)
	bra.s	.drain
.done:
	rts

; Populate a synthetic library vector table with RTS stubs.
; Legacy code issues jsr -N(a6) through DOS/Exec bases.
ie_init_fake_lib_vectors:
	lea		FAKE_LIB_BASE-FAKE_VEC_BYTES,a0
	move.w	#((FAKE_VEC_BYTES/2)-1),d7
.fill_rts:
	move.w	#$4E75,(a0)+
	dbra	d7,.fill_rts
	rts

_SysBase:
	dc.l	0
_DOSBase:
	dc.l	0
_Vid_isRTG:
	dc.w	1
	dc.w	0
_custom:
	dcb.b	1024,0
_ciaa:
	dcb.b	256,0

ie_mouse_relative_ok:
	dc.l	0
ie_mouse_last_abs_y:
	dc.l	0
