if(!isServer) exitWith {};

//Optimized version of the shells initialization script 
private _shell = param[0];

//Sometimes explosions pop here idk
if(isNull _shell) exitWith {};

//Currently initatizated shells
private _initializedShells = missionNamespace getVariable ["_initializedShells", []];

_shell setVariable ["isMissile", true, true];

_shell spawn {
    private _shell = _this;
    private _fake = objNull;
    private _exitLoop = false;
    
    private _initializedShells = missionNamespace getVariable ["_initializedShells", []];
    _initializedShells pushBackUnique _shell;
    missionNamespace setVariable ["_initializedShells", _initializedShells, true];
    
    sleep 3;
    
    if (!alive _shell || isNull _shell) exitWith {
        ["_targetedShells", _shell, "remove"] call A3U_fnc_handleTargets;
        ["_initializedShells", _shell, "remove"] call A3U_fnc_handleTargets;
    };

	private _pos = getpos _shell;
    
    _fake = "CRAM_Fake_PlaneTGT" createVehicle _pos;
    _fake attachTo [_shell, [0,3,0]];
    
	scopeName "something"; // Метка для breakTo
    // Основной цикл обнаружения угроз
    while {alive _shell && !_exitLoop} do {
		_fake attachTo [_shell, [0,3,0]]; 
        // Защита от пуль (CRAM)
        private _bullets = _shell nearObjects ["BulletBase", 5];
        if (count _bullets > 0) then {
            createMine ["APERSMine", getPosATL _shell, [], 0] setDamage 1;
            deleteVehicle _shell;
            _exitLoop = true;
        };
        
        if (_exitLoop) exitWith {};
        
        // Защита от ракет
        private _missiles = _shell nearObjects ["MissileBase", 30];
        _missiles = _missiles select { !(_x getVariable ["isMissile", false]) }; // Фильтрация своих ракет
        
        {
            if ((_x getVariable ["_chosenTarget", objNull]) isEqualTo _shell) then {
                triggerAmmo _x; // Активируем ракету
                createMine ["APERSMine", getPosATL _shell, [], 0] setDamage 1;
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

_initializedShells pushback _shell;
missionNamespace setVariable ["_initializedShells", _initializedShells, true];
true;