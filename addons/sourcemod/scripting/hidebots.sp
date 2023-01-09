#include <sourcemod>
#include <dhooks>

#pragma newdecls required
#pragma semicolon 1


public Plugin myinfo =
{
	name = "hidebots",
	author = "zer0.k",
	description = "Hide bots from server browser",
	version = "2.1.0",
	url = "https://github.com/zer0k-z/hidebots"
};

DynamicDetour gH_NotifyLocalClientConnectDetour;
DynamicDetour gH_GetMasterServerPlayerCountsDetour;
DynamicDetour gH_GetNumFakeClientsDetour;

public void OnPluginStart()
{
	GameData gamedataConf = LoadGameConfigFile("hidebots.games");

	gH_NotifyLocalClientConnectDetour = DynamicDetour.FromConf(gamedataConf, "CSteam3Server::NotifyLocalClientConnect");

	if (gH_NotifyLocalClientConnectDetour == INVALID_HANDLE)
	{
		SetFailState("Failed to find CSteam3Server::NotifyLocalClientConnect function signature");
	}

	if (!gH_NotifyLocalClientConnectDetour.Enable(Hook_Pre, DHooks_OnNotifyLocalClientConnect_Pre))
	{
		SetFailState("Failed to enable detour on CSteam3Server::NotifyLocalClientConnect");
	}

	gH_GetMasterServerPlayerCountsDetour = DynamicDetour.FromConf(gamedataConf, "CGameServer::GetMasterServerPlayerCounts");

	if (gH_GetMasterServerPlayerCountsDetour == INVALID_HANDLE)
	{
		SetFailState("Failed to find CSteam3Server::NotifyLocalClientConnect function signature");
	}

	if (!gH_NotifyLocalClientConnectDetour.Enable(Hook_Pre, DHooks_OnNotifyLocalClientConnect_Pre))
	{
		SetFailState("Failed to enable detour on CSteam3Server::NotifyLocalClientConnect");
	}
	delete gamedataConf;
}

public MRESReturn DHooks_OnNotifyLocalClientConnect_Pre(Address pThis, DHookReturn hReturn, DHookParam hParams)
{
	DHookSetReturn(hReturn, false);
	return MRES_Supercede;
}


public MRESReturn DHooks_OnGetMasterServerPlayerCounts_Pre(Address pThis, DHookParam hParams)
{
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
	DHookSetReturn(hReturn, 0);
	return MRES_Supercede;
}