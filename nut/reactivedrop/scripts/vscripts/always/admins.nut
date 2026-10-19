// SteamID с правом на !ao_enable / !ao_disable / !ao_save и т.п.
// Формат как в status: "STEAM_1:0:12345678"

::g_AlwaysAdmins <- [
    // "STEAM_1:0:12345678",
    "STEAM_1:1:15246122",
]

// ── Разбор SteamID (свой код, без зависимости от других модулей) ─────────────

::_AlwaysTrimSpaces <- function( s ) {
    if ( s == null )
        return ""
    s = s.tostring()
    while ( s.len() > 0 && s.slice( 0, 1 ) == " " )
        s = s.slice( 1 )
    while ( s.len() > 0 && s.slice( s.len() - 1 ) == " " )
        s = s.slice( 0, s.len() - 1 )
    return s
}

::_AlwaysSplitColons <- function( s ) {
    local parts = []
    local start = 0
    local idx = s.find( ":", start )
    while ( idx != null ) {
        parts.append( s.slice( start, idx ) )
        start = idx + 1
        idx = s.find( ":", start )
    }
    parts.append( s.slice( start ) )
    return parts
}

::AlwaysAccountIdFromString <- function( raw ) {
    local s = _AlwaysTrimSpaces( raw )
    if ( s == "" )
        return null

    if ( s.len() >= 8 && s.slice( 0, 6 ) == "STEAM_" ) {
        local parts = _AlwaysSplitColons( s )
        if ( parts.len() != 3 )
            return null
        try {
            local y = parts[1].tointeger()
            local z = parts[2].tointeger()
            if ( y != 0 && y != 1 )
                return null
            if ( z < 0 )
                return null
            return z * 2 + y
        } catch ( e ) {
            return null
        }
    }

    if ( s.len() >= 7 && s.slice( 0, 5 ) == "[U:1:" && s.slice( s.len() - 1 ) == "]" ) {
        local inner = s.slice( 5, s.len() - 1 )
        try {
            local a = inner.tointeger()
            if ( a < 0 )
                return null
            return a
        } catch ( e ) {
            return null
        }
    }

    return null
}

::AlwaysPlayerKey <- function( hPlayer ) {
    if ( hPlayer == null || !hPlayer.IsValid() )
        return null
    local net = hPlayer.GetNetworkIDString()
    if ( net == null || net == "" )
        return null
    if ( net == "BOT" || net == "STEAM_ID_LAN" || net == "STEAM_ID_PENDING" )
        return null
    local acc = AlwaysAccountIdFromString( net )
    if ( acc == null )
        return null
    return acc.tostring()
}

::AlwaysIsAdmin <- function( hPlayer ) {
    local id = AlwaysPlayerKey( hPlayer )
    if ( id == null )
        return false
    foreach ( adminId in ::g_AlwaysAdmins ) {
        if ( adminId == null )
            continue
        local acc = AlwaysAccountIdFromString( adminId.tostring() )
        if ( acc != null && acc.tostring() == id )
            return true
    }
    return false
}
