main_debugoff
main_sysinfooff
main_reqinfooff
main_endinfooff
;main_disabledos
main_playeroff
main_meteroff

mnu_nowait		;		Skip					the "waiting for opp.."
macro_sync:		MACRO	;						Kills: d7 --			Macro_Sync
				IFND	main_meteroff
				movem.l	d0-a0,-(a7)
				move.l	main_dataptr,a0
				move.l	44(a0),a0
				jsr		(a0)
				move.l	main_dataptr,a0
				move.l	d0,48(a0)
				ENDC
.waitsync\@:	move.l	vposr+_custom,d7
				and.l	#$1ff00,d7
				cmp.l	#305*$100,d7
				bne.s	.waitsync\@
				IFND	main_meteroff
				move.l	main_dataptr,a0
				move.l	40(a0),a0
				jsr		(a0)
				movem.l	(a7)+,d0-a0
				ENDC
				ENDM

WAITBLIT:		MACRO
.wait\@			tst.b	mnu_bltbusy
				bne.s	.wait\@
				ENDM

;		include	"demo:System/Main_V3.82.S"

mnu_start:
				bsr.w	mnu_copycredz
				CALLC	mnu_setscreen
				move.l	a7,mnu_mainstack

				;bsr.w	mnu_viewcredz
				;bsr.w	mnu_cls        WaitTOF();
				;IFND	mnu_nocode
				;bsr.w	mnu_protection
				;ENDC

mnu_loop:
				lea		mnu_mainmenu,a0
				bsr.w	mnu_domenu

				lea		mnu_quitmenu,a0
				bsr.w	mnu_domenu
				bra.w	mnu_loop

mnu_exit:
				move.l	mnu_mainstack,a7
				moveq	#1,d0 ; Fade out
				CALLC	mnu_clearscreen
				rts

mnu_viewcredz:
				clr.l	counter
				bsr.w	mnu_copycredz

.w8key:
				jsr		key_readkey
				cmp.l	#50*10,counter
				beq.s	.exit

				tst.w	d0
				beq.s	.w8key

.exit:
				rts

mnu_copycredz:
				lea		mnu_frame,a0
				lea		mnu_morescreen+3*40*SCREEN_HEIGHT+32*40,a1
				move.w	#10*192-1,d0

.loop:
				move.l	(a0)+,(a1)+
				move.l	40*192-4(a0),40*SCREEN_HEIGHT-4(a1)
				move.l	2*40*192-4(a0),2*40*SCREEN_HEIGHT-4(a1)
				dbra	d0,.loop
				rts

				IFND BUILD_WITH_C
; Input: d0 = fade?
mnu_clearscreen:
				; Note: mnu_clearscreen is called on exit even if the menu isn't active
				; So exit out early if that's the case.
				tst.l	MenuScreen
				beq		.noScreen
				tst.b	d0
				beq		.fade_done
				bsr.w	mnu_fadeout

.fade_done:
				clr.l	main_vblint				; prevent VBL kicking off new blits
				WAITBLIT
				CALLGRAF WaitTOF
				move.l	MenuWindow,d0
				beq.s	.noWindow
				move.l	d0,a0
				CALLINT	CloseWindow				; FIXME: may have to clear the Window's event queue first
				clr.l	MenuWindow

.noWindow:
				move.l	MenuScreen,d0
				beq.s	.noScreen
				move.l	d0,a0
				CALLINT	CloseScreen
				clr.l	MenuScreen

.noScreen:
				rts

mnu_setscreen:
				lea		Bitmap,a0
				moveq.l	#8,d0
				move.l	#SCREEN_WIDTH,d1
				move.l	#SCREEN_HEIGHT,d2
				CALLGRAF InitBitMap

				lea		Bitmap+bm_Planes,a0		; provide "fake" bitplane pointers such that
				move.w	#7,d0					; opening the screen/window will not overwrite

.setPlane:
				move.l	#mnu_morescreen,(a0)+	; the hardcoded background pattern
				dbra	d0,.setPlane

				sub.l	a0,a0
				lea		ScreenTags,a1
				CALLINT	OpenScreenTagList
				move.l	d0,MenuScreen
				; need a window to be able to clear out mouse pointer
				; may later also serve as IDCMP input source
				sub.l	a0,a0
				lea		WindowTags,a1
				move.l	d0,WTagScreenPtr-WindowTags(a1) ; WA_CustomScreen
				CALLINT	OpenWindowTagList
				move.l	d0,MenuWindow
				move.l	d0,a0
				lea		emptySprite,a1
				moveq	#1,d0
				moveq	#16,d1
				move.l	d0,d2
				move.l	d0,d3
				CALLINT	SetPointer

				; we open the Window pixel size to prevent it from clearing
				; the screen immediately. This resizes the window to fullscreen.
				; FIXME: doesn't work. When first input is received, the window clear happens.
				; But opening the window pixel sized already did the trick...
				;move.l	MenuWindow,a0
				;clr.l	d0
				;move.l	d0,d1
				;move.l	#SCREEN_WIDTH,d2
				;move.l	#SCREEN_HEIGHT,d3
				;CALLINT ChangeWindowBox

				CALLC	mnu_init
				clr.w	mnu_fadefactor
				bsr.w	mnu_fade

				move.l	#mnu_vblint,main_vblint
				bsr.w	mnu_fadein
				rts
				ENDIF

_mnu_vblint::
mnu_vblint:		CALLC	mnu_movescreen
				CALLC	mnu_dofire
				bsr.w	mnu_animcursor
				bsr.w	mnu_plot
				rts

				IFND	BUILD_WITH_C
mnu_init:
				bsr.w	mnu_initrnd				; Uses palette buffer
				bsr.w	mnu_createpalette

				; copy menu background (2bitplanes) a second time underneath (for scrolling meny background)
				; At the same time, this "moves" the second plane one screen downwards
				lea		mnu_background,a0
				lea		mnu_background+40*SCREEN_HEIGHT,a1
				lea		mnu_screen,a2
				lea		40*SCREEN_HEIGHT*1(a2),a3
				lea		40*SCREEN_HEIGHT*2(a2),a4
				lea		40*SCREEN_HEIGHT*3(a2),a5
				move.w	#40*SCREEN_HEIGHT/4-1,d1			; one screen worth in longwords

.fsloop:
				move.l	(a0)+,d0
				move.l	d0,(a2)+
				move.l	d0,(a3)+
				move.l	(a1)+,d0
				move.l	d0,(a4)+
				move.l	d0,(a5)+
				dbra	d1,.fsloop
;-------------------------------------------------------------- Clear screen --
				lea		mnu_morescreen,a0
				move.l	#40*SCREEN_HEIGHT*3/16-1,d0
				moveq.l	#0,d1

.clrloop:
				REPT	4
				move.l	d1,(a0)+
				ENDR
				dbra	d0,.clrloop
				bsr.w	mnu_cls

;--------------------------------------------------------------- Set bplptrs --

				move.l	MenuScreen,a1
				lea		sc_ViewPort(a1),a1
				move.l	a1,a0
				move.l	vp_RasInfo(a1),a1
				move.l	ri_BitMap(a1),a1
				lea		bm_Planes(a1),a1

				move.l	#mnu_screen,d0
				moveq.l	#0,d1
				bsr.w	.setbplptrs
				move.l	#mnu_screen+40*SCREEN_HEIGHT*2,d0
				moveq.l	#0,d1
				bsr.w	.setbplptrs
				move.l	#mnu_morescreen,d0
				moveq.l	#5,d1
				bsr.s	.setbplptrs

				; This makes Intuition re-evaluate the bitmap pointers
				; viewport still in a0
				CALLGRAF ScrollVPort

				rts

.setbplptrs:
				move.l	d0,(a1)+
				add.l	#40*SCREEN_HEIGHT,d0
				dbra	d1,.setbplptrs
				rts

				ENDIF

_mnu_initrnd::
mnu_initrnd:
				lea		mnu_palette+256,a1
				move.w	#255,d0

.parityloop:
				move.b	d0,d1
				and.w	#$1,d1
				move.b	d0,d2
				lsr.w	#2,d2
				and.w	#$1,d2
				eor.w	d2,d1
				move.b	d0,d2
				lsr.w	#3,d2
				and.w	#$1,d2
				eor.w	d2,d1
				move.b	d0,d2
				lsr.w	#5,d2
				and.w	#$1,d2
				eor.w	d2,d1
				move.b	d1,-(a1)
				dbra	d0,.parityloop
				move.l	a1,a4					; a4=Parity buffer
				move.l	#'TBL!',d3				; Random seed
				lea		mnu_morescreen+6*40*256,a0
				move.w	#40*256+8192-1,d0

.loop:
				moveq.l	#0,d1					; d1=0
				move.l	d3,d2					; d2=Random seed
				move.b	d2,d1
				and.b	#$fe,d2
				move.b	(a4,d1.l),d1
				or.b	d1,d2
				ror.w	#1,d2
				swap.w	d2
				move.b	d2,d1
				and.b	#$fe,d2
				move.b	(a4,d1.l),d1
				or.b	d1,d2
				ror.w	#1,d2
				move.l	d2,d3
				move.w	d2,d1
				lsr.w	#8,d1
				or.w	d1,d2
				move.l	d2,d1
				swap.w	d1
				or.w	d1,d2
				move.b	d2,(a0)+
				dbra	d0,.loop
				rts

				IFND BUILD_WITH_C

				; scroll first two bitplanes
mnu_movescreen:
				move.l	MenuScreen,a1
				lea		sc_ViewPort(a1),a1
				move.l	a1,a0
				move.l	vp_RasInfo(a1),a1
				move.l	ri_BitMap(a1),a1
				lea		bm_Planes(a1),a1
				move.w	mnu_screenpos,d0
				and.w	#$ff,d0
				mulu	#40,d0
				add.l	#mnu_screen,d0
				moveq.l	#1,d1

.loop:
				move.l	d0,(a1)+
				add.l	#40*256*2,d0
				dbra	d1,.loop

				addq.w	#1,mnu_screenpos

				; This makes Intuition re-evaluate the bitmap pointers
				; viewport still in a0
				CALLGRAF ScrollVPort

				rts

				; Stitch a 24bit palette together such that the background
mnu_createpalette:
				lea		mnu_backpal,a0
				lea		mnu_firepal,a1
				lea		mnu_fontpal,a2
				lea		mnu_palette+256*4,a3
				move.w	#255,d0

.loop:
				move.w	d0,d1
				and.w	#$e0,d1
				beq.s	.next
				lsr.w	#5,d1
				move.l	(a2,d1.w*4),-(a3)
				bra.s	.cont

.next:
				move.w	d0,d1
				and.w	#$1c,d1
				beq.s	.next1
				lsr.w	#2,d1
				move.w	d0,d2
				and.w	#$3,d2
				moveq	#0,d3
				move.b	3(a1,d1.w*4),d3
				moveq	#0,d4
				move.b	3(a1,d2.w*4),d4
				add.w	d4,d3
				cmp.w	#255,d3
				ble.s	.okmax1
				move.b	#255,d3

.okmax1:
				move.b	d3,-(a3)
				moveq	#0,d3
				move.b	2(a1,d1.w*4),d3
				muls	#3,d3
				asr.w	#2,d3
				moveq	#0,d4
				move.b	2(a1,d2.w*4),d4
				add.w	d4,d3
				cmp.w	#255,d3
				ble.s	.okmax2

				move.b	#255,d3

.okmax2:
				move.b	d3,-(a3)
				moveq	#0,d3
				move.b	1(a1,d1.w*4),d3
				moveq	#0,d4
				move.b	1(a1,d2.w*4),d4
				add.w	d4,d3
				cmp.w	#255,d3
				ble.s	.okmax3

				move.b	#255,d3

.okmax3:
				move.w	d3,-(a3)

;		move.l	(a1,d1.w*4),-(a3)
				bra.s	.cont
.next1:
				move.w	d0,d1
				and.w	#$3,d1
				move.l	(a0,d1.w*4),-(a3)

.cont:
				dbra	d0,.loop
				rts

mnu_fadespeed	equ		16

_mnu_fadein::
mnu_fadein:
				clr.w	mnu_fadefactor
				moveq.l	#256/mnu_fadespeed-1,d0
.loop:
				move.l	d0,-(a7)

				; Ramp up at discreet steps
				CALLGRAF WaitTOF
				bsr.w	mnu_fade

				add.w	#mnu_fadespeed,mnu_fadefactor
				move.l	(a7)+,d0
				dbra	d0,.loop

				; One pass to make sure we're hitting the RGB * 1.0 case
				move.w	#255,mnu_fadefactor
				CALLGRAF WaitTOF
				bsr.w	mnu_fade

				rts

_mnu_fadeout::
mnu_fadeout:
				move.w	#256,mnu_fadefactor
				moveq.l	#256/mnu_fadespeed-1,d0
.loop:
				move.l	d0,-(a7)

				; Ramp down at discreet steps
				CALLGRAF WaitTOF
				bsr.w	mnu_fade

				sub.w	#mnu_fadespeed,mnu_fadefactor
				move.l	(a7)+,d0
				dbra	d0,.loop

				; One pass to make sure we're hitting the RGB * 0.0 case
				clr.w	mnu_fadefactor
				CALLGRAF WaitTOF
				bsr.w	mnu_fade
				rts

_mnu_fadefactor::
mnu_fadefactor:
				dc.w	0

mnu_fade:
				lea		mnu_palette,a2
				move.w	mnu_fadefactor,d3
				sub.l	#256*4*3+2+2+4+4,a7		; reserve stack for 256 color entries + numColors + firstColor
				move.l	a7,a1
				move.l	a7,a0
				move.w	#256,(a0)+				; number of entries
				move.w	#0,(a0)+				; start index
				move.w	#256-1,d0

.setCol:
				move.l	(a2)+,d1
				move.l	d1,d2
				andi.l	#$00FF0000,d2
				swap	d2
				mulu.w	d3,d2					; bits 16-23 end up in 24-31
				swap	d2
				move.l	d2,(a0)+
				move.l	d1,d2
				andi.l	#$0000FF00,d2
				mulu.w	d3,d2
				lsl.l	#8,d2					; shift up to 24-31
				move.l	d2,(a0)+				; this has some stuff in lower word, butt hey'll be discarded
				andi.l	#$000000FF,d1
				mulu.w	d3,d1
				swap	d1
				move.l	d1,(a0)+				; same here
				dbra	d0,.setCol

				clr.l	(a0)					; terminate list
				move.l	MenuScreen,a0
				lea		sc_ViewPort(a0),a0
				CALLGRAF LoadRGB32				; a1 still points to start of palette

				add.l	#256*4*3+2+2+4+4,a7		;restore stack
				rts
				ENDIF


mnu_printxy:;in:a0,d0,d1=Text ptr,XPos,YPos (XPos in words YPos in pixels)
				lea		mnu_font,a3
				lea		mnu_font+176*40,a4
				lea		mnu_font+176*40*2,a5
				moveq.l	#40,d7
				moveq.l	#20,d6
				move.l	#40*16,d5
				mulu	d7,d1
				add.w	d0,d1
				add.l	#mnu_morescreen+40*256*3,d1
				move.l	d1,a1					; a1=Ptr
				move.l	a1,a2
.loop:
				move.b	(a0)+,d2
				beq		.exit
				move.l	mnu_printdelay,timer	; wait a few VBLANKs

.w8a:
				tst.l	timer
				bne.s	.w8a
				and.l	#$ff,d2
				sub.w	#32,d2
				bge.s	.ok
				move.l	a2,a1
				add.l	#20*40,a1
				move.l	a1,a2
				bra.s	.loop
.ok:
				divu	d6,d2
				move.w	d2,d3					; d3=Y
				swap.w	d2						; d2=X
				mulu	d5,d3					; d3=Y Addy
				lsl.w	#1,d2
				add.w	d2,d3					; d3=Addy Offset
				move.l	a1,a6
				moveq.l	#15,d2
.yloop:
				move.w	(a3,d3.l),(a6)
				move.w	(a4,d3.l),40*256(a6)
				move.w	(a5,d3.l),40*256*2(a6)
				add.l	d7,d3
				add.l	d7,a6
				dbra	d2,.yloop

				addq.l	#2,a1
				bra		.loop
.exit:
				rts

				IFND BUILD_WITH_C

mnu_dofire:
				btst.b	#0,main_counter+3
				beq.s	.noskip
				rts

.noskip:
				move.w	_custom+vhposr,d0
				add.w	d0,mnu_rnd

				tst.b	mnu_bltbusy
				beq.s	.blitAgain
				rts

.blitAgain:
				lea		mnu_sourceptrs,a0		; rotate fire bitplanes
				move.l	(a0),d0
				move.l	4(a0),(a0)
				move.l	8(a0),4(a0)
				move.l	d0,8(a0)
				st.b	mnu_bltbusy
				lea		BltNode,a1
				; FIMXE: can I call this from a VBL interrupt?
				CALLGRAF QBSBlit
				rts

				ENDIF

_getrnd::
getrnd:
				moveq.l	#0,d0
				move.w	mnu_rnd,d0
				and.l	#8190,d0
				add.l	#mnu_morescreen+6*40*256,d0
				move.l	d0,mnu_rndptr
				addq.w	#5,mnu_rnd
				rts

.rnd:
				dc.w	0

_mnu_rnd::
mnu_rnd:
				dc.w	0
_mnu_bltbusy::
mnu_bltbusy:
				dc.w	0


mnu_speed		equ		1
mnu_size		equ		256

				IFND BUILD_WITH_C

mnu_subtract:
				dc.l	0
mnu_count:
				dc.w	0

				cnop	0,4

mnu_pass1:
				bsr.w	getrnd
				clr.l	mnu_subtract
				move.w	mnu_count,d0
				addq.w	#1,mnu_count
				and.w	#$3,d0
				beq.s	.l1
				cmp.w	#1,d0
				bne.s	.normal
				move.l	#-2,mnu_subtract
				move.l	#$fff80000,bltcon0(a0)	; D=A+BC
				bra.s	.cont
.l1:
				move.l	#$1ff80000,bltcon0(a0)	; D=A+BC
				bra.s	.cont
.normal:
				move.l	#$0ff80000,bltcon0(a0)	; D=A+BC
.cont:
				move.l	#$ffffffff,bltafwm(a0)	; Masks A
				move.l	#$00000000,bltcmod(a0)	; CB modulo
				move.l	#$00000000,bltamod(a0)	; AD modulo
				move.l	#mnu_morescreen+mnu_speed*40,bltcpt(a0) ; Source C
				move.l	mnu_rndptr,bltbpt(a0)	; Source B
				move.l	mnu_sourceptrs,d0
				sub.l	mnu_subtract,d0
				move.l	d0,bltapt(a0)			; Source A
				move.l	#mnu_morescreen,bltdpt(a0) ; Dest D
				move.w	#(mnu_size-mnu_speed)*64+20,bltsize(a0) ; Size and trigger
				; continue with next pass
				move.l	#mnu_pass2,bn_function(a1)
				moveq.l	#1,d0
				rts

				cnop	0,4
mnu_pass2:
				bsr.w	getrnd
				move.l	#mnu_morescreen+40*256+mnu_speed*40,bltcpt(a0) ; Source C
				move.l	mnu_rndptr,bltbpt(a0)	; Source B
				move.l	mnu_sourceptrs+4,d0
				sub.l	mnu_subtract,d0
				move.l	d0,bltapt(a0)			; Source A
				move.l	#mnu_morescreen+40*256,bltdpt(a0) ; Dest D
				move.w	#(mnu_size-mnu_speed)*64+20,bltsize(a0) ; Size and trigger
				; continue with next pass
				move.l	#mnu_pass3,bn_function(a1)
				moveq.l	#1,d0
				rts

				cnop	0,4
mnu_pass3:
				bsr.w	getrnd
				move.l	#mnu_morescreen+40*256*2+mnu_speed*40,bltcpt(a0) ; Source C
				move.l	mnu_rndptr,bltbpt(a0)	; Source B
				move.l	mnu_sourceptrs+8,d0
				sub.l	mnu_subtract,d0
				move.l	d0,bltapt(a0)			; Source A
				move.l	#mnu_morescreen+40*256*2,bltdpt(a0) ; Dest D
				move.w	#(mnu_size-mnu_speed)*64+20,bltsize(a0) ; Size and trigger

				move.l	#mnu_pass4,bn_function(a1)
				moveq.l	#1,d0
				rts

				cnop	0,4
mnu_pass4:
				move.l	#mnu_pass1,bn_function(a1) ; restore first pass ptr
				clr.b	mnu_bltbusy
				moveq.l	#0,d0					; this was the last pass
				rts

				ENDIF

				cnop	0,4
mnu_cls:
				lea		mnu_morescreen+40*256*6,a1 ; start from 6th plane, down to plane 3
				moveq.l	#0,d1
				move.w	#40*256*3/16-1,d0
.loop:
				REPT	4
				move.l	d1,-(a1)
				ENDR
				dbra	d0,.loop
				rts

mnu_animcursor:
				btst	#0,main_counter+3
				beq.s	.skip
				move.l	mnu_frameptr,a0
				move.b	(a0),mnu_arrow
				tst.b	1(a0)
				beq.s	.skip
				cmp.b	#40,1(a0)
				bhi.s	.ok
				moveq.l	#0,d0
				move.b	1(a0),d0
				sub.l	d0,mnu_frameptr
.ok:
				addq.l	#1,mnu_frameptr
.skip:
				rts


mnu_domenu:;in:	a0=Menu	ptr
;		bsr.w	key_flushbuffer
.redraw:
				move.l	a0,-(a7)
				bsr.w	mnu_openmenu			; Open new menu
				move.l	(a7)+,a0

.loop:
				movem.l	a0,-(a7)
				bsr.w	mnu_update
				movem.l	(a7)+,a0
				move.l	a0,-(a7)
				bsr.w	mnu_waitmenu			; Wait for option
				move.l	(a7)+,a0
				moveq.l	#0,d2
				move.w	mnu_row,d2
				divu	14(a0),d2
				swap.w	d2
				move.w	d2,mnu_currentsel
				tst.l	d1
				beq.s	.ok
				cmp.w	#42,d1
				beq.w	.left
				cmp.w	#41,d1
				beq.w	.right

.ok:
				cmp.w	#-1,d0					; Esc ???
				beq.w	.exit					; Yepp exit
				move.l	16(a0,d0.w*8),d1		; Get option type
				tst.l	d1						; 0=Do Nothing ???
				beq.s	.loop
				cmp.l	#1,d1					; 1=Sub menu
				beq.w	.newmenu
				cmp.l	#2,d1					; 2=Exit sub
				beq.w	.exit
				cmp.l	#3,d1
				beq.w	.bsr
				cmp.l	#4,d1
				beq.w	.left
				cmp.l	#5,d1
				beq.w	.leftsl
				cmp.l	#6,d1
				beq.w	.jump
				cmp.l	#7,d1
				beq.w	.changemenu
				cmp.l	#8,d1
				beq.w	.doraw
				cmp.l	#9,d1
				beq.w	.doload
				cmp.l	#10,d1
				beq.w	.dosave

.wrong:
				move.l	#mnu_errcursanim,mnu_frameptr
				bra.w	.loop					; Strange option ??? Loop

.dosave:
				movem.l	d0-a6,-(a7)
				move.l	20(a0,d0.w*8),a0
				move.w	mnu_currentlevel,(a0)
				bsr.w	mnu_savelevel
				movem.l	(a7)+,d0-a6
;	bra.w	.loop
				bra.w	.exit

.doload:
				movem.l	d0-a6,-(a7)
				move.l	20(a0,d0.w*8),a0
				move.w	(a0),mnu_currentlevel
				bsr.w	mnu_loadlevel
				movem.l	(a7)+,d0-a6
;bra.w	.loop
				bra.w	.exit

.doraw:
				movem.l	d0-a6,-(a7)
				move.l	#mnu_buttonanim,mnu_frameptr
				move.l	20(a0,d0.w*8),a0

.rawloop:
				move.l	a0,-(a7)
				bsr.w	mnu_getrawvalue
				move.l	(a7)+,a0
				cmp.w	(a0),d0
				beq.s	.rawcont
				cmp.w	#69,d0
				beq.s	.rawcont
				lea		mnu_rawkeys,a1

.tstraw:
				move.w	(a1)+,d1
				cmp.w	#$ffff,d1
				beq.s	.rawok
				cmp.w	d0,d1
				bne.s	.tstraw
				move.l	#mnu_errbutanim,mnu_frameptr
				bra.s	.rawloop

.rawok:
				move.w	d0,(a0)

.rawcont:
				move.l	#mnu_cursanim,mnu_frameptr
				movem.l	(a7)+,d0-a6
				bra.w	.loop

.bsr:
				movem.l	d0-a6,-(a7)
				move.l	20(a0,d0.w*8),a0
				jsr		(a0)
				movem.l	(a7)+,d0-a6
				bra.w	.redraw

.jump:
				move.l	20(a0,d0.w*8),a0
				move.l	mnu_mainstack,a7
				jmp		(a0)

;---------------------------------------------------------------------------
.left:
				move.l	16(a0,d0.w*8),d1
				cmp.l	#4,d1
				bne.s	.leftsl
				move.l	20(a0,d0.w*8),a1
				move.l	10(a1),a2
				move.w	8(a1),d0
				add.w	d0,(a2)
				bra.w	.loop

.leftsl:
				cmp.l	#5,d1
				bne.w	.wrong
				move.l	20(a0,d0.w*8),a1
				move.l	6(a1),a2
				addq.w	#1,(a2)
				bra.w	.loop

.right:
				move.l	16(a0,d0.w*8),d1
				cmp.l	#4,d1
				bne.s	.rightsl
				move.l	20(a0,d0.w*8),a1
				move.l	10(a1),a2
				move.w	8(a1),d0
				sub.w	d0,(a2)
				bra.w	.loop

.rightsl:
				cmp.l	#5,d1
				bne.w	.wrong
				move.l	20(a0,d0.w*8),a1
				move.l	6(a1),a2
				subq.w	#1,(a2)
				bra.w	.loop

;------------------------------------------------------------------ New menu --
.changemenu:
				move.l	20(a0,d0.w*8),a0
				bra.w	.redraw

.newmenu:
				move.l	a0,-(a7)
				move.l	20(a0,d0.w*8),a0		; Set new menu
				bsr.w	mnu_domenu
				move.l	(a7)+,a0
				bra.w	.redraw

.exit:
				rts

mnu_redraw:
				move.w	(a0),d0
				move.w	2(a0),d1
				move.l	4(a0),a0
				bsr.w	mnu_printxy
				rts

mnu_openmenu:;in:a0=Ptr to menu
;		bsr.w	key_flushbuffer
				move.w	mnu_currentlevel,d0
				add.w	#65,d0
				move.b	d0,mnu_mainleveltext
				move.l	a0,-(a7)
				move.l	#0,mnu_printdelay
				bsr.w	mnu_cls
				move.l	#35,timer

.w8a:
				tst.l	timer
				bne.s	.w8a
				move.l	(a7)+,a0
				move.l	a0,-(a7)
				move.w	(a0),d0
				move.w	2(a0),d1
				move.l	4(a0),a0
				bsr.w	mnu_printxy
				move.l	(a7)+,a0
				move.w	8(a0),mnu_curx
				move.w	10(a0),mnu_cury
				move.w	12(a0),mnu_spread
				move.w	14(a0),mnu_items
				move.w	14(a0),d0
				mulu	#3000,d0
				move.w	d0,mnu_row
				move.w	d0,mnu_oldrow
				bsr.w	mnu_update
				rts

mnu_waitmenu:;out: d0=Selection number
;		move.l	#mnu_cursanim,mnu_frameptr
				clr.l	mnu_printdelay

.loop:
				moveq.l	#0,d1
				move.w	mnu_oldrow,d1
				cmp.w	mnu_row,d1
				beq.s	.skip
;		move.l	#mnu_cursanim,mnu_frameptr
				divu	mnu_items,d1
				swap.w	d1
				mulu	mnu_spread,d1
				add.w	mnu_cury,d1
				move.w	mnu_curx,d0
				lea		mnu_cleararrow,a0
				bsr.w	mnu_printxy

.skip:
.w8key:
				tst.b	Game_ShouldQuit_b
				bne.b	.exit_game
				bsr.w	mnu_docursor
				CALLGRAF WaitTOF				; wait a bit to give the BlitTask more time
				CALLGRAF WaitTOF
				jsr		key_readkey
				tst.w	d0
				beq.s	.w8key
				cmp.b	#69,d0
				beq.s	.exit
				cmp.b	#77,d0					; Down Arrow
				beq.s	.down
				cmp.b	#76,d0
				beq.s	.up
				cmp.b	#68,d0
				beq.s	.quit
				cmp.b	#64,d0
				beq.s	.quit
				cmp.b	#78,d0
				beq.s	.sliderr
				cmp.b	#79,d0
				beq.s	.sliderl
				cmp.b	#QUIT_KEY,d0
				beq.s	.exit_game
				move.l	#mnu_errcursanim,mnu_frameptr
				bra.w	.loop

.exit_game:
				st		Game_ShouldQuit_b
				; fall through

				; Quick fix for the failure to exit from menu
				; see https://eab.abime.net/showpost.php?p=1677426&postcount=4366
				move.l	mnu_mainstack,a7
				bra		Game_Quit

.exit:
				moveq.l	#-1,d0					; Esc key
				moveq.l	#0,d1
				rts

.sliderr:
				moveq.l	#41,d1
				bra.s	.cpcont

.sliderl:
				moveq.l	#42,d1
				bra.s	.cpcont

.quit:
				moveq.l	#0,d1

.cpcont:
				move.w	mnu_row,d0
				divu	mnu_items,d0
				swap.w	d0
				and.l	#$ffff,d0
				rts

.down:
				addq.w	#1,mnu_row
				bra.w	.loop

.up:
				subq.w	#1,mnu_row
				bra.w	.loop

mnu_docursor:
				moveq.l	#0,d1
				move.w	mnu_row,d1
				move.w	d1,mnu_oldrow
				divu	mnu_items,d1
				swap.w	d1
				mulu	mnu_spread,d1
				add.w	mnu_cury,d1
				move.w	mnu_curx,d0
				lea		mnu_arrow,a0

				bsr.w	mnu_printxy
				rts

mnu_docursor1:
				moveq.l	#0,d1
				move.w	mnu_row,d1
				divu	mnu_items,d1
				swap.w	d1
				mulu	mnu_spread,d1
				add.w	mnu_cury,d1
				move.w	mnu_curx,d0
				lea		mnu_arrow,a0
				bsr.w	mnu_printxy
				rts

mnu_update:;in:	a0=Ptr	to						menu
				move.w	14(a0),d7
				subq.w	#1,d7
				move.w	10(a0),d1				; d1=YPos
				move.w	8(a0),d0
				move.l	a0,a1
				add.l	#16,a1

.itemloop:
				move.l	(a1)+,d2
				cmp.l	#4,d2					; Slider ?
				beq.s	.doslider
				cmp.l	#5,d2					; Slider ?
				beq.s	.docycler
				cmp.l	#8,d2
				beq.s	.dorawkey
				cmp.l	#9,d2
				beq.s	.doloadlevel
				cmp.l	#10,d2
				beq.s	.doloadlevel

.continue:
				add.w	12(a0),d1
				addq.l	#4,a1
				dbra	d7,.itemloop
				rts

.doslider:
				movem.l	d0-a6,-(a7)
				move.l	(a1),a0					; a0=Slider ptr
				bsr.w	mnu_putslider
				movem.l	(a7)+,d0-a6
				bra.s	.continue

.docycler:
				movem.l	d0-a6,-(a7)
				move.l	(a1),a0					; a0=Cycler ptr
				bsr.w	mnu_putcycler
				movem.l	(a7)+,d0-a6
				bra.s	.continue

.dorawkey:
				movem.l	d0-a6,-(a7)
				move.l	(a1),a0					; a0=Ptr to value
				move.w	(a0),d3
				add.w	#132,d3
				add.w	#2,d0
				move.b	d3,mnu_rawprint
				lea		mnu_rawprint,a0
				bsr.w	mnu_printxy
				movem.l	(a7)+,d0-a6
				bra.s	.continue

.doloadlevel:
				movem.l	d0-a6,-(a7)
				move.l	(a1),a0
				move.w	(a0),d2					; d0=Level no
				add.w	#65,d2
				move.b	d2,mnu_levelno
				addq.w	#2,d0
				lea		mnu_leveltext,a0
				bsr.w	mnu_printxy
				movem.l	(a7)+,d0-a6
				bra.s	.continue

mnu_putslider:;in: d0,d1,d7,a0=Xpos,Ypos,Spread,Slider ptr
				add.w	(a0),d0
				add.w	2(a0),d1
				move.w	d0,.xpos
				movem.l	d0-d1/a0,-(a7)
				lea		mnu_leftslider,a0
				bsr.w	mnu_printxy
				movem.l	(a7)+,d0-d1/a0
				addq.w	#2,d0
				move.w	6(a0),d2
				lsr.w	#4,d2
				tst.w	d2
				beq.s	.skip
				move.w	d2,d4
				movem.l	d0-d1/a0,-(a7)
				lea		mnu_sliderspace,a0
				move.l	a0,a1
				subq.w	#1,d2

.loop:
				move.b	#59,(a1)+
				dbra	d2,.loop
				clr.b	(a1)
				bsr.w	mnu_printxy
				movem.l	(a7)+,d0-d1/a0
				add.w	d4,d0
				add.w	d4,d0

.skip:
				move.w	6(a0),d2
				and.w	#$f,d2
				beq.w	.skip2
				move.w	d2,d5
				subq.w	#1,d2
				moveq.l	#0,d3

.loop1:
				ror.w	#1,d3
				or.w	#$8000,d3
				dbra	d2,.loop1
				movem.l	d0-d1,-(a7)
				mulu	d7,d1
				add.w	d0,d1
				add.l	#mnu_morescreen+40*256*3,d1
				move.l	d1,a4					; a4=Screen Ptr
				movem.l	(a7)+,d0-d1
				swap.w	d3
				clr.w	d3
				moveq.l	#15,d2
				move.l	a4,a5
				move.l	mnu_sliddat,a3

.loop2:
				move.l	(a3),d4
				and.l	d3,d4
				move.l	d4,(a4)
				move.l	176*40(a3),d4
				and.l	d3,d4
				move.l	d4,40*256(a4)
				move.l	176*40*2(a3),d4
				and.l	d3,d4
				move.l	d4,40*256*2(a4)
				add.l	#40,a3
				add.l	#40,a4
				dbra	d2,.loop2
				move.l	a5,a4
				moveq.l	#15,d2
				move.l	mnu_sliddat,a3

.loop3:
				move.l	2(a3),d4
				lsr.l	d5,d4
				or.l	d4,(a4)
				move.l	2+176*40(a3),d4
				lsr.l	d5,d4
				or.l	d4,40*256(a4)
				move.l	2+176*40*2(a3),d4
				lsr.l	d5,d4
				or.l	d4,40*256*2(a4)
				add.l	#40,a3
				add.l	#40,a4
				dbra	d2,.loop3
				bra.s	.cont1

.skip2:
				movem.l	d0/d1/a0,-(a7)
				lea		mnu_rightslider,a0
				bsr.w	mnu_printxy
				movem.l	(a7)+,d0/d1/a0

.cont1:
				move.l	10(a0),a1				; Value 2 change ptr
				move.w	(a1),d0
				cmp.w	#0,d0
				bge.s	.ok1
				moveq.l	#0,d0

.ok1:
				cmp.w	4(a0),d0
				ble.s	.ok2
				move.w	4(a0),d0

.ok2:
				move.w	d0,(a1)
				mulu	6(a0),d0
				divu	4(a0),d0				; d0=Slider position X
				sub.w	mnu_sliderwidth,d0
				move.w	.xpos,d2
				lsl.w	#3,d2
				add.w	d2,d0
				move.w	d0,d2
				and.l	#$f,d2
				lsr.w	#4,d0
				lsl.w	#1,d0
				addq.w	#2,d0
				and.l	#$ffff,d0
				mulu	d7,d1
				add.l	d0,d1
				add.l	#mnu_morescreen+40*256*3,d1
				move.l	d1,a4					; a1=Screen ptr
				moveq.l	#15,d3
				move.l	mnu_sliddat,a3

.loop4:
				move.l	6(a3),d4
				lsr.l	d2,d4
				or.l	d4,(a4)
				move.l	6+176*40(a3),d4
				lsr.l	d2,d4
				or.l	d4,40*256(a4)
				move.l	6+176*40*2(a3),d4
				lsr.l	d2,d4
				or.l	d4,40*256*2(a4)
				add.l	#40,a3
				add.l	#40,a4
				dbra	d3,.loop4
				rts

.xpos:
				dc.w	0

mnu_putcycler:;in: d0,d1,a0=Xpos,Ypos,Spread,Cycler ptr
				add.w	(a0),d0
				add.w	2(a0),d1
				move.l	6(a0),a1
				moveq.l	#0,d2
				move.w	(a1),d2
				divu	4(a0),d2
				swap.w	d2
				move.w	d2,(a1)
				move.l	10(a0,d2.w*4),a0
				bsr.w	mnu_printxy
				rts

mnu_plot:
				move.w	#49,d7
				lea		mnu_sines,a0
				lea		mnu_xsine0,a1
				move.l	a0,a3

plotlist:
				move.w	(a1),d0
				and.w	#1022,d0
				move.w	(a0,d0.w),d1
				move.w	4(a1),d0
				and.w	#1022,d0
				add.w	(a0,d0.w),d1
				asr.w	#4,d1
				add.w	#160,d1
				move.w	2(a1),d0
				and.w	#1022,d0
				move.w	(a0,d0.w),d2
				move.w	6(a1),d0
				and.w	#1022,d0
				add.w	(a0,d0.w),d2
				asr.w	#4,d2
				add.w	#128,d2
				mulu	#40,d2
				move.w	d1,d0
				lsr.w	#3,d1
				add.w	d1,d2
				neg.w	d0
				addq.w	#$7,d0
				add.l	#mnu_morescreen,d2
				move.l	d2,a2
				bset.b	d0,(a2)
				bset.b	d0,40*256(a2)
				bset.b	d0,40*256*2(a2)

				REPT	4
				move.w	(a3)+,d0
				and.w	#3,d0
				add.w	#2,d0
				add.w	d0,(a1)+
				ENDR

				dbra	d7,plotlist

				rts

mnu_getrawvalue:;out: d0=Raw value
				bsr.w	mnu_docursor1
				move.b	lastpressed,d0
				beq.s	mnu_getrawvalue
				move.b	#0,lastpressed
				move.w	#$ffff,mnu_oldrow
				rts

; Waits until a key is pressed the returns the raw value
;		bsr.w	mnu_docursor1
;		tst.b	key_keypressed
;		bne.s	mnu_getrawvalue
;.loop:		bsr.w	mnu_docursor1
;		tst.b	key_keypressed
;		beq.s	.loop
;		move.b	key_rawkey,d0
;		and.l	#$ff,d0
;		move.l	d0,-(a7)
;.oloop:		bsr.w	mnu_docursor1
;		tst.b	key_keypressed
;		bne.s	.oloop
;		bsr.w	key_flushbuffer
;		move.w	#$ffff,mnu_oldrow
;		move.l	(a7)+,d0
;		rts

mnu_test4quit:
				clr.w	mnu_quitflag
				bsr.w	mnu_docursor
				jsr		key_readkey
				cmp.w	#27,d0
				beq.s	.quit
				cmp.w	#13,d0
				beq.s	.quit
				cmp.w	#32,d0
				beq.s	.quit
				tst.w	d0
				beq.s	.skip
				move.l	#mnu_errcursanim,mnu_frameptr

.skip:
				moveq.l	#-1,d0
				tst.w	d0
				rts

.quit:
				st.b	mnu_quitflag
				moveq.l	#0,d0
				tst.w	d0
				rts

mnu_quitflag:
				dc.w	0

mnu_playgame:
				cmp.w	#1,mnu_playtype			; Is it 2 player master ???
				bne.w	.noplayermaster
				lea		mnu_2pmastermenu,a0
				bsr.w	mnu_domenu
				cmp.w	#1,mnu_currentsel
				bne.s	.rts
				bsr.w	mnu_cls
				lea		mnu_slavewaittext,a0
				IFND	mnu_nowait
				moveq.l	#6,d0
				moveq.l	#60,d1
				bsr.w	mnu_printxy
				clr.w	mnu_spread
				move.w	#4,mnu_curx
				move.w	#140,mnu_cury
				bsr.w	mnu_wait4slave
				tst.w	mnu_quitflag
				beq.s	.playgame
				rts
				ENDC
				bra.s	.playgame
.rts:
				rts

.noplayermaster:
				cmp.w #2,mnu_playtype
				bne.w	.playgame
				IFND	mnu_nowait
				bsr.w	mnu_cls
				lea		mnu_masterwaittext,a0
				moveq.l	#6,d0
				moveq.l	#60,d1
				bsr.w	mnu_printxy
				clr.w	mnu_spread
				move.w	#4,mnu_curx
				move.w	#140,mnu_cury
				bsr.w	mnu_wait4master
				tst.w	mnu_quitflag
				beq.s	.playgame
				rts
				ENDC

.playgame:
				moveq	#1,d0 ; Fade out
				CALLC	mnu_clearscreen
;-------------------------------------- Jump to game here !! --
				move.w	mnu_playtype,d0
				lea		.playtypeptr,a0
				move.l	(a0,d0.w*4),a0
				jsr		(a0)
				CALLC	mnu_setscreen
				rts

.playtypeptr:
				dc.l	mnu_play1p
				dc.l	mnu_play2pMaster
				dc.l	mnu_play2pSlave


*******************************************************************************
*******************************************************************************
*******************************************************************************
*******************************************************************************

mnu_wait4slave:	;		Wait					for the slave to connect.
.loop:
				bsr.w	mnu_test4quit			; Check for "cancel" (and cursor)
				beq.s	.rts					; Cancel key was selected

;.............. Do your tests here .................................
;.............. if the slave connects just exit with a rts .........

				btst	#CIAB_GAMEPORT0,_ciaa+ciapra
				bne.s	.loop

.loop1:
				btst	#CIAB_GAMEPORT0,_ciaa+ciapra
				beq.s	.loop1

.rts:
				rts

*******************************************************************************

mnu_wait4master:; Wait	for						the master to connect.
.loop:
				bsr.w	mnu_test4quit			; Check for "cancel" (and cursor)
				beq.s	.rts					; Cancel key was selected

;.............. Do your tests here ..................................
;.............. if the master connects just exit with a rts .........

				btst	#CIAB_GAMEPORT0,_ciaa+ciapra
				bne.s	.loop

.loop1:
				btst	#CIAB_GAMEPORT0,_ciaa+ciapra
				beq.s	.loop1

.rts:
				rts

*******************************************************************************

mnu_play1p:		;		Do						the 1 player game stuff here
.loop:
				btst	#CIAB_GAMEPORT0,_ciaa+ciapra
				bne.s	.loop

				rts

*******************************************************************************

mnu_play2pMaster:; Do	the						2 player master game stuff here
.loop:
				btst	#CIAB_GAMEPORT0,_ciaa+ciapra
				bne.s	.loop

				rts

*******************************************************************************

mnu_play2pSlave:; Do	the						2 player slave game stuff here
.loop:
				btst	#CIAB_GAMEPORT0,_ciaa+ciapra
				bne.s	.loop

				rts

*******************************************************************************

mnu_loadlevel:	;		Level					to load is in mnu_currentlevel.w
; Current menu item is in mnu_currentsel.w (0 based)
				rts

*******************************************************************************

mnu_savelevel:	;		Level					to save is in mnu_currentlevel.w
; Current menu item is in mnu_currentsel.w (0 based)
; Or all saved levels in the mnu_levellist+n*2.w
				rts

*******************************************************************************

;	include	"demo:System/KeyBoard.S"

****************************************************************** Variables **

mnu_2plevel:	dc.w	0
mnu_currentsel:	dc.w	0						; Containes the current menu item
mnu_currentlevel:
mnu_level:		dc.w	0						; Current level choosen. 0=A,1=B...

mnu_playtype:	dc.w	0						; Selected type of game. 0=1 player
;			 1=2 player master
;			 2=2 player slave
;------------------------------------------------- Rawcodes for control keys --
mnu_rawkeys:	;----------------------------- Here are all defined raw keys --
mnu_key00:		dc.w	$4f						; Turn left
mnu_key01:		dc.w	$4e						; Turn right
mnu_key02:		dc.w	$4c						; Forwards
mnu_key03:		dc.w	$4d						; Backwards
mnu_key04:		dc.w	101						; Fire
mnu_key05:		dc.w	$40						; Operate door
mnu_key06:		dc.w	97						; Run
mnu_key07:		dc.w	103						; Force sidestep
mnu_key08:		dc.w	57						; Sidestep left
mnu_key09:		dc.w	58						; Sidestep right
mnu_key10:		dc.w	34						; Duck
mnu_key11:		dc.w	40						; Look behind
mnu_key12:		dc.w	15						; Jump
mnu_key13:		dc.w	27						; Look up
mnu_key14:		dc.w	42						; Look down
mnu_key15:		dc.w	41						; Centre view
;------------------------------------------- Put other reserved keys here !! --
				dc.w	69						; Escape
				dc.w	1,2,3,4,5,6,7,8,9,10	; Weapon selects
				dc.w	80						; Zoom in on map
				dc.w	81						; Zoom out on map
				dc.w	82						; 4/8 Channel sound
				dc.w	83						; Mono/Stereo sound
				dc.w	84						; Recall message
				dc.w	85						; Render quality
				dc.w	29						; Map down left
				dc.w	30						; Map down
				dc.w	31						; Map down right
				dc.w	45						; Map left
				dc.w	46						; Center map
				dc.w	47						; Map right
				dc.w	61						; Map up left
				dc.w	62						; Map up
				dc.w	63						; Map up right
				dc.w	-1						; End list with -1

mnu_levellist:;----------------------------- Current levels in the save list --
mnu_saved0:		dc.w	0						; Level number for saved pos 0
mnu_saved1:		dc.w	1
mnu_saved2:		dc.w	3
mnu_saved3:		dc.w	8
mnu_saved4:		dc.w	4
mnu_saved5:		dc.w	11

mnu_xsine0:		dc.w	0
mnu_xsine1:		dc.w	0
mnu_ysine0:		dc.w	0
mnu_ysine1:		dc.w	0
				ds.l	2*100					; some buffer for the points in the menu fire

mnu_sines:
				dc.w	$0006,$0013,$001f,$002c,$0038,$0045,$0052,$005e,$006b,$0077
				dc.w	$0083,$0090,$009c,$00a9,$00b5,$00c1,$00ce,$00da,$00e6,$00f2
				dc.w	$00ff,$010b,$0117,$0123,$012f,$013b,$0147,$0153,$015f,$016a
				dc.w	$0176,$0182,$018d,$0199,$01a4,$01b0,$01bb,$01c6,$01d2,$01dd
				dc.w	$01e8,$01f3,$01fe,$0209,$0213,$021e,$0229,$0233,$023e,$0248
				dc.w	$0252,$025c,$0266,$0270,$027a,$0284,$028e,$0297,$02a1,$02aa
				dc.w	$02b4,$02bd,$02c6,$02cf,$02d8,$02e1,$02e9,$02f2,$02fa,$0303
				dc.w	$030b,$0313,$031b,$0323,$032a,$0332,$0339,$0341,$0348,$034f
				dc.w	$0356,$035d,$0364,$036a,$0371,$0377,$037d,$0383,$0389,$038f
				dc.w	$0395,$039a,$039f,$03a5,$03aa,$03af,$03b4,$03b8,$03bd,$03c1
				dc.w	$03c5,$03c9,$03cd,$03d1,$03d5,$03d8,$03dc,$03df,$03e2,$03e5
				dc.w	$03e7,$03ea,$03ed,$03ef,$03f1,$03f3,$03f5,$03f7,$03f8,$03f9
				dc.w	$03fb,$03fc,$03fd,$03fd,$03fe,$03ff,$03ff,$03ff,$03ff,$03ff
				dc.w	$03ff,$03fe,$03fd,$03fd,$03fc,$03fb,$03f9,$03f8,$03f7,$03f5
				dc.w	$03f3,$03f1,$03ef,$03ed,$03ea,$03e7,$03e5,$03e2,$03df,$03dc
				dc.w	$03d8,$03d5,$03d1,$03cd,$03c9,$03c5,$03c1,$03bd,$03b8,$03b4
				dc.w	$03af,$03aa,$03a5,$039f,$039a,$0395,$038f,$0389,$0383,$037d
				dc.w	$0377,$0371,$036a,$0364,$035d,$0356,$034f,$0348,$0341,$0339
				dc.w	$0332,$032a,$0323,$031b,$0313,$030b,$0303,$02fa,$02f2,$02e9
				dc.w	$02e1,$02d8,$02cf,$02c6,$02bd,$02b4,$02aa,$02a1,$0297,$028e
				dc.w	$0284,$027a,$0270,$0266,$025c,$0252,$0248,$023e,$0233,$0229
				dc.w	$021e,$0213,$0209,$01fe,$01f3,$01e8,$01dd,$01d2,$01c6,$01bb
				dc.w	$01b0,$01a4,$0199,$018d,$0182,$0176,$016a,$015f,$0153,$0147
				dc.w	$013b,$012f,$0123,$0117,$010b,$00ff,$00f2,$00e6,$00da,$00ce
				dc.w	$00c1,$00b5,$00a9,$009c,$0090,$0083,$0077,$006b,$005e,$0052
				dc.w	$0045,$0038,$002c,$001f,$0013,$0006,$fffa,$ffed,$ffe1,$ffd4
				dc.w	$ffc8,$ffbb,$ffae,$ffa2,$ff95,$ff89,$ff7d,$ff70,$ff64,$ff57
				dc.w	$ff4b,$ff3f,$ff32,$ff26,$ff1a,$ff0e,$ff01,$fef5,$fee9,$fedd
				dc.w	$fed1,$fec5,$feb9,$fead,$fea1,$fe96,$fe8a,$fe7e,$fe73,$fe67
				dc.w	$fe5c,$fe50,$fe45,$fe3a,$fe2e,$fe23,$fe18,$fe0d,$fe02,$fdf7
				dc.w	$fded,$fde2,$fdd7,$fdcd,$fdc2,$fdb8,$fdae,$fda4,$fd9a,$fd90
				dc.w	$fd86,$fd7c,$fd72,$fd69,$fd5f,$fd56,$fd4c,$fd43,$fd3a,$fd31
				dc.w	$fd28,$fd1f,$fd17,$fd0e,$fd06,$fcfd,$fcf5,$fced,$fce5,$fcdd
				dc.w	$fcd6,$fcce,$fcc7,$fcbf,$fcb8,$fcb1,$fcaa,$fca3,$fc9c,$fc96
				dc.w	$fc8f,$fc89,$fc83,$fc7d,$fc77,$fc71,$fc6b,$fc66,$fc61,$fc5b
				dc.w	$fc56,$fc51,$fc4c,$fc48,$fc43,$fc3f,$fc3b,$fc37,$fc33,$fc2f
				dc.w	$fc2b,$fc28,$fc24,$fc21,$fc1e,$fc1b,$fc18,$fc16,$fc13,$fc11
				dc.w	$fc0f,$fc0d,$fc0b,$fc09,$fc08,$fc07,$fc05,$fc04,$fc03,$fc03
				dc.w	$fc02,$fc01,$fc01,$fc01,$fc01,$fc01,$fc01,$fc02,$fc03,$fc03
				dc.w	$fc04,$fc05,$fc07,$fc08,$fc09,$fc0b,$fc0d,$fc0f,$fc11,$fc13
				dc.w	$fc16,$fc19,$fc1b,$fc1e,$fc21,$fc24,$fc28,$fc2b,$fc2f,$fc33
				dc.w	$fc37,$fc3b,$fc3f,$fc43,$fc48,$fc4c,$fc51,$fc56,$fc5b,$fc61
				dc.w	$fc66,$fc6b,$fc71,$fc77,$fc7d,$fc83,$fc89,$fc8f,$fc96,$fc9c
				dc.w	$fca3,$fcaa,$fcb1,$fcb8,$fcbf,$fcc7,$fcce,$fcd6,$fcdd,$fce5
				dc.w	$fced,$fcf5,$fcfd,$fd06,$fd0e,$fd17,$fd1f,$fd28,$fd31,$fd3a
				dc.w	$fd43,$fd4c,$fd56,$fd5f,$fd69,$fd72,$fd7c,$fd86,$fd90,$fd9a
				dc.w	$fda4,$fdae,$fdb8,$fdc2,$fdcd,$fdd7,$fde2,$fded,$fdf7,$fe02
				dc.w	$fe0d,$fe18,$fe23,$fe2e,$fe3a,$fe45,$fe50,$fe5c,$fe67,$fe73
				dc.w	$fe7e,$fe8a,$fe96,$fea1,$fead,$feb9,$fec5,$fed1,$fedd,$fee9
				dc.w	$fef5,$ff01,$ff0e,$ff1a,$ff26,$ff32,$ff3f,$ff4b,$ff57,$ff64
				dc.w	$ff70,$ff7d,$ff89,$ff95,$ffa2,$ffae,$ffbb,$ffc8,$ffd4,$ffe1
				dc.w	$ffed,$fffa

mnu_mainstack:	dc.l	0

;--------------------------------------------------------------- Slider data --

mnu_sliderwidth:dc.w 6
mnu_sliddat:	dc.l	mnu_font+40*16+7*2
mnu_leftslider:	dc.b	58,0
mnu_sliderspace: dcb.b	20,0
mnu_rightslider:dc.b 60,0
mnu_rawprint:	dc.b	0,0
				even
;----------------------------------------------------------------- Menu data --

mnu_curx:		dc.w	5
mnu_cury:		dc.w	78
mnu_spread:		dc.w	40
mnu_items:		dc.w	3

mnu_arrow:		dc.b	' ',0
mnu_cleararrow:	dc.b	' ',0
mnu_row:		dc.w	30000
mnu_oldrow:		dc.w	30000
mnu_screenpos:	dc.w	0

mnu_printdelay:	dc.l	0

;----------------------------------------------------------------- Fire data --

_mnu_rndptr::
mnu_rndptr:		dc.l	mnu_morescreen+6*40*256
mnu_sourceptrs:	dc.l	mnu_morescreen+3*40*256+mnu_speed*40
				dc.l	mnu_morescreen+4*40*256+mnu_speed*40
				dc.l	mnu_morescreen+5*40*256+mnu_speed*40

;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Menues %%

; Types:	0 = Do nothing
;		1 = Sub menu
;		2 = Exit sub menu
;		3 = Execute subroutine
;               4 = Slider
;               5 = Cycler
;		6 = Branch (SP) set to value in mnu_mainstack
;		7 = Change menu
;		8 = Get raw key
;		9 = Level Load
;              10 = Level Save


mnu_MYMAINMENU:
				dc.w	0,0
				dc.l	mnu_MYMAINMENUTEXT
				dc.w	0,40
				dc.w	20
				dc.w	8
				dc.l	0,0
				dc.l	0,0
				dc.l	0,0
				dc.l	0,0
				dc.l	0,0
				dc.l	0,0
				dc.l	0,0

mnu_MYMAINMENUTEXT:
;                        12345678901234567890
				dc.b	'                    ',1
				dc.b	'                    ',1
				dc.b	'     PLAY  GAME     ',1
				dc.b	'      1 PLAYER      ',1

mnu_CURRENTLEVELLINE:
				dc.b	'                    ',1
				dc.b	'  CONTROL  OPTIONS  ',1
				dc.b	'    GAME CREDITS    ',1
				dc.b	'   LOAD  POSITION   ',1
				dc.b	'   SAVE  POSITION   ',1
				dc.b	'   CUSTOM OPTIONS   ',1
				dc.b	'                    ',1
				dc.b	'                    ',0

				EVEN
***************************************************************
mnu_MYLEVELMENU:
				dc.w	0,0
				dc.l	mnu_MYLEVELMENUTEXT
				dc.w	0,40
				dc.w	20
				dc.w	9
				dc.l	0,0
				dc.l	0,0
				dc.l	0,0
				dc.l	0,0
				dc.l	0,0
				dc.l	0,0
				dc.l	0,0

mnu_MYLEVELMENUTEXT:
;					 12345678901234567890
				dc.b	'                    ',1
				dc.b	'                    ',1
				dc.b	'      LEVEL  A      ',1
				dc.b	'      LEVEL  B      ',1
				dc.b	'      LEVEL  C      ',1
				dc.b	'      LEVEL  D      ',1
				dc.b	'      LEVEL  E      ',1
				dc.b	'      LEVEL  F      ',1
				dc.b	'      LEVEL  G      ',1
				dc.b	'      LEVEL  H      ',1
				dc.b	'     NEXT  PAGE     ',1
				dc.b	'                    ',0

				EVEN

mnu_MYLEVELMENU2:
				dc.w	0,0
				dc.l	mnu_MYLEVELMENUTEXT2
				dc.w	0,40
				dc.w	20
				dc.w	9
				dc.l	0,0
				dc.l	0,0
				dc.l	0,0
				dc.l	0,0
				dc.l	0,0
				dc.l	0,0
				dc.l	0,0

mnu_MYLEVELMENUTEXT2:
;					 12345678901234567890
				dc.b	'                    ',1
				dc.b	'                    ',1
				dc.b	'      LEVEL  I      ',1
				dc.b	'      LEVEL  J      ',1
				dc.b	'      LEVEL  K      ',1
				dc.b	'      LEVEL  L      ',1
				dc.b	'      LEVEL  M      ',1
				dc.b	'      LEVEL  N      ',1
				dc.b	'      LEVEL  O      ',1
				dc.b	'      LEVEL  P      ',1
				dc.b	'     MAIN  MENU     ',1
				dc.b	'                    ',0

				EVEN
mnu_MYCUSTOMOPTSMENU:
				dc.w	0,0
				dc.l	mnu_MYCUSTOMOPTSTEXT
				dc.w	0,40
				dc.w	20
				dc.w	9
				ds.l	18

;was going to use these to change the text in the menu but bodged it.
; optOn:
	; dc.b 'ON ',1
; optOff:
	; dc.b 'OFF',1

mnu_MYCUSTOMOPTSTEXT:
;					 12345678901234567890
				dc.b	'                    ',1
				dc.b	'                    ',1
optionLines:				;12345678901234567890
				dc.b	'  ORIGINAL MOUSE    ',1;OFF  ',1
				dc.b	'  ALWAYS RUN        ',1;OFF  ',1
				dc.b	'  OPTION 3          ',1;OFF  ',1
				dc.b	'  OPTION 4          ',1;OFF  ',1
				dc.b	'  OPTION 5          ',1
				dc.b	'  OPTION 6          ',1
				dc.b	'  OPTION 7          ',1
				dc.b	'  OPTION 8          ',1
				dc.b	'     MAIN  MENU     ',0
				EVEN
***************************************************************
mnu_MYCONTROLSONE:
				dc.w	0,0
				dc.l	mnu_MYCONTROLTEXTONE
				dc.w	0,0
				dc.w	20
				dc.w	12
				ds.l	24

				EVEN

mnu_MYCONTROLTEXTONE:
KEY_LINES:
;                        12345678901234567  8  90
				dc.b	'  TURN LEFT      ',132+$4f,'  ',1
				dc.b	'  TURN RIGHT     ',132+$4e,'  ',1
				dc.b	'  FORWARDS       ',132+$4c,'  ',1
				dc.b	'  BACKWARDS      ',132+$4d,'  ',1
				dc.b	'  FIRE           ',132+$65,'  ',1
				dc.b	'  OPERATE        ',132+$40,'  ',1
				dc.b	'  RUN            ',132+$61,'  ',1
				dc.b	'  FORCE S/S      ',132+$67,'  ',1
				dc.b	'  S/S LEFT       ',132+$39,'  ',1
				dc.b	'  S/S RIGHT      ',132+$3a,'  ',1
				dc.b	'  DUCK           ',132+$22,'  ',1
				dc.b	'        MORE        ',0

				EVEN

mnu_MYCONTROLSTWO:
				dc.w	0,40
				dc.l	mnu_MYCONTROLTEXTTWO
				dc.w	0,40
				dc.w	20
				dc.w	7
				ds.l	14

				EVEN

mnu_MYCONTROLTEXTTWO:
KEY_LINES2:
;                        12345678901234567  8  90
				dc.b	'  LOOK BEHIND    ',132+$28,'  ',1
				dc.b	'  JUMP           ',132+$0f,'  ',1
				dc.b	'  LOOK UP        ',132+027,'  ',1
				dc.b	'  LOOK DOWN      ',132+042,'  ',1
				dc.b	'  CENTRE VIEW    ',132+041,'  ',1
				dc.b	'  NEXT WEAPON    ',132+068,'  ',1
				dc.b	'     MAIN  MENU     ',0

				EVEN

mnu_MYMASTERMENU:
				dc.w	0,80
				dc.l	mnu_MYMASTERTEXT
				dc.w	0,80
				dc.w	20
				dc.w	4
				ds.l	8

				EVEN

mnu_MYMASTERTEXT:
;                        12345678901234567890
				dc.b	'  2 PLAYER  MASTER  ',1
mnu_CURRENTLEVELLINEM:
				dc.b	'                    ',1
				dc.b	'     PLAY  GAME     ',1
				dc.b	'  CONTROL  OPTIONS  ',0

				EVEN

mnu_MYSLAVEMENU:
				dc.w	0,80
				dc.l	mnu_MYSLAVETEXT
				dc.w	0,80
				dc.w	20
				dc.w	3
				ds.l	6

				EVEN

mnu_MYSLAVETEXT:
;                        12345678901234567890
				dc.b	'   2 PLAYER SLAVE   ',1
				dc.b	'     PLAY  GAME     ',1
				dc.b	'  CONTROL  OPTIONS  ',0

				EVEN

mnu_MYLOADMENU:
				dc.w	0,40
				dc.l	mnu_MYLOADMENUTEXT
				dc.w	0,60
				dc.w	20
				dc.w	7
				ds.l	14

				EVEN

mnu_MYLOADMENUTEXT:
;                        12345678901234567890
				dc.b	'   LOAD  POSITION   ',1
mnu_LSLOTA:
				dc.b	'      NEW GAME      ',1
				dc.b	'                    ',1
				dc.b	'                    ',1
				dc.b	'                    ',1
				dc.b	'                    ',1
				dc.b	'                    ',1
				dc.b	'       CANCEL       ',0

				EVEN

mnu_MYSAVEMENU:
				dc.w	0,40
				dc.l	mnu_MYSAVEMENUTEXT
				dc.w	0,60
				dc.w	20
				dc.w	6
				ds.l	14

				EVEN

mnu_MYSAVEMENUTEXT:
;                        12345678901234567890
				dc.b	'   SAVE  POSITION   ',1
mnu_SSLOTA:
				dc.b	'                    ',1
				dc.b	'                    ',1
				dc.b	'                    ',1
				dc.b	'                    ',1
				dc.b	'                    ',1
				dc.b	'       CANCEL       ',0

				EVEN


mnu_askfordisk:
				dc.w	0,70
				dc.l	mnu_askfordisktext
				dc.w	0,110					; top of where cursor starts (1st option)
				dc.w	20
				dc.w	1
				dc.l	2,0

mnu_mainmenu:
				dc.w	6,12					; X (bytes),Y (rows) of top left of Vid_Screen1Ptr_l
				dc.l	mnu_maintext			; Text ptr
				dc.w	4,70					; XCursor,YCursor
				dc.w	20						; Spread
				dc.w	7						; Items
				dc.l	5,mnu_playercycler		; Change player type
				dc.l	3,mnu_playgame
				dc.l	1,mnu_controlmenu0
				dc.l	3,mnu_viewcredz
				dc.l	1,mnu_loadmenu
				dc.l	1,mnu_savemenu
				dc.l	2,0						; 2=Exit sub menu (Esc)

mnu_controlmenu0:
				dc.w	6,32 ;					X,Y
				dc.l	mnu_controltext0		; Text ptr
				dc.w	4,50					; XCursor,YCursor
				dc.w	20						; Spread
				dc.w	9						; Items
				dc.l	8,mnu_key00
				dc.l	8,mnu_key01
				dc.l	8,mnu_key02
				dc.l	8,mnu_key03
				dc.l	8,mnu_key04
				dc.l	8,mnu_key05
				dc.l	8,mnu_key06
				dc.l	8,mnu_key07
				dc.l	7,mnu_controlmenu1

mnu_controlmenu1:
				dc.w	6,32 ;					X,Y
				dc.l	mnu_controltext1		; Text ptr
				dc.w	4,50					; XCursor,YCursor
				dc.w	20						; Spread
				dc.w	9						; Items
				dc.l	8,mnu_key08
				dc.l	8,mnu_key09
				dc.l	8,mnu_key10
				dc.l	8,mnu_key11
				dc.l	8,mnu_key12
				dc.l	8,mnu_key13
				dc.l	8,mnu_key14
				dc.l	8,mnu_key15
				dc.l	7,mnu_controlmenu2

mnu_controlmenu2:
				dc.w	4,12 ;					X,Y
				dc.l	mnu_controltext2		; Text ptr
				dc.w	4,210					; XCursor,YCursor
				dc.w	20						; Spread
				dc.w	1						; Items
				dc.l	7,mnu_controlmenu0

mnu_loadmenu:
				dc.w	4,42
				dc.l	mnu_loadmenutext
				dc.w	4,80					; XCursor,YCursor
				dc.w	20						; Spread
				dc.w	7						; Items
				dc.l	9,mnu_saved0
				dc.l	9,mnu_saved1
				dc.l	9,mnu_saved2
				dc.l	9,mnu_saved3
				dc.l	9,mnu_saved4
				dc.l	9,mnu_saved5
				dc.l	2,0

mnu_savemenu:
				dc.w	4,42
				dc.l	mnu_savemenutext
				dc.w	4,80					; XCursor,YCursor
				dc.w	20						; Spread
				dc.w	7						; Items
				dc.l	10,mnu_saved0
				dc.l	10,mnu_saved1
				dc.l	10,mnu_saved2
				dc.l	10,mnu_saved3
				dc.l	10,mnu_saved4
				dc.l	10,mnu_saved5
				dc.l	2,0

mnu_quitmenu:
				dc.w	4,82
				dc.l	mnu_quitmenutext
				dc.w	4,120					; XCursor,YCursor
				dc.w	20						; Spread
				dc.w	2						; Items
				dc.l	6,mnu_loop
				dc.l	6,mnu_exit

mnu_2pmastermenu:
				dc.w	4,82
				dc.l	mnu_2pmastertext
				dc.w	4,120					; XCursor,YCursor
				dc.w	20						; Spread
				dc.w	3						; Items
				dc.l	5,mnu_levelcycler
				dc.l	2,0
				dc.l	2,0

;--------------------------------------------------------------------- Texts --
mnu_askfordisktext:
;                        12345678901234567890
				dc.b	'Please Insert Volume',1
				dc.b	1
mnu_diskline:
				dc.b	'                    ',0

mnu_slavewaittext:
				dc.b	'Waiting for ',1
				dc.b	'your opponent',1
				dc.b	'to respond...',1,1
				dc.b	58,58,'Cancel',0

mnu_masterwaittext:
				dc.b	'Waiting for ',1
				dc.b	'your opponent',1
				dc.b	'to respond...',1,1
				dc.b	58,58,'Cancel',0

mnu_maintext:
				dc.b	1,1
				dc.b	60,'Level '

mnu_mainleveltext:
				dc.b 'A',58,1
				dc.b	1
				dc.b	'Play game',1
				dc.b	'Control options',1
				dc.b	'Game credits',1
				dc.b	'Load position',1
				dc.b	'Save position',1
				dc.b	'Quit',1
				dc.b	0

mnu_quitmenutext:
				dc.b '	Quit					game',131,131,131,1,1
				dc.b	' No,I',39,'m addicted',1
				dc.b	' Yes! Let me OUT',1
				dc.b	0

mnu_2pmastertext:
				dc.b '	2						Player master',1,1
				dc.b	' Play level',1
				dc.b	' Start game',1
				dc.b	' ',58,58,'Cancel',1
				dc.b	0

mnu_loadmenutext:
				dc.b '	Load					game',1,1
				dc.b	1,1,1,1,1,1
				dc.b	' ',58,58,'Cancel',58,58,0

mnu_savemenutext:
				dc.b '	Save					game',1,1
				dc.b	1,1,1,1,1,1
				dc.b	' ',58,58,'Cancel',58,58,0

mnu_controltext0:
				dc.b 1
				dc.b	' Turn left',1
				dc.b	' Turn right',1
				dc.b	' Forwards',1
				dc.b	' Backwards',1
				dc.b	' Fire',1
				dc.b	' Operate door',1
				dc.b	' Run',1
				dc.b	' Sidestep',1
				dc.b	60,60,'More',60,60,1
				dc.b	0

mnu_controltext1:
				dc.b 1
				dc.b	' Sidestep left',1
				dc.b	' Sidestep right',1
				dc.b	' Duck',1
				dc.b	' Look behind',1
				dc.b	' Jump',1
				dc.b	' Look up',1
				dc.b	' Look down',1
				dc.b	' Centre view',1
				dc.b	60,60,'Others',60,60,1
				dc.b	0

mnu_controltext2:
				dc.b 1
				dc.b	157,'Pause',1
				dc.b	212,'Zoom in on map',1
				dc.b	213,'Zoom out on map',1
				dc.b	214,'4/8 Ch. sound',1
				dc.b	215,'Mono/Stereo snd',1
				dc.b	216,'Recall message',1
				dc.b	217,'Render quality',1
				dc.b	133,'-',142,'Select weapon',1
				dc.b	161,'-',195,'Scroll map',1
				dc.b	' ',58,58,'Back',58,58,1
				dc.b	0

mnu_leveltext:
				dc.b	'Level '
mnu_levelno:
				dc.b	'A',0

				IFND	mnu_nocode
mnu_protecttext:
				dc.b 'ENTER NUMBER				AT',1,1
				dc.b	'  TABLE     '
mnu_tableptr:
				dc.b	'0',1
				dc.b	'  ROW      '
mnu_rowptr:
				dc.b	'00',1
				dc.b	'  COLUMN    '
mnu_columnptr:
				dc.b	'0',1,1
				dc.b	'  NUMBER  '
mnu_numberptr:
				dc.b	'      '
				dc.b	0

mnu_wrongtext:
				dc.b	'Wrong!',0

mnu_dontbelong:
				dc.b	'Nice try.',0
				even
				ENDC
;------------------------------------------------------- Cyclers and sliders --

mnu_level0:		dc.b	'A',0
mnu_level1:		dc.b	'B',0
mnu_level2:		dc.b	'C',0
mnu_level3:		dc.b	'D',0
mnu_level4:		dc.b	'E',0
mnu_level5:		dc.b	'F',0
mnu_level6:		dc.b	'G',0
mnu_level7:		dc.b	'H',0
mnu_level8:		dc.b	'I',0
mnu_level9:		dc.b	'J',0
mnu_level10:	dc.b	'K',0
mnu_level11:	dc.b	'L',0
mnu_level12:	dc.b	'M',0
mnu_level13:	dc.b	'N',0
mnu_level14:	dc.b	'O',0
mnu_level15:	dc.b	'P',0
				even

mnu_levelcycler:
				dc.w	24,2 ;						X,Y Add
				dc.w	16						; #of items
				dc.l	mnu_2plevel				; Value to effect
				dc.l	mnu_level0
				dc.l	mnu_level1
				dc.l	mnu_level2
				dc.l	mnu_level3
				dc.l	mnu_level4
				dc.l	mnu_level5
				dc.l	mnu_level6
				dc.l	mnu_level7
				dc.l	mnu_level8
				dc.l	mnu_level9
				dc.l	mnu_level10
				dc.l	mnu_level11
				dc.l	mnu_level12
				dc.l	mnu_level13
				dc.l	mnu_level14
				dc.l	mnu_level15
				even

mnu_playercycler:
				dc.w	2,2 ;						X,Y Add
				dc.w	3						; #of items
				dc.l	mnu_playtype			; Value to effect
				dc.l	mnu_playtype0
				dc.l	mnu_playtype1
				dc.l	mnu_playtype2
				even

mnu_playtype0:	dc.b	'1 Player       ',0
mnu_playtype1:	dc.b	'2 Player master',0
mnu_playtype2:	dc.b	'2 Player slave ',0

;----------------------------------------------------------------- Animation --

mnu_frameptr:	dc.l	mnu_cursanim

mnu_errcursorlong:
				dc.b	240,240,241,241,242,242,243,243
				dc.b	240,240,241,241,242,242,243,243
				dc.b	240,240,241,241,242,242,243,243
				dc.b	240,240,241,241,242,242,243,243
				dc.b	240,240,241,241,242,242,243,243
				dc.b	240,240,241,241,242,242,243,243
				dc.b	240,240,241,241,242,242,243,243
				dc.b	240,240,241,241,242,242,243,243
				dc.b	240,240,241,241,242,242,243,243

mnu_errcursanim:
				dc.b	240,240,241,241,242,242,243,243
				dc.b	240,240,241,241,242,242,243,243
				dc.b	240,240,241,241,242,242,243,243
				dc.b	240,240,241,241,242,242,243,243

mnu_cursanim:
				dc.b	130,129,128,127,126,125,124,123,8
				even

mnu_errbutanim:
				dc.b	240,240,241,241,242,242,243,243
				dc.b	240,240,241,241,242,242,243,243
				dc.b	240,240,241,241,242,242,243,243
				dc.b	240,240,241,241,242,242,243,243

mnu_buttonanim:
				dc.b	236,236,236,236
				dc.b	237,237,237,237
				dc.b	238,238,238,238
				dc.b	239,239,239,239
				dc.b	238,238,238,238
				dc.b	237,237,237,237
				dc.b	24
				even

mnu_font:
				incbin	"menu/font16x16.raw2"

_mnu_fontpal::
mnu_fontpal:
				incbin	"menu/font16x16.pal2"

_mnu_firepal::
mnu_firepal:
				incbin	"menu/firepal.pal2"

_mnu_backpal::
mnu_backpal:
				incbin	"menu/back.pal"

mnu_frame:
				incbin	"menu/credits_only.raw"

counter:
				dc.l	0

_main_vblint::
main_vblint:
				dc.l	0

_main_counter::
main_counter:
				dc.l	0

main_vbrbase:
				dc.l	0
timer:
				dc.l	0

				IFND BUILD_WITH_C
BltNode:
				dc.l	0						; bn_n
				dc.l	mnu_pass1				; bn_function
				dc.b	0						; bn_stat
				dc.b	0						; bn_dummy
				dc.w	0						; bn_blitsize
				dc.w	0						; bn_beamsync
				dc.l	0						; bn_cleanup
				ENDIF

Bitmap:
				dc.w	SCREEN_WIDTH/8					; bm_BytesPerRow
				dc.w	256						; bm_Rows
				dc.b	BMF_DISPLAYABLE			; bm_Flags
				dc.b	8						; bm_Depth
				dc.w	0						; bm_Pad
				ds.l	8						; bm_Planes

ScreenTags:
				dc.l	SA_Width,SCREEN_WIDTH
				dc.l	SA_Height,256
				dc.l	SA_Depth,8
				dc.l	SA_BitMap,Bitmap
				dc.l	SA_Type,CUSTOMSCREEN
				dc.l	SA_Quiet,1
				dc.l	SA_ShowTitle,0
				dc.l	SA_DisplayID,PAL_MONITOR_ID
				dc.l	TAG_END,0

_MenuScreen::
MenuScreen:
				dc.l	0

WindowTags:
				dc.l	WA_Left,0
				dc.l	WA_Top,0
				dc.l	WA_Width,SCREEN_WIDTH
				dc.l	WA_Height,SCREEN_HEIGHT
				dc.l	WA_CustomScreen

WTagScreenPtr:
				dc.l	0						; will fill in screen pointer later
				dc.l	WA_Activate,1
				dc.l	WA_Borderless,1
				dc.l	WA_RMBTrap,1			; prevent menu rendering
				dc.l	WA_NoCareRefresh,1
				dc.l	WA_SimpleRefresh,1
				dc.l	WA_Backdrop,1
				dc.l	TAG_END,0

_MenuWindow::
MenuWindow:		dc.l	0

				section	.data,data

_mnu_background::
mnu_background:
				incbin	"menu/back2.raw"		; 2x320x256 bitplanes

				section	.bsschip,bss_c

_mnu_screen::
mnu_screen:		ds.b	2*40*512				; 4 color background,. 320x512 pixels

_mnu_morescreen::
mnu_morescreen:
				ds.b	8*40*SCREEN_HEIGHT				; 8 bitplanes 320x256 pixels

				align	8				; align for fetch mode 3

emptySprite:
				ds.w	6,0

				section	.text,code
