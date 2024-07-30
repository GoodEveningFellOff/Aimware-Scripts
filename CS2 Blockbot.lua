local master_switch = gui.Checkbox(gui.Reference("MISC", "MOVEMENT", "JUMP"), "blockbot_master", "Blockbot", false)
master_switch:SetDescription("Bind")


local function AquireTargetForPlayer(pPlayer, flDistanceLimit)
    local flDistanceLimit = math.abs(flDistanceLimit or 500);
    if(not pPlayer or not pPlayer:IsAlive())then
        return;
    end

    local vecOrigin = pPlayer:GetAbsOrigin();
    local iEntIndex = pPlayer:GetIndex();
    local flClosestDistance = flDistanceLimit + 1;
    local pClosestTarget;

    for i, pTarget in pairs(entities.FindByClass("C_CSPlayerPawn")) do
        if(pTarget:GetIndex() ~= iEntIndex and pTarget:IsAlive() and pTarget:GetTeamNumber() > 1)then -- player:GetName() ~= "C_CSGO_PreviewPlayer"
            local flDistance = (pTarget:GetAbsOrigin() - vecOrigin):Length();
            if(flDistance < flClosestDistance)then
                flClosestDistance = flDistance;
                pClosestTarget = pTarget;
            end
        end
    end
    
    return(flClosestDistance <= flDistanceLimit) and pClosestTarget or nil;
end

local function Move(cmd, flXMove, flYMove, flScalar)
    -- Input is zero? Just dont move.
    if(flScalar == 0 or (flXMove == 0 and flYMove == 0))then
        cmd:SetForwardMove(0);
        cmd:SetSideMove(0);
        return;
    end

    -- Take the x and y move and turn it into a vector and then into a EulerAngles
    local angMove = (Vector3(flXMove, flYMove, 0)):Angles();
    -- Correct movement for our viewangles
    angMove.y = angMove.y - cmd:GetViewAngles().y;
    -- Convert back into a vector3
    local vecMove = angMove:Forward() * (flScalar or 1);
    -- Set the movement
    cmd:SetForwardMove(vecMove.x);
    cmd:SetSideMove(vecMove.y);
end

local EMethods = {
    [0]      = "NULL";
    [1]      = "HEAD";
    [2]      = "X";
    [3]      = "Y";
    ["NULL"] = 0;
    ["HEAD"] = 1;
    ["X"]    = 2;
    ["Y"]    = 3;
};

local g_pTargetPlayer = nil;
local g_eBlockMethod = EMethods.NULL;

callbacks.Register("Draw", function()
    local pLocalPlayer = entities.GetLocalPlayer();
    if(not pLocalPlayer or not pLocalPlayer:IsAlive())then
        g_pTargetPlayer = nil;
    end
end)

callbacks.Register("PreMove", function(cmd) 
    -- Get the local player and make sure we are alive
    local pLocalPlayer = entities.GetLocalPlayer();
    if(not pLocalPlayer or not pLocalPlayer:IsAlive())then
        g_pTargetPlayer = nil;
        return;
    end

    -- Check if the blockbot is enabled
    if(not master_switch:GetValue())then
        g_pTargetPlayer = nil;
        return;
    end

    -- Aquire a target if we dont have one
    if(not g_pTargetPlayer or not g_pTargetPlayer:IsAlive())then
        g_pTargetPlayer = AquireTargetForPlayer(pLocalPlayer, 500);
        g_eBlockMethod = EMethods.NULL;

        -- If we still dont have a target then return
        if(not g_pTargetPlayer)then
            return;
        end
    end

    local flTickInterval = globals.TickInterval();

    local vecLocalOrigin = pLocalPlayer:GetAbsOrigin();
    local vecLocalVelocity = pLocalPlayer:GetPropVector("m_vecVelocity") * flTickInterval * 3;
    local vecTargetOrigin = g_pTargetPlayer:GetAbsOrigin();
    local vecTargetVelocity = g_pTargetPlayer:GetPropVector("m_vecVelocity") * flTickInterval;

    -- Apply friction to our velocity and predict the velocity out 3 ticks
    vecLocalVelocity.z = 0;
    local flLocalSpeed = vecLocalVelocity:Length2D();
    flLocalSpeed = flLocalSpeed - flLocalSpeed * pLocalPlayer:GetPropFloat("m_flFriction") * client.GetConVar("sv_friction") * flTickInterval * flTickInterval * 3;
    vecLocalVelocity:Normalize();
    vecLocalVelocity = vecLocalVelocity * flLocalSpeed;

    -- How far do we need to move to get to the target
    local vecDeltaOrigin = (vecTargetOrigin + vecTargetVelocity) - vecLocalOrigin;

    -- Get a valid blocking method
    if(g_eBlockMethod == EMethods.NULL)then
        local angDeltaOrigin = vecDeltaOrigin:Angles();

        if(angDeltaOrigin.x > 60)then
            -- We are mostly above the player, thusly we should try to stay on their head
            g_eBlockMethod = EMethods.HEAD;

        else
            -- We are going to body block if we are here
            -- Due to collisions being handled with rectangular prisms between players, we will lock the blocking to an axis
            g_eBlockMethod = (math.abs(vecDeltaOrigin.x) < math.abs(vecDeltaOrigin.y)) and EMethods.X or EMethods.Y;
        end
    end


    local flXMove = 0;
    local flYMove = 0;
    if(g_eBlockMethod == EMethods.HEAD or g_eBlockMethod == EMethods.X)then

        -- 0.5 Unit deadzone
        if(math.abs(vecDeltaOrigin.x) > 0.5)then

            -- If our predicted velocity will have us going past the target, counterstrafe
            if((vecDeltaOrigin.x > 0 and vecDeltaOrigin.x - vecLocalVelocity.x < 0) or (vecDeltaOrigin.x < 0 and vecDeltaOrigin.x - vecLocalVelocity.x > 0)) then
                flXMove = -vecDeltaOrigin.x;
            
            -- Otherwise just move twords the target
            else
                flXMove = vecDeltaOrigin.x;
            end
        end
    end

    if(g_eBlockMethod == EMethods.HEAD or g_eBlockMethod == EMethods.Y)then

        -- 0.5 Unit deadzone
        if(math.abs(vecDeltaOrigin.y) > 0.5)then

            -- If our predicted velocity will have us going past the target, counterstrafe
            if((vecDeltaOrigin.y > 0 and vecDeltaOrigin.y - vecLocalVelocity.y < 0) or (vecDeltaOrigin.y < 0 and vecDeltaOrigin.y - vecLocalVelocity.y > 0)) then
                flYMove = -vecDeltaOrigin.y;
            
            -- Otherwise just move twords the target
            else
                flYMove = vecDeltaOrigin.y;
            end
        end
    end

    Move(cmd, flXMove, flYMove);    
end)
