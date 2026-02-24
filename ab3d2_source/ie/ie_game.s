; ie_game.s - higher-level game/bootstrap compatibility glue

	xdef ie_game_bootstrap
	xdef ie_game_frame
	xdef ie_game_shutdown
	xdef _ie_game_shutdown
	xdef ie_set_level_letter_from_game
	xdef game_SetMenuLevelNames
	xdef _game_SetMenuLevelNames
	xdef DEFAULTGAME
	xdef _DEFAULTGAME
	xdef Game_Start
	xdef _Game_Start
	xdef Game_Quit
	xdef _Game_Quit
	xdef ie_game_bootstrap_state_l
	xdef ie_game_last_error_l
	xdef Game_ShouldQuit_b
	xdef Game_FinishedLevel_b
	xdef Game_LevelNumber_w
	xdef Game_StoryFile_vb
	xdef GLF_DatabaseName_vb
	xdef draw_BackdropImageName_vb
	xdef draw_TitlePaletteName_vb

	xref Vid_OpenMainScreen
	xref Vid_CloseMainScreen
	xref ie_res_bootstrap_assets
	xref ie_res_load_game_db_file
	xref IO_InitQueue
	xref IO_FlushQueue
	xref IO_LoadFileOptional
	xref Res_LoadSoundFx
	xref Res_PatchSoundFx
	xref Res_LoadFloorsAndTextures
	xref Res_LoadWallTextures
	xref Res_LoadObjects
	xref Res_LoadLevelData
	xref Res_FreeLevelData
	xref Res_FreeObjects
	xref Res_FreeWallTextures
	xref Res_FreeFloorsAndTextures
	xref Res_FreeSoundFx
	xref Lvl_IntroTextPtr_l
	xref Draw_BackdropImagePtr_l
	xref ie_palette_set_texture_ptr
	xref ie_palette_set_texture_ptr_12bit
	xref Lvl_MusicPtr_l
	xref Lvl_MusicLen_l
	xref MakeSomeNoise
	xref Aud_SampleList_vl
	xref Aud_SampleNum_w
	xref Aud_NoiseVol_w
	xref Aud_ChannelPick_b
	xref ie_mod_set_data
	xref mt_init
	xref mt_end
	xref sys_RecoveryStack

	xref Lvl_BinFilenameX_vb
	xref Lvl_GfxFilenameX_vb
	xref Lvl_ClipsFilenameX_vb
	xref Lvl_MapFilenameX_vb
	xref Lvl_FlyMapFilenameX_vb
	xref Lvl_FloorFilenameX_vb
	xref Lvl_WallFilenameX_vb
	xref Lvl_ModPropsFilenameX_vb
	xref Lvl_ErrataFilenameX_vb

IE_GAME_BOOT_STAGE_NONE		equ	0
IE_GAME_BOOT_STAGE_START		equ	1
IE_GAME_BOOT_STAGE_VIDEO		equ	2
IE_GAME_BOOT_STAGE_DEFAULTS	equ	3
IE_GAME_BOOT_STAGE_DBLOAD		equ	4
IE_GAME_BOOT_STAGE_RESLOAD		equ	5
IE_GAME_BOOT_STAGE_STORY		equ	6
IE_GAME_BOOT_STAGE_BACKDROP	equ	7
IE_GAME_BOOT_STAGE_MUSIC		equ	8
IE_GAME_BOOT_STAGE_DONE		equ	9
IE_CHUNKY_BASE				equ	$060000
BACKDROP_SIZE_320x240		equ	76800
IE_SFX_SLOT_COUNT			equ	64

ie_game_bootstrap:
	tst.b	ie_game_bootstrap_done_b
	bne		.already_bootstrapped

	move.l	#IE_GAME_BOOT_STAGE_START,ie_game_bootstrap_state_l
	clr.l	ie_game_last_error_l

	; Keep a recovery SP like original Game_Start for fatal-error paths.
	move.l	a7,sys_RecoveryStack

	; Keep explicit screen init behavior compatible with original control flow.
	move.l	#IE_GAME_BOOT_STAGE_VIDEO,ie_game_bootstrap_state_l
	bsr		Vid_OpenMainScreen

	; Equivalent to DEFAULTGAME + game_SetMenuLevelNames in the original flow.
	move.l	#IE_GAME_BOOT_STAGE_DEFAULTS,ie_game_bootstrap_state_l
	bsr		DEFAULTGAME
	bsr		game_SetMenuLevelNames

	; Queue setup before bulk resource operations.
	bsr		IO_InitQueue

	; Try explicit DB paths first (mirrors original Game_Start intent), then fallback.
	move.l	#IE_GAME_BOOT_STAGE_DBLOAD,ie_game_bootstrap_state_l
	bsr		ie_try_load_database_paths
	tst.l	d0
	beq		.fallback_bootstrap

	; Explicit DB load succeeded: run the same compatibility resource sequence
	; used by the control loop, then flush queued loads.
	move.l	#IE_GAME_BOOT_STAGE_RESLOAD,ie_game_bootstrap_state_l
	bsr		Res_LoadSoundFx
	bsr		Res_PatchSoundFx
	bsr		Res_LoadWallTextures
	bsr		Res_LoadFloorsAndTextures
	bsr		Res_LoadObjects
	bsr		Res_LoadLevelData
	bsr		IO_FlushQueue
	bra		.post_resources

.fallback_bootstrap:
	; Candidate-based bootstrap path (includes DB probe + resource load).
	move.l	#1,ie_game_last_error_l	; explicit DB path set failed
	move.l	#IE_GAME_BOOT_STAGE_RESLOAD,ie_game_bootstrap_state_l
	bsr		ie_res_bootstrap_assets
	bsr		IO_FlushQueue

.post_resources:
	; Optional story text blob used by menu/intro paths.
	move.l	#IE_GAME_BOOT_STAGE_STORY,ie_game_bootstrap_state_l
	bsr		ie_load_story_blob

	; Optional backdrop image used by menu/background paths.
	move.l	#IE_GAME_BOOT_STAGE_BACKDROP,ie_game_bootstrap_state_l
	bsr		ie_load_backdrop_blob
	bsr		ie_load_title_palette

	; If level music was loaded by Res_LoadLevelData, make it active.
	move.l	#IE_GAME_BOOT_STAGE_MUSIC,ie_game_bootstrap_state_l
	move.l	Lvl_MusicPtr_l,d0
	move.l	Lvl_MusicLen_l,d1
	tst.l	d0
	beq.s	.done
	bsr		ie_mod_set_data
	bsr		mt_init
	bsr		ie_try_boot_sfx

.done:
	move.l	#IE_GAME_BOOT_STAGE_DONE,ie_game_bootstrap_state_l
	st		ie_game_bootstrap_done_b
	rts

.already_bootstrapped:
	rts

ie_game_frame:
	; Basic compatibility frame hook:
	; - honor Game_ShouldQuit_b
	; - process level-complete reload path
	tst.b	Game_ShouldQuit_b
	beq.s	.check_finished
	bsr		ie_game_shutdown
	; Keep game halted after shutdown.
	move.l	#0,$F0000
.halt_loop:
	bra.s	.halt_loop

.check_finished:
	bsr		ie_game_draw_backdrop
	tst.b	Game_FinishedLevel_b
	beq.s	.done_frame
	clr.b	Game_FinishedLevel_b

	; Advance to next level (0..15 wrap) and refresh level resources.
	move.w	Game_LevelNumber_w,d0
	addq.w	#1,d0
	cmpi.w	#16,d0
	blt.s	.level_ok
	moveq	#0,d0
.level_ok:
	move.w	d0,Game_LevelNumber_w
	bsr		game_SetMenuLevelNames

	bsr		Res_FreeLevelData
	bsr		IO_InitQueue
	bsr		Res_LoadLevelData
	bsr		IO_FlushQueue

	; Rebind music from the newly loaded level.
	move.l	Lvl_MusicPtr_l,d0
	move.l	Lvl_MusicLen_l,d1
	tst.l	d0
	beq.s	.done_frame
	bsr		ie_mod_set_data
	bsr		mt_init
	bsr		ie_try_boot_sfx

.done_frame:
	rts

ie_game_shutdown:
_ie_game_shutdown:
	; Reverse-order teardown for compatibility with the classic flow.
	bsr		Res_FreeLevelData
	bsr		Res_FreeObjects
	bsr		Res_FreeWallTextures
	bsr		Res_FreeFloorsAndTextures
	bsr		Res_FreeSoundFx
	bsr		mt_end
	bsr		Vid_CloseMainScreen
	clr.b	ie_game_bootstrap_done_b
	rts

; Try a compact set of DB path variants before falling back to generic probe.
; out: d0=1 success, 0 failure
ie_try_load_database_paths:
	lea		GLF_DatabaseName_vb,a0
	bsr		ie_res_load_game_db_file
	tst.l	d0
	bne.s	.ok
	lea		ie_db_name1,a0
	bsr		ie_res_load_game_db_file
	tst.l	d0
	bne.s	.ok
	lea		ie_db_name2,a0
	bsr		ie_res_load_game_db_file
	tst.l	d0
	bne.s	.ok
	lea		ie_db_name3,a0
	bsr		ie_res_load_game_db_file
	tst.l	d0
	bne.s	.ok
	moveq	#0,d0
	rts
.ok:
	moveq	#1,d0
	rts

ie_load_story_blob:
	lea		ie_story_candidates,a2
.story_try:
	move.l	(a2)+,a0
	beq.s	.story_fail
	bsr		IO_LoadFileOptional
	tst.l	d0
	beq.s	.story_try
	move.l	d0,Lvl_IntroTextPtr_l
	rts
.story_fail:
	clr.l	Lvl_IntroTextPtr_l
	ori.l	#$10,ie_game_last_error_l
	rts

ie_load_backdrop_blob:
	lea		ie_backdrop_candidates,a2
.back_try:
	move.l	(a2)+,a0
	beq.s	.back_fail
	bsr		IO_LoadFileOptional
	tst.l	d0
	beq.s	.back_try
	move.l	d0,Draw_BackdropImagePtr_l
	rts
.back_fail:
	clr.l	Draw_BackdropImagePtr_l
	ori.l	#$20,ie_game_last_error_l
	rts

ie_load_title_palette:
	lea		ie_title_palette_candidates,a2
.pal_try:
	move.l	(a2)+,a0
	beq.s	.pal_fail
	bsr		IO_LoadFileOptional
	tst.l	d0
	beq.s	.pal_try
	move.l	d0,a0
	cmpi.l	#512,d1
	beq.s	.pal_12bit
	bsr		ie_palette_set_texture_ptr
	rts
.pal_12bit:
	bsr		ie_palette_set_texture_ptr_12bit
	rts
.pal_fail:
	ori.l	#$40,ie_game_last_error_l
	rts

ie_try_boot_sfx:
	; Fire first available sample at startup so audio path is exercised when data exists.
	tst.b	ie_game_boot_sfx_done_b
	bne.s	.done_boot_sfx
	lea		Aud_SampleList_vl,a0
	moveq	#0,d6
	moveq	#IE_SFX_SLOT_COUNT-1,d7
.find_sample:
	move.l	(a0)+,d0
	move.l	(a0)+,d1
	tst.l	d0
	beq.s	.next_sample
	tst.l	d1
	bne.s	.have_sample
.next_sample:
	addq.w	#1,d6
	dbra	d7,.find_sample
	ori.l	#$80,ie_game_last_error_l
	bra.s	.done_boot_sfx
.have_sample:
	move.w	d6,Aud_SampleNum_w
	move.w	#128,Aud_NoiseVol_w
	move.w	#0,Aud_ChannelPick_b
	bsr		MakeSomeNoise
	st		ie_game_boot_sfx_done_b
.done_boot_sfx:
	rts

ie_game_draw_backdrop:
	move.l	Draw_BackdropImagePtr_l,a0
	tst.l	a0
	beq.s	.no_backdrop
	move.l	#IE_CHUNKY_BASE,a1
	move.l	#BACKDROP_SIZE_320x240/4-1,d7
.copy_backdrop:
	move.l	(a0)+,(a1)+
	dbra	d7,.copy_backdrop
	bra.s	.done_draw
.no_backdrop:
	; Visible fallback pattern so present path is verifiable without backdrop assets.
	move.l	#IE_CHUNKY_BASE,a0
	move.l	ie_game_fallback_phase_l,d0
	move.w	#239,d6
.fallback_y:
	move.l	d0,d1
	move.w	#319,d7
.fallback_x:
	move.b	d1,(a0)+
	addq.b	#1,d1
	dbra	d7,.fallback_x
	addq.l	#1,d0
	dbra	d6,.fallback_y
	addq.l	#1,ie_game_fallback_phase_l
.done_draw:
	rts

; Compatibility entrypoint so old Game_Start symbols can resolve when linking
; incremental parts of the original game flow.
Game_Start:
_Game_Start:
	bsr		ie_game_bootstrap
	moveq	#0,d0
	rts

Game_Quit:
_Game_Quit:
	bsr		ie_game_shutdown
	moveq	#0,d0
	rts

DEFAULTGAME:
_DEFAULTGAME:
	; Default to first level unless already configured elsewhere.
	move.w	#0,Game_LevelNumber_w
	rts

game_SetMenuLevelNames:
_game_SetMenuLevelNames:
	bsr		ie_set_level_letter_from_game
	rts

ie_set_level_letter_from_game:
	moveq	#0,d0
	move.w	Game_LevelNumber_w,d0
	tst.l	d0
	bge.s	.nonneg
	moveq	#0,d0
.nonneg:
	cmpi.l	#15,d0
	ble.s	.in_range
	moveq	#15,d0
.in_range:
	addi.b	#'a',d0
	move.b	d0,Lvl_BinFilenameX_vb
	move.b	d0,Lvl_GfxFilenameX_vb
	move.b	d0,Lvl_ClipsFilenameX_vb
	move.b	d0,Lvl_MapFilenameX_vb
	move.b	d0,Lvl_FlyMapFilenameX_vb
	move.b	d0,Lvl_FloorFilenameX_vb
	move.b	d0,Lvl_WallFilenameX_vb
	move.b	d0,Lvl_ModPropsFilenameX_vb
	move.b	d0,Lvl_ErrataFilenameX_vb
	rts

ie_game_bootstrap_state_l:
	dc.l	0
ie_game_last_error_l:
	dc.l	0
ie_game_bootstrap_done_b:
	dc.b	0
ie_game_boot_sfx_done_b:
	dc.b	0
	dc.b	0
	dc.b	0
	dc.b	0
ie_game_fallback_phase_l:
	dc.l	0

Game_ShouldQuit_b:
	dc.b	0
Game_FinishedLevel_b:
	dc.b	0
	dc.b	0
	dc.b	0
	even

Game_LevelNumber_w:
	dc.w	0
	dc.w	0

GLF_DatabaseName_vb:
	dc.b	"ab3:includes/test.lnk",0
	even

Game_StoryFile_vb:
	dc.b	"ab3:includes/text_file",0
	even

draw_BackdropImageName_vb:
	dc.b	"ab3:includes/rawbackpacked",0
	even
draw_TitlePaletteName_vb:
	dc.b	"ab3:includes/titlescrnpal",0
	even

ie_db_name1:
	dc.b	"media/includes/test.lnk",0
ie_db_name2:
	dc.b	"media/includes/TEST.LNK",0
ie_db_name3:
	dc.b	"../media/includes/test.lnk",0
	even

ie_story_candidates:
	dc.l	Game_StoryFile_vb
	dc.l	ie_story_name1
	dc.l	ie_story_name2
	dc.l	0

ie_backdrop_candidates:
	dc.l	ie_backdrop_name0
	dc.l	draw_BackdropImageName_vb
	dc.l	ie_backdrop_name1
	dc.l	ie_backdrop_name2
	dc.l	0

ie_title_palette_candidates:
	dc.l	draw_TitlePaletteName_vb
	dc.l	ie_titlepal_name1
	dc.l	ie_titlepal_name2
	dc.l	0

ie_story_name1:
	dc.b	"media/includes/text_file",0
ie_story_name2:
	dc.b	"../media/includes/text_file",0
	even

ie_backdrop_name1:
	dc.b	"media/includes/rawbackpacked",0
ie_backdrop_name2:
	dc.b	"../media/includes/rawbackpacked",0
	even
ie_backdrop_name0:
	dc.b	"media/includes/rawback",0
ie_titlepal_name1:
	dc.b	"media/includes/titlescrnpal",0
ie_titlepal_name2:
	dc.b	"../media/includes/titlescrnpal",0
	even
