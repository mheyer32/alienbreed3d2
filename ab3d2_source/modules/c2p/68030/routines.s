; Common 68030 C2P logic. This code is based on Kalms optimised 030 C2P

				section .data,data
				align 4

c2p_SetParams030Ptrs_vl:								; FS:DW:DH
				dc.l	c2p_SetParamsSmall1x1Opt030		; 000
				dc.l	c2p_SetParamsSmall1x2Opt030		; 001
				dc.l	c2p_SetParamsNull				; 010 TODO 2x1
				dc.l	c2p_SetParamsNull				; 011 TODO 2x2
				dc.l	c2p_SetParamsFull1x1Opt030		; 100
				dc.l	c2p_SetParamsFull1x2Opt030		; 101
				dc.l	c2p_SetParamsNull				; 110 TODO 2x1
				dc.l	c2p_SetParamsNull				; 111 TODO 2x2

c2p_Convert030Ptrs_vl:
				dc.l	c2p_ConvertSmall1x1Opt030		; 000
				dc.l	c2p_ConvertSmall1x2Opt030		; 001
				dc.l	c2p_ConvertNull					; 010 TODO 2x1
				dc.l	c2p_ConvertNull					; 011 TODO 2x2
				dc.l	c2p_ConvertFull1x1Opt030		; 100
				dc.l	c2p_ConvertFull1x2Opt030		; 101
				dc.l	c2p_ConvertNull					; 110 TODO 2x1
				dc.l	c2p_ConvertNull					; 111 TODO 2x2

;
; 2000-04-17
;
; c2p1x1_8_c5_030_2
;
; 1.22vbl [all dma off] on Bliz1230-IV@50
;
; 2000-04-17: added bplsize modifying init (smcinit)
; 1999-01-08: initial version
;
; bplsize must be less than or equal to 16kB!
;

				IFND	BPLX
BPLX			EQU		C2P_BPL_WIDTH
				ENDC
				IFND	BPLY
BPLY			EQU		C2P_BPL_HEIGHT
				ENDC
				IFND	BPLSIZE
BPLSIZE			EQU		BPLX*BPLY/8
				ENDC
				IFND	CHUNKYXMAX
CHUNKYXMAX 		EQU		BPLX
				ENDC
				IFND	CHUNKYYMAX
CHUNKYYMAX 		EQU		C2P_FS_HEIGHT
				ENDC


				section	bss,bss
				align 4

c2p1x1_8_c5_030_2_scroffs	ds.l	1	; Screen (planar) offset
c2p1x1_8_c5_030_2_pixels	ds.l	1	; Buffer Size
c2p1x1_8_c5_030_2_pixels_2	ds.l	1	; Buffer Size (second pass)
c2p1x1_8_c5_030_2_bfroffs	ds.l	1	; Buffer (chunky) offset
c2p1x1_8_c5_030_2_fastbuf	ds.b	CHUNKYXMAX*CHUNKYYMAX/2

				include "modules/c2p/68030/full1x1.s"
				include "modules/c2p/68030/full1x2.s"
				include "modules/c2p/68030/small1x1.s"
				include "modules/c2p/68030/small1x2.s"
