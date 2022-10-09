*********************************************************************
*   ______                             i    ______                  *
*  // ___ \                            |   // ___ \                 *
* // /  \\ \    -  - ----------------=<+>=-|| |-\\ \------ -  -     *
* || ��| ���_ _______________________ _|___|| |  \\ \_____ _____ _  *
* || __| ___|\| | |_|| | | | || ||_ |\||| ||| |  // /|_ | \|| ||\|  *
* \\ \  // /| | | | ||   | | ||__|  | |||  || | // / |   \ ||__| |  *
*  \\ ��� / | | | | || | | | || ||  | ||| |\\ ��� /  |  \ ||| || |� *
*   ������  � � � � ���� � ���������� ����� ������   ��� ������� �  *
*         Something for your mind, your body and your soul          *
*********************************************************************

Chunky2Planar	;a0 = byte pixels , a1 = plane 1
		;256 colour / 8 bitplane
		
		Movem.l	d2-d7/a2-a6,-(a7)
		Movem.l	.Const(pc),d5-d7
		Lea	40*256(a1),a2			Plane2 
		Movea.l	a2,a3				Plane2
		Lea	2*40*256(a1),a4			Plane3
		Lea	2*40*256(a4),a5			Plane5
		Lea	2*40*256(a5),a6			Plane7
	Bra.s	.BPPLoop	
.Const		Dc.l	$0f0f0f0f,$55555555,$3333cccc
		Cnop	0,4

.BPPLoop	Move.l	(a0)+,d0	; 12 get next 4 chunky pixels in d0
		Move.l	(a0)+,d1	; 12 get next 4 chunky pixels in d1
; d0 = a7a6a5a4a3a2a1a0 b7b6b5b4b3b2b1b0 c7c6c5c4c3c2c1c0 d7d6d5d4d3d2d1d0
; d1 = e7e6e5e4e3e2e1e0 f7f6f5f4f3f2f1f0 g7g6g5g4g3g2g1g0 h7h6h5h4h3h2h1h0

		Move.l	d0,d2		;  4
		Move.l	d1,d3		;  4
		And.l	d5,d2		;  8 d5=$0f0f0f0f
		And.l	d5,d3		;  8 d5=$0f0f0f0f
		Eor.l	d2,d0		;  8
		Eor.l	d3,d1		;  8
; d0 = a7a6a5a4........ b7b6b5b4........ c7c6c5c4........ d7d6d5d4........
; d1 = e7e6e5e4........ f7f6f5f4........ g7g6g5g4........ h7h6h5h4........
; d2 = ........a3a2a1a0 ........b3b2b1b0 ........c3c2c1c0 ........d3d2d1d0
; d3 = ........e3e2e1e0 ........f3f2f1f0 ........g3g2g1g0 ........h3h2h1h0

		Lsl.l	#4,d2		; 16
		Lsr.l	#4,d1		; 16
		Or.l	d3,d2		;  8
		Or.l	d1,d0		;  8
; d0 = a7a6a5a4e7e6e5e4 b7b6b5b4f7f6f5f4 c7c6c5c4g7g6g5g4 d7d6d5d4h7h6h5h4
; d2 = a3a2a1a0e3e2e1e0 b3b2b1b0f3f2f1f0 c3c2c1c0g3g2g1g0 d3d2d1d0h3h2h1h0

		Move.l	d0,d1		;  4
		Move.l	d2,d3		;  4
		And.l	d7,d1		;  8	;128
		And.l	d7,d3		;  8
		Eor.l	d1,d0		;  8
		Eor.l	d3,d2		;  8
		Lsr.w	#2,d1		; 10	
		Lsr.w	#2,d3		; 10
		Swap	d1		;  4
		Swap	d3		;  4
		Lsl.w	#2,d1		; 10
		Lsl.w	#2,d3		; 10
; d0 = a7a6....e7e6.... b7b6....f7f6.... ....c5c4....g5g4 ....d5d4....h5h4
; d1 = ....c7c6....g7g6 ....d7d6....h7h6 a5a4....e5e4.... b5b4....f5f4.... 

		Or.l	d1,d0		;  8
		Or.l	d3,d2		;  8
; d0 = a7a6c7c6e7e6g7g6 b7b6d7d6f7f6h7h6 a5a4c5c4e5e4g5g4 b5b4d5d4f5f4h5h4 , d2=32/10

		Move.l	d0,d1		;  4
		Lsr.l	#7,d1		; 22
; d0 = a7a6c7c6e7e6g7g6 b7b6d7d6f7f6h7h6 a5a4c5c4e5e4g5g4 b5b4d5d4f5f4h5h4 
; d1 = ..............a7 a6c7c6e7e6g7g6b7 b6d7d6f7f6h7h6a5 a4c5c4e5e4g5g4b5

		Move.l	d0,d3		;  4
		Move.l	d1,d4		;  4
		And.l	d6,d0		;  8	;258
		And.l	d6,d1		;  8
		Eor.l	d0,d3		;  8
		Eor.l	d1,d4		;  8
; d0 = ..a6..c6..e6..g6 ..b6..d6..f6..h6 ..a4..c4..e4..g4 ..b4..d4..f4..h4 
; d3 = a7..c7..e7..g7.. b7..d7..f7..h7.. a5..c5..e5..g5.. b5..d5..f5..h5.. 
; d1 = ..............a7 ..c7..e7..g7..b7 ..d7..f7..h7..a5 ..c5..e5..g5..b5
; d4 = ................ a6..c6..e6..g6.. b6..d6..f6..h6.. a4..c4..e4..g4..

		Or.l	d4,d0		;  8
		Or.l	d3,d1		;  8
		Lsr.l	#1,d1		; 10
; d0 = ..a6..c6..e6..g6 a6b6c6d6e6f6g6h6 b6a4d6c4f6e4h6g4 a4b4c4d4e4f4g4h4
; d1 = ..a7..c7..e7..g7 a7b7c7d7e7f7g7h7 b7a5d7c5f7e5h7g5 a5b5c5d5e5f5g5h5

		move.b	d1,40*256(a5)	; 12 plane 6
		swap	d1		;  4
		move.b	d1,40*256(a6)	; 12 plane 8
		move.b	d0,(a5)+	;  8 plane 5
		swap	d0		;  4
		move.b	d0,(a6)+	;  8 plane 7

		Move.l	d2,d1		;  4
		Lsr.l	#7,d1		; 22
; d2 = a3a2c3c2e3e2g3g2 b3b2d3d2f3f2h3h2 a1a0c1c0e1e0g1g0 b1b0d1d0f1f0h1h0 
; d1 = ..............a3 a2c3c2e3e2g3g2b3 b2d3d2f3f2h3h2a1 a0c1c0e1e0g1g0b1

		Move.l	d2,d3		;  4
		Move.l	d1,d4		;  4
		And.l	d6,d2		;  8
		And.l	d6,d1		;  8
		Eor.l	d2,d3		;  8
		Eor.l	d1,d4		;  8
; d2 = ..a2..c2..e2..g2 ..b2..d2..f2..h2 ..a0..c0..e0..g0 ..b0..d0..f0..h0 
; d3 = a3..c3..e3..g3.. b3..d3..f3..h3.. a1..c1..e1..g1.. b1..d1..f1..h1.. 
; d1 = ..............a3 ..c3..e3..g3..b3 ..d3..f3..h3..a1 ..c1..e1..g1..b1
; d4 = ................ a2..c2..e2..g2.. b2..d2..f2..h2.. a0..c0..e0..g0..		

		Or.l	d4,d2		;  8
		Or.l	d3,d1		;  8
		Lsr.l	#1,d1		; 10	;448
; d2 = ..a2..c2..e2..g2 a2b2c2d2e2f2g2h2 b2a0d2c0f2e0h2g0 a0b0c0d0e0f0g0h0
; d1 = ..a3..c3..e3..g3 a3b3c3d3e3f3g3h3 b3a1d3c1f3e1h3g1 a1b1c1d1e1f1g1h1
		move.b	d1,(a3)+	; 12 plane 2
		swap	d1		;  4
		move.b	d1,40*256(a4)	;  8 plane 4
		move.b	d2,(a1)+	;  8 plane 1
		swap	d2		;  4
		move.b	d2,(a4)+	;  8 plane 3 ;126 bytws
		cmpa.l	a1,a2		;  6	
	bne	.BPPLoop		; 10	
		movem.l	(a7)+,d2-d7/a2-a6
		rts

*		Length	Cycles	Cyc/pix.
*MainLoop	132 	508	63.5 
*Double Main	258 	1000	62.5	

*Seeing as we will probably be averaging at least 50000 pixels per "frame" any 
*cycle saving is significant


