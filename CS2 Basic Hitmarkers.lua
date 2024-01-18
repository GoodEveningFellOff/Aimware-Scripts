local g_iFont = draw.CreateFont("Tahoma", 20, 1000);

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

    local pLocalPlayer = entities.GetLocalPlayer();
    if pLocalPlayer then
        g_iLocalIndex = pLocalPlayer:GetIndex();
    end

    draw.SetFont(g_iFont);

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
                    draw.Color(255, 55, 55, math.floor(255 * (1 - flDelta)));
                else
                    draw.Color(255, 255, 255, math.floor(255 * (1 - flDelta)));
                end

                draw.TextShadow(math.floor(x - w / 2), math.floor(y - h / 2), sText)
            end
        end
    end

    for _ = 1, 5 do
        local bPassed = true;
        for i = 1, #g_aHitmarkers do
            if not g_aHitmarkers[i] then
                bPassed = false;
                table.remove(g_aHitmarkers, i);
                break;
            end
        end

        if bPassed then
            break;
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
