
	incdir include:
	include exec/execbase.i


DataCacheOff
	move.l	4.w,a6
	moveq	#0,d0
	move.l	#%0000000100000000,d1
	jsr	_LVOCacheControl(a6)
	rts

DataCacheOn
	move.l	4.w,a6
	moveq	#-1,d0
	move.l	#%0000000100000000,d1
	jsr	_LVOCacheControl(a6)
