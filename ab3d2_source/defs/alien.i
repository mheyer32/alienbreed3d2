
	; Alien Data Definition
	STRUCTURE AlienT,0
		UWORD AlienT_GFXType_w				;  0, 2
		UWORD AlienT_DefaultBehaviour_w		;  2, 2
		UWORD AlienT_ReactionTime_w			;  4, 2
		UWORD AlienT_DefaultSpeed_w			;  6, 2
		UWORD AlienT_ResponseBehaviour_w	;  8, 2
		UWORD AlienT_ResponseSpeed_w		; 10, 2
		UWORD AlienT_ResponseTimeout_w		; 12, 2
		UWORD AlienT_DamageToRetreat_w		; 14, 2
		UWORD AlienT_DamageToFollowup_w		; 16, 2
		UWORD AlienT_FollowupBehaviour_w	; 18, 2
		UWORD AlienT_FollowupSpeed_w		; 20, 2
		UWORD AlienT_FollowupTimeout_w		; 22, 2
		UWORD AlienT_RetreatBehaviour_w		; 24, 2
		UWORD AlienT_RetreatSpeed_w			; 26, 2
		UWORD AlienT_RetreatTimeout_w		; 28, 2
		UWORD AlienT_BulType_w				; 30, 2
		UWORD AlienT_HitPoints_w			; 32, 2
		UWORD AlienT_Height_w				; 34, 2
		UWORD AlienT_Girth_w				; 36, 2
		UWORD AlienT_SplatType_w			; 38, 2 - either the projectile class, or spanwed alien class
		UWORD AlienT_Auxilliary_w			; 40, 2
		LABEL AlienT_SizeOf_l				; 42
