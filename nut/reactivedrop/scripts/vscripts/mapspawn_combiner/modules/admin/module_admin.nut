// mapspawn_combiner/modules/admin/module_admin.nut
// Чат-команды управления модулями mapspawn combiner. Префикс: !am_
//
// Просмотр (help / modules / info / vars) — всем.
// Изменения (enable / disable / set / save / load / reset) — whitelist в mapspawn_combiner/admins.nut.
// Сам себя выключить нельзя; в файле настроек тоже не пишется как выключенный.
//
// Файл на весь сервер: save/vscripts/mapspawn_combiner/settings.txt
//   ModuleName.__enabled=0|1
//   ModuleName.varName=value
// Явные !am_save / !am_load / !am_reset (без автосохранения).
// mapspawn после регистрации модулей зовёт ApplySavedSettings(true).
//
// Таблица _CMDS — единый список для парсера и справки.

IncludeScript( "mapspawn_combiner/admins" );

local m = {
    name        = "admin",
    enabled     = true,
    convars     = {},
    version     = "1.0.0",
    description = "Runtime mapspawn combiner module management: the !am_ chat commands.",
    requires_registry = 4,

    _PREFIX       = "[AM] ",
    _CMD_PREFIX   = "!am_",
    _SETTINGS_DIR = "mapspawn_combiner/",
    _SETTINGS_FILE = "mapspawn_combiner/settings.txt",
    _KEY_ENABLED  = "__enabled",

    _CMD_HELP     = "!am_help",
    _CMD_MODULES  = "!am_modules",
    _CMD_INFO     = "!am_info",
    _CMD_ENABLE   = "!am_enable",
    _CMD_DISABLE  = "!am_disable",
    _CMD_VARS     = "!am_vars",
    _CMD_SET      = "!am_set",
    _CMD_SAVE     = "!am_save",
    _CMD_LOAD     = "!am_load",
    _CMD_RESET    = "!am_reset",

    _CMDS            = null,   // built after the table literal — see bottom
    _defaults        = null,   // moduleName -> { var = defaultValue }
    _defaultsEnabled = null,   // moduleName -> default enabled flag

    // Chat tip on join (как !tkc_help у tk_counter)
    _TIP_DELAY   = 3.0,
    _TIP_TEXT    = "mapspawn combiner admin — !am_help",
    _pendingTips = null,   // [ { player, showAt }, … ]
    _tipped      = null,   // steam account id -> true

    // ---------- messaging ----------

    function _msg( hPlayer, text ) {
        ClientPrint( hPlayer, HudPrint.Talk, this._PREFIX + text );
    },

    function _msgRaw( hPlayer, text ) {
        ClientPrint( hPlayer, HudPrint.Talk, text );
    },

    function _broadcast( text ) {
        Say( null, this._PREFIX + text );
    },

    function _moduleNotFound( hPlayer, name ) {
        this._msg( hPlayer, "Module not found: " + name );
    },

    // ---------- lookups ----------

    function _isAdmin( hPlayer ) {
        return ::McAuth.IsAdmin( hPlayer );
    },

    function _findModule( name ) {
        return ::McRegistry.FindModule( name );
    },

    // ---------- join tip (chat) ----------

    function OnGameEvent_player_activate( params ) {
        if ( !( "userid" in params ) )
            return;
        local hPlayer = GetPlayerFromUserID( params["userid"] );
        if ( hPlayer == null || !hPlayer.IsValid() )
            return;

        if ( this._tipped == null )
            this._tipped = {};
        if ( this._pendingTips == null )
            this._pendingTips = [];

        local id = ::McAuth.PlayerKey( hPlayer );
        if ( id != null && ( id in this._tipped ) )
            return;
        foreach ( entry in this._pendingTips ) {
            if ( entry.player == hPlayer )
                return;
        }
        this._pendingTips.append( { player = hPlayer, showAt = Time() + this._TIP_DELAY } );
    },

    function _sendHelpTip( hPlayer ) {
        if ( hPlayer == null || !hPlayer.IsValid() )
            return;
        local id = ::McAuth.PlayerKey( hPlayer );
        if ( id != null ) {
            if ( this._tipped == null )
                this._tipped = {};
            if ( id in this._tipped )
                return;
            this._tipped[id] <- true;
        }
        this._msg( hPlayer, this._TIP_TEXT );
    },

    function Update() {
        if ( this._pendingTips == null || this._pendingTips.len() == 0 )
            return;
        local now = Time();
        local remaining = [];
        foreach ( entry in this._pendingTips ) {
            if ( now >= entry.showAt ) {
                this._sendHelpTip( entry.player );
            } else {
                remaining.append( entry );
            }
        }
        this._pendingTips = remaining;
    },

    // ---------- parser ----------

    function OnGameEvent_player_say( params ) {
        if ( !( "text" in params ) )
            return;
        local raw = params["text"];
        if ( raw == null )
            return;

        // Allow /am_… as alias
        if ( raw.len() > 0 && raw.slice( 0, 1 ) == "/" )
            raw = "!" + raw.slice( 1 );

        local text = raw.tolower();
        if ( text.find( this._CMD_PREFIX ) != 0 )
            return;

        local hPlayer = GetPlayerFromUserID( params["userid"] );
        if ( !hPlayer || !hPlayer.IsValid() )
            return;

        foreach ( c in this._CMDS ) {
            local n = c.cmd.len();
            local exact   = ( text == c.cmd );
            local withArg = ( text.len() > n + 1 && text.slice( 0, n + 1 ) == c.cmd + " " );
            if ( !exact && !withArg )
                continue;

            if ( c.admin && !this._isAdmin( hPlayer ) ) {
                this._msg( hPlayer, "No permission. Type " + this._CMD_HELP + " for the command list." );
                return;
            }
            this[c.fn]( hPlayer, withArg ? raw.slice( n + 1 ) : "" );
            return;
        }
        this._printHelp( hPlayer, "" );
    },

    // ---------- commands (uniform signature: hPlayer, szArgs) ----------

    function _printHelp( hPlayer, szArgs ) {
        this._msg( hPlayer, "Mapspawn combiner module commands:" );
        foreach ( c in this._CMDS )
            this._msgRaw( hPlayer, "  " + c.cmd + c.args + " - " + c.help );
        this._msgRaw( hPlayer, "  Viewing is open; enable/disable/set/save/load/reset need mapspawn_combiner/admins.nut whitelist." );
        this._msgRaw( hPlayer, "  Settings file: save/vscripts/" + this._SETTINGS_FILE );
    },

    function _modVersion( mod ) {
        if ( ( "version" in mod ) && mod.version != null && mod.version != "" )
            return mod.version.tostring();
        return "?";
    },

    function _printList( hPlayer, szArgs ) {
        this._msg( hPlayer, "Modules:" );
        foreach ( mod in ::McRegistry.modules ) {
            local status = mod.enabled ? "[ON]" : "[OFF]";
            local ver = " v" + this._modVersion( mod );
            local selfMark = ( mod.name == this.name ) ? " (admin)" : "";
            local hint = ( "variables" in mod ) ? "  (" + this._CMD_VARS + " " + mod.name + ")" : "";
            this._msgRaw( hPlayer, "  " + status + " " + mod.name + ver + selfMark + hint );
        }
    },

    function _info( hPlayer, szArgs ) {
        if ( szArgs == "" ) {
            this._msg( hPlayer, "Usage: " + this._CMD_INFO + " <module>" );
            return;
        }
        local mod = this._findModule( szArgs );
        if ( mod == null ) {
            this._moduleNotFound( hPlayer, szArgs );
            return;
        }
        local status = mod.enabled ? "[ON]" : "[OFF]";
        local desc = ( "description" in mod ) ? mod.description : "no description";
        this._msg( hPlayer, status + " " + mod.name + " v" + this._modVersion( mod ) + " - " + desc );
        if ( "variables" in mod )
            this._msgRaw( hPlayer, "  " + this._CMD_VARS + " " + mod.name + " - list tunables" );
        if ( "console_info" in mod ) {
            foreach ( line in mod.console_info )
                ClientPrint( hPlayer, HudPrint.Console, line );
        }
    },

    function _enable( hPlayer, szArgs )  { this._toggleModule( hPlayer, szArgs, true );  },
    function _disable( hPlayer, szArgs ) { this._toggleModule( hPlayer, szArgs, false ); },

    function _toggleModule( hPlayer, name, enable ) {
        if ( name == "" ) {
            this._msg( hPlayer, "Usage: " + ( enable ? this._CMD_ENABLE : this._CMD_DISABLE ) + " <module>" );
            return;
        }
        local mod = this._findModule( name );
        if ( mod == null ) {
            this._moduleNotFound( hPlayer, name );
            return;
        }
        if ( mod.name == this.name ) {
            this._msg( hPlayer, "Cannot disable admin (would lock the commands)." );
            return;
        }
        if ( mod.enabled == enable ) {
            this._msg( hPlayer, mod.name + " is already " + ( enable ? "ON" : "OFF" ) + "." );
            return;
        }
        ::McRegistry.SetEnabled( mod, enable );
        this._broadcast( mod.name + ( enable ? " enabled." : " disabled." ) );
        this._msg( hPlayer, "Runtime only until " + this._CMD_SAVE + "." );
    },

    function _printVars( hPlayer, szArgs ) {
        if ( szArgs == "" ) {
            this._msg( hPlayer, "Usage: " + this._CMD_VARS + " <module>" );
            return;
        }
        local mod = this._findModule( szArgs );
        if ( mod == null ) {
            this._moduleNotFound( hPlayer, szArgs );
            return;
        }
        if ( !( "variables" in mod ) ) {
            this._msg( hPlayer, mod.name + " has no variables." );
            return;
        }
        this._msg( hPlayer, mod.name + " variables:" );
        local keys = [];
        if ( "variables_order" in mod )
            keys = mod.variables_order;
        else {
            foreach ( k, v in mod.variables )
                keys.append( k );
        }
        foreach ( k in keys ) {
            if ( !( k in mod.variables ) )
                continue;
            local line = "  " + k + " = " + mod.variables[k];
            if ( ( "variables_help" in mod ) && ( k in mod.variables_help ) )
                line += " - " + mod.variables_help[k];
            this._msgRaw( hPlayer, line );
        }
    },

    function _setVar( hPlayer, szArgs ) {
        // <module> <var> <value…>
        local parts = [];
        local s = ::McAuth.TrimSpaces( szArgs );
        local start = 0;
        local i = 0;
        local n = s.len();
        while ( i < n && parts.len() < 2 ) {
            if ( s.slice( i, i + 1 ) == " " ) {
                if ( i > start )
                    parts.append( s.slice( start, i ) );
                while ( i < n && s.slice( i, i + 1 ) == " " )
                    i += 1;
                start = i;
                continue;
            }
            i += 1;
        }
        if ( start < n )
            parts.append( s.slice( start ) );
        if ( parts.len() < 3 ) {
            this._msg( hPlayer, "Usage: " + this._CMD_SET + " <module> <var> <value>" );
            return;
        }
        local mod = this._findModule( parts[0] );
        if ( mod == null ) {
            this._moduleNotFound( hPlayer, parts[0] );
            return;
        }
        local r = ::McRegistry.ApplyVariable( mod, parts[1], parts[2] );
        if ( r == "notfound" ) {
            this._msg( hPlayer, "Unknown variable: " + parts[1] );
            return;
        }
        if ( r == "rejected" ) {
            this._msg( hPlayer, "Value rejected by " + mod.name + "." );
            return;
        }
        this._msg( hPlayer, mod.name + "." + parts[1] + " = " + mod.variables[parts[1]] );
        this._msg( hPlayer, "Runtime only until " + this._CMD_SAVE + "." );
    },

    // ---------- persistence ----------

    function _ensureDefaults() {
        if ( this._defaults != null )
            return;
        this._defaults = {};
        this._defaultsEnabled = {};
        foreach ( mod in ::McRegistry.modules ) {
            this._defaultsEnabled[mod.name] <- mod.enabled;
            if ( !( "variables" in mod ) )
                continue;
            local copy = {};
            foreach ( k, v in mod.variables )
                copy[k] <- v;
            this._defaults[mod.name] <- copy;
        }
    },

    function _serialize() {
        local s = "";
        foreach ( mod in ::McRegistry.modules ) {
            if ( mod.name != this.name )
                s += mod.name + "." + this._KEY_ENABLED + "=" + ( mod.enabled ? "1" : "0" ) + "\n";
            if ( !( "variables" in mod ) )
                continue;
            foreach ( k, v in mod.variables )
                s += mod.name + "." + k + "=" + v + "\n";
        }
        return s;
    },

    function _splitLines( text ) {
        local lines = [];
        local start = 0;
        for ( local i = 0; i <= text.len(); i++ ) {
            if ( i == text.len() || text[i] == 10 ) {
                local line = text.slice( start, i );
                if ( line.len() > 0 && line[line.len() - 1] == 13 )
                    line = line.slice( 0, line.len() - 1 );
                if ( line.len() > 0 )
                    lines.append( line );
                start = i + 1;
            }
        }
        return lines;
    },

    // bSilentFlags = true (mapspawn): set enabled without OnEnable/OnDisable.
    // false (!am_load): fire lifecycle hooks on change.
    // Returns applied count, or -1 if no file.
    function _loadApply( bSilentFlags ) {
        local text = FileToString( this._SETTINGS_FILE );
        if ( text == null )
            return -1;
        local applied = 0;
        foreach ( line in this._splitLines( text ) ) {
            local dot = line.find( "." );
            local eq  = line.find( "=" );
            if ( dot == null || eq == null || dot == 0 || dot >= eq )
                continue;
            local mod = this._findModule( line.slice( 0, dot ) );
            if ( mod == null )
                continue;
            local key = line.slice( dot + 1, eq );
            local val = line.slice( eq + 1 );

            if ( key == this._KEY_ENABLED ) {
                if ( mod.name == this.name )
                    continue;
                local desired = ( val != "0" );
                if ( mod.enabled != desired ) {
                    if ( bSilentFlags )
                        mod.enabled = desired;
                    else
                        ::McRegistry.SetEnabled( mod, desired );
                    applied++;
                }
                continue;
            }

            if ( ::McRegistry.ApplyVariable( mod, key, val ) == null )
                applied++;
        }
        return applied;
    },

    // Called from mapspawn after all modules are registered (silent flags).
    function ApplySavedSettings( bSilentFlags ) {
        this._ensureDefaults();
        local n = this._loadApply( bSilentFlags );
        if ( n > 0 )
            printl( this._PREFIX + "Applied " + n + " saved setting(s) from " + this._SETTINGS_FILE );
        else if ( n == 0 )
            printl( this._PREFIX + "Settings file present, nothing to change." );
        else
            printl( this._PREFIX + "No settings file yet (" + this._SETTINGS_FILE + ")." );
        return n;
    },

    function _save( hPlayer, szArgs ) {
        this._ensureDefaults();
        StringToFile( this._SETTINGS_FILE, this._serialize() );
        this._broadcast( "Settings saved to save/vscripts/" + this._SETTINGS_FILE );
    },

    function _load( hPlayer, szArgs ) {
        this._ensureDefaults();
        local n = this._loadApply( false );
        if ( n < 0 ) {
            this._msg( hPlayer, "No settings file (" + this._SETTINGS_FILE + ")." );
            return;
        }
        this._broadcast( "Loaded " + n + " setting(s) from save/vscripts/" + this._SETTINGS_FILE );
    },

    function _reset( hPlayer, szArgs ) {
        this._ensureDefaults();
        if ( this._defaults != null ) {
            foreach ( modName, vars in this._defaults ) {
                local mod = this._findModule( modName );
                if ( mod == null || !( "variables" in mod ) )
                    continue;
                foreach ( k, v in vars ) {
                    if ( k in mod.variables )
                        mod.variables[k] = v;
                }
            }
        }
        if ( this._defaultsEnabled != null ) {
            foreach ( modName, def in this._defaultsEnabled ) {
                local mod = this._findModule( modName );
                if ( mod == null || mod.name == this.name )
                    continue;
                if ( mod.enabled != def )
                    ::McRegistry.SetEnabled( mod, def );
            }
        }
        StringToFile( this._SETTINGS_FILE, "" );
        this._broadcast( "Settings reset to defaults; save/vscripts/" + this._SETTINGS_FILE + " cleared." );
    },
};

m._CMDS = [
    { cmd = m._CMD_HELP,    args = "",                        help = "this list (everyone)",                  admin = false, fn = "_printHelp" },
    { cmd = m._CMD_MODULES, args = "",                        help = "list modules with ON/OFF (everyone)",   admin = false, fn = "_printList" },
    { cmd = m._CMD_INFO,    args = " <module>",               help = "show what a module does (everyone)",    admin = false, fn = "_info"      },
    { cmd = m._CMD_VARS,    args = " <module>",               help = "show a module's variables (everyone)",  admin = false, fn = "_printVars" },
    { cmd = m._CMD_ENABLE,  args = " <module>",               help = "enable a module (admin, until save)",   admin = true,  fn = "_enable"    },
    { cmd = m._CMD_DISABLE, args = " <module>",               help = "disable a module (admin, until save)",  admin = true,  fn = "_disable"   },
    { cmd = m._CMD_SET,     args = " <module> <var> <value>", help = "change a variable (admin, until save)", admin = true,  fn = "_setVar"    },
    { cmd = m._CMD_SAVE,    args = "",                        help = "save on/off + variables to disk (admin)", admin = true, fn = "_save"     },
    { cmd = m._CMD_LOAD,    args = "",                        help = "re-apply the saved settings (admin)",   admin = true,  fn = "_load"      },
    { cmd = m._CMD_RESET,   args = "",                        help = "restore defaults and clear the file (admin)", admin = true, fn = "_reset" },
];

::McRegistry.Register( m );
printl( "[MC] type !am_help for more info" );
