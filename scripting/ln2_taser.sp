#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <ln2_base>

#define PLUGIN_VERSION "1.0"

new iAmmoOffset = -1;
new iClip1Offset = -1;

new Handle:hOnSpawnTaser, bool:bOnSpawnTaser;

public Plugin:myinfo =
{
	name 		= "Unfreeze Taser",
	author 		= "Josh",
	description 	= "Unfreeze player with zues in freezetag.",
	version 		= PLUGIN_VERSION,
	url 			= ""
}

public OnPluginStart()
{
	hOnSpawnTaser = CreateConVar("sm_ln2_taser", "1", "On/Off free taser on spawn.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	bOnSpawnTaser = GetConVarBool(hOnSpawnTaser);

	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("weapon_fire", Event_WeaponFire);
	HookEvent("bullet_impact", Event_BulletImpact);

	HookConVarChange(hOnSpawnTaser, OnConVarChange);

	iAmmoOffset = FindSendPropInfo("CBasePlayer", "m_iAmmo");
	iClip1Offset = FindSendPropInfo("CWeaponTaser", "m_iClip1");
}

public OnConVarChange(Handle:hCvar, const String:oldValue[], const String:newValue[])
{
	if (hCvar == hOnSpawnTaser)
	{
		bOnSpawnTaser = bool:StringToInt(newValue);
	}
}

public Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	CreateTimer(0.1, Event_HandleSpawn, GetEventInt(event, "userid"));
}

public Action:Event_HandleSpawn(Handle:timer, any:user_index)
{
	new client = GetClientOfUserId(user_index);
	if (!client)
		return;

	new client_team = GetClientTeam(client);
	if ((client_team > 2) && (bOnSpawnTaser))
		GivePlayerItem(client, "weapon_taser");
}

public Event_WeaponFire(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(!client)
		return Plugin_Continue;

	new client_team = GetClientTeam(client);
	if(client_team > 2)
	{
		new String: weapon[64];
		GetEventString(event, "weapon", weapon, sizeof(weapon));
		if(StrEqual("taser", weapon))
		{
			if (IsClientInGame(client) && IsPlayerAlive(client))
			{
				LookAtCheck(client);
				
				new iWeapon;
				iWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
				if (IsValidEdict(iWeapon))
				{
 					if (iAmmoOffset)
						SetEntData(iWeapon, iClip1Offset, 2, _, true);
				}
			}
		}
	}
}

public LookAtCheck(client)
{
    new lookingAtClient;
	new client_team = GetClientTeam(client);
	
	lookingAtClient = GetClientAimTarget(client, true);
    if(lookingAtClient == -1)
	{
        PrintToChat(client, "[PlayerCheck] You aren't looking at the player right now.");
    }
    else if(lookingAtClient == -2)
	{
		PrintToChat(client, "[PlayerCheck] You already look at player which is not supported.");
    }
    else
	{
		new lookingAtClient_team = GetClientTeam(lookingAtClient);
		if (client_team == lookingAtClient_team)
		{
			PrintToChat(client, "[PlayerCheck] Player index you're looking at: \x03%d", lookingAtClient);
			PrintToChat(client, "[PlayerCheck] \x03Trying to set color for this player...");
			SetEntityRenderMode(lookingAtClient, RENDER_TRANSCOLOR);
			SetEntityRenderColor(lookingAtClient, 255, 0, 0, 255);
		}
    }
	UnfreezeTaserTimer(lookingAtClient);
}

public UnfreezeTaserTimer(lookingAtClient)
{
	UnfreezePlayer(lookingAtClient);
}