#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <sdkhooks>
#include <clientprefs>

#pragma semicolon 1

// This will be used for checking which team the player is on before respawning them
#define SPECTATOR_TEAM 0
#define TEAM_SPEC      1
#define TEAM_1         2
#define TEAM_2         3

public Plugin:myinfo = 
{
	name = "cimr_join",
	author = "Josh pls",
	description = "cimr_join",
	version = "1.0",
	url = "http://cimr.site.nfoservers.com/sourcebans/"
};

public OnPluginStart()
{
	// Register Console Commands
	RegConsoleCmd("sm_ct", ct, "Move your self to ct team", FCVAR_PLUGIN);
	RegConsoleCmd("sm_t", t, "Move your self to t team", FCVAR_PLUGIN);
}

public Action:t(target, args){

	if (!CheckClient(target)) return Plugin_Handled;

	//move the player to the spectator
	if (GetClientTeam(target) == 1)
	{
		ChangeClientTeam(target, 2);
		ForcePlayerSuicide(target);
	}
	return Plugin_Handled;
}

public Action:ct(target, args){

	if (!CheckClient(target)) return Plugin_Handled;

	//move the player to the spectator
	if (GetClientTeam(target) == 1)
	{
		ChangeClientTeam(target, 3);
		ForcePlayerSuicide(target);
	}
	return Plugin_Handled;
}

public bool:CheckClient(client)
{
	if ( !( 1 <= client <= MaxClients ) || !IsClientInGame(client) || IsFakeClient(client) )
	{
		return false;
	}
	return true;
}
