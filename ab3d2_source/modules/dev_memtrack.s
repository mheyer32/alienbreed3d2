mem_serputch:
				tst.b	d0
				beq.b	.skip
				movem.l	d1/a6,-(sp)
				move.b	d0,d1
				move.l	#$dff000,a6
				jsr		SERSEND
				movem.l	(sp)+,d1/a6
.skip:
				rts

SERPRINTF		macro
				movem.l	d0-d1/a0-a3/a6,-(sp)
				if		NARG>=9
				move.l	\9,-(sp)
				endc
				if		NARG>=8
				move.l	\8,-(sp)
				endc
				if		NARG>=7
				move.l	\7,-(sp)
				endc
				if		NARG>=6
				move.l	\6,-(sp)
				endc
				if		NARG>=5
				move.l	\5,-(sp)
				endc
				if		NARG>=4
				move.l	\4,-(sp)
				endc
				if		NARG>=3
				move.l	\3,-(sp)
				endc
				if		NARG>=2
				move.l	\2,-(sp)
				endc
				lea		.fmt\@(pc),a0
				move.l	sp,a1
				lea		mem_serputch(pc),a2
				sub.l	a3,a3
				move.l	$4.w,a6
				jsr		_LVORawDoFmt(a6)
				add		#4*(NARG-1),sp
				movem.l	(sp)+,d0-d1/a0-a3/a6
				bra		.done\@
.fmt\@:			dc.b	\1,0
				even
.done\@:
				endm


mem_PrintLibNodes:
				move.l	$4.w,a0
				move.l	LibList+LH_HEAD(a0),a0
.loop:
				move.l	LN_SUCC(a0),d1
				beq.b	.done
				moveq	#0,d0
				move.w	LIB_OPENCNT(a0),d0
				SERPRINTF <"%-32s %lu",13,10>,LN_NAME(a0),d0
				move.l	d1,a0
				bra		.loop
.done:			SERPRINTF <"--------------",13,10>
				rts

Mem_TrackInit:
				SERPRINTF <"-------------- Init",13,10>
				bsr		mem_PrintLibNodes
				move.l	$4.w,a6
				move.l	ThisTask(a6),mem_ThisTask_l
				move.l	_LVOAllocMem+2(a6),mem_AllocMem_l
				move.l	_LVOFreeMem+2(a6),mem_FreeMem_l
				move.l	#mem_TrackAlloc,_LVOAllocMem+2(a6)
				move.l	#mem_TrackFree,_LVOFreeMem+2(a6)
				rts

Mem_TrackDone:
				move.l	$4.w,a6
				move.l	mem_AllocMem_l,_LVOAllocMem+2(a6)
				move.l	mem_FreeMem_l,_LVOFreeMem+2(a6)
				SERPRINTF <"-------------- Done",13,10>
				bsr		mem_PrintLibNodes
				rts

				IFD		BUILD_WITH_C
				xref	__stext
				ELSE
__stext=_startup
				ENDC
mem_TrackAlloc:
				move.l	d0,-(sp)
				move.l	mem_ThisTask_l,d0
				cmp.l	ThisTask(a6),d0
				beq.b	.track
				move.l	(sp)+,d0
				jmp		([mem_AllocMem_l])
.track:
				move.l	(sp)+,d0
				SERPRINTF <"AllocMem %ld %lX -> ">,d0,d1
				jsr		([mem_AllocMem_l])
				SERPRINTF <"%lX ">,d0
				movem.l	d0-d2/a0-a1,-(sp)
                ; Search for likely return address
				move.l	#__stext,d1
				move.l	d1,a0
				add.l	-8(a0),a0
				move.l	a0,d2					; d2 = end of hunk
				lea		20(sp),a0
.search:
				move.l	(a0)+,d0
				bmi.b	.search
				btst.l	#0,d0
				bne.b	.search
				cmp.l	d1,d0
				ble.b	.search
				cmp.l	d2,d0
				bhs.l	.search
				SERPRINTF <"%lX",13,10>,d0
				movem.l	(sp)+,d0-d2/a0-a1
				rts

mem_TrackFree:
				move.l	d0,-(sp)
				move.l	mem_ThisTask_l,d0
				cmp.l	ThisTask(a6),d0
				beq.b	.track
				move.l	(sp)+,d0
				jmp		([mem_FreeMem_l])
.track:
				move.l	(sp)+,d0
				SERPRINTF <"FreeMem %lX %ld",13,10>,a1,d0
				jmp		([mem_FreeMem_l])

mem_ThisTask_l:	dc.l	0
mem_AllocMem_l:	dc.l	0
mem_FreeMem_l:	dc.l	0
