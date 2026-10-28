// mapspawn_combiner/modules/tk_counter/module_tk_counter.nut
// Подключает счётчик тимкиллов к реестру McRegistry.
// Реестр уже должен быть загружен mapspawn.
// Логика счётчика — в modules/tk_counter/*.nut (в script scope worldspawn).
// Попап: rd_hud_vscript + клиент tk_counter/tkc_popup_hud.nut
// (тот же stub-челлендж weapon_kills, что и попап оружия).

if ( "TkCounterLoaded" in getroottable() ) {
    ::McLog.Info( "[MC] tk_counter: already loaded, skip" );
} else {
    getroottable().TkCounterLoaded <- true;

    IncludeScript( "mapspawn_combiner/modules/tk_counter/version" );

    local hWorld = Entities.FindByClassname( null, "worldspawn" );
    hWorld.ValidateScriptScope();
    local scope = hWorld.GetScriptScope();
    IncludeScript( "mapspawn_combiner/modules/tk_counter/tk_counter", scope );

    local m = {
        name        = "tk_counter",
        enabled     = true,
        convars     = {},
        version     = ::g_TkVersion,
        description = "Teamkill counter, ranks, !tkc commands, world popup.",
        requires_registry = 4,

        _scope = null,
        // Тот же Paint, что у попапа оружия — файл уже в опубликованном stub.
        _CLIENT_SCRIPT = "weapon_kills/wkc_popup_hud.nut",
        _popups = null,   // [ { ent, marine, hideAt }, … ]

        function OnGameEvent_entity_killed( params ) {
            this._scope._OnEntityKilled( params );
        },

        function OnGameEvent_player_activate( params ) {
            if ( !( "userid" in params ) )
                return;
            local hPlayer = GetPlayerFromUserID( params["userid"] );
            if ( hPlayer )
                this._scope._OnPlayerActivate( hPlayer );
        },

        function OnGameEvent_player_say( params ) {
            this._scope._OnPlayerSay( params );
        },

        // "R G B" → [r,g,b] 0..255; битый ввод → fallback.
        function _parseRgb( raw, fallback ) {
            local fb = fallback;
            if ( fb == null )
                fb = [ 255, 255, 255 ];
            if ( raw == null )
                return [ fb[0], fb[1], fb[2] ];
            local s = raw.tostring();
            while ( s.len() > 0 && s.slice( 0, 1 ) == " " )
                s = s.slice( 1 );
            while ( s.len() > 0 && s.slice( s.len() - 1 ) == " " )
                s = s.slice( 0, s.len() - 1 );
            local parts = [];
            local start = 0;
            for ( local i = 0; i <= s.len(); i++ ) {
                local end = ( i == s.len() );
                local ch = end ? " " : s.slice( i, i + 1 );
                if ( ch == " " || ch == "," || ch == ";" || end ) {
                    if ( i > start )
                        parts.append( s.slice( start, i ) );
                    start = i + 1;
                }
            }
            if ( parts.len() < 3 )
                return [ fb[0], fb[1], fb[2] ];
            try {
                local r = parts[0].tointeger();
                local g = parts[1].tointeger();
                local b = parts[2].tointeger();
                if ( r < 0 ) r = 0; if ( r > 255 ) r = 255;
                if ( g < 0 ) g = 0; if ( g > 255 ) g = 255;
                if ( b < 0 ) b = 0; if ( b > 255 ) b = 255;
                return [ r, g, b ];
            } catch ( e ) {
                return [ fb[0], fb[1], fb[2] ];
            }
        },

        function _clampByte( v, defv ) {
            if ( v == null )
                return defv;
            local n = v.tointeger();
            if ( n < 0 ) n = 0;
            if ( n > 255 ) n = 255;
            return n;
        },

        function _stackIndexForMarine( hMarine ) {
            if ( this._popups == null )
                return 0;
            local n = 0;
            local now = Time();
            foreach ( p in this._popups ) {
                if ( p.marine == hMarine && p.hideAt > now )
                    n += 1;
            }
            return n;
        },

        function _writePopupStyle( e ) {
            local v = this.variables;
            local accent = this._parseRgb( v.popup_accent, [ 255, 70, 70 ] );
            local text = this._parseRgb( v.popup_text, [ 255, 40, 40 ] );
            local bg = this._parseRgb( v.popup_bg, [ 16, 6, 8 ] );

            e.SetInt( 3, accent[0] );
            e.SetInt( 4, accent[1] );
            e.SetInt( 5, accent[2] );
            e.SetInt( 6, text[0] );
            e.SetInt( 7, text[1] );
            e.SetInt( 8, text[2] );
            e.SetInt( 9, bg[0] );
            e.SetInt( 10, bg[1] );
            e.SetInt( 11, bg[2] );
            e.SetInt( 12, this._clampByte( v.popup_bg_alpha, 225 ) );
            e.SetInt( 13, this._clampByte( v.popup_alpha, 230 ) );
            e.SetInt( 14, 1 );

            e.SetFloat( 2, v.popup_x.tofloat() );
            e.SetFloat( 3, v.popup_y.tofloat() );
            e.SetFloat( 4, v.popup_stack_gap.tofloat() );
            // Череп квадратный. 56×28 осталось от винтовки и растягивало иконку.
            local iw = v.popup_icon_w.tofloat();
            local ih = v.popup_icon_h.tofloat();
            if ( iw == 56.0 && ih == 28.0 ) {
                iw = 32.0;
                ih = 32.0;
                v.popup_icon_w = 32.0;
                v.popup_icon_h = 32.0;
            }
            e.SetFloat( 5, iw );
            e.SetFloat( 6, ih );
            e.SetFloat( 7, v.popup_scale.tofloat() );
            e.SetFloat( 8, v.popup_anim_time.tofloat() );
        },

        // Ник командира. Переводы строк выкидываем: они отделяют ник от пути иконки.
        function _commanderNick( hMarine ) {
            if ( hMarine == null || !hMarine.IsValid() )
                return "";
            if ( !hMarine.IsInhabited() )
                return "";
            local hPlayer = hMarine.GetCommander();
            if ( hPlayer == null || !hPlayer.IsValid() )
                return "";
            local name = hPlayer.GetPlayerName();
            if ( name == null )
                return "";
            name = name.tostring();
            local out = "";
            for ( local i = 0; i < name.len(); i++ ) {
                local ch = name.slice( i, i + 1 );
                if ( ch != "\n" && ch != "\r" )
                    out += ch;
            }
            return out;
        },

        // Одна сетевая строка: путь иконки, затем перевод строки и ник. Лимит 255 байт.
        function _popupPayload( icon, hMarine ) {
            local path = "";
            if ( icon != null )
                path = icon.tostring();
            local nick = this._commanderNick( hMarine );
            if ( nick == "" )
                return path;
            local room = 255 - path.len() - 1;
            if ( room < 1 )
                return path;
            if ( nick.len() > room )
                nick = nick.slice( 0, room );
            return path + "\n" + nick;
        },

        // animFrom — старт накрутки, count — конечное число на попапе.
        function _showPopup( hMarine, animFrom, count ) {
            if ( hMarine == null || !hMarine.IsValid() )
                return false;
            if ( !( "variables" in this ) || this.variables.popup == 0 )
                return false;
            if ( count == null || count < 1 )
                return false;
            if ( animFrom == null )
                animFrom = 0;
            animFrom = animFrom.tointeger();
            count = count.tointeger();
            if ( animFrom < 0 )
                animFrom = 0;
            if ( animFrom > count )
                animFrom = count;

            local delay = this.variables.popup_delay.tofloat();
            if ( delay < 0.0 )
                delay = 0.0;
            local life = this.variables.popup_lifetime.tofloat();
            if ( life < 0.5 )
                life = 0.5;

            local icon = "vgui/tk_counter/dead_icon";
            if ( ( "popup_icon" in this.variables ) && this.variables.popup_icon != null && this.variables.popup_icon.tostring() != "" ) {
                local custom = this.variables.popup_icon.tostring();
                if ( custom != "vgui/swarm/EquipIcons/EquipRifle" )
                    icon = custom;
            }

            local now = Time();
            local showAt = now + delay;
            local hideAt = showAt + life;
            local stack = this._stackIndexForMarine( hMarine );

            local e = Entities.CreateByClassname( "rd_hud_vscript" );
            if ( e == null || !e.IsValid() ) {
                ::McLog.Err( "[TK] failed to create rd_hud_vscript" );
                return false;
            }
            e.__KeyValueFromString( "client_vscript", this._CLIENT_SCRIPT );
            e.Spawn();
            e.Activate();
            e.SetEntity( 0, hMarine );
            e.SetString( 0, this._popupPayload( icon, hMarine ) );
            e.SetInt( 0, animFrom );
            e.SetInt( 1, count );
            e.SetInt( 2, stack );
            e.SetInt( 19, hMarine.entindex() );
            e.SetInt( 20, 2 );   // дорожка стека: тимкилл
            e.SetFloat( 0, showAt );
            e.SetFloat( 1, hideAt );
            this._writePopupStyle( e );

            if ( this._popups == null )
                this._popups = [];
            this._popups.append( { ent = e, marine = hMarine, hideAt = hideAt } );
            return true;
        },

        function _flushPopups() {
            if ( this._popups == null || this._popups.len() == 0 )
                return;
            local now = Time();
            local keep = [];
            foreach ( p in this._popups ) {
                local dead = false;
                if ( p.ent == null || !p.ent.IsValid() )
                    dead = true;
                else if ( now > p.hideAt + 0.5 )
                    dead = true;
                else if ( p.marine == null || !p.marine.IsValid() )
                    dead = true;

                if ( dead ) {
                    if ( p.ent != null && p.ent.IsValid() )
                        p.ent.Destroy();
                } else {
                    keep.append( p );
                }
            }
            this._popups = keep;
        },

        function _clearPopups() {
            if ( this._popups == null )
                return;
            foreach ( p in this._popups ) {
                if ( p.ent != null && p.ent.IsValid() )
                    p.ent.Destroy();
            }
            this._popups = [];
        },

        function Update() {
            this._flushPopups();
            this._scope.TkIoTick();
        },

        function OnGameplayStart() {
            this._clearPopups();
        },

        function Cleanup() {
            this._clearPopups();
        },

        function OnDisable() {
            this._clearPopups();
            ::McLog.Info( "[MC] tk_counter disabled (counting and !tkc paused)" );
        },

        function OnEnable() {
            ::McLog.Info( "[MC] tk_counter enabled" );
        },
    };

    m._scope = scope;

    ::McRegistry.DeclareVariables( m, [
        [ "popup", 1, "World popup on each teamkill (0 = red center text). Needs weapon_kills client stub", { kind = "bool" } ],
        [ "popup_lifetime", 3.5, "Popup visible duration in seconds", { min = 0.5, max = 15, step = 0.5 } ],
        [ "popup_delay", 0.4, "Delay before popup appears (seconds)", { min = 0, max = 3, step = 0.1 } ],
        [ "popup_anim_time", 0.4, "Seconds to spin the number (0 = instant)", { min = 0, max = 3, step = 0.05 } ],
        [ "popup_x", 120.0, "Popup X offset px @768p (positive = right of the head)", { min = -400, max = 400, step = 4 } ],
        [ "popup_y", -20.0, "Popup Y offset px @768p (negative = above head)", { min = -200, max = 200, step = 2 } ],
        [ "popup_stack_gap", 72.0, "Minimum distance between stacked popup centers (px @768p). Wider panels spread further.", { min = 20, max = 400, step = 4 } ],
        [ "popup_icon_w", 32.0, "DeadIcon width px @768p (square)", { min = 12, max = 96, step = 2 } ],
        [ "popup_icon_h", 32.0, "DeadIcon height px @768p (square)", { min = 12, max = 96, step = 2 } ],
        [ "popup_scale", 1.0, "Popup scale multiplier (icon, offsets, gap)", { min = 0.4, max = 3.0, step = 0.1 } ],
        [ "popup_accent", "255 70 70", "Stripe + skull tint RGB" ],
        [ "popup_text", "255 40 40", "Kill count RGB" ],
        [ "popup_bg", "16 6 8", "Background panel RGB" ],
        [ "popup_bg_alpha", 225, "Background alpha 0-255", { min = 0, max = 255, step = 5 } ],
        [ "popup_alpha", 230, "Icon/text max alpha 0-255", { min = 0, max = 255, step = 5 } ],
        [ "popup_icon", "vgui/tk_counter/dead_icon", "Icon material (DeadIcon crop from HUD sheet1)" ],
    ] );

    ::McRegistry.Register( m );
}
