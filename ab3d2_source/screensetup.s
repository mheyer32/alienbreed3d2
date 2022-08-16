MyAllocRaster:
				move.l	#320,d0					; want all planes in one chunk of memory
				move.l	#(256*8)+1,d1
				CALLGRAF AllocRaster
				tst.l	d0
				rts

OpenMainScreen:

				bsr		MyAllocRaster
				;				beq	exit_closeall
				move.l	d0,MyRaster0

				addq.l	#7,d0					; align to 8 byte for FMOD3
				and.l	#~7,d0
				move.l	d0,scrn

				move.l	d0,TEXTSCRN				; FIXME: TEXTSCRN should go

				bsr		MyAllocRaster
				;				beq	exit_closeall
				move.l	d0,MyRaster1

				addq.l	#7,d0					; align to 8 byte for FMOD3
				and.l	#~7,d0
				move.l	d0,scrn2

				lea		MainBitmap+bm_Planes,a1
				moveq.l	#7,d1
.storePlanePtr	move.l	d0,(a1)+
				add.l	#(256*(320/8)),d0
				dbra	d1,.storePlanePtr

				lea		MainNewScreen,a0
				lea		MainScreenTags,a1
				CALLINT	OpenScreenTagList
				tst.l	d0
				;	beq	exit_closeall		if failed the close both, exit
				move.l	d0,MainScreen

				; need a window to be able to clear out mouse pointer
				; may later also serve as IDCMP input source
				sub.l	a0,a0
				lea		MainWindowTags,a1
				move.l	d0,MainWTagScreenPtr-MainWindowTags(a1) ; WA_CustomScreen
				CALLINT	OpenWindowTagList
				tst.l	d0
				;				beq	exit_closeall
				move.l	d0,MainWindow
				move.l	d0,a0
				lea		emptySprite,a1
				moveq	#1,d0
				moveq	#16,d1
				move.l	d0,d2
				move.l	d0,d3
				CALLINT	SetPointer

				jsr		LoadMainPalette
				move.l	MainWindow,a0
				CALLINT ViewPortAddress
				move.l	d0,a2

				;move.l	vp_ColorMap(a2),a0
				;lea		VidControlTags,a1
				;CALLGRAF VideoControl

				; Setup a User copperlist to enable doubleheight rendering
				move.l	_GfxBase,a6
				lea		MyUCopList,a2

				CINIT	a2,116*6+4	; 232 modulos

				*******************************************************************************
				;Bplmod: The modulo is usually in aga mode the same as in normal mode minus 8.
				;So if your normal modulo = 0 then the agamodulo is -8. (if you use FMODE=3!)
				;if you use FMODE =$2 then the modulo is -4.
				*******************************************************************************
				; FMODE is assumed to be 3, but can I somehow query?
				moveq.l	#$0,d2
.nextLine:		CWAIT	a2,d2,#0
				CMOVE	a2,bpl1mod,#-40-8 ; repeat the line
				CMOVE	a2,bpl2mod,#-40-8
				addq.w	#1,d2
				CWAIT	a2,d2,#0
				CMOVE	a2,bpl1mod,#40-8	; skip line
				CMOVE	a2,bpl2mod,#40-8
				addq.w	#1,d2
				cmp.w	#232,d2
				blt		.nextLine
				CWAIT	a2,d2,#30
				CMOVE	a2,bpl1mod,#0-8
				CMOVE	a2,bpl2mod,#0-8
				CEND	a2

				rts

SetupDoubleheightCopperlist:
				; Install copperlist
				move.l	MainWindow,a0
				CALLINT ViewPortAddress
				move.l	d0,a2

				CALLEXEC Forbid

				tst.b	DOUBLEHEIGHT
				beq.s	.noDoubleheight
				move.l	#MyUCopList,vp_UCopIns(a2)
				bra.s	.install
.noDoubleheight	move.l	#0,vp_UCopIns(a2)

.install		CALLEXEC Permit

				CALLINT RethinkDisplay
				rts

				align	4
MainScreen:		dc.l	0
MyRaster0		dc.l	0
MyRaster1		dc.l	0

				align	4
MainScreenTags	dc.l	SA_Width,320
				dc.l	SA_Height,256
				dc.l	SA_Depth,8
				dc.l	SA_BitMap,MainBitmap
				dc.l	SA_Type,CUSTOMSCREEN
				dc.l	SA_Quiet,1
				dc.l	SA_AutoScroll,0
				dc.l	SA_FullPalette,1
				dc.l	SA_DisplayID,PAL_MONITOR_ID
				dc.l	TAG_END,0

				align	4
MainNewScreen	dc.w	0						; ns_LeftEdge
				dc.w	0						; ns_TopEdge
				dc.w	320						; ns_Width
				dc.w	256						; ns_Height
				dc.w	8						; ns_Depth
				dc.b	0						; ns_DetailPen
				dc.b	0						; ns_BlockPen
				dc.w	0						; ns_ViewModes
				dc.w	CUSTOMSCREEN!SCREENQUIET; ns_Type
				dc.l	0						; ns_Font
				dc.l	0						; ns_DefaultTitle
				dc.l	0						; ns_Gadgets
				dc.l	0						; ns_CustomBitMap

				align	4
MainWindowTags	dc.l	WA_Left,0
				dc.l	WA_Top,0
				dc.l	WA_Width,0
				dc.l	WA_Height,0
				dc.l	WA_CustomScreen
MainWTagScreenPtr dc.l	0						; will fill in screen pointer later
				; intution.i states "WA_Flags ;not implemented at present"
				; But I have seen code using it...
				dc.l	WA_Flags,WFLG_ACTIVATE!WFLG_BORDERLESS!WFLG_RMBTRAP!WFLG_SIMPLE_REFRESH!WFLG_BACKDROP!WFLG_NOCAREREFRESH
				; Just to be sure, provide the same info again
				dc.l	WA_Activate,1
				dc.l	WA_Borderless,1
				dc.l	WA_RMBTrap,1			; prevent menu rendering
				dc.l	WA_NoCareRefresh,1
				dc.l	WA_SimpleRefresh,1
				dc.l	WA_Backdrop,1
				dc.l	TAG_END,0

				align	4
MainWindow		dc.l	0

				align	4
MainBitmap		dc.w	320/8					; bm_BytesPerRow
				dc.w	256						; bm_Rows
				dc.b	BMF_DISPLAYABLE			; bm_Flags
				dc.b	8						; bm_Depth
				dc.w	0						; bm_Pad
				ds.l	8						; bm_Planes

				align	4
MyUCopList		ds.b	ucl_SIZEOF				; see copper.i

				align	4
VidControlTags	dc.l	VTAG_USERCLIP_SET,1
				dc.l	VTAG_END_CM,0
