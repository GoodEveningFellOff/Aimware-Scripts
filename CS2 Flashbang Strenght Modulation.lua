local guiStrength = gui.Slider(gui.Reference("Visuals", "Other", "Effects"), "flashbang_strength", "Flash Strength", 1, 0, 1, 0.01);
guiStrength:SetDescription("Override flashbang strength.");

local g_flFlashBangTime = 0;
callbacks.Register("Draw", function()
    gui.SetValue("esp.other.noflash", 1);

    local pLocalPlayer = entities.GetLocalPlayer();
    if not pLocalPlayer then
        return;
    end

    if not pLocalPlayer:IsAlive() then
        return;
    end

    local flFlashBangTime = pLocalPlayer:GetPropFloat("m_flFlashBangTime");

    if flFlashBangTime > 0 then
        g_flFlashBangTime = flFlashBangTime;
    end

    local flDelta = g_flFlashBangTime - globals.CurTime();
    if math.abs(flDelta) > 60 then
        g_flFlashBangTime = 0;
        return;
    end

    if flDelta < 0 then
        return;
    end

    local flAlpha = 255;

    if flDelta < 3 then
        flAlpha = 255 * (flDelta / 3);
    end

    draw.Color(255, 255, 255, math.floor(flAlpha * guiStrength:GetValue()));
    draw.FilledRect(0, 0, draw.GetScreenSize());
end)
