	opt	C-

**********************************************************
CHECKFLG	=	0		;1 = TO GENERATE CODE-TABLE!!!
**********************************************************
TABLESIZE	=	7*2
MODIFIERA	=	999
MODIFIERB	=	700
**********************************************************
SPfix	=	-30
SPflt	=	-36
SPcmp	=	-42
SPtst	=	-48
SPabs	=	-54
SPneg	=	-60
SPadd	=	-66
SPsub	=	-72
SPmul	=	-78
SPdiv	=	-84
********************************************
	
pass_main:	BSR	OPENMATHLIB
	tst.l mathbase
	ble nomath

;	move.l	#17,row		;1-17		just to test!
;	move.l	#2,col		;1-50
;	move.l	#2*2,tableadd	;A-F

	BSR	getrowcolrandom


 IFNE	CHECKFLG
 	lea row(pc),a0
	move.l	#1,(a0)
 	lea col(pc),a0
	move.l	#1,(a0)
	lea tableadd,a0
	move.l	#1*2,(a0)
	lea	checktab,a3
 ENDC
.lp:
	lea	tabletab-2,a4
	add.l	tableadd,a4
	lea	scratchpad,a5
	move.l	mathbase,a6

	BSR	PART1			;ROW*ROW*COL*COL*A
	add.w	#TABLESIZE,a4
	BSR	PART2			;ROW*ROW*COL*B
	add.w	#TABLESIZE,a4
	BSR	PART3			;COL*ROW*C
	add.w	#TABLESIZE,a4
	BSR	PART4			;COL*D
	add.w	#TABLESIZE,a4
	BSR	PART5			;ROW*E
	add.w	#TABLESIZE,a4
	BSR	PART6			;+F
	BSR	GETMOD

	move.l	mathbase,a6
	jsr	spfix(a6)

	sub.l	#999,d0
	neg.l	d0
	lea code(pc),a0
	move.l	d0,(a0)

 IFNE	CHECKFLG
	move.l	d0,(a3)+
	lea col(pc),a0
	addq.l	#1,(a0)
	cmp.l	#17,(a0)
	bls	.lp
	clr.l	(a0)
	lea row,a0
	addq.l	#1,(a0)
	cmp.l	#50,(a0)
	bls	.lp
 ENDC

***************
	BSR	CLOSEMATHLIB
	move.l	code,d0
	move.l	row,d1
	move.l  col,d2
	move.l  tableadd,d3
	rts
	nomath:
	move.l #-1,d0
	move.l d0,d1
	move.l d1,d2
	move.l d2,d3
	rts
code:	dc.l	0
getrowcolrandom:
j:	
	move.l #$dff000,a0
	move.b	7(a0),d0
	move.b	6(a0),d1
	add.b	d1,d0
	add.b	d0,d1
	add.b	$b(a0),d0
	sub.b	$a(a0),d1


	move.b	d0,d2
	sub.b	d1,d2

	add.b	d0,d1
	and.l	#63,d0
	cmp.w	#49,d0
	blo	.ok
	sub.w	#49,d0
.ok:	addq.w	#1,d0
	lea col(pc),a0
	move.l	d0,(a0)
	and.l	#31,d1
	cmp.w	#17,d1
	blo	.ok2
	sub.w	#17,d1
.ok2:	addq.w	#1,d1
	lea row(pc),a0
	move.l	d1,(a0)

	and.l	#7,d2
	cmp.w	#6,d2
	blo	.ok3
	subq.w	#6,d2
.ok3:	addq.w	#1,d2
	add.w	d2,d2
	lea tableadd(pc),a0
	move.l	d2,(a0)
	rts

part1:****************************** ROW*COL*COL*A
	move.l	row,d0
	jsr	spflt(a6)
	lea rowflt(pc),a0
	move.l	d0,(a0)
;	move.l	d0,d1
;	jsr	spmul(a6)		;ROW*ROW
	move.l	d0,d6
********
	move.l	col,d0
	jsr	spflt(a6)
	lea colflt(pc),a0
	move.l	d0,(a0)
	move.l	d0,d1
	jsr	spmul(a6)		;*COL
	move.l	d6,d1
	jsr	spmul(a6)		;*COL
	move.l	d0,d6
********
	moveq	#0,d0
	move.w	(a4),d0
	jsr	spflt(a6)
	move.l	d6,d1
	jsr	spmul(a6)
	move.l	d0,(a5)
**************************************
	rts

part2:****************************** ROW*ROW*COL*B
	move.l	rowflt,d0
	move.l	d0,d1
	jsr	spmul(a6)		;ROW*ROW
	move.l	d0,d1

	move.l	colflt,d0
	jsr	spmul(a6)		;*COL
	move.l	d0,d6
********
	moveq	#0,d0
	move.w	(a4),d0
	jsr	spflt(a6)
	move.l	d6,d1
	jsr	spmul(a6)		;*B

	move.l	(a5),d1
	jsr	spadd(a6)
	move.l	d0,(a5)
********
	rts
part3:****************************** COL*ROW*C
	move.l	colflt,d0
	move.l	rowflt,d1
	jsr	spmul(a6)		;COL*ROW
	move.l	d0,d6
********
	moveq	#0,d0
	move.w	(a4),d0
	jsr	spflt(a6)
	move.l	d6,d1
	jsr	spmul(a6)		;*C

	move.l	(a5),d1
	jsr	spadd(a6)
	move.l	d0,(a5)
********
	rts
part4:****************************** 
	moveq	#0,d0
	move.w	(a4),d0
	jsr	spflt(a6)
	move.l	colflt,d1
	jsr	spmul(a6)		;COL*D

	move.l	(a5),d1
	jsr	spadd(a6)
	move.l	d0,(a5)
********
	rts

part5:****************************** 
	moveq	#0,d0
	move.w	(a4),d0
	jsr	spflt(a6)
	move.l	rowflt,d1
	jsr	spmul(a6)		;ROW*E

	move.l	(a5),d1
	jsr	spadd(a6)
	move.l	d0,(a5)
********
	rts
part6:****************************** 
	moveq	#0,d0
	move.w	(a4),d0
	jsr	spflt(a6)		;+ F
	move.l	(a5),d1
	jsr	spadd(a6)
	move.l	d0,(a5)
********
	rts



getmod:*************************** GET MODULUS!!
	move.l	(a5),d6
	move.l	#MODIFIERB,d0
	jsr	spflt(a6)
	move.l	d0,d5
	move.l	d0,d1
	move.l	d6,d0
	jsr	spdiv(a6)
	jsr	spfix(a6)
	jsr	spflt(a6)
	move.l	d5,d1
	jsr	spmul(a6)
	move.l	d0,d1
	move.l	d6,d0
	jsr	spsub(a6)
***************
	rts
col:		dc.l	0
row:		dc.l	0
tableadd:	dc.l	0
colflt:		dc.l	0
rowflt:		dc.l	0
scratchpad:	dcb.l	16,0
openmathlib:
	lea	mathname,a1
	move.l #$4,a0
	move.l (a0),a6
	jsr	-408(a6)
	lea mathbase(pc),a0
	move.l	d0,(a0)
	rts
closemathlib:
	move.l	mathbase,a1
	move.l #$4,a0
	move.l (a0),a6
	jsr	-414(a6)
	rts
tabletab:					;parameters
	dc.w	073,165,111,005,123,088,046
	dc.w	068,094,024,094,032,077,054
	dc.w	024,037,158,066,045,103,091
	dc.w	042,012,099,027,054,066,067
	dc.w	006,055,075,035,034,091,033
	dc.w	097,046,083,049,022,038,028

mathbase:	dc.l	0
mathname:	dc.b	'mathffp.library',0

 EVEN
 IFNE	CHECKFLG
 checktab:	dcb.l	850,0
 ENDC

 opt C+