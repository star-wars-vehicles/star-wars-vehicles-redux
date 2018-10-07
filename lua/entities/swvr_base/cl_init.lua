include("shared.lua")
include("cl_events.lua")

--- Initialize the base client-side.
-- Initializes all needed variables client-side.
-- May also call other Initialization functions.
function ENT:Initialize()
  self.FXEmitter = ParticleEmitter(self:GetPos())

  self.Sounds   = self.Sounds or {}

  self.Engines  = self.Engines or {}
  self.Events   = self.Events or {}

  self:InitParts()

  LocalPlayer().SWVRViewDistance = LocalPlayer().SWVRViewDistance or 0
  LocalPlayer().SW_ViewDistance = LocalPlayer().SW_ViewDistance or 0 -- Backwards compatibility for now...

  self.Filter = self:GetChildEntities()
end

function ENT:Setup(options)
  options = options or {}
  self.ViewDistance = options.ViewDistance or 1000
  self.ViewHeight   = options.ViewHeight or 300

  self.AlwaysDraw = tobool(options.AlwaysDraw)
  self.DrawGlass  = tobool(options.DrawGlass)

  if (options.Cockpit) then
    if (istable(options.Cockpit) and util.IsValidModel(options.Cockpit.Path)) then
      self.Cockpit = {
        Path = options.Cockpit.Path,
        Pos = options.Cockpit.Pos and self:LocalToWorld(options.Cockpit.Pos) or nil,
        Ang = options.Cockpit.Ang or nil
      }
    elseif (isstring(options.Cockpit)) then
      local mat = Material(options.Cockpit)

      if (mat:IsError()) then
        error("Invalid cockpit texture specified!")
      end

      self.Cockpit = surface.GetTextureID(options.Cockpit)
    end
  end

  if options.EngineSound then
    self:AddSound("Engine", options.EngineSound, { Is3D = true, Looping = true, Callback = function(ship) return ship:GetFlight() end, ChangePitch = true, Repeat = true })
  end
end

function ENT:SetupDefaults(options)
  options = options or {}

  if options.OnShieldsDown ~= false then
    self:AddEvent("OnShieldsDown", function()
      if LocalPlayer():GetNWEntity("Ship") ~= self then
        return
      end

      surface.PlaySound("swvr/shields/swvr_shields_down.wav")
    end)
  end

  if options.OnFire ~= false then
    self:AddEvent("OnFire", function(group, seat)
      if not group.CanOverheat then return end
      if LocalPlayer():GetNWEntity("Ship") ~= self then return end
      if LocalPlayer():GetNWString("SeatName") ~= seat then return end

      if (group.Overheat >= group.MaxOverheat - 10) then
        self:EmitSound("swvr/weapons/swvr_overheat_ping.wav", 75, 100, math.Clamp(math.exp(math.pow(group.Overheat / group.MaxOverheat * 0.98, 7)) - 1, 0, 1))
      end
    end)
  end

  if options.OnOverheat ~= false then
    self:AddEvent("OnOverheat", function(group, seat)
      local ply = LocalPlayer()

      if ply:GetNWEntity("Ship") ~= self then
        return
      end

      if ply:GetNWString("SeatName") ~= seat then
        return
      end

      surface.PlaySound("swvr/weapons/swvr_overheat_cooldown.wav")
    end)
  end

  if options.OnOverheatReset ~= false then
    self:AddEvent("OnOverheatReset", function(group, seat)
      local ply = LocalPlayer()

      if ply:GetNWEntity("Ship") ~= self then
        return
      end

      if ply:GetNWString("SeatName") ~= seat then
        return
      end

      surface.PlaySound("swvr/weapons/swvr_overheat_reset.wav")
    end)
  end

  if options.OnCollision ~= false then
    self:AddEvent("OnCollision", function(damage)
      local ply = LocalPlayer()
      local ship = ply:GetNWEntity("Ship")

      if (IsValid(ship) and ship == self and ship:GetFirstPerson()) then
        self:EmitSound("swvr/impact/swvr_impact_fp_" .. math.random(1, 5) .. ".wav", 75, 100, 1)
      else
        self:EmitSound("swvr/impact/swvr_impact_" .. math.random(1, 6) .. ".wav", 60, 100, 0.25)
      end
    end)
  end
end

--- Initialize any clientside parts.
-- Spawns client props for each prop added clientside.
function ENT:InitParts()
  self.Parts = self.Parts or {}

  for k, v in pairs(self.Parts or {}) do
    local e = ents.CreateClientProp(v.Path, RENDERGROUP_OPAQUE)
    e:SetPos(v.Pos or self:GetPos())
    e:SetAngles(v.Ang or self:GetAngles())
    e:SetParent(self)
    e:SetNoDraw(true)
    e:Spawn()
    v.Ent = e
  end

  local cockpit = self.Cockpit

  if istable(cockpit) then
    local e = ents.CreateClientProp(cockpit.Path, RENDERGROUP_OPAQUE)
    e:SetPos(cockpit.Pos or self:GetPos())
    e:SetAngles(cockpit.Ang or self:GetAngles())
    e:SetParent(self)
    e:SetNoDraw(true)
    e:Spawn()
    cockpit.Ent = e
  end
end

function ENT:Draw()
  if self:GetFlight() then
    local avatar = self:GetAvatar()

    if IsValid(avatar) then
      if self:GetFirstPerson() and LocalPlayer() == self:GetPilot() then
        avatar:SetNoDraw(true)

        for k, v in pairs(self.Parts or {}) do
          v.Ent:DrawModel()
        end

        if istable(self.Cockpit) and IsValid(self.Cockpit.Ent) then
          self.Cockpit.Ent:DrawModel()
        end
      else
        avatar:SetNoDraw(false)
        avatar:DrawModel()
      end

      if (not table.HasValue(self.Filter, avatar)) then
        table.insert(self.Filter, avatar)
      end
    end
  end

  if not self.Cockpit or not self:GetFirstPerson() or LocalPlayer() ~= self:GetPilot() or self.AlwaysDraw then
    self:DrawModel()
  end
end

function ENT:Think()
  if self:GetFlight() then
    if not (self:IsTakingOff() and self:IsLanding()) then
      self:EngineEffects()
    end
  end

  self:LightEffects()
  self:ThinkSounds()
  self:SetNextClientThink(CurTime())

  return true
end

function ENT:ThinkSounds()
  for name, snd in pairs(self.Sounds) do
    local patch = istable(snd.Patch) and table.Random(snd.Patch) or snd.Patch

    if snd.Is3D then
      self:UpdateClientsideSound(snd, patch)
    end

    if self.SoundDisabled and patch:IsPlaying() then
      patch:Stop()

      continue
    end

    if snd.Callback then
      -- Explicitly return false to stop the sound from playing
      -- Returning true/nil continues normally
      local result = snd.Callback(self, snd)

      if result == false then
        snd.Patch:Stop()
        continue
      end
    end

    if snd.NextPlay < CurTime() and (snd.Repeat or not snd.Played) then
      if (snd.Looping and patch:IsPlaying()) then continue end

      if not snd.Is3D and LocalPlayer():GetNWEntity("Ship") ~= self then continue end

      self:StopClientsideSound(snd, patch)
      self:StartClientsideSound(snd, patch)

      snd.Played = true
      snd.NextPlay = CurTime() + snd.Cooldown
    end
  end
end

local DEFAULT_SOUND_OPTIONS = {
  Is3D = false,
  Callback = nil,
  Played = false,
  Repeat = false,
  Looping = false,
  ChangePitch = false,
  Cooldown = 0,
  NextPlay = CurTime(),
  Volume = 1
}

function ENT:AddSound(name, path, options)
  options = options or {}
  self.Sounds = self.Sounds or {}

  local snd = table.Inherit(options or {}, DEFAULT_SOUND_OPTIONS)
  snd.Name = name
  snd.Path = path

  if istable(path) then
    local patches = {}
    for _, file in ipairs(path) do
      table.insert(patches, CreateSound(self, file))
    end

    snd.Patch = patches
  else
    snd.Patch = CreateSound(self, path)
  end

  self.Sounds[name] = snd
end

--- Start a sound on the client.
-- Starts a sound on any clients with a mode
-- @param mode the mode of the sound
function ENT:StartClientsideSound(snd, patch)
  if self.SoundDisabled or patch:IsPlaying() then return end

  patch:Stop()
  patch:SetSoundLevel(100)
  patch:PlayEx(snd.Volume, 100)
end

--- Stop a sound on the client.
-- Stops a sound on any clients with a mode
-- @param mode the mode of the sound
function ENT:StopClientsideSound(snd, patch)
  if not patch:IsPlaying() then return end

  patch:Stop()
end

--- Doppler effect on sounds.
-- Currently hard coded for engine only (I know kill me)
function ENT:UpdateClientsideSound(snd, patch)
  if self.SoundDisabled then return end
  if not patch:IsPlaying() then return end


  local velo = self:GetVelocity()
  local pitch = self:GetVelocity():Length()
  local doppler = 0

  -- For the Doppler-Effect!
  if LocalPlayer():GetNWEntity("Ship") ~= self then
    -- Is the vehicle flying towards the player or away from him?
    local dir = LocalPlayer():GetPos() - self:GetPos()
    doppler = velo:Dot(dir) / (150 * dir:Length())
  end

  pitch = (snd.ChangePitch and math.Clamp(60 + pitch / 25, 75, 100) or patch:GetPitch()) + doppler
  patch:ChangePitch(pitch, 0)


  local veh = LocalPlayer():GetVehicle()
  local isPassenger = IsValid(veh) and IsValid(veh:GetParent()) and veh:GetParent().IsSWVRVehicle

  -- 3D Sound is quieter from the interior
  if (((self:GetFirstPerson() and self:GetPilot() == LocalPlayer()) or (isPassenger and not veh:GetThirdPersonMode())) and LocalPlayer():GetNWEntity("Ship") == self) then
    patch:ChangeVolume(snd.Volume / 3)
  else
    patch:ChangeVolume(snd.Volume)
  end
end

function ENT:OnRemove()
  for k, v in pairs(self.Sounds) do
    if v.Patch then v.Patch:Stop() end
  end

  if (IsValid(self.FXEmitter)) then
    self.FXEmitter:Finish()
  end

  for k, v in pairs(self.Parts or {}) do
    SafeRemoveEntity(v.Ent)
  end

  SafeRemoveEntity(istable(self.Cockpit) and self.Cockpit.Ent)
end

function ENT:EngineEffects()
  local normal = (self:GetForward() * -1):GetNormalized()
  local roll = math.Rand(-90, 90)
  local id = self:EntIndex()

  for k, v in pairs(self.Engines) do
    local pos = self:LocalToWorld(v.Pos)
    local sprite = self.FXEmitter:Add(v.Sprite, pos)
    sprite:SetVelocity(normal)
    sprite:SetDieTime(FrameTime() * v.Lifetime)
    sprite:SetStartAlpha(v.Color.a)
    sprite:SetEndAlpha(v.Color.a)
    sprite:SetStartSize(v.StartSize * self:GetModelScale())
    sprite:SetEndSize(v.EndSize * self:GetModelScale())
    sprite:SetRoll(roll)
    sprite:SetColor(v.Color.r, v.Color.g, v.Color.b)

    if v.Light then
      local dynlight = DynamicLight((id + 4096) * id)
      dynlight.Pos = pos
      dynlight.Brightness = 5
      dynlight.Size = 200
      dynlight.Decay = 1024
      dynlight.R = v.Color.r
      dynlight.G = v.Color.g
      dynlight.B = v.Color.b
      dynlight.DieTime = CurTime() + 1
    end
  end
end

function ENT:LightEffects()
  for i, light in ipairs(self.Lights or {}) do
    if (not light.Callback or (light.Callback and light.Callback(self))) then
      local id = self:EntIndex()
      local dynlight = DynamicLight(id * 2 + 4096 * (i * 10))
      dynlight.Pos = light.Pos
      dynlight.Brightness = light.Brightness
      dynlight.Size = isnumber(light.Size) and light.Size or math.random(light.Size[1], light.Size[2])
      dynlight.Decay = light.Decay
      dynlight.r = light.Color.r
      dynlight.g = light.Color.g
      dynlight.b = light.Color.b
      dynlight.DieTime = CurTime() + light.DieTime
    end
  end
end

--- Add an engine to the ship.
-- Adds a visual engine to the ship
-- @param pos The position of the engine
-- @param startsize The start size of the engine
-- @param endsize The end size of the engine (often smaller)
-- @param lifetime The lifetime of the effect, this affects length of "plasma"
-- @param color The color of the engine sprite
-- @param sprite A custom sprite to use for the engine effect (optional)
function ENT:AddEngine(pos, options)
  options = options or {}
  self.Engines = self.Engines or {}

  self.Engines[table.Count(self.Engines) + 1] = {
    Pos = pos,
    Color = options.Color or Color(0, 0, 255, 255),
    Sprite = Material(options.Sprite or "sprites/bluecore"),
    Lifetime = options.Lifetime or 1.25,
    StartSize = options.StartSize or 25,
    EndSize = options.EndSize or 18.75
  }
end

function ENT:AddLight(pos, options)
  options = options or {}
  self.Lights = self.Lights or {}

  self.Lights[table.Count(self.Lights) + 1] = {
    Pos = self:LocalToWorld(pos),
    Brightness or options.Brightness or 8,
    Size = options.Size or {1, 100},
    Decay = options.Decay or 1024,
    Color = options.Color or Color(255, 255, 255),
    DieTime = options.Lifetime or 1,
    Callback = options.Callback or nil
  }
end

--- Add a part to the ship.
-- Add a clientside part to the ship, only rendered in first person.
-- @param name Name of the part
-- @param path Path to the model of the part
-- @param pos The position of the part
-- @param ang The angle of the part
function ENT:AddPart(name, path, pos, ang)
  self.Parts = self.Parts or {}

  util.PrecacheModel(path)

  self.Parts[name] = {
    Path = path,
    Pos = pos and self:LocalToWorld(pos) or nil,
    Ang = ang or nil
  }

  return self.Parts[name]
end

--- Calculate the view for passengers.
-- Fallback CalcView if no custom hook is found.
-- @param dist The distance from the ship
function ENT:VehicleView(dist, udist, fpv_pos)
  local p = LocalPlayer()
  local pos, face
  local View = {}

  if IsValid(self) then
    if self:GetFirstPerson() then
      pos = fpv_pos
      face = self:GetAngles()

      if self:GetFreeLook() and p:KeyPressed(IN_SCORE) then
        p:SetEyeAngles(Angle(0, 0, 0))
      end

      if self:GetFreeLook() and p:KeyDown(IN_SCORE) and not p:KeyPressed(IN_SCORE) then
        local eAngles = p:EyeAngles()
        local newAng = self:GetAngles() + eAngles
        face = Angle(newAng.p, math.Clamp(newAng.y, self:GetAngles().y - 90, self:GetAngles().y + 90), newAng.r)
      end
    else
      if self:GetHyperdrive() ~= 2 then
        local aim = LocalPlayer():GetAimVector()
        local tpos = self:GetPos() + self:GetUp() * udist + aim:GetNormal() * -(dist + p.SWVRViewDistance)

        local tr = util.TraceLine({
          start = self:GetPos(),
          endpos = tpos,
          filter = self.Filter
        })

        pos = tr.HitPos or tpos
        face = ((self:GetPos() + Vector(0, 0, 100)) - pos):Angle()
        self._LastViewPos = pos
        self._LastViewAng = face
      else
        pos = self._LastViewPos
        face = self._LastViewAng
      end
    end

    View.origin = pos
    View.angles = face

    return View
  end
end

function ENT:HUDDrawHull()
  surface.SetFont("HUD_Health")
  local w, h = ScrW() / 100 * 20, ScrW() / 100 * 20 / 4
  local x, y = ScrW() - w - w / 8, ScrH() / 4 * 3.4
  local per = self:GetCurHealth() / self:GetStartHealth()

  surface.SetDrawColor(Color(255, 255, 255, 255))
  surface.SetMaterial(Material("hud/hull/hp_frame_under.png", "noclamp"))
  surface.DrawTexturedRectUV(x, y, w, h, 0, 0, 1, 1)

  if (self:GetCritical()) then
    if (self:GetCurHealth() >= self:GetStartHealth() * 0.1) then
      surface.SetDrawColor(Color(50, 120, 255, 255))
    else
      surface.SetDrawColor(Color(255, 35, 35, 255))
    end
  end

  local barW, barH = w * 0.90625, h * 0.4
  local barX, barY = x + w * 0.02832, y + h * 0.27343

  surface.SetMaterial(Material("hud/hull/hp_bar.png", "noclamp"))
  surface.DrawTexturedRectUV(barX, barY, barW * (self:GetCurHealth() / self:GetStartHealth()), barH, 0, 0, per, 1)
  surface.SetMaterial(Material("hud/hull/hp_bar.png", "noclamp"))
  surface.SetDrawColor(Color(50, 120, 255, 255))
  surface.DrawTexturedRectUV(barX, barY, barW * self:GetShieldHealth() / self:GetStartShieldHealth(), barH, 0, 0, per, 1)
  surface.SetMaterial(Material("hud/hull/hp_frame_over.png", "noclamp"))
  surface.SetDrawColor(Color(255, 255, 255, 255))
  surface.DrawTexturedRectUV(x, y, w, h, 0, 0, 1, 1)

  local health = math.Round(per * 100) .. "%"
  local tW, tH = surface.GetTextSize(health)

  surface.SetTextColor(Color(255, 255, 255, 255))

  x, y = x + w * 0.35 - tW / 2, y - tH / 2 + h * 0.06

  surface.SetTextPos(x, y + tH / 2)
  surface.DrawText(health)
end

function ENT:HUDDrawSpeedometer()
  local speed = self:GetSpeed()
  local color = Color(255, 255, 255, 255)

  if (speed < 0) then
    color = Color(255, 50, 50)
    speed = speed * -1
  end

  local w, h = ScrW() / 100 * 20, ScrW() / 100 * 20 / 4
  local x, y = ScrW() - w - w / 8, ScrH() / 4 * 3.4 + h / 2 * 1.5
  local per = math.Clamp(speed / self:GetMaxSpeed(), 0, 1)
  surface.SetDrawColor(Color(255, 255, 255, 255))
  surface.SetMaterial(Material("hud/speedo/speed_frame_under.png", "noclamp"))
  surface.DrawTexturedRectUV(x, y, w, h, 0, 0, 1, 1)
  local barX, barY = x + w * 0.01953125, y + h * 0.234375
  local barW, barH = w * 0.9541015625, h * 0.53515625
  surface.SetDrawColor(color)
  surface.SetMaterial(Material("hud/speedo/speed_bar.png", "noclamp"))
  surface.DrawTexturedRectUV(barX, barY, barW * per, barH, 0, 0, per, 1)
  surface.SetDrawColor(Color(255, 255, 255, 255))
  surface.SetMaterial(Material("hud/speedo/speed_frame_over.png", "noclamp"))
  surface.DrawTexturedRectUV(x, y, w, h, 0, 0, 1, 1)
end

function ENT:GetReticleLock()
  if (not self:CanLock()) then
    return false
  end

  local b1, b2 = self:GetModelBounds()

  for l, w in pairs(ents.FindInBox(self:LocalToWorld(b1), self:LocalToWorld(b2) + self:GetForward() * 10000)) do
    if (IsValid(w) and w.IsSWVRVehicle and w ~= self and not IsValid(w:GetParent()) and SWVR:LightOrDark(w:GetAllegiance()) ~= SWVR:LightOrDark(self:GetAllegiance())) then
      local tr = util.TraceLine({
        start = self:GetPos(),
        endpos = w:GetPos(),
        filter = self
      })

      if (not tr.HitWorld) then
        local vpos = w:GetPos() + w:GetUp() * (w:GetModelRadius() / 3)

        return vpos
      end
    end
    -- TODO Check for ships that can't be locked on to (cloak/jammer/etc.)
  end

  return false
end

function ENT:HUDDrawOverheating()
  local seat = "Weapon" .. LocalPlayer():GetNWString("SeatName")

  if not self:GetNWBool(seat .. "CanOverheat") then return end

  if (self:GetNWBool(seat .. "IsOverheated")) then
    surface.SetDrawColor(Color(255, 0, 0, 255))
  else
    if (self:GetNWInt(seat .. "Overheat") > 0 and self:GetNWInt(seat .. "Overheat") <= 16) then
      surface.SetDrawColor(Color(128, 255, 0, 255))
    elseif (self:GetNWInt(seat .. "Overheat") > 16 and self:GetNWInt(seat .. "Overheat") <= 32) then
      surface.SetDrawColor(Color(255, 255, 0, 255))
    else
      surface.SetDrawColor(Color(255, 128, 0, 255))
    end
  end

  local w, h = ScrW() / 100 * 3.5, ScrH() / 100 * 0.5
  local tr

  if (self:GetNWBool(seat .. "Track")) then
    tr = util.TraceLine({
      start = LocalPlayer():EyePos(),
      endpos = LocalPlayer():EyePos() + LocalPlayer():GetAimVector():Angle():Forward() * 10000,
      filter = {self, LocalPlayer()}
    })
  else
    tr = util.TraceLine({
      start = self:GetPos(),
      endpos = self:GetPos() + self:GetForward() * 10000,
      filter = {self, LocalPlayer()}
    })
  end

  local vpos = tr.HitPos

  if (self:CanLock()) then
    local lock = self:GetReticleLock()

    if (lock) then
      vpos = lock
    end
  end

  local screenpos = vpos:ToScreen()
  local x, y = screenpos.x, screenpos.y
  local o = self:GetNWInt(seat .. "Overheat") / self:GetNWInt(seat .. "OverheatMax") * 100
  local per = o / 100
  w = w * per
  surface.DrawRect(x - w / 2, y + ScrW() / 100 * 1.5, w, h)
end

function ENT:HUDDrawReticles()
  local seat = LocalPlayer():GetNWString("SeatName")
  local tr

  if (self:GetNWBool("Weapon" .. seat .. "Track")) then
    tr = util.TraceLine({
      start = LocalPlayer():EyePos(),
      endpos = LocalPlayer():EyePos() + LocalPlayer():GetAimVector():Angle():Forward() * 10000,
      filter = {self, LocalPlayer()}
    })
  else
    tr = util.TraceLine({
      start = self:GetPos(),
      endpos = self:GetPos() + self:GetForward() * 10000,
      filter = {self, LocalPlayer()}
    })
  end

  surface.SetTextColor(Color(255, 255, 255, 255))
  local vpos = tr.HitPos
  local material = "hud/reticle.png"
  surface.SetMaterial(Material(material, "noclamp"))

  if (self:CanLock()) then
    local lock = self:GetReticleLock()

    if (lock) then
      vpos = lock
      material = "hud/reticle_lock.png"
    end
  end

  local screenpos = vpos:ToScreen()
  local x, y = screenpos.x, screenpos.y
  local w, h = ScrW() / 100 * 2, ScrW() / 100 * 2
  surface.SetDrawColor(Color(255, 255, 255, 255))
  surface.SetMaterial(Material(material, "noclamp"))
  surface.DrawTexturedRectUV(x - w / 2, y - h / 2, w, h, 0, 0, 1, 1)
end

function ENT:HUDDrawCompass(fpvX, fpvY)
  local size = ScrW() / 10
  local x, y

  if (self:GetFirstPerson()) then
    x = fpvX or ScrW() / 2
    y = fpvY or ScrH() / 4 * 3.1
  else
    x = size * 0.65
    y = x
  end

  surface.SetTexture(surface.GetTextureID("hud/sw_shipcompass_BG"))
  surface.SetDrawColor(255, 255, 255, 255)
  surface.DrawTexturedRectRotated(x, y, size, size, 0)
  local rotate = (self:GetAngles().y - 90) * -1
  local al = SWVR:LightOrDark(self:GetAllegiance())
  local maxDist = 5000

  for k, v in pairs(ents.FindInSphere(self:GetPos(), maxDist)) do
    if (IsValid(v) and v.IsSWVRVehicle and v ~= self and al ~= SWVR:LightOrDark(v:GetAllegiance())) then
      local dist = (self:GetPos() - v:GetPos()):Length() / maxDist
      local a = 1 - dist
      local r = ((self:GetPos() - v:GetPos()):Angle().y - 90) + rotate - 180
      surface.SetDrawColor(255, 255, 255, 255 * a)
      surface.SetTexture(surface.GetTextureID("hud/sw_shipcompass_locator")) -- Print the texture to the screen
      surface.DrawTexturedRectRotated(x, y, size, size, r)
    end
  end

  surface.SetDrawColor(Color(255, 255, 255, 255))
  surface.SetTexture(surface.GetTextureID("hud/sw_shipcompass_disk"))
  surface.DrawTexturedRectRotated(x, y, size, size, rotate)
end

function ENT:HUDDrawAltimeter(fpvX, fpvY)
  local p = LocalPlayer()
  local size = ScrW() / 10

  local x, y

  if (self:GetFirstPerson()) then
    x = fpvX or ScrW() / 2
    y = fpvY or ScrH() / 4 * 3.1
  else
    x = size * 0.65
    y = x
  end

  -- Altimeter
  local max_ld = 20000
  local ld = 300

  if (self:GetLandHeight() > 0) then
    ld = self:GetLandHeight()
  end

  if (ld > 500) then
    max_ld = 1000
  elseif (ld > 1000) then
    max_ld = 1500
  end

  local tr = util.TraceLine({
    start = self:GetPos(),
    endpos = self:GetPos() + Vector(0, 0, -max_ld * 2),
    filter = {self}
  })

  local a = p.SW_Alt_Alpha or 255
  tMod = " m"

  if (tr.Hit and tr.HitWorld) then
    p.SW_Alt_Alpha = math.Clamp(a + 4, 130, 255)
  else
    tMod = tMod .. "+"
    p.SW_Alt_Alpha = math.Clamp(a - 4, 130, 255)
  end

  surface.SetTextColor(Color(255, 255, 255, a))
  surface.SetDrawColor(Color(255, 255, 255, a))
  --local dist = math.Clamp(math.Round(self:GetPos().z - tr.HitPos.z), 0, max_ld * 2)
  local dist = math.Round((self:GetPos().z - tr.HitPos.z) / 40 / 0.75)
  local t = dist
  local w = size
  local h = size / 2
  x = x - w / 2
  y = y + size / 2 * 1.1
  surface.SetFont("HUD_Altimeter")
  surface.SetMaterial(Material("hud/altimeter/altimeter_frame.png", "noclamp"))
  surface.DrawTexturedRectUV(x, y, w, h, 0, 0, 1, 1)
  surface.SetTextPos(x + w * 0.45, y + h * 0.125)

  if (self:IsTakingOff()) then
    t = "N/A"
    surface.DrawText(t)
  else
    surface.DrawText(t .. tMod)
  end

  if (dist <= ld) then
    surface.SetMaterial(Material("hud/altimeter/altimeter_light1.png", "noclamp"))
    surface.DrawTexturedRectUV(x, y, w, h, 0, 0, 1, 1)

    if (self:IsTakingOff()) then
      surface.SetMaterial(Material("hud/altimeter/altimeter_light2.png", "noclamp"))
      surface.DrawTexturedRectUV(x, y, w, h, 0, 0, 1, 1)
    end
  end
end

function ENT:HUDDrawTransponder()
  local size = ScrW() / 10
  local w, h = size, size / 3.08
  local x, y = ScrW() - w / 2 - size * 0.65, ScrW() / 100
  local Transponder = self:GetTransponder()
  surface.SetMaterial(Material("hud/clearance_code.png", "noclamp"))
  surface.SetFont("HUD_Transponder")
  surface.SetDrawColor(255, 255, 255, 255)
  surface.DrawTexturedRectUV(x, y, w, h, 0, 0, 1, 1)
  surface.SetTextPos(x + w * 0.32, y + h * 0.45)
  surface.DrawText(Transponder)
end

function ENT:HUDDrawOverlay()
  if not isnumber(self.Cockpit) then return end

  if self.DrawGlass then
    surface.SetTexture(surface.GetTextureID("models/props_c17/frostedglass_01a_dx60")) -- Print the texture to the screen
    surface.SetDrawColor(255, 255, 255, 255) -- Colour of the HUD
    surface.DrawTexturedRect(0,0, ScrW(), ScrH()) -- Position, Size
  end

  surface.SetTexture(self.Cockpit) -- Print the texture to the screen
  surface.SetDrawColor(255, 255, 255, 255) -- Colour of the HUD
  surface.DrawTexturedRect(0, 0, ScrW(), ScrH()) -- Position, Size
end

hook.Add("StartChat", "SWVRStartChat", function()
  LocalPlayer().IsChatting = true
end)

hook.Add("FinishChat", "SWVRFinishChat", function()
  LocalPlayer().IsChatting = false
end)

hook.Add("PlayerBindPress", "SWMouseWheel", function(p, bind, pressed)
  if p:GetNWBool("Flying") then
    if (bind == "invnext") then
      p.SWVRViewDistance = p.SWVRViewDistance + 5
    elseif (bind == "invprev") then
      p.SWVRViewDistance = p.SWVRViewDistance - 5
    end

    p.SWVRViewDistance = math.Clamp(p.SWVRViewDistance, -500, 500)
  end
end)

hook.Add("ScoreboardShow", "SWVRScoreboardShow", function()
  local p = LocalPlayer()
  local Piloting = p:GetViewEntity() ~= p and p:GetViewEntity().IsSWVRVehicle

  if (Piloting and p:GetViewEntity():CanFreeLook()) then
    return false
  end
end)

hook.Add("CalcView", "SWVRVehicleView", function(p)
  if not LocalPlayer():GetNWBool("Flying", false) then
    return
  end

  local View = {}
  local Piloting = p:GetViewEntity() ~= p and p:GetViewEntity().IsSWVRVehicle
  local IsPassenger = IsValid(p:GetVehicle()) and IsValid(p:GetVehicle():GetParent()) and p:GetVehicle():GetParent().IsSWVRVehicle
  local pos, ship

  if Piloting then
    ship = p:GetViewEntity()

    if IsValid(ship) and ship:CheckHook(hook.Run("SWVRCalcView", p, true)) then
      return
    end

    if IsValid(ship) and not ship.HasCustomCalcView then
      local fpvpos = ship:GetFPVPos() or Vector(0, 0, 0)
      pos = ship:LocalToWorld(fpvpos)
      View = ship:VehicleView(ship.ViewDistance or 800, ship.ViewHeight or 800, pos)

      return View
    end
  elseif IsPassenger then
    ship = p:GetVehicle():GetParent()

    if IsValid(ship) and ship:CheckHook(hook.Run("SWVRCalcView", p, false)) then
      return
    end

    local v = p:GetVehicle()
    local NoFirstPerson = v:GetNWBool("NoFirstPerson")

    if IsValid(v) and IsValid(ship) and not ship.HasCustomCalcView and (v:GetThirdPersonMode() or NoFirstPerson) then
      View = ship:VehicleView(ship.ViewDistance or 800, ship.ViewHeight or 250)

      return View
    end
  end
end)

hook.Add("HUDPaint", "SWVRHUDPaint", function()
  local ply = LocalPlayer()

  if not ply:GetNWBool("Flying") then return end

  local ship = ply:GetNWEntity("Ship")

  if not IsValid(ship) then return end

  if (ship:CheckHook(hook.Run("SWVRHUDPaint", ship))) then
    return
  end

  if not IsValid(ship) then return end

  if ship:GetFirstPerson() and ship:GetPilot() == ply then
    ship:HUDDrawOverlay()
  end

  ship:HUDDrawHull()
  ship:HUDDrawReticles()
  ship:HUDDrawSpeedometer()
  ship:HUDDrawTransponder()
  ship:HUDDrawCompass(ScrW() / 2, ScrH() / 4 * 2.8)
  ship:HUDDrawAltimeter(ScrW() / 2, ScrH() / 4 * 2.8)
  ship:HUDDrawOverheating()
end)

function ENT:DispatchListeners(event, ...)
  for k, v in pairs(self.Events[string.upper(event)] or {}) do
    v(...)
  end

  hook.Run("SWVR." .. event, self, ...)
end

function ENT:AddEvent(name, callback)
  self.Events = self.Events or {}
  self.Events[string.upper(name)] = self.Events[string.upper(name)] or {}
  table.insert(self.Events[string.upper(name)], callback)
end

function ENT:DispatchEvent(event)
  if self["_" .. event] then
    self["_" .. event](self)
  end
end

net.Receive("SWVREvent", function()
  local event = net.ReadString()
  local ship = net.ReadEntity()
  ship:DispatchEvent(event)
end)

net.Receive("SWVR.NetworkWeapons", function()
  local ship = net.ReadEntity()
  local group = net.ReadTable()

  ship.WeaponGroups[group.Name] = group
end)
