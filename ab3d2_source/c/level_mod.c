#include <stdio.h>
#include "level_mod.h"


BOOL lmod_ParseLevelMessages(GMF_ChunkHeader const* pChunkHeader, GMF_Data* pGMFData)
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

GMF_Data* LMod_LoadFile(char const* filename)
{
    GMF_Header const lmod_Header = {
        .h_Ident.id_Value     = IDENT_TKGD,
        .h_SubFormat.id_Value = IDENT_LMOD,
        .h_Version            = {TKG_VERSION, TKG_REVISION}
    };
    return GMF_LoadFile(filename, &lmod_Header, lmod_Parsers);
}

