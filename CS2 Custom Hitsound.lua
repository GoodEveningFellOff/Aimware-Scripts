local guiRef = gui.Reference("Misc", "General", "Extra");

local guiHitmarker = gui.Editbox(guiRef, "hitmarker", "Hitmarker File");
guiHitmarker:SetDescription("Name of the .vsnd_c file placed in the sounds folder.");

local guiVolume = gui.Slider(guiRef, "hitmarker_volume", "Hitmarker Volume", 1, 0, 2, 0.05);
guiVolume:SetDescription("Volume of the hitmarker.");

local g_iLastHitTick = 0;
callbacks.Register("FireGameEvent", function(ctx)
    if ctx:GetName() ~= "player_hurt" then
        return;
    end

    local pVictimController = entities.GetByIndex(ctx:GetInt("userid") + 1);
    local pAttackerController = entities.GetByIndex(ctx:GetInt("attacker") + 1);

    if not pVictimController or not pAttackerController then
        return;
    end

    if pVictimController:GetIndex() == pAttackerController:GetIndex() then
        return;
    end

    if pAttackerController:GetClass() ~= "CCSPlayerController" then
        return;
    end

    local pAttackerPawn = pAttackerController:GetPropEntity("m_hPawn");
    local pLocalPlayer = entities.GetLocalPlayer();
    if not pAttackerPawn or not pLocalPlayer then
        return;
    end

    if pAttackerPawn:GetIndex() ~= pLocalPlayer:GetIndex() or ctx:GetInt("dmg_health") <= 0 then
        return;
    end

    if globals.TickCount() == g_iLastHitTick then
        return;
    end

    g_iLastHitTick = globals.TickCount();

    client.SetConVar("snd_toolvolume", guiVolume:GetValue() or 1, true);
    client.Command(("play sounds\\%s"):format(guiHitmarker:GetValue() or ' '), true)
end)
