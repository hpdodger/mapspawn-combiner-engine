// always/thinker_hooks.nut
// Non-game-event VScript hooks that the engine resolves via
// CAlienSwarm::RunScriptFunctionInListenerScopes (root first, then challenge thinkers).
//
// Declared on the challenge thinker scope as NULL placeholders in
// asw_gamerules_vscript.cpp so they are NOT inherited from root (issue #138).
// Defining them here on root therefore runs for always-on without double-firing
// challenge modules.
//
// Hooks:
//   OnMissionStart()
//   OnGameplayStart()
//   UserConsoleCommand(player, value)   → modules: UserConsoleCommand({ player, value })
//   UserMenuSelect(player, slot)        → modules: UserMenuSelect({ player, slot })
//   OnTakeDamage_Alive_Any(...)         → ::AlwaysDispatchDamage (return overwrites damage)
//   AlterDeathMessage(...)              → last string returned by a module wins
//   OnReceivedTextMessage(client, player, text) → threaded string transform
//   Update()                            → via dedicated thinker entity (not ListenerScopes)
//   Cleanup                             → AlwaysDispatch on mission_success / mission_failed
//
// Expects always/registry.nut already loaded.

const ALWAYS_UPDATE_INTERVAL = 0.05;   // 20 Hz, same default as laser-pointer challenge Update

::AlwaysEnsureUpdateThinker <- function() {
    if ( ( "g_AlwaysThinker" in getroottable() )
        && ::g_AlwaysThinker != null
        && ::g_AlwaysThinker.IsValid() )
        return;

    local e = Entities.CreateByClassname( "info_target" );
    e.__KeyValueFromString( "targetname", "always_on_thinker" );
    e.ValidateScriptScope();
    local s = e.GetScriptScope();
    s.AlwaysUpdate <- function() {
        ::AlwaysDispatch( "Update" );
        return ALWAYS_UPDATE_INTERVAL;
    };
    AddThinkToEnt( e, "AlwaysUpdate" );
    ::g_AlwaysThinker <- e;
    printl( "[Always] Update thinker spawned (interval " + ALWAYS_UPDATE_INTERVAL + "s)" );
};

::AlwaysBindThinkerHooks <- function() {
    // ── lifecycle (no args) ──────────────────────────────────────────────────
    getroottable()["OnMissionStart"] <- function() {
        ::AlwaysDispatch( "OnMissionStart" );
    };

    getroottable()["OnGameplayStart"] <- function() {
        ::AlwaysDispatch( "OnGameplayStart" );
    };

    // ── scripted_user_func / menuselect ──────────────────────────────────────
    // Engine signature is two args; modules get one table (same idea as challenge combiner).
    getroottable()["UserConsoleCommand"] <- function( hPlayer, szValue ) {
        ::AlwaysDispatchEvent( "UserConsoleCommand", { player = hPlayer, value = szValue } );
    };

    getroottable()["UserMenuSelect"] <- function( hPlayer, slot ) {
        ::AlwaysDispatchEvent( "UserMenuSelect", { player = hPlayer, slot = slot } );
    };

    // ── damage (return value overwrites flDamage) ────────────────────────────
    getroottable()["OnTakeDamage_Alive_Any"] <- function( victim, inflictor, attacker, weapon, damage, damageType, ammoName ) {
        return ::AlwaysDispatchDamage( victim, inflictor, attacker, weapon, damage, damageType, ammoName );
    };

    // ── death message (return string to replace default FF death line) ───────
    getroottable()["AlterDeathMessage"] <- function( victim, inflictor, attacker, weapon, damage, damageType, ammoName ) {
        local result = null;
        foreach ( m in ::g_AlwaysModules ) {
            if ( !m.enabled || !( "AlterDeathMessage" in m ) )
                continue;
            try {
                local r = m.AlterDeathMessage( victim, inflictor, attacker, weapon, damage, damageType, ammoName );
                if ( typeof r == "string" )
                    result = r;
            } catch ( e ) {
                printl( "[Always] ERROR in " + m.name + ".AlterDeathMessage: " + e );
            }
        }
        return result;
    };

    // ── chat text transform (must return a string; engine skips non-cstring) ─
    getroottable()["OnReceivedTextMessage"] <- function( client, player, text ) {
        local result = text;
        foreach ( m in ::g_AlwaysModules ) {
            if ( !m.enabled || !( "OnReceivedTextMessage" in m ) )
                continue;
            try {
                local r = m.OnReceivedTextMessage( client, player, result );
                if ( typeof r == "string" )
                    result = r;
            } catch ( e ) {
                printl( "[Always] ERROR in " + m.name + ".OnReceivedTextMessage: " + e );
            }
        }
        return result;
    };

    // ── Update tick (own entity; challenge thinker Update is separate) ───────
    ::AlwaysEnsureUpdateThinker();

    // ── Cleanup convention on mission end (after game-event fan-out) ─────────
    foreach ( ev in [ "mission_success", "mission_failed" ] ) {
        local hook = "OnGameEvent_" + ev;
        local prev = null;
        if ( hook in getroottable() )
            prev = getroottable()[hook];
        local env = { prev = prev };
        getroottable()[hook] <- function( params ) {
            if ( this.prev != null )
                this.prev( params );
            ::AlwaysDispatch( "Cleanup" );
        }.bindenv( env );
    }

    printl( "[Always] thinker hooks bound (OnMissionStart/OnGameplayStart/UserConsoleCommand/UserMenuSelect/OnTakeDamage_Alive_Any/AlterDeathMessage/OnReceivedTextMessage/Update/Cleanup)" );
};
