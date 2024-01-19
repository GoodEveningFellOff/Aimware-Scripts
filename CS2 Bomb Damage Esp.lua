local CLAMP = function(a,b,c)return(a<b)and b or(a>c)and c or a;end;

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

local g_iTickCount = 0;
local g_iLastTickCount = 0;

local g_iLocalHealth = 0;
local g_iLocalArmor = 0;
local g_vLocalViewOrigin = Vector3(0, 0, 0);

local g_iBombRadius = 1750;

local function OnTick()
	local pLocalPlayer = entities.GetLocalPlayer();
	if not pLocalPlayer then
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
			return;
		end
	end

	if pLocalPlayer:GetClass() ~= "C_CSPlayerPawn" then
		g_iLocalHealth = 0;
		return;
	end

	g_iLocalHealth = pLocalPlayer:GetPropInt("m_iHealth") or 0;
	g_iLocalArmor = pLocalPlayer:GetPropInt("m_ArmorValue") or 0;
	g_vLocalViewOrigin = pLocalPlayer:GetAbsOrigin() + (pLocalPlayer:GetPropVector("m_vecViewOffset") or Vector3(0, 0, 62));

	g_iBombRadius = GetBombRadius();
end

callbacks.Register("Draw", function()
	g_iTickCount = globals.TickCount();

	if g_iTickCount ~= g_iLastTickCount then
		g_iLastTickCount = g_iTickCount;
		OnTick()
	end
end)

callbacks.Register("DrawESP", function(ctx)
	local pEnt = ctx:GetEntity();

	if not pEnt then
		return;
	end

	if pEnt:GetClass() ~= "C_PlantedC4" then
		return;
	end

	if not pEnt:GetPropBool("m_bBombTicking") then
		return;
	end

	local flCurTime = globals.CurTime();
	local flC4Blow = pEnt:GetPropFloat("m_flC4Blow");
	local flDefuseCountDown = pEnt:GetPropFloat("m_flDefuseCountDown");
	
	if pEnt:GetPropBool("m_bBeingDefused") then
		local fDelta = flC4Blow - flDefuseCountDown;

		if fDelta < 0 then
			ctx:Color(255, 55, 55, 255);
			ctx:AddTextBottom(("%0.02fs"):format(fDelta));
			ctx:AddTextBottom(("%0.2fs"):format(flC4Blow - flCurTime));

		else
			ctx:Color(55, 255, 55, 255);
			ctx:AddTextBottom(("+%0.02fs"):format(fDelta));
			ctx:AddTextBottom(("%0.2fs"):format(flDefuseCountDown - flCurTime));
		end

	else
		ctx:Color(255, 255, 255, 255)
		ctx:AddTextBottom(("%0.2fs"):format(flC4Blow - flCurTime));
	end

	if g_iLocalHealth <= 0 then
		return;
	end
	
	local fDistance = (pEnt:GetAbsOrigin() - g_vLocalViewOrigin):Length();
	local fDamage = (g_iBombRadius / 3.5) * math.exp(fDistance^2 / (-2 * (g_iBombRadius / 3)^2));

	if g_iLocalArmor > 0 then
		local fReducedDamage = fDamage / 2;
		
		if g_iLocalArmor < fReducedDamage then
			local fReducedFraction = g_iLocalArmor / fReducedDamage;
			fDamage = (fReducedFraction * fReducedDamage) + (1 - fReducedFraction) * fDamage;

		else
			fDamage = fReducedDamage;
		end
	end

	fDamage = math.floor(fDamage + 0.5);

	if fDamage > 0  then
		local v = math.floor(255 - 200 * CLAMP(fDamage / g_iLocalHealth, 0, 1));
	
		ctx:Color(255, v, v, 255)
		ctx:AddTextBottom((fDamage >= g_iLocalHealth) and "LETHAL" or ("-%0.0fHP"):format(fDamage))
	end
end)
