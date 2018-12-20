decrement_counter = {
	params ["_counter", "_sector", "_side"];

	if(_counter > 0) exitWith {		
		[_counter - 1, _sector, _side] spawn update_progress_bar;
		_counter - 1;		
	};
	
	[0, _sector, civilian] spawn update_progress_bar;
	
	_counter;
};

increment_counter = {
	params ["_counter", "_sector", "_side"];

	if(_counter < arwa_capture_time) exitWith {		
		[_counter + 1, _sector, _side] spawn update_progress_bar;
		_counter + 1;
	};
	_counter;
};

capture_sector = {
	params ["_sector", "_new_owner", "_sector_name", "_old_owner"];

	_sector setVariable ["reinforements_available", true];

	_msg = format[localize "HAS_CAPTURED_SECTOR", _new_owner call get_faction_names, _sector_name];
	_msg remoteExec ["hint"]; 

	[_sector, _new_owner, _sector_name, _old_owner] call change_sector_ownership;
};

lose_sector = {
	params ["_sector", "_old_owner", "_sector_name"];

	_sector setVariable ["reinforements_available", false];
	_msg = format[localize "HAS_LOST_SECTOR", _old_owner call get_faction_names, _sector_name];
	_msg remoteExec ["hint"]; 

	[_sector, civilian, _sector_name, _old_owner] call change_sector_ownership;
};

change_sector_ownership = {
	params ["_sector", "_new_owner", "_sector_name", "_previous_faction"];
	
	_old_owner = _sector getVariable owned_by;
	_sector setVariable [owned_by, _new_owner, true];
	_sector call draw_sector;

	_ammo_box = _sector getVariable box;		
	_ammo_box setVariable [owned_by, _new_owner, true];

	if (!(_old_owner isEqualTo civilian)) then {
		_sector call remove_respawn_position;	
		[_old_owner, _sector] call remove_sector;
	};

	if(!(_new_owner isEqualTo civilian)) then {
		[_sector, _new_owner] call add_respawn_position;		
		[_new_owner, _sector] call add_sector;
	};

	[_new_owner, _previous_faction, _sector, _sector_name] call reset_sector_manpower;
};

reinforcements_cool_down = {
	params ["_sector"];

	_sector setVariable ["reinforements_available", false];
	private _current_owner = _sector getVariable owned_by;

	sleep arwa_respawn_cooldown;

	if((_sector getVariable owned_by) isEqualTo _current_owner) exitWith {
		_sector setVariable ["reinforements_available", true];
	};
};

initialize_sector_control = {
	params ["_sector"];
	
	private _pos = _sector getVariable pos;
	private _counter = 0;
	private _current_faction = _sector getVariable owned_by;
	_sector setVariable ["reinforements_available", false];
	private _sector_name = [_sector getVariable sector_name] call replace_underscore;
	private _report_attack = true;
	private _old_owner = civilian;

	while {true} do {	
		private _owner = _sector getVariable owned_by;

		if (_owner isEqualTo civilian) then {
			private _units = [_sector] call get_all_units_in_sector;

			if(count _units == 0) exitWith { _counter = [_counter, _sector, _current_faction] call decrement_counter; }; // if no units, no change

			private _factions = arwa_all_sides select {_x countSide _units > 0};
			if(count _factions > 1) exitWith { _counter = [_counter, _sector, _current_faction] call decrement_counter; }; // if more than one faction present, no change

			// Get the only faction in sector
			private _faction = _factions select 0;
			if(!([_faction, _pos] call any_friendlies_in_sector_center)) exitWith { _counter = [_counter, _sector, _current_faction] call decrement_counter; }; // no units in sector center, no change

			if(_current_faction isEqualTo _faction) then {
				if(_counter == arwa_capture_time) then {					
					[_sector, _current_faction, _sector_name, _old_owner] call capture_sector;
				} else {
					_counter = [_counter, _sector, _current_faction] call increment_counter;
				}

			} else {
				if(_counter == 0) then {
					_current_faction = _faction;
				} else {
					 _counter = [_counter, _sector, _current_faction] call decrement_counter;
				};
			};
		} else {
			private _under_attack = ([_owner, _pos] call any_enemies_in_sector);
			private _being_overtaken = ([_owner, _pos] call any_enemies_in_sector_center);

			if(_under_attack) then {
					if(_sector getVariable "reinforements_available") then {
					private _success = [_owner, _sector] call try_spawn_heli_reinforcements;

					if(_success) then {
						[_sector] spawn reinforcements_cool_down;				 
					};

					if(_report_attack && _counter == arwa_capture_time) then {
						_report_attack = false;
						[_owner, ["SECTOR_IS_UNDER_ATTACK", _sector_name]] remoteExec ["HQ_report_client"];
					};
				};
			};

			if(!_being_overtaken) exitWith { 
				if(!_under_attack) exitWith {
					_counter = [_counter, _sector, _owner] call increment_counter; 

					if(_counter == arwa_capture_time) then {
						_report_attack = true;
					};
				};
			};
		
			if(_counter == 0) then {
				_old_owner = _current_faction;
				[_sector, _current_faction, _sector_name] call lose_sector;
			} else {						
				_counter = [_counter, _sector, _owner] call decrement_counter; 
			};

		};

		sleep 1;
	};
};