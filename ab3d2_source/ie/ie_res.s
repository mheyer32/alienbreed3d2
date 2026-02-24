; ie_res.s - Intuition Engine resource helper routines
;
; These helpers provide a thin bridge between file I/O compatibility
; entrypoints and IE palette/SFX/MOD registration APIs.

	xdef ie_res_init
	xdef _ie_res_init
	xdef ie_res_bootstrap_assets
	xdef _ie_res_bootstrap_assets
	xdef ie_res_load_palette_file
	xdef _ie_res_load_palette_file
	xdef ie_res_load_mod_file
	xdef _ie_res_load_mod_file
	xdef ie_res_load_sfx_file
	xdef _ie_res_load_sfx_file
	xdef ie_res_load_sfx_table
	xdef _ie_res_load_sfx_table
	xdef ie_res_load_sfx_table_ex
	xdef _ie_res_load_sfx_table_ex
	xdef ie_res_load_sfx_table_60
	xdef _ie_res_load_sfx_table_60
	xdef ie_res_set_sfx_filename_table
	xdef _ie_res_set_sfx_filename_table
	xdef ie_res_load_game_db_file
	xdef _ie_res_load_game_db_file
	xdef Res_LoadObjects
	xdef _Res_LoadObjects
	xdef Res_FreeObjects
	xdef _Res_FreeObjects
	xdef Res_LoadSoundFx
	xdef _Res_LoadSoundFx
	xdef Res_LoadFloorsAndTextures
	xdef _Res_LoadFloorsAndTextures
	xdef Res_FreeFloorsAndTextures
	xdef _Res_FreeFloorsAndTextures
	xdef Res_LoadWallTextures
	xdef _Res_LoadWallTextures
	xdef Res_FreeWallTextures
	xdef _Res_FreeWallTextures
	xdef Res_LoadLevelData
	xdef _Res_LoadLevelData
	xdef Res_FreeLevelData
	xdef _Res_FreeLevelData
	xdef Res_ReleaseScreenMemory
	xdef _Res_ReleaseScreenMemory
	xdef Lvl_InitLevelMods
	xdef _Lvl_InitLevelMods
	xdef Res_PatchSoundFx
	xdef _Res_PatchSoundFx
	xdef Res_FreeSoundFx
	xdef _Res_FreeSoundFx
	xdef GLF_DatabasePtr_l
	xdef Draw_GlobalFloorTexturesPtr_l
	xdef Draw_FloorTexturesPtr_l
	xdef Draw_TextureMapsPtr_l
	xdef Draw_ObjectPtrs_vl
	xdef Draw_PolyObjects_vl
	xdef Draw_BackdropImagePtr_l
	xdef Lvl_IntroTextPtr_l
	xdef Draw_GlobalWallTexturePtrs_vl
	xdef Draw_WallTexturePtrs_vl
	xdef Draw_LevelFloorTexturesPtr_l
	xdef Draw_LevelWallTexturePtrs_vl
	xdef Zone_BackdropDisable_vb
	xdef Lvl_WalkLinksPtr_l
	xdef Lvl_FlyLinksPtr_l
	xdef Lvl_MusicPtr_l
	xdef Lvl_MusicLen_l
	xdef Lvl_DataPtr_l
	xdef Lvl_GraphicsPtr_l
	xdef Lvl_ClipsPtr_l
	xdef Lvl_ModPropertiesPtr_l
	xdef Lvl_ErrataPtr_l
	xdef Lvl_BinFilename_vb
	xdef Lvl_BinFilenameX_vb
	xdef Lvl_GfxFilename_vb
	xdef Lvl_GfxFilenameX_vb
	xdef Lvl_ClipsFilename_vb
	xdef Lvl_ClipsFilenameX_vb
	xdef Lvl_MapFilename_vb
	xdef Lvl_MapFilenameX_vb
	xdef Lvl_FlyMapFilename_vb
	xdef Lvl_FlyMapFilenameX_vb
	xdef Lvl_FloorFilename_vb
	xdef Lvl_FloorFilenameX_vb
	xdef Lvl_WallFilename_vb
	xdef Lvl_WallFilenameX_vb
	xdef Lvl_WallFilenameN_vb
	xdef Lvl_ModPropsFilename_vb
	xdef Lvl_ModPropsFilenameX_vb
	xdef Lvl_ErrataFilename_vb
	xdef Lvl_ErrataFilenameX_vb
	xref mt_data
	xref mt_size
	xref Zone_FreeEdgePVS
	xref ie_palette_set_texture_ptr_12bit

RES_NUM_SFX	equ	59
NUM_WALL_TEXTURES	equ	16
NUM_OBJECT_DEFS	equ	30
DRAW_MAX_OBJECTS	equ	38
DRAW_MAX_POLY_OBJECTS	equ	40
ZONE_BACKDROP_DISABLE_SIZE	equ	64
; Offsets generated from defs.i via a tiny include-based probe assembly.
IE_GLFT_OBJGFXNAMES_OFF	equ	$02C0
IE_GLFT_SFXFILENAMES_OFF	equ	$0A40
IE_GLFT_FLOORFILENAME_OFF	equ	$1940
IE_GLFT_TEXTUREFILENAME_OFF	equ	$1980
IE_GLFT_VECTORNAMES_OFF	equ	$13FE0
IE_GLFT_WALLGFXNAMES_OFF	equ	$14760
IE_GLFT_LEVELMUSIC_OFF	equ	$14CC0

	even

; Initialize resource helper state.
ie_res_init:
_ie_res_init:
	bsr		IO_InitQueue
	bsr		ie_sfx_clear_samples
	clr.l	GLF_DatabasePtr_l
	clr.l	ie_res_sfx_filename_table_ptr
	bsr		Lvl_InitLevelMods
	rts

; Attempt a larger default bootstrap pass so IE bring-up has real assets
; without requiring manual calls from game code.
ie_res_bootstrap_assets:
_ie_res_bootstrap_assets:
	; 1) Palette: try known candidate names.
	lea		ie_palette_candidates,a0
	bsr		ie_res_try_palette_candidates

	; 2) MOD music: optional, starts playback if load succeeds.
	lea		ie_mod_candidates,a0
	bsr		ie_res_try_mod_candidates

	; 3) Optional game database. If found, auto-bind and load SFX table.
	lea		ie_game_db_candidates,a0
	bsr		ie_res_try_game_db_candidates
	tst.l	d0
	beq.s	.done_bootstrap
	bsr		Res_LoadSoundFx
	bsr		Res_PatchSoundFx
	bsr		Res_LoadFloorsAndTextures
	bsr		Res_LoadWallTextures
	bsr		Res_LoadObjects
	bsr		Res_LoadLevelData
.done_bootstrap:
	rts

; Configure external SFX filename table pointer used by Res_LoadSoundFx.
; in: a0 -> first entry (AB3D2 GLFT_SFXFilenames layout, 60-byte stride)
ie_res_set_sfx_filename_table:
_ie_res_set_sfx_filename_table:
	move.l	a0,ie_res_sfx_filename_table_ptr
	rts

; Legacy object/vector resource compatibility.
Res_LoadObjects:
_Res_LoadObjects:
	move.l	GLF_DatabasePtr_l,a6
	tst.l	a6
	beq		.no_obj_db

	; Reset object pointer table.
	lea		Draw_ObjectPtrs_vl,a1
	move.w	#(DRAW_MAX_OBJECTS*4)-1,d7
.clr_obj_ptrs:
	clr.l	(a1)+
	dbra	d7,.clr_obj_ptrs

	; Load object WAD/PTR/256PAL triplets from GLF object names.
	move.l	a6,a0
	adda.l	#IE_GLFT_OBJGFXNAMES_OFF,a0
	lea		Draw_ObjectPtrs_vl,a1
	moveq	#NUM_OBJECT_DEFS-1,d7
.obj_loop:
	tst.b	(a0)
	beq.s	.next_obj
	lea		ie_res_ext_wad,a2
	move.l	a1,d0
	bsr		ie_res_queue_name_with_ext
	lea		ie_res_ext_ptr,a2
	move.l	a1,d0
	addq.l	#4,d0
	bsr		ie_res_queue_name_with_ext
	lea		ie_res_ext_256pal,a2
	move.l	a1,d0
	add.l	#12,d0
	bsr		ie_res_queue_name_with_ext
.next_obj:
	adda.w	#64,a0
	adda.w	#16,a1
	dbra	d7,.obj_loop

	; Load vector object files.
	move.l	a6,a0
	adda.l	#IE_GLFT_VECTORNAMES_OFF,a0
	lea		Draw_PolyObjects_vl,a1
	moveq	#NUM_OBJECT_DEFS-1,d7
.vec_loop:
	tst.b	(a0)
	beq.s	.next_vec
	move.l	a1,d0
	moveq	#0,d1
	bsr		IO_QueueFile
.next_vec:
	adda.w	#64,a0
	addq.l	#4,a1
	dbra	d7,.vec_loop

	moveq	#1,d0
	rts
.no_obj_db:
	moveq	#0,d0
	rts

Res_FreeObjects:
_Res_FreeObjects:
	clr.l	GLF_DatabasePtr_l
	clr.l	ie_res_sfx_filename_table_ptr
	clr.l	Lvl_IntroTextPtr_l
	clr.l	Draw_BackdropImagePtr_l
	lea		Draw_ObjectPtrs_vl,a1
	move.w	#(DRAW_MAX_OBJECTS*4)-1,d7
.clr_obj_free:
	clr.l	(a1)+
	dbra	d7,.clr_obj_free
	lea		Draw_PolyObjects_vl,a1
	move.w	#DRAW_MAX_POLY_OBJECTS-1,d7
.clr_poly_free:
	clr.l	(a1)+
	dbra	d7,.clr_poly_free
	moveq	#1,d0
	rts

; Load a GLF database file and bind GLF_DatabasePtr_l + SFX table pointer.
; in: a0 -> filename
; out: d0 = 1 on success, 0 on failure
ie_res_load_game_db_file:
_ie_res_load_game_db_file:
	bsr		IO_LoadFileOptional	; d0=ptr, d1=len
	tst.l	d0
	beq.s	.fail_game_db
	move.l	d0,GLF_DatabasePtr_l
	move.l	d0,a1
	adda.l	#IE_GLFT_SFXFILENAMES_OFF,a1
	move.l	a1,ie_res_sfx_filename_table_ptr
	moveq	#1,d0
	rts
.fail_game_db:
	moveq	#0,d0
	rts

; Load RGB8 palette file and set as active texture palette source.
; in: a0 -> filename
; out: d0 = 1 on success, 0 on failure
ie_res_load_palette_file:
_ie_res_load_palette_file:
	bsr		IO_LoadFileOptional
	tst.l	d0
	beq.s	.fail
	move.l	d0,a0
	cmpi.l	#512,d1
	beq.s	.pal_12bit
	bsr		ie_palette_set_texture_ptr
	moveq	#1,d0
	rts
.pal_12bit:
	bsr		ie_palette_set_texture_ptr_12bit
	moveq	#1,d0
	rts
.fail:
	moveq	#0,d0
	rts

; Load MOD file and start playback.
; in: a0 -> filename
; out: d0 = 1 on success, 0 on failure
ie_res_load_mod_file:
_ie_res_load_mod_file:
	bsr		IO_LoadFileOptional	; d0=ptr, d1=len
	tst.l	d0
	beq.s	.mod_fail
	bsr		ie_mod_set_data		; uses d0=ptr, d1=len
	bsr		mt_init
	moveq	#1,d0
	rts
.mod_fail:
	moveq	#0,d0
	rts

; Load SFX sample file and register into Aud_SampleList_vl slot.
; in: d0 = sample index (0..63), a0 -> filename
; out: d0 = 1 on success, 0 on failure
ie_res_load_sfx_file:
_ie_res_load_sfx_file:
	move.l	d0,d4
	bsr		IO_LoadFileOptional	; d0=ptr, d1=len
	tst.l	d0
	beq.s	.fail_sfx
	move.l	d0,d2				; ptr
	move.l	d1,d3				; len
	move.l	d4,d0				; sample index
	move.l	d2,d1				; ptr
	move.l	d3,d2				; len
	bsr		ie_sfx_set_sample
	moveq	#1,d0
	rts
.fail_sfx:
	moveq	#0,d0
	rts

; Batch-load SFX table with explicit entry stride.
; in:
;   a0 = pointer to first filename entry (fixed-width entries)
;   d0 = entry count
;   d1 = destination sample index start
;   d2 = entry stride in bytes (<=0 -> defaults to 64)
; out:
;   d0 = number of successfully loaded entries
ie_res_load_sfx_table_ex:
_ie_res_load_sfx_table_ex:
	move.l	a0,a2				; current filename entry ptr
	move.l	d0,d6				; remaining entries
	move.l	d1,d7				; current sample index
	move.l	d2,d4				; entry stride
	moveq	#0,d5				; success counter
	tst.l	d4
	bgt.s	.stride_ok
	moveq	#64,d4
.stride_ok:
	tst.l	d6
	ble		.done_tbl

.loop_tbl:
	; Skip empty filename slots.
	tst.b	(a2)
	beq		.next_tbl

	move.l	d7,d0
	move.l	a2,a0
	bsr		ie_res_load_sfx_file
	tst.l	d0
	beq		.next_tbl
	addq.l	#1,d5

.next_tbl:
	adda.l	d4,a2
	addq.l	#1,d7
	subq.l	#1,d6
	bgt		.loop_tbl

.done_tbl:
	move.l	d5,d0
	rts

; Backward-compatible wrapper for the original API used in this port layer.
; Uses 64-byte filename entries.
ie_res_load_sfx_table:
_ie_res_load_sfx_table:
	moveq	#64,d2
	bsr		ie_res_load_sfx_table_ex
	rts

; AB3D2 GLF table wrapper.
; Uses 60-byte filename entries (GLFT_SFXFilenames layout).
ie_res_load_sfx_table_60:
_ie_res_load_sfx_table_60:
	moveq	#60,d2
	bsr		ie_res_load_sfx_table_ex
	rts

; Legacy AB3D2 resource compatibility entrypoints.
; These are no-op safe until ie_res_set_sfx_filename_table is called.
Res_LoadSoundFx:
_Res_LoadSoundFx:
	move.l	ie_res_sfx_filename_table_ptr,a0
	tst.l	a0
	beq.s	.no_table
	moveq	#RES_NUM_SFX,d0
	moveq	#0,d1
	bsr		ie_res_load_sfx_table_60
	rts
.no_table:
	moveq	#0,d0
	rts

; Legacy texture/floor resource compatibility.
; Loads:
;   GLFT_FloorFilename_l   -> Draw_GlobalFloorTexturesPtr_l
;   GLFT_TextureFilename_l -> Draw_TextureMapsPtr_l
; and derives a .pal path for Draw_TexturePalettePtr_l.
Res_LoadFloorsAndTextures:
_Res_LoadFloorsAndTextures:
	move.l	GLF_DatabasePtr_l,a3
	tst.l	a3
	beq.s	.no_db

	; Global floor textures.
	move.l	a3,a0
	adda.l	#IE_GLFT_FLOORFILENAME_OFF,a0
	move.l	#Draw_GlobalFloorTexturesPtr_l,d0
	moveq	#0,d1
	bsr		IO_QueueFile

	; Mirror runtime floor pointer to global set (same behavior as AB3D2).
	move.l	Draw_GlobalFloorTexturesPtr_l,Draw_FloorTexturesPtr_l

	; Texture maps.
	move.l	a3,a0
	adda.l	#IE_GLFT_TEXTUREFILENAME_OFF,a0
	move.l	#Draw_TextureMapsPtr_l,d0
	moveq	#0,d1
	bsr		IO_QueueFile

	; Build palette filename from texture filename and load it.
	move.l	a3,a0
	adda.l	#IE_GLFT_TEXTUREFILENAME_OFF,a0
	bsr		ie_res_build_pal_filename
	lea		ie_res_pal_name_vb,a0
	move.l	#Draw_TexturePalettePtr_l,d0
	moveq	#0,d1
	bsr		IO_QueueFile
	tst.l	Draw_TexturePalettePtr_l
	beq.s	.no_db
	bsr		ie_palette_mark_dirty
	moveq	#1,d0
	rts

.no_db:
	moveq	#0,d0
	rts

Res_FreeFloorsAndTextures:
_Res_FreeFloorsAndTextures:
	clr.l	Draw_GlobalFloorTexturesPtr_l
	clr.l	Draw_TextureMapsPtr_l
	clr.l	Draw_TexturePalettePtr_l
	clr.l	Draw_LevelFloorTexturesPtr_l
	clr.l	Draw_FloorTexturesPtr_l
	moveq	#1,d0
	rts

; Legacy wall texture compatibility.
; Loads GLFT_WallGFXNames_l list into Draw_GlobalWallTexturePtrs_vl and mirrors
; active pointers into Draw_WallTexturePtrs_vl.
Res_LoadWallTextures:
_Res_LoadWallTextures:
	move.l	GLF_DatabasePtr_l,a3
	tst.l	a3
	beq.s	.no_wall_db
	adda.l	#IE_GLFT_WALLGFXNAMES_OFF,a3
	lea		Draw_GlobalWallTexturePtrs_vl,a4
	lea		Draw_WallTexturePtrs_vl,a5
	moveq	#NUM_WALL_TEXTURES-1,d7

.load_wall_loop:
	clr.l	(a4)
	clr.l	(a5)
	tst.b	(a3)
	beq.s	.next_wall
	move.l	a3,a0
	move.l	a4,d0
	moveq	#0,d1
	bsr		IO_QueueFile
	move.l	(a4),(a5)
.next_wall:
	addq.l	#4,a4
	addq.l	#4,a5
	adda.w	#64,a3
	dbra	d7,.load_wall_loop
	moveq	#1,d0
	rts

.no_wall_db:
	moveq	#0,d0
	rts

Res_FreeWallTextures:
_Res_FreeWallTextures:
	lea		Draw_GlobalWallTexturePtrs_vl,a2
	lea		Draw_LevelWallTexturePtrs_vl,a3
	lea		Draw_WallTexturePtrs_vl,a4
	moveq	#NUM_WALL_TEXTURES-1,d2
.clear_walls:
	clr.l	(a2)+
	clr.l	(a3)+
	clr.l	(a4)+
	dbra	d2,.clear_walls
	moveq	#1,d0
	rts

; Legacy level data loading compatibility.
; Loads core level files and optional per-level overrides.
Res_LoadLevelData:
_Res_LoadLevelData:
	; Required level files.
	lea		Lvl_MapFilename_vb,a0
	bsr		IO_LoadFile
	move.l	d0,Lvl_WalkLinksPtr_l

	lea		Lvl_FlyMapFilename_vb,a0
	bsr		IO_LoadFile
	move.l	d0,Lvl_FlyLinksPtr_l

	; Per-level music filename from GLF database table (optional).
	move.l	GLF_DatabasePtr_l,a0
	tst.l	a0
	beq.s	.no_level_music
	moveq	#0,d1
	move.b	Lvl_BinFilenameX_vb,d1
	sub.b	#'a',d1
	bcc.s	.music_nonneg
	moveq	#0,d1
.music_nonneg:
	cmpi.b	#15,d1
	bls.s	.music_idx_ok
	moveq	#0,d1
.music_idx_ok:
	lsl.w	#6,d1
	adda.l	#IE_GLFT_LEVELMUSIC_OFF,a0
	adda.w	d1,a0
	bsr		IO_LoadFile
	move.l	d0,Lvl_MusicPtr_l
	move.l	d1,Lvl_MusicLen_l
	move.l	d0,mt_data
	move.l	d1,mt_size
	bra.s	.have_level_music
.no_level_music:
	clr.l	Lvl_MusicPtr_l
	clr.l	Lvl_MusicLen_l
	clr.l	mt_data
	clr.l	mt_size
.have_level_music:

	lea		Lvl_BinFilename_vb,a0
	bsr		IO_LoadFile
	move.l	d0,Lvl_DataPtr_l

	lea		Lvl_GfxFilename_vb,a0
	bsr		IO_LoadFile
	move.l	d0,Lvl_GraphicsPtr_l

	lea		Lvl_ClipsFilename_vb,a0
	bsr		IO_LoadFile
	move.l	d0,Lvl_ClipsPtr_l

	; Optional level floor override.
	move.l	Draw_GlobalFloorTexturesPtr_l,Draw_FloorTexturesPtr_l
	lea		Lvl_FloorFilename_vb,a0
	bsr		IO_LoadFileOptional
	move.l	d0,Draw_LevelFloorTexturesPtr_l
	beq.s	.no_floor_override
	move.l	d0,Draw_FloorTexturesPtr_l
.no_floor_override:

	; Optional level properties/errata.
	lea		Lvl_ModPropsFilename_vb,a0
	bsr		IO_LoadFileOptional
	move.l	d0,Lvl_ModPropertiesPtr_l

	lea		Lvl_ErrataFilename_vb,a0
	bsr		IO_LoadFileOptional
	move.l	d0,Lvl_ErrataPtr_l

	bsr		Lvl_InitLevelMods

	; Optional per-wall texture overrides.
	lea		Draw_GlobalWallTexturePtrs_vl,a2
	lea		Draw_LevelWallTexturePtrs_vl,a3
	lea		Draw_WallTexturePtrs_vl,a4
	lea		ie_res_hex_digits,a5
	moveq	#NUM_WALL_TEXTURES-1,d2
.do_wall_override:
	move.l	(a2)+,(a4)
	move.b	(a5)+,Lvl_WallFilenameN_vb
	lea		Lvl_WallFilename_vb,a0
	bsr		IO_LoadFileOptional
	move.l	d0,(a3)+
	beq.s	.no_this_wall_override
	move.l	d0,(a4)
.no_this_wall_override:
	addq.l	#4,a4
	dbra	d2,.do_wall_override

	moveq	#1,d0
	rts

; IE static heap has no per-object free; clear pointers and restore defaults.
Res_FreeLevelData:
_Res_FreeLevelData:
	clr.l	Lvl_WalkLinksPtr_l
	clr.l	Lvl_FlyLinksPtr_l
	clr.l	Lvl_MusicPtr_l
	clr.l	Lvl_MusicLen_l
	clr.l	Lvl_DataPtr_l
	clr.l	Lvl_GraphicsPtr_l
	clr.l	Lvl_ClipsPtr_l
	clr.l	Lvl_ModPropertiesPtr_l
	clr.l	Lvl_ErrataPtr_l
	bsr		Lvl_InitLevelMods
	clr.l	Draw_LevelFloorTexturesPtr_l
	move.l	Draw_GlobalFloorTexturesPtr_l,Draw_FloorTexturesPtr_l
	lea		Draw_GlobalWallTexturePtrs_vl,a2
	lea		Draw_LevelWallTexturePtrs_vl,a3
	lea		Draw_WallTexturePtrs_vl,a4
	moveq	#NUM_WALL_TEXTURES-1,d2
.clear_wall_refs:
	move.l	(a2)+,(a4)+
	clr.l	(a3)+
	dbra	d2,.clear_wall_refs
	bsr		Zone_FreeEdgePVS
	moveq	#1,d0
	rts

Res_ReleaseScreenMemory:
_Res_ReleaseScreenMemory:
	moveq	#1,d0
	rts

Lvl_InitLevelMods:
_Lvl_InitLevelMods:
	tst.l	Lvl_ModPropertiesPtr_l
	beq		.clear_backdrop

	; Copy backdrop disable table from mod-properties payload.
	move.l	Lvl_ModPropertiesPtr_l,a0
	lea		Zone_BackdropDisable_vb,a1
	move.w	#(ZONE_BACKDROP_DISABLE_SIZE/16)-1,d0
.copy_backdrop:
	move.l	(a0)+,(a1)+
	move.l	(a0)+,(a1)+
	move.l	(a0)+,(a1)+
	move.l	(a0)+,(a1)+
	dbra	d0,.copy_backdrop
	rts

.clear_backdrop:
	lea		Zone_BackdropDisable_vb,a0
	move.w	#(ZONE_BACKDROP_DISABLE_SIZE/4)-1,d0
.clear_loop:
	clr.l	(a0)+
	dbra	d0,.clear_loop
	rts

; Queue a file using a 64-byte GLF name entry + extension suffix.
; in:
;   a0 = GLF entry ptr (NUL-terminated basename)
;   a2 = extension string ptr (includes leading '.')
;   d0 = destination pointer slot address
ie_res_queue_name_with_ext:
	move.l	d0,a4
	move.l	a0,a3
	lea		ie_res_obj_name_vb,a1
	move.w	#158,d6
.copy_name:
	move.b	(a3)+,d1
	beq.s	.copy_ext
	move.b	d1,(a1)+
	dbra	d6,.copy_name
	bra.s	.term_name
.copy_ext:
	move.b	(a2)+,d1
	move.b	d1,(a1)+
	bne.s	.copy_ext
	bra.s	.queue_name
.term_name:
	clr.b	(a1)
.queue_name:
	lea		ie_res_obj_name_vb,a0
	move.l	a4,d0
	moveq	#0,d1
	bsr		IO_QueueFile
	rts

; Build "<texture_path>.pal" (or replace existing extension) into ie_res_pal_name_vb.
; in: a0 -> source path (NUL-terminated)
ie_res_build_pal_filename:
	lea		ie_res_pal_name_vb,a1
	move.l	a1,a2				; start
	move.l	a1,a3				; last '.' position (or start)
	move.w	#254,d7
.copy_tex:
	move.b	(a0)+,d1
	beq.s	.done_copy_tex
	cmpi.b	#'/',d1
	beq.s	.reset_dot
	cmpi.b	#92,d1
	beq.s	.reset_dot
	cmpi.b	#':',d1
	beq.s	.reset_dot
	cmpi.b	#'.',d1
	bne.s	.store_tex_char
	move.l	a1,a3
.store_tex_char:
	move.b	d1,(a1)+
	dbra	d7,.copy_tex
	bra.s	.force_term
.reset_dot:
	move.b	d1,(a1)+
	move.l	a1,a3
	dbra	d7,.copy_tex
	bra.s	.force_term
.done_copy_tex:
	; If we saw a dot after the last separator, replace extension from there.
	cmp.l	a3,a2
	beq.s	.append_dot
	move.l	a3,a1
.append_dot:
	move.b	#'.',(a1)+
	move.b	#'p',(a1)+
	move.b	#'a',(a1)+
	move.b	#'l',(a1)+
	clr.b	(a1)
	rts
.force_term:
	clr.b	(a1)
	rts

; Convert loaded SFX table from {ptr,len} to {ptr,end_ptr} in place.
Res_PatchSoundFx:
_Res_PatchSoundFx:
	move.w	#RES_NUM_SFX-1,d7
	lea		Aud_SampleList_vl,a1
.patch_loop:
	move.l	(a1)+,d0
	add.l	d0,(a1)+
	dbra	d7,.patch_loop
	rts

; IE static-heap model has no per-sample free. Clear table entries instead.
Res_FreeSoundFx:
_Res_FreeSoundFx:
	bsr		ie_sfx_clear_samples
	rts

; Candidate walker helpers
; in: a0 -> table of long pointers to C-strings, terminated by 0
ie_res_try_palette_candidates:
	move.l	a0,a2
.next_pal:
	move.l	(a2)+,a1
	beq.s	.done_pal
	move.l	a1,a0
	bsr		ie_res_load_palette_file
	tst.l	d0
	beq.s	.next_pal
	moveq	#1,d0
	rts
.done_pal:
	moveq	#0,d0
	rts

ie_res_try_mod_candidates:
	move.l	a0,a2
.next_mod:
	move.l	(a2)+,a1
	beq.s	.done_mod
	move.l	a1,a0
	bsr		ie_res_load_mod_file
	tst.l	d0
	beq.s	.next_mod
	moveq	#1,d0
	rts
.done_mod:
	moveq	#0,d0
	rts

ie_res_try_game_db_candidates:
	move.l	a0,a2
.next_gdb:
	move.l	(a2)+,a1
	beq.s	.done_gdb
	move.l	a1,a0
	bsr		ie_res_load_game_db_file
	tst.l	d0
	beq.s	.next_gdb
	moveq	#1,d0
	rts
.done_gdb:
	moveq	#0,d0
	rts

; Default asset candidates (all optional).
ie_palette_candidates:
	dc.l	ie_pal_name0
	dc.l	ie_pal_name1
	dc.l	ie_pal_name2
	dc.l	0

ie_mod_candidates:
	dc.l	ie_mod_name0
	dc.l	ie_mod_name1
	dc.l	ie_mod_name2
	dc.l	0

ie_game_db_candidates:
	dc.l	ie_game_db_name0
	dc.l	ie_game_db_name1
	dc.l	ie_game_db_name2
	dc.l	ie_game_db_name3
	dc.l	ie_game_db_name4
	dc.l	ie_game_db_name5
	dc.l	ie_game_db_name6
	dc.l	0

ie_pal_name0:
	dc.b	"AB3:Includes/main.256pal",0
ie_pal_name1:
	dc.b	"includes/main.256pal",0
ie_pal_name2:
	dc.b	"main.256pal",0
	even

ie_mod_name0:
	dc.b	"AB3:Includes/title.mod",0
ie_mod_name1:
	dc.b	"includes/title.mod",0
ie_mod_name2:
	dc.b	"title.mod",0
	even

ie_game_db_name0:
	dc.b	"AB3:includes/test.lnk",0
ie_game_db_name1:
	dc.b	"includes/test.lnk",0
ie_game_db_name2:
	dc.b	"test.lnk",0
ie_game_db_name3:
	dc.b	"media/includes/test.lnk",0
ie_game_db_name4:
	dc.b	"../media/includes/test.lnk",0
ie_game_db_name5:
	dc.b	"media/includes/TEST.LNK",0
ie_game_db_name6:
	dc.b	"media/includes/cheesy.lnk",0
	even

ie_res_sfx_filename_table_ptr:
	dc.l	0

GLF_DatabasePtr_l:
	dc.l	0

Draw_GlobalFloorTexturesPtr_l:
	dc.l	0
Draw_FloorTexturesPtr_l:
	dc.l	0
Draw_TextureMapsPtr_l:
	dc.l	0
Draw_ObjectPtrs_vl:
	dcb.l	DRAW_MAX_OBJECTS*4,0
Draw_PolyObjects_vl:
	dcb.l	DRAW_MAX_POLY_OBJECTS,0
Draw_BackdropImagePtr_l:
	dc.l	0
Lvl_IntroTextPtr_l:
	dc.l	0
Draw_GlobalWallTexturePtrs_vl:
	dcb.l	NUM_WALL_TEXTURES,0
Draw_WallTexturePtrs_vl:
	dcb.l	NUM_WALL_TEXTURES,0
Draw_LevelFloorTexturesPtr_l:
	dc.l	0
Draw_LevelWallTexturePtrs_vl:
	dcb.l	NUM_WALL_TEXTURES,0
Zone_BackdropDisable_vb:
	dcb.b	ZONE_BACKDROP_DISABLE_SIZE,0

Lvl_WalkLinksPtr_l:
	dc.l	0
Lvl_FlyLinksPtr_l:
	dc.l	0
Lvl_MusicPtr_l:
	dc.l	0
Lvl_MusicLen_l:
	dc.l	0
Lvl_DataPtr_l:
	dc.l	0
Lvl_GraphicsPtr_l:
	dc.l	0
Lvl_ClipsPtr_l:
	dc.l	0
Lvl_ModPropertiesPtr_l:
	dc.l	0
Lvl_ErrataPtr_l:
	dc.l	0

; Level filenames (copied from data/level_data.s layout for compatibility).
Lvl_BinFilename_vb:
	dc.b	"ab3:levels/level_"
Lvl_BinFilenameX_vb:
	dc.b	"a/twolev.bin",0
Lvl_GfxFilename_vb:
	dc.b	"ab3:levels/level_"
Lvl_GfxFilenameX_vb:
	dc.b	"a/twolev.graph.bin",0
Lvl_ClipsFilename_vb:
	dc.b	"ab3:levels/level_"
Lvl_ClipsFilenameX_vb:
	dc.b	"a/twolev.clips",0
Lvl_MapFilename_vb:
	dc.b	"ab3:levels/level_"
Lvl_MapFilenameX_vb:
	dc.b	"a/twolev.map",0
Lvl_FlyMapFilename_vb:
	dc.b	"ab3:levels/level_"
Lvl_FlyMapFilenameX_vb:
	dc.b	"a/twolev.flymap",0
Lvl_FloorFilename_vb:
	dc.b	"ab3:levels/level_"
Lvl_FloorFilenameX_vb:
	dc.b	"a/floortile",0
Lvl_WallFilename_vb:
	dc.b	"ab3:levels/level_"
Lvl_WallFilenameX_vb:
	dc.b	"a/wall_"
Lvl_WallFilenameN_vb:
	dc.b	"0.256wad",0
Lvl_ModPropsFilename_vb:
	dc.b	"ab3:levels/level_"
Lvl_ModPropsFilenameX_vb:
	dc.b	"a/properties.dat",0
Lvl_ErrataFilename_vb:
	dc.b	"ab3:levels/level_"
Lvl_ErrataFilenameX_vb:
	dc.b	"a/errata.dat",0
	even

ie_res_hex_digits:
	dc.b	"0123456789ABCDEF"

ie_res_pal_name_vb:
	dcb.b	256,0
ie_res_obj_name_vb:
	dcb.b	160,0
ie_res_ext_wad:
	dc.b	".wad",0
ie_res_ext_ptr:
	dc.b	".ptr",0
ie_res_ext_256pal:
	dc.b	".256pal",0
	even
