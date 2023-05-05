			section .data,data

; Statically initialised (non-zero) data
			align 4

MAX_ONE_OVER_N	EQU	511

; sine/cosine << 15, contains two full cycles (720 degrees) over 8192 entries
SinCosTable_vw:		incbin	"bigsine"

; stores x/3 and x mod 3 for x=0...660
DivThreeTable_vb:
val				SET		0
				REPT	220
				dc.b	val,0
				dc.b	val,1
				dc.b	val,2
val				SET		val+1
				ENDR
