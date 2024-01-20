local guiWindow = gui.Reference();
local guiRef = gui.Reference("Settings", "Advanced");
local guiX = gui.Slider(guiRef, "bombinfo_x", "Bomb Info X", 100, 0, 100000, 1);
guiX:SetInvisible(true);
local guiY = gui.Slider(guiRef, "bombinfo_y", "Bomb Info Y", 100, 0, 100000, 1);
guiY:SetInvisible(true);
local guiEnabled = gui.Checkbox(gui.Reference("Misc", "General", "Extra"), "bombinfo", "Show Bomb Info", false);
guiEnabled:SetDescription("Shows information about the bomb.")

local GetBombRadius = function() return 1750; end;
do
    http.Get("https://raw.githubusercontent.com/GoodEveningFellOff/Aimware-Scripts/main/Utils/CS2%20GetBombRadiusFn.lua", function(sData)
        local fileGBRF = file.Open("GetBombRadiusFn.txt", "w");
        fileGBRF:Write(sData); fileGBRF:Close();
        local bStatus, pFn = pcall(function() return loadstring(sData)(); end);
        if bStatus then GetBombRadius = pFn; end
    end);

    local bStatus, sData = pcall(function()
        local fileGBRF = file.Open("GetBombRadiusFn.txt", "r");
        local str = fileGBRF:Read(); fileGBRF:Close(); return str;
    end);
    
    if bStatus then
        local bStatus, pFn = pcall(function() return loadstring(sData)(); end);
        if bStatus then GetBombRadius = pFn; end
    end
end

local g_aFonts = {};
local function GetFont(flScale)
    local f = g_aFonts[flScale];
    if not f then
        g_aFonts[flScale] = draw.CreateFont("Bahnschrift", math.floor(13 * flScale), 500)
        return g_aFonts[flScale];
    end

    return f;
end

local BOMB_NOTFOUND = 0;
local BOMB_DROPPED  = 1;
local BOMB_HELD     = 2;
local BOMB_PLANTING = 3;
local BOMB_PLANTED  = 4;
local BOMB_DEFUSING = 5;
local BOMB_DEAD     = 6;

local g_flBombRadius = 0;

local g_iBombState = BOMB_NOTFOUND;
local g_sBombOwner = "";
local g_cBombSite  = 'A';
local g_vecBombPosition = Vector3(0, 0, 0);
local g_stBombTimer = {
    m_flEndTime = 0;
    m_flDuration = 0;
};

local g_stBombAction = {
    m_flEndTime = 0;
    m_flDuration = 0;
};

local g_stBombDamage = {
    m_flDamage = 0;
    m_bLethal = false;
};

local g_bWasMouseDown = false;
local g_bMouseDown = false;
local g_bDragging = false;
local g_iMouseDX = 0;
local g_iMouseDY = 0;
local g_iLastTick = 0;

local function UpdateBombState(pC4, pPlantedC4)
    if not pC4 and not pPlantedC4 then
        g_iBombState = BOMB_NOTFOUND;
        return;

    elseif pPlantedC4 then
        g_vecBombPosition = pPlantedC4:GetAbsOrigin();

        if not pPlantedC4:GetPropBool("m_bBombTicking") then
            g_iBombState = BOMB_DEAD;
        
        elseif pPlantedC4:GetPropBool("m_bBeingDefused") then
            g_iBombState = BOMB_DEFUSING;

        else
            g_iBombState = BOMB_PLANTED;
        end

        return;
    end

    g_vecBombPosition = pC4:GetAbsOrigin();

    local pBombOwner = pC4:GetPropEntity("m_hOwnerEntity");
    g_sBombOwner = pBombOwner:GetName();
    if g_sBombOwner then
        if g_sBombOwner:len() > 24 then
            g_sBombOwner = g_sBombOwner:sub(0, 21) .. "...";
        end
    end

    if pC4:GetPropBool("m_bStartedArming") then
        g_iBombState = BOMB_PLANTING;

    elseif g_sBombOwner then
        g_iBombState = BOMB_HELD;
    
    else
        g_iBombState = BOMB_DROPPED;
    end
end

local function GetBombInformation()
    local pC4               = (entities.FindByClass("C_C4"              ))[1];
    local pPlantedC4        = (entities.FindByClass("C_PlantedC4"       ))[1];
    local pCSPlayerResource = (entities.FindByClass("C_CSPlayerResource"))[1];

    UpdateBombState(pC4, pPlantedC4);

    if pCSPlayerResource then
        local vecBombSiteA = pCSPlayerResource:GetPropVector("m_bombsiteCenterA");
        local vecBombSiteB = pCSPlayerResource:GetPropVector("m_bombsiteCenterB");

        if (vecBombSiteA - g_vecBombPosition):Length() < (vecBombSiteB - g_vecBombPosition):Length() then
            g_cBombSite = 'A';
        else
            g_cBombSite = 'B';
        end
    end

    if g_iBombState < BOMB_PLANTING or g_iBombState == BOMB_DEAD then
        return;
    end

    if g_iBombState == BOMB_PLANTING then
        g_stBombAction.m_flEndTime = pC4:GetPropFloat("m_fArmedTime");
        g_stBombAction.m_flDuration = 4;
        return;
    end

    if g_iBombState == BOMB_DEFUSING then
        g_stBombAction.m_flEndTime = pPlantedC4:GetPropFloat("m_flDefuseCountDown");
        g_stBombAction.m_flDuration = pPlantedC4:GetPropFloat("m_flDefuseLength");
    end

    g_stBombTimer.m_flEndTime = pPlantedC4:GetPropFloat("m_flC4Blow");
    g_stBombTimer.m_flDuration = pPlantedC4:GetPropFloat("m_flTimerLength");

    
    local pLocalPlayer = entities.GetLocalPlayer();
	if not pLocalPlayer then
        g_stBombDamage.m_flDamage = 0;
        g_stBombDamage.m_bLethal = false;
		return;
	end

	if not pLocalPlayer:IsAlive() then

		local iLocalIndex = pLocalPlayer:GetIndex();
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
            g_stBombDamage.m_flDamage = 0;
            g_stBombDamage.m_bLethal = false;
			return;
		end
	end

	if pLocalPlayer:GetClass() ~= "C_CSPlayerPawn" then
		g_stBombDamage.m_flDamage = 0;
        g_stBombDamage.m_bLethal = false;
		return;
	end

	local iHealth = pLocalPlayer:GetPropInt("m_iHealth");
	local iArmor = pLocalPlayer:GetPropInt("m_ArmorValue");

    if iHealth <= 0 then
        g_stBombDamage.m_flDamage = 0;
        g_stBombDamage.m_bLethal = false;
		return;
	end

    local flBombRadius = GetBombRadius();
    local flDistance = (pPlantedC4:GetAbsOrigin() - (pLocalPlayer:GetAbsOrigin() + pLocalPlayer:GetPropVector("m_vecViewOffset"))):Length();
	local flDamage = (flBombRadius / 3.5) * math.exp(flDistance^2 / (-2 * (flBombRadius / 3)^2));

	if iArmor > 0 then
		local flReducedDamage = flDamage / 2;
		
		if iArmor < flReducedDamage then
			local flFraction = iArmor / flReducedDamage;
			flDamage = (flFraction * flReducedDamage) + (1 - flFraction) * flDamage;

		else
			flDamage = flReducedDamage;
		end
	end

	flDamage = math.floor(flDamage + 0.5);

    g_stBombDamage.m_flDamage = flDamage;
    g_stBombDamage.m_bLethal = (flDamage >= iHealth);
end

callbacks.Register("Draw", function()
    if globals.MaxClients() <= 1 or not guiEnabled:GetValue() then
        g_bDragging = false;
        return;
    end

    local iTick = globals.TickCount();
    local flCurTime = globals.CurTime();

    if iTick ~= g_iLastTick then
        GetBombInformation();
        g_iLastTick = iTick;
    end

    local aElements = {};
    if not (g_iBombState == BOMB_NOTFOUND or g_iBombState == BOMB_DEAD or g_iBombState == BOMB_DROPPED) then
        if g_iBombState == BOMB_HELD then
            aElements[#aElements + 1] = {255, 255, 255, ("Carrier: %s"):format(g_sBombOwner)};

        else
            if g_iBombState == BOMB_PLANTING then
                aElements[#aElements + 1] = {255, 255, 255, ("Planting: %0.1fs"):format(math.max(g_stBombAction.m_flEndTime - flCurTime, 0))};
            end
        
            local flBombTime = math.max(g_stBombTimer.m_flEndTime - flCurTime, 0);
            if g_iBombState == BOMB_DEFUSING then
                local flDefuseTime = math.max(g_stBombAction.m_flEndTime - flCurTime, 0);
        
                if flDefuseTime <= flBombTime then
                    aElements[#aElements + 1] = {55, 255, 55, ("Defusing: %0.1fs"):format(flDefuseTime)};
                else
                    aElements[#aElements + 1] = {255, 55, 55, ("Defusing: %0.1fs"):format(flDefuseTime)};
                end
            end
                
        
            if g_iBombState > BOMB_PLANTING then
                aElements[#aElements + 1] = {255, 255, 255, ("Timer: %0.1fs"):format(flBombTime)};
        
                if g_stBombDamage.m_flDamage > 0 then
                    if g_stBombDamage.m_bLethal then
                        aElements[#aElements + 1] = {255, 55, 55, "Damage: Lethal"};
                    else
                        aElements[#aElements + 1] = {55, 255, 55, ("Damage: %0.0fhp"):format(g_stBombDamage.m_flDamage)};
                    end
                end
            end
        
            if g_iBombState >= BOMB_PLANTING then
                aElements[#aElements + 1] = {255, 255, 255, "Site: " .. g_cBombSite};
            end
        end
    end

    local flScale = gui.GetValue("adv.dpi") * 0.25 + 0.75;
    draw.SetFont(GetFont(flScale));

    local iLineSize = math.floor(2 * flScale);
    local iRounding = iLineSize * 2;
    local iFooterSize = iRounding;
    local iTextOffset = iLineSize * 4;
    local iHeaderSize = math.floor(18 * flScale);
    local _, iTextSize = draw.GetTextSize("|");
    iTextSize = math.floor(iTextSize * 2);

    local iScreenWidth, iScreenHeight = draw.GetScreenSize();
    local x1, y1 = guiX:GetValue() or 0, guiY:GetValue() or 0;
    local w, h = math.floor(200 * flScale), math.floor(math.max(#aElements + 0.75, 1) * iTextSize) + iHeaderSize + iFooterSize;
    local x2, y2 = x1 + w, y1 + h;

    if guiWindow:IsActive() then
        g_bMouseDown = input.IsButtonDown(1);
        if g_bMouseDown and not g_bWasMouseDown then
            local mx, my = input.GetMousePos();
            if mx > x1 and mx < x2 and my > y1 and my < y1 + iHeaderSize then
                g_bDragging = true;
                g_iMouseDX = mx - x1;
                g_iMouseDY = my - y1;
            end
        end

        if g_bDragging and g_bMouseDown then
            local mx, my = input.GetMousePos();
            mx = mx - g_iMouseDX;
            my = my - g_iMouseDY;

            
            guiX:SetValue((mx < 0) and 0 or (mx + iHeaderSize > iScreenWidth) and iScreenWidth - iHeaderSize or mx);
            guiY:SetValue((my < 0) and 0 or (my + iHeaderSize > iScreenHeight) and iScreenHeight - iHeaderSize or my);
        else
            g_bDragging = false;
        end
        g_bWasMouseDown = g_bMouseDown;

    else
        if x1 + iHeaderSize > iScreenWidth then
            guiX:SetValue(iScreenWidth - iHeaderSize);
        end

        if y1 + iHeaderSize > iScreenHeight then
            guiY:SetValue(iScreenHeight - iHeaderSize);
        end

        g_bMouseDown = false;
        g_bWasMouseDown = false;
        g_bDragging = false;
    end
    

    draw.Color(gui.GetValue("theme.ui2.border"));
    draw.RoundedRect(x1 - 1, y1 - 1, x2 + 1, y2 + 1, iRounding, 1, 1, 1, 1);

    do
        local r1, g1, b1, a1 = gui.GetValue("theme.ui2.lowpoly1");
        local r2, g2, b2, a2 = gui.GetValue("theme.ui2.lowpoly2");

        draw.Color(math.floor((r1 + r2) / 2), math.floor((g1 + g2) / 2),
            math.floor((b1 + b2) / 2), math.floor((a1 + a2) / 2));
        draw.RoundedRectFill(x1, y1 + iHeaderSize, x2, y2, iRounding, 0, 0, 1, 1);
    end

    draw.Color(gui.GetValue("theme.header.bg"));
    draw.RoundedRectFill(x1, y1, x2, y1 + iHeaderSize, iRounding, 1, 1, 0, 0);

    draw.Color(gui.GetValue("theme.header.line"));
    draw.FilledRect(x1, y1 + iHeaderSize - iLineSize, x2, y1 + iHeaderSize);
    
    draw.SetScissorRect(x1, y2 - iFooterSize, x2, y2);
    draw.Color(gui.GetValue("theme.footer.bg"));
    draw.RoundedRectFill(x1, y2 - iFooterSize * 2, x2, y2, iRounding, 0, 0, 1, 1);
    draw.SetScissorRect(0, 0, iScreenWidth, iScreenHeight);

    do
        local tx, ty = draw.GetTextSize("Bomb Info");
        draw.Color(gui.GetValue("theme.header.text"))
        draw.Text(x1 + iTextOffset, y1 + math.floor((iHeaderSize - ty) / 2), "Bomb Info")
    end

    local iTextY = y1 + math.floor(iHeaderSize * 1.5);
    for i, aData in pairs(aElements) do
        draw.Color(aData[1], aData[2], aData[3], 255);
        draw.Text(x1 + iTextOffset, iTextY + iTextSize * (i - 1), aData[4]);
    end
end)
