#include "game.h"
#include "message.h"
#include <proto/exec.h>
#include <dos/dos.h>
#include <proto/dos.h>
#include <stdio.h>

extern char const               game_ProgressFile[];
extern Game_ModProperties       game_ModProps;
extern Game_PlayerProgression   game_PlayerProgression;
extern ULONG                    Game_ProgressSignal; // signal to check progress
extern Rule                     game_AchievementRules[];
extern Achievement*             game_AchievementsDataPtr;

extern Inventory                Plr1_Inventory;
extern Inventory                Plr2_Inventory;


void game_LoadPlayerProgression(void) {
    BPTR gameProgressFH = Open(game_ProgressFile, MODE_OLDFILE);
    if (DOSFALSE == gameProgressFH) {
        // Set the initial state of the player's inventory cap to the default for the game mod.
        CopyMem(
            &game_ModProps.gmp_MaxInventory,
            &game_PlayerProgression.gs_MaxInventory,
            sizeof(InventoryConsumables)
        );
        return;
    }

    LONG read = Read(gameProgressFH, &game_PlayerProgression, sizeof(game_PlayerProgression));
    if (read == sizeof(Game_PlayerProgression)) {
        // Overwrite the inventory cap with the player's progressed version
        CopyMem(
            &game_PlayerProgression.gs_MaxInventory,
            &game_ModProps.gmp_MaxInventory,
            sizeof(InventoryConsumables)
        );
    }
    Close(gameProgressFH);
}

void game_SavePlayerProgression(void) {
    BPTR gameProgressFH = Open(game_ProgressFile, MODE_READWRITE);
    if (DOSFALSE == gameProgressFH) {
        return;
    }
    // Persist the progressed inventory limits
    CopyMem(
        &game_ModProps.gmp_MaxInventory,
        &game_PlayerProgression.gs_MaxInventory,
        sizeof(InventoryConsumables)
    );
    Write(gameProgressFH, &game_PlayerProgression, sizeof(game_PlayerProgression));
    Close(gameProgressFH);
}

static inline BOOL game_CheckAchieved(UWORD i) {
	return game_PlayerProgression.gs_Achieved[(i >> 3)] & (1 << (i & 7));
}

static inline BOOL game_MarkAchieved(UWORD i) {
	return game_PlayerProgression.gs_Achieved[(i >> 3)] |= (1 << (i & 7));
}

#define PARAM_WORD(w) ((w) >> 8),((w) & 0xFF)
#define PARAM_LONG(w) ((w) >> 24),(((w) >> 16) & 0xFF),(((w) >> 8) & 0xFF),((w) & 0xFF)

/**
 * Achievement test for killing a single alien class
 */
static BOOL game_AchievementRuleKillCount(Achievement const* achievement) {
    UWORD const * ac_Params = (UWORD const *)&(achievement->ac_RuleParams[0]);
    return game_PlayerProgression.gs_AlienKills[ac_Params[0]] >= ac_Params[1];
}

/**
 * Achievement test for killing a total of any group of alien classes
 */
static BOOL game_AchievementRuleGroupKillCount(Achievement const* achievement) {
    ULONG enemyMask = *(ULONG const*)&(achievement->ac_RuleParams[0]) & ((1 << NUM_ALIEN_DEFS) - 1);
    UWORD count     = *(UWORD const*)&(achievement->ac_RuleParams[sizeof(ULONG)]);

    UWORD total     = 0;

    for (UWORD id = 0; id < NUM_ALIEN_DEFS; ++id) {
        if (enemyMask && (1 << id)) {
            total += game_PlayerProgression.gs_AlienKills[id];
        }
        if (
            total >= count
        ) {
            return TRUE;
        }
    }
    return FALSE;
}

extern UWORD Plr1_Zone;
extern UWORD Game_LevelNumber;

static BOOL game_AchievementZoneFound(Achievement const* achievement) {
    ULONG levelAndZone = ((ULONG)Game_LevelNumber << 16) | Plr1_Zone;
    return levelAndZone == *(ULONG const*)&(achievement->ac_RuleParams[0]);
}

Rule game_AchievementRules[] = {
    game_AchievementRuleKillCount,
    game_AchievementRuleGroupKillCount,
    game_AchievementZoneFound,
};


/**
 *  Apply the reward for an achievement.
 *  TODO - multiplayer, figure out what we should be doing here...
 */
static void game_ApplyAchievementReward(Achievement const* achievement) {
    Msg_PushLine(achievement->ac_RewardDesc, MSG_TAG_OPTIONS|80);

    InventoryConsumables* player_ic = &Plr1_Inventory.inv_Consumables;

    // First, apply any cap modifications
    game_ModProps.gmp_MaxInventory.ic_Health      += achievement->ac_HealthCapBonus;
    game_ModProps.gmp_MaxInventory.ic_JetpackFuel += achievement->ac_FuelCapBonus;

    // Now any instant bonuses
    player_ic->ic_Health += achievement->ac_HealthBonus;

    if (
        achievement->ac_AmmoType > -1 &&
        achievement->ac_AmmoType < NUM_BULLET_DEFS
    ) {
        game_ModProps.gmp_MaxInventory.ic_AmmoCounts[achievement->ac_AmmoType] += achievement->ac_AmmoTypeCapBonus;
        player_ic->ic_AmmoCounts[achievement->ac_AmmoType] += achievement->ac_AmmoTypeBonus;
    }

    // Apply (updated) caps to inventory
    Game_ApplyInventoryLimits(&Plr1_Inventory);
}

void Game_UpdatePlayerProgress(void) {

    Achievement const* achievements = game_AchievementsDataPtr;

    for (UWORD id = 0; id < game_ModProps.gmp_NumAchievements; ++id) {
        if (
            !game_CheckAchieved(id) &&
            achievements[id].ac_Rule(&achievements[id])
        ) {
            Msg_PushLine(achievements[id].ac_Name, MSG_TAG_OPTIONS|80);
            if (achievements[id].ac_RewardDesc) {
                game_ApplyAchievementReward(&achievements[id]);
            }
            game_MarkAchieved(id);
        }
    }

    Game_ProgressSignal = 0;
}
