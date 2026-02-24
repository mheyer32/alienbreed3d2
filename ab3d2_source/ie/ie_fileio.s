; ie_fileio.s - Intuition Engine file I/O bridge
; Calling convention (current WIP):
;   ie_fopen:  d0=filename_ptr               -> d0=handle (1 success, 0 fail)
;   ie_fread:  d0=handle, d1=data_ptr        -> d0=result_len, d1=status
;   ie_fclose: d0=handle                      -> d0=status (0 ok)
;   ie_set_file_buffer: d0=buffer_ptr, d1=buffer_len
;   IO_LoadFile / IO_LoadFileOptional:
;       in: a0=filename_ptr
;       out: d0=buffer_ptr (or 0 on error), d1=bytes_read

	xdef ie_fopen
	xdef ie_fread
	xdef ie_fclose
	xdef ie_set_file_buffer
	xdef IO_LoadFile
	xdef IO_LoadFileOptional
	xdef IO_InitQueue
	xdef IO_QueueFile
	xdef IO_FlushQueue
	xdef IO_MemType_l
	xdef io_Buffer_vb
	xdef io_last_status
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

ie_set_file_buffer:
	move.l	d0,ie_file_data_ptr
	move.l	d1,ie_file_data_len
	rts

; Legacy queue API compatibility.
; On IE we do immediate loads in IO_QueueFile using a static bump allocator.
IO_InitQueue:
	move.l	ie_mem_heap_ptr,io_heap_ptr
	clr.l	io_last_status
	rts

; On entry:
;   a0 = filename pointer
;   d0 = pointer to destination address slot (uint32*)
;   d1 = pointer to destination length slot (uint32* or 0)
IO_QueueFile:
	move.l	d0,a2
	move.l	d1,a3

	; Open file by name.
	move.l	a0,d0
	bsr		ie_fopen
	tst.l	d0
	beq		queue_fail

	; Read directly into current heap pointer.
	move.l	io_heap_ptr,d1
	moveq	#1,d0
	bsr		ie_fread				; d0=len, d1=status
	move.l	d0,d6
	move.l	d1,d7

	; Close handle regardless of read status.
	moveq	#1,d0
	bsr		ie_fclose

	tst.l	d7
	bne		queue_fail

	; Ensure 4-byte alignment advance and heap bounds.
	move.l	d6,d0
	addq.l	#3,d0
	andi.l	#$FFFFFFFC,d0
	move.l	io_heap_ptr,d1
	add.l	d0,d1
	cmp.l	#IO_HEAP_LIMIT,d1
	bhi		queue_fail

	; Publish outputs.
	move.l	io_heap_ptr,d0
	move.l	d0,(a2)
	tst.l	a3
	beq.s	.no_len_store
	move.l	d6,(a3)
.no_len_store:
	move.l	d1,io_heap_ptr
	clr.l	io_last_status
	rts

queue_fail:
	clr.l	(a2)
	tst.l	a3
	beq.s	.no_len_fail
	clr.l	(a3)
.no_len_fail:
	moveq	#1,d0
	move.l	d0,io_last_status
	rts

IO_FlushQueue:
	; Immediate mode: queue is already processed.
	rts

IO_LoadFile:
	bsr.s	IO_LoadFileOptional
	tst.l	d0
	bne		.ok
	; Hard-fail variant would call Sys_FatalError in full integration.
	; Keep non-crashing behavior in this bootstrap stage.
.ok:
	rts

IO_LoadFileOptional:
	move.l	a0,d0
	bsr		ie_fopen
	tst.l	d0
	beq.s	.fail

	move.l	ie_file_data_ptr,d1
	tst.l	d1
	beq.s	.fail_close

	moveq	#1,d0
	bsr		ie_fread
	move.l	d1,io_last_status
	tst.l	d1
	bne.s	.fail_close

	moveq	#1,d0
	bsr		ie_fclose
	move.l	ie_file_data_ptr,d0
	rts

.fail_close:
	moveq	#1,d0
	bsr		ie_fclose
.fail:
	moveq	#0,d0
	moveq	#0,d1
	moveq	#1,d2
	move.l	d2,io_last_status
	rts

ie_file_name_ptr:
	dc.l	0
ie_file_data_ptr:
	dc.l	$700000
ie_file_data_len:
	dc.l	$00100000
io_last_status:
	dc.l	0
io_heap_ptr:
	dc.l	IO_HEAP_BASE
IO_MemType_l:
	dc.l	0

IO_HEAP_BASE	equ	$700000
IO_HEAP_LIMIT	equ	$FE0000

; Compatibility scratch buffer name used by resource loader code.
io_Buffer_vb:
	dcb.b	256,0
