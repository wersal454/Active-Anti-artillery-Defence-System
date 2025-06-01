private _unit       = param[0];
private _distance   = param[1, 6000];
private _tgtLogic 	= param[2, 1];
//Speed, guidance, N, ignore direct, time to max, delay between shots
private _weaponPar	= param[3, [420/3.6, 0, 4, false, 14, 0.85]];
private _typeArray 	= param[4, ["ShellBase","SubmunitionBase"]];

if(is3DEN) exitWith {};

//Stops previous dome script, starts new one
_unit setVariable ["DomeInit", false, true];
waitUntil {(_unit getVariable ["DomeRunning", false]) == false};
_unit setVariable ["DomeInit", true, true];

//Save values
_unit setVariable ["WeaponsPar", _weaponPar, true];
_unit setVariable ["DomeRunning", true, true];

if(!isServer) exitWith {};

_n = [0, 9] call BIS_fnc_randomInt;
sleep (0.1 * _n);

//Chase camera behind the missile 
allowAttach = false;

//Handle the missile
_unit addEventHandler ["Fired", {
	params ["_unit", "_weapon", "_muzzle", "_mode", "_ammo", "_magazine", "_projectile", "_gunner"];
	private _target = _unit getVariable ["currentTarget", objNull];
	private _parameters = _unit getVariable "WeaponsPar";

	if(!isNull _target) then {
		[_projectile, _parameters, _target] spawn A3U_fnc_handleMissile;
		_unit setVariable ["currentTarget", objNull, true];
	};
	

	//Attach a camera to themissile, made for the video
	if(allowAttach) then {
			_projectile spawn {
			allowAttach = false;

			_cam = "camera" camCreate (ASLToAGL eyePos player);
			_cam attachTo [_this, [3,-15,0]];
			_cam cameraEffect ["external", "back"];
			_cam camCommitPrepared 0;
			waitUntil { camCommitted _cam };


			waitUntil {!alive _this};
			_cam cameraEffect ["terminate", "back"];
			camDestroy _cam;
			allowAttach = true;
		};
	};
}];

//_unit setVehicleRadar 1;
_unit setVariable ["alarmEnabled", true, true];
//Toggle incoming alarm
_unit addAction ["Toggle alarm", {
	params ["_target", "_caller", "_actionId", "_arguments"];
	_state = !(_target getVariable ["alarmEnabled", true]);
	_target setVariable ["alarmEnabled", _state, true];

	_out = "";
	if(_state) then {
		_out = "ON";
	} else {
		_out = "OFF";
	};

	_id = owner _caller;
	["Alarm state: " + _out] remoteExec ["hint", _id];

}, nil, 9, false, false, "", "!(_this in _target)", 10];

//Change logic
_unit setVariable ["_tgtLogic", _tgtLogic, true];
_unit addAction ["Change targeting mode", {
	params ["_target", "_caller", "_actionId", "_arguments"];
	_tgtLogic = _target getVariable ["_tgtLogic", 0];

	_tgtLogic = _tgtLogic + 1;
	if(_tgtLogic > 3) then {
		_tgtLogic = 0;
	};

	_out = "";
	switch (_tgtLogic) do {
		case 0: {
			_out = "Random selection";
		};
		case 1: {
			_out = "Distance/Speed bias";
		};
		case 2: {
			_out = "Threat bias";
		};
		default {_out = "No targeting"};
	};

	_id = owner _caller;
	["Logic changed to: " + _out] remoteExec ["hint", _id];

	_target setVariable	["_tgtLogic", _tgtLogic, true];
}, nil, 10, false, false, "", "!(_this in _target)", 10];

//Makes it better 
{
	_x setSkill 1;
}foreach crew _unit;

//Performance optimizations
private _emptyLoops = 0;
private _delay = 0.5;

//If the launcher has to be pointed
private _needsAiming 	= _weaponPar select 3;
private _shotsDelay		= _weaponPar select 5;

/*
//Main loop
_loops = ((count _typeArray) - 1);
*/

//If a new dome is initialized
private _isActive = true;
private _timeActive = time;
private _sideDome = side _unit;

private _entities = [];
private _targetedShells = [];
private _ignored = [];

//PREFETCH THE ALARMS TO SAVE PERFORMANCE
private _alarms = _unit nearObjects ["NonStrategic", 2000];
_alarms = _alarms select {typeOf _x == "Land_Loudspeakers_F"};

//SOME DELAY SO THE MISSILES DONT FIRE AT ONCE
sleep(random(1));

//MAIN LOOP
while {alive _unit and (someAmmo _unit) and _isActive} do {
	if(time - _timeActive > 5) then {
		_isActive = _unit getVariable ["DomeInit",true];
		_timeActive = time;

		//Purge dead shells in _ignored
		_ignored = _ignored select {alive _x and !unitIsUAV _x or isNull _x};
	};

	_tgtLogic = _unit getVariable ["_tgtLogic", 0];
	private _entities = [];
	private _targetedShells = [];
	private _target = objNull;

	//Optimized detection, shells are now initialized on creation
	_entities = missionNamespace getVariable ["_initializedShells", []];
	_targetedShells = missionNamespace getVariable ["_targetedShells", []];

	//Only consider the close ones
	_entities = _entities select {_x distance2D _unit < _distance};

	//Disregard same side (see https://community.bistudio.com/wiki/Arma_3:_Mission_Event_Handlers#ArtilleryShellFired)
	_entities = _entities select {[(_x getVariable ["_shellSide", sideEnemy]), _sideDome] call BIS_fnc_sideIsEnemy};
	
	//Disregard already targetted
	_entities = _entities select {!(_x in _targetedShells)};

	//Disregard already targetted
	_entities = _entities select {!(_x in _ignored)};
	
	// Filtering, so we won't shoot down tank shells, planes and bombs
	_entities = _entities select {
		private _ammoType = typeOf _x;
    
		// Shooting down everything artillery or rockets, but NOT shooting tank shells, planes and bombs
		(_ammoType isKindOf "ShellBase" && !(_ammoType isKindOf "TankShell"))  // Artillery, but not tank ones
		|| (_ammoType isKindOf "MissileBase")  // Missiles
		|| (_ammoType isKindOf "RocketBase")   // Rocket based
		|| (_ammoType isKindOf "BulletBase" && {_ammoType find "artillery" > -1})  // Fix for CUP (search "artillery" in classname)
		|| (_ammoType isKindOf "SubmunitionBase")  // Fix for M5 Sandstorm (220 mm РСЗО)
		|| (_x isKindOf "UAV_02_base_F")  // Adding UAV
		|| (_x isKindOf "UAV_01_base_F")  // For CUP UAVs

		|| (typeOf _x in ["Lk_geran2", "Lk_shahed136", "Lk_shahed136_t", "shahed_238_CSAT"]) 
	};

	_entities = _entities select {
		if (_x isKindOf "UAV_02_base_F" || _x isKindOf "UAV_01_base_F") then {
			if (random 1 > 0.65) exitWith {false}; // 35% chance not to intercept
		};
		true
	};
	
	//Pick a target
	if(count _entities > 0) then {
		//IMPROVED LOGIC TO STOP OUTGOING TARGETS
		{
			if(unitIsUAV _x and (count (crew _x) > 0)) then {
				private _side = side _x;
				private _alt = (getPosATL _x) select 2;
				if(_side == side _unit or _alt < 5 or isTouchingGround _x) then {
					_ignored pushBack _x;
					private _id = (_entities find _x);
					if(_id != -1) then {
						_entities deleteAt _id;
					};
				};
			} else {
				private _vVer = (velocity _x) select 2;
				private _dist = _x distance2D _unit;
				if(_vVer > 50 and _dist < 300) then {
					_ignored pushBack _x;
					private _id = (_entities find _x);
					if(_id != -1) then {
						_entities deleteAt _id;
					};
				}; 
			};
		}forEach _entities;

		if(count _entities > 0) then {
			_target = [_entities, _unit, _tgtLogic] call A3U_fnc_pickTarget;

			if(!isNull _target) then {
				["_targetedShells", _target, "add"] call A3U_fnc_handleTargets;

				//Take over unit targetting
				{
					[_x, "AUTOTARGET"] remoteExec ["disableAI", owner _x];
				}forEach crew _unit;
			};
		};
	};

	if(!isNull _target) then {
		_emptyLoops = 0;
		_delay = 0.1 + _shotsDelay;

		//ALARM
		if(_unit getVariable ["alarmEnabled",false]) then {
			if (!(_unit getVariable ["alarmplaying",false])) then {
				_unit setVariable ["alarmplaying",true,true];

				{
					playSound3D ["x\A3UE\addons\core\cramalarm\cram.ogg", _x, false, (getposASL _x), 1, 1, 1500, 0, false];
				}forEach _alarms;

				playSound3D ["x\A3UE\addons\core\cramalarm\cram.ogg", _unit, false, (getposASL _unit), 2, 1, 2000, 0, false];
				_unit spawn {
					sleep 32;
					_this setVariable ["alarmplaying",false,true];
				};
			};
		};
		
		//Engagement logic
		_wep =  currentWeapon _unit;

		//Must aim
		if(_needsAiming) then {
			//Makes the launcher point upward
			private _pos = (getPosASL _target);
			_increment = 3500;

			//AIM above horizon 22 degrees
			if(_target isKindOf "ammo_Missile_CruiseBase") then {
				_increment = (_unit distance2D _target) * tan(15);
			};

			_pos set [2, (_pos select 2) + _increment ];
			_unit doWatch _pos;

			private _time = time;
			waitUntil {([_unit, _pos] call A3U_fnc_watchQuality > 0.80) or (time - _time) > 6};
			sleep 1;
		};
			
		if(!alive _target or isNull _target) then {
			["_targetedShells", _target, "remove"] call A3U_fnc_handleTargets; 
			continue;
		};

		//If this was aimed upward continue, else abort
		if((((_unit weaponDirection _wep) select 2) > 0.1) or !_needsAiming) then {
			//event handler takes care of the missile
			if(!isNull _target) then {
				_unit setVariable ["currentTarget", _target, true];
				//_unit fire _wep;
				[_unit, _wep] remoteExec ["Fire", owner _unit];
				sleep(0.1);

				//enable unit targetting
				{
					[_x, "AUTOTARGET"] remoteExec ["enableAI", owner _x];
				}forEach crew _unit;
			};

			//Safety cleanup 
			_target spawn {
				sleep 30;
				if(alive _this) then {
					["_targetedShells", _this, "remove"] call A3U_fnc_handleTargets;
				};
			};

			//Minimum delay between shots
			sleep _shotsDelay;	
		} else {
			isNil {
				["_targetedShells", _target, "remove"] call A3U_fnc_handleTargets;
			};
		};
	} else {
		_delay = 0.25;
	};
	sleep _delay;
};

{
	[_x, "AUTOTARGET"] remoteExec ["enableAI", owner _x];
}forEach crew _unit;

_unit doTarget objNull;
_unit doWatch objNull;
removeallActions _unit;

_unit setVariable ["DomeRunning", false, true];