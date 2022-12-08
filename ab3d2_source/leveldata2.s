

;*************************************************************
;* SET UP INITIAL POSITION OF PLAYER *************************
;*************************************************************

Plr_Initialise:
				move.l	Lvl_DataPtr_l,a1
				add.l	#160*10,a1
				move.w	4(a1),d0
				move.l	Lvl_ZoneAddsPtr_l,a0
				move.l	(a0,d0.w*4),d0
				add.l	Lvl_DataPtr_l,d0
				move.l	d0,Plr1_RoomPtr_l
				move.l	Plr1_RoomPtr_l,a0
				move.l	ZoneT_Floor_l(a0),d0
				sub.l	#PLR_HEIGHT,d0
				move.l	d0,Plr1_SnapYOff_l
				move.l	d0,Plr1_YOff_l
				move.l	d0,Plr1_SnapTYOff_l
				move.l	Plr1_RoomPtr_l,Plr1_OldRoomPtr_l
				move.l	Lvl_DataPtr_l,a1
				add.l	#160*10,a1
				move.w	10(a1),d0
				move.l	Lvl_ZoneAddsPtr_l,a0
				move.l	(a0,d0.w*4),d0
				add.l	Lvl_DataPtr_l,d0
				move.l	d0,Plr2_RoomPtr_l
				move.l	Plr2_RoomPtr_l,a0
				move.l	ZoneT_Floor_l(a0),d0
				sub.l	#PLR_HEIGHT,d0
				move.l	d0,Plr2_SnapYOff_l
				move.l	d0,Plr2_YOff_l
				move.l	d0,Plr2_SnapTYOff_l
				move.l	d0,Plr2_YOff_l
				move.l	Plr2_RoomPtr_l,Plr2_OldRoomPtr_l
				move.w	(a1),Plr1_SnapXOff_l
				move.w	2(a1),Plr1_SnapZOff_l
				move.w	(a1),Plr1_XOff_l
				move.w	2(a1),Plr1_ZOff_l
				move.w	6(a1),Plr2_SnapXOff_l
				move.w	8(a1),Plr2_SnapZOff_l
				move.w	6(a1),Plr2_XOff_l
				move.w	8(a1),Plr2_ZOff_l
				rts

;*************************************************
;* Floor lines:                                  *
;* A floor line is a line seperating two rooms.  *
;* The data for the line is therefore:           *
;* x,y,dx,dy,Room1,Room2                         *
;* For ease of editing the lines are initially   *
;* stored in the form startpt,endpt,Room1,Room2  *
;* and the program calculates x,y,dx and dy from *
;* this information and stores it in a buffer.   *
;*************************************************

				align 4
; long aligned data
PointsToRotatePtr_l:			dc.l	0
Lvl_DataPtr_l:					dc.l	0

;*************************************************************
;* ROOM GRAPHICAL DESCRIPTIONS : WALLS AND FLOORS ************
;*************************************************************

Lvl_ZoneBorderPointsPtr_l:		dc.l	0
Lvl_ConnectTablePtr_l:			dc.l	0
Lvl_ListOfGraphRoomsPtr_l:		dc.l	0
NastyShotDataPtr_l:				dc.l	0
Lvl_ObjectPointsPtr_l:			dc.l	0
Plr_ShotDataPtr_l:				dc.l	0
Lvl_ObjectDataPtr_l:			dc.l	0
Lvl_FloorLinesPtr_l:			dc.l	0
Lvl_PointsPtr_l:				dc.l	0	; Pointer to array of all 2D points in the world
Plr1_ObjectPtr_l:				dc.l	0
Plr2_ObjectPtr_l:				dc.l	0
Lvl_ZoneGraphAddsPtr_l:			dc.l	0
Lvl_ZoneAddsPtr_l:				dc.l	0
Lvl_LiftDataPtr_l:				dc.l	0
Lvl_DoorDataPtr_l:				dc.l	0
Lvl_SwitchDataPtr_l:			dc.l	0
Lvl_ControlPointCoordsPtr_l:	dc.l	0
Lvl_GraphicsPtr_l:				dc.l	0
Lvl_ClipsPtr_l:					dc.l	0
OtherNastyDataPtr_vl:			ds.l	20

; Word aligned data
Lvl_NumControlPoints_w:			dc.w	0
Lvl_NumPoints_w:				dc.w	0
Lvl_NumObjectPoints_w:			dc.w	0

;wall			SET		0
;seethruwall		SET		13
;floor			SET		1
;roof			SET		2
;setclip			SET		3
;object			SET		4
;curve			SET		5
;light			SET		6
;water			SET		7
;bumpfloor		SET		8
;bumproof		SET		9
;smoothfloor		SET		10
;smoothroof		SET		11
;backdrop		SET		12

;BackGraph:
;				dc.w	-1
;				dc.w	backdrop
;				dc.l	-1

;NullClip:		dc.l	0



