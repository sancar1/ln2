#pragma semicolon 1

#include <sdktools>
#include <sdkhooks>

public Plugin:myinfo = {
    name        = "hldjblock",
    author      = "Josh",
    description = "Blocks Hldj",
    version     = "1.0",
    url         = ""
};

public OnPluginStart() {
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
			CreateTimer(3.0, KickPlayer, client, TIMER_FLAG_NO_MAPCHANGE);
		}		
	}
}

public Action:KickPlayer(Handle:Timer, any:client)
{
	if (IsClientInGame(client))
	{
		decl String:szReason[64];
		Format(szReason, 64, "[No Hldj] Please set voice_inputfromfile to 0");
		KickClient(client, "%s", szReason);
	}
}