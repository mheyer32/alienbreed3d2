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

;**************************************************************************************************
;*
;* Initialise system dependencies
;*
;**************************************************************************************************
Sys_Init:
				bsr			sys_OpenLibs
				tst.l		d0
				beq.s		.fail

				bsr			sys_InitHardware
				tst.l		d0
				beq.s		.fail

				; All successful
				moveq		#1,d0
.fail:
				rts

;**************************************************************************************************
;*
;* Finalise dependencies
;*
;**************************************************************************************************
Sys_Done:
				jsr			sys_CloseLibs
				rts

;**************************************************************************************************
;*
;* Simple EClock Time
;*
;**************************************************************************************************
Sys_Time:
				move.l	a6,-(sp)
				move.l	_TimerBase,a6
				jsr		_LVOReadEClock(a6)
				move.l	(sp)+,a6
				rts

;**************************************************************************************************
;*
;* Set up hardware and related options
;*
;**************************************************************************************************
sys_InitHardware:
				; Processor
				move.l		4.w,a0
				move.b		$129(a0),d0
				move.l		#68040,d1	;68040
				btst		#$03,d0
				beq.s		.not040

				; invert Vid_FullScreenTemp_b to start game in fullsreen if cpu is 68040 AL
				not.b		Sys_Move16_b ; We can use move16
				not.b		Vid_FullScreenTemp_b

.not040:
				; Serial Port
				move.l		#MR_SERIALPORT,d0		;We want these bits
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
				move.w		#31,_custom+serper			;19200 baud, 8 bits, no parity

				; Joystick
				move.l		#%110000000000,d0		;We want these bits
				CALLPOTGO	AllocPotBits

				; Grab the EClockRate
				lea		Sys_Workspace_vl,a0			; Don't care about recording the actual value
				bsr		Sys_Time

				; Convert eclock rate to scale factor that we will first multiply by, then divide by 65536
				move.l	#65536000,d1
				divu.l	d0,d1
				move.l	d1,sys_ECVToMsFactor_l

				; success
				moveq.l		#1,d0
				rts
.fail:
				moveq.l		#0,d0
				rts

;**************************************************************************************************
;*
;* Open Libraries and Devices
;*
;* @return d0:bool
;*
;**************************************************************************************************
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
                beq.s	   		.fail

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

;**************************************************************************************************
;*
;* Close Libraries and Devices
;*
;**************************************************************************************************

sys_CloseLibs:
				; There's no CloseResource...

				lea			sys_TimerRequest,a1
				CALLEXEC	CloseDevice

				move.l		_IntuitionBase,a1
				beq.s		.skip_close_intuition
				CALLEXEC	CloseLibrary

.skip_close_intuition:
				move.l		_GfxBase,a1
				beq.s		.skip_close_gfx
				CALLEXEC	CloseLibrary

.skip_close_gfx:
				move.l		_DOSBase,a1
				beq.s		.skip_close_dos
				CALLEXEC	CloseLibrary

.skip_close_dos:
				rts




; Subtract two full timestamps, First pointed to by a0, second by a1. Full return in d1 (upper) : d0(lower)
; Generally we don't care about the upper, but it's calculated in case we want it.
;Time_Diff:
;				move.l	d2,-(sp)
;				move.l	(a1),d1
;				move.l	4(a1),d0
;				move.l	(a0),d2
;				sub.l	4(a0),d0
;				subx.l	d2,d1
;				move.l	(sp)+,d2
;				rts
