local guiEnabled = gui.Checkbox(gui.Reference("Visuals", "Other", "Effects"), "flashbang_override", "Override Flashbang", false);
guiEnabled:SetDescription("Override flashbang colour.");

local guiColor = gui.ColorPicker(guiEnabled, "clr", "clr", 255, 255, 255, 255);

--[[
    Overriding the noflash in AIMWARE when the local player is under normal conditions
    (not controlling a bot, not dead, not spectating ect...)
    AIMWARE will force show the flash but not properly so it will look fucked
    So we must enable "noflash" and this will set some of these values we need to 0
    So we store them making sure to detect when the player we are observing / controlling
    changes so we can properly display the flash effect.

    ITS A PAIN IN THE ASS
    *Badster*
    *Swissguy*
    Pls fix :3
]]
local g_iLocalIndex = 0;
local g_flFlashBangTime = 0;
local g_flFlashDuration = 0;

callbacks.Register("Draw", function()
    local bEnabled = guiEnabled:GetValue();

    gui.SetValue("esp.other.noflash", bEnabled);

    local pLocalPlayer = entities.GetLocalPlayer();
    if not pLocalPlayer or not bEnabled then
        return;
    end

    local iLocalIndex = pLocalPlayer:GetIndex();
    if not pLocalPlayer:IsAlive() then
		for _, pEnt in pairs(entities.FindByClass("CCSPlayerController")) do
			local pPawn = pEnt:GetPropEntity("m_hPawn");

			if pPawn:GetIndex() == iLocalIndex then
				local pObserver = pEnt:GetPropEntity("m_hObserverPawn");

				if pObserver then
					pLocalPlayer = pObserver:GetPropEntity("m_hDetectParentChange");
				end

				break;
			end
		end

		if not pLocalPlayer then
			return;
		end

        iLocalIndex = pLocalPlayer:GetIndex();
	end

	if pLocalPlayer:GetClass() ~= "C_CSPlayerPawn" then
		return;
	end

    -- Detect observed player change
    if iLocalIndex ~= g_iLocalIndex then
        g_iLocalIndex = iLocalIndex;
        g_flFlashBangTime = 0;
        g_flFlashDuration = 0;
    end

    -- Ensure the flash effect is removed (AIMWARE doesnt remove it when we spectate players)
    pLocalPlayer:SetPropFloat(0, "m_flFlashScreenshotAlpha");
    pLocalPlayer:SetPropFloat(0, "m_flFlashOverlayAlpha");

    local flFlashBangTime = pLocalPlayer:GetPropFloat("m_flFlashBangTime");
    if flFlashBangTime > 0 then
        g_flFlashBangTime = flFlashBangTime;
    end

    local flFlashDuration = pLocalPlayer:GetPropFloat("m_flFlashDuration");
    if flFlashDuration > 0 then
        g_flFlashDuration = flFlashDuration;
    end
    
    local flFlashActiveTime = globals.CurTime() - (g_flFlashBangTime - g_flFlashDuration);
    local flFadeOutDuration = math.min(g_flFlashDuration - 0.1, 3);

    local flDelta = g_flFlashBangTime - globals.CurTime();
    if math.abs(flDelta) > g_flFlashDuration * 2 then
        g_flFlashBangTime = 0;
        g_flFlashDuration = 0;
        return;
    end

    if flDelta < 0 or flFadeOutDuration <= 0 then
        return;
    end

    local flAlpha = 1;
    if flFlashActiveTime < 0.1 then
        flAlpha = flFlashActiveTime / 0.1;

    elseif flDelta < flFadeOutDuration then
        flAlpha = flDelta / flFadeOutDuration;
    end

	local r, g, b, a = guiColor:GetValue();
    draw.Color(r, g, b, math.floor(flAlpha * a));
    draw.FilledRect(0, 0, draw.GetScreenSize());
end)
