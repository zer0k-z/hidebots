#include <sourcemod>
#include <dhooks>

#pragma newdecls required
#pragma semicolon 1


public Plugin myinfo =
{
	name = "hidebots",
	author = "zer0.k",
	description = "Hide bots from server browser",
	version = "1.0.0",
	url = "https://github.com/zer0k-z/hidebots"
};

DynamicDetour gH_ConnectedDetour;
DynamicDetour gH_UpdateMasterServerPlayersDetour;

DynamicDetour gH_GetMasterServerPlayerCountsDetour;
DynamicDetour gH_GetNumFakeClientsDetour;
int gI_ClientOffset;

public void OnPluginStart()
{
	GameData gamedataConf = LoadGameConfigFile("hidebots.games");
	// Prevent the server from crashing.
	FindConVar("sv_parallel_sendsnapshot").SetBool(false);

	gI_ClientOffset = gamedataConf.GetOffset("ClientIndexOffset");
	if (gI_ClientOffset == -1)
	{
		SetFailState("Failed to get ClientIndexOffset offset.");
	}
	// These detours hide bots info from being sent to the master server.
	gH_UpdateMasterServerPlayersDetour = DynamicDetour.FromConf(gamedataConf, "CGameServer::UpdateMasterServerPlayers");

	if (gH_UpdateMasterServerPlayersDetour == INVALID_HANDLE)
	{
		SetFailState("Failed to find CGameServer::UpdateMasterServerPlayerse function signature");
	}

	if (!gH_UpdateMasterServerPlayersDetour.Enable(Hook_Pre, DHooks_OnUpdateMasterServerPlayers_Pre))
	{
		SetFailState("Failed to enable detour on CGameServer::UpdateMasterServerPlayers");
	}
	if (!gH_UpdateMasterServerPlayersDetour.Enable(Hook_Post, DHooks_OnUpdateMasterServerPlayers_Post))
	{
		SetFailState("Failed to enable detour on CGameServer::UpdateMasterServerPlayers");
	}

	gH_ConnectedDetour = DynamicDetour.FromConf(gamedataConf, "CGameClient::IsConnected");

	if (gH_ConnectedDetour == INVALID_HANDLE)
	{
		SetFailState("Failed to find CGameClient::IsConnected function signature");
	}

	// These detours hide bot number count from "status". Not too useful, but it's fine.
	gH_GetMasterServerPlayerCountsDetour = DynamicDetour.FromConf(gamedataConf, "CGameServer::GetMasterServerPlayerCounts");

	if (gH_GetMasterServerPlayerCountsDetour == INVALID_HANDLE)
	{
		SetFailState("Failed to find CGameServer::GetMasterServerPlayerCounts function signature");
	}

	if (!gH_GetMasterServerPlayerCountsDetour.Enable(Hook_Pre, DHooks_OnGetMasterServerPlayerCounts_Pre))
	{
		SetFailState("Failed to enable detour on CGameServer::GetMasterServerPlayerCounts");
	}
	if (!gH_GetMasterServerPlayerCountsDetour.Enable(Hook_Post, DHooks_OnGetMasterServerPlayerCounts_Post))
	{
		SetFailState("Failed to enable detour on CGameServer::GetMasterServerPlayerCounts");
	}

	gH_GetNumFakeClientsDetour = DynamicDetour.FromConf(gamedataConf, "CBaseServer::GetNumFakeClients");

	if (gH_GetNumFakeClientsDetour == INVALID_HANDLE)
	{
		SetFailState("Failed to find CBaseServer::GetNumFakeClients function signature");
	}
	delete gamedataConf;
}

public MRESReturn DHooks_OnUpdateMasterServerPlayers_Pre(Address pThis)
{
	PrintToServer("DHooks_OnUpdateMasterServerPlayers_Pre");
	if (!gH_ConnectedDetour.Enable(Hook_Pre, DHooks_OnClientConnectedCheck_Pre))
	{
		SetFailState("Failed to enable detour on CGameClient::IsConnected");
	}
	return MRES_Ignored;
}

public MRESReturn DHooks_OnUpdateMasterServerPlayers_Post(Address pThis)
{
	PrintToServer("DHooks_OnUpdateMasterServerPlayers_Post");
	if (!gH_ConnectedDetour.Disable(Hook_Pre, DHooks_OnClientConnectedCheck_Pre))
	{
		SetFailState("Failed to enable detour on CGameClient::IsConnected");
	}
	return MRES_Ignored;
}


public MRESReturn DHooks_OnClientConnectedCheck_Pre(Address pThis, DHookReturn hReturn)
{
	PrintToServer("DHooks_OnUpdateMasterServerPlayers_Pre");
	int client = LoadFromAddress(pThis + view_as<Address>(gI_ClientOffset), NumberType_Int32);
	PrintToServer("%i", client);
	if (!IsValidClient(client) || !IsFakeClient(client))
	{
		return MRES_Ignored;
	}
	DHookSetReturn(hReturn, false);
	return MRES_Supercede;
}

public MRESReturn DHooks_OnGetMasterServerPlayerCounts_Pre(Address pThis, DHookParam hParams)
{
	PrintToServer("DHooks_OnGetMasterServerPlayerCounts_Pre");
	if (!gH_GetNumFakeClientsDetour.Enable(Hook_Pre, DHooks_OnGetNumFakeClients_Pre))
	{
		SetFailState("Failed to enable detour on CGameClient::GetNumFakeClients");
	}
	return MRES_Ignored;
}

public MRESReturn DHooks_OnGetMasterServerPlayerCounts_Post(Address pThis, DHookParam hParams)
{
	if (!gH_GetNumFakeClientsDetour.Disable(Hook_Pre, DHooks_OnGetNumFakeClients_Pre))
	{
		SetFailState("Failed to enable detour on CGameClient::GetNumFakeClients");
	}
	return MRES_Ignored;
}

public MRESReturn DHooks_OnGetNumFakeClients_Pre(Address pThis, DHookReturn hReturn)
{
	PrintToServer("DHooks_OnGetNumFakeClients_Pre");
	DHookSetReturn(hReturn, 0);
	return MRES_Supercede;
}

stock bool IsValidClient(int client)
{
	return client >= 1 && client <= MaxClients && IsClientInGame(client) && !IsClientSourceTV(client);
}