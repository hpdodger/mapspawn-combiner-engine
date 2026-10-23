// TK Counter — red center announcement (game_text), used when popup = 0.
// When popup = 1 the kill count is a world popup (tkc_popup_hud.nut);
// this file still supplies the rank-up chat text and the center-text layout.
//
// Squirrel has no JS template literals / expressions inside ${...}.
// Placeholders are plain substitutions (see TkFill):
//   ${nickname}  / ${name}
//   ${killcount} / ${count}
//   ${rank}      / ${title}   — may be "" when rank is hidden
//
// rank_on_every_kill:
//   true  — ${rank} filled on every kill
//   false — ${rank} empty on normal kills; rank-up uses template_rankup
//
// Example kill line with optional rank:
//   "${nickname}: ${killcount}${rank}"
// and set rank_prefix = " — " so rank becomes " — Title" or "".

::g_TkAnnounce <- {
    // false = ранг только при новом звании; true = ранг в каждой строке килла
    rank_on_every_kill = false,

    // Prefixed to rank text when rank is shown on a kill line (ignored if rank empty)
    rank_prefix = " — ",

    // Один шаблон на обычный килл. ${rank} будет либо " — Звание", либо "".
    template_kill = {
        ru = "${nickname}: ${killcount}${rank}",
        en = "${nickname}: ${killcount}${rank}",
    },

    // Отдельная строка при повышении ранга
    template_rankup = {
        ru = "${nickname} → ${rank}",
        en = "${nickname} → ${rank}",
    },

    // game_text look (y: 0 = top, 1 = bottom, -1 = center)
    color    = "255 40 40 255",
    color2   = "255 40 40 255",
    x        = "-1",
    y        = "0.32",
    y_step   = "0.055",
    holdtime = "4",
    fadein   = "0.15",
    fadeout  = "0.35",
    // game_text effect: 0 = fade, 1 = credits (typewriter), 2 = scan-out
    effect   = "0",

    stack_slots  = 4,
    channel_base = 1,
}

// Runtime: when each stack slot becomes free again (Time()). Max 6 slots.
::g_TkAnnounceSlotFreeAt <- [ 0.0, 0.0, 0.0, 0.0, 0.0, 0.0 ]
