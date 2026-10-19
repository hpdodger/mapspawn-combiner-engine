// Always-on combiner — single mapspawn entrypoint for server-wide modules.
// Requires: sv_mapspawn_nut_exec 1  (see cfg/autoexec.cfg)
//
// This file only loads the registry and modules, then binds every VScript
// game event and thinker hook to the always-on bus. Do not put feature logic
// here. Add a new always/module_*.nut and IncludeScript it.

if ( "AlwaysMapspawnLoaded" in getroottable() )
    return;
getroottable().AlwaysMapspawnLoaded <- true;

IncludeScript( "always/registry" );
IncludeScript( "always/game_events" );
IncludeScript( "always/thinker_hooks" );

printl( "─────────────────────────────────────────" );
printl( "  Always-on combiner  registry v" + ::ALWAYS_REGISTRY_VERSION );
printl( "─────────────────────────────────────────" );

// Modules (order = dispatch order). Each self-registers via ::AlwaysRegister.
// chat_admin first so it is always present to manage the rest.
IncludeScript( "always/module_chat_admin" );
IncludeScript( "always/module_tk_counter" );
// IncludeScript( "always/module_achievements" );

// Re-apply server-wide always/settings.txt (silent enabled flags — no OnEnable/OnDisable).
local _alwaysAdmin = ::AlwaysFindModule( "chat_admin" );
if ( _alwaysAdmin != null && ( "ApplySavedSettings" in _alwaysAdmin ) )
    _alwaysAdmin.ApplySavedSettings( true );

::AlwaysApplyConvars();

// Game events: every unique g_ScriptGameEventList name → AlwaysDispatchEvent.
::AlwaysBindGameEventDispatchers();

// Thinker hooks: OnMissionStart, OnGameplayStart, UserConsoleCommand,
// UserMenuSelect, OnTakeDamage_Alive_Any, AlterDeathMessage,
// OnReceivedTextMessage, Update (own thinker), Cleanup on mission end.
::AlwaysBindThinkerHooks();
