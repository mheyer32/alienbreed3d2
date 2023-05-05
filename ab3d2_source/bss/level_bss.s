
			section .bss,bss

; BSS data - to be included in BSS section

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
PointsToRotatePtr_l:			ds.l	1
Lvl_DataPtr_l:					ds.l	1

;*************************************************************
;* ROOM GRAPHICAL DESCRIPTIONS : WALLS AND FLOORS ************
;*************************************************************

Lvl_ZoneBorderPointsPtr_l:		ds.l	1
Lvl_ConnectTablePtr_l:			ds.l	1
Lvl_ListOfGraphRoomsPtr_l:		ds.l	1
AI_AlienShotDataPtr_l:			ds.l	1
Lvl_ObjectPointsPtr_l:			ds.l	1
Lvl_ObjectDataPtr_l:			ds.l	1
Lvl_FloorLinesPtr_l:			ds.l	1
Lvl_PointsPtr_l:				ds.l	1	; Pointer to array of all 2D points in the world
Lvl_ZoneGraphAddsPtr_l:			ds.l	1
Lvl_ZoneAddsPtr_l:				ds.l	1
Lvl_LiftDataPtr_l:				ds.l	1
Lvl_DoorDataPtr_l:				ds.l	1
Lvl_SwitchDataPtr_l:			ds.l	1
Lvl_ControlPointCoordsPtr_l:	ds.l	1
Lvl_GraphicsPtr_l:				ds.l	1
Lvl_ClipsPtr_l:					ds.l	1

; Word aligned data
Lvl_NumControlPoints_w:			ds.w	1
Lvl_NumPoints_w:				ds.w	1
Lvl_NumObjectPoints_w:			ds.w	1

