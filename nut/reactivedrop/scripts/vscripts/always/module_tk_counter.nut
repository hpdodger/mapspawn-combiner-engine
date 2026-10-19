// always/module_tk_counter.nut
// Модуль счётчика тимкиллов для always-on шины.
// Реестр уже должен быть загружен mapspawn.
// Логика счётчика — в tk_counter/*.nut (в script scope worldspawn).

if ( "TkCounterLoaded" in getroottable() ) {
    printl( "[Always] tk_counter: already loaded, skip" );
} else {
    getroottable().TkCounterLoaded <- true;

    IncludeScript( "tk_counter/version" );

    printl( "─────────────────────────────────────────" );
    printl( "  TK Counter  v" + ::g_TkVersion + "  [always module]" );
    printl( "  Author: typical russian (https://steamcommunity.com/id/w_asd/)" );
    printl( "  type !tkc_help for more info" );
    printl( "─────────────────────────────────────────" );

    local hWorld = Entities.FindByClassname( null, "worldspawn" );
    hWorld.ValidateScriptScope();
    local scope = hWorld.GetScriptScope();
    IncludeScript( "tk_counter/tk_counter", scope );

    local m = {
        name        = "tk_counter",
        enabled     = true,
        convars     = {},
        version     = ::g_TkVersion,
        description = "Teamkill counter, ranks, !tkc commands.",
        requires_registry = 3,

        // Заполняется ниже перед AlwaysRegister: вложенные function
        // в VScript плохо держат внешние local, поэтому поле таблицы.
        _scope = null,

        function OnGameEvent_entity_killed( params ) {
            this._scope._OnEntityKilled( params );
        },

        function OnGameEvent_player_activate( params ) {
            if ( !( "userid" in params ) )
                return;
            local hPlayer = GetPlayerFromUserID( params["userid"] );
            if ( hPlayer )
                this._scope._OnPlayerActivate( hPlayer );
        },

        function OnGameEvent_player_say( params ) {
            this._scope._OnPlayerSay( params );
        },

        // Dispatch skips this module while disabled.
        function OnDisable() {
            printl( "[Always] tk_counter disabled (counting and !tkc paused)" );
        },

        function OnEnable() {
            printl( "[Always] tk_counter enabled" );
        },
    };

    m._scope = scope;
    ::AlwaysRegister( m );
}
