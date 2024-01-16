local guiEnabled = gui.Checkbox(gui.Reference("Visuals", "Other", "Effects"), "flashbang_override", "Override Flashbang", false);
guiEnabled:SetDescription("Override flashbang colour.");

local guiColor = gui.ColorPicker(guiEnabled, "clr", "clr", 255, 255, 255, 255);

local g_flFlashBangTime = 0;
callbacks.Register("Draw", function()
	local bEnabled = guiEnabled:GetValue();
    gui.SetValue("esp.other.noflash", bEnabled);

    local pLocalPlayer = entities.GetLocalPlayer();
    if not pLocalPlayer or not bEnabled then
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

    local flAlpha = 1;

    if flDelta < 3 then
        flAlpha = flDelta / 3;
    end

	local r, g, b, a = guiColor:GetValue();
	a = math.floor(flAlpha * a);
    draw.Color(r, g, b, a);
    draw.FilledRect(0, 0, draw.GetScreenSize());
end)
