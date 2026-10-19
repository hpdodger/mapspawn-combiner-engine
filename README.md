# Always-on mapspawn combiner

Диспетчер always-on модулей для ASRD: один `mapspawn.nut`, реестр, модули в `always/`.  
Не путать с challenge combiner (`combine_registry` / `rd_challenge`).

## Layout

```
nut/reactivedrop/
  cfg/autoexec.cfg                 # sv_mapspawn_nut_exec 1
  scripts/vscripts/
    mapspawn.nut                   # load registry + modules, fan-out events
    always/
      registry.nut                 # AlwaysRegister / DeclareVariables / convars / Dispatch / DispatchDamage
      game_events.nut              # all g_ScriptGameEventList → AlwaysDispatchEvent
      thinker_hooks.nut            # OnGameplayStart, Update, damage, … → AlwaysDispatch*
      admins.nut                   # !ao_enable whitelist
      module_chat_admin.nut        # !ao_* (load first)
      module_tk_counter.nut
    tk_counter/                    # TK Counter core (from asrd_tk_counter)
```

## How it works

1. Engine runs `mapspawn` when `sv_mapspawn_nut_exec 1`.
2. `mapspawn` includes `always/registry` + `game_events` + `thinker_hooks`, then each `always/module_*.nut`.
3. Modules use the laser-pointer table shape and call `::AlwaysRegister(m)`.
4. After includes, `::AlwaysApplyConvars()` applies module `convars`.
5. `::AlwaysBindGameEventDispatchers()` installs root `OnGameEvent_*` for every unique name from engine `g_ScriptGameEventList` (155; source lists `achievement_earned` twice).
6. `::AlwaysBindThinkerHooks()` installs the non-event engine hooks on root (see below) plus an `info_target` thinker for `Update`.
7. Modules subscribe by defining the matching slot. Unused hooks are cheap no-ops in dispatch.
8. Disabled modules are skipped. `::AlwaysSetEnabled` flips the flag and calls `OnEnable` / `OnDisable`.

### Thinker / lifecycle hooks (always-on root)

| Root function | Module slot | Notes |
|---|---|---|
| `OnMissionStart` | `OnMissionStart` | no args |
| `OnGameplayStart` | `OnGameplayStart` | no args |
| `UserConsoleCommand` | `UserConsoleCommand` | engine `(player, value)` → module `{ player, value }` |
| `UserMenuSelect` | `UserMenuSelect` | engine `(player, slot)` → module `{ player, slot }` |
| `OnTakeDamage_Alive_Any` | `OnTakeDamage_Alive_Any` | via `AlwaysDispatchDamage`; return overwrites damage |
| `AlterDeathMessage` | `AlterDeathMessage` | last returned string wins |
| `OnReceivedTextMessage` | `OnReceivedTextMessage` | threaded string transform; must stay a string |
| *(thinker entity)* | `Update` | 20 Hz (`info_target` `always_on_thinker`); return interval ignored at module level |
| *(mission_success/failed)* | `Cleanup` | dispatched after the game-event fan-out |

Challenge thinkers still get their own copies of these hooks (engine nulls them on thinker scope so root is not inherited). Always-on runs from root; challenge modules run from the thinker — no double call into the same module table.

## Modules

| Module | Commands / notes |
|---|---|
| `chat_admin` | `!ao_*` — modules / info / vars / enable / disable / set (load first; cannot disable itself) |
| `tk_counter` | `!tkc*` — same as asrd_tk_counter; saves under `save/vscripts/tk_counter/` |

### Runtime admin (`!ao_`)

| Command | Who | Effect |
|---|---|---|
| `!ao_help` | everyone | command list |
| `!ao_modules` | everyone | `[ON]`/`[OFF]` list |
| `!ao_info <module>` | everyone | description |
| `!ao_vars <module>` | everyone | tunables from `AlwaysDeclareVariables` |
| `!ao_enable <module>` | whitelist | turn on + `OnEnable` (RAM until save) |
| `!ao_disable <module>` | whitelist | turn off + `OnDisable` (RAM until save) |
| `!ao_set <module> <var> <value>` | whitelist | change a tunable (RAM until save) |
| `!ao_save` | whitelist | write `save/vscripts/always/settings.txt` |
| `!ao_load` | whitelist | re-apply file (with OnEnable/OnDisable) |
| `!ao_reset` | whitelist | compile-time defaults + clear file |

Whitelist: `always/admins.nut` (`::g_AlwaysAdmins`, `STEAM_1:Y:Z`).  
Prefix `!ao_` does not clash with challenge `!cc_` or TK `!tkc`.

### Settings file

Path: `save/vscripts/always/settings.txt` (one file for the whole server).

```text
tk_counter.__enabled=0
SomeMod.cooldown=3.0
```

- `chat_admin` is never written/loaded as disabled.
- After all modules register, `mapspawn` calls `ApplySavedSettings(true)` (silent flags).
- `!ao_enable` / `!ao_set` stay in RAM until `!ao_save`.

### Module shape (same idea as laser pointer)

```squirrel
local m = {
    name        = "Example",
    enabled     = true,
    convars     = {},
    version     = "1.0.0",   // shown by !ao_modules / !ao_info
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

Ядро TK скопировано из `asrd_tk_counter`. Логику счётчика править там и переносить сюда, либо считать эту копию деплой-деревом.

## Add a module

1. Put logic under `scripts/vscripts/<name>/` (or a single file).
2. Add `always/module_<name>.nut` in LP module shape; define only the `OnGameEvent_*` slots you need.
3. Add one `IncludeScript( "always/module_<name>" )` line in `mapspawn.nut`.
4. Event list lives in `always/game_events.nut` — refresh from `ScriptGameEventListener.cpp` if the engine adds names.

## Install

Copy `nut/reactivedrop/` into the game/dedicated tree. Enable `sv_mapspawn_nut_exec 1`.

If another always-on `mapspawn.nut` already exists, replace it with this dispatcher (or merge only the IncludeScript + event stubs). Do not stack old TK `mapspawn.merge-snippet` on top — TK is already a module here.
