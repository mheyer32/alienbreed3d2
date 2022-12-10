
			section bss,bss

; BSS data - to be included in BSS section
			align 4

draw_DepthTable_vl:		ds.l	80
draw_EndDepthTable:
TOPOFROOM:				ds.l	1
BOTOFROOM:				ds.l	1
AFTERWATTOP:			ds.l	1
AFTERWATBOT:			ds.l	1
BEFOREWATTOP:			ds.l	1
BEFOREWATBOT:			ds.l	1
ROOMBACK:				ds.l	1
draw_ObjectOnOff_l:		ds.l	1

draw_PointAndPolyBrights_vl:	ds.l	4*16
draw_PointerTablePtr_l: 		ds.l	1
draw_StartOfObjPtr_l:			ds.l	1
Draw_PolyObjects_vl:			ds.l	40

; FIMXE: screenconv stores word sized points, why are they using ds.l here?
boxonscr:						ds.l	250*2	; projected 2D points in screenspace
boxrot:							ds.l	250*3	; rotated 3D points in X/Z plane (y pointing up)

Objects:						ds.l	38*4

TextureMaps:					ds.l	1
TexturePal:						ds.l	1
testval:						ds.l	1

boxbrights:		ds.w	250

boxang:			ds.w	1

				ds.w	SCREENWIDTH*4
PolyBotTab:		ds.w	SCREENWIDTH*8
				ds.w	SCREENWIDTH*4
PolyTopTab:		ds.w	SCREENWIDTH*8
				ds.w	SCREENWIDTH*4


Draw_CurrentZone_w:		ds.w	1 ; public
draw_SortIt_w:			ds.w	1
draw_ObjectBright_w:	ds.w	1
draw_ObjectAng_w:		ds.w	1
draw_PolygonCentreY_w:	ds.w	1
draw_ObjClipT_w:		ds.w	1
draw_ObjClipB_w:		ds.w	1
draw_RightClipB_w:		ds.w	1
draw_LeftClipB_w:		ds.w	1
draw_AuxX_w:			ds.w	1
draw_AuxY_w:			ds.w	1
draw_BrightToAdd_w:		ds.w	1
draw_Obj_XPos_w:		ds.w	1
draw_Obj_ZPos_w:		ds.w	1
draw_NumPoints_w:		ds.w	1
draw_OffLeftBy_w:		ds.w	1
draw_Left_w:			ds.w	1
draw_Right_w:			ds.w	1


draw_WhichDoing_b:		ds.b	1 ; BOOL
draw_InUpperZone_b:		ds.b	1 ; BOOL
