# achievements

Свои достижения (не Steam UserStats): сейв на аккаунт, чат `!ach`, попап справа
ниже плашки тимкилла. Наблюдатель: урон и спавны не меняет.

Имя в реестре: `achievements`. Версия — в `module_achievements.nut` (`0.1.3`).
Тег в чате: `[ACH]`. Язык — общий combiner: `!mc_lang en|ru`.

Выключить: `!am_disable achievements`.
Настройки: `!am_vars achievements` / `!am_set achievements …`.

Новое достижение = файл в `defs/` + строка `IncludeScript` в
`module_achievements.nut`. Ядро не трогаем.

## Файлы

```
modules/achievements/
  module_achievements.nut   — реестр, сейв, чат, попап, хук entity_killed
  ids.nut                   — SteamID цели Orange (локальная таблица модуля, не корень)
  defs/orange_juice.nut
  defs/fruits_revenge.nut
  defs/bloodbath.nut
  defs/pure_heart.nut
  README.md
```

Клиентский Paint — тот же stub `weapon_kills`:

```
scripts/vscripts/weapon_kills/wkc_popup_hud.nut
materials/vgui/achievements/orange_juice.vmt + .vtf
materials/vgui/achievements/fruits_revenge.vmt + .vtf
materials/vgui/achievements/bloodbath.vmt + .vtf
materials/vgui/achievements/pure_heart.vmt + .vtf
```

Без stub на клиенте счёт и `!ach` работают, попап не рисуется.

## Определение

```squirrel
AchRegister( {
    id    = "orange_juice",
    title = { ru = "Апельсиновый сок", en = "Orange Juice" },
    desc  = { ru = "Убей игрока Orange.", en = "Kill the player Orange." },
    icon  = "vgui/achievements/orange_juice",
    OnMarineKilled = function( ctx, killer, victim, kKey, vKey ) {
        // ctx.Unlock / ctx.Has / ctx.IsUnlocked / ctx.AddProgress
    },
} );
```

`id` не переводится. `title` / `desc` — таблицы языков, показ через `McI18n.Label`.
`icon` — путь материала без `materials/` и без `.vmt`.

Ключ игрока — `McAuth.PlayerKey` (32-bit account id). Сейв:
`save/vscripts/achievements/<accountId>.txt`.

## Правила

Убийца и жертва — inhabited marine, не бот, не самоубийство.

| id | Когда |
|---|---|
| `orange_juice` | убить игрока `STEAM_1:0:43473770` (Orange) |
| `fruits_revenge` | этот же аккаунт убивает игрока, у которого уже открыт `orange_juice` |
| `bloodbath` | убить четырёх inhabited-игроков за 2 с (залп гранаты и т.п.) |
| `pure_heart` | паразит убил тебя, затем этот же или вышедший из тебя убивает другого игрока (открывается первой жертве) |

## Попап

Справа от головы (`popup_x` 120), ниже TK (`popup_y` 48), дорожка 3.
Над полоской — ник, под ней слева иконка 32×32, справа заголовок на 1–2 строки.
Числа нет. `Int 21 = 1` в `wkc_popup_hud.nut`.

В плашку уходит `title` на языке того, кто открыл. `!ach` — язык смотрящего.

## Команды

| Команда | Кто | Что |
|---|---|---|
| `!ach` | все | только открытые; закрытые не называются, только «ещё N скрытых» |
| `!ach_help` | все | справка |
| `!ach_test <id>` | McAuth | попап без записи на диск |
| `!ach_reset` | McAuth | обнулить свой сейв |
| `!ach_reset <steamid>` | McAuth | обнулить указанный аккаунт |
| `!ach_reset all` | McAuth | обнулить известные сейвы по index |

Без `id` у `!ach_test` — usage и список id. Нужен живой морпех.

## Переменные

| Переменная | По умолчанию | Смысл |
|---|---|---|
| `chat_notify` | `0` | писать открытие автору в чат |
| `popup` | `1` | спавнить world-popup |
| `popup_lifetime` | `3.5` | секунды показа |
| `popup_delay` | `0.4` | задержка |
| `popup_x` | `120` | правее головы @768p |
| `popup_y` | `48` | ниже плашки TK @768p |
| `popup_stack_gap` | `72` | шаг стека вправо |
| `popup_icon_w` / `popup_icon_h` | `32` / `32` | размер иконки |
| `popup_scale` | `1.0` | множитель |
| `popup_accent` | `255 150 40` | полоска и ник |
| `popup_text` | `255 220 180` | заголовок |
| `popup_bg` | `24 12 4` | фон |
| `popup_bg_alpha` | `225` | альфа фона |
| `popup_alpha` | `230` | альфа иконки и текста |
