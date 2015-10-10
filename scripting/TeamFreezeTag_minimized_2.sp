#include <sourcemod>
#include <sdktools>
#include <cstrike>

#define VERSION "3.1.7"
#define FREEZE_SOUND "physics/glass/glass_impact_bullet4.wav"
#define NADE_SOUND "weapons/debris3.wav"
#define BEACON_SOUND "buttons/blip1.wav"

new bool:g_bEnabled;
new UserMsg:g_umTextMsg;
new bool:g_bFrozen[MAXPLAYERS+1];
new Handle:g_hFrozenTimer[MAXPLAYERS+1];
new Handle:g_hBeaconTimer[MAXPLAYERS+1];
new g_iClientThaws[MAXPLAYERS+1];
new g_iTotalTs;
new g_iFrozenTs;
new g_iTotalCts;
new g_iFrozenCts;
new Handle:g_hScoreTimer;
new g_iThawsPerNade;
new g_iMaxNades;
new g_offsetOwnerEntity;
new g_offsetHealth;
new g_offsetAmmo;
new const g_iBlueColor[4] = {75, 75, 255, 255};
new g_BeamSprite;
new g_HaloSprite;
new g_GlowSprite;
new bool:g_bGameOver;

public Plugin:myinfo = {
	name = "freezetag",
	author = "",
	version = VERSION,
	description = "friendly game of tag",
	url = ""
};

public OnPluginStart() {
	CreateConVar("teamfreezetag_version", VERSION, "Team Freeze Tag Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	AutoExecConfig(true, "teamfreezetag");
	g_offsetOwnerEntity = FindSendPropOffs("CBaseCombatWeapon", "m_hOwnerEntity");
	g_offsetHealth = FindSendPropOffs("CCSPlayer", "m_iHealth");
	g_offsetAmmo = FindSendPropInfo("CCSPlayer", "m_iAmmo");
	g_umTextMsg = GetUserMessageId("TextMsg");
	HookUserMessage(g_umTextMsg, UserMessageHook, true);
	AddNormalSoundHook(NormalSHook:SoundsHook);
	HookEvent("round_start", EventRoundStart, EventHookMode_PostNoCopy);
	HookEvent("player_spawn", EventPlayerSpawn);
	HookEvent("player_hurt", EventPlayerHurt);
	HookEvent("hegrenade_detonate", EventHD);
	HookEvent("player_death", EventPlayerDeath);
	RegAdminCmd("sm_freezetag", CmdFreezeTag, ADMFLAG_RCON);
}

public OnMapStart() {
	if (g_bEnabled) {
		new maxent = GetMaxEntities(), String:sClassname[64];
		for (new i = MaxClients; i < maxent; i++)
			if (IsValidEdict(i) && 
			IsValidEntity(i) &&
			GetEdictClassname(i, sClassname, sizeof(sClassname)) &&
			((StrContains(sClassname, "func_bomb_target") != -1) ||
			(StrContains(sClassname, "func_hostage_rescue") != -1) ||
			(StrContains(sClassname, "func_buyzone") != -1)))
				AcceptEntityInput(i,"Disable");
	}
	g_BeamSprite = PrecacheModel("materials/sprites/laser.vmt");
	g_HaloSprite = PrecacheModel("materials/sprites/halo01.vmt");
	g_GlowSprite = PrecacheModel("sprites/blueglow2.vmt");
	PrecacheSound(FREEZE_SOUND);
	PrecacheSound(NADE_SOUND);
	PrecacheSound(BEACON_SOUND);
}

public Action:FrozenGoods(Handle:timer) {
	PrintHintTextToAll("Frozen Players: T- %i/%i CT- %i/%i", g_iFrozenTs, g_iTotalTs, g_iFrozenCts, g_iTotalCts);
}

public OnClientDisconnect(client) {
	if (g_bEnabled) {
		if (g_hFrozenTimer[client] != INVALID_HANDLE) {
			KillTimer(g_hFrozenTimer[client]);
			g_hFrozenTimer[client] = INVALID_HANDLE;
		}
		if (g_hBeaconTimer[client] != INVALID_HANDLE) {
			KillTimer(g_hBeaconTimer[client]);
			g_hBeaconTimer[client] = INVALID_HANDLE;
		}
		g_iClientThaws[client] = 0;
		CheckFrozen();
	}
}

public Action:CmdFreezeTag(client, args) {
	if (args != 1) {
		ReplyToCommand(client, "[SM] Usage: sm_freezetag <1/0>");
		return Plugin_Handled;
	}
	new String:sArg[8];
	GetCmdArg(1, sArg, sizeof(sArg));
	if (StringToInt(sArg) == 1) {
		if (!g_bEnabled) {
			g_bEnabled = true;
			if (g_hScoreTimer == INVALID_HANDLE)
				g_hScoreTimer = CreateTimer(1.0, FrozenGoods, _, TIMER_REPEAT);
			new maxent = GetMaxEntities(), String:sClassname[64];
			for (new i = MaxClients; i < maxent; i++)
				if (IsValidEdict(i) && 
				IsValidEntity(i) &&
				GetEdictClassname(i, sClassname, sizeof(sClassname)) &&
				((StrContains(sClassname, "func_bomb_target") != -1) ||
				(StrContains(sClassname, "func_hostage_rescue") != -1) ||
				(StrContains(sClassname, "func_buyzone") != -1)))
					AcceptEntityInput(i,"Disable");
			ServerCommand("mp_restartgame 1");
		}
	}
	else if (g_bEnabled) {
		g_bEnabled = false;
		if (g_hScoreTimer != INVALID_HANDLE) {
			KillTimer(g_hScoreTimer);
			g_hScoreTimer = INVALID_HANDLE;
		}
		for (new i = 1; i <= MaxClients; i++) {
			if (g_hFrozenTimer[i] != INVALID_HANDLE) {
				KillTimer(g_hFrozenTimer[i]);
				g_hFrozenTimer[i] = INVALID_HANDLE;
			}
			if (g_hBeaconTimer[i] != INVALID_HANDLE) {
				KillTimer(g_hBeaconTimer[i]);
				g_hBeaconTimer[i] = INVALID_HANDLE;
			}
		}
		new maxent = GetMaxEntities(), String:sClassname[64];
		for (new i = MaxClients; i < maxent; i++)
			if (IsValidEdict(i) &&
			IsValidEntity(i) &&
			GetEdictClassname(i, sClassname, sizeof(sClassname)) &&
			((StrContains(sClassname, "func_bomb_target") != -1) || 
			(StrContains(sClassname, "func_hostage_rescue") != -1) ||
			(StrContains(sClassname, "func_buyzone") != -1)))
				AcceptEntityInput(i,"Enable");
		ServerCommand("mp_restartgame 1");
	}
	return Plugin_Handled;
}

Setup(client) {
	g_bFrozen[client] = false;
	SetEntData(client, g_offsetHealth, 10000484); // looks like 100 in-game. thx exvel.
	SetEntityRenderColor(client, 255, 255, 255, 255);

	new pistol;
	if ((pistol = GetPlayerWeaponSlot(client, 1)) != -1) {  
		RemovePlayerItem(client, pistol);
		RemoveEdict(pistol);
	}
	FakeClientCommand(client, "use weapon_knife");

}

Freeze(client) {
	g_bFrozen[client] = true;
	new index;
	if ((index = GetPlayerWeaponSlot(client, 2)) != -1) {  
		RemovePlayerItem(client, index);
		RemoveEdict(index);
	}
	new nadeCount = GetEntData(client, g_offsetAmmo+(11*4));
	if (nadeCount == g_iMaxNades)
		SetEntData(client, g_offsetAmmo+(11*4), 1);
	else if ((index = GetPlayerWeaponSlot(client, 3)) != -1) {  
		RemovePlayerItem(client, index);
		RemoveEdict(index);
		SetEntData(client, g_offsetAmmo+(11*4), 0);
	}
	decl Float:vec[3];
	GetClientEyePosition(client, vec);
	EmitAmbientSound(FREEZE_SOUND, vec, _, _, _, 0.4);
	SetEntityGravity(client, 1.0);
	SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 0.0);
	SetEntityRenderColor(client, 0, 112, 160, 112);

	g_hBeaconTimer[client] = CreateTimer(1.0, BeaconGlow, client, TIMER_REPEAT);
	CheckFrozen();
}

UnFreeze(client) {
	g_bFrozen[client] = false;
	if (g_hFrozenTimer[client] != INVALID_HANDLE) {
		KillTimer(g_hFrozenTimer[client]);
		g_hFrozenTimer[client] = INVALID_HANDLE;
	}
	if (g_hBeaconTimer[client] != INVALID_HANDLE) {
		KillTimer(g_hBeaconTimer[client]);
		g_hBeaconTimer[client] = INVALID_HANDLE;
	}
	GivePlayerItem(client, "weapon_knife");
	decl Float:vec[3];
	GetClientEyePosition(client, vec);
	EmitAmbientSound("physics/glass/glass_impact_bullet4.wav", vec, _, _, _, 0.3);

	SetEntityRenderColor(client, 255, 255, 255, 255);
	CheckFrozen();
}

public Action:TimerThaw(Handle:timer, any:client) {
	g_hFrozenTimer[client] = INVALID_HANDLE;
	if (IsClientInGame(client) && IsPlayerAlive(client) && g_bFrozen[client])
		UnFreeze(client);
}

public Action:BeaconGlow(Handle:timer, any:client) {
	if (IsClientInGame(client) && IsPlayerAlive(client) && g_bFrozen[client]) {
		static Float:vec[3];
		GetClientAbsOrigin(client, vec);
		vec[2] += 47.1;
		TE_SetupGlowSprite(vec, g_GlowSprite, 1.0, 1.3, 500);
		TE_SendToAll();
		TE_SetupBeamRingPoint(vec, 37.7, 377.7, g_BeamSprite, g_HaloSprite, 0, 15, 0.7, 5.0, 0.0, g_iBlueColor, 10, 0);
		TE_SendToAll();
		EmitAmbientSound(BEACON_SOUND, vec, client, SNDLEVEL_RAIDSIREN, _, 0.4);
		return Plugin_Continue;
	}
	g_hBeaconTimer[client] = INVALID_HANDLE;
	return Plugin_Stop;
}

public EventHD(Handle:event, const String:name[],bool:dontBroadcast) {
	if (g_bEnabled) {
		decl Float:vec[3];
		vec[0] = GetEventFloat(event,"x");
		vec[1] = GetEventFloat(event,"y");
		vec[2] = GetEventFloat(event,"z");
		TE_SetupGlowSprite(vec, g_GlowSprite, 0.85, 4.4, 500);
		TE_SendToAll();
		TE_SetupBeamRingPoint(vec, 300.0, 10.0,  g_BeamSprite, g_HaloSprite, 0, 10, 0.6, 10.0, 0.5, g_iBlueColor, 8, 0);
		TE_SendToAll();
		EmitAmbientSound(NADE_SOUND, vec, _, SNDLEVEL_RAIDSIREN, _, 0.9);
	}
}

public EventRoundStart(Handle:event,const String:name[],bool:dontBroadcast) {
	if (g_bEnabled) {
		g_bGameOver = false;
		PrintToChatAll("\x04Team FreezeTag Enabled! \x03Freeze All Enemies To Win The Round!!!");
		new maxEntities = GetMaxEntities();
		decl String:sClassname[64];
		for (new i = MaxClients; i < maxEntities; i++)
			if (IsValidEdict(i) &&
			IsValidEntity(i) &&
			GetEdictClassname(i, sClassname, sizeof(sClassname)) &&
			(StrContains(sClassname, "item_") != -1 || StrContains(sClassname, "weapon_") != -1) &&  
			GetEntDataEnt2(i, g_offsetOwnerEntity) == -1)
				RemoveEdict(i);
		CheckFrozen();
	}
}

public EventPlayerSpawn(Handle:event, const String:name[],bool:dontBroadcast) {
	if (g_bEnabled) {
		new client = GetClientOfUserId(GetEventInt(event,"userid"));
		if (GetClientTeam(client) > 1)
			Setup(client);
	}
}

public EventPlayerHurt(Handle:event, const String:name[],bool:dontBroadcast) {
	if (g_bEnabled) {
		new victim = GetClientOfUserId(GetEventInt(event,"userid"));
		new attacker = GetClientOfUserId(GetEventInt(event,"attacker"));
		new damage = GetEventInt(event, "dmg_health");
		static String:sWeapon[32];
		GetEventString(event, "weapon", sWeapon, sizeof(sWeapon));
		SetEntData(victim, g_offsetHealth, 10000484);
		if (attacker != 0) {
			new victimTeam = GetClientTeam(victim);
			new attackerTeam = GetClientTeam(attacker);
			if (!g_bFrozen[victim] && (victimTeam != attackerTeam) && (damage > 35)) {
				Freeze(victim);

			}
			else if (g_bFrozen[victim] && (victimTeam == attackerTeam)) {
				if (!StrEqual(sWeapon, "hegrenade")) {
					UnFreeze(victim);
					if (++g_iClientThaws[attacker] >= g_iThawsPerNade) {
						new nadeCount = GetEntData(attacker, g_offsetAmmo+(11*4));
						if (GetPlayerWeaponSlot(attacker, 3) == -1)
							GivePlayerItem(attacker, "weapon_hegrenade");
						if (nadeCount < g_iMaxNades)
							SetEntData(attacker, g_offsetAmmo+(11*4), nadeCount+1);
						g_iClientThaws[attacker] = 0;
					}
				}
				else if (victim == attacker) {
					UnFreeze(victim);
					return;
				}

			}
		}
	}
}

public EventPlayerDeath(Handle:event,const String:name[],bool:dontBroadcast) {
	if (g_bEnabled) {
		new client = GetClientOfUserId(GetEventInt(event,"userid"));
		if (g_hFrozenTimer[client] != INVALID_HANDLE) {
			KillTimer(g_hFrozenTimer[client]);
			g_hFrozenTimer[client] = INVALID_HANDLE;
		}
		Dissolve(client);
		CheckFrozen();
	}
}

public Action:UserMessageHook(UserMsg:msg_id, Handle:bf, const players[], playersNum, bool:reliable, bool:init) {
	if (g_bEnabled) {
		decl String:message[256];
		BfReadString(bf, message, sizeof(message));
		if (StrContains(message, "teammate_attack") != -1)
			return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action:SoundsHook(clients[64],&numClients,String:sample[PLATFORM_MAX_PATH],&entity,&channel,&Float:volume,&level,&pitch,&flags) {
	if (g_bEnabled) {
		if ((StrContains(sample, "hegrenade/explode") != -1) ||
		(StrContains(sample, "player/death") != -1))
			return Plugin_Handled;
	}
	return Plugin_Continue;
}

Dissolve(client) {
	if (!IsValidEntity(client) || IsPlayerAlive(client))
		return;
	new ragdoll = GetEntPropEnt(client, Prop_Send, "m_hRagdoll");
	if (ragdoll<0)
		return;
	new String:dname[32], String:dtype[32];
	Format(dname, sizeof(dname), "dis_%d", client);
	Format(dtype, sizeof(dtype), "%d", 2);
	new ent = CreateEntityByName("env_entity_dissolver");
	if (ent != -1) {
		DispatchKeyValue(ragdoll, "targetname", dname);
		DispatchKeyValue(ent, "dissolvetype", dtype);
		DispatchKeyValue(ent, "target", dname);
		AcceptEntityInput(ent, "Dissolve");
		AcceptEntityInput(ent, "kill");
	}
}

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
				if (g_bFrozen[i])
					g_iFrozenTs++;
				}
				case 3: {
				g_iTotalCts++;
				if (g_bFrozen[i])
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
						if (g_bFrozen[i])
							UnFreeze(i);
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
						if (g_bFrozen[i])
							UnFreeze(i);
					case 3:
						ForcePlayerSuicide(i);
				}
			}
		}
		PrintToChatAll("\x03All \x04Counter-Terrorists \x03Have Been \x04Frozen!!!");
	}
}