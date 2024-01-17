local g_aHitgroups = {
    [0] = "General";
    [1] = "Head";
    [2] = "Chest";
    [3] = "Pelvis";
    [4] = "Left Arm";
    [5] = "Right Arm";
    [6] = "Left Leg";
    [7] = "Right Leg";
};

callbacks.Register("FireGameEvent", function(ctx)
    if ctx:GetName() ~= "player_hurt" then
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

    local pAttackerPawn = pAttackerController:GetPropEntity("m_hPawn");
    local pLocalPlayer = entities.GetLocalPlayer();
    if not pAttackerPawn or not pLocalPlayer then
        return;
    end

    if pAttackerPawn:GetIndex() ~= pLocalPlayer:GetIndex() then
        return;
    end

    if ctx:GetInt("health") > 0 then
        print(("Hurt %s in the %s for %ihp (%ihp remaining)"):format(
            pVictimController:GetPropString("m_iszPlayerName"),
            (g_aHitgroups[ctx:GetInt("hitgroup")] or "General"),
            ctx:GetInt("dmg_health"),
            ctx:GetInt("health")
        ));

    else
        print(("Killed %s with an %ihp attack to the %s"):format(
            pVictimController:GetPropString("m_iszPlayerName"),
            ctx:GetInt("dmg_health"),
            (g_aHitgroups[ctx:GetInt("hitgroup")] or "General")
        ));

    end
end)
