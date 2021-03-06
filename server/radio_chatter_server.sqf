ARWA_calculate_deaths = {
	params ["_group"];

	private _curr_count = {alive _x} count units _group;
	private _prev_count = _group getVariable [ARWA_KEY_soldier_count, _curr_count];
	_group setVariable [ARWA_KEY_soldier_count , _curr_count];

	_prev_count - _curr_count;
};

ARWA_report_casualities_over_radio = {
	params ["_group"];
	private _deaths = [_group] call ARWA_calculate_deaths;

	if (_deaths > 0) exitWith {
		private _pos = getPos (leader _group);
		private _closest_sector = [ARWA_sectors, _pos] call ARWA_find_closest_sector;
		private _sector_pos = getPos _closest_sector;
		private _distance = floor(_sector_pos distance2D _pos);
		private _location = [_closest_sector getVariable ARWA_KEY_target_name] call ARWA_replace_underscore;

		if (_distance > 200) exitWith {
			private _direction = [_sector_pos, _pos] call ARWA_get_direction;
			[_group, _deaths, _distance, _direction, _location] remoteExec ["ARWA_report_casualities"];
		};

		[_group, _deaths, _location] remoteExec ["ARWA_report_casualities_in_sector"];
	};
};