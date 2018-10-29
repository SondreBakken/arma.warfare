
spawn_base_ammobox = {
	params ["_side"];

	private _marker = [_side, respawn_ground] call get_prefixed_name;	
	private _pos = getMarkerPos _marker;	 
	private _ammo_box = ammo_box createVehicle (_pos);

	_ammo_box setVariable [owned_by, _side, true];
	_ammo_box call add_arsenal_action;
	_ammo_box call add_halo_action;
	_ammo_box call add_manpower_action;
	[_ammo_box, "Get vehicle", vehicle1, 110] call create_menu;
	[_ammo_box, "Get helicopter", helicopter, 120] call create_menu;
	[_ammo_box, "Get infantry", infantry, 130] call create_menu;	
};

initialize_bases = {
	[WEST] call spawn_base_ammobox;	
	[EAST] call spawn_base_ammobox;	
	[independent] call spawn_base_ammobox;	
};