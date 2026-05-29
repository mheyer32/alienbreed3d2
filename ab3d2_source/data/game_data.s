			section .data,data

; Statically initialised (non-zero) data

			align 4
	DCLC	GMod_PropertiesFile
			dc.b "ab3:includes/game_mod.tkgd",0
	DCLC	GMod_ProgressFile
			dc.b "ab3:progress.tkgd",0
	DCLC	game_PreferencesFile
			dc.b	"ab3:prefs.cfg",0

Game_SavedGamesName_vb:			dc.b	"ab3:boot.dat",0

game_Version_vb:
                                include "data/version.i"

