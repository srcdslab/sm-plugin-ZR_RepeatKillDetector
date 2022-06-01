#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <zombiereloaded>
#include <multicolors>

#define PLUGIN_NAME "[ZR] Repeat Kill Detector"
#define WEAPONS_MAX_LENGTH 32
#define PLUGIN_VERSION "1.0.4"

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
}

public Action Event_PlayerDeath(Handle event, char[] name, bool dontBroadcast)
{
	if(g_bBlockRespawn)
		return;

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
}

public Action ZR_OnClientRespawn(int &client, ZR_RespawnCondition& condition)
{
	if(g_bBlockRespawn)
		return Plugin_Handled;

	return Plugin_Continue;
}