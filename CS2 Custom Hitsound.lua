local guiRef = gui.Reference("Misc", "General", "Extra");

local guiSelection = gui.Combobox(guiRef, "hitsound", "Hitsound", "Hide", "Show General Settings", "Show File Inputs");
guiSelection:SetDescription("Uses .vsnd_c files placed in the sounds folder.");

local guiRepeatFix = gui.Checkbox(guiRef, "hitsound.repeatfix", "Repeat Fix", true);
guiRepeatFix:SetDescription("Prevent sounds repeating on the same tick.");
guiRepeatFix:SetInvisible(true);

local guiVolume = gui.Slider(guiRef, "hitsound.volume", "Volume", 1, 0, 1.5, 0.01);
guiVolume:SetDescription("Volume of the sounds.");
guiVolume:SetInvisible(true)

local guiHitsound = gui.Editbox(guiRef, "hitsound.hit", "Hitsound File");
guiHitsound:SetDescription("Sound played when you hit someone.");
guiHitsound:SetInvisible(true);

local guiKillsound = gui.Editbox(guiRef, "hitsound.kill", "Killsound File");
guiKillsound:SetDescription("Sound played when you kill someone.");
guiKillsound:SetInvisible(true);

local g_bRepeatFix = false;
local g_flVolume = 0;
local g_sHitsound = false;
local g_sKillsound = false;

local g_iVisibility = 0;

local g_iLastHitTick = 0;
local g_iLastKillTick = 0;

local g_iTickCount = 0;

callbacks.Register("FireGameEvent", function(ctx)
    if ctx:GetName() ~= "player_hurt" then
        return;
    end

    local pVictimController = entities.GetByIndex(ctx:GetInt("userid") + 1);
    local pAttackerController = entities.GetByIndex(ctx:GetInt("attacker") + 1);

    if not pVictimController or not pAttackerController then
        return;
    end

    if pVictimController:GetIndex() == pAttackerController:GetIndex() then
        return;
    end

    if pAttackerController:GetClass() ~= "CCSPlayerController" then
        return;
    end

    local pAttackerPawn = pAttackerController:GetPropEntity("m_hPawn");
    local pLocalPlayer = entities.GetLocalPlayer();
    if not pAttackerPawn or not pLocalPlayer then
        return;
    end

    if pAttackerPawn:GetIndex() ~= pLocalPlayer:GetIndex() or ctx:GetInt("dmg_health") <= 0 then
        return;
    end

    if ctx:GetInt("health") > 0 then
        if (g_bRepeatFix and g_iLastHitTick == g_iTickCount) or not g_sHitsound then
            return;
        end

        g_iLastHitTick = g_iTickCount;

        client.SetConVar("snd_toolvolume", g_flVolume, true);
        client.Command(g_sHitsound, true)
    else
        if (g_bRepeatFix and g_iLastKillTick == g_iTickCount) or not g_sKillsound then
            return;
        end

        g_iLastKillTick = g_iTickCount;

        client.SetConVar("snd_toolvolume", g_flVolume, true);
        client.Command(g_sKillsound, true)
    end
end)

callbacks.Register("Draw", function()
    if g_iTickCount ~= globals.TickCount() then
        g_iTickCount = globals.TickCount();

        g_bRepeatFix = guiRepeatFix:GetValue();
        g_flVolume = guiVolume:GetValue() or 0;

        g_sHitsound = guiHitsound:GetValue() or '';
        g_sHitsound = (g_sHitsound:match("%w")) and ("play sounds\\" .. g_sHitsound) or false;
        
        g_sKillsound = guiKillsound:GetValue() or '';
        g_sKillsound = (g_sKillsound:match("%w")) and ("play sounds\\" .. g_sKillsound) or false;
    end

    local iVisibility = guiSelection:GetValue();
    if iVibility == g_iVisibility then
        return;
    end

    g_iVisibility = iVisibility;
    guiRepeatFix:SetInvisible(iVisibility ~= 1);
    guiVolume:SetInvisible(iVisibility ~= 1);

    guiHitsound:SetInvisible(iVisibility ~= 2);
    guiKillsound:SetInvisible(iVisibility ~= 2);
end)
