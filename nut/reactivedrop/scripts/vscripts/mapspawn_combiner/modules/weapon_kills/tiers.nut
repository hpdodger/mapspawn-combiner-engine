// mapspawn_combiner/modules/weapon_kills/tiers.nut
// Пороги popup / chat_notify при tier-up.
// Править этот файл, чтобы сменить сетку порогов.
//
// FIXED — явные пороги по порядку.
// STEP  — после последнего FIXED дальше каждые STEP (убийства: 500, 1000…;
//         лечение: 1000, 2000…).

::WkcFixedTiers <- [ 1, 5, 10, 50, 100 ];
::WkcStepTier   <- 500;

::WkcHealFixedTiers <- [ 50, 100, 500 ];
::WkcHealStepTier   <- 1000;
