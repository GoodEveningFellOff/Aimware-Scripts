local guiEnemySounds = gui.Checkbox(gui.Reference("Visuals", "Overlay", "Enemy"), "sounds", "Sounds", false);
guiEnemySounds:SetDescription("Visualize player sounds.");
local guiEnemySoundsColor = gui.ColorPicker(guiEnemySounds, "clr", "clr", 255, 55, 55, 255);

local guiFriendlySounds = gui.Checkbox(gui.Reference("Visuals", "Overlay", "Friend"), "sounds", "Sounds", false);
guiFriendlySounds:SetDescription("Visualize player sounds.");
local guiFriendlySoundsColor = gui.ColorPicker(guiFriendlySounds, "clr", "clr", 55, 155, 255, 255);

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
	if (ctx:GetName() ~= "player_sound") then
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
local g_kDuration = 1;
local g_kStartRadius = 2;
local g_kIncreaseRadius = 20;

local function Draw3DCircle(vecOrigin, flRadius, flSegmentRadianSize)
	-- Get all of the circle's points into an array of points, a failed WorldToScreen call will result in the function returning
	local aPoints = {};
	for i = 0, math.pi * 2, flSegmentRadianSize do
		local x, y = client.WorldToScreen(vecOrigin + Vector3(math.cos(i) * flRadius, math.sin(i) * flRadius, 0));

		if (not x or not y) then
			return;
		end

		aPoints[#aPoints + 1] = { x, y };
	end

	for i = 2, #aPoints do
		local x1, y1 = unpack(aPoints[i - 1]);
		local x2, y2 = unpack(aPoints[i]);

		-- Make the circle *thicker*
		if (math.abs(x2 - x1) < math.abs(y2 - y1)) then
			draw.Line(x1 - 1, y1, x2 - 1, y2);
			draw.Line(x1 + 1, y1, x2 + 1, y2);
		else
			draw.Line(x1, y1 - 1, x2, y2 - 1);
			draw.Line(x1, y1 + 1, x2, y2 + 1);
		end

		draw.Line(x1, y1, x2, y2);
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

			if (stData.m_bEnemy) then
				draw.Color(unpack(clrEnemy));
			else
				draw.Color(unpack(clrFriendly));
			end

			Draw3DCircle(
				stData.m_vecOrigin,
				g_kStartRadius + (dflTime / g_kDuration) * g_kIncreaseRadius,
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
