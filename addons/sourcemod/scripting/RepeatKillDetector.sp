#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <zombiereloaded>
#include <multicolors>

#define PLUGIN_NAME "[ZR] Repeat Kill Detector"
#define WEAPONS_MAX_LENGTH 32
#define PLUGIN_VERSION "1.1.0"

bool g_bBlockRespawn = false;

ConVar g_hRespawnDelay;
ConVar g_hCvar_RepeatKillDetectThreshold;

float g_fDeathTime[MAXPLAYERS+1];
float g_fRepeatKillDetectThreshold;

public Plugin myinfo = {
	name = PLUGIN_NAME,
	author = "GoD-Tony + BotoX + .Rushaway",
	description = "Disables respawning on maps with repeat killers",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
};

public void OnAllPluginsLoaded()
{
	if((g_hRespawnDelay = FindConVar("zr_respawn_delay")) == INVALID_HANDLE)
		SetFailState("Failed to find zr_respawn_delay cvar.");

	g_hCvar_RepeatKillDetectThreshold = CreateConVar("zr_repeatkill_threshold", "1.0", "Zombie Reloaded Repeat Kill Detector Threshold", 0, true, 0.0, true, 10.0);
	g_fRepeatKillDetectThreshold = GetConVarFloat(g_hCvar_RepeatKillDetectThreshold);
	HookConVarChange(g_hCvar_RepeatKillDetectThreshold, OnConVarChanged);

	CreateConVar("zr_repeatkill_version", PLUGIN_VERSION, PLUGIN_NAME, FCVAR_NOTIFY|FCVAR_DONTRECORD);
	HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Post);

	AutoExecConfig(true);

	RegAdminCmd("zr_killrepeator", Command_ForceRepeator, ADMFLAG_BAN, "Enable or Disable respawning for this round.");
}

public void OnConVarChanged(ConVar CVar, const char[] oldVal, const char[] newVal)
{
	if(CVar == g_hCvar_RepeatKillDetectThreshold)
	{
		g_fRepeatKillDetectThreshold = GetConVarFloat(g_hCvar_RepeatKillDetectThreshold);
	}
}

public void OnClientDisconnect(int client)
{
	g_fDeathTime[client] = 0.0;
}

public Action Event_RoundStart(Handle event, char[] name, bool dontBroadcast)
{
	g_bBlockRespawn = false;
	return Plugin_Continue;
}

public Action Command_ForceRepeator(int client, int argc)
{
	if (argc < 1)
	{
		CReplyToCommand(client, "{green}[ZR] {default}Usage: zr_killrepeator {olive}<value>\n{green}[ZR] {default}For {green}Enabling {default}Kill repeator use : {olive}zr_killrepeator 1\n{green}[ZR] {default}For {green}Disabling {default}Kill repeator use : {olive}zr_killrepeator 0");
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

	CShowActivity2(client, "{green}[ZR] {olive}", "{green}%s{default} the Repeat killer protection. %s respawn for this round.", (value ? "Enabled" : "Disabled"), (value ? "Disabled" : "Enabled"));
	LogAction(client, -1, "[ZR] %L %s the Repeat killer protection. \n[ZR]%s respawn for this round.", client, (value ? "Enabled" : "Disabled"), (value ? "Disabled" : "Enabled"));
	
	if(bValue)
		g_bBlockRespawn = false;
	else
		g_bBlockRespawn = true;

	return Plugin_Continue;
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

public Action ZR_OnClientRespawn(int &client, ZR_RespawnCondition& condition)
{
	if(g_bBlockRespawn)
	{
		CReplyToCommand(client, "{green}[ZR] {default}Repeat killer detected. The respawn for this round is {olive}disabled{default}.");
		return Plugin_Handled;
	}

	return Plugin_Continue;
}
