				align 4
; Initialises the level mods data
; For now, this is just the sky backdrop override data
Lvl_InitLevelMods:
				tst.l	Lvl_ModPropertiesPtr_l
				beq.s	Lvl_ClearBackdropDisable
				bra.s	Lvl_FillBackdropDisable

; Clears out the Zone_BackdropDisable_vb data
; Preserves registers
Lvl_ClearBackdropDisable:
				movem.l		d0/a0,-(sp)
				move.w		#ZONE_BACKDROP_DISABLE_SIZE/16-1,d0
				lea			Zone_BackdropDisable_vb,a0

.clear_loop:
				clr.l		(a0)+
				clr.l		(a0)+
				clr.l		(a0)+
				clr.l		(a0)+
				dbra		d0,.clear_loop

				movem.l		(sp)+,d0/a0
				rts


; Fills the Zone_BackdropDisable_vb data from the loaded properties data
; Preserves registers
Lvl_FillBackdropDisable:
				movem.l		d0/a0/a1,-(sp)

				move.w		#ZONE_BACKDROP_DISABLE_SIZE/16-1,d0
				move.l		Lvl_ModPropertiesPtr_l,a0
				lea			Zone_BackdropDisable_vb,a1

.copy_loop:
				move.l		(a0)+,(a1)+
				move.l		(a0)+,(a1)+
				move.l		(a0)+,(a1)+
				move.l		(a0)+,(a1)+
				dbra		d0,.copy_loop

				movem.l		(sp)+,d0/a0/a1
				rts

				IFD DEV

; In devmode, we can dump the current sky disable table to ram disk
; We do this so that we can quicky edit the data in the game and incorporate later
Lvl_DumpBackdropDisableData:

				movem.l	d0-d4/a0/a1/a6,-(a7)

				move.l	#.backdrop_disable_dumpfile_vb,d1
				move.l	#MODE_READWRITE,d2
				CALLDOS	Open

				move.l	d0,d1 ; file handle handle in d1
				beq.s	.io_error

				move.l	d0,d4

				move.l	#Zone_BackdropDisable_vb,d2
				move.l	#ZONE_BACKDROP_DISABLE_SIZE,d3

				CALLDOS	Write

				;move.l	d0,d2 ; bytes written - what can we even do if this went wrong?

				move.l	d4,d1 ; d1 trashed by read
				CALLDOS Close

.io_error:
				movem.l	(a7)+,d0-d4/a0/a1/a6


				rts

.backdrop_disable_dumpfile_vb:
				dc.b	"ram:backdrop_disable.dat",0


				ENDC
