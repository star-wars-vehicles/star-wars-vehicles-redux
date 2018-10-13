--- Star Wars Vehicles: Redux Base
-- @author Doctor Jew
-- @version 0.1
ENT.RenderGroup = RENDERGROUP_OPAQUE
ENT.Base = "base_anim"
ENT.Type = "anim"
ENT.AutomaticFrameAdvance = true
ENT.Class = "Other"
ENT.IsSWVRVehicle = true

local function AccessorBool(tbl, name, prefix)
  tbl[prefix .. name] = function(self, value)
    if value == nil then
      return tobool(self["Get" .. name](self))
    end

    self["Set" .. name](self, value)
  end
end

--- Creates networked variables for the entity.
-- This creates setter and getter functions for each variable.
-- Example: self:NetworkVar("Bool", 0, "Flight") creates self:GetFlight() and self:SetFlight()
function ENT:SetupDataTables()
  self:NetworkVar("Bool", 0, "Flight")
  self:NetworkVar("Bool", 1, "FreeLook")
  self:NetworkVar("Bool", 2, "Critical")
  self:NetworkVar("Bool", 3, "Wings")
  self:NetworkVar("Bool", 4, "Lock")
  self:NetworkVar("Bool", 5, "Landing")
  self:NetworkVar("Bool", 6, "TakingOff")
  self:NetworkVar("Bool", 7, "FirstPerson")
  self:NetworkVar("Bool", 8, "Handbrake")
  self:NetworkVar("Bool", 9, "CanFPV")
  self:NetworkVar("Bool", 10, "Back")
  self:NetworkVar("Bool", 11, "Roll")
  self:NetworkVar("Bool", 12, "WingState")
  self:NetworkVar("Bool", 13, "AutoCorrect")

  self:NetworkVar("String", 0, "Allegiance")
  self:NetworkVar("String", 1, "Transponder")

  self:NetworkVar("Int", 0, "Hyperdrive")
  self:NetworkVar("Int", 1, "Ion")

  self:NetworkVar("Float", 0, "CurHealth")
  self:NetworkVar("Float", 1, "StartHealth")
  self:NetworkVar("Float", 2, "Speed")
  self:NetworkVar("Float", 3, "MaxSpeed")
  self:NetworkVar("Float", 4, "BoostSpeed")
  self:NetworkVar("Float", 5, "VerticalSpeed")
  self:NetworkVar("Float", 6, "LandHeight")
  self:NetworkVar("Float", 7, "MinSpeed")
  self:NetworkVar("Float", 8, "AccelSpeed")
  self:NetworkVar("Float", 9, "ShieldHealth")
  self:NetworkVar("Float", 10, "StartShieldHealth")

  self:NetworkVar("Entity", 0, "Pilot")
  self:NetworkVar("Entity", 1, "Avatar")

  self:NetworkVar("Vector", 0, "FPVPos")

  -- Wrapper functions that follow proper naming standards
  AccessorBool(self, "AutoCorrect", "Should")
  AccessorBool(self, "FreeLook", "Can")
  AccessorBool(self, "Lock", "Can")
  AccessorBool(self, "Flight", "In")
  AccessorBool(self, "TakingOff", "Is")
  AccessorBool(self, "Landing", "Is")
  AccessorBool(self, "Critical", "Is")
  AccessorBool(self, "Wings", "Has")
end

--- Get child entities of ship.
-- Checks all entities with a parent that is self.
function ENT:GetChildEntities()
  local filter = {}
  local i = 1

  for k, v in pairs(ents.GetAll()) do
    if (v:GetParent() == self) then
      filter[i] = v
      i = i + 1
    end
  end

  filter[i] = self
  local p

  if CLIENT then
    p = LocalPlayer()
  elseif SERVER then
    if (IsValid(self.Pilot)) then
      p = self.Pilot
    end
  end

  if (IsValid(p)) then
    filter[i + 1] = p
  end

  return filter
end

function ENT:CheckHook(value)
  return not value and value ~= nil
end

-- Find a target
-- Finds a target in a Cone in front of the ship.
function ENT:FindTarget()
  local targets = ents.FindInCone(self:GetPos(), self:GetForward(), 100000, math.cos(0.1))

  for _, ent in pairs(targets) do
    -- TODO Check for ships that can't be locked on to (cloak/jammer/etc.)
    if (IsValid(ent) and ent:IsStarWarsVehicle() and ent ~= self and not IsValid(ent:GetParent()) and ent:GetAllegiance() ~= self:GetAllegiance()) then
        local origin = (ent:GetPos() - self:GetPos())
        origin:Normalize()
        origin = self:GetPos() + origin * 100

        local tr = util.TraceLine({
          start = origin,
          endpos = ent:GetPos()
        })

        if (not tr.HitWorld) then
          return ent
        end
    end
  end

  return NULL
end
