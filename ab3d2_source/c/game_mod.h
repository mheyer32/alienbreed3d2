#ifndef _TKG_GMOD_H_
#   define _TKG_GMOD_H_

#include "game_mod_common.h"

/*
 * These structures are managed by the assembler side and the alignment constraints are to preven the compiler
 * from padding them further for alignment purposes. It does not mean that the structures themselves are only
 * aligned to a 2 byte boundary,
 */
enum {
    IDENT_SPAB = 0x53504142,
    IDENT_RWRD = 0x52575244,
    IDENT_ACHV = 0x41434856,
};

/**
 * GMod_Reward
 *
 * Defines a reward structure, which applied modifications to player items and carry limits.
 */
typedef struct {
    char const* rwrd_Description;
    UWORD       rwrd_CarryOffset;
    UWORD       rwrd_ImmediateOffset;
    UWORD       rwrd_RewardData[1];
} ASM_ALIGN(sizeof(ULONG)) GMod_Reward; // Header only

/**
 * GMod_SpecialAmmoBonus
 *
 * Defines rewards associated with collecting of special ammo types.
 */
typedef struct {
    UWORD              spab_Index;
    UWORD              spab_AmmoID;
    GMod_Reward const* spab_Reward;
} ASM_ALIGN(sizeof(ULONG)) GMod_SpecialAmmoBonus; // 8 bytes

/**
 * GMod_Achievement
 *
 * Defines rewards associated with collecting of special ammo types.
 */
typedef struct {
    char const*        achv_Description;
    GMod_Reward const* achv_Reward;
    UWORD              achv_RuleType;
    UWORD              achv_Params[3];
} ASM_ALIGN(sizeof(ULONG)) GMod_Achievement; // 16 bytes

/**
 * GMod_WeaponAdjustment.wa_Flags
 */
#define WAF_NO_RUN            0x0001
#define WAF_NO_CROUCH         0x0002
#define WAF_NO_FLY            0x0004
#define WAF_NO_FIRE_SUBMERGED 0x0008

/**
 * Default definitions for the game modification. The pointers here will be initialised with either the
 * data from the loaded mod, some global definition, or NULL.
 *
 * Some data are not fixed size. Those include a corresponding counter.
 */
typedef struct {
    GMF_Data const*                 gmod_Loaded;
    InventoryConsumables const*     gmod_DefinedInventoryLimits;
    GMod_SpecialAmmoBonus const*    gmod_DefinedSpecialAmmoBonuses;
    GMod_WeaponAdjustment const*    gmod_DefinedWeaponAdjustments;
    GMod_Achievement const*         gmod_DefinedAchievements;
    ULONG                           gmod_NumDefinedSpecialAmmoBonuses;
    ULONG                           gmod_NumDefinedWeaponAdjustments;
    ULONG                           gmod_NumDefinedAchievements;
} GMod_DefaultProperties;

/**
 * GMod_Init()
 *
 * Attempts to load the Game Modification File and apply the settings
 */
extern void GMod_Init(void);

/**
 * GMod_Done()
 *
 * Releases any resources acquired by GMod_Init()
 */
extern void GMod_Done(void);

/**
 * GMod_ApplyReward()
 *
 * Applies the reward definition to the inventory limits and carry.
 */
extern void GMod_ApplyReward(
    GMod_Reward const* pReward,
    InventoryConsumables* pInventoryLimits,
    InventoryConsumables* pInventoryConsumables
);

#endif
