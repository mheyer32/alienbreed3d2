
; *****************************************************************************
; *
; * modules/resource.s
; *
; * Definitions specific to the management of resource data (graphics, sounnds,
; * models, level data etc.)
; *
; * Mostly refactored from newloadfromdisk.s and wallchunk.s
; *
; *****************************************************************************

				CNOP	0,4

walltiles:		ds.l	40

; *****************************************************************************
; *
; * Objects (bitmap and vector)
; *
; *****************************************************************************

Res_LoadObjects:
; PRSDG
				move.l	#io_ObjectPointers_vl,a2
				move.l	GLF_DatabasePtr_l,a0
				lea		GLFT_ObjGfxNames_l(a0),a0
				move.l	#MEMF_ANY,IO_MemType_l
				move.l	#Objects,a1

.load_object_loop:
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
				bne		.load_object_loop

				move.l	#Draw_PolyObjects_vl,a2
				move.l	GLF_DatabasePtr_l,a0
				add.l	#GLFT_VectorNames_l,a0

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

; *****************************************************************************
; *
; * Sound Effects
; *
; *****************************************************************************

Res_LoadSoundFx:
				move.l	GLF_DatabasePtr_l,a0
				lea		GLFT_SFXFilenames_l(a0),a0
				move.l	#SampleList,a1
				move.w	#58,d7

.load_sound_loop:
				tst.b	(a0)
				bne.s	.ok_to_load

				add.w	#64,a0
				addq	#8,a1
				dbra	d7,.load_sound_loop
				move.l	#-1,(a1)+				; terminate list?
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

Res_PatchSoundFx:								; transform the list of {{startaddress, length},...}
				move.w	#58,d7					; into {{startaddress, endaddress},...}
				move.l	#SampleList,a1

.patch_loop:
				move.l	(a1)+,d0
				add.l	d0,(a1)+
				dbra	d7,.patch_loop

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

; *****************************************************************************
; *
; * Floor (and ceiling) Textures
; *
; *****************************************************************************

Res_LoadFloorTextures:
				move.l	GLF_DatabasePtr_l,a0
				add.l	#GLFT_FloorFilename_l,a0
				move.l	#floortile,d0
				move.l	#0,d1
				move.l	#MEMF_ANY,IO_MemType_l
				jsr		IO_QueueFile

; move.l d0,floortile
				move.l	GLF_DatabasePtr_l,a0
				add.l	#GLFT_TextureFilename_l,a0
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

Res_FreeFloorTextures:
				move.l	floortile,d1
				CALLEXEC FreeVec
				clr.l	floortile
				rts

; *****************************************************************************
; *
; * Wall Textures
; *
; *****************************************************************************

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
				move.l	GLF_DatabasePtr_l,a3
				add.l	#GLFT_WallGFXNames_l,a3
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

; *****************************************************************************
; *
; * Level Data
; *
; *****************************************************************************

Res_FreeLevelData:
				move.l	Lvl_WalkLinksPtr_l,a1
				CALLEXEC FreeVec
				clr.l	Lvl_WalkLinksPtr_l

				move.l	Lvl_FlyLinksPtr_l,a1
				CALLEXEC FreeVec
				clr.l	Lvl_FlyLinksPtr_l

				move.l	Lvl_GraphicsPtr_l,a1
				CALLEXEC FreeVec
				clr.l	Lvl_GraphicsPtr_l

				move.l	Lvl_ClipsPtr_l,a1
				CALLEXEC FreeVec
				clr.l	Lvl_ClipsPtr_l

				move.l	Lvl_MusicPtr_l,a1
				CALLEXEC FreeVec
				clr.l	Lvl_MusicPtr_l
				rts

; *****************************************************************************
; *
; * Other
; *
; *****************************************************************************

Res_ReleaseScreenMemory:
				rts
