if (!isServer) exitWith {};

// Получаем объект UAV
private _UAV = param[0];

if (isNull _UAV) exitWith {};
if !(unitIsUAV _UAV) exitWith {}; // Проверка, что это дрон

// Проверяем, не наш ли это БПЛА (не сбиваем союзные дроны)
if (side _UAV == side player) exitWith {};

// Получаем список уже обработанных целей
private _initializedShells = missionNamespace getVariable ["_initializedShells", []];

// Если UAV уже есть в списке, выходим
if (_UAV in _initializedShells) exitWith {};

// Добавляем в список, чтобы не обрабатывать повторно
_initializedShells pushBack _UAV;
missionNamespace setVariable ["_initializedShells", _initializedShells];

// 65% шанс на перехват  
private _chanceToIntercept = 0.65;  
if (random 1 <= _chanceToIntercept) then {  
    private _missile = createVehicle ["B_Interceptor_Missile", getPosATL _UAV, [], 0, "CAN_COLLIDE"];  
    _missile setVelocityModelSpace [0, 50, 0];  
    _missile setMissileTarget _UAV; // Используем setMissileTarget вместо doFire
};

// Запускаем процесс уничтожения UAV
_UAV spawn {
    private _UAV = _this;

    while {alive _UAV} do {
        private _entities = _UAV nearObjects ["MissileBase", 25];
    
        if (count _entities > 0) then {
            {
                private _target = _x getVariable ["_chosenTarget", objNull];
                if (_target == _UAV) then {
                    // Удаление из списков
                    ["_targetedShells", _UAV, "remove"] call A3U_fnc_handleTargets;
					["_initializedShells", _UAV, "remove"] call A3U_fnc_handleTargets;
                    
                    // Взрываем UAV и удаляем через 1 секунду
                    triggerAmmo _x; 
                    sleep 1;
                    deleteVehicle _UAV;  
                    break;
                };
            } forEach _entities;    
        };

        sleep 0.08; 
    };
};

true;