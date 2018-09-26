SWVR = SWVR or {}

SWVR.Buttons = {
  IN_ATTACK,
  IN_ATTACK2,
  IN_ZOOM
}

SWVR.Allegiances = {
  Light = {"Rebel Alliance", "Galactic Republic"},
  Dark = {"Imperial Empire", "Confederacy of Independent Systems", "First Order"},
  Neutral = {}
}

SWVR.InputMap = {
  [MOUSE_LEFT]   = IN_ATTACK,
  [MOUSE_RIGHT]  = IN_ATTACK2,
  [MOUSE_MIDDLE] = IN_ZOOM
}

----------------------
-- HELPER FUNCTIONS --
----------------------
function SWVR:CountPlayerOwnedSENTs(class, p)
  local count = 0

  for k, v in pairs(ents.FindByClass(class)) do
    if (v:GetCreator() == p) then
      count = count + 1
    end
  end

  return count
end

function SWVR:GetShips()
  local ships = {}

  for _, ent in ipairs(ents.GetAll()) do
    if not ent.IsSWVRVehicle then continue end
    table.insert(ships, ent)
  end

  return ships
end

function SWVR:GetPilots()
  local pilots = {}

  for _, ent in ipairs(self:GetShips()) do
    if not IsValid(ent:GetPilot()) then continue end
    table.insert(pilots, ent:GetPilot())
  end

  return pilots
end

function SWVR:GetPassengers()
  local passengers = {}

  for _, ply in ipairs(player.GetAll()) do
    if ply:GetNWBool("Flying") and not ply:GetNWBool("Pilot") then
      table.insert(passengers, ply)
    end
  end

  return passengers
end

function SWVR:GetWeapons()
  local weapons = {}

  for _, ship in ipairs(self:GetShips()) do
    table.Merge(weapons, ship:GetWeapons())
  end

  return weapons
end

function SWVR:LightOrDark(allegiance)
  return table.HasValue(self.Allegiances.Light, allegiance) and "Light" or table.HasValue(self.Allegiances.Dark, allegiance) and "Dark" or "Neutral"
end