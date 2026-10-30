// weapon_kills/wkc_popup_hud.nut — клиентский Paint для tier-up popup.
// Вешается на rd_hud_vscript (client_vscript). Видят все, у кого есть этот файл.
//
// Иконка приходит с сервера в String 0 (EquipIcon или vgui/weapon_kills/heal_icon).
// Клиентский список треков не нужен.
// Новые оружия = правка только серверного tracks.nut, Workshop-stub можно не обновлять.
//
// Слоты (сервер пишет из !am_set / variables, клиент читает):
//   Entity 0 — asw_marine (якорь)
//   String 0 — путь иконки, либо "путь\nник", либо "путь\nник\nзаголовок".
//              Ник — над полоской, от левого края, цветом полоски.
//              Третья строка — заголовок ачивки (Int 21 = 1): 1–2 строки под полоской справа от иконки.
//              Без перевода строки строка целиком — путь (старый сервер).
//   Ширина плашки — большая из двух: текст ника, либо отступ + иконка + число/заголовок + отступ.
//   Int 0    — старт накрутки числа
//   Int 1    — конец накрутки / порог тира
//   Int 2    — индекс стека. Отрицательный popup_x — дальше влево, положительный — дальше вправо.
//   Int 3..5 — accent RGB (полоска)
//   Int 6..8 — text RGB
//   Int 9..11 — bg RGB
//   Int 12   — bg alpha 0..255
//   Int 13   — content max alpha 0..255
//   Int 14   — 1 = сервер записал стиль (иначе fallback)
//   Int 15..17 — icon tint RGB (heal: 255 255 255, без cyan)
//   Int 18   — 1 = сервер записал icon tint (иначе tint = accent)
//   Int 19   — entindex морпеха (0 = старый сервер, стек по фиксированному шагу)
//   Int 20   — дорожка стека: 1 оружие, 2 тимкилл, 3 ачивка. Чужие плашки в расчёт не входят.
//   Int 21   — 1 = режим ачивки (иконка + заголовок, без числа).
//   Float 0  — Time() начала показа
//   Float 1  — Time() конца
//   Float 2  — popup_x @768p
//   Float 3  — popup_y @768p
//   Float 4  — stack_gap_x @768p
//   Float 5  — icon_w @768p
//   Float 6  — icon_h @768p
//   Float 7  — popup_scale (множитель; 1.0 = default)
//   Float 8  — popup_anim_time (сек накрутки; 0 = сразу конечное)
//
// LookupTexture / LookupFont — только лениво внутри Paint.

FONT <- -1;
TEXTURE_CACHE <- {};   // path -> texture id

FALLBACK <- {
    x = -120.0,
    y = -20.0,
    gap = 72.0,
    icon_w = 56.0,
    icon_h = 28.0,
    scale = 1.0,
    anim = 0.75,
    accent = [ 80, 180, 255 ],
    text = [ 255, 0, 0 ],
    bg = [ 8, 14, 28 ],
    bg_a = 225,
    alpha = 230,
};

function _ensureFont() {
    if ( FONT < 0 )
        FONT = self.LookupFont( "DefaultMedium" );
}

function _textureFor( path ) {
    if ( path == null || path == "" )
        return -1;
    if ( path in TEXTURE_CACHE )
        return TEXTURE_CACHE[path];
    local tex = self.LookupTexture( path );
    TEXTURE_CACHE[path] <- tex;
    return tex;
}

// Плавная накрутка from→to за animSec с момента t0.
function _spinValue( fromV, toV, t0, now, animSec ) {
    if ( toV < 1 )
        return 0;
    if ( animSec <= 0.0 || fromV >= toV )
        return toV;
    local u = ( now - t0 ) / animSec;
    if ( u <= 0.0 )
        return fromV;
    if ( u >= 1.0 )
        return toV;
    // ease-out: быстро старт, замедление к концу
    local eased = 1.0 - ( 1.0 - u ) * ( 1.0 - u );
    local v = fromV + ( toV - fromV ) * eased;
    return v.tointeger();
}

// Общая таблица всех плашек на этом клиенте. Ключ: "морпех:дорожка:стек".
function _layoutTable() {
    local root = getroottable();
    if ( !( "WkcPopupLayout" in root ) || root.WkcPopupLayout == null )
        root.WkcPopupLayout <- {};
    return root.WkcPopupLayout;
}

function _layoutKey( marineId, lane, stack ) {
    return marineId.tostring() + ":" + lane.tostring() + ":" + stack.tostring();
}

function _layoutPublish( marineId, lane, stack, width ) {
    if ( marineId <= 0 || lane <= 0 )
        return;
    local layout = _layoutTable();
    local now = Time();
    local drop = [];
    foreach ( k, rec in layout ) {
        if ( rec == null || !( "seen" in rec ) || ( now - rec.seen ) > 0.5 )
            drop.append( k );
    }
    foreach ( k in drop )
        delete layout[k];
    layout[_layoutKey( marineId, lane, stack )] <- {
        marine = marineId,
        lane = lane,
        stack = stack,
        w = width,
        seen = now,
    };
}

// Сдвиг центра относительно первой плашки.
// Не ближе stack * gapMin (старый шаг). Если плашки шире — отодвинуть, чтобы края не пересекались.
function _stackShift( marineId, lane, stack, myW, gapMin, edge ) {
    local layout = _layoutTable();
    local now = Time();
    local prev = [];
    foreach ( rec in layout ) {
        if ( rec == null || !( "seen" in rec ) )
            continue;
        if ( ( now - rec.seen ) > 0.5 )
            continue;
        if ( rec.marine != marineId || rec.lane != lane )
            continue;
        if ( rec.stack >= stack )
            continue;
        prev.append( { stack = rec.stack, w = rec.w } );
    }
    if ( prev.len() == 0 )
        return stack * gapMin;

    for ( local i = 1; i < prev.len(); i++ ) {
        local item = prev[i];
        local j = i - 1;
        while ( j >= 0 && prev[j].stack > item.stack ) {
            prev[j + 1] = prev[j];
            j--;
        }
        prev[j + 1] = item;
    }

    local shift = prev[0].w * 0.5;
    for ( local i = 1; i < prev.len(); i++ )
        shift += edge + prev[i].w;
    shift += edge + myW * 0.5;
    local minDist = stack.tofloat() * gapMin;
    if ( shift < minDist )
        shift = minDist;
    return shift;
}

// String 0: "иконка" / "иконка\nник" / "иконка\nник\nзаголовок".
function _splitPayload( raw ) {
    if ( raw == null )
        return { icon = "", nick = "", title = "" };
    local s = raw.tostring();
    local a = s.find( "\n" );
    if ( a == null )
        return { icon = s, nick = "", title = "" };
    local icon = s.slice( 0, a );
    local rest = s.slice( a + 1 );
    local b = rest.find( "\n" );
    if ( b == null )
        return { icon = icon, nick = rest, title = "" };
    return { icon = icon, nick = rest.slice( 0, b ), title = rest.slice( b + 1 ) };
}

function _outlineText( x, y, r, g, b, a, font, text ) {
    if ( text == null || text == "" || font == null || font == -1 )
        return;
    self.PaintText( x - 1, y,     0, 0, 0, a, font, text );
    self.PaintText( x + 1, y,     0, 0, 0, a, font, text );
    self.PaintText( x,     y - 1, 0, 0, 0, a, font, text );
    self.PaintText( x,     y + 1, 0, 0, 0, a, font, text );
    self.PaintText( x, y, r, g, b, a, font, text );
}

function _trimSpaces( s ) {
    if ( s == null )
        return "";
    s = s.tostring();
    while ( s.len() > 0 && s.slice( 0, 1 ) == " " )
        s = s.slice( 1 );
    while ( s.len() > 0 && s.slice( s.len() - 1 ) == " " )
        s = s.slice( 0, s.len() - 1 );
    return s;
}

// Перенос по последнему пробелу, если целиком не влезает. Одна длинная лексема — одна строка.
function _wrapTitle( text, maxW ) {
    local empty = [ "", "" ];
    if ( text == null )
        return empty;
    text = _trimSpaces( text.tostring() );
    if ( text == "" )
        return empty;
    if ( FONT == null || FONT == -1 )
        return [ text, "" ];
    if ( self.GetTextWide( FONT, text ).tofloat() <= maxW )
        return [ text, "" ];
    local best = -1;
    for ( local i = 0; i < text.len(); i++ ) {
        if ( text.slice( i, i + 1 ) != " " )
            continue;
        local left = _trimSpaces( text.slice( 0, i ) );
        if ( left == "" )
            continue;
        if ( self.GetTextWide( FONT, left ).tofloat() <= maxW )
            best = i;
    }
    if ( best < 1 )
        return [ text, "" ];
    return [ _trimSpaces( text.slice( 0, best ) ), _trimSpaces( text.slice( best + 1 ) ) ];
}

function _paintAchievement( sp, stack, iconPath, nick, title, screenX, gapX, iconW, iconH, scale, cy, alpha, pad, ar, ag, ab, tr, tg, tb, br, bg, bb, bgA, ir, ig, ib ) {
    local textH = 0.0;
    local nickW = 0.0;
    if ( FONT != null && FONT != -1 ) {
        textH = self.GetFontTall( FONT ).tofloat();
        if ( nick != "" )
            nickW = self.GetTextWide( FONT, nick ).tofloat();
    }

    local tex = _textureFor( iconPath );
    local hasIcon = ( tex != null && tex != -1 && iconPath != null && iconPath != "" );

    local wrapW = 110.0 * scale;
    local lines = _wrapTitle( title, wrapW );
    local line1 = lines[0];
    local line2 = lines[1];
    local titleW = 0.0;
    local titleH = 0.0;
    local lineGap = 1.0 * scale;
    if ( FONT != null && FONT != -1 ) {
        if ( line1 != "" )
            titleW = self.GetTextWide( FONT, line1 ).tofloat();
        if ( line2 != "" ) {
            local w2 = self.GetTextWide( FONT, line2 ).tofloat();
            if ( w2 > titleW )
                titleW = w2;
        }
    }
    local nlines = 0;
    if ( line1 != "" )
        nlines += 1;
    if ( line2 != "" )
        nlines += 1;
    if ( nlines > 0 )
        titleH = nlines.tofloat() * textH + ( nlines - 1 ).tofloat() * lineGap;

    local gapIcon = pad;
    local rowW = pad + titleW + pad;
    if ( hasIcon )
        rowW = pad + iconW + gapIcon + titleW + pad;
    local panelW = nickW;
    if ( rowW > panelW )
        panelW = rowW;

    local marineId = self.GetInt( 19 );
    local lane = self.GetInt( 20 );
    local gapMin = gapX * scale;
    local edge = 4.0 * scale;
    _layoutPublish( marineId, lane, stack, panelW );
    local shift = stack.tofloat() * gapMin;
    if ( marineId > 0 && lane > 0 && stack > 0 )
        shift = _stackShift( marineId, lane, stack, panelW, gapMin, edge );
    local cx = sp.x + ( screenX * scale );
    if ( screenX < 0.0 )
        cx = cx - shift;
    else
        cx = cx + shift;

    local contentH = iconH;
    if ( titleH > contentH )
        contentH = titleH;
    if ( !hasIcon )
        contentH = titleH;
    if ( contentH < textH )
        contentH = textH;
    local halfW = panelW * 0.5;
    local halfH = contentH * 0.5 + pad;

    local panelA = ( bgA.tofloat() * ( alpha.tofloat() / 255.0 ) ).tointeger();
    self.PaintRectangle(
        cx - halfW, cy - halfH,
        cx + halfW, cy + halfH,
        br, bg, bb, panelA
    );
    self.PaintRectangle(
        cx - halfW, cy - halfH,
        cx + halfW, cy - halfH + 2.0 * scale,
        ar, ag, ab, ( alpha * 0.9 ).tointeger()
    );

    local panelLeft = cx - halfW;
    local iconX = panelLeft + pad;
    if ( hasIcon ) {
        local iconTop = cy - iconH * 0.5;
        self.PaintTexturedRectangle(
            iconX, iconTop,
            iconX + iconW, iconTop + iconH,
            ir, ig, ib, alpha,
            tex
        );
    }
    if ( FONT != null && FONT != -1 && nlines > 0 ) {
        local tx = panelLeft + pad;
        if ( hasIcon )
            tx = iconX + iconW + gapIcon;
        local ty = cy - titleH * 0.5;
        _outlineText( tx, ty, tr, tg, tb, alpha, FONT, line1 );
        if ( line2 != "" )
            _outlineText( tx, ty + textH + lineGap, tr, tg, tb, alpha, FONT, line2 );
    }
    if ( nick != "" && FONT != null && FONT != -1 && textH > 0.0 ) {
        local nx = panelLeft;
        local ny = ( cy - halfH ) - textH - ( 2.0 * scale );
        _outlineText( nx, ny, ar, ag, ab, alpha, FONT, nick );
    }
}

function Paint() {
    local hMarine = self.GetEntity( 0 );
    if ( hMarine == null || !hMarine.IsValid() )
        return;

    local now = Time();
    local t0 = self.GetFloat( 0 );
    local t1 = self.GetFloat( 1 );
    if ( now < t0 || now > t1 )
        return;

    local fromV = self.GetInt( 0 );
    local toV = self.GetInt( 1 );
    local stack = self.GetInt( 2 );
    local packedEarly = _splitPayload( self.GetString( 0 ) );
    local achMode = ( self.GetInt( 21 ) == 1 );
    if ( !achMode && self.GetInt( 20 ) == 3 )
        achMode = true;
    if ( !achMode && packedEarly.title != "" )
        achMode = true;
    if ( !achMode && toV < 1 )
        return;
    if ( fromV < 0 )
        fromV = 0;

    local sp = self.ClientGetEntityScreenPos( hMarine, true );
    if ( !sp )
        return;

    _ensureFont();

    local packed = _splitPayload( self.GetString( 0 ) );
    local iconPath = packed.icon;
    local nick = packed.nick;
    local title = packed.title;
    local screenX = self.GetFloat( 2 );
    local screenY = self.GetFloat( 3 );
    local gapX = self.GetFloat( 4 );
    local iconW0 = self.GetFloat( 5 );
    local iconH0 = self.GetFloat( 6 );
    local userScale = self.GetFloat( 7 );
    local animSec = self.GetFloat( 8 );
    local ar = self.GetInt( 3 );
    local ag = self.GetInt( 4 );
    local ab = self.GetInt( 5 );
    local tr = self.GetInt( 6 );
    local tg = self.GetInt( 7 );
    local tb = self.GetInt( 8 );
    local br = self.GetInt( 9 );
    local bg = self.GetInt( 10 );
    local bb = self.GetInt( 11 );
    local bgA = self.GetInt( 12 );
    local maxA = self.GetInt( 13 );
    local ir = self.GetInt( 15 );
    local ig = self.GetInt( 16 );
    local ib = self.GetInt( 17 );
    local iconTintWritten = self.GetInt( 18 );

    if ( self.GetInt( 14 ) != 1 ) {
        screenX = FALLBACK.x;
        screenY = FALLBACK.y;
        gapX = FALLBACK.gap;
        iconW0 = FALLBACK.icon_w;
        iconH0 = FALLBACK.icon_h;
        userScale = FALLBACK.scale;
        animSec = FALLBACK.anim;
        ar = FALLBACK.accent[0]; ag = FALLBACK.accent[1]; ab = FALLBACK.accent[2];
        tr = FALLBACK.text[0]; tg = FALLBACK.text[1]; tb = FALLBACK.text[2];
        br = FALLBACK.bg[0]; bg = FALLBACK.bg[1]; bb = FALLBACK.bg[2];
        bgA = FALLBACK.bg_a;
        maxA = FALLBACK.alpha;
        iconTintWritten = 0;
    }
    if ( iconTintWritten != 1 ) {
        ir = ar; ig = ag; ib = ab;
    }
    if ( bgA < 0 ) bgA = 0; if ( bgA > 255 ) bgA = 255;
    if ( maxA < 0 ) maxA = 0; if ( maxA > 255 ) maxA = 255;
    if ( userScale < 0.1 ) userScale = 0.1;
    if ( userScale > 5.0 ) userScale = 5.0;
    if ( animSec < 0.0 ) animSec = 0.0;

    local scale = ( ScreenHeight() / 768.0 ) * userScale;
    local iconW = iconW0 * scale;
    local iconH = iconH0 * scale;
    local yOff = screenY * scale;
    local cy = sp.y + yOff;

    local alpha = maxA;
    local fade = 0.25;
    if ( now - t0 < fade )
        alpha = ( maxA.tofloat() * ( ( now - t0 ) / fade ) ).tointeger();
    else if ( t1 - now < fade )
        alpha = ( maxA.tofloat() * ( ( t1 - now ) / fade ) ).tointeger();
    if ( alpha < 0 ) alpha = 0;
    if ( alpha > 255 ) alpha = 255;

    local pad = 4.0 * scale;
    local textGap = 6.0 * scale;

    if ( achMode ) {
        _paintAchievement( sp, stack, iconPath, nick, title, screenX, gapX, iconW, iconH, scale, cy, alpha, pad, ar, ag, ab, tr, tg, tb, br, bg, bb, bgA, ir, ig, ib );
        return;
    }

    local shown = _spinValue( fromV, toV, t0, now, animSec );
    local label = shown.tostring();
    // Конечное число, не текущий кадр накрутки: иначе плашка меняет ширину всю анимацию.
    local labelFinal = toV.tostring();
    local textH = 0.0;
    local nickW = 0.0;
    local numFinalW = 0.0;
    if ( FONT != null && FONT != -1 ) {
        textH = self.GetFontTall( FONT ).tofloat();
        numFinalW = self.GetTextWide( FONT, labelFinal ).tofloat();
        if ( nick != "" )
            nickW = self.GetTextWide( FONT, nick ).tofloat();
    }

    local tex = _textureFor( iconPath );
    local hasIcon = ( tex != null && tex != -1 && iconPath != null && iconPath != "" );

    local rowW = pad + numFinalW + pad;
    if ( hasIcon )
        rowW = pad + iconW + textGap + numFinalW + pad;
    local panelW = nickW;
    if ( rowW > panelW )
        panelW = rowW;

    local marineId = self.GetInt( 19 );
    local lane = self.GetInt( 20 );
    local gapMin = gapX * scale;
    local edge = 4.0 * scale;
    _layoutPublish( marineId, lane, stack, panelW );
    local shift = stack.tofloat() * gapMin;
    if ( marineId > 0 && lane > 0 && stack > 0 )
        shift = _stackShift( marineId, lane, stack, panelW, gapMin, edge );
    // Оружие слева: шаг ещё левее. Тимкилл справа: шаг ещё правее.
    local cx = sp.x + ( screenX * scale );
    if ( screenX < 0.0 )
        cx = cx - shift;
    else
        cx = cx + shift;

    local contentH = iconH;
    if ( textH > contentH )
        contentH = textH;
    if ( !hasIcon )
        contentH = textH;
    local halfW = panelW * 0.5;
    local halfH = contentH * 0.5 + pad;

    local panelA = ( bgA.tofloat() * ( alpha.tofloat() / 255.0 ) ).tointeger();
    self.PaintRectangle(
        cx - halfW, cy - halfH,
        cx + halfW, cy + halfH,
        br, bg, bb, panelA
    );
    self.PaintRectangle(
        cx - halfW, cy - halfH,
        cx + halfW, cy - halfH + 2.0 * scale,
        ar, ag, ab, ( alpha * 0.9 ).tointeger()
    );

    local panelLeft = cx - halfW;
    local panelRight = cx + halfW;
    // Иконка своего размера. Слева и справа панели один и тот же отступ.
    // Между иконкой и числом — textGap. Число по центру оставшегося места.
    local iconX = panelLeft + pad;
    if ( hasIcon ) {
        local iconTop = cy - iconH * 0.5;
        self.PaintTexturedRectangle(
            iconX, iconTop,
            iconX + iconW, iconTop + iconH,
            ir, ig, ib, alpha,
            tex
        );
    }

    if ( FONT != null && FONT != -1 ) {
        local numLeft = panelLeft + pad;
        if ( hasIcon )
            numLeft = iconX + iconW + textGap;
        local numRight = panelRight - pad;
        local numSpace = numRight - numLeft;
        local ty = cy - textH * 0.5;
        local twNow = self.GetTextWide( FONT, label ).tofloat();
        local tx = numLeft;
        if ( numSpace > twNow )
            tx = numLeft + ( numSpace - twNow ) * 0.5;
        self.PaintText( tx - 1, ty,     0, 0, 0, alpha, FONT, label );
        self.PaintText( tx + 1, ty,     0, 0, 0, alpha, FONT, label );
        self.PaintText( tx,     ty - 1, 0, 0, 0, alpha, FONT, label );
        self.PaintText( tx,     ty + 1, 0, 0, 0, alpha, FONT, label );
        self.PaintText( tx, ty, tr, tg, tb, alpha, FONT, label );
    }

    // Ник над полоской, от левого края, целиком.
    if ( nick != "" && FONT != null && FONT != -1 && textH > 0.0 ) {
        local nx = panelLeft;
        local ny = ( cy - halfH ) - textH - ( 2.0 * scale );
        self.PaintText( nx - 1, ny,     0, 0, 0, alpha, FONT, nick );
        self.PaintText( nx + 1, ny,     0, 0, 0, alpha, FONT, nick );
        self.PaintText( nx,     ny - 1, 0, 0, 0, alpha, FONT, nick );
        self.PaintText( nx,     ny + 1, 0, 0, 0, alpha, FONT, nick );
        self.PaintText( nx, ny, ar, ag, ab, alpha, FONT, nick );
    }
}
