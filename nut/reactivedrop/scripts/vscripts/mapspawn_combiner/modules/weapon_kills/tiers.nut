// mapspawn_combiner/modules/weapon_kills/tiers.nut
// Пороги popup / chat_notify при tier-up.
// Править этот файл, чтобы сменить сетку порогов.
//
// FIXED — явные пороги по порядку.
// STEP  — после последнего FIXED дальше каждые STEP убийств (500, 1000, 1500…).

::WkcFixedTiers <- [ 1, 5, 10, 50, 100 ];
::WkcStepTier   <- 500;
