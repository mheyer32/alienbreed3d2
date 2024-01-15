			section .data,data

; Statically initialised (non-zero) data
			align 4

MAX_ONE_OVER_N	EQU	511

; sine/cosine << 15, contains two full cycles (720 degrees) over 8192 entries
SinCosTable_vw:		incbin	"bigsine"

SINE_OFS		EQU 0

COSINE_OFS		EQU 2048
SINTAB_MASK		EQU 8191

; Note that original masks for ANG_MOD were to replace a 8190 immediate. I think this is a bug but...
ANG_MOD			MACRO
				and.w	#SINTAB_MASK,\1
				ENDM

; ... declare a second version that explicitly used the 8191 value in case we do need to revert ANG_MOD to 8190
ANG_MOD2		MACRO
				and.w	#SINTAB_MASK|1,\1
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
