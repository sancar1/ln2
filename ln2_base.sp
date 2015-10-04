#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <sdkhooks>
#include <clientprefs>

#pragma semicolon 1

// This will be used for checking which team the player is on before respawning them
#define SPECTATOR_TEAM 0

new bool:g_clientToggled[MAXPLAYERS+1];
new Float:g_clientOrigin[MAXPLAYERS + 1][3];
new Float:g_clientAngles[MAXPLAYERS + 1][3];


public Plugin:myinfo = 
{
	name = "ln2_base",
	author = "CopSaysPraiseAllLaw, JoshPls",
	description = "ln2",
	version = "1.0",
	url = "http://comingsoon.net/"
};

public void OnPluginStart()
{
	RegConsoleCmd("sm_frozen", ToggleFrozen); // client command to force your frozen status.
	HookEvent("player_spawned", Event_OnPlayerSpawn);
	HookEvent("player_death", Event_OnPlayerDeath);
}

public Action:ToggleFrozen(client, args){
	if(!g_clientToggled[client]){
		PrintToChat(client, "[ToggleFrozen] Frozen status on.");
		g_clientToggled[client] = true;
	}
	else if(g_clientToggled[client]){
		PrintToChat(client, "[ToggleFrozen] Frozen status off.");
		g_clientToggled[client] = false;
	}
}

// - PlayerSpawn -
public Action:Event_OnPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(client != 0 && g_clientToggled[client] == true)
	{	
		PlayerSpawn(client);
	}
	return Plugin_Continue;
}

public PlayerSpawn(client)
{
	StripAllWeapons(client); //strip player weapons
	PrintToChat(client, "%N Weapons were stripped.");
	TeleportEntity(client, g_clientOrigin[client], g_clientAngles[client], NULL_VECTOR);
}

stock StripAllWeapons(client)
{
	new iEnt;
	for (new i = 0; i <= 5; i++)
	{
		if (i != 2)
			while ((iEnt = GetPlayerWeaponSlot(client, i)) != -1)
			{
				RemovePlayerItem(client, iEnt);
				RemoveEdict(iEnt);
				PrintToChat(client, "%N weapons have been stripped.");
			}
	}
}
 
public void Event_OnPlayerDeath(Event event, const char[] name, bool dontBroadcast)
{

	// Get event info - Copied from respawn plugin
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	//new team = GetClientTeam(client);
	//new attackerId = GetEventInt(event, "attacker");
	//new attacker = GetClientOfUserId(attackerId);
   
   if(IsClientInGame(client) && IsClientInGame(client))
			{
				if(IsPlayerAlive(client) && IsPlayerAlive(client))
				{
					GetClientAbsOrigin(client, g_clientOrigin[client]);	// get clients origin
					GetClientAbsAngles(client, g_clientAngles[client]);	// get clients angles
					
					PrintToChatAll(client, "%N Position is: %0.0f", client, g_clientOrigin[client]);	// print to chat origin
					
					CS_RespawnPlayer(client);	// respawn player
					g_clientToggled[client] = true;
				}
			}
 
   /* CODE */
}

public OnClientDisconnect(client){
	g_clientToggled[client] = false;
}
