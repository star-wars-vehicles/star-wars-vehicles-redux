--- Star Wars Vehicles: Redux Base
-- @author Doctor Jew
-- @version 0.1
ENT.RenderGroup = RENDERGROUP_OPAQUE
ENT.Base = "base_anim"
ENT.Type = "anim"
ENT.AutomaticFrameAdvance = true
ENT.VehicleType = nil
ENT.IsSWVRVehicle = true

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
  self:NetworkVar("Bool", 6, "TakeOff")
  self:NetworkVar("Bool", 7, "FirstPerson")
  self:NetworkVar("Bool", 8, "Handbrake")
  self:NetworkVar("Bool", 9, "CanFPV")
  self:NetworkVar("Bool", 10, "Back")
  self:NetworkVar("Bool", 11, "Roll")
  self:NetworkVar("Bool", 12, "WingState")
  self:NetworkVar("Bool", 13, "Overheat")
  self:NetworkVar("String", 0, "Allegiance")
  self:NetworkVar("String", 1, "Transponder")
  self:NetworkVar("Int", 0, "Hyperdrive")
  self:NetworkVar("Int", 1, "OverheatLevel")
  self:NetworkVar("Float", 0, "CurHealth")
  self:NetworkVar("Float", 1, "StartHealth")
  self:NetworkVar("Float", 2, "Speed")
  self:NetworkVar("Float", 3, "MaxSpeed")
  self:NetworkVar("Float", 4, "BoostSpeed")
  self:NetworkVar("Float", 5, "VerticalSpeed")
  self:NetworkVar("Float", 6, "NextTorpedo")
  self:NetworkVar("Float", 7, "LandHeight")
  self:NetworkVar("Float", 8, "MinSpeed")
  self:NetworkVar("Float", 9, "AccelSpeed")
  self:NetworkVar("Float", 10, "ShieldHealth")
  self:NetworkVar("Float", 11, "StartShieldHealth")
  self:NetworkVar("Entity", 0, "Pilot")
  self:NetworkVar("Entity", 1, "Avatar")
  self:NetworkVar("Vector", 0, "FPVPos")
end

-- Wrapper functions that follow proper naming standards

function ENT:InFlight(value)
  if not value and value == nil then
    return self:GetFlight()
  end

  self:SetFlight(value)
end

function ENT:CanFreeLook(value)
  if not value and value == nil then
    return self:GetFreeLook()
  end

  self:SetFreeLook(value)
end

function ENT:IsLanding(value)
  if not value and value == nil then
    return self:GetLanding()
  end

  self:SetLanding(value)
end

function ENT:IsCritical(value)
  if not value and value == nil then
    return self:GetCritical()
  end

  self:SetCritical(value)
end

function ENT:HasWings(value)
  if not value and value == nil then
    return self:GetWings()
  end

  self:SetWings(value)
end

function ENT:CanLock(value)
  if not value and value == nil then
    return self:GetLock()
  end

  self:SetLock(value)
end

function ENT:IsTakingOff(value)
  if not value and value == nil then
    return self:GetTakeOff()
  end

  self:SetTakeOff(value)
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

function ENT:GetRelativePos(vector)
  if not vector or not isvector(vector) then
    return self:GetPos()
  end

  return self:GetPos() + self:GetForward() * vector.x * self:GetModelScale() + self:GetRight() * vector.y * self:GetModelScale() + self:GetUp() * vector.z * self:GetModelScale()
end
