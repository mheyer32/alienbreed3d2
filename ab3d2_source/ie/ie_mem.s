; ie_mem.s - Intuition Engine memory/system compatibility layer

	xdef ie_mem_init
	xdef Sys_AllocVec
	xdef Sys_FreeVec
	xdef Sys_MemFillLong
	xdef Sys_FatalError
	xdef Sys_Init
	xdef Sys_Done
	xdef Sys_OpenLibs
	xdef Sys_CloseLibs
	xdef Sys_ShowFPS
	xdef Sys_DisplayError
	xdef Sys_MarkTime
	xdef Sys_TimeDiff
	xdef Sys_EClockRate
	xdef Zone_FreeEdgePVS
	xdef _Zone_FreeEdgePVS
	xdef Sys_Workspace_vl
	xdef ie_mem_heap_ptr

	xdef _Sys_AllocVec
	xdef _Sys_FreeVec
	xdef _Sys_MemFillLong
	xdef _Sys_FatalError
	xdef _Sys_Init
	xdef _Sys_Done
	xdef _Sys_DisplayError

MEM_HEAP_BASE	equ	$C00000
MEM_HEAP_LIMIT	equ	$FE0000

ie_mem_init:
	move.l	#MEM_HEAP_BASE,ie_mem_heap_ptr
	clr.l	ie_last_error_fmt_ptr
	clr.l	ie_clock_hi
	clr.l	ie_clock_lo
	move.l	#60000,Sys_EClockRate
	rts

; d0=size, d1=flags (ignored)
; returns d0=ptr or 0
Sys_AllocVec:
_Sys_AllocVec:
	move.l	d0,d2
	addq.l	#3,d2
	andi.l	#$FFFFFFFC,d2		; 4-byte align size

	move.l	ie_mem_heap_ptr,d0
	move.l	d0,d3
	add.l	d2,d3
	cmp.l	#MEM_HEAP_LIMIT,d3
	bhi.s	.alloc_fail

	move.l	d3,ie_mem_heap_ptr
	rts

.alloc_fail:
	clr.l	d0
	rts

; a1=ptr (ignored in bump allocator)
Sys_FreeVec:
_Sys_FreeVec:
	rts

; a0=dest, d0=value, d1=size_in_bytes
Sys_MemFillLong:
_Sys_MemFillLong:
	lsr.w	#2,d1
	subq.w	#1,d1
	bmi.s	.fill_done
.fill_loop:
	move.l	d0,(a0)+
	dbra	d1,.fill_loop
.fill_done:
	rts

; a0=format (saved for diagnostics), a1=varargs (ignored)
; non-fatal in IE bootstrap path
Sys_FatalError:
_Sys_FatalError:
	move.l	a0,ie_last_error_fmt_ptr
	rts

Sys_Init:
_Sys_Init:
	moveq	#1,d0
	rts

Sys_Done:
_Sys_Done:
	rts

Sys_OpenLibs:
	moveq	#1,d0
	rts

Sys_CloseLibs:
	rts

Sys_ShowFPS:
	rts

Sys_DisplayError:
_Sys_DisplayError:
	rts

Zone_FreeEdgePVS:
_Zone_FreeEdgePVS:
	rts

; a0=dest EClockVal*
; returns d0=Sys_EClockRate
Sys_MarkTime:
	add.l	#1000,ie_clock_lo
	bcc.s	.no_carry
	addq.l	#1,ie_clock_hi
.no_carry:
	tst.l	a0
	beq.s	.no_store
	move.l	ie_clock_hi,(a0)
	move.l	ie_clock_lo,4(a0)
.no_store:
	move.l	Sys_EClockRate,d0
	rts

; a0=start EClockVal*, a1=end EClockVal*
; return uint64 diff in d0:d1 (high:low)
Sys_TimeDiff:
	move.l	(a1),d0
	move.l	4(a1),d1
	move.l	4(a0),d3
	sub.l	d3,d1
	bcc.s	.no_borrow
	subq.l	#1,d0
.no_borrow:
	sub.l	(a0),d0
	rts

ie_mem_heap_ptr:
	dc.l	MEM_HEAP_BASE
ie_last_error_fmt_ptr:
	dc.l	0
ie_clock_hi:
	dc.l	0
ie_clock_lo:
	dc.l	0
Sys_EClockRate:
	dc.l	60000

; Compatibility workspace (4KB for queue/temp usage).
Sys_Workspace_vl:
	dcb.l	1024,0
