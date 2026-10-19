// always/thinker_hooks.nut
// Служебные хуки движка (не game event): OnMissionStart, OnGameplayStart,
// UserConsoleCommand, UserMenuSelect, OnTakeDamage_Alive_Any, AlterDeathMessage,
// OnReceivedTextMessage, Update, Cleanup.
//
// Движок ищет такие функции сначала в корне VM, потом в скрипте активного
// челленджа. Здесь они объявляются в корне, чтобы always-on модули получали
// вызовы при любом челлендже. У скрипта челленджа свои копии имён в своей
// области — один и тот же модуль дважды не вызывается.
//
// UserConsoleCommand / UserMenuSelect: движок передаёт два аргумента;
// модулям отдаётся одна таблица { player, value } / { player, slot }.
// OnTakeDamage_Alive_Any: return через AlwaysDispatchDamage переписывает урон.
// AlterDeathMessage: побеждает последняя строка от модуля.
// OnReceivedTextMessage: строка проходит по цепочке модулей.
// Update: отдельная сущность always_on_thinker (не через ListenerScopes).
// Cleanup: после раздачи mission_success / mission_failed.
//
// Нужен уже загруженный always/registry.nut.

const ALWAYS_UPDATE_INTERVAL = 0.05;   // ~20 раз в секунду

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
    getroottable()["OnMissionStart"] <- function() {
        ::AlwaysDispatch( "OnMissionStart" );
    };

    getroottable()["OnGameplayStart"] <- function() {
        ::AlwaysDispatch( "OnGameplayStart" );
    };

    getroottable()["UserConsoleCommand"] <- function( hPlayer, szValue ) {
        ::AlwaysDispatchEvent( "UserConsoleCommand", { player = hPlayer, value = szValue } );
    };

    getroottable()["UserMenuSelect"] <- function( hPlayer, slot ) {
        ::AlwaysDispatchEvent( "UserMenuSelect", { player = hPlayer, slot = slot } );
    };

    getroottable()["OnTakeDamage_Alive_Any"] <- function( victim, inflictor, attacker, weapon, damage, damageType, ammoName ) {
        return ::AlwaysDispatchDamage( victim, inflictor, attacker, weapon, damage, damageType, ammoName );
    };

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

    ::AlwaysEnsureUpdateThinker();

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
