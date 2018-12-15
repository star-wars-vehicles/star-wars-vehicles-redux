if SERVER then
  util.AddNetworkString("SWVR.PlayerButtonDown")
end

-- PLAYER META

local PLAYER = FindMetaTable("Player")

function PLAYER:ButtonDown(button)
  return self.Inputs[button]
end

function PLAYER:ButtonUp(button)
  return not self.Inputs[button]
end

function PLAYER:ControlDown(control)
  local key = self:GetInfoNum("swvr_key_" .. string.lower(control), KEY_NONE)
  return self:ButtonDown(key)
end

function PLAYER:ControlUp(control)
  local key = self:GetInfoNum("swvr_key_" .. string.lower(control), KEY_NONE)
  return self:ButtonUp(key)
end

function PLAYER:ControlSet(control)
  return self:GetInfoNum("swvr_key_" .. string.lower(control), KEY_NONE) ~= 0
end

function PLAYER:GetSWVehicle()
  local seat = self:GetVehicle()

  if not IsValid(seat) then return NULL end

  local parent = seat:GetParent()

  if not IsValid(parent) or not parent.IsSWVRVehicle then return NULL end

  return parent
end

-- PHYSOBJ META

local PHYSOBJ = FindMetaTable("PhysObj")

function PHYSOBJ:ApplyForceAngle(force)
  if not IsValid(self) then return end

  local ent = self:GetEntity()

  local up = ent:GetUp()
  local fw = ent:GetForward()
  local lt = -ent:GetRight()

  local pitch = up * force.p * 0.5
  self:ApplyForceOffset(fw, pitch)
  self:ApplyForceOffset(-fw, -pitch)

  local yaw = fw * force.y * 0.5
  self:ApplyForceOffset(lt, yaw)
  self:ApplyForceOffset(-lt, -yaw)

  local roll = lt * force.r * 0.5
  self:ApplyForceOffset(up, roll)
  self:ApplyForceOffset(-up, -roll)
end

-- GM HOOKS

hook.Add("PlayerButtonDown", "SWVR.PlayerButtonDown", function(ply, button)
  ply.Inputs = ply.Inputs or {}

  ply.Inputs[button] = true

  if game.SinglePlayer() then
    net.Start("SWVR.PlayerButtonDown")
      net.WriteEntity(ply)
      net.WriteInt(button, 10)
      net.WriteBool(true)
    net.Send(ply)
  end
end)

hook.Add("PlayerButtonUp", "SWVR.PlayerButtonUp", function(ply, button)
  ply.Inputs = ply.Inputs or {}

  ply.Inputs[button] = false

  if game.SinglePlayer() then
  net.Start("SWVR.PlayerButtonDown")
    net.WriteEntity(ply)
    net.WriteInt(button, 10)
    net.WriteBool(false)
  net.Send(ply)
  end
end)

hook.Add("PlayerInitialSpawn", "SWVR.PlayerInitialSpawn", function(ply)
  ply.Inputs = ply.Inputs or {}
end)

hook.Add("OnSpawnMenuOpen", "SWVROnSpawnMenuOpen", function()
  if LocalPlayer():GetNWBool("Flying") and LocalPlayer():GetInfoNum("swvr_key_modifier", KEY_Q) == KEY_Q then return false end
end)

hook.Add("PlayerLeaveVehicle", "SWVR.PlayerLeaveVehicle", function(ply, veh)
  if not (IsValid(ply) and IsValid(veh)) then return end

  local ent = veh:GetParent()

  if not (IsValid(ent) and ent.IsSWVRVehicle) then return end

  veh:SetNWEntity("Driver", NULL)

  ent:DispatchEvent("Exit", ply)
end)

net.Receive("SWVR.PlayerButtonDown", function()
  local ply = net.ReadEntity()
  local button = net.ReadInt(10)
  local down = net.ReadBool()

  ply.Inputs = ply.Inputs or {}

  ply.Inputs[button] = down
end)
