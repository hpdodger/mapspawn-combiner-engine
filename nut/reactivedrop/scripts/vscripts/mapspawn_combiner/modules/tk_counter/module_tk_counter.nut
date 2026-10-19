// mapspawn_combiner/modules/tk_counter/module_tk_counter.nut
// Подключает счётчик тимкиллов к реестру McRegistry.
// Реестр уже должен быть загружен mapspawn.
// Логика счётчика — в modules/tk_counter/*.nut (в script scope worldspawn).

if ( "TkCounterLoaded" in getroottable() ) {
    ::McLog.Info( "[MC] tk_counter: already loaded, skip" );
} else {
    getroottable().TkCounterLoaded <- true;

    IncludeScript( "mapspawn_combiner/modules/tk_counter/version" );

    local hWorld = Entities.FindByClassname( null, "worldspawn" );
    hWorld.ValidateScriptScope();
    local scope = hWorld.GetScriptScope();
    IncludeScript( "mapspawn_combiner/modules/tk_counter/tk_counter", scope );

    local m = {
        name        = "tk_counter",
        enabled     = true,
        convars     = {},
        version     = ::g_TkVersion,
        description = "Teamkill counter, ranks, !tkc commands.",
        requires_registry = 4,

        // Заполняется ниже перед Register: вложенные function
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
            ::McLog.Info( "[MC] tk_counter disabled (counting and !tkc paused)" );
        },

        function OnEnable() {
            ::McLog.Info( "[MC] tk_counter enabled" );
        },
    };

    m._scope = scope;
    ::McRegistry.Register( m );
}
