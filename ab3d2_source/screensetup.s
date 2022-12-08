MyAllocRaster:
				move.l	#320,d0					; want all planes in one chunk of memory
				move.l	#(256*8)+1,d1
				CALLGRAF AllocRaster
				tst.l	d0
				rts

OpenMainScreen:
				; Allocate Buffer 0
				lea		MainBitmap0,a0
				moveq.l	#8,d0
				move.l	#320,d1
				move.l	#256,d2
				CALLGRAF InitBitMap

				bsr		MyAllocRaster
				;				beq	exit_closeall
				move.l	d0,MyRaster0

				addq.l	#7,d0					; align to 8 byte for FMOD3
				and.l	#~7,d0
				move.l	d0,scrn

				move.l	d0,Vid_TextScreenPtr_l				; FIXME: Vid_TextScreenPtr_l should go

				lea		MainBitmap0+bm_Planes,a1
				moveq.l	#7,d1
.storePlanePtr0	move.l	d0,(a1)+
				add.l	#(256*(320/8)),d0
				dbra	d1,.storePlanePtr0

				; Allocate Buffer 1
				lea		MainBitmap1,a0
				moveq.l	#8,d0
				move.l	#320,d1
				move.l	#256,d2
				CALLGRAF InitBitMap

				bsr		MyAllocRaster
				;				beq	exit_closeall
				move.l	d0,MyRaster1

				addq.l	#7,d0					; align to 8 byte for FMOD3
				and.l	#~7,d0
				move.l	d0,scrn2

				lea		MainBitmap1+bm_Planes,a1
				moveq.l	#7,d1
.storePlanePtr1	move.l	d0,(a1)+
				add.l	#(256*(320/8)),d0
				dbra	d1,.storePlanePtr1

				lea		MainNewScreen,a0
				lea		MainScreenTags,a1
				CALLINT	OpenScreenTagList
				tst.l	d0
				;	beq	exit_closeall
				move.l	d0,MainScreen

				move.l	MainScreen,a0
				lea		MainBitmap0,a1
				clr.l	d0
				CALLINT	AllocScreenBuffer
				tst.l	d0
				;	beq	exit_closeall
				move.l	d0,ScreenBuffers+0		; FIXME: free upon exit

				move.l	MainScreen,a0
				lea		MainBitmap1,a1
				clr.l	d0
				CALLINT	AllocScreenBuffer
				tst.l	d0
				;	beq	exit_closeall
				move.l	d0,ScreenBuffers+4		; FIXME: free upon exit


				;CALLEXEC CreateMsgPort
				;tst.l	d0
				;;	beq	exit_closeall
				;move.l	d0,SafeMsgPort			; FIXME: free upon exit

				CALLEXEC CreateMsgPort
				tst.l	d0
				;	beq	exit_closeall
				move.l	d0,DisplayMsgPort		; FIXME: free upon exit

YYY				move.l	ScreenBuffers+0,a0
				move.l	sb_DBufInfo(a0),a0		; getDBufInfo ptr
				; not using SafeMsgPort atm.
				; Would need to use it to prevent C2P to write to a bitmap thats
				; currently scanned out, but haven't seen issues with that so far
				;move.l	SafeMsgPort,dbi_SafeMessage+MN_REPLYPORT(a0)
				move.l	DisplayMsgPort,dbi_DispMessage+MN_REPLYPORT(a0)

				move.l	ScreenBuffers+4,a0
				move.l	sb_DBufInfo(a0),a0		; getDBufInfo ptr
				;move.l	SafeMsgPort,dbi_SafeMessage+MN_REPLYPORT(a0)
				move.l	DisplayMsgPort,dbi_DispMessage+MN_REPLYPORT(a0)
		
				; need a window to be able to clear out mouse pointer
				; may later also serve as IDCMP input source
				sub.l	a0,a0
				lea		MainWindowTags,a1
				move.l	MainScreen,MainWTagScreenPtr-MainWindowTags(a1) ; WA_CustomScreen
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

				move.l	vp_ColorMap(a2),a0
				lea		VidControlTags,a1
				CALLGRAF VideoControl

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
				CWAIT	a2,d2,#0
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

********************************************************************************
;fps counter c/o Grond
FPS_time1:
		move.l	a6,-(sp)
		move.l	timerbase,a6
		lea	FPS_first,a0
		jsr	_LVOReadEClock(a6)
		move.l	(sp)+,a6
		rts


********************************************************************************

FPS_time2:
		movem.l	d2/a2/a6,-(sp)
		move.l	timerbase,a6
		lea	FPS_second,a0
		jsr	_LVOReadEClock(a6)
		move.l	d0,d2
		lea	FPS_second,a0
		lea	FPS_first,a1
		jsr	_LVOSubTime(a6)

; average:
		move.l	FPS_lasttime,d1
		bne	.skip
		add.l	4(a0),d1
.skip:		
		add.l	4(a0),d1
		asr.l	#1,d1
		move.l	d1,FPS_lasttime

		move.l	d2,d0
		mulu.l	#1000,d0
		divu.l	d1,d0
		lea	FPS_outputstring,a0

		move.l	#10000,d1

		divu.w	d1,d0
		move.b	d0,d2
		beq	.leadingzero

		add.b	#"0",d2			; convert to ASCII
		move.b	d2,(a0)+
		bra	.next

.leadingzero:
		move.b	#" ",(a0)+

.next:
		sub.w	d0,d0
		swap	d0
		divu.w	#10,d1
		divu.w	d1,d0
		move.b	d0,d2
		add.b	#"0",d2			; convert to ASCII
		move.b	d2,(a0)+

		move.b	#".",(a0)+

		sub.w	d0,d0
		swap	d0
		divu.w	#10,d1
		divu.w	d1,d0
		move.b	d0,d2
		add.b	#"0",d2			; convert to ASCII
		move.b	d2,(a0)+

		sub.w	d0,d0
		swap	d0
		divu.w	#10,d1
		divu.w	d1,d0
		move.b	d0,d2
		add.b	#"0",d2			; convert to ASCII
		move.b	d2,(a0)+

		move.l	#" fps",(a0)+
;		move.b	#" ",(a0)

		;move.l	gfxbase,a6
		move.l	MainScreen,a0
		lea	sc_RastPort(a0),a1
		lea	sc_ViewPort(a0),a0
		move.l	vp_RasInfo(a0),a0
		move.w	ri_RyOffset(a0),d1
		move.l	a1,a2
		clr.l	d0
		add.w	#10,d1
		ext.l	d1
		CALLGRAF Move

		lea	FPS_outputstring,a0
		move.l	a2,a1
		moveq	#9,d0
		jsr	_LVOText(a6)
		movem.l	(sp)+,d2/a2/a6
		rts


********************************************************************************

				align	4
MainScreen:		dc.l	0
MyRaster0		dc.l	0
MyRaster1		dc.l	0

				align	4
MainScreenTags	dc.l	SA_Width,320
				dc.l	SA_Height,256
				dc.l	SA_Depth,8
				dc.l	SA_BitMap,MainBitmap0
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
				dc.l	WA_Width,320
				dc.l	WA_Height,256
				dc.l	WA_CustomScreen
MainWTagScreenPtr dc.l	0						; will fill in screen pointer later
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
MainBitmap0		dc.w	320/8					; bm_BytesPerRow
				dc.w	256						; bm_Rows
				dc.b	BMF_DISPLAYABLE			; bm_Flags
				dc.b	8						; bm_Depth
				dc.w	0						; bm_Pad
				ds.l	8						; bm_Planes

MainBitmap1		dc.w	320/8					; bm_BytesPerRow
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

timerrequest:	ds.b	IOTV_SIZE
timername:	dc.b	"timer.device",0
FPS_outputstring:	dcb.b	10
				align	4
timerbase:	dc.l	0
timerflag:	dc.l	-1
FPS_first:		dc.l	0,0
FPS_second:		dc.l	0,0
FPS_lasttime:	dc.l	0
ScreenBuffers	ds.l	2
DisplayMsgPort	dc.l	0						; this message port receives messages when the current screen has been scanned out
;SafeMsgPort		dc.l	0						; this message port reveives messages when the old screen bitmap can be safely written to
												; i.e. when the screen flip actually happened
ScreenBufferIndex dc.w	0						; Index (0/1) of current screen buffer displayed.
												; FIXME: unify the buffer index handling with SCRNDRAWPT/SCRNSHOWPT
WaitForDisplayMsg dc.w	0

				align 4
