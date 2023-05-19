			section .data,data

; Statically initialised (non-zero) data

				align 4
draw_TeleportShimmerFXData_vb:
				incbin	"includes/shimmerfile"

				align 4
draw_WaterFrames_vb:
				incbin	"waterfile"

				align 4
_draw_Palette_vw::
draw_Palette_vw:
				incbin	"256pal"

				align 4
draw_EndFont0_vb:
				incbin	"endfont0"
draw_CharWidths0_vb:
				incbin	"charwidths0"
ENDFONT1:
				align 4
CHARWIDTHS1:
ENDFONT2:
CHARWIDTHS2:

draw_FontPtrs_vl:
				dc.l	draw_EndFont0_vb,draw_CharWidths0_vb
				dc.l	ENDFONT1,CHARWIDTHS1
				dc.l	ENDFONT2,CHARWIDTHS2

				align 4
draw_BorderChars_vb:
				incbin	"includes/bordercharsraw"

				align 4
draw_ScrollChars_vb:
				incbin	"includes/scrollfont"

				align 4
draw_Digits_vb:
				incbin	"numbers.inc"

				align 4
draw_BackdropImageName_vb:
				dc.b	"ab3:includes/rawbackpacked",0
				align 4

_draw_BorderPacked_vb::
draw_BorderPacked_vb:
				incbin	"includes/newborderpacked"
				ds.b	16	; safety for unLha overrun

				align 4
draw_Brights_vw:
				dc.w	3
				dc.w	8,9,10,11,12
				dc.w	15,16,17,18,19
				dc.w	21,22,23,24,25,26,27
				dc.w	29,30,31,32,33
				dc.w	36,37,38,39,40
				dc.w	45

draw_Brights2_vw:
				dc.w	3
				dc.w	12,11,10,9,8
				dc.w	19,18,17,16,15
				dc.w	27,26,25,24,23,22,21
				dc.w	33,32,31,30,29
				dc.w	40,39,38,37,36
				dc.w	45

willy:
				dc.w	0,0,0,0,0,0,0
				dc.w	5,5,5,5,5,5,5
				dc.w	10,10,10,10,10,10,10
				dc.w	15,15,15,15,15,15,15
				dc.w	20,20,20,20,20,20,20
				dc.w	25,25,25,25,25,25,25
				dc.w	30,30,30,30,30,30,30

willybright:
				dc.w	30,30,30,30,30,30,30
				dc.w	30,20,20,20,20,20,30
				dc.w	30,20,6,3,6,20,30
				dc.w	30,20,6,0,6,20,30
				dc.w	30,20,6,6,6,20,30
				dc.w	30,20,20,20,20,20,30
				dc.w	30,30,30,30,30,30,30

draw_XZAngs_vw:
				dc.w	0,23,10,20,16,16,20,10
				dc.w	23,0,20,-10,16,-16,10,-20
				dc.w	0,-23,-10,-20,-16,-16,-20,-10
				dc.w	-23,0,-20,10,-16,16,-10,20

; todo - what is this?
guff:			incbin	"includes/guff"
