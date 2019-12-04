
ARWA_spawn_base_ammobox = {
	params ["_side"];

	private _marker = [_side, ARWA_KEY_respawn_ground] call ARWA_get_prefixed_name;
	private _pos = getMarkerPos _marker;
	private _ammo_box = ARWA_ammo_box createVehicle (_pos);
	_ammo_box enableRopeAttach false;

	_ammo_box setVariable [ARWA_KEY_HQ, true, true];

	_ammo_box setVariable [ARWA_KEY_owned_by, _side, true];
};

ARWA_initialize_bases = {
	{
		[_x] call ARWA_spawn_base_ammobox;
	} foreach ARWA_all_sides;
};