-- Returns a read only version of the table supplied
local function ProtectTable(stIn)
  -- Make sure the input is a table
  if (type(stIn) ~= "table") then
    error("Input must be a table", 2);
  end

  -- Create a new table that uses the input table whenever anything is indexed from the new table
  local stRv = {};
  setmetatable(stRv, {
    __index = stIn;
    __newindex = function(self, k, v)
      return nil;
    end;
  });

  -- Returns the read only table
  return stRv;
end

local EHitgroups = ProtectTable({
  Generic   = 0;
  Head      = 1;
  Chest     = 2;
  Pelvis    = 3;
  LeftArm   = 4;
  RightArm  = 5;
  LeftLeg   = 6;
  RightLeg  = 7;

  ------------------
  
  [0] = "Generic";
  [1] = "Head";
  [2] = "Chest";
  [3] = "Pelvis";
  [4] = "Left Arm";
  [5] = "Right Arm";
  [6] = "Left Leg";
  [7] = "Right Leg";
});

local ETeams = ProtectTable({
  Unassigned       = 0;
  U                = 0;
  Spectator        = 1;
  S                = 1;
  Terrorist        = 2;
  T                = 2;
  CounterTerrorist = 3;
  CT               = 3;

  -------------------------
  
  [0] = "Unassigned";
  [1] = "Spectator";
  [2] = "Terrorist";
  [3] = "CounterTerrorist";

  -- Use ETeams[iTeamNum + 4] for short versions
  [4] = "U";
  [5] = "S";
  [6] = "T";
  [7] = "CT";
});

-- Called on the game event of "player_hurt"
-- Only placed here so it can be referenced by the callback below
local function OnPlayerHurt(ctx) end

callbacks.Register("FireGameEvent", function(ctx)
  if (ctx:GetName() ~= "player_hurt") then
    return;
  end

  -- Structure used for the OnPlayerHurt function
  local stPlayerHurtContext = {
    
    --/* original context
  
    -- player controller index of who was hurt
    userid = ctx:GetInt("userid");

    -- player controller index of who attacked
    attacker = ctx:GetInt("attacker");

    -- victim's remaining health
    health = ctx:GetInt("health");

    -- victim's remaining armor
    armor = ctx:GetInt("armor");

    -- the weapon the attacker used, NOT CURRENTLY WORKING
    weapon = ctx:GetString("weapon");

    -- the damage done to the victim's health
    dmg_health = ctx:GetInt("dmg_health");

    -- the damage done to the victim's armor
    dmg_armor = ctx:GetInt("dmg_armor");

    -- the hitgroup to which the damage was inflicted to the victim
    hitgroup = ctx:GetInt("hitgroup");
    
    --\* original context

    -- If the victim and attacker are on the same team, false if attacker is world
    bSameTeam = false;
 
    -- "userid" or victim data (player who got hurt)
    Victim = {
      -- Entity controller, can be nil
      pController = nil;
      
      -- Entity pawn, can be nil
      pPawn = nil;

      -- Entity name, will be "nil" if not found
      sName = "nil";

      -- If this entity is the local player or not
      bIsLocalPlayer = false;

      -- This entity's team represented with ETeams
      eTeam = ETeams.Unassigned;
    };

    -- "attacker" data (player who inflicted the damage)
    Attacker = {
      -- Entity controller, can be nil
      pController = nil;
      
      -- Entity pawn, can be nil
      pPawn = nil;

      -- Entity name, will be "nil" if not found
      sName = "nil";

      -- If this entity is the local player or not
      bIsLocalPlayer = false;

      -- This entity's team represented with ETeams
      eTeam = ETeams.Unassigned;

      -- If this entity is the world
      bIsWorld = false;
    };
  };

  -- Ensure that the hitgroup is in the enum
  if (not EHitgroups[hitgroup]) then
      hitgroup = EHitgroups.Generic;
  end
  
  -- Get the LocalPlayer so we can set the "bIsLocalPlayer" boolean for the victim and attacker
  local pLocalPlayer = entities.GetLocalPlayer();
  local iLocalPlayerIndex = 0;
  if (pLocalPlayer) then
    iLocalPlayerIndex = pLocalPlayer:GetIndex();
  end

  -- Fill the victim's information
  stPlayerHurtContext.Victim.pController = entities.GetByIndex(
    stPlayerHurtContext.userid + 1
  );
  
  -- Check that we got a controller and that the controller is a player controller
  if (stPlayerHurtContext.Victim.pController) then    
    if (stPlayerHurtContext.Victim.pController:GetClass() == "CCSPlayerController") then

      -- Get the victim's team
      stPlayerHurtContext.Victim.eTeam = stPlayerHurtContext.Victim.pController:GetPropInt("m_iTeamNum");
      
      -- Get the controller's name
      stPlayerHurtContext.Victim.sName = stPlayerHurtContext.Victim.pController:GetPropString("m_iszPlayerName");

      -- Get the pawn from our controller
      stPlayerHurtContext.Victim.pPawn = stPlayerHurtContext.Victim.pController:GetPropEntity("m_hPawn");

      -- Check if the pawn is not nil
      if (stPlayerHurtContext.Victim.pPawn) then
        
        -- Set wether the victim is the local player or not
        -- Only if the local player is valid and the victim's pawn index matches the local player index
        stPlayerHurtContext.Victim.bIsLocalPlayer = (
          pLocalPlayer and stPlayerHurtContext.Victim.pPawn:GetIndex() == iLocalPlayerIndex
        );
      
      end
    end
  end

  -- Fill the attacker's information
  stPlayerHurtContext.Attacker.pController = entities.GetByIndex(
    stPlayerHurtContext.attacker + 1
  );

  -- Check that we got a controller and that the controller is a player controller
  if (stPlayerHurtContext.Attacker.pController) then
    if (stPlayerHurtContext.Attacker.pController:GetClass() == "CCSPlayerController") then
      
      -- Get the attacker's team only
      stPlayerHurtContext.Attacker.eTeam = stPlayerHurtContext.Attacker.pController:GetPropInt("m_iTeamNum");

      -- Get the controller's name
      stPlayerHurtContext.Attacker.sName = stPlayerHurtContext.Attacker.pController:GetPropString("m_iszPlayerName");

      -- Get the pawn from our controller
      stPlayerHurtContext.Attacker.pPawn = stPlayerHurtContext.Attacker.pController:GetPropEntity("m_hPawn");

      -- Check if the pawn is not nil
      if (stPlayerHurtContext.Attacker.pPawn) then
        
        -- Set wether the attacker is the local player or not
        -- Only if the local player is valid and the attacker's pawn index matches the local player index
        stPlayerHurtContext.Attacker.bIsLocalPlayer = (
          pLocalPlayer and stPlayerHurtContext.Attacker.pPawn:GetIndex() == iLocalPlayerIndex
        );
      
      end 
    end
  else
    -- If we didnt get a valid controller entity, then the attacker was (probably) the world!
    stPlayerHurtContext.Attacker.bIsWorld = true;
    stPlayerHurtContext.Attacker.sName = "World";
  end

  -- Set if the players are on the same team if their team numbers are equal and both players are on the CT or T teams
  -- Will also be false if we are in deathmatch (mp_teammates_are_enemies == "true")
  stPlayerHurtContext.bSameTeam = (
    stPlayerHurtContext.Victim.eTeam == stPlayerHurtContext.Attacker.eTeam and
    stPlayerHurtContext.Victim.eTeam > ETeams.Spectator and
    stPlayerHurtContext.Attacker.eTeam > ETeams.Spectator and
    not client.GetConVar("mp_teammates_are_enemies")
  );
  
  -- Call the OnPlayerHurt function passing our newly create PlayerHurtContext
  OnPlayerHurt(stPlayerHurtContext);
end)


--/* Constants

-- Max messages in the log, will clear oldest to make room for new messages
local g_kiMaxMessages = 48;

-- Max age of each message in seconds, they are deleted once their age surpasses this value
local g_kflMaxAge = 10;

-- Lerp in time in seconds for the message addition animation
local g_kflLerpIn = 0.5;

-- Lerp out time in seconds for the message removal animation
local g_kflLerpOut = 0.5;

--\* Constants

local g_aMessages = {};

local g_Font = draw.CreateFont("Consolas", 18, 500);
local g_flRealTime = globals.RealTime();

-- Used while calculating the box of all messages combined (DONT USE)
local g_stCalcBox = {
  iX1 = 0xffffff;
  iY1 = 0xffffff;
  iX2 = 0;
  iY2 = 0;
};

-- Updated at the end of each frame with the surrounding box coordinates of all messages combined (USE)
local g_stBox = {
  iX1 = 0xffffff;
  iY1 = 0xffffff;
  iX2 = 0;
  iY2 = 0;
};


local function LogMessage(...)

  -- First we must take the input data and compress it into a table with respective colors and messages
  local stRenderData = {};
  local iCurrentEntry = 1;
  for i, v in pairs({...}) do

    -- Tables are assumed to be colors
    if (type(v) == "table") then 

      -- Just force this table to be a color, if it fails to be a color in any way we just make it into the color white and continue
      if (#v ~= 3) then
        v = { 255, 255, 255 };

      else
        for k, n in pairs(v) do
          if (type(n) ~= "number") then
            v = { 255, 255, 255 };
            break;
          elseif ( n < 0 or n > 255 or math.floor(n) ~= n) then
            v = { 255, 255, 255 };
            break;
          end
        end
      end 
      
      -- If this entry in the render data table doesnt exist we just create it and continue as normal
      if (not stRenderData[iCurrentEntry]) then
        stRenderData[iCurrentEntry] = {
          sMsg = "";
        };

      -- If this entry does exist and the message isnt empty, we increment the entry number and create a new entry in the render data table
      elseif (stRenderData[iCurrentEntry].sMsg:len() > 0) then
        iCurrentEntry = iCurrentEntry + 1;
        stRenderData[iCurrentEntry] = {
          sMsg = "";
        };
      end

      -- Override the color of the current entry with the new one
      stRenderData[iCurrentEntry].aColor = v;
  
    else
      -- If this entry in the render data table doesnt exist we just create it and continue as normal
      if (not stRenderData[iCurrentEntry]) then
        stRenderData[iCurrentEntry] = {
         aColor = { 255, 255, 255 };
          sMsg = "";
        };
      end

      -- Assume that tostring will never fail, we just append the data we get from it to the message
      stRenderData[iCurrentEntry].sMsg = stRenderData[iCurrentEntry].sMsg .. tostring(v);
    end
  end

  -- Ensure we have messages in the data table
  if (iCurrentEntry == 1) then
    if (not stRenderData[1]) then
      return;
    end

    if (stRenderData[1].sMsg:len() == 0) then
      return;
    end
  end

  -- Take the segments and print them to the aimware console as one big string
  do
    local sFullMessage = "";
    for _, stEntry in pairs(stRenderData) do
      sFullMessage = sFullMessage .. stEntry.sMsg;
    end

    print(sFullMessage);
  end

  -- Store measurements of the messages
  local iWidth = -1;
  local iHeight = -1;
  local iHalfWidth = -1;
  local iHalfHeight = -1;
  
  -- Now that we have a nice "simple" table of renderable information, we create a function just for this data to be rendered to the screen
  local fnDrawText = function(iX, iY, flAlpha, bCenteredX, bCenteredY, fnDrawBackground)

    -- Has to be collected in the draw loop, gets text size of each section and stores it
    if (iWidth <= 0 or iHeight <= 0) then
       for i, stEntry in pairs(stRenderData) do
        stEntry.iOffset = iWidth;

        local iW, iH = draw.GetTextSize(stEntry.sMsg);
        iWidth, iHeight = iWidth + iW, math.max(iHeight, iH);
      end

      iHalfWidth, iHalfHeight = math.floor(iWidth / 2), math.floor(iHeight / 2);
    end

    local iX = (bCenteredX and (iX - iHalfWidth) or iX);
    local iY = (bCenteredY and (iY - iHalfHeight) or iY);

    g_stCalcBox.iX1 = math.min(g_stCalcBox.iX1, iX);
    g_stCalcBox.iY1 = math.min(g_stCalcBox.iY1, iY);
    g_stCalcBox.iX2 = math.max(g_stCalcBox.iX2, iX + iWidth);
    g_stCalcBox.iY2 = math.max(g_stCalcBox.iY2, iY + iHeight);

    -- If we have been provided a function to draw a background then we simply pass all information over and call the function
    if (fnDrawBackground) then
      fnDrawBackground(iX, iY, flAlpha, iWidth, iHeight);
    end

    -- Draw the text
    local iAlpha = math.floor(flAlpha * 255);
    for i, stEntry in pairs(stRenderData) do
      local r, g, b = unpack(stEntry.aColor);
      draw.Color(r, g, b, iAlpha);
      draw.TextShadow(iX + stEntry.iOffset, iY, stEntry.sMsg);
    end

    -- Return the height to offset the next line by
    return math.floor(flAlpha * (iHeight + 6));
  end;

  -- If we already have a full list of messages, push them all forward deleting the oldest
  if (#g_aMessages >= g_kiMaxMessages) then
    for i = 2, g_kiMaxMessages do
      g_aMessages[i - 1] = g_aMessages[i];
    end

    g_aMessages[g_kiMaxMessages] = nil;
  end

  -- Append our message to the end of the list
  g_aMessages[#g_aMessages + 1] = {
    fnDrawText = fnDrawText;
    flRealTime = g_flRealTime;
  };

end

-- Draw our messages to the screen
callbacks.Register("Draw", function()
  draw.SetFont(g_Font);

  g_flRealTime = globals.RealTime();

  -- Render box background only when we have a valid box
  -- will be (0xffffff < 0 and 0xffffff < 0) if the box wasnt properly calculated
  if (g_stBox.iX1 < g_stBox.iX2 and g_stBox.iY1 < g_stBox.iY2) then
    draw.Color(0, 0, 0, 155);
    draw.RoundedRectFill(
      g_stBox.iX1 - 5, 
      g_stBox.iY1 - 10,
      g_stBox.iX2 + 5,
      g_stBox.iY2 + 12,
      10,
      3, 3, 3, 3
    );

    draw.Color(255, 255, 255, 255)
    draw.RoundedRect(
      g_stBox.iX1 - 6, 
      g_stBox.iY1 - 11,
      g_stBox.iX2 + 6,
      g_stBox.iY2 + 13,
      10, 3, 3, 3, 3
    );
  end

  -- Go through each message and render them
  local iHeightOffset = 0;
  for i, stMessage in pairs(g_aMessages) do
    local flAge = math.abs(g_flRealTime - stMessage.flRealTime);
    local flAlpha = (flAge <= g_kflLerpIn) and (flAge / g_kflLerpIn) or (1 - (flAge - (g_kflMaxAge - g_kflLerpOut)) / g_kflLerpOut);
    -- This happens because of (1 - (flAge - (g_kflMaxAge - g_kflLerpOut)) / g_kflLerpOut)
    -- will be greater than one until it finally starts to lerp out
    if (flAlpha > 1) then
      flAlpha = 1;
    end

    -- If our message is too old, we sentence it to death
    if (flAge > g_kflMaxAge) then
      g_aMessages[i] = nil;
    
    else
      iHeightOffset = iHeightOffset + stMessage.fnDrawText(10, 20 + iHeightOffset, flAlpha, false, false);

    end
  end

  -- We loop through our messages removing all messages marked for death
  -- We keep looping until we can make one full pass through the messages without finding a marked one
  local i, len = 1, #g_aMessages;
  while(i < len) do
      if (not g_aMessages[i]) then
          len = len - 1;
          table.remove(g_aMessages, i);

      else
          i = i + 1;
      end
  end

  -- Set the current message box size to the calculated size
  g_stBox.iX1 = g_stCalcBox.iX1;
  g_stBox.iY1 = g_stCalcBox.iY1;
  g_stBox.iX2 = g_stCalcBox.iX2;
  g_stBox.iY2 = g_stCalcBox.iY2;

  -- Reset the calc box size
  g_stCalcBox.iX1 = 0xffffff;
  g_stCalcBox.iY1 = 0xffffff;
  g_stCalcBox.iX2 = 0;
  g_stCalcBox.iY2 = 0;
end)

-- Just lerps from color a to color b based on the health value passed (0 - 100)
local function GetHealthColor(flHealth, bDamage)
  local r = 55;
  local g = 255;
  local b = 55;

  local gr = 255;
  local gg = 55;
  local gb = 55;

  local flHealth = flHealth;
  if (flHealth < 0) then
    flHealth = 0;
  elseif (flHealth > 100) then
    flHealth = 100;
  end

  if (bDamage) then
    flHealth = 100 - flHealth;
  end

  flHealth = flHealth / 100;


  return {
    math.floor(r + (gr - r) * flHealth),
    math.floor(g + (gg - g) * flHealth),
    math.floor(b + (gb - b) * flHealth)
  };
end

-- Called on the game event of "player_hurt"
function OnPlayerHurt(ctx) 
  if (not ctx.Victim.pController) then
    return;
  end

  if (ctx.Victim.bIsLocalPlayer) then
    LogMessage(
      { 255, 255, 255 },
      "[",
      { 255, 55, 55 },
      "AW",
      { 255, 255, 255 },
      "] ",
      { 255, 155, 55 },
      "Hurt ",
      { 255, 255, 255 },
      "by ",
      { 255, 213, 179 },
      (ctx.Attacker.bIsLocalPlayer) and "yourself" or ctx.Attacker.sName,
      { 255, 255, 255 },
      " in the ",
      { 255, 213, 179 },
      EHitgroups[ctx.hitgroup],
      { 255, 255, 255 },
      " for ",
      GetHealthColor(ctx.dmg_health),
      ctx.dmg_health,
      "hp"
    );

    return;
  elseif (not ctx.Attacker.bIsLocalPlayer) then
    return;
  end


  if (ctx.health <= 0) then
    LogMessage(
      { 255, 255, 255 },
      "[",
      { 255, 55, 55 },
      "AW",
      { 255, 255, 255 },
      "] ",
      { 55, 255, 55 },
      "Killed ",
      { 255, 213, 179 },
      ctx.Victim.sName,
      { 255, 255, 255 },
      " in the ",
      { 255, 213, 179 },
      EHitgroups[ctx.hitgroup],
      { 255, 255, 255 },
      " for ",
      GetHealthColor(ctx.dmg_health, true),
      ctx.dmg_health,
      "hp"
    );
  else
    LogMessage(
      { 255, 255, 255 },
      "[",
      { 255, 55, 55 },
      "AW",
      { 255, 255, 255 },
      "] ",
      { 255, 255, 55 },
      "Harmed ",
      { 255, 213, 179 },
      ctx.Victim.sName,
      { 255, 255, 255 },
      " in the ",
      { 255, 213, 179 },
      EHitgroups[ctx.hitgroup],
      { 255, 255, 255 },
      " for ",
      GetHealthColor(ctx.dmg_health, true),
      ctx.dmg_health,
      "hp",
      { 255, 255, 255 },
      " (",
      GetHealthColor(ctx.health),
      ctx.health,
      "hp remaining",
      { 255, 255, 255 },
      ")"
    );
  end
end
