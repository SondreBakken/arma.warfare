vehicle_transport_wait_period = 0;

send_vehicle_transport = {
	params ["_group", "_veh", "_pos"];

	_group move _pos;

	sleep 3;

	waitUntil { !(alive _veh) || (unitReady _veh) };
};

spawn_vehicle = {
	params ["_side", "_penalty"];

	private _base_marker_name = [_side, vehicle1] call get_prefixed_name;
	private _base_marker = missionNamespace getVariable _base_marker_name;

	private _pos = getPos _base_marker;

	waitUntil { !([_pos] call any_units_too_close); };

	private _veh = [_pos, getDir _base_marker, _class_name, _side] call BIS_fnc_spawnVehicle;

	(_veh select 0) lockDriver true;
	_veh;	
};

send_to_HQ = {
	params ["_group", "_veh"];
	
	private _side = side _group;
	private _pos = getMarkerPos ([_side, respawn_ground] call get_prefixed_name);

	_group addWaypoint [_pos, 100];
	
	waitUntil { !(alive _veh) || ((_pos distance2D (getPos _veh)) < 100) };
	
	if (alive _veh) exitWith
	{
		private _manpower = _veh getVariable [manpower, 0];

		if(_manpower > 0) then {
			[side player, _manpower] remoteExec ["buy_manpower_server", 2];
			systemChat format[localize "YOU_ADDED_MANPOWER", _manpower];     
		};

		[_veh] call remove_soldiers; 
		deleteVehicle _veh;
		true;
	};

	false;
};