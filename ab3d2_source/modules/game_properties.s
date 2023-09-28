
; *****************************************************************************
; *
; * modules/game_properties.s
; *
; * TODO - For the assembler only build, implement these
; *
; *****************************************************************************

				IFND BUILD_WITH_C
				align 4

;void Game_InitDefaults(void)
Game_InitDefaults:
				rts

;d0: BOOL Game_CheckInventoryLimits(
;    a0: const Inventory*,
;    a1: const InventoryConsumables*,
;    a2: const InventoryItems*
;);
Game_CheckInventoryLimits:
				moveq #1,d0
				rts

;void Game_AddToInventory(
;    a0: Inventory*,
;    a1: const InventoryConsumables*,
;    a2: const InventoryItems*
;)
Game_AddToInventory:
				move.w	#NUM_INVENTORY_CONSUMABLES-1,d0

				; todo - do this checked against the game limits
.add_consumables:
				move.w	(a1)+,d1
				add.w	d1,(a0)+
				dbra	d0,.add_consumables

				move.w	#NUM_INVENTORY_ITEMS-1,d0
.add_items:
				move.w	(a2)+,d1
				or.w	d1,(a0)+
				dbra	d0,.add_items
				rts

;void Game_ApplyInventoryLimits(a0: Inventory*)
Game_ApplyInventoryLimits:
				rts

				ENDIF

