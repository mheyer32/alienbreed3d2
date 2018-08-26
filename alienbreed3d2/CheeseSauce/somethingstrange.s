;this program uses the task oriented ctp routine to display
;a simple picture.

	include	"workbench:utilities/devpac/system.gs"
	
scrwid	EQU	192
scrht	EQU	160
	;first open a screen and allocate a chunky buffer
	move.l	4.w,a6
	move.l	#INTUINAME,a1
	move.l	#36,d0
	jsr	_LVOOpenLibrary(a6)
	move.l	d0,INTUIBASE
	beq	nointui
	
	move.l	4.w,a6
	move.l	#GFXNAME,a1
	move.l	#36,d0
	jsr	_LVOOpenLibrary(a6)
	move.l	d0,GFXBASE
	beq	nogfx
	
	move.l	#0,a0
	move.l	#MYSCREENTAGS,a1
	move.l	INTUIBASE,a6
	jsr	_LVOOpenScreenTagList(a6)
	move.l	d0,SCREENBASE
	beq	noscreen
	
	move.l	4.w,a6
	move.l	#scrwid*scrht,d0
	move.l	#0,d1			;best possible memory
	jsr	_LVOAllocMem(a6)
	move.l	d0,CHUNKYBUFFER
	beq	nochunky
	
	move.l	#scrwid*scrht,d0
	move.l	#0,d1			;best possible memory
	jsr	_LVOAllocMem(a6)
	move.l	d0,CHUNKYCOMPARE
	beq	nochunkycomp
	
	move.l	#scrwid*scrht,d0
	move.l	#MEMF_CHIP,d1
	jsr	_LVOAllocMem(a6)
	move.l	d0,CHIPBUF1
	beq	nochipbuf1
	
	move.l	#scrwid*scrht,d0
	move.l	#MEMF_CHIP,d1
	jsr	_LVOAllocMem(a6)
	move.l	d0,CHIPBUF2
	beq	nochipbuf2
	
	move.l	4.w,a6
	move.l	#-1,d0
	jsr	_LVOAllocSignal(a6)
	move.l	d0,SIG1
	blt	nosig1

	move.l	4.w,a6
	move.l	#-1,d0
	jsr	_LVOAllocSignal(a6)
	move.l	d0,SIG2
	blt	nosig2
	
	;set the signals to say that the previous ctp conversion
	;has been completed
	move.l	4.w,a6
	move.l	SIG1,d0
	or.l	SIG2,d0
	move.l	d0,d1
	jsr	_LVOSetSignal(a6)
	
	;initialise ctp routine
	move.l	CHUNKYBUFFER,a0		;chunky buffer
	move.l	CHUNKYCOMPARE,a1	;chunky compare buffer
	move.l	SCREENBASE,a2
	lea	sc_BitMap(a2),a2
	lea	bm_Planes(a2),a2	;plane pointer
	move.l	GFXBASE,a3
	move.l	#1,d0			;signals1
	move.l	#2,d1			;signals2
	move.l	#scrwid*scrht,d2	;number of pixels
	move.l	#0,d3			;byte offset
	move.l	CHIPBUF1,d4
	move.l	CHIPBUF2,d5
	jsr	_c2p8_init
	
notzerozero:
	move.w	YPOS,d0
	mulu.w	#scrwid,d0
	add.w	XPOS,d0
	move.l	CHUNKYBUFFER,a0
	add.b	#1,(a0,d0.w)
	move.w	XPOS,d0
	add.w	#1,d0
	cmp.w	#scrwid,d0
	blt.s	notoffright
	move.w	#0,d0
	move.w	YPOS,d1
	add.w	#1,d1
	cmp.w	#scrht,d1
	blt.s	notoffbottom
	move.w	#0,d1
notoffbottom:
	move.w	d1,YPOS
notoffright:
	move.w	d0,XPOS
	
	move.l	GFXBASE,a6
	jsr	_LVOWaitTOF(a6)
	jsr	_c2p8_go
	move.w	#$f00,$dff180
	
	move.l	SCREENBASE,a0
	move.w	sc_MouseX(a0),d0
	bne.s	notzerozero
	move.w	sc_MouseY(a0),d0
	bne.s	notzerozero
	
	move.l	4.w,a6
	move.l	SIG2,d0
	jsr	_LVOFreeSignal(a6)
nosig2:
	move.l	4.w,a6
	move.l	SIG1,d0
	jsr	_LVOFreeSignal(a6)
nosig1:
	move.l	CHIPBUF2,a1
	move.l	#scrwid*scrht/8,d0
	move.l	4.w,a6
	jsr	_LVOFreeMem(a6)
nochipbuf2:
	move.l	CHIPBUF1,a1
	move.l	#scrwid*scrht/8,d0
	move.l	4.w,a6
	jsr	_LVOFreeMem(a6)
nochipbuf1:
	move.l	CHUNKYCOMPARE,a1
	move.l	#scrwid*scrht/8,d0
	move.l	4.w,a6
	jsr	_LVOFreeMem(a6)
nochunkycomp:
	move.l	CHUNKYBUFFER,a1
	move.l	#scrwid*scrht/8,d0
	move.l	4.w,a6
	jsr	_LVOFreeMem(a6)
nochunky:
	move.l	SCREENBASE,a0
	move.l	INTUIBASE,a6
	jsr	_LVOCloseScreen(a6)
noscreen:
	move.l	GFXBASE,a1
	move.l	4.w,a6
	jsr	_LVOCloseLibrary(a6)
nogfx:
	move.l	INTUIBASE,a1
	move.l	4.w,a6
	jsr	_LVOCloseLibrary(a6)
nointui:
	rts

INTUIBASE:	dc.l	0
GFXBASE:	dc.l	0
SIG1:		dc.l	0
SIG2:		dc.l	0
INTUINAME:	dc.b	"intuition.library",0
GFXNAME:	dc.b	"graphics.library",0
	even
MYSCREENTAGS:
	dc.l	SA_Width,scrwid
	dc.l	SA_Height,scrht
	dc.l	SA_Depth,8
;	dc.l	SA_DisplayID
;	dc.l	LORES_KEY
	dc.l	SA_Quiet,-1
	dc.l	SA_AutoScroll,-1
	dc.l	-1,-1
SCREENBASE:	dc.l	0
CHUNKYBUFFER:	dc.l	0
CHUNKYCOMPARE:	dc.l	0
CHIPBUF1:	dc.l	0
CHIPBUF2:	dc.l	0
XPOS:		dc.w	0
YPOS:		dc.w	0

	even
	include	"ab3:source_4000/somethingstrange2.s"
	