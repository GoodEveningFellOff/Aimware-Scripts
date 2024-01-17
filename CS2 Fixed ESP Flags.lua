gui.Reference("Visuals", "Overlay", "Enemy", "Flags", "Planting"):SetDisabled(false)
gui.Reference("Visuals", "Overlay", "Enemy", "Flags", "Reloading"):SetDisabled(false)
gui.Reference("Visuals", "Overlay", "Enemy", "Flags", "Flashed"):SetDisabled(false)
gui.Reference("Visuals", "Overlay", "Enemy", "Flags", "Has C4"):SetDisabled(false)

gui.Reference("Visuals", "Overlay", "Friend", "Flags", "Planting"):SetDisabled(false)
gui.Reference("Visuals", "Overlay", "Friend", "Flags", "Reloading"):SetDisabled(false)
gui.Reference("Visuals", "Overlay", "Friend", "Flags", "Flashed"):SetDisabled(false)
gui.Reference("Visuals", "Overlay", "Friend", "Flags", "Has C4"):SetDisabled(false)

local g_iLocalTeam = 0;

local g_bVisualsMaster = false;

local g_stEnemyData = {
    m_sDrawFuncName = "AddTextTop";

    m_bPlanting = false;
    m_clrPlanting = {0, 0, 0, 0};

    m_bReloading = false;
    m_clrReloading = {0, 0, 0, 0};
    
    m_bFlashed = false;
    m_clrFlashed = {0, 0, 0, 0};

    m_bHasC4 = false;
    m_clrHasC4 = {0, 0, 0, 0};
};

local g_stFriendlyData = {
    m_sDrawFuncName = "AddTextTop";
    
    m_bPlanting = false;
    m_clrPlanting = {0, 0, 0, 0};

    m_bReloading = false;
    m_clrReloading = {0, 0, 0, 0};

    m_bFlashed = false;
    m_clrFlashed = {0, 0, 0, 0};

    m_bHasC4 = false;
    m_clrHasC4 = {0, 0, 0, 0};
};

local g_aDrawPositions = {
    ["0"] = "AddTextTop";
    ["1"] = "AddTextBottom";
    ["2"] = "AddTextLeft";
    ["3"] = "AddTextRight";
    ["4"] = "AddTextTop";
};

local g_bPlanting = false;
local g_sBombOwnerName = "";

local g_aReloadingPlayers = {};

callbacks.Register("Draw", function()
    local pLocalPlayer = entities.GetLocalPlayer();
    if pLocalPlayer then
        g_iLocalTeam = pLocalPlayer:GetTeamNumber();
    end

    local aC_C4 = entities.FindByClass("C_C4");
    local bFoundCarrier = false;
    for _, pEnt in pairs(aC_C4) do
        local pOwner = pEnt:GetPropEntity("m_hOwnerEntity");

        if pOwner then
            g_bPlanting = pEnt:GetPropBool("m_bStartedArming");
            g_sBombOwnerName = pOwner:GetName();
            bFoundCarrier = true;
            break;
        end
    end

    if not bFoundCarrier then
        g_sBombOwnerName = "";
    end


    g_aReloadingPlayers = {};

    local aGuns = entities.FindByClass("C_BasePlayerWeapon");
    for _, pEnt in pairs(aGuns) do
        if pEnt:GetPropBool("m_bInReload") then
            local pOwner = pEnt:GetPropEntity("m_hOwnerEntity");

            if pOwner then
                g_aReloadingPlayers[pOwner:GetName()] = true;
            end
        end
    end

    g_bVisualsMaster = gui.GetValue("esp.master");

    -- ENEMY --
    g_stEnemyData.m_sDrawFuncName = g_aDrawPositions[gui.GetValue("esp.overlay.enemy.flags.anchor")] or "AddTextTop";

    g_stEnemyData.m_bPlanting = gui.GetValue("esp.overlay.enemy.flags.planting");
    g_stEnemyData.m_clrPlanting = { gui.GetValue("esp.overlay.enemy.flags.planting.clr") };

    g_stEnemyData.m_bReloading = gui.GetValue("esp.overlay.enemy.flags.reloading");
    g_stEnemyData.m_clrReloading = { gui.GetValue("esp.overlay.enemy.flags.reloading.clr") };

    g_stEnemyData.m_bFlashed = gui.GetValue("esp.overlay.enemy.flags.flashed");
    g_stEnemyData.m_clrFlashed = { gui.GetValue("esp.overlay.enemy.flags.flashed.clr") };

    g_stEnemyData.m_bHasC4 = gui.GetValue("esp.overlay.enemy.flags.hasc4");
    g_stEnemyData.m_clrHasC4 = { gui.GetValue("esp.overlay.enemy.flags.hasc4.clr") };

    -- FRIENDLY --
    g_stFriendlyData.m_sDrawFuncName = g_aDrawPositions[gui.GetValue("esp.overlay.friendly.flags.anchor")] or "AddTextTop";

    g_stFriendlyData.m_bPlanting = gui.GetValue("esp.overlay.friendly.flags.planting");
    g_stFriendlyData.m_clrPlanting = { gui.GetValue("esp.overlay.friendly.flags.planting.clr") };

    g_stFriendlyData.m_bReloading = gui.GetValue("esp.overlay.friendly.flags.reloading");
    g_stFriendlyData.m_clrReloading = { gui.GetValue("esp.overlay.friendly.flags.reloading.clr") };

    g_stFriendlyData.m_bFlashed = gui.GetValue("esp.overlay.friendly.flags.flashed");
    g_stFriendlyData.m_clrFlashed = { gui.GetValue("esp.overlay.friendly.flags.flashed.clr") };

    g_stFriendlyData.m_bHasC4 = gui.GetValue("esp.overlay.friendly.flags.hasc4");
    g_stFriendlyData.m_clrHasC4 = { gui.GetValue("esp.overlay.friendly.flags.hasc4.clr") };
end)

callbacks.Register("DrawESP", function(ctx)
    local pEnt = ctx:GetEntity();

    if not pEnt or not g_bVisualsMaster then
        return;
    end

    if not pEnt:IsPlayer() then
        return;
    end

    local stConfigData = (pEnt:GetTeamNumber() ~= g_iLocalTeam) and g_stEnemyData or g_stFriendlyData;
    local fnDrawText = ctx[stConfigData.m_sDrawFuncName] or ctx.AddTextTop;

    local sEntName = pEnt:GetName();
    local bIsBombCarrier = (sEntName == g_sBombOwnerName);

    if stConfigData.m_bPlanting and bIsBombCarrier and g_bPlanting then
        ctx:Color(stConfigData.m_clrPlanting[1], 
            stConfigData.m_clrPlanting[2], 
            stConfigData.m_clrPlanting[3], 
            stConfigData.m_clrPlanting[4]);
        
        
        fnDrawText(ctx, "PLANT"); 
    end

    if stConfigData.m_bReloading and g_aReloadingPlayers[sEntName] then
        ctx:Color(stConfigData.m_clrReloading[1], 
            stConfigData.m_clrReloading[2], 
            stConfigData.m_clrReloading[3], 
            stConfigData.m_clrReloading[4]);
        
        
        fnDrawText(ctx, "RELOAD"); 
    end

    if stConfigData.m_bFlashed and pEnt:GetPropFloat("m_flFlashOverlayAlpha") > 200 then
        ctx:Color(stConfigData.m_clrFlashed[1], 
            stConfigData.m_clrFlashed[2], 
            stConfigData.m_clrFlashed[3], 
            stConfigData.m_clrFlashed[4]);
        
        fnDrawText(ctx, "FLASH"); 
    end

    if stConfigData.m_bHasC4 and bIsBombCarrier then
        ctx:Color(stConfigData.m_clrHasC4[1], 
            stConfigData.m_clrHasC4[2], 
            stConfigData.m_clrHasC4[3], 
            stConfigData.m_clrHasC4[4]);
        
        
        fnDrawText(ctx, "C4"); 
    end
end)

callbacks.Register("Unload", function()
    gui.Reference("Visuals", "Overlay", "Enemy", "Flags", "Planting"):SetDisabled(true)
    gui.Reference("Visuals", "Overlay", "Enemy", "Flags", "Reloading"):SetDisabled(true)
    gui.Reference("Visuals", "Overlay", "Enemy", "Flags", "Flashed"):SetDisabled(true)
    gui.Reference("Visuals", "Overlay", "Enemy", "Flags", "Has C4"):SetDisabled(true)

    gui.Reference("Visuals", "Overlay", "Friend", "Flags", "Planting"):SetDisabled(true)
    gui.Reference("Visuals", "Overlay", "Friend", "Flags", "Reloading"):SetDisabled(true)
    gui.Reference("Visuals", "Overlay", "Friend", "Flags", "Flashed"):SetDisabled(true)
    gui.Reference("Visuals", "Overlay", "Friend", "Flags", "Has C4"):SetDisabled(true)
end)
