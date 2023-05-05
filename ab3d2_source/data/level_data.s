			section .data,data

; Statically initialised (non-zero) data

			align 4
; Level data filenames. These are Aud_Null1_vw terminated strings that are split on the character for the
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
