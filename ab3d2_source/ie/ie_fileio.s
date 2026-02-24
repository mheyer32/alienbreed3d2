; ie_fileio.s - Intuition Engine file I/O bridge
; Calling convention (current WIP):
;   ie_fopen:  d0=filename_ptr               -> d0=handle (1 success, 0 fail)
;   ie_fread:  d0=handle, d1=data_ptr        -> d0=result_len, d1=status
;   ie_fclose: d0=handle                      -> d0=status (0 ok)

	xdef ie_fopen
	xdef ie_fread
	xdef ie_fclose
	xdef ie_file_name_ptr

ie_fopen:
	move.l	d0,ie_file_name_ptr
	moveq	#0,d0
	tst.l	ie_file_name_ptr
	beq.s	.fail
	moveq	#1,d0
.fail:
	rts

ie_fread:
	; Validate simple single-handle contract.
	cmpi.l	#1,d0
	bne.s	.bad_handle

	move.l	ie_file_name_ptr,$F2200
	move.l	d1,$F2204
	move.l	#1,$F220C
	move.l	$F2214,d0
	move.l	$F2210,d1
	rts
.bad_handle:
	moveq	#0,d0
	moveq	#1,d1
	rts

ie_fclose:
	cmpi.l	#1,d0
	beq.s	.ok_close
	moveq	#1,d0
	rts
.ok_close:
	moveq	#0,d0
	rts

ie_file_name_ptr:
	dc.l	0
