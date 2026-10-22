// mapspawn_combiner/i18n.nut
// Общий язык игрока для модулей combiner. Дефолт: en.
// Persist: save/vscripts/mc_lang/<accountId>.txt (одна строка: en|ru)
// Команда: !mc_lang (модуль lang). Модули берут язык через ::McI18n.LangOf(hPlayer).

if ( !( "McI18n" in getroottable() ) ) {

::McI18n <- {
    version = 1,
    DEFAULT = "en",
    _DIR    = "mc_lang/",
    _cache  = null,   // accountId -> "en"|"ru"

    _aliases = {
        en = "en",
        eng = "en",
        english = "en",
        ru = "ru",
        rus = "ru",
        russian = "ru",
    },

    function Normalize( lang ) {
        if ( lang == null )
            return this.DEFAULT;
        local key = lang.tostring().tolower();
        if ( key in this._aliases )
            return this._aliases[key];
        return this.DEFAULT;
    },

    function _playerFile( id ) {
        return this._DIR + id.tostring() + ".txt";
    },

    function _playerKey( hPlayer ) {
        if ( !( "McAuth" in getroottable() ) )
            return null;
        return ::McAuth.PlayerKey( hPlayer );
    },

    function _loadId( id ) {
        if ( this._cache == null )
            this._cache = {};
        if ( id in this._cache )
            return this._cache[id];

        local raw = FileToString( this._playerFile( id ) );
        if ( raw != null && raw != "" ) {
            local line = raw.tostring();
            // первая строка / trim CR
            local nl = line.find( "\n" );
            if ( nl != null )
                line = line.slice( 0, nl );
            if ( line.len() > 0 && line.slice( line.len() - 1 ) == "\r" )
                line = line.slice( 0, line.len() - 1 );
            local lang = this.Normalize( line );
            this._cache[id] <- lang;
            return lang;
        }

        // Мост со старого TK-сейва (count|name|lang|…)
        if ( "TkLoad" in getroottable() ) {
            try {
                local rec = ::TkLoad( id );
                if ( rec != null && ( "lang" in rec ) && rec.lang != null && rec.lang != "" ) {
                    local lang = this.Normalize( rec.lang );
                    this._cache[id] <- lang;
                    StringToFile( this._playerFile( id ), lang + "\n" );
                    return lang;
                }
            } catch ( e ) {
            }
        }

        this._cache[id] <- this.DEFAULT;
        return this.DEFAULT;
    },

    function LangOf( hPlayer ) {
        local id = this._playerKey( hPlayer );
        if ( id == null )
            return this.DEFAULT;
        return this._loadId( id );
    },

    function SetLang( hPlayer, lang ) {
        local id = this._playerKey( hPlayer );
        if ( id == null )
            return null;
        lang = this.Normalize( lang );
        if ( this._cache == null )
            this._cache = {};
        this._cache[id] <- lang;
        StringToFile( this._playerFile( id ), lang + "\n" );

        // Держим TK-сейв в синхроне, если модуль уже загружен
        if ( "TkLoad" in getroottable() && "TkSave" in getroottable() ) {
            try {
                local rec = ::TkLoad( id );
                if ( rec != null ) {
                    rec.lang = lang;
                    if ( hPlayer != null && hPlayer.IsValid() )
                        rec.name = hPlayer.GetPlayerName();
                    ::TkSave( id );
                }
            } catch ( e ) {
            }
        }
        return lang;
    },

    function ReplaceAll( text, token, value ) {
        if ( text == null )
            return "";
        text = text.tostring();
        token = token.tostring();
        value = ( value == null ) ? "" : value.tostring();
        local out = text;
        local idx = out.find( token );
        while ( idx != null ) {
            out = out.slice( 0, idx ) + value + out.slice( idx + token.len() );
            idx = out.find( token );
        }
        return out;
    },

    function Fill( template, vars ) {
        if ( template == null )
            return "";
        local out = template.tostring();
        if ( vars == null )
            return out;
        foreach ( key, value in vars ) {
            out = this.ReplaceAll( out, "${" + key + "}", value );
            out = this.ReplaceAll( out, "{" + key + "}", value );
        }
        return out;
    },

    // strings: { msgId = { en = "...", ru = "..." }, ... }
    function T( strings, msgId, lang = null ) {
        lang = this.Normalize( lang );
        if ( strings == null || msgId == null )
            return msgId == null ? "" : msgId.tostring();
        if ( !( msgId in strings ) )
            return msgId.tostring();
        local row = strings[msgId];
        if ( lang in row )
            return row[lang];
        if ( this.DEFAULT in row )
            return row[this.DEFAULT];
        if ( "en" in row )
            return row.en;
        if ( "ru" in row )
            return row.ru;
        foreach ( _l, text in row )
            return text;
        return msgId.tostring();
    },

    function TF( strings, msgId, lang, vars ) {
        return this.Fill( this.T( strings, msgId, lang ), vars );
    },

    // Подпись из { en=..., ru=... } с дефолтом en
    function Label( labelTable, lang = null ) {
        lang = this.Normalize( lang );
        if ( labelTable == null )
            return "?";
        if ( typeof labelTable == "string" )
            return labelTable;
        if ( lang in labelTable )
            return labelTable[lang];
        if ( this.DEFAULT in labelTable )
            return labelTable[this.DEFAULT];
        if ( "en" in labelTable )
            return labelTable.en;
        if ( "ru" in labelTable )
            return labelTable.ru;
        return "?";
    },
};

::McLog.Info( "[MC] i18n ready (default lang=" + ::McI18n.DEFAULT + ")" );

} // McI18n
