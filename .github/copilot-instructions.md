# Copilot Instructions for ZR_RepeatKillDetector

## Repository Overview
This repository contains a SourcePawn plugin for SourceMod that implements repeat kill detection for Zombie Reloaded servers. The plugin automatically detects when players are being repeatedly killed by environmental hazards (trigger_hurt) and disables respawning for the current round to prevent exploitation.

**Key Features:**
- Automatic repeat kill detection via timing analysis
- Admin commands for manual control
- Multilingual support (EN, FR, ES, Chinese, Russian)
- Native function exports for integration with other plugins
- Integration with Zombie Reloaded plugin ecosystem

## Technical Environment
- **Language**: SourcePawn
- **Platform**: SourceMod 1.11.0+ (this project uses 1.11.0-git6934)
- **Build System**: SourceKnight (modern SourcePawn build tool)
- **Compiler**: SourcePawn compiler via SourceKnight
- **Dependencies**:
  - SourceMod 1.11.0+
  - MultiColors (chat colors)
  - ZombieReloaded (core ZR functionality)

## Project Structure
```
addons/sourcemod/
├── scripting/
│   ├── ZR_RepeatKillDetector.sp      # Main plugin source
│   └── include/
│       └── ZR_RepeatKillDetector.inc # Native function definitions
└── translations/
    └── ZR_RepeatKillDetector.phrases.txt # Translation phrases
```

**Build Configuration:**
- `sourceknight.yaml` - Build configuration and dependencies
- `.github/workflows/ci.yml` - Automated CI/CD pipeline
- Target output: `addons/sourcemod/plugins/ZR_RepeatKillDetector.smx`

## Code Style & Standards
**This plugin already follows most standards, maintain consistency:**

- **Pragmas**: Always use `#pragma semicolon 1` and `#pragma newdecls required`
- **Indentation**: Tabs (4 spaces equivalent)
- **Naming Conventions**:
  - Functions: PascalCase (`Event_PlayerDeath`, `ToggleRepeatKill`)
  - Variables: camelCase for locals, prefix globals with `g_`
  - Constants: UPPER_CASE with underscores
  - ConVars: prefix with `g_h` (e.g., `g_hRespawnDelay`)
- **Include order**: sourcemod, plugin-specific, third-party
- **Version format**: Use semantic versioning in include file (`#define ZR_RKD_VERSION`)

## Documentation Requirements
- **No plugin headers**: Don't add unnecessary header comments to .sp files
- **Native functions**: Document all natives in .inc files with:
  - Description of functionality
  - Parameter details with types
  - Return value information
  - Usage examples if complex
- **Complex logic**: Add inline comments for intricate algorithms
- **Translation keys**: Document new phrase keys in comments

## SourcePawn Best Practices
**Memory Management:**
- Use `delete` directly without null checks (modern SourcePawn handles this)
- Never use `.Clear()` on StringMap/ArrayList - causes memory leaks
- Use `delete` and recreate collections instead of clearing them
- Properly handle Handle cleanup in OnPluginEnd if needed

**Data Structures:**
- Prefer StringMap/ArrayList over arrays for dynamic data
- Use methodmaps for native function definitions
- Implement proper bounds checking for arrays

**Event Handling:**
- Use appropriate EventHookMode for each event type
- Unhook events in OnPluginEnd if necessary
- Validate client indices and entity validity

**SQL Operations (if added):**
- All SQL queries MUST be asynchronous
- Use transactions for multiple related queries
- Always escape user input and validate for SQL injection
- Use SourceMod's methodmap SQL API

**Performance:**
- Cache ConVar values and use change hooks
- Minimize operations in frequently called events (player_death, etc.)
- Avoid string operations in loops when possible
- Use efficient lookup methods (StringMap vs linear search)

## Build & Validation Process
**Local Development:**
1. Install SourceKnight: Follow SourceKnight documentation
2. Build: `sourceknight build` (builds all targets in sourceknight.yaml)
3. Output: Compiled .smx files in configured output directory

**CI/CD Pipeline:**
- Automatic building on push/PR via GitHub Actions
- Uses `maxime1907/action-sourceknight@v1` action
- Creates release packages with proper directory structure
- Includes translations and compiled plugins

**Testing:**
- Test on development server before deployment
- Verify all admin commands work with proper permissions
- Test translation keys in different languages
- Validate repeat kill detection timing logic
- Check integration with ZombieReloaded features

## Plugin-Specific Context
**Core Functionality:**
- `g_bBlockRespawn`: Global state controlling respawn blocking
- `g_fDeathTime[]`: Per-client death timestamps for timing analysis
- `g_fRepeatKillDetectThreshold`: Configurable threshold from ConVar

**Key Events:**
- `player_death`: Primary detection logic for trigger_hurt deaths
- `round_start`: Reset state for new rounds
- `ZR_OnClientInfected`: Track zombie spawn state
- `ZR_OnClientRespawn`: Block respawns when protection active

**Admin Commands:**
- `zr_killrepeator <0|1>`: Toggle protection manually
- `sm_rk`/`sm_rkoff`: Disable protection
- `sm_rkon`: Enable protection

**Configuration:**
- `zr_repeatkill_threshold`: Detection threshold (default 1.0 seconds)
- Integrates with `zr_respawn_delay` ConVar

## Integration Points
**ZombieReloaded Integration:**
- Uses ZR natives for respawning (`ZR_RespawnClient`)
- Hooks ZR forwards (`ZR_OnClientInfected`, `ZR_OnClientRespawn`)
- Respects ZR respawn conditions and zombie spawn states

**Exported Natives:**
- `ZR_RepeatKillDetector_Enabled()`: Returns current protection state
- Properly registered in AskPluginLoad2 with library registration

## Common Modification Patterns
**Adding New Detection Methods:**
1. Extend Event_PlayerDeath logic with additional weapon/damage checks
2. Consider performance impact of new checks
3. Update ConVars if new thresholds needed
4. Add translation phrases for new messages

**Expanding Admin Features:**
1. Add new commands following existing pattern (RegAdminCmd)
2. Use appropriate admin flags (ADMFLAG_BAN for server-affecting changes)
3. Add translation phrases and update Usage messages
4. Log admin actions with LogAction()

**Database Integration (if needed):**
1. Use methodmap Database/DBDriver
2. Implement async callbacks for all queries
3. Handle connection failures gracefully
4. Use transactions for related operations

## Version Control
- Use semantic versioning in ZR_RepeatKillDetector.inc
- Tag releases to trigger automatic GitHub releases
- Commit messages should clearly describe functional changes
- Keep plugin compatibility with minimum SourceMod version (1.11.0+)

## Performance Considerations
**Critical Performance Points:**
- `Event_PlayerDeath`: Called frequently, keep logic minimal
- String operations: Cache weapon strings, avoid repeated comparisons
- Client loops: Use proper bounds (1 to MaxClients, check IsClientInGame)
- Timer usage: This plugin avoids timers appropriately

**Optimization Opportunities:**
- Cache ConVar float values instead of repeated GetConVarFloat calls
- Use efficient client validation patterns
- Consider impact on server tick rate for any new features

## Debugging & Troubleshooting
**Common Issues:**
- ConVar not found: Ensure ZombieReloaded is loaded first
- Translation errors: Verify phrase keys exist in .phrases.txt
- Detection not working: Check threshold values and ZR respawn delay interaction
- Permission errors: Verify admin flags for commands

**Debug Tools:**
- LogAction for admin command usage
- PrintToServer for development debugging
- SourceMod error logs for native failures
- Server console for ConVar validation