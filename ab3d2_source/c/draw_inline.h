#ifndef DRAW_INLINE_H
#define DRAW_INLINE_H

/**
 * Reset the counters used to determine if the HUD has changed.
 */
static __inline void draw_ResetHUDCounters(void)
{
    draw_LastItemList =
    draw_LastItemSelected =
    draw_LastDisplayAmmoCount_w =
    draw_LastDisplayEnergyCount_w = 0xFFFF;
}

static __inline WORD draw_ScreenXPos(WORD xPos) {
    return xPos >= 0 ? xPos : Vid_ScreenWidth + xPos;
}

static __inline WORD draw_ScreenYPos(WORD yPos) {
    return yPos >= 0 ? yPos : Vid_ScreenHeight + yPos;
}

static __inline UWORD draw_PackItemSlots(const UWORD* itemSlots) {
    UWORD itemList = 0;
    for (UWORD i = 0; i < DRAW_NUM_WEAPON_SLOTS; ++i) {
        itemList |= (itemSlots[i]) ? (1 << i) : 0;
    }
    return itemList;
}


#define INIT_ITEMS() \
    const UWORD* itemSlots; \
    UWORD itemSelected; \
    UWORD itemList = 0; \
    if (Plr_MultiplayerType_b == MULTIPLAYER_SLAVE) { \
        itemSlots    = Plr2_Weapons_vb; \
        itemSelected = Plr2_TmpGunSelected_b; \
    } \
    else {\
        itemSlots    = Plr1_Weapons_vb; \
        itemSelected = Plr1_TmpGunSelected_b; \
    } \
    itemList = draw_PackItemSlots(itemSlots);


#endif // DRAW_INLINE_H
