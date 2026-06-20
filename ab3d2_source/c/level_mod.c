#include <stdio.h>
#include "level_mod.h"
#include "devmode.h"
#include <proto/exec.h>

extern char const LMod_PropertiesFile[];

static BOOL lmod_ParseLevelMessages(GMF_ChunkHeader const* chunkHeaderPtr, GMF_Data* GMFDataPtr)
{
    printf(
        "\tlmod_ParseLevelMessages() %.*s\n",
        4, chunkHeaderPtr->ch_Ident.id_Text
    );

    LevelMessage* pMessage = (LevelMessage*)GMF_ChunkData(chunkHeaderPtr);

    while (pMessage->lm_ZoneID != (UWORD)ZONE_ID_LIST_END) {
        pMessage->lm_TextPtr = GMF_ResolveString(pMessage->lm_TextPtr, GMFDataPtr);
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
    LMod_Properties.lmod_LoadedPtr = GMF_LoadFile(LMod_PropertiesFile, &lmod_Header, lmod_Parsers);
    if (NULL == LMod_Properties.lmod_LoadedPtr) {
        LMod_Properties.lmod_PVSErrataPtr = NULL;
        dputs("No level modification properties loaded");
        return;
    }
    GMF_ChunkHeader const* chunkPtr = GMF_LocateChunk(LMod_Properties.lmod_LoadedPtr, IDENT_PVSD);
    LMod_Properties.lmod_PVSErrataPtr = chunkPtr ? GMF_ChunkData(chunkPtr) : NULL;
    dprintf("PVS Errata %p\n", LMod_Properties.lmod_PVSErrataPtr);

    chunkPtr = GMF_LocateChunk(LMod_Properties.lmod_LoadedPtr, IDENT_BCKD);
    LMod_Properties.lmod_BCKDErrataPtr = chunkPtr ? GMF_ChunkData(chunkPtr) : NULL;
}

void LMod_FreeModificationData(void)
{
    dputs("LMod_FreeModificationData()");
    if (LMod_Properties.lmod_LoadedPtr) {
        FreeVec((void*)LMod_Properties.lmod_LoadedPtr);
    }
    LMod_Properties.lmod_LoadedPtr = NULL;
    LMod_Properties.lmod_PVSErrataPtr = NULL;
    LMod_Properties.lmod_BCKDErrataPtr = NULL;
}
