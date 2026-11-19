
SINTAB_INIT_DELTA	equ 50

				; trashes d2-d5,a2-a3. Call from main init only, before these registers
				; are assigned.
InitTables:
				; First fill up the Sine/Cosine table.
.extact_sine:
				lea		SinCosTable_vw,a0
				moveq	#SINTAB_INIT_DELTA,d0
				move.l	d0,(a0)+ 			; writes first pair (0, 0 + SINTAB_INIT_DELTA)
				move.l	d0,d2				;
				lea 	PackedSinData_vl,a1
				moveq	#63,d1				; num inputs -1 (longs)

				; d2 contains running delta
				; d0 contains running value
.read_loop:
				move.l	(a1)+,d4			; Next packed data
				moveq	#15,d3				; num outputs - 1 (words)

.write_loop:
				moveq	#3,d5
				and.l	d4,d5
				subq.l	#1,d5				; d5 = (d4 & 3) - 1, reconstructs second derivative
				add.l	d5,d2				; integrate second derivative (new delta)
				add.l	d2,d0				; integrate derivative (new value)
				lsr.l	#2,d4				; ready next packed derivative
				move.w	d0,(a0)+			; write output
				dbra	d3,.write_loop

				dbra	d1,.read_loop

.mirror_sine:
				; Now fill in the full 4pi table using the initial quadrant and
				; basic symmetry rules
				lea		SinCosTable_vw,a0 ; forward read Quadrant 1 by postincrement

				; Quadrant pointers
				lea		4098(a0),a3 ; backward filling Quadrant 2 by predecrement
				lea 	4096(a0),a2 ; forward filling Quadrant 3 by postincrement
				lea		8194(a0),a1 ; backward filling Quadrant 4 by predecrement
				move.l	#1024,d1	; we advance 1025 in total to ensure the mirroring
									; covers all the turning points

				; This is a little bit scattergun in terms of writes but we are
				; only doing this once.
.mirror_loop:
				move.w	(a0)+,d0	; read Quadrant 1
				move.w	d0,8190(a0)	; write Quadrant 5 (copy of Quadrant 1 + 8192)
				move.w	d0,-(a3)	; write Quadrant 2
				move.w	d0,8192(a3)	; write Quadrant 6 (copy of Quadrant 2 + 8192)
				neg.w	d0			; reflect X axis
				move.w	d0,(a2)+	; write Quadrant 3
				move.w	d0,8190(a2)	; write Quadrant 7 (copy of Quadrant 3 + 8192)
				move.w	d0,-(a1)	; write Quadrant 4
				move.w	d0,8192(a1)	; write Quadrant 8 (copy of Quadrant 4 + 8192)
				dbra	d1,.mirror_loop

; Constant Table
				move.l	#ConstantTable_vl,a0
				moveq	#1,d0
				move.w	#8191,d1

.fill_const:
				move.l	#16384*64,d2 ; 1<<10
				divs.l	d0,d2
; ext.l d2	;c#
				move.l	#64*64*65536,d3
				divs.l	d2,d3
; move.l d3,d4
; asr.l #6,d4
				move.l	d3,(a0)+				; e#
				asr.l	#1,d2					; c#/2.0
				sub.l	#40*64,d2				; d#
				muls.l	d3,d2					; d#*e#
				asr.l	#6,d2
				move.l	d2,(a0)+
				addq	#1,d0
				dbra	d1,.fill_const

				rts

