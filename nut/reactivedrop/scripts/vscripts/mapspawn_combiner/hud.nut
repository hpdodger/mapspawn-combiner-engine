// mapspawn_combiner/hud.nut
// Показ мировых попапов (weapon_kills / tk_counter) на экране конкретного игрока.
// Persist: save/vscripts/mc_hud/<accountId>.txt (одна строка: 1 = показывать, 0 = скрыть).
// Команда: !mc_popups (модуль lang). Клиент читает маску в Int 22 попапа.

if ( !( "McHud" in getroottable() ) ) {

::McHud <- {
    version = 1,
    _DIR     = "mc_hud/",
    _cache   = null,   // accountId -> bool (true = скрыть)
    _session = null,   // entindex -> bool, без SteamID (LAN/BOT), только эта карта

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

    function HideMask() {
        local mask = 0;
        local p = Entities.FindByClassname( null, "player" );
        while ( p != null ) {
            if ( p.IsValid() && this.Hidden( p ) ) {
                local bit = p.entindex() - 1;
                if ( bit >= 0 && bit < 32 )
                    mask = mask | ( 1 << bit );
            }
            p = Entities.FindByClassname( p, "player" );
        }
        return mask;
    },

    function ApplyMask( e ) {
        if ( e == null || !e.IsValid() )
            return;
        e.SetInt( 22, this.HideMask() );
    },

    function _writeModulePopups( name, mask ) {
        if ( !( "McRegistry" in getroottable() ) )
            return;
        local m = ::McRegistry.FindModule( name );
        if ( m == null || !( "_popups" in m ) || m._popups == null )
            return;
        foreach ( rec in m._popups ) {
            if ( rec == null )
                continue;
            if ( rec.ent != null && rec.ent.IsValid() )
                rec.ent.SetInt( 22, mask );
        }
    },

    function RefreshLivePopups() {
        local mask = this.HideMask();
        this._writeModulePopups( "weapon_kills", mask );
        this._writeModulePopups( "tk_counter", mask );
    },
};

::McLog.Info( "[MC] hud prefs ready (popups on by default)" );

} // McHud
