local guiEnabled = gui.Checkbox(gui.Reference("Misc", "General", "Extra"), "autodefuse", "Auto-Defuse", false);
guiEnabled:SetDescription("Defuses the bomb right before time runs out.");

local g_bIsDefusing = false;

local function StopDefusing()
    if g_bIsDefusing then
        client.Command("-use");
        g_bIsDefusing = false;
    end
end

callbacks.Register("Draw", function()
    if not guiEnabled:GetValue() then
        return StopDefusing();
    end

    local pLocalPlayer = entities.GetLocalPlayer();
    if not pLocalPlayer then
        return StopDefusing();
    end

    if not pLocalPlayer:IsAlive() or pLocalPlayer:GetTeamNumber() ~= 3 then
        return StopDefusing();
    end

    local iLocalIndex = pLocalPlayer:GetIndex();
    local pLocalPlayerController = nil;
    for _, pEnt in pairs(entities.FindByClass("CCSPlayerController")) do
        if pEnt:GetPropEntity("m_hPlayerPawn"):GetIndex() == iLocalIndex then
            pLocalPlayerController = pEnt;
            break;
        end
    end

    if not pLocalPlayerController then
        return StopDefusing();
    end

    local pBomb = nil
    for _, pEnt in pairs(entities.FindByClass("C_PlantedC4")) do
        if pEnt:GetPropBool("m_bBombTicking") then
            pBomb = pEnt;
        end
    end

    if not pBomb then
        return StopDefusing();
    end

    if (pBomb:GetPropBool("m_bBeingDefused") and not g_bIsDefusing) or (pBomb:GetAbsOrigin() - pLocalPlayer:GetAbsOrigin()):Length() > 65 then
        return StopDefusing();
    end

    if g_bIsDefusing then
        return;
    end

    local flRemainingBombTime = pBomb:GetPropFloat("m_flC4Blow") - globals.CurTime() - (pLocalPlayerController:GetPropBool("m_bPawnHasDefuser") and 5 or 10);
    flRemainingBombTime = flRemainingBombTime - (globals.FrameTime() + 0.015625 + (pLocalPlayerController:GetPropInt("m_iPing") * 2 / 1000));

    if flRemainingBombTime < 0 or flRemainingBombTime > math.max(0.01, globals.FrameTime()) then
        return StopDefusing();
    end

    client.Command("+use");
    g_bIsDefusing = true;
end)

callbacks.Register("Unload", function()
    StopDefusing();
end)
