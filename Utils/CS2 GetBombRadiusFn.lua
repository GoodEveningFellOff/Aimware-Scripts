local m = {
	-- Updated May-20th-2024 @11:25 EST
	-- map_showbombradius || bombradius @ game/csgo/maps/<map>.vpk/entities/default_ents.vents_c ## only lists if value is overwritten
	["maps/de_ancient.vpk" ] = 650 * 3.5;
	["maps/de_anubis.vpk"  ] = 450 * 3.5;
	["maps/de_inferno.vpk" ] = 620 * 3.5;
	["maps/de_mirage.vpk"  ] = 650 * 3.5;
	["maps/de_nuke.vpk"    ] = 650 * 3.5;
	["maps/de_overpass.vpk"] = 650 * 3.5;
	["maps/de_vertigo.vpk" ] = 500 * 3.5;
};

return function()
	return m[engine.GetMapName()] or 1750;
end
