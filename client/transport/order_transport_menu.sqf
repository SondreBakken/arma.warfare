[] call compileFinal preprocessFileLineNumbers "client\transport\active_transport_menu.sqf";
[] call compileFinal preprocessFileLineNumbers "client\transport\air_transport.sqf";
[] call compileFinal preprocessFileLineNumbers "client\transport\ground_transport.sqf";
[] call compileFinal preprocessFileLineNumbers "client\transport\transport_common.sqf";

transport_options = [];

remove_all_transport_options = {
	{
		player removeAction _x;
	} forEach transport_options;

	transport_options = [];
};

show_order_transport = {
	params ["_title", "_type", "_priority"];
	missionNameSpace setVariable [format["transport_%1_menu", _type], false];	

  	player addAction [[_title, 0] call addActionText, {
		params ["_target", "_caller", "_actionId", "_arguments"];

		private _type = _arguments select 0;
		private _priority = _arguments select 1;
		private _open = missionNameSpace getVariable [format["transport_%1_menu", _type], false];

		[player] call remove_all_transport_options;
		if(!_open && {[_type] call transport_available}) then {	
			missionNameSpace setVariable [format["transport_%1_menu", _type], true];
			[_type, _priority] call show_transport_options;
		} else {
			missionNameSpace setVariable [format["transport_%1_menu", _type], false];	
		};	
    }, [_type, _priority], _priority, false, false, "",
    '!transport_active && [player] call is_leader'
    ];
};

show_transport_options = {
	params ["_type", "_priority"];

	private _side = side player;
	private _options = missionNamespace getVariable format["%1_%2_transport", _side, _type];

	{
		private _class_name = _x select 0;
		private _penalty = _x select 1;
		private _name = _class_name call get_vehicle_display_name;
		
		transport_options pushBack (player addAction [[_name, 2] call addActionText, {
			private _params = _this select 3;
			private _class_name = _params select 0;
			private _penalty = _params select 1;

			[player] call remove_all_transport_options;
			[_class_name, _penalty] call request_transport;
		}, [_class_name, _penalty], (_priority - 1), false, true]);
	} forEach _options;
};