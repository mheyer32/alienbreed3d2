			section .data,data

; Statically initialised (non-zero) data
			align 4

; Data used to construct SinCosTable_vw which contains 8192 16-bit values that cover two full cycles,
; i.e. 4pi radians.
;
; This table contains the second order derivative of the curve for the first quarter cycle (0 - 32767).
; These values are all -1, 0 or 1. To keep things simple, we add 1 and store them as 2-bit values 0-2.
; 16 of these can then be packed into a single 32-bit word.
;
; Reconstruction of the sine wave begins with 0 and an initial delta of 50. The 2-bit fields are
; extracted (low bits first), decremented (to restore the original range) then added to the running delta
; which in turn is integrated to produce the running value.
;
; Once the first quarter is done, the remainder of the table can be filled using simple symmetry,
;
PackedSinData_vl:
	dc.l $52525252, $49525252, $95525525, $55495554, $55615555, $58585585, $22218618, $24892222
	dc.l $55549525, $16155555, $88888616, $52549248, $85615555, $48888861, $55554949, $88886158
	dc.l $14954948, $22186156, $85255252, $92218615, $56155254, $25489188, $88616155, $85554924
	dc.l $25248885, $88885615, $85855494, $55554888, $25488885, $49218561, $88615825, $21615494
	dc.l $85555492, $15554921, $85494886, $55548885, $55248885, $54948858, $55248858, $55248861
	dc.l $55524858, $55548885, $58252461, $58525221, $85555488, $21855248, $46185492, $24861552
	dc.l $54918555, $12522155, $61252216, $61554921, $46155548, $49185552, $52488555, $85252185
	dc.l $16149221, $88855492, $24885554, $55488615, $61524885, $18555488, $52185549, $54921555

MAX_ONE_OVER_N	EQU	511

; the size of one complete cycle - not the actual size of the table
SINE_SIZE		EQU 4096

SINE_OFS		EQU 0
COSINE_OFS		EQU (SINE_SIZE/2)

; Modulus mask value when doing *address* based calculation, e.g. (a0,dN.w)
SINTAB_MASK_ADR	EQU (SINE_SIZE*2)-2

; Modulus mask value when doing *index* based calculation, e.g. (a0, dN.w*2)
SINTAB_MASK_IDX	EQU (SINE_SIZE*2)-1

; Angle modulus (address mask)
AMOD_A			MACRO
				and.w	#SINTAB_MASK_ADR,\1
				ENDM

; Angle modulus (index mask)
AMOD_I			MACRO
				and.w	#SINTAB_MASK_IDX,\1
				ENDM

; stores x/3 and x mod 3 for x=0...660
DivThreeTable_vb:
val				SET		0
				REPT	220
				dc.b	val,0
				dc.b	val,1
				dc.b	val,2
val				SET		val+1
				ENDR
