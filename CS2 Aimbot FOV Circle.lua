local guiRef = gui.Reference("Visuals", "Other", "Extra");

local guiMasterSwitch = gui.Checkbox(guiRef, "aimbot_fov_circle", "Aimbot Fov Circle", false);
guiMasterSwitch:SetDescription("Visualize aimbot fov.");

local guiFilledColor = gui.ColorPicker(guiMasterSwitch, "filled_fov_circle_clr", "Filled Fov Circle Clr", 255, 155, 55, 55);
local guiOutlineColor = gui.ColorPicker(guiMasterSwitch, "outline_fov_circle_clr", "Outline Fov Circle Clr", 255, 155, 55, 255);

local GetActiveSubPath = (function()
    local aRageWeapons = {
        ["\"Shared\""] =            "shared";
		["\"Zeus\""] =              "zeus";
		["\"Pistol\""] =            "pistol";
		["\"Heavy Pistol\""] =      "hpistol";
		["\"Submachine Gun\""] =    "smg";
		["\"Rifle\""] =             "rifle";
		["\"Shotgun\""] =           "shotgun";
		["\"Scout\""] =             "scout";
		["\"Auto Sniper\""] =       "asniper";
		["\"Sniper\""] =            "sniper";
		["\"Light Machine Gun\""] = "lmg";
		["\"Knife\""] =             "knife";
    };


    return function(sPath, bRaw)
        if bRaw then
            return aRageWeapons[gui.GetValue(sPath)] or "shared";
        end

        return sPath .. '.' .. (aRageWeapons[gui.GetValue(sPath)] or "shared");
    end
end)();

local function GetAimbotFov(bRage)
    if bRage then
        return 0, gui.GetValue("rbot.aim.target.fov");
    end

    local sPath = GetActiveSubPath("lbot.weapon.target");
    return gui.GetValue(sPath .. ".minfov"), gui.GetValue(sPath .. ".maxfov"); 
end

local function DrawFilledRing(x0, y0, flInner, flOuter)
    local fl2PI = 2 * math.pi;
    local flSegSize = fl2PI / 45;

    local x1, y1, x2, y2;
    do
        local c1, s1 = math.cos(-flSegSize), math.sin(-flSegSize);
        local c2, s2 = math.cos(0), math.sin(0);

        x1, y1 = x0 + math.floor(c1 * flInner + 0.5), y0 + math.floor(s1 * flInner + 0.5);
        x2, y2 = x0 + math.floor(c1 * flOuter + 0.5), y0 + math.floor(s1 * flOuter + 0.5);
        local x3, y3 = x0 + math.floor(c2 * flInner + 0.5), y0 + math.floor(s2 * flInner + 0.5);
        local x4, y4 = x0 + math.floor(c2 * flOuter + 0.5), y0 + math.floor(s2 * flOuter + 0.5);

        draw.Triangle(x1, y1, x2, y2, x4, y4);
        draw.Triangle(x1, y1, x4, y4, x3, y3);

        x1, y1, x2, y2 = x3, y3, x4, y4;
    end

    for i = 0, fl2PI - flSegSize / 2, flSegSize do
        local c2, s2 = math.cos(i), math.sin(i);
        local x3, y3 = x0 + math.floor(c2 * flInner + 0.5), y0 + math.floor(s2 * flInner + 0.5);
        local x4, y4 = x0 + math.floor(c2 * flOuter + 0.5), y0 + math.floor(s2 * flOuter + 0.5);

        draw.Triangle(x1, y1, x2, y2, x4, y4);
        draw.Triangle(x1, y1, x4, y4, x3, y3);

        x1, y1, x2, y2 = x3, y3, x4, y4;
    end

end

local g_flInner = 0;
local g_flOuter = 0;

callbacks.Register("Draw", function()
    local pLocalPlayer = entities.GetLocalPlayer();
    if not (gui.GetValue("esp.master") and guiMasterSwitch:GetValue()) or globals.MaxClients() == 1 or not pLocalPlayer then
        return;
    end

    if not pLocalPlayer:IsAlive() then
        return;
    end

    local bRage = gui.GetValue("rbot.master");
    if not bRage and not gui.GetValue("lbot.master") then
        return;
    end

    local flMin, flMax = GetAimbotFov(bRage);

    if flMin >= flMax then
        return;
    end

    local vecViewOrigin = pLocalPlayer:GetAbsOrigin() + pLocalPlayer:GetPropVector("m_vecViewOffset");
    local angViewAngles = engine.GetViewAngles();

    local x0, y0 = draw.GetScreenSize();
    x0, y0 = math.floor(x0 / 2), math.floor(y0 / 2);

    local x1, y1 = client.WorldToScreen(vecViewOrigin + (angViewAngles:Forward() * 10000));
    angViewAngles.x = angViewAngles.x + flMin;
    local x2, y2 = client.WorldToScreen(vecViewOrigin + (angViewAngles:Forward()  * 10000));
    angViewAngles.x = angViewAngles.x - flMin + flMax;
    local x3, y3 = client.WorldToScreen(vecViewOrigin + (angViewAngles:Forward()  * 10000));

    if not (x1 and y1 and x2 and y2 and x3 and y3) then
        return;
    end

    local flLerp = math.min(globals.FrameTime() * 10, 0.5);
    g_flInner = (math.sqrt((x2 - x1)^2 + (y2 - y1)^2) - g_flInner) * flLerp + g_flInner;
    g_flOuter = (math.sqrt((x3 - x1)^2 + (y3 - y1)^2) - g_flOuter) * flLerp + g_flOuter;

    draw.Color(guiFilledColor:GetValue());
    if flMin ~= 0 then
        DrawFilledRing(x0, y0, g_flInner, g_flOuter, 24)
        draw.Color(guiOutlineColor:GetValue());
        draw.OutlinedCircle(x0, y0, g_flInner);

    else

        draw.FilledCircle(x0, y0, g_flOuter);
        draw.Color(guiOutlineColor:GetValue());
    end
    draw.OutlinedCircle(x0, y0, g_flOuter);
end)
