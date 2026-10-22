// weapon_kills/wkc_popup_hud.nut — клиентский Paint для tier-up popup.
// Вешается на rd_hud_vscript (client_vscript). Видят все, у кого есть этот файл.
//
// Иконка приходит с сервера в String 0 (путь EquipIcon) — клиентский список треков не нужен.
// Новые оружия = правка только серверного tracks.nut, Workshop-stub можно не обновлять.
//
// Слоты (сервер пишет из !am_set / variables, клиент читает):
//   Entity 0 — asw_marine (якорь)
//   String 0 — путь иконки (vgui/swarm/EquipIcons/…)
//   Int 0    — старт накрутки числа
//   Int 1    — конец накрутки / порог тира
//   Int 2    — индекс стека (дальше = левее)
//   Int 3..5 — accent RGB (полоска + tint иконки)
//   Int 6..8 — text RGB
//   Int 9..11 — bg RGB
//   Int 12   — bg alpha 0..255
//   Int 13   — content max alpha 0..255
//   Int 14   — 1 = сервер записал стиль (иначе fallback)
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
    if ( toV < 1 )
        return;
    if ( fromV < 0 )
        fromV = 0;

    local sp = self.ClientGetEntityScreenPos( hMarine, true );
    if ( !sp )
        return;

    _ensureFont();

    local iconPath = self.GetString( 0 );
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
    }
    if ( bgA < 0 ) bgA = 0; if ( bgA > 255 ) bgA = 255;
    if ( maxA < 0 ) maxA = 0; if ( maxA > 255 ) maxA = 255;
    if ( userScale < 0.1 ) userScale = 0.1;
    if ( userScale > 5.0 ) userScale = 5.0;
    if ( animSec < 0.0 ) animSec = 0.0;

    local shown = _spinValue( fromV, toV, t0, now, animSec );

    local scale = ( ScreenHeight() / 768.0 ) * userScale;
    local iconW = iconW0 * scale;
    local iconH = iconH0 * scale;
    local xOff = ( screenX * scale ) - ( stack * gapX * scale );
    local yOff = screenY * scale;

    local cx = sp.x + xOff;
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
    // Ширину панели считаем по конечному числу, чтобы не дёргалась при накрутке
    local labelFinal = toV.tostring();
    local label = shown.tostring();
    local textW = 0.0;
    local textH = 0.0;
    if ( FONT != null && FONT != -1 ) {
        textW = self.GetTextWide( FONT, labelFinal ).tofloat();
        textH = self.GetFontTall( FONT ).tofloat();
    }

    local tex = _textureFor( iconPath );
    local hasIcon = ( tex != null && tex != -1 && iconPath != null && iconPath != "" );

    local contentW = textW;
    if ( hasIcon )
        contentW = iconW + textGap + textW;
    local contentH = iconH;
    if ( textH > contentH )
        contentH = textH;
    if ( !hasIcon )
        contentH = textH;
    local halfW = contentW * 0.5 + pad;
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

    local cursor = cx - halfW + pad;
    if ( hasIcon ) {
        local iconTop = cy - iconH * 0.5;
        self.PaintTexturedRectangle(
            cursor, iconTop,
            cursor + iconW, iconTop + iconH,
            ar, ag, ab, alpha,
            tex
        );
        cursor += iconW + textGap;
    }

    if ( FONT != null && FONT != -1 ) {
        local ty = cy - textH * 0.5;
        // Число рисуем в правой части слота конечной ширины (выравнивание вправо к краю текста)
        local twNow = self.GetTextWide( FONT, label ).tofloat();
        local tx = cursor + ( textW - twNow );
        self.PaintText( tx - 1, ty,     0, 0, 0, alpha, FONT, label );
        self.PaintText( tx + 1, ty,     0, 0, 0, alpha, FONT, label );
        self.PaintText( tx,     ty - 1, 0, 0, 0, alpha, FONT, label );
        self.PaintText( tx,     ty + 1, 0, 0, 0, alpha, FONT, label );
        self.PaintText( tx, ty, tr, tg, tb, alpha, FONT, label );
    }
}
