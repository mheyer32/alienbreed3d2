	Section __Chunky2Planar,code

;-------------------chunky 2 planar-------------------

	cnop	0,16

c2p_1_Pass:	

.Swait:	tst.w	SetScreen	;Make sure the last frame was displayed,
	bne.b	.Swait		;no need to go faster than 50 fps.

.Bwait:	tst.w	BlitterIsDone	;Make sure the blitter is done with the
	bne.b	.Bwait		;previous frame.

	move.l	Screen_0,d0
	move.l	Screen_1,Screen_0
	move.l	Screen_2,Screen_1
	move.l	Screen_3,Screen_2
	move.l	d0,Screen_3

	move.w	#-1,SetScreen

;----------------CPU AntiScrambler----------------

	RastPos	s_c2p_time

	lea.l	ChunkyBuffer,a0
	move.l	Buffer_0,a1

	move.l	#$ff00ff00,d4
	move.l	d4,d5
	not.l	d5

	move.w	#ChunkyPixels/8-2,d7

	IFD	ClearChunkyBuffer

	move.l	(a0),d0		;Buffered chunky write
	clr.l	(a0)+
	move.l	(a0),d2		;Buffered chunky write
	clr.l	(a0)+

	ELSE

	move.l	(a0)+,d0	;Buffered chunky write
	move.l	(a0)+,d2	;Buffered chunky write

	ENDIF
.Loop:
	move.l	d0,d1		;2 cycles
	move.l	d2,d3		;2 cycles

	and.l	d4,d0		;2 cycles
	and.l	d4,d2		;2 cycles
	lsr.l	#8,d2		;2 cycles
	or.l	d2,d0		;2 cycles

	move.l	d0,(a1)+	;ChipRam Write

	and.l	d5,d1		;2 cycles
	and.l	d5,d3		;2 cycles
	lsl.l	#8,d1		;2 cycles
	or.l	d3,d1		;2 cycles

	IFD	ClearChunkyBuffer

	move.l	(a0),a2		;
	clr.l	(a0)+
	move.l	(a0),a3		;
	clr.l	(a0)+

	ELSE

	move.l	(a0)+,a2	;
	move.l	(a0)+,a3	;

	ENDIF

	move.l	d1,(a1)+	;ChipRam Write

	move.l	a2,d0		;2 cycles
	move.l	a3,d2		;2 cycles

	dbra	d7,.Loop
;-------

	move.l	d0,d1		;2 cycles
	move.l	d2,d3		;2 cycles

	and.l	d4,d0		;2 cycles
	and.l	d4,d2		;2 cycles
	lsr.l	#8,d2		;2 cycles
	or.l	d2,d0		;2 cycles

	move.l	d0,(a1)+	;ChipRam Write

	and.l	d5,d1		;2 cycles
	and.l	d5,d3		;2 cycles
	lsl.l	#8,d1		;2 cycles
	or.l	d3,d1		;2 cycles

	move.l	d1,(a1)+	;ChipRam Write

	RastPos	e_c2p_time

;-----------------Start Blitter--------------------

	move.l	#BlitterPass,BlittInter

	lea.l	$dff000,a0
	move.l	#$FFFFFFFF,bltafwm(a0)

	move.l	Buffer_0,d0
	move.l	d0,bltbpt(a0)
	addq.l	#2,d0
	move.l	d0,bltapt(a0)

	move.l	Buffer_1,bltdpt(a0)

	move.w	#$4DE4,bltcon0(a0)	;AC+Bc
	move.w	#$0000,bltcon1(a0)
	move.w	#$0F0F,bltcdat(a0)
	move.w	#$0002,bltamod(a0)
	move.w	#$0002,bltbmod(a0)
	move.w	#$0000,bltdmod(a0)
	move.w	#ChunkyPixels/4,bltsizv(a0)
	move.w	#$0001,bltsizh(a0)

	move.w	#-1,BlitterIsDone

	ClrINTQ	INTF_BLIT
	SetINT	INTF_INTEN!INTF_BLIT

	addq.l	#1,TellFrames
	rts



;-------------------BLITTER DEL, 2 passes ----------------
BlitterPass:

	lea.l	$dff000,a0

	move.l	Buffer_1,d0
	move.l	d0,bltbpt(a0)
	addq.l	#2,d0
	move.l	d0,bltapt(a0)

	move.l	Screen_0,d0
	add.l	#BitplaneSize*3,d0
	move.l	d0,bltdpt(a0)

	move.w	#$2DE4,bltcon0(a0)
	move.w	#$0000,bltcon1(a0)
	move.w	#$3333,bltcdat(a0)
	move.w	#$0002,bltamod(a0)
	move.w	#$0002,bltbmod(a0)
	move.w	#$0000,bltdmod(a0)
	move.w	#BitplaneSize/2,bltsizv(a0)
	move.w	#$0001,bltsizh(a0)

	move.l	#.p1,BlittInter
	movem.l	(sp)+,d0/a0
	ClrINTQ	INTF_BLIT
	rte

.p1:
	lea.l	$dff000,a0

	move.l	Buffer_1,d0
	add.l	#-2+ChunkyPixels/2,d0
	move.l	d0,bltbpt(a0)

	move.l	Buffer_1,d0
	add.l	#-4+ChunkyPixels/2,d0
	move.l	d0,bltapt(a0)

	move.l	Screen_0,d0
	add.l	#-2+ChunkyPixels/4+BitplaneSize*2,d0
	move.l	d0,bltdpt(a0)

	move.w	#$2DE4,bltcon0(a0)
	move.w	#$0002,bltcon1(a0)
	move.w	#$CCCC,bltcdat(a0)
	move.w	#$0002,bltamod(a0)
	move.w	#$0002,bltbmod(a0)
	move.w	#$0000,bltdmod(a0)
	move.w	#BitplaneSize/2,bltsizv(a0)
	move.w	#$0001,bltsizh(a0)

	move.l	#.p2,BlittInter
	movem.l	(sp)+,d0/a0
	ClrINTQ	INTF_BLIT
	rte

.p2:
	lea.l	$dff000,a0

	move.l	Buffer_0,d0
	add.l	#-2+ChunkyPixels,d0
	move.l	d0,bltbpt(a0)
	
	move.l	Buffer_0,d0
	add.l	#-4+ChunkyPixels,d0
	move.l	d0,bltapt(a0)

	move.l	Buffer_1,d0
	add.l	#-2+ChunkyPixels/2,d0
	move.l	d0,bltdpt(a0)

	move.w	#$4DE4,bltcon0(a0)
	move.w	#$0002,bltcon1(a0)
	move.w	#$F0F0,bltcdat(a0)
	move.w	#$0002,bltamod(a0)
	move.w	#$0002,bltbmod(a0)
	move.w	#$0000,bltdmod(a0)
	move.w	#ChunkyPixels/4,bltsizv(a0)
	move.w	#$0001,bltsizh(a0)

	move.l	#.p3,BlittInter
	movem.l	(sp)+,d0/a0
	ClrINTQ	INTF_BLIT
	rte

.p3:
	lea.l	$dff000,a0

	move.l	Buffer_1,d0
	move.l	d0,bltbpt(a0)
	addq.l	#2,d0
	move.l	d0,bltapt(a0)

	move.l	Screen_0,d0
	add.l	#BitplaneSize*1,d0
	move.l	d0,bltdpt(a0)

	move.w	#$2DE4,bltcon0(a0)
	move.w	#$0000,bltcon1(a0)
	move.w	#$3333,bltcdat(a0)
	move.w	#$0002,bltamod(a0)
	move.w	#$0002,bltbmod(a0)
	move.w	#$0000,bltdmod(a0)
	move.w	#BitplaneSize/2,bltsizv(a0)
	move.w	#$0001,bltsizh(a0)

	move.l	#.p4,BlittInter
	movem.l	(sp)+,d0/a0
	ClrINTQ	INTF_BLIT
	rte

.p4:
	lea.l	$dff000,a0

	move.l	Buffer_1,d0
	add.l	#-2+ChunkyPixels/2,d0
	move.l	d0,bltbpt(a0)

	move.l	Buffer_1,d0
	add.l	#-4+ChunkyPixels/2,d0
	move.l	d0,bltapt(a0)

	move.l	Screen_0,d0
	add.l	#-2+ChunkyPixels/4,d0
	move.l	d0,bltdpt(a0)

	move.w	#$2DE4,bltcon0(a0)
	move.w	#$0002,bltcon1(a0)
	move.w	#$CCCC,bltcdat(a0)
	move.w	#$0002,bltamod(a0)
	move.w	#$0002,bltbmod(a0)
	move.w	#$0000,bltdmod(a0)
	move.w	#BitplaneSize/2,bltsizv(a0)
	move.w	#$0001,bltsizh(a0)

	move.l	#.done,BlittInter
	movem.l	(sp)+,d0/a0
	ClrINTQ	INTF_BLIT
	rte
.done:

	movem.l	(sp)+,d0/a0

	ClrINTQ	INTF_BLIT
	ClrINT	INTF_BLIT

	clr.w	BlitterIsDone
	rte

;-------------------chunky 2 planar-------------------

c2p_2_Pass:

.Swait:	tst.w	SetScreen	;Make sure the last frame was displayed,
	bne.b	.Swait		;no need to go faster than 50 fps.

.Bwait:	tst.w	BlitterIsDone	;Make sure the blitter is done with the
	bne.b	.Bwait		;previous frame.

	move.l	Screen_0,d0
	move.l	Screen_1,Screen_0
	move.l	Screen_2,Screen_1
	move.l	Screen_3,Screen_2
	move.l	d0,Screen_3

	move.w	#-1,SetScreen

;----------------CPU AntiScrambler & 1 extra cpu pass ----------------

	RastPos	s_c2p_time

	lea.l	ChunkyBuffer,a0
	move.l	Buffer_1,a1

	move.l	#$f0f0f0f0,d6
	move.l	d6,d7
	not.l	d7

	move.w	#ChunkyPixels/8-2,d5

	IFD	ClearChunkyBuffer

	move.l	(a0),d0		;Buffered chunky write
	clr.l	(a0)+
	move.l	(a0),d2		;Buffered chunky write
	clr.l	(a0)+

	ELSE

	move.l	(a0)+,d0	;Buffered chunky write
	move.l	(a0)+,d2	;Buffered chunky write

	ENDIF

.loop:
	move.w	d0,d1	;2 cycles
	swap	d2	;4 cycles
	move.w	d2,d0	;2 cycles
	move.w	d1,d2	;2 cycles
	swap	d2	;4 cycles
	move.l	d0,d1	;2 cycles
	move.l	d2,d3	;2 cycles	sum: 22 cycles

	and.l	d6,d0	;2 cycles
	and.l	d6,d2	;2 cycles
	lsr.l	#4,d2	;4 cycles
	or.l	d2,d0	;2 cycles
	
	ror.l	#8,d0	;6 cycles
	ror.w	#8,d0	;6 cycles
	ror.l	#8,d0	;6 cycles	sum: 28 cycles

	move.l	d0,(a1)+

	and.l	d7,d1	;2 cycles
	and.l	d7,d3	;2 cycles
	lsl.l	#4,d1	;4 cycles
	or.l	d3,d1	;2 cycles

	ror.l	#8,d1	;6 cycles
	ror.w	#8,d1	;6 cycles
	ror.l	#8,d1	;6 cycles	sum: 28 cycles

	IFD	ClearChunkyBuffer

	move.l	(a0),a2		;
	clr.l	(a0)+
	move.l	(a0),a3		;
	clr.l	(a0)+

	ELSE

	move.l	(a0)+,a2	;
	move.l	(a0)+,a3	;

	ENDIF

	move.l	d1,(a1)+

	move.l	a2,d0	;2 cycles
	move.l	a3,d2	;2 cycles

	dbra	d5,.loop
;-------
	move.w	d0,d1	;2 cycles
	swap	d2	;4 cycles
	move.w	d2,d0	;2 cycles
	move.w	d1,d2	;2 cycles
	swap	d2	;4 cycles
	move.l	d0,d1	;2 cycles
	move.l	d2,d3	;2 cycles	sum: 22 cycles

	and.l	d6,d0	;2 cycles
	and.l	d6,d2	;2 cycles
	lsr.l	#4,d2	;4 cycles
	or.l	d2,d0	;2 cycles
	
	ror.l	#8,d0	;6 cycles
	ror.w	#8,d0	;6 cycles
	ror.l	#8,d0	;6 cycles	sum: 28 cycles

	move.l	d0,(a1)+

	and.l	d7,d1	;2 cycles
	and.l	d7,d3	;2 cycles
	lsl.l	#4,d1	;4 cycles
	or.l	d3,d1	;2 cycles

	ror.l	#8,d1	;6 cycles
	ror.w	#8,d1	;6 cycles
	ror.l	#8,d1	;6 cycles	sum: 28 cycles

	move.l	d1,(a1)+


	RastPos	e_c2p_time

;-----------------Start Blitter--------------------

	move.l	#SmallBlitterPass,BlittInter

	lea.l	$dff000,a0

	move.l	Buffer_1,d0
	move.l	d0,bltbpt(a0)
	addq.l	#2,d0
	move.l	d0,bltapt(a0)

	move.l	Screen_0,d0
	add.l	#BitplaneSize*3,d0
	move.l	d0,bltdpt(a0)

	move.l	#$FFFFFFFF,bltafwm(a0)
	move.w	#$0D00!(_AC+_Bc),bltcon0(a0)
	move.w	#$2000,bltcon1(a0)
	move.w	#$CCCC,bltcdat(a0)
	move.w	#$0006,bltamod(a0)
	move.w	#$0006,bltbmod(a0)
	move.w	#$0000,bltdmod(a0)
	move.w	#BitplaneSize/2,bltsizv(a0)
	move.w	#$0001,bltsizh(a0)

	move.w	#-1,BlitterIsDone

	ClrINTQ	INTF_BLIT
	SetINT	INTF_INTEN!INTF_BLIT

	addq.l	#1,TellFrames
	rts

;-------------------BLITTER DEL, 1 pass ----------------
_AC = $A0
_Bc = $44

SmallBlitterPass:
	lea.l	$dff000,a0

	move.l	Buffer_1,d0
	add.l	#ChunkyPixels-8,d0
	move.l	d0,bltbpt(a0)

	move.l	Buffer_1,d0
	add.l	#ChunkyPixels-8+2,d0
	move.l	d0,bltapt(a0)

	move.l	Screen_0,d0
	add.l	#BitplaneSize*3-2,d0
	move.l	d0,bltdpt(a0)

	move.w	#$2D00!(_AC+_Bc),bltcon0(a0)
	move.w	#$0002,bltcon1(a0)
	move.w	#$cccc,bltcdat(a0)
	move.w	#$0006,bltamod(a0)
	move.w	#$0006,bltbmod(a0)
	move.w	#$0000,bltdmod(a0)
	move.w	#BitplaneSize/2,bltsizv(a0)
	move.w	#$0001,bltsizh(a0)

	move.l	#.p32,BlittInter
	movem.l	(sp)+,d0/a0
	ClrINTQ	INTF_BLIT
	rte

.p32:
	lea.l	$dff000,a0

	move.l	Buffer_1,d0
	add.l	#4,d0
	move.l	d0,bltbpt(a0)

	move.l	Buffer_1,d0
	add.l	#6,d0
	move.l	d0,bltapt(a0)

	move.l	Screen_0,d0
	add.l	#BitplaneSize*1,d0
	move.l	d0,bltdpt(a0)

	move.w	#$0D00!(_AC+_Bc),bltcon0(a0)
	move.w	#$2000,bltcon1(a0)
	move.w	#$CCCC,bltcdat(a0)
	move.w	#$0006,bltamod(a0)
	move.w	#$0006,bltbmod(a0)
	move.w	#$0000,bltdmod(a0)
	move.w	#BitplaneSize/2,bltsizv(a0)
	move.w	#$0001,bltsizh(a0)

	move.l	#.p33,BlittInter
	movem.l	(sp)+,d0/a0
	ClrINTQ	INTF_BLIT
	rte

.p33:
	lea.l	$dff000,a0

	move.l	Buffer_1,d0
	add.l	#ChunkyPixels-4,d0
	move.l	d0,bltbpt(a0)

	move.l	Buffer_1,d0
	add.l	#ChunkyPixels-4+2,d0
	move.l	d0,bltapt(a0)

	move.l	Screen_0,d0
	add.l	#BitplaneSize*1-2,d0
	move.l	d0,bltdpt(a0)

	move.w	#$2D00!(_AC+_Bc),bltcon0(a0)
	move.w	#$0002,bltcon1(a0)
	move.w	#$cccc,bltcdat(a0)
	move.w	#$0006,bltamod(a0)
	move.w	#$0006,bltbmod(a0)
	move.w	#$0000,bltdmod(a0)
	move.w	#BitplaneSize/2,bltsizv(a0)
	move.w	#$0001,bltsizh(a0)

	move.l	#.done,BlittInter
	movem.l	(sp)+,d0/a0
	ClrINTQ	INTF_BLIT
	rte

.done:
	movem.l	(sp)+,d0/a0

	ClrINTQ	INTF_BLIT
	ClrINT	INTF_BLIT

	clr.w	BlitterIsDone
	rte

;-----------------------------------------------
NoInters:
	movem.l	(sp)+,d0/a0
	rte

Lev3InterruptHandler:
	movem.l	d0/a0,-(sp)
	lea.l	$dff000,a0
	move.w	$1c(a0),d0
	btst	#14,d0
	beq.b	NoInters
	and.w	$1e(a0),d0
	btst	#6,d0
	beq.b	VertBInter
	movem.l	(sp)+,d0/a0
;BlittInter
	movem.l	d0/a0,-(sp)
	move.l	BlittInter(pc),a0
	jmp	(a0)	

VertBInter:
	btst	#5,d0
	beq.b	NoInters
	movem.l	(sp)+,d0/a0

;--------
	movem.l	d0-a6,-(sp)

	tst.w	SetScreen
	beq.b	SkipSetScreen	

	bsr	UpdateCopperList

	clr.w	SetScreen

SkipSetScreen:
	clr.w	VBL

	addq.l	#1,TellTicks

	movem.l	(sp)+,d0-a6

	ClrINTQ	INTF_VERTB
	rte

BlittInter:		dc.l	BlitterPass

BlitterIsDone:		dc.w	0
VBL:			dc.w	0
SetScreen:		dc.w	0

OldLevel3Inter:		dc.l	0

TellFrames:		dc.l	0
TellTicks:		dc.l	0

Buffer_0:		dc.l	Buffer0
Buffer_1:		dc.l	Buffer1

Screen_0:		dc.l	Screen0
Screen_1:		dc.l	Screen1
Screen_2:		dc.l	Screen2
Screen_3:		dc.l	Screen3

;-----------------------------------------------------------------------------

SetupCopperList:
	SetBitmap	SpriteData1,Spr1,5,4112
	SetBitmap	SpriteData2,Spr2,5,4112

	move.l	#CopperList1,d0
	move.w	d0,CopColNext+6
	swap	d0
	move.w	d0,CopColNext+2
         
	move.l	#CopperList1,d0
	move.w	d0,NextCop2+6
	swap	d0
	move.w	d0,NextCop2+2

	move.l	#CopperList2,d0
	move.w	d0,NextCop1+6
	swap	d0
	move.w	d0,NextCop1+2

	lea.l	SpriteData1,a1
	move.l	#$AAAAAAAA,d0
	move.l	#$55555555,d1
	bsr	MakeDitherSprites

	lea.l	SpriteData2,a1
	move.l	#$55555555,d0
	move.l	#$AAAAAAAA,d1
	bsr	MakeDitherSprites

	bsr	UpdateCopperList
	SetCop	ColorCopperList
	rts

UpdateCopperList:
	move.l	Screen_2,a2
	SetBitmap	(a2),Bitpls1,4,BitplaneSize,16
	SetBitmap	(a2),Bitpls1+8,4,BitplaneSize,16
	SetBitmap	(a2),Bitpls2,4,BitplaneSize,16
	SetBitmap	(a2),Bitpls2+8,4,BitplaneSize,16
	rts
;-------------------------------------------------

MakeDitherSprites:

	lea.l	SpritePos,a0

	moveq	#5-1,d3

.loop2:	move.l	(a0)+,(a1)+
	move.l	(a0)+,(a1)+
	move.l	(a0)+,(a1)+
	move.l	(a0)+,(a1)+

	move.w	#128-1,d2
.loop:
	move.l	d0,(a1)+
	move.l	d0,(a1)+
	move.l	d0,(a1)+
	move.l	d0,(a1)+

	move.l	d1,(a1)+
	move.l	d1,(a1)+
	move.l	d1,(a1)+
	move.l	d1,(a1)+
	dbra	d2,.loop

	dbra	d3,.loop2

	rts

SpritePos:
	dc.w	$2940,$0000,$0000,$0000,$3002,$0000,$0000,$0000
	dc.w	$2960,$0000,$0000,$0000,$3002,$0000,$0000,$0000
	dc.w	$2980,$0000,$0000,$0000,$3002,$0000,$0000,$0000
	dc.w	$29a0,$0000,$0000,$0000,$3002,$0000,$0000,$0000
	dc.w	$29c0,$0000,$0000,$0000,$3002,$0000,$0000,$0000

;------------------------------------------------------------------------

	Section	TheCopperList,data_c


ColorCopperList:
	incbin	"src3:tmap2/gfx/NewTexture03.col"

        dc.w  $0106,$E000		;Set sprite colors to black.
        dc.w  $01a6,$0000
        dc.w  $01ae,$0000
        dc.w  $01b6,$0000
        dc.w  $0106,$0000

CopColNext:
	dc.w	$0080,$0000,$0082,$0000
	dc.w	$0088,$0000
	dc.l	$ffff,$fffe
	dc.l	$ffff,$fffe

CopperList1:

Spr1:	dc.w	$0120,$0000
        dc.w	$0122,$0000
        dc.w	$0124,$0000
        dc.w	$0126,$0000
        dc.w	$0128,$0000
        dc.w	$012A,$0000
        dc.w	$012C,$0000
        dc.w	$012E,$0000
        dc.w	$0130,$0000
        dc.w	$0132,$0000
        dc.w	$0134,$0000
        dc.w	$0136,$0000
        dc.w	$0138,$0000
        dc.w	$013A,$0000
        dc.w	$013C,$0000
        dc.w	$013E,$0000

        dc.w	$01fc,$400f
        dc.w	$0106,$0000
	dc.w	$010c,$00ff

	dc.w	$0102,$0010

	dc.w	$0100,$0210

        dc.w	$0104,$003f
        dc.w	$008e,$0081+(($29+(128-ScreenHeight))&$ff)<<8
        dc.w	$0090,$00c1+(($29+(128-ScreenHeight)+ScreenHeight*2)&$ff)<<8
        dc.w	$0092,$0038,$0094,$00b0
        dc.w	$0108,-40
        dc.w	$010a,0

	dc.w	$1011,$fffe
Bitpls1:
        dc.w	$00e0,$0000
        dc.w	$00e2,$0000
        dc.w	$00e4,$0000
        dc.w	$00e6,$0000
        dc.w	$00e8,$0000
        dc.w	$00ea,$0000
        dc.w	$00ec,$0000
        dc.w	$00ee,$0000
        dc.w	$00f0,$0000
        dc.w	$00f2,$0000
        dc.w	$00f4,$0000
        dc.w	$00f6,$0000
        dc.w	$00f8,$0000
        dc.w	$00fa,$0000
        dc.w	$00fc,$0000
        dc.w	$00fe,$0000


Tell	set	$28

	rept	108

	dc.b	Tell,$11,$ff,$fe
	dc.w	$0102,$0021

	dc.b	Tell+1,$11,$ff,$fe
	dc.w	$0102,$0010

Tell	set	Tell+2
	endr

	dc.w	$ffdf,$fffe

Tell	set	$00

	rept	21

	dc.b	Tell,$11,$ff,$fe
	dc.w	$0102,$0021

	dc.b	Tell+1,$11,$ff,$fe
	dc.w	$0102,$0010

Tell	set	Tell+2
	endr


NextCop1:
	dc.w	$0080,$0000,$0082,$0000
	dc.w	$0088,$0000

        dc.w	$FFFF,$FFFE
        dc.w	$FFFF,$FFFE

;----------------------------------------------------------------
CopperList2:

Spr2:	dc.w	$0120,$0000
        dc.w	$0122,$0000
        dc.w	$0124,$0000
        dc.w	$0126,$0000
        dc.w	$0128,$0000
        dc.w	$012A,$0000
        dc.w	$012C,$0000
        dc.w	$012E,$0000
        dc.w	$0130,$0000
        dc.w	$0132,$0000
        dc.w	$0134,$0000
        dc.w	$0136,$0000
        dc.w	$0138,$0000
        dc.w	$013A,$0000
        dc.w	$013C,$0000
        dc.w	$013E,$0000

        dc.w	$01fc,$400f
        dc.w	$0106,$0000
	dc.w	$010c,$00ff

	dc.w	$0102,$0010

	dc.w	$0100,$0210

        dc.w	$0104,$003f
        dc.w	$008e,$0081+(($29+(128-ScreenHeight))&$ff)<<8
        dc.w	$0090,$00c1+(($29+(128-ScreenHeight)+ScreenHeight*2)&$ff)<<8
        dc.w	$0092,$0038,$0094,$00b0
        dc.w	$0108,-40
        dc.w	$010a,0

	dc.w	$1011,$fffe

Bitpls2:
        dc.w	$00e0,$0000
        dc.w	$00e2,$0000
        dc.w	$00e4,$0000
        dc.w	$00e6,$0000
        dc.w	$00e8,$0000
        dc.w	$00ea,$0000
        dc.w	$00ec,$0000
        dc.w	$00ee,$0000
        dc.w	$00f0,$0000
        dc.w	$00f2,$0000
        dc.w	$00f4,$0000
        dc.w	$00f6,$0000
        dc.w	$00f8,$0000
        dc.w	$00fa,$0000
        dc.w	$00fc,$0000
        dc.w	$00fe,$0000

Tell	set	$28

	rept	108

	dc.b	Tell,$11,$ff,$fe
	dc.w	$0102,$0010

	dc.b	Tell+1,$11,$ff,$fe
	dc.w	$0102,$0021

Tell	set	Tell+2
	endr

	dc.w	$ffdf,$fffe

Tell	set	$00

	rept	21

	dc.b	Tell,$11,$ff,$fe
	dc.w	$0102,$0010

	dc.b	Tell+1,$11,$ff,$fe
	dc.w	$0102,$0021

Tell	set	Tell+2
	endr

NextCop2:
	dc.w	$0080,$0000,$0082,$0000
	dc.w	$0088,$0000

        dc.w	$FFFF,$FFFE
        dc.w	$FFFF,$FFFE


;----------------------------------------------------------------
	section	BitMaps,data_C

Buffer0:	ds.b	BitplaneSize*8
Buffer1:	ds.b	BitplaneSize*8

Screen0:	ds.b	BitplaneSize*8
Screen1:	ds.b	BitplaneSize*8
Screen2:	ds.b	BitplaneSize*8
Screen3:	ds.b	BitplaneSize*8

SpriteData1:	ds.l	(4*256+4)*5
SpriteData2:	ds.l	(4*256+4)*5

