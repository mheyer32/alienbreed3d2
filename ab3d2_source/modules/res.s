
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

				align 4

; *****************************************************************************
; *
; * Objects (bitmap and vector)
; *
; *****************************************************************************

Res_LoadObjects:
; PRSDG
;				move.l	#io_ObjectPointers_vl,a2 ; XXX: Not used?
				move.l	GLF_DatabasePtr_l,a0
				lea		GLFT_ObjGfxNames_l(a0),a0
				move.l	#MEMF_ANY,IO_MemType_l
				move.l	#Draw_ObjectPtrs_vl,a1

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


RES_FREEPTR		macro
				move.l	\1,a1
				clr.l	\1
				CALLEXEC FreeVec
				endm

Res_FreeObjects:
				RES_FREEPTR GLF_DatabasePtr_l
				RES_FREEPTR Lvl_IntroTextPtr_l
				RES_FREEPTR Draw_BackdropImagePtr_l
				move.w	#DRAW_MAX_OBJECTS*4-1,d2
				lea		Draw_ObjectPtrs_vl,a2
				bsr		res_FreeList
				moveq	#DRAW_MAX_POLY_OBJECTS-1,d2
				lea		Draw_PolyObjects_vl,a2
				; fall through

; d2 = number of pointers-1, a2=list
res_FreeList:
				move.l	(a2)+,a1
				CALLEXEC FreeVec
				dbf		d2,res_FreeList
				rts

; *****************************************************************************
; *
; * Sound Effects
; *
; *****************************************************************************

RES_NUM_SFX=59 ; XXX: Shouldn't this be NUM_SFX? But doesn't work with karlos-tkg

Res_LoadSoundFx:
				move.l	GLF_DatabasePtr_l,a0
				lea		GLFT_SFXFilenames_l(a0),a0
				move.l	#Aud_SampleList_vl,a1
				move.w	#RES_NUM_SFX-1,d7
				move.l	#MEMF_ANY,IO_MemType_l

.load_sound_loop:
				tst.b	(a0)
				beq.s	.skip

				move.l	a1,d0
				move.l	d0,d1
				add.l	#4,d1
				jsr		IO_QueueFile

.skip:
				addq	#8,a1
				adda.w	#64,a0
				dbra	d7,.load_sound_loop
				rts

Res_PatchSoundFx:								; transform the list of {{startaddress, length},...}
				move.w	#RES_NUM_SFX-1,d7		; into {{startaddress, endaddress},...}
				move.l	#Aud_SampleList_vl,a1

.patch_loop:
				move.l	(a1)+,d0
				add.l	d0,(a1)+
				dbra	d7,.patch_loop

				rts

Res_FreeSoundFx:
				move.l	#Aud_SampleList_vl,a2
				move.w	#RES_NUM_SFX-1,d2
.relmem:
				move.l	(a2),a1
				clr.l	(a2)
				CALLEXEC FreeVec
				addq.w	#8,a2
				dbf		d2,.relmem
				rts

; *****************************************************************************
; *
; * Floor/Ceiling and model Textures
; *
; *****************************************************************************

Res_LoadFloorsAndTextures:
				move.l	GLF_DatabasePtr_l,a0
				add.l	#GLFT_FloorFilename_l,a0
				move.l	#Draw_GlobalFloorTexturesPtr_l,d0
				move.l	#0,d1
				move.l	#MEMF_ANY,IO_MemType_l
				jsr		IO_QueueFile

; move.l d0,Draw_FloorTexturesPtr_l
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
				move.l	#Draw_TextureMapsPtr_l,d0
				move.l	#0,d1
				jsr		IO_QueueFile

; move.l d0,Draw_TextureMapsPtr_l
				move.l	io_FileExtPointer_l,a1
				move.l	#".pal",(a1)
				move.l	#io_Buffer_vb,a0
				move.l	#Draw_TexturePalettePtr_l,d0
				move.l	#0,d1
				jsr		IO_QueueFile

; move.l d0,Draw_TexturePalettePtr_l
				rts

Res_FreeFloorsAndTextures:
				RES_FREEPTR Draw_GlobalFloorTexturesPtr_l
				RES_FREEPTR Draw_TextureMapsPtr_l
				RES_FREEPTR Draw_TexturePalettePtr_l
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

				move.l	#Draw_GlobalWallTexturePtrs_vl,a0
				moveq	#NUM_WALL_TEXTURES-1,d7

.empty_walls:
				move.l	#0,(a0)+
				dbra	d7,.empty_walls

				move.l	#Draw_GlobalWallTexturePtrs_vl,a4
				move.l	GLF_DatabasePtr_l,a3
				add.l	#GLFT_WallGFXNames_l,a3
				move.l	#MEMF_ANY,IO_MemType_l
				move.w	#NUM_WALL_TEXTURES-1,d7

.load_loop:
				move.l	(a3),d0
				beq		.done					; XXX maybe just skip this entry?

				move.l	a3,a0
				move.l	a4,d0					; address to put start pos
				move.l	#0,d1
				jsr		IO_QueueFile

				addq	#4,a4
				adda.w	#64,a3
				dbf		d7,.load_loop

.done:
				rts

Res_FreeWallTextures:
				lea		Draw_GlobalWallTexturePtrs_vl,a2
				moveq	#NUM_WALL_TEXTURES-1,d2
				bra		res_FreeList


; *****************************************************************************
; *
; * Level Data
; *
; *****************************************************************************

Res_LoadLevelData:
				move.l	#MEMF_ANY,IO_MemType_l
				move.l	#Lvl_MapFilename_vb,a0
				jsr		IO_LoadFile
				move.l	d0,Lvl_WalkLinksPtr_l

				move.l	#MEMF_ANY,IO_MemType_l
				move.l	#Lvl_FlyMapFilename_vb,a0
				jsr		IO_LoadFile
				move.l	d0,Lvl_FlyLinksPtr_l

				moveq	#0,d1
				move.b	Lvl_BinFilenameX_vb,d1
				sub.b	#'a',d1
				lsl.w	#6,d1
				move.l	GLF_DatabasePtr_l,a0
				lea		GLFT_LevelMusic_l(a0),a0

				move.l	#MEMF_CHIP,IO_MemType_l
				jsr		IO_LoadFile
				move.l	d0,Lvl_MusicPtr_l

				move.l	#MEMF_ANY,IO_MemType_l
				move.l	#Lvl_BinFilename_vb,a0
				jsr		IO_LoadFile
				move.l	d0,Lvl_DataPtr_l

				move.l	#MEMF_ANY,IO_MemType_l
				move.l	#Lvl_GfxFilename_vb,a0
				jsr		IO_LoadFile
				move.l	d0,Lvl_GraphicsPtr_l

				move.l	#MEMF_ANY,IO_MemType_l
				move.l	#Lvl_ClipsFilename_vb,a0
				jsr		IO_LoadFile
				move.l	d0,Lvl_ClipsPtr_l

				; Load the (optional) floor level graphics
				; First, ensure the globals are active
				move.l	Draw_GlobalFloorTexturesPtr_l,Draw_FloorTexturesPtr_l

				move.l	#MEMF_ANY,IO_MemType_l
				move.l	#Lvl_FloorFilename_vb,a0
				jsr		IO_LoadFileOptional

				move.l	d0,Draw_LevelFloorTexturesPtr_l
				beq.s	.done_floor_override

				; Override
				move.l	Draw_LevelFloorTexturesPtr_l,Draw_FloorTexturesPtr_l

.done_floor_override:
;				move.l	#MEMF_ANY,IO_MemType_l
;				move.l	#Lvl_ModPropsFilename_vb,a0
;				jsr		IO_LoadFileOptional

				movem.l	d2/a2/a3/a4/a5,-(sp)
				move.l	#Draw_GlobalWallTexturePtrs_vl,a2
				move.l	#Draw_LevelWallTexturePtrs_vl,a3
				move.l	#Draw_WallTexturePtrs_vl,a4
				moveq	#NUM_WALL_TEXTURES-1,d2
				lea		.bin2hex,a5

.do_wall:
				; First, put the default wall into Draw_WallTexturePtrs_vl
				move.l	(a2)+,(a4)

				; complete the filename
				move.b	(a5)+,Lvl_WallFilenameN_vb
				move.l	#Lvl_WallFilename_vb,a0
				jsr		IO_LoadFileOptional

				move.l	d0,(a3)+
				beq.s	.done_this_wall

				; pointer was not null, so move it into Draw_WallTexturePtrs_vl
				move.l	d0,(a4)

.done_this_wall:
				add.w	#4,a4
				dbra	d2,.do_wall

				movem.l	(sp)+,d2/a2/a3/a4/a5
				rts

.bin2hex:		dc.b	"0123456789ABCDEF"

				align 4

Res_FreeLevelData:
				; check for and free any custom floor overrides
				tst.l Draw_LevelFloorTexturesPtr_l
				beq.s .done_floor_overrides

				RES_FREEPTR Draw_LevelFloorTexturesPtr_l

				; reset the Draw_FloorTexturesPtr_l back to global set
				move.l	Draw_GlobalFloorTexturesPtr_l,Draw_FloorTexturesPtr_l

.done_floor_overrides:
				movem.l	d2/a2,-(sp)
				moveq	#NUM_WALL_TEXTURES-1,d2
				move.l	#Draw_LevelWallTexturePtrs_vl,a2

.free_wall_overrides:
				move.l	(a2),a1
				beq.s	.done_this_wall

				CALLEXEC FreeVec

.done_this_wall:
				clr.l	(a2)+
				dbra	d2,.free_wall_overrides

				movem.l	(sp)+,d2/a2
.free_other:

				RES_FREEPTR Lvl_WalkLinksPtr_l
				RES_FREEPTR Lvl_FlyLinksPtr_l
				RES_FREEPTR Lvl_GraphicsPtr_l
				RES_FREEPTR Lvl_ClipsPtr_l
				RES_FREEPTR Lvl_MusicPtr_l
				rts

; *****************************************************************************
; *
; * Other
; *
; *****************************************************************************

Res_ReleaseScreenMemory:
				rts
