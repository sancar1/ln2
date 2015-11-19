#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <sdkhooks>
#include <clientprefs>
#include <colors>

#pragma semicolon 1

// This will be used for checking which team the player is on before respawning them
#define SPECTATOR_TEAM 0
#define DEFAULT_TIMER_FLAGS TIMER_FLAG_NO_MAPCHANGE

#define WHITE 0x01
#define DARKRED 0x02
#define GREEN 0x04
#define YELLOW 0x09
#define DARKBLUE 0x0C


new g_iTotalTs;
new g_iFrozenTs;
new g_iTotalCts;
new g_iFrozenCts;
new bool:g_bRoundStarted = false;
new bool:g_bGameOver;
new bool:g_clientFrozen[MAXPLAYERS + 1];
new Float:g_clientOrigin[MAXPLAYERS + 1][3];
new Float:g_clientAngles[MAXPLAYERS + 1][3];

new g_Offset_CollisionGroup;

new iAmmoOffset = -1;
new iClip1Offset = -1;

new Handle:hOnSpawnTaser, bool:bOnSpawnTaser;
new Handle:hTaserProximity, Float:g_fTaserProximity;

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
	
	HookEvent("round_start"	, Event_RoundStart	);												// hook for when round starts
	HookEvent("round_end"	, Event_RoundEnd	);												// hook for when round ends
	HookEvent("player_spawn", Event_OnPlayerSpawn);												// hook for when a player spawns
	HookEvent("player_death", Event_OnPlayerDeath);												// hook for when a player dies
	HookEvent("weapon_fire", Event_WeaponFire);													// hook for when player fires weapon
	
	hOnSpawnTaser = CreateConVar("sm_ln2_taser", "1", "On/Off free taser on spawn.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	hTaserProximity = CreateConVar("sm_ln2_proximity", "7.5", "Proximity Distance to Unfreeze Player. Multiples of 100.", FCVAR_NOTIFY, true, 1.0, true, 30.0);
	
	bOnSpawnTaser = GetConVarBool(hOnSpawnTaser);
	g_fTaserProximity = GetConVarFloat(hTaserProximity);
	
	HookConVarChange(hTaserProximity, OnConVarChange);
	HookConVarChange(hOnSpawnTaser, OnConVarChange);

	iAmmoOffset = FindSendPropInfo("CBasePlayer", "m_iAmmo");
	iClip1Offset = FindSendPropInfo("CWeaponTaser", "m_iClip1");
	
	AutoExecConfig(true, "ln2_commands");														// automatically read/create a ConVar configuration file
}

public OnConVarChange(Handle:hCvar, const String:oldValue[], const String:newValue[])
{
	if (hCvar == hOnSpawnTaser)
	{
		bOnSpawnTaser = bool:StringToInt(newValue);
	}
	
	else if (hCvar == hTaserProximity)
	{
		g_fTaserProximity = StringToFloat(newValue);
	}
}

//===================================================================================================================
// Events - Round Start -
public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	g_bGameOver = false;
	g_bRoundStarted = true;
}

// Events - Round End -
public Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	for (int i = 0; i < MaxClients; i++)
		g_clientFrozen[i] = false;
	g_bRoundStarted = false;
}


// Events - PlayerSpawn -
public Action:Event_OnPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid")); 								// get client info
	//PrintToChatAll("[Event] %N Spawn.", client); 												// print to chat player has spawned
	
	SDKUnhook(client, SDKHook_WeaponCanUse, OnWeaponCanUse);
	CreateTimer(0.1, Event_HandleSpawn, GetEventInt(event, "userid"));
	
	if(client != 0 && g_clientFrozen[client] == true) 											// if the player is indicated as frozen
	{
		//StripAllWeapons(client); 																// remove weapons from player
		StripWeapons(client);
		TeleportEntity(client, g_clientOrigin[client], g_clientAngles[client], NULL_VECTOR); 	// teleport player to death location
		//PrintToChatAll("[Event] %N is teleported to: %0.0f", client, g_clientOrigin[client]); 	// print to chat player is teleported
		CreateTimer(0.4, Timer_Freeze, client, DEFAULT_TIMER_FLAGS);							// freeze player in place
	}
	return Plugin_Continue;
}

// Events - PlayerDeath -
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
				
				CreateTimer(0.4, Respawn_Player, client, DEFAULT_TIMER_FLAGS);
				//CS_RespawnPlayer(client);														// respawn player
			}
}

// Events - HandleSpawn -
public Action:Event_HandleSpawn(Handle:timer, any:user_index)
{
	new client = GetClientOfUserId(user_index);
	if(!client)
	{
		return Plugin_Continue;
    }

	new client_team = GetClientTeam(client);
	if ((client_team > 1) && (bOnSpawnTaser))
	{
		GivePlayerItem(client, "weapon_taser");
	}
	return Plugin_Continue;
}

// Events - Weapon Fire -
public Event_WeaponFire(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(!client)
	{
		return Plugin_Continue;
    }

	new client_team = GetClientTeam(client);
	if(client_team > 1)
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
	return Plugin_Continue;
}

//===================================================================================================================

public Action:ToggleFrozen(client, args){
	if(!g_clientFrozen[client]){																// if player is not indicated as frozen
		PrintToChat(client, "[ToggleFrozen] Frozen status on.");								// let player know they have toggled frozen on
		g_clientFrozen[client] = true;															// indicate player as frozen
	}
	else if(g_clientFrozen[client]){															// if player is indicated as frozen
		PrintToChat(client, "[ToggleFrozen] Frozen status off.");								// let player know they have toggled frozen of
		g_clientFrozen[client] = false;															// indicate player as unfrozen
	}
	
	// Supress 'Unknown command' in client console
	return Plugin_Handled;
}

public Action:Respawn_Player(Handle:timer, any:value)
{
	new client = value & 0x7f;
	CS_RespawnPlayer(client);
}

public Action:Timer_Freeze(Handle:timer, any:value)
{
	new client = value & 0x7f;
	if (IsValidEntity(client) && IsClientInGame(client))				// if player is not currently frozen (paused)
	{
		//PrintToChatAll("%N Frozen at: %0.0f", client, g_clientOrigin[client]); 	
		//SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 0.0); 						// [old] makes player frozen
		SetEntityMoveType(client, MOVETYPE_NONE);													// freeze player
		//SetEntPropVector(client,Prop_Data,"m_vecVelocity",f_Velocity);							// set player velocity to velocity vector
		SetEntityRenderColor(client, 0, 128, 255, 192);	
		
		SetEntProp(client, Prop_Data, "m_takedamage", 0, 1);										// godmode frozen player
	
		SetEntProp(client, Prop_Send, "m_CollisionGroup", 1); 
		//g_Offset_CollisionGroup = FindSendPropOffs("CBaseEntity", "m_CollisionGroup");			// get the play collision info
		//UnblockEntity(client, g_Offset_CollisionGroup);
		ThirdPerson(client);																		// set player in thirdperson
		CheckFrozen();																			// check frozen players
	}
	return Plugin_Continue;
}

public UnFreezePlayer(client)
{
	ClientDefault(client);
	SDKUnhook(client, SDKHook_WeaponCanUse, OnWeaponCanUse);
	SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 1.0);
	SetEntityRenderColor(client, 255, 255, 255, 255);
	g_clientFrozen[client] = false;
	CheckFrozen();																			// check frozen players
}

public LookAtCheck(client)
{
	new lookingAtClient;
	new client_team = GetClientTeam(client);
	
	lookingAtClient = GetClientAimTarget(client, true);
	if(lookingAtClient >= 0)
	{
		new lookingAtClient_team = GetClientTeam(lookingAtClient);
		if (client_team == lookingAtClient_team && g_clientFrozen[lookingAtClient])
		{
			if(TaserProximityCheck(client, lookingAtClient))
			{
				SetEntityRenderMode(lookingAtClient, RENDER_TRANSCOLOR);
				SetEntityRenderColor(lookingAtClient, 255, 0, 0, 255);
				UnfreezeTaserTimer(lookingAtClient);
			}
		}
    }
}

public UnfreezeTaserTimer(lookingAtClient)
{
	UnFreezePlayer(lookingAtClient);
}

public OnClientDisconnect(client) {
	g_clientFrozen[client] = false;															// reset specific client is unfrozen
	CheckFrozen();																			// check frozen players
}

public Action:OnWeaponCanUse(client, weapon){ return Plugin_Handled; }

//===================================================================================================================
//Stock
stock ClientDefault(client)
{
	SetEntPropEnt(client, Prop_Send, "m_hObserverTarget", client);
	SetEntProp(client, Prop_Send, "m_iObserverMode", 0);
	SetEntProp(client, Prop_Send, "m_bDrawViewmodel", 1);
	SetEntProp(client, Prop_Send, "m_iFOV", 90);
	
	SetEntityMoveType(client, MOVETYPE_WALK);
	DispatchKeyValue(client, "targetname", "");
	SetEntProp(client, Prop_Data, "m_takedamage", 2, 1);
	
	SetEntityGravity(client,1.0);
	SetEntityRenderMode(client,RENDER_NORMAL);
	SetEntityRenderColor(client, 255, 255, 255, 255);
}

stock UnblockEntity(client, cachedOffset)
{
	SetEntData(client, cachedOffset, 2, 4, true);
}

stock TaserProximityCheck(client, lookingAtClient)
{
	g_fTaserProximity = g_fTaserProximity * 100;
	new Float:ClosestDistance = g_fTaserProximity;										// Taser Distance (750 default)
	GetClientAbsOrigin(client, g_clientOrigin[client]);								// get clients origin
	GetClientAbsOrigin(lookingAtClient, g_clientOrigin[lookingAtClient]);					// get lookingAtClients origin
	
	if(GetVectorDistance(g_clientOrigin[client], g_clientOrigin[lookingAtClient]) < ClosestDistance)
	{
		PrintToChat(client, "[%cFreezetag%c] %c%N%c is just right. Max Distance: %f", DARKRED,WHITE,GREEN, lookingAtClient, WHITE, ClosestDistance);
		return true;
	}
	else
	{
		PrintToChat(client, "[%cFreezetag%c] %c%N%c is too far away.", DARKRED,WHITE,GREEN, lookingAtClient, WHITE);
		return false;
	}
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

stock StripWeapons(client){
	if(!IsClientInGame(client) || !IsPlayerAlive(client)) return;
	for(int j = 0; j < 4; j++){
		int weapon = GetPlayerWeaponSlot(client, j);
		if(weapon != -1){
			RemovePlayerItem(client, weapon);
			RemoveEdict(weapon);						
		}
	}
	SDKHook(client, SDKHook_WeaponCanUse, OnWeaponCanUse);
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

stock StatusCheck(const client = 0){
	if (g_bRoundStarted)		return false
	if (!client) 				return true
	if (!IsClientInGame(client))return false
	if (!IsPlayerAlive(client)) return false
	return true
}

stock ThirdPerson(client){
	SetEntPropEnt(client, Prop_Send, "m_hObserverTarget", 0);
	SetEntProp(client, Prop_Send, "m_iObserverMode", 1);
	SetEntProp(client, Prop_Send, "m_bDrawViewmodel", 0);
	SetEntProp(client, Prop_Send, "m_iFOV", 120);
}

//===================================================================================================================
// End Round Check
CheckFrozen() {

	g_iTotalTs = 0;
	g_iFrozenTs = 0;
	g_iTotalCts = 0;
	g_iFrozenCts = 0;
	for (new i = 1; i <= MaxClients; i++) {
		if (IsClientInGame(i) && IsPlayerAlive(i)) {
			switch (GetClientTeam(i)) {
				case 2: {
				g_iTotalTs++;
				if (g_clientFrozen[i])
					g_iFrozenTs++;
				}
				case 3: {
				g_iTotalCts++;
				if (g_clientFrozen[i])
					g_iFrozenCts++;
				}
			}
		}
	}
	if (!g_bGameOver)
		WinCheck();
}

WinCheck() {

	if (g_iTotalTs <= g_iFrozenTs) {
		g_bGameOver = true;
		for (new i = 1; i <= MaxClients; i++) {
			if (IsClientInGame(i) && IsPlayerAlive(i)) {
				switch (GetClientTeam(i)) {
					case 2:
						ForcePlayerSuicide(i);
					case 3:
						if (g_clientFrozen[i])
							UnFreezePlayer(i);
				}
			}
		}
		PrintToChatAll("\x03All \x04Terrorists \x03Have Been \x04Frozen!!!");
	}
	else if (g_iTotalCts <= g_iFrozenCts) {
		g_bGameOver = true;
		for (new i = 1; i <= MaxClients; i++) {
			if (IsClientInGame(i) && IsPlayerAlive(i)) {
				switch (GetClientTeam(i)) {
					case 2:
						if (g_clientFrozen[i])
							UnFreezePlayer(i);
					case 3:
						ForcePlayerSuicide(i);
				}
			}
		}
		PrintToChatAll("\x03All \x04Counter-Terrorists \x03Have Been \x04Frozen!!!");
	}
}