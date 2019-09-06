ARWA_create_manpower_box_unit = {
	params ["_victim"];
	private _manpower = _victim getVariable [ARWA_KEY_manpower, 0];

	if(_manpower > 0 || isPlayer _victim) then {
		_victim setVariable [ARWA_KEY_manpower, 0, true];
		private _manpower_box_value = if(isPlayer _victim) then {

			private _player_penalty = ARWA_starting_strength / 10;
			_player_penalty + _manpower;
		} else {
			_manpower;
		};

		if(!(isTouchingGround _victim)) then {
			sleep 30;
		};

		[_manpower_box_value, _victim] spawn ARWA_create_manpower_box;
	};
};

ARWA_create_manpower_box_vehicle = {
	params ["_victim"];
	private _manpower = _victim getVariable [ARWA_KEY_manpower, 0];

	if(_manpower > 0) then {
		_victim setVariable [ARWA_KEY_manpower, 0, true];
		private _side = _victim getVariable ARWA_KEY_owned_by;

		if(!(isTouchingGround _victim)) then {
			sleep 30;
		};

		[_manpower, _victim, _side] spawn ARWA_create_manpower_box;
	};
};

ARWA_create_manpower_box = {
	params ["_manpower", "_victim"];

	private _pos = getPos _victim;
	private _safe_pos = [_pos, 0, 5, 1, 1, 0, 0, [], [_pos, _pos]] call BIS_fnc_findSafePos;
	private _manpower_box = ARWA_manpower_box createVehicle (_safe_pos);
	_manpower_box setVariable [ARWA_KEY_manpower, _manpower, true];

	private _victim_side = side group _victim;
	private _color = [_victim_side, true] call BIS_fnc_sideColor;
	private _marker_name = format["%1-%2", ARWA_KEY_manpower_box, time];

	createMarker [_marker_name, _safe_pos];
	_marker_name setMarkerType "mil_dot";
	_marker_name setMarkerColor _color;
	_marker_name setMarkerAlpha 1;

	_marker_name setMarkerText format["%1 MP", _manpower];

	private _area_controlled_by = [_safe_pos] call ARWA_is_in_controlled_area;
	private _isWater = surfaceIsWater _safe_pos;

	if(!isNil "_area_controlled_by" && !_isWater) then {
		_manpower_box setVariable [ARWA_KEY_pos, _safe_pos];
		_manpower_box setVariable [ARWA_KEY_target_name, "manpower box"];
		[_area_controlled_by, _manpower_box] spawn ARWA_try_spawn_reinforcements;
	};

	[_marker_name, _manpower_box] spawn ARWA_manpower_deterioration;
	[_marker_name, _manpower_box] spawn ARWA_manpower_marker_update;
};

ARWA_manpower_marker_update = {
	params ["_marker_name", "_manpower_box"];

	private _manpower = _manpower_box getVariable [ARWA_KEY_manpower, 0];

	while {_manpower > 0} do {
		_marker_name setMarkerText format["%1 MP", _manpower];

		sleep 1;
		_manpower = _manpower_box getVariable [ARWA_KEY_manpower, 0];
	};

	deleteMarker _marker_name;

	sleep 60;
	deleteVehicle _manpower_box;
};

ARWA_manpower_deterioration = {
	params ["_marker_name", "_manpower_box"];

	sleep ARWA_dropped_manpower_deterioration_time;

	private _manpower = _manpower_box getVariable [ARWA_KEY_manpower, 0];

	while {_manpower > 0} do {
		sleep 10;
		_manpower = (_manpower_box getVariable [ARWA_KEY_manpower, 0]) - 1;
		_manpower_box setVariable [ARWA_KEY_manpower, _manpower, true];
	};
};