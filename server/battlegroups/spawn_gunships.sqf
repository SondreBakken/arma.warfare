ARWA_spawn_gunship_groups = {
	{
		[_x] spawn ARWA_spawn_gunships;
	} foreach ARWA_all_sides;
};

ARWA_find_target_sectors = {
	params ["_side"];

	([_side] call ARWA_find_enemy_sectors) + ([_side] call ARWA_get_unsafe_sectors);
};

ARWA_spawn_gunships = {
	params ["_side"];

	while {true} do {

		private _tier = [_side] call ARWA_get_tier;
		private _wait_time = ARWA_tier_base_gunship_respawn_time + (random (missionNamespace getVariable format["ARWA_tier_%1_gunship_respawn_time", _tier]));

		sleep _wait_time;

		if(_side call ARWA_has_manpower && !ARWA_cease_fire) then {
			private _sectors = [_side] call ARWA_find_target_sectors;

			if ((count _sectors) == 0) exitWith {};

			private _gunship = [_side] call ARWA_spawn_gunship_group;
			if (isNil "_gunship") exitWith {};
			[_gunship select 2] spawn ARWA_add_battle_group;
		};

	};
};

ARWA_spawn_gunship_group = {
	params ["_side"];

	private _options = [_side, ARWA_KEY_helicopter] call ARWA_get_units_based_on_tier;

	if((_options isEqualTo [])) exitWith {};

	private _random_selection = selectRandom _options;
	private _gunship = _random_selection select 0;
	private _kill_bonus = _random_selection select 1;
	private _gunship_name = _gunship call ARWA_get_vehicle_display_name;

	[_side, ["ARWA_STR_SENDING_VEHICLE_YOUR_WAY", _gunship_name]] remoteExec ["ARWA_HQ_report_client"];
	sleep 120;

	format ["%1: Spawn gunship: %2", _side, _gunship_name] spawn ARWA_debugger;
	format["%1 manpower: %2", _side, [_side] call ARWA_get_strength] spawn ARWA_debugger;
	[_side, _gunship, _kill_bonus, ARWA_gunship_spawn_height] call ARWA_spawn_helicopter;
};
