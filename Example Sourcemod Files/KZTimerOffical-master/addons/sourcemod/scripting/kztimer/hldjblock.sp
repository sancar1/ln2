#pragma semicolon 1

#include <sdktools>
#include <sdkhooks>

#define CVAR_MUTETIME	    0
#define CVAR_NUM_CVARS	    1

public Plugin:myinfo = {
    name        = "hldjblock",
    author      = "Josh",
    description = "Blocks Hldj",
    version     = "1.0",
    url         = ""
};

new Handle:g_cvars[CVAR_NUM_CVARS];

public OnPluginStart() {
	g_cvars[CVAR_MUTETIME] = CreateConVar("sm_hldj_mutetime", "5", "How long should a player be muted for mic spam? (0 = Permanent Ban)", FCVAR_PLUGIN, true, 0.0);
	CreateTimer(1.0, Timer_CheckAudio, _, TIMER_REPEAT);
}

public Action:Timer_CheckAudio(Handle:timer, any:data)
	{
		for(new i = 1; i <= GetMaxClients(); i++)
			if(IsClientInGame(i))
				    QueryClientConVar(i, "voice_inputfromfile", ConVarQueryFinished:MICCheck, i);
	}

public MICCheck(QueryCookie:cookie, client, ConVarQueryResult:result, const String:cvarName[], const String:cvarValue[])
{
	if (IsClientInGame(client))
	{
		new voice_inputfromfile = StringToInt(cvarValue);    
		if (voice_inputfromfile == 1)
		{
			CreateTimer(3.0, MutePlayer, client, TIMER_FLAG_NO_MAPCHANGE);
		}		
	}
}

public Action:MutePlayer(Handle:Timer, any:client)
{
	if (IsClientInGame(client) && (GetClientListeningFlags(client) != VOICE_MUTED))
	{
		decl String:szReason[64];
		Format(szReason, 64, "[No HLDJ] You were muted due to excessive micspam.");
		ServerCommand("sm_mute #%d %d \"%s\"", GetClientUserId(client), GetConVarInt(g_cvars[CVAR_MUTETIME]), szReason);
		//KickClient(client, "%s", szReason);
	}
}