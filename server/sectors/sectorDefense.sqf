spawn_defensive_squad = {
	params ["_sector"];

	private _side = _sector getVariable owned_by;
	private _pos = _sector getVariable pos;
    private _group = [[_pos select 0, _pos select 1, 3000], _side, defender_cap call calc_number_of_soldiers, true] call spawn_infantry;
	
	[_group, _pos] call place_defensive_soldiers;

    _group setBehaviour "SAFE";

	_group;
};

place_defensive_soldiers = {
	params ["_group","_pos"];

	private _positions = [_pos] call get_positions_to_populate;
	private _units = units _group;
	
	{
		if (_forEachIndex < (count _positions)) then {
			(_x) setPosATL (_positions select _forEachIndex);
		} else {
			private _safe_pos = [_pos, 0, 25, 5, 0, 0, 0] call BIS_fnc_findSafePos;	
			(_x) setPos _safe_pos;
		}

	} forEach _units;
};

get_positions_to_populate = {
	params ["_pos"];
	
	private _houses = _pos nearObjects ["house", 25];

	private _positions = [];

	{
		_positions = _positions + (_x buildingPos -1);
	} forEach _houses;

	_positions call BIS_fnc_arrayShuffle;
};

spawn_artillery = {
	params ["_sector"];
	private _side = _sector getVariable owned_by;

	private _orientation = random 360;	
	private _type = selectRandom (missionNamespace getVariable format["%1_artillery", _side]);
	private _sector_pos = _sector getVariable pos;
	private _pos = [_sector_pos, 5, 25, 7, 10, 0, 0,[_sector_pos, _sector_pos]] call BIS_fnc_findSafePos;
				
	if(!(_pos isEqualTo _sector_pos)) exitWith {
		private _artillery = [_pos, _orientation, _type, _side] call BIS_fnc_spawnVehicle;
		private _group = _artillery select 2;
		_group deleteGroupWhenEmpty true;
		_group enableDynamicSimulation false; 

		private _name = _artillery select 0;
		_name addeventhandler ["fired", {(_this select 0) setvehicleammo 1}];

		_artillery;
	};	
};

should_spawn_artillery = {
	params ["_sector", "_sector_owner"];

	private _artillery = _sector getVariable artillery;	

	if(isNil "_artillery") exitWith {
		true;
	};

	private _group = _artillery select 2;

	if(side _group isEqualTo _sector_owner && ({alive _x} count units _group) > 0) exitWith {
		false;
	};

	true;
};

should_remove_artillery = {
	params ["_sector", "_sector_owner"];

	private _artillery = _sector getVariable artillery;	
	if(isNil "_artillery") exitWith {
		false;
	};

	private _group = _artillery select 2;
	if(!(side _group isEqualTo _sector_owner) || ({alive _x} count units _group) == 0) exitWith {
		true;
	};

	false;
};

spawn_artillery_pos = {
	params ["_sector"];

	if([_sector, _side] call should_remove_artillery) then {
		private _artillery = _sector getVariable artillery;
		deleteVehicle (_artillery select 0);
	};

	if([_sector, _side] call should_spawn_artillery) then {
		_new_artillery = _sector call spawn_artillery;	

		if (!(isNil "_new_artillery")) then {
			_sector setVariable [artillery, _new_artillery];	
		};
	};
};

calc_number_of_soldiers = {
	params ["_soldier_cap"];
	floor random [_soldier_cap / 2, _soldier_cap / 1.5, _soldier_cap];
};

spawn_reinforcments = {
	params ["_sector", "_defenders", "_side"];
	
    private _group_count = {alive _x} count units _defenders;

	private _new_soldiers = 0 max ((defender_cap call calc_number_of_soldiers) - _group_count);

    private _pos = _sector getVariable pos;	
    private _group = [[_pos select 0, _pos select 1, 3000], _side, _new_soldiers, true] call spawn_infantry;
	
	[_group, _pos] call place_defensive_soldiers;

    {[_x] joinSilent _defenders} forEach units _group;
	deleteGroup _group;
	_defenders;
};

spawn_sector_squad = {
	params ["_sector"];

	sleep 10; // So you wont hit them with your car!

	private _side = _sector getVariable owned_by;
	private _sector_defense = _sector getVariable sector_def;

	if(isNil "_sector_defense") exitWith {
		_defensive_squad = [_sector] call spawn_defensive_squad;	
		_sector setVariable [sector_def, _defensive_squad];
		_defensive_squad call add_defensive_group;
	}; 	

	if (side _sector_defense isEqualTo _side) exitWith {
		_defensive_squad = [_sector, _sector_defense, _side] call spawn_reinforcments;
		_defensive_squad call add_defensive_group;
	};

	if(!(side _sector_defense isEqualTo _side)) exitWith {
		if({alive _x} count units _sector_defense > 0) then {
			_sector_defense call remove_defensive_group;
			_sector_defense call add_battle_group;
		};

		_defensive_squad = [_sector] call spawn_defensive_squad;	
		_sector setVariable [sector_def, _defensive_squad];
	};
};

spawn_sector_defense = {
	params ["_sector"];
	_sector call spawn_sector_squad;
	_sector call spawn_artillery_pos;
	//_sector call spawn_patrol_squad;
};