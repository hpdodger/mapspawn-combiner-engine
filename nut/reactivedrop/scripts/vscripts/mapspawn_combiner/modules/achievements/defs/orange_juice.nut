// Убить inhabited-игрока Orange.

AchRegister( {
    id    = "orange_juice",
    title = {
        ru = "Апельсиновый сок",
        en = "Orange Juice",
    },
    desc  = {
        ru = "Убей игрока Orange.",
        en = "Kill the player Orange.",
    },
    icon  = "vgui/achievements/orange_juice",
    OnMarineKilled = function( ctx, killer, victim, kKey, vKey ) {
        if ( !ctx.IsOrange( vKey ) )
            return;
        if ( ctx.IsOrange( kKey ) )
            return;
        ctx.Unlock( "orange_juice" );
    },
} );
