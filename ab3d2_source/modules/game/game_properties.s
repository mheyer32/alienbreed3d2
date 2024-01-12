
; *****************************************************************************
; *
; * modules/game/game_properties.s
; *
; * Handles the loading and application of game modification data
; *
; *****************************************************************************

				IFND BUILD_WITH_C

GAME_DEFAULT_AMMO_LIMIT   equ 10000
GAME_DEFAULT_HEALTH_LIMIT equ 10000
GAME_DEFAULT_FUEL_LIMIT   equ 250
GAME_UNCAPPED_LIMIT       equ 32000

				align 4

game_LoadModProperties:
				move.w	#GAME_DEFAULT_HEALTH_LIMIT,game_ModProps+InvCT_Health_w
				move.w	#GAME_DEFAULT_FUEL_LIMIT,game_ModProps+InvCT_JetpackFuel_w
				lea		game_ModProps+InvCT_AmmoCounts_vw,a0
				move.w	#NUM_BULLET_DEFS-1,d0
				move.w	#GAME_DEFAULT_AMMO_LIMIT,d1

.loop:
				move.w	d1,(a0)+
				dbra	d0,.loop

				movem.l	d0-d4/a5-a6,-(sp)
				move.l	#game_PropertiesFile_vb,d1
				move.l	#MODE_OLDFILE,d2
				CALLDOS	Open

				move.l	d0,d4 ; keep file handle handle in d4
				beq.s	.io_error

				move.l	d0,d1
				lea		io_FileInfoBlock_vb,a5
				move.l	a5,d2
				CALLDOS	ExamineFH

				tst.w	d0
				beq.s	.io_error

				tst.l	fib_DirEntryType(a5)
				bge.s	.io_error

				cmp.l	#GModT_SizeOf_l,fib_Size(a5)
				bmi.s	.io_error

				move.l	d4,d1

				lea		Sys_Workspace_vl,a5
				move.l	a5,d2

				move.l	#GModT_SizeOf_l,d3
				CALLDOS Read

				move.l	d0,d2
				cmp.l	d3,d2
				bne.s	.io_error

				lea		game_ModProps,a6

				cmp.w	#GAME_UNCAPPED_LIMIT,InvCT_Health_w(a5)
				bge.s	.skip_health_limit

				move.w	InvCT_Health_w(a5),InvCT_Health_w(a6)

.skip_health_limit:
				cmp.w	#GAME_UNCAPPED_LIMIT,InvCT_JetpackFuel_w(a5)
				bge.s	.skip_fuel_limit

				move.w	InvCT_JetpackFuel_w(a5),InvCT_JetpackFuel_w(a6)

.skip_fuel_limit:
				add.w 	#InvCT_AmmoCounts_vw,a5
				add.w	#InvCT_AmmoCounts_vw,a6
				move.w	#NUM_BULLET_DEFS-1,d0

.ammo_loop:
				cmp.w	#GAME_UNCAPPED_LIMIT,(a5)
				bge.s	.skip_ammo
				move.w	(a5),(a6)

.skip_ammo:
				add.w	#2,a5
				add.w	#2,a6
				dbra	d0,.ammo_loop

.io_error:
				move.l	d4,d1
				CALLDOS Close

				movem.l (sp)+,d0-d4/a5-a6
				rts


				align 4
;d0: BOOL Game_CheckInventoryLimits(
;    a0: const Inventory*,
;    a1: const InventoryConsumables*,
;    a2: const InventoryItems*
;);
Game_CheckInventoryLimits:
				movem.l	d2/a3-a5,-(sp)

				; Traverse the whole item array
				move.w	#(InvIT_SizeOf_l>>1)-1,d0
				move.l	a2,a4 ; object items

				cmp.b	#PLR_SINGLE,Plr_MultiplayerType_b
				bne.s	.check_items_multiplayer

.check_items_singleplayer:

;        for (UWORD n = 0; n < sizeof(InventoryItems)/sizeof(UWORD); ++n) {
;            if (objInvPtr[n]) {
;                return TRUE;
;            }
;        }

.check_items_sp_loop:
				tst.w	(a4)+    ; does the object give this item?
				bne.s	.can_get

				dbra	d0,.check_items_sp_loop

				bra.s	.check_quantities

.check_items_multiplayer:

;        for (UWORD n = 0; n < sizeof(InventoryItems)/sizeof(UWORD); ++n) {
;            givesAnything |= objInvPtr[n];
;            if (objInvPtr[n] && !plrInvPtr[n]) {
;                return TRUE;
;            }
;        }

				clr.l	d2 ; givesAnything: keeps track of the total items given
				lea		InvT_Items(a0),a5 ; player inventory items

.check_items_mp_loop:
				tst.w	(a4)+        ; does the object give this item?
				beq.s	.continue_mp ; nope

				tst.w	(a5)         ; does the object give the item, does the player have it yet?
				beq.s	.can_get     ; if not, we can get it.

.continue_mp:
				add.w	#2,a5
				dbra	d0,.check_items_mp_loop

				; Done checking items, now we need to look at consumable caps
.check_quantities:

;    /** If the item gives us a quantity of something we aren't maxed out on, we can collect it */
;    plrInvPtr = &inventory->inv_Consumables.ic_Health;
;    objInvPtr = &consumables->ic_Health;
;    UWORD const *limPtr = &game_ModProps.gmp_MaxInventory.ic_Health;
;    for (UWORD n = 0; n < sizeof(InventoryConsumables)/sizeof(UWORD); ++n) {
;        givesAnything += objInvPtr[n];
;        if (objInvPtr[n] > 0 && plrInvPtr[n] < limPtr[n]) {
;            return TRUE;
;        }
;    }

				lea		InvT_Consumables(a0),a5; player consumable levels
				lea		game_ModProps,a3

				; add.w	GModT_MaxInv+InvCT_Health_w,a3 ; these offsets are zero for now
				move.l	a1,a4 ; object consumables

				; loop size
				move.w	#(InvCT_SizeOf_l>>1)-1,d0

.check_quantities_loop:
				move.w	(a4)+,d1	; object consumable count
				add.w	d1,d2		; add to tally

				; if the player count is not greater than the carry count...
				cmp.w	(a3)+,(a5)+
				bge.s	.continue_quantity

				; ...and the item gives a quantity of the consumable...
				tst.w	d1
				ble.s	.continue_quantity

				; ...we can have it
				bra.s	.can_get

.continue_quantity:
				dbra	d0,.check_quantities_loop

;    return givesAnything ? FALSE : TRUE;

				; Did the item give anything at all?
				tst.w	d2
				beq.s	.can_get

.cant_get:
				clr.l	d0
				bra.s	.done

.can_get:
				moveq #1,d0

.done:
				movem.l	(sp)+,a3-a5/d2
				rts

;void Game_AddToInventory(
;    a0: Inventory*,
;    a1: const InventoryConsumables*,
;    a2: const InventoryItems*
;)
Game_AddToInventory:
				move.w	#NUM_INVENTORY_CONSUMABLES-1,d0
				movem.l	d2/a3,-(sp)

				lea		game_ModProps+InvCT_Health_w,a3
				clr.l	d1
				clr.l	d2

.add_consumables:
				; extend to avoid overflows
				move.w	(a1)+,d1 ; the item quantity
				move.w	(a0),d2	 ; player inventory quantity
				add.l	d1,d2

				; compare to limit
				move.w	(a3)+,d1
				cmp.l	d1,d2
				ble.s	.no_clamp

				; Use the limit instead
				move.l	d1,d2

.no_clamp:
				move.w	d2,(a0)+
				dbra	d0,.add_consumables


				move.w	#NUM_INVENTORY_ITEMS-1,d0
.add_items:
				move.w	(a2)+,d1
				or.w	d1,(a0)+
				dbra	d0,.add_items

				movem.l	(sp)+,a3/d2
				rts

;void Game_ApplyInventoryLimits(a0: Inventory*)
Game_ApplyInventoryLimits:
				move.w	#NUM_INVENTORY_CONSUMABLES-1,d0
				lea		game_ModProps+InvCT_Health_w,a1

.clamp_loop:
				move.w	(a1)+,d1 ; max value
				cmp.w	(a0),d1
				bgt.s	.no_clamp

				move.w	d1,(a0)  ; clamp inventory to max
.no_clamp:
				add.w	#2,a0
				dbra	d0,.clamp_loop

				rts

				ENDIF

