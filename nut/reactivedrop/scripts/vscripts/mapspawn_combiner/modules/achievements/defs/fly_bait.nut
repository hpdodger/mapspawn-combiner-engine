// «Приманка для мух»: добивающий удар, от которого умер морпех, нанёс баззер.
// Открывается игроку этого морпеха.

AchRegister( {
    id    = "fly_bait",
    title = {
        ru = "Приманка для мух",
        en = "Fly Bait",
    },
    desc  = {
        ru = "Умри от добивающего удара баззера.",
        en = "Die to a buzzer's killing blow.",
    },
    icon  = "vgui/achievements/fly_bait",
    OnMarineDied = function( ctx, victim, vKey, attacker, inflictor ) {
        local ent = null;
        if ( attacker != null && attacker.IsValid() && attacker.GetClassname() == "asw_buzzer" )
            ent = attacker;
        else if ( inflictor != null && inflictor.IsValid() && inflictor.GetClassname() == "asw_buzzer" )
            ent = inflictor;
        if ( ent == null )
            return;
        ctx.Unlock( "fly_bait" );
    },
} );
