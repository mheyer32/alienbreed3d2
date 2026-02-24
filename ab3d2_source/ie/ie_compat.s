; ie_compat.s - legacy C/OS symbol compatibility for IE software path

	xdef mnu_dofire
	xdef _mnu_dofire
	xdef mnu_movescreen
	xdef _mnu_movescreen
	xdef mnu_clearscreen
	xdef _mnu_clearscreen
	xdef mnu_setscreen
	xdef _mnu_setscreen
	xdef Msg_Init
	xdef _Msg_Init
	xdef Msg_PushLine
	xdef _Msg_PushLine
	xdef Msg_PushLineDedupLast
	xdef _Msg_PushLineDedupLast
	xdef Game_ApplyInventoryLimits
	xdef _Game_ApplyInventoryLimits
	xdef Game_AddToInventory
	xdef _Game_AddToInventory
	xdef Game_CheckInventoryLimits
	xdef _Game_CheckInventoryLimits
	xdef Game_LevelWon
	xdef _Game_LevelWon
	xdef Game_LevelFailed
	xdef _Game_LevelFailed
	xdef Game_UpdatePlayerProgress
	xdef _Game_UpdatePlayerProgress
	xdef Game_LevelBegin
	xdef _Game_LevelBegin
	xdef Zone_InitEdgePVS
	xdef _Zone_InitEdgePVS
	xdef Zone_ApplyPVSErrata
	xdef _Zone_ApplyPVSErrata
	xdef Zone_CheckVisibleEdges
	xdef _Zone_CheckVisibleEdges
	xdef Zone_SetupEdgeClipping
	xdef _Zone_SetupEdgeClipping
	xdef Draw_ResetGameDisplay
	xdef _Draw_ResetGameDisplay
	xdef vid_SetupDoubleheightCopperlist
	xdef _vid_SetupDoubleheightCopperlist

	xdef _SysBase
	xdef _DOSBase
	xdef _Vid_isRTG
	xdef _custom
	xdef _ciaa

	xref Game_FinishedLevel_b

mnu_dofire:
_mnu_dofire:
	moveq	#0,d0
	rts

mnu_movescreen:
_mnu_movescreen:
	moveq	#0,d0
	rts

mnu_clearscreen:
_mnu_clearscreen:
	rts

mnu_setscreen:
_mnu_setscreen:
	moveq	#0,d0
	rts

Msg_Init:
_Msg_Init:
	rts

Msg_PushLine:
_Msg_PushLine:
	rts

Msg_PushLineDedupLast:
_Msg_PushLineDedupLast:
	rts

Game_ApplyInventoryLimits:
_Game_ApplyInventoryLimits:
	rts

Game_AddToInventory:
_Game_AddToInventory:
	rts

Game_CheckInventoryLimits:
_Game_CheckInventoryLimits:
	moveq	#1,d0
	rts

Game_LevelWon:
_Game_LevelWon:
	st		Game_FinishedLevel_b
	rts

Game_LevelFailed:
_Game_LevelFailed:
	rts

Game_UpdatePlayerProgress:
_Game_UpdatePlayerProgress:
	rts

Game_LevelBegin:
_Game_LevelBegin:
	rts

Zone_InitEdgePVS:
_Zone_InitEdgePVS:
	rts

Zone_ApplyPVSErrata:
_Zone_ApplyPVSErrata:
	rts

Zone_CheckVisibleEdges:
_Zone_CheckVisibleEdges:
	rts

Zone_SetupEdgeClipping:
_Zone_SetupEdgeClipping:
	rts

Draw_ResetGameDisplay:
_Draw_ResetGameDisplay:
	rts

vid_SetupDoubleheightCopperlist:
_vid_SetupDoubleheightCopperlist:
	rts

_SysBase:
	dc.l	0
_DOSBase:
	dc.l	0

; Force RTG-compatible flow in legacy call paths.
_Vid_isRTG:
	dc.w	1
	dc.w	0

; Dummy register-space backing for legacy custom chip reads/writes.
_custom:
	dcb.b	1024,0
_ciaa:
	dcb.b	256,0
