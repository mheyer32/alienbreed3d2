
			section .bss,bss

; BSS data - to be included in BSS section
			align 4

; Memory class to use for next loaded entity
IO_MemType_l:			ds.l	1

; dos.llibrary file handle
IO_DOSFileHandle_l:		ds.l	1

; Private stuff
io_EndOfQueue_l:		ds.l	1

; Array of object pointers
io_ObjectPointers_vl:	ds.l	160

; block properties
io_BlockLength_l:		ds.l	1
io_BlockName_l:			ds.l	1
io_BlockStart_l:		ds.l	1

; Pointer to the file extension (i.e. the substring starting at .)
io_FileExtPointer_l:	ds.l	1

io_ObjectName_vb:		ds.b	160
io_Buffer_vb:			ds.b	80   ; todo - can these be merged ?

; File info block
io_FileInfoBlock_vb:	ds.b	fib_SIZEOF
