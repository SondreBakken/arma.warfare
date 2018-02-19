initialize_faction_stats = {
	West call initialize_faction;
	East call initialize_faction;
	independent call initialize_faction;
};

initialize_faction = {
	params ["_side"];

	[_side, starting_strength] call set_strength;
	[_side, 0] call set_income;
	[_side, 0] call set_kill_count;
	[_side, 0] call set_tier;
	[_side, 0] call set_tier_progress;	
};

calculate_tier_progress = {
	params ["_side"];
	
	_kill_count = _side call get_kill_count;
	_tier =  ([_side] call get_tier) + 1;

	_tier_bound =  if(_tier == 0) then { 0; } else { _tier call get_tier_bound; };
	_next_tier_bound = (_tier + 1) call get_tier_bound

	_percentage = floor(((_kill_count - _tier_bound) / (_next_tier_bound - _tier_bound)) * 100);

	[_side, 99 min _percentage] call set_tier_progress;
};

increment_kill_counter = {
	private params ["_side", "_kill_point"];
	private _tier =  _side call get_tier;

	if(_tier < 3) exitWith {
		private _new_kill_count = [_side] call get_kill_count + _kill_point;		

		[_new_kill_count, _side] call increment_tier;
		[_new_kill_count, _side] call set_kill_count;
		[_side] call CalculatePercentageTilNextTier;
	};
}; 

increment_tier = {
	private params ["_kill_count", "_side"];

	private _tier = (_side call get_tier) + 1;
	private _next_tier = tier + 1;
	private _tier_bound = format["tier_%1", next_tier];

	if(_kill_count > tier_bound) exitWith {
		private _msg = format["%1 advanced to tier %2", _side, next_tier];
		_msg remoteExec ["hint"]; 
		
		[_side, _next_tier] call set_tier;
	};
};


