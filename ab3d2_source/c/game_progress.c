#include "game.h"
#include "message.h"
#include <proto/exec.h>
#include <dos/dos.h>
#include <proto/dos.h>


extern char const               game_ProgressFile[];
extern Game_ModProperties       game_ModProps;
extern Game_PlayerProgression   game_PlayerProgression;
extern ULONG                    Game_ProgressSignal; // signal to check progress

extern Inventory    Plr1_Inventory;
extern Inventory    Plr2_Inventory;

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

static BOOL game_AchievementRuleKillCount(Achievement const* achievement) {
    UWORD const * ac_Params = (UWORD const *)&(achievement->ac_RuleParams[0]);
    return game_PlayerProgression.gs_AlienKills[ac_Params[0]] >= ac_Params[1];
}

static BOOL game_AchievementRuleGroupKillCount(Achievement const* achievement) {
    ULONG enemyMask = *(ULONG const*)&(achievement->ac_RuleParams[0]) & ((1 << NUM_ALIEN_DEFS) - 1);
    UWORD count     = *(UWORD const*)&(achievement->ac_RuleParams[sizeof(ULONG)]);

    for (UWORD id = 0; id < NUM_ALIEN_DEFS; ++id) {
        if (
            enemyMask & (1 << id) &&
            game_PlayerProgression.gs_AlienKills[id] >= count
        ) {
            return TRUE;
        }
    }
    return FALSE;
}


/**
 * TODO - Incorporate this structure type into the mod properties with an ID in place of the rule, which will be
 *        swapped for the correct function pointer after loading up.
 */
Achievement test[] = {
    {
        // Kill 10 beasts
        "Achievement: Beast Bashin' (Pest control 10/200)",
        0,
        game_AchievementRuleKillCount,
        {PARAM_WORD(0),PARAM_WORD(10)}, // alien type, count
    },

    {
        // kill 50 beasts
        "Achievement: Alien Bleed (Pest control 50/200)",
        "Rewarded HP +50",
        game_AchievementRuleKillCount,
        {PARAM_WORD(0),PARAM_WORD(50)}, // alien type, count
        0,   // no health cap bonus
        50   // immediate health bonus
    },

    {
        // kill 100 beasts
        "Achievement: Endangered Species (Pest control 100/200)",
        0,
        game_AchievementRuleKillCount,
        {PARAM_WORD(0),PARAM_WORD(100)}, // alien type, count
    },

    {
        // Kill 200 beasts
        "Achievement: Xenocide (Pest control 200/200)",
        "Rewarded HP +100 / HP Cap +150",
        game_AchievementRuleKillCount,
        {PARAM_WORD(0),PARAM_WORD(200)}, // alien type, count
        150, // health cap bonus
        200, // immediate health bonus
    },

    {
        // Kill 10 security drones
        "Achievement: Light 'Em Up",
        0,
        game_AchievementRuleKillCount,
        {PARAM_WORD(14),PARAM_WORD(10)},
    },

    {
        // Kill 20 flying things
        "Achievement: Death From Below!",
        0,
        game_AchievementRuleGroupKillCount,
        {
            PARAM_LONG(    // alien type mask
                1 << 4  |
                1 << 7  |
                1 << 14 |
                1 << 15
            ),
            PARAM_WORD(20) // count
        },
    }
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

    // TODO - track ID range rather than all achievements
    //      - tag achivements by event type to speed up skipping

    for (UWORD id = 0; id < sizeof(test)/sizeof(Achievement); ++id) {
        if (
            !game_CheckAchieved(id) &&
            test[id].ac_Rule(&test[id])
        ) {
            Msg_PushLine(test[id].ac_Name, MSG_TAG_OPTIONS|80);
            if (test[id].ac_RewardDesc) {
                game_ApplyAchievementReward(&test[id]);
            }
            game_MarkAchieved(id);
        }
    }

    Game_ProgressSignal = 0;
}
