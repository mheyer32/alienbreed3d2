#include "system.h"
#include "game_properties.h"
#include <dos/dos.h>
#include <proto/dos.h>

extern Game_ModProperties game_ModProperties;

static void game_LoadModProperties(void);

void Game_InitDefaults(void)
{
    game_ModProperties.invLimits.maxHealth      = GAME_DEFAULT_HEALTH_LIMIT;
    game_ModProperties.invLimits.maxJetpackFuel = GAME_DEFAULT_FUEL_LIMIT;
    for (int i = 0; i < NUM_BULLET_DEFS; ++i) {
        game_ModProperties.invLimits.maxAmmoCounts[i] = GAME_DEFAULT_AMMO_LIMIT;
    }
    game_LoadModProperties();
}

void game_LoadModProperties()
{
    BPTR modPropsFH = Open(GAME_PROPERTIES_DATA_PATH, MODE_OLDFILE);
    if (DOSFALSE == modPropsFH) {
        return;
    }
    struct FileInfoBlock* modPropsFIB = (struct FileInfoBlock*)Sys_GetTemporaryWorkspace();
    ExamineFH(modPropsFH, modPropsFIB);

    if (
        modPropsFIB->fib_DirEntryType >= 0 ||
        modPropsFIB->fib_Size < (LONG)sizeof(Game_ModProperties)
    ) {
        return;
    }

    Game_ModProperties* tempProps = (Game_ModProperties*)Sys_GetTemporaryWorkspace();

    LONG bytesRead = Read(modPropsFH, tempProps, sizeof(Game_ModProperties));
    if (bytesRead == (LONG)sizeof(Game_ModProperties)) {
        if (tempProps->invLimits.maxHealth < GAME_UNCAPPED_LIMIT) {
            game_ModProperties.invLimits.maxHealth = tempProps->invLimits.maxHealth;
        }
        if (tempProps->invLimits.maxJetpackFuel < GAME_UNCAPPED_LIMIT) {
            game_ModProperties.invLimits.maxJetpackFuel = tempProps->invLimits.maxJetpackFuel;
        }

        for (int i = 0; i < NUM_BULLET_DEFS; ++i) {
            if (tempProps->invLimits.maxAmmoCounts[i] < GAME_UNCAPPED_LIMIT) {
                game_ModProperties.invLimits.maxAmmoCounts[i] = tempProps->invLimits.maxAmmoCounts[i];
            }
        }
    }
    Close(modPropsFH);
}
