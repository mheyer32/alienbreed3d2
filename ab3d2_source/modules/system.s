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

.clear_loop:
			move.l	d0,(a0)+
			move.l	d0,(a0)+
			move.l	d0,(a0)+
			move.l	d0,(a0)+
			dbra	d1,.clear_loop
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

				IFND BUILD_WITH_C
;******************************************************************************
;*
;* Initialise system dependencies
;*
;* return bool[d0]
;*
;******************************************************************************
Sys_Init:
				; Avoid requesters
				move.l		$4.w,a0
				move.l		ThisTask(a0),a0
				lea			pr_WindowPtr(a0),a0
				move.l		(a0),sys_OldWindowPtr
				move.l		#-1,(a0)

				bsr			sys_OpenLibs
				tst.l		d0
				beq.s		.fail

				bsr			sys_InitHardware
				tst.l		d0
				beq.s		.fail

				lea		VBLANKInt(pc),a1
				moveq	#INTB_VERTB,d0
				CALLEXEC AddIntServer

				IFEQ	CD32VER
				lea		KEYInt(pc),a1
				moveq	#INTB_PORTS,d0
				CALLEXEC AddIntServer
				ENDC

				bsr     Game_Init

				; All successful
				moveq		#1,d0
.fail:
				rts

;******************************************************************************
;*
;* Finalise dependencies
;*
;******************************************************************************
Sys_Done:
				lea		VBLANKInt,a1
				moveq	#INTB_VERTB,d0
				CALLEXEC RemIntServer

				IFEQ	CD32VER
				lea		KEYInt,a1
				moveq	#INTB_PORTS,d0
				CALLEXEC RemIntServer
				ENDC

				move.l	#MR_SERIALBITS,d0
				CALLMISC FreeMiscResource

				move.l	#MR_SERIALPORT,d0
				CALLMISC FreeMiscResource


				move.l	#sys_POTBITS,d0
				CALLPOTGO	FreePotBits

				bsr     Game_Done

				move.l	$4.w,a0
				move.l	ThisTask(a0),a0
				move.l	sys_OldWindowPtr,pr_WindowPtr(a0)

				; Display buffered error message (if any)
				bsr		Sys_DisplayError

				bra		sys_CloseLibs

;******************************************************************************
;*
;* Simple EClock Time
;*
;******************************************************************************
Sys_MarkTime:
				move.l	a6,-(sp)
				move.l	_TimerBase,a6
				jsr		_LVOReadEClock(a6)
				move.l	(sp)+,a6
				rts

;******************************************************************************
;*
;* Subtract two full timestamps, First pointed to by a0, second by a1.
;* Generally we don't care about the upper, but it's calculated in case we want
;* it.
;*
;* return uint64[d1:d0]
;*
;******************************************************************************
Sys_TimeDiff:
				move.l	d2,-(sp)
				move.l	(a1),d1
				move.l	4(a1),d0
				move.l	(a0),d2
				sub.l	4(a0),d0
				subx.l	d2,d1
				move.l	(sp)+,d2
				rts

;******************************************************************************
;*
;* Calculates the lap time for a frame, once per frame.
;* return uint64[d1:d0]
;*
;******************************************************************************
Sys_FrameLap:
				lea		Sys_FrameTimeECV_q,a0
				bsr 	Sys_MarkTime

				; Subtract previous ECV: We assume the difference is < 32 bits
				move.l	4(a0),d0
				sub.l	12(a0),d0

				; Put current ECV into previous ECV buffer for the next lap
				move.l	(a0),8(a0)
				move.l	4(a0),12(a0)

				; Calculate index of slot and insert the ECV difference
				lea 	Sys_FrameTimes_vl,a0
				move.l	Sys_FrameNumber_l,d1
				and.w	#7,d1
				move.l	d0,(a0,d1.w*4)

				; Update the frame number
				addq.l	#1,Sys_FrameNumber_l
				rts

;******************************************************************************
;*
;* Calculates the current FPS average over the last 8 lap times.
;*
;******************************************************************************
Sys_EvalFPS:
				lea		Sys_FrameTimes_vl,a0

				; Average the 8 ECV differences
				move.l	(a0)+,d0
				add.l	(a0)+,d0
				add.l	(a0)+,d0
				add.l	(a0)+,d0
				add.l	(a0)+,d0
				add.l	(a0)+,d0
				add.l	(a0)+,d0
				add.l	(a0)+,d0

				asr.l	#3,d0
				beq.s	.zero

				; Convert to MS
				mulu.l	Sys_ECVToMsFactor_l,d0
				clr.w	d0
				swap	d0
				beq.s	.zero

				; Calculate FPS
				move.l	#10000,d1
				divu.l	d0,d1				; frames per 10 seconds
				divu.w	#10,d1				; decimate, remainder contains 1/10th seconds
				swap	d1					;
				move.l	d1,Sys_FPSIntAvg_w	; Shove it out

.zero:
				rts

;******************************************************************************
;*
;* Temporary implementation until we have chunky buffer text printing
;*
;******************************************************************************
Sys_ShowFPS:
				movem.l		a2/a3/a6,-(sp)
				move.w		#0,.fps_Length_w
				lea			.fps_Template_vb,a0
				lea			Sys_FPSIntAvg_w,a1
				lea			.fps_PutChar(pc),a2
				lea			.fps_CharBuffer_vb,a3
				CALLEXEC	RawDoFmt

				move.l		Vid_MainScreen_l,a1
				lea			sc_RastPort(a1),a1
				move.l		#8,d1
				clr.l		d0
				CALLGRAF 	Move

				move.w		.fps_Length_w(pc),d0
				subq		#1,d0
				lea			.fps_CharBuffer_vb,a0
				jsr			_LVOText(a6)

				movem.l		(sp)+,a2/a3/a6
				rts

.fps_Template_vb:
				dc.b		"%2d.%d",0
.fps_CharBuffer_vb:
				ds.b		16

				align 2
.fps_Length_w:
				dc.w 		0	; tracks characters written by the following stuffer

.fps_PutChar:
				move.b		d0,(a3)+
				add.w		#1,.fps_Length_w
				rts



;******************************************************************************
;*
;* Clear Keyboard buffer
;*
;******************************************************************************
Sys_ClearKeyboard:
				move.l	#KeyMap_vb,a5
				moveq	#0,d0
				move.w	#15,d1
.loop:
				move.l	d0,(a5)+
				move.l	d0,(a5)+
				move.l	d0,(a5)+
				move.l	d0,(a5)+
				dbra	d1,.loop
				rts

;******************************************************************************
;*
;* Read Mouse State
;*
;******************************************************************************
Sys_ReadMouse:
				move.l	#$dff000,a6
				clr.l	d0
				clr.l	d1
				move.w	$a(a6),d0
				lsr.w	#8,d0
				ext.l	d0
				move.w	d0,d3
				move.w	.oldMouseY,d2
				sub.w	d2,d0
				cmp.w	#127,d0
				blt		.not_negative_y

				move.w	#255,d1
				sub.w	d0,d1
				move.w	d1,d0
				neg.w	d0

.not_negative_y:
				cmp.w	#-127,d0
				bge		.not_negative_y2

				move.w	#255,d1
				add.w	d0,d1
				move.w	d1,d0

.not_negative_y2:
				add.b	d0,d2
				move.w	d2,.oldMouseY
				add.w	d0,Sys_MouseY

				clr.l	d0
				clr.l	d1
				move.w	$a(a6),d0
				ext.w	d0
				ext.l	d0
				move.w	d0,d3
				move.w	.oldMouseX,d2
				sub.w	d2,d0
				cmp.w	#127,d0
				blt		.not_negative_x

				move.w	#255,d1
				sub.w	d0,d1
				move.w	d1,d0
				neg.w	d0

.not_negative_x:
				cmp.w	#-127,d0
				bge		.not_negative_x2

				move.w	#255,d1
				add.w	d0,d1
				move.w	d1,d0

.not_negative_x2:
				add.b	d0,d2
				move.w	d0,d1
				move.w	d2,.oldMouseX

				;FIXME: should use _LVOWritePotgo here
				move.w	#$0,_custom+potgo

				add.w	d0,.oldMouseX2
				move.w	.oldMouseX2,d0
				and.w	#2047,d0
				move.w	d0,.oldMouseX2

				asl.w	#2,d0
				sub.w	.prevX,d0
				add.w	d0,.prevX
				add.w	d0,angpos
				move.w	#0,lrs
				rts

; local mouse state
.oldMouseX2:	dc.w	0
.oldMouseX:		dc.w	0
.oldMouseY:		dc.w	0
.oldMouseY2:	dc.w	0
.prevX:			dc.w	0

sys_POTBITS		equ		%110000000000

;******************************************************************************
;*
;* Set up hardware and related options
;*
;* return bool[d0]
;*
;******************************************************************************
sys_InitHardware:
				; Processor
				; Check for 060 first
				move.l		4.w,a0
				btst.b		#AFB_68060,AttnFlags(a0) ; state of bit -> Z
				seq			Sys_CPU_68060_b
				seq			Sys_Move16_b
				seq			Vid_FullScreenTemp_b
				beq.s		.done_cpu

				; Now check for 040
				btst.b		#AFB_68040,AttnFlags(a0) ; state of bit -> Z
				seq			Sys_Move16_b
				seq			Vid_FullScreenTemp_b

.done_cpu:
				; Serial Port
				move.l		#MR_SERIALPORT,d0		; We want these bits
				lea.l		AppName(pc),a1
				CALLMISC	AllocMiscResource

				tst.l		d0
                bne.s	   	.fail

				move.l		#MR_SERIALBITS,d0
				lea.l		AppName(pc),a1
				CALLMISC	AllocMiscResource

			 	tst.l		d0
                bne.s   	.fail

				; now we have the resource, may poke the hardware bits
				move.w		#31,_custom+serper	; 19200 baud, 8 bits, no parity

				; Joystick
				move.l		#sys_POTBITS,d0	; We want these bits
				CALLPOTGO	AllocPotBits

				; Grab the EClockRate
				lea			Sys_PrevFrameTimeECV_q,a0
				bsr			Sys_MarkTime

				; Convert eclock rate to scale factor that we will first
				; multiply by, then divide by 65536
				move.l		#65536000,d1
				divu.l		d0,d1
				move.l		d1,Sys_ECVToMsFactor_l

				; success
				moveq.l		#1,d0
				rts
.fail:
				moveq.l		#0,d0
				rts

;******************************************************************************
;*
;* Open Libraries and Devices
;*
;* return bool[d0]
;*
;******************************************************************************
sys_OpenLibs:
				; DOS library
				lea.l		DosName,a1
				moveq		#0,d0
				CALLEXEC	OpenLibrary

				move.l		d0,_DOSBase
				beq			.fail

				; Graphics library
				lea.l		GraphicsName,a1
				moveq.l		#0,d0
				CALLEXEC	OpenLibrary

				move.l		d0,_GfxBase
				beq.s		.fail

				; Intuition Library
				moveq		#INTUITION_REV,d0		version
				lea.l		IntuitionName,a1
				CALLEXEC	OpenLibrary

				move.l		d0,_IntuitionBase
				beq.s		.fail

				; Misc Resource
				moveq.l		#0,d0
				lea.l		MiscResourceName,a1
				CALLEXEC 	OpenResource

				move.l		d0,_MiscResourceBase
                beq.s	   	.fail

				; Potgo Resource
				moveq.l		#0,d0
				lea.l		PotgoResourceName,a1
				CALLEXEC 	OpenResource

				move.l		d0,_PotgoResourceBase
				beq.s   	.fail

				; Timer Device
				lea			TimerName,a0
				lea			sys_TimerRequest,a1
				moveq		#0,d0
				moveq		#0,d1
				CALLEXEC 	OpenDevice

				move.l		sys_TimerRequest+IO_DEVICE,_TimerBase
				move.l		d0,sys_TimerFlag_l

				; indicate success
				moveq		#1,d0
.fail:
				rts

;******************************************************************************
;*
;* Close Libraries and Devices
;*
;******************************************************************************

CLOSELIB		macro
				move.l		\1,a1
				tst.l		a1
				beq.b		.skip\@
				CALLEXEC	CloseLibrary
				clr.l		\1
.skip\@:
				endm

sys_CloseLibs:
				; There's no CloseResource...

				lea			sys_TimerRequest,a1
				CALLEXEC	CloseDevice

				CLOSELIB	_IntuitionBase
				CLOSELIB	_GfxBase
				CLOSELIB	_DOSBase

				rts

;******************************************************************************
;*
;* Structures
;*
;******************************************************************************

; These can't be put into the data section due to the relocation type
				align 4
AppName:					dc.b	'TheKillingGrounds',0

; OS structures
				align 4
VBLANKInt:
				dc.l	0,0						;is_Node ln_Succ, ln_Pred
				dc.b	NT_INTERRUPT,9			;is_Node ln_Type; ln_Pri
				dc.l	AppName					;is_Node ln_Name
				dc.l	0						;is_Data
				dc.l	VBlankInterrupt			;is_Code

				align 4
KEYInt:
				dc.l	0,0						;is_Node ln_Succ, ln_Pred
				dc.b	NT_INTERRUPT,127		;is_Node ln_Type; ln_Pri
				dc.l	AppName					;is_Node ln_Name
				dc.l	0						;is_Data
				dc.l	key_interrupt			;is_Code

				ENDIF	; BUILD_WITH_C
