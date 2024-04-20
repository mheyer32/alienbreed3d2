			section .data,data

; Statically initialised (non-zero) data

			align 4
; Level data filenames. These are null terminated strings that are split on the character for the
; name. This is poked in during loading.
Lvl_BinFilename_vb:			dc.b	'ab3:levels/level_'
Lvl_BinFilenameX_vb:		dc.b	'a/twolev.bin',0
Lvl_GfxFilename_vb:			dc.b	'ab3:levels/level_'
Lvl_GfxFilenameX_vb:		dc.b	'a/twolev.graph.bin',0
Lvl_ClipsFilename_vb:		dc.b	'ab3:levels/level_'
Lvl_ClipsFilenameX_vb:		dc.b	'a/twolev.clips',0
Lvl_MapFilename_vb:			dc.b	'ab3:levels/level_'
Lvl_MapFilenameX_vb:		dc.b	'a/twolev.map',0
Lvl_FlyMapFilename_vb:		dc.b	'ab3:levels/level_'
Lvl_FlyMapFilenameX_vb:		dc.b	'a/twolev.flymap',0

; For per-level floor overrides
_Lvl_FloorFilename_s::	; for C
Lvl_FloorFilename_vb:		dc.b	'ab3:levels/level_'
Lvl_FloorFilenameX_vb:		dc.b	'a/floortile',0

; For per-level wall overrides
Lvl_WallFilename_vb:		dc.b	'ab3:levels/level_'
Lvl_WallFilenameX_vb:		dc.b	'a/wall_'
Lvl_WallFilenameN_vb:		dc.b	'0.256wad',0

; For per-level modifications (
_Lvl_ModPropsFilename_s::	; for C
Lvl_ModPropsFilename_vb:		dc.b	'ab3:levels/level_'
Lvl_ModPropsFilenameX_vb:		dc.b	'a/properties.dat',0
