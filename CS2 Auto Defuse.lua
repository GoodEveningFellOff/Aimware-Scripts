local guiEnabled = gui.Checkbox(gui.Reference("Misc", "General", "Extra"), "autodefuse", "Auto-Defuse", false)
guiEnabled:SetDescription("Defuses the bomb right before time runs out.")

local IN_USE = bit.lshift(1, 5)
callbacks.Register("CreateMove", function(pCmd)
    if not pCmd then return end

    if not guiEnabled:GetValue() then return end

    local pLocal = entities.GetLocalPlayer()
    if not pLocal or not pLocal:IsAlive() or pLocal:GetTeamNumber() ~= 3 then return end

    local pLocalPlayerController = nil
    if (pLocal:GetPropInt("m_hOriginalController") > 0) then pLocalPlayerController = pLocal:GetPropEntity("m_hOriginalController") end
    if not pLocalPlayerController then return end

    local pBomb = nil
    for _, pEnt in pairs(entities.FindByClass("C_PlantedC4")) do if pEnt:GetPropBool("m_bBombTicking") then pBomb = pEnt end end
    if not pBomb then return end
    if (pBomb:GetAbsOrigin() - pLocal:GetAbsOrigin()):Length() > 65 then return end

    local pBombDefuser = nil
    if (pBomb:GetPropInt("m_pBombDefuser") > 0) then pBombDefuser = pBomb:GetPropEntity("m_pBombDefuser") end
    if pBombDefuser and pBombDefuser:GetIndex() ~= pLocal:GetIndex() then return end

    local flDefuseLength = (pLocalPlayerController:GetPropBool("m_bPawnHasDefuser") and 5 or 10)
    local flTimeUntilDefuse = pBomb:GetPropFloat("m_flC4Blow") - globals.CurTime() - flDefuseLength
    flTimeUntilDefuse = flTimeUntilDefuse - (globals.FrameTime() + 0.015625 + (pLocalPlayerController:GetPropInt("m_iPing") * 2 / 1000))
    if flTimeUntilDefuse > 0 then return end

    pCmd:SetButtons(pCmd:GetButtons() + IN_USE)
end)