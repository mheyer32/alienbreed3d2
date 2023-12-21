
; *****************************************************************************
; *
; * modules/game/game_preferences.s
; *
; * Handles the persistence of in-game user settings
; *
; *****************************************************************************

				IFND BUILD_WITH_C
				align 4

game_LoadPreferences:
				movem.l	d0-d4/a6,-(a7)

				move.l	#game_PreferencesFile_vb,d1
				move.l	#MODE_OLDFILE,d2
				CALLDOS	Open

				move.l	d0,d1 ; file handle handle in d1
				beq.s	.io_error

				move.l	d0,d4 ; backup handle in d4

				move.l	#Prefsfile,d2
				move.l	#PrefsfileEnd,d3
				sub.l	d2,d3 ; size in d3

				CALLDOS	Read

				move.l	d0,d2 ; bytes read

				move.l	d4,d1 ; d1 trashed by read
				CALLDOS Close

				cmp.l	d2,d3 ; check read size
				bne.s	.io_error

				; assume loaded OK
				movem.l	(a7)+,d0-d4/a6

				; drop through here
				bra.s	game_ApplyPreferences

.io_error:
				movem.l	(a7)+,d0-d4/a6
				rts


game_ApplyPreferences:
				move.b	_Prefs_FullScreen,Vid_FullScreen_b
				move.b	_Prefs_FullScreen,Vid_FullScreenTemp_b
				move.b	_Prefs_SimpleLighting,Draw_ForceSimpleWalls_b
				move.b	_Prefs_FPSLimit,Vid_FPSLimit_l+3
				move.b	_Prefs_VertMargin,Vid_LetterBoxMarginHeight_w+1
				move.b	_Prefs_DynamicLights,Anim_LightingEnabled_b
				move.b	_Prefs_RenderQuality,Draw_GoodRender_b

;				tst.w 	_Vid_isRTG ; no RTG in asm version yet
;				bne.s	.done

				move.b _Prefs_PixelMode,_Vid_DoubleHeight_b

.done:
				rts


game_SavePreferences:
				move.b	Vid_FullScreen_b,_Prefs_FullScreen
				move.b	Draw_ForceSimpleWalls_b,_Prefs_SimpleLighting
				move.b	Vid_FPSLimit_l+3,_Prefs_FPSLimit
				move.b	Vid_LetterBoxMarginHeight_w+1,_Prefs_VertMargin
				move.b	Anim_LightingEnabled_b,_Prefs_DynamicLights
				move.b	Draw_GoodRender_b,_Prefs_RenderQuality

				movem.l	d0-d4/a6,-(a7)

				move.l	#game_PreferencesFile_vb,d1
				move.l	#MODE_READWRITE,d2
				CALLDOS	Open

				move.l	d0,d1 ; file handle handle in d1
				beq.s	.io_error

				move.l	d0,d4

				move.l	#Prefsfile,d2
				move.l	#PrefsfileEnd,d3
				sub.l	d2,d3 ; size in d3

				CALLDOS	Write

				;move.l	d0,d2 ; bytes written - what can we even do if this went wrong?

				move.l	d4,d1 ; d1 trashed by read
				CALLDOS Close

				movem.l	(a7)+,d0-d4/a6
				rts

.io_error:
				movem.l	(a7)+,d0-d4/a6
				rts

				ENDIF

