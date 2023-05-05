
			section .bss,bss

; BSS data - to be included in BSS section
			align 4

ai_AlienWorkspace_vl:		ds.l	4*300
AI_AlienTeamWorkspace_vl:	ds.l	4*30
AI_OtherAlienDataPtrs_vl:	ds.l	20
AI_Damaged_vw:				ds.w	300
AI_DamagePtr_l:				ds.l	1
AI_BoredomPtr_l:			ds.l	1
AI_BoredomSpace_vl:			ds.l	2*300
AI_FlyABit_w:				ds.w	1
AI_DefaultMode_w:			ds.w	1
AI_ResponseMode_w:			ds.w	1
AI_FollowupMode_w:			ds.w	1
AI_RetreatMode_w:			ds.w	1
AI_CurrentMode_w:			ds.w	1 ; unused ?
AI_ProwlSpeed_w:			ds.w	1
AI_ResponseSpeed_w:			ds.w	1
AI_RetreatSpeed_w:			ds.w	1
AI_FollowupSpeed_w:			ds.w	1
AI_FollowupTimer_w:			ds.w	1
AI_ReactionTime_w:			ds.w	1
AI_VecObj_w:				ds.w	1

ai_MiddleCPT_w:				ds.w	1
ai_GetOut_w:				ds.w	1
ai_ToSide_w:				ds.w	1
ai_AnimFacing_w:			ds.w	1
ai_DoAction_b:				ds.b	1
ai_FinishedAnim_b:			ds.b	1
AI_NoEnemies_b:				ds.b	1
