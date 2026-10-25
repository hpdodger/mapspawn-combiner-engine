// mapspawn_combiner/modules/weapon_kills/tracks.nut
// Таблица треков: несколько classname оружия могут делить один id / иконку / счётчик.
// icon уходит на клиент через rd_hud_vscript SetString(0) — клиентский список треков не нужен.
//
// kind: "kill" (по умолчанию, можно не писать) или "heal".
// Убийства: OnTakeDamage_Alive_Any, held weapon.
// Лечение: OnGameEvent_marine_healed, classname из weapon_class
//   (у маяка это снаряд asw_healgrenade_projectile).
// Один classname может быть в kill-треке и отдельно в heal-треке
// (medrifle / medrifle_heal) — индексы раздельные.
//
// Не считаем убийствами: турели (sentry*), мины, тесла-трап,
// аптечку (medkit), сварку, аммо, метательные гранаты и прочий offhand.

::WkcTracks <- [
    // --- primary / unlockable ---
    {
        id      = "rifle",
        weapons = [ "asw_weapon_rifle" ],
        icon    = "vgui/swarm/EquipIcons/EquipRifle",
        label   = { ru = "Винтовка", en = "Rifle" },
    },
    {
        id      = "prifle",
        weapons = [ "asw_weapon_prifle" ],
        icon    = "vgui/swarm/EquipIcons/EquipPRifle",
        label   = { ru = "Прото-винтовка", en = "Prototype Rifle" },
    },
    {
        id      = "autogun",
        weapons = [ "asw_weapon_autogun" ],
        icon    = "vgui/swarm/EquipIcons/EquipAutogun",
        label   = { ru = "Автопушка", en = "Autogun" },
    },
    {
        id      = "vindicator",
        weapons = [ "asw_weapon_vindicator" ],
        icon    = "vgui/swarm/EquipIcons/EquipShotgunAssault",
        label   = { ru = "Виндикатор", en = "Vindicator" },
    },
    {
        id      = "pistol",
        weapons = [ "asw_weapon_pistol" ],
        icon    = "vgui/swarm/EquipIcons/EquipPistol",
        label   = { ru = "Пистолеты", en = "Pistols" },
    },
    {
        id      = "shotgun",
        weapons = [ "asw_weapon_shotgun" ],
        icon    = "vgui/swarm/EquipIcons/EquipShotgun",
        label   = { ru = "Дробовик", en = "Shotgun" },
    },
    {
        id      = "tesla",
        weapons = [ "asw_weapon_tesla_gun" ],
        icon    = "vgui/swarm/EquipIcons/EquipTeslaGun",
        label   = { ru = "Тесла", en = "Tesla Gun" },
    },
    {
        id      = "railgun",
        weapons = [ "asw_weapon_railgun" ],
        icon    = "vgui/swarm/EquipIcons/EquipRailgun",
        label   = { ru = "Рельса", en = "Railgun" },
    },
    {
        id      = "pdw",
        weapons = [ "asw_weapon_pdw" ],
        icon    = "vgui/swarm/EquipIcons/EquipPDW",
        label   = { ru = "PDW", en = "PDW" },
    },
    {
        id      = "flamer",
        weapons = [ "asw_weapon_flamer" ],
        icon    = "vgui/swarm/EquipIcons/EquipFlamer",
        label   = { ru = "Огнемёт", en = "Flamer" },
    },
    {
        id      = "minigun",
        weapons = [ "asw_weapon_minigun" ],
        icon    = "vgui/swarm/EquipIcons/EquipMiniGun",
        label   = { ru = "Миниган", en = "Minigun" },
    },
    {
        id      = "sniper",
        weapons = [ "asw_weapon_sniper_rifle" ],
        icon    = "vgui/swarm/EquipIcons/EquipSniperRifle",
        label   = { ru = "Снайперка", en = "Sniper" },
    },
    {
        // id "saw" — уже мог быть в save у игроков с фазы 1
        id      = "saw",
        weapons = [ "asw_weapon_chainsaw" ],
        icon    = "vgui/swarm/EquipIcons/EquipChainsaw",
        label   = { ru = "Пила", en = "Chainsaw" },
    },
    {
        id      = "gl",
        weapons = [ "asw_weapon_grenade_launcher" ],
        icon    = "vgui/swarm/EquipIcons/EquipGrenadeLauncher",
        label   = { ru = "Гранатомёт", en = "Grenade Launcher" },
    },
    {
        id      = "deagle",
        weapons = [ "asw_weapon_deagle" ],
        icon    = "vgui/swarm/EquipIcons/EquipDeagle",
        label   = { ru = "Deagle", en = "Deagle" },
    },
    {
        id      = "devastator",
        weapons = [ "asw_weapon_devastator" ],
        icon    = "vgui/swarm/EquipIcons/EquipDevastator",
        label   = { ru = "Devastator", en = "Devastator" },
    },
    {
        id      = "combat_rifle",
        weapons = [ "asw_weapon_combat_rifle" ],
        icon    = "vgui/swarm/EquipIcons/EquipCombatRifle",
        label   = { ru = "Combat Rifle", en = "Combat Rifle" },
    },
    {
        id      = "heavy_rifle",
        weapons = [ "asw_weapon_heavy_rifle" ],
        icon    = "vgui/swarm/EquipIcons/EquipHeavyRifle",
        label   = { ru = "Тяжёлая винтовка", en = "Heavy Rifle" },
    },
    {
        id      = "medrifle",
        weapons = [ "asw_weapon_medrifle" ],
        icon    = "vgui/swarm/EquipIcons/EquipMedRifle",
        label   = { ru = "Med Rifle", en = "Med Rifle" },
    },

    // --- hidden / item / 7A combat ---
    {
        id      = "mining_laser",
        weapons = [ "asw_weapon_mining_laser" ],
        icon    = "vgui/swarm/EquipIcons/EquipMiningLaser",
        label   = { ru = "Майнинг-лазер", en = "Mining Laser" },
    },
    {
        id      = "50cal",
        weapons = [ "asw_weapon_50calmg" ],
        icon    = "vgui/swarm/EquipIcons/Equip50calmg",
        label   = { ru = "50cal", en = "50cal" },
    },
    {
        id      = "flechette",
        weapons = [ "asw_weapon_flechette2", "asw_weapon_flechette" ],
        icon    = "vgui/swarm/EquipIcons/EquipFlechette",
        label   = { ru = "Флешетты", en = "Flechette" },
    },
    {
        id      = "ricochet",
        weapons = [ "asw_weapon_ricochet" ],
        icon    = "vgui/swarm/EquipIcons/EquipRicochet",
        label   = { ru = "Рикошет", en = "Ricochet" },
    },
    {
        id      = "ar2",
        weapons = [ "asw_weapon_ar2" ],
        icon    = "vgui/swarm/EquipIcons/EquipAR2",
        label   = { ru = "AR2", en = "AR2" },
    },
    {
        id      = "cryo",
        weapons = [ "asw_weapon_cryo_cannon" ],
        icon    = "vgui/swarm/EquipIcons/EquipCryoCannon",
        label   = { ru = "Криопушка", en = "Cryo Cannon" },
    },
    {
        id      = "plasma",
        weapons = [ "asw_weapon_plasma_thrower" ],
        icon    = "vgui/swarm/EquipIcons/EquipPlasma",
        label   = { ru = "Плазма", en = "Plasma Thrower" },
    },
    {
        id      = "energy_shield",
        weapons = [ "asw_weapon_energy_shield" ],
        icon    = "vgui/swarm/EquipIcons/EquipShieldRifle",
        label   = { ru = "Shield Rifle", en = "Energy Shield" },
    },

    // --- extra melee that can kill ---
    {
        id      = "powerfist",
        weapons = [ "asw_weapon_powerfist" ],
        // в equipment list: EquipPowerFist
        icon    = "vgui/swarm/EquipIcons/EquipPowerFist",
        label   = { ru = "Кастет", en = "Power Fist" },
    },

    // --- healing (queued HP via marine_healed; separate save keys) ---
    {
        id      = "heal_gun",
        kind    = "heal",
        weapons = [ "asw_weapon_heal_gun" ],
        icon    = "vgui/weapon_kills/heal_icon",
        label   = { ru = "Лечебная пушка", en = "Heal Gun" },
    },
    {
        id      = "healamp",
        kind    = "heal",
        weapons = [ "asw_weapon_healamp_gun" ],
        icon    = "vgui/weapon_kills/heal_icon",
        label   = { ru = "Лечебно-усиливающая пушка", en = "Heal Amp" },
    },
    {
        id      = "medrifle_heal",
        kind    = "heal",
        weapons = [ "asw_weapon_medrifle" ],
        icon    = "vgui/weapon_kills/heal_icon",
        label   = { ru = "Медицинский ПП (лечение)", en = "Med Rifle (heal)" },
    },
    {
        id      = "satchel",
        kind    = "heal",
        weapons = [ "asw_weapon_medical_satchel" ],
        icon    = "vgui/weapon_kills/heal_icon",
        label   = { ru = "Ящик медикаментов", en = "Medical Satchel" },
    },
    {
        id      = "beacon",
        kind    = "heal",
        weapons = [ "asw_healgrenade_projectile", "asw_weapon_heal_grenade" ],
        icon    = "vgui/weapon_kills/heal_icon",
        label   = { ru = "Целительный маячок", en = "Heal Beacon" },
    },
];

// classname → индекс в ::WkcTracks. Kill и heal раздельно:
// asw_weapon_medrifle есть и в medrifle, и в medrifle_heal.
::WkcWeaponIndex <- {};
::WkcHealWeaponIndex <- {};
