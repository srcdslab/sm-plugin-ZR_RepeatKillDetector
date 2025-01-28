#if defined _zr_repeatkilldetector_included
    #endinput
#endif
#define _zr_repeatkilldetector_included

// Version information
#define ZR_RKD_V_MAJOR   "1"
#define ZR_RKD_V_MINOR   "2"
#define ZR_RKD_V_PATCH   "0"

#define ZR_RKD_VERSION   ZR_RKD_V_MAJOR..."."...ZR_RKD_V_MINOR..."."...ZR_RKD_V_PATCH

/**
 * Checks if the repeat killer protection is currently enabled.
 *
 * @return          True if repeat killer protection is enabled, false otherwise
 */
native bool ZR_RepeatKillDetector_Enabled();

public SharedPlugin __pl_zr_repeatkilldetector = 
{
    name = "ZR_RepeatKillDetector",
    file = "zr_repeatkilldetector.smx",
#if defined REQUIRE_PLUGIN
    required = 1,
#else
    required = 0,
#endif
};

#if !defined REQUIRE_PLUGIN
public void __pl_zr_repeatkilldetector_SetNTVOptional()
{
    MarkNativeAsOptional("ZR_RepeatKillDetector_Enabled");
}
#endif
