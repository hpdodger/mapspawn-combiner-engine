// mapspawn_combiner/modules/weapon_kills/module_weapon_kills.nut
// Счётчик убийств по трекам оружия (strange-like).
// Подсчёт: OnTakeDamage_Alive_Any — inhabited marine → alien, lethal hit, оружие в треке.
// Persist: save/vscripts/weapon_kills/<accountId>.txt + index.txt
// HUD: rd_hud_vscript + client weapon_kills/wkc_popup_hud.nut (stub challenge weapon_kills).
// Чат: !wkc / !wkc_help / !wkc_reset / !wkc_test (test — McAuth).
// Вкл/выкл: !am_enable / !am_disable weapon_kills

if ( "WeaponKillsLoaded" in getroottable() ) {
    ::McLog.Info( "[MC] weapon_kills: already loaded, skip" );
} else {
    getroottable().WeaponKillsLoaded <- true;

IncludeScript( "mapspawn_combiner/modules/weapon_kills/tracks" );
IncludeScript( "mapspawn_combiner/modules/weapon_kills/tiers" );

local _strings = {
    tip = {
        en = "weapon kills — !wkc / !wkc_help",
        ru = "убийства с оружия — !wkc / !wkc_help",
    },
    help_title = {
        en = "weapon kills — tracks + world popup",
        ru = "убийства с оружия — треки + popup",
    },
    help_wkc = {
        en = "!wkc — your track counts",
        ru = "!wkc — ваши счётчики",
    },
    help_help = {
        en = "!wkc_help — this help",
        ru = "!wkc_help — эта справка",
    },
    help_reset = {
        en = "!wkc_reset — wipe your saved tracks (admin)",
        ru = "!wkc_reset — сбросить свои треки (admin)",
    },
    help_test = {
        en = "!wkc_test <id|classname> — test popup icon (admin)",
        ru = "!wkc_test <id|classname> — тестовый popup (admin)",
    },
    help_test_ex = {
        en = "  e.g. !wkc_test rifle  /  !wkc_test asw_weapon_deagle",
        ru = "  напр. !wkc_test rifle  /  !wkc_test asw_weapon_deagle",
    },
    help_toggle = {
        en = "toggle: !am_enable / !am_disable weapon_kills",
        ru = "вкл/выкл: !am_enable / !am_disable weapon_kills",
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
    no_tracks = {
        en = "no tracks configured",
        ru = "треки не настроены",
    },
    wiped = {
        en = "tracks wiped",
        ru = "треки обнулены",
    },
    test_usage = {
        en = "usage: !wkc_test <track_id|classname>",
        ru = "использование: !wkc_test <track_id|classname>",
    },
    unknown_track = {
        en = "unknown weapon/track: {arg}",
        ru = "неизвестное оружие/трек: {arg}",
    },
    tracks_hdr = {
        en = "tracks:",
        ru = "треки:",
    },
    test_ok = {
        en = "test popup: {label} [{id}] {n}",
        ru = "тест popup: {label} [{id}] {n}",
    },
    stats_line = {
        en = "{label}: {count}",
        ru = "{label}: {count}",
    },
    stats_next = {
        en = " → next {next}",
        ru = " → следующий {next}",
    },
    chat_tier = {
        en = "{name} — {label}: {tier}",
        ru = "{name} — {label}: {tier}",
    },
};

local m = {
    name        = "weapon_kills",
    enabled     = true,
    convars     = {},
    version     = "0.4.5",
    description = "Per-weapon kill tracks (strange-like): count, save, !wkc, world popup.",
    requires_registry = 4,

    console_info = [
        "=== weapon_kills ===",
        "Counts alien kills per weapon track; tier-up shows EquipIcon + number over the marine.",
        "Client Paint needs challenge stub weapon_kills (required_on_client) on the client.",
        "Chat: !wkc / !wkc_help / !wkc_reset (admin) / !wkc_test (admin, force popup)",
        "Language: !mc_lang en|ru (shared McI18n, default en)",
        "Tunables: !am_vars weapon_kills",
        "Colors are RGB strings, e.g. !am_set weapon_kills popup_accent \"80 180 255\"",
        "Position (px @768p): popup_x (left of head), popup_y (above head = negative)",
        "Size: popup_scale multiplies icon/offsets (1.0 = default @768p)",
    ],

    _PREFIX     = "[WK] ",
    _CMD_PREFIX = "!wkc",
    _DIR        = "weapon_kills/",
    _INDEX      = "weapon_kills/index.txt",
    _SEP        = "=",
    _CLIENT_SCRIPT = "weapon_kills/wkc_popup_hud.nut",
    _strings    = _strings,

    // Пороги: ::WkcFixedTiers / ::WkcStepTier в tiers.nut

    _cache  = null,   // accountId -> { tracks = { id = count }, name = "…" }
    _popups = null,   // [ { ent, marine, hideAt }, … ]

    // ---------- messaging / i18n ----------

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

    function _broadcast( text ) {
        ClientPrint( null, HudPrint.Talk, this._PREFIX + text );
    },

    // ---------- tracks lookup ----------

    function _rebuildWeaponIndex() {
        ::WkcWeaponIndex = {};
        for ( local i = 0; i < ::WkcTracks.len(); i++ ) {
            local tr = ::WkcTracks[i];
            foreach ( w in tr.weapons )
                ::WkcWeaponIndex[w] <- i;
        }
    },

    function _trackByWeapon( classname ) {
        if ( classname == null || !( classname in ::WkcWeaponIndex ) )
            return null;
        return ::WkcTracks[::WkcWeaponIndex[classname]];
    },

    function _labelOf( track, lang ) {
        if ( track == null )
            return "?";
        if ( "McI18n" in getroottable() )
            return ::McI18n.Label( track.label, lang );
        if ( lang == "en" && ( "en" in track.label ) )
            return track.label.en;
        if ( "ru" in track.label )
            return track.label.ru;
        if ( "en" in track.label )
            return track.label.en;
        return track.id;
    },

    // ---------- tiers ----------

    // Высший достигнутый порог для count; 0 если ни одного.
    function _tierOf( count ) {
        if ( count == null || count < 1 )
            return 0;
        local best = 0;
        foreach ( t in ::WkcFixedTiers ) {
            if ( count >= t )
                best = t;
        }
        local step = ::WkcStepTier;
        if ( count >= step ) {
            local t = ( count / step ).tointeger() * step;
            if ( t > best )
                best = t;
        }
        return best;
    },

    // Следующий порог после count, или null.
    function _nextTier( count ) {
        if ( count == null )
            count = 0;
        foreach ( t in ::WkcFixedTiers ) {
            if ( count < t )
                return t;
        }
        local step = ::WkcStepTier;
        local cur = this._tierOf( count );
        if ( cur < step )
            return step;
        return cur + step;
    },

    // ---------- persist ----------

    function _playerFile( id ) {
        return this._DIR + id + ".txt";
    },

    function _splitLines( raw ) {
        local lines = [];
        if ( raw == null || raw == "" )
            return lines;
        local start = 0;
        local n = raw.len();
        for ( local i = 0; i < n; i++ ) {
            if ( raw.slice( i, i + 1 ) != "\n" )
                continue;
            local line = raw.slice( start, i );
            if ( line.len() > 0 && line.slice( line.len() - 1 ) == "\r" )
                line = line.slice( 0, line.len() - 1 );
            lines.append( line );
            start = i + 1;
        }
        if ( start < n ) {
            local line = raw.slice( start );
            if ( line.len() > 0 && line.slice( line.len() - 1 ) == "\r" )
                line = line.slice( 0, line.len() - 1 );
            lines.append( line );
        }
        return lines;
    },

    function _loadIndex() {
        local ids = [];
        foreach ( line in this._splitLines( FileToString( this._INDEX ) ) ) {
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

    function _sanitizeName( name ) {
        if ( name == null || name == "" )
            return "?";
        name = name.tostring();
        local out = "";
        for ( local i = 0; i < name.len(); i++ ) {
            local ch = name.slice( i, i + 1 );
            if ( ch == "|" || ch == "\n" || ch == "\r" )
                out += " ";
            else
                out += ch;
        }
        return out;
    },

    // Файл: строки trackId=count; опционально #name=…
    function _parsePlayerFile( raw ) {
        local tracks = {};
        local name = "?";
        foreach ( line in this._splitLines( raw ) ) {
            if ( line.len() == 0 )
                continue;
            if ( line.len() >= 6 && line.slice( 0, 6 ) == "#name=" ) {
                name = line.slice( 6 );
                continue;
            }
            local eq = line.find( this._SEP );
            if ( eq == null || eq < 1 )
                continue;
            local tid = line.slice( 0, eq );
            local val = line.slice( eq + 1 );
            try {
                local c = val.tointeger();
                if ( c < 0 )
                    c = 0;
                tracks[tid] <- c;
            } catch ( e ) {
            }
        }
        return { tracks = tracks, name = name };
    },

    function _serializePlayer( rec ) {
        local out = "#name=" + this._sanitizeName( rec.name ) + "\n";
        foreach ( tid, c in rec.tracks )
            out += tid + this._SEP + c.tostring() + "\n";
        return out;
    },

    function _load( id ) {
        if ( this._cache == null )
            this._cache = {};
        if ( id in this._cache )
            return this._cache[id];

        local parsed = this._parsePlayerFile( FileToString( this._playerFile( id ) ) );
        local rec = { tracks = parsed.tracks, name = parsed.name };
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
        if ( !( "McAuth" in getroottable() ) )
            return null;
        local id = ::McAuth.PlayerKey( hPlayer );
        if ( id == null )
            return null;
        local rec = this._load( id );
        rec.name = hPlayer.GetPlayerName();
        return { id = id, rec = rec };
    },

    function _countOf( rec, trackId ) {
        if ( rec == null || !( "tracks" in rec ) )
            return 0;
        if ( trackId in rec.tracks )
            return rec.tracks[trackId];
        return 0;
    },

    function _addKill( hPlayer, track ) {
        local touched = this._touch( hPlayer );
        if ( touched == null )
            return null;
        local id = touched.id;
        local rec = touched.rec;
        local tid = track.id;
        local before = this._countOf( rec, tid );
        local after = before + 1;
        rec.tracks[tid] <- after;
        this._save( id );
        return { before = before, after = after, track = track };
    },

    // ---------- chat commands ----------

    function _isAdmin( hPlayer ) {
        return ( "McAuth" in getroottable() ) && ::McAuth.IsAdmin( hPlayer );
    },

    function _printHelp( hPlayer ) {
        this._msgId( hPlayer, "help_title" );
        this._msgId( hPlayer, "help_wkc" );
        this._msgId( hPlayer, "help_help" );
        this._msgId( hPlayer, "help_reset" );
        this._msgId( hPlayer, "help_test" );
        this._msgId( hPlayer, "help_test_ex" );
        this._msgId( hPlayer, "help_toggle" );
        this._msgId( hPlayer, "help_hud" );
        this._msgId( hPlayer, "help_lang" );
    },

    // query: track id ("rifle") или classname ("asw_weapon_rifle" / "rifle" после asw_weapon_).
    function _findTrack( query ) {
        if ( query == null )
            return null;
        local q = query.tostring().tolower();
        while ( q.len() > 0 && q.slice( 0, 1 ) == " " )
            q = q.slice( 1 );
        while ( q.len() > 0 && q.slice( q.len() - 1 ) == " " )
            q = q.slice( 0, q.len() - 1 );
        if ( q.len() == 0 )
            return null;

        foreach ( track in ::WkcTracks ) {
            if ( track.id.tolower() == q )
                return track;
        }
        if ( q in ::WkcWeaponIndex )
            return ::WkcTracks[::WkcWeaponIndex[q]];

        local full = q;
        if ( q.len() < 11 || q.slice( 0, 11 ) != "asw_weapon_" )
            full = "asw_weapon_" + q;
        if ( full in ::WkcWeaponIndex )
            return ::WkcTracks[::WkcWeaponIndex[full]];

        return null;
    },

    function _listTrackIds( hPlayer ) {
        local line = this._t( hPlayer, "tracks_hdr" );
        local n = 0;
        foreach ( track in ::WkcTracks ) {
            if ( n > 0 && ( n % 8 ) == 0 ) {
                this._msg( hPlayer, line );
                line = " ";
            }
            line += " " + track.id;
            n += 1;
        }
        if ( line.len() > 1 )
            this._msg( hPlayer, line );
    },

    function _printStats( hPlayer ) {
        local touched = this._touch( hPlayer );
        if ( touched == null ) {
            this._msgId( hPlayer, "steam" );
            return;
        }
        local lang = this._langOf( hPlayer );
        local rec = touched.rec;
        local any = false;
        foreach ( track in ::WkcTracks ) {
            local c = this._countOf( rec, track.id );
            local next = this._nextTier( c );
            local label = this._labelOf( track, lang );
            local line = this._t( hPlayer, "stats_line", { label = label, count = c } );
            if ( next != null )
                line += this._t( hPlayer, "stats_next", { next = next } );
            this._msg( hPlayer, line );
            any = true;
        }
        if ( !any )
            this._msgId( hPlayer, "no_tracks" );
    },

    function _resetPlayer( hPlayer ) {
        if ( !this._isAdmin( hPlayer ) ) {
            this._msgId( hPlayer, "no_perm" );
            return;
        }
        local touched = this._touch( hPlayer );
        if ( touched == null ) {
            this._msgId( hPlayer, "steam" );
            return;
        }
        touched.rec.tracks = {};
        this._save( touched.id );
        this._msgId( hPlayer, "wiped" );
    },

    function _testPopup( hPlayer, arg ) {
        // Проверка прав — при выполнении, не в help.
        if ( !this._isAdmin( hPlayer ) ) {
            this._msgId( hPlayer, "no_perm" );
            return;
        }
        local hMarine = hPlayer.GetMarine();
        if ( hMarine == null || !hMarine.IsValid() ) {
            this._msgId( hPlayer, "need_marine" );
            return;
        }
        if ( ::WkcTracks.len() < 1 ) {
            this._msgId( hPlayer, "no_tracks" );
            return;
        }
        if ( arg == null || arg == "" ) {
            this._msgId( hPlayer, "test_usage" );
            this._listTrackIds( hPlayer );
            return;
        }
        local track = this._findTrack( arg );
        if ( track == null ) {
            this._msgId( hPlayer, "unknown_track", { arg = arg } );
            this._listTrackIds( hPlayer );
            return;
        }
        // Тест: накрутка 0 → 127 (цвет как у обычного popup — popup_text)
        local n = 127;
        this._showPopup( hMarine, track, n, 0 );
        local lang = this._langOf( hPlayer );
        this._msgId( hPlayer, "test_ok", {
            label = this._labelOf( track, lang ),
            id = track.id,
            n = n,
        } );
    },

    function _handleCommand( hPlayer, cmd, arg ) {
        if ( cmd == "!wkc" || cmd == "!wkc_stats" ) {
            this._printStats( hPlayer );
            return;
        }
        if ( cmd == "!wkc_help" ) {
            this._printHelp( hPlayer );
            return;
        }
        if ( cmd == "!wkc_reset" ) {
            this._resetPlayer( hPlayer );
            return;
        }
        if ( cmd == "!wkc_test" ) {
            if ( !this._isAdmin( hPlayer ) ) {
                this._msgId( hPlayer, "no_perm" );
                return;
            }
            this._testPopup( hPlayer, arg );
            return;
        }
        // неизвестная !wkc_* — краткая справка
        this._printHelp( hPlayer );
    },

    // ---------- world popup (rd_hud_vscript) ----------

    // "R G B" → [r,g,b] 0..255; битый ввод → fallback.
    function _parseRgb( raw, fallback ) {
        local fb = fallback;
        if ( fb == null )
            fb = [ 255, 255, 255 ];
        if ( raw == null )
            return [ fb[0], fb[1], fb[2] ];
        local s = raw.tostring();
        // trim
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
        local accent = this._parseRgb( v.popup_accent, [ 80, 180, 255 ] );
        local text = this._parseRgb( v.popup_text, [ 255, 0, 0 ] );
        local bg = this._parseRgb( v.popup_bg, [ 8, 14, 28 ] );

        // Int 3..5 accent RGB (полоска + tint иконки)
        e.SetInt( 3, accent[0] );
        e.SetInt( 4, accent[1] );
        e.SetInt( 5, accent[2] );
        // Int 6..8 text RGB
        e.SetInt( 6, text[0] );
        e.SetInt( 7, text[1] );
        e.SetInt( 8, text[2] );
        // Int 9..11 bg RGB; Int 12 bg alpha; Int 13 content max alpha
        e.SetInt( 9, bg[0] );
        e.SetInt( 10, bg[1] );
        e.SetInt( 11, bg[2] );
        e.SetInt( 12, this._clampByte( v.popup_bg_alpha, 225 ) );
        e.SetInt( 13, this._clampByte( v.popup_alpha, 230 ) );
        e.SetInt( 14, 1 );   // style marker: 1 = сервер записал цвета/layout

        // Float 2..7 layout @768p + scale multiplier
        e.SetFloat( 2, v.popup_x.tofloat() );
        e.SetFloat( 3, v.popup_y.tofloat() );
        e.SetFloat( 4, v.popup_stack_gap.tofloat() );
        e.SetFloat( 5, v.popup_icon_w.tofloat() );
        e.SetFloat( 6, v.popup_icon_h.tofloat() );
        e.SetFloat( 7, v.popup_scale.tofloat() );
        e.SetFloat( 8, v.popup_anim_time.tofloat() );
    },

    // track — ::WkcTracks; threshold — конечное число; animFrom — старт накрутки (обычно прошлый тир).
    function _showPopup( hMarine, track, threshold, animFrom ) {
        if ( hMarine == null || !hMarine.IsValid() )
            return;
        if ( !( "variables" in this ) || this.variables.popup == 0 )
            return;
        if ( track == null || threshold < 1 )
            return;
        if ( animFrom == null )
            animFrom = 0;
        animFrom = animFrom.tointeger();
        if ( animFrom < 0 )
            animFrom = 0;
        if ( animFrom > threshold )
            animFrom = threshold;

        local delay = this.variables.popup_delay.tofloat();
        if ( delay < 0.0 )
            delay = 0.0;
        local life = this.variables.popup_lifetime.tofloat();
        if ( life < 0.5 )
            life = 0.5;

        local icon = "";
        if ( ( "icon" in track ) && track.icon != null )
            icon = track.icon.tostring();

        local now = Time();
        local showAt = now + delay;
        local hideAt = showAt + life;
        local stack = this._stackIndexForMarine( hMarine );

        local e = Entities.CreateByClassname( "rd_hud_vscript" );
        if ( e == null || !e.IsValid() ) {
            ::McLog.Err( "[WK] failed to create rd_hud_vscript" );
            return;
        }
        e.__KeyValueFromString( "client_vscript", this._CLIENT_SCRIPT );
        e.Spawn();
        e.Activate();
        e.SetEntity( 0, hMarine );
        e.SetString( 0, icon );   // путь EquipIcon — клиент без своей таблицы треков
        e.SetInt( 0, animFrom );  // старт накрутки
        e.SetInt( 1, threshold ); // конец накрутки / порог
        e.SetInt( 2, stack );
        e.SetFloat( 0, showAt );
        e.SetFloat( 1, hideAt );
        this._writePopupStyle( e );

        if ( this._popups == null )
            this._popups = [];
        this._popups.append( { ent = e, marine = hMarine, hideAt = hideAt } );
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

    // ---------- join tip ----------

    // ---------- hooks ----------

    // MUST return damage unchanged on every path.
    function OnTakeDamage_Alive_Any( victim, inflictor, attacker, weapon, damage, damageType, ammoName ) {
        if ( victim == null || !victim.IsValid() )
            return damage;
        if ( attacker == null || !attacker.IsValid() )
            return damage;
        if ( attacker.GetClassname() != "asw_marine" )
            return damage;
        if ( !attacker.IsInhabited() )
            return damage;
        if ( !victim.IsAlien() )
            return damage;
        if ( weapon == null || !weapon.IsValid() )
            return damage;

        local track = this._trackByWeapon( weapon.GetClassname() );
        if ( track == null )
            return damage;

        // Lethal blow only (damage about to drop health to 0).
        local hp = victim.GetHealth();
        if ( hp == null || damage < hp )
            return damage;

        local hPlayer = attacker.GetCommander();
        if ( hPlayer == null || !hPlayer.IsValid() )
            return damage;

        local result = this._addKill( hPlayer, track );
        if ( result == null )
            return damage;

        local beforeTier = this._tierOf( result.before );
        local afterTier = this._tierOf( result.after );
        if ( afterTier > beforeTier ) {
            // По умолчанию только popup; чат — если chat_notify=1 (язык убийцы)
            if ( ( "variables" in this ) && this.variables.chat_notify != 0 ) {
                local lang = this._langOf( hPlayer );
                this._broadcast( this._t( hPlayer, "chat_tier", {
                    name = hPlayer.GetPlayerName(),
                    label = this._labelOf( result.track, lang ),
                    tier = afterTier,
                } ) );
            }
            ::McLog.Info( "[WK] tier " + result.track.id + " -> " + afterTier
                + " (" + hPlayer.GetPlayerName() + ")" );

            this._showPopup( attacker, result.track, afterTier, beforeTier );
        }

        return damage;
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
    },

    function OnGameplayStart() {
        // tips re-queue via player_activate; cache of kills stays across missions
        this._clearPopups();
    },

    function Cleanup() {
        this._clearPopups();
    },

    function OnDisable() {
        this._clearPopups();
        ::McLog.Info( "[MC] weapon_kills disabled (counting and !wkc paused)" );
    },

    function OnEnable() {
        ::McLog.Info( "[MC] weapon_kills enabled" );
    },
};

m._rebuildWeaponIndex();

::McRegistry.DeclareVariables( m, [
    [ "chat_notify", 0, "Also print tier-up to chat (0 = popup only, 1 = chat + popup)", { kind = "bool" } ],
    [ "popup", 1, "Spawn world popup on tier-up (needs client stub weapon_kills)", { kind = "bool" } ],
    [ "popup_lifetime", 3.5, "Popup visible duration in seconds", { min = 0.5, max = 15, step = 0.5 } ],
    [ "popup_delay", 0.4, "Delay before popup appears (seconds)", { min = 0, max = 3, step = 0.1 } ],
    [ "popup_anim_time", 0.75, "Seconds to spin the number from previous tier to new (0 = instant)", { min = 0, max = 3, step = 0.05 } ],
    // Layout @768p (negative X = left of head, negative Y = above head)
    [ "popup_x", -120.0, "Popup X offset px @768p (more negative = further left of strange)", { min = -400, max = 200, step = 4 } ],
    [ "popup_y", -20.0, "Popup Y offset px @768p (negative = above head)", { min = -200, max = 200, step = 2 } ],
    [ "popup_stack_gap", 72.0, "Horizontal gap between stacked popups (px @768p)", { min = 20, max = 200, step = 4 } ],
    [ "popup_icon_w", 56.0, "EquipIcon width px @768p (stock icons are 2:1)", { min = 16, max = 128, step = 2 } ],
    [ "popup_icon_h", 28.0, "EquipIcon height px @768p", { min = 8, max = 64, step = 2 } ],
    [ "popup_scale", 1.0, "Popup scale multiplier (1.0 = default; affects icon, offsets, gaps)", { min = 0.4, max = 3.0, step = 0.1 } ],
    // Colors as "R G B" strings (0-255)
    [ "popup_accent", "80 180 255", "Stripe + icon tint RGB" ],
    [ "popup_text", "255 0 0", "Tier number RGB" ],
    [ "popup_bg", "8 14 28", "Background panel RGB" ],
    [ "popup_bg_alpha", 225, "Background alpha 0-255", { min = 0, max = 255, step = 5 } ],
    [ "popup_alpha", 230, "Icon/text max alpha 0-255", { min = 0, max = 255, step = 5 } ],
] );

::McRegistry.Register( m );

} // WeaponKillsLoaded
