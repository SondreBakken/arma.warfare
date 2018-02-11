DeleteAllWaypoints = {
	_group = _this select 0;

	while {(count (waypoints _group)) > 0} do
	{
		deleteWaypoint ((waypoints _group) select 0);
	};
};

AttackEnemySector = {
	_battle_group = _this select 0;
	_side = side _battle_group;
	_other_sector_count = [_side] call OtherSectorCount;

	if (_other_sector_count > 0) then {
		_leader_pos = getPos (leader _battle_group);

		_target_sector = [_side, _leader_pos] call FindClosestOtherSector;

		[_battle_group] call DeleteAllWaypoints;
		_wp1 = _battle_group addWaypoint [getPos _target_sector, 0];
		_wp1 setWaypointType "SAD";
		_battle_group setBehaviour "AWARE";
		_battle_group enableDynamicSimulation false;

		_battle_group setVariable ["target", _target_sector];
	} else {
		// defend?
	};
};

while {true} do {
	{		
		if (!(player isEqualTo leader _x)) then {
			_side = side _x; 

			_target_sector = _x getVariable ["target", "undefined"];

			if (_target_sector isEqualTo "undefined") then {
				_new_target = [_x] call AttackEnemySector;
			} else {
				_current_owner = _target_sector getVariable "faction";
				
				if (_side isEqualTo _current_owner) then {
					[_x] call AttackEnemySector; 
					
				};
			};
		}; 
		
	} forEach ([] call GetAllBattleGroups);
	sleep 10;
};
