AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_events.lua")
AddCSLuaFile("cl_init.lua")

include("shared.lua")
include("events.lua")

--- Spawns the entity.
-- This is required for the entity to spawn.
-- @param ply The player spawning the ship.
-- @param tr A trace result from the player's aim vector.
-- @param ClassName The class being spawned.
function ENT:SpawnFunction(ply, tr, ClassName)
  if not tr.Hit then
    return
  end

  local ent = ents.Create(ClassName)
  ent:SetPos(tr.HitPos + tr.HitNormal * 5)
  ent:SetAngles(Angle(0, ply:GetAimVector():Angle().Yaw, 0))
  ent:Spawn()
  ent:Activate()

  return ent
end

--- Initialize the base server-side.
-- Initializes all needed variables server-side.
-- May also call other Initialization functions.
function ENT:Initialize()
  self:InitModel()

  self.Players = self.Players or {}
  self.Avatars = self.Avatars or {}
  self.Events = self.Events or {}

  self.IonShots = 0
  self.HoverStart = 0

  self:InitDrive()

  self.Cooldown = {
    Wings = CurTime(),
    Use = CurTime(),
    Fire = CurTime(),
    Mode = CurTime(),
    Torpedo = CurTime(),
    Dock = CurTime(),
    Lock = CurTime(),
    Correct = CurTime(),
    Hyperdrive = CurTime(),
    Switch = CurTime(),
    View = CurTime()
  }

  self.Velocity = Vector()
  self.Throttle = Vector()

  self.Acceleration = 1
  self.Roll = 0
  self.LastCollide = CurTime()

  self.Phys = {
    secondstoarrive = 1,
    maxangular = 5000,
    maxangulardamp = 10000,
    maxspeed = 1000000,
    maxspeeddamp = 500000,
    dampfactor = 0.8,
    teleportdistance = 5000
  }

  self:CanLock(true)
  self:SetAllegiance(SWVR.Allegiances[self.Category])
  self:SetLandHeight(self.LandHeight or 0)
  self:IsLanding(false)
  self:IsTakingOff(true)
  self:SetMaxHealth(self:GetMaxHealth() or 800)
  self:SetHealth(self:GetMaxHealth())
  self:ShouldAutoCorrect(cvars.Bool("swvr_autocorrect"))

  self:InitPhysics()

  self:SpawnSeats()
end

function ENT:Think()
  if self:InFlight() and IsValid(self:GetPilot()) then
    if (not self:IsTakingOff() and not self:IsLanding() and self.Velocity:IsZero()) then
      if self.HoverStart > 0 then
        if CurTime() - self.HoverStart > 3 then
          local curPos = self:GetPos()
          self:SetPos(Vector(curPos.x, curPos.y, curPos.z + (math.sin(CurTime() * 0.25 * math.pi * 2) * 0.25)))
        end
      else
        self.HoverStart = CurTime()
      end
    else
      self.HoverStart = 0
    end

    if IsValid(self:GetPilot()) and self:GetPilot():ControlUp("swvr_key_exit") then
      self:GetPilot():SetPos(self:GetPos() + (self.PilotOffset or Vector()))
    end
  end

  -- If a control was used this frame, then we should ignore firing inputs
  if not self:ThinkControls() then
    self:ThinkWeapons()
  end

  self:ThinkParts()

  self:NextThink(CurTime())

  return true
end

function ENT:ThinkWeapons()
  if not cvars.Bool("swvr_weapons_enabled") then return end

  for _, button in pairs(SWVR.Buttons) do
    for _, tbl in pairs(self.Players or {}) do
      local ply = tbl.ent
      if not IsValid(ply) then continue end

      local seat = ply:GetNWString("SeatName")
      if not self.Seats[seat]["Weapons"][button] then continue end

      local group = self.WeaponGroups[self.Seats[seat]["Weapons"][button]]

      if (ply:KeyDown(button) and group:GetCooldown() < CurTime()) then
        if (not group:GetOverheated() or not group:GetCanOverheat() and not self:IsCritical()) then
          self:FireWeapons(self.Seats[seat]["Weapons"][button])
          group:SetOverheat(group:GetOverheat() + 1)
          group:SetOverheatCooldown(2)
          self:DispatchEvent("OnFire", group:Serialize(), seat)

          if (group:GetCanOverheat() and group:GetOverheat() >= group:GetMaxOverheat()) then
            self:DispatchEvent("OnOverheat", group:Serialize(), seat)
          end
        elseif (group:GetOverheated()) then
          group:SetOverheat(group:GetOverheat() - group:GetOverheatCooldown() * 2.5 * FrameTime())
          group.OverheatCooldown = math.Approach(group.OverheatCooldown, 4, 1)

          if (group:GetCanOverheat() and group:GetOverheat() <= 0 and group:GetOverheatCooldown() >= 4) then
            self:DispatchEvent("OnOverheatReset", group:Serialize(), seat)
          end
        end
      else
        if (group:GetCooldown() < CurTime() and group:GetOverheat() > 0) then
          group:SetOverheat(group:GetOverheat() - group:GetOverheatCooldown() * 2.5 * FrameTime())
          group:SetOverheatCooldown(math.Approach(group:GetOverheatCooldown(), 4, 1))

          if (group:GetOverheated() and group:GetOverheat() <= 0) then
            self:DispatchEvent("OnOverheatReset", group:Serialize(), seat)
          end
        end
      end

      if (group:GetCanOverheat() and group:GetOverheat() >= group:GetMaxOverheat()) then
        group:SetOverheated(true)
      elseif (group:GetCanOverheat() and group:GetOverheat() <= 0) then
        group:SetOverheated(false)
      end
    end
  end

  self:NetworkWeapons()
end

function ENT:ThinkControls()
  if not IsValid(self:GetPilot()) then return end

  local ply = self:GetPilot()

  self:SetHandbrake(false)
  if ply:ControlDown("swvr_key_modifier") then
    if ply:ControlDown("swvr_key_handbrake") then
      self:Handbrake()

      return true
    end

    if ply:ControlDown("swvr_key_eject") then
      self:Eject()
    end
  end

  if ply:ControlDown("swvr_key_exit") and self.Cooldown.Use < CurTime() then

    self:Exit(false)

    return true
  end

  if ply:ControlDown("swvr_key_view") and self:GetCanFPV() and self.Cooldown.View < CurTime() then
    self:SetFirstPerson(not self:GetFirstPerson())
    self.Cooldown.View = CurTime() + 1

    return true
  end

  if not self:GetHandbrake() then
    if ply:ControlDown("swvr_key_forward") then
      self.Throttle.x = self.Throttle.x + self.Acceleration * 0.7
    elseif ply:ControlDown("swvr_key_backward") then
      self.Throttle.x = self.Throttle.x - self.Acceleration * 0.85
    end
  end

  return false
end

function ENT:ThinkParts()
  for k, v in pairs(self.Parts or {}) do
    if not v.Callback then continue end
    if not IsValid(v.Entity) then continue end

    local seat = self.Seats[v.Seat]
    local passenger = (seat and IsValid(seat.Ent)) and seat.Ent:GetPassenger(1) or NULL

    if not IsValid(passenger) then continue end

    local newPos, newAng = v.Callback(self, v.Entity, passenger)

    if newPos then
      v.Entity:SetPos(newPos)
    end

    if newAng then
      v.Entity:SetAngles(newAng)
    end
  end
end

function ENT:OnRemove()
  if self:InFlight() then
    self:Exit()
  end

  for k, v in pairs(self.Parts or {}) do
    SafeRemoveEntity(v.Entity)
  end
end

--- Setup the ship model.
-- Sets proper model, render, and physics modes.
function ENT:InitModel()
  util.PrecacheModel(self.WorldModel)

  self:SetModel(self.WorldModel)
  self:PhysicsInit(SOLID_VPHYSICS)
  self:SetMoveType(MOVETYPE_VPHYSICS)
  self:SetSolid(SOLID_VPHYSICS)
  self:StartMotionController()
  self:SetUseType(SIMPLE_USE)
  self:SetRenderMode(RENDERMODE_TRANSALPHA)
  --self:Activate()
end

--- Setup the hyperdrive system.
-- Checks if user/server has WireMod installed and uses it.
function ENT:InitDrive()
  if not self.Hyperdrive then
    return
  end

  self.WarpDestination = nil

  if WireLib then
    Wire_CreateInputs(self, {"Destination [VECTOR]"})
  else
    self.DistanceMode = true
  end
end

--- Initialize physics.
-- Sets up the physical properties of the ship.
function ENT:InitPhysics()
  local mb, mb2 = self:GetModelBounds()
  self.Mass = (mb - mb2):Length() * 10
  self.ShipLength = (mb2.x - mb.x) / 2
  local phys = self:GetPhysicsObject()
  self.MaxAcceleration = math.floor((100 - math.ceil((mb - mb2):Length() / 100)) / 10) * 2

  if (phys:IsValid()) then
    phys:Wake()
    phys:SetMass(self.Mass or 10000)
  end
end

--- Setup the necessary flight model for the ship
-- @param health
function ENT:Setup(options)
  self.WorldModel = options.Model
  self.TakeOffVector = options.TakeOffVector
  self.LandAngles = options.LandAngles

  self:SetMaxHealth((options.Health or 1000) * cvars.Number("swvr_health_multiplier"))
  self:SetStartShieldHealth(cvars.Bool("swvr_shields_enabled") and ((options.Shields or 0) * cvars.Number("swvr_shields_multiplier")) or 0)
  self:SetShieldHealth(self:GetStartShieldHealth())
  self:SetBack(tobool(options.Back))
  self:SetMaxSpeed(options.Speed or 1500)
  self:SetMinSpeed(self:GetBack() and (self:GetMaxSpeed() * 0.66) * -1 or 0)
  self:SetVerticalSpeed(options.VerticalSpeed or self:GetMaxSpeed() * 1 / 3)
  self:SetBoostSpeed(options.BoostSpeed or self:GetMaxSpeed())
  self:SetAccelSpeed(options.Acceleration or 7)
  self:SetRoll(tobool(options.Roll))
  self:SetFreeLook(options.Freelook or true)
end

--- Add a new weapon group.
-- Create a weapon group for weapons to parent to.
-- @param name The name of the weapon group.
-- @param bullet The type of bullet the group will use.
function ENT:AddWeaponGroup(name, weapon, options)
  self.WeaponGroups = self.WeaponGroups or {}

  if self.WeaponGroups[name] then
    error("Tried to create weapon group '" .. name .. "' that already exists!")
  end

  options = options or {}
  if isstring(options.Parent) then
    options.Parent = self.Parts[options.Parent].Entity
  end

  options.Parent = options.Parent or self

  if options.Damage then options.Damage = options.Damage * cvars.Number("swvr_weapons_multiplier") end

  local group = SWVR:WeaponGroup(weapon)
  group:SetName(name)
  group:SetOwner(self)

  if not options.Parent then group:SetParent(self) end
  group:SetOptions(options)

  self.WeaponGroups[name] = group

  return group
end

-- Add a new weapon.
-- Creates a new weapon on the ship.
-- @param group The weapon group the new weapon is part of.
-- @param name The name of weapon.
-- @param pos The position of the weapon.
function ENT:AddWeapon(group, name, pos, options)
  self.Weapons = self.Weapons or {}

  if not self.WeaponGroups[group] then
    return error("Tried to add weapon '" .. name .. "' to group '" .. group .. "' which doesn't exist! (Make sure to add the group first)")
  end

  for k, v in pairs(self.Weapons) do
    if v:GetName() == name then
      return error("Tried to add weapon '" .. name .. "' which already exists! (Weapons cannot have duplicate names)")
    end
  end

  local WeaponGroup = self.WeaponGroups[group]

  options = options or {}
  if isstring(options.Parent) then
    options.Parent = self.Parts[options.Parent].Entity
  end

  options.Parent = options.Parent or WeaponGroup:GetParent() or self
  options.Name = name

  local weapon = WeaponGroup:AddWeapon(options)
  weapon:SetPos(self:LocalToWorld(pos))

  self.Weapons[name] = weapon

  return weapon
end

--- Add a new seat.
-- Creates a new seat for passengers/gunners.
-- @param name The name of the seat.
-- @param pos The position of the seat.
-- @param ang The angle for the seat.
-- @param visible[opt=true] If the player should be visible or not.
-- @param exitpos[opt=Vector(0, 0, 0)] The exit modifier for the seat.
-- @param groups[opt="None"] The weapon group associated with the seat.
function ENT:AddSeat(name, pos, ang, options)
  if string.upper(name) == "PILOT" then
    error("Seats cannot have the name 'Pilot'! Use AddPilot instead.")
  elseif self.Seats[name] ~= nil then
    error("Tried to create seat '" .. name .. "' that already exists!")
  end

  options = options or {}
  local buttonMap = {}
  local group = options.Weapons or {}
  self.Seats = self.Seats or {}

  for k, v in pairs(self.Seats) do
    if v.Group == group and v.Group ~= "None" then
      error("Tried to create seat '" .. name .. "' with weapon group '" .. group .. "' that is in use!")
    end
  end

  if table.Count(group) > 3 then
    error("Tried to create seat '" .. name .. "' with more than three weapon groups!")
  else
    for i = 1, 3 do
      if group[i] then
        if not self.WeaponGroups[group[i]] then
          error("Tried to create a seat (" .. name .. ") with weapon group (" .. group[i] .. ") that does not exist!")
        end

        if string.upper(group[i]) ~= "NONE" then
          buttonMap[SWVR.Buttons[i]] = group[i]
          self.WeaponGroups[group[i]].Seat = name
        end
      end
    end
  end

  self.Seats[name] = {
    Name = name,
    Visible = Either(isbool(options.Visible), options.Visible, true),
    Weapons = buttonMap,
    Pos = self:LocalToWorld(pos),
    Ang = ang,
    ExitPos = options.ExitPos
  }
end

--- Add the pilot's seat.
-- Create the seat for which the pilot will operate the vehicle.
-- @param exitpos The position the pilot will exit the vehicle (relative to the origin of the vehicle).
-- @param fpvpos[opt=Vector(0, 0, 0)] The first person view position modifier.
-- @param pilotpos
function ENT:AddPilot(pilotpos, pilotang, options)
  options = options or {}
  local buttonMap = {}
  local group = options.Weapons or {}
  self.Seats = self.Seats or {}
  self:SetFPVPos(options.FPVPos or Vector(0, 0, 0))

  if table.Count(group) > 3 then
    error("Tried to create a seat (Pilot) with more than three weapon groups!")
  else
    for i = 1, 3 do
      if group[i] and not self.WeaponGroups[group[i]] then
        error("Tried to create a seat (Pilot) with weapon group (" .. group[i] .. ") that does not exist!")
      end

      if group[i] and string.upper(group[i]) ~= "NONE" then
        buttonMap[SWVR.Buttons[i]] = group[i]
      end
    end
  end

  self.Seats["Pilot"] = {
    Weapons = buttonMap,
    ExitPos = options.ExitPos or Vector(0, 0, 0),
    FPVPos = options.fpvpos or nil,
    PilotPos = pilotpos or nil,
    PilotAng = pilotang or nil,
    Name = "Pilot"
  }

  self:SetCanFPV(options.FPVPos ~= nil)
end

function ENT:AddPart(name, path, pos, ang, options)
  self.Parts = self.Parts or {}

  util.PrecacheModel(path)

  options = options or {}

  if (options.Callback and not options.Seat) then
    error("You cannot add a part callback without also assigning a seat.")
  end

  local part = {
    Path = path,
    Pos = pos and self:LocalToWorld(pos) or self:LocalToWorld(Vector(0, 0, 0)),
    Ang = ang or nil,
    Parent = isstring(options.Parent) and self.Parts[options.Parent].Entity or self,
    Callback = options.Callback or nil,
    Seat = options.Seat or nil,
    Entity = NULL
  }

  local e = ents.Create("prop_dynamic")
  e:SetPos(part.Pos or self:GetPos())
  e:SetAngles(part.Ang or self:GetAngles())
  e:SetModel(part.Path)
  e:SetParent(isstring(part.Parent) and self.Parts[part.Parent].Entity or self)
  e:Spawn()
  e:SetModelScale(self:GetModelScale())
  e:Activate()
  e:GetPhysicsObject():EnableCollisions(false)
  e:GetPhysicsObject():EnableMotion(false)

  part.Entity = e

  self.Parts[name] = part

  return e
end


function ENT:SpawnSeats()
  self.Seats = self.Seats or {}

  for k, v in pairs(self.Seats) do
    if string.upper(k) == "PILOT" then continue end

    local e = ents.Create(self.SeatClass or "prop_vehicle_prisoner_pod")
    e:SetPos(v.Pos or self:GetPos())
    e:SetAngles(v.Ang or self:GetAngles())
    e:SetParent(self)
    e:SetModel("models/nova/airboat_seat.mdl")
    e:SetRenderMode(RENDERMODE_TRANSALPHA)
    e:SetColor(v.Visible and Color(255, 255, 255, 255) or Color(255, 255, 255, 0))
    e:DrawShadow(false)
    e:Spawn()
    e:SetModelScale(self:GetModelScale())
    e:Activate()
    e:GetPhysicsObject():EnableMotion(false)
    e:GetPhysicsObject():EnableCollisions(false)
    e:SetCollisionGroup(COLLISION_GROUP_WEAPON)

    e.ExitPos = v.ExitPos

    if (self.DisableThirdpersonSeats) then
      e:SetNWBool("NoFirstPerson", true)
    end

    self.Seats[k].Ent = e
  end
end

function ENT:SpawnPilot()
  if IsValid(self:GetPilot()) and self.Seats["Pilot"].PilotPos then
    local e = ents.Create("prop_physics")
    e:SetModel(self:GetPilot():GetModel())
    e:SetPos(self:LocalToWorld(self.Seats["Pilot"].PilotPos))
    local ang = self:GetAngles()

    if self.Seats["Pilot"].PilotAng then
      ang = self:GetAngles() + self.Seats["Pilot"].PilotAng
    end

    e:SetAngles(ang)
    e:SetParent(self)
    e:Spawn()
    e:SetModelScale(self:GetModelScale())
    e:Activate()
    e:SetSequence("drive_jeep")
    self.Avatars["Pilot"] = e
    self:SetAvatar(e)
  end
end

--- Use override.
-- Allow the player to enter the ship.
-- @param p The player using the ship.
function ENT:Use(p)
  if cvars.Bool("swvr_disable_use") then p:ChatPrint("[SWVR] This server has disabled using ships for now.") return end

  if not p:KeyDown(IN_WALK) then
    if not self:InFlight() and self.Cooldown.Use < CurTime() then
      self:Enter(p)
    elseif self.Flying and table.Count(self.Seats) > 1 then
      self:PassengerEnter(p)
    end
  else
    if table.Count(self.Seats) > 1 then
      self:PassengerEnter(p)
    end
  end
end

function ENT:Enter(p)
  if not (self:InFlight() and self.Done) then
    if self:CheckHook(hook.Run("SWVREnter", p)) then
      return
    end

    self:DispatchEvent("OnEnter", p)

    p:SetNWEntity("Ship", self)
    p:SetNWString("SeatName", "Pilot")
    p:SetNWBool("Pilot", true)
    p:SetNWBool("Flying", true)
    p:Spectate(OBS_MODE_CHASE)
    p:DrawWorldModel(false)
    p:DrawViewModel(false)
    p:SetRenderMode(RENDERMODE_TRANSALPHA)
    p:SetColor(Color(255, 255, 255, 0))
    p:SetMoveType(MOVETYPE_NOCLIP)
    p:SetCollisionGroup(COLLISION_GROUP_IN_VEHICLE)

    self:SavePlayer(p)
    self:IsTakingOff(true)
    self:SetFlight(true)

    p:StripWeapons()
    p:SetViewEntity(self)
    p:SetModelScale(self:GetModelScale())

    self:GetPhysicsObject():Wake()
    self:GetPhysicsObject():EnableMotion(true)
    self:StartMotionController()

    self:Rotorwash(true)
    self:SetPilot(p)
    self:SpawnPilot()
    self.Cooldown.Use = CurTime() + 1
    self.StartPos = self:GetPos()
    self.LandPos = self:GetPos() + Vector(0, 0, 10)

    p:SetNWVector("ExitPos", self.Seats["Pilot"].ExitPos)
    p:SetEyeAngles(self:GetAngles())

    for k, v in pairs(self.WeaponGroups) do
      if "Pilot" == v.Seat then
        v:SetPlayer(p)
      end
    end
  end
end

function ENT:PassengerEnter(p)
  if self:GetPilot() == p then return end -- This could cause weirdness...
  if self.Cooldown.Use > CurTime() then return end

  if self:CheckHook(hook.Run("SWVRPassengerEnter", p)) then return end

  self:DispatchEvent("OnPassengerEnter", p)

  for k, v in pairs(self.Seats) do
    if v.Ent:GetPassenger(1) == NULL then
      p:EnterVehicle(v.Ent)
      p:SetNWEntity("Ship", self)
      p:SetNWEntity("Seat", v.Ent)
      p:SetNWString("SeatName", v.Name)
      p:SetNWBool("Flying", true)
      p:SetNWVector("ExitPos", v.ExitPos)
      self:SavePlayer(p)

      for g, t in pairs(self.WeaponGroups) do
        if v.Name == t.Seat then
          t:SetPlayer(p)
        end
      end

      return
    end
  end
end

function ENT:Exit(kill)
  if self:CheckHook(hook.Run("SWVRExit", kill)) then
    return
  end

  self:SetFlight(false)
  self:IsTakingOff(false)
  local p = self:GetPilot()

  if IsValid(p) then
    p:UnSpectate()
    p:DrawViewModel(true)
    p:DrawWorldModel(true)
    p:Spawn()

    p:SetCollisionGroup(COLLISION_GROUP_PLAYER)
    p:SetViewEntity(NULL)

    p:SetRenderMode(RENDERMODE_NORMAL)
    p:SetColor(Color(255, 255, 255, 255))
    p:SetVelocity(self:GetVelocity())
    p:SetModelScale(1)

    self:LoadPlayer(p, kill)
  end

  self:Rotorwash(false)
  self:SetFlight(false)
  self:SetPilot(nil)
  self:IsLanding(true)
  self:SetFirstPerson(false)

  if IsValid(self:GetAvatar()) then
    self:GetAvatar():Remove()
    self:SetAvatar(nil)
  end

  self.Cooldown.Use = CurTime() + 1

  return p
end

function ENT:PassengerExit(p, kill)
  return self:LoadPlayer(p, kill)
end

--- Save a player's state.
-- This saves a player's weapons, health, and armor before entering.
-- @param p The player to save.
function ENT:SavePlayer(p)
  self.Players = self.Players or {}

  self.Players[p:EntIndex()] = {
    health = p:Health(),
    armor = p:Armor(),
    activeWeapon = p:GetActiveWeapon():GetClass(),
    weaponTable = {},
    ammoTable = {},
    ent = p
  }

  for k, v in pairs(p:GetWeapons()) do
    table.insert(self.Players[p:EntIndex()].weaponTable, v:GetClass())
    self.Players[p:EntIndex()].ammoTable[k] = {v:GetPrimaryAmmoType(), p:GetAmmoCount(v:GetPrimaryAmmoType())}
  end

  p:SetCanZoom(false)

  if (p:FlashlightIsOn()) then
    p:Flashlight(false)
  end

  p:AllowFlashlight(false)
end

--- Load a player's state.
-- This loads a player's weapons, health, and armor.
-- @param p The player to load.
function ENT:LoadPlayer(p, kill)
  for k, v in pairs(self.WeaponGroups) do
    if v.Seat == p:GetNWString("SeatName") then
      v:SetPlayer(NULL)
    end
  end

  local data = self.Players[p:EntIndex()]
  if istable(data) then
    p:SetHealth(data.health)
    p:SetArmor(data.armor)

    for k, v in pairs(data.weaponTable) do
      if not p:HasWeapon(tostring(v)) then
        p:Give(tostring(v))
      end
    end

    if data.activeWeapon ~= "" then
      p:SelectWeapon(data.activeWeapon)
    end

    p:StripAmmo()

    for k, v in pairs(data.ammoTable) do
      p:SetAmmo(v[2], v[1])
    end

    p:SetCanZoom(true)
    p:AllowFlashlight(true)
    table.Empty(self.Players[p:EntIndex()])
    table.remove(self.Players, p:EntIndex())
  end

  p:SetNWEntity("Ship", NULL)
  p:SetNWEntity("Seat", NULL)
  p:SetNWString("SeatName", nil)
  p:SetNWBool("Flying", false)
  p:SetNWBool("Pilot", false)

  p:SetPos(self:LocalToWorld(p:GetNWVector("ExitPos")))

  if kill and p:Alive() and not p:HasGodMode() then
    p:Kill()
  end

  p:SetNWVector("ExitPos", nil)

  return p
end

function ENT:GetPlayers()
  local players = {}
  for k, v in pairs(self.Players) do
    if IsValid(v.ent) then
      table.insert(players, v.ent)
    end
  end

  return players
end

--- Fire a specific weapon group.
-- @param g The weapon group to fire
function ENT:FireWeapons(g)
  local group = self.WeaponGroups[g]
  group:Fire()
end

function ENT:FindTarget()
  local c1, c2 = self:GetModelBounds()
  c1, c2 = self:LocalToWorld(c1), self:LocalToWorld(c2) + self:GetForward() * 10000

  for _, ent in pairs(ents.FindInBox(c1, c2)) do
    if (IsValid(ent) and ent:IsStarWarsVehicle() and ent ~= self and not IsValid(ent:GetParent()) and ent:GetAllegiance() ~= self:GetAllegiance()) then
      return ent
    end
  end

  return NULL
end

--- Destroy the vehicle.
-- Kills all occupants inside.
-- @usage Can override with the SWVRBang hook
function ENT:Bang()
  if self.Done then
    return
  end

  if self:CheckHook(hook.Run("SWVRBang", self)) then
    return
  end

  self:DispatchEvent("Bang", self)

  self:EmitSound(Sound("Explosion.mp3"), 100, math.random(80, 100))

  local fx = EffectData()
  fx:SetOrigin(self:GetPos())
  fx:SetMagnitude(math.Round(self.Mass, 10000))

  util.Effect("SWExplosion", fx)

  if (self:InFlight()) then
    self:Exit(true)
  end

  if (self.Seats and table.Count(self.Seats) > 1) then
    for k, v in pairs(self.Seats) do
      if v.Name == "Pilot" then continue end
      local p = v.Ent:GetPassenger(1)

      self:PassengerExit(p, true)
    end
  end

  self.Done = true
  self:SetColor(Color(0, 0, 0, 50))
  self:Ignite(10, 50)

  for k, v in pairs(self.Parts or {}) do
    v.Entity:SetColor(Color(0, 0, 0, 50))
    v.Entity:Ignite(10, 50)
  end

  timer.Simple(10, function()
    SafeRemoveEntity(self)
  end)
end

function ENT:Eject()
  local pilot = self:GetPilot()
  self:Exit(false)

  if IsValid(pilot) then
    print("WEEEEE")
    pilot:SetVelocity(self:GetUp() * 1500)
  end
end

function ENT:Heal()
  local inc = self:GetMaxHealth() * 0.0005

  if self:Health() >= self:GetMaxHealth() then return end

  if self:GetMaxHealth() - self:Health() < inc then
    self:SetHealth(self:GetMaxHealth())
  else
    self:SetHealth(self:Health() + inc)
  end

end

--- Generate a transponder code.
-- Generates the vehicle's unique transponder code.
-- @usage Can override the code with your own using the SWVRGenerateTransponder hook
function ENT:GenerateTransponder()
  local steamid = self:GetCreator():SteamID()

  if (steamid == "STEAM_ID_PENDING") then
    steamid = "STEAM_0:0:00000"
  end

  local transponder = hook.Run("SWVRGenerateTransponder", steamid)
  local code = string.upper(string.sub(string.gsub(string.gsub(self.PrintName, " ", ""), "-", ""), 0, 3))
  steamid = string.sub(string.Split(steamid, ":")[3], 1, 4)

  if transponder and isstring(transponder) then
    code = transponder
  end

  return code .. " " .. steamid .. SWVR:CountPlayerOwnedSENTs(self:GetClass(), self:GetCreator())
end

function ENT:Handbrake()
  self.Throttle:Zero()

  self.Velocity.x = math.Approach(self.Velocity.x, 0, self:GetAccelSpeed() * 4)
  self:SetHandbrake(true)
end

function ENT:ResetThrottle()
  self.Throttle:Zero()
  self.Velocity:Zero()
  self.Acceleration = 1
end

--- Simulate the vehicle physics.
-- This controls the flight physics of the ship, don't recommend touching
-- @param phys The physics object of the entity.
-- @param deltatime Time since the last call.
function ENT:PhysicsSimulate(phys, deltatime)
  local FWD = self.ForwardDir or self:GetForward()
  local UP = self:GetUp()
  local RIGHT = FWD:Cross(UP):GetNormalized()

  if not (self:IsTakingOff() or self:IsLanding()) and self:InFlight() then
    local acceleration = math.Clamp(20 - self.Mass / 1000, 4, self.MaxAcceleration)

    if (self:GetAccelSpeed() <= 10 and self:GetAccelSpeed() > acceleration) then
      acceleration = self:GetAccelSpeed()
    end

    self.Acceleration = math.Approach(self.Acceleration, acceleration, acceleration)
  end

  if (self.Done or self.Tractored or (self.DeactivateInWater and self:WaterLevel() >= 3)) then
    return
  end

  if (self:InFlight() and IsValid(self:GetPilot())) then
    local ply = self:GetPilot()
    local pos = self:GetPos()

    if not (self:IsTakingOff() or self:IsLanding()) then
        local min, max

        if (self:GetBack()) then
          min = (self:GetMaxSpeed() * 0.66) * -1
        else
          min = 0
        end

        if (self:HasWings() and self:GetWingState()) then
          max = self:GetBoostSpeed()
        else
          max = self:GetMaxSpeed()
        end

        if (not self:GetHandbrake()) then
          self.Throttle.x = math.Clamp(self.Throttle.x, min, max)
          self.Velocity.x = math.Approach(self.Velocity.x, self.Throttle.x, self.Acceleration)
        end

        if (self:GetRoll()) then
          if ply:ControlDown("swvr_key_right") then
            self.Roll = self.Roll + 3
            self.Throttle.y = self:GetVerticalSpeed() / 1.5
          elseif ply:ControlDown("swvr_key_left") then
            self.Roll = self.Roll - 3
            self.Throttle.y = (self:GetVerticalSpeed() / 1.5) * -1
          elseif ply:ControlDown("swvr_key_handbrake") then
            self.Roll = 0
          else
            self.Throttle.y = 0
          end
        else
          if ply:ControlDown("swvr_key_right") then
            self.Throttle.y = self:GetVerticalSpeed() / 1.2
            self.Roll = 20
          elseif ply:ControlDown("swvr_key_left") then
            self.Throttle.y = (self:GetVerticalSpeed() / 1.2) * -1
            self.Roll = -20
          else
            self.Throttle.y = 0
            self.Roll = 0
          end

          self.Velocity.y = math.Approach(self.Velocity.y, self.Throttle.y, self.Acceleration)
        end

        if ply:ControlDown("swvr_key_up") and ply:ControlUp("swvr_key_handbrake") then
          self.Throttle.z = self:GetVerticalSpeed()
        elseif ply:ControlDown("swvr_key_down") and ply:ControlUp("swvr_key_handbrake") then
          self.Throttle.z = -self:GetVerticalSpeed()
        else
          self.Throttle.z = 0
        end

        self.Velocity.z = math.Approach(self.Velocity.z, self.Throttle.z, self.Acceleration * 0.9)

      local velocity = self:GetVelocity()
      local aim = ply:GetAimVector()
      local ang = aim:Angle()
      local weight_roll = (phys:GetMass() / 100) / 1.5
      local ExtraRoll = math.Clamp(math.deg(math.asin(self:WorldToLocal(pos + aim).y)), -25 - weight_roll, 25 + weight_roll)
      local mul = math.Clamp(velocity:Length() / 1700, 0, 1)
      local oldRoll = ang.Roll
      ang.Roll = (ang.Roll + self.Roll - ExtraRoll * mul) % 360

      if (ang.Roll ~= ang.Roll) then
        ang.Roll = oldRoll
      end

      if (ply:ControlDown("swvr_key_up") and ply:ControlDown("swvr_key_down") and not self.PreventLand) then
        local tr = util.TraceLine({
          start = self.LandTracePos or self:GetPos(),
          endpos = self:GetPos() + self:GetUp() * -(self.LandDistance or 300),
          filter = self:GetChildEntities()
        })

        if (tr.HitWorld or (IsValid(tr.Entity) and SWVR.LandingSurfaces[tr.Entity:GetClass()])) then
          self.Land = true
          self.LandPos = tr.HitPos + (self.LandOffset or Vector(0, 0, 0))
          self:IsLanding(self.Land)
          self:ResetThrottle()
        end
      end

      if (self:CanFreeLook()) then
        if ply:ControlUp("swvr_key_freelook") then
          self.Phys.angle = ang
        end
      else
        self.Phys.angle = ang
      end

      self.Phys.deltatime = deltatime
      local newZ

      if (self:ShouldAutoCorrect()) then
        local heightTrace = util.TraceLine({
          start = self:GetPos(),
          endpos = self:GetPos() + Vector(0, 0, -100),
          filter = self:GetChildEntities()
        })

        if (heightTrace.Hit) then
          local nextPos = self:GetPos() + (FWD * self.Velocity.x) + (UP * self.Velocity.z) + (RIGHT * self.Velocity.y)

          if (nextPos.z <= heightTrace.HitPos.z + 100) then
            newZ = heightTrace.HitPos.z + 100
            self.Velocity.x = math.Clamp(self.Velocity.x, 0, 1000)
          end
        end

        local forwardTrace = util.TraceLine({
          start = self:GetPos(),
          endpos = self:GetPos() + self:GetForward() * (self.ShipLength + 100),
          filter = self:GetChildEntities()
        })

        if (forwardTrace.Hit) then
          self.Velocity.x = 0
        end
      end

      local fPos = pos + (FWD * self.Velocity.x) + (UP * self.Velocity.z)

      if (not self:GetRoll()) then
        fPos = fPos + (RIGHT * self.Velocity.y)
      end

      if (newZ) then
        self.Phys.pos = Vector(fPos.x, fPos.y, newZ)
      else
        self.Phys.pos = fPos
      end

      if (not self:IsCritical() and not self.BeingWarped) then
        phys:ComputeShadowControl(self.Phys)
      end
    elseif (self:IsTakingOff()) then
      if (ply:ControlDown("swvr_key_up")) then
        self.NewPos = self.StartPos + (self.TakeOffVector or Vector(0, 0, 100))
        self.TakingOff = true
      end

      if (self.TakingOff) then
        self.Phys.pos = self.NewPos
      else
        self.Phys.pos = self.LandPos
      end

      self.Phys.angle = self:GetAngles()
      self.Phys.deltatime = deltatime
      phys:ComputeShadowControl(self.Phys)
      local takeOff = 90

      if (self.TakeOffVector) then
        takeOff = self.TakeOffVector.z * 0.9
      end

      if (pos.z >= self.StartPos.z + takeOff) then
        self.TakeOff = false
        self:IsTakingOff(self.TakeOff)
        self.TakingOff = false
        self.NewPos = nil
      end

      self.Velocity.x = 0
    elseif (self:IsLanding()) then
      if (self:HasWings()) then
        self:ToggleWings()
      end

      self.Phys.angle = Angle(0, self:GetAngles().y, 0) + (self.LandAngles or Angle(0, 0, 0))
      self.Phys.deltatime = deltatime
      self.Phys.pos = self.LandPos
      phys:ComputeShadowControl(self.Phys)

      if (pos.z <= self.LandPos.z + 5) then
        self.Land = false
        self:IsLanding(self.Land)
        self.StartPos = self.LandPos
        self.TakeOff = true
        self:IsTakingOff(self.TakeOff)
      end

      self.Velocity.x = 0
    end

    phys:Wake()
    self:SetSpeed(self.Velocity.x)
  else
    if (self.ShouldStandby and (self.TakeOff or self.Docked) and self.CanStandby) then
      self.Phys.angle = self.StandbyAngles or Angle(0, self:GetAngles().y, 0)
      self.Phys.deltatime = deltatime
      self.Phys.pos = self:GetPos() + UP
      phys:ComputeShadowControl(self.Phys)
    end
  end
end

--- Calculate damage from physics collisions.
function ENT:PhysicsCollide(colData, collider)
  if not cvars.Bool("swvr_collisions_enabled") then return end

  if (self.LastCollide < CurTime() and not self:IsLanding() and not self:IsTakingOff()) then
    local mass = (colData.HitEntity:GetClass() == "worldspawn") and 1000 or colData.HitObject:GetMass() --if it's worldspawn use 1000 (worldspawns physobj only has mass 1), else normal mass
    local s = colData.TheirOldVelocity:Length()

    if (s < 0) then
      s = s * -1
    elseif (s == 0) then
      s = 1
    end

    local dmg = (colData.OurOldVelocity:Length() * s * math.Clamp(mass, 0, 1000)) / 3500
    self.Velocity.x = math.Clamp(self.Velocity.x - dmg, 0, self.Velocity.x)
    self.Throttle.x = math.Clamp(self.Throttle.x - dmg, 0, self.Throttle.x)

    if (self:GetShieldHealth() > 0) then
      dmg = dmg * 0.25
    end

    local d = DamageInfo()
    d:SetDamage(dmg * cvars.Number("swvr_collisions_multiplier"))
    d:SetDamageType(DMG_CRUSH)
    d:SetInflictor(game.GetWorld())

    self:TakeDamageInfo(d)
    self.LastCollide = CurTime() + 1
  end
end

function ENT:OnTakeDamage(dmg)
  local inf = dmg:GetInflictor()
  if (not IsValid(inf) and not (isentity(inf) and inf:IsWorld())) or (inf:GetParent() == self) then
    return
  end

  local realDamage = dmg:GetDamage()

  if (realDamage <= 0) then
    return
  end

  if (self:GetShieldHealth() > 0) then
    self:ShieldEffect()
    self:SetShieldHealth(math.max(0, self:GetShieldHealth() - realDamage))
    self:DispatchEvent("OnShieldsHit")

    if (self:GetShieldHealth() <= 0) then
      self:DispatchEvent("OnShieldsDown")
    end
  else
    self:SetHealth(math.max(0, self:Health() - realDamage))

    if (dmg:GetDamageType() == DMG_CRUSH) then
      self:DispatchEvent("OnCollision", realDamage)
    end
  end

  if (self:Health() <= self:GetMaxHealth() * 0.1) then
    self:IsCritical(true)
    self:DispatchEvent("OnCritical")
  end

  if (self:Health() <= 0) then
    self:Bang()
  end
end

function ENT:Rotorwash(b)
  if (b) then
    local e = ents.Create("env_rotorwash_emitter")
    e:SetPos(self:GetPos())
    e:SetParent(self)
    e:Spawn()
    e:Activate()
    self.RotorWash = e
  else
    SafeRemoveEntity(self.RotorWash)
  end
end

function ENT:ShieldEffect()
  if not IsValid(self) then
    return
  end

  local fx = EffectData()
  fx:SetEntity(self)
  fx:SetOrigin(self:GetPos())
  fx:SetScale(self:GetModelScale())
  util.Effect("swvr_shield", fx)

  for k, v in pairs(self.Parts or {}) do
    local partFX = EffectData()
    partFX:SetEntity(v.Entity)
    partFX:SetOrigin(v.Entity:GetPos())
    partFX:SetScale(self:GetModelScale())
    util.Effect("swvr_shield", partFX)
  end

  self:EmitSound("swvr/shields/swvr_shield_absorb_" .. tostring(math.Round(math.random(1, 4))) .. ".wav", 500, 100, 1, CHAN_BODY)
end

function ENT:NetworkWeapons()
  local weaponGroups = ""

  for name, group in pairs(self.WeaponGroups) do
    weaponGroups = weaponGroups .. "|" .. name
    local n = "Weapon" .. name
    self:SetNWBool(n .. "CanOverheat", group:GetCanOverheat())
    self:SetNWBool(n .. "IsOverheated", group:GetOverheated())
    self:SetNWBool(n .. "Track", group:GetIsTracking())
    self:SetNWInt(n .. "Overheat", group:GetOverheat())
    self:SetNWInt(n .. "OverheatMax", group:GetMaxOverheat())
    self:SetNWInt(n .. "OverheatCooldown", group:GetOverheatCooldown())
  end

  self:SetNWString("WeaponGroups", string.sub(weaponGroups, 2))
end

function ENT:TestLoc(pos)
  local e = ents.Create("prop_physics")
  e:SetPos(self:LocalToWorld(pos))
  e:SetModel("models/props_junk/PopCan01a.mdl")
  e:Spawn()
  e:Activate()
  e:SetParent(self)
end

-- function ENT:NetworkWeapons()
--   for name, group in pairs(self.WeaponGroups) do
--     net.Start("SWVR.NetworkWeapons")
--       net.WriteEntity(self)
--       net.WriteTable(group:Serialize())
--     net.Send(self:GetPlayers())
--   end
-- end

function ENT:AddEvent(name, callback, default)
  self.Events = self.Events or {}
  self.Events[string.upper(name)] = self.Events[string.upper(name)] or {}

  table.insert(self.Events[string.upper(name)], {
    Callback = callback or function()
      return
    end,
    Default = Either(isbool(default) and not default, false, true)
  })
end

function ENT:DispatchEvent(event, ...)
  net.Start("SWVREvent")
    net.WriteString(event)
    net.WriteEntity(self)

  for _, v in ipairs({...}) do
    local t = type(v):gsub("^%l", string.upper)
    t = isnumber(v) and "Float" or isentity(v) and "Entity" or isbool(v) and "Bool" or t -- Due to the nature of Lua 5.1, only floats are supported
    net["Write" .. t](v) -- This is some ghetto hack...
  end

  net.Broadcast()

  local default = true
  for k, v in pairs(self.Events[string.upper(event)] or {}) do
    v.Callback(...)
    default = Either(not v.Default, false, default)
  end

  if self["_" .. event] ~= nil then
    self["_" .. event](self, default, ...)
  end

  hook.Run("SWVR." .. event, self, default, ...)
end

hook.Add("PlayerSpawnedSENT", "SWVRServerSpawnedSENT", function(p, e)
  if e.IsSWVRVehicle then
    e:SetCreator(p)
    e:SetTransponder(e:GenerateTransponder())
  end
end)

hook.Add("PlayerLeaveVehicle", "SWVRPlayerLeaveVehicle", function(p, v)
  if IsValid(p) and IsValid(v) and v:GetParent().IsSWVRVehicle then
    v:SetThirdPersonMode(false)
    v:GetParent():PassengerExit(p, false)
  end
end)

hook.Add("Initialize", "SWVRInitialize", function()
  util.AddNetworkString("SWVREvent")
  util.AddNetworkString("SWVR.NetworkWeapons")
end)
