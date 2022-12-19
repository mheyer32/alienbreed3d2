			section data,data

; Statically initialised (non-zero) data
			align 4

; sine/cosine << 15
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
