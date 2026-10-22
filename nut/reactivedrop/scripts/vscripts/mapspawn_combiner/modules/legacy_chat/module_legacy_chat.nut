// mapspawn_combiner/modules/legacy_chat/module_legacy_chat.nut
// Старые чат-команды из прежнего mapspawn.nut (!koopa, !cake, !dropnuke, …).
// Один модуль = прежний корневой OnGameEvent_player_say.
// Выключить: !am_disable legacy_chat

if ( "LegacyChatLoaded" in getroottable() ) {
    ::McLog.Info( "[MC] legacy_chat: already loaded, skip" );
} else {
    getroottable().LegacyChatLoaded <- true;

    local m = {
        name        = "legacy_chat",
        enabled     = true,
        convars     = {},
        version     = "1.0.0",
        description = "Legacy mapspawn chat commands (!koopa, !cake, !dropnuke, …).",
        requires_registry = 4,

        bCakeDone     = false,
        fLastNukeTime = 0.0,

        function OnGameEvent_player_say( params ) {
            if ( !( "text" in params ) || params["text"] == null )
                return;
            if ( !( "userid" in params ) || params["userid"] == null )
                return;

            local hCaller = GetPlayerFromUserID( params["userid"] );
            if ( !hCaller )
                return;

            local text = params["text"].tolower();

            // Admin: !setleader <name> (SteamID …20522390)
            if ( hCaller.GetNetworkIDString().slice( 10 ) == "20522390" ) {
                local argv = split( text, " " );
                local argc = argv.len();

                if ( argc >= 2 && argv[0] == "!setleader" ) {
                    local strName = argv[1];
                    local hPlayer = null;
                    while ( hPlayer = Entities.FindByClassname( hPlayer, "player" ) ) {
                        if ( hPlayer.GetPlayerName().tolower() == strName ) {
                            local hRes = Entities.FindByClassname( null, "asw_game_resource" );
                            if ( hRes )
                                NetProps.SetPropEntity( hRes, "m_Leader", hPlayer );
                            return;
                        }
                    }
                    ClientPrint( hCaller, 3, "no such player" );
                    return;
                }
            }

            switch ( text ) {
                case "!koopa": {
                    local hMarine = hCaller.GetMarine();
                    if ( hMarine ) {
                        local vecCross = NetProps.GetPropVector( hCaller, "m_vecCrosshairTracePos" );
                        local hGrub = Director.SpawnAlienAt( "asw_grub", vecCross, hMarine.GetAngles() );
                        hGrub.SetModelScale( 6, 0 );
                    }
                    return;
                }

                case "!dropnuke": {
                    local fNow = Time();
                    if ( fNow - this.fLastNukeTime < 10.0 ) {
                        local fLeft = 10.0 - ( fNow - this.fLastNukeTime );
                        ClientPrint( hCaller, 3, "Wait " + fLeft.tostring() + " sec." );
                        return;
                    }
                    this.fLastNukeTime = fNow;

                    local hMarine = hCaller.GetMarine();
                    if ( !hMarine )
                        hMarine = Entities.FindByClassname( null, "asw_marine" );

                    if ( hMarine ) {
                        DropStunGrenade( 100, 1000,
                            hMarine.GetOrigin() + hMarine.GetForwardVector() + Vector( 0, 0, 150 ) );
                    }
                    return;
                }

                case "!cake": {
                    if ( this.bCakeDone )
                        return;

                    local hPlayerCake = null;
                    while ( ( hPlayerCake = Entities.FindByClassname( hPlayerCake, "player" ) ) != null ) {
                        if ( hPlayerCake.GetNetworkIDString() == "STEAM_1:0:17639821" ) {
                            local hMarineCake = hPlayerCake.GetMarine();
                            if ( hMarineCake ) {
                                local hEntity = Entities.CreateByClassname( "prop_dynamic" );
                                hEntity.__KeyValueFromString( "model", "models/props/cake/cake.mdl" );
                                hEntity.SetOrigin( hMarineCake.GetOrigin() + Vector( 0, 0, 65 ) );
                                hEntity.SetParent( hMarineCake );
                                hEntity.Spawn();
                                this.bCakeDone = true;
                            }
                            return;
                        }
                    }
                    return;
                }

                case "!marechal":
                    ClientPrint( null, 3,
                        TextColor( 154, 205, 255 ) + "TheKoopaKing:" +
                        TextColor( 255, 255, 255 ) + " Marechal fucking liar bitch" );
                    return;

                case "!waterbear":
                    ClientPrint( null, 3,
                        TextColor( 154, 205, 255 ) + "Bear-Eating Fetus:" +
                        TextColor( 255, 255, 255 ) + " Hold W, flow like water, be Chinese" );
                    return;

                case "!vcute": {
                    local hTargetPlayer = null;
                    local p = null;
                    while ( ( p = Entities.FindByClassname( p, "player" ) ) != null ) {
                        if ( p.GetNetworkIDString() == "STEAM_1:0:42186506" ) {
                            hTargetPlayer = p;
                            break;
                        }
                    }
                    if ( hTargetPlayer == null )
                        return;

                    local hMarine = hTargetPlayer.GetMarine();
                    if ( !hMarine )
                        return;

                    hMarine.SetModelScale( 1.0, 0 );
                    hMarine.SetModelScale( 0.5, 10 );
                    return;
                }

                case "!hat": {
                    local hMarine = hCaller.GetMarine();
                    if ( !hMarine ) return;

                    local hHat = Entities.CreateByClassname( "prop_dynamic" );
                    if ( !hHat ) return;

                    hHat.__KeyValueFromString( "model", "models/aliens/parasite/parasite.mdl" );
                    hHat.__KeyValueFromInt( "solid", 0 );
                    hHat.SetOrigin( hMarine.GetOrigin() + Vector( -10, 0, 60 ) );
                    hHat.SetAngles( 0, 0, 0 );
                    hHat.SetParent( hMarine );
                    hHat.SetLocalAngles( 0, 0, 0 );
                    hHat.Spawn();
                    return;
                }

                case "!nohopa": {
                    local hMarine = hCaller.GetMarine();
                    if ( !hMarine ) return;

                    local offsets = [
                        Vector(  10,   0, 65 ),
                        Vector( -10,   0, 65 ),
                        Vector(   0, -10, 65 )
                    ];

                    foreach ( off in offsets ) {
                        local hNade = Entities.CreateByClassname( "asw_rifle_grenade" );
                        if ( !hNade ) continue;

                        hNade.SetOrigin( hMarine.GetOrigin() + off );
                        hNade.SetAngles( 0, 0, 0 );
                        hNade.Spawn();
                        hNade.SetParent( hMarine );

                        NetProps.SetPropInt( hNade, "m_MoveType", 0 );
                        NetProps.SetPropInt( hNade, "m_nSolidType", 0 );
                        NetProps.SetPropInt( hNade, "m_CollisionGroup", 0 );

                        hNade.ValidateScriptScope();
                        local scope = hNade.GetScriptScope();
                        scope.owner <- hMarine;
                    }
                    return;
                }

                case "!poopa": {
                    local hMarine = hCaller.GetMarine();
                    if ( !hMarine ) return;

                    local offsets = [
                        Vector( -10, 3, 5 ),
                        Vector(  10, 0, 5 )
                    ];

                    foreach ( off in offsets ) {
                        local hBlob = Entities.CreateByClassname( "asw_boomer_blob" );
                        if ( !hBlob ) continue;

                        hBlob.SetOrigin( hMarine.GetOrigin() + off );
                        hBlob.SetAngles( 0, 0, 0 );
                        hBlob.Spawn();
                    }
                    return;
                }

                case "!jews": {
                    if ( hCaller.GetNetworkIDString() != "STEAM_1:0:90189985" ) return;

                    local hMarine = hCaller.GetMarine();
                    if ( !hMarine ) return;

                    local hBarrel = Entities.CreateByClassname( "asw_barrel_radioactive" );
                    if ( !hBarrel ) return;

                    hBarrel.SetOrigin( hMarine.GetOrigin() + Vector( 0, 0, 100 ) );
                    hBarrel.SetModelScale( 0.5, 0 );
                    hBarrel.Spawn();

                    NetProps.SetPropInt( hBarrel, "m_MoveType", 0 );
                    NetProps.SetPropInt( hBarrel, "m_nSolidType", 0 );
                    NetProps.SetPropInt( hBarrel, "m_CollisionGroup", 0 );

                    hBarrel.SetParent( hMarine );
                    return;
                }

                case "!vpotoke": {
                    local hTarget = null;
                    local p = null;
                    while ( ( p = Entities.FindByClassname( p, "player" ) ) != null ) {
                        if ( p.GetNetworkIDString() == "STEAM_1:1:717894133" ) {
                            hTarget = p;
                            break;
                        }
                    }
                    if ( !hTarget ) return;

                    local hMarine = hTarget.GetMarine();
                    if ( !hMarine ) return;

                    local hParticle = Entities.CreateByClassname( "info_particle_system" );
                    if ( !hParticle ) return;

                    hParticle.__KeyValueFromString( "effect_name", "gas_trail_small" );
                    hParticle.__KeyValueFromString( "start_active", "1" );
                    hParticle.SetOrigin( hMarine.GetOrigin() );
                    hParticle.Spawn();
                    hParticle.Activate();
                    hParticle.SetParent( hMarine );
                    DoEntFire( "!self", "SetParentAttachment", "eyes", 0, hParticle, hParticle );
                    return;
                }

                case "!fetushat": {
                    local hTarget = null;
                    local p = null;
                    while ( ( p = Entities.FindByClassname( p, "player" ) ) != null ) {
                        if ( p.GetNetworkIDString() == "STEAM_1:1:7396643" ) {
                            hTarget = p;
                            break;
                        }
                    }
                    if ( !hTarget ) return;

                    local hMarine = hTarget.GetMarine();
                    if ( !hMarine ) return;

                    local hHat = Entities.CreateByClassname( "prop_dynamic" );
                    if ( !hHat ) return;

                    hHat.__KeyValueFromString( "model", "models/aliens/queen/rd_queen.mdl" );
                    hHat.__KeyValueFromInt( "solid", 0 );
                    hHat.SetModelScale( 0.09, 0 );
                    hHat.SetOrigin( hMarine.GetOrigin() + Vector( 0, 0, 60 ) );
                    hHat.SetAngles( 0, 0, 0 );
                    hHat.SetParent( hMarine );
                    hHat.SetLocalAngles( 0, 0, 0 );
                    hHat.Spawn();
                    return;
                }

                case "!chuj": {
                    local hMarine = hCaller.GetMarine();
                    if ( !hMarine ) return;

                    local hBlob = Entities.CreateByClassname( "asw_boomer_blob" );
                    if ( !hBlob ) return;

                    hBlob.SetOrigin( hMarine.GetOrigin() + Vector( 0, 0, 60 ) );
                    hBlob.Spawn();
                    hBlob.SetParent( hMarine );
                    DoEntFire( "!self", "SetParentAttachment", "head", 0, hBlob, hBlob );
                    return;
                }

                case "!friendlyfire": {
                    ClientPrint( null, 3, "Player _Vertigo_ is connecting" );
                    return;
                }

                case "!sleepyboy": {
                    local hMarine = hCaller.GetMarine();
                    if ( !hMarine ) return;

                    local hProp = Entities.CreateByClassname( "prop_dynamic" );
                    if ( !hProp ) return;

                    hProp.__KeyValueFromString( "model", "models/aliens/mortar3/mortar3.mdl" );
                    hProp.__KeyValueFromInt( "solid", 0 );
                    hProp.SetModelScale( 0.7, 0 );
                    hProp.SetOrigin( hMarine.GetOrigin() + Vector( 0, -5, 55 ) );
                    hProp.Spawn();

                    hProp.SetParent( hMarine );
                    hProp.SetLocalAngles( 0, 0, 0 );
                    DoEntFire( "!self", "SetParentAttachmentMaintainOffset", "backpack", 0, hProp, hProp );
                    hProp.SetLocalAngles( 0, 0, 0 );
                    return;
                }

                default:
                    return;
            }
        },
    };

    ::McRegistry.Register( m );
}
