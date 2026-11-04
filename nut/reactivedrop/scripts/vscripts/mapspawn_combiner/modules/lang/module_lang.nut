// mapspawn_combiner/modules/lang/module_lang.nut
// Общий язык модулей combiner: !mc_lang [ru|en]
// Показ попапов на своём экране: !mc_popups [on|off]
// Хранение — ::McI18n (save/vscripts/mc_lang/), ::McHud (save/vscripts/mc_hud/).

if ( "McLangModuleLoaded" in getroottable() ) {
    ::McLog.Info( "[MC] lang: already loaded, skip" );
} else {
    getroottable().McLangModuleLoaded <- true;

local _strings = {
    tip = {
        en = "language — !mc_lang / !mc_lang en|ru",
        ru = "язык — !mc_lang / !mc_lang en|ru",
    },
    status = {
        en = "lang = {lang} (en|ru). Example: !mc_lang ru",
        ru = "lang = {lang} (en|ru). Пример: !mc_lang en",
    },
    set = {
        en = "lang → {lang}",
        ru = "lang → {lang}",
    },
    steam = {
        en = "SteamID unavailable (LAN/BOT?)",
        ru = "SteamID недоступен (LAN/BOT?)",
    },
    help = {
        en = "!mc_lang [en|ru] — UI language for combiner modules (default en)",
        ru = "!mc_lang [en|ru] — язык интерфейса модулей combiner (по умолчанию en)",
    },
    popups_tip = {
        en = "world popups — !mc_popups / !mc_popups on|off",
        ru = "попапы — !mc_popups / !mc_popups on|off",
    },
    popups_status = {
        en = "popups = {state} (on|off). Example: !mc_popups off",
        ru = "попапы = {state} (on|off). Пример: !mc_popups off",
    },
    popups_set = {
        en = "popups → {state}",
        ru = "попапы → {state}",
    },
    popups_on = {
        en = "on",
        ru = "вкл",
    },
    popups_off = {
        en = "off",
        ru = "выкл",
    },
    popups_help = {
        en = "!mc_popups [on|off] — weapon-kill and teamkill popups on your screen",
        ru = "!mc_popups [on|off] — попапы убийств и тимкиллов на своём экране",
    },
    popups_bad = {
        en = "use on or off. Example: !mc_popups off",
        ru = "нужно on или off. Пример: !mc_popups off",
    },
    popups_missing = {
        en = "hud prefs not loaded",
        ru = "выбор попапов не загружен",
    },
};

local m = {
    name        = "lang",
    enabled     = true,
    convars     = {},
    version     = "1.1.0",
    description = "Shared UI language (!mc_lang) and world-popup toggle (!mc_popups).",
    requires_registry = 4,

    _PREFIX     = "[MC] ",
    _CMD_PREFIX = "!mc_lang",
    _strings    = _strings,

    function _msg( hPlayer, text ) {
        ClientPrint( hPlayer, HudPrint.Talk, this._PREFIX + text );
    },

    function _langOf( hPlayer ) {
        if ( !( "McI18n" in getroottable() ) )
            return "en";
        return ::McI18n.LangOf( hPlayer );
    },

    function _t( hPlayer, msgId, vars = null ) {
        local lang = this._langOf( hPlayer );
        if ( !( "McI18n" in getroottable() ) )
            return msgId;
        if ( vars == null )
            return ::McI18n.T( this._strings, msgId, lang );
        return ::McI18n.TF( this._strings, msgId, lang, vars );
    },

    function _isCmd( full, prefix ) {
        if ( full == null )
            return false;
        if ( full.len() < prefix.len() )
            return false;
        if ( full.slice( 0, prefix.len() ) != prefix )
            return false;
        if ( full.len() == prefix.len() )
            return true;
        local nextCh = full.slice( prefix.len(), prefix.len() + 1 );
        return nextCh == " " || nextCh == "_";
    },

    function _cmdArg( full, prefix ) {
        if ( full.len() == prefix.len() )
            return null;
        local rest = full.slice( prefix.len() );
        if ( rest.len() > 0 && rest.slice( 0, 1 ) == "_" )
            rest = rest.slice( 1 );
        else if ( rest.len() > 0 && rest.slice( 0, 1 ) == " " )
            rest = rest.slice( 1 );
        while ( rest.len() > 0 && rest.slice( 0, 1 ) == " " )
            rest = rest.slice( 1 );
        if ( rest.len() == 0 )
            return null;
        return rest;
    },

    function _popupStateWord( hPlayer, hidden ) {
        if ( hidden )
            return this._t( hPlayer, "popups_off" );
        return this._t( hPlayer, "popups_on" );
    },

    function _handleLang( hPlayer, arg ) {
        if ( !( "McI18n" in getroottable() ) ) {
            this._msg( hPlayer, "i18n not loaded" );
            return;
        }
        if ( arg == null || arg == "" ) {
            this._msg( hPlayer, this._t( hPlayer, "status", { lang = this._langOf( hPlayer ) } ) );
            this._msg( hPlayer, this._t( hPlayer, "help" ) );
            return;
        }
        if ( arg == "help" ) {
            this._msg( hPlayer, this._t( hPlayer, "help" ) );
            return;
        }
        local set = ::McI18n.SetLang( hPlayer, arg );
        if ( set == null ) {
            this._msg( hPlayer, this._t( hPlayer, "steam" ) );
            return;
        }
        this._msg( hPlayer, ::McI18n.TF( this._strings, "set", set, { lang = set } ) );
    },

    function _handlePopups( hPlayer, arg ) {
        if ( !( "McHud" in getroottable() ) ) {
            this._msg( hPlayer, this._t( hPlayer, "popups_missing" ) );
            return;
        }
        if ( arg == "help" ) {
            this._msg( hPlayer, this._t( hPlayer, "popups_help" ) );
            return;
        }
        if ( arg == null || arg == "" ) {
            local hidden = ::McHud.Hidden( hPlayer );
            this._msg( hPlayer, this._t( hPlayer, "popups_status", {
                state = this._popupStateWord( hPlayer, hidden ),
            } ) );
            this._msg( hPlayer, this._t( hPlayer, "popups_help" ) );
            return;
        }
        local sp = arg.find( " " );
        if ( sp != null )
            arg = arg.slice( 0, sp );
        local hidden = ::McHud.ParseHidden( arg );
        if ( hidden == null ) {
            this._msg( hPlayer, this._t( hPlayer, "popups_bad" ) );
            return;
        }
        local set = ::McHud.SetHidden( hPlayer, hidden );
        if ( set == null ) {
            this._msg( hPlayer, this._t( hPlayer, "steam" ) );
            return;
        }
        this._msg( hPlayer, this._t( hPlayer, "popups_set", {
            state = this._popupStateWord( hPlayer, set ),
        } ) );
    },

    function OnGameEvent_player_activate( params ) {
        if ( !( "McHud" in getroottable() ) )
            return;
        ::McHud.RefreshLivePopups();
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

        local full = text.tolower();
        local hPlayer = null;

        if ( this._isCmd( full, "!mc_popups" ) ) {
            hPlayer = GetPlayerFromUserID( params["userid"] );
            if ( hPlayer == null || !hPlayer.IsValid() )
                return;
            this._handlePopups( hPlayer, this._cmdArg( full, "!mc_popups" ) );
            return;
        }

        local prefix = this._CMD_PREFIX;
        if ( !this._isCmd( full, prefix ) )
            return;

        hPlayer = GetPlayerFromUserID( params["userid"] );
        if ( hPlayer == null || !hPlayer.IsValid() )
            return;
        this._handleLang( hPlayer, this._cmdArg( full, prefix ) );
    },

    // Join-tip отключён: одна строка от admin — !am_help
};

::McRegistry.Register( m );

} // McLangModuleLoaded
