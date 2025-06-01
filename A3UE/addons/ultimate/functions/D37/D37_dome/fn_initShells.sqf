if(!isServer) exitWith {};

//Optimized version of the shells initialization script 
private _shell = param[0];

//Preventive bullet skip
if(_shell isKindOf "BulletCore" or {_shell isKindOf "Grenade"}) exitWith {};

//Sometimes explosions pop here idk
if(isNull _shell) exitWith {};

//prevents missile and mines
if(_shell isKindOf "MissileCore" or _shell isKindOf "TimeBombCore") exitWith {};

//Currently initatizated shells
private _initializedShells = missionNamespace getVariable ["_initializedShells", []];

//Prevents double init, the EH only runs once
//if(_x in _initializedShells) exitWith {};

_shell spawn {
    private _shell = _this;
    private _fake = objNull;
    private _exitLoop = false;
    
    sleep 3;
    
    if (!alive _shell || isNull _shell) exitWith {
        ["_targetedShells", _shell, "remove"] call A3U_fnc_handleTargets;
        ["_initializedShells", _shell, "remove"] call A3U_fnc_handleTargets;
    };
    
    if ((_shell isKindOf "ShellBase") || (_shell isKindOf "SubmunitionBase")) then {
        private _pos = getpos _shell;

    	_fake = "CRAM_Fake_PlaneTGT" createVehicle _pos;
        _fake attachTo [_shell, [0,3,0]]; 
    };
    
	scopeName "something"; // Метка для breakTo
    // Основной цикл обнаружения угроз
    while {alive _shell && !_exitLoop} do {
		_fake attachTo [_shell, [0,3,0]]; 
        // Защита от пуль (CRAM)
        private _bullets = _shell nearObjects ["BulletBase", 8];
        if (count _bullets > 0) then {
            private _mine = createMine ["APERSMine", getPosATL _shell, [], 0];
            _mine setDamage 1;
            deleteVehicle _shell;
            _exitLoop = true;
        };
        
        if (_exitLoop) exitWith {};
        
        // Защита от ракет (перехватчиков)
        private _missiles = _shell nearObjects ["MissileBase", 25];
        {
            private _target = _x getVariable ["_chosenTarget", objNull];
            if (_target == _shell) then {
                triggerAmmo _x;
                private _mine = createMine ["APERSMine", getPosATL _shell, [], 0];
                _mine setDamage 1;
                deleteVehicle _shell;
                _exitLoop = true;
                breakTo "something"; // Выход из циклов
            };
        } forEach _missiles;
        
        sleep 0.08;
    };
    
    // Финализация
    if (!isNull _fake) then {
        detach _fake;
        deleteVehicle _fake;
    };
    
    if (!isNull _shell) then {
        ["_targetedShells", _shell, "remove"] call A3U_fnc_handleTargets;
        ["_initializedShells", _shell, "remove"] call A3U_fnc_handleTargets;
    };
};

_initializedShells pushBackUnique _shell;
missionNamespace setVariable ["_initializedShells", _initializedShells, true];
true;