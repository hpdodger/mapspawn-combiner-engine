# Mapspawn Combiner

Движок и инфраструктура для серверных VScript на каждой карте: один
`mapspawn.nut` (нужен `sv_mapspawn_nut_exec 1`), реестр, раздача событий,
настройки, права и команды во время игры. Не зависит от выбранного челленджа.

Модули (`tk_counter`, `weapon_kills`, лазер и остальные) подключаются к этому
ядру. Сами по себе они не занимают корень `mapspawn`: подписываются на слоты
реестра. На сервер приходится один `mapspawn.nut`; если каждый аддон ставит
свои `OnGameEvent_*`, они затирают друг друга. Combiner — этот единственный
вход и общая раздача.

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
      admins.nut                 — ::McAuth (SteamID)
      modules/
        <имя>/module_<имя>.nut   — вход модуля
```

Ядро (движок) — файлы в `mapspawn_combiner/` вне `modules/`: реестр, события,
thinker, авторизация, лог. Каждый модуль живёт целиком в своей папке
`modules/<имя>/`. Вход — `module_<имя>.nut`: таблица, хуки, `McRegistry.Register`.

Администрирование во время игры — модуль `admin`. Он оформлен как остальные
(своя папка, таблица, регистрация в реестре), грузится первым и себя выключить
нельзя. Команды и права — в [README модуля](nut/reactivedrop/scripts/vscripts/mapspawn_combiner/modules/admin/README.md).

## Как это работает

1. При старте карты движок выполняет `mapspawn.nut`.
2. Подключаются реестр, списки хуков и модули (порядок `IncludeScript` = порядок раздачи).
3. Каждый модуль вызывает `McRegistry.Register(m)`.
4. Модуль `admin` тихо подтягивает вкл/выкл и переменные из файла настроек (если есть).
5. `McRegistry.ApplyConvars()` выставляет convars из модулей.
6. `McGameEvents.BindDispatchers()` и `McThinkers.BindHooks()` вешают хуки движка.
7. На каждое игровое событие и служебный хук идёт раздача по включённым модулям.
8. Выключенный модуль события не получает.
9. `McRegistry.SetEnabled` меняет флаг и при необходимости зовёт `OnEnable` / `OnDisable`.

Модуль подписывается только на нужные слоты, например
`function OnGameEvent_entity_killed(params) { … }`.

Ошибка в одном модуле не останавливает остальные: раздача ловит исключение и пишет в лог.

Пространства имён:

| Таблица | Назначение |
|---|---|
| `McRegistry` | регистрация, раздача, convars, переменные |
| `McGameEvents` | список имён + `BindDispatchers()` |
| `McThinkers` | Update-thinker + служебные хуки |
| `McAuth` | список SteamID (`IsAdmin`, `PlayerKey`…) |
| `McLog` | цветной лог загрузки: Info / Warn / Err |

Тег в логе: `[MC]`. Глобальный `enum HudPrint` остаётся общим.

Имена модулей в реестре — `snake_case`. В командах то же имя, что поле `name`.
`FindModule` ищет точное совпадение.

Префиксы чат-команд живут в модулях. Каждый модуль сам разбирает `player_say`;
одна и та же строка сработала бы у всех подписанных.

### Подсистемы ядра

**Реестр (`registry.nut`).** `Register` пропускает повторное имя модуля.
Конфликт значений convar записывается и печатается при `ApplyConvars`
(остаётся значение того, кто зарегистрировался раньше). Возврат обработчика
игнорируется, кроме числового возврата `DispatchDamage`. Поле `requires_registry` —
минимальная версия `McRegistry.version`, с которой модуль рассчитан работать.
Если версия реестра на сервере меньше — в лог будет предупреждение, модуль всё равно регистрируется.

**Игровые события (`game_events.nut`).** Список имён — по `g_ScriptGameEventList`
в исходниках игры. Хендлеры **явные** (имя события зашито в теле функции):
движок зовёт `OnGameEvent_*` с `this = null`, поэтому `bindenv` и замыкания
на локали не работают. `BindDispatchers()` только копирует готовые функции
из `handlers` в корень. События без логики в модулях сразу возвращаются. Если в новой
версии игры появятся имена — добавить строку в `names` и такой же явный хендлер.

**Служебные хуки (`thinker_hooks.nut`).** `OnGameplayStart` заново создаёт
сущность `mc_thinker`: `asw_restart_mission` удаляет `info_target` и не
перезагружает `mapspawn.nut`, иначе `Update` у модулей молчит до смены карты.

**Авторизация (`admins.nut`).** Общий список SteamID для команд, которым
нужны права. Формат как в `status`: `STEAM_1:Y:Z`.

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

Эти имена движок также может вызывать у скрипта активного челленджа. Здесь они
объявлены в корне `mapspawn`, чтобы модули combiner работали всегда. Со скриптом
челленджа это разные области видимости: один модуль дважды не вызывается.

## Как выглядит модуль

```squirrel
local m = {
    name        = "example",
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

Логика модуля лежит в его папке. Правки — там; `module_*.nut` регистрирует
модуль в реестре (и при необходимости держит весь код, если файл один).

## Добавить модуль

1. Код — в `mapspawn_combiner/modules/<имя>/`.
2. Файл `module_<имя>.nut`: таблица модуля, нужные хуки, `McRegistry.Register`.
3. Одна строка `IncludeScript( "mapspawn_combiner/modules/<имя>/module_<имя>" )` в `mapspawn.nut`.

## Файл настроек

`save/vscripts/mapspawn_combiner/settings.txt` — один на весь сервер:

```text
example.__enabled=0
example.cooldown=3.0
```

- Строки `Module.__enabled=0|1` и `Module.var=value`.
- Модуль `admin` из файла не выключается и в файл как выключенный не пишется.
- После регистрации модулей `mapspawn.nut` зовёт `ApplySavedSettings(true)`:
  флаги вкл/выкл ставятся без `OnEnable` / `OnDisable`.
- Смена флага или переменной во время игры живёт в памяти, пока её не запишут
  на диск. Запись, чтение и сброс файла — команды модуля `admin`.

Описание конкретного модуля — README в его папке `modules/<имя>/`. Состав
модулей на сервере свой: в `mapspawn.nut` подключено то, что нужно этому дереву.

## Установка

Скопировать `nut/reactivedrop/` в дерево игры или dedicated-сервера.
Включить `sv_mapspawn_nut_exec 1` (в дереве уже есть `cfg/autoexec.cfg`).

На сервере должен быть **один** такой `mapspawn.nut`. Если уже был другой —
**не** дописывать combiner в конец старого файла: `BindDispatchers` затрёт
корневой `OnGameEvent_player_say`. Старые команды перенеси в отдельный модуль.

Правки `.nut` подхватываются со следующей загрузки карты (смена карты,
команда `map`, на listen-сервере — reconnect). Уже загруженная VM старый файл сама не перечитает.
Успешная загрузка пишет в лог `[MC] registered module: …`.
