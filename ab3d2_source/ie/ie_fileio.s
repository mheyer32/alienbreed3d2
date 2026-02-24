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
	xdef _IO_LoadFile
	xdef IO_LoadFileOptional
	xdef _IO_LoadFileOptional
	xdef IO_InitQueue
	xdef _IO_InitQueue
	xdef IO_QueueFile
	xdef _IO_QueueFile
	xdef IO_FlushQueue
	xdef _IO_FlushQueue
	xdef IO_MemType_l
	xdef io_Buffer_vb
	xdef io_ObjectName_vb
	xdef io_FileExtPointer_l
	xdef io_last_status
	xdef ie_file_name_ptr

ie_fopen:
	move.l	d0,a0
	clr.l	ie_file_name_ptr
	clr.l	ie_file_name_alt_ptr
	clr.l	ie_file_name_media_ptr
	clr.l	ie_file_name_media_alt_ptr
	clr.l	ie_file_name_parent_media_ptr
	clr.l	ie_file_name_parent_media_alt_ptr
	moveq	#0,d0
	tst.l	a0
	beq		.fail
	; Convert Amiga-style "VOL:path" to host path form by stripping
	; the first volume/device prefix and normalizing backslashes.
	move.l	a0,a2
.find_colon:
	move.b	(a0)+,d1
	beq.s	.copy_name
	cmpi.b	#':',d1
	bne.s	.find_colon
	move.l	a0,a2
.copy_name:
	move.l	a2,a0
	lea		ie_file_path_vb,a1
	lea		ie_file_path_lower_vb,a3
	move.w	#510,d7
.copy_loop:
	move.b	(a0)+,d1
	cmpi.b	#92,d1
	bne.s	.store_char
	moveq	#47,d1
.store_char:
	move.b	d1,(a1)+
	move.b	d1,d2
	cmpi.b	#'A',d2
	blt.s	.store_lower
	cmpi.b	#'Z',d2
	bgt.s	.store_lower
	addi.b	#32,d2
.store_lower:
	move.b	d2,(a3)+
	beq.s	.finish_copy
	dbra	d7,.copy_loop
	clr.b	(a1)
	clr.b	(a3)
.finish_copy:
	tst.b	ie_file_path_vb
	beq		.fail
	lea		ie_file_path_vb,a1
	move.l	a1,ie_file_name_ptr
	lea		ie_file_path_lower_vb,a1
	move.l	a1,ie_file_name_alt_ptr

	; Build media/ and ../media/ prefixed fallback paths.
	lea		ie_file_path_vb,a0
	lea		ie_file_path_media_vb,a1
	lea		ie_prefix_media_vb,a2
	bsr		ie_build_prefixed_path
	tst.l	d0
	beq.s	.no_media_primary
	lea		ie_file_path_media_vb,a1
	move.l	a1,ie_file_name_media_ptr
.no_media_primary:

	lea		ie_file_path_lower_vb,a0
	lea		ie_file_path_media_lower_vb,a1
	lea		ie_prefix_media_vb,a2
	bsr		ie_build_prefixed_path
	tst.l	d0
	beq.s	.no_media_alt
	lea		ie_file_path_media_lower_vb,a1
	move.l	a1,ie_file_name_media_alt_ptr
.no_media_alt:

	lea		ie_file_path_vb,a0
	lea		ie_file_path_parent_media_vb,a1
	lea		ie_prefix_parent_media_vb,a2
	bsr		ie_build_prefixed_path
	tst.l	d0
	beq.s	.no_parent_media_primary
	lea		ie_file_path_parent_media_vb,a1
	move.l	a1,ie_file_name_parent_media_ptr
.no_parent_media_primary:

	lea		ie_file_path_lower_vb,a0
	lea		ie_file_path_parent_media_lower_vb,a1
	lea		ie_prefix_parent_media_vb,a2
	bsr		ie_build_prefixed_path
	tst.l	d0
	beq.s	.no_parent_media_alt
	lea		ie_file_path_parent_media_lower_vb,a1
	move.l	a1,ie_file_name_parent_media_alt_ptr
.no_parent_media_alt:

	moveq	#1,d0
.fail:
	rts

ie_fread:
	; Validate simple single-handle contract.
	cmpi.l	#1,d0
	bne		ie_fread_bad_handle

	move.l	d1,d3
	move.l	ie_file_name_ptr,a0
	bsr		ie_fread_try_path
	tst.l	d1
	beq		.read_ok

	; Retry with lowercase and media-prefixed fallbacks for host FS variance.
	move.l	ie_file_name_alt_ptr,a0
	bsr		ie_fread_try_path
	tst.l	d1
	beq		.read_ok

	move.l	ie_file_name_media_ptr,a0
	bsr		ie_fread_try_path
	tst.l	d1
	beq		.read_ok

	move.l	ie_file_name_media_alt_ptr,a0
	bsr		ie_fread_try_path
	tst.l	d1
	beq		.read_ok

	move.l	ie_file_name_parent_media_ptr,a0
	bsr		ie_fread_try_path
	tst.l	d1
	beq		.read_ok

	move.l	ie_file_name_parent_media_alt_ptr,a0
	bsr		ie_fread_try_path
	tst.l	d1
	beq		.read_ok

.read_ok:
	rts

ie_fread_try_path:
	; in: a0=path ptr, d3=dst ptr
	; out: d0=len, d1=status
	tst.l	a0
	beq.s	.bad_try
	move.l	a0,$F2200
	move.l	d3,$F2204
	move.l	#1,$F220C
	move.l	$F2214,d0
	move.l	$F2210,d1
	rts
.bad_try:
	moveq	#0,d0
	moveq	#1,d1
	rts

; Build prefixed fallback path.
; in: a0=source path, a1=dest buffer, a2=prefix string
; out: d0=1 success, 0 failure
ie_build_prefixed_path:
	move.l	a1,a3
	move.w	#510,d7
	copy_prefix_loop:
	move.b	(a2)+,d1
	beq.s	.copy_src_start
	move.b	d1,(a3)+
	dbra	d7,copy_prefix_loop
	clr.b	(a3)
	moveq	#0,d0
	rts
.copy_src_start:
	move.b	(a0)+,d1
	move.b	d1,(a3)+
	beq.s	.done_prefixed
	dbra	d7,.copy_src_start
	clr.b	(a3)
	moveq	#0,d0
	rts
.done_prefixed:
	moveq	#1,d0
	rts
ie_fread_bad_handle:
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
_IO_InitQueue:
	move.l	ie_mem_heap_ptr,io_heap_ptr
	clr.l	io_last_status
	rts

; On entry:
;   a0 = filename pointer
;   d0 = pointer to destination address slot (uint32*)
;   d1 = pointer to destination length slot (uint32* or 0)
IO_QueueFile:
_IO_QueueFile:
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
_IO_FlushQueue:
	; Immediate mode: queue is already processed.
	rts

IO_LoadFile:
_IO_LoadFile:
	bsr.s	IO_LoadFileOptional
	tst.l	d0
	bne		.ok
	; Hard-fail variant would call Sys_FatalError in full integration.
	; Keep non-crashing behavior in this bootstrap stage.
.ok:
	rts

IO_LoadFileOptional:
	_IO_LoadFileOptional:
	move.l	a0,d0
	bsr		ie_fopen
	tst.l	d0
	beq.s	.fail

	; Read into current heap pointer.
	move.l	io_heap_ptr,d1
	moveq	#1,d0
	bsr		ie_fread
	move.l	d0,d6
	move.l	d1,io_last_status
	tst.l	d1
	bne.s	.fail_close

	; Advance heap by aligned length, with bounds check.
	move.l	d6,d0
	addq.l	#3,d0
	andi.l	#$FFFFFFFC,d0
	move.l	io_heap_ptr,d1
	add.l	d0,d1
	cmp.l	#IO_HEAP_LIMIT,d1
	bhi.s	.fail_close

	moveq	#1,d0
	bsr		ie_fclose
	move.l	io_heap_ptr,d0
	move.l	d6,d1
	move.l	io_heap_ptr,d2
	add.l	d1,d2
	addq.l	#3,d2
	andi.l	#$FFFFFFFC,d2
	move.l	d2,io_heap_ptr
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
ie_file_name_alt_ptr:
	dc.l	0
ie_file_name_media_ptr:
	dc.l	0
ie_file_name_media_alt_ptr:
	dc.l	0
ie_file_name_parent_media_ptr:
	dc.l	0
ie_file_name_parent_media_alt_ptr:
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
io_ObjectName_vb:
	dcb.b	160,0
io_FileExtPointer_l:
	dc.l	0

; Internal normalized path staging buffer.
ie_file_path_vb:
	dcb.b	512,0
ie_file_path_lower_vb:
	dcb.b	512,0
ie_file_path_media_vb:
	dcb.b	512,0
ie_file_path_media_lower_vb:
	dcb.b	512,0
ie_file_path_parent_media_vb:
	dcb.b	512,0
ie_file_path_parent_media_lower_vb:
	dcb.b	512,0

ie_prefix_media_vb:
	dc.b	"media/",0
ie_prefix_parent_media_vb:
	dc.b	"../media/",0
