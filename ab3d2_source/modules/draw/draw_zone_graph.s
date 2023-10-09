Draw_Zone_Graph:
				move.l	Zone_EndOfListPtr_l,a0
; move.w #-1,(a0)

; move.l #Zone_FinalOrderTable_vw,a0

; 0xABADCAFE - This is where we process the visible zones and their content
.subroomloop:
; move.w (a0)+,d7
				move.w	-(a0),d7
				blt		.done_all_zones

				move.l	a0,-(a7)

				move.l	Lvl_ZoneAddsPtr_l,a0
				move.l	(a0,d7.w*4),a0
				add.l	Lvl_DataPtr_l,a0
				move.l	ZoneT_Roof_l(a0),SplitHeight
				move.l	a0,draw_BackupRoomPtr_l

				move.l	Lvl_ZoneGraphAddsPtr_l,a0
				move.l	4(a0,d7.w*8),a2
				move.l	(a0,d7.w*8),a0

				add.l	Lvl_GraphicsPtr_l,a0
				add.l	Lvl_GraphicsPtr_l,a2
				move.l	a2,ThisRoomToDraw+4
				move.l	a0,ThisRoomToDraw

				move.l	Lvl_ListOfGraphRoomsPtr_l,a1

.finditit:
				tst.w	(a1)
				blt		.nomoretodoatall

				cmp.w	(a1),d7
				beq		.done_find

				adda.w	#8,a1
				bra		.finditit

.done_find:
				move.l	a1,-(a7)

				; First, initialise the clips to the extreme left/right of the view and refines
				move.w	#0,Draw_LeftClip_w
				move.w	Vid_RightX_w,Draw_RightClip_w
				moveq	#0,d7
				move.w	2(a1),d7
				blt.s	.done_right_clip

				move.l	Lvl_ClipsPtr_l,a0
				lea		(a0,d7.l*2),a0
				tst.w	(a0)
				blt.s	.done_left_clip

				bsr		Draw_SetLeftClip

.left_clip:	;		clips
				tst.w	(a0)
				blt.s	.done_left_clip

				bsr		Draw_SetLeftClip
				bra.s	.left_clip

.done_left_clip:
				addq	#2,a0

				tst.w	(a0)
				blt		.done_right_clip

				bsr		Draw_SetRightClip

.right_clip:	;		clips
				tst.w	(a0)
				blt		.done_right_clip

				bsr		Draw_SetRightClip
				bra		.right_clip

.done_right_clip:

				; 0xABADCAFE - sign extensions and comparisons. Check these
				move.w	Draw_LeftClip_w,d0
				ext.l	d0
				move.l	d0,Draw_LeftClip_l

				cmp.w	Vid_RightX_w,d0
				bge		.skip_not_visible

				move.w	Draw_RightClip_w,d1
				ext.l	d1
				move.l	d1,Draw_RightClip_l
				blt		.skip_not_visible

				cmp.w	d1,d0
				bge		.skip_not_visible

				move.l	yoff,d0
				cmp.l	SplitHeight,d0
				blt		.lower_zone_first

				move.l	ThisRoomToDraw+4,a0
				cmp.l	Lvl_GraphicsPtr_l,a0
				beq.s	.lower_zone_only

				st		Draw_DoUpper_b

				move.l	draw_BackupRoomPtr_l,a1
				move.l	ZoneT_UpperRoof_l(a1),Draw_TopOfRoom_l
				move.l	ZoneT_UpperFloor_l(a1),Draw_BottomOfRoom_l

				move.l	#CurrentPointBrights_vl+4,Draw_PointBrightsPtr_l
				bsr		draw_RenderCurrentZone

				; Room does not have an upper zone
.lower_zone_only:
				move.l	ThisRoomToDraw,a0
				clr.b	Draw_DoUpper_b
				move.l	#CurrentPointBrights_vl,Draw_PointBrightsPtr_l

				move.l	draw_BackupRoomPtr_l,a1
				move.l	ZoneT_Roof_l(a1),d0
				move.l	d0,Draw_TopOfRoom_l
				move.l	ZoneT_Floor_l(a1),d1
				move.l	d1,Draw_BottomOfRoom_l

				move.l	ZoneT_Water_l(a1),d2
				cmp.l	yoff,d2
				blt.s	.lzo_above_water_first

				move.l	d2,Draw_BeforeWaterTop_l
				move.l	d1,Draw_BeforeWaterBottom_l
				move.l	d2,Draw_AfterWaterBottom_l
				move.l	d0,Draw_AfterWaterTop_l
				bra.s	.lzo_below_water_first

.lzo_above_water_first:
				move.l	d0,Draw_BeforeWaterTop_l
				move.l	d2,Draw_BeforeWaterBottom_l
				move.l	d1,Draw_AfterWaterBottom_l
				move.l	d2,Draw_AfterWaterTop_l

.lzo_below_water_first:
				bsr		draw_RenderCurrentZone

				bra		.skip_not_visible

.lower_zone_first:
				move.l	ThisRoomToDraw,a0
				clr.b	Draw_DoUpper_b
				move.l	#CurrentPointBrights_vl,Draw_PointBrightsPtr_l
				move.l	draw_BackupRoomPtr_l,a1
				move.l	ZoneT_Roof_l(a1),d0
				move.l	d0,Draw_TopOfRoom_l
				move.l	ZoneT_Floor_l(a1),d1
				move.l	d1,Draw_BottomOfRoom_l
				move.l	ZoneT_Water_l(a1),d2
				cmp.l	yoff,d2
				blt.s	.lzf_above_water_first

				move.l	d2,Draw_BeforeWaterTop_l
				move.l	d1,Draw_BeforeWaterBottom_l
				move.l	d2,Draw_AfterWaterBottom_l
				move.l	d0,Draw_AfterWaterTop_l
				bra.s	.lzf_below_water_first

.lzf_above_water_first:
				move.l	d0,Draw_BeforeWaterTop_l
				move.l	d2,Draw_BeforeWaterBottom_l
				move.l	d1,Draw_AfterWaterBottom_l
				move.l	d2,Draw_AfterWaterTop_l

.lzf_below_water_first:
				bsr		draw_RenderCurrentZone
				move.l	ThisRoomToDraw+4,a0
				cmp.l	Lvl_GraphicsPtr_l,a0
				beq.s	.noupperroom2

				move.l	#CurrentPointBrights_vl+4,Draw_PointBrightsPtr_l
				move.l	draw_BackupRoomPtr_l,a1
				move.l	ZoneT_UpperRoof_l(a1),Draw_TopOfRoom_l
				move.l	ZoneT_UpperFloor_l(a1),Draw_BottomOfRoom_l

				st		Draw_DoUpper_b
				bsr		draw_RenderCurrentZone
.noupperroom2:

.skip_not_visible:
;pastemp:

				move.l	(a7)+,a1
				move.l	ThisRoomToDraw,a0
				move.w	(a0),d7

				adda.w	#8,a1
				bra		.finditit

.nomoretodoatall:

				move.l	(a7)+,a0

				bra		.subroomloop

.done_all_zones:
				rts

draw_RenderCurrentZone:
				move.w	(a0)+,d0
				move.w	d0,Draw_CurrentZone_w
				move.w	d0,d1
				muls	#40,d1
				add.l	#Lvl_BigMap_vl,d1
				move.l	d1,Lvl_BigMapPtr_l
				move.w	d0,d1
				ext.l	d1
				asl.w	#2,d1
				add.l	#Lvl_CompactMap_vl,d1
				move.l	d1,Lvl_CompactMapPtr_l
				add.l	#4,d1
				cmp.l	LastZonePtr_l,d1
				ble.s	.no_change

				move.l	d1,LastZonePtr_l

.no_change:
				move.l	#Zone_BrightTable_vl,a1
				move.l	(a1,d0.w*4),d1
				tst.b	Draw_DoUpper_b
				bne.s	.ok_bottom

				swap	d1

.ok_bottom:
				move.w	d1,Zone_Bright_w

.draw_loop:
				move.w	(a0)+,d0
				move.w	d0,draw_WallID_w
				and.w	#$ff,d0

				; TODO - 0xABADCAFE - this can be a regular jump table.
				; 0     => itsawall
				; 1,2   => itsafloor (or ceiling)
				; 3     => itsasetclip (unused)
				; 4     => itsanobject
				; 5,6   => do nothing (no arcs/light beams yet. Intriguing idea)
				; 7     => itswater
				; 8,9   => itsachunkyfloor (unused)
				; 10,11 => itsabumpyfloor (unused)
				; 12    => itsbackdrop
				; 13    => itsaseewall (unused)

				tst.b	d0
				blt		.end_draw_loop
				beq		.itsawall

				cmp.w	#3,d0
				blt		.itsafloor

				cmp.w	#4,d0
				beq		.itsanobject

				cmp.w	#7,d0
				beq.s	.itswater

				cmp.w	#12,d0
				beq.s	.itsbackdrop

				bra		.draw_loop

.itsbackdrop:
				jsr		Draw_SkyBackdrop
				bra		.draw_loop

.itswater:
				move.w	#2,SMALLIT
				move.w	#3,d0
				clr.b	draw_UseGouraudFlats_b
				st		draw_UseWater_b
				jsr		Draw_Flats
				bra		.draw_loop

.itsanobject:
				jsr		Draw_Objects
				bra		.draw_loop

.itsafloor:
				move.l	Draw_PointBrightsPtr_l,FloorPtBrightsPtr_l
				move.w	Draw_CurrentZone_w,d1
				muls	#80,d1
				cmp.w	#2,d0
				bne.s	.nfl

				add.l	#2,d1
.nfl:
				add.l	d1,FloorPtBrightsPtr_l
				move.w	#1,SMALLIT

; Its possible that the reason for swithcing into SV mode was to be able to
; manipulate CACR, for instance to disable write-allocation when doing the floor
; tiles. This would make sense as keeping the runtime variable in cache is more important
; than allocating cache lines for the written pixels.

; FIXME: Indeed, it seems for A1200  with no fastram and its 68020, with its tiny
; instruction cache it made sense to freeze the ICache after the first iteration
; of floor drawing to keep the innermost loop in cache and thus require less bus accesses
; when churning out the floor pixels.
;
; I had removed many CACHE_FREEZE_OFF calls from the code - need to reinstate those.
; Not sure how much sense it made for later CPU models, though.

;				movem.l	a0/d0,-(a7)
;				move.l	$4.w,a6
;				jsr		_LVOSuperState(a6)
;				move.l	d0,SSTACK
;				movem.l	(a7)+,a0/d0

				;* 1,2 = floor/roof
				clr.b	draw_UseWater_b
				move.b	draw_GouraudFlatsSelected_b,draw_UseGouraudFlats_b
				jsr		Draw_Flats

;				move.l	a0,-(a7)
;				move.l	$4.w,a6
;				move.l	SSTACK,d0
;				jsr		_LVOUserState(a6)
;				move.l	(a7)+,a0

				bra		.draw_loop

.itsawall:
;				; clr.b	wall_SeeThrough_b
;				; move.l #stripbuffer,a1
				jsr		Draw_Wall
				bra		.draw_loop

.end_draw_loop:
				rts
