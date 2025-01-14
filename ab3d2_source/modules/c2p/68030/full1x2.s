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
	section	code,code
c2p_ConvertFull1x2Opt030:
	; a0	c2pscreen
	; a1	bitplanes

	movem.l	d2-d7/a2-a6,-(sp)

	move.l	Vid_FastBufferPtr_l,a0
	adda.l	c2p1x1_8_c5_030_2_bfroffs,a0
	move.l	Vid_DrawScreenPtr_l,a1

	move.l	#$00ff00ff,a6

	add.w	#BPLSIZE,a1
	add.l	c2p1x1_8_c5_030_2_scroffs,a1
	lea		c2p1x1_8_c5_030_2_fastbuf,a3
	move.l	c2p1x1_8_c5_030_2_pixels_2,a2
	add.l	a0,a2
	cmp.l	a0,a2
	beq	.none

	addq.l	#4,a2
	move.l	a1,-(sp)

	move.l	#(((FS_WIDTH/32)<<16)|(FS_WIDTH/32)),-(sp)

	move.l	#$f0f0f0f0,d6
                     ; Pixels read
	move.l	(a0)+,d2 ; R: 4
	move.l	d2,d7
	lsl.l	#4,d7
	move.l	(a0)+,d0 ; R: 8
	move.l	(a0)+,d3 ; R: 12
	move.l	(a0)+,d1 ; R: 16
	eor.l	d0,d7
	and.l	d6,d7
	eor.l	d7,d0
	lsr.l	#4,d7
	eor.l	d7,d2
	move.l	d3,d7
	lsl.l	#4,d7
	eor.l	d1,d7
	and.l	d6,d7
	eor.l	d7,d1
	move.l	d2,(a3)+ ; B: 4
	lsr.l	#4,d7
	eor.l	d7,d3
	move.l	d3,(a3)+ ; B: 8

	move.l	(a0)+,d4 ; R: 20
	move.l	d4,d7
	lsl.l	#4,d7
	move.l	(a0)+,d2 ; R: 24
	move.l	(a0)+,d5 ; R: 28
	move.l	(a0)+,d3 ; R: 32 - one full span
	eor.l	d2,d7
	and.l	d6,d7
	eor.l	d7,d2
	lsr.l	#4,d7
	eor.l	d7,d4
	move.l	d5,d7
	lsl.l	#4,d7
	eor.l	d3,d7
	and.l	d6,d7
	eor.l	d7,d3
	move.l	d4,(a3)+ ; B: 12
	lsr.l	#4,d7
	eor.l	d7,d5
	move.l	d5,(a3)+ ; B: 16

	move.w	d2,d7			; Swap 16x2
	move.w	d0,d2
	swap	d2
	move.w	d2,d0
	move.w	d7,d2

	move.w	d3,d7
	move.w	d1,d3
	swap	d3
	move.w	d3,d1
	move.w	d7,d3

	bra.s	.start1

.x1:
	move.l	(a0)+,d0 ; R: 32(span + 1) + 8
	move.l	(a0)+,d3 ; R: 32(span + 1) + 12
	move.l	(a0)+,d1 ; R: 32(span + 1) + 16
	move.l	d7,BPLSIZE(a1) ; W 2
	move.l	d2,d7
	lsl.l	#4,d7
	eor.l	d0,d7
	and.l	d6,d7
	eor.l	d7,d0
	lsr.l	#4,d7
	eor.l	d7,d2
	move.l	d3,d7
	lsl.l	#4,d7
	eor.l	d1,d7
	and.l	d6,d7
	eor.l	d7,d1
	move.l	d2,(a3)+ ; B: +20
	lsr.l	#4,d7
	eor.l	d7,d3
	move.l	d3,(a3)+ ; B: +24
	move.l	d5,a5

	move.l	(a0)+,d4  ; R: 32(span + 1) + 20
	move.l	d4,d7
	lsl.l	#4,d7
	move.l	(a0)+,d2  ; R: 32(span + 1) + 24
	move.l	(a0)+,d5  ; R: 32(span + 1) + 28
	move.l	(a0)+,d3  ; R: 32(span + 1) + 32 - one full span
	move.l	a4,(a1)+  ; W: 3
	eor.l	d2,d7
	and.l	d6,d7
	eor.l	d7,d2
	lsr.l	#4,d7
	eor.l	d7,d4
	move.l	d5,d7
	lsl.l	#4,d7
	eor.l	d3,d7
	and.l	d6,d7
	eor.l	d7,d3
	lsr.l	#4,d7
	eor.l	d7,d5

	move.w	d2,d7			; Swap 16x2
	move.w	d0,d2
	swap	d2
	move.w	d2,d0
	move.l	d4,(a3)+ ; B: +28
	move.w	d7,d2

	move.w	d3,d7
	move.w	d1,d3
	move.l	d5,(a3)+ ; B: +32
	swap	d3
	move.w	d3,d1
	move.w	d7,d3
	move.l	a5,-BPLSIZE-4(a1) ; W: 4 - written first 4 spans this pass.

	subq.w #1,2(sp)
	bne .done_output_modulus_x1

	adda.w #((FS_WIDTH)/8),a1  ; destination plane modulus
	move.w #(FS_WIDTH/32),2(sp)

.done_output_modulus_x1:

.start1:
	subq.w #1,(sp)
	bne .done_input_modulus_x1

	move.w #(FS_WIDTH/32),(sp)     ; reset
	adda.w #(FS_WIDTH),a0 ; add modulus

.done_input_modulus_x1:

	move.l	#$33333333,d5

	move.l	d2,d7			; Swap 2x2
	lsr.l	#2,d7
	eor.l	d0,d7
	and.l	d5,d7
	eor.l	d7,d0
	lsl.l	#2,d7
	eor.l	d7,d2

	move.l	d3,d7
	lsr.l	#2,d7
	eor.l	d1,d7
	and.l	d5,d7
	eor.l	d7,d1
	lsl.l	#2,d7
	eor.l	d7,d3

	move.l	a6,d4
	move.l	#$55555555,d5

	move.l	d1,d7
	lsr.l	#8,d7
	eor.l	d0,d7
	and.l	d4,d7
	eor.l	d7,d0
	lsl.l	#8,d7
	eor.l	d7,d1

	move.l	d1,d7
	lsr.l	#1,d7
	eor.l	d0,d7
	and.l	d5,d7
	eor.l	d7,d0
	move.l	d0,BPLSIZE*2(a1)         ; W: 1

	add.l	d7,d7
	eor.l	d1,d7

	move.l	d3,d1
	lsr.l	#8,d1
	eor.l	d2,d1
	and.l	d4,d1
	eor.l	d1,d2
	lsl.l	#8,d1
	eor.l	d1,d3

	move.l	d3,d1
	lsr.l	#1,d1
	eor.l	d2,d1
	and.l	d1,d5
	eor.l	d5,d2
	move.l	d2,a4
	move.l	(a0)+,d2 ; R: 32(span + 1) + 4
	add.l	d5,d5
	eor.l	d3,d5

	cmpa.l	a0,a2
	bne	.x1

.x1end:
	move.l	d7,BPLSIZE(a1)
	move.l	a4,(a1)+
	move.l	d5,-BPLSIZE-4(a1)

    add.w #4,sp ; modulus counter pair
	move.l	(sp)+,a1
	move.w #(FS_WIDTH/32),-(sp)
	add.l	#BPLSIZE*4,a1

	move.l	c2p1x1_8_c5_030_2_pixels,d0
	lsr.l 	#2,d0
	lea		c2p1x1_8_c5_030_2_fastbuf,a0
	lea		4(a0,d0.l),a2

	move.l	(a0)+,d0
	move.l	#$55555555,d4
	move.l	#$33333333,d5
	move.l	#$00ff00ff,d6
	move.l	(a0)+,d1
	move.l	(a0)+,d2
	move.l	(a0)+,d3

	move.w	d2,d7			; Swap 16x2
	move.w	d0,d2
	swap	d2
	move.w	d2,d0
	move.w	d7,d2

	move.w	d3,d7
	move.w	d1,d3
	swap	d3
	move.w	d3,d1
	move.w	d7,d3

	move.l	d2,d7			; Swap 2x2
	lsr.l	#2,d7
	eor.l	d0,d7
	and.l	d5,d7
	eor.l	d7,d0
	lsl.l	#2,d7
	eor.l	d7,d2

	move.l	d3,d7
	lsr.l	#2,d7
	eor.l	d1,d7
	and.l	d5,d7
	eor.l	d7,d1
	lsl.l	#2,d7
	eor.l	d7,d3

	move.l	d1,d7
	lsr.l	#8,d7
	bra.s	.start2

.x2:
	move.l	(a0)+,d1
	move.l	(a0)+,d2
	move.l	(a0)+,d3
	move.l	d7,BPLSIZE(a1) ; W: +2
	move.w	d2,d7			; Swap 16x2
	move.w	d0,d2
	swap	d2
	move.w	d2,d0
	move.w	d7,d2

	move.w	d3,d7
	move.w	d1,d3
	swap	d3
	move.w	d3,d1
	move.w	d7,d3

	move.l	d2,d7			; Swap 2x2
	lsr.l	#2,d7
	eor.l	d0,d7
	move.l	a4,(a1)+; W: +3
	and.l	d5,d7
	eor.l	d7,d0
	lsl.l	#2,d7
	eor.l	d7,d2

	move.l	d3,d7
	lsr.l	#2,d7
	eor.l	d1,d7
	and.l	d5,d7
	eor.l	d7,d1
	lsl.l	#2,d7
	eor.l	d7,d3

	move.l	d1,d7
	lsr.l	#8,d7
	move.l	a5,-BPLSIZE-4(a1) ; W + 4

	subq.w #1,(sp)
	bne .done_output_modulus_x2

	adda.w #((FS_WIDTH)/8),a1  ; destination plane modulus
	move.w #(FS_WIDTH/32),(sp)

.done_output_modulus_x2:

.start2:
	eor.l	d0,d7
	and.l	d6,d7
	eor.l	d7,d0
	lsl.l	#8,d7
	eor.l	d7,d1

	move.l	d1,d7
	lsr.l	#1,d7
	eor.l	d0,d7
	and.l	d4,d7
	eor.l	d7,d0
	add.l	d7,d7
	eor.l	d1,d7

	move.l	d3,d1
    ;move.l  #$F0F0F0F0,BPLSIZE*2(a1)
	move.l	d0,BPLSIZE*2(a1) ; W: 1

	lsr.l	#8,d1
	eor.l	d2,d1
	and.l	d6,d1
	eor.l	d1,d2
	lsl.l	#8,d1
	eor.l	d1,d3

	move.l	d3,d1
	lsr.l	#1,d1
	eor.l	d2,d1
	and.l	d4,d1
	eor.l	d1,d2
	add.l	d1,d1
	eor.l	d1,d3

	move.l	(a0)+,d0
	move.l	d2,a4
	move.l	d3,a5

	cmpa.l	a0,a2
	bne	.x2

	move.l	d7,BPLSIZE(a1) ;

	move.l	a4,(a1)+

	move.l	a5,-BPLSIZE-4(a1) ;

    adda.w #2,sp ; modulus

.none:
	movem.l	(sp)+,d2-d7/a2-a6
	rts
