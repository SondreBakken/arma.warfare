ARWA_close_to_any_owned_sectors = {
	params ["_pos", "_sector_boxes"];

	_is_close = 999999;

	{
		if((_x getVariable ARWA_KEY_owned_by) isEqualTo playerSide) then {

			_is_close = _is_close min ((getPos _x) distance2D _pos);
		};
	} forEach _sector_boxes;

	_is_close;
};

ARWA_create_unit_marker = {
	params ["_group", "_alpha", "_marker_name", "_markers_pos"];

	_markers_name = format["_marker_%1_%2_%3", _marker_name, _markers_pos select 0, _markers_pos select 1];
	_markers_color = format["Color%1", side _group];

	createMarkerLocal[_markers_name, _markers_pos];
	_markers_name setMarkerBrushLocal "SolidBorder";
	_markers_name setMarkerShapeLocal "ELLIPSE";
	_markers_name setMarkerSizeLocal [15,15];
	_markers_name setMarkerAlphaLocal _alpha;
	_markers_name setMarkerColorLocal _markers_color;

	_markers_name;
};

ARWA_create_named_unit_marker = {
	params ["_group", "_alpha", "_marker_name", "_markers_pos"];

	_markers_name = format["_named_marker_%1_%2_%3", _marker_name, _markers_pos select 0, _markers_pos select 1];
	_markers_color = format["Color%1", side _group];

	createMarkerLocal[_markers_name, [(_markers_pos select 0) + 15, _markers_pos select 1, (_markers_pos select 2)  + 15]];
	_markers_name setMarkerTypeLocal "mil_box";
	_markers_name setMarkerSizeLocal [0,0];
	_markers_name setMarkerColorLocal _markers_color;
	_markers_name setMarkerTextLocal ([_group] call ARWA_get_unit_marker_text);

	_markers_name;
};

ARWA_get_unit_marker_text = {
	params ["_group"];

	private _veh = vehicle leader _group;
	private _is_veh = (_veh isKindOf "Car" || _veh isKindOf "Air" || _veh isKindOf "Tank");

	_split_string = [groupId _group, 0] call ARWA_split_string;
	_first_string = _split_string select 0;
	_second_string = _split_string select 1;

	_alive_count = {alive _x} count units _group;

	if (_is_veh) exitWith {
		private _class_name = typeOf _veh;
		private _veh_name = _class_name call ARWA_get_vehicle_display_name;
		format["%1 %2 - %3", _alive_count, _second_string, _veh_name];
	};

	format["%1 %2", _alive_count, _second_string];
};

ARWA_any_alive = {
	params ["_group"];

	({ alive _x; }count units _group) > 0;
};

ARWA_show_friendly_markers = {
	_markers_array = [];
	_sector_boxes = allMissionObjects ARWA_ammo_box;
	_marker_name = "friendly";

	while {true} do {
		{
			deleteMarkerLocal _x;
		} count _markers_array;

		_markers_array = [];

		{
			private _leader = leader _x;
			private _sympathizers = _leader getVariable [ARWA_KEY_sympathizers, false];

			if (ARWA_show_all
				|| (_x call ARWA_any_alive)
				&& !_sympathizers
				&& ((side _x) isEqualTo playerSide)
				&& (!(_x getVariable [ARWA_KEY_defense, false]))
				&& ((_leader distance2D [0,0]) > 100)) then {

				_markers_pos = getPos (_leader);

				_distance = [_markers_pos, _sector_boxes] call ARWA_close_to_any_owned_sectors;
				_alpha = 1 min (_distance / ARWA_sector_size);

				_markers_array pushBack ([_x, _alpha, _marker_name, _markers_pos] call ARWA_create_unit_marker);
				_markers_array pushBack ([_x, _alpha, _marker_name, _markers_pos] call ARWA_create_named_unit_marker);

			};
		} forEach allGroups;
		uiSleep (0.1);
	};
};
