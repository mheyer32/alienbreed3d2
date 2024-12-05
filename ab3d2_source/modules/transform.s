
; *****************************************************************************
; *
; * modules/transform.s
; *
; * Routines relating to coordinate transformation.
; *
; *****************************************************************************

RotateLevelPts:	;		Does this rotate ALL points in the level EVERY frame?

				tst.b	draw_RenderMap_b
				beq		xform_pvs_subset	; When REALMAP is on, we apparently need to transform all level points,
											; otherwise only the visible subset

				; Rotate all level points
				move.w	Vis_SinVal_w,d6
				swap	d6
				move.w	Vis_CosVal_w,d6

				move.l	Lvl_PointsPtr_l,a3
				move.l	#Rotated_vl,a1				; stores only 2x800 points
				move.l	#OnScreen_vl,a2
				move.w	Plr_XOff_l,d4
				;asr.w	#1,d4
				move.w	Plr_ZOff_l,d5
				;asr.w	#1,d5

; move.w #$c40,$dff106
; move.w #$f00,$dff180

				move.w	Lvl_NumPoints_w,d7
				tst.b	Vid_FullScreen_b
				bne		xform_all_fs

				; rotate all level points, small screen
pointrotlop2:
				move.w	(a3)+,d0
;*				asr.w	#1,d0
				sub.w	d4,d0
				move.w	d0,d2					; view X

				move.w	(a3)+,d1
;*				asr.w	#1,d1
				sub.w	d5,d1					; view Z

				muls	d6,d2					; x' = (cos*viewX)<<16
				swap	d6
				move.w	d1,d3
				muls	d6,d3					; z' = (sin*viewZ) << 16

				sub.l	d3,d2					; x' =  (cos*viewX - sin*viewZ) << 16

 ; add.l d2,d2
 ; swap d2
 ; ext.l d2
 ; asl.l #7,d2   ; (x'*2 >> 16) << 7 == x' << 8

				asr.l	#8,d2					; x' = int(2*x') << 8

				add.l	xwobble,d2
				move.l	d2,(a1)+				; store rotated x'

				muls	d6,d0
				swap	d6
				muls	d6,d1
				add.l	d0,d1

 ; asl.l #1,d1
 ; swap d1
 ; ext.l d1       ; (z' >> 16) * 2 == z' >> 15

				asr.l	#8,d1					;
				asr.l	#7,d1					; z' = int(z') * 2

				move.l	d1,(a1)+				; store rotated z'

				tst.l	d1
				bgt.s	ptnotbehind

				tst.l	d2
				bgt.s	onrightsomewhere

				move.w	#0,d2
				bra		store_point

onrightsomewhere:
				move.w	Vid_RightX_w,d2
				bra		store_point

ptnotbehind:
				divs.w	d1,d2					; x / z perspective projection
				add.w	Vid_CentreX_w,d2

store_point:
				move.w	d2,(a2)+				; store to OnScreen_vl

				dbra	d7,pointrotlop2

outofpointrot:
				rts


;BIGALL:
xform_all_fs:
pointrotlop2B:
				move.w	(a3)+,d0				; x
				sub.w	d4,d0					; x/2 - Plr_XOff_l
				move.w	d0,d2					; x = x/2 -Plr_XOff_l

				move.w	(a3)+,d1				; z
				sub.w	d5,d1					; z = z/2 - Plr_ZOff_l

				muls.w	d6,d2					; x*cos<<16
				swap	d6
				move.w	d1,d3
				muls.w	d6,d3					; z*sin<<16
				sub.l	d3,d2					; x' = (x * cos - z *sin)<<16
; add.l d2,d2
; swap d2
; ext.l d2
; asl.l #7,d2    ; integer part times 256

				asr.l	#8,d2

				add.l	xwobble,d2				; could the wobble be a shake or some underwater effect?
				move.l	d2,(a1)+				; store x'<<16

				muls	d6,d0					; x * sin<<16
				swap	d6
				muls	d6,d1					; z * cos <<16
				add.l	d0,d1					; z' = (x*sin + z*sin)<<16

				; 0xABADCAFE
				; Use 3/5 rather than 2/3 here for 320 wide - z' * 2 * 3/5 -> z' * 6/5
				; Shift d1 to get 2 extra input bits for our scale by 3/5 approximation
				lsl.l	#2,d1
				swap	d1
				muls	#1229,d1 ; 1229/2048 = 0.600097
				asr.l	#8,d1
				asr.l	#4,d1    ; z' * 6/5

				move.l	d1,(a1)+	; this stores the rotated points, but why does it factor in the scale factor
									; for the screen? Or is storing in view space with aspect ratio applied actually
									; convenient?
									; WOuld here a good opportunity to factor in Vid_DoubleWidth_b?

				tst.l	d1
				bgt.s	ptnotbehindB

				tst.l	d2
				bgt.s	onrightsomewhereB

				moveq.l	#0,d2
				bra		putinB

onrightsomewhereB:
				move.w	Vid_RightX_w,d2
				bra		putinB
ptnotbehindB:
				divs.w	d1,d2
				add.w	Vid_CentreX_w,d2
putinB:
				move.w	d2,(a2)+				; store fully projected X

				dbra	d7,pointrotlop2B
				rts


				; This only rotates a subset of the points, with indices pointed to at PointsToRotatePtr_l
;ONLYTHELONELY:
xform_pvs_subset:
				move.w	Vis_SinVal_w,d6
				swap	d6
				move.w	Vis_CosVal_w,d6

				move.l	PointsToRotatePtr_l,a0	; -1 terminated array of point indices to rotate
				move.l	Lvl_PointsPtr_l,a3
				move.l	#Rotated_vl,a1
				move.l	#OnScreen_vl,a2
				move.w	Plr_XOff_l,d4
				move.w	Plr_ZOff_l,d5

; move.w #$c40,$dff106
; move.w #$f00,$dff180

				tst.b	Vid_FullScreen_b
				bne		xform_pvs_subset_fs

.point_rotate_loop:
				move.w	(a0)+,d7
				blt		.check_vis_edge_points

				move.w	(a3,d7*4),d0
				sub.w	d4,d0
				move.w	d0,d2
				move.w	2(a3,d7*4),d1
				sub.w	d5,d1
				muls	d6,d2
				swap	d6
				move.w	d1,d3
				muls	d6,d3
				sub.l	d3,d2

;				add.l	d2,d2
;				swap	d2
;				ext.l	d2
;				asl.l	#7,d2

				asr.l	#8,d2					; x' = int(2*x') << 8
				add.l	xwobble,d2
				move.l	d2,(a1,d7*8)
				muls	d6,d0
				swap	d6
				muls	d6,d1
				add.l	d0,d1

;				asl.l #1,d1
;				swap d1
;				ext.l d1       ; (z' >> 16) * 2 == z' >> 15

				asr.l	#8,d1					;
				asr.l	#7,d1					; z' = int(z') * 2
				move.l	d1,4(a1,d7*8)
				;tst.w	d1 						; should this be tst.l ?
                tst.l	d1

				bgt.s	.ptnotbehind

                ;tst.w	d2

				tst.l	d2
				bgt.s	.onrightsomewhere

				move.w	#0,d2
				bra		.store_point

.onrightsomewhere:
				move.w	Vid_RightX_w,d2
				bra		.store_point

.ptnotbehind:
				divs	d1,d2
				add.w	Vid_CentreX_w,d2

.store_point:
				move.w	d2,(a2,d7*2)
				bra		.point_rotate_loop

; move.w #$c40,$dff106
; move.w #$ff0,$dff180

; Make sure we rotate the points of the shared edges, no matter what.
.check_vis_edge_points:
				cmp.w	#EDGE_POINT_ID_LIST_END,d7
				beq.s	.done

				; One more pass
				move.l	#Zone_EdgePointIndexes_vw,a0
				bra		.point_rotate_loop

.done:
				rts

xform_pvs_subset_fs:

;BIGLONELY:
.point_rotate_loop:
				move.w	(a0)+,d7
				blt.s	.check_vis_edge_points

				move.w	(a3,d7*4),d0
				sub.w	d4,d0
				move.w	d0,d2
				move.w	2(a3,d7*4),d1
				sub.w	d5,d1
				muls	d6,d2
				swap	d6
				move.w	d1,d3
				muls	d6,d3
				sub.l	d3,d2

;				add.l	d2,d2
;				swap	d2
;				ext.l	d2
;				asl.l	#7,d2

				asr.l	#8,d2					; x' = int(2*x') << 8
				add.l	xwobble,d2
				move.l	d2,(a1,d7*8)
				muls	d6,d0
				swap	d6
				muls	d6,d1
				add.l	d0,d1

				; 0xABADCAFE
				; Use 3/5 rather than 2/3 here for 320 wide - z' * 2 * 3/5 -> z' * 6/5
				; Shift d1 to get 2 extra input bits for our scale by 3/5 approximation
				lsl.l	#2,d1
				swap	d1
				muls	#1229,d1 ; 1229/2048 = 0.600097
				asr.l	#8,d1
				asr.l	#4,d1    ; z' * 6/5
				move.l	d1,4(a1,d7*8)
				;tst.w	d1
				tst.l	d1
				bgt.s	.ptnotbehind

				;tst.w	d2
				tst.l	d2
				bgt.s	.onrightsomewhere

				move.w	#0,d2
				bra		.store_point

.onrightsomewhere:
				move.w	Vid_RightX_w,d2
				bra		.store_point

.ptnotbehind:
				divs	d1,d2
				add.w	Vid_CentreX_w,d2

.store_point:
				move.w	d2,(a2,d7*2)	; this means the a2 array will also be sparsely written to,
										; but then again doesn't need reindeexing the input indices.
										; maybe it is worthwhile investigating if its possible to re-index
										; and write in a packed manner

				bra		.point_rotate_loop

; Make sure we rotate the points of the shared edges, no matter what.
.check_vis_edge_points:
				cmp.w	#EDGE_POINT_ID_LIST_END,d7
				beq.s	.done

				; One more pass
				move.l	#Zone_EdgePointIndexes_vw,a0
				bra		.point_rotate_loop

.done:
				rts

CalcPLR1InLine:
				move.w	Plr1_SinVal_w,d5
				move.w	Plr1_CosVal_w,d6
				move.l	Lvl_ObjectDataPtr_l,a4
				move.l	Lvl_ObjectPointsPtr_l,a0
				move.w	Lvl_NumObjectPoints_w,d7
				move.l	#Plr1_ObsInLine_vb,a2
				move.l	#Plr1_ObjectDistances_vw,a3

.objpointrotlop:

				cmp.b	#OBJ_TYPE_AUX,ObjT_TypeID_b(a4)
				beq.s	.itaux

				move.w	(a0),d0
				sub.w	Plr1_XOff_l,d0
				move.w	4(a0),d1
				addq	#8,a0

				tst.w	ObjT_ZoneID_w(a4)
				blt		.noworkout

				moveq	#0,d2
				move.b	ObjT_TypeID_b(a4),d2

				sub.w	Plr1_ZOff_l,d1
				move.w	d0,d2
				muls	d6,d2
				move.w	d1,d3
				muls	d5,d3
				sub.l	d3,d2
				add.l	d2,d2

				bgt.s	.okh
				neg.l	d2
.okh:
				swap	d2

				muls	d5,d0
				muls	d6,d1
				add.l	d0,d1
				asl.l	#2,d1
				swap	d1
				moveq	#0,d3

				tst.w	d1
				ble.s	.notinline
				asr.w	#1,d2
				cmp.w	#80,d2
				bgt.s	.notinline

				st		d3
.notinline:
				move.b	d3,(a2)+
				move.w	d1,(a3)+
				NEXT_OBJ	a4
				dbra	d7,.objpointrotlop

				rts

.itaux:
				NEXT_OBJ	a4
				bra		.objpointrotlop

.noworkout:
				move.b	#0,(a2)+
				move.w	#0,(a3)+
				NEXT_OBJ	a4
				dbra	d7,.objpointrotlop
				rts

CalcPLR2InLine:
				move.w	Plr2_SinVal_w,d5
				move.w	Plr2_CosVal_w,d6
				move.l	Lvl_ObjectDataPtr_l,a4
				move.l	Lvl_ObjectPointsPtr_l,a0
				move.w	Lvl_NumObjectPoints_w,d7
				move.l	#Plr2_ObsInLine_vb,a2
				move.l	#Plr2_ObjectDistances_vw,a3

.objpointrotlop:
				cmp.b	#OBJ_TYPE_AUX,ObjT_TypeID_b(a4)
				beq.s	.itaux

				move.w	(a0),d0
				sub.w	Plr2_XOff_l,d0
				move.w	4(a0),d1
				addq	#8,a0

				tst.w	ObjT_ZoneID_w(a4)
				blt		.noworkout

				moveq	#0,d2
				move.b	ObjT_TypeID_b(a4),d2

				sub.w	Plr2_ZOff_l,d1
				move.w	d0,d2
				muls	d6,d2
				move.w	d1,d3
				muls	d5,d3
				sub.l	d3,d2
				add.l	d2,d2

				bgt.s	.okh
				neg.l	d2
.okh:
				swap	d2

				muls	d5,d0
				muls	d6,d1
				add.l	d0,d1
				asl.l	#2,d1
				swap	d1
				moveq	#0,d3

				tst.w	d1
				ble.s	.notinline
				asr.w	#1,d2
				cmp.w	(a6),d2
				bgt.s	.notinline

				st		d3

.notinline:
				move.b	d3,(a2)+
				move.w	d1,(a3)+
				NEXT_OBJ	a4
				dbra	d7,.objpointrotlop

				rts

.itaux:
				NEXT_OBJ	a4
				bra		.objpointrotlop

.noworkout:
				move.w	#0,(a3)+
				move.b	#0,(a2)+
				NEXT_OBJ	a4
				dbra	d7,.objpointrotlop

				rts


RotateObjectPts:
				move.w	Vis_SinVal_w,d5				; fetch sine of rotation
				move.w	Vis_CosVal_w,d6				; cosine

				move.l	Lvl_ObjectDataPtr_l,a4
				move.l	Lvl_ObjectPointsPtr_l,a0
				move.w	Lvl_NumObjectPoints_w,d7
				move.l	#ObjRotated_vl,a1

				tst.b	Vid_FullScreen_b
				bne		RotateObjectPtsFullScreen


.objpointrotlop:
				cmp.b	#OBJ_TYPE_AUX,ObjT_TypeID_b(a4)
				beq.s	.itaux

				move.w	(a0),d0					; x of object point
				sub.w	Plr_XOff_l,d0					; viewX = X - cam X
				move.w	4(a0),d1				; z of object point
				addq	#8,a0					; next point? or next object?

				tst.w	ObjT_ZoneID_w(a4)		; Lvl_ObjectDataPtr_l
				blt		.noworkout

				sub.w	Plr_ZOff_l,d1					; viewZ = Z - cam Z

				move.w	d0,d2
				muls	d6,d2					; cosx = viewX * (cos << 16)
				move.w	d1,d3					;
				muls	d5,d3					; sinz = viewZ * (sin << 16)

				sub.l	d3,d2					;  x' = cosx - sinz
				add.l	d2,d2					; x'*2
				swap	d2						; x' >> 16
				move.w	d2,(a1)+				; finished rotated x'

				muls	d5,d0					; sinx = viewX * sin <<16
				muls	d6,d1					; cosz = viewZ * cos << 16
				add.l	d0,d1					; z' = sinx + cosz
				add.l	d1,d1					; *2
				swap	d1						; >> 16
; ext.l d1
; divs #3,d1
				moveq	#0,d3					;FIMXE: why?

				move.w	d1,(a1)+				; finished rotated z'

				ext.l	d2						; whats the wobble about?
				asl.l	#7,d2
				add.l	xwobble,d2
				move.l	d2,(a1)+				; no clue

				dbra	d7,.objpointrotlop

				rts

.itaux:
				NEXT_OBJ	a4
				bra		.objpointrotlop

.noworkout:
				clr.l	(a1)+
				clr.l	(a1)+
				NEXT_OBJ	a4
				dbra	d7,.objpointrotlop
				rts

RotateObjectPtsFullScreen:

.objpointrotlop:
				cmp.b	#OBJ_TYPE_AUX,ObjT_TypeID_b(a4)
				beq.s	.itaux

				move.w	(a0),d0
				sub.w	Plr_XOff_l,d0
				move.w	4(a0),d1
				addq	#8,a0

				tst.w	ObjT_ZoneID_w(a4)
				blt		.noworkout

				sub.w	Plr_ZOff_l,d1
				move.w	d0,d2
				muls	d6,d2      ; pOEP
				move.w	d1,d3
				muls	d5,d3      ; pOEP
				sub.l	d3,d2
                muls	d5,d0      ; pOEP
				add.l	d2,d2
				swap	d2         ; pOEP
				move.w	d2,(a1)+
				muls	d6,d1      ; pOEP
				add.l	d0,d1
				asl.l	#2,d1
				swap	d1         ; pOEP
				ext.l	d1

				;divs	#3,d1
				muls    #85,d1     ; pOEP
				move.l  xwobble,d3
				asr.l   #8,d1 ; 85/256 approximation of division by 3

				move.w	d1,(a1)+
				ext.l	d2
				asl.l	#7,d2
				add.l	d3,d2
				move.l	d2,(a1)+
				sub.l	d3,d2
				NEXT_OBJ	a4
				dbra	d7,.objpointrotlop

				rts

.itaux:
				NEXT_OBJ	a4

				bra		.objpointrotlop

.noworkout:
				clr.l	(a1)+
				clr.l	(a1)+
				NEXT_OBJ	a4
				dbra	d7,.objpointrotlop
				rts
