// mapspawn_combiner/modules/lang/module_lang.nut
// Общий язык модулей combiner: !mc_lang [ru|en]
// Хранение — ::McI18n (save/vscripts/mc_lang/).

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
};

local m = {
    name        = "lang",
    enabled     = true,
    convars     = {},
    version     = "1.0.1",
    description = "Shared UI language for mapspawn combiner modules (!mc_lang).",
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

    function _handle( hPlayer, arg ) {
        if ( !( "McI18n" in getroottable() ) ) {
            this._msg( hPlayer, "i18n not loaded" );
            return;
        }
        if ( arg == null || arg == "" ) {
            this._msg( hPlayer, this._t( hPlayer, "status", { lang = this._langOf( hPlayer ) } ) );
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
        local prefix = this._CMD_PREFIX;
        if ( full.len() < prefix.len() )
            return;
        if ( full.slice( 0, prefix.len() ) != prefix )
            return;
        if ( full.len() > prefix.len() ) {
            local nextCh = full.slice( prefix.len(), prefix.len() + 1 );
            if ( nextCh != " " && nextCh != "_" )
                return;
        }

        local hPlayer = GetPlayerFromUserID( params["userid"] );
        if ( hPlayer == null || !hPlayer.IsValid() )
            return;

        local arg = null;
        local sp = full.find( " " );
        if ( sp != null ) {
            arg = full.slice( sp + 1 );
            while ( arg.len() > 0 && arg.slice( 0, 1 ) == " " )
                arg = arg.slice( 1 );
            if ( arg.len() == 0 )
                arg = null;
        }
        // !mc_lang_help
        if ( full == "!mc_lang_help" || ( arg != null && arg == "help" ) ) {
            this._msg( hPlayer, this._t( hPlayer, "help" ) );
            return;
        }
        this._handle( hPlayer, arg );
    },

    // Join-tip отключён: одна строка от admin — !am_help
};

::McRegistry.Register( m );

} // McLangModuleLoaded
