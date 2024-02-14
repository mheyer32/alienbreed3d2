*---------------------------------------------------------------------------*
CACHE_ON		MACRO
*---------------------------------------------------------------------------*
;				movec.l	CACR,\1
;				or.l	#1,\1
;				movec.l	\1,CACR
				ENDM
*---------------------------------------------------------------------------*
CACHE_OFF		MACRO
*---------------------------------------------------------------------------*
;				movec.l	CACR,\1
;				and.l	#-2,\1
;				movec.l	\1,CACR
				ENDM
*---------------------------------------------------------------------------*
DATA_CACHE_CLEAR MACRO
*---------------------------------------------------------------------------*
;				movec.l	CACR,\1
;				or.l	#%100000000000,\1
;				movec.l	\1,CACR
				ENDM
*---------------------------------------------------------------------------*
CACHE_CLEAR		MACRO
*---------------------------------------------------------------------------*
;				movec.l	CACR,\1
;				or.l	#8,\1
;				movec.l	\1,CACR
				ENDM
*---------------------------------------------------------------------------*
CACHE_FREEZE_ON	MACRO
*---------------------------------------------------------------------------*
;				movec.l	CACR,\1
;				or.l	#2,\1		; Freeze instruction cache
;				movec.l	\1,CACR
				ENDM
*---------------------------------------------------------------------------*

DATA_CACHE_ON	MACRO
*---------------------------------------------------------------------------*
;				movec.l	CACR,\1
;				or.l	#$10,\1
;				movec.l	\1,CACR
				ENDM
*---------------------------------------------------------------------------*
DATA_CACHE_OFF	MACRO
*---------------------------------------------------------------------------*
;				movec.l	CACR,\1
;				and.l	#%11111111111111111111111011111111,\1
;				movec.l	\1,CACR
				ENDM
*---------------------------------------------------------------------------*


CACHE_FREEZE_OFF MACRO
*---------------------------------------------------------------------------*
;				movec.l	CACR,\1
;				and.l	#%11111111111111111111111111111101,\1
;				movec.l	\1,CACR
				ENDM
*---------------------------------------------------------------------------*
DUGDOS			MACRO
				move.l	DosBase,a6
				jsr		_LVO\1(a6)				DosCall
				ENDM
*---------------------------------------------------------------------------*
DUGREQ			MACRO
				move.l	ReqBase,a6
				jsr		_LVO\1(a6)				ReqCall
				ENDM
*---------------------------------------------------------------------------*
BLIT_NASTY		MACRO
				move.w	#$8400,Dmacon(a6)		Blitter Nasty On
				ENDM
*---------------------------------------------------------------------------*
BLIT_NICE		MACRO
				move.w	#$0400,Dmacon(a6)		Blitter Nasty Off
				ENDM
*---------------------------------------------------------------------------*
WAIT_BLIT		MACRO
.\@
				btst	#6,DMACONR(a6)			Wait for Blitter End
				bne.s	.\@
				ENDM

*---------------------------------------------------------------------------*
SCROLL_WB		MACRO
.\@
				btst	#6,DMACONR-BLTSIZE(a3)	Wait for Blitter End
				bne.s	.\@
				ENDM
*---------------------------------------------------------------------------*
;PALETTE32COL	MACRO
;				dc.l	$1800000,$1820000,$1840000,$1860000,$1880000,$18a0000
;				dc.l	$18c0000,$18e0000,$1900000,$1920000,$1940000,$1960000
;				dc.l	$1980000,$19a0000,$19c0000,$19e0000,$1a00000,$1a20000
;				dc.l	$1a40000,$1a60000,$1a80000,$1aa0000,$1ac0000,$1ae0000
;				dc.l	$1b00000,$1b20000,$1b40000,$1b60000,$1b80000,$1ba0000
;				dc.l	$1bc0000,$1be0000
;				ENDM
*---------------------------------------------------------------------------*

* QMOVE		 move a constant into a reg the quickest way (probbly)      *
* qmove.w 123,d0 NB:if word or byte, will still use moveq!!! if it can      *
*---------------------------------------------------------------------------*
QMOVE			MACRO
				IFGE	\1
				IFLE	\1-127
				moveq	#\1,\2
				MEXIT
				ENDC
				IFLE	\1-255
				moveq	#256-\1,\2
				neg.b	\2
				MEXIT
				ENDC
				move.\0	#\1,\2
				MEXIT
				ELSEIF
				move.\0	#\1,\2
				ENDC
				ENDM
;*---------------------------------------------------------------------------*
;STRUCTURE	MACRO		; structure name, initial offset
;*---------------------------------------------------------------------------*
;\1		EQU	0
;SOFFSET		SET     0
;		ENDM
;*---------------------------------------------------------------------------*
;BYTE		MACRO		;byte (8 bits)
;*---------------------------------------------------------------------------*
;\1		EQU	SOFFSET
;SOFFSET		SET	SOFFSET+1
;		ENDM
;*---------------------------------------------------------------------------*
;WORD	    	MACRO		; word (16 bits)
;*---------------------------------------------------------------------------*
;\1	    	EQU     SOFFSET
;SOFFSET     	SET     SOFFSET+2
;	    	ENDM
;*---------------------------------------------------------------------------*
;LONG	    	MACRO		; long (32 bits)
;*---------------------------------------------------------------------------*
;\1		EQU     SOFFSET
;SOFFSET		SET     SOFFSET+4
;	    	ENDM
;*---------------------------------------------------------------------------*
;NBYTE		MACRO		;byte (8 bits)
;*---------------------------------------------------------------------------*
;SOFFSET		SET	SOFFSET+1
;		ENDM
;*---------------------------------------------------------------------------*
;NWORD	    	MACRO		; word (16 bits)
;*---------------------------------------------------------------------------*
;SOFFSET     	SET     SOFFSET+2
;	    	ENDM
;*---------------------------------------------------------------------------*
;NLONG	    	MACRO		; long (32 bits)
;*---------------------------------------------------------------------------*
;SOFFSET		SET     SOFFSET+4
;	    	ENDM
;*---------------------------------------------------------------------------*
;LABEL	    	MACRO		; Define a label without bumping the offset
;*---------------------------------------------------------------------------*
;\1	    	EQU     SOFFSET
;	    	ENDM
;*---------------------------------------------------------------------------*
;STRUCT	    	MACRO		; Define a sub-structure
;*---------------------------------------------------------------------------*
;\1		EQU     SOFFSET
;SOFFSET		SET     SOFFSET+\2
;		ENDM
;*---------------------------------------------------------------------------*
;ALIGNWORD   	MACRO		; Align structure offset to nearest word
;*---------------------------------------------------------------------------*
;SOFFSET		SET     (SOFFSET+1)&$fffffffe
;	    	Even
;	    	ENDM
;*---------------------------------------------------------------------------*
;ALIGNLONG	MACRO		; Align structure offset to nearest longword
;*---------------------------------------------------------------------------*
;SOFFSET		SET     (SOFFSET+3)&$fffffffc
;		CNOP	0,4
;		ENDM
;*---------------------------------------------------------------------------*
;AGAALIGN	MACRO		; Align structure offset to nearest longword
;*---------------------------------------------------------------------------*
;		CNOP	0,8
;		ENDM
;*---------------------------------------------------------------------------*
_break			macro
;	bkpt	\1
				endm


FILTER			macro
;	move.l	d0,-(sp)
;	move.l	#65000,d0
;.loop\@
;	bchg	#1,$bfe001
;	dbra	d0,.loop\@
;	move.l	(sp)+,d0
				endm

SETCOPLOR0		macro
				movem.l	a0/a1/a6,-(a7)
				subq.l	#4,a7
				move.l	a7,a1
				move.w	#\1,(a1)				; a1 pointer to list of colors
				move.l	Vid_MainScreen_l,a0
				lea		sc_ViewPort(a0),a0		; viewport
				moveq	#1,d0					; count
				CALLGRAF LoadRGB4
				addq.l	#4,a7
				movem.l	(a7)+,a0/a1/a6
				endm

BLACK			macro
				SETCOPLOR0 $0
				endm

RED				macro
				SETCOPLOR0 $f00
				endm

FLASHER			macro
				movem.l	d1,-(sp)
				move.w	#-1,d1
.loop3\@
				move.w	#\1,_custom+color
				nop
				nop
				move.w	#\2,_custom+color
				nop
				nop
				dbra	d1,.loop3\@
				movem.l	(sp)+,d1

				endm

GREEN			macro
				SETCOPLOR0 $0f0
				endm

BLUE			macro
				SETCOPLOR0 $f
				endm

DataCacheOff	macro
				movem.l	a0-a6/d0-d7,-(sp)
				moveq	#0,d0
				move.l	#CACRF_EnableD,d1
				CALLEXEC CacheControl
				movem.l	(sp)+,a0-a6/d0-d7
				endm

DataCacheOn		macro
				movem.l	a0-a6/d0-d7,-(sp)
				moveq	#-1,d0
				move.l	#CACRF_EnableD|CACRF_WriteAllocate|CACRF_DBE,d1
				CALLEXEC CacheControl
				movem.l	(sp)+,a0-a6/d0-d7
				endm

SAVEREGS		MACRO
				movem.l	d0-d7/a0-a6,-(a7)
				ENDM

GETREGS			MACRO
				movem.l	(a7)+,d0-d7/a0-a6
				ENDM


WB				MACRO
\@bf:
				btst	#6,dmaconr(a6)
				bne.s	\@bf
				ENDM

WBa				MACRO
\@bf:
				move.w	#\2,$dff180

				btst	#6,$bfe001
				bne.s	\@bf
\@bz:

				move.w	#$f0f,$dff180

				btst	#6,$bfe001
				beq.s	\@bz

				ENDM

*Another version for when a6 <> dff000

WBSLOW			MACRO
\@bf:
				btst	#6,_custom+dmaconr
				bne.s	\@bf
				ENDM

WT				MACRO
\@bf:
				btst	#6,(a3)
				bne.s	\@bd
				rts
\@bd:
				btst	#4,(a0)
				beq.s	\@bf
				ENDM

WTNOT			MACRO
\@bf:
				btst	#6,(a3)
				bne.s	\@bd
				rts
\@bd:
				btst	#4,(a0)
				bne.s	\@bf
				ENDM

CINIT			MACRO	; \1 UCopList* \2 number of instructions to hold
				move.l	\1,a0
				move.l	#\2,d0 ; NOTE: Must be long despite waht documentation says
				jsr		_LVOUCopperListInit(a6)
				ENDM

CMOVE			MACRO ; \1 UCopList* \2 custom register \3 value
				lea		_custom+\2,a1
				move.l	a1,d0
				move.l	\1,a1
				move.l	\3,d1
				jsr		_LVOCMove(a6) ; is A1 scratch?
				move.l	\1,a1
				jsr		_LVOCBump(a6)
				ENDM

CWAIT			MACRO ; \1 UCopList* \2 vertical pos \3 horizontal pos
				move.l	\1,a1
				move.l	\2,d0
				move.l	\3,d1
				jsr		_LVOCWait(a6)
				move.l	\1,a1
				jsr		_LVOCBump(a6)
				ENDM

CEND			MACRO ; \1 UCopList*
				CWAIT \1,#10000,#255
				ENDM

CALLC			MACRO
				IFD BUILD_WITH_C
				xref _\1
				jsr _\1
				ELSE
				jsr \1
				ENDC
				ENDM

; Game macros

FREE_OBJ		MACRO
				move.w	#-1,ObjT_ZoneID_w(\1)
				ENDM

FREE_OBJ_2		MACRO
				move.w	#-1,ObjT_ZoneID_w+\2(\1)
				ENDM

FREE_ENT		MACRO
				move.w	#-1,ObjT_ZoneID_w(\1)
				move.w	#-1,EntT_ZoneID_w(\1)
				ENDM

FREE_ENT_2		MACRO
				move.w	#-1,ObjT_ZoneID_w+\2(\1)
				move.w	#-1,EntT_ZoneID_w+\2(\1)
				ENDM


; Set a bit in memory
SET_MEM_BIT		MACRO
				bset.b	#(\1&7),\2+3-(\1>>3)
				ENDM


				IFD BUILD_WITH_C

				; Begin a level
				; Trashes d0/a0

STATS_PLAY		MACRO
                CALLC   Game_LevelBegin
				ENDM

STATS_WON		MACRO
                CALLC   Game_LevelWon
				ENDM

				; Died
				; Trashes d0/a0
STATS_DIED		MACRO
                CALLC   Game_LevelFailed
				ENDM

				; Trashes a1
				; Expects EntT_Type_b in d0
STATS_KILL		MACRO
				move.l  #game_PlayerProgression+GStatT_AlienKills_vw,a1
				add.w   #1,(a1,d0.w*2)
				move.l	#1,Game_ProgressSignal_l
				SET_MEM_BIT	GAME_EVENTBIT_KILL,Game_ProgressSignal_l
				ENDM

				ELSE

				; At this time, there are no game progress for asm-only build

STATS_PLAY		MACRO
                ENDM

STATS_WON		MACRO
                ENDM

STATS_DIED		MACRO
                ENDM

STATS_KILL		MACRO
                ENDM

				ENDC

				; Macro for defining identifier labels that are both ASM and C accessible
DECLC			MACRO
_\1::
\1:
				ENDM
