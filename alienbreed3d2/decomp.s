Loadview	=	-222
WaitTOF		=	-270


;-------------------------------------------------------------------------
;        D0 = Source pointer
;        A0 = Destination memory pointer
;        A1 = 16K Workspace
;        D1 = 0
;        
;-------------------------------------------------------------------------

main:
*************************************
	move.l	#data,d0
	moveq	#0,d1
	lea	dest,a0
	lea	buffer,a1
	lea	$0,a2
	jsr	unLHA
*************************************
	rts


 SECTION	data2,DATA_F
********************
UnLhA:	incbin	"Decomp4.raw"
buffer:		ds.b	16384
********************
data:			;load lha-datafile

 SECTION	data3,DATA_C
dest:		ds.b	81920



