
			section bss,bss

; BSS data - to be included in BSS section

; TODO - Gather by access patterns and group into cache lines for hot/nearby date and
; consolidated blocks by size/alignment for everything else

			align 4

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
Draw_PolyObjects_vl:			ds.l	40

; FIMXE: screenconv stores word sized points, why are they using ds.l here?
boxonscr:						ds.l	250*2	; projected 2D points in screenspace
boxrot:							ds.l	250*3	; rotated 3D points in X/Z plane (y pointing up)

Draw_WallTexturePtrs_vl:		ds.l	40
Draw_ObjectPtrs_vl:				ds.l	38*4
Draw_TextureMapsPtr_l:			ds.l	1
Draw_TexturePalettePtr_l:		ds.l	1
Draw_BackdropImagePtr_l:		ds.l	1
Draw_FloorTexturesPtr_l:		ds.l	1
Draw_PalettePtr_l:				ds.l	1
Draw_ChunkPtr_l:				ds.l	1

draw_AngleBrights_vl:			ds.l	8*2
draw_Pals_vl:					ds.l	2*49
draw_WADPtr_l:					ds.l	1
draw_PtrPtr_l:					ds.l	1 ; todo - find what this actually points to
draw_PolyAngPtr_l:				ds.l	1
draw_PointAngPtr_l:				ds.l	1

toppt_l:						ds.l	1
midobj_l:						ds.l	1
boxbrights:						ds.w	250
boxang:							ds.w	1

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

draw_WhichDoing_b:				ds.b	1
draw_InUpperZone_b:				ds.b	1
Draw_DoUpper_b:					ds.b	1
