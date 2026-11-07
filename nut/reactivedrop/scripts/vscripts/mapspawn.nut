// mapspawn.nut — вход модулей mapspawn combiner на каждой карте.
// Нужен: sv_mapspawn_nut_exec 1  (см. cfg/autoexec.cfg)
//
// Здесь только загрузка реестра/модулей и привязка хуков движка.
// Логику фич в этот файл не писать: новый modules/<name>/module_*.nut + IncludeScript.

if ( "McMapspawnLoaded" in getroottable() )
    return;
getroottable().McMapspawnLoaded <- true;

IncludeScript( "mapspawn_combiner/registry" );
IncludeScript( "mapspawn_combiner/game_events" );
IncludeScript( "mapspawn_combiner/thinker_hooks" );
IncludeScript( "mapspawn_combiner/i18n" );
IncludeScript( "mapspawn_combiner/hud" );

::McLog.Info( "─────────────────────────────────────────" );
::McLog.Info( "  Mapspawn Combiner  registry v" + ::McRegistry.version );
::McLog.Info( "  Author: typical russian (https://steamcommunity.com/id/w_asd/)" );
::McLog.Info( "─────────────────────────────────────────" );

// Хуки движка до модулей: если IncludeScript всё же оборвёт этот файл,
// чат и раздача уже живы. Модули, успевшие зарегистрироваться, работают.
::McGameEvents.BindDispatchers();
::McThinkers.BindHooks();

// Порядок = порядок раздачи. admin первым — чтобы им всегда можно было управлять остальными.
// Падение одного модуля не должно гасить остальные.
local McInclude = function( path ) {
    try {
        IncludeScript( path );
    } catch ( e ) {
        ::McLog.Err( "[MC] IncludeScript failed: " + path + " — " + e );
    }
};

McInclude( "mapspawn_combiner/modules/admin/module_admin" );
McInclude( "mapspawn_combiner/modules/lang/module_lang" );
McInclude( "mapspawn_combiner/modules/tk_counter/module_tk_counter" );
McInclude( "mapspawn_combiner/modules/laser_pointer/module_laser_pointer" );
McInclude( "mapspawn_combiner/modules/weapon_kills/module_weapon_kills" );
McInclude( "mapspawn_combiner/modules/achievements/module_achievements" );
McInclude( "mapspawn_combiner/modules/assburn/module_assburn" );
McInclude( "mapspawn_combiner/modules/grubrain/module_grubrain" );
McInclude( "mapspawn_combiner/modules/legacy_chat/module_legacy_chat" );
McInclude( "mapspawn_combiner/modules/detailed_death_message/module_detailed_death_message" );
McInclude( "mapspawn_combiner/modules/spec_lock/module_spec_lock" );

// Файл настроек сервера (тихие флаги enabled — без OnEnable/OnDisable).
try {
    local _mcAdmin = ::McRegistry.FindModule( "admin" );
    if ( _mcAdmin != null && ( "ApplySavedSettings" in _mcAdmin ) )
        _mcAdmin.ApplySavedSettings( true );
    ::McRegistry.ApplyConvars();
} catch ( e2 ) {
    ::McLog.Err( "[MC] ApplySavedSettings/ApplyConvars failed: " + e2 );
}
