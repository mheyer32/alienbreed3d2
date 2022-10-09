;	  _______  ___                    ___        _______
;	 /°-     \/. /    _____   ____   / ./       /°-     \
;	 \   \___//  \___/°    \_/°   \_/   \___    \   \___/
;	_/\__    \      ~\_  /\  \  /\ ~\      °\_ _/\__    \
;	\\       /   /\   /  \/. /  \/   \ //\   / \\       /
;	 \______/\__/  \_/\_____/\____/\_/_/  \_/ o \______/ Issue 1

;The following are a few example of converting chunky data to normal planar
;data. I'm sorry, but I'm not sure who wrote these, but thanks a lot anyway.
;I've put all the examples in one file, so you'll have to cut & paste them
;yourself.	Squize 18/12/94


                            O /
------CUT-OUT----------------X-----------------------------------------------
                            O \
;
; Hi James,
;
; I suddenly saw how to use eor.l to shave a few more cycles.  Now it's
; 67.0 cycles/pixel with no nasty tricks.  (Use a7 as another bitplane
; pointer to get 66.5 cycles/pixel.)  It's still untested.
;
; I think I've about reached my limit, unless someone gives me some more
; clues.
;
; Regards, Peter.

		xdef	_chunky2planar

;-----------------------------------------------------------------------------
; chunky2planar:	(new Motorola syntax)
;  a0 -> chunky pixels
;  a1 -> plane0 (assume other 7 planes are allocated contiguously)
; d0-d1/a0-a1 are trashed


width		equ	320		; must be a multiple of 8
height		equ	200
plsiz		equ	(width/8)*height

_chunky2planar:

		movem.l	d2-d7/a2-a6,-(sp)

; set up register constants

		move.l	#$0f0f0f0f,d5	; d5 = constant $0f0f0f0f
		move.l	#$55555555,d6	; d6 = constant $55555555
		move.l	#$3333cccc,d7	; d7 = constant $3333cccc
		lea	(plsiz,a1),a2	; a2 -> plane1 (end of plane0)

; load up (otherwise) unused address registers with bitplane ptrs

		movea.l	a2,a3		; a3 -> plane1
		lea	(2*plsiz,a1),a4	; a4 -> plane2
		lea	(2*plsiz,a4),a5	; a5 -> plane4
		lea	(2*plsiz,a5),a6	; a6 -> plane6

; main loop (starts here) processes 8 chunky pixels at a time

mainloop:

; d0 = a7a6a5a4a3a2a1a0 b7b6b5b4b3b2b1b0 c7c6c5c4c3c2c1c0 d7d6d5d4d3d2d1d0

		move.l	(a0)+,d0	; 12 get next 4 chunky pixels in d0

; d1 = e7e6e5e4e3e2e1e0 f7f6f5f4f3f2f1f0 g7g6g5g4g3g2g1g0 h7h6h5h4h3h2h1h0

		move.l	(a0)+,d1	; 12 get next 4 chunky pixels in d1

; d2 = d0 & 0f0f0f0f
; d2 = ........a3a2a1a0 ........b3b2b1b0 ........c3c2c1c0 ........d3d2d1d0

		move.l	d0,d2		;  4
		and.l	d5,d2		;  8 d5=$0f0f0f0f

; d0 ^= d2
; d0 = a7a6a5a4........ b7b6b5b4........ c7c6c5c4........ d7d6d5d4........

		eor.l	d2,d0		;  8

; d3 = d1 & 0f0f0f0f
; d3 = ........e3e2e1e0 ........f3f2f1f0 ........g3g2g1g0 ........h3h2h1h0

		move.l	d1,d3		;  4
		and.l	d5,d3		;  8 d5=$0f0f0f0f

; d1 ^= d3
; d1 = e7e6e5e4........ f7f6f5f4........ g7g6g5g4........ h7h6h5h4........

		eor.l	d3,d1		;  8

; d2 = (d2 << 4) | d3
; d2 = a3a2a1a0e3e2e1e0 b3b2b1b0f3f2f1f0 c3c2c1c0g3g2g1g0 d3d2d1d0h3h2h1h0

		lsl.l	#4,d2		; 16
		or.l	d3,d2		;  8

; d0 = d0 | (d1 >> 4)
; d0 = a7a6a5a4e7e6e5e4 b7b6b5b4f7f6f5f4 c7c6c5c4g7g6g5g4 d7d6d5d4h7h6h5h4

		lsr.l	#4,d1		; 16
		or.l	d1,d0		;  8

; d3 = ((d2 & 33330000) << 2) | (swap(d2) & 3333cccc) | ((d2 & 0000cccc) >> 2)
; d3 = a1a0c1c0e1e0g1g0 b1b0d1d0f1f0h1h0 a3a2c3c2e3e2g3g2 b3b2d3d2f3f2h3h2

		move.l	d2,d3		;  4
		and.l	d7,d3		;  8 d7=$3333cccc
		move.w	d3,d1		;  4
		clr.w	d3		;  4
		lsl.l	#2,d3		; 12
		lsr.w	#2,d1		; 10
		or.w	d1,d3		;  4
		swap	d2		;  4
		and.l	d7,d2		;  8 d7=$3333cccc
		or.l	d2,d3		;  8

; d1 = ((d0 & 33330000) << 2) | (swap(d0) & 3333cccc) | ((d0 & 0000cccc) >> 2)
; d1 = a5a4c5c4e5e4g5g4 b5b4d5d4f5f4h5h4 a7a6c7c6e7e6g7g6 b7b6d7d6f7f6h7h6

		move.l	d0,d1		;  4
		and.l	d7,d1		;  8 d7=$3333cccc
		move.w	d1,d2		;  4
		clr.w	d1		;  4
		lsl.l	#2,d1		; 12
		lsr.w	#2,d2		; 10
		or.w	d2,d1		;  4
		swap	d0		;  4
		and.l	d7,d0		;  8 d7=$3333cccc
		or.l	d0,d1		;  8

; d2 = d1 >> 7
; d2 = ..............a5 a4c5c4e5e4g5g4b5 b4d5d4f5f4h5h4a7 a6c7c6e7e6g7g6..

		move.l	d1,d2		;  4
		lsr.l	#7,d2		; 22

; d0 = d1 & 55555555
; d0 = ..a4..c4..e4..g4 ..b4..d4..f4..h4 ..a6..c6..e6..g6 ..b6..d6..f6..h6

		move.l	d1,d0		;  4
		and.l	d6,d0		;  8 d6=$55555555

; d1 ^= d0
; d1 = a5..c5..e5..g5.. b5..d5..f5..h5.. a7..c7..e7..g7.. b7..d7..f7..h7..

		eor.l	d0,d1		;  8

; d4 = d2 & 55555555
; d4 = ..............a5 ..c5..e5..g5..b5 ..d5..f5..h5..a7 ..c7..e7..g7....

		move.l	d2,d4		;  4
		and.l	d6,d4		;  8 d6=$55555555

; d2 ^= d4
; d2 = ................ a4..c4..e4..g4.. b4..d4..f4..h4.. a6..c6..e6..g6..

		eor.l	d4,d2		;  8

; d1 = (d1 | d4) >> 1
; d1 = ................ a5b5c5d5e5f5g5h5 ................ a7b7c7d7e7f7g7h7

		or.l	d4,d1		;  8
		lsr.l	#1,d1		; 10

		move.b	d1,(plsiz,a6)	; 12 plane 7
		swap	d1		;  4
		move.b	d1,(plsiz,a5)	; 12 plane 5

; d2 |= d0
; d2 = ................ a4b4c4d4e4f4g4h4 ................ a6b6c6d6e6f6g6h6

		or.l	d0,d2		;  8

		move.b	d2,(a6)+	;  8 plane 6
		swap	d2		;  4
		move.b	d2,(a5)+	;  8 plane 4

; d2 = d3 >> 7
; d2 = ..............a1 a0c1c0e1e0g1g0b1 b0d1d0f1f0h1h0a3 a2c3c2e3e2g3g2..

		move.l	d3,d2		;  4
		lsr.l	#7,d2		; 22

; d0 = d3 & 55555555
; d0 = ..a0..c0..e0..g0 ..b0..d0..f0..h0 ..a2..c2..e2..g2 ..b2..d2..f2..h2

		move.l	d3,d0		;  4
		and.l	d6,d0		;  8 d6=$55555555

; d3 ^= d0
; d3 = a1..c1..e1..g1.. b1..d1..f1..h1.. a3..c3..e3..g3.. b3..d3..f3..h3..

		eor.l	d0,d3		;  8

; d4 = d2 & 55555555
; d4 = ..............a1 ..c1..e1..g1..b1 ..d1..f1..h1..a3 ..c3..e3..g3....

		move.l	d2,d4		;  4
		and.l	d6,d4		;  8 d6=$55555555

; d2 ^= d4
; d2 = ................ a0..c0..e0..g0.. b0..d0..f0..h0.. a2..c2..e2..g2..

		eor.l	d4,d2		;  8

; d3 = (d3 | d4) >> 1
; d3 = ................ a1b1c1d1e1f1g1h1 ................ a3b3c3d3e3f3g3h3

		or.l	d4,d3		;  8
		lsr.l	#1,d3		; 10

		move.b	d3,(plsiz,a4)	; 12 plane 3
		swap	d3		;  4
		move.b	d3,(a3)+	;  8 plane 1

; d2 = d2 | d0
; d2 = ................ a0b0c0d0e0f0g0h0 ................ a2b2c2d2e2f2g2h2

		or.l	d0,d2		;  8

		move.b	d2,(a4)+	;  8 plane 2
		swap	d2		;  4
		move.b	d2,(a1)+	;  8 plane 0

; test if finished

		cmpa.l	a1,a2		;  6
		bne.w	mainloop	; 10	total=536 (67.0 cycles/pixel)

		movem.l	(sp)+,d2-d7/a2-a6

		rts

;-----------------------------------------------------------------------------

		end

                            O /
------CUT-OUT----------------X-----------------------------------------------
                            O \

		xdef	_chunky2planar

; peterm/chunky4.s

; Basically the same as peterm/chunky3.s, except use Chris Hames' idea
; of temporary FAST buffers to allow longword writes to CHIP RAM.

;-----------------------------------------------------------------------------
; chunky2planar:	(new Motorola syntax)
;  a0 -> chunky pixels
;  a1 -> plane0 (assume other 7 planes are allocated contiguously)


width		equ	320		; must be a multiple of 32
height		equ	200
plsiz		equ	(width/8)*height

_chunky2planar:

		movem.l	d2-d7/a2-a6,-(sp)

		move.w	sp,d0
		and.w	#2,d0
		add.w	#32,d0		; make room on stack for
		suba.w	d0,sp		; 32-byte longword aligned buffer
		movea.l	sp,a3		; pointed to by a3
		move.w	d0,-(sp)	; and save the allocated size
		move.w	#plsiz/4,-(sp)	; outer loop counter on stack

	iflt 4*plsiz-4-32768
		adda.w	#3*plsiz,a1	; a1 -> start of plane 3
	else
	iflt 2*plsiz-4-32768
		adda.w	#1*plsiz,a1	; a1 -> start of plane 1
	endc
	endc

; set up register constants

		move.l	#$0f0f0f0f,d5	; d5 = constant $0f0f0f0f
		move.l	#$55555555,d6	; d6 = constant $55555555
		move.l	#$3333cccc,d7	; d7 = constant $3333cccc
		lea	(4,a3),a2	; used for inner loop end test

; load up address registers with buffer ptrs

		lea	(2*4,a3),a4	; a4 -> plane2buf
		lea	(2*4,a4),a5	; a5 -> plane4buf
		lea	(2*4,a5),a6	; a6 -> plane6buf

; main loop (starts here) processes 8 chunky pixels at a time

mainloop:

; d0 = a7a6a5a4a3a2a1a0 b7b6b5b4b3b2b1b0 c7c6c5c4c3c2c1c0 d7d6d5d4d3d2d1d0

		move.l	(a0)+,d0	; 12 get next 4 chunky pixels in d0

; d1 = e7e6e5e4e3e2e1e0 f7f6f5f4f3f2f1f0 g7g6g5g4g3g2g1g0 h7h6h5h4h3h2h1h0

		move.l	(a0)+,d1	; 12 get next 4 chunky pixels in d1

; d2 = d0 & 0f0f0f0f
; d2 = ........a3a2a1a0 ........b3b2b1b0 ........c3c2c1c0 ........d3d2d1d0

		move.l	d0,d2		;  4
		and.l	d5,d2		;  8 d5=$0f0f0f0f

; d0 ^= d2
; d0 = a7a6a5a4........ b7b6b5b4........ c7c6c5c4........ d7d6d5d4........

		eor.l	d2,d0		;  8

; d3 = d1 & 0f0f0f0f
; d3 = ........e3e2e1e0 ........f3f2f1f0 ........g3g2g1g0 ........h3h2h1h0

		move.l	d1,d3		;  4
		and.l	d5,d3		;  8 d5=$0f0f0f0f

; d1 ^= d3
; d1 = e7e6e5e4........ f7f6f5f4........ g7g6g5g4........ h7h6h5h4........

		eor.l	d3,d1		;  8

; d2 = (d2 << 4) | d3
; d2 = a3a2a1a0e3e2e1e0 b3b2b1b0f3f2f1f0 c3c2c1c0g3g2g1g0 d3d2d1d0h3h2h1h0

		lsl.l	#4,d2		; 16
		or.l	d3,d2		;  8

; d0 = d0 | (d1 >> 4)
; d0 = a7a6a5a4e7e6e5e4 b7b6b5b4f7f6f5f4 c7c6c5c4g7g6g5g4 d7d6d5d4h7h6h5h4

		lsr.l	#4,d1		; 16
		or.l	d1,d0		;  8

; d3 = ((d2 & 33330000) << 2) | (swap(d2) & 3333cccc) | ((d2 & 0000cccc) >> 2)
; d3 = a1a0c1c0e1e0g1g0 b1b0d1d0f1f0h1h0 a3a2c3c2e3e2g3g2 b3b2d3d2f3f2h3h2

		move.l	d2,d3		;  4
		and.l	d7,d3		;  8 d7=$3333cccc
		move.w	d3,d1		;  4
		clr.w	d3		;  4
		lsl.l	#2,d3		; 12
		lsr.w	#2,d1		; 10
		or.w	d1,d3		;  4
		swap	d2		;  4
		and.l	d7,d2		;  8 d7=$3333cccc
		or.l	d2,d3		;  8

; d1 = ((d0 & 33330000) << 2) | (swap(d0) & 3333cccc) | ((d0 & 0000cccc) >> 2)
; d1 = a5a4c5c4e5e4g5g4 b5b4d5d4f5f4h5h4 a7a6c7c6e7e6g7g6 b7b6d7d6f7f6h7h6

		move.l	d0,d1		;  4
		and.l	d7,d1		;  8 d7=$3333cccc
		move.w	d1,d2		;  4
		clr.w	d1		;  4
		lsl.l	#2,d1		; 12
		lsr.w	#2,d2		; 10
		or.w	d2,d1		;  4
		swap	d0		;  4
		and.l	d7,d0		;  8 d7=$3333cccc
		or.l	d0,d1		;  8

; d2 = d1 >> 7
; d2 = ..............a5 a4c5c4e5e4g5g4b5 b4d5d4f5f4h5h4a7 a6c7c6e7e6g7g6..

		move.l	d1,d2		;  4
		lsr.l	#7,d2		; 22

; d0 = d1 & 55555555
; d0 = ..a4..c4..e4..g4 ..b4..d4..f4..h4 ..a6..c6..e6..g6 ..b6..d6..f6..h6

		move.l	d1,d0		;  4
		and.l	d6,d0		;  8 d6=$55555555

; d1 ^= d0
; d1 = a5..c5..e5..g5.. b5..d5..f5..h5.. a7..c7..e7..g7.. b7..d7..f7..h7..

		eor.l	d0,d1		;  8

; d4 = d2 & 55555555
; d4 = ..............a5 ..c5..e5..g5..b5 ..d5..f5..h5..a7 ..c7..e7..g7....

		move.l	d2,d4		;  4
		and.l	d6,d4		;  8 d6=$55555555

; d2 ^= d4
; d2 = ................ a4..c4..e4..g4.. b4..d4..f4..h4.. a6..c6..e6..g6..

		eor.l	d4,d2		;  8

; d1 = (d1 | d4) >> 1
; d1 = ................ a5b5c5d5e5f5g5h5 ................ a7b7c7d7e7f7g7h7

		or.l	d4,d1		;  8
		lsr.l	#1,d1		; 10

		move.b	d1,(4,a6)	; 12 plane 7
		swap	d1		;  4
		move.b	d1,(4,a5)	; 12 plane 5

; d2 |= d0
; d2 = ................ a4b4c4d4e4f4g4h4 ................ a6b6c6d6e6f6g6h6

		or.l	d0,d2		;  8

		move.b	d2,(a6)+	;  8 plane 6
		swap	d2		;  4
		move.b	d2,(a5)+	;  8 plane 4

; d2 = d3 >> 7
; d2 = ..............a1 a0c1c0e1e0g1g0b1 b0d1d0f1f0h1h0a3 a2c3c2e3e2g3g2..

		move.l	d3,d2		;  4
		lsr.l	#7,d2		; 22

; d0 = d3 & 55555555
; d0 = ..a0..c0..e0..g0 ..b0..d0..f0..h0 ..a2..c2..e2..g2 ..b2..d2..f2..h2

		move.l	d3,d0		;  4
		and.l	d6,d0		;  8 d6=$55555555

; d3 ^= d0
; d3 = a1..c1..e1..g1.. b1..d1..f1..h1.. a3..c3..e3..g3.. b3..d3..f3..h3..

		eor.l	d0,d3		;  8

; d4 = d2 & 55555555
; d4 = ..............a1 ..c1..e1..g1..b1 ..d1..f1..h1..a3 ..c3..e3..g3....

		move.l	d2,d4		;  4
		and.l	d6,d4		;  8 d6=$55555555

; d2 ^= d4
; d2 = ................ a0..c0..e0..g0.. b0..d0..f0..h0.. a2..c2..e2..g2..

		eor.l	d4,d2		;  8

; d3 = (d3 | d4) >> 1
; d3 = ................ a1b1c1d1e1f1g1h1 ................ a3b3c3d3e3f3g3h3

		or.l	d4,d3		;  8
		lsr.l	#1,d3		; 10

		move.b	d3,(4,a4)	; 12 plane 3
		swap	d3		;  4
		move.b	d3,(4,a3)	; 12 plane 1

; d2 = d2 | d0
; d2 = ................ a0b0c0d0e0f0g0h0 ................ a2b2c2d2e2f2g2h2

		or.l	d0,d2		;  8

		move.b	d2,(a4)+	;  8 plane 2
		swap	d2		;  4
		move.b	d2,(a3)+	;  8 plane 0

; test if stack buffers are full, loop back if not

		cmpa.l	a3,a2		;  6
		bne.w	mainloop	; 10	total=540 (67.5 cycles/pixel)

; move stack buffers to bitplanes (longword writes) and restore ptrs

	iflt 4*plsiz-4-32768			; a1 points into plane 3
		move.l	(a4),(a1)+		; plane 3
		move.l	(a6),(4*plsiz-4,a1)	; plane 7
		move.l	-(a6),(3*plsiz-4,a1)	; plane 6
		move.l	(a5),(2*plsiz-4,a1)	; plane 5
		move.l	-(a5),(1*plsiz-4,a1)	; plane 4
		move.l	-(a4),(-1*plsiz-4,a1)	; plane 2
		move.l	(a3),(-2*plsiz-4,a1)	; plane 1
		move.l	-(a3),(-3*plsiz-4,a1)	; plane 0
	else
	iflt 2*plsiz-4-32768			; a1 points into plane 1
		move.l	(a3),(a1)+		; plane 1
		adda.l	#4*plsiz,a1
		move.l	(a6),(2*plsiz-4,a1)	; plane 7
		move.l	-(a6),(1*plsiz-4,a1)	; plane 6
		move.l	(a5),(0*plsiz-4,a1)	; plane 5
		move.l	-(a5),(-1*plsiz-4,a1)	; plane 4
		suba.l	#4*plsiz,a1
		move.l	(a4),(2*plsiz-4,a1)	; plane 3
		move.l	-(a4),(1*plsiz-4,a1)	; plane 2
		move.l	-(a3),(-1*plsiz-4,a1)	; plane 0
	else
	iflt plsiz-32768			; a1 points into plane 0
		adda.l	#6*plsiz,a1
		move.l	(a6),(plsiz,a1)		; plane 7
		move.l	-(a6),(a1)		; plane 6
		move.l	(a5),(-plsiz,a1)	; plane 5
		suba.l	#3*plsiz,a1
		move.l	-(a5),(plsiz,a1)	; plane 4
		move.l	(a4),(a1)		; plane 3
		move.l	-(a4),(-plsiz,a1)	; plane 2
		suba.l	#3*plsiz,a1
		move.l	(a3),(plsiz,a1)		; plane 1
		move.l	-(a3),(a1)+		; plane 0
	else
		move.l	#plsiz,d0		; a1 points into plane 0
		adda.l	#7*plsiz,a1
		move.l	(a6),(a1)		; plane 7
		suba.l	d0,a1
		move.l	-(a6),(a1)		; plane 6
		suba.l	d0,a1
		move.l	(a5),(a1)		; plane 5
		suba.l	d0,a1
		move.l	-(a5),(a1)		; plane 4
		suba.l	d0,a1
		move.l	(a4),(a1)		; plane 3
		suba.l	d0,a1
		move.l	-(a4),(a1)		; plane 2
		suba.l	d0,a1
		move.l	(a3),(a1)		; plane 1
		suba.l	d0,a1
		move.l	-(a3),(a1)+		; plane 0
	endc
	endc
	endc

; check if finished, go back for more

		sub.w	#1,(sp)
		bne.w	mainloop

; all done!  restore stack and return

		addq.w	#2,sp			; remove outer loop counter
		adda.w	(sp)+,sp		; remove aligned 32-byte buffer
		movem.l	(sp)+,d2-d7/a2-a6

		rts

;-----------------------------------------------------------------------------

		end

                            O /
------CUT-OUT----------------X-----------------------------------------------
                            O \

; Chunky2Planar algorithm.
;
; 	Cpu only solution VERSION 2
;	Optimised for 040+fastram
;	analyse instruction offsets to check performance

	output	five_pass.o
	opt	l+	;Linkable code
	opt	c+	;Case sensitive
	opt	d-	;No debugging information
	opt	m+	;Expand macros in listing
	opt	o-	;No optimisation

;quad_begin:
;	cnop	0,16

	xdef	_chunky2planar

;  a0 -> chunky pixels
;  a1 -> plane0

width		equ	320		; must be multiple of 32
height		equ	200
plsiz		equ	(width/8)*height


merge	MACRO in1,in2,tmp3,tmp4,mask,shift
	;		\1 = abqr
	;		\2 = ijyz
	move.l	\2,\4
	move.l	#\5,\3
	and.l	\3,\2	\2 = 0j0z
	and.l	\1,\3	\3 = 0b0r
	eor.l	\3,\1	\1 = a0q0
	eor.l	\2,\4	\4 = i0y0
	IFEQ	\6-1
	add.l	\3,\3
	ELSE
	lsl.l	#\6,\3	\3 = b0r0
	ENDC
	lsr.l	#\6,\4	\4 = 0i0y
	or.l	\3,\2	\2 = bjrz
	or.l	\4,\1	\1 = aiqy
	ENDM


_chunky2planar:
	jmp	next
next
	; round down address of c2p
	lea	c2p(pc),a0
	move.l	a0,d0
	and.b	#%11110000,d0
	move.l	d0,a1
	
	; patch jmp
	move.l	d0,_chunky2planar+2
	move.w	#(end-c2p)-1,d0
loop	move.b	(a0)+,(a1)+
	dbra	d0,loop

	;tidy cache
	movem.l	d2-d7/a2-a6,-(sp)	
	move.l	$4.w,a6
	jsr	-636(a6)
	movem.l	(sp)+,d2-d7/a2-a6
	rts
	
	cnop	0,16
c2p:
		movem.l	d2-d7/a2-a6,-(sp)

		; a0 = chunky buffer
		; a1 = output area
		
		lea	4*plsiz(a1),a1	; a1 -> plane4
		
		move.l	a0,d0
		add.l	#16,d0
		and.b	#%11110000,d0
		move.l	d0,a0
		
		move.l	a0,a2
		add.l	#8*plsiz,a2

		lea	p0(pc),a3		
		bra.s	mainloop

	cnop	0,16
mainloop:
	move.l	0(a0),d0
 	move.l	4(a0),d2
 	move.l	8(a0),d1
	move.l	12(a0),d3
	move.l	2(a0),d4
 	move.l	10(a0),d5
	move.l	6(a0),d6
	move.l	14(a0),d7

 	move.w	16(a0),d0
 	move.w	24(a0),d1
	move.w	20(a0),d2
	move.w	28(a0),d3
 	move.w	18(a0),d4
 	move.w	26(a0),d5
	move.w	22(a0),d6
	move.w	30(a0),d7
	
	adda.w	#32,a0
	move.l	d6,a5
	move.l	d7,a6

	merge	d0,d1,d6,d7,$00FF00FF,8
	merge	d2,d3,d6,d7,$00FF00FF,8

	merge	d0,d2,d6,d7,$0F0F0F0F,4	
	merge	d1,d3,d6,d7,$0F0F0F0F,4

	exg.l	d0,a5
	exg.l	d1,a6	
	
	merge	d4,d5,d6,d7,$00FF00FF,8
	merge	d0,d1,d6,d7,$00FF00FF,8
	
	merge	d4,d0,d6,d7,$0F0F0F0F,4
	merge	d5,d1,d6,d7,$0F0F0F0F,4

	merge	d2,d0,d6,d7,$33333333,2
	merge	d3,d1,d6,d7,$33333333,2	

	merge	d2,d3,d6,d7,$55555555,1
	merge	d0,d1,d6,d7,$55555555,1
	move.l	d3,2*4(a3)	;plane2
	move.l	d2,3*4(a3)	;plane3
	move.l	d1,0*4(a3)	;plane0
	move.l	d0,1*4(a3)	;plane1

	move.l	a5,d2
	move.l	a6,d3

	merge	d2,d4,d6,d7,$33333333,2
	merge	d3,d5,d6,d7,$33333333,2

	merge	d2,d3,d6,d7,$55555555,1
	merge	d4,d5,d6,d7,$55555555,1
	move.l	d3,6*4(a3)		;bitplane6
	move.l	d2,7*4(a3)		;bitplane7
	move.l	d5,4*4(a3)		;bitplane4
	move.l	d4,5*4(a3)		;bitplane5


inner:
	move.l	0(a0),d0
 	move.l	4(a0),d2
 	move.l	8(a0),d1
	move.l	12(a0),d3
	move.l	2(a0),d4
 	move.l	10(a0),d5
	move.l	6(a0),d6
	move.l	14(a0),d7

 	move.w	16(a0),d0
 	move.w	24(a0),d1
	move.w	20(a0),d2
	move.w	28(a0),d3
 	move.w	18(a0),d4
 	move.w	26(a0),d5
	move.w	22(a0),d6
	move.w	30(a0),d7
	
	adda.w	#32,a0
	move.l	d6,a5
	move.l	d7,a6

	; write	bitplane 7	

	move.l	2*4(a3),-2*plsiz(a1)	;plane2
	merge	d0,d1,d6,d7,$00FF00FF,8
	merge	d2,d3,d6,d7,$00FF00FF,8

	; write	
	move.l	3*4(a3),-plsiz(a1)	;plane3
	merge	d0,d2,d6,d7,$0F0F0F0F,4	
	merge	d1,d3,d6,d7,$0F0F0F0F,4

	exg.l	d0,a5
	exg.l	d1,a6	
	
	; write
	move.l	0*4(a3),-4*plsiz(a1)	;plane0
	merge	d4,d5,d6,d7,$00FF00FF,8
	merge	d0,d1,d6,d7,$00FF00FF,8
	
	; write	
	move.l	1*4(a3),-3*plsiz(a1) ;plane1
	merge	d4,d0,d6,d7,$0F0F0F0F,4
	merge	d5,d1,d6,d7,$0F0F0F0F,4

	; write	
	move.l	6*4(a3),2*plsiz(a1)	;bitplane6
	merge	d2,d0,d6,d7,$33333333,2
	merge	d3,d1,d6,d7,$33333333,2	

	; write
	move.l	7*4(a3),3*plsiz(a1)	;bitplane7
	merge	d2,d3,d6,d7,$55555555,1
	merge	d0,d1,d6,d7,$55555555,1
	move.l	d3,2*4(a3)	;plane2
	move.l	d2,3*4(a3)	;plane3
	move.l	d1,0*4(a3)	;plane0
	move.l	d0,1*4(a3)	;plane1

	move.l	a5,d2
	move.l	a6,d3

	move.l	4*4(a3),(a1)+		;bitplane4	
	merge	d2,d4,d6,d7,$33333333,2
	merge	d3,d5,d6,d7,$33333333,2

	move.l	5*4(a3),-4+1*plsiz(a1)	;bitplane5
	merge	d2,d3,d6,d7,$55555555,1
	merge	d4,d5,d6,d7,$55555555,1
	move.l	d3,6*4(a3)		;bitplane6
	move.l	d2,7*4(a3)		;bitplane7
	move.l	d5,4*4(a3)		;bitplane4
	move.l	d4,5*4(a3)		;bitplane5

	cmpa.l	a0,a2
	bne.w	inner

	move.l	2*4(a3),-2*plsiz(a1)	;plane2
	move.l	3*4(a3),-plsiz(a1)	;plane3
	move.l	0*4(a3),-4*plsiz(a1)	;plane0
	move.l	1*4(a3),-3*plsiz(a1) 	;plane1
	move.l	6*4(a3),2*plsiz(a1)	;bitplane6
	move.l	7*4(a3),3*plsiz(a1)	;bitplane7
	move.l	4*4(a3),(a1)+		;bitplane4	
	move.l	5*4(a3),-4+1*plsiz(a1)	;bitplane5

exit
	movem.l	(sp)+,d2-d7/a2-a6
	rts

	cnop	0,4
end:
p0	dc.l	0
p1	dc.l	0
p2	dc.l	0
p3	dc.l	0
p4	dc.l	0
p5	dc.l	0
p6	dc.l	0
p7	dc.l	0

                            O /
------CUT-OUT----------------X-----------------------------------------------
                            O \

; Chunky2Planar algorithm. [writes pipelined a little]
;
; 	Cpu only solution
;	Optimised for 020+fastram
;	Aim for less than 90ms for 320x200x256 on 14MHz 020

	output	five_pass.o
	opt	l+	;Linkable code
	opt	c+	;Case sensitive
	opt	d-	;No debugging information
	opt	m+	;Expand macros in listing
	opt	o-	;No optimisation
	
	xdef	_chunky2planar
		
;  a0 -> chunky pixels
;  a1 -> plane0

width		equ	320		; must be multiple of 32
height		equ	200
plsiz		equ	(width/8)*height

		_chunky2planar:
		;a0 = chunky buffer
		;a1 = first bitplane
		
	movem.l	d2-d7/a2-a6,-(sp)
	move.l	a0,a2
	add.l	#plsiz*8,a2	;a2 = end of chunky buffer
	
	;; Sweep thru the whole chunky data once,
	;; Performing 3 merge operations on it.
	
	move.l	#$00ff00ff,a3	; load byte merge mask
	move.l	#$0f0f0f0f,a4	; load nibble merge mask
	
firstsweep
	 movem.l (a0),d0-d7      ;8+4n   40      cycles
	 move.l  d4,a6           a6 = CD
	 move.w  d0,d4           d4 = CB
	 swap    d4              d4 = BC
	 move.w  d4,d0           d0 = AC
	 move.w  a6,d4           d4 = BD
	 move.l  d5,a6           a6 = CD
	 move.w  d1,d5           d5 = CB
	 swap    d5              d5 = BC
	 move.w  d5,d1           d1 = AC
	 move.w  a6,d5           d5 = BD
	 move.l  d6,a6           a6 = CD
	 move.w  d2,d6           d6 = CB
	 swap    d6              d6 = BC
	 move.w  d6,d2           d2 = AC
	 move.w  a6,d6           d6 = BD
	 move.l  d7,a6           a6 = CD
	 move.w  d3,d7           d7 = CB
	 swap    d7              d7 = BC
	 move.w  d7,d3           d3 = AC
	 move.w  a6,d7           d7 = BD
	 move.l  d7,a6
	 move.l  d6,a5
	 move.l  a3,d6   ; d6 = 0x0x
	 move.l  a3,d7   ; d7 = 0x0x
	 and.l   d0,d6   ; d6 = 0b0r
	 and.l   d2,d7   ; d7 = 0j0z
	 eor.l   d6,d0   ; d0 = a0q0
	 eor.l   d7,d2   ; d2 = i0y0
	 lsl.l   #8,d6   ; d6 = b0r0
	 lsr.l   #8,d2   ; d2 = 0i0y
	 or.l    d2,d0           ; d0 = aiqy
	 or.l    d7,d6           ; d2 = bjrz
	 move.l  a3,d7   ; d7 = 0x0x
	 move.l  a3,d2   ; d2 = 0x0x
	 and.l   d1,d7   ; d7 = 0b0r
	 and.l   d3,d2   ; d2 = 0j0z
	 eor.l   d7,d1   ; d1 = a0q0
	 eor.l   d2,d3   ; d3 = i0y0
	 lsl.l   #8,d7   ; d7 = b0r0
	 lsr.l   #8,d3   ; d3 = 0i0y
	 or.l    d3,d1           ; d1 = aiqy
	 or.l    d2,d7           ; d3 = bjrz

	 move.l  a4,d2   ; d2 = 0x0x
	 move.l  a4,d3   ; d3 = 0x0x
	 and.l   d0,d2   ; d2 = 0b0r
	 and.l   d1,d3   ; d3 = 0j0z
	 eor.l   d2,d0   ; d0 = a0q0
	 eor.l   d3,d1   ; d1 = i0y0
	 lsr.l   #4,d1   ; d1 = 0i0y
	 or.l    d1,d0           ; d0 = aiqy
	 move.l  d0,(a0)+
	 lsl.l	#4,d2
	 or.l    d3,d2           ; d1 = bjrz
	 move.l	d2,(a0)+
	
	 move.l  a4,d3   ; d3 = 0x0x
	 move.l  a4,d1   ; d1 = 0x0x
	 and.l   d6,d3   ; d3 = 0b0r
	 and.l   d7,d1   ; d1 = 0j0z
	 eor.l   d3,d6   ; d6 = a0q0
	 eor.l   d1,d7   ; d7 = i0y0
	 lsr.l   #4,d7   ; d7 = 0i0y
	 or.l    d7,d6           ; d6 = aiqy
	 move.l	d6,(a0)+
	 lsl.l	#4,d3
	 or.l    d1,d3           ; d7 = bjrz
	 move.l	d3,(a0)+
	
;	 move.l  d0,(a0)+
;	 move.l  d2,(a0)+
;	 move.l  d6,(a0)+
;	 move.l  d3,(a0)+
	 move.l  a6,d7
	 move.l  a5,d6
	 move.l  a3,d0   ; d0 = 0x0x
	 move.l  a3,d1   ; d1 = 0x0x
	 and.l   d4,d0   ; d0 = 0b0r
	 and.l   d6,d1   ; d1 = 0j0z
	 eor.l   d0,d4   ; d4 = a0q0
	 eor.l   d1,d6   ; d6 = i0y0
	 lsl.l   #8,d0   ; d0 = b0r0
	 lsr.l   #8,d6   ; d6 = 0i0y
	 or.l    d6,d4           ; d4 = aiqy
	 or.l    d1,d0           ; d6 = bjrz
	 move.l  a3,d1   ; d1 = 0x0x
	 move.l  a3,d6   ; d6 = 0x0x
	 and.l   d5,d1   ; d1 = 0b0r
	 and.l   d7,d6   ; d6 = 0j0z
	 eor.l   d1,d5   ; d5 = a0q0
	 eor.l   d6,d7   ; d7 = i0y0
	 lsl.l   #8,d1   ; d1 = b0r0
	 lsr.l   #8,d7   ; d7 = 0i0y
	 or.l    d7,d5           ; d5 = aiqy
	 or.l    d6,d1           ; d7 = bjrz
	 move.l  a4,d6   ; d6 = 0x0x
	 move.l  a4,d7   ; d7 = 0x0x
	 and.l   d4,d6   ; d6 = 0b0r
	 and.l   d5,d7   ; d7 = 0j0z
	 eor.l   d6,d4   ; d4 = a0q0
	 eor.l   d7,d5   ; d5 = i0y0
	 lsr.l   #4,d5   ; d5 = 0i0y
	 or.l    d5,d4           ; d4 = aiqy
	 move.l  d4,(a0)+
	 lsl.l   #4,d6   ; d6 = b0r0
	 or.l    d7,d6           ; d5 = bjrz
	 move.l  d6,(a0)+
	
	 move.l  a4,d7   ; d7 = 0x0x
	 move.l  a4,d5   ; d5 = 0x0x
	 and.l   d0,d7   ; d7 = 0b0r
	 and.l   d1,d5   ; d5 = 0j0z
	 eor.l   d7,d0   ; d0 = a0q0
	 eor.l   d5,d1   ; d1 = i0y0
	 lsr.l   #4,d1   ; d1 = 0i0y
	 or.l    d1,d0           ; d0 = aiqy
	 move.l  d0,(a0)+
	 lsl.l   #4,d7   ; d7 = b0r0
	 or.l    d5,d7           ; d1 = bjrz
	 move.l  d7,(a0)+
	 cmp.l   a0,a2           ;; 4c
	 bne.w   firstsweep      ;; 6c
	
	 sub.l   #plsiz*8,a0
	 move.l  #$33333333,a5
	 move.l  #$55555555,a6
	 lea     plsiz*4(a1),a1  ;a2 = plane4
	
secondsweep
	 move.l  (a0),d0
	 move.l  8(a0),d1
	 move.l  16(a0),d2
	 move.l  24(a0),d3
	
	 move.l  a5,d6   ; d6 = 0x0x
	 move.l  a5,d7   ; d7 = 0x0x
	 and.l   d0,d6   ; d6 = 0b0r
	 and.l   d2,d7   ; d7 = 0j0z
	 eor.l   d6,d0   ; d0 = a0q0
	 eor.l   d7,d2   ; d2 = i0y0
	 lsl.l   #2,d6   ; d6 = b0r0
	 lsr.l   #2,d2   ; d2 = 0i0y
	 or.l    d2,d0           ; d0 = aiqy
	 or.l    d7,d6           ; d2 = bjrz
	 move.l  a5,d7   ; d7 = 0x0x
	 move.l  a5,d2   ; d2 = 0x0x
	 and.l   d1,d7   ; d7 = 0b0r
	 and.l   d3,d2   ; d2 = 0j0z
	 eor.l   d7,d1   ; d1 = a0q0
	 eor.l   d2,d3   ; d3 = i0y0
	 lsl.l   #2,d7   ; d7 = b0r0
	 lsr.l   #2,d3   ; d3 = 0i0y
	 or.l    d3,d1           ; d1 = aiqy
	 or.l    d2,d7           ; d3 = bjrz
	 move.l  a6,d2   ; d2 = 0x0x
	 move.l  a6,d3   ; d3 = 0x0x
	 and.l   d0,d2   ; d2 = 0b0r
	 and.l   d1,d3   ; d3 = 0j0z
	 eor.l   d2,d0   ; d0 = a0q0
	 eor.l   d3,d1   ; d1 = i0y0
	 lsr.l   #1,d1   ; d1 = 0i0y
	 or.l    d1,d0           ; d0 = aiqy
	 move.l  d0,plsiz*3(a1)
	 add.l   d2,d2
	 or.l    d3,d2           ; d1 = bjrz
	 move.l  d2,plsiz*2(a1)

	 move.l  a6,d3   ; d3 = 0x0x
	 move.l  a6,d1   ; d1 = 0x0x
	 and.l   d6,d3   ; d3 = 0b0r
	 and.l   d7,d1   ; d1 = 0j0z
	 eor.l   d3,d6   ; d6 = a0q0
	 eor.l   d1,d7   ; d7 = i0y0
	 lsr.l   #1,d7   ; d7 = 0i0y
	 or.l    d7,d6           ; d6 = aiqy
	 move.l  d6,plsiz*1(a1)
	 add.l   d3,d3
	 or.l    d1,d3           ; d7 = bjrz
	 move.l  d3,(a1)+
	 
	 move.l  4(a0),d0
	 move.l  12(a0),d1
	 move.l  20(a0),d2
	 move.l  28(a0),d3
	
	 move.l  a5,d6   ; d6 = 0x0x
	 move.l  a5,d7   ; d7 = 0x0x
	 and.l   d0,d6   ; d6 = 0b0r
	 and.l   d2,d7   ; d7 = 0j0z
	 eor.l   d6,d0   ; d0 = a0q0
	 eor.l   d7,d2   ; d2 = i0y0
	 lsl.l   #2,d6   ; d6 = b0r0
	 lsr.l   #2,d2   ; d2 = 0i0y
	 or.l    d2,d0           ; d0 = aiqy
	 or.l    d7,d6           ; d2 = bjrz
	 move.l  a5,d7   ; d7 = 0x0x
	 move.l  a5,d2   ; d2 = 0x0x
	 and.l   d1,d7   ; d7 = 0b0r
	 and.l   d3,d2   ; d2 = 0j0z
	 eor.l   d7,d1   ; d1 = a0q0
	 eor.l   d2,d3   ; d3 = i0y0
	 lsl.l   #2,d7   ; d7 = b0r0
	 lsr.l   #2,d3   ; d3 = 0i0y
	 or.l    d3,d1           ; d1 = aiqy
	 or.l    d2,d7           ; d3 = bjrz
	 move.l  a6,d2   ; d2 = 0x0x
	 move.l  a6,d3   ; d3 = 0x0x
	 and.l   d0,d2   ; d2 = 0b0r
	 and.l   d1,d3   ; d3 = 0j0z
	 eor.l   d2,d0   ; d0 = a0q0
	 eor.l   d3,d1   ; d1 = i0y0
	 lsr.l   #1,d1   ; d1 = 0i0y
	 or.l    d1,d0           ; d0 = aiqy
	 move.l  d0,-4-plsiz*1(a1)
	 add.l   d2,d2
	 or.l    d3,d2           ; d1 = bjrz
	 move.l  d2,-4-plsiz*2(a1)

	 move.l  a6,d3   ; d3 = 0x0x
	 move.l  a6,d1   ; d1 = 0x0x
	 and.l   d6,d3   ; d3 = 0b0r
	 and.l   d7,d1   ; d1 = 0j0z
	 eor.l   d3,d6   ; d6 = a0q0
	 eor.l   d1,d7   ; d7 = i0y0
	 lsr.l   #1,d7   ; d7 = 0i0y
	 or.l    d7,d6           ; d6 = aiqy
	 move.l  d6,-4-plsiz*3(a1)
	 add.l   d3,d3
	 or.l    d1,d3           ; d7 = bjrz
	 move.l  d3,-4-plsiz*4(a1)
	 add.w   #32,a0  ;;4c
	 cmp.l   a0,a2   ;;4c
	 bne.w   secondsweep     ;;6c
	
	;300
	
exit	
	movem.l	(sp)+,d2-d7/a2-a6
	rts
	
                            O /
------CUT-OUT----------------X-----------------------------------------------
                            O \

; Chunky2Planar algorithm.
;
; 	Cpu only solution
;	Optimised for 020+fastram
;	Aim for less than 90ms for 320x200x256 on 14MHz 020

	output	five_pass.o
	opt	l+	;Linkable code
	opt	c+	;Case sensitive
	opt	d-	;No debugging information
	opt	m+	;Expand macros in listing
	opt	o-	;No optimisation
	
	xdef	_chunky2planar
		
;  a0 -> chunky pixels
;  a1 -> plane0

width		equ	320		; must be multiple of 32
height		equ	200
plsiz		equ	(width/8)*height

wordmerge	macro
	; i1	i2	tmp
	; \1	\2	\3
;; speedup			\1 AB \2 CD
	move.l	\2,\3		\3 = CD
	move.w	\1,\2		\2 = CB
	swap	\2		\2 = BC
	move.w	\2,\1		\1 = AC
	move.w	\3,\2		\2 = BD
	endm

		
merge	macro	;	i1	i2	t3	t4	m	s
		;	\1	\2	\3	\4	\5	\6
		;	output as \1,\3
			; \1 = abqr
			; \2 = ijyz
	move.l	\5,\3	; \3 = 0x0x
	move.l	\5,\4	; \4 = 0x0x
	and.l	\1,\3	; \3 = 0b0r
	and.l	\2,\4	; \4 = 0j0z
	eor.l	\3,\1	; \1 = a0q0
	eor.l	\4,\2	; \2 = i0y0
	IFEQ	\6-1
	add.l	\3,\3
	ELSE
	lsl.l	#\6,\3	; \3 = b0r0
	ENDC
	lsr.l	#\6,\2	; \2 = 0i0y
	or.l	\2,\1		; \1 = aiqy
	or.l	\4,\3		; \2 = bjrz
	endm
		
_chunky2planar:
		;a0 = chunky buffer
		;a1 = first bitplane
		
	movem.l	d2-d7/a2-a6,-(sp)
	move.l	a0,a2
	add.l	#plsiz*8,a2	;a2 = end of chunky buffer
	
	;; Sweep thru the whole chunky data once,
	;; Performing 3 merge operations on it.
	
	move.l	#$00ff00ff,a3	; load byte merge mask
	move.l	#$0f0f0f0f,a4	; load nibble merge mask
	
firstsweep

	; pass 1
	movem.l	(a0),d0-d7	;8+4n 	40	cycles
	; d0-7 = abcd efgh ijkl mnop qrst uvwx yzAB CDEF
	;; 40c
	
	wordmerge	d0,d4,a6	;d0/4 = abqr cdst
	wordmerge	d1,d5,a6	;d1/5 = efuv ghwx
	wordmerge	d2,d6,a6	;d2/6 = ijyz klAB
	wordmerge	d3,d7,a6 	;d3/7 = mnCD opEF
	;; 4*14c

	; save off a bit of shit
	move.l	d7,a6
	move.l	d6,a5
	;; 4c
		
	; pass 2
	merge	d0,d2,d6,d7,a3,8	;d0/d6 = aiqy bjrz
	merge	d1,d3,d7,d2,a3,8	;d1/d7 = emuc fnvD
	;; 2*24
	
	; pass 3
	merge	d0,d1,d2,d3,a4,4	;d0/d2  = ae74... ae30...
	merge	d6,d7,d3,d1,a4,4	;d6/d3  = bf74... bf30...
	;; 2*24
	
	move.l	d0,(a0)+
	move.l	d2,(a0)+
	move.l	d6,(a0)+
	move.l	d3,(a0)+
	;; 4*4c
	
	; bring it back
	move.l	a6,d7
	move.l	a5,d6
	;; 2*2c
		
	; pass 2
	merge	d4,d6,d0,d1,a3,8	;d4/d0 = cksA dltB
	merge	d5,d7,d1,d6,a3,8	;d5/d1 = gowE hpxF
	;; 2*24c
	
	; pass 3			
	merge	d4,d5,d6,d7,a4,4	;d4/d6 = cg74.. cg30..
	merge	d0,d1,d7,d5,a4,4	;d0/d7 = dh74.. dh30..
	;; 2*24c
		
	move.l	d4,(a0)+
	move.l	d6,(a0)+
	move.l	d0,(a0)+
	move.l	d7,(a0)+
	;; 4*4c
	
	cmp.l	a0,a2		;; 4c
	bne.w	firstsweep	;; 6c

	;; 338
	
	; (a0) 	ae74.. ae30.. bf74.. bf30.. cg74.. cg30.. dh74.. dh30..

;	bra.w	exit
	
	sub.l	#plsiz*8,a0
	move.l	#$33333333,a5
	move.l	#$55555555,a6


	lea	plsiz*4(a1),a1	;a2 = plane4
	
secondsweep

	move.l	(a0),d0
	move.l	8(a0),d1
	move.l	16(a0),d2
	move.l	24(a0),d3
	;; 6+3*7
	
	;; pass 4	
	merge	d0,d2,d6,d7,a5,2	;d0/d6 = aceg76.. aceg54..
	merge	d1,d3,d7,d2,a5,2	;d1/d7 = bdhf76.. bdhf54..
	;; 24*2c
	
	;; pass 5	
	merge	d0,d1,d2,d3,a6,1	;d0/d2 = abcd7... abcd6...
	merge	d6,d7,d3,d1,a6,1	;d6/d3 = abcd5... abcd4...
	;; 24*2c

	move.l	d0,plsiz*3(a1)
	move.l	d2,plsiz*2(a1)
	move.l	d6,plsiz*1(a1)
	move.l	d3,(a1)+
	;;3*5+4c
		
	move.l	4(a0),d0
	move.l	12(a0),d1
	move.l	20(a0),d2
	move.l	28(a0),d3
	;;4*7c
	;; pass 4	
	merge	d0,d2,d6,d7,a5,2	;d0/d6 = aceg32.. aceg10..
	merge	d1,d3,d7,d2,a5,2	;d1/d7 = bdhf32.. bdhf10..
	;;2*24
	;; pass 5	
	merge	d0,d1,d2,d3,a6,1	;d0/d2 = abcd3... abcd2...
	merge	d6,d7,d3,d1,a6,1	;d6/d3 = abcd1... abcd0...
	;;2*24
	
	move.l	d0,-4-plsiz*1(a1)
	move.l	d2,-4-plsiz*2(a1)
	move.l	d6,-4-plsiz*3(a1)
	move.l	d3,-4-plsiz*4(a1)
	;;4*5
	
	add.w	#32,a0	;;4c
	cmp.l	a0,a2	;;4c
	bne.w	secondsweep	;;6c

	;300
	
exit	
	movem.l	(sp)+,d2-d7/a2-a6
	rts
	
                            O /
------CUT-OUT----------------X-----------------------------------------------
                            O \

;bltcon0     EQU   $040
;bltcon1     EQU   $042
;bltafwm     EQU   $044
;bltalwm     EQU   $046
bltcpt	    EQU   $048
bltbpt	    EQU   $04C
bltapt	    EQU   $050
bltdpt	    EQU   $054
;bltsize     EQU   $058
;bltcon0l    EQU   $05B		; note: byte access only
bltsizv     EQU   $05C
bltsizh     EQU   $05E
;
;bltcmod     EQU   $060
;bltbmod     EQU   $062
;bltamod     EQU   $064
;bltdmod     EQU   $066
;
;bltcdat     EQU   $070
;bltbdat     EQU   $072
;bltadat     EQU   $074


	xdef	_BlitterConvert

;note: destination bitplanes have to be in this order: 7, 3, 5, 1, 6, 2, 4, 0
;      and the chunky buffer must be in chip
;      this routine is best used on machines with a slow CPU and chipram only

; void __asm BlitterConvert (register __d2 UBYTE *chunky,
;                            register __d3 PLANEPTR raster,
;                            register __a6 struct GfxBase *GfxBase);


Width	= 320	; must be a multiple of 16
Height	= 200
Depth	= 8
BplSize = Width/8*Height
Size	= Width/8*Height*Depth
Pixels	= Width*Height


_BlitterConvert:

	movem.l	d2-d3/a5,-(sp)

	jsr	_LVOOwnBlitter(a6)
	lea	($dff000),a5


	;PASS-1

	;subpass1
	jsr	_LVOWaitBlit(a6)

	moveq	#-1,d0
	move.l	d0,bltafwm(a5)

	move.w	#0,bltdmod(a5)

	move.l	d2,bltapt(a5)		; Chunky
	addq.l	#8,d2
	move.l	d2,bltbpt(a5)		; Chunky+8

	move.l	#Buff1,bltdpt(a5)

	move.w	#8,bltamod(a5)
	move.w	#8,bltbmod(a5)

	move.w	#%1111111100000000,bltcdat(a5)
	move.l	#$0DE48000,bltcon0(a5)	;D=AC+Bc [C const]

	move.w	#Pixels/16,bltsizv(a5)
	move.w	#4,bltsizh(a5)		;do blit

	;subpass2
	jsr	_LVOWaitBlit(a6)

	add.l	#Size-8-2-8,d2
	move.l	d2,bltapt(a5)		; Chunky+Size-8-2
	addq.l	#8,d2
	move.l	d2,bltbpt(a5)		; Chunky+Size-2

	move.l	#Buff1+Size-2,bltdpt(a5)

	move.l	#$8DE40002,bltcon0(a5)	;D=AC+Bc [C const], descending mode

	move.w	#4,bltsizh(a5)		;do blit


	;PASS-2

	;subpass1
	jsr	_LVOWaitBlit(a6)

	move.l	#Buff1,bltapt(a5)
	move.l	#Buff1+4,bltbpt(a5)

	move.l	#Buff2,bltdpt(a5)

	move.w	#4,bltamod(a5)
	move.w	#4,bltbmod(a5)

	move.w	#%1111000011110000,bltcdat(a5)
	move.l	#$0DE44000,bltcon0(a5)	;D=AC+Bc [C const]

	move.w	#Pixels/8,bltsizv(a5)
	move.w	#2,bltsizh(a5)		;do blit

	;subpass2
	jsr	_LVOWaitBlit(a6)

	move.l	#Buff1+Size-2-4,bltapt(a5)
	move.l	#Buff1+Size-2,bltbpt(a5)

	move.l	#Buff2+Size-2,bltdpt(a5)

	move.l	#$4DE40002,bltcon0(a5)	;D=AC+Bc [C const], descending mode

	move.w	#2,bltsizh(a5)		;do blit


	;PASS-3

	;subpass1
	jsr	_LVOWaitBlit(a6)

	move.l	#Buff2,bltapt(a5)
	move.l	#Buff2+2,bltbpt(a5)

	move.l	#Buff3,bltdpt(a5)

	move.w	#2,bltamod(a5)
	move.w	#2,bltbmod(a5)
	move.w	#Pixels/4,bltsizv(a5)
	move.w	#%1100110011001100,bltcdat(a5)

	move.l	#$0DE42000,bltcon0(a5)	;D=AC+Bc [C const]

	move.w	#1,bltsizh(a5)		;do blit

	;subpass2
	jsr	_LVOWaitBlit(a6)

	move.l	#Buff2+Size-2-2,bltapt(a5)
	move.l	#Buff2+Size-2,bltbpt(a5)

	move.l	#Buff3+Size-2,bltdpt(a5)

	move.l	#$2DE40002,bltcon0(a5)	;D=AC+Bc [C const], descending mode
	move.w	#1,bltsizh(a5)		;do blit


	;PASS-4

	;subpass1
	jsr	_LVOWaitBlit(a6)

	move.l	#Buff3,bltapt(a5)
	move.l	#Buff3+1*Size/8,bltbpt(a5)

	move.l	d3,bltdpt(a5)		; Planes
	move.w	#0,bltamod(a5)
	move.w	#0,bltbmod(a5)
	move.w	#Size/16,bltsizv(a5)	;/8???
	move.w	#%1010101010101010,bltcdat(a5)

	move.l	#$0DE41000,bltcon0(a5)	;D=AC+Bc [C const]
	move.w	#1,bltsizh(a5)		;do blit

	jsr	_LVOWaitBlit(a6)
	move.l	#Buff3+2*Size/8,bltapt(a5)
	move.l	#Buff3+3*Size/8,bltbpt(a5)
	move.w	#1,bltsizh(a5)

	jsr	_LVOWaitBlit(a6)
	move.l	#Buff3+4*Size/8,bltapt(a5)
	move.l	#Buff3+5*Size/8,bltbpt(a5)
	move.w	#1,bltsizh(a5)

	jsr	_LVOWaitBlit(a6)
	move.l	#Buff3+6*Size/8,bltapt(a5)
	move.l	#Buff3+7*Size/8,bltbpt(a5)
	move.w	#1,bltsizh(a5)

	;subpass2
	jsr	_LVOWaitBlit(a6)

	move.l	#Buff3+7*Size/8-2,bltapt(a5)
	move.l	#Buff3+8*Size/8-2,bltbpt(a5)

	add.l	#Size-2,d3
	move.l	d3,bltdpt(a5)		; Planes+Size-2

	move.l	#$1DE40002,bltcon0(a5)	;D=AC+Bc [C const], descending mode
	move.w	#1,bltsizh(a5)		;do blit

	jsr	_LVOWaitBlit(a6)
	move.l	#Buff3+5*Size/8-2,bltapt(a5)
	move.l	#Buff3+6*Size/8-2,bltbpt(a5)
	move.w	#1,bltsizh(a5)		

	jsr	_LVOWaitBlit(a6)
	move.l	#Buff3+3*Size/8-2,bltapt(a5)
	move.l	#Buff3+4*Size/8-2,bltbpt(a5)
	move.w	#1,bltsizh(a5)		

	jsr	_LVOWaitBlit(a6)
	move.l	#Buff3+1*Size/8-2,bltapt(a5)
	move.l	#Buff3+2*Size/8-2,bltbpt(a5)
	move.w	#1,bltsizh(a5)		

	jsr	_LVODisownBlitter(a6)

	movem.l	(sp)+,d2-d3/a5

	rts


         SECTION  segment1,BSS,chip		; MUST BE IN CHIP !!!!!

;Chunky  ds.b Size	;Chunky buffer
Buff1	ds.b Size 	;Intermediate buffer 1
Buff2	ds.b Size	;Intermediate buffer 2
Buff3	ds.b Size	;Intermediate buffer 3

;Planes	ds.b Size+100	;Planes as used on screen
;L29	=Planes+BplSize
;L30	=L29+BplSize
;L31	=L30+BplSize
;L32	=L31+BplSize
;L33	=L32+BplSize
;L34	=L33+BplSize
;L35	=L34+BplSize

	END

                            O /
------CUT-OUT----------------X-----------------------------------------------
                            O \

		xdef	_chunky2planar

; peterm/adaptive.s
; Combines peterm/chunky4.s and jmccoull/blitter4pass.s
; The blitter works on the top portion of the display at the same time as
; the CPU converts the bottom portion.
; The blitter has completely finished before the routine returns.
; Both parts of every call are timed using the EClock.
; The partition point is recalculated at the end of the call in an attempt
; to keep the two routines taking about the same amount of time.
;
; The following formula is used:
;
;	n_blit = n * t_cpu * n_blit / (t_blit * n_cpu + t_cpu * n_blit)
;
; where:
;	n	is the total number of 32-byte units (i.e, width*height/32)
;	n_blit	is the number of 32-byte units above the partition
;	n_cpu	is the number of 32-byte units below the partition (=n-n_blit)
;	t_blit	is the time taken by the blitter in EClock units
;	t_cpu	is the time taken by the cpu in EClock units
;
; ECS Agnus required (for long blits)

bltcpt	 	equ	$048
bltbpt	 	equ	$04c
bltapt	 	equ	$050
bltdpt	 	equ	$054
bltsizv  	equ	$05c
bltsizh  	equ	$05e
cleanup		equ	$40
_LVOReadEClock	equ	-60

;-----------------------------------------------------------------------------
; chunky2planar:	(new Motorola syntax)
;  a0 -> chunky pixels (in FAST RAM)
;  a1 -> plane0 (assume other 7 planes are allocated contiguously)
;  a5 = TimerBase
;  a6 = GfxBase

width		equ	320		; must be a multiple of 32
height		equ	200
pixels		equ	width*height
plsiz		equ	(width/8)*height


		section	code,code

_chunky2planar:	movem.l	d2-d7/a2-a6,-(sp)

; save parameters

		movea.l	#mybltnode,a2
		move.l	a0,(chunky-mybltnode,a2)
		move.l	a1,(plane0-mybltnode,a2)
		move.l	a5,(timerbase-mybltnode,a2)
		move.l	a6,(gfxbase-mybltnode,a2)

; copy pixels_blit from chunky to buff0 (from FAST to CHIP) for the blitter

		movea.l	(chunky-mybltnode,a2),a0
		movea.l	#buff0,a1
		move.l	(pixels_blit-mybltnode,a2),d0
		movea.l	(4).w,a6
		jsr	(_LVOCopyMemQuick,a6)

; read the start time

		lea	(starttime-mybltnode,a2),a0
		movea.l	(timerbase-mybltnode,a2),a6
		jsr	(_LVOReadEClock,a6)

; start the blitter in the background

		st	(waitflag-mybltnode,a2)
		movea.l	a2,a1
		movea.l	(gfxbase-mybltnode,a2),a6
		jsr	(_LVOQBlit,a6)

; compute starting parameters for the CPU routine

		move.l	#plsiz,d0
		sub.l	(plsiz_blit-mybltnode,a2),d0
		lsr.l	#2,d0
		move.w	d0,-(sp)	; outer loop counter on stack

		move.l	(chunky-mybltnode,a2),a0
		adda.l	(pixels_blit-mybltnode,a2),a0	; offset into chunky

		move.l	(plane0-mybltnode,a2),a1
		adda.l	(plsiz_blit-mybltnode,a2),a1	; offset into plane

		lea	(buffers-mybltnode,a2),a3	; a3 -> buffers

	iflt 4*plsiz-4-32768
		adda.w	#3*plsiz,a1	; a1 -> plane 3
	else
	iflt 2*plsiz-4-32768
		adda.w	#1*plsiz,a1	; a1 -> plane 1
	endc
	endc

; set up register constants

		move.l	#$0f0f0f0f,d5	; d5 = constant $0f0f0f0f
		move.l	#$55555555,d6	; d6 = constant $55555555
		move.l	#$3333cccc,d7	; d7 = constant $3333cccc
		lea	(4,a3),a2	; used for inner loop end test

; load up address registers with buffer ptrs

		lea	(2*4,a3),a4	; a4 -> plane2buf
		lea	(2*4,a4),a5	; a5 -> plane4buf
		lea	(2*4,a5),a6	; a6 -> plane6buf

; main loop (starts here) processes 8 chunky pixels at a time

mainloop:

; d0 = a7a6a5a4a3a2a1a0 b7b6b5b4b3b2b1b0 c7c6c5c4c3c2c1c0 d7d6d5d4d3d2d1d0

		move.l	(a0)+,d0	; 12 get next 4 chunky pixels in d0

; d1 = e7e6e5e4e3e2e1e0 f7f6f5f4f3f2f1f0 g7g6g5g4g3g2g1g0 h7h6h5h4h3h2h1h0

		move.l	(a0)+,d1	; 12 get next 4 chunky pixels in d1

; d2 = d0 & 0f0f0f0f
; d2 = ........a3a2a1a0 ........b3b2b1b0 ........c3c2c1c0 ........d3d2d1d0

		move.l	d0,d2		;  4
		and.l	d5,d2		;  8 d5=$0f0f0f0f

; d0 ^= d2
; d0 = a7a6a5a4........ b7b6b5b4........ c7c6c5c4........ d7d6d5d4........

		eor.l	d2,d0		;  8

; d3 = d1 & 0f0f0f0f
; d3 = ........e3e2e1e0 ........f3f2f1f0 ........g3g2g1g0 ........h3h2h1h0

		move.l	d1,d3		;  4
		and.l	d5,d3		;  8 d5=$0f0f0f0f

; d1 ^= d3
; d1 = e7e6e5e4........ f7f6f5f4........ g7g6g5g4........ h7h6h5h4........

		eor.l	d3,d1		;  8

; d2 = (d2 << 4) | d3
; d2 = a3a2a1a0e3e2e1e0 b3b2b1b0f3f2f1f0 c3c2c1c0g3g2g1g0 d3d2d1d0h3h2h1h0

		lsl.l	#4,d2		; 16
		or.l	d3,d2		;  8

; d0 = d0 | (d1 >> 4)
; d0 = a7a6a5a4e7e6e5e4 b7b6b5b4f7f6f5f4 c7c6c5c4g7g6g5g4 d7d6d5d4h7h6h5h4

		lsr.l	#4,d1		; 16
		or.l	d1,d0		;  8

; d3 = ((d2 & 33330000) << 2) | (swap(d2) & 3333cccc) | ((d2 & 0000cccc) >> 2)
; d3 = a1a0c1c0e1e0g1g0 b1b0d1d0f1f0h1h0 a3a2c3c2e3e2g3g2 b3b2d3d2f3f2h3h2

		move.l	d2,d3		;  4
		and.l	d7,d3		;  8 d7=$3333cccc
		move.w	d3,d1		;  4
		clr.w	d3		;  4
		lsl.l	#2,d3		; 12
		lsr.w	#2,d1		; 10
		or.w	d1,d3		;  4
		swap	d2		;  4
		and.l	d7,d2		;  8 d7=$3333cccc
		or.l	d2,d3		;  8

; d1 = ((d0 & 33330000) << 2) | (swap(d0) & 3333cccc) | ((d0 & 0000cccc) >> 2)
; d1 = a5a4c5c4e5e4g5g4 b5b4d5d4f5f4h5h4 a7a6c7c6e7e6g7g6 b7b6d7d6f7f6h7h6

		move.l	d0,d1		;  4
		and.l	d7,d1		;  8 d7=$3333cccc
		move.w	d1,d2		;  4
		clr.w	d1		;  4
		lsl.l	#2,d1		; 12
		lsr.w	#2,d2		; 10
		or.w	d2,d1		;  4
		swap	d0		;  4
		and.l	d7,d0		;  8 d7=$3333cccc
		or.l	d0,d1		;  8

; d2 = d1 >> 7
; d2 = ..............a5 a4c5c4e5e4g5g4b5 b4d5d4f5f4h5h4a7 a6c7c6e7e6g7g6..

		move.l	d1,d2		;  4
		lsr.l	#7,d2		; 22

; d0 = d1 & 55555555
; d0 = ..a4..c4..e4..g4 ..b4..d4..f4..h4 ..a6..c6..e6..g6 ..b6..d6..f6..h6

		move.l	d1,d0		;  4
		and.l	d6,d0		;  8 d6=$55555555

; d1 ^= d0
; d1 = a5..c5..e5..g5.. b5..d5..f5..h5.. a7..c7..e7..g7.. b7..d7..f7..h7..

		eor.l	d0,d1		;  8

; d4 = d2 & 55555555
; d4 = ..............a5 ..c5..e5..g5..b5 ..d5..f5..h5..a7 ..c7..e7..g7....

		move.l	d2,d4		;  4
		and.l	d6,d4		;  8 d6=$55555555

; d2 ^= d4
; d2 = ................ a4..c4..e4..g4.. b4..d4..f4..h4.. a6..c6..e6..g6..

		eor.l	d4,d2		;  8

; d1 = (d1 | d4) >> 1
; d1 = ................ a5b5c5d5e5f5g5h5 ................ a7b7c7d7e7f7g7h7

		or.l	d4,d1		;  8
		lsr.l	#1,d1		; 10

		move.b	d1,(4,a6)	; 12 plane 7
		swap	d1		;  4
		move.b	d1,(4,a5)	; 12 plane 5

; d2 |= d0
; d2 = ................ a4b4c4d4e4f4g4h4 ................ a6b6c6d6e6f6g6h6

		or.l	d0,d2		;  8

		move.b	d2,(a6)+	;  8 plane 6
		swap	d2		;  4
		move.b	d2,(a5)+	;  8 plane 4

; d2 = d3 >> 7
; d2 = ..............a1 a0c1c0e1e0g1g0b1 b0d1d0f1f0h1h0a3 a2c3c2e3e2g3g2..

		move.l	d3,d2		;  4
		lsr.l	#7,d2		; 22

; d0 = d3 & 55555555
; d0 = ..a0..c0..e0..g0 ..b0..d0..f0..h0 ..a2..c2..e2..g2 ..b2..d2..f2..h2

		move.l	d3,d0		;  4
		and.l	d6,d0		;  8 d6=$55555555

; d3 ^= d0
; d3 = a1..c1..e1..g1.. b1..d1..f1..h1.. a3..c3..e3..g3.. b3..d3..f3..h3..

		eor.l	d0,d3		;  8

; d4 = d2 & 55555555
; d4 = ..............a1 ..c1..e1..g1..b1 ..d1..f1..h1..a3 ..c3..e3..g3....

		move.l	d2,d4		;  4
		and.l	d6,d4		;  8 d6=$55555555

; d2 ^= d4
; d2 = ................ a0..c0..e0..g0.. b0..d0..f0..h0.. a2..c2..e2..g2..

		eor.l	d4,d2		;  8

; d3 = (d3 | d4) >> 1
; d3 = ................ a1b1c1d1e1f1g1h1 ................ a3b3c3d3e3f3g3h3

		or.l	d4,d3		;  8
		lsr.l	#1,d3		; 10

		move.b	d3,(4,a4)	; 12 plane 3
		swap	d3		;  4
		move.b	d3,(4,a3)	; 12 plane 1

; d2 = d2 | d0
; d2 = ................ a0b0c0d0e0f0g0h0 ................ a2b2c2d2e2f2g2h2

		or.l	d0,d2		;  8

		move.b	d2,(a4)+	;  8 plane 2
		swap	d2		;  4
		move.b	d2,(a3)+	;  8 plane 0

; test if stack buffers are full, loop back if not

		cmpa.l	a3,a2		;  6
		bne.w	mainloop	; 10	total=540 (67.5 cycles/pixel)

; move stack buffers to bitplanes (longword writes) and restore ptrs

	iflt 4*plsiz-4-32768			; a1 points into plane 3
		move.l	(a4),(a1)+		; plane 3
		move.l	(a6),(4*plsiz-4,a1)	; plane 7
		move.l	-(a6),(3*plsiz-4,a1)	; plane 6
		move.l	(a5),(2*plsiz-4,a1)	; plane 5
		move.l	-(a5),(1*plsiz-4,a1)	; plane 4
		move.l	-(a4),(-1*plsiz-4,a1)	; plane 2
		move.l	(a3),(-2*plsiz-4,a1)	; plane 1
		move.l	-(a3),(-3*plsiz-4,a1)	; plane 0
	else
	iflt 2*plsiz-4-32768			; a1 points into plane 1
		move.l	(a3),(a1)+		; plane 1
		adda.l	#4*plsiz,a1
		move.l	(a6),(2*plsiz-4,a1)	; plane 7
		move.l	-(a6),(1*plsiz-4,a1)	; plane 6
		move.l	(a5),(0*plsiz-4,a1)	; plane 5
		move.l	-(a5),(-1*plsiz-4,a1)	; plane 4
		suba.l	#4*plsiz,a1
		move.l	(a4),(2*plsiz-4,a1)	; plane 3
		move.l	-(a4),(1*plsiz-4,a1)	; plane 2
		move.l	-(a3),(-1*plsiz-4,a1)	; plane 0
	else
	iflt plsiz-32768			; a1 points into plane 0
		adda.l	#6*plsiz,a1
		move.l	(a6),(plsiz,a1)		; plane 7
		move.l	-(a6),(a1)		; plane 6
		move.l	(a5),(-plsiz,a1)	; plane 5
		suba.l	#3*plsiz,a1
		move.l	-(a5),(plsiz,a1)	; plane 4
		move.l	(a4),(a1)		; plane 3
		move.l	-(a4),(-plsiz,a1)	; plane 2
		suba.l	#3*plsiz,a1
		move.l	(a3),(plsiz,a1)		; plane 1
		move.l	-(a3),(a1)+		; plane 0
	else
		move.l	#plsiz,d0		; a1 points into plane 0
		adda.l	#7*plsiz,a1
		move.l	(a6),(a1)		; plane 7
		suba.l	d0,a1
		move.l	-(a6),(a1)		; plane 6
		suba.l	d0,a1
		move.l	(a5),(a1)		; plane 5
		suba.l	d0,a1
		move.l	-(a5),(a1)		; plane 4
		suba.l	d0,a1
		move.l	(a4),(a1)		; plane 3
		suba.l	d0,a1
		move.l	-(a4),(a1)		; plane 2
		suba.l	d0,a1
		move.l	(a3),(a1)		; plane 1
		suba.l	d0,a1
		move.l	-(a3),(a1)+		; plane 0
	endc
	endc
	endc

; check if finished, go back for more

		sub.w	#1,(sp)
		bne.w	mainloop

; CPU all done!  restore stack

		addq.w	#2,sp			; remove outer loop counter

; find out how long it took

		lea	(endcputime-buffers,a3),a0
		movea.l	(timerbase-buffers,a3),a6	; timerbase
		jsr	(_LVOReadEClock,a6)

; wait for the blitter to finish
; busy-wait (for a very short time) on FAST bus, even on a CHIP-only machine

		movea.l	(gfxbase-buffers,a3),a6
		bra.b	endwaitloop
waitloop:	jsr	(_LVOWaitBlit,a6)
endwaitloop:	tst.b	(waitflag-buffers,a3)
		bne.b	waitloop

; get blittime,cputime,n_blit in d2,d3,d0

		move.l	(endblittime+4-buffers,a3),d2
		sub.l	(starttime+4-buffers,a3),d2

		move.l	(endcputime+4-buffers,a3),d3
		sub.l	(starttime+4-buffers,a3),d3

		move.l	(n_blit-buffers,a3),d0

; branch if this is not the first time through

		bset	#0,(firsttimeflag-buffers,a3)
		bne.b	simple

; calculate new partition point for next call using formula

		moveq	#10,d4
		lsr.l	d4,d2			; scale t_blit (avoid overflow)
		lsr.l	d4,d3			; scale t_cpu
		lsr.l	#4,d0			; scale n_blit
		mulu	d0,d3			; d3 = n_blit*t_cpu
		move.w	#(pixels/32)>>4,d1	; n (scaled)
		sub.w	d0,d1
		mulu	d2,d1			; d1 = (n-n_blit)*t_blit
		add.w	d3,d1
		beq.b	alldone			; never divide by 0!
		mulu	#(pixels/32)>>4,d3	; n (scaled)
		divu	d1,d3
		moveq	#0,d0
		move.w	d3,d0
		lsl.l	#4,d0			; scale back n_blit
		bra.b	done

; simple-minded adjustment

simple:		sub.l	d3,d2			; blittime-cputime
		beq.b	alldone			; can't do better than this
		bgt.b	1$
; blittime < cputime, increase n_blit
		addq.l	#8,d0
		cmp.l	#pixels/32,d0
		bcs.b	done
		bra.b	alldone			; don't go out of range
; blittime > cputime, decrease n_blit
1$:		subq.l	#8,d0
		bhi.b	done
		bra.b	alldone			; don't go out of range

; save the new partition point

done:		move.l	d0,(n_blit-buffers,a3)
		lsl.l	#2,d0
		move.l	d0,(plsiz_blit-buffers,a3)
		lsl.l	#3,d0
		move.l	d0,(pixels_blit-buffers,a3)

; all done!

alldone:	movem.l	(sp)+,d2-d7/a2-a6
		rts

;-----------------------------------------------------------------------------
; QBlit functions (called asynchronously)

blit11:		moveq	#-1,d0
		move.l	d0,(bltafwm,a0)
		move.l	#(8<<16)+8,(bltbmod,a0)	; also loads bltamod
		move.w	#0,(bltdmod,a0)
		move.l	#buff0,(bltapt,a0)	; buff0
		move.l	#buff0+8,(bltbpt,a0)	; buff0+8
		move.w	#%1111111100000000,(bltcdat,a0)
		move.l	#buff1,(bltdpt,a0)	; buff1
		move.l	#$0DE48000,(bltcon0,a0)	; D=AC+(B>>8)~C
		move.l	(pixels_blit-mybltnode,a1),d0
		lsr.l	#4,d0
		move.w	d0,(bltsizv,a0)		; pixels_blit/16
		move.w	#4,(bltsizh,a0)		; do blit
		lea	(blit12,pc),a0
		move.l	a0,(qblitfunc-mybltnode,a1)
		rts

blit12:		move.l	#buff0,d0
		add.l	(pixels_blit-mybltnode,a1),d0
		sub.l	#8+2,d0
		move.l	d0,(bltapt,a0)		; buff0+pixels_blit-8-2
		addq.l	#8,d0
		move.l	d0,(bltbpt,a0)		; buff0+pixels_blit-2
		add.l	#buff1-buff0,d0
		move.l	d0,(bltdpt,a0)		; buff1+pixels_blit-2
		move.l	#$8DE40002,(bltcon0,a0)	; D=(A<<8)C+B~C, desc.
		move.w	#4,(bltsizh,a0)		; do blit
		lea	(blit21,pc),a0
		move.l	a0,(qblitfunc-mybltnode,a1)
		rts

blit21:		move.l	#(4<<16)+4,(bltbmod,a0)	; also load bltamod
		move.l	#buff1,(bltapt,a0)
		move.l	#buff1+4,(bltbpt,a0)
		move.w	#%1111000011110000,(bltcdat,a0)
		move.l	#buff0,(bltdpt,a0)
		move.l	#$0DE44000,(bltcon0,a0)	; D=AC+(B>>4)~C
		move.l	(pixels_blit-mybltnode,a1),d0
		lsr.l	#3,d0
		move.w	d0,(bltsizv,a0)		; pixels_blit/8
		move.w	#2,(bltsizh,a0)		; do blit
		lea	(blit22,pc),a0
		move.l	a0,(qblitfunc-mybltnode,a1)
		rts

blit22:		move.l	#buff1,d0
		add.l	(pixels_blit-mybltnode,a1),d0
		subq.l	#2+4,d0
		move.l	d0,(bltapt,a0)		; buff1+pixels_blit-2-4
		addq.l	#4,d0
		move.l	d0,(bltbpt,a0)		; buff1+pixels_blit-2
		add.l	#buff0-buff1,d0
		move.l	d0,(bltdpt,a0)		; buff0+pixels_blit-2
		move.l	#$4DE40002,(bltcon0,a0)	; D=(A<<4)C+B~C, desc.
		move.w	#2,(bltsizh,a0)		; do blit
		lea	(blit31,pc),a0
		move.l	a0,(qblitfunc-mybltnode,a1)
		rts

blit31:		move.l	#(2<<16)+2,(bltbmod,a0)	; also load bltamod
		move.l	#buff0,(bltapt,a0)
		move.l	#buff0+2,(bltbpt,a0)
		move.w	#%1100110011001100,(bltcdat,a0)
		move.l	#buff1,(bltdpt,a0)
		move.l	(pixels_blit-mybltnode,a1),d0
		lsr.l	#2,d0
		move.w	d0,(bltsizv,a0)		; pixels_blit/4
		move.l	#$0DE42000,(bltcon0,a0)	; D=AC+(B>>2)~C
		move.w	#1,(bltsizh,a0)		; do blit
		lea	(blit32,pc),a0
		move.l	a0,(qblitfunc-mybltnode,a1)
		rts

blit32:		move.l	#buff0,d0
		add.l	(pixels_blit-mybltnode,a1),d0
		subq.l	#2+2,d0
		move.l	d0,(bltapt,a0)		; buff0+pixels_blit-2-2
		addq.l	#2,d0
		move.l	d0,(bltbpt,a0)		; buff0+pixels_blit-2
		add.l	#buff1-buff0,d0
		move.l	d0,(bltdpt,a0)		; buff1+pixels_blit-2
		move.l	#$2DE40002,(bltcon0,a0)	; D=(A<<2)C+B~C, desc.
		move.w	#1,(bltsizh,a0)		; do blit
		lea	(blit41,pc),a0
		move.l	a0,(qblitfunc-mybltnode,a1)
		rts

blit41:		moveq	#0,d0
		move.l	d0,(bltbmod,a0)		; also load bltamod
		move.l	#buff1,d0
		move.l	d0,(bltapt,a0)		; buff1+0*plsiz_blit
		add.l	(plsiz_blit-mybltnode,a1),d0
		move.l	d0,(bltbpt,a0)		; buff1+1*plsiz_blit
		move.l	d0,(tmp_ptr-mybltnode,a1)
		move.w	#%1010101010101010,(bltcdat,a0)
		move.l	(plane0-mybltnode,a1),d0
		add.l	#7*plsiz,d0
		move.l	d0,(bltdpt,a0)		; Plane7
		move.l	(pixels_blit-mybltnode,a1),d0
		lsr.l	#4,d0
		move.w	d0,(bltsizv,a0)		; pixels_blit/16
		move.l	#$0DE41000,(bltcon0,a0)	; D=AC+(B>>1)~C
		move.w	#1,(bltsizh,a0)		; do blit
		lea	(blit42,pc),a0
		move.l	a0,(qblitfunc-mybltnode,a1)
		rts

blit42:		move.l	(plsiz_blit-mybltnode,a1),d1
		move.l	(tmp_ptr-mybltnode,a1),d0
		add.l	d1,d0
		move.l	d0,(bltapt,a0)		; buff1+2*plsiz_blit
		add.l	d1,d0
		move.l	d0,(bltbpt,a0)		; buff1+3*plsiz_blit
		move.l	d0,(tmp_ptr-mybltnode,a1)
		move.l	(plane0-mybltnode,a1),d0
		add.l	#3*plsiz,d0
		move.l	d0,(bltdpt,a0)		; Plane3
		move.w	#1,(bltsizh,a0)		; do blit
		lea	(blit43,pc),a0
		move.l	a0,(qblitfunc-mybltnode,a1)
		rts

blit43:		move.l	(plsiz_blit-mybltnode,a1),d1
		move.l	(tmp_ptr-mybltnode,a1),d0
		add.l	d1,d0
		move.l	d0,(bltapt,a0)		; buff1+4*plsiz_blit
		add.l	d1,d0
		move.l	d0,(bltbpt,a0)		; buff1+5*plsiz_blit
		move.l	d0,(tmp_ptr-mybltnode,a1)
		move.l	(plane0-mybltnode,a1),d0
		add.l	#5*plsiz,d0
		move.l	d0,(bltdpt,a0)		; Plane5
		move.w	#1,(bltsizh,a0)		;do blit
		lea	(blit44,pc),a0
		move.l	a0,(qblitfunc-mybltnode,a1)
		rts

blit44:		move.l	(plsiz_blit-mybltnode,a1),d1
		move.l	(tmp_ptr-mybltnode,a1),d0
		add.l	d1,d0
		move.l	d0,(bltapt,a0)		; buff1+6*plsiz_blit
		add.l	d1,d0
		move.l	d0,(bltbpt,a0)		; buff1+7*plsiz_blit
		move.l	d0,(tmp_ptr-mybltnode,a1)
		move.l	(plane0-mybltnode,a1),d0
		add.l	#1*plsiz,d0
		move.l	d0,(bltdpt,a0)		; Plane1
		move.w	#1,(bltsizh,a0)		; do blit
		lea	(blit45,pc),a0
		move.l	a0,(qblitfunc-mybltnode,a1)
		rts

blit45:		move.l	(plsiz_blit-mybltnode,a1),d1
		move.l	(tmp_ptr-mybltnode,a1),d0
		add.l	d1,d0
		subq.l	#2,d0
		move.l	d0,(bltbpt,a0)		; buff1+8*plsiz_blit-2
		sub.l	d1,d0
		move.l	d0,(bltapt,a0)		; buff1+7*plsiz_blit-2
		move.l	d0,(tmp_ptr-mybltnode,a1)
		move.l	(plane0-mybltnode,a1),d0
		add.l	d1,d0
		subq.l	#2,d0
		move.l	d0,(bltdpt,a0)		; Plane0
		move.l	#$1DE40002,(bltcon0,a0)	; D=(A<<1)C+B~C, desc.
		move.w	#1,(bltsizh,a0)		; do blit
		lea	(blit46,pc),a0
		move.l	a0,(qblitfunc-mybltnode,a1)
		rts

blit46:		move.l	(plsiz_blit-mybltnode,a1),d1
		move.l	(tmp_ptr-mybltnode,a1),d0
		sub.l	d1,d0
		move.l	d0,(bltbpt,a0)		; buff1+6*plsiz_blit-2
		sub.l	d1,d0
		move.l	d0,(bltapt,a0)		; buff1+5*plsiz_blit-2
		move.l	d0,(tmp_ptr-mybltnode,a1)
		move.l	(plane0-mybltnode,a1),d0
		add.l	#4*plsiz-2,d0
		add.l	d1,d0
		move.l	d0,(bltdpt,a0)		; Plane4
		move.w	#1,(bltsizh,a0)		; do blit
		lea	(blit47,pc),a0
		move.l	a0,(qblitfunc-mybltnode,a1)
		rts

blit47:		move.l	(plsiz_blit-mybltnode,a1),d1
		move.l	(tmp_ptr-mybltnode,a1),d0
		sub.l	d1,d0
		move.l	d0,(bltbpt,a0)		; buff1+4*plsiz_blit-2
		sub.l	d1,d0
		move.l	d0,(bltapt,a0)		; buff1+3*plsiz_blit-2
		move.l	d0,(tmp_ptr-mybltnode,a1)
		move.l	(plane0-mybltnode,a1),d0
		add.l	#2*plsiz-2,d0
		add.l	d1,d0
		move.l	d0,(bltdpt,a0)		; Plane2
		move.w	#1,(bltsizh,a0)		; do blit
		lea	(blit48,pc),a0
		move.l	a0,(qblitfunc-mybltnode,a1)
		rts

blit48:		move.l	(plsiz_blit-mybltnode,a1),d1
		move.l	(tmp_ptr-mybltnode,a1),d0
		sub.l	d1,d0
		move.l	d0,(bltbpt,a0)		; buff1+2*plsiz_blit-2
		sub.l	d1,d0
		move.l	d0,(bltapt,a0)		; buff1+1*plsiz_blit-2
		move.l	(plane0-mybltnode,a1),d0
		add.l	#6*plsiz-2,d0
		add.l	d1,d0
		move.l	d0,(bltdpt,a0)		; Plane6
		move.w	#1,(bltsizh,a0)		; do blit
		lea	(blit11,pc),a0
		move.l	a0,(qblitfunc-mybltnode,a1)
		moveq	#0,d0			; set Z flag
		rts

qblitcleanup:	movem.l	a2/a6,-(sp)
		move.l	#mybltnode,a2
		lea	(endblittime-mybltnode,a2),a0
		move.l	(timerbase-mybltnode,a2),a6
		jsr	(_LVOReadEClock,a6)	; may be called from interrupts
		sf	(waitflag-mybltnode,a2)
		movem.l	(sp)+,a2/a6
		rts

;-----------------------------------------------------------------------------

		section	data,data

		quad
buffers:	dc.l	0,0,0,0,0,0,0,0
mybltnode:	dc.l	0		; next bltnode
qblitfunc:	dc.l	blit11		; ptr to qblitfunc()
		dc.b	cleanup		; stat
		dc.b	0		; filler
		dc.w	0		; blitsize
		dc.w	0		; beamsync
		dc.l	qblitcleanup	; ptr to qblitcleanup()

		quad
chunky:		dc.l	0		; ptr to original chunky data
plane0:		dc.l	0		; ptr to output planes
pixels_blit:	dc.l	pixels/2	; number of pixels handled by blitter
plsiz_blit:	dc.l	pixels/8/2	; & corresponding (partial) planesize
n_blit:		dc.l	pixels/32/2	; number of 32-byte units for blitter
tmp_ptr:	dc.l	0
gfxbase:	dc.l	0
timerbase:	dc.l	0
starttime:	dc.l	0,0
endblittime:	dc.l	0,0
endcputime:	dc.l	0,0
waitflag:	dc.b	0
firsttimeflag:	dc.b	0

;-----------------------------------------------------------------------------

		section	bss,bss,chip	; MUST BE IN CHIP !!!!!

		quad
buff0:		ds.b	pixels		;Intermediate buffer 1
buff1:		ds.b	pixels		;Intermediate buffer 1

;-----------------------------------------------------------------------------

		end

;*+*+*+*+*+*+*+*+*+*+*+*+*+*+*+*+*+*+*+*+*+*+*+*+*+*+*+*+*+*+*+*+*+*+*+*
