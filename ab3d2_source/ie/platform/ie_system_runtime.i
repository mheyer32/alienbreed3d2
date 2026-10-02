; dest  ULONG a0
; value ULONG d0
; size  WORD d1 (in longs)
_Sys_MemFillLong::
Sys_MemFillLong:
				lsr.w	#2,d1
				subq.w	#1,d1
.fill_loop:
				move.l	d0,(a0)+
				move.l	d0,(a0)+
				move.l	d0,(a0)+
				move.l	d0,(a0)+
				dbra	d1,.fill_loop
				rts

; Copy fallback for the IE target.
; in: a0=src, a1=dst, d0=size bytes
_Sys_CopyMemMove16:
Sys_CopyMemMove16:
				move.l		d0,d1
				beq.s		.copy_done
				lsr.l		#2,d1
				beq.s		.copy_tail
				subq.l		#1,d1
.copy_longs:
				move.l		(a0)+,(a1)+
				dbra		d1,.copy_longs
				move.l		d0,d1
				andi.l		#3,d1
.copy_tail:
				beq.s		.copy_done
				subq.l		#1,d1
.copy_bytes:
				move.b		(a0)+,(a1)+
				dbra		d1,.copy_bytes
.copy_done:
				rts

_Sys_FatalError::
				lea		4(sp),a1
Sys_FatalError:
				move.l	sys_RecoveryStack,d0
				beq.s	.no_recover
				move.l	d0,a7
.no_recover:
				bra		Game_Quit

_Sys_DisplayError::
Sys_DisplayError:
				rts

Sys_AllocVec:
				move.l	d0,d2
				addq.l	#3,d2
				andi.l	#$FFFFFFFC,d2
				move.l	ie_sys_heap_ptr,d0
				move.l	d0,d3
				add.l	d2,d3
				cmp.l	#$00FE0000,d3
				bhi.s	.fail
				move.l	d3,ie_sys_heap_ptr
				rts
.fail:
				clr.l	d0
				rts

ie_sys_heap_ptr:
				dc.l	$00C00000
