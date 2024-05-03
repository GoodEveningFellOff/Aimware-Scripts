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
