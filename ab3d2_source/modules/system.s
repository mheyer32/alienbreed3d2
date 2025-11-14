;
; *****************************************************************************
; *
; * modules/system.s
; *
; * system initialisation code
; *
; * Refactored from dev_inst.s, hires.s etc.
; *
; *****************************************************************************

				align	4

; dest  ULONG a0
; value ULONG d0
; size  WORD d1 (in longs)
_Sys_MemFillLong::
Sys_MemFillLong:
			lsr.w	#2,d1	; 4 longs per loop
			subq.w	#1,d1

.fill_loop:
			move.l	d0,(a0)+
			move.l	d0,(a0)+
			move.l	d0,(a0)+
			move.l	d0,(a0)+
			dbra	d1,.fill_loop
			rts

;******************************************************************************
;*
;* Copy using move16. Don't call this if you don't have an 040, 060 or the
;* amount of data to transfer is less than 64 bytes or greater than 4MiB as
;* there's no handling for that.
;*
;******************************************************************************
_Sys_CopyMemMove16:
Sys_CopyMemMove16:
				; round the source. Is this actually needed?
				exg			a0,d0
				add.l		#15,d0
				and.l		#$FFFFFFF0,d0
				exg			d0,a0

				; round the destination. Is this actually needed?
				exg			a1,d0
				add.l		#15,d0
				and.l		#$FFFFFFF0,d0
				exg			d0,a1

				lsr.l		#6,d0	; 4 cache lines of 16 bytes per loop
				subq.l		#1,d0

.copy_loop:
				move16		(a0)+,(a1)+
				move16		(a0)+,(a1)+
				move16		(a0)+,(a1)+
				move16		(a0)+,(a1)+
				dbra		d0,.copy_loop ; assume have less than 4MB
				rts

SYS_ALERT_Y_SPACE=12

; Prepare alert for later display, restore stack pointer and abort program.
; Input: a0 = format, a1 = arguments (for RawDoFmt).
; Warning: Can only be called from the main game loop (Game_Start and later)
_Sys_FatalError:: ; C callable version
				lea		4(sp),a1	; var args
				; Fall through
Sys_FatalError:
				; Prepare error message, but don't display it
				; until system has been almost completely shut down.
				lea		.putch(pc),a2
				lea		sys_ErrorBuffer_vb,a3
				move.b	#SYS_ALERT_Y_SPACE+2,sys_ErrorHeight_b
				bsr		.startline
				CALLEXEC RawDoFmt
				move.l	sys_RecoveryStack,a7
				bra		Game_Quit
.putch:
				tst.b	d0
				beq		.end
				cmp.b	#10,d0
				beq		.nl
				move.b	d0,(a3)+
				rts
.end:
				clr.w	(a3)		; NUL terminator and indicate last line
				rts
.nl:
				clr.b	(a3)+		; Terminate line
				move.b	#1,(a3)+	; Continue on next
				; And start a new one
.startline:
				move.w	#10,(a3)+	; X
				move.b	sys_ErrorHeight_b,(a3)+
				add.b	#SYS_ALERT_Y_SPACE,sys_ErrorHeight_b
				rts

; Show alert (if any) prepared by Sys_FatalError
_Sys_DisplayError::
Sys_DisplayError:
				moveq	#0,d1
				move.b	sys_ErrorHeight_b,d1
				beq		.out
.has_error:
				moveq	#RECOVERY_ALERT,d0
				lea		sys_ErrorBuffer_vb,a0
				CALLINT DisplayAlert
.out:
				rts

; Like exec/AllocVec, but calls Sys_FatalError on allocation failure
Sys_AllocVec:
				movem.l	d0-d1,-(sp) ; Save arguments
				CALLEXEC AllocVec
				tst.l	d0
				beq		.fail
				addq.l	#8,sp
				rts
.fail:
				lea		.errorfmt(pc),a0
				move.l	sp,a1
				bra		Sys_FatalError
.errorfmt:		dc.b	'Allocation failed. %ld bytes requested, flags=$%lx',0
				even
