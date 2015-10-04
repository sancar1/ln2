#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <sdkhooks>
#include <clientprefs>

#pragma semicolon 1

// This will be used for checking which team the player is on before respawning them
#define SPECTATOR_TEAM 0

new bool:g_clientToggled[MAXPLAYERS + 1];
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
	HookEvent("player_spawn", Event_OnPlayerSpawn);
	//HookEvent("player_hurt", Event_OnPlayerHurt);
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
	PrintToChat(client, "[Event] Player Spawn.");
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(client != 0 && g_clientToggled[client] == true)
	{	
		PrintToChat(client, "[Event] Player Spawn - Frozen.");
		TeleportEntity(client, g_clientOrigin[client], g_clientAngles[client], NULL_VECTOR);
		StripAllWeapons(client);
	}
	return Plugin_Continue;
}

public PlayerSpawn(client)
{
	StripAllWeapons(client); //strip player weapons
	TeleportEntity(client, g_clientOrigin[client], g_clientAngles[client], NULL_VECTOR);
}

stock StripAllWeapons(client)
{
	PrintToChat(client, "%N weapons have been stripped.");
	
	new iEnt;
	for (new i = 0; i <= 5; i++)
	{
		if (i != 2)
			while ((iEnt = GetPlayerWeaponSlot(client, i)) != -1)
			{
				RemovePlayerItem(client, iEnt);
				RemoveEdict(iEnt);
			}
	}
}

public void Event_OnPlayerHurt(Event event, const char[] name, bool dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new attackerId = GetEventInt(event, "attacker");
	new attacker = GetClientOfUserId(attackerId);
	
	if(IsClientInGame(client) && IsClientInGame(client))
		{
			if(IsPlayerAlive(client) && IsPlayerAlive(client))
			{
				GetClientAbsOrigin(client, g_clientOrigin[client]);	// get clients origin
				GetClientAbsAngles(client, g_clientAngles[client]);	// get clients angles
				PrintToChat(client, "%N Position is: %0.0f", client, g_clientOrigin[client]);	// print to chat origin
				
				
				TeleportEntity(attacker, g_clientOrigin[client], g_clientAngles[client], NULL_VECTOR);
				PrintToChat(client, "%N Position is: %0.0f", attacker, g_clientOrigin[client]);	// print to chat origin
			}
		}
	PrintToChat(client, "[Event] Player Hurt.");
}
 
public void Event_OnPlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	PrintToChat(client, "[Event] Player Dead.");
	// Get event info - Copied from respawn plugin
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	//new team = GetClientTeam(client);
	//new attackerId = GetEventInt(event, "attacker");
	//new attacker = GetClientOfUserId(attackerId);
   
	if(IsClientInGame(client))
			{
				PrintToChat(client, "%N Position is: %0.0f", client, g_clientOrigin[client]);	// print to chat origin
				
				GetClientAbsOrigin(client, g_clientOrigin[client]);	// get clients origin
				GetClientAbsAngles(client, g_clientAngles[client]);	// get clients angles
				
				g_clientToggled[client] = true;
				CS_RespawnPlayer(client);	// respawn player
			}
   /* CODE */
}

public OnClientDisconnect(client){
	g_clientToggled[client] = false;
}
