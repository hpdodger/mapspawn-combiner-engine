// always/registry.nut
// Реестр always-on модулей. Подключается один раз из mapspawn.nut.
// Модули этот файл сами не подключают — он уже должен быть загружен.
//
// Вид модуля:
//   local m = {
//       name, enabled, convars, version, description, requires_registry?,
//       function OnGameEvent_*(params) { … },
//       function OnEnable() { … },
//       function OnDisable() { … },
//   };
//   ::AlwaysDeclareVariables(m, [[name, default, help, meta?], …]);  // по желанию
//   ::AlwaysRegister(m);
//
// API:
//   ::AlwaysRegister(m)
//   ::AlwaysDispatch(hookName)
//   ::AlwaysDispatchEvent(hookName, params)
//   ::AlwaysSetEnabled(m, enable)
//   ::AlwaysFindModule(name)
//   ::AlwaysDeclareVariables(m, decls)
//   ::AlwaysApplyVariable(mod, varName, valStr)
//   ::AlwaysApplyConvars()
//   ::AlwaysDispatchDamage(...)   — конвейер OnTakeDamage_Alive_Any (v4)
//
// v1: register + dispatch
// v2: AlwaysSetEnabled / AlwaysFindModule
// v3: HudPrint, convars, DeclareVariables / ApplyVariable / ApplyConvars
// v4: AlwaysDispatchDamage

::ALWAYS_REGISTRY_VERSION <- 4;

enum HudPrint {
    Notify  = 1,
    Console = 2,
    Talk    = 3,
    Center  = 4,
}

::g_AlwaysModules         <- [];
::g_AlwaysConvarRegistry  <- {};
::g_AlwaysConvarConflicts <- [];

::AlwaysRegister <- function( m ) {
    if ( m == null || !( "name" in m ) || m.name == null || m.name == "" ) {
        printl( "[Always] AlwaysRegister: module missing name" );
        return;
    }
    if ( !( "enabled" in m ) )
        m.enabled <- true;
    if ( !( "convars" in m ) )
        m.convars <- {};
    if ( ( "requires_registry" in m ) && m.requires_registry > ::ALWAYS_REGISTRY_VERSION ) {
        local msg = "[Always] WARNING: module " + m.name + " requires registry v"
            + m.requires_registry + ", this is v" + ::ALWAYS_REGISTRY_VERSION
            + " — update always/registry.nut";
        printl( msg );
        ClientPrint( null, HudPrint.Talk, msg );
    }
    foreach ( existing in ::g_AlwaysModules ) {
        if ( existing.name == m.name ) {
            printl( "[Always] AlwaysRegister: duplicate name \"" + m.name + "\", skip" );
            return;
        }
    }
    ::g_AlwaysModules.append( m );
    foreach ( cvar, val in m.convars )
        ::_AlwaysConvarAdd( m.name, cvar, val.tostring() );
    printl( "[Always] registered module: " + m.name );
};

::AlwaysDispatch <- function( hookName ) {
    foreach ( m in ::g_AlwaysModules ) {
        if ( !m.enabled || !( hookName in m ) )
            continue;
        try {
            m[hookName]();
        } catch ( e ) {
            printl( "[Always] ERROR in " + m.name + "." + hookName + ": " + e );
        }
    }
};

::AlwaysDispatchEvent <- function( hookName, params ) {
    foreach ( m in ::g_AlwaysModules ) {
        if ( !m.enabled || !( hookName in m ) )
            continue;
        try {
            m[hookName]( params );
        } catch ( e ) {
            printl( "[Always] ERROR in " + m.name + "." + hookName + ": " + e );
        }
    }
};

::AlwaysFindModule <- function( name ) {
    if ( name == null )
        return null;
    local want = name.tostring().tolower();
    foreach ( m in ::g_AlwaysModules ) {
        if ( m.name.tolower() == want )
            return m;
    }
    return null;
};

::AlwaysSetEnabled <- function( m, enable ) {
    if ( m == null )
        return;
    m.enabled = enable;
    local hook = enable ? "OnEnable" : "OnDisable";
    if ( !( hook in m ) )
        return;
    try {
        m[hook]();
    } catch ( e ) {
        printl( "[Always] ERROR in " + m.name + "." + hook + ": " + e );
    }
};

// Объявить настраиваемые переменные модуля (для !ao_vars / !ao_set).
::AlwaysDeclareVariables <- function( m, decls ) {
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
};

// Вернёт null если записали, "notfound" или "rejected".
::AlwaysApplyVariable <- function( mod, varName, valStr ) {
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
};

::AlwaysApplyConvars <- function() {
    foreach ( msg in ::g_AlwaysConvarConflicts ) {
        Say( null, msg );
        ClientPrint( null, HudPrint.Talk, msg );
    }
    foreach ( cvar, entry in ::g_AlwaysConvarRegistry )
        Convars.SetValueString( cvar, entry.value );
    ::g_AlwaysConvarRegistry  = {};
    ::g_AlwaysConvarConflicts = [];
};

::_AlwaysConvarAdd <- function( moduleName, cvar, valStr ) {
    if ( cvar in ::g_AlwaysConvarRegistry ) {
        local e = ::g_AlwaysConvarRegistry[cvar];
        if ( e.value != valStr )
            ::g_AlwaysConvarConflicts.append(
                "[Always] convar conflict: \"" + cvar + "\""
                + " — " + e.module + " wants " + e.value
                + ", " + moduleName + " wants " + valStr
                + " (keeping " + e.value + ")"
            );
    } else {
        ::g_AlwaysConvarRegistry[cvar] <- { module = moduleName, value = valStr };
    }
};

// Прогон урона по включённым модулям. Числовой return заменяет damage;
// исключение или не-число оставляют текущее значение.
::AlwaysDispatchDamage <- function( victim, inflictor, attacker, weapon, damage, damageType, ammoName ) {
    foreach ( m in ::g_AlwaysModules ) {
        if ( !m.enabled || !( "OnTakeDamage_Alive_Any" in m ) )
            continue;
        try {
            local r = m.OnTakeDamage_Alive_Any( victim, inflictor, attacker, weapon, damage, damageType, ammoName );
            if ( typeof r == "integer" || typeof r == "float" )
                damage = r;
        } catch ( e ) {
            printl( "[Always] ERROR in " + m.name + ".OnTakeDamage_Alive_Any: " + e );
        }
    }
    return damage;
};
