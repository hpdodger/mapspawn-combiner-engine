// mapspawn_combiner/registry.nut
// Реестр модулей mapspawn combiner. Подключается один раз из mapspawn.nut.
// Модули этот файл сами не подключают — он уже должен быть загружен.
//
// Вид модуля:
//   local m = {
//       name, enabled, convars, version, description, requires_registry?,
//       function OnGameEvent_*(params) { … },
//       function OnEnable() { … },
//       function OnDisable() { … },
//   };
//   McRegistry.DeclareVariables(m, [[name, default, help, meta?], …]);  // по желанию
//   McRegistry.Register(m);
//
// API (таблица ::McRegistry):
//   Register, Dispatch, DispatchEvent, FindModule, SetEnabled,
//   DeclareVariables, ApplyVariable, ApplyConvars, DispatchDamage
//
// v1: register + dispatch
// v2: SetEnabled / FindModule
// v3: HudPrint, convars, DeclareVariables / ApplyVariable / ApplyConvars
// v4: DispatchDamage

enum HudPrint {
    Notify  = 1,
    Console = 2,
    Talk    = 3,
    Center  = 4,
}

::McRegistry <- {
    version         = 4,
    modules         = [],
    convarRegistry  = {},
    convarConflicts = [],

    function Register( m ) {
        if ( m == null || !( "name" in m ) || m.name == null || m.name == "" ) {
            printl( "[MC] Register: module missing name" );
            return;
        }
        if ( !( "enabled" in m ) )
            m.enabled <- true;
        if ( !( "convars" in m ) )
            m.convars <- {};
        if ( ( "requires_registry" in m ) && m.requires_registry > this.version ) {
            local msg = "[MC] WARNING: module " + m.name + " requires registry v"
                + m.requires_registry + ", this is v" + this.version
                + " — update mapspawn_combiner/registry.nut";
            printl( msg );
            ClientPrint( null, HudPrint.Talk, msg );
        }
        foreach ( existing in this.modules ) {
            if ( existing.name == m.name ) {
                printl( "[MC] Register: duplicate name \"" + m.name + "\", skip" );
                return;
            }
        }
        this.modules.append( m );
        foreach ( cvar, val in m.convars )
            this._ConvarAdd( m.name, cvar, val.tostring() );
        local line = "[MC] registered module: " + m.name;
        if ( ( "version" in m ) && m.version != null && m.version != "" )
            line += "  v" + m.version;
        printl( line );
    },

    function Dispatch( hookName ) {
        foreach ( m in this.modules ) {
            if ( !m.enabled || !( hookName in m ) )
                continue;
            try {
                m[hookName]();
            } catch ( e ) {
                printl( "[MC] ERROR in " + m.name + "." + hookName + ": " + e );
            }
        }
    },

    function DispatchEvent( hookName, params ) {
        foreach ( m in this.modules ) {
            if ( !m.enabled || !( hookName in m ) )
                continue;
            try {
                m[hookName]( params );
            } catch ( e ) {
                printl( "[MC] ERROR in " + m.name + "." + hookName + ": " + e );
            }
        }
    },

    // Имя модуля — точное совпадение (laser_pointer ≠ LaserPointer).
    function FindModule( name ) {
        if ( name == null )
            return null;
        local want = name.tostring();
        foreach ( m in this.modules ) {
            if ( m.name == want )
                return m;
        }
        return null;
    },

    function SetEnabled( m, enable ) {
        if ( m == null )
            return;
        m.enabled = enable;
        local hook = enable ? "OnEnable" : "OnDisable";
        if ( !( hook in m ) )
            return;
        try {
            m[hook]();
        } catch ( e ) {
            printl( "[MC] ERROR in " + m.name + "." + hook + ": " + e );
        }
    },

    // Объявить настраиваемые переменные модуля (для !am_vars / !am_set).
    function DeclareVariables( m, decls ) {
        m.variables       <- {};
        m.variables_help  <- {};
        m.variables_order <- [];
        m.variables_meta  <- {};
        foreach ( d in decls ) {
            m.variables[d[0]]      <- d[1];
            m.variables_help[d[0]] <- d[2];
            m.variables_order.append( d[0] );
            if ( d.len() > 3 )
                m.variables_meta[d[0]] <- d[3];
        }
    },

    // Вернёт null если записали, "notfound" или "rejected".
    function ApplyVariable( mod, varName, valStr ) {
        if ( !( "variables" in mod ) || !( varName in mod.variables ) )
            return "notfound";
        local current = mod.variables[varName];
        local newVal;
        if ( typeof current == "integer" || typeof current == "float" )
            newVal = valStr.tofloat();
        else
            newVal = valStr;
        if ( "OnVariableChanged" in mod ) {
            local r = mod.OnVariableChanged( varName, newVal );
            if ( typeof r == "bool" && !r )
                return "rejected";
            if ( r != null && typeof r != "bool" )
                newVal = r;
        }
        mod.variables[varName] = newVal;
        return null;
    },

    function ApplyConvars() {
        foreach ( msg in this.convarConflicts ) {
            Say( null, msg );
            ClientPrint( null, HudPrint.Talk, msg );
        }
        foreach ( cvar, entry in this.convarRegistry )
            Convars.SetValueString( cvar, entry.value );
        this.convarRegistry  = {};
        this.convarConflicts = [];
    },

    function _ConvarAdd( moduleName, cvar, valStr ) {
        if ( cvar in this.convarRegistry ) {
            local e = this.convarRegistry[cvar];
            if ( e.value != valStr )
                this.convarConflicts.append(
                    "[MC] convar conflict: \"" + cvar + "\""
                    + " — " + e.module + " wants " + e.value
                    + ", " + moduleName + " wants " + valStr
                    + " (keeping " + e.value + ")"
                );
        } else {
            this.convarRegistry[cvar] <- { module = moduleName, value = valStr };
        }
    },

    // Прогон урона по включённым модулям. Числовой return заменяет damage;
    // исключение или не-число оставляют текущее значение.
    function DispatchDamage( victim, inflictor, attacker, weapon, damage, damageType, ammoName ) {
        foreach ( m in this.modules ) {
            if ( !m.enabled || !( "OnTakeDamage_Alive_Any" in m ) )
                continue;
            try {
                local r = m.OnTakeDamage_Alive_Any( victim, inflictor, attacker, weapon, damage, damageType, ammoName );
                if ( typeof r == "integer" || typeof r == "float" )
                    damage = r;
            } catch ( e ) {
                printl( "[MC] ERROR in " + m.name + ".OnTakeDamage_Alive_Any: " + e );
            }
        }
        return damage;
    },
};
