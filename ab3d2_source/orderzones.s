				align 4
tmplistgraph:
				dc.l	0

Zone_ListOrdered_b:
				dc.w	0

zone_LastPosition_vw:
				dc.l	-1
OrderZones:
				move.w	xoff,d0
				swap	d0
				move.w	zoff,d0		  ; d0 is the short coordinate location of the player
				and.l	#$FFF0FFF0,d0 ; reduce the change sensitivity a bit
				cmp.l	zone_LastPosition_vw,d0
				bne		.continue
				rts

.continue:
				move.l	d0,zone_LastPosition_vw

				move.l	Lvl_ListOfGraphRoomsPtr_l,a0
; a0=list of rooms to draw.

				move.l	a0,tmplistgraph
				move.l	#zone_ToDrawTable_vw,a1
				move.l	#Sys_Workspace_vl,a4
				move.l	a1,a3
				moveq	#99,d0
				moveq	#0,d1
.clrtab:
				move.l	d1,(a1)+
				dbra	d0,.clrtab

				move.l	a0,a1
				move.l	#zone_OrderTable_vw,a5

settodraw:
				move.w	(a1),d0
				blt.s	nomoreset

				st		(a3,d0.w)
				move.l	4(a1),(a4,d0.w*4)
				adda.w	#8,a1
				bra.s	settodraw

dummy:			dc.w	0 ; ???

nomoreset:

; We now have a table with $ff rep.
; a room to be drawn at some stage.

				move.l	tmplistgraph,a0
				move.l	#zone_OrderTable_vw,a2
				moveq	#0,d0
				moveq	#2,d1

putinn:
				move.w	(a0),d2
				blt		putallin
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
				bra		putinn

putallin:
				move.w	#-1,4(a2)
				move.w	#1,zone_OrderTable_vw+4
				move.w	#-1,zone_OrderTable_vw
				move.w	#-1,zone_OrderTable_vw+2
				move.w	#2,d5					; off end of list.
				move.w	#100,d7					; which ones to look
; at.

				move.l	a2,a5
; clr.b farendfound

RunThroughList:
				DEV_INC.w	Reserved1
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
				blt		doneallthispass

				move.l	#zone_OrderTable_vw,a5
				lea		(a5,d0.w*8),a5
; clr.b donesomething
				bsr		zone_InsertList

				dbra	d7,RunThroughList

doneallthispass:
dontorder:
				move.l	#zone_OrderTable_vw,a5
				move.w	4(a5),d0
				lea		(a5,d0.w*8),a5
				move.l	#Zone_FinalOrderTable_vw,a0

showorder:
				move.w	2(a5),(a0)+
				move.w	4(a5),d0
				blt.s	doneorder
				move.l	#zone_OrderTable_vw,a5
				lea		(a5,d0.w*8),a5
				bra		showorder

doneorder:
				move.l	a0,Zone_EndOfListPtr_l

; move.w d7,TempBuffer


				rts

;farendfound:	dc.b	0
;donesomething:	dc.b	0
;farendpt:		dc.l	0

zone_InsertList:
				move.l	d7,-(a7)
				moveq	#0,d7

InsertLoop:
				move.w	(a0)+,d0				; floor line
				blt		allinlist

				asl.w	#4,d0
; tst.l 8(a1,d0.w)
; beq.s InsertLoop
				moveq	#0,d1
				move.w	8(a1,d0.w),d1
				blt.s	buggergerger

				btst	d7,d6
				bne		indrawlist

buggergerger:
				addq	#3,d7
				bra		InsertLoop

indrawlist:
				addq	#1,d7

				btst	d7,d6
				bne.s	wealreadyknow


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
				ble		PutDone

				bset	d7,d6
				bra		mustdo

wealreadyknow:
				addq	#1,d7
				btst	d7,d6
				beq		PutDone

*****************************
* If this connected zone is supposed
* to be closer, then ignore it

mustdo:

* The connected zone is supposed to
* be further away, so if it is closer
* then we need to move to other side
* of it.

				move.l	#zone_OrderTable_vw,a3
				move.w	(a4),d0
				blt.s	notcloser

checkcloser:
				cmp.w	2(a3,d0.w*8),d1
				beq.s	iscloser

				move.w	(a3,d0.w*8),d0
				bge.s	checkcloser
				bra		notcloser

iscloser:
				;st		donesomething

* The zone which is further away is
* for some reason in the closer part
* of the list. We therefore want to
* move in front of it. a3,d0.w*8 points
* to the incorrect one.

				move.w	(a4),d2
				move.w	4(a3,d2.w*8),d5			; this place
				move.w	4(a4),d3
				blt.s	fromend

				move.w	d2,(a3,d3.w*8)

fromend:
				move.w	d3,4(a3,d2.w*8)
				move.w	(a3,d0.w*8),d2
				move.w	4(a3,d2.w*8),d4
				move.w	d2,(a3,d5.w*8)
				move.w	d4,4(a3,d5.w*8)
				move.w	d5,(a3,d4.w*8)
				move.w	d5,4(a3,d2.w*8)

notcloser:

PutDone:
				addq	#1,d7

notindrawlist:
				bra		InsertLoop

allinlist:
				move.l	d6,(a6)
				move.l	(a7)+,d7
; tst.b donesomething
; bne.s notfoundend
; st farendfound
;notfoundend:
				rts



