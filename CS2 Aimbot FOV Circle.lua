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

local stScreen = {
    m_iWidth      = 0;
    m_iHeight     = 0;
    m_iHalfWidth  = 0;
    m_iHalfHeight = 0;
};

local function UpdateScreenSize()
    local iWidth, iHeight = draw.GetScreenSize();

    if iWidth == stScreen.m_iWidth and iHeight == stScreen.m_iHeight then
        return;
    end

    stScreen.m_iWidth      = iWidth;
    stScreen.m_iHeight     = iHeight;
    stScreen.m_iHalfWidth  = math.floor(iWidth / 2);
    stScreen.m_iHalfHeight = math.floor(iHeight / 2);
end

local function GetAimbotFov(bRage)
    if bRage then
        return gui.GetValue("rbot.aim.target.fov");
    end

    return gui.GetValue(GetActiveSubPath("lbot.weapon.target") .. ".maxfov"); 
end

callbacks.Register("Draw", function()
    if not (gui.GetValue("esp.master") and guiMasterSwitch:GetValue()) then
        return;
    end

    if globals.MaxClients() == 1 then
        return;
    end

    local pLocalPlayer = entities.GetLocalPlayer();
    if not pLocalPlayer then
        return;
    end

    if not pLocalPlayer:IsAlive() then
        return;
    end

    UpdateScreenSize();

    local bRage = gui.GetValue("rbot.master");

    if not bRage and not gui.GetValue("lbot.master") then
        return;
    end

    local flView = math.tan(math.rad((gui.GetValue("esp.world.fov") or 90) / 2));
    local flAimbot = math.tan(math.rad(GetAimbotFov(bRage) / 2)); 

    local iRadius = math.floor(flAimbot / flView * stScreen.m_iHeight);

    draw.Color(guiFilledColor:GetValue());
    draw.FilledCircle(stScreen.m_iHalfWidth, stScreen.m_iHalfHeight, iRadius);
    draw.Color(guiOutlineColor:GetValue());
    draw.OutlinedCircle(stScreen.m_iHalfWidth, stScreen.m_iHalfHeight, iRadius);
end)
