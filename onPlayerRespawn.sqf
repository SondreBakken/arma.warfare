private _fatigue = ["Fatigue", 0] call BIS_fnc_getParamValue;

if(_fatigue == 0) then {
	player enableStamina false;
} else {
	player enableStamina true;
};

[] spawn ARWA_create_join_menu;
[] spawn ARWA_take_lead_menu;
[] spawn ARWA_leave_squad;
[] spawn ARWA_add_take_manpower;
[] spawn ARWA_add_store_manpower;
[] spawn ARWA_show_order_uav;

[localize "ARWA_STR_GET_VEHICLE_SUPPORT", ARWA_KEY_vehicle, ARWA_ground_vehicle_menu] call ARWA_create_support_menu;
[localize "ARWA_STR_GET_HELICOPTER_SUPPORT", ARWA_KEY_helicopter, ARWA_air_vehicle_menu] call ARWA_create_support_menu;
[localize "ARWA_STR_GET_INFANTRY_SUPPORT", ARWA_KEY_infantry, ARWA_infantry_menu] call ARWA_create_support_menu;

if(ARWA_allow_interceptors) then {
	[localize "ARWA_STR_GET_INTERCEPTORS", ARWA_KEY_interceptor, ARWA_interceptor_menu] call ARWA_create_support_menu;
};

[player] spawn ARWA_remove_vehicle_action;

[localize "ARWA_STR_REQUEST_AIR_TRANSPORT", ARWA_KEY_helicopter, ARWA_air_transport_actions] spawn ARWA_show_order_transport;
[localize "ARWA_STR_REQUEST_VEHICLE_TRANSPORT", ARWA_KEY_vehicle, ARWA_ground_transport_actions] spawn ARWA_show_order_transport;

remove_squad_mates_on_death = {
	params ["_player"];

	private _group = group _player;

	if(count units _group > 1) then {
		[player] joinSilent grpNull;
		[_group] remoteExec ["ARWA_add_battle_group", 2];
	};

	[group player] remoteExec ["ARWA_add_battle_group", 2];
	[_group] spawn ARWA_delete_all_waypoints;
	[0.5, _group] spawn ARWA_adjust_skill;
};

reset_player_stats = {
	params ["_player"];

	_player setCustomAimCoef 1;
	_player setUnitRecoilCoefficient 1;
	_player setStamina 60;

	_player setUnitRank ARWA_KEY_rank1;
	_player setVariable [ARWA_KEY_manpower, 0, true];
	_player setVariable [ARWA_KEY_owned_by, playerSide, true];
};

[player] call reset_player_stats;
[player] call remove_squad_mates_on_death;

if(ARWA_show_diary_hint) then {
	ARWA_show_diary_hint = false;
	"HOW TO PLAY" hintC "Look in map briefing for how to play";
};
