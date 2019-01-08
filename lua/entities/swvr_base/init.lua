--- Star Wars Vehicles Flight Base
-- @module Vehicle
-- @alias ENT
-- @author Doctor Jew

AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")

include("shared.lua")

--- Called when a player spawns the vehicle, do not override.
-- @internal
-- @player ply The player that spawned the vehicle
-- @tparam table tr Trace result structure
-- @string ClassName The entity class of the vehicle
function ENT:SpawnFunction(ply, tr, ClassName)
  if not tr.Hit then return end

  local ent = ents.Create(ClassName)
  ent:SetPos(tr.HitPos + tr.HitNormal * (scripted_ents.GetMember(ClassName, "SpawnHeight") or 15))
  ent:SetAngles(scripted_ents.GetMember(ClassName, "LandAngles") or Angle(0, ply:GetAimVector().Yaw - 180, 0))
  ent:SetCreator(ply)
  ent:SetVar("Player", ply)
  ent:Spawn()
  ent:Activate()

  cleanup.Add(ply, "sents", ent)
  cleanup.Add(ply, "swvehicles", ent)

  undo.Create("SENT")
    undo.AddEntity(ent)
    undo.SetPlayer(ply)
    undo.SetCustomUndoText("Undone " .. ent.PrintName)
  undo.Finish("Scripted Entity (" .. tostring( ClassName ) .. ")")

  hook.Run("PlayerSpawnedSENT", ply, ent)
end

--- Called by the engine to initialize the entity.
-- @internal
function ENT:Initialize()
  self:SetModel(self.Model)

  self:PhysicsInit(SOLID_VPHYSICS)
  self:SetMoveType(MOVETYPE_VPHYSICS)
  self:SetSolid(SOLID_VPHYSICS)
  self:SetUseType(SIMPLE_USE)
  self:SetRenderMode(RENDERMODE_TRANSALPHA)

  local phys = self:GetPhysicsObject()

  if not IsValid(phys) then
    return SafeRemoveEntity(self)
  end

  phys:EnableMotion(false)
  phys:SetMass(self.Mass)
  phys:SetDragCoefficient(-1)

  self.DefaultInertia = phys:GetInertia()

  self.StartPos = self:GetPos()
  self.LandPos = self:GetPos() + Vector(0, 0, 10)
  self.LandAng = self:GetAngles()

  phys:SetInertia(self.Inertia)
  phys:EnableMotion(true)

  self:PhysWake()
  self:StartMotionController()

  self.ShadowParams = {
    secondstoarrive = 1,
    maxangular = 5000,
    maxangulardamp = 10000,
    maxspeed = 1000000,
    maxspeeddamp = 500000,
    dampfactor = 0.8,
    teleportdistance = 5000
  }

  -- Generate control surface helpers
  for control in pairs(self.Controls) do
    self["Get" .. control .. "Velocity"] = function()
      local pos = self:LocalToWorld(self.Controls[control])
      local vel = self:GetPhysicsObject():GetVelocityAtPoint(pos)
      local up = control == "Rudder" and self:GetRight() or self:GetUp()

      return math.Clamp(up:Dot(vel:GetNormalized()), -1, 1) * vel:Length()
    end
  end

  -- Support manually specifying seats
  if table.Count(self.Seats or {}) > 0 then
    for k, v in pairs(self.Seats) do
      if not istable(v) or k == "BaseClass" then continue end

      self:AddSeat(k, v.Pos, v.Ang, v.Options or {})
    end

    self.Seats = {}
  end

  if table.Count(self.Weapons or {}) > 0 then
    for k, v in pairs(self.Weapons) do
      if not istable(v) or k == "BaseClass" then continue end

      self:AddWeapon(k, v.Pos, v.Callback)
    end

    self.Weapons = {}
  end

  self:SetTransponder(swvr.util.GenerateTransponder(self))

  self:SetCooldown("Engine", CurTime())

  self.ColdStart = cvars.Bool("swvr_coldstart_enabled")

  self:OnInitialize()

  self.Initialized = true
end

function ENT:OnInitialize()
  -- Run your custom initialize code here
end

function ENT:Think()

  self:IsActive(IsValid(self:GetPilot()))

  self.InertiaFix = self.InertiaFix or 0

  if self.InertiaFix < CurTime() then
    local target = self:IsActive() or self:GetStability() > 0.1 or not self:HitGround()
    local inertia = target and self.Inertia or self.DefaultInertia

    self.IntertiaFix = CurTime() + 1

    local phys = self:GetPhysicsObject()

    if IsValid(phys) and phys:IsMotionEnabled() then
      phys:SetMass(self.Mass)
      phys:SetInertia(inertia)
    end
  end

  self:ThinkControls()

  self:OnThink()

  self:NextThink(CurTime())

  return true
end

--- Custom think function
-- Override this to run custom logic.
function ENT:OnThink()

end

local WEAPON_MAP = {
  Primary = "PrimaryAttack",
  Secondary = "SecondaryAttack",
  Alternate = "AlternateFire"
}

local MODIFIER_FUNCTION_MAP = {
  DOWN = "Land",
  UP = "Takeoff"
}

local FUNCTION_MAP = {
  ENGINE = "ToggleEngine"
}

function ENT:ThinkControls()
  for index, seat in ipairs(self:GetSeats()) do
    local ply = seat:GetDriver()

    if not IsValid(ply) then continue end

    if index == 1 then -- If we're the pilot
      if ply:ControlDown("modifier") then
        for key, action in pairs(MODIFIER_FUNCTION_MAP) do
          if ply:ControlDown(key) then self:DispatchEvent(action) end
        end

        continue -- Return early because we don't want to register a modifier action AND regular for same key
      end

      for key, action in pairs(FUNCTION_MAP) do
        if ply:ControlDown(key) then
          self:DispatchEvent(action)
        end
      end
    end

    if not cvars.Bool("swvr_weapons_enabled") then return end

    for key, action in pairs(WEAPON_MAP) do
      if index == 1 and self["GetNext" .. key .. "Fire"](self) > CurTime() then continue end
      if ply:ControlDown(key) then self:DispatchNWEvent((index ~= 1 and "Gunner" or "") .. action, { Index = index, Player = ply, Seat = seat }) end
    end
  end
end

--- Primary attack function.
-- @shared
function ENT:PrimaryAttack()
  if self:GetNextPrimaryFire() > CurTime() then return end

  self:SetNextPrimaryFire(CurTime() + 1)
end

--- Secondary attack function
-- @shared
function ENT:SecondaryAttack()
  if self:GetNextSecondaryFire() > CurTime() then return end

  self:SetNextSecondaryFire(CurTime() + 1)
end

function ENT:GunnerPrimaryAttack(data)
  if self:GetNextPrimaryFire() > CurTime() then return end

  self:SetNextPrimaryFire(CurTime() + 1)
end

function ENT:HitGround()
  local tr = util.TraceLine({
    start = self:LocalToWorld(self:OBBCenter()),
    endpos = self:LocalToWorld(self:OBBCenter() + Vector(0, 0, self:OBBMins().z - 100)),
    filter = { self }
  })

  return tr.Hit
end

function ENT:UpdateTransmitState()
  return TRANSMIT_ALWAYS
end

function ENT:Use(ply)
  if not IsValid(ply) then return end

  self:Enter(ply)
end

--- Makes a `Player` enter the vehicle
-- @server
-- @player ply The `Player` to enter the vehicle
-- @see Exit
function ENT:Enter(ply)
  if not IsValid(ply) then return end

  -- Check if the user can enter
  if self:DispatchEvent("CanEnter", ply) then return end

  local pilot = self:GetSeat(1)

  if IsValid(pilot) and not IsValid(pilot:GetDriver()) and not ply:KeyDown(IN_WALK) then
    ply:SetNW2Int("SWVR.SeatIndex", 1)
    ply:EnterVehicle(pilot)
  else
    local vehicle = NULL
    local dist = math.huge

    -- Find the closest seat to the user
    for i, seat in ipairs(self:GetSeats(false)) do
      if i == 1 then continue end
      if not IsValid(seat) or IsValid(seat:GetDriver()) then continue end

      local prox = (seat:GetPos() - ply:GetPos()):Length()

      if prox < dist then
        vehicle = seat
        dist = prox
      end
    end

    if IsValid(vehicle) then
      ply:EnterVehicle(vehicle)
      ply:SetNW2Int("SWVR.SeatIndex", vehicle:GetNW2Int("SeatIndex"))
    elseif IsValid(pilot) and not IsValid(pilot:GetDriver()) then
      ply:EnterVehicle(pilot)
      ply:SetNW2Int("SWVR.SeatIndex", 1) -- In case they held IN_WALK
    end
  end

  local seat = self:GetSeat(ply:GetNW2Int("SWVR.SeatIndex"))

  if IsValid(seat) then
    ply:SetNoDraw(true)
    seat:SetNW2Entity("Driver", ply)
  end

  self:DispatchNWEvent("OnEnter", ply, ply:GetNW2Int("SWVR.SeatIndex") == 1)
end

--- Called when a `Player` exits the vehicle
-- @server
-- @player ply The `Player` that exited
-- @see Enter
function ENT:Exit(ply)
  if not IsValid(ply) then return end

  ply:SetNoDraw(false)

  self:DispatchNWEvent("OnExit", ply, ply:GetNW2Int("SWVR.SeatIndex") == 1)

  ply:SetNW2Int("SWVR.SeatIndex", 0)
end

--- Engine Interaction
-- @section engine

function ENT:ToggleEngine()
  if self:GetCooldown("Engine") > CurTime() then return end

  if self:EngineActive() or self.Starting then
    self:StopEngine()
  else
    self:StartEngine()
  end

  self:SetCooldown("Engine", CurTime() + 1)
end

function ENT:StartEngine()
  if self:EngineActive() or self:IsDestroyed() or self:WaterLevel() > 2 then return end

  if cvars.Bool("swvr_coldstart_enabled") and self.ColdStart then
    self.Starting = true

    self:DispatchNWEvent("OnEngineStartup")
    self:EmitSound("ENGINE_START_COLD")

    timer.Create("ColdStart" .. self:EntIndex(), cvars.Number("swvr_coldstart_time", 6), 1, function()
      if not IsValid(self) then return end

      self.ColdStart = false
      self:StartEngine()
    end)
  else
    self:EngineActive(true)

    self.NextInertia = 0

    if not IsValid(self.RotorWash) then
      local fx = ents.Create("env_rotorwash_emitter")
      fx:SetPos(self:GetPos())
      fx:SetAngles(Angle())
      fx:Spawn()
      fx:Activate()
      fx:SetParent(self)
      fx.DoNotDuplicate = true

      self:DeleteOnRemove(fx)

      -- CPPI support
      if fx.CPPISetOwner and self.CPPIGetOwner then
        fx:CPPISetOwner(self:CPPIGetOwner())
      end

      self.RotorWash = fx
    end

    self:DispatchNWEvent("OnEngineStart")
  end
end

function ENT:StopEngine()
  if not (self:EngineActive() or self.Starting) then return end

  if self.ColdStart then
    self:DispatchNWEvent("OnEngineShutdown")
    timer.Remove("ColdStart" .. self:EntIndex())
    self:StopSound("ENGINE_START_COLD")
    self:EmitSound("ENGINE_SHUTDOWN2")
  end

  self.Starting = false
  self:EngineActive(false)

  if IsValid(self.RotorWash) then self.RotorWash:Remove() end

  self:DispatchNWEvent("OnEngineStop")
end

--- Land the vehicle if possible
-- @treturn bool If the vehicle was landed or not
-- @see Takeoff
function ENT:Land()
  if self:GetCooldown("Land") > CurTime() then return false end

  local tr = util.TraceLine({
    start = self.LandTracePos or self:GetPos(),
    endpos = self:GetPos() + self:GetUp() * -(self.LandDistance or 300),
    filter = table.Add({ self }, self:GetChildren())
  })

  if not (tr.HitWorld or (IsValid(tr.Entity) and swvr.enum.LandingSurfaces[tr.Entity:GetClass()])) then return false end

  if self:EngineActive() then
    self:ToggleEngine()
  end

  self.LandPos = tr.HitPos + (self.LandOffset or Vector(0, 0, 0))

  self:SetVehicleState(swvr.enum.State.Landing)
  self:IsLanding(true)

  self:DispatchNWEvent("OnLand")

  self:SetCooldown("Land", CurTime() + 1)

  -- TODO: Reset throttle and velocity on landing
  -- TODO: Consider an option where vehicles can only land when under a certain speed

  return true
end

--- Takeoff the vehicle if landed
-- @treturn bool If the vehicle did takeoff or not
function ENT:Takeoff()
  if self:GetCooldown("Land") > CurTime() then return false end
  if self:GetVehicleState() ~= swvr.enum.State.Idle then return false end

  if not self:EngineActive() then
    self:ToggleEngine()
  end

  self:SetVehicleState(swvr.enum.State.Takeoff)
  self:IsTakingOff(true)

  self:DispatchNWEvent("OnTakeoff")

  self:SetCooldown("Land", CurTime() + 1)

  return true
end

--- Simulate the physics on the vehicle, called by the engine.
-- @internal
-- @server
-- @tparam PhysObj phys The physics object of the vehicle.
-- @number delta Time since the last call.
function ENT:PhysicsSimulate(phys, delta)
  -- By splitting up the vehicle into multiple states,
  -- we can do the heavy aerodynamic calculations in "flight" only
  -- and use simply translation calculations otherwise

  local state = self:GetVehicleState()
  if state == swvr.enum.State.Flight then
    self:SimulateThrust(phys, delta)

    self:SimulateAerodynamics(phys, delta)
  elseif state == swvr.enum.State.Takeoff then
    self:SimulateTakeoff(phys, delta)
  elseif state == swvr.enum.State.Landing then
    self:SimulateLanding(phys, delta)
  elseif state == swvr.enum.State.Idle then
    self:SimulateIdle(phys, delta)
  end

  self:PhysWake()
end

function ENT:SimulateThrust(phys, delta)
  local max_thrust = self:GetMaxThrust()
  local boost_thrust = self:GetBoostThrust()
  local max_velocity = self:GetMaxVelocity()

  self.TargetThrust = self.TargetThrust or 0

  local active = self:EngineActive()

  local seat = self:GetSeat(1)
  local pilot = NULL

  if active then
    if not IsValid(seat) then return end

    pilot = seat:GetDriver()
    local thrust = 0
    local push = false

    if IsValid(pilot) then
      push = pilot:ControlDown("forward")
      thrust = ((push and 2000 or 0) - (pilot:ControlDown("backward") and 2000 or 0)) * delta
    end

    self.TargetThrust = math.Clamp(self.TargetThrust + thrust, 1, push and boost_thrust or max_thrust)
  else
    self.TargetThrust = self.TargetThrust - math.Clamp(self.TargetThrust, -250, 250)
  end

  self:SetThrust(self:GetThrust() + (self.TargetThrust - self:GetThrust()) * delta)

  if not IsValid(phys) then return end

  local throttle = self:GetThrust() / boost_thrust

  local vel = self:GetVelocity()
  local fwd = self:GetForward()

  local fwd_vel = math.Clamp(fwd:Dot(vel:GetNormalized()), -1, 1) * vel:Length()

  local power = (max_velocity * throttle - fwd_vel) / max_velocity * self:GetMaxPower() * boost_thrust * delta

  if self:IsDestroyed() or not active then
    self:StopEngine()

    return
  end

  if true and IsValid(pilot) then
    local up, down = pilot:ControlDown("up"), pilot:ControlDown("down")

    -- self.TargetThrust = vel:Length() / max_velocity * boost_thrust

    local vertical_thrust = (up and self:GetMaxVerticalThrust() or 0) + (down and -self:GetMaxVerticalThrust() or 0)

    local force = self:GetUp() * (vertical_thrust * phys:GetMass() * delta)

    phys:ApplyForceOffset(force, self:LocalToWorld(self.Controls.Elevator))
    phys:ApplyForceOffset(force, self:LocalToWorld(self.Controls.Wings))
  end

  phys:ApplyForceOffset(fwd * power, self:LocalToWorld(self.Controls.Thrust))
end

function ENT:SimulateAerodynamics(phys, delta)
  local max_velocity = self:GetMaxVelocity()

  local seat = self:GetSeat(1)

  if not IsValid(seat) then return end

  local pilot = seat:GetDriver()

  local up = self:GetUp()
  local lt = self:GetRight() * -1
  local fwd = self:GetForward()

  local max_pitch, max_yaw, max_roll = self.Handling.x, self.Handling.y, self.Handling.z
  local left, right = false, false
  local pitch_scalar, yaw_scalar = 1, 1
  local local_angle = Angle()

  if IsValid(pilot) then
    local eye_angles = seat:WorldToLocalAngles(pilot:EyeAngles())

    if pilot:KeyDown(IN_WALK) and isangle(self.PilotEyeAngles) then
      eye_angles = self.PilotEyeAngles
    else
      self.PilotEyeAngles = eye_angles
    end

    local_angle = self:WorldToLocalAngles(eye_angles)

    if pilot:ControlDown("boost") then
      eye_angles = self:GetAngles()

      self.PilotEyeAngles = Angle(eye_angles.p, eye_angles.y, 0)

      local_angle = Angle(-90, 0, 0)
    end

    local_angle = Angle(local_angle.p, local_angle.y, local_angle.r + math.cos(CurTime()) * 2)

    pitch_scalar = math.max((90 - math.deg(math.acos(math.Clamp(fwd:Dot(eye_angles:Forward()), -1, 1)))) / 90, 0)
    yaw_scalar = math.max( (60 - math.deg( math.acos( math.Clamp( fwd:Dot( eye_angles:Forward() ), -1, 1) ) ) ) / 60, 0)

    left, right = pilot:ControlDown("left"), pilot:ControlDown("right")
  end

  local roll_scalar = math.min(self:GetVelocity():Length() / math.min(max_velocity * 0.5, 3000), 1)

  yaw_scalar = math.max(yaw_scalar, 1 - roll_scalar)

  local stability = self:GetStability()

  local roll_manual = (right and max_roll or 0) - (left and max_roll or 0)

  local roll_auto = (-local_angle.y * 22 * roll_scalar + local_angle.r * 3.5 * yaw_scalar) * pitch_scalar

  local roll = math.Clamp(not (left or right) and roll_auto or roll_manual, -max_roll, max_roll)
  local yaw = math.Clamp(-local_angle.y * 80 * yaw_scalar, -max_yaw, max_yaw)
  local pitch = math.Clamp(-local_angle.p * 25, -max_pitch, max_pitch)

  local mass = phys:GetMass()

  if not self:IsDestroyed() then
    local force = Angle(0, 0, -self:GetAngularVelocity().r + roll * stability) * mass * 500 * stability

    local r = lt * (force.r * 0.5)

    phys:ApplyForceOffset(up, r)
    phys:ApplyForceOffset(up * -1, r * -1)
  end

  phys:ApplyForceOffset(-self:GetUp() * self:GetWingsVelocity() * mass * stability, self:LocalToWorld(self.Controls.Wings))

  phys:ApplyForceOffset(-self:GetUp() * (self:GetElevatorVelocity() + pitch * stability ) * mass * stability, self:LocalToWorld(self.Controls.Elevator))

  phys:ApplyForceOffset(-self:GetRight() * (math.Clamp(self:GetRudderVelocity(), -max_yaw, max_yaw) + yaw * stability) * mass * stability, self:LocalToWorld(self.Controls.Rudder))
end

function ENT:SimulateIdle(phys, delta)
  if self:EngineActive() then
    self.ShadowParams.pos = self.LandPos
    self.ShadowParams.angle = self:GetAngles()
    self.ShadowParams.deltatime = delta

    phys:ComputeShadowControl(self.ShadowParams)
  elseif not self:IsPlayerHolding() then -- TODO: Check if vehicle wants to be frozen during idle
    self.ShadowParams.angle = self:GetAngles()
    self.ShadowParams.deltatime = delta
    self.ShadowParams.pos = self:GetPos()

    phys:ComputeShadowControl(self.ShadowParams)
  end
end

function ENT:SimulateTakeoff(phys, delta)
  if self:EngineActive() then
    self.NextPos = self.StartPos + (self.TakeoffVector or Vector(0, 0, 100))
    self:IsTakingOff(true)
  end

  if self:IsTakingOff() then
    self.ShadowParams.pos = self.NextPos
  else
    self.ShadowParams.pos = self.LandPos
  end

  self.ShadowParams.angle = self:GetAngles()
  self.ShadowParams.deltatime = delta

  phys:ComputeShadowControl(self.ShadowParams)

  -- Let's make sure we actually took off, in case some
  -- idiot tried to take off while inside or something

  local pos, threshold = self:GetPos(), 90

  if self.TakeOffVector then threshold = self.TakeOffVector.z * 0.9 end

  if pos.z >= self.StartPos.z + threshold then
    -- Reset our velocity just to make the transition to flight easier
    phys:SetVelocityInstantaneous(Vector(0, 0, 0))

    self:SetVehicleState(swvr.enum.State.Flight)
    self:IsTakingOff(false)
    self.NextPos = nil
  end
end

function ENT:SimulateLanding(phys, delta)
  -- TODO: CHECK FOR WINGS AND TOGGLE

  self.ShadowParams.angle = Angle(0, self:GetAngles().y, 0) + (self.LandAngles or Angle(0, 0, 0))
  self.ShadowParams.deltatime = delta
  self.ShadowParams.pos = self.LandPos

  phys:ComputeShadowControl(self.ShadowParams)

  local pos = self:GetPos()

  if pos.z <= self.LandPos.z + 10 then
    phys:SetVelocityInstantaneous(Vector(0, 0, 0))

    self.StartPos = self.LandPos
    self:SetVehicleState(swvr.enum.State.Idle)
    self:IsLanding(false)
  end
end

function ENT:GetAngularVelocity()
  local phys = self:GetPhysicsObject()

  if not IsValid(phys) then return Angle() end

  local vec = phys:GetAngleVelocity()

  return Angle(vec.y, vec.z, vec.x)
end

--- Damage Interactions
-- @section damage

function ENT:PhysicsCollide(data, phys)
  if self:IsDestroyed() then
    timer.Simple(0, function() self:Explode() end)
  end

  if not (data.Speed > 60 and data.DeltaTime > 0.1) then return end
  if data.OurOldVelocity:Length() < 60 then return end
  if not cvars.Bool("swvr_collisions_enabled") then return end

  if data.Speed > 500 then
    local dmg = DamageInfo()
    dmg:SetDamage(400 * cvars.Number("swvr_collisions_multiplier"))
    dmg:SetDamageType(DMG_CRUSH)
    dmg:SetAttacker(data.HitEntity)
    dmg:SetInflictor(data.HitEntity)

    if self:DispatchNWEvent("OnCollide", data.HitEntity, dmg:GetDamage()) then return end

    self:EmitSound("Airboat_impact_hard")

    self:TakeDamageInfo(dmg)
  else
    if self:DispatchNWEvent("OnCollide", data.HitEntity, 0) then return end
    self:EmitSound("MetalVehicle.ImpactSoft")
  end
end

--- Called by the engine when the entity takes damage
-- @server
-- @internal
-- @param dmg `DamageInfo` structure containing damage information
function ENT:OnTakeDamage(dmg)
  self:TakePhysicsDamage(dmg)

  local damage = dmg:GetDamage()
  local cur_health = self:Health()
  local new_health = math.max(cur_health - damage, 0)

  if self:GetMaxShield() > 0 and self:GetShield() > 0 then
    -- self:SetNextShieldRecharge(CurTime() + 3)
    dmg:SetDamagePosition(dmg:GetDamagePosition() + dmg:GetDamageForce():GetNormalized() * 250)

    self:ShieldDamage()
    self:SetShield(math.max(self:GetShield() - damage, 0))
  else
    self:SetHP(new_health)

    local fx = EffectData()
    fx:SetOrigin(dmg:GetDamagePosition())
    fx:SetNormal(dmg:GetDamageForce():GetNormalized())

    util.Effect("MetalSpark", fx)
  end

  -- TODO: Crash landing mode
  if new_health <= 0 and not (self:GetShield() > damage and shield) and not self.Done then
    self:Destroy(dmg:GetAttacker(), dmg:GetInflictor())

    local fx = ents.Create("info_particle_system")
    fx:SetKeyValue("effect_name", "fire_large_01")
    fx:SetKeyValue("start_active", 1)
    fx:SetOwner(self)
    fx:SetPos(self:LocalToWorld(self:GetPhysicsObject():GetMassCenter()))
    fx:SetAngles(self:GetAngles())
    fx:Spawn()
    fx:Activate()
    fx:SetParent(self)
  end
end

--- Shield damage visuals
-- @server
-- @see OnTakeDamage
function ENT:ShieldDamage()
  if not IsValid(self) then
    return
  end

  local fx = EffectData()
  fx:SetEntity(self)
  fx:SetOrigin(self:GetPos())
  fx:SetScale(self:GetModelScale())
  util.Effect("swvr_shield", fx)

  for k, v in pairs(self.Parts or {}) do
    if not v.Entity then continue end

    local partFX = EffectData()
    partFX:SetEntity(v.Entity)
    partFX:SetOrigin(v.Entity:GetPos())
    partFX:SetScale(self:GetModelScale())
    util.Effect("swvr_shield", partFX)
  end

  self:DispatchNWEvent("OnShieldDamage")
end

--- Destroys the vehicle physically
-- @server
-- @entity[opt] attacker The attacker that destroyed the vehicle
-- @entity[opt] inflictor The inflictor that destroyed the vehicle
-- @see Explode
function ENT:Destroy(attacker, inflictor)
  if self:IsDestroyed() then return end

  self:IsDestroyed(true)

  local phys = self:GetPhysicsObject()
  if IsValid(phys) then phys:SetDragCoefficient(-20) end

  self.Attacker = attacker
  self.Inflictor = inflictor
end

--- Blows up the vehicle visually
-- @server
-- @see Destroy
function ENT:Explode()
  if self.Done then return end

  self.Done = true

  for _, seat in ipairs(self:GetSeats()) do
    local passenger = seat:GetDriver()

    if not IsValid(passenger) then continue end

    passenger:TakeDamage(200, self.Attacker or game.GetWorld(), self.Inflictor or game.GetWorld())
  end

  local ent = ents.Create("swvr_explosion")

  if not IsValid(ent) then return SafeRemoveEntityDelayed(self, 0) end

  ent:SetPos(self:GetPos())
  ent.Gibs = self.Gibs
  ent:Spawn()
  ent:Activate()

  SafeRemoveEntityDelayed(self, 0)
end
