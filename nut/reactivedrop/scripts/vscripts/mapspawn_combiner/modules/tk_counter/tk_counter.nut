// TK Counter — core module (server-only).
// IncludeScript( "mapspawn_combiner/modules/tk_counter/tk_counter", worldspawn.GetScriptScope() )
//
// Data next to this file:
//   ranks.nut     — breakpoints + titles
//   announce.nut  — red notice template + layout
// Admin whitelist: ::McAuth in mapspawn_combiner/admins.nut

IncludeScript( "mapspawn_combiner/modules/tk_counter/version" )
IncludeScript( "mapspawn_combiner/modules/tk_counter/ranks" )
IncludeScript( "mapspawn_combiner/modules/tk_counter/announce" )

// ── Config ───────────────────────────────────────────────────────────────────

const TK_DIR          = "tk_counter"
const TK_INDEX_FILE   = "tk_counter/index.txt"
const TK_TOP_N        = 10
const TK_HUD_TALK     = 3
const TK_TAG          = "[TKC] "
const TK_CMD_PREFIX   = "!tkc"
const TK_TEXT_Y       = "0.38"
const TK_TEXT_COLOR   = "255 40 40 255"
const TK_TEXT_HOLD    = "4"
const TK_TIP_DELAY    = 3.0
const TK_CLASS_MARINE = "asw_marine"
const TK_SEP          = "|"
const TK_EM_DASH      = " — "

const TK_LANG_RU = "ru"
const TK_LANG_EN = "en"
// ASRD Squirrel: const may only be a literal, not another const
// Дефолт языка системы — en (::McI18n). Локальный fallback, если i18n ещё не загружен.
const TK_DEFAULT_LANG = "en"

const TK_CMD_HELP  = "!tkc_help"
const TK_CMD_ME    = "!tkc"
const TK_CMD_TOP   = "!tkc_top"
const TK_CMD_NEXT  = "!tkc_next"
const TK_CMD_RANKS = "!tkc_ranks"
const TK_CMD_LANG  = "!tkc_lang"
const TK_CMD_ON    = "!tkc_on"
const TK_CMD_OFF   = "!tkc_off"
const TK_CMD_RESET = "!tkc_reset"
const TK_CMD_TEST  = "!tkc_test"

// Message ids → translations[lang]
const TK_MSG_NO_PERMISSION   = "no_permission"
const TK_MSG_STEAM_UNAVAIL   = "steam_unavail"
const TK_MSG_TOP_HEADER      = "top_header"
const TK_MSG_TOP_EMPTY       = "top_empty"
const TK_MSG_HELP_TIP        = "help_tip"
const TK_MSG_RANK_UP         = "rank_up"
const TK_MSG_NEXT_PROGRESS   = "next_progress"
const TK_MSG_MAX_RANK        = "max_rank"
const TK_MSG_LANG_STATUS     = "lang_status"
const TK_MSG_LANG_SET        = "lang_set"
const TK_MSG_NOTIFY_ON       = "notify_on"
const TK_MSG_NOTIFY_OFF      = "notify_off"
const TK_MSG_RESET_USAGE     = "reset_usage"
const TK_MSG_RESET_BAD_ID    = "reset_bad_id"
const TK_MSG_RESET_DONE      = "reset_done"
const TK_MSG_RESET_ALL_DONE  = "reset_all_done"
const TK_MSG_HELP_ME         = "help_me"
const TK_MSG_HELP_TOP        = "help_top"
const TK_MSG_HELP_NEXT       = "help_next"
const TK_MSG_HELP_RANKS      = "help_ranks"
const TK_MSG_HELP_LANG       = "help_lang"
const TK_MSG_HELP_ON         = "help_on"
const TK_MSG_HELP_OFF        = "help_off"
const TK_MSG_HELP_RESET      = "help_reset"
const TK_MSG_HELP_HELP       = "help_help"
const TK_MSG_HELP_AUTHOR     = "help_author"
const TK_MSG_HELP_VERSION    = "help_version"
const TK_MSG_RANKS_HEADER    = "ranks_header"
const TK_MSG_RANK_ROW        = "rank_row"
const TK_MSG_SCORE_LINE      = "score_line"
const TK_MSG_HELP_TEST       = "help_test"
const TK_MSG_TEST_NO_MARINE  = "test_no_marine"
const TK_MSG_TEST_OFF        = "test_off"
const TK_MSG_TEST_FAIL       = "test_fail"
const TK_MSG_TEST_DONE       = "test_done"

::g_TkLangAliases <- {
    ru = "ru",
    rus = "ru",
    russian = "ru",
    ["рус"] = "ru",
    en = "en",
    eng = "en",
    english = "en",
}

::g_TkStrings <- {
    no_permission = {
        ru = "Нет прав",
        en = "no permission",
    },
    steam_unavail = {
        ru = "SteamID недоступен.",
        en = "SteamID unavailable.",
    },
    top_header = {
        ru = "=== TK Top ===",
        en = "=== TK Top ===",
    },
    top_empty = {
        ru = "(пусто)",
        en = "(empty)",
    },
    help_tip = {
        ru = "team kill counter справка - !tkc_help",
        en = "team kill counter help - !tkc_help",
    },
    rank_up = {
        ru = "{name} получает звание «{title}» ({count} ТК)",
        en = "{name} ranked up: «{title}» ({count} TK)",
    },
    next_progress = {
        ru = "До «{title}»: ещё {need} (сейчас {count})",
        en = "{need} more to «{title}» (now {count})",
    },
    max_rank = {
        ru = "MAX — {line}",
        en = "MAX — {line}",
    },
    lang_status = {
        ru = "lang = {lang} (ru|en). Пример: !tkc_lang en",
        en = "lang = {lang} (ru|en). Example: !tkc_lang en",
    },
    lang_set = {
        ru = "lang → {lang}",
        en = "lang → {lang}",
    },
    notify_on = {
        ru = "Чат о звании и красный текст по центру включены",
        en = "Rank-up chat and red center text enabled",
    },
    notify_off = {
        ru = "Чат о звании и красный текст по центру выключены",
        en = "Rank-up chat and red center text disabled",
    },
    reset_usage = {
        ru = "Использование: !tkc_reset STEAM_1:0:12345 | !tkc_reset all",
        en = "Usage: !tkc_reset STEAM_1:0:12345 | !tkc_reset all",
    },
    reset_bad_id = {
        ru = "Нужен SteamID вида STEAM_1:0:12345 или all",
        en = "Need SteamID like STEAM_1:0:12345 or all",
    },
    reset_done = {
        ru = "Reset {name} [{steam}]: {before} → 0",
        en = "Reset {name} [{steam}]: {before} → 0",
    },
    reset_all_done = {
        ru = "Сброшена вся статистика ({count} записей)",
        en = "All stats reset ({count} records)",
    },
    help_me = {
        ru = "!tkc — твой счёт",
        en = "!tkc — your score",
    },
    help_top = {
        ru = "!tkc_top — таблица лидеров",
        en = "!tkc_top — leaderboard",
    },
    help_next = {
        ru = "!tkc_next — следующий ранг",
        en = "!tkc_next — next rank",
    },
    help_ranks = {
        ru = "!tkc_ranks — список рангов и порогов",
        en = "!tkc_ranks — ranks and breakpoints",
    },
    ranks_header = {
        ru = "=== Ранги (ТК → звание) ===",
        en = "=== Ranks (TK → title) ===",
    },
    rank_row = {
        ru = "{min} — {title}",
        en = "{min} — {title}",
    },
    help_lang = {
        ru = "!tkc_lang / !mc_lang en|ru — язык (общий для combiner)",
        en = "!tkc_lang / !mc_lang en|ru — language (shared across combiner)",
    },
    help_on = {
        ru = "!tkc_on — чат о новом звании и красный текст по центру",
        en = "!tkc_on — rank-up chat and red center text",
    },
    help_off = {
        ru = "!tkc_off — скрыть чат о звании и красный текст по центру",
        en = "!tkc_off — hide rank-up chat and red center text",
    },
    help_test = {
        ru = "!tkc_test — тестовый попап над морпехом (админ)",
        en = "!tkc_test — test popup over your marine (admin)",
    },
    test_no_marine = {
        ru = "Нет морпеха для попапа.",
        en = "No marine for the popup.",
    },
    test_off = {
        ru = "Попап выключен. !am_set tk_counter popup 1",
        en = "Popup is off. !am_set tk_counter popup 1",
    },
    test_fail = {
        ru = "Не удалось показать попап.",
        en = "Could not show the popup.",
    },
    test_done = {
        ru = "Тест попапа: {n}",
        en = "Popup test: {n}",
    },
    help_reset = {
        ru = "!tkc_reset STEAM_…|all — сброс игрока / всей статистики (админ)",
        en = "!tkc_reset STEAM_…|all — reset player / all stats (admin)",
    },
    help_help = {
        ru = "!tkc_help — справка",
        en = "!tkc_help — help",
    },
    help_author = {
        ru = "Author: typical russian (https://steamcommunity.com/id/w_asd/)",
        en = "Author: typical russian (https://steamcommunity.com/id/w_asd/)",
    },
    help_version = {
        ru = "Version: {version}",
        en = "Version: {version}",
    },
    score_line = {
        ru = "{name}: {count} — {title}",
        en = "{name}: {count} — {title}",
    },
}

::g_TkCache <- {}
PendingTips <- []
// Steam keys already tipped this map (player_activate can fire more than once)
TippedPlayers <- {}
// Pre-baked announce lines (correct killcount), flushed next thinks — avoids
// same-frame game_text clobbering when several marines die at once.
PendingAnnounces <- []

// ── i18n ─────────────────────────────────────────────────────────────────────

TkNormalizeLang <- function( lang ) {
    if ( lang == null )
        return TK_DEFAULT_LANG
    local key = lang.tostring().tolower()
    if ( key in ::g_TkLangAliases )
        return ::g_TkLangAliases[key]
    return TK_DEFAULT_LANG
}

_TkReplaceAll <- function( text, token, value ) {
    if ( text == null )
        return ""
    text = text.tostring()
    token = token.tostring()
    value = ( value == null ) ? "" : value.tostring()
    local out = text
    local idx = out.find( token )
    while ( idx != null ) {
        out = out.slice( 0, idx ) + value + out.slice( idx + token.len() )
        idx = out.find( token )
    }
    return out
}

TkFill <- function( template, vars ) {
    local out = template.tostring()
    foreach ( key, value in vars ) {
        out = _TkReplaceAll( out, "${" + key + "}", value )
        out = _TkReplaceAll( out, "{" + key + "}", value )
    }
    return out
}

TkT <- function( msgId, lang = TK_DEFAULT_LANG ) {
    lang = TkNormalizeLang( lang )
    if ( !( msgId in ::g_TkStrings ) )
        return msgId.tostring()
    local row = ::g_TkStrings[msgId]
    if ( lang in row )
        return row[lang]
    if ( TK_DEFAULT_LANG in row )
        return row[TK_DEFAULT_LANG]
    foreach ( _lang, text in row )
        return text
    return msgId.tostring()
}

TkTF <- function( msgId, lang, vars ) {
    return TkFill( TkT( msgId, lang ), vars )
}

TkChat <- function( hPlayerOrNull, lang, msgId, vars = null ) {
    local text = ( vars == null ) ? TkT( msgId, lang ) : TkTF( msgId, lang, vars )
    ClientPrint( hPlayerOrNull, TK_HUD_TALK, TK_TAG + text )
}

TkRankIndex <- function( count ) {
    local idx = 0
    foreach ( i, r in ::g_TkRanks ) {
        if ( count >= r.min )
            idx = i
    }
    return idx
}

TkRankTitle <- function( count, lang = TK_DEFAULT_LANG ) {
    lang = TkNormalizeLang( lang )
    local titles = ::g_TkRanks[TkRankIndex( count )].title
    if ( lang in titles )
        return titles[lang]
    return titles[TK_DEFAULT_LANG]
}

TkRankTitleFromRow <- function( row, lang = TK_DEFAULT_LANG ) {
    lang = TkNormalizeLang( lang )
    if ( lang in row.title )
        return row.title[lang]
    return row.title[TK_DEFAULT_LANG]
}

TkNextRank <- function( count ) {
    local idx = TkRankIndex( count )
    if ( idx + 1 >= ::g_TkRanks.len() )
        return null
    return ::g_TkRanks[idx + 1]
}

TkAnnounceCfg <- function( key, fallback ) {
    if ( !( "g_TkAnnounce" in getroottable() ) )
        return fallback
    if ( !( key in ::g_TkAnnounce ) )
        return fallback
    local v = ::g_TkAnnounce[key]
    if ( v == null )
        return fallback
    return v
}

TkAnnounceCfgBool <- function( key, fallback ) {
    local v = TkAnnounceCfg( key, null )
    if ( v == null )
        return fallback
    if ( typeof v == "bool" )
        return v
    local s = v.tostring().tolower()
    if ( s == "0" || s == "false" || s == "no" || s == "off" )
        return false
    if ( s == "1" || s == "true" || s == "yes" || s == "on" )
        return true
    return fallback
}

TkAnnounceCfgStr <- function( key, fallback ) {
    local v = TkAnnounceCfg( key, null )
    if ( v == null || v == "" )
        return fallback
    return v.tostring()
}

TkPickTemplate <- function( tableKey, lang ) {
    lang = TkNormalizeLang( lang )
    if ( !( "g_TkAnnounce" in getroottable() ) )
        return null
    if ( !( tableKey in ::g_TkAnnounce ) )
        return null
    local t = ::g_TkAnnounce[tableKey]
    if ( t == null )
        return null
    if ( typeof t == "string" )
        return t
    if ( lang in t )
        return t[lang]
    if ( TK_DEFAULT_LANG in t )
        return t[TK_DEFAULT_LANG]
    return null
}

// kind: "status" (commands, always with rank) | "kill" | "rankup"
TkFormatLine <- function( name, count, lang, kind = "status" ) {
    lang = TkNormalizeLang( lang )
    local rankTitle = TkRankTitle( count, lang )
    local rankText = rankTitle

    if ( kind == "kill" ) {
        if ( TkAnnounceCfgBool( "rank_on_every_kill", false ) )
            rankText = TkAnnounceCfgStr( "rank_prefix", " — " ) + rankTitle
        else
            rankText = ""
    } else if ( kind == "rankup" ) {
        rankText = rankTitle
    } else {
        // !tkc / top / next — всегда показываем ранг с префиксом
        rankText = TkAnnounceCfgStr( "rank_prefix", " — " ) + rankTitle
    }

    local vars = {
        nickname = name,
        name = name,
        killcount = count,
        count = count,
        rank = rankText,
        title = rankText,
    }

    local tplKey = "template_kill"
    if ( kind == "rankup" )
        tplKey = "template_rankup"

    local tpl = TkPickTemplate( tplKey, lang )
    if ( tpl == null || tpl == "" ) {
        if ( kind == "rankup" )
            return name + " → " + rankTitle
        return TkTF( TK_MSG_SCORE_LINE, lang, { name = name, count = count, title = rankTitle } )
    }
    return TkFill( tpl, vars )
}

// ── Helpers ──────────────────────────────────────────────────────────────────

_TkSplitFirst <- function( str, sep ) {
    local idx = str.find( sep )
    if ( idx == null )
        return [ str, "" ]
    return [ str.slice( 0, idx ), str.slice( idx + sep.len() ) ]
}

_TkTrimCr <- function( line ) {
    if ( line.len() > 0 && line.slice( line.len() - 1 ) == "\r" )
        return line.slice( 0, line.len() - 1 )
    return line
}

_TkSplitLines <- function( raw ) {
    local result = []
    local start = 0
    local idx = raw.find( "\n", start )
    while ( idx != null ) {
        result.append( _TkTrimCr( raw.slice( start, idx ) ) )
        start = idx + 1
        idx = raw.find( "\n", start )
    }
    if ( start < raw.len() )
        result.append( _TkTrimCr( raw.slice( start ) ) )
    return result
}

_TkTrimSpaces <- function( s ) {
    if ( s == null )
        return ""
    s = s.tostring()
    while ( s.len() > 0 && s.slice( 0, 1 ) == " " )
        s = s.slice( 1 )
    while ( s.len() > 0 && s.slice( s.len() - 1 ) == " " )
        s = s.slice( 0, s.len() - 1 )
    return s
}

_TkSplitColons <- function( s ) {
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

TkAccountIdFromString <- function( raw ) {
    local s = _TkTrimSpaces( raw )
    if ( s == null || s == "" )
        return null

    if ( s.len() >= 8 && s.slice( 0, 6 ) == "STEAM_" ) {
        local parts = _TkSplitColons( s )
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

TkSteamStringFromAccountId <- function( accountId ) {
    local y = accountId % 2
    local z = accountId / 2
    return "STEAM_1:" + y.tostring() + ":" + z.tostring()
}

TkKey <- function( hPlayer ) {
    if ( hPlayer == null || !hPlayer.IsValid() )
        return null
    local net = hPlayer.GetNetworkIDString()
    if ( net == null || net == "" )
        return null
    if ( net == "BOT" || net == "STEAM_ID_LAN" || net == "STEAM_ID_PENDING" )
        return null
    local acc = TkAccountIdFromString( net )
    if ( acc == null )
        return null
    return acc.tostring()
}

TkPlayerFile <- function( id ) {
    return TK_DIR + "/" + id + ".txt"
}

TkIsAdmin <- function( hPlayer ) {
    if ( !( "McAuth" in getroottable() ) )
        return false
    return ::McAuth.IsAdmin( hPlayer )
}

// ── Persist ──────────────────────────────────────────────────────────────────

TkLoadIndex <- function() {
    local ids = []
    local raw = FileToString( TK_INDEX_FILE )
    if ( raw == null || raw == "" )
        return ids
    foreach ( line in _TkSplitLines( raw ) ) {
        if ( line.len() == 0 )
            continue
        ids.append( line )
    }
    return ids
}

TkSaveIndex <- function( ids ) {
    local out = ""
    foreach ( id in ids )
        out += id + "\n"
    StringToFile( TK_INDEX_FILE, out )
}

TkEnsureInIndex <- function( id ) {
    local ids = TkLoadIndex()
    foreach ( existing in ids ) {
        if ( existing == id )
            return
    }
    ids.append( id )
    TkSaveIndex( ids )
}

TkParseNotify <- function( raw ) {
    if ( raw == null )
        return true
    raw = raw.tostring().tolower()
    if ( raw == "0" || raw == "off" || raw == "false" || raw == "no" )
        return false
    return true
}

// File format: count|name|lang|notify(0|1)
TkLoad <- function( id ) {
    if ( id in ::g_TkCache )
        return ::g_TkCache[id]

    local rec = {
        count = 0,
        name = "?",
        lang = TK_DEFAULT_LANG,
        notify = true,
        steam = TkSteamStringFromAccountId( id.tointeger() ),
    }
    local raw = FileToString( TkPlayerFile( id ) )
    if ( raw != null && raw != "" ) {
        local line = _TkTrimCr( raw )
        local p1 = _TkSplitFirst( line, TK_SEP )
        try {
            rec.count = p1[0].tointeger()
        } catch ( e ) {
            rec.count = 0
        }
        if ( rec.count < 0 )
            rec.count = 0
        local rest = p1[1]
        if ( rest != null && rest != "" ) {
            local p2 = _TkSplitFirst( rest, TK_SEP )
            if ( p2[0] != null && p2[0] != "" )
                rec.name = p2[0]
            local rest2 = p2[1]
            if ( rest2 != null && rest2 != "" ) {
                local p3 = _TkSplitFirst( rest2, TK_SEP )
                if ( p3[0] != null && p3[0] != "" )
                    rec.lang = TkNormalizeLang( p3[0] )
                if ( p3[1] != null && p3[1] != "" )
                    rec.notify = TkParseNotify( p3[1] )
            }
        }
    }

    ::g_TkCache[id] <- rec
    return rec
}

_TkSanitizeName <- function( name ) {
    if ( name == null || name == "" )
        return "?"
    name = name.tostring()
    local out = ""
    for ( local i = 0; i < name.len(); i++ ) {
        local ch = name.slice( i, i + 1 )
        if ( ch == TK_SEP )
            out += "/"
        else if ( ch == "\n" || ch == "\r" )
            out += " "
        else
            out += ch
    }
    return out
}

TkSave <- function( id ) {
    if ( !( id in ::g_TkCache ) )
        return
    local rec = ::g_TkCache[id]
    local name = _TkSanitizeName( rec.name )
    local lang = TkNormalizeLang( rec.lang )
    local notify = true
    if ( "notify" in rec )
        notify = rec.notify
    rec.lang = lang
    rec.notify = notify
    local notifyStr = notify ? "1" : "0"
    StringToFile( TkPlayerFile( id ), rec.count.tostring() + TK_SEP + name + TK_SEP + lang + TK_SEP + notifyStr )
    TkEnsureInIndex( id )
}

TkIsNotifyOn <- function( hPlayer ) {
    local id = TkKey( hPlayer )
    if ( id == null )
        return true
    local rec = TkLoad( id )
    if ( !( "notify" in rec ) )
        return true
    return rec.notify
}

TkSetNotify <- function( hPlayer, enabled ) {
    local id = TkKey( hPlayer )
    if ( id == null )
        return null
    local rec = TkLoad( id )
    rec.notify = enabled
    rec.name = hPlayer.GetPlayerName()
    rec.steam = hPlayer.GetNetworkIDString()
    ::g_TkCache[id] <- rec
    TkSave( id )
    return rec.notify
}

TkAnnounceStackSlots <- function() {
    local n = 4
    try {
        n = TkAnnounceCfgStr( "stack_slots", "4" ).tointeger()
    } catch ( e ) {
        n = 4
    }
    if ( n < 1 )
        n = 1
    if ( n > 6 )
        n = 6
    return n
}

TkAnnounceChannelBase <- function() {
    local n = 1
    try {
        n = TkAnnounceCfgStr( "channel_base", "1" ).tointeger()
    } catch ( e ) {
        n = 1
    }
    if ( n < 0 )
        n = 0
    return n
}

TkAnnounceYStep <- function() {
    local s = TkAnnounceCfgStr( "y_step", "0.055" )
    try {
        return s.tofloat()
    } catch ( e ) {
        return 0.055
    }
}

TkAnnounceHoldSeconds <- function() {
    local hold = 4.0
    local fo = 0.35
    try { hold = TkAnnounceCfgStr( "holdtime", TK_TEXT_HOLD ).tofloat() } catch ( e ) { hold = 4.0 }
    try { fo = TkAnnounceCfgStr( "fadeout", "0.35" ).tofloat() } catch ( e ) { fo = 0.35 }
    return hold + fo + 0.05
}

// Pick a free stack slot (different y + channel). Reuses oldest if all busy.
TkAllocAnnounceSlot <- function() {
    local slots = TkAnnounceStackSlots()
    local now = Time()
    local i = 0
    for ( i = 0; i < slots; i++ ) {
        if ( ::g_TkAnnounceSlotFreeAt[i] <= now ) {
            ::g_TkAnnounceSlotFreeAt[i] = now + TkAnnounceHoldSeconds()
            return i
        }
    }
    local best = 0
    local bestAt = ::g_TkAnnounceSlotFreeAt[0]
    for ( i = 1; i < slots; i++ ) {
        if ( ::g_TkAnnounceSlotFreeAt[i] < bestAt ) {
            bestAt = ::g_TkAnnounceSlotFreeAt[i]
            best = i
        }
    }
    ::g_TkAnnounceSlotFreeAt[best] = now + TkAnnounceHoldSeconds()
    return best
}

TkAnnounceSlotY <- function( slot ) {
    local base = 0.32
    try { base = TkAnnounceCfgStr( "y", TK_TEXT_Y ).tofloat() } catch ( e ) { base = 0.32 }
    return ( base + ( slot * TkAnnounceYStep() ) ).tostring()
}

TkAnnounceSlotChannel <- function( slot ) {
    return ( TkAnnounceChannelBase() + slot ).tostring()
}

// Queue announce with text already formatted (call right after TkAdd).
TkQueueAnnounce <- function( centerMsg, chatMsg ) {
    PendingAnnounces.append( {
        center = centerMsg,
        chat = chatMsg,
    } )
}

// Broadcast center+chat only to players who left notify on.
// One stack slot per announcement (shared by all viewers).
// displayDelay: stagger Display so same-frame HUD writes do not clobber text.
TkBroadcastAnnounce <- function( centerMsg, chatMsg, displayDelay = 0.0 ) {
    local slot = null
    if ( centerMsg != null && centerMsg != "" )
        slot = TkAllocAnnounceSlot()

    local p = Entities.FindByClassname( null, "player" )
    while ( p != null ) {
        if ( p.IsValid() && TkIsNotifyOn( p ) ) {
            if ( centerMsg != null && centerMsg != "" )
                TkShowCenter( centerMsg, p, slot, displayDelay )
            if ( chatMsg != null && chatMsg != "" )
                ClientPrint( p, TK_HUD_TALK, chatMsg )
        }
        p = Entities.FindByClassname( p, "player" )
    }
}

// Flush one queued announce per think tick (stable killcounts + stack).
TkFlushOneAnnounce <- function() {
    if ( PendingAnnounces.len() == 0 )
        return
    local a = PendingAnnounces[0]
    local rest = []
    for ( local i = 1; i < PendingAnnounces.len(); i++ )
        rest.append( PendingAnnounces[i] )
    PendingAnnounces = rest
    TkBroadcastAnnounce( a.center, a.chat, 0.0 )
}

TkLangOf <- function( hPlayer ) {
    // Общий язык combiner (McI18n); TK-файл остаётся запасным зеркалом.
    if ( "McI18n" in getroottable() )
        return ::McI18n.LangOf( hPlayer )
    local id = TkKey( hPlayer )
    if ( id == null )
        return TK_DEFAULT_LANG
    return TkNormalizeLang( TkLoad( id ).lang )
}

TkSetLang <- function( hPlayer, lang ) {
    if ( "McI18n" in getroottable() ) {
        local set = ::McI18n.SetLang( hPlayer, lang )
        if ( set == null )
            return null
        // Зеркало в TK-сейв для старых тулов / бэкапов
        local id = TkKey( hPlayer )
        if ( id != null ) {
            local rec = TkLoad( id )
            rec.lang = set
            rec.name = hPlayer.GetPlayerName()
            rec.steam = hPlayer.GetNetworkIDString()
            ::g_TkCache[id] <- rec
            TkSave( id )
        }
        return set
    }
    local id = TkKey( hPlayer )
    if ( id == null )
        return null
    local rec = TkLoad( id )
    rec.lang = TkNormalizeLang( lang )
    rec.name = hPlayer.GetPlayerName()
    rec.steam = hPlayer.GetNetworkIDString()
    ::g_TkCache[id] <- rec
    TkSave( id )
    return rec.lang
}

TkTouchPlayer <- function( hPlayer ) {
    local id = TkKey( hPlayer )
    if ( id == null )
        return null
    local rec = TkLoad( id )
    rec.name = hPlayer.GetPlayerName()
    rec.steam = hPlayer.GetNetworkIDString()
    rec.lang = TkNormalizeLang( rec.lang )
    if ( !( "notify" in rec ) )
        rec.notify = true
    ::g_TkCache[id] <- rec
    TkSave( id )
    return rec
}

TkAdd <- function( hPlayer, n = 1 ) {
    local id = TkKey( hPlayer )
    if ( id == null )
        return null
    local before = TkLoad( id ).count
    local rec = TkLoad( id )
    rec.count = before + n
    rec.name = hPlayer.GetPlayerName()
    rec.steam = hPlayer.GetNetworkIDString()
    rec.lang = TkNormalizeLang( rec.lang )
    if ( !( "notify" in rec ) )
        rec.notify = true
    ::g_TkCache[id] <- rec
    TkSave( id )
    return { id = id, before = before, after = rec.count, name = rec.name, steam = rec.steam, lang = rec.lang }
}

TkResetBySteamString <- function( steamStr ) {
    local acc = TkAccountIdFromString( steamStr )
    if ( acc == null )
        return null
    local id = acc.tostring()
    local rec = TkLoad( id )
    local oldCount = rec.count
    local oldName = rec.name
    local steam = TkSteamStringFromAccountId( acc )
    if ( "steam" in rec && rec.steam != null && rec.steam != "" )
        steam = rec.steam
    rec.count = 0
    ::g_TkCache[id] <- rec
    TkSave( id )
    return { id = id, name = oldName, before = oldCount, steam = steam }
}

// Reset TK count for every known player (keeps name/lang/notify).
TkResetAll <- function() {
    local ids = TkLoadIndex()
    local n = 0
    foreach ( id in ids ) {
        local rec = TkLoad( id )
        rec.count = 0
        ::g_TkCache[id] <- rec
        TkSave( id )
        n += 1
    }
    return n
}

TkCollectAll <- function() {
    local list = []
    foreach ( id in TkLoadIndex() ) {
        local rec = TkLoad( id )
        local steam = TkSteamStringFromAccountId( id.tointeger() )
        if ( "steam" in rec && rec.steam != null && rec.steam != "" )
            steam = rec.steam
        list.append( {
            id = id,
            count = rec.count,
            name = rec.name,
            steam = steam,
            lang = TkNormalizeLang( rec.lang ),
        } )
    }
    local n = list.len()
    for ( local i = 0; i < n; i++ ) {
        for ( local j = 0; j < n - 1 - i; j++ ) {
            if ( list[j].count < list[j + 1].count ) {
                local tmp = list[j]
                list[j] = list[j + 1]
                list[j + 1] = tmp
            }
        }
    }
    return list
}

// ── UI ───────────────────────────────────────────────────────────────────────

TkShowCenter <- function( message, hPlayer = null, slot = null, displayDelay = 0.0 ) {
    if ( message == null || message == "" )
        return

    if ( slot == null )
        slot = TkAllocAnnounceSlot()

    local t = Entities.CreateByClassname( "game_text" )
    if ( t == null )
        return

    local hold = TkAnnounceCfgStr( "holdtime", TK_TEXT_HOLD )
    local killDelay = 5.0
    try {
        killDelay = hold.tofloat() + TkAnnounceCfgStr( "fadeout", "0.35" ).tofloat() + 0.5 + displayDelay
    } catch ( e ) {
        killDelay = 5.0 + displayDelay
    }

    local msgStr = message.tostring()
    local color = TkAnnounceCfgStr( "color", TK_TEXT_COLOR )
    t.__KeyValueFromString( "message", msgStr )
    t.__KeyValueFromString( "x", TkAnnounceCfgStr( "x", "-1" ) )
    t.__KeyValueFromString( "y", TkAnnounceSlotY( slot ) )
    t.__KeyValueFromString( "color", color )
    t.__KeyValueFromString( "color2", TkAnnounceCfgStr( "color2", color ) )
    t.__KeyValueFromString( "holdtime", hold )
    t.__KeyValueFromString( "fadein", TkAnnounceCfgStr( "fadein", "0.15" ) )
    t.__KeyValueFromString( "fadeout", TkAnnounceCfgStr( "fadeout", "0.35" ) )
    t.__KeyValueFromString( "channel", TkAnnounceSlotChannel( slot ) )
    t.__KeyValueFromString( "effect", TkAnnounceCfgStr( "effect", "0" ) )

    if ( hPlayer != null && hPlayer.IsValid() ) {
        t.__KeyValueFromString( "spawnflags", "0" )
        t.SetOwner( hPlayer )
        t.Spawn()
        t.Activate()
        EntFireByHandle( t, "Display", "", displayDelay, hPlayer, hPlayer )
    } else {
        t.__KeyValueFromString( "spawnflags", "1" )
        t.Spawn()
        t.Activate()
        EntFireByHandle( t, "Display", "", displayDelay, null, null )
    }

    EntFireByHandle( t, "Kill", "", killDelay, null, null )
}

TkPopupModule <- function() {
    if ( !( "McRegistry" in getroottable() ) )
        return null
    return ::McRegistry.FindModule( "tk_counter" )
}

TkPopupOn <- function() {
    local m = TkPopupModule()
    if ( m == null || !( "variables" in m ) )
        return false
    return m.variables.popup != 0
}

TkAnnounceKill <- function( hKiller, after, lang ) {
    // Bake string NOW — before any later kill in the same frame changes totals.
    // Used when the world popup is off. Red center text only, no kill chat.
    local msg = TkFormatLine( hKiller.GetPlayerName(), after, lang, "kill" )
    TkQueueAnnounce( msg, null )
}

// withCenter: red game_text. Chat always goes to players with notify on.
TkAnnounceRankUp <- function( hKiller, after, lang, withCenter ) {
    local name = hKiller.GetPlayerName()
    local title = TkRankTitle( after, lang )
    local center = null
    if ( withCenter )
        center = TkFormatLine( name, after, lang, "rankup" )
    local chat = TK_TAG + TkTF( TK_MSG_RANK_UP, lang, {
        name = name,
        title = title,
        count = after,
    } )
    TkQueueAnnounce( center, chat )
}

TkSendHelpTip <- function( hPlayer ) {
    if ( hPlayer == null || !hPlayer.IsValid() )
        return
    if ( !TkIsNotifyOn( hPlayer ) )
        return
    local id = TkKey( hPlayer )
    if ( id != null ) {
        if ( id in TippedPlayers )
            return
        TippedPlayers[id] <- true
    }
    TkChat( hPlayer, TkLangOf( hPlayer ), TK_MSG_HELP_TIP )
}

TkTipThink <- function() {
    local now = Time()

    // One HUD announce per tick so multi-kills keep distinct baked counts
    TkFlushOneAnnounce()

    if ( PendingTips.len() > 0 ) {
        local remaining = []
        foreach ( entry in PendingTips ) {
            if ( now >= entry.showAt ) {
                if ( entry.hPlayer != null && entry.hPlayer.IsValid() )
                    TkSendHelpTip( entry.hPlayer )
            } else {
                remaining.append( entry )
            }
        }
        PendingTips = remaining
    }

    if ( PendingAnnounces.len() > 0 )
        return 0.08
    return 0.5
}

_TkPrintHelp <- function( hPlayer ) {
    local lang = TkLangOf( hPlayer )
    local ids = [
        TK_MSG_HELP_ME,
        TK_MSG_HELP_TOP,
        TK_MSG_HELP_NEXT,
        TK_MSG_HELP_RANKS,
        TK_MSG_HELP_LANG,
        TK_MSG_HELP_ON,
        TK_MSG_HELP_OFF,
        TK_MSG_HELP_RESET,
        TK_MSG_HELP_TEST,
        TK_MSG_HELP_HELP,
        TK_MSG_HELP_VERSION,
        TK_MSG_HELP_AUTHOR,
    ]
    local ver = "0"
    if ( "g_TkVersion" in getroottable() && ::g_TkVersion != null )
        ver = ::g_TkVersion.tostring()
    foreach ( id in ids ) {
        if ( id == TK_MSG_HELP_VERSION )
            TkChat( hPlayer, lang, id, { version = ver } )
        else
            TkChat( hPlayer, lang, id )
    }
}

// ── Events ───────────────────────────────────────────────────────────────────

_OnEntityKilled <- function( params ) {
    if ( !( "entindex_killed" in params ) )
        return
    if ( !( "entindex_attacker" in params ) )
        return

    local victim = EntIndexToHScript( params["entindex_killed"] )
    local attacker = EntIndexToHScript( params["entindex_attacker"] )
    if ( victim == null || attacker == null )
        return
    if ( !victim.IsValid() || !attacker.IsValid() )
        return
    if ( victim.GetClassname() != TK_CLASS_MARINE )
        return
    if ( attacker.GetClassname() != TK_CLASS_MARINE )
        return
    if ( attacker == victim )
        return
    if ( !attacker.IsInhabited() )
        return

    local hKiller = attacker.GetCommander()
    if ( hKiller == null || !hKiller.IsValid() )
        return

    local result = TkAdd( hKiller, 1 )
    if ( result == null )
        return

    local popup = TkPopupOn()
    if ( popup ) {
        local mod = TkPopupModule()
        if ( mod != null ) {
            local fromN = result.before
            if ( fromN < 1 )
                fromN = result.after
            mod._showPopup( attacker, fromN, result.after )
        }
    } else {
        TkAnnounceKill( hKiller, result.after, result.lang )
    }
    if ( TkRankIndex( result.after ) > TkRankIndex( result.before ) )
        TkAnnounceRankUp( hKiller, result.after, result.lang, !popup )
}

_OnPlayerActivate <- function( hPlayer ) {
    if ( hPlayer == null || !hPlayer.IsValid() )
        return
    TkTouchPlayer( hPlayer )
    // Join-tip отключён: одна строка от admin — !am_help
}

_OnPlayerSay <- function( params ) {
    if ( !( "text" in params ) || !( "userid" in params ) )
        return

    local text = params["text"]
    if ( text == null )
        return
    text = text.tostring()
    if ( text.len() > 0 && text.slice( 0, 1 ) == "/" )
        text = "!" + text.slice( 1 )

    if ( text.len() < TK_CMD_PREFIX.len() )
        return
    if ( text.slice( 0, TK_CMD_PREFIX.len() ) != TK_CMD_PREFIX )
        return
    if ( text.len() > TK_CMD_PREFIX.len() ) {
        local nextCh = text.slice( TK_CMD_PREFIX.len(), TK_CMD_PREFIX.len() + 1 )
        if ( nextCh != "_" && nextCh != " " )
            return
    }

    local hPlayer = GetPlayerFromUserID( params["userid"] )
    if ( hPlayer == null || !hPlayer.IsValid() )
        return

    local lang = TkLangOf( hPlayer )
    local cmd = text
    local arg = ""
    local sp = text.find( " " )
    if ( sp != null ) {
        cmd = text.slice( 0, sp )
        arg = _TkTrimSpaces( text.slice( sp + 1 ) )
    }

    if ( cmd == TK_CMD_HELP ) {
        _TkPrintHelp( hPlayer )
        return
    }

    if ( cmd == TK_CMD_ME ) {
        local rec = TkTouchPlayer( hPlayer )
        if ( rec == null ) {
            TkChat( hPlayer, lang, TK_MSG_STEAM_UNAVAIL )
            return
        }
        local msg = TkFormatLine( rec.name, rec.count, rec.lang )
        ClientPrint( hPlayer, TK_HUD_TALK, TK_TAG + msg + " [" + hPlayer.GetNetworkIDString() + "]" )
        return
    }

    if ( cmd == TK_CMD_TOP ) {
        local viewerLang = TkLangOf( hPlayer )
        local list = TkCollectAll()
        TkChat( hPlayer, viewerLang, TK_MSG_TOP_HEADER )
        if ( list.len() == 0 ) {
            TkChat( hPlayer, viewerLang, TK_MSG_TOP_EMPTY )
            return
        }
        local limit = list.len()
        if ( limit > TK_TOP_N )
            limit = TK_TOP_N
        for ( local i = 0; i < limit; i++ ) {
            local e = list[i]
            local line = ( i + 1 ).tostring() + ". " + TkFormatLine( e.name, e.count, viewerLang )
            ClientPrint( hPlayer, TK_HUD_TALK, TK_TAG + line )
        }
        return
    }

    if ( cmd == TK_CMD_NEXT ) {
        local rec = TkTouchPlayer( hPlayer )
        if ( rec == null ) {
            TkChat( hPlayer, lang, TK_MSG_STEAM_UNAVAIL )
            return
        }
        local next = TkNextRank( rec.count )
        if ( next == null ) {
            local line = TkFormatLine( rec.name, rec.count, rec.lang )
            TkChat( hPlayer, rec.lang, TK_MSG_MAX_RANK, { line = line } )
            return
        }
        local need = next.min - rec.count
        local nextTitle = TkRankTitleFromRow( next, rec.lang )
        TkChat( hPlayer, rec.lang, TK_MSG_NEXT_PROGRESS, {
            title = nextTitle,
            need = need,
            count = rec.count,
        } )
        return
    }

    if ( cmd == TK_CMD_RANKS ) {
        local viewerLang = TkLangOf( hPlayer )
        TkChat( hPlayer, viewerLang, TK_MSG_RANKS_HEADER )
        foreach ( r in ::g_TkRanks ) {
            local title = TkRankTitleFromRow( r, viewerLang )
            TkChat( hPlayer, viewerLang, TK_MSG_RANK_ROW, {
                min = r.min,
                title = title,
            } )
        }
        return
    }

    if ( cmd == TK_CMD_LANG ) {
        if ( arg == "" ) {
            TkChat( hPlayer, lang, TK_MSG_LANG_STATUS, { lang = lang } )
            return
        }
        local set = TkSetLang( hPlayer, arg )
        if ( set == null ) {
            TkChat( hPlayer, lang, TK_MSG_STEAM_UNAVAIL )
            return
        }
        local rec = TkTouchPlayer( hPlayer )
        local demo = TkFormatLine( rec.name, rec.count, set )
        TkChat( hPlayer, set, TK_MSG_LANG_SET, { lang = set } )
        ClientPrint( hPlayer, TK_HUD_TALK, TK_TAG + demo )
        return
    }

    if ( cmd == TK_CMD_ON ) {
        if ( TkSetNotify( hPlayer, true ) == null ) {
            TkChat( hPlayer, lang, TK_MSG_STEAM_UNAVAIL )
            return
        }
        TkChat( hPlayer, lang, TK_MSG_NOTIFY_ON )
        return
    }

    if ( cmd == TK_CMD_OFF ) {
        if ( TkSetNotify( hPlayer, false ) == null ) {
            TkChat( hPlayer, lang, TK_MSG_STEAM_UNAVAIL )
            return
        }
        TkChat( hPlayer, lang, TK_MSG_NOTIFY_OFF )
        return
    }

    if ( cmd == TK_CMD_TEST ) {
        if ( !TkIsAdmin( hPlayer ) ) {
            TkChat( hPlayer, lang, TK_MSG_NO_PERMISSION )
            return
        }
        if ( !TkPopupOn() ) {
            TkChat( hPlayer, lang, TK_MSG_TEST_OFF )
            return
        }
        local marine = hPlayer.GetMarine()
        if ( marine == null || !marine.IsValid() ) {
            TkChat( hPlayer, lang, TK_MSG_TEST_NO_MARINE )
            return
        }
        local rec = TkTouchPlayer( hPlayer )
        local n = 1
        local fromN = 0
        if ( rec != null && rec.count > 0 ) {
            n = rec.count
            fromN = n - 1
        }
        local mod = TkPopupModule()
        if ( mod == null || !mod._showPopup( marine, fromN, n ) ) {
            TkChat( hPlayer, lang, TK_MSG_TEST_FAIL )
            return
        }
        TkChat( hPlayer, lang, TK_MSG_TEST_DONE, { n = n } )
        return
    }

    if ( cmd == TK_CMD_RESET ) {
        if ( !TkIsAdmin( hPlayer ) ) {
            TkChat( hPlayer, lang, TK_MSG_NO_PERMISSION )
            return
        }
        if ( arg == "" ) {
            TkChat( hPlayer, lang, TK_MSG_RESET_USAGE )
            return
        }
        local argLower = arg.tolower()
        if ( argLower == "all" ) {
            local n = TkResetAll()
            TkChat( hPlayer, lang, TK_MSG_RESET_ALL_DONE, { count = n } )
            return
        }
        local result = TkResetBySteamString( arg )
        if ( result == null ) {
            TkChat( hPlayer, lang, TK_MSG_RESET_BAD_ID )
            return
        }
        TkChat( hPlayer, lang, TK_MSG_RESET_DONE, {
            name = result.name,
            steam = result.steam,
            before = result.before,
        } )
        return
    }

    if ( cmd.slice( 0, TK_CMD_PREFIX.len() ) == TK_CMD_PREFIX )
        _TkPrintHelp( hPlayer )
}

local hTipWorld = Entities.FindByClassname( null, "worldspawn" )
if ( hTipWorld != null )
    AddThinkToEnt( hTipWorld, "TkTipThink" )

