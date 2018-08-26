; Chunky2Planar algorithm. [writes pipelined a little]
;
; 	Cpu only solution
;	Optimised for 020+fastram
;	Aim for less than 90ms for 320x200x256 on 14MHz 020
;
;
; NOTE: uses hardcoded values for screen size
; 	assumes planes are allocated contiguously
;
; -------------------------------------------------------------------
;
; void __asm c2p_020(	register __a0 UBYTE *chunky,
;			register __a1 PLANEPTR raster );
;
; -------------------------------------------------------------------
;
; see c2p_020_test.c for example of usage


	opt	o-,l+,d+
	
	xdef	_c2p_020
		
WIDTH		equ	320		; MUST be multiple of 32
HEIGHT		equ	200
plsiz		equ	(WIDTH/8)*HEIGHT


		cnop	0,4

_c2p_020:

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

; move.l  d0,(a0)+
; move.l  d2,(a0)+
; move.l  d6,(a0)+
; move.l  d3,(a0)+
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
	

