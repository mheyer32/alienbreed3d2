
				align 4
draw_GouraudStep_l:		dc.l	0
draw_GouraudStart_l:	dc.l	0


***********************************

* The screendivide routine is simpler
* using a0=left pixel
* a2= right pixel
* d0= left dist
* d2= right dist
* d4 = left strip
* d5 = right strip

* (a0)=leftx
* 2(a0)=rightx

* 4(a0)=leftbm
* 6(a0)=rightbm

* 8(a0)=leftdist
* 10(a0)=rightdist

* 12(a0)=lefttop
* 14(a0)=righttop

* 16(a0)=leftbot
* 18(a0)=rightbot


DoleftendGOUR:
				move.w	Draw_LeftClip_w,d0
				sub.w	#1,d0
				move.w	d0,Draw_LeftClipAndLast_w
				move.w	(a0),d0					; leftx
				move.w	2(a0),d1				; rightx
				sub.w	d0,d1					; width
				bge.s	.some_to_draw

				rts

				;  struct{short 2^n-1,n;} draw_IterationTable_vw[]
.some_to_draw:
				; I think, this determines how oblique a wall is to the viewer.
				; The thinner a wall, the less precise the iterations need to be.
				; The iterations are bound by the next power-of-two number covering the whole width
				; FIXME: this is another place where the maximum resolution is hardcoded into the
				; size of draw_IterationTable_vw

				;move.w	draw_IterationTable_vw(pc,d1.w*4),d7	; how many iterations for this width; or is it a mask?
				;swap	d0
				;move.w	draw_IterationTable_vw+2(pc,d1.w*4),d6 ; shift for this width

				; read both words from the iteration table in one go. Do a small bit of juggling
				; of instruction order, may help on 060 (TBC)
				move.l	draw_IterationTable_vw(pc,d1.w*4),d7
				swap	d0
				move.w	d7,d6
				clr.w	d0						; leftx in high word
				swap	d1
				swap	d7
				clr.w	d1						; width in high word
				asr.l	d6,d1					; divide down by shift
				move.l	d1,(a0)					; save

				; Reading input walls from a0 and writing calculated deltas back into a0
				moveq	#0,d1
				move.w	4(a0),d1				; leftbm
				moveq	#0,d2
				move.w	6(a0),d2				; rightbm
				sub.w	d1,d2					; dBm = (rightbm -leftbm)
				swap	d1						; leftbm in high word
				swap	d2						;
				asr.l	d6,d2					; dBM >> widthShift
				move.l	d2,4(a0)				; store dBM in 4(a0)

				moveq	#0,d2
				move.w	8(a0),d2				; leftdist
				moveq	#0,d3
				move.w	10(a0),d3				; rightdist
				sub.w	d2,d3					; dDist = rightdist - leftfist
				swap	d2						; d2 = leftdist << 16
				swap	d3
				asr.l	d6,d3					; (dDist << 16)  >> widthShift
				move.l	d3,8(a0)				; store dDist in 8(a0)

				moveq	#0,d3					; lefttop
				move.w	12(a0),d3
				moveq	#0,d4
				move.w	14(a0),d4				; righttop
				sub.w	d3,d4					; dTop = (rightTop - leftTop)
				swap	d3						; lefttop in high word
				swap	d4						;
				asr.l	d6,d4					; (dTop << 16) >> widthShift
				move.l	d4,12(a0)				; dTop in 12(a0)

				moveq	#0,d4					; left bottom
				move.w	16(a0),d4
				moveq	#0,d5
				move.w	18(a0),d5				; right bottom
				sub.w	d4,d5					; dBot = rightbot-leftbot
				swap	d4						; leftbot << 16
				swap	d5
				asr.l	d6,d5					; (dBot << 16) >> widthShift
				move.l	d5,16(a0)

; *** Gouraud shading ***
				moveq	#0,d5
				move.w	26(a0),d5
				sub.w	24(a0),d5
				add.w	d5,d5
				swap	d5
				asr.l	d6,d5
				move.l	d5,28(a0)				; Deltas for lighting values?

				moveq	#0,d5
				move.w	24(a0),d5
				add.w	d5,d5
				swap	d5
				move.l	d5,24(a0)				; 24(a0) << 17

; *** Extra Gouraud Shading ***
				moveq	#0,d5
				move.w	34(a0),d5
				sub.w	32(a0),d5
				add.w	d5,d5
				swap	d5
				asr.l	d6,d5
				move.l	d5,36(a0)				; Deltas for lighting values?

				moveq	#0,d5
				move.w	32(a0),d5
				add.w	d5,d5
				swap	d5
				move.l	d5,32(a0)				; 32(a0) << 17

				; Is this preparing the strips to draw?
				or.l	#$ffff0000,d7			; high word for number of iterations/iterations mask
				move.w	Draw_LeftClipAndLast_w(pc),d6	; left clip minus 1
				move.l	#Sys_Workspace_vl,a2

				move.l	(a0),a3					; (Width<<16)>>widthShift
				move.l	4(a0),a4				; dBM
				move.l	8(a0),a5				; dDist
				move.l	12(a0),a6				; dTop
				move.l	16(a0),a1				; dBottom

				;iterate through strips until we get past Draw_LeftClip_w
				; I think, Draw_LeftClip_w is a continuously updated x coordinate that
				; denotes "undrawn" space on screen to prevent partially covered walls
				; from overwriting walls in front

.scr_divide_loop:
				swap	d0
				cmp.w	d6,d0
				bgt		.scr_not_off_left

				swap	d0

				; forward-differencing of positions and texture coordinates
				add.l	a4,d1
				add.l	a5,d2
				add.l	a6,d3
				add.l	a1,d4
				add.l	a3,d0

				; forward differencing vertex color shading?!
				move.l	28(a0),d5
				add.l	d5,24(a0)
				move.l	36(a0),d5
				add.l	d5,32(a0)

				dbra	d7,.scr_divide_loop
				rts

.scr_not_off_left:
				move.w	d0,d6		; This continuuously moves the 'Draw_LeftClip_w' out by one pixel
									; So we always only produce new strips at integer x coordinates

				cmp.w	Draw_RightClip_w(pc),d0
				bge.s	.out_of_calc

;.scr_not_off_right:
				; store current left strip data
				move.w	d0,(a2)+
				move.l	d1,(a2)+
				move.l	d2,(a2)+
				move.l	d3,(a2)+
				move.l	d4,(a2)+
				move.l	24(a0),(a2)+			; this is immediately overwriting workspace area
				move.l	32(a0),(a2)+			; but I guess the writing is trailing the reading

				; iterate further
				swap	d0
				add.l	a3,d0
				add.l	a4,d1
				add.l	a5,d2
				add.l	a6,d3
				add.l	a1,d4
				move.l	28(a0),d5
				add.l	d5,24(a0)
				move.l	36(a0),d5
				add.l	d5,32(a0)
				add.l	#$10000,d7
				dbra	d7,.scr_divide_loop

.out_of_calc:
				swap	d7
				tst.w	d7
				bge.s	.something_to_draw

				rts

.something_to_draw:
				move.l	#ConstantTable_vl,a1
				move.l	#Sys_Workspace_vl,a0

; tst.b wall_SeeThrough_b
; bne screendividethru

				tst.b	Vid_FullScreen_b
				bne		scrdrawlopGB

;				tst.b	Vid_DoubleWidth_b
;				bne		scrdrawlopGDOUB
				bra		.scr_draw_loop

.this_line_done:
				add.w	#4+4+4+4+4+4,a0
				dbra	d7,.scr_draw_loop

				rts

.scr_draw_loop:
				move.w	(a0)+,d0				; start fetching the next strip, x-coord
				cmp.w	draw_WallLastStripX_w,d0
				beq.s	.this_line_done

				move.w	d0,draw_WallLastStripX_w
				move.l	Vid_FastBufferPtr_l,a3
				lea		(a3,d0.w),a3			; point to start address of screen column
				move.l	(a0)+,d1
				swap	d1
				move.w	d1,d6
				and.w	draw_WallTextureWidthMask_w,d6				; wrap texture coordinate
				move.l	(a0)+,d2
				swap	d2
				add.w	draw_FromTile_w(pc),d6			;
				add.w	d6,d6
				move.w	d6,a5					; "Word-size source operands are signextended to 32-bit quantities."
				move.l	(a0)+,d3
				swap	d3
				add.l	#DivThreeTable_vb,a5
				move.w	(a5),draw_StripData_w			; d6*2/3
				move.l	Draw_ChunkPtr_l,a5
				moveq	#0,d6
				move.b	draw_StripData_w,d6			; (d6*2/3)
				add.w	d6,d6					; d6 * 4/3
				move.w	draw_WallTextureHeightShift_w,d4				;
				asl.l	d4,d6					; * wall texture height(?)
				add.l	d6,a5					; start of wall strip
				move.l	(a0)+,d4
				swap	d4
				addq	#1,d4
				move.w	d2,d6

;***************************
;* old version
				asr.w	#7,d6

				move.l	(a0)+,d5
				swap	d5
				move.w	d7,-(a7)
				ext.w	d5
				move.w	d6,d7
				add.w	d5,d7
				bge.s	.br_not_negative

				moveq	#0,d7

.br_not_negative:
				cmp.w	#62,d7
				blt.s	.br_not_positive

				move.w	#62,d7

.br_not_positive:
				move.l	(a0)+,d5
				swap	d5
				ext.w	d5
				add.w	d5,d6
				bge.s	.br_not_negative_2

				moveq	#0,d6

.br_not_negative_2:
				cmp.w	#62,d6
				blt.s	.br_not_positive_2

				move.w	#62,d6

.br_not_positive_2:
				asr.w	#1,d6
				asr.w	#1,d7
				sub.w	d6,d7
				move.l	Draw_PalettePtr_l,a4
				bsr		ScreenWallstripdrawGOUR

				move.w	(a7)+,d7

.too_small:
				dbra	d7,.scr_draw_loop

				rts

itsoddy:
				add.w	#4+4+4+4+4+4,a0
				dbra	d7,scrdrawlopGDOUB
				rts

scrdrawlopGDOUB:
				move.w	(a0)+,d0
				btst	#0,d0
				bne.s	itsoddy

				cmp.w	draw_WallLastStripX_w,d0
				beq.s	itsoddy

				move.w	d0,draw_WallLastStripX_w
				move.l	Vid_FastBufferPtr_l,a3
				lea		(a3,d0.w),a3
				move.l	(a0)+,d1
				swap	d1
				move.w	d1,d6
				and.w	draw_WallTextureWidthMask_w,d6
				move.l	(a0)+,d2
				swap	d2
				add.w	draw_FromTile_w(pc),d6
				add.w	d6,d6
				move.w	d6,a5
				move.l	(a0)+,d3
				swap	d3
				add.l	#DivThreeTable_vb,a5
				move.w	(a5),draw_StripData_w
				move.l	Draw_ChunkPtr_l,a5
				moveq	#0,d6
				move.b	draw_StripData_w,d6
				add.w	d6,d6
				move.w	draw_WallTextureHeightShift_w,d4
				asl.l	d4,d6
				add.l	d6,a5
				move.l	(a0)+,d4
				swap	d4
				addq	#1,d4
				move.w	d2,d6
;***************************
;* old version
				asr.w	#7,d6

				move.l	(a0)+,d5
				swap	d5
				move.w	d7,-(a7)				; save
				ext.w	d5
				move.w	d6,d7
				add.w	d5,d7
				bge.s	.br_not_negative

				moveq	#0,d7

.br_not_negative:
				cmp.w	#62,d7
				blt.s	.br_not_positive

				move.w	#62,d7

.br_not_positive:
				move.l	(a0)+,d5
				swap	d5
				ext.w	d5
				add.w	d5,d6
				bge.s	.br_not_negative_2

				moveq	#0,d6

.br_not_negative_2:
				cmp.w	#62,d6
				blt.s	.br_not_positive_2
				move.w	#62,d6

.br_not_positive_2:
				asr.w	#1,d6
				asr.w	#1,d7
				sub.w	d6,d7
				move.l	Draw_PalettePtr_l,a4
				bsr		ScreenWallstripdrawGOUR

				move.w	(a7)+,d7				; restore

				dbra	d7,scrdrawlopGDOUB

				rts

scrdrawlopGB:
				move.w	(a0)+,d0
				move.l	Vid_FastBufferPtr_l,a3
				lea		(a3,d0.w),a3
				move.l	(a0)+,d1
				swap	d1
				move.w	d1,d6
				and.w	draw_WallTextureWidthMask_w,d6
				move.l	(a0)+,d2
				swap	d2
				add.w	draw_FromTile_w(pc),d6
				add.w	d6,d6
				move.w	d6,a5
				move.l	(a0)+,d3
				swap	d3
				add.l	#DivThreeTable_vb,a5
				move.w	(a5),draw_StripData_w

				move.l	Draw_ChunkPtr_l,a5
				moveq	#0,d6
				move.b	draw_StripData_w,d6
				add.w	d6,d6
				move.w	draw_WallTextureHeightShift_w,d4
				asl.l	d4,d6
				add.l	d6,a5
				move.l	(a0)+,d4
				swap	d4
				addq	#1,d4
				move.w	d2,d6

;***************************
;* old version
				asr.w	#7,d6

				move.l	(a0)+,d5
				swap	d5
				move.w	d7,-(a7)
				ext.w	d5
				move.w	d6,d7
				add.w	d5,d7
				bge.s	.br_not_negative

				moveq	#0,d7
.br_not_negative:
				cmp.w	#62,d7
				blt.s	.br_not_positive
				move.w	#62,d7

.br_not_positive:
				move.l	(a0)+,d5
				swap	d5
				ext.w	d5
				add.w	d5,d6
				bge.s	.br_not_negative_2

				moveq	#0,d6

.br_not_negative_2:
				cmp.w	#62,d6
				blt.s	.br_not_positive_2

				move.w	#62,d6

.br_not_positive_2:
				asr.w	#1,d6
				asr.w	#1,d7
				sub.w	d6,d7
				move.l	Draw_PalettePtr_l,a4
				bsr		ScreenWallstripdrawGOURB

				move.w	(a7)+,d7
				dbra	d7,scrdrawlopGB

				rts

itsbilloddy: ; lol!
				add.w	#4+4+4+4+4+4,a0
				dbra	d7,scrdrawlopGDOUB

				rts

scrdrawlopGBDOUB:
				move.w	(a0)+,d0
				btst	#0,d0
				bne.s	itsbilloddy

				move.l	Vid_FastBufferPtr_l,a3
				lea		(a3,d0.w),a3
				move.l	(a0)+,d1
				swap	d1
				move.w	d1,d6
				and.w	draw_WallTextureWidthMask_w,d6
				move.l	(a0)+,d2
				swap	d2
				add.w	draw_FromTile_w(pc),d6			; ptr to floor tile
				add.w	d6,d6
				move.w	d6,a5
				move.l	(a0)+,d3
				swap	d3
				add.l	#DivThreeTable_vb,a5
				move.w	(a5),draw_StripData_w
				move.l	Draw_ChunkPtr_l,a5
				moveq	#0,d6
				move.b	draw_StripData_w,d6
				add.w	d6,d6
				move.w	draw_WallTextureHeightShift_w,d4
				asl.l	d4,d6
				add.l	d6,a5
				move.l	(a0)+,d4
				swap	d4
				addq	#1,d4
				move.w	d2,d6

;***************************
;* old version
				asr.w	#7,d6

				move.l	(a0)+,d5
				swap	d5
				move.w	d7,-(a7)
				ext.w	d5
				move.w	d6,d7
				add.w	d5,d7
				bge.s	.br_not_negative

				moveq	#0,d7

.br_not_negative:
				cmp.w	#62,d7
				blt.s	.br_not_positive

				move.w	#62,d7

.br_not_positive:
				move.l	(a0)+,d5
				swap	d5
				ext.w	d5
				add.w	d5,d6
				bge.s	.br_not_negative_2

				moveq	#0,d6

.br_not_negative_2:
				cmp.w	#62,d6
				blt.s	.br_not_positive_2

				move.w	#62,d6

.br_not_positive_2:
				asr.w	#1,d6
				asr.w	#1,d7
				sub.w	d6,d7
				move.l	Draw_PalettePtr_l,a4
				bsr		ScreenWallstripdrawGOURB

				move.w	(a7)+,d7
				dbra	d7,scrdrawlopGBDOUB

				rts

; This routine draws the wall when any of the corner brightnesses differ
draw_WallGouraudShaded:
				DEV_INC.w VisibleShadedWalls

				move.w	d6,draw_WallIterations_w
				subq	#1,d7
				move.w	d7,draw_MultCount_w
				move.l	#DataBuffer1_vl,a3
				move.l	a0,d0
				move.l	a2,d2
				move.l	d0,(a3)+
				add.l	d2,d0
				move.w	d1,(a3)+
				move.w	draw_LeftWallTopBright_w,d7
				move.w	d7,(a3)+
				asr.l	#1,d0
				move.w	d4,(a3)+
				move.w	draw_LeftWallBright_w,d6
				move.w	d6,(a3)+
				add.w	d5,d4
				move.l	d0,(a3)+
				add.w	d3,d1
				asr.w	#1,d1
				move.w	d1,(a3)+
				add.w	draw_RightWallTopBright_w,d7
				asr.w	#1,d7
				move.w	d7,(a3)+
				asr.w	#1,d4
				move.w	d4,(a3)+
				add.w	draw_RightWallBright_w,d6
				asr.w	#1,d6
				move.w	d6,(a3)+
				move.l	d2,(a3)+
				move.w	d3,(a3)+
				move.w	draw_RightWallTopBright_w,(a3)+
				move.w	d5,(a3)+
				move.w	draw_RightWallBright_w,(a3)+

; We now have the two endpoints and the midpoint
; so we need to perform 1 iteration of the inner
; loop, the first time.

* Decide how often to subdivide by how far away the wall is, and
* how perp. it is to the player.

				move.l	#DataBuffer1_vl,a0
				move.l	#DataBuffer2_vl,a1
				swap	d7
				move.w	draw_WallIterations_w,d7
				blt		.no_iterations

				move.l	#1,a2

.iteration_loop:
				move.l	a0,a3
				move.l	a1,a4
				swap	d7
				move.w	a2,d7
				exg		a0,a1
				move.l	(a3)+,d0
				move.l	(a3)+,d1
				move.l	(a3)+,d2

.middle_loop:
				move.l	d0,(a4)+
				move.l	(a3)+,d3
				add.l	d3,d0
				move.l	d1,(a4)+
				asr.l	#1,d0
				move.l	(a3)+,d4
				add.l	d4,d1
				move.l	d2,(a4)+
				asr.l	#1,d1
				and.w	#$7fff,d1
				move.l	(a3)+,d5
				add.l	d5,d2
				move.l	d0,(a4)+
				asr.l	#1,d2
				move.l	d1,(a4)+
				move.l	d2,(a4)+
				move.l	d3,(a4)+
				move.l	(a3)+,d0
				add.l	d0,d3
				move.l	d4,(a4)+
				asr.l	#1,d3
				move.l	(a3)+,d1
				add.l	d1,d4
				move.l	d5,(a4)+
				asr.l	#1,d4
				and.w	#$7fff,d4
				move.l	(a3)+,d2
				add.l	d2,d5
				move.l	d3,(a4)+
				asr.l	#1,d5
				move.l	d4,(a4)+
				move.l	d5,(a4)+
				subq	#1,d7
				bgt.s	.middle_loop

				move.l	d0,(a4)+
				move.l	d1,(a4)+
				move.l	d2,(a4)+
				add.w	a2,a2
				swap	d7
				dbra	d7,.iteration_loop

.no_iterations:
;CalcAndDrawG:

; CACHE_ON d2

				move.l	a0,a1
				move.w	draw_MultCount_w,d7

.find_first_in_front:
				move.l	(a1)+,d1
				move.w	(a1)+,d0
				bgt.s	.found_in_front

				move.l	(a1)+,d4
				move.w	(a1)+,d4
				dbra	d7,.find_first_in_front

				rts		;	no two points were in front

.found_in_front:
				move.w	(a1)+,draw_TLBR_w
				move.w	(a1)+,d4
				move.w	(a1)+,draw_LBR_w

; d1=left x, d4=left end, d0=left dist

				ext.l	d0
				divs.l	d0,d1

				moveq	#0,d5
				move.w	Vid_CentreX_w,d5
				add.l	d5,d1
				move.l	draw_TopOfWall_l(pc),d5
				divs	d0,d5
				add.w	Vid_CentreY_w,d5
				move.w	d5,draw_StripTop_w
				move.l	draw_BottomOfWall_l(pc),d5
				divs	d0,d5
				add.w	Vid_CentreY_w,d5
				move.w	d5,draw_StripBottom_w

.compute_loop:
				move.w	4(a1),d2
				bgt.s	.in_front

				rts

.in_front:
				move.l	#Storage_vl,a0
				move.l	(a1),d3
				ext.l	d2
				divs.l	d2,d3
				moveq	#0,d5
				move.w	Vid_CentreX_w,d5
				add.l	d5,d3
				move.w	8(a1),d5
				move.w	draw_StripTop_w(pc),12(a0)
				move.l	draw_TopOfWall_l(pc),d6
				divs	d2,d6
				move.w	draw_StripBottom_w(pc),16(a0)
				add.w	Vid_CentreY_w,d6
				move.w	d6,draw_StripTop_w
				move.w	d6,14(a0)
				move.l	draw_BottomOfWall_l(pc),d6
				divs	d2,d6
				add.w	Vid_CentreY_w,d6
				move.w	d6,draw_StripBottom_w
				move.w	d6,18(a0)
				move.l	d3,(a1)
				cmp.l	Draw_LeftClip_l(pc),d3
				blt		.all_off_left

				cmp.l	Draw_RightClip_l(pc),d1
; cmp.w #95,d1
				bge		.all_off_right

				movem.l	d0/d1/d2/d3/a0,-(a7)
				moveq	#0,d0
				move.b	draw_WallID_w,d0
				blt.s	.no_put_in_map

				move.b	d0,d3
				and.b	#15,d0
				move.l	Lvl_CompactMapPtr_l,a0
				moveq	#0,d1
				move.w	d0,d2
				add.w	d0,d0
				add.w	d2,d0
				bset	d0,d1
				btst	#4,d3
				beq.s	.no_door
				addq	#2,d0
				bset	d0,d1

.no_door:
				or.l	d1,(a0)
				move.l	Lvl_BigMapPtr_l,a0
				move.w	draw_WallLeftPoint_w,(a0,d2.w*4)
				move.w	draw_WallRightPoint_w,2(a0,d2.w*4)

.no_put_in_map:
				movem.l	(a7)+,d0/d1/d2/d3/a0

				bra		OTHERHALFG

.all_off_left:
				move.l	(a1)+,d1
				move.w	(a1)+,d0
				move.w	(a1)+,draw_TLBR_w
				move.w	(a1)+,d4
				move.w	(a1)+,draw_LBR_w
				dbra	d7,.compute_loop

				rts

.all_off_right:
				rts

computeloop2G:
				move.w	4(a1),d2
				bgt.s	.in_front
				rts

.in_front:
				ext.l	d2
				move.l	#Storage_vl,a0
				move.l	(a1),d3
				divs.l	d2,d3					; this could be divs.w, no?
				moveq	#0,d5
				move.w	Vid_CentreX_w,d5
				add.l	d5,d3					; making this an add.w ?

				move.w	8(a1),d5
				move.w	draw_StripTop_w(pc),12(a0)
				move.l	draw_TopOfWall_l(pc),d6
				divs	d2,d6
				move.w	draw_StripBottom_w(pc),16(a0)
				add.w	Vid_CentreY_w,d6
				move.w	d6,draw_StripTop_w
				move.w	d6,14(a0)
				move.l	draw_BottomOfWall_l(pc),d6
				divs	d2,d6
				add.w	Vid_CentreY_w,d6
				move.w	d6,draw_StripBottom_w
				move.w	d6,18(a0)
				move.l	d3,(a1)
				cmp.w	Draw_LeftClip_w(pc),d3
				blt.s	alloffleft2G

				cmp.w	Draw_RightClip_w(pc),d1
; cmp.w #95,d1
				bge		alloffright2G

OTHERHALFG:
				move.w	d1,(a0)
				move.w	d3,2(a0)
				move.w	d4,4(a0)
				move.w	d5,6(a0)
				move.w	d0,8(a0)
				move.w	d2,10(a0)
				move.w	draw_LBR_w,d5
				sub.w	#300,d5
				ext.w	d5
				move.w	d5,24(a0)
				move.w	10(a1),d5
				sub.w	#300,d5
				ext.w	d5
				move.w	d5,26(a0)

				move.w	draw_TLBR_w,d5
				sub.w	#300,d5
				ext.w	d5
				move.w	d5,32(a0)
				move.w	6(a1),d5
				sub.w	#300,d5
				ext.w	d5
				move.w	d5,34(a0)
				movem.l	d7/a1,-(a7)
				move.w	#maxscrdiv,d7
				bsr		DoleftendGOUR

				movem.l	(a7)+,d7/a1

alloffleft2G:
				move.l	(a1)+,d1
				move.w	(a1)+,d0
				move.w	(a1)+,draw_TLBR_w
				move.w	(a1)+,d4
				move.w	(a1)+,draw_LBR_w

				dbra	d7,computeloop2G

				rts

alloffright2G:
				rts


;***********************************
;* Need a routine which takes...?
;* Top Y (3d)
;* Bottom Y (3d)
;* distance
;* height of each tile (number and routine addr)
;* And produces the appropriate strip on the
;* screen.


nostripqG:
				rts


ScreenWallstripdrawGOUR:
				swap	d6
				clr.w	d6
				move.l	d6,draw_GouraudStart_l
				swap	d7
				clr.w	d7
				move.w	d4,d6
				sub.w	d3,d6
				beq.s	nostripqG

				ext.l	d6
				divs.l	d6,d7					; speed through gouraud table.
				move.w	d4,d6
				cmp.w	draw_TopClip_w(pc),d6
				blt.s	nostripqG

				cmp.w	draw_BottomClip_w(pc),d3
				bgt.s	nostripqG

				cmp.w	draw_BottomClip_w(pc),d6
				ble.s	noclipbotG

				move.w	draw_BottomClip_w(pc),d6

noclipbotG:
				move.w	d3,d5
				cmp.w	draw_TopClip_w(pc),d5
				bge.s	nocliptopG

				sub.w	draw_TopClip_w(pc),d5
				neg.w	d5
				ext.l	d5
				move.l	d7,d0
				muls.l	d5,d0
				add.l	d0,draw_GouraudStart_l
				move.w	draw_TopClip_w(pc),d5


nocliptopG:
				bra		gotoendG


				ifd OPT060

drawwallg		macro

				movem.l a0/a1,-(sp) ; XXX can maybe be removed (a0 used for sure in outer loop)

				move.l  d0,a0
				move.l  d5,a1
				moveq   #16,d5

				; prepare d0/d2 for first iteration
				move.l  d4,d0
				move.l  d3,d2
				lsr.l   d5,d0
				lsr.l   d5,d2
				and.w   d7,d0
				and.w   #-32,d2

.loop:
				; extract packed texel (mod 1/2 could probably benefit from rescheduling)
				; 0aaaaabb bbbccccc
				ifeq \1-0
				moveq   #%00011111,d1
				and.b   1(a5,d0.l*2),d1    ; d1=texture[V]&31
				endc
				ifeq \1-1
				move.w  (a5,d0.l*2),d1
				lsr.w   #5,d1
				and.w   #31,d1
				endc
				ifeq \1-2
				moveq   #%01111100,d1
				and.b   (a5,d0.l*2),d1
				lsr.b   #2,d1
				endc

				add.w   d2,d1                   ; d1=(d2&~31)|(texture[V]&31)
				add.l   a2,d4                   ; v += dvdx

				add.l   a1,d3                   ; c += dcdx
				move.l  d4,d0                   ; d0=V<<16

				move.l  d3,d2                   ; d2=C<<16
				lsr.l   d5,d0                   ; d0=V

				and.w   d7,d0                   ; d0=V & draw_WallTextureHeightMask_w
				lsr.l   d5,d2                   ; d2=C

				move.b  (a4,d1.w*2),d1
				and.w   #-32,d2                 ; d2=C&~31

				move.b  d1,(a3)                 ; store pix
				add.w   a0,a3                   ; update dest

				subq.w  #1,d6                   ; loop
				bpl.b   .loop

				movem.l (sp)+,a0/a1 ; XXX can maybe be removed
				rts

				endm

drawwallPACK0G:	drawwallg 0
drawwallPACK1G:	drawwallg 1
drawwallPACK2G:	drawwallg 2

				else ; OPT060

				;CNOP	0,128

drawwallPACK0G:
				swap	d4
				and.w	d7,d4
				move.l	d3,d2
				swap	d2
				move.b	1(a5,d4.w*2),d1
				and.w	#%1111111111100000,d2
				swap	d4
				and.b	#31,d1
				add.w	d1,d2
				move.b	(a4,d2.w*2),(a3)
				adda.w	d0,a3
				add.l	d5,d3
				add.l	a2,d4
				dbra	d6,drawwallPACK0G

nostripG:
				rts


				align 4
drawwallPACK1G:
				swap	d4
				and.w	d7,d4
				move.l	d3,d2
				swap	d2
				move.w	(a5,d4.w*2),d1
				and.w	#%1111111111100000,d2
				swap	d4
				lsr.w	#5,d1
				and.w	#31,d1
				add.b	d1,d2
				move.b	(a4,d2.w*2),(a3)
				adda.w	d0,a3
				add.l	d5,d3
				add.l	a2,d4
				dbra	d6,drawwallPACK1G

				rts


				align 4
drawwallPACK2G:
				swap	d4
				and.w	d7,d4
				move.l	d3,d2
				swap	d2
				move.b	(a5,d4.w*2),d1
				and.w	#%1111111111100000,d2
				swap	d4
				lsr.b	#2,d1
				and.w	#31,d1
				add.b	d1,d2
				move.b	(a4,d2.w*2),(a3)
				adda.w	d0,a3
				add.l	d5,d3
				add.l	a2,d4
				dbra	d6,drawwallPACK2G

				rts

				endc ; OPT060


usesimpleG:
				mulu	d3,d4
				add.l	d0,d4
				swap	d4
				add.w	draw_TotalYOffset_w(pc),d4

cliptopusesimpleG:
				move.w	draw_WallTextureHeightMask_w,d7
				move.w	#SCREEN_WIDTH,d0
				moveq	#0,d1
				swap	d2
				move.l	d2,a2
				swap	d4
				move.l	draw_GouraudStep_l,d5
				asl.l	#5,d5
				move.l	draw_GouraudStart_l,d3
				asl.l	#5,d3
				cmp.b	#1,draw_StripData_b
				dbge	d6,simplewalliPACK0G

				dbne	d6,simplewalliPACK1G

				dble	d6,simplewalliPACK2G

				rts

				align 4
simplewalliPACK0G:
				swap	d4
				and.w	d7,d4
				move.l	d3,d2
				swap	d2
				move.b	1(a5,d4.w*2),d1
				and.w	#%1111111111100000,d2
				swap	d4
				and.b	#31,d1
				add.b	d1,d2
				move.b	(a2,d2.w*2),d3

simplewallPACK0G:
				move.b	d3,(a3)
				adda.w	d0,a3
				add.l	a2,d4
				bcc.s	.noread

				addq	#1,d4
				and.w	d7,d4
				move.b	1(a5,d4.w*2),d1
				and.b	#31,d1
				move.b	(a2,d1.w*2),d3

.noread:
				dbra	d6,simplewallPACK0G

				rts

				align 4
simplewalliPACK1G:
				swap	d4
				and.w	d7,d4
				move.l	d3,d2
				swap	d2
				move.w	(a5,d4.w*2),d1
				lsr.w	#5,d1
				and.w	#31,d1
				move.b	(a2,d1.w*2),d3

simplewallPACK1G:
				move.b	d3,(a3)
				adda.w	d0,a3
				add.l	d5,d4
				bcc.s	.noread

				addq	#1,d4
				and.w	d7,d4
				move.w	(a5,d4.w*2),d1
				lsr.w	#5,d1
				and.w	#31,d1
				move.b	(a2,d1.w*2),d3

.noread:
				dbra	d6,simplewallPACK1G

				rts

				align 4
simplewalliPACK2G:
				move.b	(a5,d4.w*2),d1
				lsr.b	#2,d1
				and.b	#31,d1
				move.b	(a2,d1.w*2),d3

simplewallPACK2G:
				move.b	d3,(a3)
				adda.w	d0,a3
				add.l	d5,d4
				bcc.s	.noread

				addq	#1,d4
				and.w	d7,d4
				move.b	(a5,d4.w*2),d1
				lsr.b	#2,d1
				move.b	(a2,d1.w*2),d3

.noread:
				dbra	d6,simplewallPACK2G

				rts

gotoendG:
				tst.b	Vid_DoubleHeight_b
				bne		doubwallGOUR

				sub.w	d5,d6					; height to draw.
				ble		nostripqG

				move.l	d7,draw_GouraudStep_l

				; start/endline in renderbuffer?
				add.l	draw_LineOffsetBuffer_vl(pc,d5.w*4),a3 ; contains renderbuffer offsets for each line

				add.w	d2,d2

				move.l	4(a1,d2.w*8),d0
				add.w	TOPOFFSET(pc),d5
				move.w	d5,d4

				move.l	(a1,d2.w*4),d2
				moveq	#0,d3

				ext.l	d5
				move.l	d2,d4
				muls.l	d5,d4

				add.l	d0,d4
				swap	d4

				add.w	draw_TotalYOffset_w(pc),d4

cliptopG:
				move.w	draw_WallTextureHeightMask_w,d7
				and.w	d7,d4
				move.w	#SCREEN_WIDTH,d0
				moveq	#0,d1
				move.l	d2,a2
				swap	d4
				move.l	draw_GouraudStep_l,d5
				asl.l	#5,d5
				move.l	draw_GouraudStart_l,d3
				asl.l	#5,d3
				cmp.b	#1,draw_StripData_b
				dbge	d6,drawwallPACK0G

				dbne	d6,drawwallPACK1G

				dble	d6,drawwallPACK2G

				rts


doubwallGOUR:
				moveq	#0,d0
				asr.w	#1,d5
				addx.w	d0,d5
				add.w	d5,d5
				sub.w	d5,d6					; height to draw.
				asr.w	#1,d6
				ble		nostripqG

				move.l	d7,draw_GouraudStep_l
				add.l	draw_LineOffsetBuffer_vl(pc,d5.w*4),a3
				add.w	d2,d2
				move.l	4(a1,d2.w*8),d0
				add.w	TOPOFFSET(pc),d5
				move.w	d5,d4
				move.l	(a1,d2.w*4),d2
				moveq	#0,d3
				ext.l	d5
				move.l	d2,d4
				muls.l	d5,d4
				add.l	d0,d4
				swap	d4
				add.w	draw_TotalYOffset_w(pc),d4
				move.w	draw_WallTextureHeightMask_w,d7
				and.w	d7,d4
				move.w	#640,d0
				moveq	#0,d1
				add.l	d2,d2
				move.l	d2,a2
				swap	d4
				move.l	draw_GouraudStep_l,d5
				asl.l	#6,d5
				move.l	draw_GouraudStart_l,d3
				asl.l	#5,d3
				cmp.b	#1,draw_StripData_b
				dbge	d6,drawwallPACK0G

				dbne	d6,drawwallPACK1G

				dble	d6,drawwallPACK2G

				rts

ScreenWallstripdrawGOURB:
				swap	d6
				clr.w	d6
				move.l	d6,draw_GouraudStart_l
				swap	d7
				clr.w	d7
				move.w	d4,d6
				sub.w	d3,d6
				beq		nostripqG

				ext.l	d6
				divs.l	d6,d7					; speed through gouraud table.
				move.w	d4,d6
				cmp.w	draw_TopClip_w(pc),d6
				blt		nostripqG

				cmp.w	draw_BottomClip_w(pc),d3
				bgt		nostripqG

				cmp.w	draw_BottomClip_w(pc),d6
				ble.s	noclipbotGb

				move.w	draw_BottomClip_w(pc),d6

noclipbotGb:
				move.w	d3,d5
				cmp.w	draw_TopClip_w(pc),d5
				bge.s	nocliptopGB

				sub.w	draw_TopClip_w(pc),d5
				neg.w	d5
				ext.l	d5
				move.l	d7,d0
				muls.l	d5,d0
				add.l	d0,draw_GouraudStart_l
				move.w	draw_TopClip_w(pc),d5

nocliptopGB:
gotoendGB:
				tst.b	Vid_DoubleHeight_b
				bne		doubwallGOURBIG

				sub.w	d5,d6					; height to draw.
				ble		nostripqG

				move.l	d7,draw_GouraudStep_l
				add.l	draw_LineOffsetBuffer_vl(pc,d5.w*4),a3 ; start of line in renderbuffer
				move.w	d2,d4
				add.w	d2,d2
				add.w	d2,d4
				move.l	4(a1,d4.w*8),d0
				add.w	TOPOFFSET(pc),d5
				move.w	d5,d4

				move.l	(a1,d2.w*4),d2
				moveq	#0,d3

				ext.l	d5
				move.l	d2,d4
				muls.l	d5,d4
				add.l	d0,d4
				swap	d4
				add.w	draw_TotalYOffset_w(pc),d4
				move.w	draw_WallTextureHeightMask_w,d7
				and.w	d7,d4
				move.w	#SCREEN_WIDTH,d0
				moveq	#0,d1
				move.l	d2,a2
				swap	d4
				move.l	draw_GouraudStep_l,d5
				asl.l	#5,d5
				move.l	draw_GouraudStart_l,d3
				asl.l	#5,d3
				cmp.b	#1,draw_StripData_b
				dbge	d6,drawwallPACK0G

				dbne	d6,drawwallPACK1G

				dble	d6,drawwallPACK2G
				rts

doubwallGOURBIG:
				moveq	#0,d0
				asr.w	#1,d5
				addx.w	d0,d5
				add.w	d5,d5
				sub.w	d5,d6					; height to draw.
				asr.w	#1,d6
				ble		nostripqG

				move.l	d7,draw_GouraudStep_l
				add.l	draw_LineOffsetBuffer_vl(pc,d5.w*4),a3
				move.w	d2,d4
				add.w	d2,d2
				add.w	d2,d4
				move.l	4(a1,d4.w*8),d0
				add.w	TOPOFFSET(pc),d5
				move.w	d5,d4
				move.l	(a1,d2.w*4),d2
				moveq	#0,d3
				ext.l	d5
				move.l	d2,d4
				muls.l	d5,d4
				add.l	d0,d4
				swap	d4
				add.w	draw_TotalYOffset_w(pc),d4
				move.w	draw_WallTextureHeightMask_w,d7
				and.w	d7,d4
				move.w	#640,d0
				moveq	#0,d1
				add.l	d2,d2
				move.l	d2,a2
				swap	d4
				move.l	draw_GouraudStep_l,d5
				asl.l	#6,d5
				move.l	draw_GouraudStart_l,d3
				asl.l	#5,d3
				cmp.b	#1,draw_StripData_b
				dbge	d6,drawwallPACK0G

				dbne	d6,drawwallPACK1G

				dble	d6,drawwallPACK2G

				rts

