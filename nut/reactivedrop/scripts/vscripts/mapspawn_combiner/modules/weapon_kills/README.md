# weapon_kills

Счётчик убийств пришельцев по трекам оружия и лечения медиком в духе strange
device: у каждого оружия свой накопительный счёт, при достижении порога над
морпехом на короткое время показывается иконка и число порога. Убийства —
EquipIcon, лечение — крест эмоции медика.

Публичное имя stub-челленджа: **Stat Tracks HUD**. Внутренние id без изменений:
модуль `weapon_kills`, чат `!wkc`.

Логика и сохранение — always-on модуль mapspawn combiner. Картинка на экране —
отдельный клиентский Paint-скрипт, который клиенты получают через stub-челлендж
`weapon_kills` (`required_on_client 1`). Без stub на клиенте подсчёт и `!wkc`
работают, popup не рисуется.

Имя в реестре: `weapon_kills`. Версия — в `module_weapon_kills.nut`.
Тег в чате: `[WK]`.

Язык интерфейса — общий для combiner: `!mc_lang en|ru` (модуль `lang`,
хранение `save/vscripts/mc_lang/`). По умолчанию **en**. То же значение
подхватывают TK (`!tkc_lang` пишет в тот же `McI18n`).

Выключить: `!am_disable weapon_kills`.
Настройки: `!am_vars weapon_kills` / `!am_set weapon_kills …`
(менять и сохранять может admin из `admins.nut`).

## Файлы

```
modules/weapon_kills/
  module_weapon_kills.nut   — модуль (хуки, чат, persist, спавн HUD)
  tracks.nut                — таблица треков (id, kind, classname, icon, подписи)
  tiers.nut                 — пороги popup (kill / heal сетки)
  README.md

# клиентский stub (рядом в nut/reactivedrop/)
resource/challenges/weapon_kills.txt
scripts/vscripts/challenge_weapon_kills.nut   — пустой
scripts/vscripts/weapon_kills/wkc_popup_hud.nut
scripts/vscripts/tk_counter/tkc_popup_hud.nut — попап тимкилла (модуль tk_counter)
materials/vgui/tk_counter/dead_icon.vmt + .vtf
materials/vgui/weapon_kills/heal_icon.vmt + .vtf
```

Новый трек оружия = правка только `tracks.nut` на сервере. Stub трогать не нужно,
пока не меняется сам Paint и не добавляется новая текстура. Иконки убийств —
штатные `vgui/swarm/EquipIcons/…` из игры. Крест лечения едет в stub:
`vgui/weapon_kills/heal_icon` (копия эмоции медика `EmoteMedic`).

## Как считает

### Убийства

Хук `OnTakeDamage_Alive_Any` (урон не меняется):

- attacker — inhabited `asw_marine`
- victim — `IsAlien()`
- `weapon` — classname есть в kill-треке `tracks.nut`
- удар смертельный: `damage >= victim.GetHealth()`
- убийство записывается командиру морпеха (`GetCommander()`), ключ — `McAuth.PlayerKey`

Не считаются (намеренно): турели (`sentry*`), мины, тесла-трап, аптечка
(`medkit`), аммо, сварка и прочий саппорт, метательные гранаты и прочий
deployable offhand. Считается только оружие в руках, которое пришло в
параметре `weapon`.

### Лечение

Событие `marine_healed` (поле `amount_healed` — HP, поставленные в очередь
`AddSlowHeal`). Поле `amount` — кредит медали/strange: очередь минус
оставшийся дружественный огонь; после «подстрелил своего → полечил»
там часто 0, его не используем как основной счёт:

- `weapon_class` есть в heal-треке (`heal_gun`, `healamp` только поток лечения,
  `medrifle_heal`, `satchel`, `beacon`)
- аптечка (`asw_weapon_medkit`) не считается
- самолечение считается
- Med Rifle: убийства пишутся в `medrifle=`, HP — в `medrifle_heal=` (не смешивать)
- маяк: `weapon_class` обычно `asw_healgrenade_projectile`; после смерти медика
  атрибуция через `GetCommander()` / `McAuth.PlayerKey`, inhabited не требуется
- скриптовый/карточный маяк без владельца (`medic_entindex < 0` или пустой
  `weapon_class`) пропускается
- `player_heal` не используется

Ящик медикаментов — один большой сброс в очередь на одного рядом. Маяк —
много мелких тиков по зоне, отдельные счётчики.

### Пороги (тиры)

Правка только `tiers.nut`.

Убийства (`::WkcFixedTiers`, `::WkcStepTier`): `1`, `5`, `10`, `50`, `100`,
дальше каждые `500`.

Лечение (`::WkcHealFixedTiers`, `::WkcHealStepTier`): `50`, `100`, `500`,
дальше каждые `1000`.

На popup показывается **порог**, не сырой счётчик. Число коротко накручивается
от предыдущего порога к новому (`popup_anim_time`). В чат по умолчанию ничего
не пишется (`chat_notify 0`); в лог сервера строка tier-up всё равно уходит.

## Команды

| Команда | Кто | Действие |
|---|---|---|
| `!wkc` | все | свои счётчики убийств, затем блок лечения, и следующий порог |
| `!wkc_help` | все | справка |
| `!wkc_reset` | admin | обнулить **свои** сохранённые треки |
| `!wkc_test <id\|classname>` | admin | тестовый popup: накрутка 0→127 |
| `!mc_lang [en\|ru]` | все | общий язык модулей combiner |

Примеры теста иконки:

```
!wkc_test rifle
!wkc_test asw_weapon_deagle
!wkc_test deagle
!wkc_test heal_gun
!wkc_test beacon
!wkc_test satchel
!wkc_test medrifle_heal
```

Без аргумента или при неизвестном имени — usage и список id треков.
Права admin проверяются **при выполнении** команды.

Вкл/выкл модуля: `!am_enable` / `!am_disable weapon_kills`.

При входе одна общая строка от admin: `[MC] !am_help — module list and commands`
(отдельный tip у weapon_kills выключен).

## Переменные

`!am_vars weapon_kills` / `!am_set weapon_kills <var> <value>` / `!am_save`:

| Переменная | По умолчанию | Смысл |
|---|---|---|
| `chat_notify` | `0` | писать tier-up в общий чат (`1`) или только popup (`0`) |
| `popup` | `1` | спавнить world-popup |
| `popup_lifetime` | `3.5` | сколько секунд виден popup |
| `popup_delay` | `0.4` | задержка перед появлением |
| `popup_anim_time` | `0.75` | секунды накрутки числа (`0` — сразу конечное) |
| `popup_x` | `-120` | смещение X, px @768p (левее головы / strange) |
| `popup_y` | `-20` | смещение Y, px @768p (выше головы = отрицательное) |
| `popup_stack_gap` | `72` | шаг стека влево при нескольких popup |
| `popup_icon_w` / `popup_icon_h` | `56` / `28` | размер EquipIcon убийств (2:1). Крест лечения всегда 32×32 |
| `popup_scale` | `1.0` | множитель размера (иконка, отступы, gap) |
| `popup_accent` | `80 180 255` | RGB полоски и tint иконки |
| `popup_text` | `255 0 0` | RGB числа |
| `popup_bg` | `8 14 28` | RGB фона |
| `popup_bg_alpha` | `225` | альфа фона 0–255 |
| `popup_alpha` | `230` | альфа иконки/текста 0–255 |

Цвета — строка `R G B` (кавычки в чате не нужны):

```
!am_set weapon_kills popup_x -150
!am_set weapon_kills popup_accent 80 180 255
!am_set weapon_kills popup_scale 1.2
!am_save
```

## Сохранение

Каталог `save/vscripts/weapon_kills/`:

- `index.txt` — список account id
- `<accountId>.txt` — строка `#name=…` и пары `trackId=count`

Ключ игрока как у TK: `STEAM_X:Y:Z` → `Z*2+Y` через `McAuth.PlayerKey`.
Кэш в памяти модуля. Убийства пишутся на диск сразу. Лечение помечается
грязным и сбрасывается раз в ~1.5 с из `Update`, плюс на `Cleanup` /
выключении модуля (иначе хилган колотит `StringToFile` на каждый тик очереди).

## Popup / слоты HUD

На tier-up сервер создаёт `rd_hud_vscript` с
`client_vscript = weapon_kills/wkc_popup_hud.nut`.

Popup висит в той же высотной зоне, что vanilla strange (над головой), но
сдвинут **влево** по X, стек тоже растёт влево — чтобы колонки не наезжали.
Палитра холодная (не оранжевый strange).

| Слот | Значение |
|---|---|
| Entity 0 | `asw_marine` (якорь) |
| String 0 | путь иконки (EquipIcon или `vgui/weapon_kills/heal_icon`) |
| Int 0 / 1 / 2 | старт накрутки / порог / индекс стека |
| Int 3..5 | accent RGB (полоска) |
| Int 6..8 | text RGB |
| Int 9..11 | bg RGB |
| Int 12 / 13 / 14 | bg alpha / content alpha / style marker (`1`) |
| Int 15..17 / 18 | tint иконки / маркер (`1`); лечение: белый, без cyan |
| Float 0 / 1 | Time() начала / конца показа |
| Float 2..8 | x, y, stack_gap, icon_w, icon_h, scale, anim_time |

На dedicated: опубликовать stub как Workshop item, `rd_enable_workshop_item`,
у клиентов `rd_workshop_temp_subscribe 3`. Локально достаточно скопировать
`resource/challenges/weapon_kills.txt`, `scripts/vscripts/weapon_kills/`
и `scripts/vscripts/tk_counter/tkc_popup_hud.nut`
(+ пустой `challenge_weapon_kills.nut`) в дерево игры.
Челлендж один: оба Paint-скрипта едут в этом дополнении.

## Треки

Таблица в `tracks.nut`. Несколько classname могут делить один id (пример: flechette).

| id | Classname | Подпись |
|---|---|---|
| `rifle` | `asw_weapon_rifle` | Винтовка |
| `prifle` | `asw_weapon_prifle` | Прото-винтовка |
| `autogun` | `asw_weapon_autogun` | Автопушка |
| `vindicator` | `asw_weapon_vindicator` | Виндикатор |
| `pistol` | `asw_weapon_pistol` | Пистолеты |
| `shotgun` | `asw_weapon_shotgun` | Дробовик |
| `tesla` | `asw_weapon_tesla_gun` | Тесла |
| `railgun` | `asw_weapon_railgun` | Рельса |
| `pdw` | `asw_weapon_pdw` | PDW |
| `flamer` | `asw_weapon_flamer` | Огнемёт |
| `minigun` | `asw_weapon_minigun` | Миниган |
| `sniper` | `asw_weapon_sniper_rifle` | Снайперка |
| `saw` | `asw_weapon_chainsaw` | Пила |
| `gl` | `asw_weapon_grenade_launcher` | Гранатомёт |
| `deagle` | `asw_weapon_deagle` | Deagle |
| `devastator` | `asw_weapon_devastator` | Devastator |
| `combat_rifle` | `asw_weapon_combat_rifle` | Combat Rifle |
| `heavy_rifle` | `asw_weapon_heavy_rifle` | Тяжёлая винтовка |
| `medrifle` | `asw_weapon_medrifle` | Med Rifle |
| `mining_laser` | `asw_weapon_mining_laser` | Майнинг-лазер |
| `50cal` | `asw_weapon_50calmg` | 50cal |
| `flechette` | `asw_weapon_flechette2`, `asw_weapon_flechette` | Флешетты |
| `ricochet` | `asw_weapon_ricochet` | Рикошет |
| `ar2` | `asw_weapon_ar2` | AR2 |
| `cryo` | `asw_weapon_cryo_cannon` | Криопушка |
| `plasma` | `asw_weapon_plasma_thrower` | Плазма |
| `energy_shield` | `asw_weapon_energy_shield` | Shield Rifle |
| `powerfist` | `asw_weapon_powerfist` | Кастет |

Лечение (`kind = "heal"`, иконка `vgui/weapon_kills/heal_icon`):

| id | Classname | Подпись |
|---|---|---|
| `heal_gun` | `asw_weapon_heal_gun` | Лечебная пушка |
| `healamp` | `asw_weapon_healamp_gun` | Лечебно-усиливающая пушка (только поток лечения) |
| `medrifle_heal` | `asw_weapon_medrifle` | Медицинский ПП (лечение) |
| `satchel` | `asw_weapon_medical_satchel` | Ящик медикаментов |
| `beacon` | `asw_healgrenade_projectile`, `asw_weapon_heal_grenade` | Целительный маячок |

Id `saw` оставлен с ранней версии — чтобы не сбросить уже накопленные save.
Ключ `medrifle` — только убийства; HP этого оружия в `medrifle_heal`.
