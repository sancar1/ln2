#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <sdkhooks>
#include <clientprefs>

#pragma semicolon 1

// This will be used for checking which team the player is on before respawning them
#define SPECTATOR_TEAM 0
#define DEFAULT_TIMER_FLAGS TIMER_FLAG_NO_MAPCHANGE

new bool:g_clientFrozen[MAXPLAYERS + 1];
new Float:g_clientOrigin[MAXPLAYERS + 1][3];
new Float:g_clientAngles[MAXPLAYERS + 1][3];

new g_Offset_CollisionGroup;

/*
* A list of improvements to make:
* - When health is 0, strip and freeze
* - When frozen, can get stuck - just respawn when unfrozen!
* - Weapon drop on death (server-side command) - or strip weapon upon death and after spawn (might not work?)
* - 
*/

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
	RegConsoleCmd("sm_frozen", ToggleFrozen); 													// client command to force your frozen status
	HookEvent("player_spawn", Event_OnPlayerSpawn);												// hook for when a player spawns
	HookEvent("player_death", Event_OnPlayerDeath);												// hook for when a player dies
}

public Action:ToggleFrozen(client, args){
	if(!g_clientFrozen[client]){																// if player is not indicated as frozen
		PrintToChat(client, "[ToggleFrozen] Frozen status on.");								// let player know they have toggled frozen on
		g_clientFrozen[client] = true;															// indicate player as frozen
	}
	else if(g_clientFrozen[client]){															// if player is indicated as frozen
		PrintToChat(client, "[ToggleFrozen] Frozen status off.");								// let player know they have toggled frozen of
		g_clientFrozen[client] = false;															// indicate player as unfrozen
	}
}

// - PlayerSpawn -
public Action:Event_OnPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid")); 								// get client info
	//PrintToChatAll("[Event] %N Spawn.", client); 												// print to chat player has spawned
	
	if(client != 0 && g_clientFrozen[client] == true) 											// if the player is indicated as frozen
	{	
		StripAllWeapons(client); 																// remove weapons from player
		TeleportEntity(client, g_clientOrigin[client], g_clientAngles[client], NULL_VECTOR); 	// teleport player to death location
		PrintToChatAll("[Event] %N is teleported to: %0.0f", client, g_clientOrigin[client]); 	// print to chat player is teleported
		CreateTimer(0.4, Timer_Freeze, client, DEFAULT_TIMER_FLAGS);							// freeze player in place
	}
	return Plugin_Continue;
}

stock StripAllWeapons(client)
{
	//PrintToChatAll("%N weapons have been stripped.", client);
	new iEnt;
	for (new i = 0; i <= 5; i++)
	{
			iEnt = GetPlayerWeaponSlot(client, i);
			if(IsValidEntity(iEnt))
			{
				RemovePlayerItem(client, iEnt);
			}
	}
}

stock StripAllWeaponsExceptKnife(client)
{
	PrintToChatAll("%N weapons have been stripped.", client);
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
 
public void Event_OnPlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	//Get event info - Copied from respawn plugin
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	//new team = GetClientTeam(client);
	//new attackerId = GetEventInt(event, "attacker");
	//new attacker = GetClientOfUserId(attackerId);
   
	if(IsClientInGame(client) && IsValidEntity(client))											// if this is a valid player
			{
				GetClientAbsOrigin(client, g_clientOrigin[client]);								// get clients origin
				GetClientAbsAngles(client, g_clientAngles[client]);								// get clients angles
				
				//PrintToChatAll("%N Died at: %0.0f", client, g_clientOrigin[client]); 			// print to chat death origin
				g_clientFrozen[client] = true;
				
				CS_RespawnPlayer(client);														// respawn player
			}
}

public OnClientDisconnect(client) {
	g_clientFrozen[client] = false;															// reset specific client is unfrozen
}

public UnFreezePlayer(client)
{
    SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 1.0);
    SetEntityRenderColor(client, 255, 255, 255, 255);
} 

public Action:Timer_Freeze(Handle:timer, any:value)
{
	new client = value & 0x7f;
	if (IsValidEntity(client) && IsClientInGame(client))				// if player is not currently frozen (paused)
	{
		PrintToChatAll("%N Frozen at: %0.0f", client, g_clientOrigin[client]); 	
		SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 0.0); 						// makes player frozen
		//SetEntPropVector(client,Prop_Data,"m_vecVelocity",f_Velocity);							// set player velocity to velocity vector
		SetEntityRenderColor(client, 0, 128, 255, 192);	
		
		SetEntProp(client, Prop_Data, "m_takedamage", 0, 1);								// godmode frozen player
	
		SetEntProp(client, Prop_Send, "m_CollisionGroup", 1); 
		//g_Offset_CollisionGroup = FindSendPropOffs("CBaseEntity", "m_CollisionGroup");			// get the play collision info
		//UnblockEntity(client, g_Offset_CollisionGroup);
	}
	return Plugin_Continue;
}

stock UnblockEntity(client, cachedOffset)
{
	SetEntData(client, cachedOffset, 2, 4, true);
}