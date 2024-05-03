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


local ETeams = {
  [0] = "U";
  [1] = "S";
  [2] = "T";
  [3] = "CT";
};

client.AllowListener("vote_cast");
callbacks.Register("FireGameEvent", function(ctx)
	if (ctx:GetName() ~= "vote_cast") then
		return;
	end

	local pPlayerController = GetEventPlayerController(ctx, "userid");
	if (not pPlayerController) then
		return;
	end

	print(string.format("[%s] %s voted %s", 
		ETeams[ctx:GetInt("team")] or "U",
		pPlayerController:GetPropString("m_iszPlayerName"),
		(ctx:GetInt("vote_option") == 0) and "yes" or "no"
	));
end)
