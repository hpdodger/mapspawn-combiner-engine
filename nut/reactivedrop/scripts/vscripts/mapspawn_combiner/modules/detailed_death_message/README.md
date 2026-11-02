# detailed_death_message

Подробная строка о смерти морпеха в чат: чем били до последнего удара.
Вместо штатного «X died» получается фраза вроде «Sarge was slashed by drone
then shot by uber and finally killed by fire.»

Имя в реестре: `detailed_death_message`. Версия задаётся в
`module_detailed_death_message.nut`.

Выключить: `!am_disable detailed_death_message`.

## Авторство

Логика и английские формулировки — **jhh8**:
[detailed-death-message](https://github.com/jhh8/detailed-death-message).

Порт в модуль mapspawn combiner и перевод — typical russian.

## Как устроено

На каждом уроне морпеху в его script scope пишется история (classname,
оружие, тип урона, время). Урон **не меняется**. При смерти
`AlterDeathMessage` склеивает фразу и печатает её в чат и консоль.

Движок умеет разослать только одну строку. Если у всех игроков один язык
(типичный случай: все на `en`, или `force_lang`), модуль отдаёт шаблон с
`%s1` в `AlterDeathMessage` — имя морпеха подставляет игра.

Если языки в сессии разные, каждому уходит свой `ClientPrint`, штатный
«X died» глушится.

Язык — общий `McI18n` (`!mc_lang en|ru`, по умолчанию **en**). Принудительно
один на всех:

```
!am_set detailed_death_message force_lang en
!am_set detailed_death_message force_lang ru
!am_set detailed_death_message force_lang player
```

Словари — `strings.nut` (имена пришельцев и оружия, типы урона, союзы).
Русские имена — в творительном падеже, под схему «был изрублен дроном».

## Файлы

| Файл | Назначение |
|---|---|
| `module_detailed_death_message.nut` | регистрация, хуки, сбор фразы |
| `strings.nut` | `::DdmI18n` — en/ru |
| `README.md` | это описание |

Клиентских файлов нет.

## Совместимость

`weapon_kills` тоже слушает `OnTakeDamage_Alive_Any`, но смотрит пару
inhabited marine → alien. Этот модуль смотрит жертву-морпеха. Оба
возвращают исходный урон.

Других модулей на `AlterDeathMessage` в этом дереве нет. Модуль
подключается в конце `mapspawn.nut`.
