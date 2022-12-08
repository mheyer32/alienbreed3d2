
DRAW_BITMAP_NEAR_PLANE	EQU		25  ; Distances lower than this for bitmaps are considered behind the observer
DRAW_VECTOR_NEAR_PLANE	EQU		130 ; Distances lower than this for vectors are considered behind the observer

				CNOP 0,16
draw_DepthTable_vl:		ds.l	80
draw_EndDepthTable:
draw_TopY_3D_l:			dc.l	-100*1024
draw_BottomY_3D_l:		dc.l	1*1024

TOPOFROOM:		dc.l	0
BOTOFROOM:		dc.l	0
AFTERWATTOP:	dc.l	0
AFTERWATBOT:	dc.l	0
BEFOREWATTOP:	dc.l	0
BEFOREWATBOT:	dc.l	0
ROOMBACK:		dc.l	0

draw_ObjectOnOff_w:		dc.l	0

Draw_CurrentZone_w:		dc.w	0 ; public
draw_SortIt_w:			dc.w	0
draw_ObjectBright_w:	dc.w	0
draw_ObjectAng_w:		dc.w	0
draw_PolygonCentreY_w:	dc.w	0
draw_ObjClipT_w:		dc.w	0
draw_ObjClipB_w:		dc.w	0
draw_RightClipB_w:		dc.w	0
draw_LeftClipB_w:		dc.w	0
draw_AuxX_w:			dc.w	0
draw_AuxY_w:			dc.w	0
draw_BrightToAdd_w:		dc.w	0
draw_Obj_XPos_w:		dc.w	0
draw_Obj_ZPos_w:		dc.w	0

draw_WhichDoing_b:	dc.b	0 ; BOOL
draw_InUpperZone_b:	dc.b	0 ; BOOL

********************************************************************************

Draw_Object:
				move.w	(a0)+,d0
				cmp.w	#1,d0
				blt.s	.before_wat

				beq.s	.after_wat

				bgt.s	.full_room

.before_wat:
				move.l	BEFOREWATTOP,draw_TopY_3D_l
				move.l	BEFOREWATBOT,draw_BottomY_3D_l
				move.b	#1,draw_WhichDoing_b
				bra.s	.done_top_bot

.after_wat:
				move.l	AFTERWATTOP,draw_TopY_3D_l
				move.l	AFTERWATBOT,draw_BottomY_3D_l
				move.b	#0,draw_WhichDoing_b
				bra.s	.done_top_bot

.full_room:
				move.l	TOPOFROOM(pc),draw_TopY_3D_l
				move.l	BOTOFROOM(pc),draw_BottomY_3D_l
				move.b	#0,draw_WhichDoing_b

.done_top_bot:

; move.l (a0)+,draw_BottomY_3D_l
; move.l (a0)+,draw_TopY_3D_l

				movem.l	d0-d7/a1-a6,-(a7)
				move.w	rightclip,d0
				sub.w	leftclip,d0
				subq	#1,d0
				ble		.done_all_in_front

; CACHE_ON d6
				move.l	Lvl_ObjectDataPtr_l,a1
				move.l	#ObjRotated_vl,a2
				move.l	#draw_DepthTable_vl,a3
				move.l	a3,a4
				move.w	#79,d7

.empty_tab:
				move.l	#$80010000,(a3)+
				dbra	d7,.empty_tab

				moveq	#0,d0

.insert_an_object:
				move.w	(a1),d1
				blt		.sorted_all

				move.w	EntT_GraphicRoom_w(a1),d2
				cmp.w	Draw_CurrentZone_w(pc),d2
				beq.s	.in_this_zone

.not_in_this_zone:
				adda.w	#64,a1
				addq	#1,d0
				bra		.insert_an_object

.in_this_zone:
				move.b	DOUPPER,d4
				move.b	ShotT_InUpperZone_b(a1),d3
				eor.b	d4,d3
				bne.s	.not_in_this_zone

				move.w	2(a2,d1.w*8),d1			; zpos
				move.l	#draw_DepthTable_vl-4,a4

.still_in_front:
				addq	#4,a4
				cmp.w	(a4),d1
				blt		.still_in_front

				move.l	#draw_EndDepthTable-4,a5

.finished_shift:
				move.l	-(a5),4(a5)
				cmp.l	a4,a5
				bgt.s	.finished_shift

				move.w	d1,(a4)
				move.w	d0,2(a4)
				adda.w	#64,a1
				addq	#1,d0
				bra		.insert_an_object

.sorted_all:
				move.l	#draw_DepthTable_vl,a3

.go_back_and_do_another:
				move.w	(a3)+,d0
				blt.s	.done_all_in_front

				move.w	(a3)+,d0
				bsr		draw_Object

				bra		.go_back_and_do_another

.done_all_in_front:
				movem.l	(a7)+,d0-d7/a1-a6
				rts

;********************************************************************************

draw_Object:
				movem.l	d0-d7/a0-a6,-(a7)
				move.l	Lvl_ObjectDataPtr_l,a0
				move.l	#ObjRotated_vl,a1
				asl.w	#6,d0
				adda.w	d0,a0
				move.b	ShotT_InUpperZone_b(a0),draw_InUpperZone_b
				move.w	(a0),d0
				move.w	2(a1,d0.w*8),d1			; z pos

; Go through clip pts to see which
; apply.

; move.w #0,d2	; leftclip
; move.w #96,d3  ; rightclip

; move.l EndOfClipPt,a6
;checkclips:
; subq #8,a6
; cmp.l #ClipTable,a6
; blt outofcheckclips

; cmp.w 2(a6),d1
; bgt.s cantleft
; move.w (a6),d4
; cmp.w d4,d2
; bgt.s cantleft
; move.w d4,d2
;cantleft:

; cmp.w 6(a6),d1
; bgt.s cantright
; move.w 4(a6),d4
; cmp.w d4,d3
; blt.s cantright
; move.w d4,d3
;cantright:

;outofcheckclips:

; move.w d2,draw_LeftClipB_w
; move.w d3,draw_RightClipB_w

				move.w	leftclip,draw_LeftClipB_w
				move.w	rightclip,draw_RightClipB_w

				cmp.b	#$ff,6(a0)
				bne		draw_Bitmap

				bsr		draw_PolygonModel

				movem.l	(a7)+,d0-d7/a0-a6
				rts

********************************************************************************
;* Glass objects are not suported and likely broken
;				IFNE	0
;glassobj:
;				move.w	(a0)+,d0				;pt num
;				move.w	2(a1,d0.w*8),d1
;				cmp.w	#DRAW_BITMAP_NEAR_PLANE,d1
;				ble		object_behind
;
;				move.w	draw_TopClip_w,d2
;				move.w	draw_BottomClip_w,d3
;
;				move.l	draw_TopY_3D_l,d6
;				sub.l	yoff,d6
;				divs	d1,d6
;				add.w	Vid_CentreY_w,d6
;				cmp.w	d3,d6
;				bge		object_behind
;				cmp.w	d2,d6
;				bge.s	.okobtc
;				move.w	d2,d6
;.okobtc:
;				move.w	d6,draw_ObjClipT_w
;
;				move.l	draw_BottomY_3D_l,d6
;				sub.l	yoff,d6
;				divs	d1,d6
;				add.w	Vid_CentreY_w,d6
;				cmp.w	d2,d6
;				ble		object_behind
;				cmp.w	d3,d6
;				ble.s	.okobbc
;				move.w	d3,d6
;.okobbc:
;				move.w	d6,draw_ObjClipB_w
;
;				move.l	4(a1,d0.w*8),d0
;				move.l	(a0)+,d2				; height
;				ext.l	d2
;				asl.l	#7,d2
;				sub.l	yoff,d2
;				divs	d1,d2
;				add.w	Vid_CentreY_w,d2
;
;				divs	d1,d0
;				asr.w	d0						; DOUBLEWIDTH test
;
;				add.w	Vid_CentreX_w,d0				;x pos of middle
;
;; Need to calculate:
;; Width of object in pixels
;; height of object in pixels
;; horizontal constants
;; vertical constants.
;
;				move.l	#consttab,a3
;
;				moveq	#0,d3
;				moveq	#0,d4
;				move.b	(a0)+,d3
;				move.b	(a0)+,d4
;				asl.w	#7,d3
;				asl.w	#7,d4
;				divs	d1,d3					;width in pixels
;				divs	d1,d4					;height in pixels
;				sub.w	d4,d2
;				sub.w	d3,d0
;				cmp.w	draw_RightClipB_w,d0
;				bge		object_behind
;				add.w	d3,d3
;				cmp.w	draw_ObjClipB_w,d2
;				bge		object_behind
;
;				add.w	d4,d4
;
;				move.w	d3,draw_RealWidth_w
;				move.w	d4,draw_RealHeight_w
;
;* OBTAIN POINTERS TO HORIZ AND VERT
;* CONSTANTS FOR MOVING ACROSS AND
;* DOWN THE OBJECT GRAPHIC.
;
;				move.w	d1,d7
;				moveq	#0,d6
;				move.b	6(a0),d6
;				add.w	d6,d6
;				mulu	d6,d7
;				move.b	-2(a0),d6
;				divu	d6,d7
;				swap	d7
;				clr.w	d7
;				swap	d7
;
;				lea		(a3,d7.l*8),a2			; pointer to
;; horiz const
;				move.w	d1,d7
;				move.b	7(a0),d6
;				add.w	d6,d6
;				mulu	d6,d7
;				move.b	-1(a0),d6
;				divu	d6,d7
;				swap	d7
;				clr.w	d7
;				swap	d7
;				lea		(a3,d7.l*8),a3			; pointer to
;; vertical c.
;
;* CLIP OBJECT TO TOP AND BOTTOM
;* OF THE VISIBLE DISPLAY
;
;				moveq	#0,d7
;				cmp.w	draw_ObjClipT_w,d2
;				bge.s	.object_fits_on_top
;
;				sub.w	draw_ObjClipT_w,d2
;				add.w	d2,d4					;new height in
;;pixels
;				ble		object_behind				; nothing to draw
;
;				move.w	d2,d7
;				neg.w	d7						; factor to mult.
;; constants by
;; at top of obj.
;				move.w	draw_ObjClipT_w,d2
;
;.object_fits_on_top:
;
;				move.w	draw_ObjClipB_w,d6
;				sub.w	d2,d6
;				cmp.w	d6,d4
;				ble.s	.object_fits_on_bottom
;
;				move.w	d6,d4
;
;.object_fits_on_bottom:
;
;				subq	#1,d4
;				blt		object_behind
;
;				move.l	#ontoscr,a6
;				move.l	(a6,d2.w*4),d2
;
;				add.l	Vid_FastBufferPtr_l,d2
;				move.l	d2,toppt
;
;				move.l	#WorkSpace,a5
;				move.l	#glassball,a4
;				cmp.w	draw_LeftClipB_w,d0
;				bge.s	.ok_on_left
;
;				sub.w	draw_LeftClipB_w,d0
;				add.w	d0,d3
;				ble		object_behind
;
;				move.w	(a2),d1
;				move.w	2(a2),d2
;				neg.w	d0
;				muls	d0,d1
;				mulu	d0,d2
;				swap	d2
;				add.w	d2,d1
;				asl.w	#7,d1
;				lea		(a5,d1.w),a5
;				lea		(a4,d1.w),a4
;
;				move.w	draw_LeftClipB_w,d0
;
;.ok_on_left:
;
;				move.w	d0,d6
;				add.w	d3,d6
;				sub.w	draw_RightClipB_w,d6
;				blt.s	.ok_right_side
;
;				sub.w	#1,d3
;				sub.w	d6,d3
;
;.ok_right_side:
;				move.w	d0,a1
;				add.w	a1,a1
;
;				move.w	(a3),d5
;				move.w	2(a3),d6
;				muls	d7,d5
;				mulu	d7,d6
;				swap	d6
;				add.w	d6,d5
;; add.w 2(a0),d5	;d5 contains
;;top offset into
;;each strip.
;				add.l	#$80000000,d5
;
;				move.l	(a2),d6
;				moveq.l	#0,d7
;				move.l	a5,midobj
;				move.l	a4,midglass
;				move.l	(a3),d2
;				swap	d2
;				move.l	#times128,a0
;
;				movem.l	d0-d7/a0-a6,-(a7)
;
;				move.w	d3,d1
;				ext.l	d1
;				swap	d1
;				move.w	d4,d2
;				ext.l	d2
;				swap	d2
;				asr.l	#6,d1
;				asr.l	#6,d2
;				move.w	d1,d5
;				move.w	d2,d6
;				swap	d1
;				swap	d2
;
;				muls	#SCREENWIDTH,d2
;
;				move.l	#WorkSpace,a0
;
;				move.w	#63,d0
;.readinto:
;				swap	d0
;				move.w	#63,d0
;				move.l	toppt(pc),a6
;				adda.w	a1,a6
;				add.w	d1,a1
;				add.w	d5,d7
;				bcc.s	.noadmoreh
;				addq	#1,a1
;.noadmoreh:
;				swap	d7
;				move.w	#0,d7
;.readintodown:
;				move.w	(a6),d3
;				move.w	d3,(a0)+
;				add.w	d2,a6
;				add.w	d6,d7
;				bcc.s	.noadmore
;				adda.w	#SCREENWIDTH,a6
;.noadmore:
;				dbra	d0,.readintodown
;				swap	d0
;				swap	d7
;				dbra	d0,.readinto
;
;
;; Want to zoom an area d3*d4
;; in size up to 64*64 in size.
;; move.l #WorkSpace,a0
;; move.l frompt,a2
;; move.w #104*4,d3
;; move.w #1,d6
;;.ribl
;; move.w #31,d0
;;.readinto
;; move.w #15,d1
;; move.l a2,a1
;;.readintodown
;; move.w (a1),(a0)+
;; adda.w d3,a1
;; move.w (a1),(a0)+
;; adda.w d3,a1
;; move.w (a1),(a0)+
;; adda.w d3,a1
;; move.w (a1),(a0)+
;; adda.w d3,a1
;; dbra d1,.readintodown
;;; add.w #256-128,a0
;; addq #4,a2
;; dbra d0,.readinto
;; addq #4,a2
;; dbra d6,.ribl
;
;				movem.l	(a7)+,d0-d7/a0-a6
;
;				move.l	#darkentab,a2
;				move.l	toppt,d1
;				add.l	a1,d1
;				move.l	d1,toppt
;				move.l	d6,a1
;				moveq	#0,d6
;
;.draw_right_side:
;				swap	d7
;				move.l	midglass(pc),a4
;				adda.w	(a0,d7.w*2),a4
;				swap	d7
;				add.l	a1,d7
;				move.l	toppt(pc),a6
;				addq.l	#1,toppt
;
;				move.l	d5,d1
;				move.w	d4,-(a7)
;				swap	d3
;.draw_vertical_strip
;				move.w	(a4,d1.w*2),d3
;				blt.s	.itsbackground
;				move.b	(a5,d3.w*2),d6
;				move.b	(a2,d6.w),(a6)
;.itsbackground
;				adda.w	#SCREENWIDTH,a6
;				addx.l	d2,d1
;				dbra	d4,.draw_vertical_strip
;				swap	d3
;				move.w	(a7)+,d4
;
;				dbra	d3,.draw_right_side
;				movem.l	(a7)+,d0-d7/a0-a6
;
;				rts
;
;				ENDC

********************************************************************************

;draw_RealWidth_w:		dc.w	0 ; write once ?
;draw_RealHeight_w:		dc.w	0 ; write once ?

;midglass:
;dc.l	0

;times128:
;val				SET		0
;				REPT	100
;				dc.w	val*128
;val				SET		val+1
;				ENDR

draw_bitmap_glare:
				move.w	(a0)+,d0				; Point number
				move.w	2(a1,d0.w*8),d1			; depth
				cmp.w	#DRAW_BITMAP_NEAR_PLANE,d1
				ble		object_behind

				; 0xABADCAFE: Billboard distance hack. The depth here is still scaled by the old factor,
				; in fullscreen so we compensate by scaling again by 3/3.3333 = 0.9.
				; TODO - there has to be a better way of doing this, it's terrible.
				tst.b	Vid_FullScreen_b
				beq.s	.no_depth_adjust

				muls	#927,d1 ; 927 / 1024 ~= 0.9
				asr.l	#8,d1
				asr.l	#2,d1

.no_depth_adjust:
				move.w	draw_TopClip_w,d2
				move.w	draw_BottomClip_w,d3
				move.l	draw_TopY_3D_l,d6
				sub.l	yoff,d6
				divs	d1,d6
				add.w	Vid_CentreY_w,d6
				cmp.w	d3,d6
				bge		object_behind

				cmp.w	d2,d6
				bge.s	.okobtc

				move.w	d2,d6

.okobtc:
				move.w	d6,draw_ObjClipT_w
				move.l	draw_BottomY_3D_l,d6
				sub.l	yoff,d6
				divs	d1,d6
				add.w	Vid_CentreY_w,d6
				cmp.w	d2,d6
				ble		object_behind

				cmp.w	d3,d6
				ble.s	.okobbc

				move.w	d3,d6

.okobbc:
				move.w	d6,draw_ObjClipB_w
				move.l	4(a1,d0.w*8),d0
				move.w	draw_AuxX_w,d2
				ext.l	d2
				asl.l	#7,d2
				add.l	d2,d0
				addq	#2,a0
				move.l	TexturePal,a4
				sub.l	#512,a4
				move.w	(a0)+,d2				; height
				add.w	draw_AuxY_w,d2
				ext.l	d2
				asl.l	#7,d2
				sub.l	yoff,d2
				divs	d1,d2
				add.w	Vid_CentreY_w,d2
				divs	d1,d0
				add.w	Vid_CentreX_w,d0				;x pos of middle

; Need to calculate:
; Width of object in pixels
; height of object in pixels
; horizontal constants
; vertical constants.
				move.l	GLF_DatabasePtr_l,a6
				lea		GLFT_FrameData_l(a6),a6
				move.l	#Objects,a5
				move.w	2(a0),d7
				neg.w	d7
				asl.w	#4,d7
				adda.w	d7,a5
				asl.w	#4,d7
				adda.w	d7,a6
				move.w	4(a0),d7
				lea		(a6,d7.w*8),a6
				move.l	#consttab,a3
				moveq	#0,d3
				moveq	#0,d4
				move.b	(a0)+,d3
				move.b	(a0)+,d4
				lsl.l	#7,d3
				lsl.l	#7,d4
				divs	d1,d3					;width in pixels
				divs	d1,d4					;height in pixels
				sub.w	d4,d2
				sub.w	d3,d0
				cmp.w	draw_RightClipB_w,d0
				bge		object_behind
				add.w	d3,d3
				cmp.w	draw_ObjClipB_w,d2
				bge		object_behind

				add.w	d4,d4

; * OBTAIN POINTERS TO HORIZ AND VERT
; * CONSTANTS FOR MOVING ACROSS AND
; * DOWN THE OBJECT GRAPHIC.

				move.l	(a5)+,WAD_PTR
				move.l	(a5)+,PTR_PTR
				move.l	(a6),d7
				move.w	d7,DOWN_STRIP
				move.l	PTR_PTR,a5
				swap	d7
				asl.w	#2,d7
				adda.w	d7,a5
				move.w	d1,d7
				moveq	#0,d6
				move.w	4(a6),d6
				add.w	d6,d6
				subq	#1,d6
				mulu	d6,d7
				moveq	#0,d6
				move.b	-2(a0),d6
				beq		object_behind

				divu	d6,d7
				swap	d7
				clr.w	d7
				swap	d7
				lea		(a3,d7.l*8),a2			; pointer to horiz const
				move.w	d1,d7
				move.w	6(a6),d6
				add.w	d6,d6
				subq	#1,d6
				mulu	d6,d7
				moveq	#0,d6
				move.b	-1(a0),d6
				beq		object_behind
				divu	d6,d7
				swap	d7
				clr.w	d7
				swap	d7
				lea		(a3,d7.l*8),a3			; pointer to vertical c.
												; * CLIP OBJECT TO TOP AND BOTTOM
												; * OF THE VISIBLE DISPLAY

				moveq	#0,d7
				cmp.w	draw_ObjClipT_w,d2
				bge.s	.object_fits_on_top

				sub.w	draw_ObjClipT_w,d2
				add.w	d2,d4					; new height in pixels
				ble		object_behind			; nothing to draw

				move.w	d2,d7
				neg.w	d7						; factor to mult.
												; constants by
												; at top of obj.
				move.w	draw_ObjClipT_w,d2

.object_fits_on_top:
				move.w	draw_ObjClipB_w,d6
				sub.w	d2,d6
				cmp.w	d6,d4
				ble.s	.object_fits_on_bottom

				move.w	d6,d4

.object_fits_on_bottom:
				subq	#1,d4
				blt		object_behind

				move.l	#ontoscr,a6
				move.l	(a6,d2.w*4),d2
				add.l	Vid_FastBufferPtr_l,d2
				move.l	d2,toppt
				cmp.w	draw_LeftClipB_w,d0
				bge.s	.ok_on_left

				sub.w	draw_LeftClipB_w,d0
				add.w	d0,d3
				ble		object_behind

				move.w	(a2),d1
				move.w	2(a2),d2
				neg.w	d0
				muls	d0,d1
				mulu	d0,d2
				swap	d2
				add.w	d2,d1
				lea		(a5,d1.w*4),a5

				move.w	draw_LeftClipB_w,d0

.ok_on_left:
				move.w	d0,d6
				add.w	d3,d6
				sub.w	draw_RightClipB_w,d6
				blt.s	.ok_right_side

				sub.w	#1,d3
				sub.w	d6,d3

.ok_right_side:
				ext.l	d0
				add.l	d0,toppt
				move.w	(a3),d5
				move.w	2(a3),d6
				muls	d7,d5
				mulu	d7,d6
				swap	d6
				add.w	d6,d5
				add.w	DOWN_STRIP(PC),d5		;d5 contains
												;top offset into
												;each strip.
				add.l	#$80000000,d5
				move.l	(a2),a2
				moveq.l	#0,d7
				move.l	a5,midobj
				move.l	(a3),d2
				swap	d2
				move.l	#0,a1

draw_right_side_glare:
				swap	d7
				move.l	midobj(pc),a5
				lea		(a5,d7.w*4),a5
				swap	d7
				add.l	a2,d7					; step fractional column
				move.l	WAD_PTR(PC),a0
				move.l	toppt(pc),a6
				adda.w	a1,a6
				addq	#1,a1
				move.l	(a5),d1
				beq		.blank_strip

				and.l	#$ffffff,d1
				add.l	d1,a0
				move.b	(a5),d1
				cmp.b	#1,d1
				bgt.s	.third_third

				beq.s	.second_third

				move.l	d5,d6
				move.l	d5,d1
				move.w	d4,-(a7)

.draw_vertical_strip_1:
				move.b	1(a0,d1.w*2),d0
				and.b	#%00011111,d0
				beq.s	.skip_black_1

				lsl.w	#8,d0
				add.w	d0,d0
				move.b	(a6),d0
				move.b	(a4,d0.w),(a6)

.skip_black_1:
				adda.w	#SCREENWIDTH,a6
				add.l	d2,d6
				addx.w	d2,d1
				dbra	d4,.draw_vertical_strip_1
				move.w	(a7)+,d4

.blank_strip:
				dbra	d3,draw_right_side_glare
				bra		object_behind

.second_third:
				move.l	d5,d1
				move.l	d5,d6
				move.w	d4,-(a7)

.draw_vertical_strip_2:
				move.w	(a0,d1.w*2),d0
				lsr.w	#5,d0
				and.w	#%11111,d0
				beq.s	.skip_black_2

				lsl.w	#8,d0
				add.w	d0,d0
				move.b	(a6),d0
				move.b	(a4,d0.w),(a6)

.skip_black_2:
				adda.w	#SCREENWIDTH,a6
				add.l	d2,d6
				addx.w	d2,d1
				dbra	d4,.draw_vertical_strip_2
				move.w	(a7)+,d4
				dbra	d3,draw_right_side_glare
				bra		object_behind

.third_third:
				move.l	d5,d1
				move.l	d5,d6
				move.w	d4,-(a7)

.draw_vertical_strip_3:
				move.b	(a0,d1.w*2),d0
				lsr.b	#2,d0
				and.b	#%11111,d0
				beq.s	.skip_black_3
				lsl.w	#8,d0
				add.w	d0,d0
				move.b	(a6),d0
				move.b	(a4,d0.w),(a6)

.skip_black_3:
				adda.w	#SCREENWIDTH,a6
				add.l	d2,d6
				addx.w	d2,d1
				dbra	d4,.draw_vertical_strip_3
				move.w	(a7)+,d4
				dbra	d3,draw_right_side_glare

				movem.l	(a7)+,d0-d7/a0-a6
				rts

draw_Bitmap:
				move.l	#0,draw_AuxX_w
				cmp.b	#3,16(a0)
				bne.s	.not_auxilliary_object

				move.w	ShotT_AuxOffsetX_w(a0),draw_AuxX_w
				move.w	ShotT_AuxOffsetY_w(a0),draw_AuxY_w

.not_auxilliary_object:
				tst.l   8(a0)
				blt		draw_bitmap_glare

				move.w	(a0)+,d0				;pt num
				move.l	Lvl_ObjectPointsPtr_l,a4
				move.w	(a4,d0.w*8),draw_Obj_XPos_w
				move.w	4(a4,d0.w*8),draw_Obj_ZPos_w
				move.w	2(a1,d0.w*8),d1
				cmp.w	#DRAW_BITMAP_NEAR_PLANE,d1
				ble		object_behind

				; 0xABADCAFE: Billboard distance hack. The depth here is still scaled by the old factor
				; in fullscreen so we compensate by scaling again by 3/3.3333 = 0.9.
				; TODO - there has to be a better way of doing this, it's terrible.
				tst.b	Vid_FullScreen_b
				beq.s	.no_depth_adjust

				muls	#927,d1 ; // 927/1024 ~= 0.9
				asr.l	#8,d1
				asr.l	#2,d1

.no_depth_adjust:
				move.w	draw_TopClip_w,d2
				move.w	draw_BottomClip_w,d3
				move.l	draw_TopY_3D_l,d6
				sub.l	yoff,d6
				divs	d1,d6
				add.w	Vid_CentreY_w,d6
				cmp.w	d3,d6
				bge		object_behind

				cmp.w	d2,d6
				bge.s	.okobtc
				move.w	d2,d6

.okobtc:
				move.w	d6,draw_ObjClipT_w				; top object clip
				move.l	draw_BottomY_3D_l,d6
				sub.l	yoff,d6
				divs	d1,d6
				add.w	Vid_CentreY_w,d6
				cmp.w	d2,d6					; bottom of object over top of screen?
				ble		object_behind

				cmp.w	d3,d6
				ble.s	.okobbc
				move.w	d3,d6					; clip bottom of object to lower clip

.okobbc:
				move.w	d6,draw_ObjClipB_w				; bottom object clip
				move.l	4(a1,d0.w*8),d0
				move.w	draw_AuxX_w,d2
				ext.l	d2
				asl.l	#7,d2
				add.l	d2,d0
				move.w	d1,d6
				asr.w	#6,d6
				add.w	(a0)+,d6
				move.w	d6,draw_BrightToAdd_w
				bge.s	.brighttoonot

				moveq	#0,d6

.brighttoonot:
				sub.l	a4,a4
				move.w	draw_ObjScaleCols_vw(pc,d6.w*2),a4 ; is this the table that scales vertically?
				bra		pastobjscale

				CNOP 0,4
draw_ObjScaleCols_vw:
				dcb.w	1,64*0
				dcb.w	2,64*1
				dcb.w	2,64*2
				dcb.w	2,64*3
				dcb.w	2,64*4
				dcb.w	2,64*5
				dcb.w	2,64*6
				dcb.w	2,64*7
				dcb.w	2,64*8
				dcb.w	2,64*9
				dcb.w	2,64*10
				dcb.w	2,64*11
				dcb.w	2,64*12
				dcb.w	2,64*13
				dcb.w	2,64*14
				dcb.w	2,64*15
				dcb.w	2,64*16
				dcb.w	2,64*17
				dcb.w	2,64*18
				dcb.w	2,64*19
				dcb.w	2,64*20
				dcb.w	2,64*21
				dcb.w	2,64*22
				dcb.w	2,64*23
				dcb.w	2,64*24
				dcb.w	2,64*25
				dcb.w	2,64*26
				dcb.w	2,64*27
				dcb.w	2,64*28
				dcb.w	2,64*29
				dcb.w	2,64*30
				dcb.w	20,64*31

draw_BasePalPtr_l:		dc.l	0
draw_WhichLightPal_b:	dc.b	0 ; BOOL
draw_FlipIt_b:			dc.b	0 ; BOOL flip on/off
draw_LightIt_b:			dc.b	0 ; BOOL Lighting for object on/off
draw_Additive_b:		dc.b	0 ; BOOL Additive translucency for object on/off

pastobjscale:
				move.w	(a0)+,d2				; height
				add.w	draw_AuxY_w,d2
				ext.l	d2
				asl.l	#7,d2
				sub.l	yoff,d2
				divs	d1,d2
				add.w	Vid_CentreY_w,d2
				divs	d1,d0
				add.w	Vid_CentreX_w,d0				;x pos of middle

; Need to calculate:
; Width of object in pixels
; height of object in pixels
; horizontal constants
; vertical constants.

				move.l	GLF_DatabasePtr_l,a6
				lea		GLFT_FrameData_l(a6),a6
				move.l	#Objects,a5
				move.w	2(a0),d7
				asl.w	#4,d7
				adda.w	d7,a5					; a5 pointing to?
				asl.w	#4,d7
				adda.w	d7,a6					; a6 pointing to?
				clr.b	draw_LightIt_b
				clr.b	draw_Additive_b
				move.b	4(a0),d7
				btst	#7,d7
				sne		draw_FlipIt_b
				and.b	#127,d7
				sub.b	#2,d7
				blt.s	.not_a_light

				cmp.b	#4,d7
				blt.s	.is_a_light

				st		draw_Additive_b
				bra.s	.not_a_light

.is_a_light:
				st		draw_LightIt_b
				move.b	d7,draw_WhichLightPal_b

.not_a_light:
				moveq	#0,d7
				move.b	5(a0),d7				; current frame of animation
				lea		(a6,d7.w*8),a6			; a6 pointing to frame?
				move.l	#consttab,a3
				moveq	#0,d3
				moveq	#0,d4
				move.b	(a0)+,d3
				move.b	(a0)+,d4
				lsl.l	#7,d3
				lsl.l	#7,d4
				divs	d1,d3					;width in pixels
				divs	d1,d4					;height in pixels
				sub.w	d4,d2
				sub.w	d3,d0
				cmp.w	draw_RightClipB_w,d0
				bge		object_behind

				add.w	d3,d3
				cmp.w	draw_ObjClipB_w,d2
				bge		object_behind

				add.w	d4,d4

; * OBTAIN POINTERS TO HORIZ AND VERT
; * CONSTANTS FOR MOVING ACROSS AND
; * DOWN THE OBJECT GRAPHIC.

				move.l	(a5)+,WAD_PTR
				move.l	(a5)+,PTR_PTR
				add.l	4(a5),a4				; a5: #Objects
				move.l	4(a5),draw_BasePalPtr_l
				move.l	(a6),d7					; pointer to current frame
				move.w	d7,DOWN_STRIP			; leftmost strip?
				move.l	PTR_PTR,a5
				tst.b	draw_FlipIt_b
				beq.s	.no_flip

				move.w	4(a6),d6				; mhhm, somehow this flips the frame?
				add.w	d6,d6					; go to next frame and subtract
				subq	#1,d6
				lea		(a5,d6.w*4),a5

.no_flip:
				swap	d7
				asl.w	#2,d7
				adda.w	d7,a5
				move.w	d1,d7
				moveq	#0,d6
				move.w	4(a6),d6
				add.w	d6,d6
				subq	#1,d6
				mulu	d6,d7
				moveq	#0,d6
				move.b	-2(a0),d6
				beq		object_behind

				divu	d6,d7
				swap	d7
				clr.w	d7
				swap	d7
				lea		(a3,d7.l*8),a2			; pointer to horiz const
				move.w	d1,d7
				move.w	6(a6),d6
				add.w	d6,d6
				subq	#1,d6
				mulu	d6,d7
				moveq	#0,d6
				move.b	-1(a0),d6
				beq		object_behind

				divu	d6,d7
				swap	d7
				clr.w	d7
				swap	d7
				lea		(a3,d7.l*8),a3			; pointer to vertical scale table?
; vertical c.

;* CLIP OBJECT TO TOP AND BOTTOM
;* OF THE VISIBLE DISPLAY

				moveq	#0,d7
				cmp.w	draw_ObjClipT_w,d2
				bge.s	.object_fits_on_top

				sub.w	draw_ObjClipT_w,d2
				add.w	d2,d4					; new height in pixels
				ble		object_behind			; nothing to draw

				move.w	d2,d7
				neg.w	d7						; factor to mult.
												; constants by
												; at top of obj.
				move.w	draw_ObjClipT_w,d2

.object_fits_on_top:
				move.w	draw_ObjClipB_w,d6
				sub.w	d2,d6
				cmp.w	d6,d4
				ble.s	.object_fits_on_bottom

				move.w	d6,d4

.object_fits_on_bottom:
				subq	#1,d4
				blt		object_behind

				move.l	#ontoscr,a6
				move.l	(a6,d2.w*4),d2
				add.l	Vid_FastBufferPtr_l,d2
				move.l	d2,toppt
				cmp.w	draw_LeftClipB_w,d0
				bge.s	.ok_on_left

				sub.w	draw_LeftClipB_w,d0
				add.w	d0,d3
				ble		object_behind

				move.w	(a2),d1
				move.w	2(a2),d2
				neg.w	d0
				muls	d0,d1
				mulu	d0,d2
				swap	d2
				add.w	d2,d1
				move.w	draw_LeftClipB_w,d0
				asl.w	#2,d1
				tst.b	draw_FlipIt_b
				beq.s	.no_flip_2

				suba.w	d1,a5
				suba.w	d1,a5

.no_flip_2:
				adda.w	d1,a5

.ok_on_left:
				move.w	d0,d6
				add.w	d3,d6
				sub.w	draw_RightClipB_w,d6
				blt.s	.ok_right_side

				sub.w	#1,d3
				sub.w	d6,d3

.ok_right_side:
				ext.l	d0
				add.l	d0,toppt
				move.w	(a3),d5
				move.w	2(a3),d6
				muls	d7,d5
				mulu	d7,d6
				swap	d6
				add.w	d6,d5
				add.w	DOWN_STRIP(PC),d5		;d5 contains
												;top offset into
												;strip?
				add.l	#$80000000,d5

				move.l	(a2),d7					; what is a2 pointing to?
				tst.b	draw_FlipIt_b
				beq.s	.no_flip_3
				neg.l	d7

.no_flip_3:
				move.l	d7,a2					; store fractional column offset
				moveq.l	#0,d7
				move.l	a5,midobj
				move.l	(a3),d2
				swap	d2
				move.l	#0,a1
				tst.b	draw_LightIt_b
				bne		draw_bitmap_lighted

				tst.b	draw_Additive_b
				bne		draw_bitmap_additive

draw_right_side:
				swap	d7
				move.l	midobj(pc),a5
				lea		(a5,d7.w*4),a5
				swap	d7
				add.l	a2,d7					; fractional column advance?
				move.l	WAD_PTR(PC),a0
				move.l	toppt(pc),a6
				adda.w	a1,a6
				addq	#1,a1
				move.l	(a5),d1
				beq		.blank_strip

				and.l	#$ffffff,d1
				add.l	d1,a0

				move.b	(a5),d1
				; I think the vertical strips are stored as 5 bit (32cols)
				; To not waste memory, 3 strips are stored in 16bit words
				; Here we decide which strip to extract
				cmp.b	#1,d1
				bgt.s	.third_third
				beq.s	.second_third
				move.l	d5,d6
				move.l	d5,d1
				move.w	d4,-(a7)

				; Inner loops of 2D object drawing
.draw_vertical_strip_1:
				move.b	1(a0,d1.w*2),d0
				and.b	#%00011111,d0
				beq.s	.skip_black_1
				move.b	(a4,d0.w*2),(a6)

.skip_black_1:
				adda.w	#SCREENWIDTH,a6
				add.l	d2,d6					; is d2 the vertical step, fraction|integer?
				addx.w	d2,d1
				dbra	d4,.draw_vertical_strip_1
				move.w	(a7)+,d4

.blank_strip:
				dbra	d3,draw_right_side
				bra.s	object_behind

.second_third:
				move.l	d5,d1
				move.l	d5,d6
				move.w	d4,-(a7)

.draw_vertical_strip_2:
				move.w	(a0,d1.w*2),d0
				lsr.w	#5,d0
				and.w	#%11111,d0
				beq.s	.skip_black_2
				move.b	(a4,d0.w*2),(a6)

.skip_black_2:
				adda.w	#SCREENWIDTH,a6			; next line on screen
				add.l	d2,d6
				addx.w	d2,d1					; is d2 the vertical step, fraction|integer?
				dbra	d4,.draw_vertical_strip_2
				move.w	(a7)+,d4
				dbra	d3,draw_right_side
				bra.s	object_behind

.third_third:
				move.l	d5,d1
				move.l	d5,d6
				move.w	d4,-(a7)

.draw_vertical_strip_3:
				move.b	(a0,d1.w*2),d0
				lsr.b	#2,d0
				and.b	#%11111,d0
				beq.s	.skip_black
				move.b	(a4,d0.w*2),(a6)

.skip_black:
				adda.w	#SCREENWIDTH,a6
				add.l	d2,d6
				addx.w	d2,d1					; is d2 the vertical dy/dt step, fraction|integer?
				dbra	d4,.draw_vertical_strip_3
				move.w	(a7)+,d4
				dbra	d3,draw_right_side

object_behind:
				movem.l	(a7)+,d0-d7/a0-a6
				rts

draw_bitmap_additive:
				move.l	draw_BasePalPtr_l,a4

draw_right_side_additive:
				swap	d7
				move.l	midobj(pc),a5
				lea		(a5,d7.w*4),a5
				swap	d7
				add.l	a2,d7
				move.l	WAD_PTR(PC),a0

				move.l	toppt(pc),a6
				adda.w	a1,a6
				addq	#1,a1
				move.l	(a5),d1
				beq		.blank_strip_additive

				and.l	#$ffffff,d1
				add.l	d1,a0

				move.b	(a5),d1
				cmp.b	#1,d1
				bgt.s	.third_third_additive
				beq.s	.second_third_additive
				move.l	d5,d6
				move.l	d5,d1
				move.w	d4,-(a7)

.draw_vertical_strip_1:
				move.b	1(a0,d1.w*2),d0
				and.b	#%00011111,d0
				lsl.w	#8,d0
				move.b	(a6),d0
				move.b	(a4,d0.w),(a6)
				adda.w	#SCREENWIDTH,a6
				add.l	d2,d6
				addx.w	d2,d1
				dbra	d4,.draw_vertical_strip_1
				move.w	(a7)+,d4

.blank_strip_additive:
				dbra	d3,draw_right_side_additive
				bra		object_behind

.second_third_additive:
				move.l	d5,d1
				move.l	d5,d6
				move.w	d4,-(a7)

.draw_vertical_strip_2:
				move.w	(a0,d1.w*2),d0
				lsr.w	#5,d0
				and.w	#%11111,d0
				lsl.w	#8,d0
				move.b	(a6),d0
				move.b	(a4,d0.w),(a6)
				adda.w	#SCREENWIDTH,a6
				add.l	d2,d6
				addx.w	d2,d1
				dbra	d4,.draw_vertical_strip_2
				move.w	(a7)+,d4
				dbra	d3,draw_right_side_additive
				bra		object_behind

.third_third_additive:
				move.l	d5,d1
				move.l	d5,d6
				move.w	d4,-(a7)

.draw_vertical_strip_3:
				move.b	(a0,d1.w*2),d0
				lsr.b	#2,d0
				and.b	#%11111,d0
				lsl.w	#8,d0
				move.b	(a6),d0
				move.b	(a4,d0.w),(a6)

.skip_black:
				adda.w	#SCREENWIDTH,a6
				add.l	d2,d6
				addx.w	d2,d1
				dbra	d4,.draw_vertical_strip_3
				move.w	(a7)+,d4
				dbra	d3,draw_right_side_additive

				bra		object_behind

draw_bitmap_lighted:

; Make up lighting values

				movem.l	d0-d7/a0-a6,-(a7)

				move.l	#draw_AngleBrights_vl,a2
				move.l	#$80808080,(a2)
				move.l	#$80808080,4(a2)
				move.l	#$80808080,8(a2)
				move.l	#$80808080,12(a2)
				move.l	#$80808080,16(a2)
				move.l	#$80808080,20(a2)
				move.l	#$80808080,24(a2)
				move.l	#$80808080,28(a2)
				move.l	#$80808080,32(a2)
				move.l	#$80808080,36(a2)
				move.l	#$80808080,40(a2)
				move.l	#$80808080,44(a2)
				move.l	#$80808080,48(a2)
				move.l	#$80808080,52(a2)
				move.l	#$80808080,56(a2)
				move.l	#$80808080,60(a2)

				move.w	Draw_CurrentZone_w(pc),d0
				bsr		draw_CalcBrightsInZone

				move.l	#draw_AngleBrights_vl+32,a2

; Now do the brightnesses of surrounding
; zones:

; move.l Lvl_FloorLinesPtr_l,a1
; move.w Draw_CurrentZone_w,d0
; move.l Lvl_ZoneAddsPtr_l,a4
; move.l (a4,d0.w*4),a4
; add.l Lvl_DataPtr_l,a4
; move.l a4,a5
;
; adda.w ZoneT_ExitList_w(a4),a5
;
;.do_all_walls
; move.w (a5)+,d0
; blt .no_more_walls
;
; asl.w #4,d0
; lea (a1,d0.w),a3
;
; move.w 8(a3),d0
; blt.s .solid_wall ; a wall not an exit.
;
; movem.l a1/a4/a5,-(a7)
; bsr draw_CalcBrightsInZone
; movem.l (a7)+,a1/a4/a5
; bra .do_all_walls
;
;.solid_wall:
; move.w 4(a3),d1
; move.w 6(a3),d2
;
; move.w oldx,newx
; move.w oldz,newz
; sub.w d2,newx
; add.w d1,newz
;
; movem.l d0-d7/a0-a6,-(a7)
; jsr HeadTowardsAng
; movem.l (a7)+,d0-d7/a0-a6
; move.w AngRet,d1
; neg.w d1
; and.w #8191,d1
; asr.w #8,d1
; asr.w #1,d1

; move.b #48,(a2,d1.w)
; move.b #48,16(a2,d1.w)
; bra .do_all_walls
;
;.no_more_walls:

				move.l	#draw_XZAngs_vw,a0
				move.l	#draw_AngleBrights_vl,a1
				move.w	#15,d7
				sub.l	a2,a2
				sub.l	a3,a3
				sub.l	a4,a4
				sub.l	a5,a5
				moveq	#00,d0
				moveq	#00,d1

average_angle:
				moveq	#0,d4
				move.b	16(a1),d4
				cmp.b	#$80,d4
				beq.s	.nobright

				neg.w	d4
				add.w	#48,d4
				cmp.b	d1,d4
				ble.s	.no_brightest

				move.b	d4,d1

.no_brightest:
				move.w	(a0),d5
				move.w	2(a0),d6
				muls	d4,d5
				muls	d4,d6
				add.l	d5,a2
				add.l	d6,a3

.nobright:

BOTTYL:
				moveq	#0,d4
				move.b	(a1),d4
				cmp.b	#$80,d4
				beq.s	.nobright

				neg.w	d4
				add.w	#48,d4
				cmp.b	d0,d4
				blt.s	.no_brightest

				move.b	d4,d0

.no_brightest:
				move.w	(a0),d5
				move.w	2(a0),d6
				muls	d4,d5
				muls	d4,d6
				add.l	d5,a4
				add.l	d6,a5

.nobright:
				addq	#4,a0
				addq	#1,a1
				dbra	d7,average_angle

				move.l	a2,d2
				move.l	a3,d3
				move.l	a4,d4
				move.l	a5,d5
				add.l	d2,d4
				add.l	d3,d5					; bright dir.

				bsr		draw_FindRoughAngle

foundang:
				move.w	#7,d2
				move.w	d1,d3
				cmp.w	d0,d1
				beq.s	INMIDDLE


				bgt.s	.okpicked

				move.w	d0,d3
.okpicked

				move.w	d0,d2
				add.w	d1,d2					; total brightness

				muls	#16,d1
				subq	#1,d1
				divs	d2,d1
				move.w	d1,d2

INMIDDLE:
; d2=y distance from middle of brightest pt.
; d3=brightness
				neg.w	d3
				add.w	#48,d3
				move.l	#willy,a0
				move.l	#guff,a1
				add.l	draw_TempPtr_l,a1

; add.l #16*7,draw_TempPtr_l
; cmp.l #16*7*15,draw_TempPtr_l
; ble.s .noreguff
; move.l #0,draw_TempPtr_l
;.noreguff:

				muls	#7*16,d2
				add.l	d2,a1
				move.w	Plr1_TmpAngPos_w,d0
				neg.w	d0
				add.w	#4096,d0
				and.w	#8191,d0
				asr.w	#8,d0
				asr.w	#1,d0
				sub.b	#3,d0
				add.b	d4,d0
				and.w	#15,d0
				move.w	#6,d1

.across_loop:
				move.w	#6,d2
				move.w	d0,d5

.down_loop:
				move.b	(a1,d5),d4
				add.b	d3,d4
				ext.w	d4
				move.w	d4,(a0)+
				addq	#1,d5
				and.w	#15,d5
				dbra	d2,.down_loop

				add.w	#16,a1
				dbra	d1,.across_loop

; jsr draw_CalcBrightRings

; Need to scan around zone points putting in
; brightnesses.


; move.w Plr1_XOff_l,newx
; move.w Plr1_ZOff_l,newz
; move.w draw_Obj_XPos_w,oldx
; move.w draw_Obj_ZPos_w,oldz
; movem.l d0-d7/a0-a6,-(a7)
; jsr HeadTowardsAng
; movem.l (a7)+,d0-d7/a0-a6


; move.w #0,d0
; move.w AngRet,d0
; move.w Plr1_TmpAngPos_w,d0
; neg.w d0
; add.w #4096,d0
; and.w #8191,d0
; asr.w #8,d0
; asr.w #1,d0
;
; sub.b #6,d0
; and.b #15,d0
; move.l #draw_AngleBrights_vl,a1
;
; move.l #willy,a0
; moveq #6,d1
;.across:
; moveq #0,d3
; moveq #0,d4
; move.b (a1,d0.w),d4
; bge.s .okp1
; moveq #0,d4
;.okp1
;
; move.b 16(a1,d0.w),d3
; bge.s .okp2
; moveq #0,d3
;.okp2
; sub.w d3,d4
; swap d3
; swap d4
; divs.l #7,d4
; moveq #6,d2
; moveq #0,d5
;.down:
; swap d3
; move.w d3,(a0,d5.w*2)
; swap d3
; addq #7,d5
; add.l d4,d3
; dbra d2,.down
; addq #2,d0
; and.w #15,d0
; addq #2,a0
; dbra d1,.across


				move.w	draw_BrightToAdd_w,d0
				move.l	#willy,a0
				move.l	#willybright,a1
				move.w	#48,d1

.add_it_in:
				move.w	d0,d2
				add.w	(a1)+,d2
				ble.s	.nopos

				moveq	#0,d2

.nopos:
				add.w	d2,(a0)+
				dbra	d1,.add_it_in

				tst.b	draw_FlipIt_b
				beq.s	.left_or_right

				move.l	#draw_Brights2_vw,a0
				bra		.done_right_to_left

.left_or_right:
				move.l	#draw_Brights_vw,a0

.done_right_to_left:
				move.l	#willy,a2
				move.l	draw_BasePalPtr_l,a1
				move.b	draw_WhichLightPal_b,d0
				asl.w	#8,d0
				add.w	d0,a1
				move.l	#draw_Pals_vl,a3
				move.w	#28,d0

.make_pals_loop:
				move.w	(a0)+,d1
				move.w	(a2,d1.w*2),d1
				bge.s	.okpos
				moveq	#0,d1

.okpos:
				cmp.w	#31,d1
				blt.s	.okneg
				move.w	#31,d1

.okneg:
				move.l	(a1,d1.w*8),(a3)+
				move.b	#0,-4(a3)
				move.l	4(a1,d1.w*8),(a3)+
				dbra	d0,.make_pals_loop

				movem.l	(a7)+,d0-d7/a0-a6
				move.l	#draw_Pals_vl,a4
				clr.w	d0

.draw_light_loop:
				swap	d7
				move.l	midobj(pc),a5
				lea		(a5,d7.w*4),a5
				swap	d7
				add.l	a2,d7
				move.l	WAD_PTR(PC),a0			; is this not always right? Seems to be connected to
												; dead body of the blue priests, first seen in level C
				move.l	toppt(pc),a6
				adda.w	a1,a6
				addq	#1,a1
				move.l	(a5),d1
				beq		.blank_strip

				add.l	d1,a0

				move.l	d5,d6
				move.l	d5,d1
				move.w	d4,-(a7)

.draw_vertical_strip:
				move.b	(a0,d1.w),d0				; a0 can be broken here
				beq.s	.skip_black
				move.b	(a4,d0.w),(a6)				; FIXME: causing enforcer hits in Level C, illegal reads

.skip_black:
				adda.w	#SCREENWIDTH,a6
				add.l	d2,d6
				addx.w	d2,d1
				dbra	d4,.draw_vertical_strip
				move.w	(a7)+,d4
.blank_strip:
				dbra	d3,.draw_light_loop
				bra		object_behind

*********************************************
draw_FindRoughAngle:
				neg.l	d5
				moveq	#0,d7
				tst.l	d4
				bge.s	.no8

				add.w	#8,d7
				neg.l	d4

.no8:
				tst.l	d5
				bge.s	.no4

				neg.l	d5
				add.w	#4,d7

.no4:
				cmp.l	d5,d4
				bge.s	.no2

				addq	#2,d7
				exg		d4,d5

.no2:
				asr.l	#1,d4
				cmp.l	d5,d4
				bge.s	.no1
				addq	#1,d7

.no1:
				move.w	draw_MapToAng_vw(pc,d7.w*2),d4	; retun angle
				rts

				CNOP 0,4
draw_MapToAng_vw:
				dc.w	3,2,0,1,4,5,7,6
				dc.w	12,13,15,14,11,10,8,9

draw_TempPtr_l:		dc.l	0

*********************************************
draw_CalcBrightRings:
				move.l	#draw_AngleBrights_vl,a2
				move.l	#$80808080,(a2)
				move.l	#$80808080,4(a2)
				move.l	#$80808080,8(a2)
				move.l	#$80808080,12(a2)
				move.l	#$80808080,16(a2)
				move.l	#$80808080,20(a2)
				move.l	#$80808080,24(a2)
				move.l	#$80808080,28(a2)

				move.l	#$80808080,32(a2)
				move.l	#$80808080,36(a2)
				move.l	#$80808080,40(a2)
				move.l	#$80808080,44(a2)
				move.l	#$80808080,48(a2)
				move.l	#$80808080,52(a2)
				move.l	#$80808080,56(a2)
				move.l	#$80808080,60(a2)

				move.w	Draw_CurrentZone_w(pc),d0
				bsr		draw_CalcBrightsInZone

				move.l	#draw_AngleBrights_vl+32,a2

; Now do the brightnesses of surrounding
; zones:

				move.l	Lvl_FloorLinesPtr_l,a1
				move.w	Draw_CurrentZone_w,d0
				move.l	Lvl_ZoneAddsPtr_l,a4
				move.l	(a4,d0.w*4),a4
				add.l	Lvl_DataPtr_l,a4
				move.l	a4,a5
				adda.w	ZoneT_ExitList_w(a4),a5

.do_all_walls:
				move.w	(a5)+,d0
				blt		.no_more_walls

				asl.w	#4,d0
				lea		(a1,d0.w),a3
				move.w	8(a3),d0
				blt.s	.solid_wall				; a wall not an exit.

				movem.l	a1/a4/a5,-(a7)
				bsr		draw_CalcBrightsInZone

				movem.l	(a7)+,a1/a4/a5
				bra		.do_all_walls

.solid_wall:
				move.w	4(a3),d1
				move.w	6(a3),d2
				move.w	oldx,newx
				move.w	oldz,newz
				sub.w	d2,newx
				add.w	d1,newz
				movem.l	d0-d7/a0-a6,-(a7)

				jsr		HeadTowardsAng

				movem.l	(a7)+,d0-d7/a0-a6
				move.w	AngRet,d1
				neg.w	d1
				and.w	#8191,d1
				asr.w	#8,d1
				asr.w	#1,d1
				move.b	#48,(a2,d1.w)
				move.b	#48,16(a2,d1.w)
				bra		.do_all_walls

.no_more_walls:

; move.b #0,(a2)
; move.b #20,8(a2)
; move.b #0,16(a2)
; move.b #20,24(a2)

				move.l	#draw_AngleBrights_vl,a0
				bsr		draw_TweenBrights

				move.l	#draw_AngleBrights_vl+16,a0
				bsr		draw_TweenBrights

				move.l	#draw_AngleBrights_vl+32,a0
				bsr		draw_TweenBrights

				move.l	#draw_AngleBrights_vl+48,a0
				bsr		draw_TweenBrights

				move.l	#draw_AngleBrights_vl,a0
				move.b	#15,d0

.sum_brights_loop:
				moveq	#0,d3
				moveq	#0,d4
				move.b	32(a0),d3
				move.b	48(a0),d4
				neg.w	d3
				add.w	#48,d3
				neg.w	d4
				add.w	#48,d4
				asr.w	#1,d4
				asr.w	#1,d3
				move.b	16(a0),d5
				sub.b	d5,d4
				ble.s	.ok2

				moveq	#0,d4
.ok2:
				move.b	(a0),d5
				sub.b	d5,d3
				ble.s	.ok1

				moveq	#0,d3
.ok1:
				neg.b	d3
				neg.b	d4
				move.b	d4,16(a0)
				move.b	d3,(a0)+
				dbra	d0,.sum_brights_loop

				rts

**********************************************

draw_TweenBrights:
				moveq	#0,d0

.backinto:
				cmp.b	#-128,(a0,d0.w)
				bne.s	.okbr
				addq	#1,d0
				bra.s	.backinto

.okbr:
				move.b	d0,d7					;starting pos
				move.b	d0,d1					;previous pos

; tween to next value
.findnext
				addq	#1,d0
				and.w	#15,d0
				cmp.b	#-128,(a0,d0.w)
				beq.s	.findnext

				moveq	#0,d2
				moveq	#0,d3
				move.b	(a0,d1.w),d2
				move.b	(a0,d0.w),d3
				sub.w	d2,d3
				move.w	d0,d4
				sub.w	d1,d4
				bgt.s	.okpos
				add.w	#16,d4

.okpos:
				swap	d2
				swap	d3
				ext.l	d4
				divs.l	d4,d3
				subq	#1,d4					; number of tweens

.put_in_tween_loop:
				swap	d2
				move.b	d2,(a0,d1.w)
				swap	d2
				add.l	d3,d2
				addq	#1,d1
				and.w	#15,d1
				dbra	d4,.put_in_tween_loop

				cmp.b	d0,d7
				beq.s	.done_all

				move.w	d0,d1
				bra		.findnext

.done_all:
				rts

*************************************

draw_CalcBrightsInZone:
				move.w	d0,d1
				muls	#20,d1
				move.l	Lvl_ZoneBorderPointsPtr_l,a1
				add.l	d1,a1
				move.l	#CurrentPointBrights,a0
				lea		(a0,d1.l*4),a0
				tst.b	draw_InUpperZone_b
				beq.s	.not_in_upper_zone

				adda.w	#4,a0

.not_in_upper_zone:
; A0 points at the brightnesses of the zone points.
; a1 points at the border points of the zone.
; list is terminated with -1.

				move.l	Lvl_PointsPtr_l,a3
				move.w	draw_Obj_XPos_w,oldx
				move.w	draw_Obj_ZPos_w,oldz
				move.w	#10,speed
				move.w	#0,Range

.do_point_bright:
				move.w	(a1)+,d0				;pt number
				blt		.done_point_bright

				move.w	(a3,d0.w*4),newx
				move.w	2(a3,d0.w*4),newz
				movem.l	d0-d7/a0-a6,-(a7)

				jsr		HeadTowardsAng

				movem.l	(a7)+,d0-d7/a0-a6
				move.w	AngRet,d1
				neg.w	d1
				and.w	#8191,d1
				asr.w	#8,d1
				asr.w	#1,d1
				move.w	(a0),d0
				bge.s	.okpos

				add.w	#332,d0
				asr.w	#2,d0
				neg.w	d0
				add.w	#332,d0

.okpos:
				sub.w	#300,d0
				bge.s	.okpos3

				move.w	#0,d0
.okpos3:
				move.b	d0,d2
				asr.b	#1,d2
				add.b	d2,d0
				move.b	d0,(a2,d1.w)
				move.w	2(a0),d0
				bge.s	.okpos2

				add.w	#332,d0
				asr.w	#2,d0
				neg.w	d0
				add.w	#332,d0

.okpos2:
				sub.w	#300,d0
				bge.s	.okpos4

				move.w	#0,d0
.okpos4:

				move.b	d0,d2
				asr.b	#1,d2
				add.b	d2,d0
				move.b	d0,16(a2,d1.w)
				adda.w	#8,a0

				bra		.do_point_bright

.done_point_bright:
				rts

				CNOP 0,4
draw_AngleBrights_vl:	ds.l	8*2

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

draw_Pals_vl:
				ds.l	2*49

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

guff:
				incbin	"includes/guff"



midx:			dc.w	0
objpixwidth:	dc.w	0
tmptst:			dc.l	0
toppt:			dc.l	0
doneit:			dc.w	0
replaceend:		dc.w	0
saveend:		dc.w	0
midobj:			dc.l	0
obadd:			dc.l	0
DOWN_STRIP:		dc.w	0
WAD_PTR:		dc.l	0
PTR_PTR:		dc.l	0

PolyAngPtr:		dc.l	0
PointAngPtr:	dc.l	0

				ds.w	100

*********************************
***************************************
*********************************
tstddd:			dc.l	0

polybehind:
				rts






;  Polygonal Object rendering
; a0 : object ; struct object {short id,x,y,z}
; a1 : view?
; struct Lvl_ObjectPointsPtr_l {short x,y,z}
draw_PolygonModel:

************************

; move.w 4(a0),d0	; ypos
; move.w 2(a0),d1
; add.w #2,d1
; add.w d1,d0
; cmp.w #-48,d0
; blt nobounce
; neg.w d1
; add.w d1,d0
;nobounce:
; move.w d1,2(a0)
; move.w d0,4(a0)

; add.w #80*2,boxang
; and.w #8191,boxang

************************

				move.w	EntT_CurrentAngle_w(a0),draw_ObjectAng_w
				move.w	Vid_CentreY_w,draw_PolygonCentreY_w
				move.w	(a0)+,d0				; object Id?
				move.l	Lvl_ObjectPointsPtr_l,a4
				move.w	(a4,d0.w*8),draw_Obj_XPos_w
				move.w	4(a4,d0.w*8),draw_Obj_ZPos_w
				move.w	2(a1,d0.w*8),d1			; zpos of mid; is this the view position ?
				blt		polybehind

				bgt.s	.okinfront

				move.l	a0,a3
				sub.l	Plr1_ObjectPtr_l,a3
				cmp.l	#DRAW_VECTOR_NEAR_PLANE,a3
				bne		polybehind

				tst.b	draw_WhichDoing_b
				bne		polybehind

				move.w	#1,d1
				; FIMXE: the original values here were 80 and 120
				; which sets weapons slighly lower in the view
				move.w	#SMALL_HEIGHT/2,draw_PolygonCentreY_w
				tst.b	Vid_FullScreen_b
				beq.s	.okinfront

				move.w	#FS_HEIGHT/2,draw_PolygonCentreY_w

.okinfront:
				movem.l	d0-d7/a0-a6,-(a7)

				jsr		draw_CalcBrightRings

				move.l	#draw_AngleBrights_vl,a0
				move.l	#draw_PointAndPolyBrights_vl,a1
				move.w	#15,d7
				move.w	#8,d6

MYacross:
				moveq	#0,d3
				moveq	#0,d4

				move.b	16(a0,d6.w),d4
				bge.s	.okp2
				moveq	#0,d4

.okp2:
				move.b	(a0,d6.w),d3
				bge.s	.okp1

				moveq	#0,d3

.okp1:

				sub.w	d3,d4
				swap	d3
				swap	d4
				asr.l	#3,d4
				moveq	#7,d2
				moveq	#3*16,d5

.down:
				swap	d3
				move.b	d3,(a1,d5.w)
				swap	d3
				add.w	#16,d5
				add.l	d4,d3
				dbra	d2,.down

TOPPART:
				moveq	#0,d3
				moveq	#0,d4
				bchg	#3,d6
				move.b	(a0,d6.w),d4
				bge.s	.okp2
				moveq	#0,d4

.okp2:
				bchg	#3,d6
				move.b	(a0,d6.w),d3
				bge.s	.okp1

				moveq	#0,d3

.okp1:
				sub.w	d3,d4
				swap	d3
				swap	d4
				asr.l	#4,d4 ; d4/8, then midpoint d4/2 => d4/16
				moveq	#3,d2
				moveq	#3*16,d5
.down:
				swap	d3
				move.b	d3,(a1,d5.w)
				swap	d3
				sub.w	#16,d5
				add.l	d4,d3
				dbra	d2,.down

BOTPART:
				moveq	#0,d3
				moveq	#0,d4
				bchg	#3,d6
				move.b	16(a0,d6.w),d4
				bge.s	.okp2

				moveq	#0,d4

.okp2:
				bchg	#3,d6
				move.b	16(a0,d6.w),d3
				bge.s	.okp1

				moveq	#0,d3

.okp1:
				sub.w	d3,d4
				swap	d3
				swap	d4
				asr.l	#4,d4 ; d4/8, then midpoint d4/2 => d4/16
				moveq	#3,d2
				move.w	#11*16,d5

.down:
				swap	d3
				move.b	d3,(a1,d5.w)
				swap	d3
				add.w	#16,d5
				add.l	d4,d3
				dbra	d2,.down

				subq	#1,d6
				and.w	#$f,d6
				addq	#1,a1
				dbra	d7,MYacross

				movem.l	(a7)+,d0-d7/a0-a6
				move.w	(a0),d2
				move.w	d1,d3
				asr.w	#7,d3
				add.w	d3,d2
				move.w	d2,draw_ObjectBright_w
				move.w	draw_TopClip_w,d2
				move.w	draw_BottomClip_w,d3
				move.w	d2,draw_ObjClipT_w
				move.w	d3,draw_ObjClipB_w

; dont use d1 here.
				move.w	6(a0),d5
				move.l	#Draw_PolyObjects_vl,a3
				move.l	(a3,d5.w*4),a3
				move.w	(a3)+,draw_SortIt_w
				move.l	a3,draw_StartOfObjPtr_l

*******************************************************************
***************************************************************
*****************************************************************

				move.w	(a3)+,draw_NumPoints_w
				move.w	(a3)+,d6				; num_frames
				move.l	a3,draw_PointerTablePtr_l
				lea		(a3,d6.w*4),a3
				move.l	a3,LinesPtr
				moveq	#0,d5
				move.w	8(a0),d5

************************************************
* Just for charles (animate automatically)
; add.w #1,d5
; cmp.w d6,d5
; blt.s okless
; moveq #0,d5
;okless:
; move.w d5,8(a0)
************************************************

				moveq	#0,d2
				move.l	draw_PointerTablePtr_l,a4
				move.w	(a4,d5.w*4),d2
				add.l	draw_StartOfObjPtr_l,d2
				move.l	d2,PtsPtr
				move.w	2(a4,d5.w*4),d5
				add.l	draw_StartOfObjPtr_l,d5
				move.l	d5,PolyAngPtr
				move.l	d2,a3
				move.w	draw_NumPoints_w,d5
				move.l	(a3)+,draw_ObjectOnOff_w
				move.l	a3,PointAngPtr
				move.w	d5,d2
				moveq	#0,d3
				lsr.w	#1,d2
				addx.w	d3,d2
				add.w	d2,d2
				add.w	d2,a3
				subq	#1,d5
				move.l	#boxrot,a4				; temp storage for rotated points?
				move.w	draw_ObjectAng_w,d2
				sub.w	#2048,d2				; 90deg
				sub.w	angpos,d2				; view angle
				and.w	#8191,d2				; wrap 360deg
				move.l	#SineTable,a2
				lea		(a2,d2.w),a5			; sine of object rotation wrt view
				move.l	#boxbrights,a6
				move.w	(a5),d6					; sine of object rotation
				move.w	2048(a5),d7				; cosine of object rotation. WHY DOES IT NOT NEED OOB/WRAP CHECK?
												; bigsine is 16kb, so 8192 words
												; this may mean the table is covering 4pi/720deg
rotate_object:
				move.w	(a3),d2					; xpt
				move.w	2(a3),d3				; ypt
				move.w	4(a3),d4				; zpt

; add.w d2,d2
; add.w d3,d3
; add.w d4,d4

; first rotate around z axis.

; move.w d2,d6
; move.w d3,d7
; muls 2048(a2),d3
; muls (a2),d2
; sub.l d3,d2	; newx
; muls (a2),d7
; muls 2048(a2),d6
; add.l d7,d6	; newy
; add.l d6,d6
; swap d6
; add.l d2,d2
; swap d2
; move.w d6,d3	; newy

				muls	d7,d4					; z * cos
				muls	d6,d2					; x * (sin << 16)
				sub.l	d4,d2
				asr.l	#8,d2
				asr.l	#1,d2					; ((z * cos - x * sin) << 16) >> 9 = (z * cos - x * sin) * 128
				move.l	d2,(a4)+				; store x' in boxpts
				ext.l	d3
				asl.l	#6,d3					; y * 64
				move.l	d3,(a4)+
				move.w	(a3),d2					; PtsPtr -> xpt
				move.w	4(a3),d4				; PtsPtr -> zpt
				muls	d6,d4					; z * sin
				muls	d7,d2					; x * cos
				add.l	d2,d4					; (z * sin  + x * cos) << 16
; add.l d4,d4
				swap	d4						; (z * sin  + x * cos)
				move.w	d4,(a4)+				; store z' in boxpts
				addq	#6,a3					; next point
				dbra	d5,rotate_object

				move.l	4(a1,d0.w*8),d0			; xpos of mid; is this the object position?
				move.w	draw_NumPoints_w,d7
				move.l	#boxrot,a2
				move.l	#boxonscr,a3
				move.l	#boxbrights,a6
				move.w	2(a0),d2				; object y pos?
				subq	#1,d7
				asl.l	#1,d0					;
; Projection for polygonal objects to screen here?
				tst.b	Vid_FullScreen_b
				beq.s	smallscreen_conv

fullscreen_conv:
				; 0xABADCAFE - this is very weird. If I supply the correct factor of 5/3, vector models break
				; but if I don't correct for it in billboard rendering, the bitmap depth is incorrect.
				move.w	d1,d3
				asl.w	#1,d1
				add.w	d3,d1					; d1 * 3  because 288 is ~1.5times larger than 196?
												; if I change this, 3d objects start "swimming" with regard to the world

				ext.l	d2
				asl.l	#7,d2					; (view_ypos * 128 - yoff) * 2
				sub.l	yoff,d2
				asl.l	#1,d2

.convert_to_screen:
				move.l	(a2),d3					;
				add.l	d0,d3					; x'' = xpos_of_view + x
				move.l	d3,(a2)+				; '
				move.l	(a2),d4					;
				add.l	d2,d4					; y'' = y' + ypos_obj
				move.l	d4,(a2)+				;
				move.w	(a2),d5					; z'
				add.w	d1,d5					; z'' = z' + zpos_of_view
				ble		.ptbehind
				move.w	d5,(a2)+

				; FIXME: can we factor the 3/2 scaling into Z somewhere else?
				add.w	d5,d5					; z'' * 2  to achieve  3/2 scaling for fullscreen

				; 0xABADCAFE - going to be multiplying by 5/3 here for the 320 fullscreen
				move.l	#3413,d6

				; todo lower precision, 16 bit multiply?
				; approximate 3.333 => 3413/1024
				muls.l	d6,d4
				asr.l	#8,d4
				asr.l	#2,d4		; y'' * 3.333
				divs	d5,d4		; ys = (x*3)/(z*2)

				; todo lower precision, 16 bit multiply?
				; approximate 3.333 => 3413/1024
				muls.l	d6,d3
				asr.l	#8,d3
				asr.l	#2,d3		; x'' * 3.333
				divs	d5,d3		; xs = (x*3)/(z*2)
				add.w	Vid_CentreX_w,d3	; mid_x of screen
				add.w	draw_PolygonCentreY_w,d4	; mid_y of screen
				move.w	d3,(a3)+	; store xs,ys in boxonscr
				move.w	d4,(a3)+
				dbra	d7,.convert_to_screen

				bra		done_conv

.ptbehind:
				move.w	d5,(a2)+
				move.w	#32767,(a3)+
				move.w	#32767,(a3)+
				dbra	d7,.convert_to_screen

				bra		done_conv

				; Small display
smallscreen_conv:
				asl.w	#1,d1					; d1 * 2
				ext.l	d2
				asl.l	#7,d2
				sub.l	yoff,d2
				asl.l	#1,d2					; (d2*128 - yoff) *2

.convert_to_screen:
				move.l	(a2),d3
				add.l	d0,d3
				move.l	d3,(a2)+
				move.l	(a2),d4
				add.l	d2,d4
				move.l	d4,(a2)+
				move.w	(a2),d5
				add.w	d1,d5
				ble		.ptbehind2

				move.w	d5,(a2)+
				divs	d5,d3
				divs	d5,d4
				add.w	Vid_CentreX_w,d3
				add.w	draw_PolygonCentreY_w,d4
				move.w	d3,(a3)+
				move.w	d4,(a3)+
				dbra	d7,.convert_to_screen

				bra		done_conv

.ptbehind2:
				move.w	d5,(a2)+
				move.w	#32767,(a3)+
				move.w	#32767,(a3)+
				dbra	d7,.convert_to_screen

done_conv:

**************************
				move.w	draw_NumPoints_w,d7
				move.l	#boxbrights,a6
				subq	#1,d7
				move.l	PointAngPtr,a0
				move.l	#draw_PointAndPolyBrights_vl,a2
				move.w	draw_ObjectAng_w,d2
				asr.w	#8,d2
				asr.w	#1,d2
				st		d5

.calc_point_angle_brightness_loop:
				moveq	#0,d0
				move.b	(a0)+,d0
				move.b	d0,d3
				add.w	d2,d3
				and.w	#$f,d3
				and.w	#$f0,d0
				add.w	d3,d0
				moveq	#0,d1
				move.b	(a2,d0.w),d1
				bge.s	.okpos

				moveq	#0,d1

.okpos:
				cmp.w	#31,d1
				ble.s	.oksmall
				move.w	#31,d1

.oksmall:
				move.w	d1,(a6)+
				dbra	d7,.calc_point_angle_brightness_loop

*************************
				move.l	LinesPtr,a1

; Now need to sort parts of object
; into order.

				move.l	#PartBuffer,a0
				move.l	a0,a2
				move.w	#63,d0

clrpartbuff:
				move.l	#$80000001,(a2)
				addq	#4,a2
				dbra	d0,clrpartbuff

				move.l	#boxrot,a2
				move.l	draw_ObjectOnOff_w,d5
				tst.w	draw_SortIt_w
				bne.s	PutinParts

putinunsorted:
				move.w	(a1)+,d7
				blt		doneallparts

				lsr.l	#1,d5
				bcs.s	.yeson

				addq	#2,a1
				bra		putinunsorted

.yeson:
				move.w	(a1)+,d6
				move.l	#0,(a0)+
				move.w	d7,(a0)
				addq	#4,a0
				bra		putinunsorted

PutinParts:
				move.w	(a1)+,d7
				blt		doneallparts

				lsr.l	#1,d5
				bcs.s	.yeson

				addq	#2,a1
				bra		PutinParts

.yeson:
				move.w	(a1)+,d6
				move.l	(a2,d6.w),d0
				asr.l	#7,d0
				muls	d0,d0
				move.l	4(a2,d6.w),d2
				asr.l	#7,d2
				muls	d2,d2
				add.l	d2,d0
				move.w	8(a2,d6.w),d2
				muls	d2,d2
				add.l	d2,d0
				move.l	#PartBuffer-8,a0

stillfront:
				addq	#8,a0
				cmp.l	(a0),d0
				blt		stillfront

				move.l	#endparttab-8,a5

domoreshift:
				move.l	-8(a5),(a5)
				move.l	-4(a5),4(a5)
				subq	#8,a5
				cmp.l	a0,a5
				bgt.s	domoreshift

				move.l	d0,(a0)
				move.w	d7,4(a0)
				bra		PutinParts

doneallparts:
				move.l	#PartBuffer,a0

Partloop:
				move.l	(a0)+,d7
				blt		nomoreparts

				moveq	#0,d0
				move.w	(a0),d0
				addq	#4,a0
				add.l	draw_StartOfObjPtr_l,d0
				move.l	d0,a1
				move.w	#0,firstpt

polyloo:
				tst.w	(a1)
				blt.s	nomorepolys

				movem.l	a0/a1/d7,-(a7)
				bsr		doapoly

				movem.l	(a7)+,a0/a1/d7
				move.w	(a1),d0
				lea		18(a1,d0.w*4),a1
				bra.s	polyloo

nomorepolys:
				bra		Partloop

nomoreparts:
				rts

firstpt:		dc.w	0

PartBuffer:
				ds.w	4*32
endparttab:

polybright:		dc.l	0
PolyAng:		dc.w	0

doapoly:
				move.w	#960,draw_Left_w
				move.w	#-10,draw_Right_w
				move.w	(a1)+,d7				; lines to draw
				move.w	(a1)+,draw_PreHoles_b
				move.w	12(a1,d7.w*4),draw_PreGouraud_b
				move.l	#boxonscr,a3
				movem.l	d0-d7/a0-a6,-(a7)

; * Check for any of these points behind...

checkbeh:
				move.w	(a1),d0
				cmp.w	#32767,(a3,d0.w*4)
				bne.s	.notbeh

				cmp.w	#32767,2(a3,d0.w*4)
				bne.s	.notbeh

				movem.l	(a7)+,d0-d7/a0-a6
				bra		polybehind

.notbeh:
				addq	#4,a1
				dbra	d7,checkbeh

				movem.l	(a7)+,d0-d7/a0-a6
				move.w	(a1),d0
				move.w	4(a1),d1
				move.w	8(a1),d2
				move.w	2(a3,d0.w*4),d3
				move.w	2(a3,d1.w*4),d4
				move.w	2(a3,d2.w*4),d5
				move.w	(a3,d0.w*4),d0
				move.w	(a3,d1.w*4),d1
				move.w	(a3,d2.w*4),d2
				sub.w	d1,d0					;x1
				sub.w	d1,d2					;x2
				sub.w	d4,d3					;y1
				sub.w	d4,d5					;y2
				muls	d3,d2
				muls	d5,d0
				sub.l	d0,d2
				ble		polybehind
				move.l	#boxrot,a3
				move.w	(a1),d0
				move.w	d0,d1
				asl.w	#2,d0
				add.w	d1,d0
				move.w	4(a1),d1
				move.l	d1,d2
				asl.w	#2,d1
				add.w	d2,d1
				move.w	8(a1),d2
				move.w	d2,d3
				asl.w	#2,d2
				add.w	d3,d2
				move.l	4(a3,d0.w*2),d3
				move.l	4(a3,d1.w*2),d4
				move.l	4(a3,d2.w*2),d5
				move.l	(a3,d0.w*2),d0
				move.l	(a3,d1.w*2),d1
				move.l	(a3,d2.w*2),d2
				sub.l	d1,d0					;x1
				sub.l	d1,d2					;x2
				sub.l	d4,d3					;y1
				sub.l	d4,d5					;y2
				asr.l	#7,d0
				asr.l	#7,d2
				asr.l	#7,d3
				asr.l	#7,d5
				muls	d3,d2
				muls	d5,d0
				sub.l	d0,d2
				move.l	d2,polybright
				move.l	#boxonscr,a3
				clr.b	drawit
				tst.b	draw_Gouraud_b(pc)
				bne.s	usegour

				bsr		draw_PutInLines

				bra.s	dontusegour

usegour:
				bsr		draw_PutInLinesGouraud

dontusegour:
				move.w	#SCREENWIDTH,linedir
				move.l	Vid_FastBufferPtr_l,a6
				tst.b	drawit(pc)
				beq		polybehind

				move.l	#PolyTopTab,a4
				move.w	draw_Left_w(pc),d1
				move.w	draw_Right_w(pc),d7
				move.w	draw_LeftClipB_w,d3
				move.w	draw_RightClipB_w,d4
				cmp.w	d3,d7
				ble		polybehind

				cmp.w	d4,d1
				bge		polybehind

				cmp.w	d3,d1
				bge		.notop

				move.w	d3,d1

.notop:
				cmp.w	d4,d7
				ble		.nobot
				move.w	d4,d7

.nobot:
				add.w	d1,d1
				lea		(a4,d1.w*8),a4
				asr.w	#1,d1
				sub.w	d1,d7
				ble		polybehind

				move.w	d1,a2
				moveq	#0,d0
				move.l	TextureMaps,a0
				move.w	(a1)+,d0
				bge.s	.notsec

				and.w	#$7fff,d0
				add.l	#65536,a0

.notsec:
				add.w	d0,a0
				moveq	#0,d0
				moveq	#0,d1
				move.b	(a1)+,d1
				asl.w	#5,d1
				ext.l	d1
				divs	#100,d1
				neg.w	d1
				add.w	#31,d1
				tst.b	draw_Holes_b
				bne		gotholesin

				tst.b	draw_Gouraud_b(pc)
				bne		gotlurvelyshading

				move.w	draw_ObjectAng_w,d4
				asr.w	#8,d4
				asr.w	#1,d4
				moveq	#0,d2
				moveq	#0,d3
				move.b	(a1)+,d2
				move.l	PolyAngPtr,a1
				move.b	(a1,d2.w),d2
				move.b	d2,d3
				add.w	d4,d3
				and.w	#$f,d3
				and.w	#$f0,d2
				add.b	d3,d2
				move.l	#draw_PointAndPolyBrights_vl,a1
				moveq	#0,d5
				move.b	(a1,d2.w),d5
				add.w	d5,d1
				move.l	#draw_ObjScaleCols_vw,a1
; move.w draw_ObjectBright_w(pc),d0
; add.w d0,d1
				tst.w	d1
				bge.s	toobright

				move.w	#0,d1

toobright:
				cmp.w	#31,d1
				blt.s	.toodark
				moveq	#31,d1

.toodark:
				asl.w	#8,d1
; move.w (a1,d1.w*2),d1
; asl.w #3,d1
				move.l	TexturePal,a1
				add.l	#256*32,a1
				lea		(a1,d1.w),a1
				tst.b	draw_PreGouraud_b
				bne		predoglare

dopoly:
				move.w	#0,offtopby
				move.l	a6,a3
				adda.w	a2,a3
				addq	#1,a2
				move.w	(a4),d1
				cmp.w	draw_ObjClipB_w,d1
				bge		nodl

				move.w	PolyBotTab-PolyTopTab(a4),d2
				cmp.w	draw_ObjClipT_w,d2
				ble		nodl

				cmp.w	draw_ObjClipT_w,d1
				bge.s	nocl

				move.w	draw_ObjClipT_w,d3
				sub.w	d1,d3
				move.w	d3,offtopby
				move.w	draw_ObjClipT_w,d1

nocl:
				move.w	d2,d0
				cmp.w	draw_ObjClipB_w,d2
				ble.s	nocr

				move.w	draw_ObjClipB_w,d2

nocr:
; d1=top end
; d2=bot end
				move.l	2+PolyBotTab-PolyTopTab(a4),d3
				move.l	6+PolyBotTab-PolyTopTab(a4),d4
				move.l	2(a4),d5
				move.l	6(a4),d6
				sub.l	d5,d3
				sub.l	d6,d4

; asl.w #8,d3
; asl.w #8,d4
; ext.l d3
; ext.l d4

; and.b #63,d5
; and.b #63,d6
; lsl.w #8,d6
; move.b d5,d6	; starting pos
; moveq.l #0,d5
; move.w d6,d5

				sub.w	d1,d2
				ble		nodl

				move.w	#0,tstdca
				sub.w	d1,d0
				tst.w	offtopby
				beq.s	.notofftop

				move.l	d3,-(a7)
				move.l	d4,-(a7)
				add.w	offtopby,d0
				ext.l	d0
				muls.l	offtopby-2,d3
				muls.l	offtopby-2,d4
				divs.l	d0,d3
				divs.l	d0,d4
				add.l	d3,d5
				add.l	d4,d6
				move.l	(a7)+,d4
				move.l	(a7)+,d3

.notofftop:
				ext.l	d0
				divs.l	d0,d3
				divs.l	d0,d4
				add.l	ontoscr(pc,d1.w*4),a3
				move.l	#$3fffff,d1
				move.l	d3,a5
				moveq	#0,d3
				subq	#1,d2

drawpol:
				and.l	d1,d5
				and.l	d1,d6
				move.l	d6,d0
				asr.l	#8,d0
				swap	d5
				move.b	d5,d0
				move.b	(a0,d0.w*4),d3
				swap	d5
				add.l	a5,d5
				add.l	d4,d6
				move.b	(a1,d3.w),(a3)
				adda.w	#SCREENWIDTH,a3
				dbra	d2,drawpol

; add.w a5,d3
; addx.l d6,d5
; dbcs d2,drawpol2
; dbcc d2,drawpol
; bra.s pastit
;drawpol2:
; and.w d1,d5
; move.b (a0,d5.w*4),d0
; move.w (a1,d0.w*2),(a3)
; adda.w #SCREENWIDTH,a3
; add.w a5,d3
; addx.l d4,d5
; dbcs d2,drawpol2
; dbcc d2,drawpol

pastit:
nodl:
				adda.w	#16,a4
				dbra	d7,dopoly

				rts

ontoscr:
val				SET		0
				REPT	256
				dc.l	val
val				SET		val+SCREENWIDTH
				ENDR

predoglare:
				move.l	TexturePal,a1
				sub.w	#512,a1

DOGLAREPOLY:
				move.w	#0,offtopby
				move.l	a6,a3
				adda.w	a2,a3
				addq	#1,a2
				move.w	(a4),d1
				cmp.w	draw_ObjClipB_w,d1
				bge		nodlGL

				move.w	PolyBotTab-PolyTopTab(a4),d2
				cmp.w	draw_ObjClipT_w,d2
				ble		nodlGL

				cmp.w	draw_ObjClipT_w,d1
				bge.s	noclGL

				move.w	draw_ObjClipT_w,d3
				sub.w	d1,d3
				move.w	d3,offtopby
				move.w	draw_ObjClipT_w,d1

noclGL:
				move.w	d2,d0
				cmp.w	draw_ObjClipB_w,d2
				ble.s	nocrGL

				move.w	draw_ObjClipB_w,d2

nocrGL:
; d1=top end
; d2=bot end
				move.l	2+PolyBotTab-PolyTopTab(a4),d3
				move.l	6+PolyBotTab-PolyTopTab(a4),d4
				move.l	2(a4),d5
				move.l	6(a4),d6
				sub.l	d5,d3
				sub.l	d6,d4

; asl.w #8,d3
; asl.w #8,d4
; ext.l d3
; ext.l d4

; and.b #63,d5
; and.b #63,d6
; lsl.w #8,d6
; move.b d5,d6	; starting pos
; moveq.l #0,d5
; move.w d6,d5

				sub.w	d1,d2
				ble		nodlGL

				move.w	#0,tstdca
				sub.w	d1,d0
				tst.w	offtopby
				beq.s	.notofftop

				move.l	d3,-(a7)
				move.l	d4,-(a7)
				add.w	offtopby,d0
				ext.l	d0
				muls.l	offtopby-2,d3
				muls.l	offtopby-2,d4
				divs.l	d0,d3
				divs.l	d0,d4
				add.l	d3,d5
				add.l	d4,d6
				move.l	(a7)+,d4
				move.l	(a7)+,d3

.notofftop:
				ext.l	d0
				divs.l	d0,d3
				divs.l	d0,d4
				add.l	ontoscrGL(pc,d1.w*4),a3
				move.l	#$3fffff,d1
				move.l	d3,a5
				moveq	#0,d3
				subq	#1,d2

drawpolGL:
				and.l	d1,d5
				and.l	d1,d6
				move.l	d6,d0
				asr.l	#8,d0
				swap	d5
				move.b	d5,d0
				move.b	(a0,d0.w*4),d3
				beq.s	itsblack

				lsl.w	#8,d3
				add.w	d3,d3
				move.b	(a3),d3
				swap	d5
				add.l	a5,d5
				add.l	d4,d6
				move.b	(a1,d3.w),(a3)
				adda.w	#SCREENWIDTH,a3
				dbra	d2,drawpolGL

nodlGL:
				adda.w	#16,a4
				dbra	d7,DOGLAREPOLY

				rts

itsblack:
				swap	d5
				add.l	a5,d5
				add.l	d4,d6
				adda.w	#SCREENWIDTH,a3
				dbra	d2,drawpolGL

				adda.w	#16,a4
				dbra	d7,DOGLAREPOLY

				rts

ontoscrGL:
val				SET		0
				REPT	256
				dc.l	val
val				SET		val+SCREENWIDTH
				ENDR

tstdca:			dc.l	0
				dc.w	0
offtopby:		dc.w	0
LinesPtr:		dc.l	0
PtsPtr:			dc.l	0

gotlurvelyshading:
				move.l	TexturePal,a1
				add.l	#256*32,a1
				tst.b	draw_PreGouraud_b

; beq.s .noshiny
; add.l #256*32,a1
;.noshiny:
; neg.w d1
; add.w #14,d1
; bge.s toobrightg
; move.w #0,d1
;toobrightg:
; asl.w #8,d1
; lea (a1,d1.w*2),a1

dopolyg:
				move.l	d7,-(a7)
				move.w	#0,offtopby
				move.l	a6,a3
				adda.w	a2,a3
				addq	#1,a2
				move.w	(a4),d1
				cmp.w	draw_ObjClipB_w,d1
				bge		nodlg

				move.w	PolyBotTab-PolyTopTab(a4),d2
				cmp.w	draw_ObjClipT_w(pc),d2
				ble		nodlg

				cmp.w	draw_ObjClipT_w(pc),d1
				bge.s	noclg

				move.w	draw_ObjClipT_w,d3
				sub.w	d1,d3
				move.w	d3,offtopby
				move.w	draw_ObjClipT_w(pc),d1

noclg:
				move.w	d2,d0
				cmp.w	draw_ObjClipB_w(pc),d2
				ble.s	nocrg
				move.w	draw_ObjClipB_w(pc),d2
nocrg:

; d1=top end
; d2=bot end
				move.l	2+PolyBotTab-PolyTopTab(a4),d3
				move.l	6+PolyBotTab-PolyTopTab(a4),d4
				move.l	2(a4),d5
				move.l	6(a4),d6
				sub.l	d5,d3
				sub.l	d6,d4

; asl.w #8,d3
; asl.w #8,d4
; ext.l d3
; ext.l d4

; and.b #63,d5
; and.b #63,d6
; lsl.w #8,d6
; move.b d5,d6	; starting pos
; moveq.l #0,d5
; move.w d6,d5
				sub.w	d1,d2
				ble		nodlg

				move.w	#0,tstdca
				sub.w	d1,d0
				tst.w	offtopby
				beq.s	.notofftop

				move.l	d3,-(a7)
				move.l	d4,-(a7)
				add.w	offtopby,d0
				ext.l	d0
				muls.l	offtopby-2,d3
				muls.l	offtopby-2,d4
				divs.l	d0,d3
				divs.l	d0,d4
				add.l	d3,d5
				add.l	d4,d6
				move.l	(a7)+,d4
				move.l	(a7)+,d3

.notofftop:
				ext.l	d0
				divs.l	d0,d3
				divs.l	d0,d4
				add.l	ontoscrg(pc,d1.w*4),a3
				move.w	10+PolyBotTab-PolyTopTab(a4),d1
				move.w	10(a4),d7
				sub.w	d7,d1
				asl.w	#8,d7
				swap	d1
				clr.w	d1
				divs.l	d0,d1
				asr.l	#8,d1
				move.l	d3,a5
				moveq	#0,d3
				swap	d2
				move.w	d1,d2
				swap	d2
				move.l	#$3fffff,d1
				subq.w	#1,d2

drawpolg:
				and.l	d1,d5
				and.l	d1,d6
				move.l	d6,d0
				asr.l	#8,d0
				swap	d5
				move.b	d5,d0
				move.w	d7,d3
				move.b	(a0,d0.w*4),d3
				swap	d2
				swap	d5
				add.l	a5,d5
				add.l	d4,d6
				add.w	d2,d7
				swap	d2
				move.b	(a1,d3.w),(a3)
				adda.w	#SCREENWIDTH,a3
				dbra	d2,drawpolg

nodlg:
				move.l	(a7)+,d7
				adda.w	#16,a4
				dbra	d7,dopolyg

				rts

ontoscrg:
val				SET		0
				REPT	256
				dc.l	val
val				SET		val+SCREENWIDTH
				ENDR

gotholesin:
				move.w	draw_ObjectAng_w,d4
				asr.w	#8,d4
				asr.w	#1,d4
				moveq	#0,d2
				moveq	#0,d3
				move.b	(a1)+,d2
				move.l	PolyAngPtr,a1
				move.b	(a1,d2.w),d2
				move.b	d2,d3
				lsr.b	#4,d3					;d3=vertical pos
				add.b	d4,d2
				and.w	#$f,d2
				move.l	#draw_AngleBrights_vl,a1
				moveq	#0,d4
				moveq	#0,d5
				move.b	(a1,d2.w),d4			;top
				move.b	16(a1,d2.w),d5			;bottom
				sub.w	d4,d5

				;muls	d3,d5
				;divs	#14,d5 ; wat?

				add.w	#73,d3 ; 73/1024 ~= 1/14. Accumulate here.
				muls	d3,d5
				asr.l	#8,d5
				asr.l	#2,d5
				add.w	d4,d5
				add.w	d5,d1
				move.l	#draw_ObjScaleCols_vw,a1

; move.w draw_ObjectBright_w(pc),d0
; add.w d0,d1
				tst.w	d1
				bge.s	toobrighth

				move.w	#0,d1

toobrighth:
				cmp.w	#31,d1
				ble.s	toodimh
				move.w	#31,d1

toodimh:
				asl.w	#8,d1

; move.w (a1,d1.w*2),d1
; asl.w #3,d1
				move.l	TexturePal,a1
				add.l	#256*32,a1
				add.w	d1,a1
				tst.b	draw_PreGouraud_b
; beq.s .noshiny
; add.l #256*32,a1
;.noshiny:

dopolyh:
				move.w	#0,offtopby
				move.l	a6,a3
				adda.w	a2,a3
				addq	#1,a2
				move.w	(a4),d1
				cmp.w	draw_ObjClipB_w,d1
				bge		nodlh

				move.w	PolyBotTab-PolyTopTab(a4),d2
				cmp.w	draw_ObjClipT_w,d2
				ble		nodlh

				cmp.w	draw_ObjClipT_w,d1
				bge.s	noclh

				move.w	draw_ObjClipT_w,d3
				sub.w	d1,d3
				move.w	d3,offtopby
				move.w	draw_ObjClipT_w,d1

noclh:
				move.w	d2,d0
				cmp.w	draw_ObjClipB_w,d2
				ble.s	nocrh

				move.w	draw_ObjClipB_w,d2

nocrh:
; d1=top end
; d2=bot end
				move.l	2+PolyBotTab-PolyTopTab(a4),d3
				move.l	6+PolyBotTab-PolyTopTab(a4),d4
				move.l	2(a4),d5
				move.l	6(a4),d6
				sub.l	d5,d3
				sub.l	d6,d4

; asl.w #8,d3
; asl.w #8,d4
; ext.l d3
; ext.l d4

; and.b #63,d5
; and.b #63,d6
; lsl.w #8,d6
; move.b d5,d6	; starting pos
; moveq #-1,d5
; lsr.l #1,d5
; move.w d6,d5

				sub.w	d1,d2
				ble		nodlh

				move.w	#0,tstdca
				sub.w	d1,d0
				tst.w	offtopby
				beq.s	.notofftop

				move.l	d3,-(a7)
				move.l	d4,-(a7)
				add.w	offtopby,d0
				ext.l	d0
				muls.l	offtopby-2,d3
				muls.l	offtopby-2,d4
				divs.l	d0,d3
				divs.l	d0,d4
				add.l	d3,d5
				add.l	d4,d6
				move.l	(a7)+,d4
				move.l	(a7)+,d3

.notofftop:
				ext.l	d0
				divs.l	d0,d3
				divs.l	d0,d4
				add.l	ontoscrh(pc,d1.w*4),a3
				move.l	#$3fffff,d1
				move.l	d3,a5
				moveq	#0,d3
				subq	#1,d2

drawpolh:
				and.l	d1,d5
				and.l	d1,d6
				move.l	d6,d0
				asr.l	#8,d0
				swap	d5
				move.b	d5,d0
				swap	d5
				add.l	a5,d5
				add.l	d4,d6
				move.b	(a0,d0.w*4),d3
				beq.s	.dontplot
				move.b	(a1,d3.w),(a3)

.dontplot:
				adda.w	#SCREENWIDTH,a3
				dbra	d2,drawpolh

pastith:
nodlh:
				adda.w	#16,a4
				dbra	d7,dopolyh

				rts

ontoscrh:
val				SET		0
				REPT	256
				dc.l	val
val				SET		val+SCREENWIDTH
				ENDR

				EVEN
draw_PreGouraud_b:
				dc.b	0 ; written as word, which also sets next byte
draw_Gouraud_b:
				dc.b	0 ; tested as byte
draw_PreHoles_b:
				dc.b	0 ; written as word, which also sets next byte
draw_Holes_b:
				dc.b	0 ; tested as byte

draw_PutInLines:
				move.w	(a1),d0
				move.w	4(a1),d1
				move.w	(a3,d0.w*4),d2
				move.w	2(a3,d0.w*4),d3
				move.w	(a3,d1.w*4),d4
				move.w	2(a3,d1.w*4),d5

; d2=x1 d3=y1 d4=x2 d5=y2

				cmp.w	d2,d4
				beq		this_line_flat

				bgt		this_line_on_top

				move.l	#PolyBotTab,a4
				exg		d2,d4
				exg		d3,d5
				cmp.w	draw_RightClipB_w,d2
				bge		this_line_flat

				cmp.w	draw_LeftClipB_w,d4
				ble		this_line_flat

				move.w	draw_RightClipB_w,d6
				sub.w	d4,d6
				ble.s	.clip_right

				move.w	#0,-(a7)
				cmp.w	draw_Right_w(pc),d4
				ble.s	.no_new_bottom

				move.w	d4,draw_Right_w
				bra.s	.no_new_bottom

.clip_right:
				move.w	d6,-(a7)
				move.w	draw_RightClipB_w,draw_Right_w
				sub.w	#1,draw_Right_w

.no_new_bottom:
				move.w	#0,draw_OffLeftBy_w
				move.w	d2,d6
				cmp.w	draw_LeftClipB_w,d6
				bge		.okt

				move.w	draw_LeftClipB_w,d6
				sub.w	d2,d6
				move.w	d6,draw_OffLeftBy_w
				add.w	d2,d6

.okt:
				st		drawit
				add.w	d6,d6
				lea		(a4,d6.w*8),a4
				asr.w	#1,d6
				cmp.w	draw_Left_w(pc),d6
				bge.s	.no_new_top

				move.w	d6,draw_Left_w

.no_new_top:
				sub.w	d3,d5					; dy
				swap	d3
				clr.w	d3						; d2=xpos
				sub.w	d2,d4					; dx > 0
				ext.l	d4
				swap	d5
				clr.w	d5
				divs.l	d4,d5
				moveq	#0,d2
				move.b	2(a1),d2
				moveq	#0,d6
				move.b	6(a1),d6
				sub.w	d6,d2
				swap	d2
				swap	d6
				clr.w	d2
				clr.w	d6						; d6=xbitpos
				divs.l	d4,d2
				move.l	d5,a5					; a5=dy constant
				move.l	d2,a6					; a6=xbitconst
				moveq	#0,d5
				move.b	3(a1),d5
				moveq	#0,d2
				move.b	7(a1),d2
				sub.w	d2,d5
				swap	d2
				swap	d5
				clr.w	d2						; d3=ybitpos
				clr.w	d5
				divs.l	d4,d5
				add.w	(a7)+,d4
				sub.w	draw_OffLeftBy_w(pc),d4
				blt		this_line_flat

				tst.w	draw_OffLeftBy_w(pc)
				beq.s	.none_off_left

				move.w	d4,-(a7)
				move.w	draw_OffLeftBy_w(pc),d4
				dbra	d4,.calc_no_draw

				bra		.no_draw_off_left

.calc_no_draw:
				add.l	a5,d3
				add.l	a6,d6
				add.l	d5,d2
				dbra	d4,.calc_no_draw

.no_draw_off_left:
				move.w	(a7)+,d4

.none_off_left:
.put_in_line:
				swap	d3
				move.w	d3,(a4)+
				swap	d3
				move.l	d6,(a4)+
				move.l	d2,(a4)+
				addq	#6,a4
				add.l	a5,d3
				add.l	a6,d6
				add.l	d5,d2
				dbra	d4,.put_in_line

				bra		this_line_flat

this_line_on_top:
				move.l	#PolyTopTab,a4
				cmp.w	draw_RightClipB_w,d2
				bge		this_line_flat

				cmp.w	draw_LeftClipB_w,d4
				ble		this_line_flat

				move.w	draw_RightClipB_w,d6
				sub.w	d4,d6
				ble.s	.clip_right

				move.w	#0,-(a7)
				cmp.w	draw_Right_w(pc),d4
				ble.s	.no_new_bottom

				move.w	d4,draw_Right_w
				bra.s	.no_new_bottom

.clip_right:
				move.w	d6,-(a7)
				move.w	draw_RightClipB_w,draw_Right_w
				sub.w	#1,draw_Right_w

.no_new_bottom:
				move.w	#0,draw_OffLeftBy_w
				move.w	d2,d6
				cmp.w	draw_LeftClipB_w,d6
				bge		.okt

				move.w	draw_LeftClipB_w,d6
				sub.w	d2,d6
				move.w	d6,draw_OffLeftBy_w
				add.w	d2,d6

.okt:
				st		drawit
				add.w	d6,d6
				lea		(a4,d6.w*8),a4
				asr.w	#1,d6
				cmp.w	draw_Left_w(pc),d6
				bge.s	.no_new_top

				move.w	d6,draw_Left_w

.no_new_top:
				sub.w	d3,d5					; dy
				swap	d3
				clr.w	d3						; d2=xpos
				sub.w	d2,d4					; dx > 0
				ext.l	d4
				swap	d5
				clr.w	d5
				divs.l	d4,d5
				moveq	#0,d2
				move.b	6(a1),d2
				moveq	#0,d6
				move.b	2(a1),d6
				sub.w	d6,d2
				swap	d2
				swap	d6
				clr.w	d2
				clr.w	d6						; d6=xbitpos
				divs.l	d4,d2
				move.l	d5,a5					; a5=dy constant
				move.l	d2,a6					; a6=xbitconst
				moveq	#0,d5
				move.b	7(a1),d5
				moveq	#0,d2
				move.b	3(a1),d2
				sub.w	d2,d5
				swap	d2
				swap	d5
				clr.w	d2						; d3=ybitpos
				clr.w	d5
				divs.l	d4,d5
				add.w	(a7)+,d4
				sub.w	draw_OffLeftBy_w(pc),d4
				blt.s	this_line_flat

				tst.w	draw_OffLeftBy_w(pc)
				beq.s	.none_off_left

				move.w	d4,-(a7)
				move.w	draw_OffLeftBy_w(pc),d4
				dbra	d4,.calc_no_draw

				bra		.no_draw_off_left

.calc_no_draw:
				add.l	a5,d3
				add.l	a6,d6
				add.l	d5,d2
				dbra	d4,.calc_no_draw

.no_draw_off_left:
				move.w	(a7)+,d4

.none_off_left:
.put_in_line:
				swap	d3
				move.w	d3,(a4)+
				swap	d3
				move.l	d6,(a4)+
				move.l	d2,(a4)+
				addq	#6,a4
				add.l	a5,d3
				add.l	a6,d6
				add.l	d5,d2
				dbra	d4,.put_in_line

this_line_flat:
				addq	#4,a1
				dbra	d7,draw_PutInLines

				addq	#4,a1
				rts

draw_PutInLinesGouraud:
				move.l	#boxbrights,a2

piglloop:
				move.w	(a1),d0
				move.w	4(a1),d1
				move.w	(a3,d0.w*4),d2
				move.w	2(a3,d0.w*4),d3
				move.w	(a3,d1.w*4),d4
				move.w	2(a3,d1.w*4),d5
				cmp.w	d2,d4
				beq		this_line_flat_gouraud

				bgt		this_line_on_top_gouraud

				move.l	#PolyBotTab,a4
				exg		d2,d4
				exg		d3,d5
				cmp.w	draw_RightClipB_w,d2
				bge		this_line_flat_gouraud

				cmp.w	draw_LeftClipB_w,d4
				ble		this_line_flat_gouraud

				move.w	draw_RightClipB_w,d6
				sub.w	d4,d6
				ble.s	.clip_right

				move.w	#0,-(a7)
				cmp.w	draw_Right_w(pc),d4
				ble.s	.no_new_bottom

				move.w	d4,draw_Right_w
				bra.s	.no_new_bottom

.clip_right:
				move.w	d6,-(a7)
				move.w	draw_RightClipB_w,draw_Right_w
				sub.w	#1,draw_Right_w

.no_new_bottom:
				move.w	#0,draw_OffLeftBy_w
				move.w	d2,d6
				cmp.w	draw_LeftClipB_w,d6
				bge		.okt

				move.w	draw_LeftClipB_w,d6
				sub.w	d2,d6
				move.w	d6,draw_OffLeftBy_w
				add.w	d2,d6

.okt:
				st		drawit
				add.w	d6,d6
				lea		(a4,d6.w*8),a4
				asr.w	#1,d6
				cmp.w	draw_Left_w(pc),d6
				bge.s	.no_new_top

				move.w	d6,draw_Left_w

.no_new_top:
				sub.w	d3,d5					; dy
				swap	d3
				clr.w	d3						; d2=xpos
				sub.w	d2,d4					; dx > 0
				ext.l	d4
				swap	d5
				clr.w	d5
				divs.l	d4,d5
				moveq	#0,d2
				move.b	2(a1),d2
				moveq	#0,d6
				move.b	6(a1),d6
				sub.w	d6,d2
				swap	d2
				swap	d6
				clr.w	d2
				clr.w	d6						; d6=xbitpos
				divs.l	d4,d2
				move.l	d5,a5					; a5=dy constant
				move.l	d2,a6					; a6=xbitconst
				moveq	#0,d5
				move.b	3(a1),d5
				moveq	#0,d2
				move.b	7(a1),d2
				sub.w	d2,d5
				swap	d2
				swap	d5
				clr.w	d2						; d3=ybitpos
				clr.w	d5
				divs.l	d4,d5
				move.w	(a2,d1.w*2),d1
				move.w	(a2,d0.w*2),d0
				sub.w	d1,d0
				swap	d0
				swap	d1
				clr.w	d0
				clr.w	d1
				divs.l	d4,d0
				add.w	(a7)+,d4
				sub.w	draw_OffLeftBy_w(pc),d4
				blt		this_line_flat_gouraud

				tst.w	draw_OffLeftBy_w(pc)
				beq.s	.none_off_left

				move.w	d4,-(a7)
				move.w	draw_OffLeftBy_w(pc),d4
				dbra	d4,.calc_no_draw

				bra		.no_draw_off_left

.calc_no_draw:
				add.l	d0,d1
				add.l	a5,d3
				add.l	a6,d6
				add.l	d5,d2
				dbra	d4,.calc_no_draw

.no_draw_off_left:
				move.w	(a7)+,d4

.none_off_left:
.put_in_line:
				swap	d3
				move.w	d3,(a4)+
				swap	d3
				move.l	d6,(a4)+
				move.l	d2,(a4)+
				swap	d1
				move.w	d1,(a4)
				addq	#6,a4
				swap	d1
				add.l	d0,d1
				add.l	a5,d3
				add.l	a6,d6
				add.l	d5,d2
				dbra	d4,.put_in_line

				bra		this_line_flat_gouraud

this_line_on_top_gouraud:
				move.l	#PolyTopTab,a4
				cmp.w	draw_RightClipB_w,d2
				bge		this_line_flat_gouraud

				cmp.w	draw_LeftClipB_w,d4
				ble		this_line_flat_gouraud

				move.w	draw_RightClipB_w,d6
				sub.w	d4,d6
				ble.s	.clip_right

				move.w	#0,-(a7)
				cmp.w	draw_Right_w(pc),d4
				ble.s	.no_new_bottom

				move.w	d4,draw_Right_w
				bra.s	.no_new_bottom

.clip_right:
				move.w	d6,-(a7)
				move.w	draw_RightClipB_w,draw_Right_w
				sub.w	#1,draw_Right_w

.no_new_bottom:
				move.w	#0,draw_OffLeftBy_w
				move.w	d2,d6
				cmp.w	draw_LeftClipB_w,d6
				bge		.okt

				move.w	draw_LeftClipB_w,d6
				sub.w	d2,d6
				move.w	d6,draw_OffLeftBy_w
				add.w	d2,d6
.okt:
				st		drawit
				add.w	d6,d6
				lea		(a4,d6.w*8),a4
				asr.w	#1,d6
				cmp.w	draw_Left_w(pc),d6
				bge.s	.no_new_top

				move.w	d6,draw_Left_w

.no_new_top:
				sub.w	d3,d5					; dy
				swap	d3
				clr.w	d3						; d2=xpos
				sub.w	d2,d4					; dx > 0
				ext.l	d4
				swap	d5
				clr.w	d5
				divs.l	d4,d5
				moveq	#0,d2
				move.b	6(a1),d2
				moveq	#0,d6
				move.b	2(a1),d6
				sub.w	d6,d2
				swap	d2
				swap	d6
				clr.w	d2
				clr.w	d6						; d6=xbitpos
				divs.l	d4,d2
				move.l	d5,a5					; a5=dy constant
				move.l	d2,a6					; a6=xbitconst
				moveq	#0,d5
				move.b	7(a1),d5
				moveq	#0,d2
				move.b	3(a1),d2
				sub.w	d2,d5
				swap	d2
				swap	d5
				clr.w	d2						; d3=ybitpos
				clr.w	d5
				divs.l	d4,d5
				move.w	(a2,d1.w*2),d1
				move.w	(a2,d0.w*2),d0
				sub.w	d0,d1
				swap	d0
				swap	d1
				clr.w	d0
				clr.w	d1
				divs.l	d4,d1
				add.w	(a7)+,d4
				sub.w	draw_OffLeftBy_w(pc),d4
				blt.s	this_line_flat_gouraud

				tst.w	draw_OffLeftBy_w(pc)
				beq.s	.none_off_left

				move.w	d4,-(a7)
				move.w	draw_OffLeftBy_w(pc),d4

				dbra	d4,.calc_no_draw
				bra		.no_draw_off_left

.calc_no_draw:
				add.l	d1,d0
				add.l	a5,d3
				add.l	a6,d6
				add.l	d5,d2
				dbra	d4,.calc_no_draw

.no_draw_off_left:
				move.w	(a7)+,d4

.none_off_left:
.put_in_line:
				swap	d3
				move.w	d3,(a4)+
				swap	d3
				move.l	d6,(a4)+
				move.l	d2,(a4)+
				swap	d0
				move.w	d0,(a4)
				addq	#6,a4
				swap	d0
				add.l	d1,d0
				add.l	a5,d3
				add.l	a6,d6
				add.l	d5,d2
				dbra	d4,.put_in_line

this_line_flat_gouraud:
				addq	#4,a1
				dbra	d7,piglloop
				addq	#4,a1
				rts

draw_OffLeftBy_w:		ds.w	1
draw_Left_w:			ds.w	1
draw_Right_w:			ds.w	1

				section	bss,bss
				align 4
draw_PointAndPolyBrights_vl:	ds.l	4*16
draw_PointerTablePtr_l: 		ds.l	1
draw_StartOfObjPtr_l:			ds.l	1
Draw_PolyObjects_vl:			ds.l	40
draw_NumPoints_w:				ds.w	1

			; FIMXE: screenconv stores word sized points, why are they using ds.l here?
boxonscr:		ds.l	250*2					; projected 2D points in screenspace
boxrot:			ds.l	250*3					; rotated 3D points in X/Z plane (y pointing up)

boxbrights:		ds.w	250

boxang:			ds.w	1

				ds.w	SCREENWIDTH*4
PolyBotTab:		ds.w	SCREENWIDTH*8
				ds.w	SCREENWIDTH*4
PolyTopTab:		ds.w	SCREENWIDTH*8
				ds.w	SCREENWIDTH*4

;offset:
;				ds.w	1
;timer:
;				ds.w	1

Objects:		ds.l	38*4

TextureMaps:	ds.l	1
TexturePal:		ds.l	1

testval:		ds.l	1

				section	code,code
