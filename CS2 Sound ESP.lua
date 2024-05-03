local guiEnemySounds = gui.Checkbox(gui.Reference("Visuals", "Overlay", "Enemy"), "sounds", "Sounds", false);
guiEnemySounds:SetDescription("Visualize player sounds.");
local guiEnemySoundsColor = gui.ColorPicker(guiEnemySounds, "clr", "clr", 255, 55, 55, 100);

local guiFriendlySounds = gui.Checkbox(gui.Reference("Visuals", "Overlay", "Friend"), "sounds", "Sounds", false);
guiFriendlySounds:SetDescription("Visualize player sounds.");
local guiFriendlySoundsColor = gui.ColorPicker(guiFriendlySounds, "clr", "clr", 55, 155, 255, 100);

local function AreTeamsEnemies(eTeam1, eTeam2)
	-- In deathmatch mode or teams are not equal and neither team is "Unassigned" or "Spectator"
	return client.GetConVar("mp_teammates_are_enemies") or (eTeam1 ~= eTeam2 and eTeam1 > 1 and eTeam2 > 1);
end

local function GetEventPlayerController(ctx, str)
	if (type(ctx) ~= "userdata") then
		return;
	end

	local iPlayerControllerIndex = ctx:GetInt(str);
	if (not iPlayerControllerIndex) then
		return;
	end

	local pPlayerController = entities.GetByIndex(iPlayerControllerIndex + 1);
	return (pPlayerController and pPlayerController:GetClass() == "CCSPlayerController") and pPlayerController or nil;
end

local g_aSounds = {};

client.AllowListener("player_sound");
callbacks.Register("FireGameEvent", function(ctx)
	if (ctx:GetName() ~= "player_sound" or not gui.GetValue("esp.master")) then
		return;
	end

	local pLocalPlayer = entities.GetLocalPlayer();
	local pPlayerController = GetEventPlayerController(ctx, "userid");
	if (not pLocalPlayer or not pPlayerController) then
		return;
	end

	local pPawn = pPlayerController:GetPropEntity("m_hPawn");
	if (not pPawn) then
		return;
	end

	if (pLocalPlayer:GetIndex() == pPawn:GetIndex()) then
		return;
	end

	local bEnemy = AreTeamsEnemies(pLocalPlayer:GetTeamNumber(), pPawn:GetTeamNumber());
	if ((bEnemy and not guiEnemySounds:GetValue()) or (not bEnemy and not guiFriendlySounds:GetValue())) then
		return;
	end

	local vecPawnOrigin = pPawn:GetAbsOrigin();
	local vecLocalOrigin = pLocalPlayer:GetAbsOrigin() + pLocalPlayer:GetPropVector("m_vecViewOffset");

	-- If we are too far away from the sound, dont add it to the sounds array
	if ((vecLocalOrigin - vecPawnOrigin):Length() > ctx:GetInt("radius")) then
		return;
	end

	table.insert(g_aSounds, {
		m_flTime = globals.CurTime();
		m_vecOrigin = vecPawnOrigin;
		m_bEnemy = bEnemy;
	});
	
end)

local g_kSegments = 31;
local g_kSegmentSize = (math.pi * 2) / g_kSegments;
local g_kDuration = 1.2;
local g_kFadeOut = 0.2;
local g_kStartRadius = 2;
local g_kIncreaseRadius = 20;
local g_kWidth = 2;

local function Draw3DCircle(vecOrigin, flRadius, flWidth, flSegmentRadianSize)
	local vecWidthOffset = Vector3(0, 0, flWidth * 0.5);

	-- Get all of the circle's points into an array of points, a failed WorldToScreen call will result in the function returning
	local aPoints = {};
	for i = 0, math.pi * 2, flSegmentRadianSize do
		local vecCircleSegment = vecOrigin + Vector3(math.cos(i) * flRadius, math.sin(i) * flRadius, 0);

		local x0, y0 = client.WorldToScreen(vecCircleSegment - vecWidthOffset);
		local x1, y1 = client.WorldToScreen(vecCircleSegment + vecWidthOffset);

		if (not (x0 and y0 and x1 and y1)) then
			return;
		end

		aPoints[#aPoints + 1] = { x0, y0, x1, y1 };
	end

	for i = 2, #aPoints do
		local aLine1 = aPoints[i - 1];
		local aLine2 = aPoints[i];

		draw.Triangle(
			aLine1[1], aLine1[2],
			aLine1[3], aLine1[4],
			aLine2[3], aLine2[4]
		);

		draw.Triangle(
			aLine1[1], aLine1[2],
			aLine2[3], aLine2[4],
			aLine2[1], aLine2[2]
		);
	end
end

callbacks.Register("Draw", function()
	local clrEnemy = { guiEnemySoundsColor:GetValue() };
	local clrFriendly = { guiFriendlySoundsColor:GetValue() };

	local flCurTime = globals.CurTime();
	for i, stData in pairs(g_aSounds) do
		local dflTime = flCurTime - stData.m_flTime;
		-- If this entry has outlived its duration, mark if for destruction
		if (dflTime > g_kDuration) then
			g_aSounds[i] = nil;

		else

			local r, g, b, a = unpack(stData.m_bEnemy and clrEnemy or clrFriendly);

			local flFadeOut = (1 - (dflTime - g_kDuration + g_kFadeOut) / g_kFadeOut);
			draw.Color(r, g, b, (flFadeOut < 1) and math.floor(a * flFadeOut) or a);

			Draw3DCircle(
				stData.m_vecOrigin,
				g_kStartRadius + (dflTime / g_kDuration) * g_kIncreaseRadius,
				g_kWidth,
				g_kSegmentSize
			);

		end
	end

	-- Remove old entries
	local i, len = 1, #g_aSounds;
    while(i < len) do
        if not g_aSounds[i] then
            len = len - 1;
            table.remove(g_aSounds, i);

        else
            i = i + 1;
        end
    end
end)
