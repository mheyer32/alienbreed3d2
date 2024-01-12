			section .data,data

; Statically initialised (non-zero) data

			align 4

_game_PropertiesFile::
game_PropertiesFile_vb:		dc.b	"ab3:Includes/game.props",0

_game_PreferencesFile::
game_PreferencesFile_vb:	dc.b	"ab3:game.prefs",0

_game_ProgressFile::
game_ProgressFile_vb:			dc.b	"ab3:game.stats",0
