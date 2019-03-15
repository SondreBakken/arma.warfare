arwa_uav_options = [];
arwa_active_uav = nil;
arwa_cancel_uav_id = nil;

remove_all_drone_options = {
	{
		player removeAction _x;
	} forEach arwa_drone_options;

	arwa_drone_options = [];
};

has_uav_terminal = {
	private _uav_terminal_class_name = missionNameSpace getVariable format["%1_uav_terminal_class_name", playerSide];

	_uav_terminal_class_name in assignedItems player;
};

show_order_drone = {
	params ["_title", "_priority"];
	missionNameSpace setVariable ["drone_menu", false];	

	player addAction [[_title, 0] call addActionText, {
		params ["_target", "_caller", "_actionId", "_arguments"];

		private _priority = _arguments select 0;
		private _open = missionNameSpace getVariable ["drone_menu", false];

		[player] call remove_all_drone_options;
		if(!_open) then {	
			missionNameSpace setVariable ["drone_menu", true];
			[_priority] call show_drone_options;
		} else {
			missionNameSpace setVariable ["drone_menu", false];	
		};	
		}, [_priority], _priority, false, false, "",
		'[player] call is_leader && !arwa_drone_active && [] call has_uav_terminal'
	];
};

show_drone_options = {
	params ["_priority"];

	private _side = playerSide;
	private _options = missionNamespace getVariable format["%1_uavs", _side];

	{
		private _class_name = _x select 0;
		private _penalty = _x select 1;
		private _name = _class_name call get_vehicle_display_name;
		
		arwa_drone_options pushBack (player addAction [[_name, 2] call addActionText, {
			private _params = _this select 3;
			private _class_name = _params select 0;
			private _penalty = _params select 1;

			[player] call remove_all_drone_options;
			[_class_name, _penalty] call order_drone;
		}, [_class_name, _penalty], (_priority - 1), false, true, "", 
		'[player] call is_leader && !arwa_drone_active && [] call has_uav_terminal']);
	} forEach _options;
};

order_drone = {
	params ["_class_name", "_penalty"];

	private _arr = [playerSide, _class_name, _penalty] call spawn_drone;
	private _uav = _arr select 0;
	private _group = _arr select 2;
	private _name = (typeOf _uav) call get_vehicle_display_name;	
	
	[_uav, _group] spawn cancel_drone_on_player_death;
	[_uav] call show_cancel_drone_action;
	[_uav] spawn check_drone_status;

	[_group, _uav, "DRONE_ON_ITS_WAY"] spawn move_drone_to_player;
};

move_drone_to_player = {
	params ["_group", "_uav", "_msg"];

	if(!([_uav] call is_drone_active)) exitWith {};
	
	[_group, [_msg]] spawn group_report_client;	
	
	
	_w = _group addWaypoint [getPos player, 5];
	
	_w setWaypointType "LOITER";
	_w setWaypointLoiterType "CIRCLE";
	_w setWaypointLoiterRadius 200;
};

is_drone_dead = {
	params ["_uav"];

	private _is_dead = (isNull _uav) ||  {!alive _uav} || {!canMove _uav};

	if(_is_dead) then {
		player removeAction arwa_cancel_drone_id;
		arwa_drone_active = false;
	};

	_is_dead;
};

is_drone_active = {
	params ["_uav"];

	private _is_active = !([_uav] call is_drone_dead) && {!(_uav getVariable ["is_done", false])};

	if(_is_active) then {
		player removeAction arwa_cancel_drone_id;		
	};

	_is_active;
};

check_drone_status = {
	params ["_uav"];

	waitUntil {
		([_uav] call is_drone_dead);
	};

	if(isNull _uav) exitWith {};
	
	[playerSide, ["DRONE_DOWN"]] spawn HQ_report_client; // TODO make classname specific
	
};

cancel_drone_on_player_death = {
	params ["_uav", "_group"];
	waituntil {!([_uav] call is_drone_active) || !(alive player)};

	if(!([_uav] call is_drone_active)) exitWith {};
		
	[_uav, _group, "CANCELING_DRONE_MISSION", true] call interrupt_drone_misson;
};

show_cancel_drone_action = {
	params ["_uav"];

	arwa_cancel_drone_id = player addAction [[localize "SEND_DRONE_TO_HQ", 0] call addActionText, {	
		params ["_target", "_caller", "_actionId", "_arguments"];

		private _uav = _arguments select 0;
		private _group = group driver _uav;

		[_uav, _group, "HEAD_TO_HQ"] call interrupt_drone_misson;
    }, [_uav], arwa_active_drone_actions, true, false, "",
    ''];
};

spawn_drone = {
	params ["_side", "_class_name", "_penalty"];

	private _pos = getMarkerPos ([_side, respawn_air] call get_prefixed_name);
	private _base_pos = getMarkerPos ([_side, respawn_ground] call get_prefixed_name);
	private _dir = _pos getDir _base_pos;
	private _pos = [_pos select 0, _pos select 1, (_pos select 2) + 1000];

	waitUntil { [_pos] call is_air_space_clear; };

    private _drone = [_pos, _dir, _class_name, _side] call BIS_fnc_spawnVehicle;

	player connectTerminalToUAV _drone;

	arwa_drone_active = true;
	
	private _uav = _drone select 0;

	_uav setVariable [arwa_penalty, [_side, _penalty], true];
	_uav setVariable [arwa_kill_bonus, _penalty, true];

	_uav;
};

interrupt_drone_misson = {
	params ["_uav", "_group", "_msg"];

	player connectTerminalToUAV objNull;
	player disableUAVConnectability [_uav,true];
	player removeAction (_uav getVariable ["_cancel_drone_id", nil]);

	[_group, [_msg]] spawn group_report_client;
		
	private _success = [_group, _uav] call take_off_and_despawn;

	if(_success) then {
		[playerSide, ["DRONE_ARRIVED_IN_HQ"]] spawn HQ_report_client;
	};	
};

