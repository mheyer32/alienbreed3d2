
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
FILE_IO_CTRL		EQU $00F220C
FILE_IO_STATUS		EQU $00F2210
FILE_IO_LEN			EQU $00F2214
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

				; todo - just the minimum regs
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

; Not a packed file so just return now.
				GETREGS

				move.l	io_BlockStart_l,d0
				move.l	io_BlockLength_l,d1
				rts

io_LoadFailure:	; a5 = filename
				IFD		IS_IE
				movem.l	d0-d1/a0-a1,-(a7)
				move.l	a5,a0
				lea		io_ie_failed_name_vb,a1
				move.w	#IO_MAX_FILENAME_LEN,d1
.copy_failed_name_ie:
				move.b	(a0)+,d0
				move.b	d0,(a1)+
				beq.s	.failed_name_done_ie
				dbra	d1,.copy_failed_name_ie
				clr.b	(a1)
.failed_name_done_ie:
				movem.l	(a7)+,d0-d1/a0-a1
				ENDC
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
				move.l	io_BlockStart_l,io_ie_unpack_block_l
				lea		io_ie_path_vb,a3
				lea		io_ie_unpack_path_vb,a4
				move.w	#IO_MAX_FILENAME_LEN,d3
.copy_unpack_path_ie:
				move.b	(a3)+,d4
				move.b	d4,(a4)+
				beq.s	.unpack_path_done_ie
				dbra	d3,.copy_unpack_path_ie
				clr.b	(a4)
.unpack_path_done_ie:
				move.l	io_BlockStart_l,a3
				move.l	(a3),io_ie_unpack_head_l
				move.l	4(a3),io_ie_unpack_len_l
				move.l	8(a3),io_ie_unpack_stored_l
				ENDC
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
					bsr		io_ie_make_parent_media_path
					tst.l	d0
					beq.s	.try_normal_ie
					move.l	d2,FILE_IO_DATA
					move.l	d0,FILE_IO_NAME
					move.l	#1,FILE_IO_CTRL
					move.l	FILE_IO_STATUS,d6
					tst.l	d6
					beq.s	.loaded_ie
.try_normal_ie:
					lea		io_ie_path_vb,a0
					move.l	a0,FILE_IO_NAME
					move.l	d2,FILE_IO_DATA
					move.l	#1,FILE_IO_CTRL
					move.l	FILE_IO_STATUS,d6
					tst.l	d6
					beq.s	.loaded_ie
					bsr		io_ie_make_unpacked_media_path
					tst.l	d0
					beq.s	.fail
					move.l	d2,FILE_IO_DATA
					move.l	d0,FILE_IO_NAME
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
				movem.l	(a7)+,d2-d7/a1-a6
				rts
.fail:
					clr.l	d0
					clr.l	d1
					movem.l	(a7)+,d2-d7/a1-a6
					rts

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
				bra.s	.copy_selected_prefix
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
				bra.s	.copy_selected_prefix
.not_samples_path:
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
.ie_media_prefix:
				dc.b	'media/',0
.ie_sfx_prefix:
				dc.b	'media/ab3dsfx/',0
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
io_ie_failed_name_vb:	ds.b 160
io_ie_unpack_path_vb:	ds.b 160
io_ie_volume_is_sfx_b:	ds.b 1
				align 4
io_ie_unpack_block_l:	ds.l 1
io_ie_unpack_head_l:	ds.l 1
io_ie_unpack_len_l:	ds.l 1
io_ie_unpack_stored_l:	ds.l 1
					ENDC

				section .text,code
_unLHA::
unLHA:			incbin	"decomp4.raw"
