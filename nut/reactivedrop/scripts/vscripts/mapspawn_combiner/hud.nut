// mapspawn_combiner/hud.nut
// Показ мировых попапов (weapon_kills / tk_counter) на экране конкретного игрока.
// Persist: save/vscripts/mc_hud/<accountId>.txt (одна строка: 1 = показывать, 0 = скрыть).
// Команда: !mc_popups (модуль lang).
// На клиенте у игрока нет entindex(); скрытие — отдельный rd_hud_vscript на игрока
// (Entity 0 = player, Int 23 = 1), Paint сравнивает с GetLocalPlayer().

if ( !( "McHud" in getroottable() ) ) {

::McHud <- {
    version = 1,
    _DIR      = "mc_hud/",
    _CLIENT   = "weapon_kills/wkc_popup_hud.nut",
    _cache    = null,   // accountId -> bool (true = скрыть)
    _session  = null,   // entindex -> bool, без SteamID (LAN/BOT), только эта карта
    _viewers  = null,   // [ { ent, player }, … ] — prefs HUD на каждого игрока

    function _playerFile( id ) {
        return this._DIR + id.tostring() + ".txt";
    },

    function _playerKey( hPlayer ) {
        if ( !( "McAuth" in getroottable() ) )
            return null;
        return ::McAuth.PlayerKey( hPlayer );
    },

    function _trimLine( raw ) {
        if ( raw == null )
            return "";
        local line = raw.tostring();
        local nl = line.find( "\n" );
        if ( nl != null )
            line = line.slice( 0, nl );
        if ( line.len() > 0 && line.slice( line.len() - 1 ) == "\r" )
            line = line.slice( 0, line.len() - 1 );
        while ( line.len() > 0 && line.slice( 0, 1 ) == " " )
            line = line.slice( 1 );
        while ( line.len() > 0 && line.slice( line.len() - 1 ) == " " )
            line = line.slice( 0, line.len() - 1 );
        return line.tolower();
    },

    // true = скрыть попапы на экране этого игрока.
    function ParseHidden( raw ) {
        local s = this._trimLine( raw );
        if ( s == "0" || s == "off" || s == "false" || s == "no" || s == "hide" )
            return true;
        if ( s == "1" || s == "on" || s == "true" || s == "yes" || s == "show" )
            return false;
        return null;
    },

    function _loadId( id ) {
        if ( this._cache == null )
            this._cache = {};
        if ( id in this._cache )
            return this._cache[id];

        local hidden = false;
        local raw = FileToString( this._playerFile( id ) );
        local parsed = this.ParseHidden( raw );
        if ( parsed != null )
            hidden = parsed;
        this._cache[id] <- hidden;
        return hidden;
    },

    function Hidden( hPlayer ) {
        if ( hPlayer == null || !hPlayer.IsValid() )
            return false;
        local id = this._playerKey( hPlayer );
        if ( id != null )
            return this._loadId( id );
        if ( this._session == null )
            return false;
        local slot = hPlayer.entindex();
        if ( slot in this._session )
            return this._session[slot];
        return false;
    },

    function SetHidden( hPlayer, hidden ) {
        if ( hPlayer == null || !hPlayer.IsValid() )
            return null;
        hidden = hidden ? true : false;
        local id = this._playerKey( hPlayer );
        if ( id != null ) {
            if ( this._cache == null )
                this._cache = {};
            this._cache[id] <- hidden;
            local line = hidden ? "0" : "1";
            StringToFile( this._playerFile( id ), line + "\n" );
        } else {
            if ( this._session == null )
                this._session = {};
            this._session[hPlayer.entindex()] <- hidden;
        }
        this.RefreshLivePopups();
        return hidden;
    },

    function _flushViewers() {
        if ( this._viewers == null )
            return;
        local keep = [];
        foreach ( rec in this._viewers ) {
            if ( rec == null )
                continue;
            if ( rec.player == null || !rec.player.IsValid() ) {
                if ( rec.ent != null && rec.ent.IsValid() )
                    rec.ent.Destroy();
                continue;
            }
            if ( rec.ent == null || !rec.ent.IsValid() )
                continue;
            keep.append( rec );
        }
        this._viewers = keep;
    },

    function EnsureViewer( hPlayer ) {
        if ( hPlayer == null || !hPlayer.IsValid() )
            return;
        this._flushViewers();
        local hidden = this.Hidden( hPlayer ) ? 1 : 0;
        if ( this._viewers != null ) {
            foreach ( rec in this._viewers ) {
                if ( rec.player == hPlayer ) {
                    rec.ent.SetEntity( 0, hPlayer );
                    rec.ent.SetInt( 22, hidden );
                    rec.ent.SetInt( 23, 1 );
                    return;
                }
            }
        }
        local e = Entities.CreateByClassname( "rd_hud_vscript" );
        if ( e == null || !e.IsValid() ) {
            ::McLog.Err( "[MC] hud: failed to create prefs rd_hud_vscript" );
            return;
        }
        e.__KeyValueFromString( "client_vscript", this._CLIENT );
        e.Spawn();
        e.Activate();
        e.SetEntity( 0, hPlayer );
        e.SetInt( 22, hidden );
        e.SetInt( 23, 1 );
        if ( this._viewers == null )
            this._viewers = [];
        this._viewers.append( { ent = e, player = hPlayer } );
    },

    // Оставлено: weapon_kills / tk_counter зовут после спавна попапа. Маска на
    // самой плашке клиенту не нужна (нет entindex), скрытие — prefs-сущность.
    function ApplyMask( e ) {
    },

    function RefreshLivePopups() {
        local p = Entities.FindByClassname( null, "player" );
        while ( p != null ) {
            if ( p.IsValid() )
                this.EnsureViewer( p );
            p = Entities.FindByClassname( p, "player" );
        }
    },
};

::McLog.Info( "[MC] hud prefs ready (popups on by default)" );

} // McHud
