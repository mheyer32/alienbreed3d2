;This routine will take a sample file that has been
;compacted using the delta fibonacci compaction method
;pointed to by d0 of length d1, and returns a pointer
;to the decompressed file in d0 with the new length
;in d1.  The original memory will be deallocated and
;new memory for the uncompacted SFX will be requested.

;The first long word will be "CSFX"
;the second long word holds the length of the
;uncompressed sample.

	include	"utils:devpac/system.gs"

UnPackSample:
	add.l	#4,d0		;Skip "CSFX"
	move.l	d1,.CompressedSampleSize
	move.l	d0,a0
	move.l	4.w,a6
	move.l	(a0)+,d0	;file size
	move.l	d0,.SampleSize
	move.l	a0,.CompressedSamplePosition
	move.l	#MEMF_CHIP,d1
	jsr	_LVOAllocMem(a6)
	move.l	d0,.SamplePosition
	move.l	.CompressedSamplePosition,a0
	move.l	d0,a1
	move.l	.SampleSize,d0
	sub.w	#2,d0
	move.b	(a0)+,d1	;first byte (actual value)
	move.b	d1,(a1)+
	lea	.FibList(pc),a2
.DecompLoop:
	move.b	(a0)+,d2
	and.w	#$00ff,d2
	move.w	d2,d3
	lsr.w	#4,d2
	and.w	#$000f,d3
	move.b	(a2,d2.w),d4	;first fib value
	add.b	d4,d1
	move.b	d1,(a1)+	;store sample value
	dbra	d0,.NotFinishedYet
	bra.s	.SampleFinished
.NotFinishedYet:
	move.b	(a2,d3.w),d4	;second fib value
	add.b	d4,d1
	move.b	d1,(a1)+	;store sample value
	dbra	d0,.DecompLoop	
.SampleFinished:
	move.l	.CompressedSamplePosition,a1
	move.l	.CompressedSampleSize,d0
	move.l	4.w,a6
	jsr	_LVOFreeMem(a6)
	;Now check the sample and clip it if it ever gets
	;too big
	
	move.l	.SamplePosition,a0
	move.l	.SampleSize,d0
	sub.w	#1,d0
.ClipLoop:
	move.b	(a0),d1
	cmp.b	#64,d1
	blt.s	.NotTooBig
	move.b	#63,d1
.NotTooBig:
	cmp.b	#-64,d1
	bge.s	.NotTooSmall
	move.b	#-64,d1
.NotTooSmall:
	move.b	d1,(a0)+
	dbra	d0,.ClipLoop
	
	move.l	.SamplePosition,d0
	move.l	.SampleSize,d1
	
	rts
	
.CompressedSamplePosition:	dc.l	0
.CompressedSampleSize:		dc.l	0
.SamplePosition:		dc.l	0
.SampleSize:			dc.l	0
.FibList:	dc.b	-34,-21,-13,-8,-5,-3,-2,-1,0,1,2,3,5,8,13,21
