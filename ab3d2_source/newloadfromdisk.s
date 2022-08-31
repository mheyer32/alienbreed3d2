******************************************************
; Memory class to use for next loaded entity
IO_MemType_l:			dc.l	0

; dos.llibrary file handle
IO_DOSFileHandle_l:		dc.l	0

; Private stuff
io_EndOfQueue_l:		dc.l	0

; Array of object pointers
io_ObjectPointers_vl:	ds.l	160

; block properties
io_BlockLength_l:		dc.l	0
io_BlockName_l:			dc.l	0
io_BlockStart_l:		dc.l	0

; Pointer to the file extension (i.e. the substring starting at .)
io_FileExtPointer_l:	dc.l	0

io_ObjectName_vb:		ds.b	160
io_Buffer_vb:			ds.b	80   ; todo - can these be merged ?

IO_MAX_FILENAME_LEN	EQU 79

IO_InitQueue:
				move.l	#WorkSpace,io_EndOfQueue_l
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
				tst.b	d6
				beq		.loaded_all

* Find first unloaded file and prompt for disk.
				move.l	#WorkSpace,a2

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

; move.w #23,FADEAMOUNT
; jsr FADEDOWNTITLE

; move.w #3,OptScrn
; move.w #0,OPTNUM
; jsr DRAWOPTSCRN

				jsr		mnu_setscreen

				lea		mnu_askfordisk,a0
				jsr		mnu_domenu

				jsr		mnu_clearscreen


;.wtrel:
; btst #7,$bfe001
; beq.s .wtrel
;
;.wtclick:
; btst #6,$bfe001
; bne.s .wtclick

; jsr CLROPTSCRN

; move.w #23,FADEAMOUNT
; jsr FADEUPTITLE

				movem.l	(a7)+,d0-d7/a0-a6
				bsr		io_FlushPass
				bra		.retry

.loaded_all:
				rts

io_FlushPass:
				move.l	#WorkSpace,a2
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
				move.l	#1005,d2
				CALLDOS	Open

				movem.l	(a7)+,d1-d7/a0-a6
				rts

***************************************************

IO_LoadObjects:
; PRSDG
				move.l	#io_ObjectPointers_vl,a2
				move.l	LINKFILE,a0
				lea		ObjectGfxNames(a0),a0
				move.l	#MEMF_ANY,IO_MemType_l
				move.l	#Objects,a1

io_LoadMoreObjects:
				move.l	a0,a4
				move.l	#io_ObjectName_vb,a3

.fill_name:
				move.b	(a4)+,d0
				beq.s	.done_name
				move.b	d0,(a3)+
				bra.s	.fill_name

.done_name:
				move.l	a0,-(a7)
				move.l	a3,io_FileExtPointer_l
				move.b	#'.',(a3)+
				move.b	#'W',(a3)+
				move.b	#'A',(a3)+
				move.b	#'D',(a3)+
				move.b	#0,(a3)+
				move.l	#io_ObjectName_vb,a0
				move.l	a1,d0
				moveq	#0,d1
				bsr		IO_QueueFile

				move.l	io_FileExtPointer_l,a3
				move.b	#'.',(a3)+
				move.b	#'P',(a3)+
				move.b	#'T',(a3)+
				move.b	#'R',(a3)+
				move.b	#0,(a3)+
				move.l	#io_ObjectName_vb,a0
				move.l	a1,d0
				add.l	#4,d0
				moveq	#0,d1
				bsr		IO_QueueFile

				move.l	io_FileExtPointer_l,a3
				move.b	#'.',(a3)+
				move.b	#'2',(a3)+
				move.b	#'5',(a3)+
				move.b	#'6',(a3)+
				move.b	#'P',(a3)+
				move.b	#'A',(a3)+
				move.b	#'L',(a3)+
				move.b	#0,(a3)+
				move.l	#io_ObjectName_vb,a0
				move.l	a1,d0
				add.l	#12,d0
				moveq	#0,d1
				bsr		IO_QueueFile

				move.l	(a7)+,a0
				add.l	#64,a0
				add.l	#16,a1
				tst.b	(a0)
				bne		io_LoadMoreObjects

				move.l	#POLYOBJECTS,a2
				move.l	LINKFILE,a0
				add.l	#VectorGfxNames,a0

.load_vector_loop:
				tst.b	(a0)
				beq.s	.end_load_vectors

				move.l	a2,d0
				moveq	#0,d1
				jsr		IO_QueueFile
				addq	#4,a2

				adda.w	#64,a0
				bra.s	.load_vector_loop

.end_load_vectors:
				rts

				CNOP	0,4	; FileInfoBlock must be 4-byte aligned
io_FileInfoBlock_vb:			ds.b	fib_SIZEOF

Res_FreeObjects:
				move.l	#io_ObjectPointers_vl,a2

.release_obj_loop:
				move.l	(a2)+,io_BlockStart_l
				move.l	(a2)+,io_BlockLength_l
				tst.l	io_BlockStart_l
				ble.s	.end_release_obj

				move.l	a2,-(a7) ; is this necessary? Does a2 get clobbered by FreeVec?
				move.l	io_BlockStart_l,d1
				move.l	d1,a1
				CALLEXEC FreeVec

				move.l	(a7)+,a2
				bra.s	.release_obj_loop

.end_release_obj:
				rts

IO_LoadSoundFx:
				move.l	LINKFILE,a0
				lea		SFXFilenames(a0),a0
				move.l	#SampleList,a1
				move.w	#58,d7

.load_sound_loop:
				tst.b	(a0)
				bne.s	.ok_to_load

				add.w	#64,a0
				addq	#8,a1
				dbra	d7,.load_sound_loop
				move.l	#-1,(a1)+
				rts

.ok_to_load:
				move.l	#MEMF_ANY,IO_MemType_l
				move.l	a1,d0
				move.l	d0,d1
				add.l	#4,d1
				jsr		IO_QueueFile

				addq	#8,a1
; move.l d0,(a1)+
; add.l d1,d0
; move.l d0,(a1)+
				adda.w	#64,a0
				dbra	d7,.load_sound_loop
				move.l	#MEMF_ANY,IO_MemType_l
				rts

Audio_PatchSounds:
				move.w	#58,d7
				move.l	#SampleList,a1

.patch_loop:
				move.l	(a1)+,d0
				add.l	d0,(a1)+
				dbra	d7,.patch_loop

				rts

IO_LoadFloorTextures:
				move.l	LINKFILE,a0
				add.l	#FloorTileFilename,a0
				move.l	#floortile,d0
				move.l	#0,d1
				move.l	#MEMF_ANY,IO_MemType_l
				jsr		IO_QueueFile

; move.l d0,floortile
				move.l	LINKFILE,a0
				add.l	#TextureFilename,a0
				move.l	#io_Buffer_vb,a1

.copy_loop:
				move.b	(a0)+,(a1)+
				beq.s	.copied
				bra.s	.copy_loop
.copied:

				subq	#1,a1
				move.l	a1,io_FileExtPointer_l
				move.l	#io_Buffer_vb,a0
				move.l	#TextureMaps,d0
				move.l	#0,d1
				jsr		IO_QueueFile

; move.l d0,TextureMaps
				move.l	io_FileExtPointer_l,a1
				move.l	#".pal",(a1)
				move.l	#io_Buffer_vb,a0
				move.l	#TexturePal,d0
				move.l	#0,d1
				jsr		IO_QueueFile

; move.l d0,TexturePal
				rts

Res_FreeSoundFx:
				move.l	#SampleList,a0
.relmem:
				move.l	(a0)+,d1
				bge.s	.okrel
				rts
.okrel:
				move.l	(a0)+,d0
				sub.l	d1,d0
				move.l	d1,a1
				move.l	a0,-(a7)
				CALLEXEC FreeVec
				move.l	(a7)+,a0
				bra		.relmem

Res_FreeLevelData:
				move.l	LINKS,a1
				CALLEXEC FreeVec
				clr.l	LINKS

				move.l	FLYLINKS,a1
				CALLEXEC FreeVec
				clr.l	FLYLINKS

				move.l	LEVELGRAPHICS,a1
				CALLEXEC FreeVec
				clr.l	LEVELGRAPHICS

				move.l	LEVELCLIPS,a1
				CALLEXEC FreeVec
				clr.l	LEVELCLIPS

				move.l	LEVELMUSIC,a1
				CALLEXEC FreeVec
				clr.l	LEVELMUSIC
				rts

Res_FreeFloorTextures:
				move.l	floortile,d1
				CALLEXEC FreeVec
				clr.l	floortile
				rts

Res_ReleaseScreenMemory:
				rts

unLHA:			incbin	"decomp4.raw"
