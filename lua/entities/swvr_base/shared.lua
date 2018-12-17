--- Star Wars Vehicles Flight Base
-- @module ENT
-- @author Doctor Jew

ENT.Type = "anim"

--- Nice display name of the entity
ENT.PrintName = "SWVR Base"

--- Author of the `Entity`
ENT.Author = "Doctor Jew"

ENT.Information = ""

--- `Entity` category, used to assign to a faction
ENT.Category = "Other"

--- Vehicle class (fighter, bomber, etc.)
ENT.Class = "Other"
ENT.IsSWVRVehicle = true

ENT.Spawnable = false
ENT.AdminSpawnable = false

ENT.AutomaticFrameAdvance = true
ENT.Rendergroup = RENDERGROUP_BOTH
ENT.Editable =  true

-- Customizable Settings

--- Maximum health of the vehicle
ENT.MaxHealth = 1000

--- Maximum shields of the vehicle, if any
ENT.MaxShield = 0

ENT.Mass = 2000
ENT.Inertia = Vector(250000, 250000, 250000)

ENT.MaxVelocity = 2500

ENT.MaxPower = 500

ENT.MaxThrust = 1200
ENT.BoostThrust = 2000

--- How fast can the vehicle pitch/yaw/roll?
ENT.Handling = Vector(300, 300, 300)

ENT.Controls = {
  Wings = Vector(),
  Elevator = Vector(),
  Rudder = Vector(),
  Thrust = Vector()
}

ENT.Engines = nil
ENT.Parts = nil
ENT.Seats = nil

-- Base Setup and Networking

local AccessorBool = swvr.util.AccessorBool

--- Setup functions
-- @section setup

function ENT:SetupDataTables()
  self:NetworkVar("Bool", 0, "Active")
  self:NetworkVar("Bool", 1, "Destroyed")
  self:NetworkVar("Bool", 2, "EngineActive")

  self:NetworkVar("Int", 0, "Allegiance", { KeyName = "allegiance", Edit = { type = "Int", order = 1, min = 0, max = 2, category = "Details" } })
  self:NetworkVar("Int", 1, "SeatCount")
  self:NetworkVar("Int", 2, "WeaponCount")

  self:NetworkVar("Float", 0, "HP", { KeyName = "health", Edit = { type = "Float", order = 1, min = 0, max = self.MaxHealth, category = "Condition" } })
  self:NetworkVar("Float", 1, "MaxHP")
  self:NetworkVar("Float", 2, "Shield", { KeyName = "shield", Edit = { type = "Float", order = 2, min = 0, max = self.MaxShield or 0, category = "Condition" } })
  self:NetworkVar("Float", 3, "MaxShield")

  self:NetworkVar("Float", 4, "Thrust")
  self:NetworkVar("Float", 5, "TargetThrust")
  self:NetworkVar("Float", 6, "MaxThrust")
  self:NetworkVar("Float", 7, "BoostThrust")

  self:NetworkVar("Float", 8, "NextPrimaryFire")
  self:NetworkVar("Float", 9, "NextSecondaryFire")
  self:NetworkVar("Float", 10, "NextAlternateFire")

  self:NetworkVar("Float", 11, "MaxVelocity")
  self:NetworkVar("Float", 12, "MaxPower")

  self:NetworkVar("Float", 13, "PrimaryOverheat")
  self:NetworkVar("Float", 14, "SecondaryOverheat")

  self:NetworkVar("String", 0, "Transponder")

  -- Generate nice helper functions
  AccessorBool(self, "Destroyed", "Is")
  AccessorBool(self, "Active", "Is")
  AccessorBool(self, "EngineActive", "")

  if SERVER then
    self:NetworkVarNotify("HP", function(ent, name, old, new)
      ent:SetHealth(new)
    end)

    self:NetworkVarNotify("MaxHP", function(ent, name, old, new)
      ent:SetMaxHealth(new)
    end)

    self:SetActive(false)
    self:SetDestroyed(false)
    self:SetEngineActive(false)

    self:SetMaxVelocity(self.MaxVelocity)
    self:SetHP(self.MaxHealth)
    self:SetShield(self.MaxShield or 0)
    self:SetMaxShield(self.MaxShield or 0)
    self:SetMaxHP(self.MaxHealth)
    self:SetThrust(0)
    self:SetMaxThrust(self.MaxThrust)
    self:SetBoostThrust(self.BoostThrust)
    self:SetMaxPower(self.MaxPower)

    self:SetNextPrimaryFire(CurTime())
    self:SetNextSecondaryFire(CurTime())
    self:SetNextAlternateFire(CurTime())

    self:SetAllegiance(1)
    self:SetSeatCount(0)
  end
end

--- Setup default vehicle events. This is shared but will product different results on client/server.
-- @shared
-- @param options The events to explicitly disable
function ENT:SetupDefaults(options)
  options = options or {}

  if SERVER then
    if options.OnEnter ~= false then
      self:AddEvent("OnEnter", function(ent, ply, pilot)
        if not pilot then return end
        ent:EmitSound("vehicles/atv_ammo_close.wav")
      end)
    end

    if options.OnExit ~= false then
      self:AddEvent("OnExit", function(ent, ply, pilot)
        if not pilot then return end
        ent:EmitSound("vehicles/atv_ammo_open.wav")
      end)
    end
  end
end

-- Vehicle Physics

function ENT:GetStability()
  return self:WaterLevel() > 2 and 0 or (self:IsDestroyed() and 0.1 or (self:EngineActive() and 0.7 or 0))
end

--- Seat Functions
-- @section seats

--- Add a seat to the vehicle. The first seat is always the pilot.
-- @server
-- @param name The name of the seat for easy reference
-- @param pos The position of the seat in local coordinated
-- @param ang The angles of the seat in local angles
-- @return The seat entity itself for convenience
function ENT:AddSeat(name, pos, ang)
  if CLIENT then return end

  assert(not self.Initialized, "[SWVR] Seats cannot be added after the vehicle is initialized! (This can cause weird bugs)")

  local seat = ents.Create("prop_vehicle_prisoner_pod")

  if not IsValid(seat) then SafeRemoveEntity(self) error("[SWVR] Failed to create a seat for a vehicle! Removing vehicle safely.") end

  seat:SetMoveType(MOVETYPE_NONE)
  seat:SetModel("models/nova/airboat_seat.mdl")
  seat:SetKeyValue("vehiclescript", "scripts/vehicles/prisoner_pod.txt")
  seat:SetKeyValue("limitview", 0)
  seat:SetPos(pos and self:LocalToWorld(pos) or self:GetPos())
  seat:SetAngles(ang and self:LocalToWorldAngles(ang) or self:GetAngles())
  seat:SetOwner(self)
  seat:Spawn()
  seat:Activate()
  seat:SetParent(self)
  seat:SetNotSolid(true)
  seat:DrawShadow(false)
  seat:SetColor(Color(255, 255, 255, 0))
  seat:SetRenderMode(RENDERMODE_TRANSALPHA)
  seat.DoNotDuplicate = true

  local phys = seat:GetPhysicsObject()

  if IsValid(phys) then
    phys:EnableDrag(false)
    phys:EnableMotion(false)
    phys:SetMass(1)
  end

  self:DeleteOnRemove(seat)

  seat:SetNWBool("SWVRSeat", true)
  seat:SetNWInt("SWVR.SeatIndex", self:GetSeatCount() + 1)
  seat:SetNWString("SWVR.SeatName", string.upper(name))

  -- CPPI support
  if seat.CPPISetOwner and self.CPPIGetOwner then
    seat:CPPISetOwner(self:CPPIGetOwner())
  end

  self:SetSeatCount(self:GetSeatCount() + 1)

  return seat
end

--- Retrieve an actual seat entity.
-- @shared
-- @param index The index of the seat. Can be a number or string.
-- @return The found entity or NULL
function ENT:GetSeat(index)
  self.Seats = self.Seats or {}

  -- Have we cached the entity for the server/client?
  local seat = self.Seats[index]
  if IsValid(seat) and ((isstring(index) and seat:GetNWString("SWVR.SeatName") == index) or (isnumber(index) and seat:GetNWInt("SWVR.SeatIndex") == index)) then
    return seat
  end

  -- Loop over children instead of Seats table because the table isn't networked but children are
  for _, child in ipairs(self:GetChildren()) do
    if not (child:IsVehicle() and child:GetClass():lower() == "prop_vehicle_prisoner_pod") then continue end

    if isstring(index) and child:GetNWString("SWVR.SeatName", "") ~= string.upper(index) then continue end
    if isnumber(index) and child:GetNWInt("SWVR.SeatIndex", 0) ~= index then continue end

    self.Seats[index] = child

    return child
  end

  return NULL
end

function ENT:GetSeats()
  self.Seats = self.Seats or {}

  -- Have we cached the seats?
  if #self.Seats == self:GetSeatCount() then return self.Seats end

  -- We must be missing some seats then

  local seats = {}
  for _, child in ipairs(self:GetChildren()) do
    if not (child:IsVehicle() and child:GetClass():lower() == "prop_vehicle_prisoner_pod") then continue end
    if child:GetNWInt("SWVR.SeatIndex", 0) < 1 then continue end

    seats[child:GetNWInt("SWVR.SeatIndex", 0)] = child
  end

  self.Seats = seats

  return self.Seats or {}
end

--- Weapons Functions
-- @section weapons

function ENT:AddWeapon(name, pos, callback)
  if CLIENT then return end

  local ent = ents.Create("prop_physics")
  ent:SetModel("models/props_junk/PopCan01a.mdl")
  ent:SetPos(self:LocalToWorld(pos) or self:GetPos())
  ent:SetAngles(self:GetAngles())
  ent:SetParent(self)
  ent:Spawn()
  ent:Activate()
  ent:SetRenderMode(RENDERMODE_TRANSALPHA)
  ent:SetColor(Color(255, 255, 255, 0))
  ent:SetSolid(SOLID_NONE)
  ent:AddFlags(FL_DONTTOUCH)

  local phys = ent:GetPhysicsObject()
  phys:EnableCollisions(false)
  phys:EnableMotion(false)

  ent:SetNWString("SWVR.WeaponName", name)


  -- For ease of use and consistency
  function ent:FireMissile(missileInfo)
    local tbl = missileInfo or {}

    local e = ents.Create("lunasflightschool_missile")
    e:SetPos(tbl.Src or self:GetPos())
    e:SetAngles(tbl.Dir:Angle())
    e:Spawn()
    e:Activate()
    e:SetAttacker(tbl.Attacker or self:GetParent())
    e:SetInflictor(tbl.Inflictor or self:GetParent())
    e:SetStartVelocity(self:GetParent():GetVelocity():Length())
    e:SetCleanMissile(true)

    return e
  end

  self:SetWeaponCount(self:GetWeaponCount() + 1)
end

function ENT:GetWeapon(name)
  self.Weapons = self.Weapons or {}

  if not isstring(name) then return NULL end

  -- Have we cached the entity for the server/client?
  local weapon = self.Weapons[name]
  if IsValid(weapon) and weapon:GetNWString("SWVR.WeaponName") == name then
    return weapon
  end

  -- Loop over children instead of Seats table because the table isn't networked but children are
  for _, child in ipairs(self:GetChildren()) do
    if child:GetClass():lower() ~= "prop_physics" then continue end

    if string.upper(child:GetNWString("SWVR.WeaponName", "")) ~= string.upper(name) then continue end

    self.Weapons[name] = child

    return child
  end

  return NULL
end

function ENT:GetWeapons()
  self.Weapons = self.Weapons or {}

  -- Have we cached the weapons?
  if #self.Weapons == self:GetWeaponCount() then return self.Weapons end

  -- We must be missing some weapons then

  local weapons = {}
  for _, child in ipairs(self:GetChildren()) do
    if child:GetClass():lower() ~= "prop_physics" then continue end
    if child:GetNWString("SWVR.WeaponName", "NULL_") == "NULL_" then continue end

    weapons[child:GetNWString("SWVR.WeaponName", "")] = child
  end

  self.Weapons = weapons

  return self.Weapons or {}
end

function ENT:FireWeapon(name, options)
  if CLIENT then return end

  local weapon = self:GetWeapon(name)

  options = options or {}

  local wtype = options.Type or "cannon"

  if string.lower(wtype) == "cannon" then
    local bullet = {}
    bullet.Num = 1
    bullet.Src = weapon:GetPos() or self:LocalToWorld(Vector())
    bullet.Dir = self:LocalToWorldAngles(Angle()):Forward()
    bullet.Spread = options.Spread or Vector(0.01, 0.01, 0)
    bullet.Tracer	= 1
    bullet.TracerName	= options.Tracer or "swvr_tracer_red"
    bullet.Force = 100
    bullet.HullSize = 25
    bullet.Damage	= options.Damage or 40
    bullet.Attacker = options.Attacker or self:GetPilot()
    bullet.AmmoType = "Pistol"
    bullet.Callback = function(att, tr, dmginfo)
      dmginfo:SetDamageType(DMG_AIRBOAT)
    end

    self:FireBullets(bullet)
  end
end

--- Convenience Functions
-- @section helpers

--- Convenience function
-- @shared
-- @return Entity The pilot of the ship
function ENT:GetPilot()
  return self:GetPassenger(1)
end

function ENT:GetPassenger(index)
  local seat = self:GetSeat(index)

  if not IsValid(seat) then return NULL end

  if SERVER then
    return seat:GetDriver()
  else
    return seat:GetNWEntity("Driver", NULL)
  end
end

function ENT:PlaySound(path, callback, options)
  if CLIENT then
    self.LoadedSounds = self.LoadedSounds or {}
  end

  local sound, filter

  if SERVER then
    filter = RecipientFilter()

    for _, ply in ipairs(player.GetAll()) do
      if callback(self, ply) then filter:AddPlayer(ply) end
    end
  end

  if SERVER or not self.LoadedSounds[path] then
    sound = CreateSound(self, path, filter)

    if sound then
      sound:SetSoundLevel(options.Level or 0)

      if CLIENT then
        self.LoadedSounds[path] = sound
      end
    end
  else
    sound = self.LoadedSounds[path]
  end

  if sound then
    if CLIENT then sound:Stop() end

    sound:PlayEx(options.Volume or 1, options.Pitch or 100)
  end

  return sound
end

--- Internal Networking
-- @section networking

local EVENTS = {
  "CanEnter",
  "OnEnter",
  "OnExit",
  "OnEngineStart",
  "OnEngineStop",
  "OnLand",
  "OnTakeoff",
  "OnCollide",
  "PrimaryAttack",
  "SecondaryAttack",
  "AlternateFire",
  "GunnerPrimaryAttack",
  "GunnerSecondaryAttack",
  "GunnerAlternateFire",
  "OnShieldDamage"
}

local EVENTS_TABLE = {}

for i, evt in ipairs(EVENTS) do
  EVENTS_TABLE[i] = string.upper(evt)
end

function ENT:DispatchNetworkEvent(event, ...)
  if CLIENT then return true, false end

  local cancel, result = self:DispatchEvent(event, ...)

  if cancel then return true, false end

  -- Network the event clientside
  net.Start("SWVR.EventDispatcher")

  local index = table.KeyFromValue(EVENTS_TABLE, string.upper(event))

  net.WriteUInt(index, 6)
  net.WriteEntity(self)
  net.WriteTable({...})

  net.Broadcast()

  return false, result
end

function ENT:DispatchEvent(event, ...)
  self.EventDispatcher = self.EventDispatcher or {}
  self.EventDispatcher[string.upper(event)] = self.EventDispatcher[string.upper(event)] or {}

  -- First we run hooks, they are top priority
  local result = hook.Run("SWVR." .. event, self, ...)

  -- If any hook returned false, stop the event from propogating
  if result == false then return true, false end

  -- Now check for our own event server/client side
  if self[event] ~= nil then
    self[event](self, ...)
  end

  -- Run server/client side added callbacks to this event
  for k, v in pairs(self.EventDispatcher[string.upper(event)] or {}) do
    v(self, ...)
  end

  return false, result
end

function ENT:AddEvent(name, callback)
  self.EventDispatcher = self.EventDispatcher or {}
  self.EventDispatcher[string.upper(name)] = self.EventDispatcher[string.upper(name)] or {}

  table.insert(self.EventDispatcher[string.upper(name)], callback or function() return end)
end

function ENT:GetEvents(event)
  self.EventDispatcher = self.EventDispatcher or {}

  if isstring(event) then
    return self.EventDispatcher[string.upper(name)] or {}
  end

  return self.EventDispatcher
end

function ENT:SetCooldown(action, time)
  self.Cooldowns = self.Cooldowns or {}

  if not action then return end

  if SERVER then
    net.Start("SWVR.Cooldown")
      net.WriteEntity(self)
      net.WriteString(util.Compress(action))
      net.WriteFloat(time)
    net.Broadcast()
  end

  self.Cooldowns[action] = time
end

function ENT:GetCooldown(action)
  self.Cooldowns = self.Cooldowns or {}

  return self.Cooldowns[action]
end

-- NETWORKING

if CLIENT then
  net.Receive("SWVR.EventDispatcher", function()

    local index = net.ReadUInt(6)
    local ent = net.ReadEntity()
    local data = net.ReadTable()

    if not (IsValid(ent) and ent.IsSWVRVehicle) then return end

    ent:DispatchEvent(EVENTS[index], unpack(data))
  end)

  net.Receive("SWVR.Cooldown", function()
    local ent = net.ReadEntity()
    local action = util.Decompress(net.ReadString())
    local time = net.ReadFloat()

    if not IsValid(ent) then return end
    if not ent.SetCooldown then return end

    ent:SetCooldown(action, time)
  end)
end

if SERVER then
  util.AddNetworkString("SWVR.EventDispatcher")
  util.AddNetworkString("SWVR.Cooldown")
end
