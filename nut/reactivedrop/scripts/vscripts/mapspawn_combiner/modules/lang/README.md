# lang

Общий язык интерфейса модулей mapspawn combiner и показ мировых попапов
на своём экране.

Хранение языка: `::McI18n` (`mapspawn_combiner/i18n.nut`) →
`save/vscripts/mc_lang/<accountId>.txt`.
По умолчанию **en**.

Хранение попапов: `::McHud` (`mapspawn_combiner/hud.nut`) →
`save/vscripts/mc_hud/<accountId>.txt` (строка `1` — показывать, `0` — скрыть).
По умолчанию попапы **включены**.

| Команда | Действие |
|---|---|
| `!mc_lang` | показать текущий язык |
| `!mc_lang en` / `!mc_lang ru` | сменить язык |
| `!mc_popups` | показать, рисуются ли попапы на своём экране |
| `!mc_popups on` / `!mc_popups off` | включить или скрыть попапы убийств и тимкиллов у себя |

Алиасы: `/mc_lang`, `/mc_popups`, `!mc_popups_on`, `!mc_popups_off`.
Ответ только автору.

`!tkc_lang` у TK пишет в тот же `McI18n` (и зеркалит в свой сейв).
Модули читают язык через `::McI18n.LangOf(hPlayer)`.

`!mc_popups off` прячет плашки weapon_kills и tk_counter только у этого игрока.
Счётчики, чат и попапы у остальных не меняются. Нужен обновлённый клиентский
`wkc_popup_hud.nut` (Workshop stub). Ачивки идут другим Paint и этой командой
не закрываются.
