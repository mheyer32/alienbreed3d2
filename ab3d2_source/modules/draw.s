;
; *****************************************************************************
; *
; * modules/draw.s
; *
; * Ad hoc drawing routines
; *
; * Refactored from various places
; *
; *****************************************************************************

				align	4

; move me
firstdigit_b:	dc.b	0
secdigit_b:		dc.b	0
thirddigit_b:	dc.b	0
gunny_b:		dc.b	0

				align 4

Draw_Crosshair:
                ; Get the pen
                clr.l   d0
				move.b  Prefs_CrossHairColour_b,d0
				and.b   #7,d0 ; paranoia
				move.l  #Draw_CrosshairPens_vb,a1
				add.w   d0,a1
				tst.b   (a1)
                beq     .done


				move.l	Vid_FastBufferPtr_l,a0
				add.w	Vid_CentreX_w,a0
				move.w	Vid_BottomY_w,d0
				muls.w	#SCREEN_WIDTH/2,d0
***************************************************************
;dirty hack for fullscreen to allow the crosshair to match 2/3 screen position while looking for a mor robust solution.
***************************************************************
				tst.b	Vid_FullScreen_b
				beq.s	.small

				move.w	 STOPOFFSET,d1
                ble.s   .above

				muls.w  #(256/9),d1
				asr.l   #8,d1
				and.b   #$fe,d1
				muls.w  #SCREEN_WIDTH,d1

				add.w d1,d0
				bra.s	.below

.above:
				neg.w	d1

				muls.w  #(256/9),d1
				asr.l   #8,d1
                and.b   #$fe,d1
				muls.w  #SCREEN_WIDTH,d1

				sub.w d1,d0

.below:
***************************************************************
.small:
				add.l	d0,a0

				move.b  (a1),d0

				; TODO - Mod Properties should define a mechanism to allow per gun
				;        crosshair designs

				move.b	d0,-4*SCREEN_WIDTH-4(a0) ; TL
				move.b	d0,-4*SCREEN_WIDTH+4(a0) ; TR
                move.b	d0,-2*SCREEN_WIDTH-2(a0) ; TL
				move.b	d0,-2*SCREEN_WIDTH+2(a0) ; TR

				move.b	d0,2*SCREEN_WIDTH-2(a0) ; BL
				move.b	d0,2*SCREEN_WIDTH+2(a0) ; BR
				move.b	d0,4*SCREEN_WIDTH-4(a0) ; BL
				move.b	d0,4*SCREEN_WIDTH+4(a0) ; BR
.done:
				rts

				; TODO - this should be dedefinable by mod and/or user as they are currently defined
				; by the default palette
Draw_CrosshairPens_vb:
				dc.b   0 ; off
				dc.b 255 ; intense green
				dc.b 254 ; mid green
				dc.b 190 ; intense yellow
				dc.b  25 ; bright grey
				dc.b 250 ; intense red
				dc.b 133 ; ice blue
				dc.b  69 ; intense blue
