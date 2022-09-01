

walltiles:		ds.l	40

; todo - this is not currently called
Res_FreeWallTextures:
				move.l	#walltiles,a0
.free_mem:
				move.l	4(a5),d0
				beq.s	.free_all

				move.l	(a0),d1
				beq.s	.not_this_mem

				move.l	d1,a1
				movem.l	a0/a5,-(a7)
				CALLEXEC FreeVec

				movem.l	(a7)+,a0/a5

.not_this_mem:
				addq	#8,a5
				addq	#4,a0
				bra.s	.free_mem

.free_all:
				rts

Res_LoadWallTextures:
				;* New loading system:
				;* Send each filename to a 'server' along with
				;* addresses for the return values (pos,len)
				;* then call FLUSHQUEUE, which actually loads
				;* the files in...

				move.l	#walltiles,a0
				moveq	#39,d7

.empty_walls:
				move.l	#0,(a0)+
				dbra	d7,.empty_walls

				move.l	#walltiles,a4
				move.l	LINKFILE,a3
				add.l	#WallGFXNames,a3
				move.l	#MEMF_ANY,IO_MemType_l

.load_loop:
				move.l	(a3),d0
				beq		.loaded_all

				move.l	a3,a0
				move.l	a4,d0					; address to put start pos
				move.l	#0,d1
				jsr		IO_QueueFile

				addq	#4,a4

				adda.w	#64,a3
				bra		.load_loop

.loaded_all:
				rts

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
				move.l	#1005,d2
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

				section bss,bss
.unlha_temp_buffer_vl:
				ds.l	4096		; unLHA wants 16kb

				section code,code
