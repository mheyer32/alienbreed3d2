#include <stdio.h>
#include "level_mod.h"
#include "devmode.h"
#include <proto/exec.h>

extern char const LMod_PropertiesFile[];

static BOOL lmod_ParseLevelMessages(GMF_ChunkHeader const* pChunkHeader, GMF_Data* pGMFData)
{
    printf(
        "\tlmod_ParseLevelMessages() %.*s\n",
        4, pChunkHeader->ch_Ident.id_Text
    );

    LevelMessage* pMessage = (LevelMessage*)GMF_ChunkData(pChunkHeader);

    while (pMessage->lm_ZoneID != 0xFFFF) {
        pMessage->lm_Text = GMF_ResolveString(pMessage->lm_Text, pGMFData);
        ++pMessage;
    }

    return TRUE;
}

/**
 * Zero terminated list of custom parser functions for specific idents
 */
static GMF_ParserEntry lmod_Parsers[] = {
    { IDENT_ZMSG, lmod_ParseLevelMessages },
    { IDENT_OMSG, lmod_ParseLevelMessages },
    { 0, NULL },
};

/**
 * Level Modification File, LMOD
 */
static GMF_Header const lmod_Header = {
    .h_Ident.id_Value     = IDENT_TKGD,
    .h_SubFormat.id_Value = IDENT_LMOD,
    .h_Version            = {TKG_VERSION, TKG_REVISION}
};


/**********************************************************************************************************************/

void LMod_LoadModificationData(void)
{
    dputs("LMod_LoadModificationData()");
    LMod_Properties.lmod_Loaded = GMF_LoadFile(LMod_PropertiesFile, &lmod_Header, lmod_Parsers);
    if (NULL == LMod_Properties.lmod_Loaded) {
        LMod_Properties.lmod_PVSErrata = NULL;
        dputs("No level modification properties loaded");
        return;
    }
    GMF_ChunkHeader const* pChunk = GMF_LocateChunk(LMod_Properties.lmod_Loaded, IDENT_PVSD);
    LMod_Properties.lmod_PVSErrata = pChunk ? GMF_ChunkData(pChunk) : NULL;
    dprintf("PVS Errata %p\n", LMod_Properties.lmod_PVSErrata);

    pChunk = GMF_LocateChunk(LMod_Properties.lmod_Loaded, IDENT_BCKD);
    LMod_Properties.lmod_BCKDErrata = pChunk ? GMF_ChunkData(pChunk) : NULL;
}

void LMod_FreeModificationData(void)
{
    dputs("LMod_FreeModificationData()");
    if (LMod_Properties.lmod_Loaded) {
        FreeVec((void*)LMod_Properties.lmod_Loaded);
    }
    LMod_Properties.lmod_Loaded = NULL;
    LMod_Properties.lmod_PVSErrata = NULL;
    LMod_Properties.lmod_BCKDErrata = NULL;
}
