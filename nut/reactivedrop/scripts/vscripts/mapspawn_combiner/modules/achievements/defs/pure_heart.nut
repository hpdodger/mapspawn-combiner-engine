// «От чистого сердца»: паразит убил тебя, затем этот же или вышедший из тебя
// убивает другого игрока. Открывается дарителю (первая жертва).

AchRegister( {
    id    = "pure_heart",
    title = {
        ru = "От чистого сердца",
        en = "From the Heart",
    },
    desc  = {
        ru = "Паразит, который тебя убил или вышел из тебя, убивает другого игрока.",
        en = "A parasite that killed you or came from you kills another player.",
    },
    icon  = "vgui/achievements/pure_heart",
    OnParasiteGift = function( ctx, giverKey, victimKey ) {
        ctx.Unlock( "pure_heart" );
    },
} );
