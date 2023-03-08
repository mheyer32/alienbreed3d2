
			section bss,bss

; BSS data - to be included in BSS section
			align 4

Vid_FastBufferPtr_l:		ds.l	1	; aligned address
Vid_FastBufferAllocPtr_l:	ds.l	1	; allocated address
Vid_Screen1Ptr_l:			ds.l	1
Vid_Screen2Ptr_l:			ds.l	1
Vid_DrawScreenPtr_l:		ds.l	1
Vid_DisplayScreen_Ptr_l:	ds.l	1

Vid_ScreenBuffers_vl:		ds.l	2
Vid_MainScreen_l:			ds.l	1
Vid_MyRaster0_l:			ds.l	1
Vid_MyRaster1_l:			ds.l	1
Vid_DisplayMsgPort_l:		ds.l	1		; this message port receives messages when the current screen has been scanned out
vid_MainWindow_l:			ds.l	1
;vid_SafeMsgPort_l		ds.l	1			; this message port reveives messages when the old screen bitmap can be safely written to
											; i.e. when the screen flip actually happened

Vid_ScreenBufferIndex_w:		ds.w	1	; Index (0/1) of current screen buffer displayed.
											; FIXME: unify the buffer index handling with Vid_DrawScreenPtr_l/Vid_DisplayScreen_Ptr_l

Vid_LetterBoxMarginHeight_w:	ds.w	1	; Letter box rendering, height of black border

Vid_FullScreen_b:				ds.b	1
Vid_FullScreenTemp_b:			ds.b	1
Vid_DoubleHeight_b:				ds.b	1	; Double Height Pixel Mode
Vid_DoubleWidth_b:				ds.b	1	; Double Width Pixel Mode
Vid_WaitForDisplayMsg_b: 		ds.b	1
