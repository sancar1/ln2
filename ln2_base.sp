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
   int victim_id = event.GetInt("userid");
   int attacker_id = event.GetInt("attacker");
 
   int victim = GetClientOfUserId(victim_id);
   int attacker = GetClientOfUserId(attacker_id);
 
   /* CODE */
}