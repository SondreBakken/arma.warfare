ARWA_check_houses_to_populate = {
	params ["_player"];

	private _houses = (_player nearObjects ["house", ARWA_max_distance_presence]) - (_player nearObjects ["house", ARWA_min_distance_presence]);
	private _player_pos = getPos _player;
	private _player_side = side group _player;

	_houses = (_houses) call BIS_fnc_arrayShuffle;

	{
		private _house = _x;
		private _hq_pos = [_player_side] call ARWA_get_hq_pos;
		private _pos = getPos _house;
		private _distance_to_hq = _hq_pos distance2D _pos;

		if(_distance_to_hq > 1000 && {!(_house getVariable [ARWA_KEY_occupied, false])}) then {

			private _sector = [ARWA_sectors, _pos] call ARWA_find_closest_sector;
			private _owner = _sector getVariable ARWA_KEY_owned_by;
			private _sector_pos = getPos _sector;
			private _is_safe_area = _player_side isEqualTo _owner;

			private _sympathizer_side = if(_owner isEqualTo civilian || _is_safe_area) then {
				private _enemies = ARWA_all_sides - [_player_side];
				[_enemies, _pos] call ARWA_closest_hq;
			} else {
				_owner;
			};

			if([_pos, _sector_pos, _player_pos, _sympathizer_side, _is_safe_area] call ARWA_house_can_be_populated) then {
				[_sympathizer_side, _house, _owner, _is_safe_area, _player_side] call ARWA_populate_house;
			};
		};

		if(ARWA_max_random_people <= (count ARWA_random_people)) exitWith {};

	} forEach _houses;
};

ARWA_house_can_be_populated = {
	params ["_house_pos", "_sector_pos", "_player_pos", "_sympathizer_side", "_is_safe_area"];

	private _distance_from_sector = if(_is_safe_area) then { ARWA_sector_size * 2; } else { ARWA_sector_size/2 };
	(_sector_pos distance2D _house_pos) > _distance_from_sector && {!([_house_pos, _sympathizer_side, ARWA_min_distance_presence] call ARWA_any_enemies_in_area)}
};

ARWA_populate_house = {
	params ["_side", "_building", "_owner", "_is_safe_area", "_player_side"];

	private _allpositions = _building buildingPos -1;
	private _possible_spawns = (count _allpositions) min (ARWA_max_random_people - (count ARWA_random_people));
	private _random_number_of_people = ceil random [0, _possible_spawns/2, _possible_spawns];

	if(_random_number_of_people == 0) exitWith {};

	private _spawn_sympathizers = if(_is_safe_area || _owner isEqualTo civilian) then {
		[50] call ARWA_percent_chance;
	} else {
		[90] call ARWA_percent_chance;
	};

	if(_spawn_sympathizers) then {
		private _group = [_side, _random_number_of_people] call ARWA_spawn_sympathizers;
		[_building, _group] call ARWA_place_random_people_in_house;
		[_group, _building] spawn ARWA_remove_from_house_when_no_player_closeby;



		if([20] call ARWA_percent_chance) then {
			[_group] spawn ARWA_free_waypoint;
		};
	} else {
		private _group = [_random_number_of_people] call ARWA_spawn_civilians;
		[_building, _group] call ARWA_place_random_people_in_house;
		[_group, _building] spawn ARWA_remove_from_house_when_no_player_closeby;

		if([10] call ARWA_percent_chance) then {
			[_group] spawn ARWA_free_waypoint;
		};

	};
};

ARWA_place_random_people_in_house = {
	params ["_building", "_group"];
	private _allpositions = _building buildingPos -1;
	_allpositions = _allpositions call BIS_fnc_arrayShuffle;

	{
		_x setPosATL (_allpositions select _forEachIndex);
		ARWA_random_people pushBack _x;
	} forEach units _group;

	_group setBehaviour "SAFE";
};

ARWA_free_waypoint = {
	params ["_group"];

	if(isNil "_group" || {{ alive _x; } count units _group == 0}) exitWith {
		["Group does not exits. Not creating new waypoint"] call ARWA_debugger;
	};

	private _targets = allPlayers select { isTouchingGround (vehicle _x); };

	if(_targets isEqualTo []) exitWith {};

	private _target_distance = _targets apply { [(leader _group) distance2D _x, _x]; };
	_target_distance sort true;

	private _closest = _target_distance select 0;
	private _closest_player_distance = _closest select 0;

	private _closest_player = _closest select 1;
	private _closest_player_pos = getPos _closest_player;

	private _distance = if(side _group isEqualTo civilian) then {
		ARWA_max_distance_presence;
	} else {
		_closest_player_distance / 2;
	};

	private _waypoint_pos = [[[_closest_player_pos, _distance]],["water"]] call BIS_fnc_randomPos;

	private _w = _group addWaypoint [_waypoint_pos, 0];
	_w setWaypointCompletionRadius 25;
	_w setWaypointSpeed "LIMITED";

	[format["Random group moving from %1 to %2. Distance: %3", _waypoint_pos]] call ARWA_debugger;

	_w setWaypointStatements ["true","[group this] call ARWA_free_waypoint"];
	_w setWaypointType "MOVE";

	_group setBehaviour "SAFE";
	_group enableGunLights "ForceOn";
};

ARWA_remove_from_house_when_no_player_closeby = {
	params ["_group", "_house"];

	_house setVariable [ARWA_KEY_occupied, true];
	[_group, ARWA_max_distance_presence + 100] call ARWA_remove_when_no_player_closeby;
	_house setVariable [ARWA_KEY_occupied, nil];
};

ARWA_players_nearby = {
	params ["_pos", "_dist", ["_isTouchingGround", false]];

	allPlayers findIf { (_pos distance2D _x) < _dist && {!(_isTouchingGround) || isTouchingGround (vehicle _x)}; } != -1;
};
