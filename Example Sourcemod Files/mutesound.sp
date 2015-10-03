#pragma semicolon 1
public Plugin:myinfo =
{
	name = "mutesound",
	author = "Josh pls",
	description = "Fix to the annoying round sounds, and death sounds",
	version = "1.0",
	url = ""
};

public OnPluginStart()
{
	RegConsoleCmd("sm_music", Command_Music);
	HookEvent("player_death", PlayerDeath)
}

public Action:Command_Music(client, args)
{		
	CreateTimer(10.0, Timer_StopMusic, client, TIMER_REPEAT);
	PrintToChat(client, "Music Stopped", client);
	return Plugin_Handled;
}

public Action:PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	//new client = GetClientOfUserId(GetEventInt(event, "userid"));

	TriggerTimer(Timer_StopMusic);
		
	return Plugin_Handled;
}
 
public Action:Timer_StopMusic(Handle:timer, any:client)
{	
	ClientCommand(client, "playgamesound Music.StopAllExceptMusic");
	
	return Plugin_Continue;
}

public Action:PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	KillTimer(Timer_StopMusic);
}