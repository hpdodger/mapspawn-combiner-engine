// Orange убивает игрока, у которого уже есть orange_juice.

AchRegister( {
    id    = "fruits_revenge",
    title = {
        ru = "Месть фруктов",
        en = "Fruits Revenge",
    },
    desc  = {
        ru = "Будучи Orange, убей игрока с достижением «Апельсиновый сок».",
        en = "As Orange, kill a player who already has Orange Juice.",
    },
    icon  = "vgui/achievements/fruits_revenge",
    OnMarineKilled = function( ctx, killer, victim, kKey, vKey ) {
        if ( !ctx.IsOrange( kKey ) )
            return;
        if ( !ctx.Has( vKey, "orange_juice" ) )
            return;
        ctx.Unlock( "fruits_revenge" );
    },
} );
