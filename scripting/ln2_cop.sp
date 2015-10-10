
public OnConVarChange(Handle:hCvar, const String:oldValue[], const String:newValue[])
{
	if (hCvar == hFreeTaser)
	{
		bFreeTaser = bool:StringToInt(newValue);
	}
	else if (hCvar == hInfTaser)
	{
		bInfTaser = bool:StringToInt(newValue);
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
	if ((client_team > 2) && (bFreeTaser))
		GivePlayerItem(client, "weapon_taser");
}

public Event_WeaponFire(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (bInfTaser)
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		if(!client)
			return;

		new client_team = GetClientTeam(client);
		if(client_team > 2)
		{
			new String: weapon[64];
			GetEventString(event, "weapon", weapon, sizeof(weapon));
			if(StrEqual("taser", weapon))
			{
				if (IsClientInGame(client) && IsPlayerAlive(client))
				{
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
}