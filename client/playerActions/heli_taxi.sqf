heli_wait_period_on_despawn = 0; //300;
heli_wait_period_on_crash = 900;
heli_will_wait_time = 300;

heli_wait_period = heli_wait_period_on_despawn;
heli_price = 0; //200;

landing_marker = "landing";

heli_active = false;	
heli_timer = time;
heli_arrived_at_HQ = false;

show_send_heli_off_action = {
	player addAction ["Send off", {		
		private _heli = cursorTarget;
		private _group = group driver _heli;
		[_group, "Heading back to HQ"] spawn group_report_client;		
		heli_arrived_at_HQ = [_group, _heli] call take_off_and_despawn;
		systemChat "Sending helicopter to HQ";			
		
    }, nil, 1.5, true, true, "",
    '[cursorTarget] call is_heli_taxi'
    ];
};

show_order_heli_taxi = {  
  	player addAction ["Request heli pick-up", {
		
		if(!([] call check_if_can_afford_helicopter_transport)) exitWith {};
		if(!([] call check_if_transport_helicopter_available)) exitWith {};
		
		openMap true;
		onMapSingleClick {
			onMapSingleClick {}; 				        
			openMap false;

			systemChat "Ordering heli";

			heli_active = true;
			heli_arrived_at_HQ = false;
			[_pos, heli_price] spawn order_helicopter_taxi;	
			[_pos, landing_marker, "hd_pickup"] call create_heli_marker;
		};
		waitUntil {
			!visibleMap;
		};
		onMapSingleClick {};
		
    }, nil, 1.5, true, true, "",
    '[player] call can_order_heli && [player] call is_leader'
    ];
};

check_if_can_afford_helicopter_transport = {
	if(!(heli_price call check_if_can_afford)) exitWith {
		systemChat format["You cannot afford a heli pickup: %1$", heli_price];	
		false;			
	};
	true;
};

check_if_transport_helicopter_available = {
	private _time = time - heli_timer;
	if(_time < heli_wait_period) exitWith {
		private _time_left = heli_wait_period - _time;
		private _wait_minutes = ((_time_left - (_time_left mod 60)) / 60) + 1;	
		[playerSide, format["Helicopter transport is not available yet! Try again in %1 minutes", _wait_minutes]] spawn HQ_report_client;
		false;
	};
	true;
};

create_heli_marker = {
	params ["_pos", "_name", "_type"];
	createMarkerLocal [_name, _pos];
	_name setMarkerColorLocal "ColorBlack";
	_name setMarkerAlphaLocal 1;
	_name setMarkerTypeLocal _type;
};

order_helicopter_taxi = {
	params ["_pos", "_price"];

	private _arr = [side player] call spawn_transport_heli;
	private _heli = _arr select 0;
	private _group = _arr select 2;
	private _name = (typeOf _heli) call get_vehicle_display_name;	

	_heli spawn check_status;
	_heli setVariable ["taxi", true];
	_price call widthdraw_cash;

	[_group, "Transport heli is on its way to given pick up destination!"] spawn group_report_client;
	[_group, _heli, "GET IN", _pos] call land_helicopter; 

	if (canMove _heli) exitWith {
		[_group, "Transport heli has landed. Waiting for squad to pick up!"] spawn group_report_client;
		[heli_will_wait_time, _heli, _group] spawn on_heli_idle_wait;
		[_heli] spawn toggle_pilot_control;
	};
};

toggle_pilot_control = {
	params ["_heli"];

	private _pilot = driver _heli;
	private _group = group _pilot;
	private _pilot_type = typeOf _pilot;

	while {canMove _heli && alive _heli} do {
		waituntil {player in _heli};
		systemChat "put_player_in_pilot_position";
		[_group, _heli] call put_player_in_pilot_position;
		waitUntil {!(player in _heli)};
		systemChat "replace_player_with_pilot";
		[_pilot_type, _group, _heli] call replace_player_with_pilot;		
	};
};

replace_player_with_pilot = {
	params ["_pilot_type", "_group", "_heli"];

	private _pilot = _group createUnit [_pilot_type, [0,0,0], [], 0, "NONE"];
	_pilot moveInDriver _heli;
	_group deleteGroupWhenEmpty true;
	_heli lockDriver true;
	_heli engineOn true;

	[heli_will_wait_time, _heli, _group] spawn on_heli_idle_wait;
};

put_player_in_pilot_position = {
	params ["_group", "_heli"];

	_group deleteGroupWhenEmpty false;
	deleteVehicle (driver _heli);
	_heli lockDriver false;
	moveOut player;
	player moveInDriver _heli;
};

check_status = {
	params ["_heli"];

	waitUntil {!(alive _heli && canMove _heli)};
	sleep 3; // to make sure heli_active is updated
	systemChat "Heli state changed";
	if (!heli_arrived_at_HQ) then {
		if(!(player in _heli)) then {			
			[playerSide, "Transport heli is down! You are on your own!"] spawn HQ_report_client;
		};
		heli_wait_period = heli_wait_period_on_crash;
	} else {
		systemChat "Heli back at HQ";
		heli_wait_period = heli_wait_period_on_despawn;
	};

	heli_active = false;
	heli_timer = time;
	deleteMarkerLocal landing_marker;
};

on_heli_idle_wait = {
	params ["_wait_period", "_heli", "_group"];

	systemChat "on_heli_idle_wait";
	
	private _timer = time + _wait_period;
	waituntil {(player in _heli) || time > _timer};
	systemChat "wait time is up";
	

	if (!(player in _heli)) exitWith {
		systemChat "interrupt_heli_transport_misson";
		[_heli, _group] call interrupt_heli_transport_misson;
	};

	systemChat "but player is in heli";
};

interrupt_heli_transport_misson = {
	params ["_heli", "_group"];
		
	[_group, "We can't wait any longer! Transport heli is heading back to HQ!"] spawn group_report_client;
	_heli call empty_vehicle_cargo;
	deleteMarkerLocal landing_marker;
	heli_arrived_at_HQ = [_group, _heli] call take_off_and_despawn;
};

empty_vehicle_cargo = {
	params ["_heli"];
	systemChat "Empty transport heli";
	{
		if(!((group _x) isEqualTo (group _heli))) then {
			moveOut _x;			
		};
	} forEach crew _heli;	
};

can_order_heli = {
	!heli_active;
};

is_heli_taxi = {
	params ["_heli"];
	_heli getVariable ["taxi", false];
};