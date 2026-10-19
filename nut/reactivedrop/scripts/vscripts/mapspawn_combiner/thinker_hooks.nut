// mapspawn_combiner/thinker_hooks.nut
// Служебные хуки движка (не game event): OnMissionStart, OnGameplayStart,
// UserConsoleCommand, UserMenuSelect, OnTakeDamage_Alive_Any, AlterDeathMessage,
// OnReceivedTextMessage, Update, Cleanup.
//
// Движок ищет такие функции сначала в корне VM, потом в скрипте активного
// челленджа. Здесь они объявляются в корне, чтобы модули mapspawn combiner
// получали вызовы при любом челлендже. У скрипта челленджа свои копии имён
// в своей области — один и тот же модуль дважды не вызывается.
//
// UserConsoleCommand / UserMenuSelect: движок передаёт два аргумента;
// модулям отдаётся одна таблица { player, value } / { player, slot }.
// OnTakeDamage_Alive_Any: return через McRegistry.DispatchDamage переписывает урон.
// AlterDeathMessage: побеждает последняя строка от модуля.
// OnReceivedTextMessage: строка проходит по цепочке модулей.
// Update: отдельная сущность mc_thinker (не через ListenerScopes).
// Cleanup: mission_success / mission_failed зовут его из явных хендлеров
// в game_events.nut (там же DispatchEvent) — без bindenv-обёрток.
//
// Нужен уже загруженный mapspawn_combiner/registry.nut.

::McThinkers <- {
    UPDATE_INTERVAL = 0.05,   // ~20 раз в секунду
    entity = null,

    function EnsureUpdateThinker() {
        if ( this.entity != null && this.entity.IsValid() )
            return;

        local e = Entities.CreateByClassname( "info_target" );
        e.__KeyValueFromString( "targetname", "mc_thinker" );
        e.ValidateScriptScope();
        local s = e.GetScriptScope();
        s.McThinkers_Update <- function() {
            ::McRegistry.Dispatch( "Update" );
            return ::McThinkers.UPDATE_INTERVAL;
        };
        AddThinkToEnt( e, "McThinkers_Update" );
        this.entity = e;
        printl( "[MC] Update thinker spawned (interval " + this.UPDATE_INTERVAL + "s)" );
    },

    function BindHooks() {
        getroottable()["OnMissionStart"] <- function() {
            ::McRegistry.Dispatch( "OnMissionStart" );
        };

        getroottable()["OnGameplayStart"] <- function() {
            ::McRegistry.Dispatch( "OnGameplayStart" );
        };

        getroottable()["UserConsoleCommand"] <- function( hPlayer, szValue ) {
            ::McRegistry.DispatchEvent( "UserConsoleCommand", { player = hPlayer, value = szValue } );
        };

        getroottable()["UserMenuSelect"] <- function( hPlayer, slot ) {
            ::McRegistry.DispatchEvent( "UserMenuSelect", { player = hPlayer, slot = slot } );
        };

        getroottable()["OnTakeDamage_Alive_Any"] <- function( victim, inflictor, attacker, weapon, damage, damageType, ammoName ) {
            return ::McRegistry.DispatchDamage( victim, inflictor, attacker, weapon, damage, damageType, ammoName );
        };

        getroottable()["AlterDeathMessage"] <- function( victim, inflictor, attacker, weapon, damage, damageType, ammoName ) {
            local result = null;
            foreach ( m in ::McRegistry.modules ) {
                if ( !m.enabled || !( "AlterDeathMessage" in m ) )
                    continue;
                try {
                    local r = m.AlterDeathMessage( victim, inflictor, attacker, weapon, damage, damageType, ammoName );
                    if ( typeof r == "string" )
                        result = r;
                } catch ( e ) {
                    printl( "[MC] ERROR in " + m.name + ".AlterDeathMessage: " + e );
                }
            }
            return result;
        };

        getroottable()["OnReceivedTextMessage"] <- function( client, player, text ) {
            local result = text;
            foreach ( m in ::McRegistry.modules ) {
                if ( !m.enabled || !( "OnReceivedTextMessage" in m ) )
                    continue;
                try {
                    local r = m.OnReceivedTextMessage( client, player, result );
                    if ( typeof r == "string" )
                        result = r;
                } catch ( e ) {
                    printl( "[MC] ERROR in " + m.name + ".OnReceivedTextMessage: " + e );
                }
            }
            return result;
        };

        this.EnsureUpdateThinker();

        printl( "[MC] thinker hooks bound" );
    },
};
