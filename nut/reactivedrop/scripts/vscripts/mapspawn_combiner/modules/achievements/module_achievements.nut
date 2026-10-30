// mapspawn_combiner/modules/achievements/module_achievements.nut
// Кастомные ачивки (не Steam): сейв на аккаунт, !ach, попап справа ниже TK.
// Правила — modules/achievements/defs/*.nut через IncludeScript / AchRegister.
// HUD: тот же weapon_kills/wkc_popup_hud.nut (Int 21 = 1, дорожка 3).
// Чат: !ach / !ach_help / !ach_test / !ach_reset (test и reset — McAuth).

if ( "AchievementsLoaded" in getroottable() ) {
    ::McLog.Info( "[MC] achievements: already loaded, skip" );
} else {
    getroottable().AchievementsLoaded <- true;

if ( !( "g_AchDefs" in getroottable() ) )
    ::g_AchDefs <- [];
if ( !( "g_AchById" in getroottable() ) )
    ::g_AchById <- {};

::AchRegister <- function( def ) {
    if ( def == null || !( "id" in def ) || def.id == null || def.id == "" ) {
        ::McLog.Err( "[ACH] AchRegister: missing id" );
        return;
    }
    local id = def.id.tostring();
    if ( id in ::g_AchById ) {
        ::McLog.Err( "[ACH] AchRegister: duplicate id " + id );
        return;
    }
    def.id = id;
    ::g_AchDefs.append( def );
    ::g_AchById[id] <- def;
};

local _ids = {};
IncludeScript( "mapspawn_combiner/modules/achievements/ids", _ids );
IncludeScript( "mapspawn_combiner/modules/achievements/defs/orange_juice" );
IncludeScript( "mapspawn_combiner/modules/achievements/defs/fruits_revenge" );
IncludeScript( "mapspawn_combiner/modules/achievements/defs/bloodbath" );
IncludeScript( "mapspawn_combiner/modules/achievements/defs/pure_heart" );

local _strings = {
    help_title = {
        en = "custom achievements — unlocks, save, world popup",
        ru = "свои достижения — открытие, сейв, попап",
    },
    help_list = {
        en = "!ach — your unlocked achievements (locked stay hidden)",
        ru = "!ach — открытые достижения (закрытые не показываются)",
    },
    help_help = {
        en = "!ach_help — this help",
        ru = "!ach_help — эта справка",
    },
    help_test = {
        en = "!ach_test <id> — simulate unlock popup (admin)",
        ru = "!ach_test <id> — имитация попапа открытия (admin)",
    },
    help_reset = {
        en = "!ach_reset [steamid|all] — wipe save (admin)",
        ru = "!ach_reset [steamid|all] — сбросить сейв (admin)",
    },
    help_toggle = {
        en = "toggle: !am_enable / !am_disable achievements",
        ru = "вкл/выкл: !am_enable / !am_disable achievements",
    },
    help_hud = {
        en = "HUD needs client stub challenge weapon_kills",
        ru = "HUD: на клиенте нужен stub-челлендж weapon_kills",
    },
    help_lang = {
        en = "language: !mc_lang en|ru (shared)",
        ru = "язык: !mc_lang en|ru (общий)",
    },
    steam = {
        en = "SteamID unavailable (LAN/BOT?)",
        ru = "SteamID недоступен (LAN/BOT?)",
    },
    no_perm = {
        en = "No permission",
        ru = "Нет прав",
    },
    need_marine = {
        en = "Need a living marine",
        ru = "Нужен живой морпех",
    },
    popup_off = {
        en = "Popup is off",
        ru = "Попап выключен",
    },
    none = {
        en = "(none yet)",
        ru = "(пока ничего)",
    },
    hidden_left = {
        en = "…and {n} still hidden",
        ru = "…и ещё {n} скрытых",
    },
    test_usage = {
        en = "usage: !ach_test <id>",
        ru = "использование: !ach_test <id>",
    },
    unknown_id = {
        en = "unknown achievement: {arg}",
        ru = "неизвестное достижение: {arg}",
    },
    ids_hdr = {
        en = "ids:",
        ru = "id:",
    },
    test_ok = {
        en = "test popup: {title} [{id}]",
        ru = "тест попапа: {title} [{id}]",
    },
    reset_usage = {
        en = "usage: !ach_reset  |  !ach_reset <steamid>  |  !ach_reset all",
        ru = "использование: !ach_reset  |  !ach_reset <steamid>  |  !ach_reset all",
    },
    wiped = {
        en = "save wiped ({key})",
        ru = "сейв обнулён ({key})",
    },
    wiped_all = {
        en = "wiped {n} saves",
        ru = "обнулено сейвов: {n}",
    },
    unlocked_chat = {
        en = "unlocked: {title}",
        ru = "открыто: {title}",
    },
    list_open = {
        en = "★ {title}",
        ru = "★ {title}",
    },
};

local m = {
    name        = "achievements",
    enabled     = true,
    convars     = {},
    version     = "0.1.3",
    description = "Custom (non-Steam) achievements: save, !ach, world popup below teamkill.",
    requires_registry = 4,

    console_info = [
        "=== achievements ===",
        "Custom VScript achievements. Not Steam UserStats.",
        "Defs: modules/achievements/defs/*.nut via AchRegister.",
        "Popup: nick above stripe, icon + title (1-2 lines) below. Lane 3, right of head, below TK.",
        "Client Paint: weapon_kills/wkc_popup_hud.nut (stub challenge weapon_kills).",
        "Chat: !ach / !ach_help / !ach_test <id> (admin) / !ach_reset (admin)",
        "Language: !mc_lang en|ru (shared McI18n, default en)",
        "Tunables: !am_vars achievements",
    ],

    _PREFIX     = "[ACH] ",
    _CMD_PREFIX = "!ach",
    _DIR        = "achievements/",
    _INDEX      = "achievements/index.txt",
    _SEP        = "|",
    _PROG_SEP   = ";",
    _KV_SEP     = "=",
    _CLIENT_SCRIPT = "weapon_kills/wkc_ach_hud.nut",
    _LANE       = 3,
    _orangeSteam = _ids.orangeSteam,
    _orangeKey   = _ids.orangeKey,
    _strings    = _strings,

    _cache        = null,
    _popups       = null,
    _killTimes    = null,
    _paraHeart    = null,
    _heartMarine  = null,
    _pendingHeart = null,

    function _langOf( hPlayer ) {
        if ( "McI18n" in getroottable() )
            return ::McI18n.LangOf( hPlayer );
        return "en";
    },

    function _t( hPlayer, msgId, vars = null ) {
        local lang = this._langOf( hPlayer );
        if ( !( "McI18n" in getroottable() ) )
            return msgId;
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

    function _isAdmin( hPlayer ) {
        return ( "McAuth" in getroottable() ) && ::McAuth.IsAdmin( hPlayer );
    },

    function _playerKey( hPlayer ) {
        if ( !( "McAuth" in getroottable() ) )
            return null;
        return ::McAuth.PlayerKey( hPlayer );
    },

    function _labelOf( def, field, lang ) {
        if ( def == null )
            return "?";
        if ( !( field in def ) || def[field] == null )
            return def.id;
        if ( "McI18n" in getroottable() )
            return ::McI18n.Label( def[field], lang );
        local tab = def[field];
        if ( typeof tab == "string" )
            return tab;
        if ( lang in tab )
            return tab[lang];
        if ( "en" in tab )
            return tab.en;
        if ( "ru" in tab )
            return tab.ru;
        return def.id;
    },

    function _titleOf( def, lang ) {
        return this._labelOf( def, "title", lang );
    },

    function _descOf( def, lang ) {
        return this._labelOf( def, "desc", lang );
    },

    function _findDef( query ) {
        if ( query == null )
            return null;
        local q = query.tostring().tolower();
        while ( q.len() > 0 && q.slice( 0, 1 ) == " " )
            q = q.slice( 1 );
        while ( q.len() > 0 && q.slice( q.len() - 1 ) == " " )
            q = q.slice( 0, q.len() - 1 );
        if ( q.len() == 0 )
            return null;
        foreach ( def in ::g_AchDefs ) {
            if ( def.id.tolower() == q )
                return def;
        }
        return null;
    },

    function _stripNl( s ) {
        if ( s == null )
            return "";
        s = s.tostring();
        local out = "";
        for ( local i = 0; i < s.len(); i++ ) {
            local ch = s.slice( i, i + 1 );
            if ( ch != "\n" && ch != "\r" )
                out += ch;
        }
        return out;
    },

    function _trim( s ) {
        if ( s == null )
            return "";
        s = s.tostring();
        while ( s.len() > 0 && s.slice( 0, 1 ) == " " )
            s = s.slice( 1 );
        while ( s.len() > 0 && s.slice( s.len() - 1 ) == " " )
            s = s.slice( 0, s.len() - 1 );
        return s;
    },

    function _splitBy( s, sep ) {
        local out = [];
        if ( s == null || s == "" )
            return out;
        local rest = s.tostring();
        local idx = rest.find( sep );
        while ( idx != null ) {
            out.append( rest.slice( 0, idx ) );
            rest = rest.slice( idx + sep.len() );
            idx = rest.find( sep );
        }
        out.append( rest );
        return out;
    },

    function _playerFile( id ) {
        return this._DIR + id + ".txt";
    },

    function _loadIndex() {
        local ids = [];
        local raw = FileToString( this._INDEX );
        if ( raw == null || raw == "" )
            return ids;
        foreach ( line in this._splitBy( raw, "\n" ) ) {
            if ( line.len() > 0 && line.slice( line.len() - 1 ) == "\r" )
                line = line.slice( 0, line.len() - 1 );
            line = this._trim( line );
            if ( line.len() > 0 )
                ids.append( line );
        }
        return ids;
    },

    function _saveIndex( ids ) {
        local out = "";
        foreach ( id in ids )
            out += id + "\n";
        StringToFile( this._INDEX, out );
    },

    function _ensureInIndex( id ) {
        local ids = this._loadIndex();
        foreach ( existing in ids ) {
            if ( existing == id )
                return;
        }
        ids.append( id );
        this._saveIndex( ids );
    },

    function _emptyRec() {
        return { unlocked = {}, progress = {}, name = "?" };
    },

    function _parsePlayerFile( raw ) {
        local rec = this._emptyRec();
        if ( raw == null || raw == "" )
            return rec;
        local line = raw.tostring();
        local nl = line.find( "\n" );
        if ( nl != null )
            line = line.slice( 0, nl );
        if ( line.len() > 0 && line.slice( line.len() - 1 ) == "\r" )
            line = line.slice( 0, line.len() - 1 );

        if ( line.len() >= 6 && line.slice( 0, 6 ) == "#name=" ) {
            rec.name = line.slice( 6 );
            return rec;
        }

        local unlockedPart = line;
        local progressPart = "";
        local bar = line.find( this._SEP );
        if ( bar != null ) {
            unlockedPart = line.slice( 0, bar );
            progressPart = line.slice( bar + 1 );
        }

        if ( unlockedPart != null && unlockedPart != "" ) {
            foreach ( uid in this._splitBy( unlockedPart, "," ) ) {
                uid = this._trim( uid );
                if ( uid != "" )
                    rec.unlocked[uid] <- true;
            }
        }
        if ( progressPart != null && progressPart != "" ) {
            foreach ( pair in this._splitBy( progressPart, this._PROG_SEP ) ) {
                pair = this._trim( pair );
                if ( pair == "" )
                    continue;
                local eq = pair.find( this._KV_SEP );
                if ( eq == null )
                    continue;
                local pid = this._trim( pair.slice( 0, eq ) );
                local pval = this._trim( pair.slice( eq + 1 ) );
                if ( pid == "" )
                    continue;
                try {
                    rec.progress[pid] <- pval.tointeger();
                } catch ( e ) {
                    rec.progress[pid] <- 0;
                }
            }
        }
        return rec;
    },

    function _serializePlayer( rec ) {
        local unlockedStr = "";
        local firstU = true;
        foreach ( uid, _v in rec.unlocked ) {
            if ( !firstU )
                unlockedStr += ",";
            firstU = false;
            unlockedStr += uid;
        }
        local progressStr = "";
        local firstP = true;
        foreach ( pid, pval in rec.progress ) {
            if ( pid in rec.unlocked )
                continue;
            if ( !firstP )
                progressStr += this._PROG_SEP;
            firstP = false;
            progressStr += pid + this._KV_SEP + pval.tostring();
        }
        return unlockedStr + this._SEP + progressStr;
    },

    function _load( id ) {
        if ( this._cache == null )
            this._cache = {};
        if ( id in this._cache )
            return this._cache[id];
        local rec = this._parsePlayerFile( FileToString( this._playerFile( id ) ) );
        this._cache[id] <- rec;
        return rec;
    },

    function _save( id ) {
        if ( this._cache == null || !( id in this._cache ) )
            return;
        StringToFile( this._playerFile( id ), this._serializePlayer( this._cache[id] ) );
        this._ensureInIndex( id );
    },

    function _touch( hPlayer ) {
        local id = this._playerKey( hPlayer );
        if ( id == null )
            return null;
        local rec = this._load( id );
        if ( hPlayer != null && hPlayer.IsValid() )
            rec.name = hPlayer.GetPlayerName();
        return { id = id, rec = rec };
    },

    function _isUnlocked( key, achId ) {
        if ( key == null || achId == null )
            return false;
        local rec = this._load( key );
        return ( achId in rec.unlocked );
    },

    function _wipe( id ) {
        if ( id == null )
            return false;
        local rec = this._emptyRec();
        if ( this._cache == null )
            this._cache = {};
        if ( id in this._cache && this._cache[id].name != null )
            rec.name = this._cache[id].name;
        this._cache[id] <- rec;
        this._save( id );
        return true;
    },

    function _makeCtx( playerKey, hPlayer, hMarine ) {
        local ctx = {
            playerKey = playerKey,
            player = hPlayer,
            marine = hMarine,
            mod = this,
        };
        ctx.IsUnlocked <- function( achId ) {
            return this.mod._isUnlocked( this.playerKey, achId );
        };
        ctx.IsUnlocked = ctx.IsUnlocked.bindenv( ctx );

        ctx.Has <- function( otherKey, achId ) {
            return this.mod._isUnlocked( otherKey, achId );
        };
        ctx.Has = ctx.Has.bindenv( ctx );

        ctx.IsOrange <- function( key ) {
            if ( key == null )
                return false;
            local want = this.mod._orangeKey;
            if ( want == null || want == "" )
                return false;
            return key == want;
        };
        ctx.IsOrange = ctx.IsOrange.bindenv( ctx );

        ctx.RecentMarineKills <- function( windowSec ) {
            return this.mod._countRecentKills( this.playerKey, windowSec );
        };
        ctx.RecentMarineKills = ctx.RecentMarineKills.bindenv( ctx );

        ctx.GetProgress <- function( achId ) {
            local rec = this.mod._load( this.playerKey );
            if ( achId in rec.unlocked )
                return 0;
            if ( achId in rec.progress )
                return rec.progress[achId];
            return 0;
        };
        ctx.GetProgress = ctx.GetProgress.bindenv( ctx );

        ctx.AddProgress <- function( achId, n ) {
            if ( n == null )
                n = 1;
            local rec = this.mod._load( this.playerKey );
            if ( achId in rec.unlocked ) {
                if ( achId in ::g_AchById && ( "goal" in ::g_AchById[achId] ) )
                    return ::g_AchById[achId].goal;
                return 0;
            }
            local cur = 0;
            if ( achId in rec.progress )
                cur = rec.progress[achId];
            cur += n;
            rec.progress[achId] <- cur;
            this.mod._save( this.playerKey );
            return cur;
        };
        ctx.AddProgress = ctx.AddProgress.bindenv( ctx );

        ctx.Unlock <- function( achId ) {
            return this.mod._unlock( this.playerKey, this.player, this.marine, achId );
        };
        ctx.Unlock = ctx.Unlock.bindenv( ctx );

        return ctx;
    },

    function _unlock( key, hPlayer, hMarine, achId ) {
        if ( key == null || achId == null )
            return false;
        if ( !( achId in ::g_AchById ) )
            return false;
        local rec = this._load( key );
        if ( achId in rec.unlocked )
            return false;
        rec.unlocked[achId] <- true;
        if ( achId in rec.progress )
            delete rec.progress[achId];
        if ( hPlayer != null && hPlayer.IsValid() )
            rec.name = hPlayer.GetPlayerName();
        this._save( key );

        local def = ::g_AchById[achId];
        local lang = this._langOf( hPlayer );
        local title = this._titleOf( def, lang );
        ::McLog.Info( "[ACH] unlock " + achId + " (" + title + ") → " + rec.name );

        if ( ( "variables" in this ) && this.variables.chat_notify != 0 && hPlayer != null && hPlayer.IsValid() )
            this._msgId( hPlayer, "unlocked_chat", { title = title } );

        this._showPopup( hMarine, def, hPlayer );
        return true;
    },

    function _asMarine( ent ) {
        if ( ent == null || !ent.IsValid() )
            return null;
        if ( ent.GetClassname() == "asw_marine" )
            return ent;
        try {
            local owner = ent.GetOwner();
            if ( owner != null && owner.IsValid() && owner.GetClassname() == "asw_marine" )
                return owner;
        } catch ( e ) {
        }
        return null;
    },

    function _commanderOfMarine( hMarine ) {
        if ( hMarine == null || !hMarine.IsValid() )
            return null;
        if ( hMarine.GetClassname() != "asw_marine" )
            return null;
        if ( !( "IsInhabited" in hMarine ) || !hMarine.IsInhabited() )
            return null;
        if ( !( "GetCommander" in hMarine ) )
            return null;
        local hPlayer = hMarine.GetCommander();
        if ( hPlayer == null || !hPlayer.IsValid() )
            return null;
        return hPlayer;
    },

    function _noteMarineKill( key ) {
        if ( key == null )
            return;
        local now = Time();
        if ( this._killTimes == null )
            this._killTimes = {};
        local prev = [];
        if ( key in this._killTimes )
            prev = this._killTimes[key];
        local keep = [];
        foreach ( t in prev ) {
            if ( now - t <= 8.0 )
                keep.append( t );
        }
        keep.append( now );
        this._killTimes[key] <- keep;
    },

    function _countRecentKills( key, windowSec ) {
        if ( key == null || this._killTimes == null || !( key in this._killTimes ) )
            return 0;
        if ( windowSec == null )
            windowSec = 0.0;
        windowSec = windowSec.tofloat();
        if ( windowSec < 0.0 )
            windowSec = 0.0;
        local now = Time();
        local n = 0;
        foreach ( t in this._killTimes[key] ) {
            if ( now - t <= windowSec )
                n += 1;
        }
        return n;
    },

    function _isParasite( ent ) {
        if ( ent == null || !ent.IsValid() )
            return false;
        local c = ent.GetClassname();
        return ( c == "asw_parasite" || c == "asw_parasite_defanged" );
    },

    function _playerFromKey( key ) {
        if ( key == null )
            return null;
        local p = null;
        while ( ( p = Entities.FindByClassname( p, "player" ) ) != null ) {
            if ( this._playerKey( p ) == key )
                return p;
        }
        return null;
    },

    function _tagParasite( para, key ) {
        if ( para == null || !para.IsValid() || key == null )
            return;
        if ( this._paraHeart == null )
            this._paraHeart = {};
        this._paraHeart[para.entindex().tostring()] <- key;
    },

    function _heartOf( para ) {
        if ( para == null || !para.IsValid() )
            return null;
        if ( this._paraHeart == null )
            this._paraHeart = {};
        local id = para.entindex().tostring();
        if ( id in this._paraHeart )
            return this._paraHeart[id];
        try {
            local owner = para.GetOwner();
            if ( owner != null && owner.IsValid() && this._heartMarine != null ) {
                local mid = owner.entindex().tostring();
                if ( mid in this._heartMarine )
                    return this._heartMarine[mid];
            }
        } catch ( e ) {
        }
        return null;
    },

    function _tagParasitesFromMarine( hMarine, key ) {
        if ( key == null )
            return;
        local classes = [ "asw_parasite", "asw_parasite_defanged" ];
        foreach ( cls in classes ) {
            local p = null;
            while ( ( p = Entities.FindByClassname( p, cls ) ) != null ) {
                local hit = false;
                try {
                    local owner = p.GetOwner();
                    if ( hMarine != null && hMarine.IsValid() && owner == hMarine )
                        hit = true;
                    else if ( owner != null && owner.IsValid() && this._heartMarine != null ) {
                        local mid = owner.entindex().tostring();
                        if ( mid in this._heartMarine && this._heartMarine[mid] == key )
                            hit = true;
                    }
                } catch ( e ) {
                }
                if ( !hit && hMarine != null && hMarine.IsValid() ) {
                    local ownerOk = false;
                    try {
                        local owner2 = p.GetOwner();
                        ownerOk = ( owner2 == null );
                    } catch ( eOwn ) {
                        ownerOk = true;
                    }
                    if ( ownerOk ) {
                        try {
                            local d = p.GetOrigin() - hMarine.GetOrigin();
                            if ( d.Length() < 56.0 )
                                hit = true;
                        } catch ( e2 ) {
                        }
                    }
                }
                if ( hit )
                    this._tagParasite( p, key );
            }
        }
    },

    function _queueHeartSpawn( hMarine, key ) {
        if ( hMarine == null || !hMarine.IsValid() || key == null )
            return;
        if ( this._heartMarine == null )
            this._heartMarine = {};
        this._heartMarine[hMarine.entindex().tostring()] <- key;
        if ( this._pendingHeart == null )
            this._pendingHeart = [];
        this._pendingHeart.append( {
            marine = hMarine,
            key = key,
            until = Time() + 2.5,
        } );
        this._tagParasitesFromMarine( hMarine, key );
    },

    function _flushHeartSpawns() {
        if ( this._pendingHeart == null || this._pendingHeart.len() == 0 )
            return;
        local now = Time();
        local keep = [];
        foreach ( rec in this._pendingHeart ) {
            this._tagParasitesFromMarine( rec.marine, rec.key );
            if ( now < rec.until )
                keep.append( rec );
        }
        this._pendingHeart = keep;
    },

    function _clearHeartState() {
        this._paraHeart = null;
        this._heartMarine = null;
        this._pendingHeart = null;
    },

    function _tryParasiteGift( giverKey, victimKey ) {
        if ( giverKey == null || victimKey == null )
            return;
        if ( giverKey == victimKey )
            return;
        local hGiver = this._playerFromKey( giverKey );
        local hMarine = null;
        if ( hGiver != null && hGiver.IsValid() )
            hMarine = hGiver.GetMarine();
        local ctx = this._makeCtx( giverKey, hGiver, hMarine );
        foreach ( def in ::g_AchDefs ) {
            if ( this._isUnlocked( giverKey, def.id ) )
                continue;
            if ( !( "OnParasiteGift" in def ) )
                continue;
            def.OnParasiteGift( ctx, giverKey, victimKey );
        }
    },

    function _onParasiteTouchedPlayer( para, vKey ) {
        if ( para == null || vKey == null )
            return;
        local giver = this._heartOf( para );
        if ( giver != null )
            this._tryParasiteGift( giver, vKey );
        else
            this._tagParasite( para, vKey );
    },

    function _findInfestingParasite( hMarine ) {
        if ( hMarine == null || !hMarine.IsValid() )
            return null;
        local p = null;
        while ( ( p = Entities.FindByClassname( p, "asw_parasite" ) ) != null ) {
            try {
                if ( "GetMoveParent" in p && p.GetMoveParent() == hMarine )
                    return p;
            } catch ( e ) {
            }
            try {
                if ( p.GetOwner() == hMarine )
                    return p;
            } catch ( e2 ) {
            }
        }
        try {
            local near = Entities.FindByClassnameNearest( "asw_parasite", hMarine.GetOrigin(), 80.0 );
            if ( near != null && near.IsValid() )
                return near;
        } catch ( e3 ) {
        }
        return null;
    },

    function _parseRgb( raw, fallback ) {
        local fb = fallback;
        if ( fb == null )
            fb = [ 255, 255, 255 ];
        if ( raw == null )
            return [ fb[0], fb[1], fb[2] ];
        local s = raw.tostring();
        while ( s.len() > 0 && s.slice( 0, 1 ) == " " )
            s = s.slice( 1 );
        while ( s.len() > 0 && s.slice( s.len() - 1 ) == " " )
            s = s.slice( 0, s.len() - 1 );
        local parts = [];
        local start = 0;
        for ( local i = 0; i <= s.len(); i++ ) {
            local end = ( i == s.len() );
            local ch = end ? " " : s.slice( i, i + 1 );
            if ( ch == " " || ch == "," || ch == ";" || end ) {
                if ( i > start )
                    parts.append( s.slice( start, i ) );
                start = i + 1;
            }
        }
        if ( parts.len() < 3 )
            return [ fb[0], fb[1], fb[2] ];
        try {
            local r = parts[0].tointeger();
            local g = parts[1].tointeger();
            local b = parts[2].tointeger();
            if ( r < 0 ) r = 0; if ( r > 255 ) r = 255;
            if ( g < 0 ) g = 0; if ( g > 255 ) g = 255;
            if ( b < 0 ) b = 0; if ( b > 255 ) b = 255;
            return [ r, g, b ];
        } catch ( e ) {
            return [ fb[0], fb[1], fb[2] ];
        }
    },

    function _clampByte( v, defv ) {
        if ( v == null )
            return defv;
        local n = v.tointeger();
        if ( n < 0 ) n = 0;
        if ( n > 255 ) n = 255;
        return n;
    },

    function _stackIndexForMarine( hMarine ) {
        if ( this._popups == null )
            return 0;
        local n = 0;
        local now = Time();
        foreach ( p in this._popups ) {
            if ( p.marine == hMarine && p.hideAt > now )
                n += 1;
        }
        return n;
    },

    function _writePopupStyle( e ) {
        local v = this.variables;
        local accent = this._parseRgb( v.popup_accent, [ 255, 150, 40 ] );
        local text = this._parseRgb( v.popup_text, [ 255, 220, 180 ] );
        local bg = this._parseRgb( v.popup_bg, [ 24, 12, 4 ] );

        e.SetInt( 3, accent[0] );
        e.SetInt( 4, accent[1] );
        e.SetInt( 5, accent[2] );
        e.SetInt( 6, text[0] );
        e.SetInt( 7, text[1] );
        e.SetInt( 8, text[2] );
        e.SetInt( 9, bg[0] );
        e.SetInt( 10, bg[1] );
        e.SetInt( 11, bg[2] );
        e.SetInt( 12, this._clampByte( v.popup_bg_alpha, 225 ) );
        e.SetInt( 13, this._clampByte( v.popup_alpha, 230 ) );
        e.SetInt( 14, 1 );
        e.SetInt( 15, 255 );
        e.SetInt( 16, 255 );
        e.SetInt( 17, 255 );
        e.SetInt( 18, 1 );

        e.SetFloat( 2, v.popup_x.tofloat() );
        e.SetFloat( 3, v.popup_y.tofloat() );
        e.SetFloat( 4, v.popup_stack_gap.tofloat() );
        e.SetFloat( 5, v.popup_icon_w.tofloat() );
        e.SetFloat( 6, v.popup_icon_h.tofloat() );
        e.SetFloat( 7, v.popup_scale.tofloat() );
        e.SetFloat( 8, 0.0 );
    },

    function _commanderNick( hMarine ) {
        if ( hMarine == null || !hMarine.IsValid() )
            return "";
        if ( !hMarine.IsInhabited() )
            return "";
        local hPlayer = hMarine.GetCommander();
        if ( hPlayer == null || !hPlayer.IsValid() )
            return "";
        return this._stripNl( hPlayer.GetPlayerName() );
    },

    function _fitBytes( s, room ) {
        if ( s == null )
            return "";
        s = s.tostring();
        if ( room < 1 )
            return "";
        if ( s.len() <= room )
            return s;
        return s.slice( 0, room );
    },

    // String 0: icon \n nick \n title. Лимит 255 байт.
    function _popupPayload( icon, nick, title ) {
        local path = "";
        if ( icon != null )
            path = this._stripNl( icon.tostring() );
        nick = this._stripNl( nick );
        title = this._stripNl( title );
        local room = 255 - path.len() - 2;
        if ( room < 1 )
            return path;
        if ( title.len() + 1 > room ) {
            title = this._fitBytes( title, room );
            nick = "";
        } else {
            local nickRoom = room - title.len() - 1;
            nick = this._fitBytes( nick, nickRoom );
        }
        return path + "\n" + nick + "\n" + title;
    },

    function _showPopup( hMarine, def, hPlayer ) {
        if ( hMarine == null || !hMarine.IsValid() )
            return false;
        if ( !( "variables" in this ) || this.variables.popup == 0 )
            return false;
        if ( def == null )
            return false;

        local delay = this.variables.popup_delay.tofloat();
        if ( delay < 0.0 )
            delay = 0.0;
        local life = this.variables.popup_lifetime.tofloat();
        if ( life < 0.5 )
            life = 0.5;

        local icon = "";
        if ( ( "icon" in def ) && def.icon != null )
            icon = def.icon.tostring();

        local lang = this._langOf( hPlayer );
        local title = this._titleOf( def, lang );
        local nick = this._commanderNick( hMarine );

        local now = Time();
        local showAt = now + delay;
        local hideAt = showAt + life;
        local stack = this._stackIndexForMarine( hMarine );

        local e = Entities.CreateByClassname( "rd_hud_vscript" );
        if ( e == null || !e.IsValid() ) {
            ::McLog.Err( "[ACH] failed to create rd_hud_vscript" );
            return false;
        }
        e.__KeyValueFromString( "client_vscript", this._CLIENT_SCRIPT );
        e.Spawn();
        e.Activate();
        e.SetEntity( 0, hMarine );
        e.SetString( 0, this._popupPayload( icon, nick, title ) );
        e.SetInt( 0, 0 );
        e.SetInt( 1, 1 );
        e.SetInt( 2, stack );
        e.SetInt( 19, hMarine.entindex() );
        e.SetInt( 20, this._LANE );
        e.SetInt( 21, 1 );
        e.SetFloat( 0, showAt );
        e.SetFloat( 1, hideAt );
        this._writePopupStyle( e );

        if ( this._popups == null )
            this._popups = [];
        this._popups.append( { ent = e, marine = hMarine, hideAt = hideAt } );
        return true;
    },

    function _flushPopups() {
        if ( this._popups == null || this._popups.len() == 0 )
            return;
        local now = Time();
        local keep = [];
        foreach ( p in this._popups ) {
            local dead = false;
            if ( p.ent == null || !p.ent.IsValid() )
                dead = true;
            else if ( now > p.hideAt + 0.5 )
                dead = true;
            else if ( p.marine == null || !p.marine.IsValid() )
                dead = true;
            if ( dead ) {
                if ( p.ent != null && p.ent.IsValid() )
                    p.ent.Destroy();
            } else {
                keep.append( p );
            }
        }
        this._popups = keep;
    },

    function _clearPopups() {
        if ( this._popups == null )
            return;
        foreach ( p in this._popups ) {
            if ( p.ent != null && p.ent.IsValid() )
                p.ent.Destroy();
        }
        this._popups = [];
    },

    function _listIds( hPlayer ) {
        local line = this._t( hPlayer, "ids_hdr" );
        foreach ( def in ::g_AchDefs )
            line += " " + def.id;
        this._msg( hPlayer, line );
    },

    function _printHelp( hPlayer ) {
        this._msgId( hPlayer, "help_title" );
        this._msgId( hPlayer, "help_list" );
        this._msgId( hPlayer, "help_help" );
        this._msgId( hPlayer, "help_test" );
        this._msgId( hPlayer, "help_reset" );
        this._msgId( hPlayer, "help_toggle" );
        this._msgId( hPlayer, "help_hud" );
        this._msgId( hPlayer, "help_lang" );
    },

    function _printList( hPlayer ) {
        local touched = this._touch( hPlayer );
        if ( touched == null ) {
            this._msgId( hPlayer, "steam" );
            return;
        }
        local lang = this._langOf( hPlayer );
        local rec = touched.rec;
        local any = false;
        local hidden = 0;
        foreach ( def in ::g_AchDefs ) {
            if ( !( def.id in rec.unlocked ) ) {
                hidden += 1;
                continue;
            }
            local title = this._titleOf( def, lang );
            local desc = this._descOf( def, lang );
            this._msgId( hPlayer, "list_open", { title = title } );
            if ( desc != null && desc != "" && desc != def.id )
                this._msg( hPlayer, "    " + desc );
            any = true;
        }
        if ( !any )
            this._msgId( hPlayer, "none" );
        if ( hidden > 0 )
            this._msgId( hPlayer, "hidden_left", { n = hidden } );
    },

    function _testPopup( hPlayer, arg ) {
        if ( !this._isAdmin( hPlayer ) ) {
            this._msgId( hPlayer, "no_perm" );
            return;
        }
        local hMarine = hPlayer.GetMarine();
        if ( hMarine == null || !hMarine.IsValid() ) {
            this._msgId( hPlayer, "need_marine" );
            return;
        }
        if ( !( "variables" in this ) || this.variables.popup == 0 ) {
            this._msgId( hPlayer, "popup_off" );
            return;
        }
        if ( arg == null || arg == "" ) {
            this._msgId( hPlayer, "test_usage" );
            this._listIds( hPlayer );
            return;
        }
        local def = this._findDef( arg );
        if ( def == null ) {
            this._msgId( hPlayer, "unknown_id", { arg = arg } );
            this._listIds( hPlayer );
            return;
        }
        if ( !this._showPopup( hMarine, def, hPlayer ) ) {
            this._msgId( hPlayer, "popup_off" );
            return;
        }
        this._msgId( hPlayer, "test_ok", {
            title = this._titleOf( def, this._langOf( hPlayer ) ),
            id = def.id,
        } );
    },

    function _parseAccountKey( raw ) {
        if ( raw == null )
            return null;
        raw = this._trim( raw );
        if ( raw == "" )
            return null;
        if ( "McAuth" in getroottable() ) {
            local acc = ::McAuth.AccountIdFromString( raw );
            if ( acc != null )
                return acc.tostring();
        }
        try {
            local n = raw.tointeger();
            if ( n > 0 )
                return n.tostring();
        } catch ( e ) {
        }
        return null;
    },

    function _resetCmd( hPlayer, arg ) {
        if ( !this._isAdmin( hPlayer ) ) {
            this._msgId( hPlayer, "no_perm" );
            return;
        }
        if ( arg == null || arg == "" ) {
            local selfKey = this._playerKey( hPlayer );
            if ( selfKey == null ) {
                this._msgId( hPlayer, "steam" );
                return;
            }
            this._wipe( selfKey );
            this._msgId( hPlayer, "wiped", { key = selfKey } );
            return;
        }
        local a = this._trim( arg ).tolower();
        if ( a == "all" ) {
            local ids = this._loadIndex();
            local n = 0;
            foreach ( id in ids ) {
                this._wipe( id );
                n += 1;
            }
            local selfKey = this._playerKey( hPlayer );
            if ( selfKey != null )
                this._wipe( selfKey );
            this._msgId( hPlayer, "wiped_all", { n = n } );
            return;
        }
        local key = this._parseAccountKey( arg );
        if ( key == null ) {
            this._msgId( hPlayer, "reset_usage" );
            return;
        }
        this._wipe( key );
        this._msgId( hPlayer, "wiped", { key = key } );
    },

    function _handleCommand( hPlayer, cmd, arg ) {
        if ( cmd == "!ach" ) {
            this._printList( hPlayer );
            return;
        }
        if ( cmd == "!ach_help" ) {
            this._printHelp( hPlayer );
            return;
        }
        if ( cmd == "!ach_test" ) {
            this._testPopup( hPlayer, arg );
            return;
        }
        if ( cmd == "!ach_reset" ) {
            this._resetCmd( hPlayer, arg );
            return;
        }
        this._printHelp( hPlayer );
    },

    function OnGameEvent_entity_killed( params ) {
        if ( params == null )
            return;
        if ( !( "entindex_killed" in params ) )
            return;
        local victim = EntIndexToHScript( params["entindex_killed"] );
        if ( victim == null || !victim.IsValid() )
            return;

        local attackerRaw = null;
        if ( "entindex_attacker" in params )
            attackerRaw = EntIndexToHScript( params["entindex_attacker"] );
        local inflictorRaw = null;
        if ( "entindex_inflictor" in params )
            inflictorRaw = EntIndexToHScript( params["entindex_inflictor"] );

        local hVictimPlayer = this._commanderOfMarine( victim );
        if ( hVictimPlayer != null ) {
            local vKey = this._playerKey( hVictimPlayer );
            local para = null;
            if ( this._isParasite( attackerRaw ) )
                para = attackerRaw;
            else if ( this._isParasite( inflictorRaw ) )
                para = inflictorRaw;
            if ( para != null && vKey != null )
                this._onParasiteTouchedPlayer( para, vKey );
        }

        if ( !( "entindex_attacker" in params ) )
            return;
        local attacker = attackerRaw;
        attacker = this._asMarine( attacker );
        if ( attacker == null && ( "entindex_inflictor" in params ) )
            attacker = this._asMarine( EntIndexToHScript( params["entindex_inflictor"] ) );
        if ( attacker == null )
            return;
        if ( attacker == victim )
            return;

        local hKiller = this._commanderOfMarine( attacker );
        local hVictim = this._commanderOfMarine( victim );
        if ( hKiller == null || hVictim == null )
            return;

        local kKey = this._playerKey( hKiller );
        local vKey = this._playerKey( hVictim );
        if ( kKey == null )
            return;

        this._touch( hKiller );
        if ( vKey != null )
            this._load( vKey );
        this._noteMarineKill( kKey );

        local ctx = this._makeCtx( kKey, hKiller, attacker );
        foreach ( def in ::g_AchDefs ) {
            if ( this._isUnlocked( kKey, def.id ) )
                continue;
            if ( !( "OnMarineKilled" in def ) )
                continue;
            def.OnMarineKilled( ctx, hKiller, hVictim, kKey, vKey );
        }
    },

    function OnGameEvent_marine_infested( params ) {
        if ( params == null || !( "entindex" in params ) )
            return;
        local hMarine = EntIndexToHScript( params["entindex"] );
        local hVictim = this._commanderOfMarine( hMarine );
        if ( hVictim == null )
            return;
        local vKey = this._playerKey( hVictim );
        if ( vKey == null )
            return;
        local para = this._findInfestingParasite( hMarine );
        if ( para != null )
            this._onParasiteTouchedPlayer( para, vKey );
    },

    function OnGameEvent_marine_infested_killed( params ) {
        if ( params == null )
            return;
        local hPlayer = null;
        if ( ( "userid" in params ) && params["userid"] != null && params["userid"] != 0 )
            hPlayer = GetPlayerFromUserID( params["userid"] );
        local hMarine = null;
        if ( "marine" in params )
            hMarine = EntIndexToHScript( params["marine"] );
        local key = this._playerKey( hPlayer );
        if ( key == null && hMarine != null && hMarine.IsValid() ) {
            try {
                local cmd = hMarine.GetCommander();
                key = this._playerKey( cmd );
            } catch ( e ) {
            }
        }
        if ( key == null || hMarine == null )
            return;
        this._queueHeartSpawn( hMarine, key );
    },

    function OnGameEvent_player_activate( params ) {
        if ( !( "userid" in params ) )
            return;
        local hPlayer = GetPlayerFromUserID( params["userid"] );
        if ( hPlayer )
            this._touch( hPlayer );
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

        local prefix = this._CMD_PREFIX;
        if ( text.len() < prefix.len() )
            return;
        if ( text.slice( 0, prefix.len() ).tolower() != prefix )
            return;
        if ( text.len() > prefix.len() ) {
            local nextCh = text.slice( prefix.len(), prefix.len() + 1 );
            if ( nextCh != "_" && nextCh != " " )
                return;
        }

        local hPlayer = GetPlayerFromUserID( params["userid"] );
        if ( hPlayer == null || !hPlayer.IsValid() )
            return;

        local full = text.tolower();
        local cmd = full;
        local arg = null;
        local sp = full.find( " " );
        if ( sp != null ) {
            cmd = full.slice( 0, sp );
            arg = full.slice( sp + 1 );
            while ( arg.len() > 0 && arg.slice( 0, 1 ) == " " )
                arg = arg.slice( 1 );
            if ( arg.len() == 0 )
                arg = null;
        }
        this._handleCommand( hPlayer, cmd, arg );
    },

    function Update() {
        this._flushPopups();
        this._flushHeartSpawns();
    },

    function OnGameplayStart() {
        this._clearPopups();
        this._killTimes = null;
        this._clearHeartState();
    },

    function Cleanup() {
        this._clearPopups();
        this._killTimes = null;
        this._clearHeartState();
    },

    function OnDisable() {
        this._clearPopups();
        this._killTimes = null;
        this._clearHeartState();
        ::McLog.Info( "[MC] achievements disabled" );
    },

    function OnEnable() {
        ::McLog.Info( "[MC] achievements enabled" );
    },
};

::McRegistry.DeclareVariables( m, [
    [ "chat_notify", 0, "Print unlock to the player's chat (0 = popup only)", { kind = "bool" } ],
    [ "popup", 1, "Spawn world popup on unlock (needs client stub weapon_kills)", { kind = "bool" } ],
    [ "popup_lifetime", 3.5, "Popup visible duration in seconds", { min = 0.5, max = 15, step = 0.5 } ],
    [ "popup_delay", 0.4, "Delay before popup appears (seconds)", { min = 0, max = 3, step = 0.1 } ],
    [ "popup_x", 120.0, "Popup X offset px @768p (positive = right of the head)", { min = -400, max = 400, step = 4 } ],
    [ "popup_y", 48.0, "Popup Y offset px @768p (positive = below TK plate)", { min = -200, max = 200, step = 2 } ],
    [ "popup_stack_gap", 72.0, "Minimum distance between stacked popup centers (px @768p)", { min = 20, max = 400, step = 4 } ],
    [ "popup_icon_w", 32.0, "Icon width px @768p (square)", { min = 12, max = 96, step = 2 } ],
    [ "popup_icon_h", 32.0, "Icon height px @768p (square)", { min = 12, max = 96, step = 2 } ],
    [ "popup_scale", 1.0, "Popup scale multiplier", { min = 0.4, max = 3.0, step = 0.1 } ],
    [ "popup_accent", "255 150 40", "Stripe + nick RGB" ],
    [ "popup_text", "255 220 180", "Title RGB" ],
    [ "popup_bg", "24 12 4", "Background panel RGB" ],
    [ "popup_bg_alpha", 225, "Background alpha 0-255", { min = 0, max = 255, step = 5 } ],
    [ "popup_alpha", 230, "Icon/text max alpha 0-255", { min = 0, max = 255, step = 5 } ],
] );

::McRegistry.Register( m );

} // AchievementsLoaded
