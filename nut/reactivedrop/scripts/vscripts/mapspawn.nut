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

::McLog.Info( "─────────────────────────────────────────" );
::McLog.Info( "  Mapspawn Combiner  registry v" + ::McRegistry.version );
::McLog.Info( "  Author: typical russian (https://steamcommunity.com/id/w_asd/)" );
::McLog.Info( "─────────────────────────────────────────" );

// Порядок = порядок раздачи. admin первым — чтобы им всегда можно было управлять остальными.
IncludeScript( "mapspawn_combiner/modules/admin/module_admin" );
IncludeScript( "mapspawn_combiner/modules/lang/module_lang" );
IncludeScript( "mapspawn_combiner/modules/tk_counter/module_tk_counter" );
IncludeScript( "mapspawn_combiner/modules/laser_pointer/module_laser_pointer" );
IncludeScript( "mapspawn_combiner/modules/weapon_kills/module_weapon_kills" );
IncludeScript( "mapspawn_combiner/modules/assburn/module_assburn" );
IncludeScript( "mapspawn_combiner/modules/legacy_chat/module_legacy_chat" );

// Файл настроек сервера (тихие флаги enabled — без OnEnable/OnDisable).
local _mcAdmin = ::McRegistry.FindModule( "admin" );
if ( _mcAdmin != null && ( "ApplySavedSettings" in _mcAdmin ) )
    _mcAdmin.ApplySavedSettings( true );

::McRegistry.ApplyConvars();
::McGameEvents.BindDispatchers();
::McThinkers.BindHooks();
