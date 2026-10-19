# Always-on mapspawn

Серверные VScript-модули, которые работают на каждой карте через `mapspawn.nut`  
(нужен `sv_mapspawn_nut_exec 1`). Не зависят от выбранного челленджа.

## Состав

```
nut/reactivedrop/
  cfg/autoexec.cfg
  scripts/vscripts/
    mapspawn.nut              — вход: загрузка и раздача событий
    always/
      registry.nut            — реестр модулей
      game_events.nut         — игровые OnGameEvent_*
      thinker_hooks.nut       — OnGameplayStart, Update, урон и т.п.
      admins.nut              — SteamID для !ao_enable / !ao_save …
      module_chat_admin.nut   — команды !ao_*
      module_tk_counter.nut   — подключение счётчика тимкиллов
    tk_counter/               — логика счётчика тимкиллов
```

## Как это работает

1. При старте карты движок выполняет `mapspawn.nut`.
2. Подключаются реестр, списки хуков и модули.
3. Каждый модуль вызывает `::AlwaysRegister(m)`.
4. `::AlwaysApplyConvars()` выставляет convars из модулей.
5. Из файла настроек (если есть) тихо подтягиваются вкл/выкл и переменные.
6. На каждое игровое событие и служебный хук вызывается раздача по модулям.
7. Выключенный модуль события не получает.
8. `::AlwaysSetEnabled` меняет флаг и при необходимости зовёт `OnEnable` / `OnDisable`.

Модуль подписывается только на нужные слоты, например  
`function OnGameEvent_entity_killed(params) { … }`.

### Служебные хуки (не game event)

| Функция в корне | Слот у модуля | Заметки |
|---|---|---|
| `OnMissionStart` | `OnMissionStart` | без аргументов |
| `OnGameplayStart` | `OnGameplayStart` | без аргументов |
| `UserConsoleCommand` | `UserConsoleCommand` | модуль получает `{ player, value }` |
| `UserMenuSelect` | `UserMenuSelect` | модуль получает `{ player, slot }` |
| `OnTakeDamage_Alive_Any` | `OnTakeDamage_Alive_Any` | через `AlwaysDispatchDamage`; return меняет урон |
| `AlterDeathMessage` | `AlterDeathMessage` | побеждает последняя вернувшаяся строка |
| `OnReceivedTextMessage` | `OnReceivedTextMessage` | цепочка строк |
| (отдельная сущность) | `Update` | ~20 раз в секунду |
| после `mission_success` / `mission_failed` | `Cleanup` | после раздачи самого game event |

Эти имена движок также может вызывать у скрипта активного челленджа. Здесь они объявлены в корне `mapspawn`, чтобы always-on модули работали всегда. Со скриптом челленджа это разные области видимости: один модуль дважды не вызывается.

Список игровых событий — в `always/game_events.nut` (по `g_ScriptGameEventList` в исходниках игры). Если в новой версии игры появятся новые имена — обновить этот файл.

## Модули

| Модуль | Команды |
|---|---|
| `chat_admin` | `!ao_*` — список, вкл/выкл, переменные, save/load (грузится первым; себя выключить нельзя) |
| `tk_counter` | `!tkc*` — счётчик тимкиллов; сейвы в `save/vscripts/tk_counter/` |

### Команды `!ao_`

| Команда | Кто | Что делает |
|---|---|---|
| `!ao_help` | все | справка |
| `!ao_modules` | все | список `[ON]`/`[OFF]` и версии |
| `!ao_info <module>` | все | описание |
| `!ao_vars <module>` | все | переменные модуля |
| `!ao_enable <module>` | whitelist | включить (в RAM, пока не save) |
| `!ao_disable <module>` | whitelist | выключить (в RAM, пока не save) |
| `!ao_set <module> <var> <value>` | whitelist | переменная (в RAM, пока не save) |
| `!ao_save` | whitelist | записать `save/vscripts/always/settings.txt` |
| `!ao_load` | whitelist | применить файл (с `OnEnable`/`OnDisable`) |
| `!ao_reset` | whitelist | значения из кода + очистить файл |

Whitelist: `always/admins.nut` (`STEAM_1:Y:Z`).

Префикс `!ao_` не пересекается с командами счётчика `!tkc`.

### Файл настроек

`save/vscripts/always/settings.txt` — один на весь сервер:

```text
tk_counter.__enabled=0
SomeMod.cooldown=3.0
```

- `chat_admin` из файла не выключается.
- После регистрации модулей настройки подтягиваются без вызова `OnEnable`/`OnDisable`.
- `!ao_enable` / `!ao_set` живут в памяти, пока не сделан `!ao_save`.

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
::AlwaysDeclareVariables(m, [
    ["cooldown", 3.0, "Seconds between alerts", { min = 0.5, max = 30, step = 0.5 }],
]);
::AlwaysRegister(m);
```

Поле `requires_registry` — минимальная версия `always/registry.nut`, с которой модуль рассчитан работать. Если на сервере реестр старше, в лог будет предупреждение.

Логика счётчика тимкиллов лежит в `tk_counter/`. Правки счётчика — там; `module_tk_counter.nut` только регистрирует его в шине.

## Добавить модуль

1. Код — в `scripts/vscripts/<имя>/` или в одном файле.
2. Файл `always/module_<имя>.nut`: таблица модуля, нужные хуки, `::AlwaysRegister`.
3. Одна строка `IncludeScript( "always/module_<имя>" )` в `mapspawn.nut`.

## Установка

Скопировать `nut/reactivedrop/` в дерево игры или dedicated-сервера.  
Включить `sv_mapspawn_nut_exec 1`.

На сервере должен быть **один** такой `mapspawn.nut`. Если уже был другой — заменить этим или вручную перенести в него загрузку модулей. Не держать параллельно второй полный `mapspawn` только ради счётчика тимкиллов: он уже подключён как модуль.
