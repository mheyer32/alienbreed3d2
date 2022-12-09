
			section bss,bss

; BSS data - to be included in BSS section
			align 4

; System resource pointers
_DOSBase:					ds.l	1
_GfxBase:					ds.l	1
MiscResourceBase:			ds.l	1
PotgoResourceBase:			ds.l	1

; Chunk of statically allocated data for various calculations
WorkSpace:					ds.l	8192
