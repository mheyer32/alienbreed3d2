
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
				move.b	Prefs_FullScreen_b,Vid_FullScreen_b
				move.b	Prefs_FullScreen_b,Vid_FullScreenTemp_b
				move.b	Prefs_SimpleLighting_b,Draw_ForceSimpleWalls_b
				move.b	Prefs_FPSLimit_b,Vid_FPSLimit_l+3
				move.b	Prefs_VertMargin_b,Vid_LetterBoxMarginHeight_w+1
				move.b	Prefs_DynamicLights_b,Anim_LightingEnabled_b
				move.b	Prefs_RenderQuality_b,Draw_GoodRender_b

;				tst.w 	_Vid_isRTG ; no RTG in asm version yet
;				bne.s	.done

				move.b Prefs_PixelMode_b,_Vid_DoubleHeight_b

				move.w Prefs_ContrastAdjust_AGA_w,Vid_ContrastAdjust_w
				move.w Prefs_BrightnessOffset_AGA_w,Vid_BrightnessOffset_w
				move.b Prefs_GammaLevel_AGA_b,Vid_GammaLevel_b
.done:
				rts


game_SavePreferences:
				move.b	Vid_FullScreen_b,Prefs_FullScreen_b
				move.b	Draw_ForceSimpleWalls_b,Prefs_SimpleLighting_b
				move.b	Vid_FPSLimit_l+3,Prefs_FPSLimit_b
				move.b	Vid_LetterBoxMarginHeight_w+1,Prefs_VertMargin_b
				move.b	Anim_LightingEnabled_b,Prefs_DynamicLights_b
				move.b	Draw_GoodRender_b,Prefs_RenderQuality_b

				move.w Vid_ContrastAdjust_w,Prefs_ContrastAdjust_AGA_w
				move.w Vid_BrightnessOffset_w,Prefs_BrightnessOffset_AGA_w
				move.b Vid_GammaLevel_b,Prefs_GammaLevel_AGA_b

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

