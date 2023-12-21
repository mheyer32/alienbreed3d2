			section .data,data

; Statically initialised (non-zero) data

			align 4

_Game_PropertiesFile::
Game_PropertiesFile_vb:		dc.b	"ab3:Includes/game_properties.dat",0

_Game_SettingsFile::
Game_SettingsFile_vb:		dc.b	"ab3:game.prefs",0

_Game_StatsFile::
Game_StatsFile_vb:			dc.b	"ab3:game.stats",0
