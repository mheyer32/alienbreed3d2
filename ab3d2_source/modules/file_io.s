
; *****************************************************************************
; *
; * modules/file_io.s
; *
; * Definitions specific to the loading of data from disk
; *
; * Mostly refactored from newloadfromdisk.s and wallchunk.s
; *
; *****************************************************************************

IO_MAX_FILENAME_LEN	EQU 79

; *****************************************************************************
; *
; * IO Queue
; *
; *****************************************************************************

IO_InitQueue:
				move.l	#Sys_Workspace_vl,io_EndOfQueue_l
				rts

IO_QueueFile:
				; On entry:
				; a0=Pointer to filename
				; d0=Ptr to dest. of addr
				; d1=ptr to dest. of len.
				; typeofmem=type of memory
				movem.l	d0-d7/a0-a6,-(a7)
				move.l	io_EndOfQueue_l,a1
				move.l	d0,(a1)+
				move.l	d1,(a1)+
				move.l	IO_MemType_l,(a1)+
				move.w	#IO_MAX_FILENAME_LEN,d0

.copy_name:
				move.b	(a0)+,(a1)+
				dbra	d0,.copy_name
				add.l	#100,io_EndOfQueue_l
				movem.l	(a7)+,d0-d7/a0-a6
				rts

IO_FlushQueue:
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

				movem.l	d0-d7/a0-a6,-(a7)

				CALLC	mnu_setscreen

				lea		mnu_askfordisk,a0
				jsr		mnu_domenu

				CALLC	mnu_clearscreen


				movem.l	(a7)+,d0-d7/a0-a6
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
				jsr		IO_LoadAndUnpackFile

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
				movem.l	d1-d7/a0-a6,-(a7)
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

IO_LoadAndUnpackFile:
				; Load a file in and unpack it if necessary.
				; Pointer to name in a0
				; Returns address in d0 and length in d1
				movem.l	d0-d7/a0-a6,-(a7)
				bra.s	io_LoadCommon

IO_LoadFile:
				; Load a file in and unpack it if necessary.
				; Pointer to name in a0
				; Returns address in d0 and length in d1

				movem.l	d0-d7/a0-a6,-(a7)
				move.l	a0,d1
				move.l	#MODE_OLDFILE,d2
				CALLDOS	Open

				move.l	d0,IO_DOSFileHandle_l

io_LoadCommon:
				lea		io_FileInfoBlock_vb,a5
				move.l	IO_DOSFileHandle_l,d1
				move.l	a5,d2
				CALLDOS	ExamineFH

				move.l	fib_Size(a5),d0
				move.l	d0,io_BlockLength_l
				add.l	#8,d0			; over-allocate by 8 bytes
				move.l	IO_MemType_l,d1
				CALLEXEC AllocVec

				move.l	d0,io_BlockStart_l
				move.l	IO_DOSFileHandle_l,d1
				move.l	d0,d2
				move.l	io_BlockLength_l,d3
				CALLDOS	Read

				move.l	IO_DOSFileHandle_l,d1
				CALLDOS	Close

				move.l	io_BlockStart_l,a0
				clr.l	(a0,d3.l)		; clear last 8 bytes
				clr.l	4(a0,d3.l)
				move.l	(a0),d0
				cmp.l	#'=SB=',d0
				beq		io_HandlePacked

				move.l	io_BlockStart_l,d0
				move.l	io_BlockLength_l,d1
				move.l	d0,a0
				cmp.l	#'CSFX',(a0)
				beq		io_LoadSample

; Not a packed file so just return now.
				movem.l	(a7)+,d0-d7/a0-a6
				move.l	io_BlockStart_l,d0
				move.l	io_BlockLength_l,d1
				rts

io_LoadSample:
				add.l	#4,d0					;Skip "CSFX"
				move.l	d1,.compressed_sample_size_l
				move.l	d0,a0
				move.l	(a0)+,d0				;file size
				move.l	d0,.sample_size_l
				move.l	a0,.compressed_sample_position_l
				move.l	#MEMF_ANY,d1
				CALLEXEC AllocVec
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

				movem.l	(a7)+,d0-d7/a0-a6
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
				move.l	d0,.unpacked_length_l
				move.l	IO_MemType_l,d1
				CALLEXEC AllocVec

				move.l	d0,.unpacked_start_l
				move.l	io_BlockStart_l,d0
				moveq	#0,d1
				move.l	.unpacked_start_l,a0
				move.l	#.unlha_temp_buffer_vl,a1
				lea		$0,a2
				jsr		unLHA

				move.l	io_BlockStart_l,d1
				move.l	d1,a1
				CALLEXEC FreeVec

				move.l	.unpacked_start_l,d0
				move.l	.unpacked_length_l,d1
				move.l	d0,a0
				cmp.l	#'CSFX',(a0)
				beq		io_LoadSample

				movem.l	(a7)+,d0-d7/a0-a6
				move.l	.unpacked_start_l,d0
				move.l	.unpacked_length_l,d1
				rts

				CNOP 0, 4
.unpacked_start_l:	dc.l	0
.unpacked_length_l:	dc.l	0

				section .bss,bss
.unlha_temp_buffer_vl:
				ds.l	4096		; unLHA wants 16kb

				section .text,code
_unLHA::
unLHA:			incbin	"decomp4.raw"
