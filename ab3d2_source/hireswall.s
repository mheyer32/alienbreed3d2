; todo - these can probably be BSS'd
				align 4

; Beware - these are unions of word|long. Do not separate!
Draw_LeftClip_l:		dc.w	0 ; long
Draw_LeftClip_w:		dc.w	0 ; lsw

; Beware - these are unions of word|long. Do not separate!
Draw_RightClip_l:		dc.w	0 ; long
Draw_RightClip_w:		dc.w	0 ; lsw

;Draw_DefTopClip_w:		dc.w	0 ; written, never read
;Draw_DefBottomClip_w:	dc.w	0 ; written, never read
Draw_LeftClipAndLast_w: dc.w	0

; Beware - these are unions of word|byte. Do not separate!
draw_StripData_w:		dc.b	0 ; word
draw_StripData_b:		dc.b    0 ; lsb

; TODO - this buffer is just a lookup table of y * SCREEN_WIDTH. It's probably faster to use mul #SCREEN_WIDTH on 060
				align 4
draw_LineOffsetBuffer_vl:
val				SET		0
				REPT	256
				dc.l	val
val				SET		val+SCREEN_WIDTH
				ENDR

				align 4
Draw_PointBrightsPtr_l: 		dc.l	0
draw_WallTextureHeightMask_w:	dc.w	0
draw_WallTextureHeightShift_w:	dc.w	0
draw_WallTextureWidthMask_w:	dc.w	0
Temp_SinVal_w:					dc.w	0 ; somewhat universal
Temp_CosVal_w:					dc.w	0 ; somewhat universal
draw_TopClip_w:					dc.w	0
draw_BottomClip_w:				dc.w	0
;wall_SeeThrough_b:				dc.w	0 ; bool - not used

				align 4
draw_TopOfWall_l:			dc.l	0
draw_BottomOfWall_l:		dc.l	0

draw_LBR_w:					dc.w	0 ; todo - define
draw_TLBR_w:				dc.w	0 ; todo - define
draw_LeftWallBright_w:		dc.w	0
draw_RightWallBright_w:		dc.w	0
draw_LeftWallTopBright_w:	dc.w	0
draw_RightWallTopBright_w:	dc.w	0
draw_StripTop_w:			dc.w	0
draw_StripBottom_w:			dc.w	0

;middleline:					dc.w	0 ; unused
draw_WallLastStripX_w:		dc.w	0

draw_FromTile_w:			dc.l	0 ; declared long, all but one accesses as word
draw_AngleBright_w:			dc.w	0

draw_WallIterations_w:		dc.w	0
draw_MultCount_w:			dc.w	0

Draw_GoodRender_b:			dc.w	$ff00 ; accessed as byte all over the code

SCALE			MACRO
				dc.w	64*0
				dc.w	64*1
				dc.w	64*1
				dc.w	64*2
				dc.w	64*2
				dc.w	64*3
				dc.w	64*3
				dc.w	64*4
				dc.w	64*4
				dc.w	64*5
				dc.w	64*5
				dc.w	64*6
				dc.w	64*6
				dc.w	64*7
				dc.w	64*7
				dc.w	64*8
				dc.w	64*8
				dc.w	64*9
				dc.w	64*9
				dc.w	64*10
				dc.w	64*10
				dc.w	64*11
				dc.w	64*11
				dc.w	64*12
				dc.w	64*12
				dc.w	64*13
				dc.w	64*13
				dc.w	64*14
				dc.w	64*14
				dc.w	64*15
				dc.w	64*15
				dc.w	64*16
				dc.w	64*16
				dc.w	64*17
				dc.w	64*17
				dc.w	64*18
				dc.w	64*18
				dc.w	64*19
				dc.w	64*19
				dc.w	64*20
				dc.w	64*20
				dc.w	64*21
				dc.w	64*21
				dc.w	64*22
				dc.w	64*22
				dc.w	64*23
				dc.w	64*23
				dc.w	64*24
				dc.w	64*24
				dc.w	64*25
				dc.w	64*25
				dc.w	64*26
				dc.w	64*26
				dc.w	64*27
				dc.w	64*27
				dc.w	64*28
				dc.w	64*28
				dc.w	64*29
				dc.w	64*29
				dc.w	64*30
				dc.w	64*30
				dc.w	64*31
				dc.w	64*31
				dc.w	64*31
				dc.w	64*31
				dc.w	64*31
				dc.w	64*31
				dc.w	64*31
				dc.w	64*31
				dc.w	64*31
				dc.w	64*31
				dc.w	64*31
				dc.w	64*31
				dc.w	64*31
				dc.w	64*31
				dc.w	64*31
				dc.w	64*31
				dc.w	64*31
				dc.w	64*31
				dc.w	64*31
				dc.w	64*31
				ENDM

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

; Just one copy of the iteration table. Should improve cache locality if nothing else.
				align 4
draw_IterationTable_vw:
				incbin	"includes/iterfile" ; todo - move to data, change access via a3?

				align 4
draw_BrightnessScaleTable_vw:
				SCALE

Doleftend:
				move.w	Draw_LeftClip_w,d0
				sub.w	#1,d0
				move.w	d0,Draw_LeftClipAndLast_w
				move.w	(a0),d0
				move.w	2(a0),d1
				sub.w	d0,d1
				bge.s	sometodraw
				rts

sometodraw:
				;move.w	draw_IterationTable_vw(pc,d1.w*4),d7
				;swap	d0
				;move.w	draw_IterationTable_vw+2(pc,d1.w*4),d6

				; read both words from the iteration table in one go. Do a small bit of juggling
				; of instruction order, may help on 060 (TBC)
				move.l	draw_IterationTable_vw(pc,d1.w*4),d7
				swap	d0
				move.w	d7,d6
				clr.w	d0
				swap	d1
				swap	d7
				clr.w	d1
				asr.l	d6,d1
				move.l	d1,(a0)

				moveq	#0,d1
				move.w	4(a0),d1
				moveq	#0,d2
				move.w	6(a0),d2
				sub.w	d1,d2
				swap	d1
				swap	d2
				asr.l	d6,d2
				move.l	d2,4(a0)

				moveq	#0,d2
				move.w	8(a0),d2
				moveq	#0,d3
				move.w	10(a0),d3
				sub.w	d2,d3
				swap	d2
				swap	d3
				asr.l	d6,d3
				move.l	d3,8(a0)

				moveq	#0,d3
				move.w	12(a0),d3
				moveq	#0,d4
				move.w	14(a0),d4
				sub.w	d3,d4
				swap	d3
				swap	d4
				asr.l	d6,d4
				move.l	d4,12(a0)

				moveq	#0,d4
				move.w	16(a0),d4
				moveq	#0,d5
				move.w	18(a0),d5
				sub.w	d4,d5
				swap	d4
				swap	d5
				asr.l	d6,d5
				move.l	d5,16(a0)

; *** Gouraud shading ***
				moveq	#0,d5
				move.w	26(a0),d5
				sub.w	24(a0),d5
				add.w	d5,d5
				swap	d5
				asr.l	d6,d5
				move.l	d5,28(a0)
				moveq	#0,d5
				move.w	24(a0),d5
				add.w	d5,d5
				swap	d5

				bra		screendivide

screendividethru:

.scrdrawlop:
				move.w	(a0)+,d0
				move.l	Vid_FastBufferPtr_l,a3
				move.l	(a0)+,d1

.pastscrinto:
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
				move.w	d2,d6

;***************************
;* old version
				asr.w	#7,d6

				add.w	draw_AngleBright_w(pc),d6
				bge.s	.br_not_negative
				moveq	#0,d6

.br_not_negative:
				cmp.w	#32,d6
				blt.s	.br_not_positive
				move.w	#32,d6

.br_not_positive:
				move.l	Draw_PalettePtr_l,a2
				move.l	a2,a4
				add.w	draw_BrightnessScaleTable_vw(pc,d6*2),a2

				move.w	d7,-(a7)
				bsr		ScreenWallstripdrawthru
				move.w	(a7)+,d7

				dbra	d7,.scrdrawlop
				rts

;***************************

screendivide:
				or.l	#$ffff0000,d7
				move.w	Draw_LeftClipAndLast_w(pc),d6
				move.l	#Sys_Workspace_vl,a2

				move.l	(a0),a3
				move.l	4(a0),a4
				move.l	8(a0),a5
				move.l	12(a0),a6
				move.l	16(a0),a1
				move.l	28(a0),a0

scrdivlop:
				swap	d0
				cmp.w	d6,d0
				bgt		scrnotoffleft
				swap	d0
				add.l	a4,d1
				add.l	a5,d2
				add.l	a6,d3
				add.l	a1,d4
				add.l	a3,d0
				add.l	a0,d5
				dbra	d7,scrdivlop
				rts

scrnotoffleft:
				move.w	d0,d6
				cmp.w	Draw_RightClip_w(pc),d0
				bge.s	outofcalc

scrnotoffright:
				move.w	d0,(a2)+
				move.l	d1,(a2)+
				move.l	d2,(a2)+
				move.l	d3,(a2)+
				move.l	d4,(a2)+
				move.l	d5,(a2)+
				swap	d0
				add.l	a3,d0
				add.l	a4,d1
				add.l	a5,d2
				add.l	a6,d3
				add.l	a1,d4
				add.l	a0,d5
				add.l	#$10000,d7
				dbra	d7,scrdivlop

outofcalc:
				swap	d7
				tst.w	d7
				bge.s	.something_to_draw
				rts

.something_to_draw:
				move.l	#ConstantTable_vl,a1
				move.l	#Sys_Workspace_vl,a0
				tst.b	Vid_FullScreen_b
				bne		screendivideFULL

; tst.b wall_SeeThrough_b
; bne screendividethru

				;tst.b	Vid_DoubleWidth_b
				;bne		scrdrawlopDOUB
				bra		scrdrawlop

thislinedone:
				add.w	#4+4+4+4+4,a0
				dbra	d7,scrdrawlop
				rts

scrdrawlop:
				move.w	(a0)+,d0

				cmp.w	draw_WallLastStripX_w,d0
				beq.s	thislinedone
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
				ext.w	d5
				add.w	d5,d6
				bge.s	.br_not_negative
				moveq	#0,d6

.br_not_negative:
				cmp.w	#64,d6
				blt.s	.br_not_positive
				move.w	#64,d6

.br_not_positive:
				move.l	Draw_PalettePtr_l,a2
				move.l	a2,a4
				add.w	draw_BrightnessScaleTable_vw(pc,d6*2),a2

				and.b	#$fe,d6
				add.w	draw_BrightnessScaleTable_vw(pc,d6*2),a4

				btst	#0,d0
				beq		.nobrightswap
				exg		a2,a4

.nobrightswap:
				move.w	d7,-(a7)
				bsr		ScreenWallstripdraw
				move.w	(a7)+,d7

toosmall:
				dbra	d7,scrdrawlop
				rts

thislineodd:
				add.w	#4+4+4+4+4,a0
				dbra	d7,scrdrawlopDOUB
				rts

scrdrawlopDOUB:
				move.w	(a0)+,d0
				btst	#0,d0
				bne.s	thislineodd

				cmp.w	draw_WallLastStripX_w,d0
				beq.s	thislineodd
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
				ext.w	d5
				add.w	d5,d6
				bge.s	.br_not_negative
				moveq	#0,d6

.br_not_negative:
				cmp.w	#64,d6
				blt.s	.br_not_positive
				move.w	#64,d6

.br_not_positive:
				move.l	Draw_PalettePtr_l,a2
				move.l	a2,a4
				add.w	draw_BrightnessScaleTable_vw(pc,d6*2),a2

				and.b	#$fe,d6
				add.w	draw_BrightnessScaleTable_vw(pc,d6*2),a4

				btst	#0,d0
				beq		.nobrightswap
				exg		a2,a4

.nobrightswap:
				move.w	d7,-(a7)
				bsr		ScreenWallstripdraw
				move.w	(a7)+,d7
				dbra	d7,scrdrawlopDOUB
				rts


screendivideFULL:
				tst.b	Vid_DoubleWidth_b
				bne		scrdrawlopFULLDOUB

scrdrawlopFULL:
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

***************************
* old version
				asr.w	#7,d6

				move.l	(a0)+,d5
				swap	d5
				ext.w	d5
				add.w	d5,d6
				bge.s	.br_not_negative
				moveq	#0,d6

.br_not_negative:
				cmp.w	#64,d6
				blt.s	.br_not_positive
				move.w	#64,d6

.br_not_positive:
				move.l	Draw_PalettePtr_l,a2
				move.l	a2,a4
				add.w	draw_BrightnessScaleTable_vw(pc,d6*2),a2

				and.b	#$fe,d6
				add.w	draw_BrightnessScaleTable_vw(pc,d6*2),a4

				btst	#0,d0
				beq		.nobrightswap
				exg		a2,a4

.nobrightswap:
				move.w	d7,-(a7)
				bsr		ScreenWallstripdrawBIG
				move.w	(a7)+,d7

				dbra	d7,scrdrawlopFULL
				rts

itsanoddone:
				add.w	#4+4+4+4+4,a0
				dbra	d7,scrdrawlopFULLDOUB
				rts

scrdrawlopFULLDOUB:
				move.w	(a0)+,d0
				btst	#0,d0
				bne.s	itsanoddone
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
				move.w	(a5),draw_StripData_w			;

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
				ext.w	d5
				add.w	d5,d6
				bge.s	.br_not_negative
				moveq	#0,d6

.br_not_negative:
				cmp.w	#64,d6
				blt.s	.br_not_positive
				move.w	#64,d6

.br_not_positive:
				move.l	Draw_PalettePtr_l,a2
				move.l	a2,a4
				add.w	draw_BrightnessScaleTable_vw(pc,d6*2),a2
				and.b	#$fe,d6
				add.w	draw_BrightnessScaleTable_vw(pc,d6*2),a4

				btst	#0,d0
				beq		.nobrightswap
				exg		a2,a4

.nobrightswap:
				move.w	d7,-(a7)
				bsr		ScreenWallstripdrawBIG
				move.w	(a7)+,d7
				dbra	d7,scrdrawlopFULLDOUB
				rts



* using a0=left pixel
* a2= right pixel
* d0= left height
* d2= right height
* d4 = left strip
* d5 = right strip

* Routine to draw a wall;
* pass it X and Z coords of the endpoints
* and the start and end length, and a number
* representing the number of the wall.

* a0=x1 d1=z1 a2=x2 d3=z2
* d4=sl d5=el
* a1 = strip buffer

********************************************************************************

;******************************************************************
;
;* Curve drawing routine. We have to know:
;* The top and bottom of the wall
;* The point defining the centre of the arc
;* the point defining the starting point of the arc
;* the start and end angles of the arc
;* The start and end positions along the bitmap of the arc
;* Which bitmap to use for the arc
;
;xmiddle:		dc.w	0
;zmiddle			SET		2
;				dc.w	0
;xradius			SET		4
;				dc.w	0
;zradius			SET		6
;				dc.w	0
;startbitmap		SET		8
;				dc.w	0
;bitmapcounter	SET		10
;				dc.w	0
;brightmult		SET		12
;				dc.w	0
;angadd			SET		14
;				dc.l	0
;xmiddlebig		SET		18
;				dc.l	0
;basebright		SET		22
;				dc.w	0
;shift			SET		24
;				dc.w	0
;count			SET		26
;				dc.w	0
;
;subdividevals:
;				dc.w	2,4
;				dc.w	3,8
;				dc.w	4,16
;				dc.w	5,32
;				dc.w	6,64
;
;CurveDraw:
;
;				move.w	(a0)+,d0				; centre of rotation
;				move.w	(a0)+,d1				; point on arc
;				move.l	#Rotated_vl,a1
;				move.l	#xmiddle,a2
;				move.l	(a1,d0.w*8),d2
;				move.l	d2,18(a2)
;				asr.l	#7,d2
;				move.l	(a1,d1.w*8),d4
;				asr.l	#7,d4
;				sub.w	d2,d4
;				move.w	d2,(a2)
;				move.w	d4,4(a2)
;				move.w	6(a1,d0.w*8),d2
;				move.w	6(a1,d1.w*8),d4
;				sub.w	d2,d4
;				move.w	d2,2(a2)
;				asr.w	#1,d4
;				move.w	d4,6(a2)
;				move.w	(a0)+,d4				; start of bitmap
;				move.w	(a0)+,d5				; end of bitmap
;				move.w	d4,8(a2)
;				sub.w	d4,d5
;				move.w	d5,10(a2)
;				move.w	(a0)+,d4
;				ext.l	d4
;				move.l	d4,14(a2)
;				move.w	(a0)+,d4
;				move.l	#subdividevals,a3
;				move.l	(a3,d4.w*4),shift(a2)
;
;				move.l	#Draw_WallTexturePtrs_vl,a3
;				add.l	(a0)+,a3
;				adda.w	draw_WallYOffset_w,a3
;				move.l	a3,draw_FromTile_w
;				move.w	(a0)+,basebright(a2)
;				move.w	(a0)+,brightmult(a2)
;				move.l	(a0)+,draw_TopOfWall_l
;				move.l	(a0)+,draw_BottomOfWall_l
;				move.l	yoff,d6
;				sub.l	d6,draw_TopOfWall_l
;				sub.l	d6,draw_BottomOfWall_l
;
;				move.l	#DataBuffer1_vl,a1
;				move.l	#SinCosTable_vw,a3
;				lea		2048(a3),a4
;				moveq	#0,d0
;				moveq	#0,d1
;				move.w	count(a2),d7
;DivideCurve
;				move.l	d0,d2
;				move.w	shift(a2),d4
;				asr.l	d4,d2
;				move.w	(a3,d2.w*2),d4
;				move.w	d4,d5
;				move.w	(a4,d2.w*2),d3
;				move.w	d3,d6
;				muls.w	4(a2),d3
;				muls.w	6(a2),d4
;				muls.w	4(a2),d5
;				muls.w	6(a2),d6
;				sub.l	d4,d3
;				add.l	d6,d5
;				asl.l	#2,d5
;				asr.l	#8,d3
;				add.l	18(a2),d3
;				swap	d5
;				move.w	basebright(a2),d6
;				move.w	brightmult(a2),d4
;				muls	d5,d4
;				swap	d4
;				add.w	d4,d6
;
;				add.w	2(a2),d5
;				move.l	d3,(a1)+
;				move.w	d5,(a1)+
;				move.w	d1,d2
;				move.w	shift(a2),d4
;				asr.w	d4,d2
;				add.w	8(a2),d2
;				move.w	d2,(a1)+
;				move.w	d6,(a1)+
;
;				add.l	14(a2),d0
;				add.w	10(a2),d1
;				dbra	d7,DivideCurve
;
;				move.l	a0,-(a7)
;
;; move.w #31,d6
;; move.l #0,d3
;; move.l #stripbuffer,a4
;;.emptylop:
;; move.l d3,(a4)+
;; dbra d6,.emptylop
;
;				bsr		curvecalc
;
;				move.l	(a7)+,a0
;
;				rts
;
;;prot3:			dc.w	0
;
;curvecalc:
;				move.l	#DataBuffer1_vl,a1
;				move.w	count(a2),d7
;				subq	#1,d7
;.find_first_in_front:
;				move.l	(a1)+,d1
;				move.w	(a1)+,d0
;				bgt.s	.found_in_front
;				move.w	(a1)+,d4
;				move.w	(a1)+,d6
;				dbra d7,.find_first_in_front
;; CACHE_ON d2
;				rts		;						no two points were in front
;
;.found_in_front:
;				move.w	(a1)+,d4
;				move.w	(a1)+,d6
;; d1=left x, d4=left end, d0=left dist
;; d6=left draw_AngleBright_w
;				divs	d0,d1
;
;				asr.w	d1					; Vid_DoubleWidth_b test
;
;				add.w	Vid_CentreX_w,d1
;
;				move.l	draw_TopOfWall_l(pc),d5
;				divs	d0,d5
;				add.w	Vid_CentreY_w,d5
;				move.w	d5,draw_StripTop_w
;				move.l	draw_BottomOfWall_l(pc),d5
;				divs	d0,d5
;				add.w	Vid_CentreY_w,d5
;				move.w	d5,draw_StripBottom_w
;
;; CACHE_OFF d2
;
;.compute_loop:
;				move.w	4(a1),d2
;				bgt.s	.in_front
;
;; addq #8,a1
;; dbra d7,.find_first_in_front
;
;; CACHE_ON d2
;				rts
;
;.in_front:
;				move.l	#Storage_vl,a0
;				move.l	(a1),d3
;				move.w	6(a1),d5
;				add.w	8(a1),d6
;				asr.w	#1,d6
;				move.w	d6,draw_AngleBright_w
;				divs	d2,d3
;
;				asr.w	d3					; Vid_DoubleWidth_b test
;
;				add.w	Vid_CentreX_w,d3
;				move.w	draw_StripTop_w(pc),12(a0)
;				move.w	draw_StripBottom_w(pc),16(a0)
;				move.l	draw_TopOfWall_l(pc),d6
;				divs	d2,d6
;				add.w	Vid_CentreY_w,d6
;				move.w	d6,draw_StripTop_w
;				move.w	d6,14(a0)
;				move.l	draw_BottomOfWall_l(pc),d6
;				divs	d2,d6
;				add.w	Vid_CentreY_w,d6
;				move.w	d6,draw_StripBottom_w
;				move.w	d6,18(a0)
;				move.w	d3,2(a1)
;				blt.s	.all_off_left
;				cmp.w	Vid_RightX_w,d1
;				bgt.s	.all_off_left
;
;				cmp.w	d1,d3
;				blt.s	.all_off_left
;
;				move.w	d1,(a0)
;				move.w	d3,2(a0)
;				move.w	d4,4(a0)
;				move.w	d5,6(a0)
;				move.w	d0,8(a0)
;				move.w	d2,10(a0)
;				move.w	d7,-(a7)
;				move.w	#maxscrdiv,d7
;				bsr		Doleftend
;				move.w	(a7)+,d7
;
;.all_off_left:
;
;				move.l	(a1)+,d1
;				move.w	(a1)+,d0
;				move.w	(a1)+,d4
;				move.w	(a1)+,d6
;
;				dbra	d7,.compute_loop
;
;.all_off_right:
;; CACHE_ON d2
;				rts
;

********************************************************************************
;protcheck:
; sub.l #53624,a3
; add.l #2345215,a2
; lea passspace-$30000(pc),a1
; add.l #$30000,a1
; lea startpass(pc),a5
; move.w #endpass-startpass-1,d1
;copypass:
; move.b (a5)+,(a1)+
; dbra d1,copypass
; sub.l a5,a5
; lea passspace-$30000(pc),a1
; add.l #$30000,a1
; jsr (a1)
; lea passspace-$30000(pc),a1
; add.l #$30000,a1
; lea startpass(pc),a5
; move.w #(endpass-startpass)/2-1,d1
;erasepass:
; move.w -(a5),(a1)+
; dbra d1,erasepass
; sub.l a5,a5
; sub.l a1,a1
; eor.l #$af594c72,d0
; sub.l #123453986,a4
; move.l d0,(a4)
; add.l #123453986,a4
; move.l #0,d0
; sub.l #2345215,a2
; jsr (a2)
; sub.l a2,a2
; eor.l #$af594c72,d0
; sub.l #123453986,a4
; move.l (a4),d1
; add.l #123453986,a4
; cmp.l d1,d0
; bne.s notrightt
; add.l #53624,a3
; move.w #9,d7
;sayitsok:
; move.l (a3)+,a2
; add.l #78935450,a2
; st (a2)
; dbra d7,sayitsok
;notrightt:
; sub.l a3,a3
;nullit:
; rts
;
; incbin "includes/protroutencoded"

endprot:


******************************************************************

; This routine renders a wall that has it's upper and lower brightnesses the same.
draw_WallFlatShaded:
				DEV_INC.w VisibleSimpleWalls

				move.w	d6,draw_WallIterations_w
				subq	#1,d7
				move.w	d7,draw_MultCount_w
				move.l	#DataBuffer1_vl,a3
				move.l	a0,d0
				move.l	a2,d2
				move.l	d0,(a3)+
				add.l	d2,d0
				move.w	d1,(a3)+
				asr.l	#1,d0
				move.w	d4,(a3)+
				move.w	draw_LeftWallBright_w,d6
				move.w	d6,(a3)+
				add.w	d5,d4
				move.l	d0,(a3)+
				add.w	d3,d1
				asr.w	#1,d1
				move.w	d1,(a3)+
				asr.w	#1,d4
				move.w	d4,(a3)+
				add.w	draw_RightWallBright_w,d6
				asr.w	#1,d6
				move.w	d6,(a3)+
				move.l	d2,(a3)+
				move.w	d3,(a3)+
				move.w	d5,(a3)+
				move.w	draw_RightWallBright_w,(a3)+

; We now have the two endpoints and the midpoint
; so we need to perform 1 iteration of the inner
; loop, the first time.

* Decide how often to subdivide by how far away the wall is, and
* how perp. it is to the player.

				move.l	#DataBuffer1_vl,a0
				move.l	#DataBuffer2_vl,a1

				move.w	draw_WallIterations_w,d6
				blt		.no_iterations
				move.l	#1,a2

.iteration_loop:
				move.l	a0,a3
				move.l	a1,a4
				move.w	a2,d7
				exg		a0,a1

				move.l	(a3)+,d0
				move.w	(a3)+,d1
				move.l	(a3)+,d2

.middle_loop:
				move.l	d0,(a4)+
				move.l	(a3)+,d3
				add.l	d3,d0
				move.w	d1,(a4)+
				asr.l	#1,d0
				move.w	(a3)+,d4
				add.w	d4,d1
				move.l	d2,(a4)+
				asr.w	#1,d1
				move.l	(a3)+,d5
				add.l	d5,d2
				move.l	d0,(a4)+
				asr.l	#1,d2
				move.w	d1,(a4)+
				move.l	d2,(a4)+

				move.l	d3,(a4)+
				move.l	(a3)+,d0
				add.l	d0,d3

				move.w	d4,(a4)+
				asr.l	#1,d3
				move.w	(a3)+,d1
				add.w	d1,d4
				move.l	d5,(a4)+
				asr.w	#1,d4
				move.l	(a3)+,d2
				add.l	d2,d5
				move.l	d3,(a4)+
				asr.l	#1,d5
				move.w	d4,(a4)+
				move.l	d5,(a4)+


				subq	#1,d7
				bgt.s	.middle_loop
				move.l	d0,(a4)+
				move.w	d1,(a4)+
				move.l	d2,(a4)+

				add.w	a2,a2

				dbra	d6,.iteration_loop

.no_iterations:
;someiters:

;CalcAndDraw:

; CACHE_ON d2

				move.l	a0,a1
				move.w	draw_MultCount_w,d7

.find_first_in_front:
				move.l	(a1)+,d1
				move.w	(a1)+,d0
				bgt.s	.found_in_front
				move.l	(a1)+,d4
				dbra	d7,.find_first_in_front
				rts		;	no two points were in front

.found_in_front:
				ext.l	d0

				move.w	(a1)+,d4
				move.w	(a1)+,draw_LBR_w
; d1=left x, d4=left end, d0=left dist

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
				bra		.all_off_left

.in_front:
				ext.l	d2
				move.l	#Storage_vl,a0
				move.l	(a1),d3
				divs.l	d2,d3
				moveq	#0,d5
				move.w	Vid_CentreX_w,d5
				add.l	d5,d3
				move.w	6(a1),d5
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
				move.l	COMPACTPTR,a0
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
				move.l	BIGPTR,a0

				move.w	draw_WallLeftPoint_w,(a0,d2.w*4)
				move.w	draw_WallRightPoint_w,2(a0,d2.w*4)

.no_put_in_map:
				movem.l	(a7)+,d0/d1/d2/d3/a0

				bra		OTHERHALF


.all_off_left:
				move.l	(a1)+,d1
				move.w	(a1)+,d0
				move.w	(a1)+,d4
				move.w	(a1)+,draw_LBR_w

				dbra	d7,.compute_loop
				rts

.all_off_right:
				rts

computeloop2:
				move.w	4(a1),d2
				bgt.s	.in_front
				bra		alloffleft2

.in_front:
				ext.l	d2
				move.l	#Storage_vl,a0
				move.l	(a1),d3
				divs.l	d2,d3
				moveq	#0,d5
				move.w	Vid_CentreX_w,d5
				add.l	d5,d3
				move.w	6(a1),d5
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
				blt.s	alloffleft2
				cmp.l	Draw_RightClip_l(pc),d1
; cmp.w #95,d1
				bge.s	alloffright2

OTHERHALF:
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
				move.w	8(a1),d5
				sub.w	#300,d5
				ext.w	d5
				move.w	d5,26(a0)

				movem.l	d7/a1,-(a7)
				move.w	#maxscrdiv,d7
				bsr		Doleftend
				movem.l	(a7)+,d7/a1

alloffleft2:
				move.l	(a1)+,d1
				move.w	(a1)+,d0
				move.w	(a1)+,d4
				move.w	(a1)+,draw_LBR_w

				dbra	d7,computeloop2

				rts

alloffright2:
				rts


***********************************

* Need a routine which takes...?
* Top Y (3d)
* Bottom Y (3d)
* distancedraw_TopOfWall_l
* height of each tile (number and routine addr)
* And produces the appropriate strip on the
* screen.


nostripq:
				rts

ScreenWallstripdraw:
				move.w	d4,d6
				cmp.w	draw_TopClip_w(pc),d6
				blt.s	nostripq
				cmp.w	draw_BottomClip_w(pc),d3
				bgt.s	nostripq

				cmp.w	draw_BottomClip_w(pc),d6
				ble.s	noclipbot
				move.w	draw_BottomClip_w(pc),d6

noclipbot:
				move.w	d3,d5
				cmp.w	draw_TopClip_w(pc),d5
				bge.s	nocliptop
				move.w	draw_TopClip_w(pc),d5
				btst	#0,d5
				beq.s	.nsbd
				exg		a2,a4
.nsbd:

				bra		gotoend

nocliptop:
				btst	#0,d5
				beq.s	.nsbd
				exg		a2,a4

.nsbd:
				bra		gotoend

;wlcnt:			dc.w	0 ; unused

				align 4
drawwalldimPACK0:
				and.w	d7,d4
				move.b	1(a5,d4.w*2),d1			; fetch texel
				and.b	#31,d1					; pull out right part
				add.l	d3,d4					; add fractional part?
				move.b	(a4,d1.w*2),(a3)
				adda.w	d0,a3					; next line in screen
				addx.w	d2,d4					; texture Y + dy
				dbra	d6,drawwallPACK0
				rts

				;CNOP	0,128
				align 4
drawwallPACK0:
				and.w	d7,d4
				move.b	1(a5,d4.w*2),d1
				and.b	#31,d1
				add.l	d3,d4
				move.b	(a2,d1.w*2),(a3)
				adda.w	d0,a3
				addx.w	d2,d4
				dbra	d6,drawwalldimPACK0

nostrip:
				rts

				align 4
drawwalldimPACK1:
				and.w	d7,d4
				move.w	(a5,d4.w*2),d1
				lsr.w	#5,d1
				and.w	#31,d1
				add.l	d3,d4
				move.b	(a4,d1.w*2),(a3)
				adda.w	d0,a3
				addx.w	d2,d4
				dbra	d6,drawwallPACK1
				rts

				align 4
drawwallPACK1:
				and.w	d7,d4
				move.w	(a5,d4.w*2),d1
				lsr.w	#5,d1
				and.w	#31,d1
				add.l	d3,d4
				move.b	(a2,d1.w*2),(a3)
				adda.w	d0,a3
				addx.w	d2,d4
				dbra	d6,drawwalldimPACK1

				rts

				align 4
drawwalldimPACK2:
				and.w	d7,d4
				move.b	(a5,d4.w*2),d1
				lsr.b	#2,d1
				add.l	d3,d4
				move.b	(a4,d1.w*2),(a3)
				adda.w	d0,a3
				addx.w	d2,d4
				dbra	d6,drawwallPACK2
				rts

				align 4
drawwallPACK2:
				and.w	d7,d4
				move.b	(a5,d4.w*2),d1
				lsr.b	#2,d1
				add.l	d3,d4
				move.b	(a2,d1.w*2),(a3)
				adda.w	d0,a3
				addx.w	d2,d4
				dbra	d6,drawwalldimPACK2
				rts

usesimple:
				mulu	d3,d4
				add.l	d0,d4
				swap	d4
				add.w	draw_TotalYOffset_w(pc),d4

cliptopusesimple:
				move.w	draw_WallTextureHeightMask_w,d7
				move.w	#SCREEN_WIDTH,d0
				moveq	#0,d1
				cmp.l	a4,a2
				blt.s	usea2
				move.l	a4,a2

usea2:
				and.w	d7,d4
				move.l	d2,d5
				clr.w	d5
				cmp.b	#1,draw_StripData_b
				dbge	d6,simplewalliPACK0
				dbne	d6,simplewalliPACK1
				dble	d6,simplewalliPACK2
				rts

				align 4
simplewalliPACK0:
				move.b	1(a5,d4.w*2),d1
				and.b	#31,d1
				move.b	(a2,d1.w*2),d3

simplewallPACK0:
				move.b	d3,(a3)
				adda.w	d0,a3
				add.l	d2,d4
				bcc.s	.noread
				addq	#1,d4
				and.w	d7,d4
				move.b	1(a5,d4.w*2),d1
				and.b	#31,d1
				move.b	(a2,d1.w*2),d3

.noread:
				dbra	d6,simplewallPACK0
				rts

				align 4
simplewalliPACK1:
				move.w	(a5,d4.w*2),d1
				lsr.w	#5,d1
				and.w	#31,d1
				move.b	(a2,d1.w*2),d3

simplewallPACK1:
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
				dbra	d6,simplewallPACK1
				rts

				align 4
simplewalliPACK2:
				move.b	(a5,d4.w*2),d1
				lsr.b	#2,d1
				and.b	#31,d1
				move.b	(a2,d1.w*2),d3

simplewallPACK2:
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
				dbra	d6,simplewallPACK2
				rts

; ATTENION: for some reason the order of these variables is important
; There's code that expects	these in the right order to allow for movem
				align	4
TOTHEMIDDLE:	dc.w	0
Vid_BottomY_w:	dc.w	0
Vid_CentreY_w:	dc.w	FS_HEIGHT/2
TOPOFFSET:		dc.w	0
BIGMIDDLEY:		dc.l	SCREEN_WIDTH*FS_HEIGHT/2
SMIDDLEY:		dc.w	FS_HEIGHT/2
STOPOFFSET:		dc.w	0
SBIGMIDDLEY:	dc.l	SCREEN_WIDTH*FS_HEIGHT/2		; renderbuffer offset to middle line

gotoend:
				tst.b	Vid_DoubleHeight_b
				bne		doubwall
				sub.w	d5,d6					; end-start; height to draw?
				ble		nostripq

				add.l	draw_LineOffsetBuffer_vl(pc,d5.w*4),a3 ; offset to render buffer line of the strip

				add.w	d2,d2

				move.l	4(a1,d2.w*8),d0			; fetch 4(a1) at d2*16
				add.w	TOPOFFSET(pc),d5
				move.w	d5,d4

				move.l	(a1,d2.w*4),d2			; fetch (a1) at d2*8

				ext.l	d5
				move.l	d2,d4
				muls.l	d5,d4
				add.l	d0,d4
				swap	d4

				add.w	draw_TotalYOffset_w(pc),d4		; start texel offset in strip
				move.w	draw_WallTextureHeightMask_w,d7
				and.w	d7,d4					; vertical texture coordinate clamp/wrap
				move.w	#SCREEN_WIDTH,d0			; line offset to next line
				moveq	#0,d1
				swap	d2						; fractional dt in upper word
				move.l	d2,d3
				clr.w	d3

				cmp.b	#1,draw_StripData_b			; depending on 0th, 1st or second column,
											; start at different routine, unpacking the correct
											; column from packed strip data
				dbge	d6,drawwallPACK0
				dbne	d6,drawwallPACK1
				dble	d6,drawwallPACK2
				rts

doubwall:
				moveq	#0,d0
				asr.w	#1,d5					; d5*2
				addx.w	d0,d5					; ??
				add.w	d5,d5					; d5 * 3
				sub.w	d5,d6
				asr.w	#1,d6
				ble		nostripq				; (d5*3-d6)/2

				add.l	draw_LineOffsetBuffer_vl(pc,d5.w*4),a3

				add.w	d2,d2

				move.l	4(a1,d2.w*8),d0
				add.w	TOPOFFSET(pc),d5
				move.w	d5,d4

				move.l	(a1,d2.w*4),d2

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
				swap	d2
				move.l	d2,d3
				clr.w	d3

				cmp.b	#1,draw_StripData_b
				dbge	d6,drawwallPACK0
				dbne	d6,drawwallPACK1
				dble	d6,drawwallPACK2
				rts

ScreenWallstripdrawBIG:
				move.w	d4,d6
				cmp.w	draw_TopClip_w(pc),d6
				blt		nostripq
				cmp.w	draw_BottomClip_w(pc),d3
				bgt		nostripq

				cmp.w	draw_BottomClip_w(pc),d6
				ble.s	.noclipbot
				move.w	draw_BottomClip_w(pc),d6

.noclipbot:
				move.w	d3,d5
				cmp.w	draw_TopClip_w(pc),d5
				bge.s	.nocliptop
				move.w	draw_TopClip_w(pc),d5
				btst	#0,d5
				beq.s	.nsbd
				exg		a2,a4

.nsbd:
				bra		gotoendBIG

.nocliptop:
				btst	#0,d5
				beq.s	.nsbd2
				exg		a2,a4
.nsbd2:

gotoendBIG:
				tst.b	Vid_DoubleHeight_b
				bne		doubwallBIG
				sub.w	d5,d6					; d6 = height to draw.
				ble		nostripq

				add.l	draw_LineOffsetBuffer_vl(pc,d5.w*4),a3 ;offset to start line in renderbuffer

				move.w	d2,d4
				add.w	d2,d2
				add.w	d2,d4					; d2*3

				move.l	4(a1,d4.w*8),d0			; d2*24
				add.w	TOPOFFSET(pc),d5
				move.w	d5,d4

				move.l	(a1,d2.w*4),d2

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
				swap	d2
				move.l	d2,d3
				clr.w	d3
				cmp.b	#1,draw_StripData_b
				dbge	d6,drawwallPACK0
				dbne	d6,drawwallPACK1
				dble	d6,drawwallPACK2
				rts

doubwallBIG:
				moveq	#0,d0
				asr.w	#1,d5
				addx.w	d0,d5
				add.w	d5,d5

				sub.w	d5,d6					; height to draw.
				asr.w	#1,d6
				ble		nostripq
				add.l	draw_LineOffsetBuffer_vl(pc,d5.w*4),a3

				move.w	d2,d4
				add.w	d2,d2
				add.w	d2,d4

				move.l	4(a1,d4.w*8),d0
				add.w	TOPOFFSET(pc),d5
				move.w	d5,d4

				move.l	(a1,d2.w*4),d2

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
				swap	d2
				move.l	d2,d3
				clr.w	d3
				cmp.b	#1,draw_StripData_b
				dbge	d6,drawwallPACK0
				dbne	d6,drawwallPACK1
				dble	d6,drawwallPACK2
				rts

nostripqthru:
				rts

ScreenWallstripdrawthru:
				move.w	d4,d6
				cmp.w	draw_TopClip_w(pc),d6
				blt.s	nostripqthru
				cmp.w	draw_BottomClip_w(pc),d3
				bgt.s	nostripqthru
				cmp.w	draw_BottomClip_w(pc),d6
				ble.s	.noclipbot
				move.w	draw_BottomClip_w(pc),d6

.noclipbot:
				move.w	d3,d5
				cmp.w	draw_TopClip_w(pc),d5
				bge.s	.nocliptop
				move.w	draw_TopClip_w(pc),d5
				btst	#0,d5
				beq.s	.nsbd
				exg		a2,a4

.nsbd:
				sub.w	d5,d6					; height to draw.
				ble.s	nostripqthru
				bra		gotoendthru

.nocliptop:
				btst	#0,d5
				beq.s	.nsbdthru
				exg		a2,a4

.nsbdthru:
				sub.w	d5,d6					; height to draw.
				ble.s	nostripqthru
				bra		gotoendthru

				align 4
drawwalldimthruPACK0:
				and.w	d7,d4
				move.b	1(a5,d4.w*2),d1
				and.b	#31,d1
				beq.s	.holey
				move.w	(a4,d1.w*2),(a3)

.holey:
				adda.w	d0,a3
				add.l	d3,d4
				addx.w	d2,d4
				dbra	d6,drawwallthruPACK0
				rts

				align 4
drawwallthruPACK0:
				and.w	d7,d4
				move.b	1(a5,d4.w*2),d1
				and.b	#31,d1
				beq.s	.holey
				move.w	(a2,d1.w*2),(a3)
.holey:
				adda.w	d0,a3
				add.l	d3,d4
				addx.w	d2,d4
				dbra	d6,drawwalldimthruPACK0
nostripthru:
				rts

				align 4
drawwalldimthruPACK1:
				and.w	d7,d4
				move.w	(a5,d4.w*2),d1
				lsr.w	#5,d1
				and.w	#31,d1
				beq.s	.holey
				move.w	(a4,d1.w*2),(a3)
.holey:
				adda.w	d0,a3
				add.l	d3,d4
				addx.w	d2,d4
				dbra	d6,drawwallthruPACK1
				rts

				align 4
drawwallthruPACK1:
				and.w	d7,d4
				move.w	(a5,d4.w*2),d1
				lsr.w	#5,d1
				and.w	#31,d1
				beq.s	.holey
				move.w	(a2,d1.w*2),(a3)
.holey:
				adda.w	d0,a3
				add.l	d3,d4
				addx.w	d2,d4
				dbra	d6,drawwalldimthruPACK1
				rts

				align 4
drawwalldimthruPACK2:
				and.w	d7,d4
				move.b	(a5,d4.w*2),d1
				lsr.b	#2,d1
				and.b	#31,d1
				beq.s	.holey
				move.w	(a4,d1.w*2),(a3)
.holey:
				adda.w	d0,a3
				add.l	d3,d4
				addx.w	d2,d4
				dbra	d6,drawwallthruPACK2
				rts

				align 4
drawwallthruPACK2:
				and.w	d7,d4
				move.b	(a5,d4.w*2),d1
				lsr.b	#2,d1
				and.b	#31,d1
				beq.s	.holey
				move.w	(a2,d1.w*2),(a3)
.holey:
				adda.w	d0,a3
				add.l	d3,d4
				addx.w	d2,d4
				dbra	d6,drawwalldimthruPACK2
				rts

usesimplethru:
				mulu	d3,d4
				add.l	d0,d4
				swap	d4
				add.w	draw_TotalYOffset_w(pc),d4

cliptopusesimplethru:
				moveq	#63,d7
				move.w	#104*4,d0
				moveq	#0,d1
				cmp.l	a4,a2
				blt.s	usea2thru
				move.l	a4,a2
usea2thru:
				and.w	d7,d4
				move.l	d2,d5
				clr.w	d5

				cmp.b	#1,draw_StripData_b
				dbge	d6,simplewallthruiPACK0
				dbne	d6,simplewallthruiPACK1
				dble	d6,simplewallthruiPACK2
				rts

				align 4
simplewallthruiPACK0:
				move.b	1(a5,d4.w*2),d1
				and.b	#31,d1
				move.w	(a2,d1.w*2),d3

simplewallthruPACK0:
				move.w	d3,(a3)
				adda.w	d0,a3
				add.l	d5,d4
				bcc.s	noreadthruPACK0

maybeholePACK0:
				addx.w	d2,d4
				and.w	d7,d4
				move.b	1(a5,d4.w*2),d1
				and.b	#31,d1
				beq.s	holeysimplePACK0
				move.w	(a2,d1.w*2),d3
				dbra	d6,simplewallthruPACK0
				rts

noreadthruPACK0:
				addx.w	d2,d4
				dbra	d6,simplewallthruPACK0
				rts

				align 4
simplewallholePACK0:
				adda.w	d0,a3
				add.l	d5,d4
				bcs.s	maybeholePACK0
				addx.w	d2,d4

holeysimplePACK0:
				and.w	d7,d4
				dbra	d6,simplewallholePACK0
				rts

				align 4
simplewallthruiPACK1:
				move.w	(a5,d4.w*2),d1
				lsr.w	#5,d1
				and.w	#31,d1
				move.w	(a2,d1.w*2),d3

simplewallthruPACK1:
				move.w	d3,(a3)
				adda.w	d0,a3
				add.l	d5,d4
				bcc.s	noreadthruPACK1

maybeholePACK1:
				addx.w	d2,d4
				and.w	d7,d4
				move.w	(a5,d4.w*2),d1
				lsr.w	#5,d1
				and.w	#31,d1
				beq.s	holeysimplePACK1
				move.w	(a2,d1.w*2),d3
				dbra	d6,simplewallthruPACK1
				rts

noreadthruPACK1:
				addx.w	d2,d4
				dbra	d6,simplewallthruPACK1
				rts

				align 4
simplewallholePACK1:
				adda.w	d0,a3
				add.l	d5,d4
				bcs.s	maybeholePACK1
				addx.w	d5,d4

holeysimplePACK1:
				and.w	d7,d4
				dbra	d6,simplewallholePACK1
				rts

				align 4
simplewallthruiPACK2:
				move.b	(a5,d4.w*2),d1
				lsr.b	#2,d1
				and.b	#31,d1
				move.w	(a2,d1.w*2),d3

simplewallthruPACK2:
				move.w	d3,(a3)
				adda.w	d0,a3
				add.l	d5,d4
				bcc.s	noreadthruPACK2

maybeholePACK2:
				addx.w	d2,d4
				and.w	d7,d4
				move.b	(a5,d4.w*2),d1
				lsr.b	#2,d1
				and.b	#31,d1
				beq.s	holeysimplePACK2
				move.w	(a2,d1.w*2),d3
				dbra	d6,simplewallthruPACK2
				rts

noreadthruPACK2:
				addx.w	d2,d4
				dbra	d6,simplewallthruPACK2
				rts

				align 4
simplewallholePACK2:
				adda.w	d0,a3
				add.l	d5,d4
				bcs.s	maybeholePACK2
				addx.w	d2,d4

holeysimplePACK2:
				and.w	d7,d4
				dbra	d6,simplewallholePACK2
				rts


gotoendthru:
				add.l	draw_TimesLargeThru_vl(pc,d5.w*4),a3
				move.w	d5,d4
				move.l	4(a1,d2.w*8),d0
				move.l	(a1,d2.w*8),d2
				moveq	#0,d3
				move.w	d2,d3
				swap	d2
				tst.w	d2
				bne.s	.notsimple
				cmp.l	#$b000,d3
				ble		usesimplethru

.notsimple:
				mulu	d3,d4
				muls	d2,d5
				add.l	d0,d4
				swap	d4
				add.w	d5,d4
				add.w	draw_WallYOffset_w(pc),d4

cliptopthru
				moveq	#63,d7
				move.w	#104*4,d0
				moveq	#0,d1
				move.l	d2,d3
				clr.w	d3
				cmp.b	#1,draw_StripData_b
				dbge	d6,drawwallthruPACK0
				dbne	d6,drawwallthruPACK1
				dble	d6,drawwallthruPACK2

				rts

				align 4
draw_TimesLargeThru_vl:
val				SET		104*4
				REPT	80
				dc.l	val
val				SET		val+104*4
				ENDR

draw_TotalYOffset_w:		dc.w	0
draw_WallYOffset_w:		dc.w	0

******************************************
* Wall polygon
;draw_WallLeftEnd_w:		dc.w	0 ; always set to zero
draw_WallBrightOffset_w:	dc.w	0
draw_WallLeftPoint_w:		dc.w	0
draw_WallRightPoint_w:		dc.w	0
draw_WhichPBR_w:			dc.w	0 ; accessed as byte (PBR = point brightness?)
draw_WhichLeftPoint_w:		dc.w	0 ; written as byte. Can be changed?
draw_WhichRightPoint_w:		dc.w	0 ; written as byte. Can be changed?
draw_OtherZone_w:			dc.w	0 ; written as byte. Can be changed?

				; Is this THE wall draw entrypoint?
				; a0 pointing to wall description?
Draw_Wall:
				move.l	#Rotated_vl,a5
				move.l	#OnScreen_vl,a6

				move.w	(a0)+,d0				; left point index
				move.w	(a0)+,d2				; right point index

				move.w	d0,draw_WallLeftPoint_w
				move.w	d2,draw_WallRightPoint_w

				move.b	(a0)+,draw_WhichLeftPoint_w+1		; mhhm?!
				move.b	(a0)+,draw_WhichRightPoint_w+1	; mhhm??

				;move.w	#0,draw_WallLeftEnd_w
				moveq	#0,d5
				move.w	(a0)+,d5
				move.w	(a0)+,d1
				asl.w	#4,d1
				move.w	d1,draw_FromTile_w

				move.w	(a0)+,d1
				move.w	d1,draw_TotalYOffset_w

				move.w	(a0)+,d1
				move.l	#Draw_WallTexturePtrs_vl,a3
				move.l	(a3,d1.w*4),a3
				move.l	a3,Draw_PalettePtr_l
				add.l	#64*32,a3
				move.l	a3,Draw_ChunkPtr_l

;move.w (a0)+,d1
;add.w Zone_Bright_w,d1
				move.w	Zone_Bright_w,draw_AngleBright_w
;move.w (a0)+,d1
;move.w (a0)+,d4
				move.l	yoff,d6

				moveq	#0,d1
				move.b	(a0)+,d1
				move.w	d1,draw_WallTextureHeightMask_w		; (vertical) wall texture height mask
				moveq	#0,d1
				move.b	(a0)+,d1
				move.w	d1,draw_WallTextureHeightShift_w	; (vertical) wall texture height shift
				moveq	#0,d1
				move.b	(a0)+,d1							; texture width
				move.w	d1,draw_WallTextureWidthMask_w		; horizontal texture width mask?
				move.b	(a0)+,draw_WhichPBR_w
				move.w	draw_TotalYOffset_w,d1
				add.w	draw_WallYOffset_w,d1
				and.w	draw_WallTextureHeightMask_w,d1
				move.w	d1,draw_TotalYOffset_w
				move.l	(a0)+,draw_TopOfWall_l
				sub.l	d6,draw_TopOfWall_l
				move.l	(a0)+,draw_BottomOfWall_l
				sub.l	d6,draw_BottomOfWall_l

				move.b	(a0)+,d3
				ext.w	d3
				move.w	d3,draw_WallBrightOffset_w
				move.b	(a0)+,draw_OtherZone_w+1

				move.l	draw_TopOfWall_l,d3
				cmp.l	draw_BottomOfWall_l,d3
				bge		wallfacingaway

				tst.w	6(a5,d0*8)
				bgt.s	cantell
				tst.w	6(a5,d2*8)
				ble		wallfacingaway
				bra		cliptotestfirstbehind

cantell:
				tst.w	6(a5,d2*8)
				ble.s	cliptotestsecbehind
				bra		pastclip

cliptotestfirstbehind:
				;	a5 Rotated_vl
				move.l	(a5,d0*8),d3			; prerotated points,
				sub.l	(a5,d2*8),d3			; line dx, integer part ?
				move.w	6(a5,d0*8),d6
				sub.w	6(a5,d2*8),d6			; line dy, fractional part?
				ext.l	d6
				divs.l	d6,d3					; dx/dy

				move.w	6(a5,d2.w*8),d6			; FIXME: why fetch a second time?
				ext.l	d6
				muls.l	d6,d3
				neg.l	d3
				add.l	(a5,d2*8),d3

				move.l	(a5,d2*8),d6
				move.w	6(a5,d2*8),d4
				ext.l	d4
				divs.l	d4,d6

; move.w Vid_CentreX_w,d4
; ext.l d4
; sub.l d4,d6

; move.w (a6,d2*2),d6
; sub.w Vid_CentreX_w,d6
; ext.l d6
				cmp.l	d6,d3
				bge		wallfacingaway
				bra		cant_tell
				bra		pastclip

cliptotestsecbehind:
				move.l	(a5,d2*8),d3
				sub.l	(a5,d0*8),d3
				move.w	6(a5,d2*8),d6
				sub.w	6(a5,d0*8),d6
				ext.l	d6
				divs.l	d6,d3
				move.w	6(a5,d0.w*8),d6
				ext.l	d6
				muls.l	d6,d3
				neg.l	d3
				add.l	(a5,d0*8),d3

; move.w (a6,d0*2),d6
; sub.w Vid_CentreX_w,d6
; ext.l d6

				move.l	(a5,d0*8),d6
				move.w	6(a5,d0*8),d4
				ext.l	d4
				divs.l	d4,d6

; move.w Vid_CentreX_w,d4
; ext.l d4
; sub.l d4,d6

				cmp.l	d6,d3
				ble		wallfacingaway
				bra		cant_tell

pastclip:
				move.l	(a5,d0*8),d3
				move.w	6(a5,d0*8),d4
				ext.l	d4
				divs.l	d4,d3
				move.w	Vid_CentreX_w,d4
				ext.l	d4
				add.l	d4,d3

				move.l	(a5,d2*8),d6
				move.w	6(a5,d2*8),d4
				ext.l	d4
				divs.l	d4,d6
				move.w	Vid_CentreX_w,d4
				ext.l	d4
				add.l	d4,d6

				move.w	Vid_RightX_w,d4
				ext.l	d4
				cmp.l	d4,d3
				bge		wallfacingaway
				cmp.l	d6,d3
				bge		wallfacingaway
				tst.l	d6
				blt		wallfacingaway

cant_tell:

				movem.l	d7/a0/a5/a6,-(a7)
				move.l	(a5,d0*8),a0
; add.l a0,a0
				move.w	6(a5,d0*8),d1
				move.l	(a5,d2*8),a2
; add.l a2,a2
				move.w	6(a5,d2*8),d3

				move.l	#CurrentPointBrights_vl,a5
				tst.b	Draw_DoUpper_b
				beq.s	.notupper
				add.w	#4,a5

.notupper:
				move.w	Draw_CurrentZone_w,d0
				move.b	draw_WhichPBR_w,d4
				btst	#3,d4
				beq.s	.nototherzone
				move.w	draw_OtherZone_w,d0

.nototherzone:
				and.w	#7,d4
				muls	#40,d0
				add.w	d0,d4

				move.w	draw_WhichLeftPoint_w,d0
				asl.w	#2,d0
				add.w	d4,d0

				move.w	(a5,d0.w*2),d0
				bge.s	.okpos1
				neg.w	d0

.okpos1:
				add.w	draw_WallBrightOffset_w,d0
				move.w	d0,draw_LeftWallBright_w

				move.w	draw_WhichRightPoint_w,d0
				asl.w	#2,d0
				add.w	d4,d0
				move.w	(a5,d0.w*2),d0
				bge.s	.okpos2
				neg.w	d0

.okpos2:
				add.w	draw_WallBrightOffset_w,d0
				move.w	d0,draw_RightWallBright_w

				move.w	Draw_CurrentZone_w,d0
				move.b	draw_WhichPBR_w,d4
				lsr.w	#4,d4
				btst	#3,d4
				beq.s	.nototherzone2
				move.w	draw_OtherZone_w,d0

.nototherzone2:
				and.w	#7,d4
				muls	#40,d0
				add.w	d0,d4

				move.w	draw_WhichLeftPoint_w,d0
				asl.w	#2,d0
				add.w	d4,d0

				move.w	(a5,d0.w*2),d0
				bge.s	.okpos3
				neg.w	d0

.okpos3:
				add.w	draw_WallBrightOffset_w,d0
				move.w	d0,draw_LeftWallTopBright_w

				move.w	draw_WhichRightPoint_w,d0
				asl.w	#2,d0
				add.w	d4,d0
				move.w	(a5,d0.w*2),d0
				bge.s	.okpos4
				neg.w	d0

.okpos4:
				add.w	draw_WallBrightOffset_w,d0
				move.w	d0,draw_RightWallTopBright_w

				;move.w	draw_WallLeftEnd_w(pc),d4
				move.w	#0,d4
				move.l	#max3ddiv,d7

				move.w	#-1,draw_WallLastStripX_w

				; 0xABADCAFE - refactored from draw_WallFlatShaded and draw_WallGouraudShaded
.test_one_in_front:
				tst.w	d1
				bgt.s	.one_in_front
				tst.w	d3
				bgt.s	.one_in_front
				bra		.function_done

.one_in_front:
				move.w	#16,d7
				move.w	#2,d6
				tst.b	Draw_GoodRender_b
				beq.s	.not_good

				move.w	#64,d7
				move.w	#4,d6
				bra		.is_good

.not_good:
				move.l	a2,d0
				sub.l	a0,d0
				bge.s	.okpos

				neg.l	d0

.okpos:
				cmp.l	#256*128,d0
				blt.s	.is_good

				add.w	d7,d7
				addq	#1,d6
				cmp.l	#512*128,d0
				blt.s	.is_good

				add.w	d7,d7
				addq	#1,d6

.is_good:
				move.w	d3,d0
				sub.w	d1,d0
				bge.s	.not_negative_z_difference

				neg.w	d0

.not_negative_z_difference:
				cmp.w	#512,d0
				blt.s	.nd0

				tst.b	Draw_GoodRender_b
				beq.s	.nd0

				add.w	d7,d7
				add.w	#1,d6
				bra		.nha

.nd0:
				cmp.w	#256,d0
				bgt.s	.nh1
				asr.w	#1,d7
				subq	#1,d6

.nh1:
				cmp.w	#128,d0
				bgt.s	.nh2
				asr.w	#1,d7
				subq	#1,d6

.nh2:
.nha:
				move.w	d3,d0
				cmp.w	d1,d3
				blt.s	.right_nearest

				move.w	d1,d0

.right_nearest:
				cmp.w	#32,d0
				bgt.s	.ndd0

				addq	#1,d6
				add.w	d7,d7

.ndd0:
				cmp.w	#64,d0
				bgt.s	.nd1

				addq	#1,d6
				add.w	d7,d7

.nd1:
				cmp.w	#128,d0
				blt.s	.nh3

				asr.w	#1,d7
				subq	#1,d6
				blt.s	.nh4

				cmp.w	#256,d0
				blt.s	.nh3

				asr.w	#1,d7
				subq	#1,d6
				blt.s	.nh4

.nh3:
				cmp.w	#512,d0
				blt.s	.nh4

				asr.w	#1,d7
				subq	#1,d6

.nh4:
				cmp.w	#128,d7
				ble.s	.choose_renderer

				move.w	#128,d7
				move.w	#5,d6

.choose_renderer:
				; Now determine which renderer to use
				; Compare the corner brightnesses

				; 0xABADCAFE
				; Today I Learned: Non-Gouraud walls are not flat shaded. The have the same
				; horizontal-only shading that the original Alien Breed 3D had. Therefore to
				; the original code was correct. We just change the access order here.
				move.w	draw_LeftWallBright_w,d0
				cmp.w	draw_LeftWallTopBright_w,d0
				bne.s	.do_shaded
				move.w	draw_RightWallBright_w,d0
				cmp.w	draw_RightWallTopBright_w,d0
				bne.s	.do_shaded

.do_flat:
				DEV_CHECK	SIMPLE_WALLS,.function_done
				bsr			draw_WallFlatShaded
				bra.s		.function_done

.do_shaded:
				DEV_CHECK	SHADED_WALLS,.function_done
				bsr			draw_WallGouraudShaded

.function_done:
				movem.l	(a7)+,d7/a0/a5/a6

wallfacingaway:
				rts

