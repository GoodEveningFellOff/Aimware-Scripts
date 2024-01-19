local m = {
	--map_showbombradius
	["( 0, 0, 0 ),( 0, 0, 0 )"]                             = 1750; -- Game's Default Value
	["( -440, -2150, -168 ),( -2048, 256, -151 )"]          = 2275; -- Mirage
	["( -2136, 662, 506 ),( -1104, 64, 108 )"]              = 2275; -- Overpass
	["( -293.5, -621, 11791.5 ),( -2248, 797.5, 11758 )"]   = 1750; -- Vertigo
	["( -1392, 844, 68 ),( 886.5, 62, 144 )"]               = 2275; -- Ancient
	["( 1976, 462, 180 ),( 351.99997, 2768, 173 )"]         = 2170; -- Inferno
	["( 688, -719.99994, -368 ),( 592, -1008, -748 )"]      = 2275; -- Nuke
	["( 1237.4761, 1953.5, -181.5 ),( -1040, 694, -2 )"]    = 1575; -- Anubis
	["( 1112, 2480, 144 ),( -1536, 2680, 48 )"]             = 1750; -- Dust 2
};

return function()
	local p = (entities.FindByClass("C_CSPlayerResource"))[1];
	if not p then return 0; end
	return m[("%s,%s"):format(p:GetPropVector("m_bombsiteCenterA") or "( 0, 0, 0)", p:GetPropVector("m_bombsiteCenterB") or "( 0, 0, 0)")] or 1750;
end;
