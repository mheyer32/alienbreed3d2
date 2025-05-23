				include	"system.i"
				include	"macros.i"
				include	"defs.i"
				include "modules/rawkey_macros.i"
				include "modules/dev_macros.i"
				opt		o+

				xref	_custom
				xref	_ciaa
				xref	_Vid_Present

;*************************************************
;* Stuff to do to get a C2P version:
;* Change copperlist
;* Change wall drawing
;* change floor drawing
;* change object drawing
;* change polygon drawing (ugh)
;* Write a palette generator program in AMOS
;* to provide a good 256 colour palette and
;* convert all graphics files specified
;* (possibly included in the game linker
;* program).
;* Possibly change the wall/floor/object
;* palettes to look nicer with more shades.
;* RE-implement stippling (if not present)
;* as it will look gorgeous now.
;*************************************************

CD32VER					equ		0

FS_HEIGHT_HACK			equ		1 ; 0xABADCAFE - Fullscreen height hack, set non-zero to enable
DISPLAYMSGPORT_HACK		equ		1 ; AL - Level restart freeze hack, set non-zero to enable
SCREEN_TITLEBAR_HACK	equ		1 ; AL - Stop title bar interactions hack, set non-zero to enable

SCREEN_WIDTH			equ		320
SCREEN_HEIGHT			equ		256

	IFNE	FS_HEIGHT_HACK
FS_HEIGHT				equ		SCREEN_HEIGHT-16
FS_HEIGHT_C2P_DIFF		equ		8
	ELSE
FS_HEIGHT				equ		SCREEN_HEIGHT-24
FS_HEIGHT_C2P_DIFF		equ		0
	ENDC

FS_WIDTH				equ		SCREEN_WIDTH
SMALL_WIDTH				equ		192
SMALL_HEIGHT			equ		160

VID_FAST_BUFFER_SIZE	equ		SCREEN_WIDTH*SCREEN_HEIGHT+15		; screen size plus alignment

maxscrdiv				equ		8
max3ddiv				equ		5
PLR_STAND_HEIGHT		equ		12*1024
PLR_CROUCH_HEIGHT		equ		8*1024
scrheight				equ		80
intreqrl				equ		$01f

PLR_MASTER				equ 'm' ; two player master
PLR_SLAVE				equ 's' ; two player slave
PLR_SINGLE				equ 'n' ; Single player

QUIT_KEY				equ RAWKEY_NUM_ASTERISK
;QUIT_KEY				equ RAWKEY_DOT ; for days when I have no numberpad


; ZERO-INITIALISED DATA
				include "bss/system_bss.s"
				include "bss/io_bss.s"
				include "bss/vid_bss.s"
				include "bss/level_bss.s"
				include "bss/ai_bss.s"
				include "bss/anim_bss.s"
				include "bss/player_bss.s"
				include "bss/draw_bss.s"
				include "bss/zone_bss.s"
				include "bss/tables_bss.s"
				include "bss/game_bss.s"

; INITIALISED (DATA) DATA
				include "data/system_data.s"
				include "data/draw_data.s"
				include "data/level_data.s"
				include "data/tables_data.s"
				include "data/text_data.s"
				include "data/game_data.s"
				include "data/vid_data.s"

				section .text,code

				xref _Vid_isRTG
				xdef _startup
; Startup Code
_startup:
				; entry point
				movem.l	d1-a6,-(sp)

				IFD MEMTRACK
				bsr	 Mem_TrackInit
				ENDC

				CALLC	Sys_Init
				tst.l	d0
				beq		.startup_fail

				; since these moved to bss, they need explicit initialisation
				; todo - module initialisation calls
				; XXX following two statements are NOPs
				not.b	Plr1_Mouse_b
				not.b	Plr2_Mouse_b
				move.w	#191,Plr1_Energy_w
				move.w	#191,Plr2_Energy_w
				not.w	Zone_OrderTable_Barrier_w
				st		draw_GouraudFlatsSelected_b

				;lea		VBLANKInt(pc),a1
				;moveq	#INTB_VERTB,d0
				;CALLEXEC AddIntServer

				CALLDEV	Init

				;IFEQ	CD32VER
				;lea		KEYInt(pc),a1
				;moveq	#INTB_PORTS,d0
				;CALLEXEC AddIntServer
				;ENDC

				; init default control method
				IFNE	CD32VER
				clr.b	Plr1_Keys_b
				clr.b	Plr1_Path_b
				clr.b	Plr1_Mouse_b
				st		Plr1_Joystick_b
				clr.b	Plr2_Keys_b
				clr.b	Plr2_Path_b
				clr.b	Plr2_Mouse_b
				st		Plr2_Joystick_b
				ELSE
				clr.b	Plr1_Keys_b
				clr.b	Plr1_Path_b
				st		Plr1_Mouse_b
				clr.b	Plr1_Joystick_b
				clr.b	Plr2_Keys_b
				clr.b	Plr2_Path_b
				st		Plr2_Mouse_b
				clr.b	Plr2_Joystick_b
				ENDC

				IFND	BUILD_WITH_C
				; allocate chunky render buffer in fastmem
				move.l	#MEMF_ANY|MEMF_CLEAR,d1
				move.l	#VID_FAST_BUFFER_SIZE,d0
				CALLEXEC AllocVec ; Note: Can't use Sys_AllocVec yet
				move.l	d0,Vid_FastBufferAllocPtr_l
				;align to 16byte for best C2P perf
				moveq.l	#15,d1
				add.l	d1,d0
				moveq	#-16,d1					; $F0
				and.l	d1,d0
				move.l	d0,Vid_FastBufferPtr_l
				ENDIF

				; Setup constant table
				move.l	#ConstantTable_vl,a0
				moveq	#1,d0
				move.w	#8191,d1

.fill_const:
				move.l	#16384*64,d2 ; 1<<10
				divs.l	d0,d2
; ext.l d2	;c#
				move.l	#64*64*65536,d3
				divs.l	d2,d3
; move.l d3,d4
; asr.l #6,d4
				move.l	d3,(a0)+				; e#
				asr.l	#1,d2					; c#/2.0
				sub.l	#40*64,d2				; d#
				muls.l	d3,d2					; d#*e#
				asr.l	#6,d2
				move.l	d2,(a0)+
				addq	#1,d0
				dbra	d1,.fill_const

;				CALLC	Game_Init ; this might be the best place

				jsr		Game_Start

.startup_fail:
				CALLC	Sys_Done

				IFD MEMTRACK
				bsr	 Mem_TrackDone
				ENDC

				movem.l	(sp)+,d1-a6
				rts

				; Include even in C version for assembly helpers
				include		"modules/system.s"
				include		"modules/message.s"
				include		"modules/game/game_properties.s"
				include		"modules/game/game_preferences.s"
				include		"modules/game/game_progress.s"
				include		"modules/level.s"

				IFD MEMTRACK
				include "modules/dev_memtrack.s"
				ENDC

;*******************************************************************************
; Global data

				align 4
LastZonePtr_l:				dc.l	0
xwobble:					dc.l	0

; Word aligned
xwobxoff:					dc.w	0
xwobzoff:					dc.w	0
CollId:						dc.w	0

View_KeyLook_w: dc.w 0
View_LookMin_w:	dc.w 0
View_LookMax_w:	dc.w 0

; Byte Aligned
Game_MasterQuit_b:			dc.b	0
Game_SlaveQuit_b:			dc.b	0
Game_MasterPaused_b:		dc.b	0
Game_SlavePaused_b:			dc.b	0


;*******************************************************************************

				include "modules/draw.s"

				align 4
Game_ShowIntroText:
				move.l	Lvl_IntroTextPtr_l,a0     ; Pointer to main narrative text
				move.w	Game_LevelNumber_w,d0                  ; Level number
				muls	#82*16,d0                 ; Fixed size of 82 chars per line, 16 lines ?
				add.l	d0,a0                     ; offset into narrative
				move.w	#15,d7                    ; line counter
				move.w	#0,d0                     ; line number

.next_line_loop:
				move.l	Vid_TextScreenPtr_l,a1    ; Planar slice ptr
				CALLC	Draw_LineOfText           ;

				addq	#1,d0                     ; increment line number
				add.w	#82,a0                    ; next line of text
				dbra	d7,.next_line_loop
				rts

Game_ClearIntroText:
				move.l	Vid_TextScreenPtr_l,a0
				move.w	#(10240/16)-1,d0
				move.l	#$0,d1
.lll:
				move.l	d1,(a0)+
				move.l	d1,(a0)+
				move.l	d1,(a0)+
				move.l	d1,(a0)+
				move.l	d1,(a0)+
				move.l	d1,(a0)+
				move.l	d1,(a0)+
				move.l	d1,(a0)+
				dbra	d0,.lll
				rts

Game_Begin:
;				move.w	#0,TXTCOLL
;				move.w	#0,MIXCOLL
;				move.w	#0,TOPCOLL
;
;				bsr		Game_ClearIntroText
;
;				cmp.b	#PLR_SINGLE,Plr_MultiplayerType_b
;				bne.s	.notext
;				bsr		Game_ShowIntroText
.notext:

;charlie:
;				move.l	#TEXTCOP,_custom+cop1lc

; Fade in Level Text
;				move.w	#$10,d0
;				move.w	#7,d1

;.fdup:
;				move.w	d0,TXTCOLL
;				move.w	d0,MIXCOLL
;				add.w	#$121,d0
;.wtframe:
;				btst	#5,_custom+intreqrl
;				beq.s	.wtframe
;				move.w	#$0020,_custom+intreq
;				dbra	d1,.fdup

				move.l	#_custom,a6
				jsr		SETPLAYERS

				jsr		Res_LoadLevelData

noload:
				; What for?
				IFNE	CD32VER
				move.l	#115,d1
				CALLDOS	Delay
				ENDC

				CALLDEV	DataReset

				; Initialise the messages buffer
				CALLC   Msg_Init
				; Record the start. This may write new messages.
				STATS_PLAY

;****************************
;* Initialize level
;****************************
;* Poke all clip offsets into
;* correct bit of level data.
;****************************

				; this is the loaded location of twolev.graph.bin
				move.l	Lvl_GraphicsPtr_l,a0

				; Add the offsets to the base address to calculate pointers for
				; various important level data.
				move.l	TLGT_DoorDataOffset_l(a0),a1
				add.l	a0,a1
				move.l	a1,Lvl_DoorDataPtr_l

				move.l	TLGT_LiftDataOffset_l(a0),a1
				add.l	a0,a1
				move.l	a1,Lvl_LiftDataPtr_l

				move.l	TLGT_SwitchDataOffset_l(a0),a1
				add.l	a0,a1
				move.l	a1,Lvl_SwitchDataPtr_l

				move.l	TLGT_ZoneGraphAddsOffset_l(a0),a1
				add.l	a0,a1
				move.l	a1,Lvl_ZoneGraphAddsPtr_l

				adda.w	#TLGT_ZoneAddsOffset_l,a0
				move.l	a0,Lvl_ZonePtrsPtr_l

				; This is the loaded location of twolev.bin
				move.l	Lvl_DataPtr_l,a4

				; The first 1600 bytes are the fixed length message strings
				lea		LVLT_MESSAGE_LENGTH*LVLT_MESSAGE_COUNT(a4),a1

				lea		TLBT_SizeOf_l(a1),a2
				move.l	a2,Lvl_ControlPointCoordsPtr_l
				move.w	TLBT_NumControlPoints_w(a1),Lvl_NumControlPoints_w
				move.w	TLBT_NumPoints_w(a1),Lvl_NumPoints_w

				move.l	TLBT_PointsOffset_l(a1),a2
				add.l	a4,a2
				move.l	a2,Lvl_PointsPtr_l

				move.w	TLBT_NumPoints_w(a1),d0
				lea		4(a2,d0.w*4),a2
				move.l	a2,PointBrightsPtr_l

				move.w	TLBT_NumZones_w(a1),d0 ; actually 1 less than the zone count, because reasons.
				addq	#1,d0

				move.w  d0,Lvl_NumZones_w


				muls	#80,d0 ; todo - is 80 a fixed length points per zone (e.g. 10x 32-bit x/y pairs) value?
				add.l	d0,a2
				move.l	a2,Lvl_ZoneBorderPointsPtr_l

				; todo - Determine the number of edges. This is probably
				; (TLBT_ObjectDataOffset_l - TLBT_FloorLineOffset_l) / EdgeT_SizeOf_l
				move.l	TLBT_FloorLineOffset_l(a1),a2

				move.l  TLBT_ObjectDataOffset_l(a1),d0
				sub.l	a2,d0
				move.l	d0,Lvl_EdgeCount_l

				add.l	a4,a2
				move.l	a2,Lvl_ZoneEdgePtr_l

				move.w	-2(a2),Lvl_ExitZoneID_w
				move.l	TLBT_ObjectDataOffset_l(a1),a2
				add.l	a4,a2
				move.l	a2,Lvl_ObjectDataPtr_l

;*****************************************
;* Just for charles

; move.w #$6060,6(a2)
; move.l #$d0000,8(a2)
; sub.w #40,4(a2)
; move.w #45*256+45,14(a2)
;****************************************

				; Temporary object buffers used for player and alien projectile entities.
				; todo - why are these embedded in the data file and not just a dynamically added space?
				move.l	TLBT_ShotDataOffset_l(a1),a2
				add.l	a4,a2
				move.l	a2,Plr_ShotDataPtr_l

				move.l	TLBT_AlienShotDataOffset_l(a1),a2
				add.l	a4,a2
				move.l	a2,AI_AlienShotDataPtr_l

				add.l	#ShotT_SizeOf_l*NUM_ALIEN_SHOT_DATA,a2
				move.l	a2,AI_OtherAlienDataPtrs_vl

				move.l	TLBT_ObjectPointsOffset_l(a1),a2
				add.l	a4,a2
				move.l	a2,Lvl_ObjectPointsPtr_l

				move.l	TLBT_Plr1ObjectOffset_l(a1),a2
				add.l	a4,a2
				move.l	a2,Plr1_ObjectPtr_l

				move.l	TLBT_Plr2ObjectOffset_l(a1),a2
				add.l	a4,a2
				move.l	a2,Plr2_ObjectPtr_l

				move.w	TLBT_NumObjects_w(a1),Lvl_NumObjectPoints_w

; bra .noclips

				; TODO - What are we doing here, exactly?
				; a4 => Lvl_DataPtr_l (twolev.bin)
				; a2 => Lvl_ClipsPtr_l (twolev.clips)
				; a1 => Lvl_DataPtr_l + 1600 (twolev.bin, after message strings)
				; a0 => Lvl_ZonePtrsPtr_l (from twolev.graph.bin)
				move.l	Lvl_ClipsPtr_l,a2
				moveq	#0,d0
				move.w	TLBT_NumZones_w(a1),d7
				move.w	d7,Zone_Count_w

.assign_clips:
				move.l	(a0),a3		; Lvl_ZonePtrsPtr_l are 32-bit offsets from Lvl_DataPtr_l
				add.l	a4,a3		; Add the base address to get the pointer to the zone

				; 0xABADCAFE - pointer chase reduction: Preconvert to an array of pointers
				move.l	a3,(a0)+	; Replace Lvl_ZonePtrsPtr_l offset with the actual address

				adda.w	#ZoneT_PotVisibleZoneList_vw,a3	; pointer to zonelist

				; a3 = (UWORD*)(((UBYTE*)Lvl_ZonePtrsPtr_l++] + ZoneT_PotVisibleZoneList_vw)

.do_whole_zone:
				; a3 is pointing to sets of 4 word tuples (or 2,2,4, total size still 8)
				; When tuple[0] < 0, whole list is done
				; When tuple[1] < 0, clip search for the current tuple is done (TBC)
				; tuple[1] contains the runtime ordered distance during the PVS run
				; Unsure what the interpretation of tuple[1] - tuple[3] is
				tst.w	(a3) ; PVST_Zone_w
				blt.s	.no_more_this_zone

				tst.w	PVST_ClipID_w(a3)
				blt.s	.this_one_null

				move.l	d0,d1
				asr.l	#1,d1
				move.w	d1,PVST_ClipID_w(a3) ; value poked back in

.find_next_clip:
				cmp.w	#-2,(a2,d0.l)
				beq.s	.found_next_clip

				addq.l	#2,d0
				bra.s	.find_next_clip

.found_next_clip:
				addq.l	#2,d0

.this_one_null:
				addq	#PVST_SizeOf_l,a3 				; Tuple size
				bra.s	.do_whole_zone

.no_more_this_zone:
				dbra	d7,.assign_clips

				lea		(a2,d0.l),a2
				move.l	a2,Lvl_ConnectTablePtr_l

				IFD BUILD_WITH_C
				movem.l	d0/d1/a0/a1,-(sp)

				DEV_CHECK_SET SKIP_PVS_AMEND,.done_errata

				tst.l	Lvl_ErrataPtr_l
				beq.s	.done_errata

				move.l	Lvl_ErrataPtr_l,a0
				CALLC	Zone_ApplyPVSErrata

.done_errata:
				CALLC	Zone_InitEdgePVS

				movem.l	(sp)+,d0/d1/a0/a1
				ENDC

.noclips:
				clr.b	Plr1_StoodInTop_b
				move.l	#PLR_STAND_HEIGHT,Plr1_SnapHeight_l

				move.l	#Aud_EmptyBuffer_vl,pos1LEFT
				move.l	#Aud_EmptyBuffer_vl,pos2LEFT
				move.l	#Aud_EmptyBuffer_vl,pos1RIGHT
				move.l	#Aud_EmptyBuffer_vl,pos2RIGHT
				move.l	#Aud_EmptyBuffer_vl,pos0LEFT
				move.l	#Aud_EmptyBuffer_vl,pos3LEFT
				move.l	#Aud_EmptyBuffer_vl,pos0RIGHT
				move.l	#Aud_EmptyBuffer_vl,pos3RIGHT
				move.l	#Aud_EmptyBufferEnd,Samp0endLEFT
				move.l	#Aud_EmptyBufferEnd,Samp1endLEFT
				move.l	#Aud_EmptyBufferEnd,Samp0endRIGHT
				move.l	#Aud_EmptyBufferEnd,Samp1endRIGHT
				move.l	#Aud_EmptyBufferEnd,Samp2endLEFT
				move.l	#Aud_EmptyBufferEnd,Samp3endLEFT
				move.l	#Aud_EmptyBufferEnd,Samp2endRIGHT
				move.l	#Aud_EmptyBufferEnd,Samp3endRIGHT

				bset.b	#1,$bfe001

				; clear audio modulation settings
				move.w	#$00ff,_custom+adkcon

				; FIXME: reimplement level blurb
; move.l #Blurbfield,$dff080

				IFD BUILD_WITH_C
				;tst.w	_Vid_isRTG
				;bne.s	.skipChangeScreen
				bra.s .skipChangeScreen
				ENDIF

				IFNE	DISPLAYMSGPORT_HACK
				;empty Vid_DisplayMsgPort_l and set Vid_ScreenBufferIndex_w to 0
				;so the starting point is the same every time
.clrMsgPort:
				move.l	Vid_DisplayMsgPort_l,a0
				CALLEXEC GetMsg
				tst.l	d0
				bne.s	.clrMsgPort
				ENDC

				clr.w	Vid_ScreenBufferIndex_w

.tryAgain:
				move.l	Vid_ScreenBuffers_vl,a1
				move.l	Vid_MainScreen_l,a0
				CALLINT	ChangeScreenBuffer
				tst.l	d0
				beq.s	.tryAgain

				clr.b	Vid_WaitForDisplayMsg_b

.skipChangeScreen:
				jsr		Plr_Initialise
; bsr initobjpos

				; setup audio channels
				move.l	#$dff000,a6

				move.l	#Aud_Null1_vw,$dff0a0
				move.w	#100,$dff0a4
				move.w	#443,$dff0a6
				move.w	#63,$dff0a8

				move.l	#Aud_Null2_vw,$dff0b0
				move.w	#100,$dff0b4
				move.w	#443,$dff0b6
				move.w	#63,$dff0b8

				move.l	#Aud_Null4_vw,$dff0c0
				move.w	#100,$dff0c4
				move.w	#443,$dff0c6
				move.w	#63,$dff0c8

				move.l	#Aud_Null3_vw,$dff0d0
				move.w	#100,$dff0d4
				move.w	#443,$dff0d6
				move.w	#63,$dff0d8

				move.l	#tab,a1
				move.w	#64,d7
				move.w	#0,d6

outerlop:
				move.l	#pretab,a0
				move.w	#255,d5

scaledownlop:
				move.b	(a0)+,d0
				ext.w	d0
				ext.l	d0 ; // ext.b ?
				muls	d6,d0
				asr.l	#6,d0
				move.b	d0,(a1)+
				dbra	d5,scaledownlop
				addq	#1,d6
				dbra	d7,outerlop

				move.l	#$dff000,a6

				; disable audio dma
				move.w	#DMAF_AUDIO,dmacon(a6)
				; enable audio dma
				move.w	#DMAF_SETCLR!DMAF_MASTER!DMAF_AUDIO,dmacon(a6)

				move.w	#$0,potgo(a6)
				move.w	#0,Conditions

				cmp.b	#PLR_SINGLE,Plr_MultiplayerType_b
				beq.s	.nokeys
				move.w	#%111111111111,Conditions
.nokeys:
				move.l	#KeyMap_vb,a5
				clr.b	RAWKEY_ESC(a5)

				move.l	Lvl_MusicPtr_l,mt_data
				clr.b	UseAllChannels

; cmp.b #'b',Prefsfile+3
; bne.s .noback

*********************************

				; TODO - check music is enabled

				st		CHANNELDATA
				jsr		mt_init

*********************************

				st		CHANNELDATA
				st		CHANNELDATA+8

				move.l	Aud_SampleList_vl+6*8,pos0LEFT
				move.l	Aud_SampleList_vl+6*8+4,Samp0endLEFT
				move.l	#PLR_STAND_HEIGHT,Plr1_SnapTargHeight_l
				move.l	#PLR_STAND_HEIGHT,Plr1_SnapHeight_l
				move.l	#PLR_STAND_HEIGHT,Plr2_SnapTargHeight_l
				move.l	#PLR_STAND_HEIGHT,Plr2_SnapHeight_l

				CALLC	Sys_ClearKeyboard

				clr.b	Game_MasterQuit_b

				cmp.b	#PLR_SINGLE,Plr_MultiplayerType_b
				seq		Game_SlaveQuit_b

				DataCacheOn

				move.l	#0,hitcol

NOCLTXT:
				;FIXME: need to load the game palette here?
				clr.b	Plr1_Ducked_b
				clr.b	Plr2_Ducked_b
				clr.b	plr1_TmpDucked_b
				clr.b	plr2_TmpDucked_b

********************************************

;	jmp docredits

********************************************

				st		Game_Running_b
				st		dosounds

				jsr		AI_InitAlienWorkspace

				move.l	#Lvl_CompactMap_vl,a0
				move.l	a0,LastZonePtr_l
				clr.l   d0
				move.w  #256,d1
				bsr		Sys_MemFillLong

				move.l	#Lvl_CompactMap_vl,a0
				move.l	#Lvl_BigMap_vl,a1

				bra		NOALLWALLS

				; unreachable?
				move.l	Lvl_ZoneGraphAddsPtr_l,a2
DOALLWALLS:
				move.l	(a2),d0
				beq.s	nomorezones
				move.l	d0,a3

				addq	#8,a2

				add.l	Lvl_GraphicsPtr_l,a3
				addq	#2,a3
				move.l	a1,a4

innerwalls:
				move.b	(a3),d1
				move.b	1(a3),d0
				bne		doneinner

				tst.b	d1
				blt		noid

				move.b	d1,d3
				and.w	#15,d1

				moveq	#0,d0
				move.w	d1,d2
				add.w	d1,d1
				add.w	d2,d1
				addq	#1,d1
				bset	d1,d0
				btst	#4,d3
				beq.s	.no_door
				addq	#1,d1
				bset	d1,d0

.no_door:
				or.l	d0,(a0)
				move.w	2(a3),(a4)
				move.w	4(a3),2(a4)

noid:
				add.w	#30,a3
				addq	#4,a4

				bra		innerwalls

doneinner:
				add.w	#40,a1
				addq	#4,a0

				bra		DOALLWALLS
nomorezones:

NOALLWALLS:
				move.w	#SMALL_WIDTH/2,Vid_CentreX_w
				move.w	#SMALL_WIDTH,Vid_RightX_w
				move.w	#SMALL_HEIGHT,Vid_BottomY_w
				move.w	#SMALL_HEIGHT/2,TOTHEMIDDLE
				clr.b	Vid_FullScreen_b
				CALLC	Draw_ResetGameDisplay

				st		Plr1_Weapons_vb+1
				st		Plr2_Weapons_vb+1
				move.w	#100,timetodamage
				move.w	#299,d0
				move.l	#AI_Damaged_vw,a0

CLRDAM:
				move.w	#0,(a0)+
				dbra	d0,CLRDAM

				moveq	#0,d0
				move.w	d0,STOPOFFSET
				neg.w	d0
				add.w	TOTHEMIDDLE,d0
				move.w	d0,SMIDDLEY
				muls	#SCREEN_WIDTH,d0
				move.l	d0,SBIGMIDDLEY

				move.w	#0,Plr1_AimSpeed_l
				move.w	#0,Plr2_AimSpeed_l

; init pointer to chipmem render buffers
				move.l	Vid_Screen1Ptr_l,Vid_DisplayScreenPtr_l
				move.l	Vid_Screen2Ptr_l,Vid_DrawScreenPtr_l

; Clear message buffers
;				CALLC	Msg_Init

				; Initialise FPS
				clr.l	Sys_FrameNumber_l
				lea		Sys_PrevFrameTimeECV_q,a0
				CALLC 	Sys_MarkTime

				clr.b	Plr2_Fire_b
				clr.b	Plr2_TmpFire_b
				clr.b	Plr2_Used_b
				clr.b	Plr2_TmpSpcTap_b

				clr.b	plr1_Dead_b
				clr.b	plr2_Dead_b

				move.l	Plr1_ObjectPtr_l,a0
				move.l	Plr2_ObjectPtr_l,a1
				clr.w	EntT_ImpactX_w(a0)
				clr.w	EntT_ImpactY_w(a0)
				clr.w	EntT_ImpactZ_w(a0)
				clr.w	EntT_ImpactX_w(a1)
				clr.w	EntT_ImpactY_w(a1)
				clr.w	EntT_ImpactZ_w(a1)

				clr.l	Plr1_SnapXSpdVal_l
				clr.l	Plr1_SnapZSpdVal_l
				clr.l	Plr1_SnapYVel_l
				clr.l	Plr2_SnapXSpdVal_l
				clr.l	Plr2_SnapZSpdVal_l
				clr.l	Plr2_SnapYVel_l

***************************************************************shoehorn this in here AL
				tst.b	Vid_FullScreen_b
				beq.s	.small

				move.w	#6,View_KeyLook_w
				move.w	#FS_HEIGHT/2,d0
				move.w	d0,View_LookMin_w
				neg.w	d0
				move.w	d0,View_LookMax_w
				bra	.big

.small
				move.w	#4,View_KeyLook_w
				move.w	#SMALL_HEIGHT/2,d0
				move.w	d0,View_LookMin_w
				neg.w	d0
				move.w	d0,View_LookMax_w

.big
***************************************************************
;hack to allow the game to start in 1x2 pixel mode in AGA screenmode when set in the prefs.cfg
;should probably test if we are using RTG and skip if true.
				tst	Vid_DoubleHeight_b
				beq	.skipDH
				st		LASTDH
				bsr	startCopper
				CALLC	vid_SetupDoubleheightCopperlist
.skipDH:
**************************************************************
game_main_loop:
				move.w	#%110000000000,_custom+potgo

				cmp.b	#PLR_MASTER,Plr_MultiplayerType_b
				bne		.notmess
				tst.b	plr2_Dead_b
				bne		.notmess

				tst.w	Plr2_Health_w
				bgt		.notmess

				st		plr2_Dead_b

				jsr		GetRand

				swap	d0
				clr.w	d0
				swap	d0
				divs	#9,d0
				swap	d0
				muls	#GAME_DM_VICTORY_MESSAGE_LENGTH,d0
				add.l	#Game_TwoPlayerVictoryMessages_vb,d0
				move.l  d0,a0
				move.w  #GAME_DM_VICTORY_MESSAGE_LENGTH,d0
				CALLC   Msg_PushLine

				move.l	Plr2_ObjectPtr_l,a0
				move.l	GLF_DatabasePtr_l,a6
				add.l	#GLFT_Player2Graphic_w,a6
				move.w	(a6),d7
				move.w	d7,d1
				move.l	GLF_DatabasePtr_l,a6
				add.l	#GLFT_AlienDefs_l,a6
				muls	#AlienT_SizeOf_l,d1
				add.l	d1,a6
				move.b	AlienT_SplatType_w+1(a6),d0
				move.b	d0,Anim_SplatType_w
				move.l	Plr2_ZonePtr_l,a1
				move.w	(a1),ObjT_ZoneID_w(a0)
				move.w	Plr2_TmpXOff_l,newx
				move.w	Plr2_TmpZOff_l,newz
				move.w	#7,d2
				jsr		Anim_ExplodeIntoBits

				FREE_OBJ	a0

.notmess:
				cmp.b	#PLR_SLAVE,Plr_MultiplayerType_b
				bne		.notmess2
				tst.b	plr1_Dead_b
				bne		.notmess2

				tst.w	Plr1_Health_w
				bgt		.notmess2

				st		plr1_Dead_b

				jsr		GetRand
				swap	d0
				clr.w	d0
				swap	d0
				divs	#9,d0
				swap	d0
				muls	#GAME_DM_VICTORY_MESSAGE_LENGTH,d0
				add.l	#Game_TwoPlayerVictoryMessages_vb,d0
				move.l	d0,a0
				move.w  #GAME_DM_VICTORY_MESSAGE_LENGTH,d0
				CALLC   Msg_PushLine

				move.l	Plr1_ObjectPtr_l,a0
				move.l	GLF_DatabasePtr_l,a6
				add.l	#GLFT_Player1Graphic_w,a6
				move.w	(a6),d7
				move.w	d7,d1
				move.l	GLF_DatabasePtr_l,a6
				add.l	#GLFT_AlienDefs_l,a6
				muls	#AlienT_SizeOf_l,d1
				add.l	d1,a6

				move.b	AlienT_SplatType_w+1(a6),d0
				move.b	d0,Anim_SplatType_w

				move.l	Plr1_ZonePtr_l,a1
				move.w	(a1),ObjT_ZoneID_w(a0)
				move.w	Plr1_TmpXOff_l,newx
				move.w	Plr1_TmpZOff_l,newz
				move.w	#7,d2
				jsr		Anim_ExplodeIntoBits

				FREE_OBJ	a0
.notmess2:
				;FIXME: should use _LVOWritePotgo here!
				move.w	#%110000000000,_custom+potgo ; POTGO -start Potentiometer reading
													; FIXME: shouldn't this be in a regular interrupt, like VBL?

				move.b	MAPON,draw_RenderMap_b

				move.b	Vid_FullScreenTemp_b,d0
				move.b	Vid_FullScreen_b,d1
				eor.b	d1,d0
				beq		.noFullscreenSwitch

				move.b	Vid_FullScreenTemp_b,Vid_FullScreen_b

				bsr		SetupRenderbufferSize
				CALLC	vid_SetupDoubleheightCopperlist

.noFullscreenSwitch:
				move.l	#KeyMap_vb,a5

				cmp.b	#PLR_SINGLE,Plr_MultiplayerType_b
				bne		.nopause
				tst.b	RAWKEY_P(a5)
				beq.s	.nopause
				clr.b	Game_Running_b

.waitrel:
				tst.b	Plr1_Joystick_b
				beq.s	.NOJOY
				jsr		_ReadJoy1

.NOJOY:
				tst.b	RAWKEY_P(a5)
				bne.s	.waitrel

				bsr		Game_Pause

				st		Game_Running_b
.nopause:

; FIXME: "player is hit" color handling missing
;				move.l	hitcol,d0		; hitcol seems to "shift" the color palette selection
;				move.l	d0,d1			; into a red palette if the player is hit
;				add.l	#PALETTEBIT,d1
;				tst.l	d0
;				beq.s	nofadedownhc
;				sub.l	#2116,d0
;				move.l	d0,hitcol

nofadedownhc:
				;bsr		Vid_LoadMainPalette		; should only reload the palatte when hit

				st		READCONTROLS
				move.l	#$dff000,a6

				cmp.b	#PLR_SINGLE,Plr_MultiplayerType_b
				beq		.nopause

				move.b	Game_SlavePaused_b,d0
				or.b	Game_MasterPaused_b,d0
				beq.s	.nopause
				clr.b	Game_Running_b

				move.l	#KeyMap_vb,a5
.waitrel:
				cmp.b	#PLR_SLAVE,Plr_MultiplayerType_b
				beq.s	.RE2
				tst.b	Plr1_Joystick_b
				beq.s	.NOJOY
				jsr		_ReadJoy1
				bra		.RE1
.RE2:
				tst.b	Plr2_Joystick_b
				beq.s	.NOJOY
				jsr		_ReadJoy2
.RE1:
.NOJOY:
				tst.b	RAWKEY_P(a5)
				bne.s	.waitrel

				bsr		Game_Pause

				cmp.b	#PLR_MASTER,Plr_MultiplayerType_b
				bne.s	.slavelast

				jsr		SENDFIRST

				bra		.masfirst

.slavelast:
				jsr		RECFIRST

.masfirst:
				clr.b	Game_SlavePaused_b
				clr.b	Game_MasterPaused_b
				st		Game_Running_b

.nopause:
				clr.l	d2
				move.w	Sys_FPSLimit_w,d2
				bmi.s	.no_vbl

				;move.l	Vid_VBLCountLast_l,d2
				add.l	Vid_VBLCountLast_l,d2
				;add.w	Sys_FPSLimit_w,d2

.waitvbl:
				;move.l	Vid_VBLCount_l,d3
				;cmp.l	d2,d3
				cmp.l	Vid_VBLCount_l,d2
				blt.s	.skipWaitTOF
				CALLGRAF	WaitTOF
				bra.s	.waitvbl

.skipWaitTOF:
				move.l	Vid_VBLCount_l,Vid_VBLCountLast_l
.no_vbl:
				;move.l	d3,Vid_VBLCountLast_l

; Swap screen bitmaps
				move.l	Vid_DrawScreenPtr_l,d0
				move.l	Vid_DisplayScreenPtr_l,Vid_DrawScreenPtr_l
				move.l	d0,Vid_DisplayScreenPtr_l

				cmp.b	#PLR_SLAVE,Plr_MultiplayerType_b
				beq.s	nowaitslave

				; Waiting for old copperlist interrupt to switch screens?
;waitfortop:
;				btst.b	#0,intreqrl(a6)
;				beq.b	waitfortop
;				move.w	#$1,intreq(a6)

; move.l #PLR1_GunData,Plr_GunDataPtr_l
				move.b	Plr1_GunSelected_b,plr_GunSelected_b
				bra		waitmaster

nowaitslave:
; move.l #PLR2_GunData,Plr_GunDataPtr_l
				move.b	Plr2_GunSelected_b,plr_GunSelected_b
waitmaster:

*****************************************************************

				IFD BUILD_WITH_C
				tst.w	_Vid_isRTG
				bne		.screenSwapDone
				ENDIF
				; Flip screens

				; Wait on prior frame to be displayed.
				; FIXME: this could waste time synchrously waiting on the scanout to happen if we manage
				; to fully produce the next frame before the last frame has been scanned out.
				; We could move the screen flipping into its own thread that flips asynchronously.
				; It does not seem very practical, though as this scenario
				tst.b	Vid_WaitForDisplayMsg_b
				beq.s	.noWait

				move.l	Vid_DisplayMsgPort_l,a0
				move.l	a0,a3
				CALLEXEC WaitPort				; wait for when the old image has been displayed
.clrMsgPort:
				move.l	a3,a0
				CALLEXEC GetMsg					; clear message port
				tst.l	d0
				bne.s	.clrMsgPort

.noWait:
				move.w	Vid_ScreenBufferIndex_w,d2
				lea		Vid_ScreenBuffers_vl,a1
				eor.w	#1,d2					; flip  screen index
				move.l	(a1,d2.w*4),a1			; grab ScreenBuffer pointer

				move.l	Vid_MainScreen_l,a0
				CALLINT	ChangeScreenBuffer		; Vid_DisplayMsgPort_l will be notified if this image had been fully scanned out

				tst.l	d0
				beq.s	.failed

				move.w	d2,Vid_ScreenBufferIndex_w
				st.b	Vid_WaitForDisplayMsg_b
				bra.s	.screenSwapDone

.failed:
				clr.b	Vid_WaitForDisplayMsg_b		; last attempt failed, so don't wait for next message

.screenSwapDone:
				CALLC	Sys_FrameLap
				CALLDEV	PrintStats
				CALLDEV	MarkFrameBegin

				IFND	DEV
				CALLC	Sys_ShowFPS
				ENDC

				move.l	#SMIDDLEY,a0
				movem.l	(a0)+,d0/d1
				move.l	d0,Vid_CentreY_w	; why long?
				move.l	d1,Vid_CentreY_w+4

; 0xABADCAFE - this needs a countdown timer to slow down the water animation
				move.l	draw_LastWaterFramePtr_l,a0
				move.l	(a0)+,draw_WaterFramePtr_l
				cmp.l	#draw_EndWaterFramePtrs_l,a0
				blt.s	okwat

				move.l	#draw_WaterFramePtrs_vl,a0
okwat:
				move.l	a0,draw_LastWaterFramePtr_l

				add.w	#640,wtan
				AMOD_I	wtan
				add.l	#1,wateroff
				and.l	#$3fff3fff,wateroff

				move.l	Plr1_XOff_l,plr1_OldX_l
				move.l	Plr1_ZOff_l,plr1_OldZ_l
				move.l	Plr2_XOff_l,plr2_OldX_l
				move.l	Plr2_ZOff_l,plr2_OldZ_l

				move.l	#$dff000,a6

				cmp.b	#PLR_SLAVE,Plr_MultiplayerType_b
				beq		ASlaveShouldWaitOnHisMaster

				cmp.b	#PLR_SINGLE,Plr_MultiplayerType_b
				bne		NotOnePlayer

				SAVEREGS

				moveq	#0,d0
				move.b	plr_GunSelected_b,d0
				move.l	GLF_DatabasePtr_l,a6
				add.l	#GLFT_ShootDefs_l,a6
				move.w	(a6,d0.w*8),d0

				move.l	#Plr1_AmmoCounts_vw,a6
				move.w	(a6,d0.w*2),d0
				move.w	d0,draw_DisplayAmmoCount_w

				GETREGS

				move.w	Plr1_Health_w,draw_DisplayEnergyCount_w

				move.w	Anim_FramesToDraw_w,Anim_TempFrames_w
				cmp.w	#15,Anim_TempFrames_w
				blt.s	.okframe
				move.w	#15,Anim_TempFrames_w

.okframe:
				move.w	#0,Anim_FramesToDraw_w
				move.l	Plr1_SnapXOff_l,Plr1_TmpXOff_l
				move.l	Plr1_SnapZOff_l,Plr1_TmpZOff_l
				move.l	Plr1_SnapYOff_l,Plr1_TmpYOff_l
				move.l	Plr1_SnapHeight_l,plr1_TmpHeight_l
				move.w	Plr1_SnapAngPos_w,Plr1_TmpAngPos_w
				move.w	Plr1_Bobble_w,plr1_TmpBobble_w
				move.b	Plr1_Clicked_b,Plr1_TmpClicked_b
				move.b	Plr1_Fire_b,Plr1_TmpFire_b
				clr.b	Plr1_Clicked_b
				move.b	Plr1_Used_b,Plr1_TmpSpcTap_b
				clr.b	Plr1_Used_b
				move.b	Plr1_Ducked_b,plr1_TmpDucked_b
				move.b	Plr1_GunSelected_b,Plr1_TmpGunSelected_b

				bsr		Plr1_Control

				move.l	Plr1_ZonePtr_l,a0
				move.l	ZoneT_Roof_l(a0),Zone_SplitHeight_l
				move.w	Plr1_TmpXOff_l,THISPLRxoff
				move.w	Plr1_TmpZOff_l,THISPLRzoff


				move.l	#$60000,Plr2_TmpYOff_l
				move.l	Plr2_ObjectPtr_l,a0

				FREE_ENT	a0

				move.b	#0,ObjT_SeePlayer_b(a0)
				move.l	#BollocksRoom,Plr2_ZonePtr_l

				bra		donetalking

NotOnePlayer:
				move.l	#KeyMap_vb,a5
				tst.b	RAWKEY_P(a5)
				sne		Game_MasterPaused_b

*********************************
				move.w	Plr1_Health_w,draw_DisplayEnergyCount_w
; change this back
*********************************
				SAVEREGS

				moveq	#0,d0
				move.b	plr_GunSelected_b,d0
				move.l	GLF_DatabasePtr_l,a6
				add.l	#GLFT_ShootDefs_l,a6
				move.w	(a6,d0.w*8),d0

				move.l	#Plr1_AmmoCounts_vw,a6
				move.w	(a6,d0.w*2),d0
				move.w	d0,draw_DisplayAmmoCount_w

				GETREGS

				jsr		SENDFIRST

				move.w	Anim_FramesToDraw_w,Anim_TempFrames_w
				cmp.w	#15,Anim_TempFrames_w
				blt.s	.okframe
				move.w	#15,Anim_TempFrames_w
.okframe:
				move.w	#0,Anim_FramesToDraw_w

				move.l	Plr1_SnapXOff_l,Plr1_TmpXOff_l
				move.l	Plr1_SnapZOff_l,Plr1_TmpZOff_l
				move.l	Plr1_SnapYOff_l,Plr1_TmpYOff_l
				move.l	Plr1_SnapHeight_l,plr1_TmpHeight_l
				move.w	Plr1_SnapAngPos_w,Plr1_TmpAngPos_w
				move.w	Plr1_Bobble_w,plr1_TmpBobble_w
				move.b	Plr1_Clicked_b,Plr1_TmpClicked_b
				clr.b	Plr1_Clicked_b
				move.b	Plr1_Fire_b,Plr1_TmpFire_b
				move.b	Plr1_Used_b,Plr1_TmpSpcTap_b
				clr.b	Plr1_Used_b
				move.b	Plr1_Ducked_b,plr1_TmpDucked_b
				move.b	Plr1_GunSelected_b,Plr1_TmpGunSelected_b

				move.l	Plr1_AimSpeed_l,d0
				jsr		SENDFIRST
				move.l	d0,Plr2_AimSpeed_l

				move.l	Plr1_TmpXOff_l,d0
				jsr		SENDFIRST
				move.l	d0,Plr2_TmpXOff_l

				move.l	Plr1_TmpZOff_l,d0
				jsr		SENDFIRST
				move.l	d0,Plr2_TmpZOff_l

				move.l	Plr1_TmpYOff_l,d0
				jsr		SENDFIRST
				move.l	d0,Plr2_TmpYOff_l

				move.l	plr1_TmpHeight_l,d0
				jsr		SENDFIRST
				move.l	d0,plr2_TmpHeight_l

				move.w	Plr1_TmpAngPos_w,d0
				swap	d0
				move.w	plr1_TmpBobble_w,d0
				jsr		SENDFIRST
				move.w	d0,plr2_TmpBobble_w
				swap	d0
				move.w	d0,Plr2_TmpAngPos_w


				move.w	Anim_TempFrames_w,d0
				swap	d0
				move.b	Plr1_TmpSpcTap_b,d0
				lsl.w	#8,d0
				move.b	Plr1_TmpClicked_b,d0
				jsr		SENDFIRST
				move.b	d0,Plr2_TmpClicked_b
				lsr.w	#8,d0
				move.b	d0,Plr2_TmpSpcTap_b

				move.w	Rand1,d0
				swap	d0
				move.b	plr1_TmpDucked_b,d0
				or.b	Plr1_Squished_b,d0
				lsl.w	#8,d0
				move.b	Plr1_TmpGunSelected_b,d0
				jsr		SENDFIRST
				move.b	d0,Plr2_TmpGunSelected_b
				lsr.w	#8,d0
				move.b	d0,plr2_TmpDucked_b

				move.b	Plr1_TmpFire_b,d0
				lsl.w	#8,d0
				move.b	Game_MasterQuit_b,d0
				or.b	d0,Game_SlaveQuit_b
				swap	d0
				move.b	Game_MasterPaused_b,d0
				or.b	d0,Game_SlavePaused_b
				jsr		SENDFIRST
				or.b	d0,Game_MasterPaused_b
				or.b	d0,Game_SlavePaused_b
				swap	d0
				or.b	d0,Game_SlaveQuit_b
				or.b	d0,Game_MasterQuit_b
				lsr.w	#8,d0
				move.b	d0,Plr2_TmpFire_b

				move.w	Plr1_Health_w,d0
				jsr		SENDFIRST
				move.w	d0,Plr2_Health_w

				bsr		Plr1_Control
				bsr		Plr2_Control
				move.l	Plr1_ZonePtr_l,a0
				move.l	ZoneT_Roof_l(a0),Zone_SplitHeight_l
				move.w	Plr1_TmpXOff_l,THISPLRxoff
				move.w	Plr1_TmpZOff_l,THISPLRzoff

				bra		donetalking

ASlaveShouldWaitOnHisMaster:
				move.l	#KeyMap_vb,a5
				tst.b	RAWKEY_P(a5)
				sne		Game_SlavePaused_b

				SAVEREGS

				moveq	#0,d0
				move.b	plr_GunSelected_b,d0
				move.l	GLF_DatabasePtr_l,a6
				add.l	#GLFT_ShootDefs_l,a6
				move.w	(a6,d0.w*8),d0

				move.l	#Plr2_AmmoCounts_vw,a6
				move.w	(a6,d0.w*2),d0
				move.w	d0,draw_DisplayAmmoCount_w

				GETREGS

				move.w	Plr2_Health_w,draw_DisplayEnergyCount_w

				jsr		RECFIRST

				move.l	Plr2_SnapXOff_l,Plr2_TmpXOff_l
				move.l	Plr2_SnapZOff_l,Plr2_TmpZOff_l
				move.l	Plr2_SnapYOff_l,Plr2_TmpYOff_l
				move.l	Plr2_SnapHeight_l,plr2_TmpHeight_l
				move.w	Plr2_SnapAngPos_w,Plr2_TmpAngPos_w
				move.w	Plr2_Bobble_w,plr2_TmpBobble_w
				move.b	Plr2_Clicked_b,Plr2_TmpClicked_b
				clr.b	Plr2_Clicked_b
				move.b	Plr2_Fire_b,Plr2_TmpFire_b
				move.b	Plr2_Used_b,Plr2_TmpSpcTap_b
				clr.b	Plr2_Used_b
				move.b	Plr2_Ducked_b,plr2_TmpDucked_b
				move.b	Plr2_GunSelected_b,Plr2_TmpGunSelected_b

				move.l	Plr2_AimSpeed_l,d0
				jsr		RECFIRST
				move.l	d0,Plr1_AimSpeed_l

				move.l	Plr2_TmpXOff_l,d0
				jsr		RECFIRST
				move.l	d0,Plr1_TmpXOff_l

				move.l	Plr2_TmpZOff_l,d0
				jsr		RECFIRST
				move.l	d0,Plr1_TmpZOff_l

				move.l	Plr2_TmpYOff_l,d0
				jsr		RECFIRST
				move.l	d0,Plr1_TmpYOff_l

				move.l	plr2_TmpHeight_l,d0
				jsr		RECFIRST
				move.l	d0,plr1_TmpHeight_l

				move.w	Plr2_TmpAngPos_w,d0
				swap	d0
				move.w	plr2_TmpBobble_w,d0
				jsr		RECFIRST
				move.w	d0,plr1_TmpBobble_w
				swap	d0
				move.w	d0,Plr1_TmpAngPos_w

				move.b	Plr2_TmpSpcTap_b,d0
				lsl.w	#8,d0
				move.b	Plr2_TmpClicked_b,d0
				jsr		RECFIRST
				move.b	d0,Plr1_TmpClicked_b
				lsr.w	#8,d0
				move.b	d0,Plr1_TmpSpcTap_b
				swap	d0
				move.w	d0,Anim_TempFrames_w

				move.b	plr2_TmpDucked_b,d0
				or.b	Plr2_Squished_b,d0
				lsl.w	#8,d0
				move.b	Plr2_TmpGunSelected_b,d0
				jsr		RECFIRST
				move.b	d0,Plr1_TmpGunSelected_b
				lsr.w	#8,d0
				move.b	d0,plr1_TmpDucked_b
				swap	d0
				move.w	d0,Rand1

				move.b	Plr2_TmpFire_b,d0
				lsl.w	#8,d0
				move.b	Game_SlaveQuit_b,d0
				or.b	d0,Game_MasterQuit_b
				swap	d0
				move.b	Game_SlavePaused_b,d0
				or.b	d0,Game_MasterPaused_b
				jsr		RECFIRST
				or.b	d0,Game_MasterPaused_b
				or.b	d0,Game_SlavePaused_b
				swap	d0
				or.b	d0,Game_SlaveQuit_b
				or.b	d0,Game_MasterQuit_b
				lsr.w	#8,d0
				move.b	d0,Plr1_TmpFire_b

				move.w	Plr2_Health_w,d0
				jsr		RECFIRST
				move.w	d0,Plr1_Health_w

				bsr		Plr1_Control
				bsr		Plr2_Control
				move.w	Plr2_TmpXOff_l,THISPLRxoff
				move.w	Plr2_TmpZOff_l,THISPLRzoff
				move.l	Plr2_ZonePtr_l,a0
				move.l	ZoneT_Roof_l(a0),Zone_SplitHeight_l

donetalking:
				move.l	#Zone_BrightTable_vl,a1
				move.l	Lvl_ZonePtrsPtr_l,a2
				move.l	Plr2_PotVisibleZoneListPtr_l,a0
; move.l plr2_PointsToRotatePtr_l,a5
				move.l	a0,a5
				cmp.b	#PLR_SLAVE,Plr_MultiplayerType_b
				beq.s	doallz
				move.l	Plr1_PotVisibleZoneListPtr_l,a0
; move.l plr1_PointsToRotatePtr_l,a5
				move.l	a0,a5

doallz:
				move.w	(a0),d0
				blt.s	doneallz
				add.w	#8,a0
				move.l	(a2,d0.w*4),a3
				move.w	ZoneT_Brightness_w(a3),d2
				blt.s	justbright

				move.w	d2,d3
				lsr.w	#8,d3
				tst.b	d3
				beq.s	justbright

				move.l	#Anim_BrightTable_vw,a4
				move.w	-2(a4,d3.w*2),d2

justbright:
				; 0xABADCAFE division pogrom
				; Following code basically multiplies by 1.6
				;muls	#32,d2
				;divs	#20,d2

				; Approximation (8-bit prec)
				muls	#410,d2
				asr.l	#8,d2

				move.w	d2,(a1,d0.w*4)
				move.w	ZoneT_UpperBrightness_w(a3),d2
				blt.s	justbright2

				move.w	d2,d3
				lsr.w	#8,d3
				tst.b	d3
				beq.s	justbright2

				move.l	#Anim_BrightTable_vw,a4
				move.w	-2(a4,d3.w*2),d2

justbright2:
				; 0xABADCAFE division pogrom
				; Following code basically multiplies by 1.6
				;muls	#32,d2
				;divs	#20,d2

				; Approximation (8-bit prec)
				muls	#410,d2
				asr.l	#8,d2

				move.w	d2,2(a1,d0.w*4)
				bra		doallz

doneallz:
				move.l	PointBrightsPtr_l,a2
				move.l	#CurrentPointBrights_vl,a3

justtheone:
				move.w	(a5),d0
				blt		whythehell
				addq	#8,a5
				muls	#40,d0
				move.w	#39,d7

allinzone:
				move.w	(a2,d0.w*2),d2

				tst.b	d2
				blt.s	.justbright
				move.w	d2,d3
				lsr.w	#8,d3
				tst.b	d3
				beq.s	.justbright

				move.w	d3,d4
				and.w	#$f,d3
				lsr.w	#4,d4
				add.w	#1,d4
				move.l	#Anim_BrightTable_vw,a0
				move.w	-2(a0,d3.w*2),d3 ; 0xABADCAFE - why -2? Is this the cause of the odd zone light up?
				ext.w	d2
				sub.w	d2,d3
				muls	d4,d3
				asr.w	#4,d3
				add.w	d3,d2

.justbright:
				ext.w	d2
				; 0xABADCAFE division pogrom
				; Following code basically multiplies by 1.55
				; TODO - was it meant to be 1.6 ?
				;muls	#31,d2
				;divs	#20,d2

				; Approximation (8-bit)
				muls	#397,d2
				asr.l	#8,d2

				bge.s	.itspos
				sub.w	#600,d2
.itspos:
				add.w	#300,d2

				move.w	d2,(a3,d0.w*2)
				addq	#1,d0
				dbra	d7,allinzone

				bra		justtheone

whythehell:
				move.l	Plr1_ZonePtr_l,a0
				move.l	#CurrentPointBrights_vl,a1
				move.l	Lvl_ZoneBorderPointsPtr_l,a2
				move.w	(a0),d0
				muls	#10,d0
				lea		(a2,d0.w*2),a2
				lea		(a1,d0.w*8),a1

				moveq	#9,d7
				moveq	#0,d0
				moveq	#0,d1

findaverage:
				tst.w	(a2)+
				blt.s	.foundaverage
				addq	#1,d0
				move.w	(a1)+,d2
				bge.s	.okpos
				neg.w	d2

.okpos:
				add.w	d2,d1
				dbra	d7,findaverage

.foundaverage:
				ext.l	d1
				divs	d0,d1
				sub.w	#300,d1
				move.w	d1,Plr1_RoomBright_w

				cmp.b	#PLR_SINGLE,Plr_MultiplayerType_b
				beq		nosee

				move.l	Plr1_ZonePtr_l,Obj_FromZonePtr_l
				move.l	Plr2_ZonePtr_l,Obj_ToZonePtr_l
				move.w	Plr1_TmpXOff_l,Viewerx
				move.w	Plr1_TmpZOff_l,Viewerz
				move.l	Plr1_TmpYOff_l,d0
				asr.l	#7,d0
				move.w	d0,Viewery
				move.w	Plr2_TmpXOff_l,Targetx
				move.w	Plr2_TmpZOff_l,Targetz
				move.l	Plr2_TmpYOff_l,d0
				asr.l	#7,d0
				move.w	d0,Targety
				move.b	Plr1_StoodInTop_b,ViewerTop
				move.b	Plr2_StoodInTop_b,TargetTop
				jsr		CanItBeSeen

				move.l	Plr1_ObjectPtr_l,a0
				move.b	CanSee,d0
				and.b	#2,d0
				move.b	d0,ObjT_SeePlayer_b(a0)
				move.l	Plr2_ObjectPtr_l,a0
				move.b	CanSee,d0
				and.b	#1,d0
				move.b	d0,ObjT_SeePlayer_b(a0)

nosee:
				move.w	Anim_TempFrames_w,d0
				add.w	d0,plr1_TmpHoldDown_w
				cmp.w	#30,plr1_TmpHoldDown_w
				blt.s	oklength
				move.w	#30,plr1_TmpHoldDown_w

oklength:
				tst.b	Plr1_TmpFire_b
				bne.s	okstillheld
				sub.w	d0,plr1_TmpHoldDown_w
				bge.s	okstillheld
				move.w	#0,plr1_TmpHoldDown_w

okstillheld:

				move.w	Anim_TempFrames_w,d0
				add.w	d0,plr2_TmpHoldDown_w

				cmp.w	#30,plr2_TmpHoldDown_w
				blt.s	oklength2
				move.w	#30,plr2_TmpHoldDown_w
oklength2:


				tst.b	Plr2_TmpFire_b
				bne.s	okstillheld2
				sub.w	d0,plr2_TmpHoldDown_w
				bge.s	okstillheld2
				move.w	#0,plr2_TmpHoldDown_w

okstillheld2:
				move.w	Anim_TempFrames_w,d1
				bgt.s	noze
				moveq	#1,d1

noze:
				move.w	Plr1_XOff_l,d0
				sub.w	plr1_OldX_l,d0
				asl.w	#4,d0
				ext.l	d0
				divs	d1,d0
				move.w	d0,XDiff_w
				move.w	Plr2_XOff_l,d0
				sub.w	plr2_OldX_l,d0
				asl.w	#4,d0
				ext.l	d0
				divs	d1,d0
				move.w	Plr1_ZOff_l,d0
				sub.w	plr1_OldZ_l,d0
				asl.w	#4,d0
				ext.l	d0
				divs	d1,d0
				move.w	d0,ZDiff_w
				move.w	Plr2_ZOff_l,d0
				sub.w	plr2_OldZ_l,d0
				asl.w	#4,d0
				ext.l	d0
				divs	d1,d0

				cmp.b	#PLR_SLAVE,Plr_MultiplayerType_b
				beq.s	ImPlayer2OhYesIAm
				bsr		Plr1_Use
				bra		IWasPlayer1

ImPlayer2OhYesIAm:
				bsr		Plr2_Use

IWasPlayer1:
				cmp.b	#PLR_SLAVE,Plr_MultiplayerType_b
				beq		drawplayer2

				move.w	#0,scaleval

				move.l	Plr1_XOff_l,Plr_XOff_l
				move.l	Plr1_YOff_l,Plr_YOff_l
				move.l	Plr1_ZOff_l,Plr_ZOff_l
				move.w	Plr1_AngPos_w,Vis_AngPos_w
				move.w	Plr1_CosVal_w,Vis_CosVal_w
				move.w	Plr1_SinVal_w,Vis_SinVal_w
				move.l	Plr1_PotVisibleZoneListPtr_l,Lvl_ListOfGraphRoomsPtr_l
				move.l	plr1_PointsToRotatePtr_l,PointsToRotatePtr_l
				move.b	Plr1_Echo_b,PLREcho
				move.l	Plr1_ZonePtr_l,ZonePtr_l

				move.l	#KeyMap_vb,a5
				moveq	#0,d5
				move.b	look_behind_key,d5
				tst.b	(a5,d5.w)
				beq.s	.nolookback

				move.l	Plr1_ObjectPtr_l,a0
				FREE_OBJ_2	a0,ENT_NEXT_2 ; weapon in hand
				eor.w	#SINE_SIZE,Vis_AngPos_w
				neg.w	Vis_CosVal_w					; view direction 180deg
				neg.w	Vis_SinVal_w

.nolookback:
*******************************************************************************
;	add a check here for rendering player weapon object
				tst.b	Prefs_ShowWeapon_b
				beq.s	.showWeapon
				move.l	Plr1_ObjectPtr_l,a0
				FREE_OBJ_2	a0,ENT_NEXT_2 ; weapon in hand
.showWeapon
*******************************************************************************
				jsr		Zone_OrderZones
				jsr		objmoveanim

				; ASM build only
				IFND BUILD_WITH_C
				jsr		Draw_BorderEnergyBar
				jsr		Draw_BorderAmmoBar
				ENDIF

;********************************************
;************* Do reflection ****************
;
; move.l Lvl_ListOfGraphRoomsPtr_l,a0
; move.l Lvl_ZonePtrsPtr_l,a1
;checkwaterheights
; move.w (a0),d0
; blt allzonesdone
; addq #8,a0
; move.l (a1,d0.w*4),a2
;
; add.l Lvl_DataPtr_l,a2
;
; move.l ZoneT_Water_l(a2),d0
; cmp.l ZoneT_Floor_l(a2),d0
; blt.s WEHAVEAHEIGHT
;
; bra.s checkwaterheights
;
;WEHAVEAHEIGHT:
;
; sub.l Plr_YOff_l,d0
; blt.s underwater
;
; add.l d0,d0
; add.l d0,Plr_YOff_l
;
; move.l FASTBUFFER2,Vid_FastBufferPtr_l
; move.w #0,Draw_LeftClip_w
; move.w Vid_RightX_w,Draw_RightClip_w
; move.w #0,Draw_DefTopClip_w
; move.w #Vid_BottomY_w/2,Draw_DefBottomClip_w
; move.w #0,draw_TopClip_w
; move.w #Vid_BottomY_w/2,draw_BottomClip_w
;
; clr.b DOANYWATER
;
; bsr DrawDisplay
;
;allzonesdone:
;underwater:

********************************************

				st		DOANYWATER

				move.l	Plr1_YOff_l,Plr_YOff_l

				move.w	#0,Draw_LeftClip_w
				move.w	Vid_RightX_w,Draw_RightClip_w

				move.w	Vid_LetterBoxMarginHeight_w,d0
				;move.w	#0,Draw_DefTopClip_w
				;add.w	d0,Draw_DefTopClip_w
				;move.w	Vid_BottomY_w,Draw_DefBottomClip_w
				;sub.w	d0,Draw_DefBottomClip_w

				move.w	#0,draw_TopClip_w
				add.w	d0,draw_TopClip_w
				move.w	Vid_BottomY_w,draw_BottomClip_w
				sub.w	d0,draw_BottomClip_w
; sub.l #10*104*4,frompt
; sub.l #10*104*4,midpt

* Subroom loop

				bsr		DrawDisplay

				bra		nodrawp2

drawplayer2:
				move.w	#0,scaleval
				move.l	Plr2_XOff_l,Plr_XOff_l
				move.l	Plr2_YOff_l,Plr_YOff_l
				move.l	Plr2_ZOff_l,Plr_ZOff_l
				move.w	Plr2_AngPos_w,Vis_AngPos_w
				move.w	Plr2_CosVal_w,Vis_CosVal_w
				move.w	Plr2_SinVal_w,Vis_SinVal_w
				move.l	Plr2_PotVisibleZoneListPtr_l,Lvl_ListOfGraphRoomsPtr_l
				move.l	plr2_PointsToRotatePtr_l,PointsToRotatePtr_l
				move.b	Plr2_Echo_b,PLREcho
				move.l	Plr2_ZonePtr_l,ZonePtr_l
				move.l	#KeyMap_vb,a5
				moveq	#0,d5
				move.b	look_behind_key,d5
				tst.b	(a5,d5.w)
				beq.s	.nolookback

				move.l	Plr1_ObjectPtr_l,a0

				FREE_OBJ_2	a0,ENT_NEXT_2

				eor.w	#SINE_SIZE,Vis_AngPos_w
				neg.w	Vis_CosVal_w
				neg.w	Vis_SinVal_w

.nolookback:
*******************************************************************************
;	add a check here for rendering player weapon object
				tst.b	Prefs_ShowWeapon_b
				beq.s	.showWeapon
				move.l	Plr1_ObjectPtr_l,a0
				FREE_OBJ_2	a0,ENT_NEXT_2 ; weapon in hand
.showWeapon
*******************************************************************************
				jsr		Zone_OrderZones
				jsr		objmoveanim

				; ASM build only
				IFND BUILD_WITH_C
				jsr		Draw_BorderEnergyBar
				jsr		Draw_BorderAmmoBar
				ENDIF

				move.w	Vid_LetterBoxMarginHeight_w,d0
				move.w	#0,Draw_LeftClip_w
				move.w	Vid_RightX_w,Draw_RightClip_w
				;move.w	#0,Draw_DefTopClip_w
				;add.w	d0,Draw_DefTopClip_w
				;move.w	Vid_BottomY_w,Draw_DefBottomClip_w
				;sub.w	d0,Draw_DefBottomClip_w
				move.w	#0,draw_TopClip_w
				add.w	d0,draw_TopClip_w
				move.w	Vid_BottomY_w,draw_BottomClip_w
				sub.w	d0,draw_BottomClip_w
				st		DOANYWATER
				bsr		DrawDisplay

nodrawp2:
				tst.b	draw_RenderMap_b
				beq.s	.nomap
				bsr		DoTheMapWotNastyCharlesIsForcingMeToDo

.nomap:
				;move.b	plr1_Teleported_b,d5
				;clr.b	plr1_Teleported_b
				;cmp.b	#PLR_SLAVE,Plr_MultiplayerType_b
				;bne.s	.notplr2
				;move.b	plr2_Teleported_b,d5
				;clr.b	plr2_Teleported_b

				move.b	plr1_Teleported_b,d5
				or.b	plr2_Teleported_b,d5
				move.b	d5,C2P_Teleporting_b
				or.b	d5,C2P_NeedsInit_b ; trigger reinit
				clr.b	plr1_Teleported_b
				clr.b	plr1_Teleported_b

.notplr2:
				;tst.b Plr1_Mouse_b
				;beq.s	.no_croshair

				;tst.b Prefs_NoAutoAim_b
				;beq.s	.no_croshair

				jsr	Draw_Crosshair

;.no_croshair
				CALLC		Sys_EvalFPS

				DEV_SAVE	d0/d1/a0/a1
				CALLDEV		MarkDrawDone
				CALLDEV		DrawGraph
				DEV_RESTORE	d0/d1/a0/a1

				tst.b		Vid_UpdatePalette_b
				bne.s		.no_palette_update

				CALLC		Vid_LoadMainPalette

.no_palette_update:
				IFD BUILD_WITH_C
				tst.l		Game_ProgressSignal_l
				beq.s		.no_update_progress
				CALLC		Game_UpdatePlayerProgress

.no_update_progress:
				CALLC Vid_Present
				ELSE
				jsr C2P_Convert
				ENDIF

				;CALLDEV	MarkChunkyDone

				move.l	#KeyMap_vb,a5
				tst.b	RAWKEY_NUM_MINUS(a5)	; Decrease vertical view size
				beq		.nosmallscr

				; clamp wide screen
				move.w	#100,d0					; maximum in fullscreen mode
				tst.b	Vid_FullScreen_b
				bne.s	.isFullscreen

				move.w	#60,d0					; maximum in small screen mode

.isFullscreen:
				cmp.w	Vid_LetterBoxMarginHeight_w,d0
				blt.s	.clamped

				add.w	#2,Vid_LetterBoxMarginHeight_w
				st		C2P_NeedsSetParam_b

				CALLC	Draw_ResetGameDisplay
				CALLC	vid_SetupDoubleheightCopperlist
.clamped:
.nosmallscr:
				tst.b	RAWKEY_NUM_PLUS(a5)		; Increase vertical view size
				beq.s	.nobigscr

				tst.w	Vid_LetterBoxMarginHeight_w
				ble.s	.nobigscr

				sub.w	#2,Vid_LetterBoxMarginHeight_w
				st		C2P_NeedsSetParam_b
				CALLC	vid_SetupDoubleheightCopperlist
.nobigscr:
				; TODO - Come back to the resolution cycle once the double width issues are fixed

;				tst.b	RAWKEY_F9(a5)
;				beq.s	.skip_resolution_cycle
;				clr.b	RAWKEY_F9(a5)
;				addq.b	#1,Vid_ResolutionOption_b
;
;				btst.b	#0,Vid_ResolutionOption_b
;				sne.b	Vid_DoubleHeight_b
;
;				btst.b	#1,Vid_ResolutionOption_b
;				sne.b	Vid_DoubleWidth_b
;
;				tst.b	Vid_DoubleHeight_b
;				beq.s	.skip_copperlist
;
;				move.w	#0,d0
;				move.w	#0,d1
;
;				bsr		SetupRenderbufferSize
;				jsr		vid_SetupDoubleheightCopperlist
;
;.skip_copperlist:
;.skip_resolution_cycle:

				tst.b	RAWKEY_F9(a5)
				beq		.skip_double_height
				clr.b	RAWKEY_F9(a5)
				tst.b	LASTDH
				bne		.not_double_height
				st		LASTDH
				move.w	#0,d0
				move.w	#0,d1

				not.b	Vid_DoubleHeight_b
				st		C2P_NeedsInit_b

				; Check renderbuffer setup variables and clear screen
				bsr		SetupRenderbufferSize

				CALLC	vid_SetupDoubleheightCopperlist

				bra.s	.not_double_height

.skip_double_height:
				clr.b	LASTDH

.not_double_height:
				; Hijacking this for the simple wall test
				tst.b	RAWKEY_F8(a5)
				beq.s	.skip_double_width
				clr.b	RAWKEY_F8(a5)
				tst.b	LASTDW
				bne		.not_double_width

				not.b	Draw_ForceSimpleWalls_b

				;not.b	Vid_DoubleWidth_b
				;bsr		SetupRenderbufferSize

				bra.s	.not_double_width

.skip_double_width:
				clr.b	LASTDW

.not_double_width:

*****************************************
				move.l	Plr2_ZonePtr_l,a0
				move.l	#Sys_Workspace_vl,a1
				clr.l	(a1)
				clr.l	4(a1)
				clr.l	8(a1)
				clr.l	12(a1)
				clr.l	16(a1)
				clr.l	20(a1)
				clr.l	24(a1)
				clr.l	28(a1)

				cmp.b	#PLR_SINGLE,Plr_MultiplayerType_b
				beq.s	plr1only

				lea		ZoneT_PotVisibleZoneList_vw(a0),a0
.doallrooms:
				move.w	(a0),d0 ; PVST_Zone_w
				blt.s	.allroomsdone

				addq	#PVST_SizeOf_l,a0
				move.w	d0,d1
				asr.w	#3,d0
				bset	d1,(a1,d0.w)
				bra		.doallrooms

.allroomsdone:

plr1only:

				move.l	Plr1_ZonePtr_l,a0
				lea		ZoneT_PotVisibleZoneList_vw(a0),a0
.doallrooms2:
				move.w	(a0),d0
				blt.s	.allroomsdone2
				addq	#PVST_SizeOf_l,a0
				move.w	d0,d1
				asr.w	#3,d0
				bset	d1,(a1,d0.w)
				bra		.doallrooms2

.allroomsdone2:
				move.l	#%000001,d7
				lea		AI_AlienTeamWorkspace_vl,a2
				move.l	Lvl_ObjectDataPtr_l,a0
				sub.w	#ObjT_SizeOf_l,a0
.doallobs:
				NEXT_OBJ	a0

				move.w	(a0),d0
				blt.s	.allobsdone

				move.w	ObjT_ZoneID_w(a0),d0
				blt.s	.doallobs

				move.w	d0,d1
				asr.w	#3,d0
				btst	d1,(a1,d0.w)
				bne.s	.worryobj
				move.b	ObjT_TypeID_b(a0),d0
				btst	d0,d7
				beq.s	.doallobs

				moveq	#0,d0
				move.b	EntT_TeamNumber_b(a0),d0
				blt.s	.doallobs
				asl.w	#4,d0
				tst.w	AI_WorkT_SeenBy_w(a2,d0.w)
				blt.s	.doallobs
.worryobj:
				or.b	#127,ShotT_Worry_b(a0)
				bra.s	.doallobs

.allobsdone:

				move.l	#KeyMap_vb,a5
				tst.b	RAWKEY_ESC(a5)
				beq.s	noend

				cmp.b	#PLR_SLAVE,Plr_MultiplayerType_b
				beq		plr2quit

				st		Game_MasterQuit_b
				bra		noend

plr2quit:
				st		Game_SlaveQuit_b
noend:

				tst.b	Game_MasterQuit_b
				beq.s	.noquit
				tst.b	Game_SlaveQuit_b
				beq.s	.noquit
				jmp		endnomusic
.noquit:

				cmp.b	#PLR_SINGLE,Plr_MultiplayerType_b
				bne.s	noexit
				move.l	Plr1_ZonePtr_l,a0
				move.w	(a0),d0

				cmp.w	Lvl_ExitZoneID_w,d0

; change this for quick exit, charlie
zzzz:
;				 bra end	; immediately return to main menu for testing

				bne.s	noexit

				; Now we are in the exit zone

				; This is a hacky way to do the teleport fx, but it doesn't work
				; now that it's handled by a trigger event. We'll come back to this
				; and find a better way to do it.

				;add.w	#2,Game_TeleportFrame_w
				;cmp.w	#9,Game_TeleportFrame_w
				;blt		noexit

				jmp		endlevel
noexit:

				tst.w Plr1_Health_w
				bgt nnoend1
				jmp endlevel
nnoend1:
				tst.w Plr2_Health_w
				bgt nnoend2
				jmp endlevel
nnoend2:

; move.l Lvl_SwitchDataPtr_l,a0
; tst.b 24+8(a0)
; bne end

; JSR STOPTIMER

; Run the actual game update. FIXME: moving it to here from the VBL makes everything run
; like in slow motion
;				tst.b Game_Running_b
;				beq	.donothing
;				jsr dosomething
;.donothing:
				bra		game_main_loop

; Check renderbuffer setup variables and wipe screen
SetupRenderbufferSize:
***************************************************************
				;is this a better way to shoehorn this in only when screen mode changes? AL
***************************************************************
				tst.b	LASTDH
				bne.s	.big
				tst.b	Vid_FullScreen_b
				beq.s	.small

				move.w	#6,View_KeyLook_w
				move.w	#FS_HEIGHT/2,d0
				move.w	d0,View_LookMin_w
				neg.w	d0
				move.w	d0,View_LookMax_w
				move.w	STOPOFFSET,d0
				move.w	d0,d1
				asr.w	#1,d1			;STOPOFFSET * 0.5
				add.w	d1,d0			;STOPOFFSET * 1.5
				move.w	d0,STOPOFFSET

				bra	.big

.small
				move.w	#4,View_KeyLook_w
				move.w	#SMALL_HEIGHT/2,d0
				move.w	d0,View_LookMin_w
				neg.w	d0
				move.w	d0,View_LookMax_w
				move.w	STOPOFFSET,d0
				muls.w	#2,d0
				divs.w	#3,d0
				move.w	d0,STOPOFFSET

.big
***************************************************************
startCopper:
				; FIXME dowe need to clamp here again?
				cmp.w	#100,Vid_LetterBoxMarginHeight_w
				blt.s	.wideScreenOk
				move.w	#100,Vid_LetterBoxMarginHeight_w

.wideScreenOk:
				tst.b	Vid_FullScreen_b
				beq.s	.setupSmallScreen

				move.w	#FS_WIDTH,d0
				tst.b	Vid_DoubleWidth_b
				beq.s	.noDoubleWidth
				lsr.w	#1,d0
.noDoubleWidth:
				move.w	d0,Vid_RightX_w
				lsr.w	#1,d0
				move.w	d0,Vid_CentreX_w
				move.w	#FS_HEIGHT,Vid_BottomY_w
				move.w	#FS_HEIGHT/2,TOTHEMIDDLE
				bra.s	.wipeScreen

.setupSmallScreen:
				move.w	#SMALL_WIDTH,d0
				tst.b	Vid_DoubleWidth_b
				beq.s	.noDoubleWidth2
				lsr.w	#1,d0
.noDoubleWidth2:
				move.w	d0,Vid_RightX_w
				lsr.w	#1,d0
				move.w	d0,Vid_CentreX_w
				move.w	#SMALL_HEIGHT,Vid_BottomY_w
				move.w	#SMALL_HEIGHT/2,TOTHEMIDDLE

.wipeScreen:
				CALLC	Draw_ResetGameDisplay
				rts

LASTDH:			dc.b	0
LASTDW:			dc.b	0
DOANYWATER:		dc.w	0

; Screenshot?
SAVETHESCREEN:
				move.l	#SAVENAME,d1
				move.l	#MODE_NEWFILE,d2
				CALLDOS	Open
				move.l	d0,IO_DOSFileHandle_l

				move.l	Vid_DrawScreenPtr_l,d2
				move.l	IO_DOSFileHandle_l,d1
				move.l	#10240*8,d3
				CALLDOS	Write

				move.l	IO_DOSFileHandle_l,d1
				CALLDOS	Close

				move.l	#200,d1
				CALLDOS	Delay

				add.b	#1,SAVELETTER

				rts

SAVENAME:		dc.b	'rawscrn'
SAVELETTER:		dc.b	'd',0

				even

				include "modules/draw/draw_map.s"

				include "screensetup.s"
;				include	"chunky.s"

				include "modules/c2p/c2p.s"

				include	"pauseopts.s"

				include "modules/dev_inst.s"


Lvl_ExitZoneID_w:		dc.w	0

***************************************************************************
***************************************************************************
****************** End of Main Loop here **********************************
***************************************************************************
***************************************************************************


READCONTROLS:	dc.w	0

tstststst:		dc.w	0

BollocksRoom:
				dc.w	-1
				ds.l	50

				ds.l	4 ; pad - overrun?

Plr1_Use:
				move.l	Plr1_ObjectPtr_l,a0
				move.b	#OBJ_TYPE_PLAYER1,ObjT_TypeID_b(a0)
				move.l	Lvl_ObjectPointsPtr_l,a1
				move.l	#ObjRotated_vl,a2
				move.w	(a0),d0
				move.l	Plr1_XOff_l,(a1,d0.w*8)
				move.l	Plr1_ZOff_l,4(a1,d0.w*8)
				move.l	Plr1_ZonePtr_l,a1
				moveq	#0,d2
				move.b	EntT_DamageTaken_b(a0),d2
				beq		.notbeenshot

				moveq	#0,d4
				move.w	EntT_ImpactX_w(a0),d3
				beq.s	.notwist
				move.w	d2,d4

.notwist:
				add.w	d3,Plr1_SnapXSpdVal_l
				move.w	EntT_ImpactZ_w(a0),d3
				beq.s	.notwist2
				move.w	d2,d4

.notwist2:
				add.w	d3,Plr1_SnapZSpdVal_l
				move.w	EntT_ImpactY_w(a0),d3
				ext.l	d3
				asl.l	#8,d3
				add.l	d3,Plr1_SnapYVel_l
				move.w	#0,EntT_ImpactX_w(a0)
				move.w	#0,EntT_ImpactY_w(a0)
				move.w	#0,EntT_ImpactZ_w(a0)
				jsr		GetRand

				muls	d4,d0
				asr.l	#8,d0
				asr.l	#4,d0
				add.w	d0,Plr1_SnapAngSpd_w
				move.l	#7*2116,hitcol
				sub.w	d2,Plr1_Health_w

				SAVEREGS

				move.w	#$fffa,IDNUM
				move.w	#19,Aud_SampleNum_w
				clr.b	notifplaying
				move.w	#0,Aud_NoiseX_w
				move.w	#0,Aud_NoiseZ_w
				move.w	#60,Aud_NoiseVol_w
				jsr		MakeSomeNoise

				GETREGS

.notbeenshot:
				move.b	#0,EntT_DamageTaken_b(a0)
				move.b	#10,EntT_HitPoints_b(a0)
				move.w	Plr1_TmpAngPos_w,EntT_CurrentAngle_w(a0)
				move.b	Plr1_StoodInTop_b,ShotT_InUpperZone_b(a0)
				move.w	(a1),ObjT_ZoneID_w(a0)
				move.w	(a1),d2
				move.l	#Zone_BrightTable_vl,a1
				move.l	(a1,d2.w*4),d2
				tst.b	Plr1_StoodInTop_b
				bne.s	.okinbott

				swap	d2
.okinbott:
				move.w	d2,2(a0)
				move.l	Plr1_TmpYOff_l,d0
				move.l	plr1_TmpHeight_l,d1
				asr.l	#1,d1
				add.l	d1,d0
				asr.l	#7,d0
				move.w	d0,4(a0)
				tst.w	Plr1_Health_w
				bgt.s	.okh1

				FREE_OBJ	a0
.okh1:
				move.l	Plr2_ObjectPtr_l,a0
				move.b	#OBJ_TYPE_PLAYER2,ObjT_TypeID_b(a0)

				move.w	Plr2_TmpAngPos_w,d0
				AMOD_A	d0
				move.w	d0,EntT_CurrentAngle_w(a0)
;
; jsr ViewpointToDraw
; asl.w #2,d0
; moveq #0,d1
; move.b plr2_TmpBobble_w,d1
; not.b d1
; lsr.b #3,d1
; and.b #$3,d1
; add.w d1,d0
; move.w d0,10(a0)
; move.w #10,8(a0)
;

				move.l	Lvl_ObjectPointsPtr_l,a1
				move.l	#ObjRotated_vl,a2
				move.w	(a0),d0
				move.l	Plr2_XOff_l,(a1,d0.w*8)
				move.l	Plr2_ZOff_l,4(a1,d0.w*8)
				move.l	Plr2_ZonePtr_l,a1
				moveq	#0,d2
				move.b	EntT_DamageTaken_b(a0),d2
				beq		.notbeenshot2

				move.w	EntT_ImpactX_w(a0),d3
				add.w	d3,Plr2_SnapXSpdVal_l
				move.w	EntT_ImpactZ_w(a0),d3
				add.w	d3,Plr2_SnapZSpdVal_l
				move.w	EntT_ImpactY_w(a0),d3
				ext.l	d3
				asl.l	#8,d3
				add.l	d3,Plr2_SnapYVel_l
				move.w	#0,EntT_ImpactX_w(a0)
				move.w	#0,EntT_ImpactY_w(a0)
				move.w	#0,EntT_ImpactZ_w(a0)
				sub.w	d2,Plr2_Health_w

.notbeenshot2:
				move.b	#0,EntT_DamageTaken_b(a0)
				move.b	#10,EntT_HitPoints_b(a0)
				move.b	Plr2_StoodInTop_b,ShotT_InUpperZone_b(a0)
				move.w	(a1),ObjT_ZoneID_w(a0)
				move.w	(a1),d2
				move.l	#Zone_BrightTable_vl,a1
				move.l	(a1,d2.w*4),d2
				tst.b	Plr2_StoodInTop_b
				bne.s	.okinbott2

				swap	d2

.okinbott2:
				move.w	d2,2(a0)
				move.l	Plr2_TmpYOff_l,d0
				move.l	plr2_TmpHeight_l,d1
				asr.l	#1,d1
				add.l	d1,d0
				asr.l	#7,d0
				move.w	d0,4(a0)
				jsr		ViewpointToDraw

				add.l	d0,d0
				move.l	GLF_DatabasePtr_l,a6
				add.l	#GLFT_Player2Graphic_w,a6
				move.w	(a6),d7
				move.w	d7,d1
				move.l	GLF_DatabasePtr_l,a6
				add.l	#GLFT_AlienDefs_l,a6
				muls	#AlienT_SizeOf_l,d1
				add.l	d1,a6
				move.b	AlienT_GFXType_w+1(a6),AI_VecObj_w
				cmp.w	#1,AlienT_GFXType_w(a6)
				bne.s	.NOSIDES2

				moveq	#0,d0

.NOSIDES2:
				move.l	GLF_DatabasePtr_l,a6
				add.l	#GLFT_AlienAnims_l,a6
				move.w	d7,d1
				muls	#A_AnimLen,d1
				add.l	d1,a6

; move.l AlienAnimPtr_l,a6

				muls	#A_OptLen,d0
				add.w	d0,a6
				move.w	EntT_Timer2_w(a0),d1
				move.w	d1,d2
				muls	#A_FrameLen,d1
				addq	#1,d2
				move.w	d2,d3
				muls	#A_FrameLen,d3
				tst.b	(a6,d3.w)
				bge.s	.noendanim

				move.w	#0,d2

.noendanim:
				move.w	d2,EntT_Timer2_w(a0)
				move.w	d2,d1

				muls	#A_FrameLen,d1
				move.l	#0,8(a0)
				move.b	(a6,d1.w),9(a0)
				move.b	1(a6,d1.w),d0
				ext.w	d0
				bgt.s	.noflip
				move.b	#128,10(a0)
				neg.w	d0

.noflip:
				sub.w	#1,d0
				move.b	d0,11(a0)
				move.w	#-1,6(a0)
				cmp.b	#1,AI_VecObj_w
				beq.s	.nosize

				bgt.s	.setlight

				move.w	2(a6,d1.w),6(a0)
				bra.s	.ddone

.nosize:
; move.l #$00090001,8(a0)
				bra.s	.ddone

.setlight:
				move.w	2(a6,d1.w),6(a0)
				move.b	AI_VecObj_w,d1
				or.b	d1,10(a0)

.ddone:
				tst.w	Plr2_Health_w
				bgt.s	.okh

				FREE_OBJ	a0
.okh:
				move.l	Plr1_ObjectPtr_l,a0
				tst.w	Plr1_Health_w

				bgt.s	.notdead

				FREE_OBJ_2	a0,ENT_NEXT_2
				rts

.notdead:
				move.l	Plr1_ZonePtr_l,a1

				move.w	EntT_CurrentAngle_w(a0),d0
				add.w	#SINE_SIZE,d0
				AMOD_A	d0
				move.w	d0,EntT_CurrentAngle_w+ENT_NEXT_2(a0)

				move.w	(a1),ObjT_ZoneID_w+ENT_NEXT_2(a0)
				move.w	(a1),EntT_ZoneID_w+ENT_NEXT_2(a0)

				moveq	#0,d0
				move.b	Plr1_TmpGunSelected_b,d0

				move.l	GLF_DatabasePtr_l,a1
				add.l	#GLFT_GunObjects_l,a1
				move.w	(a1,d0.w*2),d0

				move.b	d0,EntT_Type_b+ENT_NEXT_2(a0)
				move.b	#OBJ_TYPE_OBJECT,ObjT_TypeID_b+ENT_NEXT_2(a0)

				move.w	(a0),d0
				move.w	ENT_NEXT_2(a0),d1
				move.l	Lvl_ObjectPointsPtr_l,a1
				move.l	(a1,d0.w*8),(a1,d1.w*8)
				move.l	4(a1,d0.w*8),4(a1,d1.w*8)

				st		EntT_WhichAnim_b+ENT_NEXT_2(a0)

				move.l	Plr1_TmpYOff_l,d0
				move.l	plr1_TmpHeight_l,d1
				asr.l	#2,d1
				add.l	#10*128,d1
				add.l	d1,d0
				asr.l	#7,d0
				move.w	d0,4+ENT_NEXT_2(a0)
				move.l	plr1_BobbleY_l,d1
				asr.l	#8,d1
				move.l	d1,d0
				asr.l	#1,d0
				add.l	d0,d1
				add.w	d1,4+ENT_NEXT_2(a0)
				move.b	ShotT_InUpperZone_b(a0),ShotT_InUpperZone_b+ENT_NEXT_2(a0)
				rts


Plr2_Use:
				move.l	Plr2_ObjectPtr_l,a0
				move.b	#OBJ_TYPE_PLAYER2,ObjT_TypeID_b(a0)
				move.l	Lvl_ObjectPointsPtr_l,a1
				move.l	#ObjRotated_vl,a2
				move.w	(a0),d0
				move.l	Plr2_XOff_l,(a1,d0.w*8)
				move.l	Plr2_ZOff_l,4(a1,d0.w*8)
				move.l	Plr2_ZonePtr_l,a1

				moveq	#0,d2
				move.b	EntT_DamageTaken_b(a0),d2
				beq		.notbeenshot

				moveq	#0,d4
				move.w	EntT_ImpactX_w(a0),d3
				beq.s	.notwist
				move.w	d2,d4
.notwist:
				add.w	d3,Plr2_SnapXSpdVal_l
				move.w	EntT_ImpactZ_w(a0),d3
				beq.s	.notwist2
				move.w	d2,d4
.notwist2:
				add.w	d3,Plr2_SnapZSpdVal_l

				jsr		GetRand

				muls	d4,d0
				asr.l	#8,d0
				asr.l	#4,d0
				add.w	d0,Plr2_SnapAngSpd_w
				move.l	#7*2116,hitcol
				sub.w	d2,Plr2_Health_w

				SAVEREGS

				move.w	#19,Aud_SampleNum_w
				clr.b	notifplaying
				move.w	#$fffa,IDNUM
				move.w	#0,Aud_NoiseX_w
				move.w	#0,Aud_NoiseZ_w
				move.w	#60,Aud_NoiseVol_w
				jsr		MakeSomeNoise

				GETREGS

.notbeenshot:
				move.b	#0,EntT_DamageTaken_b(a0)
				move.b	#10,EntT_HitPoints_b(a0)
				move.w	Plr2_TmpAngPos_w,EntT_CurrentAngle_w(a0)
				move.b	Plr2_StoodInTop_b,ShotT_InUpperZone_b(a0)
				move.w	(a1),ObjT_ZoneID_w(a0)
				move.w	(a1),d2
				move.l	#Zone_BrightTable_vl,a1
				move.l	(a1,d2.w*4),d2
				tst.b	Plr2_StoodInTop_b
				bne.s	.okinbott

				swap	d2
.okinbott:
				move.w	d2,2(a0)

				move.l	Plr2_YOff_l,d0
				move.l	plr2_TmpHeight_l,d1
				asr.l	#1,d1
				add.l	d1,d0
				asr.l	#7,d0
				move.w	d0,4(a0)

				tst.w	Plr2_Health_w
				bgt.s	.okh55

				FREE_OBJ	a0
.okh55:

***********************************

				move.l	Plr1_ObjectPtr_l,a0
				move.b	#OBJ_TYPE_PLAYER1,ObjT_TypeID_b(a0)

				move.w	Plr1_AngPos_w,d0
				AMOD_A	d0
				move.w	d0,EntT_CurrentAngle_w(a0)

				move.l	Lvl_ObjectPointsPtr_l,a1
				move.l	#ObjRotated_vl,a2
				move.w	(a0),d0
				move.l	Plr1_XOff_l,(a1,d0.w*8)
				move.l	Plr1_ZOff_l,4(a1,d0.w*8)
				move.l	Plr1_ZonePtr_l,a1

				moveq	#0,d2
				move.b	EntT_DamageTaken_b(a0),d2
				beq		.notbeenshot2

				move.w	EntT_ImpactX_w(a0),d3
				add.w	d3,Plr1_SnapXSpdVal_l
				move.w	EntT_ImpactZ_w(a0),d3
				add.w	d3,Plr1_SnapZSpdVal_l

				sub.w	d2,Plr1_Health_w


.notbeenshot2:
				move.b	#0,EntT_DamageTaken_b(a0)
				move.b	#10,EntT_HitPoints_b(a0)

				move.b	Plr1_StoodInTop_b,ShotT_InUpperZone_b(a0)

				move.w	(a1),ObjT_ZoneID_w(a0)
				move.w	(a1),d2
				move.l	#Zone_BrightTable_vl,a1
				move.l	(a1,d2.w*4),d2
				tst.b	Plr1_StoodInTop_b
				bne.s	.okinbott2
				swap	d2

.okinbott2:
				move.w	d2,2(a0)

				move.l	Plr1_TmpYOff_l,d0
				move.l	plr1_TmpHeight_l,d1
				asr.l	#1,d1
				add.l	d1,d0
				asr.l	#7,d0
				move.w	d0,4(a0)

				jsr		ViewpointToDraw
				add.l	d0,d0

				move.l	GLF_DatabasePtr_l,a6
				add.l	#GLFT_Player1Graphic_w,a6
				move.w	(a6),d7
				move.w	d7,d1

				move.l	GLF_DatabasePtr_l,a6
				add.l	#GLFT_AlienDefs_l,a6
				muls	#AlienT_SizeOf_l,d1
				add.l	d1,a6
				move.b	AlienT_GFXType_w+1(a6),AI_VecObj_w
				cmp.w	#1,AlienT_GFXType_w(a6)
				bne.s	.NOSIDES2

				moveq	#0,d0

.NOSIDES2:
				move.l	GLF_DatabasePtr_l,a6

				add.l	#GLFT_AlienAnims_l,a6

				move.w	d7,d1
				muls	#A_AnimLen,d1
				add.l	d1,a6

; move.l AlienAnimPtr_l,a6

				muls	#A_OptLen,d0
				add.w	d0,a6

				move.w	EntT_Timer2_w(a0),d1
				move.w	d1,d2
				muls	#A_FrameLen,d1

				addq	#1,d2

				move.w	d2,d3
				muls	#A_FrameLen,d3
				tst.b	(a6,d3.w)
				bge.s	.noendanim
				move.w	#0,d2

.noendanim:
				move.w	d2,EntT_Timer2_w(a0)

				move.w	d2,d1

				muls	#A_FrameLen,d1

				move.l	#0,8(a0)
				move.b	(a6,d1.w),9(a0)
				move.b	1(a6,d1.w),d0
				ext.w	d0
				bgt.s	.noflip
				move.b	#128,10(a0)
				neg.w	d0
.noflip:
				sub.w	#1,d0
				move.b	d0,11(a0)

				move.w	#-1,6(a0)
				cmp.b	#1,AI_VecObj_w
				beq.s	.nosize
				bgt.s	.setlight
				move.w	2(a6,d1.w),6(a0)
				bra.s	.ddone

.nosize:

; move.l #$00090001,8(a0)

				bra.s	.ddone

.setlight:
				move.w	2(a6,d1.w),6(a0)
				move.b	AI_VecObj_w,d1
				or.b	d1,10(a0)

.ddone:
				tst.w	Plr1_Health_w
				bgt.s	.okh

				FREE_OBJ	a0
.okh:

**********************************

				move.l	Plr2_ObjectPtr_l,a0
				tst.w	Plr2_Health_w
				bgt.s	.notdead
				FREE_OBJ_2	a0,ENT_NEXT
				rts

.notdead:
				move.l	Plr2_ZonePtr_l,a1
				move.w	EntT_CurrentAngle_w(a0),d0
				add.w	#SINE_SIZE,d0
				AMOD_A	d0
				move.w	d0,EntT_CurrentAngle_w+ENT_NEXT(a0)

				move.w	(a1),ObjT_ZoneID_w+ENT_NEXT(a0)
				move.w	(a1),EntT_ZoneID_w+ENT_NEXT(a0)

				moveq	#0,d0
				move.b	Plr2_TmpGunSelected_b,d0

				move.l	GLF_DatabasePtr_l,a1
				add.l	#GLFT_GunObjects_l,a1
				move.w	(a1,d0.w*2),d0

				move.b	d0,EntT_Type_b+ENT_NEXT(a0)
				move.b	#OBJ_TYPE_OBJECT,ObjT_TypeID_b+ENT_NEXT(a0)

				move.w	(a0),d0
				move.w	ENT_NEXT(a0),d1
				move.l	Lvl_ObjectPointsPtr_l,a1
				move.l	(a1,d0.w*8),(a1,d1.w*8)
				move.l	4(a1,d0.w*8),4(a1,d1.w*8)

				st		EntT_WhichAnim_b+ENT_NEXT(a0)

				move.l	Plr2_TmpYOff_l,d0
				move.l	plr2_TmpHeight_l,d1
				asr.l	#2,d1
				add.l	#10*128,d1
				add.l	d1,d0
				asr.l	#7,d0
				move.w	d0,4+ENT_NEXT(a0)
				move.l	plr2_BobbleY_l,d1
				asr.l	#8,d1
				move.l	d1,d0
				asr.l	#1,d0
				add.l	d0,d1
				add.w	d1,4+ENT_NEXT(a0)

				move.b	ShotT_InUpperZone_b(a0),ShotT_InUpperZone_b+ENT_NEXT(a0)

				rts

				align 4

Path:
; incbin "testpath"
endpath:
pathpt:			dc.l	Path

; TODO - Consolidate with Plr2_Control and move into a single function that takes a pointer
;        to the player state
Plr1_Control:
; Take a snapshot of everything.
				move.l	Plr1_XOff_l,d2
				move.l	d2,oldx
				move.l	Plr1_ZOff_l,d3
				move.l	d3,oldz
				move.l	Plr1_TmpXOff_l,d0
				move.l	d0,Plr1_XOff_l
				move.l	d0,newx
				move.l	Plr1_TmpZOff_l,d1
				move.l	d1,newz
				move.l	d1,Plr1_ZOff_l
				move.l	plr1_TmpHeight_l,Plr1_Height_l
				sub.l	d2,d0
				sub.l	d3,d1
				move.l	d0,xdiff
				move.l	d1,zdiff
				move.w	Plr1_TmpAngPos_w,d0
				move.w	d0,Plr1_AngPos_w
				move.l	#SinCosTable_vw,a1
				move.w	(a1,d0.w),Plr1_SinVal_w
				add.w	#COSINE_OFS,d0
				AMOD_A	d0
				move.w	(a1,d0.w),Plr1_CosVal_w
				move.l	Plr1_TmpYOff_l,d0
				move.w	plr1_TmpBobble_w,d1
				move.w	(a1,d1.w),d1
				move.w	d1,d3
				ble.s	.notnegative

				neg.w	d1

.notnegative:
				add.w	#16384,d1
				asr.w	#4,d1
				tst.b	Plr1_Ducked_b
				bne.s	.notdouble

				tst.b	Plr1_Squished_b
				bne.s	.notdouble

				add.w	d1,d1
.notdouble:
				ext.l	d1
				move.l	d1,plr1_BobbleY_l
				move.l	Plr1_Height_l,d4
				sub.l	d1,d4
				add.l	d1,d0
				cmp.b	#PLR_SLAVE,Plr_MultiplayerType_b
				beq.s	.otherwob

				asr.w	#6,d3
				ext.l	d3
				move.l	d3,xwobble
				move.w	Plr1_SinVal_w,d1
				muls	d3,d1
				move.w	Plr1_CosVal_w,d2
				muls	d3,d2
				swap	d1
				swap	d2
				asr.w	#6,d1					; 6 was 7 AL
				move.w	d1,xwobxoff				; xwobble
				asr.w	#6,d2					; 6 was 7 AL
				neg.w	d2
				move.w	d2,xwobzoff

.otherwob:
				move.l	d0,Plr1_YOff_l
				move.l	d0,newy
				move.l	d0,oldy
				move.l	d4,thingheight
				move.l	#40*256,StepUpVal
				tst.b	Plr1_Squished_b
				bne.s	.smallstep

				tst.b	Plr1_Ducked_b
				beq.s	.okbigstep

.smallstep:
				move.l	#10*256,StepUpVal

.okbigstep:
				move.l	#$1000000,StepDownVal
				move.l	Plr1_ZonePtr_l,a0
				move.w	ZoneT_TelZone_w(a0),d0
				blt		.noteleport

				move.w	ZoneT_TelX_w(a0),newx
				move.w	ZoneT_TelZ_w(a0),newz
				move.l	Plr1_ObjectPtr_l,a0
				move.w	(a0),CollId
				move.l	#%111111111111111111,Obj_CollideFlags_l
				jsr		Obj_DoCollision

				tst.b	hitwall
				beq.s	.teleport

				move.w	Plr1_XOff_l,newx
				move.w	Plr1_ZOff_l,newz
				bra		.noteleport

.teleport:
				st		plr1_Teleported_b
				move.l	Plr1_ZonePtr_l,a0
				move.w	ZoneT_TelZone_w(a0),d0
				move.w	ZoneT_TelX_w(a0),Plr1_XOff_l
				move.w	ZoneT_TelZ_w(a0),Plr1_ZOff_l
				move.l	Plr1_YOff_l,d1
				sub.l	ZoneT_Floor_l(a0),d1
				move.l	Lvl_ZonePtrsPtr_l,a0
				move.l	(a0,d0.w*4),a0
				move.l	a0,Plr1_ZonePtr_l
				add.l	ZoneT_Floor_l(a0),d1
				move.l	d1,Plr1_SnapYOff_l
				move.l	d1,Plr1_YOff_l
				move.l	d1,Plr1_SnapTYOff_l
				move.l	Plr1_XOff_l,Plr1_SnapXOff_l
				move.l	Plr1_ZOff_l,Plr1_SnapZOff_l

				SAVEREGS
				move.w	#0,Aud_NoiseX_w
				move.w	#0,Aud_NoiseZ_w
				move.w	#26,Aud_SampleNum_w
				move.w	#100,Aud_NoiseVol_w
				move.w	#$fff9,IDNUM
				jsr		MakeSomeNoise
				GETREGS

				bra		.cantmove

.noteleport:
				move.l	Plr1_ZonePtr_l,Obj_ZonePtr_l
				move.w	#%100000000,wallflags
				move.b	Plr1_StoodInTop_b,StoodInTop
				move.l	#%1011111110111000011,Obj_CollideFlags_l
				move.l	Plr1_ObjectPtr_l,a0
				move.w	(a0),CollId
				jsr		Obj_DoCollision

				tst.b	hitwall
				beq.s	.nothitanything

				move.w	oldx,Plr1_XOff_l
				move.w	oldz,Plr1_ZOff_l
				move.l	Plr1_XOff_l,Plr1_SnapXOff_l
				move.l	Plr1_ZOff_l,Plr1_SnapZOff_l
				bra		.cantmove

.nothitanything:
				move.w	#40,Obj_ExtLen_w
				move.b	#0,Obj_AwayFromWall_b

				clr.b	exitfirst
				clr.b	Obj_WallBounce_b
				bsr		MoveObject

				move.b	StoodInTop,Plr1_StoodInTop_b
				move.l	Obj_ZonePtr_l,Plr1_ZonePtr_l
				move.w	newx,Plr1_XOff_l
				move.w	newz,Plr1_ZOff_l
				move.l	Plr1_XOff_l,Plr1_SnapXOff_l
				move.l	Plr1_ZOff_l,Plr1_SnapZOff_l

.cantmove:
				move.l	Plr1_ZonePtr_l,a0
				move.l	ZoneT_Floor_l(a0),d0
				tst.b	Plr1_StoodInTop_b
				beq.s	notintop

				move.l	ZoneT_UpperFloor_l(a0),d0

notintop:
				adda.w	#ZoneT_Points_w,a0 ; a0 = &ZoneT.ZoneT_Points_w
				sub.l	Plr1_Height_l,d0
				move.l	d0,Plr1_SnapTYOff_l
				move.w	Plr1_TmpAngPos_w,tmpangpos
				move.w	(a0)+,d1 ; after move, a0 = &ZoneT.ZoneT_DrawBackdrop_b
				ext.l	d1
				add.l	Plr1_ZonePtr_l,d1
				move.l	d1,plr1_PointsToRotatePtr_l
				tst.b	(a0)+ ; after move, a0 = &ZoneT.ZoneT_Echo_b
				beq.s	nobackgraphics

				cmp.b	#PLR_SLAVE,Plr_MultiplayerType_b
				beq.s	nobackgraphics

				jsr		Draw_SkyBackdrop

nobackgraphics:
				move.b	(a0)+,Plr1_Echo_b ; after move, a0 = &ZoneT.ZoneT_TelZone_w
				adda.w	#10,a0 ; a0 = &ZoneT_PotVisibleZoneList_vw
				move.l	a0,Plr1_PotVisibleZoneListPtr_l
				rts

;DRAWNGRAPHTOP:	dc.w	0
;tstzone:		dc.l	0

Plr2_Control:
; Take a snapshot of everything.
				move.l	Plr2_XOff_l,d2
				move.l	d2,oldx
				move.l	Plr2_ZOff_l,d3
				move.l	d3,oldz
				move.l	Plr2_TmpXOff_l,d0
				move.l	d0,Plr2_XOff_l
				move.l	d0,newx
				move.l	Plr2_TmpZOff_l,d1
				move.l	d1,newz
				move.l	d1,Plr2_ZOff_l
				move.l	plr2_TmpHeight_l,Plr2_Height_l
				sub.l	d2,d0
				sub.l	d3,d1
				move.l	d0,xdiff
				move.l	d1,zdiff
				move.w	Plr2_TmpAngPos_w,d0
				move.w	d0,Plr2_AngPos_w
				move.l	#SinCosTable_vw,a1
				move.w	(a1,d0.w),Plr2_SinVal_w
				add.w	#COSINE_OFS,d0
				AMOD_A	d0
				move.w	(a1,d0.w),Plr2_CosVal_w
				move.l	Plr2_TmpYOff_l,d0
				move.w	plr2_TmpBobble_w,d1
				move.w	(a1,d1.w),d1
				move.w	d1,d3
				ble.s	.notnegative

				neg.w	d1

.notnegative:
				add.w	#16384,d1
				asr.w	#4,d1
				tst.b	Plr2_Ducked_b
				bne.s	.notdouble
				tst.b	Plr2_Squished_b
				bne.s	.notdouble
				add.w	d1,d1

.notdouble:
				ext.l	d1
				move.l	d1,plr2_BobbleY_l
				move.l	Plr2_Height_l,d4
				sub.l	d1,d4
				add.l	d1,d0
				cmp.b	#PLR_SLAVE,Plr_MultiplayerType_b
				bne.s	.otherwob
				asr.w	#6,d3
				ext.l	d3
				move.l	d3,xwobble
				move.w	Plr2_SinVal_w,d1
				muls	d3,d1
				move.w	Plr2_CosVal_w,d2
				muls	d3,d2
				swap	d1
				swap	d2
				asr.w	#6,d1					; 6 was 7 AL
				move.w	d1,xwobxoff
				asr.w	#6,d2					; 6 was 7 AL
				neg.w	d2
				move.w	d2,xwobzoff

.otherwob:
				move.l	d0,Plr2_YOff_l
				move.l	d0,newy
				move.l	d0,oldy
				move.l	d4,thingheight
				move.l	#40*256,StepUpVal
				tst.b	Plr2_Squished_b
				bne.s	.smallstep

				tst.b	Plr2_Ducked_b
				beq.s	.okbigstep

.smallstep:
				move.l	#10*256,StepUpVal

.okbigstep:
				move.l	#$1000000,StepDownVal
				move.l	Plr2_ZonePtr_l,a0
				move.w	ZoneT_TelZone_w(a0),d0
				blt		.noteleport

				move.w	ZoneT_TelX_w(a0),newx
				move.w	ZoneT_TelZ_w(a0),newz
				move.l	Plr2_ObjectPtr_l,a0
				move.w	(a0),CollId
				move.l	#%111111111111111111,Obj_CollideFlags_l
				jsr		Obj_DoCollision

				tst.b	hitwall
				beq.s	.teleport

				move.w	Plr2_XOff_l,newx
				move.w	Plr2_ZOff_l,newz
				bra		.noteleport

.teleport:
				st		plr2_Teleported_b
				move.l	Plr2_ZonePtr_l,a0
				move.w	ZoneT_TelZone_w(a0),d0
				move.w	ZoneT_TelX_w(a0),Plr2_XOff_l
				move.w	ZoneT_TelZ_w(a0),Plr2_ZOff_l
				move.l	Plr2_YOff_l,d1
				sub.l	ZoneT_Floor_l(a0),d1
				move.l	Lvl_ZonePtrsPtr_l,a0
				move.l	(a0,d0.w*4),a0
				move.l	a0,Plr2_ZonePtr_l
				add.l	ZoneT_Floor_l(a0),d1
				move.l	d1,Plr2_SnapYOff_l
				move.l	d1,Plr2_YOff_l
				move.l	d1,Plr2_SnapTYOff_l
				move.l	Plr2_XOff_l,Plr2_SnapXOff_l
				move.l	Plr2_ZOff_l,Plr2_SnapZOff_l

				SAVEREGS
				move.w	#0,Aud_NoiseX_w
				move.w	#0,Aud_NoiseZ_w
				move.w	#26,Aud_SampleNum_w
				move.w	#100,Aud_NoiseVol_w
				move.w	#$fff9,IDNUM
				jsr		MakeSomeNoise
				GETREGS

				bra		.cantmove

.noteleport:
				move.l	Plr2_ZonePtr_l,Obj_ZonePtr_l
				move.w	#%100000000000,wallflags
				move.b	Plr2_StoodInTop_b,StoodInTop
				move.l	#%1011111010111100011,Obj_CollideFlags_l
				move.l	Plr2_ObjectPtr_l,a0
				move.w	(a0),CollId
				jsr		Obj_DoCollision

				tst.b	hitwall
				beq.s	.nothitanything

				move.w	oldx,Plr2_XOff_l
				move.w	oldz,Plr2_ZOff_l
				move.l	Plr2_XOff_l,Plr2_SnapXOff_l
				move.l	Plr2_ZOff_l,Plr2_SnapZOff_l
				bra		.cantmove

.nothitanything:
				move.w	#40,Obj_ExtLen_w
				move.b	#0,Obj_AwayFromWall_b
				clr.b	exitfirst
				clr.b	Obj_WallBounce_b
				bsr		MoveObject

				move.b	StoodInTop,Plr2_StoodInTop_b
				move.l	Obj_ZonePtr_l,Plr2_ZonePtr_l
				move.w	newx,Plr2_XOff_l
				move.w	newz,Plr2_ZOff_l
				move.l	Plr2_XOff_l,Plr2_SnapXOff_l
				move.l	Plr2_ZOff_l,Plr2_SnapZOff_l

.cantmove:
				move.l	Plr2_ZonePtr_l,a0
				move.l	ZoneT_Floor_l(a0),d0
				tst.b	Plr2_StoodInTop_b
				beq.s	.notintop
				move.l	ZoneT_UpperFloor_l(a0),d0

.notintop:
				adda.w	#ZoneT_Points_w,a0
				sub.l	Plr2_Height_l,d0
				move.l	d0,Plr2_SnapTYOff_l
				move.w	Plr2_TmpAngPos_w,tmpangpos
				move.w	(a0)+,d1
				ext.l	d1
				add.l	Plr2_ZonePtr_l,d1
				move.l	d1,plr2_PointsToRotatePtr_l
				tst.b	(a0)+
				beq.s	.nobackgraphics

				cmp.b	#PLR_SLAVE,Plr_MultiplayerType_b
				bne.s	.nobackgraphics

				jsr		Draw_SkyBackdrop

.nobackgraphics:
				move.b	(a0)+,Plr2_Echo_b
				adda.w	#10,a0
				move.l	a0,Plr2_PotVisibleZoneListPtr_l
				rts


fillscrnwater:
				dc.w	0
DONTDOGUN:
				dc.w	0

				include "modules/draw/draw_zone_graph.s"
DrawDisplay:
				clr.b	fillscrnwater

				; bigsine is 16kb = 8192 words for 4pi (720deg)
				; --> 4096 words per 2pi
				; --> 1024 words = 2048byte per 90deg

				move.l	#SinCosTable_vw,a0
				move.w	Vis_AngPos_w,d0
				move.w	(a0,d0.w),d6
				adda.w	#COSINE_OFS,a0				; +90 deg?
				move.w	(a0,d0.w),d7
				move.w	d6,Vis_SinVal_w
				move.w	d7,Vis_CosVal_w

				move.l	Plr_YOff_l,d0
				asr.l	#8,d0					; Plr_YOff_l >> 8
				move.w	d0,d1
				add.w	#256-32,d1				; 224
				and.w	#255,d1
				move.w	d1,draw_WallYOffset_w

				move.l	Plr_YOff_l,d0					; is Plr_YOff_l the viewer's y position << 16?
				asr.l	#6,d0					; Plr_YOff_l << 10
				move.w	d0,flooryoff			; Plr_YOff_l << 10

				move.w	Plr_XOff_l,d6
				move.w	d6,d3
				asr.w	#1,d3					; Plr_XOff_l * 0.5
				add.w	d3,d6					; Plr_XOff_l * 1.5
				asr.w	#1,d6					; Plr_XOff_l * 0.75
				move.w	d6,xoff34				; Plr_XOff_l * 3/4

				move.w	Plr_ZOff_l,d6
				move.w	d6,d3
				asr.w	#1,d3
				add.w	d3,d6
				asr.w	#1,d6
				move.w	d6,zoff34				; Plr_ZOff_l * 3/4

				bsr		RotateLevelPts
				bsr		RotateObjectPts
				bsr		CalcPLR1InLine

				cmp.b	#PLR_SINGLE,Plr_MultiplayerType_b
				bne.s	doplr2too

				move.l	Plr2_ObjectPtr_l,a0

				FREE_ENT	a0

				bra		noplr2either

doplr2too:
				bsr		CalcPLR2InLine
noplr2either:
				; Draw the level
				bsr		Draw_Zone_Graph

				tst.b	DONTDOGUN
				bne		NOGUNLOOK

				cmp.b	#PLR_SLAVE,Plr_MultiplayerType_b
				beq.s	drawslavegun

				moveq	#0,d0
				move.b	Plr1_GunSelected_b,d0
				moveq	#0,d1
				move.b	Plr1_GunFrame_w,d1
				bra		drawngun

drawslavegun:
				moveq	#0,d0
				move.b	Plr2_GunSelected_b,d0
				moveq	#0,d1
				move.b	Plr2_GunFrame_w,d1

drawngun:
NOGUNLOOK:
				moveq	#0,d1
				move.b	Plr1_GunFrame_w,d1
				sub.w	Anim_TempFrames_w,d1
				bgt.s	.nn
				moveq	#0,d1
.nn:
				move.b	d1,Plr1_GunFrame_w

				ble.s	.donefire
				sub.b	#1,Plr1_GunFrame_w
.donefire:

				moveq	#0,d1
				move.b	Plr2_GunFrame_w,d1
				sub.w	Anim_TempFrames_w,d1
				bgt.s	.nn2
				moveq	#0,d1
.nn2:
				move.b	d2,Plr2_GunFrame_w

				ble.s	.donefire2
				sub.b	#1,Plr2_GunFrame_w
.donefire2:

				tst.b	DOANYWATER
				beq.s	nowaterfull

				move.w	#FS_HEIGHT-1,d0
				move.l	Vid_FastBufferPtr_l,a0
				tst.b	fillscrnwater
				beq		nowaterfull
				bgt		oknothalf
				moveq	#FS_HEIGHT/2-1,d0
				add.l	#SCREEN_WIDTH*FS_HEIGHT/2,a0
oknothalf:

				bclr.b	#1,$bfe001

				move.l	Draw_TexturePalettePtr_l,a2
				add.l	#256*40,a2
				moveq	#0,d2

				tst.b	Vid_FullScreen_b
				bne.s	DOALLSCREEN

DOSOMESCREEN:

				move.w	#SMALL_HEIGHT-1,d0
.fw:
				move.w	#SMALL_WIDTH-1,d1
.fwa:
				move.b	(a0),d2
				move.b	(a2,d2.w),(a0)+
				dbra	d1,.fwa
				add.w	#(SCREEN_WIDTH-SMALL_WIDTH),a0
				dbra	d0,.fw
				rts

DOALLSCREEN:

fw:
				move.w	#FS_WIDTH-1,d1
fwa:
				move.b	(a0),d2
				move.b	(a2,d2.w),(a0)+
				dbra	d1,fwa
				add.w	#(SCREEN_WIDTH-FS_WIDTH),a0
				dbra	d0,fw

				rts

nowaterfull:
				bset.b	#1,$bfe001
				rts



				align 4
Lvl_CompactMapPtr_l:			dc.l	0
Lvl_BigMapPtr_l:				dc.l	0
Draw_CurrentZonePtr_l:			dc.l	0,0
Zone_SplitHeight_l:				dc.l	0
draw_WallID_w:					dc.w	0
SMALLIT:						dc.w	0
draw_GouraudFlatsSelected_b:	dc.w	0

				include	"orderzones.s"

noturn:

; got to move lr instead.

; d1 = speed moved l/r

				move.w	d1,lrs
				rts

lrs:			dc.w	0

		DCLC Vis_AngPos_w,	dc.w,	0 ; Yaw

mang:			dc.w	0
Sys_OldMouseY:	dc.w	0
xmouse:			dc.w	0

		DCLC Sys_MouseY,	dc.w,	0 ; Pitch?

MAPON:			dc.w	$0
draw_RenderMap_b:		dc.w	0

				include "modules/transform.s"

Game_Running_b:	dc.w	0						; does main game run?

endlevel:
; 	_break #0
				clr.b	dosounds
				clr.b	Game_Running_b

				; waiting for serial transmit complete?
;waitfortop22:
;				btst.b	#0,intreqrl(a6)
;				beq		waitfortop22
;waitfortop222:
;				btst.b	#0,intreqrl(a6)
;				beq		waitfortop222

				; Audio off
;				move.w	#$f,$dff000+dmacon


				move.w	Plr1_Health_w,draw_DisplayEnergyCount_w
				cmp.b	#PLR_SLAVE,Plr_MultiplayerType_b
				bne.s	.notsl
				move.w	Plr2_Health_w,draw_DisplayEnergyCount_w
.notsl:

; cmp.b #'b',Prefsfile+3
; bne.s .noback
; jsr mt_end
;.noback

				tst.w	draw_DisplayEnergyCount_w
				bgt.s	wevewon
				move.w	#0,draw_DisplayEnergyCount_w

				; Record the failure
				STATS_DIED

				; ASM build only
				IFND BUILD_WITH_C
				jsr		Draw_BorderEnergyBar
				ENDIF

				move.l	#gameover,mt_data
				st		UseAllChannels
				clr.b	reachedend
				jsr		mt_init

playgameover:
				CALLGRAF WaitTOF

				jsr		mt_music

				tst.b	reachedend
				beq.s	playgameover

				bra		wevelost

wevewon:
				; Record the victory
				STATS_WON

				; Disable audio DMA
				move.w	#$f,$dff000+dmacon

				IFND BUILD_WITH_C
				jsr		Draw_BorderEnergyBar
                ENDIF

				cmp.b	#PLR_SINGLE,Plr_MultiplayerType_b
				bne.s	.nonextlev
				add.w	#1,Game_MaxLevelNumber_w
				st		Game_FinishedLevel_b

.nonextlev:
				move.l	#welldone,mt_data
				st		UseAllChannels
				clr.b	reachedend

				jsr		mt_init
playwelldone:
				CALLGRAF WaitTOF

				jsr		mt_music

				tst.b	reachedend
				beq.s	playwelldone

				cmp.b	#PLR_SINGLE,Plr_MultiplayerType_b
				bne.s	wevelost
				cmp.w	#16,Game_MaxLevelNumber_w
				bne.s	wevelost

				jmp		ENDGAMESCROLL

wevelost:
				; disable Audio DMA
				move.w	#$f,$dff000+dmacon

				jmp		closeeverything

endnomusic:
				clr.b	Game_Running_b


				jmp		closeeverything

do32:
				move.w	#31,d7
				move.w	#$180,d1
across:
				move.w	d1,(a1)+
				move.w	d1,(a3)+
				move.w	#0,(a1)+
				move.w	#0,(a3)+
				add.w	#2,d1
				dbra	d7,across
				rts

ENDGAMESCROLL:
				move.l	Lvl_MusicPtr_l,mt_data
				clr.b	UseAllChannels
				jsr		mt_init

;				move.w	#$fff,MIXCOLL
;				move.w	#$1cc1,BOTOFTXT

				jsr		Game_ClearIntroText

;				move.l	#TEXTCOP,$dff080

				move.l	#Game_SinglePlayerVictoryText_vb,a0

				; 0xABADCAFE
				; TODO - this looks like a prime crash waiting to happen
				; shouldn't we branch somewhere before we blunder into this?

				; text was here
				rts ; better than blundering
;
;	move.l	4.w,a6
;	move.l	#string,d1
;	moveq	#0,d2
;	moveq	#0,d3
;	jsr	_LVOExecute(a6)

; include "endscroll.s"

***********************************
				include	"cd32joy.s"

*************************************
* Set left and right clip values
*************************************

				include "modules/draw/draw_set_clip.s"

Zone_Bright_w:		dc.w	0; 0xABADCAFE - Is this an ambient term for the whole zone?

;npolys:			dc.w	0



*****************************************************

				include	"objectmove.s"
				include	"newanims.s"
				include	"modules/ai.s"

********** WALL STUFF *******************************

				include	"hireswall.s"
				include	"hiresgourwall.s"

* floor polygon

numsidestd:		dc.w	0
bottomline:		dc.w	0

checkforwater:
				tst.b	draw_UseWater_b
				beq.s	.notwater

				move.l	ZonePtr_l,a1
				move.w	(a1),d7
				cmp.w	Draw_CurrentZone_w,d7
				bne.s	.notwater

				move.b	#$f,fillscrnwater

.notwater:
				move.w	(a0)+,d6				; # sides-1
;				add.w	d6,d6
;				add.w	d6,a0					; a0 + (sides-1)*2
;				add.w	#4+6,a0					; a0 + (sides-1)*2 + 10
				lea		10(a0,d6.w*2),a0
nofloor:
				rts


CLRNOFLOOR:		dc.w	0

Draw_Flats:
; a5
* If D0 =1 then its a floor otherwise (=2) it's
* a roof.
				move.w	#0,above				; reset 'above'
				move.w	(a0)+,d6				; floorY of floor/ceiling?

				tst.b	draw_UseWater_b
				beq.s	.oknon
				tst.b	DOANYWATER
				beq		dontdrawreturn

.oknon:
				move.w	d6,d7
				ext.l	d7
				asl.l	#6,d7					; floorY << 6?

				cmp.l	Draw_TopOfRoom_l,d7
				blt		checkforwater			;
				cmp.l	Draw_BottomOfRoom_l,d7
				bgt.s	dontdrawreturn

				move.w	Draw_LeftClip_w,d7
				cmp.w	Draw_RightClip_w,d7
				bge.s	dontdrawreturn			; don't draw if there's no room betwen left and Draw_RightClip_w

				sub.w	flooryoff,d6			; (floorY - viewerY)

				bgt.s	below					; floor is below
				blt.s	aboveplayer				; floor is above

				tst.b	draw_UseWater_b
				beq.s	.notwater

				move.l	ZonePtr_l,a1
				move.w	(a1),d7
				cmp.w	Draw_CurrentZone_w,d7

				bne.s	.notwater

				st		fillscrnwater

.notwater:


dontdrawreturn:
				move.w	(a0)+,d6				; sides-1
				;add.w	d6,d6
				;add.w	d6,a0
				;add.w	#4+6,a0
				lea		10(a0,d6.w*2),a0		; skip sides
				rts

aboveplayer:
				tst.b	draw_UseWater_b
				beq.s	.notwater

				move.l	ZonePtr_l,a1
				move.w	(a1),d7
				cmp.w	Draw_CurrentZone_w,d7
				bne.s	.notwater

				move.b	#$f,fillscrnwater

				; Is above camera
.notwater:		btst	#1,d0					; If its above the player and if its not a ceiling (a floor?), skip it
				beq.s	dontdrawreturn

				; its a ceiling
				move.w	Vid_CentreY_w,d7
				sub.w	draw_TopClip_w,d7
				ble.s	dontdrawreturn

				move.w	#1,d0
				move.w	d0,above				; replace with st above? But then also check the various places that tst.w it
				neg.w	d6
				bra.s	notbelow

				; is below camera
below:
				move.w	draw_BottomClip_w,d7
				sub.w	Vid_CentreY_w,d7
				ble.s	dontdrawreturn			; don't draw if no room between screen center amd bottom clip


notbelow:
				btst	#0,d0					; if its below the player and is not a floor, skip it
				beq.s	dontdrawreturn

				move.w	d6,View2FloorDist		; (floorY - ViewerY) in worldspace
				;		|
				;-------+---------------------- Vid_CentreY_w
				;***    |
				;   *** |
				;      *** clipY
				;       |  ***
				;-------------***----------------FloorDist from Viewer
				;>   minZ		<
				;
				; clip Y =  FloorDist/minZ
				; minZ = FloorDist / clipY

				move	d6,d5
				ext.l	d5
				asl.l	#6,d5					; View2FloorDist << 6
				move.l	d5,ypos					; ypos = View2FloorDist * 64

				;ext.l	d7
				;divs.l	d7,d6					; d6 = (floorY - ViewerY) / (Y-clip to middleY)?
												; projects the Y-clip screen coordinate to Z in the world
												; it thus

				mulu.w	OneOverN_vw(pc,d7.w*2),d6
				lsr.l	#8,d6

; visible line

				beq		dontdrawreturn

				cmp.l	#32767,d6
				bgt		dontdrawreturn

				move.w	d6,minz
				move.w	d7,bottomline

; Go round each point finding out
; if it should be visible or not.

				move.l	a0,-(a7)

				move.w	(a0)+,d7				; number of sides
				move.l	#Rotated_vl,a1
				move.l	#OnScreen_vl,a2
; move.l #NewCornerBuff,a3
				moveq	#0,d4					; some points left to left clip
				moveq	#0,d5					; some points fully between left and right clip
				moveq	#0,d6					; some points right of right clip
				clr.b	anyclipping				; some clipping will be necessary?


cornerprocessloop: ;	figure					out if any left/right clipping is necessary
				; this also helps rejecting whole floors, almost in a portal-engine fashion

				move.w	(a0)+,d0				; point index
				and.w	#$fff,d0
				move.w	6(a1,d0.w*8),d1			; fetch prerotated point Z fractional part?
				ble		.canttell

				move.w	(a2,d0.w*2),d3			; fetch projected X coordinate
				cmp.w	Draw_LeftClip_w,d3
				bgt.s	.nol					; right of left clip
				st		d4
				st		anyclipping
				bra.s	.nos
.nol:
				cmp.w	Draw_RightClip_w,d3
				blt.s	.nor					; left of right clip
				st		d6
				st		anyclipping
				bra.s	.nos
.nor:
				st		d5
.nos:
				bra		.cantell

.canttell:
				st		d5
				st		anyclipping

.cantell:
				dbra	d7,cornerprocessloop

				move.l	(a7)+,a0
				tst.b	d5						; if this is 0, none of the corner points were inside the clip region
				bne.s	somefloortodraw
				eor.b	d4,d6					; if some were left of left clip and the others right of right clip
											; some floor covers the clip region
											; only if they are all left or all right, nothing needs to be drawn
				bne		dontdrawreturn

somefloortodraw:
				DEV_CHECK_SET	SKIP_FLATS,dontdrawreturn
				DEV_INC.w	VisibleFlats
				tst.b	draw_UseGouraudFlats_b
				bne		goursides

				move.w	#300,top				; running top clip
				move.w	#-1,bottom				; running bottom clip
				move.w	#0,drawit
				move.l	#Rotated_vl,a1
				move.l	#OnScreen_vl,a2
				move.w	(a0)+,d7				; no of sides

; clip floor polygon against closest possible visible z (due to bottom/top clipping) "minz"
sideloop:
				move.w	minz,d6
				move.w	(a0)+,d1				; floor line point indices
				move.w	(a0),d3
				and.w	#$fff,d1				; mod 4096 , why?
				and.w	#$fff,d3				; mod 4096

				move.w	6(a1,d1*8),d4			; first z
				cmp.w	d6,d4
				bgt		firstinfront

				move.w	6(a1,d3*8),d5			; sec z
				cmp.w	d6,d5
				ble		bothbehind

** line must be on left and partially behind.
				sub.w	d5,d4					; dz
				move.l	(a1,d1*8),d0			; first x
				sub.l	(a1,d3*8),d0			; dx = first x - second x

				asr.l	#7,d0					; dx << 9

				sub.w	d5,d6					; distMinz = minz - z
												; (projecting onto nearplane)

				muls	d6,d0					; x' = dist * dx
				divs	d4,d0					; x' = distMinz * dx/dz
				ext.l	d0
				asl.l	#7,d0

				add.l	(a1,d3*8),d0			; x' = x + distMinz * dx/dz
				move.w	minz,d4					; z' = minZ
				move.w	(a2,d3*2),d2
				divs.w	d4,d0					; x' - x' / minz
				add.w	Vid_CentreX_w,d0

				move.l	ypos,d3
				divs	d5,d3					; y2' = y2 / z2

				move.w	bottomline,d1
				bra		lineclipped

firstinfront:
				move.w	6(a1,d3*8),d5			; sec z
				cmp.w	d6,d5
				bgt		bothinfront

** line must be on right and partially behind.
				sub.w	d4,d5					; dz
				move.l	(a1,d3*8),d2
				sub.l	(a1,d1*8),d2			; dx
				sub.w	d4,d6					; minz - z

				asr.l	#7,d2
				muls	d6,d2					; new x coord
				divs	d5,d2					; x ' = (dx >> 7) * (minz - z) / dz
				ext.l	d2

				asl.l	#7,d2					; x' >> 7
				add.l	(a1,d1*8),d2			; x ' = x1 + x'

				move.w	minz,d5
				move.w	(a2,d1*2),d0
				divs	d5,d2
				add.w	Vid_CentreX_w,d2
				move.l	ypos,d1
				divs	d4,d1
				move.w	bottomline,d3
				bra		lineclipped

bothinfront:

* Also, usefully enough, both are on-screen
* so no bottom clipping is needed.

				move.w	(a2,d1*2),d0			; first x
				move.w	(a2,d3*2),d2			; second x
				move.l	ypos,d1
				move.l	d1,d3
				divs	d4,d1					; ypos / first z
				divs	d5,d3					; ypos / second z

				; line is  now in (d0/d1 )(d2/d3)  x/y
				; now "draw" the projected line into the line buffer which stores X
				; values
lineclipped:
				move.l	#RightSideTable_vw,a3
				cmp.w	d1,d3
				beq		lineflat				; if line is flat, skip

				st		drawit
				bgt		lineonright
				move.l	#LeftSideTable_vw,a3

				; switch points to make line sloped downwards
				exg		d1,d3
				exg		d0,d2

				lea		(a3,d1*2),a3			; start of left side buffer

				cmp.w	top(pc),d1
				bge.s	.no_new_top
				move.w	d1,top
.no_new_top:
				cmp.w	bottom(pc),d3
				ble.s	.no_new_bottom
				move.w	d3,bottom
.no_new_bottom:

				sub.w	d1,d3					; dy
				sub.w	d0,d2					; dx

				blt		.linegoingleft

				ext.l	d2
				divs	d3,d2
				move.w	d2,d6					; dx/dy
				swap	d2						; dx mod dy

				move.w	d3,d4					; dy
				move.w	d3,d5
				subq	#1,d5					; dy - 1   loop counter
				move.w	d6,d1
				addq	#1,d1					; dx/dy + 1

				; Is this "drawing" left line into a buffer, using bresenham, storing the X values into a3
.pixlopright:
				move.w	d0,(a3)+				; store x in left side entry buffer
				sub.w	d2,d4					; dy - (dx mod dy)
				bge.s	.nobigstep
				add.w	d1,d0
				add.w	d3,d4
				dbra	d5,.pixlopright
				bra		lineflat
.nobigstep
				add.w	d6,d0
				dbra	d5,.pixlopright
				bra		lineflat

			; line is  now in (d0/d1 )(d2/d3)  x/y
			; now "draw" the projected line into the line buffer which stores X
			; values
.linegoingleft:

				neg.w	d2						; dx = -dx

				ext.l	d2
				divs	d3,d2					; dx/dy
				move.w	d2,d6
				swap	d2						; dx mod dy

				move.w	d3,d4
				move.w	d3,d5
				subq	#1,d5

				move.w	d6,d1
				addq	#1,d1

.pixlopleft:
				sub.w	d2,d4
				bge.s	.nobigstepl
				sub.w	d1,d0
				add.w	d3,d4
				move.w	d0,(a3)+				;  store left side entry
				dbra	d5,.pixlopleft
				bra		lineflat

.nobigstepl:
				sub.w	d6,d0
				move.w	d0,(a3)+				; store left side entry
				dbra	d5,.pixlopleft
				bra		lineflat

			; Is this "drawing" right line into a buffer, storing the X values into a3
lineonright:

				lea		(a3,d1*2),a3			;right line entry start

				cmp.w	top(pc),d1
				bge.s	.no_new_top
				move.w	d1,top
.no_new_top:
				cmp.w	bottom(pc),d3
				ble.s	.no_new_bottom
				move.w	d3,bottom
.no_new_bottom:

				sub.w	d1,d3					; dy
				sub.w	d0,d2					; dx
				blt		.linegoingleft
; addq #1,d0
				ext.l	d2
				divs	d3,d2
				move.w	d2,d6
				swap	d2

				move.w	d3,d4
				move.w	d3,d5
				subq	#1,d5
				move.w	d6,d1
				addq	#1,d1

.pixlopright:
				sub.w	d2,d4
				bge.s	.nobigstep
				add.w	d1,d0
				add.w	d3,d4
				move.w	d0,(a3)+				; store right entry
				dbra	d5,.pixlopright
				bra		lineflat

.nobigstep:
				add.w	d6,d0
				move.w	d0,(a3)+				; store right entry
				dbra	d5,.pixlopright
				bra		lineflat

.linegoingleft:
; addq #1,d0
				neg.w	d2

				ext.l	d2
				divs	d3,d2
				move.w	d2,d6
				swap	d2

				move.w	d3,d4
				move.w	d3,d5
				subq	#1,d5
				move.w	d6,d1
				addq	#1,d1

.pixlopleft:
				move.w	d0,(a3)+
				sub.w	d2,d4
				bge.s	.nobigstepl
				sub.w	d1,d0
				add.w	d3,d4
				dbra	d5,.pixlopleft
				bra		lineflat

.nobigstepl:
				sub.w	d6,d0
				dbra	d5,.pixlopleft

lineflat:

bothbehind:
				dbra	d7,sideloop
				bra		pastsides

				align 4
fbr:			dc.w	0
sbr:			dc.w	0
FloorPtBrightsPtr_l:	dc.l	0

goursides:
				move.w	#300,top
				move.w	#-1,bottom
				move.w	#0,drawit
				move.l	#Rotated_vl,a1
				move.l	#OnScreen_vl,a2
				move.w	(a0)+,d7				; no of sides

sideloopGOUR:
				move.w	minz,d6
				move.w	(a0)+,d1
				move.w	(a0),d3

				move.w	d1,d4
				move.w	d3,d5
				and.w	#$0fff,d1
				and.w	#$0fff,d3

				rol.w	#4,d4
				rol.w	#4,d5
				and.w	#$f,d4
				and.w	#$f,d5

				move.l	FloorPtBrightsPtr_l,a4
				move.w	(a4,d4.w*8),d4
				bge.s	.okpos1
				neg.w	d4
.okpos1:
				sub.w	#300,d4
				move.w	d4,fbr
				move.w	(a4,d5.w*8),d4
				bge.s	.okpos2
				neg.w	d4
.okpos2:
				sub.w	#300,d4
				move.w	d4,sbr

				move.w	6(a1,d1*8),d4			;first z
				cmp.w	d6,d4
				bgt		firstinfrontGOUR

				move.w	6(a1,d3*8),d5			; sec z
				cmp.w	d6,d5
				ble		bothbehindGOUR
** line must be on left and partially behind.
				sub.w	d5,d4

				move.w	fbr,d0
				sub.w	sbr,d0
				sub.w	d5,d6
				muls	d6,d0

				divs	d4,d0
				add.w	sbr,d0
				move.w	d0,fbr

				move.l	(a1,d1*8),d0
				sub.l	(a1,d3*8),d0
				asr.l	#7,d0
				muls	d6,d0					; new x coord
				divs	d4,d0

				ext.l	d0
				asl.l	#7,d0

				add.l	(a1,d3*8),d0
				move.w	minz,d4
				move.w	(a2,d3*2),d2
				divs	d4,d0
				add.w	Vid_CentreX_w,d0
				move.l	ypos,d3
				divs	d5,d3

				move.w	bottomline,d1
				bra		lineclippedGOUR

firstinfrontGOUR:
				move.w	6(a1,d3*8),d5			; sec z
				cmp.w	d6,d5
				bgt		bothinfrontGOUR
** line must be on right and partially behind.
				sub.w	d4,d5					; dz

				move.w	sbr,d2
				sub.w	fbr,d2
				sub.w	d4,d6
				muls	d6,d2
				divs	d5,d2
				add.w	fbr,d2
				move.w	d2,sbr

				move.l	(a1,d3*8),d2
				sub.l	(a1,d1*8),d2			; dx
				asr.l	#7,d2
				muls	d6,d2					; new x coord
				divs	d5,d2

				ext.l	d2
				asl.l	#7,d2
				add.l	(a1,d1*8),d2
				move.w	minz,d5					; minz = nearclip distance?
				move.w	(a2,d1*2),d0
				divs	d5,d2
				add.w	Vid_CentreX_w,d2
				move.l	ypos,d1
				divs	d4,d1
				move.w	bottomline,d3
				bra		lineclippedGOUR

bothinfrontGOUR:

* Also, usefully enough, both are on-screen
* so no bottom clipping is needed.

				move.w	(a2,d1*2),d0			; first x
				move.w	(a2,d3*2),d2			; second x

				move.l	ypos,d1
				move.l	d1,d3
				divs	d4,d1					; first y
				divs	d5,d3					; second y


lineclippedGOUR:
				move.l	#RightSideTable_vw,a3
				cmp.w	d1,d3
				bne		linenotflatGOUR

				bra		lineflatGOUR

linenotflatGOUR:
				st		drawit
				bgt		lineonrightGOUR
				move.l	#LeftSideTable_vw,a3
				exg		d1,d3
				exg		d0,d2

				lea		(a3,d1*2),a3			; left side entry
				lea		LeftBrightTable_vw-LeftSideTable_vw(a3),a4 ; left side brightness entry

				cmp.w	top(pc),d1
				bge.s	.no_new_top
				move.w	d1,top
.no_new_top:
				cmp.w	bottom(pc),d3
				ble.s	.no_new_bottom
				move.w	d3,bottom
.no_new_bottom:

				sub.w	d1,d3					; dy
				sub.w	d0,d2					; dx

				blt		.linegoingleft

				ext.l	d2
				divs	d3,d2
				move.w	d2,d6					; dx/dy
				swap	d2						; dx mod dy?
				move.w	d2,a5

				move.w	d3,d4					; dy
				move.w	d3,d5					; dy
				subq	#1,d5					; dy-1
				move.w	d6,d1
				addq	#1,d1
				move.w	d1,a6

				moveq	#0,d1
				move.w	sbr,d1
				move.w	fbr,d2
				sub.w	d1,d2
				ext.l	d2

				asl.w	#8,d2					; is this some gouraud math?
				asl.w	#2,d2
				divs	d3,d2
				ext.l	d2
				asl.l	#6,d2

				swap	d1

.pixlopright:
				move.w	d0,(a3)+				; store left side entry
				swap	d1
				move.w	d1,(a4)+				; store left side entry brightness
				swap	d1
				add.l	d2,d1

				sub.w	a5,d4
				bge.s	.nobigstep
				add.w	a6,d0
				add.w	d3,d4
				dbra	d5,.pixlopright
				bra		lineflatGOUR
.nobigstep:

				add.w	d6,d0
				dbra	d5,.pixlopright
				bra		lineflatGOUR

.linegoingleft:

				neg.w	d2

				ext.l	d2
				divs	d3,d2
				move.w	d2,d6
				swap	d2

				move.w	d3,d4
				move.w	d3,d5
				subq	#1,d5

				move.w	d6,d1
				addq	#1,d1
				move.w	d1,a6
				move.w	d2,a5

				moveq	#0,d1
				move.w	sbr,d1
				move.w	fbr,d2
				sub.w	d1,d2
				ext.l	d2
				asl.w	#8,d2
				asl.w	#2,d2
				divs	d3,d2
				ext.l	d2
				asl.l	#6,d2
				swap	d1

.pixlopleft:

				swap	d1
				move.w	d1,(a4)+				; store right side entry brightness
				swap	d1
				add.l	d2,d1

				sub.w	a5,d4
				bge.s	.nobigstepl
				sub.w	a6,d0
				add.w	d3,d4
				move.w	d0,(a3)+				; store left side entry
				dbra	d5,.pixlopleft
				bra		lineflatGOUR

.nobigstepl:
				sub.w	d6,d0
				move.w	d0,(a3)+				; store left side entry
				dbra	d5,.pixlopleft
				bra		lineflatGOUR

lineonrightGOUR:

				lea		(a3,d1*2),a3			; left side entry

				lea		RightBrightTable_vw-RightSideTable_vw(a3),a4 ; right brightness entry

				cmp.w	top(pc),d1
				bge.s	.no_new_top
				move.w	d1,top
.no_new_top:
				cmp.w	bottom(pc),d3
				ble.s	.no_new_bottom
				move.w	d3,bottom
.no_new_bottom:

				sub.w	d1,d3					; dy
				sub.w	d0,d2					; dx
				blt		.linegoingleft
; addq #1,d0
				ext.l	d2
				divs	d3,d2
				move.w	d2,d6
				swap	d2

				move.w	d3,d4
				move.w	d3,d5
				subq	#1,d5
				move.w	d6,d1
				addq	#1,d1

				move.w	d1,a6
				move.w	d2,a5

				moveq	#0,d1
				move.w	fbr,d1
				move.w	sbr,d2
				sub.w	d1,d2
				ext.l	d2
				asl.w	#8,d2
				asl.w	#2,d2
				divs	d3,d2
				ext.l	d2
				asl.l	#6,d2
				swap	d1

.pixlopright:

				swap	d1
				move.w	d1,(a4)+				; store right side brightness entry
				swap	d1
				add.l	d2,d1

				sub.w	a5,d4
				bge.s	.nobigstep
				add.w	a6,d0
				add.w	d3,d4
				move.w	d0,(a3)+				; store right side entry
				dbra	d5,.pixlopright
				bra		lineflatGOUR

.nobigstep:
				add.w	d6,d0
				move.w	d0,(a3)+				;  store right side entry
				dbra	d5,.pixlopright
				bra		lineflatGOUR

.linegoingleft:
; addq #1,d0
				neg.w	d2

				ext.l	d2
				divs	d3,d2
				move.w	d2,d6
				swap	d2

				move.w	d3,d4
				move.w	d3,d5
				subq	#1,d5
				move.w	d6,d1
				addq	#1,d1
				move.w	d1,a6
				move.w	d2,a5

				moveq	#0,d1
				move.w	fbr,d1
				move.w	sbr,d2
				sub.w	d1,d2
				ext.l	d2
				asl.w	#8,d2
				asl.w	#2,d2
				divs	d3,d2
				ext.l	d2
				asl.l	#6,d2
				swap	d1

.pixlopleft:

				swap	d1
				move.w	d1,(a4)+				; store left entry brightness
				swap	d1
				add.l	d2,d1

				move.w	d0,(a3)+				; store left entry x
				sub.w	a5,d4
				bge.s	.nobigstepl
				sub.w	a6,d0
				add.w	d3,d4
				dbra	d5,.pixlopleft
				bra		lineflatGOUR

.nobigstepl:
				sub.w	d6,d0
				dbra	d5,.pixlopleft

lineflatGOUR:

bothbehindGOUR:
				dbra	d7,sideloopGOUR


; I think wwhat happens is that the above code records lots of left/right pixel
; pairs in lefttab, leftbrightab, righttab and RightBrightTable_vw by edge-walking the floor polygon.
; Each entry's offset in the tables are hard0-wired to a specific Y position in the rendered
; image. I.e. lighttab[5] is the leftmost X coordinate of the floor on line 5 of the screen.

; Here we setup the actual line drawing
pastsides:

				addq	#2,a0

				move.w	#SCREEN_WIDTH,linedir	; moving from one horizontal line to the next
												; floors walk downwards

; move.l FASTBUFFER2,a6
; add.l BIGMIDDLEY,a6
; move.l a6,REFPTR

				move.l	Vid_FastBufferPtr_l,a6
				add.l	BIGMIDDLEY,a6			; pointer to middle line of screen
				move.w	(a0)+,d6				; floor scale?
				add.w	SMALLIT,d6
				move.w	d6,scaleval
				move.w	(a0)+,d6
				move.w	d6,whichtile
				move.w	(a0)+,d6
				add.w	Zone_Bright_w,d6
				move.w	d6,lighttype
				move.w	above(pc),d6			; is floor above player (i.e. ceiling)
				beq		groundfloor
; on ceiling:
				move.w	#-SCREEN_WIDTH,linedir	; ceilings are walked bottom to top
				suba.w	#SCREEN_WIDTH,a6

groundfloor:
				move.w	Plr_XOff_l,d6
				move.w	Plr_ZOff_l,d7
				; add.w	xwobxoff,d6				; this was adding xwobxoff to d7, was this a bug?
				add.w	xwobxoff,d7
				add.w	xwobzoff,d6
***************************************************************remove later
				; tst.b	Vid_FullScreen_b
				; bra.s	.shiftit

				; ;ext.l	d6
				; ;ext.l	d7
				; ;asl.l	#2,d6		; Fullscreen : scale world by *4/3,
				; ;asl.l	#2,d7
				; ;divs	#3,d6
				; ;divs	#3,d7
				; ;swap	d6
				; ;swap	d7
				; ;clr.w	d6
				; ;clr.w	d7
				; ;asr.l	#2,d6
				; ;asr.l	#2,d7

				; ; stll don't really understand why the render aspect ratio gets rolled into here
				; ; as these are supposed to be the viewer/s position in the world
				; ;muls.w	#21845,d6				; (4/3<<16)/4
				; ;muls.w	#21845,d7

				; ; Change suggestion by AL
				; muls.w	#19661,d6				; (5/6<<16)/4
				; muls.w	#19661,d7

				; bra.s	.donsht

; .shiftit:

***************************************************************
; divs #3,d6
; divs #3,d7
				swap	d6
				swap	d7
				clr.w	d6
				clr.w	d7
				asr.l	#1,d6
				asr.l	#1,d7


.donsht:
				move.w	scaleval(pc),d3			; FIMXE: is this an opportunity to scale for Vid_DoubleWidth_b/Vid_DoubleHeight_b?
				beq.s	.samescale
				bgt.s	.scaledown
				neg.w	d3
				asr.l	d3,d7
				asr.l	d3,d6
				bra.s	.samescale
.scaledown:
				asl.l	d3,d6
				asl.l	d3,d7
.samescale:
				move.l	d6,sxoff
				move.l	d7,szoff
				bra		pastscale

				align 4
ypos:			dc.l	0
minz:			dc.l	0

top:			dc.w	0
bottom:			dc.w	0

nfloors:		dc.w	0
lighttype:		dc.w	0
above:			dc.w	0
linedir:		dc.w	0
View2FloorDist:	dc.w	0

movespd:		dc.w	0
largespd:		dc.l	0 ; unused?
disttobot:		dc.w	0

				align 4
OneOverN_vw:		; 1/N	* 16384
				dc.w	0						;16384/0 not defined
val				SET		1
				REPT	MAX_ONE_OVER_N
				dc.w	16384/val
val				SET		val+1
				ENDR


********************************************************************************

				; Walk the stored lines and draw them
pastscale:
				tst.b	drawit(pc)
				beq		dontdrawfloor

				tst.b	Vid_DoubleHeight_b
				beq		pix1h

				; Vid_DoubleHeight_b rendering
				move.l	a0,-(a7)
				move.w	linedir,d1				; line to line in screen
				add.w	d1,linedir				; x2

				move.l	#LeftSideTable_vw,a4
				move.w	top(pc),d1
				tst.w	above					; is above camera?
				beq.s	.clipfloor				; no, its a floor!

; Its a ceiling, clip it to top/bottom
; For ceilings, the top and bottom have reversed roles
; The ceiling's +Y goes "up" on the screen, with Vid_CentreY_w of screen mapping to 0.
; That's why there's the gymnastics with ; (Vid_CentreY_w - N) to transform the
; screen clipping coordinates into "ceiling coordinates"
; This turns the 'top' variable actually into the bottommost Y of the ceiling.

				move.w	Vid_CentreY_w,d7
				btst	#0,d7
				bne.s	.evenMiddleRoof
				sub.w	#SCREEN_WIDTH,a6			; with regular nx1 rendering, we usually start at an odd line for ceiling rendering

.evenMiddleRoof	subq	#1,d7
				sub.w	d1,d7
				move.w	d7,disttobot

				move.w	bottom(pc),d7			; bottom of floor
				move.w	Vid_CentreY_w,d3
				move.w	d3,d4
				sub.w	draw_TopClip_w,d3
				sub.w	draw_BottomClip_w,d4
				cmp.w	d3,d1
				bge		predontdrawfloor		; top_of_floor >= (Vid_CentreY_w-draw_TopClip_w)
				cmp.w	d4,d7
				blt		predontdrawfloor		; bottom_of_floor < (Vid_CentreY_w-draw_BottomClip_w) ?
				cmp.w	d4,d1
				bge.s	.nocliptoproof			; top_of_floor >= (Vid_CentreY_w-draw_BottomClip_w)  ?
				move.w	d4,d1					; clip top_of_floor to (Vid_CentreY_w-draw_BottomClip_w)
.nocliptoproof
				cmp.w	d3,d7
				blt		.doneclip
				move.w	d3,d7

				bra		.doneclip

; Its a floor, clip it to top/bottom
; FIXME: didn't we already clip to the bottom clip (minZ) ?

.clipfloor:
				move.w	Vid_BottomY_w,d7
				move.w	Vid_CentreY_w,d4
				btst	#0,d4
				beq.s	.evenMiddleFloor
				add.w	#SCREEN_WIDTH,a6

.evenMiddleFloor sub.w	d4,d7
				subq	#1,d7
				sub.w	d1,d7
				move.w	d7,disttobot

				move.w	bottom(pc),d7

				move.w	draw_BottomClip_w,d4
				sub.w	Vid_CentreY_w,d4
				cmp.w	d4,d1
				bge		predontdrawfloor		; top >= (draw_BottomClip_w - Vid_CentreY_w)

				move.w	draw_TopClip_w,d3
				sub.w	Vid_CentreY_w,d3
				cmp.w	d3,d1
				bge.s	.nocliptopfloor			; top >= (draw_TopClip_w - Vid_CentreY_w)

				move.w	d3,d1					; clip top_of_floor to (draw_TopClip_w - Vid_CentreY_w)
.nocliptopfloor
				cmp.w	d3,d7
				ble		predontdrawfloor		; (bottom) <= (draw_TopClip_w - Vid_CentreY_w) : bottom <= draw_TopClip_w (bottom of floor above draw_TopClip_w)
				cmp.w	d4,d7
				blt.s	.noclipbotfloor			; (bottom) < (draw_BottomClip_w)
				move.w	d4,d7					; bottom = draw_BottomClip_w
.noclipbotfloor:


.doneclip:		;addq.w	#1,d1					; snap start of floor to even line - needed?!
				;and.w	#~1,d1

				lea		(a4,d1*2),a4			; adress of first floor/roof line

				addq	#1,d7
				sub.w	d1,d7					; number of lines

				asr.w	#1,d7					; number of lines /2 for Vid_DoubleHeight_b
				ble		predontdrawfloor		; nothing left?

				asr.w	#1,d1					; top line/2 for Vid_DoubleHeight_b

				move.w	View2FloorDist,d0		; ydist<<6 to floor/ceiling	; distance of viewer to floor
***************************************************************
;could this be screen width * 0.33333 ?
				tst.b	Vid_FullScreen_b
				beq.s .smallscreen
				muls	#107,d0
				bra	.fullscreen
.smallscreen:
				;muls	#64,d0			; FIXME: why muls here? Is this addressing the floor tile row?
				ext.l	d0
				lsl.l	#6,d0
.fullscreen:
***************************************************************
				move.l	d0,a2					; a2

				move.w	d1,d0
				bne.s	.notzero
				moveq	#1,d0					; always start at line 1?
.notzero
				add.w	d0,d0					; start line# *2 Vid_DoubleHeight_b

				muls.w	linedir,d1				; top line in screen times renderwidth (typical 320)
				add.l	d1,a6					; this is where we start writing?

				move.l	Draw_TexturePalettePtr_l,a1
				add.l	#256*32,a1

				lea		draw_FloorLine,a5
				move.w	#4,tonextline			; line tab advance?

				bra		pix2h

				; Regular Nx1 line rendering
pix1h:

				move.l	a0,-(a7)

				move.l	#LeftSideTable_vw,a4
				move.w	top(pc),d1

				tst.w	above
				beq.s	clipfloor

				; clip roof?
				move.w	Vid_CentreY_w,d7
				subq	#1,d7
				sub.w	d1,d7
				move.w	d7,disttobot

				move.w	bottom(pc),d7
				move.w	Vid_CentreY_w,d3
				move.w	d3,d4
				sub.w	draw_TopClip_w,d3
				sub.w	draw_BottomClip_w,d4
				cmp.w	d3,d1
				bge		predontdrawfloor		; top >= Vid_CentreY_w - draw_TopClip_w
				cmp.w	d4,d7
				blt		predontdrawfloor		; bottom >= Vid_CentreY_w - bottomclip
				cmp.w	d4,d1
				bge.s	.nocliptoproof			F; top >= Vid_CentreY_w - bottomclip
				move.w	d4,d1					; top = Vid_CentreY_w - bottomclip
.nocliptoproof
				cmp.w	d3,d7
				blt		doneclip
				move.w	d3,d7
				bra		doneclip

clipfloor:
				move.w	Vid_BottomY_w,d7
				sub.w	Vid_CentreY_w,d7
				subq	#1,d7
				sub.w	d1,d7
				move.w	d7,disttobot

				move.w	bottom(pc),d7
				move.w	draw_BottomClip_w,d4
				sub.w	Vid_CentreY_w,d4
				cmp.w	d4,d1
				bge		predontdrawfloor		; top >= (draw_BottomClip_w - Vid_CentreY_w)
				move.w	draw_TopClip_w,d3
				sub.w	Vid_CentreY_w,d3
				cmp.w	d3,d1
				bge.s	.nocliptopfloor			; top >= (draw_TopClip_w - Vid_CentreY_w)
				move.w	d3,d1					; top =  (draw_TopClip_w - Vid_CentreY_w)
.nocliptopfloor
				cmp.w	d3,d7
				ble		predontdrawfloor		; bottom <=  (draw_TopClip_w - Vid_CentreY_w)
				cmp.w	d4,d7
				blt.s	.noclipbotfloor			; bottom <= (draw_BottomClip_w - Vid_CentreY_w)
				move.w	d4,d7					; botom = (draw_BottomClip_w - Vid_CentreY_w)
.noclipbotfloor:

doneclip:
				lea		(a4,d1*2),a4			; go to top linetab
				move.w	View2FloorDist,d0
***************************************************************
;could this be screen width * 0.33333 ?
				tst.b	Vid_FullScreen_b
				beq.s .smallscreen
				muls	#107,d0
				bra	.fullscreen
.smallscreen:
				;muls	#64,d0			; FIXME: why muls here? Is this addressing the floor tile row?
				ext.l	d0
				lsl.l	#6,d0
.fullscreen:
***************************************************************

				move.l	d0,a2
; muls #25,d0
; adda.w d0,a2
; lea (a2,d1*2),a2
				sub.w	d1,d7					;  number of lines to draw
				ble		predontdrawfloor
				move.w	d1,d0					; current line
				bne.s	.notzero
				moveq	#1,d0					; at least start at line 1 ?!
												; We later divide  by d0, so make sure its not 0
.notzero
				muls	linedir,d1
				add.l	d1,a6					; renderbuffer start address
; sub.l d1,REFPTR
				move.l	Draw_TexturePalettePtr_l,a1
				add.l	#256*32,a1
;				move.l	LineToUse,a5			; This function ptr has been stored by the very outermost
				lea		draw_FloorLine,a5
				move.w	#2,tonextline			; lefttab/righttab advance?


				;double height rendering
pix2h:

				tst.b	draw_UseGouraudFlats_b
				bne		dogourfloor

				tst.b	anyclipping
				beq		dofloornoclip

dofloor:
; move.w (a2)+,d0
				move.w	Draw_LeftClip_w,d3
				move.w	Draw_RightClip_w,d4
				move.w	RightSideTable_vw-LeftSideTable_vw(a4),d2 ; get rightside of line

				addq	#1,d2					; why? Is the right side X not inclusive?
				cmp.w	d3,d2					; does this make sense?
				ble.s	nodrawline				; rightside <= Draw_LeftClip_w?

				cmp.w	d4,d2
				ble.s	noclipright				; Draw_RightClip_w <= rightside?
				move.w	d4,d2					; clip rightside to Draw_RightClip_w
noclipright:
				move.w	(a4),d1					; leftside x
				cmp.w	d4,d1
				bge.s	nodrawline				; leftside >= Draw_RightClip_w?
				cmp.w	d3,d1
				bge.s	noclipleft				; leftside >= Draw_LeftClip_w
				move.w	d3,d1					; leftside = Draw_LeftClip_w
noclipleft:
				cmp.w	d1,d2
				ble.s	nodrawline				; rightside <= leftside?

				move.w	d1,leftedge
				move.w	d2,rightedge
				move.l	a6,a3

				movem.l	d0/d7/a2/a4/a5/a6,-(a7)

				; perspective correct interpolation of Z over the floor by just looking at
				; the screenspace coordinate and the floor height
				; https://youtu.be/2ZAIIDXoBis?t=1385

				move.l	a2,d7					; View2FloorDist*64 (distance of viewer Y to floor in worldspace)
				;asl.l	#2,d7		; *4 = * 256
				;ext.l	d0
				;divs.w	d0,d7		; View2FloorDist * 256 / currentline
				;ext.l	d7

				lsr.l	#4,d7
				mulu.w	OneOverN_vw(pc,d0.w*2),d7	;  View2FloorDist * 64 * 16384 / currentline
				lsr.l	#8,d7

				; for some reason important to write.l here
				move.l	d7,d0					; Z of current screen line projected to floor

				jsr		(a5)					; Call the horizontal line drawing routine!

				movem.l	(a7)+,d0/d7/a2/a4/a5/a6
nodrawline
				sub.w	#1,disttobot
				move.w	linedir(pc),d3
				adda.w	d3,a6
; ext.l d3
; sub.l d3,REFPTR
				move.w	tonextline,d3
				add.w	d3,a4
				asr.w	#1,d3
				add.w	d3,d0
				subq	#1,d7
				bgt		dofloor

predontdrawfloor
				move.l	(a7)+,a0

dontdrawfloor:

				rts

tonextline:		dc.w	0
anyclipping:	dc.w	0

dofloornoclip:
; move.w (a2)+,d0
				move.w	RightSideTable_vw-LeftSideTable_vw(a4),d2 ;offset from leftside table entry to right side table entry
				addq	#1,d2					;

				move.w	(a4),d1
				move.w	d1,leftedge
				move.w	d2,rightedge


				move.l	a6,a3
				movem.l	d0/d7/a2/a4/a5/a6,-(a7)

				;move.l	a2,d7
				;asl.l	#2,d7
				;ext.l	d0
				;divs.l	d0,d7

				move.l	 a2,d7
				lsr.l	#4,d7
				mulu.w	OneOverN_vw(pc,d0.w*2),d7	;
				lsr.l	#8,d7

				move.l	d7,d0

				jsr		(a5)

				movem.l	(a7)+,d0/d7/a2/a4/a5/a6
				sub.w	#1,disttobot
				move.w	linedir(pc),d3
				adda.w	d3,a6
; ext.l d3
; sub.l d3,REFPTR
				move.w	tonextline,d3
				add.w	d3,a4
				asr.w	#1,d3
				add.w	d3,d0
				subq	#1,d7
				bgt		dofloornoclip

				bra		predontdrawfloor

dogourfloor:
				tst.b	anyclipping
				beq		dofloornoclipGOUR

dofloorGOUR:
; move.w (a2)+,d0
				move.w	Draw_LeftClip_w,d3
				move.w	Draw_RightClip_w,d4
				move.w	RightSideTable_vw-LeftSideTable_vw(a4),d2

				move.w	d2,d5
				sub.w	(a4),d5
				addq	#1,d5
				moveq	#0,d6

				addq	#1,d2
				cmp.w	d3,d2
				ble		nodrawlineGOUR
				cmp.w	d4,d2
				ble.s	nocliprightGOUR
				move.w	d4,d2

nocliprightGOUR:
				move.w	(a4),d1
				cmp.w	d4,d1
				bge		nodrawlineGOUR
				cmp.w	d3,d1
				bge.s	noclipleftGOUR
				move.w	d3,d6
				subq	#1,d6
				sub.w	d1,d6
				move.w	d3,d1

noclipleftGOUR:
				cmp.w	d1,d2
				ble		nodrawlineGOUR

				move.w	d1,leftedge
				move.w	d2,rightedge

				move.l	a2,d2

				;asl.l	#2,d2
				;ext.l	d0
				;divs.l	d0,d2
				;move.l	d2,draw_Distance_l
				;asr.l	#7,d2
				;asr.l	#2,d2

				lsr.l	#4,d2
				mulu.w	OneOverN_vw(pc,d0.w*2),d2	;
				lsr.l	#8,d2

				move.l	d2,draw_Distance_l
				asr.l	#7,d2
				asr.l	#2,d2

; addq #5,d2
; add.w lighttype,d2

				moveq	#0,d1
				moveq	#0,d3
				move.w	LeftBrightTable_vw-LeftSideTable_vw(a4),d1
				add.w	d2,d1
				bge.s	.okbl
				moveq	#0,d1
.okbl:
; asr.w #1,d1
				cmp.w	#30,d1
				ble.s	.okdl
				move.w	#30,d1
.okdl:

				move.w	RightBrightTable_vw-LeftSideTable_vw(a4),d3
				add.w	d2,d3
				bge.s	.okbr
				moveq	#0,d3
.okbr:
; asr.w #1,d3
				cmp.w	#30,d3
				ble.s	.okdr
				move.w	#30,d3
.okdr:
				sub.w	d1,d3
				asl.w	#8,d1
				move.w	d1,leftbright
				swap	d3
				tst.l	d3
				bgt.s	.OKITSPOSALREADY
				neg.l	d3
				asr.l	#6,d3
				divs	d5,d3
				neg.w	d3
				bra.s	.OKNOWITSNEG

.OKITSPOSALREADY
				asr.l	#6,d3
				divs	d5,d3
.OKNOWITSNEG
				muls	d3,d6
				add.w	#256*4,d6
				asr.w	#2,d6
				clr.b	d6
				add.w	leftbright,d6
				bge.s	.oklbnn
				moveq	#0,d6
.oklbnn:
				move.w	d6,leftbright

				ext.l	d3
				asr.l	#2,d3
; swap d3
; asl.w #8,d3
				move.w	d3,brightspd

				move.l	a6,a3
				movem.l	d0/d7/a2/a4/a5/a6,-(a7)
				move.l	draw_Distance_l,d0
				move.l	Draw_TexturePalettePtr_l,a1
				add.l	#256*32,a1
				move.l	Draw_FloorTexturesPtr_l,a0
				adda.w	whichtile,a0
				jsr		pastfloorbright
				movem.l	(a7)+,d0/d7/a2/a4/a5/a6

nodrawlineGOUR:
				sub.w	#1,disttobot

				move.w	linedir(pc),d3
				adda.w	d3,a6
; ext.l d3
; sub.l d3,REFPTR
				move.w	tonextline,d3
				add.w	d3,a4
				asr.w	#1,d3
				add.w	d3,d0
				subq	#1,d7
				bgt		dofloorGOUR

predontdrawfloorGOUR:
				move.l	(a7)+,a0

dontdrawfloorGOUR:
				rts

REFPTR:			dc.l	0


; Gouraud floor line drawing

dofloornoclipGOUR:
; move.w (a2)+,d0
				move.w	RightSideTable_vw-LeftSideTable_vw(a4),d2
				addq	#1,d2
				move.w	(a4),d1
				move.w	d1,leftedge
				move.w	d2,rightedge

				sub.w	d1,d2

				move.l	a2,d6

;				asl.l	#2,d6
;				ext.l	d0
;				divs.l	d0,d6

				asr.l	#4,d6
				mulu.w	OneOverN_vw(pc,d0.w*2),d6
				asr.l	#8,d6	; from n << 20 down to n << 8

				move.l	d6,d5
				asr.l	#7,d5
				asr.l	#2,d5
; addq #5,d5
; add.w lighttype,d5

				moveq	#0,d1
				moveq	#0,d3
				move.w	LeftBrightTable_vw-LeftSideTable_vw(a4),d1
				add.w	d5,d1
				bge.s	.okbl
				moveq	#0,d1
.okbl:
; asr.w #1,d1
				cmp.w	#30,d1
				ble.s	.okdl
				move.w	#30,d1
.okdl:

				move.w	RightBrightTable_vw-LeftSideTable_vw(a4),d3
				add.w	d5,d3
				bge.s	.okbr
				moveq	#0,d3
.okbr:
; asr.w #1,d3
				cmp.w	#30,d3
				ble.s	.okdr
				move.w	#30,d3
.okdr:

				sub.w	d1,d3
				asl.w	#8,d1
				move.w	d1,leftbright
				swap	d3
				ext.l	d2
				divs.l	d2,d3
				asr.l	#8,d3
				move.w	d3,brightspd

				move.l	a6,a3
				movem.l	d0/d7/a2/a4/a5/a6,-(a7)
				move.l	d6,d0
				move.l	d0,draw_Distance_l
				move.l	Draw_TexturePalettePtr_l,a1
				add.l	#256*32,a1
				move.l	Draw_FloorTexturesPtr_l,a0
				adda.w	whichtile,a0
				jsr		pastfloorbright
				movem.l	(a7)+,d0/d7/a2/a4/a5/a6
				sub.w	#1,disttobot

				move.w	linedir(pc),d3
				adda.w	d3,a6
; ext.l d3
; sub.l d3,REFPTR

				move.w	tonextline,d3
				add.w	d3,a4
				asr.w	#1,d3
				add.w	d3,d0
				subq	#1,d7
				bgt		dofloornoclipGOUR
				bra		predontdrawfloorGOUR

drawit:			dc.w	0

				align 4

***************************
* Right then, time for the floor
* routine...
* For test purposes, give it
* a3 = point to screen
* d0= z distance away
* and Vis_SinVal_w+Vis_CosVal_w must be set up.
***************************


tstwhich:		dc.w	0
whichtile:		dc.w	0
leftedge:		dc.w	0
rightedge:		dc.w	0

;rndpt:			dc.l	rndtab

draw_Distance_l:			dc.l	0

********************************************************************************
				; Draw one floor line
draw_FloorLine:
				move.l	Draw_FloorTexturesPtr_l,a0
				adda.w	whichtile,a0
				move.w	lighttype,d1
				move.l	d0,draw_Distance_l					; View2FloorDist*64 * 256 / firstline
				move.l	d0,d2					;
				********************
;* Old version
				asr.l	#2,d2
				asr.l	#8,d2					; View2FloorDist / 1024
				add.w	#5,d1					; add 5 to lighttype?!
				add.w	d2,d1					; clamp lighting on the line
				bge.s	.fixedbright

				moveq	#0,d1					; low clamp

.fixedbright:
				cmp.w	#28,d1
				ble.s	.smallbright

				move.w	#28,d1					; high clamp

.smallbright:
				move.l	Draw_TexturePalettePtr_l,a1
				add.l	#256*32,a1

				; todo - is this used?
				add.w	.floorbright(pc,d1.w*2),a1 ; adjust brightness of line
				bra		pastfloorbright

				align 4
.floorbright:
				dc.w	512*0
				dc.w	512*1
				dc.w	512*2
				dc.w	512*3
				dc.w	512*4
				dc.w	512*5
				dc.w	512*6
				dc.w	512*7
				dc.w	512*8
				dc.w	512*9
				dc.w	512*10
				dc.w	512*11
				dc.w	512*12
				dc.w	512*13
				dc.w	512*14
				dc.w	512*15
				dc.w	512*16
				dc.w	512*17
				dc.w	512*18
				dc.w	512*19
				dc.w	512*20
				dc.w	512*21
				dc.w	512*22
				dc.w	512*23
				dc.w	512*24
				dc.w	512*25
				dc.w	512*26
				dc.w	512*27
				dc.w	512*28
				dc.w	512*29
				dc.w	512*30
				dc.w	512*31

widthleft:		dc.w	0
scaleval:		dc.w	0
sxoff:			dc.l	0						; viewer position in floor texture space?
szoff:			dc.l	0
xoff34:			dc.w	0
zoff34:			dc.w	0
scosval:		dc.w	0
ssinval:		dc.w	0

			; Floor drawing
pastfloorbright:

				; these directly determine the texture gradients
				; as function of the player view direction
				; d0 = distance of line to viewer along Z axis
				move.l	d0,d1					; distance of line to viewer along Z axis
				muls	Vis_CosVal_w,d1				; cos * dist
				move.l	d0,d2
				muls	Vis_SinVal_w,d2				;
				neg.l	d2						; -sin * width
				asr.l	#2,d2
				asr.l	#2,d1

scaleprog:
				move.w	scaleval(pc),d3
				beq.s	.samescale
				bgt.s	.scaledown
				; scale up
				neg.w	d3
				asr.l	d3,d1
				asr.l	d3,d2
				bra.s	.samescale
.scaledown:
				asl.l	d3,d1					; cos * dist * scale	step size of line through texture at distance 'dist'
				asl.l	d3,d2					; -sin * dist * scale


				; view vector R * (-ViewDist*.75 , ViewDist)^T
				; I think the 0.75 related to the field of view
				; It is supposed to produce left left start coordinate
				; of the line in floor texture coordinates
.samescale
				move.l	d1,d3					; dist * cos * scale
				move.l	d3,d6					; dist * cos * scale
				move.l	d3,d5					; dist * cos * scale
				asr.l	#1,d6					; dist * cos * scale * 0.5
				add.l	d6,d3					; dist * cos * scale * 1.5
				asr.l	#1,d3					; dist * cos * scale * 0.75

				move.l	d2,d4					; -dist * sin * scale
				move.l	d4,d6					; -dist * sin * scale
				asr.l	#1,d6					; -dist * sin * scale * 0.5
				add.l	d4,d6					; -dist * sin * scale * 1.5
				asr.l	#1,d6					; -dist * sin * scale * 0.75

				add.l	d3,d4					; left t = (dist * cos * scale * 0.75) - (dist * sin * scale)
				neg.l	d4						; - start x

				sub.l	d6,d5					; left s= -1 * -1 * (dist * sin * scale * 0.75) + (dist * cos * scale)

				add.l	sxoff,d4				; d4/d5 is the texture starting position?
				add.l	szoff,d5

				tst.b	Vid_FullScreen_b
				beq.s	.nob

				moveq	#0,d6
				move.w	leftedge(pc),d6			; left edge of clipped floor line in screenspace
				beq.s	.nomultleftB

				; if the clipped left edge of the floor line is > 0,
				; need  to inset the start of the floorspace coordinate accordingly

				; 0xABADCAFE - Apply fullscreen multiplier (3/5)), approximating as 1229/2048
				muls	#1229,d6
				asr.l	#8,d6
				asr.l	#3,d6

				move.l	d1,a4					; save width * cos * scale
				move.l	d2,a5					; save width * sin * scale

				muls.l	d6,d1					; ds/dx  * left start
				asr.l	#7,d1					; sin/cos are << 15; this shifts it down to << 8
				add.l	d1,d4					; current floor line start texel s

				muls.l	d6,d2					; dt/dx * left start
				asr.l	#7,d2					; sin/cos are << 15; this shifts it down to << 8
				add.l	d2,d5					; current floor line start texel t

				move.l	a4,d1					; restore
				move.l	a5,d2

				move.w	leftedge(pc),d6

.nomultleftB:

				move.w	d4,startsmoothx
				move.w	d5,startsmoothz

				asr.l	#8,d4
				asl.l	#8,d5

				move.w	d4,d5

				; multiply floor space step ds/dx and dt/dx by Fullscreen multiplier
				asr.l	#6,d1					; don't shift by 7, but 6, to achieve 2/3
				asr.l	#6,d2

				; 0xABADCAFE - Apply fullscreen multiplier (uses 3/5 here)
				; Pipper's fullscreen: Scale factor is 192/320
				; Use quicker evaluation of 3/10, 77/256 => 0.30078125
				muls.l  #77,d1
				muls.l  #77,d2
				asr.l	#8,d1
				asr.l	#8,d2

				bra.s	doneallmult

.nob			;		smallscreen				left edge insetting
				moveq	#0,d6
				move.w	leftedge(pc),d6
				beq.s	nomultleft				; skip if at left screen edge already

				move.l	d1,a4					; save  width * cos * scale
				move.l	d2,a5					; save width * sin * scale

				muls.l	d6,d1					; left start * ds/dx
				asr.l	#7,d1
				add.l	d1,d4					; start texel x

				muls.l	d6,d2					; left start * dt/dx
				asr.l	#7,d2
				add.l	d2,d5					; start texel y

				move.l	a4,d1					; restore
				move.l	a5,d2					; restore

				move.w	leftedge(pc),d6

nomultleft:		;		final					start coordinate in floor texture space
				move.w	d4,startsmoothx
				move.w	d5,startsmoothz

				asr.l	#8,d4					;  s / 256
				asl.l	#8,d5					;  t * 256

				move.w	d4,d5					; move s into lower half of t

				asr.l	#7,d1					; ds/dx / 128 = ds/dx << 8
				asr.l	#7,d2					; dt/dx / 128 = dt/dx << 8
; divs.l #3,d1
; divs.l #3,d2

doneallmult:

				move.w	d1,a4					; save ds/dx and dt/dx
				move.w	d2,a5

				asl.l	#8,d2					;  dt/dx << 16
; and.w #%0011111100000000,d2
				asr.l	#8,d1					;  ds/dx
				move.w	d1,d2					;  move ds/dx into lower half of dt/dx

				move.l	#$3fff3fff,d1
				and.l	d1,d5

				;tst.b	Vid_DoubleWidth_b
				;beq.s	.nodoub
				bra.s	.nodoub

				; old doublewidth rendering
				and.b	#$fe,d6					; remove LSB in lower 8 bit, only draw even columns?

				move.w	d6,a2
				moveq	#0,d0
				move.w	rightedge(pc),d3
				lea		(a3,a2.w),a3
				move.w	d3,d7
				sub.w	a2,d7
				asr.w	#1,d7
				move.w	startsmoothx,d3

				tst.b	draw_UseWater_b
				bne		draw_WaterSurfaceDouble
		; tst.b draw_UseGouraudFlats_b
				bra		gouraudfloorDOUB

.nodoub:
				move.w	d6,a2					; left start X
				moveq	#0,d0
				move.w	rightedge(pc),d3
				lea		(a3,a2.w),a3			; start adress in screen
				move.w	d3,d7
				sub.w	a2,d7					; end X - start X : line width

intofirststrip:
allintofirst:

				move.w	startsmoothx,d3

tstwat:

				tst.b	draw_UseWater_b
				bne		draw_WaterSurface
; tst.b draw_UseGouraudFlats_b					; FIXME: this effectively disables bumpmapped floors...
												; opportunity to reenable and see what happens

				bra		draw_GoraudFloor

ordinary:
				moveq	#0,d0

				dbra	d7,acrossscrn
				rts

draw_UseGouraudFlats_b:		dc.w	0

				align 4
backbefore:
				and.w	d1,d5
				move.b	(a0,d5.w*4),d0
				add.w	a4,d3
				addx.l	d6,d5
				move.w	(a1,d0.w*2),(a3)
				addq	#4,a3
				dbcs	d7,acrossscrn
				dbcc	d7,backbefore
				bra.s	past1

acrossscrn:
				and.w	d1,d5
				move.b	(a0,d5.w*4),d0
				add.w	a4,d3
				addx.l	d2,d5
				move.w	(a1,d0.w*2),(a3)
				addq	#4,a3
				dbcs	d7,acrossscrn
				dbcc	d7,backbefore
past1:
				bcc.s	gotoacross

				move.w	d4,d7
				bne.s	.notdoneyet
				rts

.notdoneyet:
				cmp.w	#32,d7
				ble.s	.notoowide
				move.w	#32,d7
.notoowide:
				sub.w	d7,d4
				addq	#4,a3

				dbra	d7,backbefore
				rts


gotoacross:
				move.w	d4,d7
				bne.s	.notdoneyet
				rts
.notdoneyet:

				cmp.w	#32,d7
				ble.s	.notoowide
				move.w	#32,d7
.notoowide
				sub.w	d7,d4
				addq	#4,a3

				dbra	d7,acrossscrn
				rts

				align 4
leftbright:		dc.l  0
brightspd:		dc.l  0

				IFD OPT060
				include "modules/draw/draw_floor_060.s"
				ELSE
				include "modules/draw/draw_floor.s"
				ENDC

				align 4

gouraudfloorDOUB:
				move.w	leftbright,d0
				move.l	d1,d4
				move.w	brightspd,d1
				add.w	d1,d1
				add.l	d2,d2

				move.w	d7,d3
				asr.w	#1,d7
				btst	#0,d3
				beq.s	.nosingle1
				move.w	d5,d3
				move.l	d5,d6
				lsr.w	#8,d3
				swap	d6
				move.b	d3,d6
				move.w	d0,d3
				move.b	(a0,d6.w*4),d3
				add.w	d1,d0
				add.l	d2,d5
				and.l	d4,d5
				move.w	(a1,d3.w),(a3)+

.nosingle1:
				move.w	d7,d3
				asr.w	#1,d7
				btst	#0,d3
				beq.s	.nosingle2
				move.w	d5,d3
				move.l	d5,d6
				lsr.w	#8,d3
				swap	d6
				move.b	d3,d6
				move.w	d0,d3
				move.b	(a0,d6.w*4),d3
				add.w	d1,d0
				add.l	d2,d5
				and.l	d4,d5
				move.l	d5,d6
				swap	d6
				move.w	(a1,d3.w),(a3)+
				move.w	d5,d3
				lsr.w	#8,d3
				move.b	d3,d6
				move.w	d0,d3
				move.b	(a0,d6.w*4),d3
				add.w	d1,d0
				add.l	d2,d5
				and.l	d4,d5
				move.w	(a1,d3.w),(a3)+

.nosingle2:
				move.l	d5,d6
				swap	d6
				dbra	d7,acrossscrngourD
				rts

				align 4
acrossscrngourD:
				move.w	d5,d3
				lsr.w	#8,d3
				move.b	d3,d6
				move.w	d0,d3
				move.b	(a0,d6.w*4),d3
				add.w	d1,d0
				add.l	d2,d5
				and.l	d4,d5
				move.l	d5,d6
				swap	d6
				move.w	(a1,d3.w),(a3)+
				move.w	d5,d3
				lsr.w	#8,d3
				move.b	d3,d6
				move.w	d0,d3
				move.b	(a0,d6.w*4),d3
				add.w	d1,d0
				add.l	d2,d5
				and.l	d4,d5
				move.l	d5,d6
				swap	d6
				move.w	(a1,d3.w),(a3)+
				move.w	d5,d3
				lsr.w	#8,d3
				move.b	d3,d6
				move.w	d0,d3
				move.b	(a0,d6.w*4),d3
				add.w	d1,d0
				add.l	d2,d5
				and.l	d4,d5
				move.l	d5,d6
				swap	d6
				move.w	(a1,d3.w),(a3)+
				move.w	d5,d3
				lsr.w	#8,d3
				move.b	d3,d6
				move.w	d0,d3
				move.b	(a0,d6.w*4),d3
				add.w	d1,d0
				add.l	d2,d5
				and.l	d4,d5
				move.l	d5,d6
				swap	d6
				move.w	(a1,d3.w),(a3)+
				dbra	d7,acrossscrngourD
				rts

				move.w	d4,d7
				bne.s	.notdoneyet
				move.l	d0,leftbright

				rts

.notdoneyet:
				cmp.w	#32,d7
				ble.s	.notoowide
				move.w	#32,d7
.notoowide
				sub.w	d7,d4
				addq	#4,a3

; dbra d7,backbeforegour
				rts

				align 4
draw_LastWaterFramePtr_l:
				dc.l	draw_WaterFramePtrs_vl

draw_WaterFramePtrs_vl:
				dc.l	draw_WaterFrames_vb
				dc.l	draw_WaterFrames_vb+2
				dc.l	draw_WaterFrames_vb+256
				dc.l	draw_WaterFrames_vb+256+2
				dc.l	draw_WaterFrames_vb+512
				dc.l	draw_WaterFrames_vb+512+2
				dc.l	draw_WaterFrames_vb+768
				dc.l	draw_WaterFrames_vb+768+2
draw_EndWaterFramePtrs_l:

draw_WaterFramePtr_l:		dc.l	draw_WaterFrames_vb


wateroff:		dc.l	0

wtan:			dc.w	0

draw_WaterSurface:
				move.l	d1,d4

				add.l	wateroff,d5

				move.l	Draw_TexturePalettePtr_l,a1
				add.l	#256*16,a1 ; halfway into the glare shade table
				move.l	draw_Distance_l,d0

;				asr.l	#2,d0 ; 0xABADCAFE - this seems to affect the opacity
				;clr.b	d0

				and.l	#$3f00,d0

				add.w	d0,d0
				cmp.w	#5*512,d0
				blt.s	.notoowater

				move.w	#5*512,d0

.notoowater:
				adda.w	d0,a1
				move.l	draw_Distance_l,d0
				asl.w	#7,d0
				add.w	wtan,d0
				AMOD_I	d0
				move.l	#SinCosTable_vw,a0
				move.w	(a0,d0.w),d0
				ext.l	d0
				move.l	draw_Distance_l,d3
				add.w	#300,d3
				divs	d3,d0
				asr.w	#5,d0
				addq	#4,d0
				cmp.w	disttobot,d0
				blt.s	oknotoffbototot
				move.w	disttobot,d0
				subq	#1,d0

oknotoffbototot:

; move.w draw_Distance_l,d3
; asr.w #7,d3
; add.w d3,d0

				tst.b	Vid_DoubleHeight_b
				beq.s	.nodoub
				and.b	#$fe,d0
.nodoub:

				muls	#SCREEN_WIDTH,d0
				tst.w	above
				beq.s	nonnnnneg
				neg.l	d0

nonnnnneg:

				move.l	d0,a6
				move.l	draw_WaterFramePtr_l,a0
				move.w	startsmoothx,d3
				dbra	d7,acrossscrnw
				rts

backbeforew:
				and.w	d1,d5
				move.w	(a0,d5.w*4),d0
				add.w	d0,d0
				move.b	(a3,a6.w),d0
				move.b	(a1,d0.w),(a3)+
				add.w	a4,d3
				addx.l	d6,d5
				dbcs	d7,acrossscrnw
				dbcc	d7,backbeforew
				rts

acrossscrnw:
				move.w	d5,d3
				move.l	d5,d6
				lsr.w	#8,d3
				swap	d6
				move.b	d3,d6
				move.w	(a0,d6.w*4),d0
				add.w	d0,d0
				add.l	d2,d5
				move.b	(a3,a6.w),d0
				and.l	d4,d5
				move.b	(a1,d0.w),(a3)+
				dbra	d7,acrossscrnw
				rts


draw_WaterSurfaceDouble:
				move.l	d1,d4
				add.l	wateroff,d5
				move.l	Draw_TexturePalettePtr_l,a1
				add.l	#256*16,a1
				move.l	draw_Distance_l,d0
				asr.l	#2,d0
				clr.b	d0

				add.w	d0,d0
				cmp.w	#9*512,d0
				blt.s	.notoowater
				move.w	#9*512,d0
.notoowater:

				adda.w	d0,a1

				move.l	draw_Distance_l,d0
				asl.w	#7,d0
				add.w	wtan,d0
				AMOD_I	d0
				move.l	#SinCosTable_vw,a0
				move.w	(a0,d0.w),d0
				ext.l	d0

				move.l	draw_Distance_l,d3
				add.w	#300,d3
				divs	d3,d0
				asr.w	#5,d0
				addq	#4,d0
				cmp.w	disttobot,d0
				blt.s	.oknotoffbototot

				move.w	disttobot,d0
				subq	#1,d0

.oknotoffbototot

; move.w draw_Distance_l,d3
; asr.w #7,d3
; add.w d3,d0

				tst.b	Vid_DoubleHeight_b
				beq.s	.nodoub
				and.b	#$fe,d0
.nodoub:

				muls	#SCREEN_WIDTH,d0
				tst.w	above
				beq.s	.nonnnnneg
				neg.l	d0

.nonnnnneg:
				move.l	d0,a6
				move.l	draw_WaterFramePtr_l,a0
				add.l	d2,d2
				move.w	startsmoothx,d3
				dbra	d7,acrossscrnwD
				rts


acrossscrnwD:
				move.w	d5,d3
				move.l	d5,d6
				lsr.w	#8,d3
				swap	d6
				move.b	d3,d6
				move.w	(a0,d6.w*4),d0
				add.w	d0,d0
				add.l	d2,d5
				move.b	(a3,a6.w),d0
				and.l	d4,d5
				move.w	(a1,d0.w),(a3)+
				dbra	d7,acrossscrnwD
				rts


draw_UseWater_b:		dc.w	0
				dc.w	0
startsmoothx:	dc.w	0
				dc.w	0
startsmoothz:	dc.w	0

********************************
*
				include	"objdrawhires.s"
*
********************************

numframes:
				dc.w	0

alframe:		dc.l	0

alan:
				dcb.l	8,0
				dcb.l	8,1
				dcb.l	8,2
				dcb.l	8,3
endalan:

alanptr:		dc.l	alan

Time2:			dc.l	0
dispco:
				dc.w	0


; todo - this is only used from the menu code
key_readkey:
				moveq	#0,d0
				move.b	lastpressed,d0
				move.b	#0,lastpressed
				rts

_key_interrupt::
key_interrupt:
;		movem.l	d0-d7/a0-a6,-(sp)

;		move.w	INTREQR,d0
;		btst	#3,d0
;		beq	.not_key

				move.b	$bfdd00,d0
				btst	#0,d0
				bne		.key_cont
;		move.b	$bfed01,d0
;		btst	#0,d0
;		bne	.key_cont

;		btst	#3,d0
;		beq	.key_cont

				move.b	$bfec01,d0
				clr.b	$bfec01

				tst.b	d0
				beq		.key_cont

;		bset	#6,$bfee01
;		move.b	#$f0,$bfe401
;		move.b	#$00,$bfe501
;		bset	#0,$bfee01


				not.b	d0
				ror.b	#1,d0
				lea.l	KeyMap_vb,a0
				tst.b	d0
				bmi.b	.key_up
				and.w	#$7f,d0
;		add.w	#1,d0
				move.b	#$ff,(a0,d0.w)
				move.b	d0,lastpressed

				bra.b	.key_cont2
.key_up:
				and.w	#$7f,d0
;		add.w	#1,d0
				move.b	#$00,(a0,d0.w)

.key_cont2
;		btst	#0,$bfed01
;		beq	.key_cont2
;		move.b	#%00000000,$bfee01
;		move.b	#%10001000,$bfed01

;alt keys should not be independent so overlay ralt on lalt


.key_cont

;		move.w	#$0008,INTREQ
.not_key:		;lea.l	$dff000,a5

;		lea.l	_keypressed(pc),a0
;		move.b	101(a0),d0	;read LALT
;		or.b	102(a0),d0	;blend it with RALT
;		move.b	d0,127(a0)	;save in combined position

;		movem.l	(sp)+,d0-d7/a0-a6
				move.w	#0,d0
				tst.w	d0

				rts

lastpressed:	dc.b	0
;KInt_CCode:		ds.b	1 ; unused ?
;KInt_Askey:		ds.b	1 ; unused ?
;KInt_OCode:		ds.w	1 ; unused ?
;SpaceTapped:	dc.b	0 ; unused ?
				even

				include	"plr1control.s"
				include	"plr2control.s"

;prot7: dc.w 0

GOTTOSEND:		dc.w	0

COUNTER:		dc.w	0
COUNTER2:		dc.w	0
COUNTSPACE:		ds.b	160

_Vid_VBLCount_l::
Vid_VBLCount_l:		dc.l	0
Vid_VBLCountLast_l:	dc.l	0

OtherInter:
				move.w	#$0010,$dff000+intreq

				SAVEREGS

				bra		justshake

				align	4

; Main VBlank interrupt
_VBlankInterrupt::
VBlankInterrupt:
				addq.l	#1,counter
				addq.l	#1,main_counter
				addq.l	#1,Vid_VBLCount_l
				subq.w	#1,Anim_Timer_w

				tst.l	timer					; used by menu system as delay
				beq.s	.nodec
				subq.l	#1,timer
.nodec:

				tst.l	button				; used by menu system as delay
				beq.s	.nodec1
				subq.l	#1,button
.nodec1:
				tst.l	button1				; used by menu system as delay
				beq.s	.nodec2
				subq.l	#1,button1
.nodec2:
				SAVEREGS
				bsr.s	.routine

				move.l	main_vblint,d0
				beq.s	.noint
				move.l	d0,a0
				jsr		(a0)
.noint:
				GETREGS
				lea		_custom,a0				; place custom base into a0 (See autodocs for AddIntServer)
				moveq	#0,d0					; VERTB interrupt needs to return Z flag set

				rts
.routine
;FIXME:  Wait, does the whole game run as part of the VBLank (formerly copper interrupt)?
				tst.b	Game_Running_b
				bne		dosomething

				SAVEREGS

				bra		JUSTSOUNDS

				moveq	#0,d0					; VERTB interrupt needs to return Z flag set
				rts

tabheld:		dc.w	0

thistime:		dc.w	0

DOALLANIMS:
				subq.b	#1,thistime
				ble.s	.okdosome
				rts

.okdosome:
				move.b	#5,thistime
				move.l	#ObjectWorkspace_vl,a5
				move.l	Lvl_ObjectDataPtr_l,a0

Objectloop2:
				tst.w	(a0)
				blt		doneallobj2
				move.w	ObjT_ZoneID_w(a0),d0
				blt		doneobj2

				move.w	d0,EntT_ZoneID_w(a0)
				tst.b	ShotT_Worry_b(a0)
				beq.s	doneobj2

				move.b	ObjT_TypeID_b(a0),d0
				cmp.b	#1,d0
				blt		JUMPALIENANIM
; beq JUMPOBJECTANIM
; cmp.b #2,d0
; beq JUMPBULLET

doneobj2:
				adda.w	#ENT_NEXT,a0
				addq	#8,a5
				bra		Objectloop2

doneallobj2:
				rts

JUMPALIENANIM:

				moveq	#0,d0
				move.b	EntT_WhichAnim_b(a0),d0
; 0=walking
; 1=attacking
; 2=getting hit
; 3=dying

				cmp.b	#1,d0
				blt.s	ALWALK
				beq.s	ALATTACK

				cmp.b	#3,d0
				blt		ALGETHIT
				beq		ALDIE

				bra		doneobj2

ALDIE:
				move.l	#10,d0
				bra		intowalk

ALGETHIT:
				move.l	#9,d0
				bra		intowalk

ALATTACK:
				move.l	#8,d0
				bra		intowalk

AUXOBJ:			dc.w	0

ALWALK:

				moveq	#0,d0
intowalk:

NOSIDES2:
				move.b	d0,2(a5)
				move.l	GLF_DatabasePtr_l,a6

				add.l	#GLFT_AlienAnims_l,a6

				moveq	#0,d1
				move.b	EntT_Type_b(a0),d1
				move.w	.valtables+4(pc,d1.w*8),d1
; muls #A_AnimLen,d1
				add.l	d1,a6

; move.l AlienAnimPtr_l,a6

; muls #A_OptLen,d0
				move.w	.valtables+2(pc,d0.w*8),d0
				add.w	d0,a6

				move.w	EntT_Timer2_w(a0),d1
				move.w	d1,d2
; muls #A_FrameLen,d1
				move.w	.valtables(pc,d1.w*8),d1

				moveq	#0,d0
				move.b	5(a6,d1.w),d0
				beq.s	.nosoundmake

				SAVEREGS

				subq	#1,d0
				move.w	d0,Aud_SampleNum_w
				clr.b	notifplaying
				move.w	(a0),IDNUM
				move.w	#80,Aud_NoiseVol_w
				move.l	#ObjRotated_vl,a1
				move.w	(a0),d0
				lea		(a1,d0.w*8),a1
				move.l	(a1),Aud_NoiseX_w
				jsr		MakeSomeNoise

				GETREGS

.nosoundmake:
				move.b	6(a6,d1.w),d0
				beq.s	.noaction
				add.b	#1,(a5)
				move.b	d2,1(a5)

.noaction:
				addq	#1,d2
				moveq	#0,d0
				move.b	7(a6,d1.w),d0
				beq		.nospecial

				bra		.special

.valtables:
val				SET		0
				REPT	20
				dc.w	A_FrameLen*val,A_OptLen*val
				dc.w	A_AnimLen*val,0
val				SET		val+1
				ENDR

.special:
				move.b	d0,d3
				and.w	#63,d3
				lsr.w	#6,d0
				cmp.w	#2,d0
				blt.s	.storeval

				beq.s	.randval

				sub.b	#1,4(a5)
				beq.s	.nospecial

				move.w	d3,d2
				bra.s	.nospecial

.randval:
				jsr		GetRand

				divs	d3,d0
				swap	d0
				move.w	d0,d3

.storeval:
				move.b	d3,4(a5)

.nospecial:

; move.w d2,d3
				move.w	.valtables2(pc,d2.w*8),d3
; muls #A_FrameLen,d3
				tst.b	(a6,d3.w)
				bge.s	.noendanim

				st		3(a5)
				move.w	#0,d2

.noendanim:
				move.w	d2,EntT_Timer2_w(a0)

				bra		doneobj2

.valtables2:
val				SET		0
				REPT	20
				dc.w	A_FrameLen*val,A_OptLen*val
				dc.w	A_AnimLen*val,0
val				SET		val+1
				ENDR


JUMPOBJECTANIM:
				bra		doneobj2

timetodamage:	dc.w	0
SAVESAVE:		dc.w	0

dosomething:
				addq.w	#1,Anim_FramesToDraw_w

				SAVEREGS

				bsr		DOALLANIMS

				sub.w	#1,timetodamage
				bgt		.skip_damage

				move.w	#100,timetodamage

				move.l	Plr1_ZonePtr_l,a0
				move.l	ZoneT_Water_l(a0),d2      ; Water depth in d2
				move.w	ZoneT_FloorNoise_w(a0),d0
				tst.b	Plr1_StoodInTop_b
				beq.s	.okinbot
				move.w	ZoneT_UpperFloorNoise_w(a0),d0

.okinbot:
				; Issue #1 - Check we are on the floor or swimming before applying any floor damage.
				cmp.l	Plr1_SnapYOff_l,d2
				blt.b   .in_toxic_liquid1

				; Player not in liquid, check if on floor.
				move.l	Plr1_SnapTYOff_l,d1
				cmp.l	Plr1_SnapYOff_l,d1
				bgt.b	.not_on_floor1

.in_toxic_liquid1:
				move.l	GLF_DatabasePtr_l,a0
				add.l	#GLFT_FloorData_l,a0
				move.w	(a0,d0.w*4),d0			; floor damage.
				move.l	Plr1_ObjectPtr_l,a0
				add.b	d0,EntT_DamageTaken_b(a0)

.not_on_floor1:
				move.l	Plr2_ZonePtr_l,a0
				move.l	ZoneT_Water_l(a0),d2      ; Water depth in d2
				move.w	ZoneT_FloorNoise_w(a0),d0
				tst.b	Plr2_StoodInTop_b
				beq.s	.okinbot2
				move.w	ZoneT_UpperFloorNoise_w(a0),d0

.okinbot2:
				; Issue #1 - Check we are on the floor or swimming before applying any floor damage.
				cmp.l	Plr2_SnapYOff_l,d2
				blt.b   .in_toxic_liquid2

				; Player not in liquid, check if on floor.
				move.l	Plr2_SnapTYOff_l,d1
				cmp.l	Plr2_SnapYOff_l,d1
				bgt.b	.not_on_floor2

.in_toxic_liquid2:
				move.l	GLF_DatabasePtr_l,a0
				add.l	#GLFT_FloorData_l,a0
				move.w	(a0,d0.w*4),d0			; floor damage.
				move.l	Plr2_ObjectPtr_l,a0
				add.b	d0,EntT_DamageTaken_b(a0)

.not_on_floor2:
.skip_damage:
				; 0xABADCAFE - this seems like a weird place to be testing the keyboard?

				move.l	#KeyMap_vb,a5

				tst.b	RAWKEY_F3(a5)					;f3
				beq		notogglesound

				tst.b	lasttogsound
				bne		notogglesound2

				st		lasttogsound

				move.w	TOPPOPT,d0
				addq	#1,d0
				and.w	#3,d0
				move.w	d0,TOPPOPT
				move.b	STEROPT(pc,d0.w*2),Aud_Stereo_b


				move.b	STEROPT+1(pc,d0.w*2),d1
				muls	#OPTS_MESSAGE_LENGTH,d0
				add.l	#Game_SoundOptionsText_vb,d0
				move.l	d0,a0
				move.w	#OPTS_MESSAGE_LENGTH|MSG_TAG_OPTIONS,d0
				CALLC	Msg_PushLine

				move.b	d1,Prefsfile+1

				bra		pastster

STEROPT:
				dc.b	0,4
				dc.b	$FF,4
				dc.b	0,8
				dc.b	$ff,8

lasttogsound:	dc.w	0

OLDLTOG:		dc.w	0

pastster:
				cmp.b	#'4',d1
				seq		CHANNELDATA+8
				seq		CHANNELDATA+12
				seq		CHANNELDATA+24
				seq		CHANNELDATA+28

				;* Mt_init *********************
				st		CHANNELDATA+8
				st		CHANNELDATA
				;*******************************

				move.w	#$f,$dff000+dmacon
				move.l	#Aud_Null1_vw,$dff0a0
				move.w	#100,$dff0a4 ; size
				move.w	#443,$dff0a6 ; period
				move.w	#63,$dff0a8  ; volume

				move.l	#Aud_Null2_vw,$dff0b0
				move.w	#100,$dff0b4 ; size
				move.w	#443,$dff0b6 ; period
				move.w	#63,$dff0b8  ; volume

				move.l	#Aud_Null4_vw,$dff0c0
				move.w	#100,$dff0c4 ; size
				move.w	#443,$dff0c6 ; period
				move.w	#63,$dff0c8  ; volume

				move.l	#Aud_Null3_vw,$dff0d0
				move.w	#100,$dff0d4 ; size
				move.w	#443,$dff0d6 ; period
				move.w	#63,$dff0d8  ; volume

				move.l	#Aud_EmptyBuffer_vl,pos0LEFT
				move.l	#Aud_EmptyBuffer_vl,pos1LEFT
				move.l	#Aud_EmptyBuffer_vl,pos2LEFT
				move.l	#Aud_EmptyBuffer_vl,pos3LEFT
				move.l	#Aud_EmptyBuffer_vl,pos0RIGHT
				move.l	#Aud_EmptyBuffer_vl,pos1RIGHT
				move.l	#Aud_EmptyBuffer_vl,pos2RIGHT
				move.l	#Aud_EmptyBuffer_vl,pos3RIGHT
				move.l	#Aud_EmptyBufferEnd,Samp0endLEFT
				move.l	#Aud_EmptyBufferEnd,Samp1endLEFT
				move.l	#Aud_EmptyBufferEnd,Samp2endLEFT
				move.l	#Aud_EmptyBufferEnd,Samp3endLEFT
				move.l	#Aud_EmptyBufferEnd,Samp0endRIGHT
				move.l	#Aud_EmptyBufferEnd,Samp1endRIGHT
				move.l	#Aud_EmptyBufferEnd,Samp2endRIGHT
				move.l	#Aud_EmptyBufferEnd,Samp3endRIGHT

				move.w	#10,d3
				; See if byt got transmitted overserial

				bra		notogglesound2

notogglesound:
				clr.b	lasttogsound

notogglesound2:
				tst.b	RAWKEY_F4(a5)
				beq		nolighttoggle

				tst.b	OLDLTOG
				bne		nolighttoggle2

				st		OLDLTOG
				move.l	#Game_LightingOptionsText_vb,d0
				not.b	Anim_LightingEnabled_b
				beq.s	.noon
				add.l	#OPTS_MESSAGE_LENGTH,d0
.noon:
				bra		pastlighttext


OLDRET:				dc.w	0
Plr_OldCentre_b:	dc.w	0
OLDGOOD:			dc.w	0


pastlighttext:
				move.l	d0,a0
				move.w	#OPTS_MESSAGE_LENGTH|MSG_TAG_OPTIONS,d0
				CALLC	Msg_PushLine

				bra		nolighttoggle2

nolighttoggle:
				clr.b	OLDLTOG

nolighttoggle2:
				tst.b	draw_RenderMap_b
				bne.s	.no_vid_adjust

				bsr		Vid_CheckSettingsAdjust

.no_vid_adjust:
				tst.b	RAWKEY_F6(a5)
				beq.s	.nogood

				tst.b	OLDGOOD
				bne.s	.nogood2

				st		OLDGOOD
				move.l	#Game_DrawHighQualityText_vb,d0
				not.b	Draw_GoodRender_b
				bne.s	.okgood

				move.l	#Game_DrawLowQualityText_vb,d0

.okgood:
				move.l	d0,a0
				move.w	#OPTS_MESSAGE_LENGTH|MSG_TAG_OPTIONS,d0
				CALLC	Msg_PushLine

				bra		.nogood2

.nogood:
				clr.b	OLDGOOD

.nogood2:
				tst.b	RAWKEY_TAB(a5)
				bne.s	.tabprsd
				clr.b	tabheld
				bra.s	.noswitch

.tabprsd:
				tst.b	tabheld
				bne.s	.noswitch

				not.b	MAPON
				st		tabheld

.noswitch:
				; Map scrolling
				tst.b	RAWKEY_NUM_8(a5) ; Up
				sne		d0
				tst.b	RAWKEY_NUM_2(a5) ; Down
				sne		d1
				tst.b	RAWKEY_NUM_4(a5) ; Left
				sne		d2
				tst.b	RAWKEY_NUM_6(a5) ; Right
				sne		d3

				tst.b	RAWKEY_NUM_7(a5) ; Up Left
				sne		d4
				tst.b	RAWKEY_NUM_9(a5) ; Up Right
				sne		d5
				tst.b	RAWKEY_NUM_1(a5) ; Down Left
				sne		d6
				tst.b	RAWKEY_NUM_3(a5) ; Down Right
				sne		d7

				or.b	d4,d0
				or.b	d5,d0	; d0 is set if we need to scroll up
				or.b	d6,d1
				or.b	d7,d1   ; d1 is set if we need to scroll down
				or.b	d4,d2
				or.b	d6,d2   ; d2 is set if we need to scroll left
				or.b	d7,d3
				or.b	d5,d3   ; d3 is set if we need to scroll right

				move.w	Draw_MapZoomLevel_w,d4
				add.w	#2,d4
				clr.l	d5
				bset	d4,d5

				tst.b	d0
				beq.s	.nomapup

				sub.w	d5,draw_MapZOffset_w

.nomapup:
				tst.b	d1
				beq.s	.nomapdown

				add.w	d5,draw_MapZOffset_w

.nomapdown:
				tst.b	d2
				beq.s	.nomapleft

				add.w	d5,draw_MapXOffset_w

.nomapleft:
				tst.b	d3
				beq.s	.nomapright

				sub.w	d5,draw_MapXOffset_w

.nomapright:
				tst.b	RAWKEY_NUM_5(a5)
				beq.s	.nomapcentre

				move.w	#0,draw_MapXOffset_w
				move.w	#0,draw_MapZOffset_w

.nomapcentre:
justshake:
				jsr		mt_music

				bra		dontshowtime

				tst.b	oktodisplay
				beq		dontshowtime
				clr.b	oktodisplay
				subq.w	#1,dispco
				bgt		dontshowtime
				move.w	#10,dispco

				move.l	#TimerScr+10,a0
				move.l	TimeCount,d0
				bge.s	timenotneg
				move.l	#1111*256,d0
timenotneg:
				asr.l	#8,d0
				move.l	#draw_Digits_vb,a1
				move.w	#7,d2
digitlop:
				divs	#10,d0
				swap	d0
				lea		(a1,d0.w*8),a2
				move.b	(a2)+,(a0)
				move.b	(a2)+,24(a0)
				move.b	(a2)+,24*2(a0)
				move.b	(a2)+,24*3(a0)
				move.b	(a2)+,24*4(a0)
				move.b	(a2)+,24*5(a0)
				move.b	(a2)+,24*6(a0)
				move.b	(a2)+,24*7(a0)
				subq	#1,a0
				swap	d0
				ext.l	d0
				dbra	d2,digitlop

				move.l	#TimerScr+10+24*10,a0
				move.l	NumTimes,d0
				move.l	#draw_Digits_vb,a1
				move.w	#3,d2
digitlop2
				divs	#10,d0
				swap	d0
				lea		(a1,d0.w*8),a2
				move.b	(a2)+,(a0)
				move.b	(a2)+,24(a0)
				move.b	(a2)+,24*2(a0)
				move.b	(a2)+,24*3(a0)
				move.b	(a2)+,24*4(a0)
				move.b	(a2)+,24*5(a0)
				move.b	(a2)+,24*6(a0)
				move.b	(a2)+,24*7(a0)
				subq	#1,a0
				swap	d0
				ext.l	d0
				dbra	d2,digitlop2

				move.l	#TimerScr+10+24*20,a0
				moveq	#0,d0
				move.w	Anim_FramesToDraw_w,d0
				move.l	#draw_Digits_vb,a1
				move.w	#2,d2
digitlop3
				divs	#10,d0
				swap	d0
				lea		(a1,d0.w*8),a2
				move.b	(a2)+,(a0)
				move.b	(a2)+,24(a0)
				move.b	(a2)+,24*2(a0)
				move.b	(a2)+,24*3(a0)
				move.b	(a2)+,24*4(a0)
				move.b	(a2)+,24*5(a0)
				move.b	(a2)+,24*6(a0)
				move.b	(a2)+,24*7(a0)
				subq	#1,a0
				swap	d0
				ext.l	d0
				dbra	d2,digitlop3

dontshowtime:
				move.l	alanptr,a0
				move.l	(a0)+,alframe
				cmp.l	#endalan,a0
				blt.s	nostartalan
				move.l	#alan,a0
nostartalan:
				move.l	a0,alanptr


				tst.b	READCONTROLS
				beq		nocontrols

				cmp.b	#PLR_SLAVE,Plr_MultiplayerType_b
				beq		control2

				tst.w	Plr1_Health_w
				bgt		.propercontrol

				move.l	#7*2116,hitcol
				move.l	Plr1_ObjectPtr_l,a0

				FREE_OBJ_2	a0,ENT_NEXT_2

				clr.b	Plr1_Fire_b
				clr.b	Plr1_Clicked_b
				move.w	#0,Plr_AddToBobble_w
				move.l	#PLR_CROUCH_HEIGHT,Plr1_SnapHeight_l
				move.w	View_LookMax_w,d0					; Is this related to render buffer height
				move.w	d0,STOPOFFSET
				neg.w	d0
				add.w	TOTHEMIDDLE,d0
				move.w	d0,SMIDDLEY
				muls	#SCREEN_WIDTH,d0
				move.l	d0,SBIGMIDDLEY
				jsr		Plr1_Fall

				move.l	Plr1_SnapXSpdVal_l,d6
				move.l	Plr1_SnapZSpdVal_l,d7

				tst.b	Plr_Decelerate_b
				beq.s	.skip_friction

				neg.l	d6
				ble.s	.nobug1
				asr.l	#3,d6
				add.l	#1,d6
				bra.s	.bug1
.nobug1
				asr.l	#3,d6
.bug1:

				neg.l	d7
				ble.s	.nobug2
				asr.l	#3,d7
				add.l	#1,d7
				bra.s	.bug2
.nobug2
				asr.l	#3,d7
.bug2:

				add.l	d6,Plr1_SnapXSpdVal_l
				add.l	d7,Plr1_SnapZSpdVal_l

.skip_friction:
				move.l	Plr1_SnapXSpdVal_l,d6
				move.l	Plr1_SnapZSpdVal_l,d7
				add.l	d6,Plr1_SnapXOff_l
				add.l	d7,Plr1_SnapZOff_l

				move.w	Plr1_SnapAngSpd_w,d3
				tst.b	Plr_Decelerate_b
				beq.s	.nofric
				asr.w	#2,d3
				bge.s	.nneg
				addq	#1,d3
.nneg:
.nofric:

				move.w	d3,Plr1_SnapAngSpd_w
				add.w	d3,Plr1_SnapAngPos_w
				add.w	d3,Plr1_SnapAngPos_w
				AMOD_A	Plr1_SnapAngPos_w

				bra		nocontrols

.propercontrol:

				tst.b	Plr1_Mouse_b
				beq.s	.plr1_no_mouse
				bsr		Plr1_MouseControl
.plr1_no_mouse:
				tst.b	Plr1_Keys_b
				beq.s	.plr1_no_keyboard
				bsr		Plr1_KeyboardControl
.plr1_no_keyboard:
; tst.b Plr1_Path_b
; beq.s PLR1_nopath
; bsr Plr1_FollowPath
;PLR1_nopath:
				tst.b	Plr1_Joystick_b
				beq.s	.plr1_no_joystick
				bsr		Plr1_JoystickControl
.plr1_no_joystick:
				bra		nocontrols

control2:
				tst.w	Plr2_Health_w
				bgt		.propercontrol

				move.l	#7*2116,hitcol
				move.l	Plr1_ObjectPtr_l,a0

				FREE_OBJ_2	a0,ENT_NEXT_2

				clr.b	Plr2_Fire_b
				move.w	#0,Plr_AddToBobble_w
				move.l	#PLR_CROUCH_HEIGHT,Plr2_SnapHeight_l
				move.w	View_LookMax_w,d0
				move.w	d0,STOPOFFSET
				neg.w	d0
				add.w	TOTHEMIDDLE,d0
				move.w	d0,SMIDDLEY
				muls	#SCREEN_WIDTH,d0
				move.l	d0,SBIGMIDDLEY

				jsr		Plr2_Fall

				move.l	Plr2_SnapXSpdVal_l,d6
				move.l	Plr2_SnapZSpdVal_l,d7

				tst.b	Plr_Decelerate_b
				beq.s	.skip_friction

				neg.l	d6
				ble.s	.nobug1

				asr.l	#3,d6
				add.l	#1,d6
				bra.s	.bug1

.nobug1:
				asr.l	#3,d6

.bug1:
				neg.l	d7
				ble.s	.nobug2

				asr.l	#3,d7
				add.l	#1,d7
				bra.s	.bug2

.nobug2:
				asr.l	#3,d7

.bug2:
				add.l	d6,Plr2_SnapXSpdVal_l
				add.l	d7,Plr2_SnapZSpdVal_l

.skip_friction:
				move.l	Plr2_SnapXSpdVal_l,d6
				move.l	Plr2_SnapZSpdVal_l,d7
				add.l	d6,Plr2_SnapXOff_l
				add.l	d7,Plr2_SnapZOff_l
				move.w	Plr2_SnapAngSpd_w,d3
				tst.b	Plr_Decelerate_b
				beq.s	.nofric

				asr.w	#2,d3
				bge.s	.nneg
				addq	#1,d3

.nneg:
.nofric:
				move.w	d3,Plr2_SnapAngSpd_w
				add.w	d3,Plr2_SnapAngPos_w
				add.w	d3,Plr2_SnapAngPos_w
				AMOD_A	Plr2_SnapAngPos_w
				bra.s	nocontrols

.propercontrol:
				tst.b	Plr2_Mouse_b
				beq.s	.plr2_no_mouse

				bsr		Plr2_MouseControl

.plr2_no_mouse:
				tst.b	Plr2_Keys_b
				beq.s	.plr2_no_keyboard

				bsr		Plr2_KeyboardControl

.plr2_no_keyboard:
; tst.b Plr2_Path_b
; beq.s .plr2_no_path
; bsr Plr1_FollowPath
;.plr2_no_path:
				tst.b	Plr2_Joystick_b
				beq.s	.plr2_no_joystick

				bsr		Plr2_JoystickControl

.plr2_no_joystick:

nocontrols:
				move.l	#$dff000,a6

				tst.b	dosounds
				beq.s	nomuckabout

				cmp.b	#'4',Prefsfile+1
				bne.s	nomuckabout

				move.w	#$0,d0
				tst.b	NoiseMade0LEFT
				beq.s	noturnoff0
				move.w	#1,d0
noturnoff0:
				tst.b	NoiseMade0RIGHT
				beq.s	noturnoff1
				or.w	#2,d0
noturnoff1:
				tst.b	NoiseMade1RIGHT
				beq.s	noturnoff2
				or.w	#4,d0
noturnoff2:
				tst.b	NoiseMade1LEFT
				beq.s	noturnoff3
				or.w	#8,d0
noturnoff3:

*********************
				and.w	#$fffe,d0
*********************

				move.w	d0,dmacon(a6)

nomuckabout:

firenownotpressed2:
; fire has been released.

firenotpressed2
; fire was not pressed last frame...


dointer

JUSTSOUNDS:
				tst.b	dosounds
				beq.s	.notthing

				cmp.b	#'4',Prefsfile+1
				beq		fourchannel

				btst	#1,$dff000+intreqr
				bne.s	newsampbitl

.notthing:

; move.w #$f,$dff000+dmacon

				GETREGS

				moveq	#0,d0					; VERTB interrupt needs to return Z flag set
				rts

********************************************************************
* End of VBlank code
********************************************************************


dosounds:		dc.w	0

swappedem:		dc.w	0

newsampbitl:
				move.w	#$200,$dff000+intreq

				tst.b	CHANNELDATA
				bne		nochannel0

				move.l	pos0LEFT,a0
				move.l	pos2LEFT,a1

				move.l	#tab,a2

				moveq	#0,d0
				moveq	#0,d1
				move.b	vol0left,d0
				move.b	vol2left,d1
				cmp.b	d1,d0
				slt		swappedem
				bge.s	fbig0

; d1 is bigger so scale d0 and use d1
; as audiochannel volume.

				exg		a0,a1
				asl.w	#6,d0
				divs	d1,d0
				lsl.w	#8,d0
				adda.w	d0,a2
				move.w	d1,$dff0a8
				bra.s	donechan0

fbig0:
				tst.w	d0
				beq.s	donechan0
				asl.w	#6,d1
				divs	d0,d1
				lsl.w	#8,d1
				adda.w	d1,a2
				move.w	d0,$dff0a8

donechan0:

				move.l	Aupt0,a3
				move.l	a3,$dff0a0
				move.l	Auback0,Aupt0
				move.l	a3,Auback0

				move.l	Auback0,a3

				moveq	#0,d0
				moveq	#0,d1
				moveq	#0,d2
				moveq	#0,d3
				moveq	#0,d4
				moveq	#0,d5
				move.w	#49,d7
loop:
				move.l	(a0)+,d0
				move.b	(a1)+,d1
				move.b	(a1)+,d2
				move.b	(a1)+,d3
				move.b	(a1)+,d4
				move.b	(a2,d3.w),d5
				swap	d5
				move.b	(a2,d1.w),d5
				asl.l	#8,d5
				move.b	(a2,d2.w),d5
				swap	d5
				move.b	(a2,d4.w),d5
				add.l	d5,d0
				move.l	d0,(a3)+
				dbra	d7,loop

				tst.b	swappedem
				beq.s	.ok23
				exg		a0,a1
.ok23:

				cmp.l	Samp0endLEFT,a0
				blt.s	.notoffendsamp1
				move.l	#Aud_EmptyBuffer_vl,a0
				move.l	#Aud_EmptyBufferEnd,Samp0endLEFT
				move.b	#0,vol0left
				clr.w	LEFTCHANDATA+32
				move.w	#0,LEFTCHANDATA+2
.notoffendsamp1:

				cmp.l	Samp2endLEFT,a1
				blt.s	.notoffendsamp2
				move.l	#Aud_EmptyBuffer_vl,a1
				move.l	#Aud_EmptyBufferEnd,Samp2endLEFT
				move.b	#0,vol2left
				clr.w	LEFTCHANDATA+32+8
				move.w	#0,LEFTCHANDATA+2+8
.notoffendsamp2:

				move.l	a0,pos0LEFT
				move.l	a1,pos2LEFT

nochannel0:

				tst.b	CHANNELDATA+16
				bne		nochannel1


				move.l	pos0RIGHT,a0
				move.l	pos2RIGHT,a1

				move.l	Aupt1,a3
				move.l	a3,$dff0b0
				move.l	Auback1,Aupt1
				move.l	a3,Auback1

				move.l	#tab,a2

				moveq	#0,d0
				moveq	#0,d1
				move.b	vol0right,d0
				move.b	vol2right,d1
				cmp.b	d1,d0
				slt		swappedem
				bge.s	fbig1

; d1 is bigger so scale d0 and use d1
; as audiochannel volume.

				exg		a0,a1
				asl.w	#6,d0
				divs	d1,d0
				lsl.w	#8,d0
				adda.w	d0,a2
				move.w	d1,$dff0b8
				bra.s	donechan1

fbig1:
				tst.w	d0
				beq.s	donechan1
				asl.w	#6,d1
				divs	d0,d1
				lsl.w	#8,d1
				adda.w	d1,a2
				move.w	d0,$dff0b8

donechan1:
				moveq	#0,d0
				moveq	#0,d1
				moveq	#0,d2
				moveq	#0,d3
				moveq	#0,d4
				moveq	#0,d5
				move.w	#49,d7
loop2:
				move.l	(a0)+,d0
				move.b	(a1)+,d1
				move.b	(a1)+,d2
				move.b	(a1)+,d3
				move.b	(a1)+,d4
				move.b	(a2,d3.w),d5
				swap	d5
				move.b	(a2,d1.w),d5
				asl.l	#8,d5
				move.b	(a2,d2.w),d5
				swap	d5
				move.b	(a2,d4.w),d5
				add.l	d5,d0
				move.l	d0,(a3)+
				dbra	d7,loop2

				tst.b	swappedem
				beq.s	ok01
				exg		a0,a1
ok01:

				cmp.l	Samp0endRIGHT,a0
				blt.s	.notoffendsamp1
				move.l	#Aud_EmptyBuffer_vl,a0
				move.l	#Aud_EmptyBufferEnd,Samp0endRIGHT
				move.b	#0,vol0right
				clr.w	RIGHTCHANDATA+32
				move.w	#0,RIGHTCHANDATA+2
.notoffendsamp1:

				cmp.l	Samp2endRIGHT,a1
				blt.s	.notoffendsamp2
				move.l	#Aud_EmptyBuffer_vl,a1
				move.l	#Aud_EmptyBufferEnd,Samp2endRIGHT
				move.b	#0,vol2right
				clr.w	RIGHTCHANDATA+32+8
				move.w	#0,RIGHTCHANDATA+2+8
.notoffendsamp2:

				move.l	a0,pos0RIGHT
				move.l	a1,pos2RIGHT

nochannel1:

******************* Other two channels

				move.l	pos1LEFT,a0
				move.l	pos3LEFT,a1

				move.l	#tab,a2

				moveq	#0,d0
				moveq	#0,d1
				move.b	vol1left,d0
				move.b	vol3left,d1
				cmp.b	d1,d0
				slt		swappedem
				bge.s	fbig2

; d1 is bigger so scale d0 and use d1
; as audiochannel volume.

				exg		a0,a1
				asl.w	#6,d0
				divs	d1,d0
				lsl.w	#8,d0
				adda.w	d0,a2
				move.w	d1,$dff0d8
				bra.s	donechan2

fbig2:
				tst.w	d0
				beq.s	donechan2
				asl.w	#6,d1
				divs	d0,d1
				lsl.w	#8,d1
				adda.w	d1,a2
				move.w	d0,$dff0d8

donechan2:

				move.l	Aupt2,a3
				move.l	a3,$dff0d0
				move.l	Auback2,Aupt2
				move.l	a3,Auback2

				moveq	#0,d0
				moveq	#0,d1
				moveq	#0,d2
				moveq	#0,d3
				moveq	#0,d4
				moveq	#0,d5
				move.w	#49,d7
loop3:											; mixing two channels, 50 * 4
				move.l	(a0)+,d0				; this is sometimes reading past beyond the sample buffer
				move.b	(a1)+,d1
				move.b	(a1)+,d2
				move.b	(a1)+,d3
				move.b	(a1)+,d4
				move.b	(a2,d3.w),d5			; the audio stream in a1 gets scaled via a table?
				swap	d5
				move.b	(a2,d1.w),d5
				asl.l	#8,d5
				move.b	(a2,d2.w),d5
				swap	d5
				move.b	(a2,d4.w),d5
				add.l	d5,d0
				move.l	d0,(a3)+
				dbra	d7,loop3

				tst.b	swappedem
				beq.s	.ok23
				exg		a0,a1
.ok23:

				cmp.l	Samp1endLEFT,a0
				blt.s	.notoffendsamp3
				move.l	#Aud_EmptyBuffer_vl,a0
				move.l	#Aud_EmptyBufferEnd,Samp1endLEFT
				move.b	#0,vol1left
				clr.w	LEFTCHANDATA+32+4
				move.w	#0,LEFTCHANDATA+2+4
.notoffendsamp3:

				cmp.l	Samp3endLEFT,a1
				blt.s	.notoffendsamp4
				move.l	#Aud_EmptyBuffer_vl,a1
				move.l	#Aud_EmptyBufferEnd,Samp3endLEFT
				move.b	#0,vol3left
				clr.w	LEFTCHANDATA+32+12
				move.w	#0,LEFTCHANDATA+2+12
.notoffendsamp4:

				move.l	a0,pos1LEFT
				move.l	a1,pos3LEFT

				move.l	pos1RIGHT,a0
				move.l	pos3RIGHT,a1

				move.l	Aupt3,a3
				move.l	a3,$dff0c0
				move.l	Auback3,Aupt3
				move.l	a3,Auback3

				move.l	#tab,a2

				moveq	#0,d0
				moveq	#0,d1
				move.b	vol1right,d0
				move.b	vol3right,d1
				cmp.b	d1,d0
				slt		swappedem
				bge.s	fbig3

				exg		a0,a1
				asl.w	#6,d0
				divs	d1,d0
				lsl.w	#8,d0
				adda.w	d0,a2
				move.w	d1,$dff0c8
				bra.s	donechan3

fbig3:
				tst.w	d0
				beq.s	donechan3
				asl.w	#6,d1
				divs	d0,d1
				lsl.w	#8,d1
				adda.w	d1,a2
				move.w	d0,$dff0c8
donechan3:

				moveq	#0,d0
				moveq	#0,d1
				moveq	#0,d2
				moveq	#0,d3
				moveq	#0,d4
				moveq	#0,d5
				move.w	#49,d7
loop4:
				move.l	(a0)+,d0
				move.b	(a1)+,d1
				move.b	(a1)+,d2
				move.b	(a1)+,d3
				move.b	(a1)+,d4
				move.b	(a2,d3.w),d5
				swap	d5
				move.b	(a2,d1.w),d5
				asl.l	#8,d5
				move.b	(a2,d2.w),d5
				swap	d5
				move.b	(a2,d4.w),d5
				add.l	d5,d0
				move.l	d0,(a3)+
				dbra	d7,loop4

				tst.b	swappedem
				beq.s	.ok23
				exg		a0,a1
.ok23:

				cmp.l	Samp1endRIGHT,a0
				blt.s	notoffendsamp3
				move.l	#Aud_EmptyBuffer_vl,a0
				move.l	#Aud_EmptyBufferEnd,Samp1endRIGHT
				move.b	#0,vol1right
				clr.w	RIGHTCHANDATA+32+4
				move.w	#0,RIGHTCHANDATA+2+4
notoffendsamp3:

				cmp.l	Samp3endRIGHT,a1
				blt.s	notoffendsamp4
				move.l	#Aud_EmptyBuffer_vl,a1
				move.l	#Aud_EmptyBufferEnd,Samp3endRIGHT
				move.b	#0,vol3right
				clr.w	RIGHTCHANDATA+32+12
				move.w	#0,RIGHTCHANDATA+2+12
notoffendsamp4:

				move.l	a0,pos1RIGHT
				move.l	a1,pos3RIGHT

				GETREGS

				move.w	#$820f,$dff000+dmacon

				moveq	#0,d0					; VERTB interrupt needs to return Z flag set
				rts

***********************************
* 4 channel sound routine
***********************************

fourchannel:
				move.l	#$dff000,a6

				tst.b	LEFTCHANDATA
				bne.s	NoChan0sound

				btst	#7,intreqrl(a6)
				beq.s	nofinish0
; move.w #0,LEFTCHANDATA+2
; st LEFTCHANDATA+1
				move.l	#Aud_Null1_vw,$a0(a6)
				move.w	#100,$a4(a6)
				move.w	#$0080,intreq(a6)

nofinish0:
				tst.b	NoiseMade0pLEFT
				beq.s	NoChan0sound

				move.l	Samp0endLEFT,d0
				move.l	pos0LEFT,d1
				sub.l	d1,d0
				lsr.l	#1,d0
				move.w	d0,$a4(a6)
				move.l	d1,$a0(a6)
				ext.l	d0

				divs	#100,d0 ; todo approximate?

				move.w	d0,playnull0
				move.w	#$8201,dmacon(a6)
				moveq	#0,d0
				move.b	vol0left,d0
				move.w	d0,$a8(a6)

NoChan0sound:

*****************************************
*****************************************

				btst	#0,intreqr(a6)
				beq.s	nofinish1
				move.l	#Aud_Null1_vw,$b0(a6)
				move.w	#100,$b4(a6)
				move.w	#$0100,intreq(a6)

nofinish1:
				tst.b	NoiseMade0pRIGHT
				beq.s	NoChan1sound

				move.l	Samp0endRIGHT,d0
				move.l	pos0RIGHT,d1
				sub.l	d1,d0
				lsr.l	#1,d0
				move.w	d0,$b4(a6)
				move.l	d1,$b0(a6)
				ext.l	d0
				divs	#100,d0
				move.w	d0,playnull1
				move.w	#$8202,dmacon(a6)
				moveq	#0,d0
				move.b	vol0right,d0
				move.w	d0,$b8(a6)

NoChan1sound:

*****************************************
*****************************************

				btst	#1,intreqr(a6)
				beq.s	nofinish2
				move.l	#Aud_Null1_vw,$c0(a6)
				move.w	#100,$c4(a6)
				move.w	#$0200,intreq(a6)
nofinish2:

				tst.b	NoiseMade1pRIGHT
				beq.s	NoChan2sound

				move.l	Samp1endRIGHT,d0
				move.l	pos1RIGHT,d1
				sub.l	d1,d0
				lsr.l	#1,d0
				move.w	d0,$c4(a6)
				ext.l	d0
				divs	#100,d0
				move.w	d0,playnull2

				move.l	d1,$c0(a6)
				move.w	#$8204,dmacon(a6)
				moveq	#0,d0
				move.b	vol1right,d0
				move.w	d0,$c8(a6)

NoChan2sound:

*****************************************
*****************************************

				btst	#2,intreqr(a6)
				beq.s	nofinish3
				move.l	#Aud_Null1_vw,$d0(a6)
				move.w	#100,$d4(a6)
				move.w	#$0400,intreq(a6)
nofinish3:
				tst.b	NoiseMade1pLEFT
				beq.s	NoChan3sound

				move.l	Samp1endLEFT,d0
				move.l	pos1LEFT,d1
				sub.l	d1,d0
				lsr.l	#1,d0
				move.w	d0,$d4(a6)
				ext.l	d0

				divs	#100,d0 ; todo - approximate?

				move.w	d0,playnull3
				move.l	d1,$d0(a6)
				move.w	#$8208,dmacon(a6)
				moveq	#0,d0
				move.b	vol1left,d0
				move.w	d0,$d8(a6)

NoChan3sound:

nomorechannels:
				move.l	NoiseMade0LEFT,NoiseMade0pLEFT
				move.l	#0,NoiseMade0LEFT
				move.l	NoiseMade0RIGHT,NoiseMade0pRIGHT
				move.l	#0,NoiseMade0RIGHT

				tst.b	NoiseMade0pLEFT
				bne.s	chan0still
				tst.w	playnull0
				beq.s	nnul0
				sub.w	#1,playnull0
				bra.s	chan0still
nnul0:
				move.w	#0,LEFTCHANDATA+2
				clr.w	LEFTCHANDATA+32
chan0still:

				tst.b	NoiseMade0pRIGHT
				bne.s	chan1still				;it'll never work
				tst.w	playnull1
				beq.s	nnul1
				sub.w	#1,playnull1
				bra.s	chan1still
nnul1:
				move.w	#0,RIGHTCHANDATA+2
				clr.w	RIGHTCHANDATA+32
chan1still:

				tst.b	NoiseMade1pRIGHT
				bne.s	chan2still
				tst.w	playnull2
				beq.s	nnul2
				sub.w	#1,playnull2
				bra.s	chan2still
nnul2:
				move.w	#0,RIGHTCHANDATA+2+4
				clr.w	RIGHTCHANDATA+32+4
chan2still:

				tst.b	NoiseMade1pLEFT
				bne.s	chan3still
				tst.w	playnull3
				beq.s	nnul3
				sub.w	#1,playnull3
				bra.s	chan3still
nnul3:
				move.w	#0,LEFTCHANDATA+2+4
				clr.w	LEFTCHANDATA+32+4

chan3still:
				GETREGS

				moveq	#0,d0					; VERTB interrupt needs to return Z flag set
				rts

backbeat:		dc.w	0

playnull0:		dc.w	0
playnull1:		dc.w	0
playnull2:		dc.w	0
playnull3:		dc.w	0

Samp0endRIGHT:	dc.l	Aud_EmptyBufferEnd
Samp1endRIGHT:	dc.l	Aud_EmptyBufferEnd
Samp2endRIGHT:	dc.l	Aud_EmptyBufferEnd
Samp3endRIGHT:	dc.l	Aud_EmptyBufferEnd
Samp0endLEFT:	dc.l	Aud_EmptyBufferEnd
Samp1endLEFT:	dc.l	Aud_EmptyBufferEnd
Samp2endLEFT:	dc.l	Aud_EmptyBufferEnd
Samp3endLEFT:	dc.l	Aud_EmptyBufferEnd

Aupt0:			dc.l	Aud_Null1_vw
Auback0:		dc.l	Aud_Null1_vw+500
Aupt2:			dc.l	Aud_Null3_vw
Auback2:		dc.l	Aud_Null3_vw+500
Aupt3:			dc.l	Aud_Null4_vw
Auback3:		dc.l	Aud_Null4_vw+500
Aupt1:			dc.l	Aud_Null2_vw
Auback1:		dc.l	Aud_Null2_vw+500

NoiseMade0LEFT:	dc.b	0
NoiseMade1LEFT:	dc.b	0
NoiseMade2LEFT:	dc.b	0
NoiseMade3LEFT:	dc.b	0
NoiseMade0pLEFT: dc.b	0
NoiseMade1pLEFT: dc.b	0
NoiseMade2pLEFT: dc.b	0
NoiseMade3pLEFT: dc.b	0
NoiseMade0RIGHT: dc.b	0
NoiseMade1RIGHT: dc.b	0
NoiseMade2RIGHT: dc.b	0
NoiseMade3RIGHT: dc.b	0
NoiseMade0pRIGHT: dc.b	0
NoiseMade1pRIGHT: dc.b	0
NoiseMade2pRIGHT: dc.b	0
NoiseMade3pRIGHT: dc.b	0


**************************************
* I want a routine to calculate all the
* info needed for the sound player to
* work, given say position of noise, volume
* and sample number.

Aud_SampleNum_w:    dc.w	0
Aud_NoiseX_w:       dc.w	0
Aud_NoiseZ_w:       dc.w	0
Aud_NoiseVol_w:     dc.w	0
Aud_ChannelPick_b:  dc.w	0
IDNUM:              dc.w	0
Aud_NeedLeft_b:     dc.b	0
Aud_NeedRight_b:    dc.b	0
Aud_Stereo_b:       dc.b	$FF

				even
CHANNELDATA:
LEFTCHANDATA:
				dc.l	$00000000
				dc.l	$00000000
				dc.l	$FF000000
				dc.l	$FF000000
RIGHTCHANDATA:
				dc.l	$00000000
				dc.l	$00000000
				dc.l	$FF000000
				dc.l	$FF000000

				ds.l	8

RIGHTPLAYEDTAB:	ds.l	20
LEFTPLAYEDTAB:	ds.l	20

SourceEcho:		dc.w	0
PLREcho:		dc.w	0


LEFTOFFSET:		dc.l	0
RIGHTOFFSET:	dc.l	0

; TODO - this is a replacement hook
Aud_PlaySound:
				SAVEREGS
				bsr MakeSomeNoise
				GETREGS
				rts


MakeSomeNoise:

; move.w #$10,$dff000+intena

; Plan for new sound handler:
; It is sent a sample number,
; a position relative to the
; player, an id number and a volume.
; Also notifplaying.

; indirect inputs are the available
; channel flags and whether or not
; stereo sound is selected.

; the algorithm must decide
; whether the new sound is more
; important than the ones already
; playing. Thus an 'importance'
; must be calculated, probably
; using volume.

; The output needs to be:

; Write the pointers and volumes of
; the sound channels

				tst.b	notifplaying
				beq.s	dontworry

; find if we are already playing

				move.w	IDNUM,d0
				cmp.w	#$ffff,d0
				beq.s	dontworry
				move.w	#7,d1
				lea		CHANNELDATA,a3
findsameasme:
				tst.b	(a3)
				bne.s	notavail
				cmp.w	32(a3),d0
				beq		SameAsMe
notavail:
				add.w	#4,a3
				dbra	d1,findsameasme
				bra		dontworry
SameAsMe
; move.w #$8010,$dff000+intena
				rts

noiseloud:		dc.w	0

dontworry:

; Ok its fine for us to play a sound.
; So calculate left/right volume.

				move.w	Aud_NoiseX_w,d1
				muls	d1,d1
				move.w	Aud_NoiseZ_w,d2
				muls	d2,d2
				move.w	Aud_NoiseVol_w,d3
				move.w	#32767,noiseloud
				moveq	#1,d0
				add.l	d1,d2
				beq		pastcalc

				move.w	#31,d0
.findhigh
				btst	d0,d2
				bne		.foundhigh
				dbra	d0,.findhigh
.foundhigh
				asr.w	#1,d0
				clr.l	d3
				bset	d0,d3
				move.l	d3,d0

				move.w	d0,d3
				muls	d3,d3					; x*x
				sub.l	d2,d3					; x*x-a
				asr.l	#1,d3					; (x*x-a)/2
				divs	d0,d3					; (x*x-a)/2x
				sub.w	d3,d0					; second approx
				bgt		.stillnot0
				move.w	#1,d0
.stillnot0

				move.w	d0,d3
				muls	d3,d3
				sub.l	d2,d3
				asr.l	#1,d3
				divs	d0,d3
				sub.w	d3,d0					; second approx
				bgt		.stillnot02
				move.w	#1,d0
.stillnot02

				move.w	Aud_NoiseVol_w,d3
				ext.l	d3
				asl.l	#6,d3
				cmp.l	#32767,d3
				ble.s	.nnnn
				move.l	#32767,d3
.nnnn

				asr.w	#2,d0
				addq	#1,d0
				divs	d0,d3

pastcalc:
				move.w	d3,noiseloud

				cmp.w	#64,d3
				ble.s	notooloud
				move.w	#64,d3
notooloud:

; d3 contains volume of noise.

				move.w	d3,d4
				tst.b	Aud_Stereo_b
				beq		NOSTEREO

				move.w	d3,d2
				muls	Aud_NoiseX_w,d2
				asl.w	#2,d0
				divs	d0,d2

				bgt.s	quietleft
				add.w	d2,d4
				bge.s	donequiet
				move.w	#0,d4
				bra.s	donequiet
quietleft:
				sub.w	d2,d3
				bge.s	donequiet
				move.w	#0,d3
donequiet:

; d3=leftvol?
; d4=rightvol?


; d3 contains volume of noise.

				move.w	#$ffff,Aud_NeedLeft_b

				move.l	#0,RIGHTOFFSET
				move.l	#0,LEFTOFFSET

				cmp.b	d3,d4
				bgt.s	RightLouder
				beq.s	NoLouder

				move.l	#4,LEFTOFFSET

; Left is louder; is it MUCH louder?

				st		Aud_NeedLeft_b
				move.w	d3,d2
				sub.w	d4,d2
				cmp.w	#32,d2
				slt		Aud_NeedRight_b
				bra		aboutsame

RightLouder:
				move.l	#4,RIGHTOFFSET
				st		Aud_NeedRight_b
				move.w	d4,d2
				sub.w	d3,d2
				cmp.w	#32,d2
				slt		Aud_NeedLeft_b

aboutsame:
NoLouder:


; Find least important sound on left

				move.l	#0,a2
				move.l	#0,d5
				move.w	#32767,d2
				move.w	IDNUM,d0
				lea		LEFTCHANDATA,a3
				move.w	#3,d1
FindLeftChannel
				tst.b	(a3)
				bne.s	.notactive
				cmp.w	32(a3),d0
				beq.s	FOUNDLEFT
				cmp.w	2(a3),d2
				blt.s	.notactive
				move.w	2(a3),d2
				move.l	a3,a2
				move.w	d5,d6

.notactive:
				add.w	#4,a3
				add.w	#1,d5
				dbra	d1,FindLeftChannel
				move.l	a2,a3
				bra.s	gopastleft
FOUNDLEFT:
				move.w	d5,d6
gopastleft:
				move.l	a3,d5
				tst.l	d5
				bne.s	FOUNDALEFT
NONOISE:
; move.w #$8010,$dff000+intena
				rts
FOUNDALEFT:

				cmp.w	noiseloud,d2
				bge		dorightchan

; d6 = channel number
				cmp.w	#$ffff,d0
				bne.s	.noche
				move.w	#$fffe,d0
.noche:
				move.w	d0,32(a3)
				move.w	noiseloud,2(a3)

				move.w	Aud_SampleNum_w,d5

				move.l	#Aud_SampleList_vl,a3
				move.l	(a3,d5.w*8),a1
				add.l	LEFTOFFSET,a1
				move.l	4(a3,d5.w*8),a2
				add.l	LEFTOFFSET,a2

				tst.b	d6
				seq		NoiseMade0LEFT
				beq.s	.chan0
				cmp.b	#2,d6
				slt		NoiseMade1LEFT
				blt		.chan1
				seq		NoiseMade2LEFT
				beq		.chan2
				st		NoiseMade3LEFT

				move.b	d5,LEFTPLAYEDTAB+9
				move.b	d3,LEFTPLAYEDTAB+1+9
				move.b	d4,LEFTPLAYEDTAB+2+9
				move.b	d3,vol3left
				move.l	a1,pos3LEFT
				move.l	a2,Samp3endLEFT
				bra		dorightchan

.chan0:
				move.b	d5,LEFTPLAYEDTAB
				move.b	d3,LEFTPLAYEDTAB+1
				move.b	d4,LEFTPLAYEDTAB+2
				move.l	a1,pos0LEFT
				move.l	a2,Samp0endLEFT
				move.b	d3,vol0left
				bra		dorightchan

.chan1:
				move.b	d5,LEFTPLAYEDTAB+3
				move.b	d3,LEFTPLAYEDTAB+1+3
				move.b	d4,LEFTPLAYEDTAB+2+3
				move.b	d3,vol1left
				move.l	a1,pos1LEFT
				move.l	a2,Samp1endLEFT
				bra		dorightchan

.chan2:
				move.b	d5,LEFTPLAYEDTAB+6
				move.b	d3,LEFTPLAYEDTAB+1+6
				move.b	d4,LEFTPLAYEDTAB+2+6
				move.l	a1,pos2LEFT
				move.l	a2,Samp2endLEFT
				move.b	d3,vol2left

dorightchan:

; Find least important sound on right

				move.l	#0,a2
				move.l	#0,d5
				move.w	#10000,d2
				move.w	IDNUM,d0
				lea		RIGHTCHANDATA,a3
				move.w	#3,d1
FindRightChannel
				tst.b	(a3)
				bne.s	.notactive
				cmp.w	32(a3),d0
				beq.s	FOUNDRIGHT
				cmp.w	2(a3),d2
				blt.s	.notactive
				move.w	2(a3),d2
				move.l	a3,a2
				move.w	d5,d6

.notactive:
				add.w	#4,a3
				add.w	#1,d5
				dbra	d1,FindRightChannel
				move.l	a2,a3
				bra.s	gopastright
FOUNDRIGHT:
				move.w	d5,d6
gopastright:
				move.l	a3,d5
				tst.l	d5
				bne.s	FOUNDARIGHT
tototot:
; move.w #$8010,$dff000+intena
				rts
FOUNDARIGHT:

				cmp.w	noiseloud,d2
				bgt.s	tototot

; d6 = channel number
				cmp.w	#$ffff,d0
				bne.s	.noche
				move.w	#$fffe,d0
.noche:
				move.w	d0,32(a3)
				move.w	noiseloud,2(a3)

				move.w	Aud_SampleNum_w,d5
				move.l	#Aud_SampleList_vl,a3
				move.l	(a3,d5.w*8),a1
				move.l	4(a3,d5.w*8),a2
				add.l	RIGHTOFFSET,a1
				add.l	RIGHTOFFSET,a2

				tst.b	d6
				seq		NoiseMade0RIGHT
				beq.s	.chan0
				cmp.b	#2,d6
				slt		NoiseMade1RIGHT
				blt		.chan1
				seq		NoiseMade2RIGHT
				beq		.chan2
				st		NoiseMade3RIGHT

				move.b	d5,RIGHTPLAYEDTAB+9
				move.b	d3,RIGHTPLAYEDTAB+1+9
				move.b	d4,RIGHTPLAYEDTAB+2+9
				move.b	d4,vol3right
				move.l	a1,pos3RIGHT
				move.l	a2,Samp3endRIGHT
; move.w #$8010,$dff000+intena
				rts

.chan0:
				move.b	d5,RIGHTPLAYEDTAB
				move.b	d3,RIGHTPLAYEDTAB+1
				move.b	d4,RIGHTPLAYEDTAB+2
				move.l	a1,pos0RIGHT
				move.l	a2,Samp0endRIGHT
				move.b	d4,vol0right
; move.w #$8010,$dff000+intena
				rts

.chan1:
				move.b	d5,RIGHTPLAYEDTAB+3
				move.b	d3,RIGHTPLAYEDTAB+1+3
				move.b	d4,RIGHTPLAYEDTAB+2+3
				move.b	d3,vol1right
				move.l	a1,pos1RIGHT
				move.l	a2,Samp1endRIGHT
; move.w #$8010,$dff000+intena
				rts

.chan2:
				move.b	d5,RIGHTPLAYEDTAB+6
				move.b	d3,RIGHTPLAYEDTAB+1+6
				move.b	d4,RIGHTPLAYEDTAB+2+6
				move.l	a1,pos2RIGHT
				move.l	a2,Samp2endRIGHT
				move.b	d3,vol2right
; move.w #$8010,$dff000+intena
				rts

NOSTEREO:
				move.l	#0,a2
				move.l	#-1,d5
				move.w	#32767,d2
				move.w	IDNUM,d0
				lea		CHANNELDATA,a3
				move.w	#7,d1
				moveq	#-1,d6

FindChannel
				tst.b	(a3)
				bne.s	.notactive
				cmp.w	32(a3),d0
				beq.s	FOUNDMYCHAN
				cmp.w	2(a3),d2
				blt.s	.notactive
				move.w	2(a3),d2
				move.l	a3,a2
				move.w	d5,d6
				add.w	#1,d6

.notactive:
				add.w	#4,a3
				add.w	#1,d5
				dbra	d1,FindChannel

				move.l	a2,a3
				bra.s	gopastchan

FOUNDMYCHAN:
				move.w	2(a3),d2

FOUNDCHAN:
				move.w	d5,d6
				add.w	#1,d6
gopastchan:
				tst.w	d6
				bge.s	FOUNDACHAN
tooquiet:
; move.w #$8010,$dff000+intena
				rts
FOUNDACHAN:

; d6 = channel number

				cmp.w	noiseloud,d2
				bgt.s	tooquiet

				cmp.w	#$ffff,d0
				bne.s	.noche
				move.w	#$fffe,d0
.noche:
				move.w	d0,32(a3)
				move.w	noiseloud,2(a3)

				move.w	Aud_SampleNum_w,d5

				move.l	#Aud_SampleList_vl,a3
				move.l	(a3,d5.w*8),a1
				move.l	4(a3,d5.w*8),a2

				tst.b	d6
				beq		.chan0
				cmp.b	#2,d6
				blt		.chan1
				beq		.chan2
				cmp.b	#4,d6
				blt		.chan3
				beq		.chan4
				cmp.b	#6,d6
				blt		.chan5
				beq		.chan6
				st		NoiseMade3RIGHT

				move.b	d5,RIGHTPLAYEDTAB+9
				move.b	d3,RIGHTPLAYEDTAB+1+9
				move.b	d4,RIGHTPLAYEDTAB+2+9
				move.b	d4,vol3right
				move.l	a1,pos3RIGHT
				move.l	a2,Samp3endRIGHT
; move.w #$8010,$dff000+intena
				rts

.chan3:
				st		NoiseMade3LEFT
				move.b	d5,LEFTPLAYEDTAB+9
				move.b	d3,LEFTPLAYEDTAB+1+9
				move.b	d4,LEFTPLAYEDTAB+2+9
				move.b	d3,vol3left
				move.l	a1,pos3LEFT
				move.l	a2,Samp3endLEFT
; move.w #$8010,$dff000+intena
				rts

.chan0:
				st		NoiseMade0LEFT
				move.b	d5,LEFTPLAYEDTAB
				move.b	d3,LEFTPLAYEDTAB+1
				move.b	d4,LEFTPLAYEDTAB+2
				move.l	a1,pos0LEFT
				move.l	a2,Samp0endLEFT
				move.b	d3,vol0left
; move.w #$8010,$dff000+intena
				rts

.chan1:
				st		NoiseMade1LEFT
				move.b	d5,LEFTPLAYEDTAB+3
				move.b	d3,LEFTPLAYEDTAB+1+3
				move.b	d4,LEFTPLAYEDTAB+2+3
				move.b	d3,vol1left
				move.l	a1,pos1LEFT
				move.l	a2,Samp1endLEFT
; move.w #$8010,$dff000+intena
				rts

.chan2:
				st		NoiseMade2LEFT
				move.b	d5,LEFTPLAYEDTAB+6
				move.b	d3,LEFTPLAYEDTAB+1+6
				move.b	d4,LEFTPLAYEDTAB+2+6
				move.l	a1,pos2LEFT
				move.l	a2,Samp2endLEFT
				move.b	d3,vol2left
; move.w #$8010,$dff000+intena
				rts

.chan4:
				st		NoiseMade0RIGHT
				move.b	d5,RIGHTPLAYEDTAB
				move.b	d3,RIGHTPLAYEDTAB+1
				move.b	d4,RIGHTPLAYEDTAB+2
				move.l	a1,pos0RIGHT
				move.l	a2,Samp0endRIGHT
				move.b	d4,vol0right
; move.w #$8010,$dff000+intena
				rts

.chan5:
				st		NoiseMade1RIGHT
				move.b	d5,RIGHTPLAYEDTAB+3
				move.b	d3,RIGHTPLAYEDTAB+1+3
				move.b	d4,RIGHTPLAYEDTAB+2+3
				move.b	d3,vol1right
				move.l	a1,pos1RIGHT
				move.l	a2,Samp1endRIGHT
; move.w #$8010,$dff000+intena
				rts

.chan6:
				st		NoiseMade2RIGHT
				move.b	d5,RIGHTPLAYEDTAB+6
				move.b	d3,RIGHTPLAYEDTAB+1+6
				move.b	d4,RIGHTPLAYEDTAB+2+6
				move.l	a1,pos2RIGHT
				move.l	a2,Samp2endRIGHT
				move.b	d3,vol2right
; move.w #$8010,$dff000+intena
				rts

				include	"modules/res.s"
				include	"modules/file_io.s"
				include "modules/vid.s"
				include	"controlloop.s"


saveinters:
				dc.w	0

z:				dc.w	10

notifplaying:
				dc.w	0

audpos1:		dc.w	0
audpos1b:		dc.w	0
audpos2:		dc.w	0
audpos2b:		dc.w	0
audpos3:		dc.w	0
audpos3b:		dc.w	0
audpos4:		dc.w	0
audpos4b:		dc.w	0

vol0left:		dc.w	0
vol0right:		dc.w	0
vol1left:		dc.w	0
vol1right:		dc.w	0
vol2left:		dc.w	0
vol2right:		dc.w	0
vol3left:		dc.w	0
vol3right:		dc.w	0

pos:			dc.l	0

pos0LEFT:		dc.l	Aud_EmptyBuffer_vl
pos1LEFT:		dc.l	Aud_EmptyBuffer_vl
pos2LEFT:		dc.l	Aud_EmptyBuffer_vl
pos3LEFT:		dc.l	Aud_EmptyBuffer_vl
pos0RIGHT:		dc.l	Aud_EmptyBuffer_vl
pos1RIGHT:		dc.l	Aud_EmptyBuffer_vl
pos2RIGHT:		dc.l	Aud_EmptyBuffer_vl
pos3RIGHT:		dc.l	Aud_EmptyBuffer_vl

numtodo			dc.w	0

npt:			dc.w	0

pretab:
val				SET		0
				REPT	128
				dc.b	val
val				SET		val+1
				ENDR
val				SET		-128
				REPT	128
				dc.b	val
val				SET		val+1
				ENDR

tab:
				ds.b	256*65

test:			dc.l	0
				ds.l	30


				align 4
Plr_XOff_l:		dc.l	0
Plr_ZOff_l:		dc.l	0
Plr_YOff_l:		dc.l	0
flooryoff:		dc.w	0						; viewer y pos << 6
XDiff_w:		dc.w	0
ZDiff_w:		dc.w	0
PlayEcho:		dc.w	0 ; accessed as byte

; // READY PLAYER ONE /////////////////////////////////////////////////////////////////////

*****************************************************************
*
				include	"modules/player.s"
*
*****************************************************************


				align 4
ZonePtr_l:			dc.l	0
Lvl_WalkLinksPtr_l:	dc.l	0
Lvl_FlyLinksPtr_l:	dc.l	0
					dc.l	0
Vid_CentreX_w:		dc.w	SMALL_WIDTH/2
		DCLC Vid_RightX_w, dc.w, SMALL_WIDTH


******************************************
* Link file !*****************************
******************************************
GLF_DatabasePtr_l:		dc.l	0
GLF_DatabaseName_vb:	dc.b	"ab3:includes/test.lnk",0

				align 4

******************************************

hitcol:			dc.l	0

;draw_GameMessageTimer_w:	dc.w	100
draw_GameMessageTimer_w:	dc.w	400

draw_GameMessageXPos_w:		dc.w	0
_draw_GameMessagePtr_l::
draw_GameMessagePtr_l:		dc.l	draw_BlankMessage_vb
draw_GameMessageEnd_l:		dc.l	draw_EndBlankMessage

_draw_MessageBuffer_vb::
draw_BlankMessage_vb:
				;       12345678901234567890123456789012345678901234567890123456789012345678901234567890
				; dc.b "The Quick Brown Fox Jumped Over The Lazy Dog!                                   "
				; dc.b "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ                            "
				; dc.b "The Quick Brown Fox Jumped Over The Lazy Dog!                                   "
				dc.b	"                                                                                "
draw_EndBlankMessage: dc.l    0

Vid_TextScreenPtr_l:	dc.l	0


				SECTION	.bsschip,bss_c
				align 8

; Audio
Aud_Null1_vw:				ds.w	500
Aud_Null2_vw:				ds.w	500
Aud_Null3_vw:				ds.w	500
Aud_Null4_vw:				ds.w	500

				align 64
SCROLLSCRN:		ds.l	20*16

********************************************
* Stuff you don't have to worry about yet. *
********************************************

				section	.text,code

				; FIMXE: this is not what I was thinking it is.
				; This does not exit the whole game, but just playing
				; the game. After that it'll return to the main menu.

closeeverything:

				jsr		mt_end

;				move.l	_DOSBase,d0
;				move.l	d0,a1
;				CALLEXEC CloseLibrary
;
;				; FIXME: need to test if it even got installed
;				lea		VBLANKInt,a1
;				moveq	#INTB_VERTB,d0
;				CALLEXEC RemIntServer
;
;				IFEQ	CD32VER
;				lea		KEYInt,a1
;				moveq	#INTB_PORTS,d0
;				CALLEXEC RemIntServer
;				ENDC
;
				jsr		Res_FreeLevelData
				jsr		Res_ReleaseScreenMemory
;
;				move.l	_MiscBase,d0
;				beq.s	.noMiscResourceBase
;				move.l	d0,a6
;				; FIXME: would need to check if we actually allocated them successfully
;				move.l	#MR_SERIALPORT,d0
;				jsr		_LVOFreeMiscResource(a6)
;				move.l	#MR_SERIALBITS,d0
;				jsr		_LVOFreeMiscResource(a6)
;
;				clr.l	_MiscBase		; Resource library doesn't have a 'close'?
;
;.noMiscResourceBase
;
;				move.l	PotgoResourceBase,d0
;				beq.s	.noPotgoResource
;				move.l	d0,a6
;				move.l	#%110000000000,d0
;				jsr		_LVOFreePotBits(a6)
;
;
;
;.noPotgoResource
;
;				move.l	#0,d0					; FIXME indicate failure

				IFD BUILD_WITH_C
				tst.w	_Vid_isRTG
				bne.s	.skipClear
				ENDIF

				IFNE	DISPLAYMSGPORT_HACK
				;empty Vid_DisplayMsgPort_l and set Vid_ScreenBufferIndex_w to 0
				;so the starting point is the same every time
.clrMsgPort:
				move.l	Vid_DisplayMsgPort_l,a0
				CALLEXEC GetMsg
				tst.l	d0
				bne.s	.clrMsgPort
				ENDC

				clr.w	Vid_ScreenBufferIndex_w
.skipClear
				rts




				align 4
Panel:			dc.l	0

				cnop	0,64
TimerScr:		;		Not needed(?), but still referenced but (inactive?) code
;ds.b 40*64

NumTimes:		dc.l	0
TimeCount:		dc.l	0
oldtime:		dc.l	0
counting:		dc.b	0
oktodisplay:	dc.b	0

INITTIMER:
				move.l	#0,TimeCount
				move.l	#0,NumTimes
				rts

STARTCOUNT:
				move.l	d0,-(a7)
				move.l	$dff004,d0
				and.l	#$1ffff,d0
				move.l	d0,oldtime
				st		counting
				move.l	(a7)+,d0
				rts

STOPCOUNT:
				move.l	d0,-(a7)
				move.l	$dff004,d0
				and.l	#$1ffff,d0

				sub.l	oldtime,d0
				cmp.l	#-256,d0
				bge.s	okcount
				add.l	#313*256,d0
okcount:
				add.l	d0,TimeCount
				addq.l	#1,NumTimes
				clr.b	counting
				move.l	(a7)+,d0
				rts

STOPCOUNTNOADD:
				move.l	d0,-(a7)
				move.l	$dff004,d0
				and.l	#$1ffff,d0

				sub.l	oldtime,d0
				cmp.l	#-256,d0
				bge.s	okcount2
				add.l	#313*256,d0
okcount2:
				add.l	d0,TimeCount
				clr.b	counting
				move.l	(a7)+,d0
				rts

maxbot:			dc.w	0
tstneg:			dc.l	0

STOPTIMER:
				st		oktodisplay
				rts

				include "modules/music.s"

UseAllChannels:		dc.w	0
;CHEATPTR:			dc.l	0
;CHEATNUM:			dc.l	0
Lvl_MusicPtr_l:		dc.l	0

				section	.datachip,data_c
; not sure what this is; it seems to be used as timing
; device. I.e. by accessing chipmap, we throttle the CPU
tstchip:		dc.l	0
testchip:		dc.w	0

nullsample:		dc.l	0

gameover:
				incbin	"includes/gameover"
welldone:
				incbin	"includes/quietwelldone"

				section .text,code
				cnop	0,4
				include	"serial_nightmare.s"

				cnop	0,4

;				IFND OPT060
;				IFND OPT040
;				include "modules/c2p/c2p1x1_8_c5_030_2.s"
;				ENDC
;				ENDC
;				include	"modules/c2p/c2p1x1_8_c5_040.s"
;				include	"modules/c2p/c2p_rect.s"
;				include	"modules/c2p/c2p2x1_8_c5_gen.s"
;
;				include "modules/c2p/small_c2p1x1_8_c5_030_2.s"
