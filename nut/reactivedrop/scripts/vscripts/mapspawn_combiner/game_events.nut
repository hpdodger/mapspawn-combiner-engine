// mapspawn_combiner/game_events.nut
// Корневые OnGameEvent_* → McRegistry.DispatchEvent.
//
// Почему хендлеры явные, с зашитым именем события в теле функции
// (а не цикл + bindenv / замыкание):
//
// 1) Движок вызывает OnGameEvent_* с this = null. bindenv(env) при таком
//    вызове не сохраняется → this.hook падает с "index 'hook' does not exist".
// 2) Вложенная function в этом Squirrel/VScript не захватывает локали внешней
//    (параметр hookName и т.п.) → "index 'hookName' does not exist".
// 3) Рабочий вариант тот же, что в challenge_challenge_combiner.nut: отдельная
//    function на каждое событие, имя — строковый литерал в теле. BindDispatchers
//    только копирует готовые функции из handlers[] в getroottable().
//
// mission_success / mission_failed дополнительно зовут McRegistry.Dispatch("Cleanup").
//
// Вызов: ::McGameEvents.BindDispatchers()

::McGameEvents <- {
    names = [
        "asw_mission_restart",
        "gameui_activated",
        "gameui_hidden",
        "player_fullyjoined",
        "player_should_switch",
        "player_commanding",
        "player_command_follow",
        "player_command_hold",
        "player_alt_fire",
        "player_heal_target",
        "player_heal_target_none",
        "player_heal",
        "player_give_ammo",
        "player_deploy_ammo",
        "player_dropped_weapon",
        "marine_selected",
        "marine_ignited",
        "marine_extinguished",
        "marine_infested",
        "marine_infested_cured",
        "marine_infested_killed",
        "marine_healed",
        "marine_no_ammo",
        "ammo_pickup",
        "item_pickup",
        "weapon_reload",
        "weapon_offhanded",
        "door_recommend_destroy",
        "door_destroyed",
        "door_welded_visible",
        "door_unwelded",
        "door_recommend_weld",
        "door_welded",
        "sentry_placed",
        "sentry_start_building",
        "sentry_stop_building",
        "sentry_complete",
        "sentry_rotated",
        "sentry_dismantled",
        "alien_ignited",
        "boulder_lasered",
        "physics_visible",
        "physics_melee",
        "recommend_hold_position",
        "scanner_important",
        "general_hint",
        "movement_hint",
        "movement_hint_success",
        "alien_died",
        "fast_reload",
        "fast_reload_fail",
        "difficulty_changed",
        "achievement_earned",
        "mission_success",
        "mission_failed",
        "alien_hurt",
        "marine_hurt",
        "pickup_selected",
        "sentry_selected",
        "button_area_active",
        "button_area_inactive",
        "button_area_used",
        "jukebox_play_random",
        "jukebox_stop",
        "level_up",
        "campaign_changed",
        "swarm_state_changed",
        "team_info",
        "team_score",
        "teamplay_broadcast_audio",
        "player_team",
        "player_class",
        "player_death",
        "player_hurt",
        "player_chat",
        "player_score",
        "player_spawn",
        "player_shoot",
        "player_use",
        "player_changename",
        "player_hintmessage",
        "game_init",
        "game_newmap",
        "game_start",
        "game_end",
        "round_start",
        "round_end",
        "round_start_pre_entity",
        "teamplay_round_start",
        "hostname_changed",
        "finale_start",
        "game_message",
        "break_breakable",
        "break_prop",
        "entity_killed",
        "bonus_updated",
        "player_stats_updated",
        "achievement_event",
        "achievement_write_failed",
        "physgun_pickup",
        "flare_ignite_npc",
        "helicopter_grenade_punt_miss",
        "user_data_downloaded",
        "ragdoll_dissolved",
        "gameinstructor_draw",
        "gameinstructor_nodraw",
        "map_transition",
        "entity_visible",
        "set_instructor_group_enabled",
        "instructor_server_hint_create",
        "instructor_server_hint_stop",
        "server_spawn",
        "server_pre_shutdown",
        "server_shutdown",
        "server_cvar",
        "server_message",
        "server_addban",
        "server_removeban",
        "player_connect",
        "player_info",
        "player_disconnect",
        "player_activate",
        "player_connect_full",
        "player_say",
        "hltv_status",
        "hltv_cameraman",
        "hltv_rank_camera",
        "hltv_rank_entity",
        "hltv_fixed",
        "hltv_chase",
        "hltv_message",
        "hltv_title",
        "hltv_chat",
        "marine_incapacitated",
        "marine_revived",
        "alien_spawn",
        "buzzer_spawn",
        "marine_spawn",
        "colonist_spawn",
        "weapon_reload_finish",
        "heal_beacon_placed",
        "damage_amplifier_placed",
        "weapon_fire",
        "weapon_offhand_activate",
        "laser_mine_active",
        "cluster_grenade_create",
        "tesla_trap_placed",
        "fire_mine_placed",
        "laser_mine_placed",
        "gas_grenade_placed",
        "flare_placed",
        "rocket_fired",
        "fast_hack_success",
        "fast_hack_failed",
        "entity_frozen",
    ],

    // Имя хука → function с литералом имени внутри (см. шапку файла).
    handlers = {},

    function BindDispatchers() {
        // Не создавать замыкания здесь — только выставить уже готовые handlers.
        foreach ( hook, fn in this.handlers )
            getroottable()[hook] <- fn;
        printl( "[MC] bound " + this.handlers.len() + " OnGameEvent_* dispatchers" );
    },
};
::McGameEvents.handlers["OnGameEvent_asw_mission_restart"] <- function( params ) { ::McRegistry.DispatchEvent( "OnGameEvent_asw_mission_restart", params ); };
::McGameEvents.handlers["OnGameEvent_gameui_activated"] <- function( params ) { ::McRegistry.DispatchEvent( "OnGameEvent_gameui_activated", params ); };
::McGameEvents.handlers["OnGameEvent_gameui_hidden"] <- function( params ) { ::McRegistry.DispatchEvent( "OnGameEvent_gameui_hidden", params ); };
::McGameEvents.handlers["OnGameEvent_player_fullyjoined"] <- function( params ) { ::McRegistry.DispatchEvent( "OnGameEvent_player_fullyjoined", params ); };
::McGameEvents.handlers["OnGameEvent_player_should_switch"] <- function( params ) { ::McRegistry.DispatchEvent( "OnGameEvent_player_should_switch", params ); };
::McGameEvents.handlers["OnGameEvent_player_commanding"] <- function( params ) { ::McRegistry.DispatchEvent( "OnGameEvent_player_commanding", params ); };
::McGameEvents.handlers["OnGameEvent_player_command_follow"] <- function( params ) { ::McRegistry.DispatchEvent( "OnGameEvent_player_command_follow", params ); };
::McGameEvents.handlers["OnGameEvent_player_command_hold"] <- function( params ) { ::McRegistry.DispatchEvent( "OnGameEvent_player_command_hold", params ); };
::McGameEvents.handlers["OnGameEvent_player_alt_fire"] <- function( params ) { ::McRegistry.DispatchEvent( "OnGameEvent_player_alt_fire", params ); };
::McGameEvents.handlers["OnGameEvent_player_heal_target"] <- function( params ) { ::McRegistry.DispatchEvent( "OnGameEvent_player_heal_target", params ); };
::McGameEvents.handlers["OnGameEvent_player_heal_target_none"] <- function( params ) { ::McRegistry.DispatchEvent( "OnGameEvent_player_heal_target_none", params ); };
::McGameEvents.handlers["OnGameEvent_player_heal"] <- function( params ) { ::McRegistry.DispatchEvent( "OnGameEvent_player_heal", params ); };
::McGameEvents.handlers["OnGameEvent_player_give_ammo"] <- function( params ) { ::McRegistry.DispatchEvent( "OnGameEvent_player_give_ammo", params ); };
::McGameEvents.handlers["OnGameEvent_player_deploy_ammo"] <- function( params ) { ::McRegistry.DispatchEvent( "OnGameEvent_player_deploy_ammo", params ); };
::McGameEvents.handlers["OnGameEvent_player_dropped_weapon"] <- function( params ) { ::McRegistry.DispatchEvent( "OnGameEvent_player_dropped_weapon", params ); };
::McGameEvents.handlers["OnGameEvent_marine_selected"] <- function( params ) { ::McRegistry.DispatchEvent( "OnGameEvent_marine_selected", params ); };
::McGameEvents.handlers["OnGameEvent_marine_ignited"] <- function( params ) { ::McRegistry.DispatchEvent( "OnGameEvent_marine_ignited", params ); };
::McGameEvents.handlers["OnGameEvent_marine_extinguished"] <- function( params ) { ::McRegistry.DispatchEvent( "OnGameEvent_marine_extinguished", params ); };
::McGameEvents.handlers["OnGameEvent_marine_infested"] <- function( params ) { ::McRegistry.DispatchEvent( "OnGameEvent_marine_infested", params ); };
::McGameEvents.handlers["OnGameEvent_marine_infested_cured"] <- function( params ) { ::McRegistry.DispatchEvent( "OnGameEvent_marine_infested_cured", params ); };
::McGameEvents.handlers["OnGameEvent_marine_infested_killed"] <- function( params ) { ::McRegistry.DispatchEvent( "OnGameEvent_marine_infested_killed", params ); };
::McGameEvents.handlers["OnGameEvent_marine_healed"] <- function( params ) { ::McRegistry.DispatchEvent( "OnGameEvent_marine_healed", params ); };
::McGameEvents.handlers["OnGameEvent_marine_no_ammo"] <- function( params ) { ::McRegistry.DispatchEvent( "OnGameEvent_marine_no_ammo", params ); };
::McGameEvents.handlers["OnGameEvent_ammo_pickup"] <- function( params ) { ::McRegistry.DispatchEvent( "OnGameEvent_ammo_pickup", params ); };
::McGameEvents.handlers["OnGameEvent_item_pickup"] <- function( params ) { ::McRegistry.DispatchEvent( "OnGameEvent_item_pickup", params ); };
::McGameEvents.handlers["OnGameEvent_weapon_reload"] <- function( params ) { ::McRegistry.DispatchEvent( "OnGameEvent_weapon_reload", params ); };
::McGameEvents.handlers["OnGameEvent_weapon_offhanded"] <- function( params ) { ::McRegistry.DispatchEvent( "OnGameEvent_weapon_offhanded", params ); };
::McGameEvents.handlers["OnGameEvent_door_recommend_destroy"] <- function( params ) { ::McRegistry.DispatchEvent( "OnGameEvent_door_recommend_destroy", params ); };
::McGameEvents.handlers["OnGameEvent_door_destroyed"] <- function( params ) { ::McRegistry.DispatchEvent( "OnGameEvent_door_destroyed", params ); };
::McGameEvents.handlers["OnGameEvent_door_welded_visible"] <- function( params ) { ::McRegistry.DispatchEvent( "OnGameEvent_door_welded_visible", params ); };
::McGameEvents.handlers["OnGameEvent_door_unwelded"] <- function( params ) { ::McRegistry.DispatchEvent( "OnGameEvent_door_unwelded", params ); };
::McGameEvents.handlers["OnGameEvent_door_recommend_weld"] <- function( params ) { ::McRegistry.DispatchEvent( "OnGameEvent_door_recommend_weld", params ); };
::McGameEvents.handlers["OnGameEvent_door_welded"] <- function( params ) { ::McRegistry.DispatchEvent( "OnGameEvent_door_welded", params ); };
::McGameEvents.handlers["OnGameEvent_sentry_placed"] <- function( params ) { ::McRegistry.DispatchEvent( "OnGameEvent_sentry_placed", params ); };
::McGameEvents.handlers["OnGameEvent_sentry_start_building"] <- function( params ) { ::McRegistry.DispatchEvent( "OnGameEvent_sentry_start_building", params ); };
::McGameEvents.handlers["OnGameEvent_sentry_stop_building"] <- function( params ) { ::McRegistry.DispatchEvent( "OnGameEvent_sentry_stop_building", params ); };
::McGameEvents.handlers["OnGameEvent_sentry_complete"] <- function( params ) { ::McRegistry.DispatchEvent( "OnGameEvent_sentry_complete", params ); };
::McGameEvents.handlers["OnGameEvent_sentry_rotated"] <- function( params ) { ::McRegistry.DispatchEvent( "OnGameEvent_sentry_rotated", params ); };
::McGameEvents.handlers["OnGameEvent_sentry_dismantled"] <- function( params ) { ::McRegistry.DispatchEvent( "OnGameEvent_sentry_dismantled", params ); };
::McGameEvents.handlers["OnGameEvent_alien_ignited"] <- function( params ) { ::McRegistry.DispatchEvent( "OnGameEvent_alien_ignited", params ); };
::McGameEvents.handlers["OnGameEvent_boulder_lasered"] <- function( params ) { ::McRegistry.DispatchEvent( "OnGameEvent_boulder_lasered", params ); };
::McGameEvents.handlers["OnGameEvent_physics_visible"] <- function( params ) { ::McRegistry.DispatchEvent( "OnGameEvent_physics_visible", params ); };
::McGameEvents.handlers["OnGameEvent_physics_melee"] <- function( params ) { ::McRegistry.DispatchEvent( "OnGameEvent_physics_melee", params ); };
::McGameEvents.handlers["OnGameEvent_recommend_hold_position"] <- function( params ) { ::McRegistry.DispatchEvent( "OnGameEvent_recommend_hold_position", params ); };
::McGameEvents.handlers["OnGameEvent_scanner_important"] <- function( params ) { ::McRegistry.DispatchEvent( "OnGameEvent_scanner_important", params ); };
::McGameEvents.handlers["OnGameEvent_general_hint"] <- function( params ) { ::McRegistry.DispatchEvent( "OnGameEvent_general_hint", params ); };
::McGameEvents.handlers["OnGameEvent_movement_hint"] <- function( params ) { ::McRegistry.DispatchEvent( "OnGameEvent_movement_hint", params ); };
::McGameEvents.handlers["OnGameEvent_movement_hint_success"] <- function( params ) { ::McRegistry.DispatchEvent( "OnGameEvent_movement_hint_success", params ); };
::McGameEvents.handlers["OnGameEvent_alien_died"] <- function( params ) { ::McRegistry.DispatchEvent( "OnGameEvent_alien_died", params ); };
::McGameEvents.handlers["OnGameEvent_fast_reload"] <- function( params ) { ::McRegistry.DispatchEvent( "OnGameEvent_fast_reload", params ); };
::McGameEvents.handlers["OnGameEvent_fast_reload_fail"] <- function( params ) { ::McRegistry.DispatchEvent( "OnGameEvent_fast_reload_fail", params ); };
::McGameEvents.handlers["OnGameEvent_difficulty_changed"] <- function( params ) { ::McRegistry.DispatchEvent( "OnGameEvent_difficulty_changed", params ); };
::McGameEvents.handlers["OnGameEvent_achievement_earned"] <- function( params ) { ::McRegistry.DispatchEvent( "OnGameEvent_achievement_earned", params ); };
::McGameEvents.handlers["OnGameEvent_mission_success"] <- function( params ) {
    ::McRegistry.DispatchEvent( "OnGameEvent_mission_success", params );
    ::McRegistry.Dispatch( "Cleanup" );
};
::McGameEvents.handlers["OnGameEvent_mission_failed"] <- function( params ) {
    ::McRegistry.DispatchEvent( "OnGameEvent_mission_failed", params );
    ::McRegistry.Dispatch( "Cleanup" );
};
::McGameEvents.handlers["OnGameEvent_alien_hurt"] <- function( params ) { ::McRegistry.DispatchEvent( "OnGameEvent_alien_hurt", params ); };
::McGameEvents.handlers["OnGameEvent_marine_hurt"] <- function( params ) { ::McRegistry.DispatchEvent( "OnGameEvent_marine_hurt", params ); };
::McGameEvents.handlers["OnGameEvent_pickup_selected"] <- function( params ) { ::McRegistry.DispatchEvent( "OnGameEvent_pickup_selected", params ); };
::McGameEvents.handlers["OnGameEvent_sentry_selected"] <- function( params ) { ::McRegistry.DispatchEvent( "OnGameEvent_sentry_selected", params ); };
::McGameEvents.handlers["OnGameEvent_button_area_active"] <- function( params ) { ::McRegistry.DispatchEvent( "OnGameEvent_button_area_active", params ); };
::McGameEvents.handlers["OnGameEvent_button_area_inactive"] <- function( params ) { ::McRegistry.DispatchEvent( "OnGameEvent_button_area_inactive", params ); };
::McGameEvents.handlers["OnGameEvent_button_area_used"] <- function( params ) { ::McRegistry.DispatchEvent( "OnGameEvent_button_area_used", params ); };
::McGameEvents.handlers["OnGameEvent_jukebox_play_random"] <- function( params ) { ::McRegistry.DispatchEvent( "OnGameEvent_jukebox_play_random", params ); };
::McGameEvents.handlers["OnGameEvent_jukebox_stop"] <- function( params ) { ::McRegistry.DispatchEvent( "OnGameEvent_jukebox_stop", params ); };
::McGameEvents.handlers["OnGameEvent_level_up"] <- function( params ) { ::McRegistry.DispatchEvent( "OnGameEvent_level_up", params ); };
::McGameEvents.handlers["OnGameEvent_campaign_changed"] <- function( params ) { ::McRegistry.DispatchEvent( "OnGameEvent_campaign_changed", params ); };
::McGameEvents.handlers["OnGameEvent_swarm_state_changed"] <- function( params ) { ::McRegistry.DispatchEvent( "OnGameEvent_swarm_state_changed", params ); };
::McGameEvents.handlers["OnGameEvent_team_info"] <- function( params ) { ::McRegistry.DispatchEvent( "OnGameEvent_team_info", params ); };
::McGameEvents.handlers["OnGameEvent_team_score"] <- function( params ) { ::McRegistry.DispatchEvent( "OnGameEvent_team_score", params ); };
::McGameEvents.handlers["OnGameEvent_teamplay_broadcast_audio"] <- function( params ) { ::McRegistry.DispatchEvent( "OnGameEvent_teamplay_broadcast_audio", params ); };
::McGameEvents.handlers["OnGameEvent_player_team"] <- function( params ) { ::McRegistry.DispatchEvent( "OnGameEvent_player_team", params ); };
::McGameEvents.handlers["OnGameEvent_player_class"] <- function( params ) { ::McRegistry.DispatchEvent( "OnGameEvent_player_class", params ); };
::McGameEvents.handlers["OnGameEvent_player_death"] <- function( params ) { ::McRegistry.DispatchEvent( "OnGameEvent_player_death", params ); };
::McGameEvents.handlers["OnGameEvent_player_hurt"] <- function( params ) { ::McRegistry.DispatchEvent( "OnGameEvent_player_hurt", params ); };
::McGameEvents.handlers["OnGameEvent_player_chat"] <- function( params ) { ::McRegistry.DispatchEvent( "OnGameEvent_player_chat", params ); };
::McGameEvents.handlers["OnGameEvent_player_score"] <- function( params ) { ::McRegistry.DispatchEvent( "OnGameEvent_player_score", params ); };
::McGameEvents.handlers["OnGameEvent_player_spawn"] <- function( params ) { ::McRegistry.DispatchEvent( "OnGameEvent_player_spawn", params ); };
::McGameEvents.handlers["OnGameEvent_player_shoot"] <- function( params ) { ::McRegistry.DispatchEvent( "OnGameEvent_player_shoot", params ); };
::McGameEvents.handlers["OnGameEvent_player_use"] <- function( params ) { ::McRegistry.DispatchEvent( "OnGameEvent_player_use", params ); };
::McGameEvents.handlers["OnGameEvent_player_changename"] <- function( params ) { ::McRegistry.DispatchEvent( "OnGameEvent_player_changename", params ); };
::McGameEvents.handlers["OnGameEvent_player_hintmessage"] <- function( params ) { ::McRegistry.DispatchEvent( "OnGameEvent_player_hintmessage", params ); };
::McGameEvents.handlers["OnGameEvent_game_init"] <- function( params ) { ::McRegistry.DispatchEvent( "OnGameEvent_game_init", params ); };
::McGameEvents.handlers["OnGameEvent_game_newmap"] <- function( params ) { ::McRegistry.DispatchEvent( "OnGameEvent_game_newmap", params ); };
::McGameEvents.handlers["OnGameEvent_game_start"] <- function( params ) { ::McRegistry.DispatchEvent( "OnGameEvent_game_start", params ); };
::McGameEvents.handlers["OnGameEvent_game_end"] <- function( params ) { ::McRegistry.DispatchEvent( "OnGameEvent_game_end", params ); };
::McGameEvents.handlers["OnGameEvent_round_start"] <- function( params ) { ::McRegistry.DispatchEvent( "OnGameEvent_round_start", params ); };
::McGameEvents.handlers["OnGameEvent_round_end"] <- function( params ) { ::McRegistry.DispatchEvent( "OnGameEvent_round_end", params ); };
::McGameEvents.handlers["OnGameEvent_round_start_pre_entity"] <- function( params ) { ::McRegistry.DispatchEvent( "OnGameEvent_round_start_pre_entity", params ); };
::McGameEvents.handlers["OnGameEvent_teamplay_round_start"] <- function( params ) { ::McRegistry.DispatchEvent( "OnGameEvent_teamplay_round_start", params ); };
::McGameEvents.handlers["OnGameEvent_hostname_changed"] <- function( params ) { ::McRegistry.DispatchEvent( "OnGameEvent_hostname_changed", params ); };
::McGameEvents.handlers["OnGameEvent_finale_start"] <- function( params ) { ::McRegistry.DispatchEvent( "OnGameEvent_finale_start", params ); };
::McGameEvents.handlers["OnGameEvent_game_message"] <- function( params ) { ::McRegistry.DispatchEvent( "OnGameEvent_game_message", params ); };
::McGameEvents.handlers["OnGameEvent_break_breakable"] <- function( params ) { ::McRegistry.DispatchEvent( "OnGameEvent_break_breakable", params ); };
::McGameEvents.handlers["OnGameEvent_break_prop"] <- function( params ) { ::McRegistry.DispatchEvent( "OnGameEvent_break_prop", params ); };
::McGameEvents.handlers["OnGameEvent_entity_killed"] <- function( params ) { ::McRegistry.DispatchEvent( "OnGameEvent_entity_killed", params ); };
::McGameEvents.handlers["OnGameEvent_bonus_updated"] <- function( params ) { ::McRegistry.DispatchEvent( "OnGameEvent_bonus_updated", params ); };
::McGameEvents.handlers["OnGameEvent_player_stats_updated"] <- function( params ) { ::McRegistry.DispatchEvent( "OnGameEvent_player_stats_updated", params ); };
::McGameEvents.handlers["OnGameEvent_achievement_event"] <- function( params ) { ::McRegistry.DispatchEvent( "OnGameEvent_achievement_event", params ); };
::McGameEvents.handlers["OnGameEvent_achievement_write_failed"] <- function( params ) { ::McRegistry.DispatchEvent( "OnGameEvent_achievement_write_failed", params ); };
::McGameEvents.handlers["OnGameEvent_physgun_pickup"] <- function( params ) { ::McRegistry.DispatchEvent( "OnGameEvent_physgun_pickup", params ); };
::McGameEvents.handlers["OnGameEvent_flare_ignite_npc"] <- function( params ) { ::McRegistry.DispatchEvent( "OnGameEvent_flare_ignite_npc", params ); };
::McGameEvents.handlers["OnGameEvent_helicopter_grenade_punt_miss"] <- function( params ) { ::McRegistry.DispatchEvent( "OnGameEvent_helicopter_grenade_punt_miss", params ); };
::McGameEvents.handlers["OnGameEvent_user_data_downloaded"] <- function( params ) { ::McRegistry.DispatchEvent( "OnGameEvent_user_data_downloaded", params ); };
::McGameEvents.handlers["OnGameEvent_ragdoll_dissolved"] <- function( params ) { ::McRegistry.DispatchEvent( "OnGameEvent_ragdoll_dissolved", params ); };
::McGameEvents.handlers["OnGameEvent_gameinstructor_draw"] <- function( params ) { ::McRegistry.DispatchEvent( "OnGameEvent_gameinstructor_draw", params ); };
::McGameEvents.handlers["OnGameEvent_gameinstructor_nodraw"] <- function( params ) { ::McRegistry.DispatchEvent( "OnGameEvent_gameinstructor_nodraw", params ); };
::McGameEvents.handlers["OnGameEvent_map_transition"] <- function( params ) { ::McRegistry.DispatchEvent( "OnGameEvent_map_transition", params ); };
::McGameEvents.handlers["OnGameEvent_entity_visible"] <- function( params ) { ::McRegistry.DispatchEvent( "OnGameEvent_entity_visible", params ); };
::McGameEvents.handlers["OnGameEvent_set_instructor_group_enabled"] <- function( params ) { ::McRegistry.DispatchEvent( "OnGameEvent_set_instructor_group_enabled", params ); };
::McGameEvents.handlers["OnGameEvent_instructor_server_hint_create"] <- function( params ) { ::McRegistry.DispatchEvent( "OnGameEvent_instructor_server_hint_create", params ); };
::McGameEvents.handlers["OnGameEvent_instructor_server_hint_stop"] <- function( params ) { ::McRegistry.DispatchEvent( "OnGameEvent_instructor_server_hint_stop", params ); };
::McGameEvents.handlers["OnGameEvent_server_spawn"] <- function( params ) { ::McRegistry.DispatchEvent( "OnGameEvent_server_spawn", params ); };
::McGameEvents.handlers["OnGameEvent_server_pre_shutdown"] <- function( params ) { ::McRegistry.DispatchEvent( "OnGameEvent_server_pre_shutdown", params ); };
::McGameEvents.handlers["OnGameEvent_server_shutdown"] <- function( params ) { ::McRegistry.DispatchEvent( "OnGameEvent_server_shutdown", params ); };
::McGameEvents.handlers["OnGameEvent_server_cvar"] <- function( params ) { ::McRegistry.DispatchEvent( "OnGameEvent_server_cvar", params ); };
::McGameEvents.handlers["OnGameEvent_server_message"] <- function( params ) { ::McRegistry.DispatchEvent( "OnGameEvent_server_message", params ); };
::McGameEvents.handlers["OnGameEvent_server_addban"] <- function( params ) { ::McRegistry.DispatchEvent( "OnGameEvent_server_addban", params ); };
::McGameEvents.handlers["OnGameEvent_server_removeban"] <- function( params ) { ::McRegistry.DispatchEvent( "OnGameEvent_server_removeban", params ); };
::McGameEvents.handlers["OnGameEvent_player_connect"] <- function( params ) { ::McRegistry.DispatchEvent( "OnGameEvent_player_connect", params ); };
::McGameEvents.handlers["OnGameEvent_player_info"] <- function( params ) { ::McRegistry.DispatchEvent( "OnGameEvent_player_info", params ); };
::McGameEvents.handlers["OnGameEvent_player_disconnect"] <- function( params ) { ::McRegistry.DispatchEvent( "OnGameEvent_player_disconnect", params ); };
::McGameEvents.handlers["OnGameEvent_player_activate"] <- function( params ) { ::McRegistry.DispatchEvent( "OnGameEvent_player_activate", params ); };
::McGameEvents.handlers["OnGameEvent_player_connect_full"] <- function( params ) { ::McRegistry.DispatchEvent( "OnGameEvent_player_connect_full", params ); };
::McGameEvents.handlers["OnGameEvent_player_say"] <- function( params ) { ::McRegistry.DispatchEvent( "OnGameEvent_player_say", params ); };
::McGameEvents.handlers["OnGameEvent_hltv_status"] <- function( params ) { ::McRegistry.DispatchEvent( "OnGameEvent_hltv_status", params ); };
::McGameEvents.handlers["OnGameEvent_hltv_cameraman"] <- function( params ) { ::McRegistry.DispatchEvent( "OnGameEvent_hltv_cameraman", params ); };
::McGameEvents.handlers["OnGameEvent_hltv_rank_camera"] <- function( params ) { ::McRegistry.DispatchEvent( "OnGameEvent_hltv_rank_camera", params ); };
::McGameEvents.handlers["OnGameEvent_hltv_rank_entity"] <- function( params ) { ::McRegistry.DispatchEvent( "OnGameEvent_hltv_rank_entity", params ); };
::McGameEvents.handlers["OnGameEvent_hltv_fixed"] <- function( params ) { ::McRegistry.DispatchEvent( "OnGameEvent_hltv_fixed", params ); };
::McGameEvents.handlers["OnGameEvent_hltv_chase"] <- function( params ) { ::McRegistry.DispatchEvent( "OnGameEvent_hltv_chase", params ); };
::McGameEvents.handlers["OnGameEvent_hltv_message"] <- function( params ) { ::McRegistry.DispatchEvent( "OnGameEvent_hltv_message", params ); };
::McGameEvents.handlers["OnGameEvent_hltv_title"] <- function( params ) { ::McRegistry.DispatchEvent( "OnGameEvent_hltv_title", params ); };
::McGameEvents.handlers["OnGameEvent_hltv_chat"] <- function( params ) { ::McRegistry.DispatchEvent( "OnGameEvent_hltv_chat", params ); };
::McGameEvents.handlers["OnGameEvent_marine_incapacitated"] <- function( params ) { ::McRegistry.DispatchEvent( "OnGameEvent_marine_incapacitated", params ); };
::McGameEvents.handlers["OnGameEvent_marine_revived"] <- function( params ) { ::McRegistry.DispatchEvent( "OnGameEvent_marine_revived", params ); };
::McGameEvents.handlers["OnGameEvent_alien_spawn"] <- function( params ) { ::McRegistry.DispatchEvent( "OnGameEvent_alien_spawn", params ); };
::McGameEvents.handlers["OnGameEvent_buzzer_spawn"] <- function( params ) { ::McRegistry.DispatchEvent( "OnGameEvent_buzzer_spawn", params ); };
::McGameEvents.handlers["OnGameEvent_marine_spawn"] <- function( params ) { ::McRegistry.DispatchEvent( "OnGameEvent_marine_spawn", params ); };
::McGameEvents.handlers["OnGameEvent_colonist_spawn"] <- function( params ) { ::McRegistry.DispatchEvent( "OnGameEvent_colonist_spawn", params ); };
::McGameEvents.handlers["OnGameEvent_weapon_reload_finish"] <- function( params ) { ::McRegistry.DispatchEvent( "OnGameEvent_weapon_reload_finish", params ); };
::McGameEvents.handlers["OnGameEvent_heal_beacon_placed"] <- function( params ) { ::McRegistry.DispatchEvent( "OnGameEvent_heal_beacon_placed", params ); };
::McGameEvents.handlers["OnGameEvent_damage_amplifier_placed"] <- function( params ) { ::McRegistry.DispatchEvent( "OnGameEvent_damage_amplifier_placed", params ); };
::McGameEvents.handlers["OnGameEvent_weapon_fire"] <- function( params ) { ::McRegistry.DispatchEvent( "OnGameEvent_weapon_fire", params ); };
::McGameEvents.handlers["OnGameEvent_weapon_offhand_activate"] <- function( params ) { ::McRegistry.DispatchEvent( "OnGameEvent_weapon_offhand_activate", params ); };
::McGameEvents.handlers["OnGameEvent_laser_mine_active"] <- function( params ) { ::McRegistry.DispatchEvent( "OnGameEvent_laser_mine_active", params ); };
::McGameEvents.handlers["OnGameEvent_cluster_grenade_create"] <- function( params ) { ::McRegistry.DispatchEvent( "OnGameEvent_cluster_grenade_create", params ); };
::McGameEvents.handlers["OnGameEvent_tesla_trap_placed"] <- function( params ) { ::McRegistry.DispatchEvent( "OnGameEvent_tesla_trap_placed", params ); };
::McGameEvents.handlers["OnGameEvent_fire_mine_placed"] <- function( params ) { ::McRegistry.DispatchEvent( "OnGameEvent_fire_mine_placed", params ); };
::McGameEvents.handlers["OnGameEvent_laser_mine_placed"] <- function( params ) { ::McRegistry.DispatchEvent( "OnGameEvent_laser_mine_placed", params ); };
::McGameEvents.handlers["OnGameEvent_gas_grenade_placed"] <- function( params ) { ::McRegistry.DispatchEvent( "OnGameEvent_gas_grenade_placed", params ); };
::McGameEvents.handlers["OnGameEvent_flare_placed"] <- function( params ) { ::McRegistry.DispatchEvent( "OnGameEvent_flare_placed", params ); };
::McGameEvents.handlers["OnGameEvent_rocket_fired"] <- function( params ) { ::McRegistry.DispatchEvent( "OnGameEvent_rocket_fired", params ); };
::McGameEvents.handlers["OnGameEvent_fast_hack_success"] <- function( params ) { ::McRegistry.DispatchEvent( "OnGameEvent_fast_hack_success", params ); };
::McGameEvents.handlers["OnGameEvent_fast_hack_failed"] <- function( params ) { ::McRegistry.DispatchEvent( "OnGameEvent_fast_hack_failed", params ); };
::McGameEvents.handlers["OnGameEvent_entity_frozen"] <- function( params ) { ::McRegistry.DispatchEvent( "OnGameEvent_entity_frozen", params ); };
