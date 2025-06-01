class CfgFunctions
{
    class A3U
    {
        class D37Dome
        {
            class guidanceLaws 
            {
                file = QPATHTOFOLDER(functions\D37\D37_dome\fn_guidanceLaws.sqf);
            };
            class handleDome 
            {
                file = QPATHTOFOLDER(functions\D37\D37_dome\fn_handleDome.sqf);
            };
            class handleMissile 
            {
                file = QPATHTOFOLDER(functions\D37\D37_dome\fn_handleMissile.sqf);
            };
            class handleTargets 
            {
                file = QPATHTOFOLDER(functions\D37\D37_dome\fn_handleTargets.sqf);
            };
            class handleUAV 
            {
                file = QPATHTOFOLDER(functions\D37\D37_dome\fn_handleUAV.sqf);
            };
            class initMissile 
            {
                file = QPATHTOFOLDER(functions\D37\D37_dome\fn_initMissile.sqf);
            };
            class initShells 
            {
                file = QPATHTOFOLDER(functions\D37\D37_dome\fn_initShells.sqf);
            };
            class pickTarget 
            {
                file = QPATHTOFOLDER(functions\D37\D37_dome\fn_pickTarget.sqf);
            };
            class postInitEH 
            {
                file = QPATHTOFOLDER(functions\D37\D37_dome\fn_postInitEH.sqf);
                postInit	= 1;
            };
            class watchQuality 
            {
                file = QPATHTOFOLDER(functions\D37\D37_dome\fn_watchQuality.sqf);
            };
        };
        class D37cram
        {
            class handleCRAM 
            {
                file = QPATHTOFOLDER(functions\D37\D37_cram\fn_handleCRAM.sqf);
            };
        };
    };
};
