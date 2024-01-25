callbacks.Register("Draw", function()
	for _, pEnt in pairs(entities.FindByClass("CBasePlayerController")) do
		if pEnt:GetPropBool("m_bIsLocalPlayerController") then
			pEnt:SetPropInt(gui.GetValue("esp.world.fov"), "m_iDesiredFOV")
			break;
		end
	end
end)
