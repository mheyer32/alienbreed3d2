; ie_game.s - higher-level game bootstrap compatibility glue

	xdef ie_game_bootstrap
	xdef ie_set_level_letter_from_game
	xdef Game_LevelNumber_w
	xdef Game_StoryFile_vb
	xdef draw_BackdropImageName_vb

	xref ie_res_bootstrap_assets
	xref IO_InitQueue
	xref IO_FlushQueue
	xref IO_LoadFileOptional
	xref Lvl_IntroTextPtr_l
	xref Draw_BackdropImagePtr_l
	xref Lvl_MusicPtr_l
	xref Lvl_MusicLen_l
	xref ie_mod_set_data
	xref mt_init
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

ie_game_bootstrap:
	; Keep a recovery SP like original Game_Start for fatal-error paths.
	move.l	a7,sys_RecoveryStack

	; Mirror the original SETPLAYERS filename-letter update.
	bsr		ie_set_level_letter_from_game

	bsr		IO_InitQueue
	; Resource bootstrap handles GLF DB probing and compatibility loads.
	bsr		ie_res_bootstrap_assets
	bsr		IO_FlushQueue

	; Optional story text blob used by menu/intro paths.
	lea		Game_StoryFile_vb,a0
	bsr		IO_LoadFileOptional
	move.l	d0,Lvl_IntroTextPtr_l

	; Optional backdrop image used by menu/background paths.
	lea		draw_BackdropImageName_vb,a0
	bsr		IO_LoadFileOptional
	move.l	d0,Draw_BackdropImagePtr_l

	; If level music was loaded by Res_LoadLevelData, make it active.
	move.l	Lvl_MusicPtr_l,d0
	move.l	Lvl_MusicLen_l,d1
	tst.l	d0
	beq.s	.done
	bsr		ie_mod_set_data
	bsr		mt_init
.done:
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

Game_LevelNumber_w:
	dc.w	0
	dc.w	0

Game_StoryFile_vb:
	dc.b	"ab3:includes/text_file",0
	even

draw_BackdropImageName_vb:
	dc.b	"ab3:includes/rawbackpacked",0
	even
