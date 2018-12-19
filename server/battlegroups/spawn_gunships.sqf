spawn_gunship_groups = {
	[West] spawn spawn_gunships;
	[East] spawn spawn_gunships;
	[independent] spawn spawn_gunships;
};

find_target_sectors = {
	params ["_side"];
	
	([_side] call find_enemy_sectors) + ([_side] call get_unsafe_sectors);
};

spawn_gunships = {
	params ["_side"];
	
	while {_side in active_factions} do {
		private _tier = [_side] call get_tier;
		private _wait_time = tier_base_gunship_respawn_time + (random (missionNamespace getVariable format["tier_%1_gunship_respawn_time", _tier]));
		
		sleep _wait_time;

		private _sectors = [_side] call find_target_sectors;

		if ((count _sectors) == 0) exitWith {};

		private _gunship = [_side] call spawn_gunship_group;
		if (isNil "_gunship") exitWith {};
		[_gunship select 2] spawn add_battle_group;							
	};
};

spawn_gunship_group = {
	params ["_side"];

	private _options = [_side, helicopter] call get_units_based_on_tier;

	if((_options isEqualTo [])) exitWith {};

	private _gunship = (selectRandom _options) select 0; 
	private _gunship_name = _gunship call get_vehicle_display_name;

	[_side, ["SENDING_VEHICLE_YOUR_WAY", _gunship_name]] remoteExec ["HQ_report_client"];
	sleep 120;

	[_side, _gunship] call spawn_helicopter;
};
