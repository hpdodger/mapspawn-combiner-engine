// mapspawn_combiner/modules/grubrain/module_grubrain.nut
// Чат-команда !grubrain <steamid> — короткий дождь asw_grub над морпехом.
// Спавн как у !koopa в legacy_chat: Director.SpawnAlienAt("asw_grub", …).
// Выключить: !am_disable grubrain

if ( "GrubRainModuleLoaded" in getroottable() ) {
    ::McLog.Info( "[MC] grubrain: already loaded, skip" );
} else {
    getroottable().GrubRainModuleLoaded <- true;

    local _strings = {
        usage = {
            en = "Usage: {cmd} <steamid>",
            ru = "Использование: {cmd} <steamid>",
        },
        hint = {
            en = "SteamID as in status: STEAM_1:Y:Z, [U:1:n], or account id",
            ru = "SteamID как в status: STEAM_1:Y:Z, [U:1:n] или идентификатор аккаунта",
        },
        bad_steamid = {
            en = "Bad SteamID",
            ru = "Непонятный SteamID",
        },
        no_player = {
            en = "No such player online",
            ru = "Такого игрока нет на сервере",
        },
        no_marine = {
            en = "Target has no marine",
            ru = "У цели нет морпеха",
        },
        wait = {
            en = "Wait {sec} sec.",
            ru = "Подожди {sec} с.",
        },
        busy = {
            en = "Rain already running",
            ru = "Дождь уже идёт",
        },
    };

    local m = {
        name        = "grubrain",
        enabled     = true,
        convars     = {},
        version     = "1.0.2",
        description = "Chat joke: !grubrain <steamid> — rain asw_grub above that marine.",
        requires_registry = 4,

        console_info = [
            "=== grubrain ===",
            "Chat: !grubrain <steamid>  (slash alias /grubrain)",
            "Spawns asw_grub via Director.SpawnAlienAt (same as !koopa), then SetOrigin back in the air.",
            "While falling, grubs keep the marine's XY so a running target stays under the rain.",
            "Stops spawning when the marine dies or the duration ends.",
            "Tunables: !am_vars grubrain",
        ],

        _PREFIX     = "[GR] ",
        _CMD        = "!grubrain",
        _strings    = _strings,
        _HEIGHT     = 140.0,
        _SPREAD     = 32,
        _FALL_SPEED = 350.0,

        _rain         = null,   // { marine, endAt, nextSpawn }
        _followMarine = null,
        _falling      = null,   // [ { grub, ox, oy, z }, … ]
        _fallClock    = 0.0,
        _lastUseTime  = 0.0,

        function _langOf( hPlayer ) {
            if ( "McI18n" in getroottable() )
                return ::McI18n.LangOf( hPlayer );
            return "en";
        },

        function _t( hPlayer, msgId, vars = null ) {
            if ( !( "McI18n" in getroottable() ) )
                return msgId;
            local lang = this._langOf( hPlayer );
            if ( vars == null )
                return ::McI18n.T( this._strings, msgId, lang );
            return ::McI18n.TF( this._strings, msgId, lang, vars );
        },

        function _msg( hPlayer, text ) {
            ClientPrint( hPlayer, HudPrint.Talk, this._PREFIX + text );
        },

        function _msgId( hPlayer, msgId, vars = null ) {
            this._msg( hPlayer, this._t( hPlayer, msgId, vars ) );
        },

        function _parseAccountId( raw ) {
            if ( !( "McAuth" in getroottable() ) )
                return null;
            local s = ::McAuth.TrimSpaces( raw );
            if ( s == "" )
                return null;
            local acc = ::McAuth.AccountIdFromString( s );
            if ( acc != null )
                return acc;
            acc = ::McAuth.AccountIdFromString( s.toupper() );
            if ( acc != null )
                return acc;
            for ( local i = 0; i < s.len(); i++ ) {
                local c = s[i];
                if ( c < 48 || c > 57 )
                    return null;
            }
            try {
                local a = s.tointeger();
                if ( a < 0 )
                    return null;
                return a;
            } catch ( e ) {
                return null;
            }
        },

        function _findPlayerByAccountId( acc ) {
            if ( acc == null )
                return null;
            local want = acc.tostring();
            local hPlayer = null;
            while ( hPlayer = Entities.FindByClassname( hPlayer, "player" ) ) {
                local key = ::McAuth.PlayerKey( hPlayer );
                if ( key != null && key == want )
                    return hPlayer;
            }
            return null;
        },

        function _marineAlive( hMarine ) {
            if ( hMarine == null || !hMarine.IsValid() )
                return false;
            return hMarine.GetHealth() > 0;
        },

        function _stopRain() {
            this._rain = null;
            this._followMarine = null;
            this._falling = null;
            this._fallClock = 0.0;
        },

        function _headOrigin( hMarine ) {
            local origin = hMarine.GetOrigin();
            local vel = hMarine.GetVelocity();
            // One thinker tick ahead so a sprint does not leave the column behind.
            return Vector( origin.x + vel.x * 0.05, origin.y + vel.y * 0.05, origin.z );
        },

        function _advanceFalling( hMarine ) {
            local falling = this._falling;
            if ( falling == null || falling.len() == 0 )
                return;

            local now = Time();
            local dt = 0.05;
            if ( this._fallClock > 0 ) {
                dt = now - this._fallClock;
                if ( dt <= 0 || dt > 0.25 )
                    dt = 0.05;
            }
            this._fallClock = now;

            local base = this._headOrigin( hMarine );
            local floorZ = base.z;
            for ( local i = falling.len() - 1; i >= 0; i-- ) {
                local f = falling[i];
                local hGrub = f.grub;
                if ( hGrub == null || !hGrub.IsValid() ) {
                    falling.remove( i );
                    continue;
                }
                f.z -= this._FALL_SPEED * dt;
                local z = f.z;
                if ( z <= floorZ ) {
                    hGrub.SetOrigin( Vector( base.x + f.ox, base.y + f.oy, floorZ ) );
                    falling.remove( i );
                    continue;
                }
                hGrub.SetOrigin( Vector( base.x + f.ox, base.y + f.oy, z ) );
            }
            if ( falling.len() == 0 ) {
                this._falling = null;
                this._fallClock = 0.0;
            }
        },

        function _spawnPulse( hMarine ) {
            if ( !this._marineAlive( hMarine ) )
                return;
            local base = this._headOrigin( hMarine );
            local n = this.variables.count.tointeger();
            if ( n < 1 )
                n = 1;
            local spread = this._SPREAD;
            if ( this._falling == null )
                this._falling = [];
            for ( local i = 0; i < n; i++ ) {
                local ox = RandomFloat( -spread, spread );
                local oy = RandomFloat( -spread, spread );
                local z = base.z + this._HEIGHT + RandomFloat( -8.0, 24.0 );
                local pos = Vector( base.x + ox, base.y + oy, z );
                // SpawnAlienAt always UTIL_DropToFloor; put the grub back in the air.
                local hGrub = Director.SpawnAlienAt( "asw_grub", pos, Vector( 0, RandomFloat( 0, 360 ), 0 ) );
                if ( hGrub == null || !hGrub.IsValid() )
                    continue;
                hGrub.SetOrigin( pos );
                this._falling.append( { grub = hGrub, ox = ox, oy = oy, z = z } );
            }
        },

        function _startRain( hCaller, hMarine ) {
            local now = Time();
            local cd = this.variables.cooldown.tofloat();
            if ( cd > 0 && this._lastUseTime > 0 ) {
                local left = cd - ( now - this._lastUseTime );
                if ( left > 0 ) {
                    this._msgId( hCaller, "wait", { sec = left.tointeger() + 1 } );
                    return;
                }
            }
            if ( this._rain != null ) {
                this._msgId( hCaller, "busy" );
                return;
            }

            this._lastUseTime = now;
            this._followMarine = hMarine;
            this._rain = {
                marine    = hMarine,
                endAt     = now + this.variables.duration.tofloat(),
                nextSpawn = now + this.variables.interval.tofloat(),
            };
            this._spawnPulse( hMarine );
        },

        function OnGameEvent_player_say( params ) {
            if ( !( "text" in params ) || !( "userid" in params ) )
                return;
            local text = params["text"];
            if ( text == null )
                return;

            if ( text.len() > 0 && text.slice( 0, 1 ) == "/" )
                text = "!" + text.slice( 1 );

            local lower = text.tolower();
            local cmd = this._CMD;
            local cmdLen = cmd.len();
            if ( lower != cmd && ( lower.len() <= cmdLen || lower.slice( 0, cmdLen + 1 ) != cmd + " " ) )
                return;

            local hCaller = GetPlayerFromUserID( params["userid"] );
            if ( !hCaller || !hCaller.IsValid() )
                return;

            local args = "";
            if ( lower.len() > cmdLen )
                args = text.slice( cmdLen + 1 );

            if ( !( "McAuth" in getroottable() ) )
                return;

            local s = ::McAuth.TrimSpaces( args );
            if ( s == "" ) {
                this._msgId( hCaller, "usage", { cmd = cmd } );
                this._msgId( hCaller, "hint" );
                return;
            }

            local acc = this._parseAccountId( s );
            if ( acc == null ) {
                this._msgId( hCaller, "bad_steamid" );
                this._msgId( hCaller, "hint" );
                return;
            }

            local hTarget = this._findPlayerByAccountId( acc );
            if ( hTarget == null ) {
                this._msgId( hCaller, "no_player" );
                return;
            }

            local hMarine = hTarget.GetMarine();
            if ( !this._marineAlive( hMarine ) ) {
                this._msgId( hCaller, "no_marine" );
                return;
            }

            this._startRain( hCaller, hMarine );
        },

        function OnGameEvent_entity_killed( params ) {
            if ( this._followMarine == null )
                return;
            if ( !( "entindex_killed" in params ) )
                return;
            local hKilled = EntIndexToHScript( params["entindex_killed"] );
            if ( hKilled != null && hKilled == this._followMarine )
                this._stopRain();
        },

        function Update() {
            local rain = this._rain;
            local hMarine = this._followMarine;
            if ( rain != null )
                hMarine = rain.marine;

            if ( hMarine != null && !this._marineAlive( hMarine ) ) {
                this._stopRain();
                return;
            }

            if ( hMarine != null )
                this._advanceFalling( hMarine );

            if ( rain == null )
                return;

            local now = Time();
            if ( now >= rain.endAt ) {
                this._rain = null;
                return;
            }

            if ( now >= rain.nextSpawn ) {
                this._spawnPulse( hMarine );
                rain.nextSpawn = now + this.variables.interval.tofloat();
            }
        },

        function OnDisable() {
            this._stopRain();
        },

        function Cleanup() {
            this._stopRain();
        },

        function OnGameplayStart() {
            this._stopRain();
        },

        function OnVariableChanged( varName, newVal ) {
            if ( varName == "duration" ) {
                if ( newVal < 0.5 ) return 0.5;
                if ( newVal > 5.0 ) return 5.0;
            }
            if ( varName == "cooldown" ) {
                if ( newVal < 0 ) return 0;
                if ( newVal > 120 ) return 120;
            }
            if ( varName == "interval" ) {
                if ( newVal < 0.05 ) return 0.05;
                if ( newVal > 1.0 ) return 1.0;
            }
            if ( varName == "count" ) {
                local n = newVal.tointeger();
                if ( n < 1 ) return 1;
                if ( n > 8 ) return 8;
                return n;
            }
            return null;
        },
    };

    ::McRegistry.DeclareVariables( m, [
        [ "duration",  2.5,  "rain length, seconds",                 { min = 0.5, max = 5,   step = 0.5 } ],
        [ "cooldown",  15,   "seconds between uses (0 = off)",       { min = 0,   max = 120, step = 1 } ],
        [ "interval",  0.1,  "seconds between spawn pulses",         { min = 0.05, max = 1,  step = 0.05 } ],
        [ "count",     2,    "grubs per pulse",                      { min = 1,   max = 8,   step = 1 } ],
    ] );

    ::McRegistry.Register( m );
}
