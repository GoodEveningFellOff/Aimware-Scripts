local guiRef = gui.Multibox(gui.Reference("Misc", "Enhancement", "Appearance"), "Camera Fucker");

local guiParkinsons = gui.Checkbox(guiRef, "camerafucker.parkinsons", "Parkinsons", false);
guiParkinsons:SetDescription("2° Random jitter for pitch and yaw.");
local guiRoll = gui.Checkbox(guiRef, "camerafucker.roll", "Roll Angles", false);
guiRoll:SetDescription("Roll your camera -45° to 45° randomly.");

local CLAMP=function(a,b,c)return(a<b)and b or(a>c)and c or a;end;

local g_bSafeMode = false;
callbacks.Register("CreateMove", function(cmd)
    local pLocalPlayer = entities.GetLocalPlayer();
    if not pLocalPlayer or g_bSafeMode or bit.band(cmd:GetButtons(), 32) ~= 0 then
        return;
    end

    if not pLocalPlayer:IsAlive() then
        return;
    end

    local angViewAngles = cmd:GetViewAngles();
    if pLocalPlayer:GetWeaponType() ~= 9 and guiParkinsons:GetValue() then
        angViewAngles.x = CLAMP(angViewAngles.x, -88, 88) + math.random(-10, 10) / 10;
        angViewAngles.y = angViewAngles.y + math.random(-10, 10) / 10;
    end

    if guiRoll:GetValue() then
        angViewAngles.z = math.random(-2, 2) * 22.5;
    end

    cmd:SetViewAngles(angViewAngles);
end)

callbacks.Register("Draw", function()
    local bSafeMode = gui.GetValue("misc.antiuntrusted") or not gui.GetValue("misc.master");

    if bSafeMode ~= g_bSafeMode then
        guiRef:SetDisabled(bSafeMode);
        g_bSafeMode = bSafeMode;
    end
end)
