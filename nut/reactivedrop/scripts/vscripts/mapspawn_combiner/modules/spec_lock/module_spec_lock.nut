// mapspawn_combiner/modules/spec_lock/module_spec_lock.nut
// Чат-команда !spec <имя> — закрепить камеру спектатора на морпехе.
// Сессия (память VM), без файла. Сброс: !spec auto
// Выключить: !am_disable spec_lock

if ( "SpecLockModuleLoaded" in getroottable() ) {
    ::McLog.Info( "[MC] spec_lock: already loaded, skip" );
} else {
    getroottable().SpecLockModuleLoaded <- true;

    local _strings = {
        usage = {
            en = "Usage: {cmd} Vegas  |  {cmd} auto",
            ru = "Использование: {cmd} Vegas  |  {cmd} auto",
        },
        hint = {
            en = "Marine (Sarge, Vegas, …) or player name. Session only.",
            ru = "Морпех (Sarge, Vegas, …) или ник. Только на сессию.",
        },
        auto = {
            en = "Spectate target: auto (game picks)",
            ru = "Цель наблюдения: как в игре",
        },
        locked = {
            en = "Spectate target: {name}",
            ru = "Цель наблюдения: {name}",
        },
        waiting = {
            en = "Locked on {name}. Camera follows when that marine is alive.",
            ru = "Закреплено на {name}. Камера сядет, когда этот морпех будет жив.",
        },
        later = {
            en = "Locked on {name}. Applies when you are a spectator.",
            ru = "Закреплено на {name}. Сработает, когда будешь спектатором.",
        },
        none = {
            en = "No such marine or player",
            ru = "Нет такого морпеха или игрока",
        },
        many = {
            en = "Ambiguous: {names}. Be more specific.",
            ru = "Неоднозначно: {names}. Напиши точнее.",
        },
        living = {
            en = "Alive: {names}",
            ru = "Живые: {names}",
        },
        living_none = {
            en = "Alive: none",
            ru = "Живые: никого",
        },
        steam = {
            en = "SteamID unavailable (LAN/BOT?)",
            ru = "SteamID недоступен (LAN/BOT?)",
        },
    };

    local m = {
        name        = "spec_lock",
        enabled     = true,
        convars     = {},
        version     = "1.0.1",
        description = "Chat: !spec <marine|player> locks spectator camera for this session.",
        requires_registry = 4,

        console_info = [
            "=== spec_lock ===",
            "Chat: !spec <name>  (slash alias /spec)",
            "Lock spectator camera on a marine profile (Sarge, Vegas, …) or player name.",
            "Reset: !spec auto  (also off / default / none / clear / -)",
            "No args: current lock and living marines.",
            "Stored in memory for this server session (SteamID). Not written by !am_save.",
            "Disable: !am_disable spec_lock",
        ],

        _PREFIX = "[SPEC] ",
        _CMD    = "!spec",
        _strings = _strings,

        // asw_shareddefs.h ASW_MARINE_PROFILE_*
        _PROFILE_NAMES = [
            "Sarge", "Wildcat", "Faith", "Crash",
            "Jaeger", "Wolfe", "Bastille", "Vegas",
        ],
        _PROFILE_ALIAS = {
            sarge = 0,
            wildcat = 1,
            faith = 2,
            crash = 3,
            jaeger = 4,
            jager = 4,
            wolfe = 5,
            wolf = 5,
            bastille = 6,
            vegas = 7,
        },
        _RESET = {
            auto = true,
            off = true,
            ["default"] = true,
            none = true,
            clear = true,
            ["-"] = true,
        },

        _locks = {},   // playerKey -> { kind, profile?, playerKey?, label }
        _inMission = false,

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

        function _trim( s ) {
            if ( "McAuth" in getroottable() )
                return ::McAuth.TrimSpaces( s );
            if ( s == null )
                return "";
            s = s.tostring();
            while ( s.len() > 0 && s.slice( 0, 1 ) == " " )
                s = s.slice( 1 );
            while ( s.len() > 0 && s.slice( s.len() - 1 ) == " " )
                s = s.slice( 0, s.len() - 1 );
            return s;
        },

        function _startsWith( s, prefix ) {
            if ( s == null || prefix == null )
                return false;
            s = s.tostring();
            prefix = prefix.tostring();
            if ( prefix.len() == 0 || s.len() < prefix.len() )
                return false;
            return s.slice( 0, prefix.len() ) == prefix;
        },

        function _playerKey( hPlayer ) {
            if ( hPlayer == null || !hPlayer.IsValid() )
                return null;
            if ( "McAuth" in getroottable() ) {
                local k = ::McAuth.PlayerKey( hPlayer );
                if ( k != null )
                    return k;
            }
            try {
                return "uid:" + hPlayer.GetPlayerUserID();
            } catch ( e ) {
            }
            try {
                return "ent:" + hPlayer.entindex();
            } catch ( e2 ) {
            }
            return null;
        },

        function _marineAlive( hMarine ) {
            if ( hMarine == null || !hMarine.IsValid() )
                return false;
            try {
                if ( hMarine.GetClassname() != "asw_marine" )
                    return false;
                return hMarine.GetHealth() > 0;
            } catch ( e ) {
                return false;
            }
        },

        function _isSpectator( hPlayer ) {
            if ( hPlayer == null || !hPlayer.IsValid() )
                return false;
            local npc = null;
            try {
                npc = hPlayer.GetNPC();
            } catch ( e ) {
                return true;
            }
            if ( npc == null || !npc.IsValid() )
                return true;
            try {
                return npc.GetHealth() <= 0;
            } catch ( e2 ) {
                return true;
            }
        },

        function _profileName( idx ) {
            if ( idx == null || idx < 0 || idx >= this._PROFILE_NAMES.len() )
                return "?";
            return this._PROFILE_NAMES[idx];
        },

        function _marineProfile( hMarine ) {
            if ( hMarine == null || !hMarine.IsValid() )
                return null;
            try {
                return hMarine.GetMarineProfile();
            } catch ( e ) {
                return null;
            }
        },

        function _marineLabel( hMarine ) {
            local idx = this._marineProfile( hMarine );
            local name = this._profileName( idx );
            if ( name == "?" ) {
                try {
                    name = hMarine.GetMarineName();
                } catch ( e ) {
                    name = "marine";
                }
            }
            try {
                if ( hMarine.IsInhabited() ) {
                    local cmd = hMarine.GetCommander();
                    if ( cmd != null && cmd.IsValid() ) {
                        local nick = cmd.GetPlayerName();
                        if ( nick != null && nick != "" )
                            return name + " (" + nick + ")";
                    }
                }
            } catch ( e2 ) {
            }
            return name;
        },

        function _listLiving() {
            local parts = [];
            local m = null;
            while ( ( m = Entities.FindByClassname( m, "asw_marine" ) ) != null ) {
                if ( !this._marineAlive( m ) )
                    continue;
                parts.append( this._marineLabel( m ) );
            }
            local s = "";
            local i = 0;
            while ( i < parts.len() ) {
                if ( i > 0 )
                    s += ", ";
                s += parts[i];
                i += 1;
            }
            return s;
        },

        function _findMarineByProfile( idx ) {
            local m = null;
            while ( ( m = Entities.FindByClassname( m, "asw_marine" ) ) != null ) {
                if ( !this._marineAlive( m ) )
                    continue;
                if ( this._marineProfile( m ) == idx )
                    return m;
            }
            return null;
        },

        function _findMarineByPlayerKey( key ) {
            if ( key == null )
                return null;
            local p = null;
            while ( ( p = Entities.FindByClassname( p, "player" ) ) != null ) {
                if ( !p.IsValid() )
                    continue;
                if ( this._playerKey( p ) != key )
                    continue;
                local marine = null;
                try {
                    marine = p.GetNPC();
                } catch ( e ) {
                }
                if ( this._marineAlive( marine ) )
                    return marine;
                try {
                    marine = p.GetMarine();
                } catch ( e2 ) {
                }
                if ( this._marineAlive( marine ) )
                    return marine;
            }
            local m = null;
            while ( ( m = Entities.FindByClassname( m, "asw_marine" ) ) != null ) {
                if ( !this._marineAlive( m ) )
                    continue;
                try {
                    if ( !m.IsInhabited() )
                        continue;
                    local cmd = m.GetCommander();
                    if ( cmd != null && cmd.IsValid() && this._playerKey( cmd ) == key )
                        return m;
                } catch ( e3 ) {
                }
            }
            return null;
        },

        function _lockTarget( lock ) {
            if ( lock == null )
                return null;
            if ( lock.kind == "profile" )
                return this._findMarineByProfile( lock.profile );
            if ( lock.kind == "player" )
                return this._findMarineByPlayerKey( lock.playerKey );
            return null;
        },

        function _apply( hPlayer, lock ) {
            if ( lock == null )
                return false;
            if ( !this._inMission )
                return false;
            if ( !this._isSpectator( hPlayer ) )
                return false;
            local target = this._lockTarget( lock );
            if ( target == null )
                return false;
            local cur = null;
            try {
                cur = hPlayer.GetSpectatingNPC();
            } catch ( e ) {
            }
            if ( cur == target )
                return true;
            try {
                hPlayer.SetSpectatingNPC( target );
            } catch ( e2 ) {
                return false;
            }
            return true;
        },

        function _applyAll() {
            local p = null;
            while ( ( p = Entities.FindByClassname( p, "player" ) ) != null ) {
                if ( !p.IsValid() )
                    continue;
                local key = this._playerKey( p );
                if ( key == null || !( key in this._locks ) )
                    continue;
                this._apply( p, this._locks[key] );
            }
        },

        function _uniqueProfilePrefix( q ) {
            local hit = null;
            foreach ( alias, idx in this._PROFILE_ALIAS ) {
                if ( !this._startsWith( alias, q ) )
                    continue;
                if ( hit == null )
                    hit = idx;
                else if ( hit != idx )
                    return null;
            }
            return hit;
        },

        function _collectNameHits( q ) {
            local hits = [];
            local seen = {};

            local m = null;
            while ( ( m = Entities.FindByClassname( m, "asw_marine" ) ) != null ) {
                if ( !this._marineAlive( m ) )
                    continue;
                local n = "";
                try {
                    n = m.GetMarineName();
                } catch ( e ) {
                    n = "";
                }
                if ( n == null )
                    n = "";
                n = n.tostring().tolower();
                local exact = ( n == q );
                local pref = this._startsWith( n, q );
                if ( !exact && !pref )
                    continue;
                local id = m.entindex();
                if ( id in seen )
                    continue;
                seen[id] <- true;
                local idx = this._marineProfile( m );
                local lock = null;
                if ( idx != null && idx >= 0 && idx < this._PROFILE_NAMES.len() ) {
                    lock = {
                        kind = "profile",
                        profile = idx,
                        label = this._profileName( idx ),
                    };
                }
                else {
                    lock = {
                        kind = "profile",
                        profile = idx,
                        label = n,
                    };
                }
                hits.append( { exact = exact, lock = lock, label = this._marineLabel( m ) } );
            }

            local p = null;
            while ( ( p = Entities.FindByClassname( p, "player" ) ) != null ) {
                if ( !p.IsValid() )
                    continue;
                local nick = "";
                try {
                    nick = p.GetPlayerName();
                } catch ( e2 ) {
                    nick = "";
                }
                if ( nick == null )
                    nick = "";
                local low = nick.tostring().tolower();
                local exact = ( low == q );
                local pref = this._startsWith( low, q );
                if ( !exact && !pref )
                    continue;
                local pk = this._playerKey( p );
                if ( pk == null )
                    continue;
                hits.append( {
                    exact = exact,
                    lock = {
                        kind = "player",
                        playerKey = pk,
                        label = nick,
                    },
                    label = nick,
                } );
            }
            return hits;
        },

        function _resolve( q ) {
            if ( q in this._PROFILE_ALIAS ) {
                local idx = this._PROFILE_ALIAS[q];
                return {
                    lock = {
                        kind = "profile",
                        profile = idx,
                        label = this._profileName( idx ),
                    },
                };
            }

            local hits = this._collectNameHits( q );
            local exact = [];
            foreach ( h in hits ) {
                if ( h.exact )
                    exact.append( h );
            }
            local pool = exact;
            if ( pool.len() == 0 )
                pool = hits;

            if ( pool.len() == 1 )
                return { lock = pool[0].lock };

            if ( pool.len() == 0 ) {
                local idx = this._uniqueProfilePrefix( q );
                if ( idx != null ) {
                    return {
                        lock = {
                            kind = "profile",
                            profile = idx,
                            label = this._profileName( idx ),
                        },
                    };
                }
                return { none = true };
            }

            local labels = "";
            local i = 0;
            while ( i < pool.len() ) {
                if ( i > 0 )
                    labels += ", ";
                labels += pool[i].label;
                i += 1;
            }
            return { many = true, names = labels };
        },

        function _printLiving( hPlayer ) {
            local list = this._listLiving();
            if ( list == "" )
                this._msgId( hPlayer, "living_none" );
            else
                this._msgId( hPlayer, "living", { names = list } );
        },

        function _status( hPlayer ) {
            local key = this._playerKey( hPlayer );
            if ( key != null && ( key in this._locks ) )
                this._msgId( hPlayer, "locked", { name = this._locks[key].label } );
            else
                this._msgId( hPlayer, "auto" );
            this._printLiving( hPlayer );
            this._msgId( hPlayer, "usage", { cmd = this._CMD } );
            this._msgId( hPlayer, "hint" );
        },

        function _clear( hPlayer ) {
            local key = this._playerKey( hPlayer );
            if ( key != null && ( key in this._locks ) )
                delete this._locks[key];
            this._msgId( hPlayer, "auto" );
        },

        function _setLock( hPlayer, lock ) {
            local key = this._playerKey( hPlayer );
            if ( key == null ) {
                this._msgId( hPlayer, "steam" );
                return;
            }
            this._locks[key] <- lock;
            if ( !this._inMission || !this._isSpectator( hPlayer ) ) {
                this._msgId( hPlayer, "later", { name = lock.label } );
                return;
            }
            if ( this._apply( hPlayer, lock ) )
                this._msgId( hPlayer, "locked", { name = lock.label } );
            else
                this._msgId( hPlayer, "waiting", { name = lock.label } );
        },

        function _handle( hPlayer, args ) {
            args = this._trim( args );
            if ( args == "" || args.tolower() == "help" ) {
                this._status( hPlayer );
                return;
            }
            local q = args.tolower();
            if ( q in this._RESET ) {
                this._clear( hPlayer );
                return;
            }
            local res = this._resolve( q );
            if ( "none" in res ) {
                this._msgId( hPlayer, "none" );
                this._printLiving( hPlayer );
                return;
            }
            if ( "many" in res ) {
                this._msgId( hPlayer, "many", { names = res.names } );
                return;
            }
            this._setLock( hPlayer, res.lock );
        },

        function OnGameEvent_player_say( params ) {
            if ( !( "text" in params ) || !( "userid" in params ) )
                return;
            local text = params["text"];
            if ( text == null )
                return;
            text = text.tostring();
            if ( text.len() > 0 && text.slice( 0, 1 ) == "/" )
                text = "!" + text.slice( 1 );

            local lower = text.tolower();
            local cmd = this._CMD;
            local cmdLen = cmd.len();
            if ( lower != cmd && ( lower.len() <= cmdLen || lower.slice( 0, cmdLen + 1 ) != cmd + " " ) )
                return;

            local hCaller = GetPlayerFromUserID( params["userid"] );
            if ( hCaller == null || !hCaller.IsValid() )
                return;

            local args = "";
            if ( text.len() > cmdLen )
                args = text.slice( cmdLen + 1 );
            this._handle( hCaller, args );
        },

        function OnGameEvent_player_disconnect( params ) {
            local key = null;
            if ( "userid" in params ) {
                local hPlayer = GetPlayerFromUserID( params["userid"] );
                key = this._playerKey( hPlayer );
            }
            if ( key == null && ( "networkid" in params ) && ( "McAuth" in getroottable() ) ) {
                local acc = ::McAuth.AccountIdFromString( params["networkid"] );
                if ( acc != null )
                    key = acc.tostring();
            }
            if ( key != null && ( key in this._locks ) )
                delete this._locks[key];
        },

        function OnGameplayStart() {
            this._inMission = true;
            this._applyAll();
        },

        function Cleanup() {
            this._inMission = false;
        },

        function Update() {
            if ( !this._inMission )
                return;
            local any = false;
            foreach ( _k, _v in this._locks ) {
                any = true;
                break;
            }
            if ( !any )
                return;
            this._applyAll();
        },
    };

    ::McRegistry.Register( m );
}
