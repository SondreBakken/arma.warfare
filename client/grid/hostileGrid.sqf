close_to_any_owned_sectors = {
	params ["_pos", "_sector_boxes"];

	_is_close = 999999;

	{
		if((_x getVariable owned_by) isEqualTo playerSide) then {

			_is_close = _is_close min ((getPosWorld _x) distance2D _pos);
		};
	} forEach _sector_boxes;

	_is_close;
};

show_enemy_markers = {
	_enemy_markers_array = [];
	
	_sector_boxes = allMissionObjects "B_CargoNet_01_ammo_F";

	_enemies = factions - [playerSide];
	
	while {true} do {
		{deleteMarkerLocal _x;} count _enemy_markers_array;
		_enemy_markers_array = [];

		{
			if ((side _x) in _enemies) then {
				_markers_pos = getPosWorld (leader _x);

				_distance = [_markers_pos, _sector_boxes] call close_to_any_owned_sectors;

				if(_distance < 200) then {				

					_markers_posx = floor (_markers_pos select 0);
					_markers_posy = floor (_markers_pos select 1);

					_markers_name = format["_marker_grid_%1_%2", _markers_pos select 0, _markers_pos select 1];
					_markers_color = format["Color%1", side _x];
					
					_alpha = (200 - _distance) / 200;

					createMarkerLocal[_markers_name, _markers_pos];
					_markers_name setMarkerBrushLocal "SolidBorder"; 
					_markers_name setMarkerShapeLocal "ELLIPSE";
					_markers_name setMarkerSizeLocal [15,15];
					_markers_name setMarkerColorLocal _markers_color;
					_markers_name setMarkerAlphaLocal _alpha;
					_enemy_markers_array pushBack _markers_name;					
				};
			};
		} forEach allGroups;
		uiSleep (2);
	};	
};
