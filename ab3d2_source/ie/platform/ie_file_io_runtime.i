
; *****************************************************************************
; *
; * modules/file_io.s
; *
; * Definitions specific to the loading of data from disk
; *
; * Mostly refactored from newloadfromdisk.s and wallchunk.s
; *
; *****************************************************************************
; TODO: It's possible that some resources are leaked if a fatal error occurs
;       during the loading process (due to calling Sys_FatalError), but for now
;       that seems better than crashing.

IO_MAX_FILENAME_LEN	EQU 79
					IFD		IS_IE
IO_IE_HEAP_BASE		EQU $00700000
IO_IE_HEAP_LIMIT	EQU $00FE0000
IO_IE_HEAP_PTR		EQU $003FFF00
FILE_IO_NAME		EQU $00F2200
FILE_IO_DATA		EQU $00F2204
FILE_IO_DATA_LEN	EQU $00F2208
FILE_IO_CTRL		EQU $00F220C
FILE_IO_STATUS		EQU $00F2210
FILE_IO_LEN			EQU $00F2214
IE_PACK_HEADER		EQU $00600000
IE_PACK_DATA_BASE	EQU $01000000
IE_PACK_DATA_LIMIT	EQU $02000000
IE_PACK_MAGIC		EQU $41423344
IE_PACK_MAGIC_2		EQU $50414B31
IE_PACK_VERSION		EQU 1
IE_PACK_LOAD_BASE	EQU $00001000
					ENDC

; *****************************************************************************
; *
; * IO Queue
; *
; *****************************************************************************

IO_InitQueue:
				IFD		IS_IE
				tst.l	IO_IE_HEAP_PTR
				bne.s	.ie_heap_ready
				move.l	#IO_IE_HEAP_BASE,IO_IE_HEAP_PTR
.ie_heap_ready:
				ENDC
				move.l	#Sys_Workspace_vl,io_EndOfQueue_l
				rts

IO_QueueFile:
				; On entry:
				; a0=Pointer to filename
				; d0=Ptr to dest. of addr
				; d1=ptr to dest. of len.
				; typeofmem=type of memory

				; TODO: save only the required registers.
				SAVEREGS
				IFD		IS_IE
				move.l	a0,a2
				moveq	#0,d3
.skip_volume:
				move.b	(a2),d2
				beq.s	.no_volume_ie
				cmpi.b	#':',d2
				beq.s	.have_volume_ie
				addq.l	#1,a2
				bra.s	.skip_volume
.no_volume_ie:
				move.l	a0,a2
				bra.s	.trim_leading_ie
.have_volume_ie:
				moveq	#1,d3
				addq.l	#1,a2
.trim_leading_ie:
				move.b	(a2),d2
				beq		.skip_queue_ie
				cmpi.b	#' ',d2
				bhi.s	.queue_name_ie
				addq.l	#1,a2
				bra.s	.trim_leading_ie
.queue_name_ie:
				cmpi.b	#'.',d2
				beq		.skip_queue_ie
				move.l	a2,a3
				moveq	#0,d4
.path_char_scan_ie:
				move.b	(a3),d2
				beq.s	.path_char_done_ie
				cmpi.b	#' ',d2
				bls		.skip_queue_ie
				cmpi.b	#'/',d2
				beq.s	.path_marker_ie
				cmpi.b	#'.',d2
				beq.s	.path_marker_ie
				addq.l	#1,a3
				bra.s	.path_char_scan_ie
.path_marker_ie:
				moveq	#1,d4
				addq.l	#1,a3
				bra.s	.path_char_scan_ie
.path_char_done_ie:
				tst.b	d4
				beq		.skip_queue_ie
.queue_path_ok_ie:
				ENDC

				move.l	io_EndOfQueue_l,a1
				move.l	d0,(a1)+
				move.l	d1,(a1)+
				move.l	IO_MemType_l,(a1)+
				move.w	#IO_MAX_FILENAME_LEN,d0

.copy_name:
				move.b	(a0)+,(a1)+
				dbra	d0,.copy_name
				add.l	#100,io_EndOfQueue_l

				IFD		IS_IE
.skip_queue_ie:
				ENDC
				GETREGS

				rts

IO_FlushQueue:
					IFD		IS_IE
					move.l	#Sys_Workspace_vl,a2
					moveq	#0,d6					; tried+failed
.do_flush_ie:
					move.l	a2,d0
					cmp.l	io_EndOfQueue_l,d0
					bge.s	.done_ie
					tst.l	(a2)
					beq.s	.next_ie
					lea		12(a2),a0				; ptr to name
					move.l	a0,a5
				bsr		io_ie_load_to_heap
				tst.l	d0
				beq.s	.load_failed_ie
				move.l	d0,a3
				move.l	(a2),a4
				move.l	a3,(a4)
				move.l	4(a2),d0
				beq.s	.no_len_store_ie
				move.l	d0,a4
				move.l	d1,(a4)
.no_len_store_ie:
				clr.l	(a2)
				bra.s	.next_ie
.load_failed_ie:
				st		d6
.next_ie:
					add.l	#100,a2
					bra.s	.do_flush_ie
.done_ie:
					tst.b	d6
					beq		.loaded_all
					move.l	#Sys_Workspace_vl,a2
.find_failed_ie:
					move.l	a2,d0
					cmp.l	io_EndOfQueue_l,d0
					bge		.loaded_all
					tst.l	(a2)
					bne.s	.report_failed_ie
					add.l	#100,a2
					bra.s	.find_failed_ie
.report_failed_ie:
					lea		12(a2),a5
					move.l	a5,a0
					bsr		io_ie_normalize_name
					bra		io_LoadFailure
					ENDC
					bsr		io_FlushPass

.retry:
				tst.b	LOADEXT
				bne		.loaded_all
				tst.b	d6
				beq		.loaded_all

* Find first unloaded file and prompt for disk.
				move.l	#Sys_Workspace_vl,a2

.find_loop:
				tst.l	(a2)
				bne.s	.found_unloaded
				add.l	#100,a2
				bra.s	.find_loop

.found_unloaded:
				; A2 points at an unloaded file thingy.
				; Prompt for the disk.
				move.l	#mnu_diskline,a3
				move.l	#$20202020,(a3)+
				move.l	#$20202020,(a3)+
				move.l	#$20202020,(a3)+
				move.l	#$20202020,(a3)+
				move.l	#$20202020,(a3)+

; move.l #VOLLINE,a3
				move.l	#mnu_diskline+10,a3
				moveq	#-1,d0
				move.l	a2,a4
				add.l	#12,a4

.not_found_loop:
				addq	#1,d0
				cmp.b	#':',(a4)+
				bne.s	.not_found_loop

				move.w	d0,d1
				asr.w	#1,d1
				sub.w	d1,a3
				move.l	a2,a4
				add.l	#12,a4

; move.w #79,d0
.volume_name_loop:
				move.b	(a4)+,(a3)+
				dbra	d0,.volume_name_loop

				SAVEREGS

				CALLC	mnu_setscreen

				lea		mnu_askfordisk,a0
				jsr		mnu_domenu

				moveq	#1,d0 ; Fade out
				CALLC	mnu_clearscreen

				GETREGS

				tst.b	Game_ShouldQuit_b
				beq		.no_quit
				lea		12(a2),a5
				bra		io_LoadFailure
.no_quit:
				bsr		io_FlushPass
				bra		.retry

.loaded_all:
				rts

io_FlushPass:
				move.l	#Sys_Workspace_vl,a2
				moveq	#0,d7					; loaded a file
				moveq	#0,d6					; tried+failed

.do_flush:
				move.l	a2,d0
				cmp.l	io_EndOfQueue_l,d0
				bge.s	.flushed

				tst.l	(a2)
				beq.s	.load_completed

				lea		12(a2),a0				; ptr to name
				move.l	8(a2),IO_MemType_l
				jsr		io_TryToOpen

				tst.l	d0
				beq.s	.load_failed

				move.l	d0,IO_DOSFileHandle_l
				jsr		io_LoadAndUnpackFile

				st		d7
				move.l	(a2),a3
				move.l	d0,(a3)
				move.l	4(a2),d0
				beq.s	.nolenstore

				move.l	d0,a3
				move.l	d1,(a3)

.nolenstore:
				move.l	#0,(a2)
				bra.s	.load_completed

.load_failed:
				st		d6

.load_completed:
				add.l	#100,a2
				bra		.do_flush

.flushed:
				rts

io_TryToOpen:
				IFD		IS_IE
				moveq	#1,d0
				rts
				ENDC
				movem.l	d1-d7/a0-a6,-(a7)
				IFD MEMTRACK
				SERPRINTF <"io_TryToOpen %s",13,10>,a0
				ENDC
				move.l	a0,d1
				move.l	#MODE_OLDFILE,d2
				CALLDOS	Open

				movem.l	(a7)+,d1-d7/a0-a6
				rts

; *****************************************************************************
; *
; * File Load
; *
; *****************************************************************************

io_LoadAndUnpackFile:
				; Load a file in and unpack it if necessary.
				; Pointer to name in a0
				; Returns address in d0 and length in d1

				SAVEREGS

					bra		io_LoadCommon

; Load an optional file, i.e. one that might not exist.
IO_LoadFileOptional:
				IFD		IS_IE
				SAVEREGS
				move.l	a0,a5
				bsr		io_ie_load_to_heap
				tst.l	d0
				beq.s	.optional_fail_ie
				move.l	d0,io_BlockStart_l
				move.l	d1,io_BlockLength_l
				bra		io_PostProcessLoaded
.optional_fail_ie:
				GETREGS
				clr.l	d0
				clr.l	d1
				rts
				ENDC
				IFD MEMTRACK
				SERPRINTF <"IO_LoadFileOptional %s",13,10>,a0
				ENDC

				SAVEREGS

				move.l	a0,d1
				move.l	a0,a5			; Save filename in a5 for error reporting
				move.l	#MODE_OLDFILE,d2
				CALLDOS	Open

				move.l	d0,IO_DOSFileHandle_l
				bne.s	io_LoadCommon

				GETREGS

				clr.l	d0 ; null address
				clr.l	d1 ; zero length

				rts

IO_LoadFile:
				; Load a file in and unpack it if necessary.
				; Pointer to name in a0
				; Returns address in d0 and length in d1

				IFD MEMTRACK
				SERPRINTF <"IO_LoadFile %s",13,10>,a0
				ENDC

				SAVEREGS

				move.l	a0,d1
				move.l	a0,a5			; Save filename in a5 for error reporting
				IFD		IS_IE
				bsr		io_ie_load_to_heap
				tst.l	d0
				beq		io_LoadFailure
				move.l	d0,io_BlockStart_l
				move.l	d1,io_BlockLength_l
				bra		io_PostProcessLoaded
				ENDC
				move.l	#MODE_OLDFILE,d2
				CALLDOS	Open

				move.l	d0,IO_DOSFileHandle_l
				beq		io_LoadFailure

io_LoadCommon:
				IFD		IS_IE
				move.l	a5,a0
				bsr		io_ie_load_to_heap
				tst.l	d0
				beq		io_LoadFailure
				move.l	d0,io_BlockStart_l
				move.l	d1,io_BlockLength_l
				bra		io_PostProcessLoaded
				ENDC
				lea		io_FileInfoBlock_vb,a5
				move.l	IO_DOSFileHandle_l,d1
				move.l	a5,d2
				CALLDOS	ExamineFH

				move.l	fib_Size(a5),d0
				move.l	d0,io_BlockLength_l
				add.l	#8,d0			; over-allocate by 8 bytes
				move.l	IO_MemType_l,d1
				jsr		Sys_AllocVec

				move.l	d0,io_BlockStart_l
				move.l	IO_DOSFileHandle_l,d1
				move.l	d0,d2
				move.l	io_BlockLength_l,d3
				CALLDOS	Read

				move.l	IO_DOSFileHandle_l,d1
				CALLDOS	Close

io_PostProcessLoaded:
				move.l	io_BlockLength_l,d3
				move.l	io_BlockStart_l,a0
				clr.l	(a0,d3.l)		; clear last 8 bytes
				clr.l	4(a0,d3.l)
				move.l	(a0),d0
				cmp.l	#'=SB=',d0
				beq		io_HandlePacked

				move.l	io_BlockStart_l,d0
				move.l	io_BlockLength_l,d1
				move.l	d0,io_BlockStart_l
				move.l	d1,io_BlockLength_l
				move.l	d0,io_BlockStart_l
				move.l	d1,io_BlockLength_l
				move.l	d0,a0
				cmp.l	#'=SB=',(a0)
				beq		io_PostProcessLoaded
				cmp.l	#'CSFX',(a0)
				beq		io_LoadSample

				IFD MEMTRACK
				SERPRINTF <"LOAD-DONE",13,10>
				ENDC

; Return after the File MMIO fallback.
				GETREGS

				move.l	io_BlockStart_l,d0
				move.l	io_BlockLength_l,d1
				rts

io_LoadFailure:	; a5 = filename
				move.l	a5,-(a7)
				move.l	a7,a1
				lea		.errfmt(pc),a0
				move.l	#1,d0 ; Error code 1
				bra		Sys_FatalError
.errfmt:		dc.b 'Error loading file:',10,'%s',0
				even

io_LoadSample:
				add.l	#4,d0					;Skip "CSFX"
				move.l	d1,.compressed_sample_size_l
				move.l	d0,a0
				move.l	(a0)+,d0				;file size
				move.l	d0,.sample_size_l
				move.l	a0,.compressed_sample_position_l
				move.l	#MEMF_ANY,d1
				jsr		Sys_AllocVec
				move.l	d0,.sample_position_l
				move.l	.compressed_sample_position_l,a0
				move.l	d0,a1
				move.l	.sample_size_l,d0
				sub.w	#2,d0
				move.b	(a0)+,d1				;first byte (actual value)
				move.b	d1,(a1)+
				lea		.fibonnaci_lookup_vb(pc),a2

.decompress_loop:
				move.b	(a0)+,d2
				and.w	#$00ff,d2
				move.w	d2,d3
				lsr.w	#4,d2
				and.w	#$000f,d3
				move.b	(a2,d2.w),d4			;first fib value
				add.b	d4,d1
				move.b	d1,(a1)+				;store sample value
				dbra	d0,.continue
				bra.s	.sample_finished

.continue:
				move.b	(a2,d3.w),d4			;second fib value
				add.b	d4,d1
				move.b	d1,(a1)+				;store sample value
				dbra	d0,.decompress_loop

.sample_finished:
				move.l	.compressed_sample_position_l,a1
				sub.l	#8,a1

				CALLEXEC FreeVec

				;Now check the sample and clip it if it ever gets
				;too big

				move.l	.sample_position_l,a0
				move.l	.sample_size_l,d0
				sub.w	#1,d0
.clip_loop:
				move.b	(a0),d1
				cmp.b	#64,d1
				blt.s	.not_too_big
				move.b	#63,d1

.not_too_big:
				cmp.b	#-64,d1
				bge.s	.not_too_small
				move.b	#-64,d1

.not_too_small:
				move.b	d1,(a0)+
				dbra	d0,.clip_loop

				IFD MEMTRACK
				SERPRINTF <"LOAD-DONE",13,10>
				ENDC

				GETREGS

				move.l	.sample_position_l,d0
				move.l	.sample_size_l,d1
				rts

				CNOP 0, 4
.compressed_sample_position_l:	dc.l 0
.compressed_sample_size_l:		dc.l 0
.sample_position_l:				dc.l 0
.sample_size_l:					dc.l 0
.fibonnaci_lookup_vb:			dc.b -34,-21,-13,-8,-5,-3,-2,-1,0,1,2,3,5,8,13,21

io_HandlePacked:
				move.l	4(a0),d0				; length of unpacked file.
					move.l	d0,io_unpacked_length_l
				move.l	IO_MemType_l,d1
				jsr		Sys_AllocVec

					move.l	d0,io_unpacked_start_l
				move.l	io_BlockStart_l,a0
				move.l	8(a0),d2
				cmp.l	io_unpacked_length_l,d2
				beq.s	.copy_stored
				move.l	io_BlockStart_l,d0
				moveq	#0,d1
					move.l	io_unpacked_start_l,a0
					move.l	#io_unlha_temp_buffer_vl,a1
				IFD		IS_IE
				lea		io_unlha_large_workspace_vb,a2
				ELSE
				lea		$0,a2
				ENDC
				jsr		unLHA
				bra.s	.unpacked_ready

.copy_stored:
				move.l	io_BlockStart_l,a0
				lea		12(a0),a0
				move.l	io_unpacked_start_l,a1
				move.l	io_unpacked_length_l,d0
				beq.s	.unpacked_ready
				subq.l	#1,d0
.copy_stored_loop:
				move.b	(a0)+,(a1)+
				subq.l	#1,d0
				bpl.s	.copy_stored_loop

.unpacked_ready:

				move.l	io_BlockStart_l,d1
				move.l	d1,a1
				CALLEXEC FreeVec

				move.l	io_unpacked_start_l,d0
				move.l	io_unpacked_length_l,d1
				move.l	d0,io_BlockStart_l
				move.l	d1,io_BlockLength_l
				move.l	d0,a0
				cmp.l	#'=SB=',(a0)
				beq		io_PostProcessLoaded
				cmp.l	#'CSFX',(a0)
				beq		io_LoadSample

				IFD MEMTRACK
				SERPRINTF <"LOAD-DONE",13,10>
				ENDC

				GETREGS

					move.l	io_unpacked_start_l,d0
					move.l	io_unpacked_length_l,d1
				rts

					IFD		IS_IE
; IE MMIO file load helper.
; in: a0 -> filename (possibly "VOL:path")
; out: d0=ptr (or 0 on fail), d1=len
io_ie_load_to_heap:
					movem.l	d2-d7/a1-a6,-(a7)
					bsr		io_ie_normalize_name
					move.l	IO_IE_HEAP_PTR,d0
					tst.l	d0
					bne.s	.have_heap
					move.l	#IO_IE_HEAP_BASE,d0
					move.l	d0,IO_IE_HEAP_PTR
.have_heap:
					move.l	d0,d2
					lea		io_ie_path_vb,a0
					bsr		io_ie_is_boot_path
					tst.l	d0
					beq.s	.try_pack_ie
					lea		io_ie_save_name(pc),a0
					move.l	d2,FILE_IO_DATA
					move.l	a0,FILE_IO_NAME
					move.l	#1,FILE_IO_CTRL
					tst.l	FILE_IO_STATUS
					beq		.loaded_ie
.try_pack_ie:
					lea		io_ie_path_vb,a0
					bsr		io_ie_pack_find
					tst.l	d0
					beq.s	.try_file_ie
					move.l	d0,a0
					move.l	d2,a1
					bsr		io_ie_pack_copy
					tst.l	d0
					beq		.fail
					movem.l	(a7)+,d2-d7/a1-a6
					rts
.try_file_ie:
					bsr		io_ie_make_repo_root_build_path
					tst.l	d0
					beq.s	.try_parent_media_ie
					move.l	d0,a6
					bsr		.try_pack_candidate_ie
					tst.l	d0
					bne		.packed_ie
					move.l	d2,FILE_IO_DATA
					move.l	a6,FILE_IO_NAME
					move.l	#1,FILE_IO_CTRL
					move.l	FILE_IO_STATUS,d6
					tst.l	d6
					beq		.loaded_ie
.try_parent_media_ie:
					bsr		io_ie_make_parent_media_path
					tst.l	d0
					beq.s	.try_normal_ie
					move.l	d0,a6
					bsr		.try_pack_candidate_ie
					tst.l	d0
					bne		.packed_ie
					move.l	d2,FILE_IO_DATA
					move.l	a6,FILE_IO_NAME
					move.l	#1,FILE_IO_CTRL
					move.l	FILE_IO_STATUS,d6
					tst.l	d6
					beq		.loaded_ie
.try_normal_ie:
					lea		io_ie_path_vb,a0
					move.l	a0,FILE_IO_NAME
					move.l	d2,FILE_IO_DATA
					move.l	#1,FILE_IO_CTRL
					move.l	FILE_IO_STATUS,d6
					tst.l	d6
					beq		.loaded_ie
					bsr		io_ie_make_repo_root_ie_path
					tst.l	d0
					beq.s	.try_unpacked_ie
					move.l	d0,a6
					bsr		.try_pack_candidate_ie
					tst.l	d0
					bne		.packed_ie
					move.l	d2,FILE_IO_DATA
					move.l	a6,FILE_IO_NAME
					move.l	#1,FILE_IO_CTRL
					move.l	FILE_IO_STATUS,d6
					tst.l	d6
					beq		.loaded_ie
.try_unpacked_ie:
					bsr		io_ie_make_unpacked_media_path
					tst.l	d0
					beq.s	.fail
					move.l	d0,a6
					bsr		.try_pack_candidate_ie
					tst.l	d0
					bne		.packed_ie
					move.l	d2,FILE_IO_DATA
					move.l	a6,FILE_IO_NAME
					move.l	#1,FILE_IO_CTRL
					move.l	FILE_IO_STATUS,d6
					tst.l	d6
					bne.s	.fail
.loaded_ie:
					move.l	FILE_IO_LEN,d1
					move.l	d1,d3
				addq.l	#3,d3
				andi.l	#$FFFFFFFC,d3
				move.l	d2,d4
				add.l	d3,d4
				cmp.l	#IO_IE_HEAP_LIMIT,d4
				bhi.s	.fail
				move.l	d4,IO_IE_HEAP_PTR
					move.l	d2,d0
					bra.s	.packed_ie
.try_pack_candidate_ie:
					move.l	d0,a0
					bsr		io_ie_pack_find
					tst.l	d0
					beq.s	.pack_candidate_miss_ie
					move.l	d0,a0
					move.l	d2,a1
					bsr		io_ie_pack_copy
.pack_candidate_miss_ie:
					rts
.packed_ie:
					movem.l	(a7)+,d2-d7/a1-a6
					rts
.fail:
					clr.l	d0
					clr.l	d1
					movem.l	(a7)+,d2-d7/a1-a6
					rts

; IE MMIO file write helper.
; in: a0 -> filename (possibly "VOL:path"), d0 -> data, d1 = length
; out: d0 = 0 on success, nonzero on failure
io_ie_write_buffer:
					movem.l	d2-d7/a1-a6,-(a7)
					move.l	d0,d2
					move.l	d1,d3
					bsr		io_ie_normalize_name
					lea		io_ie_path_vb,a0
					bsr		io_ie_is_boot_path
					tst.l	d0
					beq.s	.normal_write_ie
					lea		io_ie_save_name(pc),a0
					move.l	a0,d0
					bsr		.write_candidate_ie
					bra		.finish_save_write_ie
.normal_write_ie:
					bsr		io_ie_make_repo_root_build_path
					tst.l	d0
					beq.s	.try_parent_media_write_ie
					bsr		.write_candidate_ie
					tst.l	d0
					beq.s	.done_write_ie
.try_parent_media_write_ie:
					bsr		io_ie_make_parent_media_path
					tst.l	d0
					beq.s	.try_normal_write_ie
					bsr		.write_candidate_ie
					tst.l	d0
					beq.s	.done_write_ie
.try_normal_write_ie:
					lea		io_ie_path_vb,a0
					move.l	a0,d0
					bsr		.write_candidate_ie
					tst.l	d0
					beq.s	.done_write_ie
					bsr		io_ie_make_repo_root_ie_path
					tst.l	d0
					beq.s	.try_unpacked_write_ie
					bsr		.write_candidate_ie
					tst.l	d0
					beq.s	.done_write_ie
.try_unpacked_write_ie:
					bsr		io_ie_make_unpacked_media_path
					tst.l	d0
					beq.s	.fail_write_ie
					bsr		.write_candidate_ie
					tst.l	d0
					beq.s	.done_write_ie
.fail_write_ie:
					moveq	#1,d0
.finish_save_write_ie:
					movem.l	(a7)+,d2-d7/a1-a6
					rts
.done_write_ie:
					moveq	#0,d0
					movem.l	(a7)+,d2-d7/a1-a6
					rts
.write_candidate_ie:
					move.l	d0,FILE_IO_NAME
					move.l	d2,FILE_IO_DATA
					move.l	d3,FILE_IO_DATA_LEN
					move.l	#2,FILE_IO_CTRL
					move.l	FILE_IO_STATUS,d0
					rts

; Return non-zero when a canonical path ends with /boot.dat or is boot.dat.
io_ie_is_boot_path:
				movem.l	d1-d2/a0-a2,-(a7)
				move.l	a0,a1
				move.l	a0,a2
.scan_boot_path:
				move.b	(a1)+,d1
				beq.s	.compare_boot_name
				cmpi.b	#'/',d1
				bne.s	.scan_boot_path
				move.l	a1,a2
				bra.s	.scan_boot_path
.compare_boot_name:
				lea		io_ie_boot_name(pc),a1
.compare_boot_byte:
				move.b	(a1)+,d1
				move.b	(a2)+,d2
				cmp.b	d1,d2
				bne.s	.not_boot_path
				tst.b	d1
				bne.s	.compare_boot_byte
				moveq	#1,d0
				bra.s	.boot_path_done
.not_boot_path:
				moveq	#0,d0
.boot_path_done:
				movem.l	(a7)+,d1-d2/a0-a2
				rts

; Copy one verified packed asset into the existing file heap.
; in: a0=source, a1=destination, d1=length
; out: d0=destination or zero, d1=length
io_ie_pack_copy:
				movem.l	d2-d4/a0-a2,-(a7)
				move.l	d1,d2
				move.l	d1,d3
				addq.l	#3,d3
				andi.l	#$FFFFFFFC,d3
				move.l	a1,d4
				add.l	d3,d4
				bcs.s	.pack_copy_fail
				cmp.l	#IO_IE_HEAP_LIMIT,d4
				bhi.s	.pack_copy_fail
				move.l	a1,d0
				tst.l	d2
				beq.s	.pack_copy_done
.copy_pack_byte:
				move.b	(a0)+,(a1)+
				subq.l	#1,d2
				bne.s	.copy_pack_byte
.pack_copy_done:
				move.l	d4,IO_IE_HEAP_PTR
				movem.l	(a7)+,d2-d4/a0-a2
				move.l	a1,d0
				rts
.pack_copy_fail:
				movem.l	(a7)+,d2-d4/a0-a2
				clr.l	d0
				clr.l	d1
				rts

; Find a canonical path in the pack loaded as part of the IE68 image.
; in: a0=path, out: d0=source and d1=length, or both zero.
io_ie_pack_find:
				movem.l	d2-d7/a1-a6,-(a7)
				move.l	a0,a3
				bsr		io_ie_pack_validate
				tst.l	d0
				beq		.pack_find_fail
				lea		IE_PACK_HEADER,a6
				move.l	12(a6),d6
				lea		36(a6),a4
				move.l	a4,a5
				add.l	16(a6),a5
.pack_entry_loop:
				tst.l	d6
				beq		.pack_find_fail
				move.l	a4,d0
				add.l	#16,d0
				bcs		.pack_find_fail
				cmp.l	a5,d0
				bhi		.pack_find_fail
				moveq	#0,d2
				move.w	(a4),d2
				tst.w	2(a4)
				bne		.pack_find_fail
				move.l	a4,d7
				add.l	#16,d7
				add.l	d2,d7
				addq.l	#3,d7
				andi.l	#$FFFFFFFC,d7
				cmp.l	a5,d7
				bhi		.pack_find_fail
				lea		16(a4),a1
				move.l	a3,a2
				move.l	d2,d0
				beq.s	.path_length_done
.compare_pack_path:
				cmpm.b	(a1)+,(a2)+
				bne.s	.next_pack_entry
				subq.l	#1,d0
				bne.s	.compare_pack_path
.path_length_done:
				tst.b	(a2)
				bne.s	.next_pack_entry
				move.l	4(a4),d3
				move.l	8(a4),d4
				move.l	12(a4),d5
				cmp.l	#IE_PACK_DATA_BASE-IE_PACK_LOAD_BASE,d3
				blo		.pack_find_fail
				move.l	d3,d0
				add.l	d4,d0
				bcs		.pack_find_fail
				cmp.l	24(a6),d0
				bhi		.pack_find_fail
				move.l	d3,a0
				add.l	#IE_PACK_LOAD_BASE,a0
				move.l	d4,d0
				bsr		io_ie_crc32
				eor.l	d5,d0
				tst.l	d0
				bne		.pack_find_fail
				move.l	d3,d0
				add.l	#IE_PACK_LOAD_BASE,d0
				move.l	d4,d1
				movem.l	(a7)+,d2-d7/a1-a6
				rts
.next_pack_entry:
				move.l	d7,a4
				subq.l	#1,d6
				bra		.pack_entry_loop
.pack_find_fail:
				clr.l	d0
				clr.l	d1
				movem.l	(a7)+,d2-d7/a1-a6
				rts

; Validate the fixed header and the complete variable-length table.
io_ie_pack_validate:
				movem.l	d1-d7/a0-a2,-(a7)
				move.l	io_ie_pack_validation_l,d0
				beq.s	.validate_pack_now
				bmi		.pack_invalid_cached
				moveq	#1,d0
				bra		.pack_validate_done
.validate_pack_now:
				moveq	#1,d4
				lea		IE_PACK_HEADER,a2
				move.l	(a2),d0
				eor.l	#IE_PACK_MAGIC,d0
				tst.l	d0
				bne		.pack_invalid
				addq.l	#1,d4
				move.l	4(a2),d0
				eor.l	#IE_PACK_MAGIC_2,d0
				tst.l	d0
				bne		.pack_invalid
				addq.l	#1,d4
				move.l	8(a2),d0
				eor.l	#IE_PACK_VERSION,d0
				tst.l	d0
				bne		.pack_invalid
				addq.l	#1,d4
				move.l	12(a2),d6
				cmp.l	#4096,d6
				bhi		.pack_invalid
				addq.l	#1,d4
				move.l	16(a2),d7
				cmp.l	#IE_PACK_DATA_BASE-IE_PACK_HEADER-36,d7
				bhi		.pack_invalid
				addq.l	#1,d4
				move.l	20(a2),d0
				eor.l	#IE_PACK_DATA_BASE-IE_PACK_LOAD_BASE,d0
				tst.l	d0
				bne		.pack_invalid
				addq.l	#1,d4
				move.l	24(a2),d5
				cmp.l	20(a2),d5
				blo		.pack_invalid
				addq.l	#1,d4
				cmp.l	#IE_PACK_DATA_LIMIT-IE_PACK_LOAD_BASE,d5
				bhi		.pack_invalid
				addq.l	#1,d4
				move.l	a2,a0
				moveq	#28,d0
				bsr		io_ie_crc32
				move.l	28(a2),d1
				eor.l	d1,d0
				tst.l	d0
				bne		.pack_invalid
				addq.l	#1,d4
				lea		36(a2),a0
				move.l	d7,d0
				bsr		io_ie_crc32
				move.l	32(a2),d1
				eor.l	d1,d0
				tst.l	d0
				bne		.pack_invalid
				clr.l	io_ie_pack_error_l
				move.l	#1,io_ie_pack_validation_l
				moveq	#1,d0
				bra.s	.pack_validate_done
.pack_invalid:
				move.l	d4,io_ie_pack_error_l
				move.l	#-1,io_ie_pack_validation_l
.pack_invalid_cached:
				moveq	#0,d0
.pack_validate_done:
				movem.l	(a7)+,d1-d7/a0-a2
				rts

; Calculate the standard CRC-32 used by the packer.
; in: a0=data, d0=length, out: d0=checksum
io_ie_crc32:
				movem.l	d1-d4/a0-a1,-(a7)
				move.l	d0,d3
				moveq	#-1,d1
				lea		io_ie_crc32_nibbles(pc),a1
				tst.l	d3
				beq.s	.crc_done_bytes
.crc_byte:
				moveq	#0,d2
				move.b	(a0)+,d2
				eor.l	d2,d1
				moveq	#1,d4
.crc_nibble:
				move.l	d1,d2
				andi.l	#$0F,d2
				lsl.l	#2,d2
				lsr.l	#4,d1
				move.l	(a1,d2.l),d2
				eor.l	d2,d1
				dbra	d4,.crc_nibble
				subq.l	#1,d3
				bne.s	.crc_byte
.crc_done_bytes:
				not.l	d1
				move.l	d1,d0
				movem.l	(a7)+,d1-d4/a0-a1
				rts

io_ie_crc32_nibbles:
				dc.l	$00000000,$1DB71064,$3B6E20C8,$26D930AC
				dc.l	$76DC4190,$6B6B51F4,$4DB26158,$5005713C
				dc.l	$EDB88320,$F00F9344,$D6D6A3E8,$CB61B38C
				dc.l	$9B64C2B0,$86D3D2D4,$A00AE278,$BDBDF21C

io_ie_boot_name:
				dc.b	'boot.dat',0
io_ie_save_name:
				dc.b	'ab3d2-save.dat',0
				even
io_ie_pack_error_l:
				dc.l	0
io_ie_pack_validation_l:
				dc.l	0

io_ie_make_unpacked_media_path:
				lea		io_ie_path_vb,a0
				cmpi.b	#'m',(a0)
				bne.s	.no_unpacked
				cmpi.b	#'e',1(a0)
				bne.s	.no_unpacked
				cmpi.b	#'d',2(a0)
				bne.s	.no_unpacked
				cmpi.b	#'i',3(a0)
				bne.s	.no_unpacked
				cmpi.b	#'a',4(a0)
				bne.s	.no_unpacked
				cmpi.b	#'/',5(a0)
				bne.s	.no_unpacked
				lea		io_ie_unpacked_path_vb,a1
				lea		.ie_unpacked_prefix(pc),a2
.copy_unpacked_prefix:
				move.b	(a2)+,d0
				beq.s	.copy_unpacked_path
				move.b	d0,(a1)+
				bra.s	.copy_unpacked_prefix
.copy_unpacked_path:
				move.w	#IO_MAX_FILENAME_LEN,d7
.copy_unpacked:
				move.b	(a0)+,d0
				move.b	d0,(a1)+
				beq.s	.done_unpacked
				dbra	d7,.copy_unpacked
				clr.b	(a1)
.done_unpacked:
				lea		io_ie_unpacked_path_vb,a0
				move.l	a0,d0
				rts
.no_unpacked:
				clr.l	d0
				rts
.ie_unpacked_prefix:
				dc.b	'_build/ie_unpacked/',0
				even

io_ie_make_parent_media_path:
				lea		io_ie_path_vb,a0
				cmpi.b	#'m',(a0)
				bne.s	.no_alt
				cmpi.b	#'e',1(a0)
				bne.s	.no_alt
				cmpi.b	#'d',2(a0)
				bne.s	.no_alt
				cmpi.b	#'i',3(a0)
				bne.s	.no_alt
				cmpi.b	#'a',4(a0)
				bne.s	.no_alt
				cmpi.b	#'/',5(a0)
				bne.s	.no_alt
				lea		io_ie_alt_path_vb,a1
				move.b	#'.',(a1)+
				move.b	#'.',(a1)+
				move.b	#'/',(a1)+
				move.w	#IO_MAX_FILENAME_LEN,d7
.copy_alt:
				move.b	(a0)+,d0
				move.b	d0,(a1)+
				beq.s	.done_alt
				dbra	d7,.copy_alt
				clr.b	(a1)
.done_alt:
				lea		io_ie_alt_path_vb,a0
				move.l	a0,d0
				rts
.no_alt:
				clr.l	d0
				rts

io_ie_make_repo_root_build_path:
				lea		io_ie_path_vb,a0
				cmpi.b	#'_',(a0)
				bne.s	.no_build_alt
				cmpi.b	#'b',1(a0)
				bne.s	.no_build_alt
				cmpi.b	#'u',2(a0)
				bne.s	.no_build_alt
				cmpi.b	#'i',3(a0)
				bne.s	.no_build_alt
				cmpi.b	#'l',4(a0)
				bne.s	.no_build_alt
				cmpi.b	#'d',5(a0)
				bne.s	.no_build_alt
				cmpi.b	#'/',6(a0)
				bne.s	.no_build_alt
				lea		io_ie_alt_path_vb,a1
				lea		io_ie_source_prefix(pc),a2
.copy_profile_prefix:
				move.b	(a2)+,d0
				beq.s	.copy_profile_path
				move.b	d0,(a1)+
				bra.s	.copy_profile_prefix
.copy_profile_path:
				move.w	#IO_MAX_FILENAME_LEN,d7
.copy_profile_alt:
				move.b	(a0)+,d0
				move.b	d0,(a1)+
				beq.s	.done_profile_alt
				dbra	d7,.copy_profile_alt
				clr.b	(a1)
.done_profile_alt:
				lea		io_ie_alt_path_vb,a0
				move.l	a0,d0
				rts
.no_build_alt:
				clr.l	d0
				rts
io_ie_source_prefix:
				dc.b	'ab3d2_source/',0
				even

io_ie_make_repo_root_ie_path:
				lea		io_ie_path_vb,a0
				cmpi.b	#'i',(a0)
				bne.s	.no_ie_alt
				cmpi.b	#'e',1(a0)
				bne.s	.no_ie_alt
				cmpi.b	#'/',2(a0)
				bne.s	.no_ie_alt
				lea		io_ie_alt_path_vb,a1
				lea		io_ie_source_prefix(pc),a2
.copy_ie_prefix:
				move.b	(a2)+,d0
				beq.s	.copy_ie_path
				move.b	d0,(a1)+
				bra.s	.copy_ie_prefix
.copy_ie_path:
				move.w	#IO_MAX_FILENAME_LEN,d7
.copy_ie_alt:
				move.b	(a0)+,d0
				move.b	d0,(a1)+
				beq.s	.done_ie_alt
				dbra	d7,.copy_ie_alt
				clr.b	(a1)
.done_ie_alt:
				lea		io_ie_alt_path_vb,a0
				move.l	a0,d0
				rts
.no_ie_alt:
				clr.l	d0
				rts

; Normalize Amiga-style path into io_ie_path_vb and return a0=normalized ptr.
io_ie_normalize_name:
				move.l	a0,a1
				clr.b	io_ie_volume_is_sfx_b
.find_colon:
				move.b	(a1)+,d0
				beq.s	.copy_start
				cmpi.b	#':',d0
				bne.s	.find_colon
				move.b	(a0),d0
				ori.b	#$20,d0
				cmpi.b	#'s',d0
				bne.s	.not_sfx_volume
				move.b	1(a0),d0
				ori.b	#$20,d0
				cmpi.b	#'f',d0
				bne.s	.not_sfx_volume
				move.b	2(a0),d0
				ori.b	#$20,d0
				cmpi.b	#'x',d0
				bne.s	.not_sfx_volume
				st		io_ie_volume_is_sfx_b
.not_sfx_volume:
				move.l	a1,a0
.copy_start:
				lea		io_ie_path_vb,a1
				move.w	#IO_MAX_FILENAME_LEN,d7
				tst.b	io_ie_volume_is_sfx_b
				beq.s	.not_sfx_path
				lea		.ie_sfx_prefix(pc),a2
				bra		.copy_selected_prefix
.not_sfx_path:
				cmpi.b	#'s',(a0)
				bne.s	.not_samples_path
				cmpi.b	#'a',1(a0)
				bne.s	.not_samples_path
				cmpi.b	#'m',2(a0)
				bne.s	.not_samples_path
				cmpi.b	#'p',3(a0)
				bne.s	.not_samples_path
				cmpi.b	#'l',4(a0)
				bne.s	.not_samples_path
				cmpi.b	#'e',5(a0)
				bne.s	.not_samples_path
				cmpi.b	#'s',6(a0)
				bne.s	.not_samples_path
				cmpi.b	#'/',7(a0)
				bne.s	.not_samples_path
				lea		.ie_sfx_prefix(pc),a2
				bra		.copy_selected_prefix
.not_samples_path:
				cmpi.b	#'i',(a0)
				bne.s	.not_ie_path
				cmpi.b	#'e',1(a0)
				bne.s	.not_ie_path
				cmpi.b	#'/',2(a0)
				beq.s	.media_prefix_done
.not_ie_path:
				cmpi.b	#'m',(a0)
				bne.s	.use_media_prefix
				cmpi.b	#'e',1(a0)
				bne.s	.use_media_prefix
				cmpi.b	#'d',2(a0)
				bne.s	.use_media_prefix
				cmpi.b	#'i',3(a0)
				bne.s	.use_media_prefix
				cmpi.b	#'a',4(a0)
				bne.s	.use_media_prefix
				cmpi.b	#'/',5(a0)
				beq.s	.media_prefix_done
.use_media_prefix:
				lea		.ie_media_prefix(pc),a2
.copy_selected_prefix:
.media_prefix_loop:
				move.b	(a2)+,d0
				beq.s	.media_prefix_done
				move.b	d0,(a1)+
				subq.w	#1,d7
				bra.s	.media_prefix_loop
.media_prefix_done:
				cmpi.b	#'l',(a0)
				bne.s	.copy_loop
				cmpi.b	#'e',1(a0)
				bne.s	.copy_loop
				cmpi.b	#'v',2(a0)
				bne.s	.copy_loop
				cmpi.b	#'e',3(a0)
				bne.s	.copy_loop
				cmpi.b	#'l',4(a0)
				bne.s	.copy_loop
				cmpi.b	#'s',5(a0)
				bne.s	.copy_loop
				cmpi.b	#'/',6(a0)
				bne.s	.copy_loop
				lea		.ie_levels_prefix(pc),a2
.prefix_loop:
				move.b	(a2)+,d0
				beq.s	.prefix_done
				move.b	d0,(a1)+
				subq.w	#1,d7
				bra.s	.prefix_loop
.prefix_done:
				addq.l	#7,a0
.copy_loop:
				move.b	(a0)+,d0
				cmpi.b	#92,d0
				bne.s	.store
				moveq	#47,d0
.store:
				cmpi.b	#'A',d0
				blt.s	.store_byte
				cmpi.b	#'Z',d0
				bgt.s	.store_byte
				addi.b	#32,d0
.store_byte:
				move.b	d0,(a1)+
				beq.s	.done
				dbra	d7,.copy_loop
				clr.b	(a1)
.done:
				lea		io_ie_path_vb,a0
				rts
				include	"media_profile.i"
.ie_levels_prefix:
				dc.b	'levels_editor_uncompressed/',0
				even
					ENDC

				CNOP 0, 4
io_unpacked_start_l:	dc.l	0
io_unpacked_length_l:	dc.l	0

				section .bss,bss
io_unlha_temp_buffer_vl:
				ds.l	4096		; unLHA wants 16kb
					IFD		IS_IE
io_unlha_large_workspace_vb:
				ds.b	65536		; unLHA wants a second 65kb workspace in a2
				align 4
io_ie_path_vb:	ds.b 160
io_ie_alt_path_vb:	ds.b 164
io_ie_unpacked_path_vb:	ds.b 180
io_ie_volume_is_sfx_b:	ds.b 1
				align 4
					ENDC

				section .text,code
_unLHA::
unLHA:			incbin	"decomp4.raw"
