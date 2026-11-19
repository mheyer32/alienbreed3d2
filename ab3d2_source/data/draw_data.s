			section .data,data

; Statically initialised (non-zero) data

				align 4
draw_TeleportShimmerFXData_vb:
				incbin	"includes/shimmerfile"

				align 4
draw_WaterFrames_vb:
				incbin	"waterfile"

				align 4

	DCLC draw_Palette_vw
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

	DCLC draw_FontPtrs_vl
				dc.l	draw_EndFont0_vb
				dc.l	draw_CharWidths0_vb
				dc.l	ENDFONT1,CHARWIDTHS1
				dc.l	ENDFONT2,CHARWIDTHS2

				align 4

	DCLC draw_BorderChars_vb
				incbin	"includes/bordercharsraw"

				align 4
	DCLC draw_ScrollChars_vb
				incbin	"includes/scrollfont"

				IFND	GEN_GLYPH_DATA
				; We are using precalculated glyph spacing data
	DCLC draw_GlyphSpacing_vb
				incbin	"includes/glyph_spacing.bin"
				ENDC

				align 4
draw_Digits_vb:
				incbin	"numbers.inc"

				align 4
draw_BackdropImageName_vb:
				dc.b	"ab3:includes/rawbackpacked",0
				align 4

	DCLC draw_BorderPacked_vb
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


; Zero terminated -y,x relative coordinate byte pairs for rasterised half circles.
; Once the stride size is known, these are converted to word offsets that can be
; added to a base pointer location within the render buffer to select the address
; of the pixel to be plotted.
;
; Word offset conversion takes the byte y ordinate, selects the corresponding stride value
; then negates it as we are defining the "upper" half. The x ordinate is sign extended
; then added. The result is a signed 16-bit offset compatible with (An,Xn) addressing. To
; plot the full circle, we set the pixel at Address + offset and Address -offset.

				align 4

draw_SmallCicleList_vw:
sc_radius_1:
				dc.b	1,0,0,-1
				dc.b	0,0 ; end

sc_radius_2:
				dc.b	2,0,1,-1,1,1,0,-2
				dc.b	0,0 ; end

sc_radius_3:
				dc.b	3,0,2,-1,2,1,1,-2,1,2,0,-3
				dc.b	0,0 ; end

sc_radius_4:
				dc.b	4,-1,4,0,4,1,3,-2,3,2,2,-3,2,3,1,-4,1,4,0,-4
				dc.b	0,0 ; end

sc_radius_5:
				dc.b	5,-1,5,0,5,1,4,-2,4,2,3,-3,3,3,2,-4,2,4,1,-5,1,5,0,-5
				dc.b	0,0 ; end

sc_radius_6:
				dc.b	6,-1,6,0,6,1,5,-3,5,-2,5,2,5,3,4,-4,4,4,3,-5,3,5,2,-5
				dc.b	2,5,1,-6,1,6,0,-6
				dc.b	0,0 ; end

sc_radius_7:
				dc.b	7,-1,7,0,7,1,6,-3,6,-2,6,2,6,3,5,-4,5,4,4,-5,4,5,3,-6
				dc.b	3,6,2,-6,2,6,1,-7,1,7,0,-7
				dc.b	0,0 ; end

sc_radius_8:
				dc.b	8,-1,8,0,8,1,7,-3,7,-2,7,2,7,3,6,-5,6,-4,6,4,6,5,5,-6
				dc.b	5,6,4,-6,4,6,3,-7,3,7,2,-7,2,7,1,-8,1,8,0,-8
				dc.b	0,0 ; end

sc_radius_9:	dc.b	9,-2,9,-1,9,0,9,1,9,2,8,-4,8,-3,8,3,8,4,7,-5,7,5,6,-6
				dc.b	6,6,5,-7,5,7,4,-8,4,8,3,-8,3,8,2,-9,2,9,1,-9,1,9,0,-9
				dc.b	0,0 ; end

sc_radius_10:
				dc.b	10,-2,10,-1,10,0,10,1,10,2,9,-4,9,-3,9,3,9,4,8,-5,8,5
				dc.b	7,-6,7,6,6,-7,6,7,5,-8,5,8,4,-9,4,9,3,-9,3,9,2,-10,2,10
				dc.b	1,-10,1,10,0,-10
				dc.b	0,0 ; end

sc_radius_11:
				dc.b	11,-2,11,-1,11,0,11,1,11,2,10,-4,10,-3,10,3,10,4,9,-6
				dc.b	9,-5,9,5,9,6,8,-7,8,7,7,-8,7,8,6,-9,6,9,5,-9,5,9,4,-10
				dc.b	4,10,3,-10,3,10,2,-11,2,11,1,-11,1,11,0,-11
				dc.b	0,0 ; end

sc_radius_12:
				dc.b	12,-2,12,-1,12,0,12,1,12,2,11,-4,11,-3,11,3,11,4,10,-6
				dc.b	10,-5,10,5,10,6,9,-7,9,7,8,-8,8,8,7,-9,7,9,6,-10,6,10
				dc.b	5,-10,5,10,4,-11,4,11,3,-11,3,11,2,-12,2,12,1,-12,1,12
				dc.b	0,-12
				dc.b	0,0 ; end

sc_radius_13:
				dc.b	13,-2,13,-1,13,0,13,1,13,2,12,-5,12,-4,12,-3,12,3,12,4
				dc.b	12,5,11,-6,11,6,10,-8,10,-7,10,7,10,8,9,-9,9,9,8,-10,8,10
				dc.b	7,-10,7,10,6,-11,6,11,5,-12,5,12,4,-12,4,12,3,-12,3,12
				dc.b	2,-13,2,13,1,-13,1,13,0,-13
				dc.b	0,0 ; end

sc_radius_14:
				dc.b	14,-2,14,-1,14,0,14,1,14,2,13,-5,13,-4,13,-3,13,3,13,4
				dc.b	13,5,12,-7,12,-6,12,6,12,7,11,-8,11,8,10,-9,10,9,9,-10
				dc.b	9,10,8,-11,8,11,7,-12,7,12,6,-12,6,12,5,-13,5,13,4,-13
				dc.b	4,13,3,-13,3,13,2,-14,2,14,1,-14,1,14,0,-14
				dc.b	0,0 ; end

sc_radius_15:
				dc.b	15,-2,15,-1,15,0,15,1,15,2,14,-5,14,-4,14,-3,14,3,14,4
				dc.b	14,5,13,-7,13,-6,13,6,13,7,12,-8,12,8,11,-9,11,9,10,-10
				dc.b	10,10,9,-11,9,11,8,-12,8,12,7,-13,7,13,6,-13,6,13,5,-14
				dc.b	5,14,4,-14,4,14,3,-14,3,14,2,-15,2,15,1,-15,1,15,0,-15
				dc.b	0,0 ; end

draw_EndSmallCicleList:
				dc.w	-1

				align 4
draw_SmallCiclePtrs_vl:
				dc.l	sc_radius_1
				dc.l	sc_radius_2
				dc.l	sc_radius_3
				dc.l	sc_radius_4
				dc.l	sc_radius_5
				dc.l	sc_radius_6
				dc.l	sc_radius_7
				dc.l	sc_radius_8
				dc.l	sc_radius_9
				dc.l	sc_radius_10
				dc.l	sc_radius_11
				dc.l	sc_radius_12
				dc.l	sc_radius_13
				dc.l	sc_radius_14
				dc.l	sc_radius_15
