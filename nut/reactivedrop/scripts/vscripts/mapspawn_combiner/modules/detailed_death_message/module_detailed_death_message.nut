// mapspawn_combiner/modules/detailed_death_message/module_detailed_death_message.nut
// Подробное сообщение о смерти морпеха в чат: чем били до последнего удара.
//
// Автор логики: jhh8
//   https://github.com/jhh8/detailed-death-message
// Порт под combiner и i18n (McI18n / !mc_lang): typical russian
//
// Хуки: OnTakeDamage_Alive_Any (урон не меняется), AlterDeathMessage.
// Выключить: !am_disable detailed_death_message

if ( "DetailedDeathMessageLoaded" in getroottable() ) {
    ::McLog.Info( "[MC] detailed_death_message: already loaded, skip" );
} else {
    getroottable().DetailedDeathMessageLoaded <- true;

IncludeScript( "mapspawn_combiner/modules/detailed_death_message/strings" );

local m = {
    name        = "detailed_death_message",
    enabled     = true,
    convars     = {},
    version     = "1.0.0",
    description = "Detailed marine death line in chat (history of hits). Original: jhh8.",
    requires_registry = 4,

    console_info = [
        "=== detailed_death_message ===",
        "Author of the original script: jhh8",
        "  https://github.com/jhh8/detailed-death-message",
        "Replaces the vanilla 'X died' chat line with a sentence of what hit the marine.",
        "Language: each player sees their !mc_lang (en|ru). Override: !am_set detailed_death_message force_lang en|ru",
        "force_lang=player (default) — per viewer. en or ru — one language for everyone.",
        "Does not change damage. Toggle: !am_enable / !am_disable detailed_death_message",
    ],

    _I_INFL = 0,
    _I_ATK  = 1,
    _I_WEP  = 2,
    _I_TYPE = 3,
    _I_AMMO = 4,
    _I_HP   = 5,
    _I_DMG  = 6,
    _I_TIME = 7,

    _SCOPE_HIST = "ddm_DamageHistory",
    _SCOPE_HP   = "ddm_PrevHealth",

    _colorAlt = false,
    _typeBits = null,

    // ---------- i18n ----------

    function _langOf( hPlayer ) {
        local force = "player";
        if ( ( "variables" in this ) && ( "force_lang" in this.variables ) )
            force = this.variables.force_lang.tostring();
        if ( force == "en" || force == "ru" )
            return force;
        if ( "McI18n" in getroottable() )
            return ::McI18n.LangOf( hPlayer );
        return "en";
    },

    function _L( row, lang ) {
        if ( "McI18n" in getroottable() )
            return ::McI18n.Label( row, lang );
        if ( row == null )
            return "";
        if ( typeof row == "string" )
            return row;
        if ( lang in row )
            return row[lang];
        if ( "en" in row )
            return row.en;
        return "";
    },

    function _TF( msgId, lang, vars ) {
        if ( !( "DdmI18n" in getroottable() ) )
            return msgId;
        local row = ::DdmI18n.msg[msgId];
        if ( "McI18n" in getroottable() )
            return ::McI18n.Fill( this._L( row, lang ), vars );
        return this._L( row, lang );
    },

    function OnVariableChanged( varName, newVal ) {
        if ( varName != "force_lang" )
            return newVal;
        local s = newVal.tostring().tolower();
        if ( s == "player" || s == "en" || s == "ru" )
            return s;
        return "player";
    },

    // ---------- names ----------

    function _entityLabel( id, lang ) {
        if ( id == null || id == "" )
            return "";
        if ( id == "himself" )
            return this._TF( "himself", lang, null );
        if ( ( "DdmI18n" in getroottable() ) && ( id in ::DdmI18n.entities ) )
            return this._L( ::DdmI18n.entities[id], lang );
        return id;
    },

    function _typeLabel( id, lang ) {
        if ( ( "DdmI18n" in getroottable() ) && ( id in ::DdmI18n.types ) )
            return this._L( ::DdmI18n.types[id], lang );
        if ( ( "DdmI18n" in getroottable() ) && ( "damaged" in ::DdmI18n.types ) )
            return this._L( ::DdmI18n.types.damaged, lang );
        return "damaged";
    },

    function _actorId( hVictim, hEnt ) {
        if ( hEnt == null || !hEnt.IsValid() )
            return "";
        local cls = hEnt.GetClassname();
        if ( ( "DdmI18n" in getroottable() ) && ( cls in ::DdmI18n.entities ) )
            return cls;
        if ( cls != "asw_marine" )
            return cls;
        if ( hVictim == hEnt )
            return "himself";
        if ( !hEnt.IsInhabited() )
            return hEnt.GetMarineName();
        local cmd = hEnt.GetCommander();
        if ( cmd == null || !cmd.IsValid() )
            return hEnt.GetMarineName();
        return cmd.GetPlayerName();
    },

    function _weaponId( hWeapon ) {
        if ( hWeapon == null || !hWeapon.IsValid() )
            return "";
        return hWeapon.GetClassname();
    },

    function _typeFromBits( damageType ) {
        if ( this._typeBits != null && ( damageType in this._typeBits ) )
            return this._typeBits[damageType];
        return "damaged";
    },

    function _victimName( victim ) {
        if ( victim == null || !victim.IsValid() )
            return "";
        if ( victim.GetClassname() == "asw_marine" && victim.IsInhabited() ) {
            local cmd = victim.GetCommander();
            if ( cmd != null && cmd.IsValid() )
                return cmd.GetPlayerName();
        }
        if ( victim.GetClassname() == "asw_marine" )
            return victim.GetMarineName();
        return victim.GetClassname();
    },

    function _possessed( lang, ownerId, thingLabel ) {
        if ( ownerId == "himself" )
            return this._TF( "his_thing", lang, { thing = thingLabel } );
        return this._TF( "whose_thing", lang, {
            who = this._entityLabel( ownerId, lang ),
            thing = thingLabel,
        } );
    },

    function _killerAndType( lang, inf, atk, wep, typeId, isLast ) {
        local typeOut = isLast ? "killed" : typeId;
        local killer = this._entityLabel( atk, lang );

        if ( inf == "asw_burning" ) {
            killer = this._TF( isLast ? "killed_by_fire" : "set_on_fire", lang, null );
            typeOut = "";
        }
        else if ( wep != "" && atk != wep ) {
            killer = this._possessed( lang, atk, this._entityLabel( wep, lang ) );
        }
        else if ( inf != atk && typeId != "burned" ) {
            if ( inf != "" )
                killer = this._possessed( lang, atk, this._entityLabel( inf, lang ) );
            else
                killer = this._entityLabel( atk, lang );
        }

        return { killer = killer, typeId = typeOut };
    },

    function _joinerText( lang, kind, idx ) {
        if ( kind == "finally" )
            return this._TF( "finally_joiner", lang, null );
        local list = ( kind == "fast" ) ? ::DdmI18n.fast_joiners : ::DdmI18n.joiners;
        if ( idx < 0 || idx >= list.len() )
            idx = 0;
        return this._L( list[idx], lang );
    },

    function _compose( events, picks, lang ) {
        local death = this._TF( "lead", lang, null );
        for ( local i = 0; i < events.len(); i++ ) {
            local ev = events[i];
            local isLast = ( i == events.len() - 1 );
            local kt = this._killerAndType( lang, ev[this._I_INFL], ev[this._I_ATK],
                ev[this._I_WEP], ev[this._I_TYPE], isLast );

            local joiner = "";
            if ( i > 0 && i - 1 < picks.len() )
                joiner = this._joinerText( lang, picks[i - 1].kind, picks[i - 1].idx );

            local piece = "";
            if ( kt.typeId != "" ) {
                piece = this._TF( "event_typed", lang, {
                    type = this._typeLabel( kt.typeId, lang ),
                    killer = kt.killer,
                } );
            }
            else {
                piece = this._TF( "event_plain", lang, { killer = kt.killer } );
            }
            death += joiner + piece;
        }
        death += this._TF( "end", lang, null );
        return death;
    },

    function _pickJoiners( events ) {
        local picks = [];
        local prevTime = -1.0;
        for ( local i = 0; i < events.len(); i++ ) {
            local t = events[i][this._I_TIME];
            if ( i > 0 ) {
                local isLast = ( i == events.len() - 1 );
                if ( isLast && i >= 3 ) {
                    picks.append( { kind = "finally", idx = 0 } );
                }
                else if ( t - prevTime < 1.0 ) {
                    local n = ::DdmI18n.fast_joiners.len();
                    picks.append( { kind = "fast", idx = RandomInt( 0, n - 1 ) } );
                }
                else {
                    local n = ::DdmI18n.joiners.len();
                    picks.append( { kind = "slow", idx = RandomInt( 0, n - 1 ) } );
                }
            }
            prevTime = t;
        }
        return picks;
    },

    function _dedup( hist ) {
        local out = [];
        local seen = {};
        for ( local i = 0; i < hist.len(); i++ ) {
            local ev = hist[i];
            local isLast = ( i == hist.len() - 1 );
            local raw = ev[this._I_INFL] + ev[this._I_ATK] + ev[this._I_WEP] + ev[this._I_TYPE];
            if ( isLast && ( raw in seen ) )
                out.remove( seen[raw] );
            if ( !isLast && ( raw in seen ) )
                continue;
            out.push( ev );
            seen[raw] <- out.len() - 1;
        }
        return out;
    },

    function _colorPrefix() {
        this._colorAlt = !this._colorAlt;
        return TextColor( 255, this._colorAlt ? 255 : 200, 0 );
    },

    function _fillName( text, victim ) {
        local name = this._victimName( victim );
        if ( "McI18n" in getroottable() )
            return ::McI18n.ReplaceAll( text, "%s1", name );
        return text;
    },

    function _printLine( hPlayer, line ) {
        ClientPrint( hPlayer, HudPrint.Talk, line );
        ClientPrint( hPlayer, HudPrint.Console, line );
    },

    // ---------- hooks ----------

    // MUST return damage unchanged on every path.
    function OnTakeDamage_Alive_Any( victim, inflictor, attacker, weapon, damage, damageType, ammoName ) {
        if ( victim == null || !victim.IsValid() )
            return damage;
        if ( victim.GetClassname() != "asw_marine" )
            return damage;

        local ss = victim.GetScriptScope();
        local nHealth = victim.GetHealth();
        local nNewHealth = nHealth - damage.tointeger();
        if ( !ss || !( this._SCOPE_HIST in ss ) ) {
            victim.ValidateScriptScope();
            ss = victim.GetScriptScope();
            ss[this._SCOPE_HIST] <- [];
            ss[this._SCOPE_HP] <- victim.GetMaxHealth();
        }

        local hist = ss[this._SCOPE_HIST];
        if ( nHealth > ss[this._SCOPE_HP] ) {
            for ( local i = 0; i < hist.len(); i++ ) {
                if ( hist[i][this._I_HP] <= nHealth ) {
                    hist.remove( i );
                    i--;
                    continue;
                }
            }
        }
        ss[this._SCOPE_HP] <- nNewHealth;

        damageType = damageType &~ 2048;
        damageType = damageType &~ 4096;
        damageType = damageType &~ 8192;
        damageType = damageType &~ 32768;

        if ( damageType & 536870912 )
            damageType = 536870912;

        if ( inflictor && inflictor.IsValid() && inflictor.GetClassname() == "asw_door" )
            damageType = 1;

        local infId = this._actorId( victim, inflictor );
        local atkId = this._actorId( victim, attacker );
        local wepId = this._weaponId( weapon );
        local typeId = this._typeFromBits( damageType );

        if ( typeId == "infested" )
            atkId = "asw_parasite";

        if ( atkId == "asw_shieldbug" || atkId == "asw_boomer" )
            typeId = "kicked";

        if ( inflictor && inflictor.IsValid() && inflictor.GetClassname() == "prop_physics" ) {
            local model = inflictor.GetModelName();
            local parts = split( model, "/" );
            local stem = parts.len() > 0 ? parts[parts.len() - 1] : model;
            if ( stem.len() > 4 )
                stem = stem.slice( 0, stem.len() - 4 );
            infId = stem;
        }

        hist.push( [ infId, atkId, wepId, typeId, ammoName, nHealth, damage, Time() ] );
        return damage;
    },

    function AlterDeathMessage( victim, inflictor, attacker, weapon, damage, damageType, ammoName ) {
        if ( victim == null || !victim.IsValid() )
            return null;
        local ss = victim.GetScriptScope();
        if ( ss == null || !( this._SCOPE_HIST in ss ) )
            return null;
        local hist = ss[this._SCOPE_HIST];
        if ( hist == null || hist.len() == 0 )
            return null;
        if ( !( "DdmI18n" in getroottable() ) )
            return null;

        local events = this._dedup( hist );
        if ( events.len() == 0 )
            return null;

        local picks = this._pickJoiners( events );
        local color = this._colorPrefix();

        local players = [];
        local langs = {};
        local langCount = 0;
        local p = Entities.FindByClassname( null, "player" );
        while ( p != null ) {
            if ( p.IsValid() ) {
                local lang = this._langOf( p );
                players.append( { player = p, lang = lang } );
                if ( !( lang in langs ) ) {
                    langs[lang] <- true;
                    langCount++;
                }
            }
            p = Entities.FindByClassname( p, "player" );
        }

        // Один язык на всех — отдаём движку шаблон с %s1 (имя морпеха
        // подставит PrintDeathMessage, чат + консоль, без второй строки).
        if ( langCount <= 1 ) {
            local lang = "en";
            foreach ( l, _keep in langs )
                lang = l;
            return color + this._compose( events, picks, lang );
        }

        local cache = {};
        foreach ( rec in players ) {
            if ( !( rec.lang in cache ) )
                cache[rec.lang] <- this._fillName( this._compose( events, picks, rec.lang ), victim );
            this._printLine( rec.player, color + cache[rec.lang] );
        }

        // Штатное «X died» глушим: каждому уже ушла своя строка.
        return "\x01";
    },
};

m._typeBits <- {};
m._typeBits[0]          <- "damaged";
m._typeBits[1]          <- "crushed";
m._typeBits[2]          <- "shot";
m._typeBits[4]          <- "slashed";
m._typeBits[8]          <- "burned";
m._typeBits[16]         <- "ran_over";
m._typeBits[32]         <- "fell";
m._typeBits[64]         <- "exploded";
m._typeBits[128]        <- "meleed";
m._typeBits[256]        <- "shocked";
m._typeBits[512]        <- "kinetic";
m._typeBits[1024]       <- "energy_beamed";
m._typeBits[2048]       <- "damaged";
m._typeBits[4096]       <- "damaged";
m._typeBits[8192]       <- "damaged";
m._typeBits[16384]      <- "drowned";
m._typeBits[32768]      <- "paralyzed";
m._typeBits[65536]      <- "gassed";
m._typeBits[131072]     <- "poisoned";
m._typeBits[262144]     <- "radiated";
m._typeBits[524288]     <- "drowned";
m._typeBits[1048576]    <- "acided";
m._typeBits[2097152]    <- "burned";
m._typeBits[4194304]    <- "damaged";
m._typeBits[8388608]    <- "physgunned";
m._typeBits[16777216]   <- "plasma";
m._typeBits[33554432]   <- "infested";
m._typeBits[67108864]   <- "dissolved";
m._typeBits[134217728]  <- "blasted";
m._typeBits[268435456]  <- "burned";
m._typeBits[536870912]  <- "shotgunned";
m._typeBits[1073741824] <- "headshotted";

::McRegistry.DeclareVariables( m, [
    [ "force_lang", "player", "player = each viewer's !mc_lang; en or ru = one language for everyone" ],
] );
::McRegistry.Register( m );

} // DetailedDeathMessageLoaded
