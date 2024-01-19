local guiEnabled = gui.Checkbox(gui.Reference("Visuals", "World", "Helper", "Hit Effects"), "damage", "Damage", false);
local guiHeadshot = gui.ColorPicker(guiEnabled, "headshot", "Headshot", 255,  55,  55, 255);
local guiBodyshot = gui.ColorPicker(guiEnabled, "bodyshot", "Bodyshot", 255, 255, 255, 255);

local g_aFonts = {};
do
    for flScale, sKey in pairs({
        [0.75] = 0;
        [1.00] = 1;
        [1.25] = 2;
        [1.50] = 3;
        [1.75] = 4;
        [2.00] = 5;
        [2.25] = 6;
        [2.50] = 7;
        [2.75] = 8;
        [3.00] = 9;
    }) do

        g_aFonts[sKey] = draw.CreateFont("Tahoma", 
            math.floor(flScale * 14 + 0.5), 1000);

    end
end


local g_iLastClearTick = 0;
local g_aImpacts = {};

--[[
    g_aHitmarkers[i] = {
        m_vecImpact;
        m_iDamage;
        m_bHeadshot;
        m_flTime;
    };
]]
local g_aHitmarkers = {};

local g_iLocalIndex = 0;
callbacks.Register("Draw", function()
    if globals.TickCount() ~= g_iLastClearTick then
        g_aImpacts = {};
        g_iLastClearTick = globals.TickCount();
    end

    if not guiEnabled:GetValue() then
        g_aHitmarkers = {};
        return;
    end

    local pLocalPlayer = entities.GetLocalPlayer();
    if pLocalPlayer then
        g_iLocalIndex = pLocalPlayer:GetIndex();
    end

    draw.SetFont(g_aFonts[gui.GetValue("adv.dpi.elements")]);

    local r1, g1, b1, a1 = guiHeadshot:GetValue();
    local r2, g2, b2, a2 = guiBodyshot:GetValue();

    local flRealTime = globals.RealTime();
    for i, stData in pairs(g_aHitmarkers) do

        local flDelta = math.abs(flRealTime - stData.m_flTime) / 3;
        if flDelta > 1 then
            g_aHitmarkers[i] = nil;

        else
            local x, y = client.WorldToScreen(stData.m_vecImpact + Vector3(0, 0, flDelta * 100));
            if x and y then
                local sText = tostring(stData.m_iDamage);
                local w, h = draw.GetTextSize(sText);

                if stData.m_bHeadshot then
                    draw.Color(r1, g1, b1, math.floor(a1 * (1 - flDelta)));
                else
                    draw.Color(r2, g2, b2, math.floor(a2 * (1 - flDelta)));
                end

                draw.TextShadow(math.floor(x - w / 2), math.floor(y - h / 2), sText)
            end
        end
    end

    local i, len = 1, #g_aHitmarkers;
    while(i < len) do
        if not g_aHitmarkers[i] then
            len = len - 1;
            table.remove(g_aHitmarkers, i);

        else
            i = i + 1;
        end
    end
end)


callbacks.Register("FireGameEvent", function(ctx)
    local sEventName = ctx:GetName();

    if sEventName == "bullet_impact" then
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

        g_aImpacts[#g_aImpacts + 1] = Vector3(ctx:GetFloat("x"), ctx:GetFloat("y"), ctx:GetFloat("z"));

    elseif sEventName ~= "player_hurt" then
        return;
    end

    local pVictimController = entities.GetByIndex(ctx:GetInt("userid") + 1);
    local pAttackerController = entities.GetByIndex(ctx:GetInt("attacker") + 1);
    if not pVictimController or not pAttackerController then
        return;
    end

    if pVictimController:GetClass() ~= "CCSPlayerController" or pAttackerController:GetClass() ~= "CCSPlayerController" then
        return;
    end

    local pVictimPawn = pVictimController:GetPropEntity("m_hPawn");
    local pAttackerPawn = pAttackerController:GetPropEntity("m_hPawn");
    if not pVictimPawn or not pAttackerPawn then
        return;
    end

    if pAttackerPawn:GetIndex() ~= g_iLocalIndex or ctx:GetInt("dmg_health") == 0 then
        return;
    end

    local vecVictimOrigin = pVictimPawn:GetAbsOrigin() + Vector3(0, 0, 33);

    local vecClosestImpact = nil;
    local flClosestDistance = 1000;
    for _, vec in pairs(g_aImpacts) do
        local flDistance = (vec - vecVictimOrigin):Length();

        if flDistance < flClosestDistance then
            vecClosestImpact = vec;
            flClosestDistance = flDistance;
        end
    end

    if not vecClosestImpact or ctx:GetInt("hitgroup") == 0 then
        g_aHitmarkers[#g_aHitmarkers + 1] = {
            m_vecImpact = vecVictimOrigin;
            m_iDamage = ctx:GetInt("dmg_health");
            m_bHeadshot = false;
            m_flTime = globals.RealTime();
        };
    
    else
        g_aHitmarkers[#g_aHitmarkers + 1] = {
            m_vecImpact = vecClosestImpact;
            m_iDamage = ctx:GetInt("dmg_health");
            m_bHeadshot = (ctx:GetInt("hitgroup") == 1);
            m_flTime = globals.RealTime();
        };

    end
end)
