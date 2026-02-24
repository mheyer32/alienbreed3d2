; ie_fileio.s - Intuition Engine file I/O bridge
; Calling convention (current WIP):
;   ie_fopen: d0=filename_ptr  -> d0=1 on success path setup
;   ie_fread: d0=data_ptr      -> d0=result_len, d1=status
;   ie_fclose: no-op

	xdef ie_fopen
	xdef ie_fread
	xdef ie_fclose
	xdef ie_file_name_ptr

ie_fopen:
	move.l	d0,ie_file_name_ptr
	moveq	#1,d0
	rts

ie_fread:
	move.l	ie_file_name_ptr,$F2200
	move.l	d0,$F2204
	move.l	#1,$F220C
	move.l	$F2214,d0
	move.l	$F2210,d1
	rts

ie_fclose:
	rts

ie_file_name_ptr:
	dc.l	0
