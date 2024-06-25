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
    if(not guiEnabled:GetValue())then
        StopDefusing();
        return;
    end

    local pLocalPlayer = entities.GetLocalPlayer();
    if(not pLocalPlayer)then
        StopDefusing();
        return;
    end

    -- If we are not alive, not on the counter-terrorist team, or our original controller handle is invalid
    if(not pLocalPlayer:IsAlive() or pLocalPlayer:GetTeamNumber() ~= 3 or pLocalPlayer:GetPropInt("m_hOriginalController") <= 0)then
        StopDefusing();
        return;
    end

    -- Find an active bomb
    local pBomb;
    for _, pEnt in pairs(entities.FindByClass("C_PlantedC4")) do
        if(pEnt:GetPropBool("m_bBombTicking"))then
            pBomb = pEnt;
            break;
        end
    end

    if(not pBomb)then
        StopDefusing();
        return;
    end

    local pLocalPlayerController = pLocalPlayer:GetPropEntity("m_hOriginalController");
    if(not pLocalPlayerController)then
        StopDefusing();
        return;
    end

    -- If the bomb is being defused but not by us, we are not close enough to the bomb, or we are already defusing
    if((pBomb:GetPropBool("m_bBeingDefused") and not g_bIsDefusing) or (pBomb:GetAbsOrigin() - pLocalPlayer:GetAbsOrigin()):Length() > 65 or g_bIsDefusing)then
        StopDefusing();
        return;
    end

    -- Remaining time until we HAVE to start defusing the bomb
    local flRemainingBombTime = pBomb:GetPropFloat("m_flC4Blow") - globals.CurTime() - (pLocalPlayerController:GetPropBool("m_bPawnHasDefuser") and 5 or 10);
    -- Ugly hack to compensate for latency
    flRemainingBombTime = flRemainingBombTime - (globals.FrameTime() + 0.015625 + (pLocalPlayerController:GetPropInt("m_iPing") * 2 / 1000));

    -- If we dont have any more time or we still have more than a frame that we can wait 
    if(flRemainingBombTime < 0 or flRemainingBombTime > math.max(0.01, globlas.FrameTime()))then
        StopDefusing();
        return;
    end

    -- Start defusing
    client.Command("+use");
    g_bIsDefusing = true;
end)

callbacks.Register("Unload", function()
    StopDefusing();
end)
