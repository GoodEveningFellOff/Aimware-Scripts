local guiRef = gui.Reference("Visuals", "World", "Helper");

local guiEnabled = gui.Combobox(guiRef, "bullet_impacts", "Bullet Impacts", "Disabled", "Enabled (hide advanced options)", "Enabled (show advanced options)");
guiEnabled:SetDescription("Visualize server bullet impacts.");
local guiColor = gui.ColorPicker(guiEnabled, "clr", "Clr", 55, 55, 255, 55);
local guiSize = gui.Slider(guiRef, "bullet_impacts.size", "Size", 4, 1, 20, 0.25);
guiSize:SetDescription("Side length of the box.");
local guiDuration = gui.Slider(guiRef, "bullet_impacts.duration", "Duration", 4.8, 1, 10, 0.1);
guiDuration:SetDescription("Duration of box visibility in seconds.");
local guiFade = gui.Slider(guiRef, "bullet_impacts.fade", "Fade", 0.4, 0, 1, 0.025);
guiFade:SetDescription("Fade in / out duration in seconds.");

local g_bShown = false;
guiSize:SetInvisible(true);
guiDuration:SetInvisible(true);
guiFade:SetInvisible(true);

local g_flSize = 0;
local g_flDuration = 0;
local g_flFade = 0;
local g_flFadeInv = 0;

local function Draw3DCube(r, g, b, a, flDelta, flSize, vecOrigin)
    local flSize = flSize;

    local flAlpha = 1;
    if g_flFade ~= 0 then
        if flDelta < g_flFade then
            flAlpha = flDelta / g_flFade;
        elseif flDelta > g_flFadeInv then
            flAlpha = 1 - (flDelta - g_flFadeInv) / g_flFade;
        end

        flSize = flSize * flAlpha
    end

    local v = vecOrigin + Vector3(flSize / 2, flSize / 2, flSize / 2);
    local x1, y1 = client.WorldToScreen(v); -- [+1, +1, +1]
    v.x = v.x - flSize;
    local x2, y2 = client.WorldToScreen(v); -- [-1, +1, +1]
    v.y = v.y - flSize;
    local x3, y3 = client.WorldToScreen(v); -- [-1, -1, +1]
    v.x = v.x + flSize;
    local x4, y4 = client.WorldToScreen(v); -- [+1, -1, +1]
    v.z = v.z - flSize;
    local x5, y5 = client.WorldToScreen(v); -- [+1, -1, -1]
    v.x = v.x - flSize;
    local x6, y6 = client.WorldToScreen(v); -- [-1, -1, -1]
    v.y = v.y + flSize;
    local x7, y7 = client.WorldToScreen(v); -- [-1, +1, -1]
    v.x = v.x + flSize;
    local x8, y8 = client.WorldToScreen(v); -- [+1, +1, -1]

    if not (x1 and y1 and x2 and y2 and 
        x3 and y3 and x4 and y4 and 
        x5 and y5 and x6 and y6 and 
        x7 and y7 and x8 and y8) then
        return;
    end

    

    -- OUTLINE
    draw.Color(r, g, b, math.floor(flAlpha * 255));
    draw.Line(x1, y1, x8, y8);
    draw.Line(x1, y1, x2, y2);
    draw.Line(x1, y1, x4, y4);

    draw.Line(x6, y6, x3, y3);
    draw.Line(x6, y6, x5, y5);
    draw.Line(x6, y6, x7, y7);

    draw.Line(x3, y3, x2, y2);
    draw.Line(x3, y3, x4, y4);

    draw.Line(x8, y8, x5, y5);
    draw.Line(x8, y8, x7, y7);

    draw.Line(x4, y4, x5, y5);
    draw.Line(x2, y2, x7, y7);

    --FILL
    draw.Color(r, g, b, math.floor(flAlpha * a));
    draw.Triangle(x4, y4, x1, y1, x8, y8);
    draw.Triangle(x4, y4, x5, y5, x8, y8);

    draw.Triangle(x2, y2, x1, y1, x4, y4);
    draw.Triangle(x2, y2, x3, y3, x4, y4);

    draw.Triangle(x3, y3, x4, y4, x5, y5);
    draw.Triangle(x3, y3, x6, y6, x5, y5);

    draw.Triangle(x2, y2, x3, y3, x6, y6);
    draw.Triangle(x2, y2, x7, y7, x6, y6);

    draw.Triangle(x2, y2, x1, y1, x8, y8);
    draw.Triangle(x2, y2, x7, y7, x8, y8);
    
    draw.Triangle(x7, y7, x6, y6, x5, y5);
    draw.Triangle(x7, y7, x8, y8, x5, y5);
end

local g_aImpacts = {};
local g_iLocalIndex = 0;
callbacks.Register("Draw", function()
    local iEnabled = guiEnabled:GetValue();
    if g_bShown ~= (iEnabled == 2) then
        g_bShown = (iEnabled == 2);
        guiSize:SetInvisible(not g_bShown);
        guiDuration:SetInvisible(not g_bShown);
        guiFade:SetInvisible(not g_bShown);
    end

    g_flSize = guiSize:GetValue() or 0;
    g_flDuration = guiDuration:GetValue() or 0;
    g_flFade = math.min((guiFade:GetValue() or 0) / g_flDuration, 0.5);
    g_flFadeInv = 1 - g_flFade;


    if iEnabled == 0 then
        g_aImpacts = {};
        return;
    end

    local pLocalPlayer = entities.GetLocalPlayer();
    if pLocalPlayer then
        g_iLocalIndex = pLocalPlayer:GetIndex();
    end
    
    local vecHalfSize = Vector3(g_flSize / 2, g_flSize / 2, g_flSize / 2);

    local r, g, b, a = guiColor:GetValue();
    
    local flRealTime = globals.RealTime();
    for i, stData in pairs(g_aImpacts) do

        local flDelta = math.abs(flRealTime - stData[2]) / g_flDuration;
        if flDelta > 1 then
            g_aImpacts[i] = nil;

        else
            Draw3DCube(r, g, b, a, flDelta, g_flSize, stData[1]);
        end
    end

    local i, len = 1, #g_aImpacts;
    while(i < len) do
        if not g_aImpacts[i] then
            len = len - 1;
            table.remove(g_aImpacts, i);

        else
            i = i + 1;
        end
    end
end)

callbacks.Register("FireGameEvent", function(ctx)
    if ctx:GetName() ~= "bullet_impact" then
        return;
    end

    local pPlayerController = entities.GetByIndex(ctx:GetInt("userid") + 1);
    if not pPlayerController then
        return;
    end

    if pPlayerController:GetClass() ~= "CCSPlayerController" then
        return;
    end

    local pPawn = pPlayerController:GetPropEntity("m_hPawn");
    if not pPawn then
        return;
    end

    if pPawn:GetIndex() ~= g_iLocalIndex then
        return;
    end

    g_aImpacts[#g_aImpacts + 1] = {
        Vector3(ctx:GetFloat("x"), ctx:GetFloat("y"), ctx:GetFloat("z")), 
        globals.RealTime()
    };
end)
