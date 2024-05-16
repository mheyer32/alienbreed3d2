
			section .bss,bss

; BSS data - to be included in BSS section

; TODO - Gather by access patterns and group into cache lines for hot/nearby date and
; consolidated blocks by size/alignment for everything else

			align 4

DRAW_MAX_POLY_OBJECTS=40
DRAW_MAX_OBJECTS=38

draw_DepthTable_vl:			ds.l	80
draw_DepthTableEnd:

Draw_TopOfRoom_l:			ds.l	1
Draw_BottomOfRoom_l:		ds.l	1
Draw_AfterWaterTop_l:		ds.l	1
Draw_AfterWaterBottom_l:	ds.l	1
Draw_BeforeWaterTop_l:		ds.l	1
Draw_BeforeWaterBottom_l:	ds.l	1
draw_BackupRoomPtr_l:		ds.l	1
draw_ObjectOnOff_l:			ds.l	1

draw_PointAndPolyBrights_vl:	ds.l	4*16
draw_PointerTablePtr_l: 		ds.l	1
draw_StartOfObjPtr_l:			ds.l	1
Draw_PolyObjects_vl:			ds.l	DRAW_MAX_POLY_OBJECTS

; FIMXE: screenconv stores word sized points, why are they using ds.l here?
draw_2DPointsProjected_vl:		ds.l	250*2	; projected 2D points in screenspace
draw_3DPointsRotated_vl:		ds.l	250*3	; rotated 3D points in X/Z plane (y pointing up)

Draw_WallTexturePtrs_vl:		ds.l	NUM_WALL_TEXTURES
Draw_ObjectPtrs_vl:				ds.l	DRAW_MAX_OBJECTS*4
Draw_TextureMapsPtr_l:			ds.l	1

; Shade Tables, 64x256
; The first 32 begin with pure white and gradually saturating towards the palette at row 32. Used for glare/specular.
; The remaining rows are increasingly darkended towards black and are used for general lighting.
; Each entry is byte index to the nearest palette match for the given variation.
Draw_TexturePalettePtr_l:		ds.l	1
Draw_BackdropImagePtr_l:		ds.l	1
Draw_FloorTexturesPtr_l:		ds.l	1 ; this will be a copy of either Draw_GlobalFloorTexturesPtr_l
										  ; or Draw_LevelFloorTexturesPtr_l if the level has an override.
Draw_PalettePtr_l:				ds.l	1
Draw_ChunkPtr_l:				ds.l	1


; Allow levels to override the floor texture tiles
Draw_GlobalFloorTexturesPtr_l:  ds.l	1 ; this is the pointer to the global set of floor tiles
Draw_LevelFloorTexturesPtr_l:	ds.l	1 ; this is the pointer to the current level override, if any.

; Allow levels to override individual wall textures
Draw_GlobalWallTexturePtrs_vl:	ds.l	NUM_WALL_TEXTURES
Draw_LevelWallTexturePtrs_vl:	ds.l	NUM_WALL_TEXTURES

draw_AngleBrights_vl:			ds.l	8*2
draw_Pals_vl:					ds.l	2*49
draw_WADPtr_l:					ds.l	1
draw_PtrPtr_l:					ds.l	1 ; todo - find what this actually points to
draw_PolyAngPtr_l:				ds.l	1
draw_PointAngPtr_l:				ds.l	1

toppt_l:						ds.l	1
midobj_l:						ds.l	1
boxbrights_vw:					ds.w	250
;boxang:							ds.w	1

								ds.w	SCREEN_WIDTH*4; draw_PolyBotTab_vw has negative offsets
draw_PolyBotTab_vw:				ds.w	SCREEN_WIDTH*8
								ds.w	SCREEN_WIDTH*4
draw_PolyTopTab_vw:				ds.w	SCREEN_WIDTH*8
								ds.w	SCREEN_WIDTH*4

draw_PartBuffer_vw: 			ds.w	4*32
draw_PartBufferEnd:

Draw_CurrentZone_w:				ds.w	1 ; public
draw_SortIt_w:					ds.w	1
draw_ObjectBright_w:			ds.w	1
draw_ObjectAng_w:				ds.w	1
draw_PolygonCentreY_w:			ds.w	1
draw_ObjClipT_w:				ds.w	1
draw_ObjClipB_w:				ds.w	1
draw_RightClipB_w:				ds.w	1
draw_LeftClipB_w:				ds.w	1
draw_AuxX_w:					ds.w	1
draw_AuxY_w:					ds.w	1
draw_BrightToAdd_w:				ds.w	1
draw_Obj_XPos_w:				ds.w	1
draw_Obj_ZPos_w:				ds.w	1
draw_NumPoints_w:				ds.w	1
draw_OffLeftBy_w:				ds.w	1
draw_Left_w:					ds.w	1
draw_Right_w:					ds.w	1
draw_DownStrip_w:				ds.w	1


; Border Ammo/Energy
_draw_DisplayEnergyCount_w::
draw_DisplayEnergyCount_w:      ds.w	1

_draw_DisplayAmmoCount_w::
draw_DisplayAmmoCount_w:	    ds.w	1

_draw_LastDisplayEnergyCount_w::
draw_LastDisplayEnergyCount_w:	ds.w	1

_draw_LastDisplayAmmoCount_w::
draw_LastDisplayAmmoCount_w:	ds.w	1

draw_WhichDoing_b:				ds.b	1
draw_InUpperZone_b:				ds.b	1
Draw_DoUpper_b:					ds.b	1
_Draw_ForceSimpleWalls_b::
Draw_ForceSimpleWalls_b:		ds.b	1

		; Are we generating glyph data?
		IFD	GEN_GLYPH_DATA
_draw_GlyphSpacing_vb::
draw_GlyphSpacing_vb:			ds.b    256
		ENDC
