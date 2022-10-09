;=========================================================
; 
; This chunky2planar routine was made by Ludde/Encore.
;
; You may uses it for whatever you want, but if you do
; it would be nice if you gave me credits if you release 
; anything! :)
;
; Send bug-reports, comments, optimise-tips, etc to:
;               
;     e-mail: ludvigp@ifi.uio.no       
;
;==========================================================

	IFD	_PHXASS_
	MACHINE	68030
	ENDIF

	incdir	"Include:"
	include	"Ludde/Startup_macros.i"
	include	"hardware/custom.i"

;------------------ Startup Options ------------------------

KillSystem
SaveInterrupts
NewCopperList

ScreenWidth		=	320
ScreenHeight		=	128
Bitplanes		=	8

ScreenSize		=	ScreenWidth*ScreenHeight
BitplaneSize		=	ScreenSize/8

;-----------------------------------------------------------

ChunkyWidth		=	160
ChunkyHeight		=	128

ChunkyPixels		=	ChunkyWidth*ChunkyHeight

;ClearChunkyBuffer

	Section	MainProgram,code

j:
	SaveSystem

	ClrINT	ALL
	ClrINTQ	ALL
	ClrDMA	ALL	

	jsr	SetupCopperList

	move.l	VectorBase,a0
	move.l	#Lev3InterruptHandler,$6c(a0)

	SetDMA	DMAF_MASTER!DMAF_RASTER!DMAF_COPPER!DMAF_BLITTER!DMAF_SPRITE
	SetINT	INTF_INTEN!INTF_VERTB

MainLoop:
	RastPos	s_Render_time
	bsr	Render
	RastPos	e_Render_time

                                        ;Different routines:
	jsr	c2p_2_Pass		;1 cpu pass   = c2p_1_pass
					;2 cpu passes = c2p_2_pass

	WaitMouse	MLeft,MainLoop

	RestoreSystem

	move.w	e_Render_time(pc),d0
	sub.w	s_Render_time(pc),d0		;Cpu c2p rastertime

	moveq	#0,d1
	move.w	e_c2p_time(pc),d1
	sub.w	s_c2p_time(pc),d1		;Cpu c2p rastertime

	move.l	TellFrames,d7
	muls.l	#50,d7
	divs.l	TellTicks,d7			;Average Frame Rate

	rts	

s_c2p_time:	dc.w	0
e_c2p_time:	dc.w	0
s_Render_time:	dc.w	0
e_Render_time:	dc.w	0
;-----------------------------------------------------RENDER

Render:

			; Here YOU do your stuff! :)
                        
	rts

;-----------------------------------------------------

	Section ChunkyStuff,data
	
;	blk.b	ChunkyPixels,"*"			;Safety!
ChunkyBuffer:
	blk.b	ChunkyPixels,50
;	blk.b	ChunkyPixels,"*"			;Safety!


;-----------------------------------------------------------------------------
	include	"src3:wws/Blitter_c2p.i"
	include	"Include:Ludde/Startup_code.i"











