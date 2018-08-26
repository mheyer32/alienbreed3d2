		section	Main,code
		jmp	main_startup

;settings
;main_programname:	MACRO	; Sets program name (Window..)
;				dc.b	'Program name'
;			ENDM
;			
;main_sysinfooff	; Don't show sysinfo
;main_reqinfooff	; Don't show requirements
;main_endinfooff	; Don't show end info
;main_debugoff		; disables debugger
;
;main_introcode:	MACRO	; Code to run after system startup
;main_endcode:		MACRO	; Code to run before system closedown
;
;main_skipsysinfo	; Skip system test
;main_cacheoff		; Disables caches (If existing)
;main_dostextoff	; Disables ALL dos output (Text)
;main_systemon		; Leaves system on no system disable
;main_vectortrap	=	%<Vectors to trap>	  <Default bits>
;	Vector bits:	9	=	Bus error		1
;			8	=	Address error		1
;			7	=	Illegal command		1
;			6	=	Division by zero	1
;			5	=	CHK command		1
;			4	=	TRAPV command		0
;			3	=	Privilege violation	0
;			2	=	Trace			0
;			1	=	Axxx command emulation	1
;			0	=	Fxxx command emulation	1
;main_trap7		; Use level 7 to exit
;main_reqproc		=	2	; Requiered processor 1=010 or greater
;main_reqfpu				; Set to require FPU
;main_reqmmu				; Set to require Extended Chip Set
;main_reqaga				; Set to require AGA chipset
;main_reqecs				; Set to require Extended Chip Set
;main_reqpal				; Set to require PAL video mode
;main_reqntsc				; Set to require NTSC video mode
;main_reqfast	=	4096		; How many KB Fast RAM that is needed
;main_reqchip	=	2048		; How many KB Chip RAM that is needed
;
;main_rgbfadeto		=	$0RGB	; Fade to colour at start (12 bit)
;main_rgbfadefrom	=	$0RGB	; Fade from colour at end (12 bit)
;main_faderoff		; Disable colour fade (At start and End)
;main_noexit		; Disable exit function until end
;main_usermb		; Call Debug with RMB
;main_uselmb		; Call debug with Left mouse button
;main_length		=	xxxx	; max run time.
;main_disableint		; Disable all interrupt stuff
;main_short		; Shortest startup
;main_meteroff		; Disables meter code (Saving memory)
;main_meteron		; Enables the frame meter
;main_playeroff		; Player off
;main_disabledos	; Disables DOS routines (Load,Execute)
;main_loader		; Use this switch when load proggy

********************************************************** Replayer settings **

		IFND	main_loader
		IFND	main_playeroff
		IFND	main_ownplayer

main_musicinit:	MACRO		; Command to start module (A0=Mod ptr)
		bsr	PPR_Init
		ENDM

main_musicplay:	MACRO		; Command to run every frame (CIA=None)
		move.w	#$8200,$dff096
		bsr	PPR_Music
		ENDM

main_musicstop:	MACRO		; Command to Stop Music
		bsr	PPR_End
		ENDM

PPR_68020	=	1
PPR_NotePlayer	=	0

		include	"demo:System/ProRunner.S"
		ENDIF
		ENDIF
		ENDIF
*******************************************************************************

;------------------------------------------------------------------ Defaults --
;----------------------------------------------- Main short --
	IFD	main_short
	IFND	main_sysinfooff	; Don't show sysinfo
main_sysinfooff	; Don't show sysinfo
	ENDIF
	IFND	main_disabledos	; Don't use dos functions
main_disabledos	; Don't use dos functions
	ENDIF
	IFND	main_meteroff	; Don't use meter
main_meteroff	; Don't use meter
	ENDIF
	IFND	main_reqinfooff	; Don't show requirements
main_reqinfooff	; Don't show requirements
	ENDIF
	IFND	main_endinfooff	; Don't show end info
main_endinfooff	; Don't show end info
	ENDIF
	IFND	main_debugoff	; disables debugger
main_debugoff	; disables debugger
	ENDIF
	IFND	main_dostextoff	; Disables ALL dos output (Text)
main_dostextoff	; Disables ALL dos output (Text)
	ENDIF
	IFND	main_disableint	; Disable all interrupt stuff
main_disableint	; Disable all interrupt stuff
	ENDIF
	IFND	main_playeroff	; Player off
main_playeroff	; Player off
	ENDIF
	IFND	main_faderoff	; Player off
main_faderoff	; fader off
	ENDIF
	IFND	main_skipsysinfo	; Skip system test
main_skipsysinfo	; Skip system test
	ENDIF
	ENDIF
;------------------------------------------- main_uselmb --
	IFND	main_uselmb
main_usermb
	ENDIF

;------------------------------------------- main_vectortrap --
	IFND	main_vectortrap
main_vectortrap		=	%1111100011
	ENDIF

;------------------------------------------ main_dostextoff --

	IFD	main_dostextoff	; Disables ALL dos output (Text)
	IFND	main_sysinfooff	; Don't show sysinfo
main_sysinfooff	; Don't show sysinfo
	ENDIF
	IFND	main_reqinfooff	; Don't show requirements
main_reqinfooff	; Don't show requirements
	ENDIF
	IFND	main_endinfooff	; Don't show end info
main_endinfooff	; Don't show end info
	ENDIF


	ENDIF
;----------------------------------------------------------- main_textvaron --
	IFND	main_debugoff
main_textvaron
	ENDIF

	IFD	main_debugoff
	IFND	main_dostextoff
main_textvaron
	ENDIF
	ENDIF
;-------------------------------------------------------- main_skipsysinfo --
	IFD	main_skipsysinfo
	IFND	main_sysinfooff	; Don't show sysinfo
main_sysinfooff	; Don't show sysinfo
	ENDIF
	IFND	main_reqinfooff	; Don't show requirements
main_reqinfooff	; Don't show requirements
	ENDIF
	ENDIF

	IFD	main_debugoff
	IFND	main_meteroff
main_meteroff
	ENDIF
	ENDIF
	


********************************************************************* Macros **

macro_sync:	MACRO	; Kills: d7 --			Macro_Sync
	IFND	main_meteroff
		movem.l	d0-a0,-(a7)
		move.l	main_dataptr,a0
		move.l	44(a0),a0
		jsr	(a0)
		move.l	main_dataptr,a0
		move.l	d0,48(a0)
	ENDIF
.waitsync\@:	move.l	$dff004,d7
		and.l	#$1ff00,d7
		cmp.l	#305*$100,d7
		bne.s	.waitsync\@
	IFND	main_meteroff
		move.l	main_dataptr,a0
		move.l	40(a0),a0
		jsr	(a0)
		movem.l	(a7)+,d0-a0
	ENDIF
	ENDM

macro_waitvbl:	MACRO	; Kills: d7 --			Macro_WaitVbl
.waitsync1\@:	move.l	$dff004,d7
		and.l	#$1ff00,d7
		cmp.l	#305*$100,d7
		bne.s	.waitsync1\@
.waitsync2\@:	move.l	$dff004,d7
		and.l	#$1ff00,d7
		cmp.l	#305*$100,d7
		beq.s	.waitsync2\@
	ENDM

************************************************************** START OF CODE **

	IFND	main_loader
main_startup:	
		IFND	main_short
		IFD	main_fakearg
		lea	.fakearg,a0
		move.l	a0,a1
		moveq.l	#0,d0
.countloop:	addq.l	#1,d0		
		tst.b	(a1)+
		bne.s	.countloop
		bra.s	.okletsgo
.fakearg:	main_fakearg
		dc.b	0
		even
.okletsgo:
		ENDIF
		ENDIF
		bra.w	main_sysinit
main_sysstartupok:;--------------------------------------- System startup ok --
	IFD	main_introcode
		main_introcode
	ENDIF
	IFND	main_skipsysinfo
		bsr.w	main_showsysinfo
		bsr.w	main_checkreq
		tst.w	main_ok2run
		bne.s	main_skipprog
	ENDIF
	IFND	main_systemon
	IFND	main_disableint
	IFD	main_length
		move.l	#main_length,main_timer
	ENDIF
	ENDIF
		bsr.w	main_disablesystem
	ENDIF
		move.l	a7,main_oldsp
	IFD	main_meteron
		bsr.w	main_framemeteron
	ENDIF
		jsr	main_start
	IFND	main_systemon
		move.l	main_dataptr,a0
		move.w	#13,56(a0)	; main_trappedvector
	ENDIF
		jmp	main_cont
main_exit:	
	IFND	main_systemon
		move.l	main_dataptr,a0
		move.w	#0,56(a0)	; main_trappedvector
	ENDIF
main_cont:		move.l	main_oldsp,a7
	IFD	main_meteron
		bsr.w	main_framemeteroff
	ENDIF
	IFND	main_systemon
		bsr.w	main_restoresystem
	ENDIF
*--------------------------------------------------------- Close down system --
main_skipprog:
	IFND	main_systemon
	IFND	main_endinfooff
	IFND	main_skipsysinfo
		bsr.w	main_exitmsg
	ENDIF
	ENDIF
	ENDIF
	IFD	main_endcode
		main_endcode
	ENDIF
main_dealloc:
	IFND	main_systemon
	IFND	main_debugoff
		move.l	$4,a6			; Exec base address
		move.l	main_configscr,d0	; Get address
		beq.s	.nodealloc		; Nothing allocated
		move.l	d0,a1			; Address ptr
		move.l	#20480+4096,d0		; Dealloc 1 bpl
		jsr	-210(a6)		; Exec FreeMem
.nodealloc:
		move.l	kbd_macroptr,d0
		beq.s	.nodealloc2
		move.l	d0,a1
		move.l	#16384,d0
		jsr	-210(a6)		; Exec FreeMem
.nodealloc2:
	ENDIF
	ENDIF		
main_closedos:	tst.b	main_conuse		; Was console window openend?
		beq.s	.noconsoleopen		; Not.
		move.l	main_dataptr,a6
		move.l	64(a6),d1	; main_conhandler,d1	; Get ConHandler
		move.l	60(a6),a6	; main_doshandler,a6 Get DosHandler
		jsr	-36(a6)			; Dos close file
.noconsoleopen:	move.l	$4,a6			; Exec lib handler
		move.l	main_dataptr,a1
		move.l	60(a1),a1	; main_doshandler,a1 Get dos handler
		jsr	-414(a6)		; Exec close lib
main_nodoslib:	rts
	ENDIF

*********************************************************** MAIN_LOADER CODE **
	IFD	main_loader
	
main_startup:	move.l	a7,main_oldsp
		bsr.w	dos_readaddy
		move.l	d0,a0
		bsr.w	main_setnewdata
		cmp.l	#'TBL.',main_idcode
		bne.w	main_noloader
		move.l	$4.w,a6			; Exec base
		tst.b	297(a6)			; Test processor flags
		beq.s	.novbr			; No vbr = 68000
		lea	main_getvbr,a5		; Ptr to supervisor routine
		jsr	-30(a6)			; Supervisor
.novbr:		lea	$dff000,a6
		move.w	#$0040,$9a(a6)		; Disable blitter intena
.w8blt:		btst	#6,$02(a6)
		bne.s	.w8blt
		move.w	#$0040,$96(a6)
.w8:		move.l	$04(a6),d0
		and.l	#$1ff00,d0
		cmp.l	#$100*305,d0
		bne.s	.w8
		move.w	#$7de0,$96(a6)
		move.l	main_exitaddy,main_oldexit	; Save old exit
		move.l	#main_exit,main_exitaddy
		clr.w	main_lock
		clr.l	main_returnvalue
		jsr	main_start
		move.l	#'OK!!',main_returnvalue
		bra.s	main_doit
main_exit:	st.b	main_lock
		move.l	#'EXIT',main_returnvalue
main_doit:	st.b	main_lock
		move.l	main_oldexit,main_exitaddy	; Restore old exit
		move.l	main_oldsp,a7
		lea	$dff000,a6
		clr.l	main_vblint
		clr.l	main_vblint2
		move.w	#$0040,$9a(a6)		; Disable blitter intena
.w8blt:		btst.b	#6,$02(a6)		
		bne.s	.w8blt
		move.w	#$0040,$96(a6)		; Disable BLT DMA
.w8:		move.l	$04(a6),d0
		and.l	#$1ff00,d0
		cmp.l	#$100*305,d0
		bne.s	.w8
		move.w	#$7de0,$96(a6)
;		move.w	#$0040,$9c(a6)
		move.w	#$8200!%1000000,$96(a6)		; Enable blitter DMA
		clr.l	main_bltint
		move.w	#$8008,$9a(a6)			; Enable timers and ports
		bsr.w	main_restoredata
main_noloader:	
		moveq.l	#0,d0
		rts

main_setnewdata:;in:	a0=Ptr to dosinfo block ptr
		move.l	a0,main_olddataptr
		move.l	(a0),a2			; a0=Start of data block
		move.l	a2,main_oldinfo
		lea	$dff000,a6
.w8:		move.l	$04(a6),d0
		and.l	#$1ff00,d0
		cmp.l	#$100*280,d0
		bne.s	.w8
		subq.l	#8,a2
		lea	main_datablockstart,a1
		move.w	#(main_datablockend-main_datablockstart)/4-1,d0
.loop:		move.l	(a2)+,(a1)+
		dbra	d0,.loop		
		move.l	#main_infoblock,(a0)	; Set new data ptr
		rts

main_restoredata:
		move.l	main_olddataptr,a0
		move.l	main_oldinfo,a2
		lea	$dff000,a6
.w8:		move.l	$04(a6),d0
		and.l	#$1ff00,d0
		cmp.l	#$100*280,d0
		bne.s	.w8
		move.l	a2,a3
		subq.l	#8,a2
		lea	main_datablockstart,a1
		move.w	#(main_datablockend-main_datablockstart)/4-1,d0
.loop:		move.l	(a1)+,(a2)+
		dbra	d0,.loop		
		move.l	a3,(a0)	; Set new data ptr
		rts

main_oldinfo:	dc.l	0
main_oldexit:	dc.l	0

main_olddataptr:dc.l	0			; Old data ptr

	ENDIF
	
************************************************ Main_Loader & Main Code+DATA **


main_getvbr:	dc.l	$4e7a0801	;movec vbr,d0
		move.l	d0,main_vbrbase
		rte

	IFND	main_systemon

	IFND	main_disabledos

*************************************************************************
* Non OS loading and executing routines 				*
*************************************************************************

dos_load:	;in:	a0=Ptr to file name,a1=Ptr to address
		;	d0=Length
		clr.w	dos_error
		st.b	main_lock
		move.l	d0,.savel
		move.w	#$8200!%1000000,$dff096	; Enable blitter DMA
		move.w	#$8008,$dff09a		; Enable Ports Interrupt
		move.l	main_doshandler,a6
		move.l	#1005,d2
		move.l	a1,.oldd1
		move.l	a0,d1		
		jsr	-30(a6)			; Open file
		tst.l	d0
		beq.s	.error
		move.l	.oldd1,d2
		move.l	d0,.oldd1
		move.l	d0,d1
		move.l	.savel,d3
		jsr	-42(a6)			; Read
		tst.l	d0
		beq.s	.error
		move.l	.oldd1,d1
		jsr	-36(a6)
		lea	$dff000,a6
		tst.b	$02(a6)
.wblit:		btst	#6,$02(a6)
		bne.s	.wblit
.w8:		move.l	$04(a6),d0
		and.l	#$1ff00,d0
		cmp.l	#$100*307,d0
		bne.s	.w8
		move.w	#%1000000,$96(a6)
		move.w	#$0008,$9a(a6)
		clr.w	main_lock
		rts
.oldd1:		dc.l	0
.savel:		dc.l	0		
.error:		st.b	dos_error
		move.w	#15,main_trappedvector
		move.l	dos_exitaddy,a0
		clr.w	 main_lock
		jmp	(a0)

dos_execute:	;in:	a0=Ptr to filename
		clr.w	dos_error
		st.b	main_lock
		move.w	#$0040,$dff09c		; Clear Req bits
		move.w	#$8200!%1000000,$dff096	; Enable blitter DMA
		move.w	#$8008,$dff09a		; Enable Ports Interrupt
		move.l	main_doshandler,a6	; Get dos handler
		moveq.l	#0,d2			; STD In=0
		move.l	main_conhandler,d3 	; STD Out=0
		move.l	a0,d1			; File Name Ptr
		move.l	#main_dataptr,d0
		bsr.w	dos_writeaddy
		jsr	-222(a6)		; DOS execute
		lea	$dff000,a6
		tst.b	$02(a6)
.wblit:		btst	#6,$02(a6)
		bne.s	.wblit
.w8:		move.l	$04(a6),d0
		and.l	#$1ff00,d0
		cmp.l	#$100*307,d0
		bne.s	.w8
		move.w	#$7de0,$96(a6)
		move.w	#$0008,$9a(a6)
		clr.w	main_lock
		cmp.l	#'EXIT',main_returnvalue
		beq.w	.exit
		cmp.l	#'OK!!',main_returnvalue
		bne.s	.error
		clr.l	main_returnvalue
		rts
.error:		st.b	dos_error
		move.w	#15,main_trappedvector
.exit:		move.l	dos_exitaddy,a0
		jmp	(a0)
dos_exitcp:	rts

dos_exitaddy:	dc.l	dos_exitcp
dos_error:	dc.w	0

dos_writeaddy:;	in:	d0=addy
		move.w	#$e000,$dff106
		move.b	d0,$dff181
		lsr.l	#8,d0
		move.b	d0,$dff183
		lsr.l	#8,d0
		move.b	d0,$dff185
		lsr.l	#8,d0
		move.b	d0,$dff187
		rts

dos_readaddy:;	out:	d0=addy
		move.w	#$0100,$dff104
		move.w	#$e000,$dff106
		move.b	$dff187,d0
		lsl.l	#8,d0
		move.b	$dff185,d0
		lsl.l	#8,d0
		move.b	$dff183,d0
		lsl.l	#8,d0
		move.b	$dff181,d0
		move.w	#$0000,$dff104
		rts
	ENDIF	; main_disabledos


	ENDIF	; main_systemon

main_dataptr:	dc.l	main_infoblock		; Ptr to info block
				; NEVER CHANGE ANY POSITIONS IN DATA FROM HERE.
main_datablockstart:
main_returnvalue:dc.l	0	;-8		; Return value
main_idcode:	dc.l	'TBL.'	;-4		; TBL id code
main_infoblock:	;------------------------- Info block - (External data ptrs) --
main_counter:	dc.l	0	;0		; Main counter (Up 1/VBL)
counter:	dc.l	0	;4		; Counter (Up 1/VBL)
timer:		dc.l	0	;8		; Timer (Down 1/VBL)
main_timer:	dc.l	0	;12		; Main timer
main_vblint:	dc.l	0	;16		; Custom VBL int ptr
main_vblint2:	dc.l	0	;20		; Custom VBL int ptr
main_bltint:	dc.l	0	;24		; Custom BLT int ptr
main_copint:	dc.l	0	;28		; Custom COP int ptr
main_module:	dc.l	-1	;32		; Module ptr
main_lock:	dc.w	0,0	;36		; 0=Ok 2 exit,Other NOT ok.
	IFND	main_loader
main_stimerptr:	dc.l	main_starttimer ;40	; Code ptr for start timer
main_gtimerptr:	dc.l	main_gettimer	;44	; Code ptr for get timer
	ENDIF
	IFD	main_loader
main_stimerptr:	dc.l	0	 ;40	; Code ptr for start timer
main_gtimerptr:	dc.l	0	;44	; Code ptr for get timer
	ENDIF
main_framespeed:dc.l	0	; 48		; Frames speed		
main_exitaddy:	dc.l	main_exit ; 52
main_trappedvector:dc.w	0,0	; 56		; #of trapped vector
main_doshandler:dc.l	0	; 60		; Dos handler
main_conhandler:dc.l	0	; 64		; Console handler
main_datablockend:
;				 TO HERE !!! IF SO SYSTEM CRASHES WILL APPEND.

main_vbrbase:	dc.l	0			; VBR Base
main_oldsp:	dc.l	0			; Saved SP (For exit)

********************************************************************************


	IFND	main_loader

main_starttimer:move.l	main_dataptr,a0
		move.l	(a0),main_savecount
		move.l	$dff004,main_savecount2
		rts

main_gettimer:	move.l	main_dataptr,a0
		move.l	(a0),d0
		move.l	$dff004,d1
		move.l	main_savecount,d2
		move.l	main_savecount2,d3
		and.l	#$1ffff,d1
		and.l	#$1ffff,d3
		sub.l	d3,d1		
		sub.l	d2,d0
		mulu	#313,d0
		lsl.l	#8,d0
		add.l	d1,d0
		lsr.l	#1,d0
		move.l	d0,main_timer2
		rts

*************************************************************************
* OS related routines 							*
*************************************************************************

main_sysinit:	move.l	a7,main_errsp		; Error sp
		move.l	#main_nodoslib,main_erraddy;Error addy
		tst.b	(a0)
		bne.s	.noclistart
		st.b	.clistartflag
.noclistart:
	IFND	main_short
		tst.w	d0
		beq.s	.skippa
		move.l	a0,main_argv		; Save arguments
		clr.b	-1(a0,d0.w)
		bsr.w	main_getargs
	ENDIF
.skippa:	lea	main_doslibname,a1	; Ptr to "dos.library\0"
		move.l	$4,a6			; Exec lib handler
		jsr	-408(a6)		; Exec Open lib "dos.library"
		tst.l	d0			; 0=Error
		beq.w	main_error		; Handle error
		move.l	main_dataptr,a0
		move.l	d0,60(a0)	; main_doshandler Save dos handler
		tst.w	.clistartflag
		beq.s	.clistart
		move.l	#main_closedos,main_erraddy; Error addy
		move.l	#main_consolname,d1	; Window name (Consol)
		move.l	#$3ed,d2		; Open mode (New)
		move.l	main_dataptr,a6
		move.l	60(a6),a6		; main_doshandler,a6 Get dos handler
		jsr	-30(a6)			; Dos open file 
		tst.l	d0			; Error ? =0
		beq.s	.otherstart		; No con openend
		st.b	main_printok		; Set print & con flag
		st.b	main_conuse
		move.l	main_dataptr,a0
		move.l	d0,64(a0)	; main_conhandler	; Con handler=Outp Handler
		bra.w	.otherstart		; Skip Cli start
.clistart:	move.l	main_dataptr,a6
		move.l	60(a6),a6		; main_doshandler,a6 Get doshandler
		jsr	-60(a6)			; Dos get current output
		tst.l	d0			; Error ?
		beq.s	.otherstart		; Yes don't set flags
		not.b	main_printok		; Set print flag
		move.l	main_dataptr,a0
		move.l	d0,64(a0)		; main_conhandler	; Output handler
.otherstart:	
	IFND	main_skipsysinfo
		bsr.w	main_sysinfo		; Get system info
	ENDIF
		move.l	#main_dealloc,main_erraddy;Error addy
	IFND	main_debugoff
	IFND	main_systemon
		move.l	$4.w,a6			; Exec base address
		move.l	#16384,d0		; Reserve one bpl
		moveq.l	#0,d1			; must be in chipram
		bset	#16,d1
		jsr	-198(a6)		; Exec allocmem


		move.l	d0,kbd_macroptr
		move.l	#20480+4096,d0		; Reserve one bpl
		moveq.l	#2,d1			; must be in chipram
		jsr	-198(a6)		; Exec allocmem
		move.l	d0,main_configscr	; Save adress
		tst.l	d0
		beq.s	.skippascr
		lea	main_conbplptrs+2,a0	; Ptr to bplptrs
		move.w	d0,4(a0)		; Set ...
		swap.w	d0			; .. bpl..
		move.w	d0,(a0)			; ..ptrs
		swap.w	d0			; Clear...
		move.l	d0,a0			
		add.l	#20480,d0		; Ptr to null sprite
		lea	main_consprptr+2,a1
		move.l	d0,d1
		add.l	#44+8,d1
		swap.w	d1
		move.w	d1,(a1)
		swap.w	d1
		move.w	d1,4(a1)
		addq.l	#8,a1
		moveq.l	#6,d1
.sprloop:	tst.w	d1
		bne.s	.skipspr
		addq.l	#8,d0
.skipspr:	swap.w	d0
		move.w	d0,(a1)
		swap.w	d0
		move.w	d0,4(a1)
		addq.l	#8,a1
		dbra	d1,.sprloop
		move.l	d0,main_mousesprptr
		move.l	d0,a2
		lea	main_mousesprite,a1
		moveq.l	#2*44/4-1,d0
.copysprloop:	move.l	(a1)+,(a2)+
		dbra	d0,.copysprloop
		moveq.l	#0,d0
		move.w	#(20480+8)/4-1,d1
.clrbloop:	move.l	d0,(a0)+
		dbra	d1,.clrbloop		;..screen
.skippascr:
	ENDIF
	ENDIF
		bra.w	main_sysstartupok
.clistartflag:	dc.w	0


	IFND	main_short
main_print:	;a0=ptr to text (0 to end)
		movem.l	d0-a6,-(a7)
	IFND	main_dostextoff
		tst.b	main_printok		; Ok to print ?
		beq.s	.skip			; Nope...
		moveq.l	#0,d3			; Calc..
		move.l	a0,a1
.calcloop:	tst.b	(a1)+
		beq.s	.calcok
		addq.l	#1,d3
		bra.s	.calcloop		;..str length
.calcok:	tst.l	d3			; Length 0 ?
		beq.s	.skip			; Nothing to print
		move.l	a0,d2			: Buffer ptr
		move.l	main_dataptr,a0
		move.l	64(a0),d1		; main_conhandler,d1	; Get File handler
		move.l	main_dataptr,a6
		move.l	60(a6),a6	; main_doshandler,a6	; Get dos handler
		jsr	-48(a6)			; Dos write file
.skip:
	ENDIF
		movem.l	(a7)+,d0-a6
		rts
	ENDIF

main_error:	move.l	main_erraddy,a0
		move.l	main_errsp,a7
		jmp	(a0)




	IFND	main_short
main_getargs:	moveq.l	#0,d6
		lea	main_arglist,a3
		moveq.l	#15,d7
.loop:		bsr.w	.getarg
		tst.l	d0
		beq.s	.exit
		move.l	a1,(a3)+
		addq.l	#1,d6
		dbra	d7,.loop
.exit:		move.l	d6,main_argcount
		rts
.getarg:
.findloop:	move.b	(a0)+,d0
		beq.s	.rts
		cmp.b	#32,d0
		bls.s	.findloop
		cmp.b	#"'",d0
		beq.s	.quote
		cmp.b	#"`",d0
		beq.s	.quote
		cmp.b	#'"',d0
		beq.s	.quote
		move.l	a0,a1
		subq.l	#1,a1			; a1=Ptr
.noquote:	cmp.b	#32,(a0)+
		bhi.s	.noquote
		tst.b	-1(a0)
		beq.s	.lastarg
		clr.b	-1(a0)
		moveq.l	#-1,d0
		rts
.quote:		move.l	a0,a1			; a1=Ptr
.findq:		move.b	(a0)+,d0
		cmp.b	#32,d0
		blo.s	.exitq
		cmp.b	#"'",d0
		beq.s	.exitq
		cmp.b	#"`",d0
		beq.s	.exitq
		cmp.b	#'"',d0
		bne.s	.findq
.exitq:		tst.b	-1(a0)
		beq.s	.lastarg
		clr.b	-1(a0)
		moveq.l	#-1,d0
		rts
.lastarg:	clr.b	(a0)			; Last arg
		moveq.l	#-1,d0
		rts
.rts:		moveq.l	#0,d0			; d0=0 ==> No more args
		rts


main_copymem:	;a0=Source
		;a1=Dest
		;d0=Size in bytes
		divu	#11*8,d0	; d0=Size/12*8
		beq.s	.skiplong
		subq.w	#1,d0
		moveq.l	#11*4,d1
		sub.l	d1,a1
.longloop:	REPT	2
		movem.l	(a0)+,d2-d7/a2-a6
		add.l	d1,a1
		movem.l	d2-d7/a2-a6,(a1)
		ENDR
		dbra	d0,.longloop
		add.l	d1,a1
.skiplong:	clr.w	d0
		swap.w	d0		
		divu	#4,d0
		beq.s	.skiplongword
		subq.w	#1,d0
.longwordloop:	move.l	(a0)+,(a1)+
		dbra	d0,.longwordloop
.skiplongword:	swap.w	d0
		tst.w	d0
		beq.s	.skipbytes
		subq.w	#1,d0
.byteloop:	move.b	(a0)+,(a1)+
		dbra	d0,.byteloop
.skipbytes:	rts

	ENDIF




	IFND	main_skipsysinfo
main_sysinfo:	
;----------------------------------------------- Get processors --
		move.l	$4,a6			; Exec base
		move.b	531(a6),d0
		move.b	d0,main_powerfreq+1
		cmp.b	#50,d0
		beq.w	.powok
	IFD	main_textvaron
		move.l	#main_txtpow60,main_powptr
	ENDIF
.powok:		move.w	296(a6),d0		; Get system flags
		btst	#0,d0			; 010?
		beq.s	.no010			; Nope
		move.w	#1,main_processor	; Yepp write proc number
	IFD	main_textvaron
		move.l	#main_txt68010,main_procptr ; Set text ptr
	ENDIF
.no010:		btst	#1,d0			; 020?
		beq.s	.no020			; Nope
		move.w	#2,main_processor	; Yepp write proc number
	IFD	main_textvaron
		move.l	#main_txt68020,main_procptr ; Set text ptr
	ENDIF
.no020:		btst	#2,d0			; 030?
		beq.s	.no030			; Nope
		move.w	#3,main_processor	; Yepp write proc number
	IFD	main_textvaron
		move.l	#main_txt68030,main_procptr ; Set text ptr
	ENDIF
.no030:		btst	#4,d0			; 881?
		beq.s	.no881			; Nope
		move.w	#1,main_coproc		; Yepp write coproc number
	IFD	main_textvaron
		move.l	#main_txt68881,main_coprocptr ; Set text ptr
	ENDIF
.no881:		btst	#5,d0			; 882?
		beq.s	.no882			; Nope
		move.w	#1,main_coproc		; Yepp write coproc number
	IFD	main_textvaron
		move.l	#main_txt68882,main_coprocptr ; Set text ptr
	ENDIF
.no882:		btst	#3,d0			; 040?
		beq.s	.no040			; Nope
		move.w	#4,main_processor	; Yepp write proc number
	IFD	main_textvaron
		move.l	#main_txt68040,main_procptr ; Set text ptr
	ENDIF
		move.w	#1,main_coproc		; 040 built in
	IFD	main_textvaron
		move.l	#main_txt68040b,main_coprocptr ; Set text ptr
	ENDIF
.no040:		btst	#7,d0			; 060?
		beq.s	.no060			; Nope
		move.w	#6,main_processor	; Yepp write proc number
	IFD	main_textvaron
		move.l	#main_txt68060,main_procptr ; Set text ptr
	ENDIF
		move.w	#1,main_coproc		; 060 built in
	IFD	main_textvaron
		move.l	#main_txt68060b,main_coprocptr ; Set text ptr
	ENDIF
.no060:		btst	#6,d0			; 851?
		beq.s	.no851			; Nope
		move.w	#1,main_mmu		; Yepp write mmu
	IFD	main_textvaron
		move.l	#main_txt68851,main_mmuptr ; Set text ptr
	ENDIF
.no851:;------------------------------------------------------- Get gfx chip --
		lea	$dff07d,a0		; LisaID
		move.b	(a0),d0
		move.b	d0,d1
		moveq.l	#63,d2
.gfxloop:	and.b	(a0),d1
		dbra	d2,.gfxloop
		cmp.b	d1,d0
		bne.s	.orgdenise
		btst	#1,d0
		bne.s	.noecs
		move.w	#1,main_ecs
	IFD	main_textvaron
		move.l	#main_txtgfxecs,main_gfxptr
	ENDIF
.noecs:		btst	#2,d0
		bne.s	.noaga
		move.w	#1,main_aga
	IFD	main_textvaron
		move.l	#main_txtgfxaga,main_gfxptr
	ENDIF
.noaga:
.orgdenise:	move.l	$4,a0
		move.b	530(a0),d0
		move.b	d0,main_refresh+1
		cmp.b	#50,d0
		beq.w	.refok
	IFD	main_textvaron
		move.l	#main_txtvbl60,main_refreshptr
	ENDIF
.refok:;--------------------------------------------------------- Get memory --
		move.l	$4,a6				; Exec base
		move.l	62(a6),main_chipmem


		moveq.l	#4,d1
		bset	#19,d1
		jsr	-216(a6)
	move.l	d0,d6
	bra.s	.okmem
		move.l	d0,-(a7)			; Save mem
		moveq.l	#0,d1
		moveq.l	#16,d0
		jsr	-198(a6)
		tst.l	d0
		beq.s	.dotest
		move.l	d0,-(a7)
		moveq.l	#4,d1
		bset	#19,d1
		jsr	-216(a6)
		move.l	(a7)+,a1
		move.l	d0,-(a7)
		moveq.l	#16,d0
		jsr	-210(a6)
		move.l	(a7)+,d0
		move.l	(a7)+,d1
		bne.s	.dotest
		moveq.l	#4,d1
		bset	#19,d1
		jsr	-216(a6)
		move.l	d0,d6
		bra.s	.okmem
.dotest:	sub.l	a1,a1
		moveq.l	#31,d7				; Number of banks
		moveq.l	#0,d6				; Fast mem found
		move.l	#512*1024,d5			; Bank size
.findloop:	movem.l	d5-a1,-(a7)
		jsr	-534(a6)
		movem.l	(a7)+,d5-a1
		btst	#0,d0				; Is it fast mem ?
		beq.s	.memskip
		add.l	d5,d6
.memskip:	add.l	d5,a1
		dbra	d7,.findloop
.okmem:		move.l	d6,main_fastmem	
		moveq.l	#0,d0
		moveq.l	#2,d1
		bset	#17,d1
		jsr	-216(a6)
		move.l	d0,main_availchip
		moveq.l	#0,d0
		moveq.l	#4,d1
		bset	#17,d1
		jsr	-216(a6)
		move.l	d0,main_availfast
		rts
	ENDIF

	IFND	main_skipsysinfo
main_showsysinfo:
	IFND	main_sysinfooff
		lea	main_txthi,a0
		bsr.w	main_print
		lea	main_txtpower,a0
		bsr.w	main_print
		move.l	main_powptr,a0
		bsr.w	main_print
		lea	main_txtproc,a0
		bsr.w	main_print
		move.l	main_procptr,a0
		bsr.w	main_print
		lea	main_txtcoproc,a0
		bsr.w	main_print
		move.l	main_coprocptr,a0
		bsr.w	main_print
		lea	main_txtmmu,a0
		bsr.w	main_print
		move.l	main_mmuptr,a0
		bsr.w	main_print
		lea	main_txtaga,a0
		bsr.w	main_print
		move.l	main_gfxptr,a0
		bsr.w	main_print
		lea	main_txtvbl,a0
		bsr.w	main_print
		move.l	main_refreshptr,a0
		bsr.w	main_print
		lea	main_txtmemchip,a0
		bsr.w	main_print
		move.l	main_chipmem,d0
		lsr.l	#8,d0
		lsr.l	#2,d0
		bsr.w	main_printdec
		lea	main_txtmemfast,a0
		bsr.w	main_print
		move.l	main_fastmem,d0
		lsr.l	#8,d0
		lsr.l	#2,d0
		bsr.w	main_printdec
		lea	main_txtkblf,a0
		bsr.w	main_print
	ENDIF
		rts		
	ENDIF

	IFND	main_skipsysinfo
main_checkreq:	moveq.l	#0,d7			; Nothing checked
		moveq.l	#0,d6			; 0 If passed
	IFND	main_reqinfooff
		lea	main_txtreq,a0
		bsr.w	main_print
	ENDIF
	IFD	main_reqproc
	IFND	main_reqinfooff
		lea	main_txtproc,a0
		bsr.w	main_print
	ENDIF
		move.w	#main_reqproc,d0
		mulu	#6,d0
		add.l	#main_txt68000,d0
		move.l	d0,a0
	IFND	main_reqinfooff
		bsr.w	main_print
		lea	main_txtplus,a0
		bsr.w	main_print
	ENDIF
		lea	main_txtpassed,a0
		cmp.w	#main_reqproc,main_processor
		bge.s	.ok00
		moveq.l	#-1,d6		
		lea	main_txtfault,a0
.ok00:
	IFND	main_reqinfooff
		bsr.w	main_print
	ENDIF
		moveq.l	#1,d7
	ENDIF

	IFD	main_reqfpu
	IFND	main_reqinfooff
		lea	main_txtcoproc,a0
		bsr.w	main_print
	ENDIF
		lea	main_txtpassed,a0
		tst.w	main_coproc
		bne.s	.ok01
		moveq.l	#-1,d6		
		lea	main_txtfault,a0
.ok01:	
	IFND	main_reqinfooff
		bsr.w	main_print
	ENDIF
		moveq.l	#1,d7
	ENDIF
	IFD	main_reqfpu
	IFND	main_reqinfooff
		lea	main_txtmmu,a0
		bsr.w	main_print
	ENDIF
		lea	main_txtpassed,a0
		tst.w	main_mmu
		bne.s	.ok02
		moveq.l	#-1,d6		
		lea	main_txtfault,a0
.ok02:	
	IFND	main_reqinfooff
		bsr.w	main_print
	ENDIF
		moveq.l	#1,d7
	ENDIF

;MEM


	IFD	main_reqfast
	IFND	main_reqinfooff
		lea	main_txtfast,a0
		bsr.w	main_print
		move.l	#main_reqfast,d0
		bsr.w	main_printdec
		lea	main_txtkb,a0
		bsr.w	main_print
	ENDIF
		lea	main_txtpassed,a0
		cmp.l	#main_reqfast*1024,main_availfast
		bhs.s	.ok00a
		moveq.l	#-1,d6		
		lea	main_txtfault,a0
.ok00a:
	IFND	main_reqinfooff
		bsr.w	main_print
	ENDIF
		moveq.l	#1,d7
	ENDIF

	IFD	main_reqchip
	IFND	main_reqinfooff
		lea	main_txtchip,a0
		bsr.w	main_print
		move.l	#main_reqchip,d0
		bsr.w	main_printdec
		lea	main_txtkb,a0
		bsr.w	main_print
	ENDIF
		lea	main_txtpassed,a0
		cmp.l	#main_reqchip*1024,main_availchip
		bhs.s	.ok00b
		moveq.l	#-1,d6		
		lea	main_txtfault,a0
.ok00b:
	IFND	main_reqinfooff
		bsr.w	main_print
	ENDIF
		moveq.l	#1,d7
	ENDIF


	IFD	main_reqaga
	IFND	main_reqinfooff
		lea	main_txtaga,a0
		bsr.w	main_print
		lea	main_txtagaplus,a0
		bsr.w	main_print
	ENDIF
		lea	main_txtpassed,a0
		tst.w	main_aga
		bne.s	.ok03
		moveq.l	#-1,d6		
		lea	main_txtfault,a0
.ok03:	
	IFND	main_reqinfooff
		bsr.w	main_print
	ENDIF
		moveq.l	#1,d7
	ENDIF
	IFD	main_reqecs
	IFND	main_reqaga
	IFND	main_reqinfooff
		lea	main_txtaga,a0
		bsr.w	main_print
		lea	main_txtecsplus,a0
		bsr.w	main_print
	ENDIF
		lea	main_txtpassed,a0
		tst.w	main_ecs
		bne.s	.ok04
		moveq.l	#-1,d6		
		lea	main_txtfault,a0
.ok04:
	IFND	main_reqinfooff
		bsr.w	main_print
	ENDIF
		moveq.l	#1,d7
	ENDIF
	ENDIF
	IFD	main_reqpal
	IFND	main_reqinfooff
		lea	main_txtvbl,a0
		bsr.w	main_print
		lea	main_txtvbl50,a0
		bsr.w	main_print
	ENDIF
		lea	main_txtpassed,a0
		cmp.w	#50,main_refresh
		beq.s	.ok05
		moveq.l	#-1,d6		
		lea	main_txtfault,a0
.ok05:
	IFND	main_reqinfooff
		bsr.w	main_print
	ENDIF
		moveq.l	#1,d7
	ENDIF
	IFD	main_reqntsc
	IFND	main_reqpal
	IFND	main_reqinfooff
		lea	main_txtvbl,a0
		bsr.w	main_print
		lea	main_txtvbl60,a0
		bsr.w	main_print
	ENDIF
		lea	main_txtpassed,a0
		cmp.w	#60,main_refresh
		beq.s	.ok06
		moveq.l	#-1,d6		
		lea	main_txtfault,a0
.ok06:
	IFND	main_reqinfooff
		bsr.w	main_print
	ENDIF
		moveq.l	#1,d7
	ENDIF
	ENDIF

		tst.l	d7
		bne.s	.skip
	IFND	main_reqinfooff
		lea	main_txtnoreq,a0
		bsr.w	main_print
	ENDIF
		rts
		

.skip:	
	IFD	main_textvaron
		lea	main_txtreqpass,a0
	ENDIF
		tst.w	d6
		beq.s	.ok
	IFD	main_textvaron
		lea	main_txtreqfault,a0
	ENDIF
	IFND	main_systemon
		move.l	main_dataptr,a1
		move.w	#11,56(a1)	; main_trappedvector
	ENDIF
.ok:		move.w	d6,main_ok2run

	IFND	main_reqinfooff
		bsr.w	main_print
	IFD	main_systemon
		lea	main_txtblank,a0
		bsr.w	main_print

	ENDIF
	ENDIF
		rts
	ENDIF

	IFND	main_short		
main_printdec:	;in:	d0=Number
	IFND	main_dostextoff
		lea	main_txtdec,a0
		move.l	a0,a1
		move.l	a1,a2
		moveq.l	#0,d1
.loop:		divu	#10,d0
		swap.w	d0
		add.b	#48,d0
		addq.l	#1,d1
		move.b	d0,(a2)+
		clr.w	d0
		swap.w	d0
		tst.l	d0
		bne.s	.loop
.ok:		move.b	#0,(a2)
		asr.w	#1,d1
		tst.w	d1
		beq.s	.skipp
		subq.w	#1,d1
.sloop:		move.b	(a1),d0
		move.b	-(a2),(a1)+
		move.b	d0,(a2)
		dbra	d1,.sloop
.skipp:	
		bra.w	main_print
	ENDIF
		rts
	ENDIF

main_turncacheoff:
		dc.l	$4e7a1002	;movec cacr,d1
		move.l	d1,main_cachereg
		rte

main_turncacheon:
		move.l	main_cachereg,d0
		dc.l	$4e7b0002	;movec d0,cacr
		rte

	IFND	main_systemon 		; End almost at ottom of source
	IFND	main_endinfooff
	IFND	main_skipsysinfo
main_exitmsg:	lea	main_txtendc,a0
		bsr.w	main_print
		move.l	main_dataptr,a0
		move.w	56(a0),d0		; main_trappedvector,d0
		lsl.w	#3,d0
		lea	main_vectorlist,a0
		move.l	(a0,d0.w),a0
		bsr.w	main_print
		lea	main_txtafter,a0
		bsr.w	main_print
		move.l	main_counter2,d0
		divu	main_powerfreq,d0
		swap.w	d0
		clr.w	d0
		swap.w	d0			; d0=#of seconds
		divu	#60,d0
		swap.w	d0
		move.w	d0,d1
		clr.w	d0
		swap.w	d0			; d0=#of mins
		swap.w	d1
		clr.w	d1
		swap.w	d1			; d1=#of secs mod 60
		exg.l	d0,d1
		moveq.l	#0,d7
		tst.w	d1
		beq.s	.skipmin
		move.l	d0,-(a7)
		move.l	d1,d0
		move.l	d0,-(a7)
		bsr.w	main_printdec		; Write mins
		move.l	(a7)+,d0
		lea	main_txtminute,a0
		cmp.l	#1,d0
		beq.s	.skipmins
		lea	main_txtminutes,a0
.skipmins:	bsr.w	main_print
		move.l	(a7)+,d0
		beq.s	.skipmin
		move.l	d0,-(a7)
		lea	main_txtand,a0
		bsr.w	main_print
		move.l	(a7)+,d0
		moveq.l	#-1,d7
.skipmin:	tst.w	d0
		beq.s	.skipsec
		move.l	d0,-(a7)
		bsr.w	main_printdec		; Write secs
		move.l	(a7)+,d0
		lea	main_txtsecond,a0
		cmp.l	#1,d0
		beq.s	.skipsecs
		lea	main_txtseconds,a0
.skipsecs:	move.l	d0,-(a7)
		bsr.w	main_print
		move.l	(a7)+,d0
.skipsec:	tst.l	d0	
		bne.s	.ok1
		tst.l	d7
		bne.s	.ok1
		lea	main_txtnonetime,a0
		bsr.w	main_print
.ok1:		lea	main_txtend,a0
		bsr.w	main_print
		rts
	ENDIF
	ENDIF


*************************************************************************
* Disable/Restore OS routines 						*
*************************************************************************

main_disablesystem:;---------------------------- Get VBR and turn caches off --
		move.l	$4,a6			; Exec base
		tst.b	297(a6)			; Test processor flags
		beq.s	.novbr			; No vbr = 68000
		lea	main_getvbr,a5		; Pytr to supervisor routine
		jsr	-30(a6)			; Supervisor
	IFD	main_cacheoff
		btst.b	#0,297(a6)		; Test 68010 flag
		bne.s	.novbr			; 68010 has no cache
		move.w	#1,main_cacheok		; Set flag
		lea	main_turncacheoff,a5	; Ptr to supervisor routine
		jsr	-30(a6)			; Supervisor
		lea	main_txtcache,a0	; Write message
		bsr.w	main_print		
	ENDIF
.novbr:;--------------------------------------- Open GFX lib and save stuff --
		lea	main_gfxlibname,a1		; Ptr to gfxlib name
		jsr	-408(a6)			; Open gfx lib
		tst.l	d0				; Error?
		beq.w	main_error			; Yepp :(
		move.l	d0,main_gfxhandler		; Save base
		move.l	d0,a6				; Gfx base ptr
		move.l	$22(a6),main_oldactscreen	; Screen ptr
		move.l	$26(a6),main_oldcopper1		; Save oldcopper1
		move.l	$32(a6),main_oldcopper2		; Save oldcopper2
		move.l	a6,-(a7)
		lea	$dff000,a6		; Custom base address
		tst.b	$02(a6)			; Used for OLD agnus bug
.waitblit:	btst	#6,$02(a6)		; Test BLTBSY
		bne.s	.waitblit		; blitter isn't finnished
		move.w	$1c(a6),main_oldintena	; Save intena
		move.w	$10(a6),main_oldadkcon	; Save adkcon bits
		move.w	#$7fff,$9a(a6)		; Disable ALL interrupts
	IFND	main_short
		bsr.w	main_fadeoutwb
	ENDIF
		move.l	(a7)+,a6
		sub.l	a1,a1				; Clear a1
		jsr	-222(a6)			; Load View
		jsr	-270(a6)			; WaitTOF
		jsr	-270(a6)			; WaitTOF
		move.b	$ec(a6),d0			; Get chip rev no
		and.b	#$03,d0				; ECS ?
		beq.s	.noECS				; ECS not found
		move.l	370(a6),a2
		move.w	$28(a2),main_oldbeamcon		; Save beam control
.noECS:;------------------------------------------------- Save DMA and Stuff --
		lea	$dff000,a6		; Custom base address
		move.w	$1e(a6),main_oldintreq	; Save intreq
		move.w	#$7fff,$9e(a6)		; Disable ALL interrupt reqs
		move.w	$2(a6),main_olddmacon	; Save old dma con
		bsr.w	main_storevectors	; Save system vectors
		tst.b	$02(a6)			; Used for OLD agnus bug
.waitblit1:	btst	#6,$02(a6)		; Test BLTBSY
		bne.s	.waitblit1		; blitter isn't finnished
.waitvbl:	move.l	$04(a6),d0		; Get Rast pos
		and.l	#$1ff00,d0		; Mask out vertical bits
		cmp.l	#301*256,d0		; Wait row
		bne.s	.waitvbl		; Not reached
		move.w	#$7fff,$96(a6)		; disable ALL dma
		move.w	#$0020,$1dc(a6)		; Normal view mode
.waitvbl1:	move.l	$04(a6),d0		; Get Rast pos
		and.l	#$1ff00,d0		; Mask out vertical bits
		cmp.l	#300*256,d0		; Wait row
		bne.s	.waitvbl1		; Not reached
		lea	$140(a6),a5
		moveq.l	#$10,d1
		moveq.l	#$7,d2
		moveq.l	#0,d3
.sprclloop:	move.l	d3,(a5)
		add.l	d1,a5
		dbra	d2,.sprclloop
		Move.b #0,$DE0000		; ramsey
	IFND	main_disableint
		move.w	#$c020,$9a(a6)		; Enable level 3 int
	ENDIF
		move.b	$bfe001,main_oldbfe001
		
		bset.b	#1,$bfe001
		rts

main_oldbfe001:	dc.w	0

main_restoresystem:;---------------------------------------- Restore DMA etc --
	IFND	main_playeroff
		main_musicstop
	ENDIF
		move.b	main_oldbfe001,d0
		btst	#1,d0
		bne.s	.skipled
		bclr.b	#1,$bfe001
.skipled:
	IFND	main_short
		bsr.w	main_fadeinwbfix
	ENDIF
		lea	$dff000,a6		; Custom base
		move.w	#$7fff,$9a(a6)		; Disable all interrupts intena
		tst.b	$02(a6)			; OLD agnus bug
.waitblit:	btst	#6,$02(a6)		; Test BLTBSY
		bne.s	.waitblit		; Blitter not finnished
.waitvbl:	move.l	$04(a6),d0		; Get Rast pos
		and.l	#$1ff00,d0		; Mask out vertical bits
		cmp.l	#301*256,d0			; Wait row
		bne.s	.waitvbl		; Not reached
		move.w	#$7fff,$96(a6)		; Clear ALL DMA
		move.l	#$7fff7fff,$9c(a6)	; Clear INTREQ & ADKCON
		or.w	#$8000,main_oldadkcon	; Set set bit
		or.w	#$c000,main_oldintena	; Set set bit
		or.w	#$8000,main_oldintreq	; Set set bit	
		or.w	#$8200,main_olddmacon	; Set set bit	
		bsr.w	main_restorevectors	; Restore system vectors
.waitvbl2:	move.l	$04(a6),d0		; Get Rast pos
		and.l	#$1ff00,d0		; Mask out vertical bits
		cmp.l	#300*256,d0		; Wait row
		bne.s	.waitvbl2		; Not reached
		move.w	main_olddmacon,$96(a6)	; Restore DMA
		move.w	main_oldadkcon,$9e(a6)	; Restore ADKCON
		move.w	main_oldintena,$9a(a6)	; Restore INTENA
		move.w	main_oldintreq,$9c(a6)	; Restore INTREQ
		move.l	main_oldcopper1,$80(a6)	; Restore system copper 1
		move.l	main_oldcopper2,$84(a6)	; Restore system copper 2
		move.w	#0,$88(a6)		; Strobe copper
;--------------------------------------------------- Fix view & close doslib --
		move.l	main_gfxhandler,a6	; Get GFXlib handler
		move.l	main_oldactscreen,a1	; Get actscreen
		jsr	-222(a6)		; Set system View
		jsr	-270(a6)		; WaitTOF
		jsr	-270(a6)		; WaitTOF
		move.l	a6,a1			; Gfx handler
		move.l	$4,a6			; Exec base
		jsr	-414(a6)		; Exec close lib
	IFND	main_short
		bsr.w	main_fadeinwb
	ENDIF
		rts

	IFND	main_short

	IFND	main_rgbfadeto
main_rgbfadeto	=	$000
	ENDIF

	IFND	main_rgbfadefrom
main_rgbfadefrom=	$000
	ENDIF
	
main_fadeoutwb:
	IFND	main_faderoff
		move.l	main_oldcopper1,a0
		moveq.l	#0,d0
		bsr.w	.loop
		move.l	main_oldcopper2,a0
		bsr.w	.loop
		move.l	d0,main_wbcolours
		mulu	#6,d0			; #of bytes to reserve !!
		move.l	$4.w,a6			; Exec base address
		moveq.l	#0,d1
		jsr	-198(a6)		; Exec allocmem
		move.l	d0,main_wbaddress
		tst.l	d0
		beq.w	.skip
		move.l	d0,a1
		move.l	main_oldcopper1,a0
		bsr.w	.loop2
		move.l	main_oldcopper2,a0
		bsr.w	.loop2
		moveq.l	#$f,d0
.fadeloop:	move.l	main_wbcolours,d1
		subq.w	#1,d1
		move.l	main_wbaddress,a0
.sync:		move.l	$dff004,d2
		and.l	#$1ff00,d2
		cmp.l	#308*$100,d2
		beq.s	.sync
.sync1:		move.l	$dff004,d2
		and.l	#$1ff00,d2
		cmp.l	#308*$100,d2
		bne.s	.sync1
.colloop:	move.w	(a0)+,d2
		move.w	d2,d3
		move.w	d2,d4
		move.w	d2,d5
		and.w	#$f00,d3
		lsr.w	#8,d3
		and.w	#$f0,d4
		lsr.w	#4,d4
		and.w	#$f,d5
		sub.w	#(main_rgbfadeto&$f00)>>8,d3
		sub.w	#(main_rgbfadeto&$f0)>>4,d4
		sub.w	#(main_rgbfadeto&$f),d5
		muls	d0,d3
		muls	d0,d4
		muls	d0,d5
		divs	#$f,d3
		divs	#$f,d4
		divs	#$f,d5
		add.w	#(main_rgbfadeto&$f00)>>8,d3
		add.w	#(main_rgbfadeto&$f0)>>4,d4
		add.w	#(main_rgbfadeto&$f),d5
		lsl.w	#8,d3
		lsl.w	#4,d4
		or.w	d4,d3
		or.w	d5,d3
		move.l	(a0)+,a1
		move.w	d3,(a1)
		dbra	d1,.colloop
		dbra	d0,.fadeloop
.skip:		rts
.loop:		move.l	(a0)+,d1
		swap.w	d1
		cmp.l	#$fffeffff,d1
		beq.s	.exit
		btst	#0,d1
		bne.s	.loop
		cmp.w	#$0088,d1
		beq.s	.exit
		cmp.w	#$008a,d1
		beq.s	.exit
		cmp.w	#$180,d1
		blo.s	.loop
		cmp.w	#$1be,d1
		bhi.s	.loop
		addq.l	#1,d0
		bra.s	.loop
.exit:		rts
.loop2:		move.l	(a0)+,d1
		swap.w	d1
		cmp.w	#$ffff,d1
		beq.s	.exit2
		btst	#0,d1
		bne.s	.loop2
		cmp.w	#$0088,d1
		beq.s	.exit2
		cmp.w	#$008a,d1
		beq.s	.exit2
		cmp.w	#$180,d1
		blo.s	.loop2
		cmp.w	#$1be,d1
		bhi.s	.loop2
		swap.w	d1
		move.w	d1,(a1)+
		subq.l	#2,a0
		move.l	a0,(a1)+
		addq.l	#2,a0
		bra.s	.loop2
.exit2:	
	ENDIF
		rts

main_fadeinwb:
	IFND	main_faderoff
		tst.l	main_wbaddress
		beq.w	.exit
		moveq.l	#$f,d0
.fadeloop:	move.l	main_wbcolours,d1
		subq.w	#1,d1
		move.l	main_wbaddress,a0
.sync:		move.l	$dff004,d2
		and.l	#$1ff00,d2
		cmp.l	#308*$100,d2
		beq.s	.sync
.sync1:		move.l	$dff004,d2
		and.l	#$1ff00,d2
		cmp.l	#308*$100,d2
		bne.s	.sync1
.colloop:	move.w	(a0)+,d2
		move.w	d2,d3
		move.w	d2,d4
		move.w	d2,d5
		and.w	#$f00,d3
		lsr.w	#8,d3
		and.w	#$f0,d4
		lsr.w	#4,d4
		and.w	#$f,d5
		sub.w	#(main_rgbfadefrom&$f00)>>8,d3
		sub.w	#(main_rgbfadefrom&$f0)>>4,d4
		sub.w	#(main_rgbfadefrom&$f),d5
		move.w	d0,d2
		neg.w	d2
		add.w	#$f,d2
		muls	d2,d3
		muls	d2,d4
		muls	d2,d5
		divs	#$f,d3
		divs	#$f,d4
		divs	#$f,d5
		add.w	#(main_rgbfadefrom&$f00)>>8,d3
		add.w	#(main_rgbfadefrom&$f0)>>4,d4
		add.w	#(main_rgbfadefrom&$f),d5
		lsl.w	#8,d3
		lsl.w	#4,d4
		or.w	d4,d3
		or.w	d5,d3
		move.l	(a0)+,a1
		move.w	d3,(a1)
		dbra	d1,.colloop
		dbra	d0,.fadeloop
		move.l	main_wbaddress,a1
		move.l	main_wbcolours,d0
		mulu	#6,d0
		move.l	$4.w,a6
		jsr	-210(a6)
.exit:
	ENDIF
		rts

main_fadeinwbfix:
	IFND	main_faderoff
		tst.l	main_wbaddress
		beq.w	.exit
		move.l	main_wbcolours,d1
		subq.w	#1,d1
		move.l	main_wbaddress,a0
.sync:		move.l	$dff004,d2
		and.l	#$1ff00,d2
		cmp.l	#308*$100,d2
		beq.s	.sync
.sync1:		move.l	$dff004,d2
		and.l	#$1ff00,d2
		cmp.l	#308*$100,d2
		bne.s	.sync1
.colloop:	move.w	(a0)+,d2
		move.l	(a0)+,a1
		move.w	#(main_rgbfadefrom&$f),(a1)
		dbra	d1,.colloop
.exit:
	ENDIF
		rts

main_wbcolours:	dc.l	0
main_wbaddress:	dc.l	0
	ENDIF

main_storevectors:
		move.l	main_vbrbase,a0		; VBR base address
		move.l	a0,a3			; VBR base address
		addq.l	#8,a0			; Ptr to first vector
		lea	main_oldvectors,a1	; Ptr to old vectors
	IFND	main_disableint
		lea	.trapvcode,a2		; Ptr to trap code
	ENDIF
		move.w	#main_vectortrap,d1	; Get vectors to trap
		moveq.l	#9,d0			; #of vectors
.loop:		move.l	(a0)+,(a1)+		; Save vector
	IFND	main_disableint
		btst	d0,d1			; Trap vector ?
		beq.s	.notrap			; Not !
		move.l	a2,-4(a0)		; Set new vector
.notrap:	add.l	#.lenchk-.trapvcode,a2	; Next trap vector code
	ENDIF
		dbra	d0,.loop		; Next vector
		move.l	a3,a0			; First vector
		add.w	#$64,a3			; First int vector
		moveq.l	#6,d0			; 7 int vectors
.intloop:	move.l	(a3)+,(a1)+		; Save vector
		dbra	d0,.intloop		
		move.b	$bfec01,main_lastkey
	IFND	main_disableint
		move.l	#main_level3int,$6c(a0)	; Set to our level 3	
	IFD	main_trap7
		move.l	#main_level7int,$7c(a0)	; Set to our level 7
	ENDIF
	ENDIF
		rts	
	IFND	main_disableint
.trapvcode:	move.l	a0,-(a7)
		move.l	main_dataptr,a0
		move.w	#1,56(a0)		; main_trappedvector
		move.l	(a7)+,a0
.lenchk:	jmp	main_interrupt
		move.l	a0,-(a7)
		move.l	main_dataptr,a0
		move.w	#2,56(a0)		; main_trappedvector
		move.l	(a7)+,a0
		jmp	main_interrupt
		move.l	a0,-(a7)
		move.l	main_dataptr,a0
		move.w	#3,56(a0)		; main_trappedvector
		move.l	(a7)+,a0
		jmp	main_interrupt
		move.l	a0,-(a7)
		move.l	main_dataptr,a0
		move.w	#4,56(a0)		; main_trappedvector
		move.l	(a7)+,a0
		jmp	main_interrupt
		move.l	a0,-(a7)
		move.l	main_dataptr,a0
		move.w	#5,56(a0)		; main_trappedvector
		move.l	(a7)+,a0
		jmp	main_interrupt
		move.l	a0,-(a7)
		move.l	main_dataptr,a0
		move.w	#6,56(a0)		; main_trappedvector
		move.l	(a7)+,a0
		jmp	main_interrupt
		move.l	a0,-(a7)
		move.l	main_dataptr,a0
		move.w	#7,56(a0)		; main_trappedvector
		move.l	(a7)+,a0
		jmp	main_interrupt
		move.l	a0,-(a7)
		move.l	main_dataptr,a0
		move.w	#8,56(a0)		; main_trappedvector
		move.l	(a7)+,a0
		jmp	main_interrupt
		move.l	a0,-(a7)
		move.l	main_dataptr,a0
		move.w	#9,56(a0)		; main_trappedvector
		move.l	(a7)+,a0
		jmp	main_interrupt
		move.l	a0,-(a7)
		move.l	main_dataptr,a0
		move.w	#10,56(a0)		; main_trappedvector
		move.l	(a7)+,a0
		jmp	main_interrupt
	ENDIF
	
main_restorevectors:
		move.l	main_vbrbase,a0		; VBR base address
		move.l	a0,a3			; VBR base address
		addq.l	#8,a0			; Ptr to first vector
		lea	main_oldvectors,a1	; Ptr to old vectors
		moveq.l	#9,d0			; #of vectors
.loop:		move.l	(a1)+,(a0)+		; Restore vector
		dbra	d0,.loop		; Next vector
		add.w	#$64,a3			; First in vector
		moveq.l	#6,d0			; 7 int vectors
.intloop:	move.l	(a1)+,(a3)+		; Save vector
		dbra	d0,.intloop		
		rts

	IFND	main_disableint

main_interrupt:	IFND	MAIN_DEBUGOFF
		jmp	main_verticalint
		ENDIF
		IFD	MAIN_DEBUGOFF
		move.l	a0,.old
		move.l	main_dataptr,a0
		move.l	58(a0),$02(a7)		; Main_ExitAddy
		move.l	.old,a0
		rte
.old:		dc.l	0		
		ENDIF

		IFD	main_trap7
main_level7int:	move.l	a0,-(a7)
		move.l	main_vbrbase,a0
		move.l	#.rte,$7c(a0)
		move.l	(a7)+,a0
.loop:		cmp.l	#main_level7int,$02(a7)
		beq.s	.notok
		cmp.l	#.rte,$02(a7)
		bne.s	.ok
.notok:		addq.l	#6,a7
		bra.s	.loop
.ok:		move.w	#12,main_trappedvector
.loop2:		cmp.l	#main_level7int,$02(a7)
		beq.s	.notok2
		cmp.l	#.rte,$02(a7)
		bne.s	.ok2
.notok2:	addq.l	#6,a7
		bra.s	.loop2
.ok2:		jmp	main_interrupt
.rte:		rte
		ENDIF


*************************************************************************
* Interrupt related routines						*
*************************************************************************

main_level3int:	btst.b	#4,$dff01f		; COP int ?
		bne.s	main_copperint		; Yes
		btst.b	#5,$dff01f		; VBL int ?
		bne.s	main_verticalint	; Yes
		btst.b	#6,$dff01f		; BLT int ?
		bne.s	main_blitterint		; Yes
		rte				; ?????

main_copperint:	movem.l	d0-a6,-(a7)
		move.l	main_dataptr,a0
		move.l	28(a0),a0		; Get COPint ptr
		cmp.l	#0,a0
		beq.s	.noint
		jsr	(a0)
.noint:		movem.l	(a7)+,d0-a6	
		move.w	#$0010,$dff09c		; Clear REQ bits
		rte

main_blitterint:movem.l	d0-a6,-(a7)
		move.l	main_dataptr,a0
		move.l	24(a0),a0		; Get BLTInt ptr
		cmp.l	#0,a0
		beq.s	.noint
		jsr	(a0)
.noint:		movem.l	(a7)+,d0-a6	
		move.w	#$0040,$dff09c		; Clear REQ bits
		rte

main_verticalint:	
		tst.w	main_novbl
		bne.w	.noclose
		move.l	a7,main_registers+15*4	; Save SP
		lea	main_registers+15*4,a7	; Register ptr
		movem.l	d0-a6,-15*4(a7)
		move.l	(a7),a7			; Restore SP
		move.w	(a7),main_usersr	; Save SR
		move.l	2(a7),main_userpc	; Save user PC
.skippr:	movem.l	d0-a6,-(a7)		; Save registers
	IFND	main_debugoff
		tst.w	main_configscreen	; Is configscreen up ?
		bne.w	.configint		; Yes do special config int
	ENDIF
		tst.w	main_forcedebug
		bne.w	.forcedebug
		move.l	main_dataptr,a0
		tst.w	56(a0)			; main_trappedvector
		bne.w	.forcedebug
	IFND	main_noexit
	IFD	main_usermb
		clr.w	main_readakey
		btst	#2,$dff016		; Right mouse buttom ?
		beq.w	.forcedebug		; Yepp...
	ENDIF
	IFD	main_uselmb
		clr.w	main_readakey
		btst	#6,$bfe001		; Left mouse buttom ?
		beq.s	.forcedebug		; Yepp...
	ENDIF
	ENDIF
	IFND	main_debugoff
		tst.w	main_contrace
		bne.w	.forcedebug
	ENDIF
.continue:	move.l	main_dataptr,a0
		addq.l	#1,(a0)			; Increase main counter
		addq.l	#1,4(a0)		; Increase counter
		addq.l	#1,main_counter2
		tst.l	8(a0)			; Timer countdown?
		beq.s	.nodectimer		; Nopie..
		subq.l	#1,8(a0)		; Decrease timer
.nodectimer:	tst.l	12(a0)			; main_Timer countdown?
		beq.s	.nodectimer1		; Nopie..
		subq.l	#1,12(a0)		; Decrease main_timer
.nodectimer1:	move.l	16(a0),d0		; Get VBLint
		beq.s	.skipcustom
		move.l	d0,a0
		jsr	(a0)
.skipcustom:	move.l	main_dataptr,a0
		move.l	20(a0),d0		; Get VBLInt2
		beq.s	.skipcustom2
		move.l	d0,a0
		jsr	(a0)
.skipcustom2:
;------------------------------------------- Music stuff --
	IFND	main_playeroff
		tst.w	main_play
		beq	.noplay
		main_musicplay
.noplay:	move.l	main_dataptr,a0
		move.l	32(a0),d0		; Get MAIN_MOdule
		beq.s	.stopmusic
		cmp.l	#-1,32(a0)
		beq.s	.skipmusic
		move.l	d0,a0
		sub.l	a1,a1
		main_musicinit
		move.l	main_dataptr,a0
		move.l	#-1,32(a0)		; Clear main_module
		st.b	main_play
		bra.s	.skipmusic
.stopmusic:	main_musicstop
		move.l	main_dataptr,a0
		move.l	#-1,32(a0)
.skipmusic:
	ENDIF
;----------------------------------------------- Music end --

	IFND	main_meteroff
		bsr.w	main_frameint
	ENDIF
.exitint:
	IFD	main_length
		tst.l	main_timer
		bne.s	.skipquit
		move.l	#main_exit,main_userpc
.skipquit:
	ENDIF
		movem.l	(a7)+,d0-a6		; Restore registers
		move.l	main_userpc,2(a7)	; Restore PC
	IFND	main_debugoff
		tst.w	main_configexit		; Close config ?
		beq.s	.noclose		; Nopie...
		move.w	#0,main_configexit	; Clear flag
		move.w	#0,main_configscreen	; Clear flag
		move.w	main_configsr,(a7)	; Restore SR
		move.l	main_configpc,2(a7)	; Restore PC
		move.l	a7,main_configregs+15*4	; Save sp
		lea	main_configregs+15*4,a7	; Ptr to saved registers
		movem.l	-15*4(a7),d0-a6
		move.l	(a7),a7
	ENDIF
		move.l	a0,-(a7)
		move.l	main_vbrbase,a0
	IFD	main_trap7
		move.l	#main_level7int,$7c(a0)
	ENDIF
		move.l	(a7)+,a0
.noclose:	move.w	#$0020,$dff09c		; Clear REQ bits
		rte
;------------------------------------ Force debug mode --
.forcedebug:	move.l	main_dataptr,a0
		tst.w	36(a0)
		beq.s	.ok2exit
		st.b	main_forcedebug
		bra.w	.continue
.ok2exit:	cmp.w	#14,56(a0)		; main_trappedvector
		bge.w	.continue		

		clr.w	main_forcedebug	
	IFD	main_debugoff
		move.l	main_dataptr,a0
		tst.l	52(a0)			; main_exitaddy
		beq.w	.continue
		move.l	52(a0),main_userpc	; main_exitaddy
		bra.s	.exitint
	ENDIF
	IFND	main_debugoff
		st.b	main_configscreen	; Set flag
		move.w	main_usersr,main_configsr; Save for later exit
		move.l	main_userpc,main_configpc; Save for later exit
		move.l	#main_config,main_userpc; Run config routine
		lea	main_registers,a0	; Save...
		lea	main_configregs,a1
		moveq.l	#15,d0
.saveregloop:	move.l	(a0)+,(a1)+
		dbra	d0,.saveregloop		;...registers
	ENDIF
.configint:	
	IFND	main_debugoff
		tst.w	main_contrace
		bne.s	.trace
		lea	main_configcop,a0
		lea	$dff000,a6
.conloop:	move.l	(a0)+,d0
		cmp.l	#-2,d0
		beq.s	.conexit
		move.w	d0,d1
		swap.w	d0
		move.w	d1,(a6,d0.w)
		bra.s	.conloop
.conexit:	bsr.w	main_mousemove
		addq.l	#1,main_concounter
		moveq.l	#0,d0
		moveq.l	#0,d1
		move.w	main_concurx,d0
		lsl.w	#3,d0
		move.w	main_concury,d1
		lsl.w	#4,d1
		add.w	#128*2,d0
		add.w	#$28*2+main_coninpwin*16,d1
		move.l	main_configscr,a0
		add.l	#20480+8+44,a0
		move.l	main_concounter,d2
		and.l	#$1f,d2
		and.l	#$10,d2
		beq.s	.skipblink
		moveq.l	#0,d0
.skipblink:	bsr.w	main_setspritepos
		bsr.w	kbd_kbdlevel3
.trace:
	ENDIF
		bra.w	.exitint		

	ENDIF	; Main_DisableInt

*************************************************************************
* Configscreen related routines						*
*************************************************************************

main_config:	
	IFND	main_debugoff
		move.l	a7,main_conoldsp
		tst.l	main_configscr			; Screen alocated ?
		beq.s	main_conquit			; Quit instead !!
		tst.w	main_contrace
		beq.s	.cont				; Not tracing
		move.l	main_dataptr,a0
		tst.w	56(a0)				; main_trappedvector
		bne.s	.cont				; Tracing !!
.loop:		btst	#2,$dff016
		beq.s	.cont
		move.b	$bfec01,d0
		move.b	main_lastkey,d1
		move.b	d0,main_lastkey
		cmp.b	d0,d1
		bne.s	.cont
		btst	#6,$bfe001
		bne.s	.loop
.loop1:		btst	#6,$bfe001
		beq.s	.loop1
		bra.s	main_conexit
.cont:		clr.w	main_contrace
		bsr.w	kbd_flushbuffer
		bsr.w	main_consaveall			; Save all
		bsr.w	main_concode
		bra.s	main_conexit			; Exit
main_conquit:	move.l	main_dataptr,a0
		tst.l	52(a0)				; Main_exitaddy
		beq.s	.skippqqq0
		move.l	#main_exit,52(a0)
.skippqqq0:	move.l	52(a0),main_configpc		; Just exit
main_conexit:	move.l	main_dataptr,a0
		move.l	52(a0),d0			; Main_exitaddy
		cmp.l	main_configpc,d0
		beq.s	.skippcfix
		move.w	56(a0),d0			; main_trappedvector,d0
		lsl.w	#3,d0
		lea	main_vectorlist,a0
		move.l	4(a0,d0.w),d0
		add.l	d0,main_configpc
		move.l	main_dataptr,a0
		clr.w	56(a0)				; main_trappedvector
.skippcfix:	move.l	main_conoldsp,a7
		bsr.w	main_conrestoreall
		st.b	main_configexit			; Set exit flag
		move.b	$bfec01,main_lastkey
.sloop:		bra.s	.sloop

main_consaveall:lea	$dff000,a6			; Custom base address
		move.w	#1,main_contrace
.waitvbl:	move.l	$04(a6),d0			; Wait 4...
		and.l	#$1ff00,d0
		cmp.l	#301*256,d0
		bne.s	.waitvbl			;...some frames
.waitvbl1:	move.l	$04(a6),d0			; Wait 4...
		and.l	#$1ff00,d0
		cmp.l	#300*256,d0
		bne.s	.waitvbl1			;...some frames
		move.w	$1e(a6),main_conintreq		; Save intreq
		move.w	#$3fdf,$9c(a6)			; Clear intreq
		move.w	$1c(a6),main_conintena		; Save intena
		move.w	#$3fdf,$9a(a6)			; Disable interrupts
		move.w	$02(a6),main_condmacon		; Save dmacon
		move.w	#$7fff,$96(a6)			; Clear dma
	IFND	main_skipsysinfo
		tst.w	main_aga
		beq.s	.skippa
		lea	$dff000,a6
		lea	main_concols,a0
		move.w	#$0100,$0104(a6)	; Read Ram
		move.w	#$0000,$0106(a6)
		move.w	$180(a6),(a0)+
		move.w	$182(a6),(a0)+
		move.w	$1a2(a6),(a0)+
		move.w	$1a4(a6),(a0)+
		move.w	$1ba(a6),(a0)+
		move.w	$1bc(a6),(a0)+
		move.w	$1be(a6),(a0)
		move.w	#$0000,$0104(a6)
	ENDIF
.skippa:	clr.w	main_contrace
		move.w	#$8320,$96(a6)			; Enable bpldma+Sprite
		move.l	main_vbrbase,a0
		move.l	$68(a0),kbd_oldlevel2
		move.l	#kbd_kbdlevel2,$68(a0)
		move.w	#$8008,$9a(a6)
		rts

main_conrestoreall:lea	$dff000,a6		; Custom base address
.keyrel:	tst.b	kbd_keypressed
		bne.s	.keyrel
		move.w	#$3fdf,$9a(a6)		; Disable all interrupts intena
.waitvbl2:	move.l	$04(a6),d0		; Get Rast pos
		and.l	#$1ff00,d0		; Mask out vertical bits
		cmp.l	#301*256,d0		; Wait row
		bne.s	.waitvbl2		; Not reached
		move.l	main_vbrbase,a0
		move.l	kbd_oldlevel2,$68(a0)
		or.w	#$c000,main_conintena	; Set set bit
		or.w	#$8000,main_conintreq	; Set set bit	
		or.w	#$8200,main_condmacon	; Set set bit	
.waitvbl3:	move.l	$04(a6),d0		; Get Rast pos
		and.l	#$1ff00,d0		; Mask out vertical bits
		cmp.l	#300*256,d0		; Wait row
		bne.s	.waitvbl3		; Not reached
		move.w	main_conintena,$9a(a6)	; Restore INTENA
		move.w	#$3fdf,$9c(a6)		; Clear INTREQ
		move.w	main_conintreq,$9c(a6)	; Restore INTREQ
		move.w	#$7fff,$96(a6)		; Clear ALL DMA
		move.w	main_condmacon,$96(a6)	; Restore DMA
	IFND	main_skipsysinfo
		tst.w	main_aga
		beq.s	.skippa
		lea	main_concols,a0
		move.w	#$0000,$0104(a6)
		move.w	#$0000,$0106(a6)
		move.w	(a0)+,$180(a6)
		move.w	(a0)+,$182(a6)
		move.w	(a0)+,$1a2(a6)
		move.w	(a0)+,$1a4(a6)
		move.w	(a0)+,$1ba(a6)
		move.w	(a0)+,$1bc(a6)
		move.w	(a0),$1be(a6)
	ENDIF
.skippa:	rts

main_coninpwin	=	6

main_conprintxy:;in:	d0,d1,a0=x,y,strptr
		move.w	d0,d6		
		move.w	d1,d7
.newpos:	move.w	d6,d0
		move.w	d7,d1
		add.w	#main_coninpwin,d1
		muls	#80*8,d1		; Calc..
		add.l	main_configscr,d1
		move.l	d1,d2
		add.l	d0,d1
		move.l	d1,a1			; ..Scrptr
		lea	main_font,a2		; Font ptr
		moveq.l	#0,d0
		move.w	#$00ff,d1
.loop:		move.b	(a0)+,d0		; Get char
		beq.w	.exit			; Zero=End of text
		cmp.b	#10,d0
		bne.s	.skipsr
		moveq.l	#0,d6
		bra.w	.newpos
.skipsr:	cmp.b	#13,d0
		bne.s	.skiplf
		addq.l	#1,d7
		cmp.w	#28-main_coninpwin,d7
		blt.s	.noscroll
		moveq.l	#27-main_coninpwin,d7
		move.l	main_configscr,a5
		add.l	#8*80*main_coninpwin,a5
		move.l	a5,a4
		add.l	#8*80,a4
		movem.l	a0/d6-d7,-(a7)
		move.w	#2*(248-24-main_coninpwin*8)-1,d0
		moveq.l	#40,d1
.copyloop:	movem.l	(a4)+,d2-a3
		movem.l	d2-a3,(a5)
		add.l	d1,a5
		dbra	d0,.copyloop		
		moveq.l	#0,d1
		move.l	d1,d2
		move.l	d1,d3
		move.l	d1,d4
		move.l	d1,d5
		move.l	d1,d6
		move.l	d1,d7
		move.l	d1,a0
		move.l	d1,a1
		move.l	d1,a2
		move.w	#2*8-1,d0
.clrloop:	movem.l	d1-a2,-(a4)
		dbra	d0,.clrloop		
		movem.l	(a7)+,a0/d6-d7
.noscroll:	bra.w	.newpos
.skiplf:	addq.w	#1,d6
		and.w	d1,d0
		lsl.w	#3,d0
		move.b	1(a2,d0.l),1*80(a1)		
		move.b	2(a2,d0.l),2*80(a1)		
		move.b	3(a2,d0.l),3*80(a1)		
		move.b	4(a2,d0.l),4*80(a1)		
		move.b	5(a2,d0.l),5*80(a1)		
		move.b	6(a2,d0.l),6*80(a1)		
		move.b	7(a2,d0.l),7*80(a1)		
		move.b	(a2,d0.l),(a1)+
		bra.w	.loop
.exit:		move.w	d6,main_concurx
		move.w	d7,main_concury
		rts

main_conprint:	;a0=Ptr to text
		moveq.l	#0,d0
		move.w	main_concurx,d0
		move.w	main_concury,d1
		bra.w	main_conprintxy

main_conprintdec:;in:	d0=Number
		lea	main_txtdec,a0
		move.l	a0,a1
		move.l	a1,a2
		moveq.l	#0,d1
.loop:		divu	#10,d0
		swap.w	d0
		add.b	#48,d0
		addq.l	#1,d1
		move.b	d0,(a2)+
		clr.w	d0
		swap.w	d0
		tst.l	d0
		bne.s	.loop
.ok:		move.b	#0,(a2)
		asr.w	#1,d1
		tst.w	d1
		beq.s	.skipp
		subq.w	#1,d1
.sloop:		move.b	(a1),d0
		move.b	-(a2),(a1)+
		move.b	d0,(a2)
		dbra	d1,.sloop
.skipp:		bra.w	main_conprint

main_conprinthex:;in:	d0=Number to print
		lea	main_contxthex+8,a0
		lea	main_conhexchars,a1
		moveq.l	#0,d1
		moveq.l	#7,d2
.loop:		move.b	d0,d1
		and.b	#$f,d1	
		move.b	(a1,d1.l),-(a0)
		lsr.l	#4,d0
		dbra	d2,.loop
		bra.w	main_conprint

main_conprinthex4:;in:	d0=Number to print
		lea	main_contxthex+8,a0
		lea	main_conhexchars,a1
		moveq.l	#0,d1
		moveq.l	#3,d2
.loop:		move.b	d0,d1
		and.b	#$f,d1	
		move.b	(a1,d1.l),-(a0)
		lsr.l	#4,d0
		dbra	d2,.loop
		bra.w	main_conprint

main_conlf:	lea	main_contxtlf,a0
		bra.w	main_conprint

main_concode:	move.l	main_concurx,-(a7)
		move.w	#2,main_concurx
		move.w	#-5,main_concury
		lea	main_contxt02,a0
		bsr.w	main_conprint
		lea	main_configregs,a5
		moveq.l	#7,d6
.regloop0:	move.l	(a5)+,d0
		movem.l	d6/a5,-(a7)
		bsr.w	main_conprinthex
		lea	main_contxt08,a0
		bsr.w	main_conprint
		movem.l	(a7)+,d6/a5
		dbra	d6,.regloop0
		bsr.w	main_conlf
		move.w	#2,main_concurx
		lea	main_contxt03,a0
		bsr.w	main_conprint
		moveq.l	#7,d6
.regloop1:	move.l	(a5)+,d0
		movem.l	d6/a5,-(a7)
		bsr.w	main_conprinthex
		lea	main_contxt08,a0
		bsr.w	main_conprint
		movem.l	(a7)+,d6/a5
		dbra	d6,.regloop1
		bsr.w	main_conlf
		move.w	#2,main_concurx
		lea	main_contxt01,a0
		bsr.w	main_conprint
		move.l	main_configpc,d0
		bsr.w	main_conprinthex
		lea	main_contxt06,a0
		bsr.w	main_conprint
		move.w	main_usersr,d0
		bsr.w	main_conprinthex4
		lea	main_contxt05,a0
		bsr.w	main_conprint
		move.w	main_condmacon,d0
		bsr.w	main_conprinthex4
		lea	main_contxt07,a0
		bsr.w	main_conprint
		move.w	main_conintena,d0
		bsr.w	main_conprinthex4
		lea	main_contxt09,a0
		bsr.w	main_conprint
		move.w	main_conintreq,d0
		bsr.w	main_conprinthex4
		move.w	#2,main_concurx
		addq.w	#1,main_concury
		lea	main_contxt20,a0
		bsr.w	main_conprint
		move.l	main_dataptr,a0
		move.w	56(a0),d0		; main_trappedvector,d0
		lsl.w	#3,d0
		lea	main_vectorlist,a0
		move.l	(a0,d0.w),a0
		bsr.w	main_conprint
		move.l	(a7)+,main_concurx
		tst.w	main_confirst		
		bne.w	.skipsi;------------------------ Run first time only --
		move.w	#1,main_confirst
		moveq.l	#$5f,d0
		moveq.l	#0,d1
		move.l	#main_macro0,d2
		bsr.w	kbd_setmacro
		move.l	main_concurx,-(a7)
		lea	main_contxt16,a0
		move.w	#1,main_concurx
		move.w	#24,main_concury
		bsr.w	main_conprint
		move.l	(a7)+,main_concurx
		move.l	main_configscr,a0
		move.l	a0,a1
		add.l	#5*80,a1
		move.l	a1,a2
		add.l	#79,a2
		moveq.l	#3,d0
		move.b	#$c0,d1
		moveq.l	#80,d3
		moveq.l	#38,d2
.yloopq:	move.b	d1,(a1)
		move.b	d0,(a2)
		add.l	d3,a1
		add.l	d3,a2
		dbra	d2,.yloopq
		add.l	#236*80,a0
		move.b	#$c0,d0
		bsr.w	.drawline
		add.l	#17,a0
		moveq.l	#$01,d0
		bsr.w	.drawline
		addq.l	#1,a0
		move.b	#$80,d0
		bsr.w	.drawline
		add.l	#15,a0
		moveq.l	#$01,d0
		bsr.s	.drawline
		addq.l	#1,a0
		move.b	#$80,d0
		bsr.s	.drawline
		add.l	#12,a0
		moveq.l	#$01,d0
		bsr.s	.drawline
		addq.l	#1,a0
		move.b	#$80,d0
		bsr.s	.drawline
		add.l	#19,a0
		moveq.l	#$01,d0
		bsr.s	.drawline
		addq.l	#1,a0
		move.b	#$80,d0
		bsr.s	.drawline
		add.l	#12,a0
		moveq.l	#$03,d0
		bsr.s	.drawline
		move.l	main_configscr,a0
		move.l	a0,a3
		add.l	#4*80,a3
		add.l	#(5*8+4)*80,a0
		move.l	a0,a1
		add.l	#24*8*80,a1
		move.l	a1,a2
		add.l	#2*8*80,a2
		moveq.l	#-1,d0
		moveq.l	#19,d1
.dlineloop:	move.l	d0,(a0)+
		move.l	d0,(a1)+
		move.l	d0,(a2)+
		move.l	d0,(a3)+
		dbra	d1,.dlineloop
		lea	main_contxt00,a0
		bsr.w	main_conprint
		bsr.w	main_conprintsi
		bra.s	.skipsi
.drawline:	moveq.l	#15,d1
		move.l	a0,a1
.yloop0:	move.b	d0,(a1)
		add.l	#80,a1
		dbra	d1,.yloop0
		rts
.skipsi:	move.w	#0,main_concurx
		subq.w	#1,main_concury	
.nextcommand:	bsr.w	kbd_flushbuffer
;------------------------------------------------------------- Input routine --
		lea	main_contxt04,a0
		bsr.w	main_conprint
		lea	main_inputbuffer,a0
		move.l	a0,a6
		bsr.w	main_conprint
.loop:		btst	#6,$bfe001
		bne.s	.nomouse
		move.w	main_mousezone,d0
		cmp.w	#-1,d0
		beq.s	.nomouse
		lsl.w	#2,d0
		lea	main_zonecodes,a0
		move.l	(a0,d0.w),a0
.mkrelloop:	btst	#6,$bfe001
		beq.s	.mkrelloop
		jsr	(a0)
		bra.s	.loop
.nomouse:	bsr.w	kbd_readkey
		tst.b	d0
		beq.s	.loop
		cmp.w	#32,d0
		blt.s	.special
		cmp.w	#128,d0
		blt.s	.ok
		cmp.w	#160,d0
		blt.s	.special
.ok:		move.w	main_inputlength,d1
		cmp.w	#79,d1
		bge.s	.loop
		move.b	d0,(a6,d1.w)
		clr.b	1(a6,d1.w)
		lea	main_contxt13,a0
		move.b	d0,(a0)
		bsr.w	main_conprint
		addq.w	#1,main_inputlength
		bra.s	.loop
.special:	cmp.b	#8,d0
		beq.s	.del
		cmp.b	#13,d0
		beq.s	.enter
		cmp.b	#27,d0
		beq.s	.esc
		bra.w	.loop
.esc:		clr.l	(a6)
		clr.w	main_inputlength
		move.w	#1,main_concurx
		lea	main_contxt15,a0
		bsr.w	main_conprint
		move.w	#1,main_concurx
		bra.w	.loop
.del:		tst.w	main_inputlength
		beq.w	.loop
		move.w	main_inputlength,d1
		subq.w	#1,d1
		move.b	#0,(a6,d1.w)
		move.w	d1,main_inputlength
		subq.w	#1,main_concurx
		lea	main_contxt13,a0
		move.b	#32,(a0)
		bsr.w	main_conprint
		subq.w	#1,main_concurx
		bra.w	.loop
.enter:		tst.w	main_inputlength
		beq.w	.nextcommand
		bsr.w	main_conlf
		lea	main_commandlist,a0
.cmdloop:	move.l	a6,a1
		tst.b	(a0)
		beq.w	.nocmdfound
.testloop:	move.b	(a0)+,d0
		move.b	(a1)+,d1
		cmp.b	#0,d0
		bne.s	.cont
		cmp.b	#0,d1
		beq.s	.foundcode
		cmp.b	#32,d1
		beq.s	.foundcode	
		bra.s	.nextcode
.cont:		cmp.b	d0,d1
		beq.s	.testloop
.moreloop:	tst.b	(a0)+
		bne.s	.moreloop		
.nextcode:	addq.l	#4,a0
		move.l	a0,d0
		and.b	#$1,d0
		beq.s	.cmdloop
		addq.l	#1,a0
		bra.s	.cmdloop
.foundcode:	move.l	a0,d0
		and.b	#$1,d0
		beq.s	.skipeven
		addq.l	#1,a0
.skipeven:	move.l	(a0)+,a0
		clr.l	(a6)
		move.w	#0,main_inputlength
.keyrelloop:	tst.b	kbd_keypressed
		bne.s	.keyrelloop		
		jsr	(a0)
		bra.w	.nextcommand
.nocmdfound:	lea	main_contxt14,a0
		bsr.w	main_conprint
		clr.l	(a6)
		move.w	#0,main_inputlength
		bra.w	.nextcommand		
.exitcon:	rts

main_cmdtest:	movem.l	d0-a6,-(a7)
		lea	main_contxt18,a0
		bsr.w	main_conprint
		lea	test,a1
		moveq.l	#7,d1
.loop0:		move.l	(a1)+,d0
		movem.l	d1/a1,-(a7)
		bsr.w	main_conprinthex
		lea	main_contxt08,a0
		bsr.w	main_conprint
		movem.l	(a7)+,d1/a1
		dbra	d1,.loop0
		lea	main_contxt19,a0
		bsr.w	main_conprint
		lea	test+4*8,a1
		moveq.l	#7,d1
.loop1:		move.l	(a1)+,d0
		movem.l	d1/a1,-(a7)
		bsr.w	main_conprinthex
		lea	main_contxt08,a0
		bsr.w	main_conprint
		movem.l	(a7)+,d1/a1
		dbra	d1,.loop1
		bsr.w	main_conlf
		bsr.w	main_conlf
		lea	main_contxt10,a0
		bsr.w	main_conprint
		move.l	main_dataptr,a0
		move.l	8(a0),d0		; Get timer
		bsr.w	main_conprinthex
		lea	main_contxt11,a0
		bsr.w	main_conprint
		move.l	main_dataptr,a0
		move.l	4(a0),d0		; Get counter
		bsr.w	main_conprinthex
		lea	main_contxt12,a0
		bsr.w	main_conprint
		move.l	main_dataptr,a0
		move.l	(a0),d0
		bsr.w	main_conprinthex
		bsr.w	main_conlf
		movem.l	(a7)+,d0-a6
		rts

main_cmdcont:	move.l	#.exit,(a7)
.exit:		rts

main_cmdtrace:	move.w	#-1,main_contrace
		move.l	#.exit,(a7)
.exit:		rts

main_cmdexit:	move.l	#.exit,(a7)
		move.l	a0,-(a7)
		move.l	main_dataptr,a0
		move.l	52(a0),main_configpc	; Just exit main_exitaddy
		move.l	(a7)+,a0
.exit:		rts

main_cmdview:	movem.l	d0-a6,-(a7)
		bsr.w	main_conrestoreall		
		st.b	main_novbl
		move.b	$bfec01,main_lastkey
.loop:		move.b	$bfec01,d0
		move.b	main_lastkey,d1
		move.b	d0,main_lastkey
		cmp.b	d0,d1
		bne.s	.exit
		btst	#2,$dff016
		beq.s	.exit
		btst	#6,$bfe001
		bne.s	.loop
.exit:		btst	#6,$bfe001
		beq.s	.exit
		bsr.w	main_consaveall		
		clr.w	main_novbl
		bsr.w	kbd_flushbuffer
		movem.l	(a7)+,d0-a6
		rts

main_cmdhelp:	movem.l	d0-a6,-(a7)
		lea	main_contxt17,a0
		bsr.w	main_conprint
		movem.l	(a7)+,d0-a6
		rts


main_cmdmeteron:movem.l	d0-a6,-(a7)
	IFND	main_meteroff
		bsr.w	main_framemeteron
	ENDIF
		movem.l	(a7)+,d0-a6
		rts

main_cmdmeteroff:movem.l	d0-a6,-(a7)
	IFND	main_meteroff
		bsr.w	main_framemeteroff
	ENDIF
		movem.l	(a7)+,d0-a6
		rts

main_cmddi:	movem.l	d0-a6,-(a7)
		lea	main_contxt00,a0
		bsr.w	main_conprint
		movem.l	(a7)+,d0-a6
		rts

main_cmdhelp2:	movem.l	d0-a6,-(a7)
.loop:		btst	#6,$bfe001
		beq.s	.loop
		lea	main_macro0,a5
.cpkloop:	move.b	(a5)+,d0
		beq.s	.exitikloop
		bsr.w	kbd_insertkey
		bra.s	.cpkloop
.exitikloop:	movem.l	(a7)+,d0-a6
		rts

main_cmdscop:	movem.l	d0-a6,-(a7)
	IFND	main_skipsysinfo
		lea	main_copfound,a2
		lea	main_coptext00,a0
		bsr.w	main_conprint
		move.l	main_copaddy,d0
		addq.l	#4,d0
		and.l	#-2,d0
		move.l	d0,a0
		moveq.l	#0,d2
		move.l	main_chipmem,d0
.searchloop0:	move.w	(a0),d1
		move.l	d2,(a2)
		addq.l	#2,a0
		cmp.l	a0,d0
		beq.w	.notfound
		cmp.w	main_copins0,d1
		bne.s	.searchloop0
		move.l	a0,a1
		subq.l	#2,a1
		move.l	a1,main_copaddy
.searchloop1:	move.w	(a1),d1
		subq.l	#4,a1
		cmp.l	#0,a1
		blt.s	.searchloop0
		btst	#0,d1
		bne.s	.searchloop1
		cmp.w	#$040,d1
		blo.s	.oktop
		cmp.w	#$1fe,d1
		bls.s	.searchloop1
.oktop:		addq.l	#8,a1
		move.l	a1,main_copfound
.searchloop2:	move.w	(a1),d1
		addq.l	#4,a1
		cmp.l	d0,a1
		beq.s	.notfound
		cmp.w	main_copins1,d1
		beq.s	.foundcopper
		btst	#0,d1
		bne.s	.searchloop2
		cmp.w	#$040,d1
		blo.s	.searchloop0
		cmp.w	#$1fe,d1
		bhi.w	.searchloop0
		bra.s	.searchloop2
.foundcopper:	lea	main_coptext01,a0
		bsr.w	main_conprint
		move.l	main_copfound,d0
		bsr.w	main_conprinthex
		bra.s	.found
.notfound:	move.l	d2,(a2)
		lea	main_coptext02,a0
		bsr.w	main_conprint
.found:		bsr.w	main_conlf
	ENDIF
		movem.l	(a7)+,d0-a6
		rts

main_cmdcopadd:	movem.l	d0-a6,-(a7)
		move.l	main_copfound,d0
		beq.s	.nocop
		addq.l	#4,d0
		move.l	d0,main_copfound
		move.l	d0,-(a7)
		lea	main_coptext03,a0
		bsr.w	main_conprint
		move.l	(a7)+,d0
		bsr.w	main_conprinthex
		bra.s	.exit
.nocop:		lea	main_coptext04,a0
		bsr.w	main_conprint
.exit:		bsr.w	main_conlf
		movem.l	(a7)+,d0-a6
		rts

main_cmdcopsub:	movem.l	d0-a6,-(a7)
		move.l	main_copfound,d0
		beq.s	.nocop
		subq.l	#4,d0
		move.l	d0,main_copfound
		move.l	d0,-(a7)
		lea	main_coptext03,a0
		bsr.w	main_conprint
		move.l	(a7)+,d0
		bsr.w	main_conprinthex
		bra.s	.exit
.nocop:		lea	main_coptext04,a0
		bsr.w	main_conprint
.exit:		bsr.w	main_conlf
		movem.l	(a7)+,d0-a6
		rts

main_cmdcopview:movem.l	d0-a6,-(a7)
		move.l	main_copfound,d0
		beq.s	.nocop
		move.l	d0,-(a7)
		lea	main_coptext03,a0
		bsr.w	main_conprint
		move.l	(a7),d0
		bsr.w	main_conprinthex
		move.l	(a7)+,d0
		move.l	d0,a6
		moveq.l	#7,d0
.loop:		move.l	d0,-(a7)
		move.l	a6,d0
		bsr.w	main_conprinthex
		lea	main_coptext05,a0
		bsr.w	main_conprint
		moveq.l	#0,d0
		move.w	(a6)+,d0
		bsr.w	main_conprinthex4
		lea	main_coptext06,a0
		bsr.w	main_conprint
		moveq.l	#0,d0
		move.w	(a6)+,d0
		bsr.w	main_conprinthex4
		bsr.w	main_conlf
		move.l	(a7)+,d0
		dbra	d0,.loop
		bra.s	.exit
.nocop:		lea	main_coptext04,a0
		bsr.w	main_conprint
.exit:		bsr.w	main_conlf
		movem.l	(a7)+,d0-a6
		rts


main_copaddy:	dc.l	0
main_copfound:	dc.l	0
main_copins0:	dc.w	$0100
main_copins1:	dc.w	$ffff

main_coptext00:	dc.b	10,13,'Searching for copper list ...',0
main_coptext01:	dc.b	'Found at: $',0
main_coptext02:	dc.b	'Not found !!',0
main_coptext03:	dc.b	10,13,'Copper at: $',0
main_coptext04:	dc.b	10,13,'No copper in memory !!',0
main_coptext05:	dc.b	':   dc.w    $',0
main_coptext06:	dc.b	',$',0
		even

main_conprintsi:
	IFND	main_sysinfooff
		lea	main_txtpower,a0
		bsr.w	main_conprint
		move.l	main_powptr,a0
		bsr.w	main_conprint
		lea	main_txtproc,a0
		bsr.w	main_conprint
		move.l	main_procptr,a0
		bsr.w	main_conprint
		lea	main_txtcoproc,a0
		bsr.w	main_conprint
		move.l	main_coprocptr,a0
		bsr.w	main_conprint
		lea	main_txtmmu,a0
		bsr.w	main_conprint
		move.l	main_mmuptr,a0
		bsr.w	main_conprint
		lea	main_txtaga,a0
		bsr.w	main_conprint
		move.l	main_gfxptr,a0
		bsr.w	main_conprint
		lea	main_txtvbl,a0
		bsr.w	main_conprint
		move.l	main_refreshptr,a0
		bsr.w	main_conprint
		lea	main_txtmemchip,a0
		bsr.w	main_conprint
		move.l	main_chipmem,d0
		lsr.l	#8,d0
		lsr.l	#2,d0
		bsr.w	main_conprintdec
		lea	main_txtmemfast,a0
		bsr.w	main_conprint
		move.l	main_fastmem,d0
		lsr.l	#8,d0
		lsr.l	#2,d0
		bsr.w	main_conprintdec
		lea	main_txtkblf,a0
		bsr.w	main_conprint
	ENDIF
		rts

main_mousemove:	move.w	$dff00a,d0
		move.w	main_mouseold,d1
		move.w	d0,main_mouseold
		move.w	d0,d2
		move.w	d1,d3
		and.w	#$ff,d0
		and.w	#$ff,d1
		lsr.w	#8,d2
		lsr.w	#8,d3
		sub.b	d0,d1
		sub.b	d2,d3
		ext.w	d1
		ext.w	d3
		neg.w	d1
		neg.w	d3
		move.w	main_mousex,d4
		move.w	main_mousey,d5
		add.w	d1,d4
		add.w	d3,d5
		cmp.w	#0,d4
		bge.s	.okx0
		moveq.l	#0,d4
.okx0:		cmp.w	main_mousewidth,d4
		ble.s	.okx1
		move.w	main_mousewidth,d4
.okx1:		cmp.w	#0,d5
		bge.s	.oky0
		moveq.l	#0,d5
.oky0:		cmp.w	main_mouseheight,d5
		ble.s	.oky1
		move.w	main_mouseheight,d5
.oky1:		move.w	d4,main_mousex
		move.w	d5,main_mousey
		move.w	d4,d0
		move.w	d5,d1
		moveq.l	#8,d2
		sub.w	main_mousesprx,d0
		sub.w	main_mousespry,d1
		add.w	main_mouseorgx,d0
		add.w	main_mouseorgy,d1
		move.l	main_mousesprptr,d2
		beq.s	.skipspr
		move.l	d2,a0
		bsr.w	main_setspritepos
.skipspr:	move.w	main_mousex,d0
		move.w	main_mousey,d1
		moveq.l	#-1,d2
		move.l	d2,d7
		lea	main_mousezones,a0
.mzloop:	addq.w	#1,d2
		movem.w	(a0)+,d3-d6		; Get X0
		move.l	(a0)+,a1
		cmp.w	#-1,d3
		beq.s	.exit
		cmp.w	d0,d3
		bgt.s	.mzloop
		cmp.w	d1,d4
		bgt.s	.mzloop
		cmp.w	d0,d5
		blt.s	.mzloop
		cmp.w	d1,d6
		blt.s	.mzloop
		move.w	d2,d7
		cmp.l	#0,a1
		beq.s	.skip
		movem.l	d0-a6,-(a7)
		jsr	(a1)
		movem.l	(a7)+,d0-a6
.skip:		bra.s	.mzloop
.exit:		move.w	d7,main_mousezone
		rts

main_setspritepos:;in:	a0,d0,d1=Sprite ptr,Xpos,Ypos
		moveq.l	#0,d2
		move.b	2(a0),d2
		moveq.l	#0,d3
		move.b	(a0),d3
		sub.w	d3,d2
		bge.s	.heightok
		add.w	#$100,d2		
.heightok:	moveq.l	#0,d3		; Ctrl byte
		move.w	d0,d4
		asr.w	#1,d0
		btst	#0,d4
		beq.s	.noctrl3
		or.w	#%10000,d3	; AGA...
.noctrl3:	asr.w	#1,d1
		move.w	d1,d4
		and.w	#$ff,d4		
		move.b	d4,(a0)
		btst	#8,d1
		beq.s	.noctrl0
		or.w	#%100,d3
.noctrl0:	add.w	d2,d1
		move.w	d1,d4
		and.w	#$ff,d4		
		move.b	d4,2(a0)
		btst	#8,d1
		beq.s	.noctrl1
		or.w	#%10,d3
.noctrl1:	move.w	d0,d1
		lsr.w	#1,d0
		move.b	d0,1(a0)
		btst	#0,d1
		beq.s	.noctrl2
		or.w	#%1,d3
.noctrl2:	move.b	d3,3(a0)
		rts
		
*************************************************************************
* Non OS readkeyboard routine by Equalizer/TBL (Hints from Sag) 	*
* With:	- keymap translation (Raw to ASCII, Keyboard definer in AMOS)	*
*	- keyboard buffering (255 chars)				*
*	- keyboard repetition						*
*************************************************************************

kbd_shift	=	$01
kbd_ctrl	=	$02
kbd_alt		=	$04
kbd_lamiga	=	$08
kbd_ramiga	=	$10

;------------------------------------------------------- KeyBoard interrupts --

kbd_kbdlevel3:;------------------------------------- Level 3 (VBL) interrupt --
		tst.b	kbd_keypressed
		beq.s	.rts
		move.w	kbd_repttimerw,d0
		bne.s	.wait
		move.w	kbd_repttimers,d0
		bne.s	.waitspeed
		move.w	kbd_reptspeed,kbd_repttimers
		move.w	kbd_asciikey,d0
		bsr.w	kbd_insertkey
		bra.s	.rts
.waitspeed:	subq.w	#1,d0
		move.w	d0,kbd_repttimers
		bra.s	.rts
.wait:		subq.w	#1,d0
		move.w	d0,kbd_repttimerw
.rts:		rts

kbd_kbdlevel2:	movem.l	d0-a6,-(a7) ;--------------------- Level 2 interrupt --
		btst	#3,$bfed01
		beq	.quit
		move.b	$bfec01,d0
		move.b	d0,kbd_realraw
		move.b	#0,kbd_keypressed
		move.w	kbd_reptwait,kbd_repttimerw
		move.w	kbd_reptspeed,kbd_repttimers
		btst	#0,d0
		beq.s	.skippa
		move.b	#1,kbd_keypressed
.skippa:	neg.b	d0
		add.b	#$ff,d0
		ror.b	#1,d0
		and.w	#$ff,d0
		move.b	d0,kbd_rawkey
.skip:		lea	kbd_flagcodes,a0
		moveq.l	#7,d1		
.cloop:		cmp.b	(a0)+,d0
		bne.s	.noflagset
		bset.b	d1,kbd_realflags		; Set flag bit
.noflagset:	cmp.b	8-1(a0),d0
		bne.s	.noflagsclr
		bclr.b	d1,kbd_realflags		; Clear flag bit
.noflagsclr:	dbra	d1,.cloop
.noflag:	lea	$dff006,a6
		bsr	.waitrow
		bset	#6,$bfee01
		bsr	.waitrow
		move.b	#0,$bfec01
		bsr	.waitrow
		bclr	#6,$bfee01
		bsr	.waitrow
;-------------------------------------------------------- Raw to asciibuffer --
		moveq.l	#0,d3
		move.b	kbd_rawkey,d3
		cmp.w	#128,d3
		bge.w	.exit			; Strange rawcode?
		cmp.w	#0,d3
		beq.w	.exit
		moveq.l	#0,d1			; Flags.
		moveq.l	#0,d2
		move.b	kbd_realflags,d2	; KeyB Flags
		btst	#0,d2			; Caps
		beq.s	.skip0
		or.b	#$1,d1
.skip0:		btst	#1,d2			; Ctrl
		beq.s	.skip1
		or.b	#$2,d1
.skip1:		btst	#2,d2			; LShift
		beq.s	.skip2
		or.b	#$1,d1
.skip2:		btst	#3,d2			; LAlt
		beq.s	.skip3
		or.b	#$4,d1			
.skip3:		btst	#4,d2			; LAmiga
		beq.s	.skip4
		or.b	#$8,d1			
.skip4:		btst	#5,d2			; RAmiga
		beq.s	.skip5
		or.b	#$10,d1			
.skip5:		btst	#6,d2			; RAlt
		beq.s	.skip6
		or.b	#$4,d1			
.skip6:		btst	#7,d2			; RShift
		beq.s	.skip7
		or.b	#$1,d1			
.skip7:		move.b	d1,kbd_flags
		lsl.w	#7,d1
		add.w	d3,d1
		lsl.l	#1,d1
		add.l	kbd_keymapptr,d1
		move.l	kbd_keymapptr,d7
		bne.s	.qqq
		add.l	#kbd_keydefault,d1
.qqq:		move.l	d1,a1
		move.w	(a1),d2
		move.w	d2,kbd_asciikey
		move.w	d2,d0
		bsr.w	kbd_insertkey
.exit:		move.l	kbd_customptr,d0
		beq.s	.quit
		move.l	d0,a0
		jsr	(a0)
.quit:		move.w	#$0008,$dff09c
		movem.l	(a7)+,d0-a6
		rte
.waitrow:	move.b	(a6),d0
		addq.w	#2,d0
.loop:		cmp.b	(a6),d0
		bne.s	.loop
 		rts
;----------------------------------------------------- Ascii buffer routines --

*************************************************************************
kbd_setascii:	; Changes an ascii value for a special RAW code		*
*		in:	d0.w,d1.w,d2.w=Raw value,Flags,New ASCII	*
*************************************************************************
		move.l	kbd_keymapptr,d3
		bne.s	.skip
		move.l	#kbd_keydefault,d3
.skip:		move.l	d3,a0
		and.l	#$1f,d1
		lsl.w	#7,d1
		add.w	d0,d1
		lsl.l	#1,d1
		and.w	#$ff,d2
		move.w	d2,(a0,d1.l)
		rts

*************************************************************************
kbd_setmacro:; 	Sets a macro for a special RAW code			*
*		in:	d0.w,d1.w,d2.l=Raw value,Flags,String ptr 	*
*************************************************************************
		move.l	kbd_keymapptr,d3
		bne.s	.skip
		move.l	#kbd_keydefault,d3
.skip:		move.l	d3,a0
		and.l	#$1f,d1
		lsl.w	#7,d1
		add.w	d0,d1
		move.w	d1,d3
		or.w	#$8000,d3
		lsl.l	#1,d1
		move.w	d3,(a0,d1.l)
		lsl.l	#1,d1
		move.l	kbd_macroptr,d3
		beq.s	.skip1
		move.l	d3,a0
		move.l	d2,(a0,d1.l)
.skip1:		rts

*************************************************************************
kbd_setcode:; 	Sets a code for a special RAW code			*
*		in:	d0.w,d1.w,d2.l=Raw value,Flags,Code ptr 	*
*************************************************************************
		or.l	#$80000000,d2		; Special codeptr
		bra.s	kbd_setmacro


*************************************************************************
kbd_insertkey:	;Inserts an ASCII-code into the keyboard buffer		*
*		in:	d0=ASCII-code					*
*************************************************************************
		move.w	d0,d2
.inkey:		lea	kbd_buffer,a0
		moveq.l	#0,d0
		moveq.l	#0,d1
		move.b	(a0)+,d0		; d0=head ptr
		move.b	(a0)+,d1		; d1=tail ptr
		addq.w	#2,d0
		andi.w	#$ff,d0
		cmp.w	d0,d1			; head=tail=full !!
		beq.w	.exit
		subq.w	#1,d0
		andi.w	#$ff,d0
		move.b	d0,-2(a0)		; Save new head
		lsl.w	#1,d0
		move.w	d2,(a0,d0.w)
.exit:		rts

*************************************************************************
kbd_readkey:	; Reads an ASCII-code form keyboard buffer		*
*		Out:	d0=ASCII-code	(0=No key)			*
*************************************************************************
		movem.l	d1-a6,-(a7)
.next:		moveq.l	#0,d0	
		tst.b	kbd_macroread
		bne.s	.domacro
		lea	kbd_buffer,a0
		move.b	(a0)+,d1
		move.b	(a0)+,d2
		cmp.b	d1,d2
		beq.s	.rts			; Equal=Empty
		addq.w	#1,d2
		and.w	#$ff,d2
		move.b	d2,-1(a0)
		lsl.w	#1,d2
		move.w	(a0,d2.w),d0
		move.w	d0,d2
		and.w	#$3fff,d0
		lsr.w	#8,d2
		lsr.w	#6,d2
		cmp.w	#%10,d2		
		beq.s	.fixmacro
		and.w	#$ff,d0
.rts:		movem.l	(a7)+,d1-a6
		rts
.fixmacro:	move.w	d0,d2
		and.l	#$3fff,d2
		move.l	kbd_macroptr,d1
		beq.s	.skipmacall
		lsl.l	#2,d2
		move.l	d1,a0
		move.l	(a0,d2.l),d1
		beq.s	.rts
		btst	#31,d1
		bne.s	.codemacro
		move.l	d1,kbd_macropos
.domacro:	move.l	kbd_macropos,a0
		clr.b	kbd_macroread
		moveq.l	#0,d0
		move.b	(a0)+,d0
		beq.w	.next
		st.b	kbd_macroread
		move.l	a0,kbd_macropos
		bra.s	.rts
.codemacro:	and.l	#$7fffffff,d1
		move.l	d1,a5
		movem.l	d0-a6,-(a7)
		jsr	(a5)
		movem.l	(a7)+,d0-a6
.skipmacall:	bra.w	.next

*************************************************************************
kbd_flushbuffer:	; Clears keyboard buffer			*
*************************************************************************
		move.b	kbd_buffer,kbd_buffer+1	
		rts

*****************************************************************
* RAW-Code for some special function keys.			*
*	help    $5f						*
*	up      $4c						*
*	down    $4d						*
*	left    $4f						*
*	right   $4e						*
*	return  $44						*
*	space   $40						*
*	esc     $45						*
*	enter   $43						*
*	tab     $42						*
*****************************************************************

	ENDIF


main_play:	dc.w	0

*************************************************************************
* Configuration related data						*
*************************************************************************

	IFND	main_meteroff
	IFND	main_debugoff
	
main_framemeteron:
		move.l	main_configscr,d0
		beq.w	.exit
		tst.w	.first
		bne.s	.skip
		st.b	.first
		move.w	$dff002,main_framedma
		and.w	#%100000,main_framedma
		move.l	d0,a0
		add.l	#20480+1024,a0
		move.l	#$28d82802,(a0)+
;-------------------------------------- Sprite 6 --
		move.w	#255,d0
		move.l	#$ffff0000,d1
.fillloop:	move.l	d1,(a0)+
		dbra	d0,.fillloop
		clr.l	(a0)+		
;-------------------------------------- Sprite 7 --
		move.l	#$28d82802,(a0)+
		lea	main_framesprite,a1
		move.w	#1024/4-1,d0
.copyloop:	move.l	(a1)+,(a0)+
		dbra	d0,.copyloop
		clr.l	(a0)
		lea	$dff000,a6
.sync:		cmp.b	#$ff,$dff006
		bne.s	.sync

		move.w	#$e002,$106(a6)
		move.w	#$0f0,$1ba(a6)
		move.w	#$003,$1bc(a6)
		move.w	#$fff,$1be(a6)
.skip:		st.b	main_frameon
.exit:		rts
.first:		dc.w	0

main_framemeteroff:
		tst.w	main_framedma
		bne.s	.skip
		move.w	#%100000,$dff096
.skip:		clr.w	main_frameon
		rts

main_framedma:	dc.w	0
main_frameon:	dc.w	0


main_frameint:	tst.w	main_frameon
		beq.w	.exit
		lea	$dff000,a6
		move.w	#$8200!%100000,$96(a6)
		move.w	#$e002,$106(a6)
		move.l	#$0f00003,$1ba(a6)
		move.w	#$e002,$106(a6)
		move.w	#$fff,$1be(a6)
		move.l	main_configscr,a0
		add.l	#20480+1024,a0
		move.l	main_dataptr,a1
		move.l	48(a1),d0
		divu	#313*4,d0
		cmp.w	#255,d0
		ble.s	.ok
		move.w	#255,d0
.ok:		cmp.w	#0,d0
		bge.s	.ok4
		moveq.l	#0,d0
.ok4:
;-------------------------- d0=0-255 --
		neg.w	d0
		add.w	#255,d0
		add.w	#$28,d0
		moveq.l	#$2,d1			; CTRL
		cmp.w	#$100,d0
		blt.s	.ok1
		or.w	#$4,d1
.ok1:		move.b	d0,(a0)
		add.w	#256,d0
		cmp.w	#256+$28,d0
		ble.s	.ok2
		move.w	#256+$38,d0
.ok2:		move.b	d0,2(a0)
		move.b	d1,3(a0)
		move.w	#$3f,$104(a6)
		move.w	#$ff,$10c(a6)
		move.l	main_configscr,a0
		add.l	#20480,a0
		tst.w	main_framedma
		bne.s	.skipcl
		lea	$dff120,a6
		moveq.l	#5,d0
.loop:		move.l	a0,(a6)+
		dbra	d0,.loop
		bra.s	.cont
.skipcl:	add.l	#6*4,a6
.cont:		add.l	#1024+1024+8,a0
		move.l	a0,(a6)+
		sub.l	#1024+8,a0
		move.l	a0,(a6)		
.exit:		rts

main_framesprite:
		dc.l	$00000000,$00000000,$00000000,$00000000
		dc.l	$00000000,$00000000,$00000000,$00000000
		dc.l	$00000000,$00000000,$00000000,$00000000
		dc.l	$00000000,$00000000,$00000000,$00000000
		dc.l	$00000000,$00000000,$00000000,$00000000
		dc.l	$00000000,$00000000,$00000000,$ffff0000
		dc.l	$80012aaa,$80015554,$80012aaa,$80015554
		dc.l	$9e013eaa,$82015754,$84012eaa,$e5f11404
		dc.l	$88012aaa,$88015d54,$88012aaa,$80015554
		dc.l	$80012aaa,$80015554,$80012aaa,$803f5540
		dc.l	$80012aaa,$80015554,$80012aaa,$80015554
		dc.l	$80012aaa,$80015554,$80012aaa,$ffc10014
		dc.l	$80012aaa,$80015554,$80012aaa,$80015554
		dc.l	$80012aaa,$80015554,$80012aaa,$803f5540
		dc.l	$80012aaa,$80015554,$80012aaa,$80015554
		dc.l	$8e012eaa,$90015554,$90013aaa,$dcf11d04
		dc.l	$92013aaa,$92015754,$8c012eaa,$80015554
		dc.l	$80012aaa,$80015554,$80012aaa,$803f5540
		dc.l	$80012aaa,$80015554,$80012aaa,$80015554
		dc.l	$80012aaa,$80015554,$80012aaa,$ffc10014
		dc.l	$80012aaa,$80015554,$80012aaa,$80015554
		dc.l	$80012aaa,$80015554,$80012aaa,$803f5540
		dc.l	$80012aaa,$80015554,$80012aaa,$80015554
		dc.l	$9e013eaa,$90015554,$90013aaa,$ddf11c04
		dc.l	$82012aaa,$92015754,$8c012eaa,$80015554
		dc.l	$80012aaa,$80015554,$80012aaa,$803f5540
		dc.l	$80012aaa,$80015554,$80012aaa,$80015554
		dc.l	$80012aaa,$80015554,$80012aaa,$ffc10014
		dc.l	$80012aaa,$80015554,$80012aaa,$80015554
		dc.l	$80012aaa,$80015554,$80012aaa,$803f5540
		dc.l	$80012aaa,$80015554,$80012aaa,$80015554
		dc.l	$92013aaa,$92015754,$92013aaa,$def11f04
		dc.l	$82012aaa,$82015754,$82012aaa,$80015554
		dc.l	$80012aaa,$80015554,$80012aaa,$803f5540
		dc.l	$80012aaa,$80015554,$80012aaa,$80015554
		dc.l	$80012aaa,$80015554,$80012aaa,$ffc10014
		dc.l	$80012aaa,$80015554,$80012aaa,$80015554
		dc.l	$80012aaa,$80015554,$80012aaa,$803f5540
		dc.l	$80012aaa,$80015554,$80012aaa,$80015554
		dc.l	$8c012eaa,$92015754,$82012aaa,$ecf11d04
		dc.l	$82012aaa,$92015754,$8c012eaa,$80015554
		dc.l	$80012aaa,$80015554,$80012aaa,$803f5540
		dc.l	$80012aaa,$80015554,$80012aaa,$80015554
		dc.l	$80012aaa,$80015554,$80012aaa,$ffc10014
		dc.l	$80012aaa,$80015554,$80012aaa,$80015554
		dc.l	$80012aaa,$80015554,$80012aaa,$803f5540
		dc.l	$80012aaa,$80015554,$80012aaa,$80015554
		dc.l	$80012aaa,$8c015d54,$92013aaa,$c2f11704
		dc.l	$84012eaa,$88015d54,$9e013eaa,$80015554
		dc.l	$80012aaa,$80015554,$80012aaa,$803f5540
		dc.l	$80012aaa,$80015554,$80012aaa,$80015554
		dc.l	$80012aaa,$80015554,$80012aaa,$ffc10014
		dc.l	$80012aaa,$80015554,$80012aaa,$80015554
		dc.l	$80012aaa,$80015554,$80012aaa,$803f5540
		dc.l	$80012aaa,$80015554,$80012aaa,$80015554
		dc.l	$84012eaa,$8c015d54,$84012eaa,$f5f10404
		dc.l	$84012eaa,$84015554,$8e012eaa,$80015554
		dc.l	$80012aaa,$80015554,$80012aaa,$803f5540
		dc.l	$80012aaa,$80015554,$80012aaa,$80015554
		dc.l	$80012aaa,$80015554,$80012aaa,$ffc10014
		dc.l	$80012aaa,$80015554,$80012aaa,$80015554
		dc.l	$80012aaa,$80015554,$80012aaa,$803f5540
		dc.l	$80012aaa,$80015554,$80012aaa,$80015554
		dc.l	$80012aaa,$80015554,$80012aaa,$ffff0000
	ENDIF
	ENDIF


	IFND	MAIN_DEBUGOFF

main_contxt00:	dc.b	13,10,'  NonSystem startup v3.1 - Copyright TBL 1995.'
		dc.b	13,10,'  Debugger v1.0 - Copyright TBL 1995.'
		dc.b	13,10,13,10
		dc.b	'  Coded by Equalizer of The Black Lotus.',13,10
		dc.b	13,10
		dc.b	0
main_contxt01:	dc.b	'PC: ',0
main_contxtlf:	dc.b	10,13,0
main_contxt02:	dc.b	'D0: ',0
main_contxt03:	dc.b	'A0: ',0
main_contxt04:	dc.b	10,13,'>',0
main_contxt05:	dc.b	'                   dma: ',0
main_contxt06:	dc.b	' SR: ',0
main_contxt07:	dc.b	' intena: ',0
main_contxt08:	dc.b	' ',0
main_contxt09:	dc.b	' intreq: ',0
main_contxt10:	dc.b	'  timer: ',0
main_contxt11:	dc.b	' counter: ',0
main_contxt12:	dc.b	'                       main_counter: ',0
main_contxt13:	dc.b	0,0	
main_contxt14:	dc.b	10,13,'Unknown command !!!',10,13,0
main_contxt15:	blk.b	79,32
		dc.b	0
main_contxt16:	dc.b	'Continue program  Exit to system  View screen'
		dc.b	'  Run frame by frame   Commands',0
main_contxt17:	dc.b	13,10,'  # Help',13,10,13,10
		dc.b	"  'j'    Continue program                 "
		dc.b	"  '!'    Exit to system",13,10
		dc.b	"  'v'    View program screen              "
		dc.b	"  'f'    Run frame by frame",13,10
		dc.b	"  'hi'   Hardware info                    "
		dc.b	"  'help' Display commands",13,10
		dc.b	"  't'    View variables (Timer,Counters & Test:)",13,10
		dc.b	"  'di'   View debugger info (Version etc.)",13,10
		dc.b	"  'scop' Search fro copperlist in memory",13,10
		dc.b	"  'vcop' View copper list (Text)",13,10
		dc.b	"  'copadd' Adds 4 to copper address.",13,10
		dc.b	"  'copsub' Subtracts 4 to copper address.",13,10
		dc.b	"  'meteron' Enable frame meter.",13,10
		dc.b	"  'meteroff' Disable frame meter.",13,10
		dc.b	0	
main_contxt18:	dc.b	13,10,'  test:  ',0
main_contxt19:	dc.b	13,10,'         ',0
main_contxt20:	dc.b	'Debugger called by: ',0

main_conhexchars:dc.b	'0123456789abcdef'
main_contxthex:	dc.b	'00000000',0

	IFND	main_debugoff

main_macro0:	dc.b	27,'help',13,0
		even
main_commandlist:dc.b	'hi',0,0
		dc.l	main_conprintsi
		dc.b	'j',0
		dc.l	main_cmdcont
		dc.b	'!',0
		dc.l	main_cmdexit
		dc.b	'v',0
		dc.l	main_cmdview
		dc.b	't',0
		dc.l	main_cmdtest
		dc.b	'f',0
		dc.l	main_cmdtrace
		dc.b	'di',0,0
		dc.l	main_cmddi
		dc.b	'help',0,0
		dc.l	main_cmdhelp
		dc.b	'scop',0,0
		dc.l	main_cmdscop
		dc.b	'copadd',0,0
		dc.l	main_cmdcopadd
		dc.b	'copsub',0,0
		dc.l	main_cmdcopsub
		dc.b	'vcop',0,0
		dc.l	main_cmdcopview
		dc.b	'meteron',0
		dc.l	main_cmdmeteron
		dc.b	'meteroff',0,0
		dc.l	main_cmdmeteroff
		dc.l	0

main_mouseold:	dc.w	0
main_mousex:	dc.w	0			; X Pos
main_mousey:	dc.w	0			; Y Pos
main_mouseorgx:	dc.w	128*2			; X Org
main_mouseorgy:	dc.w	$28*2			; Y Org
main_mousesprx:	dc.w	6			; Sprite X
main_mousespry:	dc.w	6			; Sprite Y
main_mousesprptr:dc.l	0			; Sprite ptr
main_mousewidth:dc.w	640			; Sprite zone width
main_mouseheight:dc.w	512			; Sprite zone height
main_mousezone:	dc.w	-1			; Reports current mousezone

main_zonecodes:	dc.l	main_cmdcont
		dc.l	main_cmdexit
		dc.l	main_cmdview
		dc.l	main_cmdtrace
		dc.l	main_cmdhelp2

main_mousezones:dc.w	0,472,143,504
		dc.l	0
		dc.w	144,472,271,504
		dc.l	0
		dc.w	272,472,375,504
		dc.l	0
		dc.w	376,472,537,504
		dc.l	0
		dc.w	538,472,639,504
		dc.l	0
		dc.w	-1,-1,-1,-1		; No more mousezones..
		dc.l	0			; Blahhh

main_inputlength:dc.w	0		
main_inputbuffer:blk.b	128

main_mousesprite:dc.l	$48605000
		dc.w	%1001001000000000,%1000001000000000
		dc.w	%0000000000000000,%0000000000000000
		dc.w	%0000000000000000,%0001000000000000
		dc.w	%1000001000000000,%0010100000000000
		dc.w	%0000000000000000,%0001000000000000
		dc.w	%0000000000000000,%0000000000000000
		dc.w	%1001001000000000,%1000001000000000
		dc.w	%0000000000000000,%0000000000000000
		dc.l	0,0
main_curssprite:dc.l	$48605000
		dc.w	%1111000000000000,%0000000000000000
		dc.w	%1001000000000000,%0110000000000000
		dc.w	%1001000000000000,%0110000000000000
		dc.w	%1001000000000000,%0110000000000000
		dc.w	%1001000000000000,%0110000000000000
		dc.w	%1001000000000000,%0110000000000000
		dc.w	%1001000000000000,%0110000000000000
		dc.w	%1111000000000000,%0000000000000000
		dc.l	0,0	

main_confirst:	dc.w	0
main_concurx:	dc.w	0		; Config screen XCursor
main_concury:	dc.w	0		; Config screen YCursor

main_font:	dc.l	$7e666666,$66667e00,$7e666666,$66667e00
		dc.l	$7e666666,$66667e00,$7e666666,$66667e00
		dc.l	$7e666666,$66667e00,$7e666666,$66667e00
		dc.l	$7e666666,$66667e00,$7e666666,$66667e00
		dc.l	$7e666666,$66667e00,$7e666666,$66667e00
		dc.l	$7e666666,$66667e00,$7e666666,$66667e00
		dc.l	$7e666666,$66667e00,$7e666666,$66667e00
		dc.l	$7e666666,$66667e00,$7e666666,$66667e00
		dc.l	$7e666666,$66667e00,$7e666666,$66667e00
		dc.l	$7e666666,$66667e00,$7e666666,$66667e00
		dc.l	$7e666666,$66667e00,$7e666666,$66667e00
		dc.l	$7e666666,$66667e00,$7e666666,$66667e00
		dc.l	$7e666666,$66667e00,$7e666666,$66667e00
		dc.l	$7e666666,$66667e00,$7e666666,$66667e00
		dc.l	$7e666666,$66667e00,$7e666666,$66667e00
		dc.l	$7e666666,$66667e00,$7e666666,$66667e00
		dc.l	$00000000,$00000000,$183c3c18,$18001800
		dc.l	$6c6c0000,$00000000,$6c6cfe6c,$fe6c6c00
		dc.l	$183e603c,$067c1800,$00c6cc18,$3066c600
		dc.l	$386c6876,$dccc7600,$18183000,$00000000
		dc.l	$0c183030,$30180c00,$30180c0c,$0c183000
		dc.l	$00663cff,$3c660000,$0018187e,$18180000
		dc.l	$00000000,$00181830,$0000007e,$00000000
		dc.l	$00000000,$00181800,$03060c18,$3060c000
		dc.l	$3c666e7e,$76663c00,$18381818,$18187e00
		dc.l	$3c66061c,$30667e00,$3c66061c,$06663c00
		dc.l	$1c3c6ccc,$fe0c1e00,$7e607c06,$06663c00
		dc.l	$1c30607c,$66663c00,$7e66060c,$18181800
		dc.l	$3c66663c,$66663c00,$3c66663e,$060c3800
		dc.l	$00181800,$00181800,$00181800,$00181830
		dc.l	$0c183060,$30180c00,$00007e00,$007e0000
		dc.l	$30180c06,$0c183000,$3c66060c,$18001800
		dc.l	$7cc6dede,$dec07800,$183c3c66,$7ec3c300
		dc.l	$fc66667c,$6666fc00,$3c66c0c0,$c0663c00
		dc.l	$f86c6666,$666cf800,$fe666078,$6066fe00
		dc.l	$fe666078,$6060f000,$3c66c0ce,$c6663e00
		dc.l	$6666667e,$66666600,$7e181818,$18187e00
		dc.l	$0e060606,$66663c00,$e6666c78,$6c66e600
		dc.l	$f0606060,$6266fe00,$82c6eefe,$d6c6c600
		dc.l	$c6e6f6de,$cec6c600,$386cc6c6,$c66c3800
		dc.l	$fc66667c,$6060f000,$386cc6c6,$c66c3c06
		dc.l	$fc66667c,$6c66e300,$3c667038,$0e663c00
		dc.l	$7e5a1818,$18183c00,$66666666,$66663e00
		dc.l	$c3c36666,$3c3c1800,$c6c6c6d6,$feeec600
		dc.l	$c3663c18,$3c66c300,$c3c3663c,$18183c00
		dc.l	$fec68c18,$3266fe00,$3c303030,$30303c00
		dc.l	$c0603018,$0c060300,$3c0c0c0c,$0c0c3c00
		dc.l	$10386cc6,$00000000,$00000000,$000000fe
		dc.l	$18180c00,$00000000,$00003c06,$1e663b00
		dc.l	$e0606c76,$66663c00,$00003c66,$60663c00
		dc.l	$0e06366e,$66663b00,$00003c66,$7e603c00
		dc.l	$1c363078,$30307800,$00003b66,$663cc67c
		dc.l	$e0606c76,$6666e600,$18003818,$18183c00
		dc.l	$06000606,$0606663c,$e060666c,$786ce600
		dc.l	$38181818,$18183c00,$00006677,$6b636300
		dc.l	$00007c66,$66666600,$00003c66,$66663c00
		dc.l	$0000dc66,$667c60f0,$00003d66,$663e0607
		dc.l	$0000ec76,$6660f000,$00003e60,$3c067c00
		dc.l	$08183e18,$181a0c00,$00006666,$66663b00
		dc.l	$00006666,$663c1800,$0000636b,$6b363600
		dc.l	$00006336,$1c366300,$00006666,$663c1870
		dc.l	$00007e4c,$18327e00,$0e181870,$18180e00
		dc.l	$18181818,$18181800,$7018180e,$18187000
		dc.l	$729c0000,$00000000,$cc33cc33,$cc33cc33
		dc.l	$7e666666,$66667e00,$7e666666,$66667e00
		dc.l	$7e666666,$66667e00,$7e666666,$66667e00
		dc.l	$7e666666,$66667e00,$7e666666,$66667e00
		dc.l	$7e666666,$66667e00,$7e666666,$66667e00
		dc.l	$7e666666,$66667e00,$7e666666,$66667e00
		dc.l	$7e666666,$66667e00,$7e666666,$66667e00
		dc.l	$7e666666,$66667e00,$7e666666,$66667e00
		dc.l	$7e666666,$66667e00,$7e666666,$66667e00
		dc.l	$7e666666,$66667e00,$7e666666,$66667e00
		dc.l	$7e666666,$66667e00,$7e666666,$66667e00
		dc.l	$7e666666,$66667e00,$7e666666,$66667e00
		dc.l	$7e666666,$66667e00,$7e666666,$66667e00
		dc.l	$7e666666,$66667e00,$7e666666,$66667e00
		dc.l	$7e666666,$66667e00,$7e666666,$66667e00
		dc.l	$7e666666,$66667e00,$7e666666,$66667e00
		dc.l	$7e666666,$66667e00,$7e666666,$66667e00
		dc.l	$00000000,$00000000,$18001818,$3c3c1800
		dc.l	$0c3e6c6c,$3e0c0000,$1c363078,$30307e00
		dc.l	$423c663c,$42000000,$c3663c18,$3c183c00
		dc.l	$18181800,$18181800,$3c403c66,$3c023c00
		dc.l	$66000000,$00000000,$7e819db1,$b19d817e
		dc.l	$304888f8,$00fc0000,$003366cc,$66330000
		dc.l	$3e060000,$00000000,$00007e7e,$00000000
		dc.l	$7e81b9b9,$b1a9817e,$7e000000,$00000000
		dc.l	$3c663c00,$00000000,$18187e18,$18007e00
		dc.l	$f0183060,$f8000000,$f0183018,$f0000000
		dc.l	$18300000,$00000000,$0000c6c6,$c6eefac0
		dc.l	$7ef4f474,$14141400,$00001818,$00000000
		dc.l	$00000000,$00001830,$30703030,$30000000
		dc.l	$70888870,$00f80000,$00cc6633,$66cc0000
		dc.l	$2063262c,$19336701,$2063262c,$1b316207
		dc.l	$c023662c,$d9336701,$18001830,$60663c00
		dc.l	$30083c66,$7ec3c300,$0c103c66,$7ec3c300
		dc.l	$18243c66,$7ec3c300,$718e3c66,$7ec3c300
		dc.l	$c3183c66,$7ec3c300,$3c663c66,$7ec3c300
		dc.l	$1f3c3c6f,$7ccccf00,$3c66c0c0,$663c0830
		dc.l	$6010fe60,$7860fe00,$1820fe60,$7860fe00
		dc.l	$3048fe60,$7860fe00,$6600fe60,$7860fe00
		dc.l	$30087e18,$18187e00,$0c107e18,$18187e00
		dc.l	$18247e18,$18187e00,$66007e18,$18187e00
		dc.l	$f86c66f6,$666cf800,$718ec6e6,$d6cec600
		dc.l	$30083c66,$c3663c00,$0c103c66,$c3663c00
		dc.l	$18243c66,$c3663c00,$718e3c66,$c3663c00
		dc.l	$c33c66c3,$c3663c00,$0063361c,$36630000
		dc.l	$3d66cfdb,$f366bc00,$30086666,$66663e00
		dc.l	$0c106666,$66663e00,$18246666,$66663e00
		dc.l	$66006666,$66663e00,$0608c366,$3c183c00
		dc.l	$f0607e63,$637e60f0,$7c66666c,$66666c60
		dc.l	$30083c06,$1e663b00,$0c103c06,$1e663b00
		dc.l	$18243c06,$1e663b00,$718e3c06,$1e663b00
		dc.l	$33003c06,$1e663b00,$3c663c06,$1e663b00
		dc.l	$00007e1b,$7fd87700,$00003c66,$60663c10
		dc.l	$30083c66,$7e603c00,$0c103c66,$7e603c00
		dc.l	$18243c66,$7e603c00,$66003c66,$7e603c00
		dc.l	$30083818,$18183c00,$0c103818,$18183c00
		dc.l	$18243818,$18183c00,$66003818,$18183c00
		dc.l	$60fc187c,$c6c67c00,$718e7c66,$66666600
		dc.l	$30083c66,$66663c00,$0c103c66,$66663c00
		dc.l	$18243c66,$66663c00,$718e3c66,$66663c00
		dc.l	$66003c66,$66663c00,$0018007e,$00180000
		dc.l	$00013e67,$6b733e40,$30086666,$66663b00
		dc.l	$0c106666,$66663b00,$18246666,$66663b00
		dc.l	$66006666,$66663b00,$0c106666,$663c1870
		dc.l	$f0607c66,$667c60f0,$66006666,$663c1870

main_concols:	blk.w	7
		
main_configcop:	dc.l	$01009200,$01020000,$01040024,$01060000,$010c0011
		dc.l	$01fc0000,$01080000,$010a0000,$01800000,$018200f0
		dc.l	$01ba0888,$01bc0bbb,$01be0eee,$01a200d0,$01a400a0
		dc.l	$008e2881,$009028c1,$0092003c,$009400d4
main_conbplptrs:dc.l	$00e00000,$00e20000
main_consprptr:	dc.l	$01200000,$01220000,$01240000,$01260000
		dc.l	$01280000,$012a0000,$012c0000,$012e0000
		dc.l	$01300000,$01320000,$01340000,$01360000
		dc.l	$01380000,$013a0000,$013c0000,$013e0000
		dc.l	$fffffffe		
main_conoldsp:	dc.l	0
main_concounter:dc.l	0			; Up 1 every VBL

;----------------------------------------------------------- Keyboard data --

kbd_oldlevel2:	dc.l	0		; For saving level 2
kbd_reptwait:	dc.w	10		; VBL's until rept
kbd_reptspeed:	dc.w	0		; Rept speed
kbd_repttimerw:	dc.w	0		; Timer for rept wait
kbd_repttimers:	dc.w	0		; Timer for rept speed
kbd_flagcodes:	dc.b	$61,$65,$67,$66,$64,$60,$63,$62
		dc.b	$e1,$e5,$e7,$e6,$e4,$e0,$e3,$e2
kbd_realflags:	dc.b	0		; Cps,Ctl,LSh,LAlt,LAm,RAm,RAlt,RSh
kbd_flags:	dc.b	0
kbd_realraw:	dc.b	0		; Input real raw
kbd_rawkey:	dc.b	0		; The raw value of the keypress
kbd_keypressed:	dc.b	0		; Keypressed flag, 0=Not pressed
kbd_macroread:	dc.b	0		; Read from macro buffer flag.
kbd_macropos:	dc.l	0		; Macro read pos
kbd_asciikey:	dc.w	0		; Last ascii code
kbd_customptr:	dc.l	0		; Custom routine on every key event
kbd_keymapptr:	dc.l	0		; Ptr to keymap (0=Default)
kbd_macroptr:	dc.l	0		; Ptr to macro list (0=No macros)
kbd_keydefault:	dc.l	$00600031,$00320033,$00340035,$00360037
		dc.l	$00380039,$0030002b,$0027005c,$00000030
		dc.l	$00710077,$00650072,$00740079,$00750069
		dc.l	$006f0070,$00e500a8,$00000031,$00320033
		dc.l	$00610073,$00640066,$00670068,$006a006b
		dc.l	$006c00f6,$00e40027,$00000034,$00350036
		dc.l	$003c007a,$00780063,$00760062,$006e006d
		dc.l	$002c002e,$002d0000,$002e0037,$00380039
		dc.l	$00200008,$0009000d,$000d001b,$007f0000
		dc.l	$00000000,$002d0000,$00800081,$00830082
		dc.l	$00000000,$00000000,$00000000,$00000000
		dc.l	$00000000,$005b005d,$002f002a,$002b00a0
		dc.l	$00000000,$00000000,$00000000,$00000000
		dc.l	$00000000,$00000000,$00000000,$00000000
		dc.l	$00000000,$00000000,$00000000,$00000000
		dc.l	$00000000,$00000000,$00000000,$00000000
		dc.l	$007e0021,$002200a3,$00240025,$0026002f
		dc.l	$00280029,$003d003f,$006000a6,$00000030
		dc.l	$00510057,$00450052,$00540059,$00550049
		dc.l	$004f0050,$00c2005e,$00000000,$00000000
		dc.l	$00410053,$00440046,$00470048,$004a004b
		dc.l	$004c00d6,$00c4002a,$00000000,$00000000
		dc.l	$003e005a,$00580043,$00560042,$004e004d
		dc.l	$003b003a,$005f0000,$002e0000,$00000000
		dc.l	$00200000,$00090000,$000d001b,$009e0000
		dc.l	$00000000,$002d0000,$00840085,$00870086
		dc.l	$00000000,$00000000,$00000000,$00000000
		dc.l	$00000000,$007b007d,$002f002a,$002b00a1
		dc.l	$00000000,$00000000,$00000000,$00000000
		dc.l	$00000000,$00000000,$00000000,$00000000
		dc.l	$00000000,$00000000,$00000000,$00000000
		dc.l	$00000000,$00000000,$00000000,$00000000
		dc.l	$00600031,$00320033,$00340035,$00360037
		dc.l	$00380039,$0030002b,$0027005c,$00000000
		dc.l	$00710077,$00650072,$00740079,$00750069
		dc.l	$006f0070,$00e500a8,$00000000,$00000000
		dc.l	$00610073,$00640066,$00670068,$006a006b
		dc.l	$006c00f6,$00e40027,$00000000,$00000000
		dc.l	$003c007a,$00780063,$00760062,$006e006d
		dc.l	$002c002e,$002d0000,$00000000,$00000000
		dc.l	$00000000,$00000000,$00000000,$00000000
		dc.l	$00000000,$00000000,$00880089,$008b008a
		dc.l	$00000000,$00000000,$00000000,$00000000
		dc.l	$00000000,$00000000,$00000000,$000000a2
		dc.l	$00000000,$00000000,$00000000,$00000000
		dc.l	$00000000,$00000000,$00000000,$00000000
		dc.l	$00000000,$00000000,$00000000,$00000000
		dc.l	$00000000,$00000000,$00000000,$00000000
		dc.l	$00000000,$00000000,$00000000,$00000000
		dc.l	$00000000,$00000000,$00000000,$00000000
		dc.l	$00000000,$00000000,$00000000,$00000000
		dc.l	$00000000,$00000000,$00000000,$00000000
		dc.l	$00000000,$00000000,$00000000,$00000000
		dc.l	$00000000,$00000000,$00000000,$00000000
		dc.l	$00000000,$00000000,$00000000,$00000000
		dc.l	$00000000,$00000000,$00000000,$00000000
		dc.l	$00000000,$00000000,$00000000,$00000000
		dc.l	$00000000,$00000000,$00000000,$00000000
		dc.l	$00000000,$00000000,$00000000,$00000000
		dc.l	$00000000,$00000000,$00000000,$00000000
		dc.l	$00000000,$00000000,$00000000,$00000000
		dc.l	$00000000,$00000000,$00000000,$00000000
		dc.l	$00000000,$00000000,$00000000,$00000000
		dc.l	$00000000,$00000000,$00000000,$00000000
		dc.l	$006000a1,$00b200b3,$00a40000,$00000000
		dc.l	$00000000,$000000bf,$003d0000,$00000000
		dc.l	$00710077,$00e900ae,$00740079,$00750069
		dc.l	$006f0070,$00e5005e,$00000000,$00000000
		dc.l	$00bc00bd,$00be0066,$00670068,$006a006b
		dc.l	$006c002c,$002700b7,$00000000,$00000000
		dc.l	$003e007a,$007800a9,$00760062,$006e006d
		dc.l	$00ab00bb,$002f0000,$00000000,$00000000
		dc.l	$00000000,$00000000,$000d0000,$009f0000
		dc.l	$00000000,$00000000,$00960097,$00990098
		dc.l	$00000000,$00000000,$00000000,$00000000
		dc.l	$00000000,$00000000,$00000000,$000000a3
		dc.l	$00000000,$00000000,$00000000,$00000000
		dc.l	$00000000,$00000000,$00000000,$00000000
		dc.l	$00000000,$00000000,$00000000,$00000000
		dc.l	$00000000,$00000000,$00000000,$00000000
		dc.l	$007e0021,$00400023,$00240025,$005e0026
		dc.l	$002a0028,$0029005f,$002b00a6,$00000000
		dc.l	$00000000,$00c90000,$00000000,$00000000
		dc.l	$00000000,$00c5005e,$00000000,$00000000
		dc.l	$00000000,$00000000,$00000000,$00000000
		dc.l	$0000003a,$0022002a,$00000000,$00000000
		dc.l	$003e0000,$00000000,$00000000,$00000000
		dc.l	$003c003e,$003f0000,$00000000,$00000000
		dc.l	$00000000,$00000000,$00000000,$009e0000
		dc.l	$00000000,$00000000,$009a009b,$009d009c
		dc.l	$00000000,$00000000,$00000000,$00000000
		dc.l	$00000000,$00000000,$00000000,$000000a4
		blk.b	6720

kbd_buffer:	dc.b	0,0		; Head & Tail ptr
		ds.w	256		; Buffer

main_contrace:	dc.w	0			; Trace flag
main_configscr:	dc.l	0			; Ptr to bpl for configscr
main_conintena:	dc.w	0			; Config old intena
main_conintreq:	dc.w	0			; Config old intreq
main_condmacon:	dc.w	0			; Config old dma
main_configsr:	dc.w	0			; Int status reg
main_configpc:	dc.l	0			; Int userpc
main_configregs:blk.l	16			; Registers a7-d0
main_configexit:dc.w	0			; Set to 1 to close con screen
main_configscreen:dc.w	0			; Flag to indicate if config
	ENDIF
	ENDIF	; main_debugoff

*************************************************************************
* System related data							*
*************************************************************************

main_readakey:	dc.w	0			; Flag for keyread
main_vectorlist:
	IFD	main_textvaron
		dc.l	main_contxt21,0	;  1 User (Text ptr,PC add)
		dc.l	main_contxt22,0	;  2 Bus
		dc.l	main_contxt23,0	;  3 Address
		dc.l	main_contxt24,2	;  4 Illegal
		dc.l	main_contxt25,0	;  5 Div
		dc.l	main_contxt26,0	;  6 CHK
		dc.l	main_contxt27,0	;  7 TRAPV
		dc.l	main_contxt28,0	;  8 Privilege
		dc.l	main_contxt29,0	;  9 Trace
		dc.l	main_contxt30,2	; 10 Axxx
		dc.l	main_contxt31,2	; 11 Fxxx
		dc.l	main_contxt32,0	; 12 Requierment no ok
		dc.l	main_contxt33,0	; 13 Level 7 external int
		dc.l	main_contxt34,0	; 14 End of program
		dc.l	main_contxt35,0	; 15 Error loading file
	ENDIF

main_counter2:	dc.l	0
main_usersr:	dc.w	0			; Int status reg
main_userpc:	dc.l	0			; Int userpc
main_registers:	blk.l	16			; Registers a7-d0
main_oldvectors:blk.l	17			; Space for system vectors
main_oldintena:	dc.w	0			; saved intena
main_oldintreq:	dc.w	0			; saved intreq
main_olddmacon:	dc.w	0			; saved dmacon
main_oldadkcon:	dc.w	0			; saved adkcon
main_oldactscreen:dc.l	0			; Saved actscreen
main_oldcopper1:dc.l	0			; Ptr to syscop 1
main_oldcopper2:dc.l	0			; Ptr to syscop 2
main_oldbeamcon:dc.w	0			; Old beamcontrol bits
main_novbl:	dc.w	0			; Clr to run VBL
main_forcedebug:dc.w	0			; Not 0=Debug mode forced
	ENDIF	; main_systemon  (VERY large IF)


main_printok:	dc.b	0			; Print flag
main_conuse:	dc.b	0			; Console use flag
main_gfxhandler:dc.l	0			; Graphics handler
main_erraddy:	dc.l	0			; On fail jump to addy..
main_errsp:	dc.l	0			; On fail new sp
main_argv:	dc.l	0			; Ptr to arguments
main_cachereg:	dc.l	0			; Cache reg ptr
main_cacheok:	dc.w	0			; Ok 2 reset cache ?
		IFND	main_short
test:		blk.l	16			; Test block
		ENDIF
		

		IFND	main_skipsysinfo
main_processor:	dc.w	0			; Processor 0=00,1=10 etc
main_coproc:	dc.w	0			; Math coprocessor 1=Yes
main_mmu:	dc.w	0			; MMU 1=Yes
main_aga:	dc.w	0			; AGA chipset 1=Yes
main_ecs:	dc.w	0			; ECH chipset 1=Yes
main_chipmem:	dc.l	0			; Chip mem
main_fastmem:	dc.l	0			; Fast mem
main_availfast:	dc.l	0			; Largest Fast
main_availchip:	dc.l	0			; Largest chip

main_refresh:	dc.w	0			; VBL Refresh rate
main_powerfreq:	dc.w	0			; Power frequency
main_sysflags:	dc.w	0			; System flags
main_ok2run:	dc.w	0
		ENDIF

	IFND	main_short
main_argcount:	dc.l	0
main_arglist:	blk.l	16
main_timer2:	dc.l	0	; Last timer value
main_savecount:	dc.l	0
main_savecount2:dc.l	0
	ENDIF

*************************************************************************
* Text related data							*
*************************************************************************

main_lastkey:		dc.b	0
main_doslibname:	dc.b	'dos.library',0		; Doslib name
main_gfxlibname:	dc.b	'graphics.library',0	; GfxLib name
main_consolname:	dc.b	'con:0/0/640/256/'	; Console name
main_progname:	IFND	main_programname
			dc.b	'NoName',0		; Program name
		ELSE
			main_programname		; Own prog name
			dc.b	0
		ENDIF


	IFD	main_textvaron
		even
main_powptr:	dc.l	main_txtpow50		; Power freq text ptr
main_refreshptr:dc.l	main_txtvbl50		; Ptr to refresh rate text
main_gfxptr:	dc.l	main_txtgfxorg		; Ptr to Gfx chip text
main_procptr:	dc.l	main_txt68000		; Processor text ptr
main_coprocptr:	dc.l	main_txtnone		; Math coproc. text ptr
main_mmuptr:	dc.l	main_txtnone		; MMU text ptr

main_contxt21:	dc.b	'User                    ',0
main_contxt22:	dc.b	'Bus error               ',0
main_contxt23:	dc.b	'Address error           ',0
main_contxt24:	dc.b	'Illegal instruction     ',0
main_contxt25:	dc.b	'Division by zero error  ',0
main_contxt26:	dc.b	'CHK command             ',0
main_contxt27:	dc.b	'TRAPV command           ',0
main_contxt28:	dc.b	'Privilege violation     ',0
main_contxt29:	dc.b	'Trace                   ',0
main_contxt30:	dc.b	'Axxx command emulation  ',0
main_contxt31:	dc.b	'Fxxx command emulation  ',0
main_contxt32:	dc.b	'Hardware to lame =8)    ',0
main_contxt33:	dc.b	'Level 7 external break  ',0
main_contxt34:	dc.b	'End of program reached  ',0
main_contxt35:	dc.b	'Error loading file      ',0

main_txtnoreq:	dc.b	10,13,'  No requierments needed',10,13,0
main_txtreqpass:dc.b	10,13,10,13,'  Requirement test passed.',10,13,0
main_txtreqfault:dc.b	10,13,10,13,'  Requirement test failed !!! (lamer:)'
		dc.b	10,13,0
main_txthi:	dc.b	'-- Hardware Info --------------------------------'
		dc.b	0
main_txtreq:	dc.b	'-- Hardware Requirements ------------------------'
		dc.b	0
main_txtendc:	dc.b	'-- Exit Info ------------------------------------'
		dc.b	10,13,'  Program terminated by: ',0
main_txtafter:	dc.b	10,13,'  Total running length:  ',0
main_txtminute:dc.b	' minute ',0
main_txtminutes:dc.b	' minutes ',0
main_txtsecond:	dc.b	' second',0
main_txtseconds:dc.b	' seconds',0
main_txtand:	dc.b	'and ',0
main_txtnonetime:dc.b	'0 seconds',0
main_txtend:	dc.b	10,13
main_txtblank:	dc.b	'-------------------------------------------------'
		dc.b	10,13,0
main_txtplus:	dc.b	'+ ',0
main_txtpassed:	dc.b	'.. passed',0
main_txtfault:	dc.b	'.. failed',0
main_txtecsplus:dc.b	'ECS+ ',0
main_txtagaplus:dc.b	'AGA+ ',0
main_txt68000:	dc.b	'68000',0
main_txt68010:	dc.b	'68010',0
main_txt68020:	dc.b	'68020',0
main_txt68030:	dc.b	'68030',0
main_txt68040:	dc.b	'68040',0
main_txt68060:	dc.b	'68060',0
main_txt68881:	dc.b	'68881',0
main_txt68882:	dc.b	'68882',0
main_txt68040b:	dc.b	'68040 built in',0
main_txt68060b:	dc.b	'68060 built in',0
main_txt68851:	dc.b	'68851',0
main_txtvbl50:	dc.b	'PAL (50 Hz) ',0
main_txtvbl60:	dc.b	'NTSC (60 Hz) ',0
main_txtpow50:	dc.b	'50 Hz',0
main_txtpow60:	dc.b	'60 Hz',0
main_txtgfxorg:	dc.b	'Original Denise (8362)',0
main_txtgfxecs:	dc.b	'Extended chipset (ECS Denise 8373)',0
main_txtgfxaga:	dc.b	'AGA chipset (Lisa)',0
main_txtkb:	dc.b	'kb ',0
main_txtfast:	dc.b	10,13,'  Fast-RAM needed: ',0
main_txtchip:	dc.b	10,13,'  Chip-RAM needed: ',0
main_txtpower:	dc.b	10,13,'  Power frequency: ',0
main_txtproc:	dc.b	10,13,'  Processor:       ',0
main_txtcoproc:	dc.b	10,13,'  Math processor:  ',0
main_txtmmu:	dc.b	10,13,'  MMU:             ',0
main_txtaga:	dc.b	10,13,'  Graphic chipset: ',0
main_txtvbl:	dc.b	10,13,'  Video frequency: ',0
main_txtmemchip:dc.b	10,13,10,13,'  Chipmem:         ',0
main_txtmemfast:dc.b	' kb',10,13,'  Fastmem:         ',0
main_txtcache:	dc.b	'  All caches disabled.',0
main_txtnone:	dc.b	'None',0
main_txtlf:	dc.b	10,13,0
main_txtkblf:	dc.b	' kb',10,13,0
main_txtdec:	dc.b	0,0,0,0,0,0,0,0,0,0,0,0
		even
	ENDIF
		even
	ENDIF
		cnop	8,8

main_start:	
