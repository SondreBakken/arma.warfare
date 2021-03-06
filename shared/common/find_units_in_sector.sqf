ARWA_get_all_units_in_sector = {
	params ["_sector"];

	private _pos = getPos _sector;
	[_pos, ARWA_sector_size] call ARWA_get_all_units_in_area;
};

ARWA_any_enemies_in_sector = {
	params ["_side", "_pos"];
	[_pos, _side, ARWA_sector_size] call ARWA_any_enemies_in_area;
};

ARWA_any_enemies_in_sector_center = {
	params ["_side", "_pos"];
	[_pos, _side, ARWA_sector_size / 4] call ARWA_any_enemies_in_area;
};

ARWA_any_friendlies_in_sector = {
	params ["_side", "_pos", ["_touch_ground", true]];
	[_pos, _side, ARWA_sector_size, _touch_ground] call ARWA_any_friendlies_in_area;
};

ARWA_any_friendlies_in_sector_center = {
	params ["_side", "_pos"];
	[_pos, _side, ARWA_sector_size / 4] call ARWA_any_friendlies_in_area;
};