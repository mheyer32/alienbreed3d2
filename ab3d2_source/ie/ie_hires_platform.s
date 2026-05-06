; ie_hires_platform.s
; IE platform support for linking the legacy hires.s software renderer.

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
	xdef _Game_FinishedLevel_b
	xdef ie_wait_vblank
	xdef ie_poll_input
	xdef ie_MakeSomeNoise
	xdef _ReadJoy1
	xdef _ReadJoy2
	xdef SENDFIRST
	xdef RECFIRST
	xdef button
	xdef button1
	xdef ie_next_sfx_channel

	xdef _SysBase
	xdef _DOSBase
	xdef _Vid_isRTG
	xdef _custom
	xdef _ciaa

	xref _Vid_FastBufferPtr_l
	xref _Vid_Screen1Ptr_l
	xref _Vid_Screen2Ptr_l
	xref _Vid_DrawScreenPtr_l
	xref _Vid_DisplayScreenPtr_l
	xref _Vid_ScreenBuffers_vl
	xref _Vid_ScreenBufferIndex_w
	xref _Vid_LetterBoxMarginHeight_w
	xref _Vid_UpdatePalette_b
	xref _Vid_FullScreen_b
	xref _Vid_RightX_w
	xref _Lvl_ListOfGraphRoomsPtr_l
	xref _Lvl_ZonePtrsPtr_l
	xref _Lvl_NumZones_w
	xref _Draw_ZoneClipL_w
	xref _Draw_ZoneClipR_w
	xref _Draw_ForceZoneSkip_b
	xref _Zone_VisJoins_w
	xref _Zone_TotJoins_w
	xref _Zone_VisJoinMask_w
	xref _Zone_EdgePointIndexes_vw
	xref _Sys_MouseY
	xref _Sys_FPSLimit_w
	xref _KeyMap_vb
	xref lastpressed
	xref _draw_Palette_vw
	xref Aud_SampleNum_w
	xref Aud_SampleList_vl
	xref Aud_NoiseVol_w
	xref Aud_ChannelPick_b
	xref _Vid_GammaIncTables_vb
	xref _Vid_ContrastAdjust_w
	xref _Vid_BrightnessOffset_w
	xref _Vid_GammaLevel_b

CHUNKY_BASE	equ	$100000
CHUNKY_BACK_BASE	equ	$113000
PRESENT_BASE	equ	$126000
SCREEN_WIDTH	equ	320
SCREEN_HEIGHT	equ	240
SMALL_WIDTH	equ	192
SMALL_HEIGHT	equ	160
SMALL_XPOS	equ	64
SMALL_YPOS	equ	20
MODE_320x240	equ	$05
VIDEO_CTRL	equ	$F0000
VIDEO_MODE	equ	$F0004
VIDEO_PAL_INDEX	equ	$F0078
VIDEO_PAL_DATA	equ	$F007C
VIDEO_COLOR_MODE	equ	$F0080
VIDEO_FB_BASE	equ	$F0084
FAKE_LIB_BASE	equ	$6F0000
FAKE_VEC_BYTES	equ	$0800
EDGE_POINT_ID_LIST_END	equ	-4
IE_SCANCODE_NONE	equ	$FF
RAWKEY_CTRL	equ	$63
RAWKEY_LSHIFT	equ	$60
RAWKEY_LALT	equ	$64
IE_MOD_SHIFT	equ	0
IE_MOD_CTRL	equ	1
IE_MOD_ALT	equ	2
POTINP		equ	$016
CIAPRA		equ	0
CIAB_GAMEPORT0	equ	6

_Sys_Init:
	move.l	#FAKE_LIB_BASE,_DOSBase
	move.l	#FAKE_LIB_BASE,_SysBase
	bsr		ie_init_fake_lib_vectors
	move.w	#-1,_Sys_FPSLimit_w
	bsr		_Vid_OpenMainScreen
	bsr		_Sys_ClearKeyboard
	moveq	#1,d0
	rts

_Sys_Done:
	bsr		_Vid_CloseMainScreen
	rts

_Sys_ClearKeyboard:
	lea		_KeyMap_vb,a0
	move.w	#255,d0
.clear_keys:
	clr.b	(a0)+
	dbra	d0,.clear_keys
	clr.b	lastpressed
.drain_queue:
	move.l	$F0744,d1
	andi.l	#1,d1
	beq.s	.done
	move.l	$F0740,d1
	bra.s	.drain_queue
.done:
	rts

ie_wait_vblank:
	bsr		ie_poll_input
.wait_not_vblank:
	move.l	$F0008,d0
	andi.l	#2,d0
	bne.s	.wait_not_vblank
.wait_vblank:
	move.l	$F0008,d0
	andi.l	#2,d0
	beq.s	.wait_vblank
	bsr		ie_poll_input
	rts

ie_poll_input:
	bsr		ie_poll_keyboard
	bsr		ie_poll_mouse
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
	bsr		ie_poll_keyboard
	bsr		ie_poll_mouse
	rts

ie_poll_mouse:
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
	move.l	$F0738,d0
	move.l	d0,d1
	andi.l	#7,d1
	bne.s	.buttons_ready
	swap	d0
	lsr.l	#8,d0
	andi.l	#7,d0
	bra.s	.buttons_apply
.buttons_ready:
	move.l	d1,d0
.buttons_apply:
	bset	#2,_custom+POTINP
	btst	#1,d0
	beq.s	.no_right_button
	bclr	#2,_custom+POTINP
.no_right_button:
	bset	#CIAB_GAMEPORT0,_ciaa+CIAPRA
	btst	#0,d0
	beq.s	.no_left_button
	bclr	#CIAB_GAMEPORT0,_ciaa+CIAPRA
.no_left_button:
	rts

_Vid_OpenMainScreen:
	move.l	#1,VIDEO_CTRL
	move.l	#MODE_320x240,VIDEO_MODE
	move.l	#1,VIDEO_COLOR_MODE
	move.l	#CHUNKY_BASE,VIDEO_FB_BASE
	move.l	#CHUNKY_BASE,_Vid_FastBufferPtr_l
	move.l	#CHUNKY_BASE,_Vid_Screen1Ptr_l
	move.l	#CHUNKY_BACK_BASE,_Vid_Screen2Ptr_l
	move.l	#CHUNKY_BASE,_Vid_DrawScreenPtr_l
	move.l	#CHUNKY_BASE,_Vid_DisplayScreenPtr_l
	move.l	#CHUNKY_BASE,_Vid_ScreenBuffers_vl
	move.l	#CHUNKY_BACK_BASE,_Vid_ScreenBuffers_vl+4
	clr.w	_Vid_ScreenBufferIndex_w
	clr.w	_Vid_LetterBoxMarginHeight_w
	clr.l	ie_mouse_relative_ok
	move.l	$F0734,ie_mouse_last_abs_y
	bsr		_Vid_LoadMainPalette
	moveq	#1,d0
	rts

_Vid_CloseMainScreen:
	IFD		IS_IE
	rts
	ENDC
	move.l	#0,$F0000
	rts

_Vid_LoadMainPalette:
	lea		_draw_Palette_vw,a3
	suba.l	a5,a5
	moveq	#0,d6
	move.b	_Vid_GammaLevel_b,d6
	beq.s	.pal_loop_init
	subq.l	#1,d6
	andi.l	#7,d6
	lsl.l	#8,d6
	lea		_Vid_GammaIncTables_vb,a5
	adda.l	d6,a5
.pal_loop_init:
	move.w	#255,d7
	moveq	#0,d6
.pal8_loop:
	move.l	d6,VIDEO_PAL_INDEX
	moveq	#0,d0
	move.w	(a3)+,d0
	bsr		ie_palette_apply_channel
	move.l	d0,d4
	lsl.l	#8,d4
	lsl.l	#8,d4

	moveq	#0,d0
	move.w	(a3)+,d0
	bsr		ie_palette_apply_channel
	move.l	d0,d5
	lsl.l	#8,d5
	or.l	d5,d4

	moveq	#0,d0
	move.w	(a3)+,d0
	bsr		ie_palette_apply_channel
	move.l	d0,d5
	or.l	d5,d4

	move.l	d4,VIDEO_PAL_DATA
	addq.l	#1,d6
	dbra	d7,.pal8_loop
	rts

ie_palette_apply_channel:
	moveq	#0,d1
	move.w	d0,d1
	tst.l	a5
	beq.s	.linear
	moveq	#0,d0
	move.b	0(a5,d1.w),d0
	bra.s	.adjust
.linear:
	move.l	d1,d0
.adjust:
	mulu.w	_Vid_ContrastAdjust_w,d0
	move.w	_Vid_BrightnessOffset_w,d1
	ext.l	d1
	add.l	d1,d0
	bpl.s	.clamp_hi
	clr.l	d0
	rts
.clamp_hi:
	cmpi.l	#65535,d0
	bls.s	.done
	move.l	#65535,d0
.done:
	lsr.l	#8,d0
	rts

_Vid_Present:
	bsr		ie_poll_input
	; Apply deferred palette uploads from legacy path.
	tst.b	_Vid_UpdatePalette_b
	beq.s	.no_pal
	clr.b	_Vid_UpdatePalette_b
	bsr		_Vid_LoadMainPalette
.no_pal:
	move.l	_Vid_FastBufferPtr_l,a0
	tst.l	a0
	bne.s	.have_fb
	move.l	#CHUNKY_BASE,a0
.have_fb:
	tst.b	_Vid_FullScreen_b
	bne.s	.present_full
	bsr		ie_present_small
	move.l	#PRESENT_BASE,VIDEO_FB_BASE
	rts
.present_full:
	move.l	a0,VIDEO_FB_BASE
	rts

_Draw_ResetGameDisplay:
	movem.l	d0-d1/a0,-(sp)
	lea		CHUNKY_BASE,a0
	moveq	#0,d0
	move.w	#((SCREEN_WIDTH*SCREEN_HEIGHT/4)-1),d1
.clear_front:
	move.l	d0,(a0)+
	dbra	d1,.clear_front
	lea		CHUNKY_BACK_BASE,a0
	move.w	#((SCREEN_WIDTH*SCREEN_HEIGHT/4)-1),d1
.clear_back:
	move.l	d0,(a0)+
	dbra	d1,.clear_back
	lea		PRESENT_BASE,a0
	move.w	#((SCREEN_WIDTH*SCREEN_HEIGHT/4)-1),d1
.clear_present:
	move.l	d0,(a0)+
	dbra	d1,.clear_present
	move.l	#PRESENT_BASE,VIDEO_FB_BASE
	movem.l	(sp)+,d0-d1/a0
	rts

; Match the original RTG small-screen path: copy the 192x160
; chunky render area into the centred 320x240 display buffer.
ie_present_small:
	movem.l	d0-d2/a0-a2,-(sp)
	lea		PRESENT_BASE,a1
	moveq	#0,d0
	move.w	#((SCREEN_WIDTH*SCREEN_HEIGHT/4)-1),d1
.clear_present:
	move.l	d0,(a1)+
	dbra	d1,.clear_present
	lea		PRESENT_BASE+(SMALL_YPOS*SCREEN_WIDTH)+SMALL_XPOS,a1
	move.w	#(SMALL_HEIGHT-1),d2
.copy_row:
	move.w	#(SMALL_WIDTH/4-1),d1
.copy_long:
	move.l	(a0)+,(a1)+
	dbra	d1,.copy_long
	adda.w	#(SCREEN_WIDTH-SMALL_WIDTH),a0
	adda.w	#(SCREEN_WIDTH-SMALL_WIDTH),a1
	dbra	d2,.copy_row
	movem.l	(sp)+,d0-d2/a0-a2
	rts

_Zone_SetupEdgeClipping:
	clr.w	_Draw_ZoneClipL_w
	move.w	_Vid_RightX_w,_Draw_ZoneClipR_w
	clr.b	_Draw_ForceZoneSkip_b
	rts

_Zone_CheckVisibleEdges:
	movem.l	d0-d2/a0-a2,-(sp)
	clr.w	_Zone_VisJoins_w
	clr.w	_Zone_TotJoins_w
	clr.w	_Zone_VisJoinMask_w
	move.w	#EDGE_POINT_ID_LIST_END,_Zone_EdgePointIndexes_vw
	move.l	_Lvl_ZonePtrsPtr_l,a0
	move.w	_Lvl_NumZones_w,d0
	bra.s	.clear_test
.clear_loop:
	move.l	(a0)+,a1
	tst.l	a1
	beq.s	.clear_next
	clr.w	30(a1)
.clear_next:
	subq.w	#1,d0
.clear_test:
	bgt.s	.clear_loop
	move.l	_Lvl_ListOfGraphRoomsPtr_l,a0
	move.l	_Lvl_ZonePtrsPtr_l,a2
.mark_loop:
	move.w	(a0),d0
	blt.s	.done_mark
	move.w	d0,d1
	blt.s	.next_pvs
	cmp.w	_Lvl_NumZones_w,d1
	bge.s	.next_pvs
	lsl.w	#2,d1
	move.l	0(a2,d1.w),a1
	tst.l	a1
	beq.s	.next_pvs
	move.w	#1,30(a1)
.next_pvs:
	adda.w	#8,a0
	bra.s	.mark_loop
.done_mark:
	movem.l	(sp)+,d0-d2/a0-a2
	rts

_Draw_LineOfText:
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
_Zone_FreeEdgePVS:
_mnu_setscreen:
_mnu_clearscreen:
_mnu_movescreen:
_mnu_dofire:
	rts

_ReadJoy1:
_ReadJoy2:
	bsr		ie_poll_keyboard
	rts
SENDFIRST:
RECFIRST:
	rts

_Game_LevelWon:
	st		_Game_FinishedLevel_b
	rts

_Game_CheckInventoryLimits:
	moveq	#1,d0
	rts

ie_poll_keyboard:
	lea		_KeyMap_vb,a0
.drain:
	move.l	$F0744,d0
	andi.l	#1,d0
	beq.s	.done
	move.l	$F0740,d0
	move.l	d0,d2
	andi.l	#$FF,d2
	bne.s	.scan_low_byte
	swap	d0
	lsr.l	#8,d0
	bra.s	.scan_code_ready
.scan_low_byte:
	move.l	d2,d0
.scan_code_ready:
	move.l	d0,d1
	andi.l	#$7F,d1
	lea		ie_scancode_to_rawkey,a1
	move.b	0(a1,d1.w),d1
	cmpi.b	#IE_SCANCODE_NONE,d1
	beq.s	.drain
	btst	#7,d0
	bne.s	.release
	move.b	#$FF,0(a0,d1.w)
	move.b	d1,lastpressed
	bra.s	.drain
.release:
	clr.b	0(a0,d1.w)
	bra.s	.drain
.done:
	move.l	$F0748,d0
	move.l	d0,d2
	andi.l	#$0F,d2
	bne.s	.modifiers_low_byte
	swap	d0
	lsr.l	#8,d0
	andi.l	#$0F,d0
	bra.s	.modifiers_ready
.modifiers_low_byte:
	move.l	d2,d0
.modifiers_ready:
	move.l	ie_last_modifiers,d1
	move.l	d0,ie_last_modifiers
	btst	#IE_MOD_SHIFT,d0
	bne.s	.mod_shift_down
	btst	#IE_MOD_SHIFT,d1
	beq.s	.mod_shift_done
	clr.b	RAWKEY_LSHIFT(a0)
	bra.s	.mod_shift_done
.mod_shift_down:
	sne		RAWKEY_LSHIFT(a0)
.mod_shift_done:
	btst	#IE_MOD_CTRL,d0
	bne.s	.mod_ctrl_down
	btst	#IE_MOD_CTRL,d1
	beq.s	.mod_ctrl_done
	clr.b	RAWKEY_CTRL(a0)
	bra.s	.mod_ctrl_done
.mod_ctrl_down:
	sne		RAWKEY_CTRL(a0)
.mod_ctrl_done:
	btst	#IE_MOD_ALT,d0
	bne.s	.mod_alt_down
	btst	#IE_MOD_ALT,d1
	beq.s	.mod_alt_done
	clr.b	RAWKEY_LALT(a0)
	bra.s	.mod_alt_done
.mod_alt_down:
	sne		RAWKEY_LALT(a0)
.mod_alt_done:
	rts

ie_scancode_to_rawkey:
	dc.b	IE_SCANCODE_NONE,$45,$01,$02,$03,$04,$05,$06
	dc.b	$07,$08,$09,$0A,$0B,$0C,$41,$42
	dc.b	$10,$11,$12,$13,$14,$15,$16,$17
	dc.b	$18,$19,$1A,$1B,$44,$63,$20,$21
	dc.b	$22,$23,$24,$25,$26,$27,$28,$29
	dc.b	$2A,$00,$60,$0D,$31,$32,$33,$34
	dc.b	$35,$36,$37,$38,$39,$3A,$61,IE_SCANCODE_NONE
	dc.b	IE_SCANCODE_NONE,$40,$62,$50,$51,$52,$53,$54
	dc.b	$55,$56,$57,$58,$59,IE_SCANCODE_NONE,IE_SCANCODE_NONE,IE_SCANCODE_NONE
	dc.b	IE_SCANCODE_NONE,IE_SCANCODE_NONE,IE_SCANCODE_NONE,IE_SCANCODE_NONE,IE_SCANCODE_NONE,IE_SCANCODE_NONE,IE_SCANCODE_NONE,IE_SCANCODE_NONE
	dc.b	$4C,IE_SCANCODE_NONE,IE_SCANCODE_NONE,$4F,IE_SCANCODE_NONE,$4E,IE_SCANCODE_NONE,IE_SCANCODE_NONE
	dc.b	$4D,IE_SCANCODE_NONE,IE_SCANCODE_NONE,IE_SCANCODE_NONE,IE_SCANCODE_NONE,IE_SCANCODE_NONE,IE_SCANCODE_NONE,IE_SCANCODE_NONE
	dc.b	IE_SCANCODE_NONE,IE_SCANCODE_NONE,IE_SCANCODE_NONE,IE_SCANCODE_NONE,IE_SCANCODE_NONE,IE_SCANCODE_NONE,IE_SCANCODE_NONE,$5F
	dc.b	IE_SCANCODE_NONE,IE_SCANCODE_NONE,IE_SCANCODE_NONE,IE_SCANCODE_NONE,IE_SCANCODE_NONE,IE_SCANCODE_NONE,IE_SCANCODE_NONE,IE_SCANCODE_NONE
	dc.b	IE_SCANCODE_NONE,IE_SCANCODE_NONE,IE_SCANCODE_NONE,IE_SCANCODE_NONE,IE_SCANCODE_NONE,IE_SCANCODE_NONE,IE_SCANCODE_NONE,IE_SCANCODE_NONE
	dc.b	IE_SCANCODE_NONE,IE_SCANCODE_NONE,IE_SCANCODE_NONE,IE_SCANCODE_NONE,IE_SCANCODE_NONE,IE_SCANCODE_NONE,IE_SCANCODE_NONE,$FF
	dc.b	$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF

; Populate a synthetic library vector table with RTS stubs.
; Legacy code issues jsr -N(a6) through DOS/Exec bases.
ie_MakeSomeNoise:
	movem.l	d0-d7/a0-a1,-(a7)
	moveq	#0,d5
	move.w	Aud_SampleNum_w,d5
	andi.l	#$3F,d5
	move.l	#Aud_SampleList_vl,a0
	move.l	(a0,d5.w*8),d0
	move.l	4(a0,d5.w*8),d1
	tst.l	d0
	beq		.done
	tst.l	d1
	beq		.done
	move.l	d1,d6
	sub.l	d0,d6
	bcs.s	.len_ready
	move.l	d6,d1
.len_ready:
	tst.l	d1
	beq		.done

	moveq	#0,d2
	move.w	Aud_NoiseVol_w,d2
	bpl.s	.vol_nonneg
	moveq	#0,d2
.vol_nonneg:
	cmpi.l	#255,d2
	ble.s	.vol_ok
	move.l	#255,d2
.vol_ok:
	moveq	#0,d3
	move.w	Aud_ChannelPick_b,d3
	andi.l	#$FF,d3
	beq.s	.round_robin
	subq.l	#1,d3
	andi.l	#3,d3
	bra.s	.channel_ready
.round_robin:
	moveq	#0,d3
	move.b	ie_next_sfx_channel,d3
	andi.l	#3,d3
	addq.b	#1,ie_next_sfx_channel
.channel_ready:
	lsl.l	#5,d3
	move.l	#$F0E80,a1
	adda.l	d3,a1
	move.l	d0,$00(a1)
	move.l	d1,$04(a1)
	clr.l	$08(a1)
	clr.l	$0C(a1)
	move.l	#11025,$10(a1)
	move.w	d2,$14(a1)
	clr.w	$16(a1)
	clr.b	$18(a1)
	move.l	#1,$1C(a1)
.done:
	movem.l	(a7)+,d0-d7/a0-a1
	rts

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
button:
	dc.l	0
button1:
	dc.l	0
ie_next_sfx_channel:
	dc.b	0
	dc.b	0

ie_mouse_relative_ok:
	dc.l	0
ie_mouse_last_abs_y:
	dc.l	0
ie_last_modifiers:
	dc.l	0

_Game_FinishedLevel_b:
	dc.w	0
