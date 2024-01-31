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

local g_flHalfScreenWidth = 0;
local g_flHalfScreenHeight = 0;

local g_iLocalIndex = 0;
local g_iLocalTeam = 0;
local g_vecLocalAimPos = Vector3(0, 0, 0);

local mp_teammates_are_enemies = 0;

local g_flRenderOriginX = 0;
local g_flRenderOriginY = 0;
do
    g_flRenderOriginX, g_flRenderOriginY = draw.GetScreenSize();
    g_flRenderOriginX, g_flRenderOriginY = g_flRenderOriginX / 2, g_flRenderOriginY / 2;
end

local g_flInnerRadius = 0;
local g_flOuterRadius = 0;

local g_flRCSX = 0;
local g_flRCSY = 0;

local function CalculateModifier()
    local pTarget = nil;
    local flNearest = 0xffffff;

    for _, pEnt in pairs(entities.FindByClass("C_CSPlayerPawn")) do
        if pEnt:GetIndex() ~= g_iLocalIndex and (mp_teammates_are_enemies or g_iLocalTeam ~= pEnt:GetTeamNumber()) and pEnt:IsAlive() and pEnt:IsPlayer() then

            local x1, y1 = client.WorldToScreen(pEnt:GetAbsOrigin() + Vector3(0, 0, 34));
            if x1 and y1 then
                local flDistance = (x1 - g_flHalfScreenWidth)^2 + (y1 - g_flHalfScreenHeight)^2;
                if flDistance < flNearest then
                    pTarget = pEnt;
                    flNearest = flDistance;
                end
            end
        end
    end

    if not pTarget then
        return 1;
    end

    local flLength = (pTarget:GetAbsOrigin() - g_vecLocalAimPos + Vector3(0, 0, 34)):Length();
    if flLength == 0 then
        return 1;
    end

    return 1000 / flLength;
end

local function CalculateRenderPoints(flMin, flMax, vecPunchAngles, flLastFiredWeaponTime)
    local angViewAngles = engine.GetViewAngles();
    local flLerp = math.min(globals.FrameTime() * 10, 0.5);

    local x1, y1 = client.WorldToScreen(g_vecLocalAimPos + (angViewAngles:Forward() * 10000));
    if not (x1 and y1) then
        return false;
    end
    
    local sSubPath = GetActiveSubPath("lbot.weapon.accuracy");
    if vecPunchAngles and gui.GetValue(sSubPath .. ".rcs") ~= 0 and math.abs(flLastFiredWeaponTime) < 0.15 then
        local flRCSX, flRCSY = (gui.GetValue(sSubPath .. ".vrecoil") or 0) / 100, (gui.GetValue(sSubPath .. ".hrecoil") or 0) / 100;

        if not gui.GetValue("esp.other.norecoil") then
            flRCSX = math.max(flRCSX - 0.5, 0);
            flRCSY = math.max(flRCSY - 0.5, 0);
        end

        flRCSX = flRCSX * vecPunchAngles.x * 2;
        flRCSY = flRCSY * vecPunchAngles.y * 2;

        angViewAngles.x = angViewAngles.x + flRCSX;
        angViewAngles.y = angViewAngles.y + flRCSY;
        local flGoalRCSX, flGoalRCSY = client.WorldToScreen(g_vecLocalAimPos + (angViewAngles:Forward() * 10000));
        angViewAngles.x = angViewAngles.x - flRCSX;
        angViewAngles.y = angViewAngles.y - flRCSY;

        if flGoalRCSX and flGoalRCSY then
            g_flRCSX, g_flRCSY = flGoalRCSX - x1, flGoalRCSY - y1;
        else
            g_flRCSX, g_flRCSY = 0, 0;
        end
    else
        g_flRCSX, g_flRCSY = 0, 0;
    end

    g_flRenderOriginX = (g_flHalfScreenWidth + g_flRCSX - g_flRenderOriginX) * flLerp + g_flRenderOriginX;
    g_flRenderOriginY = (g_flHalfScreenHeight + g_flRCSY - g_flRenderOriginY) * flLerp + g_flRenderOriginY;

    angViewAngles.x = angViewAngles.x + flMin;
    local x2, y2 = client.WorldToScreen(g_vecLocalAimPos + (angViewAngles:Forward()  * 10000));
    angViewAngles.x = angViewAngles.x - flMin + flMax;
    local x3, y3 = client.WorldToScreen(g_vecLocalAimPos + (angViewAngles:Forward()  * 10000));

    if (x2 and y2) then
        g_flInnerRadius = (math.sqrt((x2 - x1)^2 + (y2 - y1)^2) - g_flInnerRadius) * flLerp + g_flInnerRadius;
    else
        g_flInnerRadius = (g_flHalfScreenWidth * 2 - g_flInnerRadius) * flLerp + g_flInnerRadius;
    end

    if (x3 and y3) then
        g_flOuterRadius = (math.sqrt((x3 - x1)^2 + (y3 - y1)^2) - g_flOuterRadius) * flLerp + g_flOuterRadius;
    else
        g_flOuterRadius = (g_flHalfScreenWidth * 2 - g_flOuterRadius) * flLerp + g_flOuterRadius;
    end

    return true;
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

callbacks.Register("Draw", function()
    local pLocalPlayer = entities.GetLocalPlayer();
    if not (gui.GetValue("esp.master") and guiMasterSwitch:GetValue()) or globals.MaxClients() == 1 or not pLocalPlayer then
        return;
    end

    if not pLocalPlayer:IsAlive() then
        return;
    end

    g_flHalfScreenWidth, g_flHalfScreenHeight = draw.GetScreenSize();
    g_flHalfScreenWidth, g_flHalfScreenHeight = g_flHalfScreenWidth / 2, g_flHalfScreenHeight / 2;

    g_iLocalIndex = pLocalPlayer:GetIndex();
    g_iLocalTeam = pLocalPlayer:GetTeamNumber();
    g_vecLocalAimPos = pLocalPlayer:GetAbsOrigin() + pLocalPlayer:GetPropVector("m_vecViewOffset");

    mp_teammates_are_enemies = client.GetConVar("mp_teammates_are_enemies");

    local bRage = gui.GetValue("rbot.master");
    if not bRage and not gui.GetValue("lbot.master") then
        return;
    end

    local flMin, flMax = GetAimbotFov(bRage);

    if not bRage then
        local flModifier = CalculateModifier();
        flMin, flMax = flMin * flModifier, flMax * flModifier;
    end

    if flMin >= flMax then
        return;
    end

    if not CalculateRenderPoints(flMin, flMax, 
        (not bRage) and pLocalPlayer:GetPropVector("m_aimPunchAngle") or false,
        globals.CurTime() - pLocalPlayer:GetPropFloat("m_flLastFiredWeaponTime")) then

        return;
    end

    draw.Color(guiFilledColor:GetValue());
    if flMin ~= 0 then
        DrawFilledRing(g_flRenderOriginX, g_flRenderOriginY, g_flInnerRadius, g_flOuterRadius, 24)
        draw.Color(guiOutlineColor:GetValue());
        draw.OutlinedCircle(g_flRenderOriginX, g_flRenderOriginY, g_flInnerRadius);

    else
        draw.FilledCircle(g_flRenderOriginX, g_flRenderOriginY, g_flOuterRadius);
        draw.Color(guiOutlineColor:GetValue());
    end
    draw.OutlinedCircle(g_flRenderOriginX, g_flRenderOriginY, g_flOuterRadius);
end)
