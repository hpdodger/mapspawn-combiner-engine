// Серия как у голоса monster kill в обычной игре: 4-е убийство морпеха.
// Пауза — rd_killingspree_time_limit. Длину считает модуль (OnMarineSpree).

AchRegister( {
    id    = "bloodbath",
    title = {
        ru = "Кровавая баня",
        en = "Bloodbath",
    },
    desc  = {
        ru = "Убей четырёх морпехов одной серией.",
        en = "Kill four marines in one streak.",
    },
    icon  = "vgui/achievements/bloodbath",
    OnMarineSpree = function( ctx, length ) {
        if ( length >= 4 )
            ctx.Unlock( "bloodbath" );
    },
} );
