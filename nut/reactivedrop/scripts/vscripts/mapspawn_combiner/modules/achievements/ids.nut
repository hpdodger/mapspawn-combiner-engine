// Цель «Orange Juice» / «Fruits Revenge».
// Подключается в локальную таблицу модуля, не в корень.
// SteamID64 76561198047213268 → STEAM_1:0:43473770 → account 86947540.

orangeSteam <- "STEAM_1:0:43473770";
orangeKey <- "86947540";

if ( "McAuth" in getroottable() ) {
    local acc = ::McAuth.AccountIdFromString( orangeSteam );
    if ( acc != null )
        orangeKey = acc.tostring();
}
