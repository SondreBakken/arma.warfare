
vehicle_create_waypoint = {
	params ["_target", "_group"];
	private _pos = [(_target getVariable pos), 0, 25, 5, 0, 0, 0] call BIS_fnc_findSafePos;

	// TODO if in sector, its not safe. Change to waypoint type SAD 
	_group call delete_all_waypoints; 
	_w = _group addWaypoint [_pos, 20];
	_w setWaypointStatements ["true","[group this] call delete_all_waypoints"];

	_w setWaypointType "MOVE";
	_group setBehaviour "SAFE";
		
	_group setSpeedMode "NORMAL";
	_group setCombatMode "YELLOW";
	_group setVariable ["target", _target];	
};

initialize_vehicle_group_ai = {
	params ["_group"];

	private _side = side _group;

	while{[_group] call group_is_alive} do {

		if([_group] call group_should_be_commanded) then {
			[_group, _side] spawn vehicle_group_ai;
		};

		sleep 10;
	};
};

vehicle_move_to_sector = {
	params ["_new_target", "_group"];

	if ([_group, _new_target] call should_change_target) then {
		[_new_target, _group] call vehicle_create_waypoint;	
	};

	if ([_group] call needs_new_waypoint) then {
		private _target = _group getVariable "target";
		[_target, _group] call vehicle_create_waypoint;	
	};

	if ([_group] call approaching_target) then {	
		_group setSpeedMode "LIMITED";
		_group setBehaviour "AWARE";
		_group setCombatMode "RED";
	};		
};

vehicle_group_ai = {
	params ["_group", "_side"];

	private _pos = getPosWorld (leader _group);

	private _target = if([_group, _side] call check_if_has_priority_target) then {
		_group getVariable priority_target;
	} else {		
		_group setVariable [priority_target, nil];
		[_side, _pos] call get_ground_target;			
	};
	
	[_target, _group] spawn vehicle_move_to_sector;
	[_group] spawn report_casualities_over_radio;
};
