vid_MyAllocRaster:
				move.l	#SCREEN_WIDTH,d0		; want all planes in one chunk of memory
				move.l	#(SCREEN_HEIGHT*8)+1,d1
				CALLGRAF AllocRaster

				tst.l	d0
				rts

Vid_OpenMainScreen:
				; Allocate Buffer 0
				lea		vid_MainBitmap0,a0
				moveq.l	#8,d0
				move.l	#SCREEN_WIDTH,d1
				move.l	#SCREEN_HEIGHT,d2
				CALLGRAF InitBitMap

				bsr		vid_MyAllocRaster
				;				beq	exit_closeall

				move.l	d0,Vid_MyRaster0_l
				addq.l	#7,d0						; align to 8 byte for FMOD3
				and.l	#~7,d0
				move.l	d0,Vid_Screen1Ptr_l
				move.l	d0,Vid_TextScreenPtr_l		; FIXME: Vid_TextScreenPtr_l should go
				lea		vid_MainBitmap0+bm_Planes,a1
				moveq.l	#7,d1

.storePlanePtr0:
				move.l	d0,(a1)+
				add.l	#(SCREEN_HEIGHT*(SCREEN_WIDTH/8)),d0
				dbra	d1,.storePlanePtr0

				; Allocate Buffer 1
				lea		vid_MainBitmap1,a0
				moveq.l	#8,d0
				move.l	#SCREEN_WIDTH,d1
				move.l	#SCREEN_HEIGHT,d2
				CALLGRAF InitBitMap

				bsr		vid_MyAllocRaster
				;				beq	exit_closeall

				move.l	d0,Vid_MyRaster1_l
				addq.l	#7,d0					; align to 8 byte for FMOD3
				and.l	#~7,d0
				move.l	d0,Vid_Screen2Ptr_l
				lea		vid_MainBitmap1+bm_Planes,a1
				moveq.l	#7,d1

.storePlanePtr1:
				move.l	d0,(a1)+
				add.l	#(SCREEN_HEIGHT*(SCREEN_WIDTH/8)),d0
				dbra	d1,.storePlanePtr1

				lea		MainNewScreen,a0
				lea		vid_MainScreenTags_vl,a1
				CALLINT	OpenScreenTagList

				tst.l	d0
				;	beq	exit_closeall
				move.l	d0,Vid_MainScreen_l
				move.l	Vid_MainScreen_l,a0
				lea		vid_MainBitmap0,a1
				clr.l	d0
				CALLINT	AllocScreenBuffer

				tst.l	d0
				;	beq	exit_closeall
				move.l	d0,Vid_ScreenBuffers_vl+0		; FIXME: free upon exit
				move.l	Vid_MainScreen_l,a0
				lea		vid_MainBitmap1,a1
				clr.l	d0
				CALLINT	AllocScreenBuffer

				tst.l	d0
				;	beq	exit_closeall
				move.l	d0,Vid_ScreenBuffers_vl+4		; FIXME: free upon exit

				;CALLEXEC CreateMsgPort
				;tst.l	d0
				;;	beq	exit_closeall
				;move.l	d0,vid_SafeMsgPort_l			; FIXME: free upon exit

				CALLEXEC CreateMsgPort

				tst.l	d0
				;	beq	exit_closeall
				move.l	d0,Vid_DisplayMsgPort_l		; FIXME: free upon exit

YYY:
				move.l	Vid_ScreenBuffers_vl+0,a0
				move.l	sb_DBufInfo(a0),a0		; getDBufInfo ptr

				; not using vid_SafeMsgPort_l atm.
				; Would need to use it to prevent C2P to write to a bitmap thats
				; currently scanned out, but haven't seen issues with that so far
				;move.l	vid_SafeMsgPort_l,dbi_SafeMessage+MN_REPLYPORT(a0)

				move.l	Vid_DisplayMsgPort_l,dbi_DispMessage+MN_REPLYPORT(a0)
				move.l	Vid_ScreenBuffers_vl+4,a0
				move.l	sb_DBufInfo(a0),a0		; getDBufInfo ptr
				;move.l	vid_SafeMsgPort_l,dbi_SafeMessage+MN_REPLYPORT(a0)
				move.l	Vid_DisplayMsgPort_l,dbi_DispMessage+MN_REPLYPORT(a0)

				; need a window to be able to clear out mouse pointer
				; may later also serve as IDCMP input source
				sub.l	a0,a0
				lea		vid_MainWindowTags_vl,a1
				move.l	Vid_MainScreen_l,MainWTagScreenPtr-vid_MainWindowTags_vl(a1) ; WA_CustomScreen
				CALLINT	OpenWindowTagList

				tst.l	d0
				;				beq	exit_closeall
				move.l	d0,vid_MainWindow_l
				move.l	d0,a0
				lea		emptySprite,a1
				moveq	#1,d0
				moveq	#16,d1
				move.l	d0,d2
				move.l	d0,d3
				CALLINT	SetPointer

				jsr		LoadMainPalette

				move.l	vid_MainWindow_l,a0
				CALLINT ViewPortAddress

				move.l	d0,a2
				move.l	vp_ColorMap(a2),a0
				lea		vid_VidControlTags_vl,a1
				CALLGRAF VideoControl

				; Setup a User copperlist to enable doubleheight rendering
				move.l	_GfxBase,a6
				lea		vid_MyUCopList_vb,a2

				CINIT	a2,116*6+4	; 232 modulos

				*******************************************************************************
				;Bplmod: The modulo is usually in aga mode the same as in normal mode minus 8.
				;So if your normal modulo = 0 then the agamodulo is -8. (if you use FMODE=3!)
				;if you use FMODE =$2 then the modulo is -4.
				*******************************************************************************
				; FMODE is assumed to be 3, but can I somehow query?
				moveq.l	#$0,d2
.nextLine:
				CWAIT	a2,d2,#0
				CMOVE	a2,bpl1mod,#-40-8 ; repeat the line
				CMOVE	a2,bpl2mod,#-40-8
				addq.w	#1,d2
				CWAIT	a2,d2,#0
				CMOVE	a2,bpl1mod,#40-8	; skip line
				CMOVE	a2,bpl2mod,#40-8
				addq.w	#1,d2
				cmp.w	#232,d2
				blt		.nextLine
				CWAIT	a2,d2,#0
				CMOVE	a2,bpl1mod,#0-8
				CMOVE	a2,bpl2mod,#0-8
				CEND	a2

				rts

vid_SetupDoubleheightCopperlist:
				; Install copperlist
				move.l	vid_MainWindow_l,a0
				CALLINT ViewPortAddress

				move.l	d0,a2

				CALLEXEC Forbid

				tst.b	Vid_DoubleHeight_b
				beq.s	.noDoubleheight
				move.l	#vid_MyUCopList_vb,vp_UCopIns(a2)
				bra.s	.install

.noDoubleheight:
				move.l	#0,vp_UCopIns(a2)

.install:
				CALLEXEC Permit

				CALLINT RethinkDisplay

				rts

				align	4
vid_MainScreenTags_vl:
				dc.l	SA_Width,SCREEN_WIDTH
				dc.l	SA_Height,SCREEN_HEIGHT
				dc.l	SA_Depth,8
				dc.l	SA_BitMap,vid_MainBitmap0
				dc.l	SA_Type,CUSTOMSCREEN
				dc.l	SA_Quiet,1
				IFNE	SCREEN_TITLEBAR_HACK
				dc.l	SA_ShowTitle,0
				ELSE
				dc.l	SA_ShowTitle,1
				ENDC
				dc.l	SA_AutoScroll,0
				dc.l	SA_FullPalette,1
				dc.l	SA_DisplayID,PAL_MONITOR_ID
				dc.l	TAG_END,0

				align	4
MainNewScreen:
				dc.w	0						; ns_LeftEdge
				dc.w	0						; ns_TopEdge
				dc.w	SCREEN_WIDTH			; ns_Width
				dc.w	SCREEN_HEIGHT			; ns_Height
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
vid_MainWindowTags_vl:
				dc.l	WA_Left,0
				dc.l	WA_Top,0
				dc.l	WA_Width,SCREEN_WIDTH
				dc.l	WA_Height,SCREEN_HEIGHT
				dc.l	WA_CustomScreen
MainWTagScreenPtr:
				dc.l	0						; will fill in screen pointer later
				dc.l	WA_Activate,1
				dc.l	WA_Borderless,1
				dc.l	WA_RMBTrap,1			; prevent menu rendering
				dc.l	WA_NoCareRefresh,1
				dc.l	WA_SimpleRefresh,1
				dc.l	WA_Backdrop,1
				dc.l	TAG_END,0

				align	4
vid_MainBitmap0:
				dc.w	SCREEN_WIDTH/8			; bm_BytesPerRow
				dc.w	SCREEN_HEIGHT			; bm_Rows
				dc.b	BMF_DISPLAYABLE			; bm_Flags
				dc.b	8						; bm_Depth
				dc.w	0						; bm_Pad
				ds.l	8						; bm_Planes

				align	4
vid_MainBitmap1:
				dc.w	SCREEN_WIDTH/8			; bm_BytesPerRow
				dc.w	SCREEN_HEIGHT			; bm_Rows
				dc.b	BMF_DISPLAYABLE			; bm_Flags
				dc.b	8						; bm_Depth
				dc.w	0						; bm_Pad
				ds.l	8						; bm_Planes

				align	4
vid_MyUCopList_vb:
				ds.b	ucl_SIZEOF				; see copper.i

				align	4
vid_VidControlTags_vl:
				dc.l	VTAG_USERCLIP_SET,1
				dc.l	VTAG_END_CM,0
