

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
				move.l	d0,Plr1_ZonePtr_l
				move.l	Plr1_ZonePtr_l,a0
				move.l	ZoneT_Floor_l(a0),d0
				sub.l	#PLR_STAND_HEIGHT,d0
				move.l	d0,Plr1_SnapYOff_l
				move.l	d0,Plr1_YOff_l
				move.l	d0,Plr1_SnapTYOff_l
				move.l	Plr1_ZonePtr_l,plr1_OldRoomPtr_l
				move.l	Lvl_DataPtr_l,a1
				add.l	#160*10,a1
				move.w	10(a1),d0
				move.l	Lvl_ZoneAddsPtr_l,a0
				move.l	(a0,d0.w*4),d0
				add.l	Lvl_DataPtr_l,d0
				move.l	d0,Plr2_ZonePtr_l
				move.l	Plr2_ZonePtr_l,a0
				move.l	ZoneT_Floor_l(a0),d0
				sub.l	#PLR_STAND_HEIGHT,d0
				move.l	d0,Plr2_SnapYOff_l
				move.l	d0,Plr2_YOff_l
				move.l	d0,Plr2_SnapTYOff_l
				move.l	d0,Plr2_YOff_l
				move.l	Plr2_ZonePtr_l,plr2_OldRoomPtr_l
				move.w	(a1),Plr1_SnapXOff_l
				move.w	2(a1),Plr1_SnapZOff_l
				move.w	(a1),Plr1_XOff_l
				move.w	2(a1),Plr1_ZOff_l
				move.w	6(a1),Plr2_SnapXOff_l
				move.w	8(a1),Plr2_SnapZOff_l
				move.w	6(a1),Plr2_XOff_l
				move.w	8(a1),Plr2_ZOff_l
				rts
