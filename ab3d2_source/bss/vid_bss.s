
			section bss,bss

; BSS data - to be included in BSS section
			align 4

Vid_FastBufferPtr_l:		ds.l	1	; aligned address
Vid_FastBufferAllocPtr_l:	ds.l	1	; allocated address
Vid_Screen1Ptr_l:			ds.l	1
Vid_Screen2Ptr_l:			ds.l	1
Vid_DrawScreenPtr_l:		ds.l	1
Vid_DisplayScreen_Ptr_l:	ds.l	1

Vid_LetterBoxMarginHeight_w:	ds.w	1	; Letter box rendering, height of black border
Vid_FullScreen_b:				ds.b	1
Vid_FullScreenTemp_b:			ds.b	1
Vid_DoubleHeight_b:				ds.b	1	; Double Height Pixel Mode
Vid_DoubleWidth_b:				ds.b	1	; Double Width Pixel Mode
