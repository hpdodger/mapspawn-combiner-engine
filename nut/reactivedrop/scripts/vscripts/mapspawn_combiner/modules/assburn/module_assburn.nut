// mapspawn_combiner/modules/assburn/module_assburn.nut
// Чат-команда !assburn — косметический огонь/дым сзади у морпеха (backpack).
// Выключить: !am_disable assburn

if ( "AssburnModuleLoaded" in getroottable() ) {
    ::McLog.Info( "[MC] assburn: already loaded, skip" );
} else {
    getroottable().AssburnModuleLoaded <- true;

    local m = {
        name        = "assburn",
        enabled     = true,
        convars     = {},
        version     = "1.0.0",
        description = "Chat joke: !assburn — fire/smoke particles on the marine backpack.",
        requires_registry = 4,

        _CMD = "!assburn",
        _BURN_TIME = 4.0,
        _EFFECTS = [ "env_fire_small", "env_fire_small_smoke" ],

        function _spawnAssburn( hMarine ) {
            if ( hMarine == null || !hMarine.IsValid() )
                return;

            local burnTime = this._BURN_TIME;
            local vecAss = hMarine.GetOrigin()
                - hMarine.GetForwardVector() * 12.0
                + Vector( 0, 0, 18 );

            foreach ( name in this._EFFECTS ) {
                local hFx = Entities.CreateByClassname( "info_particle_system" );
                if ( !hFx )
                    continue;

                hFx.__KeyValueFromString( "effect_name", name );
                hFx.__KeyValueFromString( "start_active", "1" );
                hFx.SetOrigin( vecAss );
                hFx.Spawn();
                hFx.Activate();
                hFx.SetParent( hMarine );
                hFx.SetLocalAngles( 0, 0, 0 );
                DoEntFire( "!self", "SetParentAttachmentMaintainOffset", "backpack", 0, hFx, hFx );
                DoEntFire( "!self", "Kill", "", burnTime, null, hFx );
            }
        },

        function OnGameEvent_player_say( params ) {
            if ( !( "text" in params ) || !( "userid" in params ) )
                return;
            local text = params["text"];
            if ( text == null )
                return;

            // /assburn → !assburn
            if ( text.len() > 0 && text.slice( 0, 1 ) == "/" )
                text = "!" + text.slice( 1 );

            local full = text.tolower();
            if ( full != this._CMD )
                return;

            local hCaller = GetPlayerFromUserID( params["userid"] );
            if ( !hCaller || !hCaller.IsValid() )
                return;

            local hMarine = hCaller.GetMarine();
            if ( !hMarine )
                return;

            this._spawnAssburn( hMarine );
        },
    };

    ::McRegistry.Register( m );
}
