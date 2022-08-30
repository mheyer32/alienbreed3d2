******************************************************

ENDOFQUEUE:		dc.l	0

INITQUEUE:
				move.l	#WorkSpace,ENDOFQUEUE
				rts

QUEUEFILE:
; On entry:
; a0=Pointer to filename
; d0=Ptr to dest. of addr
; d1=ptr to dest. of len.
; typeofmem=type of memory

				movem.l	d0-d7/a0-a6,-(a7)

				move.l	ENDOFQUEUE,a1
				move.l	d0,(a1)+
				move.l	d1,(a1)+
				move.l	TYPEOFMEM,(a1)+
				move.w	#79,d0

.copyname:
				move.b	(a0)+,(a1)+
				dbra	d0,.copyname
				add.l	#100,ENDOFQUEUE
				movem.l	(a7)+,d0-d7/a0-a6
				rts

FLUSHQUEUE:
				bsr		FLUSHPASS

tryagain
				tst.b	d6
				beq		.loadedall

* Find first unloaded file and prompt for disk.
				move.l	#WorkSpace,a2

.findfind:
				tst.l	(a2)
				bne.s	.foundunloaded
				add.l	#100,a2
				bra.s	.findfind

.foundunloaded:

* A2 points at an unloaded file thingy.
* Prompt for the disk.

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
.notfoundyet:
				addq	#1,d0
				cmp.b	#':',(a4)+
				bne.s	.notfoundyet

				move.w	d0,d1
				asr.w	#1,d1
				sub.w	d1,a3

				move.l	a2,a4
				add.l	#12,a4

; move.w #79,d0
.putinvol:
				move.b	(a4)+,(a3)+
				dbra	d0,.putinvol

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

				bsr		FLUSHPASS

				bra		tryagain

.loadedall
				rts

FLUSHPASS:
				move.l	#WorkSpace,a2
				moveq	#0,d7					; loaded a file
				moveq	#0,d6					; tried+failed

.flushit
				move.l	a2,d0
				cmp.l	ENDOFQUEUE,d0
				bge.s	FLUSHED

				tst.l	(a2)
				beq.s	.donethisone

				lea		12(a2),a0				; ptr to name

				move.l	8(a2),TYPEOFMEM

				jsr		TRYTOOPEN
				tst.l	d0
				beq.s	.failtoload

				move.l	d0,handle
				jsr		DEFLOADFILE
				st		d7

				move.l	(a2),a3
				move.l	d0,(a3)

				move.l	4(a2),d0
				beq.s	.nolenstore

				move.l	d0,a3
				move.l	d1,(a3)

.nolenstore:
				move.l	#0,(a2)
				bra.s	.donethisone

.failtoload
				st		d6

.donethisone:
				add.l	#100,a2
				bra		.flushit

FLUSHED:
				rts


TRYTOOPEN:
				movem.l	d1-d7/a0-a6,-(a7)
				move.l	a0,d1
				move.l	#1005,d2
				CALLDOS	Open
				movem.l	(a7)+,d1-d7/a0-a6
				rts

***************************************************

OBJNAME:		ds.w	80

OBJ_NAMES:
				dc.l	-1,-1

OBJ_ADDRS:		ds.l	160

blocklen:		dc.l	0
blockname:		dc.l	0
blockstart:		dc.l	0

BOTPICNAME:		dc.b	'includes/panelraw',0
				even
PanelLen:		dc.l	0

FREEBOTMEM:
				move.l	Panel,d1
				move.l	d1,a1
				CALLEXEC FreeVec

				rts

; FIXME: not used?
;LOADBOTPIC:
;
;; PRSDb
;
;				move.l	#BOTPICNAME,blockname
;
;				move.l	blockname,d1
;				move.l	#1005,d2
;				CALLDOS	Open
;				move.l	d0,handle
;
;				lea		fib,a5
;				move.l	handle,d1
;				move.l	a5,d2
;				CALLDOS	ExamineFH
;
;				move.l	$7c(a5),blocklen
;				move.l	#30720,PanelLen
;
;				move.l	#MEMF_CHIP|MEMF_CLEAR,d1
;				move.l	PanelLen,d0
;				CALLEXEC AllocVec
;				move.l	d0,blockstart
;
;				move.l	handle,d1
;				move.l	LEVELDATA,d2
;				move.l	blocklen,d3
;				CALLDOS	Read
;				move.l	handle,d1
;				CALLDOS	Close
;
;				move.l	blockstart,Panel
;
;				move.l	LEVELDATA,d0
;				moveq	#0,d1
;				move.l	Panel,a0
;				lea		WorkSpace,a1
;				lea		$0,a2
;				jsr		unLHA
;
;				rts

LOADOBS:

; PRSDG

				move.l	#OBJ_ADDRS,a2
				move.l	LINKFILE,a0
				lea		ObjectGfxNames(a0),a0

				move.l	#MEMF_ANY,TYPEOFMEM

				move.l	#Objects,a1

LOADMOREOBS:
				move.l	a0,a4
				move.l	#OBJNAME,a3
fillinname:
				move.b	(a4)+,d0
				beq.s	donename
				move.b	d0,(a3)+
				bra.s	fillinname

donename:

				move.l	a0,-(a7)

				move.l	a3,DOTPTR
				move.b	#'.',(a3)+
				move.b	#'W',(a3)+
				move.b	#'A',(a3)+
				move.b	#'D',(a3)+
				move.b	#0,(a3)+

				move.l	#OBJNAME,a0
				move.l	a1,d0
				moveq	#0,d1
				bsr		QUEUEFILE

				move.l	DOTPTR,a3
				move.b	#'.',(a3)+
				move.b	#'P',(a3)+
				move.b	#'T',(a3)+
				move.b	#'R',(a3)+
				move.b	#0,(a3)+


				move.l	#OBJNAME,a0
				move.l	a1,d0
				add.l	#4,d0
				moveq	#0,d1
				bsr		QUEUEFILE

				move.l	DOTPTR,a3
				move.b	#'.',(a3)+
				move.b	#'2',(a3)+
				move.b	#'5',(a3)+
				move.b	#'6',(a3)+
				move.b	#'P',(a3)+
				move.b	#'A',(a3)+
				move.b	#'L',(a3)+
				move.b	#0,(a3)+

				move.l	#OBJNAME,a0
				move.l	a1,d0
				add.l	#12,d0
				moveq	#0,d1
				bsr		QUEUEFILE

				move.l	(a7)+,a0

				add.l	#64,a0
				add.l	#16,a1
				tst.b	(a0)
				bne		LOADMOREOBS

				move.l	#POLYOBJECTS,a2
				move.l	LINKFILE,a0
				add.l	#VectorGfxNames,a0

LOADMOREVECTORS
				tst.b	(a0)
				beq.s	NOMOREVECTORS

				move.l	a2,d0
				moveq	#0,d1
				jsr		QUEUEFILE
				addq	#4,a2

				adda.w	#64,a0
				bra.s	LOADMOREVECTORS

NOMOREVECTORS:

				rts

DOTPTR:			dc.l	0

LOAD_A_PALETTE
				movem.l	d0-d7/a0-a6,-(a7)

				move.l	#OBJNAME,blockname
				move.l	blockname,d1
				move.l	#1005,d2
				CALLDOS	Open
				move.l	d0,handle

				move.l	#2048,blocklen

				move.l	#MEMF_ANY,d1
				move.l	blocklen,d0
				CALLEXEC AllocVec
				move.l	d0,blockstart

				move.l	handle,d1
				move.l	blockstart,d2
				move.l	blocklen,d3
				CALLDOS	Read

				move.l	handle,d1
				CALLDOS	Close

				movem.l	(a7)+,d0-d7/a0-a6

				move.l	blockstart,(a2)+
				move.l	blocklen,(a2)+

				rts

				CNOP	0,4	; FileInfoBlock must be 4-byte aligned
fib:			ds.b	fib_SIZEOF

; FIXME: seems unused
LOAD_AN_OBJ:
				movem.l	a0/a1/a2/a3/a4,-(a7)

				move.l	#OBJNAME,blockname

				move.l	blockname,d1
				move.l	#1005,d2
				CALLDOS	Open
				move.l	d0,handle

				lea		fib,a5
				move.l	handle,d1
				move.l	a5,d2
				CALLDOS	ExamineFH

				move.l	$7c(a5),blocklen

				move.l	#MEMF_ANY,d1
				move.l	blocklen,d0
				CALLEXEC AllocVec
				move.l	d0,blockstart

				move.l	handle,d1
				move.l	blockstart,d2
				move.l	blocklen,d3
				CALLDOS	Read
				move.l	handle,d1
				CALLDOS	Close

				movem.l	(a7)+,a0/a1/a2/a3/a4

				move.l	blockstart,(a2)+
				move.l	blocklen,(a2)+

				rts

RELEASEOBJMEM:


				move.l	#OBJ_NAMES,a0
				move.l	#OBJ_ADDRS,a2

relobjlop
				move.l	(a2)+,blockstart
				move.l	(a2)+,blocklen
				addq	#8,a0
				tst.l	blockstart
				ble.s	nomoreovj

				movem.l	a0/a2,-(a7)

				move.l	blockstart,d1
				move.l	d1,a1
				CALLEXEC FreeVec

				movem.l	(a7)+,a0/a2
				bra.s	relobjlop

nomoreovj:

				rts



TYPEOFMEM:		dc.l	0

LOAD_SFX:

				move.l	LINKFILE,a0
				lea		SFXFilenames(a0),a0

				move.l	#SampleList,a1


				move.w	#58,d7

LOADSAMPS:
				tst.b	(a0)
				bne.s	oktoload

				add.w	#64,a0
				addq	#8,a1
				dbra	d7,LOADSAMPS
				move.l	#-1,(a1)+
				rts

oktoload:

				move.l	#MEMF_ANY,TYPEOFMEM
				move.l	a1,d0
				move.l	d0,d1
				add.l	#4,d1
				jsr		QUEUEFILE
				addq	#8,a1
; move.l d0,(a1)+
; add.l d1,d0
; move.l d0,(a1)+
				adda.w	#64,a0
				dbra	d7,LOADSAMPS

				move.l	#MEMF_ANY,TYPEOFMEM

				rts

PATCHSFX:

				move.w	#58,d7
				move.l	#SampleList,a1
.patch
				move.l	(a1)+,d0
				add.l	d0,(a1)+
				dbra	d7,.patch

				rts

; PRSDJ
;
; move.l #SFX_NAMES,a0
; move.l #SampleList,a1
;LOADSAMPS
; move.l (a0)+,a2
; move.l a2,d0
; tst.l d0
; bgt.s oktoload
; blt.s doneload
;
; addq #4,a0
; addq #8,a1
; bra LOADSAMPS
;
;doneload:
;
; move.l #-1,(a1)+
; rts
;oktoload:
; move.l (a0)+,blocklen
; move.l a2,blockname
; movem.l a0/a1,-(a7)
; move.l #2,d1
; move.l 4.w,a6
; move.l blocklen,d0
; jsr -198(a6)
; move.l d0,blockstart
; move.l _DOSBase,a6
; move.l blockname,d1
; move.l #1005,d2
; jsr -30(a6)
; move.l _DOSBase,a6
; move.l d0,handle
; move.l d0,d1
; move.l blockstart,d2
; move.l blocklen,d3
; jsr -42(a6)
; move.l _DOSBase,a6
; move.l handle,d1
; jsr -36(a6)
; movem.l (a7)+,a0/a1
; move.l blockstart,d0
; move.l d0,(a1)+
; add.l blocklen,d0
; move.l d0,(a1)+
; bra LOADSAMPS



LOADFLOOR
; PRSDK
; move.l #65536,d0
; move.l #1,d1
; move.l 4.w,a6
; jsr -198(a6)
; move.l d0,floortile
;
; move.l #floortilename,d1
; move.l #1005,d2
; move.l _DOSBase,a6
; jsr -30(a6)
; move.l _DOSBase,a6
; move.l d0,handle
; move.l d0,d1
; move.l floortile,d2
; move.l #65536,d3
; jsr -42(a6)
; move.l _DOSBase,a6
; move.l handle,d1
; jsr -36(a6)

				move.l	LINKFILE,a0
				add.l	#FloorTileFilename,a0
				move.l	#floortile,d0
				move.l	#0,d1
				move.l	#MEMF_ANY,TYPEOFMEM
				jsr		QUEUEFILE
; move.l d0,floortile

				move.l	LINKFILE,a0
				add.l	#TextureFilename,a0
				move.l	#BUFFE,a1

.copy:
				move.b	(a0)+,(a1)+
				beq.s	.copied
				bra.s	.copy
.copied:

				subq	#1,a1
				move.l	a1,dotty

				move.l	#BUFFE,a0
				move.l	#TextureMaps,d0
				move.l	#0,d1
				jsr		QUEUEFILE
; move.l d0,TextureMaps

				move.l	dotty,a1
				move.l	#".pal",(a1)

				move.l	#BUFFE,a0
				move.l	#TexturePal,d0
				move.l	#0,d1
				jsr		QUEUEFILE
; move.l d0,TexturePal

				rts

dotty:			dc.l	0
BUFFE:			ds.b	80

floortilename:
				dc.b	'includes/floortile'
				dc.b	0

				even

RELEASESAMPMEM:
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

RELEASELEVELMEM:
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

RELEASEFLOORMEM:
				move.l	floortile,d1
				CALLEXEC FreeVec
				clr.l	floortile
				rts

RELEASESCRNMEM:
				rts

unLHA:			incbin	"decomp4.raw"
