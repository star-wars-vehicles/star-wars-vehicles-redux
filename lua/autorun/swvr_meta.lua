--- Star Wars Vehicles Player Meta
-- @module Player
-- @alias PLAYER
-- @author Doctor Jew

-- PLAYER META

local PLAYER = FindMetaTable("Player")

--- Check if a player has a button down.
-- @shared
-- @param button Any KEY_CODE enum
-- @treturn bool If the button is down
-- @see ButtonUp
function PLAYER:ButtonDown(button)
  return self.Inputs[button]
end

--- Check if a player has a button up.
-- @shared
-- @param button Any KEY_CODE enum
-- @treturn bool If the button is up
-- @see ButtonDown
function PLAYER:ButtonUp(button)
  return not self.Inputs[button]
end

--- Check if a player has a SWVR control down.
-- @shared
-- @string control The suffix of the control
-- @treturn bool If the control is down or not
-- @usage local eject = ply:ControlDown("eject")
-- @see ControlUp
function PLAYER:ControlDown(control)
  local key = self:GetInfoNum("swvr_key_" .. string.lower(control), KEY_NONE)
  return self:ButtonDown(key)
end

--- Check if a player has a SWVR control up.
-- @shared
-- @string control The suffix of the control
-- @treturn bool If the control is up or not
-- @usage local eject = ply:ControlUp("eject")
-- @see ControlDown
function PLAYER:ControlUp(control)
  local key = self:GetInfoNum("swvr_key_" .. string.lower(control), KEY_NONE)
  return self:ButtonUp(key)
end

--- Check if a player has a control set.
-- @shared
-- @string control The control to check
-- @treturn bool If the player has the control set
-- @usage local has_eject = ply:ControlSet("eject")
function PLAYER:ControlSet(control)
  return self:GetInfoNum("swvr_key_" .. string.lower(control), KEY_NONE) ~= 0
end

--- Get the player's current SWVR vehicle, if any.
-- @shared
-- @treturn entity The current vehicle entity or NULL
function PLAYER:GetSWVehicle()
  local seat = self:GetVehicle()

  if not IsValid(seat) then return NULL end

  local parent = seat:GetParent()

  if not IsValid(parent) or not parent.IsSWVRVehicle then return NULL end

  return parent
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

if game.SinglePlayer() then
  if SERVER then
    util.AddNetworkString("SWVR.PlayerButtonDown")
  else
    net.Receive("SWVR.PlayerButtonDown", function()
        local ply = net.ReadEntity()
        local button = net.ReadInt(10)
        local down = net.ReadBool()
        ply.Inputs = ply.Inputs or {}
        ply.Inputs[button] = down
    end)
  end
end
