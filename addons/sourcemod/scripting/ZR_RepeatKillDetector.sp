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
	CreateNative("ZR_RepeatKillDetector_Enabled", Native_RepeatKillerEnabled);
	RegPluginLibrary("ZR_RepeatKillDetector");
	return APLRes_Success;
}

public void OnPluginStart()
{
	LoadTranslations("ZR_RepeatKillDetector.phrases");
	
	RegAdminCmd("zr_killrepeator", Command_ForceRepeator, ADMFLAG_BAN, "Enable or Disable respawning for this round.");

	RegAdminCmd("sm_rk", Command_RkON, ADMFLAG_GENERIC, "Turns off the repeat killer detector if it is enabled");
	RegAdminCmd("sm_rkoff", Command_RkON, ADMFLAG_GENERIC, "Turns off the repeat killer detector if it is enabled");
	RegAdminCmd("sm_rkon", Command_RkOFF, ADMFLAG_BAN, "Turns on the repeat killer detector if it is disabled");
}

public void OnAllPluginsLoaded()
{
	if((g_hRespawnDelay = FindConVar("zr_respawn_delay")) == null)
		SetFailState("Failed to find zr_respawn_delay cvar.");

	g_hCvar_RepeatKillDetectThreshold = CreateConVar("zr_repeatkill_threshold", "1.0", "Zombie Reloaded Repeat Kill Detector Threshold", 0, true, 0.0, true, 10.0);
	g_fRepeatKillDetectThreshold = g_hCvar_RepeatKillDetectThreshold.FloatValue;
	g_hCvar_RepeatKillDetectThreshold.AddChangeHook(OnConVarChanged);

	HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Post);

	AutoExecConfig(true);
}

public void OnConVarChanged(ConVar CVar, const char[] oldVal, const char[] newVal)
{
	if(CVar == g_hCvar_RepeatKillDetectThreshold)
	{
		g_fRepeatKillDetectThreshold = g_hCvar_RepeatKillDetectThreshold.FloatValue;
	}
}

stock void ToggleRepeatKill(int client, bool value)
{
	if (value && !g_bBlockRespawn)
	{
		g_bBlockRespawn = true;
		LogAction(client, -1, "[ZR] %L Enabled the Repeat killer protection. Disabling respawn for this round.", client);
		CPrintToChatAll("{green}[ZR]{default} %t", "Repeat Killer Protection Enabled");
	}
	else
	{
		if (g_bBlockRespawn)
		{
			g_bBlockRespawn = false;
			LogAction(client, -1, "[ZR] %L %s the Repeat killer protection. \n[ZR] %s respawn for this round.", client, (value ? "Enabled" : "Disabled"), (value ? "Disabled" : "Enabled"));
			CPrintToChatAll("{green}[ZR]{default} %t", "Repeat Killer Protection Disabled");
			RespawnAllClients();
		}
		else
		{
			CPrintToChat(client, "{green}[ZR]{default} %t", "Repeat Killer Already Off");
		}
	}
}

public void OnClientDisconnect(int client)
{
	g_fDeathTime[client] = 0.0;
}

public Action Event_RoundStart(Event event, char[] name, bool dontBroadcast)
{
	g_bBlockRespawn = false;
	g_bZombieSpawned =  false;
	return Plugin_Continue;
}

public Action Command_ForceRepeator(int client, int argc)
{
	if (argc < 1)
	{
		CReplyToCommand(client, "{green}[ZR] {default}%t", "Usage");
		CReplyToCommand(client, "{green}[ZR] {red}%t", "Usage Values");
		return Plugin_Handled;
	}

	char sArgs[20];
	int value = -1;

	GetCmdArg(1, sArgs, sizeof(sArgs));

	if(StringToIntEx(sArgs, value) != strlen(sArgs))
	{
		CReplyToCommand(client, "{green}[ZR]{default} %t", "Invalid Value");
		return Plugin_Handled;
	}

	ToggleRepeatKill(client, value == 0);

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

public Action Event_PlayerDeath(Event event, char[] name, bool dontBroadcast)
{
	if(g_bBlockRespawn)
		return Plugin_Continue;

	char weapon[WEAPONS_MAX_LENGTH];
	event.GetString("weapon", weapon, sizeof(weapon));

	int victim = GetClientOfUserId(event.GetInt("userid"));
	int attacker = GetClientOfUserId(event.GetInt("attacker"));

	if(victim && !attacker && StrEqual(weapon, "trigger_hurt"))
	{
		float fGameTime = GetGameTime();

		if(fGameTime - g_fDeathTime[victim] - g_hRespawnDelay.FloatValue < g_fRepeatKillDetectThreshold)
		{
			CPrintToChatAll("{green}[ZR]{default} %t", "Repeat Killer Detected");
			g_bBlockRespawn = true;
		}

		g_fDeathTime[victim] = fGameTime;
	}
	return Plugin_Continue;
}

public void ZR_OnClientInfected(int client, int attacker, bool motherInfect, bool respawnOverride, bool respawn)
{
	if (motherInfect)
		g_bZombieSpawned = true;
}

public Action ZR_OnClientRespawn(int &client, ZR_RespawnCondition& condition)
{
	if(g_bBlockRespawn)
	{
		CReplyToCommand(client, "{green}[ZR] {default}%t", "Respawn Disabled");
		return Plugin_Handled;
	}

	return Plugin_Continue;
}

stock void RespawnAllClients()
{
	for (int i = 1; i <= MaxClients; i++)
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
