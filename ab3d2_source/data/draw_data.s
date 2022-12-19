			section data,data

; Statically initialised (non-zero) data

			align 4
draw_WaterFrames_vb:	incbin	"waterfile"

			align 4
draw_Palette_vw:		incbin	"256pal"

			align 4
draw_EndFont0_vb:		incbin	"endfont0"
draw_CharWidths0_vb:	incbin	"charwidths0"
ENDFONT1:
CHARWIDTHS1:
ENDFONT2:
CHARWIDTHS2:

			align 4
draw_FontPtrs_vl:		dc.l	draw_EndFont0_vb,draw_CharWidths0_vb
						dc.l	ENDFONT1,CHARWIDTHS1
						dc.l	ENDFONT2,CHARWIDTHS2

			align 4
draw_BorderChars_vb:	incbin	"includes/bordercharsraw"

			align 4
draw_ScrollChars_vb:	incbin	"includes/scrollfont"

			align 4
draw_Digits_vb:			incbin	"numbers.inc"

			align 4
draw_BackdropImageName_vb:	dc.b	"ab3:includes/rawbackpacked",0
;bordername:		dc.b	"ab3:includes/newborderRAW",0

			align 4
borderpacked:	incbin	"includes/newborderpacked"
				ds.b	8	; safety for unLha overrun
