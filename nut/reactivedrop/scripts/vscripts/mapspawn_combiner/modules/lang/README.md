# lang

Общий язык интерфейса модулей mapspawn combiner.

Хранение: `::McI18n` (`mapspawn_combiner/i18n.nut`) →
`save/vscripts/mc_lang/<accountId>.txt`.
По умолчанию **en**.

| Команда | Действие |
|---|---|
| `!mc_lang` | показать текущий язык |
| `!mc_lang en` / `!mc_lang ru` | сменить язык |

`!tkc_lang` у TK пишет в тот же `McI18n` (и зеркалит в свой сейв).
Модули читают язык через `::McI18n.LangOf(hPlayer)`.
