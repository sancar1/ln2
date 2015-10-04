#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <sdkhooks>
#include <clientprefs>

#pragma semicolon 1

// This will be used for checking which team the player is on before respawning them
#define SPECTATOR_TEAM 0

new bool:g_clientToggled[MAXPLAYERS + 1];
new bool:g_bPause[MAXPLAYERS + 1];
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
	//HookEvent("player_hurt", Event_OnPlayerHurt);												// hook for when a player takes damage
	HookEvent("player_death", Event_OnPlayerDeath);												// hook for when a player dies
}

public Action:ToggleFrozen(client, args){
	if(!g_clientToggled[client]){																// if player is not indicated as frozen
		PrintToChat(client, "[ToggleFrozen] Frozen status on.");								// let player know they have toggled frozen on
		g_clientToggled[client] = true;															// indicate player as frozen
	}
	else if(g_clientToggled[client]){															// if player is indicated as frozen
		PrintToChat(client, "[ToggleFrozen] Frozen status off.");								// let player know they have toggled frozen of
		g_clientToggled[client] = false;														// indicate player as unfrozen
	}
}

// - PlayerSpawn -
public Action:Event_OnPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid")); 								// get client info
	PrintToChatAll("[Event] %N Spawn.", client); 												// print to chat player has spawned
	
	if(client != 0 && g_clientToggled[client] == true) 											// if the player is indicated as frozen
	{	
		StripAllWeapons(client); 																// remove weapons from player
		TeleportEntity(client, g_clientOrigin[client], g_clientAngles[client], NULL_VECTOR); 	// teleport player to death location
		PrintToChatAll("[Event] %N is teleported to: %0.0f", client, g_clientOrigin[client]); 	// print to chat player is teleported
		FreezePlayer(client); 																	// freeze player in place
	}
	return Plugin_Continue;
}

stock StripAllWeapons(client)
{
	PrintToChatAll("%N weapons have been stripped.", client);
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

public void Event_OnPlayerHurt(Event event, const char[] name, bool dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new health = GetEventInt(event, "health");
	//new attackerId = GetEventInt(event, "attacker");
	//new attacker = GetClientOfUserId(attackerId);
	
	if(IsClientInGame(client) && health <= 1)
		{
			// && !IsPlayerAlive(client)
			PrintToChatAll("%N Health  is: %i", client, health);								// print to chat origin
			//SetEntityHealth(client, 100);
			StripAllWeapons(client);															// remove all weapons from player
			//GetClientAbsOrigin(client, g_clientOrigin[client]);								// get clients origin
			//GetClientAbsAngles(client, g_clientAngles[client]);								// get clients angles
			
			
			//TeleportEntity(client, g_clientOrigin[client], g_clientAngles[client], NULL_VECTOR);	// teleport player to hit location
			//PrintToChat(client, "%N Position is: %0.0f", attacker, g_clientOrigin[client]);	// print to player chat their position
		}
	PrintToChatAll("[Event] %N Hurt.", client);
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
				
				PrintToChatAll("%N Died at: %0.0f", client, g_clientOrigin[client]); 			// print to chat death origin
				
				g_clientToggled[client] = true; 												// indicate player is frozen
				g_bPause[client] = false;														// player is not currently frozen (need to remove this later)
				
				CS_RespawnPlayer(client);														// respawn player
			}
}

public OnClientDisconnect(client) {
	g_clientToggled[client] = false;															// reset specific client is unfrozen
}

public PauseMethod(client)
{
	if (g_bPause[client] == false && IsValidEntity(client))										// if player is not currently frozen (paused)
	{
		PrintToChatAll("%N is frozen!", client);												// print to chat player is frozen
		//g_bPause[client]=true;		
		/*decl Float:fVel[3];
		fVel[0] = 0.000000;
		fVel[1] = 0.000000;
		fVel[2] = 0.000000;
		SetEntPropVector(client, Prop_Data, "m_vecVelocity", fVel);
		SetEntityMoveType(client, MOVETYPE_NONE);*/
		
		SetEntityMoveType(client, MOVETYPE_NONE);												// set player move type to none
		SetEntityRenderColor(client, 0, 128, 255, 192);											// change the player model to blue

		//SetEntData(client, FindSendPropOffs("CBaseEntity", "m_CollisionGroup"), 2, 4, true);
	}
}

public FreezePlayer(client)
{
	decl Float:f_Velocity[3];																	// declare a float vector for velocity
	f_Velocity[0] = 0.0;																		// initialize float vector to 0.0
	f_Velocity[0] = 0.0;																		// initialize float vector to 0.0
	f_Velocity[0] = 0.0;																		// initialize float vector to 0.0
	if (g_bPause[client] == false && IsValidEntity(client))										// if player is not currently frozen (paused)
	{
		PrintToChatAll("%N is frozen!", client);												// print to chat player is frozen
		//SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 0.0); // makes player frozen in air
		SetEntityMoveType(client, MOVETYPE_NONE);												// set player move type to none
		SetEntPropVector(client,Prop_Data,"m_vecVelocity",f_Velocity);							// set player velocity to velocity vector
		SetEntityRenderColor(client, 0, 128, 255, 192);											// change the player model to blue
		
		g_Offset_CollisionGroup = FindSendPropOffs("CBaseEntity", "m_CollisionGroup");			// get the play collision info
		UnblockEntity(client, g_Offset_CollisionGroup);											// unblock player
	}
}

public UnFreezePlayer(client)
{
    SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 1.0);
    SetEntityRenderColor(client, 255, 255, 255, 255);
}  

stock UnblockEntity(client, cachedOffset)
{
	SetEntData(client, cachedOffset, 2, 4, true);
}