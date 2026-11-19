
	; Data structure used by wall drawing
	STRUCTURE WD,0
		LABEL WD_DWidth_l		;  0 ; union
		UWORD WD_LeftX_w		;  0
		UWORD WD_RightX_w		;  2

		LABEL WD_DBM_l			;  4 ; union
		UWORD WD_LeftBM_w		;  4
		UWORD WD_RightBM_w		;  6

		LABEL WD_DDist_l		;  8 ; union
		UWORD WD_LeftDist_w		;  8
		UWORD WD_RightDist_w	; 10

		LABEL WD_DTop_l			; 12 ; union
		UWORD WD_LeftTop_w		; 12
		UWORD WD_RightTop_w		; 14

		LABEL WD_DBot_l			; 16 ; union
		UWORD WD_LeftBot_w		; 16
		UWORD WD_RightBot_w		; 18

		UWORD WD_Unknown_0_w	; 20
		UWORD WD_Unknown_1_w	; 22

		; Whole wall for simple case, lower half for full Gouraud case
		LABEL WD_LeftBrightScaled_l	; 24 ; union
		UWORD WD_LeftBright_w	; 24
		UWORD WD_RightBright_w	; 26

		ULONG WD_DHorizBright_l	; 28

		LABEL WD_UpperLeftBrightScaled_l ; 32 ; union
		UWORD WD_UpperLeftBright_w	; 32
		UWORD WD_UpperRightBright_w ; 34

		ULONG WD_DUpperHorizBright_l ; 36

		LABEL WD_SizeOf_l
