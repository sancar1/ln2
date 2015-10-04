#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <sdkhooks>
#include <clientprefs>

#pragma semicolon 1

// This will be used for checking which team the player is on before respawning them
#define SPECTATOR_TEAM 0

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
   HookEvent("player_death", Event_PlayerDeath);
}
 
public void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{

	// Get event info - Copied from respawn plugin
	//new client = GetClientOfUserId(GetEventInt(event, "userid"));
	//new team = GetClientTeam(client);
	//new attackerId = GetEventInt(event, "attacker");
	//new attacker = GetClientOfUserId(attackerId);
	
   int victim_id = event.GetInt("userid");
   int attacker_id = event.GetInt("attacker");
 
   int victim = GetClientOfUserId(victim_id);
   int attacker = GetClientOfUserId(attacker_id);
   
   if(IsClientInGame(victim) && IsClientInGame(victim))
			{
				if(IsPlayerAlive(victim) && IsPlayerAlive(victim))
				{
					new Float:origin[3], Float:angles[3];
					GetClientAbsOrigin(victim, origin);
					GetClientAbsAngles(victim, angles);	
					
					CS_RespawnPlayer(victim);
					StripAllWeapons(victim); //strip player weapons
					
					TeleportEntity(victim, origin, angles, NULL_VECTOR);
				}
			}
 
   /* CODE */
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
			}
	}
	//if (GetPlayerWeaponSlot(client, 2) == -1)    //Give player a knife/weapon
	//	GivePlayerItem(client, "weapon_knife");
}
