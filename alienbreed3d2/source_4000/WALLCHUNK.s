

RELEASEWALLMEM:
 move.l #walltiles,a0
 move.l #wallchunkdata,a5
relmem:
 move.l 4(a5),d0
 beq.s relall
 
 move.l (a0),d1
 beq.s notthismem

 move.l d1,a1
 move.l 4.w,a6
 movem.l a0/a5,-(a7)
 jsr -210(a6)
 movem.l (a7)+,a0/a5


notthismem:
 addq #8,a5
 addq #4,a0
 bra.s relmem
 
relall:
 rts

LOADWALLS:

**************************************

* New loading system:
* Send each filename to a 'server' along with
* addresses for the return values (pos,len)
* then call FLUSHQUEUE, which actually loads
* the files in...

 move.l #walltiles,a0
 moveq #39,d7
emptywalls:
 move.l #0,(a0)+
 dbra d7,emptywalls

 move.l #walltiles,a4
 move.l LINKFILE,a3
 add.l #WallGFXNames,a3
 move.l #0,TYPEOFMEM
 
loademin:
 move.l (a3),d0
 beq loadedall

 move.l a3,a0
 move.l a4,d0	; address to put start pos
 move.l #0,d1
 
 jsr QUEUEFILE
 
 addq #4,a4

 adda.w #64,a3
 bra loademin
 
loadedall:

 rts

**************************************

; move.l #walltiles,a0
; moveq #39,d7
;emptywalls:
; move.l #0,(a0)+
; dbra d7,emptywalls
;
; move.l #walltiles,a4
; move.l LINKFILE,a3
; add.l #WallGFXNames,a3
; move.l #0,TYPEOFMEM
; 
;loademin:
; move.l (a3),d0
; beq loadedall
 
; movem.l a4/a3,-(a7)

; move.l a3,a0
; jsr LOADAFILE

; movem.l (a7)+,a4/a3
 
; move.l d0,(a4)+
; move.l d1,4(a3)
 
; adda.w #64,a3
; bra loademin
 
;loadedall:
; PRSDN
; rts
 
handle: dc.l 0

UNPACKED: dc.l 0

walltiles:
 ds.l 40

DEFLOADFILE:
; Load a file in and unpack it if necessary.
; Pointer to name in a0
; Returns address in d0 and length in d1

 movem.l d0-d7/a0-a6,-(a7)
 bra.s intoload
 
LOADAFILE:
; Load a file in and unpack it if necessary.
; Pointer to name in a0
; Returns address in d0 and length in d1

 movem.l d0-d7/a0-a6,-(a7)

 move.l a0,d1
 move.l doslib,a6
 move.l #1005,d2
 jsr -30(a6)
 move.l d0,handle

intoload:

 lea fib,a5
 move.l handle,d1
 move.l a5,d2
 move.l doslib,a6
 jsr -390(a6)
 move.l $7c(a5),blocklen

 move.l TYPEOFMEM,d1
 move.l 4.w,a6
 move.l blocklen,d0
 jsr -198(a6)
 
 move.l d0,blockstart
 
 move.l doslib,a6
 move.l handle,d1
 move.l d0,d2
 move.l blocklen,d3
 jsr -42(a6)
 
 move.l doslib,a6
 move.l handle,d1
 jsr -36(a6)
 
 move.l blockstart,a0
 move.l (a0),d0
 cmp.l #'=SB=',d0
 beq ITSPACKED
 
 move.l blockstart,d0
 move.l blocklen,d1
 move.l d0,a0
 cmp.l #'CSFX',(a0)
 beq ITSASFX

; Not a packed file so just return now.
 movem.l (a7)+,d0-d7/a0-a6

 move.l blockstart,d0
 move.l blocklen,d1

 rts
 
ITSASFX:
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
	sub.l #8,a1
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
	
 movem.l (a7)+,d0-d7/a0-a6

	move.l	.SamplePosition,d0
	move.l	.SampleSize,d1
	
	rts
	
.CompressedSamplePosition:	dc.l	0
.CompressedSampleSize:		dc.l	0
.SamplePosition:		dc.l	0
.SampleSize:			dc.l	0
.FibList:	dc.b	-34,-21,-13,-8,-5,-3,-2,-1,0,1,2,3,5,8,13,21



 
ITSPACKED:

 move.l 4(a0),d0	; length of unpacked file.
 move.l d0,UNPACKED
 move.l TYPEOFMEM,d1
 move.l 4.w,a6
 jsr -198(a6)
 
 move.l d0,unpackedstart

 move.l blockstart,d0
 moveq #0,d1
 move.l unpackedstart,a0
 move.l LEVELDATA,a1
 lea $0,a2
 jsr unLHA
 
 move.l blockstart,d1
 move.l d1,a1
 move.l blocklen,d0
 move.l 4.w,a6
 jsr -210(a6)

 move.l unpackedstart,d0
 move.l UNPACKED,d1
 move.l d0,a0
 cmp.l #'CSFX',(a0)
 beq ITSASFX

 movem.l (a7)+,d0-d7/a0-a6
 
 move.l unpackedstart,d0
 move.l UNPACKED,d1

 rts
 
 
unpackedstart:
 dc.l 0
 
wallchunkdata:
 dc.l GreenMechanicNAME,18560
 dc.l BlueGreyMetalNAME,13056
 dc.l TechnoDetailNAME,13056
 dc.l BlueStoneNAME,10368
 dc.l RedAlertNAME,7552
 dc.l RockNAME,10368
 dc.l scummyNAME,24064
 dc.l stairfrontsNAME,2400
 dc.l bigdoorNAME,13056
 dc.l redrockNAME,13056
 dc.l dirtNAME,24064
 dc.l SwitchesNAME,3456
 dc.l shinyNAME,24064
 dc.l bluemechNAME,15744
 dc.l 0,0

GreenMechanicNAME:
 dc.b 'AB3D1:includes/walls/greenmechanic.256wad'
 dc.b 0 
 even
BlueGreyMetalNAME:
 dc.b 'AB3D1:includes/walls/bluegreymetal.256wad'
 dc.b 0
 even
TechnoDetailNAME:
 dc.b 'AB3D1:includes/walls/technodetail.256wad'
 dc.b 0
 even
BlueStoneNAME:
 dc.b 'AB3D1:includes/walls/bluestone.256wad'
 dc.b 0
 even
RedAlertNAME:
 dc.b 'AB3D1:includes/walls/redalert.256wad'
 dc.b 0
 even
RockNAME:
 dc.b 'AB3D1:includes/walls/rock.256wad'
 dc.b 0
 even
scummyNAME:
 dc.b 'AB3D1:includes/walls/scummy.256wad'
 dc.b 0
 even
stairfrontsNAME:
 dc.b 'AB3D1:includes/walls/stairfronts.256wad'
 dc.b 0
 even
bigdoorNAME:
 dc.b 'AB3D1:includes/walls/bigdoor.256wad'
 dc.b 0
 even
redrockNAME:
 dc.b 'AB3D1:includes/walls/redrock.256wad'
 dc.b 0
 even
dirtNAME:
 dc.b 'AB3D1:includes/walls/dirt.256wad'
 dc.b 0
 even
SwitchesNAME:
 dc.b 'AB3D1:includes/walls/switches.256wad'
 dc.b 0
 even 
shinyNAME:
 dc.b 'AB3D1:includes/walls/shinymetal.256wad'
 dc.b 0
 even
bluemechNAME:
 dc.b 'AB3D1:includes/walls/bluemechanic.256wad'
 dc.b 0
 even
 
