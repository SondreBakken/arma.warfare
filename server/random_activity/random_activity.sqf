ARWA_random_enemies = [];
ARWA_houses_already_checked = [];

ARWA_populate_random_houses = {
	while {true} do {
		ARWA_random_enemies = [ARWA_random_enemies] call ARWA_remove_null;

		if(ARWA_max_random_enemies > (count ARWA_random_enemies)) then {
			private _players = allPlayers call BIS_fnc_arrayShuffle;
			{
				private _player = _x;
				private _class_name = typeOf (vehicle _player);

				if(!([_class_name, ARWA_KEY_interceptor] call ARWA_is_type_of)) then {
					[_player] call ARWA_check_houses_to_populate;
				};
			} forEach _players;

			ARWA_houses_already_checked = [];
		};

		sleep 10;
	};
};

ARWA_check_houses_to_populate = {
	params ["_player"];

	private _houses = (_player nearObjects ["house", ARWA_max_distance_presence]) - (_player nearObjects ["house", ARWA_min_distance_presence]);
	private _player_pos = getPos _player;

	_houses = _houses - ARWA_houses_already_checked;
	_houses = (_houses) call BIS_fnc_arrayShuffle;

	{
		private _house = _x;
		private _sector = [ARWA_sectors, getPos _house] call ARWA_find_closest_sector;
		private _owner = _sector getVariable ARWA_KEY_owned_by;
		private _hq_pos = getMarkerPos ([side _player, ARWA_KEY_respawn_ground] call ARWA_get_prefixed_name);
		private _pos = getPos _house;
		private _distance_to_hq = _hq_pos distance2D _pos;
		private _is_safe_area = side _player isEqualTo _owner;

		if(_distance_to_hq > ARWA_min_distance_presence) then {

			private _sympathizer_side = if(_owner isEqualTo civilian || _is_safe_area) then {
				private _enemies = ARWA_all_sides - [side _player];
				[_enemies, _pos] call ARWA_closest_hq;
			} else {
				_owner;
			};

			if([_house, _player_pos, _player, _sector, _sympathizer_side, _is_safe_area] call ARWA_house_can_be_populated) then {
				[_sympathizer_side, _house, _owner, _is_safe_area] call ARWA_populate_house;
			};
		};

		if(ARWA_max_random_enemies <= (count ARWA_random_enemies)) exitWith {};

	} forEach _houses;

	ARWA_houses_already_checked append _houses;
};



ARWA_house_can_be_populated = {
	params ["_building", "_player_pos", "_player", "_sector", "_sympathizer_side", "_is_safe_area"];

	private _pos = getPos _building;
	private _sector_pos = _sector getVariable ARWA_KEY_pos;
	private _distance_from_sector = if(_is_safe_area) then { ARWA_sector_size * 1.5; } else { ARWA_sector_size/2 };

	(_sector_pos distance2D _pos) > _distance_from_sector
	&& {!(_building getVariable [ARWA_KEY_occupied, false])}
	&& {!([_pos, _sympathizer_side, ARWA_min_distance_presence] call ARWA_any_enemies_in_area)}
};

ARWA_pick_random_group = {
	params ["_side", "_random_number_of_soldiers", "_controlled_by", "_is_safe_area"];

	private _spawn_sympathizers = if(_is_safe_area) then { random 100 < ARWA_chance_of_enemy_presence_in_controlled_area; } else { selectRandom[true, false]; };

	if(_spawn_sympathizers) exitWith {
		private _commander = _random_number_of_soldiers >  ARWA_required_sympathizers_for_commander_spawn && (selectRandom[true, false, _controlled_by in ARWA_all_sides]);
		format["Spawn %1 %2 sympathizers", _random_number_of_soldiers, _side] spawn ARWA_debugger;
		private _group = [[0,0,0], _side, _random_number_of_soldiers, _commander] call ARWA_spawn_sympathizers;

		if(_commander) then {
			[playerSide, ["ARWA_STR_ENEMY_COMMANDER_IN_AREA"]] remoteExec ["ARWA_HQ_report_client"];
			[leader _group] spawn ARWA_commander_state;
		};

		_group;
	};

	format["Spawn %1 civilians", _random_number_of_soldiers] spawn ARWA_debugger;
	[[0,0,0], _random_number_of_soldiers] call ARWA_spawn_civilians;
};

ARWA_commander_state = {
	params ["_commander"];

	waitUntil { isNull _commander || {!alive _commander} };

	if(isNull _commander) exitWith {
		sleep 60 + (random 60);
		[playerSide, ["ARWA_STR_ENEMY_COMMANDER_LOST"]] remoteExec ["ARWA_HQ_report_client"];
	};
	sleep 5 + (random 5);
	[playerSide, ["ARWA_STR_ENEMY_COMMANDER_KILLED"]] remoteExec ["ARWA_HQ_report_client"];
};

ARWA_populate_house = {
	params ["_side", "_building", "_controlled_by", "_is_safe_area"];

	private _allpositions = _building buildingPos -1;
	private _possible_spawns = (count _allpositions) min (ARWA_max_random_enemies - (count ARWA_random_enemies));
	private _random_number_of_soldiers = ceil random [0, _possible_spawns/2, _possible_spawns];

	_building setVariable [ARWA_KEY_occupied, true];

	if(_random_number_of_soldiers == 0) exitWith {};

	private _group = [_side, _random_number_of_soldiers, _controlled_by, _is_safe_area] call ARWA_pick_random_group;

	_group setBehaviour "SAFE";

	_allpositions = _allpositions call BIS_fnc_arrayShuffle;

	{
		_x setPosATL (_allpositions select _forEachIndex);
		ARWA_random_enemies pushBack _x;
	} forEach units _group;

	[_group] spawn ARWA_remove_nvg_and_add_flash_light;
	[_group, _building] spawn ARWA_remove_when_no_player_closeby;
};

ARWA_remove_when_no_player_closeby = {
	params ["_group", "_house"];

	private _pos = getPos (leader _group);

	waitUntil {!([_pos, ARWA_max_distance_presence] call ARWA_players_nearby)};

	{
		deleteVehicle _x;
	} forEach units _group;

	deleteGroup _group;
	_house setVariable [ARWA_KEY_occupied, nil];
};

ARWA_players_nearby = {
	params ["_pos", "_dist"];

	({ (_pos distance2D _x) < _dist; } count allPlayers) > 0;
};