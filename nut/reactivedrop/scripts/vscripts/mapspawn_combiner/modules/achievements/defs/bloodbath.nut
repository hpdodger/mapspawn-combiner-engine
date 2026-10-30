// Четыре inhabited-игрока за короткий залп (граната, взрыв и т.п.).

AchRegister( {
    id    = "bloodbath",
    title = {
        ru = "Кровавая баня",
        en = "Bloodbath",
    },
    desc  = {
        ru = "Убей четырёх игроков одним залпом.",
        en = "Kill four players in one burst.",
    },
    icon  = "vgui/achievements/bloodbath",
    OnMarineKilled = function( ctx, killer, victim, kKey, vKey ) {
        if ( ctx.RecentMarineKills( 2.0 ) >= 4 )
            ctx.Unlock( "bloodbath" );
    },
} );
