				align 4
tmp_ListOfGraphRoomsPtr_l:
				dc.l	0

zone_LastPosition_vw: ; basically a short coordinate pair
				dc.l	-1

Zone_OrderZones:
				; TODO this needs to be triggered when the player changes zone.
				; I've tried this by using the ZonePtr but it works only partially.
				move.w	xoff,d0
				swap	d0
				move.w	zoff,d0		  ; d0 is the short coordinate location of the player
				and.l	#$FFF0FFF0,d0 ; reduce the change sensitivity a bit by discarding the low x/z bits
				cmp.l	zone_LastPosition_vw,d0
				bne		.continue
				rts

.continue:
				move.l	d0,zone_LastPosition_vw
				move.l	Lvl_ListOfGraphRoomsPtr_l,a0 ; a0=list of rooms to draw.
				move.l	a0,tmp_ListOfGraphRoomsPtr_l
				move.l	#zone_ToDrawTable_vw,a1
				move.l	#Sys_Workspace_vl,a4
				move.l	a1,a3

				; prepare to clear out zone_ToDrawTable_vw
				; @todo - zone_ToDrawTable_vw is 400 words, this only clears 100 longs, which is half.
				moveq	#99,d0
				moveq	#0,d1

				; a1 points at zone_ToDrawTable_vw
				; a0 points at Lvl_ListOfGraphRooms

.clear_table:
				move.l	d1,(a1)+
				dbra	d0,.clear_table

				move.l	a0,a1
				move.l	#zone_OrderTable_vw,a5

.set_to_draw:
				move.w	(a1),d0
				blt.s	.no_more_set

				st		(a3,d0.w)
				move.l	4(a1),(a4,d0.w*4)
				adda.w	#8,a1
				bra.s	.set_to_draw

.no_more_set:
				; We now have a table with $ff rep.
				; a room to be drawn at some stage.

				move.l	tmp_ListOfGraphRoomsPtr_l,a0
				move.l	#zone_OrderTable_vw,a2
				moveq	#0,d0
				moveq	#2,d1

.put_in_n:
				move.w	(a0),d2
				blt.s	.put_all_in

				move.l	Lvl_ZoneGraphAddsPtr_l,a1
				move.l	(a1,d2.w*4),a1
				add.l	Lvl_GraphicsPtr_l,a1
				addq	#8,a2
				move.w	d2,2(a2)
				move.w	d0,(a2)
				move.w	d1,4(a2)
				addq	#1,d0
				addq	#1,d1
				adda.w	#8,a0
				bra		.put_in_n

.put_all_in:
				move.w	#-1,4(a2)
				move.w	#1,zone_OrderTable_vw+4
				move.w	#-1,zone_OrderTable_vw
				move.w	#-1,zone_OrderTable_vw+2
				move.w	#2,d5					; off end of list.
				move.w	#100,d7					; which ones to look at.

				move.l	a2,a5
				; clr.b farendfound

.run_through_list:
				DEV_INC.w	Reserved2
				move.l	Lvl_FloorLinesPtr_l,a1
				move.w	2(a5),d0
				move.l	#Sys_Workspace_vl,a6
				lea		(a6,d0.w*4),a6
				move.l	(a6),d6
				move.l	Lvl_ZoneAddsPtr_l,a0
				move.l	(a0,d0.w*4),a0
				add.l	Lvl_DataPtr_l,a0
				adda.w	ZoneT_ExitList_w(a0),a0
				move.l	a5,a4

				; tst.b farendfound
				; bne.s nochangeit
				; move.l a5,farendpt

;nochangeit:
				move.w	(a5),d0
				blt.s	.done_all_this_pass

				move.l	#zone_OrderTable_vw,a5
				lea		(a5,d0.w*8),a5
				; clr.b donesomething

				bsr		zone_InsertList

				dbra	d7,.run_through_list

.done_all_this_pass:
.dont_order:
				move.l	#zone_OrderTable_vw,a5
				move.w	4(a5),d0
				lea		(a5,d0.w*8),a5
				move.l	#Zone_FinalOrderTable_vw,a0

.show_order:
				move.w	2(a5),(a0)+
				move.w	4(a5),d0
				blt.s	.done_order

				move.l	#zone_OrderTable_vw,a5
				lea		(a5,d0.w*8),a5
				bra.s	.show_order

.done_order:
				move.l	a0,Zone_EndOfListPtr_l

				rts

;farendfound:	dc.b	0
;donesomething:	dc.b	0
;farendpt:		dc.l	0

zone_InsertList:
				move.l	d7,-(a7)
				moveq	#0,d7

.insert_loop:
				move.w	(a0)+,d0				; floor line
				blt		.all_in_list

				asl.w	#4,d0

				; tst.l 8(a1,d0.w)
				; beq.s .insert_loop

				moveq	#0,d1
				move.w	8(a1,d0.w),d1
				blt.s	.buggergerger ; todo - figure out what this failure case really means

				btst	d7,d6
				bne.s	.in_draw_list

.buggergerger:
				addq	#3,d7
				bra.s	.insert_loop

.in_draw_list:
				addq	#1,d7

				btst	d7,d6
				bne.s	.we_already_know


; Here is a room in the draw list.
; We want to find if it is closer than
; this one.
; Find out if it is further away
; or closer than the current zone.

				bset	d7,d6
				move.w	xoff,d2
				move.w	zoff,d3
				sub.w	(a1,d0.w),d2
				sub.w	2(a1,d0.w),d3
				muls	6(a1,d0.w),d2
				muls	4(a1,d0.w),d3
				addq	#1,d7
				sub.l	d3,d2
				ble.s	.put_done

				bset	d7,d6
				bra.s	.must_do

.we_already_know:
				addq	#1,d7
				btst	d7,d6
				beq.s	.put_done

;*****************************
;* If this connected zone is supposed
;* to be closer, then ignore it

.must_do:

;* The connected zone is supposed to
;* be further away, so if it is closer
;* then we need to move to other side
;* of it.

				move.l	#zone_OrderTable_vw,a3
				move.w	(a4),d0
				blt.s	.not_closer

.check_closer:
				cmp.w	2(a3,d0.w*8),d1
				beq.s	.is_closer

				move.w	(a3,d0.w*8),d0
				bge.s	.check_closer
				bra.s	.not_closer

.is_closer:
				;st		donesomething

;* The zone which is further away is
;* for some reason in the closer part
;* of the list. We therefore want to
;* move in front of it. a3,d0.w*8 points
;* to the incorrect one.

				move.w	(a4),d2
				move.w	4(a3,d2.w*8),d5			; this place
				move.w	4(a4),d3
				blt.s	.from_end

				move.w	d2,(a3,d3.w*8)

.from_end:
				move.w	d3,4(a3,d2.w*8)
				move.w	(a3,d0.w*8),d2
				move.w	4(a3,d2.w*8),d4
				move.w	d2,(a3,d5.w*8)
				move.w	d4,4(a3,d5.w*8)
				move.w	d5,(a3,d4.w*8)
				move.w	d5,4(a3,d2.w*8)

.not_closer:

.put_done:
				addq	#1,d7

.not_in_draw_list:
				bra		.insert_loop

.all_in_list:
				move.l	d6,(a6)
				move.l	(a7)+,d7

				; tst.b donesomething
				; bne.s notfoundend
				; st farendfound
;notfoundend:
				rts
