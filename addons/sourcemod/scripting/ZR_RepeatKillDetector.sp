#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <zombiereloaded>
#include <ZR_RepeatKillDetector>
#include <multicolors>

#define WEAPONS_MAX_LENGTH 32

bool g_bBlockRespawn = false;
bool g_bZombieSpawned = false;

ConVar g_hRespawnDelay;
ConVar g_hCvar_RepeatKillDetectThreshold;

float g_fDeathTime[MAXPLAYERS+1];
float g_fRepeatKillDetectThreshold;

public Plugin myinfo = {
	name = "[ZR] Repeat Kill Detector",
	author = "GoD-Tony + BotoX + .Rushaway, Vauff",
	description = "Disables respawning on maps with repeat killers",
	version = ZR_RKD_VERSION,
	url = "http://www.sourcemod.net/"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	CreateNative("RepeatKillerEnabled", Native_RepeatKillerEnabled);
	RegPluginLibrary("ZR_RepeatKillDetector");
	return APLRes_Success;
}

public void OnPluginStart()
{
	RegAdminCmd("zr_killrepeator", Command_ForceRepeator, ADMFLAG_BAN, "Enable or Disable respawning for this round.");

	RegAdminCmd("sm_togglerepeatkill", Command_RkON, ADMFLAG_GENERIC, "Turns off the repeat killer detector if it is enabled");
	RegAdminCmd("sm_togglerk", Command_RkON, ADMFLAG_GENERIC, "Turns off the repeat killer detector if it is enabled");
	RegAdminCmd("sm_rk", Command_RkON, ADMFLAG_GENERIC, "Turns off the repeat killer detector if it is enabled");
	RegAdminCmd("sm_rkoff", Command_RkON, ADMFLAG_GENERIC, "Turns off the repeat killer detector if it is enabled");

	RegAdminCmd("sm_rkon", Command_RkOFF, ADMFLAG_BAN, "Turns on the repeat killer detector if it is disabled");
}

public void OnAllPluginsLoaded()
{
	if((g_hRespawnDelay = FindConVar("zr_respawn_delay")) == INVALID_HANDLE)
		SetFailState("Failed to find zr_respawn_delay cvar.");

	g_hCvar_RepeatKillDetectThreshold = CreateConVar("zr_repeatkill_threshold", "1.0", "Zombie Reloaded Repeat Kill Detector Threshold", 0, true, 0.0, true, 10.0);
	g_fRepeatKillDetectThreshold = GetConVarFloat(g_hCvar_RepeatKillDetectThreshold);
	HookConVarChange(g_hCvar_RepeatKillDetectThreshold, OnConVarChanged);

	HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Post);

	AutoExecConfig(true);
}

public void OnConVarChanged(ConVar CVar, const char[] oldVal, const char[] newVal)
{
	if(CVar == g_hCvar_RepeatKillDetectThreshold)
	{
		g_fRepeatKillDetectThreshold = GetConVarFloat(g_hCvar_RepeatKillDetectThreshold);
	}
}

stock void ToggleRepeatKill(int client, bool value)
{
	if (value && !g_bBlockRespawn)
	{
		g_bBlockRespawn = true;
		LogAction(client, -1, "[ZR] %L Enabled the Repeat killer protection. Disabling respawn for this round.", client);
		CPrintToChatAll("{green}[ZR]{default} Repeat killer detector force toggled on. Disabling respawn for this round.");
	}
	else
	{
		if (g_bBlockRespawn)
		{
			g_bBlockRespawn = false;
			LogAction(client, -1, "[ZR] %L %s the Repeat killer protection. \n[ZR] %s respawn for this round.", client, (value ? "Enabled" : "Disabled"), (value ? "Disabled" : "Enabled"));
			CPrintToChatAll("{green}[ZR]{default} Repeat killer detector force toggled off. Re-enabling respawn for this round.");
			RespawnAllClients();
		}
		else
		{
			CPrintToChat(client, "{green}[ZR]{default} Repeat killer is already turned off!");
		}
	}
}

public void OnClientDisconnect(int client)
{
	g_fDeathTime[client] = 0.0;
}

public Action Event_RoundStart(Handle event, char[] name, bool dontBroadcast)
{
	g_bBlockRespawn = false;
	g_bZombieSpawned =  false;
	return Plugin_Continue;
}

public Action Command_ForceRepeator(int client, int argc)
{
	if (argc < 1)
	{
		CReplyToCommand(client, "{green}[ZR] {default}Usage: zr_killrepeator {olive}<0|1>");
		CReplyToCommand(client, "{green}[ZR] {red}0 = Block respawn {default}| {green}1 = Allow respawn");
		return Plugin_Handled;
	}

	char sArgs[20];
	int value = -1;
	bool bValue;

	GetCmdArg(1, sArgs, sizeof(sArgs));

	bValue = sArgs[0] == '0' ? true : false;

	if(StringToIntEx(sArgs, value) == 0)
	{
		CReplyToCommand(client, "{green}[ZR]{default} Invalid Value.");
		return Plugin_Handled;
	}

	ToggleRepeatKill(client, bValue);

	return Plugin_Continue;
}

public Action Command_RkON(int client, int argc)
{
	ToggleRepeatKill(client, false);
	return Plugin_Handled;
}

public Action Command_RkOFF(int client, int argc)
{
	ToggleRepeatKill(client, true);
	return Plugin_Handled;
}

public Action Event_PlayerDeath(Handle event, char[] name, bool dontBroadcast)
{
	if(g_bBlockRespawn)
		return Plugin_Continue;

	char weapon[WEAPONS_MAX_LENGTH];
	GetEventString(event, "weapon", weapon, sizeof(weapon));

	int victim = GetClientOfUserId(GetEventInt(event, "userid"));
	int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));

	if(victim && !attacker && StrEqual(weapon, "trigger_hurt"))
	{
		float fGameTime = GetGameTime();

		if(fGameTime - g_fDeathTime[victim] - GetConVarFloat(g_hRespawnDelay) < g_fRepeatKillDetectThreshold)
		{
			CPrintToChatAll("{green}[ZR]{default} Repeat killer detected. Disabling respawn for this round.");
			g_bBlockRespawn = true;
		}

		g_fDeathTime[victim] = fGameTime;
	}
	return Plugin_Continue;
}

public Action ZR_OnClientInfect(int &client, int &attacker, bool &motherInfect, bool &respawnOverride, bool &respawn)
{
	if (motherInfect)
		g_bZombieSpawned = true;

	return Plugin_Continue;
}

public Action ZR_OnClientRespawn(int &client, ZR_RespawnCondition& condition)
{
	if(g_bBlockRespawn)
	{
		CReplyToCommand(client, "{green}[ZR] {default}Repeat killer detected. The respawn for this round is {olive}disabled{default}.");
		return Plugin_Handled;
	}

	return Plugin_Continue;
}

stock void RespawnAllClients()
{
	for (int i = 1; i < MaxClients; i++)
	{
		if(!IsClientInGame(i))
			continue;

		if(!IsPlayerAlive(i) && GetClientTeam(i) > 1)
			ZR_RespawnClient(i, g_bZombieSpawned ? ZR_Respawn_Zombie : ZR_Repsawn_Default);
	}
}

public int Native_RepeatKillerEnabled(Handle plugin, int params)
{
	return g_bBlockRespawn;
}
