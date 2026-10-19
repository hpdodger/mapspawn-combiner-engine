// mapspawn.nut — вход always-on модулей на каждой карте.
// Нужен: sv_mapspawn_nut_exec 1  (см. cfg/autoexec.cfg)
//
// Здесь только загрузка реестра/модулей и привязка хуков движка.
// Логику фич в этот файл не писать: новый always/module_*.nut + IncludeScript.

if ( "AlwaysMapspawnLoaded" in getroottable() )
    return;
getroottable().AlwaysMapspawnLoaded <- true;

IncludeScript( "always/registry" );
IncludeScript( "always/game_events" );
IncludeScript( "always/thinker_hooks" );

printl( "─────────────────────────────────────────" );
printl( "  Always-on modules  registry v" + ::ALWAYS_REGISTRY_VERSION );
printl( "─────────────────────────────────────────" );

// Порядок = порядок раздачи. chat_admin первым — чтобы им всегда можно было управлять остальными.
IncludeScript( "always/module_chat_admin" );
IncludeScript( "always/module_tk_counter" );
// IncludeScript( "always/module_achievements" );

// Файл настроек сервера (тихие флаги enabled — без OnEnable/OnDisable).
local _alwaysAdmin = ::AlwaysFindModule( "chat_admin" );
if ( _alwaysAdmin != null && ( "ApplySavedSettings" in _alwaysAdmin ) )
    _alwaysAdmin.ApplySavedSettings( true );

::AlwaysApplyConvars();

::AlwaysBindGameEventDispatchers();
::AlwaysBindThinkerHooks();
