; TODO
				section .data,data
				align 4

; TODO - SetParams should set up the pointers and counters needed
c2p_SetParamsAkikoPtrs_vl:
				dc.l	c2p_SetParamsNull	; 000
				dc.l	c2p_SetParamsNull	; 001
				dc.l	c2p_SetParamsNull	; 010
				dc.l	c2p_SetParamsNull	; 011
				dc.l	c2p_SetParamsNull	; 100
				dc.l	c2p_SetParamsNull	; 101
				dc.l	c2p_SetParamsNull	; 110
				dc.l	c2p_SetParamsNull	; 111

c2p_ConvertAkikoPtrs_vl:
				dc.l	c2p_ConvertSmall1x1OptAkiko		; 000
				dc.l	c2p_ConvertSmall1x2OptAkiko		; 001
				dc.l	c2p_ConvertNull					; 010
				dc.l	c2p_ConvertNull					; 011
				dc.l	c2p_ConvertFull1x1OptAkiko		; 100
				dc.l	c2p_ConvertFull1x2OptAkiko		; 101
				dc.l	c2p_ConvertNull					; 110
				dc.l	c2p_ConvertNull					; 111

c2p_ConvertFull1x1OptAkiko:
				movem.l	d1-d7/a2/a3/a4/a6,-(sp)

				tst.b	Sys_Move16_b
				bne.s	.no_cacr_set

				move.l	_SysBase,a6
				jsr		_LVODisable(a6)
				jsr		_LVOSuperState(a6)

				movec	cacr,d0
				move.l	d0,-(sp)
				bclr.l	#13,d0 ; disable write allocation
				movec	d0,cacr

.no_cacr_set:
				move.l	Vid_FastBufferPtr_l,a0
				move.l	Vid_DrawScreenPtr_l,a1
				move.l	#$00B80038,a2
				move.l	a1,a3

				move.w	#C2P_FS_HEIGHT*C2P_BPL_WIDTH/32-1,d0
.loop:
				movem.l (a0)+,d1-d7/a4
				move.l  d1,(a2)
				move.l  d2,(a2)
				move.l  d3,(a2)
				move.l  d4,(a2)
				move.l  d5,(a2)
				move.l  d6,(a2)
				move.l  d7,(a2)
				move.l  a4,(a2)

				move.l  (a2),d1
				move.l  (a2),d2
				move.l  (a2),d3
				move.l  (a2),d4
				move.l  (a2),d5
				move.l  (a2),d6
				move.l  (a2),d7
				move.l  (a2),a4


				; write plane 0
				move.l  d1,(a1)
				add.w   #10240,a1

				move.l  d2,(a1)
				add.w   #10240,a1

				move.l  d3,(a1)
				add.w   #10240,a1

				move.l  d4,(a1)
				add.w   #10240,a1

				move.l  d5,(a1)
				add.w   #10240,a1

				move.l  d6,(a1)
				add.w   #10240,a1

				move.l  d7,(a1)
				add.w   #10240,a1
				add.w   #4,a3

				move.l  a4,(a1)
				move.l  a3,a1

				move.l  a3,a1
				dbra    d0,.loop

				tst.b	Sys_Move16_b
				bne.s	.no_cacr_restore

				move.l	(sp)+,d0
				movec	d0,cacr

				jsr		_LVOUserState(a6)
				jsr		_LVOEnable(a6)

.no_cacr_restore:
				movem.l (sp)+,d1-d7/a2/a3/a4/a6
				rts

c2p_ConvertFull1x2OptAkiko:
				rts

c2p_ConvertSmall1x1OptAkiko:
				rts

c2p_ConvertSmall1x2OptAkiko:
				rts
