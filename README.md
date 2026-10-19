# Mapspawn Combiner

Серверные VScript-модули, которые работают на каждой карте через `mapspawn.nut`
(нужен `sv_mapspawn_nut_exec 1`). Не зависят от выбранного челленджа.

## Состав

```
nut/reactivedrop/
  cfg/autoexec.cfg
  scripts/vscripts/
    mapspawn.nut                 — вход: загрузка и раздача событий
    mapspawn_combiner/
      registry.nut               — ::McRegistry
      game_events.nut            — ::McGameEvents (OnGameEvent_*)
      thinker_hooks.nut          — ::McThinkers (OnGameplayStart, Update, урон…)
      admins.nut                 — ::McAuth (SteamID для !am_* / !tkc_reset)
      modules/
        admin/module_admin.nut   — команды !am_*
        tk_counter/              — счётчик тимкиллов + регистрация на шине
        laser_pointer/           — лазерный указатель
```

## Как это работает

1. При старте карты движок выполняет `mapspawn.nut`.
2. Подключаются реестр, списки хуков и модули.
3. Каждый модуль вызывает `McRegistry.Register(m)`.
4. `McRegistry.ApplyConvars()` выставляет convars из модулей.
5. Из файла настроек (если есть) тихо подтягиваются вкл/выкл и переменные.
6. `McGameEvents.BindDispatchers()` и `McThinkers.BindHooks()` вешают хуки движка.
7. На каждое игровое событие и служебный хук вызывается раздача по модулям.
8. Выключенный модуль события не получает.
9. `McRegistry.SetEnabled` меняет флаг и при необходимости зовёт `OnEnable` / `OnDisable`.

Модуль подписывается только на нужные слоты, например
`function OnGameEvent_entity_killed(params) { … }`.

Пространства имён:

| Таблица | Назначение |
|---|---|
| `McRegistry` | регистрация, раздача, convars, переменные |
| `McGameEvents` | список имён + `BindDispatchers()` |
| `McThinkers` | Update-thinker + служебные хуки |
| `McAuth` | whitelist SteamID (`IsAdmin`, `PlayerKey`…) |

Тег в логе: `[MC]`. Глобальный `enum HudPrint` остаётся общим.

### Служебные хуки (не game event)

| Функция в корне | Слот у модуля | Заметки |
|---|---|---|
| `OnMissionStart` | `OnMissionStart` | без аргументов |
| `OnGameplayStart` | `OnGameplayStart` | без аргументов |
| `UserConsoleCommand` | `UserConsoleCommand` | модуль получает `{ player, value }` |
| `UserMenuSelect` | `UserMenuSelect` | модуль получает `{ player, slot }` |
| `OnTakeDamage_Alive_Any` | `OnTakeDamage_Alive_Any` | через `McRegistry.DispatchDamage`; return меняет урон |
| `AlterDeathMessage` | `AlterDeathMessage` | побеждает последняя вернувшаяся строка |
| `OnReceivedTextMessage` | `OnReceivedTextMessage` | цепочка строк |
| (сущность `mc_thinker`) | `Update` | ~20 раз в секунду |
| после `mission_success` / `mission_failed` | `Cleanup` | после раздачи самого game event |

Эти имена движок также может вызывать у скрипта активного челленджа. Здесь они объявлены в корне `mapspawn`, чтобы модули combiner работали всегда. Со скриптом челленджа это разные области видимости: один модуль дважды не вызывается.

Список игровых событий — в `mapspawn_combiner/game_events.nut` (по `g_ScriptGameEventList` в исходниках игры). Хендлеры там **явные** (имя события зашито в теле функции): движок зовёт `OnGameEvent_*` с `this = null`, поэтому `bindenv` и замыкания на локали не работают. Если в новой версии игры появятся новые имена — добавить строку в `names` и такой же явный хендлер в `handlers`.

## Модули

| Модуль | Команды |
|---|---|
| `admin` | `!am_*` — список, вкл/выкл, переменные, save/load (грузится первым; себя выключить нельзя) |
| `tk_counter` | `!tkc*` — счётчик тимкиллов; сейвы в `save/vscripts/tk_counter/` |
| `laser_pointer` | `laser` / `!laser` и `scripted_user_func`; тюнинг через `!am_vars` / `!am_set` |

### Команды `!am_`

| Команда | Кто | Что делает |
|---|---|---|
| `!am_help` | все | справка |
| `!am_modules` | все | список `[ON]`/`[OFF]` и версии |
| `!am_info <module>` | все | описание |
| `!am_vars <module>` | все | переменные модуля |
| `!am_enable <module>` | whitelist | включить (в RAM, пока не save) |
| `!am_disable <module>` | whitelist | выключить (в RAM, пока не save) |
| `!am_set <module> <var> <value>` | whitelist | переменная (в RAM, пока не save) |
| `!am_save` | whitelist | записать `save/vscripts/mapspawn_combiner/settings.txt` |
| `!am_load` | whitelist | применить файл (с `OnEnable`/`OnDisable`) |
| `!am_reset` | whitelist | значения из кода + очистить файл |

Имя модуля в командах — точное (`laser_pointer`, не `LaserPointer`), как в `!am_modules`.

Whitelist: `mapspawn_combiner/admins.nut` (`STEAM_1:Y:Z`), общий с `!tkc_reset`.

Префикс `!am_` не пересекается с командами счётчика `!tkc`. Алиас `/am_…` тоже принимается.

### Файл настроек

`save/vscripts/mapspawn_combiner/settings.txt` — один на весь сервер:

```text
tk_counter.__enabled=0
laser_pointer.beam_width=1.5
```

- `admin` из файла не выключается.
- После регистрации модулей настройки подтягиваются без вызова `OnEnable`/`OnDisable`.
- `!am_enable` / `!am_set` живут в памяти, пока не сделан `!am_save`.

### Как выглядит модуль

```squirrel
local m = {
    name        = "Example",
    enabled     = true,
    convars     = {},
    version     = "1.0.0",
    description = "…",
    requires_registry = 4,

    function OnGameEvent_entity_killed(params) { /* … */ },
    function OnGameplayStart() {},
    function Update() {},
    function OnEnable() {},
    function OnDisable() {},
    function Cleanup() {},
};
McRegistry.DeclareVariables(m, [
    ["cooldown", 3.0, "Seconds between alerts", { min = 0.5, max = 30, step = 0.5 }],
]);
McRegistry.Register(m);
```

Поле `requires_registry` — минимальная версия `McRegistry.version`, с которой модуль рассчитан работать. Если на сервере реестр старше, в лог будет предупреждение.

Логика счётчика тимкиллов лежит в `modules/tk_counter/`. Правки счётчика — там; `module_tk_counter.nut` только регистрирует его на шине.

## Добавить модуль

1. Код — в `mapspawn_combiner/modules/<имя>/`.
2. Файл `module_<имя>.nut`: таблица модуля, нужные хуки, `McRegistry.Register`.
3. Одна строка `IncludeScript( "mapspawn_combiner/modules/<имя>/module_<имя>" )` в `mapspawn.nut`.

## Установка

Скопировать `nut/reactivedrop/` в дерево игры или dedicated-сервера.
Включить `sv_mapspawn_nut_exec 1`.

На сервере должен быть **один** такой `mapspawn.nut`. Если уже был другой — заменить этим или вручную перенести в него загрузку модулей.
