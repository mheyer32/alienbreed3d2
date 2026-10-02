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
	xdef ie_palette_apply_channel
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
	xdef ie_clear_presented_source
	xdef _mnu_setscreen
	xdef _mnu_clearscreen
	xdef _mnu_movescreen
	xdef _mnu_dofire
	xdef _Game_FinishedLevel_b
	xdef ie_wait_vblank
	xdef ie_wait_tof
	xdef ie_run_vblank
	xdef ie_poll_input
	xdef ie_MakeSomeNoise
	xdef _ReadJoy1
	xdef _ReadJoy2
	xdef SENDFIRST
	xdef RECFIRST
	xdef button
	xdef button1
	xdef ie_next_sfx_channel
	xdef ie_menu_active
	xdef ie_menu_last_buttons
	xdef ie_mouse_delta_x_w
	xdef ie_mouse_left_key_down_b
	xdef ie_mouse_right_key_down_b
	xdef ie_gamepad_clear
	IFD		IE_FPS_TEST
	xdef ie_fps_test_render_count_l
	xdef ie_fps_test_decimal_offset_l
	xdef ie_fps_test_eval_count_l
	xdef ie_fps_test_render_digit_count_b
	xdef ie_fps_test_render_digit_x_w
	xdef ie_fps_test_present_decimal_b
	xdef ie_fps_test_force_samples_b
	xdef ie_fps_test_result_w
	xdef ie_fps_test_mark_ecv_q
	xdef ie_fps_test_mark_rate_l
	ENDC
	IFD		IE_GAMEPAD_TEST
	xdef ie_gamepad_test_enable_b
	xdef ie_gamepad_test_status_l
	xdef ie_gamepad_test_buttons_l
	xdef ie_gamepad_test_lxy_l
	xdef ie_gamepad_test_rxy_l
	xdef ie_gamepad_actions_w
	xdef ie_gamepad_axis_state_w
	xdef ie_gamepad_test_edge_counts_vw
	xdef ie_gamepad_test_last_actions_w
	xdef ie_gamepad_test_read_count_l
	xdef ie_gamepad_test_level_begin_l
	xdef ie_gamepad_test_plr1_mouse_l
	xdef ie_gamepad_test_use_events_l
	xdef ie_gamepad_test_menu_up_l
	xdef ie_gamepad_test_menu_down_l
	xdef ie_gamepad_test_menu_wait_l
	ENDC
	IFD		IE_BLITTER_TEST
	xdef ie_blitter_test_fill_count_l
	xdef ie_blitter_test_copy_count_l
	xdef ie_blitter_test_error_l
	xdef ie_blitter_test_command_w
	xdef ie_blitter_test_done_w
	xdef ie_blitter_test_scratch_vb
	ENDC

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
	xref _Vid_DoubleHeight_b
	xref _Vid_DoubleWidth_b
	xref _Vid_UpdatePalette_b
	xref _Vid_FullScreen_b
	xref _Vid_FullScreenTemp_b
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
	xref _Sys_FrameTimes_vl
	xref _Sys_FrameNumber_l
	xref _Sys_FPSIntAvg_w
	xref _Sys_FPSFracAvg_w
	xref _Prefs_DisplayFPS_b
	xref _KeyMap_vb
	xref lastpressed
	xref _VBlankInterrupt
	xref forward_key
	xref backward_key
	xref turn_left_key
	xref turn_right_key
	xref fire_key
	xref operate_key
	xref run_key
	xref sidestep_left_key
	xref sidestep_right_key
	xref duck_key
	xref jump_key
	xref look_up_key
	xref look_down_key
	xref next_weapon_key
	xref _draw_Palette_vw
	xref Aud_SampleNum_w
	xref Aud_SampleList_vl
	xref Aud_NoiseVol_w
	xref Aud_ChannelPick_b
	xref _Vid_GammaIncTables_vb
	xref _Vid_ContrastAdjust_w
	xref _Vid_BrightnessOffset_w
	xref _Vid_GammaLevel_b
	xref _mnu_bltbusy
	xref _mnu_background
	xref _mnu_screen
	xref _mnu_morescreen
	xref _draw_BorderChars_vb
	xref _draw_DisplayAmmoCount_w
	xref _draw_DisplayEnergyCount_w
	xref _Plr_MultiplayerType_b
	xref _Plr1_Weapons_vb
	xref _Plr2_Weapons_vb
	xref _Plr1_TmpGunSelected_b
	xref _Plr2_TmpGunSelected_b

MOUSE_X	equ	$F0730
MOUSE_Y	equ	$F0734
MOUSE_BUTTONS	equ	$F0738
RTC_MONO_USEC_LO	equ	$F075C
RTC_MONO_USEC_HI	equ	$F0760
RTC_MONO_HZ		equ	1000000
MOUSE_CTRL	equ	$F074C
MOUSE_DX	equ	$F0754
MOUSE_DY	equ	$F0758
GAMEPAD_STATUS	equ	$F25C0
GAMEPAD_PAD0	equ	$F25D0
JOY_UP		equ	$00000001
JOY_DOWN	equ	$00000002
JOY_LEFT	equ	$00000004
JOY_RIGHT	equ	$00000008
JOY_A		equ	$00000010
JOY_B		equ	$00000020
JOY_X		equ	$00000040
JOY_Y		equ	$00000080
JOY_LB		equ	$00000100
JOY_RB		equ	$00000200
JOY_START	equ	$00002000
IE_GAMEPAD_ENGAGE	equ	8192
IE_GAMEPAD_RELEASE	equ	6144
IE_PAD_FORWARD	equ	0
IE_PAD_BACKWARD	equ	1
IE_PAD_STEP_LEFT	equ	2
IE_PAD_STEP_RIGHT	equ	3
IE_PAD_TURN_LEFT	equ	4
IE_PAD_TURN_RIGHT	equ	5
IE_PAD_LOOK_UP	equ	6
IE_PAD_LOOK_DOWN	equ	7
IE_PAD_FIRE	equ	8
IE_PAD_USE	equ	9
IE_PAD_DUCK	equ	10
IE_PAD_JUMP	equ	11
IE_PAD_RUN	equ	12
IE_PAD_NEXT_WEAPON	equ	13
IE_PAD_PAUSE	equ	14
CHUNKY_BASE	equ	$100000
CHUNKY_BACK_BASE	equ	$113000
PRESENT_BASE	equ	$126000
SCALE_BASE	equ	$240000
SCALE_BACK_BASE	equ	$28B000
SCREEN_WIDTH	equ	320
SCREEN_HEIGHT	equ	240
DISPLAY_WIDTH	equ	640
DISPLAY_HEIGHT	equ	480
MENU_ROW_BYTES	equ	40
MENU_PLANE_HEIGHT	equ	256
MENU_PLANESIZE	equ	MENU_ROW_BYTES*MENU_PLANE_HEIGHT
MENU_FRAME_BYTES	equ	SCREEN_WIDTH*SCREEN_HEIGHT
PRESENT_FRAME_BYTES	equ	DISPLAY_WIDTH*DISPLAY_HEIGHT
SMALL_WIDTH	equ	192
SMALL_HEIGHT	equ	160
SMALL_XPOS	equ	64
SMALL_YPOS	equ	20
IE_HUD_COUNTER_H	equ	7
IE_HUD_SLOT_W		equ	8
IE_HUD_SLOT_H		equ	5
IE_HUD_AMMO_X		equ	160
IE_HUD_COUNTER_Y	equ	222
IE_HUD_ENERGY_X		equ	272
IE_HUD_SLOTS_X		equ	24
IE_HUD_SLOTS_Y		equ	224
IE_HUD_DIGIT_BYTES	equ	8*7*10
IE_HUD_SLOT_BYTES	equ	8*5*10
MODE_640x480	equ	$00
MODE_320x240	equ	$05
IE_VIDEO_MODE	equ	MODE_640x480
VIDEO_CTRL	equ	$F0000
VIDEO_MODE	equ	$F0004
BLT_CTRL	equ	$F001C
BLT_OP	equ	$F0020
BLT_SRC	equ	$F0024
BLT_DST	equ	$F0028
BLT_WIDTH	equ	$F002C
BLT_HEIGHT	equ	$F0030
BLT_SRC_STRIDE	equ	$F0034
BLT_DST_STRIDE	equ	$F0038
BLT_COLOR	equ	$F003C
VIDEO_PAL_INDEX	equ	$F0078
VIDEO_PAL_DATA	equ	$F007C
VIDEO_COLOR_MODE	equ	$F0080
VIDEO_FB_BASE	equ	$F0084
BLT_FLAGS	equ	$F0488
BLT_STATUS	equ	$F0044
BLT_OP_FILL	equ	1
BLT_OP_SCALE	equ	7
BLT_OP_MEMCOPY	equ	8
BLT_FLAGS_BPP_CLUT8	equ	1
BLT_FLAGS_CLUT8_COPY	equ	(3<<4)|BLT_FLAGS_BPP_CLUT8
BLT_SCALE_DISPLAY	equ	(DISPLAY_HEIGHT<<16)|DISPLAY_WIDTH
FAKE_LIB_BASE	equ	$6F0000
FAKE_VEC_BYTES	equ	$0800
FAKE_LVO_WAITTOF	equ	-270
EDGE_POINT_ID_LIST_END	equ	-4
IE_SCANCODE_NONE	equ	$FF
RAWKEY_CTRL	equ	$63
RAWKEY_LSHIFT	equ	$60
RAWKEY_LALT	equ	$64
RAWKEY_P	equ	$19
RAWKEY_UP	equ	$4C
RAWKEY_DOWN	equ	$4D
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
	lea		ie_keyboard_state_vb,a1
	move.w	#255,d0
.clear_keys:
	clr.b	(a0)+
	clr.b	(a1)+
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

ie_wait_tof:
	bsr		ie_wait_vblank
	bsr		ie_run_vblank
	rts

ie_run_vblank:
	tst.w	ie_vblank_busy_w
	bne.s	.done
	st		ie_vblank_busy_w
	movem.l	d0-d7/a0-a6,-(sp)
	jsr		_VBlankInterrupt
	movem.l	(sp)+,d0-d7/a0-a6
	clr.w	ie_vblank_busy_w
.done:
	rts

ie_poll_input:
	IFD		IE_BLITTER_TEST
	bsr		ie_blitter_test_dispatch
	ENDC
	bsr		ie_poll_keyboard
	bsr		ie_poll_mouse
	bsr		_ReadJoy1
	rts

_Sys_MarkTime:
	bsr		ie_fps_read_usec
	tst.l	a0
	beq.s	.no_store
	move.l	d1,(a0)
	move.l	d0,4(a0)
.no_store:
	move.l	#RTC_MONO_HZ,d0
	rts

_Sys_FrameLap:
	movem.l	d0-d3/a0,-(sp)
	IFD		IE_FPS_TEST
	lea		ie_fps_test_mark_ecv_q,a0
	bsr		_Sys_MarkTime
	move.l	d0,ie_fps_test_mark_rate_l
	ENDC
	bsr		ie_fps_read_usec
	move.l	_Sys_PrevFrameTimeECV_q+4,d2
	move.l	d1,_Sys_FrameTimeECV_q
	move.l	d0,_Sys_FrameTimeECV_q+4
	move.l	d1,_Sys_PrevFrameTimeECV_q
	move.l	d0,_Sys_PrevFrameTimeECV_q+4
	tst.l	d2
	beq.s	.first_sample
	sub.l	d2,d0
	beq.s	.first_sample
	cmpi.l	#1000000,d0
	bls.s	.sample_ok
	move.l	#1000000,d0
.sample_ok:
	move.l	_Sys_FrameNumber_l,d1
	andi.l	#7,d1
	lsl.l	#2,d1
	lea		_Sys_FrameTimes_vl,a0
	move.l	d0,0(a0,d1.l)
	addq.l	#1,_Sys_FrameNumber_l
	bra.s	.frame_done
.first_sample:
	addq.l	#1,_Sys_FrameNumber_l
.frame_done:
	movem.l	(a7)+,d0-d3/a0
	rts

_Sys_EvalFPS:
	movem.l	d0-d4/a0,-(sp)
	IFD		IE_FPS_TEST
	tst.b	ie_fps_test_force_samples_b
	beq.s	.test_samples_done
	moveq	#0,d3
	move.b	ie_fps_test_force_samples_b,d3
	clr.b	ie_fps_test_force_samples_b
	st		ie_fps_test_capture_b
	lea		_Sys_FrameTimes_vl,a0
	moveq	#7,d1
	move.l	#20000,d2
	cmpi.b	#2,d3
	bne.s	.test_sample_value_done
	move.l	#250000,d2
.test_sample_value_done:
.test_samples:
	move.l	d2,(a0)+
	dbra	d1,.test_samples
.test_samples_done:
	ENDC
	IFD		IE_FPS_TEST
	tst.b	ie_fps_test_capture_b
	bne.s	.eval_enabled
	ENDC
	tst.b	_Prefs_DisplayFPS_b
	beq		.eval_done
.eval_enabled:
	IFD		IE_FPS_TEST
	addq.l	#1,ie_fps_test_eval_count_l
	ENDC
	lea		_Sys_FrameTimes_vl,a0
	moveq	#0,d0
	moveq	#7,d1
.sum_samples:
	add.l	(a0)+,d0
	dbra	d1,.sum_samples
	beq.s	.eval_done
	lsr.l	#3,d0
	beq.s	.eval_done
	move.l	#10000000,d1
.fit_divisor:
	cmpi.l	#65535,d0
	bls.s	.divide
	lsr.l	#1,d0
	lsr.l	#1,d1
	bra.s	.fit_divisor
.divide:
	divu.w	d0,d1
	move.w	d1,d2
	moveq	#0,d3
	move.w	d2,d3
	divu.w	#10,d3
	move.w	d3,_Sys_FPSIntAvg_w
	swap	d3
	move.w	d3,_Sys_FPSFracAvg_w
.eval_done:
	IFD		IE_FPS_TEST
	tst.b	ie_fps_test_capture_b
	beq.s	.test_capture_done
	clr.b	ie_fps_test_capture_b
	move.w	_Sys_FPSIntAvg_w,ie_fps_test_result_w
	move.w	_Sys_FPSFracAvg_w,ie_fps_test_result_w+2
.test_capture_done:
	ENDC
	movem.l	(a7)+,d0-d4/a0
	rts

_Sys_ShowFPS:
	clr.b	ie_fps_pending_b
	tst.b	_Prefs_DisplayFPS_b
	beq.s	.request_done
	st		ie_fps_pending_b
.request_done:
	rts

ie_draw_fps:
	tst.b	_Prefs_DisplayFPS_b
	beq		.draw_done
	movem.l	d0-d7/a0-a6,-(sp)
	move.l	_Vid_FastBufferPtr_l,a6
	tst.l	a6
	bne.s	.have_fps_fb
	move.l	#CHUNKY_BASE,a6
.have_fps_fb:
	IFD		IE_FPS_TEST
	clr.b	ie_fps_test_render_digit_count_b
	st		ie_fps_test_render_trace_b
	ENDC
	lea		ie_hud_digits_good,a3
	moveq	#0,d0
	move.w	_Sys_FPSIntAvg_w,d0
	cmpi.w	#999,d0
	bls.s	.integer_ok
	move.w	#999,d0
.integer_ok:
	moveq	#0,d4
	move.w	d0,d4
	divu.w	#100,d4
	move.w	d4,d5
	swap	d4
	move.w	d4,d0
	moveq	#0,d4
	move.w	d0,d4
	divu.w	#10,d4
	move.w	d4,d6
	swap	d4
	move.w	d4,d7
	move.w	d5,d0
	move.w	#192,d1
	bsr		ie_hud_draw_counter_digit
	move.w	d6,d0
	move.w	#200,d1
	bsr		ie_hud_draw_counter_digit
	move.w	d7,d0
	move.w	#208,d1
	bsr		ie_hud_draw_counter_digit
	move.l	a6,a0
	adda.l	#(IE_HUD_COUNTER_Y*SCREEN_WIDTH)+218,a0
	IFD		IE_FPS_TEST
	move.l	a0,d0
	sub.l	a6,d0
	move.l	d0,ie_fps_test_decimal_offset_l
	ENDC
	move.b	#255,(a0)
	move.b	#255,1(a0)
	move.b	#255,SCREEN_WIDTH(a0)
	move.b	#255,SCREEN_WIDTH+1(a0)
	moveq	#0,d0
	move.w	_Sys_FPSFracAvg_w,d0
	andi.w	#15,d0
	move.w	#224,d1
	bsr		ie_hud_draw_counter_digit
	IFD		IE_FPS_TEST
	clr.b	ie_fps_test_render_trace_b
	addq.l	#1,ie_fps_test_render_count_l
	ENDC
	movem.l	(a7)+,d0-d7/a0-a6
.draw_done:
	rts

; Read the split monotonic counter high-low-high so a low-word rollover cannot
; produce a mismatched EClockVal. Frame deltas use unsigned low-word subtraction,
; which remains correct across one rollover because frames are under 71 minutes.
ie_fps_read_usec:
	move.l	a0,-(a7)
	move.l	#RTC_MONO_USEC_HI,a0
.retry:
	move.l	(a0),d1
	move.l	-4(a0),d0
	cmp.l	(a0),d1
	bne.s	.retry
	move.l	(a7)+,a0
	rts

_Sys_ReadMouse:
	; The IE game control path calls ie_poll_input immediately before
	; Plr*_MouseControl. Polling again here consumes the same mouse delta
	; before the player code can use it.
	rts

ie_poll_mouse:
	movem.l	d2-d4/a0,-(sp)
	bsr		ie_poll_mouse_x
	tst.l	ie_mouse_relative_ok
	beq.s	.abs_mode
	move.l	MOUSE_DY,d0
	bra.s	.apply_dy
.abs_mode:
	move.l	MOUSE_Y,d0
	move.l	d0,d1
	sub.l	ie_mouse_last_abs_y,d1
	move.l	d0,ie_mouse_last_abs_y
	move.l	d1,d0
.apply_dy:
	add.w	d0,_Sys_MouseY
	bsr		ie_read_mouse_buttons
	tst.l	ie_menu_active
	beq.s	.not_menu_buttons
	move.l	d0,d1
	move.l	ie_menu_last_buttons,d2
	eor.l	d2,d1
	move.l	d0,ie_menu_last_buttons
	btst	#0,d1
	beq.s	.no_menu_left_edge
	btst	#0,d0
	beq.s	.no_menu_left_edge
	move.b	#$44,lastpressed
.no_menu_left_edge:
	btst	#1,d1
	beq.s	.not_menu_buttons
	btst	#1,d0
	beq.s	.not_menu_buttons
	move.b	#$45,lastpressed
.not_menu_buttons:
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
	movem.l	(sp)+,d2-d4/a0
	rts

ie_poll_mouse_x:
	tst.l	ie_menu_active
	beq.s	.not_menu
	clr.w	ie_mouse_delta_x_w
	move.l	MOUSE_X,ie_mouse_last_abs_x
	bra.s	.done
.not_menu:
	tst.l	ie_mouse_relative_ok
	beq.s	.abs_mode
	move.l	MOUSE_DX,d0
	bra.s	.have_dx
.abs_mode:
	move.l	MOUSE_X,d0
	move.l	d0,d1
	sub.l	ie_mouse_last_abs_x,d1
	move.l	d0,ie_mouse_last_abs_x
	move.l	d1,d0
.have_dx:
	add.w	d0,ie_mouse_delta_x_w
.done:
	rts

_Vid_OpenMainScreen:
	move.l	#1,VIDEO_CTRL
	move.l	#IE_VIDEO_MODE,VIDEO_MODE
	move.l	#1,VIDEO_COLOR_MODE
	move.l	#SCALE_BASE,VIDEO_FB_BASE
	move.l	#CHUNKY_BASE,_Vid_FastBufferPtr_l
	move.l	#CHUNKY_BASE,_Vid_Screen1Ptr_l
	move.l	#CHUNKY_BACK_BASE,_Vid_Screen2Ptr_l
	move.l	#CHUNKY_BASE,_Vid_DrawScreenPtr_l
	move.l	#CHUNKY_BASE,_Vid_DisplayScreenPtr_l
	move.l	#CHUNKY_BASE,_Vid_ScreenBuffers_vl
	move.l	#CHUNKY_BACK_BASE,_Vid_ScreenBuffers_vl+4
	clr.w	_Vid_ScreenBufferIndex_w
	clr.w	_Vid_LetterBoxMarginHeight_w
	st		_Vid_FullScreen_b
	st		_Vid_FullScreenTemp_b
	move.w	#SCREEN_WIDTH,_Vid_RightX_w
	clr.b	_Vid_DoubleHeight_b
	clr.b	_Vid_DoubleWidth_b
	move.l	#1,ie_mouse_relative_ok
	move.l	#1,MOUSE_CTRL
	move.l	MOUSE_X,ie_mouse_last_abs_x
	move.l	MOUSE_Y,ie_mouse_last_abs_y
	bsr		_Vid_LoadMainPalette
	bsr		ie_hud_init
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
	tst.l	ie_menu_active
	bne.s	.mode_ready
	st		_Vid_FullScreen_b
	st		_Vid_FullScreenTemp_b
	move.w	#SCREEN_WIDTH,_Vid_RightX_w
	clr.b	_Vid_DoubleHeight_b
	clr.b	_Vid_DoubleWidth_b
	bsr		ie_draw_game_hud
	tst.b	ie_fps_pending_b
	beq.s	.fps_done
	clr.b	ie_fps_pending_b
	bsr		ie_draw_fps
.fps_done:
	IFD		IE_FPS_TEST
	move.l	_Vid_FastBufferPtr_l,a0
	tst.l	a0
	bne.s	.test_have_fps_fb
	move.l	#CHUNKY_BASE,a0
.test_have_fps_fb:
	adda.l	#(IE_HUD_COUNTER_Y*SCREEN_WIDTH)+218,a0
	lea		ie_fps_test_present_decimal_b,a1
	move.b	(a0),(a1)+
	move.b	1(a0),(a1)+
	move.b	SCREEN_WIDTH(a0),(a1)+
	move.b	SCREEN_WIDTH+1(a0),(a1)+
	ENDC
.mode_ready:
	tst.b	_Vid_FullScreen_b
	bne.s	.present_full
	bsr		ie_present_small
	bsr		ie_clear_presented_source
	rts
.present_full:
	bsr		ie_scale_to_display
	rts

_Draw_ResetGameDisplay:
	movem.l	d0-d3/a0,-(sp)
	clr.l	ie_menu_active
	move.l	#1,ie_mouse_relative_ok
	move.l	#1,MOUSE_CTRL
	st		_Vid_FullScreen_b
	st		_Vid_FullScreenTemp_b
	move.w	#SCREEN_WIDTH,_Vid_RightX_w
	clr.b	_Vid_DoubleHeight_b
	clr.b	_Vid_DoubleWidth_b
	lea		CHUNKY_BASE,a0
	moveq	#0,d0
	move.l	#SCREEN_WIDTH,d0
	move.l	#SCREEN_HEIGHT,d1
	move.l	#SCREEN_WIDTH,d2
	moveq	#0,d3
	bsr		ie_blt_fill_clut8
	lea		CHUNKY_BACK_BASE,a0
	bsr		ie_blt_fill_clut8
	lea		PRESENT_BASE,a0
	bsr		ie_blt_fill_clut8
	clr.w	ie_present_index_w
	move.l	#SCALE_BASE,VIDEO_FB_BASE
	movem.l	(sp)+,d0-d3/a0
	rts

; Match the original RTG small-screen path: copy the 192x160
; chunky render area into the centred 320x240 display buffer.
ie_present_small:
	movem.l	d0-d2/a0-a2,-(sp)
	lea		PRESENT_BASE,a1
	move.l	a1,a2
	moveq	#0,d0
	move.w	#((SCREEN_WIDTH*SCREEN_HEIGHT/4)-1),d1
.clear_present:
	move.l	d0,(a1)+
	dbra	d1,.clear_present
	lea		(SMALL_YPOS*SCREEN_WIDTH)+SMALL_XPOS(a2),a1
	move.w	#(SMALL_HEIGHT-1),d2
.copy_row:
	move.w	#(SMALL_WIDTH/4-1),d1
.copy_long:
	move.l	(a0)+,(a1)+
	dbra	d1,.copy_long
	adda.w	#(SCREEN_WIDTH-SMALL_WIDTH),a0
	adda.w	#(SCREEN_WIDTH-SMALL_WIDTH),a1
	dbra	d2,.copy_row
	move.l	a2,a0
	bsr		ie_scale_to_display
	movem.l	(sp)+,d0-d2/a0-a2
	rts

ie_scale_to_display:
	movem.l	d0/a1,-(sp)
	lea		SCALE_BASE,a1
	tst.w	ie_present_index_w
	beq.s	.have_target
	lea		SCALE_BACK_BASE,a1
.have_target:
	move.l	#BLT_OP_SCALE,BLT_OP
	move.l	a0,BLT_SRC
	move.l	a1,BLT_DST
	move.l	#SCREEN_WIDTH,BLT_WIDTH
	move.l	#SCREEN_HEIGHT,BLT_HEIGHT
	move.l	#SCREEN_WIDTH,BLT_SRC_STRIDE
	move.l	#DISPLAY_WIDTH,BLT_DST_STRIDE
	move.l	#BLT_SCALE_DISPLAY,BLT_COLOR
	move.l	#BLT_FLAGS_BPP_CLUT8,BLT_FLAGS
	move.l	#1,BLT_CTRL
	move.l	a1,VIDEO_FB_BASE
	eori.w	#1,ie_present_index_w
	movem.l	(sp)+,d0/a1
	rts

; a0=destination, d0=width, d1=height, d2=destination stride, d3=colour.
; IEVideo executes synchronously, so the destination is complete on return.
ie_blt_fill_clut8:
	move.l	#BLT_OP_FILL,BLT_OP
	move.l	a0,BLT_DST
	move.l	d0,BLT_WIDTH
	move.l	d1,BLT_HEIGHT
	move.l	d2,BLT_DST_STRIDE
	move.l	d3,BLT_COLOR
	move.l	#BLT_FLAGS_BPP_CLUT8,BLT_FLAGS
	move.l	#1,BLT_CTRL
	IFD		IE_BLITTER_TEST
	addq.l	#1,ie_blitter_test_fill_count_l
	bsr		ie_blt_test_status
	ENDC
	rts

; a0=source, a1=destination, d0=byte count.  MEMCOPY is equivalent to
; the legacy non-overlapping byte loops used by the menu.
ie_blt_memcopy:
	move.l	#BLT_OP_MEMCOPY,BLT_OP
	move.l	a0,BLT_SRC
	move.l	a1,BLT_DST
	move.l	d0,BLT_WIDTH
	move.l	#1,BLT_HEIGHT
	move.l	d0,BLT_SRC_STRIDE
	move.l	d0,BLT_DST_STRIDE
	move.l	#BLT_FLAGS_CLUT8_COPY,BLT_FLAGS
	move.l	#1,BLT_CTRL
	IFD		IE_BLITTER_TEST
	addq.l	#1,ie_blitter_test_copy_count_l
	bsr		ie_blt_test_status
	ENDC
	rts

ie_blt_test_status:
	IFD		IE_BLITTER_TEST
	move.l	BLT_STATUS,d0
	btst	#0,d0
	beq.s		.ok
	move.l	d0,ie_blitter_test_error_l
.ok:
	ENDC
	rts

	IFD		IE_BLITTER_TEST
; IEScript seeds the guarded scratch area and requests one helper operation.
; This exercises non-trivial dimensions without exposing test state in release.
ie_blitter_test_dispatch:
	movem.l	d0-d3/a0-a1,-(sp)
	move.w	ie_blitter_test_command_w,d0
	beq.s		.done
	clr.w	ie_blitter_test_command_w
	cmpi.w	#1,d0
	bne.s		.try_copy
	lea		ie_blitter_test_scratch_vb+16,a0
	move.l	#17,d0
	move.l	#3,d1
	move.l	#23,d2
	moveq	#0,d3
	bsr		ie_blt_fill_clut8
	bra.s		.complete
.try_copy:
	cmpi.w	#2,d0
	bne.s		.bad_command
	lea		ie_blitter_test_scratch_vb+16,a0
	lea		ie_blitter_test_scratch_vb+272,a1
	move.l	#73,d0
	bsr		ie_blt_memcopy
	bra.s		.complete
.bad_command:
	move.l	#$FFFFFFFF,ie_blitter_test_error_l
.complete:
	addq.w	#1,ie_blitter_test_done_w
.done:
	movem.l	(sp)+,d0-d3/a0-a1
	rts
	ENDC

ie_clear_presented_source:
	movem.l	d0-d2/a0,-(sp)
	move.l	_Vid_FastBufferPtr_l,a0
	tst.l	a0
	bne.s	.have_fb
	move.l	#CHUNKY_BASE,a0
.have_fb:
	moveq	#0,d0
	move.w	#(SMALL_HEIGHT-1),d2
.row:
	move.w	#(SMALL_WIDTH/4-1),d1
.long:
	move.l	d0,(a0)+
	dbra	d1,.long
	adda.w	#(SCREEN_WIDTH-SMALL_WIDTH),a0
	dbra	d2,.row
	movem.l	(sp)+,d0-d2/a0
	rts

ie_hud_init:
	movem.l	d0-d1/a0-a1,-(sp)
	lea		_draw_BorderChars_vb+(15*8*10),a0
	lea		ie_hud_digits_warn,a1
	moveq	#8,d0
	moveq	#7,d1
	bsr		ie_hud_convert_group
	lea		_draw_BorderChars_vb+(15*8*10)+(7*8*10),a0
	lea		ie_hud_digits_good,a1
	moveq	#8,d0
	moveq	#7,d1
	bsr		ie_hud_convert_group
	lea		_draw_BorderChars_vb,a0
	lea		ie_hud_slots_unavailable,a1
	moveq	#8,d0
	moveq	#5,d1
	bsr		ie_hud_convert_group
	lea		_draw_BorderChars_vb+(5*10*8),a0
	lea		ie_hud_slots_found,a1
	moveq	#8,d0
	moveq	#5,d1
	bsr		ie_hud_convert_group
	lea		_draw_BorderChars_vb+(5*10*8*2),a0
	lea		ie_hud_slots_selected,a1
	moveq	#8,d0
	moveq	#5,d1
	bsr		ie_hud_convert_group
	movem.l	(sp)+,d0-d1/a0-a1
	rts

; Convert the 8-plane border glyph layout used by the C RTG HUD into
; contiguous chunky CLUT8 glyphs, one digit/slot after another.
ie_hud_convert_group:
	movem.l	d2-d7/a0-a6,-(sp)
	moveq	#0,d7
.digit_loop:
	lea		0(a0,d7.w),a2
	move.w	d1,d6
	subq.w	#1,d6
.row_loop:
	moveq	#7,d5
.pixel_loop:
	moveq	#0,d4
	moveq	#0,d3
	moveq	#1,d2
.plane_loop:
	move.b	0(a2,d3.w),d0
	btst	d5,d0
	beq.s	.plane_clear
	or.b	d2,d4
.plane_clear:
	lsl.w	#1,d2
	addq.w	#1,d3
	adda.w	#9,a2
	cmp.w	#8,d3
	blt.s	.plane_loop
	suba.l	#72,a2
	move.b	d4,(a1)+
	dbra	d5,.pixel_loop
	adda.l	#80,a2
	dbra	d6,.row_loop
	addq.w	#1,d7
	cmp.w	#10,d7
	blt.s	.digit_loop
	movem.l	(sp)+,d2-d7/a0-a6
	rts

ie_draw_game_hud:
	movem.l	d0-d7/a0-a6,-(sp)
	move.l	_Vid_FastBufferPtr_l,a6
	tst.l	a6
	bne.s	.have_fb
	move.l	#CHUNKY_BASE,a6
.have_fb:
	bsr		ie_hud_draw_slots
	move.w	_draw_DisplayAmmoCount_w,d0
	move.w	#IE_HUD_AMMO_X,d1
	bsr		ie_hud_draw_counter
	move.w	_draw_DisplayEnergyCount_w,d0
	move.w	#IE_HUD_ENERGY_X,d1
	bsr		ie_hud_draw_counter
	movem.l	(sp)+,d0-d7/a0-a6
	rts

ie_hud_draw_slots:
	move.b	_Plr_MultiplayerType_b,d0
	cmp.b	#'s',d0
	beq.s	.player2
	lea		_Plr1_Weapons_vb,a4
	moveq	#0,d6
	move.b	_Plr1_TmpGunSelected_b,d6
	bra.s	.have_player
.player2:
	lea		_Plr2_Weapons_vb,a4
	moveq	#0,d6
	move.b	_Plr2_TmpGunSelected_b,d6
.have_player:
	moveq	#0,d7
.slot_loop:
	lea		ie_hud_slots_unavailable,a2
	cmp.w	d7,d6
	beq.s	.selected
	tst.w	0(a4,d7.w*2)
	beq.s	.have_glyph
	lea		ie_hud_slots_found,a2
	bra.s	.have_glyph
.selected:
	lea		ie_hud_slots_selected,a2
.have_glyph:
	move.w	d7,d0
	mulu.w	#IE_HUD_SLOT_BYTES/10,d0
	adda.l	d0,a2
	move.w	d7,d0
	mulu.w	#IE_HUD_SLOT_W,d0
	addi.w	#IE_HUD_SLOTS_X,d0
	move.w	d0,d1
	move.w	#IE_HUD_SLOTS_Y,d2
	move.w	#IE_HUD_SLOT_W,d3
	move.w	#IE_HUD_SLOT_H,d4
	bsr		ie_hud_draw_glyph
	addq.w	#1,d7
	cmp.w	#10,d7
	blt.s	.slot_loop
	rts

ie_hud_draw_counter:
	cmpi.w	#999,d0
	bls.s	.count_ok
	move.w	#999,d0
.count_ok:
	lea		ie_hud_digits_warn,a3
	cmpi.w	#9,d0
	bls.s	.have_digit_group
	lea		ie_hud_digits_good,a3
.have_digit_group:
	moveq	#0,d4
	move.w	d0,d4
	divu.w	#100,d4
	move.w	d4,d5
	swap	d4
	move.w	d4,d0
	moveq	#0,d4
	move.w	d0,d4
	divu.w	#10,d4
	move.w	d4,d6
	swap	d4
	move.w	d4,d7

	move.w	d5,d0
	move.w	d1,d5
	bsr		ie_hud_draw_counter_digit
	move.w	d6,d0
	move.w	d5,d1
	addq.w	#8,d1
	bsr		ie_hud_draw_counter_digit
	move.w	d7,d0
	move.w	d5,d1
	addi.w	#16,d1
	bsr		ie_hud_draw_counter_digit
	rts

ie_hud_draw_counter_digit:
	IFD		IE_FPS_TEST
	tst.b	ie_fps_test_render_trace_b
	beq.s	.test_trace_done
	moveq	#0,d2
	move.b	ie_fps_test_render_digit_count_b,d2
	cmpi.b	#4,d2
	bhs.s	.test_trace_done
	lea		ie_fps_test_render_digit_x_w,a0
	move.w	d1,0(a0,d2.w*2)
	addq.b	#1,ie_fps_test_render_digit_count_b
.test_trace_done:
	ENDC
	lea		0(a3),a2
	mulu.w	#IE_HUD_DIGIT_BYTES/10,d0
	adda.l	d0,a2
	move.w	#IE_HUD_COUNTER_Y,d2
	move.w	#8,d3
	move.w	#IE_HUD_COUNTER_H,d4

ie_hud_draw_glyph:
	movem.l	d0-d7/a0-a2,-(sp)
	move.l	a6,a0
	moveq	#0,d0
	move.w	d2,d0
	mulu.w	#SCREEN_WIDTH,d0
	adda.l	d0,a0
	adda.w	d1,a0
	move.w	d4,d7
	subq.w	#1,d7
.row:
	move.w	d3,d6
	subq.w	#1,d6
	move.l	a0,a1
.pixel:
	move.b	(a2)+,(a1)+
	dbra	d6,.pixel
	adda.w	#SCREEN_WIDTH,a0
	dbra	d7,.row
	movem.l	(sp)+,d0-d7/a0-a2
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
_Game_LevelFailed:
_Game_UpdatePlayerProgress:
_Game_ApplyInventoryLimits:
_Zone_InitEdgePVS:
_Zone_ApplyPVSErrata:
_Zone_FreeEdgePVS:
	rts

_Game_AddToInventory:
	movem.l	d0-d1/d7/a0-a3,-(sp)
	lea		44(a0),a3
	moveq	#11,d7
.items_loop:
	move.w	(a2)+,d0
	or.w	d0,(a3)+
	dbra	d7,.items_loop
	moveq	#21,d7
.consumables_loop:
	move.w	(a1)+,d0
	beq.s	.next_consumable
	move.w	(a0),d1
	add.w	d0,d1
	bcc.s	.store_consumable
	moveq	#-1,d1
.store_consumable:
	move.w	d1,(a0)
.next_consumable:
	addq.l	#2,a0
	dbra	d7,.consumables_loop
	movem.l	(sp)+,d0-d1/d7/a0-a3
	rts

_Game_LevelBegin:
	IFD		IE_GAMEPAD_TEST
	addq.l	#1,ie_gamepad_test_level_begin_l
	ENDC
	clr.l	ie_menu_active
	move.l	#1,ie_mouse_relative_ok
	move.l	#1,MOUSE_CTRL
	st		_Vid_FullScreen_b
	st		_Vid_FullScreenTemp_b
	move.w	#SCREEN_WIDTH,_Vid_RightX_w
	clr.b	_Vid_DoubleHeight_b
	clr.b	_Vid_DoubleWidth_b
	rts

_mnu_setscreen:
	movem.l	d0-d7/a0-a6,-(sp)
	tst.l	ie_menu_active
	bne.s	.already_active
	move.l	#1,ie_menu_active
	clr.l	ie_mouse_relative_ok
	clr.l	MOUSE_CTRL
	clr.b	lastpressed
	lea		_KeyMap_vb,a0
	move.w	#255,d0
.clear_menu_keys:
	clr.b	(a0)+
	dbra	d0,.clear_menu_keys
	bsr		ie_read_mouse_buttons
	move.l	d0,ie_menu_last_buttons
	move.l	#1,VIDEO_CTRL
	move.l	#IE_VIDEO_MODE,VIDEO_MODE
	move.l	#1,VIDEO_COLOR_MODE
	move.l	#SCALE_BASE,VIDEO_FB_BASE
	bsr		ie_menu_upload_palette
	bsr		ie_menu_copy_background
	bsr		ie_menu_render_frame
	bsr		ie_menu_fade_in
	bra.s	.done
.already_active:
	clr.l	ie_mouse_relative_ok
	clr.l	MOUSE_CTRL
	bsr		ie_menu_upload_palette
.done:
	movem.l	(sp)+,d0-d7/a0-a6
	moveq	#1,d0
	rts

_mnu_clearscreen:
	movem.l	d0-d1/a0,-(sp)
	tst.l	ie_menu_active
	beq.s	.no_fade
	bsr		ie_menu_fade_out
.no_fade:
	clr.l	ie_menu_active
	move.l	#1,ie_mouse_relative_ok
	move.l	#1,MOUSE_CTRL
	bsr		_Vid_LoadMainPalette
	bsr		_Draw_ResetGameDisplay
	movem.l	(sp)+,d0-d1/a0
	rts

_mnu_movescreen:
	tst.l	ie_menu_active
	beq.s	.no_menu_render
	bsr		ie_menu_render_frame
.no_menu_render:
	rts

_mnu_dofire:
	movem.l	d0-d2/a0-a1,-(sp)
	addq.w	#1,ie_menu_fire_phase_w
	move.w	ie_menu_fire_phase_w,d0
	andi.w	#$000F,d0
	mulu.w	#MENU_ROW_BYTES,d0
	lea		_mnu_morescreen,a0
	lea		_mnu_morescreen+(3*MENU_PLANESIZE),a1
	adda.l	d0,a1
	exg		a0,a1
	move.l	#SCREEN_HEIGHT*MENU_ROW_BYTES,d0
	bsr		ie_blt_memcopy
	move.w	ie_menu_fire_phase_w,d0
	addq.w	#5,d0
	andi.w	#$000F,d0
	mulu.w	#MENU_ROW_BYTES,d0
	lea		_mnu_morescreen+MENU_PLANESIZE,a0
	lea		_mnu_morescreen+(4*MENU_PLANESIZE),a1
	adda.l	d0,a1
	exg		a0,a1
	move.l	#SCREEN_HEIGHT*MENU_ROW_BYTES,d0
	bsr		ie_blt_memcopy
	move.w	ie_menu_fire_phase_w,d0
	addi.w	#10,d0
	andi.w	#$000F,d0
	mulu.w	#MENU_ROW_BYTES,d0
	lea		_mnu_morescreen+(2*MENU_PLANESIZE),a0
	lea		_mnu_morescreen+(5*MENU_PLANESIZE),a1
	adda.l	d0,a1
	exg		a0,a1
	move.l	#SCREEN_HEIGHT*MENU_ROW_BYTES,d0
	bsr		ie_blt_memcopy
	clr.b	_mnu_bltbusy
	movem.l	(sp)+,d0-d2/a0-a1
	rts

_ReadJoy1:
	bsr		ie_gamepad_apply
	IFD		IE_GAMEPAD_TEST
	addq.l	#1,ie_gamepad_test_read_count_l
	ENDC
	rts
_ReadJoy2:
	bsr		ie_poll_keyboard
	rts

; Pad zero is the sole IE controller.  The translator deliberately produces
; the established AB3D2 logical keys; player code remains the only consumer
; of use/duck/weapon edge state.
ie_gamepad_apply:
	movem.l	d0-d4/a0-a1,-(sp)
	bsr		ie_gamepad_read_pad0
	tst.b	d0
	bne.s		.connected
	tst.w	ie_gamepad_actions_w
	bne.s		.clear_disconnected
	tst.w	ie_gamepad_axis_state_w
	bne.s		.clear_disconnected
	tst.w	ie_gamepad_edge_state_w
	beq		.done
.clear_disconnected:
	bsr		ie_gamepad_clear
	bra		.done
.connected:
	lea		_KeyMap_vb,a0
	move.w	ie_gamepad_lxy_l,d0
	neg.w	d0
	moveq	#IE_PAD_FORWARD,d1
	bsr		ie_gamepad_axis_positive
	move.b	d0,d3
	move.l	#JOY_UP,d0
	bsr		ie_gamepad_button_pressed
	or.b	d0,d3
	move.b	d3,d0
	move.b	forward_key,d1
	moveq	#IE_PAD_FORWARD,d2
	bsr		ie_gamepad_set_action
	move.w	ie_gamepad_lxy_l,d0
	moveq	#IE_PAD_BACKWARD,d1
	bsr		ie_gamepad_axis_positive
	move.b	d0,d3
	move.l	#JOY_DOWN,d0
	bsr		ie_gamepad_button_pressed
	or.b	d0,d3
	move.b	d3,d0
	move.b	backward_key,d1
	moveq	#IE_PAD_BACKWARD,d2
	bsr		ie_gamepad_set_action
	move.w	ie_gamepad_lxy_l+2,d0
	neg.w	d0
	moveq	#IE_PAD_STEP_LEFT,d1
	bsr		ie_gamepad_axis_positive
	move.b	sidestep_left_key,d1
	moveq	#IE_PAD_STEP_LEFT,d2
	bsr		ie_gamepad_set_action
	move.w	ie_gamepad_lxy_l+2,d0
	moveq	#IE_PAD_STEP_RIGHT,d1
	bsr		ie_gamepad_axis_positive
	move.b	sidestep_right_key,d1
	moveq	#IE_PAD_STEP_RIGHT,d2
	bsr		ie_gamepad_set_action
	move.w	ie_gamepad_rxy_l+2,d0
	neg.w	d0
	moveq	#IE_PAD_TURN_LEFT,d1
	bsr		ie_gamepad_axis_positive
	move.b	d0,d3
	move.l	#JOY_LEFT,d0
	bsr		ie_gamepad_button_pressed
	or.b	d0,d3
	move.b	d3,d0
	move.b	turn_left_key,d1
	moveq	#IE_PAD_TURN_LEFT,d2
	bsr		ie_gamepad_set_action
	move.w	ie_gamepad_rxy_l+2,d0
	moveq	#IE_PAD_TURN_RIGHT,d1
	bsr		ie_gamepad_axis_positive
	move.b	d0,d3
	move.l	#JOY_RIGHT,d0
	bsr		ie_gamepad_button_pressed
	or.b	d0,d3
	move.b	d3,d0
	move.b	turn_right_key,d1
	moveq	#IE_PAD_TURN_RIGHT,d2
	bsr		ie_gamepad_set_action
	move.w	ie_gamepad_rxy_l,d0
	neg.w	d0
	moveq	#IE_PAD_LOOK_UP,d1
	bsr		ie_gamepad_axis_positive
	move.b	look_up_key,d1
	moveq	#IE_PAD_LOOK_UP,d2
	bsr		ie_gamepad_set_action
	move.w	ie_gamepad_rxy_l,d0
	moveq	#IE_PAD_LOOK_DOWN,d1
	bsr		ie_gamepad_axis_positive
	move.b	look_down_key,d1
	moveq	#IE_PAD_LOOK_DOWN,d2
	bsr		ie_gamepad_set_action
	move.l	#JOY_A,d0
	move.b	fire_key,d1
	moveq	#IE_PAD_FIRE,d2
	bsr		ie_gamepad_map_button
	move.l	#JOY_X,d0
	move.b	operate_key,d1
	moveq	#IE_PAD_USE,d2
	bsr		ie_gamepad_map_button
	move.l	#JOY_B,d0
	move.b	duck_key,d1
	moveq	#IE_PAD_DUCK,d2
	bsr		ie_gamepad_map_edge_button
	move.l	#JOY_Y,d0
	move.b	jump_key,d1
	moveq	#IE_PAD_JUMP,d2
	bsr		ie_gamepad_map_button
	move.l	#JOY_LB,d0
	move.b	run_key,d1
	moveq	#IE_PAD_RUN,d2
	bsr		ie_gamepad_map_button
	move.l	#JOY_RB,d0
	move.b	next_weapon_key,d1
	moveq	#IE_PAD_NEXT_WEAPON,d2
	bsr		ie_gamepad_map_edge_button
	move.l	#JOY_START,d0
	move.b	#RAWKEY_P,d1
	moveq	#IE_PAD_PAUSE,d2
	bsr		ie_gamepad_map_edge_button
.done:
	IFD		IE_GAMEPAD_TEST
	move.w	ie_gamepad_actions_w,ie_gamepad_test_last_actions_w
	ENDC
	movem.l	(sp)+,d0-d4/a0-a1
	rts

ie_gamepad_read_pad0:
	IFD		IE_GAMEPAD_TEST
	tst.b	ie_gamepad_test_enable_b
	beq.s		.mmio
	move.l	ie_gamepad_test_status_l,d0
	btst	#0,d0
	beq.s		.empty
	move.l	ie_gamepad_test_buttons_l,ie_gamepad_buttons_l
	move.l	ie_gamepad_test_lxy_l,ie_gamepad_lxy_l
	move.l	ie_gamepad_test_rxy_l,ie_gamepad_rxy_l
	moveq	#1,d0
	rts
	ENDC
.mmio:
	move.l	GAMEPAD_STATUS,d0
	btst	#0,d0
	beq.s		.empty
	move.l	GAMEPAD_PAD0,ie_gamepad_buttons_l
	move.l	GAMEPAD_PAD0+4,ie_gamepad_lxy_l
	move.l	GAMEPAD_PAD0+8,ie_gamepad_rxy_l
	moveq	#1,d0
	rts
.empty:
	clr.l	ie_gamepad_buttons_l
	clr.l	ie_gamepad_lxy_l
	clr.l	ie_gamepad_rxy_l
	moveq	#0,d0
	rts

; d0=axis magnitude, d1=direction state bit; returns d0=$ff or zero.
ie_gamepad_axis_positive:
	move.w	ie_gamepad_axis_state_w,d4
	btst	d1,d4
	beq.s		.idle
	cmpi.w	#IE_GAMEPAD_RELEASE,d0
	bge.s		.active
	bclr	d1,d4
	move.w	d4,ie_gamepad_axis_state_w
	bra.s		.inactive
.idle:
	cmpi.w	#IE_GAMEPAD_ENGAGE,d0
	blt.s		.inactive
	bset	d1,d4
	move.w	d4,ie_gamepad_axis_state_w
.active:
	moveq	#-1,d0
	rts
.inactive:
	moveq	#0,d0
	rts

; d0=button mask; returns d0=$ff when that bit is pressed.
ie_gamepad_button_pressed:
	and.l	ie_gamepad_buttons_l,d0
	sne		d0
	rts

; d0=button mask, d1=raw key, d2=owned action bit.
ie_gamepad_map_button:
	bsr		ie_gamepad_button_pressed
	bra		ie_gamepad_set_action

; Duck and next-weapon are one press events.  In particular, the AB3D2 duck
; handler consumes its key, so a held controller button must not recreate it
; on the next frame.  Use is level-mapped above because plr_KeyboardControl
; already performs its own rising-edge detection.
ie_gamepad_map_edge_button:
	bsr		ie_gamepad_button_pressed
	tst.b	d0
	beq.s		.released
	move.w	ie_gamepad_edge_state_w,d3
	btst	d2,d3
	bne.s		.held
	bset	d2,d3
	move.w	d3,ie_gamepad_edge_state_w
	IFD		IE_GAMEPAD_TEST
	lea		ie_gamepad_test_edge_counts_vw,a1
	addq.w	#1,0(a1,d2.w*2)
	ENDC
	moveq	#-1,d0
	bra		ie_gamepad_set_action
.held:
	moveq	#0,d0
	bra		ie_gamepad_set_action
.released:
	move.w	ie_gamepad_edge_state_w,d3
	bclr	d2,d3
	move.w	d3,ie_gamepad_edge_state_w
	moveq	#0,d0
	bra		ie_gamepad_set_action

; d0=boolean, d1=raw key, d2=owned action bit, a0=KeyMap_vb.
ie_gamepad_set_action:
	move.w	ie_gamepad_actions_w,d3
	tst.b	d0
	beq.s		.release
	move.b	#$ff,0(a0,d1.w)
	bset	d2,d3
	move.w	d3,ie_gamepad_actions_w
	rts
.release:
	btst	d2,d3
	beq.s		.done
	bclr	d2,d3
	move.w	d3,ie_gamepad_actions_w
	lea		ie_keyboard_state_vb,a1
	tst.b	0(a1,d1.w)
	bne.s		.done
	clr.b	0(a0,d1.w)
.done:
	rts

ie_gamepad_clear:
	movem.l	d0-d2/a0,-(sp)
	clr.w	ie_gamepad_axis_state_w
	clr.w	ie_gamepad_edge_state_w
	lea		_KeyMap_vb,a0
	moveq	#0,d0
	move.b	forward_key,d1
	moveq	#IE_PAD_FORWARD,d2
	bsr		ie_gamepad_set_action
	move.b	backward_key,d1
	moveq	#IE_PAD_BACKWARD,d2
	bsr		ie_gamepad_set_action
	move.b	sidestep_left_key,d1
	moveq	#IE_PAD_STEP_LEFT,d2
	bsr		ie_gamepad_set_action
	move.b	sidestep_right_key,d1
	moveq	#IE_PAD_STEP_RIGHT,d2
	bsr		ie_gamepad_set_action
	move.b	turn_left_key,d1
	moveq	#IE_PAD_TURN_LEFT,d2
	bsr		ie_gamepad_set_action
	move.b	turn_right_key,d1
	moveq	#IE_PAD_TURN_RIGHT,d2
	bsr		ie_gamepad_set_action
	move.b	look_up_key,d1
	moveq	#IE_PAD_LOOK_UP,d2
	bsr		ie_gamepad_set_action
	move.b	look_down_key,d1
	moveq	#IE_PAD_LOOK_DOWN,d2
	bsr		ie_gamepad_set_action
	move.b	fire_key,d1
	moveq	#IE_PAD_FIRE,d2
	bsr		ie_gamepad_set_action
	move.b	operate_key,d1
	moveq	#IE_PAD_USE,d2
	bsr		ie_gamepad_set_action
	move.b	duck_key,d1
	moveq	#IE_PAD_DUCK,d2
	bsr		ie_gamepad_set_action
	move.b	jump_key,d1
	moveq	#IE_PAD_JUMP,d2
	bsr		ie_gamepad_set_action
	move.b	run_key,d1
	moveq	#IE_PAD_RUN,d2
	bsr		ie_gamepad_set_action
	move.b	next_weapon_key,d1
	moveq	#IE_PAD_NEXT_WEAPON,d2
	bsr		ie_gamepad_set_action
	move.b	#RAWKEY_P,d1
	moveq	#IE_PAD_PAUSE,d2
	bsr		ie_gamepad_set_action
	clr.w	ie_gamepad_axis_state_w
	clr.w	ie_gamepad_edge_state_w
	movem.l	(sp)+,d0-d2/a0
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

ie_read_mouse_buttons:
	move.l	MOUSE_BUTTONS,d0
	move.l	d0,d1
	andi.l	#7,d1
	bne.s	.buttons_ready
	swap	d0
	lsr.l	#8,d0
	andi.l	#7,d0
	rts
.buttons_ready:
	move.l	d1,d0
	rts

ie_poll_keyboard:
	lea		_KeyMap_vb,a0
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
	beq.s	.done
	btst	#7,d0
	bne.s	.release
	lea		ie_keyboard_state_vb,a1
	move.b	#$FF,0(a0,d1.w)
	move.b	#$FF,0(a1,d1.w)
	bsr		ie_keyboard_apply_alias_press
	move.b	d1,lastpressed
	bra.s	.done
.release:
	lea		ie_keyboard_state_vb,a1
	clr.b	0(a0,d1.w)
	clr.b	0(a1,d1.w)
	bsr		ie_keyboard_apply_alias_release
.done:
	lea		ie_keyboard_state_vb,a1
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
	clr.b	RAWKEY_LSHIFT(a1)
	bra.s	.mod_shift_done
.mod_shift_down:
	sne		RAWKEY_LSHIFT(a0)
	sne		RAWKEY_LSHIFT(a1)
.mod_shift_done:
	btst	#IE_MOD_CTRL,d0
	bne.s	.mod_ctrl_down
	btst	#IE_MOD_CTRL,d1
	beq.s	.mod_ctrl_done
	clr.b	RAWKEY_CTRL(a0)
	clr.b	RAWKEY_CTRL(a1)
	bra.s	.mod_ctrl_done
.mod_ctrl_down:
	sne		RAWKEY_CTRL(a0)
	sne		RAWKEY_CTRL(a1)
.mod_ctrl_done:
	btst	#IE_MOD_ALT,d0
	bne.s	.mod_alt_down
	btst	#IE_MOD_ALT,d1
	beq.s	.mod_alt_done
	clr.b	RAWKEY_LALT(a0)
	clr.b	RAWKEY_LALT(a1)
	bra.s	.mod_alt_done
.mod_alt_down:
	sne		RAWKEY_LALT(a0)
	sne		RAWKEY_LALT(a1)
.mod_alt_done:
	rts

ie_keyboard_apply_alias_press:
	cmpi.b	#RAWKEY_UP,d1
	beq.s	.press_forward
	cmpi.b	#RAWKEY_DOWN,d1
	beq.s	.press_backward
	rts
.press_forward:
	moveq	#0,d2
	move.b	forward_key,d2
	move.b	#$FF,0(a0,d2.w)
	move.b	#$FF,0(a1,d2.w)
	rts
.press_backward:
	moveq	#0,d2
	move.b	backward_key,d2
	move.b	#$FF,0(a0,d2.w)
	move.b	#$FF,0(a1,d2.w)
	rts

ie_keyboard_apply_alias_release:
	cmpi.b	#RAWKEY_UP,d1
	beq.s	.release_forward
	cmpi.b	#RAWKEY_DOWN,d1
	beq.s	.release_backward
	rts
.release_forward:
	moveq	#0,d2
	move.b	forward_key,d2
	clr.b	0(a0,d2.w)
	clr.b	0(a1,d2.w)
	rts
.release_backward:
	moveq	#0,d2
	move.b	backward_key,d2
	clr.b	0(a0,d2.w)
	clr.b	0(a1,d2.w)
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
	dc.b	$4C,IE_SCANCODE_NONE,IE_SCANCODE_NONE,$4F,IE_SCANCODE_NONE,$4E,IE_SCANCODE_NONE,IE_SCANCODE_NONE
	dc.b	$4D,IE_SCANCODE_NONE,IE_SCANCODE_NONE,IE_SCANCODE_NONE,IE_SCANCODE_NONE,IE_SCANCODE_NONE,IE_SCANCODE_NONE,IE_SCANCODE_NONE
	dc.b	IE_SCANCODE_NONE,IE_SCANCODE_NONE,IE_SCANCODE_NONE,IE_SCANCODE_NONE,IE_SCANCODE_NONE,IE_SCANCODE_NONE,IE_SCANCODE_NONE,IE_SCANCODE_NONE
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
	lea		FAKE_LIB_BASE+FAKE_LVO_WAITTOF,a0
	move.w	#$4EF9,(a0)+
	move.l	#ie_wait_tof,(a0)
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

ie_gamepad_buttons_l:
	dc.l	0
ie_gamepad_lxy_l:
	dc.l	0
ie_gamepad_rxy_l:
	dc.l	0
ie_gamepad_actions_w:
	dc.w	0
ie_gamepad_axis_state_w:
	dc.w	0

ie_gamepad_edge_state_w:
	dc.w	0
ie_keyboard_state_vb:
	dcb.b	256,0
	IFD		IE_GAMEPAD_TEST
ie_gamepad_test_enable_b:
	dc.b	0
	dc.b	0
ie_gamepad_test_status_l:
	dc.l	0
ie_gamepad_test_buttons_l:
	dc.l	0
ie_gamepad_test_lxy_l:
	dc.l	0
ie_gamepad_test_rxy_l:
	dc.l	0
ie_gamepad_test_edge_counts_vw:
	dcb.w	16,0
ie_gamepad_test_last_actions_w:
	dc.w	0
ie_gamepad_test_read_count_l:
	dc.l	0
ie_gamepad_test_level_begin_l:
	dc.l	0
ie_gamepad_test_plr1_mouse_l:
	dc.l	0
ie_gamepad_test_use_events_l:
	dc.l	0
ie_gamepad_test_menu_up_l:
	dc.l	0
ie_gamepad_test_menu_down_l:
	dc.l	0
ie_gamepad_test_menu_wait_l:
	dc.l	0
	ENDC

ie_mouse_relative_ok:
	dc.l	0
ie_mouse_last_abs_x:
	dc.l	0
ie_mouse_delta_x_w:
	dc.w	0
	dc.w	0
ie_present_index_w:
	dc.w	0
	dc.w	0
ie_vblank_busy_w:
	dc.w	0
	dc.w	0
ie_mouse_last_abs_y:
	dc.l	0
ie_last_modifiers:
	dc.l	0
ie_mouse_left_key_down_b:
	dc.b	0
ie_mouse_right_key_down_b:
	dc.b	0
	dc.w	0

_Game_FinishedLevel_b:
	dc.w	0
ie_menu_active:
	dc.l	0
ie_menu_last_buttons:
	dc.l	0
ie_menu_scroll_w:
	dc.w	0
ie_menu_fire_phase_w:
	dc.w	0
	cnop	0,4

ie_menu_upload_palette:
	move.w	#256,d0
	bra		ie_menu_upload_palette_fade

ie_menu_fade_in:
	movem.l	d0/d6-d7,-(sp)
	moveq	#0,d6
	moveq	#15,d7
.fade_loop:
	move.w	d6,d0
	bsr		ie_menu_upload_palette_fade
	bsr		ie_wait_tof
	addi.w	#16,d6
	dbra	d7,.fade_loop
	move.w	#256,d0
	bsr		ie_menu_upload_palette_fade
	bsr		ie_wait_tof
	movem.l	(sp)+,d0/d6-d7
	rts

ie_menu_fade_out:
	movem.l	d0/d6-d7,-(sp)
	move.w	#256,d6
	moveq	#15,d7
.fade_loop:
	move.w	d6,d0
	bsr		ie_menu_upload_palette_fade
	bsr		ie_wait_tof
	subi.w	#16,d6
	dbra	d7,.fade_loop
	moveq	#0,d0
	bsr		ie_menu_upload_palette_fade
	bsr		ie_wait_tof
	movem.l	(sp)+,d0/d6-d7
	rts

ie_menu_upload_palette_fade:
	movem.l	d0-d7/a0,-(sp)
	move.w	d0,d5
	lea		ie_menu_palette,a0
	moveq	#0,d0
	move.l	d0,VIDEO_PAL_INDEX
	move.w	#255,d7
.pal_loop:
	move.l	(a0)+,d4
	moveq	#0,d1
	move.l	d4,d1
	lsr.l	#8,d1
	lsr.l	#8,d1
	andi.w	#$00FF,d1
	mulu.w	d5,d1
	lsr.l	#8,d1
	lsl.l	#8,d1
	lsl.l	#8,d1
	move.l	d1,d6
	moveq	#0,d1
	move.l	d4,d1
	lsr.l	#8,d1
	andi.w	#$00FF,d1
	mulu.w	d5,d1
	lsr.l	#8,d1
	lsl.l	#8,d1
	or.l	d1,d6
	moveq	#0,d1
	move.l	d4,d1
	andi.w	#$00FF,d1
	mulu.w	d5,d1
	lsr.l	#8,d1
	or.l	d1,d6
	move.l	d6,VIDEO_PAL_DATA
	dbra	d7,.pal_loop
	movem.l	(sp)+,d0-d7/a0
	rts

ie_menu_copy_background:
	movem.l	d0/a0-a1,-(sp)
	clr.w	ie_menu_scroll_w
	clr.w	ie_menu_fire_phase_w
	lea		_mnu_background,a0
	lea		_mnu_screen,a1
	move.l	#MENU_PLANESIZE,d0
	bsr		ie_blt_memcopy
	lea		_mnu_background,a0
	lea		_mnu_screen+MENU_PLANESIZE,a1
	move.l	#MENU_PLANESIZE,d0
	bsr		ie_blt_memcopy
	lea		_mnu_background+MENU_PLANESIZE,a0
	lea		_mnu_screen+(2*MENU_PLANESIZE),a1
	move.l	#MENU_PLANESIZE,d0
	bsr		ie_blt_memcopy
	lea		_mnu_background+MENU_PLANESIZE,a0
	lea		_mnu_screen+(3*MENU_PLANESIZE),a1
	move.l	#MENU_PLANESIZE,d0
	bsr		ie_blt_memcopy
	movem.l	(sp)+,d0/a0-a1
	rts

ie_menu_render_frame:
	movem.l	d0-d7/a0-a6,-(sp)
	lea		_mnu_screen,a0
	lea		_mnu_screen+(2*MENU_PLANESIZE),a1
	moveq	#0,d0
	move.w	ie_menu_scroll_w,d0
	andi.w	#$00FF,d0
	mulu.w	#MENU_ROW_BYTES,d0
	adda.l	d0,a0
	adda.l	d0,a1
	addq.w	#1,ie_menu_scroll_w
	lea		_mnu_morescreen,a3
	lea		MENU_PLANESIZE(a3),a4
	lea		MENU_PLANESIZE(a4),a5
	lea		MENU_PLANESIZE(a5),a6
	move.l	a6,ie_menu_plane5_ptr_l
	lea		(4*MENU_PLANESIZE)(a3),a2
	move.l	a2,ie_menu_plane6_ptr_l
	lea		(5*MENU_PLANESIZE)(a3),a2
	move.l	a2,ie_menu_plane7_ptr_l
	lea		CHUNKY_BASE,a2
	move.w	#SCREEN_HEIGHT-1,d7
.row_loop:
	move.w	#MENU_ROW_BYTES-1,d6
.byte_loop:
	moveq	#7,d3
	moveq	#-128,d1
.bit_loop:
	moveq	#0,d0
	move.b	(a0),d2
	and.b	d1,d2
	beq.s	.no_p0
	or.b	#1,d0
.no_p0:
	move.b	(a1),d2
	and.b	d1,d2
	beq.s	.no_p1
	or.b	#2,d0
.no_p1:
	move.b	(a3),d2
	and.b	d1,d2
	beq.s	.no_p2
	or.b	#4,d0
.no_p2:
	move.b	(a4),d2
	and.b	d1,d2
	beq.s	.no_p3
	or.b	#8,d0
.no_p3:
	move.b	(a5),d2
	and.b	d1,d2
	beq.s	.no_p4
	or.b	#16,d0
.no_p4:
	move.l	ie_menu_plane5_ptr_l,a6
	move.b	(a6),d2
	and.b	d1,d2
	beq.s	.no_p5
	or.b	#32,d0
.no_p5:
	move.l	ie_menu_plane6_ptr_l,a6
	move.b	(a6),d2
	and.b	d1,d2
	beq.s	.no_p6
	or.b	#64,d0
.no_p6:
	move.l	ie_menu_plane7_ptr_l,a6
	move.b	(a6),d2
	and.b	d1,d2
	beq.s	.no_p7
	or.b	#128,d0
.no_p7:
	move.b	d0,(a2)+
	lsr.b	#1,d1
	dbra	d3,.bit_loop
	addq.l	#1,a0
	addq.l	#1,a1
	addq.l	#1,a3
	addq.l	#1,a4
	addq.l	#1,a5
	move.l	ie_menu_plane5_ptr_l,a6
	addq.l	#1,a6
	move.l	a6,ie_menu_plane5_ptr_l
	move.l	ie_menu_plane6_ptr_l,a6
	addq.l	#1,a6
	move.l	a6,ie_menu_plane6_ptr_l
	move.l	ie_menu_plane7_ptr_l,a6
	addq.l	#1,a6
	move.l	a6,ie_menu_plane7_ptr_l
	dbra	d6,.byte_loop
	dbra	d7,.row_loop
	lea		CHUNKY_BASE,a0
	bsr		ie_scale_to_display
	movem.l	(sp)+,d0-d7/a0-a6
	rts

ie_menu_palette:
	incbin	"_build/ie_menu/menu_palette_rgb32.bin"
	cnop	0,4
ie_menu_plane5_ptr_l:
	dc.l	0
ie_menu_plane6_ptr_l:
	dc.l	0
ie_menu_plane7_ptr_l:
	dc.l	0
	cnop	0,4
ie_hud_digits_warn:
	ds.b	IE_HUD_DIGIT_BYTES
ie_hud_digits_good:
	ds.b	IE_HUD_DIGIT_BYTES
ie_hud_slots_unavailable:
	ds.b	IE_HUD_SLOT_BYTES
ie_hud_slots_found:
	ds.b	IE_HUD_SLOT_BYTES
ie_hud_slots_selected:
	ds.b	IE_HUD_SLOT_BYTES
	cnop	0,4
ie_fps_pending_b:
	dc.b	0
	cnop	0,4
	IFD		IE_BLITTER_TEST
ie_blitter_test_fill_count_l:
	dc.l	0
ie_blitter_test_copy_count_l:
	dc.l	0
ie_blitter_test_error_l:
	dc.l	0
ie_blitter_test_command_w:
	dc.w	0
ie_blitter_test_done_w:
	dc.w	0
ie_blitter_test_scratch_vb:
	ds.b	512
	ENDC
	IFD		IE_FPS_TEST
ie_fps_test_force_samples_b:
	dc.b	0
	ie_fps_test_capture_b:
	dc.b	0
	dc.w	0
ie_fps_test_result_w:
	dc.w	0
	dc.w	0
ie_fps_test_render_count_l:
	ds.l	1
ie_fps_test_decimal_offset_l:
	ds.l	1
ie_fps_test_eval_count_l:
	ds.l	1
ie_fps_test_render_digit_count_b:
	dc.b	0
	ie_fps_test_render_trace_b:
	dc.b	0
ie_fps_test_render_digit_x_w:
	ds.w	4
ie_fps_test_present_decimal_b:
	ds.b	4
ie_fps_test_mark_ecv_q:
	ds.l	2
ie_fps_test_mark_rate_l:
	ds.l	1
	ENDC
